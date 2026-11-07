import SwiftUI

// Controlli del tema Apple (Design/template-apple-specifica.md §2.8, §2.9, §2.10, §2.15).
// - SegmentatoPillola: la pillola scivola a molla sotto la voce scelta (matchedGeometryEffect).
// - StileInterruttoreApple: `Toggle(isOn:) { … }.toggleStyle(.apple)`.
// - CursoreApple: binario, manopola con ombra, passi e limiti; frecce della tastiera e VoiceOver.
// - `.avvisoToast(_:)`: la capsula scura in alto al centro della scena.
// Con «Riduci movimento» le molle diventano la dissolvenza di 0,15 s; nelle istantanee nessuna animazione
// (stato finale subito). Gettoni in Tema.Apple+Controlli.swift e TemaAppleMoto.swift.

// MARK: - Segmentato a pillola (§2.8)

/// Segmentato a capsula: fondo `chip`, voci 13 semibold, la pillola `cardPiena` con l'ombra `pillola` che si
/// sposta e cambia larghezza con la molla di 0,5 s. Un clic sulla voce attiva non fa nulla.
///
///     SegmentatoPillola(selezione: $scheda, voci: [(.panoramica, "Panoramica"), (.obiettivi, "Obiettivi")])
///     SegmentatoPillola(selezione: $giorno, voci: giorni, larghezzaPiena: true)          // settimana dell'Agenda
///     SegmentatoPillola(selezione: $cliente, voci: clienti) { AnyView(Avatar(cliente: $0)) }  // con l'avatar
struct SegmentatoPillola<Valore: Hashable>: View {
    @Binding var selezione: Valore
    let voci: [(Valore, String)]
    /// Voci di uguale larghezza che riempiono lo spazio (settimana dell'Agenda).
    var larghezzaPiena: Bool
    /// Un'icona prima del titolo (avatar 24 dei clienti di Analisi 360).
    var icona: ((Valore) -> AnyView)?

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Namespace private var spazio

    init(selezione: Binding<Valore>, voci: [(Valore, String)], larghezzaPiena: Bool = false,
         icona: ((Valore) -> AnyView)? = nil) {
        self._selezione = selezione
        self.voci = voci
        self.larghezzaPiena = larghezzaPiena
        self.icona = icona
    }

    /// Le voci da un elenco di valori e da come si chiamano.
    init(selezione: Binding<Valore>, valori: [Valore], titolo: (Valore) -> String, larghezzaPiena: Bool = false,
         icona: ((Valore) -> AnyView)? = nil) {
        self.init(selezione: selezione, voci: valori.map { ($0, titolo($0)) },
                  larghezzaPiena: larghezzaPiena, icona: icona)
    }

    private var indiceScelto: Int? {
        voci.firstIndex { $0.0 == selezione }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(voci.indices, id: \.self) { i in
                voce(i)
            }
        }
        .frame(maxWidth: larghezzaPiena ? .infinity : nil)
        .padding(Tema.Apple.Misura.Padding.segmentato)
        .background { pillola }
        .background { Capsule(style: .continuous).fill(Tema.Apple.Colore.chip) }
        .animation(animazionePillola, value: indiceScelto)
    }

    /// Una sola pillola che prende la cornice della voce scelta (niente dissolvenza fra due pillole).
    @ViewBuilder private var pillola: some View {
        if let i = indiceScelto {
            Capsule(style: .continuous)
                .fill(Tema.Apple.Colore.cardPiena)
                .ombraApple(.pillola)
                .matchedGeometryEffect(id: i, in: spazio, properties: .frame, isSource: false)
        }
    }

    private func voce(_ i: Int) -> some View {
        let valore = voci[i].0
        let titolo = voci[i].1
        let attiva = i == indiceScelto
        let c = Tema.Apple.Controlli.Segmentato.self
        return HStack(spacing: icona == nil ? 0 : c.spazioIcona) {
            if let icona {
                icona(valore)
                    .frame(width: c.latoIcona, height: c.latoIcona)
            }
            Text(titolo)
                .lineLimit(1)
                // A tutta larghezza ogni voce tiene almeno la sua etichetta: lo spazio in più va alle voci corte
                .fixedSize(horizontal: larghezzaPiena, vertical: false)
        }
        .carattereApple(Tema.Apple.Carattere.barra)
        .foregroundColor(attiva ? Tema.Apple.Colore.inchiostro : Tema.Apple.Colore.inchiostro2)
        .animation(animazioneTesto, value: attiva)
        .padding(icona == nil ? Tema.Apple.Misura.Padding.voceSegmentato : c.paddingVoceIcona)
        .frame(maxWidth: larghezzaPiena ? .infinity : nil)
        .contentShape(Capsule(style: .continuous))
        .matchedGeometryEffect(id: i, in: spazio, properties: .frame, isSource: true)
        .onTapGesture {
            guard !attiva else { return }
            selezione = valore
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(titolo))
        .accessibilityAddTraits(attiva ? Self.trattiAttiva : Self.trattiVoce)
        .accessibilityAction {
            guard !attiva else { return }
            selezione = valore
        }
    }

    private static var trattiVoce: AccessibilityTraits { .isButton }
    private static var trattiAttiva: AccessibilityTraits { [.isButton, .isSelected] }

    private var animazionePillola: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.Segmentato.animazione, calmo: calmo, istantanea: istantanea)
    }

    private var animazioneTesto: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.Segmentato.animazioneTesto, calmo: calmo, istantanea: istantanea)
    }
}

