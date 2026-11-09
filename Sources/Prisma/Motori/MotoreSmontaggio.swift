import Foundation

// Lo smontaggio (Design/template-luce-specifica.md §8.2, «Luce» giro 2): le voci di costo trovate nelle righe di un
// estratto conto, di un rendiconto o di un KID, con la cifra in euro dove Prisma può darla e la fonte di ogni cifra.
// Regole (§8.2.5.2 punto 2), mai percentuali o importi inventati:
// - gestione: l'importo addebitato se il documento lo scrive, altrimenti percentuale × valore, segnato «stima»;
// - performance: solo l'importo scritto (la percentuale «oltre l'indice» non basta senza indice e rendimento dell'anno);
// - diritti fissi: importo × volte l'anno (trimestre 4, semestre 2, mese 12);
// - ingresso: percentuale × versato, «già persi»; senza versato resta senza cifra;
// - penale d'uscita: percentuale × valore «se esce ora», con la data fino a cui vale;
// - bollo: l'importo scritto, altrimenti senza cifra.
// Una riga senza numeri non diventa mai un costo. Le note sono frasi di Prisma con le sue cifre (TestiSmontaggio),
// mai di Qwen. Il confronto «con la tua proposta» lo fa `MotoreSostituzione` (penale, ingresso, tasse) su una posizione
// provvisoria in memoria, mai salvata.

enum TipoCosto: String, Codable, CaseIterable, Identifiable {
    case gestione, performance, dirittiFissi, ingresso, uscita, bollo, altro
    var id: String { rawValue }

    var nome: String {
        switch self {
        case .gestione: return "Commissione di gestione"
        case .performance: return "Commissione di performance"
        case .dirittiFissi: return "Diritti fissi"
        case .ingresso: return "Costi di ingresso"
        case .uscita: return "Penale di rimborso"
        case .bollo: return "Imposta di bollo"
        case .altro: return "Altro costo"
        }
    }

    /// Le voci che si pagano ogni anno (entrano nel costo annuo).
    var annuo: Bool { [.gestione, .performance, .dirittiFissi, .bollo, .altro].contains(self) }
}

/// Da dove viene la cifra in euro di una voce.
enum FonteCosto: String, Codable {
    /// L'importo in euro è scritto nel documento.
    case scritta
    /// Prisma lo calcola dalla percentuale e dal valore o dal versato (stima).
    case calcolata
    /// Non si può calcolare: manca l'importo addebitato, il valore o il versato.
    case mancante
}

struct VoceCostoTrovata: Codable, Hashable, Identifiable {
    var tipo: TipoCosto
    /// L'etichetta come è scritta nel documento.
    var etichetta: String
    /// Il valore come è scritto («2,10% l'anno»).
    var valoreScritto: String
    var euroAnno: Double?
    var euroUnaVolta: Double?
    var finoAl: Int?
    var fonte: FonteCosto
    var riga: Int
    var riquadro: RiquadroPagina?
    /// Il conto fatto da Prisma, per il fumetto («2,10% × 90.000 € = 1.890 €»).
    var conto: String?
    /// Perché la cifra manca («serve l'importo addebitato»).
    var motivoMancante: String?
    var confermata = true

    var id: Int { riga }
    var euro: Double? { euroAnno ?? euroUnaVolta }
}

struct SmontaggioCosti: Equatable {
    var voci: [VoceCostoTrovata]
    var valore: Double?
    var versato: Double?
    /// Somma delle voci annue con cifra.
    var costoAnnuo: Double? {
        let annue = voci.filter { $0.tipo.annuo }.compactMap(\.euroAnno)
        return annue.isEmpty ? nil : annue.reduce(0, +)
    }
    /// Costo annuo sul valore (frazione).
    var quotaAnnua: Double? {
        guard let c = costoAnnuo, let v = valore, v > 0 else { return nil }
        return c / v
    }
    var giaPagati: Double? { voci.first { $0.tipo == .ingresso }?.euroUnaVolta }
    var uscitaOggi: Double? { voci.first { $0.tipo == .uscita }?.euroUnaVolta }
    var mancanti: [TipoCosto] { voci.filter { $0.fonte == .mancante }.map(\.tipo) }
    var vuoto: Bool { voci.isEmpty }
    /// La voce annua più pesante, con la sua quota del costo annuo (frazione).
    var piuPesante: (voce: VoceCostoTrovata, quota: Double)? {
        guard let totale = costoAnnuo, totale > 0,
              let v = voci.filter({ $0.tipo.annuo && $0.euroAnno != nil }).max(by: { ($0.euroAnno ?? 0) < ($1.euroAnno ?? 0) }) else { return nil }
        return (v, (v.euroAnno ?? 0) / totale)
    }
}

