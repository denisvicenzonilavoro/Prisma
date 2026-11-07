import SwiftUI

// Gettoni dell'app Incontri (gerarchia di Design/iphone.html: una cosa principale grande in alto,
// poi ciò che serve per decidere, il resto a un tocco). Ricavati dal tema Apple (Tema.Apple, AltreAppApple.swift):
// colori dinamici chiari e scuri e scala tipografica del template, nessun valore sparso nelle viste.

extension Tema.Colore {
    /// Nel tema Apple (Design/template-apple-specifica.md §1.1, §1.2): inchiostri, verde, accento, chip e binario.
    enum Incontri {
        private typealias A = Tema.Apple.Colore
        /// Il testo principale (cliente, titoli) e quello di contorno.
        static let testo = A.inchiostro
        static let secondario = A.inchiostro2
        static let terziario = A.inchiostro3
        /// Indicatore del percorso: passo fatto (verde), passo aperto (accento), passo da fare (binario).
        static let passoFatto = A.verde
        static let passoFattoFondo = A.verde.opacity(Tema.Apple.AltreApp.alfaFondoVerde)
        static let passoCorrente = A.accento
        static let passoDaFare = A.inchiostro3
        static let passoDaFareFondo = A.binario
        static let filoPasso = A.binario
        static let testoSuPasso = Tema.Apple.Controlli.Pulsante.testoPrincipale
        /// Fondo dei gettoni (quando, tipo, priorità, variazioni) e dei pozzetti.
        static let gettone = A.chip
        /// Tema scelto / non scelto nella preparazione.
        static let temaNonScelto = A.inchiostro3
        /// Stato dei dati di un tema: confermati (verde) o da verificare (arancio).
        static let datiConfermati = A.verde
        static let datiDaVerificare = A.arancio
        /// Cifre del dossier: scadenze vicine (rosso) e proposte aperte (arancio), quando ce ne sono.
        static let cifraScadenze = A.rosso
        static let cifraProposte = A.arancio
        static let filo = A.separatore
        /// Proposta spuntata nei prossimi passi.
        static let propostaScelta = A.selezioneVoce
        static let spunta = A.accento
    }
}

extension Tema.Testo {
    /// La scala del tema Apple (§1.7), con la «Dimensione del testo» dei caratteri di sempre.
    enum Incontri {
        private typealias C = Tema.Apple.Carattere
        /// Il nome del cliente nella testata: la cosa principale, grande (come il nome del dossier).
        static let cliente = C.nomeDossier.fontLeggibile
        /// Il titolo dell'incontro sotto il nome.
        static let titolo = C(dimensione: 15, peso: .medium).fontLeggibile
        /// Gettoni della testata (quando, tipo, durata).
        static let gettone = C.canale.fontLeggibile
        /// Indicatore del percorso.
        static let passoNumero = C(dimensione: 12, peso: .bold, tabellare: true).fontLeggibile
        static let passo = C.barra.fontLeggibile
        static let passoSpento = C(dimensione: 13, peso: .regular).fontLeggibile
        /// Occhielli delle sezioni («PRIORITÀ», «DAL DOSSIER»…): `.lbl`.
        static let occhiello = C.etichetta.fontLeggibile
        /// Cifre chiave del dossier e loro etichette.
        static let cifra = Tema.Apple.AltreApp.cifraPiccola.fontLeggibile
        static let cifraEtichetta = C.secondario.fontLeggibile
        /// Una riga breve (una proposta, una scadenza, la data dell'ultima volta).
        static let riga = C.secondario.fontLeggibile
        static let rigaForte = C.pulsante.fontLeggibile
        /// Priorità del cliente e variazioni dal riesame, in capsula.
        static let priorita = C.pulsante.fontLeggibile
        static let variazione = C(dimensione: 12, peso: .medium).fontLeggibile
        /// Le schede dei temi: area e domanda.
        static let tema = C(dimensione: 14, peso: .semibold).fontLeggibile
        static let temaDomanda = C.secondario.fontLeggibile
        /// Le domande dell'ascolto e il suggerimento dentro il campo vuoto.
        static let domanda = C(dimensione: 14, peso: .semibold).fontLeggibile
        static let segnaposto = C.corpo.fontLeggibile
        /// Titolo di una sezione (le proposte dei prossimi passi).
        static let sezione = Tema.Apple.AltreApp.titoloScheda.fontLeggibile
        /// Proposte: occhiello del tipo, titolo e frase di origine.
        static let tipoProposta = C(dimensione: 11, peso: .semibold).fontLeggibile
        static let proposta = C(dimensione: 13.5, peso: .semibold).fontLeggibile
        static let fonte = Tema.Apple.AltreApp.nota.fontLeggibile
        /// Note di contorno (la chiusura, il piede).
        static let nota = Tema.Apple.AltreApp.nota.fontLeggibile
    }
}

