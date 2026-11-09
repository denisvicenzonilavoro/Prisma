import Foundation

// Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.5.2 punto 2, «Luce» giro 6, decisione 93):
// l'indice locale dei documenti della Biblioteca. Ogni pagina si divide in passi (paragrafi; se la pagina non ne ha,
// finestre di circa 120 parole che si sovrappongono di 20), ognuno con l'ultima intestazione vista sopra («Art. 9 –
// Riscatto»). La ricerca è BM25 su parole normalizzate (minuscole, senza accenti, parole vuote tolte, radice corta:
// «riscatto», «riscattare» → «riscatt»), con un premio se la parola è nell'intestazione o nel titolo. Niente vettori,
// niente dipendenze. L'indice è derivato: si costruisce dai testi fuori dal thread principale e sta solo in memoria.
// Qui c'è anche la verifica della frase di Vera (deve stare parola per parola nel passo) e l'avviso sui parametri di
// Prisma che una citazione contraddice (decisione 7).

struct PassoBiblioteca: Equatable, Identifiable {
    var documentoId: String
    /// La pagina, da 1.
    var pagina: Int
    /// Il numero del passo nella pagina, da 1.
    var numero: Int
    var testo: String
    /// L'ultimo titolo visto sopra il passo («Art. 9 – Riscatto»), anche da una pagina precedente; "" se non c'è.
    var intestazione: String
    /// La posizione del passo nel testo della pagina (in caratteri).
    var inizio: Int

    var id: String { "\(documentoId)#\(pagina)#\(numero)" }

    /// «Art. 9 · Riscatto» (il trattino dell'intestazione diventa il punto in mezzo).
    var intestazioneVista: String {
        intestazione.replacingOccurrences(of: " – ", with: " · ").replacingOccurrences(of: " - ", with: " · ")
            .replacingOccurrences(of: " — ", with: " · ")
    }
}

/// Un passo trovato, con il suo punteggio.
struct PassoTrovato: Equatable {
    var passo: PassoBiblioteca
    var punteggio: Double
}

/// L'indice delle parole, in memoria.
struct IndiceBiblioteca {
    let passi: [PassoBiblioteca]
    fileprivate let frequenze: [[String: Int]]
    fileprivate let lunghezze: [Int]
    fileprivate let paroleIntestazione: [Set<String>]
    fileprivate let paroleTitolo: [String: Set<String>]
    fileprivate let presenza: [String: Int]
    fileprivate let media: Double
    /// Le pagine lette di tutti i documenti indicizzati («ho cercato in N pagine»).
    let pagine: Int
    let documenti: Int
    /// I documenti lasciati fuori dal tetto della memoria («Indice parziale: 140 di 200 documenti»).
    let esclusi: Int
    /// I documenti e le pagine da cui è nato: se cambiano, l'indice si rifà.
    let firma: String

    static let vuoto = IndiceBiblioteca(passi: [], frequenze: [], lunghezze: [], paroleIntestazione: [], paroleTitolo: [:],
                                        presenza: [:], media: 1, pagine: 0, documenti: 0, esclusi: 0, firma: "")
}

enum MotoreBiblioteca {
    /// Circa 120 parole per finestra, 20 in comune con la successiva (pagine senza paragrafi).
    static let paroleFinestra = 120
    static let sovrapposizione = 20
    /// I passi dati a Vera.
    static let quanti = 6
    /// Il tetto dell'indice in memoria: oltre si indicizzano i documenti più recenti (Mac da 8 GB).
    static let tettoCaratteri = 60_000_000

    // MARK: - Parole

    private static let vuote: Set<String> = [
        "il", "lo", "la", "i", "gli", "le", "un", "uno", "una", "di", "da", "in", "su", "per", "con", "tra", "fra", "a", "e", "o",
        "del", "della", "dello", "dei", "degli", "delle", "al", "alla", "allo", "ai", "agli", "alle", "dal", "dalla", "dallo",
        "dai", "dagli", "dalle", "nel", "nella", "nello", "nei", "negli", "nelle", "sul", "sulla", "sullo", "sui", "sugli",
        "sulle", "che", "chi", "cui", "non", "ne", "ci", "si", "se", "ma", "anche", "come", "dove", "quando", "quanto", "quanta",
        "quanti", "quante", "qual", "quale", "quali", "cosa", "cos", "questo", "questa", "questi", "queste", "quello", "quella", "quelli",
        "quelle", "suo", "sua", "suoi", "sue", "mio", "mia", "tuo", "tua", "loro", "ogni", "essere", "sono", "era", "sia", "siano",
        "ha", "hanno", "ho", "hai", "abbia", "puo", "possono", "deve", "devono", "viene", "vengono", "piu", "meno", "gia", "poi",
        "dopo", "prima", "entro", "fino", "oltre", "senza", "verso", "art", "articolo", "pagina", "comma", "lett", "dei",
    ]

