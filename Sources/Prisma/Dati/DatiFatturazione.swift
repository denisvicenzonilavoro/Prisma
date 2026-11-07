import Foundation

// MARK: - Studio › Parcelle e fatture: i dati fiscali del consulente (versione 26 dell'archivio, «Orizzonte», giro 2)
// Specifica Design/template-novita-specifica.md §3.5.4 e §3.6. Prisma NON sceglie il regime fiscale, l'IVA, il contributo
// previdenziale, la ritenuta o il bollo: sono tutti campi che il consulente compila in Impostazioni › Studio › Fatturazione
// (vuoti di base, nessun valore predefinito, nemmeno nei dati di prova). Finché mancano, la fattura non si prepara e
// `MotoreFattura.mancanti` dice che cosa manca. Gli elenchi dei codici (RF, N, TC, RT, MP, TP) sono i valori pubblici del
// tracciato FatturaPA 1.2.2 con la descrizione ufficiale: servono a far scegliere il consulente, non scelgono al suo posto.
// Tutto è letto con tolleranza: un campo illeggibile diventa vuoto e non fa scartare le impostazioni.

/// Lettura tollerante di un campo: un valore assente o illeggibile diventa nil.
private func leggiCampoFiscale<T: Decodable, K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ k: K) -> T? {
    (try? c.decodeIfPresent(T.self, forKey: k)) ?? nil
}

/// Un numero inserito dal consulente: nil se illeggibile, non finito o negativo.
private func leggiImportoFiscale<K: CodingKey>(_ c: KeyedDecodingContainer<K>, _ k: K) -> Double? {
    guard let v: Double = leggiCampoFiscale(c, k), v.isFinite, v >= 0 else { return nil }
    return v
}

/// Regime fiscale del cedente (RegimeFiscale, 1.2.1.8 del tracciato 1.2.2). Il consulente sceglie il suo codice.
enum CodiceRegimeFiscale: String, Codable, CaseIterable, Identifiable {
    case rf01 = "RF01", rf02 = "RF02", rf04 = "RF04", rf05 = "RF05", rf06 = "RF06", rf07 = "RF07", rf08 = "RF08"
    case rf09 = "RF09", rf10 = "RF10", rf11 = "RF11", rf12 = "RF12", rf13 = "RF13", rf14 = "RF14", rf15 = "RF15"
    case rf16 = "RF16", rf17 = "RF17", rf18 = "RF18", rf19 = "RF19"

    var id: String { rawValue }
    var codice: String { rawValue }

    /// La descrizione del tracciato.
    var descrizione: String {
        switch self {
        case .rf01: return "Ordinario"
        case .rf02: return "Contribuenti minimi (art. 1, c. 96-117, L. 244/07)"
        case .rf04: return "Agricoltura e attività connesse e pesca (artt. 34 e 34-bis, DPR 633/72)"
        case .rf05: return "Vendita sali e tabacchi (art. 74, c. 1, DPR 633/72)"
        case .rf06: return "Commercio fiammiferi (art. 74, c. 1, DPR 633/72)"
        case .rf07: return "Editoria (art. 74, c. 1, DPR 633/72)"
        case .rf08: return "Gestione servizi telefonia pubblica (art. 74, c. 1, DPR 633/72)"
        case .rf09: return "Rivendita documenti di trasporto pubblico e di sosta (art. 74, c. 1, DPR 633/72)"
        case .rf10: return "Intrattenimenti, giochi e altre attività di cui alla tariffa allegata al DPR 640/72 (art. 74, c. 6, DPR 633/72)"
        case .rf11: return "Agenzie viaggi e turismo (art. 74-ter, DPR 633/72)"
        case .rf12: return "Agriturismo (art. 5, c. 2, L. 413/91)"
        case .rf13: return "Vendite a domicilio (art. 25-bis, c. 6, DPR 600/73)"
        case .rf14: return "Rivendita beni usati, oggetti d'arte, d'antiquariato o da collezione (art. 36, DL 41/95)"
        case .rf15: return "Agenzie di vendite all'asta di oggetti d'arte, antiquariato o da collezione (art. 40-bis, DL 41/95)"
        case .rf16: return "IVA per cassa P.A. (art. 6, c. 5, DPR 633/72)"
        case .rf17: return "IVA per cassa (art. 32-bis, DL 83/2012)"
        case .rf18: return "Altro"
        case .rf19: return "Regime forfettario (art. 1, c. 54-89, L. 190/2014)"
        }
    }

