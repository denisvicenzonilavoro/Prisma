import SwiftUI

// Territorio · «Il tuo territorio» (Design/template-luce-specifica.md §5.1.2-§5.1.3, «Luce» giro 11): misure, caratteri,
// colori e tempi della mappa (sempre scura, anche nel tema chiaro), delle luci, del pannello, del giro, della crescita,
// del fumetto e della legenda. Le viste stanno in Shell/AppTerritorio.swift, Shell/MappaTerritorio.swift e
// Shell/PannelloTerritorio.swift. I colori delle luci sono le varianti scure dei canali (decisione 118).

extension Tema.Apple {
    enum Territorio {
        typealias C = Tema.Apple.Carattere
        typealias K = Tema.Apple.Colore

        // MARK: Mappa di base (sempre scura)

        enum Mappa {
            static let terra = Color(hex: "#0C1720")
            static let vignettaCentro = Color(hex: "#1A3044")
            static let vignettaBordo = Color(hex: "#0A121A")
            static let centroVignetta = UnitPoint(x: 0.6, y: 0.5)
            /// Frazione della diagonale della card.
            static let raggioVignetta: CGFloat = 0.7
            /// I confini dei comuni con clienti (la «strada» del template: bianco 11%).
            static let confine = Color.white.opacity(0.11)
            /// Lo spessore 7 del template disegna strade su 1440 px; per i confini dei comuni 2,3 (si decide guardando
            /// l'istantanea 700).
            static let spessoreConfine: CGFloat = 7 / 3
            /// Gli altri comuni della provincia (la «stradina»: bianco 4,5%).
            static let confineAltri = Color.white.opacity(0.045)
            static let spessoreConfineAltri: CGFloat = 1
            static let zona = C(dimensione: 13, peso: .semibold, tracking: 0.5, maiuscolo: true)
            static let coloreZona = Color.white.opacity(0.38)
            /// Spazio minimo fra i riquadri dei nomi delle zone (niente nomi sovrapposti).
            static let spazioNomiZona: CGFloat = 6
            /// Margine attorno alle luci nella proiezione.
            static let margine: CGFloat = 40
            static let zoomMinimo: CGFloat = 1
            static let zoomMassimo: CGFloat = 12
            /// Distanza minima del trascinamento (sotto è un clic).
            static let distanzaTrascinamento: CGFloat = 4
        }

        // MARK: Le luci

        enum Luce {
            static let alleanza = Color(hex: "#6B95FF")
            static let indipendente = Color(hex: "#D0954A")
            static let entrambi = Color(hex: "#FFFFFF")
            static let nucleo: [Gradient.Stop] = [.init(color: .white, location: 0),
                                                  .init(color: Color(hex: "#FFE7A8"), location: 0.35),
                                                  .init(color: Color(hex: "#FFB547").opacity(0), location: 1)]
            static let centro = Color.white
            static let raggioBase: CGFloat = 4
            static let passo: CGFloat = 3.2
            static let patrimonioUnita: Double = 60_000
            static let raggioMassimo: CGFloat = 22
            static let quotaAlone: CGFloat = 3.2
            static let opacitaAlone = 0.35
            static let sfocaturaAlone: CGFloat = 7
            static let quotaCentro: CGFloat = 0.45
            static let daFare = Color(hex: "#FF9F0A")
            static let spessoreDaFare: CGFloat = 2
            static let distanzaDaFare: CGFloat = 6
            static let nome = C(dimensione: 12.5, peso: .bold)
            static let coloreNome = Color.white
            static let contornoNome = Color(hex: "#0C1720")
            static let spessoreContornoNome: CGFloat = 3
            static let distanzaNome: CGFloat = 8
            static let sottoNome: CGFloat = 4
            static let nomiMassimi = 8
            /// Minimo per il fumetto e il clic.
            static let raggioTocco: CGFloat = 10
            /// Le luci fuori dal filtro (zona, giro) restano attenuate a questa opacità.
            static let opacitaFuori = 0.28

