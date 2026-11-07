import Foundation

// Il registro degli strumenti di Vera (Vera/BRIEF.md, fase 1): ogni azione di Prisma che Vera può usare, con nome,
// descrizione e schema JSON degli argomenti, come lo vuole la chiamata di strumenti di Qwen 3.5 via Ollama («tools»).
// Il modello sceglie lo strumento e gli argomenti; Prisma li risolve (il cliente dal nome, il giorno dalle parole, la
// posizione dalla descrizione), controlla quello che si controlla con regole (sovrapposizioni, campi validi, cifre nei
// messaggi) e prepara l'azione per la scheda di conferma. Niente si esegue qui: l'esecuzione sta in
// Shell/FalloTuShell.swift e parte solo dopo «Conferma». Le azioni di app non ancora pronte (Pratiche, i chilometri di
// Studio) restano registrate «in attesa» e lo dicono, con un'alternativa quando c'è.

/// Dove Prisma risolve gli argomenti: i dati che servono, il giorno di oggi e il cliente di cui si parla.
struct ContestoStrumenti {
    var oggi: Date
    var clienti: [Cliente]
    var appuntamenti: [Appuntamento]
    var posizioni: [Posizione]
    /// Il cliente della conversazione (nil nel portafoglio).
    var attivo: String?
    var impostazioni: Impostazioni
    var inModoCliente = false
    var calendario = Calendar.current

    var nomeUtente: String { impostazioni.nomeUtente }
}

/// Uno strumento del registro.
struct StrumentoVera {
    let nome: String
    let app: AppPrisma
    let descrizione: String
    /// Lo schema JSON degli argomenti.
    let parametri: [String: Any]
    /// false per le azioni di app non ancora pronte in Prisma: si registrano, ma lo dicono.
    let disponibile: Bool
    /// false per le azioni che non si possono annullare (aprire un'app).
    let annullabile: Bool
    /// In modalità cliente: lo strumento resta nel dossier del cliente davanti a te.
    let nelDossier: Bool

    var modello: StrumentoModello { StrumentoModello(nome: nome, descrizione: descrizione, parametri: parametri) }
}

/// Cosa Prisma ricava dagli argomenti di una chiamata.
enum PreparazioneAzione {
    /// L'azione pronta per la scheda.
    case azione(AzioneConferma)
    /// Manca un dato che solo il consulente può dare: Vera lo chiede.
    case domanda(String)
    /// Non si può fare (lo strumento non c'è, il cliente non c'è, l'app non è pronta…): Vera lo dice.
    case impossibile(String)
}

/// Gli argomenti di una chiamata, letti con tolleranza (il modello a volte scrive numeri come testo e viceversa).
struct ArgomentiStrumento {
    var valori: [String: Any]

    init(_ valori: [String: Any]) { self.valori = valori }

    func testo(_ chiave: String) -> String? {
        let v: String?
        switch valori[chiave] {
        case let s as String: v = s
        case let n as NSNumber: v = n.stringValue
        default: v = nil
        }
        guard let t = v?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        // «null», «nessuno», «-»: il modello a volte riempie così i campi che non sa
        if ["null", "nil", "none", "nessuno", "nessuna", "-", "n/a"].contains(t.lowercased()) { return nil }
        return t
    }

    func numero(_ chiave: String) -> Double? {
        switch valori[chiave] {
        case let n as NSNumber: return n.doubleValue
        case let s as String: return Double(s.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
        default: return nil
        }
    }
}

enum RegistroStrumenti {
    // MARK: - Il registro

    static let agendaNuovo = "agenda_nuovo_impegno"
    static let agendaSposta = "agenda_sposta_impegno"
    static let agendaBlocca = "agenda_blocca_tempo"
    static let attivitaNuova = "attivita_nuova"
    static let notaNuova = "nota_nuova"
    static let clienteAggiorna = "cliente_aggiorna"
    static let messaggiPrepara = "messaggi_prepara"
    static let posizioniScadenza = "posizioni_aggiorna_scadenza"
    static let simulatoreApri = "simulatore_apri"
    static let praticheApri = "pratiche_apri"
    static let studioChilometri = "studio_registra_chilometri"

    private static func testo(_ descrizione: String) -> [String: Any] { ["type": "string", "description": descrizione] }
    private static func scelta(_ valori: [String], _ descrizione: String) -> [String: Any] {
        ["type": "string", "enum": valori, "description": descrizione]
    }
    private static func oggetto(_ proprieta: [String: [String: Any]], richiesti: [String]) -> [String: Any] {
        ["type": "object", "properties": proprieta, "required": richiesti]
    }

    private static let schemaCliente = testo("Il cliente come lo nomina il consulente (nome o cognome). Vuoto se parla del cliente aperto.")
    private static let schemaGiorno = testo("Il giorno come lo dice il consulente («giovedì», «domani», «5 dicembre») oppure AAAA-MM-GG.")
    private static let schemaOra = testo("L'ora in formato HH:MM. Vuota se il consulente non la dice.")

