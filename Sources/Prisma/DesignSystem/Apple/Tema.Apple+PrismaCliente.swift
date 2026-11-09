import SwiftUI

// Il Prisma del cliente («Luce» giro 15, Design/template-luce-specifica.md §2.1.2 e §2.1.3): le misure del palco (il
// telefono appoggiato a sinistra, la colonna della preparazione a destra), della mini-app dentro il telefono (i colori
// sono in `Tema.Apple.MiniCliente`, fissi e chiari) e delle pagine del PDF protetto, più i tempi del movimento.

extension Tema.Apple {
    enum PrismaCliente {
        typealias K = Tema.Apple.Carattere
        typealias C = Tema.Apple.Colore

        // MARK: La colonna della preparazione

        /// «Il suo piano, in un file protetto.» (display 30, 700, −0,7).
        static let titolo = K(dimensione: 30, peso: .bold, tracking: -0.7)
        static let coloreTitolo = C.inchiostro
        /// Il testo introduttivo (14,5, interlinea 1,55, `--ink2`, al più 540).
        static let introduzione = K(dimensione: 14.5, peso: .regular, interlinea: 1.55)
        static let coloreIntroduzione = C.inchiostro2
        static let larghezzaTesto: CGFloat = 540
        static let sottoTitolo: CGFloat = 10
        /// «COSA C'È DENTRO» (22 sopra, 4 sotto).
        static let etichetta = K.etichetta
        static let coloreEtichetta = C.inchiostro2
        static let sopraEtichetta: CGFloat = 22
        static let sottoEtichetta: CGFloat = 4
        /// Le righe dei contenuti (14,5, padding 10/0, filo `--sep`).
        static let riga = K(dimensione: 14.5, peso: .regular)
        static let coloreRiga = C.inchiostro
        static let coloreRigaSpenta = C.inchiostro3
        static let paddingRiga: CGFloat = 10
        static let filo = C.separatore
        static let spessoreFilo: CGFloat = 1
        /// Il motivo sotto una voce spenta (`.k`) e il suo collegamento.
        static let motivo = K.secondario
        static let coloreMotivo = C.inchiostro2
        static let sopraMotivo: CGFloat = 3
        /// «nuova dall'ultimo file».
        static let nuova = K(dimensione: 11, peso: .semibold)
        static let coloreNuova = C.accento
        static let fondoNuova = C.selezioneVoce
        static let paddingNuova = EdgeInsets(top: 2, leading: 7, bottom: 2, trailing: 7)
        /// Le note sotto le voci e in fondo alla colonna stretta (`.k`, interlinea 1,45).
        static let nota = K(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let coloreNota = C.inchiostro2
        static let coloreAvviso = C.scadenza
        static let sopraNote: CGFloat = 14
        static let spazioNote: CGFloat = 6

        // MARK: La colonna stretta (tile e pulsanti)

        static let larghezzaColonna: CGFloat = 290
        static let spazioColonna: CGFloat = 10
        static let spazioColonne: CGFloat = 26
        static let margine = EdgeInsets(top: 30, leading: 30, bottom: 24, trailing: 30)
        static let tile = Superficie.tile
        static let raggioTile = Raggio.tile
        static let paddingTile = Misura.Padding.tile
        static let titoloTile = K.secondario
        static let coloreTitoloTile = C.inchiostro2
        static let spazioTile: CGFloat = 6
        /// La password nascosta o mostrata (18, grassetto, spaziatura 2, cifre tabellari).
        static let password = K(dimensione: 18, peso: .bold, tracking: 2, tabellare: true)
        static let colorePassword = C.inchiostro
        static let campoPassword = K(dimensione: 14, peso: .medium, tabellare: true)
        static let puntini = "••••••••••"
        /// La data di scadenza (16, grassetto).
        static let scadenza = K(dimensione: 16, peso: .bold)
        static let coloreScadenza = C.inchiostro
        /// Il file pronto: bordo verde a 0,4.
        static let bordoPronto = C.verde.opacity(0.4)
        static let spessoreBordoPronto: CGFloat = 1.5
        static let testoPronto = K(dimensione: 13, peso: .bold)
        static let coloreTestoPronto = C.verde
        static let coloreErrore = C.rosso
        /// La barra della preparazione (alta 8, raggio 9, blu).
        static let barra = C.accento
        static let altezzaBarra: CGFloat = 8
        static let raggioBarra: CGFloat = 9

        // MARK: Il telefono nel palco

        static let scalaTelefono: CGFloat = 0.92
        /// In alto a sinistra, a x 44 e y −8: il bordo alto esce un poco dal palco («il telefono è appoggiato»).
        static let posizioneTelefono = CGPoint(x: 44, y: -8)
        /// La zona del telefono: 300 × 0,92 più la posizione e un respiro.
        static let larghezzaZonaTelefono: CGFloat = 300 * 0.92 + 44 + 16
        /// Sulla sala opaca della presentazione il telefono sta al centro, intero.
        static let scalaTelefonoSala: CGFloat = 1

        /// I colori dei canali nel file (sempre chiaro: le varianti chiare di `Colore.canaleAlleanza/Indipendente`).
        static let canaleAlleanzaHex = "#2563EB"
        static let canaleIndipendenteHex = "#B06E12"

        // MARK: La mini-app (dentro il telefono)

        enum Mini {
            typealias K = Tema.Apple.Carattere
            static let altezzaTestata: CGFloat = 210
            /// La testata a 165°: da in alto a sinistra verso in basso a destra, quasi verticale.
            static let inizioTestata = UnitPoint(x: 0.37, y: 0)
            static let fineTestata = UnitPoint(x: 0.63, y: 1)
            static let onda: CGFloat = 60
            static let bordoOnda: CGFloat = 2
            static let coloreOnda = Color(r: 255, g: 255, b: 255, a: 0.8)
            static let centriOnde: [CGPoint] = [CGPoint(x: 60, y: 80), CGPoint(x: 190, y: 60), CGPoint(x: 120, y: 140)]
            static let logo: CGFloat = 22
            static let posizioneLogo = CGPoint(x: 20, y: 58)
            /// «IL PRISMA DI» (11, 700, spaziatura 1, opacità 0,6) e il nome (display 34, 700, −0,8).
            static let sopraNome = K(dimensione: 11, peso: .bold, tracking: 1, maiuscolo: true)
            static let opacitaSopraNome = 0.6
            static let nome = K(dimensione: 34, peso: .bold, tracking: -0.8)
            static let margineNome: CGFloat = 20
            static let fondoNome: CGFloat = 18
            /// Le card: bianche, raggio 16, padding 12/14, spazio 10, ombra 0 8 18 −12 nero 0,25.
            static let raggioCard: CGFloat = 16
            static let paddingCard = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            static let spazioCard: CGFloat = 10
            static let ombraCard = Color(r: 0, g: 0, b: 0, a: 0.12)
            static let raggioOmbraCard: CGFloat = 9
            static let yOmbraCard: CGFloat = 6
            static let margineCards: CGFloat = 14
            static let spazioCards: CGFloat = 12
            /// L'occhiello delle card (11, 700, spaziatura 0,5).
            static let occhiello = K(dimensione: 11, peso: .bold, tracking: 0.5, maiuscolo: true)
            /// Gli anelli (60, spessore 7) con il nome sotto (10, interlinea 1,2, larghezza 72).
            static let anello: CGFloat = 60
            static let spessoreAnello: CGFloat = 7
            static let larghezzaEtichettaAnello: CGFloat = 72
            static let etichettaAnello = K(dimensione: 10, peso: .regular, interlinea: 1.2)
            static let binarioAnello = Color(r: 20, g: 32, b: 43, a: 0.08)
            static let fraseObiettivo = K(dimensione: 11.5, peso: .semibold)
            /// «67 anni» (display 24, grassetto) e la frase (11,5).
            static let eta = K(dimensione: 24, peso: .bold, tabellare: true)
            static let frase = K(dimensione: 11.5, peso: .semibold)
            static let fraseIndicativa = K(dimensione: 10.5, peso: .regular)
            /// Il grafico 232×60: area a 0,15, linea 2,2, filo tratteggiato [2, 3].
            static let grafico = CGSize(width: 232, height: 60)
            static let spessoreLinea: CGFloat = 2.2
            static let opacitaArea = 0.15
            static let tratteggio: [CGFloat] = [2, 3]
            static let spessoreFiloEta: CGFloat = 1
            /// La lettera: quadrato 38 raggio 10; il film: cerchio 38 bianco a 0,15.
            static let quadrato: CGFloat = 38
            static let raggioQuadrato: CGFloat = 10
            static let cerchioFilm = Color(r: 255, g: 255, b: 255, a: 0.15)
            static let testoFilm = Color(hex: "#FFFFFF")
            static let opacitaSottoFilm = 0.65
            static let titoloCard = K(dimensione: 13, peso: .bold)
            static let sottoCard = K(dimensione: 11, peso: .regular)
            static let glifo = K(dimensione: 15, peso: .semibold)
            static let freccia = K(dimensione: 17, peso: .semibold)
            /// Il prisma di luce e la giornata come immagini ferme (altezza nella card).
            static let altezzaImmagine: CGFloat = 130
            static let raggioImmagine: CGFloat = 10
            /// Il sinistro: cerchi delle fasi 12.
            static let fase: CGFloat = 12
            static let etichettaFase = K(dimensione: 11, peso: .medium)
            /// Le posizioni: nome, canale e valore.
            static let valore = K(dimensione: 13, peso: .semibold, tabellare: true)
            static let canale = K(dimensione: 10.5, peso: .semibold)
            /// Il piede (10, centrato, margini 14/6/24).
            static let piede = K(dimensione: 10, peso: .regular, interlinea: 1.35)
            static let marginePiede = EdgeInsets(top: 14, leading: 6, bottom: 24, trailing: 6)
            static let datiDiProva = K(dimensione: 9.5, peso: .bold, tracking: 0.8, maiuscolo: true)
        }

        // MARK: Le pagine del PDF protetto (A4 verticale, carta bianca)

        enum Pagina {
            typealias K = Tema.Apple.Carattere
            static let margine: CGFloat = 44
            static let sopratitolo = K(dimensione: 10, peso: .bold, tracking: 0.8, maiuscolo: true)
            static let titolo = K(dimensione: 30, peso: .bold, tracking: -0.6)
            static let sottotitolo = K(dimensione: 13, peso: .regular)
            static let titoloSezione = K(dimensione: 17, peso: .bold, tracking: -0.2)
            static let testo = K(dimensione: 12, peso: .regular, interlinea: 1.45)
            static let riga = K(dimensione: 12.5, peso: .regular)
            static let rigaForte = K(dimensione: 12.5, peso: .semibold, tabellare: true)
            static let piede = K(dimensione: 9, peso: .regular, interlinea: 1.35)
            static let anello: CGFloat = 76
            static let spessoreAnello: CGFloat = 8
            static let larghezzaEtichettaAnello: CGFloat = 110
            static let spazio: CGFloat = 16
            static let spazioRighe: CGFloat = 9
            static let paddingRiga: CGFloat = 8
            static let logo: CGFloat = 16
            static let altezzaImmagine: CGFloat = 300
            static let raggioImmagine: CGFloat = 6
            static let fase: CGFloat = 12
        }
    }
}

extension Tema.Apple.Moto {
    /// Il movimento del Prisma del cliente (§2.1.3).
    enum PrismaCliente {
        /// Il nome che si scrive: una lettera ogni 0,11 s (vista `Animatable`, niente Timer).
        static let lettera = 0.11
        /// Le onde della testata: 3,3 s, scala 0,2→2,6, opacità 0,9→0, sfasate di 1,1 s; ferme (calmo) a 0,35.
        enum Onda {
            static let durata = 3.3
            static let scalaDa: CGFloat = 0.2
            static let scalaA: CGFloat = 2.6
            static let opacitaDa = 0.9
            static let sfasamento = 1.1
            static let opacitaFerma = 0.35
            /// Istantanee: ferme a metà del loro giro.
            static let scalaFerma: CGFloat = 1.4
        }
        /// La tile «file pronto»: 0,42 s, scala 0,9→1, con la molla.
        enum FilePronto {
            static let durata = 0.42
            static let scala: CGFloat = 0.9
        }
        /// L'ultimo tratto della barra (curva `backup`, la «standard» della specifica).
        static let barra = 0.30
        /// Le card che entrano o escono dal telefono quando cambia una voce.
        static let card = 0.32
    }
}
