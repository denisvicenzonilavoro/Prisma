import SwiftUI

// La tabella prima/dopo degli scenari «E se…?» di Ruby (Design/template-apple-specifica.md §4.7): un modello grafico
// fisso riempito con le cifre di MotoreScenari, mai con quelle di Qwen. Gettoni in Tema.Apple+ScenariRuby.swift.
// «Riduci movimento»: compare con la dissolvenza di 0,15 s, senza spostamento; istantanee: già al suo posto.

/// La tabella a tre colonne: voce, oggi, con lo scenario (in viola).
struct TabellaScenarioApple: View {
    let colonnaOggi: String
    let colonnaScenario: String
    let righe: [RigaScenarioRuby]

    var body: some View {
        let t = Tema.Apple.ScenarioRuby.self
        VStack(spacing: 0) {
            riga("", colonnaOggi, colonnaScenario, intestazione: true)
                .background(t.fondoIntestazione)
            ForEach(righe) { r in
                riga(r.voce, r.oggi, r.scenario, intestazione: false)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(t.filetto)
                            .frame(height: Tema.Apple.Misura.bordo)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(r.voce): oggi \(r.oggi), con lo scenario \(r.scenario)")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: t.raggio, style: .continuous))
        .superficieApple(.tile)
    }

    private func riga(_ voce: String, _ oggi: String, _ scenario: String, intestazione: Bool) -> some View {
        let t = Tema.Apple.ScenarioRuby.self
        return ColonneScenarioApple(pesi: t.pesiColonne).callAsFunction {
            cella(voce, intestazione ? t.intestazione : t.voce, t.coloreVoce)
            cella(oggi, intestazione ? t.intestazione : t.oggi, t.coloreOggi)
            cella(scenario, t.scenario, t.coloreScenario)
        }
    }

    private func cella(_ testo: String, _ carattere: Tema.Apple.Carattere, _ colore: Color) -> some View {
        let t = Tema.Apple.ScenarioRuby.self
        return Text(testo)
            .carattereApple(carattere)
            .foregroundColor(colore)
            .lineLimit(t.righeCella)
            .minimumScaleFactor(t.scalaMinima)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(t.cella)
    }
}

/// Le colonne in proporzione (`grid-template-columns: 1.2fr 1fr 1fr`): ogni cella prende la sua parte della
/// larghezza, la riga è alta quanto la cella più alta.
struct ColonneScenarioApple: Layout {
    let pesi: [CGFloat]

    private func larghezze(_ totale: CGFloat, _ quante: Int) -> [CGFloat] {
        let p = (0..<quante).map { $0 < pesi.count ? pesi[$0] : 1 }
        let somma = max(p.reduce(0, +), 0.0001)
        return p.map { totale * $0 / somma }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ideale = subviews.reduce(CGFloat(0)) { $0 + $1.sizeThatFits(.unspecified).width }
        let larghezza = proposal.width ?? ideale
        let l = larghezze(larghezza, subviews.count)
        var altezza: CGFloat = 0
        for (i, s) in subviews.enumerated() {
            altezza = max(altezza, s.sizeThatFits(ProposedViewSize(width: l[i], height: nil)).height)
        }
        return CGSize(width: larghezza, height: altezza)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let l = larghezze(bounds.width, subviews.count)
        var x = bounds.minX
        for (i, s) in subviews.enumerated() {
            s.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading, proposal: ProposedViewSize(width: l[i], height: bounds.height))
            x += l[i]
        }
    }
}

/// La scheda dei calcoli entra dopo il testo: 0,5 s con la curva `uscita`, da y +10 (calma: dissolvenza; istantanea: ferma).
private struct EntrataTabellaScenario: ViewModifier {
    let attiva: Bool
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var entrata = false

    func body(content: Content) -> some View {
        let t = Tema.Apple.ScenarioRuby.self
        let fuori = attiva && !entrata && !istantanea
        return content
            .opacity(fuori ? 0 : 1)
            .offset(y: fuori && !calmo ? t.spostamentoEntrata : 0)
            .onAppear {
                guard attiva, !entrata, !istantanea else { return }
                withAnimation(Tema.Apple.Moto.animazione(t.entrata, calmo: calmo)) { entrata = true }
            }
    }
}

extension View {
    /// L'entrata della scheda prima/dopo sotto la risposta di Ruby (`attiva` false: c'era già o entra con altro).
    func entrataTabellaScenario(_ attiva: Bool = true) -> some View {
        modifier(EntrataTabellaScenario(attiva: attiva))
    }
}