// MARK: - Interruttore (§2.9)

/// Interruttore 44×26 a capsula: spento `binario`, acceso verde (0,3 s); manopola bianca 20 con ombra
/// che va da 3 a 21 con la molla di 0,35 s.
///
///     Toggle(isOn: $acqua) { Text("L'acqua della scrivania") }.toggleStyle(.apple)
///     Toggle(isOn: $calmo) { EmptyView() }.toggleStyle(.appleSenzaEtichetta)
///         .accessibilityLabel("Riduci movimento")                                    // solo l'interruttore
struct StileInterruttoreApple: ToggleStyle {
    /// true: l'etichetta a sinistra e l'interruttore spinto a destra (righe d'impostazione).
    /// false: solo l'interruttore (per VoiceOver aggiungere `.accessibilityLabel` al Toggle).
    var conEtichetta = true

    func makeBody(configuration: Configuration) -> some View {
        CorpoInterruttoreApple(configuration: configuration, conEtichetta: conEtichetta)
    }
}

extension ToggleStyle where Self == StileInterruttoreApple {
    /// Interruttore del tema Apple, con l'etichetta a sinistra.
    static var apple: StileInterruttoreApple { StileInterruttoreApple() }
    /// Interruttore del tema Apple senza l'etichetta visibile.
    static var appleSenzaEtichetta: StileInterruttoreApple { StileInterruttoreApple(conEtichetta: false) }
}

private struct CorpoInterruttoreApple: View {
    let configuration: ToggleStyleConfiguration
    let conEtichetta: Bool

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.isEnabled) private var abilitato

    var body: some View {
        HStack(spacing: 0) {
            if conEtichetta {
                configuration.label
                Spacer(minLength: Tema.Apple.Controlli.Interruttore.spazioEtichetta)
            }
            interruttore
        }
        .opacity(abilitato ? 1 : Tema.Apple.Controlli.opacitaDisattivato)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(Text(acceso ? "Attivo" : "Spento"))
        .accessibilityAction {
            guard abilitato else { return }
            configuration.isOn.toggle()
        }
    }

    private var acceso: Bool { configuration.isOn }

    private var interruttore: some View {
        let m = Tema.Apple.Misura.Controllo.self
        return ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(acceso ? Tema.Apple.Colore.verdeInterruttore : Tema.Apple.Colore.binario)
                .animation(animazioneFondo, value: acceso)
            Circle()
                .fill(Tema.Apple.Controlli.manopola)
                .frame(width: m.manopolaInterruttore, height: m.manopolaInterruttore)
                .ombraApple(.manopolaInterruttore)
                .offset(x: acceso ? m.manopolaAcceso : m.manopolaSpento)
                .animation(animazioneManopola, value: acceso)
        }
        .frame(width: m.interruttore.width, height: m.interruttore.height)
        .contentShape(Capsule(style: .continuous))
        .onTapGesture {
            guard abilitato else { return }
            configuration.isOn.toggle()
        }
    }

    private var animazioneManopola: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.Interruttore.animazione, calmo: calmo, istantanea: istantanea)
    }

    private var animazioneFondo: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.Interruttore.animazioneFondo, calmo: calmo, istantanea: istantanea)
    }
}

// MARK: - Cursore (§2.10)

