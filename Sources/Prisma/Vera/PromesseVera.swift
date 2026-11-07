import Foundation

// «Le promesse» (Vera/BRIEF.md, funzione 8; template «Le promesse»): gli impegni che il consulente prende con i clienti,
// trovati nelle note, negli incontri, nei resoconti e nei messaggi che ha mandato. Prima il codice: le regole cercano le
// frasi in prima persona con un verbo d'impegno («le mando…», «la richiamo…», «porto io…») e ne leggono il quando con
// DateItaliane. Qwen (se è pronto) riscrive il «cosa fare» e trova le frasi che le regole non vedono, in JSON con uno
// schema fisso: una promessa vale solo se la sua frase si ritrova parola per parola nella fonte. Vera non inventa promesse.

/// Un testo in cui cercare promesse.
struct FontePromesse {
    var clienteId: String
    var tipo: PromessaCliente.Fonte
    var id: String
    var etichetta: String
    var data: Date
    var testo: String
}

enum PromesseVera {
    /// I verbi d'impegno in prima persona (al presente con il pronome del cliente, o al futuro).
    static let impegni = #"\b(?:le|ti|gli|vi) (?:mando|invio|porto|preparo|faccio sapere|faccio avere|scrivo|giro|confermo|spedisco|telefono|chiamo|propongo|organizzo|fisso|verifico|controllo|aggiorno|richiamo)\b|\b(?:la|lo|ti|vi|li|le) (?:richiamo|chiamo|ricontatto|risento|aggiorno|sento)\b|\b(?:mando|porto|preparo|verifico|controllo|organizzo|fisso|chiamo|scrivo) io\b|\bmi impegno a\b|\b(?:manderò|invierò|porterò|preparerò|richiamerò|chiamerò|scriverò|verificherò|controllerò|organizzerò|farò avere|farò sapere|ricontatterò|aggiornerò)\b|\bci sentiamo (?:entro|dopo|il|la|lunedì|martedì|mercoledì|giovedì|venerdì|domani)"#

    // MARK: - Frasi e quando

