import SwiftUI

// Spunta che si disegna, lista «Ti preparo» e sequenza «Segna come fatto»
// (Design/template-apple-specifica.md §2.12, §2.13, §2.14).
// «Riduci movimento»: spunta già disegnata, voci spuntate tutte insieme con una dissolvenza breve,
// anello aggiornato senza brillio, scheda tolta con una dissolvenza.
// Istantanee: tutto nello stato finale, nessuna animazione e nessuna attesa.

// MARK: - Spunta che si disegna (§2.12)

/// Cerchio verde da ore 12 in 0,5 s, poi il segno in 0,35 s dopo 0,35 s (curva `uscita` per entrambi).
/// `progresso` (0…1) è il tempo del disegno: va animato in modo lineare (`Tema.Apple.Moto.Spunta.tracciato`),
/// le curve dei due tratti le applica la forma. Con `init(disegnata:)` la spunta si anima da sola.
struct SpuntaDisegnata: View {
    let progresso: Double
    var lato: CGFloat = Tema.Apple.Misura.Spunta.lato
    private let animataDaSola: Bool

    @Environment(\.prismaStatoFinale) private var fermo

    /// La spunta al punto `progresso` del disegno (l'animazione la dà chi la usa).
    init(progresso: Double, lato: CGFloat = Tema.Apple.Misura.Spunta.lato) {
        self.progresso = progresso
        self.lato = lato
        self.animataDaSola = false
    }

    /// La spunta che si disegna quando `disegnata` diventa vera (subito, con calma o in istantanea).
    init(disegnata: Bool, lato: CGFloat = Tema.Apple.Misura.Spunta.lato) {
        self.progresso = disegnata ? 1 : 0
        self.lato = lato
        self.animataDaSola = true
    }

    var body: some View {
        let m = Tema.Apple.Misura.Spunta.self
        let scala = lato / m.lato
        return ZStack {
            CerchioSpuntaApple(progresso: progresso)
                .stroke(Tema.Apple.Colore.verde, lineWidth: m.trattoCerchio * scala)
            SegnoSpuntaApple(progresso: progresso)
                .stroke(Tema.Apple.Colore.verde,
                        style: StrokeStyle(lineWidth: m.trattoSegno * scala, lineCap: .round, lineJoin: .round))
        }
        .frame(width: lato, height: lato)
        .modifier(TempoSpuntaApple(attivo: animataDaSola, fermo: fermo, progresso: progresso))
        .accessibilityHidden(true)
    }
}

/// Con `init(disegnata:)` la spunta segue da sola il tempo del disegno (o nessuno, se ferma).
private struct TempoSpuntaApple: ViewModifier {
    let attivo: Bool
    let fermo: Bool
    let progresso: Double

    @ViewBuilder func body(content: Content) -> some View {
        if attivo {
            content.animation(fermo ? nil : Tema.Apple.Moto.Spunta.tracciato, value: progresso)
        } else {
            content
        }
    }
}

/// Tempo del disegno (0…1) → frazione di un tratto che dura `durata` e parte dopo `ritardo`, con la curva `uscita`.
private func trattoSpuntaApple(_ progresso: Double, ritardo: Double, durata: Double) -> Double {
    let s = Tema.Apple.Moto.Spunta.self
    let tempo = progresso * s.durataTotale
    let t = (tempo - ritardo) / durata
    return Tema.Apple.Moto.Curva.uscita.valore(t)
}

/// Il cerchio (raggio 30 su 72), da ore 12 in senso orario.
private struct CerchioSpuntaApple: Shape {
    var progresso: Double

    var animatableData: Double {
        get { progresso }
        set { progresso = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let m = Tema.Apple.Misura.Spunta.self
        let s = Tema.Apple.Moto.Spunta.self
        let fatto = trattoSpuntaApple(progresso, ritardo: 0, durata: s.durataCerchio)
        guard fatto > 0 else { return Path() }
        let scala = min(rect.width, rect.height) / m.lato
        let centro = CGPoint(x: rect.midX, y: rect.midY)
        let r = m.raggio * scala
        let cerchio = Path(ellipseIn: CGRect(x: centro.x - r, y: centro.y - r, width: 2 * r, height: 2 * r))
        // Path(ellipseIn:) parte da ore 3 in senso orario: si ruota di −90° attorno al centro.
        let giro = CGAffineTransform(translationX: centro.x, y: centro.y)
            .rotated(by: -.pi / 2)
            .translatedBy(x: -centro.x, y: -centro.y)
        return cerchio.trimmedPath(from: 0, to: CGFloat(min(fatto, 1))).applying(giro)
    }
}

/// Il segno `M23 37 l9 9 l17 −19` su 72.
private struct SegnoSpuntaApple: Shape {
    var progresso: Double

