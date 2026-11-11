import SwiftUI

// Studio › Cruscotto, Impostazioni › Studio e il riquadro «Il tuo studio» della scrivania (versione «Orizzonte»,
// Design/template-novita-specifica.md §1.5, §2.4 e §2 di Studio): misure, caratteri, colori e tempi. Le viste stanno in
// Shell/Studio*.swift; qui solo i valori, tutti ricavati dal tema Apple. Le cifre arrivano da MotoreStudio.

extension Tema.Apple {
    enum Studio {
        // MARK: Colori fissi (uguali in chiaro e in scuro, come nel template)

        /// Anelli e pallini della legenda degli obiettivi, dall'esterno: produzione Alleanza (#2563EB), nuovi clienti
        /// (`anello1`), ricavi della consulenza (#B06E12). Fissi: in scuro non diventano i colori dei canali schiariti.
        static let anelloAlleanza = Color(hex: "#2563EB")
        static let anelloNuoviClienti = Colore.anello1
        static let anelloConsulenza = Color(hex: "#B06E12")

        /// Il colore dell'anello di una voce degli obiettivi.
        static func colore(_ voce: VoceObiettivoStudio) -> Color {
            switch voce {
            case .produzioneAlleanza: return anelloAlleanza
            case .nuoviClienti: return anelloNuoviClienti
            case .ricaviConsulenza: return anelloConsulenza
            }
        }

        // MARK: Disposizione del Cruscotto

        enum Disposizione {
            /// Le cinque card su due righe: 560 : 408 : 384 e 760 : 608, alte 300 e 338 (su 654) nel palco.
            static let quoteRigaAlta: [CGFloat] = [560, 408, 384]
            static let quoteRigaBassa: [CGFloat] = [760, 608]
            static let rigaAlta: CGFloat = 300
            static let rigaBassa: CGFloat = 338
            /// Sotto queste altezze le righe non scendono: il resto scorre.
            static let rigaAltaMinima: CGFloat = 286
            static let rigaBassaMinima: CGFloat = 300
            /// Spazio fra le card, in orizzontale e in verticale.
            static let spazio: CGFloat = 16
            /// Sotto questa larghezza le card vanno in colonna, una sotto l'altra (iPhone, finestre strette).
            static let larghezzaColonna: CGFloat = 900
        }

        // MARK: Card

        enum Card {
            /// `.card`: raggio 22, card del tema con l'ombra, padding 22×24.
            static let superficie = Superficie.card
            static let raggio = Raggio.card
            static let padding = Misura.Padding.cardGrande
            /// Inclinazione delle card verso il puntatore (solo quella sotto il puntatore): leggera, come le card grandi.
            static let inclinazione = Tema.Apple.Moto.Inclinazione.massimoImpegni
            /// `.lbl`: 12 semibold maiuscolo, `inchiostro2`.
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            /// `.k`: didascalie e frasi degli stati vuoti.
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
            /// «dati di prova» accanto al titolo della card.
            static let prova = Carattere.secondario
            static let coloreProva = Colore.arancio
            static let spazioProva: CGFloat = 8
            /// Quanto si può stringere un testo di una riga prima di andare a capo o tagliarsi.
            static let riduzioneTesto: CGFloat = 0.75
            /// La frase di uno stato vuoto, sotto il titolo.
            static let vuotoSopra: CGFloat = 12
            /// Il pulsante di uno stato vuoto («Inserisci le tue aliquote», «Imposta gli obiettivi»).
            static let pulsanteSopra: CGFloat = 12
        }

        // MARK: Card 1 · I tuoi ricavi

