import Foundation

/// Prova della fase 1 di Vera (Vera/BRIEF.md) dentro `Prisma --prova-vera`: la chiamata di strumenti nei corpi e nello
/// streaming di Ollama, il registro degli strumenti, la scheda di conferma (niente cambia prima di «Conferma»,
/// «Annulla» rimette tutto com'era), «Fallo tu» con un Qwen finto che risponde con due chiamate («sposta l'incontro con
/// Laura e avvisala»), i comandi a regole che passano dalla scheda, «Chiedi alla tua clientela» (filtri capiti, stessa
/// risposta della ricerca fatta a mano, a Qwen solo la domanda) e «Mai a caso» (ogni cifra con la sua fonte, «non
/// trovato» per quella inventata).
enum ProvaFalloTu {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        strumentiNelModello(controlla)
        registro(controlla)
        falloTuConQwenFinto(controlla)
        scheda(controlla)
        comandiConConferma(controlla)
        riconoscimento(controlla)
        clientela(controlla)
        clientelaConQwenFinto(controlla)
        fonti(controlla)
        archivio(controlla)
    }

    // MARK: - Aiuti

    private final class Scatola<T>: @unchecked Sendable { var valore: T?; init() {} }

    /// Aspetta una funzione asincrona (le prove girano fuori da un ciclo di eventi).
    private static func aspetta<T>(_ f: @escaping () async -> T?) -> T? {
        let s = Scatola<T>()
        let semaforo = DispatchSemaphore(value: 0)
        Task.detached {
            s.valore = await f()
            semaforo.signal()
        }
        _ = semaforo.wait(timeout: .now() + 20)
        return s.valore
    }

    private static func motoreFinto() -> MotoreLocale {
        let configurazione = URLSessionConfiguration.ephemeral
        configurazione.protocolClasses = [ServerFintoScenari.self]
        return MotoreLocale(ImpostazioniVera(), disponibilita: .pronto, sessione: URLSession(configuration: configurazione))
    }

    private static func iso(_ d: Date) -> String { Formati.formato("yyyy-MM-dd").string(from: d) }

    // MARK: - Pacchetto

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let fallo = IstruzioniVera.testo("fallo-tu") ?? ""
        controlla(fallo.contains("strumenti") && fallo.contains("Conferma") && fallo.contains("messaggi_prepara"),
                  "Fallo tu: istruzioni nel pacchetto (Vera/Istruzioni/fallo-tu.md)")
        let cl = IstruzioniVera.testo("clientela") ?? ""
        controlla(cl.contains("JSON") && cl.contains("liquidita_mesi_minimo") && cl.contains("Non fare conti"),
                  "Clientela: istruzioni nel pacchetto (Vera/Istruzioni/clientela.md)")
        let chat = IstruzioniVera.testo("chat") ?? ""
        controlla(chat.contains("Mai a caso") && chat.contains("pagina"), "Mai a caso: la regola delle fonti nelle istruzioni della chat")
        let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Schemi/clientela.json")
        let file = url.flatMap { try? Data(contentsOf: $0) }.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? NSDictionary }
        controlla(file != nil && file == (ClientelaVera.schemaInterno as NSDictionary),
                  "Clientela: lo schema di Vera/Schemi/clientela.json coincide con quello nel codice")
    }

    // MARK: - Strumenti nel modello

    private static func strumentiNelModello(_ controlla: (Bool, String) -> Void) {
        let o = FalloTuVera.opzioni(ImpostazioniVera(), inModoCliente: false)
        let corpo = FornitoreOllama.corpo(modello: "qwen3.5:4b", messaggi: [MessaggioModello(ruolo: .utente, testo: "x")], opzioni: o)
        let tools = corpo["tools"] as? [[String: Any]] ?? []
        let nomi = Set(tools.compactMap { ($0["function"] as? [String: Any])?["name"] as? String })
        controlla(nomi == Set(RegistroStrumenti.tutti.map(\.nome)) && corpo["format"] == nil && (corpo["options"] as? [String: Any])?["temperature"] as? Double == 0,
                  "Strumenti: a Ollama tutti gli strumenti del registro in «tools», senza «format», temperatura 0 (\(nomi.count))")
        controlla(JSONSerialization.isValidJSONObject(corpo), "Strumenti: il corpo con gli schemi è JSON valido")
        let validi = RegistroStrumenti.tutti.allSatisfy { s in
            let p = s.parametri
            let proprieta = p["properties"] as? [String: Any] ?? [:]
            let richiesti = p["required"] as? [String] ?? []
            return p["type"] as? String == "object" && !s.descrizione.isEmpty && richiesti.allSatisfy { proprieta[$0] != nil }
        }
        controlla(validi, "Strumenti: ogni strumento ha descrizione e schema JSON (i campi richiesti esistono)")
        let cliente = Set(RegistroStrumenti.perModello(inModoCliente: true).map(\.nome))
        controlla(!cliente.contains(RegistroStrumenti.agendaBlocca) && cliente.contains(RegistroStrumenti.agendaSposta),
                  "Strumenti: in modalità cliente restano solo quelli del dossier")
        let app = Set(RegistroStrumenti.tutti.map(\.app))
        controlla([AppPrisma.agenda, .attivita, .note, .clienti, .messaggi, .posizioni, .simulazioni, .pratiche, .studio].allSatisfy(app.contains),
                  "Strumenti: agenda, clienti, pratiche, messaggi, posizioni, studio e simulatore nel registro")
        controlla(RegistroStrumenti.strumento(RegistroStrumenti.praticheApri)?.disponibile == false
                  && RegistroStrumenti.strumento(RegistroStrumenti.studioChilometri)?.disponibile == false,
                  "Strumenti: Pratiche e i chilometri di Studio registrati «in attesa»")

        // La storia con chiamate e risultati, nelle due forme
        let chiamata = ChiamataStrumento(nome: "agenda_sposta_impegno", argomenti: ["cliente": "Laura", "nuovo_giorno": "giovedì"])
        let storia = [MessaggioModello(ruolo: .assistente, testo: "", chiamate: [chiamata]),
                      MessaggioModello(ruolo: .strumento, testo: "{\"fatto\":true}", nomeStrumento: "agenda_sposta_impegno")]
        let ollama = FornitoreOllama.corpo(modello: "m", messaggi: storia, opzioni: OpzioniModello())["messages"] as? [[String: Any]] ?? []
        let argomenti = ((ollama.first?["tool_calls"] as? [[String: Any]])?.first?["function"] as? [String: Any])?["arguments"] as? [String: Any]
        controlla(argomenti?["cliente"] as? String == "Laura" && ollama.last?["role"] as? String == "tool" && ollama.last?["tool_name"] as? String == "agenda_sposta_impegno",
                  "Strumenti: a Ollama la chiamata con gli argomenti come oggetto e il risultato con ruolo «tool»")
        let openAI = FornitoreCompatibileOpenAI.corpo(modello: "m", messaggi: storia, opzioni: OpzioniModello())["messages"] as? [[String: Any]] ?? []
        let comeTesto = ((openAI.first?["tool_calls"] as? [[String: Any]])?.first?["function"] as? [String: Any])?["arguments"] as? String
        controlla(comeTesto?.contains("\"cliente\":\"Laura\"") == true, "Strumenti: al server compatibile OpenAI gli argomenti come stringa JSON")
        controlla(storia[0] == MessaggioModello(ruolo: .assistente, testo: "", chiamate: [chiamata]) && storia[0] != storia[1],
                  "Strumenti: i messaggi con chiamate si confrontano")

        // Lo streaming: argomenti come oggetto o come stringa JSON
        var l = FornitoreOllama.Lettore()
        let riga = #"{"message":{"role":"assistant","content":"","tool_calls":[{"function":{"name":"nota_nuova","arguments":"{\"cliente\":\"Giulia\",\"testo\":\"ok\"}"}}]},"done":false}"#
        let pezzi = (try? l.leggi(riga)) ?? []
        if case .strumento(let c)? = pezzi.first {
            controlla(c.nome == "nota_nuova" && c.argomenti["cliente"] as? String == "Giulia", "Strumenti: argomenti scritti come stringa JSON letti lo stesso")
        } else {
            controlla(false, "Strumenti: argomenti scritti come stringa JSON letti lo stesso")
        }
    }

    // MARK: - Registro

    private static func registro(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "giulia"
        let x = s.contestoStrumenti
        let cal = Calendar.current
        let oggi = x.oggi
        // Cliente dal nome, dal cognome, quello aperto, nessuno
        if case .trovato(let c) = RegistroStrumenti.cliente("Laura", x) { controlla(c.id == "laura", "Registro: «Laura» è Laura Moretti") } else { controlla(false, "Registro: «Laura» è Laura Moretti") }
        if case .trovato(let c) = RegistroStrumenti.cliente(nil, x) { controlla(c.id == "giulia", "Registro: senza nome vale il cliente aperto") } else { controlla(false, "Registro: senza nome vale il cliente aperto") }
        if case .nessuno = RegistroStrumenti.cliente("Topolino", x) { controlla(true, "Registro: un nome che non c'è non diventa un cliente") } else { controlla(false, "Registro: un nome che non c'è non diventa un cliente") }
        // Giorni e ore
        let giovedi = RegistroStrumenti.giorno("giovedì", oggi: oggi)
        controlla(giovedi.map { cal.component(.weekday, from: $0) == 5 && $0 > cal.startOfDay(for: oggi) } == true, "Registro: «giovedì» è il prossimo giovedì")
        controlla(RegistroStrumenti.giorno("2026-12-05", oggi: oggi).map(iso) == "2026-12-05", "Registro: il giorno anche in AAAA-MM-GG")
        controlla(RegistroStrumenti.ora("10:30").map { $0.ore == 10 && $0.minuti == 30 } == true && RegistroStrumenti.ora("15").map { $0.ore == 15 } == true
                  && RegistroStrumenti.ora("alle 3").map { $0.ore == 15 } == true
                  && RegistroStrumenti.ora("alle tre e mezza") != nil, "Registro: l'ora come «10:30», «15» o a parole")

        // Pratiche in attesa: un'attività per Marco (Elena è sua moglie), con l'avviso
        let pratica = RegistroStrumenti.prepara(ChiamataStrumento(nome: RegistroStrumenti.praticheApri, argomenti: ["cliente": "Elena", "tipo": "protezione"]), contesto: x)
        if case .azione(let a) = pratica {
            controlla(a.strumento == RegistroStrumenti.attivitaNuova && a.argomenti["cliente"] == "marco" && a.app == .pratiche && (a.avviso ?? "").contains("non è ancora pronta"),
                      "Registro: «apri una pratica per Elena» diventa un'attività per Marco, con l'avviso che Pratiche non è pronta")
        } else {
            controlla(false, "Registro: «apri una pratica per Elena» diventa un'attività per Marco")
        }
        if case .impossibile(let m) = RegistroStrumenti.prepara(ChiamataStrumento(nome: RegistroStrumenti.studioChilometri, argomenti: ["chilometri": 24]), contesto: x) {
            controlla(m.contains("Studio"), "Registro: i chilometri di Studio non sono ancora registrabili e Vera lo dice")
        } else {
            controlla(false, "Registro: i chilometri di Studio non sono ancora registrabili e Vera lo dice")
        }
        if case .impossibile = RegistroStrumenti.prepara(ChiamataStrumento(nome: "cancella_tutto", argomenti: [:]), contesto: x) {
            controlla(true, "Registro: uno strumento inventato dal modello si scarta")
        } else {
            controlla(false, "Registro: uno strumento inventato dal modello si scarta")
        }
        // Dati mancanti: Vera chiede
        if case .domanda(let d) = RegistroStrumenti.prepara(ChiamataStrumento(nome: RegistroStrumenti.agendaNuovo, argomenti: ["cliente": "Marco"]), contesto: x) {
            controlla(d.hasPrefix("Per quando"), "Registro: un impegno senza giorno, Vera chiede per quando")
        } else {
            controlla(false, "Registro: un impegno senza giorno, Vera chiede per quando")
        }
        // Il numero di telefono si controlla con regole
        if case .impossibile = RegistroStrumenti.prepara(ChiamataStrumento(nome: RegistroStrumenti.clienteAggiorna, argomenti: ["cliente": "Giulia", "campo": "cellulare", "valore": "abc"]), contesto: x) {
            controlla(true, "Registro: un cellulare senza cifre non passa")
        } else {
            controlla(false, "Registro: un cellulare senza cifre non passa")
        }
        // Un messaggio scritto dal modello con una cifra inventata: l'avviso
        let preparate = RegistroStrumenti.prepara([ChiamataStrumento(nome: RegistroStrumenti.messaggiPrepara,
                                                                     argomenti: ["cliente": "Sofia", "scopo": "altro", "testo": "Il suo piano vale 99.999 €."])],
                                                  richiesta: "Scrivi a Sofia del piano", contesto: x)
        if case .azione(let a)? = preparate.first {
            controlla((a.avviso ?? "").contains("99.999"), "Registro: una cifra del messaggio che non viene da Prisma diventa un avviso")
        } else {
            controlla(false, "Registro: una cifra del messaggio che non viene da Prisma diventa un avviso")
        }
    }

    // MARK: - «Fallo tu» con un Qwen finto

    private static func falloTuConQwenFinto(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "giulia"
        guard let laura = s.dati.appuntamenti.first(where: { $0.id == "event-laura" }) else {
            return controlla(false, "Fallo tu: l'incontro di Laura di domani nei dati di prova")
        }
        let cal = Calendar.current
        let nuovoGiorno = cal.date(byAdding: .day, value: 3, to: laura.inizio) ?? laura.inizio
        let ora = Formati.ora.string(from: laura.inizio)
        let richiesta = "Sposta l'incontro con Laura di domani alle \(ora) a \(Formati.dataLunga.string(from: nuovoGiorno)), stessa ora, e avvisala con un messaggio."
        ServerFintoScenari.prepara([ServerFintoScenari.strumenti([
            (RegistroStrumenti.agendaSposta, ["cliente": "Laura", "giorno_attuale": "domani", "ora_attuale": ora, "nuovo_giorno": iso(nuovoGiorno), "nuova_ora": ""]),
            (RegistroStrumenti.messaggiPrepara, ["cliente": "Laura", "scopo": "spostamento", "testo": ""]),
        ])])
        let motore = motoreFinto()
        let contesto = s.contestoStrumenti
        let messaggi = FalloTuVera.messaggi(richiesta, contesto: contesto)
        let opzioni = FalloTuVera.opzioni(ImpostazioniVera(), inModoCliente: false)
        guard let r = aspetta({ try? await motore.chiediConStrumenti(messaggi, opzioni: opzioni) }) else {
            return controlla(false, "Fallo tu, Qwen finto: la risposta con le chiamate")
        }
        let ricevuto = ServerFintoScenari.ultimo
        let utente = ((ricevuto["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        controlla((ricevuto["tools"] as? [Any])?.count == RegistroStrumenti.tutti.count && utente.contains(richiesta) && utente.contains("Laura Moretti"),
                  "Fallo tu, Qwen finto: la richiesta porta gli strumenti, la frase e i nomi dei clienti")
        controlla(r.chiamate.map(\.nome) == [RegistroStrumenti.agendaSposta, RegistroStrumenti.messaggiPrepara] && r.testo.isEmpty,
                  "Fallo tu, Qwen finto: due chiamate lette dallo streaming, un turno di sole chiamate è valido")

        let messaggiPrima = s.dati.messaggi.count
        let m = s.rispondiFalloTu(r, richiesta: richiesta, chiave: "giulia", motore: "Qwen sul Mac")
        guard let scheda = m.conferma else { return controlla(false, "Fallo tu: la scheda di conferma con due azioni") }
        controlla(scheda.azioni.count == 2 && scheda.azioni[0].app == .agenda && scheda.azioni[1].app == .messaggi && m.testo.hasPrefix("Sono due azioni"),
                  "Fallo tu: «sposta l'incontro e avvisala» produce due azioni nella scheda («\(m.testo)»)")
        let testoMessaggio = scheda.azioni[1].argomenti["testo"] ?? ""
        controlla(testoMessaggio.contains("Laura") && testoMessaggio.contains(Formati.dataLunga.string(from: nuovoGiorno)) && testoMessaggio.contains(ora),
                  "Fallo tu: il testo per Laura lo scrive Prisma con il giorno e l'ora dello spostamento («\(testoMessaggio)»)")
        let ferma = s.dati.appuntamenti.first { $0.id == "event-laura" }?.inizio == laura.inizio && s.dati.messaggi.count == messaggiPrima
        controlla(ferma, "Fallo tu: prima di «Conferma» non cambia niente")

        s.confermaSchedaVera(messaggio: m.id)
        let spostato = s.dati.appuntamenti.first { $0.id == "event-laura" }?.inizio
        let atteso = cal.date(bySettingHour: cal.component(.hour, from: laura.inizio), minute: cal.component(.minute, from: laura.inizio), second: 0, of: nuovoGiorno)
        let bozza = s.dati.messaggi.last
        controlla(spostato == atteso && s.dati.messaggi.count == messaggiPrima + 1 && bozza?.stato == .bozza && bozza?.clienteId == "laura" && bozza?.origine.tipo == .richiestaVera,
                  "Fallo tu: dopo «Conferma» l'incontro è spostato e la bozza per Laura è pronta (mai inviata)")
        let dopo = s.messaggioVera(m.id)?.conferma
        controlla(dopo?.stato == .eseguita && dopo?.azioni.allSatisfy { $0.esito?.fatta == true } == true
                  && s.conversazione("giulia").last?.testo.hasPrefix("Fatto") == true,
                  "Fallo tu: la scheda segna le azioni fatte e Vera lo dice")
        s.annullaSchedaVera(messaggio: m.id)
        controlla(s.dati.appuntamenti.first { $0.id == "event-laura" }?.inizio == laura.inizio && s.dati.messaggi.count == messaggiPrima
                  && s.messaggioVera(m.id)?.conferma?.stato == .annullata,
                  "Fallo tu: «Annulla» rimette l'incontro al suo posto e toglie la bozza")

        // Una risposta senza strumenti resta testo; un cliente che non c'è non diventa un'azione
        let soloTesto = s.rispondiFalloTu(RispostaConStrumenti(testo: "Non è un'azione.", chiamate: []), richiesta: "x", chiave: "giulia", motore: "Qwen sul Mac")
        controlla(soloTesto.conferma == nil && soloTesto.testo == "Non è un'azione.", "Fallo tu: senza chiamate la risposta resta una frase")
        let nessuno = s.rispondiFalloTu(RispostaConStrumenti(testo: "", chiamate: [ChiamataStrumento(nome: RegistroStrumenti.notaNuova, argomenti: ["cliente": "Topolino", "testo": "ciao"])]),
                                        richiesta: "x", chiave: "giulia", motore: "Qwen sul Mac")
        controlla(nessuno.conferma == nil && nessuno.testo.contains("Topolino"), "Fallo tu: un cliente inventato non diventa un'azione, Vera lo dice")
    }

    // MARK: - La scheda

    private static func scheda(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "giulia"
        let oggi = Date()
        let venerdi = ClientelaVera.venerdi(oggi)
        func risposta(_ c: [(String, [String: Any])]) -> RispostaConStrumenti {
            RispostaConStrumenti(testo: "", chiamate: c.map { ChiamataStrumento(nome: $0.0, argomenti: $0.1) })
        }
        // Il cellulare di Giulia: il vecchio numero passa nelle note, «Annulla» lo rimette
        let vecchio = s.cliente("giulia")?.telefono ?? ""
        let notaPrima = s.cliente("giulia")?.nota ?? ""
        let m1 = s.rispondiFalloTu(risposta([(RegistroStrumenti.clienteAggiorna, ["cliente": "Giulia", "campo": "telefono", "valore": "347 555 0182"])]),
                                   richiesta: "Il nuovo cellulare di Giulia è 347 555 0182", chiave: "giulia", motore: "Qwen")
        s.confermaSchedaVera(messaggio: m1.id)
        let g = s.cliente("giulia")
        controlla(g?.telefono == "347 555 0182" && (vecchio.isEmpty || g?.nota.contains(vecchio) == true), "Scheda: il cellulare aggiornato, il vecchio nelle note")
        s.annullaSchedaVera(messaggio: m1.id)
        controlla(s.cliente("giulia")?.telefono == vecchio && s.cliente("giulia")?.nota == notaPrima, "Scheda: «Annulla» rimette il numero di prima")

        // «Liberami venerdì pomeriggio»: un blocco «Non disponibile» senza cliente
        let m2 = s.rispondiFalloTu(risposta([(RegistroStrumenti.agendaBlocca, ["giorno": iso(venerdi), "dalle": "14:00", "alle": "19:00"])]),
                                   richiesta: "Liberami venerdì pomeriggio", chiave: "giulia", motore: "Qwen")
        let quanti = s.dati.appuntamenti.count
        s.confermaSchedaVera(messaggio: m2.id)
        let blocco = s.dati.appuntamenti.last
        controlla(s.dati.appuntamenti.count == quanti + 1 && blocco?.tipo == .nonDisponibile && blocco?.clienteId == "" && blocco?.durataMinuti == 300,
                  "Scheda: «liberami venerdì pomeriggio» blocca le 14-19 come «Non disponibile»")

        // La scadenza in Posizioni, con il canale nella riga
        if let p = s.dati.posizioni.first(where: { $0.clienteId == "sofia" && $0.stato == .inEssere }) {
            let prima = p.scadenza
            let m3 = s.rispondiFalloTu(risposta([(RegistroStrumenti.posizioniScadenza, ["cliente": "Sofia", "posizione": p.nome, "scadenza": "2027-01-15"])]),
                                       richiesta: "La \(p.nome) di Sofia scade il 15 gennaio", chiave: "giulia", motore: "Qwen")
            controlla(m3.conferma?.azioni.first?.dettaglio.contains(p.canale.nomeBreve) == true, "Scheda: la riga della posizione dice il canale")
            s.confermaSchedaVera(messaggio: m3.id)
            controlla(s.dati.posizioni.first { $0.id == p.id }?.scadenza.map(iso) == "2027-01-15", "Scheda: la scadenza aggiornata in Posizioni")
            s.annullaSchedaVera(messaggio: m3.id)
            controlla(s.dati.posizioni.first { $0.id == p.id }?.scadenza == prima, "Scheda: «Annulla» rimette la scadenza di prima")
        } else {
            controlla(false, "Scheda: una posizione di Sofia nei dati di prova")
        }

        // ✕ su una riga, «Modifica», «lascia stare», «sì»
        let due = s.rispondiFalloTu(risposta([(RegistroStrumenti.notaNuova, ["cliente": "Giulia", "testo": "uno"]), (RegistroStrumenti.notaNuova, ["cliente": "Giulia", "testo": "due"])]),
                                    richiesta: "Prendi due note", chiave: "giulia", motore: "Qwen")
        let note = s.dati.note.count
        if let a = due.conferma?.azioni.first { s.togliAzioneVera(a.id, messaggio: due.id) }
        s.confermaSchedaVera(messaggio: due.id)
        controlla(s.dati.note.count == note + 1 && s.dati.note.last?.testo == "due", "Scheda: un'azione tolta con ✕ non si esegue")
        let tre = s.rispondiFalloTu(risposta([(RegistroStrumenti.notaNuova, ["cliente": "Giulia", "testo": "tre"])]), richiesta: "Annota tre", chiave: "giulia", motore: "Qwen")
        s.modificaSchedaVera(messaggio: tre.id)
        controlla(s.messaggioVera(tre.id)?.conferma?.stato == .sostituita && s.domandaVera == "Annota tre", "Scheda: «Modifica» rimette la richiesta nel campo")
        s.domandaVera = ""
        _ = s.rispondiFalloTu(risposta([(RegistroStrumenti.notaNuova, ["cliente": "Giulia", "testo": "quattro"])]), richiesta: "Annota quattro", chiave: "giulia", motore: "Qwen")
        let noteQuattro = s.dati.note.count
        controlla(s.rispostaAllaSchedaVera("lascia stare", chiave: "giulia") && s.dati.note.count == noteQuattro, "Scheda: «lascia stare» non esegue niente")
        let cinque = s.rispondiFalloTu(risposta([(RegistroStrumenti.notaNuova, ["cliente": "Giulia", "testo": "cinque"])]), richiesta: "Annota cinque", chiave: "giulia", motore: "Qwen")
        controlla(s.rispostaAllaSchedaVera("Sì", chiave: "giulia") && s.messaggioVera(cinque.id)?.conferma?.stato == .eseguita && s.dati.note.last?.testo == "cinque",
                  "Scheda: «sì» a voce conferma la scheda")

        // Modalità cliente: un'azione su un altro cliente non si esegue
        let altro = s.rispondiFalloTu(risposta([(RegistroStrumenti.notaNuova, ["cliente": "Sofia", "testo": "riservato"])]), richiesta: "Annota per Sofia", chiave: "giulia", motore: "Qwen")
        s.entraModoCliente()
        let noteCliente = s.dati.note.count
        s.confermaSchedaVera(messaggio: altro.id)
        controlla(s.dati.note.count == noteCliente && s.messaggioVera(altro.id)?.conferma?.azioni.first?.esito?.fatta == false,
                  "Scheda: in modalità cliente un'azione su un altro cliente non si esegue")
    }

    // MARK: - I comandi a regole passano dalla scheda

    private static func comandiConConferma(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        s.clienteAttivoId = "giulia"
        let prima = s.dati.appuntamenti.count
        _ = s.eseguiComandoVera("Fissa una telefonata con Marco domani alle 15")
        let m = s.conversazione("giulia").last
        controlla(s.dati.appuntamenti.count == prima && m?.conferma?.azioni.first?.strumento == RegistroStrumenti.agendaNuovo && m?.conferma?.origine == .regole,
                  "Comandi: «fissa una telefonata…» mostra la scheda e non scrive in agenda")
        if let m { s.confermaSchedaVera(messaggio: m.id) }
        let fissato = s.dati.appuntamenti.last
        controlla(s.dati.appuntamenti.count == prima + 1 && fissato?.clienteId == "marco" && fissato?.tipo == .telefonata && fissato?.durataMinuti == 20,
                  "Comandi: dopo «Conferma» la telefonata con Marco è in agenda")
        controlla(!s.eseguiComandoVera("Apri una pratica per la protezione di Elena") && !s.eseguiComandoVera("Apri una pratica per Marco"),
                  "Comandi: «apri una pratica per…» non apre l'app né il dossier, è un'azione per «Fallo tu»")
    }

    // MARK: - Riconoscimento

    private static func riconoscimento(_ controlla: (Bool, String) -> Void) {
        let si = ["Sposta l'incontro con Laura di domani alle 10 a giovedì, stessa ora, e avvisala con un messaggio.",
                  "Liberami venerdì pomeriggio", "Il nuovo cellulare di Giulia è 347 555 0182", "Apri una pratica per la protezione di Elena",
                  "Scrivi a Sofia per il consenso", "La rivalutabile di Sofia scade il 15 gennaio", "Segna 24 chilometri per oggi", "Ok Vera, aggiorna l'email di Marco"]
        let no = ["Quanto ha Giulia nel piano per la casa?", "Cosa ho domani?", "Chi compie 50 anni entro marzo?", "Spiegami il piano pensione",
                  "E se Marco va in pensione a 63 anni?", "Quando scade la polizza di Marco?"]
        let sbagliateSi = si.filter { !FalloTuVera.eUnaRichiesta($0) }
        let sbagliateNo = no.filter { FalloTuVera.eUnaRichiesta($0) }
        controlla(sbagliateSi.isEmpty && sbagliateNo.isEmpty,
                  "Fallo tu: le richieste d'azione riconosciute, le domande restano domande (\((sbagliateSi + sbagliateNo).joined(separator: " | ")))")
        let noti = StatoShell(persistente: false).dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let domande = ["Chi ha più di sei mesi di spese ferme in liquidità e non lo vedo da almeno tre mesi?", "Chi compie 50 anni entro marzo?",
                       "Chi non ha una protezione per il coniuge?", "Chi ha polizze in scadenza entro gennaio?", "Quali clienti non hanno la previdenza?"]
        let nonDomande = ["Chi devo ricontattare?", "Chi è Marco Bianchi?", "Cos'è un PIP?", "Quali riesami devo fare?", "E se chi lavora smette di versare?"]
        let errate = domande.filter { !ClientelaVera.eUnaDomanda($0, clienti: noti) } + nonDomande.filter { ClientelaVera.eUnaDomanda($0, clienti: noti) }
        controlla(errate.isEmpty, "Clientela: le domande su tutti i clienti riconosciute, quelle del portafoglio e su un cliente no (\(errate.joined(separator: " | ")))")
        controlla(!ClientelaVera.eUnaDomanda("Chi è il beneficiario della rivalutabile?", clienti: noti, soloEspliciti: true)
                  && ClientelaVera.eUnaDomanda("Quali clienti non hanno la previdenza?", clienti: noti, soloEspliciti: true),
                  "Clientela: nel dossier «chi è il beneficiario?» resta una domanda sul cliente")
        controlla(!FalloTuVera.eUnaRichiesta("Scrivi un riepilogo della situazione di Giulia per l'incontro"),
                  "Fallo tu: «scrivi un riepilogo…» va alla chat con la scheda, non agli strumenti")
    }

    // MARK: - «Chiedi alla tua clientela»

    private static func dati(_ s: StatoShell, oggi: Date) -> DatiClientela {
        var d = s.datiClientela
        d.oggi = oggi
        return d
    }

    private static func clientela(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.dati = ClientiFittizi.completi()
        let cal = Calendar.current
        let oggi = cal.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 10)) ?? Date()
        // Un cliente che compie 50 anni a dicembre (i dati di prova non ne hanno)
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "laura" }) {
            s.dati.clienti[i].dataNascita = cal.date(from: DateComponents(year: 1976, month: 12, day: 14))
        }
        let d = dati(s, oggi: oggi)

        // Le regole rileggono la frase
        let q1 = "Chi ha più di sei mesi di spese ferme in liquidità e non lo vedo da almeno tre mesi?"
        let f1 = ClientelaVera.correggi([FiltroClientela(.liquiditaMesiMinimo, numero: 12), FiltroClientela(.senzaIncontroDaGiorni)], domanda: q1, oggi: oggi)
        controlla(f1[0].numero == 6 && f1[1].numero == 90, "Clientela: «sei mesi di spese» e «da almeno tre mesi» vincono sui numeri di Qwen")
        let f24 = ClientelaVera.correggi([FiltroClientela(.liquiditaMesiMinimo, numero: 24)], domanda: "Chi ha più di ventiquattro mesi di spese in liquidità?", oggi: oggi)
        controlla(f24[0].numero == 24, "Clientela: «ventiquattro» non diventa «quattro»")
        let q2 = "Chi compie 50 anni entro marzo?"
        let f2 = ClientelaVera.correggi([FiltroClientela(.compieAnniEntro, numero: 50, data: cal.date(from: DateComponents(year: 2027, month: 3, day: 1)))], domanda: q2, oggi: oggi)
        controlla(f2[0].data.map(iso) == "2027-03-31", "Clientela: «entro marzo» è il 31 marzo 2027")
        controlla(ClientelaVera.leggiJSON(#"Ecco: {"capito":true,"filtri":[{"tipo":"polizze_in_scadenza_entro","data":"2027-01-31"},{"tipo":"inventato"}]}"#, oggi: oggi)?.count == 1
                  && ClientelaVera.leggiJSON(#"{"capito":false,"filtri":[]}"#, oggi: oggi)?.isEmpty == true
                  && ClientelaVera.leggiJSON("non è JSON", oggi: oggi) == nil,
                  "Clientela: il JSON di Qwen letto con tolleranza, i filtri inventati scartati")

        // Stesso risultato della ricerca fatta a mano
        let r1 = ClientelaVera.cerca(f1, domanda: q1, dati: d)
        let mano1 = Set(d.clienti.filter { c in
            let liq = d.posizioni.filter { $0.clienteId == c.id && $0.stato == .inEssere && $0.area == .liquidita }.reduce(0) { $0 + $1.valore }
            let spese = d.spese[c.id]?.mensili ?? 0
            let ultimo = (d.appuntamenti.filter { $0.clienteId == c.id && $0.inizio < oggi }.map(\.inizio) + d.incontri.filter { $0.clienteId == c.id && $0.data < oggi }.map(\.data)).max()
            let giorni = ultimo.map { cal.dateComponents([.day], from: cal.startOfDay(for: $0), to: cal.startOfDay(for: oggi)).day ?? 0 } ?? Int.max
            return spese > 0 && liq / spese > 6 && giorni >= 90
        }.map(\.id))
        controlla(Set(r1.righe.map(\.id)) == mano1, "Clientela: liquidità e ultimo incontro, stesso risultato della ricerca a mano (\(r1.righe.count) clienti)")
        controlla(r1.etichette == ["Liquidità oltre 6 mesi di spese", "Ultimo incontro oltre 90 giorni"] && r1.colonne.first == "Cliente" && r1.colonne.last == "Canale",
                  "Clientela: i filtri capiti si vedono come etichette, con le colonne")

        let r2 = ClientelaVera.cerca(f2, domanda: q2, dati: d)
        controlla(r2.righe.map(\.id) == ["laura"] && r2.etichette.contains("Compie 50 anni"), "Clientela: chi compie 50 anni entro marzo (Laura a dicembre)")

        let r3 = ClientelaVera.cerca([FiltroClientela(.coniugeSenzaProtezione)], domanda: "Chi non ha una protezione per il coniuge?", dati: d)
        func coperto(_ f: Familiare, _ c: Cliente) -> Bool {
            for p in d.posizioni where p.clienteId == c.id && p.stato == .inEssere && p.area == .protezione {
                if MotoreProtezioneFamiglia.assicurato(p, cliente: c) == f.id { return true }
            }
            return false
        }
        var mano3: Set<String> = []
        for c in d.clienti {
            for f in c.famiglia where (f.relazione == .coniuge || f.relazione == .convivente) && !coperto(f, c) { mano3.insert(c.id) }
        }
        controlla(Set(r3.righe.map(\.id)) == mano3 && !mano3.isEmpty, "Clientela: coniuge senza protezione, stesso risultato della ricerca a mano (\(mano3.count))")

        let gennaio = cal.date(from: DateComponents(year: 2027, month: 1, day: 31)) ?? oggi
        let r4 = ClientelaVera.cerca([FiltroClientela(.polizzeInScadenzaEntro, data: gennaio)], domanda: "Chi ha polizze in scadenza entro gennaio?", dati: d)
        let mano4 = Set(d.posizioni.filter { p in
            p.stato == .inEssere && p.area == .protezione && (p.scadenza.map { $0 >= cal.startOfDay(for: oggi) && $0 <= gennaio } ?? false)
        }.map(\.clienteId))
        controlla(Set(r4.righe.map(\.id)) == mano4, "Clientela: polizze in scadenza entro gennaio, stesso risultato della ricerca a mano (\(mano4.count))")

        // «Crea N attività» passa dalla scheda
        let m = s.rispondiClientela(f1, domanda: q1, motore: "Qwen sul Mac", oggi: oggi)
        let attivita = s.dati.attivita.count
        controlla(m.clientela?.righe.count == r1.righe.count && m.conferma?.origine == .clientela && m.conferma?.azioni.count == r1.righe.count,
                  "Clientela: la risposta porta la tabella e la scheda «Crea \(r1.righe.count) attività»")
        if let m2 = s.conversazione(VeraPortafoglio.chiave).last, !r1.righe.isEmpty {
            s.confermaSchedaVera(messaggio: m2.id)
            controlla(s.dati.attivita.count == attivita + r1.righe.count, "Clientela: dopo la conferma un'attività per ogni cliente")
        }
        let vuoto = s.rispondiClientela([], domanda: "Chi tifa per la Juventus?", motore: "Qwen", oggi: oggi)
        controlla(vuoto.clientela == nil && vuoto.testo.contains("Non so ancora"), "Clientela: una domanda che i filtri non coprono, Vera lo dice")
        s.entraModoCliente()
        controlla(s.chiediClientela("Chi compie 50 anni entro marzo?") && s.conversazione(s.chiaveConversazione).last?.testo.contains("modalità cliente") == true,
                  "Clientela: in modalità cliente non si cerca tra gli altri clienti")
    }

    private static func clientelaConQwenFinto(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        let oggi = Date()
        let domanda = "Chi non ha una protezione per il coniuge?"
        ServerFintoScenari.prepara([#"{"capito":true,"filtri":[{"tipo":"coniuge_senza_protezione"}]}"#])
        let motore = motoreFinto()
        let messaggi = ClientelaVera.messaggi(domanda, oggi: oggi)
        let opzioni = ClientelaVera.opzioni(ImpostazioniVera())
        let testo = aspetta { try? await motore.scrivi(messaggi, opzioni: opzioni).testo }
        let ricevuto = ServerFintoScenari.ultimo
        let corpo = String(data: (try? JSONSerialization.data(withJSONObject: ricevuto)) ?? Data(), encoding: .utf8) ?? ""
        let nessunNome = !s.dati.clienti.contains { corpo.contains($0.nome) }
        controlla(ricevuto["format"] != nil && corpo.contains("coniuge") && nessunNome,
                  "Clientela, Qwen finto: a Qwen solo la domanda e lo schema, nessun dato dei clienti")
        let filtri = testo.flatMap { ClientelaVera.leggiJSON($0, oggi: oggi) }
        let m = s.rispondiClientela(filtri, domanda: domanda, motore: "Qwen sul Mac")
        controlla(m.clientela?.etichette.first == "Coniuge o convivente in famiglia" && (m.clientela?.righe.contains { $0.id == "marco" } ?? false),
                  "Clientela, Qwen finto: il JSON in streaming diventa la tabella (Marco: Elena senza polizza a suo nome)")
    }

    // MARK: - «Mai a caso»

    private static func fonti(_ controlla: (Bool, String) -> Void) {
        let n = FontiVera.numeri("Ha 20.800 € al 30 ottobre, l'1,5% di rendimento, alle 10:00 del 1° marzo 2028 con qwen3 e 2 polizze.")
        controlla(n.map(\.valore) == [20_800, 1.5, 2] && n[0].unita == .euro && n[1].unita == .percento,
                  "Mai a caso: le cifre lette come valori; orari, date, anni e nomi dei modelli restano fuori")
        controlla(FontiVera.numeri("rende il 3.5% e il codice 12345678901234567890").map(\.valore).first == 3.5,
                  "Mai a caso: «3.5%» con il punto letto come decimale, un numero lunghissimo non fa danni")
        controlla(FontiVera.valore("1.234,56") == 1_234.56 && FontiVera.valore("20800") == 20_800 && FontiVera.valore("−3") == -3,
                  "Mai a caso: «1.234,56», «20800» e «−3» letti giusti")

        let s = StatoShell(persistente: false)
        guard let fonte = s.fonteVera("giulia"), let p = fonte.posizioni.first(where: { $0.stato == .inEssere && $0.valore > 100 }) else {
            return controlla(false, "Mai a caso: una posizione di Giulia nei dati di prova")
        }
        let cifra = Formati.euro(p.valore)
        let risposta = "Nel piano Giulia ha \(cifra). Il riscatto parziale costerebbe 999.999 €. Ha 2 polizze."
        var ambiente = AmbienteVera(cliente: fonte.cliente.nome)
        ambiente.modalita = .lavoro
        let piano = NucleoVera.piano(RichiestaVera(domanda: "Quanto ha Giulia nel piano?", spunto: nil, fonte: fonte, storia: []), impostazioni: ImpostazioniVera(), ambiente: ambiente)
        let f = FontiVera.fonti(risposta, fonte: fonte, richiesta: piano.messaggi.last?.testo ?? "")
        let trovata = f.first { FontiVera.valore(String($0.testo.prefix { $0.isNumber || $0 == "." || $0 == "," })) == p.valore.rounded() }
        // «2 polizze» conta solo se Prisma ha quel numero: le cifre in euro sono due
        controlla(f.filter { $0.testo.contains("€") }.count == 2 && trovata?.trovata == true && trovata?.origine.contains(p.nome) == true,
                  "Mai a caso: la cifra della posizione ha la sua fonte («\(trovata?.origine ?? "-")», \(trovata?.dettaglio ?? "-"))")
        controlla(f.contains { !$0.trovata && $0.testo.contains("999.999") && $0.origine == "Non trovato" },
                  "Mai a caso: la cifra inventata resta «non trovata»")
        let conRimandi = FontiVera.conRimandi(risposta, fonti: f)
        controlla(conRimandi.contains("\(cifra)¹") && conRimandi.contains("999.999 €²") && !conRimandi.contains("polizze¹"),
                  "Mai a caso: nel testo il rimando dopo ogni cifra («\(conRimandi.prefix(60))…»)")
        let blocchi = FontiVera.registro(testo: "QUADRO (calcolato da Prisma)\nPatrimonio 120.000 €\nDOMANDA DEL CONSULENTE\nE con 5.000 € in più?")
        controlla(blocchi.first?.origine == "Calcoli di Prisma · Quadro" && blocchi.last?.origine == FontiVera.origineDomanda,
                  "Mai a caso: le righe della scheda portano il loro blocco, la domanda la sua origine")
        // Un dato letto da un documento porta la pagina
        var documento = Documento(clienteId: "giulia", titolo: "Contratto", tipo: .polizza)
        documento.campi = [CampoEstratto(chiave: .controvalore, valore: "20.800 €", pagina: 4, estratto: "Valore di riscatto 20.800 €")]
        let voce = FontiVera.registro(FonteVera(oggi: Date(), nomeUtente: "", cliente: fonte.cliente, posizioni: [], appuntamenti: [], attivita: [],
                                                analisi: fonte.analisi, analisiSalvata: false, simulazioni: [], documenti: [documento]))
        controlla(voce.contains { $0.origine == "Documento «Contratto» · pagina 4" && $0.valore == 20_800 }, "Mai a caso: un dato del documento cita documento e pagina")
    }

    // MARK: - Archivio

    private static func archivio(_ controlla: (Bool, String) -> Void) {
        var m = MessaggioVera(autore: .vera, testo: "Sono due azioni.")
        var a = AzioneConferma(strumento: RegistroStrumenti.notaNuova, app: .note, titolo: "Prendo nota", dettaglio: "«x»", argomenti: ["cliente": "giulia"])
        a.esito = EsitoAzioneVera(fatta: true, messaggio: "Annotato.", oggetto: "nota-1")
        m.conferma = SchedaConfermaVera(richiesta: "Annota x", azioni: [a], origine: .qwen)
        m.clientela = RisultatoClientela(domanda: "Chi?", filtri: [FiltroClientela(.canale, testo: "alleanza")], etichette: ["Canale Alleanza"],
                                         colonne: ["Cliente", "Canale"], righe: [RigaClientela(id: "giulia", nome: "Giulia Rossi", valori: [], canali: [.alleanza])], totale: 5)
        m.fonti = [FonteCifra(id: 1, testo: "20.800 €", trovata: true, origine: "Posizioni · Piano casa", dettaglio: "valore al 30 ottobre", app: .posizioni)]
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        let letto = (try? e.encode(m)).flatMap { try? d.decode(MessaggioVera.self, from: $0) }
        controlla(letto?.conferma == m.conferma && letto?.clientela == m.clientela && letto?.fonti == m.fonti,
                  "Archivio: scheda, tabella e fonti tornano uguali dal salvataggio")
        let vecchio = #"{"id":"msg-1","autore":"eve","testo":"Ciao","data":"2026-11-01T10:00:00Z","conferma":{"azioni":[{"id":"x"}]}}"#
        let daVecchio = try? d.decode(MessaggioVera.self, from: Data(vecchio.utf8))
        controlla(daVecchio?.testo == "Ciao" && daVecchio?.conferma?.azioni.isEmpty == true && daVecchio?.fonti == nil,
                  "Archivio: un messaggio di prima (o con una scheda guasta) si legge lo stesso")
        let tipo = #"{"id":"e1","clienteId":"","inizio":"2026-11-13T13:00:00Z","tipo":"sconosciuto"}"#
        controlla((try? d.decode(Appuntamento.self, from: Data(tipo.utf8)))?.tipo == .altro, "Archivio: un tipo di impegno sconosciuto torna «altro»")
    }
}
