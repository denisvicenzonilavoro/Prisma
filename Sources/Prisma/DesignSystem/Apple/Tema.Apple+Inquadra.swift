import SwiftUI

// Inquadra e capisci (Design/template-novita-specifica.md §9.2, §9.3): misure, caratteri, colori e tempi della scena
// del Mac (velo, iPhone disegnato con il foglio, linea della scansione, scheda «Prisma sul Mac», tabella del
// confronto, zona dove trascinare una foto o un PDF) e della schermata della fotocamera sull'iPhone.
// Le viste stanno in Shell/ScenaInquadra.swift, Shell/FoglioInquadra.swift e iOS/InquadraTelefono.swift; qui solo i
// valori. Misure in pt del palco 1440×900 del template. Il foglio è carta: sempre chiaro, anche in scuro.

extension Tema.Apple {
    enum Inquadra {
        typealias C = Tema.Apple.Carattere
        typealias K = Tema.Apple.Colore

        /// Il verde della lettura sul foglio (#34C759, il verde di sistema); i ✓ della scheda usano `K.verde`
        /// (#2FA35A), come nel template: due tinte diverse.
        static let verdeLettura = K.verdeInterruttore

        // MARK: Velo (§2.1)

        /// Il velo è quello comune della scena del telefono (Tema.Apple+Luce.swift, versione «Luce» §1.4.2).
        typealias Velo = Tema.Apple.VeloScena

        // MARK: Disposizione (§2.8)

        enum Disposizione {
            /// Telefono e scheda affiancati e centrati: 100 fra i due, la scheda 70 più in basso del telefono.
            static let spazio: CGFloat = 100
            static let scartoScheda: CGFloat = 70
            /// Margine minimo dai bordi della finestra; sotto questa misura la scena si rimpicciolisce.
            static let margine: CGFloat = 24
            static let scalaMinima: CGFloat = 0.6
        }

        // MARK: iPhone disegnato (§2.2)

        /// L'iPhone disegnato è quello comune (Tema.Apple+Luce.swift, versione «Luce» §1.4.2): stessi valori di prima.
        typealias Apparecchio = Tema.Apple.Apparecchio

        // MARK: Il foglio (§2.3)

        enum Foglio {
            /// Dentro lo schermo: 30 dai lati, 120 dall'alto; ruotato di −3°.
            static let lati: CGFloat = 30
            static let dallAlto: CGFloat = 120
            static let rotazione: Double = -3
            static let fondo = Color(hex: "#FBFAF7")
            static let raggio: CGFloat = 6
            static let padding = Tema.Apple.Misura.padding(18, 16)
            /// Ombra `0 20px 40px rgba(0,0,0,.5)`.
            static let ombra = Color(r: 0, g: 0, b: 0, a: 0.5)
            static let ombraRaggio: CGFloat = 20
            static let ombraY: CGFloat = 20
            /// Intestazione: 9 bold, spaziatura 1, maiuscola, #7a8590.
            static let intestazione = C(dimensione: 9, peso: .bold, tracking: 1, maiuscolo: true)
            static let coloreIntestazione = Color(hex: "#7A8590")
            /// Titolo: 15 heavy, 4 sopra e 10 sotto, #1b2530.
            static let titolo = C(dimensione: 15, peso: .heavy)
            static let titoloSopra: CGFloat = 4
            static let titoloSotto: CGFloat = 10
            /// Righe: 10,5, #4a5560, padding 5, raggio 5; il valore in grassetto #1b2530.
            static let riga = C(dimensione: 10.5, peso: .regular)
            static let valoreRiga = C(dimensione: 10.5, peso: .bold)
            static let inchiostro = Color(hex: "#4A5560")
            static let inchiostroForte = Color(hex: "#1B2530")
            static let paddingRiga: CGFloat = 5
            static let raggioRiga: CGFloat = 5
            /// Riga letta: contorno 2 verde e fondo verde al 14%.
            static let contornoLetto: CGFloat = 2
            static let fondoLetto = Tema.Apple.Inquadra.verdeLettura.opacity(0.14)
            /// Le righe finte (testo illeggibile della polizza): alte 5, raggio 3, #e8ecef, 12 e 5 sopra.
            static let righeFinte = Color(hex: "#E8ECEF")
            static let altezzaFinta: CGFloat = 5
            static let raggioFinta: CGFloat = 3
            static let primaFintaSopra: CGFloat = 12
            static let fintaSopra: CGFloat = 5
            static let larghezzeFinte: [CGFloat] = [0.8, 0.6, 0.7]
            /// Su una foto vera: il riquadro del campo letto, con un poco d'aria intorno alla riga.
            static let ariaRiquadro: CGFloat = 3
            static let raggioRiquadro: CGFloat = 4
        }

