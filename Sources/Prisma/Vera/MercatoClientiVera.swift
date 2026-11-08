import Foundation

// «Il mercato per i tuoi clienti» (Vera/BRIEF.md, funzione 14, fase 4; template «// 14 · IL MERCATO PER I TUOI CLIENTI»):
// quando succede qualcosa sui mercati, Vera dice quali clienti tocca, perché e cosa conviene fare con ciascuno, e
// prepara le bozze dei messaggi nello stile del consulente.
//
// Prima il codice, poi il modello (regola 5):
// 1. l'evento arriva dai dati di Mercato che Prisma ha già (serie BCE ed Eurostat, o importate da CSV, e gli avvisi di
//    MotoreMercato) oppure detto a parole a Vera («le borse hanno perso l'8% in una settimana», «la BCE taglia i tassi
//    di 25 punti base», «l'inflazione sale al 3%»): le regole riconoscono tipo e misura, senza modello;
// 2. le regole incrociano l'evento con le posizioni vere dei clienti (quota azionaria, liquidità in mesi di spese,
//    rivalutabili in scadenza, mutui variabili, obiettivo casa, obiettivi lontani, previdenza) e Prisma calcola ogni
//    cifra (regola 3): motivo, azione e numeri escono da qui, mai dal modello;
// 3. Qwen scrive solo le bozze dei messaggi, in JSON (regola 6): una bozza vale solo se ogni cifra è nei fatti di quel
//    cliente (CommentoVera.numeriConservati), senza promesse di rendimento, senza nomi di altri clienti e con il tu o il
//    Lei giusto; altrimenti resta la bozza fissa di Prisma, con l'avviso.
// Nessuna azione parte da qui (regola 2): il motore prepara le azioni per la scheda «Conferma» (messaggi da aprire in
// Mail o in Messaggi e attività), il consulente conferma. Nessun dato dei clienti esce dal Mac (regola 1): Qwen è sul
// Mac e Mercato scarica solo serie pubbliche (ClienteMercato.richiesta, che qui non si usa).
// Motore puro: dati e `oggi` entrano sempre come parametri.

// MARK: - L'evento

/// Il tipo di evento di mercato che Vera sa leggere per i clienti.
enum TipoEventoVera: String, Codable, CaseIterable {
    /// I tassi ufficiali della BCE si muovono (misura: variazione in punti percentuali, con il segno).
    case tassiBCE
    /// L'inflazione arriva a un livello (misura: il livello in %, «al 3%»).
    case inflazione
    /// Le borse si muovono (misura: variazione in %, con il segno).
    case borse

    var nome: String {
        switch self {
        case .tassiBCE: return "Tassi BCE"
        case .inflazione: return "Inflazione"
        case .borse: return "Borse"
        }
    }
}

/// Da dove arriva l'evento.
enum OrigineEventoVera: String, Codable {
    /// Detto a parole a Vera dal consulente (nessun dato BCE o Eurostat lo dice: per esempio le borse).
    case aParole
    /// Da una serie di Mercato (BCE, Eurostat, file CSV importato o scritta a mano).
    case serie
    /// Da un avviso di Mercato (MotoreMercato.avvisi).
    case avviso
}

/// Un evento di mercato, con la sua misura e la sua fonte. Non contiene dati dei clienti.
struct EventoMercatoVera: Codable, Equatable, Identifiable {
    var id: String
    var tipo: TipoEventoVera
    /// Tassi: variazione in punti (−0,25); inflazione: livello in % (3); borse: variazione in % (−8).
    var misura: Double
    /// Il verso: −1 giù, +1 su, 0 non detto (solo per l'inflazione: «l'inflazione è al 3%»).
    var verso: Int
    /// Inflazione: il dato di prima, se noto (dalla serie).
    var precedente: Double?
    /// «in una settimana», «da inizio anno»; nil se non detto.
    var periodo: String?
    var origine: OrigineEventoVera
    /// «Detto a Vera», «Fonte: BCE», «Fonte: Eurostat», «Fonte: … (file importato)».
    var fonte: String
    /// Il giorno del dato (o di quando il consulente l'ha detto).
    var data: Date
    /// La frase del consulente, per un evento detto a parole.
    var frase: String?
    var serieId: String?

    init(tipo: TipoEventoVera, misura: Double, verso: Int, precedente: Double? = nil, periodo: String? = nil,
         origine: OrigineEventoVera, fonte: String, data: Date, frase: String? = nil, serieId: String? = nil, cal: Calendar = .current) {
        self.tipo = tipo
        self.misura = misura
        self.verso = verso
        self.precedente = precedente
        self.periodo = periodo
        self.origine = origine
        self.fonte = fonte
        self.data = data
        self.frase = frase
        self.serieId = serieId
        id = "mercato-\(tipo.rawValue)-\(MotoreMercato.timbro(data, cal: cal))-\(Int((misura * 100).rounded()))"
    }

    var giu: Bool { verso < 0 }
    var su: Bool { verso > 0 }

    /// «La BCE taglia i tassi di 0,25 punti», «L'inflazione sale al 3%», «Le borse perdono l'8% in una settimana».
    var titolo: String { TestiMercatoClienti.titolo(self) }

    /// «la BCE ha tagliato i tassi di 0,25 punti», per il messaggio al cliente.
    var fraseMessaggio: String { TestiMercatoClienti.fraseMessaggio(self) }
}

/// Il risultato del riconoscimento di una frase.
enum RiconoscimentoEventoVera: Equatable {
    /// Tipo e misura chiari.
    case evento(EventoMercatoVera)
    /// Il tipo è chiaro, manca la misura o il verso: Vera fa la domanda.
    case incompleto(TipoEventoVera, domanda: String)
    /// Non è un evento di mercato.
    case nessuno
}

// MARK: - Clienti toccati

/// Una cifra calcolata da Prisma, con la sua etichetta: entra nei fatti per Qwen.
struct CifraMercatoVera: Codable, Equatable {
    var etichetta: String
    var valore: String
}

/// Cosa conviene fare con un cliente.
enum AzioneMercatoVera: String, Codable, CaseIterable {
    case chiamaOggi, rivediBilancio, decidiScadenza, preparaIpotesi, rassicura, ricalcolaObiettivo, rivediObiettivo,
         fissaRiesame, confrontaConto, ribilancia, parlaneIncontro, dueRighe

    /// Dal più urgente.
    var priorita: Int {
        switch self {
        case .chiamaOggi: return 0
        case .rivediBilancio, .decidiScadenza: return 1
        case .preparaIpotesi, .rassicura: return 2
        case .ricalcolaObiettivo, .rivediObiettivo, .fissaRiesame, .confrontaConto, .ribilancia, .parlaneIncontro: return 3
        case .dueRighe: return 4
        }
    }

    /// «Chiama Marco oggi», «Parlane giovedì 12 novembre». `nome` è il primo nome del cliente.
    func etichetta(nome: String, giorno: String?) -> String {
        switch self {
        case .chiamaOggi: return "Chiama \(nome) oggi"
        case .rivediBilancio: return "Rivedete la rata"
        case .decidiScadenza: return "Decidete prima della scadenza"
        case .preparaIpotesi: return "Prepara un'ipotesi"
        case .rassicura: return "Rassicura \(nome) con i numeri"
        case .ricalcolaObiettivo: return "Ricalcola l'obiettivo"
        case .rivediObiettivo: return "Rivedi l'obiettivo"
        case .fissaRiesame: return "Fissa il riesame"
        case .confrontaConto: return "Confronta il conto deposito"
        case .ribilancia: return "Valuta il ribilanciamento"
        case .parlaneIncontro: return giorno.map { "Parlane \($0)" } ?? "Parlane all'incontro"
        case .dueRighe: return "Manda due righe a \(nome)"
        }
    }

    /// L'azione chiede un'attività in agenda (le due righe bastano col messaggio).
    var conAttivita: Bool { self != .dueRighe }
}

/// Perché l'evento tocca un cliente: una regola, la frase con le cifre di Prisma e l'azione.
struct MotivoMercatoVera: Codable, Equatable {
    enum Regola: String, Codable, CaseIterable {
        case liquiditaFerma, contoDeposito, rivalutabileInScadenza, mutuoVariabile, obiettivoCasa, obbligazioni
        case liquiditaInflazione, obiettivoInflazione, rivalutabileSottoInflazione, previdenzaInflazione
        case azioniCalo, azioniRialzo
    }

    var regola: Regola
    /// «Il 52% del suo investito è in azioni (36.400 €): con un calo dell'8% sono circa 2.912 € in meno.»
    var testo: String
    var cifre: [CifraMercatoVera]
    var azione: AzioneMercatoVera
    var posizioni: [String] = []
    var obiettivoId: String?
    /// Il canale quando le posizioni del motivo sono di uno solo.
    var canale: Canale?
    /// Gli euro in gioco, per l'ordine (nil = solo qualitativo).
    var impatto: Double?
}

/// Un cliente toccato: i suoi motivi (il primo è il principale) e l'azione da fare.
struct ClienteToccatoVera: Codable, Equatable, Identifiable {
    var clienteId: String
    var nome: String
    var motivi: [MotivoMercatoVera]
    var azione: AzioneMercatoVera
    /// «Chiama Marco oggi».
    var etichettaAzione: String
    /// Il canale del cliente quando è uno solo (dei motivi, altrimenti delle posizioni in essere o della scheda).
    var canale: Canale?
    /// Il prossimo incontro entro `RegoleMercatoClienti.giorniIncontroVicino` giorni.
    var incontro: Date?
    /// Le spese al mese sono quelle predefinite di Analisi 360 (l'analisi del cliente non è salvata).
    var speseStimate: Bool

    var id: String { clienteId }
    var motivo: String { motivi.first?.testo ?? "" }
    /// Il canale della firma del messaggio: quello del motivo principale (il messaggio parla di lui), altrimenti
    /// quello del cliente. nil = canali misti senza un motivo di canale: niente firma, la sceglie il consulente.
    var canaleFirma: Canale? { motivi.first?.canale ?? canale }
    var impatto: Double { motivi.compactMap(\.impatto).map(abs).reduce(0, +) }
}

/// Un evento con i clienti che tocca.
struct EsitoMercatoVera: Codable, Equatable {
    var evento: EventoMercatoVera
    /// «Conti deposito e liquidità renderanno meno…».
    var sintesi: String
    /// Dal più urgente, al massimo `RegoleMercatoClienti.massimoClienti`.
    var toccati: [ClienteToccatoVera]
    /// I clienti toccati oltre il massimo (non in elenco).
    var oltre: Int
    var calcolatoIl: Date

    /// «Tocca 3 dei tuoi clienti», «Non tocca nessuno dei tuoi clienti».
    var intestazione: String {
        let n = toccati.count + oltre
        switch n {
        case 0: return "Non tocca nessuno dei tuoi clienti"
        case 1: return "Tocca uno dei tuoi clienti"
        default: return "Tocca \(n) dei tuoi clienti"
        }
    }

    /// «Prepara 3 messaggi».
    var etichettaBozze: String { toccati.count == 1 ? "Prepara il messaggio" : "Prepara \(toccati.count) messaggi" }
}

/// I dati che servono al motore (ricavati dall'archivio con `init(dati:oggi:)`).
struct DatiMercatoClienti {
    var oggi: Date
    var clienti: [Cliente]
    var posizioni: [Posizione]
    var obiettivi: [Obiettivo]
    var appuntamenti: [Appuntamento]
    /// Le analisi 360 salvate, per cliente (chi non ce l'ha usa la prima stesura ricavata dalle posizioni).
    var analisi: [String: Analisi360]
    var calendario = Calendar.current

