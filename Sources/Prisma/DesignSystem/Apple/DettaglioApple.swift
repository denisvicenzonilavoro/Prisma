import SwiftUI

// Dettaglio che nasce dall'elemento (Design/template-apple-specifica.md §2.7).
// L'elemento toccato (`.origineDettaglio(id:)`) si nasconde e al suo posto si apre un contenitore pieno
// (`cardPiena`, bordo, ombra `dettaglio`, raggio 22) che anima posizione e misure fino al rettangolo W×H
// centrato nell'area contenuto, con il raggio che arriva a 28: 0,62 s con la curva `(0.32,1.22,0.5,1)`.
// Il contenuto ha da subito la misura finale, ancorato in alto a sinistra e ritagliato: si monta a 0,17 s
// (partono numeri, anelli, linee e barre) e compare in 0,35 s da 0,33 s. Il velo entra in 0,45 s e il resto
// si sfoca dietro con UNA sola sfocatura (10), messa sul contenuto del presentatore.
// Chiusura (✕, Esc, clic sul velo): il contenitore torna al rettangolo attuale dell'origine (rimisurato)
// in 0,46 s con `(0.32,1.08,0.5,1)`, il contenuto svanisce in 0,2 s, poi l'origine ricompare e parte `poi`.
// Un solo dettaglio alla volta. Niente `matchedGeometryEffect`: il contenuto non deve rifluire mentre il
// contenitore cresce, quindi si anima un rettangolo (un solo `progresso` 0 → 1 fra le due cornici).
// «Riduci movimento»: il contenitore compare già al centro, in dissolvenza di 0,15 s, col contenuto visibile.
// Istantanee: il dettaglio aperto, a misura piena, subito.
// Prestazioni: a dettaglio chiuso non c'è niente montato (né ombra né contenuto) e la sfocatura vale 0;
// l'ombra esatta usa sempre il raggio finale, così la bitmap pronta non si ridisegna a ogni fotogramma.

/// Lo stato del dettaglio di una finestra: chi è aperto e a che punto è l'animazione.
final class StatoDettaglio: ObservableObject {
    /// Come si muove (lo imposta il presentatore dall'ambiente).
    fileprivate enum Modo { case animato, calmo, istantaneo }

    /// L'id dell'elemento da cui è nato il dettaglio aperto (nil = chiuso).
    @Published private(set) var idAperto: String?
    /// La misura W×H chiesta all'apertura.
    @Published private(set) var misura: CGSize = Tema.Apple.Misura.DettaglioAperto.predefinito
    /// 0 = sulla cornice dell'origine, 1 = al centro.
    @Published fileprivate private(set) var progresso: Double = 0
    @Published fileprivate private(set) var contenitoreVisibile = false
    @Published fileprivate private(set) var contenutoMontato = false
    @Published fileprivate private(set) var contenutoVisibile = false
    @Published fileprivate private(set) var veloAcceso = false

    fileprivate var modo: Modo = .animato
    private var chiudendo = false
    /// Le `poi` in attesa della fine della chiusura: nessuna si perde se arriva una seconda chiusura
    /// (per esempio «Segna come fatto» seguito da un cambio app che chiude subito).
    private var dopoChiusura: [() -> Void] = []
    /// Cresce a ogni apertura e chiusura: le chiamate in ritardo di un giro vecchio non fanno niente.
    private var giro = 0

    /// true se un dettaglio è aperto (anche mentre si apre o si chiude).
    var aperto: Bool { idAperto != nil }

    init() {}

    /// Già aperto, a misura piena (istantanee e anteprime).
    init(aperto id: String, misura: CGSize = Tema.Apple.Misura.DettaglioAperto.predefinito) {
        idAperto = id
        self.misura = misura
        progresso = 1
        contenitoreVisibile = true
        contenutoMontato = true
        contenutoVisibile = true
        veloAcceso = true
    }

    /// Apre il dettaglio nato dall'elemento `id` (`.origineDettaglio(id:)`). Ignorato se uno è già aperto.
    /// Misure: `Tema.Apple.Misura.DettaglioAperto`.
    func apri(_ id: String, misura: CGSize = Tema.Apple.Misura.DettaglioAperto.predefinito) {
        guard idAperto == nil else { return }
        giro += 1
        chiudendo = false
        switch modo {
        case .istantaneo:
            senzaAnimazione {
                idAperto = id
                self.misura = misura
                progresso = 1
                contenitoreVisibile = true
                contenutoMontato = true
                contenutoVisibile = true
                veloAcceso = true
            }
        case .calmo:
            senzaAnimazione {
                idAperto = id
                self.misura = misura
                progresso = 1
                contenutoMontato = true
            }
            withAnimation(Tema.Moto.dissolvenzaCalma) {
                contenitoreVisibile = true
                contenutoVisibile = true
                veloAcceso = true
            }
        case .animato:
            apriAnimato(id, misura: misura)
        }
    }

