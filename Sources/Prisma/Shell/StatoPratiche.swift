import Foundation

// Le pratiche dopo la firma nello stato di Prisma (Design/template-luce-specifica.md §7.3, «Luce» giro 3): nascita
// della pratica quando una proposta viene accettata, segni a mano sui passi, note, sollecito in Messaggi e rimandi a
// Posizioni. I calcoli li fa MotorePratiche; qui solo le modifiche all'archivio. Prisma non spedisce niente da solo.

extension StatoShell {
    /// Le pratiche con il loro stato, nell'ordine della scheda (in modalità cliente solo quelle del suo cliente:
    /// ma Pratiche in modalità cliente non si apre).
    func statiPratiche(oggi: Date = Date()) -> [StatoPratica] {
        let tutti = MotorePratiche.stati(datiPratiche(), oggi: oggi)
        guard let solo = modoCliente else { return tutti }
        return tutti.filter { $0.clienteId == solo }
    }

    /// L'archivio per MotorePratiche: i dati dei calcoli (senza iscriversi a tutto l'archivio) più le pratiche, le schede
    /// di adeguatezza e le impostazioni, che non entrano nei calcoli e si leggono vive (la vista si iscrive a quelle).
    func datiPratiche() -> DatiPrisma {
        var d = datiDeiCalcoli()
        d.pratiche = dati.pratiche
        d.schedeAdeguatezza = dati.schedeAdeguatezza
        d.impostazioni = dati.impostazioni
        return d
    }

    /// Una proposta appena accettata apre la sua pratica, se la posizione non ne ha già una. Data di apertura: quella
    /// dell'esito. Le proposte accettate prima del giro 3 restano senza pratica (nessuna creazione in massa).
    func apriPraticaSeServe(_ p: Posizione) {
        let il = p.seguito?.esitoIl ?? Posizione.oggiArrotondato
        guard let nuova = MotorePratiche.nuova(per: p, esistenti: dati.pratiche, il: il) else { return }
        dati.pratiche.append(nuova)
    }

    /// Segna un passo a mano, fatto (con la data, oggi di base) o tolto. Il segno a mano vince sul riconoscimento.
    func segnaPasso(_ praticaId: String, _ passo: PassoPratica, fatto: Bool, il data: Date = Posizione.oggiArrotondato) {
        guard !solaLettura else {
            mostraAvviso(TestiSeguito.solaLettura)
            return
        }
        guard let i = dati.pratiche.firstIndex(where: { $0.id == praticaId }) else { return }
        var p = dati.pratiche[i]
        MotorePratiche.segna(passo, fatto: fatto, il: data, pratica: &p, dati: dati.istantanea)
        dati.pratiche[i] = p
    }

    /// Toglie il segno a mano: torna a valere ciò che Prisma riconosce dai dati.
    func togliSegnoPasso(_ praticaId: String, _ passo: PassoPratica) {
        guard !solaLettura, let i = dati.pratiche.firstIndex(where: { $0.id == praticaId }) else { return }
        var p = dati.pratiche[i]
        MotorePratiche.togliSegno(passo, pratica: &p, dati: dati.istantanea)
        dati.pratiche[i] = p
    }

    /// Aggiunge una nota di lavoro alla pratica (con la data di oggi). Una nota vuota non si salva.
    func aggiungiNotaPratica(_ praticaId: String, _ testo: String) {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !solaLettura, let i = dati.pratiche.firstIndex(where: { $0.id == praticaId }) else { return }
        dati.pratiche[i].note = (dati.pratiche[i].note ?? []) + [NotaPratica(data: MessaggioCliente.adesso, testo: t)]
    }

    /// «Sollecita»: prepara il messaggio in Messaggi (una bozza da rivedere: niente parte da solo) e ricorda
    /// l'occasione nella pratica, così la card dice «✓ Sollecito pronto». `apri`: false lascia Pratiche davanti
    /// (istantanee e prove).
    func sollecitaPratica(_ praticaId: String, apri: Bool = true, oggi: Date = Date()) {
        guard let s = MotorePratiche.stati(datiPratiche(), oggi: oggi).first(where: { $0.id == praticaId }),
              let o = MotorePratiche.occasioneSollecito(s, oggi: oggi),
              let i = dati.pratiche.firstIndex(where: { $0.id == praticaId }) else { return }
        if !solaLettura { dati.pratiche[i].sollecitoOccasioneId = o.id }
        if apri {
            preparaMessaggio(clienteId: s.clienteId, occasione: o)
            mostraAvviso("Messaggio di sollecito pronto in Messaggi")
        } else {
            occasioniSuRichiesta.removeAll { $0.id == o.id }
            occasioniSuRichiesta.insert(o, at: 0)
        }
    }

    /// «✓ Sollecito pronto» finché il messaggio del sollecito è in bozza: l'occasione è ancora fra quelle su richiesta
    /// (in memoria) o c'è un messaggio salvato in bozza, e nessun messaggio per quell'occasione è stato aperto.
    func sollecitoPronto(_ p: Pratica) -> Bool {
        guard let id = p.sollecitoOccasioneId else { return false }
        let suoi = dati.messaggi.filter { $0.occasioneId == id }
        if suoi.contains(where: { $0.stato.copreOccasione }) { return false }
        return suoi.contains { $0.stato == .bozza } || occasioniSuRichiesta.contains { $0.id == id }
    }

    /// «Apri in Posizioni»: la posizione della pratica nel dettaglio di Posizioni.
    func apriPosizioneDellaPratica(_ praticaId: String) {
        guard let pid = dati.pratiche.first(where: { $0.id == praticaId })?.posizioneId,
              let pos = dati.posizioni.first(where: { $0.id == pid }) else { return }
        apriPosizione(pos)
    }

    /// Sull'iPhone un passo si segna solo se il giornale di «Prisma ovunque» lo porta al Mac (modifiche dai dispositivi
    /// ammesse dal Mac); altrimenti la vista resta in sola lettura.
    var passiDalTelefono: Bool { !solaLettura && dati.impostazioni.ovunque.scriveGiornale }

    /// «Apri i moduli»: Pratiche › Moduli per il cliente e la posizione della pratica, sul primo modello del suo canale.
    func apriModuliDellaPratica(_ praticaId: String) {
        guard let pid = dati.pratiche.first(where: { $0.id == praticaId })?.posizioneId,
              let pos = dati.posizioni.first(where: { $0.id == pid }) else { return }
        moduli.carica()
        let prodotto = pos.prodottoId.flatMap { id in dati.prodotti.first { $0.id == id } }
        let primo = MotoreProposta.modelli(per: pos, prodotto: prodotto, tra: moduli.tutti).first
        apriModuliProposta(pos, modulo: primo?.id)
    }

    /// «Vai alle proposte»: il Portafoglio di Posizioni sull'elenco delle proposte da riprendere.
    func vaiAlleProposte() {
        posizioneInDettaglio = nil
        portafoglio = true
        provaFuoco.vista = .portafoglio
        ancoraPosizioni = "seguito"
        apri(.posizioni)
    }
}
