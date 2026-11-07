import Foundation

// Gli scenari «E se…?» di Vera: «e se Marco va in pensione a 63 anni e smette di versare?».
// 1. L'app riconosce che la frase sembra uno scenario (regole sulle parole, `sembraScenario`).
// 2. Qwen estrae i parametri in uno schema JSON fisso (Vera/Istruzioni/scenari.md, Vera/Schemi/scenario.json,
//    passato a Ollama nel campo «format»); le regole dell'app leggono le stesse cifre dalla frase e, dove le
//    trovano, vincono (un numero scritto nella frase non si sbaglia).
// 3. Se manca un dato indispensabile Vera fa una domanda breve e la frase dopo completa lo scenario.
// 4. I numeri li calcola Prisma (MotoreScenari, con le ipotesi del cliente), mai Qwen: Qwen racconta la scheda
//    prima/dopo con le sole cifre di Prisma; se ne cambia una, resta il testo di Prisma.

/// L'area dell'analisi che uno scenario cambia.
enum AreaScenarioVera: String, Codable, CaseIterable {
    case previdenza, investimenti, risparmio, protezione

    var nome: String {
        switch self {
        case .previdenza: return "Previdenza"
        case .investimenti: return "Investimenti"
        case .risparmio: return "Risparmio"
        case .protezione: return "Protezione"
        }
    }

    /// L'area di Analisi 360 con le stesse ipotesi.
    var areaAnalisi: AreaAnalisi {
        switch self {
        case .previdenza: return .previdenza
        case .investimenti: return .investimenti
        case .risparmio: return .risparmio
        case .protezione: return .protezione
        }
    }
}

/// I parametri di uno scenario, come li vogliono i motori di Prisma (lo schema di Vera/Schemi/scenario.json,
/// con il cliente già riconosciuto).
struct ParametriScenarioVera: Codable, Equatable {
    var clienteId: String?
    var area: AreaScenarioVera?
    /// Età a cui il cliente va in pensione nello scenario.
    var etaPensione: Int?
    /// Il nuovo versamento al mese, in euro.
    var versamentoMensile: Double?
    /// Di quanto cambia il versamento al mese (se la frase non dice il nuovo valore).
    var variazioneVersamento: Double?
    var smetteDiVersare = false
    /// Capitale in più (positivo) o in meno (negativo); in protezione il capitale caso morte.
    var capitale: Double?
    /// Rendimento annuo in percentuale.
    var rendimento: Double?
    /// Anni dell'orizzonte; in protezione gli anni di sostegno.
    var durata: Int?
    /// I dati indispensabili che Qwen ha detto mancanti ("cliente", "area", "cambiamento").
    var mancanti: [String] = []
    /// La frase da cui nasce lo scenario (con la domanda di Vera e la risposta, se Vera ha chiesto qualcosa).
    var frase = ""
    /// Il cliente è nominato nella frase (non è solo quello aperto). Non si salva.
    var clienteNominato = false

    init() {}

    private enum CodingKeys: String, CodingKey {
        case clienteId, area, etaPensione, versamentoMensile, variazioneVersamento, smetteDiVersare, capitale, rendimento, durata, mancanti, frase
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        clienteId = try c.decodeIfPresent(String.self, forKey: .clienteId)
        area = try? c.decodeIfPresent(AreaScenarioVera.self, forKey: .area)
        etaPensione = try c.decodeIfPresent(Int.self, forKey: .etaPensione)
        versamentoMensile = try c.decodeIfPresent(Double.self, forKey: .versamentoMensile)
        variazioneVersamento = try c.decodeIfPresent(Double.self, forKey: .variazioneVersamento)
        smetteDiVersare = try c.decodeIfPresent(Bool.self, forKey: .smetteDiVersare) ?? false
        capitale = try c.decodeIfPresent(Double.self, forKey: .capitale)
        rendimento = try c.decodeIfPresent(Double.self, forKey: .rendimento)
        durata = try c.decodeIfPresent(Int.self, forKey: .durata)
        mancanti = try c.decodeIfPresent([String].self, forKey: .mancanti) ?? []
        frase = try c.decodeIfPresent(String.self, forKey: .frase) ?? ""
    }

