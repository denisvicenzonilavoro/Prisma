import SwiftUI

// Gettoni della capsula del tempo (Sala, «Luce» giro 15, Design/template-luce-specifica.md §3.4.2 e §3.4.3). Misure in pt
// del palco 1440×900. La busta e il foglio restano chiari anche nello scuro (colori fissi); le colonne seguono il tema.

extension Tema.Apple.SalaRacconti {
    enum Capsula {
        typealias C = Tema.Apple.Carattere

        /// #9B6FB5: chip scelto, sigillo, lampo della riga nuova (la tinta del glifo della capsula).
        static let colore = Tema.Apple.Colore.Glifi.capsula
        /// Il sigillo della capsula pronta e la tile «pronta».
        static let coloreSigilloPronta = Tema.Apple.Colore.arancio

        // MARK: Colonne

        /// La colonna di sinistra a 28/24, larga 560, fino a 24 dal fondo; quella di destra da 620 a 28 dal bordo.
        static let sinistra: CGFloat = 28
        static let alto: CGFloat = 24
        static let larghezzaSinistra: CGFloat = 560
        static let inizioDestra: CGFloat = 620
        static let margineDestro: CGFloat = 28
        static let basso: CGFloat = 24

        static let titolo = C(dimensione: 26, peso: .bold, tracking: -0.5, interlinea: 1.2)
        static let coloreTitolo = Tema.Apple.Colore.inchiostro
        static let frase = C(dimensione: 14, peso: .regular, interlinea: 1.5)
        static let coloreFrase = Tema.Apple.Colore.inchiostro2
        static let sottoTitolo: CGFloat = 6
        static let sopraCampo: CGFloat = 14

        // MARK: Campo

        /// Alto al più 230 (almeno 150), raggio 16, padding 16, serif 17 con interlinea 1,6.
        static let altezzaCampo: CGFloat = 230
        static let altezzaMinimaCampo: CGFloat = 150
        static let raggioCampo: CGFloat = 16
        static let paddingCampo: CGFloat = 16
        static let testoCampo = C(dimensione: 17, peso: .regular, interlinea: 1.6, disegno: .serif)
        static let fondoCampo = Tema.Apple.Colore.cardPiena
        static let bordoCampo = Tema.Apple.Colore.separatore
        static let spessoreBordo: CGFloat = 1
        static let coloreTestoCampo = Tema.Apple.Colore.inchiostro
        static let coloreSegnaposto = Tema.Apple.Colore.inchiostro3
        static let aiuto = Tema.Apple.Carattere.secondario
        static let coloreAiuto = Tema.Apple.Colore.inchiostro3
        static let sopraAiuto: CGFloat = 6

        // MARK: «Si apre quando»

        static let etichetta = Tema.Apple.Carattere.etichetta
        static let coloreEtichetta = Tema.Apple.Colore.inchiostro2
        static let sopraEtichetta: CGFloat = 14
        static let sottoEtichetta: CGFloat = 8
        /// Le chip: 13 semibold, spazio 8; scelta = fondo viola e testo bianco, senza bordo (`.chip.on2`).
        static let chip = C(dimensione: 13, peso: .semibold)
        static let paddingChip = EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        static let fondoChip = Tema.Apple.Colore.cardPiena
        static let bordoChip = Tema.Apple.Colore.separatore
        static let testoChip = Tema.Apple.Colore.inchiostro
        static let testoChipScelto = Color.white
        static let spazioChip: CGFloat = 8
        static let sopraPulsante: CGFloat = 16
        static let nota = Tema.Apple.Carattere.secondario
        static let coloreNota = Tema.Apple.Colore.inchiostro2

        // MARK: Elenco