    /// Tutti gli strumenti, nell'ordine delle app del dock.
    static let tutti: [StrumentoVera] = [
        StrumentoVera(nome: agendaNuovo, app: .agenda,
                      descrizione: "Fissa un nuovo impegno con un cliente in Agenda (incontro, telefonata, revisione, firma, proposta).",
                      parametri: oggetto(["cliente": schemaCliente, "giorno": schemaGiorno, "ora": schemaOra,
                                          "tipo": scelta(["incontro", "telefonata", "revisione", "firma", "proposta", "analisi", "primo incontro"], "Il tipo di impegno."),
                                          "durata_minuti": ["type": "integer", "description": "La durata in minuti, solo se il consulente la dice."],
                                          "luogo": testo("Il luogo, solo se il consulente lo dice.")],
                                         richiesti: ["cliente", "giorno", "ora"]),
                      disponibile: true, annullabile: true, nelDossier: true),
        StrumentoVera(nome: agendaSposta, app: .agenda,
                      descrizione: "Sposta un impegno già in Agenda a un altro giorno o a un'altra ora.",
                      parametri: oggetto(["cliente": schemaCliente,
                                          "giorno_attuale": testo("Il giorno in cui l'impegno è oggi («domani», «martedì»), se il consulente lo dice."),
                                          "ora_attuale": testo("L'ora attuale dell'impegno, HH:MM, se il consulente la dice."),
                                          "nuovo_giorno": testo("Il nuovo giorno, come lo dice il consulente oppure AAAA-MM-GG."),
                                          "nuova_ora": testo("La nuova ora HH:MM. Vuota per «stessa ora».")],
                                         richiesti: ["cliente", "nuovo_giorno"]),
                      disponibile: true, annullabile: true, nelDossier: true),
        StrumentoVera(nome: agendaBlocca, app: .agenda,
                      descrizione: "Blocca un pezzo di giornata in Agenda come «Non disponibile» (libera il consulente). Non sposta né cancella gli impegni.",
                      parametri: oggetto(["giorno": schemaGiorno,
                                          "dalle": testo("Inizio HH:MM (pomeriggio = 14:00, mattina = 09:00)."),
                                          "alle": testo("Fine HH:MM (pomeriggio = 19:00, mattina = 13:00)."),
                                          "motivo": testo("Il motivo, se il consulente lo dice.")],
                                         richiesti: ["giorno"]),
                      disponibile: true, annullabile: true, nelDossier: false),
        StrumentoVera(nome: attivitaNuova, app: .attivita,
                      descrizione: "Segna un'attività da fare (un promemoria) per un cliente, con la scadenza.",
                      parametri: oggetto(["cliente": schemaCliente, "titolo": testo("Cosa fare, in poche parole."),
                                          "scadenza": testo("Entro quando, come lo dice il consulente oppure AAAA-MM-GG.")],
                                         richiesti: ["cliente", "titolo"]),
                      disponibile: true, annullabile: true, nelDossier: true),
        StrumentoVera(nome: notaNuova, app: .note,
                      descrizione: "Prende una nota nel taccuino di un cliente.",
                      parametri: oggetto(["cliente": schemaCliente, "testo": testo("Il testo della nota, con le parole del consulente.")],
                                         richiesti: ["cliente", "testo"]),
                      disponibile: true, annullabile: true, nelDossier: true),
        StrumentoVera(nome: clienteAggiorna, app: .clienti,
                      descrizione: "Aggiorna un dato della scheda di un cliente: telefono o cellulare, email, indirizzo, professione.",
                      parametri: oggetto(["cliente": schemaCliente,
                                          "campo": scelta(["telefono", "email", "indirizzo", "professione"], "Il dato da cambiare (il cellulare è «telefono»)."),
                                          "valore": testo("Il nuovo valore, esattamente come lo dice il consulente.")],
                                         richiesti: ["cliente", "campo", "valore"]),
                      disponibile: true, annullabile: true, nelDossier: true),
        StrumentoVera(nome: messaggiPrepara, app: .messaggi,
                      descrizione: "Prepara la bozza di un messaggio per un cliente (non lo invia: il consulente lo apre e lo spedisce lui). «Avvisala» dopo uno spostamento = scopo spostamento.",
                      parametri: oggetto(["cliente": schemaCliente,
                                          "scopo": scelta(["spostamento", "promemoria", "consenso", "saluto", "altro"], "Perché si scrive."),
                                          "testo": testo("Il testo del messaggio, breve, con il Lei. Vuoto per lo spostamento: lo scrive Prisma.")],
                                         richiesti: ["cliente", "scopo"]),
                      disponibile: true, annullabile: true, nelDossier: true),
        StrumentoVera(nome: posizioniScadenza, app: .posizioni,
                      descrizione: "Aggiorna la data di scadenza di una posizione (polizza, piano, investimento) di un cliente.",
                      parametri: oggetto(["cliente": schemaCliente, "posizione": testo("La posizione come la chiama il consulente («la rivalutabile», «il piano casa»)."),
                                          "scadenza": testo("La nuova scadenza, come la dice il consulente oppure AAAA-MM-GG.")],
                                         richiesti: ["cliente", "scadenza"]),
                      disponibile: true, annullabile: true, nelDossier: true),
        StrumentoVera(nome: simulatoreApri, app: .simulazioni,
                      descrizione: "Apre il simulatore di Prisma per un cliente, sulla posizione indicata se c'è.",
                      parametri: oggetto(["cliente": schemaCliente, "posizione": testo("La posizione da simulare, se il consulente la dice.")],
                                         richiesti: ["cliente"]),
                      disponibile: true, annullabile: false, nelDossier: true),
        StrumentoVera(nome: praticheApri, app: .pratiche,
                      descrizione: "Apre una pratica per un cliente (proposta, moduli, firma, sinistro).",
                      parametri: oggetto(["cliente": schemaCliente, "tipo": testo("Di cosa è la pratica (es. «protezione»).")],
                                         richiesti: ["cliente"]),
                      disponibile: false, annullabile: true, nelDossier: true),
        StrumentoVera(nome: studioChilometri, app: .studio,
                      descrizione: "Registra i chilometri di una trasferta in Studio.",
                      parametri: oggetto(["giorno": schemaGiorno, "chilometri": ["type": "number", "description": "I chilometri."],
                                          "motivo": testo("Il motivo della trasferta.")],
                                         richiesti: ["chilometri"]),
                      disponibile: false, annullabile: true, nelDossier: false),
    ]

