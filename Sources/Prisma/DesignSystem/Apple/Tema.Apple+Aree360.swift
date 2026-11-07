import SwiftUI

// Analisi 360 › la griglia delle quattro aree nel tema Apple (Design/template-apple-specifica.md §4.3.1, §4.3.4,
// §4.3.5, riferimenti analisi-agenda/A01-A05, A17-A22): misure, caratteri, colori e tempi della testata con le
// pillole dei clienti, delle quattro card con l'anello, del piede con gli strumenti e dei dettagli Investimenti e
// Risparmio e liquidità (barra di composizione, blocchi dei mesi). Le viste stanno in Shell/Analisi360Apple.swift
// e Shell/Analisi360AppleDettagli.swift; qui solo i valori.

extension Tema.Apple {
    enum Aree360 {
        /// Il colore di un'area: anello, `.lbl` e cifra in evidenza.
        static func colore(_ a: AreaAnalisi) -> Color {
            switch a {
            case .previdenza: return Colore.Area.previdenza
            case .protezione: return Colore.Area.protezione
            case .investimenti: return Colore.Area.investimenti
            case .risparmio: return Colore.Area.liquidita
            }
        }

        // MARK: Disposizione

        enum Disposizione {
            /// Margini del contenuto (come la panoramica di sempre: 16 sopra, 18 ai lati e sotto).
            static let margine = EdgeInsets(top: 16, leading: 18, bottom: 18, trailing: 18)
            /// Spazio fra le card della griglia 2×2 (14 nel template).
            static let spazio: CGFloat = Misura.Spazio.griglia
            /// Testata sopra la griglia, piede sotto.
            static let testataSotto: CGFloat = 14
            static let piedeSopra: CGFloat = 14
            /// Altezza di una card: in parti uguali dello spazio che resta, fra 236 e 319 (319 nel template).
            static let altezzaMinimaArea: CGFloat = 236
            static let altezzaMassimaArea: CGFloat = 319
            /// Spazio che testata e piede tengono fuori dalla griglia, per dividere l'altezza in due righe.
            static let riservatoTestataPiede: CGFloat = 176
            /// Fondo: la carta chiara della finestra del tema.
            static let fondo = Colore.finestra
        }

        // MARK: Tempi

        enum Tempi {
            /// Cascata: 0,14 all'apertura della finestra, 0 dopo un cambio di cliente.
            static let baseApertura = Tema.Apple.Moto.Cascata.baseFinestra
            static let baseCambio: Double = 0
            /// Anelli: 0,32 all'apertura, 0,15 dopo un cambio di cliente.
            static let anelliApertura = Tema.Apple.Moto.Anello.ritardoFinestra
            static let anelliCambio = Tema.Apple.Moto.Anello.ritardoCambio
            /// Indici della cascata: testata 0, aree 1-4, piede 5.
            static let indiceTestata = 0
            static let indicePrimaArea = 1
            static let indicePiede = 5
        }

        // MARK: Testata

        enum Testata {
            static let occhiello = Carattere.etichetta
            static let coloreOcchiello = Colore.inchiostro2
            static let titolo = Carattere.h2
            static let coloreTitolo = Colore.inchiostro
            static let spazioTitolo: CGFloat = 3
            /// Riga della completezza dei dati: `.k` nel tono (verde da 85% in su, altrimenti arancio).
            static let completezza = Carattere.secondario
            static let coloreCompleti = Colore.verde
            static let coloreIncompleti = Colore.arancio
            static let completezzaSopra: CGFloat = 6
            /// Fra la riga della completezza e «Completa nella scheda del cliente ›».
            static let spazioCompletezza: CGFloat = 10
            /// Le pillole dei clienti: al massimo cinque, come nel template (poi quattro e tre se lo spazio manca).
            static let pilloleMassime = 5
            static let pilloleMinime = 3
            static let spazioPillole: CGFloat = 16
            static let avatar: CGFloat = Controlli.Segmentato.latoIcona
        }

        // MARK: Card di un'area

