import Foundation

// Spese, scadenze e ore di aggiornamento di Studio › Spese (Design/template-luce-specifica.md §6.3.5 punti 4-5, «Luce»
// giro 9). Motore puro: somme, elenchi e ricorrenze sui dati scritti dall'utente. Nessuna regola fiscale (decisione 66):
// niente deducibilità, niente IVA detraibile, niente calendario fiscale, niente requisito di ore.

enum MotoreSpese {
    /// Le spese di un mese, in ordine di data (le più vecchie prima, come nel template).
    static func delMese(_ spese: [SpesaStudio], mese: Date, calendario cal: Calendar = .current) -> [SpesaStudio] {
        let inizio = MotoreChilometri.inizioMese(mese, cal)
        guard let fine = cal.date(byAdding: .month, value: 1, to: inizio) else { return [] }
        return spese.filter { $0.data >= inizio && $0.data < fine }.sorted { ($0.data, $0.id) < ($1.data, $1.id) }
    }

    /// La somma vera delle spese date (al centesimo).
    static func totale(_ spese: [SpesaStudio]) -> Double {
        (spese.map(\.importo).reduce(0, +) * 100).rounded() / 100
    }

    /// I totali per categoria, nell'ordine delle categorie, solo quelle con spese.
    static func perCategoria(_ spese: [SpesaStudio]) -> [(categoria: CategoriaSpesa, totale: Double)] {
        CategoriaSpesa.allCases.compactMap { c in
            let delle = spese.filter { $0.categoria == c }
            return delle.isEmpty ? nil : (c, totale(delle))
        }
    }

    // MARK: Scadenze

    /// Le prossime scadenze da fare: entro `giorni` da oggi (anche quelle già passate e non segnate fatte, prima), in
    /// ordine di data, al più `limite`.
    static func prossime(_ scadenze: [ScadenzaStudio], oggi: Date, giorni: Int = 90, limite: Int = 4,
                         calendario cal: Calendar = .current) -> [ScadenzaStudio] {
        let fine = cal.date(byAdding: .day, value: giorni + 1, to: cal.startOfDay(for: oggi)) ?? oggi
        return Array(scadenze.filter { $0.fattaIl == nil && $0.data < fine }
            .sorted { ($0.data, $0.titolo) < ($1.data, $1.titolo) }
            .prefix(limite))
    }

    /// Vero se la scadenza è passata e non è stata segnata fatta.
    static func passata(_ s: ScadenzaStudio, oggi: Date, calendario cal: Calendar = .current) -> Bool {
        s.fattaIl == nil && s.data < cal.startOfDay(for: oggi)
    }

    /// La data della volta dopo di una scadenza ricorrente (lo stesso giorno del mese, fermato all'ultimo se manca).
    static func prossimaData(_ data: Date, ricorrenza: RicorrenzaScadenza, calendario cal: Calendar = .current) -> Date {
        let giorno = cal.component(.day, from: data)
        let inizio = MotoreChilometri.inizioMese(data, cal)
        guard let mese = cal.date(byAdding: .month, value: ricorrenza.mesi, to: inizio),
              let giorni = cal.range(of: .day, in: .month, for: mese) else { return data }
        let ora = cal.dateComponents([.hour, .minute], from: data)
        var c = cal.dateComponents([.year, .month], from: mese)
        c.day = min(giorno, giorni.count)
        c.hour = ora.hour
        c.minute = ora.minute
        return cal.date(from: c) ?? data
    }

    /// Segna fatta la scadenza `id`: resta nell'archivio con la data, e se è ricorrente nasce la prossima.
    static func segnaFatta(_ id: String, in scadenze: [ScadenzaStudio], il: Date,
                           calendario cal: Calendar = .current) -> [ScadenzaStudio] {
        guard let i = scadenze.firstIndex(where: { $0.id == id }), scadenze[i].fattaIl == nil else { return scadenze }
        var nuove = scadenze
        nuove[i].fattaIl = il
        if let r = nuove[i].ricorrenza {
            let s = nuove[i]
            nuove.append(ScadenzaStudio(titolo: s.titolo, data: prossimaData(s.data, ricorrenza: r, calendario: cal),
                                        ricorrenza: r, tipo: s.tipo, importo: nil, nota: s.nota))
        }
        return nuove
    }