    /// «RF19 · Regime forfettario (…)», per l'elenco da cui scegliere.
    var etichetta: String { "\(rawValue) · \(descrizione)" }
}

/// Natura dell'operazione senza IVA (Natura, tracciato 1.2.2). Il consulente la sceglie con il suo riferimento normativo.
enum NaturaIVA: String, Codable, CaseIterable, Identifiable {
    case n1 = "N1"
    case n2_1 = "N2.1", n2_2 = "N2.2"
    case n3_1 = "N3.1", n3_2 = "N3.2", n3_3 = "N3.3", n3_4 = "N3.4", n3_5 = "N3.5", n3_6 = "N3.6"
    case n4 = "N4", n5 = "N5"
    case n6_1 = "N6.1", n6_2 = "N6.2", n6_3 = "N6.3", n6_4 = "N6.4", n6_5 = "N6.5", n6_6 = "N6.6", n6_7 = "N6.7"
    case n6_8 = "N6.8", n6_9 = "N6.9"
    case n7 = "N7"

    var id: String { rawValue }
    var codice: String { rawValue }

    var descrizione: String {
        switch self {
        case .n1: return "Escluse ex art. 15 del DPR 633/72"
        case .n2_1: return "Non soggette ad IVA ai sensi degli artt. da 7 a 7-septies del DPR 633/72"
        case .n2_2: return "Non soggette – altri casi"
        case .n3_1: return "Non imponibili – esportazioni"
        case .n3_2: return "Non imponibili – cessioni intracomunitarie"
        case .n3_3: return "Non imponibili – cessioni verso San Marino"
        case .n3_4: return "Non imponibili – operazioni assimilate alle cessioni all'esportazione"
        case .n3_5: return "Non imponibili – a seguito di dichiarazioni d'intento"
        case .n3_6: return "Non imponibili – altre operazioni che non concorrono alla formazione del plafond"
        case .n4: return "Esenti"
        case .n5: return "Regime del margine / IVA non esposta in fattura"
        case .n6_1: return "Inversione contabile – cessione di rottami e altri materiali di recupero"
        case .n6_2: return "Inversione contabile – cessione di oro e argento ai sensi della legge 7/2000 nonché di oreficeria usata ad OPO"
        case .n6_3: return "Inversione contabile – subappalto nel settore edile"
        case .n6_4: return "Inversione contabile – cessione di fabbricati"
        case .n6_5: return "Inversione contabile – cessione di telefoni cellulari"
        case .n6_6: return "Inversione contabile – cessione di prodotti elettronici"
        case .n6_7: return "Inversione contabile – prestazioni comparto edile e settori connessi"
        case .n6_8: return "Inversione contabile – operazioni settore energetico"
        case .n6_9: return "Inversione contabile – altri casi"
        case .n7: return "IVA assolta in altro stato UE (vendite a distanza e prestazioni di servizi di telecomunicazioni, tele-radiodiffusione ed elettronici)"
        }
    }

    var etichetta: String { "\(rawValue) · \(descrizione)" }
}

/// Esigibilità dell'IVA (EsigibilitaIVA, facoltativa): I immediata, D differita, S scissione dei pagamenti.
enum EsigibilitaIVA: String, Codable, CaseIterable, Identifiable {
    case immediata = "I", differita = "D", scissione = "S"
    var id: String { rawValue }
    var descrizione: String {
        switch self {
        case .immediata: return "IVA ad esigibilità immediata"
        case .differita: return "IVA ad esigibilità differita"
        case .scissione: return "Scissione dei pagamenti"
        }
    }
}

/// Tipo di cassa previdenziale (TipoCassa, tracciato 1.2.2).
enum TipoCassa: String, Codable, CaseIterable, Identifiable {
    case tc01 = "TC01", tc02 = "TC02", tc03 = "TC03", tc04 = "TC04", tc05 = "TC05", tc06 = "TC06", tc07 = "TC07"
    case tc08 = "TC08", tc09 = "TC09", tc10 = "TC10", tc11 = "TC11", tc12 = "TC12", tc13 = "TC13", tc14 = "TC14"
    case tc15 = "TC15", tc16 = "TC16", tc17 = "TC17", tc18 = "TC18", tc19 = "TC19", tc20 = "TC20", tc21 = "TC21"
    case tc22 = "TC22"

