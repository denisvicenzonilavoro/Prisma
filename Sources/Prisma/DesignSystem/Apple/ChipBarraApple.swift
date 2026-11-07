import SwiftUI

// Due componenti del tema Apple nati con la prova del fuoco (Design/template-novita-specifica.md §6.2, §6.3):
// - ChipApple: la pillola selezionabile degli scenari (`.chip`, accesa in rosso). Servirà anche altrove.
// - BarraOggiDopo: binario, barra chiara (oggi) e barra piena (dopo lo scenario) che si accorcia con la curva
//   `uscita` in 0,8 s e cambia colore in 0,5 s.
// «Riduci movimento»: niente sollevamento, la barra compare già al valore «dopo» e i cambi sono la dissolvenza di
// 0,15 s. Istantanee: stato finale subito, nessuna animazione. Gettoni in Tema.Apple+ProvaFuoco.swift.

// MARK: - Chip

/// Pillola a capsula con il testo 13 semibold: spenta `cardPiena` con il filo, accesa rossa con il testo bianco.
/// Sotto il puntatore si solleva di 2 con la molla di 0,35 s. Un clic sulla chip accesa non fa nulla.
///
///     ChipApple(titolo: "Mercati −25%", accesa: scelta == .mercati) { scelta = .mercati }
struct ChipApple: View {
    let titolo: String
    let accesa: Bool
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.isEnabled) private var abilitato
    @State private var sopra = false

    init(titolo: String, accesa: Bool, azione: @escaping () -> Void) {
        self.titolo = titolo
        self.accesa = accesa
        self.azione = azione
    }

    var body: some View {
        let c = Tema.Apple.Posizioni.Fuoco.Chip.self
        let forma = Capsule(style: .continuous)
        return Text(titolo)
            .carattereApple(c.carattere)
            .foregroundColor(accesa ? c.testoAcceso : c.testo)
            .lineLimit(1)
            .fixedSize()
            .padding(c.padding)
            .background {
                forma.fill(accesa ? c.fondoAcceso : c.fondo)
                    .overlay {
                        forma.strokeBorder(accesa ? Color.clear : c.bordo, lineWidth: c.spessoreBordo)
                    }
            }
            .contentShape(forma)
            .offset(y: sollevata ? c.sollevamento : 0)
            .animation(animazione, value: accesa)
            .animation(animazione, value: sollevata)
            .opacity(abilitato ? 1 : Tema.Apple.Controlli.opacitaDisattivato)
            .onHover { dentro in sopra = dentro && abilitato && !istantanea }
            .onTapGesture { scegli() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(titolo))
            .accessibilityAddTraits(accesa ? Self.trattiAccesa : Self.trattiSpenta)
            .accessibilityAction { scegli() }
    }

    private var sollevata: Bool { sopra && !calmo && !istantanea }

    private func scegli() {
        guard abilitato, !accesa else { return }
        azione()
    }

    private static var trattiSpenta: AccessibilityTraits { .isButton }
    private static var trattiAccesa: AccessibilityTraits { [.isButton, .isSelected] }

    private var animazione: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.ChipScelta.animazione, calmo: calmo, istantanea: istantanea)
    }
}

// MARK: - Barra oggi / dopo

/// La barra dell'obiettivo: binario alto 12 (raggio 8), sopra la barra chiara della copertura di oggi e sopra
/// ancora la barra piena della copertura dopo lo scenario, nel colore del calo. Alla prima comparsa la barra piena
/// parte da «oggi» e si accorcia fino a «dopo»; ai cambi segue il valore nuovo con la stessa curva.
///
///     BarraOggiDopo(oggi: 0.90, dopo: 0.74, colore: Tema.Apple.Posizioni.Fuoco.Barra.allarme)
struct BarraOggiDopo: View {
    /// Coperture fra 0 e 1 (fuori si limitano).
    let oggi: Double
    let dopo: Double
    let colore: Color

    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var partita = false

    init(oggi: Double, dopo: Double, colore: Color) {
        self.oggi = oggi
        self.dopo = dopo
        self.colore = colore
    }

    var body: some View {
        let b = Tema.Apple.Posizioni.Fuoco.Barra.self
        let mostrata = (fermo || partita) ? dopo : oggi
        return GeometryReader { g in
            let w = g.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: b.raggio, style: .continuous)
                    .fill(b.binario)
                RoundedRectangle(cornerRadius: b.raggio, style: .continuous)
                    .fill(b.oggi)
                    .frame(width: w * Self.limita(oggi))
                    .animation(animazioneBarra, value: oggi)
                RoundedRectangle(cornerRadius: b.raggio, style: .continuous)
                    .fill(colore)
                    .animation(animazioneColore, value: colore)
                    .frame(width: w * Self.limita(mostrata))
                    .animation(animazioneBarra, value: mostrata)
            }
            .frame(width: w, height: b.altezza, alignment: .leading)
        }
        .frame(height: b.altezza)
        .accessibilityHidden(true)
        .onAppear(perform: parti)
    }

    static func limita(_ v: Double) -> CGFloat {
        guard v.isFinite else { return 0 }
        return CGFloat(min(1, max(0, v)))
    }

    /// Alla comparsa (fuori dallo stato finale) la barra piena parte da «oggi» e va a «dopo» al giro dopo.
    private func parti() {
        guard !fermo, !partita else { return }
        DispatchQueue.main.async { partita = true }
    }

    private var animazioneBarra: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.BarraScenario.animazione, calmo: calmo, istantanea: istantanea)
    }

    private var animazioneColore: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.BarraScenario.animazioneColore, calmo: calmo, istantanea: istantanea)
    }
}