    // MARK: Ore di aggiornamento

    /// Le ore dei corsi di un anno.
    static func ore(_ corsi: [CorsoAggiornamento], anno: Int, calendario cal: Calendar = .current) -> Double {
        corsi.filter { cal.component(.year, from: $0.data) == anno }.map(\.ore).reduce(0, +)
    }

    /// I corsi di un anno, i più recenti prima.
    static func corsi(_ corsi: [CorsoAggiornamento], anno: Int, calendario cal: Calendar = .current) -> [CorsoAggiornamento] {
        corsi.filter { cal.component(.year, from: $0.data) == anno }.sorted { $0.data > $1.data }
    }

    /// La percentuale delle ore fatte sull'obiettivo scritto dall'utente (nil senza obiettivo), al più 100.
    static func percentualeOre(fatte: Double, obiettivo: Double?) -> Double? {
        guard let obiettivo, obiettivo > 0 else { return nil }
        return min(100, fatte / obiettivo * 100)
    }
}

// MARK: - Lo scontrino

/// Legge un testo di scontrino (da Vision o da un PDF, `LetturaDocumenti`) e propone i campi della spesa: data, totale,
/// esercente, partita IVA dell'esercente e IVA, se stampati. Sempre da confermare: ciò che non trova resta vuoto e la
/// spesa è «da controllare». Regole di forma, non fiscali.
enum LettoreScontrino {
    struct Campi: Equatable {
        var data: Date?
        var totale: Double?
        var esercente: String?
        var partitaIVA: String?
        var iva: Double?
        /// Una categoria proposta dalle parole dello scontrino (la sceglie l'utente).
        var categoria: CategoriaSpesa?

        /// Importo o data non trovati.
        var incerto: Bool { totale == nil || data == nil }
    }

    static func leggi(_ testo: String, calendario cal: Calendar = .current) -> Campi {
        let righe = testo.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var c = Campi()
        c.totale = totale(righe)
        c.data = data(righe, cal)
        c.esercente = esercente(righe)
        c.partitaIVA = partitaIVA(righe)
        c.iva = iva(righe)
        c.categoria = categoria(testo)
        return c
    }

    /// Gli importi di una riga: «36,00», «1.234,50», «12.50».
    static func importi(_ riga: String) -> [Double] {
        let schema = #"(?<![\d,.])(\d{1,3}(?:\.\d{3})+,\d{2}|\d+,\d{2}|\d+\.\d{2})(?![\d])"#
        guard let re = try? NSRegularExpression(pattern: schema) else { return [] }
        let ns = riga as NSString
        return re.matches(in: riga, range: NSRange(location: 0, length: ns.length)).compactMap { m in
            var t = ns.substring(with: m.range(at: 1))
            if t.contains(",") {
                t = t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            }
            return Double(t)
        }
    }

    private static func maiuscolo(_ s: String) -> String { s.uppercased() }

    /// Il totale: la prima riga «TOTALE …» (non «SUBTOTALE»), o «IMPORTO PAGATO», con l'importo sulla riga o sulla dopo.
    private static func totale(_ righe: [String]) -> Double? {
        let chiavi = ["TOTALE", "TOTAL", "IMPORTO PAGATO", "DA PAGARE"]
        for (i, r) in righe.enumerated() {
            let m = maiuscolo(r)
            guard chiavi.contains(where: { m.contains($0) }), !m.contains("SUBTOTALE"), !m.contains("SUB TOTALE"),
                  !m.contains("IVA") else { continue }
            if let v = importi(r).last { return v }
            if i + 1 < righe.count, let v = importi(righe[i + 1]).first { return v }
        }
        return nil
    }

