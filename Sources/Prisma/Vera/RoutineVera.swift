import Foundation

// «Le routine» (Vera/BRIEF.md, funzione 3; template «Le routine»): sequenze di lavoro salvate una volta e lanciate con
// una frase. Vera le esegue passo per passo con gli strumenti di Prisma e lascia il risultato pronto (la scaletta, la
// settimana in quattro righe, il mese chiuso, le cose da fare dopo la firma).
//
// Regole:
// - Prima il codice. Le quattro routine pronte, il riconoscimento della frase, l'esecuzione dei passi e la
//   programmazione sono solo codice. Qwen serve soltanto a capire una routine nuova detta a parole, in JSON con lo
//   schema fisso: valgono solo i passi del catalogo (`TipoPassoRoutine`), il resto si scarta; quando si lancia
//   (ogni lunedì, a fine mese, dopo ogni firma) e i mesi del controllo li leggono le regole dalla frase, mai il modello.
// - I numeri li calcola Prisma: ogni cifra viene dai motori che ci sono già (MotoreParcelle, MotoreStudio.eventi,
//   MotoreOccasioniMessaggi.scadenze, MotoreMossaDelGiorno, MotoreCompletezza, PromesseVera, MotoreStorie).
// - Prima di agire, conferma. I passi di sola lettura leggono `DatiPrisma` e basta; i passi che cambiano qualcosa
//   (messaggi, agenda, attività, posizioni, documenti) preparano `AzioneConferma` per la scheda «Conferma»
//   attraverso il registro degli strumenti (`RegistroStrumenti.prepara`, le stesse azioni di «Fallo tu»). Il motore
//   non esegue niente.
// - Lo strumento dei chilometri di Studio è «in attesa» dalla fase 1: il passo lo dice e non inventa chilometri.
// - La programmazione vale solo con Prisma aperto: `dovute(_:adesso:)` dice quali routine sono da lanciare adesso,
//   dato l'ultimo lancio (con un recupero di `giorniRecupero` giorni se Prisma era chiuso all'ora giusta).
// Motore puro: riceve i dati, `oggi` e il calendario; niente SwiftUI, niente StatoShell, niente Date() nascosti.

// MARK: - Il catalogo dei passi

/// Un passo che Vera sa fare dentro una routine. I nomi sono quelli del JSON (archivio e Qwen): non cambiarli.
enum TipoPassoRoutine: String, Codable, CaseIterable {
    // Prepara l'incontro
    case schedaCliente, ultimoIncontro, scadenzeCliente, cosaManca, scaletta
    // Il mio lunedì
    case agendaSettimana, buchiSettimana, promesseScadenze, mossaSettimana
    // Fine mese
    case parcelleMese, chilometriMese, fattureDaEmettere, scadenzeMeseDopo
    // Dopo la firma
    case archiviaContratto, aggiornaPosizioni, fissaControllo, messaggioBenvenuto

    /// Il passo lavora su un cliente (senza, la routine chiede «Per quale cliente?»).
    var serveCliente: Bool {
        switch self {
        case .schedaCliente, .ultimoIncontro, .scadenzeCliente, .cosaManca, .scaletta,
             .archiviaContratto, .aggiornaPosizioni, .fissaControllo, .messaggioBenvenuto: return true
        default: return false
        }
    }

    /// Il passo può preparare azioni da confermare (mai eseguite qui).
    var preparaAzioni: Bool {
        switch self {
        case .scaletta, .scadenzeMeseDopo, .archiviaContratto, .aggiornaPosizioni, .fissaControllo, .messaggioBenvenuto: return true
        default: return false
        }
    }

    /// La descrizione per Qwen (catalogo nelle istruzioni della routine nuova) e per la pagina delle routine.
    var descrizione: String {
        switch self {
        case .schedaCliente: return "apre la scheda del cliente e il suo prossimo incontro"
        case .ultimoIncontro: return "riassume l'ultimo incontro con il cliente"
        case .scadenzeCliente: return "controlla le scadenze del cliente (posizioni e promesse)"
        case .cosaManca: return "cerca i dati che mancano al cliente"
        case .scaletta: return "prepara la scaletta dell'incontro con i minuti"
        case .agendaSettimana: return "legge l'agenda della settimana"
        case .buchiSettimana: return "cerca le mezze giornate libere della settimana"
        case .promesseScadenze: return "controlla le promesse in ritardo e le scadenze del mese"
        case .mossaSettimana: return "sceglie la mossa della settimana"
        case .parcelleMese: return "somma parcelle incassate e provvigioni del mese"
        case .chilometriMese: return "controlla i chilometri del mese"
        case .fattureDaEmettere: return "elenca le fatture da emettere e quelle scadute"
        case .scadenzeMeseDopo: return "guarda le scadenze del mese che arriva"
        case .archiviaContratto: return "archivia il contratto firmato nella scheda del cliente"
        case .aggiornaPosizioni: return "segna in essere la proposta firmata"
        case .fissaControllo: return "fissa il primo controllo dopo qualche mese (sei se non detto)"
        case .messaggioBenvenuto: return "prepara il messaggio di benvenuto da rivedere"
        }
    }
}

/// Un passo di una routine.
struct PassoRoutine: Codable, Equatable {
    var tipo: TipoPassoRoutine
    /// Solo per `fissaControllo`: fra quanti mesi (nil = `RoutineVera.mesiControllo`).
    var mesi: Int?

    init(_ tipo: TipoPassoRoutine, mesi: Int? = nil) {
        self.tipo = tipo
        self.mesi = mesi
    }

    private enum CodingKeys: String, CodingKey { case tipo, mesi }

    /// Un passo con un tipo che questo Prisma non conosce non si legge (l'elenco tollerante lo salta).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tipo = try c.decode(TipoPassoRoutine.self, forKey: .tipo)
        mesi = ((try? c.decodeIfPresent(Int.self, forKey: .mesi)) ?? nil).flatMap { (1...24).contains($0) ? $0 : nil }
    }
}

/// Quando una routine parte da sola (solo con Prisma aperto) o a quale evento.
struct ProgrammazioneRoutine: Codable, Equatable {
    enum Tipo: String, Codable {
        /// Ogni settimana, nel giorno e all'ora scelti.
        case settimanale
        /// L'ultimo giorno del mese, all'ora scelta.
        case fineMese
        /// Dopo ogni firma (l'evento lo segnala la Shell quando una proposta diventa accettata).
        case dopoFirma
    }

    var tipo: Tipo
    /// Come `Calendar.weekday`: 1 = domenica, 2 = lunedì … 7 = sabato (solo `settimanale`).
    var giorno = 2
    var ora = 8
    var minuto = 30

    static let giorni = ["domenica", "lunedì", "martedì", "mercoledì", "giovedì", "venerdì", "sabato"]

    /// «Ogni lunedì alle 8:30», «L'ultimo giorno del mese», «Dopo ogni firma».
    var etichetta: String {
        switch tipo {
        case .settimanale:
            let g = ProgrammazioneRoutine.giorni[max(0, min(6, giorno - 1))]
            return "Ogni \(g) alle \(ora):\(String(format: "%02d", minuto))"
        case .fineMese: return "L'ultimo giorno del mese"
        case .dopoFirma: return "Dopo ogni firma"
        }
    }

    private enum CodingKeys: String, CodingKey { case tipo, giorno, ora, minuto }

    init(tipo: Tipo, giorno: Int = 2, ora: Int = 8, minuto: Int = 30) {
        self.tipo = tipo
        self.giorno = giorno
        self.ora = ora
        self.minuto = minuto
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tipo = try c.decode(Tipo.self, forKey: .tipo)
        let g = (try? c.decodeIfPresent(Int.self, forKey: .giorno)) ?? nil
        let o = (try? c.decodeIfPresent(Int.self, forKey: .ora)) ?? nil
        let m = (try? c.decodeIfPresent(Int.self, forKey: .minuto)) ?? nil
        giorno = g.flatMap { (1...7).contains($0) ? $0 : nil } ?? 2
        ora = o.flatMap { (0...23).contains($0) ? $0 : nil } ?? 8
        minuto = m.flatMap { (0...59).contains($0) ? $0 : nil } ?? 30
    }
}

/// Una routine: le quattro pronte di Prisma e quelle create a parole dal consulente.
struct RoutineVera: Codable, Equatable, Identifiable {
    var id: String
    var titolo: String
    /// La frase d'esempio con cui si lancia («Vera, prepara l'incontro con Marco»).
    var frase: String
    /// Le espressioni regolari (sul testo pulito, in minuscolo) che la riconoscono.
    var inneschi: [String]
    var passi: [PassoRoutine]
    var programmazione: ProgrammazioneRoutine?
    /// Una delle quattro routine pronte di Prisma.
    var pronta = false
    /// Spenta: non si riconosce e non parte da sola.
    var attiva = true
    var usata = 0
    var ultimoLancio: Date?
    var creataIl: Date

    init(id: String, titolo: String, frase: String, inneschi: [String], passi: [PassoRoutine],
         programmazione: ProgrammazioneRoutine? = nil, pronta: Bool = false, creataIl: Date) {
        self.id = id
        self.titolo = titolo
        self.frase = frase
        self.inneschi = inneschi
        self.passi = passi
        self.programmazione = programmazione
        self.pronta = pronta
        self.creataIl = creataIl
    }

    /// Sotto il titolo nella pagina: la programmazione se c'è, altrimenti quante volte è stata usata.
    var etichetta: String {
        if let p = programmazione { return p.etichetta }
        switch usata {
        case 0: return "Mai usata"
        case 1: return "Usata una volta"
        default: return "Usata \(usata) volte"
        }
    }

    var serveCliente: Bool { passi.contains { $0.tipo.serveCliente } }

    private enum CodingKeys: String, CodingKey {
        case id, titolo, frase, inneschi, passi, programmazione, pronta, attiva, usata, ultimoLancio, creataIl
    }

    /// Lettura tollerante: senza id o senza passi leggibili la routine si scarta; il resto ha un valore di ripiego.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        titolo = (try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? "Routine"
        frase = (try? c.decodeIfPresent(String.self, forKey: .frase)) ?? ""
        inneschi = ((try? c.decodeIfPresent([String].self, forKey: .inneschi)) ?? nil) ?? []
        passi = ((try? c.decodeIfPresent(ElencoTollerante<PassoRoutine>.self, forKey: .passi)) ?? nil)?.elementi ?? []
        guard !passi.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .passi, in: c, debugDescription: "Routine senza passi leggibili")
        }
        programmazione = (try? c.decodeIfPresent(ProgrammazioneRoutine.self, forKey: .programmazione)) ?? nil
        pronta = (try? c.decodeIfPresent(Bool.self, forKey: .pronta)) ?? false
        attiva = (try? c.decodeIfPresent(Bool.self, forKey: .attiva)) ?? true
        usata = max(0, (try? c.decodeIfPresent(Int.self, forKey: .usata)) ?? 0)
        ultimoLancio = (try? c.decodeIfPresent(Date.self, forKey: .ultimoLancio)) ?? nil
        creataIl = (try? c.decodeIfPresent(Date.self, forKey: .creataIl)) ?? Date(timeIntervalSinceReferenceDate: 0)
    }
}

