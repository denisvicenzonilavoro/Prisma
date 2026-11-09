import SwiftUI

// Gettoni di Sala › La realtà aumentata (Design/template-luce-specifica.md §2.3.2, «Luce» giro 16): il palco del Mac
// con la cornice dell'iPad, le sovrapposizioni comuni a Mac, iPad e iPhone (pillole, guida, targhetta, pillole degli
// strati, barra), la colonna del Mac, il cristallo in RealityKit (scala, vetro, camera, tavolo, ombra) e il
// fermo-immagine `CristalloFermo`. Il palco resta chiaro anche con Prisma scuro (il template non lo cambia).
// Misure in pt del palco 1440×900; nessun valore grafico della realtà aumentata fuori da qui.

extension Tema.Apple {
    enum RealtaAumentata {
        typealias C = Tema.Apple.Carattere

        /// 1 unità del cristallo = 0,16 m sul tavolo vero (decisione 107: da provare su un tavolo vero).
        static let metriPerUnita: Float = 0.16

        /// Il fondo del palco: gradiente radiale 900×600 al 40%/40% da #EEF2F5 a #D9E1E7.
        enum Fondo {
            static let centro = Color(hex: "#EEF2F5")
            static let bordo = Color(hex: "#D9E1E7")
            static let punto = UnitPoint(x: 0.4, y: 0.4)
            static let raggio: CGFloat = 900
            /// Lo stesso fondo per RealityKit (sRGB 0…1).
            static let srgb = SIMD3<Float>(0.93, 0.95, 0.96)
        }

        /// La cornice dell'iPad a sinistra del palco.
        enum CorniceiPad {
            static let origine = CGPoint(x: 28, y: 22)
            static let dimensione = CGSize(width: 944, height: 560)
            static let raggio: CGFloat = 42
            static let margine: CGFloat = 15
            static let raggioSchermo: CGFloat = 28
            /// Gradiente a 145° da #2A2D31 a #0B0C0E (al 40%).
            static let fondoInizio = Color(hex: "#2A2D31")
            static let fondoFine = Color(hex: "#0B0C0E")
            static let fermataFondo: CGFloat = 0.4
            static let inizio = UnitPoint(x: 0.1, y: 0)
            static let fine = UnitPoint(x: 0.9, y: 1)
            /// Ombra 0 50 90 −30 rgba(8,30,50,.55): il raggio è dimezzato come nel resto del tema.
            static let ombra = Color(r: 8, g: 30, b: 50, a: 0.55)
            static let raggioOmbra: CGFloat = 45
            static let scostamentoOmbra: CGFloat = 50
            static let rientroOmbra: CGFloat = 30
            /// Il filo interno bianco 0,08.
            static let filo = Color(r: 255, g: 255, b: 255, a: 0.08)
            static let spessoreFilo: CGFloat = 1
            /// La fotocamera frontale: puntino da 5 sul lato sinistro.
            static let fotocamera: CGFloat = 5
            static let coloreFotocamera = Color(hex: "#1C1F23")
            static let schermo = Color(hex: "#000000")
        }

        /// Le pillole in alto («◉ Prisma · AR» e lo stato).
        enum Pillola {
            static let testo = C(dimensione: 12.5, peso: .semibold)
            static let fondo = Color(r: 0, g: 0, b: 0, a: 0.38)
            static let inchiostro = Color(hex: "#FFFFFF")
            static let sfocatura: CGFloat = 18
            static let padding = EdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12)
            static let margine: CGFloat = 16
            static let verde = Color(hex: "#34D399")
        }

        /// La guida al centro: due quadrati arrotondati da 64 che ruotano in prospettiva.
        enum Guida {
            static let lato: CGFloat = 64
            static let raggio: CGFloat = 16
            static let bordo: CGFloat = 3
            static let colore = Color(hex: "#FFFFFF")
            static let secondaOpacita: Double = 0.55
            static let testo = C(dimensione: 15, peso: .semibold)
            static let spazio: CGFloat = 14
            static let inclinazione: Double = 60
            static let giro: Double = 90
            static let salto: CGFloat = 16
        }

