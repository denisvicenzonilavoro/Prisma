#if os(macOS)
import Foundation

/// Le istantanee di Vera nel tema Apple (§4.7, PIE e01…e10): la colonna con la sfera grande, «Ciao, sono Vera.», lo
/// stato vero di Qwen e la card «Oggi»; la chat che comincia con il saluto di Vera, i suggerimenti e il campo a
/// capsula; la testata con «Lavoro / Conversazione». Poi una risposta con la scheda dei calcoli (le cifre dai
/// motori di Prisma sui dati di prova), i puntini «sta scrivendo» e Qwen non pronto. Tutto nello stato finale.
extension Istantanee {
    nonisolated static var sceneVeraApple: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("480-vera-apple", { s in preparaVeraApple(s) }),
            ("480-vera-apple-scuro", { s in preparaVeraApple(s) }),
            ("481-vera-risposta-calcoli", { s in
                preparaVeraApple(s)
                conversazioneDiProva(s, chiave: "giulia",
                                     domanda: "Come è diviso il patrimonio di Giulia?",
                                     risposta: "Il patrimonio di Giulia poggia soprattutto sulla casa; investimenti, liquidità e risparmio vengono dopo. Qui sotto le cifre di Prisma, area per area: la liquidità è il punto da cui partire per l'anticipo della casa.")
            }),
            ("481-vera-risposta-calcoli-scuro", { s in
                preparaVeraApple(s)
                conversazioneDiProva(s, chiave: "giulia",
                                     domanda: "Come è diviso il patrimonio di Giulia?",
                                     risposta: "Il patrimonio di Giulia poggia soprattutto sulla casa; investimenti, liquidità e risparmio vengono dopo. Qui sotto le cifre di Prisma, area per area: la liquidità è il punto da cui partire per l'anticipo della casa.")
            }),
            // La domanda appena partita: la bolla dell'utente, i puntini e la sfera che pulsa (ferma, in istantanea)
            ("482-vera-sta-scrivendo", { s in
                preparaVeraApple(s)
                s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "Spiegami la previdenza di Giulia"), cliente: "giulia", parla: false)
                s.veraInCorso = true
                s.flussoVera.inizia(SceltaVera(modalita: .lavoro, pensa: false), motore: s.qwen.nome)
            }),
            // Qwen non è pronto: la card lo dice, con «Verifica»; Vera non risponde
            ("483-vera-qwen-non-pronto", { s in
                preparaVeraApple(s)
                s.disponibilitaLocale = .nonDisponibile("Ollama non risponde: aprilo sul Mac e premi «Verifica».")
            }),
        ]
    }

    /// L'app Vera su Giulia Rossi, con Qwen pronto e la conversazione vuota.
    nonisolated static func preparaVeraApple(_ s: StatoShell) {
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "giulia"
        s.veraPortafoglio = false
        s.apri(.vera)
    }
}
#endif