/// Un punto della scaletta dell'incontro.
struct RigaScaletta: Codable, Equatable {
    var testo: String
    var minuti: Int
}

/// Un pulsante sotto il risultato («Apri in Incontri», «Apri Studio»): l'app da aprire e il cliente.
struct PulsanteRoutine: Codable, Equatable {
    var titolo: String
    var app: AppPrisma
    var clienteId: String?
}

/// Quello che un passo ha fatto: la riga che si spunta nella scheda della routine.
struct EsitoPassoRoutine: Codable, Equatable {
    enum Stato: String, Codable {
        /// Fatto, con qualcosa da dire.
        case fatto
        /// Fatto, ma non c'era niente («Nessuna scadenza nei prossimi tre mesi»).
        case vuoto
        /// Ha preparato una o più azioni per la scheda «Conferma».
        case daConfermare
        /// Lo strumento non è ancora pronto in Prisma, oppure serve qualcosa dal consulente (il PDF firmato).
        case inAttesa
        /// Non si può fare (manca il cliente, la proposta…).
        case impossibile
    }

    var tipo: TipoPassoRoutine
    /// «Apro la scheda di Marco Bianchi».
    var titolo: String
    /// «45 anni, imprenditore · oggi alle 11:00 in videochiamata».
    var dettaglio: String
    var stato: Stato
    /// Da dove viene quello che dice («La scheda», «Studio», «Agenda»…): «Mai a caso».
    var fonte: String
}

/// Il risultato pronto in fondo alla routine.
struct RisultatoRoutine: Codable, Equatable {
    var titolo: String
    var righe: [String]
    var pulsanti: [PulsanteRoutine]
}

/// Un lancio di una routine: i passi spuntati, il risultato e le azioni da confermare.
struct EsitoRoutine: Codable, Equatable, Identifiable {
    var id = "esito-routine-\(UUID().uuidString.prefix(8).lowercased())"
    var routineId: String
    var titolo: String
    /// La frase del consulente (o «Ogni lunedì alle 8:30» per un lancio programmato).
    var richiesta: String
    var clienteId: String?
    var data: Date
    var passi: [EsitoPassoRoutine] = []
    var risultato = RisultatoRoutine(titolo: "", righe: [], pulsanti: [])
    /// Solo «Prepara l'incontro»: la scaletta con i minuti.
    var scaletta: [RigaScaletta] = []
    /// Le azioni preparate, da mostrare nella scheda «Conferma» (nessuna è stata eseguita).
    var azioni: [AzioneConferma] = []
    /// Manca un dato che solo il consulente può dare («Per quale cliente?»): i passi non sono partiti.
    var domanda: String?

    init(routineId: String, titolo: String, richiesta: String, clienteId: String?, data: Date) {
        self.routineId = routineId
        self.titolo = titolo
        self.richiesta = richiesta
        self.clienteId = clienteId
        self.data = data
    }

    /// La scheda di conferma con le azioni preparate (nil se non ce ne sono).
    var schedaConferma: SchedaConfermaVera? {
        azioni.isEmpty ? nil : SchedaConfermaVera(richiesta: richiesta, azioni: azioni, origine: .regole)
    }
}

/// Le routine nell'archivio (da collegare a `DatiPrisma`): le salvate, lo stato delle pronte e gli ultimi esiti.
struct ArchivioRoutine: Codable, Equatable {
    var routine: [RoutineVera] = []
    var esiti: [EsitoRoutine] = []

    static let esitiMassimi = 20

    init(routine: [RoutineVera] = [], esiti: [EsitoRoutine] = []) {
        self.routine = routine
        self.esiti = esiti
    }

    /// Le routine da mostrare: le salvate, più le pronte che non ci sono ancora (le pronte prima, nell'ordine del template).
    var tutte: [RoutineVera] {
        let pronte = RoutineVera.pronte().map { p in routine.first { $0.id == p.id } ?? p }
        return pronte + routine.filter { r in !pronte.contains { $0.id == r.id } }
    }

    private enum CodingKeys: String, CodingKey { case routine, esiti }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        routine = ((try? c.decodeIfPresent(ElencoTollerante<RoutineVera>.self, forKey: .routine)) ?? nil)?.elementi ?? []
        esiti = ((try? c.decodeIfPresent(ElencoTollerante<EsitoRoutine>.self, forKey: .esiti)) ?? nil)?.elementi ?? []
    }
}

/// Dove gira una routine: i dati, il giorno e quello che la frase ha detto (cliente, proposta, file trascinato).
struct ContestoRoutine {
    var dati: DatiPrisma
    var oggi: Date
    var clienteId: String?
    /// La posizione firmata, se la Shell la conosce (l'evento «firma»).
    var posizioneId: String?
    /// Il PDF del contratto firmato, se è stato trascinato con la frase.
    var file: String?
    var calendario = Calendar.current

    init(dati: DatiPrisma, oggi: Date, clienteId: String? = nil, posizioneId: String? = nil, file: String? = nil,
         calendario: Calendar = .current) {
        self.dati = dati
        self.oggi = oggi
        self.clienteId = clienteId
        self.posizioneId = posizioneId
        self.file = file
        self.calendario = calendario
    }
}

/// La routine riconosciuta in una frase, con il cliente nominato.
struct LancioRoutine: Equatable {
    var routine: RoutineVera
    var clienteId: String?
}

// MARK: - Le routine pronte e il motore

extension RoutineVera {
    static let idPrepara = "routine-prepara-incontro"
    static let idLunedi = "routine-il-mio-lunedi"
    static let idFineMese = "routine-fine-mese"
    static let idDopoFirma = "routine-dopo-la-firma"

    /// Strumenti nuovi che le routine preparano (da registrare in RegistroStrumenti ed eseguire in FalloTuShell).
    static let strumentoPosizioneFirmata = "posizioni_segna_firmata"
    static let strumentoSalva = "routine_salva"

    /// Il primo controllo dopo la firma, se la frase non dice altro.
    static let mesiControllo = 6
    /// Le scadenze del cliente da guardare prima di un incontro.
    static let giorniScadenzeCliente = 90
    /// Le scadenze da contare nel «mio lunedì».
    static let giorniScadenzeSettimana = 30
    /// Una routine programmata, se Prisma era chiuso all'ora giusta, parte ancora entro tanti giorni.
    static let giorniRecupero = 3
    /// Il mese da chiudere è quello prima nei primi giorni del mese (la «Fine mese» lanciata in ritardo).
    static let giorniMesePrima = 3
    /// Al più tanti passi in una routine.
    static let passiMassimi = 8
    /// Le durate della scaletta si arrotondano a 5 minuti.
    static let passoMinuti = 5

    private static let innescoFirma = #"\bho firmato\b|\babbiamo firmato\b|\bha firmato\b|\bdopo la firma\b|\bfirmato con\b"#

