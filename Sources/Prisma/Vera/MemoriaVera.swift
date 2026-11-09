import CryptoKit
import Foundation

// La memoria di Vera (Vera/BRIEF.md, fase 2): funzioni 18 «La memoria», 21 «Impara dalle correzioni» e 24 «Il filo
// lungo». Ricordi su di te e sui clienti, lezioni dalle correzioni, esempi approvati con 👍 e i riassunti delle
// conversazioni lunghe stanno in un file solo, cifrato (Vera/memoria.cifrato accanto all'archivio, algoritmo 2 di
// CifraturaBackup con una chiave casuale nel Portachiavi, PortachiaviMemoria). Mai in archivio.json, mai nell'istantanea
// di «Prisma ovunque». Nel backup va il file cifrato; la chiave ci va solo cifrata con la password dei backup
// (Vera/chiave-memoria.cifrato), così la memoria si apre anche su un altro Mac. Prima il codice: un ricordo con numeri di
// documenti, conti o password non si salva.

struct RicordoVera: Codable, Identifiable, Equatable {
    var id = "ricordo-\(UUID().uuidString.prefix(8).lowercased())"
    var testo: String
    /// nil = un ricordo su di te.
    var clienteId: String?
    /// «in chat», «dal resoconto del 12 settembre», «da una tua correzione».
    var fonte: String
    var data = Date()
}

struct LezioneVera: Codable, Identifiable, Equatable {
    var id = "lezione-\(UUID().uuidString.prefix(8).lowercased())"
    var testo: String
    var fonte = "da una tua correzione"
    var data = Date()
    var attiva = true
}

/// Una risposta approvata con 👍: un esempio per l'addestramento su misura (fase 5) e per lo stile.
/// Fase 5: un id stabile (per tenere da parte le domande dell'esame), la modalità in cui Vera aveva risposto e
/// l'esclusione scelta dal consulente nell'anteprima di «Vera su misura». Letto con tolleranza: un esempio di prima
/// senza id riceve sempre lo stesso id (l'impronta di domanda e risposta).
struct EsempioVera: Codable, Equatable, Identifiable {
    var id: String
    var domanda: String
    var risposta: String
    var data = Date()
    /// nil = esempio di prima della fase 5 (la modalità non era salvata).
    var modalita: ModalitaVera?
    /// Escluso dal consulente: non entra mai nel pacchetto né nell'esame.
    var escluso = false

    init(domanda: String, risposta: String, data: Date = Date(), modalita: ModalitaVera? = nil) {
        self.id = Self.impronta(domanda: domanda, risposta: risposta)
        self.domanda = domanda
        self.risposta = risposta
        self.data = data
        self.modalita = modalita
    }

    /// Le prime 12 cifre esadecimali dello SHA256 di domanda e risposta: lo stesso esempio ha sempre lo stesso id.
    static func impronta(domanda: String, risposta: String) -> String {
        let h = SHA256.hash(data: Data((domanda + "\u{1F}" + risposta).utf8))
        return "esempio-" + String(h.map { String(format: "%02x", $0) }.joined().prefix(12))
    }

    private enum CodingKeys: String, CodingKey { case id, domanda, risposta, data, modalita, escluso }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        domanda = try c.decode(String.self, forKey: .domanda)
        risposta = try c.decode(String.self, forKey: .risposta)
        data = (try? c.decodeIfPresent(Date.self, forKey: .data)) ?? Date()
        modalita = (try? c.decodeIfPresent(ModalitaVera.self, forKey: .modalita)) ?? nil
        escluso = (try? c.decodeIfPresent(Bool.self, forKey: .escluso)) ?? false
        let salvato = ((try? c.decodeIfPresent(String.self, forKey: .id)) ?? nil) ?? ""
        id = salvato.isEmpty ? Self.impronta(domanda: domanda, risposta: risposta) : salvato
    }
}

/// Il riassunto progressivo di una conversazione lunga: copre le battute fino a `finoA` (esclusa la storia ancora visibile).
struct FiloVera: Codable, Equatable {
    var riassunto: String
    var finoA: String
    var data = Date()
}

