import Foundation

// La nota vocale («Luce» giro 13, Design/template-luce-specifica.md §6.2.5): dal testo dettato sull'iPhone (già
// trascritto sul telefono) Prisma capisce di quale cliente si parla e propone cosa farne: la nota nel dossier (sempre),
// un'attività con la sua scadenza, un messaggio da preparare, un obiettivo da aggiornare. Solo regole, riusando quelle
// del copilota (`RiconoscitoreCopilota`); Qwen, se pronto, può aggiungere attività ma le regole vincono. Mai una scelta
// silenziosa fra due clienti con lo stesso nome; mai un obiettivo creato da qui; mai una cifra non detta.
// Motore puro: niente stato dell'app.

/// Di chi si parla nella nota.
enum RiconoscimentoCliente: Equatable {
    /// Un solo cliente possibile (dal nome, o come indizio dall'appuntamento appena concluso).
    case sicuro(String)
    /// Più clienti possibili (al massimo tre): l'utente sceglie.
    case dubbio([String])
    case nessuno
}

enum MotoreNotaVocale {
    static let maxCandidati = 3
    /// Un appuntamento concluso da meno di 3 ore vale come indizio del cliente.
    static let oreAppuntamento: TimeInterval = 3 * 3600
    /// Il titolo della nota nel dossier: la prima frase, al massimo questi caratteri.
    static let massimoTitolo = 140

    // MARK: - Il cliente

    /// Le parole del nome in forma semplice («Giulia Rossi» → ["giulia", "rossi"]).
    private static func parole(_ nome: String) -> [String] {
        RiconoscitoreCopilota.semplice(nome).split(whereSeparator: { !$0.isLetter }).map(String.init).filter { $0.count >= 2 }
    }

    /// Vero se la parola (o le parole) compaiono intere nel testo semplice.
    private static func contiene(_ t: String, _ parola: String) -> Bool {
        guard !parola.isEmpty else { return false }
        let schema = "\\b" + NSRegularExpression.escapedPattern(for: parola) + "\\b"
        return RiconoscitoreCopilota.primo(schema, t) != nil
    }

    /// Di chi si parla: nome e cognome; il solo nome se è di un cliente solo; i familiari; poi, se nel testo non c'è
    /// nessun nome, il cliente suggerito dall'iPhone o l'appuntamento concluso più vicino (solo come indizio).
    static func cliente(in testo: String, clienti: [Cliente], appuntamenti: [Appuntamento], quando: Date,
                        suggerito: String? = nil) -> RiconoscimentoCliente {
        let t = RiconoscitoreCopilota.semplice(testo)
        // 1. Nome e cognome (in un ordine o nell'altro)
        let completi = clienti.filter { c in
            let p = parole(c.nome)
            guard p.count >= 2 else { return false }
            return contiene(t, p.joined(separator: " ")) || contiene(t, p.reversed().joined(separator: " "))
        }
        if completi.count == 1, let c = completi.first { return .sicuro(c.id) }
        if completi.count > 1 { return .dubbio(Array(completi.prefix(maxCandidati).map(\.id))) }
        // 2. Il nome di battesimo e i familiari (il cliente del familiare)
        var trovati: [String] = []
        for c in clienti {
            let nome = parole(c.nome).first ?? ""
            let familiari = c.famiglia.compactMap { parole($0.nome).first }
            if contiene(t, nome) || familiari.contains(where: { contiene(t, $0) }) {
                if !trovati.contains(c.id) { trovati.append(c.id) }
            }
        }
        if trovati.count == 1, let id = trovati.first { return .sicuro(id) }
        if trovati.count > 1 { return .dubbio(Array(trovati.prefix(maxCandidati))) }
        // 3. Nessun nome: il cliente suggerito dall'iPhone, poi l'appuntamento appena concluso
        if let s = suggerito, clienti.contains(where: { $0.id == s }) { return .sicuro(s) }
        if let a = appuntamentoVicino(appuntamenti, clienti: clienti, quando: quando) { return .sicuro(a.clienteId) }
        return .nessuno
    }

    /// L'appuntamento con un cliente finito da meno di 3 ore prima di `quando` (il più vicino).
    static func appuntamentoVicino(_ appuntamenti: [Appuntamento], clienti: [Cliente], quando: Date) -> Appuntamento? {
        let ids = Set(clienti.map(\.id))
        return appuntamenti.compactMap { a -> (Appuntamento, TimeInterval)? in
            guard ids.contains(a.clienteId) else { return nil }
            let fine = a.inizio.addingTimeInterval(TimeInterval(max(0, a.durataMinuti) * 60))
            let distanza = quando.timeIntervalSince(fine)
            guard distanza >= 0, distanza <= oreAppuntamento else { return nil }
            return (a, distanza)
        }.min { $0.1 < $1.1 }?.0
    }

    // MARK: - Le proposte

