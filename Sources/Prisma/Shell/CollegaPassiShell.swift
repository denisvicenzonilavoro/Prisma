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

    /// «Marco ha 400 € al mese: protezione e studi, come li divido?», «ragiona a passi: …». true se l'ha gestita.
    func chiediPassi(_ testo: String, chiave: String) -> Bool {
        guard richiestaPassi(testo) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        guard let id = clienteDellaRichiesta(testo, chiave: chiave), let d = datiPassi(cliente: id) else {
            rispostaPassi("Di quale cliente divido il budget? Dimmi il nome, o apri il suo dossier.", chiave: chiave)
            return true
        }
        let r: RichiestaPassi
        switch PassiVera.capisci(testo, cliente: d.cliente, obiettivi: d.obiettivi) {
        case .domanda(let domanda):
            // Vera non inventa il budget né l'obiettivo: lo chiede
            rispostaPassi(domanda, chiave: chiave)
            return true
        case .richiesta(let capita):
            r = capita
        }
        guard let motore = qwenPerPassi else {
            // Senza Qwen (o con le risposte preparate): il piano delle regole e la bozza di Prisma, subito
            let piano = PassiVera.eseguiTutto(PassiVera.piano(r, dati: d), dati: d)
            pubblicaPianoPassi(piano, cliente: d.cliente, chiave: chiave, motore: MotoriVera.sintesi.nome,
                               senzaQwen: generativo == nil && !rispostePreparate)
            return true
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
        return true
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

    /// «Rifai i calcoli»: la stessa richiesta con i dati di adesso (le posizioni o gli obiettivi possono essere cambiati).
    /// Il piano delle regole, subito; con Qwen pronto passa dalla chat come una richiesta nuova.
    func rifaiPassi(_ piano: PianoPassi, chiave: String) {
        guard !veraInCorso else { return }
        if qwenPerPassi != nil, chiediPassi(piano.richiesta.testo, chiave: chiave) { return }
        guard let d = datiPassi(cliente: piano.richiesta.clienteId) else { return mostraAvviso("Il cliente non è più in Prisma.") }
        var r = piano.richiesta
        // Gli obiettivi tolti nel frattempo escono dalla richiesta
        r.obiettiviIds = r.obiettiviIds.filter { d.obiettivo($0) != nil }
        guard !r.obiettiviIds.isEmpty else { return mostraAvviso("Gli obiettivi della richiesta non sono più nel dossier.") }
        let nuovo = PassiVera.eseguiTutto(PassiVera.piano(r, dati: d), dati: d)
        pubblicaPianoPassi(nuovo, cliente: d.cliente, chiave: chiave, motore: MotoriVera.sintesi.nome,
                           senzaQwen: generativo == nil && !rispostePreparate)
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
