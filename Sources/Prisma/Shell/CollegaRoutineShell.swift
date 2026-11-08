import Foundation

// «Le routine» di Vera nell'app (Vera/BRIEF.md, funzione 3; motore in Vera/RoutineVera.swift): le sequenze salvate si
// lanciano con una frase in chat («Vera, prepara l'incontro con Marco»), dalla pagina delle routine, da sole all'ora
// scelta (solo con Prisma aperto) o dopo una firma. Il motore legge una copia dei dati e prepara le azioni; qui si
// mostra il risultato in chat con la scheda «Conferma» e, dopo «Conferma», si eseguono i due strumenti nuovi
// (segnare in essere la proposta firmata, salvare una routine nuova). Niente cambia senza «Conferma»; le cifre sono
// quelle dei motori di Prisma; Qwen serve solo a capire a parole una routine nuova (con le regole prima).
extension StatoShell {
    // MARK: - Lettura

    /// Le routine da mostrare: le quattro pronte (con il loro stato) e quelle del consulente.
    var routineTutte: [RoutineVera] { dati.routine.tutte }

    func routineVera(_ id: String) -> RoutineVera? { dati.routine.tutte.first { $0.id == id } }

    /// L'ultimo lancio di una routine (nil se non è mai partita o se l'esito è uscito dagli ultimi venti).
    func ultimoEsitoRoutine(_ routineId: String) -> EsitoRoutine? {
        dati.routine.esiti.last { $0.routineId == routineId && routineVisibile($0) }
    }

    /// In modalità cliente si vedono solo i lanci sul cliente davanti a te (mai quelli di tutto il portafoglio).
    func routineVisibile(_ e: EsitoRoutine) -> Bool {
        guard inModoCliente else { return true }
        return e.clienteId == clienteAttivoId
    }

    /// Qwen si usa solo se è pronto (e non nelle prove con le risposte preparate).
    private var qwenPerRoutine: MotoreLocale? { generativo != nil && !rispostePreparate ? qwen : nil }

    // MARK: - La pagina delle routine

    /// Apre la pagina delle routine dentro Vera, sulla routine data (o sull'ultima scelta).
    func apriPaginaRoutine(_ id: String? = nil) {
        routineSelezionataVera = id ?? routineSelezionataVera ?? RoutineVera.idPrepara
        if !aperta(.vera) { apri(.vera) }
        paginaRoutineVera = true
    }

    func chiudiPaginaRoutine() {
        paginaRoutineVera = false
    }

    /// Accende o spegne una routine (anche una pronta: la copia salvata ne tiene lo stato). È il consulente che lo fa
    /// dall'interruttore della pagina, non Vera.
    func impostaRoutineAttiva(_ id: String, _ attiva: Bool) {
        guard !solaLettura, !inModoCliente, var r = routineVera(id), r.attiva != attiva else { return }
        r.attiva = attiva
        if let i = dati.routine.routine.firstIndex(where: { $0.id == id }) {
            dati.routine.routine[i] = r
        } else {
            dati.routine.routine.append(r)
        }
    }

    /// Toglie una routine del consulente (le pronte non si tolgono: si spengono). I suoi lanci passati restano.
    func eliminaRoutine(_ id: String) {
        guard !solaLettura, !inModoCliente, let r = routineVera(id), !r.pronta else { return }
        dati.routine.routine.removeAll { $0.id == id }
        if routineSelezionataVera == id { routineSelezionataVera = RoutineVera.idPrepara }
        mostraAvviso("La routine «\(r.titolo)» è tolta")
    }