        /// La targhetta sopra il cristallo.
        enum Targhetta {
            static let fondo = Color(r: 255, g: 255, b: 255, a: 0.8)
            static let sfocatura: CGFloat = 14
            static let raggio: CGFloat = 14
            static let padding = EdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14)
            static let ombra = Color(r: 8, g: 30, b: 50, a: 0.22)
            static let raggioOmbra: CGFloat = 12
            static let cifra = C(dimensione: 19, peso: .bold, tracking: -0.4, tabellare: true)
            static let inchiostroCifra = Color(hex: "#14202B")
            static let nome = C(dimensione: 11.5, peso: .medium)
            static let inchiostroNome = Color(hex: "#5A6873")
            static let asta = CGSize(width: 1.5, height: 14)
            static let coloreAsta = Color(hex: "#FFFFFF")
            /// Distanza minima dal bordo alto dello schermo.
            static let distanzaAlto: CGFloat = 96
            static let spazio: CGFloat = 1
        }

        /// Le pillole degli strati con «Esploso».
        enum Strato {
            static let fondo = Color(r: 255, g: 255, b: 255, a: 0.82)
            static let sfocatura: CGFloat = 12
            static let pallino: CGFloat = 9
            static let nome = C(dimensione: 12, peso: .bold)
            static let valore = C(dimensione: 12, peso: .regular, tabellare: true)
            static let inchiostro = Color(hex: "#14202B")
            static let inchiostroValore = Color(hex: "#5A6873")
            static let padding = EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 10)
            static let spazio: CGFloat = 6
            static let scostamento = CGSize(width: 18, height: -12)
            /// Lo strato scelto con un tocco: gli altri più trasparenti.
            static let opacitaAltri: Double = 0.35
            /// La pillola si posiziona dal centro: mezza larghezza tipica, così parte accanto allo strato.
            static let mezzaLarghezza: CGFloat = 70
        }

        /// La barra in basso al centro.
        enum Barra {
            static let fondo = Color(r: 0, g: 0, b: 0, a: 0.38)
            static let sfocatura: CGFloat = 18
            static let distanzaFondo: CGFloat = 16
            static let padding = EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 10)
            static let spazio: CGFloat = 14
            static let anno = C(dimensione: 12, peso: .semibold, tabellare: true)
            static let opacitaAnno: Double = 0.75
            static let larghezzaAnno: CGFloat = 42
            static let larghezzaCursore: CGFloat = 220
            static let binario = Color(r: 255, g: 255, b: 255, a: 0.3)
            static let inchiostro = Color(hex: "#FFFFFF")
        }

        /// Il pulsante «Esploso».
        enum Interruttore {
            static let testo = C(dimensione: 12.5, peso: .semibold)
            static let spento = Color(r: 255, g: 255, b: 255, a: 0.14)
            static let acceso = Color(hex: "#FFFFFF")
            static let inchiostroSpento = Color(hex: "#FFFFFF")
            static let inchiostroAcceso = Color(hex: "#14202B")
            static let padding = EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        }

        /// Lo scatto: cerchio bianco 42, anello 3 nero 0,4 e anello 5 bianco 0,85, premuto scala 0,9.
        enum Scatto {
            static let lato: CGFloat = 42
            static let colore = Color(hex: "#FFFFFF")
            static let anelloInterno: CGFloat = 3
            static let coloreAnelloInterno = Color(r: 0, g: 0, b: 0, a: 0.4)
            static let anelloEsterno: CGFloat = 5
            static let coloreAnelloEsterno = Color(r: 255, g: 255, b: 255, a: 0.85)
            static let scalaPremuto: CGFloat = 0.9
            static let opacitaSpento: Double = 0.4
            static let lampo = Color(hex: "#FFFFFF")
        }

        /// Gli avvisi sullo schermo (scatto salvato, fotocamera assente).
        enum Avviso {
            static let testo = C(dimensione: 13, peso: .semibold)
            static let fondo = Color(r: 0, g: 0, b: 0, a: 0.55)
            static let inchiostro = Color(hex: "#FFFFFF")
            static let padding = EdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14)
            static let raggio: CGFloat = 14
            static let larghezza: CGFloat = 420
            static let distanzaBarra: CGFloat = 76
        }

        /// La colonna del Mac, da x 1000 al bordo − 30.
        enum Colonna {
            static let inizio: CGFloat = 1000
            static let margineDestro: CGFloat = 30
            /// Sotto questa larghezza la cornice dell'iPad si rimpicciolisce (palco stretto): scelta di Prisma.
            static let larghezzaMinima: CGFloat = 300
            static let alto: CGFloat = 40
            static let etichetta = C(dimensione: 12, peso: .semibold, tracking: 0.6, maiuscolo: true)
            static let titolo = C(dimensione: 28, peso: .bold, tracking: -0.6, interlinea: 1.15)
            static let testo = C(dimensione: 14, peso: .regular, interlinea: 1.55)
            static let inchiostro = Color(hex: "#14202B")
            static let inchiostro2 = Color(hex: "#5A6873")
            static let separatore = Color(r: 0, g: 0, b: 0, a: 0.08)
            static let spazio: CGFloat = 14
            static let tile = Color(r: 255, g: 255, b: 255, a: 0.72)
            static let raggioTile: CGFloat = 16
            static let paddingTile: CGFloat = 14
            static let spazioTile: CGFloat = 2
            static let cifraTile = C(dimensione: 30, peso: .bold, tracking: -0.6, tabellare: true)
            static let etichettaTile = C(dimensione: 12.5, peso: .regular)
            static let riga = C(dimensione: 13.5, peso: .regular)
            static let rigaForte = C(dimensione: 13.5, peso: .bold, tabellare: true)
            static let paddingRiga: CGFloat = 7
            static let quadratino: CGFloat = 12
            static let raggioQuadratino: CGFloat = 4
            static let nota = C(dimensione: 12.5, peso: .regular)
        }

        /// La riga di conferma delle cifre in testa al palco (decisione 49).
        enum Conferma {
            static let testo = C(dimensione: 13.5, peso: .semibold)
            static let fondo = Color(r: 255, g: 255, b: 255, a: 0.9)
            static let inchiostro = Color(hex: "#14202B")
            static let bordo = Color(r: 0, g: 0, b: 0, a: 0.08)
            static let raggio: CGFloat = 14
            static let padding = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 10)
            static let spazio: CGFloat = 12
            static let larghezza: CGFloat = 640
        }

        /// I colori degli strati: quelli delle classi del prisma di luce (decisione 119).
        enum Strati {
            static let azionario = Tema.Apple.Luce.Raggi.azionario
            static let obbligazionario = Tema.Apple.Luce.Raggi.obbligazionario
            static let gestioneSeparata = Tema.Apple.Luce.Raggi.gestioneSeparata
            static let liquidita = Tema.Apple.Luce.Raggi.liquidita

            static func colore(_ c: ComposizioneInvestimenti360.Classe) -> Color {
                switch c {
                case .azionario: return azionario
                case .obbligazionario: return obbligazionario
                case .gestioneSeparata: return gestioneSeparata
                case .liquidita: return liquidita
                }
            }
        }

        /// Il vetro in RealityKit: i colori delle classi mescolati al 58% verso il bianco, trasparenti.
        enum Vetro {
            static let versoBianco: Float = 0.58
            static let opacita: Float = 0.62
            static let opacitaScelto: Float = 0.7
            static let opacitaAltri: Float = 0.22
            static let ruvidita: Float = 0.05
            static let vernice: Float = 1
            static let ruviditaVernice: Float = 0.02
            /// Il logo inciso: 0,5 mm sopra la faccia alta, largo 0,36 unità.
            static let sopraLogo: Float = 0.003
            static let latoLogo: Float = 0.36
            static let opacitaLogo: Float = 0.55

            /// Il colore dello strato per RealityKit (sRGB 0…1, già mescolato).
            static func mescola(_ c: SIMD3<Float>) -> SIMD3<Float> { c + (SIMD3<Float>(1, 1, 1) - c) * versoBianco }
        }

        /// La camera dell'anteprima (Mac e ripiego): D = 2,9 + 0,75·H + 1,6·e.
        enum Camera {
            static let distanzaBase: Float = 2.9
            static let distanzaAltezza: Float = 0.75
            static let distanzaEsploso: Float = 1.6
            /// Il punto guardato: a metà dell'altezza.
            static let quotaGuardata: Float = 0.5
            static let azimutIniziale: Float = -1.25
            static let azimutFinale: Float = -0.55
            static let elevazione: Float = 0.42
            static let elevazioneMinima: Float = 0.18
            static let elevazioneMassima: Float = 0.85
            /// Trascinamento: 220 pt = 1 radiante in orizzontale, 320 pt in verticale.
            static let puntiPerRadianteOrizzontale: CGFloat = 220
            static let puntiPerRadianteVerticale: CGFloat = 320
            static let campoVisivo: Float = 38
        }

        /// La luce della scena.
        enum Luce {
            static let intensita: Float = 2_600
            static let direzione = SIMD3<Float>(-0.5, -1, -0.35)
            static let ombra: Float = 6
        }

        /// Il tavolo virtuale: 5,2 × 3,1 unità, legno caldo.
        enum Tavolo {
            static let larghezza: Float = 5.2
            static let profondita: Float = 3.1
            static let legnoChiaro = Color(hex: "#C89B6D")
            static let legnoScuro = Color(hex: "#9C6B43")
            static let venatura = Color(r: 90, g: 55, b: 30, a: 0.18)
            static let lato: Int = 512
            static let ruvidita: Float = 0.55
        }

        /// L'ombra colorata dipinta sul tavolo.
        enum Ombra {
            static let lato: Int = 256
            static let opacita: Double = 0.42
            /// Spostata verso la luce (unità).
            static let spostamento = SIMD2<Float>(0.22, 0.12)
            static let allargamento: Float = 1.45
            /// L'immagine dell'ombra è più grande della pianta allargata (sfumatura), a passi di 0,12.
            static let margine: Float = 1.4
            static let passi = 10
            static let alfaPasso: CGFloat = 0.12
        }

        /// I puntini del piano trovato e l'anello della posa.
        enum Puntini {
            static let lato: Float = 0.018
            static let passo: Float = 0.22
            static let quanti = 9
            static let anello: Float = 1.3
            /// La targhetta guarda 0,12 unità sopra la faccia alta.
            static let sopraTarghetta: Float = 0.12
        }

        /// Il fermo-immagine in SwiftUI (`CristalloFermo`): assonometria del prisma triangolare.
        enum Fermo {
            /// Punti per unità del cristallo nel fermo-immagine (rispetto al lato corto dell'area).
            static let quotaScala: CGFloat = 0.26
            /// La targhetta guarda un po' verso il fondo della faccia alta, le pillole accanto al lato destro.
            static let quotaTarghetta: Float = 0.2
            static let quotaPillole: Float = 0.85
            /// Il logo schiacciato come la faccia alta.
            static let schiacciamentoLogo: CGFloat = 1.6
            /// Le luci a bolle della stanza.
            static let quanteBolle = 6
            static let bollaX: CGFloat = 0.12
            static let bollaPassoX: CGFloat = 0.16
            static let bollaY: CGFloat = 0.14
            static let bollaPassoY: CGFloat = 0.09
            static let bollaLato: CGFloat = 0.10
            static let bollaPassoLato: CGFloat = 0.03
            /// Lo schiacciamento verticale della pianta (assonometria) e l'angolo di vista.
            static let schiacciamento: CGFloat = 0.42
            static let rotazione: Double = -0.55
            /// Le facce laterali più scure e la faccia alta più chiara.
            static let scuroFacce: Double = 0.18
            static let chiaroAlto: Double = 0.22
            static let opacitaFacce: Double = 0.86
            static let bordo = Color(r: 255, g: 255, b: 255, a: 0.7)
            static let spessoreBordo: CGFloat = 0.8
            static let ombra = Color(r: 20, g: 40, b: 60, a: 0.28)
            static let quotaOmbra: CGFloat = 1.6
            static let logo: CGFloat = 0.34
            static let coloreLogo = Color(r: 15, g: 36, b: 51, a: 0.55)
            /// La scena del fermo-immagine: la stanza calda sfocata.
            static let stanzaAlto = Color(hex: "#3B2F2A")
            static let stanzaBasso = Color(hex: "#6E5547")
            static let bolle = [Color(r: 255, g: 210, b: 150, a: 0.35), Color(r: 255, g: 235, b: 200, a: 0.25),
                                Color(r: 250, g: 190, b: 120, a: 0.3)]
            /// Il tavolo comincia al 52% dell'altezza.
            static let orizzonte: CGFloat = 0.52
            static let neutro = Color(hex: "#FFFFFF")
            /// Il centro del cristallo nello schermo (frazioni) e l'altezza della targhetta sopra.
            static let centro = CGPoint(x: 0.5, y: 0.66)
        }

        /// Il palco dell'iPhone e dell'iPad (Sala › La realtà aumentata): anteprima ferma, classi e pulsante.
        enum Mobile {
            static let altezzaAnteprima: CGFloat = 280
            static let raggioAnteprima: CGFloat = 22
            static let spazio: CGFloat = 14
            static let margine: CGFloat = 20
        }

        /// Il foglio dello scatto nel dossier (A4, su carta bianca).
        enum Foglio {
            static let formato = CGSize(width: 595, height: 842)
            static let margine: CGFloat = 48
            static let titolo = C(dimensione: 20, peso: .bold, tracking: -0.3)
            static let riga = C(dimensione: 11, peso: .regular, tabellare: true)
            static let nota = C(dimensione: 9.5, peso: .regular)
            static let inchiostro = Color(hex: "#14202B")
            static let inchiostro2 = Color(hex: "#5A6873")
            static let filo = Color(hex: "#E2E8EE")
            static let altezzaImmagine: CGFloat = 420
            static let lato: CGFloat = 1_200
            static let spazio: CGFloat = 18
            static let spazioRiga: CGFloat = 8
            static let quadratino: CGFloat = 10
            static let raggioQuadratino: CGFloat = 3
            static let paddingRiga: CGFloat = 6
            static let larghezzaValore: CGFloat = 90
        }
    }
}