    private static let suffissi = ["ibilita", "abilita", "azione", "azioni", "amento", "amenti", "imento", "imenti", "mente",
                                   "abile", "abili", "ibile", "ibili", "ando", "endo", "are", "ere", "ire", "ato", "ata", "ati",
                                   "ate", "ito", "ita", "iti", "ite", "uto", "uta", "uti", "ute"]

    /// La radice corta di una parola già minuscola e senza accenti: i suffissi più comuni dell'italiano e l'ultima vocale.
    static func radice(_ parola: String) -> String {
        guard parola.count > 3, parola.allSatisfy(\.isLetter) else { return parola }
        var p = parola
        for s in suffissi where p.hasSuffix(s) && p.count - s.count >= 3 {
            p = String(p.dropLast(s.count))
            break
        }
        if p.count > 3, let ultima = p.last, "aeiou".contains(ultima) { p.removeLast() }
        if p.count > 3, p.hasSuffix("h") { p.removeLast() }
        return p
    }

    /// Le parole significative di un testo, normalizzate.
    static func parole(_ testo: String) -> [String] {
        let piegato = testo.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
        return piegato.split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 2 && !vuote.contains($0) }
            .map(radice)
    }

    /// Le parole minuscole e senza accenti, intere (per i nomi propri).
    static func paroleSemplici(_ testo: String) -> [String] {
        testo.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
            .split { !$0.isLetter }.map(String.init)
    }

    // MARK: - Passi

    private static let schemaIntestazione = try? NSRegularExpression(
        pattern: #"^\s*(Art\.|Articolo|ART\.|ARTICOLO|Paragrafo|PARAGRAFO|Sezione|SEZIONE|Capitolo|CAPITOLO|[IVXLC]{1,6}[.)]\s)"#)

    /// Una riga che fa da titolo: «Art.», «Articolo», «Paragrafo», «Sezione», un numero romano; corta.
    static func eIntestazione(_ riga: String) -> Bool {
        let r = riga.trimmingCharacters(in: .whitespaces)
        guard !r.isEmpty, r.count <= 90, let re = schemaIntestazione else { return false }
        return re.firstMatch(in: r, range: NSRange(location: 0, length: (r as NSString).length)) != nil
    }

    /// I passi di un documento, pagina per pagina. Le intestazioni restano valide anche nelle pagine dopo.
    static func passi(pagine: [String], documentoId: String) -> [PassoBiblioteca] {
        var risultato: [PassoBiblioteca] = []
        var intestazione = ""
        for (i, pagina) in pagine.enumerated() {
            var numero = 0
            var blocchi = paragrafi(pagina)
            // Una pagina senza righe vuote (PDF che vanno a capo a ogni riga): finestre di parole
            if blocchi.count <= 1, let unico = blocchi.first, unico.testo.split(whereSeparator: \.isWhitespace).count > paroleFinestra + sovrapposizione {
                blocchi = finestre(unico)
            }
            for b in blocchi {
                // Le righe d'intestazione dentro il blocco aggiornano il titolo; il resto è il passo
                var corpo: [String] = []
                for riga in b.testo.components(separatedBy: "\n") {
                    if eIntestazione(riga) {
                        intestazione = riga.trimmingCharacters(in: .whitespaces)
                    } else {
                        corpo.append(riga)
                    }
                }
                let testo = corpo.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                guard testo.count >= 20 else { continue }
                numero += 1
                risultato.append(PassoBiblioteca(documentoId: documentoId, pagina: i + 1, numero: numero, testo: testo,
                                                 intestazione: intestazione, inizio: b.inizio))
            }
        }
        return risultato
    }

    /// I paragrafi di una pagina (separati da righe vuote), con la loro posizione.
    static func paragrafi(_ pagina: String) -> [(testo: String, inizio: Int)] {
        var r: [(String, Int)] = []
        var corrente: [String] = []
        var inizio = 0
        var posizione = 0
        for riga in pagina.components(separatedBy: "\n") {
            if riga.trimmingCharacters(in: .whitespaces).isEmpty {
                if !corrente.isEmpty { r.append((corrente.joined(separator: "\n"), inizio)) }
                corrente = []
            } else {
                if corrente.isEmpty { inizio = posizione }
                corrente.append(riga)
            }
            posizione += riga.count + 1
        }
        if !corrente.isEmpty { r.append((corrente.joined(separator: "\n"), inizio)) }
        return r
    }

    private static func finestre(_ b: (testo: String, inizio: Int)) -> [(testo: String, inizio: Int)] {
        let parole = b.testo.split(whereSeparator: \.isWhitespace).map(String.init)
        var r: [(String, Int)] = []
        var i = 0
        var posizione = b.inizio
        while i < parole.count {
            let fine = min(parole.count, i + paroleFinestra)
            r.append((parole[i..<fine].joined(separator: " "), posizione))
            if fine == parole.count { break }
            posizione += parole[i..<(fine - sovrapposizione)].reduce(0) { $0 + $1.count + 1 }
            i = fine - sovrapposizione
        }
        return r
    }

    // MARK: - Indice

    /// Un documento da indicizzare: le pagine e il titolo (le sue parole valgono come premio, non da sole).
    struct Fonte {
        let id: String
        let titolo: String
        let pagine: [String]
        var importatoIl = Date.distantPast
    }

    /// L'indice dei documenti (fuori dal thread principale). Oltre il tetto entrano i documenti più recenti.
    static func indice(_ fonti: [Fonte], tetto: Int = tettoCaratteri) -> IndiceBiblioteca {
        var scelte: [Fonte] = []
        var caratteri = 0
        for f in fonti.sorted(by: { $0.importatoIl > $1.importatoIl }) {
            let n = f.pagine.reduce(0) { $0 + $1.count }
            if caratteri + n > tetto, !scelte.isEmpty { continue }
            caratteri += n
            scelte.append(f)
        }
        let ordine = fonti.map(\.id)
        scelte.sort { (ordine.firstIndex(of: $0.id) ?? 0) < (ordine.firstIndex(of: $1.id) ?? 0) }
        var passi: [PassoBiblioteca] = []
        var titoli: [String: Set<String>] = [:]
        for f in scelte {
            passi += Self.passi(pagine: f.pagine, documentoId: f.id)
            titoli[f.id] = Set(parole(f.titolo))
        }
        var frequenze: [[String: Int]] = []
        var lunghezze: [Int] = []
        var intestazioni: [Set<String>] = []
        var presenza: [String: Int] = [:]
        frequenze.reserveCapacity(passi.count)
        for p in passi {
            let ps = parole(p.testo)
            var f: [String: Int] = [:]
            for x in ps { f[x, default: 0] += 1 }
            for x in f.keys { presenza[x, default: 0] += 1 }
            frequenze.append(f)
            lunghezze.append(ps.count)
            intestazioni.append(Set(parole(p.intestazione)))
        }
        let media = max(1, Double(lunghezze.reduce(0, +)) / Double(max(1, lunghezze.count)))
        let firma = fonti.map { "\($0.id):\($0.pagine.count):\($0.titolo)" }.joined(separator: "|")
        return IndiceBiblioteca(passi: passi, frequenze: frequenze, lunghezze: lunghezze, paroleIntestazione: intestazioni,
                                paroleTitolo: titoli, presenza: presenza, media: media,
                                pagine: scelte.reduce(0) { $0 + $1.pagine.count }, documenti: scelte.count,
                                esclusi: fonti.count - scelte.count, firma: firma)
    }

    /// I passi più pertinenti (BM25, k1 = 1,2, b = 0,75), con il premio per intestazione (metà dell'idf) e titolo
    /// (un quarto). Entra solo un passo che ha almeno una parola della domanda nel suo testo o nell'intestazione: meglio
    /// «non trovata» che un passo a caso.
    static func cerca(_ domanda: String, in indice: IndiceBiblioteca, quanti: Int = quanti) -> [PassoTrovato] {
        let q = Set(parole(domanda))
        guard !q.isEmpty, !indice.passi.isEmpty else { return [] }
        let n = Double(indice.passi.count)
        func idf(_ x: String) -> Double {
            let df = Double(indice.presenza[x] ?? 0)
            return log(1 + (n - df + 0.5) / (df + 0.5))
        }
        var trovati: [PassoTrovato] = []
        for (i, p) in indice.passi.enumerated() {
            var punti = 0.0
            var corpo = false
            for x in q {
                if let f = indice.frequenze[i][x] {
                    let ff = Double(f)
                    punti += idf(x) * ff * 2.2 / (ff + 1.2 * (0.25 + 0.75 * Double(indice.lunghezze[i]) / indice.media))
                    corpo = true
                }
                if indice.paroleIntestazione[i].contains(x) {
                    punti += 0.5 * idf(x)
                    corpo = true
                }
                if indice.paroleTitolo[p.documentoId]?.contains(x) == true { punti += 0.25 * idf(x) }
            }
            if corpo, punti > 0 { trovati.append(PassoTrovato(passo: p, punteggio: punti)) }
        }
        return Array(trovati.sorted { $0.punteggio != $1.punteggio ? $0.punteggio > $1.punteggio : $0.passo.id < $1.passo.id }.prefix(quanti))
    }

    /// Le pagine più vicine, una per pagina (per lo stato «non trovata»).
    static func pagineVicine(_ trovati: [PassoTrovato], quante: Int = 3) -> [PassoBiblioteca] {
        var viste = Set<String>()
        var r: [PassoBiblioteca] = []
        for t in trovati where viste.insert("\(t.passo.documentoId)#\(t.passo.pagina)").inserted {
            r.append(t.passo)
            if r.count == quante { break }
        }
        return r
    }

    // MARK: - La frase dentro il passo

    /// Il testo per il confronto: minuscolo, senza accenti, spazi e a capo ridotti a uno, sillabazioni a fine riga
    /// ricucite («ri-\nscatto» → «riscatto»), virgolette e apostrofi tipografici resi semplici. Con la posizione nel
    /// testo originale di ogni carattere normalizzato.
    static func normalizzaConPosizioni(_ testo: String) -> (testo: [Character], posizioni: [String.Index]) {
        var out: [Character] = []
        var pos: [String.Index] = []
        var i = testo.startIndex
        var spazio = false
        while i < testo.endIndex {
            let c = testo[i]
            let dopo = testo.index(after: i)
            // Sillabazione: «-» seguito da a capo (con spazi) si salta insieme all'a capo
            if c == "-" || c == "\u{00AD}" {
                var j = dopo
                while j < testo.endIndex, testo[j] == " " || testo[j] == "\t" { j = testo.index(after: j) }
                if j < testo.endIndex, testo[j].isNewline {
                    i = testo.index(after: j)
                    while i < testo.endIndex, testo[i].isWhitespace { i = testo.index(after: i) }
                    continue
                }
            }
            if c.isWhitespace {
                if !spazio, !out.isEmpty { out.append(" "); pos.append(i) }
                spazio = true
                i = dopo
                continue
            }
            spazio = false
            let semplice: String
            switch c {
            case "’", "‘", "`", "´": semplice = "'"
            case "“", "”", "«", "»", "„": semplice = "\""
            case "–", "—": semplice = "-"
            default:
                semplice = String(c).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
            }
            for s in semplice { out.append(s); pos.append(i) }
            i = dopo
        }
        while out.last == " " { out.removeLast(); pos.removeLast() }
        return (out, pos)
    }

    /// La frase pulita dalle virgolette che Qwen a volte aggiunge intorno e dai puntini finali.
    static func frasePulita(_ frase: String) -> String {
        var f = frase.trimmingCharacters(in: .whitespacesAndNewlines)
        let attorno: Set<Character> = ["\"", "«", "»", "“", "”", "'"]
        while let p = f.first, attorno.contains(p) { f.removeFirst() }
        while let u = f.last, attorno.contains(u) { f.removeLast() }
        while f.hasSuffix("…") || f.hasSuffix("...") { f = String(f.dropLast(f.hasSuffix("…") ? 1 : 3)) }
        return f.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Dove sta la frase nel testo, parola per parola (nil se non c'è). Le frasi troppo corte non valgono come citazione.
    static func intervallo(_ frase: String, in testo: String) -> Range<String.Index>? {
        let f = normalizzaConPosizioni(frasePulita(frase)).testo
        guard f.count >= 12 else { return nil }
        let t = normalizzaConPosizioni(testo)
        guard t.testo.count >= f.count else { return nil }
        let ultimo = t.testo.count - f.count
        var k = 0
        while k <= ultimo {
            if t.testo[k] == f[0] {
                var j = 1
                while j < f.count, t.testo[k + j] == f[j] { j += 1 }
                if j == f.count {
                    let inizio = t.posizioni[k]
                    let fine = testo.index(after: t.posizioni[k + f.count - 1])
                    return inizio..<fine
                }
            }
            k += 1
        }
        return nil
    }

    /// La verifica di Prisma: la frase sta dentro il passo indicato.
    static func fraseNelPasso(_ frase: String, _ passo: PassoBiblioteca) -> Bool {
        intervallo(frase, in: passo.testo) != nil
    }

    // MARK: - Parametri di Prisma superati (decisione 7)

    /// Un parametro dei motori di Prisma che una citazione può contraddire: le parole che lo riconoscono e il valore.
    struct Parametro {
        let parole: [String]
        let valore: Double
        let testo: String
        /// L'intervallo in cui una cifra del passo è plausibilmente lo stesso parametro.
        let minimo: Double
        let massimo: Double
        let percentuale: Bool
    }

    static var parametri: [Parametro] {
        [Parametro(parole: ["deduc", "dedurre", "deduzione"], valore: RegoleFiscali.limiteDeducibilita,
                   testo: "Prisma usa \(Formati.euro(RegoleFiscali.limiteDeducibilita)) l'anno per la deducibilità dei contributi (dal 2026)",
                   minimo: 1_000, massimo: 20_000, percentuale: false)]
    }

    /// L'avviso se il testo (la frase o il passo citato) parla di un parametro di Prisma con una cifra diversa.
    /// Il parametro resta quello di Prisma: la Biblioteca non lo cambia mai.
    static func avvisoParametri(_ testo: String) -> String? {
        let piegato = testo.lowercased()
        for p in parametri where p.parole.contains(where: { piegato.contains($0) }) {
            let cifre = numeri(testo, percentuali: p.percentuale).filter { $0 >= p.minimo && $0 <= p.massimo }
            guard !cifre.isEmpty, !cifre.contains(where: { abs($0 - p.valore) < 0.005 }) else { continue }
            return "Attenzione: \(p.testo); il documento potrebbe essere superato."
        }
        return nil
    }

    /// I numeri scritti all'italiana («5.164,57», «1.000», «26%»).
    static func numeri(_ testo: String, percentuali: Bool) -> [Double] {
        let schema = percentuali ? #"[0-9]+(?:,[0-9]+)?\s?%"# : #"[0-9]{1,3}(?:\.[0-9]{3})+(?:,[0-9]+)?|[0-9]+(?:,[0-9]+)?"#
        guard let re = try? NSRegularExpression(pattern: schema) else { return [] }
        let ns = testo as NSString
        return re.matches(in: testo, range: NSRange(location: 0, length: ns.length)).compactMap { m in
            let s = ns.substring(with: m.range).replacingOccurrences(of: "%", with: "").replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            return Double(s)
        }
    }
}

// MARK: - Edizioni e prodotti (§8.1.6 punto 3, §8.1.5.2 punto 6)

extension MotoreBiblioteca {
    private static let mesi = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto",
                               "settembre", "ottobre", "novembre", "dicembre"]

    /// L'edizione scritta come un numero da confrontare (aaaammgg; mese e giorno a 0 se mancano): «ed. 03/2026» →
    /// 20260300, «aggiornato al 1° ottobre 2026» → 20261001, «12/05/2025» → 20250512, «2024» → 20240000. Un'edizione
    /// che non dice una data: nil (non si confronta, mai indovinata).
    static func chiaveEdizione(_ edizione: String) -> Int? {
        let t = edizione.lowercased()
        func numero(_ r: NSTextCheckingResult, _ i: Int, in s: NSString) -> Int? {
            guard r.range(at: i).location != NSNotFound else { return nil }
            return Int(s.substring(with: r.range(at: i)))
        }
        let s = t as NSString
        let tutto = NSRange(location: 0, length: s.length)
        func valida(_ a: Int, _ m: Int, _ g: Int) -> Int? {
            guard (1900...2200).contains(a), (0...12).contains(m), (0...31).contains(g) else { return nil }
            return a * 10_000 + m * 100 + g
        }
        // 12/05/2025, 12.05.2025, 12/05/25
        if let re = try? NSRegularExpression(pattern: #"\b([0-9]{1,2})[/.]([0-9]{1,2})[/.]([0-9]{2,4})\b"#),
           let r = re.firstMatch(in: t, range: tutto),
           let g = numero(r, 1, in: s), let m = numero(r, 2, in: s), var a = numero(r, 3, in: s) {
            if a < 100 { a += 2000 }
            return valida(a, m, g)
        }
        // 03/2026
        if let re = try? NSRegularExpression(pattern: #"\b([0-9]{1,2})[/.]([0-9]{4})\b"#),
           let r = re.firstMatch(in: t, range: tutto), let m = numero(r, 1, in: s), let a = numero(r, 2, in: s) {
            return valida(a, m, 0)
        }
        // 1° ottobre 2026, ottobre 2026
        let nomi = mesi.joined(separator: "|")
        if let re = try? NSRegularExpression(pattern: #"(?:\b([0-9]{1,2})°?\s+)?\b("# + nomi + #")\s+([0-9]{4})\b"#),
           let r = re.firstMatch(in: t, range: tutto), let a = numero(r, 3, in: s) {
            let mese = (mesi.firstIndex(of: s.substring(with: r.range(at: 2))) ?? -1) + 1
            return valida(a, mese, numero(r, 1, in: s) ?? 0)
        }
        // 2024
        if let re = try? NSRegularExpression(pattern: #"\b(19[0-9]{2}|2[01][0-9]{2})\b"#),
           let r = re.firstMatch(in: t, range: tutto), let a = numero(r, 1, in: s) {
            return valida(a, 0, 0)
        }
        return nil
    }

    /// Gli altri documenti dello stesso prodotto con un'edizione diversa.
    static func altreEdizioni(_ d: DocumentoBiblioteca, tra documenti: [DocumentoBiblioteca]) -> [DocumentoBiblioteca] {
        guard let prodotto = d.prodottoId else { return [] }
        let mia = d.edizione.trimmingCharacters(in: .whitespaces).lowercased()
        return documenti.filter { x in
            x.id != d.id && x.prodottoId == prodotto && x.edizione.trimmingCharacters(in: .whitespaces).lowercased() != mia
        }
    }

    /// L'avviso sotto l'edizione della risposta (§8.1.6 punto 3): se lo stesso prodotto ha un documento di un'edizione
    /// più vecchia, «C'è anche un'edizione più vecchia: …»; se ce n'è una più recente lo dice per prima (la risposta può
    /// essere superata); se le date non si confrontano, «C'è anche un'altra edizione: …». Nessun prodotto collegato: nil.
    static func avvisoEdizione(_ d: DocumentoBiblioteca, tra documenti: [DocumentoBiblioteca]) -> String? {
        let altre = altreEdizioni(d, tra: documenti)
        guard !altre.isEmpty else { return nil }
        func nome(_ x: DocumentoBiblioteca) -> String { "«\(x.titoloBreve)»" + (x.edizione.isEmpty ? "" : " (\(x.edizione))") }
        guard let mia = chiaveEdizione(d.edizione) else {
            return "C'è anche un'altra edizione: " + altre.map(nome).joined(separator: ", ") + "."
        }
        let chiavi = altre.map { ($0, chiaveEdizione($0.edizione)) }
        let recenti = chiavi.filter { ($0.1 ?? Int.min) > mia }.map(\.0)
        if !recenti.isEmpty {
            return "C'è un'edizione più recente: " + recenti.map(nome).joined(separator: ", ") + ". Controlla che la risposta valga ancora."
        }
        let vecchie = chiavi.filter { ($0.1 ?? Int.max) < mia }.map(\.0)
        if !vecchie.isEmpty {
            return "C'è anche un'edizione più vecchia: " + vecchie.map(nome).joined(separator: ", ") + "."
        }
        return "C'è anche un'altra edizione: " + altre.map(nome).joined(separator: ", ") + "."
    }

    /// Il documento da aprire con «Condizioni nella Biblioteca» dalla scheda di un prodotto: fra quelli collegati, prima
    /// condizioni e set informativi, poi l'edizione più recente, poi l'ultimo importato. Gli illeggibili restano fuori.
    static func condizioniDelProdotto(_ prodottoId: String, tra documenti: [DocumentoBiblioteca]) -> DocumentoBiblioteca? {
        let collegati = documenti.filter { $0.prodottoId == prodottoId && !$0.illeggibile }
        func peso(_ d: DocumentoBiblioteca) -> Int {
            switch d.genereVisto {
            case .condizioni: return 0
            case .setInformativo: return 1
            case .kid, .notaInformativa: return 2
            case .circolare, .normativa, .altro: return 3
            }
        }
        return collegati.min { a, b in
            if peso(a) != peso(b) { return peso(a) < peso(b) }
            let ka = chiaveEdizione(a.edizione) ?? Int.min, kb = chiaveEdizione(b.edizione) ?? Int.min
            if ka != kb { return ka > kb }
            return a.importatoIl > b.importatoIl
        }
    }
}
