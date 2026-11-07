import CryptoKit
import Foundation

/// La memoria di Vera dentro l'app: legge e scrive il file cifrato (MemoriaVera), tiene la chiave del Portachiavi,
/// aggiorna le lezioni attive e porta la chiave nel backup cifrata con la password dei backup. Senza persistenza (prove,
/// istantanee) resta solo in memoria e non tocca mai il Portachiavi.
final class StatoMemoriaVera: ObservableObject {
    @Published private(set) var contenuto = ContenutoMemoriaVera()
    /// La pagina dei ricordi è aperta.
    @Published var aperta = false
    /// Il file c'è ma la chiave no (ripristino su un altro Mac senza la password dei backup): la pagina lo dice.
    @Published private(set) var bloccata = false

    let persistente: Bool
    /// Impostazioni › Vera › «Impara dalle correzioni»: spento, le lezioni restano ma non si usano.
    var lezioniAccese = true { didSet { pubblicaLezioni() } }
    private var chiave: SymmetricKey?
    /// La chiave si chiede anche dalla ricerca, fuori dal thread principale: una sola chiave, mai due.
    private let bloccoChiave = NSLock()
    private var caricata = false
    private static let coda = DispatchQueue(label: "prisma.memoria-vera", qos: .utility)

    /// Aspetta le scritture in coda (prima di sostituire la cartella dei dati con un ripristino).
    static func attendiScritture() { coda.sync {} }

    init(persistente: Bool, chiave: SymmetricKey? = nil) {
        self.persistente = persistente
        self.chiave = chiave
    }

    /// La chiave della memoria (per la cache dei vettori): la crea alla prima volta.
    func chiaveMemoria() -> SymmetricKey? {
        bloccoChiave.lock(); defer { bloccoChiave.unlock() }
        if let chiave { return chiave }
        guard persistente else { return nil }
        if let d = PortachiaviMemoria.leggi(), d.count == 32 {
            chiave = SymmetricKey(data: d)
        } else if !FileManager.default.fileExists(atPath: MemoriaVera.file.path), let nuova = MemoriaVera.nuovaChiave() {
            if PortachiaviMemoria.salva(nuova.withUnsafeBytes { Data($0) }) { chiave = nuova }
        } else if let password = PortachiaviBackup.leggi(), let k = try? MemoriaVera.svolgi(MemoriaVera.fileChiave, password: password) {
            // Dopo un ripristino su un altro Mac: la chiave torna dal backup con la password dei backup
            if PortachiaviMemoria.salva(k.withUnsafeBytes { Data($0) }) { chiave = k }
        }
        return chiave
    }

    /// Legge la memoria (una volta). Sul thread principale.
    func carica() {
        guard !caricata else { return }
        caricata = true
        defer { pubblicaLezioni() }
        guard persistente else { return }
        let fm = FileManager.default
        guard fm.fileExists(atPath: MemoriaVera.file.path) else { return }
        guard let k = chiaveMemoria(), let d = try? Data(contentsOf: MemoriaVera.file) else {
            bloccata = true
            return
        }
        if let c = try? MemoriaVera.leggi(d, chiave: k) {
            contenuto = c
            bloccata = false
        } else {
            bloccata = true
        }
    }

    /// Apre la memoria con la password dei backup (la pagina dei ricordi, quando è bloccata).
    @discardableResult
    func sblocca(password: String) -> Bool {
        guard persistente, let k = try? MemoriaVera.svolgi(MemoriaVera.fileChiave, password: password),
              let d = try? Data(contentsOf: MemoriaVera.file), let c = try? MemoriaVera.leggi(d, chiave: k) else { return false }
        PortachiaviMemoria.salva(k.withUnsafeBytes { Data($0) })
        chiave = k
        contenuto = c
        bloccata = false
        pubblicaLezioni()
        return true
    }

    /// Cambia la memoria e la salva; false se non si può salvare (memoria bloccata, nessuna chiave): niente finto «Ricordato».
    @discardableResult
    private func cambia(_ f: (inout ContenutoMemoriaVera) -> Void) -> Bool {
        carica()
        guard !bloccata else { return false }
        if persistente && chiaveMemoria() == nil { return false }
        var c = contenuto
        f(&c)
        c.ricordi = Array(c.ricordi.suffix(MemoriaVera.massimoRicordi))
        c.lezioni = Array(c.lezioni.suffix(MemoriaVera.massimoLezioni))
        c.esempi = Array(c.esempi.suffix(MemoriaVera.massimoEsempi))
        contenuto = c
        pubblicaLezioni()
        salva()
        return true
    }