    private func apriAnimato(_ id: String, misura: CGSize) {
        let a = Tema.Apple.Moto.DettaglioApre.self
        let g = giro
        senzaAnimazione {
            idAperto = id
            self.misura = misura
            contenitoreVisibile = true
        }
        withAnimation(a.animazione) { progresso = 1 }
        withAnimation(Tema.Apple.Moto.Velo.animazione) { veloAcceso = true }
        withAnimation(a.animazioneContenuto.delay(a.ritardoContenuto)) { contenutoVisibile = true }
        Movimenti.dopo(a.avvioContenuto) { [weak self] in
            guard let self, self.giro == g else { return }
            self.contenutoMontato = true
        }
    }

    /// Chiude il dettaglio. `subito`: senza animazione (cambio app, blocco, «Apri il dossier»).
    /// `poi` parte quando l'origine è ricomparsa (es. «Segna come fatto»); subito se niente è aperto.
    func chiudi(subito: Bool = false, poi: (() -> Void)? = nil) {
        guard idAperto != nil else {
            poi?()
            return
        }
        if let poi { dopoChiusura.append(poi) }
        guard !chiudendo || subito else { return }
        giro += 1
        let g = giro
        if subito || modo == .istantaneo {
            azzera()
            eseguiDopoChiusura()
            return
        }
        chiudendo = true
        let durata: Double
        if modo == .calmo {
            durata = Tema.Apple.Moto.durataCalma
            withAnimation(Tema.Moto.dissolvenzaCalma) {
                contenitoreVisibile = false
                contenutoVisibile = false
                veloAcceso = false
            }
        } else {
            let c = Tema.Apple.Moto.DettaglioChiude.self
            durata = c.durata
            withAnimation(c.animazione) { progresso = 0 }
            withAnimation(c.animazioneContenuto) { contenutoVisibile = false }
            withAnimation(Tema.Apple.Moto.Velo.animazione) { veloAcceso = false }
        }
        Movimenti.dopo(durata) { [weak self] in
            guard let self, self.giro == g else { return }
            self.azzera()
            self.eseguiDopoChiusura()
        }
    }

    private func eseguiDopoChiusura() {
        let attese = dopoChiusura
        dopoChiusura = []
        attese.forEach { $0() }
    }

    private func azzera() {
        senzaAnimazione {
            idAperto = nil
            progresso = 0
            contenitoreVisibile = false
            contenutoMontato = false
            contenutoVisibile = false
            veloAcceso = false
        }
        chiudendo = false
    }

    private func senzaAnimazione(_ cambia: () -> Void) {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t, cambia)
    }

    fileprivate func impostaModo(calmo: Bool, istantanea: Bool) {
        modo = istantanea ? .istantaneo : (calmo ? .calmo : .animato)
    }
}

// MARK: - Ambiente e origini

private struct ChiaveStatoDettaglioApple: EnvironmentKey {
    static let defaultValue: StatoDettaglio? = nil
}

extension EnvironmentValues {
    /// Il dettaglio della finestra (lo mette `.presentatoreDettaglio`): lo legge `.origineDettaglio(id:)`.
    var statoDettaglioApple: StatoDettaglio? {
        get { self[ChiaveStatoDettaglioApple.self] }
        set { self[ChiaveStatoDettaglioApple.self] = newValue }
    }
}

/// Le cornici delle origini, per id: si risolvono nello spazio del presentatore al momento del disegno,
/// quindi alla chiusura il contenitore torna sempre alla cornice attuale.
private struct ChiaveOriginiDettaglio: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, nuovo in nuovo })
    }
}

extension View {
    /// Segna l'elemento da cui nasce il dettaglio `id` (va dentro un `.presentatoreDettaglio`).
    /// Mentre il suo dettaglio è aperto l'elemento è nascosto.
    func origineDettaglio(id: String) -> some View {
        modifier(OrigineDettaglioApple(id: id))
    }

    /// Mette sopra questa vista il dettaglio che nasce dagli elementi `.origineDettaglio(id:)` che contiene.
    /// `area`: rientri dell'area in cui il dettaglio si centra (in una finestra intera
    /// `Tema.Apple.Misura.DettaglioAperto.areaFinestra`; zero se la vista è già l'area contenuto).
    /// Il velo e la sfocatura coprono tutta la vista: va messo sul contenuto della finestra, non sul suo vetro.
    func presentatoreDettaglio<Dettaglio: View>(_ stato: StatoDettaglio,
                                                area: EdgeInsets = EdgeInsets(),
                                                @ViewBuilder dettaglio: @escaping (String) -> Dettaglio) -> some View {
        modifier(ModificatorePresentatoreDettaglio(stato: stato, area: area, dettaglio: dettaglio))
    }
}

