import SwiftUI

// Impostazioni › Strumenti › Velocità (giro 0 di «Prisma istantaneo»): le tabelle di «Misura la velocità su questo
// Mac» e di «Misura Vera» (Shell/MisuraVelocita.swift). Una card piatta come le righe delle impostazioni, con le
// cifre tabellari allineate a destra. Qui solo i valori.

extension Tema.Apple.Impostazioni {
    enum Velocita {
        static let superficie = Tema.Apple.Superficie.cardPiatta
        static let raggio = Tema.Apple.Raggio.card
        static let padding = Tema.Apple.Misura.Padding.rigaImpostazione
        /// Titolo della tabella (15 bold) e il pulsante «Copia» a destra, 12 sopra le righe.
        static let titolo = Tema.Apple.Carattere.titoloRiga
        static let coloreTitolo = Tema.Apple.Colore.inchiostro
        static let sottoTitolo: CGFloat = 12
        /// Lo scenario (5 clienti, 200 clienti): `.lbl`, 14 sopra (tranne il primo), 6 sotto.
        static let scenario = Tema.Apple.Carattere.etichetta
        static let coloreScenario = Tema.Apple.Colore.inchiostro2
        static let sopraScenario: CGFloat = 14
        static let sottoScenario: CGFloat = 6
        /// Le intestazioni delle colonne e le righe: azione a sinistra, cifre tabellari a destra.
        static let intestazione = Tema.Apple.Carattere.secondario
        static let coloreIntestazione = Tema.Apple.Colore.inchiostro3
        static let voce = Tema.Apple.Carattere.secondario
        static let coloreVoce = Tema.Apple.Colore.inchiostro
        static let cifre = Tema.Apple.Carattere.secondario.tabellari
        static let coloreCifre = Tema.Apple.Colore.inchiostro
        static let coloreCifreSecondarie = Tema.Apple.Colore.inchiostro2
        static let larghezzaColonna: CGFloat = 96
        static let altezzaRiga: CGFloat = 22
        static let filo: CGFloat = 0.5
        static let coloreFilo = Tema.Apple.Colore.separatore
        /// La nota sotto la tabella (come le note dei gruppi).
        static let nota = Tema.Apple.Carattere.secondario
        static let coloreNota = Tema.Apple.Colore.inchiostro2
        static let sopraNota: CGFloat = 10
    }
}
