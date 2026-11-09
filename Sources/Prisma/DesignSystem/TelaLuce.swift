import SwiftUI
import Metal
import QuartzCore
import simd
#if os(macOS)
import AppKit
import CoreVideo
#endif

// La tela Metal del prisma di luce (Design/template-luce-specifica.md §2.2.2-ter, «Luce» giro 4), con lo stesso schema
// dell'acqua della scrivania e file propri (l'acqua non si tocca):
// - `ProgrammaLuce`: la sorgente di `ShaderLuce` compilata una volta sola, fuori dal thread principale;
// - `RendererLuce`: lo stato della scena (fasi dell'apertura, rotazione, evidenza dei raggi, passaggio fra due viste),
//   aggiornato a ogni battito con il dt vero dell'orologio dello schermo (le inseguite esponenziali del template, niente
//   Timer), e il disegno su una coda propria («prisma.luce.disegno»);
// - `StatoTelaLuce`: ciò che la vista SwiftUI vede (la rotazione mostrata, per le etichette) e il trascinamento;
// - `TelaLuceMetal`: la `NSView` con il `CAMetalLayer` e il battito `CVDisplayLink` (solo Mac: sull'iPad il prisma di
//   luce arriva con il tavolo, decisione 111).
// 30 fotogrammi al secondo (20 in risparmio energetico), 60 durante il trascinamento e le transizioni (D6). Con
// «Riduci movimento» un solo fotogramma a ogni cambio, tutto già completo; con Prisma nascosto, coperto o a riposo la
// tela si ferma e tiene l'ultima immagine; uscendo dall'esperienza la tela si distrugge (8 GB). Nelle istantanee, se
// Metal manca o lo shader non si compila, si vede `PrismaDiLuceFermo`.

/// Il programma dello shader, condiviso: si compila al primo disegno, dalla coda del disegno.
enum ProgrammaLuce {
    private static let serratura = NSLock()
    private static var programma: MTLRenderPipelineState?
    private static var fallito = false

    /// nil se la sorgente non si compila (resta il fermo-immagine).
    static func pronto(_ device: MTLDevice) -> MTLRenderPipelineState? {
        serratura.lock()
        defer { serratura.unlock() }
        if let p = programma { return p }
        guard !fallito else { return nil }
        do {
            let libreria = try device.makeLibrary(source: ShaderLuce.sorgente, options: MTLCompileOptions())
            guard let vs = libreria.makeFunction(name: "vs_luce"), let fs = libreria.makeFunction(name: "fs_luce") else {
                throw NSError(domain: "Prisma.ShaderLuce", code: 1)
            }
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = vs
            d.fragmentFunction = fs
            d.colorAttachments[0].pixelFormat = .bgra8Unorm
            let p = try device.makeRenderPipelineState(descriptor: d)
            programma = p
            return p
        } catch {
            print("Prisma di luce: shader non compilato (\(error.localizedDescription)), resta il fermo-immagine")
            fallito = true
            return nil
        }
    }

    /// Compila lo shader adesso (prova del motore, `--prova-calcoli`): true se si compila.
    static func provaCompilazione() -> Bool {
        guard let d = MetalPrisma.device() else { return true }
        return pronto(d) != nil
    }
}

/// Ciò che la vista chiede alla scena.
struct ScenaLuce: Equatable {
    /// La misura del palco in punti.
    var misura: CGSize = .zero
    /// Sette bordi cumulati 0…1, sei colori (sRGB 0…1), quante fasce.
    var bordi: [Float] = [0, 1, 1, 1, 1, 1, 1]
    var colori: [SIMD3<Float>] = Array(repeating: .zero, count: 6)
    var n = 0
    /// La fascia sotto il puntatore (o fissata con il clic).
    var scelta: Int?
    /// La lunghezza del ventaglio (punti).
    var lunghezza: Float = 0
    /// Cristallo spento: niente raggio né ventaglio (nessuna posizione in essere).
    var spento = false
    /// «Riduci movimento»: tutto già completo, un solo fotogramma a ogni cambio.
    var fermo = false
}

/// Lo stato della scena e il disegno, fuori dal thread principale. Tutto ciò che cambia passa dalla serratura.
final class RendererLuce: NSObject {
    private typealias M = Tema.Apple.Moto.Luce

    private struct Stato {
        var scena = ScenaLuce()
        var pixel = CGSize.zero
        var pixelPerPunto: CGFloat = 1
        var inizio: CFTimeInterval = 0
        var ultimo: CFTimeInterval = 0
        var ultimoBattito: CFTimeInterval = 0
        var inCoda = false
        // La rotazione mostrata e quella a cui tende (trascinamento, oscillazione)
        var rotazione = 0.0
        var obiettivo = 0.0
        var trascinando = false
        var pesi: [Float] = Array(repeating: 1, count: 6)
        // Il passaggio fra due viste: da dove partono bordi e colori, e quando
        var daBordi: [Float] = [0, 1, 1, 1, 1, 1, 1]
        var daColori: [SIMD3<Float>] = Array(repeating: .zero, count: 6)
        var daN = 0
        var cambio: CFTimeInterval = -10
        var rotazioneComunicata = 0.0
    }

