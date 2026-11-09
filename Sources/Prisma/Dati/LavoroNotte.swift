import Foundation

// «Stanotte Prisma ha lavorato» («Luce» giro 14, Design/template-luce-specifica.md §6.1, decisioni 29, 30, 31, 101).
// Di notte, solo con il Mac acceso, alla corrente e Prisma aperto (e non in uso), Prisma prepara le cose di domani una alla
// volta (prima quelle senza Qwen, poi al più 10 bozze di Vera) e le lascia come carte da approvare al mattino. «Approva» non
// manda mai nulla e si annulla. Le notti (ultime 14) stanno nell'archivio, sezione «relazione», lette con tolleranza; mai in
// «Prisma ovunque». Solo Foundation: compila su Mac e iOS.

/// Il tipo di una carta della notte (§6.1.1 punto 1.8). L'ordine è quello del lavoro: prima i senza Qwen.
enum TipoCartaNotte: String, Codable, CaseIterable, Identifiable {
    case ricalcolo, documento, riesame, domani, fascicolo, moduli, campagna, messaggio, daFinire

    var id: String { rawValue }

    /// Ha bisogno di Qwen (decisione 101: dopo tutti gli altri).
    var conQwen: Bool { self == .messaggio }

    /// Il nome nelle Impostazioni (un interruttore per tipo).
    var nome: String {
        switch self {
        case .ricalcolo: return "Ricalcolo delle attenzioni"
        case .documento: return "Documenti d'identità in scadenza"
        case .riesame: return "Riesami dovuti"
        case .domani: return "La borsa di domani"
        case .fascicolo: return "Fascicoli degli incontri"
        case .moduli: return "Moduli da firmare"
        case .campagna: return "Una campagna"
        case .messaggio: return "Bozze dei messaggi con Vera"
        case .daFinire: return "Da finire"
        }
    }
}

/// A che punto è una carta. Un valore sconosciuto torna «daDecidere» (mai un effetto applicato per sbaglio).
enum StatoCartaNotte: String, Codable {
    case daDecidere, approvata, rimandata, scaduta
}

/// Come è andata una notte. Sconosciuto (o «inCorso» trovato all'avvio) = «interrotta».
enum EsitoNotte: String, Codable {
    case inCorso, fatta, interrotta, saltata
}

/// Perché il lavoro si è fermato prima (per la carta «Da finire» e per la riga del registro).
enum MotivoStopNotte: String, Codable {
    case memoria, riposo, tempo, qwenNonPronto, chiusura
}

/// Una carta preparata di notte, con il materiale che serve a «Approva» e gli effetti per annullarla.
struct CartaNotte: Identifiable, Codable, Hashable {
    /// Stabile: «‹tipo›-‹riferimento›-‹aaaa-mm-gg del giorno servito›» (rifare il lavoro non duplica).
    var id: String
    var tipo: TipoCartaNotte
    var clienteId: String?
    /// L'oggetto preparato: appuntamento, occasione, cliente, proposta, gruppo della campagna…
    var riferimento: String
    var titolo: String
    var descrizione: String
    /// La riga del registro dopo «Approva» («Fascicolo approvato»).
    var conferma: String
    /// Al secondo, come le altre date dell'archivio.
    var preparataIl: Date
    /// Il giorno per cui è stata preparata (inizio del giorno): se è prima del giorno della notte attuale, «DA IERI».
    var perIl: Date
    var stato: StatoCartaNotte = .daDecidere
    var decisaIl: Date?
    // Il materiale preparato (solo i campi del suo tipo)
    /// Fascicolo e riesame: `TipoProspetto.rawValue`.
    var prospetti: [String] = []
    /// Messaggio e documento: le bozze (stato `.bozza`, id stabili), salvate in Messaggi solo con «Approva».
    var bozze: [MessaggioCliente] = []
    /// Campagna: i clienti inclusi; ricalcolo: i clienti con un'attenzione nuova.
    var clienti: [String] = []
    /// Moduli: gli id dei modelli compilabili.
    var modelli: [String] = []
    /// Domani: la lista della borsa (una riga per appuntamento).
    var righe: [String] = []
    /// Domani: gli appuntamenti del giorno (stesso ordine delle righe).
    var appuntamenti: [String] = []
    /// Da finire: quante bozze mancano.
    var daFinire = 0
    // Gli effetti di «Approva», per annullarli
    /// Gli id di documenti, messaggi, attività, campagna creati dall'approvazione.
    var creati: [String] = []
    /// Domani: appuntamentoId → testo aggiunto alla nota.
    var noteAggiunte: [String: String] = [:]

    init(id: String, tipo: TipoCartaNotte, clienteId: String?, riferimento: String, titolo: String, descrizione: String,
         conferma: String, preparataIl: Date, perIl: Date) {
        self.id = id
        self.tipo = tipo
        self.clienteId = clienteId
        self.riferimento = riferimento
        self.titolo = titolo
        self.descrizione = descrizione
        self.conferma = conferma
        self.preparataIl = preparataIl
        self.perIl = perIl
    }

