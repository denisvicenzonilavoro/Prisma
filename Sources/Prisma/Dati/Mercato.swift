import Foundation

// Mercato, «Prisma conosce il mercato» (Design/template-novita-specifica.md §12, archivio versione 26, giro 7).
// Le serie pubbliche arrivano da BCE (Data Portal, SDMX) ed Eurostat (JSON-stat) SOLO con l'interruttore «Dati di
// mercato» acceso (`ImpostazioniMercato.attivo`, spento di base) e attraverso l'unica funzione che costruisce le
// richieste (`ClienteMercato.richiesta`): escono solo i codici pubblici delle serie, mai dati dei clienti. Le quote dei
// fondi per ISIN e tutto ciò che non viene da BCE ed Eurostat si importano da CSV (Design/mercato-csv.md) o si
// scrivono a mano. Ogni valore ha la sua data e la sua fonte. Tutto si legge con tolleranza: un archivio senza queste
// sezioni si apre con Mercato vuoto, un elemento illeggibile si scarta e gli altri restano.

/// Da dove arriva un dato di mercato.
enum OrigineDatoMercato: String, Codable, CaseIterable, Identifiable {
    case bce, eurostat, csv, aMano

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .bce: return "BCE"
        case .eurostat: return "Eurostat"
        case .csv: return "File CSV"
        case .aMano: return "A mano"
        }
    }

    /// Scaricato da internet (solo con l'interruttore acceso).
    var scaricato: Bool { self == .bce || self == .eurostat }
}

/// L'unità dei valori: tassi e inflazione in percentuale (le variazioni in punti), indici in punti, quote in euro
/// (le variazioni in percentuale).
enum UnitaMercato: String, Codable, CaseIterable {
    case percentuale, punti, euro

    /// La variazione si misura in percentuale del valore (indici e quote) e non in punti (tassi).
    var variazioneInPercentuale: Bool { self != .percentuale }
}

/// Ogni quanto esce un valore.
enum FrequenzaMercato: String, Codable, CaseIterable {
    case giornaliera, mensile, trimestrale, annuale

    /// Un dato più vecchio di così non è più «di oggi» per «Chi è toccato»: i dati mensili escono con un mese di
    /// ritardo e portano la data del primo giorno del mese.
    var giorniFreschezza: Int {
        switch self {
        case .giornaliera: return 10
        case .mensile: return 62
        case .trimestrale: return 125
        case .annuale: return 400
        }
    }

    /// Quanto storico si conserva (memoria e archivio leggeri): 13 mesi per i dati giornalieri, 3 anni per gli altri.
    var mesiConservati: Int { self == .giornaliera ? 13 : 36 }
}

/// Che cosa misura una serie: decide chi ne è toccato (MotoreMercato.toccati).
enum TipoSerieMercato: String, Codable, CaseIterable {
    case indiceAzionario, rendimentoStato, spread, tassoInterbancario, tassoUfficiale, inflazione, altro
}

/// Un valore datato. `fonte` vale per il singolo valore quando è diversa da quella della serie (quote importate da
/// file diversi); nil = quella della serie.
struct PuntoMercato: Codable, Hashable {
    var data: Date
    var valore: Double
    var fonte: String?

    init(data: Date, valore: Double, fonte: String? = nil) {
        self.data = data
        self.valore = valore
        self.fonte = fonte
    }

    private enum CodingKeys: String, CodingKey { case data, valore, fonte }

    /// Senza data o senza un valore finito il punto non si legge (e `ElencoTollerante` lo scarta).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = try c.decode(Date.self, forKey: .data)
        let v = try c.decode(Double.self, forKey: .valore)
        guard v.isFinite else {
            throw DecodingError.dataCorruptedError(forKey: .valore, in: c, debugDescription: "valore non finito")
        }
        valore = v
        fonte = (try? c.decodeIfPresent(String.self, forKey: .fonte)) ?? nil
    }
}

