import SwiftUI

// La mini-app del cliente («Luce» giro 15, Design/template-luce-specifica.md §2.1.2): la tavolozza fissa e chiara del
// telefono del Prisma del cliente (15a) e del telefono «Così lo vede …» dei sinistri (15e). Sempre chiara, anche
// nell'aspetto scuro: tutti i colori sono esadecimali fissi (mai `Colore.rosso` e simili, che in scuro cambiano). Ogni
// colore c'è in doppia forma, l'esadecimale (per il CSS del file del cliente, 15a) e il `Color` (per le viste).

extension Tema.Apple {
    enum MiniCliente {
        static let fondoHex = "#F2F6F9"
        static let testoHex = "#14202B"
        static let testo2Hex = "#5A6873"
        static let piedeHex = "#7A8790"
        /// Gradiente della testata (165°): da… a….
        static let testataDaHex = "#E3EFF5"
        static let testataAHex = "#9DC2D6"
        static let cardHex = "#FFFFFF"
        /// «I risparmi bastano oltre i 90 anni».
        static let bastaHex = "#2F7A4A"
        /// «… fino a N anni».
        static let nonBastaHex = "#E5484D"
        /// Il quadrato della lettera.
        static let letteraHex = "#C45A75"
        /// La card scura del film.
        static let cardFilmHex = "#0F1C26"
        static let frecciaHex = "#0A84FF"
        /// Le fasi future del sinistro e i testi spenti.
        static let futuroHex = "#9AA6B0"
        static let cerchioVuotoHex = "#D5DCE2"
        /// La fase fatta del sinistro.
        static let fattaHex = "#30B15C"
        /// La fase di adesso del sinistro.
        static let adessoHex = "#E08A00"
        /// Il logo nella testata (sempre il colore del logo chiaro).
        static let logoHex = "#0F2433"
        /// La linea della pensione.
        static let lineaHex = "#8B5CF6"

        static var fondo: Color { Color(hex: fondoHex) }
        static var testo: Color { Color(hex: testoHex) }
        static var testo2: Color { Color(hex: testo2Hex) }
        static var piede: Color { Color(hex: piedeHex) }
        static var testataDa: Color { Color(hex: testataDaHex) }
        static var testataA: Color { Color(hex: testataAHex) }
        static var card: Color { Color(hex: cardHex) }
        static var basta: Color { Color(hex: bastaHex) }
        static var nonBasta: Color { Color(hex: nonBastaHex) }
        static var lettera: Color { Color(hex: letteraHex) }
        static var cardFilm: Color { Color(hex: cardFilmHex) }
        static var freccia: Color { Color(hex: frecciaHex) }
        static var futuro: Color { Color(hex: futuroHex) }
        static var cerchioVuoto: Color { Color(hex: cerchioVuotoHex) }
        static var fatta: Color { Color(hex: fattaHex) }
        static var adesso: Color { Color(hex: adessoHex) }
        static var logo: Color { Color(hex: logoHex) }
        static var linea: Color { Color(hex: lineaHex) }

        /// Tutti gli esadecimali per nome, per le variabili CSS del file del cliente (15a: `--fondo: #F2F6F9;`…).
        static let tuttiHex: [(nome: String, hex: String)] = [
            ("fondo", fondoHex), ("testo", testoHex), ("testo2", testo2Hex), ("piede", piedeHex),
            ("testata-da", testataDaHex), ("testata-a", testataAHex), ("card", cardHex), ("basta", bastaHex),
            ("non-basta", nonBastaHex), ("lettera", letteraHex), ("card-film", cardFilmHex), ("freccia", frecciaHex),
            ("futuro", futuroHex), ("cerchio-vuoto", cerchioVuotoHex), ("fatta", fattaHex), ("adesso", adessoHex),
            ("logo", logoHex), ("linea", lineaHex),
        ]
    }

    /// «Dato al cliente» in cima alla scheda Documenti del dossier (giro 15).
    enum UsciteCliente {
        typealias K = Tema.Apple.Carattere
        typealias C = Tema.Apple.Colore
        static let quante = 5
        static let etichetta = K.etichetta
        static let coloreEtichetta = C.inchiostro2
        static let titolo = K(dimensione: 13, peso: .semibold)
        static let dettaglio = K.secondario
        static let coloreTitolo = C.inchiostro
        static let coloreDettaglio = C.inchiostro2
        static let lucchetto = "lock.fill"
        static let coloreLucchetto = C.inchiostro3
        static let fondo = C.card
        static let raggio = Tema.Apple.Raggio.tile
        static let padding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        static let spazio: CGFloat = 8
        static let spazioRiga: CGFloat = 10
        static let spazioStretto: CGFloat = 2
        static let larghezzaData: CGFloat = 92
        static let margine = EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20)
        /// La riga sotto il pulsante di condivisione senza il consenso a WhatsApp.
        static let nota = K.secondario
        static let coloreNota = C.inchiostro3
    }
}
