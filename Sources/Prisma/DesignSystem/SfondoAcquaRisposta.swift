import SwiftUI

// «L'acqua risponde» (Design/template-apple-specifica.md §3.6 e §3.7): l'acqua della scrivania sente ciò che succede.
// - un clic o un tocco sul fondo libero della scrivania fa cadere una goccia lì (`.gocciaAlTocco()`);
// - una notifica nuova arriva come una goccia sulla campanella della barra;
// - mentre Vera risponde, l'acqua vibra piano intorno alla sua sfera;
// - allo sblocco una goccia grande apre la scrivania, al centro.
// L'acqua è la stessa di oggi: la goccia è una goccia della pioggia (FisicaAcqua.goccia), la vibrazione una serie di
// impatti leggeri della stessa fisica (FisicaAcqua.vibra), lo shader non cambia.
//
// Fili: le richieste arrivano da qualsiasi thread (di solito il principale) a `RispostaAcqua.condivisa`, che le gira
// alle code delle tele d'acqua montate (`CodaRispostaAcqua`, una per renderer, sotto la sua serratura). La coda del
// disegno le prende al fotogramma in moto successivo e le applica alla fisica: niente lavoro sul thread principale,
// niente fisica fuori dalla coda del disegno.
// Le gocce non cadono con «L'acqua della scrivania» spenta (Impostazioni › Aspetto), con lo sfondo fermo, con
// «Riduci movimento» (del sistema o di Prisma), nelle istantanee, con la finestra nascosta o il Mac a riposo: in tutti
// questi casi la richiesta si lascia cadere, non si accumula.

/// Una richiesta all'acqua. I punti sono nello spazio globale di SwiftUI (quello della finestra: `.global`).
enum EventoAcqua {
    /// Una goccia nel punto, con il peso dato (come la pioggia: 0,4…1; oltre 1 più grande).
    case goccia(CGPoint, peso: Float)
    /// Una goccia al centro dell'acqua (lo sblocco).
    case gocciaAlCentro(peso: Float)
    /// L'acqua vibra piano intorno al punto per tanti secondi.
    case vibra(CGPoint, durata: Double)
    /// Smette di vibrare.
    case fermaVibrazioni
}

/// I punti della shell su cui l'acqua risponde: li segna `.puntoAcqua(_:)` sulla vista.
enum PuntoAcqua: Hashable {
    /// La campanella del centro notifiche, nella barra.
    case campanella
    /// La sfera di Vera sulla scrivania (pagina di Vera, riga di Vera sul telefono).
    case sferaVera
    /// La sfera di Vera nella barra (Mac): vale se quella della scrivania non c'è.
    case sferaVeraBarra
}

/// Chi riceve le richieste: la coda di una tela d'acqua.
protocol RicevitoreAcqua: AnyObject {
    func riceviAcqua(_ evento: EventoAcqua)
}

/// Il punto d'ingresso, sicuro da ogni thread.
///
///     RispostaAcqua.condivisa.goccia(in: puntoGlobale)                       // goccia del clic
///     RispostaAcqua.condivisa.goccia(su: .campanella, peso: Tema.Apple.Acqua.Goccia.pesoNotifica)
///     RispostaAcqua.condivisa.vibra(intorno: .sferaVera, durata: 4)          // Vera che parla
///     RispostaAcqua.condivisa.fermaVibrazioni()
///     RispostaAcqua.condivisa.gocciaAlCentro()                               // sblocco
final class RispostaAcqua {
    static let condivisa = RispostaAcqua()

    private struct Debole {
        weak var ricevitore: RicevitoreAcqua?
    }

    private struct Segno {
        let punto: PuntoAcqua
        var cornice: CGRect
        var ordine: Int
    }

    private let serratura = NSLock()
    private var consentitaOra = true
    private var ricevitori: [Debole] = []
    private var segni: [UUID: Segno] = [:]
    private var ordine = 0

    private init() {}

    // MARK: Chi può far cadere gocce

    /// «L'acqua della scrivania» accesa, sfondo animato, senza «Riduci movimento» e fuori dalle istantanee
    /// (lo imposta OsservatoreAcqua dalla shell). Spenta, ogni richiesta si lascia cadere e le vibrazioni si fermano.
    func consenti(_ si: Bool) {
        serratura.lock()
        let prima = consentitaOra
        consentitaOra = si
        serratura.unlock()
        if prima && !si { fermaVibrazioni() }
    }