extension Tema.Misura {
    enum Incontri {
        /// Testata: avatar del cliente, margini, spazi.
        static let avatar: CGFloat = Tema.Apple.Misura.Avatar.dossier
        static let margineTestata = Tema.Apple.Misura.Padding.cardGrande
        static let spazioTestata: CGFloat = 14
        static let spazioRigheTestata: CGFloat = 4
        static let spazioGettoni: CGFloat = 6
        /// Spaziatura delle lettere degli occhielli in maiuscolo.
        static let trackingOcchiello: CGFloat = Tema.Apple.Carattere.etichetta.tracking
        /// Gettone in capsula: altezza minima e margine laterale.
        static let gettone: CGFloat = 24
        static let margineGettone: CGFloat = 9
        static let spazioSimboloGettone: CGFloat = 5
        /// Indicatore del percorso: cerchio di un passo, filo tra i passi, spazio sotto il cerchio.
        static let passo: CGFloat = 28
        static let filoPasso: CGFloat = 2
        static let lunghezzaFilo: CGFloat = 36
        static let spazioPasso: CGFloat = 5
        static let larghezzaPasso: CGFloat = 92
        /// Tessere «per decidere» (priorità, dossier, cambiato): margine interno e spazi.
        static let margineTessera = Tema.Apple.Misura.Padding.cardPiccola
        static let spazioTessera: CGFloat = 10
        static let spazioCifre: CGFloat = 16
        /// Cifra chiave: spazio tra il numero e l'etichetta, riduzione massima del numero lungo.
        static let spazioCifra: CGFloat = 1
        static let scalaMinimaCifra: CGFloat = 0.7
        static let righeDossier = 2
        /// Sopra questa larghezza le tessere «per decidere» stanno in fila, sotto una sotto l'altra.
        static let sogliaFila: CGFloat = 720
        /// Larghezze dei menu del cliente e dell'incontro nella barra.
        static let menuCliente: CGFloat = 190
        static let menuIncontro: CGFloat = 300
        /// Le schede dei temi: margine interno, pallino dello stato, simbolo dell'area.
        static let margineTema = Tema.Apple.Misura.Padding.tile
        static let pallino: CGFloat = 7
        static let simboloTema: CGFloat = 26
        /// Ultima volta: righe delle decisioni prima di «Mostra tutto».
        static let righeUltimaVolta = 2
        /// Oltre questi caratteri le decisioni dell'ultima volta si aprono con «Mostra tutto».
        static let caratteriBreve = 110
        /// Ascolto: numero della domanda.
        static let numeroDomanda: CGFloat = 22
        /// Rientro del suggerimento nel campo vuoto (allineato al testo dell'editor).
        static let rientroSegnaposto = EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        /// Prossimi passi: margini della riga di una proposta, spazio tra le righe.
        static let marginePropostaV: CGFloat = 8
        static let marginePropostaO: CGFloat = 11
        static let spazioProposte: CGFloat = 6
        /// Spazio tra il titolo di una proposta e la frase degli appunti.
        static let spazioRigaProposta: CGFloat = 2
        /// Incontro concluso: larghezza minima di una colonna dei testi archiviati.
        static let colonnaArchivio: CGFloat = 300
    }
}

extension Tema.Icona {
    enum Incontri {
        /// Simbolo di un tema della preparazione (le quattro aree dell'Analisi 360).
        static func tema(_ a: AreaAnalisi) -> String {
            switch a {
            case .previdenza: return "sun.horizon.fill"
            case .protezione: return "shield.fill"
            case .investimenti: return "chart.line.uptrend.xyaxis"
            case .risparmio: return "eurosign.circle.fill"
            }
        }

        /// Simbolo di una fase del percorso.
        static func fase(_ s: SchedaIncontro) -> String {
            switch s {
            case .preparazione: return "list.bullet.rectangle"
            case .ascolto: return "ear"
            case .passi: return "arrow.right.circle"
            }
        }
    }
}