        enum Ricavi {
            /// Il totale: display 52 bold, spaziatura −2,2, cifre tabellari, interlinea 1.
            static let totale = Carattere(dimensione: 52, peso: .bold, tracking: -2.2, interlinea: 1, tabellare: true)
            static let coloreTotale = Colore.inchiostro
            static let riduzioneTotale: CGFloat = 0.6
            static let totaleSopra: CGFloat = 10
            static let spazioTotale: CGFloat = 14
            /// «+18% sul 2025»: 15 semibold, verde (rosso se scende); «primo anno in Prisma» in `inchiostro2`.
            static let variazione = Carattere.delta
            static let coloreSale = Colore.verde
            static let coloreScende = Colore.rosso
            static let colorePrimoAnno = Colore.inchiostro2
            static let sottoVariazione: CGFloat = 6
            /// Le due tessere dei canali: `.tile` (raggio 18, padding 14×16), 10 fra loro, 14 sotto il totale.
            static let tessera = Superficie.tile
            static let raggioTessera = Raggio.tile
            static let paddingTessera = Misura.Padding.tile
            static let spazioTessere: CGFloat = 10
            static let tessereSopra: CGFloat = 14
            static let valoreTessera = Carattere.valore
            static let coloreValore = Colore.inchiostro
            static let riduzioneValore: CGFloat = 0.6
            static let spazioTessera: CGFloat = 4
            /// La linea dei ricavi cumulati: alta 56, 12 sotto le tessere.
            static let graficoSopra: CGFloat = 12
            static let altezzaGrafico: CGFloat = 56
            /// L'anno in corso: linea piena #0A84FF da 2,6; l'anno prima: tratteggiata 4 5, `inchiostro3`, da 2.
            static let coloreAnno = Colore.anello2
            static let spessoreAnno: CGFloat = 2.6
            static let colorePrima = Colore.inchiostro3
            static let spessorePrima: CGFloat = 2
            static let tratteggioPrima: [CGFloat] = [4, 5]
            /// La scala arriva al più alto dei due valori finali, con un po' di margine sopra.
            static let margineScala: Double = 1.06
            /// Etichette in fondo a destra: «2026» 11 semibold blu, 6 sopra la fine della linea; «2025» 11 `inchiostro3`.
            static let etichettaAnno = Carattere(dimensione: 11, peso: .semibold, tabellare: true)
            static let etichettaPrima = Carattere(dimensione: 11, peso: .regular, tabellare: true)
            static let sopraLinea: CGFloat = 6
            static let sottoLinea: CGFloat = 14
            static let larghezzaEtichetta: CGFloat = 48
            /// Dalla linea di base al centro di un'etichetta da 11 (per metterla a 6 sopra o 14 sotto la linea).
            static let centroEtichetta: CGFloat = 4
        }

        // MARK: Card 2 · Gli obiettivi dell'anno

        enum Obiettivi {
            /// Tre anelli concentrici da 170, spessore 15, 14 sotto il titolo, 18 dalla legenda.
            static let anelli: CGFloat = 170
            static let spessore: CGFloat = 15
            static let sopra: CGFloat = 14
            static let spazio: CGFloat = 18
            /// La legenda `.leg`: 13 con interlinea 1,35, voci con padding 10 sopra e sotto e il filo fra loro.
            static let voce = Carattere(dimensione: 13, peso: .regular, interlinea: 1.35)
            static let coloreVoce = Colore.inchiostro
            static let dettaglio = Carattere.secondario
            static let coloreDettaglio = Colore.inchiostro2
            /// La nota di una voce («dalla data di inserimento in Prisma»).
            static let avviso = Carattere(dimensione: 11.5, peso: .regular)
            static let coloreAvviso = Colore.inchiostro3
            static let paddingVoce: CGFloat = 10
            /// Fra il nome della voce, il dettaglio e la nota.
            static let spazioTesti: CGFloat = 1
            static let spazioPallino: CGFloat = 12
            static let pallino: CGFloat = 10
            static let filo = Colore.separatore
            /// Una voce senza traguardo: il pallino in `inchiostro3`.
            static let pallinoSenza = Colore.inchiostro3
        }

        // MARK: Card 3 · L'imbuto delle proposte

        enum Imbuto {
            static let riga = Carattere(dimensione: 13, peso: .regular)
            static let numero = Carattere(dimensione: 13, peso: .bold, tabellare: true)
            static let coloreRiga = Colore.inchiostro
            /// Barre alte 14, raggio 8, binario `binario`; la prima 16 sotto il titolo, le altre 10 sotto, 4 dalla riga.
            static let barra: CGFloat = 14
            static let raggioBarra: CGFloat = 8
            static let primaSopra: CGFloat = 16
            static let fraRighe: CGFloat = 10
            static let barraSopra: CGFloat = 4
            /// Preparate #9FB3C2, presentate #5AC8FA, firmate #30B15C.
            static let colorePreparate = Colore.Composizione.liquidita
            static let colorePresentate = Colore.Composizione.obbligazionario
            static let coloreFirmate = Colore.anello1
            /// Le due cifre sotto (`.v` a 24), 16 sotto le barre, 18 fra loro.
            static let cifra = Carattere(dimensione: 24, peso: .bold, tracking: -0.5, tabellare: true)
            static let coloreCifra = Colore.inchiostro
            static let cifreSopra: CGFloat = 16
            static let spazioCifre: CGFloat = 18
            static let fraseSopra: CGFloat = 8
        }

