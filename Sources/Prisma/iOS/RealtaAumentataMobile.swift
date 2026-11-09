#if os(iOS)
import AVFoundation
import Combine
import SwiftUI
import UIKit
#if canImport(RealityKit)
import RealityKit
#endif
#if !targetEnvironment(simulator)
import ARKit
#endif

// Sala › La realtà aumentata sull'iPhone e sull'iPad («Luce» giro 16, §2.3.1 e §2.3.4, decisioni 26, 27, 28 e 107).
// - Da soli (Sala › La realtà aumentata, con i dati della copia di «Prisma ovunque»): il palco con il cristallo fermo e
//   «Apri in realtà aumentata», che apre la fotocamera a tutto schermo. «Fine» chiude la sessione e spegne la
//   fotocamera. Lo scatto qui è spento: l'iPhone non scrive nell'archivio, lo scatto arriva nel dossier solo al tavolo.
// - Al tavolo (l'iPad collegato al Mac, genere `realtaAumentata`): la stessa vista senza «Fine» (si esce dal Mac); lo
//   scatto va al Mac in rete locale cifrata (`FotoRealtaTavolo`) e il Mac lo archivia nei Documenti del cliente.
// - ARKit sul dispositivo vero: piano orizzontale, il cristallo si posa dove punta il centro dello schermo, un tocco sul
//   piano lo sposta, due dita lo ruotano, un tocco su uno strato lo evidenzia. Occlusione delle persone spenta. Le
//   immagini della fotocamera restano in memoria: nessuna mappa dell'ambiente si salva, nulla va nel Rullino.
// - Ripiego (simulatore, dispositivo senza AR, fotocamera negata): il tavolo virtuale con lo stesso codice del Mac.
// - Sessione in pausa quando l'app va in secondo piano, distrutta all'uscita. Nessun lavoro in background.

private typealias RA = Tema.Apple.RealtaAumentata

// MARK: - Il palco della Sala (iPhone e iPad da soli)

struct PalcoRealtaAumentata: View {
    @Environment(StatoShell.self) var stato
    let cliente: Cliente
    var inSala = false

    @Environment(\.istantaneaSchermo) private var istantaneaSchermo
    @Environment(\.modoIstantanea) private var modoIstantanea
    @Environment(\.prismaCalmo) private var calmo
    @State private var aperta = false

    var body: some View {
        let _ = ContaCorpi.segna()
        let id = cliente.id
        let esito = CacheRealta.esito(cliente: stato.cliente(id) ?? cliente, posizioni: stato.posizioniCliente(id),
                                      obiettivi: stato.obiettiviCliente(id), eventi: stato.eventiVitaCliente(id),
                                      analisi: stato.dati.analisi[id])
        let primo = TestiRealta.primoNome(cliente.nome)
        let prova = (istantaneaSchermo || modoIstantanea) ? stato.sala.realtaIstantanea : nil
        let anno = prova.map { $0.allaPensione ? esito.annoFine : ($0.anno ?? esito.annoOggi) } ?? esito.annoOggi
        ScrollView {
            VStack(alignment: .leading, spacing: RA.Mobile.spazio) {
                CristalloFermo(esito: esito, anno: anno, esploso: prova?.esploso ?? false, scelto: prova?.scelto, fondo: .tavoloLegno)
                    .frame(height: RA.Mobile.altezzaAnteprima)
                    .clipShape(RoundedRectangle(cornerRadius: RA.Mobile.raggioAnteprima, style: .continuous))
                ColonnaRealta(esito: esito, primo: primo, anno: anno)
                Button { aperta = true } label: {
                    Text(TestiRealta.apri).frame(maxWidth: .infinity)
                }
                .buttonStyle(.applePrimario)
                .disabled(esito.vuota || inSala)
                .accessibilityHint(Text(esito.vuota ? TestiRealta.senzaPosizioni(primo) : TestiRealta.notaAnteprima))
            }
            .padding(RA.Mobile.margine)
        }
        .fullScreenCover(isPresented: $aperta) {
            RealtaAumentataMobile(esito: esito, nome: primo, scattoConStanza: stato.dati.impostazioni.sala.scattoConStanza,
                                  modo: .daSolo)
                .environment(\.istantaneaSchermo, istantaneaSchermo)
                .prismaCalmo(calmo)
        }
    }
}

