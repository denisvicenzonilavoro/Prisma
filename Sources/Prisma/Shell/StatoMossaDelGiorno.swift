import Foundation

// La mossa del giorno nello stato: tenuta da parte in DerivatiDati per un'ora (come le proposte ferme), con
// gli ingressi presi dalle cache che la scrivania e le notifiche usano già. `mossaDelGiorno` sta in DerivatiDati.

extension StatoShell {
    /// La mossa del giorno dei clienti visibili (in modalità cliente solo il suo). Per oggi tenuta da parte finché
    /// non cambiano i dati dei calcoli, il giorno, la modalità cliente o l'ora; per un altro giorno calcolata
    /// ogni volta dai dati, come `conformitaClienti(oggi:)`.
    func mossaDelGiorno(oggi: Date = Date()) -> EsitoMossaDelGiorno {
        let regole = dati.impostazioni.occasioni
        let soglia = dati.impostazioni.giorniSeguitoProposte
        guard Calendar.current.isDateInToday(oggi) else {
            return MotoreMossaDelGiorno.calcola(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti,
                                                attivita: attivita, incontri: dati.incontri, prodotti: dati.prodotti,
                                                analisi: dati.analisi, regoleOccasioni: regole, sogliaSeguito: soglia, oggi: oggi)
        }
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.mossaDelGiorno, c.ora == ora { return c.valore }
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: oggi)
        // Lo stesso intervallo delle notifiche: le occasioni vengono dalla stessa cache
        let fine = cal.date(byAdding: .day, value: regole.anticipoGiorni + 1, to: inizio) ?? inizio
        let ingressi = MotoreMossaDelGiorno.Ingressi(
            clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti,
            proposte: proposteInSospeso, sogliaSeguito: soglia,
            // Gli stessi riesami del Portafoglio, in cache per l'ora come la mossa stessa (oggi è un momento di oggi)
            riesami: riesamiDovuti(),
            occasioni: occasioni(da: inizio, a: fine),
            completezza: { c in self.completezzaCliente(c.id) },
            oggi: oggi)
        let v = MotoreMossaDelGiorno.scegli(ingressi)
        d.mossaDelGiorno = (ora, v)
        return v
    }

    /// «Preparami l'incontro»: con l'appuntamento in agenda il fascicolo dell'Agenda; senza, lo stesso fascicolo
    /// con i report scelti dalla mossa, per il cliente della mossa (la bozza dell'appuntamento non si salva).
    func preparaMossa(_ m: MossaDelGiorno) {
        if m.appuntamentoInAgenda {
            preparaFascicolo(per: m.appuntamento)
            return
        }
        clienteAttivoId = m.cliente.id
        sceltaFascicolo = m.report
        fascicoloAppuntamento = nil
        apriProspetto(.fascicolo)
    }
}
