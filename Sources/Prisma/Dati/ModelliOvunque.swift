import Foundation

// Prisma ovunque (Design/template-novita-specifica.md §13, prova di fattibilità Design/ovunque-fattibilita.md, giro 8):
// i modelli dello spazio cifrato in una cartella di iCloud Drive scelta dall'utente.
// - `ImpostazioniOvunque` sta nell'archivio (`Impostazioni.ovunque`, versione 26, letta con tolleranza, nei backup).
//   La passphrase e la chiave non ci sono MAI: la chiave sta nel Portachiavi del dispositivo (`PortachiaviOvunque`).
// - Nella cartella: `prisma-ovunque.json` (in chiaro, nessun dato: `DescrittoreSpazio`), `istantanea.cifrato` (scritta
//   solo dal Mac: `IstantaneaOvunque`) e `giornale-<dispositivo>.cifrato` (scritto solo da quel dispositivo:
//   `GiornaleOvunque`). Un solo scrittore per file.
// - Le operazioni del giornale (`OperazioneOvunque`) hanno id, dispositivo, orologio di Lamport, progressivo, data e i
//   valori prima/dopo per campo: il Mac le unisce (`MotoreUnioneOvunque`), i conflitti vanno in «Da decidere».

/// Chi è questo archivio nello spazio: il Mac (unico punto di unione, scrive l'istantanea) o un iPhone/iPad.
enum RuoloOvunque: String, Codable {
    case mac, dispositivo

    /// Il ruolo naturale della piattaforma (la prova li usa tutti e due nello stesso processo).
    static var predefinito: RuoloOvunque {
        #if os(macOS)
        return .mac
        #elseif os(iOS)
        return .dispositivo
        #endif
    }
}

/// Le impostazioni dello spazio di Prisma ovunque in questo archivio. Spento finché l'utente non lo accende.
struct ImpostazioniOvunque: Codable, Equatable {
    /// «Copia cifrata su iPhone e iPad»: spenta di base, nessun file scritto finché è spenta.
    var acceso = false
    /// «Lavora anche con il Mac spento»: sul Mac decide se i giornali dei dispositivi si uniscono; sui dispositivi è la
    /// copia di quella scelta arrivata con l'istantanea (spento = copia di sola lettura).
    var modificheDaiDispositivi = true
    var ruolo = RuoloOvunque.predefinito
    /// L'id stabile di questo archivio nello spazio («mac-…», «dispositivo-…»), generato alla prima attivazione.
    var idDispositivo: String?
    /// Il nome mostrato all'utente («Mac di Denis», «iPhone»).
    var nomeDispositivo: String?
    /// Il segnalibro della cartella (normale sul Mac, con il security scope implicito su iOS) e il percorso di ripiego.
    var segnalibro: Data?
    var percorso: String?
    /// La generazione della chiave dello spazio conosciuta (cambia con la passphrase).
    var generazioneChiave: Int?
    /// Mac: l'ultima istantanea scritta. Dispositivo: l'ultima letta.
    var generazione = 0
    /// Mac: fin dove ha unito il giornale di ogni dispositivo (id → progressivo). È la «ricevuta» dell'istantanea.
    var vistoFinoA: [String: Int] = [:]
    /// L'orologio di Lamport di questo archivio.
    var lamport = 0
    /// Dispositivo: il progressivo della prossima operazione del giornale.
    var prossimoSeq = 1
    /// L'impronta del contenuto dell'ultima istantanea scritta (Mac): se non cambia, non si riscrive.
    var improntaIstantanea: String?
    var ultimaIstantanea: Date?
    var ultimoControllo: Date?
    var ultimoErrore: String?
    /// Dimensione e data dei file della cartella all'ultimo controllo (il controllo all'attivazione le confronta).
    var impronteCartella: [String: String] = [:]
    /// «Porta anche i potenziali clienti» (Mac, «Luce» giro 12, decisione 44): spento di base. Spento, l'istantanea dello
    /// spazio non contiene i potenziali clienti (dati di persone che non sono clienti).
    var potenzialiNelloSpazio = false

    init() {}

    private enum CodingKeys: String, CodingKey {
        case acceso, modificheDaiDispositivi, ruolo, idDispositivo, nomeDispositivo, segnalibro, percorso, generazioneChiave
        case generazione, vistoFinoA, lamport, prossimoSeq, improntaIstantanea, ultimaIstantanea, ultimoControllo, ultimoErrore
        case impronteCartella
        case potenzialiNelloSpazio
    }

