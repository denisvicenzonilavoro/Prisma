import Foundation

// La lettura dei dati di mercato (Mercato, giro 7): le risposte della BCE in SDMX-CSV (Data Portal,
// `format=csvdata`), quelle di Eurostat in JSON-stat 2.0 (dissemination API) e i file CSV del consulente
// (Design/mercato-csv.md: «data;valore» oppure «data;isin;valore»). Motore puro: niente rete, niente stato.

/// Perché una risposta o un file non si legge.
enum ErroreMercato: Error, Equatable {
    case rispostaVuota
    case formatoNonRiconosciuto(String)
    case rispostaDiErrore(String)
    case serieNonTrovata(String)
    case nessunValore
    case rete(String)
    case spento
    case richiestaNonValida(String)

    var descrizione: String {
        switch self {
        case .rispostaVuota: return "La risposta è vuota."
        case .formatoNonRiconosciuto(let cosa): return "La risposta non è nel formato atteso (\(cosa))."
        case .rispostaDiErrore(let testo): return "La fonte ha risposto con un errore: \(testo)"
        case .serieNonTrovata(let codice): return "La serie \(codice) non è stata trovata."
        case .nessunValore: return "Nella risposta non c'è nessun valore."
        case .rete(let testo): return "Connessione non riuscita: \(testo)"
        case .spento: return "«Dati di mercato» è spento: Prisma non esce su internet."
        case .richiestaNonValida(let codice): return "Il codice «\(codice)» non è un codice pubblico valido: nessuna richiesta."
        }
    }
}

/// Le osservazioni lette da una risposta, già datate e ordinate.
struct LetturaMercato: Equatable {
    var punti: [PuntoMercato]
    /// Le chiavi delle serie trovate nella risposta (BCE: colonna KEY).
    var chiavi: [String]
    /// Osservazioni senza valore o con un periodo illeggibile, saltate.
    var scartati: Int
}

/// Una riga del file CSV del consulente che non si è potuta leggere (la riga conta dall'1, intestazione compresa).
struct ErroreRigaMercato: Equatable {
    var riga: Int
    var testo: String
    var motivo: String
}

/// Il risultato dell'importazione di un CSV: una serie («data;valore») o le quote per ISIN («data;isin;valore»).
struct ImportazioneMercatoCSV: Equatable {
    enum Forma: String, Equatable { case serie, quote }

    var forma: Forma
    /// Forma «serie»: i valori letti, dal più vecchio.
    var punti: [PuntoMercato]
    /// Forma «quote»: le quote per ISIN normalizzato, dal più vecchio.
    var quote: [String: [PuntoMercato]]
    var errori: [ErroreRigaMercato]
    /// Le righe di dati lette (senza intestazione e righe vuote).
    var righe: Int

    var valoriLetti: Int { punti.count + quote.values.reduce(0) { $0 + $1.count } }
}

enum LettoreMercato {
    /// Il calendario delle date di mercato (ore 12, come `AiutiProva.data` e le date dei documenti).
    static let calendario = Calendar(identifier: .gregorian)

    // MARK: - BCE, SDMX-CSV