    var id: String { rawValue }
    var codice: String { rawValue }

    var descrizione: String {
        switch self {
        case .tc01: return "Cassa nazionale previdenza e assistenza avvocati e procuratori legali"
        case .tc02: return "Cassa previdenza dottori commercialisti"
        case .tc03: return "Cassa previdenza e assistenza geometri"
        case .tc04: return "Cassa nazionale previdenza e assistenza ingegneri e architetti liberi professionisti"
        case .tc05: return "Cassa nazionale del notariato"
        case .tc06: return "Cassa nazionale previdenza e assistenza ragionieri e periti commerciali"
        case .tc07: return "Ente nazionale assistenza agenti e rappresentanti di commercio (ENASARCO)"
        case .tc08: return "Ente nazionale previdenza e assistenza consulenti del lavoro (ENPACL)"
        case .tc09: return "Ente nazionale previdenza e assistenza medici (ENPAM)"
        case .tc10: return "Ente nazionale previdenza e assistenza farmacisti (ENPAF)"
        case .tc11: return "Ente nazionale previdenza e assistenza veterinari (ENPAV)"
        case .tc12: return "Ente nazionale previdenza e assistenza impiegati dell'agricoltura (ENPAIA)"
        case .tc13: return "Fondo previdenza impiegati imprese di spedizione e agenzie marittime"
        case .tc14: return "Istituto nazionale previdenza giornalisti italiani (INPGI)"
        case .tc15: return "Opera nazionale assistenza orfani sanitari italiani (ONAOSI)"
        case .tc16: return "Cassa autonoma assistenza integrativa giornalisti italiani (CASAGIT)"
        case .tc17: return "Ente previdenza periti industriali e periti industriali laureati (EPPI)"
        case .tc18: return "Ente previdenza e assistenza pluricategoriale (EPAP)"
        case .tc19: return "Ente nazionale previdenza e assistenza biologi (ENPAB)"
        case .tc20: return "Ente nazionale previdenza e assistenza professione infermieristica (ENPAPI)"
        case .tc21: return "Ente nazionale previdenza e assistenza psicologi (ENPAP)"
        case .tc22: return "INPS"
        }
    }

    var etichetta: String { "\(rawValue) · \(descrizione)" }
}

/// Tipo di ritenuta (TipoRitenuta, tracciato 1.2.2).
enum TipoRitenuta: String, Codable, CaseIterable, Identifiable {
    case rt01 = "RT01", rt02 = "RT02", rt03 = "RT03", rt04 = "RT04", rt05 = "RT05", rt06 = "RT06"

    var id: String { rawValue }
    var codice: String { rawValue }

    var descrizione: String {
        switch self {
        case .rt01: return "Ritenuta persone fisiche"
        case .rt02: return "Ritenuta persone giuridiche"
        case .rt03: return "Contributo INPS"
        case .rt04: return "Contributo ENASARCO"
        case .rt05: return "Contributo ENPAM"
        case .rt06: return "Altro contributo previdenziale"
        }
    }

    var etichetta: String { "\(rawValue) · \(descrizione)" }
}

/// Modalità di pagamento (ModalitaPagamento, tracciato 1.2.2).
enum ModalitaPagamento: String, Codable, CaseIterable, Identifiable {
    case mp01 = "MP01", mp02 = "MP02", mp03 = "MP03", mp04 = "MP04", mp05 = "MP05", mp06 = "MP06", mp07 = "MP07"
    case mp08 = "MP08", mp09 = "MP09", mp10 = "MP10", mp11 = "MP11", mp12 = "MP12", mp13 = "MP13", mp14 = "MP14"
    case mp15 = "MP15", mp16 = "MP16", mp17 = "MP17", mp18 = "MP18", mp19 = "MP19", mp20 = "MP20", mp21 = "MP21"
    case mp22 = "MP22", mp23 = "MP23"

    var id: String { rawValue }
    var codice: String { rawValue }

