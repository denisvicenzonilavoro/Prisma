import SwiftUI

// La scheda «L'azienda» del dossier (Design/template-luce-specifica.md §9.3.2, «Luce» giro 7). Le viste stanno in
// Shell/DossierAzienda.swift e Shell/ModuloAzienda.swift; qui solo i valori.

extension Tema.Apple {
    enum Azienda {
        // MARK: Testata (card piatta, padding 18/22, in riga con spazio 16)

        static let superficie = Tema.Apple.Superficie.cardPiatta
        static let paddingTestata = Tema.Apple.Misura.padding(18, 22)
        static let spazioTestata: CGFloat = 16
        /// Il tassello del glifo `azienda` (48, #3F5A78).
        static let tassello: CGFloat = 48
        /// Display 21, 700 (come `.h2` del template).
        static let nome = Tema.Apple.Carattere(dimensione: 21, peso: .bold, tracking: -0.4)
        static let coloreNome = Tema.Apple.Colore.inchiostro
        /// La riga sotto il nome (`.k`).
        static let sotto = Tema.Apple.Carattere.secondario
        static let coloreSotto = Tema.Apple.Colore.inchiostro2
        static let spazioNomeSotto: CGFloat = 3
        /// «Fatturato 2025» `.k` e la cifra 20 grassetto, allineati a destra.
        static let etichettaFatturato = Tema.Apple.Carattere.secondario
        static let coloreEtichettaFatturato = Tema.Apple.Colore.inchiostro2
        static let fatturato = Tema.Apple.Carattere(dimensione: 20, peso: .bold, tabellare: true)
        static let coloreFatturato = Tema.Apple.Colore.inchiostro
        /// «da inserire» al posto della cifra.
        static let fatturatoMancante = Tema.Apple.Carattere(dimensione: 15, peso: .semibold)
        static let coloreFatturatoMancante = Tema.Apple.Colore.inchiostro3

        // MARK: Più aziende (decisione 3.4: la scelta in testa alla scheda)

        static let sottoScelta: CGFloat = 12

        // MARK: Le quattro schede (griglia a 4 colonne, spazio 12, 12 sopra)

        static let colonne = 4
        static let spazioSchede: CGFloat = 12
        static let sopraSchede: CGFloat = 12
        /// Sotto questa larghezza di scheda la griglia va a 2 colonne (la finestra stretta).
        static let larghezzaMinimaScheda: CGFloat = 196
        static let paddingScheda: CGFloat = 18
        static let raggio = Tema.Apple.Raggio.card
        static let inclinazioneMassima: Double = Tema.Apple.Moto.Inclinazione.massimoAree
        /// Anello 76 / 9 con la percentuale 15 grassetto.
        static let anello: CGFloat = 76
        static let spessoreAnello: CGFloat = 9
        static let percentuale = Tema.Apple.Carattere(dimensione: 15, peso: .bold, tabellare: true)
        static let colorePercentuale = Tema.Apple.Colore.inchiostro
        /// L'anello vuoto grigio «—» (dato mancante o area non pertinente).
        static let anelloVuoto = Tema.Apple.Colore.inchiostro3
        static let coloreTrattino = Tema.Apple.Colore.inchiostro3
        static let titolo = Tema.Apple.Carattere.titoloRiga
        static let coloreTitolo = Tema.Apple.Colore.inchiostro
        static let coloreTitoloSpento = Tema.Apple.Colore.inchiostro2
        static let sopraTitolo: CGFloat = 12
        static let testo = Tema.Apple.Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let coloreTesto = Tema.Apple.Colore.inchiostro2
        static let sopraTesto: CGFloat = 4
        static let collegamento = Tema.Apple.Carattere(dimensione: 13, peso: .semibold)
        static let coloreCollegamento = Tema.Apple.Colore.accento
        static let coloreCollegamentoSpento = Tema.Apple.Colore.inchiostro3
        static let sopraCollegamento: CGFloat = 10
        /// «Non pertinente»: la scheda in grigio.
        static let opacitaNonPertinente: Double = 0.62
        /// Il ritardo degli anelli dopo il cambio di scheda (0,15, come `accendi(t,150)`), poi + i·0,13.
        static let ritardoAnelli = Tema.Apple.Clienti.Moto.ritardoAnelli

        // MARK: Piede (`.k`, 12 sopra)

        static let piede = Tema.Apple.Carattere.secondario
        static let colorePiede = Tema.Apple.Colore.inchiostro2
        static let sopraPiede: CGFloat = 12

        // MARK: Nessuna azienda (scheda aperta da «Altro › Azienda»)

        static let vuotoFrase = Tema.Apple.Carattere.titoloRiga
        static let vuotoNota = Tema.Apple.Carattere.secondario
        static let spazioVuoto: CGFloat = 10

        // MARK: Il dettaglio di un'area (nasce dalla scheda)

        static let misuraDettaglio = CGSize(width: 640, height: 500)
        static let anelloDettaglio: CGFloat = 120
        static let spessoreAnelloDettaglio: CGFloat = 13
        static let percentualeDettaglio = Tema.Apple.Carattere.centroAnello(26)
        static let titoloDettaglio = Tema.Apple.Carattere.titoloDettaglio(26)
        static let etichettaDettaglio = Tema.Apple.Carattere.etichetta
        static let spazioDettaglio: CGFloat = 18
        static let spazioRighe: CGFloat = 8
        static let rigaEtichetta = Tema.Apple.Carattere(dimensione: 13.5, peso: .regular)
        static let rigaValore = Tema.Apple.Carattere(dimensione: 13.5, peso: .semibold, tabellare: true)
        static let filo = Tema.Apple.Colore.separatore

        // MARK: Il modulo (foglio, come quello del familiare)

        static let modulo = CGSize(width: 680, height: 640)
        static let campoAnno: CGFloat = 64
        /// Le voci proposte da aggiungere, in colonne di almeno questa larghezza.
        static let colonnaProposta: CGFloat = 200

        /// I colori delle quattro aree: rosso, arancio, blu degli investimenti, viola della previdenza (template).
        enum Tinta {
            static func colore(_ area: AreaAzienda) -> Color {
                switch area {
                case .personaChiave: return Tema.Apple.Colore.Area.protezione
                case .tfm: return Tema.Apple.Colore.arancio
                case .welfare: return Tema.Apple.Colore.Area.investimenti
                case .passaggio: return Tema.Apple.Colore.Area.previdenza
                }
            }
        }
    }
}
