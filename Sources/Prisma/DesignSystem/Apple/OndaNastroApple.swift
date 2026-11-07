import SwiftUI

// L'onda «nastro» della voce del copilota dell'incontro (Design/template-novita-specifica.md §8.2.2 e §8.3): 48 barre
// che seguono il microfono, l'ultimo valore entra a destra a ogni pezzo d'audio. Niente Timer: la vista si ridisegna
// quando cambiano i livelli (`StatoCopilotaIncontro.livelli`, dal `livello` di AscoltoVera).
// - Ferma: tutte grigie, alte 3.
// - Istantanee: la forma del template a un tempo fisso, sempre la stessa.
// - «Riduci movimento»: l'onda resta (dice che il microfono sente) ma senza interpolazione fra un valore e l'altro.
// Valori in Tema.Apple+Copilota.swift (`Tema.Apple.Copilota.Onda`).

struct OndaNastroApple: View {
    /// I livelli del microfono (0…1), il più recente in fondo; ne contano gli ultimi 48.
    let livelli: [Float]
    /// true durante l'ascolto: barre rosse; false: ferma e grigia.
    let ascolta: Bool

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaScatto) private var scatto

    private typealias O = Tema.Apple.Copilota.Onda

    /// La forma del template (`onda` in template-novita.html) al tempo `t`: a(i) fra 0 e 1.
    static func forma(tempo t: Double, barre: Int = Tema.Apple.Copilota.Onda.barre) -> [Double] {
        (0..<barre).map { i in
            let x = Double(i)
            let battito = abs(sin(3.1 * t + 0.55 * x) * sin(1.7 * t + 0.21 * x))
            return (0.25 + 0.75 * battito) * (0.5 + 0.5 * sin(0.4 * x + t))
        }
    }

    /// I valori da disegnare, uno per barra (0…1).
    private var valori: [Double] {
        guard ascolta else { return Array(repeating: 0.0, count: O.barre) }
        if scatto { return Self.forma(tempo: O.tempoIstantanea) }
        let ultimi = livelli.suffix(O.barre).map { Double(min(max($0, 0), 1)) }
        return Array(repeating: 0.0, count: O.barre - ultimi.count) + ultimi
    }

    var body: some View {
        let v = valori
        return HStack(alignment: .center, spacing: O.passo - O.larghezzaBarra) {
            ForEach(0..<O.barre, id: \.self) { i in
                RoundedRectangle(cornerRadius: O.raggioBarra, style: .continuous)
                    .fill(ascolta ? O.coloreAscolto : O.coloreFermo)
                    .frame(width: O.larghezzaBarra, height: max(O.minima, CGFloat(v[i]) * O.scala))
            }
        }
        .frame(width: O.larghezza, height: O.altezza)
        .animation(calmo || scatto ? nil : O.passoAnimato, value: livelli)
        .accessibilityHidden(true)
    }
}
