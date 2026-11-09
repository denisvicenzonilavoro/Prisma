import Foundation

/// Gli scenari «E se…?» nella conversazione con Vera (app Vera, Vera della scrivania, mini finestra, iPhone e iPad).
/// Qwen estrae i parametri nello schema fisso (ScenariVera), Prisma calcola il prima/dopo con le ipotesi del cliente
/// (MotoreScenari) e Qwen lo racconta con quelle sole cifre. Su iPhone e iPad Qwen è quello del Mac, attraverso il
/// ponte: al Mac vanno solo le due richieste di testo (estrazione e racconto), la scheda la costruisce il telefono con
/// i suoi dati, come le altre cifre di Vera. Se Qwen non è pronto Vera lo dice e non risponde.
extension StatoShell {
    /// Se la frase è uno scenario (o risponde alla domanda di Vera su uno scenario in sospeso) Vera lo gestisce qui:
    /// true se l'ha presa. `chiave` è la conversazione: il cliente aperto o il portafoglio (lì solo con un cliente nominato).
    func chiediScenarioVera(_ testo: String, chiave: String, breve: Bool) -> Bool {
        let noti = clientiAttivi.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let portafoglio = chiave == VeraPortafoglio.chiave
        let attivo: String? = portafoglio ? nil : clienteAttivoId
        var sospeso = scenarioInSospeso
        if sospeso != nil {
            if ScenariVera.rinuncia(testo) {
                scenarioInSospeso = nil
                rispondiScenario(testo, "Va bene, lascio stare lo scenario.", chiave: chiave)
                return true
            }
            // Una frase che apre un altro scenario lo sostituisce
            if ScenariVera.sembraScenario(testo) { sospeso = nil }
        }
        let regole = ScenariVera.regole(testo, clienti: noti, attivo: sospeso?.clienteId ?? attivo,
                                       etaPensioneAttuale: { self.etaPensioneScenario($0) })
        if sospeso != nil {
            // Non risponde alla domanda (niente cifre, area o cliente) ed è lunga: è un'altra domanda
            let utile = regole.cambia || regole.area != nil || regole.clienteNominato
            if !utile && testo.split(separator: " ").count > Self.paroleRispostaScenario {
                scenarioInSospeso = nil
                return false
            }
        } else {
            guard ScenariVera.sembraScenario(testo) else { return false }
            if portafoglio && !regole.clienteNominato { return false }
            // Senza Qwen (istantanee e prove) decidono le regole
            if rispostePreparate && !regole.cambia { return false }
        }
        scenarioInSospeso = nil
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        let frase = sospeso.map { $0.frase + "\nRisposta del consulente: " + testo } ?? testo
        let prima = sospeso

        if rispostePreparate {
            var p = prima.map { ScenariVera.completa($0, con: regole) } ?? regole
            p.frase = frase
            let (domanda, scheda) = preparaScenario(p, chiave: chiave)
            if let domanda { rispondiScenario(nil, domanda, chiave: chiave) }
            if let scheda { aggiungiRispostaScenario(scheda, testo: scheda.racconto, motore: MotoriVera.sintesi.nome, chiave: chiave) }
            return true
        }

        let base = prima?.clienteId ?? attivo
        let clienteContesto = base.flatMap { cliente($0) }
        let messaggi = ScenariVera.messaggiEstrazione(frase: frase, attivo: clienteContesto,
                                                     etaPensione: clienteContesto.map { etaPensioneScenario($0.id) }, clienti: noti)
        let opzioni = ScenariVera.opzioniEstrazione(dati.impostazioni.vera)
        conQwen(cliente: chiave) { _ in
            let motore = self.qwen
            self.veraInCorso = true
            self.compitoVera = Task { @MainActor in
                do {
                    // 1. Qwen legge la frase e risponde con il JSON dello schema
                    let r = try await motore.scrivi(messaggi, opzioni: opzioni)
                    let letto = ScenariVera.leggiJSON(r.testo, clienti: noti, attivo: base)
                    let perQwen = (letto?.scenario ?? false) && (letto?.parametri.cambia ?? false)
                    if prima == nil && !regole.cambia && !perQwen {
                        // Per Qwen non è uno scenario e le regole non trovano niente: è una domanda come le altre
                        self.veraInCorso = false
                        self.compitoVera = nil
                        self.togliUltimaDomanda(chiave: chiave)
                        if portafoglio {
                            self.chiediVeraPortafoglio(testo, breve: breve, scenari: false)
                        } else {
                            self.chiediVera(testo, breve: breve, scenari: false)
                        }
                        return
                    }
                    var p = ScenariVera.unisci(modello: letto?.parametri ?? ParametriScenarioVera(), regole: regole)
                    if let s = prima { p = ScenariVera.completa(s, con: p) }
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
                    self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: error.localizedDescription,
                                                        titolo: "Vera non ha potuto rispondere", motore: motore.nome), cliente: chiave)
                }
                self.flussoVera.chiudi()
                self.veraInCorso = false
                self.compitoVera = nil
            }
        }
        return true
    }

    /// Una risposta fuori tema a una domanda di Vera su uno scenario: oltre queste parole è un'altra domanda.
    static let paroleRispostaScenario = 8

    /// L'età di pensione con cui Prisma fa i conti oggi (Analisi 360, mai sotto l'età del cliente).
    func etaPensioneScenario(_ id: String) -> Int {
        let a = analisi360(id).previdenza
        return max(cliente(id)?.eta ?? a.eta, a.etaPensione)
    }

    /// La domanda da fare (e lo scenario resta in sospeso) oppure la scheda calcolata.
    func preparaScenario(_ p: ParametriScenarioVera, chiave: String) -> (domanda: String?, scheda: SchedaScenarioVera?) {
        // In modalità cliente gli altri clienti non sono tra quelli visibili (`cliente(_:)` non li trova):
        // il controllo viene prima, altrimenti Vera chiederebbe «per quale cliente» invece di restare sul dossier
        if inModoCliente, let id = p.clienteId, id != clienteAttivoId {
            return ("In modalità cliente resto sul dossier di \(clienteAttivo?.nome ?? "questo cliente").", nil)
        }
        guard let id = p.clienteId, let c = cliente(id) else {
            scenarioInSospeso = inSospeso(p, "Per quale cliente faccio lo scenario?")
            return ("Per quale cliente faccio lo scenario?", nil)
        }
        if let d = ScenariVera.domandaMancante(p, cliente: c) {
            scenarioInSospeso = inSospeso(p, d)
            return (d, nil)
        }
        guard let fonte = fonteVera(id), let scheda = MotoreScenari.calcola(p, fonte: fonte, chiave: chiave) else {
            return ("Non riesco a calcolare lo scenario di \(c.nome): controlla i dati in Analisi 360.", nil)
        }
        return (nil, scheda)
    }

    private func inSospeso(_ p: ParametriScenarioVera, _ domanda: String) -> ParametriScenarioVera {
        var s = p
        s.frase = p.frase + "\nVera ha chiesto: " + domanda
        return s
    }

    /// Il racconto di Qwen in streaming (la bolla in arrivo); se una cifra non è nella scheda di Prisma resta il
    /// racconto di Prisma. La scheda prima/dopo va comunque sotto la risposta.
    @MainActor private func raccontaScenario(_ scheda: SchedaScenarioVera, domanda: String, chiave: String, breve: Bool, motore: MotoreLocale) async throws {
        var ambiente = ambienteVera(cliente: scheda.clienteId)
        ambiente.breve = breve
        let messaggi = ScenariVera.messaggiRacconto(scheda, domanda: domanda, ambiente: ambiente)
        var opzioni = OpzioniModello()
        opzioni.temperatura = 0.3
        opzioni.contesto = NucleoVera.finestra
        opzioni.restaInMemoria = dati.impostazioni.vera.restaInMemoria
        let generazione = flussoVera.inizia(SceltaVera(modalita: .lavoro, pensa: false), motore: motore.nome)
        let r = try await motore.scrivi(messaggi, opzioni: opzioni) { p in
            DispatchQueue.main.async { self.flussoVera.aggiorna(p, generazione: generazione) }
        }
        let fedele = CommentoVera.numeriConservati(bozza: scheda.bozza + "\n" + domanda, testo: r.testo)
        aggiungiRispostaScenario(scheda, testo: fedele ? r.testo : scheda.racconto,
                                 motore: fedele ? motore.nome : MotoriVera.sintesi.nome, chiave: chiave)
    }

    private func aggiungiRispostaScenario(_ scheda: SchedaScenarioVera, testo: String, motore: String, chiave: String) {
        var m = MessaggioVera(autore: .vera, testo: testo, motore: motore)
        m.modalita = .lavoro
        m.scenario = scheda
        aggiungiMessaggio(m, cliente: chiave)
    }

    /// Una domanda breve di Vera (o il commiato), con la frase del consulente se non è già nella conversazione.
    private func rispondiScenario(_ domanda: String?, _ risposta: String, chiave: String) {
        if let domanda {
            aggiungiMessaggio(MessaggioVera(autore: .utente, testo: domanda), cliente: chiave)
            domandaVera = ""
        }
        var m = MessaggioVera(autore: .vera, testo: risposta, motore: StatoShell.motoreAzioni)
        m.modalita = .lavoro
        aggiungiMessaggio(m, cliente: chiave)
    }

    /// Toglie l'ultima domanda del consulente (prima di passarla alla risposta normale, che la rimette).
    private func togliUltimaDomanda(chiave: String) {
        func togli(_ elenco: inout [MessaggioVera]) {
            if let i = elenco.lastIndex(where: { $0.autore == .utente }), i == elenco.count - 1 { elenco.remove(at: i) }
        }
        if dati.impostazioni.vera.conservaConversazioni {
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
    func salvaScenarioVera(_ s: SchedaScenarioVera, messaggio: String) {
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
    func apriScenarioVera(_ s: SchedaScenarioVera) {
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

    /// La scheda di una risposta di Vera (per i pulsanti della mini finestra).
    func schedaScenario(messaggio: String, chiave: String) -> SchedaScenarioVera? {
        conversazione(chiave).first { $0.id == messaggio }?.scenario
    }

    /// Dopo il salvataggio la scheda nella conversazione lo ricorda (il pulsante diventa «Nel dossier»).
    private func aggiornaScenario(_ s: SchedaScenarioVera, messaggio: String) {
        func aggiorna(_ elenco: inout [MessaggioVera]) {
            if let i = elenco.firstIndex(where: { $0.id == messaggio }) { elenco[i].scenario = s }
        }
        if dati.impostazioni.vera.conservaConversazioni {
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