/// Il modificatore di `.origineDettaglio(id:)`.
struct OrigineDettaglioApple: ViewModifier {
    let id: String
    @Environment(\.statoDettaglioApple) private var stato

    func body(content: Content) -> some View {
        nascosta(content)
            .anchorPreference(key: ChiaveOriginiDettaglio.self, value: .bounds) { [id: $0] }
    }

    @ViewBuilder private func nascosta(_ content: Content) -> some View {
        if let stato {
            content.modifier(NascondiOrigineApple(id: id, stato: stato))
        } else {
            content
        }
    }
}

private struct NascondiOrigineApple: ViewModifier {
    let id: String
    @ObservedObject var stato: StatoDettaglio

    func body(content: Content) -> some View {
        let nascosta = stato.idAperto == id
        return content
            .environment(\.inclinazioneSospesaApple, nascosta)
            .opacity(nascosta ? 0 : 1)
            .allowsHitTesting(!nascosta)
            .accessibilityHidden(nascosta)
    }
}

// MARK: - Presentatore

/// Il contenuto con sopra il dettaglio: la forma a vista di `.presentatoreDettaglio(_:area:dettaglio:)`.
struct PresentatoreDettaglio<Contenuto: View, Dettaglio: View>: View {
    let stato: StatoDettaglio
    var area = EdgeInsets()
    let contenuto: Contenuto
    let dettaglio: (String) -> Dettaglio

    init(stato: StatoDettaglio, area: EdgeInsets = EdgeInsets(),
         @ViewBuilder contenuto: () -> Contenuto,
         @ViewBuilder dettaglio: @escaping (String) -> Dettaglio) {
        self.stato = stato
        self.area = area
        self.contenuto = contenuto()
        self.dettaglio = dettaglio
    }

    var body: some View {
        contenuto.presentatoreDettaglio(stato, area: area, dettaglio: dettaglio)
    }
}

/// Il modificatore di `.presentatoreDettaglio(_:area:dettaglio:)`.
struct ModificatorePresentatoreDettaglio<Dettaglio: View>: ViewModifier {
    @ObservedObject var stato: StatoDettaglio
    let area: EdgeInsets
    let dettaglio: (String) -> Dettaglio

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.colorScheme) private var schema

    /// Nelle istantanee il dettaglio aperto è già nello stato finale, qualunque sia la fase.
    private var finale: Bool { istantanea && stato.aperto }

    func body(content: Content) -> some View {
        let velo = finale || stato.veloAcceso
        return content
            .blur(radius: velo ? Tema.Apple.Moto.Velo.sfocatura : 0)
            .overlayPreferenceValue(ChiaveOriginiDettaglio.self) { origini in
                GeometryReader { g in
                    strato(origini: origini, geo: g)
                }
            }
            .environment(\.statoDettaglioApple, stato)
            .onAppear(perform: aggiornaModo)
            .onChange(of: calmo) { _ in aggiornaModo() }
            .onChange(of: istantanea) { _ in aggiornaModo() }
    }

    private func aggiornaModo() {
        stato.impostaModo(calmo: calmo, istantanea: istantanea)
    }

    private func strato(origini: [String: Anchor<CGRect>], geo: GeometryProxy) -> some View {
        let fine = rettangoloFinale(in: geo.size)
        let ancora = stato.idAperto.flatMap { origini[$0] }
        // Se l'origine non c'è più, il contenitore nasce e torna al centro.
        let origine = ancora.map { geo[$0] } ?? fine
        return ZStack(alignment: .topLeading) {
            VeloDettaglioApple(acceso: finale || stato.veloAcceso) { stato.chiudi() }
            CorniceDettaglioApple(progresso: finale ? 1 : stato.progresso,
                                  origine: origine, fine: fine,
                                  presente: stato.aperto, scuro: schema == .dark,
                                  interno: interno(fine: fine))
                .opacity(finale || stato.contenitoreVisibile ? 1 : 0)
                .allowsHitTesting(stato.aperto)
        }
        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        // A dettaglio chiuso lo strato non prende clic: passano tutti al contenuto.
        .allowsHitTesting(stato.aperto)
    }

    /// Contenuto a misura finale, ancorato in alto a sinistra, con il ✕ a 22 dall'alto e da destra.
    private func interno(fine: CGRect) -> some View {
        let montato = finale || stato.contenutoMontato
        let margineChiudi = Tema.Apple.Misura.Padding.chiudiDettaglio
        return ZStack(alignment: .topTrailing) {
            if let id = stato.idAperto, montato {
                dettaglio(id)
                    .padding(Tema.Apple.Misura.Padding.dettaglio)
                    .frame(width: fine.width, height: fine.height, alignment: .topLeading)
            }
            if stato.aperto {
                PulsanteChiudiDettaglioApple { stato.chiudi() }
                    .padding(.top, margineChiudi)
                    .padding(.trailing, margineChiudi)
            }
        }
        .frame(width: fine.width, height: fine.height, alignment: .topLeading)
        .opacity(finale || stato.contenutoVisibile ? 1 : 0)
    }

    /// W×H centrato nell'area (ridotto se l'area è più piccola).
    private func rettangoloFinale(in misura: CGSize) -> CGRect {
        let larghezza = max(misura.width - area.leading - area.trailing, 0)
        let altezza = max(misura.height - area.top - area.bottom, 0)
        let w = min(stato.misura.width, larghezza)
        let h = min(stato.misura.height, altezza)
        return CGRect(x: area.leading + (larghezza - w) / 2, y: area.top + (altezza - h) / 2,
                      width: w, height: h)
    }
}

