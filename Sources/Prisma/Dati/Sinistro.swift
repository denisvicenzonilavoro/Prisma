import Foundation

// Il sinistro come una spedizione («Luce» giro 15, §7.4): fasi, fatti brevi, documenti e stime. Solo testi brevi e
// generici (decisione 36: niente diagnosi né referti; i referti vanno nei Documenti del cliente). Sta nella sezione
// «pratiche» della cartella a pezzi e nei backup; in «Prisma ovunque» entra limitato (`SpazioOvunque.sinistroPerOvunque`:
// senza descrizione, numero di sinistro, stime, importo pagato e senza i file dei documenti).

/// Le fasi del sinistro: le cinque del percorso più «Respinto» (D4.4, nodo rosso).
enum FaseSinistro: String, Codable, CaseIterable {
    case denuncia, documenti, perizia, liquidazione, pagato, respinto

    /// Il percorso normale (D4.5): «Respinto» ne è fuori.
    static let percorso: [FaseSinistro] = [.denuncia, .documenti, .perizia, .liquidazione, .pagato]

    var nome: String {
        switch self {
        case .denuncia: return "Denuncia"
        case .documenti: return "Documenti"
        case .perizia: return "Perizia"
        case .liquidazione: return "Liquidazione"
        case .pagato: return "Pagato"
        case .respinto: return "Respinto"
        }
    }
}

/// Un fatto breve («Inviati i documenti alla compagnia»), con la fase a cui appartiene.
struct EventoSinistro: Identifiable, Codable, Hashable {
    var id: String
    var data: Date
    var testo: String
    var fase: FaseSinistro?
}

/// Un documento richiesto: ricevuto o mancante; il file, se c'è, sta nei Documenti del cliente.
struct DocumentoSinistro: Identifiable, Codable, Hashable {
    var id: String
    var titolo: String
    var ricevutoIl: Date?
    var documentoId: String?
}

struct Sinistro: Identifiable, Codable, Hashable {
    var id: String
    var clienteId: String
    /// La polizza; il canale viene da lì. Nil = «polizza da collegare».
    var posizioneId: String? = nil
    /// «Infortunio di Pietro» (al più 60 caratteri).
    var titolo: String
    /// Breve, senza dettagli sanitari (al più 140 caratteri). Non esce dal Mac.
    var descrizione: String = ""
    var accadutoIl: Date? = nil
    /// La data della denuncia: da qui «Aperto da».
    var apertoIl: Date
    var numeroSinistro: String? = nil
    var fase: FaseSinistro = .denuncia
    var eventi: [EventoSinistro] = []
    var documenti: [DocumentoSinistro] = []
    var stimaMinima: Double? = nil
    var stimaMassima: Double? = nil
    var pagato: Double? = nil
    var chiusoIl: Date? = nil
    /// D4.7: gli aggiornamenti per il cliente sono spenti finché il consulente non li accende.
    var mostraAlCliente: Bool? = nil
    /// Decisione 11: l'importo pagato nell'aggiornamento al cliente solo se acceso.
    var importoAlCliente: Bool? = nil
    var ultimoAggiornamentoCliente: Date? = nil

    private enum CodingKeys: String, CodingKey {
        case id, clienteId, posizioneId, titolo, descrizione, accadutoIl, apertoIl, numeroSinistro, fase, eventi, documenti
        case stimaMinima, stimaMassima, pagato, chiusoIl, mostraAlCliente, importoAlCliente, ultimoAggiornamentoCliente
    }
}

