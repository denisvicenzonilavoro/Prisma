import SwiftUI

// La nota vocale (Design/template-luce-specifica.md §6.2.2, §6.2.3, «Luce» giro 13): misure, caratteri, colori e tempi
// della scheda «Arriva sul Mac», delle quattro voci proposte, della scena dimostrativa «Come funziona» (telefono disegnato
// in ascolto) e della schermata vera dell'iPhone. Le viste stanno in Shell/NotaVocaleArrivo.swift e
// iOS/NotaVocaleTelefono.swift; qui solo i valori.

extension Tema.Apple {
    enum NotaVocale {
        typealias C = Tema.Apple.Carattere
        typealias K = Tema.Apple.Colore

        // MARK: La scheda «Arriva sul Mac»

        enum Scheda {
            /// Larga 470, padding 22×24, in alto a destra sotto la barra (come le notifiche).
            static let larghezza: CGFloat = 470
            static let padding = Tema.Apple.Misura.padding(22, 24)
            static let superficie = Tema.Apple.Inquadra.Scheda.superficie
            static let sfera: CGFloat = 26
            static let spazioTesta: CGFloat = 10
            static let etichetta = C.etichetta
            static let coloreEtichetta = K.inchiostro2
            static let paddingChiudi = Tema.Apple.Misura.padding(6, 10)
            /// «Aspetto la nota…»: padding 20 sopra e sotto.
            static let attesa: CGFloat = 20
            static let fraseAttesa = C.secondario
            static let coloreAttesa = K.inchiostro2
            /// Dal bordo destro e dalla barra.
            static let margineDestro: CGFloat = 16
            static let sottoBarra: CGFloat = 52
            static let piede = C.secondario
            static let colorePiede = K.inchiostro2
            static let piedeSopra: CGFloat = 14
            static let pulsantiSopra: CGFloat = 14
            static let spazioPulsanti: CGFloat = 8
            /// Il testo dettato, sotto la riga del cliente (al più quattro righe).
            static let testo = C(dimensione: 13, peso: .regular, interlinea: 1.4)
            static let coloreTesto = K.inchiostro2
            static let righeTesto = 4
        }

        enum Cliente {
            /// Avatar 40 (nuovo: `Misura.Avatar` ha 38 e 54), didascalia 12,5, nome 16 bold; filo sotto (6 sopra, 12 sotto).
            static let avatar: CGFloat = 40
            static let didascalia = C(dimensione: 12.5, peso: .regular)
            static let coloreDidascalia = K.inchiostro2
            static let nome = C(dimensione: 16, peso: .bold)
            static let coloreNome = K.inchiostro
            static let sopra: CGFloat = 6
            static let sotto: CGFloat = 12
            static let spazio: CGFloat = 12
            static let filo = K.separatore
            /// I clienti possibili quando Prisma non è sicuro.
            static let spazioCandidati: CGFloat = 6
        }

        // MARK: Le voci proposte

        enum Voce {
            /// Padding 10×14, 10 sopra, raggio 12, fondo chip, filo sinistro 3 nel colore della voce.
            static let padding = Tema.Apple.Misura.padding(10, 14)
            static let sopra: CGFloat = 10
            static let raggio: CGFloat = 12
            static let fondo = K.chip
            static let filo: CGFloat = 3
            static let titolo = C(dimensione: 13.5, peso: .bold)
            static let coloreTitolo = K.inchiostro
            static let riga = C(dimensione: 13, peso: .regular)
            static let coloreRiga = K.inchiostro2
            static let spazio: CGFloat = 4
            static let spazioPulsanti: CGFloat = 6
            /// Una voce scartata resta, sbiadita.
            static let opacitaScartata: Double = 0.45
            /// I colori: nota #0A84FF, attività #30B15C, messaggio #E08A00, obiettivo #8B5CF6 (distinti dal copilota).
            static let nota = K.Area.investimenti
            static let attivita = K.anello1
            static let messaggio = K.arancio
            static let obiettivo = K.stima

            static func colore(_ t: TipoPropostaNota) -> Color {
                switch t {
                case .nota: return nota
                case .attivita: return attivita
                case .messaggio: return messaggio
                case .obiettivo: return obiettivo
                }
            }
        }

        // MARK: Il telefono (scena dimostrativa e schermata vera)

