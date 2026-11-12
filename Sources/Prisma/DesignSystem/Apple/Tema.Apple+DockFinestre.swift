import SwiftUI

// Gettoni del dock che si ingrandisce e della finestra che esce dall'icona e vi rientra
// (Design/template-apple-specifica.md §3.4, §3.5, §1.8). Le viste stanno in Shell/Dock.swift e Shell/VoloFinestra.swift.
// Le curve e le durate di base sono già in TemaAppleMoto.swift (`FinestraApre`, `FinestraChiude`,
// `IngrandimentoDock`, `RimbalzoIcona`): qui solo ciò che serve in più.

extension Tema.Apple.Moto {
    /// La finestra che vola fra l'icona del dock e la sua cornice (apertura, chiusura, riduzione, ripristino).
    enum VoloFinestra {
        /// La finestra è del tutto opaca quando è uscita dall'icona per questa parte del volo (in chiusura è il punto
        /// che la curva raggiunge al 60% del tempo: lì comincia a svanire). Una sola regola per i due versi.
        static let valoreOpaco: Double = 0.18
        /// Senza un'icona da cui partire (app fuori dal dock): appena più piccola, al suo posto.
        static let scalaSulPosto: CGFloat = 0.94
        /// Passi di bisezione per ritrovare il tempo dal valore della curva (2^-24: ben sotto un fotogramma).
        static let passiCurva = 24
        /// Apertura: 0,6 s con `(0.3,1.12,0.5,1)`.
        static func apertura(durata: Double = FinestraApre.durata) -> Animation {
            Curva.finestraApre.animazione(durata)
        }
        /// Chiusura e riduzione: 0,48 s con `(0.5,0,0.3,1)`.
        static func chiusura(durata: Double = FinestraChiude.durata) -> Animation {
            Curva.finestraChiude.animazione(durata)
        }
    }

    /// Il pallino sotto le app aperte: compare e scompare in 0,3 s.
    enum PuntinoDock {
        static let durata = 0.30
        static var animazione: Animation { .easeInOut(duration: durata * Tema.Apple.Moto.ritmo) }
    }
}

extension Tema.Apple.Moto.Curva {
    /// Il punto della bézier al parametro `s` (0…1): `x` è il tempo, `y` il valore.
    func punto(alParametro s: Double) -> (x: Double, y: Double) {
        let u = 1 - s
        let a = 3 * u * u * s
        let b = 3 * u * s * s
        let c = s * s * s
        return (a * x1 + b * x2 + c, a * y1 + b * y2 + c)
    }

    /// Il tempo (0…1) in cui la curva arriva per la prima volta al valore `v`. Vale anche per le curve che
    /// superano 1 (apertura della finestra): la salita fino al picco è monotona e si cerca lì.
    func tempo(alValore v: Double) -> Double {
        if v <= 0 { return 0 }
        // Oltre il valore finale si cerca il primo istante in cui ci arriva
        let obiettivo = min(v, 1)
        var basso = 0.0
        var alto = 1.0
        for _ in 0..<Tema.Apple.Moto.VoloFinestra.passiCurva {
            let medio = (basso + alto) / 2
            if punto(alParametro: medio).y >= obiettivo { alto = medio } else { basso = medio }
        }
        return min(max(punto(alParametro: alto).x, 0), 1)
    }
}
