import Foundation

/// Un messaggio della conversazione con Vera (salvato nel dossier del cliente).
struct MessaggioVera: Identifiable, Codable, Equatable {
    // Compatibilità: negli archivi, nei backup e nei giornali di «Prisma ovunque» il valore salvato resta «eve» (il vecchio nome).
    enum Autore: String, Codable { case utente, vera = "eve" }

    var id = "msg-\(UUID().uuidString.prefix(8).lowercased())"
    var autore: Autore
    var testo: String
    /// Titolo breve delle risposte di Vera.
    var titolo: String?
    /// Motore che ha prodotto la risposta ("Qwen sul Mac", "Calcoli di Prisma").
    var motore: String?
    var data = Date()
    /// Le azioni proposte da Vera (spunto «Cosa proporre al cliente?»), con quello che ne è stato fatto.
    var proposte: [PropostaVera]?
    /// Quello che Vera ha fatto su tua richiesta (un appuntamento, un promemoria, una nota): si apre o si annulla.
    var azione: AzioneVera?
    /// La modalità in cui Vera ha risposto (lavoro o conversazione): una domanda breve di seguito resta lì.
    var modalita: ModalitaVera?
    /// Lo scenario «E se…?» calcolato da Prisma: la scheda prima/dopo sotto la risposta (ScenariVera, MotoreScenari).
    var scenario: SchedaScenarioVera?
    /// «Fallo tu»: le azioni proposte da Vera, eseguite solo dopo «Conferma» (ConfermaVera.swift).
    var conferma: SchedaConfermaVera?
    /// «Chiedi alla tua clientela»: i filtri capiti e la tabella dei clienti (ClientelaVera.swift).
    var clientela: RisultatoClientela?
    /// «Mai a caso»: la fonte di ogni cifra della risposta (FontiVera.swift).
    var fonti: [FonteCifra]?
    /// 👍 (true) o 👎 (false) del consulente sulla risposta («Impara dalle correzioni»).
    var voto: Bool?
    /// «Il cliente in 30 secondi»: le cinque sezioni con la loro fonte (TrentaSecondiVera.swift).
    var trenta: SchedaTrentaSecondi?
    /// «Il codice in tasca»: gli articoli citati dalla biblioteca delle norme (NormeVera.swift).
    var norme: RispostaNorme?
    /// Fase 3: «Le promesse» (gli id, lo stato si legge sempre aggiornato), «La seconda lettura» (gli avvisi), «Trova
    /// le differenze» (il confronto salvato), «Cosa non copre» (la polizza letta) e il resoconto (l'incontro).
    var promesse: [String]?
    var lettura: EsitoSecondaLettura?
    var confronto: String?
    var copertura: String?
    var resoconto: String?
    /// Fase 4 (Vera/BRIEF.md), le risposte con la loro scheda; tutto viaggia con le conversazioni (archivio e backup sì,
    /// istantanea di Prisma ovunque no) e si legge con tolleranza (un campo rovinato si perde da solo, il messaggio resta).
    /// «Le routine» (3): il lancio con i passi spuntati e il risultato (le azioni sono nella scheda `conferma`).
    var esitoRoutine: EsitoRoutine?
    /// «L'agenda che si organizza» (4): gli orari proposti (la ricerca di Prisma), quello scelto dal cliente e lo
    /// spostamento in blocco (AgendaOrganizzaVera.swift; viste in VisteAgendaOrganizzaVera.swift).
    var agendaOrari: RicercaOrari?
    var agendaOrariScelto: String?
    var agendaSpostamento: SpostamentoBlocco?
    /// «Il tagliando dei dati» (5) sotto la risposta: "" = tutto l'archivio, altrimenti l'id del cliente (il controllo
    /// si legge da StatoShell.esitoTagliando, che le viste ricalcolano quando cambiano i dati: `versioneCalcoli`).
    var tagliando: String?
    /// «Il mercato per i tuoi clienti» (14): l'evento con i clienti toccati (motivo, azione e cifre di Prisma) e l'id
    /// del messaggio con la scheda «Conferma» delle bozze, quando sono state preparate («Bozze pronte ✓»).
    var mercatoClienti: EsitoMercatoVera?
    var mercatoBozze: String?
    /// «Scrive come te» (15): il profilo di stile o la bozza riscritta nello stile (CollegaStileShell.swift).
    var stileVera: SchedaStileVera?
    /// «Tre livelli» (17): l'id della spiegazione salvata (DatiPrisma.spiegazioniTreLivelli) e il livello che la scheda
    /// apre per primo.
    var treLivelli: String?
    var treLivelliLivello: LivelloTreLivelli?
    /// «Ragiona a passi» (20): il piano eseguito con le tre divisioni e la scelta (PassiVera.swift, VistePassiVera.swift).
    var pianoPassi: PianoPassi?