    var descrizione: String {
        switch self {
        case .mp01: return "Contanti"
        case .mp02: return "Assegno"
        case .mp03: return "Assegno circolare"
        case .mp04: return "Contanti presso Tesoreria"
        case .mp05: return "Bonifico"
        case .mp06: return "Vaglia cambiario"
        case .mp07: return "Bollettino bancario"
        case .mp08: return "Carta di pagamento"
        case .mp09: return "RID"
        case .mp10: return "RID utenze"
        case .mp11: return "RID veloce"
        case .mp12: return "RIBA"
        case .mp13: return "MAV"
        case .mp14: return "Quietanza erario"
        case .mp15: return "Giroconto su conti di contabilità speciale"
        case .mp16: return "Domiciliazione bancaria"
        case .mp17: return "Domiciliazione postale"
        case .mp18: return "Bollettino di c/c postale"
        case .mp19: return "SEPA Direct Debit"
        case .mp20: return "SEPA Direct Debit CORE"
        case .mp21: return "SEPA Direct Debit B2B"
        case .mp22: return "Trattenuta su somme già riscosse"
        case .mp23: return "PagoPA"
        }
    }

    var etichetta: String { "\(rawValue) · \(descrizione)" }

    /// Le modalità per cui serve l'IBAN del consulente.
    var richiedeIBAN: Bool { self == .mp05 || self == .mp07 || self == .mp19 || self == .mp20 || self == .mp21 }
}

/// Condizioni di pagamento (CondizioniPagamento, tracciato 1.2.2).
enum CondizioniPagamento: String, Codable, CaseIterable, Identifiable {
    case rate = "TP01", completo = "TP02", anticipo = "TP03"
    var id: String { rawValue }
    var codice: String { rawValue }
    var descrizione: String {
        switch self {
        case .rate: return "Pagamento a rate"
        case .completo: return "Pagamento completo"
        case .anticipo: return "Anticipo"
        }
    }
}

/// Una sede (del consulente o del cliente), divisa nei campi del tracciato. Tutti scritti dal consulente.
struct SedeFiscale: Codable, Hashable {
    var indirizzo = ""
    var numeroCivico = ""
    /// 5 cifre.
    var cap = ""
    var comune = ""
    /// Sigla di 2 lettere (per l'Italia).
    var provincia = ""
    /// Codice ISO di 2 lettere (per esempio «IT»): lo scrive il consulente.
    var nazione = ""

    init() {}

    var vuota: Bool { self == SedeFiscale() }

    private enum CodingKeys: String, CodingKey { case indirizzo, numeroCivico, cap, comune, provincia, nazione }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        indirizzo = leggiCampoFiscale(c, .indirizzo) ?? ""
        numeroCivico = leggiCampoFiscale(c, .numeroCivico) ?? ""
        cap = leggiCampoFiscale(c, .cap) ?? ""
        comune = leggiCampoFiscale(c, .comune) ?? ""
        provincia = leggiCampoFiscale(c, .provincia) ?? ""
        nazione = leggiCampoFiscale(c, .nazione) ?? ""
    }
}

/// Il contributo previdenziale (cassa) come lo imposta il consulente. Si applica solo con `applicaCassa == true`.
struct CassaPrevidenziale: Codable, Hashable {
    var tipo: TipoCassa?
    /// Aliquota del contributo in percentuale (AlCassa), sull'imponibile delle righe.
    var aliquota: Double?
    /// Il contributo è soggetto a ritenuta (Ritenuta «SI» nei dati della cassa): scelta del consulente.
    var soggettoARitenuta: Bool?

    init(tipo: TipoCassa? = nil, aliquota: Double? = nil, soggettoARitenuta: Bool? = nil) {
        self.tipo = tipo
        self.aliquota = aliquota
        self.soggettoARitenuta = soggettoARitenuta
    }

    private enum CodingKeys: String, CodingKey { case tipo, aliquota, soggettoARitenuta }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        tipo = leggiCampoFiscale(c, .tipo)
        aliquota = leggiImportoFiscale(c, .aliquota)
        soggettoARitenuta = leggiCampoFiscale(c, .soggettoARitenuta)
    }
}

/// La ritenuta d'acconto come la imposta il consulente. Si applica solo con `applicaRitenuta == true`.
struct RitenutaAcconto: Codable, Hashable {
    var tipo: TipoRitenuta?
    /// Aliquota della ritenuta in percentuale.
    var aliquota: Double?
    /// Causale di pagamento del modello 770 (per esempio una lettera): la scrive il consulente.
    var causale = ""
    /// Percentuale dell'imponibile delle righe su cui si calcola la ritenuta (facoltativa: se manca, tutto l'imponibile).
    var quotaImponibile: Double?

