import Foundation

// «L'agenda che si organizza» nell'app (Vera/BRIEF.md, funzione 4; template «// 4 · L'AGENDA CHE SI ORGANIZZA»).
// Prima le regole del motore (AgendaOrganizzaVera); Qwen, se è pronto, serve solo a capire una frase che le regole
// lasciano a metà, e la sua risposta passa i controlli di Prisma (giorni solo dalla frase, durata detta, cliente nominato).
// La ricerca degli orari la fa sempre il codice. Niente cambia in agenda né parte verso il cliente senza «Conferma»:
// la bozza con i due orari, l'orario scelto e lo spostamento in blocco sono tutte schede di conferma.
// In modalità cliente: niente spostamenti in blocco (sono l'agenda di tutti) e gli altri impegni restano anonimi.
extension StatoShell {
    // MARK: - Contesto

    /// Il contesto degli strumenti con il calendario dell'agenda (lunedì primo giorno, festività italiane) e `oggi`
    /// da fuori (le istantanee e le prove usano una data fissa).
    func contestoAgendaOrganizza(oggi: Date = Date()) -> ContestoStrumenti {
        var x = contestoStrumenti
        x.oggi = oggi
        x.calendario = MotorePianificazione.calendario
        return x
    }

    /// Qwen si usa solo se è pronto (e non nelle prove con le risposte preparate): le regole bastano quasi sempre.
    private var qwenPerAgendaOrganizza: MotoreLocale? { generativo != nil && !rispostePreparate ? qwen : nil }

    /// L'oggetto della mail per le bozze di questa funzione (nil per gli altri scopi): «Due orari per il nostro
    /// incontro» con gli orari proposti, «Il nostro incontro» per la conferma dell'orario scelto.
    static func oggettoAgendaOrganizza(scopo: String?, orari: String?) -> String? {
        switch scopo {
        case "orari"?:
            let n = (orari ?? "").split(separator: ",").count
            return n == 1 ? "Un orario per il nostro incontro" : "Due orari per il nostro incontro"
        case "conferma_orario"?:
            return "Il nostro incontro"
        default:
            return nil
        }
    }

    @discardableResult
    private func rispostaAgendaOrganizza(_ testo: String, titolo: String? = nil, chiave: String, motore: String? = nil,
                                         _ completa: (inout MessaggioVera) -> Void = { _ in }) -> MessaggioVera {
        var m = MessaggioVera(autore: .vera, testo: testo, titolo: titolo, motore: motore ?? MotoriVera.sintesi.nome)
        completa(&m)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    // MARK: - La frase in chat

    /// «Trovami un'ora per il riesame di Federico entro giovedì, attaccata a un altro incontro in studio»,
    /// «Libera giovedì, sposta tutto a venerdì». true se la frase era per questa funzione.
    func chiediAgendaOrganizza(_ testo: String, chiave: String, oggi: Date = Date()) -> Bool {
        guard let intento = AgendaOrganizzaVera.riconosce(testo) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        if intento == .spostaBlocco, inModoCliente {
            rispostaAgendaOrganizza("In modalità cliente non tocco l'agenda di tutti: lo spostamento in blocco lo fai dopo, fuori dalla modalità cliente.",
                                    titolo: "L'agenda che si organizza", chiave: chiave)
            return true
        }
        let x = contestoAgendaOrganizza(oggi: oggi)
        let regole = AgendaOrganizzaVera.interpreta(testo, contesto: x)
        if let r = regole, AgendaOrganizzaVera.domanda(r, oggi: x.oggi, cal: x.calendario) == nil {
            procediAgendaOrganizza(r, frase: testo, chiave: chiave, contesto: x)
            return true
        }
        // Le regole hanno lasciato la richiesta a metà: Qwen prova a capirla, altrimenti Vera chiede quello che manca
        guard let motore = qwenPerAgendaOrganizza else {
            chiediCosaMancaAgenda(regole, chiave: chiave, contesto: x)
            return true
        }
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let json = try? await motore.scrivi(AgendaOrganizzaVera.messaggi(testo, oggi: x.oggi),
                                                opzioni: AgendaOrganizzaVera.opzioni(self.dati.impostazioni.vera)).testo
            guard !Task.isCancelled else { return }
            self.veraInCorso = false
            self.compitoVera = nil
            // Il contesto è quello del momento della domanda, ma l'agenda si rilegge: può essere cambiata nel frattempo
            var y = self.contestoAgendaOrganizza(oggi: x.oggi)
            y.attivo = x.attivo
            if let q = json.flatMap({ AgendaOrganizzaVera.leggi($0, frase: testo, contesto: y) }),
               q.intento != .spostaBlocco || !self.inModoCliente,
               AgendaOrganizzaVera.domanda(q, oggi: y.oggi, cal: y.calendario) == nil {
                self.procediAgendaOrganizza(q, frase: testo, chiave: chiave, contesto: y)
            } else {
                self.chiediCosaMancaAgenda(regole, chiave: chiave, contesto: y)
            }
        }
        return true
    }