    init(autore: Autore, testo: String, titolo: String? = nil, motore: String? = nil, proposte: [PropostaVera]? = nil) {
        self.autore = autore
        self.testo = testo
        self.titolo = titolo
        self.motore = motore
        self.proposte = proposte
        data = Appuntamento.alMinuto(Date())
    }

    private enum CodingKeys: String, CodingKey { case id, autore, testo, titolo, motore, data, proposte, azione, modalita, scenario, conferma, clientela, fonti, voto, trenta, norme
        case promesse, lettura, confronto, copertura, resoconto
        case esitoRoutine, agendaOrari, agendaOrariScelto, agendaSpostamento, tagliando, mercatoClienti, mercatoBozze, stileVera
        case treLivelli, treLivelliLivello, pianoPassi
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        autore = try c.decodeIfPresent(Autore.self, forKey: .autore) ?? .vera
        testo = try c.decodeIfPresent(String.self, forKey: .testo) ?? ""
        titolo = try c.decodeIfPresent(String.self, forKey: .titolo)
        motore = try c.decodeIfPresent(String.self, forKey: .motore)
        data = try c.decodeIfPresent(Date.self, forKey: .data) ?? Date()
        proposte = try? c.decodeIfPresent([PropostaVera].self, forKey: .proposte)
        azione = try? c.decodeIfPresent(AzioneVera.self, forKey: .azione)
        modalita = try? c.decodeIfPresent(ModalitaVera.self, forKey: .modalita)
        scenario = try? c.decodeIfPresent(SchedaScenarioVera.self, forKey: .scenario)
        conferma = try? c.decodeIfPresent(SchedaConfermaVera.self, forKey: .conferma)
        clientela = try? c.decodeIfPresent(RisultatoClientela.self, forKey: .clientela)
        fonti = try? c.decodeIfPresent([FonteCifra].self, forKey: .fonti)
        voto = try? c.decodeIfPresent(Bool.self, forKey: .voto)
        trenta = try? c.decodeIfPresent(SchedaTrentaSecondi.self, forKey: .trenta)
        norme = try? c.decodeIfPresent(RispostaNorme.self, forKey: .norme)
        promesse = try? c.decodeIfPresent([String].self, forKey: .promesse)
        lettura = try? c.decodeIfPresent(EsitoSecondaLettura.self, forKey: .lettura)
        confronto = try? c.decodeIfPresent(String.self, forKey: .confronto)
        copertura = try? c.decodeIfPresent(String.self, forKey: .copertura)
        resoconto = try? c.decodeIfPresent(String.self, forKey: .resoconto)
        // Fase 4: ogni campo con try?, così uno rovinato non fa perdere il messaggio
        esitoRoutine = try? c.decodeIfPresent(EsitoRoutine.self, forKey: .esitoRoutine)
        agendaOrari = try? c.decodeIfPresent(RicercaOrari.self, forKey: .agendaOrari)
        agendaOrariScelto = try? c.decodeIfPresent(String.self, forKey: .agendaOrariScelto)
        agendaSpostamento = try? c.decodeIfPresent(SpostamentoBlocco.self, forKey: .agendaSpostamento)
        tagliando = try? c.decodeIfPresent(String.self, forKey: .tagliando)
        mercatoClienti = try? c.decodeIfPresent(EsitoMercatoVera.self, forKey: .mercatoClienti)
        mercatoBozze = try? c.decodeIfPresent(String.self, forKey: .mercatoBozze)
        stileVera = try? c.decodeIfPresent(SchedaStileVera.self, forKey: .stileVera)
        treLivelli = try? c.decodeIfPresent(String.self, forKey: .treLivelli)
        treLivelliLivello = try? c.decodeIfPresent(LivelloTreLivelli.self, forKey: .treLivelliLivello)
        pianoPassi = try? c.decodeIfPresent(PianoPassi.self, forKey: .pianoPassi)
    }
}

/// Una cosa fatta da Vera su richiesta: cosa ha creato e se l'hai annullata.
struct AzioneVera: Codable, Equatable {
    enum Tipo: String, Codable { case appuntamento, attivita, nota }

