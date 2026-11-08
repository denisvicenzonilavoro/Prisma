import Foundation

// Le impostazioni di Studio (versione 26 dell'archivio, «Orizzonte»): le aliquote provvigionali Alleanza del consulente
// e i suoi obiettivi dell'anno. Prisma non li inventa mai: finché il consulente non li scrive restano vuoti (nil) e
// Studio lo dice («Inserisci le tue aliquote in Impostazioni › Studio», «Imposta gli obiettivi»). Nemmeno i dati di
// prova li riempiono. Tutto è letto con tolleranza: gli archivi e i backup di prima si aprono con le impostazioni vuote.

/// Le aliquote provvigionali Alleanza di un tipo di prodotto (un'area di `AreaPosizione`), in percentuale (3 = 3%).
/// Ognuna è facoltativa: nil = non inserita, e la provvigione che ne dipende non si stima.
///
/// Base di calcolo (la usa `MotoreStudio.eventi`), sulle posizioni Alleanza in essere con la decorrenza:
/// - `nuovaProduzione`: % sul versamento iniziale (premio unico) più i premi della prima annualità
///   (`premioAnnuo`), maturata tutta nel mese della decorrenza;
/// - `ricorrenti`: % su ogni rata di premio dalla seconda annualità in poi (piani di risparmio, investimento e
///   previdenza a premi periodici), nel mese della rata, fino alla scadenza;
/// - `rinnovi`: come `ricorrenti`, ma per le coperture (area `protezione`): % su ogni rata dalla seconda annualità,
///   cioè al rinnovo della copertura.
/// Per le rate dalla seconda annualità vale quindi una sola delle due: `rinnovi` per la protezione, `ricorrenti` per
/// le altre aree (`voceSuccessiva(area:)`).
struct AliquoteProvvigione: Codable, Equatable {
    var nuovaProduzione: Double?
    var ricorrenti: Double?
    var rinnovi: Double?

    init(nuovaProduzione: Double? = nil, ricorrenti: Double? = nil, rinnovi: Double? = nil) {
        self.nuovaProduzione = nuovaProduzione
        self.ricorrenti = ricorrenti
        self.rinnovi = rinnovi
    }

    /// Nessuna aliquota inserita.
    var vuota: Bool { nuovaProduzione == nil && ricorrenti == nil && rinnovi == nil }

    /// L'aliquota delle rate dalla seconda annualità per un'area: `rinnovi` per la protezione, `ricorrenti` per le altre.
    func successiva(area: AreaPosizione) -> Double? {
        AliquoteProvvigione.voceSuccessiva(area: area) == .rinnovo ? rinnovi : ricorrenti
    }

    /// Quale voce vale per le rate dalla seconda annualità di un'area (Impostazioni › Studio mostra solo quella).
    static func voceSuccessiva(area: AreaPosizione) -> MotoreStudio.TipoProvvigione {
        area == .protezione ? .rinnovo : .ricorrente
    }

    private enum CodingKeys: String, CodingKey { case nuovaProduzione, ricorrenti, rinnovi }

    /// Lettura tollerante: un valore illeggibile, negativo o non finito diventa nil (non inserito).
    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        func leggi(_ k: CodingKeys) -> Double? {
            guard let v = (try? c.decodeIfPresent(Double.self, forKey: k)) ?? nil, v.isFinite, v >= 0 else { return nil }
            return v
        }
        nuovaProduzione = leggi(.nuovaProduzione)
        ricorrenti = leggi(.ricorrenti)
        rinnovi = leggi(.rinnovi)
    }
}

/// Gli obiettivi di un anno del consulente. Tutti facoltativi: nil = non impostato (niente anello per quella voce).
struct ObiettiviStudio: Codable, Equatable {
    /// Produzione Alleanza dell'anno in € (definizione di `MotoreStudio`: versamenti iniziali più premi annui delle
    /// posizioni Alleanza con decorrenza nell'anno).
    var produzioneAlleanza: Double?
    /// Clienti nuovi dell'anno.
    var nuoviClienti: Int?
    /// Ricavi della consulenza indipendente dell'anno in € (parcelle).
    var ricaviConsulenza: Double?

    init(produzioneAlleanza: Double? = nil, nuoviClienti: Int? = nil, ricaviConsulenza: Double? = nil) {
        self.produzioneAlleanza = produzioneAlleanza
        self.nuoviClienti = nuoviClienti
        self.ricaviConsulenza = ricaviConsulenza
    }

    /// Nessun obiettivo impostato.
    var vuoto: Bool { produzioneAlleanza == nil && nuoviClienti == nil && ricaviConsulenza == nil }

    private enum CodingKeys: String, CodingKey { case produzioneAlleanza, nuoviClienti, ricaviConsulenza }