    private let serratura = NSLock()
    private var stato = Stato()
    private let coda = DispatchQueue(label: "prisma.luce.disegno", qos: .userInteractive, autoreleaseFrequency: .workItem)
    private let device = MetalPrisma.device()
    private lazy var comandi: MTLCommandQueue? = device?.makeCommandQueue()
    /// Solo coda del disegno.
    private var strato: CAMetalLayer?
    /// Sul thread principale: la rotazione mostrata è cambiata (per le etichette).
    var rotazioneCambiata: ((Double) -> Void)?
    /// Sul thread principale: lo shader non si compila.
    var rinuncia: (() -> Void)?

    static let disponibile = MetalPrisma.device() != nil

    func collega(_ s: CAMetalLayer) {
        s.device = device
        s.pixelFormat = .bgra8Unorm
        s.framebufferOnly = true
        s.isOpaque = true
        s.maximumDrawableCount = 3
        coda.async { [weak self] in self?.strato = s }
    }

    func stacca() {
        coda.async { [weak self] in self?.strato = nil }
    }

    /// La scena chiesta dalla vista. Se cambiano le fasce parte il passaggio da ciò che si vede adesso.
    func imposta(_ s: ScenaLuce) {
        let ora = CACurrentMediaTime()
        serratura.lock()
        if stato.inizio == 0 { stato.inizio = ora }
        let vecchia = stato.scena
        if vecchia.n > 0, vecchia.bordi != s.bordi || vecchia.colori != s.colori || vecchia.n != s.n {
            let (b, c, n) = mostrati(ora)
            stato.daBordi = b
            stato.daColori = c
            stato.daN = n
            stato.cambio = s.fermo ? -10 : ora
        } else if vecchia.n == 0 {
            stato.daBordi = s.bordi
            stato.daColori = s.colori
            stato.daN = s.n
        }
        stato.scena = s
        serratura.unlock()
    }

    func misura(pixel: CGSize, pixelPerPunto: CGFloat) {
        serratura.lock()
        stato.pixel = pixel
        stato.pixelPerPunto = pixelPerPunto
        serratura.unlock()
    }

    /// La rotazione a cui tende adesso (inizio del trascinamento).
    var rotazioneObiettivo: Double {
        serratura.lock()
        defer { serratura.unlock() }
        return stato.obiettivo
    }

    func trascina(_ r: Double) {
        serratura.lock()
        stato.trascinando = true
        stato.obiettivo = r
        if stato.scena.fermo { stato.rotazione = r }
        serratura.unlock()
    }

    func fineTrascinamento() {
        serratura.lock()
        stato.trascinando = false
        serratura.unlock()
    }

    /// Bordi, colori e numero di fasce che si vedono adesso (a metà di un passaggio, quelli interpolati).
    private func mostrati(_ ora: CFTimeInterval) -> ([Float], [SIMD3<Float>], Int) {
        let k = Float(M.dentroFuoriCubica((ora - stato.cambio) / M.cambioVista))
        guard k < 1 else { return (stato.scena.bordi, stato.scena.colori, stato.scena.n) }
        let b = (0..<7).map { stato.daBordi[$0] + (stato.scena.bordi[$0] - stato.daBordi[$0]) * k }
        let c = (0..<6).map { stato.daColori[$0] + (stato.scena.colori[$0] - stato.daColori[$0]) * k }
        return (b, c, max(stato.scena.n, stato.daN))
    }

    /// Un battito dello schermo (qualsiasi thread): accoda un fotogramma ogni intervallo, mai due in coda.
    func battito(ora: CFTimeInterval) {
        serratura.lock()
        let s = stato
        let transizione = s.trascinando || ora - s.cambio < M.cambioVista
            || ora - s.inizio < M.ventaglio.inizio + M.ventaglio.durata
        let fps = ProcessInfo.processInfo.isLowPowerModeEnabled ? M.fotogrammiRisparmio
            : (transizione ? M.fotogrammiTransizione : M.fotogrammi)
        let intervallo = 1.0 / Double(fps)
        var accoda = false
        if !s.inCoda && (s.ultimoBattito == 0 || ora - s.ultimoBattito >= intervallo * 0.9) {
            stato.inCoda = true
            stato.ultimoBattito = ora
            accoda = true
        }
        serratura.unlock()
        guard accoda else { return }
        coda.async { [weak self] in self?.disegna(fermo: false) }
    }

