import SwiftUI

// La barra della distribuzione di «Rispetto alle famiglie come la sua» (Design/template-novita-specifica.md §10.2.3,
// §10.3.4; CSS `.dist` del template): la fascia sfumata da rosso a verde lungo i percentili 0-100, velata fuori da
// p10-p90, le tacche sottili dei quartili, la tacca della metà con «metà delle famiglie» sotto e l'avatar del cliente
// sul suo percentile. Con le tavole a una dimensione la stessa barra può essere in valori (la tacca è il valore del
// gruppo, l'avatar la cifra del cliente, nessun percentile) o a quota (chi non ha la cosa a sinistra, chi ce l'ha a
// destra): le posizioni le calcola MotoreFamiglie (`BarraFamiglie`). L'avatar parte dall'estremità rossa e scorre al suo
// posto con la molla del tema (1,3 s, dopo 0,25 + i·0,12 s). «Riduci movimento» e istantanee: l'avatar è già al suo
// posto. Niente Timer.
// Valori in Tema.Apple+Famiglie.swift.

/// La barra di una voce. Le posizioni sono 0-100 lungo la barra (percentili, valori o quota: `BarraFamiglie`).
struct BarraDistribuzione: View {
    /// Dove sta il cliente (nil = nessun avatar: manca la cifra del cliente).
    let posizione: Double?
    /// La tacca principale: 50 (la metà delle famiglie) o il confine fra chi ha e chi non ha la cosa.
    var tacca: Double = 50
    var scrittaTacca: String = "metà delle famiglie"
    /// I quartili disegnati con le tacche sottili (25 e 75 se la fonte li dà).
    var quartili: [Double] = []
    /// Da dove a dove la fascia è piena (p10-p90 se la fonte li dà); nil = piena tutta.
    var parteCentrale: ClosedRange<Double>? = nil
    let iniziali: String
    let tinta: Colori.Avatar.Tinta
    /// Ordine della barra nella pagina: ritarda la partenza dell'avatar.
    var indice: Int = 0

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var arrivato = false

    init(posizione: Double?, tacca: Double = 50, scrittaTacca: String = "metà delle famiglie", quartili: [Double] = [],
         parteCentrale: ClosedRange<Double>? = nil, iniziali: String, tinta: Colori.Avatar.Tinta, indice: Int = 0) {
        self.posizione = posizione
        self.tacca = tacca
        self.scrittaTacca = scrittaTacca
        self.quartili = quartili
        self.parteCentrale = parteCentrale
        self.iniziali = iniziali
        self.tinta = tinta
        self.indice = indice
    }

    var body: some View {
        let f = Tema.Apple.Famiglie.self
        return GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            ZStack(alignment: .topLeading) {
                fascia(larghezza: w)
                ForEach(Array(quartili.enumerated()), id: \.offset) { _, q in
                    Rectangle()
                        .fill(f.coloreTaccaQuantile)
                        .opacity(f.opacitaTaccaQuantile)
                        .frame(width: f.larghezzaTaccaQuantile, height: max(0, h - 2 * f.rientroTaccaQuantile))
                        .position(x: Self.x(q, w), y: h / 2)
                }
                Rectangle()
                    .fill(f.coloreTacca)
                    .frame(width: f.larghezzaTacca, height: h + 2 * f.sporgenzaTacca)
                    .position(x: Self.x(tacca, w), y: h / 2)
                scritta(larghezza: w)
                if let p = posizione {
                    segnaposto
                        .position(x: Self.x(fermo || arrivato ? p : 0, w), y: h / 2)
                        .animation(fermo ? nil : Tema.Apple.Famiglie.Tempi.animazioneSegnaposto, value: p)
                }
            }
        }
        .frame(height: f.altezzaBarra)
        .onAppear(perform: parti)
        .accessibilityHidden(true)
    }

    /// La scritta sotto la tacca: centrata sulla tacca, ma allineata alla tacca (verso l'interno) quando la tacca è
    /// vicina a un bordo, così non esce dalla card.
    @ViewBuilder private func scritta(larghezza w: CGFloat) -> some View {
        let f = Tema.Apple.Famiglie.self
        let xt = Self.x(tacca, w)
        let y = f.scrittaTaccaY + f.mezzaScrittaTacca
        let testo = Text(scrittaTacca)
            .carattereApple(f.scrittaTacca)
            .foregroundColor(f.coloreScrittaTacca)
            .lineLimit(1)
            .fixedSize()
        if tacca < f.bordoScrittaTacca {
            testo
                .frame(width: max(0, w - xt), alignment: .leading)
                .position(x: xt + max(0, w - xt) / 2, y: y)
        } else if tacca > 100 - f.bordoScrittaTacca {
            testo
                .frame(width: xt, alignment: .trailing)
                .position(x: xt / 2, y: y)
        } else {
            testo.position(x: xt, y: y)
        }
    }

    private static func x(_ percentile: Double, _ larghezza: CGFloat) -> CGFloat {
        larghezza * CGFloat(min(max(percentile, 0), 100) / 100)
    }

    private func fascia(larghezza w: CGFloat) -> some View {
        let f = Tema.Apple.Famiglie.self
        return HStack(spacing: 0) {
            if let c = parteCentrale {
                Rectangle()
                    .fill(f.veloCode)
                    .opacity(f.opacitaVeloCode)
                    .frame(width: Self.x(c.lowerBound, w))
                Spacer(minLength: 0)
                Rectangle()
                    .fill(f.veloCode)
                    .opacity(f.opacitaVeloCode)
                    .frame(width: max(0, w - Self.x(c.upperBound, w)))
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(width: w, height: f.altezzaBarra)
        .background { f.fascia }
        .clipShape(Capsule(style: .continuous))
    }

    private var segnaposto: some View {
        let f = Tema.Apple.Famiglie.self
        return AvatarCliente(iniziali: iniziali, tinta: tinta, lato: f.latoAvatar)
            .overlay(Circle().strokeBorder(f.coloreBordoAvatar, lineWidth: f.bordoAvatar))
            .shadow(color: f.ombraAvatar, radius: f.raggioOmbraAvatar, x: 0, y: f.yOmbraAvatar)
    }

    /// L'avatar parte dall'estremità rossa dopo il suo ritardo; nello stato finale è già al suo posto (nelle istantanee
    /// non si scrive nulla: `fermo` basta).
    private func parti() {
        guard !fermo, !arrivato, posizione != nil else { return }
        let t = Tema.Apple.Famiglie.Tempi.self
        withAnimation(t.animazioneSegnaposto.ritardoPrisma(t.ritardo(segnaposto: indice))) { arrivato = true }
    }
}
