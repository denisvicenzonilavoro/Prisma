import Foundation

// «Ragiona a passi» (Vera/BRIEF.md, funzione 20; motore PassiVera.swift) nell'app: davanti a una richiesta come «Marco ha
// 400 € al mese: vuole proteggere Elena e continuare con gli studi di Tommaso. Come li divido?» Vera scrive il piano
// (al massimo cinque passi, ognuno con il suo strumento di sola lettura), lo esegue con i motori di Prisma e spiega la
// scelta. Qwen, se è pronto, propone il piano e riscrive la spiegazione; il codice controlla entrambi e, se non vanno,
// restano il piano delle regole e la bozza di Prisma (stesse cifre). Qwen non pronto: Vera lo dice e risponde con le
// regole. Niente cambia senza «Conferma»: la divisione nel taccuino e il rinnovo delle polizze sono nella scheda.
//
// Il piano finito sta nel messaggio di Vera (`MessaggioVera.pianoPassi`), quindi nella conversazione del cliente: nel backup
// sì, nell'istantanea di «Prisma ovunque» no (le conversazioni restano sul Mac). L'interruttore «Mostra il
// ragionamento» e «Ragiona a passi» acceso o spento sono in `Impostazioni.vera.passi`.
extension StatoShell {
    static let titoloPassi = "Ragiona a passi"
    static let avvisoPassiSenzaQwen = "Qwen non è pronto: il piano e la spiegazione sono quelli delle regole di Prisma, con le stesse cifre."

    /// Qwen si usa solo se è pronto (e non nelle prove e nelle istantanee con le risposte preparate).
    var qwenPerPassi: MotoreLocale? { generativo != nil && !rispostePreparate ? qwen : nil }

    /// La frase merita il ragionamento a passi (e la funzione è accesa in Impostazioni › Vera).
    func richiestaPassi(_ testo: String) -> Bool {
        dati.impostazioni.vera.passi.attivo && PassiVera.eUnaRichiesta(testo)
    }

    /// I dati dei passi per un cliente, presi dall'archivio una volta sola (fuori dalle viste).
    func datiPassi(cliente id: String, oggi: Date = Date()) -> DatiPassi? {
        guard cliente(id) != nil else { return nil }
        return DatiPassi.da(dati.istantanea, clienteId: id, oggi: oggi)
    }

    // MARK: - La richiesta in chat

    /// Com'è andata la lettura di una richiesta: manca il cliente, Vera deve chiedere qualcosa, oppure è pronta.
    enum EsitoRichiestaPassi {
        case senzaCliente
        case domanda(String)
        case pronta(RichiestaPassi, DatiPassi)
    }

    static let domandaClientePassi = "Di quale cliente divido il budget? Dimmi il nome, o apri il suo dossier."
    /// Una domanda di Vera aspetta la risposta per questo tempo; dopo, la frase è una richiesta nuova.
    static let attesaRispostaPassi: TimeInterval = 30 * 60
    /// Al massimo tante domande di seguito sulla stessa richiesta.
    static let domandeDiSeguitoPassi = 3

    /// Il cliente della richiesta: quello nominato; con più clienti nominati quello del dossier aperto solo se è tra
    /// loro (altrimenti nil e Vera chiede di chi si parla, come `PassiVera.cliente(nel:clienti:attivo:)`); nessuno
    /// nominato, quello del dossier aperto. In modalità cliente sempre e solo quello davanti a te.
    func clientePassi(_ testo: String, chiave: String) -> String? {
        if inModoCliente { return clienteDellaRichiesta(testo, chiave: chiave) }
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let nominati = InterpreteComandi.clientiNominati(InterpreteComandi.pulisci(testo), noti)
        let aperto = chiave != VeraPortafoglio.chiave && cliente(chiave) != nil ? chiave : nil
        if nominati.count == 1 { return nominati[0].id }
        if nominati.count > 1 { return nominati.contains { $0.id == aperto } ? aperto : nil }
        return aperto
    }

