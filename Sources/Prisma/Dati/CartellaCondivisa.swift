import Foundation
#if os(macOS)
import AppKit
import CoreServices
#elseif os(iOS)
import SwiftUI
import UniformTypeIdentifiers
#endif

// Prisma ovunque (Design/ovunque-fattibilita.md §1-2, giro 8): la cartella di iCloud Drive scelta dall'utente.
// Prisma non parla con iCloud: legge e scrive file in una cartella, come fa con i backup. Niente contenitore iCloud
// dell'app, niente CloudKit, niente server. In produzione è `CartellaCondivisaFile`; la prova usa una cartella locale
// che finge iCloud (ritardi, file non scaricati, copie «nome 2», file troncati).

/// Un file della cartella condivisa.
struct VoceCartella: Equatable {
    var nome: String
    var dimensione: Int64
    var modificatoIl: Date?
    /// false = in iCloud ma non (o non nella versione più recente) su questo dispositivo.
    var scaricato: Bool

    /// Dimensione, data e stato: il controllo all'attivazione confronta queste impronte.
    var impronta: String {
        "\(dimensione)·\(Int64((modificatoIl?.timeIntervalSince1970 ?? 0) * 1000))·\(scaricato ? 1 : 0)"
    }
}

/// Ciò che lo spazio chiede alla cartella: elencare, leggere e sostituire con coordinazione, eliminare.
protocol CartellaCondivisa: AnyObject {
    /// I file della cartella (non le sottocartelle né i file nascosti), con i segnaposto di iCloud riconosciuti.
    func elenca() throws -> [VoceCartella]
    /// Il contenuto di un file. Un file non ancora scaricato → `ErroreOvunque.inAttesaDiICloud` (e lo scaricamento parte).
    func leggi(_ nome: String) throws -> Data
    /// Sostituisce (o crea) un file tutto in una volta: chi legge vede il file vecchio intero o quello nuovo intero.
    func sostituisci(_ nome: String, con dati: Data) throws
    func elimina(_ nome: String) throws
}

extension CartellaCondivisa {
    /// Le impronte dei file per il controllo all'attivazione (nome → dimensione·data·stato).
    func impronte() throws -> [String: String] {
        let voci = try elenca()
        return Dictionary(voci.map { ($0.nome, $0.impronta) }, uniquingKeysWith: { a, _ in a })
    }
}

/// La cartella vera (iCloud Drive o qualunque cartella scelta), con `NSFileCoordinator`.
/// - Mac: Prisma non è in sandbox, l'URL si usa direttamente (segnalibro normale per seguire spostamenti e nuovi nomi).
/// - iOS: l'URL del selettore ha un security scope, aperto per la vita dell'oggetto (`ambitoProtetto`) e chiuso alla fine.
final class CartellaCondivisaFile: CartellaCondivisa {
    let url: URL
    private let ambitoAperto: Bool

    init(url: URL, ambitoProtetto: Bool = false) {
        self.url = url
        // Un `false` è tollerato (cartella senza security scope): si prova lo stesso
        ambitoAperto = ambitoProtetto ? url.startAccessingSecurityScopedResource() : false
    }

    deinit {
        if ambitoAperto { url.stopAccessingSecurityScopedResource() }
    }