    init(oggi: Date, clienti: [Cliente], posizioni: [Posizione], obiettivi: [Obiettivo] = [], appuntamenti: [Appuntamento] = [],
         analisi: [String: Analisi360] = [:], calendario: Calendar = .current) {
        self.oggi = oggi
        self.clienti = clienti
        self.posizioni = posizioni
        self.obiettivi = obiettivi
        self.appuntamenti = appuntamenti
        self.analisi = analisi
        self.calendario = calendario
    }

    init(dati: DatiPrisma, oggi: Date, calendario: Calendar = .current) {
        self.init(oggi: oggi, clienti: dati.clienti, posizioni: dati.posizioni, obiettivi: dati.obiettivi,
                  appuntamenti: dati.appuntamenti, analisi: dati.analisi, calendario: calendario)
    }
}

/// Le soglie fisse delle regole, tutte in un punto.
enum RegoleMercatoClienti {
    /// La liquidità «ferma» da tanti mesi di spese in su.
    static let mesiLiquiditaFerma = 6.0
    /// La liquidità che l'inflazione erode si segnala da tanti euro in su.
    static let liquiditaMinimaInflazione = 5_000.0
    /// Una rivalutabile scade «presto» entro tanti mesi.
    static let mesiScadenzaRivalutabili = 12
    /// Le obbligazioni contano per i tassi in salita da tanti euro in su.
    static let obbligazioniMinime = 10_000.0
    /// Un cliente è esposto alle borse con almeno tanti euro in azioni e tanta quota dell'investito (%).
    static let azioniMinime = 1_000.0
    static let quotaAzionariaMinima = 10.0
    /// Da questa quota azionaria (%) un calo merita una telefonata, un rialzo un ribilanciamento.
    static let quotaChiamaOggi = 50.0
    /// Tanti anni (o più) alla pensione: un calo delle borse non chiede mosse.
    static let anniOrizzonteLungo = 20
    /// Un obiettivo è «vicino» entro tanti anni.
    static let anniObiettivoVicino = 3
    /// Un obiettivo conta per l'inflazione da tanti anni in su.
    static let anniObiettivoInflazione = 2
    /// Un incontro è «vicino» entro tanti giorni: l'azione diventa «Parlane…».
    static let giorniIncontroVicino = 10
    /// L'obiettivo d'inflazione della BCE (%).
    static let inflazioneObiettivoBCE = 2.0
    /// Le borse: dalla serie, una variazione in una settimana conta da tanti punti % in su (se l'utente non ha soglie).
    static let borseMinimaSerie = 3.0
    /// Età della pensione se l'analisi non la dice.
    static let etaPensionePredefinita = IpotesiPrevidenza().etaPensione
    /// Clienti in elenco al massimo, e per ogni richiesta a Qwen.
    static let massimoClienti = 12
    static let clientiPerRichiesta = 6
    /// Parole al massimo in una bozza.
    static let paroleBozza = 90
}

/// Lo stile delle bozze: tono (tu o Lei), firme e tratti del consulente. Oggi nasce da Impostazioni › Messaggi;
/// con «Scrive come te» (funzione 15) arriveranno lo stile imparato e i tratti.
struct StileBozzeVera: Codable, Equatable {
    var tonoPredefinito: TonoMessaggio = .cordiale
    /// Dai del Lei da questa età in su (nil = sempre il tono predefinito).
    var etaDelLei: Int?
    /// Il tono scelto per un cliente (prevale su tutto).
    var toni: [String: TonoMessaggio] = [:]
    var firmaAlleanza = ""
    var firmaIndipendente = ""
    /// La chiusura prima della firma («A presto»); nil = nessuna.
    var chiusura: String?
    /// I tratti dello stile da dire a Qwen («Frasi brevi, una cosa per riga»).
    var tratti: [String] = []

    init() {}

    init(messaggi: ImpostazioniMessaggi) {
        firmaAlleanza = messaggi.firmaAlleanza
        firmaIndipendente = messaggi.firmaIndipendente
    }

    func tono(_ c: Cliente, oggi: Date, cal: Calendar = .current) -> TonoMessaggio {
        if let t = toni[c.id] { return t }
        if let soglia = etaDelLei, let n = c.dataNascita, let eta = cal.dateComponents([.year], from: n, to: oggi).year {
            return eta >= soglia ? .formale : .cordiale
        }
        return tonoPredefinito
    }