    /// Lettura tollerante: ogni campo illeggibile prende il valore di base (lo spazio resta spento, mai acceso per errore).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        acceso = ((try? c.decodeIfPresent(Bool.self, forKey: .acceso)) ?? nil) ?? false
        modificheDaiDispositivi = ((try? c.decodeIfPresent(Bool.self, forKey: .modificheDaiDispositivi)) ?? nil) ?? true
        ruolo = ((try? c.decodeIfPresent(RuoloOvunque.self, forKey: .ruolo)) ?? nil) ?? RuoloOvunque.predefinito
        idDispositivo = (try? c.decodeIfPresent(String.self, forKey: .idDispositivo)) ?? nil
        nomeDispositivo = (try? c.decodeIfPresent(String.self, forKey: .nomeDispositivo)) ?? nil
        segnalibro = (try? c.decodeIfPresent(Data.self, forKey: .segnalibro)) ?? nil
        percorso = (try? c.decodeIfPresent(String.self, forKey: .percorso)) ?? nil
        generazioneChiave = (try? c.decodeIfPresent(Int.self, forKey: .generazioneChiave)) ?? nil
        generazione = max(0, ((try? c.decodeIfPresent(Int.self, forKey: .generazione)) ?? nil) ?? 0)
        vistoFinoA = ((try? c.decodeIfPresent([String: Int].self, forKey: .vistoFinoA)) ?? nil) ?? [:]
        lamport = max(0, ((try? c.decodeIfPresent(Int.self, forKey: .lamport)) ?? nil) ?? 0)
        prossimoSeq = max(1, ((try? c.decodeIfPresent(Int.self, forKey: .prossimoSeq)) ?? nil) ?? 1)
        improntaIstantanea = (try? c.decodeIfPresent(String.self, forKey: .improntaIstantanea)) ?? nil
        ultimaIstantanea = (try? c.decodeIfPresent(Date.self, forKey: .ultimaIstantanea)) ?? nil
        ultimoControllo = (try? c.decodeIfPresent(Date.self, forKey: .ultimoControllo)) ?? nil
        ultimoErrore = (try? c.decodeIfPresent(String.self, forKey: .ultimoErrore)) ?? nil
        impronteCartella = ((try? c.decodeIfPresent([String: String].self, forKey: .impronteCartella)) ?? nil) ?? [:]
        potenzialiNelloSpazio = ((try? c.decodeIfPresent(Bool.self, forKey: .potenzialiNelloSpazio)) ?? nil) ?? false
    }

    /// Un id nuovo per questo archivio nello spazio.
    static func nuovoId(_ ruolo: RuoloOvunque) -> String {
        (ruolo == .mac ? "mac-" : "dispositivo-") + UUID().uuidString.prefix(8).lowercased()
    }

    /// true se questo archivio è un dispositivo che può scrivere il suo giornale.
    var scriveGiornale: Bool { acceso && ruolo == .dispositivo && modificheDaiDispositivi && idDispositivo != nil }
}

/// Le cose che iPhone e iPad possono cambiare (Design/ovunque-fattibilita.md §4.4). Il resto arriva solo con l'istantanea.
enum EntitaOvunque: String, Codable, CaseIterable {
    /// Note del taccuino (`DatiPrisma.note`).
    case nota
    /// Attività (`DatiPrisma.attivita`).
    case attivita
    /// Appuntamenti (`DatiPrisma.appuntamenti`).
    case appuntamento
    /// Profilo dei bisogni raccolto dal cliente (`Cliente.bisogni`, id = id del cliente).
    case bisogni
    /// Eventi della linea della vita (`DatiPrisma.eventiVita`).
    case eventoVita
    /// Schede, verbale e attività del copilota (`DatiPrisma.sessioniCopilota`, mai la trascrizione).
    case sessioneCopilota
    /// Posizioni inquadrate dall'iPhone: bozze da confermare sul Mac (`DatiPrisma.inquadratureDaConfermare`).
    case inquadratura

    /// Il nome per l'utente («una nota», «due attività»), al singolare.
    var nome: String {
        switch self {
        case .nota: return "nota"
        case .attivita: return "attività"
        case .appuntamento: return "appuntamento"
        case .bisogni: return "profilo dei bisogni"
        case .eventoVita: return "evento della linea della vita"
        case .sessioneCopilota: return "scheda del copilota"
        case .inquadratura: return "posizione inquadrata"
        }
    }
}

enum TipoOperazioneOvunque: String, Codable {
    case crea, modificaCampo, elimina
}

