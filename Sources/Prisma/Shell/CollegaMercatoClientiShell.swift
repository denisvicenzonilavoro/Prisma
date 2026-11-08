import Foundation

// «Il mercato per i tuoi clienti» nell'app (Vera/BRIEF.md, funzione 14, fase 4; motore in Vera/MercatoClientiVera.swift).
// Quando succede qualcosa sui mercati (detto a Vera in chat, oppure dalle serie e dagli avvisi di Mercato) Prisma dice
// quali clienti tocca, perché e cosa conviene fare con ciascuno; con «Prepara N messaggi» Qwen scrive le bozze nello
// stile del consulente (ogni cifra controllata, altrimenti resta la bozza di Prisma) e tutto arriva in una scheda
// «Conferma»: bozze in Messaggi e attività in agenda solo dopo la conferma, mai un invio.
// L'esito vive nel messaggio di Vera (MessaggioVera.mercatoClienti): entra nella conversazione salvata e nei backup,
// mai nell'istantanea di «Prisma ovunque» (le conversazioni non ci vanno). Nessun dato dei clienti esce dal Mac: Qwen è
// sul Mac e qui non si scarica niente. In modalità cliente niente: l'evento tocca tutti i clienti.
extension StatoShell {
    // MARK: - I dati del motore

    /// I dati del motore dai campi osservati (non l'istantanea intera): clienti, posizioni, obiettivi, agenda e analisi.
    func datiMercatoClientiVera(oggi: Date = Date()) -> DatiMercatoClienti {
        DatiMercatoClienti(oggi: oggi, clienti: dati.clienti, posizioni: dati.posizioni, obiettivi: dati.obiettivi,
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

    /// Lo stile delle bozze: oggi le firme di Impostazioni › Messaggi. «Scrive come te» (funzione 15) lo arricchisce
    /// qui con lo stile imparato (tratti, tono per cliente, chiusura): è l'unico punto da cambiare.
    func stileBozzeMercatoVera() -> StileBozzeVera {
        StileBozzeVera(messaggi: dati.impostazioni.messaggi)
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
    func chiediMercatoClienti(_ testo: String, chiave: String, oggi: Date = Date()) -> Bool {
        guard !inModoCliente, MercatoClientiVera.eUnEvento(testo) else { return false }
        let t = InterpreteComandi.pulisci(testo)
        guard DateItaliane.cerca(Self.verboAzioneMercatoClienti, t) == nil else { return false }
        let riconosciuto = MercatoClientiVera.riconosci(testo, oggi: oggi)
        if case .nessuno = riconosciuto { return false }
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
              let esito = ultima.mercatoClienti, !esito.toccati.isEmpty, ultima.mercatoBozze == nil else { return false }
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
        guard m.mercatoBozze == nil else { return mostraAvviso("Le bozze per questo evento sono già pronte nella conversazione.") }
        guard !veraInCorso else { return mostraAvviso("Vera sta ancora rispondendo: aspetta un attimo.") }
        let chiave = chiaveMessaggioMercatoClienti(id) ?? chiaveConversazione
        let clienti = dati.clienti
        let stile = stileBozzeMercatoVera()
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
        let clienti = dati.clienti
        var scheda = MercatoClientiVera.scheda(esito, bozze: bozze, clienti: clienti,
                                               richiesta: "\(esito.etichettaBozze) · \(esito.evento.titolo)", oggi: oggi)
        scheda.origine = .mercato
        // Il tono di ogni bozza (tu o Lei) va con la bozza in Messaggi
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for i in scheda.azioni.indices where scheda.azioni[i].strumento == RegistroStrumenti.messaggiPrepara {
            guard let c = scheda.azioni[i].argomenti["cliente"].flatMap({ perId[$0] }) else { continue }
            scheda.azioni[i].argomenti["tono"] = stile.tono(c, oggi: oggi).rawValue
        }
        let diVera = bozze.filter { $0.autore == .vera }.count
        let n = bozze.count
        var testo = n == 1 ? "Ho preparato la bozza" : "Ho preparato \(SchedaConfermaVera.numero(n)) bozze"
        if diVera == n {
            testo += " nel tuo stile, con le cifre di Prisma."
        } else if diVera == 0 {
            testo += " con il testo di Prisma: le cifre sono esatte, il tono lo puoi ritoccare tu."
        } else {
            testo += ": \(diVera) le ha scritte Vera nel tuo stile, le altre restano con il testo di Prisma."
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
    func preparaBozzeMercatoDaScena(_ esito: EsitoMercatoVera) {
        guard !inModoCliente, !solaLettura, !esito.toccati.isEmpty else { return }
        scenaMercatoClientiVera = nil
        veraPortafoglio = true
        let m = rispondiMercatoClienti(esito, chiave: VeraPortafoglio.chiave)
        apri(.vera)
        preparaBozzeMercatoClienti(messaggio: m.id)
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
