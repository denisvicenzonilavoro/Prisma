import SwiftUI
import Metal
import QuartzCore
#if os(macOS)
import AppKit
import CoreVideo
#elseif os(iOS)
import UIKit
#endif

// Lo shader a tutta tela della versione «Luce» (Design/template-luce-specifica.md §1.4.1 punto 4.4, §1.4.5, decisioni
// 106 e 8 del §1.4.8): un solo fragment shader su un triangolo che copre la vista, con le uniformi del tempo, della
// misura e di quattro parametri. Lo usano il prisma di luce (giro 4) e l'anteprima della realtà aumentata.
// Stesso schema dell'acqua della scrivania: un `CAMetalLayer` (niente MetalKit), sorgente compilata a runtime con
// `makeLibrary(source:)` (niente file .metal: senza Xcode non si compilano), battito dello schermo (CVDisplayLink sul
// Mac, CADisplayLink su iPhone e iPad) a 30 fotogrammi al secondo (20 con il risparmio energetico), disegno su una coda
// propria, mai sul thread principale. Con «Riduci movimento», con Prisma non visibile o a riposo un solo fotogramma,
// quello finale. Nelle istantanee (e se Metal manca o lo shader non si compila) si vede il ripiego in SwiftUI.
//
// Il contratto dello shader: la sorgente data contiene solo la funzione
//     fragment float4 fs_tela(UscitaTela in [[stage_in]], constant UniformiTela &u [[buffer(0)]])
// e può usare `in.uv` (0…1, origine in alto a sinistra), `u.tempo`, `u.risoluzione` (pixel) e `u.parametri`.

/// Le parti fisse dello shader: intestazione, strutture e vertici.
enum ShaderTela {
    static let intestazione = """
    #include <metal_stdlib>
    using namespace metal;

    struct UscitaTela {
        float4 posizione [[position]];
        float2 uv;
    };

    struct UniformiTela {
        float tempo;
        float2 risoluzione;
        float4 parametri;
    };

    vertex UscitaTela vs_tela(uint id [[vertex_id]]) {
        float2 p = float2(float((id << 1) & 2), float(id & 2));
        UscitaTela o;
        o.posizione = float4(p * 2.0 - 1.0, 0.0, 1.0);
        o.uv = float2(p.x, 1.0 - p.y);
        return o;
    }

    """

    /// Lo shader di prova della vetrina: un gradiente che respira, colorato dai parametri.
    static let prova = """
    fragment float4 fs_tela(UscitaTela in [[stage_in]], constant UniformiTela &u [[buffer(0)]]) {
        float onda = 0.5 + 0.5 * sin(u.tempo * 0.8 + in.uv.x * 6.2831);
        float3 a = u.parametri.xyz;
        float3 b = float3(1.0) - a * 0.5;
        return float4(mix(a, b, onda * in.uv.y), 1.0);
    }
    """

    /// Le uniformi come le legge lo shader: tempo, spazio, risoluzione (allineata a 8), parametri (allineati a 16).
    static func uniformi(tempo: Double, pixel: CGSize, parametri: SIMD4<Float>) -> [Float] {
        [Float(tempo), 0, Float(pixel.width), Float(pixel.height), parametri.x, parametri.y, parametri.z, parametri.w]
    }

    /// Metal c'è (mai falso sui Mac supportati; possibile nel simulatore).
    static let disponibile = MetalPrisma.device() != nil

    private static let serratura = NSLock()
    private static var programmi: [String: MTLRenderPipelineState] = [:]
    private static var falliti: Set<String> = []

    /// Il programma della sorgente data, compilato una volta sola (dalla coda del disegno). nil se non si compila.
    static func programma(_ sorgente: String, device: MTLDevice) -> MTLRenderPipelineState? {
        serratura.lock()
        if let p = programmi[sorgente] {
            serratura.unlock()
            return p
        }
        let fallito = falliti.contains(sorgente)
        serratura.unlock()
        guard !fallito else { return nil }
        do {
            let libreria = try device.makeLibrary(source: intestazione + sorgente, options: MTLCompileOptions())
            guard let vs = libreria.makeFunction(name: "vs_tela"), let fs = libreria.makeFunction(name: "fs_tela") else {
                throw NSError(domain: "Prisma.TelaShader", code: 1)
            }
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = vs
            d.fragmentFunction = fs
            d.colorAttachments[0].pixelFormat = .bgra8Unorm
            let p = try device.makeRenderPipelineState(descriptor: d)
            serratura.lock()
            programmi[sorgente] = p
            serratura.unlock()
            return p
        } catch {
            print("Tela shader: sorgente non compilata (\(error.localizedDescription)), resta il ripiego")
            serratura.lock()
            falliti.insert(sorgente)
            serratura.unlock()
            return nil
        }
    }
}

