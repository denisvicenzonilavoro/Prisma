import SwiftUI
import Combine
#if canImport(RealityKit)
import RealityKit
import simd
#if os(macOS)
import AppKit
#else
import UIKit
#endif
#endif

// Il cristallo della realtà aumentata in RealityKit («Luce» giro 16, §2.3.2-bis): un solo codice per il palco del Mac
// (anteprima virtuale), l'iPad e l'iPhone (con la fotocamera o sul tavolo virtuale del ripiego). Framework di sistema,
// nessuna dipendenza esterna (decisione 28); solo API presenti su macOS 14 e iOS 17 (niente RealityView né
// GroundingShadowComponent, che sono di iOS 18). Le maglie le costruisce `MotoreRealtaAumentata.maglia` (valori puri);
// qui diventano `MeshResource` con `MeshDescriptor`. Le animazioni le guida chi tiene l'`ARView`, iscritto a
// `SceneEvents.Update` (il tempo del fotogramma): mai un Timer.
// Nello stesso file, fuori da RealityKit: la memoria del calcolo (`CacheRealta`) e lo stato delle etichette
// sopra la vista (`EtichetteRealta`).

/// La memoria del calcolo, come `CacheLuce`: `MotoreRealtaAumentata.calcola` prepara anche la linea della vita.
enum CacheRealta {
    nonisolated(unsafe) private static var memoria: [Int: EsitoRealta] = [:]
    private static let massimo = 8

    static func esito(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventi: [EventoLineaVita],
                      analisi: Analisi360?, oggi: Date = Date()) -> EsitoRealta {
        var h = Hasher()
        h.combine(cliente)
        h.combine(posizioni)
        h.combine(obiettivi)
        h.combine(eventi)
        h.combine(analisi != nil)
        if let a = analisi {
            h.combine(a.previdenza.etaPensione)
            h.combine(a.previdenza.redditoDesiderato)
            h.combine(a.previdenza.pensionePubblica)
            h.combine(a.previdenza.rendimentoReale)
        }
        h.combine(Calendar.current.startOfDay(for: oggi))
        let chiave = h.finalize()
        if let e = memoria[chiave] { return e }
        let e = MotoreRealtaAumentata.calcola(cliente: cliente, posizioni: posizioni, obiettivi: obiettivi, eventi: eventi,
                                              analisi: analisi, oggi: oggi)
        if memoria.count >= massimo { memoria.removeAll() }
        memoria[chiave] = e
        return e
    }
}

/// Lo stato osservato dalle etichette sopra l'ARView (targhetta, pillole degli strati): cambia a ogni fotogramma, lo
/// osservano solo loro (il resto della vista non si ridisegna).
@MainActor
final class EtichetteRealta: ObservableObject {
    @Published var targhetta: CGPoint?
    @Published var strati: [String: CGPoint] = [:]
}

#if canImport(RealityKit)
#if os(macOS)
typealias ColoreRealta = NSColor
#else
typealias ColoreRealta = UIColor
#endif

/// Il cristallo in RealityKit (Mac, iPad, iPhone): uno strato di vetro per classe, il logo sulla faccia alta,
/// l'ombra colorata dipinta sul tavolo, i puntini del piano trovato e l'anello della posa.
@MainActor
final class CristalloRealta {
    private typealias T = Tema.Apple.RealtaAumentata

    /// Il cristallo, figlio dell'ancora: `ModelEntity` perché ha la collisione (i gesti di iOS la vogliono).
    let radice = ModelEntity()
    private(set) var strati: [ModelEntity] = []
    private let logo = ModelEntity()
    private let ombra = ModelEntity()
    private let puntini = Entity()
    private let anello = ModelEntity()
    private(set) var esito: EsitoRealta
    private var colori: [String: SIMD3<Float>] = [:]
    private var estremiFatti: [(basso: Float, alto: Float)] = []
    private var sceltoFatto: String??
    private var ombraFatta: (anno: Int?, esploso: Bool)?
    private var altezzaAttuale: Float = 0