    var consentita: Bool {
        serratura.lock()
        defer { serratura.unlock() }
        return consentitaOra
    }

    // MARK: Le richieste

    /// Una goccia nel punto (spazio globale di SwiftUI).
    func goccia(in punto: CGPoint, peso: Float = Tema.Apple.Acqua.Goccia.pesoTocco) {
        manda(.goccia(punto, peso: peso))
    }

    /// Una goccia al centro del punto segnato; false se quel punto non è sullo schermo.
    @discardableResult
    func goccia(su punto: PuntoAcqua, peso: Float) -> Bool {
        guard let c = cornice(di: punto) else { return false }
        goccia(in: CGPoint(x: c.midX, y: c.midY), peso: peso)
        return true
    }

    /// Una goccia al centro dell'acqua.
    func gocciaAlCentro(peso: Float = Tema.Apple.Acqua.Goccia.pesoSblocco) {
        manda(.gocciaAlCentro(peso: peso))
    }

    /// L'acqua vibra piano intorno al punto (spazio globale) per `durata` secondi.
    func vibra(intorno punto: CGPoint, durata: Double) {
        manda(.vibra(punto, durata: min(max(0, durata), Tema.Apple.Acqua.Vibrazione.durataMassima)))
    }

    /// L'acqua vibra intorno al punto segnato; false se quel punto non è sullo schermo.
    @discardableResult
    func vibra(intorno punto: PuntoAcqua, durata: Double) -> Bool {
        guard let c = cornice(di: punto) else { return false }
        vibra(intorno: CGPoint(x: c.midX, y: c.midY), durata: durata)
        return true
    }

    /// Smette di vibrare (passa sempre, anche con le gocce spente).
    func fermaVibrazioni() {
        for r in vivi() { r.riceviAcqua(.fermaVibrazioni) }
    }

    private func manda(_ e: EventoAcqua) {
        guard consentita else { return }
        for r in vivi() { r.riceviAcqua(e) }
    }

    // MARK: Tele d'acqua

    func registra(_ r: RicevitoreAcqua) {
        serratura.lock()
        ricevitori.removeAll { $0.ricevitore == nil || $0.ricevitore === r }
        ricevitori.append(Debole(ricevitore: r))
        serratura.unlock()
    }

    func togli(_ r: RicevitoreAcqua) {
        serratura.lock()
        ricevitori.removeAll { $0.ricevitore == nil || $0.ricevitore === r }
        serratura.unlock()
    }

    /// I ricevitori vivi, copiati sotto la serratura: si chiamano fuori, senza serrature annidate.
    private func vivi() -> [RicevitoreAcqua] {
        serratura.lock()
        let elenco = ricevitori.compactMap { $0.ricevitore }
        serratura.unlock()
        return elenco
    }

    // MARK: Punti segnati

    func segna(_ id: UUID, punto: PuntoAcqua, cornice: CGRect) {
        serratura.lock()
        if var s = segni[id] {
            s.cornice = cornice
            segni[id] = s
        } else {
            ordine += 1
            segni[id] = Segno(punto: punto, cornice: cornice, ordine: ordine)
        }
        serratura.unlock()
    }

    func cancella(_ id: UUID) {
        serratura.lock()
        segni[id] = nil
        serratura.unlock()
    }

    /// La cornice (spazio globale) dell'ultima vista comparsa con quel punto; nil se non c'è o è vuota.
    func cornice(di punto: PuntoAcqua) -> CGRect? {
        serratura.lock()
        defer { serratura.unlock() }
        var scelto: Segno?
        for s in segni.values where s.punto == punto && s.cornice.width > 0 && s.cornice.height > 0 {
            if let b = scelto, b.ordine > s.ordine { continue }
            scelto = s
        }
        return scelto?.cornice
    }
}

// MARK: - La coda di una tela d'acqua

/// Le richieste in attesa di una tela d'acqua (RendererAcqua sul Mac, RendererAcquaMobile su iPhone e iPad).
/// Il renderer dice dal thread principale dove sta la tela (`origine`, spazio globale) e se l'acqua si muove
/// (`accogli`); la coda del disegno prende le richieste a ogni fotogramma in moto (`prendi`). Serratura propria,
/// tenuta per poche istruzioni.
final class CodaRispostaAcqua: RicevitoreAcqua {
    private let serratura = NSLock()
    private var eventi: [EventoAcqua] = []
    private var origine = CGPoint.zero
    private var accoglie = false
    /// L'acqua si è fermata: alla ripartenza le vibrazioni di prima non riprendono.
    private var azzera = false