    var raggiungibile: Bool {
        var cartella: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &cartella) && cartella.boolValue
    }

    func elenca() throws -> [VoceCartella] {
        guard raggiungibile else { throw ErroreOvunque.cartellaNonRaggiungibile }
        let chiavi: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .ubiquitousItemDownloadingStatusKey, .isDirectoryKey]
        let file: [URL]
        do {
            file = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: chiavi, options: [])
        } catch {
            // TCC (privacy di macOS) o permesso revocato: si propone di scegliere di nuovo la cartella
            throw ErroreOvunque.accessoNegato(error.localizedDescription)
        }
        var voci: [String: VoceCartella] = [:]
        var segnaposto: [String] = []
        for f in file {
            let nome = f.lastPathComponent
            if nome.hasPrefix("."), nome.hasSuffix(Self.suffissoSegnaposto) {
                // Fino a macOS 13 (e su iOS di prima) un file non scaricato è «.<nome>.icloud»
                let vero = String(nome.dropFirst().dropLast(Self.suffissoSegnaposto.count))
                if !vero.isEmpty { segnaposto.append(vero) }
                continue
            }
            if nome.hasPrefix(".") { continue }
            let valori = try? f.resourceValues(forKeys: Set(chiavi))
            if valori?.isDirectory == true { continue }
            // Da macOS 14 un file non scaricato ha il suo nome vero ed è «dataless»: lo dice lo stato di iCloud
            let stato = valori?.ubiquitousItemDownloadingStatus
            voci[nome] = VoceCartella(nome: nome, dimensione: Int64(valori?.fileSize ?? 0), modificatoIl: valori?.contentModificationDate,
                                      scaricato: stato == nil || stato == .current)
        }
        for vero in segnaposto where voci[vero] == nil {
            voci[vero] = VoceCartella(nome: vero, dimensione: 0, modificatoIl: nil, scaricato: false)
        }
        return voci.values.sorted { $0.nome < $1.nome }
    }

    func leggi(_ nome: String) throws -> Data {
        let fm = FileManager.default
        let file = url.appendingPathComponent(nome)
        let segnaposto = url.appendingPathComponent("." + nome + Self.suffissoSegnaposto)
        let stato = (try? file.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]))?.ubiquitousItemDownloadingStatus
        let esiste = fm.fileExists(atPath: file.path)
        if (!esiste && fm.fileExists(atPath: segnaposto.path)) || (esiste && stato != nil && stato != .current) {
            // Lo scaricamento parte; FSEvents (Mac) o il controllo successivo (iOS) riprovano quando arriva
            try? fm.startDownloadingUbiquitousItem(at: file)
            throw ErroreOvunque.inAttesaDiICloud(nome)
        }
        guard esiste else { throw ErroreOvunque.fileMancante(nome) }
        var erroreCoordinazione: NSError?
        var letto: Result<Data, Error>?
        NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: file, options: [.withoutChanges], error: &erroreCoordinazione) { u in
            letto = Result { try Data(contentsOf: u) }
        }
        if let erroreCoordinazione { throw ErroreOvunque.accessoNegato(erroreCoordinazione.localizedDescription) }
        guard let letto else { throw ErroreOvunque.fileMancante(nome) }
        do {
            return try letto.get()
        } catch {
            throw ErroreOvunque.accessoNegato(error.localizedDescription)
        }
    }

    func sostituisci(_ nome: String, con dati: Data) throws {
        guard raggiungibile else { throw ErroreOvunque.cartellaNonRaggiungibile }
        let fm = FileManager.default
        // Il file nuovo si prepara fuori dalla cartella di iCloud (dove anche i provvisori verrebbero caricati)
        let provvisorio = fm.temporaryDirectory.appendingPathComponent("Prisma-ovunque-\(UUID().uuidString).tmp")
        defer { try? fm.removeItem(at: provvisorio) }
        do {
            try dati.write(to: provvisorio, options: Archivio.opzioniScrittura)
        } catch {
            throw ErroreOvunque.scrittura(error.localizedDescription)
        }
        let destinazione = url.appendingPathComponent(nome)
        var erroreCoordinazione: NSError?
        var erroreScrittura: Error?
        // `.forReplacing`: il segnale che il demone di iCloud Drive e gli altri lettori coordinati si aspettano
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: destinazione, options: .forReplacing, error: &erroreCoordinazione) { u in
            do {
                if fm.fileExists(atPath: u.path) {
                    do {
                        _ = try fm.replaceItemAt(u, withItemAt: provvisorio)
                    } catch {
                        // Volumi diversi o sostituzione rifiutata: scrittura atomica sul posto
                        try dati.write(to: u, options: .atomic)
                    }
                } else {
                    do {
                        try fm.moveItem(at: provvisorio, to: u)
                    } catch {
                        try dati.write(to: u, options: .atomic)
                    }
                }
            } catch {
                erroreScrittura = error
            }
        }
        if let e = erroreCoordinazione ?? (erroreScrittura.map { $0 as NSError }) {
            throw ErroreOvunque.scrittura(e.localizedDescription)
        }
    }

    func elimina(_ nome: String) throws {
        let fm = FileManager.default
        let file = url.appendingPathComponent(nome)
        guard fm.fileExists(atPath: file.path) else { return }
        var erroreCoordinazione: NSError?
        var erroreEliminazione: Error?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: file, options: .forDeleting, error: &erroreCoordinazione) { u in
            do { try fm.removeItem(at: u) } catch { erroreEliminazione = error }
        }
        if let e = erroreCoordinazione ?? (erroreEliminazione.map { $0 as NSError }) {
            throw ErroreOvunque.scrittura(e.localizedDescription)
        }
    }

    static let suffissoSegnaposto = ".icloud"
}

