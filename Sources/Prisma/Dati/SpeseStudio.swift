import Foundation

// Studio › Spese, «Chilometri, spese e scadenze» (Design/template-luce-specifica.md §6.3, «Luce» giro 9; decisioni 14,
// 22, 34, 66 e 100). Le cose del consulente come professionista: le spese con gli scontrini, le scadenze, i corsi di
// aggiornamento e le impostazioni dei chilometri.
//
// - Tutto lo scrive l'utente (decisione 66): nessuna scadenza fiscale, percentuale di deducibilità, IVA detraibile, costo
//   chilometrico o requisito di ore IVASS/OCF sta nel codice. Le categorie delle spese sono solo nomi descrittivi.
//   Prisma propone al più dei titoli di scadenza senza date (`ScadenzaStudio.titoliSuggeriti`): le date le decide l'utente,
//   da verificare con il suo commercialista.
// - I chilometri non si calcolano con servizi di percorso (decisione 22): l'utente scrive una volta i km di andata e
//   ritorno per cliente (`DatiPrisma.kmClienti`, nel file di ogni cliente) e corregge un giro a mano (`kmCorretti`).
// - Dove si è svolto un incontro lo dice l'utente (`Appuntamento.presso`, decisione 100): senza, la visita va fra quelle
//   «senza km» con «Dove eri?».
// - Archivio: versione 27, una sola chiave `speseStudio` (sezione «studio» della cartella a pezzi), letta con tolleranza
//   (una spesa, una scadenza o un corso illeggibile si scarta, gli altri restano). Le impostazioni stanno in
//   `ImpostazioniStudio.spese`. I file degli scontrini e degli attestati stanno in `Studio/Scontrini` e `Studio/Attestati`
//   accanto all'archivio: il backup li porta (è la cartella intera), «Prisma ovunque» no (restano sul Mac, come le spese).

// MARK: - Dove si è svolto un incontro

/// Dove si è svolto un appuntamento (decisione 100). nil = non indicato: Prisma non lo indovina dal testo del luogo.
enum LuogoIncontro: String, Codable, CaseIterable, Identifiable {
    case cliente, studio, altro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .cliente: return "Dal cliente"
        case .studio: return "In studio"
        case .altro: return "Altrove"
        }
    }
}

// MARK: - Spese

/// La categoria di una spesa: solo un nome descrittivo, scelto dall'utente. Nessuna percentuale di deducibilità.
enum CategoriaSpesa: String, Codable, CaseIterable, Identifiable {
    case carburante, pedaggi, parcheggio, pasti, viaggio, cancelleria, telefono, formazione, abbonamenti, altro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .carburante: return "Carburante"
        case .pedaggi: return "Pedaggi"
        case .parcheggio: return "Parcheggio"
        case .pasti: return "Pasti"
        case .viaggio: return "Viaggi"
        case .cancelleria: return "Cancelleria"
        case .telefono: return "Telefono e internet"
        case .formazione: return "Formazione"
        case .abbonamenti: return "Abbonamenti"
        case .altro: return "Altro"
        }
    }
}

/// Una spesa del consulente, scritta a mano o letta da uno scontrino (sempre confermata dall'utente).
struct SpesaStudio: Codable, Identifiable, Equatable {
    var id: String
    var data: Date
    var descrizione: String
    var esercente: String?
    var importo: Double
    /// L'IVA stampata sullo scontrino, se c'è: un fatto, non un calcolo di detraibilità.
    var iva: Double?
    var categoria: CategoriaSpesa
    var pagamento: String?
    /// Il canale a cui la spesa si riferisce, se l'utente lo indica (decisione 100).
    var canale: Canale?
    /// Il cliente a cui è legata, facoltativo: nel pacchetto per il commercialista il nome va solo con `nomiNelPacchetto`.
    var clienteId: String?
    /// Il nome del file nella cartella `Studio/Scontrini` (nil = senza scontrino).
    var scontrino: String?
    /// Letta da uno scontrino (poi confermata dall'utente).
    var letta: Bool
    /// Lo scontrino non diceva importo o data con certezza: la riga resta evidenziata in arancio finché non si controlla.
    var daControllare: Bool
    var nota: String