enum MotoreSmontaggio {
    // MARK: Lettura delle righe

    /// Le voci di costo nelle righe lette. `valore` e `versato` vengono dal documento (se scritti) o dalla posizione.
    static func smonta(_ righe: [RigaLetta], valore valoreDato: Double? = nil, versato versatoDato: Double? = nil,
                       penaleCondizioni: Double? = nil) -> SmontaggioCosti {
        let valore = valoreDato ?? valoreLetto(righe)
        let versato = versatoDato ?? versatoLetto(righe)
        var voci: [VoceCostoTrovata] = []
        var visti: Set<TipoCosto> = []
        for (i, r) in righe.enumerated() {
            let testo = r.testo
            guard let tipo = tipo(testo), !visti.contains(tipo) || tipo == .altro else { continue }
            let percentuali = numeri(testo, dopo: "%")
            let euro = importi(testo)
            // Una riga senza numeri non è un costo
            guard !percentuali.isEmpty || !euro.isEmpty else { continue }
            var v = VoceCostoTrovata(tipo: tipo, etichetta: etichetta(testo), valoreScritto: valoreScritto(testo),
                                     euroAnno: nil, euroUnaVolta: nil, finoAl: anno(testo), fonte: .mancante, riga: i,
                                     riquadro: r.riquadro)
            switch tipo {
            case .gestione, .altro:
                if let e = euro.last {
                    v.euroAnno = e; v.fonte = .scritta
                } else if let p = percentuali.first, let valore {
                    v.euroAnno = arrotonda(p / 100 * valore); v.fonte = .calcolata
                    v.conto = "\(TestiSmontaggio.percento(p)) × \(Formati.euro(valore)) = \(Formati.euro(v.euroAnno ?? 0))"
                } else {
                    v.motivoMancante = "cifra non calcolabile senza il valore"
                }
            case .performance:
                if let e = euro.last {
                    v.euroAnno = e; v.fonte = .scritta
                } else {
                    v.motivoMancante = "cifra non calcolabile: serve l'importo addebitato"
                }
            case .dirittiFissi:
                if let e = euro.first {
                    let volte = voltePerAnno(testo)
                    v.euroAnno = arrotonda(e * Double(volte))
                    v.fonte = volte == 1 ? .scritta : .calcolata
                    if volte > 1 { v.conto = "\(Formati.euro(e)) × \(volte) = \(Formati.euro(v.euroAnno ?? 0)) l'anno" }
                } else {
                    v.motivoMancante = "cifra non calcolabile: serve l'importo"
                }
            case .ingresso:
                if let e = euro.last {
                    v.euroUnaVolta = e; v.fonte = .scritta
                } else if let p = percentuali.first, let versato {
                    v.euroUnaVolta = arrotonda(p / 100 * versato); v.fonte = .calcolata
                    v.conto = "\(TestiSmontaggio.percento(p)) × \(Formati.euro(versato)) versati = \(Formati.euro(v.euroUnaVolta ?? 0))"
                } else {
                    v.motivoMancante = "\(percentuali.first.map(TestiSmontaggio.percento) ?? "percentuale") del versato · versato non indicato"
                }
            case .uscita:
                let p = penaleCondizioni ?? percentuali.first
                if let e = euro.last {
                    v.euroUnaVolta = e; v.fonte = .scritta
                } else if let p, let valore {
                    v.euroUnaVolta = arrotonda(p / 100 * valore); v.fonte = .calcolata
                    v.conto = "\(TestiSmontaggio.percento(p)) × \(Formati.euro(valore)) = \(Formati.euro(v.euroUnaVolta ?? 0))"
                        + (penaleCondizioni != nil ? " (dalle condizioni della posizione)" : "")
                } else {
                    v.motivoMancante = "cifra non calcolabile senza il valore"
                }
            case .bollo:
                if let e = euro.last { v.euroAnno = e; v.fonte = .scritta } else { v.motivoMancante = "serve l'importo" }
            }
            visti.insert(tipo)
            voci.append(v)
        }
        return SmontaggioCosti(voci: voci, valore: valore, versato: versato)
    }

    /// Il tipo di costo di una riga, dalle parole (nil se la riga non parla di costi).
    static func tipo(_ testo: String) -> TipoCosto? {
        let t = testo.lowercased()
        if t.contains("performance") || t.contains("incentiv") || t.contains("overperformance") { return .performance }
        if t.contains("diritti fissi") || t.contains("diritto fisso") || t.contains("spese fisse") { return .dirittiFissi }
        if t.contains("ingresso") || t.contains("sottoscrizione") || t.contains("caricament") { return .ingresso }
        if t.contains("penale") || t.contains("rimborso") || t.contains("uscita") || t.contains("riscatto") { return .uscita }
        if t.contains("bollo") { return .bollo }
        if t.contains("gestione") || t.contains("costi correnti") { return .gestione }
        if t.contains("commission") || t.contains("spese") || t.contains("oneri") { return .altro }
        return nil
    }