    /// «Lancia ora» dalla pagina: per un cliente (le routine che lavorano su un cliente) o sul portafoglio. La pagina
    /// si chiude e la risposta, con la scheda «Conferma», compare nella conversazione giusta.
    func lanciaRoutineDaPagina(_ id: String, cliente clienteId: String?, oggi: Date = Date()) {
        guard !veraInCorso, let r = routineVera(id) else { return }
        let chiave: String
        if inModoCliente && !Self.tuttaSulCliente(r) {
            return mostraAvviso("In modalità cliente lancio solo le routine fatte tutte di passi sul cliente davanti a te.")
        }
        if let c = clienteId {
            guard visibileAlCliente(c), cliente(c) != nil else { return mostraAvviso("In modalità cliente lancio solo le routine sul cliente davanti a te.") }
            if !inModoCliente { clienteAttivoId = c }
            veraPortafoglio = false
            chiave = c
        } else {
            guard !inModoCliente else { return mostraAvviso("In modalità cliente lancio solo le routine sul cliente davanti a te.") }
            veraPortafoglio = true
            chiave = VeraPortafoglio.chiave
        }
        let chi = clienteId.flatMap { cliente($0)?.nome }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "Lancia «\(r.titolo)»" + (chi.map { " per \($0)" } ?? "")), cliente: chiave)
        paginaRoutineVera = false
        lanciaRoutine(r, richiesta: r.frase.isEmpty ? r.titolo : r.frase, clienteId: clienteId, chiave: chiave, oggi: oggi)
    }

    /// Un pulsante sotto il risultato («Apri in Incontri», «Apri Studio»): apre l'app, sul cliente se c'è. Il messaggio
    /// per il cliente nasce solo con «Conferma»: finché la scheda aspetta, Vera lo ricorda invece di aprire Messaggi vuota.
    func apriPulsanteRoutine(_ p: PulsanteRoutine, messaggio: String?) {
        if p.app == .messaggi, let id = messaggio, let s = messaggioVera(id)?.conferma, s.stato == .daConfermare,
           s.attive.contains(where: { $0.strumento == RegistroStrumenti.messaggiPrepara }) {
            return mostraAvviso("Prima conferma la bozza nella scheda «Conferma»: poi la trovi in Messaggi")
        }
        if let c = p.clienteId, cliente(c) != nil {
            guard visibileAlCliente(c) else { return }
            if !inModoCliente { clienteAttivoId = c }
        }
        paginaRoutineVera = false
        apri(p.app)
    }

    // MARK: - Il lancio

    /// Esegue una routine su una copia dei dati (il motore non cambia niente), registra il lancio (le volte e l'ultimo
    /// esito) e risponde in chat con i passi spuntati, il risultato e la scheda «Conferma» delle azioni preparate.
    /// Senza il cliente che serve, Vera lo chiede e non registra niente.
    @discardableResult
    func lanciaRoutine(_ r: RoutineVera, richiesta: String, clienteId: String?, posizioneId: String? = nil, file: String? = nil,
                       chiave: String, oggi: Date = Date(), parla: Bool = true) -> EsitoRoutine {
        var d = dati.istantanea
        // In modalità cliente il motore vede solo il cliente davanti a te: clienti, agenda, attività, promesse,
        // posizioni, documenti, messaggi e incontri (le routine con passi fuori dal cliente non partono, vedi
        // `tuttaSulCliente`: il filtro è la seconda difesa)
        if inModoCliente {
            let id = clienteAttivoId
            d.clienti = d.clienti.filter { $0.id == id }
            d.appuntamenti = d.appuntamenti.filter { $0.clienteId == id }
            d.attivita = d.attivita.filter { $0.clienteId == id }
            d.promesse = d.promesse.filter { $0.clienteId == id }
            d.posizioni = d.posizioni.filter { $0.clienteId == id }
            d.documenti = d.documenti.filter { $0.clienteId == id }
            d.messaggi = d.messaggi.filter { $0.clienteId == id }
            d.incontri = d.incontri.filter { $0.clienteId == id }
        }
        let contesto = ContestoRoutine(dati: d, oggi: oggi, clienteId: clienteId, posizioneId: posizioneId, file: file)
        let esito = RoutineVera.esegui(r, richiesta: richiesta, contesto: contesto)
        if esito.domanda == nil, !solaLettura {
            dati.routine = RoutineVera.registra(esito, in: dati.routine)
        }
        var m = MessaggioVera(autore: .vera, testo: Self.testoRoutine(esito), titolo: r.titolo,
                              motore: esito.azioni.isEmpty ? MotoriVera.sintesi.nome : Self.motoreAzioni)
        m.esitoRoutine = esito
        m.conferma = self.inStile(esito.schedaConferma)
        aggiungiMessaggio(m, cliente: chiave, parla: parla)
        return esito
    }

    /// true se ogni passo lavora sul cliente: le sole routine che partono in modalità cliente (le altre guardano anche
    /// l'agenda o il portafoglio del consulente).
    static func tuttaSulCliente(_ r: RoutineVera) -> Bool {
        !r.passi.isEmpty && !r.passi.contains { !$0.tipo.serveCliente }
    }

    /// Il testo della risposta sopra i passi: la domanda, oppure quante azioni aspettano «Conferma».
    static func testoRoutine(_ e: EsitoRoutine) -> String {
        if let d = e.domanda {
            return d == "Per quale cliente?" ? "Per quale cliente lancio «\(e.titolo)»? Dimmi il nome, o apri il suo dossier." : d
        }
        let fatti = e.passi.filter { $0.stato == .fatto || $0.stato == .vuoto || $0.stato == .daConfermare }.count
        var t = fatti == e.passi.count ? "Ecco «\(e.titolo)», passo per passo." : "Ecco «\(e.titolo)»: \(fatti) passi su \(e.passi.count), gli altri te li segnalo."
        switch e.azioni.count {
        case 0: break
        case 1: t += " L'azione che cambia qualcosa in Prisma aspetta la tua «Conferma»."
        default: t += " Le \(SchedaConfermaVera.numero(e.azioni.count)) azioni che cambiano qualcosa in Prisma aspettano la tua «Conferma»."
        }
        return t
    }

    // MARK: - La chat

    /// Le frasi delle routine (in `smistaVera`, prima dei comandi a regole): la risposta a «Per quale cliente?»,
    /// «le mie routine», una routine nuova a parole e il lancio di una routine riconosciuta. true se l'ha gestita.
    func chiediRoutine(_ testo: String, chiave: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        guard !t.isEmpty else { return false }
        if completaRoutineInSospeso(testo, chiave: chiave) { return true }
        if Self.eUnElencoRoutine(t) {
            aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
            domandaVera = ""
            let n = routineTutte.filter(\.attiva).count
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "Ecco le tue routine: \(n == 1 ? "una attiva" : "\(n) attive"). Le lanci con la loro frase, o da qui con «Lancia ora».",
                                            titolo: "Le routine", motore: MotoriVera.sintesi.nome), cliente: chiave)
            apriPaginaRoutine()
            return true
        }
        if Self.eUnaRoutineNuova(testo, t) {
            guard !inModoCliente else {
                aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
                domandaVera = ""
                aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "In modalità cliente non creo routine: lo faccio quando torni alla tua scrivania.",
                                                motore: Self.motoreAzioni), cliente: chiave)
                return true
            }
            proponiRoutineNuova(testo, chiave: chiave)
            return true
        }
        // Un comando («fissa un incontro con Marco a fine mese») o un documento («preparami il fascicolo per
        // l'incontro») resta ai comandi di sempre
        guard DateItaliane.cerca(Self.esclusioniRoutine, t) == nil, DateItaliane.cerca(Self.comandiNonRoutine, t) == nil else { return false }
        let clienti = inModoCliente ? dati.clienti.filter { $0.id == clienteAttivoId } : dati.clienti
        let noti = clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let attivo: String? = inModoCliente ? clienteAttivoId : (chiave != VeraPortafoglio.chiave && cliente(chiave) != nil ? chiave : nil)
        // Le domande sulle promesse e sulle scadenze («quali promesse scadono a fine mese?») restano ai loro motori
        guard !Self.eUnaDomandaNonRoutine(t) else { return false }
        guard let l = RoutineVera.riconosci(testo, routine: routineTutte, clienti: noti, attivo: attivo) else { return false }
        // La firma si annuncia: «l'ha firmato?», «cosa ho promesso dopo la firma», «il contratto firmato con…» no
        if l.routine.programmazione?.tipo == .dopoFirma, Self.nonEUnAnnuncioDiFirma(testo, t) { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        if inModoCliente && !Self.tuttaSulCliente(l.routine) {
            let perche = l.routine.serveCliente ? "guarda anche l'agenda o il portafoglio" : "guarda tutto il portafoglio"
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "In modalità cliente lancio solo le routine sul cliente davanti a te: «\(l.routine.titolo)» \(perche).",
                                            motore: Self.motoreAzioni), cliente: chiave)
            return true
        }
        lanciaRoutine(l.routine, richiesta: testo, clienteId: l.clienteId, chiave: chiave)
        return true
    }

    /// Dopo «Per quale cliente?»: una frase che nomina un solo cliente rilancia la stessa routine per lui.
    func completaRoutineInSospeso(_ testo: String, chiave: String) -> Bool {
        guard let m = conversazione(chiave).last, m.autore == .vera, let e = m.esitoRoutine, e.domanda != nil,
              let r = routineVera(e.routineId) else { return false }
        // Un comando, un documento, un elenco, una routine nuova o un'altra routine non sono la risposta: restano ai
        // loro motori (anche se nominano un solo cliente)
        let t = InterpreteComandi.pulisci(testo)
        guard Self.rispostaBreve(t),
              DateItaliane.cerca(Self.comandiNonRoutine, t) == nil, DateItaliane.cerca(Self.esclusioniRoutine, t) == nil,
              !Self.eUnaRoutineNuova(testo, t), !Self.eUnElencoRoutine(t), !Self.eUnaDomandaNonRoutine(t),
              !routineTutte.contains(where: { $0.attiva && $0.id != r.id && $0.inneschi.contains { DateItaliane.cerca($0, t) != nil } })
        else { return false }
        let clienti = inModoCliente ? dati.clienti.filter { $0.id == clienteAttivoId } : dati.clienti
        let nominati = InterpreteComandi.clientiNominati(InterpreteComandi.pulisci(testo), clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) })
        guard nominati.count == 1 else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        lanciaRoutine(r, richiesta: e.richiesta, clienteId: nominati[0].id, chiave: chiave)
        return true
    }

    /// «Le mie routine», «mostrami le routine», «quali routine ho?».
    static func eUnElencoRoutine(_ t: String) -> Bool {
        DateItaliane.cerca(#"\broutine\b"#, t) != nil
            && DateItaliane.cerca(creaRoutine, t) == nil
            && (DateItaliane.cerca(#"^(?:mi )?(?:mostra(?:mi)?|apri(?:mi)?|vedi|fammi vedere|elenca(?:mi)?|quali|che)\b"#, t) != nil
                || DateItaliane.cerca(#"^(?:le )?(?:mie )?routine$"#, t) != nil)
    }

    /// «Crea una routine…», «nuova routine: …» (anche con Qwen), oppure «ogni volta che firmo, archivia il contratto e
    /// fissa il controllo a sei mesi» quando le regole ci trovano già la programmazione e almeno un passo.
    static func eUnaRoutineNuova(_ testo: String, _ t: String) -> Bool {
        if DateItaliane.cerca(creaRoutine, t) != nil { return true }
        guard DateItaliane.cerca(#"^(?:ogni volta che|quando firmo|dopo ogni firma|appena firmo|ogni (?:luned[iì]|marted[iì]|mercoled[iì]|gioved[iì]|venerd[iì]|sabato|domenica)|a fine mese|alla fine (?:di ogni|del) mese|l'ultimo giorno del mese)\b"#, t) != nil
        else { return false }
        return RoutineVera.programmazioneDa(testo) != nil && !RoutineVera.passiDa(testo).isEmpty
    }

    /// La risposta a «Per quale cliente?» è breve: il nome, al più con «per», «con», «di» e la cortesia («per Marco»,
    /// «Marco Rossi», «quello di Giulia Verdi»).
    static func rispostaBreve(_ t: String) -> Bool {
        t.split(whereSeparator: { $0 == " " || $0 == "," }).count <= Self.paroleRispostaCliente
    }
    static let paroleRispostaCliente = 5

    /// Le domande sulle promesse e sulle scadenze («quali promesse scadono a fine mese?», «chi ha polizze in scadenza
    /// a fine mese?», «cosa devo mandare a Giulia entro fine mese?»): restano a promesse, clientela e agenda.
    static func eUnaDomandaNonRoutine(_ t: String) -> Bool {
        DateItaliane.cerca(richiestaPromesse, t) != nil
            || DateItaliane.cerca(#"^(?:chi|quali|quale|quanti|quante|cosa|che cosa|che)\b.*\b(?:scad|promess)\w*"#, t) != nil
    }

    /// La frase che nomina la firma ma non la annuncia: una domanda («?» nella frase originale: `pulisci` lo toglie),
    /// le promesse, il resoconto, oppure «il contratto firmato con…» senza «ho/abbiamo firmato».
    static func nonEUnAnnuncioDiFirma(_ testo: String, _ t: String) -> Bool {
        if testo.contains("?") { return true }
        if DateItaliane.cerca(richiestaPromesse, t) != nil || eUnResoconto(t) { return true }
        let primaPersona = DateItaliane.cerca(#"\b(?:ho|abbiamo) firmato\b"#, t) != nil
        return !primaPersona && DateItaliane.cerca(#"\b(?:contratt[oi]|modul[oi]|polizz[ae]|document[oi]) firmat[oaie]\b|\bfirmato con alleanza\b"#, t) != nil
    }

    static let creaRoutine = #"\b(?:crea(?:mi)?|nuova|aggiungi|salva|fammi|imposta|registra|voglio)\b[^.?!]*\broutine\b"#
    /// I documenti hanno i loro comandi («preparami il fascicolo per l'incontro di giovedì»).
    /// Anche le bozze e il resoconto («prepara un messaggio per Federico per spostare l'appuntamento», «preparami il
    /// resoconto dell'incontro con Marco»): vanno a «Fallo tu» e al resoconto.
    static let esclusioniRoutine = #"\b(?:report|prospett[oi]|document[oi]|fascicol[oi]|presentazione|relazione|messaggi[oa]?|e-?mail|bozz[ae]|sms|whatsapp|resocont[oi])\b"#
    /// I comandi d'azione di sempre («fissa…», «sposta…», «ricordami…»): non sono routine anche se dicono «fine mese».
    static let comandiNonRoutine = #"^(?:mi )?(?:fiss|mett|prenot|organizz|programm|spost|anticip|posticip|rimand|scriv|mand|invi|avvis|ricordami|annot|prend\w* nota|blocc|liber|aggiorn|cambi)\w*\b"#

    // MARK: - Una routine nuova a parole

    /// Prima le regole; se non bastano, Qwen (solo i passi del catalogo, controllati da `RoutineVera.leggi`). La
    /// routine si salva solo con «Conferma».
    func proponiRoutineNuova(_ testo: String, chiave: String, oggi: Date = Date()) {
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        if let r = RoutineVera.daParole(testo, oggi: oggi) {
            rispondiRoutineNuova(r, richiesta: testo, chiave: chiave, motore: MotoriVera.sintesi.nome)
            return
        }
        guard let motore = qwenPerRoutine else {
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "Con le regole non trovo passi che so fare, e Qwen non è pronto per capire la routine a parole. " + Self.catalogoRoutine,
                                            titolo: "Una routine nuova", motore: MotoriVera.sintesi.nome), cliente: chiave)
            return
        }
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let json = try? await motore.scrivi(RoutineVera.messaggi(testo), opzioni: RoutineVera.opzioni(self.dati.impostazioni.vera)).testo
            guard !Task.isCancelled else { return }
            self.veraInCorso = false
            self.compitoVera = nil
            if let r = json.flatMap({ RoutineVera.leggi($0, richiesta: testo, oggi: oggi) }) {
                self.rispondiRoutineNuova(r, richiesta: testo, chiave: chiave, motore: motore.nome)
            } else {
                self.aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "Non ho riconosciuto passi che so fare. " + Self.catalogoRoutine,
                                                     titolo: "Una routine nuova", motore: motore.nome), cliente: chiave)
            }
        }
    }

    /// La routine capita, nella scheda «Conferma»: si salva solo confermando.
    @discardableResult
    func rispondiRoutineNuova(_ capita: RoutineVera, richiesta: String, chiave: String, motore: String) -> MessaggioVera {
        var r = capita
        // Per sicurezza (il motore già lo fa): una routine all'ora con passi sul cliente non partirebbe mai da sola
        if let p = r.programmazione, p.tipo != .dopoFirma, r.serveCliente { r.programmazione = nil }
        let passi = r.passi.enumerated().map { "\($0.offset + 1). \($0.element.tipo.descrizione)" }.joined(separator: "\n")
        let quando: String
        if let p = r.programmazione {
            quando = "Parte da sola: \(p.etichetta.prefix(1).lowercased() + p.etichetta.dropFirst()), con Prisma aperto."
        } else if RoutineVera.programmazioneTolta(richiesta: richiesta, routine: r) {
            quando = "Ha passi su un cliente: non può partire da sola. La lanci dicendo «\(r.frase)» e scegli il cliente."
        } else {
            quando = "La lanci dicendo «\(r.frase)»."
        }
        var m = MessaggioVera(autore: .vera, testo: "Ho capito la routine «\(r.titolo)»:\n\(passi)\n\(quando) La salvo solo con «Conferma».",
                              titolo: "Una routine nuova", motore: motore == MotoriVera.sintesi.nome ? Self.motoreAzioni : motore)
        m.conferma = SchedaConfermaVera(richiesta: richiesta, azioni: [RoutineVera.azioneSalva(r)], origine: .regole)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    /// I passi che Vera sa mettere in una routine, per quando non capisce.
    static var catalogoRoutine: String {
        let esempi = [TipoPassoRoutine.archiviaContratto, .fissaControllo, .messaggioBenvenuto, .agendaSettimana, .promesseScadenze, .parcelleMese, .scaletta]
        return "So per esempio: " + RoutineVera.elenco(esempi.map(\.descrizione)) + ". Prova così: «crea una routine: ogni volta che firmo, archivia il contratto e fissa il controllo a sei mesi»."
    }

    // MARK: - Programmazione (solo con Prisma aperto)

    /// Ogni quanto si guarda se c'è una routine da lanciare (le routine partono al minuto giusto con questo ritardo al più).
    static let intervalloControlloRoutine: TimeInterval = 600
    /// Il primo controllo poco dopo l'avvio (lo sblocco ne fa uno suo).
    static let primoControlloRoutine: TimeInterval = 20
    /// Un solo giro di controlli alla volta (l'app ha un solo StatoShell persistente; le prove e le istantanee non lo avviano).
    nonisolated(unsafe) private static var giroControlloRoutine = 0

    /// Avvia i controlli periodici delle routine programmate (una volta, all'avvio dell'app persistente).
    func avviaControlloRoutine() {
        guard persistente else { return }
        Self.giroControlloRoutine &+= 1
        programmaControlloRoutine(Self.giroControlloRoutine, fra: Self.primoControlloRoutine)
    }

    private func programmaControlloRoutine(_ giro: Int, fra attesa: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + attesa) { [weak self] in
            guard let self, Self.giroControlloRoutine == giro else { return }
            // Con il Mac a riposo o Prisma bloccata si rimanda: lo sblocco fa il suo controllo
            if !self.lavoriInPausa, !self.bloccato { self.controllaRoutineDovute() }
            self.programmaControlloRoutine(giro, fra: Self.intervalloControlloRoutine)
        }
    }

    /// Lancia le routine programmate che sono dovute adesso (anche in ritardo, entro `RoutineVera.giorniRecupero`
    /// giorni) sul portafoglio, senza voce, e lo dice con un avviso. Le routine che lavorano su un cliente non partono
    /// da sole (non saprebbero per chi). Non in modalità cliente, non durante la presentazione, mai in sola lettura.
    @discardableResult
    func controllaRoutineDovute(adesso: Date = Date()) -> [EsitoRoutine] {
        guard !solaLettura, modoCliente == nil, presentazione == nil else { return [] }
        let dovute = RoutineVera.dovute(dati.routine.tutte, adesso: adesso).filter { !$0.serveCliente }
        var esiti: [EsitoRoutine] = []
        for r in dovute {
            esiti.append(lanciaRoutine(r, richiesta: r.programmazione?.etichetta ?? r.titolo, clienteId: nil,
                                       chiave: VeraPortafoglio.chiave, oggi: adesso, parla: false))
        }
        if let primo = esiti.first {
            mostraAvviso(esiti.count == 1 ? "Vera ha preparato «\(primo.titolo)»: lo trovi in Vera, nel portafoglio"
                                          : "Vera ha preparato \(SchedaConfermaVera.numero(esiti.count)) routine: le trovi in Vera, nel portafoglio",
                         daVera: true)
        }
        return esiti
    }

    /// Una proposta appena accettata (StatoSeguito.chiudiProposta): le routine «dopo ogni firma» partono nella
    /// conversazione del cliente, con la posizione firmata. Le azioni aspettano «Conferma» come sempre.
    @discardableResult
    func routineDopoFirma(posizione p: Posizione, oggi: Date = Date()) -> [EsitoRoutine] {
        guard !solaLettura, cliente(p.clienteId) != nil, visibileAlCliente(p.clienteId) else { return [] }
        // Le routine del consulente prendono il posto di «Dopo la firma» (`perEvento`); in modalità cliente solo
        // quelle fatte tutte di passi sul cliente
        let routine = RoutineVera.perEvento(.dopoFirma, dati.routine.tutte).filter { !inModoCliente || Self.tuttaSulCliente($0) }
        let nome = p.nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? p.area.nome : p.nome
        let esiti = routine.map { r in
            lanciaRoutine(r, richiesta: "Firmato: «\(nome)»", clienteId: p.clienteId, posizioneId: p.id,
                          chiave: p.clienteId, oggi: oggi, parla: false)
        }
        if let primo = esiti.first, let c = cliente(p.clienteId) {
            mostraAvviso("Firmato: Vera ha preparato «\(primo.titolo)» nella conversazione di \(c.nome)", daVera: true)
        }
        return esiti
    }

    // MARK: - Il contratto trascinato dopo «Dopo la firma»

    /// Un documento trascinato su Vera subito dopo «Dopo la firma» (con il passo «Archivio il contratto» in attesa del
    /// PDF): diventa il contratto firmato del cliente, nella scheda «Conferma». Il file si copia prima nella cartella
    /// temporanea (l'archiviazione toglie la cartella del file, mai quella dell'utente). true se l'ha preso.
    func lasciaCadereRoutine(_ urls: [URL], oggi: Date = Date()) -> Bool {
        let chiave = chiaveConversazione
        guard let url = urls.first(where: { LetturaDocumenti.estensioniAccettate.contains($0.pathExtension.lowercased()) }),
              let m = conversazione(chiave).last(where: { $0.autore == .vera }), let e = m.esitoRoutine,
              let clienteId = e.clienteId, let c = cliente(clienteId), visibileAlCliente(clienteId),
              e.passi.contains(where: { $0.tipo == .archiviaContratto && $0.stato == .inAttesa }),
              oggi.timeIntervalSince(e.data) < Self.attesaContrattoRoutine else { return false }
        let fm = FileManager.default
        let cartella = Self.cartellaInArrivo.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let copia = cartella.appendingPathComponent(url.lastPathComponent)
        do {
            try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
            try fm.copyItem(at: url, to: copia)
        } catch {
            mostraAvviso("Non riesco a leggere «\(url.lastPathComponent)»: \(error.localizedDescription)")
            return true
        }
        let posizione = RoutineVera.posizioneFirmata(cliente: c, posizioneId: e.posizioneId, posizioni: dati.posizioni)
        let nomePosizione = posizione.map { $0.nome.trimmingCharacters(in: .whitespaces).isEmpty ? $0.area.nome : $0.nome }
        let titolo = "Contratto firmato · \(nomePosizione ?? c.nome)"
        let a = AzioneConferma(strumento: RegistroStrumenti.documentiArchivia, app: .documenti, titolo: "Archivio «\(titolo)»",
                               dettaglio: "Nella scheda di \(c.nome) · Documenti",
                               argomenti: ["cliente": c.id, "file": copia.path, "titolo": titolo, "tipo": Documento.Tipo.polizza.rawValue]
                                   .merging(posizione.map { ["posizione": $0.id] } ?? [:]) { a, _ in a })
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "📄 \(url.lastPathComponent)"), cliente: chiave, parla: false)
        var r = MessaggioVera(autore: .vera, testo: "È il contratto firmato di \(c.nome): con «Conferma» lo archivio nella sua scheda, tra i Documenti.",
                              titolo: e.titolo, motore: Self.motoreAzioni)
        // Origine «documento»: lasciata stare, la scheda toglie anche la copia temporanea del file
        r.conferma = SchedaConfermaVera(richiesta: e.richiesta, azioni: [a], origine: .documento)
        aggiungiMessaggio(r, cliente: chiave)
        return true
    }

    /// Il PDF firmato si aggancia a «Dopo la firma» entro due ore dal lancio.
    static let attesaContrattoRoutine: TimeInterval = 2 * 3600

    // MARK: - Esecuzione dopo «Conferma» (chiamate da FalloTuShell.eseguiAzioneVera / disfaAzioneVera)

    /// Com'era prima di «segna in essere» (per «Annulla»): la posizione, quella scritta dalla firma (per capire se qualcuno
    /// l'ha cambiata dopo), la pratica aperta insieme, l'attività di ripresa chiusa e la raccomandazione del track
    /// record prima e dopo. I campi nuovi sono opzionali: le schede salvate prima si leggono ancora.
    private struct PrimaDellaFirmaRoutine: Codable {
        var posizione: Posizione
        var pratica: Pratica?
        var dopo: Posizione?
        /// L'attività «Riprendere la proposta…» com'era, ancora aperta, prima della firma.
        var ripresa: Attivita?
        var raccomandazionePrima: Raccomandazione?
        var raccomandazioneDopo: Raccomandazione?
    }

    private static func codificaRoutine<T: Encodable>(_ v: T) -> String? {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return (try? e.encode(v)).flatMap { String(data: $0, encoding: .utf8) }
    }

    private static func decodificaRoutine<T: Decodable>(_ t: T.Type, _ s: String?) -> T? {
        guard let d = s?.data(using: .utf8) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(t, from: d)
    }

    /// `posizioni_segna_firmata`: la proposta firmata passa in essere come quando l'esito si segna a mano
    /// (`StatoSeguito.chiudiProposta`): `MotoreSeguitoProposte.applica(.accettata)` con i dati proposti di Prisma
    /// (decorrenza della scheda, primo valore, versato, scadenza, prima adesione), la pratica dopo la firma, la scelta
    /// nel track record e la ripresa chiusa. Senza rilanciare le routine «dopo ogni firma» (sono loro ad averla
    /// chiesta). Una posizione che non è più una proposta non si tocca.
    func eseguiPosizioneFirmataRoutine(_ a: AzioneConferma) -> EsitoAzioneVera {
        let arg = a.argomenti
        guard let id = arg["posizione"], let i = dati.posizioni.firstIndex(where: { $0.id == id }) else {
            return EsitoAzioneVera(fatta: false, messaggio: "La proposta non è più in Prisma.")
        }
        let prima = dati.posizioni[i]
        if let c = arg["cliente"], c != prima.clienteId { return EsitoAzioneVera(fatta: false, messaggio: "La proposta non è più di questo cliente.") }
        let nome = prima.nome.trimmingCharacters(in: .whitespaces).isEmpty ? prima.area.nome : prima.nome
        guard prima.stato == .proposta else {
            return EsitoAzioneVera(fatta: false, messaggio: "«\(nome)» non è più una proposta: non l'ho toccata.")
        }
        var d = datiAccettazione(prima, appuntamento: nil)
        if let dec = RegistroStrumenti.daIso(arg["decorrenza"]) { d.decorrenza = dec }
        let raccomandazionePrima = raccomandazione(perPosizione: id)
        let ripresaId = prima.seguito?.attivitaId
        let ripresa = ripresaId.flatMap { t in dati.attivita.first { $0.id == t && !$0.completata } }
        var p = prima
        _ = MotoreSeguitoProposte.applica(.accettata(d), a: &p, appuntamentoId: nil, adesso: Posizione.oggiArrotondato)
        dati.posizioni[i] = p
        let pratichePrima = Set(dati.pratiche.map(\.id))
        apriPraticaSeServe(p)
        let pratica = dati.pratiche.first { !pratichePrima.contains($0.id) }
        // Track record: la scelta del cliente con l'esito (e la raccomandazione, se è la prima presentazione)
        registraRaccomandazioneSeServe(prima: prima, dopo: p)
        if let t = ripresa?.id, let j = dati.attivita.firstIndex(where: { $0.id == t && !$0.completata }) {
            dati.attivita[j].completata = true
        }
        let mese = p.decorrenza.map { " da " + Formati.dataEstesa.string(from: $0) } ?? ""
        let primaFirma = PrimaDellaFirmaRoutine(posizione: prima, pratica: pratica, dopo: p, ripresa: ripresa,
                                               raccomandazionePrima: raccomandazionePrima,
                                               raccomandazioneDopo: raccomandazione(perPosizione: id))
        return EsitoAzioneVera(fatta: true, messaggio: "«\(nome)» di \(cliente(p.clienteId)?.nome ?? "del cliente") è in essere\(mese).",
                               oggetto: id, prima: Self.codificaRoutine(primaFirma))
    }

    /// «Annulla»: la posizione torna com'era se nessuno l'ha cambiata dopo; se è stata corretta (premio, date…) si
    /// rimettono solo stato, esito, decorrenza e seguito e le correzioni restano. La pratica aperta insieme esce se è
    /// ancora com'era (una pratica già lavorata a mano resta); la ripresa si riapre e la raccomandazione torna com'era,
    /// anche queste solo se nessuno le ha toccate dopo.
    func disfaPosizioneFirmataRoutine(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, let id = e.oggetto, let prima = Self.decodificaRoutine(PrimaDellaFirmaRoutine.self, e.prima),
              let i = dati.posizioni.firstIndex(where: { $0.id == id }) else { return false }
        let ora = dati.posizioni[i]
        guard ora.stato == .inEssere, ora.esito == .accettata else { return false }
        if let dopo = prima.dopo, ora == dopo {
            dati.posizioni[i] = prima.posizione
        } else {
            var r = ora
            r.stato = prima.posizione.stato
            r.esito = prima.posizione.esito
            r.decorrenza = prima.posizione.decorrenza
            if let dopo = prima.dopo, ora.seguito == dopo.seguito { r.seguito = prima.posizione.seguito }
            dati.posizioni[i] = r
            mostraAvviso("«\(ora.nome.trimmingCharacters(in: .whitespaces).isEmpty ? ora.area.nome : ora.nome)» torna proposta: le correzioni fatte dopo la firma restano")
        }
        if let pr = prima.pratica, let k = dati.pratiche.firstIndex(where: { $0.id == pr.id }), dati.pratiche[k] == pr {
            dati.pratiche.remove(at: k)
        }
        if let t = prima.ripresa, let j = dati.attivita.firstIndex(where: { $0.id == t.id }) {
            var chiusa = t
            chiusa.completata = true
            if dati.attivita[j] == chiusa { dati.attivita[j].completata = false }
        }
        if let dopo = prima.raccomandazioneDopo, prima.raccomandazionePrima != dopo,
           let k = dati.raccomandazioni.firstIndex(where: { $0.id == dopo.id }), dati.raccomandazioni[k] == dopo {
            if let r = prima.raccomandazionePrima { dati.raccomandazioni[k] = r } else { dati.raccomandazioni.remove(at: k) }
        }
        return true
    }

    /// `routine_salva`: la routine nuova entra tra quelle del consulente.
    func eseguiSalvaRoutine(_ a: AzioneConferma) -> EsitoAzioneVera {
        guard var r = Self.decodificaRoutine(RoutineVera.self, a.argomenti["routine"]) else {
            return EsitoAzioneVera(fatta: false, messaggio: "Non riesco a leggere la routine da salvare.")
        }
        guard !dati.routine.tutte.contains(where: { $0.id == r.id }) else {
            return EsitoAzioneVera(fatta: false, messaggio: "La routine «\(r.titolo)» è già salvata.")
        }
        // Una routine all'ora con passi sul cliente non partirebbe mai da sola: si lancia con la frase
        let tolta = r.programmazione.map { $0.tipo != .dopoFirma && r.serveCliente } ?? false
        if tolta { r.programmazione = nil }
        dati.routine.routine.append(r)
        let lancio = r.programmazione.map { "parte da sola, \($0.etichetta.prefix(1).lowercased() + $0.etichetta.dropFirst())" }
            ?? (tolta ? "ha passi su un cliente, quindi non parte da sola: la lanci con «\(r.frase)»" : "la lanci con «\(r.frase)»")
        return EsitoAzioneVera(fatta: true, messaggio: "La routine «\(r.titolo)» è salvata: \(lancio).", oggetto: r.id)
    }

    /// «Annulla»: la routine salvata esce (i suoi lanci passati restano nell'elenco degli esiti).
    func disfaSalvaRoutine(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, let id = e.oggetto, dati.routine.routine.contains(where: { $0.id == id }) else { return false }
        dati.routine.routine.removeAll { $0.id == id }
        return true
    }
}