    /// Vera chiede quello che manca («Quale giorno ti libero?», «Quale cliente intendi…?»).
    private func chiediCosaMancaAgenda(_ r: RichiestaOrari?, chiave: String, contesto x: ContestoStrumenti) {
        let domanda = r.flatMap { AgendaOrganizzaVera.domanda($0, oggi: x.oggi, cal: x.calendario) }
            ?? "Non ho capito bene la richiesta sull'agenda: dimmi per chi cerco l'orario ed entro quando, oppure quale giorno libero e dove sposto gli impegni."
        rispostaAgendaOrganizza(domanda, titolo: "L'agenda che si organizza", chiave: chiave)
    }

    /// La richiesta completa: cerca i due orari (con la bozza per il cliente) o prepara lo spostamento in blocco.
    func procediAgendaOrganizza(_ r: RichiestaOrari, frase: String, chiave: String, contesto x: ContestoStrumenti) {
        switch r.intento {
        case .cerca:
            rispondiOrariAgenda(r, frase: frase, chiave: chiave, contesto: x)
        case .spostaBlocco:
            rispondiSpostamentoAgenda(r, frase: frase, chiave: chiave, contesto: x)
        }
    }

    // MARK: - I due orari

    /// In modalità cliente le etichette non nominano gli altri clienti né i loro impegni.
    private func orariPerIlCliente(_ ricerca: RicercaOrari) -> RicercaOrari {
        guard inModoCliente else { return ricerca }
        var r = ricerca
        for i in r.proposte.indices {
            r.proposte[i].etichetta = AgendaOrganizzaGriglia.etichetta(r.proposte[i], inModoCliente: true)
        }
        return r
    }

    @discardableResult
    func rispondiOrariAgenda(_ r: RichiestaOrari, frase: String, chiave: String, contesto x: ContestoStrumenti) -> MessaggioVera {
        let ricerca = orariPerIlCliente(AgendaOrganizzaVera.cerca(r, contesto: x))
        let c = r.clienteId.flatMap { cliente($0) }
        var testo = AgendaOrganizzaVera.risposta(ricerca, oggi: x.oggi, cal: x.calendario)
        // Il canale dell'impegno che si sostituisce decide la firma (Alleanza o indipendente)
        let canale = r.daSpostare.flatMap { id in x.appuntamenti.first { $0.id == id }?.canale }
        let bozza = c.flatMap { AgendaOrganizzaVera.azioneBozza(ricerca, cliente: $0, impostazioni: dati.impostazioni, canale: canale) }
        if !ricerca.proposte.isEmpty {
            if let c {
                let nome = Self.primoNome(c.nome)
                testo += bozza == nil ? "" : " Con «Conferma» preparo la bozza per \(nome) con \(ricerca.proposte.count == 1 ? "l'orario" : "i due orari"): la spedisci tu."
                testo += " Quando \(nome) sceglie, tocca l'orario o dimmi «ha scelto \(Formati.giornoSettimana.string(from: ricerca.proposte[0].inizio))»."
            } else {
                testo += " Per fissarlo dimmi con quale cliente è l'incontro."
            }
        }
        let titolo: String
        if let c, !ricerca.proposte.isEmpty {
            titolo = ricerca.proposte.count == 1 ? "Un orario per \(c.nome)" : "Due orari per \(c.nome)"
        } else {
            titolo = "L'agenda che si organizza"
        }
        let motore = bozza == nil ? (r.conQwen ? qwen.nome : MotoriVera.sintesi.nome) : Self.motoreAzioni
        return rispostaAgendaOrganizza(testo, titolo: titolo, chiave: chiave, motore: motore) { m in
            m.agendaOrari = ricerca
            if let bozza {
                var a = bozza
                a.argomenti["agendaOrari"] = m.id
                m.conferma = self.inStile(SchedaConfermaVera(richiesta: frase, azioni: [a], origine: r.conQwen ? .qwen : .regole))
            }
        }
    }

