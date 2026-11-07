#if os(macOS)
import Foundation

/// Le istantanee della Ruby della scrivania (RubyScrivania.swift): la pagina di Ruby aperta, piccola, poi allargata
/// con una risposta e il quadro visivo nello stato finale (fermo: modoIstantanea). Senza Qwen: la conversazione
/// di prova la scrive qui, senza cifre; le cifre del quadro vengono dai calcoli di Prisma sui dati di prova.
extension Istantanee {
    nonisolated static var sceneRubyScrivania: [(nome: String, prepara: (StatoShell) -> Void)] {
        let chiare: [(String, (StatoShell) -> Void)] = [
            ("296-scrivania-ruby", { s in
                preparaRubyScrivania(s)
            }),
            ("297-scrivania-ruby-risposta", { s in
                preparaRubyScrivania(s)
                conversazioneDiProva(s, chiave: "giulia",
                                     domanda: "Come è diviso il patrimonio di Giulia?",
                                     risposta: "Il patrimonio di Giulia poggia soprattutto sulla casa; investimenti, liquidità e risparmio vengono dopo. Qui sotto le cifre di Prisma, area per area: la liquidità è il punto da cui partire per l'anticipo della casa.")
            }),
        ]
        let soloChiare: [(String, (StatoShell) -> Void)] = [
            ("298-scrivania-ruby-portafoglio-canali", { s in
                preparaRubyScrivania(s)
                s.rubyPortafoglio = true
                conversazioneDiProva(s, chiave: RubyPortafoglio.chiave,
                                     domanda: "Come si divide il portafoglio tra Alleanza e indipendente?",
                                     risposta: "Il portafoglio si regge su due canali: le polizze Alleanza e la consulenza indipendente. Le barre qui sotto mostrano quanto pesa ciascuno, con le cifre calcolate da Prisma.")
            }),
            ("299-scrivania-ruby-scadenze", { s in
                preparaRubyScrivania(s)
                conversazioneDiProva(s, chiave: "giulia",
                                     domanda: domandaMiniRuby,
                                     risposta: "Nei prossimi mesi a Giulia scadono il conto deposito e il piano di risparmio. È liquidità che può andare verso l'anticipo della casa: ne parlerei con lei prima della prima scadenza.")
            }),
        ]
        let conScuro: [(nome: String, prepara: (StatoShell) -> Void)] = chiare.flatMap { nome, prepara in
            [(nome: nome, prepara: prepara), (nome: nome + "-scuro", prepara: prepara)]
        }
        let altre: [(nome: String, prepara: (StatoShell) -> Void)] = soloChiare.map { (nome: $0.0, prepara: $0.1) }
        return conScuro + altre
    }

    /// La scrivania libera con la pagina di Ruby davanti, su Giulia Rossi, con Qwen pronto e due scadenze in arrivo.
    nonisolated static func preparaRubyScrivania(_ s: StatoShell) {
        let cal = Calendar.current
        let oggi = Date()
        func tra(_ mesi: Int, giorni: Int) -> Date? {
            cal.date(byAdding: .day, value: giorni, to: cal.date(byAdding: .month, value: mesi, to: oggi) ?? oggi)
        }
        for (id, mesi, giorni) in [("pos-giulia-conto-corrente-e-conto-deposito", 2, 12), ("pos-giulia-piano-di-risparmio-rivalutabile", 4, 3)] {
            if let i = s.dati.posizioni.firstIndex(where: { $0.id == id }) { s.dati.posizioni[i].scadenza = tra(mesi, giorni: giorni) }
        }
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "giulia"
        s.sistema.paginaRuby = 1
    }

    /// Una domanda e una risposta di Ruby (in modalità lavoro, come le scrive Qwen), senza chiamare il modello.
    nonisolated static func conversazioneDiProva(_ s: StatoShell, chiave: String, domanda: String, risposta: String) {
        s.aggiungiMessaggio(MessaggioRuby(autore: .utente, testo: domanda), cliente: chiave, parla: false)
        var m = MessaggioRuby(autore: .ruby, testo: risposta, motore: s.qwen.nome)
        m.modalita = .lavoro
        s.aggiungiMessaggio(m, cliente: chiave, parla: false)
    }
}
#endif