/// Tutto il contenuto del file cifrato.
struct ContenutoMemoriaVera: Codable, Equatable {
    var versione = 1
    var ricordi: [RicordoVera] = []
    var lezioni: [LezioneVera] = []
    var esempi: [EsempioVera] = []
    /// Per conversazione (la chiave è quella delle conversazioni: id del cliente o «·portafoglio»).
    var fili: [String: FiloVera] = [:]

    init() {}

    private enum CodingKeys: String, CodingKey { case versione, ricordi, lezioni, esempi, fili }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        versione = (try? c.decodeIfPresent(Int.self, forKey: .versione)) ?? 1
        ricordi = ((try? c.decodeIfPresent(ElencoTollerante<RicordoVera>.self, forKey: .ricordi)) ?? nil)?.elementi ?? []
        lezioni = ((try? c.decodeIfPresent(ElencoTollerante<LezioneVera>.self, forKey: .lezioni)) ?? nil)?.elementi ?? []
        esempi = ((try? c.decodeIfPresent(ElencoTollerante<EsempioVera>.self, forKey: .esempi)) ?? nil)?.elementi ?? []
        fili = (try? c.decodeIfPresent([String: FiloVera].self, forKey: .fili)) ?? [:]
    }
}

enum MemoriaVera {
    static let uso = "PrismaVE v1 · memoria"
    static let massimoRicordi = 400
    static let massimoLezioni = 60
    static let massimoEsempi = 300

    static var file: URL { Archivio.cartellaVera.appendingPathComponent("memoria.cifrato") }
    static var fileChiave: URL { Archivio.cartellaVera.appendingPathComponent("chiave-memoria.cifrato") }

    // MARK: - Cifratura

    static func scrivi(_ c: ContenutoMemoriaVera, chiave: SymmetricKey) throws -> Data {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return try CifraturaBackup.cifra(try e.encode(c), chiave: chiave, uso: uso)
    }

    static func leggi(_ cifrato: Data, chiave: SymmetricKey) throws -> ContenutoMemoriaVera {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(ContenutoMemoriaVera.self, from: try CifraturaBackup.decifra(cifrato, chiave: chiave, uso: uso))
    }

    /// Una chiave nuova, casuale (32 byte).
    static func nuovaChiave() -> SymmetricKey? {
        (try? CifraturaBackup.casuali(32)).map { SymmetricKey(data: $0) }
    }

