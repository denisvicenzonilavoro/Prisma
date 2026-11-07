import SwiftUI

// Pratiche (Design/template-luce-specifica.md §7.0 e §7.1, «Luce» giro 3): misure, colori, caratteri e tempi dell'app
// Pratiche. La parte comune (barra laterale delle schede, voci, stato vuoto) sta in `Tema.Apple.Pratiche`, la scheda
// Proposta in `Tema.Apple.Pratiche.Proposta`. Le viste stanno in Shell/PratichePropostaApple.swift; qui solo i valori.

extension Tema.Apple {
    enum Pratiche {
        typealias C = Tema.Apple.Colore
        typealias K = Tema.Apple.Carattere

        // MARK: Parte comune (§7.0)

        /// Barra laterale di Proposta e Sinistri: 300 (Moduli 290), colonna principale a 16 dalla barra.
        static let laterale: CGFloat = 300
        static let lateraleModuli: CGFloat = 290
        static let spazioLaterale: CGFloat = 16
        /// La barra: raggio 20, fondo `pannello`, bordo 1 separatore, padding 14/12, titolo etichetta con 8 sotto.
        static let raggioLaterale = Tema.Apple.Raggio.pannello
        static let fondoLaterale = C.pannello
        static let bordoLaterale = C.separatore
        static let paddingLaterale = Tema.Apple.Misura.Padding.barraLaterale
        static let titoloLaterale = K.etichetta
        static let coloreTitoloLaterale = C.inchiostro2
        static let sottoTitoloLaterale: CGFloat = 8
        /// Le voci: padding 10, raggio 14, spazio 10, allineate in alto; scelta `selezioneVoce`, sotto il puntatore `chip`.
        static let paddingVoce = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        static let raggioVoce = Tema.Apple.Raggio.voce
        static let spazioVoce: CGFloat = 10
        static let spazioVoci: CGFloat = 2
        static let fondoScelta = C.selezioneVoce
        static let fondoSopra = C.chip
        static let titoloVoce = K(dimensione: 14, peso: .bold)
        static let motivoVoce = K(dimensione: 12, peso: .regular, interlinea: 1.35)
        static let spazioTitoloMotivo: CGFloat = 2
        /// Il motivo va a capo, largo al più 200.
        static let larghezzaMotivo: CGFloat = 200
        static let animazioneFondo = Tema.Apple.Moto.Curva.ease.animazione(0.25)
        /// Avatar della voce (36), della testata (46); delle pratiche (40) e dei chip (22) per i giri dopo.
        static let avatarVoce: CGFloat = 36
        static let avatarTestata: CGFloat = 46
        static let avatarPratica: CGFloat = 40
        static let avatarChip: CGFloat = 22
        /// Titolo della colonna principale: display 24 grassetto, tracking −0,5.
        static let titolo = K(dimensione: 24, peso: .bold, tracking: -0.5)
        static let sopraTitolo = K.secondario
        static let spazioTestata: CGFloat = 12
        static let spazioSopraTitolo: CGFloat = 2
        /// Lo stato vuoto comune: tassello del glifo della scheda (64), frase e pulsante.
        static let tasselloVuoto: CGFloat = 64
        static let spazioVuoto: CGFloat = 12
        static let fraseVuota = K.corpo
        static let notaVuota = K.secondario
        static let larghezzaVuota: CGFloat = 420
        /// L'etichetta «dati di prova» (catalogo d'esempio).
        static let datiDiProva = K(dimensione: 11, peso: .semibold)
        static let coloreDatiDiProva = C.inchiostro3
        static let paddingDatiDiProva = Tema.Apple.Misura.padding(2, 7)
        static let fondoDatiDiProva = C.chip

        // MARK: Proposta (§7.1)

