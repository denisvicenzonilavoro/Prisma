import CryptoKit
import Foundation

/// Perché un modello addestrato non è entrato in Ollama.
enum ErroreImporta: LocalizedError, Equatable {
    case nonGGUF
    case troppoGrande
    case nonLocale
    case nonTrovato
    case ollama(String)

    var errorDescription: String? {
        switch self {
        case .nonGGUF: return "Il file non è un modello GGUF: scegli lo zip scaricato dall'addestramento o il file .gguf."
        case .troppoGrande: return "Il file è più grande di 6 GB: non è il modello addestrato per Vera."
        case .nonLocale: return "Prisma parla solo con Ollama sul Mac (127.0.0.1): l'indirizzo non è locale."
        case .nonTrovato: return "Nello zip non c'è nessun file .gguf."
        case .ollama(let m): return "Ollama non ha accettato il modello: \(m)"
        }
    }
}

/// L'importazione del modello addestrato in Ollama, con le sole API locali (127.0.0.1): il file entra come blob
/// (/api/blobs), poi si crea il modello (/api/create) con il template e i parametri del modello di partenza (/api/show).
/// Il file non si carica mai tutto in memoria.
enum ImportaSuMisura {
    static let massimoByte: Int64 = 6_000_000_000
    /// Una copia di 3 GB può durare.
    static let attesaCopia: TimeInterval = 30 * 60
    static let nomeFile = "vera.gguf"

