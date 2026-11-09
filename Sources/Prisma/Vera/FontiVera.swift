import Foundation

// «Mai a caso» (Vera/BRIEF.md, funzione 19; template «Mai a caso»): ogni cifra di una risposta di Vera ha la sua fonte.
// Il codice estrae i numeri dal testo di Qwen come valori (non come stringhe: «20.800 €» e «20800 euro» sono la
// stessa cifra) e li abbina a quello che Prisma ha dato al modello: le posizioni con la data del valore, i dati letti
// dai documenti con la pagina, le righe della scheda e dei calcoli di Prisma con il loro blocco, la domanda del
// consulente. Una cifra senza fonte resta «non trovata» e si vede: Vera non la inventa e il consulente non la usa.
// Date, orari e anni non sono cifre da controllare.

/// Di che cosa è una cifra.
enum UnitaCifra: String, Codable {
    case euro, percento, anni, mesi, nessuna
}

/// Un numero trovato in un testo.
struct NumeroNelTesto: Equatable {
    /// Come è scritto, unità compresa («20.800 €», «1,5%»).
    var testo: String
    var valore: Double
    var unita: UnitaCifra
    /// Dove sta nel testo (NSRange, per rimettere i rimandi).
    var posizione: NSRange
}

/// Una fonte possibile: il valore e da dove viene.
struct VoceFonte: Equatable {
    var valore: Double
    var unita: UnitaCifra
    /// «Posizioni · Piano casa», «Documento «Contratto» · pagina 4», «Calcoli di Prisma · Quadro».
    var origine: String
    /// «Giulia Rossi · valore al 30 ottobre», la riga della scheda…
    var dettaglio: String
    var app: AppPrisma?
}

/// La fonte di una cifra della risposta (salvata nel messaggio, MessaggioVera.fonti).
struct FonteCifra: Codable, Equatable, Identifiable {
    /// Il numero del rimando nel testo (¹, ², …).
    var id: Int
    var testo: String
    var trovata: Bool
    var origine: String
    var dettaglio: String
    var app: AppPrisma?

    private enum CodingKeys: String, CodingKey { case id, testo, trovata, origine, dettaglio, app }

    init(id: Int, testo: String, trovata: Bool, origine: String, dettaglio: String, app: AppPrisma?) {
        self.id = id
        self.testo = testo
        self.trovata = trovata
        self.origine = origine
        self.dettaglio = dettaglio
        self.app = app
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        testo = (try? c.decodeIfPresent(String.self, forKey: .testo)) ?? ""
        trovata = (try? c.decodeIfPresent(Bool.self, forKey: .trovata)) ?? false
        origine = (try? c.decodeIfPresent(String.self, forKey: .origine)) ?? ""
        dettaglio = (try? c.decodeIfPresent(String.self, forKey: .dettaglio)) ?? ""
        app = (try? c.decodeIfPresent(AppPrisma.self, forKey: .app)) ?? nil
    }
}

enum FontiVera {
    /// La spiegazione di una cifra senza fonte.
    static let nonTrovata = "Non viene da Prisma: non la trovo nella scheda, nei calcoli o nei documenti. Non usarla."
    static let origineDomanda = "La tua domanda"
    static let origineFilo = "Filo della conversazione"
    static let origineDocumenti = "Documenti e note del cliente"

    // MARK: - I numeri nel testo

    private static let mesi = DateItaliane.mesi.joined(separator: "|")
    private static let schema = try? NSRegularExpression(
        pattern: #"(?<![\p{L}\d.,:/])([+\-−]?(?:\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+\.\d{1,2}(?![\d.])|\d+(?:,\d+)?))(?![\d/])(\s?(?:€|euro\b|%|per cento\b|anni\b|anno\b|mesi\b|mese\b))?"#,
        options: [.caseInsensitive])

