import SwiftUI

// L'iPhone nel tema Apple (Design/template-apple-specifica.md §5.1 e le note per iPhone e iPad; la gerarchia
// approvata è quella di Design/iphone.html). Stessa barra, acqua, dock e finestre di vetro del Mac; in ogni
// schermata una cosa principale grande in alto, poi ciò che serve per decidere, il resto a un tocco.
// Leggibilità (Design/iphone.html): testi da 13 a 15 pt, righe alte almeno 56, pulsanti alti 44; nomi e titoli mai
// tagliati per far posto alle etichette (il canale va sotto). Le schede scendono a 0,98 alla pressione
// (`.inclinazione`, variante iOS). Le viste stanno in Sources/Prisma/iOS/; qui solo i valori, ricavati dal tema.

extension Tema.Apple {
    enum Telefono {
        /// L'area minima di un dito: pulsanti alti 44.
        static let tocco: CGFloat = 44
        /// Le schede premute scendono a 0,98 (la variante iOS di `.inclinazione` usa solo la pressione: il massimo
        /// serve solo a tenerla accesa).
        static let inclinazione = Moto.Inclinazione.massimoPredefinito

        // MARK: Elenchi e schede delle app

        enum Elenco {
            /// Il contenuto a 12 dai bordi della finestra (§3.5), le schede a 10 l'una dall'altra.
            static let margine: CGFloat = Misura.Finestra.margineContenuto
            static let spazio: CGFloat = 10
            /// Una riga o una scheda: card piatta col filo, raggio 18, padding 14×16, alta almeno 56.
            static let superficie = Superficie.tile
            static let raggio: CGFloat = Raggio.tile
            static let padding = Misura.Padding.tile
            static let rigaMinima: CGFloat = 56
            /// Le righe dentro un riquadro (aree, impostazioni): padding 12×16, divise dal filo.
            static let paddingRigaInterna = Misura.padding(12, 16)
            /// Un pannello grande (il totale, il mese): card piatta, raggio 22, padding 18×18.
            static let superficiePannello = Superficie.cardPiatta
            static let raggioPannello: CGFloat = Raggio.card
            static let paddingPannello = Misura.padding(18, 18)
            static let spazioRiga: CGFloat = 12
            static let spazioTesto: CGFloat = 3
            static let spazioEtichette: CGFloat = 6
            /// Titolo della riga 15 semibold, dettaglio 13, valore 15 semibold tabellare, corpo 14,5.
            static let nome = Carattere(dimensione: 15, peso: .semibold)
            static let dettaglio = Carattere(dimensione: 13, peso: .regular)
            static let valore = Carattere(dimensione: 15, peso: .semibold, tabellare: true)
            static let corpo = Carattere(dimensione: 14.5, peso: .regular, interlinea: 1.45)
            static let simbolo = Carattere(dimensione: 15, peso: .semibold)
            static let chevron = Carattere(dimensione: 13, peso: .semibold)
            static let coloreNome = Colore.inchiostro
            static let coloreDettaglio = Colore.inchiostro2
            static let coloreTerziario = Colore.inchiostro3
            static let coloreSimbolo = Colore.accento
            static let coloreScaduto = Colore.rosso
            static let coloreVicino = Colore.scadenza
            /// Le sezioni: `.lbl` maiuscolo `inchiostro2`, 14 sopra e 2 sotto.
            static let sezione = Carattere.etichetta
            static let coloreSezione = Colore.inchiostro2
            static let sezioneSopra: CGFloat = 14
            static let sezioneSotto: CGFloat = 2
            static let sezioneLato: CGFloat = 4
            /// Elenco vuoto: `.k` dentro una tile.
            static let vuoto = Carattere(dimensione: 14, peso: .regular)
            /// Il titolo di un dettaglio (posizione, appuntamento, nota) e la cifra grande.
            static let titolo = Carattere.h2
            static let cifra = Carattere(dimensione: 30, peso: .bold, tracking: -0.8, tabellare: true)
            /// La larghezza fissa dell'icona a sinistra delle righe (documenti).
            static let icona: CGFloat = 28
            /// Una riga d'appuntamento: la barra di 3 nel colore del cliente.
            static let barra: CGFloat = 3
            /// Opacità degli appuntamenti conclusi.
            static let opacitaConcluso: Double = 0.6
            /// Le righe etichetta–valore dei dettagli.
            static let etichettaDato = Carattere.secondario
            static let valoreDato = Carattere(dimensione: 13.5, peso: .semibold)
            /// Il campo di testo (codice del Mac): `chip`, raggio 14, alto 44.
            static let fondoCampo = Colore.chip
            static let raggioCampo: CGFloat = Raggio.voce
        }