/// Cursore del tema Apple: binario 6 (`binario`, raggio 9) senza parte riempita e manopola bianca 28 con
/// l'ombra `manopolaCursore`. Nessuna animazione propria: il valore cambia subito, ciò che è collegato
/// (anelli, cifre) insegue con la propria curva. Si trascina, si clicca sul binario, si regola con le frecce
/// della tastiera (Mac, quando ha il fuoco) e con VoiceOver.
///
///     CursoreApple(valore: $versamento, intervallo: 0...2400, passo: 10, etichetta: "Versamento mensile")
///     CursoreApple(valore: $versamento, intervallo: 0...2400, passo: 10, etichetta: "Versamento mensile",
///                  formato: .euro)                       // con il valore 46 bold blu sopra il binario
///     CursoreApple(valore: $capitale, intervallo: 0...300_000, passo: 10_000, etichetta: "Capitale",
///                  formato: .euro, conta: true, carattereValore: Tema.Apple.Carattere.valoreCursoreAnalisi)
struct CursoreApple: View {
    @Binding var valore: Double
    let intervallo: ClosedRange<Double>
    let passo: Double
    /// Il nome per VoiceOver.
    var etichetta: String
    /// Se c'è, il valore si scrive sopra il binario con questo formato.
    var formato: FormatoCifra?
    /// Il valore scritto si conta (`NumeroCheConta`, 0,9 s a ogni cambio) invece di cambiare subito.
    var conta: Bool
    var carattereValore: Tema.Apple.Carattere
    var coloreValore: Color
    /// Chiamata quando il trascinamento finisce e a ogni passo dalla tastiera o da VoiceOver (che valgono come
    /// rilascio): la prova del fuoco ricalcola dal vivo mentre si trascina e riordina solo qui.
    var alRilascio: (() -> Void)?

    @Environment(\.isEnabled) private var abilitato

    init(valore: Binding<Double>, intervallo: ClosedRange<Double>, passo: Double, etichetta: String = "",
         formato: FormatoCifra? = nil, conta: Bool = false,
         carattereValore: Tema.Apple.Carattere = Tema.Apple.Carattere.valoreCursore,
         coloreValore: Color = Tema.Apple.Colore.accento, alRilascio: (() -> Void)? = nil) {
        self.alRilascio = alRilascio
        self._valore = valore
        self.intervallo = intervallo
        self.passo = passo
        self.etichetta = etichetta
        self.formato = formato
        self.conta = conta
        self.carattereValore = carattereValore
        self.coloreValore = coloreValore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spazioSopraBinario) {
            if let formato {
                valoreScritto(formato)
            }
            binario
        }
        .opacity(abilitato ? 1 : Tema.Apple.Controlli.opacitaDisattivato)
    }

    @ViewBuilder private func valoreScritto(_ formato: FormatoCifra) -> some View {
        Group {
            if conta {
                NumeroCheConta(valore, formato: formato, da: nil)
            } else {
                Text(formato.testo(valore, finale: valore))
                    .monospacedDigit()
            }
        }
        .carattereApple(carattereValore)
        .foregroundColor(coloreValore)
        .lineLimit(1)
        .accessibilityHidden(true)
    }

    private var binario: some View {
        let m = Tema.Apple.Misura.Controllo.self
        return GeometryReader { g in
            let corsa = max(0, g.size.width - m.manopolaCursore)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Tema.Apple.Raggio.barra, style: .continuous)
                    .fill(Tema.Apple.Colore.binario)
                    .frame(height: m.binarioCursore)
                Circle()
                    .fill(Tema.Apple.Controlli.manopola)
                    .frame(width: m.manopolaCursore, height: m.manopolaCursore)
                    .ombraApple(.manopolaCursore)
                    .offset(x: corsa * frazione)
            }
            .frame(width: g.size.width, height: m.manopolaCursore)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { v in
                        guard abilitato, corsa > 0 else { return }
                        let f = (v.location.x - m.manopolaCursore / 2) / corsa
                        imposta(intervallo.lowerBound + Double(f) * ampiezza)
                    }
                    .onEnded { _ in
                        guard abilitato else { return }
                        alRilascio?()
                    }
            )
        }
        .frame(height: m.manopolaCursore)
        .modifier(TastieraCursoreApple(aumenta: { passa(1) }, diminuisci: { passa(-1) }))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(etichetta))
        .accessibilityValue(Text((formato ?? .intero).testo(valore, finale: valore)))
        .accessibilityAdjustableAction { direzione in
            switch direzione {
            case .increment: passa(1)
            case .decrement: passa(-1)
            default: break
            }
        }
    }

    /// I 10 del template vanno dal valore al binario da 6, non alla cornice della manopola da 28
    /// (che sporge di 11 sopra il binario): lo spazio della pila è quindi 10 − 11.
    private var spazioSopraBinario: CGFloat {
        let m = Tema.Apple.Misura.Controllo.self
        return Tema.Apple.Controlli.Cursore.spazioValore - (m.manopolaCursore - m.binarioCursore) / 2
    }

    private var ampiezza: Double { intervallo.upperBound - intervallo.lowerBound }

    /// Dove sta la manopola, da 0 a 1.
    private var frazione: CGFloat {
        guard ampiezza > 0 else { return 0 }
        return CGFloat(min(1, max(0, (valore - intervallo.lowerBound) / ampiezza)))
    }

    /// Un passo avanti (+1) o indietro (−1).
    private func passa(_ verso: Double) {
        guard abilitato else { return }
        imposta(valore + verso * max(passo, 0))
        alRilascio?()
    }

    /// Arrotonda al passo, resta nei limiti, e cambia il valore senza animazione (solo se è diverso).
    private func imposta(_ grezzo: Double) {
        let basso = intervallo.lowerBound
        var nuovo = min(intervallo.upperBound, max(basso, grezzo))
        if passo > 0 {
            nuovo = basso + ((nuovo - basso) / passo).rounded() * passo
            nuovo = min(intervallo.upperBound, max(basso, nuovo))
        }
        guard nuovo != valore else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { valore = nuovo }
    }
}