    static func strumento(_ nome: String) -> StrumentoVera? { tutti.first { $0.nome == nome } }

    /// Gli strumenti da dare al modello. In modalità cliente solo quelli che restano nel dossier.
    static func perModello(inModoCliente: Bool) -> [StrumentoModello] {
        tutti.filter { !inModoCliente || $0.nelDossier }.map(\.modello)
    }

    // MARK: - Dalla chiamata all'azione

    /// Prepara le azioni di una risposta del modello, nell'ordine; poi lega i messaggi agli spostamenti dello stesso
    /// cliente (il testo di «avvisala» lo scrive Prisma con il giorno e l'ora giusti).
    static func prepara(_ chiamate: [ChiamataStrumento], richiesta: String, contesto: ContestoStrumenti) -> [PreparazioneAzione] {
        let preparate = chiamate.map { prepara($0, contesto: contesto) }
        return lega(preparate, richiesta: richiesta, contesto: contesto)
    }

    static func prepara(_ c: ChiamataStrumento, contesto: ContestoStrumenti) -> PreparazioneAzione {
        guard let s = strumento(c.nome) else { return .impossibile("Non conosco l'azione «\(c.nome)».") }
        let a = ArgomentiStrumento(c.argomenti)
        switch s.nome {
        case agendaNuovo: return nuovoImpegno(a, contesto)
        case agendaSposta: return spostaImpegno(a, contesto)
        case agendaBlocca: return bloccaTempo(a, contesto)
        case attivitaNuova: return nuovaAttivita(a, contesto)
        case notaNuova: return nuovaNota(a, contesto)
        case clienteAggiorna: return aggiornaCliente(a, contesto)
        case messaggiPrepara: return preparaMessaggio(a, contesto)
        case posizioniScadenza: return scadenzaPosizione(a, contesto)
        case simulatoreApri: return apriSimulatore(a, contesto)
        case praticheApri: return praticaInAttesa(a, contesto)
        case studioChilometri:
            return .impossibile("Studio non registra ancora i chilometri: quando sarà pronto lo farò io. Per ora segnali tu in Studio.")
        default: return .impossibile("Non conosco l'azione «\(c.nome)».")
        }
    }

    // MARK: - Clienti, giorni, ore

    enum Risolto<T> {
        case trovato(T)
        case nessuno
        case ambiguo([T])
    }

    /// Il cliente nominato (o quello aperto se il nome manca).
    static func cliente(_ nome: String?, _ x: ContestoStrumenti) -> Risolto<Cliente> {
        if let id = nome, let c = x.clienti.first(where: { $0.id == id }) { return .trovato(c) }
        guard let nome, !nome.isEmpty else {
            if let id = x.attivo, let c = x.clienti.first(where: { $0.id == id }) { return .trovato(c) }
            return .nessuno
        }
        let noti = x.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        var trovati = InterpreteComandi.clientiNominati(nome.lowercased(), noti)
        // Con un nome ripetuto (due Bianchi) vince il cliente aperto
        if trovati.count > 1, let id = x.attivo, trovati.contains(where: { $0.id == id }) { trovati = trovati.filter { $0.id == id } }
        let clienti = trovati.compactMap { t in x.clienti.first { $0.id == t.id } }
        switch clienti.count {
        case 0: return .nessuno
        case 1: return .trovato(clienti[0])
        default: return .ambiguo(clienti)
        }
    }

    /// Il cliente, oppure il cliente nella cui famiglia c'è la persona nominata (Elena → Marco Bianchi).
    static func clienteOFamiliare(_ nome: String?, _ x: ContestoStrumenti) -> (Cliente, Familiare?)? {
        if case .trovato(let c) = cliente(nome, x) { return (c, nil) }
        guard let nome = nome?.lowercased(), !nome.isEmpty else { return nil }
        for c in x.clienti {
            if let f = c.famiglia.first(where: { f in
                let primo = f.nome.split(separator: " ").first.map { $0.lowercased() } ?? ""
                return primo.count >= 3 && nome.contains(primo)
            }) { return (c, f) }
        }
        return nil
    }

