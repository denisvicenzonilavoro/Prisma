import Foundation

// «Ragiona a passi» (Vera/BRIEF.md, funzione 20; template «Ragiona a passi»): davanti a una richiesta complicata («Marco ha
// 400 € al mese: vuole proteggere Elena e continuare con gli studi di Tommaso. Come li divido?») Vera scrive un piano
// visibile di al massimo cinque passi, ognuno con il suo strumento di Prisma, lo esegue un passo alla volta e alla fine
// spiega la scelta.
//
// Chi fa cosa (regola 5 «Prima il codice»):
// - le regole riconoscono quando una richiesta merita il ragionamento a passi (`eUnaRichiesta`) e la capiscono
//   (`capisci`: budget mensile o capitale una tantum, protezione sì o no, gli obiettivi del cliente di cui si parla, chi va
//   protetto). Oltre a «come li divido?», anche le scelte tra due voci («meglio la casa o gli studi?», «cosa conviene
//   prima», «su cosa punto») e i capitali da dividere tra gli obiettivi («30.000 € da parte: casa o studi?», simulati
//   con l'accantonato dell'obiettivo; la protezione no, perché si paga con un premio periodico);
// - Qwen propone il piano in JSON scegliendo solo dal catalogo di sola lettura (`StrumentoPasso`); il codice lo valida
//   (strumenti esistenti, al massimo cinque passi, letture prima della simulazione, «scegli e spiega» per ultimo, titoli
//   senza cifre) e, se non va, usa il piano delle regole (`pianoConRegole`);
// - i passi si eseguono uno alla volta (`eseguiPasso`) con i motori di Prisma: MotoreAnalisi.protezione e la tariffa caso
//   morte del simulatore della protezione (MotoreSimulatoriAnalisi), MotoreObiettivo (lo stesso calcolo del cursore del
//   dettaglio dell'obiettivo) per ogni divisione, le scadenze delle posizioni per i vincoli;
// - la scelta la fa una regola trasparente (`regola`): regge chi porta tutti gli obiettivi in tempo; tra queste, quella che
//   protegge di più; a parità, l'equilibrio. Se nessuna regge, quella che lascia meno indietro la voce più scoperta;
// - Qwen spiega la scelta con le cifre di Prisma (`leggiSpiegazione` scarta il testo che non è JSON, con cifre nuove,
//   anche in lettere, o che consiglia un'altra divisione, `consigliaSolo`); senza Qwen resta la bozza di Prisma.
//   Se il piano di Qwen salta «controlla_vincoli», i vincoli li controlla comunque «scegli e spiega».
//
// Niente si cambia qui: «Metti la divisione nel taccuino» e «Segna il rinnovo» sono AzioneConferma (`azioni`) da
// mostrare nella scheda «Conferma».

// MARK: - Il catalogo (sola lettura)

/// Gli strumenti che il piano può usare: tutti di sola lettura, ognuno con il suo motore di Prisma.
enum StrumentoPasso: String, Codable, CaseIterable, Identifiable {
    case leggiProtezione = "leggi_protezione"
    case leggiObiettivo = "leggi_obiettivo"
    case simulaDivisioni = "simula_divisioni"
    case controllaVincoli = "controlla_vincoli"
    case scegliESpiega = "scegli_e_spiega"

    var id: String { rawValue }

    /// Il titolo del passo quando Qwen non ne dà uno valido.
    var titolo: String {
        switch self {
        case .leggiProtezione: return "Leggo la protezione della famiglia"
        case .leggiObiettivo: return "Guardo l'obiettivo"
        case .simulaDivisioni: return "Simulo tre divisioni"
        case .controllaVincoli: return "Controllo i vincoli"
        case .scegliESpiega: return "Scelgo e spiego"
        }
    }

    /// La descrizione che legge Qwen nel catalogo.
    var descrizione: String {
        switch self {
        case .leggiProtezione: return "legge quanto capitale caso morte serve alla famiglia e quanto ce n'è (solo se si parla di protezione)"
        case .leggiObiettivo: return "legge un obiettivo del cliente: importo, data, quanto c'è e quanto manca al mese (campo «obiettivo»: il titolo, vuoto per tutti)"
        case .simulaDivisioni: return "simula tre divisioni del budget con il simulatore di Prisma (protezione e obiettivi)"
        case .controllaVincoli: return "controlla scadenze e vincoli: polizze da rinnovare, obiettivi vicini, sostenibilità del budget"
        case .scegliESpiega: return "sceglie la divisione con la regola di Prisma e la spiega (sempre l'ultimo passo)"
        }
    }

    /// Il motore di Prisma che fa il lavoro (per la riga del piano, «Da Prisma: …»).
    var motore: String {
        switch self {
        case .leggiProtezione: return "Analisi 360 · protezione"
        case .leggiObiettivo: return "Obiettivi"
        case .simulaDivisioni: return "Simulatore di Prisma"
        case .controllaVincoli: return "Posizioni e scadenze"
        case .scegliESpiega: return "Regola di Prisma"
        }
    }

    /// Tutti di sola lettura: il ragionamento a passi non cambia niente.
    var soloLettura: Bool { true }
}

// MARK: - Modelli (entreranno nell'archivio)

/// L'interruttore «Mostra il ragionamento» (Impostazioni › Vera e la scheda della risposta). Letto con tolleranza.
struct ImpostazioniPassiVera: Codable, Equatable {
    /// Il piano resta visibile accanto alla risposta (spento: solo le divisioni e la spiegazione).
    var mostraRagionamento = true
    /// Il ragionamento a passi è acceso: spento, la richiesta va alla chat normale.
    var attivo = true

    init() {}

    private enum CodingKeys: String, CodingKey { case mostraRagionamento, attivo }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mostraRagionamento = (try? c.decodeIfPresent(Bool.self, forKey: .mostraRagionamento)) ?? true
        attivo = (try? c.decodeIfPresent(Bool.self, forKey: .attivo)) ?? true
    }
}

/// La richiesta capita dalle regole.
struct RichiestaPassi: Codable, Equatable {
    var testo: String
    var clienteId: String
    /// Il budget mensile da dividere, in euro.
    var budgetMensile: Double
    /// La richiesta parla di proteggere la famiglia.
    var protezione: Bool
    /// Gli obiettivi del cliente di cui si parla, in ordine di priorità.
    var obiettiviIds: [String]
    /// Chi va protetto, per i testi: «Elena», «la famiglia».
    var protetta: String
    /// Un capitale una tantum da dividere tra gli obiettivi («30.000 € da parte»), al posto del budget mensile (che resta 0).
    /// nil per le richieste di prima, che erano tutte mensili (letto con tolleranza: manca = mensile).
    var capitale: Double? = nil

    /// Il capitale una tantum, oppure il budget mensile.
    var totale: Double { capitale ?? budgetMensile }
    var unaTantum: Bool { capitale != nil }
    /// «400 € al mese» o «30.000 € una tantum».
    var dicitura: String { CifreDoc.euro(totale) + (unaTantum ? " una tantum" : " al mese") }
}

/// Com'è andata la lettura della richiesta.
enum CapitoPassi: Equatable {
    case richiesta(RichiestaPassi)
    /// Manca qualcosa: Vera lo chiede (non inventa il budget né l'obiettivo).
    case domanda(String)
}

/// Un passo del piano.
struct PassoPiano: Codable, Equatable, Identifiable {
    enum Stato: String, Codable { case daFare, fatto, saltato }
    /// La posizione nel piano, da 1.
    var id: Int
    var strumento: StrumentoPasso
    var titolo: String
    /// Per «leggi_obiettivo»: l'obiettivo da leggere (nil = tutti quelli della richiesta).
    var obiettivoId: String?
    var stato: Stato = .daFare
    /// Cosa ha trovato Prisma («Da Prisma: servono 620.000 €, oggi ce ne sono 150.000 €»).
    var esito: String = ""
}

/// Le tre divisioni del template.
enum TipoDivisione: String, Codable, CaseIterable {
    /// Più alla prima voce (la protezione o il primo obiettivo).
    case piuPrima
    case equilibrio
    /// Più agli obiettivi (o agli altri obiettivi).
    case piuSeconda
}

/// La quota di un obiettivo in una divisione, con il risultato del simulatore.
struct QuotaObiettivo: Codable, Equatable {
    var obiettivoId: String
    var titolo: String
    /// Il versamento mensile in più per l'obiettivo, in euro.
    var mensile: Double
    var scadenza: Date
    /// L'importo alla scadenza (rivalutato) e la proiezione con la quota.
    var importoScadenza: Double
    var proiezione: Double
    /// 0…1.
    var copertura: Double
    var inTempo: Bool
    /// Anni prima della scadenza in cui l'obiettivo è già raggiunto (0 = proprio alla scadenza).
    var anniAnticipo: Int = 0
    /// Anni dopo la scadenza (nil quando è in tempo o oltre 30 anni).
    var anniRitardo: Int?
    /// Quando si raggiunge (nil se oltre 30 anni dopo la scadenza).
    var raggiunto: Date?
}