extension Tema.Apple.Moto {
    /// Il movimento della realtà aumentata (§2.3.3). Le animazioni della scena RealityKit si guidano con
    /// `SceneEvents.Update` (il tempo del fotogramma), mai con un Timer; le sovrapposizioni sono animazioni di SwiftUI.
    enum RealtaAumentata {
        /// La panoramica dell'apertura (solo anteprima e ripiego): 2,2 s, azimut da −1,25 a −0,55, dentro-fuori.
        static let panoramica = 2.2
        /// I puntini del piano trovato: entrano a 1,2 s in 0,6 s, escono a 2,6 s in 0,5 s.
        static let puntiniInizio = 1.2
        static let puntiniEntrata = 0.6
        static let puntiniFine = 2.6
        static let puntiniUscita = 0.5
        /// La guida svanisce in 0,5 s al primo piano trovato.
        static let guidaUscita = 0.5
        /// La guida: un giro in 2 s, il secondo quadrato sfasato di 1 s.
        static let guida = 2.0
        static let guidaSfasamento = 1.0
        /// L'anello della posa: 1,1 s.
        static let anelloPosa = 1.1
        /// La targhetta: 3,4 s dall'apertura (o 0,8 dopo la posa), in 0,6 s.
        static let targhettaRitardo = 3.4
        static let targhettaDopoPosa = 0.8
        static let targhettaDurata = 0.6
        /// L'orbita lenta: 0,05 rad/s dopo 4 s senza trascinamento (solo anteprima e ripiego).
        static let orbita = 0.05
        static let orbitaDopo = 4.0
        /// Gli inseguimenti: la camera a 5/s, la forma (anno, esploso) a 6/s.
        static let inseguimentoCamera = 5.0
        static let inseguimentoForma = 6.0
        /// Le pillole degli strati in 0,4 s.
        static let pilloleStrati = 0.4
        /// Il lampo dello scatto: decadimento 9/s (durata visibile circa 0,45 s).
        static let lampo = 0.45
        /// La cifra contata in 500 ms.
        static let cifra = 0.5
        /// Lo scatto premuto: scala 0,9 in 0,2 s.
        static let scattoPremuto = 0.2
        /// Il rimbalzo delle pillole in SwiftUI.
        static let molla = Molla(risposta: 0.58, smorzamento: 0.56)
        /// Con «Riduci movimento»: il cristallo intero con una dissolvenza di 0,15 s.
        static let calmo = 0.15
    }
}