    /// `scala`: metri per unità (`Tema.Apple.RealtaAumentata.metriPerUnita` sul tavolo vero, 1 nella scena virtuale).
    init(esito: EsitoRealta, scala: Float) throws {
        self.esito = esito
        radice.name = "cristallo"
        radice.scale = SIMD3(repeating: scala)
        for s in esito.strati {
            colori[s.id] = T.Vetro.mescola(ColoriLuce.srgb(T.Strati.colore(s.classe)))
        }
        for s in esito.strati {
            let e = ModelEntity()
            e.name = s.id
            strati.append(e)
            radice.addChild(e)
        }
        radice.addChild(logo)
        radice.addChild(ombra)
        radice.addChild(puntini)
        radice.addChild(anello)
        try preparaLogo()
        preparaPuntini()
        preparaAnello()
        try aggiorna(anno: esito.annoOggi, esploso: 0, crescita: 1, scelto: nil)
    }

    /// Anno, esploso (0…1), crescita (0…1), strato scelto: ricostruisce le maglie solo se cambiano gli estremi.
    func aggiorna(anno: Int?, esploso: Double, crescita: Double, scelto: String?) throws {
        let bordi = esito.bordi
        let altezza = esito.altezza(anno: anno)
        let nuovi = esito.strati.indices.map {
            MotoreRealtaAumentata.estremi(strato: $0, bordi: bordi, altezza: altezza, esploso: esploso, crescita: crescita)
        }
        let cambiati = nuovi.count != estremiFatti.count
            || zip(nuovi, estremiFatti).contains { abs($0.0.basso - $0.1.basso) > 1e-4 || abs($0.0.alto - $0.1.alto) > 1e-4 }
        let sceltaCambiata = sceltoFatto == nil || sceltoFatto! != scelto
        if cambiati || sceltaCambiata {
            for (i, s) in esito.strati.enumerated() where i < strati.count {
                let opacita: Float = scelto == nil ? T.Vetro.opacita : (scelto == s.id ? T.Vetro.opacitaScelto : T.Vetro.opacitaAltri)
                let materiale = Self.vetro(colori[s.id] ?? SIMD3(1, 1, 1), opacita: opacita)
                if cambiati {
                    let m = MotoreRealtaAumentata.maglia(basso: nuovi[i].basso, alto: nuovi[i].alto)
                    strati[i].model = ModelComponent(mesh: try Self.risorsa(m, nome: s.id), materials: [materiale])
                } else {
                    strati[i].model?.materials = [materiale]
                }
            }
            if cambiati {
                estremiFatti = nuovi
                let alto = nuovi.last?.alto ?? 0
                logo.position = SIMD3(0, alto + T.Vetro.sopraLogo, 0)
                altezzaAttuale = alto
                // Le forme degli strati (tocco) e la scatola della radice (gesti), solo quando cambiano le maglie
                for e in strati { e.generateCollisionShapes(recursive: false) }
                let lato = MotoreRealtaAumentata.raggio * 2
                radice.collision = CollisionComponent(shapes: [
                    ShapeResource.generateBox(size: SIMD3(lato, max(0.01, alto), lato)).offsetBy(translation: SIMD3(0, alto / 2, 0))
                ])
            }
            sceltoFatto = .some(scelto)
        }
        // L'ombra dipinta si rifà solo al cambio di anno o di esploso, non a ogni fotogramma
        let chiaveOmbra = (anno: anno, esploso: esploso > 0.5)
        if ombraFatta == nil || ombraFatta!.anno != chiaveOmbra.anno || ombraFatta!.esploso != chiaveOmbra.esploso {
            try preparaOmbra()
            ombraFatta = chiaveOmbra
        }
    }

    /// I puntini del piano trovato (0…1).
    func puntiniVisibili(_ opacita: Float) {
        puntini.isEnabled = opacita > 0.001
        puntini.components.set(OpacityComponent(opacity: min(1, max(0, opacita))))
    }

    /// L'anello della posa che si allarga e svanisce (avanzamento 0…1).
    func anelloPosa(_ avanzamento: Float) {
        let a = min(1, max(0, avanzamento))
        anello.isEnabled = a > 0 && a < 1
        let r = T.Puntini.anello * a
        anello.scale = SIMD3(max(0.001, r), 1, max(0.001, r))
        anello.components.set(OpacityComponent(opacity: 1 - a))
    }