    /// La prima frase del testo (per il titolo della nota).
    static func primaFrase(_ testo: String) -> String {
        let prima = RiconoscitoreCopilota.frasi(testo).first?.testo ?? testo
        var t = prima.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count > massimoTitolo {
            let corto = t.prefix(massimoTitolo)
            t = (corto.lastIndex(of: " ").map { String(corto[..<$0]) } ?? String(corto)) + "…"
        } else if !t.isEmpty, let ultimo = t.last, !".!?…".contains(ultimo) {
            t += "."
        }
        return t
    }

    /// Le proposte della nota: la nota sempre, poi attività, messaggio e obiettivo se il testo li dice.
    static func proposte(testo: String, cliente: Cliente?, obiettivi: [Obiettivo], oggi: Date) -> [PropostaNota] {
        var esito: [PropostaNota] = []
        let prima = primaFrase(testo)
        esito.append(PropostaNota(id: "nota", tipo: .nota, titolo: prima, frase: testo.trimmingCharacters(in: .whitespacesAndNewlines)))
        let nome = cliente.flatMap { $0.nome.split(separator: " ").first.map(String.init) } ?? ""
        let suoi = obiettivi.filter { o in cliente.map { o.clienteId == $0.id } ?? false }
        for f in RiconoscitoreCopilota.frasi(testo) where !f.domanda {
            if let a = attivita(f, nome: nome, oggi: oggi), !esito.contains(where: { $0.id == a.id }) { esito.append(a) }
            if let m = messaggio(f), !esito.contains(where: { $0.id == m.id }) { esito.append(m) }
            if let sp = spostamentoObiettivo(f.semplice), let o = suoi.first(where: { $0.area == sp.area }) {
                let anni = sp.anni, area = sp.area
                let id = "obiettivo-" + area.rawValue
                guard !esito.contains(where: { $0.id == id }) else { continue }
                var p = PropostaNota(id: id, tipo: .obiettivo, titolo: titoloObiettivo(area: area, anni: anni), frase: f.testo)
                p.obiettivoId = o.id
                p.anniSpostamento = anni
                p.area = area
                esito.append(p)
            }
        }
        return esito
    }

    /// «Casa: un anno prima · da confermare».
    static func titoloObiettivo(area: AreaBisogno, anni: Int) -> String {
        let n = abs(anni)
        let quanto = n == 1 ? "un anno" : "\(n) anni"
        return "\(RiconoscitoreCopilota.nomeArea(area)): \(quanto) \(anni < 0 ? "prima" : "dopo") · da confermare"
    }

    private static let verbiAttivita: [(String, String)] = [
        ("risentir", "Risentire"), ("richiamar", "Richiamare"), ("ricontattar", "Ricontattare"), ("chiamar", "Chiamare"),
        ("sentir", "Sentire"), ("riveder", "Rivedere"), ("incontrar", "Incontrare"),
    ]

