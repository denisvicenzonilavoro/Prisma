import Foundation

// La fase 2 di Vera nella conversazione (Vera/BRIEF.md): i ricordi (dettati con «ricorda che…» o proposti da Vera e
// salvati dopo il tuo sì), 👍 e 👎 con la correzione che diventa una lezione, il riassunto progressivo delle
// conversazioni lunghe e i passaggi dei documenti e delle note trovati con la ricerca per significato.
extension StatoShell {
    // MARK: - Impostazioni

    /// La finestra del modello e le lezioni seguono Impostazioni › Vera.
    func applicaImpostazioniVera() {
        let v = dati.impostazioni.vera
        FinestraVera.attuale = v.finestra
        memoriaVera.lezioniAccese = v.imparaDalleCorrezioni
        memoriaVera.carica()
    }

    // MARK: - Ricordi

    /// «Ricorda che Sofia decide sempre insieme a Paolo»: si salva subito (l'hai detto tu), con «Annulla».
    /// true se la frase era per la memoria.
    func ricordaVera(_ testo: String, chiave: String) -> Bool {
        guard let ricordo = MemoriaVera.richiestaEsplicita(testo) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        guard dati.impostazioni.vera.memoriaAttiva else {
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "La memoria di Vera è spenta: la riaccendi in Impostazioni › Vera.",
                                            motore: Self.motoreAzioni), cliente: chiave)
            return true
        }
        if let motivo = MemoriaVera.vietato(ricordo) {
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: motivo, motore: Self.motoreAzioni), cliente: chiave)
            return true
        }
        let cliente = clienteDelRicordo(ricordo, chiave: chiave)
        var azione = azioneRicordo(ricordo, cliente: cliente, fonte: "in chat")
        azione.esito = eseguiAzioneVera(azione)
        var scheda = SchedaConfermaVera(richiesta: testo, azioni: [azione], origine: .memoria)
        scheda.stato = .eseguita
        var m = MessaggioVera(autore: .vera, testo: azione.esito?.fatta == true ? "Ricordato." : (azione.esito?.messaggio ?? "Non l'ho ricordato."),
                              motore: Self.motoreAzioni)
        m.conferma = scheda
        aggiungiMessaggio(m, cliente: chiave)
        return true
    }

    /// Il cliente di un ricordo: quello nominato, altrimenti quello della conversazione (nel portafoglio: su di te).
    func clienteDelRicordo(_ testo: String, chiave: String) -> String? {
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let nominati = InterpreteComandi.clientiNominati(testo.lowercased(), noti)
        if nominati.count == 1 { return nominati[0].id }
        if chiave == VeraPortafoglio.chiave { return nil }
        // «Preferisco i report in una pagina» parla di te anche nel dossier di un cliente
        if DateItaliane.cerca(#"^(preferisco|io |mi piace|non mi piace|lavoro|il mio|la mia|odio|amo)"#, testo.lowercased()) != nil { return nil }
        return cliente(chiave) == nil ? nil : chiave
    }

    func azioneRicordo(_ testo: String, cliente: String?, fonte: String) -> AzioneConferma {
        let chi = cliente.flatMap { self.cliente($0)?.nome }
        var argomenti = ["testo": testo, "fonte": fonte]
        if let cliente { argomenti["cliente"] = cliente }
        return AzioneConferma(strumento: RegistroStrumenti.memoriaRicorda, app: .vera, titolo: chi.map { "Ricordo per \($0)" } ?? "Ricordo su di te",
                              dettaglio: "«\(testo)» · nella memoria di Vera, sul Mac, cifrata", argomenti: argomenti)
    }

    /// I ricordi che Vera propone da una tua domanda (preferenze, abitudini): una scheda «Ricorda», salvata solo dopo il sì.
    func schedaRicordi(da testo: String, chiave: String) -> SchedaConfermaVera? {
        guard dati.impostazioni.vera.memoriaAttiva, !inModoCliente else { return nil }
        let gia = Set(memoriaVera.ricordi.map { $0.testo.lowercased() })
        let azioni = MemoriaVera.proposte(da: testo).filter { !gia.contains($0.lowercased()) }.prefix(3)
            .map { azioneRicordo($0, cliente: clienteDelRicordo($0, chiave: chiave), fonte: "in chat") }
        guard !azioni.isEmpty else { return nil }
        return SchedaConfermaVera(richiesta: testo, azioni: Array(azioni), origine: .memoria)
    }

    /// I ricordi da dare a Vera per una domanda (in modalità cliente solo quelli del cliente davanti a te).
    func ricordiPerVera(cliente: String?) -> [String] {
        guard dati.impostazioni.vera.memoriaAttiva else { return [] }
        let tutti = MemoriaVera.pertinenti(memoriaVera.ricordi, cliente: cliente)
        return (inModoCliente ? tutti.filter { $0.clienteId == cliente } : tutti).map(\.testo)
    }

    // MARK: - 👍 e 👎

    /// 👍: la risposta è un buon esempio (resta cifrato nella memoria, per lo stile e l'addestramento su misura).
    func approvaRispostaVera(_ messaggio: String) {
        guard let m = messaggioVera(messaggio) else { return }
        guard dati.impostazioni.vera.imparaDalleCorrezioni, dati.impostazioni.vera.memoriaAttiva else { return }
        aggiornaMessaggioVera(messaggio) { $0.voto = true }
        let domanda = conversazioneDel(messaggio).flatMap { elenco -> String? in
            guard let i = elenco.firstIndex(where: { $0.id == messaggio }), i > 0 else { return nil }
            return elenco[..<i].last(where: { $0.autore == .utente })?.testo
        } ?? ""
        memoriaVera.approva(domanda: domanda, risposta: m.testo)
        mostraAvviso("Segnata come buona: Vera la usa come esempio")
    }

    /// 👎 con la correzione: diventa una lezione, valida dalla risposta successiva. Senza testo non si impara niente.
    @discardableResult
    func correggiRispostaVera(_ messaggio: String, correzione: String) -> LezioneVera? {
        aggiornaMessaggioVera(messaggio) { $0.voto = false }
        let t = correzione.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        guard dati.impostazioni.vera.imparaDalleCorrezioni, dati.impostazioni.vera.memoriaAttiva else {
            mostraAvviso("Le correzioni sono spente (Impostazioni › Vera).")
            return nil
        }
        if let motivo = MemoriaVera.vietato(t) {
            mostraAvviso(motivo)
            return nil
        }
        let l = memoriaVera.impara(t)
        if l != nil {
            mostraAvviso("Lezione salvata: vale dalla prossima risposta")
        } else if memoriaVera.bloccata {
            mostraAvviso("La memoria non si apre su questo Mac: sbloccala da Impostazioni › Vera.")
        }
        return l
    }

    private func conversazioneDel(_ messaggio: String) -> [MessaggioVera]? {
        let tutte = (dati.impostazioni.vera.conservaConversazioni ? Array(dati.conversazioni.values) : []) + Array(conversazioniTemporanee.values)
        return tutte.first { $0.contains { $0.id == messaggio } }
    }

    // MARK: - Il filo lungo

    /// Il riassunto delle battute uscite dalla finestra: quello di Qwen se copre già tutte le uscite, altrimenti quello di
    /// Prisma (le battute accorciate), con davanti il riassunto di Qwen delle più vecchie.
    func riassuntoVera(chiave: String, uscite: [MessaggioVera]) -> String? {
        guard !uscite.isEmpty else { return nil }
        let filo = memoriaVera.filo(chiave)
        guard let filo, let i = uscite.firstIndex(where: { $0.id == filo.finoA }) else { return FiloLungoVera.riassuntoDiPrisma(uscite) }
        let dopo = Array(uscite[(i + 1)...])
        return dopo.isEmpty ? filo.riassunto : filo.riassunto + "\n" + FiloLungoVera.riassuntoDiPrisma(dopo)
    }

    /// Dopo una risposta: se ci sono battute uscite non ancora riassunte, Qwen aggiorna il riassunto (in background).
    func aggiornaFiloVera(chiave: String, uscite: [MessaggioVera], motore: MotoreLocale) {
        // Le conversazioni temporanee non lasciano riassunti sul disco
        guard dati.impostazioni.vera.memoriaAttiva, dati.impostazioni.vera.conservaConversazioni, let ultima = uscite.last else { return }
        let filo = memoriaVera.filo(chiave)
        guard filo?.finoA != ultima.id else { return }
        let precedente: String?
        let nuove: [MessaggioVera]
        // Il riassunto di una conversazione chiusa non rientra in quella nuova
        if let filo, let i = uscite.firstIndex(where: { $0.id == filo.finoA }) { precedente = filo.riassunto; nuove = Array(uscite[(i + 1)...]) } else { precedente = nil; nuove = uscite }
        let messaggi = FiloLungoVera.messaggi(precedente: precedente, nuove: nuove)
        var o = OpzioniModello()
        o.temperatura = 0.2
        o.contesto = NucleoVera.finestra
        o.massimoToken = 500
        o.restaInMemoria = dati.impostazioni.vera.restaInMemoria
        o.conLezioni = false
        Task { @MainActor in
            guard let r = try? await motore.scrivi(messaggi, opzioni: o).testo, !r.isEmpty, MemoriaVera.vietato(r) == nil,
                  // Una risposta arrivata dopo «Nuova conversazione» non riscrive il filo
                  self.conversazione(chiave).contains(where: { $0.id == ultima.id }) else { return }
            self.memoriaVera.aggiornaFilo(chiave, FiloVera(riassunto: String(r.prefix(FiloLungoVera.massimoCaratteri)), finoA: ultima.id))
        }
    }

    // MARK: - I passaggi trovati

    /// I passaggi dei documenti, delle note e degli incontri del cliente pertinenti alla domanda (al massimo quattro):
    /// per significato se c'è il modello di ricerca, altrimenti per parole.
    func braniPerVera(_ domanda: String, cliente id: String) async -> [(fonte: String, testo: String)] {
        let documenti = documentiCliente(id).compactMap { d -> (Documento, [String])? in
            let p = testoDocumento(d)
            return p.isEmpty ? nil : (d, p)
        }
        let pezzi = RicercaVera.pezzi(documenti: documenti, note: noteCliente(id), incontri: incontriCliente(id))
        guard !pezzi.isEmpty else { return [] }
        let vera = dati.impostazioni.vera
        var vettori: [String: [Float]] = [:]
        var q: [Float]?
        if vera.fornitore == .ollama, disponibilitaLocale.pronto {
            let f = FornitoreOllama(indirizzo: vera.indirizzoLocale, modello: vera.modelloLocale)
            if let v = await indiceVera.vettori(per: pezzi, domanda: domanda, fornitore: f, modello: vera.modelloRicerca,
                                                liberaPrima: { await f.libera() }) {
                vettori = v.pezzi
                q = v.domanda
            }
        }
        return RicercaVera.cerca(domanda, in: pezzi, vettori: vettori, domandaVettore: q, quanti: 4)
            .map { ($0.pezzo.fonte, String($0.pezzo.testo.prefix(700))) }
    }
}
