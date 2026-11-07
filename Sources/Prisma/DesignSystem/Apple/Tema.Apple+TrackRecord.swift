import SwiftUI

// Studio › Track record (versione «Orizzonte», giro 2, Design/template-novita-specifica.md §4.2): misure, caratteri,
// colori e tempi della scheda, delle card delle raccomandazioni, della pillola dell'esito e del dettaglio. Le viste
// stanno in Shell/StudioTrackRecord.swift; qui solo i valori, tutti ricavati dal tema Apple. Le cifre arrivano da
// MotoreTrackRecord (in cache in StatoShell).

extension Tema.Apple.Studio {
    enum Track {
        // MARK: Linee (uguali in chiaro e in scuro)

        /// La proposta: #30B15C (`anello1`), spessore 2,6.
        static let lineaProposta = Tema.Apple.Colore.anello1
        static let spessoreProposta: CGFloat = 2.6
        /// L'alternativa (sempre una stima): `inchiostro3`, spessore 2, tratteggiata 4 4 come la legenda «┅».
        static let lineaAlternativa = Tema.Apple.Colore.inchiostro3
        static let spessoreAlternativa: CGFloat = 2
        static let tratteggioAlternativa: [CGFloat] = [4, 4]
        /// Con molte card le ultime linee non partono dopo 1,5 s: l'indice del tracciato si ferma qui.
        static let indiceMassimoLinee = 12

        // MARK: Risultato

        static let coloreSale = Tema.Apple.Colore.verde
        static let coloreScende = Tema.Apple.Colore.rosso
        static let coloreNeutro = Tema.Apple.Colore.inchiostro2

        // MARK: Pillola dell'esito

        /// Capsula, 12 bold, padding 4×10.
        static let pillola = Tema.Apple.Carattere(dimensione: 12, peso: .bold)
        static let paddingPillola = Tema.Apple.Misura.padding(4, 10)
        /// Accettata: verde su verde al 13%; Rifiutata: rosso su rosso al 12%; Rimandata: arancio su arancio al 13%;
        /// In attesa: `inchiostro2` su `inchiostro3` al 14% (neutra).
        static let testoAccettata = Tema.Apple.Colore.verde
        static let fondoAccettata = Color(r: 47, g: 163, b: 90, a: 0.13)
        static let testoRifiutata = Tema.Apple.Colore.rosso
        static let fondoRifiutata = Color(r: 229, g: 72, b: 77, a: 0.12)
        static let testoRimandata = Tema.Apple.Colore.arancio
        static let fondoRimandata = Color(r: 224, g: 138, b: 0, a: 0.13)
        static let testoInAttesa = Tema.Apple.Colore.inchiostro2
        static let fondoInAttesa = Tema.Apple.Colore.inchiostro3.opacity(0.14)

        // MARK: Disposizione della scheda

        enum Disposizione {
            /// Le quattro tile: 4 colonne uguali, 12 fra loro (2 colonne sotto i 700 di larghezza).
            static let spazioTile: CGFloat = 12
            static let colonneTile = 4
            static let colonneTileStrette = 2
            static let larghezzaTileStrette: CGFloat = 700
            /// Riga del titolo: 18 sopra, 4 ai lati, 10 sotto; la nota a 8 dal titolo.
            static let titoloSopra: CGFloat = 18
            static let titoloLati: CGFloat = 4
            static let titoloSotto: CGFloat = 10
            static let spazioNota: CGFloat = 8
            /// Le card una sotto l'altra, 10 fra loro; 16 in fondo perché l'ombra dell'ultima non si tagli.
            static let spazioCard: CGFloat = 10
            static let fondo: CGFloat = 16
            /// Sotto questa larghezza la card perde il mini-grafico (iPad stretto, finestre piccole).
            static let larghezzaConGrafico: CGFloat = 980
            /// Cascata: tile 0-3, titolo 4, card da 5; oltre la quindicesima le card entrano insieme.
            static let primaCard = 5
            static let indiceMassimoCascata = 16
        }

        // MARK: Tile

