import Foundation

/// Un evento della linea della vita di un cliente (Clienti › Dossier › La linea della vita, Orizzonte giro 4,
/// versione 26 dell'archivio, `DatiPrisma.eventiVita`): un'entrata o un'uscita a un'età (o in un anno), una volta
/// o per più anni, in euro di oggi. Letto con tolleranza: un campo illeggibile prende il valore predefinito, un tipo
/// o un'origine sconosciuti diventano «altro» e «manuale».
struct EventoLineaVita: Identifiable, Codable, Hashable {
    enum Tipo: String, Codable, CaseIterable, Identifiable {
        case matrimonio, casa, figlio, studi, eredita, annoSabbatico, pensione, altro
        var id: String { rawValue }

        var nome: String {
            switch self {
            case .matrimonio: return "Matrimonio"
            case .casa: return "Casa"
            case .figlio: return "Figlio"
            case .studi: return "Studi"
            case .eredita: return "Eredità"
            case .annoSabbatico: return "Anno sabbatico"
            case .pensione: return "Pensione"
            case .altro: return "Altro"
            }
        }

        /// L'area di vita dell'evento: un obiettivo della stessa area alla stessa età non si conta due volte.
        var area: AreaBisogno? {
            switch self {
            case .casa: return .casa
            case .matrimonio, .figlio, .studi: return .famiglia
            case .eredita: return .patrimonio
            case .annoSabbatico: return .lavoro
            case .pensione: return .pensione
            case .altro: return nil
            }
        }
    }

    /// Da dove viene l'evento: scritto dal consulente o proposto dal copilota dell'incontro.
    enum Origine: String, Codable, CaseIterable {
        case manuale, copilota
    }

    var id = "vita-\(UUID().uuidString.prefix(8).lowercased())"
    var clienteId: String
    var tipo: Tipo
    /// Età del cliente all'evento; se manca vale `anno` (con la data di nascita).
    var eta: Int?
    var anno: Int?
    /// Euro di oggi: > 0 entrata, < 0 uscita. nil = evento senza cifra (si vede, non entra nel calcolo).
    var importo: Double?
    /// nil o 1 = una volta; N = ogni anno per N anni.
    var durataAnni: Int?
    /// Nome libero sul gettone; nil = `tipo.nome`.
    var titolo: String?
    var nota = ""
    var origine = Origine.manuale

    init(clienteId: String, tipo: Tipo, eta: Int? = nil, anno: Int? = nil, importo: Double? = nil, durataAnni: Int? = nil,
         titolo: String? = nil, nota: String = "", origine: Origine = .manuale) {
        self.clienteId = clienteId
        self.tipo = tipo
        self.eta = eta
        self.anno = anno
        self.importo = importo
        self.durataAnni = durataAnni
        self.titolo = titolo
        self.nota = nota
        self.origine = origine
    }

    var nome: String { titolo.map { $0.trimmingCharacters(in: .whitespaces) }.flatMap { $0.isEmpty ? nil : $0 } ?? tipo.nome }

    /// Anni toccati dall'evento (almeno 1).
    var anniDurata: Int { max(1, durataAnni ?? 1) }

    /// L'età del cliente all'evento: `eta`, altrimenti dall'anno e dall'età di oggi (nil se non si sa).
    func etaEvento(etaOggi: Int?, annoOggi: Int) -> Int? {
        if let eta { return eta }
        guard let anno, let etaOggi else { return nil }
        return etaOggi + (anno - annoOggi)
    }

    private enum CodingKeys: String, CodingKey {
        case id, clienteId, tipo, eta, anno, importo, durataAnni, titolo, nota, origine
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Senza cliente l'evento non ha senso: si scarta (ElencoTollerante salta l'elemento)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        if let i = try? c.decodeIfPresent(String.self, forKey: .id), !i.isEmpty { id = i }
        tipo = (try? c.decodeIfPresent(String.self, forKey: .tipo)).flatMap { $0 }.flatMap(Tipo.init(rawValue:)) ?? .altro
        eta = (try? c.decodeIfPresent(Int.self, forKey: .eta)) ?? nil
        anno = (try? c.decodeIfPresent(Int.self, forKey: .anno)) ?? nil
        importo = ((try? c.decodeIfPresent(Double.self, forKey: .importo)) ?? nil).flatMap { $0.isFinite ? $0 : nil }
        durataAnni = (try? c.decodeIfPresent(Int.self, forKey: .durataAnni)) ?? nil
        titolo = (try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? nil
        nota = ((try? c.decodeIfPresent(String.self, forKey: .nota)) ?? nil) ?? ""
        origine = (try? c.decodeIfPresent(String.self, forKey: .origine)).flatMap { $0 }.flatMap(Origine.init(rawValue:)) ?? .manuale
    }
}