        enum Telefono {
            /// Fondo del telefono disegnato: sfumatura a 170° da #141B22 a #0B1015 (solo nella scena dimostrativa).
            static let fondo = [Color(hex: "#141B22"), Color(hex: "#0B1015")]
            static let paddingSopra: CGFloat = 58
            static let paddingLati: CGFloat = 22
            /// In alto: l'ora e «Prisma», 12 al 60%.
            static let testa = C(dimensione: 12, peso: .regular)
            static let opacitaTesta: Double = 0.6
            /// Titolo display 24 bold (28 sotto la testa), sottotitolo 13 al 55%, testo 16 interlinea 1,5 alto almeno 140.
            static let titolo = C(dimensione: 24, peso: .bold, tracking: -0.4)
            static let titoloSopra: CGFloat = 28
            static let sottotitolo = C(dimensione: 13, peso: .regular)
            static let opacitaSottotitolo: Double = 0.55
            static let sottotitoloSopra: CGFloat = 4
            static let testo = C(dimensione: 16, peso: .regular, interlinea: 1.5)
            static let testoSopra: CGFloat = 22
            static let altezzaTesto: CGFloat = 140
            static let ondaSopra: CGFloat = 10
            /// La riga di stato: 12 al 60%, a 34 dal fondo.
            static let stato = C(dimensione: 12, peso: .regular)
            static let opacitaStato: Double = 0.6
            static let statoDalFondo: CGFloat = 34
            static let inchiostro = Color.white
            /// L'avviso «Detta solo tu…» e la riga dello scaricamento.
            static let avviso = C(dimensione: 12, peso: .regular, interlinea: 1.35)
            static let spazio: CGFloat = 12
            /// L'elenco «Note in partenza».
            static let titoloCoda = C(dimensione: 13, peso: .semibold)
            static let voceCoda = C(dimensione: 13, peso: .regular)
            static let massimoRigheVoceCoda = 2
        }

        enum Registra {
            /// Cerchio 68 con il bordo 4 bianco all'85%, a 62 dal fondo; dentro il quadrato rosso 28 con raggio 8.
            static let diametro: CGFloat = 68
            static let bordo: CGFloat = 4
            static let coloreBordo = Color.white.opacity(0.85)
            static let dalFondo: CGFloat = 62
            static let quadrato: CGFloat = 28
            static let raggioQuadrato: CGFloat = 8
            static let rosso = Color(hex: "#FF453A")
            /// A nota finita: bordo verde e cerchio pieno verde da 50.
            static let fatto: CGFloat = 50
            static let verde = Color(hex: "#30D158")
            /// Il respiro: il quadrato scende all'85% e torna.
            static let scalaRespiro: CGFloat = 0.85
            /// Il bordo quando il pulsante è su sfondo chiaro (iPhone in chiaro).
            static let coloreBordoChiaro = K.inchiostro3
        }

        /// L'onda del telefono: 39 barre a passo 6, larghe 3,6, raggio 1,8, altezza max(3, a·44), #FF453A al 90%; ferma,
        /// barre alte 3 nello stesso rosso (come il template).
        static let onda = ParametriOnda(larghezza: 234, altezza: 50, barre: 39, passo: 6, larghezzaBarra: 3.6, raggioBarra: 1.8,
                                        minima: 3, scala: 44, coloreAscolto: Color(r: 255, g: 69, b: 58, a: 0.9),
                                        coloreFermo: Color(r: 255, g: 69, b: 58, a: 0.9),
                                        tempoIstantanea: Tema.Apple.Copilota.Onda.tempoIstantanea)
    }
}

extension Tema.Apple.Moto {
    enum NotaVocale {
        /// Il quadrato rosso respira in 1,6 s (avanti e indietro, `repeatForever`).
        static let respiro = 1.6
        static var animazioneRespiro: Animation { Curva.easeInOut.animazione(respiro).repeatForever(autoreverses: true) }
        /// Le voci sul Mac: da x +30, 0,5 s, una ogni 0,26 s, con la molla del tema.
        static let durataVoce = 0.50
        static let passo = 0.26
        static let spostamento: CGFloat = 30
        static var voce: Animation { Curva.molla.animazione(durataVoce) }
        /// Fine della nota: bordo e cerchio verdi in 0,5 s con la molla.
        static let durataFine = 0.5
        static var fine: Animation { Curva.molla.animazione(durataFine) }
        /// Dal pannello Novità: «Come funziona» dopo 0,5 s se Incontri era già davanti, 0,9 s se no.
        static let aperturaDaNovita = Tema.Apple.Moto.Inquadra.aperturaDaNovita
        static let aperturaDaNovitaFinestra = Tema.Apple.Moto.Inquadra.aperturaDaNovitaFinestra
        /// La scheda entra come il pannello delle notifiche.
        static var scheda: Animation { PannelloNotifiche.animazione }
        static let spostamentoScheda = PannelloNotifiche.spostamento
        static let scalaScheda = PannelloNotifiche.scala
    }
}