    /// Il valore della posizione scritto nel documento («Valore al 31/12 90.000 €», «controvalore»).
    static func valoreLetto(_ righe: [RigaLetta]) -> Double? {
        for (i, r) in righe.enumerated() {
            let t = r.testo.lowercased()
            guard t.contains("valore") || t.contains("controvalore") || t.contains("patrimonio") else { continue }
            if let e = importi(r.testo).last { return e }
            if i + 1 < righe.count, tipo(righe[i + 1].testo) == nil, let e = importi(righe[i + 1].testo).first { return e }
        }
        return nil
    }

    /// Il versato scritto nel documento («Totale versato 78.000 €»).
    static func versatoLetto(_ righe: [RigaLetta]) -> Double? {
        for r in righe where r.testo.lowercased().contains("versat") {
            if let e = importi(r.testo).last { return e }
        }
        return nil
    }

    // MARK: Numeri all'italiana

    /// «2,10» → 2.1, «90.000» → 90000, «1.890,50» → 1890.5.
    static func numero(_ s: String) -> Double? {
        var t = s.trimmingCharacters(in: .whitespaces)
        if t.contains(",") {
            t = t.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else if t.range(of: #"^\d{1,3}(\.\d{3})+$"#, options: .regularExpression) != nil {
            t = t.replacingOccurrences(of: ".", with: "")
        }
        return Double(t)
    }

    /// Le percentuali di una riga («2,10%», «3 %»).
    static func numeri(_ testo: String, dopo segno: String) -> [Double] {
        corrispondenze(#"(\d{1,3}(?:[.,]\d{1,3})?)\s?%"#, in: testo).compactMap(numero)
    }

    /// Gli importi in euro di una riga («1.890 €», «€ 25», «25 euro»).
    static func importi(_ testo: String) -> [Double] {
        let dopo = corrispondenze(#"(\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?|\d+(?:,\d{1,2})?)\s?(?:€|euro\b|eur\b)"#, in: testo)
        let prima = corrispondenze(#"(?:€|eur)\s?(\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?|\d+(?:,\d{1,2})?)"#, in: testo)
        return (dopo + prima).compactMap(numero)
    }

    /// L'anno fino a cui vale («fino al 2027»).
    static func anno(_ testo: String) -> Int? {
        corrispondenze(#"fino al(?:l')?\s+(?:\d{1,2}/\d{1,2}/)?((?:19|20)\d{2})"#, in: testo.lowercased()).first.flatMap { Int($0) }
    }

    static func voltePerAnno(_ testo: String) -> Int {
        let t = testo.lowercased()
        if t.contains("trimestr") { return 4 }
        if t.contains("semestr") { return 2 }
        if t.contains("mese") || t.contains("mensil") { return 12 }
        return 1
    }

    private static func corrispondenze(_ schema: String, in testo: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: schema, options: [.caseInsensitive]) else { return [] }
        let r = NSRange(testo.startIndex..., in: testo)
        return re.matches(in: testo, range: r).compactMap { m in
            Range(m.range(at: 1), in: testo).map { String(testo[$0]) }
        }
    }

    /// L'etichetta: il testo prima del primo numero.
    static func etichetta(_ testo: String) -> String {
        guard let i = testo.firstIndex(where: \.isNumber) else { return testo.trimmingCharacters(in: .whitespaces) }
        let e = testo[..<i].trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ":·-–€")))
        return e.isEmpty ? testo : e
    }

    /// Il valore: il testo dal primo numero in poi.
    static func valoreScritto(_ testo: String) -> String {
        guard let i = testo.firstIndex(where: \.isNumber) else { return "" }
        let inizio = testo[..<i].last == "€" ? testo.index(before: i) : i
        return testo[inizio...].trimmingCharacters(in: .whitespaces)
    }

    static func arrotonda(_ v: Double) -> Double { (v * 100).rounded() / 100 }

    // MARK: Il confronto con una proposta

    /// La posizione provvisoria, in memoria e mai salvata, costruita dai dati letti (o la posizione vera aggiornata in
    /// memoria): valore, versato, costo annuo in % = costo annuo / valore.
    static func posizioneProvvisoria(_ s: SmontaggioCosti, da base: Posizione?, clienteId: String, nome: String) -> Posizione? {
        guard let valore = s.valore ?? base?.valore, valore > 0 else { return nil }
        var p = base ?? Posizione(clienteId: clienteId, canale: .indipendente, stato: .inEssere, area: .investimento, nome: nome)
        p.controvalore = valore
        if let v = s.versato { p.totaleVersato = v }
        if let c = s.costoAnnuo { p.costoAnnuo = c / valore * 100 }
        // La penale letta passa a MotoreSostituzione come `penaleIndicata` (vale solo se le condizioni non ne danno una)
        p.stato = .inEssere
        return p
    }

    /// «Con la tua proposta» e «In dieci anni»: MotoreSostituzione su orizzonte di 10 anni (le ipotesi di Prisma), con
    /// penale, costi d'ingresso e tasse.
    static func confronto(_ s: SmontaggioCosti, attuale: Posizione, proposta: Posizione, prodotti: [Prodotto]) -> EsitoSostituzione {
        MotoreSostituzione.calcola(attuale: attuale, alternativa: proposta, prodotti: prodotti,
                                   anni: IpotesiCalcolo.orizzontePredefinito, penaleIndicata: s.uscitaOggi)
    }
}

// MARK: - Testi

enum TestiSmontaggio {
    /// La conferma di «Aggiungi al dossier…».
    static func confermaDossier(voci n: Int) -> String {
        "Entra nei Documenti come estratto conto, con il testo letto e \(n == 1 ? "la voce di costo trovata" : "le \(n) voci di costo trovate"). "
            + "La foto non si conserva."
    }

