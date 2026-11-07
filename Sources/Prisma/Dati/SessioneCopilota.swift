import Foundation

// Il copilota dell'incontro (Orizzonte, giro 5; specifica §8): il consenso del cliente all'ascolto, le sessioni
// d'ascolto con le schede riconosciute, il verbale e le attività create. Solo testo: l'audio non si salva mai e non
// lascia il dispositivo. La trascrizione si scrive nell'archivio solo se il consulente sceglie «Conserva la
// trascrizione»; altrimenti resta solo in memoria finché la sessione è aperta e poi si tiene il solo verbale.
// Niente entra nel dossier senza conferma: le schede nascono «proposte» e le applica `ApplicaCopilota`.

/// Il consenso del cliente all'ascolto del copilota (nel dossier, `Cliente.consensoCopilota`).
/// Letto con prudenza: senza la data o con un modo sconosciuto il consenso non vale (nil), mai il contrario.
struct ConsensoCopilota: Codable, Hashable {
    enum Modo: String, Codable, CaseIterable, Identifiable {
        case aVoce, scritto
        var id: String { rawValue }

        var nome: String {
            switch self {
            case .aVoce: return "A voce"
            case .scritto: return "Per iscritto"
            }
        }
    }

    /// Quando il cliente l'ha dato.
    var data: Date
    var modo: Modo
    /// Una nota del consulente («dato all'inizio dell'incontro, presente anche il marito»).
    var nota = ""

    init(data: Date, modo: Modo, nota: String = "") {
        self.data = data
        self.modo = modo
        self.nota = nota
    }

    private enum CodingKeys: String, CodingKey {
        case data, modo, nota
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Data e modo sono indispensabili: se mancano o non si leggono, il consenso non c'è
        data = try c.decode(Date.self, forKey: .data)
        modo = try c.decode(Modo.self, forKey: .modo)
        nota = ((try? c.decodeIfPresent(String.self, forKey: .nota)) ?? nil) ?? ""
    }
}

/// L'unica porta del copilota: senza consenso registrato non si accende niente (né il microfono, né il
/// riconoscimento, né le schede arrivate dall'iPad).
enum GuardiaCopilota {
    static let senzaCliente = "Scegli il cliente dell’incontro: il copilota ascolta solo un incontro con un cliente."
    static let consensoFuturo = "La data del consenso all’ascolto è nel futuro: correggila nel dossier prima di accendere il copilota."

    static func senzaConsenso(_ nome: String) -> String {
        let n = nome.trimmingCharacters(in: .whitespaces)
        return "Manca il consenso \(n.isEmpty ? "del cliente" : "di \(n)") all’ascolto: registralo nel dossier prima di accendere il copilota."
    }

    /// nil = il copilota può partire; altrimenti il motivo da mostrare.
    static func motivoBlocco(_ cliente: Cliente?, adesso: Date = Date()) -> String? {
        guard let c = cliente else { return senzaCliente }
        guard let consenso = c.consensoCopilota else { return senzaConsenso(c.nome) }
        // Un minuto di tolleranza per gli orologi
        guard consenso.data <= adesso.addingTimeInterval(60) else { return consensoFuturo }
        return nil
    }

    static func puoPartire(_ cliente: Cliente?, adesso: Date = Date()) -> Bool {
        motivoBlocco(cliente, adesso: adesso) == nil
    }
}

/// Un intervallo di testo, in caratteri (`Character`) dall'inizio del testo: le parole da illuminare.
struct IntervalloTesto: Codable, Hashable, Comparable {
    var inizio: Int
    var fine: Int

    init(_ inizio: Int, _ fine: Int) {
        self.inizio = max(0, inizio)
        self.fine = max(self.inizio, fine)
    }

    var lunghezza: Int { fine - inizio }

    static func < (a: IntervalloTesto, b: IntervalloTesto) -> Bool {
        a.inizio != b.inizio ? a.inizio < b.inizio : a.fine < b.fine
    }

