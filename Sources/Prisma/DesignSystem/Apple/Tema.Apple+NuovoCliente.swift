import SwiftUI

// «Nuovo cliente in 10 secondi» (Design/template-luce-specifica.md §9.1.2, §9.1.3, «Luce» giro 13): misure, caratteri,
// colori e tempi della scena del Mac (carta d'identità fac-simile sul telefono disegnato, scheda «Prisma sul Mac» con il
// contatore e le cinque righe, tile dei moduli) e della schermata dell'iPhone. Riusa i valori di `Tema.Apple.Inquadra`
// dove coincidono. Le viste stanno in Shell/ScenaNuovoCliente.swift, DesignSystem/Apple/CartaIdentitaDisegnata.swift e
// iOS/CartaIdentitaTelefono.swift; qui solo i valori. La carta è carta: sempre chiara, anche in scuro.

extension Tema.Apple {
    enum NuovoCliente {
        typealias C = Tema.Apple.Carattere
        typealias K = Tema.Apple.Colore

        enum Disposizione {
            /// Telefono a 280 e scheda a 680 nel palco: 100 fra i due, la scheda 30 più in basso del telefono.
            static let spazio: CGFloat = 100
            static let scartoScheda: CGFloat = 30
        }

        // MARK: La carta fac-simile sul telefono

        enum Carta {
            /// A 20 dai lati dello schermo, 150 dall'alto, raggio 10, padding 12, ruotata di +2°.
            static let lati: CGFloat = 20
            static let dallAlto: CGFloat = 150
            static let raggio: CGFloat = 10
            static let padding: CGFloat = 12
            static let rotazione: Double = 2
            /// Sfumatura a 135° da #EDF1F4 a #D2DDE5.
            static let fondo = [Color(hex: "#EDF1F4"), Color(hex: "#D2DDE5")]
            static let ombra = Tema.Apple.Inquadra.Foglio.ombra
            static let ombraRaggio = Tema.Apple.Inquadra.Foglio.ombraRaggio
            static let ombraY = Tema.Apple.Inquadra.Foglio.ombraY
            /// «CARTA D'IDENTITÀ» 8,5 bold spaziatura 0,8; «FAC-SIMILE» 7 spaziatura 0,5.
            static let intestazione = C(dimensione: 8.5, peso: .bold, tracking: 0.8, maiuscolo: true)
            static let facSimile = C(dimensione: 7, peso: .regular, tracking: 0.5, maiuscolo: true)
            static let spazioTesta: CGFloat = 8
            /// La foto 62×80, raggio 6, #BCC9D2 con la sagoma #7E909D.
            static let foto = CGSize(width: 62, height: 80)
            static let raggioFoto: CGFloat = 6
            static let fondoFoto = Color(hex: "#BCC9D2")
            static let sagoma = Color(hex: "#7E909D")
            /// La testa della sagoma è un cerchio largo il 42% della foto, a un terzo dall'alto; le spalle un'ellisse in basso.
            static let testaSagoma: CGFloat = 0.42
            static let spalleSagoma = CGSize(width: 0.9, height: 0.5)
            static let spazioFoto: CGFloat = 10
            /// I campi: etichetta 6,5 maiuscola #5A6873 sopra, valore 10 bold #1B2530, padding 2/4, raggio 4.
            static let etichettaCampo = C(dimensione: 6.5, peso: .regular, tracking: 0.4, maiuscolo: true)
            static let valoreCampo = C(dimensione: 10, peso: .bold, tracking: 0.3)
            static let paddingCampo = Tema.Apple.Misura.padding(2, 4)
            static let raggioCampo: CGFloat = 4
            static let spazioCampi: CGFloat = 1
            static let fiscaleSopra: CGFloat = 6
            /// Il campo letto: anello 1,5 verde e fondo verde al 14% (Inquadra usa 2).
            static let contornoLetto: CGFloat = 1.5
            static let coloreLetto = Tema.Apple.Inquadra.verdeLettura
            static let fondoLetto = Tema.Apple.Inquadra.Foglio.fondoLetto
            /// La zona a lettura ottica: monospazio 7,5, spaziatura 0,8, interlinea 1,4, #33424D.
            static let mrz = C(dimensione: 7.5, peso: .regular, tracking: 0.8, interlinea: 1.4, disegno: .monospaced)
            static let mrzSopra: CGFloat = 8
            static let inchiostroForte = Tema.Apple.Inquadra.Foglio.inchiostroForte
            static let inchiostroEtichetta = Tema.Apple.Carta.etichetta
            static let inchiostroMrz = Tema.Apple.Carta.testoCorrente
        }

