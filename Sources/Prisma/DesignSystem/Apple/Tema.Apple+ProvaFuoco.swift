import SwiftUI

// Posizioni › La prova del fuoco (Design/template-novita-specifica.md §6.2, §6.3): misure, caratteri, colori e tempi
// della card dello scenario, delle chip, del cursore, della lista «Chi chiamare, in ordine» e della barra oggi/dopo.
// Le viste stanno in Shell/ProvaDelFuocoApple.swift e DesignSystem/Apple/ChipBarraApple.swift; qui solo i valori,
// tutti ricavati dai token del tema Apple. Le soglie (10 e 5 punti) stanno nel motore (MotoreProvaFuoco).

extension Tema.Apple.Posizioni {
    enum Fuoco {
        typealias C = Tema.Apple.Carattere
        typealias K = Tema.Apple.Colore

        // MARK: Testata delle viste (Portafoglio · Prova del fuoco)

        enum Testata {
            /// Occhiello «35 clienti · aggiornato adesso» (maiuscoletto dell'etichetta).
            static let occhiello = C.etichetta
            static let coloreOcchiello = K.inchiostro2
            /// Spazio sotto la testata, prima del contenuto della vista.
            static let sotto: CGFloat = 2
        }

        // MARK: Card dello scenario (§2.1)

        enum Card {
            static let padding = Tema.Apple.Misura.padding(20, 24)
            static let superficie = Tema.Apple.Superficie.card
            static let raggio = Tema.Apple.Raggio.card
            /// Fra le tre colonne (scenario | clienti | patrimonio).
            static let spazioColonne: CGFloat = 24
            static let larghezzaClienti: CGFloat = 250
            static let larghezzaPatrimonio: CGFloat = 220
            /// Sotto questa larghezza della card le cifre vanno sotto lo scenario, in due colonne.
            static let sogliaStretta: CGFloat = 900
            static let larghezzaClientiStretta: CGFloat = 200
            static let larghezzaPatrimonioStretta: CGFloat = 200
            /// Spazio fra lo scenario e le cifre quando vanno sotto.
            static let spazioCifreSotto: CGFloat = 16
            static let filo = K.separatore
            static let spessoreFilo: CGFloat = Tema.Apple.Misura.bordo
            /// «La prova del fuoco · tutto il portafoglio» in rosso.
            static let etichetta = C.etichetta
            static let coloreEtichetta = K.rosso
            static let chipSopra: CGFloat = 12
            static let spazioChip: CGFloat = 8
            static let cursoreSopra: CGFloat = 16
            static let spazioCursore: CGFloat = 16
            /// Etichetta a sinistra del cursore («Ribasso delle azioni»): 12,5, larga 150.
            static let etichettaCursore = C.secondario
            static let coloreEtichettaCursore = K.inchiostro2
            static let larghezzaEtichettaCursore: CGFloat = 150
            /// Valore a destra del cursore («−25%»): display 20 bold, largo 90.
            static let valoreCursore = C(dimensione: 20, peso: .bold, tabellare: true)
            static let coloreValoreCursore = K.inchiostro
            static let larghezzaValoreCursore: CGFloat = 90
            /// Frase degli scenari storici al posto del cursore.
            static let frase = C(dimensione: 12.5, peso: .regular, interlinea: 1.4)
            static let coloreFrase = K.inchiostro2
            /// Il numero dei clienti oltre la soglia: display 40 bold; verde quando è zero.
            static let numeroClienti = C(dimensione: 40, peso: .bold, tracking: -0.5, tabellare: true)
            /// La cifra del patrimonio perso: 26 bold.
            static let cifraPatrimonio = C.valore
            static let coloreCifre = K.rosso
            static let coloreNessuno = K.verde
            static let coloreGuadagno = K.inchiostro
            /// Le frasi sotto le cifre: 13,5.
            static let sottoCifra = C(dimensione: 13.5, peso: .regular, interlinea: 1.3)
            static let coloreSottoCifra = K.inchiostro2
            static let spazioSottoCifra: CGFloat = 2
            /// «Ricalcolo…»: discreto, accanto al valore del cursore.
            static let ricalcolo = C(dimensione: 11.5, peso: .medium)
            static let coloreRicalcolo = K.inchiostro3
            /// Opacità delle chip senza clienti (card spenta).
            static let opacitaSpenta: Double = Tema.Apple.Controlli.opacitaDisattivato
        }

