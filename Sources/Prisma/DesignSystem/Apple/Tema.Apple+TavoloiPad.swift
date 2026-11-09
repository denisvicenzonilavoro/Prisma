import SwiftUI

// Il tavolo con il Mac, lato iPad (iOS/TavoloiPad.swift, viste in iOS/SchermiTavoloiPad.swift): la modalità a tutto
// schermo davanti al cliente. Il template non ha il tavolo: i valori vengono dai token del tema Apple (finestra di
// vetro sull'acqua, card, cursore, pulsanti a capsula, logo) e, per la pagina e per l'area della presa visione, dalla
// sala della presentazione (sempre scura) e dalla carta dei documenti (sempre chiara, colori opachi e fissi).
// La macchina del tempo e la famiglia riusano i valori della scheda del dossier (Tema.Apple+NelTempoFamiglia.swift).

extension Tema.Apple.Tavolo {
    enum iPad {
        typealias Colore = Tema.Apple.Colore
        typealias Carattere = Tema.Apple.Carattere

        /// Da una schermata all'altra: dissolvenza con la curva `uscita` (calma: 0,15 s; istantanee: di colpo).
        static let cambio = Tema.Apple.Moto.uscita(0.35)

        // MARK: La finestra di vetro (macchina del tempo, famiglia, cursore, presa visione)

        /// La finestra sopra l'acqua, come quelle del Mac: vetro `finestra`, raggio 24.
        static let superficie = Tema.Apple.Superficie.finestra
        /// Il contenuto non si allarga oltre questa misura (l'iPad 13" in orizzontale).
        static let larghezzaMassima: CGFloat = 820
        static let margineEsterno: CGFloat = 28
        static let padding = Tema.Apple.Misura.padding(30, 34)
        /// Fra la testata, la cosa principale e ciò che serve per decidere.
        static let spazioBlocchi: CGFloat = 26
        static let spazioTestata: CGFloat = 6
        static let spazioRighe: CGFloat = 10

        /// La testata: «IL PATRIMONIO NEL TEMPO» (.lbl), il nome del cliente grande, il canale accanto.
        static let sopratitolo = Carattere.etichetta
        static let coloreSopratitolo = Colore.inchiostro2
        static let titolo = Carattere.titoloDettaglio(30)
        static let coloreTitolo = Colore.inchiostro
        static let sottotitolo = Carattere.secondario
        static let coloreSottotitolo = Colore.inchiostro2

        // MARK: La schermata neutra (logo sull'acqua, nessun dato)

        static let logo: CGFloat = 132
        static let coloreLogo = Colore.logo
        static let spazioLogo: CGFloat = 22
        /// «In attesa del Mac…» o «Mi collego al Mac…»: solo quando l'iPad non è collegato.
        static let stato = Carattere(dimensione: 13, peso: .medium)
        static let coloreStato = Colore.inchiostroAcqua2

        // MARK: La pagina (sala: sempre scura, colori fissi)

        /// Il fondo opaco sotto il foglio (la sala della presentazione, senza trasparenza: l'acqua sotto si ferma).
        static let fondoPagina = Color(r: 6, g: 14, b: 20, a: 1)
        static let marginePagina: CGFloat = 26
        /// «Pagina 2 di 6 · Il check-up» sotto il foglio.
        static let didascalia = Carattere(dimensione: 13, peso: .medium, tabellare: true)
        static let coloreDidascalia = Color(r: 255, g: 255, b: 255, a: 0.62)
        static let altezzaDidascalia: CGFloat = 34

        // MARK: Il cursore lasciato al cliente

        static let valoreCursore = Carattere.valoreCursore
        static let coloreValore = Colore.accento
        static let unita = Carattere(dimensione: 15, peso: .medium)
        static let coloreUnita = Colore.inchiostro2
        /// Il risultato ricalcolato dal Mac: la cifra grande, poi le righe.
        static let titoloRisultato = Carattere.etichetta
        static let coloreTitoloRisultato = Colore.inchiostro2
        static let cifraRisultato = Carattere.numeroGrande
        static let coloreCifra = Colore.inchiostro
        static let riga = Carattere(dimensione: 15, peso: .regular)
        static let valoreRiga = Carattere(dimensione: 15, peso: .semibold, tabellare: true)
        static let coloreRiga = Colore.inchiostro
        static let filo = Colore.separatore
        static let spessoreFilo: CGFloat = 1
        static let nota = Carattere(dimensione: 13, peso: .regular, interlinea: 1.45)
        static let coloreNota = Colore.inchiostro2
        /// Mentre il Mac ricalcola, il risultato di prima si attenua.
        static let opacitaRicalcolo: Double = 0.45
        static let limiti = Carattere.asse
        static let coloreLimiti = Colore.inchiostro3
        static let altezzaGraficoNelTempo: CGFloat = 320
        /// Il segno della legenda della macchina del tempo: la linea piena o tratteggiata accanto alla voce.
        static let segnoLegenda: CGFloat = 15
        static let tratteggioLegenda: [CGFloat] = [3, 3]