// MARK: - La vista a tutto schermo

/// Lo stato della fotocamera e del piano, osservato dalle sovrapposizioni.
@MainActor
final class StatoARRealta: ObservableObject {
    enum Modo: Equatable {
        /// Si aspetta la risposta sul permesso della fotocamera.
        case attesa
        /// ARKit con la fotocamera.
        case ar
        /// Il tavolo virtuale: simulatore, dispositivo senza AR o fotocamera negata.
        case virtuale(motivo: String?, negata: Bool)
    }

    @Published var modo: Modo = .attesa
    @Published var trovato = false
    @Published var tracciamento: String?

    /// Il dispositivo sa fare la realtà aumentata (nel simulatore mai).
    static var arPossibile: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return ARWorldTrackingConfiguration.isSupported
        #endif
    }

    /// Controlla a ogni apertura il supporto e il permesso della fotocamera; `.notDetermined` lo chiede.
    func prepara() {
        guard Self.arPossibile else {
            modo = .virtuale(motivo: TestiRealta.fotocameraAssente, negata: false)
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            modo = .ar
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] concesso in
                Task { @MainActor in
                    self?.modo = concesso ? .ar : .virtuale(motivo: TestiRealta.fotocameraNegata, negata: true)
                }
            }
        default:
            modo = .virtuale(motivo: TestiRealta.fotocameraNegata, negata: true)
        }
    }
}

struct RealtaAumentataMobile: View {
    enum Modo {
        /// iPhone o iPad da soli: «Fine», scatto spento.
        case daSolo
        /// Al tavolo con il Mac: niente «Fine», lo scatto va al Mac con l'id di ciò che il Mac mostra.
        case tavolo(id: String, mandaFoto: (FotoRealtaTavolo) -> Void)
    }

    let esito: EsitoRealta
    let nome: String
    let scattoConStanza: Bool
    let modo: Modo
    /// Al tavolo: «Foto salvata nel dossier di …», rimandato dal Mac.
    var ultimoScatto: String?

    @Environment(\.dismiss) private var chiudi
    @Environment(\.scenePhase) private var fase
    @Environment(\.istantaneaSchermo) private var istantaneaSchermo
    @Environment(\.modoIstantanea) private var modoIstantanea
    @Environment(\.prismaCalmo) private var calmo
    @StateObject private var statoAR = StatoARRealta()
    @StateObject private var controllo = ControlloScenaRealta()
    @State private var anno: Int?
    @State private var esploso = false
    @State private var scelto: String?
    @State private var lampo = false
    @State private var avviso: String?
    @State private var confermaStanza = false
    @State private var targhetta = false

    private var istantanea: Bool { istantaneaSchermo || modoIstantanea }

    private var alTavolo: Bool {
        if case .tavolo = modo { return true }
        return false
    }

    var body: some View {
        let annoMostrato = anno ?? esito.annoOggi
        ZStack {
            Color.black.ignoresSafeArea()
            scena(annoMostrato)
                .ignoresSafeArea()
            if !esito.vuota {
                if istantanea || controllo.guasto {
                    EtichetteFermeRealta(esito: esito, nome: nome, anno: annoMostrato, esploso: esploso, scelto: scelto,
                                         targhettaVisibile: true)
                } else {
                    EtichetteSopraRealta(etichette: controllo.etichette, esito: esito, nome: nome, anno: annoMostrato,
                                         esploso: esploso, scelto: scelto, targhettaVisibile: targhetta)
                }
            }
            sovrapposizioni(annoMostrato)
            LampoRealta(attivo: lampo).ignoresSafeArea()
        }
        .environment(\.colorScheme, .light)
        .statusBarHidden()
        .onAppear {
            anno = esito.annoOggi
            controllo.anno = esito.annoOggi
            controllo.calmo = calmo
            controllo.sceltoCambiato = { s in scelto = s }
            if istantanea {
                statoAR.trovato = true
                targhetta = true
            } else {
                statoAR.prepara()
            }
        }
        .onChange(of: anno) { _, v in controllo.anno = v }
        .onChange(of: esploso) { _, v in controllo.esploso = v }
        .onChange(of: scelto) { _, v in controllo.scelto = v }
        .onChange(of: statoAR.trovato) { _, v in
            guard v else { return }
            Task { @MainActor in
                let attesa = calmo ? 0 : M.targhettaDopoPosa
                try? await Task.sleep(nanoseconds: UInt64(attesa * 1_000_000_000))
                withAnimation(Tema.Apple.Moto.animazione(.easeOut(duration: M.targhettaDurata), calmo: calmo)) { targhetta = true }
            }
        }
        .onChange(of: ultimoScatto) { _, v in
            guard let v else { return }
            avviso = v
        }
        .confirmationDialog(TestiRealta.confermaStanza(nome), isPresented: $confermaStanza, titleVisibility: .visible) {
            Button("Manda la foto con la stanza") { scattaConStanza(annoMostrato) }
            Button("Solo il cristallo") { scattaCristallo(annoMostrato) }
            Button("Annulla", role: .cancel) {}
        }
    }

