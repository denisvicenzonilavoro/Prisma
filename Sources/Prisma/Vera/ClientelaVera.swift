import Foundation

// «Chiedi alla tua clientela» (Vera/BRIEF.md, funzione 2; template «Chiedi alla tua clientela»): una domanda su tutti
// i clienti insieme («Chi ha più di sei mesi di spese ferme in liquidità e non lo vedo da almeno tre mesi?»).
// 1. Il codice riconosce la domanda (comincia con «chi», «quali clienti»… e non nomina un cliente).
// 2. Qwen la traduce in filtri JSON con lo schema fisso di Vera/Schemi/clientela.json (istruzioni
//    Vera/Istruzioni/clientela.md, schema in «format» di Ollama, temperatura 0). A Qwen va solo la domanda: nessun dato.
// 3. Le regole rileggono numeri e mesi scritti nella frase («sei mesi», «entro marzo»): dove li trovano vincono.
// 4. Prisma applica i filtri ai dati (stesse regole di Posizioni e Agenda) e mostra i filtri capiti, la tabella e
//    «Crea N attività», che passa dalla scheda di conferma. Il risultato è lo stesso della ricerca fatta a mano.

/// Un filtro capito da Qwen (e riletto dalle regole).
struct FiltroClientela: Codable, Equatable {
    enum Tipo: String, Codable, CaseIterable {
        case liquiditaMesiMinimo = "liquidita_mesi_minimo"
        case senzaIncontroDaGiorni = "senza_incontro_da_giorni"
        case compieAnniEntro = "compie_anni_entro"
        case etaMinima = "eta_minima"
        case etaMassima = "eta_massima"
        case coniugeSenzaProtezione = "coniuge_senza_protezione"
        case polizzeInScadenzaEntro = "polizze_in_scadenza_entro"
        case posizioniInScadenzaEntro = "posizioni_in_scadenza_entro"
        case canale
        case consensoPrivacyMancante = "consenso_privacy_mancante"
        case senzaConsensoMarketing = "senza_consenso_marketing"
        case senzaArea = "senza_area"
        case conArea = "con_area"
        case patrimonioMinimo = "patrimonio_minimo"
        case senzaAppuntamentiFuturi = "senza_appuntamenti_futuri"
        case figliACarico = "figli_a_carico"
    }

    var tipo: Tipo
    var numero: Double?
    var data: Date?
    var testo: String?

    init(_ tipo: Tipo, numero: Double? = nil, data: Date? = nil, testo: String? = nil) {
        self.tipo = tipo
        self.numero = numero
        self.data = data
        self.testo = testo
    }
}

/// Una riga della tabella: il cliente, i valori delle colonne dei filtri e i canali.
struct RigaClientela: Codable, Equatable, Identifiable {
    var id: String
    var nome: String
    var valori: [String]
    var canali: [Canale]
}

/// Il risultato: i filtri capiti (come etichette), la tabella e quanti clienti sono stati controllati.
struct RisultatoClientela: Codable, Equatable {
    var domanda: String
    var filtri: [FiltroClientela]
    /// «Liquidità oltre 6 mesi di spese», «Ultimo incontro oltre 90 giorni».
    var etichette: [String]
    var colonne: [String]
    var righe: [RigaClientela]
    /// I clienti controllati (tutti quelli in Prisma).
    var totale: Int
    /// Come sono state lette le ipotesi («spese stimate…»).
    var note: [String] = []

    /// «Prisma ha controllato le schede: sono 3 clienti.»
    var frase: String {
        switch righe.count {
        case 0: return "Prisma ha controllato le schede: nessun cliente."
        case 1: return "Prisma ha controllato le schede: c'è 1 cliente."
        default: return "Prisma ha controllato le schede: sono \(righe.count) clienti."
        }
    }
}

/// I dati su cui si cerca: tutti i clienti e quello che serve ai filtri.
struct DatiClientela {
    var oggi: Date
    var clienti: [Cliente]
    var posizioni: [Posizione]
    var appuntamenti: [Appuntamento]
    var incontri: [Incontro]
    /// Le spese al mese di ogni cliente (Analisi 360 › Protezione, fabbisogno mensile) e se l'analisi è salvata.
    var spese: [String: (mensili: Double, salvata: Bool)]
    var calendario = Calendar.current
}

enum ClientelaVera {
    // MARK: - Riconoscere la domanda

