import SwiftUI

// Pratiche › Dopo la firma (Design/template-luce-specifica.md §7.3.2-§7.3.3, «Luce» giro 3): misure, colori, caratteri e
// tempi della scheda a tutta larghezza (tre tile, una card per pratica con la linea dei passi, il dettaglio che nasce
// dalla card). Le viste stanno in Shell/PraticheDopoFirma.swift; qui solo i valori, ricavati dal tema Apple.

extension Tema.Apple {
    enum PraticheDopo {
        typealias C = Tema.Apple.Colore
        typealias K = Tema.Apple.Carattere

        // MARK: Tile (§7.3.2)

        /// Tre tile in riga, spazio 12, 14 sotto.
        static let spazioTile: CGFloat = 12
        static let sottoTile: CGFloat = 14
        static let paddingTile = Tema.Apple.Misura.Padding.tile
        static let superficieTile = Tema.Apple.Superficie.tile
        static let etichettaTile = K.secondario
        static let coloreEtichettaTile = C.inchiostro2
        /// Il numero (26, contato da 0).
        static let numeroTile = K.valore
        static let spazioDentroTile: CGFloat = 4
        /// La tile scelta come filtro: bordo blu.
        static let bordoTileScelta = C.accento.opacity(0.55)
        static let spessoreTileScelta: CGFloat = 1.5

        // MARK: Card di una pratica (§7.3.2)

        /// Padding 16/20, 10 fra le card, nessuna ombra, raggio 22.
        static let paddingCard = Tema.Apple.Misura.padding(16, 20)
        static let spazioCard: CGFloat = 10
        static let superficieCard = Tema.Apple.Superficie.cardPiatta
        static let raggioCard = Tema.Apple.Raggio.card
        /// Pratica ferma: bordo rosso al 40% e fondo rosso al 5%.
        static let bordoFerma = C.rosso.opacity(0.4)
        static let fondoFerma = C.rosso.opacity(0.05)
        static let spessoreBordo = Tema.Apple.Misura.bordo
        /// Dentro la card: una riga con spazio 12.
        static let spazioRiga: CGFloat = 12
        static let avatar: CGFloat = 40
        static let colonnaNome: CGFloat = 260
        static let colonnaCanale: CGFloat = 130
        static let colonnaStato: CGFloat = 210
        static let margineLinea: CGFloat = 20
        /// Sotto questa larghezza della scheda il canale va sotto il nome (la colonna del canale sparisce).
        static let larghezzaCompatta: CGFloat = 1100
        static let nome = K.titoloRiga
        static let prodotto = K.secondario
        static let spazioNome: CGFloat = 2
        /// Lo stato a destra: 13,5 grassetto; la nota sotto, 12 secondaria.
        static let stato = K(dimensione: 13.5, peso: .bold, tabellare: true)
        static let nota = K(dimensione: 12, peso: .regular)
        static let spazioStato: CGFloat = 2
        static let sopraPulsante: CGFloat = 6
        /// «Sollecita»: pulsante primario piccolo, padding 5/12.
        static let paddingPulsante = Tema.Apple.Misura.padding(5, 12)
        static let caratterePulsante = K.pulsante
        static let colorePronto = C.verde
        static let opacitaPremuto = 0.85

        // MARK: Passi (§7.3.2)

        /// Pallino 14 con bordo 2, 6 fra pallino ed etichetta, filo 2 al centro del pallino.
        static let pallino: CGFloat = 14
        static let bordoPallino: CGFloat = 2
        static let filo: CGFloat = 2
        static let distanzaEtichetta: CGFloat = 6
        static let etichetta = K(dimensione: 10.5, peso: .regular, interlinea: 1.25)
        static let etichettaAdesso = K(dimensione: 10.5, peso: .semibold, interlinea: 1.25)
        static let etichettaBloccato = K(dimensione: 10.5, peso: .bold, interlinea: 1.25)
        static let colorePallinoVuoto = C.cardPiena
        static let coloreBinario = C.binario
        static let coloreFatto = C.verde
        static let coloreAdesso = C.accento
        static let coloreBloccato = C.rosso
        static let etichettaFutura = C.inchiostro3
        static let etichettaFatta = C.inchiostro2
        /// Alone di 4 attorno al passo di adesso (blu al 18%) e al passo bloccato (rosso al 20%).
        static let spessoreAlone: CGFloat = 4
        static let aloneAdesso = C.accento.opacity(0.18)
        static let aloneBloccato = C.rosso.opacity(0.2)

