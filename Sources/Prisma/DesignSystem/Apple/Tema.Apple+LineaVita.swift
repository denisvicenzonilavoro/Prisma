import SwiftUI

// Clienti › Dossier › La linea della vita (Orizzonte, giro 4; Design/template-novita-specifica.md §7.2): la card a
// tutta scheda con le tre cifre, il grafico del patrimonio da oggi a 90 anni e la linea del tempo con i gettoni
// trascinabili. La vista sta in Shell/DossierLineaVita.swift, il gettone in DesignSystem/Apple/GettoneEventoApple.swift,
// le cifre in Motori/MotoreLineaVita.swift. Qui solo i valori.

extension Tema.Apple.Clienti {
    enum LineaVita {
        typealias Colore = Tema.Apple.Colore
        typealias Carattere = Tema.Apple.Carattere

        // MARK: Card e intestazione

        /// Card intera, padding 18×24 (le altre card del dossier 20×22/24).
        static let superficie = Tema.Apple.Superficie.cardPiatta
        static let padding = Tema.Apple.Misura.padding(18, 24)
        /// `.lbl` «La linea della vita · da oggi a 90 anni» e a destra `.k` «Trascina gli eventi…».
        static let titolo = Carattere.etichetta
        static let coloreTitolo = Colore.inchiostro2
        static let suggerimento = Carattere.secondario
        static let coloreSuggerimento = Colore.inchiostro2
        static let spazioIntestazione: CGFloat = 12

        // MARK: Le tre cifre

        /// In riga a 34 l'una dall'altra, a 10 sotto il titolo: `.k` sopra e `.v` sotto.
        static let spazioCifre: CGFloat = 34
        static let sopraCifre: CGFloat = 10
        static let spazioEtichettaCifra: CGFloat = 2
        static let etichettaCifra = Carattere.secondario
        static let coloreEtichettaCifra = Colore.inchiostro2
        static let cifra = Carattere.valore
        static let coloreCifra = Colore.inchiostro
        /// «oltre i 90 anni» in verde, «fino a N anni» in rosso (fissi, uguali in scuro).
        static let coloreBasta = Colore.verde
        static let coloreFinisce = Colore.rosso
        /// «ipotesi» accanto all'età di pensione non indicata.
        static let ipotesi = Carattere(dimensione: 11, peso: .semibold)
        static let coloreIpotesi = Colore.inchiostro3

        // MARK: Il grafico

        /// A 8 sotto le cifre; area di disegno alta 130, più i 10 di margine sopra dei grafici del tema.
        static let sopraGrafico: CGFloat = 8
        static let altezzaDisegno: CGFloat = 130
        static let altezzaGrafico: CGFloat = altezzaDisegno + Tema.Apple.Grafico.Tracciato.margineAlto
        /// Scala verticale da 0 al massimo × 1,08.
        static let scala: Double = 1.08
        /// Curva viola, spessore 2,8, area con il gradiente da 0,28 a 0.
        static let coloreCurva = Colore.stima
        static let spessoreCurva: CGFloat = Tema.Apple.Grafico.Tracciato.spessore
        static let opacitaArea: Double = 0.28
        /// L'area sotto la parte indicativa (dopo la pensione senza reddito desiderato): metà.
        static let opacitaAreaIndicativa: Double = 0.14
        /// Dopo la pensione senza reddito desiderato la curva è solo indicativa: tratteggiata 6 6.
        static let tratteggioIndicativa: [CGFloat] = Tema.Apple.Grafico.Tracciato.tratteggioStima
        /// La curva si disegna dopo l'entrata della card (ritardo 0,15 del tema, indice 0).
        static let ritardoCurva: Double = 0
        /// Zona della pensione: viola al 6%, con «in pensione» 11 semibold a 8 dal bordo sinistro e dal fondo.
        static let opacitaZona: Double = 0.06
        static let scrittaZona = Carattere(dimensione: 11, peso: .semibold)
        static let coloreScrittaZona = Colore.stima
        static let margineScrittaZona: CGFloat = 8
        /// Righe verticali degli eventi: tratteggio 2 4, opacità 0,7, spesse 1.
        static let tratteggioEventi: [CGFloat] = [2, 4]
        static let opacitaEventi: Double = 0.7
        static let spessoreEventi: CGFloat = 1
        /// Il punto della fine: raggio 6 rosso sul fondo; «finisce a N anni» 12 bold centrata a 12 sopra il fondo.
        static let raggioFine: CGFloat = 6
        static let coloreFine = Colore.rosso
        static let scrittaFine = Carattere(dimensione: 12, peso: .bold)
        static let sopraScrittaFine: CGFloat = 12
        /// Sul tavolo con l'iPad il grafico è più alto (la finestra di vetro è più grande della card).
        static let altezzaGraficoTavolo: CGFloat = 240

        // MARK: Colori degli eventi

        static let coloreEntrata = Tema.Apple.GettoneEvento.coloreEntrata
        static let coloreUscita = Tema.Apple.GettoneEvento.coloreUscita
        static let colorePensione = Tema.Apple.GettoneEvento.colorePensione
        /// Evento senza cifra: grigio, fuori dal calcolo.
        static let coloreSenzaCifra = Tema.Apple.GettoneEvento.coloreSenzaCifra