    /// Il cliente ha scelto un orario (dalla griglia o a parole): una scheda «Conferma» che sposta l'impegno da
    /// sostituire (o ne fissa uno nuovo) e prepara la bozza di conferma per il cliente. Una scelta precedente ancora da
    /// confermare è sostituita.
    @discardableResult
    func scegliOrarioAgenda(messaggio: String, orario: String, oggi: Date = Date()) -> MessaggioVera? {
        guard let m = messaggioVera(messaggio), let ricerca = m.agendaOrari,
              let p = ricerca.proposte.first(where: { $0.id == orario }) else {
            mostraAvviso("Quell'orario non è più tra quelli proposti.")
            return nil
        }
        let chiave = chiaveDelMessaggioAgenda(messaggio) ?? chiaveConversazione
        guard p.inizio > oggi else {
            let quando = DateItaliane.descrivi(p.inizio, conOra: true, oggi: oggi, cal: MotorePianificazione.calendario)
            return rispostaAgendaOrganizza("L'orario di \(quando) è già passato: chiedimi di nuovo un orario.", chiave: chiave)
        }
        guard let id = ricerca.richiesta.clienteId, let c = cliente(id), visibileAlCliente(id) else {
            return rispostaAgendaOrganizza("Con quale cliente fisso l'incontro? Dimmi il nome e rifaccio la ricerca degli orari.", chiave: chiave)
        }
        // Una scelta precedente ancora da confermare lascia il posto a questa
        for v in conversazione(chiave) where v.conferma?.stato == .daConfermare
            && v.conferma?.azioni.contains(where: { $0.argomenti["agendaScelta"] == messaggio }) == true {
            aggiornaSchedaVera(messaggio: v.id) { $0.stato = .sostituita }
        }
        let x = contestoAgendaOrganizza(oggi: oggi)
        // Un orario di questi orari già fissato con «Conferma» (agenda_nuovo_impegno ancora in agenda): la nuova scelta
        // sposta quell'impegno invece di fissarne un secondo
        var r = ricerca.richiesta
        if r.daSpostare == nil, let fissato = impegnoGiaFissatoAgenda(messaggio: messaggio, chiave: chiave) {
            r.daSpostare = fissato
        }
        var scelta = AgendaOrganizzaVera.azioneScelta(p, richiesta: r, cliente: c, contesto: x)
        scelta.argomenti["agendaScelta"] = messaggio
        var azioni = [scelta]
        if let conferma = azioneConfermaOrarioAgenda(p, richiesta: r, cliente: c) {
            azioni.append(conferma)
        }
        aggiornaMessaggioVera(messaggio) { $0.agendaOrariScelto = p.id }
        let nome = Self.primoNome(c.nome)
        let quando = DateItaliane.descrivi(p.inizio, conOra: true, oggi: oggi, cal: x.calendario)
        let dove = p.etichetta.isEmpty ? "" : ", \(p.etichetta)"
        let cosa = r.daSpostare != nil && scelta.strumento == RegistroStrumenti.agendaSposta ? "sposto l'impegno" : "lo metto in agenda"
        return rispostaAgendaOrganizza("\(nome) ha scelto \(quando)\(dove). Con «Conferma» \(cosa) e preparo la conferma per \(nome): la spedisci tu.",
                                       chiave: chiave, motore: Self.motoreAzioni) { v in
            v.conferma = self.inStile(SchedaConfermaVera(richiesta: "\(nome) ha scelto \(quando)", azioni: azioni, origine: .regole))
        }
    }

    /// L'impegno fissato da una scelta precedente di questi orari: l'ultima agenda_nuovo_impegno eseguita (non annullata)
    /// con `agendaScelta` uguale al messaggio degli orari, se l'impegno è ancora in agenda.
    func impegnoGiaFissatoAgenda(messaggio: String, chiave: String) -> String? {
        for v in conversazione(chiave).reversed() {
            guard let azioni = v.conferma?.azioni else { continue }
            for a in azioni.reversed() where a.strumento == RegistroStrumenti.agendaNuovo
                && a.argomenti["agendaScelta"] == messaggio && !a.tolta {
                guard let e = a.esito, e.fatta, !e.annullata, let id = e.oggetto,
                      dati.appuntamenti.contains(where: { $0.id == id }) else { continue }
                return id
            }
        }
        return nil
    }