    init() {
        eventi.reserveCapacity(Tema.Apple.Acqua.eventiInCoda)
    }

    /// L'angolo in alto a sinistra della tela nello spazio globale di SwiftUI.
    func imposta(origine o: CGPoint) {
        serratura.lock()
        origine = o
        serratura.unlock()
    }

    /// true mentre l'acqua si muove: ferma, le richieste si lasciano cadere.
    func accogli(_ si: Bool) {
        serratura.lock()
        if accoglie && !si {
            eventi.removeAll(keepingCapacity: true)
            azzera = true
        }
        accoglie = si
        serratura.unlock()
    }

    func riceviAcqua(_ evento: EventoAcqua) {
        serratura.lock()
        if case .fermaVibrazioni = evento {
            azzera = true
        } else if accoglie && eventi.count < Tema.Apple.Acqua.eventiInCoda {
            eventi.append(evento)
        }
        serratura.unlock()
    }

    /// Dalla coda del disegno: le richieste in attesa, l'origine e se fermare le vibrazioni. Senza richieste
    /// non alloca niente.
    func prendi() -> (eventi: [EventoAcqua], origine: CGPoint, azzera: Bool) {
        serratura.lock()
        defer { serratura.unlock() }
        let a = azzera
        azzera = false
        guard !eventi.isEmpty else { return ([], origine, a) }
        let presi = eventi
        eventi.removeAll(keepingCapacity: true)
        return (presi, origine, a)
    }

    /// Dalla coda del disegno, dopo `fisica.misura`: applica le richieste in attesa alla fisica.
    func applica(a fisica: FisicaAcqua, lato: CGSize) {
        let (presi, o, a) = prendi()
        if a { fisica.fermaVibrazioni() }
        for e in presi {
            switch e {
            case let .goccia(p, peso: peso):
                fisica.goccia(x: Float(p.x - o.x), y: Float(p.y - o.y), peso: peso)
            case let .gocciaAlCentro(peso: peso):
                fisica.goccia(x: Float(lato.width / 2), y: Float(lato.height / 2), peso: peso)
            case let .vibra(p, durata: durata):
                fisica.vibra(x: Float(p.x - o.x), y: Float(p.y - o.y), durata: Float(durata))
            case .fermaVibrazioni:
                fisica.fermaVibrazioni()
            }
        }
    }
}

// MARK: - Viste

extension View {
    /// Segna la vista come un punto su cui l'acqua risponde (la campanella, la sfera di Vera).
    func puntoAcqua(_ punto: PuntoAcqua) -> some View {
        modifier(SegnoPuntoAcqua(punto: punto))
    }

    /// Un clic o un tocco sul fondo libero di questa vista fa cadere una goccia lì. Va sulla scrivania: lo strato sta
    /// dietro il contenuto, quindi widget, pulsanti e testi prendono i loro clic e solo il fondo libero arriva qui;
    /// barra, dock e finestre stanno sopra la scrivania e non ci arrivano mai. Un trascinamento non è un tocco
    /// (il gesto della pagina di Vera resta com'è).
    func gocciaAlTocco() -> some View {
        modifier(GocciaAlTocco())
    }
}

private struct SegnoPuntoAcqua: ViewModifier {
    let punto: PuntoAcqua
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { geo in
                let spazio: CoordinateSpace = .global
                let cornice = geo.frame(in: spazio)
                Color.clear
                    .onAppear { RispostaAcqua.condivisa.segna(id, punto: punto, cornice: cornice) }
                    .onChange(of: cornice) { nuova in RispostaAcqua.condivisa.segna(id, punto: punto, cornice: nuova) }
                    .onDisappear { RispostaAcqua.condivisa.cancella(id) }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

private struct GocciaAlTocco: ViewModifier {
    @Environment(\.modoIstantanea) private var modoIstantanea

    func body(content: Content) -> some View {
        let spazio: CoordinateSpace = .global
        let tocco = SpatialTapGesture(count: 1, coordinateSpace: spazio)
            .onEnded { valore in
                RispostaAcqua.condivisa.goccia(in: valore.location, peso: Tema.Apple.Acqua.Goccia.pesoTocco)
            }
        return content.background {
            Color.clear
                .contentShape(Rectangle())
                .gesture(tocco)
                .allowsHitTesting(!modoIstantanea)
                .accessibilityHidden(true)
        }
    }
}
