#if os(macOS)
import Foundation

/// Le istantanee della Vera della scrivania (VeraScrivania.swift): la pagina di Vera aperta, piccola, poi allargata
/// con una risposta e il quadro visivo nello stato finale (fermo: modoIstantanea). Senza Qwen: la conversazione
/// di prova la scrive qui, senza cifre; le cifre del quadro vengono dai calcoli di Prisma sui dati di prova.
extension Istantanee {
    nonisolated static var sceneVeraScrivania: [(nome: String, prepara: (StatoShell) -> Void)] {
        let chiare: [(String, (StatoShell) -> Void)] = [
            ("296-scrivania-vera", { s in
                preparaVeraScrivania(s)
            }),
            ("297-scrivania-vera-risposta", { s in
                preparaVeraScrivania(s)
                conversazioneDiProva(s, chiave: "giulia",
                                     domanda: "Come è diviso il patrimonio di Giulia?",
                                     risposta: "Il patrimonio di Giulia poggia soprattutto sulla casa; investimenti, liquidità e risparmio vengono dopo. Qui sotto le cifre di Prisma, area per area: la liquidità è il punto da cui partire per l'anticipo della casa.")
            }),
        ]
        let soloChiare: [(String, (StatoShell) -> Void)] = [
            ("298-scrivania-vera-portafoglio-canali", { s in
                preparaVeraScrivania(s)
                s.veraPortafoglio = true
                conversazioneDiProva(s, chiave: VeraPortafoglio.chiave,
                                     domanda: "Come si divide il portafoglio tra Alleanza e indipendente?",
                                     risposta: "Il portafoglio si regge su due canali: le polizze Alleanza e la consulenza indipendente. Le barre qui sotto mostrano quanto pesa ciascuno, con le cifre calcolate da Prisma.")
            }),
            ("299-scrivania-vera-scadenze", { s in
                preparaVeraScrivania(s)
                conversazioneDiProva(s, chiave: "giulia",
                                     domanda: domandaMiniVera,
                                     risposta: "Nei prossimi mesi a Giulia scadono il conto deposito e il piano di risparmio. È liquidità che può andare verso l'anticipo della casa: ne parlerei con lei prima della prima scadenza.")
            }),
        ]
        let conScuro: [(nome: String, prepara: (StatoShell) -> Void)] = chiare.flatMap { nome, prepara in
            [(nome: nome, prepara: prepara), (nome: nome + "-scuro", prepara: prepara)]
        }
        let altre: [(nome: String, prepara: (StatoShell) -> Void)] = soloChiare.map { (nome: $0.0, prepara: $0.1) }
        return conScuro + altre
    }

    /// La scrivania libera con la pagina di Vera davanti, su Giulia Rossi, con Qwen pronto e due scadenze in arrivo.
    nonisolated static func preparaVeraScrivania(_ s: StatoShell) {
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
        s.sistema.paginaVera = 1
    }

    /// Una domanda e una risposta di Vera (in modalità lavoro, come le scrive Qwen), senza chiamare il modello.
    nonisolated static func conversazioneDiProva(_ s: StatoShell, chiave: String, domanda: String, risposta: String) {
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: domanda), cliente: chiave, parla: false)
        var m = MessaggioVera(autore: .vera, testo: risposta, motore: s.qwen.nome)
        m.modalita = .lavoro
        s.aggiungiMessaggio(m, cliente: chiave, parla: false)
    }
}
#endif