    func firma(_ k: Canale) -> String {
        (k == .alleanza ? firmaAlleanza : firmaIndipendente).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Una bozza di messaggio per un cliente toccato. Resta una bozza: si apre in Mail o in Messaggi dopo «Conferma».
struct BozzaMercatoVera: Codable, Equatable, Identifiable {
    var clienteId: String
    /// Il testo intero, con la chiusura e la firma (le aggiunge Prisma).
    var testo: String
    var canale: CanaleMessaggio
    var autore: AutoreMessaggio
    /// Il modello di Qwen che l'ha scritta; nil per la bozza di Prisma.
    var modello: String?
    /// Perché è rimasta la bozza di Prisma; nil se l'ha scritta Vera.
    var avviso: String?

    init(clienteId: String, testo: String, canale: CanaleMessaggio, autore: AutoreMessaggio, modello: String? = nil, avviso: String? = nil) {
        self.clienteId = clienteId
        self.testo = testo
        self.canale = canale
        self.autore = autore
        self.modello = modello
        self.avviso = avviso
    }

    var id: String { clienteId }
}

// MARK: - Il motore

enum MercatoClientiVera {
    // MARK: Riconoscere la frase

    /// La frase è un evento di mercato (per lo smistamento: prima delle domande generali a Qwen). Un evento a metà
    /// (manca la misura) conta solo se la frase dice un verbo di mercato forte («sale», «taglia», «crolla») e non è una
    /// domanda che chiede un dato o una spiegazione («Com'è andata la borsa oggi?», «Cos'è l'inflazione?», «Cosa ha
    /// deciso la BCE sui tassi?», «Quanto ha perso la borsa?»: vanno a Qwen). Per i tassi serve anche che la frase nomini
    /// la BCE, l'Euribor o il costo del denaro: «Che tasso ha il mutuo di Marco?» e «Il tasso del mutuo è salito?»
    /// restano domande normali («su», «aumentare», «riduco» non bastano).
    static func eUnEvento(_ frase: String) -> Bool {
        switch riconosci(frase, oggi: Date()) {
        case .evento: return true
        case .nessuno: return false
        case .incompleto(let genere, _):
            let t = normale(frase)
            guard versoForte(t), DateItaliane.cerca(domandaDiUnDato, t) == nil else { return false }
            // «tasso» da solo è anche quello di un mutuo o di un prestito («Il tasso del mutuo di Marco è salito?»):
            // per i tassi serve che la frase nomini la BCE, l'Euribor o il costo del denaro, il verbo forte non basta
            if genere == .tassiBCE { return DateItaliane.cerca(soggettoMercato, t) != nil }
            return true
        }
    }

    /// L'inizio delle domande che chiedono un dato o una spiegazione sul mercato (non annunciano un evento).
    private static let domandaDiUnDato = #"^(?:dimmi )?(?:com'[eè]|come (?:va|vanno|sta|stanno|[eè] andat|sono andat|si (?:[eè]|sono) moss)|quant[oa]\b|qual [eè]|quali sono|cos'[eè]|che cos'[eè]|(?:che )?cosa (?:ha|hanno|[eè]|sono|significa|vuol dire|succede)\b|perch[eé]\b|di quanto\b)"#

    /// La frase è un'ipotesi («Supponiamo che…», «Se la BCE tagliasse…», «Simula un crollo…», «Ipotizziamo…», «Mettiamo
    /// che…», «Facciamo finta che…», «E se…», «Cosa succederebbe…»): resta degli scenari (ScenariVera), non è un evento
    /// accaduto. Le aperture sono quelle degli scenari, sul loro testo semplificato (senza accenti).
    static func ipotesi(_ frase: String) -> Bool {
        DateItaliane.cerca(ScenariVera.apertura, ScenariVera.semplice(frase)) != nil
            || DateItaliane.cerca(#"\be se\b|cosa succede se|cosa succederebbe"#, normale(frase)) != nil
    }

    /// Le parole che nominano il mercato in modo esplicito (non «tasso» o «azioni» da soli).
    private static let soggettoMercato = #"\bbce\b|banca centrale|\beuribor\b|costo del denaro|inflazion|carovita|prezzi al consumo|\bhicp\b|\bipca\b|\bbors[ae]\b|\blistin[oi]\b|mercat[oi] azionar|piazza affari|\bftse\b|\bstoxx\b|s&p|\bnasdaq\b|\bdax\b|wall street"#

    /// Riconosce a regole tipo, verso e misura di un evento detto a parole.
    static func riconosci(_ frase: String, oggi: Date, cal: Calendar = .current) -> RiconoscimentoEventoVera {
        let t = normale(frase)
        // Una domanda su un cliente o un «e se» resta degli scenari (ScenariVera)
        guard !ipotesi(frase), let genere = tipo(t) else { return .nessuno }
        let periodo = DateItaliane.cerca(#"\b(in (?:una|un|due|tre|quattro|cinque|sei|\d+) (?:settiman[ae]|giorn[oi]|sedut[ae]|mes[ei]|ann[oi])|da inizio (?:anno|mese)|in giornata|nell'ultima settimana|nell'ultimo mese|questa settimana|oggi|ieri)\b"#, t)?.1[1]
        let detto = "Detto a Vera"
        switch genere {
        case .tassiBCE:
            guard let v = puntiTassi(t) else {
                return .incompleto(.tassiBCE, domanda: "Di quanti punti si sono mossi i tassi della BCE? Per esempio «la BCE taglia i tassi di 0,25 punti».")
            }
            let segno = v.segno ?? verso(t)
            guard segno != 0 else { return .incompleto(.tassiBCE, domanda: "La BCE ha alzato o abbassato i tassi?") }
            return .evento(EventoMercatoVera(tipo: .tassiBCE, misura: Double(segno) * v.valore, verso: segno, periodo: periodo,
                                             origine: .aParole, fonte: detto, data: oggi, frase: frase, cal: cal))
        case .inflazione:
            guard let v = livelloInflazione(t), (-5...30).contains(v.livello) else {
                return .incompleto(.inflazione, domanda: "A quanto è arrivata l'inflazione? Per esempio «l'inflazione sale al 3%».")
            }
            // «dal 2,5% al 3%»: il verso viene dal confronto, anche con un verbo neutro («passa»)
            var segno = verso(t)
            if let p = v.precedente, p != v.livello { segno = v.livello < p ? -1 : 1 }
            return .evento(EventoMercatoVera(tipo: .inflazione, misura: v.livello, verso: segno, precedente: v.precedente, periodo: periodo,
                                             origine: .aParole, fonte: detto, data: oggi, frase: frase, cal: cal))
        case .borse:
            guard let v = percentuale(t), v.valore > 0, v.valore <= 60 else {
                return .incompleto(.borse, domanda: "Di quanto si sono mosse le borse? Per esempio «le borse hanno perso l'8% in una settimana».")
            }
            let segno = v.segno ?? verso(t)
            guard segno != 0 else { return .incompleto(.borse, domanda: "Le borse sono salite o scese?") }
            return .evento(EventoMercatoVera(tipo: .borse, misura: Double(segno) * v.valore, verso: segno, periodo: periodo,
                                             origine: .aParole, fonte: detto, data: oggi, frase: frase, cal: cal))
        }
    }

    static func normale(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "\u{2212}", with: "-").replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: "\u{2014}", with: "-").replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    static func tipo(_ frase: String) -> TipoEventoVera? {
        // «il tasso d'inflazione» parla dell'inflazione, non dei tassi della BCE
        let t = frase.replacingOccurrences(of: #"\btass[oi] (?:d'|di |dell')\s?inflazion"#, with: "inflazion", options: .regularExpression)
        if DateItaliane.cerca(#"\btass[oi]\b|\beuribor\b|costo del denaro"#, t) != nil { return .tassiBCE }
        if DateItaliane.cerca(#"inflazion|carovita|prezzi al consumo|\bhicp\b|\bipca\b"#, t) != nil { return .inflazione }
        if DateItaliane.cerca(#"\bbors[ae]\b|\blistin[oi]\b|mercat[oi] azionar|piazza affari|\bftse\b|\bstoxx\b|s&p|\bnasdaq\b|\bdax\b|\bazionar[ie]\b|wall street"#, t) != nil { return .borse }
        // «azioni» da solo è anche «quali azioni mi suggerisci» o «posso aumentare le azioni di Marco»: vale per le borse
        // solo con un verbo di mercato forte («perdono», «crollano»), non con «su», «aumentare», «ridurre»
        if DateItaliane.cerca(#"\bazioni\b"#, t) != nil, versoForte(t), verso(t) != 0 { return .borse }
        if DateItaliane.cerca(#"\bbce\b|banca centrale"#, t) != nil, verso(t) != 0 { return .tassiBCE }
        return nil
    }

    private static let versoGiu = #"\btagli|\babbass|\bridu[cz]|\bscend|\bsces[aeio]\b|\bcal(?:a|ano|ato|ati|ata|ate|o|i)\b|\bperd|\bpers[aeio]\b|\bcroll|\bgi[uù]\b|\bribass|\bnegativ|\baffond|\bin rosso\b"#
    private static let versoSu = #"\balz|\baument|\bsal(?:e|gono|ita|ite|iti|ito|ire)\b|\brialz|\bcresc|\bguadagn|\bsu\b|\brimbalz|\bin verde\b|\brecord\b"#

    /// I verbi che dicono un movimento del mercato senza dubbi: niente «su», «aument», «ridu[cz]», che stanno anche
    /// nelle domande normali («che tasso c'è su questo mutuo», «posso aumentare le azioni»).
    private static let verbiForti = #"\btagli|\balz|\bcroll|\bperd|\bpers[aeio]\b|\bguadagn|\bsal(?:e|gono|ita|ite|iti|ito|ire)\b|\bscend|\bsces[aeio]\b|\bcal(?:a|ano|ato|ati|ata|ate|o|i)\b|\brialz|\bribass|\brimbalz|\baffond|\bin rosso\b|\bin verde\b"#

    /// La frase dice un verbo di mercato forte.
    static func versoForte(_ t: String) -> Bool {
        DateItaliane.cerca(verbiForti, t) != nil
    }

    /// −1, +1, oppure 0 se il verso non si capisce (o se la frase dice entrambi).
    static func verso(_ t: String) -> Int {
        let giu = DateItaliane.cerca(versoGiu, t) != nil
        let su = DateItaliane.cerca(versoSu, t) != nil
        if giu == su { return 0 }
        return giu ? -1 : 1
    }

    /// Un numero scritto all'italiana («0,25», «1.200», «8») o con il punto decimale («0.25»).
    static func numero(_ s: String) -> Double? {
        let x = s.trimmingCharacters(in: .whitespaces)
        if x.contains(",") { return Double(x.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")) }
        if DateItaliane.cerca(#"^\d+\.\d{3}$"#, x) != nil { return Double(x.replacingOccurrences(of: ".", with: "")) }
        return Double(x)
    }

    private static let numeriInParole: [String: Double] = [
        "uno": 1, "un": 1, "due": 2, "tre": 3, "quattro": 4, "cinque": 5, "sei": 6, "sette": 7, "otto": 8, "nove": 9,
        "dieci": 10, "dodici": 12, "quindici": 15, "venti": 20,
    ]

    /// La variazione dei tassi in punti percentuali (sempre positiva) e il segno se scritto («−0,25»).
    static func puntiTassi(_ t: String) -> (valore: Double, segno: Int?)? {
        if let (r, g) = DateItaliane.cerca(#"([+-]?)\s?(\d+(?:[.,]\d+)?)\s*(punti base|punto base|pb\b|bp\b|bps\b|basis point|punti percentuali|punto percentuale|punti|punto|%|per cento)"#, t),
           var v = numero(g[2]) {
            // «al 2%» è un livello, non una variazione: Vera chiede di quanto si sono mossi
            let prima = (t as NSString).substring(to: r.location)
            if DateItaliane.cerca(#"\b(?:al|all'|a|sul|sull')\s*$"#, prima) != nil { return nil }
            let unita = g[3]
            if unita.contains("base") || ["pb", "bp", "bps"].contains(unita) || unita.contains("basis") {
                v /= 100
            } else if unita.hasPrefix("punt"), !unita.contains("percentual"), v >= 5 {
                // «25 punti» si dice per i punti base
                v /= 100
            }
            guard v > 0, v <= 3 else { return nil }
            return (v, g[1] == "-" ? -1 : (g[1] == "+" ? 1 : nil))
        }
        if DateItaliane.cerca(#"\btre quarti di punto\b"#, t) != nil { return (0.75, nil) }
        if DateItaliane.cerca(#"\bun quarto di punto\b"#, t) != nil { return (0.25, nil) }
        if DateItaliane.cerca(#"\bmezzo punto\b"#, t) != nil { return (0.5, nil) }
        if DateItaliane.cerca(#"\bdi un punto\b"#, t) != nil { return (1, nil) }
        return nil
    }

    /// Una percentuale («8%», «−8%», «3 per cento», «otto per cento»), sempre positiva, con il segno se scritto.
    static func percentuale(_ t: String) -> (valore: Double, segno: Int?)? {
        if let (_, g) = DateItaliane.cerca(#"([+-]?)\s?(\d+(?:[.,]\d+)?)\s*(?:%|per ?cento)"#, t), let v = numero(g[2]) {
            return (v, g[1] == "-" ? -1 : (g[1] == "+" ? 1 : nil))
        }
        let parole = numeriInParole.keys.sorted { $0.count > $1.count }.joined(separator: "|")
        if let (_, g) = DateItaliane.cerca(#"\b("# + parole + #")\s+per ?cento\b"#, t), let v = numeriInParole[g[1]] {
            return (v, nil)
        }
        return nil
    }

    /// Il livello dell'inflazione detto a parole e, se c'è, quello di prima: «dal 2,5% al 3%» → 3 (prima 2,5).
    /// Vale la percentuale dopo «al/all'/a»; con solo «dal 2,5%» serve un'altra percentuale dopo, altrimenti nil.
    static func livelloInflazione(_ t: String) -> (livello: Double, precedente: Double?)? {
        let cifra = #"([+-]?)\s?(\d+(?:[.,]\d+)?)\s*(?:%|per ?cento)"#
        func valore(_ g: [String]) -> Double? { numero(g[2]).map { g[1] == "-" ? -$0 : $0 } }
        let dal = DateItaliane.cerca(#"\b(?:dal|dall')\s?"# + cifra, t)
        let prima = dal.flatMap { valore($0.1) }
        if let (_, g) = DateItaliane.cerca(#"\b(?:al|all'|a)\s?"# + cifra, t), let v = valore(g) { return (v, prima) }
        if let (r, _) = dal {
            let dopo = (t as NSString).substring(from: r.location + r.length)
            guard let v = percentuale(dopo) else { return nil }
            return (v.segno == -1 ? -v.valore : v.valore, prima)
        }
        guard let v = percentuale(t) else { return nil }
        return (v.segno == -1 ? -v.valore : v.valore, nil)
    }

    // MARK: Gli eventi dai dati di Mercato (BCE, Eurostat, CSV)

    /// Gli eventi che le serie di Mercato dicono oggi: tassi ufficiali che si sono mossi sull'ultimo dato, inflazione
    /// che è cambiata, indici azionari mossi in una settimana oltre la soglia. Le soglie dell'utente (Impostazioni ›
    /// Mercato) valgono se ci sono; i dati vecchi non contano (`FrequenzaMercato.giorniFreschezza`).
    static func eventi(archivio: ArchivioMercato, impostazioni: ImpostazioniMercato, oggi: Date, cal: Calendar = .current) -> [EventoMercatoVera] {
        var elenco: [EventoMercatoVera] = []
        for s in archivio.serie {
            guard let ultimo = s.ultimo, recente(ultimo.data, giorni: s.frequenza.giorniFreschezza, oggi: oggi, cal: cal) else { continue }
            switch s.tipo {
            case .tassoUfficiale:
                guard s.punti.count >= 2 else { continue }
                let delta = ((ultimo.valore - s.punti[s.punti.count - 2].valore) * 100).rounded() / 100
                guard delta != 0, abs(delta) >= (impostazioni.variazioneTassi ?? 0.01) - 1e-9, abs(delta) <= 3 else { continue }
                elenco.append(EventoMercatoVera(tipo: .tassiBCE, misura: delta, verso: delta < 0 ? -1 : 1, origine: .serie,
                                                fonte: s.citazione, data: ultimo.data, serieId: s.id, cal: cal))
            case .inflazione:
                guard s.punti.count >= 2 else { continue }
                let prima = s.punti[s.punti.count - 2].valore
                let delta = ((ultimo.valore - prima) * 10).rounded() / 10
                guard delta != 0 else { continue }
                elenco.append(EventoMercatoVera(tipo: .inflazione, misura: (ultimo.valore * 10).rounded() / 10, verso: delta < 0 ? -1 : 1,
                                                precedente: (prima * 10).rounded() / 10, origine: .serie, fonte: s.citazione,
                                                data: ultimo.data, serieId: s.id, cal: cal))
            case .indiceAzionario:
                // Il punto di confronto deve stare davvero intorno a una settimana prima (quattro giorni di margine per
                // i festivi: dopo Pasquetta l'ultimo dato è del giovedì prima di Venerdì Santo): con una serie mensile il
                // punto precedente è di un mese prima e «in una settimana» sarebbe falso
                guard let inizio = cal.date(byAdding: .day, value: -7, to: ultimo.data),
                      let finestra = cal.date(byAdding: .day, value: -4, to: cal.startOfDay(for: inizio)),
                      let prima = MotoreMercato.valore(s.punti, al: inizio, cal: cal), prima.valore > 0, prima.data < ultimo.data,
                      prima.data >= finestra else { continue }
                let delta = ((ultimo.valore / prima.valore - 1) * 1000).rounded() / 10
                guard abs(delta) >= (impostazioni.variazioneIndici ?? RegoleMercatoClienti.borseMinimaSerie) - 1e-9, abs(delta) <= 60 else { continue }
                elenco.append(EventoMercatoVera(tipo: .borse, misura: delta, verso: delta < 0 ? -1 : 1, periodo: "in una settimana",
                                                origine: .serie, fonte: s.citazione, data: ultimo.data, serieId: s.id, cal: cal))
            default:
                continue
            }
        }
        // Due serie per lo stesso dato (l'inflazione Italia da BCE e da Eurostat, i due tassi ufficiali che si muovono
        // insieme) fanno un evento solo: si fondono solo gli eventi con lo stesso id (stesso tipo, giorno e misura).
        // Due serie diverse nello stesso giorno (inflazione Italia ed euro, due tassi mossi di quantità diverse) restano due
        var visti: Set<String> = []
        return elenco
            .sorted { (x: EventoMercatoVera, y: EventoMercatoVera) -> Bool in
                if x.data != y.data { return x.data > y.data }
                if x.id != y.id { return x.id < y.id }
                return (x.serieId ?? "") < (y.serieId ?? "")
            }
            .filter { e in
                visti.insert(e.id).inserted
            }
    }

    /// L'evento di un avviso di Mercato (variazione di una serie): tassi, inflazione (con il livello dell'ultimo dato)
    /// o borse. nil per gli avvisi di un ISIN (calo, distanza, cedola): quelli sono già di un cliente.
    static func evento(da a: AvvisoMercato, archivio: ArchivioMercato, cal: Calendar = .current) -> EventoMercatoVera? {
        guard a.tipo == .variazioneSerie, let id = a.serieId, let s = archivio.serie(id), a.valore.isFinite, a.valore != 0 else { return nil }
        let verso = a.valore < 0 ? -1 : 1
        switch s.tipo {
        case .tassoUfficiale:
            return EventoMercatoVera(tipo: .tassiBCE, misura: (a.valore * 100).rounded() / 100, verso: verso, origine: .avviso,
                                     fonte: a.fonte, data: a.dataDato, serieId: id, cal: cal)
        case .inflazione:
            guard let livello = MotoreMercato.valore(s.punti, al: a.dataDato, cal: cal)?.valore else { return nil }
            return EventoMercatoVera(tipo: .inflazione, misura: (livello * 10).rounded() / 10, verso: verso,
                                     precedente: ((livello - a.valore) * 10).rounded() / 10, origine: .avviso, fonte: a.fonte,
                                     data: a.dataDato, serieId: id, cal: cal)
        case .indiceAzionario:
            return EventoMercatoVera(tipo: .borse, misura: (a.valore * 10).rounded() / 10, verso: verso, origine: .avviso,
                                     fonte: a.fonte, data: a.dataDato, serieId: id, cal: cal)
        default:
            return nil
        }
    }

    private static func recente(_ data: Date, giorni: Int, oggi: Date, cal: Calendar) -> Bool {
        guard let limite = cal.date(byAdding: .day, value: -giorni, to: cal.startOfDay(for: oggi)) else { return false }
        return data >= limite && cal.startOfDay(for: data) <= cal.startOfDay(for: oggi)
    }

    // MARK: Chi tocca

    /// Il quadro di un cliente, calcolato da Prisma.
    struct Quadro {
        var inEssere: [Posizione]
        var liquidita: Double
        var spese: Double
        var speseStimate: Bool
        /// Mesi di spese in liquidità, per difetto al decimo (nil senza spese).
        var mesi: Double?
        /// Investimento, risparmio e previdenza in essere.
        var investito: Double
        var azioni: Double
        var obbligazioni: Double
        /// Le posizioni con una parte in azioni.
        var conAzioni: [Posizione]
        var eta: Int?
        var anniPensione: Int?
        var propensione: ProfiloInvestitore.Propensione?

        /// La quota azionaria dell'investito, in % intera.
        var quotaAzionaria: Double { investito > 0 ? (azioni / investito * 100).rounded() : 0 }
    }

    static func quadro(_ c: Cliente, _ d: DatiMercatoClienti) -> Quadro {
        let cal = d.calendario
        let tutte = d.posizioni.filter { $0.clienteId == c.id }
        let inEssere = tutte.filter { $0.stato == .inEssere }
        let liquidita = inEssere.filter { $0.area == .liquidita }.reduce(0) { $0 + max(0, $1.valore) }
        let analisi = d.analisi[c.id] ?? Analisi360(cliente: c, posizioni: tutte)
        let spese = max(0, analisi.protezione.fabbisognoMensile)
        let mesi: Double? = spese > 0 ? (liquidita / spese * 10).rounded(.down) / 10 : nil
        var investito = 0.0, azioni = 0.0, obbligazioni = 0.0
        var conAzioni: [Posizione] = []
        for p in inEssere where p.area.proiettabile && p.valore > 0 {
            investito += p.valore
            guard let k = MotoreResistenza.composizione(p) else { continue }
            if k.azioni > 0 {
                azioni += p.valore * k.azioni
                conAzioni.append(p)
            }
            obbligazioni += p.valore * (k.governativi + k.societarie)
        }
        let eta = c.dataNascita.flatMap { cal.dateComponents([.year], from: $0, to: d.oggi).year }
        let etaPensione = d.analisi[c.id]?.previdenza.etaPensione ?? RegoleMercatoClienti.etaPensionePredefinita
        return Quadro(inEssere: inEssere, liquidita: liquidita, spese: spese, speseStimate: d.analisi[c.id] == nil, mesi: mesi,
                      investito: investito, azioni: azioni, obbligazioni: obbligazioni, conAzioni: conAzioni, eta: eta,
                      anniPensione: eta.map { max(0, etaPensione - $0) }, propensione: c.profilo.propensione)
    }

    /// I clienti che l'evento tocca, con motivo, azione e cifre di Prisma. Ordine: dal più urgente, poi dagli euro
    /// in gioco, poi per nome.
    static func toccati(_ e: EventoMercatoVera, dati d: DatiMercatoClienti) -> EsitoMercatoVera {
        var elenco: [ClienteToccatoVera] = []
        for c in d.clienti {
            let q = quadro(c, d)
            var motivi = regole(e, cliente: c, quadro: q, dati: d)
            guard !motivi.isEmpty else { continue }
            motivi.sort { a, b in
                if a.azione.priorita != b.azione.priorita { return a.azione.priorita < b.azione.priorita }
                return abs(a.impatto ?? 0) > abs(b.impatto ?? 0)
            }
            let incontro = prossimoIncontro(c.id, d)
            var azione = motivi[0].azione
            // Con un incontro vicino se ne parla lì (tranne quando serve chiamare oggi)
            if incontro != nil, azione != .chiamaOggi, azione != .dueRighe { azione = .parlaneIncontro }
            let giorno = incontro.map { DateItaliane.descrivi($0, conOra: false, oggi: d.oggi, cal: d.calendario) }
            let canali = Set(motivi.compactMap(\.canale))
            let canale = canali.count == 1 ? canali.first : MotoreOccasioniMessaggi.canaleComune(c, d.posizioni.filter { $0.clienteId == c.id })
            elenco.append(ClienteToccatoVera(clienteId: c.id, nome: c.nome, motivi: motivi, azione: azione,
                                             etichettaAzione: azione.etichetta(nome: ModelliMessaggi.primoNome(c.nome), giorno: giorno),
                                             canale: canale, incontro: incontro, speseStimate: q.speseStimate))
        }
        elenco.sort { a, b in
            if a.azione.priorita != b.azione.priorita { return a.azione.priorita < b.azione.priorita }
            if a.impatto != b.impatto { return a.impatto > b.impatto }
            if a.nome != b.nome { return a.nome.localizedCompare(b.nome) == .orderedAscending }
            return a.clienteId < b.clienteId
        }
        let massimo = RegoleMercatoClienti.massimoClienti
        return EsitoMercatoVera(evento: e, sintesi: TestiMercatoClienti.sintesi(e), toccati: Array(elenco.prefix(massimo)),
                                oltre: max(0, elenco.count - massimo), calcolatoIl: d.oggi)
    }

    /// Il primo incontro in agenda con il cliente da oggi a `giorniIncontroVicino` giorni.
    static func prossimoIncontro(_ cliente: String, _ d: DatiMercatoClienti) -> Date? {
        let inizio = d.calendario.startOfDay(for: d.oggi)
        guard let fine = d.calendario.date(byAdding: .day, value: RegoleMercatoClienti.giorniIncontroVicino + 1, to: inizio) else { return nil }
        return d.appuntamenti.filter { $0.clienteId == cliente && $0.stato == .pianificato && $0.inizio >= d.oggi && $0.inizio < fine }
            .map(\.inizio).min()
    }

    /// Le regole per tipo di evento.
    static func regole(_ e: EventoMercatoVera, cliente c: Cliente, quadro q: Quadro, dati d: DatiMercatoClienti) -> [MotivoMercatoVera] {
        switch e.tipo {
        case .tassiBCE: return regoleTassi(e, c, q, d)
        case .inflazione: return regoleInflazione(e, c, q, d)
        case .borse: return regoleBorse(e, c, q, d)
        }
    }

    private static func mesiTra(_ da: Date, _ a: Date, _ cal: Calendar) -> Int {
        cal.dateComponents([.month], from: cal.startOfDay(for: da), to: cal.startOfDay(for: a)).month ?? 0
    }

    private static func canale(_ posizioni: [Posizione]) -> Canale? {
        let k = Set(posizioni.map(\.canale))
        return k.count == 1 ? k.first : nil
    }

    private static func mutuoVariabile(_ p: Posizione) -> Bool {
        p.area == .debiti && (p.tipologia + " " + p.nome).lowercased().contains("variabil")
    }

    // Tassi BCE

    private static func regoleTassi(_ e: EventoMercatoVera, _ c: Cliente, _ q: Quadro, _ d: DatiMercatoClienti) -> [MotivoMercatoVera] {
        typealias T = TestiMercatoClienti
        let cal = d.calendario
        let giu = e.giu
        let delta = e.misura
        var m: [MotivoMercatoVera] = []

        // Il mutuo variabile: la rata nuova con il tasso spostato, sul debito residuo e i mesi che restano
        for p in q.inEssere where mutuoVariabile(p) {
            let quota = min(100, max(0, p.quotaDebito ?? 100)) / 100
            var cifre: [CifraMercatoVera] = [CifraMercatoVera(etichetta: "Debito residuo", valore: T.euro(p.valore * quota))]
            var testo = giu ? "La rata del mutuo variabile può scendere." : "La rata del mutuo variabile può salire."
            var impatto: Double?
            if let s = p.scadenza, let tasso = p.tassoDebito, p.valore > 0 {
                let mesi = mesiTra(d.oggi, s, cal)
                if mesi > 0 {
                    let prima = MotoreProtezioneFamiglia.rataDebito(capitale: p.valore, tasso: tasso, mesi: mesi) * quota
                    let dopo = MotoreProtezioneFamiglia.rataDebito(capitale: p.valore, tasso: max(0, tasso + delta), mesi: mesi) * quota
                    let diff = (dopo - prima).rounded()
                    if abs(diff) >= 1 {
                        testo = "La rata del mutuo variabile (\(T.euro(prima)) al mese) può \(giu ? "scendere" : "salire") di circa \(T.euro(abs(diff))) al mese."
                        cifre.append(CifraMercatoVera(etichetta: "Rata di oggi", valore: T.euro(prima)))
                        cifre.append(CifraMercatoVera(etichetta: giu ? "Rata più bassa di circa" : "Rata più alta di circa", valore: T.euro(abs(diff))))
                        impatto = abs(diff) * 12
                    }
                }
            }
            m.append(MotivoMercatoVera(regola: .mutuoVariabile, testo: testo, cifre: cifre, azione: giu ? .dueRighe : .rivediBilancio,
                                       posizioni: [p.id], canale: p.canale, impatto: impatto))
        }

        // La rivalutabile in scadenza: il rinnovo parte dai rendimenti nuovi
        let inizio = cal.startOfDay(for: d.oggi)
        let limite = cal.date(byAdding: .month, value: RegoleMercatoClienti.mesiScadenzaRivalutabili, to: inizio) ?? inizio
        for p in q.inEssere where p.gestioneSeparata {
            guard let s = p.scadenza, s >= inizio, s <= limite else { continue }
            m.append(MotivoMercatoVera(regola: .rivalutabileInScadenza,
                                       testo: "«\(p.nome)» (\(T.euro(p.valore))) scade a \(T.meseAnno(s)): il rinnovo partirà da rendimenti più \(giu ? "bassi" : "alti").",
                                       cifre: [CifraMercatoVera(etichetta: "Valore", valore: T.euro(p.valore)),
                                               CifraMercatoVera(etichetta: "Scadenza", valore: T.meseAnno(s))],
                                       azione: .decidiScadenza, posizioni: [p.id], canale: p.canale, impatto: p.valore))
        }

        // La liquidità ferma: oltre i mesi di spese della soglia
        if let mesi = q.mesi, mesi >= RegoleMercatoClienti.mesiLiquiditaFerma, q.liquidita > 0 {
            let conti = q.inEssere.filter { $0.area == .liquidita }
            var cifre = [CifraMercatoVera(etichetta: "Liquidità", valore: T.euro(q.liquidita)),
                         CifraMercatoVera(etichetta: "Mesi di spese", valore: T.mesi(mesi)),
                         CifraMercatoVera(etichetta: "Spese al mese" + (q.speseStimate ? " (stimate)" : ""), valore: T.euro(q.spese))]
            if giu {
                let interessi = (q.liquidita * abs(delta) / 100).rounded()
                cifre.append(CifraMercatoVera(etichetta: "Interessi in meno all'anno, se il conto segue la BCE", valore: T.euro(interessi)))
                m.append(MotivoMercatoVera(regola: .liquiditaFerma,
                                           testo: "Ha \(T.mesi(mesi)) di spese ferme in liquidità (\(T.euro(q.liquidita))): renderanno meno, circa \(T.euro(interessi)) di interessi all'anno se il conto segue la BCE.",
                                           cifre: cifre, azione: .preparaIpotesi, posizioni: conti.map(\.id), canale: canale(conti), impatto: interessi))
            } else {
                m.append(MotivoMercatoVera(regola: .contoDeposito,
                                           testo: "Ha \(T.mesi(mesi)) di spese in liquidità (\(T.euro(q.liquidita))): i conti deposito possono rendere di più.",
                                           cifre: cifre, azione: .confrontaConto, posizioni: conti.map(\.id), canale: canale(conti),
                                           impatto: (q.liquidita * abs(delta) / 100).rounded()))
            }
        }

        // L'obiettivo casa: il mutuo che servirà costa meno (o di più)
        for o in d.obiettivi where o.clienteId == c.id && o.area == .casa && o.scadenza > d.oggi && o.raggiuntoIl == nil {
            m.append(MotivoMercatoVera(regola: .obiettivoCasa,
                                       testo: "Per «\(o.titolo)» (\(T.euro(o.importo)) entro \(T.meseAnno(o.scadenza))) un mutuo costerà \(giu ? "meno" : "di più").",
                                       cifre: [CifraMercatoVera(etichetta: "Obiettivo", valore: T.euro(o.importo)),
                                               CifraMercatoVera(etichetta: "Entro", valore: T.meseAnno(o.scadenza))],
                                       azione: .ricalcolaObiettivo, obiettivoId: o.id, impatto: nil))
        }

        // Le obbligazioni in portafoglio: con i tassi in salita i prezzi scendono per un po'
        if !giu, q.obbligazioni >= RegoleMercatoClienti.obbligazioniMinime {
            let conObbligazioni = q.inEssere.filter { p in
                guard p.area.proiettabile, let k = MotoreResistenza.composizione(p) else { return false }
                return k.governativi + k.societarie > 0
            }
            m.append(MotivoMercatoVera(regola: .obbligazioni,
                                       testo: "Ha circa \(T.euro(q.obbligazioni)) in obbligazioni: con i tassi più alti i prezzi possono scendere per un po'.",
                                       cifre: [CifraMercatoVera(etichetta: "In obbligazioni", valore: T.euro(q.obbligazioni))],
                                       azione: .rassicura, posizioni: conObbligazioni.map(\.id), canale: canale(conObbligazioni), impatto: nil))
        }
        return m
    }

    // Inflazione

    private static func regoleInflazione(_ e: EventoMercatoVera, _ c: Cliente, _ q: Quadro, _ d: DatiMercatoClienti) -> [MotivoMercatoVera] {
        typealias T = TestiMercatoClienti
        let cal = d.calendario
        let x = e.misura
        guard x > 0 else { return [] }
        let al = T.al(x)
        var m: [MotivoMercatoVera] = []

        // La liquidità perde potere d'acquisto
        if q.liquidita >= RegoleMercatoClienti.liquiditaMinimaInflazione {
            let perdita = (q.liquidita * x / 100).rounded()
            let conti = q.inEssere.filter { $0.area == .liquidita }
            let ferma = (q.mesi ?? 0) >= RegoleMercatoClienti.mesiLiquiditaFerma
            m.append(MotivoMercatoVera(regola: .liquiditaInflazione,
                                       testo: "Ha \(T.euro(q.liquidita)) fermi in liquidità: con l'inflazione \(al) perdono circa \(T.euro(perdita)) di potere d'acquisto in un anno.",
                                       cifre: [CifraMercatoVera(etichetta: "Liquidità", valore: T.euro(q.liquidita)),
                                               CifraMercatoVera(etichetta: "Potere d'acquisto perso in un anno", valore: T.euro(perdita))],
                                       azione: ferma ? .preparaIpotesi : .fissaRiesame, posizioni: conti.map(\.id), canale: canale(conti), impatto: perdita))
        }

        // Gli obiettivi lontani costano di più (importi in euro di oggi)
        for o in d.obiettivi where o.clienteId == c.id && o.raggiuntoIl == nil && o.importo > 0 {
            let mesi = mesiTra(d.oggi, o.scadenza, cal)
            guard mesi >= RegoleMercatoClienti.anniObiettivoInflazione * 12 else { continue }
            let anni = Double(mesi) / 12
            let costo = (o.importo * pow(1 + x / 100, anni) / 100).rounded() * 100
            let interi = Int(anni.rounded())
            m.append(MotivoMercatoVera(regola: .obiettivoInflazione,
                                       testo: "«\(o.titolo)»: \(T.euro(o.importo)) di oggi fra \(T.anni(interi)), con l'inflazione \(al) all'anno, sarebbero circa \(T.euro(costo)).",
                                       cifre: [CifraMercatoVera(etichetta: "Obiettivo in euro di oggi", valore: T.euro(o.importo)),
                                               CifraMercatoVera(etichetta: "Fra", valore: T.anni(interi)),
                                               CifraMercatoVera(etichetta: "Costo con l'inflazione", valore: T.euro(costo))],
                                       azione: .rivediObiettivo, obiettivoId: o.id, impatto: costo - o.importo))
        }

        // Le rivalutabili che rendono meno dell'inflazione
        for p in q.inEssere where p.gestioneSeparata {
            guard let r = p.rendimentoAtteso, r < x else { continue }
            m.append(MotivoMercatoVera(regola: .rivalutabileSottoInflazione,
                                       testo: "«\(p.nome)» rende circa \(T.percento(r)) lordo: meno dell'inflazione \(al).",
                                       cifre: [CifraMercatoVera(etichetta: "Rendimento lordo ipotizzato", valore: T.percento(r)),
                                               CifraMercatoVera(etichetta: "Valore", valore: T.euro(p.valore))],
                                       azione: .fissaRiesame, posizioni: [p.id], canale: p.canale,
                                       impatto: (p.valore * (x - r) / 100).rounded()))
        }

        // La previdenza: la pensione integrativa di domani vale meno (solo oltre l'obiettivo della BCE)
        if x > RegoleMercatoClienti.inflazioneObiettivoBCE,
           let p = q.inEssere.filter({ $0.area == .previdenza && $0.valore > 0 }).max(by: { $0.valore < $1.valore }) {
            m.append(MotivoMercatoVera(regola: .previdenzaInflazione,
                                       testo: "«\(p.nome)» (\(T.euro(p.valore))): con l'inflazione \(al) la pensione integrativa di domani vale meno di oggi.",
                                       cifre: [CifraMercatoVera(etichetta: "Valore", valore: T.euro(p.valore))],
                                       azione: .rivediObiettivo, posizioni: [p.id], canale: p.canale, impatto: nil))
        }
        return m
    }

    // Borse

    private static func regoleBorse(_ e: EventoMercatoVera, _ c: Cliente, _ q: Quadro, _ d: DatiMercatoClienti) -> [MotivoMercatoVera] {
        typealias T = TestiMercatoClienti
        let cal = d.calendario
        let quota = q.quotaAzionaria
        guard q.azioni >= RegoleMercatoClienti.azioniMinime, quota >= RegoleMercatoClienti.quotaAzionariaMinima else { return [] }
        let x = abs(e.misura)
        let variazione = (q.azioni * x / 100).rounded()
        let posizioni = q.conAzioni.map(\.id)
        var cifre = [CifraMercatoVera(etichetta: "Quota in azioni dell'investito", valore: T.percento(quota)),
                     CifraMercatoVera(etichetta: "In azioni", valore: T.euro(q.azioni)),
                     CifraMercatoVera(etichetta: e.giu ? "Calo stimato" : "Rialzo stimato", valore: T.euro(variazione))]

        if e.su {
            guard quota >= RegoleMercatoClienti.quotaChiamaOggi else { return [] }
            return [MotivoMercatoVera(regola: .azioniRialzo,
                                      testo: "Il \(T.percento(quota)) del suo investito è in azioni (\(T.euro(q.azioni))): con un rialzo \(T.del(x)) sono circa \(T.euro(variazione)) in più.",
                                      cifre: cifre, azione: .ribilancia, posizioni: posizioni, canale: canale(q.conAzioni), impatto: variazione)]
        }

        var testo = "Il \(T.percento(quota)) del suo investito è in azioni (\(T.euro(q.azioni))): con un calo \(T.del(x)) sono circa \(T.euro(variazione)) in meno."
        let azione: AzioneMercatoVera
        // Un obiettivo vicino che lavora con posizioni in azioni
        let idsAzioni = Set(posizioni)
        let vicino = d.obiettivi.filter { o in
            o.clienteId == c.id && o.raggiuntoIl == nil && o.scadenza > d.oggi
                && mesiTra(d.oggi, o.scadenza, cal) <= RegoleMercatoClienti.anniObiettivoVicino * 12
                && o.posizioniCollegate.contains { idsAzioni.contains($0) }
        }.min { $0.scadenza < $1.scadenza }
        if let o = vicino {
            let anni = max(1, Int((Double(mesiTra(d.oggi, o.scadenza, cal)) / 12).rounded()))
            testo += " L'obiettivo «\(o.titolo)» è fra \(T.anni(anni))."
            cifre.append(CifraMercatoVera(etichetta: "Obiettivo vicino", valore: "\(o.titolo), fra \(T.anni(anni))"))
            azione = .chiamaOggi
        } else if q.propensione == .prudente {
            testo += " Il suo profilo è prudente."
            azione = .chiamaOggi
        } else if let a = q.anniPensione, a >= RegoleMercatoClienti.anniOrizzonteLungo {
            testo += " Ha \(T.anni(a)) davanti per la pensione: nessuna mossa da fare."
            cifre.append(CifraMercatoVera(etichetta: "Anni alla pensione", valore: T.anni(a)))
            azione = .dueRighe
        } else if quota >= RegoleMercatoClienti.quotaChiamaOggi {
            azione = .chiamaOggi
        } else {
            azione = .rassicura
        }
        return [MotivoMercatoVera(regola: .azioniCalo, testo: testo, cifre: cifre, azione: azione, posizioni: posizioni,
                                  obiettivoId: vicino?.id, canale: canale(q.conAzioni), impatto: variazione)]
    }

    // MARK: La risposta in chat

    /// La risposta di Vera in chat, tutta di Prisma: l'evento, la sintesi, i clienti con motivo e azione.
    static func testoChat(_ esito: EsitoMercatoVera) -> String {
        var righe = ["\(esito.evento.titolo) · \(esito.evento.fonte)", esito.sintesi, ""]
        guard !esito.toccati.isEmpty else {
            righe.append("Non tocca nessuno dei tuoi clienti: nessuna posizione in essere è esposta a questo evento.")
            return righe.joined(separator: "\n")
        }
        righe.append(esito.intestazione + ":")
        for t in esito.toccati {
            righe.append("• \(t.nome): \(t.motivo) → \(t.etichettaAzione)")
        }
        if esito.oltre > 0 { righe.append("E altri \(esito.oltre) clienti: li trovi nell'elenco completo.") }
        if esito.toccati.contains(where: \.speseStimate),
           esito.toccati.contains(where: { $0.motivi.contains { m in m.regola == .liquiditaFerma || m.regola == .contoDeposito } }) {
            righe.append("Per chi non ha l'analisi 360 salvata i mesi di spese usano il fabbisogno predefinito.")
        }
        righe.append("")
        righe.append("Le cifre sono di Prisma. Se vuoi preparo le bozze dei messaggi: le apri e le mandi tu.")
        return righe.joined(separator: "\n")
    }

    // MARK: Le bozze di Prisma (fisse)

    /// Il canale del messaggio: Messaggi con un cellulare, altrimenti Mail (come «messaggi_prepara»).
    static func canaleMessaggio(_ c: Cliente) -> CanaleMessaggio {
        c.telefono.filter(\.isNumber).count >= 6 ? .messaggi : .mail
    }

    /// La bozza fissa di Prisma per un cliente toccato, nel tono dello stile (tu o Lei), con chiusura e firma.
    static func bozzaFissa(_ t: ClienteToccatoVera, evento e: EventoMercatoVera, cliente c: Cliente, stile: StileBozzeVera,
                           oggi: Date, cal: Calendar = .current) -> String {
        corpoFisso(t, evento: e, cliente: c, tu: !stile.tono(c, oggi: oggi, cal: cal).lei, oggi: oggi, cal: cal)
            + coda(stile, canale: t.canaleFirma)
    }

    /// La chiusura e la firma: le mette sempre Prisma. Con il canale nil (canali misti) niente firma: mai quella
    /// di un canale scelta a caso.
    static func coda(_ stile: StileBozzeVera, canale: Canale?) -> String {
        var s = ""
        if let ch = stile.chiusura?.trimmingCharacters(in: .whitespacesAndNewlines), !ch.isEmpty { s += "\n\n" + ch }
        let f = canale.map { stile.firma($0) } ?? ""
        if !f.isEmpty { s += (s.isEmpty ? "\n\n" : "\n") + f }
        return s
    }

    /// Il corpo della bozza fissa (dal saluto all'invito finale).
    static func corpoFisso(_ t: ClienteToccatoVera, evento e: EventoMercatoVera, cliente c: Cliente, tu: Bool,
                           oggi: Date, cal: Calendar = .current) -> String {
        typealias T = TestiMercatoClienti
        func v(_ a: String, _ b: String) -> String { tu ? a : b }
        let nome = ModelliMessaggi.primoNome(c.nome)
        let saluto = v("Ciao \(nome),", "Buongiorno \(nome),")
        let ev = e.fraseMessaggio
        let motivo = t.motivi.first
        let corpo: String
        var invito: String
        switch motivo?.regola {
        case .azioniCalo?:
            switch motivo?.azione {
            case .chiamaOggi?:
                corpo = v("avrai visto che \(ev). Ho guardato i tuoi investimenti.", "avrà visto che \(ev). Ho guardato i Suoi investimenti.")
                invito = v("Ti chiamo oggi per guardare insieme i numeri, con calma.", "La chiamo oggi per guardare insieme i numeri, con calma.")
            case .dueRighe?:
                corpo = v("avrai visto che \(ev). Il tuo piano guarda lontano: per ora non c'è nessuna mossa da fare.",
                          "avrà visto che \(ev). Il Suo piano guarda lontano: per ora non c'è nessuna mossa da fare.")
                invito = v("Se vuoi ne parliamo con calma.", "Se vuole ne parliamo con calma.")
            default:
                corpo = v("avrai visto che \(ev). Ho guardato i tuoi numeri e te li spiego volentieri.",
                          "avrà visto che \(ev). Ho guardato i Suoi numeri e glieli spiego volentieri.")
                invito = v("Quando ti posso chiamare?", "Quando La posso chiamare?")
            }
        case .azioniRialzo?:
            corpo = v("\(ev): il tuo portafoglio ora pesa di più sulle azioni.", "\(ev): il Suo portafoglio ora pesa di più sulle azioni.")
            invito = "Potrebbe essere il momento di riequilibrare: ne parliamo?"
        case .liquiditaFerma?:
            corpo = v("\(ev): i soldi fermi sul conto renderanno meno.", "\(ev): i soldi fermi sul conto renderanno meno.")
            invito = v("Ho in mente un'idea per far lavorare la parte che non ti serve subito: ne parliamo?",
                       "Ho in mente un'idea per far lavorare la parte che non Le serve subito: ne parliamo?")
        case .contoDeposito?:
            corpo = "\(ev): i conti deposito possono tornare a rendere di più."
            invito = v("Guardiamo insieme le condizioni del tuo?", "Guardiamo insieme le condizioni del Suo?")
        case .rivalutabileInScadenza?:
            let scadenza = motivo?.cifre.first { $0.etichetta == "Scadenza" }?.valore ?? ""
            let nomePolizza = motivo.flatMap { m in T.nomeTraVirgolette(m.testo) } ?? "polizza"
            corpo = v("la tua «\(nomePolizza)» scade a \(scadenza) e \(ev).", "la Sua «\(nomePolizza)» scade a \(scadenza) e \(ev).")
            invito = "Conviene decidere per tempo come proseguire: ne parliamo?"
        case .mutuoVariabile?:
            let diff = motivo?.cifre.first { $0.etichetta.hasPrefix("Rata più") }?.valore
            let quanto = diff.map { " di circa \($0) al mese" } ?? ""
            corpo = v("\(ev): la rata del tuo mutuo variabile potrebbe \(e.giu ? "scendere" : "salire")\(quanto).",
                      "\(ev): la rata del Suo mutuo variabile potrebbe \(e.giu ? "scendere" : "salire")\(quanto).")
            invito = e.giu ? v("Ti aggiorno con i numeri giusti alla prossima revisione.", "La aggiorno con i numeri giusti alla prossima revisione.")
                : v("Ti chiamo per rivedere insieme il bilancio di casa?", "La chiamo per rivedere insieme il bilancio di casa?")
        case .obiettivoCasa?:
            corpo = "\(ev): per la casa un mutuo potrebbe costare \(e.giu ? "meno" : "di più")."
            invito = "Rifacciamo insieme i conti dell'obiettivo?"
        case .obbligazioni?:
            corpo = "\(ev): i prezzi delle obbligazioni possono scendere per un po'."
            invito = v("Ti spiego volentieri cosa vuol dire per il tuo portafoglio.", "Le spiego volentieri cosa vuol dire per il Suo portafoglio.")
        case .liquiditaInflazione?:
            let l = motivo?.cifre.first { $0.etichetta == "Liquidità" }?.valore ?? ""
            let p = motivo?.cifre.first { $0.etichetta.hasPrefix("Potere") }?.valore ?? ""
            corpo = "\(ev): i \(l) fermi sul conto perdono circa \(p) di valore in un anno."
            invito = "Ne parliamo?"
        case .obiettivoInflazione?:
            let fra = motivo?.cifre.first { $0.etichetta == "Fra" }?.valore ?? ""
            let costo = motivo?.cifre.first { $0.etichetta == "Costo con l'inflazione" }?.valore ?? ""
            let titolo = motivo.flatMap { m in T.nomeTraVirgolette(m.testo) } ?? "obiettivo"
            corpo = "\(ev): l'obiettivo «\(titolo)» fra \(fra) costerebbe circa \(costo)."
            invito = "Rivediamo insieme l'importo?"
        case .rivalutabileSottoInflazione?:
            let r = motivo?.cifre.first { $0.etichetta.hasPrefix("Rendimento") }?.valore ?? ""
            let nomePolizza = motivo.flatMap { m in T.nomeTraVirgolette(m.testo) } ?? "polizza"
            corpo = v("\(ev): la tua «\(nomePolizza)» rende circa \(r) lordo, meno dell'inflazione.",
                      "\(ev): la Sua «\(nomePolizza)» rende circa \(r) lordo, meno dell'inflazione.")
            invito = "Ne parliamo al prossimo incontro?"
        case .previdenzaInflazione?:
            corpo = v("\(ev): conviene rivedere quanto ti servirà per la pensione.", "\(ev): conviene rivedere quanto Le servirà per la pensione.")
            invito = "Ne parliamo al prossimo incontro?"
        case nil:
            corpo = "\(ev)."
            invito = "Ne parliamo?"
        }
        if t.azione == .parlaneIncontro, let i = t.incontro {
            invito = "Ne parliamo \(DateItaliane.descrivi(i, conOra: false, oggi: oggi, cal: cal)), quando ci vediamo."
        }
        return saluto + " " + corpo + " " + invito
    }

    // MARK: Qwen (solo le bozze, JSON, cifre controllate)

    static let schema: [String: Any] = {
        let voce: [String: Any] = ["type": "object", "required": ["cliente", "testo"],
                                   "properties": ["cliente": ["type": "string"], "testo": ["type": "string"]] as [String: Any]]
        return ["type": "object", "properties": ["bozze": ["type": "array", "items": voce]], "required": ["bozze"]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("mercato-clienti") ?? "Scrivi in italiano, a nome del consulente, un messaggio breve per ogni cliente partendo dalla bozza di Prisma. Usa solo i fatti e le cifre del cliente, dai del tu o del Lei come indicato, non promettere rendimenti, non nominare altri clienti, non scrivere oggetto, chiusura né firma. Rispondi solo con il JSON: bozze, ognuna con cliente (l'id dato) e testo."
    }

    /// I fatti di un cliente per Qwen: il nome (solo il primo), il tono, l'azione, le cifre di Prisma e la bozza fissa.
    static func scheda(_ t: ClienteToccatoVera, evento e: EventoMercatoVera, cliente c: Cliente, stile: StileBozzeVera,
                       oggi: Date, cal: Calendar = .current) -> String {
        let tono = stile.tono(c, oggi: oggi, cal: cal)
        var righe = ["CLIENTE id=\(t.clienteId) · \(ModelliMessaggi.primoNome(c.nome)) (\(tono.lei ? "dai del Lei" : "dai del tu"))",
                     "Canale del messaggio: \(canaleMessaggio(c) == .mail ? "mail" : "messaggio sul telefono")",
                     "Cosa fare: \(t.etichettaAzione)",
                     "FATTI (cifre esatte di Prisma: usa solo queste)"]
        for m in t.motivi {
            righe.append("- \(m.testo)")
            righe += m.cifre.map { "  · \($0.etichetta): \($0.valore)" }
        }
        righe.append("BOZZA DI PRISMA")
        righe.append(corpoFisso(t, evento: e, cliente: c, tu: !tono.lei, oggi: oggi, cal: cal))
        return righe.joined(separator: "\n")
    }

    static func messaggi(_ esito: EsitoMercatoVera, toccati: [ClienteToccatoVera], clienti: [Cliente], stile: StileBozzeVera,
                         oggi: Date, cal: Calendar = .current) -> [MessaggioModello] {
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var righe = ["EVENTO: \(esito.evento.titolo) (\(esito.evento.fonte))", "In breve: \(esito.sintesi)"]
        if !stile.tratti.isEmpty {
            righe.append("STILE DEL CONSULENTE")
            righe += stile.tratti.map { "- \($0)" }
        }
        for t in toccati {
            guard let c = perId[t.clienteId] else { continue }
            righe.append("")
            righe.append(scheda(t, evento: esito.evento, cliente: c, stile: stile, oggi: oggi, cal: cal))
        }
        righe.append("")
        righe.append("Scrivi una bozza per ogni cliente, dal saluto all'invito finale. Niente oggetto, chiusura né firma: le aggiunge Prisma.")
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni), MessaggioModello(ruolo: .utente, testo: righe.joined(separator: "\n"))]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.4
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.massimoToken = 1_200
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    static func piano(_ esito: EsitoMercatoVera, toccati: [ClienteToccatoVera], clienti: [Cliente], stile: StileBozzeVera,
                      vera: ImpostazioniVera, oggi: Date, cal: Calendar = .current) -> PianoVera {
        PianoVera(scelta: SceltaVera(modalita: .lavoro, pensa: false),
                  messaggi: messaggi(esito, toccati: toccati, clienti: clienti, stile: stile, oggi: oggi, cal: cal), opzioni: opzioni(vera))
    }

    /// Tutto il testo da cui possono venire le cifre della bozza di un cliente: l'evento, la sintesi, i motivi, le
    /// cifre e la bozza fissa (con la misura anche senza segno: «−8%» e «8%»).
    static func ammessi(_ t: ClienteToccatoVera, evento e: EventoMercatoVera, sintesi: String, cliente c: Cliente,
                        oggi: Date, cal: Calendar = .current) -> String {
        var righe = [e.titolo, e.fraseMessaggio, sintesi, c.nome, TestiMercatoClienti.numero(abs(e.misura)), TestiMercatoClienti.numero(e.misura)]
        for m in t.motivi {
            righe.append(m.testo)
            righe += m.cifre.map { "\($0.etichetta): \($0.valore)" }
        }
        righe.append(corpoFisso(t, evento: e, cliente: c, tu: true, oggi: oggi, cal: cal))
        return righe.joined(separator: "\n")
    }

    /// nil se la bozza di Qwen va bene; altrimenti il motivo per cui resta quella di Prisma.
    static func controlla(_ testo: String, toccato t: ClienteToccatoVera, esito: EsitoMercatoVera, cliente c: Cliente,
                          altri: [String], tu: Bool, oggi: Date, cal: Calendar = .current) -> String? {
        let s = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "la bozza di Vera era vuota" }
        if s.contains("[") || s.contains("]") || s.contains("{") || s.contains("}") || s.contains("<") || s.contains(">") {
            return "la bozza di Vera aveva dei segnaposto da completare"
        }
        let fatti = ammessi(t, evento: esito.evento, sintesi: esito.sintesi, cliente: c, oggi: oggi, cal: cal)
        guard CommentoVera.numeriConservati(bozza: fatti, testo: s) else {
            return "la bozza di Vera citava una cifra che Prisma non ha calcolato"
        }
        guard numeriInParoleConservati(fatti: fatti, testo: s) else {
            return "la bozza di Vera citava una cifra in parole che Prisma non ha calcolato"
        }
        if s.range(of: MessaggiVera.promesse, options: [.regularExpression, .caseInsensitive]) != nil {
            return "la bozza di Vera prometteva un risultato"
        }
        // Nel messaggio a un cliente niente nomi degli altri
        let minuscolo = s.lowercased()
        let mio = ModelliMessaggi.primoNome(c.nome).lowercased()
        for nome in altri.map({ ModelliMessaggi.primoNome($0).lowercased() }) where nome.count >= 3 && nome != mio {
            if DateItaliane.cerca(#"\b"# + NSRegularExpression.escapedPattern(for: nome) + #"\b"#, minuscolo) != nil {
                return "la bozza di Vera nominava un altro cliente"
            }
        }
        // Le stesse forme del tu di StileVera.allocuzione («ciao», «hai», «vuoi», «puoi», «fammi»…), senza «sei»
        // che è anche il numero
        if !tu, DateItaliane.cerca(#"\b(?:ti|te|tuo|tua|tuoi|tue|ciao|puoi|vuoi|hai|fammi|dimmi|scrivimi|chiamami)\b"#, minuscolo) != nil {
            return "la bozza di Vera dava del tu a chi riceve il Lei"
        }
        // E al contrario: a chi riceve il tu niente Lei, né forme di cortesia maiuscole a metà frase («i Suoi numeri»)
        if tu, StileVera.allocuzione(di: s) == .lei
            || s.range(of: #"(?<=[a-zà-ù,] )(?:La|Le|Lei|Sua|Suo|Sue|Suoi)\b"#, options: .regularExpression) != nil {
            return "la bozza di Vera dava del Lei a chi riceve il tu"
        }
        if s.split(whereSeparator: { $0.isWhitespace }).count > RegoleMercatoClienti.paroleBozza { return "la bozza di Vera era troppo lunga" }
        return nil
    }

    private static let valoriInParole: [String: Int] = [
        "due": 2, "tre": 3, "quattro": 4, "cinque": 5, "sei": 6, "sette": 7, "otto": 8, "nove": 9, "dieci": 10, "undici": 11,
        "dodici": 12, "tredici": 13, "quattordici": 14, "quindici": 15, "sedici": 16, "diciassette": 17, "diciotto": 18,
        "diciannove": 19, "venti": 20, "trenta": 30, "quaranta": 40, "cinquanta": 50, "sessanta": 60, "settanta": 70,
        "ottanta": 80, "novanta": 90, "cento": 100,
    ]

    /// I numeri scritti in parole («fra dieci anni», «due mesi di spese», «un terzo») non li vede `numeriConservati`:
    /// ognuno deve stare nei fatti, come parola o come cifra («dieci» con «10»). «Un/una» sono articoli e non contano;
    /// «sei» conta solo davanti a una quantità («sei mesi»), perché è anche il verbo; «per cento» è già nelle cifre.
    /// I composti sono elencati uno per uno (non «ventaglio», «venturo», «Trentino», «quarantena»); «metà» solo con
    /// l'accento (non «meta»), e «mezzo», «metà», «terzo», «quarto» solo davanti a una quantità («mezzo punto»,
    /// «un terzo del», «metà della»), non in «per mezzo di» o «il terzo cliente».
    static func numeriInParoleConservati(fatti: String, testo: String) -> Bool {
        let schema = #"\b(?:due|tre|quattro|cinque|sette|otto|nove|dieci|undici|dodici|tredici|quattordici|quindici|sedici|diciassette|diciotto|diciannove|venti|trenta|quaranta|cinquanta|sessanta|settanta|ottanta|novanta|(?<!per )cento|mezz[oa](?= (?:punt|percentual|per ?cento|ora\b|anno\b|mese\b|milion|giornat))|(?:metà|terz[oi]|quart[oi])(?= (?:di|del|dell|della|dello|dei|degli|delle)\b)|doppi[oa]|tripl[oa]|vent(?:i(?:due|tr[eé]|quattro|cinque|sei|sette|nove|mila)|uno|otto|in[ae])|(?:trent|quarant|cinquant|sessant|settant|ottant|novant)(?:a(?:due|tr[eé]|quattro|cinque|sei|sette|nove|mila)|uno|otto|in[ae])|sei(?= (?:mesi|anni|settimane|giorni|volte|rate|per ?cento)\b))\b"#
        guard let re = try? NSRegularExpression(pattern: schema, options: [.caseInsensitive]) else { return false }
        let ns = testo as NSString
        let minuscoli = fatti.lowercased()
        let cifre = CommentoVera.cifre(fatti)
        for m in re.matches(in: testo, range: NSRange(location: 0, length: ns.length)) {
            let parola = ns.substring(with: m.range).lowercased()
            if DateItaliane.cerca(#"\b"# + NSRegularExpression.escapedPattern(for: parola) + #"\b"#, minuscoli) != nil { continue }
            if let v = valoriInParole[parola], cifre.contains(String(v)) { continue }
            return false
        }
        return true
    }

    /// Le bozze di Qwen che passano il controllo, per cliente (già pulite, con chiusura e firma di Prisma).
    /// nil se il JSON non si legge.
    static func leggi(_ json: String, esito: EsitoMercatoVera, clienti: [Cliente], stile: StileBozzeVera,
                      oggi: Date, cal: Calendar = .current) -> [String: Result<String, ErroreBozzaMercato>]? {
        guard let i = json.firstIndex(of: "{"), let fine = json.lastIndex(of: "}"), i < fine,
              let d = String(json[i...fine]).data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let elenco = j["bozze"] as? [[String: Any]] else { return nil }
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let toccati = Dictionary(esito.toccati.map { ($0.clienteId, $0) }, uniquingKeysWith: { a, _ in a })
        let nomi = esito.toccati.map(\.nome)
        var risultato: [String: Result<String, ErroreBozzaMercato>] = [:]
        for v in elenco {
            guard let id = (v["cliente"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), let t = toccati[id], let c = perId[id],
                  risultato[id] == nil, let grezzo = v["testo"] as? String else { continue }
            // Le firme di tutti e due i canali si tolgono dal testo di Qwen: quella giusta la rimette Prisma
            let firme = [stile.firma(.alleanza), stile.firma(.indipendente)].filter { !$0.isEmpty }.joined(separator: " ")
            let pulito = MessaggiVera.pulisci(grezzo, firma: firme.isEmpty ? nil : firme)
            let tu = !stile.tono(c, oggi: oggi, cal: cal).lei
            if let motivo = controlla(pulito, toccato: t, esito: esito, cliente: c, altri: nomi.filter { $0 != c.nome }, tu: tu, oggi: oggi, cal: cal) {
                risultato[id] = .failure(ErroreBozzaMercato(motivo: motivo))
            } else {
                risultato[id] = .success(pulito + coda(stile, canale: t.canaleFirma))
            }
        }
        return risultato
    }

    /// Le bozze di tutti i toccati: quella di Qwen se è passata dal controllo, altrimenti la fissa di Prisma con
    /// l'avviso. `json` nil = Qwen non ha risposto (o non è pronto: `motivoNonPronta`).
    static func bozze(_ esito: EsitoMercatoVera, clienti: [Cliente], stile: StileBozzeVera, json: String?, modello: String? = nil,
                      motivoNonPronta: String? = nil, oggi: Date, cal: Calendar = .current) -> [BozzaMercatoVera] {
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let lette = json.flatMap { leggi($0, esito: esito, clienti: clienti, stile: stile, oggi: oggi, cal: cal) }
        return esito.toccati.compactMap { t -> BozzaMercatoVera? in
            guard let c = perId[t.clienteId] else { return nil }
            let canale = canaleMessaggio(c)
            let fissa = bozzaFissa(t, evento: esito.evento, cliente: c, stile: stile, oggi: oggi, cal: cal)
            guard json != nil else {
                return BozzaMercatoVera(clienteId: c.id, testo: fissa, canale: canale, autore: .modelloFisso,
                                        avviso: MessaggiVera.avvisoNonPronta(motivoNonPronta))
            }
            switch lette?[t.clienteId] {
            case .success(let testo)?:
                return BozzaMercatoVera(clienteId: c.id, testo: testo, canale: canale, autore: .vera, modello: modello, avviso: nil)
            case .failure(let e)?:
                return BozzaMercatoVera(clienteId: c.id, testo: fissa, canale: canale, autore: .modelloFisso,
                                        avviso: TestiMercatoClienti.maiuscola(e.motivo) + ": resta il testo di Prisma, con le cifre esatte.")
            case nil:
                return BozzaMercatoVera(clienteId: c.id, testo: fissa, canale: canale, autore: .modelloFisso,
                                        avviso: lette == nil ? "La risposta di Vera non si leggeva: resta il testo di Prisma, con le cifre esatte."
                                            : "Vera non ha scritto la bozza per questo cliente: resta il testo di Prisma.")
            }
        }
    }

    /// Scrive le bozze con Qwen sul Mac, a gruppi di `clientiPerRichiesta`. Senza motore (o non pronto) restano le
    /// bozze fisse di Prisma, con l'avviso. Mai un invio: le bozze tornano al consulente.
    static func scrivi(_ esito: EsitoMercatoVera, clienti: [Cliente], stile: StileBozzeVera, motore: MotoreLocale?,
                       vera: ImpostazioniVera, oggi: Date, cal: Calendar = .current) async -> [BozzaMercatoVera] {
        guard let motore else { return bozze(esito, clienti: clienti, stile: stile, json: nil, oggi: oggi, cal: cal) }
        guard motore.disponibilita.pronto else {
            return bozze(esito, clienti: clienti, stile: stile, json: nil, motivoNonPronta: motore.disponibilita.motivo, oggi: oggi, cal: cal)
        }
        var tutte: [BozzaMercatoVera] = []
        let passo = RegoleMercatoClienti.clientiPerRichiesta
        var inizio = 0
        while inizio < esito.toccati.count {
            let gruppo = Array(esito.toccati[inizio..<min(inizio + passo, esito.toccati.count)])
            var parziale = esito
            parziale.toccati = gruppo
            let json: String?
            do {
                json = try await motore.scrivi(piano(parziale, toccati: gruppo, clienti: clienti, stile: stile, vera: vera, oggi: oggi, cal: cal)).testo
            } catch {
                json = "{}"
            }
            tutte += bozze(parziale, clienti: clienti, stile: stile, json: json, modello: motore.modello, oggi: oggi, cal: cal)
            inizio += passo
        }
        return tutte
    }

    // MARK: Le azioni per la scheda «Conferma»

    /// Per ogni cliente: la bozza da preparare in Messaggi e, quando serve, l'attività (chiamare oggi, preparare
    /// l'ipotesi, decidere prima della scadenza…). Niente si esegue qui: è la scheda «Conferma».
    static func azioni(_ esito: EsitoMercatoVera, bozze: [BozzaMercatoVera], clienti: [Cliente], oggi: Date,
                       cal: Calendar = .current) -> [AzioneConferma] {
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let perBozza = Dictionary(bozze.map { ($0.clienteId, $0) }, uniquingKeysWith: { a, _ in a })
        var elenco: [AzioneConferma] = []
        for t in esito.toccati {
            guard let c = perId[t.clienteId] else { continue }
            if let b = perBozza[t.clienteId] {
                elenco.append(AzioneConferma(strumento: RegistroStrumenti.messaggiPrepara, app: .messaggi,
                                             titolo: "Preparo un messaggio per \(c.nome)",
                                             dettaglio: RegistroStrumenti.dettaglioMessaggio(b.testo, canale: b.canale),
                                             argomenti: ["cliente": c.id, "scopo": "altro", "testo": b.testo, "canale": b.canale.rawValue,
                                                         "origine": "mercato", "evento": esito.evento.id],
                                             avviso: b.avviso))
            }
            guard t.azione.conAttivita else { continue }
            let scadenza = scadenzaAttivita(t, oggi: oggi, cal: cal)
            let titolo = "\(t.etichettaAzione) · \(esito.evento.titolo)"
            elenco.append(AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita,
                                         titolo: "Segno un'attività per \(c.nome)",
                                         dettaglio: "«\(titolo)» · entro \(DateItaliane.descrivi(scadenza, conOra: false, oggi: oggi, cal: cal))",
                                         argomenti: ["cliente": c.id, "titolo": titolo, "scadenza": RegistroStrumenti.isoData(scadenza)]))
        }
        return elenco
    }

    /// Oggi per chiamare, il giorno dell'incontro per parlarne, una settimana per il resto.
    static func scadenzaAttivita(_ t: ClienteToccatoVera, oggi: Date, cal: Calendar = .current) -> Date {
        let giorno = cal.startOfDay(for: oggi)
        switch t.azione {
        case .chiamaOggi: return giorno
        case .parlaneIncontro: return t.incontro.map { cal.startOfDay(for: $0) } ?? giorno
        default: return cal.date(byAdding: .day, value: 7, to: giorno) ?? giorno
        }
    }

    /// La scheda «Conferma» con tutte le azioni (da mostrare in chat; l'origine dedicata arriverà con il collegamento).
    static func scheda(_ esito: EsitoMercatoVera, bozze: [BozzaMercatoVera], clienti: [Cliente], richiesta: String,
                       oggi: Date, cal: Calendar = .current) -> SchedaConfermaVera {
        SchedaConfermaVera(richiesta: richiesta, azioni: azioni(esito, bozze: bozze, clienti: clienti, oggi: oggi, cal: cal), origine: .regole)
    }
}

/// Il motivo per cui una bozza di Qwen è stata scartata.
struct ErroreBozzaMercato: Error, Equatable {
    var motivo: String
}

// MARK: - Testi

/// Le parole di «Il mercato per i tuoi clienti»: numeri all'italiana, articoli davanti alle cifre, titoli e sintesi.
enum TestiMercatoClienti {
    static func numero(_ v: Double) -> String {
        Formati.numeroFormatter.string(from: NSNumber(value: v)) ?? String(v)
    }

    static func euro(_ v: Double) -> String { Formati.euro(v) }

    /// «52%», «2,5%».
    static func percento(_ v: Double) -> String { numero((v * 10).rounded() / 10) + "%" }

    static func meseAnno(_ d: Date) -> String { Formati.meseAnno.string(from: d) }

    /// «6,5 mesi», «1 mese».
    static func mesi(_ v: Double) -> String { v == 1 ? "1 mese" : "\(TestiAree360.mesi(v)) mesi" }

    static func anni(_ n: Int) -> String { n == 1 ? "1 anno" : "\(n) anni" }

    /// Le cifre che si leggono con la vocale davanti: 1, 8, 11 e 80… («l'8%», «l'11%», «l'1,5%», «l'80%»).
    static func conVocale(_ v: Double) -> Bool {
        let s = numero(abs(v))
        if s.hasPrefix("8") { return true }
        if s == "1" || s.hasPrefix("1,") { return true }
        if s == "11" || s.hasPrefix("11,") { return true }
        return false
    }

    /// «al 3%», «all'8%», «all'1,5%».
    static func al(_ v: Double) -> String { (conVocale(v) ? "all'" : "al ") + numero(v) + "%" }
    /// «del 5%», «dell'8%».
    static func del(_ v: Double) -> String { (conVocale(v) ? "dell'" : "del ") + numero(v) + "%" }
    /// «il 5%», «l'8%».
    static func il(_ v: Double) -> String { (conVocale(v) ? "l'" : "il ") + numero(v) + "%" }

    /// «0,25 punti», «1 punto».
    static func punti(_ v: Double) -> String { numero(abs(v)) + (abs(v) == 1 ? " punto" : " punti") }

    static func titolo(_ e: EventoMercatoVera) -> String {
        let periodo = e.periodo.map { " \($0)" } ?? ""
        switch e.tipo {
        case .tassiBCE:
            return e.giu ? "La BCE taglia i tassi di \(punti(e.misura))" : "La BCE alza i tassi di \(punti(e.misura))"
        case .inflazione:
            switch e.verso {
            case 1: return "L'inflazione sale \(al(e.misura))"
            case -1: return "L'inflazione scende \(al(e.misura))"
            default: return "L'inflazione è \(al(e.misura))"
            }
        case .borse:
            return (e.giu ? "Le borse perdono \(il(abs(e.misura)))" : "Le borse guadagnano \(il(abs(e.misura)))") + periodo
        }
    }

    static func fraseMessaggio(_ e: EventoMercatoVera) -> String {
        let periodo = e.periodo.map { " \($0)" } ?? ""
        switch e.tipo {
        case .tassiBCE:
            return e.giu ? "la BCE ha tagliato i tassi di \(punti(e.misura))" : "la BCE ha alzato i tassi di \(punti(e.misura))"
        case .inflazione:
            switch e.verso {
            case 1: return "l'inflazione è salita \(al(e.misura))"
            case -1: return "l'inflazione è scesa \(al(e.misura))"
            default: return "l'inflazione è \(al(e.misura))"
            }
        case .borse:
            return (e.giu ? "le borse hanno perso \(il(abs(e.misura)))" : "le borse hanno guadagnato \(il(abs(e.misura)))") + periodo
        }
    }

    static func sintesi(_ e: EventoMercatoVera) -> String {
        switch e.tipo {
        case .tassiBCE:
            return e.giu
                ? "Conti deposito e liquidità renderanno meno. I nuovi piani rivalutabili partiranno da rendimenti più bassi; i mutui variabili costeranno meno."
                : "I mutui variabili costeranno di più e i conti deposito possono rendere di più. Le obbligazioni già in portafoglio possono perdere valore per un po'."
        case .inflazione:
            return e.misura > RegoleMercatoClienti.inflazioneObiettivoBCE
                ? "Rendite fisse e liquidità perdono potere d'acquisto più in fretta, e gli obiettivi costano di più."
                : "Con l'inflazione vicina all'obiettivo della BCE pesa meno su liquidità e obiettivi, ma conta ancora sugli obiettivi lontani."
        case .borse:
            return e.giu
                ? "Chi ha più azioni vedrà il portafoglio scendere. Meglio chiamarlo prima che chiami lui."
                : "Chi ha più azioni vede il portafoglio salire: per qualcuno è il momento di riequilibrare."
        }
    }

    /// Il primo nome tra «…» di un testo.
    static func nomeTraVirgolette(_ s: String) -> String? {
        DateItaliane.cerca(#"«([^»]+)»"#, s)?.1[1]
    }

    static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.uppercased() + s.dropFirst()
    }
}

// MARK: - Prova: ipotesi e domande

extension MercatoClientiVera {
    /// Le ipotesi restano degli scenari e le domande su un dato vanno a Qwen: nessuna delle due è un evento accaduto
    /// (da chiamare in `ProvaMercatoClientiVera`, accanto ai casi del riconoscimento).
    static func provaIpotesiEDomande(_ controlla: (Bool, String) -> Void) {
        let oggi = Date()
        let ipotesi = ["Supponiamo che le borse perdano il 20%: cosa cambia per Marco?",
                       "Se la BCE tagliasse i tassi di 50 punti base, cosa cambia?",
                       "Simula un crollo delle borse del 30%",
                       "Ipotizziamo che l'inflazione salga al 5%",
                       "Mettiamo che le borse perdano il 15%",
                       "Facciamo finta che la BCE alzi i tassi di mezzo punto",
                       "Cosa succederebbe se le borse crollassero del 25%?"]
        for f in ipotesi {
            controlla(riconosci(f, oggi: oggi) == .nessuno && !eUnEvento(f),
                      "Mercato per i clienti: «\(f)» è un'ipotesi degli scenari, non un evento")
        }
        let domande = ["Com'è andata la borsa oggi?", "Quanto è l'inflazione adesso?", "Cos'è l'inflazione?",
                       "Cosa ha deciso la BCE sui tassi?", "Quanto ha perso la borsa oggi?"]
        for f in domande {
            controlla(!eUnEvento(f), "Mercato per i clienti: «\(f)» è una domanda, non un evento")
        }
        controlla(eUnEvento("La BCE ha tagliato i tassi") && eUnEvento("Le borse sono crollate")
                    && eUnEvento("Le borse hanno perso l'8% in una settimana"),
                  "Mercato per i clienti: gli eventi detti restano eventi (anche a metà, con il verbo forte)")
    }
}
