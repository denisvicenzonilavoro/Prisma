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
        /// La lettura a voce: l'anello del conto alla rovescia (rubino, come nel template), i secondi al centro, le sezioni
        /// non ancora dette in trasparenza (template `.s30`, opacità 0,25 → 1 in 0,5 s).
        static let anelloTrenta: CGFloat = 46
        static let spessoreAnelloTrenta: CGFloat = 4.5
        static let coloreAnelloTrenta = Color.dinamico(chiaro: Color(hex: "#C2264B"), scuro: Color(hex: "#FF5C83"))
        static let binarioAnelloTrenta = Colore.chip
        static let secondiTrenta = Carattere(dimensione: 15, peso: .bold)
        static let spazioAscolto: CGFloat = 10
        static let opacitaAttesa: Double = 0.25
        static let cambioSezione = 0.5
        static let fineAnello = 0.4
        static let fondoSezioneDetta = Color.dinamico(chiaro: Color(hex: "#C2264B").opacity(0.06), scuro: Color(hex: "#FF5C83").opacity(0.10))
        /// La card nella Panoramica del dossier («Raccontami Marco»).
        static let sferaCardTrenta: CGFloat = 30
        static let titoloCardTrenta = Carattere(dimensione: 14, peso: .bold)
        static let sottotitoloCardTrenta = Carattere(dimensione: 12.5, peso: .regular)

        // MARK: Lascia cadere qui · dati letti, scelta del cliente, «Archiviati da Vera oggi»

        /// I dati letti da correggere uno per uno prima di «Conferma»: etichetta a sinistra, campo a destra, la pagina.
        static let titoloCampiLetti = Carattere(dimensione: 12.5, peso: .semibold)
        static let etichettaCampo = Carattere(dimensione: 12.5, peso: .regular)
        static let valoreCampo = Carattere(dimensione: 13, peso: .medium)
        static let larghezzaEtichettaCampo: CGFloat = 150
        static let larghezzaValorePosizione: CGFloat = 120
        static let spazioCampi: CGFloat = 5
        static let paddingCampiLetti = Misura.padding(10, 12)
        /// La scelta del cliente: un pulsante per cliente con l'avatar.
        static let avatarScelta: CGFloat = 22
        static let spazioScelta: CGFloat = 8
        /// Le righe di «Archiviati da Vera oggi»: il foglietto con il colore del tipo (template `rigaD`), la pillola, dove.
        static let foglietto = CGSize(width: 22, height: 28)
        static let raggioFoglietto: CGFloat = 3
        static let testataFoglietto: CGFloat = 4
        static let fondoFoglietto = Color.white
        static let massimoArchiviati = 4
        static let spazioArchiviati: CGFloat = 8
        static let titoloArchiviato = Carattere(dimensione: 12.5, peso: .semibold)
        static let dettaglioArchiviato = Carattere(dimensione: 11.5, peso: .regular)
        static func coloreTipo(_ c: CategoriaDocumento) -> Color {
            switch c {
            case .kid: return Color(hex: "#2563EB")
            case .identita: return Color(hex: "#8B5CF6")
            default: return Colore.inchiostro2
            }
        }
        static func coloreTipo(_ t: Documento.Tipo, categoria c: CategoriaDocumento) -> Color {
            if c == .identita || c == .kid { return coloreTipo(c) }
            switch t {
            case .estrattoConto: return Color(hex: "#2FA35A")
            case .polizza: return Color(hex: "#E08A00")
            case .kid: return Color(hex: "#2563EB")
            default: return Colore.inchiostro2
            }
        }

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