    /// Una domanda su tutti i clienti: comincia con «chi», «quali clienti», «quanti clienti», «elenca i clienti»… e non
    /// nomina un cliente preciso (allora è una domanda su quel cliente).
    static func eUnaDomanda(_ testo: String, clienti: [ClienteNoto], soloEspliciti: Bool = false) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        // Nel dossier di un cliente «chi è l'assicurato?» riguarda quel cliente: vale solo la forma con «clienti»
        if soloEspliciti, DateItaliane.cerca(#"\bclienti\b"#, t) == nil { return false }
        guard DateItaliane.cerca(#"^(?:chi\b|quali (?:dei miei |tra i miei )?clienti\b|quali sono i (?:miei )?clienti\b|quanti (?:dei miei |tra i miei )?clienti\b|(?:elenca|elencami|trova|trovami|mostrami|dimmi|cerca)(?: tutti)? i (?:miei )?clienti\b|tra i (?:miei )?clienti\b|(?:i )?clienti che\b)"#, t) != nil else { return false }
        guard DateItaliane.cerca(#"\be se\b|cosa succede se"#, t) == nil else { return false }
        // Le domande che il portafoglio sa già («Chi devo ricontattare?», riesami, deduzioni di fine anno) restano sue
        let piega = { (s: String) in s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Formati.italiano) }
        if SpuntoPortafoglio.allCases.contains(where: { piega(InterpreteComandi.pulisci($0.domanda)) == piega(t) }) { return false }
        if DateItaliane.cerca(#"ricontatt|richiam|riesam|dedur|deducib"#, t) != nil { return false }
        return InterpreteComandi.clientiNominati(t, clienti).isEmpty
    }

    // MARK: - Qwen: la domanda in filtri JSON

    static var schema: [String: Any] {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Schemi/clientela.json"),
           let d = try? Data(contentsOf: url), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] {
            return j
        }
        return schemaInterno
    }

    /// Lo stesso schema di Vera/Schemi/clientela.json (la prova controlla che coincidano).
    static let schemaInterno: [String: Any] = {
        let tipo: [String: Any] = ["type": "string", "enum": FiltroClientela.Tipo.allCases.map(\.rawValue)]
        var voce: [String: Any] = ["type": "object", "required": ["tipo"]]
        voce["properties"] = ["tipo": tipo, "numero": ["type": "number"], "data": ["type": "string"], "testo": ["type": "string"]] as [String: Any]
        let filtri: [String: Any] = ["type": "array", "items": voce]
        let proprieta: [String: Any] = ["capito": ["type": "boolean"], "filtri": filtri]
        let richiesti: [String] = ["capito", "filtri"]
        return ["type": "object", "properties": proprieta, "required": richiesti]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("clientela") ?? "Traduci la domanda di un consulente finanziario sui suoi clienti in filtri JSON: capito (true se la domanda si può tradurre con i filtri) e filtri (tipo tra quelli dello schema, numero, data AAAA-MM-GG, testo). Non inventare filtri che la domanda non dice."
    }

    static func messaggi(_ domanda: String, oggi: Date) -> [MessaggioModello] {
        let giorno = "\(Formati.dataLunga.string(from: oggi)) \(Formati.formato("yyyy").string(from: oggi))"
        let iso = Formati.formato("yyyy-MM-dd").string(from: oggi)
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "CONTESTO: oggi è \(giorno) (\(iso)).\nDOMANDA: \(domanda)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.massimoToken = 300
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    /// I filtri dal JSON di Qwen (tollera parole o ``` attorno). nil se il JSON non è valido; [] se Qwen non ha capito.
    static func leggiJSON(_ testo: String, oggi: Date, cal: Calendar = .current) -> [FiltroClientela]? {
        guard let i = testo.firstIndex(of: "{"), let f = testo.lastIndex(of: "}"), i < f,
              let d = String(testo[i...f]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return nil }
        if (j["capito"] as? Bool) == false { return [] }
        guard let elenco = j["filtri"] as? [[String: Any]] else { return nil }
        return elenco.compactMap { v -> FiltroClientela? in
            guard let t = (v["tipo"] as? String).flatMap(FiltroClientela.Tipo.init(rawValue:)) else { return nil }
            let a = ArgomentiStrumento(v)
            return FiltroClientela(t, numero: a.numero("numero"), data: RegistroStrumenti.giorno(a.testo("data"), oggi: oggi, cal: cal) ?? fineMese(a.testo("data"), oggi: oggi, cal: cal),
                                   testo: a.testo("testo")?.lowercased())
        }
    }

    // MARK: - Prima il codice: le regole rileggono la frase

    /// «entro marzo» → 31 marzo (la prossima volta che arriva); nil se il testo non è un mese.
    static func fineMese(_ s: String?, oggi: Date, cal: Calendar = .current) -> Date? {
        guard let s = s?.lowercased(), let i = DateItaliane.mesi.firstIndex(where: { s.contains($0) }) else { return nil }
        let mese = i + 1
        var anno = cal.component(.year, from: oggi)
        if let a = DateItaliane.cerca(#"\b(20\d{2})\b"#, s).flatMap({ Int($0.1[1]) }) {
            anno = a
        } else if mese < cal.component(.month, from: oggi) {
            anno += 1
        }
        guard let primo = cal.date(from: DateComponents(year: anno, month: mese, day: 1)),
              let ultimo = cal.date(byAdding: DateComponents(month: 1, day: -1), to: primo) else { return nil }
        return cal.startOfDay(for: ultimo)
    }

    private static func numeroDetto(_ s: String) -> Double? {
        if let n = Double(s.replacingOccurrences(of: ",", with: ".")) { return n }
        return DateItaliane.numero(s).map(Double.init)
    }

    private static let numeroParola = #"\b(\d+(?:,\d+)?|un|una|uno|due|tre|quattro|cinque|sei|sette|otto|nove|dieci|undici|dodici|diciotto|venti|trenta|quaranta|cinquanta)"#

    /// I numeri e le date scritti nella frase vincono su quelli di Qwen (come negli scenari).
    static func correggi(_ filtri: [FiltroClientela], domanda: String, oggi: Date, cal: Calendar = .current) -> [FiltroClientela] {
        let t = domanda.lowercased()
        let entro = DateItaliane.cerca(#"\b(?:entro|fino a|prima di|da oggi a)\s+(?:fine\s+)?(?:il mese di\s+)?("# + DateItaliane.mesi.joined(separator: "|") + #")(?:\s+(20\d{2}))?"#, t)
            .flatMap { fineMese($0.1[1] + " " + $0.1[2], oggi: oggi, cal: cal) }
        return filtri.map { f in
            var f = f
            switch f.tipo {
            case .liquiditaMesiMinimo:
                if let g = DateItaliane.cerca(numeroParola + #"\s+mesi\s+di\s+spes"#, t), let n = numeroDetto(g.1[1]) { f.numero = n }
            case .senzaIncontroDaGiorni:
                if let g = DateItaliane.cerca(#"(?:da|almeno|più di|oltre)\s+(?:almeno\s+)?"# + numeroParola + #"\s+(mesi|mese|giorni|settimane|anni|anno)(?!\s+di\s+spes)"#, t),
                   let n = numeroDetto(g.1[1]) {
                    switch g.1[2] {
                    case "giorni": f.numero = n
                    case "settimane": f.numero = n * 7
                    case "anni", "anno": f.numero = n * 365
                    default: f.numero = n * 30
                    }
                }
            case .compieAnniEntro:
                if let g = DateItaliane.cerca(#"compi(?:e|ono)\s+"# + numeroParola + #"\s+anni"#, t), let n = numeroDetto(g.1[1]) { f.numero = n }
                if let e = entro { f.data = e }
            case .polizzeInScadenzaEntro, .posizioniInScadenzaEntro:
                if let e = entro { f.data = e }
            default: break
            }
            return f
        }
    }

    // MARK: - La ricerca

    private static func fmt(_ v: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? String(v)
    }

    static func etichette(_ f: FiltroClientela, oggi: Date) -> [String] {
        let n = f.numero.map(fmt) ?? "?"
        let entro = f.data.map { "entro il \(Formati.dataEstesa.string(from: $0))" } ?? "senza data"
        switch f.tipo {
        case .liquiditaMesiMinimo: return ["Liquidità oltre \(n) mesi di spese"]
        case .senzaIncontroDaGiorni: return ["Ultimo incontro oltre \(n) giorni"]
        case .compieAnniEntro:
            let periodo = f.data.map { "Da oggi a \(Formati.meseAnno.string(from: $0))" } ?? "Nei prossimi 12 mesi"
            return ["Compie \(n) anni", periodo]
        case .etaMinima: return ["Almeno \(n) anni"]
        case .etaMassima: return ["Al massimo \(n) anni"]
        case .coniugeSenzaProtezione: return ["Coniuge o convivente in famiglia", "Nessuna polizza a suo nome"]
        case .polizzeInScadenzaEntro: return ["Polizze in essere", "Scadenza \(entro)"]
        case .posizioniInScadenzaEntro: return ["Posizioni in essere", "Scadenza \(entro)"]
        case .canale: return [f.testo?.contains("all") == true ? "Canale Alleanza" : "Canale indipendente"]
        case .consensoPrivacyMancante: return ["Consenso privacy mancante"]
        case .senzaConsensoMarketing: return ["Senza consenso commerciale"]
        case .senzaArea: return ["Nessuna posizione \(nomeArea(f.testo))"]
        case .conArea: return ["Con posizioni \(nomeArea(f.testo))"]
        case .patrimonioMinimo: return ["Patrimonio oltre \(Formati.euro(f.numero ?? 0))"]
        case .senzaAppuntamentiFuturi: return ["Nessun incontro in agenda"]
        case .figliACarico: return ["Figli a carico"]
        }
    }

    static func area(_ s: String?) -> AreaPosizione? {
        let t = s?.lowercased() ?? ""
        if t.contains("previd") || t.contains("pension") { return .previdenza }
        if t.contains("protez") || t.contains("assicur") || t.contains("polizz") { return .protezione }
        if t.contains("investim") { return .investimento }
        if t.contains("rispar") || t.contains("accumul") { return .risparmio }
        if t.contains("liquid") || t.contains("conto") { return .liquidita }
        if t.contains("immob") || t.contains("casa") { return .immobili }
        if t.contains("debit") || t.contains("mutuo") || t.contains("prestit") { return .debiti }
        return nil
    }

    private static func nomeArea(_ s: String?) -> String {
        switch area(s) {
        case .previdenza: return "di previdenza"
        case .protezione: return "di protezione"
        case .investimento: return "di investimento"
        case .risparmio: return "di risparmio"
        case .liquidita: return "di liquidità"
        case .immobili: return "immobiliare"
        case .debiti: return "di debito"
        case nil: return "in quell'area"
        }
    }

    private static func colonna(_ f: FiltroClientela) -> String? {
        switch f.tipo {
        case .liquiditaMesiMinimo: return "Liquidità"
        case .senzaIncontroDaGiorni: return "Ultimo incontro"
        case .compieAnniEntro: return "Quando"
        case .etaMinima, .etaMassima: return "Età"
        case .coniugeSenzaProtezione: return "In famiglia"
        case .polizzeInScadenzaEntro: return "Polizza"
        case .posizioniInScadenzaEntro: return "In scadenza"
        case .consensoPrivacyMancante: return "Privacy"
        case .senzaConsensoMarketing: return "Consenso commerciale"
        case .senzaArea, .conArea: return "Area"
        case .patrimonioMinimo: return "Patrimonio"
        case .senzaAppuntamentiFuturi: return "Prossimo incontro"
        case .figliACarico: return "Figli a carico"
        case .canale: return nil
        }
    }

    /// L'età compiuta a una data.
    static func eta(_ nascita: Date?, al giorno: Date, cal: Calendar = .current) -> Int? {
        nascita.flatMap { cal.dateComponents([.year], from: $0, to: giorno).year }
    }

    /// L'ultimo incontro passato (agenda o incontro registrato).
    static func ultimoIncontro(_ c: Cliente, _ d: DatiClientela) -> Date? {
        let a = d.appuntamenti.filter { $0.clienteId == c.id && $0.inizio < d.oggi }.map(\.inizio)
        let i = d.incontri.filter { $0.clienteId == c.id && $0.data < d.oggi }.map(\.data)
        return (a + i).max()
    }

    static func liquidita(_ c: Cliente, _ d: DatiClientela) -> Double {
        d.posizioni.filter { $0.clienteId == c.id && $0.stato == .inEssere && $0.area == .liquidita }.reduce(0) { $0 + $1.valore }
    }

    /// Le polizze in essere che assicurano una persona della famiglia (vita, invalidità e le altre coperture).
    static func protezioniDi(_ f: Familiare, cliente c: Cliente, _ d: DatiClientela) -> [Posizione] {
        d.posizioni.filter { $0.clienteId == c.id && $0.stato == .inEssere && $0.area == .protezione && MotoreProtezioneFamiglia.assicurato($0, cliente: c) == f.id }
    }

    private static func quanto(_ giorni: Int) -> String {
        if giorni < 60 { return "\(giorni) giorni fa" }
        let mesi = giorni / 30
        return mesi == 1 ? "1 mese fa" : "\(mesi) mesi fa"
    }

    /// Il valore della colonna di un filtro per un cliente, se il cliente passa il filtro (nil se non passa).
    static func valuta(_ f: FiltroClientela, _ c: Cliente, _ d: DatiClientela) -> String?? {
        let cal = d.calendario
        let oggi = cal.startOfDay(for: d.oggi)
        switch f.tipo {
        case .liquiditaMesiMinimo:
            guard let minimo = f.numero, let s = d.spese[c.id], s.mensili > 0 else { return nil }
            let mesi = liquidita(c, d) / s.mensili
            guard mesi > minimo else { return nil }
            let arrotondati = (mesi * 2).rounded(.down) / 2
            return .some("\(fmt(arrotondati)) mesi di spese" + (s.salvata ? "" : " (spese stimate)"))
        case .senzaIncontroDaGiorni:
            guard let g = f.numero else { return nil }
            guard let u = ultimoIncontro(c, d) else { return .some("mai") }
            let giorni = cal.dateComponents([.day], from: cal.startOfDay(for: u), to: oggi).day ?? 0
            return Double(giorni) >= g ? .some(quanto(giorni)) : nil
        case .compieAnniEntro:
            guard let anni = f.numero.map({ Int($0) }), let nascita = c.dataNascita,
                  let compleanno = cal.date(byAdding: .year, value: anni, to: nascita) else { return nil }
            let fine = f.data ?? cal.date(byAdding: .year, value: 1, to: oggi) ?? oggi
            guard compleanno >= oggi, compleanno <= fine else { return nil }
            return .some("il \(Formati.giornoMese.string(from: compleanno))")
        case .etaMinima:
            guard let e = eta(c.dataNascita, al: oggi, cal: cal), let n = f.numero, Double(e) >= n else { return nil }
            return .some("\(e) anni")
        case .etaMassima:
            guard let e = eta(c.dataNascita, al: oggi, cal: cal), let n = f.numero, Double(e) <= n else { return nil }
            return .some("\(e) anni")
        case .coniugeSenzaProtezione:
            let scoperti = c.famiglia.filter { ($0.relazione == .coniuge || $0.relazione == .convivente) && protezioniDi($0, cliente: c, d).isEmpty }
            guard !scoperti.isEmpty else { return nil }
            return .some(scoperti.map { p in
                let nome = p.nome.split(separator: " ").first.map(String.init) ?? p.nome
                return eta(p.dataNascita, al: oggi, cal: cal).map { "\(nome), \($0) anni" } ?? nome
            }.joined(separator: "; "))
        case .polizzeInScadenzaEntro, .posizioniInScadenzaEntro:
            guard let fine = f.data else { return nil }
            let elenco = d.posizioni.filter {
                $0.clienteId == c.id && $0.stato == .inEssere && (f.tipo == .posizioniInScadenzaEntro || $0.area == .protezione)
                    && ($0.scadenza.map { $0 >= oggi && $0 <= fine } ?? false)
            }.sorted { ($0.scadenza ?? oggi) < ($1.scadenza ?? oggi) }
            guard !elenco.isEmpty else { return nil }
            return .some(elenco.map { "\($0.nome) · \(Formati.giornoMese.string(from: $0.scadenza ?? oggi))" }.joined(separator: "; "))
        case .canale:
            let voluto: Canale = f.testo?.contains("all") == true ? .alleanza : .indipendente
            return canali(c, d).contains(voluto) ? .some(nil) : nil
        case .consensoPrivacyMancante:
            return c.consensi.privacy ? nil : .some("manca")
        case .senzaConsensoMarketing:
            return c.consensi.marketing ? nil : .some("non dato")
        case .senzaArea, .conArea:
            guard let a = area(f.testo) else { return nil }
            let n = d.posizioni.filter { $0.clienteId == c.id && $0.stato == .inEssere && $0.area == a }.count
            if f.tipo == .senzaArea { return n == 0 ? .some("nessuna") : nil }
            return n > 0 ? .some(n == 1 ? "1 posizione" : "\(n) posizioni") : nil
        case .patrimonioMinimo:
            guard let minimo = f.numero else { return nil }
            let totale = d.posizioni.filter { $0.clienteId == c.id && $0.stato == .inEssere && $0.area != .debiti }.reduce(0) { $0 + $1.valore }
            return totale > minimo ? .some(Formati.euro(totale)) : nil
        case .senzaAppuntamentiFuturi:
            let futuri = d.appuntamenti.contains { $0.clienteId == c.id && $0.stato == .pianificato && $0.inizio >= d.oggi }
            return futuri ? nil : .some("nessuno")
        case .figliACarico:
            let figli = c.famiglia.filter { ($0.relazione == .figlio || $0.relazione == .figlia) && $0.aCarico }
            return figli.isEmpty ? nil : .some(String(figli.count))
        }
    }

    /// I canali del cliente: quelli delle posizioni in essere, altrimenti quelli della scheda.
    static func canali(_ c: Cliente, _ d: DatiClientela) -> [Canale] {
        let delle = Set(d.posizioni.filter { $0.clienteId == c.id && $0.stato == .inEssere }.map(\.canale))
        let scelti = delle.isEmpty ? Set(c.canali) : delle
        return Canale.allCases.filter { scelti.contains($0) }
    }

    /// Applica i filtri a tutti i clienti: passa chi li supera tutti.
    static func cerca(_ filtri: [FiltroClientela], domanda: String, dati d: DatiClientela) -> RisultatoClientela {
        let colonne = ["Cliente"] + filtri.compactMap(colonna) + ["Canale"]
        var righe: [RigaClientela] = []
        for c in d.clienti.sorted(by: { $0.nome < $1.nome }) {
            var valori: [String] = []
            var passa = true
            for f in filtri {
                guard let v = valuta(f, c, d) else { passa = false; break }
                if colonna(f) != nil { valori.append(v ?? "") }
            }
            if passa { righe.append(RigaClientela(id: c.id, nome: c.nome, valori: valori, canali: canali(c, d))) }
        }
        var note: [String] = []
        if filtri.contains(where: { $0.tipo == .liquiditaMesiMinimo }),
           righe.contains(where: { d.spese[$0.id]?.salvata == false }) {
            note.append("Le spese stimate sono il fabbisogno predefinito di Analisi 360 (\(Formati.euro(IpotesiProtezione().fabbisognoMensile)) al mese): salva l'analisi del cliente per usare le sue.")
        }
        return RisultatoClientela(domanda: domanda, filtri: filtri, etichette: filtri.flatMap { etichette($0, oggi: d.oggi) },
                                  colonne: colonne, righe: righe, totale: d.clienti.count, note: note)
    }

    // MARK: - «Crea N attività»

    /// Il prossimo venerdì da oggi (oggi compreso): le attività «da fare questa settimana».
    static func venerdi(_ oggi: Date, cal: Calendar = .current) -> Date {
        let base = cal.startOfDay(for: oggi)
        if cal.component(.weekday, from: base) == 6 { return base }
        return cal.nextDate(after: base, matching: DateComponents(weekday: 6), matchingPolicy: .nextTime) ?? base
    }

    /// La scheda di conferma con un'attività per ogni cliente della tabella.
    static func schedaAttivita(_ r: RisultatoClientela, oggi: Date, cal: Calendar = .current) -> SchedaConfermaVera? {
        guard !r.righe.isEmpty else { return nil }
        let scadenza = venerdi(oggi, cal: cal)
        let motivo = r.etichette.first.map { $0.prefix(1).lowercased() + $0.dropFirst() } ?? "dalla domanda su tutti i clienti"
        let titolo = "Da sentire: \(motivo)"
        let azioni = r.righe.map { riga in
            AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Segno un'attività per \(riga.nome)",
                           dettaglio: "«\(titolo)» · entro \(DateItaliane.descrivi(scadenza, conOra: false, oggi: oggi))",
                           argomenti: ["cliente": riga.id, "titolo": titolo, "scadenza": RegistroStrumenti.isoData(scadenza)])
        }
        return SchedaConfermaVera(richiesta: r.domanda, azioni: azioni, origine: .clientela)
    }
}
