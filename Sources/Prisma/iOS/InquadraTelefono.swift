#if os(iOS)
import ImageIO
import SwiftUI
import UIKit
import Vision
import VisionKit

// Inquadra e capisci sull'iPhone (Design/template-novita-specifica.md §9, strada B): Posizioni › «Inquadra» apre la
// fotocamera dal vivo.
// - Fotocamera: `DataScannerViewController` (VisionKit) evidenzia dal vivo il testo che riconosce; lo scatto legge la
//   foto con Vision (`LetturaDocumenti.riconosciConRiquadri`, sul telefono). Dove lo scanner dal vivo non c'è
//   (`isSupported`/`isAvailable` falsi), il ripiego è la scansione documenti di sistema (`VNDocumentCameraViewController`).
// - Poi in alto il foglio con i campi che si illuminano uno alla volta (la cascata del tema, StatoInquadra), sotto i
//   dati riconosciuti e «Manda al Mac»: solo il testo letto, riga per riga con il riquadro, va al Mac sul ponte
//   cifrato (`PonteRuby.manda`). L'immagine non lascia il telefono e non si salva: se ne va alla chiusura.
// - L'iPhone non scrive nell'archivio (è una copia): la posizione la crea il Mac, dopo la conferma del consulente.
// Nelle istantanee la fotocamera non c'è: il foglio è quello disegnato di prova (FoglioInquadraDiProva).

// MARK: - Presentazione da Posizioni

extension View {
    /// La schermata della fotocamera sopra tutto, quando `stato.inquadra.telefonoAperto`.
    func inquadraTelefono(_ stato: StatoShell) -> some View {
        modifier(PresentaInquadraTelefono(inquadra: stato.inquadra))
    }
}

private struct PresentaInquadraTelefono: ViewModifier {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var inquadra: StatoInquadra
    @Environment(\.istantaneaSchermo) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: Binding(get: { inquadra.telefonoAperto },
                                                     set: { if !$0 { inquadra.chiudiTelefono() } })) {
            InquadraTelefono(inquadra: inquadra)
                .environmentObject(stato)
                .environment(\.istantaneaSchermo, istantanea)
                .prismaCalmo(calmo)
        }
    }
}

/// Il pulsante «Inquadra» nella barra di Posizioni.
struct PulsanteInquadraTelefono: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        Button { stato.inquadra.apriTelefono() } label: {
            Label("Inquadra", systemImage: "viewfinder")
        }
        .accessibilityHint(Text("Leggi una polizza con la fotocamera e mandala al Mac"))
    }
}

// MARK: - La schermata

