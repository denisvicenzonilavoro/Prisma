import SwiftUI

// Anelli in stile Fitness del tema «stile Apple» (Design/template-apple-specifica.md §2.3).
// Estremità arrotondate, binario dello stesso colore al 15%, disegno da ore 12 in senso orario.
// Il riempimento cresce da 0 alla frazione in 1,4 s con la curva `uscita`, ritardo d + i·0,13;
// un nuovo valore anima dal valore mostrato. Il brillio (completamento) è un'ombra del colore dell'anello:
// sale in 0,6 s, resta fino a 0,9 s e scende in 0,6 s.
// Calmo e istantanee: frazione finale subito, nessun brillio.

/// Un anello di `AnelliConcentrici`.
struct VoceAnello: Identifiable {
    let id: String
    var valore: Double
    var massimo: Double = 100
    var colore: Color

    /// Frazione riempita (0…1).
    var frazione: Double {
        guard massimo > 0 else { return 0 }
        return min(max(valore / massimo, 0), 1)
    }
}

/// Anelli concentrici (dall'esterno all'interno nell'ordine di `voci`), con un contenuto facoltativo al centro.
///
///     AnelliConcentrici(voci: voci, misura: 190, spessore: 16, ritardo: Tema.Apple.Moto.Anello.ritardoFinestra)
///     AnelliConcentrici(voci: voci, misura: 118, spessore: 12, brilla: "riesami", impulsoBrillio: n) { Text("…") }
struct AnelliConcentrici<Centro: View>: View {
    let voci: [VoceAnello]
    let misura: CGFloat
    let spessore: CGFloat?
    let ritardo: Double
    let brilla: String?
    let impulsoBrillio: Int
    let centro: Centro

    /// - Parameters:
    ///   - spessore: nil = misura·0,09.
    ///   - ritardo: d del primo anello (gli altri + i·0,13). Finestra 0,32; dettaglio 0,12; cambio 0,15; scrivania 0,60.
    ///   - brilla: id dell'anello che brilla; brilla quando cambia questo id o `impulsoBrillio`.
    ///   - impulsoBrillio: aumentalo per far brillare di nuovo lo stesso anello.
    init(voci: [VoceAnello],
         misura: CGFloat,
         spessore: CGFloat? = nil,
         ritardo: Double = Tema.Apple.Moto.Anello.ritardoFinestra,
         brilla: String? = nil,
         impulsoBrillio: Int = 0,
         @ViewBuilder centro: () -> Centro) {
        self.voci = voci
        self.misura = misura
        self.spessore = spessore
        self.ritardo = ritardo
        self.brilla = brilla
        self.impulsoBrillio = impulsoBrillio
        self.centro = centro()
    }

    var body: some View {
        let g = Tema.Apple.Grafico.Anello.self
        let s = spessore ?? misura * g.spessoreRelativo
        let passo = s * g.passoRelativo
        // Il foro dell'anello più interno: lì dentro sta il contenuto
        let foro = max(0, misura - 2 * s - 2 * CGFloat(max(voci.count - 1, 0)) * passo)
        ZStack {
            ForEach(Array(voci.enumerated()), id: \.element.id) { indice, voce in
                TrattoAnello(
                    frazione: voce.frazione,
                    colore: voce.colore,
                    diametro: max(0, misura - s - 2 * CGFloat(indice) * passo),
                    spessore: s,
                    ritardo: Tema.Apple.Moto.Anello.ritardo(indice: indice, base: ritardo),
                    brilla: brilla == voce.id,
                    impulsoBrillio: impulsoBrillio
                )
            }
            centro
                .lineLimit(1)
                .minimumScaleFactor(g.riduzioneCentro)
                .frame(maxWidth: foro * g.quotaCentro, maxHeight: foro * g.quotaCentro)
        }
        .frame(width: misura, height: misura)
        .accessibilityElement(children: .combine)
    }
}

extension AnelliConcentrici where Centro == EmptyView {
    /// Anelli senza contenuto al centro.
    init(voci: [VoceAnello],
         misura: CGFloat,
         spessore: CGFloat? = nil,
         ritardo: Double = Tema.Apple.Moto.Anello.ritardoFinestra,
         brilla: String? = nil,
         impulsoBrillio: Int = 0) {
        self.init(voci: voci, misura: misura, spessore: spessore, ritardo: ritardo,
                  brilla: brilla, impulsoBrillio: impulsoBrillio) { EmptyView() }
    }
}

/// Un anello singolo, con un contenuto facoltativo al centro (per esempio la percentuale).
///
///     Anello(frazione: 0.52, colore: Tema.Apple.Colore.anello2, misura: 150, spessore: 15) {
///         Text("52%").carattereApple(.centroAnello(32))
///     }
struct Anello<Centro: View>: View {
    let frazione: Double
    let colore: Color
    let misura: CGFloat
    let spessore: CGFloat?
    let ritardo: Double
    let brilla: Bool
    let impulsoBrillio: Int
    let centro: Centro