    /// Lo stesso intervallo spostato di `n` caratteri (da una frase al pezzo che la contiene).
    func spostato(di n: Int) -> IntervalloTesto { IntervalloTesto(inizio + n, fine + n) }

    /// Il testo coperto dall'intervallo (nil se esce dal testo).
    func testo(in s: String) -> String? {
        guard fine <= s.count else { return nil }
        let a = s.index(s.startIndex, offsetBy: inizio)
        let b = s.index(s.startIndex, offsetBy: fine)
        return String(s[a..<b])
    }

    /// Da un intervallo UTF-16 (NSRange delle espressioni regolari) di `s` agli indici in caratteri.
    static func da(_ r: NSRange, in s: String) -> IntervalloTesto? {
        guard r.location != NSNotFound, let rr = Range(r, in: s) else { return nil }
        return IntervalloTesto(s.distance(from: s.startIndex, to: rr.lowerBound), s.distance(from: s.startIndex, to: rr.upperBound))
    }

    /// In ordine, con quelli che si toccano fusi in uno.
    static func unisci(_ elenco: [IntervalloTesto]) -> [IntervalloTesto] {
        var esito: [IntervalloTesto] = []
        for x in elenco.filter({ $0.lunghezza > 0 }).sorted() {
            if let u = esito.last, x.inizio <= u.fine {
                esito[esito.count - 1] = IntervalloTesto(u.inizio, max(u.fine, x.fine))
            } else {
                esito.append(x)
            }
        }
        return esito
    }

    private enum CodingKeys: String, CodingKey {
        case inizio, fine
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let a = try c.decode(Int.self, forKey: .inizio)
        let b = try c.decode(Int.self, forKey: .fine)
        self.init(a, b)
    }
}

/// Un pezzo della trascrizione: solo il testo riconosciuto sul dispositivo, mai l'audio.
struct PezzoTrascrizione: Identifiable, Codable, Hashable {
    enum Chi: String, Codable, CaseIterable {
        case consulente, cliente, sconosciuto
    }

    var id = "pezzo-\(UUID().uuidString.prefix(8).lowercased())"
    var testo: String
    var quando: Date
    var chi = Chi.sconosciuto
    /// Il dispositivo che l'ha sentito («Mac», «iPad»): nil = questo Mac.
    var dispositivo: String?
    /// Le parole da illuminare nel testo del pezzo.
    var evidenze: [IntervalloTesto] = []

    init(testo: String, quando: Date, chi: Chi = .sconosciuto, dispositivo: String? = nil, evidenze: [IntervalloTesto] = []) {
        self.testo = testo
        self.quando = quando
        self.chi = chi
        self.dispositivo = dispositivo
        self.evidenze = evidenze
    }

    private enum CodingKeys: String, CodingKey {
        case id, testo, quando, chi, dispositivo, evidenze
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        testo = try c.decode(String.self, forKey: .testo)
        if let i = try? c.decodeIfPresent(String.self, forKey: .id), !i.isEmpty { id = i }
        quando = ((try? c.decodeIfPresent(Date.self, forKey: .quando)) ?? nil) ?? Date(timeIntervalSinceReferenceDate: 0)
        chi = (try? c.decodeIfPresent(String.self, forKey: .chi)).flatMap { $0 }.flatMap(Chi.init(rawValue:)) ?? .sconosciuto
        dispositivo = (try? c.decodeIfPresent(String.self, forKey: .dispositivo)) ?? nil
        evidenze = ((try? c.decodeIfPresent(ElencoTollerante<IntervalloTesto>.self, forKey: .evidenze)) ?? nil)?.elementi ?? []
    }
}