    private typealias M = Tema.Apple.Moto.RealtaAumentata

    @ViewBuilder
    private func scena(_ annoMostrato: Int?) -> some View {
        if istantanea || esito.vuota || controllo.guasto {
            CristalloFermo(esito: esito, anno: annoMostrato, esploso: esploso, scelto: scelto, fondo: .tavoloLegno)
        } else {
            switch statoAR.modo {
            case .attesa:
                Color.black
            case .ar:
                #if canImport(RealityKit)
                VistaARRealta(esito: esito, conFotocamera: true, controllo: controllo, statoAR: statoAR, attiva: fase == .active)
                #else
                CristalloFermo(esito: esito, anno: annoMostrato, esploso: esploso, scelto: scelto, fondo: .tavoloLegno)
                #endif
            case .virtuale:
                #if canImport(RealityKit)
                VistaARRealta(esito: esito, conFotocamera: false, controllo: controllo, statoAR: statoAR, attiva: fase == .active)
                #else
                CristalloFermo(esito: esito, anno: annoMostrato, esploso: esploso, scelto: scelto, fondo: .tavoloLegno)
                #endif
            }
        }
    }

    private func sovrapposizioni(_ annoMostrato: Int?) -> some View {
        let trovato = statoAR.trovato || statoAR.modo != .ar
        return VStack(spacing: RA.Barra.spazio) {
            HStack {
                PillolaRealta(testo: TestiRealta.marchio)
                Spacer()
                PillolaRealta(testo: statoAR.tracciamento ?? (trovato ? TestiRealta.tavoloTrovato : TestiRealta.cercoSuperficie),
                              verde: trovato && statoAR.tracciamento == nil)
                if case .daSolo = modo {
                    Button(TestiRealta.fine) { chiudi() }
                        .buttonStyle(.plain)
                        .carattereApple(RA.Pillola.testo)
                        .foregroundStyle(RA.Pillola.inchiostro)
                        .padding(RA.Pillola.padding)
                        .background(Capsule().fill(RA.Pillola.fondo))
                }
            }
            .padding(RA.Pillola.margine)
            Spacer()
            if statoAR.modo == .ar && !statoAR.trovato && !istantanea {
                GuidaRealta(testo: UIDevice.current.userInterfaceIdiom == .pad ? TestiRealta.guida : TestiRealta.guidaTelefono)
                    .transition(.opacity)
                Spacer()
            }
            if case .virtuale(let motivo, let negata) = statoAR.modo, let motivo, !istantanea {
                AvvisoRealta(testo: motivo, azione: negata ? (titolo: TestiRealta.consentiImpostazioni, fai: apriImpostazioni) : nil)
            }
            if let avviso { AvvisoRealta(testo: avviso).transition(.opacity) }
            if esito.vuota {
                AvvisoRealta(testo: TestiRealta.senzaPosizioni(nome))
            } else {
                if esito.anni.isEmpty, let motivo = esito.motivoSenzaAnni { AvvisoRealta(testo: motivo) }
                BarraRealta(anni: esito.anni, anno: $anno, esploso: $esploso, scattoAcceso: alTavolo,
                            aiutoScatto: alTavolo ? nil : TestiRealta.scattoSoloAlTavolo) { scatta(annoMostrato) }
                if !alTavolo {
                    Text(TestiRealta.scattoSoloAlTavolo)
                        .carattereApple(RA.Pillola.testo)
                        .foregroundStyle(RA.Pillola.inchiostro.opacity(RA.Barra.opacitaAnno))
                }
            }
        }
        .padding(.bottom, RA.Barra.distanzaFondo)
    }