/// Una divisione del budget, simulata con i motori di Prisma.
struct DivisioneBudget: Codable, Equatable, Identifiable {
    var tipo: TipoDivisione
    var id: String { tipo.rawValue }
    /// «Più protezione», «Equilibrio», «Più per Università di Anna».
    var titolo: String
    /// Il premio mensile in più per la protezione (0 senza protezione nella richiesta).
    var protezioneMensile: Double
    var quote: [QuotaObiettivo]
    /// Il capitale caso morte che il premio compra con la tariffa di Prisma (nil senza tariffa o senza protezione).
    var capitaleAggiunto: Double?
    /// La quota del fabbisogno coperta con il capitale in più (nil senza protezione nella richiesta).
    var coperturaProtezione: Double?
    var scopertoProtezione: Double?

    /// Tutti gli obiettivi della richiesta arrivano entro la loro data.
    var reggeObiettivi: Bool { quote.allSatisfy(\.inTempo) }
    /// La voce più scoperta (per la regola quando nessuna divisione regge).
    var minimo: Double {
        let voci = quote.map(\.copertura) + [coperturaProtezione].compactMap { $0 }
        return voci.min() ?? 1
    }
    var totaleObiettivi: Double { quote.reduce(0) { $0 + $1.mensile } }
}

/// Un vincolo o una scadenza trovati dal passo «controlla_vincoli».
struct VincoloPassi: Codable, Equatable {
    enum Tipo: String, Codable { case rinnovo, obiettivoVicino, sostenibilita, budgetCorto, senzaTariffa }
    var tipo: Tipo
    var testo: String
    var data: Date?
    var posizioneId: String?
}

/// Il piano con i passi, le divisioni e la spiegazione: quello che si vede nella risposta di Vera.
struct PianoPassi: Codable, Equatable, Identifiable {
    var id = "passi-\(UUID().uuidString.prefix(8).lowercased())"
    var richiesta: RichiestaPassi
    var passi: [PassoPiano]
    /// Il piano l'ha proposto Qwen (e ha passato il controllo); false = piano delle regole.
    var conQwen = false
    var creatoIl: Date
    var divisioni: [DivisioneBudget] = []
    var consigliata: TipoDivisione?
    /// La consigliata regge su tutti gli obiettivi (false = nessuna regge: è la meno scoperta).
    var regge = false
    var vincoli: [VincoloPassi] = []
    /// La spiegazione: la bozza di Prisma o il testo di Qwen controllato.
    var spiegazione = ""
    var spiegazioneConQwen = false

    var finito: Bool { !passi.contains { $0.stato == .daFare } }
    var divisioneConsigliata: DivisioneBudget? { divisioni.first { $0.tipo == consigliata } }

    init(richiesta: RichiestaPassi, passi: [PassoPiano], conQwen: Bool, creatoIl: Date) {
        self.richiesta = richiesta
        self.passi = passi
        self.conQwen = conQwen
        self.creatoIl = creatoIl
    }

    private enum CodingKeys: String, CodingKey {
        case id, richiesta, passi, conQwen, creatoIl, divisioni, consigliata, regge, vincoli, spiegazione, spiegazioneConQwen
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        richiesta = try c.decode(RichiestaPassi.self, forKey: .richiesta)
        passi = (try? c.decodeIfPresent([PassoPiano].self, forKey: .passi)) ?? []
        conQwen = (try? c.decodeIfPresent(Bool.self, forKey: .conQwen)) ?? false
        creatoIl = (try? c.decodeIfPresent(Date.self, forKey: .creatoIl)) ?? Date(timeIntervalSinceReferenceDate: 0)
        divisioni = (try? c.decodeIfPresent([DivisioneBudget].self, forKey: .divisioni)) ?? []
        consigliata = (try? c.decodeIfPresent(TipoDivisione.self, forKey: .consigliata)) ?? nil
        regge = (try? c.decodeIfPresent(Bool.self, forKey: .regge)) ?? false
        vincoli = (try? c.decodeIfPresent([VincoloPassi].self, forKey: .vincoli)) ?? []
        spiegazione = (try? c.decodeIfPresent(String.self, forKey: .spiegazione)) ?? ""
        spiegazioneConQwen = (try? c.decodeIfPresent(Bool.self, forKey: .spiegazioneConQwen)) ?? false
    }
}

/// I dati che servono ai passi, presi dall'archivio una volta sola (il motore non legge lo stato dell'app).
struct DatiPassi {
    var oggi: Date
    var cliente: Cliente
    /// Le posizioni del cliente.
    var posizioni: [Posizione]
    /// Tutte le posizioni dell'archivio: per la tariffa caso morte quando il cliente non ne ha.
    var archivio: [Posizione]
    /// Gli obiettivi del cliente.
    var obiettivi: [Obiettivo]
    /// Le ipotesi della protezione dell'Analisi 360 (salvata o prima stesura).
    var protezione: IpotesiProtezione
    var calendario = Calendar.current

    init(oggi: Date, cliente: Cliente, posizioni: [Posizione], archivio: [Posizione], obiettivi: [Obiettivo],
         protezione: IpotesiProtezione, calendario: Calendar = .current) {
        self.oggi = oggi
        self.cliente = cliente
        self.posizioni = posizioni
        self.archivio = archivio
        self.obiettivi = obiettivi
        self.protezione = protezione
        self.calendario = calendario
    }

    /// Dall'archivio: posizioni e obiettivi del cliente, l'Analisi 360 salvata o la sua prima stesura.
    static func da(_ d: DatiPrisma, clienteId: String, oggi: Date) -> DatiPassi? {
        guard let c = d.clienti.first(where: { $0.id == clienteId }) else { return nil }
        let mie = d.posizioni.filter { $0.clienteId == clienteId }
        let analisi = d.analisi[clienteId] ?? Analisi360(cliente: c, posizioni: mie)
        return DatiPassi(oggi: oggi, cliente: c, posizioni: mie, archivio: d.posizioni,
                         obiettivi: d.obiettivi.filter { $0.clienteId == clienteId }, protezione: analisi.protezione)
    }

    func obiettivo(_ id: String) -> Obiettivo? { obiettivi.first { $0.id == id } }
}

// MARK: - Il motore

enum PassiVera {
    static let massimoPassi = 5
    /// Le quote degli obiettivi nelle divisioni «più prima» ed «equilibrio» e «più seconda» (frazioni del budget).
    static let frazioni: [TipoDivisione: Double] = [.piuPrima: 0.3, .equilibrio: 0.5, .piuSeconda: 0.7]
    /// Le coperture caso morte si stimano a multipli di 5.000 € (per difetto: il premio basta).
    static let passoCapitale = 5_000.0
    /// Due coperture della protezione entro mezzo punto sono pari.
    static let tolleranza = 0.005
    /// Le scadenze delle polizze da rinnovare che contano (giorni).
    static let giorniRinnovo = 90

    /// La regola della scelta, scritta come la legge il consulente.
    static let regola = "Consiglio la divisione che regge su tutti gli obiettivi (ognuno raggiunto entro la sua data); se più di una regge, quella che protegge di più la famiglia; a parità, l'equilibrio. Se nessuna regge, quella che lascia meno indietro la voce più scoperta."

    // MARK: Riconoscimento

    /// Le famiglie di parole degli obiettivi: una parola della richiesta e una del titolo nella stessa famiglia.
    static let famiglie: [[String]] = [
        ["stud", "univers", "scuol", "laure", "istruz", "master", "college"],
        ["casa", "mutuo", "appartament", "immobil", "trasloc"],
        ["pension", "previd", "vecchiaia"],
        ["auto", "macchin"],
        ["matrimon", "nozze"],
        ["viagg", "vacanz"],
        ["riserva", "emergenz", "imprevist", "serenit"],
        ["negozio", "impresa", "aziend"],
    ]

    static func piega(_ s: String) -> String {
        s.lowercased().replacingOccurrences(of: "’", with: "'").folding(options: .diacriticInsensitive, locale: Locale(identifier: "it_IT"))
    }

    /// Le parole di un testo (piegate, senza punteggiatura).
    static func parole(_ s: String) -> [String] {
        piega(s).components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
    }

    static func famiglieIn(_ testo: String) -> Set<Int> {
        let p = parole(testo)
        var trovate = Set<Int>()
        for (i, radici) in famiglie.enumerated() where p.contains(where: { w in radici.contains { w.hasPrefix($0) } }) {
            trovate.insert(i)
        }
        return trovate
    }