    init(id: String = "spesa-\(UUID().uuidString.prefix(8).lowercased())", data: Date, descrizione: String,
         esercente: String? = nil, importo: Double, iva: Double? = nil, categoria: CategoriaSpesa = .altro,
         pagamento: String? = nil, canale: Canale? = nil, clienteId: String? = nil, scontrino: String? = nil,
         letta: Bool = false, daControllare: Bool = false, nota: String = "") {
        self.id = id
        self.data = data
        self.descrizione = descrizione
        self.esercente = esercente
        self.importo = importo
        self.iva = iva
        self.categoria = categoria
        self.pagamento = pagamento
        self.canale = canale
        self.clienteId = clienteId
        self.scontrino = scontrino
        self.letta = letta
        self.daControllare = daControllare
        self.nota = nota
    }

    private enum CodingKeys: String, CodingKey {
        case id, data, descrizione, esercente, importo, iva, categoria, pagamento, canale, clienteId, scontrino, letta, daControllare, nota
    }

    /// Lettura tollerante: senza id o data la spesa si scarta; una categoria sconosciuta diventa «Altro».
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        data = try c.decode(Date.self, forKey: .data)
        descrizione = (try? c.decodeIfPresent(String.self, forKey: .descrizione)) ?? ""
        esercente = (try? c.decodeIfPresent(String.self, forKey: .esercente)) ?? nil
        let valore = (try? c.decodeIfPresent(Double.self, forKey: .importo)) ?? nil
        importo = valore.flatMap { $0.isFinite ? $0 : nil } ?? 0
        iva = ((try? c.decodeIfPresent(Double.self, forKey: .iva)) ?? nil).flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        categoria = ((try? c.decodeIfPresent(CategoriaSpesa.self, forKey: .categoria)) ?? nil) ?? .altro
        pagamento = (try? c.decodeIfPresent(String.self, forKey: .pagamento)) ?? nil
        canale = (try? c.decodeIfPresent(Canale.self, forKey: .canale)) ?? nil
        clienteId = (try? c.decodeIfPresent(String.self, forKey: .clienteId)) ?? nil
        scontrino = (try? c.decodeIfPresent(String.self, forKey: .scontrino)) ?? nil
        letta = (try? c.decodeIfPresent(Bool.self, forKey: .letta)) ?? false
        daControllare = (try? c.decodeIfPresent(Bool.self, forKey: .daControllare)) ?? false
        nota = (try? c.decodeIfPresent(String.self, forKey: .nota)) ?? ""
    }
}

// MARK: - Scadenze

/// Il tipo di una scadenza: decide solo il colore del mese nella card.
enum TipoScadenza: String, Codable, CaseIterable, Identifiable {
    case fiscale, polizza, aggiornamento, altra

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .fiscale: return "Fiscale"
        case .polizza: return "Polizza"
        case .aggiornamento: return "Aggiornamento professionale"
        case .altra: return "Altra"
        }
    }
}

/// Ogni quanto torna una scadenza (nil = una volta sola). La prossima nasce quando si segna fatta.
enum RicorrenzaScadenza: String, Codable, CaseIterable, Identifiable {
    case mensile, trimestrale, annuale

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .mensile: return "Ogni mese"
        case .trimestrale: return "Ogni tre mesi"
        case .annuale: return "Ogni anno"
        }
    }

    /// Quanti mesi dopo torna.
    var mesi: Int {
        switch self {
        case .mensile: return 1
        case .trimestrale: return 3
        case .annuale: return 12
        }
    }
}

/// Una scadenza del consulente (fiscale, polizza RC, aggiornamento, altro): data, ricorrenza e importo li scrive l'utente.
struct ScadenzaStudio: Codable, Identifiable, Equatable {
    var id: String
    var titolo: String
    var data: Date
    var ricorrenza: RicorrenzaScadenza?
    var tipo: TipoScadenza
    /// L'importo, se l'utente lo conosce (per esempio dal commercialista).
    var importo: Double?
    var nota: String
    /// Quando è stata segnata fatta (nil = da fare). Le fatte restano nell'archivio ma non si mostrano.
    var fattaIl: Date?

