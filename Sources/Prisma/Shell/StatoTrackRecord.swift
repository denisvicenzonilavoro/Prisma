import Foundation

// MARK: - Studio › Track record nello stato (giro 2)
// Il registro delle raccomandazioni (`DatiPrisma.raccomandazioni`) è IMMUTABILE: da qui si può solo `registra` una
// raccomandazione nuova (una per proposta), `aggiungiNota` e `registraScelta`. Nessuna funzione cambia o toglie ciò che è
// registrato. La registrazione è automatica quando una proposta viene presentata (`registraRaccomandazioneSeServe`,
// chiamata dal seguito delle proposte: StatoSeguito.swift e `salvaPosizione`), con le cifre dei motori di quel momento;
// quando arriva l'esito (accettata, rifiutata) la scelta del cliente si aggiunge da sola.

extension StatoShell {
    /// Le raccomandazioni dei clienti visibili (in modalità cliente solo le sue), dalla più recente.
    var raccomandazioni: [Raccomandazione] {
        let elenco = modoCliente.map { id in dati.raccomandazioni.filter { $0.clienteId == id } } ?? dati.raccomandazioni
        return elenco.sorted { $0.data != $1.data ? $0.data > $1.data : $0.id < $1.id }
    }

    /// La raccomandazione registrata per una proposta (nil se non c'è).
    func raccomandazione(perPosizione id: String) -> Raccomandazione? {
        dati.raccomandazioni.first { $0.posizioneId == id }
    }

    /// Registra una raccomandazione nuova. Rifiutata (false) se c'è già una con lo stesso id o per la stessa proposta.
    @discardableResult
    func registra(_ r: Raccomandazione) -> Bool {
        guard !solaLettura, !dati.raccomandazioni.contains(where: { $0.id == r.id }) else { return false }
        if let pid = r.posizioneId, dati.raccomandazioni.contains(where: { $0.posizioneId == pid }) { return false }
        dati.raccomandazioni.append(r)
        return true
    }

    /// Aggiunge una nota (con la data) a una raccomandazione. Le note di prima restano come sono.
    @discardableResult
    func aggiungiNota(_ testo: String, aRaccomandazione id: String, il data: Date = Posizione.oggiArrotondato) -> Bool {
        guard !solaLettura, let i = dati.raccomandazioni.firstIndex(where: { $0.id == id }) else { return false }
        var r = dati.raccomandazioni[i]
        guard r.aggiungiNota(testo, il: data) else { return false }
        dati.raccomandazioni[i] = r
        return true
    }

    /// Registra la scelta del cliente (con la data). Le scelte di prima restano nello storico; vale l'ultima.
    @discardableResult
    func registraScelta(_ scelta: SceltaCliente, raccomandazione id: String, il data: Date = Posizione.oggiArrotondato) -> Bool {
        guard !solaLettura, let i = dati.raccomandazioni.firstIndex(where: { $0.id == id }) else { return false }
        var r = dati.raccomandazioni[i]
        guard r.registraScelta(scelta, il: data) else { return false }
        dati.raccomandazioni[i] = r
        return true
    }

    /// Dopo un cambio della proposta: se è appena stata presentata (da bozza o senza esito a presentata, accettata,
    /// rifiutata o rimandata) registra la raccomandazione con le cifre di adesso; se l'esito è cambiato aggiunge la scelta
    /// del cliente. Una sola raccomandazione per proposta. Le posizioni in essere che non sono mai state proposte no.
    func registraRaccomandazioneSeServe(prima: Posizione?, dopo p: Posizione, adesso: Date = Posizione.oggiArrotondato) {
        guard !solaLettura, MotoreTrackRecord.presentata(p.esito) else { return }
        // Una posizione in essere senza esito non è una proposta; con l'esito sì (le accettate restano «accettata»)
        let eraPresentata = MotoreTrackRecord.presentata(prima?.esito)
        if raccomandazione(perPosizione: p.id) == nil {
            // Si registra solo nel momento della presentazione, non per le proposte già presentate prima del giro 2
            guard !eraPresentata else { return }
            let data = p.seguito?.presentataIl ?? adesso
            let r = MotoreTrackRecord.raccomandazione(per: p, adeguatezza: esitoAdeguatezza(p), scheda: schedaAdeguatezza(p.id),
                                                      posizioni: posizioniCliente(p.clienteId),
                                                      riferimenti: dati.impostazioni.riferimenti, data: data)
            registra(r)
        }
        guard let r = raccomandazione(perPosizione: p.id), let scelta = MotoreTrackRecord.scelta(p.esito),
              prima?.esito != p.esito else { return }
        registraScelta(scelta, raccomandazione: r.id, il: p.seguito?.esitoIl ?? adesso)
    }

    /// Il track record dei clienti visibili. Per oggi viene dalla cache (DerivatiDati); per un altro giorno si calcola.
    func trackRecord(oggi: Date = Date()) -> TrackRecord {
        let calcola = {
            MotoreTrackRecord.calcola(raccomandazioni: self.raccomandazioni, posizioni: self.posizioni,
                                      riferimenti: self.dati.impostazioni.riferimenti, oggi: oggi)
        }
        guard Calendar.current.isDateInToday(oggi) else { return calcola() }
        let d = derivatiValidi()
        if let t = d.trackRecord { return t }
        let v = calcola()
        d.trackRecord = v
        return v
    }
}
