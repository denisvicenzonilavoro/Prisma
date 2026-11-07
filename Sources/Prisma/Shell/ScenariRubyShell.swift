import Foundation

/// Gli scenari «E se…?» nella conversazione con Ruby (app Ruby, Ruby della scrivania, mini finestra, iPhone e iPad).
/// Qwen estrae i parametri nello schema fisso (ScenariRuby), Prisma calcola il prima/dopo con le ipotesi del cliente
/// (MotoreScenari) e Qwen lo racconta con quelle sole cifre. Su iPhone e iPad Qwen è quello del Mac, attraverso il
/// ponte: al Mac vanno solo le due richieste di testo (estrazione e racconto), la scheda la costruisce il telefono con
/// i suoi dati, come le altre cifre di Ruby. Se Qwen non è pronto Ruby lo dice e non risponde.
extension StatoShell {
    /// Se la frase è uno scenario (o risponde alla domanda di Ruby su uno scenario in sospeso) Ruby lo gestisce qui:
    /// true se l'ha presa. `chiave` è la conversazione: il cliente aperto o il portafoglio (lì solo con un cliente nominato).
    func chiediScenarioRuby(_ testo: String, chiave: String, breve: Bool) -> Bool {
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let portafoglio = chiave == RubyPortafoglio.chiave
        let attivo: String? = portafoglio ? nil : clienteAttivoId
        var sospeso = scenarioInSospeso
        if sospeso != nil {
            if ScenariRuby.rinuncia(testo) {
                scenarioInSospeso = nil
                rispondiScenario(testo, "Va bene, lascio stare lo scenario.", chiave: chiave)
                return true
            }
            // Una frase che apre un altro scenario lo sostituisce
            if ScenariRuby.sembraScenario(testo) { sospeso = nil }
        }
        let regole = ScenariRuby.regole(testo, clienti: noti, attivo: sospeso?.clienteId ?? attivo,
                                       etaPensioneAttuale: { self.etaPensioneScenario($0) })
        if sospeso != nil {
            // Non risponde alla domanda (niente cifre, area o cliente) ed è lunga: è un'altra domanda
            let utile = regole.cambia || regole.area != nil || regole.clienteNominato
            if !utile && testo.split(separator: " ").count > Self.paroleRispostaScenario {
                scenarioInSospeso = nil
                return false
            }
        } else {
            guard ScenariRuby.sembraScenario(testo) else { return false }
            if portafoglio && !regole.clienteNominato { return false }
            // Senza Qwen (istantanee e prove) decidono le regole
            if rispostePreparate && !regole.cambia { return false }
        }
        scenarioInSospeso = nil
        aggiungiMessaggio(MessaggioRuby(autore: .utente, testo: testo), cliente: chiave)
        domandaRuby = ""
        let frase = sospeso.map { $0.frase + "\nRisposta del consulente: " + testo } ?? testo
        let prima = sospeso

        if rispostePreparate {
            var p = prima.map { ScenariRuby.completa($0, con: regole) } ?? regole
            p.frase = frase
            let (domanda, scheda) = preparaScenario(p, chiave: chiave)
            if let domanda { rispondiScenario(nil, domanda, chiave: chiave) }
            if let scheda { aggiungiRispostaScenario(scheda, testo: scheda.racconto, motore: MotoriRuby.sintesi.nome, chiave: chiave) }
            return true
        }

        let base = prima?.clienteId ?? attivo
        let clienteContesto = base.flatMap { cliente($0) }
        let messaggi = ScenariRuby.messaggiEstrazione(frase: frase, attivo: clienteContesto,
                                                     etaPensione: clienteContesto.map { etaPensioneScenario($0.id) }, clienti: noti)
        let opzioni = ScenariRuby.opzioniEstrazione(dati.impostazioni.ruby)
        conQwen(cliente: chiave) { _ in
            let motore = self.qwen
            self.rubyInCorso = true
            self.compitoRuby = Task { @MainActor in
                do {
                    // 1. Qwen legge la frase e risponde con il JSON dello schema
                    let r = try await motore.scrivi(messaggi, opzioni: opzioni)
                    let letto = ScenariRuby.leggiJSON(r.testo, clienti: noti, attivo: base)
                    let perQwen = (letto?.scenario ?? false) && (letto?.parametri.cambia ?? false)
                    if prima == nil && !regole.cambia && !perQwen {
                        // Per Qwen non è uno scenario e le regole non trovano niente: è una domanda come le altre
                        self.rubyInCorso = false
                        self.compitoRuby = nil
                        self.togliUltimaDomanda(chiave: chiave)
                        if portafoglio {
                            self.chiediRubyPortafoglio(testo, breve: breve, scenari: false)
                        } else {
                            self.chiediRuby(testo, breve: breve, scenari: false)
                        }
                        return
                    }
                    var p = ScenariRuby.unisci(modello: letto?.parametri ?? ParametriScenarioRuby(), regole: regole)
                    if let s = prima { p = ScenariRuby.completa(s, con: p) }
                    p.frase = frase
                    // 2. Prisma: la domanda che manca, oppure la scheda prima/dopo
                    let (domanda, scheda) = self.preparaScenario(p, chiave: chiave)
                    if let domanda { self.rispondiScenario(nil, domanda, chiave: chiave) }
                    if let scheda {
                        // 3. Qwen racconta la scheda con le sole cifre di Prisma, mentre la scrive
                        try await self.raccontaScenario(scheda, domanda: testo, chiave: chiave, breve: breve, motore: motore)
                    }
                } catch is CancellationError {
                    // Nuova conversazione: la risposta interrotta non resta
                } catch {
                    self.aggiungiMessaggio(MessaggioRuby(autore: .ruby, testo: error.localizedDescription,
                                                        titolo: "Ruby non ha potuto rispondere", motore: motore.nome), cliente: chiave)
                }
                self.flussoRuby.chiudi()
                self.rubyInCorso = false
                self.compitoRuby = nil
            }
        }
        return true
    }