    /// Un solo fotogramma (Riduci movimento, dopo un cambio).
    func fotogrammaFermo() {
        coda.async { [weak self] in self?.disegna(fermo: true) }
    }

    /// Aggiorna lo stato al tempo `ora` e ne ricava le uniformi.
    private func avanza(ora: CFTimeInterval, fermo: Bool) -> ShaderLuce.Strato {
        serratura.lock()
        defer { serratura.unlock() }
        let calmo = fermo || stato.scena.fermo
        let t = calmo ? M.tempoFermo : ora - stato.inizio
        let dt = stato.ultimo == 0 ? 0 : min(M.dtMassimo, max(0, ora - stato.ultimo))
        stato.ultimo = ora
        func liscio(_ k: Double) -> Double { 1 - exp(-dt * k) }
        let s = stato.scena
        if calmo {
            stato.rotazione = stato.obiettivo
            for i in 0..<6 { stato.pesi[i] = s.scelta == nil ? 1 : (i == s.scelta ? M.evidenzaScelto : M.evidenzaAltri) }
            stato.cambio = -10
        } else {
            if !stato.trascinando {
                let oscillazione = sin(t * M.oscillazionePulsazione) * M.oscillazioneAmpiezza
                stato.obiettivo += (oscillazione - stato.obiettivo) * liscio(M.oscillazioneInseguimento)
            }
            stato.rotazione += (stato.obiettivo - stato.rotazione) * liscio(M.inseguimentoRotazione)
            for i in 0..<6 {
                let meta: Float = s.scelta == nil ? 1 : (i == s.scelta ? M.evidenzaScelto : M.evidenzaAltri)
                stato.pesi[i] += (meta - stato.pesi[i]) * Float(liscio(M.evidenzaInseguimento))
            }
        }
        let (bordi, colori, n) = mostrati(ora)
        let fasi: SIMD3<Float>
        if calmo {
            fasi = s.spento ? SIMD3(0, 1, 0) : SIMD3(1, 1, 1)
        } else {
            let vetro = Float(M.vetro.valore(t))
            fasi = s.spento ? SIMD3(0, vetro, 0)
                : SIMD3(Float(M.raggio.valore(t)), vetro, Float(M.ventaglio.valore(t)))
        }
        let geo = GeometriaLuce(misura: s.misura)
        var u = ShaderLuce.Strato()
        u.pixel = stato.pixel
        u.pixelPerPunto = Float(stato.pixelPerPunto)
        u.tempo = Float(t)
        u.centro = geo.centro
        u.raggio = Float(geo.raggio)
        u.rotazione = Float(stato.rotazione)
        u.fasi = fasi
        u.lunghezza = s.lunghezza
        u.n = n
        u.respiro = Float(M.respiroBase + M.respiroAmpiezza * sin(t * M.respiroPulsazione))
        u.bordi = bordi
        u.pesi = stato.pesi
        u.colori = colori
        if abs(stato.rotazione - stato.rotazioneComunicata) > M.sogliaRotazione {
            stato.rotazioneComunicata = stato.rotazione
            let r = stato.rotazione
            DispatchQueue.main.async { [weak self] in self?.rotazioneCambiata?(r) }
        }
        return u
    }

    private func disegna(fermo: Bool) {
        defer {
            if !fermo {
                serratura.lock()
                stato.inCoda = false
                serratura.unlock()
            }
        }
        guard let device, let comandi, let strato else { return }
        guard let programma = ProgrammaLuce.pronto(device) else {
            DispatchQueue.main.async { [weak self] in self?.rinuncia?() }
            return
        }
        let u = avanza(ora: CACurrentMediaTime(), fermo: fermo)
        guard u.pixel.width >= 1, u.pixel.height >= 1 else { return }
        autoreleasepool {
            if strato.drawableSize != u.pixel { strato.drawableSize = u.pixel }
            guard let disegnabile = strato.nextDrawable(), let buffer = comandi.makeCommandBuffer() else { return }
            let passo = MTLRenderPassDescriptor()
            passo.colorAttachments[0].texture = disegnabile.texture
            passo.colorAttachments[0].loadAction = .dontCare
            passo.colorAttachments[0].storeAction = .store
            guard let encoder = buffer.makeRenderCommandEncoder(descriptor: passo) else { return }
            var valori = u.impacchettate
            encoder.setRenderPipelineState(programma)
            encoder.setFragmentBytes(&valori, length: MemoryLayout<Float>.stride * valori.count, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
            buffer.present(disegnabile)
            buffer.commit()
        }
    }
}

/// La rotazione mostrata, a parte: cambia a ogni fotogramma e la osservano solo le etichette e il puntatore.
final class RotazioneLuce: ObservableObject {
    @Published fileprivate(set) var valore: Double = 0
}

/// Ciò che la vista del palco vede della tela: la rotazione mostrata (per le etichette e il puntatore), il trascinamento
/// del cristallo e la rinuncia allo shader. Senza Metal (istantanee, ripiego) la rotazione la tiene questo oggetto,
/// senza oscillazione.
final class StatoTelaLuce: ObservableObject {
    let rotazione = RotazioneLuce()
    @Published fileprivate(set) var rinunciato = false
    let renderer = RendererLuce()
    /// La tela Metal è montata.
    fileprivate(set) var metalAttivo = false
    /// La tela Metal si muove (non ferma).
    fileprivate(set) var animato = false
    private var base = 0.0