    init(tipo: TipoRitenuta? = nil, aliquota: Double? = nil, causale: String = "", quotaImponibile: Double? = nil) {
        self.tipo = tipo
        self.aliquota = aliquota
        self.causale = causale
        self.quotaImponibile = quotaImponibile
    }

    private enum CodingKeys: String, CodingKey { case tipo, aliquota, causale, quotaImponibile }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        tipo = leggiCampoFiscale(c, .tipo)
        aliquota = leggiImportoFiscale(c, .aliquota)
        causale = leggiCampoFiscale(c, .causale) ?? ""
        quotaImponibile = leggiImportoFiscale(c, .quotaImponibile)
    }
}

/// L'imposta di bollo virtuale come la imposta il consulente. Si applica solo con `applicaBollo == true`.
struct BolloVirtuale: Codable, Hashable {
    /// Importo del bollo in euro, scritto dal consulente.
    var importo: Double?
    /// Facoltativa: il bollo è dovuto solo se l'imponibile senza IVA (con una natura) supera questa soglia. Senza
    /// soglia il bollo si applica a ogni fattura.
    var soglia: Double?
    /// Il bollo si addebita al cliente (riga in fattura e nel totale del documento): scelta del consulente.
    var aCaricoCliente: Bool?
    /// Con l'addebito al cliente: la natura della riga del bollo e il suo riferimento normativo (scelti dal consulente).
    var naturaRiga: NaturaIVA?
    var riferimentoNormativoRiga = ""

    init(importo: Double? = nil, soglia: Double? = nil, aCaricoCliente: Bool? = nil, naturaRiga: NaturaIVA? = nil,
         riferimentoNormativoRiga: String = "") {
        self.importo = importo
        self.soglia = soglia
        self.aCaricoCliente = aCaricoCliente
        self.naturaRiga = naturaRiga
        self.riferimentoNormativoRiga = riferimentoNormativoRiga
    }

    private enum CodingKeys: String, CodingKey { case importo, soglia, aCaricoCliente, naturaRiga, riferimentoNormativoRiga }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        importo = leggiImportoFiscale(c, .importo)
        soglia = leggiImportoFiscale(c, .soglia)
        aCaricoCliente = leggiCampoFiscale(c, .aCaricoCliente)
        naturaRiga = leggiCampoFiscale(c, .naturaRiga)
        riferimentoNormativoRiga = leggiCampoFiscale(c, .riferimentoNormativoRiga) ?? ""
    }
}

/// Il regime della fatturazione: tutte le regole fiscali, scelte dal consulente (o dal suo commercialista).
/// Vuoto di base: nessun codice, nessuna aliquota, nessuna scelta su cassa, ritenuta e bollo (nil = «non indicato»).
struct RegimeFatturazione: Codable, Hashable {
    var regimeFiscale: CodiceRegimeFiscale?
    /// IVA: un'aliquota in percentuale OPPURE una natura (operazione senza IVA) con il riferimento normativo.
    var aliquotaIVA: Double?
    var natura: NaturaIVA?
    /// Obbligatorio con la natura: il testo lo scrive il consulente.
    var riferimentoNormativo = ""
    var esigibilitaIVA: EsigibilitaIVA?
    /// Contributo previdenziale: true = si applica (con `cassa`), false = non si applica, nil = non indicato.
    var applicaCassa: Bool?
    var cassa = CassaPrevidenziale()
    /// Ritenuta d'acconto: true = si applica (con `ritenuta`), false = non si applica, nil = non indicato.
    var applicaRitenuta: Bool?
    var ritenuta = RitenutaAcconto()
    /// Bollo virtuale: true = sì (con `bollo`), false = no, nil = non indicato.
    var applicaBollo: Bool?
    var bollo = BolloVirtuale()
    /// La dicitura che il consulente vuole sul documento (il testo lo dà lui o il commercialista).
    var frasePiede = ""

    init() {}