    /// Una risposta fuori tema a una domanda di Ruby su uno scenario: oltre queste parole è un'altra domanda.
    static let paroleRispostaScenario = 8

    /// L'età di pensione con cui Prisma fa i conti oggi (Analisi 360, mai sotto l'età del cliente).
    func etaPensioneScenario(_ id: String) -> Int {
        let a = analisi360(id).previdenza
        return max(cliente(id)?.eta ?? a.eta, a.etaPensione)
    }

    /// La domanda da fare (e lo scenario resta in sospeso) oppure la scheda calcolata.
    func preparaScenario(_ p: ParametriScenarioRuby, chiave: String) -> (domanda: String?, scheda: SchedaScenarioRuby?) {
        // In modalità cliente gli altri clienti non sono tra quelli visibili (`cliente(_:)` non li trova):
        // il controllo viene prima, altrimenti Ruby chiederebbe «per quale cliente» invece di restare sul dossier
        if inModoCliente, let id = p.clienteId, id != clienteAttivoId {
            return ("In modalità cliente resto sul dossier di \(clienteAttivo?.nome ?? "questo cliente").", nil)
        }
        guard let id = p.clienteId, let c = cliente(id) else {
            scenarioInSospeso = inSospeso(p, "Per quale cliente faccio lo scenario?")
            return ("Per quale cliente faccio lo scenario?", nil)
        }
        if let d = ScenariRuby.domandaMancante(p, cliente: c) {
            scenarioInSospeso = inSospeso(p, d)
            return (d, nil)
        }
        guard let fonte = fonteRuby(id), let scheda = MotoreScenari.calcola(p, fonte: fonte, chiave: chiave) else {
            return ("Non riesco a calcolare lo scenario di \(c.nome): controlla i dati in Analisi 360.", nil)
        }
        return (nil, scheda)
    }

    private func inSospeso(_ p: ParametriScenarioRuby, _ domanda: String) -> ParametriScenarioRuby {
        var s = p
        s.frase = p.frase + "\nRuby ha chiesto: " + domanda
        return s
    }

    /// Il racconto di Qwen in streaming (la bolla in arrivo); se una cifra non è nella scheda di Prisma resta il
    /// racconto di Prisma. La scheda prima/dopo va comunque sotto la risposta.
    @MainActor private func raccontaScenario(_ scheda: SchedaScenarioRuby, domanda: String, chiave: String, breve: Bool, motore: MotoreLocale) async throws {
        var ambiente = ambienteRuby(cliente: scheda.clienteId)
        ambiente.breve = breve
        let messaggi = ScenariRuby.messaggiRacconto(scheda, domanda: domanda, ambiente: ambiente)
        var opzioni = OpzioniModello()
        opzioni.temperatura = 0.3
        opzioni.contesto = NucleoRuby.finestra
        opzioni.restaInMemoria = dati.impostazioni.ruby.restaInMemoria
        let generazione = flussoRuby.inizia(SceltaRuby(modalita: .lavoro, pensa: false), motore: motore.nome)
        let r = try await motore.scrivi(messaggi, opzioni: opzioni) { p in
            DispatchQueue.main.async { self.flussoRuby.aggiorna(p, generazione: generazione) }
        }
        let fedele = CommentoRuby.numeriConservati(bozza: scheda.bozza + "\n" + domanda, testo: r.testo)
        aggiungiRispostaScenario(scheda, testo: fedele ? r.testo : scheda.racconto,
                                 motore: fedele ? motore.nome : MotoriRuby.sintesi.nome, chiave: chiave)
    }