        // MARK: Linea della scansione (§2.4)

        enum Linea {
            static let lati: CGFloat = 18
            static let altezza: CGFloat = 3
            /// Da 110 a 420 dall'alto dello schermo, e ritorno: si ferma in alto.
            static let dallAlto: CGFloat = 110
            static let finoA: CGFloat = 420
            static let colore = Tema.Apple.Inquadra.verdeLettura
            /// Alone `0 0 18px`.
            static let alone: CGFloat = 9
        }

        // MARK: Scheda «Prisma sul Mac» (§2.6)

        enum Scheda {
            static let larghezza: CGFloat = 440
            static let padding = Tema.Apple.Misura.padding(22, 24)
            /// Fondo pieno `--cardE` (bianca in chiaro, #283642 in scuro), bordo, ombra della card, raggio 22.
            static let superficie = Tema.Apple.Superficie(riempimento: K.cardPiena, sfocatura: 0, saturazione: 1,
                                                          bordo: K.separatore, spessoreBordo: Tema.Apple.Misura.bordo,
                                                          ombra: .card, raggio: Tema.Apple.Raggio.card, filoInterno: false)
            static let sfera: CGFloat = 26
            static let spazioTesta: CGFloat = 10
            static let etichetta = C.etichetta
            static let coloreEtichetta = K.inchiostro2
            static let paddingChiudi = Tema.Apple.Misura.padding(6, 10)
            /// Titolo: display 22 bold, 10 sopra.
            static let titolo = C(dimensione: 22, peso: .bold, tracking: -0.4)
            static let coloreTitolo = K.inchiostro
            static let titoloSopra: CGFloat = 10
            /// Frase sotto il titolo (attesa, errori, avvisi).
            static let frase = C(dimensione: 13.5, peso: .regular, interlinea: 1.4)
            static let coloreFrase = K.inchiostro2
            static let fraseSopra: CGFloat = 6
            /// Righe dei dati: 8 sopra il blocco, 8×0 ciascuna, filetto sotto.
            static let righeSopra: CGFloat = 8
            static let paddingRiga: CGFloat = 8
            static let filo = K.separatore
            static let spunta = C(dimensione: 14, peso: .bold)
            static let coloreSpunta = K.verde
            static let larghezzaSpunta: CGFloat = 22
            static let etichettaRiga = C.secondario
            static let coloreEtichettaRiga = K.inchiostro2
            static let larghezzaEtichetta: CGFloat = 150
            static let valore = C(dimensione: 14, peso: .bold)
            static let coloreValore = K.inchiostro
            /// Il campo che manca («pochi dati»): grigio, senza ✓.
            static let coloreMancante = K.inchiostro3
            /// Pulsanti: 8 fra loro, 16 sopra.
            static let spazioPulsanti: CGFloat = 8
            static let pulsantiSopra: CGFloat = 16
            /// La scelta del cliente e il canale, sopra i pulsanti.
            static let clienteSopra: CGFloat = 14
            static let spazioCliente: CGFloat = 8
            static let carattereCliente = C.secondario
            static let coloreCliente = K.inchiostro2
            /// La conferma prima di aggiungere: tile con la frase e i due pulsanti.
            static let confermaSopra: CGFloat = 14
            static let paddingConferma = Tema.Apple.Misura.Padding.tile
            static let superficieConferma = Tema.Apple.Superficie.tile
            static let fraseConferma = C(dimensione: 13, peso: .regular, interlinea: 1.4)
        }