    private enum CodingKeys: String, CodingKey {
        case regimeFiscale, aliquotaIVA, natura, riferimentoNormativo, esigibilitaIVA
        case applicaCassa, cassa, applicaRitenuta, ritenuta, applicaBollo, bollo, frasePiede
    }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        regimeFiscale = leggiCampoFiscale(c, .regimeFiscale)
        aliquotaIVA = leggiImportoFiscale(c, .aliquotaIVA)
        natura = leggiCampoFiscale(c, .natura)
        riferimentoNormativo = leggiCampoFiscale(c, .riferimentoNormativo) ?? ""
        esigibilitaIVA = leggiCampoFiscale(c, .esigibilitaIVA)
        applicaCassa = leggiCampoFiscale(c, .applicaCassa)
        cassa = leggiCampoFiscale(c, .cassa) ?? CassaPrevidenziale()
        applicaRitenuta = leggiCampoFiscale(c, .applicaRitenuta)
        ritenuta = leggiCampoFiscale(c, .ritenuta) ?? RitenutaAcconto()
        applicaBollo = leggiCampoFiscale(c, .applicaBollo)
        bollo = leggiCampoFiscale(c, .bollo) ?? BolloVirtuale()
        frasePiede = leggiCampoFiscale(c, .frasePiede) ?? ""
    }
}

/// La numerazione delle fatture, scelta dal consulente.
struct NumerazioneFatture: Codable, Hashable {
    /// Il modello del numero, con i segnaposti `{anno}`, `{numero}`, `{numero:3}` (numero con almeno 3 cifre) e
    /// `{prefisso}`; per esempio «{anno}/{numero:3}» dà «2026/016». Vuoto = prefisso seguito dal numero.
    var modello = ""
    var prefisso = ""
    /// Il numero da cui partire in un anno (per chi comincia a usare Prisma a metà anno). Senza: da 1.
    var primoNumeroPerAnno: [Int: Int] = [:]
    /// L'ultimo progressivo d'invio usato nel nome dei file XML (cresce di 1 a ogni file, non si ripete).
    var ultimoProgressivoInvio = 0

    init() {}

    private enum CodingKeys: String, CodingKey { case modello, prefisso, primoNumeroPerAnno, ultimoProgressivoInvio }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        modello = leggiCampoFiscale(c, .modello) ?? ""
        prefisso = leggiCampoFiscale(c, .prefisso) ?? ""
        let grezzi: [String: Int] = leggiCampoFiscale(c, .primoNumeroPerAnno) ?? [:]
        for (chiave, valore) in grezzi {
            if let anno = Int(chiave), valore >= 1 { primoNumeroPerAnno[anno] = valore }
        }
        if let u: Int = leggiCampoFiscale(c, .ultimoProgressivoInvio), u >= 0 { ultimoProgressivoInvio = u }
    }

    /// Gli anni si scrivono come testo, così il JSON è un oggetto leggibile.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(modello, forKey: .modello)
        try c.encode(prefisso, forKey: .prefisso)
        var perAnno: [String: Int] = [:]
        for (anno, valore) in primoNumeroPerAnno { perAnno[String(anno)] = valore }
        try c.encode(perAnno, forKey: .primoNumeroPerAnno)
        try c.encode(ultimoProgressivoInvio, forKey: .ultimoProgressivoInvio)
    }
}

/// Chi trasmette il file allo SdI (IdTrasmittente): il consulente stesso o un intermediario (il commercialista).
struct TrasmittenteFattura: Codable, Hashable {
    enum Chi: String, Codable, CaseIterable, Identifiable {
        case consulente, intermediario
        var id: String { rawValue }
        var nome: String { self == .consulente ? "Lo carico io" : "Lo carica il commercialista o un intermediario" }
    }

    /// nil = non indicato.
    var chi: Chi?
    /// Con un intermediario: il suo codice fiscale (IdCodice del trasmittente).
    var codiceFiscaleIntermediario = ""

    init(chi: Chi? = nil, codiceFiscaleIntermediario: String = "") {
        self.chi = chi
        self.codiceFiscaleIntermediario = codiceFiscaleIntermediario
    }

    private enum CodingKeys: String, CodingKey { case chi, codiceFiscaleIntermediario }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        chi = leggiCampoFiscale(c, .chi)
        codiceFiscaleIntermediario = leggiCampoFiscale(c, .codiceFiscaleIntermediario) ?? ""
    }
}