struct InquadraTelefono: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var inquadra: StatoInquadra
    @Environment(\.istantaneaSchermo) private var istantanea
    @StateObject private var scanner = ControlloreScannerInquadra()
    @State private var scansioneDocumenti = false

    private typealias M = Tema.Apple.Inquadra.Mobile

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                M.fondoCamera.ignoresSafeArea()
                if conFoglio {
                    VStack(spacing: M.spazio) {
                        foglio
                            .frame(maxWidth: .infinity, maxHeight: geo.size.height * M.quotaFoglio)
                            .padding(.horizontal, M.margine)
                            .padding(.top, M.foglioDallAlto)
                        if inquadra.dati != nil { scritta }
                        ScrollView {
                            pannello
                                .padding(.horizontal, M.margine)
                                .padding(.bottom, M.margine)
                        }
                    }
                } else {
                    camera
                        .ignoresSafeArea()
                    VStack {
                        Spacer(minLength: 0)
                        pannello
                            .padding(.horizontal, M.margine)
                            .padding(.bottom, M.margine)
                    }
                }
                chiudi
                    .padding(M.margine)
            }
        }
        .sheet(isPresented: $scansioneDocumenti) {
            CameraDocumentiInquadra { foto in
                scansioneDocumenti = false
                if let foto { stato.leggiFotoInquadra(foto) }
            }
            .ignoresSafeArea()
        }
    }

    /// Il foglio c'è (lettura finita o in corso sui dati), oppure la foto è illeggibile.
    private var conFoglio: Bool {
        inquadra.dati != nil || inquadra.fase == .illeggibile || inquadra.fase == .lettura
    }

    private var chiudi: some View {
        Button { inquadra.chiudiTelefono() } label: {
            Image(systemName: "xmark")
        }
        .buttonStyle(.appleVetro)
        .accessibilityLabel(Text("Chiudi"))
    }

    // MARK: La fotocamera

    @ViewBuilder private var camera: some View {
        if istantanea {
            M.fondoCamera
        } else if ControlloreScannerInquadra.dalVivo {
            ScannerInquadra(controllore: scanner)
                .overlay { GuidaDocumento().allowsHitTesting(false) }
        } else {
            ZStack {
                M.fondoCamera
                GuidaDocumento()
            }
        }
    }

    // MARK: Il foglio letto

    @ViewBuilder private var foglio: some View {
        if let d = inquadra.dati, !d.campi.isEmpty {
            if let img = inquadra.immagine {
                FoglioInquadra(righe: inquadra.righe, campi: d.campi, accesi: inquadra.campiAccesi, immagine: img)
            } else {
                FoglioInquadra(righe: inquadra.righe, campi: d.campi, accesi: inquadra.campiAccesi)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        } else {
            VStack(spacing: M.spazio) {
                if inquadra.fase == .lettura { ProgressView().tint(M.coloreScritta) }
                scritta
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// La scritta sull'inquadratura: «Inquadra il documento», «Riconosco i dati…», «✓ Fatto».
    private var scritta: some View {
        Text(testoScritta)
            .carattereApple(M.scritta)
            .foregroundColor(M.coloreScritta)
            .padding(M.paddingScritta)
            .background(Capsule(style: .continuous).fill(M.fondoScritta))
    }

    private var testoScritta: String {
        switch inquadra.fase {
        case .lettura: return "Riconosco i dati…"
        case .illeggibile: return "Riprova con più luce"
        case .letto: return inquadra.finito ? "✓ Fatto" : "Riconosco i dati…"
        case .attesa, .trascina: return scanner.righeViste > 0 ? "Tocca il pulsante per leggere" : "Inquadra il documento"
        }
    }

    // MARK: Il pannello in basso

    private var pannello: some View {
        VStack(alignment: .leading, spacing: M.spazio) {
            switch inquadra.fase {
            case .attesa, .trascina:
                pannelloCamera
            case .lettura:
                Text("Sto leggendo…")
                    .carattereApple(M.titolo)
                    .foregroundColor(M.coloreTitolo)
            case .illeggibile:
                Text("Non riesco a leggere il documento")
                    .carattereApple(M.titolo)
                    .foregroundColor(M.coloreTitolo)
                Text("Riprova con più luce, con il foglio intero e dritto nell’inquadratura.")
                    .carattereApple(M.frase)
                    .foregroundColor(M.coloreFrase)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Riprova") { inquadra.apriTelefono() }
                    .buttonStyle(.applePrimarioGrande)
            case .letto:
                pannelloLetto
            }
        }
        .padding(M.paddingPannello)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(M.superficiePannello, raggio: M.raggioPannello)
    }

    @ViewBuilder private var pannelloCamera: some View {
        HStack {
            scritta
            Spacer(minLength: 0)
        }
        if istantanea || ControlloreScannerInquadra.dalVivo {
            Text("Tieni il foglio intero nel riquadro: il testo riconosciuto si illumina. Poi leggi: solo il testo va al Mac, cifrato.")
                .carattereApple(M.frase)
                .foregroundColor(M.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer(minLength: 0)
                Button { scatta() } label: {
                    ZStack {
                        Circle().strokeBorder(M.coloreScatto, lineWidth: M.anelloScatto)
                            .frame(width: M.scatto, height: M.scatto)
                        Circle().fill(M.coloreScatto)
                            .frame(width: M.interScatto, height: M.interScatto)
                    }
                }
                .buttonStyle(StileSemplice())
                .accessibilityLabel(Text("Leggi il documento"))
                Spacer(minLength: 0)
            }
        } else if ControlloreScannerInquadra.scansioneDisponibile {
            Text("Su questo iPhone la lettura dal vivo non c’è: scansiona il documento, poi Prisma lo legge sul telefono.")
                .carattereApple(M.frase)
                .foregroundColor(M.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
            Button("Scansiona il documento") { scansioneDocumenti = true }
                .buttonStyle(.applePrimarioGrande)
        } else {
            Text("La fotocamera non è disponibile: consenti a Prisma di usarla in Impostazioni › Prisma › Fotocamera.")
                .carattereApple(M.frase)
                .foregroundColor(M.coloreFrase)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var pannelloLetto: some View {
        let canale = stato.canaleEAreaInquadra.canale
        let righe = inquadra.righeScheda(canale: canale)
        Text(titoloLetto)
            .carattereApple(M.titolo)
            .foregroundColor(M.coloreTitolo)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(righe.prefix(inquadra.mostrate).enumerated()), id: \.element.id) { _, r in
                RigaSchedaInquadra(riga: r)
                    .entrataStile(.rigaInquadra)
            }
        }
        if inquadra.finito {
            HStack(spacing: M.spazio) {
                Menu {
                    ForEach(stato.clienti) { x in
                        Button(x.nome) { inquadra.clienteScelto = x.id }
                    }
                } label: {
                    Label(stato.clienteInquadra?.nome ?? "Scegli il cliente", systemImage: "person.crop.circle")
                }
                Spacer(minLength: 0)
                EtichettaCanaleApple(canale: canale, compatta: true)
            }
            if let r = inquadra.ricevuta {
                Text(r.accettato ? "Mandato al Mac: controllalo lì e aggiungilo a Posizioni." : (r.motivo ?? PonteRuby.macNonTrovato))
                    .carattereApple(M.frase)
                    .foregroundColor(M.coloreFrase)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: M.spazio) {
                if inquadra.ricevuta?.accettato == true {
                    Button("Fatto") { inquadra.chiudiTelefono() }
                        .buttonStyle(.applePrimarioGrande)
                } else {
                    Button { stato.mandaInquadraturaAlMac() } label: {
                        Label(inquadra.inInvio ? "Mando…" : "Manda al Mac", systemImage: "desktopcomputer")
                    }
                    .buttonStyle(.applePrimarioGrande)
                    .disabled(inquadra.inInvio)
                    Button("Rifai") { inquadra.apriTelefono() }
                        .buttonStyle(.appleGrande)
                        .disabled(inquadra.inInvio)
                }
            }
        }
    }

    private var titoloLetto: String {
        guard inquadra.finito, let d = inquadra.dati else { return "Sto leggendo…" }
        return inquadra.pochiDati ? "Ho letto solo una parte" : MotoreInquadra.titoloRiconosciuto(d.tipoDocumento)
    }

    private func scatta() {
        guard !istantanea else { return }
        Task { @MainActor in
            guard let foto = await scanner.scatta() else { return }
            stato.leggiFotoInquadra(foto)
        }
    }
}

/// La guida del documento sull'inquadratura: quattro angoli bianchi con il rapporto di un A4 verticale.
private struct GuidaDocumento: View {
    private typealias M = Tema.Apple.Inquadra.Mobile

    var body: some View {
        GeometryReader { g in
            let larghezza = max(0, g.size.width - 2 * M.margineGuida)
            let altezza = min(larghezza / M.rapportoGuida, max(0, g.size.height * M.quotaGuida))
            let r = CGRect(x: (g.size.width - larghezza) / 2, y: (g.size.height - altezza) / 2 - M.margineGuida,
                           width: larghezza, height: altezza)
            Path { p in
                let a = M.angolo
                p.move(to: CGPoint(x: r.minX, y: r.minY + a)); p.addLine(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.minX + a, y: r.minY))
                p.move(to: CGPoint(x: r.maxX - a, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY + a))
                p.move(to: CGPoint(x: r.maxX, y: r.maxY - a)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.maxX - a, y: r.maxY))
                p.move(to: CGPoint(x: r.minX + a, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY - a))
            }
            .stroke(M.coloreGuida, style: StrokeStyle(lineWidth: M.spessoreAngolo, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Lo scanner dal vivo (VisionKit)

/// Lo scanner del testo di VisionKit: evidenzia dal vivo il testo che riconosce e scatta la foto da leggere.
@MainActor
final class ControlloreScannerInquadra: NSObject, ObservableObject, DataScannerViewControllerDelegate {
    @Published var righeViste = 0
    weak var scanner: DataScannerViewController?

    /// Lo scanner dal vivo c'è (dispositivo con il Neural Engine) e si può usare (fotocamera consentita).
    static var dalVivo: Bool { DataScannerViewController.isSupported && DataScannerViewController.isAvailable }
    /// Il ripiego: la scansione documenti di sistema.
    static var scansioneDisponibile: Bool { VNDocumentCameraViewController.isSupported }

    func avvia() {
        guard let s = scanner, !s.isScanning else { return }
        try? s.startScanning()
    }

    func scatta() async -> UIImage? {
        guard let s = scanner else { return nil }
        return try? await s.capturePhoto()
    }

    func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        righeViste = allItems.count
    }

    func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        righeViste = allItems.count
    }
}

private struct ScannerInquadra: UIViewControllerRepresentable {
    let controllore: ControlloreScannerInquadra

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let v = DataScannerViewController(recognizedDataTypes: [.text(languages: ["it-IT", "en-US"])],
                                          qualityLevel: .accurate,
                                          recognizesMultipleItems: true,
                                          isHighFrameRateTrackingEnabled: false,
                                          isPinchToZoomEnabled: true,
                                          isGuidanceEnabled: true,
                                          isHighlightingEnabled: true)
        v.delegate = controllore
        controllore.scanner = v
        return v
    }

    func updateUIViewController(_ v: DataScannerViewController, context: Context) {
        controllore.avvia()
    }

    static func dismantleUIViewController(_ v: DataScannerViewController, coordinator: ()) {
        v.stopScanning()
    }
}

// MARK: - Il ripiego: la scansione documenti di sistema

private struct CameraDocumentiInquadra: UIViewControllerRepresentable {
    let fatto: (UIImage?) -> Void

    func makeCoordinator() -> Coordinatore { Coordinatore(fatto: fatto) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let v = VNDocumentCameraViewController()
        v.delegate = context.coordinator
        return v
    }

    func updateUIViewController(_ v: VNDocumentCameraViewController, context: Context) {}

    final class Coordinatore: NSObject, VNDocumentCameraViewControllerDelegate {
        let fatto: (UIImage?) -> Void

        init(fatto: @escaping (UIImage?) -> Void) {
            self.fatto = fatto
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            fatto(scan.pageCount > 0 ? scan.imageOfPage(at: 0) : nil)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            fatto(nil)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            fatto(nil)
        }
    }
}

// MARK: - Lettura della foto e invio al Mac

extension StatoShell {
    /// La foto scattata: ridotta (lato 2.000, orientamento diritto) e letta con Vision sul telefono, in coda.
    /// La foto resta solo in memoria.
    func leggiFotoInquadra(_ foto: UIImage) {
        let giro = inquadra.inizioLettura(origine: "")
        let lato = CGFloat(Self.latoImmagineInquadra)
        Self.codaInquadra.async { [weak self] in
            let letto = autoreleasepool { () -> (immagine: UIImage, righe: [RigaLetta]?) in
                let ridotta = Self.ridottaInquadra(foto, lato: lato)
                return (immagine: ridotta, righe: LetturaDocumenti.riconosciConRiquadri(ridotta))
            }
            DispatchQueue.main.async {
                guard let self, self.inquadra.telefonoAperto else { return }
                guard let righe = letto.righe, !righe.isEmpty else {
                    self.inquadra.illeggibile(origine: "", giroAtteso: giro)
                    return
                }
                self.inquadra.mostra(righe: righe, immagine: letto.immagine, origine: "", giroAtteso: giro)
            }
        }
    }

    /// La foto ridisegnata diritta, con il lato lungo al più `lato` pixel (scala 1).
    static func ridottaInquadra(_ img: UIImage, lato: CGFloat) -> UIImage {
        let s = img.size
        let k = min(1, lato / max(1, max(s.width, s.height)))
        let misura = CGSize(width: (s.width * k).rounded(), height: (s.height * k).rounded())
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: misura, format: formato).image { _ in
            img.draw(in: CGRect(origin: .zero, size: misura))
        }
    }

    /// «Manda al Mac»: il testo letto (righe con il riquadro e i campi trovati), mai l'immagine, sul ponte cifrato.
    @MainActor
    func mandaInquadraturaAlMac() {
        guard let d = inquadra.dati, !inquadra.righe.isEmpty, !inquadra.inInvio else { return }
        let righe = inquadra.righe.prefix(PonteRuby.massimoRighe).map {
            RigaLetta(testo: String($0.testo.prefix(PonteRuby.massimoTestoRiga)), riquadro: $0.riquadro)
        }
        let x = InquadraturaPonte(clienteId: clienteInquadra?.id, dispositivo: UIDevice.current.name, righe: Array(righe),
                                  campi: Array(d.campi.prefix(PonteRuby.massimoCampi)))
        let ruby = dati.impostazioni.ruby
        inquadra.inInvio = true
        inquadra.ricevuta = nil
        Task { @MainActor [weak self] in
            let r = await PonteRuby.manda(.inquadratura(x), ruby: ruby)
            guard let self else { return }
            self.inquadra.inInvio = false
            self.inquadra.ricevuta = r
        }
    }
}
#endif
