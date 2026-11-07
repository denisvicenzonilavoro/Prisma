import SwiftUI

// Gettoni dei componenti «numero che si conta», «entrata a cascata», «spunta che si disegna»,
// «Ti preparo» e «Segna come fatto» (Design/template-apple-specifica.md §2.1, §2.2, §2.12-§2.14).
// I componenti stanno in CifreApple.swift, CascataApple.swift e CompletamentoApple.swift.

// MARK: - Colori

extension Tema.Apple.Colore {
    /// Velo verde sulla scheda segnata come fatta (`rgba(47,163,90,.16)`).
    static let veloFatto = Color(r: 47, g: 163, b: 90, a: 0.16)
    /// Spunta bianca dentro il cerchietto pieno di «Ti preparo».
    static let spuntaSuVerde = Color.white
}

// MARK: - Misure

extension Tema.Apple.Misura {
    /// Spunta che si disegna: disegno 72×72 (coordinate del viewBox SVG del template).
    enum Spunta {
        /// Lato del disegno.
        static let lato: CGFloat = 72
        /// Centro e raggio del cerchio.
        static let centro: CGFloat = 36
        static let raggio: CGFloat = 30
        static let trattoCerchio: CGFloat = 4
        static let trattoSegno: CGFloat = 5
        /// Il segno `M23 37 l9 9 l17 −19`.
        static let segno: [CGPoint] = [CGPoint(x: 23, y: 37), CGPoint(x: 32, y: 46), CGPoint(x: 49, y: 27)]
    }

    /// Lista «Ti preparo» (`.prep`).
    enum TiPreparo {
        /// Spazio fra il titolo e la prima voce.
        static let sottoTitolo: CGFloat = 4
        /// Spazio fra il cerchietto e il testo.
        static let spazio: CGFloat = 10
        /// Padding verticale di ogni riga.
        static let paddingRiga: CGFloat = 9
        /// Cerchietto: lato e bordo.
        static let cerchietto: CGFloat = 20
        static let bordoCerchietto: CGFloat = 2
        /// Spunta bianca del cerchietto: una «L» 8×4 con tratto 2, ruotata di −45° e spostata di (1, −1).
        static let spuntaLarghezza: CGFloat = 8
        static let spuntaAltezza: CGFloat = 4
        static let spuntaTratto: CGFloat = 2
        static let spuntaRotazione: Double = -45
        static let spuntaScostamento: CGFloat = 1
    }
}

// MARK: - Tempi e curve

// La bézier valutata a mano (`Curva.valore(_:)`) sta in Tema.Apple+Grafici.swift: la spunta la usa
// per applicare la curva `uscita` ai due tratti mentre l'avanzamento è lineare.

extension Tema.Apple.Moto {
    /// Come entra un blocco: da dove parte (spostamento, scala, sfocatura, opacità 0) e con che tempo.
    struct StileEntrata {
        let durata: Double
        let curva: Curva
        let spostamentoX: CGFloat
        let spostamentoY: CGFloat
        let scala: CGFloat
        let sfocatura: CGFloat

        var animazione: Animation { curva.animazione(durata) }

        /// Cascata (§2.2): da y +18, scala 0,985, sfocatura 6, in 0,72 s con `uscita`.
        static let cascata = StileEntrata(durata: Cascata.durata, curva: .uscita, spostamentoX: 0,
                                          spostamentoY: Cascata.spostamento, scala: Cascata.scala,
                                          sfocatura: Cascata.sfocatura)
        /// Impegni dell'agenda: da x +30, in 0,60 s.
        static let laterale = StileEntrata(durata: CascataLaterale.durata, curva: .uscita,
                                           spostamentoX: CascataLaterale.spostamento, spostamentoY: 0,
                                           scala: 1, sfocatura: 0)
        /// Voci delle notifiche: da x +20, in 0,40 s.
        static let notifica = StileEntrata(durata: VoceNotifica.durata, curva: .uscita,
                                           spostamentoX: VoceNotifica.spostamento, spostamentoY: 0,
                                           scala: 1, sfocatura: 0)
    }
}

extension Tema.Apple.Moto.Spunta {
    /// Durata complessiva del disegno: il segno finisce a 0,35 + 0,35 s.
    static var durataTotale: Double { max(durataCerchio, ritardoSegno + durataSegno) }
    /// Avanzamento lineare del disegno (le curve dei due tratti si applicano dentro la forma).
    static var tracciato: Animation { .linear(duration: durataTotale) }
    /// Velo verde sulla scheda (`transition: background .4s`).
    static var velo: Animation { Tema.Apple.Moto.Curva.ease.animazione(durataVelo) }
}

extension Tema.Apple.Moto.TiPreparo {
    /// Il cerchietto pieno si ingrandisce appena.
    static let scalaFatta: CGFloat = 1.08
}

extension Tema.Apple.Moto.Fatto {
    /// La scheda che si stringe: scala 0,85 e margine sinistro −14 (lo spazio del nastro).
    static let scala: CGFloat = 0.85
    static let margine: CGFloat = -14
}
