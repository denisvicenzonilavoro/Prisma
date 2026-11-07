import SwiftUI

// Gettoni della sintesi di Analisi 360 › Investimenti (Shell/Analisi360Investimenti.swift): la cifra grande del
// capitale atteso, la scala del rischio (SRI 1-7) con il profilo del cliente segnato, il grafico dei tre scenari,
// la prova di tenuta come barre «oggi / dopo il calo», la cascata dei costi, le posizioni collegate con il canale
// e le sezioni richiudibili. Solo alias dei colori e dei caratteri del tema: dinamici in chiaro e in scuro.

extension Tema.Colore {
    enum Investimenti360 {
        /// Occhiello, cifra grande e note della testata.
        static let occhiello = Colori.Strumenti.risultatoNota
        static let cifra = Colori.Strumenti.risultato
        static let nota = Colori.Strumenti.risultatoNota
        static let guadagno = Colori.Strumenti.positivo
        static let perdita = Colori.Strumenti.negativo
        /// Titoli delle sezioni ed etichette dei grafici.
        static let titoloSezione = Colori.Strumenti.consoleTitolo
        static let etichetta = Colori.Strumenti.consoleEtichetta
        /// Le tre linee degli scenari e il versato.
        static let atteso = Colori.Analisi.linea
        static let prudente = Colori.Analisi.prudente
        static let favorevole = Colori.Analisi.favorevole
        static let versato = Colori.Analisi.lineaTratteggiata
        /// Prova di tenuta: il capitale di oggi e quello subito dopo il calo.
        static let oggi = Colori.Analisi.area(.investimento)
        static let dopoCalo = Colori.Analisi.barre
        /// Scala del rischio: caselle nel profilo, oltre il profilo, la casella del portafoglio.
        static let casella = Colori.Analisi.chip
        static let casellaBordo = Colori.Analisi.chipBordo
        static let casellaTesto = Colori.Analisi.chipTesto
        static let casellaOltre = Colori.Analisi.attenzioneFondo
        static let casellaOltreBordo = Colori.Analisi.attenzioneTesto
        static let scelta = Colori.Analisi.navAlto
        static let sceltaOltre = Colori.Analisi.attenzioneTesto
        static let testoScelta = Tema.Colore.Componenti.testoSuColore
        /// Il segno del limite del profilo sotto la scala.
        static let limiteProfilo = Tema.Colore.inchiostroSecondario
        /// Posizioni collegate.
        static let nomePosizione = Colori.Analisi.tabellaTesto
        static let notaPosizione = Colori.Analisi.kpiNota
        /// Sezioni richiudibili: freccia e titolo nel colore dei collegamenti.
        static let apri = Tema.Colore.link
    }
}

extension Tema.Misura {
    enum Investimenti360 {
        /// Spazio tra i blocchi della sintesi (testata, grafico, tessere, prova di tenuta, costi, posizioni).
        static let spazioBlocchi: CGFloat = 18
        /// Testata: spazio tra cifra e indicatore del rischio, tra le righe, occhiello.
        static let spazioTestata: CGFloat = 18
        static let spazioCifra: CGFloat = 4
        static let tracciatoOcchiello: CGFloat = 1.2
        static let scalaMinimaCifra: CGFloat = 0.5
        /// Riquadro del rischio rispetto al profilo.
        static let larghezzaRischio: CGFloat = 236
        static let margineRischio = EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        static let spazioRischio: CGFloat = 6
        static let casellaLarga: CGFloat = 26
        static let casellaAlta: CGFloat = 22
        static let spazioCaselle: CGFloat = 3
        static let segnoLimite: CGFloat = 2
        static let sporgenzaLimite: CGFloat = 4
        /// Titolo di una sezione e il suo contenuto; legenda del grafico.
        static let spazioSezione: CGFloat = 8
        static let spazioLegenda: CGFloat = 16
        static let spazioPillola: CGFloat = 8
        /// Tessere affiancate.
        static let spazioTessere: CGFloat = 10
        /// Posizioni collegate: righe in vetro sottile.
        static let spazioPosizioni: CGFloat = 6
        static let marginePosizione = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let spazioPosizione: CGFloat = 10
        static let spazioTestiPosizione: CGFloat = 1
        static let colonnaCifraPosizione: CGFloat = 130
        /// Sezioni richiudibili.
        static let spazioApribili: CGFloat = 10
        static let spazioFreccia: CGFloat = 6
        static let freccia: CGFloat = 10
    }
}

extension Tema.Testo {
    enum Investimenti360 {
        static let occhiello = Tipo.risultatoOcchiello
        static let cifra = Tipo.risultatoGrande
        static let nota = Tipo.risultatoNota
        static let titoloSezione = Tipo.consoleTitolo
        static let etichetta = Tipo.consoleEtichetta
        /// Scala del rischio: titolo del riquadro, numeri delle caselle, cifra dell'SRI, note.
        static let titoloRischio = Tipo.consoleTitolo
        static let casella = Tipo.chip
        static let cifraRischio = Tema.Testo.importo
        static let notaRischio = Tipo.kpiNota
        /// Posizioni collegate.
        static let nomePosizione = Tipo.tabellaCellaForte
        static let notaPosizione = Tipo.kpiNota
        static let cifraPosizione = Tema.Testo.importo
        static let apri = Tipo.consoleTitolo
        static let freccia = Tema.Testo.sf(9, .semibold)
    }
}