        // MARK: Card 4 · Gli incassi dei prossimi 12 mesi

        enum Incassi {
            /// Il totale a destra del titolo: display 20 bold.
            static let totale = Carattere(dimensione: 20, peso: .bold, tabellare: true)
            static let coloreTotale = Colore.inchiostro
            /// Le colonne: contenitore alto 220, 16 sotto la didascalia, 12 fra le colonne, colonna piena fino a 190.
            static let altezza: CGFloat = 220
            static let sopra: CGFloat = 16
            static let spazioColonne: CGFloat = 12
            static let colonnaMassima: CGFloat = 190
            /// Due parti per colonna, 2 fra loro: Alleanza sotto, indipendente sopra (al 90%).
            static let fraParti: CGFloat = 2
            static let raggioEsterno: CGFloat = 6
            static let raggioInterno: CGFloat = 2
            static let coloreAlleanza = Colore.canaleAlleanza
            static let coloreIndipendente = Colore.canaleIndipendente
            static let opacitaIndipendente: Double = 0.9
            /// Il mese sotto la colonna: 11 `inchiostro2`, 6 sotto.
            static let mese = Carattere.asse
            static let coloreMese = Colore.inchiostro2
            static let sottoColonna: CGFloat = 6
            static let altezzaMese: CGFloat = 14
            /// Le etichette dei due canali sopra le colonne (il canale resta sempre riconoscibile), 8 sotto la didascalia.
            static let legendaSopra: CGFloat = 8
            static let spazioLegenda: CGFloat = 8
        }

        // MARK: Card 5 · Il valore e il tempo

        enum Dispersione {
            /// Il grafico alto 250, 12 sotto la didascalia: 20 in fondo per le etichette degli assi.
            static let altezza: CGFloat = 250
            static let sopra: CGFloat = 12
            static let margineAssi: CGFloat = 20
            /// I clienti in evidenza: cerchi da 28 con le iniziali e l'ombra; gli altri pallini da 12 in `inchiostro3` al 55%.
            static let puntoNome: CGFloat = 28
            static let punto: CGFloat = 12
            static let colorePunto = Colore.inchiostro3
            static let opacitaPunto: Double = 0.55
            static let ombraNome = Color(r: 0, g: 0, b: 0, a: 0.22)
            static let raggioOmbraNome: CGFloat = 5
            static let yOmbraNome: CGFloat = 4
            /// Quanti clienti hanno le iniziali (prima i preferiti, poi quelli con più ore).
            static let massimoNomi = 5
            /// La zona «molto tempo, poco valore»: raggio 12, rosso al 7%, scritta 11 rossa in basso a destra.
            static let zona = Color(r: 229, g: 72, b: 77, a: 0.07)
            static let raggioZona: CGFloat = 12
            static let scrittaZona = Carattere(dimensione: 11, peso: .regular)
            static let coloreScrittaZona = Colore.rosso
            static let margineScritta: CGFloat = 6
            /// Etichette degli assi: 11 `inchiostro3`.
            static let asse = Carattere.asse
            static let coloreAsse = Colore.inchiostro3
            /// L'asse delle ore arriva a un multiplo di questo passo (5, 10, 15… ore).
            static let passoOre: Double = 5
            /// Margine sopra il valore più alto dei ricavi.
            static let margineRicavi: Double = 1.1
        }

        // MARK: Schede che arrivano

        enum Prossime {
            /// La nota sobria delle schede future: card piatta, larga al più 560.
            static let superficie = Superficie.cardPiatta
            static let raggio = Raggio.card
            static let padding = Misura.Padding.cardMedia
            static let larghezza: CGFloat = 560
            static let titolo = Carattere.titoloRiga
            static let coloreTitolo = Colore.inchiostro
            static let testo = Carattere.corpo
            static let coloreTesto = Colore.inchiostro2
            static let spazio: CGFloat = 6
            static let sopra: CGFloat = 4
        }

        // MARK: Modalità cliente

        enum Riservato {
            static let titolo = Carattere.titoloRiga
            static let coloreTitolo = Colore.inchiostro
            static let testo = Carattere.secondario
            static let coloreTesto = Colore.inchiostro2
        }

        // MARK: Riquadro «Il tuo studio» sulla scrivania