        // MARK: Chip (§2.1, `.chip`)

        enum Chip {
            static let padding = Tema.Apple.Misura.padding(7, 14)
            static let carattere = C.barra
            static let fondo = K.cardPiena
            static let bordo = K.separatore
            static let spessoreBordo: CGFloat = Tema.Apple.Misura.bordo
            static let testo = K.inchiostro
            /// Accesa: fondo rosso, testo bianco, niente bordo.
            static let fondoAcceso = K.rosso
            static let testoAcceso = Color.white
            /// Sotto il puntatore si solleva di 2.
            static let sollevamento: CGFloat = -2
        }

        // MARK: Titolo della lista (§2.2)

        enum Titolo {
            static let sopra: CGFloat = 16
            static let lati: CGFloat = 4
            static let sotto: CGFloat = 8
            static let titolo = C.h2
            static let coloreTitolo = K.inchiostro
            static let nota = C.secondario
            static let coloreNota = K.inchiostro2
            static let spazioNota: CGFloat = 16
        }

        // MARK: Righe della lista (§2.3)

        enum Riga {
            static let padding = Tema.Apple.Misura.padding(10, 16)
            static let spazio: CGFloat = 14
            /// Spazio fra una riga e l'altra.
            static let passo: CGFloat = 8
            static let superficie = Tema.Apple.Superficie.cardPiatta
            static let raggio = Tema.Apple.Raggio.card
            static let avatar: CGFloat = 36
            /// Blocchi: nome 200, «dopo/oggi» 150, perdita 110 (stretti: 130, 96, 92).
            static let larghezzaNome: CGFloat = 200
            static let larghezzaPercento: CGFloat = 150
            static let larghezzaPerdita: CGFloat = 110
            static let larghezzaNomeStretta: CGFloat = 130
            static let larghezzaPercentoStretta: CGFloat = 96
            static let larghezzaPerditaStretta: CGFloat = 92
            /// Riga minima (finestra molto stretta): blocchi 110, 76, 80, pulsanti con il solo simbolo, spazio 10.
            static let larghezzaNomeMinima: CGFloat = 110
            static let larghezzaPercentoMinima: CGFloat = 76
            static let larghezzaPerditaMinima: CGFloat = 80
            static let spazioMinimo: CGFloat = 10
            /// Fra le due righe del nome (nome e obiettivo) e di «dopo/oggi»; fra la «≈» e «dopo».
            static let spazioRighe: CGFloat = 2
            static let spazioStima: CGFloat = 4
            /// Sotto questa larghezza della lista la riga usa i blocchi stretti e il solo pallino del canale.
            static let sogliaStretta: CGFloat = 1040
            /// Sotto questa larghezza la riga è minima.
            static let sogliaMinima: CGFloat = 720
            /// La barra non scende sotto questa larghezza (40 nella riga minima).
            static let barraMinima: CGFloat = 60
            static let barraMinimaStretta: CGFloat = 40
            /// I simboli dei pulsanti della riga minima.
            static let simboloChiama = "phone"
            static let simboloMessaggio = "message"
            static let nome = C(dimensione: 14, peso: .bold)
            static let coloreNome = K.inchiostro
            static let obiettivo = C.secondario
            static let coloreObiettivo = K.inchiostro2
            static let dopo = C(dimensione: 14, peso: .bold, tabellare: true)
            static let coloreDopo = K.inchiostro
            static let coloreDopoAllarme = K.rosso
            static let oggi = C(dimensione: 12.5, peso: .regular, tabellare: true)
            static let coloreOggi = K.inchiostro2
            static let perdita = C(dimensione: 14, peso: .bold, tabellare: true)
            static let colorePerdita = K.rosso
            static let coloreGuadagno = K.verde
            static let spazioCanali: CGFloat = 5
            /// Nella riga stretta il canale è il solo pallino nel suo colore.
            static let pallinoCanale: CGFloat = Tema.Apple.Misura.Controllo.pallinoCanale + 2
            static func coloreCanale(_ c: Canale) -> Color {
                c == .alleanza ? K.canaleAlleanza : K.canaleIndipendente
            }
            /// «≈» accanto a «dopo» quando la composizione è stimata.
            static let stima = C(dimensione: 13, peso: .semibold)
            static let coloreStima = K.inchiostro2
            /// Le frasi al posto della barra (senza obiettivi) e la nota in fondo alla lista.
            static let senzaObiettivo = C.secondario
            static let coloreSenzaObiettivo = K.inchiostro2
            static let nota = C(dimensione: 12.5, peso: .regular, interlinea: 1.4)
            static let coloreNota = K.inchiostro2
            static let notaSopra: CGFloat = 6
            /// Spazio in fondo alla lista (l'ultima riga non tocca il bordo).
            static let fondoLista: CGFloat = 12
            /// Il margine a destra della lista (la barra di scorrimento non copre i pulsanti).
            static let margineScorrimento: CGFloat = 4
        }