        enum Proposta {
            /// La linea dei cinque passi: 22 sotto la testata, cinque colonne uguali con 16 di spazio, riquadri alti 320.
            static let distanzaLinea: CGFloat = 22
            static let spazioPassi: CGFloat = 16
            static let altezzaPasso: CGFloat = 320
            static let raggioPasso = Tema.Apple.Raggio.pannello
            static let paddingPasso = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            static let spazioDentro: CGFloat = 12
            /// Fra le righe di un contenuto (cifra e spiegazione, nome e canale, titolo e frase del riquadro finale).
            static let spazioRighe: CGFloat = 4
            /// Spento: bordo tratteggiato 1,5 `inchiostro3` (in scuro bianco al 38%), tratteggio 5 4, opacità 0,7.
            static let trattoSpento: CGFloat = 1.5
            static let tratteggio: [CGFloat] = [5, 4]
            static let coloreSpento = C.inchiostro3
            static let opacitaSpento = 0.7
            /// Acceso: fondo `cardPiena` (#283642 in scuro), bordo 1 separatore, ombra della card.
            static let fondoAcceso = C.cardPiena
            static let bordoAcceso = C.separatore
            /// Fermo (arancio): fondo e bordo dell'avviso, frase e «Rimedia».
            static let fondoFermo = C.avvisoFondo
            static let bordoFermo = C.avvisoBordo
            static let coloreFermo = C.arancio
            /// Non adeguata (rosso).
            static let fondoRosso = C.rosso.opacity(0.06)
            static let bordoRosso = C.rosso.opacity(0.4)
            /// Il tondo col numero: 26, fondo `chip`, cifra 12,5 grassetto; acceso verde con la cifra bianca, scala 1,1.
            static let numero: CGFloat = 26
            static let cifra = K(dimensione: 12.5, peso: .bold, tabellare: true)
            static let fondoNumero = C.chip
            static let fondoNumeroAcceso = C.verde
            static let fondoNumeroFermo = C.arancio
            static let fondoNumeroRosso = C.rosso
            static let cifraAccesa = Color.white
            static let scalaNumeroAcceso: CGFloat = 1.1
            static let spazioNumero: CGFloat = 8
            static let etichetta = K.etichetta
            /// Il prodotto: tassello 40, nome display 19 grassetto interlinea 1,2.
            static let tassello: CGFloat = 40
            static let nomeProdotto = K.perche
            /// L'importo: display 30 grassetto, tracking −0,8, cifre tabellari; spiegazione e riga del premio (10 sopra).
            static let importo = K(dimensione: 30, peso: .bold, tracking: -0.8, tabellare: true)
            static let spiegazione = K.secondario
            static let rigaPremio = K.barra
            static let spazioPremio: CGFloat = 10
            /// L'adeguatezza: anello 100 spessore 11, spunta 30.
            static let anello: CGFloat = 100
            static let spessoreAnello: CGFloat = 11
            static let spunta: CGFloat = 30
            static let esitoAdeguatezza = K.barra
            static let dettaglio = K(dimensione: 12, peso: .regular, interlinea: 1.3)
            static let anelloVerde = C.anello1
            static let anelloGiallo = C.arancio
            static let anelloRosso = C.rosso
            static let anelloNeutro = C.binario
            /// Frase dei passi fermi e dei moduli in arrivo.
            static let frase = K(dimensione: 13, peso: .regular, interlinea: 1.35)
            /// La scelta del prodotto: al più quattro, ognuno in una riga con l'etichetta del canale.
            static let maxProdottiScelta = 4
            static let rigaScelta = Tema.Apple.Misura.padding(8, 10)
            static let raggioScelta = Tema.Apple.Raggio.giorno
            static let fondoScelta = C.chip
            static let nomeScelta = K(dimensione: 13, peso: .semibold)
            static let spazioScelta: CGFloat = 6
            /// Il riquadro finale «Proposta pronta»: 20 sotto la linea, bordo verde 40%, fondo verde 7%, riga con spazio 18.
            static let distanzaFine: CGFloat = 20
            static let spuntaPronta: CGFloat = 34
            static let spazioPronta: CGFloat = 18
            static let fondoPronta = C.verde.opacity(0.07)
            static let bordoPronta = C.verde.opacity(0.4)
            static let titoloPronta = K.titoloGruppo
            static let testoPronta = K.secondario
            static let paddingPronta = Tema.Apple.Misura.Padding.cardPiccola
            static let raggioPronta = Tema.Apple.Raggio.card
            /// Colonna principale: sotto questa larghezza i cinque riquadri vanno su due righe.
            static let larghezzaUnaRiga: CGFloat = 900
            static let colonneStrette = 3

