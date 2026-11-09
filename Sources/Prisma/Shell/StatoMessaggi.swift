import Foundation

// Ciò che Messaggi chiede allo stato (fondamenta del giro 3 di Orizzonte): le occasioni di oggi e della settimana
// (MotoreOccasioniMessaggi, tenute da parte in DerivatiDati finché non cambiano i dati dei calcoli, messaggi compresi,
// o il giorno), i messaggi di un cliente per il dossier, la firma, la scrittura con Vera e il salvataggio nel dossier.
// Prisma non spedisce mai: `apriMessaggio` apre Mail o Messaggi già compilati e segna il messaggio come aperto.

extension StatoShell {
    /// Le occasioni dei messaggi dei clienti visibili (in modalità cliente solo le sue). Per oggi vengono dalla cache
    /// (DerivatiDati); per un altro giorno si calcolano.
    func occasioniMessaggi(oggi: Date = Date()) -> OccasioniMessaggi {
        let calcola = { () -> OccasioniMessaggi in
            let tutte = MotoreOccasioniMessaggi.calcola(dati: self.datiDeiCalcoli(), oggi: oggi)
            return self.modoCliente.map { tutte.soloCliente($0) } ?? tutte
        }
        guard Calendar.current.isDateInToday(oggi) else { return calcola() }
        let d = derivatiValidi()
        if let o = d.occasioniMessaggi { return o }
        let v = calcola()
        d.occasioniMessaggi = v
        return v
    }

    /// I messaggi preparati per un cliente, dal più recente (il dossier li mostra con la data).
    func messaggiCliente(_ id: String) -> [MessaggioCliente] {
        dati.messaggi.filter { $0.clienteId == id }.sorted(by: MessaggioCliente.ordina)
    }

    /// La firma per il canale di lavoro e il tono, dai dati del consulente (nil se Prisma non la conosce).
    func firmaMessaggio(_ canale: Canale?, tono: TonoMessaggio) -> String? {
        ModelliMessaggi.firma(canale, tono: tono, impostazioni: dati.impostazioni)
    }

    /// Il testo di un messaggio: Qwen se è pronto (in streaming su `aggiorna`, dal thread del modello), altrimenti o se
    /// il testo non passa la verifica delle cifre il modello fisso di Prisma con l'avviso. Sul thread principale: legge
    /// `dati` e `disponibilitaLocale` senza gare con il salvataggio; la scrittura di Qwen gira fuori (MessaggiVera.scrivi).
    @MainActor
    func scriviMessaggio(_ o: OccasioneMessaggio, tono: TonoMessaggio, canale: CanaleMessaggio,
                         aggiorna: ((String) -> Void)? = nil) async -> TestoScrittoMessaggio? {
        guard let c = dati.clienti.first(where: { $0.id == o.clienteId }) else { return nil }
        let vera = dati.impostazioni.vera
        let firma = firmaMessaggio(o.canale, tono: tono)
        return await MessaggiVera.scrivi(o, cliente: c, tono: tono, canale: canale, firma: firma,
                                        motore: MotoriVera.qwen(vera, locale: disponibilitaLocale), vera: vera, aggiorna: aggiorna)
    }

    /// Salva nel dossier il messaggio di un'occasione (o aggiorna quello con lo stesso id). Restituisce il messaggio
    /// salvato; nil in sola lettura o se il cliente non c'è più.
    @discardableResult
    func salvaMessaggio(_ o: OccasioneMessaggio, tono: TonoMessaggio, canale: CanaleMessaggio, scritto: TestoScrittoMessaggio,
                        stato: StatoMessaggio = .salvato, id: String? = nil) -> MessaggioCliente? {
        guard !solaLettura, dati.clienti.contains(where: { $0.id == o.clienteId }) else { return nil }
        var m = MessaggioCliente(clienteId: o.clienteId, occasioneId: o.id, origine: o.origine, canaleLavoro: o.canale, tono: tono,
                                 canale: canale, oggetto: canale == .mail ? scritto.oggetto : nil, testo: scritto.testo,
                                 cifre: o.cifre, autore: scritto.autore, modello: scritto.modello)
        m.stato = stato
        if stato == .apertoInMail || stato == .apertoInMessaggi { m.apertoIl = MessaggioCliente.adesso }
        if let id, let i = dati.messaggi.firstIndex(where: { $0.id == id }) {
            m.id = id
            m.creatoIl = dati.messaggi[i].creatoIl
            dati.messaggi[i] = m
        } else {
            dati.messaggi.append(m)
        }
        return m
    }

    /// Apre il messaggio già compilato in Mail o in Messaggi (mai un invio) e, se si è aperto, lo segna nel dossier.
    @MainActor
    @discardableResult
    func apriMessaggio(_ o: OccasioneMessaggio, tono: TonoMessaggio, canale: CanaleMessaggio, scritto: TestoScrittoMessaggio,
                       id: String? = nil) -> EsitoApertura {
        guard let c = dati.clienti.first(where: { $0.id == o.clienteId }) else {
            return .nonRiuscito("Il cliente non è più in Prisma")
        }
        // Con i file dell'occasione (il PDF della fattura da Studio): CollegamentiMessaggi.swift
        let esito = AperturaMessaggi.apri(testo: scritto.testo, oggetto: canale == .mail ? scritto.oggetto : nil, canale: canale,
                                          cliente: c, allegati: allegatiMessaggi[o.id] ?? [])
        if esito.aperto {
            salvaMessaggio(o, tono: tono, canale: canale, scritto: scritto,
                           stato: canale == .mail ? .apertoInMail : .apertoInMessaggi, id: id)
            // «Le promesse» (fase 3 di Vera): gli impegni scritti nel messaggio aperto entrano nell'elenco
            raccogliPromesse(cliente: o.clienteId)
            // «Luce» giro 15: l'aggiornamento del sinistro segna il giorno nel sinistro e la traccia nel dossier
            if o.tipo == .sinistro { segnaAggiornamentoSinistro(o, canale: canale) }
        }
        return esito
    }
}
