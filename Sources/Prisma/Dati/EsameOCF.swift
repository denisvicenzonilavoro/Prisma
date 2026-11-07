import Foundation

// L'allenamento per l'esame OCF (Studio › Esame OCF, Orizzonte giro 6, specifica §11). Le domande le importa il
// consulente nel suo archivio locale (CSV o JSON, Design/ocf-formato.md); Prisma ne contiene solo poche di esempio,
// scritte apposta (`Risorse/ocf-esempio.json`). Nell'archivio dalla versione 26 (`DatiPrisma.ocf`), letto con
// tolleranza: una domanda o una risposta illeggibile si scarta, le altre restano.

/// Da dove viene una domanda.
enum OrigineDomandaOCF: String, Codable, CaseIterable {
    /// Una delle domande di esempio di Prisma.
    case esempio
    /// Importata dal consulente da un file CSV o JSON.
    case importata
    /// Proposta da Vera e confermata dal consulente.
    /// Compatibilità: negli archivi, nei backup e nei giornali di «Prisma ovunque» il valore salvato resta «eve» (il vecchio nome).
    case vera = "eve"
}

/// Il tipo di caso dei clienti a cui una domanda (o una materia) si può collegare: il «caso vero» dell'archivio.
enum CasoOCF: String, Codable, CaseIterable {
    /// Polizza rivalutabile di Ramo I in essere (gestione separata).
    case gestioneSeparata
    /// Polizza multiramo in essere.
    case multiramo
    /// Fondo, ETF o titoli in essere.
    case fondo
    /// Previdenza complementare in essere (PIP o fondo pensione).
    case previdenzaComplementare
    /// Temporanea caso morte in essere (TCM).
    case casoMorte
    /// Copertura danni alla persona o al patrimonio in essere (infortuni, invalidità, salute, LTC, casa, RC).
    case protezioneDanni
    /// Un KID tra i documenti dei clienti.
    case kid

    /// Un valore scritto in un file: il nome del caso, senza badare a maiuscole, trattini e spazi («gestione-separata»).
    static func da(_ testo: String?) -> CasoOCF? {
        guard let t = testo?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        let pulito = t.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "_", with: "").replacingOccurrences(of: " ", with: "")
            .lowercased()
        return allCases.first { $0.rawValue.lowercased() == pulito }
    }
}

/// Una materia dell'esame, con il nome che decide il consulente.
struct MateriaOCF: Codable, Hashable, Identifiable {
    var id: String
    var nome: String
    /// Il caso dei clienti che fa da esempio per le domande di questa materia senza un caso proprio.
    var caso: CasoOCF?

    init(id: String, nome: String, caso: CasoOCF? = nil) {
        self.id = id
        self.nome = nome
        self.caso = caso
    }

    private enum CodingKeys: String, CodingKey { case id, nome, caso }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        nome = (try? c.decodeIfPresent(String.self, forKey: .nome)) ?? id
        // Un caso sconosciuto si ignora
        caso = CasoOCF.da((try? c.decodeIfPresent(String.self, forKey: .caso)) ?? nil)
    }
}

/// Una domanda a risposta multipla: quattro risposte, una corretta.
struct DomandaOCF: Codable, Hashable, Identifiable {
    static let numeroRisposte = 4

    var id: String
    /// `MateriaOCF.id`.
    var materia: String
    var testo: String
    /// Le quattro risposte, nell'ordine A, B, C, D.
    var risposte: [String]
    /// Indice della risposta corretta (0 = A … 3 = D).
    var corretta: Int
    var spiegazione: String?
    /// Fonte o appunti del consulente (manuale, norma, pagina).
    var fonte: String?
    var origine: OrigineDomandaOCF
    /// Collegamento facoltativo a un tipo di caso dei clienti (prevale su quello della materia).
    var caso: CasoOCF?
    var aggiuntaIl: Date?

    init(id: String, materia: String, testo: String, risposte: [String], corretta: Int, spiegazione: String? = nil,
         fonte: String? = nil, origine: OrigineDomandaOCF = .importata, caso: CasoOCF? = nil, aggiuntaIl: Date? = nil) {
        self.id = id
        self.materia = materia
        self.testo = testo
        self.risposte = risposte
        self.corretta = corretta
        self.spiegazione = spiegazione
        self.fonte = fonte
        self.origine = origine
        self.caso = caso
        self.aggiuntaIl = aggiuntaIl
    }

