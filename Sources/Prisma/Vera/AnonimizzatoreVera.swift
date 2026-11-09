import Foundation

// L'anonimizzazione degli esempi di «Vera su misura» (fase 5, funzione 22) e il controllo del «cervello grande»
// (funzione 25). Prima il codice, con regole fisse e in quest'ordine: IBAN, codici fiscali, email, telefoni, numeri
// lunghi; indirizzi; date di nascita; nomi e cognomi dei clienti, dei familiari, delle aziende e del consulente. Poi il
// controllo dei residui: un esempio in cui resta qualcosa di identificabile non entra nel pacchetto. Le cifre degli
// importi restano (come nel template: «550 € al mese»).

/// I dati di identità di tutti i clienti dell'archivio, pronti per la ricerca: nomi e cognomi (interi e parola per
/// parola, da 3 lettere), familiari, aziende e partite IVA, email, telefoni, codici fiscali, indirizzi, date di nascita
/// e il nome del consulente.
struct IdentificativiClienti {
    /// Nomi interi da togliere, con il loro segnaposto (i più lunghi prima).
    private(set) var frasi: [(testo: String, segnaposto: String)] = []
    /// Parole singole (semplificate: minuscole, senza accenti) con il loro segnaposto.
    private(set) var parole: [String: String] = [:]
    private(set) var email: Set<String> = []
    /// Le cifre dei telefoni e delle partite IVA (almeno 6).
    private(set) var cifre: Set<String> = []
    private(set) var codiciFiscali: Set<String> = []
    /// Le date di nascita già scritte nei modi più comuni («02/07/1987», «2 luglio 1987»).
    private(set) var date: Set<String> = []

    init(clienti: [Cliente], consulente: String = "") {
        var frasi: [(String, String)] = []
        var parole: [String: String] = [:]
        func aggiungi(_ nome: String, _ segnaposto: String, parola: Bool = true) {
            let n = nome.trimmingCharacters(in: .whitespacesAndNewlines)
            guard n.count >= 3 else { return }
            frasi.append((n, segnaposto))
            guard parola else { return }
            for p in n.split(whereSeparator: { !$0.isLetter }).map(String.init) where p.count >= 3 {
                let s = NucleoVera.semplice(p)
                // Il segnaposto più forte vince: un cognome del cliente resta «[Cliente]» anche se lo porta un familiare
                if parole[s] == nil || segnaposto == AnonimizzatoreVera.cliente { parole[s] = segnaposto }
            }
        }
        for c in clienti {
            aggiungi(c.nome, AnonimizzatoreVera.cliente)
            for f in c.famiglia { aggiungi(f.nome, AnonimizzatoreVera.familiare) }
            for a in c.elencoAziende {
                aggiungi(a.ragioneSociale, AnonimizzatoreVera.azienda, parola: false)
                if let p = a.partitaIVA { let d = p.filter(\.isNumber); if d.count >= 6 { cifre.insert(d) } }
            }
            if !c.indirizzo.trimmingCharacters(in: .whitespaces).isEmpty {
                frasi.append((c.indirizzo.trimmingCharacters(in: .whitespaces), AnonimizzatoreVera.indirizzo))
                // Anche solo la via, senza la città
                if let via = c.indirizzo.split(separator: ",").first.map({ $0.trimmingCharacters(in: .whitespaces) }), via.count >= 6 {
                    frasi.append((via, AnonimizzatoreVera.indirizzo))
                }
            }
            let e = c.email.trimmingCharacters(in: .whitespaces).lowercased()
            if e.contains("@") { email.insert(e) }
            let t = c.telefono.filter(\.isNumber)
            if t.count >= 6 { cifre.insert(t) }
            let cf = c.codiceFiscale.trimmingCharacters(in: .whitespaces).lowercased()
            if cf.count >= 11 { codiciFiscali.insert(cf) }
            for d in [c.dataNascita].compactMap({ $0 }) + c.famiglia.compactMap(\.dataNascita) {
                date.formUnion(Self.scritture(d))
            }
        }
        aggiungi(consulente, AnonimizzatoreVera.consulente)
        self.frasi = frasi.sorted { $0.0.count > $1.0.count }.map { (testo: $0.0, segnaposto: $0.1) }
        self.parole = parole
    }