    var tipo: Tipo
    var id: String
    var annullata = false
}

/// Un'azione che Vera propone per il cliente, ricavata dai motori di analisi: diventa un'attività
/// o una bozza di proposta in Posizioni, sempre da completare e confermare dal consulente.
struct PropostaVera: Codable, Equatable, Identifiable {
    /// Chiave stabile ("protezione-vita", "obiettivo-<id>"…).
    var id: String
    var titolo: String
    /// Il perché, con le cifre dei motori.
    var perche: String
    /// Area della posizione da proporre (nil se è solo un'attività).
    var area: AreaPosizione?
    var rischio: RischioCoperto?
    var capitale: Double?
    var versamentoMensile: Double?
    var importo: Double?
    /// Cosa ne ha fatto il consulente.
    var attivitaId: String?
    var posizioneId: String?
}

/// Gli spunti pronti sotto la conversazione. Quelli di analisi leggono gli stessi motori dei
/// prospetti e dei report: i numeri di Vera e quelli dei documenti coincidono.
enum SpuntoVera: String, CaseIterable, Identifiable {
    case riepilogo, checkUp, proposte, incontro, prossimiPassi, resoconto, costi, resistenza, successione, pensione, protezione, liquidita, obiettivi, cambiare, documenti, scadenze

    var id: String { rawValue }

    var domanda: String {
        switch self {
        case .riepilogo: return "Fammi un riepilogo del cliente"
        case .checkUp: return "Fai il check-up del cliente"
        case .proposte: return "Cosa proporre al cliente?"
        case .incontro: return "Prepara il prossimo incontro"
        case .prossimiPassi: return "Elenca i prossimi passi"
        case .resoconto: return "Come stanno andando le posizioni?"
        case .costi: return "Quanto pesano i costi?"
        case .resistenza: return "Cosa succede se i mercati crollano?"
        case .successione: return "Cosa andrebbe agli eredi?"
        case .pensione: return "Spiegami il piano pensione"
        case .protezione: return "Dove è scoperta la protezione?"
        case .liquidita: return "Cosa fare della liquidità?"
        case .obiettivi: return "A che punto sono gli obiettivi?"
        case .cambiare: return "Conviene restare o cambiare?"
        case .documenti: return "Cosa dicono i documenti?"
        case .scadenze: return "Spiegami le scadenze in arrivo"
        }
    }

    var simbolo: String {
        switch self {
        case .riepilogo: return "≡"
        case .checkUp: return "●"
        case .proposte: return "✚"
        case .incontro: return "◷"
        case .prossimiPassi: return "✓"
        case .resoconto: return "↗"
        case .costi: return "%"
        case .resistenza: return "↘"
        case .successione: return "⚭"
        case .pensione: return "☂"
        case .protezione: return "◈"
        case .liquidita: return "€"
        case .obiettivi: return "◎"
        case .cambiare: return "⇄"
        case .documenti: return "▤"
        case .scadenze: return "!"
        }
    }

    /// Riconosce uno spunto anche se scritto a mano.
    static func da(_ testo: String) -> SpuntoVera? {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allCases.first { $0.domanda.lowercased() == t }
    }