    private static func messaggioCliente(_ nome: String?, _ r: Risolto<Cliente>) -> PreparazioneAzione? {
        switch r {
        case .trovato: return nil
        case .nessuno:
            if let nome, !nome.isEmpty { return .impossibile("Non trovo «\(nome)» tra i clienti.") }
            return .domanda("Per quale cliente?")
        case .ambiguo(let c):
            return .domanda("Quale cliente intendi: \(c.map(\.nome).joined(separator: " o "))?")
        }
    }

    /// Il giorno: AAAA-MM-GG oppure le parole («giovedì», «domani», «5 dicembre»).
    static func giorno(_ s: String?, oggi: Date, cal: Calendar = .current) -> Date? {
        guard let s, !s.isEmpty else { return nil }
        let iso = DateFormatter()
        iso.locale = Locale(identifier: "en_US_POSIX")
        iso.calendar = cal
        iso.timeZone = cal.timeZone
        iso.dateFormat = "yyyy-MM-dd"
        if let d = iso.date(from: String(s.prefix(10))) { return cal.startOfDay(for: d) }
        // «giovedì» da solo: DateItaliane lo riconosce anche senza preposizione
        return DateItaliane.trova(s, oggi: oggi, cal: cal).giorno.map { cal.startOfDay(for: $0) }
    }

    /// L'ora: «10:00», «10.30», «10», «alle tre e mezza».
    static func ora(_ s: String?) -> (ore: Int, minuti: Int)? {
        guard let s, !s.isEmpty else { return nil }
        if case let (_, g)? = DateItaliane.cerca(#"^\s*(?:alle\s+)?(\d{1,2})(?:[:.](\d{2}))?\s*$"#, s.lowercased()),
           var h = Int(g[1]), (0...23).contains(h) {
            let m = Int(g[2]) ?? 0
            // «3» o «alle 3» senza minuti: per un impegno è il pomeriggio, come in DateItaliane.trova
            if g[2].isEmpty, (1...7).contains(h) { h += 12 }
            return (0...59).contains(m) ? (h, m) : nil
        }
        let t = s.lowercased().hasPrefix("alle") ? s : "alle " + s
        return DateItaliane.trova(t).ora
    }

    static func unisci(_ g: Date, _ o: (ore: Int, minuti: Int), cal: Calendar = .current) -> Date? {
        cal.date(bySettingHour: o.ore, minute: o.minuti, second: 0, of: g)
    }

    static func isoData(_ d: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: d)
    }

    static func daIso(_ s: String?) -> Date? {
        guard let s else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }

    /// «giovedì 12 novembre, 10:00».
    static func quando(_ d: Date, conOra: Bool = true) -> String {
        let g = Formati.dataLunga.string(from: d)
        return conOra ? "\(g), \(Formati.ora.string(from: d))" : g
    }

    /// Gli impegni pianificati che si sovrappongono a un intervallo (escluso quello che si sposta).
    static func sovrapposti(_ inizio: Date, _ fine: Date, _ x: ContestoStrumenti, escluso: String? = nil) -> [Appuntamento] {
        x.appuntamenti.filter { $0.id != escluso && $0.stato == .pianificato && $0.inizio < fine && $0.fine > inizio }
    }

    /// «giovedì sei libero fino alle 11:30» / «giovedì non hai altri impegni».
    private static func libero(dopo fine: Date, _ x: ContestoStrumenti, escluso: String?) -> String {
        let cal = x.calendario
        let giorno = Formati.giornoSettimana.string(from: fine)
        let dopo = x.appuntamenti.filter { $0.id != escluso && $0.stato == .pianificato && cal.isDate($0.inizio, inSameDayAs: fine) && $0.inizio >= fine }
            .min { $0.inizio < $1.inizio }
        if let d = dopo { return "\(giorno) sei libero fino alle \(Formati.ora.string(from: d.inizio))" }
        return "\(giorno) non hai altri impegni dopo"
    }

    private static func avvisoSovrapposti(_ s: [Appuntamento], _ x: ContestoStrumenti) -> String? {
        guard let a = s.first else { return nil }
        // In modalità cliente niente titoli né nomi degli impegni degli altri
        if x.inModoCliente && a.clienteId != x.attivo { return "A quell'ora hai già un altro impegno, alle \(Formati.ora.string(from: a.inizio))." }
        let chi = x.clienti.first { $0.id == a.clienteId }.map { " con \($0.nome)" } ?? ""
        return "A quell'ora c'è già «\(a.titolo)»\(chi), alle \(Formati.ora.string(from: a.inizio))."
    }

    // MARK: - Agenda

    static func tipo(_ s: String?) -> TipoAppuntamento {
        switch s?.lowercased() ?? "" {
        case let t where t.contains("telefon") || t.contains("chiamata"): return .telefonata
        case let t where t.contains("revision"): return .revisione
        case let t where t.contains("firma"): return .firma
        case let t where t.contains("propost"): return .proposta
        case let t where t.contains("analisi"): return .analisi
        case let t where t.contains("primo"): return .primoIncontro
        default: return .altro
        }
    }

