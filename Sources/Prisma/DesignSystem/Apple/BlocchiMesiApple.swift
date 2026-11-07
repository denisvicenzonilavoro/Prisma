import SwiftUI

// Blocchi dei mesi del tema «stile Apple» (Design/template-apple-specifica.md §2.22).
// 12 blocchi (o quanti ne chiede la soglia) con spazio 6, alti 90, raggio 12: un mese pieno è verde, il mese
// parziale ha il verde fino alla sua frazione, i mesi vuoti sono `binario`. Entrano da scala y 0,2 e opacità 0
// con la molla di 0,5 s, ritardo 0,2 + i·0,06, ancorati al centro.
// «Riduci movimento» e istantanee: tutti al loro posto subito. Il componente non calcola: riceve i mesi pronti.
// Gettoni in Tema.Apple+Aree360.swift (`Tema.Apple.Aree360.Mesi`).

/// I mesi di spese da parte, in blocchi.
///
///     BlocchiMesi(mesi: 3.5)                 // 12 blocchi, tre pieni e mezzo
///     BlocchiMesi(mesi: 8, blocchi: 18)      // soglia delle ipotesi a 18 mesi
struct BlocchiMesi: View {
    let mesi: Double
    var blocchi: Int = Tema.Apple.Aree360.Mesi.blocchi
    var colore: Color = Tema.Apple.Aree360.Mesi.pieno

    @Environment(\.prismaStatoFinale) private var fermo
    /// Istantanee: lo stato finale è per sempre, niente da scrivere alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    @State private var entrati = false

    private var mostrati: Bool { fermo || entrati }

    var body: some View {
        let m = Tema.Apple.Aree360.Mesi.self
        let n = max(1, blocchi)
        return HStack(spacing: m.spazio) {
            ForEach(0..<n, id: \.self) { i in
                blocco(i)
                    .scaleEffect(x: 1, y: mostrati ? 1 : m.scalaIniziale, anchor: .center)
                    .opacity(mostrati ? 1 : 0)
                    .animation(fermo ? nil : m.animazione.delay(m.ritardo(i)), value: entrati)
            }
        }
        .frame(height: m.altezza)
        .onAppear(perform: entra)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(TestiAree360.mesiConNome(mesi)) di spese da parte"))
    }

    private func entra() {
        guard !entrati else { return }
        if fermo {
            if !scatto { entrati = true }
            return
        }
        // Al giro dopo: i blocchi partono dallo stato iniziale già disegnato
        DispatchQueue.main.async { entrati = true }
    }

    @ViewBuilder private func blocco(_ i: Int) -> some View {
        let m = Tema.Apple.Aree360.Mesi.self
        let forma = RoundedRectangle(cornerRadius: m.raggio, style: .continuous)
        let pieno = min(max(mesi - Double(i), 0), 1)
        if pieno >= 1 {
            forma.fill(colore)
        } else if pieno <= 0 {
            forma.fill(m.vuoto)
        } else {
            let f = CGFloat(pieno)
            forma.fill(LinearGradient(stops: [
                Gradient.Stop(color: colore, location: 0),
                Gradient.Stop(color: colore, location: f),
                Gradient.Stop(color: m.vuoto, location: f),
                Gradient.Stop(color: m.vuoto, location: 1),
            ], startPoint: .leading, endPoint: .trailing))
        }
    }
}