/// Una serie di mercato scaricata (BCE, Eurostat) o importata (CSV, a mano).
struct SerieMercato: Identifiable, Codable, Equatable {
    /// L'id locale («bce-depositi», «euribor-3m»… dalla configurazione, oppure «serie-…» del consulente).
    var id: String
    /// Il codice pubblico della serie («FM.D.U2.EUR.4F.KR.DFR.LEV», «prc_hicp_manr»); vuoto per le serie del consulente.
    var codice: String
    var nome: String
    var origine: OrigineDatoMercato
    /// La fonte da citare: «BCE», «Eurostat» o quella scritta dal consulente per un file («Borsa Italiana», «SGR»…).
    var fonte: String
    /// Il dato è di terzi, ridistribuito dalla fonte (Euribor: EMMI; Euro Stoxx 50: STOXX): va indicato.
    var datoDiTerzi: String?
    var unita: UnitaMercato
    var tipo: TipoSerieMercato
    var frequenza: FrequenzaMercato
    /// I valori, dal più vecchio.
    var punti: [PuntoMercato]
    /// Quando è stata scaricata o importata l'ultima volta.
    var aggiornataIl: Date

    init(id: String, codice: String = "", nome: String, origine: OrigineDatoMercato, fonte: String, datoDiTerzi: String? = nil,
         unita: UnitaMercato, tipo: TipoSerieMercato, frequenza: FrequenzaMercato, punti: [PuntoMercato], aggiornataIl: Date) {
        self.id = id
        self.codice = codice
        self.nome = nome
        self.origine = origine
        self.fonte = fonte
        self.datoDiTerzi = datoDiTerzi
        self.unita = unita
        self.tipo = tipo
        self.frequenza = frequenza
        self.punti = punti
        self.aggiornataIl = aggiornataIl
    }

    private enum CodingKeys: String, CodingKey {
        case id, codice, nome, origine, fonte, datoDiTerzi, unita, tipo, frequenza, punti, aggiornataIl
    }

    /// Lettura tollerante: servono l'id e il nome; un punto illeggibile si scarta, gli altri restano.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        nome = try c.decode(String.self, forKey: .nome)
        codice = (try? c.decodeIfPresent(String.self, forKey: .codice)) ?? ""
        origine = ((try? c.decodeIfPresent(OrigineDatoMercato.self, forKey: .origine)) ?? nil) ?? .aMano
        fonte = ((try? c.decodeIfPresent(String.self, forKey: .fonte)) ?? nil) ?? origine.nome
        datoDiTerzi = (try? c.decodeIfPresent(String.self, forKey: .datoDiTerzi)) ?? nil
        unita = ((try? c.decodeIfPresent(UnitaMercato.self, forKey: .unita)) ?? nil) ?? .percentuale
        tipo = ((try? c.decodeIfPresent(TipoSerieMercato.self, forKey: .tipo)) ?? nil) ?? .altro
        frequenza = ((try? c.decodeIfPresent(FrequenzaMercato.self, forKey: .frequenza)) ?? nil) ?? .mensile
        punti = (((try? c.decodeIfPresent(ElencoTollerante<PuntoMercato>.self, forKey: .punti)) ?? nil)?.elementi ?? [])
            .sorted { $0.data < $1.data }
        aggiornataIl = ((try? c.decodeIfPresent(Date.self, forKey: .aggiornataIl)) ?? nil) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    var ultimo: PuntoMercato? { punti.last }

    /// «Fonte: BCE», «Fonte: BCE (dato di EMMI)», «Fonte: Eurostat», «Fonte: Borsa Italiana (file importato)»,
    /// «Inserito a mano».
    var citazione: String { TestiMercato.citazione(origine: origine, fonte: fonte, datoDiTerzi: datoDiTerzi) }
}

/// Le quote di un fondo, ETF o titolo per ISIN: si importano da CSV o si scrivono a mano (nessuna fonte libera le dà).
struct QuotaISIN: Identifiable, Codable, Equatable {
    /// L'ISIN normalizzato (maiuscolo, senza spazi), con la cifra di controllo giusta.
    var isin: String
    var nome: String
    var valuta: String
    /// Le quote, dal più vecchio; ognuna con la sua fonte.
    var punti: [PuntoMercato]
    /// La fonte dell'ultima importazione («Estratto della piattaforma Alleanza», «SGR»…).
    var fonte: String
    var origine: OrigineDatoMercato
    var importataIl: Date

    var id: String { isin }

    init(isin: String, nome: String = "", valuta: String = "EUR", punti: [PuntoMercato], fonte: String,
         origine: OrigineDatoMercato, importataIl: Date) {
        self.isin = isin
        self.nome = nome
        self.valuta = valuta
        self.punti = punti
        self.fonte = fonte
        self.origine = origine
        self.importataIl = importataIl
    }