    /// L'argomento di una domanda libera, dalle parole chiave (per la sintesi dai dati, che non capisce
    /// le frasi): "quanto paga di tasse se riscatta il fondo pensione?" → pensione.
    static func argomento(_ testo: String) -> SpuntoVera? {
        // Ogni chiave è l'inizio di una parola ("pension" sì in «pensione», no in «sospensione»);
        // con \b in fondo vale solo la parola intera («passi» sì, «passività» no).
        let parole: [(SpuntoVera, [String])] = [
            (.successione, ["eredi", "succession", "testament", "beneficiar", #"passaggio generazionale\b"#]),
            (.proposte, [#"proporre\b"#, "proposte da fare", "cosa gli propongo", "cosa le propongo", "opportunità"]),
            (.pensione, ["pension", "previdenz", "anticipazion", #"tfr\b"#, "deducib"]),
            (.cambiare, [#"cambiare\b"#, "sostitu", #"restare\b"#, #"switch\b"#, "conviene"]),
            (.documenti, [#"document[oi]\b"#, #"kid\b"#, "estratto conto", "set informativo"]),
            (.liquidita, ["liquidit", "conto corrente", "in scadenza", "salvadana"]),
            (.obiettivi, ["obiettiv", "traguard"]),
            (.protezione, ["protezion", "copertur", #"tcm\b"#, "caso morte", "invalidit"]),
            // Dopo pensione e protezione: «i costi della TCM», «rischia di perdere la pensione» restano lì
            (.costi, [#"cost[oai]\b"#, #"costano\b"#, "commission", "caricament"]),
            (.resistenza, ["croll", #"crisi\b"#, "stress", "resisten", "ribass", #"perder[eà]\b"#]),
            (.riepilogo, [#"patrimonio netto\b"#]),
            (.resoconto, ["rendiment", "andament", "guadagn", #"tasse\b"#, #"impost[ae]\b"#, #"netto\b"#, "resoconto"]),
            (.checkUp, ["check", "semaforo"]),
            (.scadenze, ["scadenz", #"scad[eo]\b"#]),
            (.incontro, [#"incontr[oi]\b"#, "appuntament"]),
            (.prossimiPassi, [#"passi\b"#, "cosa fare", "da fare"]),
            (.riepilogo, ["riepilog", "quadro", "situazione", "patrimonio"])
        ]
        let r = NSRange(testo.startIndex..., in: testo)
        return parole.first { voce in
            voce.1.contains { chiave in
                (try? NSRegularExpression(pattern: #"\b"# + chiave, options: [.caseInsensitive]))?.firstMatch(in: testo, range: r) != nil
            }
        }?.0
    }
}

/// Tutto ciò che Vera sa del cliente in questo momento: lo prepara l'app, con i suoi motori di calcolo.
struct FonteVera {
    let oggi: Date
    let nomeUtente: String
    let cliente: Cliente
    let posizioni: [Posizione]
    let appuntamenti: [Appuntamento]
    let attivita: [Attivita]
    let analisi: Analisi360
    let analisiSalvata: Bool
    let simulazioni: [Simulazione]
    var incontri: [Incontro] = []
    var obiettivi: [Obiettivo] = []
    /// Catalogo dei prodotti: penali, condizioni e costi per i calcoli fiscali e di sostituzione.
    var prodotti: [Prodotto] = []
    /// Documenti del cliente con i dati estratti (KID, polizze, estratti conto).
    var documenti: [Documento] = []
    /// Note del taccuino, le fissate prima e poi dalla più recente.
    var note: [Nota] = []
    /// Le due posizioni del confronto scelto in Prospetti e report (altrimenti la coppia predefinita)
    /// e gli anni della simulazione.
    var confronto: (attuale: String, alternativa: String)?
    var anniConfronto: Int?
}

extension SceltaProspetto {
    /// Lo spunto di Vera che spiega questo documento (nil se Vera non ne ha uno).
    var spuntoVera: SpuntoVera? {
        switch self {
        case .resoconto: return .resoconto
        case .sostituzione: return .cambiare
        case .previdenza: return .pensione
        case .protezione: return .protezione
        case .obiettivo: return .obiettivi
        case .liquidita: return .liquidita
        case .checkUp: return .checkUp
        case .resistenza: return .resistenza
        case .costi: return .costi
        case .successione: return .successione
        case .patrimonio: return .riepilogo
        case .riesame: return .incontro
        case .posizione, .confronto, .valutazione, .portafoglio, .fascicolo, .annoInsieme: return nil
        }
    }
}

struct RichiestaVera {
    let domanda: String
    let spunto: SpuntoVera?
    let fonte: FonteVera
    /// Ultimi messaggi della conversazione (per le domande di seguito).
    let storia: [MessaggioVera]
}

struct RispostaVera {
    var titolo: String?
    let testo: String
    var proposte: [PropostaVera]? = nil
}

enum DisponibilitaVera: Equatable {
    case pronto
    case nonDisponibile(String)

    var pronto: Bool { self == .pronto }

    var motivo: String? {
        if case .nonDisponibile(let m) = self { return m }
        return nil
    }
}

/// Un motore di Vera. Se ne possono aggiungere altri (per esempio un modello Qwen in locale)
/// senza toccare l'app: basta rispettare questo protocollo.
protocol MotoreVera {
    /// Nome mostrato nell'app e accanto alle risposte.
    var nome: String { get }
    /// Riga che spiega all'utente cosa fa il motore e dove lavora.
    var descrizione: String { get }
    var disponibilita: DisponibilitaVera { get }
    func rispondi(_ richiesta: RichiestaVera) async throws -> RispostaVera
}

struct ErroreVera: LocalizedError {
    let messaggio: String
    var errorDescription: String? { messaggio }
}