    /// Lo scenario cambia almeno una cosa.
    var cambia: Bool {
        etaPensione != nil || versamentoMensile != nil || variazioneVersamento != nil || smetteDiVersare
            || capitale != nil || rendimento != nil || durata != nil
    }

    /// Uguali in tutto quello che si salva (`clienteNominato` serve solo mentre Vera legge la frase).
    static func == (a: ParametriScenarioVera, b: ParametriScenarioVera) -> Bool {
        a.stessi(b) && a.mancanti == b.mancanti && a.frase == b.frase
    }

    /// Stessi parametri (senza frase e mancanti): per le prove.
    func stessi(_ o: ParametriScenarioVera) -> Bool {
        clienteId == o.clienteId && area == o.area && etaPensione == o.etaPensione && versamentoMensile == o.versamentoMensile
            && variazioneVersamento == o.variazioneVersamento && smetteDiVersare == o.smetteDiVersare && capitale == o.capitale
            && rendimento == o.rendimento && durata == o.durata
    }

    /// Una descrizione compatta («area previdenza, pensione a 63 anni, smette di versare»), per le prove.
    var descrizione: String {
        var p = ["cliente \(clienteId ?? "-")", "area \(area?.rawValue ?? "-")"]
        if let e = etaPensione { p.append("pensione a \(e)") }
        if let v = versamentoMensile { p.append("versamento \(v)") }
        if let v = variazioneVersamento { p.append("variazione \(v)") }
        if smetteDiVersare { p.append("smette") }
        if let c = capitale { p.append("capitale \(c)") }
        if let r = rendimento { p.append("rendimento \(r)") }
        if let d = durata { p.append("durata \(d)") }
        return p.joined(separator: ", ")
    }
}

enum ScenariVera {
    /// Etichetta delle risposte in cui le cifre sono di Prisma (testo di Prisma, senza Qwen).
    static let motorePrisma = "Calcoli di Prisma"

    // MARK: - Riconoscimento

    /// Le parole che aprono uno scenario: «e se…», «cosa succede se…», «ipotizziamo…», «scenario».
    static let apertura = #"(^|[\s,;:(«"])e se\b|^se\b|\b(cosa|che cosa|che) succede(rebbe)? se\b|\b(cosa|come) cambi(a|erebbe)? se\b|\bscenari[oi]\b|\bipotizziamo\b|\bsupponiamo\b|\bimmagin(a|iamo)(mo)? che\b|\bmettiamo (il caso )?che\b|\bnel caso in cui\b|^simula(mi)?\b|\bfacciamo (finta|conto) che\b"#

    /// Le parole che dicono cosa cambia: senza nessuna, «e se possibile scrivila breve» non è uno scenario.
    static let materia = #"pension|previdenz|\bvers|\bcapital|\brend|\bdurat|\bann[oi]\b|copertur|investi|risparm|accumul|eredit|ritir|riscatt|\bmett|aggiung|smett|anticip|posticip|€|\beuro\b|\d"#

    /// true se la frase sembra uno scenario «E se…?»: le parole d'apertura e almeno una cosa che cambia.
    /// Gli spunti pronti («Cosa succede se i mercati crollano?») restano spunti.
    static func sembraScenario(_ frase: String) -> Bool {
        guard SpuntoVera.da(frase) == nil else { return false }
        let t = semplice(frase)
        return DateItaliane.cerca(apertura, t) != nil && DateItaliane.cerca(materia, t) != nil
    }

    /// Minuscole, senza accenti, apostrofi dritti, cifre in lettere davanti ad «anni» («due anni» → «2 anni»).
    static func semplice(_ frase: String) -> String {
        var t = NucleoVera.semplice(frase).lowercased()
        t = t.replacingOccurrences(of: "\u{00A0}", with: " ")
        for (parola, n) in numeriInLettere {
            t = t.replacingOccurrences(of: "\\b\(parola) (ann[oi])\\b", with: "\(n) $1", options: .regularExpression)
        }
        return t
    }

    static let numeriInLettere: [(String, Int)] = [
        ("un", 1), ("uno", 1), ("due", 2), ("tre", 3), ("quattro", 4), ("cinque", 5), ("sei", 6), ("sette", 7), ("otto", 8),
        ("nove", 9), ("dieci", 10), ("undici", 11), ("dodici", 12), ("quindici", 15), ("venti", 20), ("venticinque", 25), ("trenta", 30),
    ]