    private enum CodingKeys: String, CodingKey { case isin, nome, valuta, punti, fonte, origine, importataIl }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let codice = MotoreMercato.normalizzaISIN(try c.decode(String.self, forKey: .isin))
        guard MotoreMercato.isinValido(codice) else {
            throw DecodingError.dataCorruptedError(forKey: .isin, in: c, debugDescription: "ISIN non valido")
        }
        isin = codice
        nome = (try? c.decodeIfPresent(String.self, forKey: .nome)) ?? ""
        valuta = ((try? c.decodeIfPresent(String.self, forKey: .valuta)) ?? nil) ?? "EUR"
        punti = (((try? c.decodeIfPresent(ElencoTollerante<PuntoMercato>.self, forKey: .punti)) ?? nil)?.elementi ?? [])
            .sorted { $0.data < $1.data }
        origine = ((try? c.decodeIfPresent(OrigineDatoMercato.self, forKey: .origine)) ?? nil) ?? .csv
        fonte = ((try? c.decodeIfPresent(String.self, forKey: .fonte)) ?? nil) ?? origine.nome
        importataIl = ((try? c.decodeIfPresent(Date.self, forKey: .importataIl)) ?? nil) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(isin, forKey: .isin)
        try c.encode(nome, forKey: .nome)
        try c.encode(valuta, forKey: .valuta)
        try c.encode(punti, forKey: .punti)
        try c.encode(fonte, forKey: .fonte)
        try c.encode(origine, forKey: .origine)
        try c.encode(importataIl, forKey: .importataIl)
    }

    var ultimo: PuntoMercato? { punti.last }
}

/// La cedola di un titolo (BTP, obbligazioni) di una posizione: serve all'avviso «cedola in arrivo».
struct CedolaTitolo: Codable, Hashable {
    /// Tasso annuo lordo (%).
    var tassoAnnuo: Double
    /// Quante cedole all'anno (2 per i BTP).
    var volteAllAnno: Int
    /// La prossima data di pagamento indicata dal consulente.
    var prossima: Date

    init(tassoAnnuo: Double, volteAllAnno: Int, prossima: Date) {
        self.tassoAnnuo = tassoAnnuo
        self.volteAllAnno = volteAllAnno
        self.prossima = prossima
    }

    /// La prima data di pagamento da oggi in poi: se quella scritta è passata si va avanti di 12 / volte mesi.
    func prossimaData(da oggi: Date, cal: Calendar = .current) -> Date? {
        guard volteAllAnno > 0, volteAllAnno <= 12 else { return nil }
        let passo = 12 / volteAllAnno
        let inizio = cal.startOfDay(for: oggi)
        var d = prossima
        var giri = 0
        while cal.startOfDay(for: d) < inizio, giri < 600 {
            guard let dopo = cal.date(byAdding: .month, value: passo, to: d) else { return nil }
            d = dopo
            giri += 1
        }
        return cal.startOfDay(for: d) >= inizio ? d : nil
    }
}

/// Il tipo di un evento di mercato e dell'avviso che ne nasce.
enum TipoEventoMercato: String, Codable, CaseIterable {
    /// Una serie (indice, tasso, inflazione) si è mossa oltre la soglia dell'utente sull'ultimo dato.
    case variazioneSerie
    /// La quota di un ISIN è scesa dal massimo degli ultimi 12 mesi oltre la soglia.
    case caloDalMassimo
    /// In un mese la quota di un ISIN si è allontanata dalla serie di riferimento scelta oltre la soglia.
    case distanzaDalRiferimento
    /// La cedola di un titolo arriva entro i giorni scelti.
    case cedolaInArrivo

    var nome: String {
        switch self {
        case .variazioneSerie: return "Variazione del mercato"
        case .caloDalMassimo: return "Calo dal massimo"
        case .distanzaDalRiferimento: return "Distanza dal riferimento"
        case .cedolaInArrivo: return "Cedola in arrivo"
        }
    }

    /// La condizione dura nel tempo (calo, distanza): l'avviso non si ripete finché non rientra.
    var condizione: Bool { self == .caloDalMassimo || self == .distanzaDalRiferimento }
}

/// A che punto è un avviso: nuovo finché il consulente non lo apre.
enum StatoAvvisoMercato: String, Codable, CaseIterable {
    case nuovo, visto
}