    /// Le osservazioni di una risposta SDMX-CSV della BCE: colonne TIME_PERIOD e OBS_VALUE (con KEY per riconoscere
    /// la serie). Con `chiave` si tengono solo le righe di quella serie (KEY senza il flusso o con il flusso davanti).
    static func sdmxCSV(_ testo: String, chiave: String? = nil) throws -> LetturaMercato {
        let righe = righeDiTesto(testo)
        guard let testa = righe.first else { throw ErroreMercato.rispostaVuota }
        let colonne = campi(testa, separatore: ",").map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
        guard let iPeriodo = colonne.firstIndex(of: "TIME_PERIOD"), let iValore = colonne.firstIndex(of: "OBS_VALUE") else {
            // La BCE risponde con un testo semplice quando la serie non c'è («No results found»)
            if testa.lowercased().contains("no results") || testa.lowercased().contains("not found") {
                throw ErroreMercato.serieNonTrovata(chiave ?? "")
            }
            throw ErroreMercato.formatoNonRiconosciuto("mancano TIME_PERIOD o OBS_VALUE")
        }
        let iChiave = colonne.firstIndex(of: "KEY") ?? colonne.firstIndex(of: "SERIES_KEY")
        let attesa = chiave.map { $0.uppercased() }
        var punti: [PuntoMercato] = []
        var chiavi: [String] = []
        var scartati = 0
        for riga in righe.dropFirst() {
            let c = campi(riga, separatore: ",")
            guard c.count > max(iPeriodo, iValore) else { scartati += 1; continue }
            if let iChiave, iChiave < c.count {
                let k = c[iChiave].trimmingCharacters(in: .whitespaces).uppercased()
                if let attesa, !(k == attesa || attesa.hasSuffix("." + k) || k.hasSuffix("." + attesa)) { continue }
                if !k.isEmpty, !chiavi.contains(k) { chiavi.append(k) }
            }
            let v = c[iValore].trimmingCharacters(in: .whitespaces)
            guard let data = periodo(c[iPeriodo]), let valore = Double(v), valore.isFinite else { scartati += 1; continue }
            punti.append(PuntoMercato(data: data, valore: valore))
        }
        guard !punti.isEmpty else { throw ErroreMercato.nessunValore }
        return LetturaMercato(punti: ordinati(punti), chiavi: chiavi, scartati: scartati)
    }

    // MARK: - Eurostat, JSON-stat 2.0

    /// Le osservazioni di una risposta JSON-stat 2.0 di Eurostat lungo la dimensione del tempo. Le altre dimensioni
    /// sono fissate dai filtri della richiesta (una sola voce ciascuna); se ne restano di più vale la prima voce.
    static func jsonStat(_ dati: Data) throws -> LetturaMercato {
        guard !dati.isEmpty else { throw ErroreMercato.rispostaVuota }
        guard let radice = (try? JSONSerialization.jsonObject(with: dati)) as? [String: Any] else {
            throw ErroreMercato.formatoNonRiconosciuto("non è JSON")
        }
        if let errore = radice["error"] {
            throw ErroreMercato.rispostaDiErrore(testoErrore(errore))
        }
        guard let id = radice["id"] as? [String], let dimensioni = radice["dimension"] as? [String: Any],
              let misure = (radice["size"] as? [Any])?.compactMap(intero), misure.count == id.count, !id.isEmpty else {
            throw ErroreMercato.formatoNonRiconosciuto("mancano id, size o dimension")
        }
        let ruoli = radice["role"] as? [String: Any]
        let nomeTempo = (ruoli?["time"] as? [String])?.first(where: { id.contains($0) })
            ?? ["time", "TIME_PERIOD", "TIME"].first(where: { id.contains($0) })
        guard let nomeTempo, let t = id.firstIndex(of: nomeTempo),
              let dTempo = dimensioni[nomeTempo] as? [String: Any], let categoria = dTempo["category"] as? [String: Any] else {
            throw ErroreMercato.formatoNonRiconosciuto("manca la dimensione del tempo")
        }
        // I codici del tempo nell'ordine della loro posizione
        var periodi: [(codice: String, posizione: Int)] = []
        if let indice = categoria["index"] as? [String: Any] {
            for (codice, v) in indice {
                if let n = intero(v) { periodi.append((codice: codice, posizione: n)) }
            }
            periodi.sort { $0.posizione < $1.posizione }
        } else if let indice = categoria["index"] as? [String] {
            for (n, codice) in indice.enumerated() { periodi.append((codice: codice, posizione: n)) }
        } else if let etichette = categoria["label"] as? [String: Any], etichette.count == 1, let solo = etichette.keys.first {
            periodi = [(codice: solo, posizione: 0)]
        }
        guard !periodi.isEmpty else { throw ErroreMercato.formatoNonRiconosciuto("periodi assenti") }
        // Passo di ogni dimensione nell'elenco piatto dei valori (la prima dimensione cambia più lentamente)
        var passi = Array(repeating: 1, count: misure.count)
        if misure.count > 1 {
            for k in stride(from: misure.count - 2, through: 0, by: -1) { passi[k] = passi[k + 1] * max(misure[k + 1], 1) }
        }
        let valori = radice["value"]
        func valore(_ posizione: Int) -> Double? {
            if let elenco = valori as? [Any] {
                guard posizione >= 0, posizione < elenco.count else { return nil }
                return numero(elenco[posizione])
            }
            if let mappa = valori as? [String: Any] { return mappa[String(posizione)].flatMap(numero) }
            return nil
        }
        var punti: [PuntoMercato] = []
        var scartati = 0
        for p in periodi {
            guard p.posizione < misure[t] else { scartati += 1; continue }
            guard let data = periodo(p.codice), let v = valore(p.posizione * passi[t]), v.isFinite else { scartati += 1; continue }
            punti.append(PuntoMercato(data: data, valore: v))
        }
        guard !punti.isEmpty else { throw ErroreMercato.nessunValore }
        let estensione = radice["extension"] as? [String: Any]
        let codice = (estensione?["id"] as? String).map { [$0.lowercased()] } ?? []
        return LetturaMercato(punti: ordinati(punti), chiavi: codice, scartati: scartati)
    }