        /// La pastiglia «In essere» (verde) o «Proposta» (viola, come le proposte nei grafici e negli anelli).
        enum StatoPosizione {
            static let carattere = Carattere(dimensione: 11.5, peso: .semibold)
            static let padding = Misura.Padding.etichettaCanale
            static let testoInEssere = Colore.verde
            static let fondoInEssere = Colore.verde.opacity(0.13)
            static let testoProposta = Colore.stima
            static let fondoProposta = Colore.stima.opacity(0.13)
        }

        // MARK: Scrivania (Design/iphone.html, schermata 1)

        enum Scrivania {
            /// Margine sui lati, spazio fra i riquadri (la griglia del tema).
            static let margine: CGFloat = 16
            static let spazio: CGFloat = Misura.Spazio.griglia
            /// La data sopra il saluto (15 medium `inchiostroAcqua2`) e il saluto 32 bold `inchiostroAcqua`.
            static let data = Carattere(dimensione: 15, peso: .medium)
            static let coloreData = Colore.inchiostroAcqua2
            static let saluto = Carattere(dimensione: 32, peso: .bold, tracking: -1)
            static let coloreSaluto = Colore.inchiostroAcqua
            static let riduzioneSaluto: CGFloat = 0.75
            static let spazioSaluto: CGFloat = 2
            static let salutoSopra: CGFloat = 14
            static let salutoSotto: CGFloat = 18
            static let salutoLato: CGFloat = 4
            /// Il piede sull'acqua: 12,5 `inchiostroAcqua2`.
            static let piede = Carattere.secondario
            static let colorePiede = Colore.inchiostroAcqua2
            static let piedeSopra: CGFloat = 18
            static let spazioPiede: CGFloat = 3
            /// La cascata dei riquadri: base della scrivania (0,12).
            static let baseCascata = Moto.Cascata.baseScrivania
            /// I riquadri: vetro raggio 26, padding 18×20 (come sul Mac); la testata 14 bold con il collegamento.
            static let raggio: CGFloat = Raggio.riquadro
            static let testata = Carattere(dimensione: 14, peso: .bold)
            static let collegamento = Carattere(dimensione: 14, peso: .semibold)
            static let coloreCollegamento = Colore.accento
            static let sottoTestata: CGFloat = 12
            static let spazioPulsanti: CGFloat = 8
            static let pulsantiSopra: CGFloat = 16
        }

        /// La mossa del giorno in grande: la sfera con le iniziali, l'etichetta, il titolo 22 bold, il perché, poi
        /// due pulsanti alti 44 e, sotto il filo, il prossimo incontro.
        enum Mossa {
            static let sfera: CGFloat = 60
            static let iniziali = Carattere(dimensione: 20, peso: .bold)
            static let spazioSfera: CGFloat = 14
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.mossaDelGiorno
            static let titolo = Carattere(dimensione: 22, peso: .bold, tracking: -0.5)
            static let corpo = Carattere(dimensione: 14.5, peso: .regular, interlinea: 1.45)
            static let coloreCorpo = Colore.inchiostro2
            static let titoloSopra: CGFloat = 4
            static let corpoSopra: CGFloat = 10
            /// Il prossimo incontro sotto il filo: ora 15 semibold tabellare, titolo 13,5 semibold, «tra 25 minuti».
            static let incontroSopra: CGFloat = 16
            static let incontroPadding: CGFloat = 12
            static let ora = Carattere(dimensione: 15, peso: .semibold, tabellare: true)
            static let incontro = Carattere(dimensione: 13.5, peso: .semibold)
            static let quando = Carattere.quando
            static let coloreQuando = Colore.accento
            static let spazioIncontro: CGFloat = 10
            /// I due pulsanti affiancati: sugli iPhone stretti il testo si riduce appena, mai tagliato.
            static let riduzionePulsanti: CGFloat = 0.85
        }