    /// I numeri di un testo, come valori. Restano fuori orari (10:00), date (5 novembre, 1° marzo, 12/03), anni
    /// (2028) e numeri attaccati alle parole («qwen3»).
    static func numeri(_ testo: String) -> [NumeroNelTesto] {
        guard let re = schema else { return [] }
        let ns = testo as NSString
        var trovati: [NumeroNelTesto] = []
        for m in re.matches(in: testo, range: NSRange(location: 0, length: ns.length)) {
            let cifra = ns.substring(with: m.range(at: 1))
            let unitaTesto = m.range(at: 2).location == NSNotFound ? "" : ns.substring(with: m.range(at: 2)).lowercased()
            let fine = m.range.location + m.range.length
            let dopo = ns.substring(from: min(fine, ns.length))
            // Un orario o un giorno con il mese dopo: non è una cifra
            // Un orario («15:30») ha una cifra subito dopo i due punti; «il 15%: meno…» è una cifra
            if dopo.hasPrefix(":"), unitaTesto.isEmpty, dopo.dropFirst().first?.isNumber == true { continue }
            if dopo.hasPrefix("°") || dopo.hasPrefix("ª") { continue }
            if unitaTesto.isEmpty, DateItaliane.cerca(#"^\s*(?:"# + mesi + #")\b"#, dopo.lowercased()) != nil { continue }
            guard let valore = valore(cifra) else { continue }
            let unita: UnitaCifra
            switch unitaTesto.trimmingCharacters(in: .whitespaces) {
            case "€", "euro": unita = .euro
            case "%", "per cento": unita = .percento
            case "anni", "anno": unita = .anni
            case "mesi", "mese": unita = .mesi
            default: unita = .nessuna
            }
            // Un anno da solo (1900-2100, senza unità e senza separatori): è una data
            if unita == .nessuna, !cifra.contains("."), !cifra.contains(","), valore >= 1900, valore <= 2100, valore == valore.rounded() { continue }
            trovati.append(NumeroNelTesto(testo: ns.substring(with: m.range).trimmingCharacters(in: .whitespaces), valore: valore, unita: unita, posizione: m.range))
        }
        return trovati
    }

    /// «20.800» → 20800, «1,5» → 1,5, «1.234,56» → 1234,56, «−3» → −3.
    static func valore(_ s: String) -> Double? {
        var t = s.replacingOccurrences(of: "−", with: "-").replacingOccurrences(of: "+", with: "")
        if t.contains(",") {
            t = t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else if t.range(of: #"^-?\d{1,3}(\.\d{3})+$"#, options: .regularExpression) != nil {
            t = t.replacingOccurrences(of: ".", with: "")
        }
        return Double(t)
    }

    // MARK: - Le fonti possibili

    /// Le fonti del dossier di un cliente: posizioni (valore con la sua data, premio, capitale assicurato), dati letti
    /// dai documenti con la pagina, l'età del cliente.
    static func registro(_ f: FonteVera) -> [VoceFonte] {
        var voci: [VoceFonte] = []
        for p in f.posizioni where p.stato != .chiusa {
            let origine = "Posizioni · \(p.nome)"
            let quando = p.dataValore.map { " · valore al \(Formati.giornoMese.string(from: $0))" } ?? ""
            voci.append(VoceFonte(valore: p.valore, unita: .euro, origine: origine, dettaglio: "\(f.cliente.nome)\(quando) · \(p.canale.nomeBreve)", app: .posizioni))
            if p.premio > 0 {
                voci.append(VoceFonte(valore: p.premio, unita: .euro, origine: origine, dettaglio: "\(f.cliente.nome) · premio · \(p.canale.nomeBreve)", app: .posizioni))
            }
            if let c = p.capitaleAssicurato, c > 0 {
                voci.append(VoceFonte(valore: c, unita: .euro, origine: origine, dettaglio: "\(f.cliente.nome) · capitale assicurato · \(p.canale.nomeBreve)", app: .posizioni))
            }
        }
        for d in f.documenti {
            for campo in d.campi {
                for n in numeri(campo.valore) {
                    let conferma = campo.confermato ? "" : ", da confermare"
                    voci.append(VoceFonte(valore: n.valore, unita: n.unita, origine: "Documento «\(d.titolo)» · pagina \(campo.pagina)",
                                          dettaglio: "\(campo.chiave.nome): \(campo.valore)\(conferma)", app: .documenti))
                }
            }
        }
        if let e = f.cliente.eta {
            voci.append(VoceFonte(valore: Double(e), unita: .anni, origine: "Clienti · \(f.cliente.nome)", dettaglio: "età dalla data di nascita", app: .clienti))
        }
        return voci
    }

    /// Le fonti di un testo che Prisma ha dato al modello (la scheda, la bozza, i calcoli, la domanda): ogni numero
    /// con il blocco da cui viene («QUADRO (calcolato da Prisma)» → «Calcoli di Prisma · Quadro») e la sua riga.
    static func registro(testo: String) -> [VoceFonte] {
        var voci: [VoceFonte] = []
        var blocco = "Calcoli di Prisma"
        for riga in testo.components(separatedBy: .newlines) {
            var contenuto = riga.trimmingCharacters(in: .whitespaces)
            if let (titolo, resto) = intestazione(contenuto) {
                blocco = titolo
                contenuto = resto
            }
            guard !contenuto.isEmpty else { continue }
            // Le cifre del riassunto le ha scritte il modello: non sono una fonte (restano «non trovate»)
            if blocco == origineFilo { continue }
            var origine = blocco
            var riga = contenuto
            var app: AppPrisma?
            // «[Documento «KID» · pagina 2] …»: la fonte vera è il documento con la pagina
            if blocco == origineDocumenti, contenuto.hasPrefix("["), let fine = contenuto.firstIndex(of: "]") {
                origine = String(contenuto[contenuto.index(after: contenuto.startIndex)..<fine])
                riga = String(contenuto[contenuto.index(after: fine)...]).trimmingCharacters(in: .whitespaces)
                app = .documenti
            }
            for n in numeri(riga) {
                voci.append(VoceFonte(valore: n.valore, unita: n.unita, origine: origine, dettaglio: String(riga.prefix(140)), app: app))
            }
        }
        return voci
    }

    /// «POSIZIONI IN ESSERE» → («Calcoli di Prisma · Posizioni in essere», ""); «DOMANDA DEL CONSULENTE: quanto…» →
    /// («La tua domanda», «quanto…»). nil per una riga normale.
    static func intestazione(_ riga: String) -> (String, String)? {
        guard let (_, g) = DateItaliane.cerca(#"^([A-ZÀÈÉÌÒÙ][A-ZÀÈÉÌÒÙ0-9' ]{3,})(?:\s*\([^)]*\))?\s*:?\s*(.*)$"#, riga),
              g[1].uppercased() == g[1], g[1].contains(where: \.isLetter),
              // Una sigla in testa a una riga («KID: …», «SRI 3») non è un'intestazione
              g[1].trimmingCharacters(in: .whitespaces).count >= 5 else { return nil }
        let nome = g[1].trimmingCharacters(in: .whitespaces).lowercased()
        let bello = nome.prefix(1).uppercased() + nome.dropFirst()
        let resto = g[2].trimmingCharacters(in: .whitespaces)
        switch nome {
        case let n where n.hasPrefix("domanda"): return (origineDomanda, resto)
        case let n where n.hasPrefix("contesto"): return ("Contesto", resto)
        case let n where n.hasPrefix("scheda"): return ("Scheda del cliente · Prisma", resto)
        case let n where n.hasPrefix("bozza"): return ("Bozza di Prisma", resto)
        case let n where n.hasPrefix("calcoli"): return ("Calcoli di Prisma", resto)
        case let n where n.hasPrefix("il filo"): return (origineFilo, resto)
        case let n where n.hasPrefix("ricordi"): return ("Memoria di Vera", resto)
        case let n where n.hasPrefix("dai documenti"): return (origineDocumenti, resto)
        default: return ("Calcoli di Prisma · \(bello)", resto)
        }
    }

    // MARK: - L'abbinamento

    /// Due valori sono la stessa cifra: al centesimo per gli euro (con l'arrotondamento all'euro), al decimo di punto
    /// per le percentuali, esatti per il resto.
    static func coincide(_ n: NumeroNelTesto, _ v: VoceFonte) -> Bool {
        if n.unita != .nessuna, v.unita != .nessuna, n.unita != v.unita { return false }
        let tolleranza: Double
        switch n.unita == .nessuna ? v.unita : n.unita {
        case .euro: tolleranza = 0.51
        case .percento: tolleranza = 0.051
        default: tolleranza = 0.001
        }
        return abs(n.valore - v.valore) <= tolleranza
    }

    /// Le fonti delle cifre di una risposta, nell'ordine in cui compaiono (una cifra ripetuta ha lo stesso rimando).
    /// Un numero piccolo senza unità (2 polizze, 3 punti) che non si trova non conta: non è una cifra da controllare.
    static func abbina(_ risposta: String, registro: [VoceFonte]) -> [FonteCifra] {
        var cifre: [FonteCifra] = []
        var gia: [String: Int] = [:]
        for n in numeri(risposta) {
            let chiave = "\(n.valore)-\(n.unita.rawValue)"
            if gia[chiave] != nil { continue }
            // Prima le fonti del dossier (più precise), poi i blocchi della scheda, ultima la domanda
            let ordinate = registro.filter { $0.origine != origineDomanda } + registro.filter { $0.origine == origineDomanda }
            if let v = ordinate.first(where: { coincide(n, $0) }) {
                cifre.append(FonteCifra(id: cifre.count + 1, testo: n.testo, trovata: true, origine: v.origine, dettaglio: v.dettaglio, app: v.app))
            } else if n.unita == .nessuna, abs(n.valore) <= 31, n.valore == n.valore.rounded() {
                continue
            } else {
                cifre.append(FonteCifra(id: cifre.count + 1, testo: n.testo, trovata: false, origine: "Non trovato", dettaglio: nonTrovata, app: nil))
            }
            gia[chiave] = cifre.count
        }
        return cifre
    }

    /// Le fonti di una risposta in modalità lavoro: il dossier del cliente e il messaggio dato al modello.
    static func fonti(_ risposta: String, fonte: FonteVera?, richiesta: String) -> [FonteCifra] {
        abbina(risposta, registro: (fonte.map(registro) ?? []) + registro(testo: richiesta))
    }

    // MARK: - I rimandi nel testo

    private static let apici: [Character] = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]

    static func apice(_ n: Int) -> String { String(String(n).compactMap { $0.wholeNumberValue.map { apici[$0] } }) }

    /// Il testo con il rimando dopo ogni cifra che ha una voce tra le fonti: «20.800 €¹».
    static func conRimandi(_ testo: String, fonti: [FonteCifra]) -> String {
        guard !fonti.isEmpty else { return testo }
        let ns = NSMutableString(string: testo)
        let per = Dictionary(fonti.map { (Self.chiave($0.testo), $0.id) }, uniquingKeysWith: { a, _ in a })
        for n in numeri(testo).reversed() {
            guard let id = per[chiave(n.testo)] else { continue }
            ns.insert(apice(id), at: n.posizione.location + n.posizione.length)
        }
        return ns as String
    }

    private static func chiave(_ testo: String) -> String {
        guard let n = numeri(testo).first else { return testo }
        return "\(n.valore)-\(n.unita.rawValue)"
    }
}
