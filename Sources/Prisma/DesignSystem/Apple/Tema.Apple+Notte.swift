import SwiftUI

// «Stanotte Prisma ha lavorato» («Luce» giro 14, Design/template-luce-specifica.md §6.1.2 e §6.1.3): la sovrapposizione
// delle carte della notte (alone, testata, pila, carta, timbri, comandi, registro, fine), il pallino della scrivania, le
// tinte dei tipi di carta e il movimento. Misure in pt, durate in secondi. Tutti i valori grafici della notte solo qui.

extension Tema.Apple {
    enum Notte {
        /// L'alone viola in alto: radiale 1000×520 centrato al 50% e a −12%, rgba(91,75,200,.24) → trasparente al 70%.
        static let alone = Color(r: 91, g: 75, b: 200, a: 0.24)
        static let centroAlone = UnitPoint(x: 0.5, y: -0.12)
        static let raggioAlone: CGFloat = 520
        /// Il gradiente è un'ellisse: si allarga in orizzontale di 1000/520.
        static let scalaAlone: CGFloat = 1000.0 / 520.0
        static let fineAlone: CGFloat = 0.70
        /// Il velo sotto l'alone (`--scrim`) con la sfocatura 28 e la saturazione 1,25 (`.ultraThinMaterial` come ripiego).
        static let velo = Colore.velo
        static let sfocatura: CGFloat = 28
        static let saturazione: Double = 1.25
        /// Sotto questa larghezza il registro va sotto i comandi.
        static let larghezzaStretta: CGFloat = 1100
        /// La carta in piccolo nella vetrina del tema (istantanea 400).
        static let scalaVetrina: CGFloat = 0.42

        enum Testata {
            static let margine: CGFloat = 120
            static let margineStretto: CGFloat = 40
            static let dallAlto: CGFloat = 70
            static let spazio: CGFloat = 20
            static let tassello: CGFloat = 52
            static let titolo = Carattere(dimensione: 34, peso: .bold, tracking: -0.8)
            static let sottotitolo = Carattere(dimensione: 15, peso: .regular)
            static let spazioTitoli: CGFloat = 4
            /// La testata sopra la pila (la pila parte a 200 dall'alto nel template, la testata a 70).
            static let sottoTestata: CGFloat = 44
        }

        enum Pila {
            static let larghezza: CGFloat = 600
            static let altezza: CGFloat = 370
            /// Le carte dietro: spostate di 16 e 32, scala 0,955 e 0,91, la terza a opacità 0,55.
            static let scarto: CGFloat = 16
            static let riduzione: CGFloat = 0.045
            static let opacitaTerza: Double = 0.55
            static let visibili = 3
            /// Fra la pila e il registro.
            static let spazioRegistro: CGFloat = 60
        }

        enum Carta {
            static let raggio: CGFloat = 30
            static let fondo = Colore.cardPiena
            static let bordo = Colore.separatore
            static let spessoreBordo: CGFloat = 1
            /// `0 44px 90px -34px rgba(8,30,60,.5), 0 4px 14px -6px rgba(8,30,60,.15)`.
            static let ombra1 = Color(r: 8, g: 30, b: 60, a: 0.5)
            static let raggioOmbra1: CGFloat = 28
            static let yOmbra1: CGFloat = 30
            static let ombra2 = Color(r: 8, g: 30, b: 60, a: 0.15)
            static let raggioOmbra2: CGFloat = 4
            static let yOmbra2: CGFloat = 3
            static let padding: CGFloat = 28
            static let tassello: CGFloat = 44
            static let spazioRiga: CGFloat = 12
            static let avatar = Misura.Avatar.voce
            static let occhiello = Carattere.etichetta
            static let nome = Carattere(dimensione: 13.5, peso: .bold)
            static let titolo = Carattere(dimensione: 27, peso: .bold, tracking: -0.6, interlinea: 1.2)
            static let sopraTitolo: CGFloat = 22
            static let descrizione = Carattere(dimensione: 15.5, peso: .regular, interlinea: 1.55)
            static let sopraDescrizione: CGFloat = 10
            static let piede = Carattere(dimensione: 12.5, peso: .regular)
            static let apri = Carattere(dimensione: 12.5, peso: .semibold)
            static let dalFondo: CGFloat = 22
            static let testo = Colore.inchiostro
            static let testo2 = Colore.inchiostro2
            static let accento = Colore.accento
            /// Il tassello spento della notte saltata.
            static let opacitaSpento: Double = 0.45
            /// Le carte di stato (saltata, niente da preparare, lavoro in corso): pulsanti in fondo.
            static let spazioPulsanti: CGFloat = 12
        }

        enum Timbro {
            static let carattere = Carattere(dimensione: 21, peso: .heavy, tracking: 2)
            static let padding = Misura.padding(5, 14)
            static let bordo: CGFloat = 3
            static let raggio: CGFloat = 10
            static let rotazione: Double = 12
            static let dallAlto: CGFloat = 30
            static let dalLato: CGFloat = 26
            static let approva = Colore.verde
            static let piuTardi = Colore.arancio
            static let fondo = Colore.cardPiena
            /// Il trascinamento che decide (e il divisore dell'opacità dei timbri, dx/110).
            static let soglia: CGFloat = 110
            /// Solo istantanee: lo spostamento della 761.
            static let istantanea: CGFloat = 90
        }