        static let sottoEtichettaElenco: CGFloat = 10
        /// La tile «pronta»: bordo arancio a 0,45, fondo a 0,08, alone di 6 a 0,15 (pulsazione), avatar 44.
        static let opacitaBordoPronta: Double = 0.45
        static let opacitaFondoPronta: Double = 0.08
        static let opacitaAlonePronta: Double = 0.15
        static let alonePronta: CGFloat = 6
        static let spessoreBordoPronta: CGFloat = 1
        static let raggioPronta = Tema.Apple.Raggio.tile
        static let paddingPronta: CGFloat = 16
        static let avatarPronta: CGFloat = 44
        static let nomePronta = C(dimensione: 15, peso: .bold)
        static let perchePronta = C(dimensione: 13, peso: .semibold)
        static let colorePerchePronta = Tema.Apple.Carta.ambra
        static let spazioPronta: CGFloat = 12
        static let sottoPronta: CGFloat = 12
        /// Le righe: padding 12/4, spazio 12, avatar 36, lucchetto 18 (`lock.fill`), filetto `separatore`.
        static let rigaVerticale: CGFloat = 12
        static let rigaOrizzontale: CGFloat = 4
        static let spazioRiga: CGFloat = 12
        static let avatarRiga: CGFloat = 36
        static let nomeRiga = C(dimensione: 14, peso: .bold)
        static let coloreNomeRiga = Tema.Apple.Colore.inchiostro
        static let dettaglioRiga = Tema.Apple.Carattere.secondario
        static let coloreDettaglioRiga = Tema.Apple.Colore.inchiostro2
        static let coloreAvvisoRiga = Tema.Apple.Colore.arancio
        static let lucchetto: CGFloat = 18
        static let coloreLucchetto = Tema.Apple.Colore.inchiostro2
        static let filetto = Tema.Apple.Colore.separatore
        static let spessoreFiletto: CGFloat = 1
        /// Il lampo viola della riga appena sigillata.
        static let opacitaLampo: Double = 0.25
        static let raggioLampo = Tema.Apple.Raggio.giorno
        static let spostamentoRigaNuova: CGFloat = -16

        // MARK: Busta e sigillo (colori fissi, chiari anche nello scuro)

        static let busta = CGSize(width: 300, height: 200)
        static let cartaBusta = Color(hex: "#F6EFE4")
        static let bordoBusta = Color(hex: "#D9CBB6")
        static let lembo = Color(hex: "#EFE4D3")
        static let spessoreBordoBusta: CGFloat = 2
        static let raggioBusta: CGFloat = 10
        /// Il lembo: un triangolo alto metà della busta.
        static let altezzaLembo: CGFloat = 0.55
        /// La busta del sigillo a 130/150 nella colonna di sinistra.
        static let bustaSinistra: CGFloat = 130
        static let bustaAlto: CGFloat = 150
        /// Il volo del testo verso la busta (+100, +140, scala 0,25) e il volo della busta verso l'elenco (+640, +120, 0,15).
        static let voloTesto = CGSize(width: 100, height: 140)
        static let scalaVoloTesto: CGFloat = 0.25
        static let voloBusta = CGSize(width: 640, height: 120)
        static let scalaVoloBusta: CGFloat = 0.15
        static let scalaEntrataBusta: CGFloat = 0.8
        /// Il sigillo: raggio 26, logo bianco di 32 (spicchi 1 / 0,7 / 0,45).
        static let raggioSigillo: CGFloat = 26
        static let logoSigillo: CGFloat = 32
        static let coloreLogoSigillo = Color.white

        // MARK: Apertura

        /// Il velo su tutto il palco con la sfocatura 10; al centro 520×460.
        static let velo = Tema.Apple.Colore.velo
        static let sfocaturaVelo: CGFloat = 10
        static let palcoApertura = CGSize(width: 520, height: 460)
        /// La lettera sale da +60 a −120 rispetto alla busta.
        static let partenzaLettera: CGFloat = 60
        static let arrivoLettera: CGFloat = -120
        /// Il sigillo che si rompe: scala 1 → 1,3.
        static let scalaRottura: CGFloat = 1.3
        /// Il foglio: largo 400, alto almeno 230, padding 26/30, raggio 6, l'ombra del foglio della lettera.
        static let larghezzaFoglio: CGFloat = 400
        static let altezzaFoglio: CGFloat = 230
        static let paddingFoglio = EdgeInsets(top: 26, leading: 30, bottom: 26, trailing: 30)
        static let raggioFoglio: CGFloat = 6
        static let ombraFoglio = Tema.Apple.Ombra.foglioLettera
        static let cartaFoglio = Tema.Apple.SalaRacconti.Lettera.carta
        static let inchiostroFoglio = Tema.Apple.SalaRacconti.Lettera.inchiostro
        static let coloreSopratitolo = Tema.Apple.SalaRacconti.Lettera.sopratitolo
        static let sopratitolo = C(dimensione: 11, peso: .bold, tracking: 1.4)
        static let sottoSopratitolo: CGFloat = 10
        static let testoFoglio = C(dimensione: 17, peso: .regular, interlinea: 1.6, disegno: .serif)
        static let altezzaMassimaTesto: CGFloat = 520
        /// I pulsanti a 40 dal fondo, 10 fra l'uno e l'altro.
        static let pulsantiFondo: CGFloat = 40
        static let spazioPulsanti: CGFloat = 10
        static let sottoFoglio: CGFloat = 22
        static let aiutoChiave = Tema.Apple.Carattere.secondario

