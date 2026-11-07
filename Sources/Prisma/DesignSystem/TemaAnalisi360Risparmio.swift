import SwiftUI

// Gettoni della sintesi di Analisi 360 › Risparmio (Shell/Analisi360Risparmio.swift): la cifra grande di quanto
// manca all'obiettivo (o «Raggiunto»), la barra di avanzamento verso l'obiettivo a scadenza, le tessere, la
// proiezione del piano, i piani collegati con il canale e le sezioni richiudibili (dove va il denaro, metodo).
// Solo alias dei colori e dei caratteri del tema: dinamici in chiaro e in scuro, come lo strumento TFR.

extension Tema.Colore {
    enum Risparmio360 {
        /// Colore del piano (barra di avanzamento e grafico): quello dell'area Risparmio.
        static let piano = Colori.Analisi.area(.risparmio)
        /// Cifra grande, semaforica: raggiunto (verde), a metà strada o oltre (arancio), sotto la metà (rosso).
        static let cifraRaggiunto = Colori.Strumenti.positivo
        static let cifraAttenzione = Colori.Analisi.attenzioneTesto
        static let cifraLontano = Colori.Strumenti.negativo
        /// Occhiello, note sotto la cifra, titoli delle sezioni.
        static let occhiello = Colori.Strumenti.risultatoNota
        static let nota = Colori.Strumenti.risultatoNota
        static let titoloSezione = Colori.Strumenti.consoleTitolo
        static let etichetta = Colori.Strumenti.consoleEtichetta
        /// Linea del versato nel grafico della proiezione.
        static let versato = Colori.Analisi.lineaTratteggiata
        /// Piani collegati.
        static let nomePiano = Colori.Analisi.tabellaTesto
        static let notaPiano = Colori.Analisi.kpiNota
        /// Sezioni richiudibili: freccia e titolo nel colore dei collegamenti.
        static let apri = Tema.Colore.link
    }
}

extension Tema.Misura {
    enum Risparmio360 {
        /// Spazio tra i blocchi della sintesi (cifra, barra, tessere, grafico, piani, sezioni).
        static let spazioBlocchi: CGFloat = 18
        /// Occhiello, cifra e note della testata.
        static let spazioCifra: CGFloat = 4
        static let spazioUnita: CGFloat = 6
        static let spazioPillola: CGFloat = 10
        static let tracciatoOcchiello: CGFloat = 1.2
        static let scalaMinimaCifra: CGFloat = 0.5
        /// Tessere affiancate.
        static let spazioTessere: CGFloat = 10
        /// Titolo di una sezione e il suo contenuto.
        static let spazioSezione: CGFloat = 8
        /// Piani collegati: righe in vetro sottile.
        static let spazioPiani: CGFloat = 6
        static let marginePiano = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let spazioPiano: CGFloat = 10
        static let spazioTestiPiano: CGFloat = 1
        static let colonnaCifraPiano: CGFloat = 150
        /// Legenda del grafico.
        static let spazioLegenda: CGFloat = 14
        /// Sezioni richiudibili.
        static let spazioApribili: CGFloat = 10
        static let spazioFreccia: CGFloat = 6
        static let freccia: CGFloat = 10
    }
}

extension Tema.Testo {
    enum Risparmio360 {
        static let occhiello = Tipo.risultatoOcchiello
        static let cifra = Tipo.risultatoGrande
        static let unita = Tipo.risultatoNota
        static let nota = Tipo.risultatoNota
        static let titoloSezione = Tipo.consoleTitolo
        static let etichetta = Tipo.consoleEtichetta
        static let nomePiano = Tipo.tabellaCellaForte
        static let notaPiano = Tipo.kpiNota
        static let cifraPiano = Tema.Testo.importo
        static let apri = Tipo.consoleTitolo
        static let freccia = Tema.Testo.sf(9, .semibold)
    }
}