    private static func intero(_ v: Any) -> Int? {
        if let n = v as? NSNumber { return n.intValue }
        if let s = v as? String { return Int(s) }
        return nil
    }

    private static func numero(_ v: Any) -> Double? {
        if v is NSNull { return nil }
        if let n = v as? NSNumber { return n.doubleValue }
        if let s = v as? String { return Double(s) }
        return nil
    }

    private static func testoErrore(_ errore: Any) -> String {
        if let s = errore as? String { return s }
        if let d = errore as? [String: Any] {
            return (d["label"] as? String) ?? (d["message"] as? String) ?? (d["status"].map { "\($0)" } ?? "errore")
        }
        if let elenco = errore as? [Any], let primo = elenco.first { return testoErrore(primo) }
        return "errore"
    }

    // MARK: - Periodi

    /// Il giorno di un periodo SDMX o JSON-stat, alle 12: «2026-10-23» quel giorno; «2026-10» e «2026M10» il primo del
    /// mese; «2026-Q3» e «2026Q3» il primo del trimestre; «2026-S2» il primo del semestre; «2026» il primo gennaio.
    static func periodo(_ s: String) -> Date? {
        let t = s.trimmingCharacters(in: .whitespaces).uppercased()
        let parti = t.split(separator: "-").map(String.init)
        func giorno(_ a: Int, _ m: Int, _ g: Int) -> Date? { dataValida(a, m, g) }
        if parti.count == 3, parti[0].count == 4, let a = Int(parti[0]), let m = Int(parti[1]), let g = Int(parti[2]) {
            return giorno(a, m, g)
        }
        if parti.count == 2, parti[0].count == 4, let a = Int(parti[0]) {
            let p = parti[1]
            if let m = Int(p) { return giorno(a, m, 1) }
            if p.hasPrefix("Q"), let q = Int(p.dropFirst()), (1...4).contains(q) { return giorno(a, (q - 1) * 3 + 1, 1) }
            if p.hasPrefix("S"), let h = Int(p.dropFirst()), (1...2).contains(h) { return giorno(a, h == 1 ? 1 : 7, 1) }
            return nil
        }
        if parti.count == 1, t.count >= 4, let a = Int(t.prefix(4)) {
            let resto = t.dropFirst(4)
            if resto.isEmpty { return giorno(a, 1, 1) }
            if resto.hasPrefix("M"), let m = Int(resto.dropFirst()) { return giorno(a, m, 1) }
            if resto.hasPrefix("Q"), let q = Int(resto.dropFirst()), (1...4).contains(q) { return giorno(a, (q - 1) * 3 + 1, 1) }
        }
        return nil
    }

    /// Una data vera (niente 31 febbraio), alle 12.
    static func dataValida(_ anno: Int, _ mese: Int, _ giorno: Int) -> Date? {
        guard (1900...2200).contains(anno), (1...12).contains(mese), (1...31).contains(giorno),
              let d = calendario.date(from: DateComponents(year: anno, month: mese, day: giorno, hour: 12)) else { return nil }
        let c = calendario.dateComponents([.year, .month, .day], from: d)
        guard c.year == anno, c.month == mese, c.day == giorno else { return nil }
        return d
    }

    // MARK: - CSV del consulente (Design/mercato-csv.md)

