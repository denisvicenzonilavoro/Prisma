import Foundation

// Il contenuto del Prisma del cliente («Luce» giro 15, Design/template-luce-specifica.md §2.1.5 punto 2): solo ciò che il
// cliente vedrà, già calcolato da Prisma (il file non contiene nessun motore di calcolo). Lo stesso modello disegna
// l'anteprima nel telefono del palco (`MiniPrisma`), le pagine del PDF protetto (`PaginePrismaCliente`) e, cifrato, il
// file HTML sperimentale (`FilePrismaCliente`). Non si salva mai nell'archivio: nasce alla preparazione del file e se ne
// va con lui. Mai numeri di contratto, IBAN, codice fiscale, email o telefono.

/// Le voci del file («COSA C'È DENTRO»).
enum VoceFilePrisma: String, Codable, CaseIterable, Identifiable {
    case obiettivi, lineaVita, lettera, film, luce, giornata, sinistro, posizioni

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .obiettivi: return "Gli obiettivi con gli anelli"
        case .lineaVita: return "La linea della vita da esplorare"
        case .lettera: return "La lettera dal futuro"
        case .film: return "Il film del piano"
        case .luce: return "Il prisma di luce"
        case .giornata: return "Una giornata della pensione"
        case .sinistro: return "Il tuo sinistro"
        case .posizioni: return "Le posizioni nel dettaglio"
        }
    }

    /// Le voci accese di base (le posizioni partono spente: §2.1.4).
    static let accesePredefinite: Set<VoceFilePrisma> = [.obiettivi, .lineaVita, .lettera, .film]

    /// La voce che accende un'esperienza della Sala con «✦ Aggiungi al Prisma di …» (nil = nessuna: il disegno entra
    /// nel file solo come obiettivo salvato, decisione 7).
    static func perEsperienza(_ e: EsperienzaSala) -> VoceFilePrisma? {
        switch e {
        case .lettera: return .lettera
        case .film: return .film
        case .prismaLuce: return .luce
        case .giornataPensione: return .giornata
        default: return nil
        }
    }

    /// Le voci in ordine, da un elenco di nomi salvati (i nomi sconosciuti si ignorano).
    static func da(_ nomi: [String]) -> [VoceFilePrisma] {
        let insieme = Set(nomi.compactMap(VoceFilePrisma.init(rawValue:)))
        return allCases.filter { insieme.contains($0) }
    }
}

/// Un obiettivo come lo vede il cliente: il nome, la quota già da parte (0…1, decisione 81) e il colore dell'area.
struct ObiettivoMini: Codable, Equatable {
    var titolo: String
    var quota: Double
    var coloreHex: String
}

/// La linea della vita per un'età di pensione: il patrimonio anno per anno da oggi a `etaFine` (euro di oggi).
struct SerieLineaVita: Codable, Equatable {
    var etaPensione: Int
    var valori: [Double]
    /// Primo anno con il patrimonio sotto zero; nil = basta oltre `etaFine`.
    var etaEsaurimento: Int?
}

/// Le serie già calcolate per ogni età del cursore (solo le età dopo quella di oggi).
struct LineaVitaMini: Codable, Equatable {
    var etaOggi: Int
    var etaProposta: Int
    var etaFine: Int
    var serie: [SerieLineaVita]
    /// Dopo la pensione la linea è indicativa (manca il reddito desiderato o la pensione pubblica).
    var indicativa: Bool

    /// La serie dell'età data (o la più vicina).
    func serie(_ eta: Int) -> SerieLineaVita? {
        serie.first { $0.etaPensione == eta } ?? serie.min { abs($0.etaPensione - eta) < abs($1.etaPensione - eta) }
    }
}

/// Una posizione in essere come la vede il cliente: nome, canale a parole, colore del canale, valore e data.
struct PosizioneMini: Codable, Equatable {
    var nome: String
    var canale: String
    var coloreCanaleHex: String
    var valore: Double
    var data: Date
}

/// Il contenuto del file del cliente (versione 1 del formato).
struct ContenutoPrismaCliente: Codable, Equatable {
    var versione = 1
    var nomeBattesimo: String
    /// «Denis Vicenzoni · il tuo consulente» (o «Il tuo consulente» senza nome).
    var consulente: String
    var creatoIl: Date
    var validoFinoAl: Date
    var obiettivi: [ObiettivoMini]?
    var lineaVita: LineaVitaMini?
    var lettera: String?
    /// MP4 del film del piano (solo nell'HTML: nel PDF «te l'ho mandato a parte»).
    var film: Data?
    /// PNG del prisma di luce (immagine ferma).
    var luce: Data?
    /// PNG di una giornata della pensione (modalità ferma, cifre di oggi).
    var giornata: Data?
    var sinistri: [SinistroMini]?
    var posizioni: [PosizioneMini]?
    var avvertenze: [String]
    var diProva: Bool
    /// Il film c'era fra le voci accese (nel PDF la riga «te l'ho mandato a parte» anche senza i byte del video).
    var conFilm: Bool = false

    init(nomeBattesimo: String, consulente: String, creatoIl: Date, validoFinoAl: Date, obiettivi: [ObiettivoMini]? = nil,
         lineaVita: LineaVitaMini? = nil, lettera: String? = nil, film: Data? = nil, luce: Data? = nil, giornata: Data? = nil,
         sinistri: [SinistroMini]? = nil, posizioni: [PosizioneMini]? = nil, avvertenze: [String], diProva: Bool,
         conFilm: Bool = false) {
        self.nomeBattesimo = nomeBattesimo
        self.consulente = consulente
        self.creatoIl = creatoIl
        self.validoFinoAl = validoFinoAl
        self.obiettivi = obiettivi
        self.lineaVita = lineaVita
        self.lettera = lettera
        self.film = film
        self.luce = luce
        self.giornata = giornata
        self.sinistri = sinistri
        self.posizioni = posizioni
        self.avvertenze = avvertenze
        self.diProva = diProva
        self.conFilm = conFilm || film != nil
    }

    /// Le voci che il contenuto porta davvero (per `StatoPrismaCliente.contenuti`).
    var voci: [VoceFilePrisma] {
        var v: [VoceFilePrisma] = []
        if obiettivi?.isEmpty == false { v.append(.obiettivi) }
        if lineaVita != nil { v.append(.lineaVita) }
        if lettera != nil { v.append(.lettera) }
        if conFilm { v.append(.film) }
        if luce != nil { v.append(.luce) }
        if giornata != nil { v.append(.giornata) }
        if sinistri?.isEmpty == false { v.append(.sinistro) }
        if posizioni?.isEmpty == false { v.append(.posizioni) }
        return v
    }

    /// Il JSON del contenuto (date ISO 8601, dati in base64): lo stesso che legge il lettore del file.
    func json() throws -> Data {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return try e.encode(self)
    }

    static func daJSON(_ dati: Data) throws -> ContenutoPrismaCliente {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(ContenutoPrismaCliente.self, from: dati)
    }
}
