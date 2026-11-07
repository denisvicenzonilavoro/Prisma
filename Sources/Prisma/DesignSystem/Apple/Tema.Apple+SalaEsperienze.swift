import SwiftUI

// La Sala della versione «Luce» (Design/template-luce-specifica.md §1.3.2, §1.3.3): griglia delle 11 esperienze, palco
// e presentazione sulla sala opaca. Il nome non è `Tema.Apple.Sala` perché `Tema.Apple.Prospetti.Sala` e
// `Tema.Apple.Moto.Sala` esistono già (la sala della presentazione dei Prospetti). Misure in pt del palco 1440×900.

extension Tema.Apple {
    enum SalaEsperienze {
        typealias C = Tema.Apple.Carattere

        /// Griglia `1.35fr repeat(5,1fr)`, due righe uguali, spazio 12.
        enum Griglia {
            static let quotaPrima: CGFloat = 1.35
            static let colonne = 5
            static let righe = 2
            static let spazio: CGFloat = 12
        }

        /// Le schede: `.card` raggio 22, padding 24 (grande) e 16 (piccole), contenuto ritagliato.
        enum Scheda {
            static let superficie = Tema.Apple.Superficie.card
            static let raggio = Tema.Apple.Raggio.card
            static let paddingGrande: CGFloat = 24
            static let paddingPiccola: CGFloat = 16
            /// Tasselli: 60 (grande) e 44 (piccole), raggio 14 fisso.
            static let tasselloGrande = Tema.Apple.Tassello.latoSalaGrande
            static let tassello = Tema.Apple.Tassello.latoSala
            static let raggioTassello = Tema.Apple.Raggio.voce
            /// «Ciao Giulia.» 38 bold, 26 sotto il tassello; sotto «Il tuo piano, sempre con te.» 14 grigio.
            static let saluto = C.saluto
            static let sottoTassello: CGFloat = 26
            static let sottotitolo = C.corpo
            /// Gli anelli dei primi tre obiettivi: 70, tratto 8, 10 fra uno e l'altro; etichetta 11 larga al più 76.
            static let anello: CGFloat = 70
            static let trattoAnello: CGFloat = 8
            static let spazioAnelli: CGFloat = 10
            static let sopraAnelli: CGFloat = 18
            static let etichettaAnello = C(dimensione: 11, peso: .regular)
            static let larghezzaEtichetta: CGFloat = 76
            static let sopraEtichetta: CGFloat = 4
            static let centroAnello = C(dimensione: 15, peso: .bold, tabellare: true)
            static let massimoAnelli = 3
            /// I colori degli anelli, nell'ordine degli obiettivi.
            static let coloriAnelli = [Tema.Apple.Colore.anello1, Tema.Apple.Colore.anello2, Tema.Apple.Colore.anello3]
            /// Titolo 26 (grande) / 17 (piccole) bold, −0,3, interlinea 1,2; frase 14 / 12,5 grigia a 4.
            static let titoloGrande = C(dimensione: 26, peso: .bold, tracking: -0.3, interlinea: 1.2)
            static let titolo = C(dimensione: 17, peso: .bold, tracking: -0.3, interlinea: 1.2)
            static let fraseGrande = C.corpo
            static let frase = C.secondario
            static let sopraFrase: CGFloat = 4
            static let righeFrase = 2
            /// Le schede spente (nessun cliente in archivio).
            static let opacitaSpenta: Double = 0.55
        }

        /// Il palco: testata alta 40 («‹ Sala», tassello 32 raggio 10, nome 21 bold, cliente 14 grigio, pulsanti a
        /// destra a 6), la card a 52 dall'alto fino in fondo.
        enum Palco {
            static let altezzaTestata: CGFloat = 40
            static let spazioTestata: CGFloat = 12
            static let spazioPulsanti: CGFloat = 6
            static let tassello = Tema.Apple.Tassello.latoPalco
            static let raggioTassello: CGFloat = 10
            static let nome = C.h2
            static let cliente = C.corpo
            static let dallAlto: CGFloat = 52
            /// Lo stato «in arrivo» dentro la card.
            static let tasselloInArrivo = Tema.Apple.Tassello.latoSalaGrande
            static let spazioInArrivo: CGFloat = 14
            static let titoloInArrivo = C.titoloGruppo
            static let testoInArrivo = C.corpoGrande
            static let larghezzaInArrivo: CGFloat = 460
        }

        /// La presentazione sulla sala opaca (velo dei Prospetti, sempre scuro): il palco grande al centro, «Chiudi»
        /// bianco in basso.
        enum Presenta {
            static let velo = Tema.Apple.Colore.sala
            static let margine: CGFloat = 40
            static let comandiFondo: CGFloat = 24
            static let altezzaComandi: CGFloat = 32
            static let sopraComandi: CGFloat = 20
            static let tassello: CGFloat = 96
            static let raggioTassello: CGFloat = 26
            static let spazio: CGFloat = 18
            static let titolo = C(dimensione: 34, peso: .bold, tracking: -0.8)
            static let testo = C(dimensione: 17, peso: .regular, interlinea: 1.4)
            static let coloreTitolo = Color.white
            static let coloreTesto = Color(r: 255, g: 255, b: 255, a: 0.72)
            static let cliente = C.sottotitolo
            static let coloreCliente = Color(r: 255, g: 255, b: 255, a: 0.55)
            static let larghezzaTesto: CGFloat = 560
        }
    }
}

extension Tema.Apple.Moto.Inclinazione {
    /// La Sala: massimo 4° per la scheda grande, 7° per le piccole.
    static let massimoSalaGrande: Double = 4
    static let massimoSala: Double = 7
}

extension Tema.Apple.Moto {
    /// La Sala: la scheda scelta (scala 1,05 e opacità 0,4 in 0,18 s), la rimonta che parte 0,12 s dopo il clic e la
    /// card del palco che entra da scala 0,98 in 0,52 s con `uscita`; il palco nasce dalla scheda
    /// (`matchedGeometryEffect`, decisione 124) e ci torna con «‹ Sala».
    enum SalaEsperienze {
        static let durataScelta = 0.18
        static let scalaScelta: CGFloat = 1.05
        static let opacitaScelta: Double = 0.4
        static let ritardoRimonta = 0.12
        static let durataPalco = 0.52
        static let scalaPalco: CGFloat = 0.98
        static var palco: Animation { Curva.uscita.animazione(durataPalco) }
        /// Il passaggio griglia ↔ palco (la card nasce dalla scheda toccata).
        static var passaggio: Animation { Curva.dettaglioApre.animazione(durataPalco) }
        static var ritorno: Animation { Curva.dettaglioChiude.animazione(durataPalco) }
    }
}