    /// Le quattro routine del template.
    static func pronte() -> [RoutineVera] {
        let inizio = Date(timeIntervalSinceReferenceDate: 0)
        let prepara = RoutineVera(id: idPrepara, titolo: "Prepara l'incontro", frase: "Vera, prepara l'incontro con Marco",
                                  inneschi: [#"\bprepara(?:mi)?\b.*\b(?:incontro|appuntamento|colloquio|riunione|scaletta)\b"#],
                                  passi: [PassoRoutine(.schedaCliente), PassoRoutine(.ultimoIncontro), PassoRoutine(.scadenzeCliente),
                                          PassoRoutine(.cosaManca), PassoRoutine(.scaletta)],
                                  pronta: true, creataIl: inizio)
        let lunedi = RoutineVera(id: idLunedi, titolo: "Il mio lunedì", frase: "Vera, com'è la settimana?",
                                 inneschi: [#"\bcom'(?:è|e) (?:la|questa) (?:mia )?settimana\b"#, #"\bcome (?:va|è|e'|sarà) (?:la|questa) (?:mia )?settimana\b"#,
                                            #"\bil mio lunedì\b"#, #"\bla mia settimana\b"#, #"\bcosa (?:c'è|ho) questa settimana\b"#],
                                 passi: [PassoRoutine(.agendaSettimana), PassoRoutine(.buchiSettimana), PassoRoutine(.promesseScadenze),
                                         PassoRoutine(.mossaSettimana)],
                                 programmazione: ProgrammazioneRoutine(tipo: .settimanale, giorno: 2, ora: 8, minuto: 30),
                                 pronta: true, creataIl: inizio)
        let fineMese = RoutineVera(id: idFineMese, titolo: "Fine mese", frase: "Vera, chiudiamo il mese",
                                   inneschi: [#"\bchiud(?:iamo|i|ere) il mese\b"#, #"\bfine (?:del )?mese\b"#, #"\bchiusura del mese\b"#],
                                   passi: [PassoRoutine(.parcelleMese), PassoRoutine(.chilometriMese), PassoRoutine(.fattureDaEmettere),
                                           PassoRoutine(.scadenzeMeseDopo)],
                                   programmazione: ProgrammazioneRoutine(tipo: .fineMese, ora: 17, minuto: 30),
                                   pronta: true, creataIl: inizio)
        let firma = RoutineVera(id: idDopoFirma, titolo: "Dopo la firma", frase: "Vera, ho firmato con Giulia",
                                inneschi: [innescoFirma],
                                passi: [PassoRoutine(.archiviaContratto), PassoRoutine(.aggiornaPosizioni),
                                        PassoRoutine(.fissaControllo, mesi: mesiControllo), PassoRoutine(.messaggioBenvenuto)],
                                programmazione: ProgrammazioneRoutine(tipo: .dopoFirma),
                                pronta: true, creataIl: inizio)
        return [prepara, lunedi, fineMese, firma]
    }

    // MARK: - Riconoscere la frase

    /// La routine della frase, con il cliente (nominato, o quello aperto se non ne nomina nessuno). Le routine del
    /// consulente vincono sulle pronte (una sua «quando firmo…» prende il posto di «Dopo la firma»). nil se nessuna.
    static func riconosci(_ testo: String, routine: [RoutineVera], clienti: [ClienteNoto], attivo: String?) -> LancioRoutine? {
        let t = InterpreteComandi.pulisci(testo)
        guard !t.isEmpty else { return nil }
        let ordinate = routine.filter { $0.attiva && !$0.pronta } + routine.filter { $0.attiva && $0.pronta }
        guard let r = ordinate.first(where: { r in r.inneschi.contains { DateItaliane.cerca($0, t) != nil } }) else { return nil }
        guard r.serveCliente else { return LancioRoutine(routine: r, clienteId: nil) }
        let nominati = InterpreteComandi.clientiNominati(t, clienti)
        switch nominati.count {
        case 1: return LancioRoutine(routine: r, clienteId: nominati[0].id)
        case 0:
            // «Ho firmato con Rossi» e Rossi non è un cliente: non è «nessun nome», non vale il cliente aperto
            return LancioRoutine(routine: r, clienteId: nomeSconosciuto(testo) ? nil : attivo)
        default: return LancioRoutine(routine: r, clienteId: nil)
        }
    }

    /// Le parole con la maiuscola dopo «con/di/per» che non sono nomi di clienti (Vera stessa, i canali).
    private static let nonNomi: Set<String> = ["vera", "ruby", "eve", "alleanza", "prisma", "denis"]

    /// true se la frase originale nomina qualcuno con la maiuscola dopo «con», «di» o «per» (già sappiamo che non è
    /// un cliente: `clientiNominati` non l'ha trovato).
    static func nomeSconosciuto(_ testo: String) -> Bool {
        let t = testo.replacingOccurrences(of: "’", with: "'")
        guard let re = try? NSRegularExpression(pattern: #"\b(?:con|di|per)\s+(\p{Lu}[\p{L}']+)"#) else { return false }
        let r = NSRange(t.startIndex..., in: t)
        return re.matches(in: t, range: r).contains { m in
            guard let g = Range(m.range(at: 1), in: t) else { return false }
            return !nonNomi.contains(t[g].lowercased())
        }
    }

    // MARK: - Programmazione (solo con Prisma aperto)

    /// L'ultima volta che la programmazione cadeva, non dopo `adesso` (nil per «dopo ogni firma»).
    static func ultimaOccorrenza(_ p: ProgrammazioneRoutine, finoA adesso: Date, cal: Calendar = .current) -> Date? {
        let oggi = cal.startOfDay(for: adesso)
        switch p.tipo {
        case .dopoFirma:
            return nil
        case .settimanale:
            for indietro in 0...7 {
                guard let g = cal.date(byAdding: .day, value: -indietro, to: oggi),
                      cal.component(.weekday, from: g) == p.giorno,
                      let d = cal.date(bySettingHour: p.ora, minute: p.minuto, second: 0, of: g) else { continue }
                if d <= adesso { return d }
            }
            return nil
        case .fineMese:
            guard let inizioMese = cal.date(from: cal.dateComponents([.year, .month], from: oggi)) else { return nil }
            for mesi in [0, -1] {
                guard let inizio = cal.date(byAdding: .month, value: mesi, to: inizioMese),
                      let dopo = cal.date(byAdding: .month, value: 1, to: inizio),
                      let ultimo = cal.date(byAdding: .day, value: -1, to: dopo),
                      let d = cal.date(bySettingHour: p.ora, minute: p.minuto, second: 0, of: ultimo) else { continue }
                if d <= adesso { return d }
            }
            return nil
        }
    }

    /// Le routine programmate da lanciare adesso: l'ultima occorrenza è dopo l'ultimo lancio (o dopo la creazione) e
    /// non è più vecchia di `giorniRecupero` giorni. Le routine «dopo ogni firma» non sono mai dovute qui: partono
    /// con l'evento (`perEvento`).
    static func dovute(_ routine: [RoutineVera], adesso: Date, cal: Calendar = .current) -> [RoutineVera] {
        routine.filter { r in
            guard r.attiva, let p = r.programmazione, let occ = ultimaOccorrenza(p, finoA: adesso, cal: cal) else { return false }
            let base = r.ultimoLancio ?? r.creataIl
            guard occ > base else { return false }
            let limite = cal.date(byAdding: .day, value: giorniRecupero, to: occ) ?? occ
            return adesso < limite
        }
    }

    /// Le routine che partono con un evento (oggi solo la firma).
    static func perEvento(_ tipo: ProgrammazioneRoutine.Tipo, _ routine: [RoutineVera]) -> [RoutineVera] {
        routine.filter { $0.attiva && $0.programmazione?.tipo == tipo && tipo == .dopoFirma }
    }

    /// La routine dopo un lancio: una volta in più, con la data.
    static func lanciata(_ r: RoutineVera, il data: Date) -> RoutineVera {
        var n = r
        n.usata += 1
        n.ultimoLancio = data
        return n
    }

    /// L'archivio dopo un lancio: la routine aggiornata (salvata anche se era una pronta) e l'esito in fondo, al più
    /// `ArchivioRoutine.esitiMassimi`.
    static func registra(_ esito: EsitoRoutine, in archivio: ArchivioRoutine) -> ArchivioRoutine {
        var a = archivio
        if let r = a.tutte.first(where: { $0.id == esito.routineId }) {
            let nuova = lanciata(r, il: esito.data)
            if let i = a.routine.firstIndex(where: { $0.id == r.id }) { a.routine[i] = nuova } else { a.routine.append(nuova) }
        }
        a.esiti.append(esito)
        if a.esiti.count > ArchivioRoutine.esitiMassimi { a.esiti.removeFirst(a.esiti.count - ArchivioRoutine.esitiMassimi) }
        return a
    }

    // MARK: - Eseguire

    /// Esegue i passi uno alla volta sui dati: legge, calcola con i motori di Prisma e accumula le azioni da confermare.
    /// Niente viene cambiato: i dati arrivano per valore e le azioni restano nell'esito.
    static func esegui(_ r: RoutineVera, richiesta: String, contesto x: ContestoRoutine) -> EsitoRoutine {
        let cliente = x.clienteId.flatMap { id in x.dati.clienti.first { $0.id == id } }
        var esito = EsitoRoutine(routineId: r.id, titolo: r.titolo, richiesta: richiesta, clienteId: cliente?.id, data: x.oggi)
        if r.serveCliente && cliente == nil {
            esito.domanda = x.clienteId == nil ? "Per quale cliente?" : "Non trovo il cliente tra quelli in Prisma."
            esito.risultato = RisultatoRoutine(titolo: r.titolo, righe: [], pulsanti: [])
            return esito
        }
        var l = Lavagna()
        l.cliente = cliente
        for p in r.passi.prefix(passiMassimi) { esito.passi.append(passo(p, x, &l)) }
        esito.azioni = l.azioni
        esito.scaletta = l.scaletta
        let titolo = l.titolo ?? titoloRisultato(r, l)
        esito.risultato = RisultatoRoutine(titolo: titolo, righe: l.righe.isEmpty ? ["Niente da segnalare."] : l.righe,
                                           pulsanti: Array(l.pulsantiOrdinati.prefix(2)))
        return esito
    }

    /// Quello che i passi scrivono e si passano (il prossimo incontro, le scadenze, il controllo fissato…).
    private struct Lavagna {
        var cliente: Cliente?
        var appuntamento: Appuntamento?
        var cercatoAppuntamento = false
        var ultimoIncontro: Incontro?
        var scadenze: [Posizione]?
        var promesse: [PromessaCliente] = []
        var mancanze: [String]?
        var posizione: Posizione?
        var cercataPosizione = false
        var controllo: Date?
        var titolo: String?
        var righe: [String] = []
        var scaletta: [RigaScaletta] = []
        /// I pulsanti con la loro importanza (3 = il principale della routine, 1 = di contorno).
        var pulsanti: [(PulsanteRoutine, Int)] = []
        var azioni: [AzioneConferma] = []

        mutating func pulsante(_ titolo: String, _ app: AppPrisma, _ cliente: String? = nil, peso: Int) {
            if !pulsanti.contains(where: { $0.0.titolo == titolo }) { pulsanti.append((PulsanteRoutine(titolo: titolo, app: app, clienteId: cliente), peso)) }
        }

        /// I pulsanti dal più importante; a parità, nell'ordine dei passi.
        var pulsantiOrdinati: [PulsanteRoutine] {
            pulsanti.enumerated().sorted { ($1.element.1, $0.offset) < ($0.element.1, $1.offset) }.map { $0.element.0 }
        }
    }

    private static func titoloRisultato(_ r: RoutineVera, _ l: Lavagna) -> String {
        switch r.id {
        case idLunedi: return "La tua settimana in \(l.righe.count <= 1 ? "una riga" : "\(SchedaConfermaVera.numero(l.righe.count)) righe")"
        case idFineMese: return "Il mese è chiuso"
        case idDopoFirma: return "Tutto in ordine dopo la firma"
        default: return r.titolo
        }
    }

    private static func passo(_ p: PassoRoutine, _ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        switch p.tipo {
        case .schedaCliente: return schedaCliente(x, &l)
        case .ultimoIncontro: return ultimoIncontro(x, &l)
        case .scadenzeCliente: return scadenzeCliente(x, &l)
        case .cosaManca: return cosaManca(x, &l)
        case .scaletta: return scaletta(x, &l)
        case .agendaSettimana: return agendaSettimana(x, &l)
        case .buchiSettimana: return buchiSettimana(x, &l)
        case .promesseScadenze: return promesseScadenze(x, &l)
        case .mossaSettimana: return mossaSettimana(x, &l)
        case .parcelleMese: return parcelleMese(x, &l)
        case .chilometriMese: return chilometriMese(x, &l)
        case .fattureDaEmettere: return fattureDaEmettere(x, &l)
        case .scadenzeMeseDopo: return scadenzeMeseDopo(x, &l)
        case .archiviaContratto: return archiviaContratto(x, &l)
        case .aggiornaPosizioni: return aggiornaPosizioni(x, &l)
        case .fissaControllo: return fissaControllo(p.mesi ?? mesiControllo, x, &l)
        case .messaggioBenvenuto: return messaggioBenvenuto(x, &l)
        }
    }

    // MARK: - Aiuti

    private static func formato(_ schema: String, _ cal: Calendar) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.calendar = cal
        f.timeZone = cal.timeZone
        f.dateFormat = schema
        return f
    }

    static func giornoIso(_ d: Date, cal: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = cal
        f.timeZone = cal.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    static func elenco(_ parti: [String]) -> String {
        switch parti.count {
        case 0: return ""
        case 1: return parti[0]
        default: return parti.dropLast().joined(separator: ", ") + " e " + parti[parti.count - 1]
        }
    }

    private static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
    private static func minuscola(_ s: String) -> String { s.prefix(1).lowercased() + s.dropFirst() }
    private static func primoNome(_ nome: String) -> String { nome.split(separator: " ").first.map(String.init) ?? nome }

    private static func contestoStrumenti(_ x: ContestoRoutine, attivo: String?) -> ContestoStrumenti {
        ContestoStrumenti(oggi: x.oggi, clienti: x.dati.clienti, appuntamenti: x.dati.appuntamenti, posizioni: x.dati.posizioni,
                          attivo: attivo, impostazioni: x.dati.impostazioni, calendario: x.calendario)
    }

    /// Prepara un'azione con il registro, come «Fallo tu»: la stessa esecuzione dopo «Conferma».
    private static func prepara(_ nome: String, _ argomenti: [String: Any], _ x: ContestoRoutine, attivo: String?) -> AzioneConferma? {
        if case .azione(let a) = RegistroStrumenti.prepara(ChiamataStrumento(nome: nome, argomenti: argomenti), contesto: contestoStrumenti(x, attivo: attivo)) {
            return a
        }
        return nil
    }

    /// «in studio», «in videochiamata», «al telefono».
    private static func dove(_ luogo: String) -> String {
        let t = luogo.trimmingCharacters(in: .whitespaces).lowercased()
        if t.isEmpty { return "" }
        if t.contains("telefon") { return "al telefono" }
        if t.hasPrefix("in ") || t.hasPrefix("a ") || t.hasPrefix("da ") { return t }
        if t.contains("video") { return "in videochiamata" }
        return t
    }

    /// Il prossimo impegno del cliente da oggi (compreso).
    private static func prossimoAppuntamento(_ c: Cliente, _ x: ContestoRoutine) -> Appuntamento? {
        let inizio = x.calendario.startOfDay(for: x.oggi)
        return x.dati.appuntamenti
            .filter { $0.clienteId == c.id && $0.stato == .pianificato && $0.tipo != .nonDisponibile && $0.inizio >= inizio }
            .min { $0.inizio < $1.inizio }
    }

    private static func scadenzeDi(_ c: Cliente, _ x: ContestoRoutine) -> [Posizione] {
        let cal = x.calendario
        let inizio = cal.startOfDay(for: x.oggi)
        let fine = cal.date(byAdding: .day, value: giorniScadenzeCliente, to: inizio) ?? inizio
        return x.dati.posizioni
            .filter { $0.clienteId == c.id && $0.stato == .inEssere && $0.area != .debiti && ($0.scadenza.map { $0 >= inizio && $0 <= fine } ?? false) }
            .sorted { ($0.scadenza ?? inizio, $0.id) < ($1.scadenza ?? inizio, $1.id) }
    }

    private static func aperta(_ p: PromessaCliente) -> Bool { p.stato == .aperta || p.stato == .rimandata }

    private static func nomePosizione(_ p: Posizione) -> String {
        let n = p.nome.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? p.area.nome : n
    }

    /// La durata arrotondata al passo della scaletta (42 → 40, 43 → 45; almeno un passo).
    static func durataScaletta(_ durata: Int) -> Int {
        let p = max(1, passoMinuti)
        return max(p, Int((Double(durata) / Double(p)).rounded()) * p)
    }

    /// Le durate della scaletta in proporzione ai pesi, a multipli di 5 minuti (almeno 5 per punto), con la somma
    /// uguale alla durata arrotondata al passo (`durataScaletta`). Se la durata non basta per 5 minuti a punto, si
    /// tengono solo i primi punti (quelli più importanti, nell'ordine della scaletta): l'elenco può essere più corto
    /// dei pesi. Ogni punto ha un passo, gli altri passi vanno in proporzione ai pesi (resti più grandi per primi).
    static func ripartisci(_ durata: Int, pesi: [Int]) -> [Int] {
        guard !pesi.isEmpty else { return [] }
        let p = max(1, passoMinuti)
        let passi = durataScaletta(durata) / p
        let quanti = min(pesi.count, passi)
        guard quanti > 0 else { return [] }
        var w = pesi.prefix(quanti).map { max(0, $0) }
        if w.reduce(0, +) == 0 { w = Array(repeating: 1, count: quanti) }
        let totale = w.reduce(0, +)
        let resto = passi - quanti
        let quote = w.map { Double(resto) * Double($0) / Double(totale) }
        var unita = quote.map { 1 + Int($0.rounded(.down)) }
        var mancano = passi - unita.reduce(0, +)
        // I passi che restano: ai resti più grandi, a parità al peso più grande, poi al primo
        let ordine = w.indices.sorted { a, b in
            let ra = quote[a] - quote[a].rounded(.down), rb = quote[b] - quote[b].rounded(.down)
            return ra != rb ? ra > rb : (w[a] != w[b] ? w[a] > w[b] : a < b)
        }
        var k = 0
        while mancano > 0 {
            unita[ordine[k % ordine.count]] += 1
            mancano -= 1
            k += 1
        }
        return unita.map { $0 * p }
    }

    // MARK: - Prepara l'incontro

    private static func schedaCliente(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.schedaCliente) }
        let cal = x.calendario
        var chi: [String] = []
        if let n = c.dataNascita, let anni = cal.dateComponents([.year], from: n, to: x.oggi).year { chi.append("\(anni) anni") }
        let lavoro = c.professione.trimmingCharacters(in: .whitespaces)
        if !lavoro.isEmpty { chi.append(lavoro.lowercased()) }
        let a = prossimoAppuntamento(c, x)
        l.appuntamento = a
        l.cercatoAppuntamento = true
        let quando = a.map { a -> String in
            let d = dove(a.luogo)
            return DateItaliane.descrivi(a.inizio, conOra: true, oggi: x.oggi, cal: cal) + (d.isEmpty ? "" : " \(d)")
        } ?? "nessun incontro in agenda"
        let primo = chi.isEmpty ? "" : chi.joined(separator: ", ") + " · "
        l.pulsante("Apri la scheda", .clienti, c.id, peso: 1)
        return EsitoPassoRoutine(tipo: .schedaCliente, titolo: "Apro la scheda di \(c.nome)", dettaglio: primo + quando, stato: .fatto, fonte: "La scheda e l'agenda")
    }

    private static func ultimoIncontro(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.ultimoIncontro) }
        let titolo = "Riassumo l'ultimo incontro"
        if let i = x.dati.incontri.filter({ $0.clienteId == c.id && $0.stato == .concluso && $0.data <= x.oggi }).max(by: { $0.data < $1.data }) {
            l.ultimoIncontro = i
            let testo = [i.decisioni, i.progetti, i.appunti, i.titolo]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.first(where: { !$0.isEmpty }) ?? i.titolo
            let frase = PromesseVera.frasi(testo).first ?? testo
            let breve = frase.count > 140 ? String(frase.prefix(137)) + "…" : frase
            return EsitoPassoRoutine(tipo: .ultimoIncontro, titolo: titolo,
                              dettaglio: "\(formato("d MMMM", x.calendario).string(from: i.data)): \(breve)", stato: .fatto, fonte: "Incontri")
        }
        if let a = x.dati.appuntamenti.filter({ $0.clienteId == c.id && $0.stato == .concluso && $0.inizio <= x.oggi }).max(by: { $0.inizio < $1.inizio }) {
            let nota = a.note.trimmingCharacters(in: .whitespacesAndNewlines)
            return EsitoPassoRoutine(tipo: .ultimoIncontro, titolo: titolo,
                              dettaglio: "\(formato("d MMMM", x.calendario).string(from: a.inizio)): \(a.titolo)" + (nota.isEmpty ? "" : " · \(nota)"),
                              stato: .fatto, fonte: "Agenda")
        }
        return EsitoPassoRoutine(tipo: .ultimoIncontro, titolo: titolo, dettaglio: "Non ci sono incontri registrati: è il primo",
                          stato: .vuoto, fonte: "Incontri")
    }

