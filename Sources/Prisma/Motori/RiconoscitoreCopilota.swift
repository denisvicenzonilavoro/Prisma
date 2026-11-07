import Foundation

// Il riconoscitore del copilota dell'incontro (Orizzonte, giro 5; specifica §8.5.3): dato un pezzo di trascrizione
// trova quattro tipi di cose, più le cose da fare:
// - obiettivi, con tempi e cifre («comprare casa tra tre anni, 40.000 euro di anticipo»);
// - polizze e posizioni di altre compagnie («una vita intera con un'altra compagnia, 90 euro al mese»);
// - timori e preferenze di rischio («i soldi della casa non voglio rischiarli»): annotazione, non profilo MiFID;
// - eventi della vita («a giugno del 2027 ci sposiamo»);
// - attività («ti preparo un confronto»), anche derivate (la polizza da chiedere per il confronto).
// Due livelli: (a) regole locali, deterministiche e veloci (parole, cifre, anni), che funzionano anche senza Qwen;
// (b) Qwen con Vera/Istruzioni/copilota.md e lo schema fisso Vera/Schemi/copilota.json: ogni scheda di Qwen con una
// cifra che non è nella frase si scarta, e sulle stesse cose vincono le regole. Le cifre sono sempre lette dalla frase,
// mai inventate; i titoli li scrive l'app con frasi fisse. Le schede nascono «proposte»: niente entra nel dossier
// senza conferma (`ApplicaCopilota`).

/// Quello che il copilota sa dell'incontro mentre ascolta.
struct ContestoCopilota: Equatable {
    /// Gli obiettivi del cliente già nel dossier (per «Aggiorna l’obiettivo» invece di «Crea»).
    var obiettivi: [Obiettivo]
    /// L'area dell'ultimo obiettivo di cui si è parlato («i soldi della casa», «anzi tra quattro»).
    var ultimaArea: AreaBisogno?
    var oggi: Date

    init(obiettivi: [Obiettivo] = [], ultimaArea: AreaBisogno? = nil, oggi: Date = Date()) {
        self.obiettivi = obiettivi
        self.ultimaArea = ultimaArea
        self.oggi = oggi
    }

    var annoOggi: Int { Calendar(identifier: .gregorian).component(.year, from: oggi) }
}

/// Quello che il riconoscitore trova in un pezzo: le schede e le parole da illuminare nel pezzo.
struct EsitoPezzoCopilota: Equatable {
    var schede: [SchedaCopilota]
    /// Intervalli in caratteri del testo del pezzo.
    var evidenze: [IntervalloTesto]
}

enum RiconoscitoreCopilota {

    // MARK: - Frasi e testo semplice

    /// Una frase del pezzo: il testo, lo stesso in forma semplice (stessi caratteri, uno per uno), dove comincia nel
    /// pezzo e se è una domanda (le domande non danno schede).
    struct Frase: Equatable {
        let testo: String
        let semplice: String
        let inizio: Int
        let domanda: Bool
    }

