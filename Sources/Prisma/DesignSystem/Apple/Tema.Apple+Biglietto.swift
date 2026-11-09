import SwiftUI

// Gettoni della condivisione del biglietto dei traguardi («Luce» giro 15, Design/template-luce-specifica.md §5.4,
// decisioni 9 e 115): il PNG del biglietto (560×420 a scala 2), la frase modificabile sotto il biglietto e la riga
// «Il biglietto» del pannello (interruttore «Mostra la cifra», «Condividi…», menu «…»). Le viste stanno in
// Shell/PannelloTraguardo.swift, Shell/BigliettoTraguardo.swift e Shell/EsportaBiglietto.swift.

extension Tema.Apple.Messaggi.Traguardo {
    enum Esporta {
        /// Il PNG: la misura del biglietto (`biglietto`) a scala 2, 1120×840 pixel.
        static let scala: CGFloat = 2
        /// La frase scritta a mano: oltre questo numero di caratteri non entra nel biglietto.
        static let massimoFrase = 260
    }

    enum Frase {
        static let spazio: CGFloat = 10
        static let altezza: CGFloat = 96
        static let padding = EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        static let raggio = Tema.Apple.Raggio.pannello / 2
        static let carattere = Tema.Apple.Carattere.corpo
        static let coloreTesto = Tema.Apple.Colore.inchiostro
        static let fondo = Tema.Apple.Colore.chip
        static let bordo = Tema.Apple.Colore.separatore
        static let spessoreBordo = Tema.Apple.Misura.bordo
        static let spazioComandi: CGFloat = 8
        static let nota = Tema.Apple.Carattere.secondario
        static let coloreNota = Tema.Apple.Colore.inchiostro2
    }

    enum Condividi {
        static let spazioAzioni: CGFloat = 8
        /// Sotto il titolo della riga: l'interruttore e le note.
        static let spazioSotto: CGFloat = 8
        static let interruttore = Tema.Apple.Carattere.corpo
        static let coloreInterruttore = Tema.Apple.Colore.inchiostro
        static let nota = Tema.Apple.Carattere.secondario
        static let coloreNota = Tema.Apple.Colore.inchiostro2
        static let altro = "ellipsis"
    }
}
