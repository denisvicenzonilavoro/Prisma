import SwiftUI

// I coriandoli dei traguardi (componente comune della versione «Luce», Design/template-luce-specifica.md §1.4 e §5.4.3):
// 70 rettangolini che cadono, ondeggiano e ruotano sopra il biglietto, disegnati in una `TelaAnimata` (niente Timer).
// Il disegno è sempre lo stesso per lo stesso `seme` (il template usa `Math.random()`: qui un generatore con seme fisso
// per traguardo). Dopo 8 s la tela sparisce e smette di disegnare: niente ciclo infinito. Con «Riduci movimento» e
// nelle istantanee niente coriandoli (immagine pulita, §5.4.3). Valori in Tema.Apple+Traguardi.swift.

/// I coriandoli sopra una superficie; `seme` decide il disegno.
struct CoriandoliApple: View {
    let seme: String

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var finiti = false

    var body: some View {
        if !fermo && !finiti {
            let pezzi = Self.pezzi(seme: seme)
            TelaAnimata(tempoFinale: Tema.Apple.Moto.Coriandoli.fine) { c, misura, t in
                Self.disegna(&c, misura: misura, t: t, pezzi: pezzi)
            }
            .allowsHitTesting(false)
            .task {
                try? await Task.sleep(nanoseconds: UInt64(Tema.Apple.Moto.Coriandoli.fine * 1_000_000_000))
                finiti = true
            }
        }
    }

    /// Un pezzo: posizione di partenza (0…1 in x, −1…0 in y sopra il bordo), lato, velocità, fase, colore.
    struct Pezzo {
        let x: Double
        let y: Double
        let lato: Double
        let velocita: Double
        let fase: Double
        let colore: Int
    }

    /// I pezzi del seme (generatore congruenziale: stesso seme, stesso disegno).
    static func pezzi(seme: String) -> [Pezzo] {
        var stato: UInt64 = 1_469_598_103_934_665_603
        for b in seme.utf8 { stato = (stato ^ UInt64(b)) &* 1_099_511_628_211 }
        func prossimo() -> Double {
            stato = stato &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(stato >> 11) / Double(UInt64(1) << 53)
        }
        let k = Tema.Apple.Coriandoli.self
        let m = Tema.Apple.Moto.Coriandoli.self
        return (0..<k.numero).map { _ in
            Pezzo(x: prossimo(), y: -prossimo(),
                  lato: k.lato.lowerBound + prossimo() * (k.lato.upperBound - k.lato.lowerBound),
                  velocita: m.velocita.lowerBound + prossimo() * (m.velocita.upperBound - m.velocita.lowerBound),
                  fase: prossimo() * .pi * 2, colore: Int(prossimo() * Double(k.colori.count)) % k.colori.count)
        }
    }

    static func disegna(_ c: inout GraphicsContext, misura: CGSize, t: Double, pezzi: [Pezzo]) {
        let m = Tema.Apple.Moto.Coriandoli.self
        guard t < m.fine, misura.height > 0 else { return }
        let opacita = t <= m.inizioDissolvenza ? 1 : max(0, 1 - (t - m.inizioDissolvenza) / (m.fine - m.inizioDissolvenza))
        let colori = Tema.Apple.Coriandoli.colori
        let h = Double(misura.height)
        for p in pezzi {
            // Rientra dall'alto finché piove (6 s), poi cade fuori senza tornare
            var y = p.y * h + p.velocita * t
            if t < m.durataPioggia, y > h + p.lato { y = y.truncatingRemainder(dividingBy: h + p.lato * 2) - p.lato }
            guard y < h + p.lato else { continue }
            let x = p.x * Double(misura.width) + sin(m.frequenzaOnda * t + p.fase) * m.ondeggia
            var copia = c
            copia.opacity = opacita
            copia.translateBy(x: x, y: y)
            copia.rotate(by: .radians(m.rotazione * t + p.fase))
            let r = CGRect(x: -p.lato / 2, y: -p.lato / 4, width: p.lato, height: p.lato / 2)
            copia.fill(Path(r), with: .color(colori[p.colore]))
        }
    }
}
