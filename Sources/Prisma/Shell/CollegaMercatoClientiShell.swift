import Foundation

// «Il mercato per i tuoi clienti» nell'app (Vera/BRIEF.md, funzione 14, fase 4; motore in Vera/MercatoClientiVera.swift).
// Quando succede qualcosa sui mercati (detto a Vera in chat, oppure dalle serie e dagli avvisi di Mercato) Prisma dice
// quali clienti tocca, perché e cosa conviene fare con ciascuno; con «Prepara N messaggi» Qwen scrive le bozze nello
// stile del consulente (ogni cifra controllata, altrimenti resta la bozza di Prisma) e tutto arriva in una scheda
// «Conferma»: bozze in Messaggi e attività in agenda solo dopo la conferma, mai un invio.
// L'esito vive nel messaggio di Vera (MessaggioVera.mercatoClienti): entra nella conversazione salvata e nei backup,
// mai nell'istantanea di «Prisma ovunque» (le conversazioni non ci vanno). Nessun dato dei clienti esce dal Mac: Qwen è
// sul Mac e qui non si scarica niente. In modalità cliente niente: l'evento tocca tutti i clienti. Per lo stesso motivo
// l'elenco e le bozze stanno sempre nella conversazione del portafoglio, mai nel dossier di un cliente (che si vede
// poi in modalità cliente).
extension StatoShell {
    // MARK: - I dati del motore

    /// I dati del motore dai campi osservati (non l'istantanea intera): clienti, posizioni, obiettivi, agenda e analisi.
    func datiMercatoClientiVera(oggi: Date = Date()) -> DatiMercatoClienti {
        DatiMercatoClienti(oggi: oggi, clienti: clientiAttivi, posizioni: dati.posizioni, obiettivi: dati.obiettivi,
                           appuntamenti: dati.appuntamenti, analisi: dati.analisi)
    }

    /// I clienti che un evento tocca, con motivo, azione e cifre di Prisma.
    func esitoMercatoClientiVera(_ e: EventoMercatoVera, oggi: Date = Date()) -> EsitoMercatoVera {
        MercatoClientiVera.toccati(e, dati: datiMercatoClientiVera(oggi: oggi))
    }

    /// Gli eventi che i dati di Mercato dicono oggi: le serie (BCE, Eurostat, CSV) e gli avvisi di variazione di una
    /// serie, senza doppioni (stesso tipo, giorno e misura), dal più recente.
    func eventiMercatoClientiVera(oggi: Date = Date()) -> [EventoMercatoVera] {
        let archivio = dati.mercato
        var elenco = MercatoClientiVera.eventi(archivio: archivio, impostazioni: dati.impostazioni.mercato, oggi: oggi)
        var visti = Set(elenco.map(\.id))
        for a in archivio.avvisi where a.stato == .nuovo {
            guard let e = MercatoClientiVera.evento(da: a, archivio: archivio), visti.insert(e.id).inserted else { continue }
            elenco.append(e)
        }
        return elenco.sorted { $0.data != $1.data ? $0.data > $1.data : $0.id < $1.id }
    }

    /// Lo stile delle bozze: le firme di Impostazioni › Messaggi, arricchite dal profilo di «Scrive come te»
    /// (funzione 15) quando non è vuoto: tu o Lei per ogni cliente, firma, chiusura e tratti da dire a Qwen.
    func stileBozzeMercatoVera(oggi: Date = Date()) -> StileBozzeVera {
        Self.stileBozzeMercato(messaggi: dati.impostazioni.messaggi, profilo: dati.impostazioni.stileVera,
                               clienti: clientiAttivi, oggi: oggi)
    }

