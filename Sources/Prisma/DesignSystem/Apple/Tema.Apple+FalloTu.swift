import SwiftUI

// Gettoni delle schede della fase 1 di Vera (Design/template-vera.html: «Fallo tu», «Chiedi alla tua clientela»,
// «Mai a caso»), coerenti con le schede dei calcoli di Vera (§4.7 della specifica Apple): tile col filo, righe divise
// dal `separatore`, icone delle app a 30, titolo 13 semibold e dettaglio `.k`; sotto, «Conferma» (principale) e
// «Modifica». Le righe eseguite si spuntano in verde; gli avvisi in arancio, «non trovato» in rosso.

extension Tema.Apple {
    enum ConfermaVera {
        // MARK: Misure

        static let superficie = Superficie.tile
        static let raggio: CGFloat = Raggio.tile
        static let paddingRiga = Misura.padding(9, 11)
        static let icona: CGFloat = 30
        static let spazioRiga: CGFloat = 11
        static let sopraPulsanti: CGFloat = 10
        static let spazioPulsanti: CGFloat = 6
        static let sopraAvviso: CGFloat = 3
        static let lineeDettaglio = 3
        /// Le schede lunghe («Crea 30 attività») mostrano le prime righe e «e altre N».
        static let righeVisibili = 5
        static let segno: CGFloat = 18

        // MARK: Caratteri

        static let intestazione = Carattere.etichetta
        static let titolo = Carattere(dimensione: 13, peso: .semibold)
        static let dettaglio = Carattere.secondario
        static let avviso = Carattere(dimensione: 12, peso: .medium)
        static let stato = Carattere(dimensione: 12.5, peso: .semibold)
        static let segnoCarattere = Carattere(dimensione: 11, peso: .bold)

        // MARK: Colori

        static let coloreIntestazione = Colore.inchiostro2
        static let coloreTitolo = Colore.inchiostro
        static let coloreDettaglio = Colore.inchiostro2
        static let coloreAvviso = Colore.arancio
        static let fatto = Colore.verde
        static let nonFatto = Colore.rosso
        static let coloreTolta = Colore.inchiostro3
        static let filetto = Colore.separatore
        static let fondoSegno = Colore.chip
        static let opacitaAnnullata: Double = 0.55

        // MARK: Movimento

        /// Le righe si spuntano una dopo l'altra dopo «Conferma».
        static let cascataSpunte = 0.38
        static var spunta: Animation { Moto.uscita(0.35) }
    }

    enum ClientelaVera {
        static let spazioFiltri: CGFloat = 6
        static let paddingFiltro = Misura.padding(4, 10)
        static let filtro = Carattere(dimensione: 12.5, peso: .semibold)
        static let fondoFiltro = Colore.accento.opacity(0.12)
        static let testoFiltro = Colore.accento
        static let fondoTutti = Colore.chip
        static let testoTutti = Colore.inchiostro2
        static let sopraFiltri: CGFloat = 6
        static let sopraTabella: CGFloat = 10
        static let cella = Misura.padding(8, 12)
        static let avatar: CGFloat = 26
        /// La colonna del canale: due etichette compatte (Alleanza e indipendente) affiancate.
        static let colonnaCanale: CGFloat = 190
        static let intestazione = Carattere(dimensione: 12.5, peso: .semibold)
        static let voce = Carattere(dimensione: 13, peso: .regular)
        static let nome = Carattere(dimensione: 13, peso: .semibold)
        static let fondoIntestazione = Colore.chip
        static let coloreVoce = Colore.inchiostro
        static let coloreIntestazione = Colore.inchiostro2
        static let filetto = Colore.separatore
        static let raggio: CGFloat = Raggio.tile
        /// Le tabelle lunghe: le prime righe, poi «e altri N clienti».
        static let righeVisibili = 12
    }

    enum FontiVera {
        static let sopra: CGFloat = 10
        static let spazio: CGFloat = 6
        static let paddingPillola = Misura.padding(4, 10)
        static let pillola = Carattere(dimensione: 12, peso: .semibold)
        static let fondoControllata = Colore.verde.opacity(0.12)
        static let testoControllata = Colore.verde
        static let fondoNonTrovata = Colore.rosso.opacity(0.12)
        static let testoNonTrovata = Colore.rosso
        static let fondoPillola = Colore.chip
        static let testoPillola = Colore.inchiostro2
        static let paddingVoce = Misura.padding(8, 11)
        static let numero = Carattere(dimensione: 11, peso: .bold, tabellare: true)
        static let cifra = Carattere(dimensione: 13.5, peso: .bold, tabellare: true)
        static let origine = Carattere(dimensione: 12.5, peso: .semibold)
        static let dettaglio = Carattere.secondario
        static let coloreOrigine = Colore.inchiostro
        static let coloreDettaglio = Colore.inchiostro2
        static let filetto = Colore.separatore
        static let icona: CGFloat = 22
        static let raggio: CGFloat = Raggio.tile
        static let fondoNumero = Colore.chip
        static let latoNumero: CGFloat = 18
    }
}
