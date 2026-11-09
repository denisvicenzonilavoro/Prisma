import SwiftUI

// Il film del piano («Luce» giro 15, Design/template-luce-specifica.md §3.2.2 e §3.2.3): le misure dello schermo del film
// (in punti del film a 880×495; nel video 1920×1080 si moltiplicano per 1920/880, così video e anteprima sono identici),
// i colori fissi (lo schermo è sempre scuro, in chiaro e in scuro), i comandi sotto lo schermo, la tile dell'esportazione
// e i tempi del movimento. `DisegnoFilm` (Core Graphics, anche fuori dal thread principale) legge da qui numeri puri:
// caratteri come `TestoFilm` (dimensione, peso di sistema, spaziatura, opacità) e colori come `ColoreFilm`.

/// Un gradino di testo del film per Core Text: dimensione in punti del film, peso di sistema (`PesoFilm`), spaziatura,
/// opacità del bianco, interlinea (multiplo della dimensione) e cifre tabellari.
struct TestoFilm: Equatable, Sendable {
    let dimensione: CGFloat
    let peso: CGFloat
    var tracking: CGFloat = 0
    var opacita: Double = 1
    var interlinea: CGFloat? = nil
    var tabellare = false
}

/// I pesi del carattere di sistema come numeri (`NSFont.Weight`/`UIFont.Weight.rawValue`).
enum PesoFilm {
    static let regolare: CGFloat = 0
    static let medio: CGFloat = 0.23
    static let semigrassetto: CGFloat = 0.3
    static let grassetto: CGFloat = 0.4
}

extension Tema.Apple.SalaRacconti {
    enum Film {
        typealias K = Tema.Apple.Carattere
        typealias C = Tema.Apple.Colore

        // MARK: Lo schermo (880×495, raggio 18, a 22 dall'alto)

        static let formato = CGSize(width: 880, height: 495)
        static let raggio: CGFloat = 18
        static let sopra: CGFloat = 22
        /// Fondo radiale 700×400 al 50%/40%: #1D3447 → #0A121A.
        static let fondoCentro = ColoreFilm.hex("#1D3447")
        static let fondoBordo = ColoreFilm.hex("#0A121A")
        static let raggiFondo = CGSize(width: 700, height: 400)
        static let centroFondo = CGPoint(x: 0.5, y: 0.4)
        /// Ombra `0 30px 60px -20px rgba(0,0,0,.5)` (costanti di `.shadow`, senza un caso nuovo di `Tema.Apple.Ombra`).
        static let ombraColore = Color.black.opacity(0.5)
        static let ombraRaggio: CGFloat = 24
        static let ombraY: CGFloat = 30
        /// Il testo è bianco; la curva, la pensione e il punto finale lavanda (#C4B5FD).
        static let testo = ColoreFilm.hex("#FFFFFF")
        static let lavanda = ColoreFilm.hex("#C4B5FD")
        /// Il binario degli anelli: bianco al 12%.
        static let opacitaBinarioAnello: Double = 0.12
        /// Colori dei canali sul fondo scuro (decisione 118): Alleanza #6B95FF, indipendente #D0954A, più la parola.
        static let canaleAlleanza = ColoreFilm.hex("#6B95FF")
        static let canaleIndipendente = ColoreFilm.hex("#D0954A")

        // MARK: Scena 0 · il titolo

        static let logo: CGFloat = 84
        static let opacitaSpicchi: [Double] = [1, 0.66, 0.38]
        static let sottoLogo: CGFloat = 26
        static let titolo = TestoFilm(dimensione: 52, peso: PesoFilm.grassetto, tracking: -1.5)
        static let sottoTitolo: CGFloat = 6
        static let data = TestoFilm(dimensione: 18, peso: PesoFilm.regolare, opacita: 0.6)

        // MARK: Scena 1 · oggi