    private static func nuovoImpegno(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard case .trovato(let c) = r else { return .domanda("Con quale cliente?") }
        guard let g = giorno(a.testo("giorno"), oggi: x.oggi, cal: x.calendario) else {
            return .domanda("Per quando lo fisso con \(c.nome)? Dimmi per esempio «giovedì alle 15».")
        }
        guard let o = ora(a.testo("ora")), let inizio = unisci(g, o, cal: x.calendario) else {
            return .domanda("A che ora, \(DateItaliane.descrivi(g, conOra: false, oggi: x.oggi))?")
        }
        let t = tipo(a.testo("tipo"))
        let durata = a.numero("durata_minuti").map { max(10, min(600, Int($0))) } ?? (t == .telefonata ? 20 : 60)
        let luogo = a.testo("luogo") ?? (t == .telefonata ? "Telefonata" : "In studio")
        let titolo = titoloImpegno(t, cliente: c.nome)
        let fine = inizio.addingTimeInterval(TimeInterval(durata * 60))
        var avviso = avvisoSovrapposti(sovrapposti(inizio, fine, x), x)
        if inizio < x.oggi { avviso = "È un orario già passato." + (avviso.map { " " + $0 } ?? "") }
        return .azione(AzioneConferma(strumento: agendaNuovo, app: .agenda, titolo: "Fisso «\(titolo)»",
                                      dettaglio: "\(quando(inizio)) · \(luogo) · \(durata) minuti",
                                      argomenti: ["cliente": c.id, "inizio": isoData(inizio), "tipo": t.rawValue,
                                                  "durata": String(durata), "luogo": luogo, "titolo": titolo],
                                      avviso: avviso))
    }

    static func titoloImpegno(_ tipo: TipoAppuntamento, cliente: String) -> String {
        switch tipo {
        case .telefonata: return "Telefonata con \(cliente)"
        case .revisione: return "Revisione con \(cliente)"
        case .firma: return "Firma con \(cliente)"
        case .proposta: return "Presentazione della proposta a \(cliente)"
        default: return "Incontro con \(cliente)"
        }
    }

    /// L'impegno da spostare: tra i prossimi del cliente, quello del giorno e dell'ora detti (se detti).
    static func impegnoDaSpostare(_ c: Cliente, giorno g: Date?, ora o: (ore: Int, minuti: Int)?, _ x: ContestoStrumenti) -> Appuntamento? {
        let cal = x.calendario
        var candidati = x.appuntamenti.filter { $0.clienteId == c.id && $0.stato == .pianificato && $0.inizio >= cal.startOfDay(for: x.oggi) }
        if let g { candidati = candidati.filter { cal.isDate($0.inizio, inSameDayAs: g) } }
        if let o, candidati.count > 1 {
            let stessaOra = candidati.filter { cal.component(.hour, from: $0.inizio) == o.ore }
            if !stessaOra.isEmpty { candidati = stessaOra }
        }
        return candidati.min { $0.inizio < $1.inizio }
    }

    private static func spostaImpegno(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard case .trovato(let c) = r else { return .domanda("Di quale cliente è l'impegno da spostare?") }
        let giornoAttuale = giorno(a.testo("giorno_attuale"), oggi: x.oggi, cal: x.calendario)
        guard let imp = impegnoDaSpostare(c, giorno: giornoAttuale, ora: ora(a.testo("ora_attuale")), x)
                ?? (giornoAttuale != nil ? impegnoDaSpostare(c, giorno: nil, ora: nil, x) : nil) else {
            return .impossibile("Non trovo un impegno di \(c.nome) da spostare: i prossimi in agenda non ci sono.")
        }
        let cal = x.calendario
        let nuovoGiorno = giorno(a.testo("nuovo_giorno"), oggi: x.oggi, cal: cal)
        let nuovaOra = ora(a.testo("nuova_ora"))
        guard nuovoGiorno != nil || nuovaOra != nil else {
            return .domanda("A quando sposto «\(imp.titolo)» con \(c.nome)?")
        }
        let g = nuovoGiorno ?? cal.startOfDay(for: imp.inizio)
        let o = nuovaOra ?? (cal.component(.hour, from: imp.inizio), cal.component(.minute, from: imp.inizio))
        guard let inizio = unisci(g, o, cal: cal) else { return .domanda("A che ora lo sposto?") }
        guard inizio != imp.inizio else { return .impossibile("«\(imp.titolo)» è già \(DateItaliane.descrivi(inizio, conOra: true, oggi: x.oggi)).") }
        let fine = inizio.addingTimeInterval(TimeInterval(imp.durataMinuti * 60))
        var avviso = avvisoSovrapposti(sovrapposti(inizio, fine, x, escluso: imp.id), x)
        if inizio < x.oggi { avviso = "È un orario già passato." + (avviso.map { " " + $0 } ?? "") }
        let luogo = imp.luogo.isEmpty ? "" : " · \(imp.luogo)"
        let liberoDopo = avviso == nil ? " · " + libero(dopo: fine, x, escluso: imp.id) : ""
        return .azione(AzioneConferma(strumento: agendaSposta, app: .agenda, titolo: "Sposto «\(imp.titolo)»",
                                      dettaglio: "\(quando(imp.inizio)) → \(quando(inizio))\(luogo)\(liberoDopo)",
                                      argomenti: ["appuntamento": imp.id, "cliente": c.id, "inizio": isoData(inizio),
                                                  "prima": isoData(imp.inizio), "luogo": imp.luogo],
                                      avviso: avviso))
    }

