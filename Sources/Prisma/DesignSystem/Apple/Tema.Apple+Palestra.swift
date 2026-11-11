import SwiftUI

// Gettoni di Studio › Palestra, la palestra della trattativa (Design/template-luce-specifica.md §5.3.2 e §5.3.3,
// «Luce» giro 5; template righe 1729-1757, CSS `.pB`, `.pFb`, `.opz`, `.typing`). Misure in pt del palco 1440×900,
// tempi in secondi. La vista sta in Shell/StudioPalestra.swift.

extension Tema.Apple {
    enum Palestra {
        typealias C = Tema.Apple.Carattere
        typealias K = Tema.Apple.Colore

        // MARK: Disposizione

        /// La colonna sinistra larga 380 (come la colonna di Messaggi) e 16 prima della conversazione.
        static let larghezzaColonna = Tema.Apple.Messaggi.Disposizione.larghezzaColonna
        static let gioco = Tema.Apple.Messaggi.Disposizione.gioco
        /// Sotto questa larghezza la colonna si stringe fino a `larghezzaColonnaMinima`.
        static let larghezzaColonnaMinima = Tema.Apple.Messaggi.Disposizione.larghezzaColonnaMinima
        /// Le due card: superficie e raggio delle card di Studio; padding 22 / 24 a sinistra, 20 / 26 a destra.
        static let superficie = Tema.Apple.Studio.Card.superficie
        static let raggio = Tema.Apple.Studio.Card.raggio
        static let paddingColonna = Tema.Apple.Misura.Padding.cardGrande
        static let paddingConversazione = Tema.Apple.Misura.padding(20, 26)

        // MARK: Colonna sinistra

        /// `.lbl` «LA PALESTRA DELLA TRATTATIVA», «DIFFICOLTÀ».
        static let etichetta = C.etichetta
        static let coloreEtichetta = K.inchiostro2
        /// Il profilo: 14 sotto l'etichetta, avatar 56, 12 di gioco, nome 17 bold, «Vera nei panni di …» `.k`.
        static let sopraProfilo: CGFloat = 14
        static let avatar = Tema.Apple.Misura.Avatar.dossier
        static let spazioAvatar: CGFloat = 12
        static let nome = C.titoloFinestra
        static let coloreNome = K.inchiostro
        static let ruolo = C.secondario
        static let coloreRuolo = K.inchiostro2
        /// Il selettore «Allenati con…» accanto al nome.
        static let selettore = C.pulsante
        static let coloreSelettore = K.accento
        /// La tile del profilo: 16 sopra, 13,5 interlinea 1,55, padding 14 / 16, raggio 18.
        static let sopraTile: CGFloat = 16
        static let profilo = C(dimensione: 13.5, peso: .regular, interlinea: 1.55)
        static let profiloForte = C(dimensione: 13.5, peso: .bold, interlinea: 1.55)
        static let coloreProfilo = K.inchiostro
        static let tile = Superficie.tile
        static let paddingTile = Tema.Apple.Misura.Padding.tile
        /// «Di … Prisma sa poco»: la nota del profilo scarno, arancio come le altre etichette di attenzione.
        static let coloreScarno = K.arancio
        /// «DIFFICOLTÀ»: 16 sopra, 8 sotto.
        static let sopraDifficolta: CGFloat = 16
        static let sottoDifficolta: CGFloat = 8
        /// «Obiezione 1 di 3» `.k`, 16 sopra; la barra alta 8 in accento, 6 sotto il testo.
        static let sopraAvanzamento: CGFloat = 16
        static let sottoTestoAvanzamento: CGFloat = 6
        static let altezzaBarra: CGFloat = 8
        static let coloreBarra = K.accento
        /// La nota in fondo: 24 dai lati, 20 dal fondo, `.k` interlinea 1,45.
        static let nota = C(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let coloreNota = K.inchiostro2

        // MARK: Conversazione

        /// La conversazione: 18 sopra; le risposte 18 dal fondo.
        static let sopraConversazione: CGFloat = 18
        static let sottoRisposte: CGFloat = 18
        /// Fra una bolla e l'altra 14 (`.pB` margin-bottom).
        static let fraBolle: CGFloat = 14

        enum Bolla {
            /// Cliente `--chip`, consulente `--accent` con il testo bianco.
            static let fondoCliente = K.chip
            static let fondoConsulente = K.accento
            static let testoCliente = K.inchiostro
            static let testoConsulente = Color.white
            /// Padding 11 / 15, raggio 18 con la punta 6, 15 pt interlinea 1,5, larga al più 720.
            static let padding = Tema.Apple.Misura.padding(11, 15)
            static let raggio: CGFloat = 18
            static let raggioPunta: CGFloat = 6
            static let testo = C(dimensione: 15, peso: .regular, interlinea: 1.5)
            static let larghezzaMassima: CGFloat = 720
            /// Avatar 34 con 10 di gioco; sopra la bolla «… · recitata da Vera» 11,5 `.k`, 3 sotto.
            static let avatar = Tema.Apple.Misura.Avatar.voce
            static let spazioAvatar: CGFloat = 10
            static let chi = C(dimensione: 11.5, peso: .regular)
            static let coloreChi = K.inchiostro2
            static let sottoChi: CGFloat = 3
        }

        /// Il giudizio sotto la bolla del consulente: 12,5 bold, 5 sopra; verde, accento, rosso.
        static let giudizio = C(dimensione: 12.5, peso: .bold)
        static let sopraGiudizio: CGFloat = 5
        static func colore(_ g: GiudizioPalestra) -> Color {
            switch g {
            case .ottima: return K.verde
            case .buona: return K.accento
            case .debole: return K.rosso
            }
        }

        // MARK: Risposte

        /// `.lbl` «RISPONDI», 8 sotto; opzioni padding 10 / 14, 14 pt, raggio 16, lettera 26, 8 fra loro.
        static let sottoRispondi: CGFloat = 8
        static let fraOpzioni: CGFloat = 8
        static let paddingOpzione = Tema.Apple.Misura.padding(10, 14)
        static let testoOpzione = C(dimensione: 14, peso: .regular, interlinea: 1.3)
        static let letteraOpzione: CGFloat = 26
        static let raggioOpzione = Tema.Apple.OpzioneLettera.raggio
        /// Il campo libero: pillola `--chip`, padding 4 / 4 / 4 / 16, 14 pt; il pulsante «↑» primario.
        static let fondoCampo = K.chip
        static let paddingCampo = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 4)
        static let testoCampo = C.corpo
        static let sopraCampo: CGFloat = 2
        /// Il microfono nel campo (la voce del Mac già in Vera).
        static let coloreMicrofono = K.inchiostro2
        static let coloreMicrofonoAcceso = K.rosso