/// Un avviso generato da MotoreMercato con le soglie dell'utente, per un cliente toccato.
struct AvvisoMercato: Identifiable, Codable, Equatable {
    /// Stabile tra un calcolo e l'altro (MotoreMercato.idAvviso).
    var id: String
    var tipo: TipoEventoMercato
    var clienteId: String
    /// Le posizioni del cliente toccate (vuoto = il portafoglio o gli obiettivi).
    var posizioni: [String]
    var isin: String?
    var serieId: String?
    /// Il canale quando le posizioni toccate sono di un canale solo (Alleanza o indipendente).
    var canale: Canale?
    var titolo: String
    var dettaglio: String
    /// La misura (variazione in % o in punti, calo in %, distanza in punti, giorni alla cedola) e la soglia.
    var valore: Double
    var soglia: Double
    /// La data del dato (o della cedola) da cui nasce.
    var dataDato: Date
    /// La citazione della fonte («Fonte: BCE»).
    var fonte: String
    var creatoIl: Date
    var stato: StatoAvvisoMercato
    var vistoIl: Date?

    init(id: String, tipo: TipoEventoMercato, clienteId: String, posizioni: [String] = [], isin: String? = nil,
         serieId: String? = nil, canale: Canale? = nil, titolo: String, dettaglio: String, valore: Double, soglia: Double,
         dataDato: Date, fonte: String, creatoIl: Date, stato: StatoAvvisoMercato = .nuovo, vistoIl: Date? = nil) {
        self.id = id
        self.tipo = tipo
        self.clienteId = clienteId
        self.posizioni = posizioni
        self.isin = isin
        self.serieId = serieId
        self.canale = canale
        self.titolo = titolo
        self.dettaglio = dettaglio
        self.valore = valore
        self.soglia = soglia
        self.dataDato = dataDato
        self.fonte = fonte
        self.creatoIl = creatoIl
        self.stato = stato
        self.vistoIl = vistoIl
    }

    private enum CodingKeys: String, CodingKey {
        case id, tipo, clienteId, posizioni, isin, serieId, canale, titolo, dettaglio, valore, soglia, dataDato, fonte, creatoIl, stato, vistoIl
    }

    /// Servono id, tipo, cliente, titolo e data del dato; uno stato sconosciuto torna «nuovo».
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tipo = try c.decode(TipoEventoMercato.self, forKey: .tipo)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        titolo = try c.decode(String.self, forKey: .titolo)
        dataDato = try c.decode(Date.self, forKey: .dataDato)
        posizioni = ((try? c.decodeIfPresent([String].self, forKey: .posizioni)) ?? nil) ?? []
        isin = (try? c.decodeIfPresent(String.self, forKey: .isin)) ?? nil
        serieId = (try? c.decodeIfPresent(String.self, forKey: .serieId)) ?? nil
        canale = (try? c.decodeIfPresent(Canale.self, forKey: .canale)) ?? nil
        dettaglio = ((try? c.decodeIfPresent(String.self, forKey: .dettaglio)) ?? nil) ?? ""
        valore = ((try? c.decodeIfPresent(Double.self, forKey: .valore)) ?? nil) ?? 0
        soglia = ((try? c.decodeIfPresent(Double.self, forKey: .soglia)) ?? nil) ?? 0
        fonte = ((try? c.decodeIfPresent(String.self, forKey: .fonte)) ?? nil) ?? ""
        creatoIl = ((try? c.decodeIfPresent(Date.self, forKey: .creatoIl)) ?? nil) ?? dataDato
        stato = ((try? c.decodeIfPresent(StatoAvvisoMercato.self, forKey: .stato)) ?? nil) ?? .nuovo
        vistoIl = (try? c.decodeIfPresent(Date.self, forKey: .vistoIl)) ?? nil
    }
}

/// Tutto ciò che Mercato conserva nell'archivio (`DatiPrisma.mercato`, versione 26, giro 7). Entra nel backup.
struct ArchivioMercato: Codable, Equatable {
    var serie: [SerieMercato] = []
    var quote: [QuotaISIN] = []
    var avvisi: [AvvisoMercato] = []
    /// L'ultimo scaricamento riuscito da BCE o Eurostat (nil = mai).
    var ultimoAggiornamento: Date?
    /// L'errore dell'ultimo scaricamento non riuscito (rete assente, serie non trovata…), come i backup.
    var ultimoErrore: String?

    init() {}

