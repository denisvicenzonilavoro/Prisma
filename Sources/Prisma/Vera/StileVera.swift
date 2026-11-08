import Foundation

// «Scrive come te» (Vera/BRIEF.md, funzione 15; template «Scrive come te»): Vera impara lo stile del consulente dai
// messaggi che lui ha aperto da Prisma in Mail o in Messaggi (quelli usciti davvero: `StatoMessaggio.apertoInMail` e
// `.apertoInMessaggi`), più un profilo di regole che lui vede e corregge. Prima il codice, niente invenzioni: le regole
// nascono solo da statistiche sui testi (tu o Lei e l'età dei clienti, lunghezza delle frasi, righe, firma, saluti,
// emoji, formule da ufficio mai usate), ognuna con «imparata da N messaggi»; quelle che scrive il consulente («scritta
// da te») non le cambia più nessun apprendimento. Il profilo poi si usa in tre modi: le istruzioni da accodare a quelle
// di MessaggiVera per Qwen, i ritocchi sicuri di una bozza fatti dal codice (saluto, chiusura, firma, una cosa per riga,
// formule da ufficio da togliere, emoji) e la verifica di una bozza con l'elenco delle regole violate.
// Niente invii: il motore restituisce testi, le bozze restano da confermare dal consulente.

/// Tu o Lei.
enum Allocuzione: String, Codable, CaseIterable {
    case tu, lei

    var nome: String { self == .tu ? "tu" : "Lei" }
}

/// Da dove viene una regola del profilo.
enum OrigineRegolaStile: String, Codable {
    /// Ricavata dal codice dai messaggi aperti (con quanti messaggi in `RegolaStile.messaggi`).
    case imparata
    /// Scritta o corretta dal consulente: l'apprendimento non la tocca più.
    case scritta
}

/// Le regole del profilo, nell'ordine in cui si mostrano.
enum ChiaveRegolaStile: String, Codable, CaseIterable, Identifiable {
    case cortesia, lunghezzaFrasi, unaCosaPerRiga, primaGiornoEOra, firma, formuleVietate, emoji, aperture, chiusure

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .cortesia: return "Tu o Lei"
        case .lunghezzaFrasi: return "Lunghezza delle frasi"
        case .unaCosaPerRiga: return "Una cosa per riga"
        case .primaGiornoEOra: return "Prima giorno e ora"
        case .firma: return "Firma"
        case .formuleVietate: return "Formule da ufficio"
        case .emoji: return "Emoji"
        case .aperture: return "Saluto d'apertura"
        case .chiusure: return "Saluto di chiusura"
        }
    }
}

/// Una regola del profilo: il valore, da dove viene e se vale (il consulente può spegnerla senza cancellarla).
struct RegolaStile<Valore: Codable & Equatable>: Codable, Equatable {
    var valore: Valore
    var origine: OrigineRegolaStile
    /// Da quanti messaggi è imparata (0 per una regola scritta dal consulente).
    var messaggi: Int
    var attiva: Bool

    init(valore: Valore, origine: OrigineRegolaStile, messaggi: Int, attiva: Bool = true) {
        self.valore = valore
        self.origine = origine
        self.messaggi = messaggi
        self.attiva = attiva
    }

    static func imparata(_ v: Valore, da n: Int) -> RegolaStile { RegolaStile(valore: v, origine: .imparata, messaggi: n) }
    static func scritta(_ v: Valore) -> RegolaStile { RegolaStile(valore: v, origine: .scritta, messaggi: 0) }

    /// Il consulente cambia il valore: da qui in poi la regola è sua.
    mutating func scrivi(_ v: Valore) {
        valore = v
        origine = .scritta
        messaggi = 0
        attiva = true
    }

    /// «imparata da 214 messaggi», «scritta da te».
    var provenienza: String {
        switch origine {
        case .scritta: return "scritta da te"
        case .imparata: return messaggi == 1 ? "imparata da 1 messaggio" : "imparata da \(messaggi) messaggi"
        }
    }

    private enum CodingKeys: String, CodingKey { case valore, origine, messaggi, attiva }

    /// Lettura tollerante: senza valore la regola si scarta (ProfiloStile la salta), il resto torna al predefinito.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        valore = try c.decode(Valore.self, forKey: .valore)
        origine = (try? c.decodeIfPresent(OrigineRegolaStile.self, forKey: .origine)) ?? .scritta
        messaggi = max(0, (try? c.decodeIfPresent(Int.self, forKey: .messaggi)) ?? 0)
        attiva = (try? c.decodeIfPresent(Bool.self, forKey: .attiva)) ?? true
    }
}

/// Tu o Lei: la scelta di base, la soglia d'età (sotto la soglia del tu, dalla soglia in su del Lei) e le eccezioni
/// per cliente (id del cliente → tu o Lei).
struct CortesiaStile: Codable, Equatable {
    var predefinita: Allocuzione
    var sogliaEta: Int?
    var perCliente: [String: Allocuzione]

    init(predefinita: Allocuzione, sogliaEta: Int? = nil, perCliente: [String: Allocuzione] = [:]) {
        self.predefinita = predefinita
        self.sogliaEta = sogliaEta
        self.perCliente = perCliente
    }

    private enum CodingKeys: String, CodingKey { case predefinita, sogliaEta, perCliente }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        predefinita = (try? c.decodeIfPresent(Allocuzione.self, forKey: .predefinita)) ?? .lei
        let s = (try? c.decodeIfPresent(Int.self, forKey: .sogliaEta)) ?? nil
        sogliaEta = s.flatMap { (14...110).contains($0) ? $0 : nil }
        perCliente = ((try? c.decodeIfPresent([String: Allocuzione].self, forKey: .perCliente)) ?? nil) ?? [:]
    }
}

/// Le emoji con i clienti.
enum UsoEmoji: String, Codable, CaseIterable {
    case mai
    /// Mai con i clienti nuovi (quelli a cui non è ancora uscito nessun messaggio da Prisma).
    case soloClientiNoti
    case libere
}

/// Il profilo di stile del consulente (più avanti in `DatiPrisma` o nelle impostazioni di Vera, e nel backup).
/// Ogni regola è facoltativa: nil vuol dire che Prisma non ha prove sufficienti e il consulente non l'ha scritta.
struct ProfiloStile: Codable, Equatable {
    var cortesia: RegolaStile<CortesiaStile>?
    /// Il massimo di parole per frase.
    var lunghezzaFrasi: RegolaStile<Int>?
    var unaCosaPerRiga: RegolaStile<Bool>?
    var primaGiornoEOra: RegolaStile<Bool>?
    var firma: RegolaStile<String>?
    /// Le formule da ufficio che il consulente non usa mai.
    var formuleVietate: RegolaStile<[String]>?
    var emoji: RegolaStile<UsoEmoji>?
    /// I saluti d'apertura tipici, con i segnaposto del nome e del cognome (`StileVera.segnaNome`, `segnaCognome`): «Ciao ‹nome›,».
    var aperture: RegolaStile<[String]>?
    /// I saluti di chiusura tipici: «A presto!».
    var chiusure: RegolaStile<[String]>?
    /// Su quanti messaggi aperti in Messaggi e quante mail è stato imparato l'ultima volta.
    var messaggiLetti = 0
    var mailLette = 0
    var aggiornatoIl: Date?