/// Frecce della tastiera sul Mac (il cursore prende il fuoco); su iPhone e iPad non serve.
private struct TastieraCursoreApple: ViewModifier {
    let aumenta: () -> Void
    let diminuisci: () -> Void

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .focusable()
            .onMoveCommand { direzione in
                switch direzione {
                case .right, .up: aumenta()
                case .left, .down: diminuisci()
                default: break
                }
            }
        #else
        content
        #endif
    }
}

// MARK: - Toast (§2.15)

extension View {
    /// Il toast del tema Apple sopra questa vista (la scena): capsula scura con testo bianco 13, centrata a
    /// 44 dall'alto. Entra da −20 con la molla di 0,45 s ed esce allo stesso modo; un testo nuovo sostituisce
    /// quello in vista. Qui `testo` decide solo se si vede: la durata la tiene chi lo imposta
    /// (oggi `StatoShell.mostraAvviso`).
    func avvisoToast(_ testo: String?) -> some View {
        modifier(AvvisoToastApple(testo: testo))
    }

    /// Come `avvisoToast(_:)`, ma il toast si toglie da solo dopo 2,4 s rimettendo `testo` a nil
    /// (nelle istantanee resta in vista).
    func avvisoToast(_ testo: Binding<String?>) -> some View {
        modifier(AvvisoToastTemporaneoApple(testo: testo))
    }
}

/// La capsula del toast.
private struct CapsulaToastApple: View {
    let testo: String

    var body: some View {
        let t = Tema.Apple.Controlli.Toast.self
        Text(testo)
            .carattereApple(t.carattere)
            .foregroundColor(Tema.Apple.Colore.testoToast)
            .lineLimit(1)
            .fixedSize()
            .padding(t.padding)
            .background { Capsule(style: .continuous).fill(Tema.Apple.Colore.toast) }
    }
}

private struct AvvisoToastApple: ViewModifier {
    let testo: String?
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            ZStack {
                if let testo {
                    CapsulaToastApple(testo: testo)
                        .transition(transizione)
                        .accessibilityAddTraits(.isStaticText)
                }
            }
            .padding(.top, Tema.Apple.Controlli.Toast.dallAlto)
            .animation(animazione, value: testo != nil)
            .allowsHitTesting(false)
        }
    }

    private var transizione: AnyTransition {
        calmo ? .opacity : .opacity.combined(with: .offset(y: Tema.Apple.Moto.Toast.spostamento))
    }

    private var animazione: Animation? {
        Tema.Apple.Moto.animazione(Tema.Apple.Moto.Toast.animazione, calmo: calmo, istantanea: istantanea)
    }
}

private struct AvvisoToastTemporaneoApple: ViewModifier {
    @Binding var testo: String?
    @Environment(\.modoIstantanea) private var istantanea

    func body(content: Content) -> some View {
        content
            .modifier(AvvisoToastApple(testo: testo))
            .task(id: testo) {
                guard let mostrato = testo, !istantanea else { return }
                let attesa = UInt64(Tema.Apple.Moto.Toast.tenuto * 1_000_000_000)
                try? await Task.sleep(nanoseconds: attesa)
                guard !Task.isCancelled, testo == mostrato else { return }
                testo = nil
            }
    }
}