    /// I modi più comuni di scrivere una data di nascita.
    static func scritture(_ d: Date) -> Set<String> {
        let it = Locale(identifier: "it_IT")
        return Set(["dd/MM/yyyy", "d/M/yyyy", "dd-MM-yyyy", "dd.MM.yyyy", "d MMMM yyyy"].map { f -> String in
            let df = DateFormatter()
            df.locale = it
            df.dateFormat = f
            return df.string(from: d).lowercased()
        })
    }

    /// C'è ancora qualcosa di identificabile nel testo?
    func contiene(_ testo: String) -> Bool { !trovati(testo).isEmpty }

    /// Ciò che di identificabile resta nel testo (nomi, email, telefoni, codici fiscali, date di nascita).
    func trovati(_ testo: String) -> [String] {
        var r: [String] = []
        let s = NucleoVera.semplice(testo)
        for f in frasi where AnonimizzatoreVera.intervalli(di: f.testo, in: testo).isEmpty == false { r.append(f.testo) }
        for p in s.split(whereSeparator: { !$0.isLetter }).map(String.init) where parole[p] != nil && !AnonimizzatoreVera.segnaposti.contains(p) {
            r.append(p)
        }
        let minuscolo = testo.lowercased()
        r += email.filter { minuscolo.contains($0) }
        r += codiciFiscali.filter { minuscolo.contains($0) }
        r += date.filter { minuscolo.contains($0) }
        let soloCifre = testo.filter(\.isNumber)
        r += cifre.filter { soloCifre.contains($0) }
        var visti = Set<String>()
        return r.filter { visti.insert($0.lowercased()).inserted }
    }
}

/// Una sostituzione fatta dall'anonimizzazione (per l'anteprima evidenziata).
struct Sostituzione: Equatable {
    var originale: String
    var segnaposto: String
}

/// Un esempio approvato, reso anonimo, pronto per l'anteprima e per il pacchetto.
struct EsempioAnonimo: Equatable, Identifiable {
    var id: String
    var domanda: String
    var risposta: String
    var modalita: ModalitaVera
    var sostituzioni: [Sostituzione]
    /// Possibili nomi che non sono nell'archivio (due parole maiuscole di fila non a inizio frase): da guardare.
    var daGuardare: [String]
    /// Ciò che resta di identificabile dopo le regole: un esempio con residui non entra nel pacchetto.
    var residui: [String] = []

    var pulito: Bool { residui.isEmpty }
}

enum AnonimizzatoreVera {
    static let cliente = "[Cliente]"
    static let familiare = "[Familiare]"
    static let indirizzo = "[Indirizzo]"
    static let email = "[Email]"
    static let telefono = "[Telefono]"
    static let codiceFiscale = "[Codice fiscale]"
    static let iban = "[IBAN]"
    static let numero = "[Numero]"
    static let data = "[Data di nascita]"
    static let azienda = "[Azienda]"
    static let consulente = "[Consulente]"

    /// Le parole dei segnaposti (semplificate): non sono residui.
    static let segnaposti: Set<String> = ["cliente", "familiare", "indirizzo", "email", "telefono", "codice", "fiscale", "iban",
                                          "numero", "data", "nascita", "azienda", "consulente"]

    // MARK: - Schemi (prima il codice)

    static let schemaIBAN = #"(?i)\bit\s?\d{2}\s?[a-z]\s?(?:\d\s?){10}(?:[0-9a-z]\s?){11}[0-9a-z]\b"#
    static let schemaCodiceFiscale = #"(?i)\b[a-z]{6}\d{2}[a-z]\d{2}[a-z]\d{3}[a-z]\b"#
    static let schemaEmail = #"(?i)\b[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}\b"#
    /// Cellulari e fissi italiani, con o senza +39.
    static let schemaTelefono = #"(?:\+39[\s.\-]?)?\b(?:3\d{2}[\s.\-]?\d{3}[\s.\-]?\d{3,4}|0\d{1,3}[\s.\-]?\d{5,8})\b"#
    /// Numeri di documenti, polizze, conti: 8 cifre o più di fila (anche con i trattini). Gli importi con i punti restano.
    static let schemaNumeroLungo = #"\b\d{8,}\b|\b\d+(?:-\d+){1,}\b"#
    /// «via Manzoni 12, Monza»: la parola della via senza maiuscole obbligate, il nome e il civico, la città se c'è.
    static let schemaIndirizzo = #"(?i:\b(?:via|viale|piazza|piazzale|corso|largo|vicolo|strada|contrada|borgo)\b)\s+(?:[\p{L}'’.]+\s+){1,4}?\d+[a-zA-Z]?(?:\s*,\s*\p{Lu}[\p{L}'’]+(?:\s+\p{Lu}[\p{L}'’]+)?)?"#

