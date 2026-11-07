import SwiftUI

// Token di anelli, barre e grafici del tema «stile Apple»
// (Design/template-apple-specifica.md §2.3, §2.4, §2.5, §2.11). Li usano AnelliApple.swift e GraficiApple.swift.

extension Tema.Apple {
    enum Grafico {

        /// Rapporto tra la linea di base del testo e la sua dimensione: serve a mettere un'etichetta
        /// «sulla linea di base» come `<text y=…>` dell'SVG (il centro sta circa 0,35·dimensione sopra).
        static let rapportoLineaBase: CGFloat = 0.35

        // MARK: Anelli (§2.3)

        /// Misura e spessore di un anello (o del gruppo di anelli concentrici).
        struct MisuraAnello {
            let misura: CGFloat
            let spessore: CGFloat
        }

        enum Anello {
            /// Spessore predefinito: misura·0,09.
            static let spessoreRelativo: CGFloat = 0.09
            /// Passo tra gli anelli: spessore·1,22.
            static let passoRelativo: CGFloat = 1.22
            /// Binario: lo stesso colore dell'anello al 15%.
            static let opacitaBinario: Double = 0.15
            /// Il disegno parte da ore 12, in senso orario.
            static let inizio = Angle.degrees(-90)
            /// Il contenuto al centro sta dentro il foro dell'anello più interno: al più l'82% del suo diametro,
            /// e il testo si riduce fino a metà se non ci sta (come nel template, la cifra non tocca gli anelli).
            static let quotaCentro: CGFloat = 0.82
            static let riduzioneCentro: CGFloat = 0.5

            static let scrivania = MisuraAnello(misura: 118, spessore: 12)
            static let posizioni = MisuraAnello(misura: 190, spessore: 16)
            static let completezza = MisuraAnello(misura: 120, spessore: 13)
            static let obiettivi = MisuraAnello(misura: 150, spessore: 15)
            static let dettaglioObiettivo = MisuraAnello(misura: 220, spessore: 22)
            static let aree = MisuraAnello(misura: 170, spessore: 17)
            static let previdenza = MisuraAnello(misura: 210, spessore: 20)
            static let backup = MisuraAnello(misura: 110, spessore: 12)
            /// Carta «Obiettivo casa» (fermo).
            static let cartaObiettivo = MisuraAnello(misura: 170, spessore: 18)
        }

        // MARK: Barre (§2.11)

        enum Barra {
            /// Barra semplice: alta 8, raggio 9, fondo `binario`.
            static let altezza: CGFloat = Misura.Controllo.barra
            static let raggio: CGFloat = Raggio.barra
            /// Spazio tra i pezzi (canali e composizione).
            static let spazio: CGFloat = 3
            /// Barra dei canali: larga 520.
            static let larghezzaCanali: CGFloat = 520
            /// Barra di composizione: alta 22, contenitore di raggio 12, pezzi di raggio 6.
            static let altezzaComposizione: CGFloat = 22
            static let raggioComposizione: CGFloat = Raggio.giorno
            static let raggioPezzo: CGFloat = Raggio.bollaPiccola
        }

        // MARK: Linea che si disegna (§2.4)

        enum Tracciato {
            /// Margine sopra la linea: y = altezza − valore·(altezza − 10), come `pathDa` del template.
            static let margineAlto: CGFloat = 10
            static let spessore: CGFloat = 2.8
            static let spessoreStima: CGFloat = 2.6
            /// Tratteggio delle stime (resta anche dopo il disegno).
            static let tratteggioStima: [CGFloat] = [6, 6]
            /// Area sotto la linea: gradiente del colore da 0,20 a 0.
            static let opacitaArea: Double = 0.20
            /// Fascia di incertezza della stima.
            static let opacitaFascia: Double = 0.13
            /// Punto finale: raggio 5, bordo bianco 2,5.
            static let raggioPunto: CGFloat = 5
            static let bordoPunto: CGFloat = 2.5
            static let colorePuntoBordo = Color.white
            /// Griglia leggera: righe del colore `separatore`, spesse 1.
            static let coloreGriglia = Colore.separatore
            static let spessoreGriglia: CGFloat = 1
            static let righeGriglia = 4
            /// Riga verticale «oggi»: tratteggio 2 4, `inchiostro3`.
            static let coloreOggi = Colore.inchiostro3
            static let tratteggioOggi: [CGFloat] = [2, 4]
        }

        // MARK: Grafico «In essere / Con le proposte» (§2.5)

