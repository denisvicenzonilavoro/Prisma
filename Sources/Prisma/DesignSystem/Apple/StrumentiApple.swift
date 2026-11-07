import SwiftUI

// Gli strumenti di Analisi 360 (Simulatore, Scenari, Confronto, TFR) nel tema Apple.
// `.strumentiApple()` chiede ai componenti condivisi degli strumenti — comandi della console (`ComandoSimulatore`,
// `DisplayLCD`), tabelle (`TabellaStrumento`, `RigaStrumento`, `CellaTesta`, `CellaTabella`), `TitoloStrumento`,
// `NotaMetodo`, `LegendaLinea` e `SegmentiAnalisi` — lo stile del tema Apple (caratteri SF del tema, superfici
// `tile` e `cardPiatta`, `CursoreApple`, `SegmentatoPillola`), e accende anche `.superficiApple()` (pannelli,
// indicatori ed etichetta del canale `.chA` / `.chI`). Le altre app che usano gli stessi componenti restano
// com'erano. Gettoni in Tema.Apple+Strumenti360.swift.

private struct ChiaveStrumentiApple: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// true: i componenti condivisi degli strumenti di analisi si disegnano nel tema Apple.
    var strumentiApple: Bool {
        get { self[ChiaveStrumentiApple.self] }
        set { self[ChiaveStrumentiApple.self] = newValue }
    }
}

extension View {
    /// Gli strumenti di Analisi 360 nel tema Apple: componenti degli strumenti, pannelli ed etichette del canale.
    func strumentiApple(_ attivi: Bool = true) -> some View {
        environment(\.strumentiApple, attivi)
            .superficiApple(attivi)
    }

    /// La testata di uno strumento nel tema Apple: la spia verde e il titolo (14 semibold).
    func titoloTestataStrumentoApple() -> some View {
        carattereApple(Tema.Apple.Strumenti360.titoloTestata)
            .foregroundColor(Tema.Apple.Strumenti360.coloreTitoloTestata)
            .lineLimit(1)
    }
}

/// La spia della testata degli strumenti (il pallino verde accanto al titolo).
struct SpiaStrumentoApple: View {
    var body: some View {
        let lato = Tema.Misura.StrumentiAnalisi.spia
        Circle()
            .fill(Tema.Apple.Strumenti360.spia)
            .frame(width: lato, height: lato)
    }
}