        // MARK: Stati vuoti

        static let nessuna = Tema.Apple.Carattere.secondario
        static let coloreNessuna = Tema.Apple.Colore.inchiostro2

        // MARK: Pagina PDF (carta bianca)

        static let sopratitoloCarta = C(dimensione: 11, peso: .bold, tracking: 1.4)
        static let coloreSopratitoloCarta = Tema.Apple.Carta.etichetta
        static let testoCarta = C(dimensione: 15, peso: .regular, interlinea: 1.6, disegno: .serif)
        static let coloreTestoCarta = Tema.Apple.Carta.testoCorrente
        static let nomeCarta = C(dimensione: 20, peso: .bold, disegno: .serif)
        static let coloreNomeCarta = Tema.Apple.Carta.testo
        static let piedeCarta = C(dimensione: 10.5, peso: .regular)
        static let colorePiedeCarta = Tema.Apple.Carta.piede
        static let filettoCarta = Tema.Apple.Carta.filetto
        static let spazioCarta: CGFloat = 18

        // MARK: Dossier › Obiettivi

        static let segnoDossier = C(dimensione: 11, peso: .semibold)
        static let coloreSegnoDossier = colore
        static let paddingSegnoDossier = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let fondoSegnoDossier: Double = 0.12
        static let margineSegnoDossier: CGFloat = 12
        static let spazioSegnoDossier: CGFloat = 4

        // MARK: Tile del traguardo

        /// Viola: bordo `Glifi.capsula` a 0,45, fondo a 0,08.
        static let opacitaBordoTraguardo: Double = 0.45
        static let opacitaFondoTraguardo: Double = 0.08
        static let paddingTraguardo: CGFloat = 14
        static let raggioTraguardo = Tema.Apple.Raggio.tile
        static let titoloTraguardo = C(dimensione: 14, peso: .bold)
        static let percheTraguardo = Tema.Apple.Carattere.secondario
        static let spazioTraguardo: CGFloat = 8
    }
}

extension Tema.Apple.Moto {
    /// La capsula del tempo (§3.4.3): i tempi dal clic su «Sigilla» e su «Apri e consegna».
    enum Capsula {
        static let voloTesto = 0.80
        static let curvaVoloTesto = Tema.Apple.Moto.Curva.finestraChiude
        static let entrataBusta = 0.40
        static let ritardoBusta = 0.50
        static let lembo = 0.60
        static let ritardoLembo = 0.90
        static let curvaLembo = Tema.Apple.Moto.Curva.backup
        static let sigillo = 0.52
        static let ritardoSigillo = 1.50
        static let scalaSigillo: CGFloat = 2.2
        static let sigilloMolla = Tema.Apple.Moto.Molla(risposta: 0.52, smorzamento: 0.55)
        static let voloBusta = 0.70
        static let ritardoVolo = 2.30
        static let rigaNuova = 0.90
        static let ritardoRiga = 2.95
        static let curvaRiga = Tema.Apple.Moto.Curva.uscita
        /// Aprire: velo 0,30; il sigillo si rompe a 0,40 (0,40); il lembo si apre a 0,70 (0,60); la lettera sale a 1,20
        /// (0,90); la busta svanisce a 1,70 (0,60); il testo si scrive da 2,10, una parola ogni 0,04 s.
        static let velo = 0.30
        static let ritardoRottura = 0.40
        static let rottura = 0.40
        static let ritardoLemboApre = 0.70
        static let ritardoLettera = 1.20
        static let lettera = 0.90
        static let ritardoSvanisce = 1.70
        static let svanisce = 0.60
        static let ritardoTesto = 2.10
        static let passoParola = 0.04
        /// Chiudere: dissolvenza 0,25 (non `Moto.Sala.durataChiusura`, che è della presentazione).
        static let chiusura = 0.25
        /// La tile «pronta» pulsa in 2,2 s all'infinito.
        static let pulsazione = 2.2
    }
}