        enum Portafoglio {
            static let larghezza: CGFloat = 818
            static let altezza: CGFloat = 92
            static let coloreStoria = Colore.anello2
            static let spessoreStoria: CGFloat = 2.6
            /// Area della storia: gradiente da 0,22 a 0.
            static let opacitaArea: Double = 0.22
            static let coloreStima = Colore.stima
            static let spessoreStima: CGFloat = 2.4
            static let tratteggioStima: [CGFloat] = [5, 6]
            /// Fascia viola: opacità 0,13·p.
            static let opacitaFascia: Double = 0.13
            /// Mesi: 15 sotto il grafico, uno ogni 2, uno ogni 3 quando p > 0,5 (a scatto).
            static let distanzaMesi: CGFloat = 15
            static let passoMesi = 2
            static let passoMesiProposte = 3
            static let sogliaPassoMesi: Double = 0.5
            /// Spazio sotto il grafico riservato ai mesi.
            static let fasciaMesi: CGFloat = 20
            /// Etichetta della stima: 8 a sinistra e 11 sopra il punto, allineata a destra.
            static let scostamentoEtichetta = CGSize(width: 8, height: 11)
            /// Riquadro dell'etichetta (allineata a destra dentro questa larghezza).
            static let larghezzaEtichetta: CGFloat = 240
            /// La linea della storia si disegna 0,20 s dopo il montaggio del grafico.
            static let ritardoDisegno: Double = 0.20
        }
    }
}

// MARK: Caratteri dei grafici

extension Tema.Apple.Carattere {
    /// «stima giugno 2027»: 12 semibold, colore della stima.
    static let etichettaStima = Tema.Apple.Carattere(dimensione: 12, peso: .semibold)
    /// «oggi» sotto la riga verticale: 12 bold.
    static let oggiGrafico = Tema.Apple.Carattere(dimensione: 12, peso: .bold)
}

// MARK: Curve e tempi dei grafici

extension Tema.Apple.Moto.Curva {
    /// Bézier che approssima la quartica `1 − (1−t)^4` (easeOutQuart), per animare con SwiftUI
    /// ciò che il template interpola a mano (morph del grafico delle proposte).
    static let quarticaUscita = Tema.Apple.Moto.Curva(x1: 0.25, y1: 1, x2: 0.5, y2: 1)

    /// Il valore della curva al tempo `t` (0…1), come la calcola il browser: serve dentro gli `Animatable`
    /// che seguono una fase lineare (brillio).
    func valore(_ t: Double) -> Double {
        let t = min(max(t, 0), 1)
        if t == 0 || t == 1 { return t }
        // Coefficienti della bézier con P0 = (0,0) e P3 = (1,1).
        let cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx
        let cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by
        func x(_ s: Double) -> Double { ((ax * s + bx) * s + cx) * s }
        func dx(_ s: Double) -> Double { (3 * ax * s + 2 * bx) * s + cx }
        // Newton, poi bisezione se la derivata è troppo piatta.
        var s = t
        for _ in 0..<8 {
            let errore = x(s) - t
            if abs(errore) < 1e-6 { return ((ay * s + by) * s + cy) * s }
            let d = dx(s)
            if abs(d) < 1e-6 { break }
            s -= errore / d
        }
        var basso = 0.0, alto = 1.0
        s = t
        for _ in 0..<20 {
            let v = x(s)
            if abs(v - t) < 1e-6 { break }
            if v < t { basso = s } else { alto = s }
            s = (basso + alto) / 2
        }
        return ((ay * s + by) * s + cy) * s
    }
}

extension Tema.Apple.Moto.MorphProposte {
    /// Il grafico si allarga in 0,9 s con la quartica.
    static var animazione: Animation { Tema.Apple.Moto.Curva.quarticaUscita.animazione(durata) }
}

extension Tema.Apple.Moto.Brillio {
    /// Tutto il brillio: sale in 0,6 s, resta fino a 0,9 s, poi scende in 0,6 s.
    static var durataTotale: Double { tenuto + durata }

    /// L'animazione lineare della fase (0 → 1) che guida `intensita(fase:)`.
    static var animazioneFase: Animation { .linear(duration: durataTotale) }

    /// Intensità del brillio (0…1) alla fase data (0…1 su `durataTotale`), con la curva `ease`.
    static func intensita(fase: Double) -> Double {
        let t = min(max(fase, 0), 1) * durataTotale
        let curva = Tema.Apple.Moto.Curva.ease
        if t <= durata { return curva.valore(t / durata) }
        if t <= tenuto { return 1 }
        return 1 - curva.valore((t - tenuto) / durata)
    }
}