        static let occhiello = TestoFilm(dimensione: 14, peso: PesoFilm.grassetto, tracking: 2, opacita: 0.6)
        static let sottoOcchiello: CGFloat = 22
        static let anello: CGFloat = 150
        static let spessoreAnello: CGFloat = 15
        static let spazioAnelli: CGFloat = 46
        static let percentuale = TestoFilm(dimensione: 32, peso: PesoFilm.grassetto, tabellare: true)
        static let sottoAnello: CGFloat = 10
        static let nomeObiettivo = TestoFilm(dimensione: 16, peso: PesoFilm.regolare, opacita: 0.85)
        /// Il nome sotto l'anello va a capo dentro la larghezza dell'anello più metà dello spazio.
        static let larghezzaNome: CGFloat = 180

        // MARK: Scena 2 · ogni mese

        static let sottoOcchielloCifra: CGFloat = 8
        static let cifraMese = TestoFilm(dimensione: 110, peso: PesoFilm.grassetto, tracking: -4, interlinea: 1.05, tabellare: true)
        static let perObiettivo = TestoFilm(dimensione: 20, peso: PesoFilm.regolare, opacita: 0.8)
        static let sottoPerObiettivo: CGFloat = 26
        static let pensione = TestoFilm(dimensione: 34, peso: PesoFilm.grassetto)

        // MARK: Scena 3 · il futuro

        static let occhielloFuturo = CGPoint(x: 60, y: 46)
        /// L'area della curva: x 60-820, y 80-380; margine sopra il massimo del 12%.
        static let areaCurva = CGRect(x: 60, y: 80, width: 760, height: 300)
        static let margineMassimo: Double = 0.12
        static let spessoreCurva: CGFloat = 4
        static let puntoCurva: CGFloat = 8
        static let etichettaPunto = TestoFilm(dimensione: 17, peso: PesoFilm.grassetto)
        static let sopraEtichettaPunto: CGFloat = 20
        static let etichettaFine = TestoFilm(dimensione: 22, peso: PesoFilm.grassetto)
        static let lontanoEtichettaFine: CGFloat = 14

        // MARK: Scena 4 · la chiusura

        static let chiusura = TestoFilm(dimensione: 56, peso: PesoFilm.grassetto, tracking: -1.5)
        static let sottoChiusura: CGFloat = 14
        static let firma = TestoFilm(dimensione: 18, peso: PesoFilm.regolare, opacita: 0.75)
        static let spazioFirme: CGFloat = 6
        static let sopraAvvertenza: CGFloat = 40
        static let avvertenza = TestoFilm(dimensione: 12, peso: PesoFilm.regolare, opacita: 0.5, interlinea: 1.5)
        static let larghezzaAvvertenza: CGFloat = 560

        // MARK: Sottotitolo e angolo dei dati di prova

        static let sottotitolo = TestoFilm(dimensione: 17, peso: PesoFilm.medio)
        static let sottoSottotitolo: CGFloat = 22
        static let ombraSottotitolo = (y: CGFloat(2), raggio: CGFloat(8), opacita: 0.6)
        static let datiDiProva = TestoFilm(dimensione: 12, peso: PesoFilm.grassetto, tracking: 1.5, opacita: 0.55)
        static let angoloDatiDiProva = CGPoint(x: 24, y: 22)

        // MARK: I comandi (10 sotto lo schermo, spazio 12)

        static let sottoSchermo: CGFloat = 10
        static let spazioComandi: CGFloat = 12
        static let pulsanteTondo: CGFloat = 38
        static let fondoPulsanteTondo = C.chip
        static let simboloPulsante = K(dimensione: 14, peso: .bold)
        static let coloreSimbolo = C.inchiostro
        static let altezzaBarra: CGFloat = 6
        static let raggioBarra: CGFloat = 9
        static let binarioBarra = C.binario
        static let riempimentoBarra = C.accento
        /// L'area del clic della barra (più alta della barra disegnata).
        static let areaBarra: CGFloat = 22
        static let tempo = K(dimensione: 13, peso: .medium, tabellare: true)
        static let coloreTempo = C.inchiostro2
        static let larghezzaTempo: CGFloat = 84
        /// Spazio minimo riservato sotto lo schermo (comandi, tile, note): lo schermo si riduce se il palco è basso.
        static let riservaSotto: CGFloat = 176
        static let scalaMinima: CGFloat = 0.6

