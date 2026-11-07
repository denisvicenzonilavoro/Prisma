import Foundation

// «Fallo tu» (Vera/BRIEF.md, funzione 1; template «Fallo tu»): una richiesta a parole diventa azioni in qualsiasi app
// di Prisma. Prima il codice: i comandi di sempre («fissa un incontro…», «ricordami…», «prendi nota…») li riconoscono
// le regole di ComandiVera; le altre richieste d'azione («sposta l'incontro con Laura e avvisala», «il nuovo cellulare
// di Giulia è…», «liberami venerdì pomeriggio») le riconosce questo file e le passa a Qwen con gli strumenti del
// registro. Qwen sceglie strumenti e argomenti; Prisma li risolve (RegistroStrumenti) e mostra la scheda di conferma.
// Si esegue solo dopo «Conferma» (Shell/FalloTuShell.swift).

enum FalloTuVera {
    /// Una richiesta d'azione: comincia con un verbo che cambia qualcosa, oppure dice un dato nuovo da segnare.
    /// Le domande («chi…», «quanto…», «cosa…?») restano domande.
    static func eUnaRichiesta(_ testo: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        guard !t.isEmpty else { return false }
        if DateItaliane.cerca(#"^(?:chi|cosa|che cosa|come|quanto|quanti|quante|quando|perch[eé]|qual|quali|dove|posso|puoi dirmi|sai)\b"#, t) != nil { return false }
        // Le richieste di testo o di analisi («scrivi un riepilogo della situazione…») vanno alla chat con la scheda
        if DateItaliane.cerca(#"\b(?:riepilogo|sintesi|resoconto|report|relazione|analisi|spiegazione|panoramica|situazione)\b"#, t) != nil,
           DateItaliane.cerca(#"\b(?:messaggio|mail|e-mail|email|sms|whatsapp)\b"#, t) == nil { return false }
        let verbi = #"^(?:sposta|spostami|spostiamo|anticipa|posticipa|rimanda|rinvia|avvisa|avvisala|avvisalo|avverti|scrivi (?:a|ad|un (?:messaggio|sms|whatsapp)|una (?:mail|e-mail|email)|un'e-mail)|scrivile|scrivigli|manda|mandale|mandagli|invia|prepara (?:un|una|il|la) (?:messaggio|mail|e-mail|bozza|risposta)|aggiorna|cambia|correggi|modifica|segna|segnami|registra|libera|liberami|blocca|bloccami|apri (?:una|la) pratica|annota|imposta|metti (?:la|il) scadenza)\b"#
        if DateItaliane.cerca(verbi, t) != nil { return true }
        if DateItaliane.cerca(#"\b(?:il|la) nuov[oa] (?:cellulare|telefono|numero|indirizzo|email|e-mail|mail|professione) di\b"#, t) != nil { return true }
        if DateItaliane.cerca(#"\bscade (?:il|a|ad|entro)\b"#, t) != nil, !testo.contains("?") { return true }
        if DateItaliane.cerca(#"\be (?:avvisala|avvisalo|avvisali|scrivile|scrivigli|mandale|mandagli)\b"#, t) != nil { return true }
        return false
    }

    static var istruzioni: String {
        IstruzioniVera.testo("fallo-tu") ?? "Sei Vera, l'assistente di Prisma. Il consulente ti chiede di fare qualcosa: rispondi solo chiamando gli strumenti, uno per ogni azione, nell'ordine. Non inventare clienti, giorni, ore o cifre: usa solo la richiesta e il CONTESTO. Il giorno come lo dice il consulente oppure AAAA-MM-GG, l'ora HH:MM. «Avvisala» dopo uno spostamento: messaggi_prepara con scopo spostamento e testo vuoto. Se la richiesta non è un'azione, rispondi con una frase senza strumenti."
    }

    /// Le istruzioni, il contesto (giorno, cliente aperto, nomi dei clienti) e la richiesta.
    static func messaggi(_ richiesta: String, contesto x: ContestoStrumenti) -> [MessaggioModello] {
        let giorno = "\(Formati.dataLunga.string(from: x.oggi)) \(Formati.formato("yyyy").string(from: x.oggi))"
        let iso = Formati.formato("yyyy-MM-dd").string(from: x.oggi)
        var righe = ["Oggi è \(giorno) (\(iso)), ore \(Formati.ora.string(from: x.oggi))"]
        if let id = x.attivo, let c = x.clienti.first(where: { $0.id == id }) { righe.append("cliente aperto: \(c.nome)") }
        let nomi = x.clienti.prefix(ScenariVera.massimoNomi).map(\.nome)
        if !nomi.isEmpty { righe.append("clienti: \(nomi.joined(separator: ", "))") }
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "CONTESTO: " + righe.joined(separator: "; ") + ".\nRICHIESTA: \(richiesta)")]
    }

    static func opzioni(_ vera: ImpostazioniVera, inModoCliente: Bool) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.massimoToken = 500
        o.restaInMemoria = vera.restaInMemoria
        o.strumenti = RegistroStrumenti.perModello(inModoCliente: inModoCliente)
        return o
    }

    /// Cosa Vera risponde da una risposta di Qwen: la scheda con le azioni pronte, oppure una domanda o un avviso.
    struct Esito {
        var scheda: SchedaConfermaVera?
        /// Il testo della bolla: l'intestazione della scheda, le domande per i dati mancanti, gli avvisi.
        var testo: String
    }

    static func esito(_ risposta: RispostaConStrumenti, richiesta: String, contesto x: ContestoStrumenti) -> Esito {
        guard !risposta.chiamate.isEmpty else {
            let t = risposta.testo.trimmingCharacters(in: .whitespacesAndNewlines)
            return Esito(scheda: nil, testo: t.isEmpty ? "Non ho capito cosa fare: prova a dirmelo con il cliente, il giorno e l'azione." : t)
        }
        var chiamate = risposta.chiamate
        // In modalità cliente le azioni che escono dal dossier non si preparano
        if x.inModoCliente {
            chiamate = chiamate.filter { RegistroStrumenti.strumento($0.nome)?.nelDossier ?? false }
        }
        var preparate = RegistroStrumenti.prepara(chiamate, richiesta: richiesta, contesto: x)
        if x.inModoCliente {
            preparate = preparate.map { p in
                if case .azione(let a) = p, let c = a.argomenti["cliente"], c != x.attivo { return .impossibile("In modalità cliente resto sul dossier del cliente davanti a te.") }
                return p
            }
        }
        return esito(preparate, richiesta: richiesta, origine: .qwen)
    }

    /// Le azioni pronte vanno nella scheda; domande e impossibilità diventano il testo della bolla.
    static func esito(_ preparate: [PreparazioneAzione], richiesta: String, origine: SchedaConfermaVera.Origine) -> Esito {
        var azioni: [AzioneConferma] = []
        var domande: [String] = []
        var avvisi: [String] = []
        for p in preparate {
            switch p {
            case .azione(let a): azioni.append(a)
            case .domanda(let d): if !domande.contains(d) { domande.append(d) }
            case .impossibile(let m): if !avvisi.contains(m) { avvisi.append(m) }
            }
        }
        guard !azioni.isEmpty else {
            let t = (avvisi + domande).joined(separator: " ")
            return Esito(scheda: nil, testo: t.isEmpty ? "Non ho capito cosa fare." : t)
        }
        let scheda = SchedaConfermaVera(richiesta: richiesta, azioni: azioni, origine: origine)
        let testo = ([scheda.intestazione] + avvisi + domande).joined(separator: " ")
        return Esito(scheda: scheda, testo: testo)
    }
}