    /// Il punto 3D sopra la faccia alta (per la targhetta), in coordinate del mondo.
    func puntoTarghetta() -> SIMD3<Float> {
        radice.convert(position: SIMD3(0, altezzaAttuale + T.Puntini.sopraTarghetta, 0), to: nil)
    }

    /// Il punto accanto a ogni strato (per le pillole), in coordinate del mondo.
    func puntiStrati() -> [String: SIMD3<Float>] {
        var punti: [String: SIMD3<Float>] = [:]
        for (i, s) in esito.strati.enumerated() where i < estremiFatti.count {
            let y = (estremiFatti[i].basso + estremiFatti[i].alto) / 2
            punti[s.id] = radice.convert(position: SIMD3(MotoreRealtaAumentata.raggio * T.Fermo.quotaPillole, y, 0), to: nil)
        }
        return punti
    }

    /// Lo strato toccato (nil fuori dal cristallo).
    func strato(di e: Entity?) -> String? {
        var x = e
        while let corrente = x {
            if esito.strati.contains(where: { $0.id == corrente.name }) { return corrente.name }
            x = corrente.parent
        }
        return nil
    }

    // MARK: - Le parti

    private func preparaLogo() throws {
        let lato = T.Vetro.latoLogo
        guard let immagine = Self.immagineLogo() else { return }
        let tex = try TextureResource.generate(from: immagine, options: .init(semantic: .color))
        var m = UnlitMaterial()
        m.color = .init(tint: .white, texture: .init(tex))
        m.blending = .transparent(opacity: .init(floatLiteral: T.Vetro.opacitaLogo))
        logo.model = ModelComponent(mesh: .generatePlane(width: lato, depth: lato), materials: [m])
    }

    private func preparaOmbra() throws {
        let lato = MotoreRealtaAumentata.raggio * 2 * T.Ombra.allargamento * T.Ombra.margine
        guard let immagine = Self.immagineOmbra(esito.strati.map { colori[$0.id] ?? SIMD3(1, 1, 1) }) else { return }
        let tex = try TextureResource.generate(from: immagine, options: .init(semantic: .color))
        var m = UnlitMaterial()
        m.color = .init(tint: .white, texture: .init(tex))
        m.blending = .transparent(opacity: .init(floatLiteral: Float(T.Ombra.opacita)))
        ombra.model = ModelComponent(mesh: .generatePlane(width: lato, depth: lato), materials: [m])
        ombra.position = SIMD3(T.Ombra.spostamento.x, 0.001, T.Ombra.spostamento.y)
    }

    private func preparaPuntini() {
        var m = UnlitMaterial(color: .white)
        m.blending = .transparent(opacity: .init(floatLiteral: 0.9))
        let mesh = MeshResource.generatePlane(width: T.Puntini.lato, depth: T.Puntini.lato, cornerRadius: T.Puntini.lato / 2)
        let n = T.Puntini.quanti
        for i in 0..<n {
            for j in 0..<n {
                let p = ModelEntity()
                p.model = ModelComponent(mesh: mesh, materials: [m])
                p.position = SIMD3(Float(i - n / 2) * T.Puntini.passo, 0.0005, Float(j - n / 2) * T.Puntini.passo)
                puntini.addChild(p)
            }
        }
        puntiniVisibili(0)
    }

    private func preparaAnello() {
        guard let immagine = Self.immagineAnello(),
              let tex = try? TextureResource.generate(from: immagine, options: .init(semantic: .color)) else { return }
        var m = UnlitMaterial()
        m.color = .init(tint: .white, texture: .init(tex))
        m.blending = .transparent(opacity: .init(floatLiteral: 1))
        anello.model = ModelComponent(mesh: .generatePlane(width: 2, depth: 2), materials: [m])
        anello.position = SIMD3(0, 0.002, 0)
        anelloPosa(0)
    }

    // MARK: - Risorse

