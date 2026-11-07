import SwiftUI

// MARK: - Gettoni delle multiramo a due parti (tema Liquid Glass)
// Composizione «gestione separata + fondi» nel modulo della posizione, nella scheda prodotto e nel dettaglio:
// barra a due colori, colonne affiancate delle due parti, cursore della quota.
// Le tinte vengono da quelle che i documenti usano già per le parti (StileDocumenti: GS #6f86a6, FI #7a6fb0),
// schiarite nell'aspetto scuro. Su carta (PDF) restano solo `Colori.Documento.prisma.parte(_:)`.

extension Tema.Colore {
    /// Colori delle due parti di una multiramo.
    enum Multiramo {
        /// La parte in gestione separata (Ramo I): barra, pallino della colonna, linea nel grafico.
        static let gestione = Color.dinamico(chiaro: Color(hex: "#5F7EA3"), scuro: Color(hex: "#93B2D8"))
        /// La parte nei fondi (Ramo III): viola, perché l'ocra di prima sembrava il cuoio del canale indipendente.
        static let fondi = Color.dinamico(chiaro: Color(hex: "#7A6FB0"), scuro: Color(hex: "#A69BDB"))
        /// Fondo delle due colonne del modulo: il pozzetto dei campi.
        static let fondoColonna = Tema.Colore.pozzetto
        /// Filo attorno alle colonne.
        static let bordoColonna = Tema.Colore.separatore
        /// Avvisi: quota stimata, quota fuori dai limiti del contratto, multiramo calcolata a comparto unico.
        static let avviso = Tema.Colore.arancio
        /// Testi delle colonne: etichette dei campi e note.
        static let etichetta = Tema.Colore.inchiostroSecondario
        static let nota = Tema.Colore.inchiostroTerziario
        /// Testo della barra (quote ed euro delle due parti).
        static let testoBarra = Tema.Colore.inchiostroSecondario
        /// Quote che tornano al 100% e risultato della media ponderata.
        static let conferma = Tema.Colore.verde
        static let media = Tema.Colore.inchiostro
        /// «Togli» di una riga dei fondi.
        static let togli = Tema.Colore.Inserimento.togli
    }
}

extension Tema.Misura {
    /// Misure delle due parti di una multiramo.
    enum Multiramo {
        /// Altezza della barra a due colori e raggio dei suoi tratti.
        static let barra: CGFloat = 8
        static let raggioBarra: CGFloat = Tema.Raggio.barraCanali
        /// Stacco tra i due tratti della barra: quello della barra dei canali.
        static let staccoBarra: CGFloat = Tema.Misura.Componenti.spazioBarraCanali
        /// Spazio tra le due colonne «Gestione separata» e «Fondi», larghezza minima di una colonna
        /// (sotto due colonne minime vanno una sopra l'altra).
        static let spazioColonne: CGFloat = 16
        static let colonnaMinima: CGFloat = 230
        /// Larghezza del cursore della quota in gestione separata, passo del cursore (punti percentuali).
        static let larghezzaCursore: CGFloat = 220
        static let passoCursore: Double = 5
        /// Pallino del colore della parte, nelle testate delle colonne e nelle etichette della barra.
        static let pallino: CGFloat = 8
        /// Spazio tra le righe della sezione, tra i campi di una colonna, tra un'etichetta e il suo campo.
        static let spazioRighe: CGFloat = 12
        static let spazioCampi: CGFloat = 9
        static let spazioEtichetta: CGFloat = 3
        /// Spazio tra i controlli di una riga (cursore, campo, nota) e tra le etichette e la barra.
        static let spazioRiga: CGFloat = 10
        static let spazioBarra: CGFloat = 5
        /// Margini interni delle colonne.
        static let margineColonna = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        /// Spazio tra le coppie etichetta-campo delle parti nelle condizioni del contratto (come le righe vicine).
        static let spazioCondizioni: CGFloat = 14
        /// Tendine: SRI dei fondi, ribilanciamento.
        static let tendinaSRI: CGFloat = 140
        static let tendinaRibilanciamento: CGFloat = 340
        /// Pannello della composizione nel dettaglio: etichette delle righe, spazio sotto la barra e tra gli
        /// avvisi, margini del pulsante «Completa i dati».
        static let etichettaPannello: CGFloat = 130
        static let spazioPannello: CGFloat = 8
        static let margineAzione = EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
        /// Elenco dei fondi uno per uno (dalla versione 25 dell'archivio): larghezza minima del nome, spazio
        /// tra le righe e tra i campi di una riga, larghezza dei campi in %.
        static let nomeFondo: CGFloat = 170
        static let spazioFondi: CGFloat = 6
        static let spazioCampiFondo: CGFloat = 8
        static let campoFondo: CGFloat = 60
        /// Spazio tra la media ponderata e la sua barra.
        static let spazioMedia: CGFloat = 6
    }
}