    /// Legge un CSV «data;valore» (una serie) o «data;isin;valore» (quote per ISIN). Separatore «;» o «,» (con la
    /// virgola il decimale è il punto; con il punto e virgola vale la virgola o il punto); intestazione facoltativa.
    /// Le righe sbagliate finiscono in `errori` e non fermano le altre. `oggi`: le date future sono errori.
    static func importaCSV(_ testo: String, oggi: Date) -> ImportazioneMercatoCSV {
        let tutte = testo.replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
        // Le righe con il loro numero nel file, senza quelle vuote
        let numerate = tutte.enumerated().map { (numero: $0.offset + 1, testo: $0.element) }
            .filter { !$0.testo.trimmingCharacters(in: .whitespaces).isEmpty }
        var esito = ImportazioneMercatoCSV(forma: .serie, punti: [], quote: [:], errori: [], righe: 0)
        guard let prima = numerate.first else { return esito }
        let separatore: Character = prima.testo.contains(";") ? ";" : (prima.testo.contains("\t") ? "\t" : ",")
        // Intestazione: la prima riga se la sua prima cella non è una data
        let primaCelle = campi(prima.testo, separatore: separatore).map { $0.trimmingCharacters(in: .whitespaces) }
        var iData = 0, iISIN: Int? = nil, iValore = 1
        // Le colonne attese: quelle dell'intestazione o della prima riga (una in più vuol dire un decimale con la
        // virgola in un file separato da virgole: «18,4» diventerebbe «18»)
        let colonneAttese = primaCelle.count
        var dati = numerate
        if dataCSV(primaCelle.first ?? "") == nil {
            dati = Array(numerate.dropFirst())
            let nomi = primaCelle.map(chiaveIntestazione)
            if let d = nomi.firstIndex(of: "data"), let v = nomi.firstIndex(of: "valore") {
                iData = d
                iValore = v
                iISIN = nomi.firstIndex(of: "isin")
            } else if primaCelle.count >= 3 {
                iISIN = 1
                iValore = 2
            }
        } else if primaCelle.count >= 3 {
            iISIN = 1
            iValore = 2
        }
        esito.forma = iISIN == nil ? .serie : .quote
        let inizioDomani = calendario.date(byAdding: .day, value: 1, to: calendario.startOfDay(for: oggi)) ?? oggi
        var visteSerie = Set<Date>()
        var visteQuote = Set<String>()
        var punti: [PuntoMercato] = []
        var quote: [String: [PuntoMercato]] = [:]
        for r in dati {
            esito.righe += 1
            let c = campi(r.testo, separatore: separatore).map { $0.trimmingCharacters(in: .whitespaces) }
            func errore(_ motivo: String) { esito.errori.append(ErroreRigaMercato(riga: r.numero, testo: r.testo, motivo: motivo)) }
            let necessarie = max(iData, iValore, iISIN ?? 0) + 1
            guard c.count >= necessarie else { errore(TestiMercato.erroreColonne(necessarie)); continue }
            guard c.count <= colonneAttese || c.dropFirst(colonneAttese).allSatisfy({ $0.isEmpty }) else {
                errore(TestiMercato.erroreTroppeColonne)
                continue
            }
            guard let data = dataCSV(c[iData]) else { errore(TestiMercato.erroreData); continue }
            guard data < inizioDomani else { errore(TestiMercato.erroreDataFutura); continue }
            guard let valore = numeroCSV(c[iValore], separatore: separatore) else { errore(TestiMercato.erroreValore); continue }
            if let iISIN {
                let isin = MotoreMercato.normalizzaISIN(c[iISIN])
                guard MotoreMercato.isinValido(isin) else { errore(TestiMercato.erroreISIN); continue }
                guard valore > 0 else { errore(TestiMercato.erroreQuotaNonPositiva); continue }
                let chiave = "\(isin)|\(calendario.startOfDay(for: data).timeIntervalSinceReferenceDate)"
                guard visteQuote.insert(chiave).inserted else { errore(TestiMercato.erroreRipetuta); continue }
                quote[isin, default: []].append(PuntoMercato(data: data, valore: valore))
            } else {
                guard visteSerie.insert(calendario.startOfDay(for: data)).inserted else { errore(TestiMercato.erroreRipetuta); continue }
                punti.append(PuntoMercato(data: data, valore: valore))
            }
        }
        esito.punti = ordinati(punti)
        esito.quote = quote.mapValues(ordinati)
        return esito
    }

