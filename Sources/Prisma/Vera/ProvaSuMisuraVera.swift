import Foundation

/// Prova di «Vera su misura» (Vera/BRIEF.md, fase 5, funzione 22) dentro `Prisma --prova-vera`: anonimizzazione e
/// residui sui clienti di prova, raccolta e divisione degli esempi, pacchetto di addestramento (nessun dato dei clienti
/// in nessun byte, nessun esempio d'esame), risorse dell'addestramento, importazione in Ollama ed esame con un server
/// finto dentro il processo (niente rete, niente modello), sostituzione e ritorno alla versione di prima, frasi in chat.
enum ProvaSuMisuraVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let dati = StatoShell(persistente: false).dati.istantanea
        anonimizzazione(dati, controlla)
    }

    /// Domenica 8 novembre 2026, 10:00: sempre lo stesso giorno.
    static let oggi: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 11
        c.day = 8
        c.hour = 10
        return Calendar(identifier: .gregorian).date(from: c) ?? Date(timeIntervalSince1970: 1_794_128_400)
    }()

    // MARK: - 1. Anonimizzazione

    private static func anonimizzazione(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        let id = IdentificativiClienti(clienti: dati.clienti, consulente: dati.impostazioni.nomeUtente)
        let frase = AnonimizzatoreVera.anonimizza("Giulia Rossi, 37 anni, via Manzoni 12, Monza, versa 550 € al mese", identificativi: id)
        controlla(frase.testo == "[Cliente], 37 anni, [Indirizzo], versa 550 € al mese",
                  "Su misura: nome e indirizzo diventano segnaposto, l'importo resta (\(frase.testo))")
        controlla(frase.sostituzioni.contains(Sostituzione(originale: "Giulia Rossi", segnaposto: AnonimizzatoreVera.cliente)),
                  "Su misura: la sostituzione è registrata per l'anteprima")
        let soloNome = AnonimizzatoreVera.anonimizza("Ciao giulia, come va con la casa?", identificativi: id).testo
        controlla(soloNome == "Ciao [Cliente], come va con la casa?", "Su misura: il nome da solo, anche minuscolo, diventa [Cliente]")
        if let marco = dati.clienti.first(where: { $0.id == "marco" }), let f = marco.famiglia.first {
            let primo = f.nome.split(separator: " ").first.map(String.init) ?? f.nome
            let t = AnonimizzatoreVera.anonimizza("Ne parlo con \(primo) domani.", identificativi: id).testo
            controlla(t == "Ne parlo con [Familiare] domani.", "Su misura: il nome di un familiare diventa [Familiare] (\(t))")
        } else {
            controlla(false, "Su misura: Marco ha un familiare nei dati di prova")
        }
        let documenti = AnonimizzatoreVera.anonimizza("CF RSSGLI87L42A944X, conto IT60 X054 2811 1010 0000 0123 456, mail anna.verdi@example.org, cellulare +39 333 1234567, polizza 1234567890",
                                                      identificativi: id).testo
        let attesi = [AnonimizzatoreVera.codiceFiscale, AnonimizzatoreVera.iban, AnonimizzatoreVera.email, AnonimizzatoreVera.telefono, AnonimizzatoreVera.numero]
        controlla(attesi.allSatisfy { documenti.contains($0) } && documenti.filter(\.isNumber).isEmpty,
                  "Su misura: codice fiscale, IBAN, email, telefono e numero di polizza diventano segnaposto (\(documenti))")
        let consulente = AnonimizzatoreVera.anonimizza("A presto, \(dati.impostazioni.nomeUtente)", identificativi: id).testo
        controlla(consulente == "A presto, \(AnonimizzatoreVera.consulente)", "Su misura: anche il nome del consulente non esce")
        let data = AnonimizzatoreVera.anonimizza("Ci vediamo il 2026-11-12 alle 15.", identificativi: id).testo
        controlla(data == "Ci vediamo il 2026-11-12 alle 15.", "Su misura: una data non diventa un numero di documento")

        // Nessun residuo per i 5 clienti del template e i clienti fittizi
        let tutti = ClientiFittizi.completi()
        let idTutti = IdentificativiClienti(clienti: tutti.clienti, consulente: tutti.impostazioni.nomeUtente)
        var sporchi: [String] = []
        for c in tutti.clienti {
            var testo = "\(c.nome) (\(c.email), \(c.telefono)) abita in \(c.indirizzo)."
            if let f = c.famiglia.first { testo += " Con lei c'è \(f.nome)." }
            if let a = c.elencoAziende.first { testo += " Lavora in \(a.ragioneSociale)." }
            let anonimo = AnonimizzatoreVera.anonimizza(testo, identificativi: idTutti).testo
            let r = AnonimizzatoreVera.residui(anonimo, identificativi: idTutti)
            if !r.isEmpty { sporchi.append("\(c.nome): \(r.joined(separator: ", "))") }
        }
        controlla(sporchi.isEmpty && tutti.clienti.count >= 35,
                  "Su misura: nessun residuo per i \(tutti.clienti.count) clienti di prova" + (sporchi.isEmpty ? "" : " (\(sporchi.prefix(3).joined(separator: " | ")))"))
        controlla(!AnonimizzatoreVera.residui("Ne ho parlato con Giulia Rossi", identificativi: id).isEmpty,
                  "Su misura: un nome rimasto è un residuo")
        let guardare = AnonimizzatoreVera.anonimizza(EsempioVera(domanda: "Ho visto Carla Neri ieri", risposta: "Bene."), identificativi: id)
        controlla(guardare.daGuardare == ["Carla Neri"], "Su misura: un nome che l'archivio non conosce è «da guardare» (\(guardare.daGuardare))")
        controlla(guardare.modalita == .lavoro, "Su misura: un esempio di prima, senza modalità, vale come lavoro")
    }
}
