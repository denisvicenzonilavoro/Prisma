import Foundation

// Il registro leggero della palestra della trattativa (Studio › Palestra, versione 27, «Luce» giro 5, decisione 51):
// solo data, cliente, difficoltà e punteggio di ogni allenamento finito, al massimo 50 (i più vecchi si tolgono). Le
// conversazioni non si salvano: sono prove, non fatti del cliente, e non entrano nel dossier.

/// Un allenamento finito.
struct EsitoPalestra: Codable, Equatable, Identifiable {
    var id = "palestra-\(UUID().uuidString.prefix(8).lowercased())"
    var data: Date
    /// Il cliente recitato (nil con un profilo inventato).
    var clienteId: String?
    var difficolta: DifficoltaPalestra
    /// Il punteggio indicativo, 0-100.
    var punteggio: Int

    init(data: Date, clienteId: String?, difficolta: DifficoltaPalestra, punteggio: Int) {
        self.data = data
        self.clienteId = clienteId
        self.difficolta = difficolta
        self.punteggio = min(100, max(0, punteggio))
    }

    private enum CodingKeys: String, CodingKey {
        case id, data, clienteId, difficolta, punteggio
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        data = try c.decode(Date.self, forKey: .data)
        clienteId = (try? c.decodeIfPresent(String.self, forKey: .clienteId)) ?? nil
        // Una difficoltà che questo Prisma non conosce vale «Realistica»
        difficolta = ((try? c.decodeIfPresent(DifficoltaPalestra.self, forKey: .difficolta)) ?? nil) ?? .realistica
        punteggio = min(100, max(0, (try? c.decodeIfPresent(Int.self, forKey: .punteggio)) ?? nil ?? 0))
    }
}

/// Le impostazioni della palestra: per ora solo il registro degli allenamenti.
struct ImpostazioniPalestra: Codable, Equatable {
    var allenamenti: [EsitoPalestra] = []

    init() {}

    private enum CodingKeys: String, CodingKey { case allenamenti }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Un allenamento illeggibile si scarta, gli altri restano
        allenamenti = ((try? c.decodeIfPresent(ElencoTollerante<EsitoPalestra>.self, forKey: .allenamenti)) ?? nil)?.elementi ?? []
    }

    /// Aggiunge un esito e tiene gli ultimi `PalestraVera.massimoEsiti`.
    mutating func registra(_ e: EsitoPalestra) {
        allenamenti.append(e)
        if allenamenti.count > PalestraVera.massimoEsiti {
            allenamenti.removeFirst(allenamenti.count - PalestraVera.massimoEsiti)
        }
    }
}