            static func raggio(patrimonio: Double) -> CGFloat {
                min(raggioMassimo, raggioBase + CGFloat((max(0, patrimonio) / patrimonioUnita).squareRoot()) * passo)
            }

            static func colore(_ c: CanaleLuce) -> Color {
                switch c {
                case .alleanza: return alleanza
                case .indipendente: return indipendente
                case .entrambi: return entrambi
                }
            }
        }

        // MARK: Il pannello

        enum Pannello {
            static let larghezza: CGFloat = 340
            static let margine: CGFloat = 16
            static let raggio = Tema.Apple.Raggio.card
            static let padding = EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22)
            static let fondo = K.cardPiena
            /// Sotto questa larghezza della mappa (iPad stretto) il pannello passa sotto la mappa.
            static let mappaMinima: CGFloat = 200
            static let altezzaMappaStretta: CGFloat = 420
            static let etichetta = C.etichetta
            static let coloreEtichetta = K.inchiostro2
            static let totale = C(dimensione: 30, peso: .bold, tracking: -0.6, tabellare: true)
            static let anno = C(dimensione: 72, peso: .bold, tracking: -2.2, interlinea: 1, tabellare: true)
            static let valoreCrescita = C(dimensione: 24, peso: .bold, tracking: -0.5, tabellare: true)
            static let titoloGiro = C.valore
            static let testo = C(dimensione: 13, peso: .regular, interlinea: 1.4)
            static let testoForte = C(dimensione: 13, peso: .semibold)
            static let piccolo = C.secondario
            static let coloreTesto = K.inchiostro
            static let coloreTesto2 = K.inchiostro2
            static let coloreTesto3 = K.inchiostro3
            static let testoDaFare = Color(hex: "#C25E00")
            static let bordoDaFare = Color(hex: "#FF9F0A").opacity(0.4)
            static let spazioTile: CGFloat = 10
            static let sopraTile: CGFloat = 16
            static let spazio: CGFloat = 8
            static let spazioSezione: CGFloat = 14
            // Le tile del pannello
            static let raggioTile = Tema.Apple.Raggio.tile
            static let paddingTile = Tema.Apple.Misura.Padding.tile
            static let fondoTile = K.chip
            static let fondoTileAcceso = K.selezioneVoce
            static let bordoTile = K.separatore
            static let spessoreBordoTile: CGFloat = 1
            static let titoloTile = C(dimensione: 11.5, peso: .semibold)
            static let valoreTile = C(dimensione: 16, peso: .bold, tracking: -0.2)
            static let notaTile = C(dimensione: 12, peso: .regular)
            // Il cursore della crescita
            static let spazioCursore: CGFloat = 12
            // Elenchi (con qualcosa da fare, senza posizione)
            static let altezzaRiga: CGFloat = 40
            static let avatar: CGFloat = 28
            static let raggioRiga = Tema.Apple.Raggio.voce
        }

        // MARK: Il giro di domani

        enum Giro {
            static let percorso = K.anello2
            static let spessorePercorso: CGFloat = 5
            static let raggioTappa: CGFloat = 13
            static let bordoTappa: CGFloat = 3
            static let coloreBordoTappa = Color.white
            static let numeroTappa = C(dimensione: 12, peso: .heavy, tabellare: true)
            static let coloreNumero = Color.white
            static let raggioAuto: CGFloat = 7
            static let bordoAuto: CGFloat = 3
            static let fondoAuto = Color.white
            static let raggioSuggerimento: CGFloat = 22
            static let spessoreSuggerimento: CGFloat = 2.5
            static let opacitaFuori = 0.28
            static let bordoSuggerimento = Color(hex: "#FF9F0A").opacity(0.45)
            static let fondoSuggerimento = Color(hex: "#FF9F0A").opacity(0.07)
            static let titoloSuggerimento = Color(hex: "#B45309")
            static let fondoRigaNuova = Color(hex: "#FF9F0A").opacity(0.08)
            static let raggioRigaNuova: CGFloat = 10
            static let larghezzaOra: CGFloat = 46
            static let avatar: CGFloat = 28
            static let ora = C(dimensione: 12.5, peso: .semibold, tabellare: true)
            static let nome = C(dimensione: 13.5, peso: .bold)
            static let motivo = C(dimensione: 12, peso: .regular)
            static let tratto = C(dimensione: 12, peso: .medium, tabellare: true)
            static let casa = "⌂"
            static let casaCarattere = C(dimensione: 14, peso: .bold)
            static let spazioRighe: CGFloat = 4
            static let paddingRiga = EdgeInsets(top: 7, leading: 6, bottom: 7, trailing: 6)
            /// Frazione della lunghezza del tratto: la curva «dichiarata in linea d'aria».
            static let curvatura: CGFloat = 0.12
            /// Margine della proiezione del giro (le tappe non toccano il bordo né il pannello).
            static let margineProiezione: CGFloat = 70
        }