/// Le cifre lette nella frase (mai inventate): tutte facoltative.
struct CifreCopilota: Codable, Hashable {
    /// Importo (obiettivo, premio): in euro.
    var importo: Double?
    /// Un elenco di importi («450, 550 e 650 euro al mese»).
    var importi: [Double]?
    var frequenza: Frequenza?
    /// «tra tre anni» → 3.
    var anniDaOggi: Int?
    var anno: Int?
    /// 1…12.
    var mese: Int?
    var area: AreaBisogno?
    var propensione: ProfiloInvestitore.Propensione?
    /// «vita intera», «TCM», «fondo pensione»…
    var tipoPolizza: String?
    /// La compagnia detta («Generali»); nil = «altra compagnia».
    var compagnia: String?
    var evento: EventoLineaVita.Tipo?
    /// La scadenza dell'attività, se la frase la dice («entro venerdì»).
    var scadenza: Date?

    init() {}

    var vuote: Bool { self == CifreCopilota() }

    /// Le cifre nuove dove ci sono, le vecchie altrimenti.
    func aggiornate(con n: CifreCopilota) -> CifreCopilota {
        var x = self
        if let v = n.importo { x.importo = v }
        if let v = n.importi { x.importi = v }
        if let v = n.frequenza { x.frequenza = v }
        if let v = n.anniDaOggi { x.anniDaOggi = v; if n.anno == nil { x.anno = nil; x.mese = nil } }
        if let v = n.anno { x.anno = v; if n.anniDaOggi == nil { x.anniDaOggi = nil } }
        if let v = n.mese { x.mese = v }
        if let v = n.area { x.area = v }
        if let v = n.propensione { x.propensione = v }
        if let v = n.tipoPolizza { x.tipoPolizza = v }
        if let v = n.compagnia { x.compagnia = v }
        if let v = n.evento { x.evento = v }
        if let v = n.scadenza { x.scadenza = v }
        return x
    }

    /// Completa le cifre che mancano con quelle di `n` (le proprie vincono).
    func completate(con n: CifreCopilota) -> CifreCopilota {
        var x = self
        if x.importo == nil { x.importo = n.importo }
        if x.importi == nil { x.importi = n.importi }
        if x.frequenza == nil { x.frequenza = n.frequenza }
        if x.anniDaOggi == nil && x.anno == nil { x.anniDaOggi = n.anniDaOggi; x.anno = n.anno }
        if x.mese == nil { x.mese = n.mese }
        if x.area == nil { x.area = n.area }
        if x.propensione == nil { x.propensione = n.propensione }
        if x.tipoPolizza == nil { x.tipoPolizza = n.tipoPolizza }
        if x.compagnia == nil { x.compagnia = n.compagnia }
        if x.evento == nil { x.evento = n.evento }
        if x.scadenza == nil { x.scadenza = n.scadenza }
        return x
    }

    private enum CodingKeys: String, CodingKey {
        case importo, importi, frequenza, anniDaOggi, anno, mese, area, propensione, tipoPolizza, compagnia, evento, scadenza
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func numero(_ k: CodingKeys) -> Double? {
            ((try? c.decodeIfPresent(Double.self, forKey: k)) ?? nil).flatMap { $0.isFinite ? $0 : nil }
        }
        func intero(_ k: CodingKeys) -> Int? { (try? c.decodeIfPresent(Int.self, forKey: k)) ?? nil }
        func testo(_ k: CodingKeys) -> String? { (try? c.decodeIfPresent(String.self, forKey: k)) ?? nil }
        importo = numero(.importo)
        importi = ((try? c.decodeIfPresent([Double].self, forKey: .importi)) ?? nil).map { $0.filter(\.isFinite) }
        frequenza = testo(.frequenza).flatMap(Frequenza.init(rawValue:))
        anniDaOggi = intero(.anniDaOggi)
        anno = intero(.anno)
        mese = intero(.mese).flatMap { (1...12).contains($0) ? $0 : nil }
        area = testo(.area).flatMap(AreaBisogno.init(rawValue:))
        propensione = testo(.propensione).flatMap(ProfiloInvestitore.Propensione.init(rawValue:))
        tipoPolizza = testo(.tipoPolizza)
        compagnia = testo(.compagnia)
        evento = testo(.evento).flatMap(EventoLineaVita.Tipo.init(rawValue:))
        scadenza = (try? c.decodeIfPresent(Date.self, forKey: .scadenza)) ?? nil
    }
}

