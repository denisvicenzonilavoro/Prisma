import SwiftUI

// Gettoni delle esperienze «racconto» della Sala (Design/template-luce-specifica.md §3): per ora «Disegna il tuo
// futuro» (§3.3.2, giro 4). Misure in pt del palco 1440×900 (card del palco circa 1384×600).

extension Tema.Apple {
    enum SalaRacconti {
        typealias C = Tema.Apple.Carattere

        /// Disegna il tuo futuro: la tela 900×520 a 24/22 (raggio 16, fondo `chip`) e la colonna di destra.
        enum Disegno {
            static let tela = CGSize(width: 900, height: 520)
            static let telaSinistra: CGFloat = 24
            static let telaAlto: CGFloat = 22
            static let raggioTela: CGFloat = 16
            static let fondoTela = Tema.Apple.Colore.chip
            /// Margini del grafico dentro la tela: 60 a sinistra, 40 in basso, 20 a destra e in alto.
            static let margini = EdgeInsets(top: 20, leading: 60, bottom: 40, trailing: 20)
            static let passoAnni = 10
            static let righeOrizzontali = 5
            static let scrittaAssi = C(dimensione: 12, peso: .medium, tabellare: true)
            static let coloreAssi = Tema.Apple.Colore.inchiostro3
            static let righe = Tema.Apple.Colore.separatore
            static let spessoreRighe: CGFloat = 1
            /// Le cifre dell'asse a 8 dal bordo sinistro, l'età 20 sotto il grafico (centrata sulla riga).
            static let asseSinistra: CGFloat = 8
            static let etaSotto: CGFloat = 20
            /// L'invito «Disegna qui, partendo dal punto viola →»: 18, 600, 20 a destra e 24 sopra il punto.
            static let invito = C(dimensione: 18, peso: .semibold)
            static let invitoDestra: CGFloat = 20
            static let invitoSopra: CGFloat = 24
            /// Il punto di partenza (viola) e quello della pensione (verde): raggio 6.
            static let raggioPunto: CGFloat = 6
            static let colorePartenza = Tema.Apple.Colore.stima
            static let coloreDisegno = Tema.Apple.Colore.stima
            static let colorePossibile = Tema.Apple.Colore.anello1
            /// Il tratto: 4, estremi e giunzioni tondi.
            static let tratto: CGFloat = 4
            /// Il fantasma: viola al 45%, spessore 3, tratteggio 7/7.
            static let opacitaFantasma: Double = 0.45
            static let spessoreFantasma: CGFloat = 3
            static let tratteggioFantasma: [CGFloat] = [7, 7]
            /// La curva del piano: 4,5; tratteggiata 6/6 dopo la pensione quando è solo indicativa.
            static let curvaPossibile: CGFloat = 4.5
            static let tratteggioIndicativa: [CGFloat] = Tema.Apple.Grafico.Tracciato.tratteggioStima
            /// La colonna di destra: da x 950 (26 dopo la tela), 28 dal bordo destro, 26 sopra, 24 sotto.
            static let colonnaSinistra: CGFloat = 950
            static let colonnaDestra: CGFloat = 28
            static let colonnaAlto: CGFloat = 26
            static let colonnaBasso: CGFloat = 24
            static let titolo = C(dimensione: 26, peso: .bold, tracking: -0.5, interlinea: 1.2)
            static let spiegazione = C(dimensione: 14, peso: .regular, interlinea: 1.5)
            static let sottoTitolo: CGFloat = 8
            static let sopraRisultato: CGFloat = 18
            /// I due riquadri del risultato (`.tile`), 10 fra l'uno e l'altro, la cifra `.v`.
            static let superficieTile = Tema.Apple.Superficie.tile
            static let raggioTile = Tema.Apple.Raggio.tile
            static let paddingTile = Tema.Apple.Misura.Padding.tile
            static let etichettaTile = Tema.Apple.Carattere.secondario
            static let cifraTile = Tema.Apple.Carattere.valore
            static let fraTile: CGFloat = 10
            /// La frase: display 20, 700, interlinea 1,3, 14 sotto i riquadri; l'avvertenza `.k` 6 sotto.
            static let frase = C(dimensione: 20, peso: .bold, interlinea: 1.3)
            static let sopraFrase: CGFloat = 14
            static let avvertenza = Tema.Apple.Carattere.secondario
            static let sopraAvvertenza: CGFloat = 6
            static let spazioPulsanti: CGFloat = 8
            /// La nota sotto il titolo (punto di partenza 0 €).
            static let nota = Tema.Apple.Carattere.secondario
            static let sopraNota: CGFloat = 10
            /// Un tratto con meno di 4 punti torna vuoto; un punto più a sinistra di 2 si scarta (in MotoreDisegno).
            /// Il modulo «Salva come obiettivo» sopra la tela: largo 420, padding 22, raggio 22.
            static let larghezzaModulo: CGFloat = 420
            static let paddingModulo: CGFloat = 22
            static let raggioModulo = Tema.Apple.Raggio.card
            static let superficieModulo = Tema.Apple.Superficie.card
            static let spazioModulo: CGFloat = 12
            static let titoloModulo = Tema.Apple.Carattere.titoloFinestra
            static let etichettaModulo = Tema.Apple.Carattere.secondario
            static let campoModulo = Tema.Apple.Carattere.corpo
            static let veloModulo = Color(r: 0, g: 0, b: 0, a: 0.18)
            /// Il segno sotto la tela vuota per lo stato senza data di nascita: largo al più 460.
            static let larghezzaManca: CGFloat = 460
        }
    }
}

extension Tema.Apple.Moto {
    /// Disegna il tuo futuro: la curva verde passa dal disegno al piano in 1,3 s con la quartica (`Animatable`, niente
    /// Timer); il risultato entra dopo, a cascata, con i numeri contati.
    enum Disegno {
        static let trasformazione = 1.30
        static var animazione: Animation { .linear(duration: trasformazione) }
    }
}