        enum Area {
            static let padding = EdgeInsets(top: 24, leading: 26, bottom: 24, trailing: 26)
            static let raggio = Raggio.card
            static let superficie = Superficie.card
            /// Inclinazione delle aree: 5 gradi.
            static let inclinazione = Moto.Inclinazione.massimoAree
            /// Anello 170/17 (più piccolo se la card è bassa o stretta, mai sotto 110), 28 dal testo.
            static let anello = Grafico.Anello.aree
            static let anelloMinimo: CGFloat = 110
            /// Quota massima della larghezza interna che l'anello può prendere.
            static let quotaAnello: CGFloat = 0.36
            static let spazioAnello: CGFloat = 28
            /// Al centro 36 bold, 24 se il testo è più lungo di 5 caratteri («3,5 mesi»).
            static let centro = Carattere.centroAnello(36)
            static let centroLungo = Carattere.centroAnello(24)
            static let lunghezzaCentroCorto = 5
            static let coloreCentro = Colore.inchiostro
            static let coloreTrattino = Colore.inchiostro3
            /// `.lbl` nel colore dell'area, con la priorità del cliente accanto.
            static let etichetta = Carattere.etichetta
            static let priorita = Carattere(dimensione: 11.5, peso: .semibold)
            static let colorePriorita = Colore.arancio
            static let spazioEtichetta: CGFloat = 8
            /// Titolo 26 bold «{grande} {testo}», 4 sotto l'etichetta.
            static let titolo = Carattere(dimensione: 26, peso: .bold, tracking: -0.5)
            static let coloreTitolo = Colore.inchiostro
            static let titoloSopra: CGFloat = 4
            static let riduzioneTitolo: CGFloat = 0.7
            /// Descrizione 14,5 `inchiostro2` (interlinea 1,45, al massimo 380 di larghezza), 6 sotto il titolo.
            static let descrizione = Carattere(dimensione: 14.5, peso: .regular, interlinea: 1.45)
            static let coloreDescrizione = Colore.inchiostro2
            static let larghezzaDescrizione: CGFloat = 380
            static let descrizioneSopra: CGFloat = 6
            /// 4 righe: con 3 la descrizione degli investimenti finiva con «…» («118.134 € ne…»).
            static let righeDescrizione = 4
            /// Stato delle ipotesi e canali in essere: `.k` 12,5, 10 sopra.
            static let stato = Carattere.secondario
            static let coloreStimate = Colore.arancio
            static let coloreConfermate = Colore.verde
            static let coloreDaVerificare = Colore.inchiostro2
            static let statoSopra: CGFloat = 10
            static let spazioStato: CGFloat = 6
            /// Collegamento 13 semibold blu, 12 sopra.
            static let collegamento = Carattere(dimensione: 13, peso: .semibold)
            static let coloreCollegamento = Colore.accento
            static let collegamentoSopra: CGFloat = 12
        }

        // MARK: Piede

        enum Piede {
            /// La nota sulle ipotesi che si sovrappongono: `.k`, accanto «Prepara l'incontro».
            static let nota = Carattere(dimensione: 12.5, peso: .regular, interlinea: 1.4)
            static let coloreNota = Colore.inchiostro2
            /// La riga «Strumenti»: `.lbl` e i pulsanti di simulatore, scenari, confronto e TFR.
            static let etichetta = Carattere.etichetta
            static let coloreEtichetta = Colore.inchiostro2
            static let spazioPulsanti: CGFloat = 8
            static let spazioRighe: CGFloat = 12
            static let spazioEtichetta: CGFloat = 12
            /// Fra la nota e «Prepara l'incontro».
            static let spazioNota: CGFloat = 18
        }

        // MARK: Dettagli (Investimenti 900×480, Risparmio e liquidità 900×440)