    /// Legge la richiesta: il cliente (quello scelto nella risposta a «Di quale cliente…?», se c'è), poi budget,
    /// protezione e obiettivi (`PassiVera.capisci`).
    func risolviPassi(_ testo: String, chiave: String, clienteScelto: String? = nil) -> EsitoRichiestaPassi {
        guard let id = clienteScelto ?? clientePassi(testo, chiave: chiave), let d = datiPassi(cliente: id) else { return .senzaCliente }
        switch PassiVera.capisci(testo, cliente: d.cliente, obiettivi: d.obiettivi) {
        case .domanda(let domanda): return .domanda(domanda)
        case .richiesta(let r): return .pronta(r, d)
        }
    }

    /// La richiesta che aspetta la risposta a una domanda di Vera in questa conversazione, ricavata dai messaggi (niente
    /// stato da azzerare): l'ultimo messaggio è una domanda dei passi (titolo dei passi, senza piano né scheda), recente,
    /// e risalendo le coppie domanda dell'utente → domanda di Vera si arriva a una richiesta completa. Le frasi
    /// dell'utente si uniscono in ordine. nil se la conversazione è andata avanti o la domanda è vecchia.
    func richiestaPassiInSospeso(_ chiave: String, adesso: Date = Date()) -> String? {
        let c = conversazione(chiave)
        guard let ultima = c.last, adesso.timeIntervalSince(ultima.data) < Self.attesaRispostaPassi else { return nil }
        var i = c.count - 1
        var pezzi: [String] = []
        for _ in 0..<Self.domandeDiSeguitoPassi {
            guard i >= 1, c[i].autore == .vera, c[i].titolo == Self.titoloPassi, c[i].pianoPassi == nil, c[i].conferma == nil,
                  c[i - 1].autore == .utente else { return nil }
            let frase = c[i - 1].testo
            pezzi.insert(frase, at: 0)
            if PassiVera.eUnaRichiesta(frase) { return pezzi.joined(separator: " ") }
            i -= 2
        }
        return nil
    }