            /// La miniatura del prospetto: carta bianca larga 150, raggio 6, padding 12; quattro righe alte 5 (raggio 3,
            /// spazio 6) larghe 60/85/70/45%; in mezzo il grafico 120×44 con la linea blu 2,4. Sempre bianca, anche in scuro.
            enum Miniatura {
                static let larghezza: CGFloat = 150
                static let raggio = Tema.Apple.Raggio.bollaPiccola
                static let padding: CGFloat = 12
                static let riga: CGFloat = 5
                static let raggioRiga: CGFloat = 3
                static let spazioRighe: CGFloat = 6
                static let larghezze: [CGFloat] = [0.60, 0.85, 0.70, 0.45]
                static let grafico = CGSize(width: 120, height: 44)
                static let tratto: CGFloat = 2.4
                static let fondo = Tema.Apple.Carta.fondo
                static let coloreRiga = Tema.Apple.Carta.filetto
                static let coloreLinea = Tema.Apple.Carta.bluGrafico
                /// La linea che sale (punti normalizzati, y dal basso): solo un disegno, non dati.
                static let linea: [CGPoint] = [CGPoint(x: 0, y: 0.12), CGPoint(x: 0.25, y: 0.3), CGPoint(x: 0.5, y: 0.42),
                                               CGPoint(x: 0.75, y: 0.66), CGPoint(x: 1, y: 0.9)]
                /// Ombra 0 8 20 −10 nero al 35%.
                static let ombra = Color(r: 0, g: 0, b: 0, a: 0.35)
                static let ombraRaggio: CGFloat = 10
                static let ombraY: CGFloat = 8
            }
        }

        // MARK: Movimento (§7.1.8)

        enum Moto {
            /// Il passo i si accende a 0,30 + i·0,62 s: bordo, fondo, ombra e opacità in 0,50 s (uscita); sale da 12 e
            /// scala 0,97 in 0,52 s (molla).
            enum Passo {
                static let base = 0.30
                static let passo = 0.62
                static let durataAccensione = 0.50
                static let durataSalita = 0.52
                static let spostamento: CGFloat = 12
                static let scala: CGFloat = 0.97
                static func ritardo(_ i: Int) -> Double { base + Double(i) * passo }
                static var accensione: Animation { Tema.Apple.Moto.Curva.uscita.animazione(durataAccensione) }
                static var salita: Animation { Tema.Apple.Moto.Curva.molla.animazione(durataSalita) }
            }
            /// Il tondo del numero: scala 1,1 in 0,4 s (molla).
            static let durataNumero = 0.40
            static var numero: Animation { Tema.Apple.Moto.Curva.molla.animazione(durataNumero) }
            /// L'anello parte 0,08 s dopo l'accensione del passo.
            static let ritardoAnello = 0.08
            /// La linea della miniatura: 0,15 s poi 1,5 s (`Moto.Linea`).
            static let ritardoLinea = Tema.Apple.Moto.Linea.ritardoBase
            /// Il riquadro finale: 1,10 s dopo il quinto passo, 0,50 s da 14 più in basso e opacità 0 (uscita).
            enum Pronta {
                static let ritardo = 1.10
                static let durata = 0.50
                static let spostamento: CGFloat = 14
                static var animazione: Animation { Tema.Apple.Moto.Curva.uscita.animazione(durata) }
            }
            /// Il cambio di bisogno: la colonna principale esce in 0,14 s verso y +14 (`Moto.CambioCliente`).
            static var cambio: Animation { Tema.Apple.Moto.CambioCliente.uscita }
            static let spostamentoCambio = Tema.Apple.Moto.CambioCliente.spostamento
        }
    }
}