/// Il segnalibro della cartella: segue la cartella se l'utente la rinomina o la sposta dentro iCloud Drive.
/// - Mac: segnalibro normale (Prisma non è in sandbox: `.withSecurityScope` non serve e la sua risoluzione può fallire).
/// - iOS: il segnalibro di un URL del selettore conserva il security scope; va creato con l'accesso aperto.
enum SegnalibroOvunque {
    static func crea(_ url: URL) throws -> Data {
        try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    /// L'URL del segnalibro e se va rigenerato (`scaduto`: si rigenera subito, con l'accesso aperto).
    static func risolvi(_ dati: Data) throws -> (url: URL, scaduto: Bool) {
        var scaduto = false
        let url = try URL(resolvingBookmarkData: dati, options: [], relativeTo: nil, bookmarkDataIsStale: &scaduto)
        return (url, scaduto)
    }
}

extension ImpostazioniOvunque {
    /// La cartella dello spazio: dal segnalibro (rigenerato se scaduto) o, sul Mac, dal percorso di ripiego.
    /// nil se non c'è o non si risolve (l'utente sceglie di nuovo la cartella).
    mutating func cartella() -> CartellaCondivisaFile? {
        let protetto = ruolo == .dispositivo
        if let s = segnalibro, let risolto = try? SegnalibroOvunque.risolvi(s) {
            let c = CartellaCondivisaFile(url: risolto.url, ambitoProtetto: protetto)
            if risolto.scaduto, let nuovo = try? SegnalibroOvunque.crea(risolto.url) { segnalibro = nuovo }
            percorso = risolto.url.path
            return c
        }
        #if os(macOS)
        if let p = percorso { return CartellaCondivisaFile(url: URL(fileURLWithPath: p, isDirectory: true)) }
        #endif
        return nil
    }

    /// Ricorda la cartella scelta (segnalibro e percorso). Su iOS l'accesso va aperto mentre si crea il segnalibro.
    mutating func ricorda(_ url: URL) throws {
        let aperto = ruolo == .dispositivo ? url.startAccessingSecurityScopedResource() : false
        defer { if aperto { url.stopAccessingSecurityScopedResource() } }
        segnalibro = try SegnalibroOvunque.crea(url)
        percorso = url.path
    }

    /// Perché una cartella non va bene per lo spazio (nil = va bene): non dentro l'archivio di Prisma, non la cartella
    /// dei backup (la rotazione dei backup non si mescola con i file della sincronizzazione).
    static func motivoRifiuto(_ url: URL, cartellaBackup: URL?) -> String? {
        let scelta = url.standardizedFileURL.resolvingSymlinksInPath().path
        let archivio = Archivio.cartella.standardizedFileURL.resolvingSymlinksInPath().path
        if scelta == archivio || scelta.hasPrefix(archivio + "/") {
            return "La cartella di Prisma ovunque non può stare dentro l'archivio di Prisma."
        }
        if let b = cartellaBackup?.standardizedFileURL.resolvingSymlinksInPath().path, scelta == b {
            return "Scegli una cartella diversa da quella dei backup."
        }
        return nil
    }
}

#if os(macOS)
/// Mac: la scelta della cartella (Impostazioni › iPhone e iPad) con `NSOpenPanel`.
enum SceltaCartellaOvunque {
    /// Proposta: iCloud Drive › Prisma ovunque (se iCloud Drive c'è), altrimenti la cartella Inizio.
    static var iCloudDrive: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs", isDirectory: true)
    }

