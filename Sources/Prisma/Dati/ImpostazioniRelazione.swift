import Foundation

// Le impostazioni delle due novità di «Studio e relazione» («Luce» giro 5, Design/template-luce-specifica.md §5.2.5
// punto 5.3 e §5.4.5 punto 5.3): la storia della settimana del lunedì e i traguardi festeggiati. Stanno nell'archivio
// (`Impostazioni.storie`, `Impostazioni.traguardi`, versione 27) ed entrano nel backup; lette con tolleranza: un campo
// illeggibile torna al suo valore di base, mai un errore che fa perdere le altre impostazioni.

/// «La tua settimana»: il lunedì si apre da sola una volta dopo lo sblocco (spegnibile in Impostazioni › Studio) e
/// Prisma ricorda quale settimana e quale anno sono già stati visti, per non riproporli.
struct ImpostazioniStorie: Codable, Equatable, Hashable {
    /// Il lunedì, al primo sblocco, la storia della settimana si apre da sola (una volta per settimana).
    var aperturaLunedi = true
    /// Il lunedì della settimana già vista (inizio del giorno); nil = mai vista.
    var ultimaSettimanaVista: Date?
    /// L'anno della storia «Il tuo anno» già vista; nil = mai vista.
    var ultimoAnnoVisto: Int?

    init() {}

    private enum CodingKeys: String, CodingKey { case aperturaLunedi, ultimaSettimanaVista, ultimoAnnoVisto }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        aperturaLunedi = ((try? c.decodeIfPresent(Bool.self, forKey: .aperturaLunedi)) ?? nil) ?? true
        ultimaSettimanaVista = (try? c.decodeIfPresent(Date.self, forKey: .ultimaSettimanaVista)) ?? nil
        ultimoAnnoVisto = (try? c.decodeIfPresent(Int.self, forKey: .ultimoAnnoVisto)) ?? nil
    }
}

/// I traguardi: quali tipi sono spenti, a quanti anni si festeggia il rapporto, quali traguardi sono già stati
/// festeggiati (id → quando) o scartati («Non è un traguardo»). Un traguardo festeggiato resta nella lista con la spunta
/// fino al giorno dopo; uno scartato non torna.
struct ImpostazioniTraguardi: Codable, Equatable, Hashable {
    /// Gli anniversari del rapporto festeggiati (decisione 87: 1, 5, 10, 15 e 20 anni).
    static let anniversariPredefiniti = [1, 5, 10, 15, 20]

    var tipiSpenti: [TipoTraguardo] = []
    var anniversari = ImpostazioniTraguardi.anniversariPredefiniti
    var festeggiati: [String: Date] = [:]
    var scartati: [String] = []

    init() {}

    private enum CodingKeys: String, CodingKey { case tipiSpenti, anniversari, festeggiati, scartati }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Un tipo che questo Prisma non conosce (di una versione più nuova) si salta
        let tipi = ((try? c.decodeIfPresent([String].self, forKey: .tipiSpenti)) ?? nil) ?? []
        tipiSpenti = tipi.compactMap(TipoTraguardo.init(rawValue:))
        let anni = (((try? c.decodeIfPresent([Int].self, forKey: .anniversari)) ?? nil) ?? Self.anniversariPredefiniti)
            .filter { $0 > 0 && $0 <= 100 }
        anniversari = Array(Set(anni)).sorted()
        festeggiati = ((try? c.decodeIfPresent([String: Date].self, forKey: .festeggiati)) ?? nil) ?? [:]
        scartati = ((try? c.decodeIfPresent([String].self, forKey: .scartati)) ?? nil) ?? []
    }
}