    private func apriImpostazioni() {
        if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
    }

    /// Lo scatto al tavolo: il cristallo su fondo neutro; con l'interruttore acceso e la fotocamera, prima la conferma
    /// della stanza (decisione 27). Mai nel Rullino.
    private func scatta(_ annoMostrato: Int?) {
        guard alTavolo else { return }
        if scattoConStanza && statoAR.modo == .ar && controllo.scattaConStanza != nil {
            confermaStanza = true
        } else {
            scattaCristallo(annoMostrato)
        }
    }

    private func scattaCristallo(_ annoMostrato: Int?) {
        guard case .tavolo(let id, let manda) = modo,
              let immagine = CristalloFermo.scatto(esito, anno: annoMostrato, esploso: esploso),
              let png = ProtocolloTavolo.png(immagine) else {
            avviso = TestiRealta.scattoGuasto
            return
        }
        manda(FotoRealtaTavolo(id: id, immagine: png, conStanza: false, anno: annoScatto(annoMostrato), esploso: esploso))
        lampeggia()
    }

    private func scattaConStanza(_ annoMostrato: Int?) {
        guard case .tavolo(let id, let manda) = modo, let scatto = controllo.scattaConStanza else { return }
        let anno = annoScatto(annoMostrato)
        let esploso = esploso
        scatto { immagine in
            guard let immagine,
                  let ridotta = ProtocolloTavolo.riduci(immagine, lato: ProtocolloTavolo.latoFoto),
                  let jpeg = ProtocolloTavolo.jpeg(ridotta, qualita: 0.8), jpeg.count <= ProtocolloTavolo.massimoFoto else {
                avviso = TestiRealta.scattoGuasto
                return
            }
            manda(FotoRealtaTavolo(id: id, immagine: jpeg, conStanza: true, anno: anno, esploso: esploso))
            lampeggia()
        }
    }

    private func annoScatto(_ a: Int?) -> Int { a ?? esito.annoOggi ?? Calendar.current.component(.year, from: Date()) }

    private func lampeggia() {
        lampo = true
        DispatchQueue.main.async {
            withAnimation(Tema.Apple.Moto.animazione(.easeOut(duration: M.lampo), calmo: calmo)) { lampo = false }
        }
    }
}

// MARK: - La vista RealityKit

#if canImport(RealityKit)
/// L'`ARView`: con la fotocamera (ARKit, solo sul dispositivo vero) o sul tavolo virtuale (stesso codice del Mac).
struct VistaARRealta: UIViewRepresentable {
    let esito: EsitoRealta
    let conFotocamera: Bool
    let controllo: ControlloScenaRealta
    let statoAR: StatoARRealta
    /// false quando l'app non è in primo piano: la sessione va in pausa.
    let attiva: Bool

    final class Coordinatore {
        var virtuale: CoordinatoreScenaRealta?
        #if !targetEnvironment(simulator)
        var ar: CoordinatoreARRealta?
        #endif
    }

    func makeCoordinator() -> Coordinatore { Coordinatore() }

    func makeUIView(context: Context) -> ARView {
        #if targetEnvironment(simulator)
        // Nel simulatore l'ARView è già senza fotocamera (cameraMode e la sessione non ci sono)
        let vista = ARView(frame: .zero)
        let v = CoordinatoreScenaRealta()
        v.avvia(vista, esito: esito, controllo: controllo)
        context.coordinator.virtuale = v
        DispatchQueue.main.async { statoAR.trovato = true }
        #else
        let vista: ARView
        if conFotocamera {
            vista = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
            let a = CoordinatoreARRealta(esito: esito, controllo: controllo, statoAR: statoAR)
            a.avvia(vista)
            context.coordinator.ar = a
        } else {
            vista = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
            let v = CoordinatoreScenaRealta()
            v.avvia(vista, esito: esito, controllo: controllo)
            context.coordinator.virtuale = v
            DispatchQueue.main.async { statoAR.trovato = true }
        }
        #endif
        return vista
    }