/// Una cosa riconosciuta nell'incontro, con l'azione proposta. Nasce «proposta»: entra nel dossier solo quando il
/// consulente la conferma (da sola o con tutte le altre), con `ApplicaCopilota`.
struct SchedaCopilota: Identifiable, Codable, Hashable {
    enum Tipo: String, Codable, CaseIterable {
        /// Un obiettivo con tempi e cifre.
        case obiettivo
        /// Una polizza o posizione di un'altra compagnia.
        case polizzaEsterna
        /// Un timore o una preferenza di rischio (annotazione, non profilo MiFID).
        case profilo
        /// Un evento della vita.
        case evento
        /// Una cosa da fare.
        case attivita
    }

    enum Stato: String, Codable, CaseIterable {
        case proposta, confermata, scartata
    }

    enum Azione: String, Codable, CaseIterable {
        case aggiornaObiettivo, creaObiettivo, aggiungiPosizione, annotaProfilo, aggiungiLineaVita, creaAttivita

        var nome: String {
            switch self {
            case .aggiornaObiettivo: return "Aggiorna l’obiettivo"
            case .creaObiettivo: return "Crea l’obiettivo"
            case .aggiungiPosizione: return "Aggiungi a Posizioni"
            case .annotaProfilo: return "Annota nel profilo"
            case .aggiungiLineaVita: return "Aggiungi alla linea della vita"
            case .creaAttivita: return "Crea l’attività"
            }
        }

        /// L'azione di base di un tipo (l'obiettivo diventa «aggiorna» se il cliente ne ha già uno nell'area).
        static func di(_ t: Tipo) -> Azione {
            switch t {
            case .obiettivo: return .creaObiettivo
            case .polizzaEsterna: return .aggiungiPosizione
            case .profilo: return .annotaProfilo
            case .evento: return .aggiungiLineaVita
            case .attivita: return .creaAttivita
            }
        }
    }

    /// Chi l'ha riconosciuta.
    enum Origine: String, Codable, CaseIterable {
        case regole, qwen

        var nome: String {
            switch self {
            case .regole: return "Regole di Prisma"
            case .qwen: return "Qwen"
            }
        }
    }

    /// Stabile: tipo + chiave («obiettivo-casa»), così la stessa cosa detta due volte aggiorna la stessa scheda.
    var id: String
    var tipo: Tipo
    /// Costruito dall'app con frasi fisse dalle cifre («Casa tra 3 anni · 40.000 €»).
    var titolo: String
    var azione: Azione
    /// La frase da cui nasce (vuota nell'archivio se la trascrizione non si conserva).
    var frase: String
    /// Le parole da illuminare dentro `frase`.
    var evidenze: [IntervalloTesto] = []
    var pezzoId: String?
    var cifre = CifreCopilota()
    var origine = Origine.regole
    /// Il dispositivo che l'ha riconosciuta (nil = questo Mac; «iPad» per le schede arrivate dal ponte).
    var dispositivo: String?
    var stato = Stato.proposta
    /// L'obiettivo del cliente da aggiornare (azione `.aggiornaObiettivo`).
    var obiettivoId: String?
    /// Quando è entrata nel dossier e con quale elemento (id dell'obiettivo, della posizione, della nota…).
    var applicataIl: Date?
    var elementoId: String?

    init(id: String, tipo: Tipo, titolo: String, azione: Azione, frase: String, evidenze: [IntervalloTesto] = [],
         pezzoId: String? = nil, cifre: CifreCopilota = CifreCopilota(), origine: Origine = .regole) {
        self.id = id
        self.tipo = tipo
        self.titolo = titolo
        self.azione = azione
        self.frase = frase
        self.evidenze = evidenze
        self.pezzoId = pezzoId
        self.cifre = cifre
        self.origine = origine
    }