    init() {}

    var vuoto: Bool { ChiaveRegolaStile.allCases.allSatisfy { !ha($0) } }

    /// C'è una regola per questa chiave (accesa o spenta).
    func ha(_ k: ChiaveRegolaStile) -> Bool {
        switch k {
        case .cortesia: return cortesia != nil
        case .lunghezzaFrasi: return lunghezzaFrasi != nil
        case .unaCosaPerRiga: return unaCosaPerRiga != nil
        case .primaGiornoEOra: return primaGiornoEOra != nil
        case .firma: return firma != nil
        case .formuleVietate: return formuleVietate != nil
        case .emoji: return emoji != nil
        case .aperture: return aperture != nil
        case .chiusure: return chiusure != nil
        }
    }

    /// Accende o spegne una regola (il consulente la «cancella» spegnendola: l'apprendimento non la riaccende).
    mutating func imposta(_ k: ChiaveRegolaStile, attiva: Bool) {
        switch k {
        case .cortesia: cortesia?.attiva = attiva
        case .lunghezzaFrasi: lunghezzaFrasi?.attiva = attiva
        case .unaCosaPerRiga: unaCosaPerRiga?.attiva = attiva
        case .primaGiornoEOra: primaGiornoEOra?.attiva = attiva
        case .firma: firma?.attiva = attiva
        case .formuleVietate: formuleVietate?.attiva = attiva
        case .emoji: emoji?.attiva = attiva
        case .aperture: aperture?.attiva = attiva
        case .chiusure: chiusure?.attiva = attiva
        }
    }

    private enum CodingKeys: String, CodingKey {
        case cortesia, lunghezzaFrasi, unaCosaPerRiga, primaGiornoEOra, firma, formuleVietate, emoji, aperture, chiusure
        case messaggiLetti, mailLette, aggiornatoIl
    }

    /// Lettura tollerante: una regola illeggibile si salta, le altre restano.
    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        cortesia = (try? c.decodeIfPresent(RegolaStile<CortesiaStile>.self, forKey: .cortesia)) ?? nil
        lunghezzaFrasi = (try? c.decodeIfPresent(RegolaStile<Int>.self, forKey: .lunghezzaFrasi)) ?? nil
        if let l = lunghezzaFrasi, l.valore < 3 { lunghezzaFrasi = nil }
        unaCosaPerRiga = (try? c.decodeIfPresent(RegolaStile<Bool>.self, forKey: .unaCosaPerRiga)) ?? nil
        primaGiornoEOra = (try? c.decodeIfPresent(RegolaStile<Bool>.self, forKey: .primaGiornoEOra)) ?? nil
        firma = (try? c.decodeIfPresent(RegolaStile<String>.self, forKey: .firma)) ?? nil
        if let f = firma, f.valore.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { firma = nil }
        formuleVietate = (try? c.decodeIfPresent(RegolaStile<[String]>.self, forKey: .formuleVietate)) ?? nil
        emoji = (try? c.decodeIfPresent(RegolaStile<UsoEmoji>.self, forKey: .emoji)) ?? nil
        aperture = (try? c.decodeIfPresent(RegolaStile<[String]>.self, forKey: .aperture)) ?? nil
        chiusure = (try? c.decodeIfPresent(RegolaStile<[String]>.self, forKey: .chiusure)) ?? nil
        messaggiLetti = max(0, (try? c.decodeIfPresent(Int.self, forKey: .messaggiLetti)) ?? 0)
        mailLette = max(0, (try? c.decodeIfPresent(Int.self, forKey: .mailLette)) ?? 0)
        aggiornatoIl = (try? c.decodeIfPresent(Date.self, forKey: .aggiornatoIl)) ?? nil
    }
}

/// Una riga del profilo come si mostra nella scheda «Il tuo stile».
struct VoceStile: Identifiable, Equatable {
    var id: ChiaveRegolaStile
    /// «Dai del tu ai clienti sotto i 40 anni, del Lei agli altri».
    var testo: String
    /// «imparata da 214 messaggi» o «scritta da te».
    var provenienza: String
    var attiva: Bool
    /// Le eccezioni per cliente, l'elenco delle formule vietate…
    var dettaglio: String?
}

/// Le parti di un messaggio: saluto d'apertura, righe del corpo, saluto di chiusura e firma.
struct StrutturaMessaggio: Equatable {
    var apertura: String?
    var corpo: [String]
    var chiusura: String?
    var firma: String?
}

/// Una regola del profilo che la bozza non rispetta. Grave: Vera non può proporre il testo così (tu al posto del Lei,
/// una formula vietata, un'emoji vietata).
struct ViolazioneStile: Equatable {
    var regola: ChiaveRegolaStile
    var spiegazione: String
    var grave: Bool
}

/// Una bozza ritoccata dal codice secondo il profilo, con l'elenco di cosa è cambiato.
struct BozzaInStile: Equatable {
    var testo: String
    var modifiche: [String]
}

enum StileVera {
    /// Sotto questi messaggi una regola non si impara: poche prove, niente regola.
    static let minimoMessaggi = 3
    /// Il segnaposto del nome nei saluti del profilo.
    static let segnaNome = "‹nome›"
    static let segnaCognome = "‹cognome›"

    /// Le formule da ufficio che un consulente vicino ai clienti di solito non usa. Nel profilo entrano solo quelle
    /// che nei suoi messaggi non compaiono mai.
    static let formuleUfficio = [
        "con la presente", "restiamo a disposizione", "resto a disposizione", "rimaniamo a disposizione",
        "per qualsiasi chiarimento", "cordiali saluti", "distinti saluti", "la preghiamo", "le ricordiamo",
        "si comunica", "facendo seguito", "in riferimento a", "porgiamo", "in allegato si trasmette",
        "si prega di", "in attesa di un cortese riscontro", "sarà nostra cura",
    ]

    /// Le formule che il codice può togliere da sole senza cambiare il senso: una frase che comincia così si toglie
    /// intera (le formule di cortesia finali), «con la presente» si toglie dall'inizio della frase.
    static let frasiDaTogliere = ["restiamo a disposizione", "resto a disposizione", "rimaniamo a disposizione",
                                  "rimango a disposizione", "resto a sua disposizione", "per qualsiasi chiarimento"]

    // MARK: - I messaggi da cui si impara

    /// Solo i messaggi usciti davvero: aperti in Mail o in Messaggi (le bozze e i salvati no).
    static func inviati(_ messaggi: [MessaggioCliente]) -> [MessaggioCliente] {
        messaggi.filter { $0.stato == .apertoInMail || $0.stato == .apertoInMessaggi }
            .sorted { ($0.dataMostrata, $0.id) < ($1.dataMostrata, $1.id) }
    }

