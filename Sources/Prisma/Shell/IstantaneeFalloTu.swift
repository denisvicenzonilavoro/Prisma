#if os(macOS)
import Foundation

/// Le istantanee della fase 1 di Vera (Design/template-vera.html), chiare e scure, senza Qwen:
/// - «Fallo tu»: «sposta l'incontro con Laura e avvisala», la scheda con due azioni da confermare, e la stessa scheda
///   dopo «Conferma» con le righe spuntate e la risposta di Vera;
/// - «Chiedi alla tua clientela»: i filtri capiti, la tabella dei clienti e «Crea N attività»;
/// - «Mai a caso»: una risposta con le cifre sottolineate dai rimandi, le fonti e una cifra «non trovata».
extension Istantanee {
    nonisolated static var sceneFalloTu: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("485-vera-fallo-tu", { s in preparaFalloTu(s, conferma: false) }),
            ("485-vera-fallo-tu-scuro", { s in preparaFalloTu(s, conferma: false) }),
            ("485-vera-fallo-tu-fatto", { s in preparaFalloTu(s, conferma: true) }),
            ("486-vera-clientela", { s in preparaClientela(s) }),
            ("486-vera-clientela-scuro", { s in preparaClientela(s) }),
            ("487-vera-mai-a-caso", { s in preparaMaiACaso(s) }),
            ("487-vera-mai-a-caso-scuro", { s in preparaMaiACaso(s) }),
        ]
    }

    /// La scheda di «Fallo tu» come la prepara Prisma dalle due chiamate di Qwen.
    nonisolated static func preparaFalloTu(_ s: StatoShell, conferma: Bool) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "laura"
        s.veraPortafoglio = false
        guard let laura = s.dati.appuntamenti.first(where: { $0.id == "event-laura" }) else { return }
        let giovedi = Calendar.current.date(byAdding: .day, value: 2, to: laura.inizio) ?? laura.inizio
        let richiesta = "Sposta l'incontro con Laura di domani alle \(Formati.ora.string(from: laura.inizio)) a \(Formati.giornoSettimana.string(from: giovedi)), stessa ora, e avvisala con un messaggio."
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: richiesta), cliente: "laura", parla: false)
        let r = RispostaConStrumenti(testo: "", chiamate: [
            ChiamataStrumento(nome: RegistroStrumenti.agendaSposta, argomenti: ["cliente": "Laura", "giorno_attuale": "domani",
                                                                               "nuovo_giorno": Formati.formato("yyyy-MM-dd").string(from: giovedi)]),
            ChiamataStrumento(nome: RegistroStrumenti.messaggiPrepara, argomenti: ["cliente": "Laura", "scopo": "spostamento"]),
        ])
        let m = s.rispondiFalloTu(r, richiesta: richiesta, chiave: "laura", motore: s.qwen.nome)
        if conferma { s.confermaSchedaVera(messaggio: m.id) }
        s.apri(.vera)
    }

    /// «Chi ha polizze in scadenza nei prossimi mesi e non lo vedo da almeno tre mesi?» sui 35 clienti.
    nonisolated static func preparaClientela(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.dati.carica(ClientiFittizi.completi())
        s.veraPortafoglio = true
        let domanda = "Chi non ha una protezione per il coniuge?"
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: domanda), cliente: VeraPortafoglio.chiave, parla: false)
        s.rispondiClientela([FiltroClientela(.coniugeSenzaProtezione)], domanda: domanda, motore: s.qwen.nome)
        s.apri(.vera)
    }

    /// Una risposta di Qwen su Giulia: la cifra della posizione con la sua fonte e una cifra inventata «non trovata».
    nonisolated static func preparaMaiACaso(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "giulia"
        s.veraPortafoglio = false
        guard let fonte = s.fonteVera("giulia"), let p = fonte.posizioni.first(where: { $0.stato == .inEssere && $0.valore > 100 }) else { return }
        let domanda = "Quanto ha Giulia nel \(p.nome.lowercased()) e il riscatto parziale costa qualcosa?"
        let risposta = "Nel \(p.nome.lowercased()) Giulia ha \(Formati.euro(p.valore)). Sul costo del riscatto parziale direi 1.234 €, ma va verificato nelle condizioni."
        var ambiente = AmbienteVera(cliente: fonte.cliente.nome)
        ambiente.modalita = .lavoro
        let piano = NucleoVera.piano(RichiestaVera(domanda: domanda, spunto: nil, fonte: fonte, storia: []), impostazioni: s.dati.impostazioni.vera, ambiente: ambiente)
        s.aggiungiMessaggio(MessaggioVera(autore: .utente, testo: domanda), cliente: "giulia", parla: false)
        var m = MessaggioVera(autore: .vera, testo: risposta, motore: s.qwen.nome)
        m.modalita = .lavoro
        m.fonti = FontiVera.fonti(risposta, fonte: fonte, richiesta: piano.messaggi.last?.testo ?? "")
        s.aggiungiMessaggio(m, cliente: "giulia", parla: false)
        s.apri(.vera)
    }
}
#endif