        // MARK: Tabella del confronto (§2.6)

        enum Tabella {
            static let sopra: CGFloat = 14
            static let superficie = Tema.Apple.Superficie.tile
            static let raggio = Tema.Apple.Raggio.tile
            /// Colonne `1.1fr 1fr 1fr`.
            static let pesi: [CGFloat] = [1.1, 1, 1]
            static let carattere = C(dimensione: 13, peso: .regular)
            static let carattereForte = C(dimensione: 13, peso: .bold)
            static let carattereTesta = C(dimensione: 13, peso: .semibold)
            static let padding = Tema.Apple.Misura.padding(8, 12)
            static let colorePrima = K.inchiostro2
            static let coloreSeconda = K.inchiostro
            static let coloreTerza = K.accento
            static let fondoTesta = K.chip
            static let filo = K.separatore
            static let nota = C(dimensione: 12.5, peso: .regular, interlinea: 1.45)
            static let coloreNota = K.inchiostro2
            static let notaSopra: CGFloat = 8
        }

        // MARK: Zona dove trascinare (il Mac senza l'iPhone)

        enum Zona {
            static let sopra: CGFloat = 14
            static let altezza: CGFloat = 132
            static let raggio = Tema.Apple.Raggio.tile
            static let tratto: CGFloat = 1.5
            static let trattino: [CGFloat] = [6, 5]
            static let coloreTratto = K.inchiostro3
            static let coloreTrattoSopra = K.accento
            static let fondo = K.chip
            static let fondoSopra = K.selezioneVoce
            static let icona: CGFloat = 26
            static let coloreIcona = K.inchiostro2
            static let testo = C(dimensione: 13.5, peso: .semibold)
            static let coloreTesto = K.inchiostro
            static let sottotesto = C.secondario
            static let coloreSottotesto = K.inchiostro2
            static let spazio: CGFloat = 6
        }

        // MARK: Schermata della fotocamera sull'iPhone

        enum Mobile {
            /// La guida del documento sull'inquadratura: angoli bianchi, rapporto di un A4 verticale.
            static let rapportoGuida: CGFloat = 0.707
            static let margineGuida: CGFloat = 28
            /// La guida è alta al più il 62% dello schermo.
            static let quotaGuida: CGFloat = 0.62
            static let angolo: CGFloat = 26
            static let spessoreAngolo: CGFloat = 4
            static let coloreGuida = Color.white
            static let fondoCamera = Tema.Apple.Inquadra.Apparecchio.schermo
            /// Il pannello in basso: vetro sopra l'acqua o la fotocamera, raggio 26, padding 16×18.
            static let superficiePannello = Tema.Apple.Superficie.vetroSopra
            static let raggioPannello = Tema.Apple.Raggio.riquadro
            static let paddingPannello = Tema.Apple.Misura.padding(16, 18)
            static let margine: CGFloat = 16
            static let spazio: CGFloat = 12
            /// Lo scatto: cerchio bianco 68 con l'anello 4.
            static let scatto: CGFloat = 68
            static let anelloScatto: CGFloat = 4
            static let interScatto: CGFloat = 56
            static let coloreScatto = Color.white
            static let titolo = C(dimensione: 19, peso: .bold, tracking: -0.3)
            static let coloreTitolo = K.inchiostro
            static let frase = C(dimensione: 13.5, peso: .regular, interlinea: 1.35)
            static let coloreFrase = K.inchiostro2
            /// Il foglio letto in alto: al più metà dell'altezza.
            static let quotaFoglio: CGFloat = 0.46
            /// Il foglio letto sta sotto la ✕ di chiusura.
            static let foglioDallAlto: CGFloat = 56
            static let raggioFoglio = Tema.Apple.Raggio.tile
            /// La scritta sopra l'inquadratura.
            static let scritta = Tema.Apple.Inquadra.Apparecchio.scritta
            static let coloreScritta = Color.white
            static let fondoScritta = Color(r: 0, g: 0, b: 0, a: 0.45)
            static let paddingScritta = Tema.Apple.Misura.padding(6, 12)
        }
    }
}