    /// Decisa per sempre (approvata o non più valida): non torna nella pila.
    var decisa: Bool { stato == .approvata || stato == .scaduta }

    private enum CodingKeys: String, CodingKey {
        case id, tipo, clienteId, riferimento, titolo, descrizione, conferma, preparataIl, perIl, stato, decisaIl
        case prospetti, bozze, clienti, modelli, righe, appuntamenti, daFinire, creati, noteAggiunte
    }

    /// Lettura tollerante: id e tipo obbligatori (senza, la carta si scarta); il resto con un valore di base.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tipo = try c.decode(TipoCartaNotte.self, forKey: .tipo)
        clienteId = (try? c.decodeIfPresent(String.self, forKey: .clienteId)) ?? nil
        riferimento = (try? c.decodeIfPresent(String.self, forKey: .riferimento)) ?? ""
        titolo = (try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? ""
        descrizione = (try? c.decodeIfPresent(String.self, forKey: .descrizione)) ?? ""
        conferma = (try? c.decodeIfPresent(String.self, forKey: .conferma)) ?? ""
        preparataIl = (try? c.decodeIfPresent(Date.self, forKey: .preparataIl)) ?? Date.distantPast
        perIl = (try? c.decodeIfPresent(Date.self, forKey: .perIl)) ?? Date.distantPast
        stato = (try? c.decodeIfPresent(StatoCartaNotte.self, forKey: .stato)) ?? .daDecidere
        decisaIl = (try? c.decodeIfPresent(Date.self, forKey: .decisaIl)) ?? nil
        prospetti = (try? c.decodeIfPresent([String].self, forKey: .prospetti)) ?? []
        bozze = ((try? c.decodeIfPresent(ElencoTollerante<MessaggioCliente>.self, forKey: .bozze)) ?? nil)?.elementi ?? []
        clienti = (try? c.decodeIfPresent([String].self, forKey: .clienti)) ?? []
        modelli = (try? c.decodeIfPresent([String].self, forKey: .modelli)) ?? []
        righe = (try? c.decodeIfPresent([String].self, forKey: .righe)) ?? []
        appuntamenti = (try? c.decodeIfPresent([String].self, forKey: .appuntamenti)) ?? []
        daFinire = max(0, (try? c.decodeIfPresent(Int.self, forKey: .daFinire)) ?? 0)
        creati = (try? c.decodeIfPresent([String].self, forKey: .creati)) ?? []
        noteAggiunte = (try? c.decodeIfPresent([String: String].self, forKey: .noteAggiunte)) ?? [:]
    }
}

/// Una notte di lavoro: il giorno servito, quando ha lavorato e le carte preparate.
struct NotteDiLavoro: Identifiable, Codable, Hashable {
    var id: String { giornoChiave }
    /// Il giorno servito (inizio del giorno, fuso del Mac).
    var giorno: Date
    var inizio: Date?
    var fine: Date?
    var esito: EsitoNotte = .inCorso
    var motivoStop: MotivoStopNotte?
    var carte: [CartaNotte] = []
    /// La fotografia delle attenzioni e dei clienti fuori dal radar («clienteId·tipo»): il ricalcolo della notte dopo dice
    /// solo le nuove. Mai titoli né cifre.
    var attenzioni: [String] = []
    /// Le carte si sono già aperte da sole questa mattina (una volta sola).
    var apertaDaSola = false
    /// «2026-11-09», calendario gregoriano.
    var giornoChiave: String

    init(giorno: Date, inizio: Date?, cal: Calendar = .current) {
        self.giorno = giorno
        self.inizio = inizio
        self.giornoChiave = NotteDiLavoro.chiave(giorno, cal: cal)
    }

    /// La chiave di un giorno («aaaa-mm-gg»), con il fuso del calendario dato e le cifre gregoriane.
    static func chiave(_ giorno: Date, cal: Calendar = .current) -> String {
        var g = Calendar(identifier: .gregorian)
        g.timeZone = cal.timeZone
        let d = g.dateComponents([.year, .month, .day], from: giorno)
        return String(format: "%04d-%02d-%02d", d.year ?? 0, d.month ?? 0, d.day ?? 0)
    }

    private enum CodingKeys: String, CodingKey {
        case giorno, inizio, fine, esito, motivoStop, carte, attenzioni, apertaDaSola, giornoChiave
    }