        // MARK: Fine

        /// La tile finale (fondo `--cardE`), 14 sopra e sotto, 22 fra l'anello e il testo.
        static let tileFine = Superficie(riempimento: K.cardPiena, sfocatura: 0, saturazione: 1, bordo: K.separatore,
                                         spessoreBordo: 1, ombra: nil, raggio: Tema.Apple.Raggio.tile, filoInterno: false)
        static let spazioFine: CGFloat = 22
        /// Anello 120 tratto 12; soglie 70 / 45; #30B15C / #0A84FF / #E08A00; punteggio display 28 bold.
        static let anelloFinale: CGFloat = 120
        static let spessoreFinale: CGFloat = 12
        static let sogliaBuona = 70
        static let sogliaMedia = 45
        static func coloreAnello(_ punteggio: Int) -> Color {
            punteggio >= sogliaBuona ? K.anello1 : (punteggio >= sogliaMedia ? K.anello2 : K.arancio)
        }
        static let punteggio = C(dimensione: 28, peso: .bold, tabellare: true)
        static let titoloFine = C.titoloFinestra
        static let testoFine = C(dimensione: 12.5, peso: .regular, interlinea: 1.5)
        static let testoFineForte = C(dimensione: 12.5, peso: .bold, interlinea: 1.5)
        static let sopraTestoFine: CGFloat = 6
        static let sopraPulsantiFine: CGFloat = 10
        static let fraPulsanti: CGFloat = 6
        /// «punteggio indicativo» sotto l'anello.
        static let indicativo = C.asse
        static let coloreIndicativo = K.inchiostro3

        // MARK: Stati

        /// L'invito, Vera non pronta, «Scegli un cliente»: riquadro centrato, largo al più 440.
        static let larghezzaStato: CGFloat = 440
        static let titoloStato = C.titoloRiga
        static let testoStato = C(dimensione: 13.5, peso: .regular, interlinea: 1.45)
        static let coloreStato = K.inchiostro2
        static let spazioStato: CGFloat = 10
        static let sferaStato: CGFloat = 44
        /// «Vera ci sta mettendo un po'…»: dopo 20 s.
        static let attesaLenta: Double = 20
    }
}

extension Tema.Apple.Moto {
    /// La bolla della palestra che entra: da y +14, scala 0,97, opacità 0, 0,42 s con la molla (§5.3.3).
    enum Bolla {
        static let durata = 0.42
        static let spostamento: CGFloat = 14
        static let scala: CGFloat = 0.97
        static var animazione: Animation { Curva.molla.animazione(durata) }
    }

    /// I tempi della palestra della trattativa (§5.3.3).
    enum Palestra {
        /// La prima obiezione parte 0,35 s dopo «Inizia».
        static let attesaInizio = 0.35
        /// Tra la replica e l'obiezione dopo.
        static let pausaTurno = 0.9
        /// Le opzioni: da y +10, 0,38 s `uscita`, una ogni 0,07 s.
        static let durataOpzione = 0.38
        static let passoOpzione = 0.07
        static let spostamentoOpzione: CGFloat = 10
        static func opzione(indice: Int) -> Animation {
            Curva.uscita.animazione(durataOpzione).ritardoPrisma(Double(indice) * passoOpzione)
        }
        /// Il giudizio: scala 0,8 → 1, 0,4 s dopo 0,3 s, curva `punti` (.34, 1.6, .64, 1).
        static let giudizio = 0.4
        static let ritardoGiudizio = 0.3
        static let scalaGiudizio: CGFloat = 0.8
        static let curvaPunti = Curva(x1: 0.34, y1: 1.6, x2: 0.64, y2: 1)
        static var animazioneGiudizio: Animation { curvaPunti.animazione(giudizio).ritardoPrisma(ritardoGiudizio) }
        /// La barra d'avanzamento: 0,6 s `uscita`.
        static let avanzamento = 0.6
        static var animazioneAvanzamento: Animation { Curva.uscita.animazione(avanzamento) }
        /// La tile finale: da y +16, 0,5 s `uscita`; l'anello 0,1 s dopo.
        static let durataFine = 0.5
        static let spostamentoFine: CGFloat = 16
        static let ritardoAnelloFine = 0.1
        static var animazioneFine: Animation { Curva.uscita.animazione(durataFine) }
        /// Lo scorrimento all'ultima bolla.
        static let durataScorrimento = 0.45
        static var animazioneScorrimento: Animation { Curva.uscita.animazione(durataScorrimento) }
    }
}
