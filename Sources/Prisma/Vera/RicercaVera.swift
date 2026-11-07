import CryptoKit
import Foundation

// La ricerca di Vera (Vera/BRIEF.md, fase 2): per significato con Qwen3-Embedding 0.6B via Ollama (/api/embed, solo sul
// Mac, caricato solo quando serve) e per parole con BM25, che resta sempre (anche senza il modello di ricerca). I due
// elenchi si fondono con il rango reciproco. I vettori stanno in una cache cifrata fuori dall'archivio (si ricostruiscono:
// non vanno nel backup). Cerca nei documenti dei clienti (pagina per pagina), nelle note, negli incontri, nei ricordi e
// nella biblioteca delle norme (articolo per articolo).

/// La finestra del modello (funzione 24 «Il filo lungo»): una sola per tutte le chiamate, perché Ollama ricarica il
/// modello quando cambia. Misurata sul MacBook Pro M1 da 8 GB il 7 novembre 2026: Qwen 3.5 4B occupa 3,79 GB a 8.192,
/// 16.384 e 32.768 token (/api/ps), il modello di ricerca 1,15 GB.
enum FinestraVera {
    static let scelte = [8_192, 16_384, 32_768]
    static let predefinita = 32_768

    static func valida(_ n: Int) -> Int { scelte.contains(n) ? n : predefinita }

    static func nome(_ n: Int) -> String {
        switch n {
        case 8_192: return "8.000 token, come prima"
        case 16_384: return "16.000 token"
        default: return "32.000 token, il filo lungo"
        }
    }

    private static let blocco = NSLock()
    private static var _attuale = predefinita

    /// La finestra in uso (la imposta Prisma dalle impostazioni di Vera).
    static var attuale: Int {
        get { blocco.lock(); defer { blocco.unlock() }; return _attuale }
        set { blocco.lock(); _attuale = valida(newValue); blocco.unlock() }
    }
}

/// Un pezzo in cui cercare: una pagina di un documento, una nota, un incontro, un ricordo, un articolo di una norma.
struct PezzoRicerca: Equatable {
    enum Tipo: String { case documento, nota, incontro, ricordo, norma }

    var id: String
    var tipo: Tipo
    var clienteId: String?
    /// «Documento «KID» · pagina 2», «Nota del 12 settembre», «Codice delle assicurazioni · art. 177».
    var fonte: String
    var testo: String
}

/// Un pezzo trovato, con il suo punteggio.
struct Trovato: Equatable {
    var pezzo: PezzoRicerca
    var punteggio: Double
}

enum RicercaVera {
    static let modelloPredefinito = "qwen3-embedding:0.6b"
    /// Qwen3-Embedding vuole l'istruzione davanti alla domanda (i testi vanno senza).
    static let istruzione = "Instruct: Data la domanda di un consulente finanziario italiano, trova i passaggi che rispondono\nQuery: "
    /// Il modello di ricerca resta in memoria per poco dopo l'ultima ricerca (regola 7: un solo modello grande).
    static let restaInMemoria = "1m"

    // MARK: - Parole (BM25)

    private static let vuote: Set<String> = ["della", "delle", "degli", "dello", "nella", "nelle", "negli", "dalla", "dalle", "sulla", "sulle",
                                             "alla", "alle", "agli", "allo", "che", "con", "per", "una", "uno", "non", "più", "sono", "come",
                                             "anche", "questo", "questa", "quello", "quella", "cosa", "quanto", "quando", "dove", "chi", "del",
                                             "dei", "gli", "le", "lo", "il", "la", "di", "da", "in", "su", "tra", "fra", "suo", "sua", "suoi", "sue",
                                             "mio", "mia", "tuo", "tua", "ogni", "essere", "deve", "può", "hanno", "ha", "è", "sia", "se", "ma", "o", "e"]

    /// Le parole significative, minuscole e senza accenti, accorciate a sei lettere (riscatto/riscattare insieme).
    static func parole(_ t: String) -> [String] {
        let piegato = t.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
        return piegato.split { !$0.isLetter && !$0.isNumber }.map(String.init)
            .filter { $0.count >= 3 && !vuote.contains($0) }
            .map { $0.count > 6 && $0.allSatisfy(\.isLetter) ? String($0.prefix(6)) : $0 }
    }

