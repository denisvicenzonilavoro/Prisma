import Foundation

/// «Ragiona a passi» collegato all'app (CollegaPassiShell.swift): la frase del template in chat dà il messaggio di Vera
/// con il piano eseguito e la scheda «Conferma» (niente scritto prima); una domanda qualsiasi non passa di qui; spento in
/// Impostazioni la frase va alla chat normale; senza cliente nel portafoglio Vera chiede di chi si parla.
enum ProvaCollegaPassi {
    static let frase = "Marco ha 400 € al mese: vuole proteggere Elena e continuare con gli studi di Tommaso. Come li divido?"

    static func esegui(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        s.veraPortafoglio = false
        s.clienteAttivoId = "marco"
        let note = s.dati.note.count
        let attivita = s.dati.attivita.count
        controlla(s.chiediPassi(frase, chiave: "marco"), "Ragiona a passi in chat: la frase del template va al ragionamento a passi")
        let m = s.conversazione("marco").last
        controlla(m?.autore == .vera && m?.titolo == StatoShell.titoloPassi && m?.pianoPassi?.consigliata != nil
                  && m?.pianoPassi?.passi.allSatisfy { $0.stato == .fatto } == true,
                  "Ragiona a passi in chat: il messaggio di Vera ha il piano eseguito e la scelta")
        controlla(m?.testo.hasPrefix(m?.pianoPassi?.spiegazione ?? "§") == true, "Ragiona a passi in chat: il testo della risposta è la spiegazione")
        controlla(m?.conferma?.stato == .daConfermare && m?.conferma?.azioni.first?.strumento == RegistroStrumenti.notaNuova
                  && s.dati.note.count == note && s.dati.attivita.count == attivita,
                  "Ragiona a passi in chat: la nota e il rinnovo aspettano «Conferma», niente è stato scritto")
        let prima = s.conversazione("marco").count
        controlla(!s.chiediPassi("Che tempo fa domani?", chiave: "marco") && s.conversazione("marco").count == prima,
                  "Ragiona a passi in chat: una domanda qualsiasi non passa di qui")
        s.dati.impostazioni.vera.passi.attivo = false
        controlla(!s.chiediPassi(frase, chiave: "marco") && s.conversazione("marco").count == prima,
                  "Ragiona a passi in chat: spento in Impostazioni, la frase va alla chat normale")
        s.dati.impostazioni.vera.passi.attivo = true
        s.veraPortafoglio = true
        controlla(s.chiediPassi("Ha 400 € al mese: vuole proteggere la famiglia e gli studi. Come li divido?", chiave: VeraPortafoglio.chiave)
                  && s.conversazione(VeraPortafoglio.chiave).last?.pianoPassi == nil
                  && s.conversazione(VeraPortafoglio.chiave).last?.testo.hasPrefix("Di quale cliente") == true,
                  "Ragiona a passi in chat: nel portafoglio senza un nome Vera chiede di quale cliente, non sceglie a caso")
        s.veraPortafoglio = false
        let rifatto = s.conversazione("marco").count
        if let p = m?.pianoPassi { s.rifaiPassi(p, chiave: "marco") }
        controlla(s.conversazione("marco").count == rifatto + 1 && s.conversazione("marco").last?.pianoPassi?.richiesta.budgetMensile == 400,
                  "Ragiona a passi: «Rifai i calcoli» ripete la richiesta con i dati di adesso")
    }
}