    var animatableData: Double {
        get { progresso }
        set { progresso = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let m = Tema.Apple.Misura.Spunta.self
        let s = Tema.Apple.Moto.Spunta.self
        let fatto = trattoSpuntaApple(progresso, ritardo: s.ritardoSegno, durata: s.durataSegno)
        guard fatto > 0 else { return Path() }
        let scala = min(rect.width, rect.height) / m.lato
        let origine = CGPoint(x: rect.midX - m.lato * scala / 2, y: rect.midY - m.lato * scala / 2)
        var segno = Path()
        segno.addLines(m.segno.map { CGPoint(x: origine.x + $0.x * scala, y: origine.y + $0.y * scala) })
        return segno.trimmedPath(from: 0, to: CGFloat(min(fatto, 1)))
    }
}

// MARK: - Lista «Ti preparo» (§2.13)

/// Le voci si spuntano una alla volta (voce i a 0,22 + i·0,36 s, molla di 0,35 s); `poi` arriva a
/// 0,32 + n·0,36 s, quando tutte sono spuntate (per il toast «Fascicolo per <nome> pronto in Prospetti»).
/// `pronte` dice quante voci il motore ha davvero preparato: una voce non si spunta prima di essere pronta,
/// e il ritmo da 0,36 s resta il minimo visivo. nil = tutte pronte.
struct ListaTiPreparo: View {
    var titolo: String = "Ti preparo"
    let voci: [String]
    let avviata: Bool
    var pronte: Int? = nil
    var poi: () -> Void = {}

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var inizio: Date?
    /// Diventa vera subito dopo l'avvio: così anche una lista che nasce già avviata parte vuota e si spunta
    /// al ritmo (in istantanea invece è subito completa).
    @State private var partita = false
    @State private var annunciata = false
    @State private var giro = 0

    init(titolo: String = "Ti preparo", voci: [String], avviata: Bool, pronte: Int? = nil,
         poi: @escaping () -> Void = {}) {
        self.titolo = titolo
        self.voci = voci
        self.avviata = avviata
        self.pronte = pronte
        self.poi = poi
    }

    private var quantePronte: Int { min(pronte ?? voci.count, voci.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titolo)
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .padding(.bottom, Tema.Apple.Misura.TiPreparo.sottoTitolo)
            ForEach(Array(voci.enumerated()), id: \.offset) { i, voce in
                VoceTiPreparoApple(testo: voce, fatta: (partita || istantanea) && avviata && i < quantePronte,
                                   animazione: animazione(indice: i))
            }
        }
        .onAppear { if avviata { avvia() } }
        .onChange(of: avviata) { acceso in
            if acceso { avvia() } else { ferma() }
        }
        .onChange(of: quantePronte) { _ in programmaAnnuncio() }
    }

    /// Secondi passati dall'avvio (0 se non è ancora partita).
    private var trascorso: Double {
        guard let inizio else { return 0 }
        return Date().timeIntervalSince(inizio)
    }

    /// La molla della voce i, con il ritardo che le resta; dissolvenza con calma, nessuna in istantanea.
    private func animazione(indice i: Int) -> Animation? {
        let m = Tema.Apple.Moto.TiPreparo.self
        if istantanea { return nil }
        if calmo { return Tema.Moto.dissolvenzaCalma }
        let resto = max(0, m.ritardo(indice: i) - trascorso)
        return m.ripiego.animazione.delay(resto)
    }

    private func avvia() {
        guard inizio == nil else { return }
        inizio = Date()
        partita = true
        annunciata = false
        programmaAnnuncio()
    }

    private func ferma() {
        inizio = nil
        partita = false
        annunciata = false
        giro += 1
    }

    /// `poi` una volta sola, quando tutte le voci sono pronte e il ritmo è arrivato in fondo.
    private func programmaAnnuncio() {
        guard avviata, !annunciata, quantePronte >= voci.count, !istantanea else { return }
        let attesa = Tema.Apple.Moto.ritardo(Tema.Apple.Moto.TiPreparo.ritardoToast(voci: voci.count) - trascorso,
                                             calmo: calmo)
        annunciata = true
        let questo = giro
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, attesa)) {
            guard giro == questo else { return }
            poi()
        }
    }
}

/// Una riga della lista: cerchietto (vuoto o verde con la spunta bianca) e testo.
private struct VoceTiPreparoApple: View {
    let testo: String
    let fatta: Bool
    let animazione: Animation?

