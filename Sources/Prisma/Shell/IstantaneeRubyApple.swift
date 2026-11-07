#if os(macOS)
import Foundation

/// Le istantanee di Ruby nel tema Apple (§4.7, PIE e01…e10): la colonna con la sfera grande, «Ciao, sono Ruby.», lo
/// stato vero di Qwen e la card «Oggi»; la chat che comincia con il saluto di Ruby, i suggerimenti e il campo a
/// capsula; la testata con «Lavoro / Conversazione». Poi una risposta con la scheda dei calcoli (le cifre dai
/// motori di Prisma sui dati di prova), i puntini «sta scrivendo» e Qwen non pronto. Tutto nello stato finale.
extension Istantanee {
    nonisolated static var sceneRubyApple: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("480-ruby-apple", { s in preparaRubyApple(s) }),
            ("480-ruby-apple-scuro", { s in preparaRubyApple(s) }),
            ("481-ruby-risposta-calcoli", { s in
                preparaRubyApple(s)
                conversazioneDiProva(s, chiave: "giulia",
                                     domanda: "Come è diviso il patrimonio di Giulia?",
                                     risposta: "Il patrimonio di Giulia poggia soprattutto sulla casa; investimenti, liquidità e risparmio vengono dopo. Qui sotto le cifre di Prisma, area per area: la liquidità è il punto da cui partire per l'anticipo della casa.")
            }),
            ("481-ruby-risposta-calcoli-scuro", { s in
                preparaRubyApple(s)
                conversazioneDiProva(s, chiave: "giulia",
                                     domanda: "Come è diviso il patrimonio di Giulia?",
                                     risposta: "Il patrimonio di Giulia poggia soprattutto sulla casa; investimenti, liquidità e risparmio vengono dopo. Qui sotto le cifre di Prisma, area per area: la liquidità è il punto da cui partire per l'anticipo della casa.")
            }),
            // La domanda appena partita: la bolla dell'utente, i puntini e la sfera che pulsa (ferma, in istantanea)
            ("482-ruby-sta-scrivendo", { s in
                preparaRubyApple(s)
                s.aggiungiMessaggio(MessaggioRuby(autore: .utente, testo: "Spiegami la previdenza di Giulia"), cliente: "giulia", parla: false)
                s.rubyInCorso = true
                s.flussoRuby.inizia(SceltaRuby(modalita: .lavoro, pensa: false), motore: s.qwen.nome)
            }),
            // Qwen non è pronto: la card lo dice, con «Verifica»; Ruby non risponde
            ("483-ruby-qwen-non-pronto", { s in
                preparaRubyApple(s)
                s.disponibilitaLocale = .nonDisponibile("Ollama non risponde: aprilo sul Mac e premi «Verifica».")
            }),
        ]
    }

    /// L'app Ruby su Giulia Rossi, con Qwen pronto e la conversazione vuota.
    nonisolated static func preparaRubyApple(_ s: StatoShell) {
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "giulia"
        s.rubyPortafoglio = false
        s.apri(.ruby)
    }
}
#endif