        // MARK: La tile dell'esportazione (sotto i comandi)

        static let sopraTile: CGFloat = 12
        static let larghezzaTile: CGFloat = 340
        static let tile = Tema.Apple.Superficie.tile
        static let raggioTile = Tema.Apple.Raggio.tile
        static let paddingTile = Tema.Apple.Misura.Padding.tile
        static let spazioTile: CGFloat = 6
        static let testoTile = K(dimensione: 13, peso: .bold)
        static let coloreTestoTile = C.inchiostro
        static let dettaglioTile = K.secondario
        static let coloreDettaglio = C.inchiostro2
        static let colorePronto = C.verde
        static let bordoPronto = C.verde.opacity(0.4)
        static let coloreErrore = C.rosso
        static let bordoErrore = C.rosso.opacity(0.4)
        static let spessoreBordo: CGFloat = 1.5
        static let altezzaBarraTile: CGFloat = 8
        static let raggioBarraTile: CGFloat = 9

        // MARK: Note e stato vuoto

        static let sopraNote: CGFloat = 10
        static let spazioNote: CGFloat = 4
        static let nota = K(dimensione: 12.5, peso: .regular, interlinea: 1.45)
        static let coloreNota = C.inchiostro2
        static let coloreAvviso = C.scadenza
        static let vuoto = K(dimensione: 17, peso: .semibold, interlinea: 1.4)
        static let coloreVuoto = C.inchiostro
        static let larghezzaVuoto: CGFloat = 520
        static let spazioVuoto: CGFloat = 14
    }
}

extension Tema.Apple.Moto {
    /// I tempi del film (§3.2.3): una funzione pura del tempo li applica in `DisegnoFilm`, mai animazioni di SwiftUI.
    enum Film {
        /// Elementi principali (`.fA`): 0,90 s, passo 0,22, da y +24, scala 0,97 (la sfocatura 8 si approssima con
        /// opacità e scala: un `CGContext` non sfoca), curva `uscita`.
        enum Elemento {
            static let durata = 0.90
            static let passo = 0.22
            static let spostamento: CGFloat = 24
            static let scala: CGFloat = 0.97
            static let sfocatura: CGFloat = 8
        }
        /// Secondo e terzo tempo (`.fB`, `.fC`): opacità in 0,70 s a 1,50 e a 2,30.
        static let secondo = (durata: 0.70, ritardo: 1.50)
        static let terzo = (durata: 0.70, ritardo: 2.30)
        /// Sottotitolo: opacità in 0,60 s a 0,40.
        static let sottotitolo = (durata: 0.60, ritardo: 0.40)
        /// La cifra della scena 2: contata da 0 (quartica) come `Moto.Numero`.
        static let numero = Tema.Apple.Moto.Numero.durataBase
        /// Gli anelli della scena 1: 1,4 s a 0,35 + i·0,13 (`Moto.Anello`).
        static let anello = (durata: Tema.Apple.Moto.Anello.durata, ritardo: 0.35, passo: Tema.Apple.Moto.Anello.passo)
        /// La curva della scena 3: 1,5 s dopo 0,15 (`Moto.Linea`).
        static let linea = (durata: Tema.Apple.Moto.Linea.durata, ritardo: Tema.Apple.Moto.Linea.ritardoBase)
        /// Dissolvenza incrociata fra le scene (D-F3); con «Riduci movimento» 0,15 s.
        static let dissolvenzaScene = 0.30
        static let dissolvenzaCalma = 0.15
        /// Durate delle scene: titolo, oggi, ogni mese, il futuro, chiusura (20,2 s in tutto).
        static let durate: [Double] = [3.4, 4.2, 4.2, 4.8, 3.6]
        /// La barra della tile dell'esportazione segue l'avanzamento vero, ammorbidita.
        static let barraEsportazione = 0.25
    }
}
