import SwiftUI

// Gettoni della sintesi di Analisi 360 › Previdenza (Shell/Analisi360Previdenza.swift): la cifra grande del
// divario, le barre «pensione pubblica + piani + divario» fino al reddito desiderato, le tessere, la riga della
// stima contributiva, i piani collegati con il canale e le sezioni richiudibili (stima, fisco, metodo).
// Solo alias dei colori e dei caratteri del tema: dinamici in chiaro e in scuro, come lo strumento TFR.

extension Tema.Colore {
    enum Previdenza360 {
        /// Tratti delle barre: pensione pubblica, integrazione dai piani, divario che resta (tratteggiato).
        static let pensione = Colori.Analisi.barre
        static let piani = Colori.Analisi.area(.previdenza)
        static let divario = Colori.Analisi.attenzioneTesto
        /// Cifra grande: il divario (arancio) o il reddito coperto (verde).
        static let cifraDivario = Colori.Analisi.attenzioneTesto
        static let cifraCoperto = Colori.Strumenti.positivo
        /// Occhiello, note sotto la cifra, titoli delle sezioni.
        static let occhiello = Colori.Strumenti.risultatoNota
        static let nota = Colori.Strumenti.risultatoNota
        static let titoloSezione = Colori.Strumenti.consoleTitolo
        static let etichetta = Colori.Strumenti.consoleEtichetta
        /// Linea del versato nel grafico della proiezione.
        static let versato = Colori.Analisi.lineaTratteggiata
        /// Riga della stima contributiva e piani collegati.
        static let testo = Colori.Strumenti.risultato
        static let nomePiano = Colori.Analisi.tabellaTesto
        static let notaPiano = Colori.Analisi.kpiNota
        static let avviso = Colori.Analisi.attenzioneTesto
        /// Sezioni richiudibili: freccia e titolo nel colore dei collegamenti.
        static let apri = Tema.Colore.link
    }
}

extension Tema.Misura {
    enum Previdenza360 {
        /// Spazio tra i blocchi della sintesi (cifra, barre, tessere, grafico, piani, sezioni).
        static let spazioBlocchi: CGFloat = 18
        /// Occhiello, cifra e note della testata.
        static let spazioCifra: CGFloat = 4
        static let spazioUnita: CGFloat = 6
        static let spazioPillola: CGFloat = 8
        static let tracciatoOcchiello: CGFloat = 1.2
        /// La cifra grande si rimpicciolisce fin qui invece di troncarsi.
        static let scalaMinimaCifra: CGFloat = 0.5
        /// Tessere affiancate.
        static let spazioTessere: CGFloat = 10
        /// Titolo di una sezione e il suo contenuto.
        static let spazioSezione: CGFloat = 8
        /// Riga della stima contributiva.
        static let margineStima = EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 12)
        static let spazioStima: CGFloat = 10
        static let marginePulsante = EdgeInsets(top: 3, leading: 9, bottom: 3, trailing: 9)
        /// Piani collegati: righe in vetro sottile.
        static let spazioPiani: CGFloat = 6
        static let marginePiano = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let spazioPiano: CGFloat = 10
        static let spazioTestiPiano: CGFloat = 1
        static let colonnaCifraPiano: CGFloat = 150
        /// Sezioni richiudibili.
        static let spazioApribili: CGFloat = 10
        static let spazioFreccia: CGFloat = 6
        static let freccia: CGFloat = 10
    }
}

extension Tema.Testo {
    enum Previdenza360 {
        static let occhiello = Tipo.risultatoOcchiello
        static let cifra = Tipo.risultatoGrande
        static let unita = Tipo.risultatoNota
        static let nota = Tipo.risultatoNota
        static let titoloSezione = Tipo.consoleTitolo
        static let etichetta = Tipo.consoleEtichetta
        static let testo = Tipo.strumentoTesto
        static let nomePiano = Tipo.tabellaCellaForte
        static let notaPiano = Tipo.kpiNota
        static let cifraPiano = Tema.Testo.importo
        static let apri = Tipo.consoleTitolo
        static let freccia = Tema.Testo.sf(9, .semibold)
    }
}
