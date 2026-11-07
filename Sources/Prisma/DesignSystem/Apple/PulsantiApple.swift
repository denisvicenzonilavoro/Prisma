import SwiftUI

// Pulsanti ed etichetta del canale del tema Apple (Design/template-apple-specifica.md §2.16, §2.17).
// - StilePulsanteApple: `.buttonStyle(.apple)`, `.applePrimario`, `.appleVetro`, `.appleSobrio`,
//   oppure `StilePulsanteApple(.principale, grande: true)`.
// - EtichettaCanaleApple: la capsula del canale nei colori di Prisma (Alleanza blu con il logo Alleanza,
//   indipendente cuoio con «Denis Vicenzoni · Consulenza finanziaria»).
// Premuto: scala 0,95 con la molla di 0,25 s; sopra (hover): luminosità 0,97. Con «Riduci movimento» la
// scala segue la dissolvenza di 0,15 s; nelle istantanee né pressione né hover.

// MARK: - Pulsante (§2.16)

/// Le varianti del pulsante.
enum VariantePulsanteApple {
    /// `.btn.pri`: blu `accento` con il testo bianco (l'azione principale).
    case principale
    /// `.btn`: `cardPiena` con il bordo `separatore` (le altre azioni).
    case secondaria
    /// `.btn.glass`: sul vetro della scrivania (Nuovo cliente, Cerca ovunque).
    case vetro
    /// Solo il testo blu, con il fondo `chip` sotto il puntatore (azioni minori dentro le card).
    case sobria
}

/// Pulsante a capsula del tema Apple: 12,5 semibold con padding 7×14 (grande: 13,5 con 10×18),
/// spazio 6 fra icona e testo.
///
///     Button("Analisi 360") { … }.buttonStyle(.apple)
///     Button("Salva nel dossier") { … }.buttonStyle(StilePulsanteApple(.principale, grande: true))
///     Button { … } label: { Label("Nuovo cliente", systemImage: "person.badge.plus") }.buttonStyle(.appleVetro)
struct StilePulsanteApple: ButtonStyle {
    var variante: VariantePulsanteApple
    var grande: Bool

    init(_ variante: VariantePulsanteApple = .secondaria, grande: Bool = false) {
        self.variante = variante
        self.grande = grande
    }

    func makeBody(configuration: Configuration) -> some View {
        CorpoPulsanteApple(etichetta: configuration.label, premuto: configuration.isPressed,
                           variante: variante, grande: grande)
    }
}

extension ButtonStyle where Self == StilePulsanteApple {
    /// Pulsante secondario (`.btn`).
    static var apple: StilePulsanteApple { StilePulsanteApple(.secondaria) }
    /// Pulsante principale blu (`.btn.pri`).
    static var applePrimario: StilePulsanteApple { StilePulsanteApple(.principale) }
    /// Pulsante sul vetro della scrivania (`.btn.glass`).
    static var appleVetro: StilePulsanteApple { StilePulsanteApple(.vetro) }
    /// Pulsante sobrio: solo il testo blu.
    static var appleSobrio: StilePulsanteApple { StilePulsanteApple(.sobria) }
    /// Pulsante secondario grande (`.btn.big`).
    static var appleGrande: StilePulsanteApple { StilePulsanteApple(.secondaria, grande: true) }
    /// Pulsante principale grande (`.btn.pri.big`).
    static var applePrimarioGrande: StilePulsanteApple { StilePulsanteApple(.principale, grande: true) }
}