        enum Scrivania {
            /// Tre anelli da 116, tratto 11; sugli schermi bassi si stringono fino a 48.
            static let anelli: CGFloat = 116
            static let anelliMinimi: CGFloat = 48
            static let spessore: CGFloat = 11
            /// Anelli, testata e cifre in fila, 22 fra loro.
            static let spazio: CGFloat = 22
            /// La testata «Il tuo studio · novembre» e «Apri Studio» (stessi caratteri dei riquadri).
            static let titolo = Tema.Apple.Scrivania.Riquadro.titolo
            static let collegamento = Tema.Apple.Scrivania.Riquadro.collegamento
            static let coloreCollegamento = Tema.Apple.Scrivania.Riquadro.coloreCollegamento
            /// Tre cifre in fila, 10 sotto la testata, 30 fra loro: etichetta `.k`, cifra display 26 bold.
            static let cifreSopra: CGFloat = 10
            static let spazioCifre: CGFloat = 30
            static let etichetta = Carattere.secondario
            static let coloreEtichetta = Colore.inchiostro2
            static let cifra = Carattere(dimensione: 26, peso: .bold, tabellare: true)
            static let coloreCifra = Colore.inchiostro
            static let riduzioneCifra: CGFloat = 0.6
            /// «Da incassare» in arancio quando c'è qualcosa da incassare.
            static let coloreDaIncassare = Colore.arancio
            /// La nota sotto le cifre (aliquote o obiettivi mancanti).
            static let nota = Carattere(dimensione: 12, peso: .regular)
            static let coloreNota = Colore.inchiostro2
            static let notaSopra: CGFloat = 8
            /// Gli anelli dello studio partono dopo i tre del portafoglio (indici 3, 4 e 5).
            static let anelliPrima = 3
        }

        // MARK: Impostazioni › Studio

        enum Impostazioni {
            /// Un campo numerico (percentuale o importo) nella riga, con la sua etichetta sopra.
            static let campoPercentuale: CGFloat = 78
            static let campoImporto: CGFloat = 130
            static let campoNumero: CGFloat = 78
            static let etichettaCampo = Carattere(dimensione: 11.5, peso: .medium)
            static let coloreEtichettaCampo = Colore.inchiostro2
            static let spazioEtichetta: CGFloat = 3
            static let spazioCampi: CGFloat = 12
            static let unita = Carattere.secondario
            static let coloreUnita = Colore.inchiostro2
            static let spazioUnita: CGFloat = 4
        }

        // MARK: Movimento

        enum Moto {
            /// Le colonne degli incassi: scala y 0 → 1 dal basso in 0,8 s, curva (.34, 1.3, .64, 1), ritardo 0,30 + i·0,055.
            static let durataColonne = 0.80
            static let ritardoColonne = 0.30
            static let passoColonne = 0.055
            static let curvaColonne = Tema.Apple.Moto.Curva(x1: 0.34, y1: 1.3, x2: 0.64, y2: 1)
            static var animazioneColonne: Animation { curvaColonne.animazione(durataColonne) }
            static func ritardoColonna(_ i: Int) -> Double { ritardoColonne + Double(i) * passoColonne }
            /// I punti della dispersione: scala 0 → 1 in 0,5 s, curva (.34, 1.6, .64, 1), ritardo 0,40 + min(i, 24)·0,025
            /// (prima quelli con le iniziali, poi gli altri; con tanti clienti la cascata non supera 1 s).
            static let durataPunti = 0.50
            static let ritardoPunti = 0.40
            static let passoPunti = 0.025
            static let indiceMassimoPunti = 24
            static let curvaPunti = Tema.Apple.Moto.Curva(x1: 0.34, y1: 1.6, x2: 0.64, y2: 1)
            static var animazionePunti: Animation { curvaPunti.animazione(durataPunti) }
            static func ritardoPunto(_ i: Int) -> Double { ritardoPunti + Double(min(i, indiceMassimoPunti)) * passoPunti }
            /// Cambio di scheda (`rimonta`): il contenuto svanisce in 0,13 s fino a scala 0,99, poi rientra a cascata da 0.
            static let durataRimonta = 0.13
            static let scalaRimonta: CGFloat = 0.99
            static var uscitaRimonta: Animation { .linear(duration: durataRimonta * Tema.Apple.Moto.ritmo) }
            /// Cascata: 0,14 all'apertura della finestra, 0 dopo un cambio di scheda; anelli 0,32 e 0,15.
            static let baseApertura = Tema.Apple.Moto.Cascata.baseFinestra
            static let baseCambio = Tema.Apple.Moto.Cascata.baseDentroApp
            static let anelliApertura = Tema.Apple.Moto.Anello.ritardoFinestra
            static let anelliCambio = Tema.Apple.Moto.Anello.ritardoCambio
        }
    }
}