    /// Minuscole, senza accenti, apostrofi dritti: carattere per carattere, così gli intervalli valgono anche sul
    /// testo originale.
    static func semplice(_ s: String) -> String {
        String(s.map { c -> Character in
            if c == "’" || c == "‘" || c == "`" { return "'" }
            if c == "\u{00A0}" { return " " }
            let f = String(c).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Formati.italiano).lowercased()
            if f.count == 1, let x = f.first { return x }
            return c
        })
    }

    /// Le frasi del pezzo (si spezza a «. ! ? ; …» seguiti da uno spazio, e agli a capo; mai dentro «40.000»).
    static func frasi(_ testo: String) -> [Frase] {
        let c = Array(testo)
        var esito: [Frase] = []
        var inizio = 0
        func chiudi(_ fine: Int, _ segno: Character?) {
            var a = inizio, b = fine
            while a < b, c[a].isWhitespace { a += 1 }
            while b > a, c[b - 1].isWhitespace { b -= 1 }
            guard b - a >= 3 else { return }
            let t = String(c[a..<b])
            esito.append(Frase(testo: t, semplice: semplice(t), inizio: a, domanda: segno == "?"))
        }
        var i = 0
        while i < c.count {
            let x = c[i]
            if x == "\n" {
                chiudi(i, nil)
                inizio = i + 1
            } else if ".!?;…".contains(x), i + 1 == c.count || c[i + 1].isWhitespace {
                chiudi(i, x)
                inizio = i + 1
            }
            i += 1
        }
        if inizio < c.count { chiudi(c.count, nil) }
        return esito
    }

    // MARK: - Ricerca

    struct Trovato: Equatable {
        let gruppi: [String]
        let intervallo: IntervalloTesto
        /// Dove sta ogni gruppo (nil per un gruppo che non c'è).
        let intervalli: [IntervalloTesto?]
    }

    /// Tutte le corrispondenze dello schema nel testo (senza maiuscole), con i gruppi ("" per un gruppo vuoto).
    static func tutti(_ schema: String, _ t: String) -> [Trovato] {
        guard let re = try? NSRegularExpression(pattern: schema, options: [.caseInsensitive]) else { return [] }
        let ns = t as NSString
        return re.matches(in: t, range: NSRange(location: 0, length: ns.length)).compactMap { m -> Trovato? in
            guard let x = IntervalloTesto.da(m.range, in: t) else { return nil }
            let g = (0..<m.numberOfRanges).map { i -> String in
                let r = m.range(at: i)
                return r.location == NSNotFound ? "" : ns.substring(with: r)
            }
            let dove = (0..<m.numberOfRanges).map { IntervalloTesto.da(m.range(at: $0), in: t) }
            return Trovato(gruppi: g, intervallo: x, intervalli: dove)
        }
    }

    static func primo(_ schema: String, _ t: String) -> Trovato? { tutti(schema, t).first }

    /// Il testo con gli intervalli coperti da spazi (stessi caratteri): le regole dopo non rileggono le stesse cifre.
    private static func copri(_ t: String, _ x: IntervalloTesto) -> String {
        var a = Array(t)
        for k in x.inizio..<min(x.fine, a.count) { a[k] = " " }
        return String(a)
    }

    // MARK: - Cifre: importi

    struct Importo: Equatable {
        var valori: [Double]
        var frequenza: Frequenza?
        var intervallo: IntervalloTesto
    }

    private static let numeroNC = #"(?:\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?|\d+(?:,\d{1,2})?)"#
    private static let parteFrequenza = #"(?:\s+(?:di premio\s+|circa\s+)?(al mese|ogni mese|a mese|mensil\w*|al trimestre|trimestral\w*|al semestre|semestral\w*|all'anno|l'anno|ogni anno|annu\w*))?"#

    /// Gli importi in euro detti nella frase: elenchi («450, 550 e 650 euro al mese»), «40.000 euro», «40 mila
    /// euro», «€ 90», con la frequenza se c'è. Una cifra senza euro né «mila» (un anno, un'età) non è un importo.
    static func importi(_ t: String) -> [Importo] {
        var lavoro = t
        var esito: [Importo] = []
        // 1. Gli elenchi
        for m in tutti(#"(?<![\d.,])("# + numeroNC + #"(?:\s*,\s*"# + numeroNC + #")*\s+e\s+"# + numeroNC + #")\s*(?:€|euro\b)"# + parteFrequenza, lavoro) {
            let valori = tutti("(" + numeroNC + ")", m.gruppi[1]).compactMap { ScenariVera.euro($0.gruppi[1]) }
            guard valori.count >= 2 else { continue }
            esito.append(Importo(valori: valori, frequenza: frequenza(m.gruppi[2]), intervallo: m.intervallo))
            lavoro = copri(lavoro, m.intervallo)
        }
        // 2. Una cifra con «euro», «€» o «mila» dopo
        for m in tutti(#"(?<![\d.,])("# + numeroNC + #")\s*(?:(mila)\b\s*(?:€|euro\b)?|(€|euro\b))"# + parteFrequenza, lavoro) {
            guard let v = ScenariVera.euro(m.gruppi[1], m.gruppi[2]) else { continue }
            esito.append(Importo(valori: [v], frequenza: frequenza(m.gruppi[4]), intervallo: m.intervallo))
            lavoro = copri(lavoro, m.intervallo)
        }
        // 3. «€ 90»
        for m in tutti(#"€\s*("# + numeroNC + #")"# + parteFrequenza, lavoro) {
            guard let v = ScenariVera.euro(m.gruppi[1]) else { continue }
            esito.append(Importo(valori: [v], frequenza: frequenza(m.gruppi[2]), intervallo: m.intervallo))
        }
        return esito.sorted { $0.intervallo < $1.intervallo }
    }

    static func frequenza(_ s: String) -> Frequenza? {
        let t = s.lowercased()
        if t.isEmpty { return nil }
        if t.contains("mes") || t.hasPrefix("mensil") { return .mensile }
        if t.contains("trimestr") { return .trimestrale }
        if t.contains("semestr") { return .semestrale }
        if t.contains("ann") { return .annuale }
        return nil
    }

    // MARK: - Cifre: tempi

    struct Tempo: Equatable {
        var anniDaOggi: Int?
        var anno: Int?
        var mese: Int?
        var intervallo: IntervalloTesto
    }

    static let parolaNumero = "(\\d{1,2}|un|uno|una|due|tre|quattro|cinque|sei|sette|otto|nove|dieci|undici|dodici|quindici|venti|venticinque|trenta)"
    static let mesi = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"]

    /// «tre» → 3, «12» → 12.
    static func numero(_ parola: String) -> Int? {
        if let n = Int(parola) { return n }
        if parola == "una" { return 1 }
        return ScenariVera.numeriInLettere.first { $0.0 == parola }?.1
    }

    /// I tempi detti nella frase, in ordine: «tra tre anni», «anzi tra quattro», «a giugno del 2027», «nel 2030»,
    /// «l'anno prossimo». Anni fuori da oggi − 1 … oggi + 60 non valgono.
    static func tempi(_ t: String, annoOggi: Int) -> [Tempo] {
        var trovati: [Tempo] = []
        let elencoMesi = mesi.joined(separator: "|")
        for m in tutti(#"\b(?:tra|fra|entro|in) "# + parolaNumero + #" ann[oi]\b"#, t) {
            if let n = numero(m.gruppi[1]), (1...60).contains(n) { trovati.append(Tempo(anniDaOggi: n, intervallo: m.intervallo)) }
        }
        for m in tutti(#"\banzi,? (?:tra|fra) "# + parolaNumero + #"(?: ann[oi])?\b"#, t) {
            if let n = numero(m.gruppi[1]), (1...60).contains(n) { trovati.append(Tempo(anniDaOggi: n, intervallo: m.intervallo)) }
        }
        for m in tutti(#"\b(?:(?:a|ad|in|entro|nel mese di|a fine|per) )?("# + elencoMesi + #")(?: del| di| dell'anno)? (20\d\d)\b"#, t) {
            if let a = Int(m.gruppi[2]), let k = mesi.firstIndex(of: m.gruppi[1]), ((annoOggi - 1)...(annoOggi + 60)).contains(a) {
                trovati.append(Tempo(anno: a, mese: k + 1, intervallo: m.intervallo))
            }
        }
        for m in tutti(#"\b(?:nel|entro il|dal|per il|nell'anno) (20\d\d)\b"#, t) {
            if let a = Int(m.gruppi[1]), ((annoOggi - 1)...(annoOggi + 60)).contains(a) { trovati.append(Tempo(anno: a, intervallo: m.intervallo)) }
        }
        for m in tutti(#"\b(?:l'anno prossimo|il prossimo anno|l'anno che viene)\b"#, t) {
            trovati.append(Tempo(anniDaOggi: 1, intervallo: m.intervallo))
        }
        // Un tempo dentro un altro più lungo («tra quattro anni» dentro «anzi tra quattro anni») non conta due volte
        let senzaDoppi = trovati.filter { x in
            !trovati.contains { y in y != x && y.intervallo.inizio <= x.intervallo.inizio && y.intervallo.fine >= x.intervallo.fine && y.intervallo.lunghezza > x.intervallo.lunghezza }
        }
        return senzaDoppi.sorted { $0.intervallo < $1.intervallo }
    }

    // MARK: - Parole

    /// Le aree di vita, nell'ordine in cui contano (la pensione prima del lavoro, la casa prima del patrimonio).
    static let paroleArea: [(AreaBisogno, [String])] = [
        (.pensione, ["pensione", "pensionamento", "tfr", "contributi", "smettere di lavorare", "vecchiaia"]),
        (.casa, ["casa", "mutuo", "appartamento", "ristruttur", "trasloc", "immobile", "anticipo", "rogito", "trilocale", "bilocale", "villetta"]),
        (.famiglia, ["figli", "figlio", "figlia", "moglie", "marito", "compagna", "compagno", "famiglia", "bambin", "nipot", "matrimonio", "nozze", "universita"]),
        (.salute, ["salute", "malatt", "invalid", "ospedal", "cure", "imprevist", "autosufficien"]),
        (.lavoro, ["lavoro", "stipendio", "reddito", "azienda", "partita iva", "in proprio"]),
        (.patrimonio, ["eredita", "successione", "donazione", "investiment", "patrimonio", "rendita"]),
    ]

    static func area(_ t: String) -> AreaBisogno? {
        paroleArea.first { $0.1.contains { t.contains($0) } }?.0
    }

    static let desiderio = #"\b(?:vorrei|vorremmo|vorrebbe|vorrebbero|desider\w*|sogn\w*|(?:pens|contiam|progett|pianific)\w* di|ci piacerebbe|mi piacerebbe|(?:vogli\w*|dobbiamo|devo|dovremmo) (?:compr|acquist|prend|mett|risparm|cambi|ristruttur|far)\w*|compr\w*|acquist\w*|ci serv\w*|mi serv\w*|servir\w*|mettere da parte|risparmiare|obiettiv\w*)\b"#
    static let correzione = #"\b(?:anzi|pero|piuttosto|meglio)\b"#

    /// Le coperture, dalla più precisa: chiave nel testo semplice e nome da mostrare.
    static let tipiPolizza: [(String, String)] = [
        ("vita intera", "vita intera"), ("temporanea caso morte", "temporanea caso morte"), ("tcm", "TCM"), ("caso morte", "caso morte"),
        ("long term care", "LTC"), ("ltc", "LTC"), ("infortuni", "infortuni"), ("malattia", "malattia"),
        ("fondo pensione", "fondo pensione"), ("piano individuale pensionistico", "PIP"), ("pip", "PIP"),
        ("unit linked", "unit linked"), ("multiramo", "multiramo"), ("rivalutabile", "rivalutabile"), ("polizza vita", "polizza vita"),
    ]
    static let esterna = #"\b(?:con|presso|da|in|nella|alla|dalla) (?:un'altra|un altra|un'altra|l'altra|altra) (?:compagnia|assicurazione|agenzia)\b|\b(?:con|presso|in|dalla|alla|tramite) (?:la )?banca\b|\bda un altro (?:agente|consulente|assicuratore|intermediario)\b"#
    static let compagnie: [(String, String)] = [
        ("generali", "Generali"), ("allianz", "Allianz"), ("unipolsai", "UnipolSai"), ("unipol", "Unipol"), ("axa", "AXA"),
        ("zurich", "Zurich"), ("poste vita", "Poste Vita"), ("intesa sanpaolo", "Intesa Sanpaolo"), ("mediolanum", "Mediolanum"),
        ("reale mutua", "Reale Mutua"), ("cattolica", "Cattolica"), ("groupama", "Groupama"), ("helvetia", "Helvetia"),
        ("fideuram", "Fideuram"), ("credit agricole", "Crédit Agricole"),
    ]
    static let possesso = #"\b(?:ho|abbiamo|ha|hanno|avete|pago|paghiamo|paga|verso|versiamo|c'e|tengo|teniamo|gia)\b"#

    /// Timori e preferenze di rischio che valgono «prudente» (dati di prova finché il consulente non dà le sue frasi).
    static let timori = #"\bnon (?:voglio|vogliamo|vorrei|vorremmo) (?:rischi\w*|perder\w*)|\bsenza (?:rischi\w*|perder\w*)|(?<!non )\b(?:mi|ci) fa(?:nno)? paura\b|\b(?:ho|abbiamo) paura\b|\btranquill\w*|\bal sicuro\b|\bnon (?:posso|possiamo) permetter\w* di perder\w*|\bmi preoccup\w*|\bci preoccup\w*"#

    static let paroleEvento: [(EventoLineaVita.Tipo, String)] = [
        (.matrimonio, #"\b(?:ci )?spos\w*|\bmatrimonio\b|\bnozze\b"#),
        (.figlio, #"\bfiglio in arrivo\b|\baspett(?:iamo|o|a) un (?:bambin\w*|figli\w*)|\bincinta\b|\bin dolce attesa\b"#),
        (.studi, #"\buniversita\b|\bmaster\b|\bstudi (?:del|della|dei|delle) figli\w*"#),
        (.eredita, #"\beredit\w*|\bdonazione\b"#),
        (.pensione, #"\b(?:vado|andro|andra|andiamo|andremo|andare|andrei) in pensione\b|\bpensionamento\b|\bsmett\w* di lavorare\b"#),
        (.annoSabbatico, #"\banno sabbatico\b"#),
        (.casa, #"\brogito\b|\bci trasferiamo\b|\btrasloc\w*"#),
    ]

    /// Il consulente che dice cosa farà: «ti preparo», «le mando», «invio»… (con l'infinito per il titolo).
    static let verbi: [(String, String)] = [
        ("preparo", "Preparare"), ("preparero", "Preparare"), ("mando", "Mandare"), ("mandero", "Mandare"), ("invio", "Mandare"),
        ("inviero", "Mandare"), ("giro", "Mandare"), ("faccio avere", "Mandare"), ("porto", "Portare"), ("scrivo", "Scrivere"),
        ("chiamo", "Chiamare"), ("richiamo", "Chiamare"), ("sento", "Sentire"), ("fisso", "Fissare"), ("verifico", "Verificare"),
        ("controllo", "Controllare"), ("calcolo", "Calcolare"),
    ]
    static let infiniti = ["inviare", "mandare", "preparare", "verificare", "recuperare", "fissare", "chiamare", "richiedere", "valutare",
                           "confrontare", "aggiornare", "portare", "controllare", "rivedere", "presentare", "firmare"]
    private static var elencoVerbi: String { verbi.map(\.0).joined(separator: "|") }
    private static let apertura = #"^(?:(?:allora|perfetto|bene|ok|va bene|d'accordo|benissimo|si),?\s+)?"#

    // MARK: - Il pezzo

    /// Le schede di un pezzo di trascrizione con le sole regole di Prisma. `contesto.ultimaArea` si aggiorna con
    /// l'ultimo obiettivo citato.
    static func leggi(_ testo: String, pezzoId: String? = nil, contesto: inout ContestoCopilota) -> EsitoPezzoCopilota {
        var schede: [SchedaCopilota] = []
        var evidenze: [IntervalloTesto] = []
        for f in frasi(testo) where !f.domanda {
            let nuove = leggi(frase: f, pezzoId: pezzoId, contesto: &contesto)
            for s in nuove { evidenze += s.evidenze.map { $0.spostato(di: f.inizio) } }
            schede = unisci(schede, nuove)
        }
        return EsitoPezzoCopilota(schede: schede, evidenze: IntervalloTesto.unisci(evidenze))
    }

    /// Le schede di una frase (le evidenze sono dentro la frase).
    static func leggi(frase f: Frase, pezzoId: String?, contesto: inout ContestoCopilota) -> [SchedaCopilota] {
        let t = f.semplice
        let tempi = self.tempi(t, annoOggi: contesto.annoOggi)
        let importi = self.importi(t)
        var schede: [SchedaCopilota] = []
        func nuova(_ tipo: SchedaCopilota.Tipo, chiave: String, cifre: CifreCopilota, evidenze: [IntervalloTesto], titolo: String? = nil) -> SchedaCopilota {
            var s = SchedaCopilota(id: "\(tipo.rawValue)-\(chiave)", tipo: tipo, titolo: titolo ?? "", azione: .di(tipo), frase: f.testo,
                                   evidenze: IntervalloTesto.unisci(evidenze), pezzoId: pezzoId, cifre: cifre, origine: .regole)
            s = adatta(s, contesto: contesto)
            if titolo == nil { s.titolo = self.titolo(s) }
            return s
        }
        let tempo = tempi.last
        func conTempo(_ c: inout CifreCopilota) {
            guard let x = tempo else { return }
            c.anniDaOggi = x.anniDaOggi
            c.anno = x.anno
            c.mese = x.mese
        }

        // 1. La polizza di un'altra compagnia (prima dell'obiettivo: «pago 90 euro al mese» è un premio)
        let tipoPolizza = parola(tipiPolizza, in: t)
        let compagnia = parola(compagnie, in: t)
        let altrove = primo(esterna, t)
        var polizza = false
        if let tp = tipoPolizza, primo(#"\balleanza\b"#, t) == nil,
           altrove != nil || compagnia != nil || primo(possesso, t) != nil {
            let tipo = tp.0, dove = tp.1
            polizza = true
            var c = CifreCopilota()
            c.tipoPolizza = tipo
            c.compagnia = compagnia?.0
            var ev = [dove]
            if let x = altrove?.intervallo { ev.append(x) }
            if let x = compagnia?.1 { ev.append(x) }
            if let premio = importi.first(where: { $0.valori.count == 1 && $0.frequenza != nil }) ?? importi.first(where: { $0.valori.count == 1 }) {
                c.importo = premio.valori[0]
                c.frequenza = premio.frequenza
                ev.append(premio.intervallo)
            }
            let chiavePolizza = chiave(tipo)
            schede.append(nuova(.polizzaEsterna, chiave: chiavePolizza, cifre: c, evidenze: ev))
            // L'attività derivata: senza documento non si confronta
            schede.append(nuova(.attivita, chiave: "chiedere-polizza-\(chiavePolizza)", cifre: CifreCopilota(), evidenze: [dove],
                                titolo: "Chiedere la polizza \(tipo) per il confronto"))
        }

        // 2. L'obiettivo: un desiderio, un'area e una cifra o un tempo; oppure la correzione dell'ultimo obiettivo
        let areaFrase = area(t)
        let desiderio = primo(self.desiderio, t)
        let importoObiettivo = polizza ? nil : (importi.first { $0.valori.count == 1 && $0.frequenza == nil } ?? importi.first { $0.valori.count == 1 })
        var obiettivoTrovato = false
        if !polizza, desiderio != nil, let a = areaFrase, importoObiettivo != nil || tempo != nil {
            var c = CifreCopilota()
            c.area = a
            if let i = importoObiettivo { c.importo = i.valori[0]; c.frequenza = i.frequenza }
            conTempo(&c)
            let ev = [importoObiettivo?.intervallo, tempo?.intervallo].compactMap { $0 }
            schede.append(nuova(.obiettivo, chiave: a.rawValue, cifre: c, evidenze: ev))
            contesto.ultimaArea = a
            obiettivoTrovato = true
        } else if !polizza, let a = contesto.ultimaArea, primo(correzione, t) != nil, tempo != nil || importoObiettivo != nil,
                  areaFrase == nil || areaFrase == a {
            var c = CifreCopilota()
            c.area = a
            if let i = importoObiettivo { c.importo = i.valori[0]; c.frequenza = i.frequenza }
            conTempo(&c)
            let ev = [importoObiettivo?.intervallo, tempo?.intervallo].compactMap { $0 }
            schede.append(nuova(.obiettivo, chiave: a.rawValue, cifre: c, evidenze: ev))
            obiettivoTrovato = true
        }

        // 3. Il timore: prudente, legato all'area della frase o all'ultimo obiettivo
        if let timore = primo(timori, t) {
            var c = CifreCopilota()
            c.propensione = .prudente
            c.area = areaFrase ?? contesto.ultimaArea
            schede.append(nuova(.profilo, chiave: c.area?.rawValue ?? "generale", cifre: c, evidenze: [timore.intervallo]))
        }

        // 4. L'evento della vita
        // (un evento della stessa area dell'obiettivo appena trovato è lo stesso progetto: resta l'obiettivo)
        if let ev = evento(t), !(obiettivoTrovato && ev.0.area != nil && ev.0.area == areaFrase) {
            var c = CifreCopilota()
            c.evento = ev.0
            conTempo(&c)
            schede.append(nuova(.evento, chiave: ev.0.rawValue, cifre: c, evidenze: [ev.1, tempo?.intervallo].compactMap { $0 }))
        }

        // 5. Le attività del consulente
        if let a = attivita(f, importi: importi, oggi: contesto.oggi) {
            schede.append(a)
        }
        return schede.map { s in
            var x = s
            x.pezzoId = pezzoId
            return x
        }
    }

    /// La prima parola dell'elenco che compare nella frase (nome da mostrare e dove sta).
    static func parola(_ elenco: [(String, String)], in t: String) -> (String, IntervalloTesto)? {
        for voce in elenco {
            if let m = primo(#"\b"# + NSRegularExpression.escapedPattern(for: voce.0) + #"\b"#, t) { return (voce.1, m.intervallo) }
        }
        return nil
    }

    /// Il primo evento della vita detto nella frase, con la parola che lo dice.
    static func evento(_ t: String) -> (EventoLineaVita.Tipo, IntervalloTesto)? {
        for voce in paroleEvento {
            if let m = primo(voce.1, t) { return (voce.0, m.intervallo) }
        }
        return nil
    }

    /// «ti preparo un confronto con 450, 550 e 650 euro al mese» → «Preparare un confronto · 450 / 550 / 650 € al mese».
    static func attivita(_ f: Frase, importi: [Importo], oggi: Date) -> SchedaCopilota? {
        let t = f.semplice
        var verbo: String?
        var dopo = 0
        var evidenza: IntervalloTesto?
        if let m = primo(#"\b(?:ti|le|vi|gli|la|lo|te lo|ve lo|glielo|gliela) ("# + elencoVerbi + #")\b"#, t) ?? primo(apertura + #"(?:io\s+)?("# + elencoVerbi + #")\b"#, t) {
            verbo = verbi.first { $0.0 == m.gruppi[1] }?.1
            dopo = m.intervallo.fine
            evidenza = m.intervallo
        } else if let m = primo(apertura + "(" + infiniti.joined(separator: "|") + #")\b"#, t) {
            verbo = m.gruppi[1].prefix(1).uppercased() + m.gruppi[1].dropFirst()
            dopo = m.intervallo.fine
            evidenza = m.intervallo
        }
        guard let v = verbo else { return nil }
        // La scadenza detta, poi l'oggetto: le parole dopo il verbo (senza la scadenza) fino a «con», «per», una
        // virgola o la fine
        let sc = scadenza(t, oggi: oggi)
        let senzaScadenza = sc.map { copri(t, $0.1) } ?? t
        let coda = String(Array(senzaScadenza)[dopo...])
        var oggetto = ""
        if let m = primo(#"^\s*(.*?)(?=\s+(?:con|entro|per|da|e poi|cosi|che|appena)\b|[,;:]|$)"#, coda),
           m.intervalli.count > 1, let gruppo = m.intervalli[1],
           let originale = gruppo.spostato(di: dopo).testo(in: f.testo) {
            oggetto = originale.trimmingCharacters(in: .whitespaces)
            if oggetto.count > 60 {
                let corto = oggetto.prefix(60)
                oggetto = corto.lastIndex(of: " ").map { String(corto[..<$0]) } ?? String(corto)
            }
        }
        var titolo = oggetto.isEmpty ? v : "\(v) \(oggetto)"
        var c = CifreCopilota()
        var ev = [evidenza].compactMap { $0 }
        if let i = importi.first {
            titolo += " · " + i.valori.map { cifra($0) }.joined(separator: " / ") + " €" + dopoImporto(i.frequenza)
            if i.valori.count > 1 { c.importi = i.valori } else { c.importo = i.valori[0] }
            c.frequenza = i.frequenza
            ev.append(i.intervallo)
        }
        if let sc {
            c.scadenza = sc.0
            ev.append(sc.1)
        }
        return SchedaCopilota(id: "attivita-" + chiave(oggetto.isEmpty ? v : "\(v) \(oggetto)"), tipo: .attivita, titolo: titolo,
                              azione: .creaAttivita, frase: f.testo, evidenze: IntervalloTesto.unisci(ev), cifre: c, origine: .regole)
    }

    /// La scadenza detta: «entro venerdì», «domani», «la prossima settimana», «entro fine mese». Mai inventata.
    static func scadenza(_ t: String, oggi: Date) -> (Date, IntervalloTesto)? {
        let cal = Calendar(identifier: .gregorian)
        let giorno = cal.startOfDay(for: oggi)
        let giorni = ["domenica", "lunedi", "martedi", "mercoledi", "giovedi", "venerdi", "sabato"]
        if let m = primo(#"\bentro (lunedi|martedi|mercoledi|giovedi|venerdi|sabato|domenica)\b"#, t),
           let k = giorni.firstIndex(of: m.gruppi[1]) {
            let oggiSettimana = cal.component(.weekday, from: giorno)
            var mancano = (k + 1 - oggiSettimana + 7) % 7
            if mancano == 0 { mancano = 7 }
            return cal.date(byAdding: .day, value: mancano, to: giorno).map { ($0, m.intervallo) }
        }
        if let m = primo(#"\b(dopodomani|domani)\b"#, t) {
            return cal.date(byAdding: .day, value: m.gruppi[1] == "domani" ? 1 : 2, to: giorno).map { ($0, m.intervallo) }
        }
        if let m = primo(#"\b(?:entro )?la (?:prossima settimana|settimana prossima)\b"#, t) {
            return cal.date(byAdding: .day, value: 7, to: giorno).map { ($0, m.intervallo) }
        }
        if let m = primo(#"\bentro (?:la )?fine (?:del )?mese\b"#, t),
           let inizioMese = cal.date(from: cal.dateComponents([.year, .month], from: giorno)),
           let fine = cal.date(byAdding: DateComponents(month: 1, day: -1), to: inizioMese) {
            return (fine, m.intervallo)
        }
        return nil
    }

    // MARK: - Schede, titoli, unione

    /// L'azione secondo il dossier: l'obiettivo diventa «Aggiorna l’obiettivo» se il cliente ne ha già uno nell'area.
    static func adatta(_ s: SchedaCopilota, contesto: ContestoCopilota) -> SchedaCopilota {
        var x = s
        x.azione = .di(s.tipo)
        x.obiettivoId = nil
        if s.tipo == .obiettivo, let a = s.cifre.area, let o = contesto.obiettivi.first(where: { $0.area == a }) {
            x.azione = .aggiornaObiettivo
            x.obiettivoId = o.id
        }
        return x
    }

    /// Una chiave per gli id: minuscole senza accenti, trattini al posto degli spazi.
    static func chiave(_ s: String) -> String {
        let t = semplice(s).map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
        let compatto = t.replacingOccurrences(of: #"-+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return String(compatto.prefix(48))
    }

    /// «40000» → «40.000», «90,5» → «90,5».
    static func cifra(_ v: Double) -> String {
        Formati.numeroFormatter.string(from: NSNumber(value: v)) ?? String(Int(v))
    }

    static func dopoImporto(_ f: Frequenza?) -> String {
        switch f {
        case .mensile?: return " al mese"
        case .trimestrale?: return " al trimestre"
        case .semestrale?: return " al semestre"
        case .annuale?: return " l’anno"
        default: return ""
        }
    }

    static func nomeArea(_ a: AreaBisogno) -> String {
        switch a {
        case .casa: return "Casa"
        case .famiglia: return "Famiglia"
        case .lavoro: return "Lavoro"
        case .pensione: return "Pensione"
        case .salute: return "Salute"
        case .patrimonio: return "Patrimonio"
        }
    }

    /// «della casa», «per la pensione»: i soldi di cosa.
    static func soldiDi(_ a: AreaBisogno) -> String {
        switch a {
        case .casa: return "della casa"
        case .famiglia: return "per la famiglia"
        case .lavoro: return "del lavoro"
        case .pensione: return "per la pensione"
        case .salute: return "per la salute"
        case .patrimonio: return "del patrimonio"
        }
    }

    /// «tra 3 anni», «a giugno 2027», «nel 2030» (vuoto senza tempo).
    static func quando(_ c: CifreCopilota) -> String {
        if let n = c.anniDaOggi { return n == 1 ? "tra un anno" : "tra \(n) anni" }
        if let a = c.anno, let m = c.mese, (1...12).contains(m) { return "a \(mesi[m - 1]) \(a)" }
        if let a = c.anno { return "nel \(a)" }
        return ""
    }

    /// Il titolo con frasi fisse dalle cifre (le attività tengono il loro).
    static func titolo(_ s: SchedaCopilota) -> String {
        let c = s.cifre
        let importo = c.importo.map { cifra($0) + " €" + dopoImporto(c.frequenza) }
        switch s.tipo {
        case .obiettivo:
            let testa = ([c.area.map(nomeArea) ?? "Obiettivo", quando(c)].filter { !$0.isEmpty }).joined(separator: " ")
            return ([testa, importo].compactMap { $0 }).joined(separator: " · ")
        case .polizzaEsterna:
            let tipo = c.tipoPolizza.map { $0.prefix(1).uppercased() + $0.dropFirst() } ?? "Polizza"
            return ([tipo, c.compagnia ?? "altra compagnia", importo].compactMap { $0 }).joined(separator: " · ")
        case .profilo:
            return "Prudente" + (c.area.map { " sui soldi " + soldiDi($0) } ?? "")
        case .evento:
            let nome = c.evento?.nome ?? "Evento"
            let q = quando(c)
            return q.isEmpty ? nome : "\(nome) · \(q)"
        case .attivita:
            return s.titolo
        }
    }

    /// Le schede nuove dentro quelle che ci sono: la stessa cosa detta di nuovo aggiorna la scheda (cifre nuove
    /// dove ci sono). Una scheda scartata resta scartata; una confermata che cambia torna da confermare.
    static func unisci(_ esistenti: [SchedaCopilota], _ nuove: [SchedaCopilota]) -> [SchedaCopilota] {
        var esito = esistenti
        for n in nuove {
            guard let i = esito.firstIndex(where: { $0.id == n.id }) else {
                esito.append(n)
                continue
            }
            var x = esito[i]
            guard x.stato != .scartata else { continue }
            let cifre = x.cifre.aggiornate(con: n.cifre)
            let cambiano = cifre != x.cifre
            x.cifre = cifre
            if !n.frase.isEmpty {
                x.frase = n.frase
                x.evidenze = n.evidenze
                x.pezzoId = n.pezzoId
            }
            if n.azione == .aggiornaObiettivo, let o = n.obiettivoId {
                x.azione = .aggiornaObiettivo
                x.obiettivoId = o
            }
            x.titolo = x.tipo == .attivita ? (n.titolo.isEmpty ? x.titolo : n.titolo) : titolo(x)
            if x.stato == .confermata && cambiano { x.stato = .proposta }
            esito[i] = x
        }
        return esito
    }

    /// Le parole da illuminare in una frase qualsiasi (per le schede di Qwen): tempi, importi, coperture, compagnie,
    /// timori, eventi.
    static func evidenze(_ frase: String, annoOggi: Int) -> [IntervalloTesto] {
        let t = semplice(frase)
        var x = tempi(t, annoOggi: annoOggi).map(\.intervallo) + importi(t).map(\.intervallo)
        for (k, _) in tipiPolizza { if let m = primo(#"\b"# + NSRegularExpression.escapedPattern(for: k) + #"\b"#, t) { x.append(m.intervallo); break } }
        for (k, _) in compagnie { if let m = primo(#"\b"# + NSRegularExpression.escapedPattern(for: k) + #"\b"#, t) { x.append(m.intervallo) } }
        if let m = primo(esterna, t) { x.append(m.intervallo) }
        if let m = primo(timori, t) { x.append(m.intervallo) }
        for (_, schema) in paroleEvento { if let m = primo(schema, t) { x.append(m.intervallo) } }
        return IntervalloTesto.unisci(x)
    }

    // MARK: - Qwen: lo schema JSON

    /// Lo schema di Vera/Schemi/copilota.json dal pacchetto (in sviluppo e su iOS senza la cartella: quello qui sotto).
    static var schema: [String: Any] {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Schemi/copilota.json"),
           let d = try? Data(contentsOf: url), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] {
            return j
        }
        return schemaInterno
    }

    static let tipiJSON = ["obiettivo", "polizza", "profilo", "evento", "attivita"]
    static let areeJSON = ["casa", "famiglia", "lavoro", "pensione", "salute", "patrimonio", "nessuna"]
    static let frequenzeJSON = ["mensile", "trimestrale", "semestrale", "annuale", "unica", "nessuna"]
    static let propensioniJSON = ["prudente", "moderata", "dinamica", "aggressiva", "nessuna"]
    static let eventiJSON = ["matrimonio", "casa", "figlio", "studi", "eredita", "annoSabbatico", "pensione", "altro", "nessuno"]

    /// Lo stesso schema, nel codice (la prova controlla che coincida con quello della cartella Vera/Schemi).
    static let schemaInterno: [String: Any] = {
        var p: [String: Any] = [:]
        p["tipo"] = ["type": "string", "enum": RiconoscitoreCopilota.tipiJSON] as [String: Any]
        p["frase"] = ["type": "string"]
        p["area"] = ["type": "string", "enum": RiconoscitoreCopilota.areeJSON] as [String: Any]
        p["importo"] = ["type": "number"]
        p["importi"] = ["type": "array", "items": ["type": "number"]] as [String: Any]
        p["frequenza"] = ["type": "string", "enum": RiconoscitoreCopilota.frequenzeJSON] as [String: Any]
        p["anniDaOggi"] = ["type": "integer"]
        p["anno"] = ["type": "integer"]
        p["mese"] = ["type": "integer"]
        p["tipoPolizza"] = ["type": "string"]
        p["compagnia"] = ["type": "string"]
        p["propensione"] = ["type": "string", "enum": RiconoscitoreCopilota.propensioniJSON] as [String: Any]
        p["evento"] = ["type": "string", "enum": RiconoscitoreCopilota.eventiJSON] as [String: Any]
        p["attivita"] = ["type": "string"]
        let voce: [String: Any] = ["type": "object", "properties": p, "required": ["tipo", "frase"]]
        let schede: [String: Any] = ["type": "array", "items": voce]
        return ["type": "object", "properties": ["schede": schede], "required": ["schede"]]
    }()

    /// Le istruzioni di Vera/Istruzioni/copilota.md (con un ripiego minimo in sviluppo).
    static var istruzioni: String {
        IstruzioniVera.testo("copilota") ?? "Leggi un pezzo della trascrizione di un incontro tra un consulente finanziario e il suo cliente e rispondi solo con un oggetto JSON {\"schede\": [...]}: obiettivi (area, importo, anniDaOggi o anno e mese), polizze di altre compagnie (tipoPolizza, compagnia, importo, frequenza), timori sul rischio (propensione), eventi della vita (evento, anno, mese), attività del consulente (attivita). Per ogni scheda la frase esatta del testo. Solo cifre scritte nella frase: non inventare e non fare conti. Nessuna scheda per le domande."
    }

    /// La richiesta per Qwen: le istruzioni fisse, il contesto (cliente, obiettivi già nel dossier, ultimo obiettivo
    /// citato, anno in corso) e il pezzo.
    static func messaggi(pezzo: String, contesto: ContestoCopilota, cliente: String?) -> [MessaggioModello] {
        var righe = ["CONTESTO: anno in corso \(contesto.annoOggi)"]
        if let c = cliente, !c.isEmpty { righe.append("cliente: \(c)") }
        let aree = Array(Set(contesto.obiettivi.map(\.area.rawValue))).sorted()
        righe.append("obiettivi già nel dossier: " + (aree.isEmpty ? "nessuno" : aree.joined(separator: ", ")))
        if let a = contesto.ultimaArea { righe.append("ultimo obiettivo di cui si è parlato: \(a.rawValue)") }
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: righe.joined(separator: "; ") + ".\n\nPEZZO DELLA TRASCRIZIONE\n" + pezzo)]
    }

    /// Estrazione: niente fantasia, niente ragionamento, la stessa finestra delle altre risposte, risposta vincolata
    /// allo schema.
    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.massimoToken = 600
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    // MARK: - Qwen: la risposta

    /// Le schede del JSON di Qwen sul pezzo. Si scarta ogni scheda la cui frase non è nel pezzo o con una cifra che
    /// la frase non dice (importi, anni, mesi; i numeri del titolo dell'attività). nil se non c'è un oggetto JSON
    /// con «schede».
    static func leggiJSON(_ risposta: String, pezzo: String, pezzoId: String? = nil, contesto: ContestoCopilota) -> [SchedaCopilota]? {
        guard let inizio = risposta.firstIndex(of: "{"), let fine = risposta.lastIndex(of: "}"), inizio < fine,
              let d = String(risposta[inizio...fine]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let elenco = j["schede"] as? [Any] else { return nil }
        let pezzoSemplice = semplice(pezzo)
        var esito: [SchedaCopilota] = []
        for case let voce as [String: Any] in elenco {
            guard let s = scheda(voce, pezzoSemplice: pezzoSemplice, pezzoId: pezzoId, contesto: contesto) else { continue }
            esito = unisci(esito, [s])
        }
        return esito
    }

    private static func scheda(_ v: [String: Any], pezzoSemplice: String, pezzoId: String?, contesto: ContestoCopilota) -> SchedaCopilota? {
        func testo(_ k: String) -> String? {
            (v[k] as? String).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 }
        }
        func numero(_ k: String) -> Double? {
            if let n = v[k] as? NSNumber { return CFGetTypeID(n) == CFBooleanGetTypeID() ? nil : n.doubleValue }
            if let s = v[k] as? String { return ScenariVera.euro(s) }
            return nil
        }
        func intero(_ k: String) -> Int? { numero(k).map { Int($0.rounded()) } }
        guard let tipoJSON = testo("tipo"), let frase = testo("frase") else { return nil }
        let fraseSemplice = semplice(frase)
        // La frase deve essere davvero nel pezzo (i modelli piccoli a volte la riscrivono)
        guard fraseSemplice.count >= 3, pezzoSemplice.contains(fraseSemplice) else { return nil }
        let numeri = numeriDetti(fraseSemplice)
        let annoOggi = contesto.annoOggi
        var c = CifreCopilota()
        // Zeri e valori vuoti che i modelli piccoli scrivono al posto di «non c'è»
        c.importo = numero("importo").flatMap { $0 == 0 ? nil : $0 }
        c.importi = (v["importi"] as? [Any])?.compactMap { ($0 as? NSNumber)?.doubleValue }.filter { $0 != 0 }
        if c.importi?.isEmpty == true { c.importi = nil }
        c.anniDaOggi = intero("anniDaOggi").flatMap { $0 == 0 ? nil : $0 }
        c.anno = intero("anno").flatMap { $0 == 0 ? nil : $0 }
        c.mese = intero("mese").flatMap { (1...12).contains($0) ? $0 : nil }
        c.frequenza = testo("frequenza").flatMap(Frequenza.init(rawValue:))
        c.area = testo("area").flatMap(AreaBisogno.init(rawValue:))
        c.propensione = testo("propensione").flatMap(ProfiloInvestitore.Propensione.init(rawValue:))
        c.evento = testo("evento").flatMap(EventoLineaVita.Tipo.init(rawValue:))
        c.tipoPolizza = testo("tipoPolizza")
        c.compagnia = testo("compagnia").flatMap { semplice($0).contains("altra") ? nil : $0 }
        // Le cifre devono essere nella frase
        if let x = c.importo, !numeri.contains(x) { return nil }
        if let x = c.importi, !x.allSatisfy({ numeri.contains($0) }) { return nil }
        if let x = c.anniDaOggi, !numeri.contains(Double(x)) { return nil }
        if let a = c.anno, !numeri.contains(Double(a)), !(a > annoOggi && numeri.contains(Double(a - annoOggi))) { return nil }
        if let m = c.mese, !mesiDetti(fraseSemplice).contains(m) { return nil }
        if c.anniDaOggi != nil && c.anno != nil { c.anno = nil; c.mese = nil }
        let evidenze = self.evidenze(frase, annoOggi: annoOggi)
        var s: SchedaCopilota
        switch tipoJSON {
        case "obiettivo":
            guard let a = c.area, c.importo != nil || c.anniDaOggi != nil || c.anno != nil else { return nil }
            s = SchedaCopilota(id: "obiettivo-\(a.rawValue)", tipo: .obiettivo, titolo: "", azione: .creaObiettivo, frase: frase, evidenze: evidenze)
        case "polizza":
            guard let tipo = c.tipoPolizza else { return nil }
            let nota = tipiPolizza.first { semplice(tipo) == $0.0 }?.1 ?? tipo
            c.tipoPolizza = nota
            s = SchedaCopilota(id: "polizzaEsterna-\(chiave(nota))", tipo: .polizzaEsterna, titolo: "", azione: .aggiungiPosizione, frase: frase, evidenze: evidenze)
        case "profilo":
            guard c.propensione != nil else { return nil }
            if c.area == nil { c.area = contesto.ultimaArea }
            s = SchedaCopilota(id: "profilo-\(c.area?.rawValue ?? "generale")", tipo: .profilo, titolo: "", azione: .annotaProfilo, frase: frase, evidenze: evidenze)
        case "evento":
            guard let e = c.evento else { return nil }
            s = SchedaCopilota(id: "evento-\(e.rawValue)", tipo: .evento, titolo: "", azione: .aggiungiLineaVita, frase: frase, evidenze: evidenze)
        case "attivita":
            guard let titolo = testo("attivita"), titolo.count <= 90, CommentoVera.numeriConservati(bozza: frase, testo: titolo) else { return nil }
            let t = titolo.prefix(1).uppercased() + titolo.dropFirst()
            s = SchedaCopilota(id: "attivita-\(chiave(t))", tipo: .attivita, titolo: t, azione: .creaAttivita, frase: frase, evidenze: evidenze)
        default:
            return nil
        }
        s.cifre = c
        s.pezzoId = pezzoId
        s.origine = .qwen
        s = adatta(s, contesto: contesto)
        if s.tipo != .attivita { s.titolo = titolo(s) }
        return s
    }

    /// I numeri detti nella frase (cifre all'italiana, «40 mila», i numeri in lettere: «tra tre anni»).
    static func numeriDetti(_ t: String) -> Set<Double> {
        var x = Set<Double>()
        for m in tutti(#"(\d[\d.,]*\d|\d)(?:\s*(mila)\b)?"#, t) {
            if let v = ScenariVera.euro(m.gruppi[1]) {
                x.insert(v)
                if !m.gruppi[2].isEmpty { x.insert(v * 1_000) }
            }
        }
        for m in tutti(#"\b"# + parolaNumero + #"\b"#, t) {
            if let n = numero(m.gruppi[1]) { x.insert(Double(n)) }
        }
        return x
    }

    /// I mesi nominati nella frase (1…12).
    static func mesiDetti(_ t: String) -> Set<Int> {
        Set(mesi.indices.filter { t.range(of: "\\b\(mesi[$0])\\b", options: .regularExpression) != nil }.map { $0 + 1 })
    }

    /// Le schede di Qwen con quelle delle regole: sulle stesse cose vincono le regole (le cifre lette dalla frase),
    /// Qwen completa le cifre che mancano e aggiunge quello che le regole non trovano.
    static func conQwen(regole: [SchedaCopilota], modello: [SchedaCopilota]) -> [SchedaCopilota] {
        var esito = regole
        for m in modello {
            if let i = esito.firstIndex(where: { $0.id == m.id }) {
                esito[i].cifre = esito[i].cifre.completate(con: m.cifre)
                if esito[i].tipo != .attivita { esito[i].titolo = titolo(esito[i]) }
            } else {
                esito.append(m)
            }
        }
        return esito
    }
}