    /// - Parameters:
    ///   - frazione: 0…1 (fuori intervallo viene limitata).
    ///   - spessore: nil = misura·0,09.
    ///   - brilla: true per far brillare l'anello (quando diventa true o cambia `impulsoBrillio`).
    init(frazione: Double,
         colore: Color,
         misura: CGFloat,
         spessore: CGFloat? = nil,
         ritardo: Double = Tema.Apple.Moto.Anello.ritardoFinestra,
         brilla: Bool = false,
         impulsoBrillio: Int = 0,
         @ViewBuilder centro: () -> Centro) {
        self.frazione = min(max(frazione, 0), 1)
        self.colore = colore
        self.misura = misura
        self.spessore = spessore
        self.ritardo = ritardo
        self.brilla = brilla
        self.impulsoBrillio = impulsoBrillio
        self.centro = centro()
    }

    var body: some View {
        let s = spessore ?? misura * Tema.Apple.Grafico.Anello.spessoreRelativo
        ZStack {
            TrattoAnello(frazione: frazione, colore: colore, diametro: max(0, misura - s), spessore: s,
                         ritardo: ritardo, brilla: brilla, impulsoBrillio: impulsoBrillio)
            centro
        }
        .frame(width: misura, height: misura)
        .accessibilityElement(children: .combine)
    }
}

extension Anello where Centro == EmptyView {
    /// Anello senza contenuto al centro.
    init(frazione: Double,
         colore: Color,
         misura: CGFloat,
         spessore: CGFloat? = nil,
         ritardo: Double = Tema.Apple.Moto.Anello.ritardoFinestra,
         brilla: Bool = false,
         impulsoBrillio: Int = 0) {
        self.init(frazione: frazione, colore: colore, misura: misura, spessore: spessore, ritardo: ritardo,
                  brilla: brilla, impulsoBrillio: impulsoBrillio) { EmptyView() }
    }
}

// MARK: - Un anello con binario, riempimento e brillio

/// Cosa fa brillare l'anello: un solo `onChange` per non accenderlo due volte.
private struct ChiaveBrillioAnello: Equatable {
    let brilla: Bool
    let impulso: Int
}

private struct TrattoAnello: View {
    let frazione: Double
    let colore: Color
    /// Diametro della circonferenza che passa a metà del tratto.
    let diametro: CGFloat
    let spessore: CGFloat
    let ritardo: Double
    let brilla: Bool
    let impulsoBrillio: Int

    @Environment(\.prismaStatoFinale) private var statoFinale
    /// Istantanee: lo stato finale è per sempre, niente da scrivere alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    /// Frazione mostrata (animata).
    @State private var mostrata: Double = 0
    /// Fase del brillio: cresce di 1 a ogni brillio (la parte frazionaria guida l'intensità).
    @State private var faseBrillio: Double = 0

    var body: some View {
        let g = Tema.Apple.Grafico.Anello.self
        ZStack {
            Circle()
                .stroke(colore.opacity(g.opacitaBinario), lineWidth: spessore)
            Circle()
                .trim(from: 0, to: CGFloat(statoFinale ? frazione : mostrata))
                .stroke(colore, style: StrokeStyle(lineWidth: spessore, lineCap: .round))
                .rotationEffect(g.inizio)
                .modifier(BrillioAnello(fase: faseBrillio, colore: colore, attivo: brilla && !statoFinale))
                // Calmo e istantanee: il valore nuovo compare subito, anche dentro un'animazione di chi lo usa.
                .transaction { t in if statoFinale { t.animation = nil } }
        }
        .frame(width: diametro, height: diametro)
        .onAppear(perform: riempi)
        .onChange(of: frazione) { nuova in aggiorna(nuova) }
        .onChange(of: ChiaveBrillioAnello(brilla: brilla, impulso: impulsoBrillio)) { chiave in
            if chiave.brilla { accendiBrillio() }
        }
    }

    /// Primo riempimento, dopo il ritardo.
    private func riempi() {
        guard !statoFinale else {
            // Il tratto mostra già `frazione`: nelle istantanee non serve ricordarla
            if !scatto { mostrata = frazione }
            return
        }
        guard mostrata != frazione else { return }
        withAnimation(Tema.Apple.Moto.Anello.animazione.delay(ritardo)) {
            mostrata = frazione
        }
    }

    /// Nuovo valore: anima dal valore mostrato, con la stessa curva (subito nello stato finale se calmo).
    private func aggiorna(_ nuova: Double) {
        guard !statoFinale else {
            mostrata = nuova
            return
        }
        withAnimation(Tema.Apple.Moto.Anello.animazione) {
            mostrata = nuova
        }
    }

    private func accendiBrillio() {
        guard !statoFinale else { return }
        withAnimation(Tema.Apple.Moto.Brillio.animazioneFase) {
            faseBrillio = faseBrillio.rounded(.down) + 1
        }
    }
}

/// Ombra del colore dell'anello, con l'intensità che segue la fase (sale, resta, scende).
/// A riposo il raggio è 0 e il colore trasparente: nessuna sfocatura da calcolare.
private struct BrillioAnello: ViewModifier, Animatable {
    var fase: Double
    let colore: Color
    let attivo: Bool

    var animatableData: Double {
        get { fase }
        set { fase = newValue }
    }

    func body(content: Content) -> some View {
        let parte = fase - fase.rounded(.down)
        let intensita = attivo ? Tema.Apple.Moto.Brillio.intensita(fase: parte) : 0
        let raggio = intensita > 0
            ? Tema.Apple.Moto.Brillio.sfocatura * Tema.Apple.Ombra.raggioPerSfocatura
            : 0
        return content.shadow(color: colore.opacity(intensita), radius: raggio)
    }
}