    func updateUIView(_ vista: ARView, context: Context) {
        #if !targetEnvironment(simulator)
        context.coordinator.ar?.pausa(!attiva)
        #endif
    }

    static func dismantleUIView(_ vista: ARView, coordinator: Coordinatore) {
        coordinator.virtuale?.ferma(vista)
        coordinator.virtuale = nil
        #if !targetEnvironment(simulator)
        coordinator.ar?.ferma(vista)
        coordinator.ar = nil
        #endif
    }
}
#endif

#if canImport(RealityKit) && !targetEnvironment(simulator)
/// La sessione ARKit del dispositivo vero: piano orizzontale, posa al centro dello schermo, tocchi e rotazione.
@MainActor
final class CoordinatoreARRealta: NSObject, ARSessionDelegate {
    private typealias M = Tema.Apple.Moto.RealtaAumentata

    let esito: EsitoRealta
    private weak var controllo: ControlloScenaRealta?
    private weak var statoAR: StatoARRealta?
    private weak var vista: ARView?
    private var cristallo: CristalloRealta?
    private var ancora: AnchorEntity?
    private var aggiornamento: Cancellable?
    private var gestiInstallati = false
    private var t: Double = 0
    private var trovatoA: Double?
    private var posatoA: Double?
    private var esploso: Double = 0
    private var inPausa = false

    init(esito: EsitoRealta, controllo: ControlloScenaRealta, statoAR: StatoARRealta) {
        self.esito = esito
        self.controllo = controllo
        self.statoAR = statoAR
        super.init()
    }

    /// La configurazione: piani orizzontali, luce dell'ambiente; niente occlusione delle persone (decisione 107).
    private static func configurazione() -> ARWorldTrackingConfiguration {
        let c = ARWorldTrackingConfiguration()
        c.planeDetection = [.horizontal]
        c.environmentTexturing = .automatic
        return c
    }