    /// Lettura tollerante: il giorno è obbligatorio; carte con `ElencoTollerante`; esito sconosciuto → «interrotta».
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        giorno = try c.decode(Date.self, forKey: .giorno)
        inizio = (try? c.decodeIfPresent(Date.self, forKey: .inizio)) ?? nil
        fine = (try? c.decodeIfPresent(Date.self, forKey: .fine)) ?? nil
        if c.contains(.esito) {
            esito = (try? c.decodeIfPresent(EsitoNotte.self, forKey: .esito)) ?? .interrotta
        } else {
            esito = .interrotta
        }
        motivoStop = (try? c.decodeIfPresent(MotivoStopNotte.self, forKey: .motivoStop)) ?? nil
        carte = ((try? c.decodeIfPresent(ElencoTollerante<CartaNotte>.self, forKey: .carte)) ?? nil)?.elementi ?? []
        attenzioni = (try? c.decodeIfPresent([String].self, forKey: .attenzioni)) ?? []
        apertaDaSola = (try? c.decodeIfPresent(Bool.self, forKey: .apertaDaSola)) ?? false
        giornoChiave = (try? c.decodeIfPresent(String.self, forKey: .giornoChiave)) ?? NotteDiLavoro.chiave(giorno)
    }
}

/// Impostazioni › Vera › «Stanotte» (§5.5). Spento di base: lo accende l'utente.
struct ImpostazioniNotte: Codable, Equatable, Hashable {
    var attivo = false
    /// L'ora di inizio della finestra serale (18…23; fuori scelta → 22). La finestra finisce alle 6:00.
    var inizio = 22
    /// Non modificabile nell'interfaccia di questo giro (decisione 30): resta per il futuro.
    var soloConCorrente = true
    var usaQwen = true
    /// 0…10 (decisione 101: mai oltre 10).
    var massimoBozze = 10
    var massimoFascicoli = 6
    var massimoRiesami = 3
    var giorniDocumenti = 30
    var giorniRiesami = 14
    var apriAlMattino = true
    /// La notifica di macOS al mattino («Stanotte ho preparato N cose», senza nomi): spenta di base (decisione 29).
    var notificaAlMattino = false
    /// I tipi di carta da preparare (array, non Set: JSON stabile).
    var preparatori: [TipoCartaNotte] = TipoCartaNotte.allCases.filter { $0 != .daFinire }

    static let oreScelta = Array(18...23)
    static let fineFinestra = 6
    static let restaInMemoriaNotte = "2m"
    static let massimoNotti = 14
    static let giorniDaIeri = 7
    static let minutiMassimi = 20
    /// Il tetto delle bozze di Qwen in una notte (decisione 101).
    static let tettoBozze = 10

    init() {}

    private enum CodingKeys: String, CodingKey {
        case attivo, inizio, soloConCorrente, usaQwen, massimoBozze, massimoFascicoli, massimoRiesami, giorniDocumenti
        case giorniRiesami, apriAlMattino, notificaAlMattino, preparatori
    }

    /// Lettura tollerante, con i limiti (come `OrariLavoro.init(from:)`).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let base = ImpostazioniNotte()
        attivo = (try? c.decodeIfPresent(Bool.self, forKey: .attivo)) ?? base.attivo
        let i = (try? c.decodeIfPresent(Int.self, forKey: .inizio)) ?? base.inizio
        inizio = ImpostazioniNotte.oreScelta.contains(i) ? i : base.inizio
        soloConCorrente = (try? c.decodeIfPresent(Bool.self, forKey: .soloConCorrente)) ?? true
        usaQwen = (try? c.decodeIfPresent(Bool.self, forKey: .usaQwen)) ?? base.usaQwen
        let b = (try? c.decodeIfPresent(Int.self, forKey: .massimoBozze)) ?? base.massimoBozze
        massimoBozze = min(ImpostazioniNotte.tettoBozze, max(0, b))
        let f = (try? c.decodeIfPresent(Int.self, forKey: .massimoFascicoli)) ?? base.massimoFascicoli
        massimoFascicoli = min(20, max(0, f))
        let r = (try? c.decodeIfPresent(Int.self, forKey: .massimoRiesami)) ?? base.massimoRiesami
        massimoRiesami = min(10, max(0, r))
        let gd = (try? c.decodeIfPresent(Int.self, forKey: .giorniDocumenti)) ?? base.giorniDocumenti
        giorniDocumenti = min(120, max(1, gd))
        let gr = (try? c.decodeIfPresent(Int.self, forKey: .giorniRiesami)) ?? base.giorniRiesami
        giorniRiesami = min(90, max(1, gr))
        apriAlMattino = (try? c.decodeIfPresent(Bool.self, forKey: .apriAlMattino)) ?? base.apriAlMattino
        notificaAlMattino = (try? c.decodeIfPresent(Bool.self, forKey: .notificaAlMattino)) ?? base.notificaAlMattino
        if let p = (try? c.decodeIfPresent([String].self, forKey: .preparatori)) ?? nil {
            // Un tipo sconosciuto (di un Prisma più nuovo) si salta; «daFinire» non è un preparatore
            var visti = Set<TipoCartaNotte>()
            preparatori = p.compactMap { TipoCartaNotte(rawValue: $0) }.filter { $0 != .daFinire && visti.insert($0).inserted }
        } else {
            preparatori = base.preparatori
        }
    }

    /// Il preparatore è acceso.
    func prepara(_ t: TipoCartaNotte) -> Bool { preparatori.contains(t) }
}