    init(id: String = "scadenza-\(UUID().uuidString.prefix(8).lowercased())", titolo: String, data: Date,
         ricorrenza: RicorrenzaScadenza? = nil, tipo: TipoScadenza = .altra, importo: Double? = nil, nota: String = "",
         fattaIl: Date? = nil) {
        self.id = id
        self.titolo = titolo
        self.data = data
        self.ricorrenza = ricorrenza
        self.tipo = tipo
        self.importo = importo
        self.nota = nota
        self.fattaIl = fattaIl
    }

    private enum CodingKeys: String, CodingKey { case id, titolo, data, ricorrenza, tipo, importo, nota, fattaIl }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        data = try c.decode(Date.self, forKey: .data)
        titolo = (try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? ""
        ricorrenza = (try? c.decodeIfPresent(RicorrenzaScadenza.self, forKey: .ricorrenza)) ?? nil
        tipo = ((try? c.decodeIfPresent(TipoScadenza.self, forKey: .tipo)) ?? nil) ?? .altra
        importo = ((try? c.decodeIfPresent(Double.self, forKey: .importo)) ?? nil).flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        nota = (try? c.decodeIfPresent(String.self, forKey: .nota)) ?? ""
        fattaIl = (try? c.decodeIfPresent(Date.self, forKey: .fattaIl)) ?? nil
    }

    /// I titoli che il modulo propone per una scadenza nuova: SOLO titoli e tipo, senza date né importi (decisione 66).
    /// Le date le scrive l'utente, da verificare con il commercialista.
    static let titoliSuggeriti: [(titolo: String, tipo: TipoScadenza)] = [
        ("F24", .fiscale),
        ("Acconto delle imposte", .fiscale),
        ("Saldo delle imposte", .fiscale),
        ("Polizza RC professionale", .polizza),
        ("Aggiornamento professionale", .aggiornamento),
    ]
}

// MARK: - Corsi di aggiornamento

/// Un corso di aggiornamento professionale con le sue ore e, se c'è, l'attestato (file in `Studio/Attestati`).
struct CorsoAggiornamento: Codable, Identifiable, Equatable {
    var id: String
    var titolo: String
    var ente: String
    var data: Date
    var ore: Double
    /// Il nome del file nella cartella `Studio/Attestati` (nil = attestato non allegato).
    var attestato: String?
    var canale: Canale?

    init(id: String = "corso-\(UUID().uuidString.prefix(8).lowercased())", titolo: String, ente: String = "", data: Date,
         ore: Double, attestato: String? = nil, canale: Canale? = nil) {
        self.id = id
        self.titolo = titolo
        self.ente = ente
        self.data = data
        self.ore = ore
        self.attestato = attestato
        self.canale = canale
    }

    private enum CodingKeys: String, CodingKey { case id, titolo, ente, data, ore, attestato, canale }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        data = try c.decode(Date.self, forKey: .data)
        titolo = (try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? ""
        ente = (try? c.decodeIfPresent(String.self, forKey: .ente)) ?? ""
        let o = (try? c.decodeIfPresent(Double.self, forKey: .ore)) ?? nil
        ore = o.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil } ?? 0
        attestato = (try? c.decodeIfPresent(String.self, forKey: .attestato)) ?? nil
        canale = (try? c.decodeIfPresent(Canale.self, forKey: .canale)) ?? nil
    }
}

// MARK: - Visite di clienti eliminati

/// Una visita conclusa di un cliente poi eliminato, tenuta per i chilometri dei mesi già chiusi: senza nome, titolo,
/// luogo né note, solo l'ora, dove si è svolta e i km di andata e ritorno che valevano quel giorno. `gruppo` è una sigla a
/// caso, uguale per le visite dello stesso cliente (due visite di fila sono una sola andata e ritorno) e senza legami con
/// il cliente tolto.
struct VisitaTolta: Codable, Identifiable, Equatable {
    /// L'id dell'appuntamento di allora.
    var id: String
    var inizio: Date
    var presso: LuogoIncontro?
    var km: Double?
    var gruppo: String

    init(id: String, inizio: Date, presso: LuogoIncontro?, km: Double?, gruppo: String) {
        self.id = id
        self.inizio = inizio
        self.presso = presso
        self.km = km
        self.gruppo = gruppo
    }

