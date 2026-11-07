import Foundation

/// La prova della schermata del copilota dentro `Prisma --prova-ruby` (ProvaCopilota.swift), senza microfono: i testi
/// del contatore e della durata (§8.5.5 CP12), le parole illuminate della trascrizione, il dialogo di prova delle
/// istantanee (senza consenso niente, con il consenso schede tutte proposte e niente nel dossier), il verbale confermato
/// voce per voce (una voce tolta non entra, la seconda conferma non duplica, la trascrizione non conservata si
/// dimentica) e l'avvio senza consenso, che non accende niente.
enum ProvaVistaCopilota {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        testi(controlla)
        parole(controlla)
        dialogo(controlla)
        verbale(controlla)
        senzaConsenso(controlla)
    }

    private static func testi(_ controlla: (Bool, String) -> Void) {
        let t = TestiCopilota.self
        controlla(t.contatore(9) == "00:09" && t.contatore(600) == "10:00" && t.contatore(3_599) == "59:59"
                  && t.contatore(3_905) == "1:05:05",
                  "Copilota, schermata: il contatore in mm:ss fino a 59:59, poi con le ore (\(t.contatore(9)), \(t.contatore(3_905)))")
        controlla(t.durata(18 * 60) == "18 minuti" && t.durata(60) == "1 minuto" && t.durata(75 * 60) == "1 ora e 15 minuti"
                  && t.durata(120 * 60) == "2 ore" && t.durata(30) == "meno di un minuto",
                  "Copilota, schermata: la durata dell'incontro (\(t.durata(18 * 60)), \(t.durata(75 * 60)))")
        controlla(t.concluso(18 * 60) == "Incontro concluso · 18 minuti",
                  "Copilota, schermata: «\(t.concluso(18 * 60))»")
    }

    private static func parole(_ controlla: (Bool, String) -> Void) {
        let r = DialogoProvaCopilota.righe[1]
        let ev = r.evidenze.compactMap { DialogoProvaCopilota.intervallo($0, in: r.testo) }
        let p = ParolaCopilota.parole(r.testo, evidenze: ev)
        let illuminate = p.filter(\.evidenza).map(\.testo)
        let dopo = p.firstIndex { $0.testo == "tra tre anni" }.flatMap { i in i + 1 < p.count ? p[i + 1] : nil }
        controlla(ev.count == 2 && illuminate == ["tra tre anni", "40.000 euro"],
                  "Copilota, schermata: le parole illuminate restano intere (\(illuminate.joined(separator: " | ")))")
        controlla(dopo?.testo == "," && dopo?.attaccata == true && p.first?.attaccata == false
                  && p.map(\.testo).joined(separator: " ").replacingOccurrences(of: " ,", with: ",")
                      .replacingOccurrences(of: " .", with: ".") == r.testo,
                  "Copilota, schermata: la virgola dopo un'evidenza resta attaccata e il testo si ricompone uguale")
        controlla(ParolaCopilota.parole("", evidenze: [IntervalloTesto(0, 5)]).isEmpty
                  && ParolaCopilota.parole("Sì.", evidenze: [IntervalloTesto(2, 40)]).map(\.testo) == ["Sì", "."],
                  "Copilota, schermata: evidenze fuori dal testo non rompono niente")
    }

    private static func dialogo(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        controlla(DialogoProvaCopilota.prepara(s, righe: 7, consenso: false) == nil && s.dati.sessioniCopilota.isEmpty,
                  "Copilota, dialogo di prova: senza consenso nessuna sessione")
        let attivita = s.dati.attivita.count, eventi = s.dati.eventiVita.count, posizioni = s.dati.posizioni.count
        let sid = DialogoProvaCopilota.prepara(s, righe: 7)
        let sessione = sid.flatMap { s.sessioneCopilota($0) }
        controlla(sessione?.trascrizione.count == 7 && sessione?.schede.count == 6
                  && sessione?.schede.allSatisfy { $0.stato == .proposta } == true,
                  "Copilota, dialogo di prova: 7 righe e 6 schede, tutte proposte")
        controlla(s.dati.attivita.count == attivita && s.dati.eventiVita.count == eventi && s.dati.posizioni.count == posizioni,
                  "Copilota, dialogo di prova: niente nel dossier senza conferma")
        // Ogni scheda illumina parole della sua frase
        let evidenzeOk = sessione?.schede.allSatisfy { x in
            !x.evidenze.isEmpty && x.evidenze.allSatisfy { $0.testo(in: x.frase) != nil }
        } ?? false
        controlla(evidenzeOk, "Copilota, dialogo di prova: le evidenze delle schede sono dentro le loro frasi")
    }

    private static func verbale(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        guard let sid = DialogoProvaCopilota.prepara(s, righe: 7), let sessione = s.sessioneCopilota(sid) else {
            controlla(false, "Copilota, verbale: dialogo di prova non preparato")
            return
        }
        let c = StatoCopilotaIncontro()
        controlla(c.scelte(sessione).count == 6, "Copilota, verbale: di base tutte le voci proposte sono scelte")
        c.alterna("evento-matrimonio", in: sessione)
        controlla(!c.scelte(sessione).contains("evento-matrimonio") && c.scelte(sessione).count == 5,
                  "Copilota, verbale: un clic toglie la voce dalla conferma")
        let eventi = s.dati.eventiVita.count, attivita = s.dati.attivita.count
        c.confermaVerbale(s, sessione: sessione)
        let dopo = s.sessioneCopilota(sid)
        controlla(s.dati.eventiVita.count == eventi && s.dati.attivita.count == attivita + 2
                  && dopo?.scheda("evento-matrimonio")?.stato == .proposta
                  && dopo?.schede.filter { $0.stato == .confermata }.count == 5,
                  "Copilota, verbale: entrano solo le voci scelte (5), il matrimonio tolto resta da confermare")
        controlla(dopo?.aperta == false && dopo?.trascrizione.isEmpty == true && dopo?.verbale?.confermatoIl != nil
                  && dopo?.schede.allSatisfy { $0.frase.isEmpty } == true,
                  "Copilota, verbale: senza «Conserva la trascrizione» la sessione si chiude con il verbale e il testo si dimentica")
        let obiettivi = s.dati.obiettivi.count, posizioni = s.dati.posizioni.count, note = s.dati.note.count
        if let d = dopo { c.confermaVerbale(s, sessione: d) }
        controlla(s.dati.obiettivi.count == obiettivi && s.dati.posizioni.count == posizioni && s.dati.note.count == note
                  && s.dati.attivita.count == attivita + 2 && s.dati.eventiVita.count == eventi + 1,
                  "Copilota, verbale: la seconda conferma porta solo la voce rimasta, senza duplicare niente")
    }

    private static func senzaConsenso(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        let c = StatoCopilotaIncontro()
        c.avvia(s, clienteId: "marco", incontroId: nil)
        controlla(c.fase == .pronto && !c.ascolta && c.sessioneId == nil && c.problema == GuardiaCopilota.senzaConsenso("Marco Bianchi")
                  && s.dati.sessioniCopilota.isEmpty,
                  "Copilota, schermata: senza consenso «Avvia» non accende il microfono e dice perché")
    }
}
