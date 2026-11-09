import Foundation

// Ciò che Messaggi › Campagne chiede allo stato («Luce» giro 12, §9.4.4-9.4.5): i gruppi (in cache come le occasioni dei
// messaggi), gli orari liberi da proporre (mai bloccati in Agenda: decisione 98), l'avvio della campagna che crea una
// bozza per ogni incluso con il modello fisso e le cifre di quel cliente (decisione 15: niente si apre da solo), le
// aperture una alla volta, «Apri tutte», l'annullamento finché nessuna bozza è aperta e la riscrittura facoltativa di Vera,
// un messaggio alla volta e interrompibile.

extension StatoShell {
    /// I gruppi con lo stesso bisogno di oggi (nessuno in modalità cliente: le campagne mostrano tutti i clienti).
    func gruppiCampagne() -> [GruppoCampagna] {
        guard !inModoCliente else { return [] }
        let d = derivatiValidi()
        if let g = d.gruppiCampagne { return g }
        let g = MotoreCampagne.gruppi(dati: datiDeiCalcoli(), oggi: Date())
        d.gruppiCampagne = g
        return g
    }

    /// Gli orari liberi da proporre: mezz'ora, nei prossimi 14 giorni lavorativi da domani, al più quattro, uno per giorno.
    func spaziCampagna(oggi: Date = Date()) -> [SpazioLibero] {
        let cal = MotorePianificazione.calendario
        let domani = cal.date(byAdding: .day, value: MotorePianificazione.preavvisoGiorni, to: cal.startOfDay(for: oggi)) ?? oggi
        return MotorePianificazione.spazi(durata: RegoleCampagne.durataAppuntamento, da: domani,
                                          giorni: RegoleCampagne.giorniAppuntamenti, quanti: RegoleCampagne.appuntamentiMassimi,
                                          appuntamenti: dati.appuntamenti, orari: dati.impostazioni.orari, cal: cal)
    }

    /// Il testo del modello fisso per un membro (l'anteprima del pannello e la bozza). `firmaCanale`: la firma scelta con
    /// i canali misti.
    func testoCampagna(_ g: GruppoCampagna, membro: MembroCampagna, campagnaId: String, appuntamenti: [Date],
                       tono: TonoMessaggio, canale: CanaleMessaggio, firmaCanale: Canale? = nil) -> (OccasioneMessaggio, TestoMessaggio)? {
        guard let c = dati.clienti.first(where: { $0.id == membro.clienteId }) else { return nil }
        let o = MotoreCampagne.occasione(gruppo: g, membro: membro, campagnaId: campagnaId, appuntamenti: appuntamenti)
        let firma = firmaMessaggio(o.canale ?? firmaCanale, tono: tono)
        return (o, ModelliMessaggi.testo(o, tono: tono, canale: canale, cliente: c, firma: firma))
    }

    /// «Avvia la campagna»: una bozza per ogni incluso (stato «bozza», origine «campagna», il modello fisso con le cifre di
    /// quel cliente), salvata nel dossier; lo storico della campagna. Una sola assegnazione a `messaggi` e a `campagne`.
    /// Niente si apre da solo. nil in sola lettura o senza inclusi.
    @discardableResult
    func avviaCampagna(_ g: GruppoCampagna, inclusi: [String], appuntamenti: [Date], tono: TonoMessaggio,
                       canale: CanaleMessaggio, firmaCanale: Canale? = nil) -> Campagna? {
        guard !solaLettura, !inModoCliente else { return nil }
        let id = "campagna-\(UUID().uuidString.prefix(8).lowercased())"
        let adesso = MessaggioCliente.adesso
        var nuovi: [MessaggioCliente] = []
        for m in g.membri where inclusi.contains(m.clienteId) {
            guard let pronto = testoCampagna(g, membro: m, campagnaId: id, appuntamenti: appuntamenti, tono: tono,
                                             canale: canale, firmaCanale: firmaCanale) else { continue }
            let (o, t) = pronto
            // L'id dell'occasione è quello che `salvaMessaggio(…, id:)` ricostruisce: la copertura non si rompe
            let bozza = MessaggioCliente(clienteId: m.clienteId, occasioneId: o.id, origine: o.origine, canaleLavoro: o.canale,
                                         tono: tono, canale: canale, oggetto: canale == .mail ? t.oggetto : nil, testo: t.completo,
                                         cifre: o.cifre, autore: .modelloFisso, modello: nil, creatoIl: adesso)
            nuovi.append(bozza)
        }
        guard !nuovi.isEmpty else { return nil }
        let campagna = Campagna(id: id, gruppoId: g.id, gruppoTipo: g.tipo, titolo: g.titolo, avviataIl: adesso, tono: tono,
                                canale: canale, clienti: nuovi.map(\.clienteId), appuntamenti: appuntamenti.sorted(),
                                messaggi: nuovi.map(\.id))
        dati.messaggi = dati.messaggi + nuovi
        dati.campagne = dati.campagne + [campagna]
        return campagna
    }

