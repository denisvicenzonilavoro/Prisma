import SwiftUI

// «Dimensione del testo» per il tema Apple (Design/template-apple-specifica.md §4.6): Normale, Grande, Molto grande
// (1,0 / 1,12 / 1,25, l'impostazione `DimensioneTesto` di sempre). La radice delle viste (ShellView sul Mac, la
// radice su iPhone e iPad) mette la scala nell'ambiente con `.prismaScalaTesto(_:)`; `.carattereApple(_:)` la
// applica alla dimensione e alla spaziatura delle lettere di ogni gradino della scala tipografica (§1.7), subito,
// senza riaprire Prisma. I caratteri di sempre (`Tipo`) seguono `Tipo.fattore`, fissato all'avvio.
// La carta (prospetti, report, PDF) resta come sulla carta: fuori dall'albero delle viste (PDF e stampa) la scala
// vale 1, e un'anteprima su carta a schermo la riporta a 1 con `.prismaScalaTesto(1)`.

private struct ChiaveScalaTestoApple: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

extension EnvironmentValues {
    /// Quanto si ingrandiscono i caratteri del tema Apple (1 = come nel template).
    var prismaScalaTesto: CGFloat {
        get { self[ChiaveScalaTestoApple.self] }
        set { self[ChiaveScalaTestoApple.self] = newValue }
    }
}

extension View {
    /// Imposta la scala dei caratteri del tema Apple per questa vista e le sue figlie.
    func prismaScalaTesto(_ scala: CGFloat) -> some View {
        environment(\.prismaScalaTesto, scala)
    }
}

extension Tema.Apple.Carattere {
    /// Lo stesso gradino ingrandito: dimensione e spaziatura delle lettere per la scala (interlinea, maiuscolo e
    /// cifre restano come sono, perché l'interlinea è un multiplo della dimensione).
    func scalato(_ scala: CGFloat) -> Tema.Apple.Carattere {
        guard scala != 1 else { return self }
        return Tema.Apple.Carattere(dimensione: dimensione * scala, peso: peso, tracking: tracking * scala,
                                    interlinea: interlinea, maiuscolo: maiuscolo, tabellare: tabellare)
    }
}

/// `.carattereApple(_:)`: il gradino alla scala dell'ambiente.
struct ModificatoreCarattereApple: ViewModifier {
    let carattere: Tema.Apple.Carattere
    @Environment(\.prismaScalaTesto) private var scala

    func body(content: Content) -> some View {
        let c = carattere.scalato(scala)
        return content
            .font(c.font)
            .tracking(c.tracking)
            .lineSpacing(c.spazioRighe)
            .textCase(c.maiuscolo ? .uppercase : nil)
    }
}
