import SwiftUI

// Gettoni della scheda «E se…?» di Vera (Design/template-apple-specifica.md §4.7, «Schede di calcolo»): tabella a tre
// colonne 1,2fr 1fr 1fr in una tile senza padding, intestazione su `chip` in semibold, celle 13,5 con padding 9×14,
// la colonna dello scenario in viola (`stima`) e 700; sotto, a 10, «Salva nel dossier» e «Apri in Simulazioni».
// La scheda entra dopo il testo in 0,5 s con la curva `uscita`, da y +10. Il componente sta in TabellaScenarioApple.swift.

extension Tema.Apple {
    enum ScenarioVera {
        // MARK: Misure

        /// Pesi delle tre colonne: voce, oggi, scenario.
        static let pesiColonne: [CGFloat] = [1.2, 1, 1]
        /// Padding di ogni cella.
        static let cella = Misura.padding(9, 14)
        /// Dal testo della risposta alla tabella, dalla tabella ai pulsanti, fra i pulsanti, sopra le note.
        static let sopraTabella: CGFloat = 12
        static let sopraPulsanti: CGFloat = 10
        static let spazioPulsanti: CGFloat = 6
        static let sopraNote: CGFloat = 8
        /// Le cifre lunghe si stringono un poco prima di andare a capo.
        static let scalaMinima: CGFloat = 0.85
        static let righeCella = 2
        /// Le note sotto la scheda: al più due.
        static let massimoNote = 2
        static let raggio: CGFloat = Raggio.tile

        // MARK: Caratteri

        /// Celle 13,5: voce regolare, oggi semibold, scenario bold; l'intestazione semibold.
        static let voce = Carattere(dimensione: 13.5, peso: .regular)
        static let intestazione = Carattere(dimensione: 13.5, peso: .semibold, tabellare: true)
        static let oggi = Carattere(dimensione: 13.5, peso: .semibold, tabellare: true)
        static let scenario = Carattere(dimensione: 13.5, peso: .bold, tabellare: true)
        static let nota = Carattere.secondario

        // MARK: Colori

        static let fondoIntestazione = Colore.chip
        static let coloreVoce = Colore.inchiostro2
        static let coloreOggi = Colore.inchiostro
        /// Viola delle stime e delle proposte (`#8B5CF6`).
        static let coloreScenario = Colore.stima
        static let filetto = Colore.separatore
        static let coloreNota = Colore.inchiostro2
        static let coloreSalvata = Colore.verde

        // MARK: Movimento

        static let durataEntrata = 0.5
        static let spostamentoEntrata: CGFloat = 10
        static var entrata: Animation { Moto.uscita(durataEntrata) }
    }
}
