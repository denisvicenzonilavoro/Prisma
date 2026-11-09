import CryptoKit
import Foundation

// I messaggi nuovi del ponte cifrato (Orizzonte, giro 5), accanto alle richieste per Qwen:
// - «prisma/copilota»: l'iPad manda al Mac i pezzi di trascrizione (solo testo) e le schede del copilota riconosciute
//   sull'iPad; il Mac le aggiunge alla sessione aperta del cliente come proposte (niente entra nel dossier senza
//   conferma, e senza il consenso del cliente non entra niente);
// - «prisma/inquadra»: l'iPhone manda al Mac il testo letto con la fotocamera, con il riquadro di ogni riga e i campi
//   trovati; il Mac li tiene in arrivo finché il consulente non li guarda.
// L'audio e le immagini non passano mai sul ponte: solo testo, cifrato con il codice di abbinamento come il resto.
// Versione 2 del protocollo: le buste dicono la loro versione (nil = 1, i telefoni di prima, che parlano solo con
// Qwen); un Mac di prima risponde 404 ai percorsi nuovi e il telefono dice di aggiornare Prisma sul Mac.
// Versione 3 («Luce» giro 13): in più
// - «prisma/carta»: l'iPhone manda al Mac il testo letto sulla carta d'identità di un cliente nuovo (fronte e, se c'è,
//   retro), mai l'immagine; il Mac lo tiene solo in memoria e crea il cliente solo con la conferma;
// - «prisma/nota»: l'iPhone manda al Mac una nota dettata, già trascritta sul telefono (l'audio non esiste); il Mac
//   capisce di chi si parla e propone cosa farne, tutto da confermare.

extension PonteVera {
    /// 1: solo Qwen («api/chat», «v1/chat/completions», «prisma/stato», «prisma/precarica»).
    /// 2: in più «prisma/copilota» e «prisma/inquadra».
    /// 3 («Luce» giro 13): in più «prisma/carta» e «prisma/nota».
    static let versioneProtocollo = 3
    static let macDaAggiornare = "Il Mac ha una versione di Prisma che non riceve ancora queste schede: aggiorna Prisma sul Mac."

    // I limiti di un messaggio (stanno ben sotto `massimoBusta`)
    static let massimoSchede = 200
    static let massimoPezzi = 400
    static let massimoTestoPezzo = 4_000
    static let massimoRighe = 1_500
    static let massimoTestoRiga = 500
    static let massimoCampi = 40
    static let massimoTestoNota = 4_000
    static let massimoDispositivo = 120
    static let massimeFacce = 2
}

extension BustaPonte {
    static let copilota = "prisma/copilota"
    static let inquadra = "prisma/inquadra"
    static let carta = "prisma/carta"
    static let nota = "prisma/nota"
}

/// iPad → Mac: le schede del copilota riconosciute sull'iPad, con i pezzi di trascrizione da cui vengono.
struct SchedeCopilotaPonte: Codable, Equatable {
    var clienteId: String
    /// La sessione del Mac, se l'iPad la conosce; nil = quella aperta del cliente (o una nuova, con il consenso).
    var sessioneId: String?
    /// «iPad di Denis».
    var dispositivo: String
    var quando: Date
    var pezzi: [PezzoTrascrizione]
    var schede: [SchedaCopilota]

    init(clienteId: String, sessioneId: String? = nil, dispositivo: String, quando: Date = Date(),
         pezzi: [PezzoTrascrizione] = [], schede: [SchedaCopilota] = []) {
        self.clienteId = clienteId
        self.sessioneId = sessioneId
        self.dispositivo = dispositivo
        self.quando = quando
        self.pezzi = pezzi
        self.schede = schede
    }

    var valido: Bool {
        !clienteId.trimmingCharacters(in: .whitespaces).isEmpty && schede.count <= PonteVera.massimoSchede
            && pezzi.count <= PonteVera.massimoPezzi && pezzi.allSatisfy { $0.testo.count <= PonteVera.massimoTestoPezzo }
            && (!pezzi.isEmpty || !schede.isEmpty)
    }
}