    /// La bozza di conferma per il cliente dopo la scelta (messaggi_prepara, scopo «conferma_orario», testo di Prisma).
    func azioneConfermaOrarioAgenda(_ p: OrarioProposto, richiesta r: RichiestaOrari, cliente c: Cliente) -> AzioneConferma? {
        let canale = r.daSpostare.flatMap { id in dati.appuntamenti.first { $0.id == id }?.canale }
        let firma = ModelliMessaggi.firma(canale, tono: .formale, impostazioni: dati.impostazioni)
        let testo = Self.testoConfermaOrarioAgenda(p, cliente: c, modo: r.modo, firma: firma)
        let via: CanaleMessaggio = c.telefono.filter(\.isNumber).count >= 6 ? .messaggi : .mail
        var argomenti = ["cliente": c.id, "scopo": "conferma_orario", "testo": testo, "canale": via.rawValue]
        if let id = r.daSpostare { argomenti["appuntamento"] = id }
        return AzioneConferma(strumento: RegistroStrumenti.messaggiPrepara, app: .messaggi, titolo: "Preparo la conferma per \(c.nome)",
                              dettaglio: RegistroStrumenti.dettaglioMessaggio(testo, canale: via), argomenti: argomenti)
    }

    /// «Buongiorno Federico, la ringrazio: ci vediamo martedì 3 novembre alle 11:00 in studio. Un caro saluto, Denis»
    static func testoConfermaOrarioAgenda(_ p: OrarioProposto, cliente c: Cliente, modo: ModoIncontro, firma: String?) -> String {
        let nome = primoNome(c.nome)
        let dove = modo.dove.isEmpty ? "" : " \(modo.dove)"
        let verbo = modo == .telefonata ? "la chiamo" : (modo == .videochiamata ? "ci sentiamo" : "ci vediamo")
        let saluto = firma.map { " Un caro saluto, \($0)" } ?? " Un caro saluto."
        let quando = "\(Formati.dataLunga.string(from: p.inizio)) alle \(Formati.ora.string(from: p.inizio))"
        let detto = modo == .telefonata ? "\(verbo) \(quando)" : "\(verbo) \(quando)\(dove)"
        return "Buongiorno \(nome), la ringrazio: \(detto).\(saluto)"
    }

    /// «Federico ha scelto martedì», «va bene giovedì alle 15», «preferisce il secondo»: la scelta tra gli ultimi
    /// orari proposti in questa conversazione. true se la frase era una scelta.
    func sceltaDettaAgenda(_ testo: String, chiave: String, oggi: Date = Date()) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        guard DateItaliane.cerca(#"\b(?:ha scelto|sceglie|scelgo|preferisce|preferisco|va bene|vanno bene|prendo|prendiamo|meglio|opta per|optiamo per|ok per|fissiamo|confermo)\b"#, t) != nil,
              let m = conversazione(chiave).suffix(8).last(where: { $0.autore == .vera && ($0.agendaOrari?.proposte.isEmpty == false) }),
              let ricerca = m.agendaOrari else { return false }
        // Un altro cliente nominato nella frase: non è la scelta di questi orari
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let nominati = InterpreteComandi.clientiNominati(t, noti)
        if !nominati.isEmpty, !nominati.contains(where: { $0.id == ricerca.richiesta.clienteId }) { return false }
        let cal = MotorePianificazione.calendario
        var candidati = ricerca.proposte
        var detto = false
        var perPosizione = false
        if DateItaliane.cerca(#"\b(?:il primo|la prima|primo orario)\b"#, t) != nil {
            candidati = Array(candidati.prefix(1))
            detto = true
            perPosizione = true
        } else if DateItaliane.cerca(#"\b(?:il secondo|la seconda|secondo orario)\b"#, t) != nil {
            candidati = candidati.count > 1 ? [candidati[1]] : []
            detto = true
            perPosizione = true
        }
        let giorni = AgendaOrganizzaVera.giorniNominati(testo, oggi: oggi, cal: cal)
        if !giorni.isEmpty {
            let perData = candidati.filter { p in giorni.contains { cal.isDate($0, inSameDayAs: p.inizio) } }
            // «Martedì» detto per nome vale per ogni martedì proposto (anche nella seconda settimana, e anche se la
            // risposta arriva giorni dopo la proposta): la data assoluta resta per «il 17», «domani»
            let nomi = Self.giorniSettimanaNominati(t)
            candidati = perData.isEmpty && !nomi.isEmpty
                ? candidati.filter { nomi.contains(cal.component(.weekday, from: $0.inizio)) }
                : perData
            detto = true
        }
        if let ora = DateItaliane.trova(t, oggi: oggi, cal: cal).ora {
            candidati = candidati.filter { AgendaOrganizzaVera.minuti($0.inizio, cal: cal) == ora.ore * 60 + ora.minuti }
            detto = true
        }
        guard detto else { return false }
        // Nessun orario proposto coincide: «Non era tra gli orari proposti» solo per una scelta esplicita («ha scelto»,
        // «preferisce», «il secondo»). «Fissiamo una telefonata venerdì alle 15», «confermo la riunione di giovedì»,
        // «meglio saperlo: cosa ho lunedì?» passano ai comandi e a «Fallo tu», con la loro scheda di conferma
        if candidati.isEmpty, !perPosizione,
           DateItaliane.cerca(#"\b(?:ha scelto|sceglie|scelgo|preferisce|preferisco|opta per|optiamo per)\b"#, t) == nil {
            return false
        }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        guard candidati.count == 1 else {
            let elenco = ricerca.proposte.map { DateItaliane.descrivi($0.inizio, conOra: true, oggi: oggi, cal: cal) }.joined(separator: " oppure ")
            rispostaAgendaOrganizza(candidati.isEmpty ? "Non era tra gli orari proposti: \(elenco). Quale ha scelto?" : "Quale dei due? \(elenco).",
                                    chiave: chiave)
            return true
        }
        scegliOrarioAgenda(messaggio: m.id, orario: candidati[0].id, oggi: oggi)
        return true
    }