    func avvia(_ v: ARView) {
        vista = v
        guard let cr = try? CristalloRealta(esito: esito, scala: Tema.Apple.RealtaAumentata.metriPerUnita) else {
            controllo?.guasto = true
            return
        }
        cristallo = cr
        v.session.delegate = self
        v.session.run(Self.configurazione())
        v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tocco(_:))))
        aggiornamento = v.scene.subscribe(to: SceneEvents.Update.self) { [weak self] evento in
            let dt = evento.deltaTime
            MainActor.assumeIsolated { self?.fotogramma(dt) }
        }
        // Lo scatto con la stanza: l'immagine della vista, in memoria
        controllo?.scattaConStanza = { [weak v] fatto in
            guard let v else { return fatto(nil) }
            v.snapshot(saveToHDR: false) { immagine in fatto(immagine?.cgImage) }
        }
    }

    func pausa(_ si: Bool) {
        guard let v = vista, si != inPausa else { return }
        inPausa = si
        if si { v.session.pause() } else { v.session.run(Self.configurazione()) }
    }

    func ferma(_ v: ARView) {
        aggiornamento?.cancel()
        aggiornamento = nil
        v.session.pause()
        v.session.delegate = nil
        for a in Array(v.scene.anchors) { v.scene.removeAnchor(a) }
        controllo?.scattaConStanza = nil
        cristallo = nil
        ancora = nil
    }

    // MARK: ARSessionDelegate (dalla coda della sessione: si torna sul thread principale)

    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard anchors.contains(where: { $0 is ARPlaneAnchor }) else { return }
        Task { @MainActor [weak self] in self?.pianoTrovato() }
    }

    nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var testo: String?
        if case .limited(let motivo) = camera.trackingState {
            switch motivo {
            case .excessiveMotion: testo = TestiRealta.piuLentamente
            case .insufficientFeatures: testo = TestiRealta.serveLuce
            default: testo = nil
            }
        }
        let t = testo
        Task { @MainActor [weak self] in self?.statoAR?.tracciamento = t }
    }

    private func pianoTrovato() {
        guard trovatoA == nil else { return }
        trovatoA = t
        let calmo = controllo?.calmo ?? false
        guard let s = statoAR else { return }
        withAnimation(Tema.Apple.Moto.animazione(.easeOut(duration: M.guidaUscita), calmo: calmo)) { s.trovato = true }
    }

    // MARK: Ogni fotogramma

    private func fotogramma(_ dt: Double) {
        guard let v = vista, let c = controllo, let cr = cristallo else { return }
        t += dt
        if ancora == nil, trovatoA != nil {
            let centro = CGPoint(x: v.bounds.midX, y: v.bounds.midY)
            if let r = v.raycast(from: centro, allowing: .estimatedPlane, alignment: .horizontal).first { posa(r.worldTransform, in: v, cr) }
        }
        if let inizio = trovatoA {
            let entrata = min(1, max(0, (t - inizio) / M.puntiniEntrata))
            let durata = M.puntiniFine - M.puntiniInizio
            let uscita = min(1, max(0, (t - inizio - durata) / M.puntiniUscita))
            cr.puntiniVisibili(c.calmo ? 0 : Float(entrata * (1 - uscita)))
        }
        guard let posato = posatoA else { return }
        let dopo = t - posato
        let crescita = c.calmo ? 1 : MotoreRealtaAumentata.crescita(dopo)
        esploso = c.calmo ? (c.esploso ? 1 : 0)
            : MotoreRealtaAumentata.insegui(esploso, verso: c.esploso ? 1 : 0, velocita: M.inseguimentoForma, dt: dt)
        try? cr.aggiorna(anno: c.anno, esploso: esploso, crescita: max(0.001, crescita), scelto: c.scelto)
        cr.anelloPosa(c.calmo ? 1 : Float(dopo / M.anelloPosa))
        etichette(cr, c.etichette, v)
    }

    private func posa(_ trasformazione: simd_float4x4, in v: ARView, _ cr: CristalloRealta) {
        let a = AnchorEntity(world: trasformazione)
        a.addChild(cr.radice)
        v.scene.addAnchor(a)
        ancora = a
        posatoA = t
        if !gestiInstallati {
            // Due dita ruotano il cristallo (niente ridimensionamento)
            _ = v.installGestures([.rotation], for: cr.radice)
            gestiInstallati = true
        }
    }

    /// Un tocco su uno strato lo evidenzia (di nuovo: lo spegne); un tocco sul piano sposta il cristallo.
    @objc private func tocco(_ g: UITapGestureRecognizer) {
        guard let v = vista, let cr = cristallo, let c = controllo else { return }
        let p = g.location(in: v)
        if let id = cr.strato(di: v.entity(at: p)) {
            let nuovo: String? = c.scelto == id ? nil : id
            c.scelto = nuovo
            c.sceltoCambiato?(nuovo)
            return
        }
        guard let r = v.raycast(from: p, allowing: .estimatedPlane, alignment: .horizontal).first else { return }
        if let a = ancora {
            a.setTransformMatrix(r.worldTransform, relativeTo: nil)
        } else {
            posa(r.worldTransform, in: v, cr)
        }
    }

    private func etichette(_ cr: CristalloRealta, _ et: EtichetteRealta, _ v: ARView) {
        let targhetta = v.project(cr.puntoTarghetta())
        if let a = targhetta, let b = et.targhetta, abs(a.x - b.x) < 0.5, abs(a.y - b.y) < 0.5 {} else { et.targhetta = targhetta }
        var punti: [String: CGPoint] = [:]
        for (id, p) in cr.puntiStrati() { if let q = v.project(p) { punti[id] = q } }
        let cambiati = punti.contains { id, q in
            guard let vecchio = et.strati[id] else { return true }
            return abs(vecchio.x - q.x) >= 0.5 || abs(vecchio.y - q.y) >= 0.5
        }
        if cambiati || punti.count != et.strati.count { et.strati = punti }
    }
}
#endif

// MARK: - Il tavolo lato Mac non c'è su iOS

extension View {
    /// Gemello vuoto del modificatore del Mac (Tavolo/TavoloMac.swift): su iPhone e iPad il tavolo lato Mac non c'è.
    func dalTavolo(_ azione: @escaping (ContenutoTavolo) -> Void) -> some View { self }
}
#endif