    static func percento(_ p: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.minimumFractionDigits = p.rounded() == p ? 0 : 2
        f.maximumFractionDigits = 2
        return (f.string(from: NSNumber(value: p)) ?? "\(p)") + "%"
    }

    /// La cifra di Prisma accanto al valore scritto: «1.890 € nel 2025», «100 € l'anno», «1.950 € già persi»,
    /// «fino a 2.700 € se esce ora».
    static func cifra(_ v: VoceCostoTrovata, anno: Int?) -> String {
        guard let e = v.euro else { return v.motivoMancante ?? "cifra non calcolabile" }
        switch v.tipo {
        case .ingresso: return "\(Formati.euro(e)) già persi"
        case .uscita: return "fino a \(Formati.euro(e)) se esce ora"
        case .dirittiFissi: return "\(Formati.euro(e)) l'anno"
        default: return anno.map { "\(Formati.euro(e)) nel \($0)" } ?? "\(Formati.euro(e)) l'anno"
        }
    }

    /// La nota rossa di una voce (nil = nessuna nota), con le cifre di Prisma.
    static func nota(_ v: VoceCostoTrovata, in s: SmontaggioCosti, nomeCliente: String) -> String? {
        if v.fonte == .mancante, let m = v.motivoMancante { return maiuscola(m) + "." }
        switch v.tipo {
        case .ingresso:
            guard v.euro != nil else { return nil }
            return "Soldi che non hanno mai lavorato per \(nomeCliente)."
        case .uscita:
            guard let fino = v.finoAl else { return "Da considerare nel momento del cambio." }
            return "Vale fino al \(fino): da considerare nel momento del cambio."
        default:
            if let p = s.piuPesante, p.voce.riga == v.riga, p.quota > 0.5 {
                return "La voce più pesante: da sola fa il \(Int((p.quota * 100).rounded()))% dei costi."
            }
            return nil
        }
    }

    static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    static let vuoto = "Inquadra con l'iPhone o trascina qui un estratto conto, un rendiconto o un KID: Prisma cerchia i costi."
    static let nessunCosto = "Non ho trovato voci di costo in questo documento. Se ci sono, segnale tu: clic sulla riga."
    static let scegliProposta = "Scegli un prodotto da confrontare"
    static let provvisoria = "Posizione non registrata: crea la posizione per salvarla."

    static func didascalia(rendimento: Double, anni: Int) -> String {
        "Con la penale, i costi d'ingresso e le tasse. Stima con rendimento lordo del \(percento(rendimento)) l'anno, su \(anni) anni: le ipotesi di Prisma, che puoi cambiare."
    }

    /// Le righe del fac-simile del template (dati di prova dichiarati), per l'esempio e le prove. Il versato (78.000 €)
    /// il template non lo scrive: la specifica lo ricava dai 1.950 € d'ingresso, e qui è scritto perché si veda.
    static let righeFacSimile: [String] = [
        "BANCA ESEMPIO · FAC-SIMILE",
        "Fondo Esempio Globale",
        "Estratto annuale 2025",
        "Valore al 31/12 90.000 €",
        "Totale versato 78.000 €",
        "Commissione di gestione 2,10% l'anno",
        "Commissione di performance 20% oltre l'indice · 420 € addebitati",
        "Diritti fissi 25 € a trimestre",
        "Costi di ingresso 2,50% (pagati nel 2021)",
        "Penale di rimborso 3% fino al 2027",
    ]
}
