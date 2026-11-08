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

        // MARK: Moduli (§7.2, «Luce» giro 10)

        /// «Compila da solo»: barra larga 290 con le voci a tassello 32, la pagina del modulo su un piano `chip`, la
        /// colonna «Compila per» larga 300. Sulla carta i colori sono fissi (uguali in scuro, regola dei documenti).
        enum Moduli {
            /// Il tassello della voce: 32, blu se scelta, grigio (#9FB3C2) se no.
            static let tassello: CGFloat = 32
            static let tasselloScelto = C.anello2
            static let tasselloSpento = C.Composizione.liquidita
            static let sottotitoloVoce = K(dimensione: 12, peso: .regular)
            /// La frase in fondo alla barra (`.k`, interlinea 1,45) e lo spazio sopra il piede.
            static let fraseBarra = K(dimensione: 12.5, peso: .regular, interlinea: 1.45)
            static let spazioPiede: CGFloat = 10
            /// Colonne: pagina e colonna destra a 18; la colonna destra 300, i suoi blocchi a 10.
            static let spazioColonne: CGFloat = 18
            static let colonnaDestra: CGFloat = 300
            static let spazioDestra: CGFloat = 10
            /// Il piano grigio della pagina: `chip`, raggio 20, 14 sopra, contenuto centrato e tagliato.
            static let fondoPiano = C.chip
            static let raggioPiano = Tema.Apple.Raggio.pannello
            static let margineAltoPiano: CGFloat = 14
            static let marginePiano: CGFloat = 18
            /// La pagina: carta bianca con l'ombra 0 20 50 −10 nero al 25%; scala 0,74 (si stringe se non c'è spazio).
            static let scalaPagina: CGFloat = 0.74
            static let fondoPagina = Tema.Apple.Carta.fondo
            static let ombraPagina = Color(r: 0, g: 0, b: 0, a: 0.25)
            static let ombraRaggio: CGFloat = 25
            static let ombraY: CGFloat = 20
            /// Il titolo del fac-simile (solo il PDF di prova: il PDF vero ha i suoi caratteri).
            static let titoloPagina: CGFloat = 26
            /// Le caselle sopra la pagina (in punti della pagina, poi scalate): raggio 5, bordo 1 #D5DCE2.
            static let raggioCampo: CGFloat = 5
            /// Il bordo delle caselle e delle tile: quello del tema; 2 sulla casella scelta nella revisione.
            static let bordoCasella = Tema.Apple.Misura.bordo
            static let bordoCasellaScelta: CGFloat = 2
            /// La larghezza in pixel a cui si disegna la pagina (una sola misura: l'immagine resta in memoria).
            static let larghezzaDisegno: CGFloat = 1000
            /// La colonna del numero nelle righe della revisione.
            static let colonnaNumero: CGFloat = 18
            static let altezzaCampo: CGFloat = 31
            static let altezzaFirma: CGFloat = 56
            static let bordoCampo = Tema.Apple.Carta.bordoCampo
            static let testoCampo = Tema.Apple.Carta.testo
            /// Il valore nella casella: 12,5 (in punti della pagina), il «?» rosso grassetto.
            static let valoreCampo: CGFloat = 12.5
            static let campoPieno = C.anello1.opacity(0.08)
            static let bordoPieno = C.anello1.opacity(0.55)
            static let campoManca = C.rosso.opacity(0.08)
            static let bordoManca = C.rosso
            static let anelloManca = C.rosso.opacity(0.15)
            static let spessoreAnello: CGFloat = 3
            static let testoManca = C.rosso
            /// Firma: fondo giallo .16, bordo #E0B000, anello giallo .25 (colori fissi della carta).
            static let firmaFondo = Color(hex: "#FFCC00").opacity(0.16)
            static let firmaBordo = Color(hex: "#E0B000")
            static let firmaAnello = Color(hex: "#FFCC00").opacity(0.25)
            /// Le risposte del cliente (questionario, antiriciclaggio): casella tratteggiata grigia, mai riempita.
            static let riservatoBordo = Tema.Apple.Carta.piede
            static let riservatoTratteggio: [CGFloat] = [3, 3]
            static let riservatoTesto = Tema.Apple.Carta.piede
            static let riservatoCarattere: CGFloat = 8.5
            /// La casella non ancora compilata e quella scelta nella revisione della mappa.
            static let campoVuoto = C.anello2.opacity(0.05)
            static let bordoVuoto = C.anello2.opacity(0.35)
            static let campoScelto = C.anello2.opacity(0.16)
            static let bordoScelto = C.anello2
            static let numeroCampo: CGFloat = 8
            /// Le frecce delle pagine sotto il foglio.
            static let pagine = K.secondario
            static let spazioPagine: CGFloat = 10
            /// Tile «Campi compilati»: il numero 26 e «di 15» 14 `inchiostro2`.
            static let tile = Tema.Apple.Superficie.tile
            static let numero = K.valore
            static let diTotale = K(dimensione: 14, peso: .regular, tabellare: true)
            static let paddingTile = Tema.Apple.Misura.padding(14, 16)
            static let raggioTile = Tema.Apple.Raggio.tile
            static let spazioTile: CGFloat = 8
            /// Tile di Vera: bordo rosato (rosso .35), sfera 22, testo 14 interlinea 1,5.
            static let bordoVera = C.rosso.opacity(0.35)
            static let sferaVera: CGFloat = 22
            static let nomeVera = K(dimensione: 13.5, peso: .bold)
            static let testoVera = K(dimensione: 14, peso: .regular, interlinea: 1.5)
            /// Tile delle firme: bordo giallo .5, fondo .08.
            static let tileFirmeBordo = Color(hex: "#FFCC00").opacity(0.5)
            static let tileFirmeFondo = Color(hex: "#FFCC00").opacity(0.08)
            static let titoloTile = K(dimensione: 13.5, peso: .bold)
            /// Tile delle risposte del cliente: bordo `separatore`.
            static let tileRisposteBordo = C.separatore
            /// Le righe dei dati che mancano: nome 13 semigrassetto e «Lo scrivo io».
            static let rigaManca = K(dimensione: 13, peso: .semibold)
            static let spazioRighe: CGFloat = 6
            /// Chip dei clienti: avatar 22, nome 13 semigrassetto; acceso blu pieno (`accento`) con il testo bianco.
            static let avatarChip: CGFloat = 22
            static let chipCarattere = K.barra
            static let chipFondo = C.cardPiena
            static let chipBordo = C.separatore
            static let chipTesto = C.inchiostro
            static let chipAcceso = C.accento
            static let chipTestoAcceso = Color.white
            static let chipPadding = EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 14)
            static let spazioChip: CGFloat = 6
            /// Il margine del testo dentro una casella (punti della pagina, scalati con la pagina).
            static let paddingCasella: CGFloat = 6
            /// Lo spazio per le frecce delle pagine sotto la pagina, quando le pagine sono più di una.
            static let altezzaFrecce: CGFloat = 30
            /// I popover (correzione a mano, ricerca del cliente): larghi 260, padding 14.
            static let larghezzaPopover: CGFloat = 260
            static let paddingPopover: CGFloat = 14
            /// Spazi piccoli dentro le tile e le righe: 2, 4, 8.
            static let spazioMinimo: CGFloat = 2
            static let spazioStretto: CGFloat = 4
            static let spazioMedio: CGFloat = 8
            /// La zona di rilascio quando non c'è nessun modulo: tratteggio 1,5 (6 5), raggio 20.
            static let trattoRilascio: CGFloat = 1.5
            static let tratteggioRilascio: [CGFloat] = [6, 5]
            static let coloreRilascio = C.inchiostro3
            static let rilascioAttivo = C.accento
            /// La nota per il canale Alleanza (decisione 60).
            static let notaAlleanza = K(dimensione: 12, peso: .regular, interlinea: 1.35)
            /// La revisione della mappa: elenco largo 360, righe con padding 8/10, raggio 12.
            static let colonnaRevisione: CGFloat = 360
            static let rigaRevisione = Tema.Apple.Misura.padding(8, 10)
            static let raggioRiga = Tema.Apple.Raggio.giorno
            static let fondoRiga = C.chip
            static let fondoRigaScelta = C.selezioneVoce
            static let etichettaRiga = K(dimensione: 13, peso: .semibold)
            static let origineRiga = K(dimensione: 11.5, peso: .regular)
            static let coloreDaConfermare = C.arancio
            /// La casella aggiunta a mano (in punti della pagina).
            static let casellaAMano = CGSize(width: 160, height: 20)
            /// Impostazioni › Moduli: il tassello delle righe.
            static let tasselloRiga: CGFloat = 28
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
            /// Un campo del modulo (§7.2.3): a 0,20 + i·0,19 s; fondo, bordo e anello in 0,40 s; il valore si scrive a
            /// 0,016 s per lettera («Lo scrivo io» a 0,020).
            enum Campo {
                static let base = 0.20
                static let passo = 0.19
                static let durataColore = 0.40
                static let lettera = 0.016
                static let letteraAMano = 0.020
                static func ritardo(_ i: Int) -> Double { base + Double(i) * passo }
                static var colore: Animation { Tema.Apple.Moto.Curva.ease.animazione(durataColore) }
            }
            /// Le firme respirano: periodo 2,4 s, scala 1,03, senza alone (si ferma con calma e nelle istantanee).
            enum RespiroFirma {
                static let periodo = 2.4
                static let scala: CGFloat = 1.03
                static var animazione: Animation { .easeInOut(duration: periodo / 2).repeatForever(autoreverses: true) }
            }
            /// Le tile finali: dopo l'ultimo campo (0,30 s), 0,45 s da 10 più in basso, una ogni 0,12 s.
            enum TileFinali {
                static let dopoUltimo = 0.30
                static let durata = 0.45
                static let passo = 0.12
                static let spostamento: CGFloat = 10
                static var animazione: Animation { Tema.Apple.Moto.Curva.uscita.animazione(durata) }
            }
            /// Il cambio di bisogno: la colonna principale esce in 0,14 s verso y +14 (`Moto.CambioCliente`).
            static var cambio: Animation { Tema.Apple.Moto.CambioCliente.uscita }
            static let spostamentoCambio = Tema.Apple.Moto.CambioCliente.spostamento
        }
    }
}
