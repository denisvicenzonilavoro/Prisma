import SwiftUI

// Il tavolo con l'iPad, lato Mac (Tavolo/TavoloMac.swift, viste in Shell/AlTavolo.swift): il pulsante «Al tavolo» con
// lo stato in Prospetti e nella sala della presentazione, il pannello dei comandi e la pagina finale della presa
// visione nel PDF. Il template non ha il tavolo: i valori vengono dai token del tema Apple (capsule, puntini di stato,
// sala sempre scura) e dalla carta dei documenti (sempre chiara, colori opachi e fissi).

extension Tema.Apple {
    enum Tavolo {
        typealias Colore = Tema.Apple.Colore
        typealias Carattere = Tema.Apple.Carattere

        /// Pixel per punto delle pagine mandate all'iPad: un A4 diventa 1190×1684, nitido sullo schermo dell'iPad.
        static let scalaPagina: CGFloat = 2

        // MARK: Lo stato (puntino nel pulsante «Al tavolo»)

        static let puntino: CGFloat = 7
        static let spazioPuntino: CGFloat = 6
        /// iPad collegato: verde; in attesa dell'iPad: arancio; tavolo chiuso: inchiostro tenue.
        static let coloreCollegato = Colore.verde
        static let coloreInAttesa = Colore.arancio
        static let coloreSpento = Colore.inchiostro3

        // MARK: Il pannello in Prospetti (popover)

        static let larghezzaPannello: CGFloat = 320
        static let paddingPannello = Tema.Apple.Misura.padding(16, 18)
        static let spazioPannello: CGFloat = 10
        static let spazioAzioni: CGFloat = 6
        static let titoloPannello = Carattere.titoloRiga
        static let coloreTitoloPannello = Colore.inchiostro
        static let statoPannello = Carattere.secondario
        static let coloreStatoPannello = Colore.inchiostro2
        static let avviso = Carattere.secondario
        static let coloreAvviso = Colore.arancio
        static let codice = Carattere(dimensione: 13, peso: .semibold, tabellare: true)
        static let coloreCodice = Colore.inchiostro
        /// I limiti del cursore lasciato al cliente («da 50 a 1.000 € al mese»).
        static let larghezzaCampo: CGFloat = 72

        // MARK: Nella sala (colori fissi: la sala è sempre scura)

        /// La striscia dei comandi sopra quelli della sala, a 12 da loro.
        static let fondoStriscia = Color(r: 255, g: 255, b: 255, a: 0.08)
        static let raggioStriscia = Tema.Apple.Raggio.tile
        static let paddingStriscia = Tema.Apple.Misura.padding(10, 14)
        static let spazioStriscia: CGFloat = 8
        static let sopraComandiSala: CGFloat = 12
        static let testoStriscia = Color(r: 255, g: 255, b: 255, a: 0.70)
        static let carattereStriscia = Carattere(dimensione: 12, peso: .medium)
        /// La striscia compare dal basso con la curva `uscita` (con «Riduci movimento»: dissolvenza di 0,15 s).
        static let comparsa = Tema.Apple.Moto.uscita(0.30)
        static let spostamentoComparsa: CGFloat = 8

        // MARK: La pagina della presa visione (carta, sempre chiara)

        enum PresaVisione {
            static let margine: CGFloat = 40
            static let alto: CGFloat = 34
            static let spazio: CGFloat = 12
            static let spazioPiccolo: CGFloat = 4
            /// Il riquadro del tratto: 300×120 con il bordo `linea` della carta.
            static let tratto = CGSize(width: 300, height: 120)
            static let raggioTratto: CGFloat = 6
            static let bordoTratto: CGFloat = 0.8
            static let paddingTratto: CGFloat = 10
            static let coloreBordo = Tema.Apple.Carta.linea
            static let filetto: CGFloat = 0.6
            /// Il tratto di prova (istantanee e prove): blu scuro su trasparente, 3 pt.
            static let coloreTrattoProva = CGColor(red: 0.08, green: 0.13, blue: 0.17, alpha: 1)
            static let spessoreTrattoProva: CGFloat = 3
        }
    }
}