        enum Comandi {
            static let pulsante: CGFloat = 66
            static let glifo = Carattere(dimensione: 25, peso: .bold)
            static let spazio: CGFloat = 30
            static let contatore: CGFloat = 120
            static let carattereContatore = Carattere(dimensione: 15, peso: .semibold, tabellare: true)
            static let scalaSopra: CGFloat = 1.08
            static let sottoPila: CGFloat = 70
            static let fondo = Colore.cardPiena
            static let bordo = Colore.separatore
            static let piuTardi = Colore.arancio
            static let approva = Colore.verde
        }

        enum Registro {
            static let larghezza: CGFloat = 360
            static let altezza: CGFloat = 440
            static let raggio = Raggio.finestra
            static let fondo = Colore.pannello
            static let bordo = Colore.separatore
            static let padding = Misura.padding(18, 20)
            static let riga = Carattere(dimensione: 13.5, peso: .regular)
            static let segnoCarattere = Carattere(dimensione: 13.5, peso: .bold)
            static let paddingRiga: CGFloat = 9
            static let spazioRiga: CGFloat = 10
            static let segno: CGFloat = 16
            static let approvata = Colore.verde
            static let rimandata = Colore.arancio
            /// Stretta: largo come la pila, alto al più 200.
            static let altezzaStretta: CGFloat = 200
            static let sottoComandi: CGFloat = 24
        }

        enum Fine {
            static let anello: CGFloat = 120
            static let spessore: CGFloat = 12
            static let colore = Colore.anello1
            static let segno = Carattere(dimensione: 46, peso: .bold)
            static let titolo = Carattere(dimensione: 30, peso: .bold)
            static let sopraTitolo: CGFloat = 18
            static let testo = Carattere(dimensione: 15, peso: .regular)
            static let spazio: CGFloat = 12
        }

        /// Il pallino sul pulsante «Stanotte» della scrivania (come le notifiche).
        enum Pallino {
            static let lato: CGFloat = 16
            static let fondo = Colore.rossoBadge
            static let testo = Color.white
            static let carattere = Carattere(dimensione: 10, peso: .bold, tabellare: true)
            static let scostamento: CGFloat = 5
            static let paddingOrizzontale: CGFloat = 4
        }

        /// Le tinte dei tipi di carta (§2.3): il colore lo dà il tipo, non il glifo.
        enum Tipo {
            static let fascicolo = Colore.anello2
            static let messaggio = Colore.arancio
            static let ricalcolo = Colore.anello1
            static let documento = Colore.rosso
            static let moduli = Color(hex: "#5B4BC8")
            static let riesame = Color(hex: "#1E9E6A")
            /// Token nuovo (non il colore dell'avatar di Giulia, anche se oggi coincide).
            static let campagna = Color(hex: "#C45A75")
            static let domani = Color(hex: "#2A9BC8")
            static let daFinire = Colore.inchiostro2
            /// Il tassello della notte (#1F3A5F).
            static let notte = Colore.Glifi.notte

            static func tinta(_ t: TipoCartaNotte) -> Color {
                switch t {
                case .fascicolo: return fascicolo
                case .messaggio: return messaggio
                case .ricalcolo: return ricalcolo
                case .documento: return documento
                case .moduli: return moduli
                case .riesame: return riesame
                case .campagna: return campagna
                case .domani: return domani
                case .daFinire: return daFinire
                }
            }

            static func glifo(_ t: TipoCartaNotte) -> GlifoLuce {
                switch t {
                case .fascicolo: return .cartella
                case .messaggio: return .lettera
                case .ricalcolo: return .rischio
                case .documento: return .scan
                case .moduli: return .modulo
                case .riesame: return .radar
                case .campagna: return .campagna
                case .domani: return .auto
                case .daFinire: return .notte
                }
            }
        }
    }
}

extension Tema.Apple.Moto {
    /// Il movimento della notte (§6.1.3).
    enum Notte {
        static let apertura = 0.40
        static let chiusura = 0.25
        /// L'entrata delle carte la prima volta: da y +120+k·16, scala 0,9, opacità 0; 0,70 s; ritardo 0,20 + k·0,09.
        static let entrata = 0.70
        static let ritardo = 0.20
        static let passo = 0.09
        static let spostamento: CGFloat = 120
        static let scalaEntrata: CGFloat = 0.9
        /// Trascinamento: rotazione dx/24 gradi.
        static let rotazionePerPunto: Double = 1.0 / 24
        /// Rilascio sotto soglia: torna in 0,45 s con la molla.
        static let ritorno = 0.45
        /// Decisione: volo a ±760, ±26°, opacità 0 in 0,46 s.
        static let volo = 0.46
        static let distanzaVolo: CGFloat = 760
        static let rotazioneVolo: Double = 26
        /// La riga nuova del registro: da x +20 in 0,40 s.
        static let riga = 0.40
        static let spostamentoRiga: CGFloat = 20
        static let ritardoAnello = 0.10

        static var animazioneApre: Animation { .linear(duration: apertura) }
        static var animazioneChiude: Animation { .linear(duration: chiusura) }
        static func animazioneEntrata(_ k: Int) -> Animation {
            Curva.mollaLeggera.animazione(entrata).delay(ritardo + Double(k) * passo)
        }
        static var animazioneRitorno: Animation { Curva.molla.animazione(ritorno) }
        static var animazioneVolo: Animation { Curva.backup.animazione(volo) }
        static var animazionePila: Animation { Curva.molla.animazione(ritorno) }
        static var animazioneRiga: Animation { Curva.uscita.animazione(riga) }
    }
}