        enum Dettaglio {
            static let misuraInvestimenti = Misura.DettaglioAperto.investimenti
            static let misuraLiquidita = Misura.DettaglioAperto.liquidita
            /// `.lbl` «AREA · Nome Cognome» nel colore dell'area e titolo 28 bold, con 56 a destra per la ✕.
            static let etichetta = Carattere.etichetta
            static let titolo = Carattere.titoloDettaglio(28)
            static let coloreTitolo = Colore.inchiostro
            static let margineChiudi: CGFloat = 56
            static let spazioTitolo: CGFloat = 4
            /// Fra il titolo e «Apri l'analisi completa ›».
            static let spazioTestata: CGFloat = 12
            static let riduzioneTitolo: CGFloat = 0.7
            /// Cifre `.k` + `.v` (26 bold), 40 fra l'una e l'altra, 24 sopra la riga.
            static let etichettaCifra = Carattere.secondario
            static let coloreEtichettaCifra = Colore.inchiostro2
            static let cifra = Carattere.valore
            static let coloreCifra = Colore.inchiostro
            static let spazioCifre: CGFloat = 40
            static let cifreSopra: CGFloat = 24
            static let spazioEtichettaCifra: CGFloat = 2
            /// Le ipotesi scritte sotto i risultati: `.k` 12 `inchiostro2`, al massimo due righe, 14 sopra.
            static let ipotesi = Carattere(dimensione: 12, peso: .regular, interlinea: 1.35)
            static let coloreIpotesi = Colore.inchiostro2
            static let ipotesiSopra: CGFloat = 14
            static let righeIpotesi = 3
            /// Piede: pulsanti grandi a 8 l'uno dall'altro; nota `.k` a destra.
            static let spazioPulsanti: CGFloat = 8
            static let piedeSopra: CGFloat = 16
            static let nota = Carattere.secondario
            static let coloreNota = Colore.inchiostro2
            /// Vuoto (nessuna posizione finanziaria): corpo 14,5 `inchiostro2`, 26 sopra.
            static let vuoto = Carattere.corpoGrande
            static let coloreVuoto = Colore.inchiostro2
            static let vuotoSopra: CGFloat = 26
        }

        // MARK: Composizione (Investimenti)

        enum Composizione {
            /// La barra di composizione: 26 sopra, 18 sotto (alta 22, pezzi di raggio 6).
            static let barraSopra: CGFloat = 26
            static let barraSotto: CGFloat = 18
            /// Indice della barra nella sequenza (ritardi 0,15 / 0,24 / 0,33 / 0,42).
            static let indiceBarra = 0
            /// Quattro tile con spazio 12: pallino 10, nome `.k`, quota `.v` che conta e i canali sotto.
            static let spazioTile: CGFloat = 12
            static let paddingTile = Misura.Padding.tile
            static let superficieTile = Superficie.tile
            static let pallino: CGFloat = 10
            static let spazioPallino: CGFloat = 7
            static let quota = Carattere.valore
            static let quotaSopra: CGFloat = 4
            /// Le cifre di ciascun canale sotto la quota: 11,5 semibold nel colore del canale.
            static let canale = Carattere(dimensione: 11.5, peso: .semibold, tabellare: true)
            static let canaleSopra: CGFloat = 4
            static let spazioCanali: CGFloat = 2
            static let coloreNessuno = Colore.inchiostro3

            static func colore(_ c: ComposizioneInvestimenti360.Classe) -> Color {
                switch c {
                case .azionario: return Colore.Composizione.azionario
                case .obbligazionario: return Colore.Composizione.obbligazionario
                case .gestioneSeparata: return Colore.Composizione.gestioneSeparata
                case .liquidita: return Colore.Composizione.liquidita
                }
            }
        }

        // MARK: Blocchi dei mesi (Risparmio e liquidità, §2.22)

        enum Mesi {
            /// 12 blocchi (di più se la soglia delle ipotesi supera i 12 mesi, fino a 24), spazio 6, alti 90, raggio 12.
            static let blocchi = 12
            static let blocchiMassimi = 24
            static let spazio: CGFloat = 6
            static let altezza: CGFloat = 90
            static let raggio: CGFloat = Raggio.giorno
            static let pieno = Colore.Area.liquidita
            static let vuoto = Colore.binario
            /// 30 sopra, 14 fra i blocchi e la riga «1 mese · soglia · 12 mesi».
            static let sopra: CGFloat = 30
            static let sotto: CGFloat = 14
            static let etichetta = Carattere.secondario
            static let coloreEtichetta = Colore.inchiostro2
            static let soglia = Carattere(dimensione: 12.5, peso: .semibold)
            static let coloreSoglia = Colore.Area.liquidita
            /// Da scala y 0,2 e opacità 0, con la molla di 0,5 s, ritardo 0,2 + i·0,06, ancorati al centro.
            static let scalaIniziale = Moto.BlocchiMese.scalaIniziale
            static var animazione: Animation { Moto.BlocchiMese.ripiego.animazione }
            static func ritardo(_ i: Int) -> Double { Moto.BlocchiMese.ritardo(indice: i) }
        }
    }
}