/// I dati fiscali del consulente per le fatture (Impostazioni › Studio › Fatturazione, `ImpostazioniStudio.fatturazione`).
/// Tutti vuoti di base. Il consulente è una persona (nome e cognome) oppure scrive una denominazione.
struct DatiFatturazione: Codable, Hashable {
    var nome = ""
    var cognome = ""
    /// In alternativa a nome e cognome (per esempio uno studio associato).
    var denominazione = ""
    /// 11 cifre (IdFiscaleIVA, IdPaese IT).
    var partitaIVA = ""
    var codiceFiscale = ""
    var sede = SedeFiscale()
    var email = ""
    var telefono = ""
    var pec = ""
    var iban = ""
    var banca = ""
    var beneficiario = ""
    var modalitaPagamento: ModalitaPagamento?
    var condizioniPagamento: CondizioniPagamento?
    /// Giorni per il pagamento dalla data della fattura (per la scadenza proposta), facoltativo.
    var giorniPagamento: Int?
    var regime = RegimeFatturazione()
    var numerazione = NumerazioneFatture()
    var trasmittente = TrasmittenteFattura()

    init() {}

    /// Nulla di inserito (i dati di Prisma appena installato).
    var vuoti: Bool { self == DatiFatturazione() }

    private enum CodingKeys: String, CodingKey {
        case nome, cognome, denominazione, partitaIVA, codiceFiscale, sede, email, telefono, pec
        case iban, banca, beneficiario, modalitaPagamento, condizioniPagamento, giorniPagamento
        case regime, numerazione, trasmittente
    }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        nome = leggiCampoFiscale(c, .nome) ?? ""
        cognome = leggiCampoFiscale(c, .cognome) ?? ""
        denominazione = leggiCampoFiscale(c, .denominazione) ?? ""
        partitaIVA = leggiCampoFiscale(c, .partitaIVA) ?? ""
        codiceFiscale = leggiCampoFiscale(c, .codiceFiscale) ?? ""
        sede = leggiCampoFiscale(c, .sede) ?? SedeFiscale()
        email = leggiCampoFiscale(c, .email) ?? ""
        telefono = leggiCampoFiscale(c, .telefono) ?? ""
        pec = leggiCampoFiscale(c, .pec) ?? ""
        iban = leggiCampoFiscale(c, .iban) ?? ""
        banca = leggiCampoFiscale(c, .banca) ?? ""
        beneficiario = leggiCampoFiscale(c, .beneficiario) ?? ""
        modalitaPagamento = leggiCampoFiscale(c, .modalitaPagamento)
        condizioniPagamento = leggiCampoFiscale(c, .condizioniPagamento)
        if let g: Int = leggiCampoFiscale(c, .giorniPagamento), g >= 0 { giorniPagamento = g }
        regime = leggiCampoFiscale(c, .regime) ?? RegimeFatturazione()
        numerazione = leggiCampoFiscale(c, .numerazione) ?? NumerazioneFatture()
        trasmittente = leggiCampoFiscale(c, .trasmittente) ?? TrasmittenteFattura()
    }
}

/// I dati del cliente per la fattura (dossier del cliente, `Cliente.fiscale`, dalla versione 26). Il codice fiscale
/// resta `Cliente.codiceFiscale`; l'indirizzo dell'anagrafica (`Cliente.indirizzo`, una stringa) resta com'è e qui è
/// diviso nei campi del tracciato.
struct DatiFiscaliCliente: Codable, Hashable {
    /// Nome e cognome come vanno in fattura (il nome dell'anagrafica è una stringa sola).
    var nome = ""
    var cognome = ""
    /// Se la fattura va a una società o a uno studio.
    var denominazione = ""
    var partitaIVA = ""
    /// 7 caratteri (0000000 per i privati senza codice).
    var codiceDestinatario = ""
    var pec = ""
    var sede = SedeFiscale()
    /// Il cliente è un sostituto d'imposta (per la ritenuta): nil = non indicato.
    var sostitutoImposta: Bool?

    init() {}

    var vuoti: Bool { self == DatiFiscaliCliente() }

    private enum CodingKeys: String, CodingKey {
        case nome, cognome, denominazione, partitaIVA, codiceDestinatario, pec, sede, sostitutoImposta
    }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        nome = leggiCampoFiscale(c, .nome) ?? ""
        cognome = leggiCampoFiscale(c, .cognome) ?? ""
        denominazione = leggiCampoFiscale(c, .denominazione) ?? ""
        partitaIVA = leggiCampoFiscale(c, .partitaIVA) ?? ""
        codiceDestinatario = leggiCampoFiscale(c, .codiceDestinatario) ?? ""
        pec = leggiCampoFiscale(c, .pec) ?? ""
        sede = leggiCampoFiscale(c, .sede) ?? SedeFiscale()
        sostitutoImposta = leggiCampoFiscale(c, .sostitutoImposta)
    }
}