        /// «Richiede attenzione»: il segno tondo 30 (rosso, arancio o accento), titolo 15 semibold, dettaglio 13.
        enum Attenzione {
            static let massimo = 3
            static let segno: CGFloat = 30
            static let simbolo = Carattere(dimensione: 13, peso: .bold)
            static let coloreSimbolo = Color.white
            static let urgente = Colore.rosso
            static let vicino = Colore.arancio
            static let oggi = Colore.accento
            static let paddingRiga: CGFloat = 10
        }

        /// La riga di Ruby: la sfera 40, «Ruby» 15 bold, la frase e lo stato di Qwen.
        enum RigaRuby {
            static let sfera: CGFloat = 40
            static let nome = Carattere(dimensione: 15, peso: .bold)
            static let frase = Carattere(dimensione: 13.5, peso: .regular)
            static let coloreFrase = Colore.inchiostro2
            static let coloreNonPronto = Colore.arancio
            static let spazio: CGFloat = 14
        }

        /// Il portafoglio: il totale 34 bold che conta, «in essere · 5 clienti», i tre anelli 104/11 e la legenda,
        /// sotto la barra dei canali.
        enum Portafoglio {
            static let totale = Carattere(dimensione: 34, peso: .bold, tracking: -1, tabellare: true)
            static let riduzioneTotale: CGFloat = 0.6
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
            static let anelli: CGFloat = 104
            static let spessoreAnelli: CGFloat = 11
            static let anelliSopra: CGFloat = 16
            static let spazioAnelli: CGFloat = 18
            /// Gli anelli partono a 0,30 dopo 0,30 (scrivania); senza movimento d'avvio a 0,20.
            static let ritardoAnelli = Moto.Anello.ritardoPredefinito
            static let legenda = Carattere(dimensione: 13, peso: .regular)
            static let legendaForte = Carattere(dimensione: 13, peso: .bold, tabellare: true)
            static let spazioLegenda: CGFloat = 10
            static let pallino: CGFloat = 8
            static let spazioPallino: CGFloat = 6
            static let coloreInRegola = Colore.anello1
            static let coloreRiesami = Colore.anello2
            static let coloreProposte = Colore.anello3
            static let canaliSopra: CGFloat = 18
            static let canale = Carattere(dimensione: 12.5, peso: .medium, tabellare: true)
            static let spazioCanali: CGFloat = 8
        }

        // MARK: Cliente (Design/iphone.html, schermata 2)

        enum Cliente {
            /// La testata: avatar 56, nome 26 bold (fino a due righe), motto · età · professione 13, i canali sotto.
            static let avatar: CGFloat = Misura.Avatar.dossier
            static let nome = Carattere(dimensione: 26, peso: .bold, tracking: -0.6)
            static let riduzioneNome: CGFloat = 0.8
            static let dettaglio = Carattere(dimensione: 13, peso: .regular)
            static let coloreDettaglio = Colore.inchiostro2
            static let spazioAvatar: CGFloat = 14
            static let spazioRighe: CGFloat = 3
            /// La cifra principale (patrimonio netto) 34 bold che conta, nel pannello con la barra dei canali.
            static let principale = Carattere(dimensione: 34, peso: .bold, tracking: -1, tabellare: true)
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            /// Le quattro tessere su due colonne: `.k`, il valore 19 bold che conta, la nota 12.
            static let spazioTessere: CGFloat = 10
            static let paddingTessera = Misura.padding(12, 14)
            static let tesseraMinima: CGFloat = 76
            static let voceTessera = Carattere.secondario
            static let valoreTessera = Carattere(dimensione: 19, peso: .bold, tracking: -0.3, tabellare: true)
            static let notaTessera = Carattere(dimensione: 12, peso: .regular)
            static let spazioTessera: CGFloat = 2
            /// Il segmentato delle schede, a 14 sopra e 4 sotto.
            static let schedeSopra: CGFloat = 4
            static let schedeSotto: CGFloat = 4
            /// Gli obiettivi: la barra che si riempie (8) sotto il titolo.
            static let barraSopra: CGFloat = 8
            /// Le righe della rubrica entrano a cascata fino alla nona; le altre insieme all'ultima.
            static let righeInCascata = 8
        }

        // MARK: Posizioni (Design/iphone.html, schermata 3)