        // MARK: Barra oggi/dopo (§2.3, `BarraOggiDopo`)

        enum Barra {
            static let altezza: CGFloat = 12
            static let raggio: CGFloat = 8
            static let binario = K.binario
            /// La barra chiara: la copertura di oggi, blu grafico al 22% (uguale in chiaro e in scuro).
            static let oggi = Tema.Apple.Colore.Area.investimenti.opacity(0.22)
            /// La barra piena: blu, arancio sopra 5 punti di calo, rossa sopra 10.
            static let tranquillo = Tema.Apple.Colore.Area.investimenti
            static let attenzione = K.arancio
            static let allarme = K.rosso

            static func colore(_ l: MotoreProvaFuoco.Livello) -> Color {
                switch l {
                case .tranquillo: return tranquillo
                case .attenzione: return attenzione
                case .allarme: return allarme
                }
            }
        }

        // MARK: Movimento (§6.3)

        enum Moto {
            /// Cambio di vista (`rimonta`): come le schede di Studio, 0,13 s lineare verso opacità 0 e scala 0,99.
            static let durataRimonta = Tema.Apple.Studio.Moto.durataRimonta
            static let scalaRimonta = Tema.Apple.Studio.Moto.scalaRimonta
            static var uscitaRimonta: Animation { Tema.Apple.Studio.Moto.uscitaRimonta }
            /// La card e il titolo della lista entrano a cascata (dentro l'app, da 0).
            static let baseCascata = Tema.Apple.Moto.Cascata.baseDentroApp
        }
    }
}

// MARK: - Tempi nuovi del tema (§6.3: Riordino, BarraScenario, chip)

extension Tema.Apple.Moto.Curva {
    /// Riordino delle righe della prova del fuoco: `cubic-bezier(.32, 1.2, .5, 1)`, leggero rimbalzo.
    static let riordino = Tema.Apple.Moto.Curva(x1: 0.32, y1: 1.2, x2: 0.5, y2: 1)
}

extension Tema.Apple.Moto {
    /// Le righe scivolano al nuovo posto in 0,65 s (FLIP del template; in SwiftUI identità stabili e `withAnimation`).
    enum Riordino {
        static let durata = 0.65
        static var animazione: Animation { Curva.riordino.animazione(durata) }
    }

    /// La barra piena va al valore «dopo» in 0,8 s con la curva `uscita`; il colore cambia in 0,5 s (`ease`).
    enum BarraScenario {
        static let durata = 0.80
        static let durataColore = 0.50
        static var animazione: Animation { Curva.uscita.animazione(durata) }
        static var animazioneColore: Animation { Curva.ease.animazione(durataColore) }
    }

    /// La chip si accende e si solleva con la molla di 0,35 s.
    enum ChipScelta {
        static let durata = 0.35
        static var animazione: Animation { Curva.molla.animazione(durata) }
    }

    /// «Ricalcolo…» compare solo se il calcolo dura più di 0,25 s, e sparisce subito.
    enum IndicatoreCalcolo {
        static let attesa = 0.25
        static let durata = 0.20
        static let durataUscita = 0.15
        static var entrata: Animation { .easeIn(duration: durata * Tema.Apple.Moto.ritmo).ritardoPrisma(attesa) }
        static var uscita: Animation { .easeOut(duration: durataUscita * Tema.Apple.Moto.ritmo) }
    }
}
