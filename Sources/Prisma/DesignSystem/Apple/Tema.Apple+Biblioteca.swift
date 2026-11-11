import SwiftUI

// Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.2-§8.1.3, «Luce» giro 6): misure, caratteri,
// colori e tempi della barra dei documenti, della domanda, della risposta e del foglio con l'evidenziatore. Le viste
// stanno in Shell/AppBiblioteca.swift e Shell/FoglioBiblioteca.swift. Il foglio è carta bianca in chiaro e in scuro
// (regola dei documenti): colori fissi.

extension Tema.Apple {
    enum Biblioteca {
        typealias K = Tema.Apple.Carattere
        typealias C = Tema.Apple.Colore

        // MARK: Colonne (§8.1.2.2)

        static let larghezzaLaterale: CGFloat = 310
        static let spazioLaterale: CGFloat = 16
        static let larghezzaRisposta: CGFloat = 380
        static let spazioColonne: CGFloat = 18
        static let margine = Tema.Apple.Misura.Finestra.margineContenuto
        /// La colonna della risposta si stringe fino a qui (finestra a 1100); sotto, la risposta va sopra il foglio.
        static let rispostaMinima: CGFloat = 300
        /// Il vassoio sotto la risposta nella finestra stretta.
        static let altezzaVassoioStretto: CGFloat = 620

        // MARK: Barra laterale «I documenti»

        static let superficieLaterale = Tema.Apple.Superficie.pannello
        static let raggioLaterale = Tema.Apple.Raggio.pannello
        static let paddingLaterale = Tema.Apple.Misura.Padding.barraLaterale
        static let etichetta = K.etichetta
        static let coloreEtichetta = C.inchiostro2
        static let raggioVoce = Tema.Apple.Raggio.voce
        static let paddingVoce: CGFloat = 10
        static let spazioVoce: CGFloat = 10
        static let fondoVoceAccesa = C.selezioneVoce
        static let latoTassello: CGFloat = 32
        static let titoloDocumento = K(dimensione: 13, peso: .bold, interlinea: 1.3)
        static let dettaglioDocumento = K(dimensione: 12, peso: .regular)
        static let coloreTitolo = C.inchiostro
        static let coloreDettaglio = C.inchiostro2
        static let coloreAvviso = C.arancio
        static let didascalia = K(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let coloreDidascalia = C.inchiostro2
        static let anelloLettura: CGFloat = 14
        static let spessoreAnello: CGFloat = 2
        static let coloreAnello = C.accento
        static let fondoRilascio = C.selezioneVoce
        static let bordoRilascio = C.accento

        /// Il tassello del documento: blu Alleanza e cuoio dell'indipendente nella versione chiara fissa (il template
        /// non li cambia nello scuro); grigio (`Carta.etichetta`) per normativa e circolari, che non sono di un canale.
        static func tassello(canale: Canale?) -> Color {
            switch canale {
            case .alleanza?: return Color(hex: "#2563EB")
            case .indipendente?: return Color(hex: "#B06E12")
            case nil: return Tema.Apple.Carta.etichetta
            }
        }

        // MARK: Domanda (§8.1.1.3)

        static let fondoDomanda = C.cardPiena
        static let bordoDomanda = C.separatore
        static let ombraDomanda = Tema.Apple.Ombra.card
        static let paddingDomanda = EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 6)
        static let altezzaDomanda: CGFloat = 46
        static let campoDomanda = K(dimensione: 15, peso: .regular)
        static let sferaDomanda: CGFloat = 24
        static let spazioSfera: CGFloat = 10
        static let sottoDomanda: CGFloat = 12
        static let spazioSuggerimenti: CGFloat = 8
        static let sopraRisposta: CGFloat = 18
        static let invito = K(dimensione: 15, peso: .regular, interlinea: 1.45)
        static let coloreInvito = C.inchiostro2
        static let sopraInvito: CGFloat = 120

        // MARK: Risposta (§8.1.1.4)