    private func aggiungiRispostaScenario(_ scheda: SchedaScenarioRuby, testo: String, motore: String, chiave: String) {
        var m = MessaggioRuby(autore: .ruby, testo: testo, motore: motore)
        m.modalita = .lavoro
        m.scenario = scheda
        aggiungiMessaggio(m, cliente: chiave)
    }

    /// Una domanda breve di Ruby (o il commiato), con la frase del consulente se non è già nella conversazione.
    private func rispondiScenario(_ domanda: String?, _ risposta: String, chiave: String) {
        if let domanda {
            aggiungiMessaggio(MessaggioRuby(autore: .utente, testo: domanda), cliente: chiave)
            domandaRuby = ""
        }
        var m = MessaggioRuby(autore: .ruby, testo: risposta, motore: StatoShell.motoreAzioni)
        m.modalita = .lavoro
        aggiungiMessaggio(m, cliente: chiave)
    }

    /// Toglie l'ultima domanda del consulente (prima di passarla alla risposta normale, che la rimette).
    private func togliUltimaDomanda(chiave: String) {
        func togli(_ elenco: inout [MessaggioRuby]) {
            if let i = elenco.lastIndex(where: { $0.autore == .utente }), i == elenco.count - 1 { elenco.remove(at: i) }
        }
        if dati.impostazioni.ruby.conservaConversazioni {
            var elenco = dati.conversazioni[chiave] ?? []
            togli(&elenco)
            dati.conversazioni[chiave] = elenco
        } else {
            var elenco = conversazioniTemporanee[chiave] ?? []
            togli(&elenco)
            conversazioniTemporanee[chiave] = elenco
        }
    }

    // MARK: - Dalla scheda: salva o apri

    /// «Salva nel dossier»: lo scenario tra quelli salvati del cliente (Analisi 360 › Scenari); in protezione, dove il
    /// simulatore non c'è, una nota del taccuino con il prima e il dopo.
    func salvaScenarioRuby(_ s: SchedaScenarioRuby, messaggio: String) {
        let nome = cliente(s.clienteId)?.nome ?? s.nomeCliente
        guard !s.salvata else { return mostraAvviso("Lo scenario è già nel dossier di \(nome)") }
        var aggiornata = s
        if var sim = s.simulazione {
            sim.creataIl = Date()
            salvaSimulazione(sim)
            aggiornata.salvataId = sim.id
            mostraAvviso("Scenario salvato nel dossier di \(nome) · " + Self.doveScenari)
        } else {
            let n = Nota(clienteId: s.clienteId, titolo: String(s.titolo.prefix(Nota.limiteTitolo)), testo: s.testoNota)
            dati.note.append(n)
            aggiornata.notaId = n.id
            mostraAvviso("Scenario salvato nelle note di \(nome)")
        }
        aggiornaScenario(aggiornata, messaggio: messaggio)
    }

    #if os(macOS)
    static let doveScenari = "Analisi 360 › Scenari"
    #else
    static let doveScenari = "Simulazioni › Scenari"
    #endif

    /// «Apri in Simulazioni»: il simulatore con i parametri dello scenario; in protezione l'area di Analisi 360.
    func apriScenarioRuby(_ s: SchedaScenarioRuby) {
        if inModoCliente && s.clienteId != clienteAttivoId {
            return mostraAvviso("In modalità cliente resto sul dossier di \(clienteAttivo?.nome ?? "questo cliente")")
        }
        if clienteAttivoId != s.clienteId { clienteAttivoId = s.clienteId }
        if let sim = s.simulazione {
            bozzaSimulazione = sim
            schedaSimulazioni = .simulatore
            apri(.simulazioni)
        } else {
            areaAnalisi = s.area.areaAnalisi
            apri(.analisi360)
        }
    }

    /// La scheda di una risposta di Ruby (per i pulsanti della mini finestra).
    func schedaScenario(messaggio: String, chiave: String) -> SchedaScenarioRuby? {
        conversazione(chiave).first { $0.id == messaggio }?.scenario
    }

    /// Dopo il salvataggio la scheda nella conversazione lo ricorda (il pulsante diventa «Nel dossier»).
    private func aggiornaScenario(_ s: SchedaScenarioRuby, messaggio: String) {
        func aggiorna(_ elenco: inout [MessaggioRuby]) {
            if let i = elenco.firstIndex(where: { $0.id == messaggio }) { elenco[i].scenario = s }
        }
        if dati.impostazioni.ruby.conservaConversazioni {
            var elenco = dati.conversazioni[s.chiave] ?? []
            aggiorna(&elenco)
            dati.conversazioni[s.chiave] = elenco
        } else {
            var elenco = conversazioniTemporanee[s.chiave] ?? []
            aggiorna(&elenco)
            conversazioniTemporanee[s.chiave] = elenco
        }
    }
}