    /// Quattro risposte non vuote e l'indice della corretta tra 0 e 3.
    var valida: Bool {
        risposte.count == Self.numeroRisposte && (0..<Self.numeroRisposte).contains(corretta)
            && !testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !materia.isEmpty
            && risposte.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// Stesso contenuto (id, data e origine a parte): reimportare la stessa domanda non la cambia.
    func stessoContenuto(di altra: DomandaOCF) -> Bool {
        materia == altra.materia && testo == altra.testo && risposte == altra.risposte && corretta == altra.corretta
            && spiegazione == altra.spiegazione && fonte == altra.fonte && caso == altra.caso
    }

    private enum CodingKeys: String, CodingKey {
        case id, materia, testo, risposte, corretta, spiegazione, fonte, origine, caso, aggiuntaIl
    }

    /// Lettura tollerante: origine sconosciuta = importata, caso sconosciuto = nessuno; una domanda senza quattro
    /// risposte o con l'indice fuori non si legge (e l'elenco la scarta).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        materia = try c.decode(String.self, forKey: .materia)
        testo = try c.decode(String.self, forKey: .testo)
        risposte = try c.decode([String].self, forKey: .risposte)
        corretta = try c.decode(Int.self, forKey: .corretta)
        spiegazione = (try? c.decodeIfPresent(String.self, forKey: .spiegazione)) ?? nil
        fonte = (try? c.decodeIfPresent(String.self, forKey: .fonte)) ?? nil
        origine = ((try? c.decodeIfPresent(String.self, forKey: .origine)) ?? nil).flatMap(OrigineDomandaOCF.init(rawValue:)) ?? .importata
        caso = CasoOCF.da((try? c.decodeIfPresent(String.self, forKey: .caso)) ?? nil)
        aggiuntaIl = (try? c.decodeIfPresent(Date.self, forKey: .aggiuntaIl)) ?? nil
        guard valida else {
            throw DecodingError.dataCorruptedError(forKey: .risposte, in: c, debugDescription: "Domanda OCF non valida")
        }
    }
}

/// Una risposta data: quando, a quale domanda, se era giusta. Lo storico è la sola fonte del ripasso: passo e
/// prossima data si ricavano (`MotoreOCF.ripasso`), non si salvano.
struct RispostaOCF: Codable, Hashable, Identifiable {
    var id: String
    var domandaId: String
    var data: Date
    var giusta: Bool
    /// La risposta scelta (0-3); nil = non registrata.
    var scelta: Int?

    init(id: String = UUID().uuidString, domandaId: String, data: Date, giusta: Bool, scelta: Int? = nil) {
        self.id = id
        self.domandaId = domandaId
        self.data = data
        self.giusta = giusta
        self.scelta = scelta
    }
}

/// L'allenamento OCF nell'archivio.
struct ArchivioOCF: Codable, Equatable {
    /// Domande nuove da proporre ogni giorno, dopo quelle del ripasso (da confermare con l'utente).
    static let nuovePredefinite = 10

    var materie: [MateriaOCF] = []
    var domande: [DomandaOCF] = []
    var risposte: [RispostaOCF] = []
    /// La data dell'esame (nil = non impostata).
    var dataEsame: Date?
    var nuovePerGiorno = ArchivioOCF.nuovePredefinite

    init() {}

    var vuoto: Bool { domande.isEmpty && risposte.isEmpty && materie.isEmpty && dataEsame == nil }

    func materia(_ id: String) -> MateriaOCF? { materie.first { $0.id == id } }
    func domanda(_ id: String) -> DomandaOCF? { domande.first { $0.id == id } }

    private enum CodingKeys: String, CodingKey { case materie, domande, risposte, dataEsame, nuovePerGiorno }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        materie = ((try? c.decodeIfPresent(ElencoTollerante<MateriaOCF>.self, forKey: .materie)) ?? nil)?.elementi ?? []
        domande = ((try? c.decodeIfPresent(ElencoTollerante<DomandaOCF>.self, forKey: .domande)) ?? nil)?.elementi ?? []
        risposte = ((try? c.decodeIfPresent(ElencoTollerante<RispostaOCF>.self, forKey: .risposte)) ?? nil)?.elementi ?? []
        dataEsame = (try? c.decodeIfPresent(Date.self, forKey: .dataEsame)) ?? nil
        let nuove = (try? c.decodeIfPresent(Int.self, forKey: .nuovePerGiorno)) ?? nil
        nuovePerGiorno = nuove.map { min(max($0, 0), 200) } ?? ArchivioOCF.nuovePredefinite
    }

    /// Registra una risposta (la domanda deve esserci). Restituisce la risposta salvata.
    @discardableResult
    mutating func rispondi(_ domandaId: String, scelta: Int, il data: Date = Date()) -> RispostaOCF? {
        guard let d = domanda(domandaId) else { return nil }
        let r = RispostaOCF(domandaId: domandaId, data: data, giusta: scelta == d.corretta, scelta: scelta)
        risposte.append(r)
        return r
    }

    /// Applica un'importazione confermata: materie nuove, domande nuove e aggiornate. Lo storico resta com'è.
    mutating func applica(_ i: ImportazioneOCF) {
        for m in i.materieNuove where materia(m.id) == nil { materie.append(m) }
        for d in i.aggiornate {
            if let k = domande.firstIndex(where: { $0.id == d.id }) { domande[k] = d }
        }
        let presenti = Set(domande.map(\.id))
        domande.append(contentsOf: i.nuove.filter { !presenti.contains($0.id) })
    }

    /// Toglie una domanda e le sue risposte.
    mutating func elimina(_ domandaId: String) {
        domande.removeAll { $0.id == domandaId }
        risposte.removeAll { $0.domandaId == domandaId }
    }
}