    /// Lo stile delle bozze dai dati (senza lo stato, per le prove).
    static func stileBozzeMercato(messaggi: ImpostazioniMessaggi, profilo p: ProfiloStile, clienti: [Cliente],
                                  oggi: Date) -> StileBozzeVera {
        var s = StileBozzeVera(messaggi: messaggi)
        guard !p.vuoto else { return s }
        // Il tu o Lei del profilo, cliente per cliente (cordiale se il profilo non dice niente)
        if p.cortesia?.attiva == true {
            for c in clienti { s.toni[c.id] = StileVera.tono(p, cliente: c, oggi: oggi, richiesto: s.tonoPredefinito) }
        }
        if let f = StileVera.firma(p) {
            s.firmaAlleanza = f
            s.firmaIndipendente = f
        }
        if let r = p.chiusure, r.attiva, let prima = r.valore.first?.trimmingCharacters(in: .whitespacesAndNewlines), !prima.isEmpty {
            s.chiusura = prima
        }
        // Le regole di forma per Qwen; il tu o Lei è già nella scheda di ogni cliente
        s.tratti = StileVera.istruzioni(p, cliente: nil, oggi: oggi, clienteNuovo: false)
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix("- ") }
            .map { String($0.dropFirst(2)) }
            .filter { !$0.hasPrefix("Dai del") }
        return s
    }

    /// Ogni bozza della scheda prende la forma del profilo (saluto, chiusura, firma, via emoji e formule vietate) e
    /// passa la verifica: una regola grave ancora violata diventa l'avviso della riga. Con il profilo vuoto niente cambia.
    static func bozzeMercatoInStile(_ scheda: inout SchedaConfermaVera, clienti: [Cliente], contesto x: ContestoStrumenti) {
        guard !x.impostazioni.stileVera.vuoto else { return }
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for i in scheda.azioni.indices where scheda.azioni[i].strumento == RegistroStrumenti.messaggiPrepara {
            guard let c = scheda.azioni[i].argomenti["cliente"].flatMap({ perId[$0] }),
                  let testo = scheda.azioni[i].argomenti["testo"], !testo.isEmpty else { continue }
            let canale = CanaleMessaggio(rawValue: scheda.azioni[i].argomenti["canale"] ?? "") ?? .messaggi
            let stile = RegistroStrumenti.messaggioInStile(testo, cliente: c, contesto: x)
            if stile.testo != testo {
                scheda.azioni[i].argomenti["testo"] = stile.testo
                scheda.azioni[i].dettaglio = RegistroStrumenti.dettaglioMessaggio(stile.testo, canale: canale)
            }
            if scheda.azioni[i].avviso == nil, let avviso = stile.avviso { scheda.azioni[i].avviso = avviso }
        }
    }

    /// Le bozze di quell'elenco sono pronte solo se la loro scheda c'è ancora ed è da confermare o eseguita: lasciata
    /// stare, sostituita, annullata o sparita, le bozze si possono rifare.
    func bozzeMercatoPronte(_ m: MessaggioVera) -> Bool {
        guard let id = m.mercatoBozze, let s = messaggioVera(id)?.conferma else { return false }
        return s.stato == .daConfermare || s.stato == .eseguita
    }

    /// L'ultimo elenco dello stesso evento nella conversazione del portafoglio (per non rifarlo dalla scena).
    func elencoMercatoClienti(evento: String) -> MessaggioVera? {
        conversazione(VeraPortafoglio.chiave).last { $0.autore == .vera && $0.mercatoClienti?.evento.id == evento }
    }

    /// Qwen scrive le bozze solo se è pronto (e mai nelle prove e nelle istantanee con le risposte preparate).
    private var qwenPerMercatoClienti: MotoreLocale? { generativo != nil && !rispostePreparate ? qwen : nil }

    // MARK: - In chat

    /// Le frasi d'azione («Scrivi a Marco che le borse sono scese dell'8%») restano di «Fallo tu».
    static let verboAzioneMercatoClienti = #"^(?:scrivi|manda|invia|spedisci|inoltra|gira|prepara|fissa|chiama|telefona|sposta|aggiungi|crea|avvisa)(?:mi|gli|le|ci|lo|la|li|glielo|gliela|glieli)?\b"#

    /// «Prepara i messaggi», «sì, prepara le bozze», «prepara 3 messaggi» subito dopo un elenco di Vera.
    static let richiestaBozzeMercatoClienti = #"^(?:s[iì][,!.]?\s*)?(?:(?:prepara|scrivi)(?:mi|li|le)?|fammi)\s+(?:(?:pure|tu|subito)\s+)?(?:le\s+bozze|i\s+messaggi|(?:i\s+)?(?:\d+|due|tre|quattro|cinque|sei|sette|otto|nove|dieci)\s+messaggi|il\s+messaggio|la\s+bozza)(?:\s+(?:per\s+(?:loro|tutti|i\s+clienti)|ai\s+clienti))?\s*[.!]?$"#

    /// «Le borse hanno perso l'8% in una settimana», «la BCE taglia i tassi di 25 punti base», «l'inflazione sale al 3%»:
    /// le regole riconoscono l'evento, Prisma calcola chi tocca. Un evento a metà («la BCE ha tagliato i tassi») fa la
    /// domanda che manca. true se l'ha gestita.
    /// La `chiave` ricevuta non conta: l'evento tocca tutti i clienti, quindi domanda e risposta vanno nel portafoglio
    /// (come «Chiedi alla tua clientela»), mai nel dossier del cliente aperto.
    func chiediMercatoClienti(_ testo: String, chiave _: String, oggi: Date = Date()) -> Bool {
        guard !inModoCliente, MercatoClientiVera.eUnEvento(testo) else { return false }
        let t = InterpreteComandi.pulisci(testo)
        guard DateItaliane.cerca(Self.verboAzioneMercatoClienti, t) == nil else { return false }
        let riconosciuto = MercatoClientiVera.riconosci(testo, oggi: oggi)
        if case .nessuno = riconosciuto { return false }
        let chiave = VeraPortafoglio.chiave
        veraPortafoglio = true
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        switch riconosciuto {
        case .evento(let e):
            rispondiMercatoClienti(esitoMercatoClientiVera(e, oggi: oggi), chiave: chiave)
        case .incompleto(let tipo, let domanda):
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: domanda, titolo: tipo.nome, motore: MotoriVera.sintesi.nome), cliente: chiave)
        case .nessuno:
            break
        }
        return true
    }

    /// La risposta con l'elenco dei clienti toccati sotto la bolla. Il testo è breve (l'elenco è nella scheda); senza
    /// clienti toccati resta il testo intero di Prisma.
    @discardableResult
    func rispondiMercatoClienti(_ esito: EsitoMercatoVera, chiave: String) -> MessaggioVera {
        var m = MessaggioVera(autore: .vera, testo: Self.testoBreveMercatoClienti(esito), titolo: esito.evento.titolo,
                              motore: MotoriVera.sintesi.nome)
        m.mercatoClienti = esito
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    /// «La BCE taglia… Conti deposito e liquidità renderanno meno. Tocca 4 dei tuoi clienti: per ognuno trovi il
    /// motivo e cosa fare.» Le cifre sono tutte di Prisma (nell'elenco).
    static func testoBreveMercatoClienti(_ esito: EsitoMercatoVera) -> String {
        guard !esito.toccati.isEmpty else { return MercatoClientiVera.testoChat(esito) }
        var righe = ["\(esito.sintesi) \(esito.intestazione): per ognuno trovi il motivo e cosa conviene fare."]
        if esito.toccati.contains(where: \.speseStimate),
           esito.toccati.contains(where: { $0.motivi.contains { m in m.regola == .liquiditaFerma || m.regola == .contoDeposito } }) {
            righe.append("Per chi non ha l'analisi 360 salvata i mesi di spese usano il fabbisogno predefinito.")
        }
        righe.append("Le cifre sono di Prisma. Se vuoi preparo le bozze dei messaggi: le apri e le mandi tu.")
        return righe.joined(separator: "\n")
    }

    /// «Prepara i messaggi» scritto in chat subito dopo un elenco di Vera senza bozze. true se l'ha gestita.
    func chiediBozzeMercatoClienti(_ testo: String, chiave: String) -> Bool {
        guard !inModoCliente else { return false }
        let t = InterpreteComandi.pulisci(testo)
        guard DateItaliane.cerca(Self.richiestaBozzeMercatoClienti, t) != nil,
              let ultima = conversazione(chiave).last(where: { $0.autore == .vera }),
              let esito = ultima.mercatoClienti, !esito.toccati.isEmpty, !bozzeMercatoPronte(ultima) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        preparaBozzeMercatoClienti(messaggio: ultima.id)
        return true
    }

    // MARK: - Le bozze e la scheda «Conferma»

    /// La conversazione che contiene un messaggio di Vera (nil se non c'è più).
    func chiaveMessaggioMercatoClienti(_ id: String) -> String? {
        if dati.impostazioni.vera.conservaConversazioni {
            for (chiave, elenco) in dati.conversazioni where elenco.contains(where: { $0.id == id }) { return chiave }
        }
        for (chiave, elenco) in conversazioniTemporanee where elenco.contains(where: { $0.id == id }) { return chiave }
        return nil
    }

    /// «Prepara N messaggi» sotto l'elenco: Qwen scrive le bozze (a gruppi, con il controllo di ogni cifra), poi la
    /// scheda «Conferma» con le bozze per Messaggi e le attività. Senza Qwen restano le bozze fisse di Prisma, con
    /// l'avviso. Niente si esegue qui.
    func preparaBozzeMercatoClienti(messaggio id: String, oggi: Date = Date()) {
        guard !inModoCliente, !solaLettura else { return }
        guard let m = messaggioVera(id), let esito = m.mercatoClienti, !esito.toccati.isEmpty else {
            return mostraAvviso("L'elenco dei clienti non è più nella conversazione.")
        }
        guard !bozzeMercatoPronte(m) else { return mostraAvviso("Le bozze per questo evento sono già pronte nella conversazione.") }
        guard !veraInCorso else { return mostraAvviso("Vera sta ancora rispondendo: aspetta un attimo.") }
        let chiave = chiaveMessaggioMercatoClienti(id) ?? VeraPortafoglio.chiave
        let clienti = clientiAttivi
        let stile = stileBozzeMercatoVera(oggi: oggi)
        guard let motore = qwenPerMercatoClienti else {
            // Senza Qwen: le bozze fisse di Prisma, subito
            let motivo = rispostePreparate ? nil : MotoriVera.qwen(dati.impostazioni.vera, locale: disponibilitaLocale).disponibilita.motivo
            let bozze = MercatoClientiVera.bozze(esito, clienti: clienti, stile: stile, json: nil, motivoNonPronta: motivo, oggi: oggi)
            rispondiBozzeMercatoClienti(esito, bozze: bozze, stile: stile, origine: id, chiave: chiave, motore: MotoriVera.sintesi.nome, oggi: oggi)
            return
        }
        let vera = dati.impostazioni.vera
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let bozze = await MercatoClientiVera.scrivi(esito, clienti: clienti, stile: stile, motore: motore, vera: vera, oggi: oggi)
            guard !Task.isCancelled else { return }
            self.rispondiBozzeMercatoClienti(esito, bozze: bozze, stile: stile, origine: id, chiave: chiave, motore: motore.nome, oggi: oggi)
            self.veraInCorso = false
            self.compitoVera = nil
        }
    }

    /// La scheda «Conferma» con le bozze e le attività, nella conversazione dell'elenco; l'elenco ricorda la scheda
    /// («Bozze pronte ✓»).
    @discardableResult
    func rispondiBozzeMercatoClienti(_ esito: EsitoMercatoVera, bozze: [BozzaMercatoVera], stile: StileBozzeVera, origine: String,
                                     chiave: String, motore: String, oggi: Date = Date()) -> MessaggioVera {
        let clienti = clientiAttivi
        var scheda = MercatoClientiVera.scheda(esito, bozze: bozze, clienti: clienti,
                                               richiesta: "\(esito.etichettaBozze) · \(esito.evento.titolo)", oggi: oggi)
        scheda.origine = .mercato
        // Il tono di ogni bozza (tu o Lei) va con la bozza in Messaggi
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for i in scheda.azioni.indices where scheda.azioni[i].strumento == RegistroStrumenti.messaggiPrepara {
            guard let c = scheda.azioni[i].argomenti["cliente"].flatMap({ perId[$0] }) else { continue }
            scheda.azioni[i].argomenti["tono"] = stile.tono(c, oggi: oggi).rawValue
        }
        // «Scrive come te» (funzione 15): ogni bozza segue il profilo, come quelle di «Fallo tu»
        var x = contestoStrumenti
        x.oggi = oggi
        Self.bozzeMercatoInStile(&scheda, clienti: clienti, contesto: x)
        // Una bozza per lo stesso cliente ed evento già in Messaggi: la riga lo dice, così non si raddoppia senza saperlo
        for i in scheda.azioni.indices where scheda.azioni[i].strumento == RegistroStrumenti.messaggiPrepara {
            let arg = scheda.azioni[i].argomenti
            guard let c = arg["cliente"], let evento = arg["evento"] else { continue }
            let occasione = "\(TipoOccasioneMessaggio.avvisoMercato.rawValue)-\(c)-\(evento)"
            if dati.messaggi.contains(where: { $0.occasioneId == occasione && $0.stato == .bozza }) {
                // Nasce già tolta: «Fallo tu» rifiuta comunque la bozza doppia
                scheda.azioni[i].avviso = "In Messaggi c'è già una bozza per questo evento: questa riga non ne crea un'altra."
                scheda.azioni[i].tolta = true
            }
        }
        let conProfilo = !dati.impostazioni.stileVera.vuoto
        let diVera = bozze.filter { $0.autore == .vera }.count
        let n = bozze.count
        var testo = n == 1 ? "Ho preparato la bozza" : "Ho preparato \(SchedaConfermaVera.numero(n)) bozze"
        if diVera == n {
            testo += conProfilo ? " nel tuo stile, con le cifre di Prisma." : ", scritte da Vera con le cifre di Prisma."
        } else if diVera == 0 {
            testo += conProfilo ? " con il testo di Prisma, nella forma del tuo stile: le cifre sono esatte, il tono lo puoi ritoccare tu."
                                : " con il testo di Prisma: le cifre sono esatte, il tono lo puoi ritoccare tu."
        } else {
            testo += ": \(diVera) " + (conProfilo ? "le ha scritte Vera nel tuo stile" : "le ha scritte Vera") + ", le altre restano con il testo di Prisma."
        }
        testo += " Le metto in Messaggi e segno le attività solo con «Conferma»: le apri e le spedisci tu."
        var m = MessaggioVera(autore: .vera, testo: testo, titolo: esito.etichettaBozze, motore: diVera > 0 ? motore : Self.motoreAzioni)
        m.conferma = scheda
        aggiungiMessaggio(m, cliente: chiave)
        let nuovo = m.id
        aggiornaMessaggioVera(origine) { $0.mercatoBozze = nuovo }
        return m
    }

    // MARK: - Dalla scena di Mercato

    /// Apre la scena «Per i tuoi clienti» in Mercato; `scelta` è l'evento da mostrare (nil = il primo).
    func apriMercatoClientiVera(scelta: String? = nil) {
        guard !inModoCliente else { return }
        scenaMercatoClientiVera = scelta ?? ""
        apri(.mercato)
    }

    func chiudiMercatoClientiVera() {
        scenaMercatoClientiVera = nil
    }

    /// «Prepara N messaggi» dalla scena: l'elenco e le bozze vanno nella conversazione del portafoglio di Vera, dove
    /// c'è la scheda «Conferma».
    /// Se l'evento ha già un elenco nel portafoglio: con le bozze pronte lo dice; lo riusa solo se ha gli stessi
    /// clienti e le stesse cifre dell'esito appena mostrato (l'id dell'evento di una serie resta uguale per settimane),
    /// altrimenti aggiunge un elenco nuovo con l'esito di adesso e prepara le bozze su quello.
    func preparaBozzeMercatoDaScena(_ esito: EsitoMercatoVera) {
        guard !inModoCliente, !solaLettura, !esito.toccati.isEmpty else { return }
        scenaMercatoClientiVera = nil
        veraPortafoglio = true
        if let gia = elencoMercatoClienti(evento: esito.evento.id) {
            if bozzeMercatoPronte(gia) {
                if !aperta(.vera) { apri(.vera) }
                return mostraAvviso("Le bozze per questo evento sono già pronte nella conversazione.")
            }
            if let v = gia.mercatoClienti, StatoShell.stessoEsitoMercato(v, esito) {
                if !aperta(.vera) { apri(.vera) }
                return preparaBozzeMercatoClienti(messaggio: gia.id)
            }
        }
        let m = rispondiMercatoClienti(esito, chiave: VeraPortafoglio.chiave)
        apri(.vera)
        preparaBozzeMercatoClienti(messaggio: m.id)
    }

    /// Due esiti con gli stessi clienti toccati e le stesse cifre (il momento del calcolo non conta). Un elenco senza
    /// clienti toccati vale come assente.
    nonisolated static func stessoEsitoMercato(_ a: EsitoMercatoVera, _ b: EsitoMercatoVera) -> Bool {
        !a.toccati.isEmpty && a.toccati == b.toccati && a.oltre == b.oltre && a.evento == b.evento && a.sintesi == b.sintesi
    }

    /// Gli eventi della scena: prima quelli dei dati di Mercato, poi i tre esempi del template (tassi giù, inflazione su,
    /// borse −8%), segnati «Esempio»: con un esempio si guarda chi toccherebbe, le bozze no.
    func scelteMercatoClientiVera(oggi: Date = Date()) -> [SceltaMercatoClientiVera] {
        let dalMercato = eventiMercatoClientiVera(oggi: oggi).map {
            SceltaMercatoClientiVera(id: $0.id, etichetta: SceltaMercatoClientiVera.etichettaBreve($0), evento: $0, esempio: false)
        }
        return dalMercato + SceltaMercatoClientiVera.esempi(oggi: oggi)
    }
}