        enum Posizioni {
            /// Il totale 34 bold che conta, la barra dei canali da 8, i canali con l'importo.
            static let totale = Carattere(dimensione: 34, peso: .bold, tracking: -1, tabellare: true)
            static let riduzioneTotale: CGFloat = 0.6
            static let barraSopra: CGFloat = 14
            static let barraSotto: CGFloat = 12
            static let spazioCanali: CGFloat = 8
            /// La striscia dell'area a sinistra della riga.
            static let striscia: CGFloat = 4
            static let altezzaStriscia: CGFloat = 34
            /// I debiti in negativo e in rosso.
            static let colorePassivo = Colore.rosso
            /// Il filtro a gettoni: capsule alte 36 (area di tocco 44), 13 semibold, padding 14, spazio 8; il pallino
            /// del canale (6) a 6 dal nome.
            static let pallino: CGFloat = Misura.Controllo.pallinoCanale
            static let spazioPallino: CGFloat = 6
            static let filtro = Carattere.barra
            static let paddingFiltro: CGFloat = 14
            static let altezzaFiltro: CGFloat = 36
            static let spazioFiltro: CGFloat = 8
        }

        // MARK: Agenda (Design/iphone.html, schermata 4)

        enum Agenda {
            /// Il mese 20 bold fra le frecce (tasti tondi 36 `chip`).
            static let mese = Carattere.meseAgenda
            static let freccia: CGFloat = 36
            static let simboloFreccia = Carattere(dimensione: 14, peso: .semibold)
            static let fondoFreccia = Colore.chip
            static let spazio: CGFloat = 10
            /// Le caselle: alte 40 (il dito), raggio 12, numero 15; oggi rosso pieno, il giorno scelto accento al 14%.
            static let cella: CGFloat = 40
            static let raggio: CGFloat = Raggio.giorno
            static let numero = Carattere(dimensione: 15, peso: .regular, tabellare: true)
            static let numeroForte = Carattere(dimensione: 15, peso: .bold, tabellare: true)
            static let intestazione = Carattere(dimensione: 11, peso: .semibold)
            static let coloreIntestazione = Colore.inchiostro3
            static let coloreNumero = Colore.inchiostro
            static let coloreFuori = Colore.inchiostro3
            static let fondoOggi = Colore.rosso
            static let testoOggi = Color.white
            static let fondoScelto = Colore.selezioneGiorno
            static let testoScelto = Colore.accento
            static let puntino: CGFloat = 5
            static let spazioPuntini: CGFloat = 3
            static let spazioRighe: CGFloat = 2
            static let appuntamento = Colore.accento
            static let attivita = Colore.arancio
            static let puntinoSuOggi = Color.white
            static let legenda = Carattere.secondario
            static let coloreLegenda = Colore.inchiostro2
        }

        // MARK: Ruby (Design/iphone.html, schermata 5)

        enum Ruby {
            static let margine: CGFloat = 12
            /// Di chi si parla: capsula `chip` alta 36, 13,5 semibold; a destra il pallino 8 e lo stato.
            static let gettone: CGFloat = 36
            static let paddingGettone: CGFloat = 14
            static let carattereGettone = Carattere(dimensione: 13.5, peso: .semibold)
            static let fondoGettone = Colore.chip
            static let stato = Carattere.secondario
            static let coloreStato = Colore.inchiostro2
            static let pallino: CGFloat = 8
            static let pronto = Colore.verde
            static let nonPronto = Colore.arancio
            static let testata: CGFloat = 48
            static let spazio: CGFloat = 8
            /// L'avviso «Ruby usa Qwen del tuo Mac»: card d'avviso arancio, titolo 15 bold, testo 13.
            static let fondoAvviso = Colore.avvisoFondo
            static let bordoAvviso = Colore.avvisoBordo
            static let titoloAvviso = Carattere(dimensione: 15, peso: .bold)
            static let testoAvviso = Carattere(dimensione: 13, peso: .regular)
            static let paddingAvviso = Misura.padding(14, 16)
            static let raggioAvviso: CGFloat = Raggio.card
            /// Il benvenuto: la sfera 96 viva, la frase 19 semibold, il testo 14,5.
            static let sferaBenvenuto: CGFloat = 96
            static let benvenutoSopra: CGFloat = 28
            static let spazioBenvenuto: CGFloat = 10
            /// I messaggi a 14 l'uno dall'altro; spunti e campo in basso.
            static let spazioMessaggi: CGFloat = 14
            static let campoMinimo: CGFloat = 48
            static let margineCampo = EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12)
        }
    }
}