    private static func bloccaTempo(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let cal = x.calendario
        guard let g = giorno(a.testo("giorno"), oggi: x.oggi, cal: cal) else { return .domanda("Quale giorno ti libero?") }
        let dalle = ora(a.testo("dalle")) ?? (9, 0)
        let alle = ora(a.testo("alle")) ?? (19, 0)
        guard let inizio = unisci(g, dalle, cal: cal), let fine = unisci(g, alle, cal: cal), fine > inizio else {
            return .domanda("Da che ora a che ora ti libero?")
        }
        let motivo = a.testo("motivo")
        let dentro = sovrapposti(inizio, fine, x)
        let avviso: String? = dentro.isEmpty ? nil
            : "In quell'orario \(dentro.count == 1 ? "c'è già «\(dentro[0].titolo)»" : "ci sono già \(dentro.count) impegni"): restano dove sono, decidi tu se spostarli."
        let minuti = Int(fine.timeIntervalSince(inizio) / 60)
        let resto = dentro.isEmpty ? "Nessun impegno da spostare: " : ""
        return .azione(AzioneConferma(strumento: agendaBlocca, app: .agenda,
                                      titolo: "Blocco \(Formati.dataLunga.string(from: g)) dalle \(Formati.ora.string(from: inizio)) alle \(Formati.ora.string(from: fine))",
                                      dettaglio: "\(resto)il tempo diventa «Non disponibile»" + (motivo.map { " · \($0)" } ?? ""),
                                      argomenti: ["inizio": isoData(inizio), "durata": String(minuti), "motivo": motivo ?? ""],
                                      avviso: avviso))
    }

    // MARK: - Attività e note

    private static func nuovaAttivita(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard case .trovato(let c) = r else { return .domanda("Per quale cliente lo segno?") }
        guard let titolo = a.testo("titolo") else { return .domanda("Cosa ti segno per \(c.nome)?") }
        let scadenza = giorno(a.testo("scadenza"), oggi: x.oggi, cal: x.calendario) ?? x.calendario.startOfDay(for: x.oggi)
        return .azione(AzioneConferma(strumento: attivitaNuova, app: .attivita, titolo: "Segno un'attività per \(c.nome)",
                                      dettaglio: "«\(titolo)» · entro \(DateItaliane.descrivi(scadenza, conOra: false, oggi: x.oggi))",
                                      argomenti: ["cliente": c.id, "titolo": titolo, "scadenza": isoData(scadenza)]))
    }

    private static func nuovaNota(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard case .trovato(let c) = r else { return .domanda("Per quale cliente prendo nota?") }
        guard let testo = a.testo("testo") else { return .domanda("Cosa annoto per \(c.nome)?") }
        return .azione(AzioneConferma(strumento: notaNuova, app: .note, titolo: "Prendo nota per \(c.nome)",
                                      dettaglio: "«\(testo)» · nel taccuino del cliente",
                                      argomenti: ["cliente": c.id, "testo": testo]))
    }

    // MARK: - Clienti

    /// I campi della scheda che Vera può cambiare.
    static let campiCliente: [String: String] = ["telefono": "Cellulare", "email": "Email", "indirizzo": "Indirizzo", "professione": "Professione"]

    static func campo(_ s: String?) -> String? {
        let t = s?.lowercased() ?? ""
        if t.contains("cell") || t.contains("telef") || t.contains("numero") { return "telefono" }
        if t.contains("mail") { return "email" }
        if t.contains("indirizz") || t.contains("casa") { return "indirizzo" }
        if t.contains("profess") || t.contains("lavoro") { return "professione" }
        return nil
    }

    private static func aggiornaCliente(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard case .trovato(let c) = r else { return .domanda("Di quale cliente aggiorno la scheda?") }
        guard let campo = campo(a.testo("campo")), let etichetta = campiCliente[campo] else {
            return .domanda("Quale dato di \(c.nome) cambio: cellulare, email, indirizzo o professione?")
        }
        guard let valore = a.testo("valore") else { return .domanda("Qual è il nuovo valore?") }
        let vecchio: String
        switch campo {
        case "telefono":
            let cifre = valore.filter(\.isNumber)
            guard cifre.count >= 6 else { return .impossibile("«\(valore)» non sembra un numero di telefono: me lo ripeti?") }
            vecchio = c.telefono
        case "email":
            guard valore.contains("@"), valore.contains(".") else { return .impossibile("«\(valore)» non sembra un indirizzo email: me lo ripeti?") }
            vecchio = c.email
        case "indirizzo": vecchio = c.indirizzo
        default: vecchio = c.professione
        }
        guard vecchio != valore else { return .impossibile("La scheda di \(c.nome) ha già \(etichetta.lowercased()) \(valore).") }
        let nota = campo == "telefono" && !vecchio.isEmpty ? " · il vecchio numero passa nelle note" : (vecchio.isEmpty ? "" : " · prima: \(vecchio)")
        return .azione(AzioneConferma(strumento: clienteAggiorna, app: .clienti, titolo: "Aggiorno la scheda di \(c.nome)",
                                      dettaglio: "\(etichetta) \(valore)\(nota)",
                                      argomenti: ["cliente": c.id, "campo": campo, "valore": valore]))
    }