    private static func scadenzeCliente(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.scadenzeCliente) }
        let pos = scadenzeDi(c, x)
        l.scadenze = pos
        let promesse = x.dati.promesse.filter { $0.clienteId == c.id && aperta($0) }
            .sorted { ($0.scadenzaAttuale ?? .distantFuture) < ($1.scadenzaAttuale ?? .distantFuture) }
        l.promesse = promesse
        let ritardo = promesse.filter { PromesseVera.semaforo($0, oggi: x.oggi) == .inRitardo }.count
        var parti: [String] = []
        if let p = pos.first, let s = p.scadenza {
            parti.append("\(nomePosizione(p)): scade il \(formato("d MMMM", x.calendario).string(from: s))"
                         + (pos.count > 1 ? " (e altre \(pos.count - 1))" : ""))
        }
        if ritardo > 0 { parti.append(ritardo == 1 ? "1 promessa in ritardo" : "\(ritardo) promesse in ritardo") }
        let titolo = "Controllo le scadenze"
        guard !parti.isEmpty else {
            return EsitoPassoRoutine(tipo: .scadenzeCliente, titolo: titolo, dettaglio: "Nessuna scadenza nei prossimi tre mesi", stato: .vuoto, fonte: "Posizioni e promesse")
        }
        return EsitoPassoRoutine(tipo: .scadenzeCliente, titolo: titolo, dettaglio: parti.joined(separator: " · "), stato: .fatto, fonte: "Posizioni e promesse")
    }

    private static func cosaManca(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.cosaManca) }
        let mancanze = mancanzeDi(c, x)
        l.mancanze = mancanze
        let titolo = "Cerco cosa manca"
        guard !mancanze.isEmpty else {
            return EsitoPassoRoutine(tipo: .cosaManca, titolo: titolo, dettaglio: "I dati per le analisi ci sono tutti", stato: .vuoto, fonte: "Completezza dei dati")
        }
        return EsitoPassoRoutine(tipo: .cosaManca, titolo: titolo, dettaglio: maiuscola(elenco(Array(mancanze.prefix(2)).map { minuscola($0) })),
                          stato: .fatto, fonte: "Completezza dei dati")
    }

    private static func mancanzeDi(_ c: Cliente, _ x: ContestoRoutine) -> [String] {
        let completezza = MotoreCompletezza.calcola(cliente: c, posizioni: x.dati.posizioni.filter { $0.clienteId == c.id },
                                                    analisi: x.dati.analisi[c.id], oggi: x.calendario.startOfDay(for: x.oggi))
        var m = completezza.daCompletare.prefix(3).map(\.titolo)
        if !c.consensi.privacy { m.insert("Il consenso privacy", at: 0) }
        return m
    }

    /// Il familiare (coniuge o convivente) senza una protezione propria in essere.
    private static func familiareScoperto(_ c: Cliente, _ x: ContestoRoutine) -> Familiare? {
        let protezioni = x.dati.posizioni.filter { $0.clienteId == c.id && $0.stato == .inEssere && $0.area == .protezione }
        return c.famiglia.first { m in
            (m.relazione == .coniuge || m.relazione == .convivente)
                && !protezioni.contains { MotoreProtezioneFamiglia.assicurato($0, cliente: c) == m.id }
        }
    }

    private static func scaletta(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.scaletta) }
        let cal = x.calendario
        if !l.cercatoAppuntamento {
            l.appuntamento = prossimoAppuntamento(c, x)
            l.cercatoAppuntamento = true
        }
        let scadenze = l.scadenze ?? scadenzeDi(c, x)
        let mancanze = l.mancanze ?? mancanzeDi(c, x)
        let giorno = formato("d MMMM", cal)
        var punti: [(String, Int)] = []

        // 1. La scadenza più vicina, altrimenti la promessa in ritardo
        if let p = scadenze.first, let s = p.scadenza {
            punti.append(("Rinnovo di «\(nomePosizione(p))» entro il \(giorno.string(from: s))", 2))
        } else if let p = (l.promesse.isEmpty ? x.dati.promesse.filter({ $0.clienteId == c.id && aperta($0) }) : l.promesse)
                    .first(where: { PromesseVera.semaforo($0, oggi: x.oggi) == .inRitardo }) {
            punti.append((maiuscola(p.testo), 2))
        }
        // 2. La protezione del coniuge, altrimenti la proposta aperta, altrimenti i dati che mancano
        let proposte = x.dati.posizioni
            .filter { $0.clienteId == c.id && $0.stato == .proposta && $0.esito != .rifiutata && $0.esito != .accettata }
            .sorted { ($0.creataIl, $0.id) > ($1.creataIl, $1.id) }
        var propostaUsata = false
        if let f = familiareScoperto(c, x) {
            punti.append(("Una protezione per \(primoNome(f.nome))", 4))
        } else if let p = proposte.first {
            punti.append(("La proposta «\(nomePosizione(p))»", 4))
            propostaUsata = true
        } else if let m = mancanze.first {
            punti.append(("Completare i dati: \(minuscola(m))", 3))
        }
        // 3. La proposta (se non è già entrata), altrimenti l'obiettivo, altrimenti quanto deciso l'ultima volta
        let obiettivi = x.dati.obiettivi.filter { $0.clienteId == c.id && $0.raggiuntoIl == nil }
            .sorted { ($0.priorita, $1.scadenza) > ($1.priorita, $0.scadenza) }
        if !propostaUsata, let p = proposte.first {
            punti.append(("La proposta «\(nomePosizione(p))»", 3))
        } else if let o = obiettivi.first {
            punti.append(("Un piano per «\(o.titolo)»", 3))
        } else if let d = l.ultimoIncontro?.decisioni.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty {
            punti.append(("Riprendere quanto deciso: \(minuscola(PromesseVera.frasi(d).first ?? d))", 3))
        }
        if punti.isEmpty { punti.append(("Il punto sulla situazione e sugli obiettivi", 1)) }

        let durata = durataScaletta(l.appuntamento?.durataMinuti ?? 45)
        let minuti = ripartisci(durata, pesi: punti.map { $0.1 })
        // Con un incontro brevissimo restano solo i primi punti (zip si ferma ai minuti)
        punti = Array(punti.prefix(minuti.count))
        l.scaletta = zip(punti, minuti).map { RigaScaletta(testo: $0.0.0, minuti: $0.1) }
        l.righe = l.scaletta.map { "\($0.testo) · \($0.minuti) minuti" }
        if let a = l.appuntamento {
            let luogo = a.luogo.trimmingCharacters(in: .whitespaces)
            let quando = cal.isDate(a.inizio, inSameDayAs: x.oggi)
                ? "le \(formato("HH:mm", cal).string(from: a.inizio))"
                : DateItaliane.descrivi(a.inizio, conOra: true, oggi: x.oggi, cal: cal)
            l.titolo = "La scaletta per \(quando)" + (luogo.isEmpty ? "" : " · \(luogo)")
        } else {
            l.titolo = "La scaletta per il prossimo incontro"
        }
        l.pulsante("Apri in Incontri", .incontri, c.id, peso: 3)

        // L'ordine del giorno per il cliente: una bozza da confermare, mai spedita da qui
        var stato = EsitoPassoRoutine.Stato.fatto
        if let a = l.appuntamento {
            let quando = DateItaliane.descrivi(a.inizio, conOra: true, oggi: x.oggi, cal: cal)
            let firma = x.dati.impostazioni.nomeUtente.trimmingCharacters(in: .whitespaces)
            let testo = "Buongiorno \(primoNome(c.nome)), per il nostro incontro di \(quando) le propongo questi punti: "
                + l.scaletta.map { minuscola($0.testo) }.joined(separator: "; ") + ". A presto" + (firma.isEmpty ? "." : ", \(firma)")
            if let azione = prepara(RegistroStrumenti.messaggiPrepara, ["cliente": c.id, "scopo": "promemoria", "testo": testo], x, attivo: c.id) {
                l.azioni.append(azione)
                l.pulsante("Manda a \(primoNome(c.nome)) l'ordine del giorno", .messaggi, c.id, peso: 2)
                stato = .daConfermare
            }
        }
        let numeri = ["Nessun punto", "Un punto", "Due punti", "Tre punti", "Quattro punti"]
        let quanti = punti.count < numeri.count ? numeri[punti.count] : "\(punti.count) punti"
        return EsitoPassoRoutine(tipo: .scaletta, titolo: "Preparo la scaletta", dettaglio: "\(quanti) per \(durata) minuti", stato: stato,
                          fonte: "Scheda, posizioni, obiettivi e agenda")
    }

    // MARK: - Il mio lunedì

    /// I giorni di lavoro della settimana di `oggi`: i giorni di OrariLavoro, senza le festività (se `orari.festivi`),
    /// come in «Pianifica» (`MotorePianificazione.lavorativo`).
    private static func giorniLavoro(_ x: ContestoRoutine) -> [Date] {
        let cal = x.calendario
        let settimana = MotoreStorie.settimanaDi(x.oggi, cal: cal)
        let orari = x.dati.impostazioni.orari
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: settimana.start) }
            .filter { MotorePianificazione.lavorativo($0, orari: orari, cal: cal) }
    }

    private static func impegniSettimana(_ x: ContestoRoutine) -> [Appuntamento] {
        let settimana = MotoreStorie.settimanaDi(x.oggi, cal: x.calendario)
        return x.dati.appuntamenti
            .filter { $0.inizio >= settimana.start && $0.inizio < settimana.end && $0.tipo != .nonDisponibile }
            .sorted { $0.inizio < $1.inizio }
    }

    private static func agendaSettimana(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        let cal = x.calendario
        let impegni = impegniSettimana(x)
        let giorni = giorniLavoro(x)
        let f = formato("EEEE d", cal)
        let arco = giorni.isEmpty ? "questa settimana" : "da \(f.string(from: giorni[0])) a \(f.string(from: giorni[giorni.count - 1]))"
        l.pulsante("Apri l'agenda", .agenda, peso: 3)
        guard !impegni.isEmpty else {
            return EsitoPassoRoutine(tipo: .agendaSettimana, titolo: "Leggo l'agenda", dettaglio: "Nessun impegno \(arco)", stato: .vuoto, fonte: "Agenda")
        }
        // Il giorno pieno: quello con più impegni (almeno due)
        let perGiorno = Dictionary(grouping: impegni) { cal.startOfDay(for: $0.inizio) }
        if let pieno = perGiorno.max(by: { ($0.value.count, $1.key) < ($1.value.count, $0.key) }), pieno.value.count >= 2 {
            let clienti = Dictionary(x.dati.clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let chi = pieno.value.map { a -> String in
                let nome = clienti[a.clienteId].map { primoNome($0.nome) } ?? a.titolo
                return a.tipo == .telefonata ? "la telefonata a \(nome)" : nome
            }
            l.righe.append("\(maiuscola(formato("EEEE", cal).string(from: pieno.key))) è il giorno pieno: \(elenco(chi))")
        }
        let n = impegni.count
        return EsitoPassoRoutine(tipo: .agendaSettimana, titolo: "Leggo l'agenda", dettaglio: "\(n) \(n == 1 ? "impegno" : "impegni") \(arco)",
                          stato: .fatto, fonte: "Agenda")
    }

    private static func buchiSettimana(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        let cal = x.calendario
        let orari = x.dati.impostazioni.orari
        var fasce: [(String, FasciaOraria)] = [("mattina", orari.mattina)]
        if orari.pomeriggioAttivo { fasce.append(("pomeriggio", orari.pomeriggio)) }
        let occupati = x.dati.appuntamenti.filter { $0.stato == .pianificato }
        var liberi: [(Date, String)] = []
        for g in giorniLavoro(x) {
            for (nome, fascia) in fasce where fascia.valida {
                guard let inizio = cal.date(byAdding: .minute, value: fascia.inizio, to: g),
                      let fine = cal.date(byAdding: .minute, value: fascia.fine, to: g), fine > x.oggi else { continue }
                if !occupati.contains(where: { $0.inizio < fine && $0.fine > inizio }) { liberi.append((g, nome)) }
            }
        }
        let titolo = "Cerco i buchi"
        guard let libero = liberi.first else {
            return EsitoPassoRoutine(tipo: .buchiSettimana, titolo: titolo, dettaglio: "Nessuna mezza giornata libera", stato: .vuoto, fonte: "Agenda")
        }
        let (giorno, fascia) = libero
        let nomeGiorno = maiuscola(formato("EEEE", cal).string(from: giorno))
        let altre = liberi.count - 1
        let dettaglio = "\(nomeGiorno) \(fascia) è libero" + (altre > 0 ? " (e altre \(altre) mezze giornate)" : "")
        // A cosa può servire: la prima attività aperta della settimana
        let settimana = MotoreStorie.settimanaDi(x.oggi, cal: cal)
        let attivita = x.dati.attivita.filter { !$0.completata && $0.scadenza < settimana.end }
            .sorted { ($0.scadenza, $0.priorita.ordine, $0.id) < ($1.scadenza, $1.priorita.ordine, $1.id) }.first
        let uso = attivita.map { "buono per «\($0.titolo)»" } ?? "buono per le telefonate della settimana"
        l.righe.append("\(nomeGiorno) \(fascia) è libero: \(uso)")
        return EsitoPassoRoutine(tipo: .buchiSettimana, titolo: titolo, dettaglio: dettaglio, stato: .fatto, fonte: "Agenda e orari di lavoro")
    }

    private static func promesseScadenze(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        let cal = x.calendario
        let clienti = Dictionary(x.dati.clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let ritardo = x.dati.promesse.filter { aperta($0) && clienti[$0.clienteId] != nil && PromesseVera.semaforo($0, oggi: x.oggi) == .inRitardo }
            .sorted { ($0.scadenzaAttuale ?? .distantPast) < ($1.scadenzaAttuale ?? .distantPast) }
        let scadenze = MotoreOccasioniMessaggi.scadenze(x.dati.posizioni, clienti: clienti, soglia: giorniScadenzeSettimana, oggi: x.oggi, cal: cal)
            .sorted { $0.data < $1.data }
        var parti: [String] = []
        if !ritardo.isEmpty { parti.append(ritardo.count == 1 ? "1 promessa in ritardo" : "\(ritardo.count) promesse in ritardo") }
        if !scadenze.isEmpty { parti.append(scadenze.count == 1 ? "1 scadenza nel mese" : "\(scadenze.count) scadenze nel mese") }
        let titolo = "Controllo promesse e scadenze"
        if let p = ritardo.first {
            l.righe.append("In ritardo: \(minuscola(p.testo))")
            l.pulsante("Sistema il ritardo", .attivita, p.clienteId, peso: 2)
        } else if let s = scadenze.first {
            l.righe.append("In scadenza: \(s.titolo) · \(clienti[s.clienteId]?.nome ?? "")")
        }
        guard !parti.isEmpty else {
            return EsitoPassoRoutine(tipo: .promesseScadenze, titolo: titolo, dettaglio: "Nessuna promessa in ritardo e nessuna scadenza nel mese",
                              stato: .vuoto, fonte: "Promesse e posizioni")
        }
        return EsitoPassoRoutine(tipo: .promesseScadenze, titolo: titolo, dettaglio: parti.joined(separator: ", "), stato: .fatto, fonte: "Promesse e posizioni")
    }

    private static func mossaSettimana(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        let d = x.dati
        let esito = MotoreMossaDelGiorno.calcola(clienti: d.clienti, posizioni: d.posizioni, appuntamenti: d.appuntamenti,
                                                 attivita: d.attivita, incontri: d.incontri, prodotti: d.prodotti,
                                                 analisi: d.analisi, regoleOccasioni: d.impostazioni.occasioni,
                                                 sogliaSeguito: d.impostazioni.giorniSeguitoProposte, oggi: x.oggi)
        let titolo = "Scelgo la mossa della settimana"
        guard let m = esito.mossa else {
            return EsitoPassoRoutine(tipo: .mossaSettimana, titolo: titolo, dettaglio: "Niente di urgente: è una settimana tranquilla", stato: .vuoto, fonte: "La mossa del giorno")
        }
        l.righe.append("La mossa: \(m.cliente.nome). \(m.motivo)")
        return EsitoPassoRoutine(tipo: .mossaSettimana, titolo: titolo, dettaglio: "\(m.cliente.nome): \(m.motivo)", stato: .fatto, fonte: "La mossa del giorno")
    }

    // MARK: - Fine mese

    /// Il mese da chiudere: quello di `oggi`, oppure quello prima nei primi `giorniMesePrima` giorni del mese.
    static func meseDaChiudere(_ oggi: Date, cal: Calendar = .current) -> DateInterval {
        let giorno = cal.startOfDay(for: oggi)
        let inizioMese = cal.date(from: cal.dateComponents([.year, .month], from: giorno)) ?? giorno
        let inizio = cal.component(.day, from: giorno) <= giorniMesePrima
            ? (cal.date(byAdding: .month, value: -1, to: inizioMese) ?? inizioMese) : inizioMese
        let fine = cal.date(byAdding: .month, value: 1, to: inizio) ?? inizio
        return DateInterval(start: inizio, end: fine)
    }

    private static func parcelleMese(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        let cal = x.calendario
        let mese = meseDaChiudere(x.oggi, cal: cal)
        let nomeMese = formato("MMMM", cal).string(from: mese.start)
        let pagate = x.dati.parcelle.filter { p in
            let d = p.incassataIl ?? p.data
            return p.stato == .pagata && d >= mese.start && d < mese.end
        }
        let incassato = pagate.map(MotoreParcelle.importo).reduce(0, +)
        let eventi = x.dati.posizioni.flatMap { MotoreStudio.eventi($0, studio: x.dati.impostazioni.studio, da: mese.start, a: mese.end, cal: cal) }
        let provvigioni = eventi.compactMap(\.importo).reduce(0, +)
        let senzaAliquota = eventi.contains { $0.importo == nil }
        var parti: [String] = []
        parti.append(pagate.isEmpty ? "nessuna parcella incassata" : "parcelle incassate \(Formati.euro(incassato))")
        if eventi.isEmpty {
            parti.append("nessuna provvigione Alleanza")
        } else {
            parti.append("provvigioni stimate \(Formati.euro(provvigioni))" + (senzaAliquota ? " (mancano alcune aliquote)" : ""))
        }
        l.righe.append("\(maiuscola(nomeMese)): \(parti.joined(separator: ", "))")
        l.pulsante("Apri Studio", .studio, peso: 3)
        return EsitoPassoRoutine(tipo: .parcelleMese, titolo: "Sommo provvigioni e parcelle",
                          dettaglio: maiuscola(parti.joined(separator: " · ")) + " · Studio, \(nomeMese)",
                          stato: pagate.isEmpty && eventi.isEmpty ? .vuoto : .fatto, fonte: "Studio")
    }

    private static func chilometriMese(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        let titolo = "Controllo i chilometri"
        guard RegistroStrumenti.strumento(RegistroStrumenti.studioChilometri)?.disponibile == true else {
            l.righe.append("Chilometri: Studio non li registra ancora, per ora li segni tu")
            return EsitoPassoRoutine(tipo: .chilometriMese, titolo: titolo,
                              dettaglio: "Studio non registra ancora i chilometri: quando sarà pronto lo farò io", stato: .inAttesa, fonte: "Studio · in attesa")
        }
        // Lo strumento c'è, ma i chilometri non sono ancora nell'archivio: Vera non li inventa
        return EsitoPassoRoutine(tipo: .chilometriMese, titolo: titolo, dettaglio: "I chilometri del mese sono in Studio", stato: .vuoto, fonte: "Studio")
    }

    private static func fattureDaEmettere(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        let bozze = x.dati.parcelle.filter { $0.stato == .bozza }
        let scadute = MotoreParcelle.scadute(x.dati.parcelle, oggi: x.oggi, cal: x.calendario)
        var parti: [String] = []
        if !bozze.isEmpty {
            parti.append(bozze.count == 1 ? "1 parcella da fatturare" : "\(bozze.count) parcelle da fatturare")
            let totale = bozze.map(MotoreParcelle.importo).reduce(0, +)
            l.righe.append((bozze.count == 1 ? "1 fattura in bozza" : "\(bozze.count) fatture in bozza") + " da controllare (\(Formati.euro(totale)))")
        }
        if !scadute.isEmpty {
            parti.append(scadute.count == 1 ? "1 scaduta da sollecitare" : "\(scadute.count) scadute da sollecitare")
            let importo = scadute.map(MotoreParcelle.importo).reduce(0, +)
            l.righe.append((scadute.count == 1 ? "1 parcella scaduta" : "\(scadute.count) parcelle scadute") + ": \(Formati.euro(importo)) da incassare")
        }
        let titolo = "Preparo le fatture da emettere"
        guard !parti.isEmpty else {
            return EsitoPassoRoutine(tipo: .fattureDaEmettere, titolo: titolo, dettaglio: "Nessuna fattura da emettere", stato: .vuoto, fonte: "Studio › Parcelle")
        }
        l.pulsante("Vedi le fatture", .studio, peso: 2)
        return EsitoPassoRoutine(tipo: .fattureDaEmettere, titolo: titolo, dettaglio: maiuscola(parti.joined(separator: " · ")), stato: .fatto, fonte: "Studio › Parcelle")
    }

    private static func scadenzeMeseDopo(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        let cal = x.calendario
        let chiuso = meseDaChiudere(x.oggi, cal: cal)
        let inizio = chiuso.end
        let fine = cal.date(byAdding: .month, value: 1, to: inizio) ?? inizio
        let nomeMese = formato("MMMM", cal).string(from: inizio)
        let escluse: Set<AreaPosizione> = [.debiti, .immobili, .liquidita]
        let posizioni = x.dati.posizioni
            .filter { $0.stato == .inEssere && !escluse.contains($0.area) && ($0.scadenza.map { $0 >= inizio && $0 < fine } ?? false) }
            .sorted { ($0.scadenza ?? inizio, $0.id) < ($1.scadenza ?? inizio, $1.id) }
        let titolo = "Guardo il mese che arriva"
        guard !posizioni.isEmpty else {
            l.righe.append("Nessuna scadenza a \(nomeMese)")
            return EsitoPassoRoutine(tipo: .scadenzeMeseDopo, titolo: titolo, dettaglio: "Nessuna scadenza a \(nomeMese)", stato: .vuoto, fonte: "Posizioni")
        }
        // Già in agenda: un impegno su quella posizione, o un'attività aperta che la nomina
        let daFissare = posizioni.filter { p in
            let inAgenda = x.dati.appuntamenti.contains { $0.posizioneId == p.id && $0.stato == .pianificato }
            let nome = nomePosizione(p).lowercased()
            let inAttivita = x.dati.attivita.contains { $0.clienteId == p.clienteId && !$0.completata && $0.titolo.lowercased().contains(nome) }
            return !inAgenda && !inAttivita
        }
        var preparate = 0
        for p in daFissare.prefix(passiMassimi) {
            let quando = max(cal.startOfDay(for: x.oggi), cal.date(byAdding: .day, value: -15, to: cal.startOfDay(for: p.scadenza ?? inizio)) ?? inizio)
            if let a = prepara(RegistroStrumenti.attivitaNuova,
                               ["cliente": p.clienteId, "titolo": "Preparare il rinnovo di «\(nomePosizione(p))»", "scadenza": giornoIso(quando, cal: cal)],
                               x, attivo: p.clienteId) {
                l.azioni.append(a)
                preparate += 1
            }
        }
        let n = posizioni.count
        let quante = n == 1 ? "1 scadenza" : "\(n) scadenze"
        if preparate == 0 {
            l.righe.append("\(quante) di \(nomeMese) già in agenda")
        } else {
            l.righe.append("\(quante) di \(nomeMese): \(preparate) da mettere in agenda (da confermare)")
        }
        l.pulsante("Apri l'agenda", .agenda, peso: 1)
        return EsitoPassoRoutine(tipo: .scadenzeMeseDopo, titolo: titolo, dettaglio: "\(quante) a \(nomeMese)",
                          stato: preparate > 0 ? .daConfermare : .fatto, fonte: "Posizioni e agenda")
    }

    // MARK: - Dopo la firma

    /// La posizione firmata: quella indicata, altrimenti la proposta aperta del cliente (accettata, presentata,
    /// rimandata, bozza), la più recente.
    static func posizioneFirmata(cliente c: Cliente, posizioneId: String?, posizioni: [Posizione]) -> Posizione? {
        if let id = posizioneId, let p = posizioni.first(where: { $0.id == id && $0.clienteId == c.id }) { return p }
        func ordine(_ p: Posizione) -> Int {
            switch p.esito {
            case .accettata: return 0
            case .presentata: return 1
            case .rimandata: return 2
            default: return 3
            }
        }
        return posizioni.filter { $0.clienteId == c.id && $0.stato == .proposta && $0.esito != .rifiutata }
            .sorted { (ordine($0), $1.creataIl, $0.id) < (ordine($1), $0.creataIl, $1.id) }.first
    }

    private static func firmata(_ c: Cliente, _ x: ContestoRoutine, _ l: inout Lavagna) -> Posizione? {
        if !l.cercataPosizione {
            l.posizione = posizioneFirmata(cliente: c, posizioneId: x.posizioneId, posizioni: x.dati.posizioni)
            l.cercataPosizione = true
        }
        return l.posizione
    }

    private static func archiviaContratto(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.archiviaContratto) }
        let p = firmata(c, x, &l)
        let titolo = "Archivio il contratto firmato"
        if let file = x.file?.trimmingCharacters(in: .whitespacesAndNewlines), !file.isEmpty {
            let nome = "Contratto firmato · \(p.map { nomePosizione($0) } ?? c.nome)"
            l.azioni.append(AzioneConferma(strumento: RegistroStrumenti.documentiArchivia, app: .documenti, titolo: "Archivio «\(nome)»",
                                           dettaglio: "Nella scheda di \(c.nome) · Documenti",
                                           argomenti: ["cliente": c.id, "file": file, "titolo": nome, "tipo": Documento.Tipo.polizza.rawValue]))
            l.righe.append("Contratto da archiviare nella scheda di \(primoNome(c.nome)) (da confermare)")
            return EsitoPassoRoutine(tipo: .archiviaContratto, titolo: titolo, dettaglio: "Nella scheda di \(c.nome) · Documenti", stato: .daConfermare, fonte: "Il file trascinato")
        }
        if let p, x.dati.documenti.contains(where: { $0.clienteId == c.id && $0.posizioneId == p.id && $0.tipo == .polizza }) {
            return EsitoPassoRoutine(tipo: .archiviaContratto, titolo: titolo, dettaglio: "Il contratto di «\(nomePosizione(p))» è già nei Documenti", stato: .fatto, fonte: "Documenti")
        }
        l.righe.append("Contratto: trascinalo su Vera e lo archivio nella scheda di \(primoNome(c.nome))")
        return EsitoPassoRoutine(tipo: .archiviaContratto, titolo: titolo,
                          dettaglio: "Trascina su Vera il PDF firmato: lo archivio nella scheda di \(c.nome) · Documenti", stato: .inAttesa, fonte: "Documenti")
    }

    /// «550 € al mese», «12.000 € premio unico».
    static func importoTesto(_ p: Posizione) -> String {
        switch p.frequenza {
        case .unica: return "\(Formati.euro(p.versamentoIniziale > 0 ? p.versamentoIniziale : p.premio)) premio unico"
        case .mensile: return "\(Formati.euro(p.premio)) al mese"
        case .trimestrale: return "\(Formati.euro(p.premio)) al trimestre"
        case .semestrale: return "\(Formati.euro(p.premio)) al semestre"
        case .annuale: return "\(Formati.euro(p.premio)) all'anno"
        }
    }

    private static func aggiornaPosizioni(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.aggiornaPosizioni) }
        let titolo = "Aggiorno le posizioni"
        guard let p = firmata(c, x, &l) else {
            return EsitoPassoRoutine(tipo: .aggiornaPosizioni, titolo: titolo, dettaglio: "\(c.nome) non ha proposte aperte da segnare in essere",
                              stato: .vuoto, fonte: "Posizioni")
        }
        if p.stato == .inEssere {
            return EsitoPassoRoutine(tipo: .aggiornaPosizioni, titolo: titolo, dettaglio: "«\(nomePosizione(p))» è già in essere", stato: .fatto, fonte: "Posizioni")
        }
        let cal = x.calendario
        let inizioMese = cal.date(from: cal.dateComponents([.year, .month], from: x.oggi)) ?? x.oggi
        let decorrenza = p.decorrenza ?? (cal.date(byAdding: .month, value: 1, to: inizioMese) ?? inizioMese)
        let mese = formato("MMMM", cal).string(from: decorrenza)
        let dettaglio = "\(nomePosizione(p)): \(importoTesto(p)) da \(mese)"
        l.azioni.append(AzioneConferma(strumento: strumentoPosizioneFirmata, app: .posizioni, titolo: "Segno in essere «\(nomePosizione(p))» di \(c.nome)",
                                       dettaglio: "\(importoTesto(p)) da \(mese) · \(p.canale.nomeBreve)",
                                       argomenti: ["cliente": c.id, "posizione": p.id, "decorrenza": RegistroStrumenti.isoData(decorrenza),
                                                   "stato_prima": p.stato.rawValue, "esito_prima": p.esito?.rawValue ?? ""]))
        l.righe.append("«\(nomePosizione(p))» da segnare in essere (da confermare)")
        l.pulsante("Apri la scheda", .clienti, c.id, peso: 2)
        return EsitoPassoRoutine(tipo: .aggiornaPosizioni, titolo: titolo, dettaglio: dettaglio, stato: .daConfermare, fonte: "Posizioni")
    }

    /// La durata del primo controllo e per quanti giorni lo si cerca.
    static let minutiControllo = 60
    static let giorniCercaControllo = 21

    /// Il primo orario libero (un'ora in studio) da `mesi` mesi dopo oggi: solo nei giorni di lavoro non festivi
    /// (`MotorePianificazione.lavorativo`), dentro le fasce di OrariLavoro (pomeriggio spento compreso) e dalle 9:30
    /// (`AgendaOrganizzaVera.inizi`), lontano dagli altri impegni almeno il margine, senza superare il limite dei riesami
    /// al giorno. nil se nei `giorniCercaControllo` giorni non c'è uno spazio libero (mai un orario occupato).
    static func orarioControllo(mesi: Int, dati: DatiPrisma, oggi: Date, cal: Calendar = .current) -> Date? {
        guard let base = cal.date(byAdding: .month, value: mesi, to: cal.startOfDay(for: oggi)) else { return nil }
        let orari = dati.impostazioni.orari
        let durata = TimeInterval(minutiControllo * 60)
        let margine = TimeInterval(max(0, orari.margineMinuti) * 60)
        let occupati = dati.appuntamenti.map { (inizio: $0.inizio.addingTimeInterval(-margine), fine: $0.fine.addingTimeInterval(margine)) }
        for n in 0..<giorniCercaControllo {
            guard let g = cal.date(byAdding: .day, value: n, to: base).map({ cal.startOfDay(for: $0) }),
                  MotorePianificazione.lavorativo(g, orari: orari, cal: cal) else { continue }
            if orari.riesamiAlGiorno > 0,
               dati.appuntamenti.filter({ $0.tipo == .revisione && cal.isDate($0.inizio, inSameDayAs: g) }).count >= orari.riesamiAlGiorno { continue }
            for t in AgendaOrganizzaVera.inizi(giorno: g, durata: minutiControllo, orari: orari, conCliente: true, cal: cal) where t >= oggi {
                let fine = t.addingTimeInterval(durata)
                if !occupati.contains(where: { $0.inizio < fine && t < $0.fine }) { return t }
            }
        }
        return nil
    }

    private static func fissaControllo(_ mesi: Int, _ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.fissaControllo) }
        let cal = x.calendario
        let titolo = "Fisso il primo controllo"
        guard let inizio = orarioControllo(mesi: mesi, dati: x.dati, oggi: x.oggi, cal: cal),
              let azione = prepara(RegistroStrumenti.agendaNuovo,
                                   ["cliente": c.id, "giorno": giornoIso(inizio, cal: cal), "ora": formato("HH:mm", cal).string(from: inizio),
                                    "tipo": "revisione", "durata_minuti": String(minutiControllo), "luogo": "In studio"], x, attivo: c.id) else {
            return EsitoPassoRoutine(tipo: .fissaControllo, titolo: titolo, dettaglio: "Non trovo un orario libero fra \(mesi) mesi", stato: .impossibile, fonte: "Agenda")
        }
        l.azioni.append(azione)
        l.controllo = inizio
        let mese = formato(mesi >= 12 ? "MMMM yyyy" : "MMMM", cal).string(from: inizio)
        l.righe.append("Primo controllo a \(mese) (da confermare)")
        return EsitoPassoRoutine(tipo: .fissaControllo, titolo: titolo, dettaglio: "Fra \(mesi) \(mesi == 1 ? "mese" : "mesi"), a \(mese)", stato: .daConfermare, fonte: "Agenda e orari di lavoro")
    }

    /// Il messaggio di benvenuto composto da Prisma (lo stile del consulente arriverà con «Scrive come te»).
    static func testoBenvenuto(cliente c: Cliente, posizione p: Posizione?, controllo: Date?, firma: String, cal: Calendar = .current) -> String {
        let avvio = p.map { "«\(nomePosizione($0))» è avviato" } ?? "da oggi la seguo passo passo"
        let rivederci = controllo.map { "ci rivediamo a \(formato("MMMM", cal).string(from: $0)) per il primo controllo" }
            ?? "ci sentiamo presto per il primo controllo"
        let f = firma.trimmingCharacters(in: .whitespaces)
        return "Buongiorno \(primoNome(c.nome)), grazie per la fiducia. \(maiuscola(avvio)): \(rivederci), e per qualsiasi domanda mi scriva pure. Un caro saluto" + (f.isEmpty ? "." : ", \(f)")
    }

    private static func messaggioBenvenuto(_ x: ContestoRoutine, _ l: inout Lavagna) -> EsitoPassoRoutine {
        guard let c = l.cliente else { return senzaCliente(.messaggioBenvenuto) }
        let p = firmata(c, x, &l)
        let testo = testoBenvenuto(cliente: c, posizione: p, controllo: l.controllo, firma: x.dati.impostazioni.nomeUtente, cal: x.calendario)
        let titolo = "Preparo il messaggio di benvenuto"
        guard let a = prepara(RegistroStrumenti.messaggiPrepara, ["cliente": c.id, "scopo": "saluto", "testo": testo], x, attivo: c.id) else {
            return EsitoPassoRoutine(tipo: .messaggioBenvenuto, titolo: titolo, dettaglio: "Non riesco a preparare il messaggio", stato: .impossibile, fonte: "Messaggi")
        }
        l.azioni.append(a)
        l.righe.append("Messaggio di benvenuto pronto da rivedere (da confermare)")
        l.pulsante("Leggi il messaggio", .messaggi, c.id, peso: 3)
        return EsitoPassoRoutine(tipo: .messaggioBenvenuto, titolo: titolo, dettaglio: "Una bozza da rivedere: la spedisci tu", stato: .daConfermare, fonte: "Messaggi")
    }

    private static func senzaCliente(_ t: TipoPassoRoutine) -> EsitoPassoRoutine {
        EsitoPassoRoutine(tipo: t, titolo: t.descrizione.prefix(1).uppercased() + t.descrizione.dropFirst(), dettaglio: "Manca il cliente", stato: .impossibile, fonte: "")
    }

    // MARK: - Routine nuove a parole: prima le regole

    /// Le parole che riconoscono un passo (sul testo in minuscolo); l'ordine dei passi è quello della frase.
    static let parolePassi: [(TipoPassoRoutine, String)] = [
        (.archiviaContratto, #"\barchivi\w*\b[^.;]*\b(?:contratt|firmat|document|modul)"#),
        (.aggiornaPosizioni, #"\baggiorn\w*\b[^.;]*\bposizion|\bsegn\w* in essere\b"#),
        (.fissaControllo, #"\b(?:fiss|mett|programm|segn|prenot)\w*\b[^.;]*\b(?:controllo|riesame|revisione)\b|\b(?:controllo|riesame) (?:a|tra|fra|dopo)\b"#),
        (.messaggioBenvenuto, #"\bbenvenut|\bringrazi\w* (?:il cliente|la cliente|per la fiducia)"#),
        (.schedaCliente, #"\bscheda\b"#),
        (.ultimoIncontro, #"\bultimo (?:incontro|colloquio|appuntamento)\b"#),
        (.cosaManca, #"\bcosa manca\b|\bdati mancanti\b|\bmanca(?:no)? (?:dei |i )?dati\b"#),
        (.scaletta, #"\bscaletta\b|\bordine del giorno\b"#),
        (.agendaSettimana, #"\b(?:guard|legg|controll|dimm|mostr|apr)\w*\b[^.;]*\bagenda\b|\bagenda della settimana\b|\bimpegni della settimana\b"#),
        (.buchiSettimana, #"\bbuchi\b|\b(?:spazi|mezze giornate|orari|ore) liber"#),
        (.promesseScadenze, #"\bpromess"#),
        (.mossaSettimana, #"\bmossa\b"#),
        (.parcelleMese, #"\bparcell|\bprovvigion"#),
        (.chilometriMese, #"\bchilometr|\bkm\b"#),
        (.fattureDaEmettere, #"\bfattur"#),
        (.scadenzeMeseDopo, #"\bscadenz\w*\b[^.;]*\bmese (?:dopo|prossimo|che (?:arriva|viene))"#),
        (.scadenzeCliente, #"\bscadenz"#),
    ]

    /// I mesi detti nella frase («a sei mesi», «tra 3 mesi», «dopo un anno»).
    static func mesiDa(_ testo: String) -> Int? {
        let t = testo.lowercased()
        if DateItaliane.cerca(#"\b(?:a|tra|fra|dopo|entro) (?:un|1) anno\b"#, t) != nil { return 12 }
        guard let (_, g) = DateItaliane.cerca(#"\b(?:a|tra|fra|dopo|entro) (\d{1,2}|un|uno|due|tre|quattro|cinque|sei|sette|otto|nove|dieci|undici|dodici) mes[ei]\b"#, t),
              let n = DateItaliane.numero(g[1]), (1...24).contains(n) else { return nil }
        return n
    }

    /// Quando si lancia, letto dalla frase: ogni lunedì (all'ora detta), a fine mese, dopo ogni firma.
    static func programmazioneDa(_ testo: String) -> ProgrammazioneRoutine? {
        let t = InterpreteComandi.pulisci(testo)
        var ora: (Int, Int)?
        if let (_, g) = DateItaliane.cerca(#"\balle (\d{1,2})(?:[:.](\d{2}))?\b"#, t), let h = Int(g[1]), (0...23).contains(h) {
            let m = Int(g[2]) ?? 0
            if (0...59).contains(m) { ora = (h, m) }
        }
        if DateItaliane.cerca(#"\b(?:ogni volta che|quando|dopo che|appena) (?:firmo|firmiamo|ho firmato|abbiamo firmato|(?:un|il|la) cliente firma)\b|\bdopo (?:ogni|la) firma\b"#, t) != nil {
            return ProgrammazioneRoutine(tipo: .dopoFirma)
        }
        if DateItaliane.cerca(#"\bultimo giorno del mese\b|\b(?:a|ogni) fine mese\b|\balla fine (?:di ogni|del) mese\b"#, t) != nil {
            return ProgrammazioneRoutine(tipo: .fineMese, ora: ora?.0 ?? 17, minuto: ora?.1 ?? 30)
        }
        let giorni = ["domenica", "luned[iì]", "marted[iì]", "mercoled[iì]", "gioved[iì]", "venerd[iì]", "sabato"]
        for (i, g) in giorni.enumerated() where DateItaliane.cerca(#"\b(?:ogni|il) "# + g + #"\b"#, t) != nil {
            return ProgrammazioneRoutine(tipo: .settimanale, giorno: i + 1, ora: ora?.0 ?? 8, minuto: ora?.1 ?? 30)
        }
        return nil
    }

    /// I passi riconosciuti dalle regole, nell'ordine in cui la frase li dice.
    static func passiDa(_ testo: String) -> [PassoRoutine] {
        let t = InterpreteComandi.pulisci(testo)
        var trovati: [(Int, TipoPassoRoutine)] = []
        for (tipo, schema) in parolePassi {
            guard let (r, _) = DateItaliane.cerca(schema, t) else { continue }
            // «le scadenze del mese dopo» non sono anche le scadenze del cliente
            if tipo == .scadenzeCliente && trovati.contains(where: { $0.1 == .scadenzeMeseDopo }) { continue }
            trovati.append((r.location, tipo))
        }
        let mesi = mesiDa(t)
        return trovati.sorted { $0.0 < $1.0 }.prefix(passiMassimi)
            .map { PassoRoutine($0.1, mesi: $0.1 == .fissaControllo ? (mesi ?? mesiControllo) : nil) }
    }

    private static func titoloDa(_ programmazione: ProgrammazioneRoutine?, passi: [PassoRoutine]) -> String {
        switch programmazione?.tipo {
        case .dopoFirma?: return "Quando firmo"
        case .fineMese?: return "A fine mese"
        case .settimanale?:
            let g = ProgrammazioneRoutine.giorni[max(0, min(6, (programmazione?.giorno ?? 2) - 1))]
            return "Ogni \(g)"
        case nil: return passi.first.map { maiuscola($0.tipo.descrizione) } ?? "La mia routine"
        }
    }

    private static func inneschiDa(titolo: String, frase: String, programmazione: ProgrammazioneRoutine?) -> [String] {
        if programmazione?.tipo == .dopoFirma { return [innescoFirma] }
        return [titolo, frase].map { InterpreteComandi.pulisci($0) }
            .filter { $0.count >= 6 }
            .map { "\\b" + NSRegularExpression.escapedPattern(for: $0) + "\\b" }
    }

    /// Una routine nuova con le regole: almeno un passo del catalogo riconosciuto. nil se le regole non bastano
    /// (allora tocca a Qwen).
    static func daParole(_ testo: String, oggi: Date) -> RoutineVera? {
        let passi = passiDa(testo)
        guard !passi.isEmpty else { return nil }
        let prog = programmazioneDa(testo)
        let titolo = titoloDa(prog, passi: passi)
        return nuova(titolo: titolo, frase: nil, passi: passi, programmazione: prog, oggi: oggi)
    }

    private static func nuova(titolo: String, frase: String?, passi: [PassoRoutine], programmazione: ProgrammazioneRoutine?, oggi: Date) -> RoutineVera {
        let lancio = frase ?? (programmazione?.tipo == .dopoFirma ? "Vera, ho firmato con…" : "Vera, \(minuscola(titolo))")
        return RoutineVera(id: "routine-\(UUID().uuidString.prefix(8).lowercased())", titolo: titolo, frase: lancio,
                           inneschi: inneschiDa(titolo: titolo, frase: lancio, programmazione: programmazione),
                           passi: passi, programmazione: programmazione, creataIl: oggi)
    }

    // MARK: - Routine nuove a parole: Qwen (JSON, solo i passi del catalogo)

    static let schema: [String: Any] = {
        let passo: [String: Any] = ["type": "object", "required": ["tipo"],
                                    "properties": ["tipo": ["type": "string", "enum": TipoPassoRoutine.allCases.map(\.rawValue)] as [String: Any]] as [String: Any]]
        return ["type": "object", "required": ["titolo", "passi"],
                "properties": ["titolo": ["type": "string"], "frase": ["type": "string"],
                               "passi": ["type": "array", "items": passo] as [String: Any]] as [String: Any]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("routine") ?? "Il consulente descrive a parole una routine di lavoro. Traducila nei passi del catalogo, nell'ordine detto. Rispondi solo con il JSON: titolo (breve, al massimo cinque parole), frase (come la lancerebbe, breve), passi (ognuno con tipo preso solo dal catalogo). Niente passi fuori dal catalogo, niente cifre. Se nessun passo del catalogo corrisponde, passi vuoto."
    }

    static func messaggi(_ richiesta: String) -> [MessaggioModello] {
        let catalogo = TipoPassoRoutine.allCases.map { "- \($0.rawValue): \($0.descrizione)" }.joined(separator: "\n")
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "CATALOGO DEI PASSI\n\(catalogo)\n\nRICHIESTA DEL CONSULENTE\n\(richiesta)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.contesto = NucleoVera.finestra
        o.massimoToken = 300
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        o.conLezioni = false
        return o
    }

    /// La routine di Qwen, se passa i controlli: solo passi del catalogo (gli altri si scartano, senza nessun passo
    /// valido la risposta non vale), al più `passiMassimi`, senza doppioni; titolo e frase senza cifre che non sono
    /// nella richiesta. Programmazione e mesi del controllo li leggono le regole dalla richiesta.
    static func leggi(_ json: String, richiesta: String, oggi: Date) -> RoutineVera? {
        guard let i = json.firstIndex(of: "{"), let fine = json.lastIndex(of: "}"), i < fine,
              let d = String(json[i...fine]).data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let elenco = j["passi"] as? [[String: Any]] else { return nil }
        let mesi = mesiDa(richiesta) ?? mesiControllo
        var tipi: [TipoPassoRoutine] = []
        for v in elenco {
            guard let s = v["tipo"] as? String, let t = TipoPassoRoutine(rawValue: s.trimmingCharacters(in: .whitespaces)), !tipi.contains(t) else { continue }
            tipi.append(t)
        }
        guard !tipi.isEmpty else { return nil }
        let passi = tipi.prefix(passiMassimi).map { PassoRoutine($0, mesi: $0 == .fissaControllo ? mesi : nil) }
        let prog = programmazioneDa(richiesta)
        func pulito(_ chiave: String, massimo: Int) -> String? {
            guard let s = (j[chiave] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "«»\""))),
                  !s.isEmpty, s.count <= massimo, CommentoVera.numeriConservati(bozza: richiesta, testo: s),
                  s.rangeOfCharacter(from: .decimalDigits) == nil || richiesta.contains(where: \.isNumber) else { return nil }
            return s
        }
        let titolo = pulito("titolo", massimo: 60).map { maiuscola($0) } ?? titoloDa(prog, passi: passi)
        let frase = pulito("frase", massimo: 80)
        return nuova(titolo: titolo, frase: frase, passi: passi, programmazione: prog, oggi: oggi)
    }

    /// Salvare una routine nuova cambia l'archivio: passa dalla scheda «Conferma» (strumento da registrare).
    static func azioneSalva(_ r: RoutineVera) -> AzioneConferma {
        let codificatore = JSONEncoder()
        codificatore.dateEncodingStrategy = .iso8601
        let json = (try? codificatore.encode(r)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let passi = r.passi.map { $0.tipo.descrizione }
        let quando = r.programmazione.map { " · \($0.etichetta)" } ?? " · «\(r.frase)»"
        return AzioneConferma(strumento: strumentoSalva, app: .vera, titolo: "Salvo la routine «\(r.titolo)»",
                              dettaglio: "\(r.passi.count) \(r.passi.count == 1 ? "passo" : "passi"): \(elenco(passi))\(quando)",
                              argomenti: ["routine": json, "id": r.id])
    }
}