        // MARK: La presa visione

        /// La scritta esatta, grande: è la cosa principale della schermata.
        static let testoPresaVisione = Carattere(dimensione: 22, peso: .semibold, tracking: -0.4, interlinea: 1.3)
        static let coloreTestoPresaVisione = Colore.inchiostro
        /// L'area del tratto ha le proporzioni del riquadro nel PDF (300×120): 2,5 a 1.
        static let rapportoArea: CGFloat = Tema.Apple.Tavolo.PresaVisione.tratto.width / Tema.Apple.Tavolo.PresaVisione.tratto.height
        static let larghezzaArea: CGFloat = 680
        /// L'area è carta: bianca anche in scuro, con il bordo e la riga della carta.
        static let fondoArea = Tema.Apple.Carta.fondo
        static let bordoArea = Tema.Apple.Carta.linea
        static let spessoreBordoArea: CGFloat = 1
        static let raggioArea: CGFloat = Tema.Apple.Raggio.voce
        static let rigaArea = Tema.Apple.Carta.filetto
        static let spessoreRigaArea: CGFloat = 1.2
        /// La riga su cui firmare, al 72% dell'altezza, con un margine ai lati.
        static let quotaRigaArea: CGFloat = 0.72
        static let margineRigaArea: CGFloat = 28
        static let suggerimentoArea = Carattere(dimensione: 13, peso: .regular)
        static let coloreSuggerimento = Tema.Apple.Carta.piede
        /// L'inchiostro del tratto: lo stesso sullo schermo e nel PNG per il PDF (blu scuro, fisso).
        static let inchiostro = Color(r: 20, g: 33, b: 43, a: 1)
        static let inchiostroCG = Tema.Apple.Tavolo.PresaVisione.coloreTrattoProva
        static let spessoreTratto: CGFloat = 3
        /// Pixel per punto del PNG mandato al Mac.
        static let scalaTratto: CGFloat = 2
        static let spazioPulsanti: CGFloat = 12
        static let avviso = Carattere.secondario
        static let coloreAvviso = Colore.inchiostro2

        // MARK: L'ingresso (Impostazioni e schermata d'apertura)

        static let spazioIngresso: CGFloat = 10
        static let esito = Carattere.secondario
        static let coloreEsito = Colore.arancio

        // MARK: Il doppio senso («Luce» giro 16): rischio, Lancia l'anno, disegno, capsula

        enum Rischio {
            static let altezzaGrafico: CGFloat = 220
            static let spazioOpzioni: CGFloat = 10
            static let larghezzaOpzioni: CGFloat = 720
            static let anello: CGFloat = 150
            static let coloreAnello = Colore.accento
            static let profilo = Carattere.titoloDettaglio(30)
        }

        enum Lancia {
            static let spazioVite: CGFloat = 14
            static let raggioVita: CGFloat = 18
            static let fondoVita = Colore.card
            static let paddingVita: CGFloat = 18
            static let cifraVita = Carattere(dimensione: 34, peso: .bold, tracking: -1, tabellare: true)
            static let etichettaVita = Carattere.etichetta
            static let titoloCarta = Carattere(dimensione: 19, peso: .bold)
            static let fraseCarta = Carattere(dimensione: 15, peso: .regular, interlinea: 1.4)
            static let con = Colore.canaleAlleanza
            static let senza = Colore.inchiostro2
            static let toni: [String: Color] = ["rosso": Colore.rosso, "arancio": Colore.arancio, "verde": Colore.verde]
        }

        enum Disegno {
            /// La tela: carta bianca anche in scuro, come l'area della presa visione.
            static let rapporto: CGFloat = 1.7
            static let fondo = Tema.Apple.Carta.fondo
            static let bordo = Tema.Apple.Carta.linea
            static let griglia = Tema.Apple.Carta.filetto
            static let asse = Carattere.asse
            static let coloreAsse = Tema.Apple.Carta.etichetta
            static let inchiostro = Color(r: 37, g: 99, b: 235, a: 1)
            static let spessore: CGFloat = 3.5
            static let pensione = Color(r: 176, g: 110, b: 18, a: 0.5)
            static let margineAsse: CGFloat = 64
            static let altezzaRisultato: CGFloat = 320
        }

        enum Capsula {
            static let altezzaCampo: CGFloat = 300
            static let fondoCampo = Tema.Apple.Carta.fondo
            static let raggioCampo: CGFloat = Tema.Apple.Raggio.voce
            static let bordoCampo = Tema.Apple.Carta.linea
            static let testo = Carattere(dimensione: 17, peso: .regular, interlinea: 1.45)
            static let inchiostro = Tema.Apple.Carta.testo
        }
    }
}