    static func frasi(_ testo: String) -> [String] {
        var risultato: [String] = []
        testo.enumerateSubstrings(in: testo.startIndex..., options: [.bySentences, .localized]) { s, _, _, _ in
            if let s { risultato.append(s.trimmingCharacters(in: .whitespacesAndNewlines)) }
        }
        return risultato.flatMap { $0.components(separatedBy: "\n") }.map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.count >= 8 }
    }

    /// Il quando della frase e la sua data, a partire dal giorno della fonte («entro venerdì 6», «dopo il 15»).
    static func quando(_ frase: String, dal giorno: Date) -> (testo: String?, data: Date?) {
        let t = frase.lowercased()
        let cal = Calendar.current
        if let (r, g) = DateItaliane.cerca(#"\bdopo il (\d{1,2})\b(?! (?:gennaio|febbraio|marzo|aprile|maggio|giugno|luglio|agosto|settembre|ottobre|novembre|dicembre))"#, t),
           let n = Int(g[1]), (1...31).contains(n) {
            var c = DateComponents(day: n)
            c.hour = 12
            let d = cal.nextDate(after: dal(giorno, -1), matching: c, matchingPolicy: .nextTime)
            return ((t as NSString).substring(with: r), d.flatMap { cal.date(byAdding: .day, value: 1, to: $0) })
        }
        let trovato = DateItaliane.trova(frase, oggi: giorno)
        guard let g = trovato.giorno else { return (nil, nil) }
        let parti = trovato.parti.map { (t as NSString).substring(with: $0).trimmingCharacters(in: .whitespaces) }
        var prima = ""
        if let p = trovato.parti.first, p.location > 0,
           let (_, gg) = DateItaliane.cerca(#"\b(entro|per|prima di|non oltre)\s*$"#, (t as NSString).substring(to: p.location)) {
            prima = gg[1] + " "
        }
        return (prima + parti.joined(separator: " "), g)
    }

    private static func dal(_ d: Date, _ giorni: Int) -> Date { Calendar.current.date(byAdding: .day, value: giorni, to: d) ?? d }

    // MARK: - Dalla frase al «cosa fare»

    private static let verbi: [(String, String)] = [
        ("mando", "Mandare"), ("invio", "Mandare"), ("spedisco", "Mandare"), ("giro", "Girare"), ("porto", "Portare"),
        ("preparo", "Preparare"), ("faccio sapere", "Far sapere"), ("faccio avere", "Far avere"), ("scrivo", "Scrivere"),
        ("confermo", "Confermare"), ("telefono", "Telefonare"), ("chiamo", "Chiamare"), ("richiamo", "Richiamare"),
        ("ricontatto", "Ricontattare"), ("risento", "Risentire"), ("sento", "Sentire"), ("propongo", "Proporre"),
        ("organizzo", "Organizzare"), ("fisso", "Fissare"), ("verifico", "Verificare"), ("controllo", "Controllare"),
        ("aggiorno", "Aggiornare"), ("manderò", "Mandare"), ("invierò", "Mandare"), ("porterò", "Portare"),
        ("preparerò", "Preparare"), ("richiamerò", "Richiamare"), ("chiamerò", "Chiamare"), ("scriverò", "Scrivere"),
        ("verificherò", "Verificare"), ("controllerò", "Controllare"), ("organizzerò", "Organizzare"),
        ("farò avere", "Far avere"), ("farò sapere", "Far sapere"), ("ricontatterò", "Ricontattare"), ("aggiornerò", "Aggiornare"),
    ]

    /// «Le mando il confronto per gli studi di Tommaso entro venerdì 6» → «Mandare a Marco il confronto per gli studi di
    /// Tommaso». Le regole cambiano solo il verbo e tolgono il quando: il resto sono le parole della frase.
    static func cosaFare(_ frase: String, nome: String, giorno: Date) -> String {
        var t = frase.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,;:!")))
        let trovato = DateItaliane.trova(t, oggi: giorno)
        t = DateItaliane.togli(trovato, da: t)
        t = t.replacingOccurrences(of: #"\s*\b(entro|per|prima di|non oltre|dopo il \d{1,2})\s*$"#, with: "", options: [.regularExpression, .caseInsensitive])
        // Le spiegazioni dopo la virgola («, così lo guarda anche Elena») non sono la cosa da fare
        t = t.replacingOccurrences(of: #"\s*,\s*(?:così|cosi|perché|in modo|dato che|visto che)\b.*$"#, with: "", options: [.regularExpression, .caseInsensitive])
        t = t.replacingOccurrences(of: #"\s+([,;.])"#, with: "$1", options: .regularExpression)
        t = t.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ",;")))
        let minuscolo = t.lowercased()
        for (verbo, infinito) in verbi {
            guard let r = DateItaliane.cerca(#"\b(?:(?:le|ti|gli|vi|la|lo|li) )?"# + NSRegularExpression.escapedPattern(for: verbo) + #"(?: io)?\b"#, minuscolo) else { continue }
            let dopo = (t as NSString).substring(from: r.0.location + r.0.length).trimmingCharacters(in: .whitespaces)
            let persona = ["richiamo", "chiamo", "ricontatto", "risento", "sento", "telefono", "richiamerò", "chiamerò", "ricontatterò"].contains(verbo)
                ? " \(nome)" : (["aggiorno", "aggiornerò"].contains(verbo) ? " \(nome)" : " a \(nome)")
            let resto = dopo.replacingOccurrences(of: #"^(io|a lei|a te)\b\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
            return (infinito + persona + (resto.isEmpty ? "" : " " + resto)).replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        }
        return t.prefix(1).uppercased() + t.dropFirst()
    }

    // MARK: - Le regole

    static func conRegole(_ f: FontePromesse, nome: String) -> [PromessaCliente] {
        frasi(f.testo).compactMap { frase -> PromessaCliente? in
            let minuscola = frase.lowercased()
            guard DateItaliane.cerca(impegni, minuscola) != nil,
                  // Le promesse di rendimento non sono impegni: sono vietate (MessaggiVera.promesse)
                  DateItaliane.cerca(MessaggiVera.promesse, minuscola) == nil else { return nil }
            let q = quando(frase, dal: f.data)
            return PromessaCliente(clienteId: f.clienteId, testo: cosaFare(frase, nome: nome, giorno: f.data), frase: frase, fonte: f.tipo,
                                   fonteId: f.id, fonteEtichetta: f.etichetta, scadenza: q.data, quando: q.testo)
        }
    }

    /// Le fonti di un cliente: note, incontri (appunti e decisioni, il resoconto se c'è) e messaggi aperti in Mail o in
    /// Messaggi (quelli che sono usciti davvero).
    static func fonti(cliente: String, note: [Nota], incontri: [Incontro], messaggi: [MessaggioCliente]) -> [FontePromesse] {
        var f: [FontePromesse] = []
        for n in note where n.clienteId == cliente && !n.vuota {
            let d = n.aggiornataIl
            f.append(FontePromesse(clienteId: cliente, tipo: .nota, id: n.id, etichetta: "dalla nota del \(Formati.giornoMese.string(from: d))", data: d,
                                   testo: n.titolo + "\n" + n.testo))
        }
        // Gli incontri avvenuti (o conclusi): gli appunti di uno in preparazione sono una scaletta, non impegni presi
        for i in incontri where i.clienteId == cliente && (i.stato == .concluso || i.data <= Date()) {
            let testo = [i.appunti, i.decisioni, i.prossimaAttivita].filter { !$0.isEmpty }.joined(separator: "\n")
            if !testo.isEmpty {
                f.append(FontePromesse(clienteId: cliente, tipo: .incontro, id: i.id, etichetta: "dall'incontro del \(Formati.giornoMese.string(from: i.data))",
                                       data: i.data, testo: testo))
            }
            if let r = i.resoconto {
                f.append(FontePromesse(clienteId: cliente, tipo: .resoconto, id: i.id + "-resoconto",
                                       etichetta: "dal resoconto del \(Formati.giornoMese.string(from: i.data))", data: i.data,
                                       testo: r.sezioni.flatMap(\.righe).joined(separator: "\n")))
            }
        }
        for m in messaggi where m.clienteId == cliente && (m.stato == .apertoInMail || m.stato == .apertoInMessaggi) {
            let d = m.apertoIl ?? m.creatoIl
            f.append(FontePromesse(clienteId: cliente, tipo: .messaggio, id: m.id, etichetta: "dal messaggio del \(Formati.giornoMese.string(from: d))",
                                   data: d, testo: m.testo))
        }
        return f
    }

    /// Le promesse nuove: quelle già nell'elenco (anche scartate) con la stessa frase e la stessa fonte non tornano.
    static func nuove(_ trovate: [PromessaCliente], esistenti: [PromessaCliente]) -> [PromessaCliente] {
        let gia = Set(esistenti.map { chiave($0) })
        var viste: Set<String> = []
        return trovate.filter { p in
            let k = chiave(p)
            guard !gia.contains(k), !viste.contains(k) else { return false }
            viste.insert(k)
            return true
        }
    }

    /// La stessa frase dello stesso cliente è una promessa sola, da qualunque fonte arrivi (gli appunti di un incontro
    /// ritornano parola per parola nel suo resoconto): una promessa fatta o tolta non ricompare.
    /// Un incontro e il suo resoconto sono la stessa fonte (gli appunti ritornano parola per parola nel resoconto).
    static func chiave(_ p: PromessaCliente) -> String {
        let fonte = p.fonteId.hasSuffix("-resoconto") ? String(p.fonteId.dropLast("-resoconto".count)) : p.fonteId
        return p.clienteId + "|" + fonte + "|" + normale(p.frase)
    }

    static func normale(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
            .split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
    }

    // MARK: - Qwen (JSON, la frase sempre nella fonte)

    static let schema: [String: Any] = {
        let voce: [String: Any] = ["type": "object", "required": ["frase", "cosa"],
                                   "properties": ["frase": ["type": "string"], "cosa": ["type": "string"], "quando": ["type": "string"]] as [String: Any]]
        return ["type": "object", "properties": ["promesse": ["type": "array", "items": voce]], "required": ["promesse"]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("promesse") ?? "Trova nel testo gli impegni che il consulente ha preso con il cliente (cose che ha detto di fare lui). Rispondi solo con il JSON: promesse, ognuna con frase (copiata parola per parola dal testo), cosa (all'infinito, breve) e quando (come nel testo, se c'è). Niente promesse di rendimento, niente cose che deve fare il cliente. Se non ce ne sono, promesse vuoto."
    }

    static func messaggi(_ f: FontePromesse, nome: String) -> [MessaggioModello] {
        [MessaggioModello(ruolo: .sistema, testo: istruzioni),
         MessaggioModello(ruolo: .utente, testo: "CLIENTE: \(nome)\nTESTO (\(f.etichetta))\n\(f.testo)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.contesto = NucleoVera.finestra
        o.massimoToken = 600
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    /// Le promesse di Qwen che passano il controllo: la frase sta nella fonte e dice un impegno (o un quando).
    static func leggi(_ json: String, fonte f: FontePromesse) -> [PromessaCliente]? {
        guard let i = json.firstIndex(of: "{"), let fine = json.lastIndex(of: "}"), i < fine,
              let d = String(json[i...fine]).data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let elenco = j["promesse"] as? [[String: Any]] else { return nil }
        let fonte = normale(f.testo)
        return elenco.compactMap { v in
            guard let frase = (v["frase"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), frase.count >= 8,
                  let cosa = (v["cosa"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !cosa.isEmpty,
                  fonte.contains(normale(frase)), DateItaliane.cerca(MessaggiVera.promesse, frase.lowercased()) == nil,
                  // Un impegno in prima persona, come per le regole; e nel «cosa» nessuna cifra che non sia nella frase
                  DateItaliane.cerca(impegni, frase.lowercased()) != nil,
                  CommentoVera.numeriConservati(bozza: frase, testo: cosa) else { return nil }
            // La frase intera del testo che contiene quella di Qwen: lo stesso impegno delle regole non entra due volte
            let intera = frasi(f.testo).first { normale($0).contains(normale(frase)) } ?? frase
            let q = quando(intera, dal: f.data)
            // Il «quando» di Qwen vale solo se è scritto nella frase
            let qq = (v["quando"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let quandoQwen = qq.flatMap { !$0.isEmpty && normale(intera).contains(normale($0)) ? $0 : nil }
            return PromessaCliente(clienteId: f.clienteId, testo: cosa.prefix(1).uppercased() + cosa.dropFirst(), frase: intera, fonte: f.tipo,
                                   fonteId: f.id, fonteEtichetta: f.etichetta, scadenza: q.data, quando: q.testo ?? quandoQwen)
        }
    }

    // MARK: - Lo stato di una promessa

    enum Semaforo { case inRitardo, presto, inTempo, senzaData }

    static func semaforo(_ p: PromessaCliente, oggi: Date) -> Semaforo {
        guard let s = p.scadenzaAttuale else { return .senzaData }
        let giorno = Calendar.current.startOfDay(for: oggi)
        if s < giorno { return .inRitardo }
        let giorni = Calendar.current.dateComponents([.day], from: giorno, to: Calendar.current.startOfDay(for: s)).day ?? 0
        return giorni <= 7 ? .presto : .inTempo
    }

    static func etichetta(_ p: PromessaCliente, oggi: Date) -> String {
        guard let s = p.scadenzaAttuale else { return "Senza data" }
        let giorno = Calendar.current.startOfDay(for: oggi)
        let giorni = Calendar.current.dateComponents([.day], from: giorno, to: Calendar.current.startOfDay(for: s)).day ?? 0
        switch semaforo(p, oggi: oggi) {
        case .inRitardo: return "In ritardo"
        case .presto: return giorni == 0 ? "Oggi" : (giorni == 1 ? "Domani" : "Fra \(giorni) giorni")
        case .inTempo: return "In tempo"
        case .senzaData: return "Senza data"
        }
    }
}