    private enum CodingKeys: String, CodingKey { case id, inizio, presso, km, gruppo }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        inizio = try c.decode(Date.self, forKey: .inizio)
        presso = (try? c.decodeIfPresent(LuogoIncontro.self, forKey: .presso)) ?? nil
        km = ((try? c.decodeIfPresent(Double.self, forKey: .km)) ?? nil).flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        gruppo = ((try? c.decodeIfPresent(String.self, forKey: .gruppo)) ?? nil) ?? id
    }
}

// MARK: - L'archivio delle spese

/// Spese, scadenze e corsi del consulente (`DatiPrisma.speseStudio`, versione 27, «Luce» giro 9).
struct ArchivioSpese: Codable, Equatable {
    var spese: [SpesaStudio] = []
    var scadenze: [ScadenzaStudio] = []
    var corsi: [CorsoAggiornamento] = []
    /// Le visite concluse dei clienti eliminati, perché i km dei mesi già chiusi col commercialista non cambino.
    var visiteTolte: [VisitaTolta] = []

    init(spese: [SpesaStudio] = [], scadenze: [ScadenzaStudio] = [], corsi: [CorsoAggiornamento] = [],
         visiteTolte: [VisitaTolta] = []) {
        self.spese = spese
        self.scadenze = scadenze
        self.corsi = corsi
        self.visiteTolte = visiteTolte
    }

    var vuoto: Bool { spese.isEmpty && scadenze.isEmpty && corsi.isEmpty && visiteTolte.isEmpty }

    private enum CodingKeys: String, CodingKey { case spese, scadenze, corsi, visiteTolte }

    /// Lettura tollerante: un elemento illeggibile si scarta, gli altri restano; un elenco illeggibile si apre vuoto.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spese = ((try? c.decodeIfPresent(ElencoTollerante<SpesaStudio>.self, forKey: .spese)) ?? nil)?.elementi ?? []
        scadenze = ((try? c.decodeIfPresent(ElencoTollerante<ScadenzaStudio>.self, forKey: .scadenze)) ?? nil)?.elementi ?? []
        corsi = ((try? c.decodeIfPresent(ElencoTollerante<CorsoAggiornamento>.self, forKey: .corsi)) ?? nil)?.elementi ?? []
        visiteTolte = ((try? c.decodeIfPresent(ElencoTollerante<VisitaTolta>.self, forKey: .visiteTolte)) ?? nil)?.elementi ?? []
    }
}

// MARK: - Impostazioni

/// Impostazioni › Studio › Chilometri, spese e scadenze (`ImpostazioniStudio.spese`, versione 27). Tutto dall'utente:
/// nessun valore inventato. Non entrano nei calcoli in cache (cambiarle non rifà le cache dei clienti).
struct ImpostazioniSpese: Codable, Equatable {
    /// Da dove parti: una descrizione («Studio di via Roma»), mai una coordinata. Vuota = non impostata.
    var partenza = ""
    /// Le correzioni a mano dei giri («aaaa-mm-gg» → km del giro): vincono sulla tabella.
    var kmCorretti: [String: Double] = [:]
    /// Contare anche gli appuntamenti senza cliente fatti fuori (i km solo dalla correzione del giorno).
    var contaVisiteSenzaCliente = false
    /// Le ore di aggiornamento richieste per anno (anno → ore), scritte dall'utente: nessun requisito nel codice.
    var oreAggiornamentoAnno: [Int: Double] = [:]
    /// L'ente dell'aggiornamento scritto dall'utente (per esempio quello che gli chiede le ore), vuoto = non indicato.
    var enteAggiornamento = ""
    /// Fino a questo giorno del mese Studio › Spese mostra il mese prima (quello da chiudere col commercialista).
    var giornoCambioMese = ImpostazioniSpese.giornoCambioPredefinito
    /// I nomi dei clienti visitati nel pacchetto per il commercialista: spento di base (decisione 14).
    var nomiNelPacchetto = false
    /// Il valore per km che l'utente vuole nel pacchetto (nil = nessuno: Prisma non mostra euro per i km).
    var euroPerKm: Double?

    static let giornoCambioPredefinito = 10
    static let giorniCambio = 1...28

    init() {}