    /// I primi 4 byte sono «GGUF».
    static func eGGUF(_ url: URL) -> Bool {
        guard let h = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? h.close() }
        guard let d = try? h.read(upToCount: 4) else { return false }
        return d == Data("GGUF".utf8)
    }

    static func dimensione(_ url: URL) -> Int64 {
        ((try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? NSNumber)?.int64Value ?? 0
    }

    /// SHA256 a pezzi da 8 MB.
    static func impronta(_ url: URL) throws -> String {
        let h = try FileHandle(forReadingFrom: url)
        defer { try? h.close() }
        var sha = SHA256()
        while true {
            let pezzo: Data? = try autoreleasepool { try h.read(upToCount: 8 * 1_024 * 1_024) }
            guard let pezzo, !pezzo.isEmpty else { break }
            sha.update(data: pezzo)
        }
        return sha.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// I parametri di /api/show (testo a righe: «stop "<|im_end|>"\ntemperature 0.6») come oggetto per /api/create:
    /// le chiavi ripetute in un array (stop sempre in un array), i numeri come numeri.
    static func parametri(daShow testo: String) -> [String: Any] {
        var r: [String: Any] = [:]
        for riga in testo.split(whereSeparator: \.isNewline) {
            let t = riga.trimmingCharacters(in: .whitespaces)
            guard let spazio = t.firstIndex(where: \.isWhitespace) else { continue }
            let chiave = String(t[..<spazio])
            var valore = t[spazio...].trimmingCharacters(in: .whitespaces)
            if valore.count >= 2, valore.hasPrefix("\""), valore.hasSuffix("\"") { valore = String(valore.dropFirst().dropLast()) }
            let v: Any = Int(valore).map { $0 as Any } ?? Double(valore).map { $0 as Any } ?? valore
            if let gia = r[chiave] {
                r[chiave] = ((gia as? [Any]) ?? [gia]) + [v]
            } else {
                r[chiave] = chiave == "stop" ? [v] : v
            }
        }
        return r
    }

    /// Il corpo di /api/create.
    static func corpoCreazione(nome: String, impronta: String, show: [String: Any]) -> [String: Any] {
        var c: [String: Any] = ["model": nome, "files": [nomeFile: "sha256:" + impronta], "stream": false]
        if let t = show["template"] as? String, !t.isEmpty { c["template"] = t }
        if let p = show["parameters"] as? String, !p.isEmpty { c["parameters"] = parametri(daShow: p) }
        // Alcuni modelli recenti usano un renderer e un parser interni al posto del template: si copiano tali e quali
        for chiave in ["renderer", "parser", "system"] {
            if let v = show[chiave] as? String, !v.isEmpty { c[chiave] = v }
        }
        return c
    }

    private static func codice(_ r: URLResponse?) -> Int { (r as? HTTPURLResponse)?.statusCode ?? 0 }

    private static func richiesta(_ url: URL, metodo: String, corpo: [String: Any]? = nil, attesa: TimeInterval = 60) throws -> URLRequest {
        var r = URLRequest(url: url, timeoutInterval: attesa)
        r.httpMethod = metodo
        if let corpo {
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.httpBody = try JSONSerialization.data(withJSONObject: corpo)
        }
        return r
    }

    private static func indirizzo(_ fornitore: FornitoreOllama, _ percorso: String) throws -> URL {
        do { return try fornitore.url(percorso) } catch { throw ErroreImporta.nonLocale }
    }

    /// Copia il modello in Ollama e lo crea con il nome dato. Prima i controlli (indirizzo locale, file GGUF, dimensione):
    /// se uno non va, nessuna richiesta parte.
    static func importa(gguf: URL, nome: String, partenza: String, fornitore: FornitoreOllama,
                        avanzamento: @escaping (String) -> Void = { _ in }) async throws {
        _ = try indirizzo(fornitore, "api/version")
        avanzamento("Controllo il file…")
        guard eGGUF(gguf) else { throw ErroreImporta.nonGGUF }
        guard dimensione(gguf) <= massimoByte else { throw ErroreImporta.troppoGrande }
        avanzamento("Calcolo l'impronta…")
        let h = try impronta(gguf)
        let blob = try indirizzo(fornitore, "api/blobs/sha256:" + h)
        let s = fornitore.sessione
        let (_, testa) = try await s.data(for: try richiesta(blob, metodo: "HEAD"))
        if codice(testa) != 200 {
            avanzamento("Copio il modello in Ollama…")
            let (dati, risposta) = try await s.upload(for: try richiesta(blob, metodo: "POST", attesa: attesaCopia), fromFile: gguf)
            guard (200..<300).contains(codice(risposta)) else {
                throw ErroreImporta.ollama(FornitoreOllama.messaggioServer(String(data: dati, encoding: .utf8) ?? ""))
            }
        }
        avanzamento("Leggo il modello di partenza…")
        var show: [String: Any] = [:]
        let (datiShow, rispostaShow) = try await s.data(for: try richiesta(try indirizzo(fornitore, "api/show"), metodo: "POST", corpo: ["model": partenza]))
        if codice(rispostaShow) == 200, let j = try? JSONSerialization.jsonObject(with: datiShow) as? [String: Any] { show = j }
        avanzamento("Creo la Vera su misura…")
        let (datiCrea, rispostaCrea) = try await s.data(for: try richiesta(try indirizzo(fornitore, "api/create"), metodo: "POST",
                                                                          corpo: corpoCreazione(nome: nome, impronta: h, show: show), attesa: attesaCopia))
        guard codice(rispostaCrea) == 200 else {
            throw ErroreImporta.ollama(FornitoreOllama.messaggioServer(String(data: datiCrea, encoding: .utf8) ?? ""))
        }
    }

    /// DELETE /api/delete: libera i circa 3 GB di un modello scartato. true se Ollama l'ha tolto (o non c'era più).
    static func elimina(_ nome: String, fornitore: FornitoreOllama) async -> Bool {
        guard let u = try? indirizzo(fornitore, "api/delete"), let r = try? richiesta(u, metodo: "DELETE", corpo: ["model": nome]),
              case let (_, risposta)? = try? await fornitore.sessione.data(for: r) else { return false }
        return codice(risposta) == 200 || codice(risposta) == 404
    }

    /// Il .gguf e rapporto.json nella cartella o nello zip scelto (lo zip si apre in una cartella temporanea, che
    /// chi chiama cancella dopo l'importazione).
    static func trova(in url: URL) throws -> (gguf: URL, rapporto: URL?) {
        let fm = FileManager.default
        var cartella = url
        var eCartella: ObjCBool = false
        if url.pathExtension.lowercased() == "gguf" {
            let r = url.deletingLastPathComponent().appendingPathComponent(SuMisuraVera.nomeFileRapporto)
            return (url, fm.fileExists(atPath: r.path) ? r : nil)
        }
        if !(fm.fileExists(atPath: url.path, isDirectory: &eCartella) && eCartella.boolValue) {
            cartella = fm.temporaryDirectory.appendingPathComponent("Prisma-su-misura-\(UUID().uuidString)")
            try LettoreZip.estrai(url, in: cartella)
        }
        let file = (fm.enumerator(at: cartella, includingPropertiesForKeys: nil)?.allObjects as? [URL]) ?? []
        guard let gguf = file.first(where: { $0.pathExtension.lowercased() == "gguf" }) else { throw ErroreImporta.nonTrovato }
        return (gguf, file.first { $0.lastPathComponent == SuMisuraVera.nomeFileRapporto })
    }
}