    init() {
        renderer.rotazioneCambiata = { [weak self] r in
            guard let self, self.metalAttivo, self.animato else { return }
            self.rotazione.valore = r
        }
        renderer.rinuncia = { [weak self] in
            self?.metalAttivo = false
            self?.rinunciato = true
        }
    }

    func iniziaTrascinamento() {
        base = metalAttivo ? renderer.rotazioneObiettivo : rotazione.valore
    }

    /// Il trascinamento di `dx` punti dall'inizio: 520 punti = 1 rad, al più ±0,22.
    func trascina(_ dx: CGFloat) {
        let m = Tema.Apple.Moto.Luce.self
        let r = min(m.rotazioneMassima, max(-m.rotazioneMassima, base + Double(dx / m.puntiPerRadiante)))
        renderer.trascina(r)
        if !(metalAttivo && animato) {
            rotazione.valore = r
            if metalAttivo { renderer.fotogrammaFermo() }
        }
    }

    func fineTrascinamento() { renderer.fineTrascinamento() }
}

#if os(macOS)

/// La vista con il CAMetalLayer: non prende i clic (li prende la vista SwiftUI sopra), avvisa quando cambia misura.
final class VistaTelaLuce: NSView {
    let strato = CAMetalLayer()
    var cambioMisura: ((CGSize, CGFloat) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
    }

    required init?(coder: NSCoder) {
        fatalError("VistaTelaLuce si crea solo dal codice")
    }

    override func makeBackingLayer() -> CALayer { strato }
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {}
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        aggiornaMisura()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        aggiornaMisura()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        aggiornaMisura()
    }

    /// Al più 1,6 pixel per punto (`Tema.Apple.Luce.scalaRisoluzione`).
    func aggiornaMisura() {
        let schermo = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
        let scala = min(Tema.Apple.Luce.scalaRisoluzione, schermo)
        strato.contentsScale = scala
        cambioMisura?(CGSize(width: max(1, (bounds.width * scala).rounded()), height: max(1, (bounds.height * scala).rounded())), scala)
    }
}

/// La tela del prisma di luce. `animato` è falso con «Riduci movimento» o con Prisma che non si vede.
struct TelaLuceMetal: NSViewRepresentable {
    /// Non osservato: la rotazione che cambia a ogni fotogramma non ridisegna la vista.
    let tela: StatoTelaLuce
    let scena: ScenaLuce
    let animato: Bool

    func makeCoordinator() -> BattitoLuce { BattitoLuce(renderer: tela.renderer) }

    func makeNSView(context: Context) -> VistaTelaLuce {
        let v = VistaTelaLuce(frame: .zero)
        let b = context.coordinator
        let r = tela.renderer
        r.collega(v.strato)
        r.imposta(scena)
        v.cambioMisura = { [weak b] px, scala in
            r.misura(pixel: px, pixelPerPunto: scala)
            if b?.animato == false { r.fotogrammaFermo() }
        }
        v.aggiornaMisura()
        tela.metalAttivo = true
        tela.animato = animato
        b.imposta(animato: animato)
        return v
    }

    func updateNSView(_ v: VistaTelaLuce, context: Context) {
        tela.renderer.imposta(scena)
        tela.animato = animato
        context.coordinator.imposta(animato: animato)
        // Ferma: i cambi (vista, anno, raggio, rotazione a mano) si vedono subito in un fotogramma
        if !animato { tela.renderer.fotogrammaFermo() }
    }

    static func dismantleNSView(_ v: VistaTelaLuce, coordinator: BattitoLuce) {
        coordinator.imposta(animato: false)
        coordinator.renderer.stacca()
    }
}

/// Il battito dello schermo (CVDisplayLink): acceso solo mentre la tela si muove.
final class BattitoLuce: NSObject {
    let renderer: RendererLuce
    private(set) var animato = false
    private var link: CVDisplayLink?

    init(renderer: RendererLuce) {
        self.renderer = renderer
    }

    deinit {
        if let l = link { _ = CVDisplayLinkStop(l) }
    }

    func imposta(animato nuovo: Bool) {
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
        } else if let l = link {
            _ = CVDisplayLinkStop(l)
        }
    }
}

#endif
