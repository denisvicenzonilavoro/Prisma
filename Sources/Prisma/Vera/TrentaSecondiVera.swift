import Foundation

// «Il cliente in 30 secondi» (Vera/BRIEF.md, funzione 6; template «Il cliente in 30 secondi»): prima di una chiamata Vera
// racconta la relazione in cinque sezioni fisse, ognuna con la sua fonte: chi è, la famiglia, cosa avete deciso, cosa
// preferisce, cosa è in sospeso. Prima il codice: Prisma compone le cinque sezioni dalla scheda, dagli incontri, dalle
// attività, dalle posizioni, dai messaggi e dai ricordi. Qwen (se è pronto) le rende più scorrevoli in JSON con lo schema fisso; se
// cambia o aggiunge una cifra, resta il testo di Prisma («Mai a caso»). Si chiede a voce, per scritto o con un tocco dalla
// scheda del cliente, e Vera la racconta a voce in 30 secondi, una sezione alla volta (TrentaSecondiShell.swift).

struct SezioneTrenta: Codable, Equatable {
    var titolo: String
    var testo: String
    var fonte: String
}

struct SchedaTrentaSecondi: Codable, Equatable {
    var clienteId: String
    var nome: String
    /// Il tema del cliente («Il futuro della sua famiglia»).
    var tema: String
    var canali: [Canale]
    var sezioni: [SezioneTrenta]
    var incontri: Int
    var messaggi: Int
    var ricordi: Int
    var documenti: Int
}

enum TrentaSecondiVera {
    static let titoli = ["Chi è", "La famiglia", "Cosa avete deciso", "Cosa preferisce", "In sospeso"]
    static let chiavi = ["chi", "famiglia", "deciso", "preferisce", "sospeso"]

