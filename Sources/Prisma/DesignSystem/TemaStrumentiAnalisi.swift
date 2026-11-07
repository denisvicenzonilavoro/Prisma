import SwiftUI

// Gettoni degli strumenti dentro Analisi 360 (simulatore, scenari, confronto, TFR): le app accorpate
// Simulazioni e Confronti senza la loro cornice. I comandi dei loro elenchi laterali (orizzonte, prospetto,
// «Parti da una posizione») stanno nella testata del contenuto; la cifra principale sta in alto.
// Nessun colore nuovo: solo alias dei colori del tema (dinamici chiari e scuri).

extension Tema.Misura {
    enum StrumentiAnalisi {
        /// Il simbolo delle voci «Strumenti» nell'elenco laterale (e nei «Collegati»).
        static let simboloVoce: CGFloat = 16
        /// Testata del contenuto: spazio tra gli elementi, spia, righe del titolo.
        static let spazioTestata: CGFloat = Misure.ColonneStrumento.spazioTestata
        static let spia: CGFloat = Tema.Misura.Componenti.spiaStato
        static let spazioTitoloTestata: CGFloat = 1
        /// Il menu «Parti da una posizione» e i segmenti dell'orizzonte nella testata.
        static let menuPosizioni: CGFloat = 210
        static let segmentiOrizzonte: CGFloat = 190
        /// L'orizzonte comune del confronto: da 1 a 50 anni.
        static let orizzonteMinimo = 1
        static let orizzonteMassimo = 50
        /// Console e risultati del simulatore (come il TFR).
        static let margineConsole = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        static let margineRisultati = EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22)
        static let spazioConsole: CGFloat = 16
        static let spazioRisultati: CGFloat = 16
        static let spazioLegenda: CGFloat = 16
        static let spazioCanale: CGFloat = 6
        /// Il contenuto che scorre di scenari e confronto.
        static let margineContenuto = EdgeInsets(top: 16, leading: 18, bottom: 18, trailing: 18)
        static let spazioContenuto: CGFloat = 16
        /// Le due schede A e B del confronto.
        static let spazioSchede: CGFloat = 14
        /// La cifra principale del confronto (differenza netta) e i costi di A e B accanto.
        static let margineCifra = EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        static let spazioCifra: CGFloat = 4
        static let spazioVerdetto: CGFloat = 18
        static let spazioCosti: CGFloat = 14
        static let spazioPallino: CGFloat = 6
        static let pallino: CGFloat = 8
        static let spazioPillole: CGFloat = 6
        static let spaziaturaOcchiello: CGFloat = 1.2
        /// Grafico del confronto: legenda sotto.
        static let spazioGrafico: CGFloat = 10
    }
}

extension Tema.Colore {
    enum StrumentiAnalisi {
        /// Il simbolo delle voci «Strumenti».
        static let simboloVoce = Tema.Colore.inchiostroSecondario
        /// La cifra principale, le sue note, i segni.
        static let cifra = Colori.Strumenti.risultato
        static let nota = Colori.Strumenti.risultatoNota
        static let positivo = Colori.Strumenti.positivo
        static let titoloTestata = Colori.Strumenti.consoleTitolo
        static let notaTestata = Colori.Analisi.kpiNota
        static let spia = Colori.Strumenti.spia
    }
}

extension Tema.Testo {
    enum StrumentiAnalisi {
        static let simboloVoce = Tema.Testo.Componenti.voce
        static let titoloTestata = Tipo.consoleTitolo
        static let notaTestata = Tipo.chip
        static let occhiello = Tipo.risultatoOcchiello
        static let cifra = Tipo.risultatoGrande
        static let nota = Tipo.risultatoNota
        static let costo = Tipo.risultatoDettaglio
    }
}
