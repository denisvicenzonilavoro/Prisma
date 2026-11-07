import SwiftUI

// I componenti di analisi di sempre nel tema Apple, solo dove serve (Design/template-apple-specifica.md §5.1).
// `PannelloAnalisi`, `KPI` ed `EtichettaCanale` sono usati da molte app: con `.superficiApple()` una schermata li
// chiede nello stile del tema Apple (card piatte, caratteri SF del tema, etichetta del canale `.chA` / `.chI`),
// senza toccare le altre app. Lo usano Posizioni (vista Cliente, dettagli delle posizioni e pannelli del
// Portafoglio). Un pannello dentro un altro pannello resta senza card (niente card annidate).

private struct ChiaveSuperficiApple: EnvironmentKey {
    static let defaultValue = false
}

private struct ChiaveEtichetteApple: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// true: `PannelloAnalisi` e `KPI` si disegnano come card del tema Apple.
    var superficiApple: Bool {
        get { self[ChiaveSuperficiApple.self] }
        set { self[ChiaveSuperficiApple.self] = newValue }
    }

    /// true: `EtichettaCanale` è l'etichetta del tema Apple (`EtichettaCanaleApple`); resta anche dentro i pannelli.
    var etichetteApple: Bool {
        get { self[ChiaveEtichetteApple.self] }
        set { self[ChiaveEtichetteApple.self] = newValue }
    }
}

extension View {
    /// I pannelli, gli indicatori e le etichette del canale di questa vista nello stile del tema Apple.
    func superficiApple(_ attive: Bool = true) -> some View {
        environment(\.superficiApple, attive)
            .environment(\.etichetteApple, attive)
    }
}

extension Tema.Apple {
    /// I valori dei componenti di analisi nel tema Apple.
    enum SuperficiAnalisi {
        // Pannello: card piatta, padding 20×22, titolo 17 bold, nota `.k`
        static let pannello = Superficie.cardPiatta
        static let raggioPannello = Raggio.card
        static let paddingPannello = Misura.Padding.cardMedia
        static let titoloPannello = Carattere(dimensione: 17, peso: .bold, tracking: -0.3)
        static let notaPannello = Carattere.secondario
        static let coloreNota = Colore.inchiostro2
        static let spazioPannello: CGFloat = 12
        static let spazioTitolo: CGFloat = 2
        // Indicatore: tile, padding 14×16, etichetta `.k`, valore 22 bold con le cifre tabellari, nota 12
        static let tessera = Superficie.tile
        static let raggioTessera = Raggio.tile
        static let paddingTessera = Misura.Padding.tile
        static let titoloTessera = Carattere.secondario
        static let valoreTessera = Carattere(dimensione: 22, peso: .bold, tracking: -0.4, tabellare: true)
        static let notaTessera = Carattere(dimensione: 12, peso: .regular)
        static let spazioTessera: CGFloat = 4
        /// Fra gli elementi della nota sotto il valore.
        static let spazioNota: CGFloat = 5
    }
}
