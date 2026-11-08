import Foundation

/// Una campagna avviata (Messaggi › Campagne, «Luce» giro 12, §9.4). I testi restano `MessaggioCliente` in
/// `DatiPrisma.messaggi`: qui solo chi, quando, quale bisogno e gli id delle bozze. Serve allo storico «Campagne avviate»
/// e alla regola dei 30 giorni fra due campagne (decisione 97). Archivio versione 27, sezione «relazione».
struct Campagna: Identifiable, Codable, Hashable {
    /// "campagna-<uuid8>".
    var id: String
    /// `GruppoCampagna.id` (es. "scadenzaNelMese-2027-03").
    var gruppoId: String
    /// nil = tipo di un Prisma più nuovo: la campagna resta per la regola dei 30 giorni.
    var gruppoTipo: TipoGruppoCampagna?
    var titolo: String
    /// Al secondo, come le altre date dell'archivio.
    var avviataIl: Date
    var tono: TonoMessaggio
    var canale: CanaleMessaggio
    /// Gli id dei clienti inclusi.
    var clienti: [String]
    /// Gli orari proposti nel testo (spazi liberi dell'Agenda, mai bloccati: decisione 98).
    var appuntamenti: [Date]
    /// Gli id dei `MessaggioCliente` creati.
    var messaggi: [String]

    init(id: String = "campagna-\(UUID().uuidString.prefix(8).lowercased())", gruppoId: String,
         gruppoTipo: TipoGruppoCampagna?, titolo: String, avviataIl: Date = MessaggioCliente.adesso,
         tono: TonoMessaggio, canale: CanaleMessaggio, clienti: [String], appuntamenti: [Date], messaggi: [String]) {
        self.id = id
        self.gruppoId = gruppoId
        self.gruppoTipo = gruppoTipo
        self.titolo = titolo
        self.avviataIl = avviataIl
        self.tono = tono
        self.canale = canale
        self.clienti = clienti
        self.appuntamenti = appuntamenti
        self.messaggi = messaggi
    }

    private enum CodingKeys: String, CodingKey {
        case id, gruppoId, gruppoTipo, titolo, avviataIl, tono, canale, clienti, appuntamenti, messaggi
    }

    /// Lettura tollerante: senza id si scarta; tono e canale sconosciuti → cordiale e Mail; tipo del gruppo sconosciuto → nil.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        guard !id.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: c, debugDescription: "Campagna senza id")
        }
        gruppoId = ((try? c.decodeIfPresent(String.self, forKey: .gruppoId)) ?? nil) ?? ""
        let tipo = (try? c.decodeIfPresent(String.self, forKey: .gruppoTipo)) ?? nil
        gruppoTipo = tipo.flatMap { TipoGruppoCampagna(rawValue: $0) }
        titolo = ((try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? nil) ?? ""
        avviataIl = ((try? c.decodeIfPresent(Date.self, forKey: .avviataIl)) ?? nil) ?? MessaggioCliente.adesso
        let t = (try? c.decodeIfPresent(String.self, forKey: .tono)) ?? nil
        tono = t.flatMap { TonoMessaggio(rawValue: $0) } ?? .cordiale
        let k = (try? c.decodeIfPresent(String.self, forKey: .canale)) ?? nil
        canale = k.flatMap { CanaleMessaggio(rawValue: $0) } ?? .mail
        clienti = ((try? c.decodeIfPresent([String].self, forKey: .clienti)) ?? nil) ?? []
        appuntamenti = ((try? c.decodeIfPresent([Date].self, forKey: .appuntamenti)) ?? nil) ?? []
        messaggi = ((try? c.decodeIfPresent([String].self, forKey: .messaggi)) ?? nil) ?? []
    }
}