    private enum CodingKeys: String, CodingKey {
        case id, tipo, titolo, azione, frase, evidenze, pezzoId, cifre, origine, dispositivo, stato, obiettivoId, applicataIl, elementoId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Senza id o con un tipo sconosciuto la scheda si scarta (ElencoTollerante salta l'elemento)
        id = try c.decode(String.self, forKey: .id)
        tipo = try c.decode(Tipo.self, forKey: .tipo)
        func testo(_ k: CodingKeys) -> String? { (try? c.decodeIfPresent(String.self, forKey: k)) ?? nil }
        titolo = testo(.titolo) ?? ""
        azione = testo(.azione).flatMap(Azione.init(rawValue:)) ?? Azione.di(tipo)
        frase = testo(.frase) ?? ""
        evidenze = ((try? c.decodeIfPresent(ElencoTollerante<IntervalloTesto>.self, forKey: .evidenze)) ?? nil)?.elementi ?? []
        pezzoId = testo(.pezzoId)
        cifre = ((try? c.decodeIfPresent(CifreCopilota.self, forKey: .cifre)) ?? nil) ?? CifreCopilota()
        origine = testo(.origine).flatMap(Origine.init(rawValue:)) ?? .regole
        dispositivo = testo(.dispositivo)
        // Uno stato sconosciuto torna «proposta»: mai una scheda applicata per sbaglio
        stato = testo(.stato).flatMap(Stato.init(rawValue:)) ?? .proposta
        obiettivoId = testo(.obiettivoId)
        applicataIl = (try? c.decodeIfPresent(Date.self, forKey: .applicataIl)) ?? nil
        elementoId = testo(.elementoId)
    }

    /// La stessa scheda senza le parole del cliente (frase ed evidenze), per l'archivio senza trascrizione.
    var senzaFrase: SchedaCopilota {
        var x = self
        x.frase = ""
        x.evidenze = []
        return x
    }
}

/// Il verbale dell'incontro, con frasi fisse costruite dalle cifre delle schede.
struct VerbaleCopilota: Codable, Hashable {
    /// Cosa è emerso.
    var punti: [String] = []
    /// Le attività.
    var attivita: [String] = []
    /// Cosa cambia nel dossier.
    var dossier: [String] = []
    /// nil = da confermare.
    var confermatoIl: Date?

    init(punti: [String] = [], attivita: [String] = [], dossier: [String] = [], confermatoIl: Date? = nil) {
        self.punti = punti
        self.attivita = attivita
        self.dossier = dossier
        self.confermatoIl = confermatoIl
    }

    private enum CodingKeys: String, CodingKey {
        case punti, attivita, dossier, confermatoIl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        punti = ((try? c.decodeIfPresent([String].self, forKey: .punti)) ?? nil) ?? []
        attivita = ((try? c.decodeIfPresent([String].self, forKey: .attivita)) ?? nil) ?? []
        dossier = ((try? c.decodeIfPresent([String].self, forKey: .dossier)) ?? nil) ?? []
        confermatoIl = (try? c.decodeIfPresent(Date.self, forKey: .confermatoIl)) ?? nil
    }
}

/// Una sessione d'ascolto del copilota, per incontro (`DatiPrisma.sessioniCopilota`).
struct SessioneCopilota: Identifiable, Codable, Hashable {
    var id = "copilota-\(UUID().uuidString.prefix(8).lowercased())"
    var clienteId: String
    /// L'incontro (`DatiPrisma.incontri`) a cui appartiene, se c'è.
    var incontroId: String?
    var data: Date
    /// Il consenso com'era all'avvio (prova di cosa valeva quel giorno).
    var consenso: ConsensoCopilota
    /// «Conserva la trascrizione»: solo con questa scelta testo e frasi delle schede si scrivono nell'archivio.
    var conservaTrascrizione = false
    /// Solo testo. Senza «Conserva la trascrizione» non si scrive nell'archivio e alla chiusura si cancella.
    var trascrizione: [PezzoTrascrizione] = []
    var schede: [SchedaCopilota] = []
    var verbale: VerbaleCopilota?
    /// Le attività create dalle schede confermate (id in `DatiPrisma.attivita`).
    var attivitaCreate: [String] = []
    /// nil = l'ascolto è ancora aperto.
    var conclusaIl: Date?

