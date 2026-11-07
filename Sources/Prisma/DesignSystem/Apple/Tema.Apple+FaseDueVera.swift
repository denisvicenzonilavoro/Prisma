import SwiftUI

// Gettoni della fase 2 di Vera (Design/template-vera.html: «Il cliente in 30 secondi», «Lascia cadere qui», «Il codice in
// tasca», «La memoria», «Impara dalle correzioni», «Il filo lungo»), coerenti con le schede dei calcoli (§4.7): tile col
// filo, `.lbl` delle sezioni nel colore di Vera, citazioni con l'icona della Biblioteca, la pagina dei ricordi a due
// colonne con ✎ e ✕, la cornice del rilascio tratteggiata.

extension Tema.Apple {
    enum FaseDueVera {
        // MARK: Il cliente in 30 secondi

        static let spazioSezioni: CGFloat = 8
        static let paddingSezione = Misura.padding(10, 13)
        static let titoloSezione = Carattere.etichetta
        static let coloreTitoloSezione = Colore.rosso
        static let testoSezione = Carattere(dimensione: 14, peso: .regular, interlinea: 1.45)
        static let fonteSezione = Carattere.secondario
        static let coloreFonte = Colore.inchiostro2
        static let tema = Carattere(dimensione: 13, peso: .medium)
        static let sopraScheda: CGFloat = 10
        static let avatarTrenta: CGFloat = 34
        static let fonti = Carattere(dimensione: 12, peso: .semibold)

        // MARK: Citazioni delle norme

        static let iconaCitazione: CGFloat = 28
        static let titoloCitazione = Carattere(dimensione: 13.5, peso: .semibold)
        static let dettaglioCitazione = Carattere.secondario
        static let paddingCitazione = Misura.padding(10, 12)
        static let nonRisponde = Colore.arancio

        // MARK: 👍 e 👎

        static let pollice = Carattere(dimensione: 13, peso: .regular)
        static let fondoCorrezione = Colore.chip
        static let paddingCorrezione = Misura.padding(9, 12)
        static let correzione = Carattere(dimensione: 13.5, peso: .regular)
        static let raggioCorrezione: CGFloat = Raggio.tile
        static let votoDato = Colore.verde
        static let votoContrario = Colore.rosso

        // MARK: La memoria

        static let larghezzaPagina: CGFloat = 820
        static let altezzaPagina: CGFloat = 620
        static let paddingPagina: CGFloat = 22
        static let spazioColonne: CGFloat = 16
        static let paddingRicordo = Misura.padding(9, 12)
        static let ricordo = Carattere(dimensione: 13.5, peso: .medium)
        static let fonteRicordo = Carattere.secondario
        static let avatarRicordo: CGFloat = 28
        static let titoloColonna = Carattere(dimensione: 17, peso: .bold)
        static let titoloPagina = Carattere(dimensione: 22, peso: .bold)
        static let pillola = Carattere(dimensione: 12, peso: .semibold)
        static let fondoPillola = Colore.chip
        static let testoPillola = Colore.inchiostro2
        static let paddingPillola = Misura.padding(4, 10)
        static let filetto = Colore.separatore
        static let tasto: CGFloat = 22

        // MARK: Il rilascio

        static let cornice = Colore.accento
        static let fondoCornice = Colore.accento.opacity(0.08)
        static let spessoreCornice: CGFloat = 2
        static let trattino: [CGFloat] = [8, 6]
        static let raggioCornice: CGFloat = Raggio.pannello
        static let testoCornice = Carattere(dimensione: 17, peso: .semibold)
        static let notaCornice = Carattere.secondario

        // MARK: La Biblioteca

        static let colonnaTesti: CGFloat = 300
        static let colonnaArticoli: CGFloat = 260
        static let titoloTesto = Carattere(dimensione: 13.5, peso: .semibold)
        static let siglaTesto = Carattere.secondario
        static let titoloArticolo = Carattere(dimensione: 13, peso: .semibold)
        static let testoArticolo = Carattere(dimensione: 14, peso: .regular, interlinea: 1.5)
        static let paddingVoce = Misura.padding(8, 11)
        static let fondoScelto = Colore.accento.opacity(0.12)
        static let spazioBiblioteca: CGFloat = 14
        static let paddingBiblioteca: CGFloat = 18
        static let paddingArticolo: CGFloat = 16
    }
}
