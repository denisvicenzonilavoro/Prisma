import QuartzCore
import SwiftUI

// Scheda che si inclina (Design/template-apple-specifica.md §2.6).
// Mac: al passaggio del puntatore la scheda ruota verso di lui (X = (0,5 − y)·m·0,8°, Y = (x − 0,5)·m°),
// si solleva di 5 pt e cresce a 1,02, con la prospettiva di 900 pt (`projectionEffect`, m34 = −1/900).
// L'inseguimento e il ritorno all'uscita usano la molla da 0,5 s; l'ombra diventa `inclinata` in 0,4 s
// e un riflesso radiale 260×200 segue il puntatore (compare in 0,3 s).
// iPhone e iPad: niente inclinazione; alla pressione la scheda scende a 0,98.
// «Riduci movimento», istantanee e schede già «fatte» (`attiva: false`): spenta.
// Prestazioni: col puntatore fuori non c'è nessuno stato che cambia, nessuna ombra né riflesso montati;
// l'effetto lavora solo sulla scheda sotto il puntatore.

extension View {
    /// Inclina la scheda verso il puntatore. `massimo`: gradi (impegni 3, aree 5, familiari 6, predefinito 10,
    /// in `Tema.Apple.Moto.Inclinazione`). `raggio`: quello della scheda (riflesso e ombra).
    /// `attiva: false` per le schede già «fatte». Va messo sulla scheda intera, dopo il suo fondo.
    func inclinazione(massimo: Double = Tema.Apple.Moto.Inclinazione.massimoPredefinito,
                      raggio: CGFloat = Tema.Apple.Raggio.card,
                      attiva: Bool = true) -> some View {
        modifier(SchedaInclinabileApple(massimo: massimo, raggio: raggio, attiva: attiva))
    }
}

private struct ChiaveInclinazioneSospesaApple: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// true mentre la scheda è nascosta sotto il suo dettaglio aperto (`.origineDettaglio(id:)`):
    /// l'inclinazione torna piatta subito, così alla chiusura la scheda ricompare a riposo
    /// anche se il Mac non ha segnalato l'uscita del puntatore coperto dal velo.
    var inclinazioneSospesaApple: Bool {
        get { self[ChiaveInclinazioneSospesaApple.self] }
        set { self[ChiaveInclinazioneSospesaApple.self] = newValue }
    }
}

/// Il modificatore di `.inclinazione(massimo:raggio:attiva:)`.
struct SchedaInclinabileApple: ViewModifier {
    let massimo: Double
    let raggio: CGFloat
    let attiva: Bool

    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.inclinazioneSospesaApple) private var sospesa

    #if os(macOS)
    @Environment(\.colorScheme) private var schema
    /// Posizione del puntatore normalizzata (0…1).
    @State private var punto = CGPoint(x: 0.5, y: 0.5)
    /// Il puntatore è sopra: rotazione, sollevamento e scala.
    @State private var sopra = false
    /// Ombra e riflesso montati.
    @State private var luce = false
    /// La misura della scheda, tenuta fuori da `@State`: scriverla alla comparsa non rifà la scheda.
    @StateObject private var misura = MisuraSchedaApple()
    #else
    @GestureState private var premuto = false
    #endif

    private var abilitata: Bool { attiva && !fermo && !sospesa && massimo > 0 }

    func body(content: Content) -> some View {
        #if os(macOS)
        corpoMac(content)
        #else
        corpoTocco(content)
        #endif
    }

    #if os(macOS)

    private func corpoMac(_ content: Content) -> some View {
        let su = sopra && abilitata
        let fattoreX = Tema.Apple.Moto.Inclinazione.fattoreX
        let rx = su ? Double(0.5 - punto.y) * massimo * fattoreX : 0
        let ry = su ? Double(punto.x - 0.5) * massimo : 0
        return content
            // Il lettore della misura serve solo con l'inclinazione accesa (niente GeometryReader nelle istantanee,
            // con «Riduci movimento» o a scheda «fatta»); il ramo è nel fondo, quindi non tocca l'identità della scheda
            .background { if abilitata { LettoreMisuraScheda(misura: misura) } }
            .onContinuousHover(coordinateSpace: .local) { fase in muovi(fase) }
            .background { ombraInclinata }
            .overlay { riflesso }
            .modifier(EffettoInclinazioneApple(rx: rx, ry: ry, sollevato: su ? 1 : 0))
            .zIndex(su ? 1 : 0)
            .onChange(of: abilitata) { si in
                if !si { tornaSubito() }
            }
    }

    private func muovi(_ fase: HoverPhase) {
        guard abilitata else { return }
        switch fase {
        case .active(let p):
            let m = misura.valore
            guard m.width > 0, m.height > 0 else { return }
            let n = CGPoint(x: min(max(p.x / m.width, 0), 1),
                            y: min(max(p.y / m.height, 0), 1))
            withAnimation(Tema.Apple.Moto.Inclinazione.ripiego.animazione) {
                punto = n
                sopra = true
                luce = true
            }
        case .ended:
            guard sopra || luce else { return }
            withAnimation(Tema.Apple.Moto.Inclinazione.ripiego.animazione) {
                sopra = false
                luce = false
            }
        }
    }

    /// Torna piatta di colpo (calma accesa, scheda «fatta»).
    private func tornaSubito() {
        guard sopra || luce else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            sopra = false
            luce = false
        }
    }

    /// Ombra `inclinata`, montata solo col puntatore sopra.
    private var ombraInclinata: some View {
        ZStack {
            if luce && abilitata {
                OmbraVetroPronta(raggio: raggio,
                                 strati: Tema.Apple.Ombra.inclinata.strati(scuro: schema == .dark))
                    .transition(.opacity.animation(Tema.Apple.Moto.Inclinazione.animazioneOmbra))
            }
        }
    }

    /// Riflesso radiale che segue il puntatore, montato solo col puntatore sopra.
    private var riflesso: some View {
        ZStack {
            if luce && abilitata {
                RiflessoSchedaApple(punto: punto, misura: misura.valore, raggio: raggio, scuro: schema == .dark)
                    .transition(.opacity.animation(Tema.Apple.Moto.Inclinazione.animazioneRiflesso))
            }
        }
        .allowsHitTesting(false)
    }

    #else

    private func corpoTocco(_ content: Content) -> some View {
        let giu = premuto && abilitata
        let pressione = LongPressGesture(minimumDuration: Tema.Apple.Moto.Inclinazione.durataPressione,
                                         maximumDistance: Tema.Apple.Moto.Inclinazione.distanzaPressione)
            .updating($premuto) { attuale, stato, _ in stato = attuale }
        return content
            .scaleEffect(giu ? Tema.Apple.Moto.Inclinazione.scalaPressione : 1)
            .animation(Tema.Apple.Moto.Inclinazione.ripiego.animazione, value: giu)
            .simultaneousGesture(pressione)
    }

    #endif
}