// MARK: - Movimento (§9.3)

extension Tema.Apple.Moto {
    enum Inquadra {
        /// Il velo appare in 0,3 s (lineare); se ne va in 0,22 s.
        static let durataVelo = 0.30
        static let durataChiusura = 0.22
        static var velo: Animation { .linear(duration: durataVelo * Tema.Apple.Moto.ritmo) }
        static var chiusura: Animation { .linear(duration: durataChiusura * Tema.Apple.Moto.ritmo) }
        /// L'iPhone entra da y +60 e −4° in 0,7 s con la molla leggera `cubic-bezier(.34,1.3,.64,1)`.
        static let durataTelefono = 0.70
        static let curvaTelefono = Curva.mollaLeggera
        static var telefono: Animation { curvaTelefono.animazione(durataTelefono) }
        static let spostamentoTelefono: CGFloat = 60
        static let rotazioneTelefono: Double = -4
        /// La linea scende in 1,1 s e torna su in altri 1,1 s (`ease-in-out`): si ferma in alto.
        static let durataLinea = 1.10
        static var linea: Animation { Curva.easeInOut.animazione(durataLinea) }
        /// I campi a cascata: il primo dopo 1,3 s (solo se il foglio è appena arrivato), poi uno ogni 0,45 s.
        static let ritardoPrimo = 1.30
        static let passoCampo = 0.45
        /// «✓ Fatto» e i pulsanti 0,3 s dopo l'ultimo campo, di colpo.
        static let codaFatto = 0.30
        /// La riga del foglio si illumina in 0,4 s (`ease`); quella della scheda entra da x −14 in 0,4 s (`uscita`).
        static let durataRiga = 0.40
        static var accensione: Animation { Curva.ease.animazione(durataRiga) }
        static let spostamentoRiga: CGFloat = -14
        /// La tabella del confronto entra da y +10 in 0,45 s (`uscita`).
        static let durataTabella = 0.45
        static var tabella: Animation { Curva.uscita.animazione(durataTabella) }
        static let spostamentoTabella: CGFloat = 10
        /// Dal pannello Novità: lo scanner si apre 0,5 s dopo se Posizioni era già davanti, 0,9 s se no.
        static let aperturaDaNovita = 0.50
        static let aperturaDaNovitaFinestra = 0.90
    }
}

extension Tema.Apple.Moto.StileEntrata {
    /// Righe della scheda «Prisma sul Mac»: da x −14, in 0,4 s con `uscita`, senza sfocatura.
    static let rigaInquadra = Tema.Apple.Moto.StileEntrata(durata: Tema.Apple.Moto.Inquadra.durataRiga,
                                                           curva: Tema.Apple.Moto.Curva.uscita,
                                                           spostamentoX: Tema.Apple.Moto.Inquadra.spostamentoRiga,
                                                           spostamentoY: 0, scala: 1, sfocatura: 0)
    /// La tabella del confronto: da y +10, in 0,45 s con `uscita`.
    static let tabellaInquadra = Tema.Apple.Moto.StileEntrata(durata: Tema.Apple.Moto.Inquadra.durataTabella,
                                                              curva: Tema.Apple.Moto.Curva.uscita,
                                                              spostamentoX: 0,
                                                              spostamentoY: Tema.Apple.Moto.Inquadra.spostamentoTabella,
                                                              scala: 1, sfocatura: 0)
}