/// Un'operazione del giornale di un dispositivo. I valori sono JSON canonico (chiavi ordinate) del campo o dell'oggetto:
/// `prima` è ciò che il dispositivo vedeva, `dopo` il valore nuovo (unione a tre vie sul Mac).
struct OperazioneOvunque: Codable, Equatable, Identifiable {
    /// Rende l'unione idempotente: un'operazione vista due volte si applica una volta.
    var id: String
    var dispositivo: String
    /// Orologio logico: max(visto) + 1. Decide l'ordine insieme al dispositivo.
    var lamport: Int
    /// Progressivo del dispositivo (per «visto fino a»).
    var seq: Int
    /// Solo per l'utente e per ordinare a parità di Lamport: mai per decidere.
    var data: Date
    /// La generazione dell'istantanea su cui il dispositivo lavorava.
    var base: Int
    var entita: EntitaOvunque
    var entitaId: String
    var tipo: TipoOperazioneOvunque
    /// Solo per `modificaCampo`.
    var campo: String?
    /// `modificaCampo`: valore del campo visto dal dispositivo; `elimina`: l'oggetto visto (solo i campi sincronizzati).
    var prima: String?
    /// `modificaCampo`: il valore nuovo; `crea`: l'oggetto intero.
    var dopo: String?
}

/// Perché un'operazione è finita in «Da decidere».
enum MotivoConflitto: String, Codable {
    /// Stessa entità e stesso campo cambiati sul Mac e sul dispositivo.
    case stessoCampo
    /// Il dispositivo ha cambiato qualcosa che sul Mac non c'è più.
    case eliminataSulMac
    /// Il dispositivo l'ha eliminata, il Mac l'ha cambiata.
    case eliminataSulDispositivo
    /// Il dispositivo ha aggiunto qualcosa per un cliente che sul Mac non c'è più.
    case clienteMancante
}

/// Un conflitto in attesa della scelta dell'utente. Finché non decide, vale il valore del Mac.
struct ConflittoOvunque: Codable, Equatable, Identifiable {
    /// È l'id dell'operazione: la stessa operazione non entra due volte.
    var id: String { operazione.id }
    var operazione: OperazioneOvunque
    var motivo: MotivoConflitto
    /// Il valore sul Mac quando è arrivata l'operazione (JSON canonico; nil = sul Mac non c'è).
    var valoreMac: String?
    var nomeDispositivo: String
    var arrivatoIl: Date

    private enum CodingKeys: String, CodingKey { case operazione, motivo, valoreMac, nomeDispositivo, arrivatoIl }
}

/// La scelta su un conflitto (foglio «Vedi»).
enum SceltaConflitto: String, Codable {
    case tieniMac, tieniDispositivo
}

/// Una cosa creata su un dispositivo e unita sul Mac («Arrivato da iPhone»).
struct ArrivoOvunque: Codable, Equatable {
    var entita: EntitaOvunque
    var entitaId: String
    var dispositivo: String
    var nomeDispositivo: String
    var il: Date
}

/// `prisma-ovunque.json`: in chiaro nella cartella, nessun dato dei clienti. Sale, iterazioni e verifica della chiave madre.
struct DescrittoreSpazio: Codable, Equatable {
    static let formatoAttuale = 1
    var formato = DescrittoreSpazio.formatoAttuale
    /// Cambia (+ 1) con la passphrase: i dispositivi la chiedono di nuovo.
    var generazioneChiave: Int
    var sale: Data
    var iterazioni: UInt32
    /// `CifraturaBackup.verificaSpazio` della chiave madre.
    var verifica: Data
    /// L'id del Mac proprietario: è l'unico che scrive l'istantanea; un secondo Mac non può accendere lo spazio.
    var proprietario: String
    var creatoIl: Date
}

/// Il giornale di un dispositivo: le sue operazioni non ancora confermate dal Mac. Lo scrive solo quel dispositivo.
struct GiornaleOvunque: Codable, Equatable {
    static let formatoAttuale = 1
    var formato = GiornaleOvunque.formatoAttuale
    var dispositivo: String
    var nomeDispositivo: String
    var scrittoIl: Date
    var operazioni: [OperazioneOvunque]

    init(dispositivo: String, nomeDispositivo: String, scrittoIl: Date, operazioni: [OperazioneOvunque]) {
        self.dispositivo = dispositivo
        self.nomeDispositivo = nomeDispositivo
        self.scrittoIl = scrittoIl
        self.operazioni = operazioni
    }

    private enum CodingKeys: String, CodingKey { case formato, dispositivo, nomeDispositivo, scrittoIl, operazioni }