/// La tela con lo shader. `ripiego`: ciò che si vede nelle istantanee, senza Metal o se lo shader non si compila (di
/// solito l'immagine ferma dello stato finale disegnata in SwiftUI).
struct TelaShader<Ripiego: View>: View {
    let sorgente: String
    var parametri: SIMD4<Float> = .zero
    /// Il tempo del fotogramma finale (Riduci movimento, Prisma non visibile).
    var tempoFinale: Double = 0
    let ripiego: Ripiego

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaStatoFinale) private var fermo
    @ObservedObject private var visibilita = VisibilitaPrisma.condivisa
    @State private var rinunciato = false

    init(sorgente: String, parametri: SIMD4<Float> = .zero, tempoFinale: Double = 0,
         @ViewBuilder ripiego: () -> Ripiego) {
        self.sorgente = sorgente
        self.parametri = parametri
        self.tempoFinale = tempoFinale
        self.ripiego = ripiego()
    }

    var body: some View {
        ZStack {
            ripiego
            if !istantanea && !rinunciato && ShaderTela.disponibile {
                TelaShaderMetal(sorgente: sorgente, parametri: parametri, tempoFinale: tempoFinale,
                                animato: !(calmo || fermo || !visibilita.visibile),
                                rinuncia: { rinunciato = true })
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Il disegno (comune a Mac, iPhone e iPad)

/// Disegna lo shader fuori dal thread principale, un fotogramma per volta e mai due in coda.
final class RendererTelaShader: NSObject {
    private struct Condiviso {
        var sorgente = ""
        var parametri = SIMD4<Float>.zero
        var tempoFinale: Double = 0
        var pixel = CGSize.zero
        var inizio: CFTimeInterval = 0
        var inCoda = false
        var ultimo: CFTimeInterval = 0
        var intervallo: Double = 1.0 / Double(Misure.Acqua.fotogrammiAlSecondo)
    }

    private let serratura = NSLock()
    private var condiviso = Condiviso()
    private let coda = DispatchQueue(label: "prisma.tela.shader", qos: .userInteractive, autoreleaseFrequency: .workItem)
    private let device = MetalPrisma.device()
    private lazy var comandi: MTLCommandQueue? = device?.makeCommandQueue()
    /// Solo coda del disegno.
    private var strato: CAMetalLayer?
    /// Chiamata (sul thread principale) se lo shader non si compila.
    var rinuncia: (() -> Void)?

    func collega(_ s: CAMetalLayer) {
        s.device = device
        s.pixelFormat = .bgra8Unorm
        s.framebufferOnly = true
        s.isOpaque = false
        s.maximumDrawableCount = Misure.Acqua.drawable
        coda.async { [weak self] in self?.strato = s }
    }

    func stacca() {
        coda.async { [weak self] in self?.strato = nil }
    }

    func imposta(sorgente: String, parametri: SIMD4<Float>, tempoFinale: Double) {
        serratura.lock()
        let nuova = condiviso.sorgente != sorgente
        condiviso.sorgente = sorgente
        condiviso.parametri = parametri
        condiviso.tempoFinale = tempoFinale
        if nuova { condiviso.inizio = CACurrentMediaTime() }
        let intervallo = ProcessInfo.processInfo.isLowPowerModeEnabled
            ? 1.0 / Double(Misure.Acqua.fotogrammiAlSecondoBassoConsumo) : 1.0 / Double(Misure.Acqua.fotogrammiAlSecondo)
        condiviso.intervallo = intervallo
        serratura.unlock()
    }

    func misura(pixel: CGSize) {
        serratura.lock()
        condiviso.pixel = pixel
        serratura.unlock()
    }

    /// Un battito dello schermo (qualsiasi thread): accoda un fotogramma ogni intervallo.
    func battito(ora: CFTimeInterval) {
        serratura.lock()
        var accoda = false
        if !condiviso.inCoda && (condiviso.ultimo == 0 || ora - condiviso.ultimo >= condiviso.intervallo * 0.9) {
            condiviso.inCoda = true
            condiviso.ultimo = ora
            accoda = true
        }
        serratura.unlock()
        guard accoda else { return }
        coda.async { [weak self] in self?.disegna(finale: false) }
    }

    /// Un solo fotogramma, quello finale (fermo).
    func fermo() {
        coda.async { [weak self] in self?.disegna(finale: true) }
    }

    private func disegna(finale: Bool) {
        serratura.lock()
        let c = condiviso
        serratura.unlock()
        defer {
            if !finale {
                serratura.lock()
                condiviso.inCoda = false
                serratura.unlock()
            }
        }
        guard let device, let comandi, let strato, c.pixel.width >= 1, c.pixel.height >= 1 else { return }
        guard let programma = ShaderTela.programma(c.sorgente, device: device) else {
            DispatchQueue.main.async { [weak self] in self?.rinuncia?() }
            return
        }
        autoreleasepool {
            if strato.drawableSize != c.pixel { strato.drawableSize = c.pixel }
            guard let disegnabile = strato.nextDrawable(), let buffer = comandi.makeCommandBuffer() else { return }
            let passo = MTLRenderPassDescriptor()
            passo.colorAttachments[0].texture = disegnabile.texture
            passo.colorAttachments[0].loadAction = .clear
            passo.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            passo.colorAttachments[0].storeAction = .store
            guard let encoder = buffer.makeRenderCommandEncoder(descriptor: passo) else { return }
            let tempo = finale ? c.tempoFinale : max(0, CACurrentMediaTime() - c.inizio)
            var u = ShaderTela.uniformi(tempo: tempo, pixel: c.pixel, parametri: c.parametri)
            encoder.setRenderPipelineState(programma)
            encoder.setFragmentBytes(&u, length: MemoryLayout<Float>.stride * u.count, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
            buffer.present(disegnabile)
            buffer.commit()
        }
    }
}

// MARK: - Mac

#if os(macOS)

/// La vista con il CAMetalLayer: non prende i clic, avvisa quando cambia misura o finestra.
final class VistaTelaShader: NSView {
    let strato = CAMetalLayer()
    var cambioMisura: ((CGSize) -> Void)?
    var cambioFinestra: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
    }

    required init?(coder: NSCoder) {
        fatalError("VistaTelaShader si crea solo dal codice")
    }

    override func makeBackingLayer() -> CALayer { strato }
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {}
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        aggiornaMisura()
        cambioFinestra?()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        aggiornaMisura()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        aggiornaMisura()
    }

    func aggiornaMisura() {
        let scala = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
        strato.contentsScale = scala
        cambioMisura?(CGSize(width: max(1, (bounds.width * scala).rounded()), height: max(1, (bounds.height * scala).rounded())))
    }
}

private struct TelaShaderMetal: NSViewRepresentable {
    let sorgente: String
    let parametri: SIMD4<Float>
    let tempoFinale: Double
    let animato: Bool
    let rinuncia: () -> Void

    func makeCoordinator() -> BattitoTelaShader { BattitoTelaShader() }

    func makeNSView(context: Context) -> VistaTelaShader {
        let v = VistaTelaShader(frame: .zero)
        let b = context.coordinator
        b.renderer.rinuncia = rinuncia
        b.renderer.collega(v.strato)
        b.renderer.imposta(sorgente: sorgente, parametri: parametri, tempoFinale: tempoFinale)
        v.cambioMisura = { [weak b] px in
            b?.renderer.misura(pixel: px)
            if b?.animato == false { b?.renderer.fermo() }
        }
        v.cambioFinestra = { [weak b, weak v] in b?.finestra = v?.window }
        v.aggiornaMisura()
        b.imposta(animato: animato)
        return v
    }

    func updateNSView(_ v: VistaTelaShader, context: Context) {
        context.coordinator.renderer.imposta(sorgente: sorgente, parametri: parametri, tempoFinale: tempoFinale)
        context.coordinator.imposta(animato: animato)
        // Ferma: i parametri nuovi si vedono subito nel fotogramma finale
        if !animato { context.coordinator.renderer.fermo() }
    }

    static func dismantleNSView(_ v: VistaTelaShader, coordinator: BattitoTelaShader) {
        coordinator.imposta(animato: false, disegnaFermo: false)
        coordinator.renderer.stacca()
    }
}

/// Il battito dello schermo del Mac (CVDisplayLink): acceso solo mentre la tela si muove.
final class BattitoTelaShader: NSObject {
    let renderer = RendererTelaShader()
    private(set) var animato = false
    weak var finestra: NSWindow?
    private var link: CVDisplayLink?

    deinit {
        if let l = link { _ = CVDisplayLinkStop(l) }
    }

    func imposta(animato nuovo: Bool, disegnaFermo: Bool = true) {
        guard nuovo != animato || (nuovo && link == nil) else { return }
        animato = nuovo
        if nuovo {
            if link == nil {
                var l: CVDisplayLink?
                if CVDisplayLinkCreateWithActiveCGDisplays(&l) == kCVReturnSuccess, let l {
                    let r = renderer
                    _ = CVDisplayLinkSetOutputHandler(l) { _, _, _, _, _ in
                        r.battito(ora: CACurrentMediaTime())
                        return kCVReturnSuccess
                    }
                    link = l
                }
            }
            if let l = link { _ = CVDisplayLinkStart(l) }
        } else {
            if let l = link { _ = CVDisplayLinkStop(l) }
            if disegnaFermo { renderer.fermo() }
        }
    }
}

#elseif os(iOS)

/// La vista con il CAMetalLayer su iPhone e iPad.
final class VistaTelaShader: UIView {
    override class var layerClass: AnyClass { CAMetalLayer.self }
    var strato: CAMetalLayer { layer as! CAMetalLayer }
    var cambioMisura: ((CGSize) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("VistaTelaShader si crea solo dal codice")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scala = window?.screen.scale ?? UIScreen.main.scale
        strato.contentsScale = scala
        cambioMisura?(CGSize(width: max(1, (bounds.width * scala).rounded()), height: max(1, (bounds.height * scala).rounded())))
    }
}

private struct TelaShaderMetal: UIViewRepresentable {
    let sorgente: String
    let parametri: SIMD4<Float>
    let tempoFinale: Double
    let animato: Bool
    let rinuncia: () -> Void

    func makeCoordinator() -> BattitoTelaShader { BattitoTelaShader() }

    func makeUIView(context: Context) -> VistaTelaShader {
        let v = VistaTelaShader(frame: .zero)
        let b = context.coordinator
        b.renderer.rinuncia = rinuncia
        b.renderer.collega(v.strato)
        b.renderer.imposta(sorgente: sorgente, parametri: parametri, tempoFinale: tempoFinale)
        v.cambioMisura = { [weak b] px in
            b?.renderer.misura(pixel: px)
            if b?.animato == false { b?.renderer.fermo() }
        }
        b.imposta(animato: animato)
        return v
    }

    func updateUIView(_ v: VistaTelaShader, context: Context) {
        context.coordinator.renderer.imposta(sorgente: sorgente, parametri: parametri, tempoFinale: tempoFinale)
        context.coordinator.imposta(animato: animato)
        if !animato { context.coordinator.renderer.fermo() }
    }

    static func dismantleUIView(_ v: VistaTelaShader, coordinator: BattitoTelaShader) {
        coordinator.imposta(animato: false, disegnaFermo: false)
        coordinator.renderer.stacca()
    }
}

/// Il CADisplayLink trattiene il suo bersaglio: questo intermediario non trattiene il battito.
private final class BersaglioTelaShader: NSObject {
    weak var battito: BattitoTelaShader?

    init(_ b: BattitoTelaShader) { battito = b }

    @objc func scatta(_ link: CADisplayLink) {
        battito?.renderer.battito(ora: link.timestamp)
    }
}

/// Il battito dello schermo di iPhone e iPad (CADisplayLink a 30, o 20 con il risparmio energetico).
final class BattitoTelaShader: NSObject {
    let renderer = RendererTelaShader()
    private(set) var animato = false
    private var link: CADisplayLink?

    deinit { link?.invalidate() }

    func imposta(animato nuovo: Bool, disegnaFermo: Bool = true) {
        guard nuovo != animato || (nuovo && link == nil) else { return }
        animato = nuovo
        if nuovo {
            let l = CADisplayLink(target: BersaglioTelaShader(self), selector: #selector(BersaglioTelaShader.scatta(_:)))
            let fps = Float(ProcessInfo.processInfo.isLowPowerModeEnabled
                            ? Misure.Acqua.fotogrammiAlSecondoBassoConsumo : Misure.Acqua.fotogrammiAlSecondo)
            l.preferredFrameRateRange = CAFrameRateRange(minimum: fps, maximum: fps, preferred: fps)
            l.add(to: .main, forMode: .common)
            link = l
        } else {
            link?.invalidate()
            link = nil
            if disegnaFermo { renderer.fermo() }
        }
    }
}

#endif