/// Un evento che la scena di Mercato propone: dai dati o un esempio.
struct SceltaMercatoClientiVera: Identifiable, Equatable {
    var id: String
    /// La voce del segmentato: «Tassi BCE −0,25», «Borse −8%», «Tassi BCE giù».
    var etichetta: String
    var evento: EventoMercatoVera
    /// Un esempio del template, non un dato: niente bozze ai clienti.
    var esempio: Bool

    static let idTassi = "esempio-tassi"
    static let idInflazione = "esempio-inflazione"
    static let idBorse = "esempio-borse"

    static func etichettaBreve(_ e: EventoMercatoVera) -> String {
        let n = TestiMercatoClienti.numero(abs(e.misura))
        let segno = e.misura < 0 ? "\u{2212}" : "+"
        switch e.tipo {
        case .tassiBCE: return "Tassi BCE \(segno)\(n)"
        case .inflazione: return "Inflazione \(n)%"
        case .borse: return "Borse \(segno)\(n)%"
        }
    }

    static func esempi(oggi: Date, cal: Calendar = .current) -> [SceltaMercatoClientiVera] {
        let fonte = "Esempio di Prisma"
        return [
            SceltaMercatoClientiVera(id: idTassi, etichetta: "Tassi BCE giù",
                                     evento: EventoMercatoVera(tipo: .tassiBCE, misura: -0.25, verso: -1, origine: .aParole, fonte: fonte, data: oggi, cal: cal),
                                     esempio: true),
            SceltaMercatoClientiVera(id: idInflazione, etichetta: "Inflazione su",
                                     evento: EventoMercatoVera(tipo: .inflazione, misura: 3, verso: 1, origine: .aParole, fonte: fonte, data: oggi, cal: cal),
                                     esempio: true),
            SceltaMercatoClientiVera(id: idBorse, etichetta: "Borse \u{2212}8%",
                                     evento: EventoMercatoVera(tipo: .borse, misura: -8, verso: -1, periodo: "in una settimana", origine: .aParole,
                                                               fonte: fonte, data: oggi, cal: cal),
                                     esempio: true),
        ]
    }
}