    /// La chiave di un giorno per `kmCorretti`: «2026-10-03».
    static func chiaveGiorno(_ d: Date, calendario: Calendar = .current) -> String {
        let c = calendario.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private enum CodingKeys: String, CodingKey {
        case partenza, kmCorretti, contaVisiteSenzaCliente, oreAggiornamentoAnno
        case enteAggiornamento, giornoCambioMese, nomiNelPacchetto, euroPerKm
    }

    /// Lettura tollerante: un valore illeggibile, negativo o non finito si scarta, le altre impostazioni restano.
    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        func numeri(_ k: CodingKeys) -> [String: Double] {
            let grezzi = ((try? c.decodeIfPresent([String: Double].self, forKey: k)) ?? nil) ?? [:]
            return grezzi.filter { $0.value.isFinite && $0.value >= 0 }
        }
        partenza = ((try? c.decodeIfPresent(String.self, forKey: .partenza)) ?? nil) ?? ""
        kmCorretti = numeri(.kmCorretti)
        contaVisiteSenzaCliente = ((try? c.decodeIfPresent(Bool.self, forKey: .contaVisiteSenzaCliente)) ?? nil) ?? false
        for (chiave, valore) in numeri(.oreAggiornamentoAnno) {
            if let anno = Int(chiave) { oreAggiornamentoAnno[anno] = valore }
        }
        enteAggiornamento = ((try? c.decodeIfPresent(String.self, forKey: .enteAggiornamento)) ?? nil) ?? ""
        let giorno = ((try? c.decodeIfPresent(Int.self, forKey: .giornoCambioMese)) ?? nil) ?? Self.giornoCambioPredefinito
        giornoCambioMese = Self.giorniCambio.contains(giorno) ? giorno : Self.giornoCambioPredefinito
        nomiNelPacchetto = ((try? c.decodeIfPresent(Bool.self, forKey: .nomiNelPacchetto)) ?? nil) ?? false
        euroPerKm = ((try? c.decodeIfPresent(Double.self, forKey: .euroPerKm)) ?? nil).flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
    }

    /// Le ore per anno si scrivono con l'anno come testo, così il JSON è un oggetto leggibile.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(partenza, forKey: .partenza)
        try c.encode(kmCorretti, forKey: .kmCorretti)
        try c.encode(contaVisiteSenzaCliente, forKey: .contaVisiteSenzaCliente)
        var perAnno: [String: Double] = [:]
        for (anno, ore) in oreAggiornamentoAnno { perAnno[String(anno)] = ore }
        try c.encode(perAnno, forKey: .oreAggiornamentoAnno)
        try c.encode(enteAggiornamento, forKey: .enteAggiornamento)
        try c.encode(giornoCambioMese, forKey: .giornoCambioMese)
        try c.encode(nomiNelPacchetto, forKey: .nomiNelPacchetto)
        try c.encodeIfPresent(euroPerKm, forKey: .euroPerKm)
    }
}

// MARK: - I file

extension Archivio {
    /// La cartella dei file degli scontrini, accanto all'archivio (nel backup come i documenti, mai in «Prisma ovunque»).
    static func cartellaScontrini(in cartella: URL = Archivio.cartella) -> URL {
        cartella.appendingPathComponent("Studio", isDirectory: true).appendingPathComponent("Scontrini", isDirectory: true)
    }

    /// La cartella degli attestati dei corsi di aggiornamento.
    static func cartellaAttestati(in cartella: URL = Archivio.cartella) -> URL {
        cartella.appendingPathComponent("Studio", isDirectory: true).appendingPathComponent("Attestati", isDirectory: true)
    }

    /// Copia un file (scontrino o attestato) nella cartella data con un nome nuovo che non si ripete
    /// («a1b2c3d4-scontrino.jpg»). Restituisce il nome del file copiato.
    static func copiaFileStudio(_ url: URL, in cartella: URL) throws -> String {
        let fm = FileManager.default
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        let base = url.lastPathComponent.replacingOccurrences(of: "/", with: "-")
        let nome = "\(UUID().uuidString.prefix(8).lowercased())-\(base)"
        try fm.copyItem(at: url, to: cartella.appendingPathComponent(nome))
        return nome
    }
}
