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
        guard !solaLettura, var r = routineVera(id), r.attiva != attiva else { return }
        r.attiva = attiva
        if let i = dati.routine.routine.firstIndex(where: { $0.id == id }) {
            dati.routine.routine[i] = r
        } else {
            dati.routine.routine.append(r)
        }
    }

    /// Toglie una routine del consulente (le pronte non si tolgono: si spengono). I suoi lanci passati restano.
    func eliminaRoutine(_ id: String) {
        guard !solaLettura, let r = routineVera(id), !r.pronta else { return }
        dati.routine.routine.removeAll { $0.id == id }
        if routineSelezionataVera == id { routineSelezionataVera = RoutineVera.idPrepara }
        mostraAvviso("La routine «\(r.titolo)» è tolta")
    }

    /// «Lancia ora» dalla pagina: per un cliente (le routine che lavorano su un cliente) o sul portafoglio. La pagina
    /// si chiude e la risposta, con la scheda «Conferma», compare nella conversazione giusta.
    func lanciaRoutineDaPagina(_ id: String, cliente clienteId: String?, oggi: Date = Date()) {
        guard !veraInCorso, let r = routineVera(id) else { return }
        let chiave: String
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
        // In modalità cliente il motore vede solo il cliente davanti a te (anche nei passi che leggono l'agenda)
        if inModoCliente {
            d.clienti = d.clienti.filter { $0.id == clienteAttivoId }
        }
        let contesto = ContestoRoutine(dati: d, oggi: oggi, clienteId: clienteId, posizioneId: posizioneId, file: file)
        let esito = RoutineVera.esegui(r, richiesta: richiesta, contesto: contesto)
        if esito.domanda == nil, !solaLettura {
            dati.routine = RoutineVera.registra(esito, in: dati.routine)
        }
        var m = MessaggioVera(autore: .vera, testo: Self.testoRoutine(esito), titolo: r.titolo,
                              motore: esito.azioni.isEmpty ? MotoriVera.sintesi.nome : Self.motoreAzioni)
        m.esitoRoutine = esito
        m.conferma = esito.schedaConferma
        aggiungiMessaggio(m, cliente: chiave, parla: parla)
        return esito
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
        guard let l = RoutineVera.riconosci(testo, routine: routineTutte, clienti: noti, attivo: attivo) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        if inModoCliente && !l.routine.serveCliente {
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "In modalità cliente lancio solo le routine sul cliente davanti a te: «\(l.routine.titolo)» guarda tutto il portafoglio.",
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

    static let creaRoutine = #"\b(?:crea(?:mi)?|nuova|aggiungi|salva|fammi|imposta|registra|voglio)\b[^.?!]*\broutine\b"#
    /// I documenti hanno i loro comandi («preparami il fascicolo per l'incontro di giovedì»).
    static let esclusioniRoutine = #"\b(?:report|prospett[oi]|document[oi]|fascicol[oi]|presentazione|relazione)\b"#
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
    func rispondiRoutineNuova(_ r: RoutineVera, richiesta: String, chiave: String, motore: String) -> MessaggioVera {
        let passi = r.passi.enumerated().map { "\($0.offset + 1). \($0.element.tipo.descrizione)" }.joined(separator: "\n")
        let quando = r.programmazione.map { "Parte da sola: \($0.etichetta.prefix(1).lowercased() + $0.etichetta.dropFirst()), con Prisma aperto." }
            ?? "La lanci dicendo «\(r.frase)»."
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
        let routine = RoutineVera.perEvento(.dopoFirma, dati.routine.tutte)
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
        let posizione = RoutineVera.posizioneFirmata(cliente: c, posizioneId: nil, posizioni: dati.posizioni)
        let nomePosizione = posizione.map { $0.nome.trimmingCharacters(in: .whitespaces).isEmpty ? $0.area.nome : $0.nome }
        let titolo = "Contratto firmato · \(nomePosizione ?? c.nome)"
        let a = AzioneConferma(strumento: RegistroStrumenti.documentiArchivia, app: .documenti, titolo: "Archivio «\(titolo)»",
                               dettaglio: "Nella scheda di \(c.nome) · Documenti",
                               argomenti: ["cliente": c.id, "file": copia.path, "titolo": titolo, "tipo": Documento.Tipo.polizza.rawValue])
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

    /// Com'era la posizione prima di «segna in essere», e la pratica aperta insieme (per «Annulla»).
    private struct PrimaDellaFirmaRoutine: Codable {
        var posizione: Posizione
        var pratica: Pratica?
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

    /// `posizioni_segna_firmata`: la proposta firmata diventa in essere, accettata, con la decorrenza; si apre la sua
    /// pratica dopo la firma come quando l'esito si segna a mano. Una posizione che non è più una proposta non si tocca.
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
        var p = prima
        p.stato = .inEssere
        p.esito = .accettata
        if let d = RegistroStrumenti.daIso(arg["decorrenza"]) { p.decorrenza = d }
        dati.posizioni[i] = p
        let pratichePrima = Set(dati.pratiche.map(\.id))
        apriPraticaSeServe(p)
        let pratica = dati.pratiche.first { !pratichePrima.contains($0.id) }
        let mese = p.decorrenza.map { " da " + Formati.dataEstesa.string(from: $0) } ?? ""
        return EsitoAzioneVera(fatta: true, messaggio: "«\(nome)» di \(cliente(p.clienteId)?.nome ?? "del cliente") è in essere\(mese).",
                               oggetto: id, prima: Self.codificaRoutine(PrimaDellaFirmaRoutine(posizione: prima, pratica: pratica)))
    }

    /// «Annulla»: la posizione torna com'era, se nessuno l'ha cambiata dopo; la pratica aperta insieme esce, se è
    /// ancora com'era (una pratica già lavorata a mano resta).
    func disfaPosizioneFirmataRoutine(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, let id = e.oggetto, let prima = Self.decodificaRoutine(PrimaDellaFirmaRoutine.self, e.prima),
              let i = dati.posizioni.firstIndex(where: { $0.id == id }) else { return false }
        let ora = dati.posizioni[i]
        guard ora.stato == .inEssere, ora.esito == .accettata else { return false }
        dati.posizioni[i] = prima.posizione
        if let pr = prima.pratica, let k = dati.pratiche.firstIndex(where: { $0.id == pr.id }), dati.pratiche[k] == pr {
            dati.pratiche.remove(at: k)
        }
        return true
    }

    /// `routine_salva`: la routine nuova entra tra quelle del consulente.
    func eseguiSalvaRoutine(_ a: AzioneConferma) -> EsitoAzioneVera {
        guard let r = Self.decodificaRoutine(RoutineVera.self, a.argomenti["routine"]) else {
            return EsitoAzioneVera(fatta: false, messaggio: "Non riesco a leggere la routine da salvare.")
        }
        guard !dati.routine.tutte.contains(where: { $0.id == r.id }) else {
            return EsitoAzioneVera(fatta: false, messaggio: "La routine «\(r.titolo)» è già salvata.")
        }
        dati.routine.routine.append(r)
        let lancio = r.programmazione.map { "parte da sola, \($0.etichetta.prefix(1).lowercased() + $0.etichetta.dropFirst())" } ?? "la lanci con «\(r.frase)»"
        return EsitoAzioneVera(fatta: true, messaggio: "La routine «\(r.titolo)» è salvata: \(lancio).", oggetto: r.id)
    }

    /// «Annulla»: la routine salvata esce (i suoi lanci passati restano nell'elenco degli esiti).
    func disfaSalvaRoutine(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, let id = e.oggetto, dati.routine.routine.contains(where: { $0.id == id }) else { return false }
        dati.routine.routine.removeAll { $0.id == id }
        return true
    }
}
