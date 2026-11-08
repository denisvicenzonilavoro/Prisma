import Foundation

// Vera fa le cose, dopo «Conferma» (Vera/BRIEF.md, fase 1): «Fallo tu» chiede a Qwen gli strumenti del registro e
// mostra la scheda di conferma; «Chiedi alla tua clientela» traduce la domanda in filtri e mostra la tabella; la scheda
// si conferma, si corregge («Modifica»), si accorcia (✕ su una riga) o si annulla dopo l'esecuzione. Ogni messaggio
// si cerca in tutte le conversazioni (non solo in quella aperta): la scheda resta giusta anche cambiando cliente.
extension StatoShell {
    // MARK: - Contesto

    var contestoStrumenti: ContestoStrumenti {
        // In modalità cliente Vera conosce solo il cliente davanti a te: niente nomi né dati degli altri
        let clienti = inModoCliente ? dati.clienti.filter { $0.id == clienteAttivoId } : dati.clienti
        return ContestoStrumenti(oggi: Date(), clienti: clienti, appuntamenti: dati.appuntamenti, posizioni: dati.posizioni,
                          attivo: veraPortafoglio ? nil : clienteAttivoId, impostazioni: dati.impostazioni, inModoCliente: inModoCliente)
    }

    // MARK: - Lo smistamento

    /// Prima il codice: la risposta a una scheda in attesa («sì», «lascia stare»), i comandi a regole, le domande su
    /// tutti i clienti, poi «Fallo tu» con Qwen. true se la frase è stata gestita.
    func smistaVera(_ testo: String, chiave: String) -> Bool {
        if rispostaAllaSchedaVera(testo, chiave: chiave) { return true }
        // «Ricorda che…» (fase 2): si salva subito, con «Annulla»
        if ricordaVera(testo, chiave: chiave) { return true }
        // «Rileggi: …» prima dei comandi: il testo da rileggere può contenere giorni, clienti e appuntamenti
        if chiediSecondaLettura(testo, chiave: chiaveConversazione) { return true }
        if eseguiComandoVera(testo) { return true }
        // Fase 3: promesse, differenze, coperture e resoconto
        if chiediResoconto(testo, chiave: chiaveConversazione) { return true }
        if chiediDifferenze(testo, chiave: chiaveConversazione) { return true }
        if chiediCopertura(testo, chiave: chiaveConversazione) { return true }
        if chiediPromesse(testo, chiave: chiaveConversazione) { return true }
        // «Raccontami Marco» (funzione 6) e le domande sulle norme della biblioteca (funzione 13)
        if chiediTrentaSecondi(testo, chiave: chiaveConversazione) { return true }
        if chiediClientela(testo, nelDossier: chiave != VeraPortafoglio.chiave) { return true }
        if chiediNorme(testo, chiave: chiaveConversazione) { return true }
        return chiediFalloTu(testo, chiave: chiaveConversazione)
    }

    // MARK: - «Fallo tu»