        enum Tile {
            static let superficie = Tema.Apple.Superficie.tile
            static let raggio = Tema.Apple.Raggio.tile
            static let padding = Tema.Apple.Misura.Padding.tile
            static let etichetta = Tema.Apple.Carattere.secondario
            static let coloreEtichetta = Tema.Apple.Colore.inchiostro2
            static let valore = Tema.Apple.Carattere.valore
            static let coloreValore = Tema.Apple.Colore.inchiostro
            static let riduzioneValore: CGFloat = 0.6
            static let didascalia = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular)
            static let coloreDidascalia = Tema.Apple.Colore.inchiostro3
            static let spazio: CGFloat = 4
        }

        // MARK: Riga del titolo

        enum Titolo {
            static let titolo = Tema.Apple.Carattere.h2
            static let coloreTitolo = Tema.Apple.Colore.inchiostro
            static let nota = Tema.Apple.Carattere.secondario
            static let coloreNota = Tema.Apple.Colore.inchiostro2
            static let coloreProva = Tema.Apple.Colore.arancio
        }

        // MARK: Card di una raccomandazione

        enum Card {
            /// `.card .tilt`: raggio 22, card con l'ombra, padding 14×18, contenuto in riga a 16, inclinazione 3.
            static let superficie = Tema.Apple.Superficie.card
            static let raggio = Tema.Apple.Raggio.card
            static let padding = Tema.Apple.Misura.padding(14, 18)
            static let spazio: CGFloat = 16
            static let inclinazione = Tema.Apple.Moto.Inclinazione.massimoImpegni
            static let avatar: CGFloat = 40
            /// Il blocco del testo, largo 330: titolo 14,5 bold, sotto la riga `.k`.
            static let larghezzaTesto: CGFloat = 330
            static let titolo = Tema.Apple.Carattere(dimensione: 14.5, peso: .bold)
            static let coloreTitolo = Tema.Apple.Colore.inchiostro
            static let sotto = Tema.Apple.Carattere.secondario
            static let coloreSotto = Tema.Apple.Colore.inchiostro2
            static let spazioTesti: CGFloat = 3
            /// Il mini-grafico 300×44.
            static let grafico = CGSize(width: 300, height: 44)
            /// La colonna destra, larga 120: risultato `.v` a 20, sotto la didascalia `.k`.
            static let larghezzaDestra: CGFloat = 120
            static let risultato = Tema.Apple.Carattere(dimensione: 20, peso: .bold, tracking: -0.4, tabellare: true)
            /// «da misurare»: più sobrio della cifra.
            static let daMisurare = Tema.Apple.Carattere(dimensione: 15, peso: .semibold)
            static let didascalia = Tema.Apple.Carattere(dimensione: 11.5, peso: .regular)
            static let coloreDidascalia = Tema.Apple.Colore.inchiostro2
            static let riduzione: CGFloat = 0.7
            static let spazioDestra: CGFloat = 2
        }

        // MARK: Stato vuoto

        enum Vuoto {
            static let superficie = Tema.Apple.Superficie.cardPiatta
            static let raggio = Tema.Apple.Raggio.card
            static let padding = Tema.Apple.Misura.Padding.cardMedia
            static let larghezza: CGFloat = 600
            static let titolo = Tema.Apple.Carattere.titoloRiga
            static let coloreTitolo = Tema.Apple.Colore.inchiostro
            static let testo = Tema.Apple.Carattere.corpo
            static let coloreTesto = Tema.Apple.Colore.inchiostro2
            static let nota = Tema.Apple.Carattere.secondario
            static let coloreNota = Tema.Apple.Colore.inchiostro3
            static let spazio: CGFloat = 8
            static let pulsanteSopra: CGFloat = 14
            static let sopra: CGFloat = 4
        }

        // MARK: Dettaglio