    /// Un cliente è nuovo finché non gli è uscito nessun messaggio da Prisma.
    static func clienteNuovo(_ clienteId: String, messaggi: [MessaggioCliente]) -> Bool {
        !inviati(messaggi).contains { $0.clienteId == clienteId }
    }

    /// L'età di un cliente a una certa data (nil senza data di nascita).
    static func eta(_ c: Cliente, al giorno: Date) -> Int? {
        guard let n = c.dataNascita, n <= giorno else { return nil }
        return Calendar.current.dateComponents([.year], from: n, to: giorno).year
    }

    // MARK: - Leggere un testo

    static func normale(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
            .split { $0.isWhitespace }.joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:!?…–-"))
    }

    static func conta(_ schema: String, _ testo: String, maiuscole: Bool = false) -> Int {
        guard let re = try? NSRegularExpression(pattern: schema, options: maiuscole ? [] : [.caseInsensitive]) else { return 0 }
        return re.numberOfMatches(in: testo, range: NSRange(location: 0, length: (testo as NSString).length))
    }

    /// Le frasi di una riga: si spezza dopo . ! ? … seguiti da uno spazio e da una maiuscola o una cifra
    /// («Sig.ra Rossi» e «16.00» restano interi).
    static func frasi(_ riga: String) -> [String] {
        riga.replacingOccurrences(of: #"([.!?…])\s+(?=[A-ZÀ-ÖØ-Þ0-9«"])"#, with: "$1\u{1F}", options: .regularExpression)
            .components(separatedBy: "\u{1F}")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static func parole(_ s: String) -> Int {
        s.split { $0.isWhitespace }.filter { $0.contains { $0.isLetter || $0.isNumber } }.count
    }

    private static func ePaEmoji(_ u: Unicode.Scalar) -> Bool {
        u.properties.isEmojiPresentation || (u.properties.isEmoji && u.value >= 0x2600)
    }

    static func haEmoji(_ s: String) -> Bool { s.unicodeScalars.contains { ePaEmoji($0) } }

    static func senzaEmoji(_ s: String) -> String {
        var v = String.UnicodeScalarView()
        // Con l'emoji vanno via anche il selettore di variante e il giunto che la accompagnano
        for u in s.unicodeScalars where !ePaEmoji(u) && u.value != 0xFE0F && u.value != 0x200D { v.append(u) }
        return String(v).replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[ \t]+(\n|$)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"[ \t]+([,.!?;:])"#, with: "$1", options: .regularExpression)
    }

    private static let saluto = #"^((?:ciao|gentil\w*|car[oaie]|buongiorno|buonasera|salve|egregi\w*)\b[^,!\n]{0,40}[,!])\s*(.*)$"#

    private static let giorniSettimana = "lunedì|martedì|mercoledì|giovedì|venerdì|sabato|domenica"

    /// Un giorno o un'ora scritti nel testo («giovedì 5», «domani», «alle 16», «12 novembre», «10:30»).
    static var quando: String {
        #"\b(?:oggi|domani|dopodomani|"# + giorniSettimana + #")\b|\b\d{1,2}\s+(?:"# + DateItaliane.mesi.joined(separator: "|")
            + #")\b|\balle\s+(?:ore\s+)?\d{1,2}\b|\b\d{1,2}:\d{2}\b"#
    }

    static func eChiusura(_ riga: String) -> Bool {
        let r = riga.trimmingCharacters(in: .whitespaces)
        guard parole(r) <= 6, !r.contains(where: { $0.isNumber }) else { return false }
        let n = normale(r)
        if MessaggiVera.chiusure.contains(where: { n.hasPrefix(normale($0)) }) { return true }
        let schema = #"^(?:a (?:presto|dopo|domani|stasera|risentirci|breve|"# + giorniSettimana
            + #")|ci vediamo|ci sentiamo|buon\w* (?:giornata|serata|weekend|fine settimana)|grazie|un (?:caro )?saluto|un abbraccio|saluti|cordiali|distinti|cari saluti)\b"#
        return DateItaliane.cerca(schema, r.lowercased()) != nil
    }

    /// Una firma è una firma conosciuta (quella del profilo) oppure una riga breve che somiglia a un nome: ogni parola
    /// della parte prima di «·», «|», «-» o «,» comincia con la maiuscola («Denis», «Denis Vicenzoni · Consulenza
    /// finanziaria», «Dott. Vicenzoni»). «Fammi sapere» resta nel corpo.
    private static func eFirma(_ riga: String, firme: [String] = []) -> Bool {
        let r = riga.trimmingCharacters(in: .whitespaces)
        if !r.isEmpty, firme.contains(where: { !normale($0).isEmpty && normale($0) == normale(r) }) { return true }
        guard let primo = r.first, primo.isLetter, primo.isUppercase, !r.contains(where: { $0.isNumber }),
              let ultimo = r.last, !".!?,;:".contains(ultimo), !eChiusura(r), !eAuguri(r) else { return false }
        return (1...5).contains(parole(r)) && sembraUnNome(r)
    }

    /// Gli auguri in fondo al messaggio («Buone Feste», «Buon Natale», «Tanti auguri»): hanno le maiuscole come un
    /// nome ma non sono una firma, restano nel testo e la firma del profilo va sotto.
    static func eAuguri(_ riga: String) -> Bool {
        let r = riga.trimmingCharacters(in: .whitespaces)
        guard parole(r) <= 6 else { return false }
        let schema = #"^(?:(?:tanti |i miei |i nostri |sinceri |cari |affettuosi |migliori )?auguri|buon\w* (?:feste|natale|pasqua|anno|capodanno|ferragosto|vacanze|compleanno|onomastico)|felice? (?:anno|natale|pasqua|compleanno)|serene feste|sereno natale|sereni? (?:natale|pasqua|feste))\b"#
        return DateItaliane.cerca(schema, r.lowercased()) != nil
    }

    private static let particelleNome: Set<String> = ["de", "di", "da", "del", "della", "dei", "van", "von", "e", "ed"]

    static func sembraUnNome(_ riga: String) -> Bool {
        let nome = riga.components(separatedBy: CharacterSet(charactersIn: "·|–—-,/")).first?.trimmingCharacters(in: .whitespaces) ?? riga
        let parole = nome.split { $0.isWhitespace }.map(String.init).filter { $0.contains { $0.isLetter } }
        guard !parole.isEmpty, parole.count <= 4 else { return false }
        return parole.allSatisfy { p in
            particelleNome.contains(p) || (p.first { $0.isLetter }.map { $0.isUppercase } ?? false)
        }
    }

    /// Le parti di un messaggio. Il saluto d'apertura può stare su una riga sua o all'inizio della prima
    /// («Ciao Giulia, ci vediamo…»); firma e chiusura sono le ultime righe brevi. `firme`: le firme conosciute
    /// (del profilo), riconosciute anche quando non somigliano a un nome.
    static func struttura(_ testo: String, firme: [String] = []) -> StrutturaMessaggio {
        var righe = testo.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var apertura: String?
        if let p = righe.first, let (_, g) = DateItaliane.cerca(saluto, p), parole(g[1]) <= 6 {
            apertura = g[1].trimmingCharacters(in: .whitespaces)
            let resto = g[2].trimmingCharacters(in: .whitespaces)
            if resto.isEmpty { righe.removeFirst() } else { righe[0] = resto }
        }
        var firma: String?
        if righe.count >= 2, let u = righe.last, eFirma(u, firme: firme) {
            firma = u
            righe.removeLast()
        }
        var chiusura: String?
        if let u = righe.last, eChiusura(u), !(righe.count == 1 && apertura == nil) {
            chiusura = u
            righe.removeLast()
        }
        return StrutturaMessaggio(apertura: apertura, corpo: righe, chiusura: chiusura, firma: firma)
    }

    private static func rimonta(_ s: StrutturaMessaggio) -> String {
        ([s.apertura].compactMap { $0 } + s.corpo + [s.chiusura, s.firma].compactMap { $0 }).joined(separator: "\n")
    }

    /// Tu o Lei in un testo, dalle parole che lo dicono; nil se non si capisce.
    static func allocuzione(di testo: String) -> Allocuzione? {
        // «può», «potrebbe», «desidera», «vorrebbe» sono il Lei solo senza un soggetto davanti, cioè a inizio frase
        // («Può portare il contratto?»); «la rata può scendere» è una terza persona e non dice niente
        let lei = conta(#"\bgentil(?:e|issim[oa])\b|\begregi[oa]\b|\bmi (?:faccia|dica|scriva|chiami)\b|\bsua disposizione\b|\bla saluto\b"#, testo)
            + conta(#"(?m)(?:^|[.!?…]\s+)(?:Può|Potrebbe|Desidera|Vorrebbe)\b"#, testo, maiuscole: true)
            + conta(#"(?<=[a-zà-ù,] )(?:La|Le|Lei|Sua|Suo|Sue|Suoi)\b"#, testo, maiuscole: true)
            // «Le/La + verbo» a inizio frase (a metà frase lo conta già il termine sopra); «le invio», «la mando»
            // minuscoli sono pronomi oggetto anche col tu («le simulazioni: le invio stasera») e non dicono niente
            + conta(#"(?m)(?:^|[.!?…]\s+)(?:Le|La) (?:ricord\w*|preg\w*|scriv\w*|invi\w*|mand\w*|aspett\w*|chied\w*|inform\w*|comunic\w*|ringrazi\w*|conferm\w*|ricontatt\w*|richiam\w*)\b"#, testo, maiuscole: true)
        let tu = conta(#"\bciao\b|\bti\b|\bte\b|\btuo\b|\btua\b|\btuoi\b|\btue\b|\bpuoi\b|\bvuoi\b|\bhai\b|\bsei\b|\bfammi\b|\bdimmi\b|\bscrivimi\b|\bchiamami\b"#, testo)
        if lei > tu { return .lei }
        if tu > lei { return .tu }
        return nil
    }

    /// Un saluto del profilo dice tu o Lei? («Gentile ‹nome›,» → Lei, «Ciao ‹nome›,» → tu, «Buongiorno ‹nome›,» → tutti e due).
    static func allocuzione(diSaluto s: String) -> Allocuzione? {
        let n = normale(s)
        if DateItaliane.cerca(#"\b(?:gentil\w*|egregi\w*|sig)"#, n) != nil { return .lei }
        if DateItaliane.cerca(#"\b(?:ciao|car[oaie])\b"#, n) != nil { return .tu }
        return nil
    }

    /// Il primo nome del cliente (come lo usa ModelliMessaggi: «Marco e Elena») e il resto, il cognome.
    static func nomeECognome(_ c: Cliente) -> (nome: String, cognome: String) {
        let completo = c.nome.trimmingCharacters(in: .whitespaces)
        let primo = ModelliMessaggi.primoNome(completo)
        let parolePrimo = primo.split(separator: " ").count
        let cognome = completo.split(separator: " ").dropFirst(parolePrimo).joined(separator: " ")
        return (primo, cognome)
    }

    /// Il saluto con i segnaposto al posto del nome e del cognome del cliente: «Ciao Giulia,» → «Ciao ‹nome›,»,
    /// «Gentile Sig.ra Rossi,» → «Gentile Sig.ra ‹cognome›,».
    static func modelloSaluto(_ apertura: String, cliente: Cliente?) -> String {
        var s = apertura.trimmingCharacters(in: .whitespaces)
        guard let cliente else { return s }
        let (nome, cognome) = nomeECognome(cliente)
        for (parola, segno) in [(cognome, segnaCognome), (nome, segnaNome)] where !parola.isEmpty {
            s = s.replacingOccurrences(of: #"\b"# + NSRegularExpression.escapedPattern(for: parola) + #"\b"#, with: segno,
                                       options: [.regularExpression, .caseInsensitive])
        }
        return s
    }

    private static let titoliSaluto: Set<String> = ["sig", "sig.", "sig.ra", "sig.na", "signor", "signora", "signore", "signorina", "dott",
                                                    "dott.", "dott.ssa", "dottor", "dottore", "dottoressa", "prof", "prof.", "prof.ssa",
                                                    "avv", "avv.", "ing", "ing.", "rag", "rag.", "geom", "geom.", "arch", "arch.", "egr", "egr.",
                                                    "gent", "gent.", "gent.mo", "gent.ma", "gent.mi", "gent.me", "famiglia",
                                                    // i vocativi generici, senza un nome: «Gentile Cliente,», «Gentili Signori,»
                                                    "cliente", "clienti", "signori", "signorine", "tutti", "tutte", "amici", "amiche"]

    /// Nel modello di un saluto, dopo la prima parola resta una parola con la maiuscola che non è un titolo
    /// («Ciao Giuly,» con la scheda di Giulia): è un nome che non è della scheda.
    static func restaUnNome(_ modello: String) -> Bool {
        let parole = modello.split { $0.isWhitespace }.dropFirst().map {
            $0.trimmingCharacters(in: CharacterSet(charactersIn: ",!;:"))
        }
        return parole.contains { p in
            guard let primo = p.first, primo.isLetter, primo.isUppercase else { return false }
            return !titoliSaluto.contains(p.lowercased())
        }
    }

    /// Il saluto del profilo con il nome e il cognome del cliente (senza cliente, o senza cognome, i segnaposto spariscono).
    static func compila(_ modello: String, cliente: Cliente?) -> String {
        let nc = cliente.map { nomeECognome($0) }
        let nome = nc?.nome ?? "", cognome = nc?.cognome ?? ""
        var s = modello
        for (segno, valore) in [(segnaNome, nome), (segnaCognome, cognome)] {
            s = valore.isEmpty ? s.replacingOccurrences(of: " " + segno, with: "").replacingOccurrences(of: segno, with: "")
                               : s.replacingOccurrences(of: segno, with: valore)
        }
        return s
    }

    /// Il saluto del profilo per questo tu o Lei: prima uno che lo dice («Ciao…» per il tu), poi uno che va bene
    /// per tutti e due («Buongiorno…»).
    static func salutoAdatto(_ elenco: [String], _ a: Allocuzione?) -> String? {
        guard let a else { return elenco.first }
        return elenco.first { allocuzione(diSaluto: $0) == a } ?? elenco.first { allocuzione(diSaluto: $0) == nil }
    }

    // MARK: - Imparare

    private struct Campione {
        var clienteId: String
        var eta: Int?
        var allocuzione: Allocuzione
    }

    /// Il profilo ricavato solo dai messaggi aperti, con le statistiche del codice. Nessuna regola senza almeno
    /// `minimoMessaggi` messaggi che la mostrano.
    static func impara(messaggi: [MessaggioCliente], clienti: [Cliente], oggi: Date) -> ProfiloStile {
        let usciti = inviati(messaggi)
        var p = ProfiloStile()
        p.messaggiLetti = usciti.filter { $0.canale == .messaggi }.count
        p.mailLette = usciti.filter { $0.canale == .mail }.count
        p.aggiornatoIl = oggi
        guard usciti.count >= minimoMessaggi else { return p }
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let strutture = usciti.map { struttura($0.testo) }

        // Tu o Lei, con l'età del cliente al giorno del messaggio
        let campioni = zip(usciti, strutture).compactMap { m, s -> Campione? in
            let testo = ([s.apertura].compactMap { $0 } + s.corpo).joined(separator: "\n")
            guard let a = allocuzione(di: testo) else { return nil }
            return Campione(clienteId: m.clienteId, eta: perId[m.clienteId].flatMap { eta($0, al: m.dataMostrata) }, allocuzione: a)
        }
        if let c = cortesia(campioni) { p.cortesia = .imparata(c, da: campioni.count) }

        // Lunghezza delle frasi: il 90° percentile delle frasi del corpo
        let lunghezze = strutture.flatMap { $0.corpo.flatMap(frasi) }.map(parole).filter { $0 > 0 }.sorted()
        if !lunghezze.isEmpty {
            let i = max(0, Int((0.9 * Double(lunghezze.count)).rounded(.up)) - 1)
            p.lunghezzaFrasi = .imparata(max(4, lunghezze[min(i, lunghezze.count - 1)]), da: usciti.count)
        }

        // Una cosa per riga: tra i messaggi con almeno due frasi, quelli con (quasi) ogni riga di una frase sola
        let conPiuFrasi = strutture.filter { $0.corpo.flatMap(frasi).count >= 2 }
        let unaPerRiga = conPiuFrasi.filter { s in
            Double(s.corpo.filter { frasi($0).count <= 1 }.count) >= 0.8 * Double(s.corpo.count)
        }
        if conPiuFrasi.count >= minimoMessaggi, Double(unaPerRiga.count) >= 0.75 * Double(conPiuFrasi.count) {
            p.unaCosaPerRiga = .imparata(true, da: unaPerRiga.count)
        }

        // Prima giorno e ora: tra i messaggi che ne parlano, quelli che lo dicono nella prima frase
        let conQuando = strutture.filter { conta(quando, $0.corpo.joined(separator: "\n")) > 0 }
        let primaQuando = conQuando.filter { s in s.corpo.first.flatMap { frasi($0).first }.map { conta(quando, $0) > 0 } ?? false }
        if conQuando.count >= minimoMessaggi, Double(primaQuando.count) >= 0.75 * Double(conQuando.count) {
            p.primaGiornoEOra = .imparata(true, da: primaQuando.count)
        }

        // La firma: la stessa in almeno sei messaggi su dieci
        if let (firma, n) = piuFrequente(strutture.compactMap(\.firma)), n >= minimoMessaggi, Double(n) >= 0.6 * Double(usciti.count) {
            p.firma = .imparata(firma, da: n)
        }

        // I saluti tipici (al massimo tre, ognuno in almeno due messaggi)
        // Un saluto con un soprannome («Ciao Giuly,») resta di quel cliente: si impara solo il saluto in cui, tolti
        // nome e cognome della scheda, non resta un altro nome
        let aperture = zip(usciti, strutture).compactMap { m, s in s.apertura.map { modelloSaluto($0, cliente: perId[m.clienteId]) } }
            .filter { !restaUnNome($0) }
        let apertureTipiche = frequenti(aperture)
        if aperture.count >= minimoMessaggi, !apertureTipiche.isEmpty {
            p.aperture = .imparata(apertureTipiche.map { $0.0 }, da: apertureTipiche.reduce(0) { $0 + $1.1 })
        }
        let chiusure = strutture.compactMap(\.chiusura)
        let chiusureTipiche = frequenti(chiusure)
        if chiusure.count >= minimoMessaggi, !chiusureTipiche.isEmpty {
            p.chiusure = .imparata(chiusureTipiche.map { $0.0 }, da: chiusureTipiche.reduce(0) { $0 + $1.1 })
        }

        // Le formule da ufficio mai usate
        let testi = usciti.map { normale($0.testo) }
        let mai = formuleUfficio.filter { f in !testi.contains { $0.contains(normale(f)) } }
        if !mai.isEmpty { p.formuleVietate = .imparata(mai, da: usciti.count) }

        // Le emoji: mai, o solo con i clienti a cui era già uscito un messaggio
        var noti: Set<String> = []
        var conEmoji = 0, conEmojiNuovi = 0, primiSenza = 0
        for m in usciti {
            let nuovo = !noti.contains(m.clienteId)
            if haEmoji(m.testo) {
                conEmoji += 1
                if nuovo { conEmojiNuovi += 1 }
            } else if nuovo {
                primiSenza += 1
            }
            noti.insert(m.clienteId)
        }
        if conEmoji == 0 {
            p.emoji = .imparata(.mai, da: usciti.count)
        } else if conEmojiNuovi == 0, primiSenza >= minimoMessaggi {
            p.emoji = .imparata(.soloClientiNoti, da: usciti.count)
        } else {
            p.emoji = .imparata(.libere, da: conEmoji)
        }
        return p
    }

    /// Tu o Lei dai campioni: la scelta di base, la soglia d'età che li separa meglio (se ne separa almeno l'80%,
    /// preferendo i multipli di 5) e le eccezioni dei clienti con almeno due messaggi tutti uguali e contrari alla regola.
    private static func cortesia(_ campioni: [Campione]) -> CortesiaStile? {
        guard campioni.count >= minimoMessaggi else { return nil }
        let tu = campioni.filter { $0.allocuzione == .tu }.count
        let quota = Double(tu) / Double(campioni.count)
        var regola = CortesiaStile(predefinita: tu * 2 > campioni.count ? .tu : .lei)
        let conEta = campioni.compactMap { c in c.eta.map { (eta: $0, a: c.allocuzione) } }
        if quota > 0.15, quota < 0.85, conEta.count >= minimoMessaggi {
            var migliore: (soglia: Int, giusti: Int)?
            let candidati = Set(conEta.map { $0.eta + 1 } + Array(stride(from: 20, through: 90, by: 5)))
            for t in candidati.sorted() {
                let sotto = conEta.filter { $0.eta < t }, sopra = conEta.filter { $0.eta >= t }
                guard !sotto.isEmpty, !sopra.isEmpty else { continue }
                let giusti = sotto.filter { $0.a == .tu }.count + sopra.filter { $0.a == .lei }.count
                if let m = migliore {
                    if giusti > m.giusti || (giusti == m.giusti && t % 5 == 0 && m.soglia % 5 != 0) { migliore = (t, giusti) }
                } else {
                    migliore = (t, giusti)
                }
            }
            if let m = migliore, m.giusti * 5 >= conEta.count * 4,
               // la soglia deve davvero dare del tu ai più giovani
               conEta.contains(where: { $0.eta < m.soglia && $0.a == .tu }) {
                regola.sogliaEta = m.soglia
            }
        }
        for (id, gruppo) in Dictionary(grouping: campioni, by: \.clienteId) where gruppo.count >= 2 {
            let tutte = Set(gruppo.map(\.allocuzione))
            guard tutte.count == 1, let unica = tutte.first else { continue }
            var attesa = regola.predefinita
            if let s = regola.sogliaEta, let e = gruppo.last?.eta { attesa = e < s ? .tu : .lei }
            if unica != attesa { regola.perCliente[id] = unica }
        }
        return regola
    }

    /// Il valore più frequente (confrontato senza maiuscole, accenti e punteggiatura finale) con quante volte compare.
    private static func piuFrequente(_ valori: [String]) -> (String, Int)? { frequenti(valori, minimo: 1).first }

    /// I valori che compaiono almeno `minimo` volte, dal più frequente (al massimo tre), nella forma scritta più spesso.
    private static func frequenti(_ valori: [String], minimo: Int = 2) -> [(String, Int)] {
        let gruppi = Dictionary(grouping: valori.map { $0.trimmingCharacters(in: .whitespaces) }, by: normale)
        return gruppi.compactMap { _, g -> (String, Int)? in
            guard g.count >= minimo else { return nil }
            let forme = Dictionary(grouping: g, by: { $0 })
            let forma = forme.max { ($0.value.count, $1.key) < ($1.value.count, $0.key) }?.key ?? g[0]
            return (forma, g.count)
        }
        .sorted { ($0.1, $1.0) > ($1.1, $0.0) }
        .prefix(3).map { $0 }
    }

    /// Impara di nuovo e tiene le scelte del consulente: le regole scritte da lui restano come sono, quelle che ha
    /// spento restano spente; le regole imparate senza più prove escono dal profilo.
    static func aggiorna(_ attuale: ProfiloStile, messaggi: [MessaggioCliente], clienti: [Cliente], oggi: Date) -> ProfiloStile {
        unisci(imparato: impara(messaggi: messaggi, clienti: clienti, oggi: oggi), attuale: attuale)
    }

    static func unisci(imparato: ProfiloStile, attuale: ProfiloStile) -> ProfiloStile {
        var r = imparato
        tieni(\.cortesia, attuale, &r)
        tieni(\.lunghezzaFrasi, attuale, &r)
        tieni(\.unaCosaPerRiga, attuale, &r)
        tieni(\.primaGiornoEOra, attuale, &r)
        tieni(\.firma, attuale, &r)
        tieni(\.formuleVietate, attuale, &r)
        tieni(\.emoji, attuale, &r)
        tieni(\.aperture, attuale, &r)
        tieni(\.chiusure, attuale, &r)
        return r
    }

    private static func tieni<V>(_ k: WritableKeyPath<ProfiloStile, RegolaStile<V>?>, _ attuale: ProfiloStile, _ r: inout ProfiloStile) {
        guard let vecchia = attuale[keyPath: k] else { return }
        if vecchia.origine == .scritta {
            r[keyPath: k] = vecchia
        } else if r[keyPath: k] != nil {
            r[keyPath: k]?.attiva = vecchia.attiva
        }
    }

    // MARK: - Il profilo da mostrare

    /// «Imparato da 214 messaggi e 38 email che hai scritto. Lo correggi quando vuoi.»
    static func intestazione(_ p: ProfiloStile) -> String {
        let m = p.messaggiLetti, e = p.mailLette
        guard m + e > 0 else {
            return "Ancora nessun messaggio aperto da Prisma: scrivi tu le regole, o Vera le impara dai primi messaggi."
        }
        let pezzi = [m > 0 ? (m == 1 ? "1 messaggio" : "\(m) messaggi") : nil, e > 0 ? (e == 1 ? "1 email" : "\(e) email") : nil].compactMap { $0 }
        return "Imparato da " + pezzi.joined(separator: " e ") + " che hai scritto. Lo correggi quando vuoi."
    }

    static func voci(_ p: ProfiloStile, clienti: [Cliente]) -> [VoceStile] {
        let nomi = Dictionary(clienti.map { ($0.id, $0.nome) }, uniquingKeysWith: { a, _ in a })
        var v: [VoceStile] = []
        if let r = p.cortesia {
            let c = r.valore
            let testo: String
            if let s = c.sogliaEta { testo = "Dai del tu ai clienti sotto i \(s) anni, del Lei agli altri" }
            else { testo = c.predefinita == .tu ? "Dai del tu ai clienti" : "Dai del Lei ai clienti" }
            let eccezioni = c.perCliente.sorted { (nomi[$0.key] ?? $0.key) < (nomi[$1.key] ?? $1.key) }
                .map { "del \($0.value.nome) a \(nomi[$0.key] ?? "un cliente non più in archivio")" }
            v.append(VoceStile(id: .cortesia, testo: testo, provenienza: r.provenienza, attiva: r.attiva,
                               dettaglio: eccezioni.isEmpty ? nil : "Eccezioni: " + eccezioni.joined(separator: "; ")))
        }
        if let r = p.lunghezzaFrasi {
            let testo = r.valore <= 15 ? "Frasi brevi: al massimo \(r.valore) parole" : "Frasi di al massimo \(r.valore) parole"
            v.append(VoceStile(id: .lunghezzaFrasi, testo: testo, provenienza: r.provenienza, attiva: r.attiva, dettaglio: nil))
        }
        if let r = p.unaCosaPerRiga, r.valore {
            v.append(VoceStile(id: .unaCosaPerRiga, testo: "Una cosa per riga", provenienza: r.provenienza, attiva: r.attiva, dettaglio: nil))
        }
        if let r = p.primaGiornoEOra, r.valore {
            v.append(VoceStile(id: .primaGiornoEOra, testo: "Prima il giorno e l'ora, poi il resto", provenienza: r.provenienza, attiva: r.attiva, dettaglio: nil))
        }
        if let r = p.firma {
            v.append(VoceStile(id: .firma, testo: "Firmi «\(r.valore)»", provenienza: r.provenienza, attiva: r.attiva, dettaglio: nil))
        }
        if let r = p.formuleVietate, !r.valore.isEmpty {
            v.append(VoceStile(id: .formuleVietate, testo: "Niente formule da ufficio", provenienza: r.provenienza, attiva: r.attiva,
                               dettaglio: r.valore.map { "«\($0)»" }.joined(separator: ", ")))
        }
        if let r = p.emoji {
            let testo: String
            switch r.valore {
            case .mai: testo = "Mai emoji"
            case .soloClientiNoti: testo = "Mai emoji con i clienti nuovi"
            case .libere: testo = "Emoji quando servono"
            }
            v.append(VoceStile(id: .emoji, testo: testo, provenienza: r.provenienza, attiva: r.attiva, dettaglio: nil))
        }
        if let r = p.aperture, !r.valore.isEmpty {
            v.append(VoceStile(id: .aperture, testo: "Apri con " + r.valore.map { "«\($0)»" }.joined(separator: " o "),
                               provenienza: r.provenienza, attiva: r.attiva, dettaglio: nil))
        }
        if let r = p.chiusure, !r.valore.isEmpty {
            v.append(VoceStile(id: .chiusure, testo: "Chiudi con " + r.valore.map { "«\($0)»" }.joined(separator: " o "),
                               provenienza: r.provenienza, attiva: r.attiva, dettaglio: nil))
        }
        return v
    }

    // MARK: - Applicare il profilo

    /// Tu o Lei per questo cliente: l'eccezione del cliente, poi la soglia d'età, poi la scelta di base.
    /// nil se il profilo non ha la regola (o è spenta).
    static func allocuzione(_ p: ProfiloStile, cliente: Cliente?, oggi: Date) -> Allocuzione? {
        guard let r = p.cortesia, r.attiva else { return nil }
        let c = r.valore
        if let cliente, let a = c.perCliente[cliente.id] { return a }
        if let s = c.sogliaEta, let cliente, let e = eta(cliente, al: oggi) { return e < s ? .tu : .lei }
        return c.predefinita
    }

    /// Il tono da passare a MessaggiVera perché la scheda dica lo stesso tu o Lei del profilo
    /// (cordiale e breve danno del tu, formale del Lei).
    static func tono(_ p: ProfiloStile, cliente: Cliente?, oggi: Date, richiesto: TonoMessaggio) -> TonoMessaggio {
        switch allocuzione(p, cliente: cliente, oggi: oggi) {
        case .lei?: return .formale
        case .tu?: return richiesto == .formale ? .cordiale : richiesto
        case nil: return richiesto
        }
    }

    /// La firma del profilo, da passare come `firma:` a MessaggiVera (che la aggiunge in fondo): nil se non c'è o è spenta.
    static func firma(_ p: ProfiloStile) -> String? {
        guard let f = p.firma, f.attiva else { return nil }
        let t = f.valore.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private static func emojiVietate(_ p: ProfiloStile, clienteNuovo: Bool) -> Bool {
        guard let e = p.emoji, e.attiva else { return false }
        return e.valore == .mai || (e.valore == .soloClientiNoti && clienteNuovo)
    }

    /// Le istruzioni di stile per Qwen, da accodare a quelle fisse di MessaggiVera (Vera/Istruzioni/stile.md più le
    /// regole del profilo per questo cliente). Firma e chiusura non ci sono: le aggiunge Prisma (`firma(_:)`).
    /// Stringa vuota se il profilo non ha regole accese.
    static func istruzioni(_ p: ProfiloStile, cliente: Cliente?, oggi: Date, clienteNuovo: Bool) -> String {
        var regole: [String] = []
        let nome = cliente.map { ModelliMessaggi.primoNome($0.nome.trimmingCharacters(in: .whitespaces)) } ?? ""
        if let a = allocuzione(p, cliente: cliente, oggi: oggi) {
            regole.append(a == .tu ? "Dai del tu" + (nome.isEmpty ? "" : " a \(nome)") + "."
                                   : "Dai del Lei" + (nome.isEmpty ? "" : " a \(nome)") + ", con le maiuscole (La, Le, Sua).")
        }
        if let r = p.lunghezzaFrasi, r.attiva { regole.append("Frasi brevi: al massimo \(r.valore) parole ciascuna.") }
        if let r = p.unaCosaPerRiga, r.attiva, r.valore { regole.append("Una cosa per riga: ogni frase va a capo, niente paragrafi lunghi.") }
        if let r = p.primaGiornoEOra, r.attiva, r.valore { regole.append("Se c'è un giorno o un'ora, scrivili nella prima frase, poi il resto.") }
        if let r = p.formuleVietate, r.attiva, !r.valore.isEmpty {
            regole.append("Non usare queste formule da ufficio: " + r.valore.map { "«\($0)»" }.joined(separator: ", ") + ".")
        }
        if emojiVietate(p, clienteNuovo: clienteNuovo) { regole.append("Niente emoji.") }
        if let r = p.aperture, r.attiva {
            let a = allocuzione(p, cliente: cliente, oggi: oggi)
            if let s = salutoAdatto(r.valore, a) { regole.append("Apri con «\(compila(s, cliente: cliente))».") }
        }
        guard !regole.isEmpty else { return "" }
        let testa = IstruzioniVera.testo("stile") ?? "STILE DEL CONSULENTE. Scrivi come scrive lui: segui queste regole del suo profilo di stile. Valgono per la forma; le regole sulle cifre e sui divieti restano quelle di sopra. Se una regola di forma di sopra dice altro, vale quella dello stile."
        return testa + "\n" + regole.map { "- " + $0 }.joined(separator: "\n")
    }

    /// I messaggi di MessaggiVera con lo stile accodato alle istruzioni di sistema (il primo messaggio di sistema).
    static func conStile(_ m: [MessaggioModello], profilo: ProfiloStile, cliente: Cliente?, oggi: Date, clienteNuovo: Bool) -> [MessaggioModello] {
        let s = istruzioni(profilo, cliente: cliente, oggi: oggi, clienteNuovo: clienteNuovo)
        guard !s.isEmpty else { return m }
        var r = m
        if let i = r.firstIndex(where: { $0.ruolo == .sistema }) {
            r[i].testo += "\n\n" + s
        } else {
            r.insert(MessaggioModello(ruolo: .sistema, testo: s), at: 0)
        }
        return r
    }

    /// I ritocchi sicuri del codice: niente parole nuove nel corpo, solo saluto, chiusura e firma del profilo, una cosa
    /// per riga, via le emoji vietate e le formule di cortesia d'ufficio che si tolgono senza cambiare il senso.
    /// Il tu o Lei del corpo non lo cambia il codice: lo segnala `verifica`.
    static func applica(_ testo: String, profilo p: ProfiloStile, cliente: Cliente?, oggi: Date, clienteNuovo: Bool) -> BozzaInStile {
        var modifiche: [String] = []
        var t = testo
        if emojiVietate(p, clienteNuovo: clienteNuovo), haEmoji(t) {
            t = senzaEmoji(t)
            modifiche.append("Tolte le emoji")
        }
        var s = struttura(t, firme: [firma(p)].compactMap { $0 })
        let a = allocuzione(p, cliente: cliente, oggi: oggi)

        // Il saluto d'apertura del profilo, se quello della bozza non è tra i suoi o dice il tu o Lei sbagliato
        if let r = p.aperture, r.attiva, let attuale = s.apertura {
            let modello = normale(modelloSaluto(attuale, cliente: cliente))
            let sbagliato = a != nil && allocuzione(diSaluto: attuale).map { $0 != a } == true
            if sbagliato || !r.valore.contains(where: { normale($0) == modello }),
               let scelto = salutoAdatto(r.valore, a) {
                let nuovo = compila(scelto, cliente: cliente)
                if nuovo != attuale {
                    s.apertura = nuovo
                    modifiche.append("Saluto d'apertura: «\(nuovo)»")
                }
            }
        }

        // Le formule d'ufficio che si tolgono da sole
        if let r = p.formuleVietate, r.attiva {
            let vietate = Set(r.valore.map(normale))
            var corpo: [String] = []
            for riga in s.corpo {
                var tenute: [String] = []
                for f in frasi(riga) {
                    let n = normale(f)
                    if frasiDaTogliere.contains(where: { vietate.contains(normale($0)) && n.hasPrefix(normale($0)) }) {
                        modifiche.append("Tolta «\(f)»")
                        continue
                    }
                    if vietate.contains("con la presente"), let (rr, _) = DateItaliane.cerca(#"^con la presente,?\s+"#, f) {
                        let resto = (f as NSString).substring(from: rr.location + rr.length)
                        tenute.append(resto.prefix(1).uppercased() + resto.dropFirst())
                        modifiche.append("Tolto «con la presente»")
                        continue
                    }
                    tenute.append(f)
                }
                if !tenute.isEmpty { corpo.append(tenute.joined(separator: " ")) }
            }
            s.corpo = corpo
        }

        // Una cosa per riga
        if let r = p.unaCosaPerRiga, r.attiva, r.valore, s.corpo.contains(where: { frasi($0).count > 1 }) {
            s.corpo = s.corpo.flatMap(frasi)
            modifiche.append("Una cosa per riga")
        }

        // La chiusura del profilo al posto di una che non è sua o che è una formula vietata
        if let r = p.chiusure, r.attiva, let prima = r.valore.first, let attuale = s.chiusura,
           !r.valore.contains(where: { normale($0) == normale(attuale) }) {
            s.chiusura = prima
            modifiche.append("Saluto di chiusura: «\(prima)»")
        }

        // La firma
        if let f = firma(p), normale(s.firma ?? "") != normale(f) {
            s.firma = f
            modifiche.append("Firma: «\(f)»")
        }
        return BozzaInStile(testo: modifiche.isEmpty ? testo : rimonta(s), modifiche: modifiche)
    }

    // MARK: - Verificare

    /// Le regole del profilo (accese) che la bozza non rispetta, nell'ordine del profilo.
    static func verifica(_ testo: String, profilo p: ProfiloStile, cliente: Cliente?, oggi: Date, clienteNuovo: Bool) -> [ViolazioneStile] {
        var v: [ViolazioneStile] = []
        let s = struttura(testo, firme: [firma(p)].compactMap { $0 })
        let nome = cliente.map { ModelliMessaggi.primoNome($0.nome.trimmingCharacters(in: .whitespaces)) } ?? "questo cliente"
        if let atteso = allocuzione(p, cliente: cliente, oggi: oggi),
           let scritto = allocuzione(di: ([s.apertura].compactMap { $0 } + s.corpo).joined(separator: "\n")), scritto != atteso {
            v.append(ViolazioneStile(regola: .cortesia, spiegazione: "Dai del \(atteso.nome) a \(nome): la bozza dà del \(scritto.nome).", grave: true))
        }
        if let r = p.lunghezzaFrasi, r.attiva, let lunga = s.corpo.flatMap(frasi).max(by: { parole($0) < parole($1) }), parole(lunga) > r.valore {
            v.append(ViolazioneStile(regola: .lunghezzaFrasi, spiegazione: "Una frase ha \(parole(lunga)) parole: il tuo massimo è \(r.valore).", grave: false))
        }
        if let r = p.unaCosaPerRiga, r.attiva, r.valore, s.corpo.contains(where: { frasi($0).count > 1 }) {
            v.append(ViolazioneStile(regola: .unaCosaPerRiga, spiegazione: "Una riga ha più di una frase: tu scrivi una cosa per riga.", grave: false))
        }
        if let r = p.primaGiornoEOra, r.attiva, r.valore, conta(quando, s.corpo.joined(separator: "\n")) > 0,
           !(s.corpo.first.flatMap { frasi($0).first }.map { conta(quando, $0) > 0 } ?? false) {
            v.append(ViolazioneStile(regola: .primaGiornoEOra, spiegazione: "Il giorno e l'ora non sono nella prima frase.", grave: false))
        }
        if let f = firma(p), normale(s.firma ?? "") != normale(f) {
            let detto = s.firma.map { "La firma è «\($0)»" } ?? "Manca la firma"
            v.append(ViolazioneStile(regola: .firma, spiegazione: "\(detto): tu firmi «\(f)».", grave: false))
        }
        if let r = p.formuleVietate, r.attiva {
            let n = normale(testo)
            let usate = r.valore.filter { n.contains(normale($0)) }
            if !usate.isEmpty {
                v.append(ViolazioneStile(regola: .formuleVietate, spiegazione: "Formule da ufficio che non usi: " + usate.map { "«\($0)»" }.joined(separator: ", ") + ".", grave: true))
            }
        }
        if emojiVietate(p, clienteNuovo: clienteNuovo), haEmoji(testo) {
            let perche = p.emoji?.valore == .mai ? "non usi emoji con i clienti" : "non usi emoji con i clienti nuovi"
            v.append(ViolazioneStile(regola: .emoji, spiegazione: "La bozza ha delle emoji: \(perche).", grave: true))
        }
        if let r = p.aperture, r.attiva, !r.valore.isEmpty, let a = s.apertura,
           !r.valore.contains(where: { normale($0) == normale(modelloSaluto(a, cliente: cliente)) }) {
            v.append(ViolazioneStile(regola: .aperture, spiegazione: "Il saluto «\(a)» non è tra i tuoi.", grave: false))
        }
        if let r = p.chiusure, r.attiva, !r.valore.isEmpty, let c = s.chiusura, !r.valore.contains(where: { normale($0) == normale(c) }) {
            v.append(ViolazioneStile(regola: .chiusure, spiegazione: "La chiusura «\(c)» non è tra le tue.", grave: false))
        }
        return v
    }

    /// Il motivo per cui il testo di Vera non si propone così (la prima violazione grave), da usare come MessaggiVera.controlla:
    /// nil se il testo segue il profilo nelle regole che contano.
    static func motivoScarto(_ violazioni: [ViolazioneStile]) -> String? {
        guard let g = violazioni.first(where: \.grave) else { return nil }
        return "il testo di Vera non segue il tuo stile (\(g.spiegazione.trimmingCharacters(in: CharacterSet(charactersIn: "."))))"
    }
}
