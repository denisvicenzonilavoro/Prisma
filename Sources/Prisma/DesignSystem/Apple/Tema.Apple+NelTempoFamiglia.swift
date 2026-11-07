import SwiftUI

// Clienti del tema Apple, le schede «Nel tempo» e «Famiglia» del dossier (Design/template-apple-specifica.md §4.2.4,
// §4.2.5, riferimenti PC C17-C21, MO 13-14). Le viste stanno in Shell/DossierNelTempo.swift e
// Shell/DossierFamiglia.swift; le cifre in Motori/MotoreNelTempo.swift e Motori/MotoreFamigliaDossier.swift.

extension Tema.Apple.Clienti {
    // MARK: Nel tempo (§4.2.4)

    enum NelTempo {
        typealias Colore = Tema.Apple.Colore
        typealias Carattere = Tema.Apple.Carattere

        /// Card intera, padding 20×24.
        static let superficie = Tema.Apple.Superficie.cardPiatta
        static let padding = Tema.Apple.Misura.padding(20, 24)
        /// `.lbl` «Il patrimonio, tre anni indietro e due avanti» e legenda 12,5 `inchiostro2`.
        static let titolo = Carattere.etichetta
        static let coloreTitolo = Colore.inchiostro2
        static let legenda = Carattere(dimensione: 12.5, peso: .regular)
        static let coloreLegenda = Colore.inchiostro2
        static let spazioLegenda: CGFloat = 12
        /// Fra il segno della legenda («━», «┅») e la sua parola.
        static let spazioSegnoLegenda: CGFloat = 4
        static let spazioIntestazione: CGFloat = 12
        /// Il grafico a 14 sotto l'intestazione.
        static let sopraGrafico: CGFloat = 14

        // Grafico 1040×330 nel template: passato 36 mesi su 600, futuro 25 mesi su 400 (la riga «oggi» al 60%)
        /// Dove cade «oggi», in frazione della larghezza del grafico.
        static let quotaPassato: CGFloat = 0.6
        static let colorePassato = Colore.anello2
        static let coloreStima = Colore.stima
        static let spessorePassato: CGFloat = Tema.Apple.Grafico.Tracciato.spessore
        static let spessoreStima: CGFloat = Tema.Apple.Grafico.Tracciato.spessoreStima
        /// Tratteggiata 6 6 anche a disegno finito (§4.9, errore 1).
        static let tratteggioStima: [CGFloat] = Tema.Apple.Grafico.Tracciato.tratteggioStima
        /// Senza proposte la stima è nel blu del passato, tratteggiata.
        static let coloreStimaSenza = Colore.anello2
        /// Margini della scala: 4% sotto il minimo e 6% sopra il massimo, come nel template.
        static let margineSotto: Double = 0.96
        static let margineSopra: Double = 1.06
        /// Valori «NNNk» 11 `inchiostro3` a destra della griglia, in una colonna di 46.
        static let colonnaValori: CGFloat = 46
        static let valoriAsse = Carattere.asse
        static let coloreAsse = Colore.inchiostro3
        /// «nov 2023», «oggi» 12 bold, «nov 2028» 11,5, a 20 sotto il grafico.
        static let date = Carattere(dimensione: 11.5, peso: .regular)
        static let oggi = Carattere.oggiGrafico
        static let coloreOggi = Colore.inchiostro
        static let altezzaDate: CGFloat = 20
        /// Il grafico non scende sotto questa altezza; sopra cresce fino a riempire la card.
        static let altezzaMinimaGrafico: CGFloat = 170
        static let altezzaMassimaGrafico: CGFloat = 330
        /// Le linee si disegnano dopo l'entrata della card.
        static let ritardoLinee = 0.30

        // Il momento scelto con il cursore (Prisma: il template non ha il cursore)
        /// Il cursore a 12 sotto le date; la manopola è centrata sul mese.
        static let sopraCursore: CGFloat = 12
        /// Riga verticale del momento scelto e il suo punto.
        static let coloreMomento = Colore.accento
        static let spessoreMomento: CGFloat = 1.5
        static let raggioMomento: CGFloat = 5
        static let bordoMomento: CGFloat = 2.5
        static let coloreBordoMomento = Tema.Apple.Controlli.manopola
        /// I riesami sulla linea del passato: cerchi vuoti di raggio 4,5, bordo 2.
        static let raggioRiesame: CGFloat = 4.5
        static let bordoRiesame: CGFloat = 2
        static let fondoRiesame = Colore.cardPiena