    /// Il budget mensile della richiesta: «400 € al mese», «€ 400 al mese», «1.200 euro mensili».
    static func budget(_ testo: String) -> Double? {
        let t = piega(testo)
        let numero = #"(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?"#
        let mese = #"(?:al mese|ogni mese|mensili|mensilmente|a mese|il mese|al mese)"#
        let schemi = [numero + #"\s*(?:€|euro)\s*(?:da \w+\s+)?"# + mese, #"€\s*"# + numero + #"\s*"# + mese]
        for s in schemi {
            guard let trovato = DateItaliane.cerca(s, t), trovato.1.count >= 3 else { continue }
            let g = trovato.1
            let intero = g[1].replacingOccurrences(of: ".", with: "")
            let decimali = g[2].isEmpty ? "" : "." + g[2]
            if let v = Double(intero + decimali), v > 0 { return v }
        }
        return nil
    }

    static func parlaDiProtezione(_ testo: String) -> Bool {
        DateItaliane.cerca(#"\b(?:protegg\w*|proteg\w*|protezion\w*|tutel\w*|caso morte|assicurar\w*|se (?:gli|le|mi) succede)"#, piega(testo)) != nil
    }

    static func chiedeDivisione(_ testo: String) -> Bool {
        let t = piega(testo)
        if chiedePassi(t) { return true }
        if DateItaliane.cerca(#"\bcome (?:li|le|lo|la) (?:divido|dividiamo|divid\w*|ripart\w*|distribu\w*|uso|usiamo|impiego|investo|metto)\b|\bdivider\w*|\bdivision\w*|\bsuddivid\w*|\bripart\w*|\bdistribu\w*|\bcome conviene\b|\bpriorit\w*|\bsia .+ sia\b"#, t) != nil {
            return true
        }
        // Altre richieste complesse con la stessa forma: una scelta tra due voci («meglio la casa o gli studi?», «cosa
        // conviene prima», «su cosa punto», «a cosa do la precedenza», «dove li metto»)
        return DateItaliane.cerca(#"\bcosa conviene\b|\bsu cosa punt\w*|\ba cosa (?:do|diamo|dare|dovrei dare) (?:la )?precedenza\b|\bdove (?:li|le) (?:metto|mettiamo)\b|\bmeglio\b.{1,80}\bo\b"#, t) != nil
    }

    /// Un capitale una tantum da dividere: «30.000 € da parte», «20.000 euro da investire», «€ 15.000 di liquidità»,
    /// «50.000 € dal TFR». Solo con una di queste parole vicino alla cifra (una cifra qualsiasi non è un capitale).
    static func capitaleUnaTantum(_ testo: String) -> Double? {
        let t = piega(testo)
        let numero = #"(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?"#
        let quale = #"(?:da parte|messi da parte|da investire|da impiegare|di risparmi\w*|di liquidit\w*|una tantum|in un'unica soluzione|in banca|sul conto|di eredit\w*|dall'eredit\w*|di bonus|di tfr|dal tfr|accantonat\w*|dalla vendita|da una vendita|liquidat\w*)"#
        let schemi = [numero + #"\s*(?:€|euro)\s*(?:[a-z']+\s+){0,3}?"# + quale, #"€\s*"# + numero + #"\s*(?:[a-z']+\s+){0,3}?"# + quale]
        for s in schemi {
            guard let trovato = DateItaliane.cerca(s, t), trovato.1.count >= 3 else { continue }
            let g = trovato.1
            let intero = g[1].replacingOccurrences(of: ".", with: "")
            let decimali = g[2].isEmpty ? "" : "." + g[2]
            if let v = Double(intero + decimali), v > 0 { return v }
        }
        return nil
    }

    /// «Ragiona a passi», «passo per passo», «mostrami il ragionamento».
    static func chiedePassi(_ testo: String) -> Bool {
        DateItaliane.cerca(#"\bragion\w* (?:a|per) passi\b|\bpasso (?:per|dopo) passo\b|\bmostra(?:mi)? il ragionamento\b"#, piega(testo)) != nil
    }

    /// Merita il ragionamento a passi: un budget mensile da dividere tra almeno due voci (la protezione e un obiettivo,
    /// oppure due obiettivi). Solo regole, senza dati: lo smistamento lo chiede prima di tutto il resto.
    static func eUnaRichiesta(_ testo: String) -> Bool {
        guard budget(testo) != nil || capitaleUnaTantum(testo) != nil, chiedeDivisione(testo) else { return false }
        var voci = famiglieIn(testo).count
        if voci == 0, DateItaliane.cerca(#"\bobiettiv\w*"#, piega(testo)) != nil { voci = 1 }
        if parlaDiProtezione(testo) { voci += 1 }
        return voci >= 2
    }

    /// Il cliente nominato nella richiesta (nome o cognome), altrimenti quello aperto. Con più clienti nominati vale
    /// quello aperto se è tra questi; se no nil, e Vera chiede di quale cliente si parla (mai il primo dell'archivio).
    static func cliente(nel testo: String, clienti: [Cliente], attivo: String?) -> Cliente? {
        let p = Set(parole(testo))
        let nominati = clienti.filter { c in parole(c.nome).contains { $0.count >= 3 && p.contains($0) } }
        if nominati.count == 1 { return nominati[0] }
        if nominati.count > 1 {
            guard let attivo else { return nil }
            return nominati.first { $0.id == attivo }
        }
        guard let attivo else { return nil }
        return clienti.first { $0.id == attivo }
    }

    /// Gli obiettivi del cliente di cui parla la richiesta: stessa famiglia di parole, una parola lunga del titolo o il
    /// nome di un familiare presente nel titolo e nella richiesta.
    static func obiettiviNominati(_ testo: String, obiettivi: [Obiettivo], famiglia: [Familiare]) -> [Obiettivo] {
        let richiesta = Set(parole(testo))
        let famiglieRichiesta = famiglieIn(testo)
        let vuote: Set<String> = ["della", "delle", "degli", "dello", "per", "con", "anni", "obiettivo", "piano", "fondo", "futuro"]
        let nomi = Set(famiglia.compactMap { parole($0.nome).first })
        let trovati = obiettivi.filter { o in
            let titolo = parole(o.titolo)
            if !famiglieIn(o.titolo).isDisjoint(with: famiglieRichiesta) { return true }
            if titolo.contains(where: { $0.count >= 5 && !vuote.contains($0) && richiesta.contains($0) }) { return true }
            return titolo.contains { nomi.contains($0) && richiesta.contains($0) }
        }
        return trovati.sorted { ($0.priorita, $1.scadenza) > ($1.priorita, $0.scadenza) }
    }

    /// Chi va protetto: il familiare nominato (prima il coniuge o il convivente), altrimenti il coniuge, «la famiglia».
    static func protetta(_ testo: String, famiglia: [Familiare], obiettivi: [Obiettivo]) -> String {
        let richiesta = Set(parole(testo))
        let neiTitoli = Set(obiettivi.flatMap { parole($0.titolo) })
        func nome(_ f: Familiare) -> String { f.nome.split(separator: " ").first.map(String.init) ?? f.nome }
        let partner: Set<Familiare.Relazione> = [.coniuge, .convivente]
        let nominati = famiglia.filter { richiesta.contains(piega(nome($0))) && !neiTitoli.contains(piega(nome($0))) }
        if let f = nominati.first(where: { partner.contains($0.relazione) }) ?? nominati.first { return nome(f) }
        if let f = famiglia.first(where: { partner.contains($0.relazione) }) { return nome(f) }
        return "la famiglia"
    }

    /// Capisce la richiesta: budget, protezione, obiettivi. Se manca qualcosa, la domanda da fare.
    static func capisci(_ testo: String, cliente c: Cliente, obiettivi: [Obiettivo]) -> CapitoPassi {
        let primo = c.nome.split(separator: " ").first.map(String.init) ?? c.nome
        // Prima il budget mensile; senza, un capitale una tantum («30.000 € da parte»)
        let mensile = budget(testo)
        let capitale = mensile == nil ? capitaleUnaTantum(testo) : nil
        guard let b = mensile ?? capitale else { return .domanda("Quanto può mettere \(primo) ogni mese?") }
        // La protezione si paga con un premio periodico: con un capitale una tantum si divide solo tra gli obiettivi
        let protezione = capitale == nil && parlaDiProtezione(testo)
        var scelti = obiettiviNominati(testo, obiettivi: obiettivi, famiglia: c.famiglia)
        // «l'obiettivo» senza dire quale: va bene solo se ce n'è uno
        if scelti.isEmpty, obiettivi.count == 1, DateItaliane.cerca(#"\bobiettiv\w*"#, piega(testo)) != nil { scelti = obiettivi }
        if scelti.isEmpty {
            if obiettivi.isEmpty { return .domanda("\(primo) non ha obiettivi nel dossier: prima va creato l'obiettivo, poi divido il budget.") }
            let elenco = obiettivi.map { "«\($0.titolo)»" }.joined(separator: ", ")
            return .domanda("Per quale obiettivo? \(primo) ha \(elenco).")
        }
        if capitale != nil && scelti.count < 2 {
            if parlaDiProtezione(testo) {
                return .domanda("La protezione si paga con un premio ogni mese o ogni anno: i \(CifreDoc.euro(b)) una tantum li divido tra gli obiettivi. Quanto può mettere \(primo) ogni mese per la protezione?")
            }
            return .domanda("Tra quali obiettivi divido i \(CifreDoc.euro(b))? Dimmene almeno due.")
        }
        if !protezione && scelti.count < 2 {
            return .domanda("Tra cosa divido i \(CifreDoc.euro(b)) al mese? Dimmi se c'è anche la protezione o un altro obiettivo.")
        }
        // Al massimo tre obiettivi: il piano ha cinque passi e la scheda tre colonne
        let ids = Array(scelti.prefix(3)).map(\.id)
        return .richiesta(RichiestaPassi(testo: testo, clienteId: c.id, budgetMensile: mensile ?? 0, protezione: protezione, obiettiviIds: ids,
                                         protetta: protetta(testo, famiglia: c.famiglia, obiettivi: scelti), capitale: capitale))
    }

    // MARK: Il piano (regole o Qwen)

    /// Il piano delle regole: letture, simulazione, vincoli, scelta (al massimo cinque passi).
    static func pianoConRegole(_ r: RichiestaPassi, dati: DatiPassi) -> [PassoPiano] {
        var strumenti: [(StrumentoPasso, String?)] = []
        if r.protezione { strumenti.append((.leggiProtezione, nil)) }
        // Un obiettivo solo ha il suo titolo; più obiettivi si leggono in un passo
        strumenti.append((.leggiObiettivo, r.obiettiviIds.count == 1 ? r.obiettiviIds[0] : nil))
        strumenti.append((.simulaDivisioni, nil))
        strumenti.append((.controllaVincoli, nil))
        strumenti.append((.scegliESpiega, nil))
        return strumenti.prefix(massimoPassi).enumerated().map { i, s in
            PassoPiano(id: i + 1, strumento: s.0, titolo: titoloPredefinito(s.0, obiettivoId: s.1, r, dati), obiettivoId: s.1)
        }
    }

    static func titoloPredefinito(_ s: StrumentoPasso, obiettivoId: String?, _ r: RichiestaPassi, _ dati: DatiPassi) -> String {
        switch s {
        case .leggiObiettivo:
            if let id = obiettivoId ?? (r.obiettiviIds.count == 1 ? r.obiettiviIds.first : nil), let o = dati.obiettivo(id) {
                return "Guardo l'obiettivo «\(o.titolo)»"
            }
            return "Guardo gli obiettivi"
        case .simulaDivisioni:
            return "Simulo tre divisioni dei \(CifreDoc.euro(r.totale))"
        default:
            return s.titolo
        }
    }

    static let schemaPiano: [String: Any] = {
        let passo: [String: Any] = ["type": "object", "required": ["strumento", "titolo"],
                                    "properties": ["strumento": ["type": "string", "enum": StrumentoPasso.allCases.map(\.rawValue)],
                                                   "titolo": ["type": "string"], "obiettivo": ["type": "string"]] as [String: Any]]
        return ["type": "object", "required": ["passi"],
                "properties": ["passi": ["type": "array", "minItems": 1, "maxItems": massimoPassi, "items": passo] as [String: Any]]]
    }()

    static var istruzioniPiano: String {
        IstruzioniVera.testo("passi") ?? "Prepara il piano per la richiesta del consulente scegliendo solo questi strumenti: leggi_protezione, leggi_obiettivo, simula_divisioni, controlla_vincoli, scegli_e_spiega. Al massimo cinque passi, prima le letture, poi simula_divisioni, scegli_e_spiega per ultimo; titoli brevi in prima persona, senza cifre. Rispondi solo con il JSON: {\"passi\": [{\"strumento\", \"titolo\", \"obiettivo\"}]}."
    }

    /// Il catalogo come lo legge Qwen.
    static var catalogo: String {
        StrumentoPasso.allCases.map { "- \($0.rawValue): \($0.descrizione)" }.joined(separator: "\n")
    }

    static func messaggiPiano(_ r: RichiestaPassi, dati: DatiPassi) -> [MessaggioModello] {
        let obiettivi = r.obiettiviIds.compactMap { dati.obiettivo($0) }.map { "«\($0.titolo)»" }.joined(separator: ", ")
        let utente = """
        RICHIESTA: \(r.testo)
        CLIENTE: \(dati.cliente.nome)
        BUDGET: \(r.dicitura)
        PROTEZIONE: \(r.protezione ? "sì, per \(r.protetta)" : "no")
        OBIETTIVI DELLA RICHIESTA: \(obiettivi)
        STRUMENTI
        \(catalogo)
        """
        return [MessaggioModello(ruolo: .sistema, testo: istruzioniPiano), MessaggioModello(ruolo: .utente, testo: utente)]
    }

    static func opzioniPiano(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.contesto = NucleoVera.finestra
        o.massimoToken = 400
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schemaPiano
        o.conLezioni = false
        return o
    }

    /// Il piano di Qwen, se passa il controllo: JSON valido, da 1 a 5 passi, solo strumenti del catalogo, letture prima
    /// della simulazione, «scegli_e_spiega» per ultimo (aggiunto se manca e c'è posto), l'obiettivo tra quelli della
    /// richiesta, titoli senza cifre (altrimenti quello di Prisma). nil = si usa il piano delle regole.
    static func leggiPiano(_ json: String, richiesta r: RichiestaPassi, dati: DatiPassi) -> [PassoPiano]? {
        guard let i = json.firstIndex(of: "{"), let fine = json.lastIndex(of: "}"), i < fine,
              let d = String(json[i...fine]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let elenco = j["passi"] as? [[String: Any]], !elenco.isEmpty, elenco.count <= massimoPassi else { return nil }
        var letti: [(StrumentoPasso, String?, String)] = []
        for v in elenco {
            guard let nome = v["strumento"] as? String, let s = StrumentoPasso(rawValue: nome.trimmingCharacters(in: .whitespaces)) else { return nil }
            var obiettivoId: String?
            if s == .leggiObiettivo, let testo = (v["obiettivo"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !testo.isEmpty {
                guard let id = obiettivo(testo, tra: r.obiettiviIds, dati: dati) else { return nil }
                obiettivoId = id
            }
            // La protezione letta senza che la richiesta ne parli non serve: il passo si toglie
            if s == .leggiProtezione && !r.protezione { continue }
            // Doppioni: uno per strumento (gli obiettivi uno per obiettivo)
            if letti.contains(where: { $0.0 == s && (s != .leggiObiettivo || $0.1 == obiettivoId) }) { continue }
            letti.append((s, obiettivoId, ((v["titolo"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        // L'ultimo è sempre «scegli e spiega»: se manca si aggiunge (se c'è posto), se sta in mezzo il piano non vale
        if let k = letti.firstIndex(where: { $0.0 == .scegliESpiega }), k != letti.count - 1 { return nil }
        if letti.last?.0 != .scegliESpiega {
            guard letti.count < massimoPassi else { return nil }
            letti.append((.scegliESpiega, nil, ""))
        }
        // La simulazione c'è e viene dopo tutte le letture
        guard let sim = letti.firstIndex(where: { $0.0 == .simulaDivisioni }) else { return nil }
        if letti.enumerated().contains(where: { ($0.element.0 == .leggiProtezione || $0.element.0 == .leggiObiettivo) && $0.offset > sim }) { return nil }
        return letti.enumerated().map { k, x in
            let titolo = titoloValido(x.2) ? x.2 : titoloPredefinito(x.0, obiettivoId: x.1, r, dati)
            return PassoPiano(id: k + 1, strumento: x.0, titolo: titolo, obiettivoId: x.1)
        }
    }

    /// Un titolo di Qwen vale se è breve e senza cifre (le cifre le mette Prisma nell'esito del passo).
    static func titoloValido(_ t: String) -> Bool {
        !t.isEmpty && t.count <= 70 && t.rangeOfCharacter(from: .decimalDigits) == nil && !t.contains("€")
    }

    /// L'obiettivo nominato da Qwen tra quelli della richiesta (per id o titolo).
    static func obiettivo(_ testo: String, tra ids: [String], dati: DatiPassi) -> String? {
        let t = piega(testo).replacingOccurrences(of: "«", with: "").replacingOccurrences(of: "»", with: "").trimmingCharacters(in: .whitespaces)
        for id in ids {
            guard let o = dati.obiettivo(id) else { continue }
            let titolo = piega(o.titolo)
            if t == piega(id) || t == titolo || (t.count >= 4 && (titolo.contains(t) || t.contains(titolo))) { return id }
        }
        return nil
    }

    /// Il piano pronto da eseguire: quello di Qwen se valido, altrimenti quello delle regole.
    static func piano(_ r: RichiestaPassi, dati: DatiPassi, passiQwen: [PassoPiano]? = nil) -> PianoPassi {
        if let q = passiQwen, !q.isEmpty, q.count <= massimoPassi {
            return PianoPassi(richiesta: r, passi: q, conQwen: true, creatoIl: dati.oggi)
        }
        return PianoPassi(richiesta: r, passi: pianoConRegole(r, dati: dati), conQwen: false, creatoIl: dati.oggi)
    }

    // MARK: L'esecuzione, un passo alla volta

    /// Esegue il prossimo passo da fare; false quando il piano è finito.
    @discardableResult
    static func eseguiPasso(_ piano: inout PianoPassi, dati: DatiPassi) -> Bool {
        guard let k = piano.passi.firstIndex(where: { $0.stato == .daFare }) else { return false }
        let passo = piano.passi[k]
        switch passo.strumento {
        case .leggiProtezione:
            piano.passi[k].esito = esitoProtezione(dati)
        case .leggiObiettivo:
            let ids = passo.obiettivoId.map { [$0] } ?? piano.richiesta.obiettiviIds
            piano.passi[k].esito = ids.compactMap { dati.obiettivo($0) }.map { esitoObiettivo($0, dati, unaTantum: piano.richiesta.unaTantum) }.joined(separator: " · ")
        case .simulaDivisioni:
            piano.divisioni = divisioni(piano.richiesta, dati: dati)
            piano.passi[k].esito = esitoSimulazione(piano)
        case .controllaVincoli:
            piano.vincoli = vincoli(piano.richiesta, dati: dati)
            piano.passi[k].esito = piano.vincoli.isEmpty ? "Nessuna scadenza né vincolo nei prossimi \(giorniRinnovo) giorni"
                : piano.vincoli.map(\.testo).joined(separator: "; ")
        case .scegliESpiega:
            // Senza simulazione (piano di Qwen che l'ha messa dopo: non succede, il controllo la vuole prima) si simula qui
            if piano.divisioni.isEmpty { piano.divisioni = divisioni(piano.richiesta, dati: dati) }
            // Un piano di Qwen senza «controlla_vincoli» non deve nascondere rinnovi e vincoli: si controllano qui
            if !piano.passi.contains(where: { $0.strumento == .controllaVincoli }) { piano.vincoli = vincoli(piano.richiesta, dati: dati) }
            let scelta = scegli(piano.divisioni)
            piano.consigliata = scelta?.tipo
            piano.regge = scelta?.reggeObiettivi ?? false
            piano.spiegazione = bozzaSpiegazione(piano, dati: dati)
            piano.spiegazioneConQwen = false
            if let s = scelta {
                piano.passi[k].esito = s.reggeObiettivi ? "\(s.titolo): la divisione che regge su tutti gli obiettivi"
                    : "\(s.titolo): nessuna divisione regge su tutto, è quella che lascia meno indietro"
            } else {
                piano.passi[k].esito = "Nessuna divisione da scegliere"
            }
        }
        piano.passi[k].stato = .fatto
        return piano.passi.contains { $0.stato == .daFare }
    }

    /// Tutti i passi, uno dopo l'altro (le prove e le istantanee; la vista li anima uno alla volta con `eseguiPasso`).
    static func eseguiTutto(_ piano: PianoPassi, dati: DatiPassi) -> PianoPassi {
        var p = piano
        var giri = 0
        while eseguiPasso(&p, dati: dati), giri < massimoPassi { giri += 1 }
        return p
    }

    // MARK: Le letture

    static func tariffa(_ dati: DatiPassi) -> MotoreSimulatoriAnalisi.TariffaCasoMorte? {
        MotoreSimulatoriAnalisi.tariffaCasoMorte(cliente: dati.posizioni, archivio: dati.archivio)
    }

    /// Il premio mensile che colma il divario caso morte con la tariffa (per eccesso, a 10 €); nil senza tariffa o divario.
    static func premioPerColmare(_ dati: DatiPassi) -> Double? {
        let e = MotoreAnalisi.protezione(dati.protezione, posizioni: dati.posizioni)
        guard e.divario >= 1, let t = tariffa(dati), t.perMille > 0 else { return nil }
        return (e.divario * t.perMille / 1_000 / 12 / 10).rounded(.up) * 10
    }

    static func esitoProtezione(_ dati: DatiPassi) -> String {
        let e = MotoreAnalisi.protezione(dati.protezione, posizioni: dati.posizioni)
        guard e.fabbisogno >= 1 else { return "Da Prisma: con queste ipotesi alla famiglia non serve capitale caso morte" }
        var testo = "Da Prisma: servono \(CifreDoc.euro(e.fabbisogno)), oggi ce ne sono \(CifreDoc.euro(e.capitaleVita))"
        if let premio = premioPerColmare(dati) {
            testo += "; per colmare il resto servono circa \(CifreDoc.euro(premio)) al mese"
        } else if e.divario >= 1 {
            testo += "; senza una tariffa in archivio il premio va chiesto in preventivo"
        }
        return testo
    }

    /// Il versamento mensile in più che porta l'obiettivo in tempo (per eccesso, a 10 €; 0 se è già raggiunto).
    static func bisogno(_ o: Obiettivo, _ dati: DatiPassi) -> Double {
        let e = MotoreObiettivo.calcola(o, posizioni: dati.posizioni, data: dati.oggi)
        guard e.mancante > 0.5 else { return 0 }
        guard let v = e.versamentoNecessario else { return .infinity }
        return (v / 10).rounded(.up) * 10
    }

    /// Il capitale da aggiungere oggi che porta l'obiettivo in tempo (per eccesso, a 100 €; 0 se è già raggiunto; infinito
    /// se nemmeno il doppio dell'importo basta). Lo stesso calcolo del dettaglio dell'obiettivo, con l'accantonato aumentato.
    static func bisognoCapitale(_ o: Obiettivo, _ dati: DatiPassi) -> Double {
        func basta(_ c: Double) -> Bool {
            var x = o
            x.accantonato += c
            return MotoreObiettivo.calcola(x, posizioni: dati.posizioni, data: dati.oggi).mancante <= 0.5
        }
        guard !basta(0) else { return 0 }
        var basso = 0.0
        var alto = max(o.importo, 1) * 2
        guard basta(alto) else { return .infinity }
        for _ in 0..<40 {
            let m = (basso + alto) / 2
            if basta(m) { alto = m } else { basso = m }
        }
        return (alto / 100).rounded(.up) * 100
    }

    static func esitoObiettivo(_ o: Obiettivo, _ dati: DatiPassi, unaTantum: Bool = false) -> String {
        let e = MotoreObiettivo.calcola(o, posizioni: dati.posizioni, data: dati.oggi)
        var testo = "«\(o.titolo)»: \(CifreDoc.euro(o.importo)) per \(Formati.meseAnno.string(from: o.scadenza)), oggi \(CifreDoc.euro(e.disponibileOggi))"
        let b = unaTantum ? bisognoCapitale(o, dati) : bisogno(o, dati)
        if b == 0 {
            testo += ", già in tempo"
        } else if b.isFinite {
            testo += unaTantum ? ", servono \(CifreDoc.euro(b)) in più oggi" : ", servono \(CifreDoc.euro(b)) al mese in più"
        } else {
            testo += ", la data è troppo vicina"
        }
        return testo
    }

    // MARK: La simulazione

    private static func arrotonda10(_ v: Double) -> Double { (v / 10).rounded() * 10 }
    /// Un capitale si divide a 100 €, un budget mensile a 10 €.
    private static func arrotonda(_ v: Double, _ r: RichiestaPassi) -> Double { r.unaTantum ? (v / 100).rounded() * 100 : arrotonda10(v) }

    /// Le tre divisioni del budget, ognuna simulata con i motori di Prisma. La «seconda» voce sono gli obiettivi (con
    /// la protezione nella richiesta) o gli obiettivi dopo il primo (senza). L'equilibrio dà alla seconda voce quanto
    /// basta per arrivare in tempo, se sta tra le altre due divisioni; altrimenti metà budget.
    static func divisioni(_ r: RichiestaPassi, dati: DatiPassi) -> [DivisioneBudget] {
        let obiettivi = r.obiettiviIds.compactMap { dati.obiettivo($0) }
        guard r.totale > 0, !obiettivi.isEmpty, r.protezione || obiettivi.count >= 2 else { return [] }
        let b = r.totale
        let prima: Obiettivo? = r.protezione ? nil : obiettivi[0]
        let seconda = r.protezione ? obiettivi : Array(obiettivi.dropFirst())
        let bisogni = Dictionary(obiettivi.map { ($0.id, r.unaTantum ? bisognoCapitale($0, dati) : bisogno($0, dati)) }, uniquingKeysWith: { a, _ in a })
        let bisognoSeconda = seconda.reduce(0.0) { $0 + (bisogni[$1.id] ?? 0) }

        let basso = arrotonda(b * (frazioni[.piuPrima] ?? 0.3), r)
        let alto = arrotonda(b * (frazioni[.piuSeconda] ?? 0.7), r)
        let equilibrio = (bisognoSeconda > basso && bisognoSeconda < alto) ? bisognoSeconda : arrotonda(b * (frazioni[.equilibrio] ?? 0.5), r)
        let quoteSeconda: [TipoDivisione: Double] = [.piuPrima: basso, .equilibrio: equilibrio, .piuSeconda: alto]

        let esito = MotoreAnalisi.protezione(dati.protezione, posizioni: dati.posizioni)
        let t = tariffa(dati)
        let nomePrima = prima.map { "Più per «\($0.titolo)»" } ?? "Più protezione"
        let nomeSeconda = seconda.count == 1 ? "Più per «\(seconda[0].titolo)»" : "Più obiettivi"

        return TipoDivisione.allCases.map { tipo -> DivisioneBudget in
            let s = min(b, max(0, quoteSeconda[tipo] ?? 0))
            let restoPrima = b - s
            // La quota della seconda voce si divide tra i suoi obiettivi secondo quanto manca a ciascuno (in parti
            // uguali se non manca niente), all'euro; l'ultimo prende il resto
            var perObiettivo: [String: Double] = [:]
            let pesi = seconda.map { o -> Double in
                let v = bisogni[o.id] ?? 0
                return v.isFinite ? v : b
            }
            let totalePesi = pesi.reduce(0, +)
            var assegnato = 0.0
            for (k, o) in seconda.enumerated() {
                let quota: Double
                if k == seconda.count - 1 {
                    quota = s - assegnato
                } else {
                    quota = (totalePesi > 0 ? s * pesi[k] / totalePesi : s / Double(seconda.count)).rounded()
                }
                perObiettivo[o.id] = quota
                assegnato += quota
            }
            if let prima { perObiettivo[prima.id] = restoPrima }
            let quote = obiettivi.map { quotaObiettivo($0, mensile: perObiettivo[$0.id] ?? 0, dati, unaTantum: r.unaTantum) }

            var capitale: Double?
            var copertura: Double?
            var scoperto: Double?
            let premio = r.protezione ? restoPrima : 0
            if r.protezione {
                if let t, t.perMille > 0 {
                    // Un margine minimo contro gli errori di arrotondamento (1.440 € / 3,6 ‰ = 400.000 €, non 395.000 €)
                    let c = (premio * 12 * 1_000 / t.perMille / passoCapitale + 1e-6).rounded(.down) * passoCapitale
                    capitale = c
                    let passo = MotoreSimulatoriAnalisi.protezione(esito, aggiunta: c, tariffa: t)
                    copertura = passo.copertura
                    scoperto = passo.scoperto
                } else {
                    // Senza tariffa il capitale non si stima: la copertura resta quella di oggi
                    let passo = MotoreSimulatoriAnalisi.protezione(esito, aggiunta: 0, tariffa: nil)
                    copertura = passo.copertura
                    scoperto = passo.scoperto
                }
            }
            let titolo: String
            switch tipo {
            case .piuPrima: titolo = nomePrima
            case .equilibrio: titolo = "Equilibrio"
            case .piuSeconda: titolo = nomeSeconda
            }
            return DivisioneBudget(tipo: tipo, titolo: titolo, protezioneMensile: premio, quote: quote,
                                   capitaleAggiunto: capitale, coperturaProtezione: copertura, scopertoProtezione: scoperto)
        }
    }

    /// Un obiettivo con `mensile` € in più al mese: lo stesso calcolo del dettaglio dell'obiettivo (MotoreObiettivo, con
    /// il versamento previsto aumentato). In tempo: quanti anni prima si arriva; in ritardo: quanti anni dopo.
    static func quotaObiettivo(_ o: Obiettivo, mensile: Double, _ dati: DatiPassi, unaTantum: Bool = false) -> QuotaObiettivo {
        var conQuota = o
        // Un capitale una tantum entra oggi nell'accantonato; un budget mensile nel versamento previsto
        if unaTantum { conQuota.accantonato += max(0, mensile) } else { conQuota.versamentoMensile += max(0, mensile) }
        let e = MotoreObiettivo.calcola(conQuota, posizioni: dati.posizioni, data: dati.oggi)
        let inTempo = e.mancante <= 0.5
        let cal = dati.calendario
        var anticipo = 0
        var ritardo: Int?
        var raggiunto: Date? = o.scadenza
        if inTempo {
            // Un anno prima alla volta, finché basta (al massimo dieci, e mai prima di un mese da oggi)
            let limite = cal.date(byAdding: .month, value: 1, to: dati.oggi) ?? dati.oggi
            for k in 1...10 {
                guard let prima = cal.date(byAdding: .year, value: -k, to: o.scadenza), prima > limite else { break }
                var x = conQuota
                x.scadenza = prima
                guard MotoreObiettivo.calcola(x, posizioni: dati.posizioni, data: dati.oggi).mancante <= 0.5 else { break }
                anticipo = k
            }
            raggiunto = cal.date(byAdding: .year, value: -anticipo, to: o.scadenza)
        } else {
            ritardo = e.rinvio
            raggiunto = e.rinvio.flatMap { cal.date(byAdding: .year, value: $0, to: o.scadenza) }
        }
        return QuotaObiettivo(obiettivoId: o.id, titolo: o.titolo, mensile: max(0, mensile), scadenza: o.scadenza,
                              importoScadenza: e.importoScadenza, proiezione: e.proiezione, copertura: e.copertura,
                              inTempo: inTempo, anniAnticipo: anticipo, anniRitardo: ritardo, raggiunto: raggiunto)
    }

    static func esitoSimulazione(_ piano: PianoPassi) -> String {
        guard !piano.divisioni.isEmpty else { return "Nessuna divisione da simulare" }
        return "Con il simulatore di Prisma: " + piano.divisioni.map { "\($0.titolo) (\(ripartizione($0, piano.richiesta)))" }.joined(separator: ", ")
    }

    /// «200 € alla protezione e 200 € a «Università di Anna»».
    static func ripartizione(_ d: DivisioneBudget, _ r: RichiestaPassi) -> String {
        var parti: [String] = []
        if r.protezione { parti.append("\(CifreDoc.euro(d.protezioneMensile)) alla protezione") }
        parti += d.quote.map { "\(CifreDoc.euro($0.mensile)) a «\($0.titolo)»" }
        if parti.count <= 1 { return parti.first ?? "" }
        return parti.dropLast().joined(separator: ", ") + " e " + (parti.last ?? "")
    }

    // MARK: I vincoli

    static func vincoli(_ r: RichiestaPassi, dati: DatiPassi) -> [VincoloPassi] {
        let cal = dati.calendario
        let inizio = cal.startOfDay(for: dati.oggi)
        let limite = cal.date(byAdding: .day, value: giorniRinnovo, to: inizio) ?? inizio
        var elenco: [VincoloPassi] = []
        // Le polizze di protezione da rinnovare presto: si decide dopo averle viste
        let daRinnovare = dati.posizioni.filter { p in
            guard p.area == .protezione, p.stato == .inEssere, let s = p.scadenza else { return false }
            return s >= inizio && s <= limite
        }.sorted { ($0.scadenza ?? inizio) < ($1.scadenza ?? inizio) }
        for p in daRinnovare {
            guard let s = p.scadenza else { continue }
            elenco.append(VincoloPassi(tipo: .rinnovo, testo: "\(p.nome) da rinnovare entro il \(Formati.giornoMese.string(from: s))",
                                       data: s, posizioneId: p.id))
        }
        let obiettivi = r.obiettiviIds.compactMap { dati.obiettivo($0) }
        let unAnno = cal.date(byAdding: .year, value: 1, to: inizio) ?? inizio
        for o in obiettivi where o.scadenza <= unAnno {
            elenco.append(VincoloPassi(tipo: .obiettivoVicino, testo: "«\(o.titolo)» scade entro un anno: i versamenti mensili contano poco", data: o.scadenza))
        }
        let bisogni = obiettivi.map { r.unaTantum ? bisognoCapitale($0, dati) : bisogno($0, dati) }
        let totale = bisogni.reduce(0, +)
        if totale.isFinite, totale > r.totale {
            elenco.append(VincoloPassi(tipo: .budgetCorto, testo: "Da soli gli obiettivi chiederebbero \(CifreDoc.euro(totale))\(r.unaTantum ? " oggi" : " al mese"), più dei \(CifreDoc.euro(r.totale)) disponibili"))
        }
        if !r.unaTantum, let netto = dati.cliente.profilo.redditoNettoAnnuo, netto > 0, r.budgetMensile * 12 > netto / 4 {
            elenco.append(VincoloPassi(tipo: .sostenibilita, testo: "I \(CifreDoc.euro(r.budgetMensile)) al mese sono più di un quarto del reddito netto: va verificato che restino sostenibili"))
        }
        if r.protezione, tariffa(dati) == nil {
            elenco.append(VincoloPassi(tipo: .senzaTariffa, testo: "Nessuna copertura caso morte con capitale e premio in archivio: il capitale della protezione va stimato con un preventivo"))
        }
        return elenco
    }

    // MARK: La scelta (regola trasparente)

    /// La divisione consigliata secondo `regola`.
    static func scegli(_ divisioni: [DivisioneBudget]) -> DivisioneBudget? {
        guard !divisioni.isEmpty else { return nil }
        func preferisci(_ candidati: [DivisioneBudget], _ valore: (DivisioneBudget) -> Double) -> DivisioneBudget? {
            guard let migliore = candidati.map(valore).max() else { return nil }
            let pari = candidati.filter { valore($0) >= migliore - tolleranza }
            return pari.first { $0.tipo == .equilibrio } ?? pari.first
        }
        let reggono = divisioni.filter(\.reggeObiettivi)
        if !reggono.isEmpty { return preferisci(reggono) { $0.coperturaProtezione ?? 0 } }
        return preferisci(divisioni) { $0.minimo }
    }

    // MARK: La spiegazione

    static func percento(_ v: Double) -> String { "\(Int((max(0, min(1, v)) * 100).rounded(.down)))%" }

    /// Cosa succede alla protezione in una divisione, per i testi.
    static func testoProtezione(_ d: DivisioneBudget, _ r: RichiestaPassi) -> String? {
        guard r.protezione else { return nil }
        let chi = r.protetta == "la famiglia" ? "la famiglia" : r.protetta
        guard d.protezioneMensile > 0 else { return "nessun premio in più per proteggere \(chi)" }
        guard let c = d.capitaleAggiunto else {
            return "\(CifreDoc.euro(d.protezioneMensile)) al mese di premio per proteggere \(chi), con il capitale da chiedere in preventivo"
        }
        return "+\(CifreDoc.euro(c)) di protezione per \(chi) (\(percento(d.coperturaProtezione ?? 0)) del fabbisogno)"
    }

    /// Quando arriva un obiettivo con la sua quota, per i testi.
    static func testoObiettivo(_ q: QuotaObiettivo) -> String {
        if q.inTempo {
            if q.anniAnticipo > 0, let d = q.raggiunto {
                return "«\(q.titolo)» raggiunto a \(Formati.meseAnno.string(from: d)), \(q.anniAnticipo == 1 ? "un anno" : "\(q.anniAnticipo) anni") prima"
            }
            return "«\(q.titolo)» raggiunto in tempo per \(Formati.meseAnno.string(from: q.scadenza))"
        }
        if let d = q.raggiunto { return "«\(q.titolo)» raggiunto solo a \(Formati.meseAnno.string(from: d))" }
        return "«\(q.titolo)» non raggiunto nemmeno con trent'anni in più"
    }

    /// Il riepilogo delle tre divisioni (le cifre che Qwen può usare).
    static func riepilogo(_ piano: PianoPassi) -> String {
        piano.divisioni.map { d -> String in
            var righe = ["\(d.titolo): \(ripartizione(d, piano.richiesta))"]
            if let p = testoProtezione(d, piano.richiesta) { righe.append(p) }
            righe += d.quote.map(testoObiettivo)
            return righe.joined(separator: "; ")
        }.joined(separator: "\n")
    }

    /// La spiegazione di Prisma (sempre disponibile, cifre esatte): la scelta, il perché e il primo vincolo.
    static func bozzaSpiegazione(_ piano: PianoPassi, dati: DatiPassi) -> String {
        guard let d = piano.divisioneConsigliata else {
            return "Non riesco a dividere i \(piano.richiesta.dicitura): mancano gli obiettivi o il budget."
        }
        let r = piano.richiesta
        let reggono = piano.divisioni.filter(\.reggeObiettivi).count
        let nomi = d.quote.map { "«\($0.titolo)»" }
        let obiettivi = nomi.count <= 1 ? (nomi.first ?? "") : nomi.dropLast().joined(separator: ", ") + " e " + (nomi.last ?? "")
        let date = d.quote.map { Formati.meseAnno.string(from: $0.scadenza) }
        let quando = Array(Set(date)).count == 1 ? "per \(date[0])" : "entro le loro date"
        var testo = "Ti consiglio «\(d.titolo)» (\(ripartizione(d, r))). "
        let protezione = testoProtezione(d, r)
        let quante = reggono == 2 ? "due" : "tre"
        if piano.regge {
            if reggono == 1 {
                testo += "È l'unica divisione che porta \(obiettivi) in tempo \(quando)"
            } else if r.protezione {
                testo += "Delle \(quante) divisioni che portano \(obiettivi) in tempo \(quando) è quella che protegge di più"
            } else {
                testo += "Tutte e \(quante) le divisioni portano \(obiettivi) in tempo \(quando): scelgo l'equilibrio"
            }
            if let protezione { testo += ", con \(protezione)" }
            testo += "."
        } else {
            testo += "Nessuna divisione dei \(CifreDoc.euro(r.totale)) porta tutti gli obiettivi in tempo: questa è quella che lascia meno indietro. "
            testo += (d.quote.map(testoObiettivo) + [protezione].compactMap { $0 }).joined(separator: "; ") + "."
        }
        if let v = piano.vincoli.first { testo += " Prima, però: \(minuscolaIniziale(v.testo))." }
        return testo
    }

    private static func minuscolaIniziale(_ s: String) -> String {
        // I nomi delle polizze («Infortuni famiglia») restano con la maiuscola: si abbassa solo «Da», «I», «Nessuna»
        guard let primo = s.split(separator: " ").first, ["Da", "I", "Nessuna"].contains(String(primo)) else { return s }
        return s.prefix(1).lowercased() + String(s.dropFirst())
    }

    static let schemaSpiegazione: [String: Any] = [
        "type": "object", "required": ["spiegazione"], "properties": ["spiegazione": ["type": "string"]],
    ]

    static var istruzioniSpiegazione: String {
        IstruzioniVera.testo("passi-spiega") ?? "Spiega al consulente la divisione scelta da Prisma, chiamandola con il suo nome, senza cambiarla. Usa solo le cifre della bozza e del riepilogo, come sono scritte. Se c'è una scadenza, dilla alla fine. Dai del tu, al massimo 90 parole. Rispondi solo con il JSON: {\"spiegazione\": \"...\"}."
    }

    static func messaggiSpiegazione(_ piano: PianoPassi) -> [MessaggioModello] {
        let utente = """
        RICHIESTA: \(piano.richiesta.testo)
        REGOLA DI PRISMA: \(regola)
        DIVISIONE SCELTA DA PRISMA: \(piano.divisioneConsigliata?.titolo ?? "")
        RIEPILOGO DELLE DIVISIONI
        \(riepilogo(piano))
        BOZZA DI PRISMA (cifre esatte: non cambiarle e non aggiungerne)
        \(piano.spiegazione)
        """
        return [MessaggioModello(ruolo: .sistema, testo: istruzioniSpiegazione), MessaggioModello(ruolo: .utente, testo: utente)]
    }

    static func opzioniSpiegazione(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.3
        o.contesto = NucleoVera.finestra
        o.massimoToken = 400
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schemaSpiegazione
        return o
    }

    /// La spiegazione di Qwen, se passa il controllo: un oggetto JSON con «spiegazione» (la prosa o un JSON rotto non
    /// valgono), non vuota, al massimo 900 caratteri, nomina la divisione scelta da Prisma e non ne consiglia un'altra,
    /// cifre solo dalla bozza e dal riepilogo, nessuna cifra in lettere (salvo le parole fisse della bozza). nil = resta la bozza.
    static func leggiSpiegazione(_ json: String, piano: PianoPassi) -> String? {
        guard let d = piano.divisioneConsigliata,
              let i = json.firstIndex(of: "{"), let fine = json.lastIndex(of: "}"), i < fine,
              let dati = String(json[i...fine]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: dati)) as? [String: Any],
              let s = j["spiegazione"] as? String else { return nil }
        let testo = s.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testo.isEmpty, testo.count <= 900 else { return nil }
        guard consigliaSolo(d, tra: piano.divisioni, testo: testo) else { return nil }
        let bozza = piano.spiegazione + "\n" + riepilogo(piano)
        guard CommentoVera.numeriConservati(bozza: bozza, testo: testo) else { return nil }
        guard !cifreInLettere(testo, piano: piano) else { return nil }
        return testo
    }

    /// true se il testo ha cifre in lettere. Le parole fisse della bozza («delle due divisioni», «tutte e tre») e i
    /// titoli delle divisioni e degli obiettivi non contano; ogni altro numerale in lettere sì, anche uno che la bozza
    /// usa con un altro significato («tra due anni»).
    static func cifreInLettere(_ testo: String, piano: PianoPassi) -> Bool {
        let titoli = piano.divisioni.flatMap { [$0.titolo] + $0.quote.map(\.titolo) }.filter { !$0.isEmpty }
        let senzaTitoli = titoli.sorted { $0.count > $1.count }.reduce(testo) { $0.replacingOccurrences(of: $1, with: " ") }
        let senzaFrasiFisse = senzaTitoli.replacingOccurrences(of: #"\bdell[ae]\s+(?:due|tre)\s+divisioni\b"#, with: " ",
                                                               options: [.regularExpression, .caseInsensitive])
        return !TreLivelliVera.paroleNumeriche(senzaFrasiFisse).isEmpty
    }

    /// Un titolo di divisione piegato e senza virgolette («Più per «Università di Anna»» → «piu per universita di anna»).
    private static func nomeDivisione(_ s: String) -> String {
        piega(s).replacingOccurrences(of: "«", with: "").replacingOccurrences(of: "»", with: "")
    }

    /// true se il testo nomina la divisione scelta e non ne consiglia un'altra: dopo ogni «consiglio», «suggerisco»,
    /// «raccomando», «la scelta migliore», «meglio» (ma non «meglio di»)… la prima divisione nominata nella stessa frase
    /// è quella scelta, e per le parole di valutazione («scelta», «migliore», «meglio», «ideale», «conviene», «preferibile»)
    /// anche la divisione più vicina prima, nella stessa proposizione («ma Più protezione è la scelta migliore» no);
    /// se nessuna frase consiglia una divisione, la prima nominata nel testo è quella scelta («L'Equilibrio non basta: ti consiglio Più protezione» no).
    static func consigliaSolo(_ scelta: DivisioneBudget, tra divisioni: [DivisioneBudget], testo: String) -> Bool {
        let t = nomeDivisione(testo)
        let nome = nomeDivisione(scelta.titolo)
        guard !nome.isEmpty, t.contains(nome) else { return false }
        // Dove compare ogni divisione (la più lunga vince se due titoli si sovrappongono)
        var trovate: [(posizione: Int, fine: Int, tipo: TipoDivisione)] = []
        let ns = t as NSString
        for div in divisioni {
            let n = nomeDivisione(div.titolo)
            guard !n.isEmpty else { continue }
            var cerca = NSRange(location: 0, length: ns.length)
            while true {
                let r = ns.range(of: n, options: [], range: cerca)
                if r.location == NSNotFound { break }
                trovate.append((r.location, r.location + r.length, div.tipo))
                let dopo = r.location + max(r.length, 1)
                cerca = NSRange(location: dopo, length: ns.length - dopo)
            }
        }
        trovate = trovate.filter { a in
            !trovate.contains { b in (b.fine - b.posizione) > (a.fine - a.posizione) && b.posizione <= a.posizione && b.fine >= a.fine }
        }.sorted { $0.posizione < $1.posizione }
        // Il gruppo 1 sono le parole di confronto («meglio», «conviene», «preferibile», «migliore»): non consigliano
        // quando sono seguite da «di / a / che / rispetto» («meglio di Più protezione» è un paragone, non un consiglio).
        // Un punto seguito da una cifra (le migliaia, «400.000») non chiude la frase.
        guard let re = try? NSRegularExpression(pattern: #"\b(?:(meglio|convien\w*|preferi\w*|miglior\w*|ideale)|consigli\w*|suggeri\w*|suggerirei|propong\w*|proporrei|scegl\w*|scelgo|scelt[ao]\b|raccomand\w*|opt\w*|punt(?:a|o|erei)\b)"#),
              let paragone = try? NSRegularExpression(pattern: #"\s+(?:(?:molto|ben|assai)\s+)?(?:(?:piu|meno)\s+)?(?:di|del\w*|dell'|a|al|ai|agli|all\w*|che|rispetto)\b"#),
              let fineFrase = try? NSRegularExpression(pattern: #"[!?;\n]|\.(?!\d)"#) else { return false }
        // Dove comincia una proposizione: la fine della frase, la punteggiatura, «ma», «però», «anche se», «mentre», «invece»
        guard let inizioProposizione = try? NSRegularExpression(pattern: #"[!?;:,\n]|\.(?!\d)|\b(?:ma|pero|anche se|mentre|invece)\b"#) else { return false }
        var unaFraseConsiglia = false
        for m in re.matches(in: t, range: NSRange(location: 0, length: ns.length)) {
            let da = m.range.location + m.range.length
            let resto = NSRange(location: da, length: ns.length - da)
            let valuta = m.range(at: 1).location != NSNotFound || ns.substring(with: m.range).hasPrefix("scelta")
            if m.range(at: 1).location != NSNotFound,
               paragone.firstMatch(in: t, options: [.anchored], range: resto) != nil { continue }
            // Le parole di valutazione («meglio», «la scelta migliore», «conviene») valgono anche per la divisione
            // nominata prima, nella stessa proposizione: «ma Più protezione è la scelta migliore» consiglia Più protezione
            if valuta {
                let davanti = NSRange(location: 0, length: m.range.location)
                let inizio = inizioProposizione.matches(in: t, range: davanti).last.map { $0.range.location + $0.range.length } ?? 0
                if let prima = trovate.last(where: { $0.posizione >= inizio && $0.fine <= m.range.location }) {
                    unaFraseConsiglia = true
                    if prima.tipo != scelta.tipo { return false }
                }
            }
            let limite = fineFrase.firstMatch(in: t, range: resto)?.range.location ?? ns.length
            guard let prima = trovate.first(where: { $0.posizione >= da && $0.posizione < limite }) else { continue }
            unaFraseConsiglia = true
            if prima.tipo != scelta.tipo { return false }
        }
        return unaFraseConsiglia || trovate.first?.tipo == scelta.tipo
    }

    /// Mette la spiegazione di Qwen nel piano, se passa il controllo.
    static func conSpiegazione(_ json: String, piano: PianoPassi) -> PianoPassi {
        var p = piano
        if let s = leggiSpiegazione(json, piano: piano) {
            p.spiegazione = s
            p.spiegazioneConQwen = true
        }
        return p
    }

    // MARK: La risposta e le azioni

    /// La risposta in chat: con il ragionamento, il piano con gli esiti; sempre le divisioni e la spiegazione.
    static func testoRisposta(_ piano: PianoPassi, mostraRagionamento: Bool) -> String {
        var parti: [String] = []
        if mostraRagionamento {
            let righe = piano.passi.map { p in "\(p.id). \(p.titolo)" + (p.esito.isEmpty ? "" : " — \(p.esito)") }
            parti.append("Il piano di Vera\n" + righe.joined(separator: "\n"))
        }
        if !piano.divisioni.isEmpty {
            let righe = piano.divisioni.map { d -> String in
                let segno = d.tipo == piano.consigliata ? " (Vera consiglia)" : ""
                var r = "• \(d.titolo)\(segno): \(ripartizione(d, piano.richiesta))"
                let dettagli = [testoProtezione(d, piano.richiesta)].compactMap { $0 } + d.quote.map(testoObiettivo)
                if !dettagli.isEmpty { r += ". " + dettagli.joined(separator: "; ") }
                return r
            }
            parti.append(righe.joined(separator: "\n"))
        }
        if !piano.spiegazione.isEmpty { parti.append(piano.spiegazione) }
        if mostraRagionamento { parti.append("La regola: \(regola)") }
        return parti.joined(separator: "\n\n")
    }

    /// Le azioni da confermare: la divisione consigliata nel taccuino del cliente e un'attività per ogni polizza da
    /// rinnovare. Il motore non le esegue.
    static func azioni(_ piano: PianoPassi, cliente c: Cliente) -> [AzioneConferma] {
        var elenco: [AzioneConferma] = []
        if let d = piano.divisioneConsigliata {
            let nota = "Divisione dei \(piano.richiesta.dicitura) consigliata da Vera: «\(d.titolo)», \(ripartizione(d, piano.richiesta))."
            elenco.append(AzioneConferma(strumento: RegistroStrumenti.notaNuova, app: .note, titolo: "Metto «\(d.titolo)» nel taccuino di \(c.nome)",
                                         dettaglio: "«\(nota)» · nel taccuino del cliente",
                                         argomenti: ["cliente": c.id, "testo": nota]))
        }
        for v in piano.vincoli where v.tipo == .rinnovo {
            guard let data = v.data else { continue }
            let titolo = v.testo.components(separatedBy: " da rinnovare").first.map { "Rinnovare \($0)" } ?? v.testo
            elenco.append(AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Segno un'attività per \(c.nome)",
                                         dettaglio: "«\(titolo)» · entro il \(Formati.giornoMese.string(from: data))",
                                         argomenti: ["cliente": c.id, "titolo": titolo, "scadenza": RegistroStrumenti.isoData(data)]))
        }
        return elenco
    }
}
