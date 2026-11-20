import Foundation

/// Istruzioni di Vera, lette da Vera/Istruzioni nel pacchetto dell'app (le copia il workflow).
enum IstruzioniVera {
    static let cartella = "Vera/Istruzioni"

    static func testo(_ nome: String) -> String? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("\(cartella)/\(nome).md"),
              let t = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Chat, mini e conversazione si leggono una volta sola: le risorse del pacchetto non cambiano mentre l'app gira, e
    // la chat le chiede a ogni domanda e il filo lungo a ogni ridisegno (prima ogni volta era una lettura dal disco).

    /// Istruzioni della chat; in sviluppo (`swift run`) ripiega su una versione minima.
    static let chat: String =
        testo("chat") ?? "Sei Vera, l'assistente di un consulente finanziario italiano (canali Alleanza Assicurazioni e indipendente). Rispondi in italiano usando solo i dati della scheda del cliente; non inventare numeri e distingui sempre il canale."

    /// La risposta breve della mini finestra di Vera.
    static let mini: String =
        testo("mini") ?? "Rispondi in al massimo tre frasi brevi, senza elenchi: le cifre nel dettaglio le mostra Prisma sotto la risposta."

    /// Istruzioni della modalità conversazione (uso generale).
    static let conversazione: String =
        testo("conversazione") ?? "Sei Vera, l'assistente di un consulente finanziario italiano. Rispondi in italiano, in modo naturale e utile, a domande di ogni tipo. Non inventare dati dei clienti."
}

/// Un motore che scrive testo libero (Qwen sul Mac): lo usano chat, commenti e spiegazioni dei documenti.
protocol MotoreGenerativo {
    var nome: String { get }
    func genera(istruzioni: String, richiesta: String) async throws -> String
}

/// I motori di Vera. L'intelligenza artificiale è il modello sul Mac (Qwen con Ollama, o un server compatibile OpenAI).
/// I calcoli di Prisma (`sintesi`) preparano le cifre esatte che Qwen racconta, ma non rispondono da soli.
enum MotoriVera {
    static let sintesi = MotoreSintesi()

    /// Qwen sul Mac, con lo stato verificato dall'ultima chiamata a Ollama.
    static func qwen(_ vera: ImpostazioniVera, locale: DisponibilitaVera) -> MotoreLocale {
        MotoreLocale(vera, disponibilita: locale)
    }

    /// Qwen, se è pronto; nil se Ollama è spento o manca il modello.
    static func generativo(_ vera: ImpostazioniVera, locale: DisponibilitaVera) -> (MotoreVera & MotoreGenerativo)? {
        let q = qwen(vera, locale: locale)
        return q.disponibilita.pronto ? q : nil
    }

    /// Il motore della scelta automatica (MotoriMistral.swift). Se la scelta è il modello del Mac vale `generativo`;
    /// un altro modello (Quotidiano o Profondo) la scelta lo dà solo se Ollama l'ha già tra i modelli scaricati.
    /// Su iPhone e iPad risponde sempre il modello del Mac attraverso il ponte.
    /// Sul computer dell'IA (tappa 2) il motore parla attraverso il ponte cifrato con il suo codice.
    static func generativo(_ scelta: SceltaMotore, vera: ImpostazioniVera, locale: DisponibilitaVera,
                           computerIA: StatoComputerIA? = nil) -> (MotoreVera & MotoreGenerativo)? {
        #if os(iOS)
        return generativo(vera, locale: locale)
        #else
        if scelta.dove == .computerIA {
            // Senza lo stato del computer dell'IA (appena scollegato) risponde il modello del Mac
            guard let ia = computerIA else { return generativo(vera, locale: locale) }
            return MotoreLocale(fornitore: ComputerIA.fornitore(vera, stato: ia, modello: scelta.modello), disponibilita: .pronto,
                                restaInMemoria: vera.restaInMemoria, nome: "\(scelta.famiglia) sul computer dell'IA")
        }
        guard !FornitoreOllama.stessoModello(scelta.modello, vera.modello) else { return generativo(vera, locale: locale) }
        guard locale.pronto else { return nil }
        var altro = vera
        altro.modello = scelta.modello
        return MotoreLocale(altro, disponibilita: .pronto)
        #endif
    }

    /// Perché Qwen non risponde (nil se è pronto).
    static func motivo(_ vera: ImpostazioniVera, locale: DisponibilitaVera) -> String? {
        locale.motivo
    }
}