    /// true se sul Mac c'è la cartella di iCloud Drive (non si può chiedere a iCloud senza diritti).
    static var iCloudDriveAcceso: Bool {
        var cartella: ObjCBool = false
        return FileManager.default.fileExists(atPath: iCloudDrive.path, isDirectory: &cartella) && cartella.boolValue
    }

    /// Mostra il pannello; nil se l'utente annulla. Dal thread principale.
    static func scegli() -> URL? {
        let pannello = NSOpenPanel()
        pannello.canChooseDirectories = true
        pannello.canChooseFiles = false
        pannello.canCreateDirectories = true
        pannello.allowsMultipleSelection = false
        pannello.prompt = "Usa questa cartella"
        pannello.message = "Scegli in iCloud Drive la cartella di Prisma ovunque: ci finisce solo un file cifrato con la tua passphrase."
        if iCloudDriveAcceso { pannello.directoryURL = iCloudDrive }
        return pannello.runModal() == .OK ? pannello.url : nil
    }
}

/// Mac: i cambiamenti della cartella (i giornali scritti da iPhone e iPad) con FSEvents, su una coda propria e fuori dal
/// thread principale. Sul Mac iCloud Drive è una vera cartella del disco: ogni file che iCloud scarica o sostituisce
/// produce un evento. In più lo spazio si controlla all'avvio, al risveglio e quando la finestra torna attiva.
final class OsservatoreCartellaOvunque {
    let cartella: URL
    /// Chiamata sulla coda dell'osservatore (non sul thread principale) dopo ogni gruppo di eventi.
    private let cambiata: () -> Void
    private let coda = DispatchQueue(label: "prisma.ovunque.osservatore", qos: .utility)
    private var flusso: FSEventStreamRef?
    /// Latenza di FSEvents: gli eventi vicini arrivano insieme.
    static let latenza: CFTimeInterval = 2

    init(cartella: URL, cambiata: @escaping () -> Void) {
        self.cartella = cartella
        self.cambiata = cambiata
    }

    deinit { ferma() }

    var attivo: Bool { flusso != nil }

    /// Avvia l'osservazione. false se FSEvents non l'accetta (la cartella si controlla comunque all'attivazione).
    @discardableResult
    func avvia() -> Bool {
        guard flusso == nil else { return true }
        var contesto = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
                                            retain: nil, release: nil, copyDescription: nil)
        let richiamo: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            Unmanaged<OsservatoreCartellaOvunque>.fromOpaque(info).takeUnretainedValue().cambiata()
        }
        let opzioni = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        guard let f = FSEventStreamCreate(kCFAllocatorDefault, richiamo, &contesto, [cartella.path] as CFArray,
                                          FSEventStreamEventId(kFSEventStreamEventIdSinceNow), Self.latenza, opzioni) else {
            return false
        }
        FSEventStreamSetDispatchQueue(f, coda)
        guard FSEventStreamStart(f) else {
            FSEventStreamInvalidate(f)
            FSEventStreamRelease(f)
            return false
        }
        flusso = f
        return true
    }

    func ferma() {
        guard let f = flusso else { return }
        FSEventStreamStop(f)
        FSEventStreamInvalidate(f)
        FSEventStreamRelease(f)
        flusso = nil
    }
}
#elseif os(iOS)
extension View {
    /// iPhone e iPad: il selettore di cartelle di File (anche iCloud Drive, senza diritti iCloud). L'URL scelto ha un
    /// security scope: si ricorda con `ImpostazioniOvunque.ricorda(_:)`, che ne crea il segnalibro.
    func sceltaCartellaOvunque(_ mostra: Binding<Bool>, scelta: @escaping (Result<URL, Error>) -> Void) -> some View {
        fileImporter(isPresented: mostra, allowedContentTypes: [.folder], onCompletion: scelta)
    }
}
#endif