    /// «data», «isin», «valore» per i nomi di colonna riconosciuti (anche in inglese); "" per gli altri.
    private static func chiaveIntestazione(_ s: String) -> String {
        let t = s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Formati.italiano)
            .trimmingCharacters(in: .whitespaces).lowercased()
        if ["data", "date", "giorno", "data valore", "periodo"].contains(t) { return "data" }
        if ["isin", "codice isin", "codice"].contains(t) { return "isin" }
        if ["valore", "quota", "prezzo", "nav", "value", "close", "chiusura", "valore quota", "livello", "tasso"].contains(t) { return "valore" }
        return ""
    }

    /// Le date del CSV: «2026-10-30», «30/10/2026», «30.10.2026», «30-10-2026», «2026-10» (il primo del mese).
    static func dataCSV(_ s: String) -> Date? {
        let t = s.trimmingCharacters(in: .whitespaces)
        let parti = t.split(whereSeparator: { "/.-".contains($0) }).map(String.init)
        guard parti.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else { return nil }
        if parti.count == 3, let x = Int(parti[0]), let y = Int(parti[1]), let z = Int(parti[2]) {
            if parti[0].count == 4 { return dataValida(x, y, z) }
            if parti[2].count == 4 { return dataValida(z, y, x) }
            return nil
        }
        if parti.count == 2, parti[0].count == 4, let a = Int(parti[0]), let m = Int(parti[1]) { return dataValida(a, m, 1) }
        return nil
    }

    /// Un valore del CSV: niente separatore delle migliaia. Con la virgola come separatore di colonna il decimale è il
    /// punto; con il punto e virgola vale la virgola o il punto (uno solo). Ammessi il meno tipografico, € e %.
    static func numeroCSV(_ s: String, separatore: Character) -> Double? {
        var t = s.replacingOccurrences(of: "\u{2212}", with: "-").replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "%", with: "").replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard !t.isEmpty else { return nil }
        let virgole = t.filter { $0 == "," }.count
        let punti = t.filter { $0 == "." }.count
        guard virgole + punti <= 1 else { return nil }
        if virgole == 1 {
            guard separatore != "," else { return nil }
            t = t.replacingOccurrences(of: ",", with: ".")
        }
        guard t.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" || $0 == "+" }), let v = Double(t), v.isFinite else { return nil }
        return v
    }

    /// Un valore scritto a mano: «18,42», «18.42», «−0,25», «3,42%» (niente migliaia).
    static func valoreAMano(_ testo: String) -> Double? { numeroCSV(testo, separatore: ";") }

    /// Una data scritta a mano, come nel CSV.
    static func dataAMano(_ testo: String) -> Date? { dataCSV(testo) }

    // MARK: - Aiuti

    /// Le righe non vuote di un testo (a capo di Windows compresi).
    static func righeDiTesto(_ testo: String) -> [String] {
        testo.replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// I campi di una riga, con le virgolette («"a, b"» resta un campo; «""» è una virgoletta).
    static func campi(_ riga: String, separatore: Character) -> [String] {
        var elenco: [String] = []
        var campo = ""
        var tra = false
        var precedenteVirgoletta = false
        for ch in riga {
            if tra {
                if ch == "\"" {
                    tra = false
                    precedenteVirgoletta = true
                    continue
                }
                campo.append(ch)
            } else if ch == "\"" {
                // «""» dentro un campo tra virgolette: una virgoletta vera
                if precedenteVirgoletta { campo.append("\"") }
                tra = true
            } else if ch == separatore {
                elenco.append(campo)
                campo = ""
            } else {
                campo.append(ch)
            }
            precedenteVirgoletta = false
        }
        elenco.append(campo)
        return elenco
    }

    /// Dal più vecchio; a parità di giorno resta l'ultimo letto.
    static func ordinati(_ punti: [PuntoMercato]) -> [PuntoMercato] {
        var perGiorno: [Date: PuntoMercato] = [:]
        for p in punti { perGiorno[calendario.startOfDay(for: p.data)] = p }
        return perGiorno.values.sorted { $0.data < $1.data }
    }
}