        enum Dettaglio {
            /// 900×560: il 900×500 del template più la parte delle note (che il template non ha).
            static let misura = CGSize(width: 900, height: 560)
            /// Testata: avatar 54, spazio 14; sopra il titolo l'etichetta `.lbl`; titolo display 25 bold, −0,5, largo 700.
            static let avatar = Tema.Apple.Misura.Avatar.grande
            static let spazioTestata: CGFloat = 14
            static let etichetta = Tema.Apple.Carattere.etichetta
            static let coloreEtichetta = Tema.Apple.Colore.inchiostro2
            static let titolo = Tema.Apple.Carattere(dimensione: 25, peso: .bold, tracking: -0.5)
            static let coloreTitolo = Tema.Apple.Colore.inchiostro
            static let larghezzaTitolo: CGFloat = 700
            static let spazioEtichettaTitolo: CGFloat = 2
            /// La testata lascia lo spazio del ✕ a destra.
            static let margineChiudi: CGFloat = 44
            /// Corpo 22 sotto la testata, due colonne a 28; la destra larga 420.
            static let corpoSopra: CGFloat = 22
            static let spazioColonne: CGFloat = 28
            static let larghezzaDestra: CGFloat = 420
            /// I blocchi della colonna sinistra: `.lbl`, 6 sotto; 18 fra un blocco e l'altro.
            static let sottoEtichetta: CGFloat = 6
            static let fraBlocchi: CGFloat = 18
            /// Testi 15 con interlinea 1,5; la scelta 15 semibold.
            static let testo = Tema.Apple.Carattere(dimensione: 15, peso: .regular, interlinea: 1.5)
            static let coloreTesto = Tema.Apple.Colore.inchiostro
            static let scelta = Tema.Apple.Carattere(dimensione: 15, peso: .semibold)
            static let mancante = Tema.Apple.Colore.inchiostro3
            /// Le cifre registrate: righe 13, etichetta `inchiostro2` a sinistra, valore a destra; il filo fra loro.
            static let rigaCifre = Tema.Apple.Carattere(dimensione: 13, peso: .regular, tabellare: true)
            static let coloreEtichettaCifre = Tema.Apple.Colore.inchiostro2
            static let coloreValoreCifre = Tema.Apple.Colore.inchiostro
            static let paddingRigaCifre: CGFloat = 5
            static let filo = Tema.Apple.Colore.separatore
            /// Le frasi piccole (ricavata da Prisma, storico delle scelte, conformità).
            static let nota = Tema.Apple.Carattere.secondario
            static let coloreNota = Tema.Apple.Colore.inchiostro2
            static let notaSopra: CGFloat = 4
            /// Le note: data 11,5 `inchiostro3`, testo 14; 10 fra una nota e l'altra; il campo 10 sotto.
            static let dataNota = Tema.Apple.Carattere(dimensione: 11.5, peso: .medium, tabellare: true)
            static let coloreDataNota = Tema.Apple.Colore.inchiostro3
            static let testoNota = Tema.Apple.Carattere.corpo
            static let fraNote: CGFloat = 10
            static let campoSopra: CGFloat = 10
            static let spazioCampo: CGFloat = 8
            /// Il grafico 420×190: linee in 170, date sotto a 11 `inchiostro3`.
            static let grafico = CGSize(width: 420, height: 190)
            static let altezzaLinee: CGFloat = 170
            static let asse = Tema.Apple.Carattere.asse
            static let coloreAsse = Tema.Apple.Colore.inchiostro3
            /// Senza linee: la frase al centro del riquadro del grafico, sul fondo `tile`.
            static let fondoVuoto = Tema.Apple.Superficie.tile
            static let raggioVuoto = Tema.Apple.Raggio.tile
            static let paddingVuoto = Tema.Apple.Misura.Padding.tile
            /// Legenda 10 sotto, 12,5, voci a 16; il segno lungo 18.
            static let legendaSopra: CGFloat = 10
            static let legenda = Tema.Apple.Carattere.secondario
            static let coloreLegenda = Tema.Apple.Colore.inchiostro2
            static let spazioLegenda: CGFloat = 16
            static let segno = CGSize(width: 18, height: 2.6)
            static let spazioSegno: CGFloat = 6
            /// La cifra del risultato `.v` (26), 12 sotto la legenda, senza segno; sotto la didascalia `.k`.
            static let cifraSopra: CGFloat = 12
            static let cifra = Tema.Apple.Carattere.valore
            static let riduzioneCifra: CGFloat = 0.6
            /// Piede: «Chiudi» grande, accanto la frase della conformità; 12 fra loro, 14 sopra.
            static let piedeSopra: CGFloat = 14
            static let spazioPiede: CGFloat = 10
        }
    }
}