    private enum CodingKeys: String, CodingKey { case serie, quote, avvisi, ultimoAggiornamento, ultimoErrore }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        serie = ((try? c.decodeIfPresent(ElencoTollerante<SerieMercato>.self, forKey: .serie)) ?? nil)?.elementi ?? []
        quote = ((try? c.decodeIfPresent(ElencoTollerante<QuotaISIN>.self, forKey: .quote)) ?? nil)?.elementi ?? []
        avvisi = ((try? c.decodeIfPresent(ElencoTollerante<AvvisoMercato>.self, forKey: .avvisi)) ?? nil)?.elementi ?? []
        ultimoAggiornamento = (try? c.decodeIfPresent(Date.self, forKey: .ultimoAggiornamento)) ?? nil
        ultimoErrore = (try? c.decodeIfPresent(String.self, forKey: .ultimoErrore)) ?? nil
    }

    var vuoto: Bool { serie.isEmpty && quote.isEmpty && avvisi.isEmpty }

    func serie(_ id: String) -> SerieMercato? { serie.first { $0.id == id } }

    func quota(_ isin: String) -> QuotaISIN? {
        let codice = MotoreMercato.normalizzaISIN(isin)
        return quote.first { $0.isin == codice }
    }
}

/// Le scelte di Mercato (Impostazioni › Mercato). Tutto spento o vuoto di base: le soglie le decide l'utente e
/// senza soglia non nasce nessun avviso.
struct ImpostazioniMercato: Codable, Equatable {
    /// «Dati di mercato»: Prisma scarica le serie pubbliche di BCE ed Eurostat. Spento di base: senza, Prisma non esce
    /// mai su internet.
    var attivo = false
    /// Le serie da scaricare (id della configurazione), nell'ordine scelto. nil = tutte quelle della configurazione.
    var serieAttive: [String]?
    /// Avviso quando la quota di un ISIN scende dal massimo degli ultimi 12 mesi di almeno tanti punti percentuali
    /// (5 = −5%). nil = nessun avviso.
    var caloDalMassimo: Double?
    /// Avviso quando in un mese la quota di un ISIN si allontana dalla sua serie di riferimento (`riferimenti`) di
    /// almeno tanti punti percentuali. nil = nessun avviso.
    var distanzaDalRiferimento: Double?
    /// Avviso quando la cedola di un titolo arriva entro tanti giorni. nil = nessun avviso.
    var giorniCedola: Int?
    /// «Chi è toccato»: variazione minima di un indice (%, sull'ultimo dato) e di un tasso (punti). nil = nessun evento.
    var variazioneIndici: Double?
    var variazioneTassi: Double?
    /// La serie di riferimento di ogni ISIN (ISIN → id della serie), per la distanza dal riferimento.
    var riferimenti: [String: String] = [:]

    init() {}

    private enum CodingKeys: String, CodingKey {
        case attivo, serieAttive, caloDalMassimo, distanzaDalRiferimento, giorniCedola, variazioneIndici, variazioneTassi, riferimenti
    }

    /// Lettura tollerante: una soglia non positiva o illeggibile resta spenta.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        attivo = ((try? c.decodeIfPresent(Bool.self, forKey: .attivo)) ?? nil) ?? false
        serieAttive = (try? c.decodeIfPresent([String].self, forKey: .serieAttive)) ?? nil
        caloDalMassimo = Self.positiva((try? c.decodeIfPresent(Double.self, forKey: .caloDalMassimo)) ?? nil)
        distanzaDalRiferimento = Self.positiva((try? c.decodeIfPresent(Double.self, forKey: .distanzaDalRiferimento)) ?? nil)
        let giorni = (try? c.decodeIfPresent(Int.self, forKey: .giorniCedola)) ?? nil
        giorniCedola = giorni.flatMap { $0 > 0 ? $0 : nil }
        variazioneIndici = Self.positiva((try? c.decodeIfPresent(Double.self, forKey: .variazioneIndici)) ?? nil)
        variazioneTassi = Self.positiva((try? c.decodeIfPresent(Double.self, forKey: .variazioneTassi)) ?? nil)
        riferimenti = ((try? c.decodeIfPresent([String: String].self, forKey: .riferimenti)) ?? nil) ?? [:]
    }

    private static func positiva(_ v: Double?) -> Double? {
        guard let v, v.isFinite, v > 0 else { return nil }
        return v
    }

    /// Nessuna soglia scelta: nessun avviso e nessun evento.
    var senzaSoglie: Bool {
        caloDalMassimo == nil && distanzaDalRiferimento == nil && giorniCedola == nil && variazioneIndici == nil && variazioneTassi == nil
    }
}