/// iPhone → Mac: il testo letto con la fotocamera, riga per riga con il riquadro, e i campi trovati sull'iPhone.
/// Il Mac rilegge le righe con le sue regole (`MotoreInquadra.leggi`): i campi del telefono servono solo a mostrare
/// subito le stesse righe illuminate.
struct InquadraturaPonte: Codable, Equatable, Identifiable {
    var id = "inquadra-\(UUID().uuidString.prefix(8).lowercased())"
    /// Il cliente scelto sull'iPhone, se c'è.
    var clienteId: String?
    var dispositivo: String
    var quando: Date
    var righe: [RigaLetta]
    var campi: [CampoInquadrato]

    init(clienteId: String? = nil, dispositivo: String, quando: Date = Date(), righe: [RigaLetta], campi: [CampoInquadrato] = []) {
        self.clienteId = clienteId
        self.dispositivo = dispositivo
        self.quando = quando
        self.righe = righe
        self.campi = campi
    }

    var valido: Bool {
        !righe.isEmpty && righe.count <= PonteVera.massimoRighe && righe.allSatisfy { $0.testo.count <= PonteVera.massimoTestoRiga }
            && campi.count <= PonteVera.massimoCampi
    }

    /// I dati letti dal Mac sulle stesse righe.
    var dati: DatiInquadrati { MotoreInquadra.leggi(righe) }
}

/// iPhone → Mac: il testo letto sulla carta d'identità (fronte e, se c'è, retro), mai l'immagine. I campi servono solo ad
/// accendere subito le stesse righe: il Mac rilegge tutto con `MotoreCartaIdentita`. Sul Mac vive solo in memoria
/// (decisione 25): mai nell'archivio né nei backup.
struct CartaIdentitaPonte: Codable, Equatable, Identifiable {
    var id = "carta-\(UUID().uuidString.prefix(8).lowercased())"
    /// «iPhone di Denis».
    var dispositivo: String
    var quando: Date
    var righe: [RigaLetta]
    var campi: [CampoInquadrato]
    /// 1 o 2 (fronte e retro).
    var facce: Int

    init(dispositivo: String, quando: Date = Date(), righe: [RigaLetta], campi: [CampoInquadrato] = [], facce: Int = 1) {
        self.dispositivo = dispositivo
        self.quando = quando
        self.righe = righe
        self.campi = campi
        self.facce = facce
    }

    var valido: Bool {
        !righe.isEmpty && righe.count <= PonteVera.massimoRighe && righe.allSatisfy { $0.testo.count <= PonteVera.massimoTestoRiga }
            && campi.count <= PonteVera.massimoCampi && (1...PonteVera.massimeFacce).contains(facce)
            && dispositivo.count <= PonteVera.massimoDispositivo && !id.isEmpty
    }

    /// La lettura del Mac sulle stesse righe.
    var lettura: LetturaCartaIdentita { MotoreCartaIdentita.leggi(righe) }
}

/// iPhone → Mac: una nota dettata (solo testo, riconosciuto sul dispositivo; l'audio non esiste e non si salva).
struct NotaVocalePonte: Codable, Equatable, Identifiable {
    /// «nota-<uuid8>», scelto sull'iPhone: stabile fra un tentativo e l'altro (ricevere due volte non duplica).
    var id: String
    var testo: String
    var quando: Date
    /// Secondi di dettatura.
    var durata: Double
    var dispositivo: String
    /// Il cliente, se l'iPhone lo sa (appuntamento appena concluso).
    var clienteId: String?
    var appuntamentoId: String?
    /// «sul dispositivo».
    var riconoscimento: String

    init(id: String = "nota-\(UUID().uuidString.prefix(8).lowercased())", testo: String, quando: Date = Date(), durata: Double,
         dispositivo: String, clienteId: String? = nil, appuntamentoId: String? = nil, riconoscimento: String = "sul dispositivo") {
        self.id = id
        self.testo = testo
        self.quando = quando
        self.durata = durata
        self.dispositivo = dispositivo
        self.clienteId = clienteId
        self.appuntamentoId = appuntamentoId
        self.riconoscimento = riconoscimento
    }