    /// Se la frase è una richiesta d'azione, Qwen sceglie gli strumenti e Vera risponde con la scheda di conferma.
    /// true se l'ha gestita. Se Qwen non è pronto Vera lo dice e non fa niente.
    func chiediFalloTu(_ testo: String, chiave: String) -> Bool {
        guard FalloTuVera.eUnaRichiesta(testo) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        // Il contesto della richiesta (cliente aperto, modalità cliente) vale anche quando arriva la risposta
        let contesto = contestoStrumenti
        conQwen(cliente: chiave) { _ in
            let motore = self.qwen
            let messaggi = FalloTuVera.messaggi(testo, contesto: contesto)
            let opzioni = FalloTuVera.opzioni(self.dati.impostazioni.vera, inModoCliente: contesto.inModoCliente)
            self.veraInCorso = true
            self.compitoVera = Task { @MainActor in
                do {
                    let r = try await motore.chiediConStrumenti(messaggi, opzioni: opzioni)
                    if r.chiamate.isEmpty {
                        // Non era un'azione: la frase torna alla chat, con la scheda e le cifre di Prisma
                        self.togliUltimaDomanda(testo, chiave: chiave)
                        self.veraInCorso = false
                        self.compitoVera = nil
                        if chiave == VeraPortafoglio.chiave { self.chiediVeraPortafoglio(testo, smista: false) } else { self.chiediVera(testo, smista: false) }
                        return
                    }
                    self.rispondiFalloTu(r, richiesta: testo, chiave: chiave, motore: motore.nome, contesto: contesto)
                } catch is CancellationError {
                    // Nuova conversazione: la risposta interrotta non resta
                } catch {
                    self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: error.localizedDescription,
                                                        titolo: "Vera non ha potuto rispondere", motore: motore.nome), cliente: chiave)
                }
                self.veraInCorso = false
                self.compitoVera = nil
            }
        }
        return true
    }

    /// La risposta di Qwen diventa la scheda (o una domanda, o un avviso) nella conversazione.
    @discardableResult
    func rispondiFalloTu(_ r: RispostaConStrumenti, richiesta: String, chiave: String, motore: String, contesto: ContestoStrumenti? = nil) -> MessaggioVera {
        let e = FalloTuVera.esito(r, richiesta: richiesta, contesto: contesto ?? contestoStrumenti)
        var m = MessaggioVera(autore: .vera, testo: e.testo, motore: e.scheda == nil ? motore : Self.motoreAzioni)
        m.conferma = e.scheda
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    /// Toglie la domanda appena aggiunta (quando passa dalla scheda alla chat, che la riaggiunge).
    func togliUltimaDomanda(_ testo: String, chiave: String) {
        var elenco = conversazione(chiave)
        guard let u = elenco.last, u.autore == .utente, u.testo == testo else { return }
        elenco.removeLast()
        if dati.impostazioni.vera.conservaConversazioni { dati.conversazioni[chiave] = elenco } else { conversazioniTemporanee[chiave] = elenco }
    }

    /// La scheda per un comando riconosciuto dalle regole («fissa un incontro con Giulia giovedì alle 15»).
    func schedaDaComando(_ chiamata: ChiamataStrumento, richiesta: String) -> FalloTuVera.Esito {
        FalloTuVera.esito([RegistroStrumenti.prepara(chiamata, contesto: contestoStrumenti)], richiesta: richiesta, origine: .regole)
    }

    /// «Sì», «conferma», «procedi» oppure «no», «lascia stare» subito dopo una scheda: la risposta va alla scheda.
    /// true se la frase era per la scheda.
    func rispostaAllaSchedaVera(_ testo: String, chiave: String) -> Bool {
        guard let m = conversazione(chiave).last, m.autore == .vera, let s = m.conferma, s.stato == .daConfermare else { return false }
        let t = testo.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        if DateItaliane.cerca(#"^(?:s[iì]|conferma|confermo|procedi|vai|fallo|fai pure|va bene(?: fallo)?|ok(?: fallo| procedi| conferma)?|d'accordo)$"#, t) != nil {
            aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
            domandaVera = ""
            confermaSchedaVera(messaggio: m.id)
            return true
        }
        if DateItaliane.cerca(#"^(?:no|annulla|lascia (?:stare|perdere)|niente|non farlo|fermati)$"#, t) != nil {
            aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
            domandaVera = ""
            aggiornaSchedaVera(messaggio: m.id) { $0.stato = .rinunciata }
            ripulisciInArrivo(s)
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "Va bene, lascio stare: non ho fatto niente.", motore: Self.motoreAzioni), cliente: chiave)
            return true
        }
        return false
    }

    // MARK: - La scheda

    /// Trova un messaggio di Vera in qualsiasi conversazione e lo cambia; restituisce la chiave della conversazione.
    @discardableResult
    func aggiornaMessaggioVera(_ id: String, _ cambia: (inout MessaggioVera) -> Void) -> String? {
        if dati.impostazioni.vera.conservaConversazioni {
            for (chiave, elenco) in dati.conversazioni {
                guard let i = elenco.firstIndex(where: { $0.id == id }) else { continue }
                var nuovo = elenco
                cambia(&nuovo[i])
                dati.conversazioni[chiave] = nuovo
                return chiave
            }
        }
        for (chiave, elenco) in conversazioniTemporanee {
            guard let i = elenco.firstIndex(where: { $0.id == id }) else { continue }
            var nuovo = elenco
            cambia(&nuovo[i])
            conversazioniTemporanee[chiave] = nuovo
            return chiave
        }
        return nil
    }

    func messaggioVera(_ id: String) -> MessaggioVera? {
        let tutte = (dati.impostazioni.vera.conservaConversazioni ? Array(dati.conversazioni.values) : []) + Array(conversazioniTemporanee.values)
        for elenco in tutte { if let m = elenco.first(where: { $0.id == id }) { return m } }
        return nil
    }

    @discardableResult
    func aggiornaSchedaVera(messaggio: String, _ cambia: (inout SchedaConfermaVera) -> Void) -> String? {
        aggiornaMessaggioVera(messaggio) { m in
            guard var s = m.conferma else { return }
            cambia(&s)
            m.conferma = s
        }
    }

    /// ✕ su una riga: l'azione esce dalla scheda prima della conferma. Tolte tutte, la scheda è lasciata stare.
    func togliAzioneVera(_ azione: String, messaggio: String) {
        aggiornaSchedaVera(messaggio: messaggio) { s in
            guard s.stato == .daConfermare, let i = s.azioni.firstIndex(where: { $0.id == azione }) else { return }
            s.azioni[i].tolta = true
            if s.attive.isEmpty { s.stato = .rinunciata }
        }
    }

    /// «No, grazie» / «Lascia stare»: la scheda non si esegue.
    func lasciaStareSchedaVera(messaggio: String) {
        aggiornaSchedaVera(messaggio: messaggio) { s in if s.stato == .daConfermare { s.stato = .rinunciata } }
        if let s = messaggioVera(messaggio)?.conferma { ripulisciInArrivo(s) }
    }

    /// I file trascinati che non si archiviano più (scheda lasciata stare o sostituita) escono dalla cartella temporanea.
    func ripulisciInArrivo(_ s: SchedaConfermaVera) {
        guard s.origine == .documento else { return }
        for a in s.azioni {
            if let p = a.argomenti["file"], p.hasPrefix(Self.cartellaInArrivo.path) {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: p).deletingLastPathComponent())
            }
        }
    }

    /// «Modifica»: la richiesta torna nel campo di scrittura, da correggere a parole; la scheda è sostituita.
    func modificaSchedaVera(messaggio: String) {
        guard let s = messaggioVera(messaggio)?.conferma, s.stato == .daConfermare else { return }
        aggiornaSchedaVera(messaggio: messaggio) { $0.stato = .sostituita }
        ripulisciInArrivo(s)
        domandaVera = s.richiesta
        mostraAvviso("Correggi la richiesta a parole: rifaccio la scheda")
    }

    /// «Conferma»: Prisma esegue le azioni della scheda, una per una, e Vera dice com'è andata.
    @discardableResult
    func confermaSchedaVera(messaggio: String) -> [EsitoAzioneVera]? {
        guard let s = messaggioVera(messaggio)?.conferma, s.stato == .daConfermare else { return nil }
        var esiti: [String: EsitoAzioneVera] = [:]
        for a in s.attive { esiti[a.id] = eseguiAzioneVera(a) }
        let chiave = aggiornaSchedaVera(messaggio: messaggio) { s in
            for i in s.azioni.indices { if let e = esiti[s.azioni[i].id] { s.azioni[i].esito = e } }
            s.stato = .eseguita
        }
        let fatte = s.attive.compactMap { esiti[$0.id] }
        let testo: String
        if fatte.count == 1 {
            testo = (fatte[0].fatta ? "Fatto. " : "") + fatte[0].messaggio
        } else {
            testo = (fatte.allSatisfy(\.fatta) ? "Fatto." : "Fatto in parte.") + "\n" + fatte.map { "• \($0.messaggio)" }.joined(separator: "\n")
        }
        aggiungiMessaggio(MessaggioVera(autore: .vera, testo: testo, motore: Self.motoreAzioni), cliente: chiave ?? chiaveConversazione)
        return fatte
    }

    /// «Annulla» dopo l'esecuzione: ogni azione fatta torna com'era (gli spostamenti al giorno di prima).
    func annullaSchedaVera(messaggio: String) {
        guard let s = messaggioVera(messaggio)?.conferma, s.stato == .eseguita else { return }
        let daDisfare = s.attive.filter { $0.esito?.fatta == true && $0.esito?.annullata == false
            && RegistroStrumenti.strumento($0.strumento)?.annullabile != false }
        var annullate: Set<String> = []
        for a in daDisfare.reversed() where disfaAzioneVera(a) { annullate.insert(a.id) }
        guard !annullate.isEmpty else { return mostraAvviso("Non ho potuto annullare: le cose sono già cambiate") }
        let tutte = annullate.count == daDisfare.count
        aggiornaSchedaVera(messaggio: messaggio) { s in
            for i in s.azioni.indices where annullate.contains(s.azioni[i].id) { s.azioni[i].esito?.annullata = true }
            // Annullata in parte: la scheda resta eseguita, con le righe annullate segnate
            if tutte { s.stato = .annullata }
        }
        mostraAvviso(tutte ? "Annullato" : "Annullato in parte: alcune cose erano già cambiate")
    }

    // MARK: - Esecuzione

    private static func json<T: Encodable>(_ v: T) -> String? {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return (try? e.encode(v)).flatMap { String(data: $0, encoding: .utf8) }
    }

    private static func daJSON<T: Decodable>(_ t: T.Type, _ s: String?) -> T? {
        guard let d = s?.data(using: .utf8) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(t, from: d)
    }

    /// Esegue un'azione della scheda. In modalità cliente resta nel dossier del cliente davanti a te.
    func eseguiAzioneVera(_ a: AzioneConferma) -> EsitoAzioneVera {
        let no = { (m: String) in EsitoAzioneVera(fatta: false, messaggio: m) }
        guard !solaLettura else { return no("Prisma è in sola lettura: non ho cambiato niente.") }
        let arg = a.argomenti
        if inModoCliente {
            if let c = arg["cliente"], c != clienteAttivoId { return no("In modalità cliente resto sul dossier di \(clienteAttivo?.nome ?? "questo cliente").") }
            if RegistroStrumenti.strumento(a.strumento)?.nelDossier == false { return no("In modalità cliente non tocco l'agenda di tutti.") }
        }
        let oggi = Date()
        switch a.strumento {
        case RegistroStrumenti.agendaNuovo:
            guard let id = arg["cliente"], let c = cliente(id), let inizio = RegistroStrumenti.daIso(arg["inizio"]) else { return no("Non ho trovato il cliente o l'orario.") }
            var x = Appuntamento.nuovo(clienteId: id, giorno: inizio)
            x.inizio = inizio
            x.tipo = TipoAppuntamento(rawValue: arg["tipo"] ?? "") ?? .altro
            x.titolo = arg["titolo"] ?? RegistroStrumenti.titoloImpegno(x.tipo, cliente: c.nome)
            x.durataMinuti = Int(arg["durata"] ?? "") ?? 60
            x.luogo = arg["luogo"] ?? "In studio"
            x.note = "Fissato con Vera."
            dati.appuntamenti.append(x)
            return EsitoAzioneVera(fatta: true, messaggio: "«\(x.titolo)» è in agenda \(DateItaliane.descrivi(inizio, conOra: true, oggi: oggi)).", oggetto: x.id)

        case RegistroStrumenti.agendaSposta:
            guard let id = arg["appuntamento"], let i = dati.appuntamenti.firstIndex(where: { $0.id == id }),
                  let inizio = RegistroStrumenti.daIso(arg["inizio"]) else { return no("L'impegno da spostare non è più in agenda.") }
            let prima = dati.appuntamenti[i]
            dati.appuntamenti[i].inizio = inizio
            return EsitoAzioneVera(fatta: true, messaggio: "«\(prima.titolo)» è spostato a \(DateItaliane.descrivi(inizio, conOra: true, oggi: oggi)).",
                                   oggetto: id, prima: Self.json(prima))

        case RegistroStrumenti.agendaBlocca:
            guard let inizio = RegistroStrumenti.daIso(arg["inizio"]) else { return no("Non ho capito quale orario bloccare.") }
            let motivo = arg["motivo"] ?? ""
            let x = Appuntamento(id: "event-\(UUID().uuidString.prefix(8).lowercased())", clienteId: "",
                                 titolo: motivo.isEmpty ? "Non disponibile" : "Non disponibile · \(motivo)", inizio: inizio,
                                 durataMinuti: Int(arg["durata"] ?? "") ?? 60, luogo: "", note: "Bloccato con Vera.", stato: .pianificato, tipo: .nonDisponibile)
            dati.appuntamenti.append(x)
            return EsitoAzioneVera(fatta: true, messaggio: "\(DateItaliane.descrivi(inizio, conOra: false, oggi: oggi).prefix(1).uppercased() + DateItaliane.descrivi(inizio, conOra: false, oggi: oggi).dropFirst()) dalle \(Formati.ora.string(from: x.inizio)) alle \(Formati.ora.string(from: x.fine)) sei «Non disponibile».", oggetto: x.id)

        case RegistroStrumenti.attivitaNuova:
            guard let id = arg["cliente"], let c = cliente(id), let titolo = arg["titolo"] else { return no("Non ho trovato il cliente dell'attività.") }
            var t = Attivita.nuova(clienteId: id, scadenza: RegistroStrumenti.daIso(arg["scadenza"]) ?? oggi)
            t.titolo = titolo
            t.note = "Chiesta a Vera."
            dati.attivita.append(t)
            return EsitoAzioneVera(fatta: true, messaggio: "«\(titolo)» è tra le attività di \(c.nome).", oggetto: t.id)

        case RegistroStrumenti.notaNuova:
            guard let id = arg["cliente"], let c = cliente(id), let testo = arg["testo"] else { return no("Non ho trovato il cliente della nota.") }
            let titolo = String(testo.split(separator: " ").prefix(8).joined(separator: " ").prefix(Nota.limiteTitolo))
            let n = Nota(clienteId: id, titolo: titolo, testo: testo)
            dati.note.append(n)
            return EsitoAzioneVera(fatta: true, messaggio: "Annotato nelle note di \(c.nome).", oggetto: n.id)

        case RegistroStrumenti.clienteAggiorna:
            guard let id = arg["cliente"], let i = dati.clienti.firstIndex(where: { $0.id == id }),
                  let campo = arg["campo"], let valore = arg["valore"] else { return no("Non ho trovato la scheda del cliente.") }
            let c = dati.clienti[i]
            let prima = Self.json(["campo": campo, "valore": c.valore(campo), "nota": c.nota])
            var nuovo = c
            switch campo {
            case "telefono":
                if !c.telefono.isEmpty {
                    nuovo.nota = (c.nota.isEmpty ? "" : c.nota + "\n") + "Numero precedente: \(c.telefono)"
                }
                nuovo.telefono = valore
            case "email": nuovo.email = valore
            case "indirizzo": nuovo.indirizzo = valore
            default: nuovo.professione = valore
            }
            dati.clienti[i] = nuovo
            let etichetta = RegistroStrumenti.campiCliente[campo]?.lowercased() ?? campo
            return EsitoAzioneVera(fatta: true, messaggio: "La scheda di \(c.nome) ha il nuovo \(etichetta == "email" ? "indirizzo email" : etichetta).", oggetto: id, prima: prima)

        case RegistroStrumenti.messaggiPrepara:
            guard let id = arg["cliente"], let c = cliente(id), let testo = arg["testo"], !testo.isEmpty else { return no("Non ho il testo del messaggio.") }
            let canale = CanaleMessaggio(rawValue: arg["canale"] ?? "") ?? .messaggi
            let origine = OrigineMessaggio(tipo: .richiestaVera, riferimento: a.id)
            var m = MessaggioCliente(clienteId: id, occasioneId: "\(TipoOccasioneMessaggio.richiestaVera.rawValue)-\(id)-\(a.id)", origine: origine,
                                     canaleLavoro: nil, tono: .formale, canale: canale,
                                     oggetto: canale == .mail ? (arg["scopo"] == "spostamento" ? "Il nostro incontro" : "Un messaggio da \(nomeUtente)") : nil,
                                     testo: testo, cifre: [], autore: .vera, modello: nil)
            m.stato = .bozza
            dati.messaggi.append(m)
            return EsitoAzioneVera(fatta: true, messaggio: "La bozza per \(c.nome) è pronta in Messaggi: la apri e la spedisci tu.", oggetto: m.id)

        case RegistroStrumenti.posizioniScadenza:
            guard let id = arg["posizione"], let i = dati.posizioni.firstIndex(where: { $0.id == id }),
                  let nuova = RegistroStrumenti.daIso(arg["scadenza"]) else { return no("La posizione non è più in Prisma.") }
            let prima = dati.posizioni[i].scadenza.map(RegistroStrumenti.isoData) ?? ""
            dati.posizioni[i].scadenza = nuova
            return EsitoAzioneVera(fatta: true, messaggio: "«\(dati.posizioni[i].nome)» scade il \(Formati.dataEstesa.string(from: nuova)).", oggetto: id, prima: prima)

        case RegistroStrumenti.simulatoreApri:
            if let id = arg["posizione"], let p = dati.posizioni.first(where: { $0.id == id }) {
                simula(p)
            } else {
                if let c = arg["cliente"], !inModoCliente { clienteAttivoId = c }
                apri(.simulazioni)
            }
            return EsitoAzioneVera(fatta: true, messaggio: "Il simulatore è aperto.")

        case RegistroStrumenti.memoriaRicorda:
            guard dati.impostazioni.vera.memoriaAttiva else { return no("La memoria di Vera è spenta (Impostazioni › Vera).") }
            guard let testo = arg["testo"] else { return no("Non c'è niente da ricordare.") }
            if let motivo = MemoriaVera.vietato(testo) { return no(motivo) }
            let gia = Set(memoriaVera.ricordi.map(\.id))
            guard let r = memoriaVera.ricorda(testo, cliente: arg["cliente"], fonte: arg["fonte"] ?? "in chat") else {
                return no(memoriaVera.bloccata ? "La memoria non si apre su questo Mac: sbloccala da Impostazioni › Vera." : "Non l'ho ricordato.")
            }
            // Un ricordo che c'era già: «Annulla» non deve cancellare quello vecchio
            if gia.contains(r.id) { return EsitoAzioneVera(fatta: true, messaggio: "Lo ricordavo già: «\(r.testo)».", oggetto: nil, prima: "gia") }
            return EsitoAzioneVera(fatta: true, messaggio: "Ricordato: «\(r.testo)».", oggetto: r.id)

        case RegistroStrumenti.documentiArchivia:
            return archiviaDocumentoCaduto(a)

        default:
            return no("Questa azione non è ancora disponibile in Prisma.")
        }
    }

    /// Rimette le cose com'erano prima di un'azione; true se ci è riuscito.
    func disfaAzioneVera(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta else { return false }
        switch a.strumento {
        case RegistroStrumenti.agendaNuovo, RegistroStrumenti.agendaBlocca:
            guard let id = e.oggetto, dati.appuntamenti.contains(where: { $0.id == id }) else { return false }
            eliminaAppuntamento(id)
        case RegistroStrumenti.agendaSposta:
            guard let prima = Self.daJSON(Appuntamento.self, e.prima), let i = dati.appuntamenti.firstIndex(where: { $0.id == prima.id }) else { return false }
            dati.appuntamenti[i].inizio = prima.inizio
        case RegistroStrumenti.attivitaNuova:
            guard let id = e.oggetto, dati.attivita.contains(where: { $0.id == id }) else { return false }
            eliminaAttivita(id)
        case RegistroStrumenti.notaNuova:
            guard let id = e.oggetto else { return false }
            dati.note.removeAll { $0.id == id }
        case RegistroStrumenti.messaggiPrepara:
            guard let id = e.oggetto else { return false }
            // Una bozza già aperta in Mail o in Messaggi resta: potrebbe essere partita
            guard let m = dati.messaggi.first(where: { $0.id == id }), m.stato == .bozza else { return false }
            dati.messaggi.removeAll { $0.id == id }
        case RegistroStrumenti.clienteAggiorna:
            guard let id = e.oggetto, let i = dati.clienti.firstIndex(where: { $0.id == id }),
                  let prima = Self.daJSON([String: String].self, e.prima), let campo = prima["campo"] else { return false }
            var c = dati.clienti[i]
            let valore = prima["valore"] ?? ""
            switch campo {
            case "telefono": c.telefono = valore
            case "email": c.email = valore
            case "indirizzo": c.indirizzo = valore
            default: c.professione = valore
            }
            // Si toglie solo la riga aggiunta da Vera: le note scritte dopo restano
            if campo == "telefono", !valore.isEmpty, let r = c.nota.range(of: "Numero precedente: \(valore)", options: .backwards) {
                var da = r.lowerBound
                if da > c.nota.startIndex, c.nota[c.nota.index(before: da)] == "\n" { da = c.nota.index(before: da) }
                c.nota.removeSubrange(da..<r.upperBound)
            }
            dati.clienti[i] = c
        case RegistroStrumenti.posizioniScadenza:
            guard let id = e.oggetto, let i = dati.posizioni.firstIndex(where: { $0.id == id }) else { return false }
            dati.posizioni[i].scadenza = RegistroStrumenti.daIso(e.prima)
        case RegistroStrumenti.memoriaRicorda:
            if e.prima == "gia" { return true }
            guard let id = e.oggetto, memoriaVera.ricordi.contains(where: { $0.id == id }) else { return false }
            memoriaVera.dimentica(id)
        case RegistroStrumenti.documentiArchivia:
            guard let id = e.oggetto, let d = documento(id) else { return false }
            if let u = urlDocumento(d) { try? FileManager.default.removeItem(at: u) }
            if let u = urlTesto(d) { try? FileManager.default.removeItem(at: u) }
            dati.documenti.removeAll { $0.id == id }
        default:
            return false
        }
        return true
    }

    // MARK: - «Chiedi alla tua clientela»

    /// Un cliente della tabella: si apre la sua scheda (in modalità cliente resta quello davanti a te).
    func mostraClienteDaVera(_ id: String) {
        guard !inModoCliente, cliente(id) != nil else { return }
        clienteAttivoId = id
        apri(.clienti)
    }

    var datiClientela: DatiClientela {
        var spese: [String: (mensili: Double, salvata: Bool)] = [:]
        for c in dati.clienti { spese[c.id] = (analisi360(c.id).protezione.fabbisognoMensile, analisiSalvata(c.id)) }
        return DatiClientela(oggi: Date(), clienti: dati.clienti, posizioni: dati.posizioni, appuntamenti: dati.appuntamenti,
                             incontri: dati.incontri, spese: spese)
    }

    /// Una domanda su tutti i clienti: Qwen la traduce in filtri, Prisma cerca. true se l'ha gestita.
    /// La conversazione passa al portafoglio (riguarda tutti i clienti); in modalità cliente non si fa.
    func chiediClientela(_ testo: String, nelDossier: Bool = false) -> Bool {
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        guard ClientelaVera.eUnaDomanda(testo, clienti: noti, soloEspliciti: nelDossier) else { return false }
        if inModoCliente {
            let chiave = chiaveConversazione
            aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
            domandaVera = ""
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "In modalità cliente non cerco tra gli altri clienti: lo faccio quando torni alla tua scrivania.",
                                            motore: Self.motoreAzioni), cliente: chiave)
            return true
        }
        let chiave = VeraPortafoglio.chiave
        veraPortafoglio = true
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        conQwen(cliente: chiave) { _ in
            let motore = self.qwen
            let oggi = Date()
            let messaggi = ClientelaVera.messaggi(testo, oggi: oggi)
            let opzioni = ClientelaVera.opzioni(self.dati.impostazioni.vera)
            self.veraInCorso = true
            self.compitoVera = Task { @MainActor in
                do {
                    let r = try await motore.scrivi(messaggi, opzioni: opzioni)
                    self.rispondiClientela(ClientelaVera.leggiJSON(r.testo, oggi: oggi), domanda: testo, motore: motore.nome)
                } catch is CancellationError {
                } catch {
                    self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: error.localizedDescription,
                                                        titolo: "Vera non ha potuto rispondere", motore: motore.nome), cliente: chiave)
                }
                self.veraInCorso = false
                self.compitoVera = nil
            }
        }
        return true
    }

    /// I filtri capiti (nil se il JSON non era valido) diventano la tabella e la scheda «Crea N attività».
    @discardableResult
    func rispondiClientela(_ filtri: [FiltroClientela]?, domanda: String, motore: String, oggi: Date = Date()) -> MessaggioVera {
        let chiave = VeraPortafoglio.chiave
        let elenco = "liquidità in mesi di spese, ultimo incontro, età e compleanni, protezione del coniuge, scadenze delle polizze, canale, consensi, aree e patrimonio"
        guard let filtri else {
            let m = MessaggioVera(autore: .vera, testo: "Non ho capito la domanda. Posso cercare tra i clienti per \(elenco).", motore: motore)
            aggiungiMessaggio(m, cliente: chiave)
            return m
        }
        guard !filtri.isEmpty else {
            let m = MessaggioVera(autore: .vera, testo: "Non so ancora rispondere a questa domanda su tutti i clienti. Posso cercare per \(elenco).", motore: motore)
            aggiungiMessaggio(m, cliente: chiave)
            return m
        }
        var d = datiClientela
        d.oggi = oggi
        let corretti = ClientelaVera.correggi(filtri, domanda: domanda, oggi: oggi)
        let r = ClientelaVera.cerca(corretti, domanda: domanda, dati: d)
        var m = MessaggioVera(autore: .vera, testo: ([r.frase] + r.note).joined(separator: " "), motore: "Calcoli di Prisma · filtri di \(motore)")
        m.clientela = r
        m.conferma = ClientelaVera.schedaAttivita(r, oggi: oggi)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }
}

extension Cliente {
    /// Il valore di un campo della scheda che Vera può cambiare.
    func valore(_ campo: String) -> String {
        switch campo {
        case "telefono": return telefono
        case "email": return email
        case "indirizzo": return indirizzo
        default: return professione
        }
    }
}