        // MARK: Stati vuoti

        static let tasselloVuoto: CGFloat = 64
        static let larghezzaVuoto: CGFloat = 440
        static let paddingVuoto = Tema.Apple.Misura.padding(28, 30)
        static let spazioVuoto: CGFloat = 12
        static let tuttoInOrdine = K.titoloRiga
        static let coloreTuttoInOrdine = C.verde
        /// «dati di prova» accanto al titolo della scheda.
        static let etichettaProva = K.sottotitolo
        static let coloreProva = C.inchiostro3
        static let titoloScheda = K.etichetta
        static let coloreTitoloScheda = C.inchiostro2
        static let sottoTitoloScheda: CGFloat = 10
        static let sopraSezione: CGFloat = 18

        // MARK: Dettaglio (nasce dalla card)

        enum Dettaglio {
            static let misura = CGSize(width: 900, height: 560)
            static let avatar = Tema.Apple.Misura.Avatar.grande
            static let nome = K(dimensione: 24, peso: .bold, tracking: -0.5)
            static let occhiello = K.etichetta
            /// 56 dal bordo destro per lasciare il ✕.
            static let margineChiudi: CGFloat = 56
            static let spazioIntestazione: CGFloat = 16
            static let sopraPassi: CGFloat = 18
            static let spazioPassi: CGFloat = 8
            static let paddingPasso = Tema.Apple.Misura.padding(8, 12)
            static let raggioPasso = Tema.Apple.Raggio.voce
            static let fondoPasso = C.chip
            static let titoloPasso = K.barraTitolo
            static let righePasso = K.secondario
            static let colonnaSinistra: CGFloat = 480
            static let spazioPallino: CGFloat = 10
            static let spazioRighePasso: CGFloat = 2
            /// Il pallino al centro della prima riga del titolo del passo.
            static let allineaPallino: CGFloat = 5
            static let spazioControlli: CGFloat = 8
            static let spazioPopover: CGFloat = 10
            static let larghezzaPopover: CGFloat = 280
            static let spazioColonne: CGFloat = 22
            static let titoloSezione = K.etichetta
            static let spazioSezione: CGFloat = 8
            static let sopraSezione: CGFloat = 16
            static let notaTesto = K.corpo
            static let notaData = K.secondario
            static let selettoreData: CGFloat = 120
        }

        // MARK: Movimento (§7.3.3)

        enum Moto {
            /// Tile e card a cascata dentro l'app.
            static let baseCascata = Tema.Apple.Moto.Cascata.baseDentroApp
            /// Ogni passo da y +6 e opacità 0, 0,40 s con `--out`, dopo 0,20 + i·0,025 s (i su tutta la pagina, al
            /// massimo 36: la cascata dei passi finisce entro 1,1 s circa).
            static let basePassi = 0.20
            static let passoPassi = 0.025
            static let durataPassi = 0.40
            static let spostamentoPassi: CGFloat = 6
            static let massimoIndice = 36
            static let entrataPasso = Tema.Apple.Moto.StileEntrata(durata: durataPassi, curva: .uscita, spostamentoX: 0,
                                                                   spostamentoY: spostamentoPassi, scala: 1, sfocatura: 0)
            static func ritardoPasso(_ i: Int) -> Double { basePassi + Double(min(i, massimoIndice)) * passoPassi }
        }
    }
}