    /// BM25 classico (k1 = 1,2, b = 0,75): il punteggio di ogni pezzo per la domanda.
    static func bm25(_ domanda: String, _ pezzi: [PezzoRicerca]) -> [Double] {
        let q = Set(parole(domanda))
        guard !q.isEmpty, !pezzi.isEmpty else { return pezzi.map { _ in 0 } }
        let documenti = pezzi.map(\.testo).map(parole)
        let media = max(1, Double(documenti.map(\.count).reduce(0, +)) / Double(documenti.count))
        var presenza: [String: Int] = [:]
        for d in documenti { for p in Set(d) where q.contains(p) { presenza[p, default: 0] += 1 } }
        let n = Double(documenti.count)
        return documenti.map { d in
            var frequenze: [String: Int] = [:]
            for p in d where q.contains(p) { frequenze[p, default: 0] += 1 }
            return frequenze.reduce(0) { somma, voce in
                let df = Double(presenza[voce.key] ?? 0)
                let idf = log(1 + (n - df + 0.5) / (df + 0.5))
                let f = Double(voce.value)
                return somma + idf * f * 2.2 / (f + 1.2 * (0.25 + 0.75 * Double(d.count) / media))
            }
        }
    }

    // MARK: - Significato

    /// Il prodotto scalare (i vettori di Ollama sono già normalizzati).
    static func somiglianza(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var s: Float = 0
        for i in a.indices { s += a[i] * b[i] }
        return Double(s)
    }

    /// I pezzi più pertinenti: BM25 e (se ci sono i vettori) significato, fusi con il rango reciproco. Un pezzo senza
    /// nessuna parola in comune e poco simile non entra: meglio «non trovato» che un passaggio a caso.
    static func cerca(_ domanda: String, in pezzi: [PezzoRicerca], vettori: [String: [Float]] = [:], domandaVettore: [Float]? = nil,
                      quanti: Int = 5, somiglianzaMinima: Double = 0.45) -> [Trovato] {
        guard !pezzi.isEmpty else { return [] }
        let parolePunti = bm25(domanda, pezzi)
        var punti: [Int: Double] = [:]
        let perParole = parolePunti.enumerated().filter { $0.element > 0 }.sorted { $0.element > $1.element }
        for (rango, voce) in perParole.enumerated() { punti[voce.offset, default: 0] += 1 / Double(60 + rango) }
        if let q = domandaVettore {
            let perSignificato = pezzi.enumerated().compactMap { i, p -> (Int, Double)? in
                guard let v = vettori[p.id] else { return nil }
                let s = somiglianza(q, v)
                return s >= somiglianzaMinima ? (i, s) : nil
            }.sorted { $0.1 > $1.1 }
            for (rango, voce) in perSignificato.enumerated() { punti[voce.0, default: 0] += 1 / Double(60 + rango) }
        }
        return punti.sorted { $0.value > $1.value }.prefix(quanti).map { Trovato(pezzo: pezzi[$0.key], punteggio: $0.value) }
    }

    /// L'impronta del testo di un pezzo (la chiave della cache dei vettori): se il testo cambia, il vettore si rifà.
    static func impronta(_ testo: String, modello: String) -> String {
        let h = SHA256.hash(data: Data((modello + "\u{1F}" + testo).utf8))
        return h.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Pezzi dai dati

    /// Le pagine dei documenti di un cliente (dal testo letto, «\u{0C}» tra le pagine), le note e gli incontri.
    static func pezzi(documenti: [(Documento, [String])], note: [Nota], incontri: [Incontro]) -> [PezzoRicerca] {
        var p: [PezzoRicerca] = []
        for (d, pagine) in documenti {
            for (i, testo) in pagine.enumerated() where testo.trimmingCharacters(in: .whitespacesAndNewlines).count > 40 {
                p.append(PezzoRicerca(id: "doc-\(d.id)-\(i + 1)", tipo: .documento, clienteId: d.clienteId,
                                      fonte: "Documento «\(d.titolo)» · pagina \(i + 1)", testo: String(testo.prefix(3_000))))
            }
        }
        for n in note where !n.vuota {
            p.append(PezzoRicerca(id: "nota-\(n.id)", tipo: .nota, clienteId: n.clienteId,
                                  fonte: "Nota «\(n.titolo)»", testo: String((n.titolo + "\n" + n.testo).prefix(1_500))))
        }
        for i in incontri {
            let testo = [i.preoccupazioni, i.progetti, i.esperienza, i.appunti, i.decisioni].filter { !$0.isEmpty }.joined(separator: "\n")
            guard !testo.isEmpty else { continue }
            p.append(PezzoRicerca(id: "incontro-\(i.id)", tipo: .incontro, clienteId: i.clienteId,
                                  fonte: "Incontro del \(Formati.dataEstesa.string(from: i.data))", testo: String(testo.prefix(2_000))))
        }
        return p
    }
}

/// I vettori della ricerca: chiesti a Ollama solo per i testi che mancano, tenuti in una cache cifrata
/// (~/Library/Caches/Prisma/vettori-vera.cifrato, con la chiave della memoria di Vera; fuori dal backup).
final class IndiceVera {
    private let blocco = NSLock()
    private var vettori: [String: [Float]] = [:]
    private var caricato = false
    private let persistente: Bool
    private let chiave: () -> SymmetricKey?