        static let superficieRisposta = Tema.Apple.Superficie.tile
        static let paddingRisposta = Tema.Apple.Misura.Padding.cardPiccola
        static let sferaRisposta: CGFloat = 22
        static let nomeVera = K(dimensione: 14, peso: .bold)
        static let notaCercate = K.secondario
        static let risposta = K(dimensione: 16, peso: .regular, interlinea: 1.55)
        static let coloreRisposta = C.inchiostro
        static let minimoRisposta: CGFloat = 96
        static let sopraChip: CGFloat = 12
        static let spazioChip: CGFloat = 6
        static let chip = K(dimensione: 13, peso: .semibold)
        static let paddingChip = Tema.Apple.Misura.padding(7, 14)
        static let fondoChip = C.cardPiena
        static let bordoChip = C.separatore
        static let glifoChip: CGFloat = 20
        /// La chip gialla della pagina: `rgba(255,204,0,.18)` col filo `rgba(200,150,0,.3)`.
        static let fondoPagina = Color(r: 255, g: 204, b: 0, a: 0.18)
        static let bordoPagina = Color(r: 200, g: 150, b: 0, a: 0.30)
        static let testoPagina = C.inchiostro
        static let sottoTile: CGFloat = 12
        static let spazioPulsanti: CGFloat = 8
        static let nota = K(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let coloreNota = C.inchiostro2
        /// L'avviso sui parametri di Prisma superati (decisione 7 della Biblioteca).
        static let fondoAvviso = C.arancio.opacity(0.12)
        static let testoAvviso = K(dimensione: 12.5, peso: .medium, interlinea: 1.4)
        static let coloreTestoAvviso = C.inchiostro
        static let raggioAvviso = Tema.Apple.Raggio.giorno
        static let paddingAvviso = Tema.Apple.Misura.padding(10, 12)

        // MARK: Vassoio e foglio

        static let fondoVassoio = C.chip
        static let raggioVassoio = Tema.Apple.Raggio.pannello
        static let sopraContatore: CGFloat = 12
        static let contatore = K(dimensione: 12, peso: .semibold, tabellare: true)
        static let paddingContatore = Tema.Apple.Misura.padding(4, 12)
        static let fondoContatore = C.cardPiena
        static let margineFoglio: CGFloat = 46
        static let larghezzaFoglio: CGFloat = 600
        static let altezzaFoglio: CGFloat = 848
        static let scalaFoglio: CGFloat = 0.78
        static let scalaMinima: CGFloat = 0.6
        static let latiVassoio: CGFloat = 24
        static let paddingFoglio = EdgeInsets(top: 40, leading: 46, bottom: 40, trailing: 46)
        static let intestazioneFoglio = K(dimensione: 10, peso: .regular)
        static let coloreIntestazione = Tema.Apple.Carta.piede
        static let filettoFoglio = Tema.Apple.Carta.filetto
        static let sottoIntestazione: CGFloat = 22
        static let titoloArticolo = K(dimensione: 15, peso: .bold)
        static let coloreTitoloArticolo = Tema.Apple.Carta.testo
        static let paragrafo = K(dimensione: 13.5, peso: .regular, interlinea: 1.7)
        /// Altezza di una riga del paragrafo (13,5 × 1,7): le righe dell'evidenziatore.
        static let rigaParagrafo: CGFloat = 13.5 * 1.7
        static let coloreParagrafo = Tema.Apple.Carta.testoCorrente
        static let spazioParagrafi: CGFloat = 14
        static let omesso = K(dimensione: 13.5, peso: .regular)
        /// L'evidenziatore giallo `rgba(255,214,10,.55)`, raggio 3; il testo evidenziato #14202B.
        static let evidenzia = Color(r: 255, g: 214, b: 10, a: 0.55)
        static let raggioEvidenzia: CGFloat = 3
        static let testoEvidenziato = Tema.Apple.Carta.testo
        /// I passi trovati quando Vera non c'è: lo stesso giallo, più tenue.
        static let evidenziaPasso = Color(r: 255, g: 214, b: 10, a: 0.30)
        static let frecciaPagina = K(dimensione: 13, peso: .semibold)

        // MARK: Mostra al cliente

        static let formatoPresentazione = CGSize(width: larghezzaFoglio, height: altezzaFoglio)

        // MARK: Movimento

        static let baseCascata = Tema.Apple.Moto.Cascata.baseDentroApp
    }
}

extension Tema.Apple.Moto {
    /// Il contatore delle pagine da 1 alla pagina trovata in 0,90 s con la cubica entra-esci; intanto il foglio oscilla
    /// in verticale di ±4 (`sin(30·t)·4`), poi arriva passando da opacità 0,4 a 1 in 0,30 s (§8.1.3).
    enum GiroPagine {
        static let durata = 0.90
        static let curva = Curva(x1: 0.65, y1: 0, x2: 0.35, y2: 1)
        static let oscillazione: CGFloat = 4
        static let frequenza: Double = 30
        static let durataArrivo = 0.30
        static let opacitaGiro: Double = 0.4
        static var animazione: Animation { curva.animazione(durata) }
        static var arrivo: Animation { Curva.easeOut.animazione(durataArrivo).ritardoPrisma(durata) }
    }

    /// L'evidenziatore si stende da sinistra a destra in 1,30 s con la curva `uscita`: ogni riga dopo la precedente,
    /// con la durata divisa per le righe (§8.1.3).
    enum Evidenzia {
        static let durata = 1.30
        static let curva = Curva.uscita
        /// Parte quando il foglio è arrivato.
        static let ritardo = GiroPagine.durata
        static var animazione: Animation { curva.animazione(durata).ritardoPrisma(ritardo) }
    }
}