    static func risorsa(_ m: MagliaPrisma, nome: String) throws -> MeshResource {
        var d = MeshDescriptor(name: nome)
        d.positions = MeshBuffers.Positions(m.posizioni)
        d.normals = MeshBuffers.Normals(m.normali)
        d.primitives = .triangles(m.indici)
        return try MeshResource.generate(from: [d])
    }

    static func vetro(_ c: SIMD3<Float>, opacita: Float) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: ColoreRealta(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: 1))
        m.roughness = .init(floatLiteral: T.Vetro.ruvidita)
        m.metallic = .init(floatLiteral: 0)
        m.clearcoat = .init(floatLiteral: T.Vetro.vernice)
        m.clearcoatRoughness = .init(floatLiteral: T.Vetro.ruviditaVernice)
        m.blending = .transparent(opacity: .init(floatLiteral: opacita))
        m.faceCulling = .none
        return m
    }

    /// Un'immagine quadrata disegnata in Swift (sRGB, trasparente).
    static func immagine(lato: Int, _ disegna: (CGContext) -> Void) -> CGImage? {
        guard lato > 0, let spazio = CGColorSpace(name: CGColorSpace.sRGB),
              let c = CGContext(data: nil, width: lato, height: lato, bitsPerComponent: 8, bytesPerRow: 0, space: spazio,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        c.clear(CGRect(x: 0, y: 0, width: lato, height: lato))
        disegna(c)
        return c.makeImage()
    }

    /// Il logo di Prisma per la faccia alta.
    static func immagineLogo() -> CGImage? {
        let lato = CGFloat(T.Ombra.lato)
        let r = ImageRenderer(content: LogoPrisma(colore: T.Fermo.coloreLogo).frame(width: lato, height: lato))
        r.proposedSize = ProposedViewSize(width: lato, height: lato)
        r.scale = 1
        return r.cgImage
    }

    /// L'ombra colorata: la pianta del cristallo, allargata e sfumata, a fasce nei colori degli strati.
    static func immagineOmbra(_ colori: [SIMD3<Float>]) -> CGImage? {
        let lato = T.Ombra.lato
        let pianta = MotoreRealtaAumentata.pianta()
        return immagine(lato: lato) { c in
            let mezzo = CGFloat(lato) / 2
            // La pianta occupa 1/1,4 dell'immagine (vedi `preparaOmbra`)
            let scala = mezzo / CGFloat(MotoreRealtaAumentata.raggio * T.Ombra.allargamento * T.Ombra.margine)
            let passi = T.Ombra.passi
            for k in 0..<passi {
                let f = 1 - CGFloat(k) / CGFloat(passi)
                let indice = colori.isEmpty ? 0 : min(colori.count - 1, Int(CGFloat(colori.count) * (1 - f)))
                let col = colori.isEmpty ? SIMD3<Float>(0.3, 0.4, 0.5) : colori[indice]
                c.setFillColor(CGColor(srgbRed: CGFloat(col.x), green: CGFloat(col.y), blue: CGFloat(col.z), alpha: T.Ombra.alfaPasso))
                c.beginPath()
                let allarga = CGFloat(T.Ombra.allargamento) * f
                for (i, p) in pianta.enumerated() {
                    let q = CGPoint(x: mezzo + CGFloat(p.x) * scala * allarga, y: mezzo + CGFloat(p.y) * scala * allarga)
                    if i == 0 { c.move(to: q) } else { c.addLine(to: q) }
                }
                c.closePath()
                c.fillPath()
            }
        }
    }

    /// L'anello bianco della posa.
    static func immagineAnello() -> CGImage? {
        immagine(lato: 128) { c in
            c.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.9))
            c.setLineWidth(5)
            c.strokeEllipse(in: CGRect(x: 6, y: 6, width: 116, height: 116))
        }
    }

    /// Il legno del tavolo virtuale: un gradiente caldo con le venature.
    static func immagineLegno() -> CGImage? {
        let lato = T.Tavolo.lato
        let chiaro = ColoriLuce.srgb(T.Tavolo.legnoChiaro)
        let scuro = ColoriLuce.srgb(T.Tavolo.legnoScuro)
        let venatura = ColoriLuce.srgb(T.Tavolo.venatura)
        return immagine(lato: lato) { c in
            for riga in 0..<lato {
                let f = Float(riga) / Float(lato)
                let col = chiaro + (scuro - chiaro) * f
                c.setFillColor(CGColor(srgbRed: CGFloat(col.x), green: CGFloat(col.y), blue: CGFloat(col.z), alpha: 1))
                c.fill(CGRect(x: 0, y: riga, width: lato, height: 1))
            }
            c.setStrokeColor(CGColor(srgbRed: CGFloat(venatura.x), green: CGFloat(venatura.y), blue: CGFloat(venatura.z), alpha: 0.18))
            c.setLineWidth(1.5)
            for k in 0..<24 {
                let y = CGFloat(k) * CGFloat(lato) / 24 + 6
                c.beginPath()
                c.move(to: CGPoint(x: 0, y: y))
                c.addCurve(to: CGPoint(x: CGFloat(lato), y: y + 4), control1: CGPoint(x: CGFloat(lato) * 0.3, y: y - 5),
                           control2: CGPoint(x: CGFloat(lato) * 0.7, y: y + 9))
                c.strokePath()
            }
        }
    }
}