extension Sinistro {
    /// Lettura tollerante: id, cliente e data della denuncia obbligatori (senza, il sinistro si scarta); una fase
    /// sconosciuta torna «Denuncia»; un fatto o un documento illeggibile si scarta, gli altri restano.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        posizioneId = (try? c.decodeIfPresent(String.self, forKey: .posizioneId)) ?? nil
        titolo = ((try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? nil) ?? ""
        descrizione = ((try? c.decodeIfPresent(String.self, forKey: .descrizione)) ?? nil) ?? ""
        accadutoIl = (try? c.decodeIfPresent(Date.self, forKey: .accadutoIl)) ?? nil
        apertoIl = try c.decode(Date.self, forKey: .apertoIl)
        numeroSinistro = (try? c.decodeIfPresent(String.self, forKey: .numeroSinistro)) ?? nil
        fase = ((try? c.decodeIfPresent(FaseSinistro.self, forKey: .fase)) ?? nil) ?? .denuncia
        eventi = ((try? c.decodeIfPresent(ElencoTollerante<EventoSinistro>.self, forKey: .eventi)) ?? nil)?.elementi ?? []
        documenti = ((try? c.decodeIfPresent(ElencoTollerante<DocumentoSinistro>.self, forKey: .documenti)) ?? nil)?.elementi ?? []
        stimaMinima = ((try? c.decodeIfPresent(Double.self, forKey: .stimaMinima)) ?? nil).flatMap { $0.isFinite ? $0 : nil }
        stimaMassima = ((try? c.decodeIfPresent(Double.self, forKey: .stimaMassima)) ?? nil).flatMap { $0.isFinite ? $0 : nil }
        pagato = ((try? c.decodeIfPresent(Double.self, forKey: .pagato)) ?? nil).flatMap { $0.isFinite ? $0 : nil }
        chiusoIl = (try? c.decodeIfPresent(Date.self, forKey: .chiusoIl)) ?? nil
        mostraAlCliente = (try? c.decodeIfPresent(Bool.self, forKey: .mostraAlCliente)) ?? nil
        importoAlCliente = (try? c.decodeIfPresent(Bool.self, forKey: .importoAlCliente)) ?? nil
        ultimoAggiornamentoCliente = (try? c.decodeIfPresent(Date.self, forKey: .ultimoAggiornamentoCliente)) ?? nil
    }
}

/// Ciò che il cliente vede (telefono «Così lo vede …» e blocco del file del cliente): solo titolo, fasi, ultimo fatto,
/// data e consulente; l'importo pagato solo se il consulente lo ha acceso nel sinistro.
struct SinistroMini: Codable, Equatable {
    enum StatoFase: String, Codable {
        case fatta, adesso, futura, respinta
    }

    struct Fase: Codable, Equatable {
        var nome: String
        var stato: StatoFase
    }

    var titolo: String
    var fasi: [Fase]
    var ultimoFatto: String?
    var aggiornatoIl: Date
    var consulente: String
    var pagato: String?
}

extension Sinistro {
    /// Il fatto più recente (a pari data l'ultimo scritto).
    var ultimoEvento: EventoSinistro? {
        eventi.enumerated().max { a, b in
            a.element.data != b.element.data ? a.element.data < b.element.data : a.offset < b.offset
        }?.element
    }

    /// La vista del cliente: mai descrizione, numero di sinistro, stime o documenti; l'importo pagato solo con
    /// `importoAlCliente == true`.
    func perIlCliente(consulente: String, oggi: Date) -> SinistroMini {
        var fasi: [SinistroMini.Fase] = []
        if fase == .respinto {
            // Le fasi del percorso raggiunte prima del rifiuto (dai fatti), poi il nodo rosso
            let raggiunte = eventi.compactMap(\.fase).compactMap { FaseSinistro.percorso.firstIndex(of: $0) }
            let ultima = raggiunte.max() ?? 0
            for (i, f) in FaseSinistro.percorso.enumerated() where i <= ultima && f != .pagato {
                fasi.append(.init(nome: f.nome, stato: .fatta))
            }
            fasi.append(.init(nome: FaseSinistro.respinto.nome, stato: .respinta))
        } else {
            let attuale = FaseSinistro.percorso.firstIndex(of: fase) ?? 0
            for (i, f) in FaseSinistro.percorso.enumerated() {
                let stato: SinistroMini.StatoFase
                if i < attuale || fase == .pagato { stato = .fatta } else if i == attuale { stato = .adesso } else { stato = .futura }
                fasi.append(.init(nome: f.nome, stato: stato))
            }
        }
        let ultimo = ultimoEvento
        let aggiornato = ultimoAggiornamentoCliente ?? ultimo?.data ?? apertoIl
        let importo: String? = (importoAlCliente == true) ? pagato.map { Formati.euro($0) } : nil
        return SinistroMini(titolo: titolo, fasi: fasi, ultimoFatto: ultimo?.testo, aggiornatoIl: min(aggiornato, oggi),
                            consulente: consulente, pagato: importo)
    }
}