/// Il velo sotto il dettaglio: colore `velo`; un clic chiude.
private struct VeloDettaglioApple: View {
    let acceso: Bool
    let chiudi: () -> Void

    var body: some View {
        Tema.Apple.Colore.velo
            .opacity(acceso ? 1 : 0)
            .contentShape(Rectangle())
            .onTapGesture(perform: chiudi)
            .allowsHitTesting(acceso)
            .accessibilityHidden(true)
    }
}

/// Il contenitore che cresce dalla cornice dell'origine (progresso 0) a quella finale (1), con il raggio
/// da 22 a 28. Il contenuto resta a misura finale e viene solo ritagliato.
private struct CorniceDettaglioApple<Interno: View>: View, Animatable {
    var progresso: Double
    let origine: CGRect
    let fine: CGRect
    let presente: Bool
    let scuro: Bool
    let interno: Interno

    var animatableData: Double {
        get { progresso }
        set { progresso = newValue }
    }

    var body: some View {
        let p = CGFloat(progresso)
        let r = CGRect(x: origine.minX + (fine.minX - origine.minX) * p,
                       y: origine.minY + (fine.minY - origine.minY) * p,
                       width: max(origine.width + (fine.width - origine.width) * p, 0),
                       height: max(origine.height + (fine.height - origine.height) * p, 0))
        let a = Tema.Apple.Moto.DettaglioApre.self
        let raggio = a.raggioIniziale + (a.raggioFinale - a.raggioIniziale) * p
        let forma = RoundedRectangle(cornerRadius: max(raggio, 0), style: .continuous)
        return ZStack(alignment: .topLeading) {
            if presente { interno }
        }
        .frame(width: r.width, height: r.height, alignment: .topLeading)
        .background { fondo(forma) }
        .clipShape(forma)
        .overlay { bordo(forma) }
        .background { ombra }
        .offset(x: r.minX, y: r.minY)
        .accessibilityAddTraits(presente ? .isModal : [])
    }

    @ViewBuilder private func fondo(_ forma: RoundedRectangle) -> some View {
        if presente { forma.fill(Tema.Apple.Colore.cardPiena) }
    }

    @ViewBuilder private func bordo(_ forma: RoundedRectangle) -> some View {
        if presente {
            forma.strokeBorder(Tema.Apple.Colore.separatore, lineWidth: Tema.Apple.Misura.bordo)
                .allowsHitTesting(false)
        }
    }

    /// Ombra esatta `dettaglio` col raggio finale fisso: la bitmap pronta non cambia durante l'animazione.
    @ViewBuilder private var ombra: some View {
        if presente {
            OmbraVetroPronta(raggio: Tema.Apple.Moto.DettaglioApre.raggioFinale,
                             strati: Tema.Apple.Ombra.dettaglio.strati(scuro: scuro),
                             misuraEsatta: false)
        }
    }
}

/// ✕ del dettaglio (`.btn`, padding 7×11); Esc lo preme.
private struct PulsanteChiudiDettaglioApple: View {
    let azione: () -> Void

    var body: some View {
        Button(action: azione) {
            Image(systemName: "xmark")
                .font(Tema.Apple.Carattere.pulsante.font)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .padding(Tema.Apple.Misura.DettaglioAperto.paddingChiudi)
                .background { Capsule(style: .continuous).fill(Tema.Apple.Colore.cardPiena) }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Tema.Apple.Colore.separatore, lineWidth: Tema.Apple.Misura.bordo)
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
        .accessibilityLabel("Chiudi")
    }
}