    // MARK: - Messaggi

    private static func preparaMessaggio(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard case .trovato(let c) = r else { return .domanda("A quale cliente scrivo?") }
        let scopo = a.testo("scopo")?.lowercased() ?? "altro"
        let testo = a.testo("testo") ?? ""
        let canale: CanaleMessaggio = c.telefono.filter(\.isNumber).count >= 6 ? .messaggi : .mail
        // Il testo dello spostamento lo scrive Prisma in `lega`; gli altri restano quelli del modello, da rivedere
        guard !testo.isEmpty || scopo == "spostamento" else { return .domanda("Cosa scrivo a \(c.nome)?") }
        return .azione(AzioneConferma(strumento: messaggiPrepara, app: .messaggi, titolo: "Preparo un messaggio per \(c.nome)",
                                      dettaglio: dettaglioMessaggio(testo, canale: canale),
                                      argomenti: ["cliente": c.id, "scopo": scopo, "testo": testo, "canale": canale.rawValue]))
    }

    static func dettaglioMessaggio(_ testo: String, canale: CanaleMessaggio) -> String {
        "«\(testo)» · resta una bozza da aprire in \(canale == .mail ? "Mail" : "Messaggi"): lo spedisci tu"
    }

    /// «Buongiorno Laura, le propongo di spostare il nostro incontro a giovedì 12 novembre alle 10:00, sempre in studio. Mi conferma?»
    static func testoSpostamento(_ c: Cliente, inizio: Date, luogo: String, firma: String?) -> String {
        let nome = c.nome.split(separator: " ").first.map(String.init) ?? c.nome
        let dove = luogo.isEmpty ? "" : (luogo.lowercased().contains("studio") ? ", sempre in studio" : ", \(luogo.lowercased())")
        let saluto = firma.map { " Un caro saluto, \($0)" } ?? " Un caro saluto."
        return "Buongiorno \(nome), le propongo di spostare il nostro incontro a \(Formati.dataLunga.string(from: inizio)) alle \(Formati.ora.string(from: inizio))\(dove). Mi conferma?\(saluto)"
    }

    /// I numeri di un testo del modello che non vengono dalla richiesta né dalle altre azioni della scheda.
    static func cifreSenzaFonte(_ testo: String, fonti: String) -> [String] {
        let ammesse = Set(FontiVera.numeri(fonti).map(\.valore))
        return FontiVera.numeri(testo).filter { n in !ammesse.contains { abs($0 - n.valore) < 0.001 } }.map(\.testo)
    }

    /// Dopo la preparazione: il messaggio di uno spostamento prende giorno e ora dallo spostamento (scritti da Prisma);
    /// le cifre di un testo scritto dal modello che non vengono da nessuna parte diventano un avviso.
    static func lega(_ preparate: [PreparazioneAzione], richiesta: String, contesto x: ContestoStrumenti) -> [PreparazioneAzione] {
        let spostamenti: [String: AzioneConferma] = preparate.reduce(into: [:]) { m, p in
            if case .azione(let a) = p, a.strumento == agendaSposta, let c = a.argomenti["cliente"] { m[c] = a }
        }
        // Le fonti ammesse: la richiesta e le righe scritte da Prisma; i testi dei messaggi li scrive il modello e non contano
        let dettagli = preparate.compactMap { p -> String? in
            if case .azione(let a) = p, a.strumento != messaggiPrepara { return a.dettaglio }
            return nil
        }.joined(separator: "\n")
        return preparate.map { p in
            guard case .azione(var a) = p, a.strumento == messaggiPrepara, let id = a.argomenti["cliente"],
                  let c = x.clienti.first(where: { $0.id == id }) else { return p }
            let canale = CanaleMessaggio(rawValue: a.argomenti["canale"] ?? "") ?? .messaggi
            if let s = spostamenti[id], let inizio = daIso(s.argomenti["inizio"]),
               a.argomenti["scopo"] == "spostamento" || (a.argomenti["testo"] ?? "").isEmpty {
                let firma = ModelliMessaggi.firma(nil, tono: .formale, impostazioni: x.impostazioni)
                a.argomenti["testo"] = testoSpostamento(c, inizio: inizio, luogo: s.argomenti["luogo"] ?? "", firma: firma)
                a.argomenti["scopo"] = "spostamento"
                a.argomenti["appuntamento"] = s.argomenti["appuntamento"]
                a.titolo = "Preparo un messaggio per \(c.nome)"
                a.dettaglio = dettaglioMessaggio(a.argomenti["testo"] ?? "", canale: canale)
                return .azione(a)
            }
            guard let testo = a.argomenti["testo"], !testo.isEmpty else {
                return .domanda("Cosa scrivo a \(c.nome)? Per avvisarla di uno spostamento, dimmi anche cosa sposto.")
            }
            let senza = cifreSenzaFonte(testo, fonti: richiesta + "\n" + dettagli)
            if !senza.isEmpty {
                a.avviso = "Controlla nel testo \(senza.joined(separator: ", ")): non viene da Prisma né dalla tua richiesta."
            }
            return .azione(a)
        }
    }

