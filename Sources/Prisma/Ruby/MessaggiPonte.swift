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

extension PonteRuby {
    /// 1: solo Qwen («api/chat», «v1/chat/completions», «prisma/stato», «prisma/precarica»).
    /// 2: in più «prisma/copilota» e «prisma/inquadra».
    static let versioneProtocollo = 2
    static let macDaAggiornare = "Il Mac ha una versione di Prisma che non riceve ancora queste schede: aggiorna Prisma sul Mac."

    // I limiti di un messaggio (stanno ben sotto `massimoBusta`)
    static let massimoSchede = 200
    static let massimoPezzi = 400
    static let massimoTestoPezzo = 4_000
    static let massimoRighe = 1_500
    static let massimoTestoRiga = 500
    static let massimoCampi = 40
}

extension BustaPonte {
    static let copilota = "prisma/copilota"
    static let inquadra = "prisma/inquadra"
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
        !clienteId.trimmingCharacters(in: .whitespaces).isEmpty && schede.count <= PonteRuby.massimoSchede
            && pezzi.count <= PonteRuby.massimoPezzi && pezzi.allSatisfy { $0.testo.count <= PonteRuby.massimoTestoPezzo }
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
        !righe.isEmpty && righe.count <= PonteRuby.massimoRighe && righe.allSatisfy { $0.testo.count <= PonteRuby.massimoTestoRiga }
            && campi.count <= PonteRuby.massimoCampi
    }

    /// I dati letti dal Mac sulle stesse righe.
    var dati: DatiInquadrati { MotoreInquadra.leggi(righe) }
}

/// La risposta del Mac a un messaggio nuovo (cifrata come il resto).
struct RicevutaPonte: Codable, Equatable {
    var accettato: Bool
    var motivo: String?
    /// La versione del protocollo del Mac.
    var versione: Int

    init(accettato: Bool, motivo: String? = nil, versione: Int = PonteRuby.versioneProtocollo) {
        self.accettato = accettato
        self.motivo = motivo
        self.versione = versione
    }

    static func accettata(_ motivo: String? = nil) -> RicevutaPonte { RicevutaPonte(accettato: true, motivo: motivo) }
    static func rifiutata(_ motivo: String) -> RicevutaPonte { RicevutaPonte(accettato: false, motivo: motivo) }
}

/// Un messaggio nuovo arrivato sul ponte.
enum ArrivoPonte: Equatable {
    case schedeCopilota(SchedeCopilotaPonte)
    case inquadratura(InquadraturaPonte)

    var percorso: String {
        switch self {
        case .schedeCopilota: return BustaPonte.copilota
        case .inquadratura: return BustaPonte.inquadra
        }
    }

    /// Il corpo JSON della busta.
    func corpo() throws -> Data {
        switch self {
        case .schedeCopilota(let p): return try JSONEncoder().encode(p)
        case .inquadratura(let i): return try JSONEncoder().encode(i)
        }
    }

    var valido: Bool {
        switch self {
        case .schedeCopilota(let p): return p.valido
        case .inquadratura(let i): return i.valido
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