    /// «Raccontami Marco», «Marco in 30 secondi», «parlami di Laura», «chi è Sofia Romano?»: il cliente (nil se la frase
    /// non è una di queste o il cliente non è unico).
    static func cliente(_ testo: String, clienti: [ClienteNoto], attivo: String?) -> String? {
        let t = InterpreteComandi.pulisci(testo).trimmingCharacters(in: .punctuationCharacters)
        let trenta = #"\b(?:il )?(?:cliente )?in (?:30|trenta) secondi\b"#
        let apertura = #"^(?:raccontami di|raccontami|parlami di|riassumimi|presentami|chi è|chi e'|dimmi di)\s+"#
        let haTrenta = DateItaliane.cerca(trenta, t) != nil
        guard haTrenta || DateItaliane.cerca(apertura, t) != nil else { return nil }
        let nominati = InterpreteComandi.clientiNominati(t, clienti)
        if !haTrenta {
            // Con il solo verbo il resto della frase dev'essere il cliente: «chi è il beneficiario della polizza di Marco»,
            // «dimmi di più su Laura» e «parlami di previdenza» non lo sono
            let resto = t.replacingOccurrences(of: apertura, with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
            let piega = { (s: String) in s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "it_IT")) }
            if ["il cliente", "questo cliente", "il mio cliente"].contains(piega(resto)) { return nominati.isEmpty ? attivo : nil }
            guard nominati.count == 1, let c = clienti.first(where: { $0.id == nominati[0].id }) else { return nil }
            let parole = Set(piega(c.nome).split(separator: " ").map(String.init))
            guard Set(piega(resto).split(separator: " ").map(String.init)).isSubset(of: parole) else { return nil }
            return c.id
        }
        if nominati.count == 1 { return nominati[0].id }
        if nominati.isEmpty, let attivo { return attivo }
        return nil
    }

    private static func anni(_ d: Date?, oggi: Date) -> Int? {
        d.flatMap { Calendar.current.dateComponents([.year], from: $0, to: oggi).year }
    }

    private static func elenco(_ parti: [String]) -> String {
        switch parti.count {
        case 0: return ""
        case 1: return parti[0]
        default: return parti.dropLast().joined(separator: ", ") + " e " + parti.last!
        }
    }

    /// Le cinque sezioni composte da Prisma.
    static func scheda(_ f: FonteVera, messaggi: [MessaggioCliente], ricordi: [RicordoVera]) -> SchedaTrentaSecondi {
        let c = f.cliente
        let oggi = f.oggi
        let inEssere = f.posizioni.filter { $0.stato == .inEssere }
        let canali = Canale.allCases.filter { k in inEssere.contains { $0.canale == k } || (inEssere.isEmpty && c.canali.contains(k)) }

        // Chi è
        var chi: [String] = []
        let eta = anni(c.dataNascita, oggi: oggi)
        let lavoro = c.professione.trimmingCharacters(in: .whitespaces)
        if let eta { chi.append(lavoro.isEmpty ? "\(eta) anni" : "\(eta) anni, \(lavoro.lowercased())") } else if !lavoro.isEmpty { chi.append(lavoro) }
        switch canali {
        case [.alleanza, .indipendente]: chi.append("È cliente sia per Alleanza sia come indipendente")
        case [.alleanza]: chi.append("È cliente Alleanza")
        case [.indipendente]: chi.append("È cliente come indipendente")
        default: chi.append("Non ha ancora posizioni in essere")
        }
        let testoChi = chi.joined(separator: ". ") + "."

        // La famiglia
        var famiglia: [String] = []
        for m in c.famiglia {
            let nome = m.nome.split(separator: " ").first.map(String.init) ?? m.nome
            var p = anni(m.dataNascita, oggi: oggi).map { "\(nome), \($0) anni" } ?? nome
            if m.relazione == .coniuge || m.relazione == .convivente {
                let coperta = f.posizioni.contains { $0.stato == .inEssere && $0.area == .protezione && MotoreProtezioneFamiglia.assicurato($0, cliente: c) == m.id }
                p += coperta ? ", con una protezione propria" : ", senza una protezione propria"
            } else if m.aCarico {
                p += ", a carico"
            }
            famiglia.append(p)
        }
        let testoFamiglia = famiglia.isEmpty ? "Nella scheda non ci sono familiari." : elenco(famiglia) + "."

        // Cosa avete deciso
        let conclusi = f.incontri.filter { $0.stato == .concluso && !$0.decisioni.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.data > $1.data }
        var deciso = conclusi.prefix(2).map { "A \(Formati.meseAnno.string(from: $0.data)): \($0.decisioni.trimmingCharacters(in: .whitespacesAndNewlines))" }
        let obiettivi = f.obiettivi.prefix(2).map { o in "\(o.titolo) per il \(Formati.formato("yyyy").string(from: o.scadenza))" }
        if !obiettivi.isEmpty { deciso.append("Gli obiettivi: " + elenco(obiettivi)) }
        let testoDeciso = deciso.isEmpty ? "Non ci sono ancora decisioni registrate negli incontri." : deciso.joined(separator: ". ") + "."
        let fonteDeciso = conclusi.isEmpty ? (obiettivi.isEmpty ? "Incontri" : "Gli obiettivi") : (conclusi.count == 1 ? "1 incontro" : "\(conclusi.count) incontri")

        // Cosa preferisce: i ricordi, il canale dei messaggi che gli hai mandato davvero, gli incontri
        let suoi = ricordi.filter { $0.clienteId == c.id }.sorted { $0.data > $1.data }
        let suoiMessaggi = messaggi.filter { $0.clienteId == c.id }
        let canale = canalePreferito(suoiMessaggi)
        var preferisce = suoi.prefix(canale == nil ? 3 : 2).map(\.testo)
        if let canale { preferisce.append(canale == .mail ? "Di solito vi scrivete via mail" : "Di solito vi scrivete su Messaggi") }
        if let esperienza = f.incontri.sorted(by: { $0.data > $1.data }).first(where: { !$0.esperienza.isEmpty })?.esperienza {
            preferisce.append(esperienza.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let testoPreferisce = preferisce.isEmpty ? "Non lo so ancora: dimmi «ricorda che…» e me lo segno." : preferisce.prefix(3).joined(separator: ". ") + "."
        var fontiPreferisce: [String] = []
        if !suoi.isEmpty { fontiPreferisce.append(suoi.count == 1 ? "1 ricordo" : "\(suoi.count) ricordi") }
        if canale != nil { fontiPreferisce.append("i messaggi") }
        let fontePreferisce = fontiPreferisce.isEmpty ? "Gli incontri" : maiuscola(elenco(fontiPreferisce))

        // In sospeso
        var sospeso: [String] = []
        let fraTre = Calendar.current.date(byAdding: .day, value: 90, to: oggi) ?? oggi
        for p in inEssere.filter({ ($0.scadenza.map { $0 >= oggi && $0 <= fraTre }) ?? false }).sorted(by: { ($0.scadenza ?? oggi) < ($1.scadenza ?? oggi) }).prefix(2) {
            sospeso.append("\(p.nome) scade il \(Formati.giornoMese.string(from: p.scadenza ?? oggi))")
        }
        for a in f.attivita.filter({ !$0.completata }).sorted(by: { $0.scadenza < $1.scadenza }).prefix(2) {
            sospeso.append("da fare: \(a.titolo.prefix(1).lowercased() + a.titolo.dropFirst())")
        }
        // Un messaggio preparato e mai aperto in Mail o in Messaggi negli ultimi due mesi: è rimasto in sospeso
        let daQuando = Calendar.current.date(byAdding: .day, value: -giorniBozza, to: oggi) ?? oggi
        let bozza = suoiMessaggi.filter { $0.stato == .bozza && $0.creatoIl >= daQuando }.max { $0.creatoIl < $1.creatoIl }
        if let b = bozza {
            let oggetto = b.oggetto?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            sospeso.append("un messaggio ancora da mandare" + (oggetto.isEmpty ? "" : " («\(oggetto)»)"))
        }
        if !c.consensi.privacy { sospeso.append("manca il consenso privacy") }
        if !f.analisiSalvata { sospeso.append("mancano le spese mensili (Analisi 360)") }
        let testoSospeso = sospeso.isEmpty ? "Niente in sospeso." : (sospeso.first!.prefix(1).uppercased() + elenco(sospeso).dropFirst()) + "."

        let sezioni = [SezioneTrenta(titolo: titoli[0], testo: testoChi, fonte: "La scheda"),
                       SezioneTrenta(titolo: titoli[1], testo: testoFamiglia, fonte: "La scheda"),
                       SezioneTrenta(titolo: titoli[2], testo: testoDeciso, fonte: fonteDeciso),
                       SezioneTrenta(titolo: titoli[3], testo: testoPreferisce, fonte: fontePreferisce),
                       SezioneTrenta(titolo: titoli[4], testo: testoSospeso, fonte: bozza == nil ? "Agenda e posizioni" : "Agenda, posizioni e messaggi")]
        let annoFa = Calendar.current.date(byAdding: .year, value: -1, to: oggi) ?? oggi
        return SchedaTrentaSecondi(clienteId: c.id, nome: c.nome, tema: c.tema, canali: canali, sezioni: sezioni,
                                   incontri: f.incontri.count, messaggi: messaggi.filter { $0.clienteId == c.id && $0.creatoIl >= annoFa }.count,
                                   ricordi: suoi.count, documenti: f.documenti.count)
    }

    /// Una bozza più vecchia di così non è più «in sospeso».
    static let giorniBozza = 60

    private static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    /// Il canale dei messaggi che il consulente ha aperto davvero in Mail o in Messaggi: quello di almeno due terzi, con
    /// almeno due messaggi (nil se non ce ne sono abbastanza o se usa i due canali allo stesso modo).
    static func canalePreferito(_ messaggi: [MessaggioCliente]) -> CanaleMessaggio? {
        let usciti = messaggi.filter { $0.stato == .apertoInMail || $0.stato == .apertoInMessaggi }
        guard usciti.count >= 2 else { return nil }
        let mail = usciti.filter { $0.stato == .apertoInMail }.count
        if mail * 3 >= usciti.count * 2 { return .mail }
        if (usciti.count - mail) * 3 >= usciti.count * 2 { return .messaggi }
        return nil
    }

    // MARK: - La lettura a voce in 30 secondi (template: anello del conto alla rovescia e «Ascolta di nuovo»)

    /// Quanto dura il racconto: l'anello conta alla rovescia da qui.
    static let durata: Double = 30
    /// Caratteri al secondo della sintesi vocale di macOS alla velocità 1 (stima prudente per l'italiano).
    static let caratteriAlSecondo: Double = 15
    /// La velocità più alta che si chiede alla voce (oltre non si capisce più).
    static let velocitaMassima: Double = 1.4

    /// Quello che Vera dice per una sezione: la prima comincia con «Marco Bianchi in trenta secondi.»; poi il titolo e il
    /// testo, così com'è sullo schermo (stesse cifre), ripulito per la voce.
    static func parlato(_ s: SchedaTrentaSecondi, sezione i: Int) -> String {
        guard s.sezioni.indices.contains(i) else { return "" }
        let x = s.sezioni[i]
        let corpo = "\(x.titolo). \(TestoParlato.pulisci(x.testo))"
        return i == 0 ? "\(s.nome) in trenta secondi. " + corpo : corpo
    }

    /// La velocità della voce per stare nei 30 secondi: quella scelta in Impostazioni, più svelta solo se il racconto è
    /// lungo, mai oltre `velocitaMassima`.
    static func velocita(_ s: SchedaTrentaSecondi, preferita: Double) -> Double {
        let caratteri = s.sezioni.indices.reduce(0) { $0 + parlato(s, sezione: $1).count }
        let necessaria = Double(caratteri) / (caratteriAlSecondo * durata)
        return min(velocitaMassima, max(preferita, necessaria))
    }

    // MARK: - Qwen rende le sezioni scorrevoli (JSON, «Mai a caso»)

    static let schema: [String: Any] = {
        var p: [String: Any] = [:]
        for k in chiavi { p[k] = ["type": "string"] }
        return ["type": "object", "properties": p, "required": chiavi]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("trenta") ?? "Riscrivi in modo naturale e breve le cinque sezioni del ritratto di un cliente preparate da Prisma (chi, famiglia, deciso, preferisce, sospeso). Una o due frasi per sezione, in italiano, al consulente. Non aggiungere fatti e non cambiare né aggiungere cifre, date o nomi. Rispondi solo con il JSON."
    }

    static func messaggi(_ s: SchedaTrentaSecondi) -> [MessaggioModello] {
        let righe = zip(chiavi, s.sezioni).map { "\($0.0): \($0.1.testo)" }.joined(separator: "\n")
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "CLIENTE: \(s.nome)\nSEZIONI DI PRISMA\n\(righe)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.3
        o.contesto = NucleoVera.finestra
        o.massimoToken = 600
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    /// Le sezioni riscritte da Qwen dove passano il controllo delle cifre; le altre restano quelle di Prisma.
    static func applica(_ json: String, a s: SchedaTrentaSecondi) -> SchedaTrentaSecondi {
        guard let i = json.firstIndex(of: "{"), let f = json.lastIndex(of: "}"), i < f,
              let d = String(json[i...f]).data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return s }
        var r = s
        for (n, k) in chiavi.enumerated() {
            guard let t = (j[k] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), t.count >= 8, t.count <= 400,
                  CommentoVera.numeriConservati(bozza: s.sezioni[n].testo, testo: t) else { continue }
            r.sezioni[n].testo = t
        }
        return r
    }
}