    init(persistente: Bool, chiave: @escaping () -> SymmetricKey?) {
        self.persistente = persistente
        self.chiave = chiave
    }

    static var file: URL {
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return cache.appendingPathComponent("Prisma", isDirectory: true).appendingPathComponent("vettori-vera.cifrato")
    }

    static let uso = "PrismaVE v1 · vettori"

    private func caricaSeServe() {
        blocco.lock(); defer { blocco.unlock() }
        guard !caricato else { return }
        caricato = true
        guard persistente, let k = chiave(), let d = try? Data(contentsOf: Self.file),
              let chiaro = try? CifraturaBackup.decifra(d, chiave: k, uso: Self.uso),
              let letti = try? JSONDecoder().decode([String: [Float]].self, from: chiaro) else { return }
        vettori = letti
    }

    private func salva() {
        guard persistente, let k = chiave() else { return }
        blocco.lock()
        let copia = vettori
        blocco.unlock()
        guard let d = try? JSONEncoder().encode(copia), let cifrato = try? CifraturaBackup.cifra(d, chiave: k, uso: Self.uso) else { return }
        try? FileManager.default.createDirectory(at: Self.file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? cifrato.write(to: Self.file, options: .atomic)
    }

    var quanti: Int {
        caricaSeServe()
        blocco.lock(); defer { blocco.unlock() }
        return vettori.count
    }

    /// I vettori dei pezzi (per id) e della domanda; nil se il modello di ricerca non c'è (resta BM25).
    /// Prima di un'indicizzazione grande Qwen si libera (un solo modello grande alla volta).
    func vettori(per pezzi: [PezzoRicerca], domanda: String, fornitore: FornitoreOllama, modello: String,
                 liberaPrima: (() async -> Void)? = nil) async -> (pezzi: [String: [Float]], domanda: [Float])? {
        caricaSeServe()
        var mancanti: [(String, String)] = []
        var trovati: [String: [Float]] = [:]
        blocco.lock()
        for p in pezzi {
            let k = RicercaVera.impronta(p.testo, modello: modello)
            if let v = vettori[k] { trovati[p.id] = v } else { mancanti.append((p.id, p.testo)) }
        }
        blocco.unlock()
        // Prima la domanda: se il modello di ricerca non c'è si resta a BM25, senza aver liberato Qwen per niente
        guard let q = try? await fornitore.incorpora([RicercaVera.istruzione + domanda], modello: modello).first else { return nil }
        if mancanti.count > 32, let liberaPrima { await liberaPrima() }
        var nuovi = false
        for gruppo in stride(from: 0, to: mancanti.count, by: 16).map({ Array(mancanti[$0..<min($0 + 16, mancanti.count)]) }) {
            guard let v = try? await fornitore.incorpora(gruppo.map(\.1), modello: modello), v.count == gruppo.count else {
                if nuovi { salva() }
                return nil
            }
            blocco.lock()
            for (i, voce) in gruppo.enumerated() {
                trovati[voce.0] = v[i]
                vettori[RicercaVera.impronta(voce.1, modello: modello)] = v[i]
            }
            blocco.unlock()
            nuovi = true
        }
        if nuovi { salva() }
        return (trovati, q)
    }
}

extension FornitoreOllama {
    /// I vettori dei testi con il modello di ricerca (/api/embed), sempre a un indirizzo del Mac.
    func incorpora(_ testi: [String], modello: String, restaInMemoria: String = RicercaVera.restaInMemoria) async throws -> [[Float]] {
        guard !testi.isEmpty else { return [] }
        var r = URLRequest(url: try url("api/embed"), timeoutInterval: 120)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try JSONSerialization.data(withJSONObject: ["model": modello, "input": testi, "keep_alive": restaInMemoria] as [String: Any])
        let (dati, risposta) = try await sessione.data(for: r)
        guard (risposta as? HTTPURLResponse)?.statusCode == 200,
              let j = try JSONSerialization.jsonObject(with: dati) as? [String: Any],
              let e = j["embeddings"] as? [[NSNumber]] else {
            throw ErroreVera(messaggio: "Il modello di ricerca \(modello) non risponde: scaricalo con «ollama pull \(modello)».")
        }
        return e.map { $0.map(\.floatValue) }
    }

    /// Toglie dalla memoria il modello di ricerca.
    func liberaRicerca(_ modello: String) async {
        _ = await manda("api/embed", ["model": modello, "input": [String](), "keep_alive": 0], attesa: 20)
    }
}