    /// Lettura tollerante: un'operazione illeggibile (per esempio di una versione più recente) si salta, le altre restano.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        formato = ((try? c.decodeIfPresent(Int.self, forKey: .formato)) ?? nil) ?? 1
        dispositivo = try c.decode(String.self, forKey: .dispositivo)
        nomeDispositivo = ((try? c.decodeIfPresent(String.self, forKey: .nomeDispositivo)) ?? nil) ?? dispositivo
        scrittoIl = ((try? c.decodeIfPresent(Date.self, forKey: .scrittoIl)) ?? nil) ?? .distantPast
        operazioni = ((try? c.decodeIfPresent(ElencoTollerante<OperazioneOvunque>.self, forKey: .operazioni)) ?? nil)?.elementi ?? []
    }
}

/// L'istantanea scritta dal Mac: l'archivio (senza documenti, conversazioni di Vera e trascrizioni) con la generazione e
/// la ricevuta «visto fino a» di ogni dispositivo.
struct IstantaneaOvunque: Codable {
    static let formatoAttuale = 1
    var formato = IstantaneaOvunque.formatoAttuale
    var generazione: Int
    var mac: String
    var nomeMac: String
    var scrittaIl: Date
    var vistoFinoA: [String: Int]
    var lamport: Int
    /// «Lavora anche con il Mac spento» del Mac: spento = i dispositivi non scrivono il giornale.
    var modificheAmmesse: Bool
    var dati: DatiPrisma
}

/// Gli errori dello spazio, con le frasi per l'utente.
enum ErroreOvunque: LocalizedError, Equatable {
    case cartellaNonRaggiungibile
    case accessoNegato(String)
    /// Il file è in iCloud ma non ancora sul dispositivo: lo scaricamento è partito.
    case inAttesaDiICloud(String)
    case fileMancante(String)
    case spazioMancante
    case spazioGiaPresente
    case spazioDiAltroMac
    case passphraseErrata
    case passphraseCorta
    case fileDanneggiato(String)
    /// La passphrase è cambiata sul Mac: serve quella nuova.
    case generazioneCambiata
    case versionePiuRecente
    case scrittura(String)

    static let lunghezzaMinimaPassphrase = 8

    var errorDescription: String? {
        switch self {
        case .cartellaNonRaggiungibile:
            return "La cartella di Prisma ovunque non è raggiungibile: controlla di aver acceso iCloud Drive. I dati restano sul Mac."
        case .accessoNegato:
            return "Prisma non ha il permesso di aprire la cartella di Prisma ovunque: scegli di nuovo la cartella."
        case .inAttesaDiICloud:
            return "In attesa di iCloud: il file non è ancora su questo dispositivo."
        case .fileMancante(let nome):
            return "Nella cartella di Prisma ovunque manca «\(nome)»."
        case .spazioMancante:
            return "In questa cartella non c'è uno spazio di Prisma ovunque: scegli la cartella creata dal Mac."
        case .spazioGiaPresente:
            return "In questa cartella c'è già uno spazio di Prisma ovunque: aprilo con la sua passphrase."
        case .spazioDiAltroMac:
            return "Questo spazio è di un altro Mac (o di questo Mac prima di reinstallare Prisma): per non sovrascriverlo, Prisma non lo riapre qui. Scegli una cartella nuova."
        case .passphraseErrata:
            return "La passphrase non apre lo spazio di Prisma ovunque. Controlla di averla scritta bene."
        case .passphraseCorta:
            return "La passphrase deve avere almeno \(ErroreOvunque.lunghezzaMinimaPassphrase) caratteri."
        case .fileDanneggiato(let nome):
            return "«\(nome)» è danneggiato o incompleto: lo ignoro finché non arriva una copia buona. I dati restano dove sono."
        case .generazioneCambiata:
            return "La passphrase di Prisma ovunque è cambiata sul Mac: scrivi quella nuova."
        case .versionePiuRecente:
            return "Lo spazio è stato scritto da una versione più recente di Prisma: aggiorna Prisma."
        case .scrittura(let m):
            return "Scrittura nella cartella di Prisma ovunque non riuscita: \(m)"
        }
    }

    /// L'errore della cifratura con le parole dello spazio.
    static func da(_ errore: Error, nome: String) -> Error {
        guard let b = errore as? ErroreBackup else { return errore }
        switch b {
        case .passwordErrata: return ErroreOvunque.passphraseErrata
        case .backupDanneggiato, .archivioMancante: return ErroreOvunque.fileDanneggiato(nome)
        case .versionePiuRecente: return ErroreOvunque.versionePiuRecente
        default: return errore
        }
    }
}