    var body: some View {
        let m = Tema.Apple.Misura.TiPreparo.self
        return HStack(spacing: m.spazio) {
            cerchietto
            Text(testo)
                .carattereApple(Tema.Apple.Carattere.voceLista)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            Spacer(minLength: 0)
        }
        .padding(.vertical, m.paddingRiga)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Tema.Apple.Colore.separatore)
                .frame(height: Tema.Apple.Misura.bordo)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(testo))
        .accessibilityValue(Text(fatta ? "pronto" : "in preparazione"))
    }

    private var cerchietto: some View {
        let m = Tema.Apple.Misura.TiPreparo.self
        let c = Tema.Apple.Colore.self
        return ZStack {
            Circle().fill(fatta ? c.verde : Color.clear)
            Circle().strokeBorder(fatta ? c.verde : c.binario, lineWidth: m.bordoCerchietto)
            SpuntaPiccolaApple()
                .stroke(c.spuntaSuVerde, style: StrokeStyle(lineWidth: m.spuntaTratto, lineCap: .butt, lineJoin: .miter))
                .opacity(fatta ? 1 : 0)
        }
        .frame(width: m.cerchietto, height: m.cerchietto)
        .scaleEffect(fatta ? Tema.Apple.Moto.TiPreparo.scalaFatta : 1)
        .animation(animazione, value: fatta)
    }
}

/// La spunta bianca del cerchietto: i bordi sinistro e inferiore di un riquadro 8×4, ruotati di −45° (anche nel
/// verbale del copilota, Shell/VerbaleCopilota.swift).
struct SpuntaPiccolaApple: Shape {
    func path(in rect: CGRect) -> Path {
        let m = Tema.Apple.Misura.TiPreparo.self
        let w = m.spuntaLarghezza
        let h = m.spuntaAltezza
        let mezzo = m.spuntaTratto / 2
        // Il riquadro centrato nel cerchietto; il tratto corre a metà del bordo CSS.
        let x0 = rect.midX - w / 2
        let y0 = rect.midY - h / 2
        var p = Path()
        p.move(to: CGPoint(x: x0 + mezzo, y: y0))
        p.addLine(to: CGPoint(x: x0 + mezzo, y: y0 + h - mezzo))
        p.addLine(to: CGPoint(x: x0 + w, y: y0 + h - mezzo))
        // CSS: rotate(−45°) translate(1px, −1px) attorno al centro.
        let giro = CGAffineTransform(translationX: rect.midX, y: rect.midY)
            .rotated(by: CGFloat(m.spuntaRotazione * .pi / 180))
            .translatedBy(x: m.spuntaScostamento, y: -m.spuntaScostamento)
            .translatedBy(x: -rect.midX, y: -rect.midY)
        return p.applying(giro)
    }
}

// MARK: - «Segna come fatto» (§2.14)

/// A che punto è una scheda segnata come fatta.
enum FaseFatto: Int, Comparable {
    /// Nessuna sequenza in corso.
    case inAttesa
    /// t0: spunta e velo verde.
    case spuntata
    /// t0 + 0,6: l'anello collegato sale e brilla.
    case anello
    /// t0 + 1,15: la scheda si stringe e le altre scorrono al suo posto.
    case stretta

    static func < (a: FaseFatto, b: FaseFatto) -> Bool { a.rawValue < b.rawValue }
}

/// La sequenza «Segna come fatto» per le schede di una schermata (una sola istanza, `@StateObject`).
/// Chi la usa chiude il dettaglio, chiama `segna(_:…)` e mette `.schedaFatta(sequenza.fase(id), larghezza:)`
/// sulla scheda; l'anello collegato brilla passando `impulsoBrillio: sequenza.impulsoBrillio` (e `brilla:` con
/// l'anello giusto) ad `AnelliConcentrici` o `Anello` (AnelliApple.swift).
/// Le richiamate fanno il lavoro vero: `anello` fa salire l'anello di 1 (e la legenda conta in 0,9 s con
/// `NumeroCheConta`), `stringi` mostra il toast «<nome>: fatto», `togli` toglie la scheda dal modello.
final class SequenzaFatto<ID: Hashable>: ObservableObject {
    @Published private(set) var fasi: [ID: FaseFatto] = [:]
    /// Cresce di 1 quando l'anello sale (t0 + 0,6), per far brillare l'anello collegato.
    /// Con calma e in istantanea non cambia: l'anello si aggiorna senza brillio.
    @Published private(set) var impulsoBrillio = 0

    private var generazioni: [ID: Int] = [:]

    init() {}

    func fase(_ id: ID) -> FaseFatto { fasi[id] ?? .inAttesa }

