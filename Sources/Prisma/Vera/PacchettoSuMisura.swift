import CryptoKit
import Foundation

/// Il manifesto del pacchetto di addestramento: cosa contiene e da quale modello partire. Nessun dato dei clienti.
struct ManifestoSuMisura: Codable, Equatable {
    var versione = 1
    var creatoIl: Date
    var esempi: Int
    var lezioni: Int
    /// Il modello di Ollama da cui si parte («qwen3.5:4b»).
    var modelloDiPartenza: String
    /// Lo stesso modello come lo chiama Unsloth (Hugging Face): da verificare al primo addestramento.
    var modelloUnsloth: String
    /// Il nome che avrà in Ollama («vera-su-misura:2026-11-08»).
    var nomeModello: String
    var lunghezzaMassima = 4096
    /// SHA256 di addestramento.jsonl.
    var impronta: String
}

/// Il pacchetto di addestramento di «Vera su misura»: una cartella con gli esempi anonimi approvati (addestramento.jsonl),
/// il manifesto, le istruzioni (LEGGIMI.txt) e il notebook con lo script presi dal pacchetto dell'app
/// (Vera/Addestramento). Le domande dell'esame non ci sono mai. Prisma non lo invia: lo zip va dove sceglie l'utente.
enum PacchettoSuMisura {
    /// Il nome di Unsloth corrispondente a qwen3.5:4b: da verificare su Hugging Face al primo giro (domanda per l'utente).
    static let modelloUnslothPredefinito = "unsloth/Qwen3.5-4B"
    static let nomeLeggimi = "LEGGIMI.txt"

    static func modelloUnsloth(per partenza: String) -> String {
        FornitoreOllama.stessoModello(partenza, MotoreLocale.modelloPredefinito) ? modelloUnslothPredefinito : partenza
    }

    /// Una riga JSONL: {"messages":[…]} con le chiavi in ordine e senza barre protette.
    static func rigaJSONL(_ messaggi: [[String: String]]) -> String {
        guard let d = try? JSONSerialization.data(withJSONObject: ["messages": messaggi], options: [.sortedKeys, .withoutEscapingSlashes]),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }

    static func impronta(_ d: Data) -> String {
        SHA256.hash(data: d).map { String(format: "%02x", $0) }.joined()
    }

    /// Scrive la cartella del pacchetto e restituisce il manifesto. Gli esempi con residui non entrano.
    @discardableResult
    static func scrivi(_ esempi: [EsempioAnonimo], lezioni: [String], in cartella: URL, oggi: Date,
                       modelloDiPartenza: String, risorse: URL? = Bundle.main.resourceURL) throws -> ManifestoSuMisura {
        let fm = FileManager.default
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        let puliti = esempi.filter(\.pulito)
        let righe = puliti.map { rigaJSONL(SuMisuraVera.messaggiAddestramento($0, lezioni: lezioni)) }.filter { !$0.isEmpty }
        let jsonl = Data((righe.joined(separator: "\n") + (righe.isEmpty ? "" : "\n")).utf8)
        try jsonl.write(to: cartella.appendingPathComponent(SuMisuraVera.nomeFileAddestramento), options: .atomic)
        let manifesto = ManifestoSuMisura(creatoIl: oggi, esempi: righe.count, lezioni: lezioni.count, modelloDiPartenza: modelloDiPartenza,
                                          modelloUnsloth: modelloUnsloth(per: modelloDiPartenza), nomeModello: SuMisuraVera.nomeModello(oggi),
                                          impronta: impronta(jsonl))
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        try e.encode(manifesto).write(to: cartella.appendingPathComponent(SuMisuraVera.nomeFileManifesto), options: .atomic)
        try Data(leggimi(manifesto).utf8).write(to: cartella.appendingPathComponent(nomeLeggimi), options: .atomic)
        // Il notebook e lo script dal pacchetto dell'app (su iOS non ci sono: su misura si fa dal Mac)
        if let base = risorse?.appendingPathComponent("Vera/Addestramento") {
            for nome in [SuMisuraVera.nomeNotebook, SuMisuraVera.nomeScript] {
                let da = base.appendingPathComponent(nome)
                guard fm.fileExists(atPath: da.path) else { continue }
                let a = cartella.appendingPathComponent(nome)
                try? fm.removeItem(at: a)
                try fm.copyItem(at: da, to: a)
            }
        }
        return manifesto
    }

    /// La cartella in uno zip (ScrittoreZip), al posto scelto dall'utente.
    static func zippa(_ cartella: URL, a zip: URL) throws {
        try? FileManager.default.removeItem(at: zip)
        try ScrittoreZip.crea(da: cartella, a: zip)
    }

    /// Le istruzioni in chiaro dentro il pacchetto.
    static func leggimi(_ m: ManifestoSuMisura) -> String {
        """
        Vera su misura · pacchetto di addestramento
        ===========================================

        Esempi: \(m.esempi) (resi anonimi e approvati da te in Prisma) · lezioni: \(m.lezioni)
        Modello di partenza: \(m.modelloDiPartenza) (per Unsloth: \(m.modelloUnsloth), da verificare)
        Nome del modello addestrato: \(m.nomeModello)

        Cosa c'è
        - \(SuMisuraVera.nomeFileAddestramento): una conversazione per riga (istruzioni, domanda, risposta approvata).
        - \(SuMisuraVera.nomeFileManifesto): questi dati, con l'impronta SHA256 del file degli esempi.
        - \(SuMisuraVera.nomeNotebook) e \(SuMisuraVera.nomeScript): l'addestramento con Unsloth (LoRA, poi GGUF \(SuMisuraVera.quantizzazione)).

        Cosa non c'è
        - Nessun nome, indirizzo, email, telefono, codice fiscale o numero di documento dei clienti.
        - Nessuna domanda dell'esame: l'esame resta sul Mac.

        Come si usa
        1. Apri il notebook su Google Colab o Kaggle con una GPU gratuita e carica questa cartella.
        2. Esegui le celle in ordine (circa due ore).
        3. Scarica lo zip finale (il file .gguf e \(SuMisuraVera.nomeFileRapporto)).
        4. In Prisma: Vera › Vera su misura › «Importa il modello addestrato».
        La nuova Vera prende il posto di quella di oggi solo se supera l'esame sul Mac.
        """
    }
}