/// La scena virtuale (palco del Mac, ripiego dell'iPhone e dell'iPad, simulatore): il tavolo di legno, il cristallo, la
/// camera che orbita e la luce con l'ombra. Solo API comuni a Mac e iOS.
@MainActor
final class ScenaVirtualeRealta {
    private typealias K = Tema.Apple.RealtaAumentata.Camera

    let ancora = AnchorEntity(world: .zero)
    let camera = PerspectiveCamera()
    let luce = DirectionalLight()
    let tavolo = ModelEntity()

    /// Prepara la scena sull'`ARView` (sfondo, tavolo, cristallo, camera, luce) e la aggiunge.
    func prepara(_ arView: ARView, cristallo: CristalloRealta) {
        let f = Tema.Apple.RealtaAumentata.Fondo.srgb
        arView.environment.background = .color(ColoreRealta(red: CGFloat(f.x), green: CGFloat(f.y), blue: CGFloat(f.z), alpha: 1))
        let t = Tema.Apple.RealtaAumentata.Tavolo.self
        if let legno = CristalloRealta.immagineLegno(),
           let tex = try? TextureResource.generate(from: legno, options: .init(semantic: .color)) {
            var m = PhysicallyBasedMaterial()
            m.baseColor = .init(tint: .white, texture: .init(tex))
            m.roughness = .init(floatLiteral: t.ruvidita)
            tavolo.model = ModelComponent(mesh: .generatePlane(width: t.larghezza, depth: t.profondita), materials: [m])
        }
        ancora.addChild(tavolo)
        ancora.addChild(cristallo.radice)
        camera.camera.fieldOfViewInDegrees = K.campoVisivo
        ancora.addChild(camera)
        let l = Tema.Apple.RealtaAumentata.Luce.self
        luce.light.intensity = l.intensita
        luce.shadow = DirectionalLightComponent.Shadow(maximumDistance: l.ombra, depthBias: 1)
        luce.look(at: .zero, from: -l.direzione * 4, relativeTo: nil)
        ancora.addChild(luce)
        arView.scene.addAnchor(ancora)
        orbita(azimut: K.azimutIniziale, elevazione: K.elevazione, altezza: Float(cristallo.esito.altezza(anno: nil)), esploso: 0)
    }

    /// La camera sull'orbita: D = 2,9 + 0,75·H + 1,6·e, guarda a metà altezza.
    func orbita(azimut: Float, elevazione: Float, altezza: Float, esploso: Float) {
        let d = K.distanzaBase + K.distanzaAltezza * altezza + K.distanzaEsploso * esploso
        let el = min(max(elevazione, K.elevazioneMinima), K.elevazioneMassima)
        let ty = altezza * K.quotaGuardata
        let da = SIMD3<Float>(d * cos(el) * sin(azimut), ty + d * sin(el), d * cos(el) * cos(azimut))
        camera.look(at: SIMD3(0, ty, 0), from: da, relativeTo: nil)
    }

    func rimuovi(da arView: ARView) {
        arView.scene.removeAnchor(ancora)
    }
}
#endif