    // MARK: - Le regole dell'app

    /// I parametri che le regole leggono nella frase. `etaPensioneAttuale` dà l'età di pensione dell'Analisi 360 di
    /// un cliente (per «anticipa la pensione di due anni»).
    static func regole(_ frase: String, clienti: [ClienteNoto], attivo: String?,
                       etaPensioneAttuale: (String) -> Int? = { _ in nil }) -> ParametriScenarioVera {
        var p = ParametriScenarioVera()
        p.frase = frase
        var t = semplice(frase)
        let nominati = InterpreteComandi.clientiNominati(t, clienti)
        p.clienteId = nominati.count == 1 ? nominati[0].id : (nominati.isEmpty ? attivo : nil)
        p.clienteNominato = nominati.count == 1

        // Il versamento al mese, prima del capitale: «versa 400 € al mese» non è un capitale
        let importo = #"(?:€\s*)?(\d[\d.,]*)(?![\d.,])\s*(mila|k|milion[ei])?\s*(?:€|euro)?"#
        let alMese = #"(?:al mese|ogni mese|mensil[ei]|a rata)"#
        if let g = consuma(importo + #"\s*(in piu|in meno)\s*"# + alMese, &t) {
            p.variazioneVersamento = euro(g[1], g[2]).map { g[3] == "in meno" ? -$0 : $0 }
        } else if let g = consuma(#"\b(aument|alz|ridu|diminu|abbass|tagli)\w*\s+(?:il |i |del |dei )?versament\w*(?:\s+mensil\w*)?\s+di\s+"# + importo, &t) {
            let meno = ["ridu", "diminu", "abbass", "tagli"].contains(g[1])
            p.variazioneVersamento = euro(g[2], g[3]).map { meno ? -$0 : $0 }
        } else if let g = consuma(importo + #"\s*"# + alMese, &t) {
            p.versamentoMensile = euro(g[1], g[2])
        } else if let g = consuma(#"\bversament\w*(?:\s+mensil\w*)?\s+(?:a|di|da)\s+"# + importo + #"(?!\s*ann)"#, &t) {
            p.versamentoMensile = euro(g[1], g[2])
        }
        if consuma(#"\bsmett\w* di (?:versare|pagare|contribuire|mettere)|\bnon vers\w* piu\b|\b(?:ferm|sospend|interromp|azzer|bloc)\w* (?:i |il )?versament\w*|\bsenza (?:piu )?versament\w*|\bversament\w* (?:fermi|sospesi|a zero)"#, &t) != nil {
            p.smetteDiVersare = true
            p.versamentoMensile = nil
            p.variazioneVersamento = nil
        }

        // L'età della pensione: «va in pensione a 63 anni», «a 63 anni in pensione», «anticipa di due anni»
        if let g = consumaUno([#"pension\w*[^.?!\d]{0,40}?\ba (\d{2}) anni\b"#, #"\ba (\d{2}) anni[^.?!\d]{0,30}?pension"#,
                               #"\b(?:smett\w* di lavorare|lasci\w* il lavoro|esc\w* dal lavoro|usci\w* dal lavoro|si ritir\w*)[^.?!\d]{0,20}?\ba (\d{2}) anni\b"#], &t) {
            p.etaPensione = Int(g[1])
        } else if let g = consumaUno([#"\b(anticip|posticip|ritard|rimand)\w*(?: la)? pensione di (\d{1,2}) ann[oi]\b"#,
                                      #"\b(anticip|posticip|ritard|rimand)\w* di (\d{1,2}) ann[oi]\b(?=[^.?!]*pension)"#], &t) {
            let anticipa = g[1] == "anticip"
            if let n = Int(g[2]), let id = p.clienteId, let attuale = etaPensioneAttuale(id) { p.etaPensione = attuale + (anticipa ? -n : n) }
        } else if DateItaliane.cerca("pension", t) != nil, let g = consuma(#"\b(\d{1,2}) ann[oi] (prima|dopo)\b"#, &t) {
            if let n = Int(g[1]), let id = p.clienteId, let attuale = etaPensioneAttuale(id) { p.etaPensione = attuale + (g[2] == "prima" ? -n : n) }
        }

        // Il rendimento: «al 2%», «rendesse il 3,5% l'anno»
        if let g = consumaUno([#"\brend\w*[^.?!\d]{0,40}?(-?\d+(?:[.,]\d+)?)\s*(?:%|per ?cento)"#,
                               #"(-?\d+(?:[.,]\d+)?)\s*(?:%|per ?cento)\s*(?:l'anno|annu\w*|all'anno|di rendimento)"#,
                               #"\bal (\d+(?:[.,]\d+)?)\s*(?:%|per ?cento)"#], &t) {
            p.rendimento = Double(g[1].replacingOccurrences(of: ",", with: "."))
        }

        // La durata: «per 10 anni», «tra 15 anni», «10 anni di sostegno»
        if let g = consumaUno([#"\b(?:per|tra|fra|in|durata di|orizzonte di)\s+(\d{1,2})\s+ann[oi]\b"#, #"\b(\d{1,2})\s+ann[oi] di sostegno\b"#], &t) {
            p.durata = Int(g[1])
        }

        // Il capitale in più o in meno: «mette altri 20.000 €», «ritira 10.000 €», «aumenta la copertura di 100.000 €»
        let soldi = #"\s+(?:€\s*)?(\d[\d.,]*)(?![\d.,])\s*(mila|k|milion[ei])?\s*(?:€|euro)"#
        let verbiPiu = #"\b(mett|vers|aggiung|invest|ricev|eredit|incass|arriv|entr|aument|alz|destin|port|premio)\w*\b(?:\s+[^\s\d]+){0,6}?"#
        let verbiMeno = #"\b(ritir|prelev|riscatt|togl|spend|us|perd|tir|ridu|diminu|abbass|tagli|prend)\w*\b(?:\s+[^\s\d]+){0,6}?"#
        if let g = consuma(verbiMeno + soldi, &t) {
            p.capitale = euro(g[2], g[3]).map { -$0 }
        } else if let g = consuma(verbiPiu + soldi, &t) {
            p.capitale = euro(g[2], g[3])
        } else if let g = consuma(#"(?:€\s*)?(\d[\d.,]*)(?![\d.,])\s*(mila|k|milion[ei])?\s*(?:€|euro)\s+in (piu|meno)\b"#, &t) {
            p.capitale = euro(g[1], g[2]).map { g[3] == "meno" ? -$0 : $0 }
        }

        p.area = area(semplice(frase), etaPensione: p.etaPensione)
        return p
    }

    /// L'area dalle parole della frase (con l'età di pensione è sempre la previdenza).
    static func area(_ t: String, etaPensione: Int?) -> AreaScenarioVera? {
        if etaPensione != nil { return .previdenza }
        let parole: [(AreaScenarioVera, String)] = [
            (.previdenza, #"pension|previdenz|\bpip\b|\btfr\b"#),
            (.protezione, #"protezion|copertur|caso morte|\btcm\b|sostegno|invalidit|assicurat"#),
            (.risparmio, #"risparm|accumul|obiettiv|\bcasa\b|anticipo|\bstudi|accantona|\bpac\b"#),
            (.investimenti, #"investiment|\binvest|portafogl|mercat|\betf\b|azion|obbligaz"#),
        ]
        return parole.first { DateItaliane.cerca($0.1, t) != nil }?.0
    }

    /// Il primo schema che si trova, tolto dal testo.
    private static func consumaUno(_ schemi: [String], _ t: inout String) -> [String]? {
        for s in schemi {
            if let g = consuma(s, &t) { return g }
        }
        return nil
    }

    /// Trova lo schema nel testo e lo toglie (al suo posto spazi), così le regole dopo non rileggono le stesse cifre.
    private static func consuma(_ schema: String, _ t: inout String) -> [String]? {
        guard let trovato = DateItaliane.cerca(schema, t) else { return nil }
        let (r, g) = trovato
        t = (t as NSString).replacingCharacters(in: r, with: String(repeating: " ", count: r.length))
        return g
    }

    /// «20.000» → 20000, «1.500,50» → 1500,5, «20» + «mila» → 20000.
    static func euro(_ cifra: String, _ moltiplicatore: String = "") -> Double? {
        var s = cifra.trimmingCharacters(in: CharacterSet(charactersIn: ".,"))
        if s.range(of: #"^\d{1,3}(\.\d{3})+(,\d+)?$"#, options: .regularExpression) != nil { s = s.replacingOccurrences(of: ".", with: "") }
        if s.range(of: #"^\d{1,3}(,\d{3})+$"#, options: .regularExpression) != nil { s = s.replacingOccurrences(of: ",", with: "") }
        s = s.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(s) else { return nil }
        switch moltiplicatore {
        case "mila", "k": return v * 1_000
        case let m where m.hasPrefix("milion"): return v * 1_000_000
        default: return v
        }
    }

    // MARK: - Lo schema JSON per Qwen

    /// Lo schema di Vera/Schemi/scenario.json dal pacchetto (in sviluppo e su iOS senza la cartella: quello qui sotto).
    static var schema: [String: Any] {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Schemi/scenario.json"),
           let d = try? Data(contentsOf: url), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] {
            return j
        }
        return schemaInterno
    }

    /// Lo stesso schema, nel codice (la prova controlla che coincida con quello della cartella Vera/Schemi).
    static let schemaInterno: [String: Any] = {
        let aree: [String] = ["previdenza", "investimenti", "risparmio", "protezione", "nessuna"]
        let area: [String: Any] = ["type": "string", "enum": aree]
        let voceMancante: [String: Any] = ["type": "string", "enum": ["cliente", "area", "cambiamento"]]
        let mancanti: [String: Any] = ["type": "array", "items": voceMancante]
        var proprieta: [String: Any] = [:]
        proprieta["scenario"] = ["type": "boolean"]
        proprieta["cliente"] = ["type": "string"]
        proprieta["area"] = area
        proprieta["etaPensione"] = ["type": "integer"]
        proprieta["versamentoMensile"] = ["type": "number"]
        proprieta["variazioneVersamento"] = ["type": "number"]
        proprieta["smetteDiVersare"] = ["type": "boolean"]
        proprieta["capitale"] = ["type": "number"]
        proprieta["rendimento"] = ["type": "number"]
        proprieta["durata"] = ["type": "integer"]
        proprieta["mancanti"] = mancanti
        let richiesti: [String] = ["scenario", "cliente", "area", "smetteDiVersare", "mancanti"]
        return ["type": "object", "properties": proprieta, "required": richiesti]
    }()

    /// Le istruzioni di Vera/Istruzioni/scenari.md (con un ripiego minimo in sviluppo).
    static var istruzioni: String {
        IstruzioniVera.testo("scenari") ?? "Leggi la frase di un consulente finanziario e rispondi solo con un oggetto JSON: scenario (true se chiede cosa succederebbe a un cliente cambiando qualcosa), cliente (come è scritto, \"\" se non c'è), area (previdenza, investimenti, risparmio, protezione o nessuna), e solo se la frase li dice etaPensione, versamentoMensile, variazioneVersamento, smetteDiVersare, capitale (in più positivo, in meno negativo), rendimento (%), durata (anni), mancanti (cliente, area, cambiamento). Importi come numeri senza simboli. Non inventare e non fare conti."
    }

    /// La richiesta di estrazione: le istruzioni fisse, poi il contesto (cliente attivo con la sua età di pensione,
    /// i nomi dei clienti) e la frase.
    static func messaggiEstrazione(frase: String, attivo: Cliente?, etaPensione: Int?, clienti: [ClienteNoto]) -> [MessaggioModello] {
        var contesto = "CONTESTO: "
        if let c = attivo {
            contesto += "cliente attivo: \(c.nome)" + (etaPensione.map { " (età di pensione nell'Analisi 360: \($0) anni)" } ?? "") + "; "
        } else {
            contesto += "nessun cliente attivo; "
        }
        contesto += "clienti: " + clienti.prefix(massimoNomi).map(\.nome).joined(separator: ", ") + "."
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: contesto + "\n\nFRASE DEL CONSULENTE\n" + frase)]
    }

    static let massimoNomi = 80

    /// Estrazione: niente fantasia, niente ragionamento, la stessa finestra delle altre risposte (Ollama non ricarica
    /// il modello) e la risposta vincolata allo schema.
    static func opzioniEstrazione(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.massimoToken = 220
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    /// Il JSON di Qwen: i parametri, con il cliente riconosciuto, e se per Qwen è uno scenario.
    /// Accetta anche un JSON tra altre parole o tra ```; nil se non c'è un oggetto JSON.
    static func leggiJSON(_ testo: String, clienti: [ClienteNoto], attivo: String?) -> (parametri: ParametriScenarioVera, scenario: Bool)? {
        guard let inizio = testo.firstIndex(of: "{"), let fine = testo.lastIndex(of: "}"), inizio < fine,
              let d = String(testo[inizio...fine]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return nil }
        func numero(_ k: String) -> Double? {
            if let n = j[k] as? NSNumber { return CFGetTypeID(n) == CFBooleanGetTypeID() ? nil : n.doubleValue }
            if let s = j[k] as? String { return euro(s) }
            return nil
        }
        func intero(_ k: String) -> Int? { numero(k).map { Int($0.rounded()) } }
        var p = ParametriScenarioVera()
        let nome = (j["cliente"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if nome.isEmpty {
            p.clienteId = attivo
        } else {
            let trovati = InterpreteComandi.clientiNominati(NucleoVera.semplice(nome).lowercased(), clienti)
            p.clienteId = trovati.count == 1 ? trovati[0].id : nil
        }
        p.area = (j["area"] as? String).flatMap { AreaScenarioVera(rawValue: NucleoVera.semplice($0).lowercased()) }
        p.etaPensione = intero("etaPensione")
        p.versamentoMensile = numero("versamentoMensile")
        p.variazioneVersamento = numero("variazioneVersamento")
        p.smetteDiVersare = (j["smetteDiVersare"] as? Bool) ?? false
        p.capitale = numero("capitale")
        p.rendimento = numero("rendimento")
        p.durata = intero("durata")
        p.mancanti = (j["mancanti"] as? [String]) ?? []
        // Zeri e campi vuoti che i modelli piccoli scrivono al posto di «non c'è»
        if p.etaPensione == 0 { p.etaPensione = nil }
        if p.durata == 0 { p.durata = nil }
        if p.capitale == 0 { p.capitale = nil }
        if p.variazioneVersamento == 0 { p.variazioneVersamento = nil }
        if p.smetteDiVersare { p.versamentoMensile = nil; p.variazioneVersamento = nil }
        if p.etaPensione != nil { p.area = .previdenza }
        return (p, (j["scenario"] as? Bool) ?? true)
    }

    /// I parametri di Qwen con quelli delle regole: le cifre lette dalle regole vincono (sono scritte nella frase),
    /// Qwen completa quello che le regole non trovano (un cliente detto in altro modo, «due anni prima»).
    static func unisci(modello m: ParametriScenarioVera, regole r: ParametriScenarioVera) -> ParametriScenarioVera {
        var p = m
        p.frase = r.frase.isEmpty ? m.frase : r.frase
        // Il cliente nominato nella frase vince; altrimenti quello di Qwen (detto in altro modo), poi quello aperto
        if r.clienteNominato, let c = r.clienteId {
            p.clienteId = c
            p.clienteNominato = true
        } else if m.clienteId == nil {
            p.clienteId = r.clienteId
        }
        p.etaPensione = r.etaPensione ?? m.etaPensione
        p.versamentoMensile = r.versamentoMensile ?? m.versamentoMensile
        p.variazioneVersamento = r.variazioneVersamento ?? m.variazioneVersamento
        p.smetteDiVersare = r.smetteDiVersare || m.smetteDiVersare
        if p.smetteDiVersare { p.versamentoMensile = nil; p.variazioneVersamento = nil }
        if p.versamentoMensile != nil { p.variazioneVersamento = nil }
        p.capitale = r.capitale ?? m.capitale
        p.rendimento = r.rendimento ?? m.rendimento
        p.durata = r.durata ?? m.durata
        p.area = p.etaPensione != nil ? .previdenza : (m.area ?? r.area)
        return p
    }

    /// Lo scenario lasciato in sospeso (Vera aveva chiesto un dato) con quello che aggiunge la risposta.
    static func completa(_ sospeso: ParametriScenarioVera, con nuovo: ParametriScenarioVera) -> ParametriScenarioVera {
        var p = sospeso
        p.frase = nuovo.frase
        if let c = nuovo.clienteId { p.clienteId = c }
        if let a = nuovo.area { p.area = a }
        if let e = nuovo.etaPensione { p.etaPensione = e }
        if nuovo.smetteDiVersare {
            p.smetteDiVersare = true
            p.versamentoMensile = nil
            p.variazioneVersamento = nil
        }
        if let v = nuovo.versamentoMensile { p.versamentoMensile = v; p.smetteDiVersare = false }
        if let v = nuovo.variazioneVersamento { p.variazioneVersamento = v; p.smetteDiVersare = false }
        if let c = nuovo.capitale { p.capitale = c }
        if let r = nuovo.rendimento { p.rendimento = r }
        if let d = nuovo.durata { p.durata = d }
        if p.etaPensione != nil { p.area = .previdenza }
        p.mancanti = nuovo.mancanti
        return p
    }

    // MARK: - Quello che manca

    /// La domanda breve da fare se manca un dato indispensabile (nil se lo scenario si può calcolare).
    static func domandaMancante(_ p: ParametriScenarioVera, cliente: Cliente?) -> String? {
        guard p.clienteId != nil, let c = cliente else { return "Per quale cliente faccio lo scenario?" }
        let nome = c.nome.split(separator: " ").first.map(String.init) ?? c.nome
        guard p.cambia else {
            return "Cosa cambia nello scenario di \(nome)? Dimmi per esempio l'età della pensione, il versamento al mese, un capitale in più o in meno, il rendimento o la durata."
        }
        guard let area = p.area else {
            return "Su quale area calcolo lo scenario di \(nome): previdenza, investimenti, risparmio o protezione?"
        }
        if let e = p.etaPensione {
            if let oggi = c.eta, e <= oggi { return "\(nome) ha già \(oggi) anni: a che età va in pensione nello scenario?" }
            if !(etaMinima...etaMassima).contains(e) { return "L'età di pensione va tra i \(etaMinima) e i \(etaMassima) anni: a che età la metto per \(nome)?" }
        }
        if let d = p.durata, !(1...durataMassima).contains(d) { return "Per quanti anni faccio lo scenario di \(nome)? Da 1 a \(durataMassima)." }
        if let r = p.rendimento, !(rendimentoMinimo...rendimentoMassimo).contains(r) {
            return "Il rendimento va tra il \(Int(rendimentoMinimo))% e il \(Int(rendimentoMassimo))% l'anno: quale uso per \(nome)?"
        }
        if area == .protezione && p.capitale == nil && p.durata == nil {
            return "In protezione posso cambiare il capitale caso morte o gli anni di sostegno alla famiglia: quale dei due, e di quanto?"
        }
        return nil
    }

    static let etaMinima = 50
    static let etaMassima = 75
    static let durataMassima = 50
    static let rendimentoMinimo = -10.0
    static let rendimentoMassimo = 15.0

    /// «no», «lascia stare»: lo scenario in sospeso si chiude.
    static func rinuncia(_ frase: String) -> Bool {
        DateItaliane.cerca(#"^(?:no|niente|lascia (?:stare|perdere)|annulla|non importa|lascia|lasciamo (?:stare|perdere))\b"#,
                           InterpreteComandi.pulisci(frase)) != nil
    }

    // MARK: - Il racconto di Qwen

    /// La richiesta per il racconto: le istruzioni della modalità lavoro, poi contesto, scheda prima/dopo di Prisma
    /// (cifre esatte) e domanda. Nella mini finestra anche le istruzioni brevi.
    static func messaggiRacconto(_ s: SchedaScenarioVera, domanda: String, ambiente: AmbienteVera) -> [MessaggioModello] {
        var parti = [NucleoVera.rigaContesto(ambiente)]
        parti.append("SCENARIO CALCOLATO DA PRISMA (numeri esatti: usali così come sono, non rifare i conti e non aggiungerne)\n" + s.bozza)
        parti.append("Racconta lo scenario al consulente: cosa cambia rispetto a oggi e perché conta, con le sole cifre di Prisma, e chiudi con il passo da fare. La tabella con il prima e il dopo la mostra Prisma sotto la tua risposta: non ripeterla riga per riga.")
        if ambiente.breve { parti.append("COME RISPONDERE\n" + IstruzioniVera.mini) }
        parti.append("DOMANDA DEL CONSULENTE\n" + domanda)
        return [MessaggioModello(ruolo: .sistema, testo: IstruzioniVera.chat),
                MessaggioModello(ruolo: .utente, testo: parti.joined(separator: "\n\n"))]
    }
}