private struct CorpoPulsanteApple: View {
    let etichetta: ButtonStyleConfiguration.Label
    let premuto: Bool
    let variante: VariantePulsanteApple
    let grande: Bool

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.isEnabled) private var abilitato
    @State private var sopra = false

    private var forma: Capsule { Capsule(style: .continuous) }

    var body: some View {
        let m = Tema.Apple.Moto.PulsantePremuto.self
        HStack(spacing: Tema.Apple.Controlli.Pulsante.spazio) {
            etichetta
        }
        .carattereApple(grande ? Tema.Apple.Carattere.pulsanteGrande : Tema.Apple.Carattere.pulsante)
        .foregroundColor(coloreTesto)
        .lineLimit(1)
        .colorMultiply(moltiplica)
        .padding(grande ? Tema.Apple.Misura.Padding.pulsanteGrande : Tema.Apple.Misura.Padding.pulsante)
        .background { fondo }
        .contentShape(forma)
        .scaleEffect(premuto && abilitato && !istantanea ? m.scala : 1)
        .animation(Tema.Apple.Moto.animazione(m.animazione, calmo: calmo, istantanea: istantanea), value: premuto)
        .animation(Tema.Apple.Moto.animazione(m.animazioneSopra, calmo: calmo, istantanea: istantanea), value: sopra)
        .opacity(abilitato ? 1 : Tema.Apple.Controlli.opacitaDisattivato)
        .onHover { dentro in sopra = dentro && abilitato && !istantanea }
    }

    /// `filter: brightness(.97)` sotto il puntatore: moltiplica i colori (bianco = invariato).
    private var moltiplica: Color {
        sopra ? Color(white: Tema.Apple.Moto.PulsantePremuto.luminositaSopra) : Color.white
    }

    private var coloreTesto: Color {
        switch variante {
        case .principale: return Tema.Apple.Controlli.Pulsante.testoPrincipale
        case .secondaria, .vetro: return Tema.Apple.Colore.inchiostro
        case .sobria: return Tema.Apple.Colore.accento
        }
    }

    @ViewBuilder private var fondo: some View {
        switch variante {
        case .principale:
            forma.fill(Tema.Apple.Colore.accento)
                .colorMultiply(moltiplica)
        case .secondaria:
            forma.fill(Tema.Apple.Colore.cardPiena)
                .overlay { forma.strokeBorder(Tema.Apple.Colore.separatore, lineWidth: Tema.Apple.Misura.bordo) }
                .colorMultiply(moltiplica)
        case .vetro:
            // Il vetro non si moltiplica (il campionamento dello sfondo resta nativo): basta il testo.
            GeometryReader { g in
                Color.clear
                    .superficieApple(Tema.Apple.Superficie.pulsanteVetro, raggio: g.size.height / 2)
            }
        case .sobria:
            forma.fill(sopra ? Tema.Apple.Colore.chip : Color.clear)
        }
    }
}

// MARK: - Etichetta del canale (§2.17)

/// L'etichetta del canale nello stile del template (`.chA` / `.chI`): capsula 11,5 semibold con padding 3×9,
/// spazio 5. Alleanza: fondo blu al 13% e testo `canaleAlleanza`, con il logo Alleanza (nella compatta il
/// pallino 6). Indipendente: fondo cuoio al 14% e testo `canaleIndipendente`, pallino 6; nella versione
/// estesa la scritta è «Denis Vicenzoni · Consulenza finanziaria», nella compatta «Indipendente».
/// Sui documenti (`\.etichetteStampa`) è `EtichettaCanaleStampa`, come `EtichettaCanale`.
///
///     EtichettaCanaleApple(canale: .alleanza)
///     EtichettaCanaleApple(canale: p.canale, compatta: true)
struct EtichettaCanaleApple: View {
    let canale: Canale
    var compatta = false
    @Environment(\.etichetteStampa) private var stampa

    var body: some View {
        if stampa {
            EtichettaCanaleStampa(canale: canale, compatta: compatta)
        } else {
            capsula
        }
    }

    private var alleanza: Bool { canale == .alleanza }

    private var colore: Color {
        alleanza ? Tema.Apple.Colore.canaleAlleanza : Tema.Apple.Colore.canaleIndipendente
    }

    /// Alleanza: sempre «Alleanza»; indipendente: la firma completa nella versione estesa.
    private var testo: String {
        alleanza || compatta ? canale.nomeBreve : canale.nome
    }

    private var capsula: some View {
        HStack(spacing: Tema.Apple.Misura.Spazio.etichettaCanale) {
            segno
            Text(testo)
                .carattereApple(Tema.Apple.Carattere.canale)
                .foregroundColor(colore)
                .lineLimit(1)
        }
        .padding(Tema.Apple.Misura.Padding.etichettaCanale)
        .background {
            Capsule(style: .continuous)
                .fill(alleanza ? Tema.Apple.Colore.fondoAlleanza : Tema.Apple.Colore.fondoIndipendente)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(canale.nome))
    }

    /// Il logo Alleanza (estesa) o il pallino nel colore del testo.
    @ViewBuilder private var segno: some View {
        if alleanza, !compatta, let simbolo = Risorse.immagine("Loghi/Alleanza_simbolo.png") {
            Image(piattaforma: simbolo)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(height: Tema.Apple.Controlli.Etichetta.simboloAlleanza)
                .foregroundColor(colore)
        } else {
            let lato = Tema.Apple.Misura.Controllo.pallinoCanale
            Circle()
                .fill(colore)
                .frame(width: lato, height: lato)
        }
    }
}