        // MARK: La scheda «Prisma sul Mac»

        enum Scheda {
            static let larghezza: CGFloat = 480
            /// Avatar 56 con le iniziali 19 bianche, all'inizio opaco al 25%.
            static let avatar = Tema.Apple.Misura.Avatar.dossier
            static let avatarSpento: Double = 0.25
            static let rigaClienteSopra: CGFloat = 14
            static let spazioCliente: CGFloat = 14
            /// Nome: display 24 bold; contatore: display 24 bold, cifre tabellari.
            static let nome = C(dimensione: 24, peso: .bold, tracking: -0.4)
            static let coloreNome = K.inchiostro
            static let sottotitolo = C.secondario
            static let coloreSottotitolo = K.inchiostro2
            static let secondi = C(dimensione: 24, peso: .bold, tabellare: true)
            static let etichettaSecondi = C.secondario
            /// Fra il nome e il sottotitolo, fra «secondi» e il contatore.
            static let spazioNome: CGFloat = 2
            /// La zona dove trascinare: aria ai lati del testo.
            static let paddingZona: CGFloat = 12
            /// Le righe: 12 sopra, etichetta larga 140 (Inquadra 150), spunta verde, «—» grigio, «!» arancio.
            static let righeSopra: CGFloat = 12
            static let larghezzaEtichetta: CGFloat = 140
            static let coloreDaGuardare = K.arancio
            static let coloreMancante = Tema.Apple.Inquadra.Scheda.coloreMancante
            static let coloreScrittoDaTe = K.inchiostro3
            static let segnoScrittoDaTe = "pencil"
            static let nota = C(dimensione: 12, peso: .regular, interlinea: 1.35)
            static let notaSopra: CGFloat = 4
            /// Il campo sul posto: largo quanto il valore, con il bordo dei campi di Prisma.
            static let campo = C(dimensione: 14, peso: .semibold)
            static let spazioCampi: CGFloat = 6
            /// La tile dei moduli: 12 sopra, titolo 13,5 bold, voci con padding 6.
            static let tileSopra: CGFloat = 12
            static let titoloTile = C(dimensione: 13.5, peso: .bold)
            static let coloreTitoloTile = K.inchiostro
            static let paddingVoceModulo: CGFloat = 6
            static let voceModulo = C(dimensione: 13.5, peso: .regular)
            static let coloreVoceModulo = K.inchiostro
            static let coloreVoceSpenta = K.inchiostro3
            static let spuntaModulo: CGFloat = 18
            static let fraseTile = C(dimensione: 12.5, peso: .regular, interlinea: 1.4)
            static let coloreFraseTile = K.inchiostro2
            /// Il pulsante grande, 14 sotto; «Scrivi a mano» sotto, piccolo.
            static let pulsanteSopra: CGFloat = 14
            static let link = C(dimensione: 12.5, peso: .semibold)
            static let coloreLink = K.accento
            static let linkSopra: CGFloat = 10
            /// L'interruttore della copia e la riga grigia dell'iPhone.
            static let copiaSopra: CGFloat = 12
            static let copia = C(dimensione: 12.5, peso: .regular, interlinea: 1.35)
            static let coloreCopia = K.inchiostro2
            /// «Canale da scegliere» nella testata del dossier (§9.1.6): etichetta grigia.
            static let canaleDaScegliere = C(dimensione: 11.5, peso: .semibold)
            static let coloreCanaleDaScegliere = K.inchiostro2
            static let fondoCanaleDaScegliere = K.chip
            static let paddingCanaleDaScegliere = Tema.Apple.Misura.padding(3, 8)
            /// Il glifo `scan` del pulsante «Nuovo cliente» nella testata di Clienti.
            static let glifoTestata: CGFloat = 14
        }

        // MARK: iPhone e iPad

        enum Mobile {
            /// Il pulsante grande «Nuovo cliente» in cima a Clienti sull'iPhone.
            static let pulsante = C(dimensione: 17, peso: .semibold)
            static let altezzaPulsante: CGFloat = 52
            static let glifo: CGFloat = 18
            static let spazio: CGFloat = 10
        }
    }
}

extension Tema.Apple.Moto {
    enum NuovoCliente {
        /// L'avatar si accende (opacità 0,25 → 1) in 0,5 s.
        static let durataAvatar = 0.5
        static var avatar: Animation { Curva.ease.animazione(durataAvatar) }
        /// Il contatore si aggiorna ogni decimo di secondo (TimelineView, niente Timer).
        static let passoContatore = 0.1
    }
}