        /// La colonna del momento accanto al grafico: 300 di larghezza a 22 di distanza; sotto 760 va sotto.
        static let larghezzaMomento: CGFloat = 300
        static let spazioMomento: CGFloat = 22
        static let larghezzaAffiancata: CGFloat = 760
        static let spazioRigheMomento: CGFloat = 8
        static let spazioBlocchiMomento: CGFloat = 14
        /// Fra il «quando», la cifra e la riga sotto della testata del momento.
        static let spazioTestata: CGFloat = 2
        /// Righe del momento: fra etichetta (o canale) e valore, e lo spazio minimo che li separa.
        static let spazioRiga: CGFloat = 6
        static let minimoRiga: CGFloat = 4
        /// «Marzo 2025 · 20 mesi fa»: `.lbl`; «stima, non una previsione» nel viola della stima.
        static let quando = Carattere.etichetta
        static let coloreQuando = Colore.inchiostro2
        static let coloreAvvisoStima = Colore.stima
        /// Il patrimonio del momento: `.v` 26 bold.
        static let valore = Carattere.valore
        static let coloreValore = Colore.inchiostro
        static let sottoValore = Carattere.secondario
        static let coloreSottoValore = Colore.inchiostro2
        /// Righe del riesame (canali, debiti, proposte): 13, valori tabellari.
        static let riga = Carattere(dimensione: 13, peso: .regular)
        static let valoreRiga = Carattere(dimensione: 13, peso: .semibold, tabellare: true)
        static let coloreRiga = Colore.inchiostro
        static let titoloRiesame = Carattere(dimensione: 14, peso: .bold)
        static let nota = Carattere(dimensione: 13, peso: .regular, interlinea: 1.45)
        static let coloreNota = Colore.inchiostro2
        static let filo = Colore.separatore
        /// Le note del riesame si accorciano a tanti caratteri.
        static let caratteriNota = 220
        /// Quante posizioni e quante variazioni mostrare.
        static let massimoPosizioni = 4
        static let massimoVariazioni = 3
    }

    // MARK: Famiglia (§4.2.5)

    enum Famiglia {
        typealias Colore = Tema.Apple.Colore
        typealias Carattere = Tema.Apple.Carattere

        /// Griglia di `max(2, familiari + 1)` colonne (al massimo 4, poi va a capo), spazio 14.
        static let colonneMinime = 2
        static let colonneMassime = 4
        static let spazio: CGFloat = Tema.Apple.Misura.Spazio.griglia
        /// Card padding 22, contenuto centrato; i familiari si inclinano di 6°.
        static let superficie = Tema.Apple.Superficie.cardPiatta
        static let padding: CGFloat = 22
        static let inclinazione = Tema.Apple.Moto.Inclinazione.massimoFamiliari
        /// Avatar 70 visibile e centrato anche per il titolare (§4.9, errore 2).
        static let avatar: CGFloat = Tema.Apple.Misura.Avatar.massimo
        /// Nome 19 bold a 10 sotto l'avatar; «45 anni · titolare del dossier» `.k`.
        static let nome = Carattere(dimensione: 19, peso: .bold, tracking: -0.3)
        static let coloreNome = Colore.inchiostro
        static let sopraNome: CGFloat = 10
        static let descrizione = Carattere.secondario
        static let coloreDescrizione = Colore.inchiostro2
        static let spazioNomeDescrizione: CGFloat = 2
        /// Capsule delle scoperture: 12 semibold, padding 4×10, testo nel tono e fondo nel tono al 12%, a 10 sotto.
        static let capsula = Carattere(dimensione: 12, peso: .semibold)
        static let paddingCapsula = Tema.Apple.Misura.padding(4, 10)
        static let opacitaFondoCapsula: Double = 0.12
        static let sopraCapsule: CGFloat = 10
        static let fraCapsule: CGFloat = 6
        static let rosso = Colore.rosso
        static let arancio = Colore.arancio
        static let verde = Colore.verde
        /// La freccia «›» dopo il testo della capsula: porta alla scheda dove si risolve.
        static let spazioFreccia: CGFloat = 3
        /// «Modifica» sotto, a 12.
        static let sopraModifica: CGFloat = 12
        /// «Nessun familiare nel dossier.» `.k` 14 a 16 sotto la griglia.
        static let vuoto = Carattere(dimensione: 14, peso: .regular)
        static let coloreVuoto = Colore.inchiostro2
        static let sopraVuoto: CGFloat = 16
        /// Il posto per un nuovo familiare: card tratteggiata senza fondo (come «Un nome al futuro» degli obiettivi).
        static let bordoNuovo = Colore.inchiostro3
        static let tratteggioNuovo: [CGFloat] = [6, 5]
        static let spessoreNuovo: CGFloat = 1.5
        static let raggio: CGFloat = Tema.Apple.Raggio.card
        static let segnoNuovo = Carattere(dimensione: 30, peso: .regular)
        static let spazioNuovo: CGFloat = 4
        static let testoNuovo = Carattere(dimensione: 13.5, peso: .regular)
        static let coloreNuovo = Colore.inchiostro2
        /// Spiegazione sotto la griglia (da dove vengono le capsule).
        static let fonte = Carattere.secondario
        static let coloreFonte = Colore.inchiostro3
        static let sopraFonte: CGFloat = 14
    }
}