    var valido: Bool {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && testo.count <= PonteVera.massimoTestoNota && durata.isFinite && (0...600).contains(durata)
            && dispositivo.count <= PonteVera.massimoDispositivo && !id.trimmingCharacters(in: .whitespaces).isEmpty
            && id.count <= 80
    }
}

/// La risposta del Mac a un messaggio nuovo (cifrata come il resto).
struct RicevutaPonte: Codable, Equatable {
    var accettato: Bool
    var motivo: String?
    /// La versione del protocollo del Mac.
    var versione: Int

    init(accettato: Bool, motivo: String? = nil, versione: Int = PonteVera.versioneProtocollo) {
        self.accettato = accettato
        self.motivo = motivo
        self.versione = versione
    }

    static func accettata(_ motivo: String? = nil) -> RicevutaPonte { RicevutaPonte(accettato: true, motivo: motivo) }
    static func rifiutata(_ motivo: String) -> RicevutaPonte { RicevutaPonte(accettato: false, motivo: motivo) }

    /// Il Mac non si trova in rete: la nota resta in coda sull'iPhone («Il Mac non è raggiungibile…»).
    var macIrraggiungibile: Bool { !accettato && motivo == PonteVera.macNonTrovato }
}

/// Un messaggio nuovo arrivato sul ponte.
enum ArrivoPonte: Equatable {
    case schedeCopilota(SchedeCopilotaPonte)
    case inquadratura(InquadraturaPonte)
    case cartaIdentita(CartaIdentitaPonte)
    case notaVocale(NotaVocalePonte)

    var percorso: String {
        switch self {
        case .schedeCopilota: return BustaPonte.copilota
        case .inquadratura: return BustaPonte.inquadra
        case .cartaIdentita: return BustaPonte.carta
        case .notaVocale: return BustaPonte.nota
        }
    }

    /// Il corpo JSON della busta.
    func corpo() throws -> Data {
        switch self {
        case .schedeCopilota(let p): return try JSONEncoder().encode(p)
        case .inquadratura(let i): return try JSONEncoder().encode(i)
        case .cartaIdentita(let c): return try JSONEncoder().encode(c)
        case .notaVocale(let n): return try JSONEncoder().encode(n)
        }
    }

    var valido: Bool {
        switch self {
        case .schedeCopilota(let p): return p.valido
        case .inquadratura(let i): return i.valido
        case .cartaIdentita(let c): return c.valido
        case .notaVocale(let n): return n.valido
        }
    }

    /// Il messaggio di una busta già aperta: nil se il percorso non è uno dei nuovi, se il corpo non si legge o se
    /// supera i limiti.
    static func leggi(_ b: BustaPonte) -> ArrivoPonte? {
        guard let corpo = b.corpo else { return nil }
        let a: ArrivoPonte?
        switch b.percorso {
        case BustaPonte.copilota:
            a = (try? JSONDecoder().decode(SchedeCopilotaPonte.self, from: corpo)).map(ArrivoPonte.schedeCopilota)
        case BustaPonte.inquadra:
            a = (try? JSONDecoder().decode(InquadraturaPonte.self, from: corpo)).map(ArrivoPonte.inquadratura)
        case BustaPonte.carta:
            a = (try? JSONDecoder().decode(CartaIdentitaPonte.self, from: corpo)).map(ArrivoPonte.cartaIdentita)
        case BustaPonte.nota:
            a = (try? JSONDecoder().decode(NotaVocalePonte.self, from: corpo)).map(ArrivoPonte.notaVocale)
        default:
            a = nil
        }
        guard let x = a, x.valido else { return nil }
        return x
    }

    /// La busta sigillata con la chiave del codice (per le prove e per il telefono).
    func busta(_ k: SymmetricKey, adesso: Date = Date()) throws -> Data {
        try BustaPonte(quando: adesso.timeIntervalSince1970, percorso: percorso, corpo: corpo()).sigillata(k)
    }
}
