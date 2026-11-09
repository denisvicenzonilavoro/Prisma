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
        let noti = clientiAttivi.map { ClienteNoto(id: $0.id, nome: $0.nome) }
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
        memoriaVera.approva(domanda: domanda, risposta: m.testo, modalita: m.modalita)
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

    /// «Il filo lungo» sullo schermo (template: «Memoria della conversazione» e «Riassunto che Vera tiene da parte»): per una
    /// conversazione lunga, quanta finestra occupa (stima dei token di Prisma) e, se delle battute sono già uscite, il
    /// riassunto che Vera porta con sé. nil per le conversazioni brevi.
    func filoConversazione(chiave: String) -> FiloMostrato? {
        let storia = storiaPerQwen(chiave).storia
        guard storia.count >= FiloMostrato.minimoMessaggi else { return nil }
        // La finestra scelta in Impostazioni › Vera (la stessa che Prisma passa al nucleo)
        let finestra = FinestraVera.valida(dati.impostazioni.vera.finestra)
        let istruzioni = NucleoVera.token(IstruzioniVera.chat)
        let budget = max(0, finestra - istruzioni - NucleoVera.riservaRisposta - FiloMostrato.riservaUltimo)
        let uscite = FiloLungoVera.uscite(storia, budget: budget)
        let dentro = storia.suffix(max(0, storia.count - uscite.count))
        let usati = istruzioni + dentro.reduce(0) { $0 + NucleoVera.token($1.testo) + 4 }
        return FiloMostrato(messaggi: storia.count, token: min(finestra, usati), finestra: finestra, uscite: uscite.count,
                            riassunto: riassuntoVera(chiave: chiave, uscite: uscite))
    }

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

/// «Le lezioni di Vera» (template «Impara dalle correzioni», riquadro marcato «Esempio»): le risposte di Qwen votate, quante
/// approvate con 👍 al primo colpo e l'andamento nelle ultime settimane. Solo dai voti veri delle conversazioni: senza
/// voti niente percentuale (mai cifre d'esempio).
struct AndamentoApprovazioni: Equatable {
    static let settimane = 8
    /// Una settimana conta nell'andamento con almeno tante risposte votate.
    static let minimoSettimana = 1

    var votate: Int
    var approvate: Int
    /// Dalla più vecchia alla più recente: la quota approvata della settimana (nil senza voti).
    var perSettimana: [Double?]

    var percentuale: Int? { votate > 0 ? Int((Double(approvate) / Double(votate) * 100).rounded()) : nil }

    static func da(_ messaggi: [MessaggioVera], oggi: Date, cal: Calendar = .current) -> AndamentoApprovazioni {
        let votati = messaggi.filter { $0.autore == .vera && $0.voto != nil }
        var quote: [Double?] = []
        let fine = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: oggi) ?? oggi)
        for k in stride(from: Self.settimane, to: 0, by: -1) {
            let da = cal.date(byAdding: .day, value: -7 * k, to: fine) ?? fine
            let a = cal.date(byAdding: .day, value: 7, to: da) ?? da
            let dentro = votati.filter { $0.data >= da && $0.data < a }
            quote.append(dentro.count >= minimoSettimana ? Double(dentro.filter { $0.voto == true }.count) / Double(dentro.count) : nil)
        }
        return AndamentoApprovazioni(votate: votati.count, approvate: votati.filter { $0.voto == true }.count, perSettimana: quote)
    }
}

extension StatoShell {
    /// L'andamento delle risposte approvate, su tutte le conversazioni salvate (e quelle di adesso).
    func approvazioniVera(oggi: Date = Date()) -> AndamentoApprovazioni {
        let tutte = (dati.impostazioni.vera.conservaConversazioni ? Array(dati.conversazioni.values) : []) + Array(conversazioniTemporanee.values)
        return AndamentoApprovazioni.da(Array(tutte.joined()), oggi: oggi)
    }
}

/// Quello che la chat mostra del filo della conversazione.
struct FiloMostrato: Equatable {
    /// Da quanti messaggi in su la conversazione è «lunga» e il filo si vede.
    static let minimoMessaggi = 12
    /// Spazio stimato per l'ultimo messaggio (contesto, scheda, domanda).
    static let riservaUltimo = 1_200

    var messaggi: Int
    var token: Int
    var finestra: Int
    var uscite: Int
    var riassunto: String?

    var frazione: Double { finestra > 0 ? min(1, Double(token) / Double(finestra)) : 0 }
}