    /// I giorni della settimana detti per nome nella frase, come `Calendar.component(.weekday)` (domenica = 1).
    static func giorniSettimanaNominati(_ t: String) -> Set<Int> {
        let nomi: [(String, Int)] = [
            (#"\bdomenica\b"#, 1), (#"\bluned[iì]\b"#, 2), (#"\bmarted[iì]\b"#, 3), (#"\bmercoled[iì]\b"#, 4),
            (#"\bgioved[iì]\b"#, 5), (#"\bvenerd[iì]\b"#, 6), (#"\bsabato\b"#, 7),
        ]
        return Set(nomi.filter { DateItaliane.cerca($0.0, t.lowercased()) != nil }.map(\.1))
    }

    /// La conversazione che contiene un messaggio di Vera.
    private func chiaveDelMessaggioAgenda(_ id: String) -> String? {
        if dati.impostazioni.vera.conservaConversazioni,
           let k = dati.conversazioni.first(where: { voce in voce.value.contains { m in m.id == id } })?.key { return k }
        return conversazioniTemporanee.first(where: { voce in voce.value.contains { m in m.id == id } })?.key
    }

    // MARK: - Lo spostamento in blocco

    @discardableResult
    func rispondiSpostamentoAgenda(_ r: RichiestaOrari, frase: String, chiave: String, contesto x: ContestoStrumenti) -> MessaggioVera {
        guard let s = AgendaOrganizzaVera.spostaBlocco(r, contesto: x) else {
            return rispostaAgendaOrganizza(AgendaOrganizzaVera.domanda(r, oggi: x.oggi, cal: x.calendario) ?? "Quale giorno ti libero, e dove sposto gli impegni?",
                                           titolo: "L'agenda che si organizza", chiave: chiave)
        }
        let azioni = AgendaOrganizzaVera.azioni(s, clienti: dati.clienti, impostazioni: dati.impostazioni, cal: x.calendario)
        let testo = AgendaOrganizzaVera.risposta(s, oggi: x.oggi, cal: x.calendario)
        let titolo = "\(Formati.giornoSettimana.string(from: s.da).capitalized) → \(Formati.giornoSettimana.string(from: s.a))"
        guard !azioni.isEmpty else {
            return rispostaAgendaOrganizza(testo, titolo: "L'agenda che si organizza", chiave: chiave)
        }
        return rispostaAgendaOrganizza(testo, titolo: titolo, chiave: chiave, motore: Self.motoreAzioni) { m in
            m.agendaSpostamento = s
            m.conferma = self.inStile(AgendaOrganizzaVera.scheda(azioni, richiesta: frase, conQwen: r.conQwen))
        }
    }

    // MARK: - Navigazione

    /// «Apri in Agenda»: la settimana del giorno, in Agenda.
    func apriAgendaOrganizza(giorno: Date) {
        giornoAgenda = Calendar.current.startOfDay(for: giorno)
        vistaAgenda = .settimana
        apri(.agenda)
    }
}