    /// La chiave cifrata con la password dei backup (algoritmo 1, come i backup protetti): va nel backup.
    static func avvolgi(_ chiave: SymmetricKey, password: String, in url: URL, iterazioni: UInt32 = CifraturaBackup.iterazioniPredefinite) throws {
        let fm = FileManager.default
        let chiaro = fm.temporaryDirectory.appendingPathComponent("Prisma-chiave-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: chiaro) }
        try chiave.withUnsafeBytes { Data($0) }.write(to: chiaro, options: .atomic)
        try CifraturaBackup.cifra(chiaro, in: url, password: password, iterazioni: iterazioni)
    }

    /// La chiave ripresa dal file cifrato con la password dei backup (dopo un ripristino su un altro Mac).
    static func svolgi(_ url: URL, password: String) throws -> SymmetricKey {
        let fm = FileManager.default
        let chiaro = fm.temporaryDirectory.appendingPathComponent("Prisma-chiave-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: chiaro) }
        try CifraturaBackup.decifra(url, in: chiaro, password: password)
        let d = try Data(contentsOf: chiaro)
        guard d.count == 32 else { throw ErroreBackup.backupDanneggiato }
        return SymmetricKey(data: d)
    }

    // MARK: - Prima il codice: cosa non si ricorda mai

    /// Il motivo per cui un testo non si può ricordare (nil = si può): numeri di documenti, conti, carte, codici fiscali,
    /// password e PIN.
    static func vietato(_ testo: String) -> String? {
        let t = testo.lowercased()
        if DateItaliane.cerca(#"\b(password|passcode|pin|codice segreto|credenziali|parola d'ordine)\b"#, t) != nil {
            return "Non ricordo password, PIN o credenziali."
        }
        if DateItaliane.cerca(#"\bit\s?\d{2}\s?[a-z]\s?(?:\d\s?){10}(?:[0-9a-z]\s?){12}"#, t) != nil || DateItaliane.cerca(#"\biban\b"#, t) != nil {
            return "Non ricordo numeri di conto (IBAN)."
        }
        if DateItaliane.cerca(#"\b[a-z]{6}\d{2}[a-z]\d{2}[a-z]\d{3}[a-z]\b"#, t) != nil {
            return "Non ricordo codici fiscali: stanno nella scheda del cliente."
        }
        let cifreDiFila = t.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if DateItaliane.cerca(#"\d{8,}"#, cifreDiFila) != nil {
            return "Non ricordo numeri di documenti, conti, carte o telefoni: stanno nelle schede di Prisma."
        }
        if DateItaliane.cerca(#"\b(carta d'identit|passaporto|patente|numero di (conto|carta|polizza|contratto))"#, t) != nil, DateItaliane.cerca(#"\d{5,}"#, t) != nil {
            return "Non ricordo numeri di documenti."
        }
        return nil
    }

    // MARK: - Ricordi dalle frasi

    /// «Ricorda che Sofia decide sempre insieme a Paolo» → «Sofia decide sempre insieme a Paolo».
    static func richiestaEsplicita(_ testo: String) -> String? {
        let t = InterpreteComandi.pulisci(testo)
        guard let (r, g) = DateItaliane.cerca(#"^(?:ricorda(?:ti)?|tieni a mente|memorizza|segnati in memoria)\s+(?:che\s+|di\s+)?(.+)$"#, t) else { return nil }
        _ = r
        let resto = g[1].trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        // «Ricorda(ti) di + verbo» è una cosa da fare (un promemoria dei comandi), non un fatto da ricordare
        guard resto.count >= 6, DateItaliane.cerca(#"^(?:ricorda(?:ti)?|tieni a mente|memorizza|segnati in memoria)\s+di\s+"#, t) == nil else { return nil }
        // Ripreso dalla frase originale (con le maiuscole dei nomi)
        if let i = testo.range(of: resto, options: [.caseInsensitive, .diacriticInsensitive]) {
            return maiuscola(String(testo[i]))
        }
        return maiuscola(resto)
    }

    private static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    /// Le frasi di una tua domanda che sembrano un ricordo utile (preferenze, abitudini, cose che contano): Vera le propone,
    /// tu confermi. Prima il codice: si cercano parole come «preferisce», «non vuole», «decide sempre».
    static func proposte(da testo: String) -> [String] {
        let frasi = testo.components(separatedBy: CharacterSet(charactersIn: ".;!?\n")).map { $0.trimmingCharacters(in: .whitespaces) }
        let segni = #"\b(preferisce|preferiscono|non vuole|non vogliono|vuole sempre|decide(?:no)? sempre|decide(?:no)? insieme|gli piace|le piace|ama|odia|detesta|evita|non sopporta|è importante per|la cosa più importante|tiene molto|ci tiene|è allergic|non ama|mai prima delle|solo (?:al mattino|il pomeriggio|in studio|per telefono)|dà(?:i)? del lei|vuole il lei|vuole essere chiamat)"#
        return frasi.filter { f in
            f.count >= 12 && f.count <= 220 && DateItaliane.cerca(segni, f.lowercased()) != nil && vietato(f) == nil
                && DateItaliane.cerca(#"\?$|^(chi|cosa|come|quanto|quando|perch)"#, f.lowercased()) == nil
        }.map(maiuscola)
    }

    /// I ricordi da dare a Vera per una domanda: quelli del cliente, poi quelli su di te (al massimo `quanti`).
    static func pertinenti(_ ricordi: [RicordoVera], cliente: String?, quanti: Int = 12) -> [RicordoVera] {
        let delCliente = ricordi.filter { $0.clienteId != nil && $0.clienteId == cliente }.sorted { $0.data > $1.data }
        let tuoi = ricordi.filter { $0.clienteId == nil }.sorted { $0.data > $1.data }
        return Array((delCliente + tuoi).prefix(quanti))
    }
}

/// Le lezioni attive, lette prima di ogni risposta di Qwen (MotoreLocale): valgono dalla risposta successiva al salvataggio.
enum LezioniVera {
    private static let blocco = NSLock()
    private static var _attive: [String] = []

    static var attive: [String] {
        get { blocco.lock(); defer { blocco.unlock() }; return _attive }
        set { blocco.lock(); _attive = newValue; blocco.unlock() }
    }

    /// Il blocco aggiunto alle istruzioni di sistema (nil senza lezioni).
    static func blocco(_ lezioni: [String]) -> String? {
        guard !lezioni.isEmpty else { return nil }
        return "LEZIONI DEL CONSULENTE (correzioni che ti ha dato: seguile sempre, prima di ogni altra preferenza di stile)\n"
            + lezioni.prefix(MemoriaVera.massimoLezioni).map { "- \($0)" }.joined(separator: "\n")
    }

    /// Le istruzioni di sistema con le lezioni in fondo (solo per le risposte a testo libero, non per i JSON).
    static func applica(_ messaggi: [MessaggioModello], opzioni: OpzioniModello, lezioni: [String] = attive) -> [MessaggioModello] {
        guard opzioni.formato == nil, opzioni.conLezioni, let b = blocco(lezioni), let i = messaggi.firstIndex(where: { $0.ruolo == .sistema }) else { return messaggi }
        var m = messaggi
        m[i].testo += "\n\n" + b
        return m
    }
}

/// Il riassunto progressivo (funzione 24): le battute che escono dalla finestra si riassumono con Qwen in poche righe;
/// il riassunto entra nell'ultimo messaggio come «IL FILO DELLA CONVERSAZIONE». Senza Qwen resta un riassunto di Prisma:
/// le tue frasi uscite, accorciate.
enum FiloLungoVera {
    static let massimoCaratteri = 1_800

    /// Le battute che la storia non porta più al modello (le più vecchie), in ordine.
    static func uscite(_ messaggi: [MessaggioVera], budget: Int) -> [MessaggioVera] {
        let dentro = NucleoVera.storia(messaggi, budget: budget).count
        let valide = messaggi.filter { !($0.autore == .vera && ($0.motore == "Prisma" || $0.titolo == "Vera non ha potuto rispondere")) }
        guard valide.count > dentro else { return [] }
        return Array(valide.prefix(valide.count - dentro))
    }

    /// Il riassunto di Prisma, senza modello: le tue frasi (e l'inizio delle risposte di Vera), le prime della conversazione
    /// e le più recenti, entro il limite; in mezzo «…». L'inizio conta: è lì che di solito si dicono i fatti.
    static func riassuntoDiPrisma(_ uscite: [MessaggioVera]) -> String {
        let righe = uscite.map { m -> String in
            let testo = m.testo.replacingOccurrences(of: "\n", with: " ")
            let massimo = m.autore == .utente ? 200 : 110
            return "\(m.autore == .utente ? "Tu" : "Vera"): \(testo.count > massimo ? String(testo.prefix(massimo)) + "…" : testo)"
        }
        guard righe.reduce(0, { $0 + $1.count + 1 }) > massimoCaratteri else { return righe.joined(separator: "\n") }
        var inizio: [String] = []
        var fine: [String] = []
        var resto = massimoCaratteri - 2
        var i = 0, j = righe.count - 1
        while i <= j {
            let r = righe[i]
            guard r.count + 1 <= resto / 2 || inizio.isEmpty, r.count + 1 <= resto else { break }
            inizio.append(r); resto -= r.count + 1; i += 1
            guard i <= j else { break }
            let u = righe[j]
            guard u.count + 1 <= resto else { break }
            fine.insert(u, at: 0); resto -= u.count + 1; j -= 1
        }
        return (inizio + (i <= j ? ["…"] : []) + fine).joined(separator: "\n")
    }

    static var istruzioni: String {
        IstruzioniVera.testo("filo") ?? "Aggiorna il riassunto di una conversazione tra un consulente finanziario e Vera, la sua assistente. Tieni i fatti, le decisioni, le preferenze e le cifre così come sono scritte (non rifare conti, non aggiungere niente). Al massimo dieci righe brevi, in italiano, senza titoli."
    }

    static func messaggi(precedente: String?, nuove: [MessaggioVera]) -> [MessaggioModello] {
        let battute = nuove.map { ($0.autore == .utente ? "Consulente: " : "Vera: ") + $0.testo }.joined(separator: "\n")
        let testo = "RIASSUNTO FIN QUI\n\(precedente ?? "(nessuno)")\n\nBATTUTE DA AGGIUNGERE\n\(battute)\n\nScrivi solo il riassunto aggiornato."
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni), MessaggioModello(ruolo: .utente, testo: testo)]
    }
}
