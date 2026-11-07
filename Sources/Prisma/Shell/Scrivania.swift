import SwiftUI

/// La scrivania del Mac nel tema Apple (Design/template-apple-specifica.md §3.6, riferimenti shell/03-scrivania e
/// 13-riquadro-hover): il saluto sull'acqua, «Nuovo cliente» e «Cerca ovunque», la mossa del giorno a tutta
/// larghezza, poi Agenda di oggi, Portafoglio clienti con i tre anelli e Vera, sotto Da fare oggi e In scadenza.
/// I riquadri sono in ScrivaniaApple.swift, i valori in DesignSystem/Apple/Tema.Apple+Scrivania.swift.
/// Un clic sul fondo libero fa cadere una goccia sull'acqua (`.gocciaAlTocco()`, SfondoAcquaRisposta.swift);
/// il trascinamento orizzontale verso Vera resta quello di `PagineScrivania` (VeraScrivania.swift).
/// iPhone e iPad hanno le loro scrivanie (iOS/) con i widget di Widget.swift.
struct Scrivania: View {
    var body: some View {
        GeometryReader { geo in
            let d = Tema.Apple.Scrivania.Disposizione.self
            // Margine laterale: 3% della larghezza, fra 16 e 44 punti; contenuto al massimo 1600, centrato
            let margine = min(max(geo.size.width * d.quotaMargine, d.margineMinimo), d.margine)
            let larghezza = max(0, min(geo.size.width - 2 * margine, d.larghezzaMassima))
            RiquadriScrivania()
                .frame(width: larghezza, height: geo.size.height)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        // Un clic sul fondo libero (non su riquadri, pulsanti o testi) fa cadere una goccia sull'acqua
        .gocciaAlTocco()
    }
}

/// Pulsante di vetro sullo sfondo (.gbtn del tema): capsula di vetro sottile, più chiara al passaggio,
/// molla alla pressione. `piccolo`: alto 30 invece di 34.
struct StilePulsanteVetro: ButtonStyle {
    var piccolo = false

    func makeBody(configuration: Configuration) -> some View {
        CorpoPulsanteVetro(etichetta: configuration.label, piccolo: piccolo, premuto: configuration.isPressed)
    }
}

private struct CorpoPulsanteVetro<Etichetta: View>: View {
    let etichetta: Etichetta
    let piccolo: Bool
    let premuto: Bool
    @State var sopra = false
    @Environment(\.isEnabled) var abilitato

    var body: some View {
        etichetta
            .font(piccolo ? Tema.Testo.pulsantePiccolo : Tema.Testo.pulsante)
            .foregroundColor(Tema.Colore.inchiostro)
            .lineLimit(1)
            .padding(.horizontal, piccolo ? Tema.Misura.Shell.pulsanteVetroPiccoloMargine : Tema.Misura.Shell.pulsanteVetroMargine)
            .frame(height: piccolo ? Tema.Misura.pulsanteVetroPiccolo : Tema.Misura.pulsanteVetro)
            .contentShape(Capsule(style: .continuous))
            .vetro(.leggero, forma: .capsula, tinta: sopra ? Tema.Colore.Shell.passaggioVetro : nil, interattivo: true)
            .scaleEffect(premuto ? Tema.Moto.scalaPressione : 1)
            .animation(Tema.Moto.molla, value: premuto)
            .opacity(abilitato ? 1 : Tema.Misura.Shell.opacitaDisabilitato)
            .onHover { sopra = $0 }
    }
}