    // MARK: - Anonimizzazione

    static func anonimizza(_ testo: String, identificativi: IdentificativiClienti) -> (testo: String, sostituzioni: [Sostituzione]) {
        var t = testo
        var s: [Sostituzione] = []
        sostituisci(schemaIBAN, in: &t, con: iban, &s)
        sostituisci(schemaCodiceFiscale, in: &t, con: codiceFiscale, &s)
        sostituisci(schemaEmail, in: &t, con: email, &s)
        sostituisci(schemaTelefono, in: &t, con: telefono, &s, solo: { $0.filter(\.isNumber).count >= 8 })
        // Una data scritta all'inglese («2026-11-08») non è un numero di documento
        sostituisci(schemaNumeroLungo, in: &t, con: numero, &s, solo: { $0.filter(\.isNumber).count >= 8 && $0.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) == nil })
        // Gli indirizzi esatti dei clienti prima dello schema generico
        for f in identificativi.frasi where f.segnaposto == indirizzo { sostituisciFrase(f.testo, in: &t, con: indirizzo, &s) }
        sostituisci(schemaIndirizzo, in: &t, con: indirizzo, &s)
        for d in identificativi.date { sostituisciFrase(d, in: &t, con: data, &s) }
        // Nomi interi (i più lunghi prima), poi le parole da sole
        for f in identificativi.frasi where f.segnaposto != indirizzo { sostituisciFrase(f.testo, in: &t, con: f.segnaposto, &s) }
        sostituisciParole(in: &t, identificativi.parole, &s)
        return (t, s)
    }

    static func anonimizza(_ e: EsempioVera, identificativi: IdentificativiClienti) -> EsempioAnonimo {
        let d = anonimizza(e.domanda, identificativi: identificativi)
        let r = anonimizza(e.risposta, identificativi: identificativi)
        var visti = Set<String>()
        let sostituzioni = (d.sostituzioni + r.sostituzioni).filter { visti.insert($0.originale.lowercased()).inserted }
        let guardare = Array(Set(possibiliNomi(d.testo) + possibiliNomi(r.testo))).sorted()
        return EsempioAnonimo(id: e.id, domanda: d.testo, risposta: r.testo, modalita: e.modalita ?? .lavoro,
                              sostituzioni: sostituzioni, daGuardare: guardare,
                              residui: residui(d.testo + "\n" + r.testo, identificativi: identificativi))
    }

    /// Ciò che resta di identificabile dopo l'anonimizzazione (vuoto = pulito).
    static func residui(_ testo: String, identificativi: IdentificativiClienti) -> [String] {
        // I segnaposti non contano («[IBAN]» non è un IBAN)
        let senza = testo.replacingOccurrences(of: #"\[[^\]]{1,24}\]"#, with: " ", options: .regularExpression)
        var r = identificativi.trovati(senza)
        if let motivo = MemoriaVera.vietato(senza) { r.append(motivo) }
        if !intervalli(schema: schemaEmail, in: senza).isEmpty { r.append("un indirizzo email") }
        if !intervalli(schema: schemaCodiceFiscale, in: senza).isEmpty { r.append("un codice fiscale") }
        return r
    }

    /// Parole che non fanno pensare a un nome anche se maiuscole (istituzioni, prodotti, mesi, giorni).
    static let nonNomi: Set<String> = ["alleanza", "assicurazioni", "prisma", "vera", "qwen", "ollama", "fondo", "fondi", "gestione",
                                       "separata", "euro", "italia", "inps", "covip", "consob", "ivass", "bce", "eurostat", "banca",
                                       "gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre",
                                       "ottobre", "novembre", "dicembre", "lunedi", "martedi", "mercoledi", "giovedi", "venerdi",
                                       "sabato", "domenica", "piano", "individuale", "pensionistico", "orizzonte", "valore"]

    /// Due parole maiuscole di fila non a inizio frase: forse un nome che l'archivio non conosce.
    static func possibiliNomi(_ testo: String) -> [String] {
        let ns = testo as NSString
        guard let re = try? NSRegularExpression(pattern: #"\b\p{Lu}\p{Ll}{1,}\s+\p{Lu}\p{Ll}{1,}\b"#) else { return [] }
        var r: [String] = []
        for m in re.matches(in: testo, range: NSRange(location: 0, length: ns.length)) {
            let trovato = ns.substring(with: m.range)
            if trovato.split(separator: " ").contains(where: { nonNomi.contains(NucleoVera.semplice(String($0))) }) { continue }
            // A inizio frase la maiuscola non dice niente
            let prima = ns.substring(to: m.range.location).trimmingCharacters(in: .whitespaces)
            if prima.isEmpty || ".!?:\n«\"".contains(prima.last ?? ".") { continue }
            r.append(trovato.split(whereSeparator: \.isWhitespace).joined(separator: " "))
        }
        return r
    }

    // MARK: - Aiuti

    /// Gli intervalli di una frase nel testo, come parola intera (senza maiuscole né accenti).
    static func intervalli(di frase: String, in testo: String) -> [Range<String.Index>] {
        var r: [Range<String.Index>] = []
        var da = testo.startIndex
        while da < testo.endIndex,
              let x = testo.range(of: frase, options: [.caseInsensitive, .diacriticInsensitive], range: da..<testo.endIndex) {
            let primaOk = x.lowerBound == testo.startIndex || !testo[testo.index(before: x.lowerBound)].isLetter
            let dopoOk = x.upperBound == testo.endIndex || !(testo[x.upperBound].isLetter || testo[x.upperBound].isNumber)
            if primaOk && dopoOk { r.append(x) }
            da = x.upperBound
        }
        return r
    }

    static func intervalli(schema: String, in testo: String) -> [NSRange] {
        guard let re = try? NSRegularExpression(pattern: schema) else { return [] }
        return re.matches(in: testo, range: NSRange(location: 0, length: (testo as NSString).length)).map(\.range)
    }

    private static func registra(_ originale: String, _ segnaposto: String, _ s: inout [Sostituzione]) {
        if !s.contains(where: { $0.originale.caseInsensitiveCompare(originale) == .orderedSame }) {
            s.append(Sostituzione(originale: originale, segnaposto: segnaposto))
        }
    }

    private static func sostituisci(_ schema: String, in t: inout String, con segnaposto: String, _ s: inout [Sostituzione],
                                    solo: (String) -> Bool = { _ in true }) {
        let ns = t as NSString
        var nuovo = t as NSString
        for r in intervalli(schema: schema, in: t).reversed() {
            let originale = ns.substring(with: r)
            guard solo(originale), !originale.contains("[") else { continue }
            registra(originale, segnaposto, &s)
            nuovo = nuovo.replacingCharacters(in: r, with: segnaposto) as NSString
        }
        t = nuovo as String
    }

    private static func sostituisciFrase(_ frase: String, in t: inout String, con segnaposto: String, _ s: inout [Sostituzione]) {
        for r in intervalli(di: frase, in: t).reversed() {
            registra(String(t[r]), segnaposto, &s)
            t.replaceSubrange(r, with: segnaposto)
        }
    }

    private static func sostituisciParole(in t: inout String, _ parole: [String: String], _ s: inout [Sostituzione]) {
        guard !parole.isEmpty, let re = try? NSRegularExpression(pattern: #"\p{L}+"#) else { return }
        var nuovo = t as NSString
        let ns = t as NSString
        for m in re.matches(in: t, range: NSRange(location: 0, length: ns.length)).reversed() {
            let parola = ns.substring(with: m.range)
            // Dentro un segnaposto («[Cliente]») non si tocca niente
            if m.range.location > 0, ns.substring(with: NSRange(location: m.range.location - 1, length: 1)) == "[" { continue }
            guard parola.count >= 3, let segnaposto = parole[NucleoVera.semplice(parola)] else { continue }
            registra(parola, segnaposto, &s)
            nuovo = nuovo.replacingCharacters(in: m.range, with: segnaposto) as NSString
        }
        t = nuovo as String
    }
}