    // MARK: - Posizioni e simulatore

    /// La posizione nominata tra quelle del cliente (in essere o in proposta); se il cliente ne ha una sola, quella.
    static func posizione(_ nome: String?, di c: Cliente, _ x: ContestoStrumenti) -> Risolto<Posizione> {
        let sue = x.posizioni.filter { $0.clienteId == c.id && $0.stato != .chiusa }
        guard let nome = nome?.lowercased(), !nome.isEmpty else {
            return sue.count == 1 ? .trovato(sue[0]) : (sue.isEmpty ? .nessuno : .ambiguo(sue))
        }
        let vuote: Set<String> = ["il", "la", "lo", "di", "del", "della", "per", "sua", "suo", "piano", "polizza"]
        let parole = nome.split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count >= 3 && !vuote.contains($0) }
        func punti(_ p: Posizione) -> Int {
            let t = "\(p.nome) \(p.tipologia) \(p.area.rawValue) \(p.rischio?.rawValue ?? "")".lowercased()
            return parole.reduce(0) { $0 + (t.contains($1) || t.contains(String($1.prefix(6))) ? 1 : 0) }
        }
        let migliori = sue.map { ($0, punti($0)) }.filter { $0.1 > 0 }
        guard let massimo = migliori.map(\.1).max() else { return sue.isEmpty ? .nessuno : .ambiguo(sue) }
        let scelte = migliori.filter { $0.1 == massimo }.map(\.0)
        return scelte.count == 1 ? .trovato(scelte[0]) : .ambiguo(scelte)
    }

    private static func scadenzaPosizione(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard case .trovato(let c) = r else { return .domanda("Di quale cliente è la posizione?") }
        let p: Posizione
        switch posizione(a.testo("posizione"), di: c, x) {
        case .trovato(let t): p = t
        case .nessuno: return .impossibile("\(c.nome) non ha posizioni in Prisma.")
        case .ambiguo(let elenco): return .domanda("Quale posizione di \(c.nome): \(elenco.prefix(4).map { "«\($0.nome)»" }.joined(separator: ", "))?")
        }
        guard let nuova = giorno(a.testo("scadenza"), oggi: x.oggi, cal: x.calendario) else { return .domanda("Qual è la nuova scadenza?") }
        let prima = p.scadenza.map { " · prima: \(Formati.dataEstesa.string(from: $0))" } ?? " · prima non c'era"
        return .azione(AzioneConferma(strumento: posizioniScadenza, app: .posizioni, titolo: "Aggiorno la scadenza in Posizioni",
                                      dettaglio: "«\(p.nome)» di \(c.nome) · \(p.canale.nomeBreve) · \(Formati.dataEstesa.string(from: nuova))\(prima)",
                                      argomenti: ["posizione": p.id, "cliente": c.id, "scadenza": isoData(nuova)]))
    }

    private static func apriSimulatore(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard case .trovato(let c) = r else { return .domanda("Per quale cliente apro il simulatore?") }
        var argomenti = ["cliente": c.id]
        var dettaglio = "Con le ipotesi di \(c.nome)"
        if a.testo("posizione") != nil, case .trovato(let p) = posizione(a.testo("posizione"), di: c, x) {
            argomenti["posizione"] = p.id
            dettaglio = "«\(p.nome)» di \(c.nome) · \(p.canale.nomeBreve)"
        }
        return .azione(AzioneConferma(strumento: simulatoreApri, app: .simulazioni, titolo: "Apro il simulatore", dettaglio: dettaglio, argomenti: argomenti))
    }

    // MARK: - In attesa

    /// Pratiche non è ancora pronta: Vera lo dice e propone un'attività al suo posto.
    private static func praticaInAttesa(_ a: ArgomentiStrumento, _ x: ContestoStrumenti) -> PreparazioneAzione {
        let r = cliente(a.testo("cliente"), x)
        if case .ambiguo = r, let m = messaggioCliente(a.testo("cliente"), r) { return m }
        guard let (c, familiare) = clienteOFamiliare(a.testo("cliente"), x) else {
            if let n = a.testo("cliente") { return .impossibile("Non trovo «\(n)» tra i clienti né nelle loro famiglie.") }
            return .domanda("Per quale cliente apro la pratica?")
        }
        let tipo = a.testo("tipo").map { " · \($0)" } ?? ""
        let per = familiare.map { " per \($0.nome)" } ?? ""
        let titolo = "Aprire la pratica\(per)\(tipo)"
        return .azione(AzioneConferma(strumento: attivitaNuova, app: .pratiche, titolo: "Segno un'attività per la pratica",
                                      dettaglio: "«\(titolo)» tra le attività di \(c.nome)",
                                      argomenti: ["cliente": c.id, "titolo": titolo, "scadenza": isoData(x.calendario.startOfDay(for: x.oggi))],
                                      avviso: "Pratiche non è ancora pronta in Prisma: al suo posto ti segno un'attività."))
    }
}