extension Tema.Testo {
    /// Caratteri delle due parti di una multiramo.
    enum Multiramo {
        /// Testata di una colonna («Gestione separata», «Fondi»).
        static let testataColonna = Tema.Testo.Inserimento.gruppo
        /// Quota accanto alla testata e riepilogo «40% gestione separata · 60% fondi».
        static let quota = Tema.Testo.sf(12, .semibold).monospacedDigit()
        /// Etichette della barra e note.
        static let barra = Tema.Testo.didascalia
        static let nota = Tema.Testo.Inserimento.nota
        /// Intestazioni delle colonne dell'elenco dei fondi.
        static let intestazione = Tema.Testo.Inserimento.azione
        /// La riga «Media ponderata: 40% × 3,00% + 60% × 5,50% = 4,60%».
        static let media = Tema.Testo.sf(12.5, .semibold).monospacedDigit()
        /// «Togli» di una riga.
        static let azione = Tema.Testo.Inserimento.azione
    }
}

// MARK: - Dettaglio a colpo d'occhio (tessere delle parti, lordo → netto, media ponderata, gettoni)
// Il dettaglio di una multiramo e della gestione separata in cifre grandi e piccoli grafici: una tessera
// per parte con il lordo che diventa netto, la scala SRI, la garanzia come gettone; le spiegazioni nei tooltip.

extension Tema.Colore.Multiramo {
    /// Cifra principale di una tessera (il netto) e cifra negativa o in perdita.
    static let cifra = Tema.Colore.inchiostro
    static let negativo = Tema.Colore.MotoriPosizioni.negativo
    /// Gettoni: garanzia piena (verde), garanzia solo a scadenza o dati stimati (arancio), neutri.
    static let gettoneOk = Tema.Colore.MotoriPosizioni.positivo
    static let gettoneAttenzione = Tema.Colore.arancio
    static let gettoneNeutro = Tema.Colore.inchiostroSecondario
    /// Fondo dei gettoni e binario delle barre (lordo → netto, quote della media ponderata).
    static let fondoGettone = Tema.Colore.pozzetto
    static let binario = Tema.Colore.pozzetto
    /// Testo dei gettoni e didascalie sotto le cifre («lordo», «al cliente»).
    static let testoGettone = Tema.Colore.inchiostroSecondario
    static let didascalia = Tema.Colore.inchiostroSecondario
}

extension Tema.Misura.Multiramo {
    /// Tessera di una parte: margini, raggio, spazio tra le righe, larghezza minima per affiancarne due.
    static let margineTessera = Tema.Misura.Componenti.tessera
    static let raggioTessera: CGFloat = Tema.Raggio.tessera
    static let spazioTessera: CGFloat = 10
    static let spazioTessere: CGFloat = Tema.Misura.Componenti.spazioTessere
    static let tesseraMinima: CGFloat = 220
    /// Lordo → netto: spazio tra le cifre e la freccia, altezza della barra, opacità del tratto che va in costi.
    static let spazioFreccia: CGFloat = 8
    static let barraRendimento: CGFloat = 6
    static let opacitaCosto: Double = 0.3
    /// Gettoni (garanzia, ribilanciamento, azioni…): altezza, margine, spazio tra un gettone e l'altro.
    static let gettone: CGFloat = 22
    static let margineGettone: CGFloat = 8
    static let spazioGettoni: CGFloat = 6
    static let spazioIconaGettone: CGFloat = 4
    /// Media ponderata visiva: colonna del nome, barra della quota, colonne della quota e del rendimento.
    static let nomeMediaVisiva: CGFloat = 132
    static let barraMediaVisiva: CGFloat = 6
    static let quotaMediaVisiva: CGFloat = 40
    static let rendimentoMediaVisiva: CGFloat = 62
    static let spazioMediaVisiva: CGFloat = 8
    /// Spazio tra le sezioni del pannello (barra, tessere, media, gettoni).
    static let spazioSezioniPannello: CGFloat = 14
}

extension Tema.Testo.Multiramo {
    /// Il netto di una parte (cifra principale) e il lordo da cui parte, più piccolo.
    static let cifraGrande = Tema.Testo.sf(22, .semibold).monospacedDigit()
    static let cifraLordo = Tema.Testo.sf(14, .medium).monospacedDigit()
    /// Didascalie sotto le cifre («lordo», «al cliente») e nota del costo sotto la barra.
    static let didascalia = Tema.Testo.didascalia
    /// Quota di una parte nella testata della tessera («40%») e i suoi euro.
    static let quotaTessera = Tema.Testo.sf(15, .semibold).monospacedDigit()
    static let euroTessera = Tema.Testo.didascalia.monospacedDigit()
    /// Testo dei gettoni e la loro icona.
    static let gettone = Tema.Testo.chipPiccolo
    static let iconaGettone = Tema.Testo.sf(10.5, .semibold)
    /// Freccia tra lordo e netto.
    static let freccia = Tema.Testo.sf(12, .semibold)
    /// Media ponderata visiva: righe e risultato.
    static let rigaMediaVisiva = Tema.Testo.sf(12, .medium).monospacedDigit()
    static let risultatoMedia = Tema.Testo.sf(20, .semibold).monospacedDigit()
    static let titoloSezione = Tema.Testo.occhiello
    /// Cifra delle tessere dei numeri (rendimento reale, trattenuto in euro, garantito a scadenza).
    static let cifraTessera = Tema.Testo.valoreTessera.monospacedDigit()
}
