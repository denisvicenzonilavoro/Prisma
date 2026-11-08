import Foundation

// «Il cervello grande» (Vera/BRIEF.md, fase 5, funzione 25): l'aggancio a un motore esterno, più grande, per le domande
// generali. In questa fase è predisposto e NON collegato: nessuna richiesta parte, nessuna chiave è salvata. Le regole
// sono bloccate nel codice e non si spengono dalle impostazioni: i dati dei clienti non escono mai dal Mac, il motore
// esterno riceve solo domande della modalità conversazione (senza schede, documenti o numeri dei clienti) e sotto ogni
// risposta c'è l'etichetta di chi l'ha scritta.

/// Che tipo di motore esterno l'utente collegherà un domani (solo la scelta: resta non collegato).
enum TipoMotoreEsterno: String, Codable, CaseIterable, Identifiable {
    /// Un modello grande su un tuo computer o server.
    case server
    /// Un servizio a pagamento.
    case servizio

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .server: return "Un tuo server"
        case .servizio: return "Un servizio a pagamento"
        }
    }

    var spiegazione: String {
        switch self {
        case .server: return "Un modello grande su un tuo computer: le domande generali restano tue, anche fuori dal Mac."
        case .servizio: return "Un servizio in cloud, a pagamento: riceve solo le domande generali, mai i dati dei clienti."
        }
    }
}

/// Le impostazioni del motore esterno: solo il tipo scelto. Nessun indirizzo, nessuna chiave (quando l'utente collegherà,
/// la chiave andrà nel Portachiavi, mai nell'archivio).
struct ImpostazioniMotoreEsterno: Codable, Equatable {
    var tipo = TipoMotoreEsterno.server

    init() {}

    private enum CodingKeys: String, CodingKey { case tipo }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tipo = (try? c.decodeIfPresent(TipoMotoreEsterno.self, forKey: .tipo)) ?? .server
    }
}
