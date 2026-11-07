import Foundation

// MARK: - Studio › Parcelle e fatture: le parcelle della consulenza indipendente (versione 26 dell'archivio, giro 2)
// Specifica Design/template-novita-specifica.md §3.5.4. `DatiPrisma.parcelle`: una parcella nasce bozza (senza numero),
// prende il numero all'emissione (`MotoreParcelle.emessa`, progressiva per anno, senza buchi), poi è pagata o annullata
// (con una nota di credito facoltativa). Le voci fiscali si congelano all'emissione (`voci`): se poi il consulente cambia
// il regime, la parcella emessa non cambia. Tutto è letto con tolleranza (`ElencoTollerante` per l'elenco).

/// Una riga della parcella: la descrizione e l'importo (imponibile della riga, in euro).
struct RigaParcella: Codable, Identifiable, Hashable {
    var id: String
    var descrizione: String
    var importo: Double

    init(id: String = UUID().uuidString, descrizione: String, importo: Double) {
        self.id = id
        self.descrizione = descrizione
        self.importo = importo
    }

    private enum CodingKeys: String, CodingKey { case id, descrizione, importo }

    /// Lettura tollerante: un importo illeggibile o non finito diventa 0, un id mancante si rifà.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = ((try? c.decodeIfPresent(String.self, forKey: .id)) ?? nil) ?? UUID().uuidString
        descrizione = ((try? c.decodeIfPresent(String.self, forKey: .descrizione)) ?? nil) ?? ""
        let v = ((try? c.decodeIfPresent(Double.self, forKey: .importo)) ?? nil) ?? 0
        importo = v.isFinite ? v : 0
    }
}

/// Lo stato di una parcella.
enum StatoParcella: String, Codable, CaseIterable, Identifiable {
    /// In preparazione: senza numero, non conta nei totali.
    case bozza
    /// Emessa e da incassare.
    case emessa
    case pagata
    /// Annullata (con una nota di credito facoltativa): tiene il numero, non conta nei totali.
    case annullata

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .bozza: return "Bozza"
        case .emessa: return "Da incassare"
        case .pagata: return "Pagata"
        case .annullata: return "Annullata"
        }
    }

    /// Ha un numero di fattura.
    var numerata: Bool { self != .bozza }
}

/// Un file generato da una parcella (il PDF o l'XML del tracciato FatturaPA), con la data.
struct DocumentoParcella: Codable, Identifiable, Hashable {
    enum Formato: String, Codable, CaseIterable { case pdf, xml }

    var id: String
    var formato: Formato
    var nomeFile: String
    var creatoIl: Date
    /// L'id in Documenti, se il file è stato tenuto nel dossier del cliente.
    var documentoId: String?

    init(id: String = UUID().uuidString, formato: Formato, nomeFile: String, creatoIl: Date, documentoId: String? = nil) {
        self.id = id
        self.formato = formato
        self.nomeFile = nomeFile
        self.creatoIl = creatoIl
        self.documentoId = documentoId
    }
}

/// Una parcella (fattura) della consulenza indipendente.
struct Parcella: Codable, Identifiable, Hashable {
    var id: String
    var clienteId: String
    var stato: StatoParcella
    /// L'anno della numerazione (quello della data del documento all'emissione).
    var anno: Int
    /// Il numero progressivo nell'anno (nil finché è bozza).
    var progressivo: Int?
    /// Il numero come va in fattura, nel formato scelto dal consulente (`NumerazioneFatture`); nil finché è bozza.
    var numero: String?
    /// La data del documento (per la bozza: la data prevista).
    var data: Date
    /// La causale o descrizione generale (facoltativa).
    var descrizione: String
    var righe: [RigaParcella]
    /// L'incontro e la consulenza (posizione o prospetto) da cui nasce, facoltativi.
    var incontroId: String?
    var consulenzaId: String?
    /// Quando è stata incassata (solo pagata).
    var incassataIl: Date?
    /// La scadenza del pagamento.
    var scadenza: Date?
    var ricorrente: Bool
    /// Annullata: quando, e il riferimento della nota di credito (facoltativo).
    var annullataIl: Date?
    var notaDiCredito: String?
    /// Le voci fiscali congelate all'emissione (nil per la bozza o se il regime non era completo).
    var voci: VociFiscali?
    /// Il progressivo d'invio del file XML (5 caratteri del nome del file), assegnato al primo file.
    var progressivoInvio: String?
    /// I file generati (PDF e XML), con la data.
    var documenti: [DocumentoParcella]

    init(id: String = UUID().uuidString, clienteId: String, data: Date, descrizione: String = "", righe: [RigaParcella] = [],
         anno: Int? = nil, ricorrente: Bool = false, cal: Calendar = .current) {
        self.id = id
        self.clienteId = clienteId
        self.stato = .bozza
        self.anno = anno ?? cal.component(.year, from: data)
        self.progressivo = nil
        self.numero = nil
        self.data = data
        self.descrizione = descrizione
        self.righe = righe
        self.incontroId = nil
        self.consulenzaId = nil
        self.incassataIl = nil
        self.scadenza = nil
        self.ricorrente = ricorrente
        self.annullataIl = nil
        self.notaDiCredito = nil
        self.voci = nil
        self.progressivoInvio = nil
        self.documenti = []
    }

    private enum CodingKeys: String, CodingKey {
        case id, clienteId, stato, anno, progressivo, numero, data, descrizione, righe, incontroId, consulenzaId
        case incassataIl, scadenza, ricorrente, annullataIl, notaDiCredito, voci, progressivoInvio, documenti
    }

    /// Lettura tollerante: id, cliente e data sono necessari (senza, la parcella si scarta); il resto, se illeggibile,
    /// diventa vuoto. Una parcella numerata senza numero torna bozza (non si inventa un numero).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        data = try c.decode(Date.self, forKey: .data)
        func leggi<T: Decodable>(_ k: CodingKeys) -> T? { (try? c.decodeIfPresent(T.self, forKey: k)) ?? nil }
        anno = leggi(.anno) ?? Calendar.current.component(.year, from: data)
        progressivo = leggi(.progressivo)
        numero = leggi(.numero)
        let s: StatoParcella = leggi(.stato) ?? .bozza
        stato = s.numerata && (numero ?? "").isEmpty ? .bozza : s
        if stato == .bozza { progressivo = nil; numero = nil }
        descrizione = leggi(.descrizione) ?? ""
        righe = (leggi(.righe) as ElencoTollerante<RigaParcella>?)?.elementi ?? []
        incontroId = leggi(.incontroId)
        consulenzaId = leggi(.consulenzaId)
        incassataIl = leggi(.incassataIl)
        scadenza = leggi(.scadenza)
        ricorrente = leggi(.ricorrente) ?? false
        annullataIl = leggi(.annullataIl)
        notaDiCredito = leggi(.notaDiCredito)
        voci = leggi(.voci)
        progressivoInvio = leggi(.progressivoInvio)
        documenti = (leggi(.documenti) as ElencoTollerante<DocumentoParcella>?)?.elementi ?? []
    }
}
