import Foundation

/// Istruzioni di Ruby, lette da Ruby/Istruzioni nel pacchetto dell'app (le copia il workflow).
enum IstruzioniRuby {
    static let cartella = "Ruby/Istruzioni"

    static func testo(_ nome: String) -> String? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("\(cartella)/\(nome).md"),
              let t = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Istruzioni della chat; in sviluppo (`swift run`) ripiega su una versione minima.
    static var chat: String {
        testo("chat") ?? "Sei Ruby, l'assistente di un consulente finanziario italiano (canali Alleanza Assicurazioni e indipendente). Rispondi in italiano usando solo i dati della scheda del cliente; non inventare numeri e distingui sempre il canale."
    }

    /// La risposta breve della mini finestra di Ruby.
    static var mini: String {
        testo("mini") ?? "Rispondi in al massimo tre frasi brevi, senza elenchi: le cifre nel dettaglio le mostra Prisma sotto la risposta."
    }

    /// Istruzioni della modalità conversazione (uso generale).
    static var conversazione: String {
        testo("conversazione") ?? "Sei Ruby, l'assistente di un consulente finanziario italiano. Rispondi in italiano, in modo naturale e utile, a domande di ogni tipo. Non inventare dati dei clienti."
    }
}

/// Un motore che scrive testo libero (Qwen sul Mac): lo usano chat, commenti e spiegazioni dei documenti.
protocol MotoreGenerativo {
    var nome: String { get }
    func genera(istruzioni: String, richiesta: String) async throws -> String
}

/// I motori di Ruby. L'intelligenza artificiale è il modello sul Mac (Qwen con Ollama, o un server compatibile OpenAI).
/// I calcoli di Prisma (`sintesi`) preparano le cifre esatte che Qwen racconta, ma non rispondono da soli.
enum MotoriRuby {
    static let sintesi = MotoreSintesi()

    /// Qwen sul Mac, con lo stato verificato dall'ultima chiamata a Ollama.
    static func qwen(_ ruby: ImpostazioniRuby, locale: DisponibilitaRuby) -> MotoreLocale {
        MotoreLocale(ruby, disponibilita: locale)
    }

    /// Qwen, se è pronto; nil se Ollama è spento o manca il modello.
    static func generativo(_ ruby: ImpostazioniRuby, locale: DisponibilitaRuby) -> (MotoreRuby & MotoreGenerativo)? {
        let q = qwen(ruby, locale: locale)
        return q.disponibilita.pronto ? q : nil
    }

    /// Perché Qwen non risponde (nil se è pronto).
    static func motivo(_ ruby: ImpostazioniRuby, locale: DisponibilitaRuby) -> String? {
        locale.motivo
    }
}