    private func salva() {
        guard persistente, let k = chiaveMemoria(), let d = try? MemoriaVera.scrivi(contenuto, chiave: k) else { return }
        let fileChiave = MemoriaVera.fileChiave
        let password = PortachiaviBackup.leggi()
        Self.coda.async {
            try? FileManager.default.createDirectory(at: Archivio.cartellaVera, withIntermediateDirectories: true)
            try? d.write(to: MemoriaVera.file, options: Archivio.opzioniScrittura)
            // La chiave nel backup, solo cifrata con la password dei backup (una volta)
            if let password, !FileManager.default.fileExists(atPath: fileChiave.path) {
                try? MemoriaVera.avvolgi(k, password: password, in: fileChiave)
            }
        }
    }

    private func pubblicaLezioni() {
        LezioniVera.attive = lezioniAccese ? contenuto.lezioni.filter(\.attiva).map(\.testo) : []
    }

    /// Dopo un ripristino: dimentica quello che c'è in memoria e rilegge il file ripristinato (con la chiave del Portachiavi;
    /// se è di un altro Mac la memoria resta bloccata finché non la apri con la password dei backup).
    func ricarica() {
        Self.coda.sync {}
        bloccoChiave.lock(); chiave = nil; bloccoChiave.unlock()
        caricata = false
        contenuto = ContenutoMemoriaVera()
        bloccata = false
        carica()
    }

    /// Riscrive la chiave nel backup con la password dei backup di adesso (o la toglie se la protezione è spenta).
    func riavvolgiChiave(password: String?) {
        guard persistente, FileManager.default.fileExists(atPath: MemoriaVera.file.path), !bloccata, let k = chiaveMemoria() else { return }
        let fileChiave = MemoriaVera.fileChiave
        Self.coda.async {
            if let password { try? MemoriaVera.avvolgi(k, password: password, in: fileChiave) } else { try? FileManager.default.removeItem(at: fileChiave) }
        }
    }

    /// Ricomincia da capo: la memoria che non si apre più (senza chiave né password) si cancella.
    func ricomincia() {
        guard persistente else { contenuto = ContenutoMemoriaVera(); return }
        try? FileManager.default.removeItem(at: MemoriaVera.file)
        try? FileManager.default.removeItem(at: MemoriaVera.fileChiave)
        PortachiaviMemoria.elimina()
        bloccoChiave.lock(); chiave = nil; bloccoChiave.unlock()
        contenuto = ContenutoMemoriaVera()
        bloccata = false
        pubblicaLezioni()
    }

    // MARK: - Ricordi

    var ricordi: [RicordoVera] { carica(); return contenuto.ricordi }

    /// Aggiunge un ricordo; nil se il testo è vietato o vuoto (il motivo in `vietato`).
    @discardableResult
    func ricorda(_ testo: String, cliente: String?, fonte: String) -> RicordoVera? {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, MemoriaVera.vietato(t) == nil else { return nil }
        if let gia = ricordi.first(where: { $0.testo.caseInsensitiveCompare(t) == .orderedSame && $0.clienteId == cliente }) { return gia }
        let r = RicordoVera(testo: t, clienteId: cliente, fonte: fonte)
        guard cambia({ $0.ricordi.append(r) }) else { return nil }
        return r
    }

    func modificaRicordo(_ id: String, testo: String) {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, MemoriaVera.vietato(t) == nil else { return }
        cambia { c in if let i = c.ricordi.firstIndex(where: { $0.id == id }) { c.ricordi[i].testo = t } }
    }

    func dimentica(_ id: String) {
        cambia { $0.ricordi.removeAll { $0.id == id } }
    }

    // MARK: - Lezioni ed esempi

    var lezioni: [LezioneVera] { carica(); return contenuto.lezioni }

    @discardableResult
    func impara(_ testo: String) -> LezioneVera? {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 4, MemoriaVera.vietato(t) == nil else { return nil }
        let l = LezioneVera(testo: t)
        guard cambia({ $0.lezioni.append(l) }) else { return nil }
        return l
    }

    func alternaLezione(_ id: String) {
        cambia { c in if let i = c.lezioni.firstIndex(where: { $0.id == id }) { c.lezioni[i].attiva.toggle() } }
    }

    func eliminaLezione(_ id: String) {
        cambia { $0.lezioni.removeAll { $0.id == id } }
    }

    func approva(domanda: String, risposta: String) {
        guard MemoriaVera.vietato(domanda + " " + risposta) == nil else { return }
        cambia { $0.esempi.append(EsempioVera(domanda: domanda, risposta: risposta)) }
    }

    // MARK: - Il filo lungo

    func filo(_ chiave: String) -> FiloVera? { carica(); return contenuto.fili[chiave] }

    func aggiornaFilo(_ chiave: String, _ f: FiloVera?) {
        // Mai numeri di documenti, conti o password nella memoria, nemmeno dentro un riassunto
        if let f, MemoriaVera.vietato(f.riassunto) != nil { return }
        cambia { $0.fili[chiave] = f }
    }
}