    /// «Risentirla a gennaio per il mutuo» → «Risentire Giulia per il mutuo · gennaio» (1° gennaio prossimo, da confermare).
    /// Anche le frasi del copilota («ti preparo…», «mandare la proposta entro venerdì»), con la loro scadenza.
    static func attivita(_ f: RiconoscitoreCopilota.Frase, nome: String, oggi: Date) -> PropostaNota? {
        let t = f.semplice
        let elenco = verbiAttivita.map(\.0).joined(separator: "|")
        guard let m = RiconoscitoreCopilota.primo(#"\b("# + elenco + #")(?:e|la|lo|li|le|ci)?\b"#, t),
              let verbo = verbiAttivita.first(where: { $0.0 == m.gruppi[1] })?.1 else {
            return nil
        }
        // «per il mutuo»: fino alla virgola, al punto o a «e …»
        var perCosa = ""
        let coda = String(Array(t)[m.intervallo.fine...])
        if let p = RiconoscitoreCopilota.primo(#"\bper (?:il|la|lo|l'|i|gli|le|un|una|un') ?[^,;.]+?(?=\s+e\s|[,;.]|$)"#, coda),
           let originale = p.intervallo.spostato(di: m.intervallo.fine).testo(in: f.testo) {
            perCosa = " " + originale.trimmingCharacters(in: .whitespaces)
        }
        var titolo = verbo + (nome.isEmpty ? "" : " " + nome) + perCosa
        var scadenza: Date?
        var daConfermare = false
        let annoOggi = Calendar(identifier: .gregorian).component(.year, from: oggi)
        if let tempo = RiconoscitoreCopilota.tempi(t, annoOggi: annoOggi).first(where: { $0.anno != nil && $0.mese != nil }),
           let a = tempo.anno, let mese = tempo.mese,
           let d = Calendar(identifier: .gregorian).date(from: DateComponents(year: a, month: mese, day: 1)) {
            scadenza = d
            titolo += " · " + RiconoscitoreCopilota.mesi[mese - 1] + " \(a)"
        } else if let detto = meseSenzaAnno(t, oggi: oggi) {
            let d = detto.data
            scadenza = d
            daConfermare = true
            let mese = Calendar(identifier: .gregorian).component(.month, from: d)
            titolo += " · " + RiconoscitoreCopilota.mesi[mese - 1]
        } else if let detta = RiconoscitoreCopilota.scadenza(t, oggi: oggi) {
            scadenza = detta.0
        }
        var p = PropostaNota(id: "attivita-" + RiconoscitoreCopilota.chiave(verbo + perCosa), tipo: .attivita, titolo: titolo, frase: f.testo)
        p.scadenza = scadenza.map(NotaInArrivo.alSecondo)
        p.scadenzaDaConfermare = daConfermare
        return p
    }

    /// «a gennaio» senza l'anno → il primo gennaio prossimo, da confermare (il mese di oggi → oggi).
    static func meseSenzaAnno(_ t: String, oggi: Date) -> (data: Date, daConfermare: Bool)? {
        let elencoMesi = RiconoscitoreCopilota.mesi.joined(separator: "|")
        guard let m = RiconoscitoreCopilota.primo(#"\b(?:a|ad|in|entro|per|verso|da|di|a fine|a inizio) ("# + elencoMesi + #")\b(?!\s+(?:del\s+|di\s+)?20\d\d)"#,
                                                  RiconoscitoreCopilota.semplice(t)),
              let k = RiconoscitoreCopilota.mesi.firstIndex(of: m.gruppi[1]) else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let mese = k + 1
        let meseOggi = cal.component(.month, from: oggi)
        let annoOggi = cal.component(.year, from: oggi)
        if mese == meseOggi { return (cal.startOfDay(for: oggi), true) }
        let anno = mese > meseOggi ? annoOggi : annoOggi + 1
        guard let d = cal.date(from: DateComponents(year: anno, month: mese, day: 1)) else { return nil }
        return (d, true)
    }

    /// «anticipare la casa di un anno» → (-1, .casa); «posticipare la pensione di due anni» → (+2, .pensione).
    static func spostamentoObiettivo(_ t: String) -> (anni: Int, area: AreaBisogno)? {
        let s = RiconoscitoreCopilota.semplice(t)
        guard let m = RiconoscitoreCopilota.primo(#"\b(anticip|posticip|rimand|ritard)\w*\b(.{0,60}?)\bdi "# + RiconoscitoreCopilota.parolaNumero + #" ann[oi]\b"#, s),
              let n = RiconoscitoreCopilota.numero(m.gruppi[3]), (1...30).contains(n) else { return nil }
        guard let area = RiconoscitoreCopilota.area(m.gruppi[2]) ?? RiconoscitoreCopilota.area(s) else { return nil }
        return (m.gruppi[1] == "anticip" ? -n : n, area)
    }

    /// «mandarle il confronto con 650 euro al mese» → «Il confronto con 650 € al mese».
    static func messaggio(_ f: RiconoscitoreCopilota.Frase) -> PropostaNota? {
        guard let m = RiconoscitoreCopilota.primo(#"\b(?:mandar|inviar|spedir)(?:e|le|gli|la|lo|vi|ci|glielo|gliela)?\s+(.+?)(?=[,;.]|$)"#, f.semplice),
              m.intervalli.count > 1, let gruppo = m.intervalli[1], var oggetto = gruppo.testo(in: f.testo) else { return nil }
        oggetto = oggetto.trimmingCharacters(in: .whitespaces)
        guard oggetto.count >= 3 else { return nil }
        let importi = RiconoscitoreCopilota.importi(RiconoscitoreCopilota.semplice(oggetto))
        let leggibile = oggetto.replacingOccurrences(of: #"\s+euro\b"#, with: " €", options: [.regularExpression, .caseInsensitive])
        let titolo = leggibile.prefix(1).uppercased() + leggibile.dropFirst()
        var p = PropostaNota(id: "messaggio-" + RiconoscitoreCopilota.chiave(oggetto), tipo: .messaggio, titolo: String(titolo), frase: f.testo)
        p.importi = importi.flatMap(\.valori)
        p.frequenza = importi.first?.frequenza
        return p
    }

    /// Qwen aggiunge solo attività che le regole non hanno trovato; le regole vincono sempre.
    static func unisciQwen(regole: [PropostaNota], qwen: [SchedaCopilota], testo: String) -> [PropostaNota] {
        var esito = regole
        let giaAttivita = regole.contains { $0.tipo == .attivita }
        for s in qwen where s.tipo == .attivita && !giaAttivita {
            let id = "attivita-" + RiconoscitoreCopilota.chiave(s.titolo)
            guard !esito.contains(where: { $0.id == id }) else { continue }
            var p = PropostaNota(id: id, tipo: .attivita, titolo: s.titolo, frase: s.frase)
            p.scadenza = s.cifre.scadenza.map(NotaInArrivo.alSecondo)
            p.origine = .qwen
            esito.append(p)
        }
        return esito
    }
}