    /// Le bozze di una campagna, nell'ordine dei clienti.
    func messaggiCampagna(_ id: String) -> [MessaggioCliente] {
        guard let c = dati.campagne.first(where: { $0.id == id }) else { return [] }
        return c.messaggi.compactMap { mid in dati.messaggi.first { $0.id == mid } }
    }

    /// Apre una bozza della campagna in Mail o in Messaggi (mai spedita): diventa «aperta» sullo stesso messaggio.
    @MainActor
    @discardableResult
    func apriBozzaCampagna(_ messaggioId: String) -> EsitoApertura {
        guard let m = dati.messaggi.first(where: { $0.id == messaggioId }) else {
            return .nonRiuscito("Il messaggio non è più nel dossier")
        }
        let o = TestiMessaggi.occasioneDalDossier(m)
        let scritto = TestoScrittoMessaggio(oggetto: m.oggetto, testo: m.testo, autore: m.autore, modello: m.modello, avviso: nil)
        let esito = apriMessaggio(o, tono: m.tono, canale: m.canale, scritto: scritto, id: m.id)
        mostraAvviso(esito.messaggio)
        return esito
    }

    /// «Apri la prossima»: la prima bozza ancora da aprire (nil se sono tutte aperte).
    @MainActor
    @discardableResult
    func apriProssimaBozza(_ campagnaId: String) -> EsitoApertura? {
        guard let m = messaggiCampagna(campagnaId).first(where: { $0.stato == .bozza }) else { return nil }
        return apriBozzaCampagna(m.id)
    }

    /// «Apri tutte» (oltre cinque la vista chiede conferma prima): una dopo l'altra.
    @MainActor
    func apriTutteLeBozze(_ campagnaId: String) {
        for m in messaggiCampagna(campagnaId) where m.stato == .bozza {
            let esito = apriBozzaCampagna(m.id)
            if case .nonRiuscito = esito { break }
        }
    }

    /// «Annulla la campagna»: solo se nessuna bozza è stata aperta; toglie le bozze e lo storico.
    @discardableResult
    func annullaCampagna(_ id: String) -> Bool {
        guard !solaLettura, let c = dati.campagne.first(where: { $0.id == id }) else { return false }
        let suoi = Set(c.messaggi)
        guard !dati.messaggi.contains(where: { suoi.contains($0.id) && $0.stato != .bozza }) else { return false }
        if dati.messaggi.contains(where: { suoi.contains($0.id) }) {
            dati.messaggi = dati.messaggi.filter { !suoi.contains($0.id) }
        }
        dati.campagne = dati.campagne.filter { $0.id != id }
        if campagne.avviata == id { campagne.avviata = nil }
        return true
    }

    /// «Fai riscrivere a Vera»: un messaggio alla volta, interrompibile; senza Qwen resta il testo di Prisma (lo dice).
    @MainActor
    func riscriviConVera(_ messaggioId: String) {
        guard !solaLettura, campagne.compitoVera == nil, let m = dati.messaggi.first(where: { $0.id == messaggioId }),
              m.stato == .bozza else { return }
        let o = TestiMessaggi.occasioneDalDossier(m)
        campagne.inScrittura.insert(messaggioId)
        campagne.compitoVera = Task { @MainActor [weak self] in
            guard let self else { return }
            let scritto = await self.scriviMessaggio(o, tono: m.tono, canale: m.canale)
            defer {
                self.campagne.inScrittura.remove(messaggioId)
                self.campagne.compitoVera = nil
            }
            guard !Task.isCancelled, let scritto else { return }
            if let avviso = scritto.avviso { self.mostraAvviso(avviso) }
            // Ancora una bozza (non aperta nel frattempo): si aggiorna lo stesso messaggio
            guard self.dati.messaggi.first(where: { $0.id == messaggioId })?.stato == .bozza else { return }
            self.salvaMessaggio(o, tono: m.tono, canale: m.canale, scritto: scritto, stato: .bozza, id: messaggioId)
        }
    }

    /// Ferma la riscrittura di Vera.
    @MainActor
    func fermaVeraCampagna() {
        campagne.compitoVera?.cancel()
        campagne.compitoVera = nil
        campagne.inScrittura = []
    }
}
