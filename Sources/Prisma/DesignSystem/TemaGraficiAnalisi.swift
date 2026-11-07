import SwiftUI

// Gettoni dei grafici di vetro delle aree di Analisi 360 (GraficiAnalisi.swift): barre impilate, barra di
// copertura, cascata, barre a confronto e tessera con una cifra. Stesso linguaggio delle barre del TFR
// (TemaTFR.swift): barre piene a capsula morbida, scala che parte da zero, cifre subito leggibili, differenze in
// capsula nel colore del segno. Nessun colore nuovo: solo alias dei colori del tema, dinamici in chiaro e scuro.
// Niente animazioni: i grafici si disegnano fermi (vanno bene con «Riduci movimento» e nelle istantanee).

extension Tema.Colore {
    enum GraficiAnalisi {
        /// Binario vuoto delle barre e linea dello zero.
        static let binario = Tema.Colore.pozzetto
        static let zero = Tema.Colore.separatore
        /// Collegamenti tra un gradino e l'altro della cascata, segno del traguardo.
        static let raccordo = Colori.Analisi.lineaTratteggiata
        static let traguardo = Tema.Colore.inchiostroSecondario
        /// Testi: etichette delle righe, cifre, note e legenda.
        static let etichetta = Colori.Strumenti.consoleEtichetta
        static let cifra = Colori.Strumenti.risultato
        static let nota = Colori.Analisi.kpiNota
        /// Colori predefiniti delle serie (chi usa il grafico può passare il colore dell'area o del canale).
        static let principale = Colori.Analisi.linea
        static let secondaria = Colori.Analisi.barre
        /// Cascata: voce di partenza e totale, aggiunte, sottrazioni.
        static let cascataTotale = Colori.Analisi.linea
        static let cascataAggiunta = Colori.Analisi.barre
        static let cascataSottrazione = Colori.Analisi.prudente
        /// Toni semaforici (cifre, differenze, parte scoperta).
        static let positivo = Colori.Strumenti.positivo
        static let negativo = Colori.Strumenti.negativo
        static let attenzione = Colori.Analisi.attenzioneTesto
        static let neutro = Colori.Strumenti.risultato
        /// Tinte delle tessere evidenziate.
        static let tintaPositivo = Colori.Analisi.okFondo
        static let tintaAttenzione = Colori.Analisi.attenzioneFondo
        static let tintaNegativo = Colori.Analisi.erroreFondo
    }
}

extension Tema.Misura {
    enum GraficiAnalisi {
        /// Spazio tra le parti di un grafico (barre, legenda, note).
        static let spazio: CGFloat = 8
        /// Barre: altezza, raggio, altezza della riga (la barra sta al centro), lunghezza minima di un tratto
        /// visibile, stacco tra i tratti di una barra impilata.
        static let barra: CGFloat = 16
        static let barraSpessa: CGFloat = 22
        static let raggioBarra: CGFloat = 4
        static let rigaBarra: CGFloat = 26
        /// Riga delle barre spesse (impilate, copertura): c'è posto per il segno del traguardo che sporge.
        static let rigaBarraSpessa: CGFloat = 34
        static let barraMinima: CGFloat = 4
        static let stacco: CGFloat = 2
        /// Colonna delle etichette a sinistra delle barre (come le strade del TFR) e spazio dopo la barra.
        static let etichetta: CGFloat = 132
        static let spazioCifra: CGFloat = 8
        /// Spazio a destra della barra più lunga per la cifra e la differenza (barre a confronto).
        static let riservaCifra: CGFloat = 190
        /// Spazio a destra della barra più lunga per il totale (barre impilate) o la quota coperta («62% → 85%»).
        static let riservaTotale: CGFloat = 120
        /// Colonna delle cifre a destra della cascata orizzontale.
        static let cifraCascata: CGFloat = 104
        /// Cascata verticale: altezza dell'area delle colonne, larghezza massima di una colonna, spazio tra colonne.
        static let altezzaColonne: CGFloat = 150
        static let colonnaMassima: CGFloat = 64
        static let spazioColonne: CGFloat = 10
        /// Parte mancante (divario, scoperto): tinta del riempimento e tratteggio del bordo.
        static let opacitaMancante: Double = 0.14
        static let trattoMancante: CGFloat = 4
        static let filoMancante: CGFloat = 1
        /// Parte aggiunta dalle proposte: stesso colore, più chiaro (come la rendita nel TFR).
        static let opacitaProposte: Double = 0.45
        /// Segno verticale del traguardo (reddito desiderato, fabbisogno): spessore e sporgenza sopra e sotto la barra.
        static let segnoTraguardo: CGFloat = 1.5
        static let sporgenzaTraguardo: CGFloat = 5
        /// Legenda: quadratino del colore, spazi, larghezza minima di una voce (le voci vanno a capo, mai troncate).
        static let quadratino: CGFloat = 10
        static let raggioQuadratino: CGFloat = 3
        static let spazioQuadratino: CGFloat = 6
        static let spazioLegenda: CGFloat = 16
        static let voceLegendaMinima: CGFloat = 150
        static let spazioVoceLegenda: CGFloat = 1
        /// Capsula della differenza sulla barra.
        static let margineDifferenza = EdgeInsets(top: 2, leading: 7, bottom: 2, trailing: 7)
        static let opacitaDifferenza: Double = 0.14
        /// Tessera con una cifra.
        static let spazioTessera: CGFloat = 4
        static let scalaMinimaCifra: CGFloat = 0.6
    }
}

extension Tema.Testo {
    enum GraficiAnalisi {
        /// Etichette delle righe e delle colonne.
        static let etichetta = Tipo.consoleEtichetta
        /// Etichetta e cifra del totale della cascata.
        static let etichettaTotale = Tipo.consoleTitolo
        static let cifraTotale = Tema.Testo.importo.weight(.bold)
        /// Cifra dopo la barra e capsula della differenza.
        static let cifra = Tema.Testo.importo
        static let differenza = Tema.Testo.pill.monospacedDigit()
        /// Legenda: nome e cifra della voce.
        static let legenda = Tipo.kpiNota
        static let cifraLegenda = Tema.Testo.importo
        /// Etichetta del traguardo e note sotto le colonne.
        static let nota = Tipo.kpiNota
        /// Tessera: etichetta, cifra grande, riga breve.
        static let titoloTessera = Tema.Testo.secondario
        static let valoreTessera = Tema.Testo.valoreTessera
        static let spaziaturaValore = Tema.Testo.Componenti.spaziaturaValore
        static let notaTessera = Tema.Testo.didascalia
    }
}