    init(clienteId: String, incontroId: String? = nil, data: Date, consenso: ConsensoCopilota) {
        self.clienteId = clienteId
        self.incontroId = incontroId
        self.data = data
        self.consenso = consenso
    }

    /// Una sessione nuova, solo se il cliente ha dato il consenso (`GuardiaCopilota`).
    static func nuova(cliente: Cliente?, incontroId: String? = nil, data: Date = Date()) -> SessioneCopilota? {
        guard GuardiaCopilota.puoPartire(cliente, adesso: data), let c = cliente, let consenso = c.consensoCopilota else { return nil }
        return SessioneCopilota(clienteId: c.id, incontroId: incontroId, data: data, consenso: consenso)
    }

    var aperta: Bool { conclusaIl == nil }

    func scheda(_ id: String) -> SchedaCopilota? { schede.first { $0.id == id } }

    var proposte: [SchedaCopilota] { schede.filter { $0.stato == .proposta } }

    /// Dimentica le parole del cliente: la trascrizione e le frasi delle schede (resta il verbale).
    mutating func dimenticaTrascrizione() {
        trascrizione = []
        schede = schede.map(\.senzaFrase)
    }

    private enum CodingKeys: String, CodingKey {
        case id, clienteId, incontroId, data, consenso, conservaTrascrizione, trascrizione, schede, verbale, attivitaCreate, conclusaIl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Senza cliente o senza il consenso dell'avvio la sessione si scarta
        clienteId = try c.decode(String.self, forKey: .clienteId)
        consenso = try c.decode(ConsensoCopilota.self, forKey: .consenso)
        if let i = try? c.decodeIfPresent(String.self, forKey: .id), !i.isEmpty { id = i }
        incontroId = (try? c.decodeIfPresent(String.self, forKey: .incontroId)) ?? nil
        data = ((try? c.decodeIfPresent(Date.self, forKey: .data)) ?? nil) ?? consenso.data
        conservaTrascrizione = ((try? c.decodeIfPresent(Bool.self, forKey: .conservaTrascrizione)) ?? nil) ?? false
        let pezzi = ((try? c.decodeIfPresent(ElencoTollerante<PezzoTrascrizione>.self, forKey: .trascrizione)) ?? nil)?.elementi ?? []
        let lette = ((try? c.decodeIfPresent(ElencoTollerante<SchedaCopilota>.self, forKey: .schede)) ?? nil)?.elementi ?? []
        // Una trascrizione scritta senza la scelta di conservarla (archivio alterato) non si tiene
        trascrizione = conservaTrascrizione ? pezzi : []
        schede = conservaTrascrizione ? lette : lette.map(\.senzaFrase)
        verbale = (try? c.decodeIfPresent(VerbaleCopilota.self, forKey: .verbale)) ?? nil
        attivitaCreate = ((try? c.decodeIfPresent([String].self, forKey: .attivitaCreate)) ?? nil) ?? []
        conclusaIl = (try? c.decodeIfPresent(Date.self, forKey: .conclusaIl)) ?? nil
    }

    /// La trascrizione e le frasi delle schede si scrivono solo con «Conserva la trascrizione».
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(clienteId, forKey: .clienteId)
        try c.encodeIfPresent(incontroId, forKey: .incontroId)
        try c.encode(data, forKey: .data)
        try c.encode(consenso, forKey: .consenso)
        try c.encode(conservaTrascrizione, forKey: .conservaTrascrizione)
        if conservaTrascrizione {
            try c.encode(trascrizione, forKey: .trascrizione)
            try c.encode(schede, forKey: .schede)
        } else {
            try c.encode(schede.map(\.senzaFrase), forKey: .schede)
        }
        try c.encodeIfPresent(verbale, forKey: .verbale)
        try c.encode(attivitaCreate, forKey: .attivitaCreate)
        try c.encodeIfPresent(conclusaIl, forKey: .conclusaIl)
    }
}