        // MARK: La linea del tempo

        /// A 4 sotto il grafico, alta 104: binario alto 2 a y 78, tacche 1×10 a y 74, numeri centrati a y 92.
        static let sopraLinea: CGFloat = 4
        static let altezzaLinea: CGFloat = 104
        static let yBinario: CGFloat = 78
        static let altezzaBinario: CGFloat = 2
        static let coloreBinario = Colore.binario
        static let yTacca: CGFloat = 74
        static let tacca = CGSize(width: 1, height: 10)
        static let coloreTacca = Colore.separatore
        static let centroNumeri: CGFloat = 92
        static let numeri = Carattere.asse
        static let coloreNumeri = Colore.inchiostro3
        /// Una tacca ogni 5 anni.
        static let passoTacche = 5
        /// Gettoni su tre file sfalsate di 25 (alti 29: si toccano), centri tenuti a 70 dai bordi.
        static let file = 3
        static let passoFile: CGFloat = 25
        static let altezzaGettone: CGFloat = 29
        static let margineGettoni: CGFloat = 70

        // MARK: Sotto la linea

        /// Avvisi e righe del metodo: 12 `inchiostro2`, a 10 sotto la linea, 4 fra una riga e l'altra.
        static let sopraNote: CGFloat = 10
        static let spazioNote: CGFloat = 4
        static let nota = Carattere(dimensione: 12, peso: .regular, interlinea: 1.4)
        static let coloreNota = Colore.inchiostro2
        static let coloreAvviso = Colore.arancio
        /// Il vuoto (senza data di nascita, senza eventi): 13,5 con il pulsante sotto.
        static let vuoto = Carattere(dimensione: 13.5, peso: .regular, interlinea: 1.45)
        static let coloreVuoto = Colore.inchiostro2
        static let sopraVuoto: CGFloat = 14
        static let spazioVuoto: CGFloat = 10

        // MARK: Il foglio dell'evento (Prisma: il template non l'ha)

        static let larghezzaModulo: CGFloat = 540
        static let altezzaModulo: CGFloat = 470
        static let spazioModulo: CGFloat = 14
        static let spazioCampoModulo: CGFloat = 6
        static let larghezzaSceltaModulo: CGFloat = 260
        static let larghezzaImportoModulo: CGFloat = 120
        /// «Ogni anno per N anni»: al massimo 40.
        static let massimoAnniModulo = 40
    }
}

// MARK: - Il gettone di un evento (§7.2.3)

extension Tema.Apple {
    enum GettoneEvento {
        typealias Colore = Tema.Apple.Colore
        typealias Carattere = Tema.Apple.Carattere

        /// Capsula: padding 5×12, bordo 2 nel colore dell'evento, fondo `cardPiena`; pensione al 12% del viola.
        static let padding = Misura.padding(5, 12)
        static let bordo: CGFloat = 2
        static let fondo = Colore.cardPiena
        static let opacitaFondoPensione: Double = 0.12
        /// Nome 12,5 bold `inchiostro`, età 12,5 `inchiostro2`, a 4 l'uno dall'altra.
        static let nome = Carattere(dimensione: 12.5, peso: .bold)
        static let coloreNome = Colore.inchiostro
        static let dettaglio = Carattere(dimensione: 12.5, peso: .regular, tabellare: true)
        static let coloreDettaglio = Colore.inchiostro2
        static let spazio: CGFloat = 4
        /// Verde entrata, arancio uscita, viola pensione, grigio senza cifra (fissi, uguali in scuro).
        static let coloreEntrata = Colore.anello1
        static let coloreUscita = Colore.arancio
        static let colorePensione = Colore.stima
        static let coloreSenzaCifra = Colore.inchiostro3
        /// Ombra del gettone fermo (`--shadow`) e del gettone preso (0 16 30 −10, blu del tema al 45%).
        static let ombra = Tema.Apple.Ombra.pillola
        static let ombraPresa = StratoOmbra(colore: Color(r: 8, g: 40, b: 60, a: 0.45), y: 16, sfocatura: 30, espansione: -10)
        /// Il gettone non trascinabile (un obiettivo): bordo al 55%.
        static let opacitaFisso: Double = 0.55
    }
}

extension Tema.Apple.Moto {
    /// Il gettone della linea della vita: l'ombra della presa in 0,2 s, al rilascio un rimbalzo 1,08 → 1 in 0,35 s
    /// con la molla del tema (cubic-bezier .34 1.6 .64 1 nel template). Con «Riduci movimento» niente rimbalzo.
    enum LineaVita {
        static let durataOmbra = 0.20
        static let ombra = Animation.easeOut(duration: durataOmbra)
        static let scalaRimbalzo: CGFloat = 1.08
        static let durataRimbalzo = 0.35
        static var rimbalzo: Animation { Tema.Apple.Moto.molla(durataRimbalzo) }
    }
}