    /// Lettura tollerante: un valore illeggibile, negativo o non finito diventa nil.
    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        if let v = (try? c.decodeIfPresent(Double.self, forKey: .produzioneAlleanza)) ?? nil, v.isFinite, v >= 0 { produzioneAlleanza = v }
        if let v = (try? c.decodeIfPresent(Int.self, forKey: .nuoviClienti)) ?? nil, v >= 0 { nuoviClienti = v }
        if let v = (try? c.decodeIfPresent(Double.self, forKey: .ricaviConsulenza)) ?? nil, v.isFinite, v >= 0 { ricaviConsulenza = v }
    }
}

/// Impostazioni › Studio (dalla versione 26 dell'archivio): aliquote provvigionali Alleanza per tipo di prodotto e
/// obiettivi del consulente per anno. Entrano nei calcoli (cambiano la versione dei calcoli) e nel backup.
struct ImpostazioniStudio: Codable, Equatable {
    /// Le aliquote per tipo di prodotto (area della posizione). Un'area assente o con tutte le voci nil = non inserita.
    var aliquote: [AreaPosizione: AliquoteProvvigione] = [:]
    /// Gli obiettivi per anno (chiave: l'anno, per esempio 2026).
    var obiettivi: [Int: ObiettiviStudio] = [:]
    /// I dati fiscali del consulente per le fatture (Impostazioni › Studio › Fatturazione, giro 2): vuoti di base,
    /// nessun regime, aliquota o regola predefinita (DatiFatturazione.swift).
    var fatturazione = DatiFatturazione()
    /// Chilometri, spese e scadenze («Luce» giro 9, versione 27, SpeseStudio.swift): partenza, km per cliente, correzioni
    /// dei giri, ore di aggiornamento richieste, nomi nel pacchetto. Non entrano nei calcoli in cache.
    var spese = ImpostazioniSpese()

    /// I tipi di prodotto che danno provvigioni (gli altri, liquidità, immobili e debiti, non entrano in Studio).
    static let areeProvvigionali: [AreaPosizione] = [.investimento, .risparmio, .previdenza, .protezione]

    init() {}

    /// Le aliquote di un'area, se almeno una è inserita.
    func aliquoteInserite(per area: AreaPosizione) -> AliquoteProvvigione? {
        guard let a = aliquote[area], !a.vuota else { return nil }
        return a
    }

    /// Nessuna aliquota inserita per nessun tipo di prodotto: Studio non stima le provvigioni Alleanza.
    var senzaAliquote: Bool { !ImpostazioniStudio.areeProvvigionali.contains { aliquoteInserite(per: $0) != nil } }

    /// Gli obiettivi di un anno, se almeno uno è impostato.
    func obiettiviImpostati(anno: Int) -> ObiettiviStudio? {
        guard let o = obiettivi[anno], !o.vuoto else { return nil }
        return o
    }

    private enum CodingKeys: String, CodingKey { case aliquote, obiettivi, fatturazione, spese }

    /// Lettura tollerante: le chiavi sconosciute (un'area che non c'è più, un anno non numerico) si scartano, le altre
    /// restano così come sono (anche vuote: l'archivio torna identico dopo un salvataggio).
    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        let grezze = (try? c.decodeIfPresent([String: AliquoteProvvigione].self, forKey: .aliquote)) ?? nil
        for (chiave, valore) in grezze ?? [:] {
            if let area = AreaPosizione(rawValue: chiave) { aliquote[area] = valore }
        }
        let anni = (try? c.decodeIfPresent([String: ObiettiviStudio].self, forKey: .obiettivi)) ?? nil
        for (chiave, valore) in anni ?? [:] {
            if let anno = Int(chiave) { obiettivi[anno] = valore }
        }
        // Giro 2: gli archivi del giro 1 non hanno i dati fiscali
        fatturazione = ((try? c.decodeIfPresent(DatiFatturazione.self, forKey: .fatturazione)) ?? nil) ?? DatiFatturazione()
        // «Luce» giro 9 (versione 27): gli archivi di prima non hanno le impostazioni delle spese
        spese = ((try? c.decodeIfPresent(ImpostazioniSpese.self, forKey: .spese)) ?? nil) ?? ImpostazioniSpese()
    }

    /// Le chiavi si scrivono come testo (l'area e l'anno), così il JSON è un oggetto leggibile.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        var perArea: [String: AliquoteProvvigione] = [:]
        for (area, valore) in aliquote { perArea[area.rawValue] = valore }
        var perAnno: [String: ObiettiviStudio] = [:]
        for (anno, valore) in obiettivi { perAnno[String(anno)] = valore }
        try c.encode(perArea, forKey: .aliquote)
        try c.encode(perAnno, forKey: .obiettivi)
        try c.encode(fatturazione, forKey: .fatturazione)
        try c.encode(spese, forKey: .spese)
    }
}