    /// «Marco ha 400 € al mese: protezione e studi, come li divido?», «ragiona a passi: …». true se l'ha gestita.
    /// Una risposta breve a una domanda di Vera («Marco», il titolo dell'obiettivo) riprende la richiesta in sospeso:
    /// solo se così Vera va avanti (piano pronto o una domanda nuova), altrimenti la frase passa agli altri motori.
    func chiediPassi(_ testo: String, chiave: String) -> Bool {
        guard dati.impostazioni.vera.passi.attivo else { return false }
        if !PassiVera.eUnaRichiesta(testo), let prima = richiestaPassiInSospeso(chiave) {
            // «Marco» in risposta a «Di quale cliente…?» vale anche se la richiesta nominava più persone
            var scelto: String?
            if !inModoCliente, conversazione(chiave).last?.testo == Self.domandaClientePassi {
                let nominati = InterpreteComandi.clientiNominati(InterpreteComandi.pulisci(testo), dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) })
                if nominati.count == 1 { scelto = nominati[0].id }
            }
            let esito = risolviPassi(prima + " " + testo, chiave: chiave, clienteScelto: scelto)
            let ultimaDomanda = conversazione(chiave).last?.testo
            switch esito {
            case .pronta: break
            case .domanda(let d) where d != ultimaDomanda: break
            default: return false
            }
            // Nella conversazione la risposta resta come l'ha scritta l'utente
            aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
            domandaVera = ""
            concludiPassi(esito, chiave: chiave)
            return true
        }
        guard richiestaPassi(testo) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        concludiPassi(risolviPassi(testo, chiave: chiave), chiave: chiave)
        return true
    }

    /// La domanda di Vera (non inventa il cliente, il budget né l'obiettivo) o il piano.
    private func concludiPassi(_ esito: EsitoRichiestaPassi, chiave: String) {
        switch esito {
        case .senzaCliente: rispostaPassi(Self.domandaClientePassi, chiave: chiave)
        case .domanda(let domanda): rispostaPassi(domanda, chiave: chiave)
        case .pronta(let r, let d): eseguiPassi(r, dati: d, chiave: chiave)
        }
    }

    /// Il piano di una richiesta capita: con Qwen pronto in un Task (piano proposto e spiegazione, controllati), senza
    /// Qwen subito con le regole. Non scrive messaggi dell'utente e non tocca il campo di scrittura («Rifai i calcoli»
    /// passa di qui).
    func eseguiPassi(_ r: RichiestaPassi, dati d: DatiPassi, chiave: String) {
        guard let motore = qwenPerPassi else {
            // Senza Qwen (o con le risposte preparate): il piano delle regole e la bozza di Prisma, subito
            let piano = PassiVera.eseguiTutto(PassiVera.piano(r, dati: d), dati: d)
            pubblicaPianoPassi(piano, cliente: d.cliente, chiave: chiave, motore: MotoriVera.sintesi.nome,
                               senzaQwen: generativo == nil && !rispostePreparate)
            return
        }
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let piano = await self.pianoPassiConQwen(r, dati: d, motore: motore)
            guard !Task.isCancelled else { return }
            // Il cliente può essere stato tolto mentre Qwen pensava
            if let c = self.cliente(r.clienteId) {
                let nome = piano.conQwen || piano.spiegazioneConQwen ? motore.nome : MotoriVera.sintesi.nome
                self.pubblicaPianoPassi(piano, cliente: c, chiave: chiave, motore: nome)
            }
            self.veraInCorso = false
            self.compitoVera = nil
        }
    }

    /// Con Qwen: il piano proposto (valido solo se passa il controllo di `PassiVera.leggiPiano`), l'esecuzione con i
    /// motori di Prisma e la spiegazione riscritta (valida solo se passa `PassiVera.leggiSpiegazione`).
    func pianoPassiConQwen(_ r: RichiestaPassi, dati d: DatiPassi, motore: MotoreLocale) async -> PianoPassi {
        let vera = dati.impostazioni.vera
        var passiQwen: [PassoPiano]?
        if let json = try? await motore.scrivi(PassiVera.messaggiPiano(r, dati: d), opzioni: PassiVera.opzioniPiano(vera)).testo {
            passiQwen = PassiVera.leggiPiano(json, richiesta: r, dati: d)
        }
        var piano = PassiVera.eseguiTutto(PassiVera.piano(r, dati: d, passiQwen: passiQwen), dati: d)
        guard !Task.isCancelled, piano.divisioneConsigliata != nil else { return piano }
        if let json = try? await motore.scrivi(PassiVera.messaggiSpiegazione(piano), opzioni: PassiVera.opzioniSpiegazione(vera)).testo {
            piano = PassiVera.conSpiegazione(json, piano: piano)
        }
        return piano
    }

    /// La risposta di Vera: la spiegazione come testo (anche a voce), il piano e le divisioni nella scheda, le azioni
    /// (taccuino, rinnovi) nella scheda «Conferma».
    @discardableResult
    func pubblicaPianoPassi(_ piano: PianoPassi, cliente c: Cliente, chiave: String, motore: String, senzaQwen: Bool = false) -> MessaggioVera {
        // La data del piano è quella in cui compare: con Qwen la risposta può arrivare dopo la finestra delle animazioni
        // e la cascata dei passi non partirebbe
        var piano = piano
        piano.creatoIl = Date()
        var testo = piano.spiegazione
        if senzaQwen { testo += "\n\n" + Self.avvisoPassiSenzaQwen }
        var m = MessaggioVera(autore: .vera, testo: testo, titolo: Self.titoloPassi, motore: motore)
        m.pianoPassi = piano
        let azioni = solaLettura ? [] : PassiVera.azioni(piano, cliente: c)
        if !azioni.isEmpty {
            m.conferma = SchedaConfermaVera(richiesta: piano.richiesta.testo, azioni: azioni, origine: .regole)
        }
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    @discardableResult
    private func rispostaPassi(_ testo: String, chiave: String) -> MessaggioVera {
        let m = MessaggioVera(autore: .vera, testo: testo, titolo: Self.titoloPassi, motore: MotoriVera.sintesi.nome)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    // MARK: - Dalla scheda

    /// «Apri gli obiettivi»: il dossier del cliente sulla scheda Obiettivi, con il primo obiettivo della richiesta.
    /// In modalità cliente solo il cliente davanti a te.
    func apriObiettiviPassi(_ piano: PianoPassi) {
        let id = piano.richiesta.clienteId
        guard cliente(id) != nil else { return mostraAvviso("Il cliente non è più in Prisma.") }
        guard visibileAlCliente(id) else { return }
        if clienteAttivoId != id { clienteAttivoId = id }
        schedaCliente = .obiettivi
        if let o = piano.richiesta.obiettiviIds.first, dati.obiettivi.contains(where: { $0.id == o }) { obiettivoSelezionato = o }
        apri(.clienti)
    }

    /// «Rifai i calcoli»: la stessa richiesta con i dati di adesso (le posizioni o gli obiettivi possono essere cambiati),
    /// con Qwen se è pronto, altrimenti con le regole. Non ripete la domanda in chat e non tocca il campo di scrittura.
    func rifaiPassi(_ piano: PianoPassi, chiave: String) {
        guard !veraInCorso else { return }
        guard let d = datiPassi(cliente: piano.richiesta.clienteId) else { return mostraAvviso("Il cliente non è più in Prisma.") }
        var r = piano.richiesta
        // Gli obiettivi tolti nel frattempo escono dalla richiesta
        r.obiettiviIds = r.obiettiviIds.filter { d.obiettivo($0) != nil }
        guard !r.obiettiviIds.isEmpty else { return mostraAvviso("Gli obiettivi della richiesta non sono più nel dossier.") }
        // Resta un solo obiettivo senza la protezione: non c'è niente da dividere, Vera chiede invece di un piano vuoto
        guard r.protezione || r.obiettiviIds.count >= 2 else {
            rispostaPassi("Tra cosa divido i \(CifreDoc.euro(r.budgetMensile)) al mese? Uno degli obiettivi non è più nel dossier: dimmi se c'è anche la protezione o un altro obiettivo.", chiave: chiave)
            return
        }
        eseguiPassi(r, dati: d, chiave: chiave)
    }

    /// L'interruttore «Mostra il ragionamento» (nella scheda e in Impostazioni › Vera).
    var mostraRagionamentoPassi: Bool {
        get { dati.impostazioni.vera.passi.mostraRagionamento }
        set { dati.impostazioni.vera.passi.mostraRagionamento = newValue }
    }

    // MARK: - Per le istantanee e le prove

    /// Il piano completo con le regole, senza chat (le istantanee della scheda e le prove dello stato).
    func pianoPassiConRegole(_ testo: String, cliente id: String, oggi: Date = Date()) -> PianoPassi? {
        guard let d = datiPassi(cliente: id, oggi: oggi),
              case .richiesta(let r) = PassiVera.capisci(testo, cliente: d.cliente, obiettivi: d.obiettivi) else { return nil }
        return PassiVera.eseguiTutto(PassiVera.piano(r, dati: d), dati: d)
    }
}

// MARK: - Prova

extension StatoShell {
    /// «Ragiona a passi» oltre la prima frase (da chiamare in `Prisma --prova-vera`, accanto a `ProvaCollegaPassi`): con più
    /// clienti nominati vale il dossier aperto solo se è tra loro; la risposta a «Di quale cliente…?» riprende la
    /// richiesta; «Rifai i calcoli» non ripete la domanda né svuota il campo e non pubblica un piano vuoto; il piano
    /// pubblicato ha la data di quando compare.
    static func provaPassiSeguito(_ controlla: (Bool, String) -> Void) {
        // Più clienti nominati (con i fittizi c'è Tommaso Fabbri): il dossier aperto vale solo se è tra loro
        let f = StatoShell(persistente: false)
        f.rispostePreparate = true
        f.dati.carica(ClientiFittizi.completi())
        let frase = ProvaCollegaPassi.frase
        let noti = f.dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let nominati = InterpreteComandi.clientiNominati(InterpreteComandi.pulisci(frase), noti)
        if nominati.count > 1, nominati.contains(where: { $0.id == "marco" }),
           let altro = f.dati.clienti.first(where: { c in !nominati.contains { $0.id == c.id } }) {
            controlla(f.clientePassi(frase, chiave: "marco") == "marco",
                      "Ragiona a passi: con più clienti nominati vale il dossier aperto se è tra loro")
            controlla(f.clientePassi(frase, chiave: altro.id) == nil,
                      "Ragiona a passi: con più clienti nominati il dossier di \(altro.nome) non vale, Vera chiede di chi si parla")
        } else {
            controlla(false, "Ragiona a passi: con i clienti fittizi la frase del template dovrebbe nominare Marco e Tommaso: \(nominati.map(\.nome))")
        }
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        // Nel portafoglio: la domanda, poi la risposta «Marco» riprende la richiesta
        let richiesta = "Ha 400 € al mese: vuole proteggere Elena e continuare con gli studi di Tommaso. Come li divido?"
        let p = VeraPortafoglio.chiave
        s.veraPortafoglio = true
        controlla(s.chiediPassi(richiesta, chiave: p) && s.conversazione(p).last?.testo == domandaClientePassi,
                  "Ragiona a passi: nel portafoglio senza un nome Vera chiede di quale cliente")
        controlla(s.richiestaPassiInSospeso(p) == richiesta, "Ragiona a passi: la richiesta resta in sospeso fino alla risposta")
        let n = s.conversazione(p).count
        controlla(!s.chiediPassi("Che tempo fa domani?", chiave: p) && s.conversazione(p).count == n,
                  "Ragiona a passi: una frase che non risponde alla domanda passa agli altri motori")
        controlla(s.chiediPassi("Marco", chiave: p), "Ragiona a passi: «Marco» risponde alla domanda di Vera")
        let conv = s.conversazione(p)
        controlla(conv.count >= 2 && conv[conv.count - 2].autore == .utente && conv[conv.count - 2].testo == "Marco"
                  && (conv.last?.titolo == titoloPassi),
                  "Ragiona a passi: la risposta resta com'è scritta e Vera riprende la richiesta su Marco")
        guard let piano = conv.last?.pianoPassi, piano.richiesta.clienteId == "marco" else {
            return controlla(false, "Ragiona a passi: dopo «Marco» manca il piano su Marco: \(conv.last?.testo ?? "")")
        }
        controlla(Date().timeIntervalSince(piano.creatoIl) < 5, "Ragiona a passi: il piano ha la data di quando compare")
        controlla(s.richiestaPassiInSospeso(p) == nil, "Ragiona a passi: con il piano pubblicato niente resta in sospeso")
        // «Rifai i calcoli»: niente messaggi dell'utente, il campo resta com'era
        s.domandaVera = "Una domanda a metà"
        let utente = s.conversazione(p).filter { $0.autore == .utente }.count
        s.rifaiPassi(piano, chiave: p)
        controlla(s.domandaVera == "Una domanda a metà" && s.conversazione(p).filter { $0.autore == .utente }.count == utente
                  && s.conversazione(p).last?.pianoPassi != nil,
                  "Ragiona a passi: «Rifai i calcoli» non ripete la domanda e non svuota il campo")
        // Resta un solo obiettivo, senza la protezione: Vera chiede, niente piano vuoto
        var vecchio = piano
        vecchio.richiesta.protezione = false
        vecchio.richiesta.obiettiviIds = Array(piano.richiesta.obiettiviIds.prefix(1)) + ["obiettivo-tolto"]
        s.rifaiPassi(vecchio, chiave: p)
        controlla(s.conversazione(p).last?.pianoPassi == nil && s.conversazione(p).last?.testo.hasPrefix("Tra cosa divido") == true,
                  "Ragiona a passi: con un solo obiettivo rimasto e senza protezione Vera chiede invece di un piano vuoto")
        // Un piano preparato tempo fa e pubblicato adesso ha la data di adesso
        if let c = s.cliente("marco"),
           let ieri = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           let vecchioPiano = s.pianoPassiConRegole(frase, cliente: "marco", oggi: ieri) {
            let m = s.pubblicaPianoPassi(vecchioPiano, cliente: c, chiave: "marco", motore: MotoriVera.sintesi.nome)
            controlla(Date().timeIntervalSince(m.pianoPassi?.creatoIl ?? .distantPast) < 5,
                      "Ragiona a passi: la cascata parte quando il piano compare, non quando è iniziata la richiesta")
        }
        s.veraPortafoglio = false
    }
}