        // MARK: La crescita

        enum Crescita {
            static let onda = Color(hex: "#FFB547")
            static let spessoreOnda: CGFloat = 2
            static let ondaDa: CGFloat = 6
            static let ondaA: CGFloat = 46
            /// Le luci non ancora nate nell'anno scelto non si vedono; quelle appena nate fanno l'onda.
        }

        // MARK: Il fumetto di una luce

        /// Non esiste un fumetto riusabile nel DesignSystem (solo `FormaFumettoDock` e `FumettoCosto`, privati): token
        /// propri sulla superficie del tema.
        enum Fumetto {
            static let superficie = Tema.Apple.Superficie.dettaglio
            static let raggio = Tema.Apple.Raggio.tile
            static let padding = Tema.Apple.Misura.Padding.tile
            static let larghezzaMassima: CGFloat = 240
            static let distanza: CGFloat = 10
            static let titolo = Tema.Apple.Carattere(dimensione: 13.5, peso: .bold)
            static let riga = Tema.Apple.Carattere.secondario
            static let coloreTitolo = K.inchiostro
            static let coloreRiga = K.inchiostro2
            static let spazio: CGFloat = 4
        }

        // MARK: Legenda e note in fondo al pannello

        enum Legenda {
            static let pallino: CGFloat = 8
            static let spazio: CGFloat = 6
            static let interlinea: CGFloat = 1.5
            static let margineBasso: CGFloat = 18
            static let margineLati: CGFloat = 22
            static let testo = C(dimensione: 11.5, peso: .regular, interlinea: 1.5)
            static let colore = K.inchiostro2
            static let bordoEntrambi = K.inchiostro3
            static let spessoreBordo: CGFloat = 1.2
        }

        // MARK: Modalità «Sposta» (posizione a mano)

        enum Sposta {
            static let fondo = K.toast
            static let testo = K.testoToast
            static let carattere = C(dimensione: 13, peso: .semibold)
            static let padding = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            static let raggio = Tema.Apple.Raggio.tile
            static let margineAlto: CGFloat = 16
            static let mirino = Color(hex: "#FF9F0A")
        }

        // MARK: Movimento (§5.1.3)

        enum Moto {
            static let durataLuce = 0.65
            static let passoLuce = 0.022
            static let indiceMassimoLuce = 40
            static let curvaLuce = Tema.Apple.Studio.Moto.curvaPunti
            static let attesaAvvio = 0.7
            static let passoAnno = 0.9
            static let passoAnnoCalmo = 0.9
            static let nascita = 0.7
            static let scalaPicco: CGFloat = 1.4
            static let onda = 1.1
            static let conteggio = 0.6
            static let tracciato = 2.0
            static let curvaTracciato = Tema.Apple.Moto.Curva.uscita
            static let tappa = 0.5
            static let ritardoTappa = 0.3
            static let passoTappa = 0.45
            static let partenzaAuto = 2.0
            static let giroAuto = 6.0
            static let pulsazione = 1.8
            static let scalaPulsazione: CGFloat = 1.35
            static let opacitaPulsazione = 0.35
            static let pulsantiMassimi = 12
            static let rimonta = Tema.Apple.Studio.Moto.durataRimonta
            static let dissolvenzaCalma = 0.15
            static let cambioProiezione = 0.6
        }
    }
}