    /// La data: gg/mm/aa, gg/mm/aaaa, gg-mm-aaaa o gg.mm.aaaa (la prima valida).
    private static func data(_ righe: [String], _ cal: Calendar) -> Date? {
        let schema = #"(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?!\d)"#
        guard let re = try? NSRegularExpression(pattern: schema) else { return nil }
        for r in righe {
            let ns = r as NSString
            for m in re.matches(in: r, range: NSRange(location: 0, length: ns.length)) {
                guard let g = Int(ns.substring(with: m.range(at: 1))), let me = Int(ns.substring(with: m.range(at: 2))),
                      var a = Int(ns.substring(with: m.range(at: 3))) else { continue }
                if a < 100 { a += 2000 }
                guard (1...12).contains(me), (1...31).contains(g), (2000...2100).contains(a) else { continue }
                var c = DateComponents()
                (c.year, c.month, c.day, c.hour) = (a, me, g, 12)
                if let d = cal.date(from: c), cal.component(.day, from: d) == g { return d }
            }
        }
        return nil
    }

    /// L'esercente: la prima riga con almeno tre lettere che non sia un'intestazione del documento, una data o un importo.
    private static func esercente(_ righe: [String]) -> String? {
        let scarta = ["DOCUMENTO COMMERCIALE", "SCONTRINO", "RICEVUTA", "FATTURA", "P.IVA", "P. IVA", "PARTITA IVA",
                      "TOTALE", "C.F."]
        for r in righe.prefix(6) {
            let m = maiuscolo(r)
            guard !scarta.contains(where: m.contains), !m.hasPrefix("TEL"), importi(r).isEmpty else { continue }
            if r.filter(\.isLetter).count >= 3 { return r }
        }
        return nil
    }

    /// La partita IVA dell'esercente, se stampata: 11 cifre dopo «P.IVA» o «PARTITA IVA».
    private static func partitaIVA(_ righe: [String]) -> String? {
        let schema = #"(?:P\.?\s?IVA|PARTITA\s+IVA)[^\d]{0,6}(\d{11})(?!\d)"#
        guard let re = try? NSRegularExpression(pattern: schema, options: [.caseInsensitive]) else { return nil }
        for r in righe {
            let ns = r as NSString
            if let m = re.firstMatch(in: r, range: NSRange(location: 0, length: ns.length)) {
                return ns.substring(with: m.range(at: 1))
            }
        }
        return nil
    }

    /// L'IVA stampata («DI CUI IVA 3,27», «IVA 10% 3,27»): l'ultimo importo della riga, non la partita IVA.
    private static func iva(_ righe: [String]) -> Double? {
        for r in righe {
            let m = maiuscolo(r)
            guard m.contains("IVA"), !m.contains("P.IVA"), !m.contains("P. IVA"), !m.contains("PARTITA") else { continue }
            if let v = importi(r).last { return v }
        }
        return nil
    }

    /// Una categoria proposta dalle parole dello scontrino; nil se non si capisce (la sceglie l'utente).
    static func categoria(_ testo: String) -> CategoriaSpesa? {
        let m = testo.uppercased()
        let regole: [(CategoriaSpesa, [String])] = [
            (.carburante, ["CARBURANT", "BENZINA", "GASOLIO", "DIESEL", "SELF SERVICE", "EROGATORE"]),
            (.pedaggi, ["AUTOSTRAD", "PEDAGGIO", "CASELLO"]),
            (.parcheggio, ["PARCHEGG", "PARKING", "SOSTA"]),
            (.pasti, ["RISTORANTE", "TRATTORIA", "PIZZERIA", "OSTERIA", "BAR ", "CAFFE", "PRANZO", "COPERTO"]),
            (.cancelleria, ["CARTOLERIA", "CANCELLERIA", "TONER"]),
            (.viaggio, ["TRENITALIA", "BIGLIETTO", "HOTEL", "ALBERGO"]),
        ]
        return regole.first { $0.1.contains(where: m.contains) }?.0
    }
}
