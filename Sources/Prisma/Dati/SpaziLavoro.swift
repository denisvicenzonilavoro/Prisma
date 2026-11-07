import Foundation

/// Uno spazio di lavoro: un gruppo di app con la loro disposizione, da riaprire con un clic
/// (per esempio «Incontro con il cliente»: Clienti, Posizioni e Ruby affiancate).
struct SpazioLavoro: Identifiable, Codable, Hashable {
    var id = "spazio-\(UUID().uuidString.prefix(8).lowercased())"
    var nome: String
    var finestre: [FinestraSpazio]
    /// Gli spazi pronti di Prisma non si eliminano e non si salvano nell'archivio.
    var predefinito = false

    private enum CodingKeys: String, CodingKey { case id, nome, finestre }
}

extension SpazioLavoro {
    /// Lettura tollerante (versione 27, «Luce», decisione 104): una finestra di un'app che questo Prisma non conosce
    /// (per esempio un iPhone non ancora aggiornato che legge uno spazio con la Sala) si salta e lo spazio resta con le
    /// altre; uno spazio senza nessuna finestra leggibile non si apre.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let nome = try c.decode(String.self, forKey: .nome)
        let finestre = try c.decode(ElencoTollerante<FinestraSpazio>.self, forKey: .finestre).elementi
        guard !finestre.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .finestre, in: c, debugDescription: "Spazio senza finestre leggibili")
        }
        self.init(nome: nome, finestre: finestre)
        if let id = try c.decodeIfPresent(String.self, forKey: .id) { self.id = id }
    }
}

/// Una finestra dello spazio, in frazioni dell'area delle finestre (0…1): così la disposizione
/// si adatta a qualsiasi schermo.
struct FinestraSpazio: Codable, Hashable {
    var app: AppPrisma
    var x: Double
    var y: Double
    var larghezza: Double
    var altezza: Double
    var ingrandita = false

    var frazione: CGRect { CGRect(x: x, y: y, width: larghezza, height: altezza) }

    static func intera(_ app: AppPrisma) -> FinestraSpazio {
        FinestraSpazio(app: app, x: 0, y: 0, larghezza: 1, altezza: 1, ingrandita: true)
    }
    /// Quota dell'app principale quando due app sono affiancate (l'altra prende il resto).
    static let quotaPrincipale = 0.58

    static func sinistra(_ app: AppPrisma, quota: Double = quotaPrincipale) -> FinestraSpazio {
        FinestraSpazio(app: app, x: 0, y: 0, larghezza: quota, altezza: 1)
    }
    static func destra(_ app: AppPrisma, quota: Double = 1 - quotaPrincipale) -> FinestraSpazio {
        FinestraSpazio(app: app, x: 1 - quota, y: 0, larghezza: quota, altezza: 1)
    }
}

extension SpazioLavoro {
    /// Le disposizioni pronte: due app affiancate, la principale più larga e in primo piano.
    /// Non di più: le app hanno bisogno di spazio e le finestre una misura minima. Posizioni e
    /// Prospetti non si affiancano: su uno schermo da 13″ rendono solo a schermo pieno. Ruby sta bene
    /// nella colonna stretta.
    static let predefiniti: [SpazioLavoro] = [
        SpazioLavoro(id: "pronto-incontro", nome: "Incontro con il cliente",
                     finestre: [.destra(.ruby), .sinistra(.clienti)], predefinito: true),
        SpazioLavoro(id: "pronto-analisi", nome: "Analisi 360 con Ruby",
                     finestre: [.destra(.ruby), .sinistra(.analisi360)], predefinito: true),
        // Le attività ora vivono nell'Agenda (vista mese, con la colonna del giorno): accanto la scheda del cliente
        SpazioLavoro(id: "pronto-giornata", nome: "La giornata",
                     finestre: [.destra(.clienti), .sinistra(.agenda)], predefinito: true),
    ]

    /// Le app, dalla principale (l'ultima, in primo piano) alle altre.
    var app: [AppPrisma] { finestre.reversed().map(\.app) }
}