#if os(macOS)

/// La misura della scheda, senza nulla di pubblicato: serve solo a normalizzare il puntatore (e al riflesso, che si
/// ridisegna già a ogni movimento del puntatore), quindi scriverla non deve rifare la scheda. Con un `@State` ogni
/// scheda inclinabile si rifaceva una seconda volta alla comparsa (le quattro card di Analisi 360, le schede di
/// Posizioni e Clienti).
private final class MisuraSchedaApple: ObservableObject {
    var valore: CGSize = .zero
}

/// Legge la misura della scheda (per normalizzare la posizione del puntatore).
private struct LettoreMisuraScheda: View {
    let misura: MisuraSchedaApple

    var body: some View {
        GeometryReader { g in
            Color.clear
                .onAppear { misura.valore = g.size }
                .onChange(of: g.size) { nuova in misura.valore = nuova }
        }
    }
}

/// `.sheen`: ellisse 260×200 bianca (.6 con `softLight` in chiaro, .16 normale in scuro) che svanisce al 60%.
private struct RiflessoSchedaApple: View {
    let punto: CGPoint
    let misura: CGSize
    let raggio: CGFloat
    let scuro: Bool

    var body: some View {
        let r = Tema.Apple.Misura.RiflessoInclinazione.self
        let colore = Tema.Apple.Colore.riflessoInclinazione
        // In EllipticalGradient la frazione 0,5 tocca il bordo del riquadro (= il raggio dell'ellisse).
        let fine = r.fineSfumatura * 0.5
        return ZStack(alignment: .topLeading) {
            EllipticalGradient(colors: [colore, colore.opacity(0)], center: .center,
                               startRadiusFraction: 0, endRadiusFraction: fine)
                .frame(width: r.raggioOrizzontale * 2, height: r.raggioVerticale * 2)
                .position(x: punto.x * misura.width, y: punto.y * misura.height)
                // Il riflesso segue il puntatore senza molla, come `--mx`/`--my` del template.
                .animation(nil, value: punto)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: raggio, style: .continuous))
        .blendMode(Tema.Apple.Colore.fusioneRiflesso(scuro: scuro))
        .accessibilityHidden(true)
    }
}

#endif

/// `perspective(900px) rotateX(rx) rotateY(ry) translateY(−5·s) scale(1 + 0,02·s)` attorno al centro.
/// Animabile su (rx, ry, sollevato); a riposo è l'identità.
struct EffettoInclinazioneApple: GeometryEffect {
    var rx: Double
    var ry: Double
    var sollevato: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, CGFloat> {
        get { AnimatablePair(AnimatablePair(rx, ry), sollevato) }
        set {
            rx = newValue.first.first
            ry = newValue.first.second
            sollevato = newValue.second
        }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        if rx == 0, ry == 0, sollevato == 0 { return ProjectionTransform() }
        let i = Tema.Apple.Moto.Inclinazione.self
        let cx = size.width / 2
        let cy = size.height / 2
        let s = 1 + (i.scala - 1) * sollevato
        // Core Animation compone da sinistra a destra (prima a, poi b): l'ordine è quello in cui
        // il CSS applica le trasformazioni al punto (prima la scala, per ultima la prospettiva).
        var t = CATransform3DMakeTranslation(-cx, -cy, 0)
        t = CATransform3DConcat(t, CATransform3DMakeScale(s, s, 1))
        t = CATransform3DConcat(t, CATransform3DMakeTranslation(0, i.sollevamento * sollevato, 0))
        t = CATransform3DConcat(t, CATransform3DMakeRotation(CGFloat(ry * .pi / 180), 0, 1, 0))
        t = CATransform3DConcat(t, CATransform3DMakeRotation(CGFloat(rx * .pi / 180), 1, 0, 0))
        var prospettiva = CATransform3DIdentity
        prospettiva.m34 = -1 / i.prospettiva
        t = CATransform3DConcat(t, prospettiva)
        t = CATransform3DConcat(t, CATransform3DMakeTranslation(cx, cy, 0))
        return ProjectionTransform(t)
    }
}