    /// Avvia la sequenza per la scheda `id`.
    /// - Parameter attesa: secondi prima della spunta (es. `Tema.Apple.Moto.DettaglioChiude.durata`
    ///   se il dettaglio si sta chiudendo in quel momento).
    func segna(_ id: ID, calmo: Bool, istantanea: Bool, attesa: Double = 0,
               anello: @escaping () -> Void,
               stringi: @escaping () -> Void = {},
               togli: @escaping () -> Void) {
        let f = Tema.Apple.Moto.Fatto.self
        let generazione = (generazioni[id] ?? 0) + 1
        generazioni[id] = generazione

        if istantanea {
            anello()
            stringi()
            togli()
            fasi[id] = nil
            return
        }

        let t0 = max(0, attesa)
        dopo(t0, id, generazione) { $0.fasi[id] = .spuntata }
        dopo(t0 + f.anello, id, generazione) { sequenza in
            sequenza.fasi[id] = .anello
            anello()
            if !calmo { sequenza.impulsoBrillio += 1 }
        }
        dopo(t0 + f.stringe, id, generazione) { sequenza in
            sequenza.fasi[id] = .stretta
            stringi()
        }
        dopo(t0 + f.stringe + f.tolta, id, generazione) { sequenza in
            togli()
            sequenza.fasi[id] = nil
            sequenza.generazioni[id] = nil
        }
    }

    /// Ferma la sequenza della scheda (per esempio se la schermata si chiude) e la riporta com'era.
    func annulla(_ id: ID) {
        generazioni[id] = nil
        fasi[id] = nil
    }

    private func dopo(_ secondi: Double, _ id: ID, _ generazione: Int, _ fai: @escaping (SequenzaFatto) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + secondi) { [weak self] in
            guard let self, self.generazioni[id] == generazione else { return }
            fai(self)
        }
    }
}

extension View {
    /// La scheda nella sequenza «fatto»: velo verde e spunta che si disegna, poi si stringe (larghezza 0,
    /// margine −14, scala 0,85, opacità 0) e le altre schede dell'HStack scorrono al suo posto.
    /// `larghezza` è quella della scheda a riposo (serve per stringerla).
    func schedaFatta(_ fase: FaseFatto, larghezza: CGFloat,
                     raggio: CGFloat = Tema.Apple.Raggio.card) -> some View {
        modifier(SchedaFattaApple(fase: fase, larghezza: larghezza, raggio: raggio))
    }
}

private struct SchedaFattaApple: ViewModifier {
    let fase: FaseFatto
    let larghezza: CGFloat
    let raggio: CGFloat

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        let spuntata = fase >= .spuntata
        let stretta = fase >= .stretta
        let f = Tema.Apple.Moto.Fatto.self
        return content
            .overlay { velo(spuntata) }
            .scaleEffect(stretta && !calmo ? f.scala : 1)
            .animation(animazione(f.trasformazione), value: stretta)
            .opacity(stretta ? 0 : 1)
            .animation(animazione(f.opacita), value: stretta)
            .modifier(LarghezzaFattoApple(stretta: stretta ? 1 : 0, larghezza: larghezza))
            .animation(animazione(f.larghezza), value: stretta)
            .allowsHitTesting(!stretta)
    }

    private func velo(_ spuntata: Bool) -> some View {
        let s = Tema.Apple.Moto.Spunta.self
        return ZStack {
            RoundedRectangle(cornerRadius: raggio, style: .continuous)
                .fill(Tema.Apple.Colore.veloFatto)
                .opacity(spuntata ? 1 : 0)
                .animation(animazione(s.velo), value: spuntata)
            SpuntaDisegnata(disegnata: spuntata)
        }
        .allowsHitTesting(false)
    }

    /// Istantanea: nessuna. Calmo: dissolvenza (e restringimento lineare) di 0,15 s, senza scala né superamento.
    private func animazione(_ a: Animation) -> Animation? {
        Tema.Apple.Moto.animazione(a, calmo: calmo, istantanea: istantanea)
    }
}

/// Larghezza e margine sinistro della scheda che si stringe (0 = a riposo, 1 = stretta).
/// La larghezza non scende mai sotto 0 anche se la molla supera il traguardo.
private struct LarghezzaFattoApple: ViewModifier, Animatable {
    var stretta: Double
    let larghezza: CGFloat

    var animatableData: Double {
        get { stretta }
        set { stretta = newValue }
    }

    func body(content: Content) -> some View {
        let p = CGFloat(min(max(stretta, 0), 1))
        return content
            .frame(width: max(0, larghezza * (1 - p)), alignment: .leading)
            .padding(.leading, Tema.Apple.Moto.Fatto.margine * p)
    }
}
