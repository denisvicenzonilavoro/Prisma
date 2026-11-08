import Foundation

// «Il tagliando dei dati» nell'app (Vera/BRIEF.md, funzione 5; motore in Vera/TagliandoVera.swift). Ogni notte alle
// 2:10 (con Prisma aperto sul Mac), oppure alla prima apertura o al primo risveglio dopo una notte saltata, Prisma
// controlla l'archivio: doppioni, campi vuoti, consensi, riesame, questionari, documento d'identità e posizioni
// scadute. Il risultato in breve (`StatoTagliando`) resta nell'archivio; l'elenco delle voci (`esitoTagliando`) vive
// in memoria e si rifà quando serve. Ogni correzione è una proposta: una scheda «Conferma» (mai eseguita in silenzio)
// oppure una schermata da aprire. Nulla si cancella da solo: «Unisci le schede» sposta sulla scheda principale tutto ciò
// che è legato al cliente (tranne le raccomandazioni registrate, un registro che non si cambia) e segna l'altra come
// unita (`Cliente.unitaIn`): resta in archivio ma esce dai clienti (`StatoShell.clientiAttivi`); «Annulla» rimette
// tutto com'era. L'elenco delle voci porta con sé la `versioneCalcoli` con cui è stato fatto: le azioni lo rifanno
// prima di usarlo se i dati sono cambiati intanto (`esitoTagliandoAggiornato`).
// Il tagliando riguarda tutto l'archivio: in modalità cliente non si apre.
extension StatoShell {
    static let titoloTagliando = "Il tagliando dei dati"
    /// Quanto aspettare dopo l'avvio (o il risveglio) prima del controllo dovuto: l'avvio resta libero.
    static let attesaTagliando: Double = 8
    /// Quante voci «Va bene così» si ricordano al massimo (le più vecchie escono).
    static let massimoIgnorateTagliando = 500

    // MARK: - Il controllo

    /// I clienti che il tagliando controlla: le schede unite a un'altra restano in archivio ma non contano più.
    var clientiDelTagliando: [Cliente] { clientiAttivi }

    /// Rifà l'elenco delle voci con i dati di adesso, senza toccare il registro salvato (dopo una correzione, a pagina
    /// aperta). Fuori dai body: legge i campi dell'archivio uno per uno.
    @discardableResult
    func aggiornaEsitoTagliando(adesso: Date = Date()) -> EsitoTagliando {
        let e = TagliandoVera.controlla(clienti: clientiDelTagliando, posizioni: dati.posizioni, appuntamenti: dati.appuntamenti,
                                        incontri: dati.incontri, documenti: dati.documenti, regole: dati.impostazioni.conformita,
                                        oggi: adesso, ignorate: Set(dati.tagliando.ignorate))
        esitoTagliando = e
        versioneEsitoTagliando = versioneCalcoli
        return e
    }

    /// L'elenco delle voci con i dati di adesso: quello in memoria se nessun dato dei calcoli è cambiato da quando è
    /// stato fatto, altrimenti si rifà (un codice fiscale scritto a mano, una scheda tolta a pagina chiusa). nil in
    /// modalità cliente. Solo dalle azioni (pulsanti, chat), mai dentro un body: può scrivere `esitoTagliando`.
    @discardableResult
    func esitoTagliandoAggiornato() -> EsitoTagliando? {
        guard !inModoCliente else { return nil }
        if let e = esitoTagliando, esitoTagliandoAttuale { return e }
        return aggiornaEsitoTagliando()
    }

    /// L'elenco in memoria vale ancora: fatto con i dati di adesso e oggi (al cambio di giorno un documento o un
    /// consenso può scadere, e le attività proposte hanno la data di oggi, anche con il controllo notturno spento).
    var esitoTagliandoAttuale: Bool {
        guard let e = esitoTagliando else { return false }
        return versioneEsitoTagliando == versioneCalcoli && Calendar.current.isDate(e.oggi, inSameDayAs: Date())
    }

    /// Al cambio di giorno (NSCalendarDayChanged): l'elenco in memoria, se c'è, si rifà con l'«oggi» nuovo, così pagina,
    /// card della colonna e chat non mostrano le scadenze del giorno prima. Il registro salvato non si tocca.
    func aggiornaEsitoTagliandoAlCambioGiorno() {
        guard esitoTagliando != nil, !inModoCliente, !lavoriInPausa, !esitoTagliandoAttuale else { return }
        aggiornaEsitoTagliando()
    }

    /// La scheda vera a cui portano le azioni su un cliente: se la scheda è stata unita a un'altra si segue `unitaIn`
    /// fino alla principale (con un limite di passi contro un giro chiuso). Una scheda che non c'è più resta com'è.
    func schedaPrincipaleTagliando(_ id: String) -> String {
        var attuale = id
        var visti: Set<String> = [id]
        for _ in 0..<8 {
            guard let u = dati.clienti.first(where: { $0.id == attuale })?.unitaIn, !visti.contains(u),
                  dati.clienti.contains(where: { $0.id == u }) else { break }
            visti.insert(u)
            attuale = u
        }
        return attuale
    }

    /// Il tagliando completo: le voci e, sul Mac, il registro salvato (ultimo controllo, riassunto, voci «Va bene così»
    /// ancora valide). Su iPhone e iPad i dati arrivano dal Mac: il controllo si mostra ma non si salva.
    @discardableResult
    func eseguiTagliando(adesso: Date = Date()) -> EsitoTagliando {
        let e = aggiornaEsitoTagliando(adesso: adesso)
        #if os(macOS)
        if !solaLettura {
            var t = dati.tagliando
            t.ultimoControllo = adesso
            t.ultimo = e.registro
            // Le voci «Va bene così» che non ci sono più (la situazione è cambiata) escono dall'elenco
            t.ignorate = Array(e.ignorate.map(\.id).suffix(Self.massimoIgnorateTagliando))
            if t != dati.tagliando { dati.tagliando = t }
        }
        #endif
        return e
    }

    /// Il controllo, solo se è dovuto (acceso e nessun controllo dall'ultimo turno notturno).
    func tagliandoSeDovuto(adesso: Date = Date()) {
        #if os(macOS)
        guard persistente, archivioPronto, !lavoriInPausa, !solaLettura else { return }
        guard TagliandoVera.dovuto(ultimo: dati.tagliando.ultimoControllo, adesso: adesso, impostazioni: dati.impostazioni.tagliando) else {
            // Non dovuto: dopo un riavvio l'elenco in memoria si rifà (senza toccare il registro dei controlli)
            if esitoTagliando == nil, !inModoCliente { aggiornaEsitoTagliando(adesso: adesso) }
            return
        }
        eseguiTagliando(adesso: adesso)
        #endif
    }

    /// All'avvio e dopo il risveglio: il controllo dovuto (poco dopo, per lasciare libero l'avvio) e il prossimo turno.
    func avviaTagliando() {
        #if os(macOS)
        guard persistente else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.attesaTagliando) { [weak self] in
            guard let self, !self.lavoriInPausa else { return }
            self.tagliandoSeDovuto()
            self.programmaTagliando()
        }
        #endif
    }

    /// Programma il prossimo turno notturno (niente Timer: un lavoro sul thread principale all'ora dell'orologio, che
    /// conta anche il tempo del Mac a riposo; dopo il risveglio lo riprogramma la ripresa dei lavori).
    func programmaTagliando(adesso: Date = Date()) {
        #if os(macOS)
        lavoroTagliando?.cancel()
        lavoroTagliando = nil
        guard persistente, !lavoriInPausa, dati.impostazioni.tagliando.attivo else { return }
        let quando = TagliandoVera.prossimoTurno(dopo: adesso, impostazioni: dati.impostazioni.tagliando)
        let lavoro = DispatchWorkItem { [weak self] in
            guard let self, !self.lavoriInPausa else { return }
            self.lavoroTagliando = nil
            self.tagliandoSeDovuto()
            self.programmaTagliando()
        }
        lavoroTagliando = lavoro
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + max(1, quando.timeIntervalSince(adesso)), execute: lavoro)
        #endif
    }

    /// Prima del riposo del Mac: il turno programmato si toglie (lo rimette la ripresa dei lavori).
    func annullaTagliandoProgrammato() {
        lavoroTagliando?.cancel()
        lavoroTagliando = nil
    }

    // MARK: - La pagina

    func apriPaginaTagliando() {
        guard !inModoCliente else { return mostraAvviso("Il tagliando riguarda tutto l'archivio: fuori dalla modalità cliente.") }
        esitoTagliandoAggiornato()
        if !aperta(.vera) { apri(.vera) }
        paginaTagliandoAperta = true
    }

    func chiudiPaginaTagliando() {
        paginaTagliandoAperta = false
    }

    /// «Controlla adesso» dalla pagina o dalle impostazioni.
    func controllaTagliandoAdesso() {
        guard !inModoCliente else { return }
        eseguiTagliando()
    }

    /// La voce dell'elenco di adesso.
    func voceTagliando(_ id: String) -> VoceTagliando? {
        esitoTagliando?.voci.first { $0.id == id } ?? esitoTagliando?.ignorate.first { $0.id == id }
    }

    /// «Va bene così»: la voce esce dall'elenco e dal punteggio finché la situazione non cambia (l'id la descrive).
    func ignoraVoceTagliando(_ id: String) {
        ignoraVociTagliando([id])
    }

    func ignoraVociTagliando(_ ids: [String]) {
        guard !solaLettura, !inModoCliente, !ids.isEmpty else { return }
        var t = dati.tagliando
        for id in ids where !t.ignorate.contains(id) { t.ignorate.append(id) }
        t.ignorate = Array(t.ignorate.suffix(Self.massimoIgnorateTagliando))
        dati.tagliando = t
        aggiornaEsitoTagliando()
    }

    /// Rimette nell'elenco una voce segnata «Va bene così».
    func ripristinaVoceTagliando(_ id: String) {
        guard !solaLettura, dati.tagliando.ignorate.contains(id) else { return }
        dati.tagliando.ignorate.removeAll { $0 == id }
        aggiornaEsitoTagliando()
    }

    /// Una voce con la correzione «attività» già segnata (un'attività aperta dello stesso cliente con lo stesso titolo):
    /// nella pagina si vede «Attività segnata».
    func correzioneTagliandoInCorso(_ v: VoceTagliando) -> Bool {
        guard let a = v.correzione?.azione, a.strumento == RegistroStrumenti.attivitaNuova,
              let cliente = a.argomenti["cliente"], let titolo = a.argomenti["titolo"] else { return false }
        return dati.attivita.contains { $0.clienteId == cliente && !$0.completata && $0.titolo == titolo }
    }

    /// Una correzione che porta a una schermata: la scheda del cliente sulla sezione giusta, oppure la posizione.
    func vaiTagliando(_ d: DestinazioneTagliando) {
        guard !inModoCliente else { return }
        paginaTagliandoAperta = false
        switch d {
        case .scheda(let id, let sezione):
            guard cliente(id) != nil else { return mostraAvviso("La scheda del cliente non è più in Prisma.") }
            clienteAttivoId = id
            switch sezione {
            case .anagrafica: schedaCliente = .anagrafica
            case .inRegola: schedaCliente = .inRegola
            case .documenti: schedaCliente = .documenti
            }
            apri(.clienti)
        case .posizione(let id):
            guard let p = dati.posizioni.first(where: { $0.id == id }) else { return mostraAvviso("La posizione non è più in Prisma.") }
            apriPosizione(p)
        }
    }

    /// Il messaggio di Vera con la scheda «Conferma» (nella conversazione del portafoglio: il tagliando è di tutto
    /// l'archivio). Restituisce l'id del messaggio, che la pagina mostra subito sotto l'elenco.
    @discardableResult
    func proponiConfermaTagliando(_ scheda: SchedaConfermaVera, testo: String, chiave: String = VeraPortafoglio.chiave,
                                  parla: Bool = false) -> String? {
        guard !inModoCliente, !solaLettura else { return nil }
        var m = MessaggioVera(autore: .vera, testo: testo, titolo: Self.titoloTagliando, motore: Self.motoreAzioni)
        m.conferma = scheda
        aggiungiMessaggio(m, cliente: chiave, parla: parla)
        return m.id
    }

    /// Il pulsante di una voce: la scheda «Conferma» della sua azione, oppure la schermata da aprire.
    @discardableResult
    func correggiVoceTagliando(_ id: String) -> String? {
        // I dati possono essere cambiati da quando la pagina mostra la voce: si rifà l'elenco prima di proporre
        esitoTagliandoAggiornato()
        guard let v = voceTagliando(id), let c = v.correzione else {
            mostraAvviso("Questa voce non c'è più: i dati sono cambiati e il tagliando è aggiornato.")
            return nil
        }
        // L'attività è già segnata: una seconda uguale non serve
        guard !correzioneTagliandoInCorso(v) else {
            mostraAvviso("L'attività per questa voce è già segnata.")
            return nil
        }
        switch c {
        case .naviga(_, let destinazione):
            vaiTagliando(destinazione)
            return nil
        case .conferma:
            guard let s = TagliandoVera.scheda(v) else { return nil }
            return proponiConfermaTagliando(s, testo: "\(v.titolo): ti preparo la correzione, la faccio solo con «Conferma».")
        }
    }

    /// Le voci dei campi vuoti, insieme: le azioni «Completa dai documenti» in una scheda sola (nil se nessuna).
    @discardableResult
    func completaCampiVuotiTagliando() -> String? {
        let azioni = (esitoTagliandoAggiornato()?.voci ?? []).filter { $0.tipo == .campiVuoti && !correzioneTagliandoInCorso($0) }
            .compactMap { $0.correzione?.azione }
        guard !azioni.isEmpty else { return nil }
        let s = SchedaConfermaVera(richiesta: "Campi vuoti: completa dai documenti (tagliando dei dati)", azioni: azioni, origine: .regole)
        return proponiConfermaTagliando(s, testo: "Completo le schede con i dati letti nei documenti, solo con «Conferma».")
    }

    /// «Sistema tutto»: tutte le azioni del tagliando in una scheda «Conferma» (le voci che portano a una schermata
    /// restano nella pagina; quelle con l'attività già segnata non si ripropongono, per non fare doppioni). L'elenco si
    /// rifà prima se i dati sono cambiati, così la scheda non propone correzioni su voci già sistemate.
    @discardableResult
    func sistemaTuttoTagliando(chiave: String = VeraPortafoglio.chiave, parla: Bool = false) -> String? {
        if solaLettura {
            let detto = "Prisma è in sola lettura: non posso preparare correzioni."
            if parla { rispostaTagliando(detto, chiave: chiave) } else { mostraAvviso(detto) }
            return nil
        }
        guard let e = esitoTagliandoAggiornato() else { return nil }
        let azioni = e.voci.filter { !correzioneTagliandoInCorso($0) }.compactMap { $0.correzione?.azione }
        let scheda = azioni.isEmpty ? nil : SchedaConfermaVera(richiesta: "Sistema tutto (tagliando dei dati)", azioni: azioni, origine: .regole)
        guard let s = scheda else {
            if parla {
                rispostaTagliando("Non c'è niente da sistemare con un'azione: le voci rimaste si aprono dalla pagina del tagliando.", chiave: chiave)
            } else {
                mostraAvviso("Niente da sistemare con un'azione: le voci rimaste portano alla scheda giusta.")
            }
            return nil
        }
        let inCorso = e.voci.filter { correzioneTagliandoInCorso($0) }.count
        let restano = max(0, e.voci.count - s.azioni.count - inCorso)
        var testo = "Ecco tutte le correzioni del tagliando: le faccio solo con «Conferma». Nulla si cancella."
        if restano > 0 { testo += restano == 1 ? " Una voce si sistema dalla sua scheda." : " \(restano) voci si sistemano dalla loro scheda." }
        if inCorso > 0 { testo += inCorso == 1 ? " Per una voce l'attività è già segnata." : " Per \(inCorso) voci l'attività è già segnata." }
        return proponiConfermaTagliando(s, testo: testo, chiave: chiave, parla: parla)
    }

    // MARK: - In chat

    /// «Fai il tagliando», «controlla l'archivio», «salute dell'archivio», «ci sono doppioni?», «tagliando di Marco».
    static let richiestaTagliando = #"\btagliando\b|\b(?:controlla|ricontrolla|verifica|metti in ordine|pulisci)\s+(?:tutto\s+)?(?:l'|dell')?archivio\b|\bsalute dell'archivio\b|\bcome sta l'archivio\b|\b(?:schede doppie|doppioni)\b|\bcampi vuoti\b"#
    /// «Sistema tutto» (dopo una risposta del tagliando), «sistema tutto il tagliando».
    static let sistemaTuttoTagliando = #"^(?:sì,?\s+)?sistema(?:mi)? tutto\b"#

    @discardableResult
    func rispostaTagliando(_ testo: String, chiave: String, _ completa: (inout MessaggioVera) -> Void = { _ in }) -> MessaggioVera {
        var m = MessaggioVera(autore: .vera, testo: testo, titolo: Self.titoloTagliando, motore: MotoriVera.sintesi.nome)
        completa(&m)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    /// L'ultima risposta di Vera in questa conversazione è del tagliando (per il «sistema tutto» che segue).
    private func ultimaRispostaTagliando(_ chiave: String) -> Bool {
        conversazione(chiave).last { $0.autore == .vera }?.titolo == Self.titoloTagliando
    }

    /// Lo smistamento in chat (FalloTuShell.smistaVera). true se la frase era per il tagliando. Il tagliando è di tutto
    /// l'archivio: domanda, riassunto e scheda «Sistema tutto» vanno nella conversazione del portafoglio, mai nel dossier
    /// di un cliente (la scheda cita nomi e dati di altri clienti). In modalità cliente resta la sola risposta di rifiuto,
    /// nella conversazione davanti al cliente.
    func chiediTagliando(_ testo: String, chiave chiaveRicevuta: String) -> Bool {
        let chiave = inModoCliente ? chiaveRicevuta : VeraPortafoglio.chiave
        let t = InterpreteComandi.pulisci(testo)
        let sistema = DateItaliane.cerca(Self.sistemaTuttoTagliando, t) != nil
            // La conversazione in cui è stata scritta la frase (dopo la prima risposta del tagliando è quella del portafoglio)
            && (ultimaRispostaTagliando(chiaveRicevuta) || DateItaliane.cerca(#"\btagliando\b"#, t) != nil)
        let richiesta = DateItaliane.cerca(Self.richiestaTagliando, t) != nil
            // «Scrivi a Marco…», «manda…» sono per «Fallo tu»; «tagliando dell'auto» non è l'archivio
            && DateItaliane.cerca(Self.verboAzione, t) == nil
            && DateItaliane.cerca(#"\btagliando (?:dell'|della |del )(?:auto|macchina|moto|caldaia|vettura)"#, t) == nil
        guard sistema || richiesta else { return false }
        if !inModoCliente { veraPortafoglio = true }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        guard !inModoCliente else {
            rispostaTagliando("In modalità cliente il tagliando non si apre: riguarda le schede di tutti i clienti.", chiave: chiave)
            return true
        }
        let e = eseguiTagliando()
        if sistema {
            sistemaTuttoTagliando(chiave: chiave, parla: true)
            return true
        }
        // «Apri il tagliando»: la pagina, e in chat il riassunto
        // (anche dalla Vera della scrivania: si apre la finestra di Vera, dove la pagina vive)
        if t.hasPrefix("apri") || t.hasPrefix("mostra") || t.hasPrefix("fammi vedere") { apriPaginaTagliando() }
        let noti = clientiAttivi.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let nominati = InterpreteComandi.clientiNominati(t, noti)
        if nominati.count == 1, let c = cliente(nominati[0].id) {
            let voci = e.voci(cliente: c.id)
            let testoCliente: String
            if voci.isEmpty {
                testoCliente = "La scheda di \(c.nome) è in ordine: nessuna cosa da sistemare."
            } else {
                let rosse = voci.filter { $0.gravita == .rosso }.count
                testoCliente = "La scheda di \(c.nome): \(voci.count == 1 ? "una cosa da sistemare" : "\(voci.count) cose da sistemare")"
                    + (rosse > 0 ? (rosse == 1 ? ", una urgente" : ", \(rosse) urgenti") : "")
                    + ". Salute della scheda \(e.saluteSchede[c.id] ?? 100)%. Ogni correzione passa da te."
            }
            rispostaTagliando(testoCliente, chiave: chiave) { $0.tagliando = c.id }
            return true
        }
        rispostaTagliando(Self.testoTagliando(e), chiave: chiave) { $0.tagliando = "" }
        return true
    }

    /// Il riassunto in chat, con le sole cifre del controllo.
    static func testoTagliando(_ e: EsitoTagliando) -> String {
        if e.inOrdine { return "Archivio in ordine: \(TagliandoVera.schede(e.schede)) controllate, salute \(e.salute)%." }
        let rosse = e.rosse.count
        var testo = "Salute dell'archivio \(e.salute)% su \(TagliandoVera.schede(e.schede)): \(TagliandoVera.riepilogo(e).lowercased())"
        if rosse > 0 { testo += rosse == 1 ? ", una urgente" : ", \(rosse) urgenti" }
        return testo + ". Ti propongo le correzioni: niente cambia senza «Conferma» e nulla si cancella."
    }

    // MARK: - Gli strumenti (dopo «Conferma»)

    /// Esegue i tre strumenti del tagliando (nil se l'azione non è del tagliando). La chiama `eseguiAzioneVera`.
    func eseguiAzioneTagliando(_ a: AzioneConferma, oggi: Date = Date()) -> EsitoAzioneVera? {
        switch a.strumento {
        case TagliandoVera.strumentoUnisci: return unisciSchedeTagliando(a)
        case TagliandoVera.strumentoCompleta: return completaDatoTagliando(a)
        case TagliandoVera.strumentoDocumento: return registraDocumentoTagliando(a, oggi: oggi)
        case RegistroStrumenti.attivitaNuova, RegistroStrumenti.notaNuova, RegistroStrumenti.agendaNuovo:
            // Una scheda unita nel frattempo (in «Sistema tutto» l'unione viene prima delle voci del consenso
            // commerciale della doppia): l'attività, la nota o l'impegno vanno sulla principale. Si riesegue l'azione con
            // l'id della principale, che qui non ha più niente da cambiare e passa al caso normale di `eseguiAzioneVera`.
            guard let chiesto = a.argomenti["cliente"], case let id = schedaPrincipaleTagliando(chiesto), id != chiesto,
                  dati.clienti.contains(where: { $0.id == id && $0.unitaIn == nil }) else { return nil }
            var b = a
            b.argomenti["cliente"] = id
            return eseguiAzioneVera(b)
        default: return nil
        }
    }

    /// «Annulla» dei tre strumenti (nil se l'azione non è del tagliando). La chiama `disfaAzioneVera`.
    func disfaAzioneTagliando(_ a: AzioneConferma) -> Bool? {
        switch a.strumento {
        case TagliandoVera.strumentoUnisci: return disfaUnioneTagliando(a)
        case TagliandoVera.strumentoCompleta: return disfaDatoTagliando(a)
        case TagliandoVera.strumentoDocumento: return disfaDocumentoTagliando(a)
        default: return nil
        }
    }

    private static func jsonTagliando<T: Encodable>(_ v: T) -> String? {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return (try? e.encode(v)).flatMap { String(data: $0, encoding: .utf8) }
    }

    private static func daJSONTagliando<T: Decodable>(_ t: T.Type, _ s: String?) -> T? {
        guard let d = s?.data(using: .utf8) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(t, from: d)
    }

    /// Sposta su un altro cliente gli elementi di un campo dell'archivio (tutti quelli di `da`, o solo gli id dati).
    private func spostaTagliando<T, C: Equatable>(_ campo: ReferenceWritableKeyPath<DatiVivi, [T]>, id: KeyPath<T, String>,
                                                  cliente: WritableKeyPath<T, C>, da: C, a: C, soli: Set<String>? = nil) -> [String] {
        var elenco = dati[keyPath: campo]
        var spostati: [String] = []
        for i in elenco.indices where elenco[i][keyPath: cliente] == da && (soli?.contains(elenco[i][keyPath: id]) ?? true) {
            elenco[i][keyPath: cliente] = a
            spostati.append(elenco[i][keyPath: id])
        }
        if !spostati.isEmpty { dati[keyPath: campo] = elenco }
        return spostati
    }

    /// Unisce due schede: passa sulla principale tutto ciò che è legato al cliente (le raccolte con il suo id, le voci
    /// per cliente di analisi, confronti TFR e conversazioni di Vera, i consensi e le date di «In regola» che le
    /// mancano); i dati dell'anagrafica che le mancano li prende dall'altra, telefono ed email diversi vanno nelle note.
    /// Restano sulla doppia solo le raccomandazioni registrate (un registro che non si cambia, il messaggio lo dice).
    /// La scheda doppia resta in archivio, segnata come unita. Niente si cancella; «Annulla» rimette tutto com'era.
    private func unisciSchedeTagliando(_ a: AzioneConferma) -> EsitoAzioneVera {
        let no = { (m: String) in EsitoAzioneVera(fatta: false, messaggio: m) }
        guard let pId = a.argomenti["principale"], let dId = a.argomenti["doppione"], pId != dId,
              let ip = dati.clienti.firstIndex(where: { $0.id == pId }), let id = dati.clienti.firstIndex(where: { $0.id == dId }) else {
            return no("Non trovo più le due schede da unire.")
        }
        let principale = dati.clienti[ip], doppia = dati.clienti[id]
        guard principale.unitaIn == nil else { return no("La scheda di «\(principale.nome)» è già unita a un'altra.") }
        guard doppia.unitaIn == nil else { return no("La scheda di «\(doppia.nome)» è già unita a un'altra.") }
        let cfP = TagliandoVera.codiceFiscale(principale.codiceFiscale), cfD = TagliandoVera.codiceFiscale(doppia.codiceFiscale)
        guard cfP.isEmpty || cfD.isEmpty || cfP == cfD else { return no("Le due schede hanno codici fiscali diversi: sono due persone, non le unisco.") }

        var u = UnioneTagliando(principale: pId, doppione: dId)
        u.posizioni = spostaTagliando(\DatiVivi.posizioni, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.documenti = spostaTagliando(\DatiVivi.documenti, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.appuntamenti = spostaTagliando(\DatiVivi.appuntamenti, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.attivita = spostaTagliando(\DatiVivi.attivita, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.note = spostaTagliando(\DatiVivi.note, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.messaggi = spostaTagliando(\DatiVivi.messaggi, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.incontri = spostaTagliando(\DatiVivi.incontri, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.obiettivi = spostaTagliando(\DatiVivi.obiettivi, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.simulazioni = spostaTagliando(\DatiVivi.simulazioni, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.valutazioni = spostaTagliando(\DatiVivi.valutazioni, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.commenti = spostaTagliando(\DatiVivi.commenti, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.fotografie = spostaTagliando(\DatiVivi.fotografie, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.schedeAdeguatezza = spostaTagliando(\DatiVivi.schedeAdeguatezza, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.parcelle = spostaTagliando(\DatiVivi.parcelle, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.eventiVita = spostaTagliando(\DatiVivi.eventiVita, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.sessioniCopilota = spostaTagliando(\DatiVivi.sessioniCopilota, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.partiteRischio = spostaTagliando(\DatiVivi.partiteRischio, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.promesse = spostaTagliando(\DatiVivi.promesse, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.confrontiDocumenti = spostaTagliando(\DatiVivi.confrontiDocumenti, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        // Le coperture si riconoscono dal documento (`id` = documentoId): passano con il loro documento
        u.coperture = spostaTagliando(\DatiVivi.coperture, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.sussurriChiusi = spostaTagliando(\DatiVivi.sussurriChiusi, id: \.idTagliando, cliente: \.clienteId, da: dId, a: pId)
        u.spiegazioniTreLivelli = spostaTagliando(\DatiVivi.spiegazioniTreLivelli, id: \.id, cliente: \.clienteId, da: dId, a: pId)
        u.esitiRoutine = spostaTagliando(\DatiVivi.routine.esiti, id: \.id, cliente: \.clienteId, da: Optional(dId), a: Optional(pId))
        // Le pratiche seguono la loro posizione (non hanno un cliente proprio): passano con le posizioni.
        // Analisi 360 e confronto TFR (una voce per cliente): passano solo se la principale non ne ha una sua
        if dati.analisi[pId] == nil, let an = dati.analisi[dId] {
            var d = dati.analisi
            d[pId] = an
            d[dId] = nil
            dati.analisi = d
            u.analisiSpostata = true
        }
        if dati.confrontiTFR[pId] == nil, let tfr = dati.confrontiTFR[dId] {
            var d = dati.confrontiTFR
            d[pId] = tfr
            d[dId] = nil
            dati.confrontiTFR = d
            u.confrontoTFRSpostato = true
        }
        // La conversazione di Vera della doppia passa in coda a quella della principale
        if let vecchi = dati.conversazioni[dId], !vecchi.isEmpty {
            var d = dati.conversazioni
            d[pId] = (d[pId] ?? []) + vecchi
            d[dId] = nil
            dati.conversazioni = d
            u.messaggiVera = vecchi.map(\.id)
        }

        // I dati che mancano alla principale arrivano dall'altra; quelli diversi restano nelle note
        var nuovo = principale
        if nuovo.codiceFiscale.trimmingCharacters(in: .whitespaces).isEmpty, !cfD.isEmpty { nuovo.codiceFiscale = cfD; u.riempiti["codiceFiscale"] = cfD }
        if nuovo.email.trimmingCharacters(in: .whitespaces).isEmpty, !doppia.email.isEmpty { nuovo.email = doppia.email; u.riempiti["email"] = doppia.email }
        if nuovo.telefono.trimmingCharacters(in: .whitespaces).isEmpty, !doppia.telefono.isEmpty { nuovo.telefono = doppia.telefono; u.riempiti["telefono"] = doppia.telefono }
        if nuovo.indirizzo.trimmingCharacters(in: .whitespaces).isEmpty, !doppia.indirizzo.isEmpty { nuovo.indirizzo = doppia.indirizzo; u.riempiti["indirizzo"] = doppia.indirizzo }
        if nuovo.dataNascita == nil, let n = doppia.dataNascita { nuovo.dataNascita = n; u.riempiti["dataNascita"] = RegistroStrumenti.isoData(n) }
        // I canali della doppia (le sue posizioni Alleanza o indipendenti ora sono qui)
        for canale in doppia.canali where !nuovo.canali.contains(canale) {
            nuovo.canali.append(canale)
            u.canaliAggiunti.append(canale)
        }
        // I consensi: quello che la principale non ha (mai dato né registrato) arriva dalla doppia
        var consensi = nuovo.consensi
        if !consensi.privacy, doppia.consensi.privacy {
            consensi.privacy = true
            consensi.dataPrivacy = doppia.consensi.dataPrivacy
        }
        // Il consenso commerciale solo se la principale non ne ha mai registrato uno (un «no» con la data resta)
        if !consensi.marketing, consensi.dataMarketing == nil, doppia.consensi.marketing {
            consensi.marketing = true
            consensi.dataMarketing = doppia.consensi.dataMarketing
        }
        if consensi != nuovo.consensi {
            u.consensiPrima = nuovo.consensi
            u.consensiDopo = consensi
            nuovo.consensi = consensi
        }
        // «In regola»: questionari, verifiche e documento d'identità che mancano alla principale arrivano dalla doppia
        if let cd = doppia.conformita {
            var conf = nuovo.conformita ?? ConformitaCliente()
            if conf.questionarioAlleanza == nil { conf.questionarioAlleanza = cd.questionarioAlleanza }
            if conf.questionarioIndipendente == nil { conf.questionarioIndipendente = cd.questionarioIndipendente }
            if conf.verificaAlleanza == nil { conf.verificaAlleanza = cd.verificaAlleanza }
            if conf.verificaIndipendente == nil { conf.verificaIndipendente = cd.verificaIndipendente }
            if conf.documento == nil { conf.documento = cd.documento }
            let unita = MotoreConformita.normalizzata(conf)
            if unita != nuovo.conformita {
                u.conformitaUnita = true
                u.conformitaPrima = nuovo.conformita
                u.conformitaDopo = unita
                nuovo.conformita = unita
            }
        }
        // Il resto dell'anagrafica: famiglia, profilo investitore, bisogni, dati per la fattura, consenso al copilota,
        // portafoglio modello del radar, stato civile, aziende e professione. Passa ciò che alla principale manca (vuoto
        // o mai compilato); se le due schede hanno valori diversi resta quello della principale e la riga delle note dice
        // cosa è rimasto sulla scheda unita.
        var anag = AnagraficaUnione()
        var restanoLa: [String] = []
        if !doppia.famiglia.isEmpty {
            if nuovo.famiglia.isEmpty { nuovo.famiglia = doppia.famiglia; anag.famiglia = doppia.famiglia }
            else if nuovo.famiglia != doppia.famiglia { restanoLa.append("famiglia") }
        }
        if doppia.profilo != ProfiloInvestitore() {
            if nuovo.profilo == ProfiloInvestitore() { nuovo.profilo = doppia.profilo; anag.profilo = doppia.profilo }
            else if nuovo.profilo != doppia.profilo { restanoLa.append("profilo investitore") }
        }
        if doppia.bisogni != ProfiloBisogni() {
            if nuovo.bisogni == ProfiloBisogni() { nuovo.bisogni = doppia.bisogni; anag.bisogni = doppia.bisogni }
            else if nuovo.bisogni != doppia.bisogni { restanoLa.append("bisogni") }
        }
        if let f = doppia.fiscale {
            if nuovo.fiscale == nil { nuovo.fiscale = f; anag.fiscale = f }
            else if nuovo.fiscale != f { restanoLa.append("dati per la fattura") }
        }
        if let k = doppia.consensoCopilota {
            if nuovo.consensoCopilota == nil { nuovo.consensoCopilota = k; anag.consensoCopilota = k }
            else if nuovo.consensoCopilota != k { restanoLa.append("consenso al copilota") }
        }
        if let m = doppia.modelloId {
            if nuovo.modelloId == nil { nuovo.modelloId = m; anag.modelloId = m }
            else if nuovo.modelloId != m { restanoLa.append("portafoglio modello") }
        }
        if let s = doppia.statoCivile {
            if nuovo.statoCivile == nil { nuovo.statoCivile = s; anag.statoCivile = s }
            else if nuovo.statoCivile != s { restanoLa.append("stato civile") }
        }
        if let az = doppia.aziende, !az.isEmpty {
            if nuovo.aziende?.isEmpty ?? true { anag.aziendePrima = nuovo.aziende; nuovo.aziende = az; anag.aziende = az }
            else if nuovo.aziende != az { restanoLa.append("aziende") }
        }
        let professioneD = doppia.professione.trimmingCharacters(in: .whitespacesAndNewlines)
        if !professioneD.isEmpty {
            if nuovo.professione.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                anag.professionePrima = nuovo.professione
                nuovo.professione = doppia.professione
                anag.professione = doppia.professione
            } else if nuovo.professione.trimmingCharacters(in: .whitespacesAndNewlines) != professioneD {
                restanoLa.append("professione")
            }
        }
        if anag != AnagraficaUnione() { u.anagrafica = anag }
        var diversi: [String] = []
        if !doppia.telefono.isEmpty, !principale.telefono.isEmpty, TagliandoVera.telefono(doppia.telefono) != TagliandoVera.telefono(principale.telefono) {
            diversi.append("telefono \(doppia.telefono)")
        }
        if !doppia.email.isEmpty, !principale.email.isEmpty, TagliandoVera.email(doppia.email) != TagliandoVera.email(principale.email) {
            diversi.append("email \(doppia.email)")
        }
        if !restanoLa.isEmpty {
            diversi.append("diversi da questa scheda e rimasti là: \(restanoLa.joined(separator: ", "))")
        }
        if !diversi.isEmpty {
            let riga = "Dalla scheda unita «\(doppia.nome)»: \(diversi.joined(separator: "; "))"
            nuovo.nota = (nuovo.nota.isEmpty ? "" : nuovo.nota + "\n") + riga
            u.rigaNota = riga
        }
        var elenco = dati.clienti
        elenco[ip] = nuovo
        elenco[id].unitaIn = pId
        dati.clienti = elenco
        if clienteAttivoId == dId { clienteAttivoId = pId }
        aggiornaEsitoTagliando()
        let spostati = u.elementiSpostati
        let quanti = spostati == 0 ? "" : (spostati == 1 ? " Un elemento è passato sulla sua scheda." : " \(spostati) elementi sono passati sulla sua scheda.")
        var resta = ""
        if dati.analisi[dId] != nil || dati.confrontiTFR[dId] != nil {
            resta += " La principale aveva già la sua analisi 360 o il suo confronto TFR: quelli della doppia restano sulla scheda unita."
        }
        if !restanoLa.isEmpty {
            resta += " Diversi da quelli della principale, restano sulla scheda unita (e nelle note): \(restanoLa.joined(separator: ", "))."
        }
        let raccomandazioni = dati.raccomandazioni.filter { $0.clienteId == dId }.count
        if raccomandazioni > 0 {
            resta += raccomandazioni == 1 ? " La raccomandazione registrata resta sulla scheda unita (il registro non si cambia)."
                : " Le \(raccomandazioni) raccomandazioni registrate restano sulla scheda unita (il registro non si cambia)."
        }
        return EsitoAzioneVera(fatta: true, messaggio: "«\(doppia.nome)» è unita a «\(principale.nome)».\(quanti)\(resta) La scheda doppia resta in archivio, segnata come unita, e non compare più fra i clienti.",
                               oggetto: pId, prima: Self.jsonTagliando(u))
    }

    private func disfaUnioneTagliando(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, let u = Self.daJSONTagliando(UnioneTagliando.self, e.prima),
              let ip = dati.clienti.firstIndex(where: { $0.id == u.principale }), let id = dati.clienti.firstIndex(where: { $0.id == u.doppione }),
              dati.clienti[id].unitaIn == u.principale else { return false }
        // La principale è stata unita a sua volta a un'altra scheda (un tagliando dopo): i suoi elementi, anche quelli
        // arrivati da questa unione, sono ormai là. Prima si annulla l'unione più recente, poi questa.
        guard dati.clienti[ip].unitaIn == nil else { return false }
        let (p, d) = (u.principale, u.doppione)
        _ = spostaTagliando(\DatiVivi.posizioni, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.posizioni))
        _ = spostaTagliando(\DatiVivi.documenti, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.documenti))
        _ = spostaTagliando(\DatiVivi.appuntamenti, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.appuntamenti))
        _ = spostaTagliando(\DatiVivi.attivita, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.attivita))
        _ = spostaTagliando(\DatiVivi.note, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.note))
        _ = spostaTagliando(\DatiVivi.messaggi, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.messaggi))
        _ = spostaTagliando(\DatiVivi.incontri, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.incontri))
        _ = spostaTagliando(\DatiVivi.obiettivi, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.obiettivi))
        _ = spostaTagliando(\DatiVivi.simulazioni, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.simulazioni))
        _ = spostaTagliando(\DatiVivi.valutazioni, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.valutazioni))
        _ = spostaTagliando(\DatiVivi.commenti, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.commenti))
        _ = spostaTagliando(\DatiVivi.fotografie, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.fotografie))
        _ = spostaTagliando(\DatiVivi.schedeAdeguatezza, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.schedeAdeguatezza))
        _ = spostaTagliando(\DatiVivi.parcelle, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.parcelle))
        _ = spostaTagliando(\DatiVivi.eventiVita, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.eventiVita))
        _ = spostaTagliando(\DatiVivi.sessioniCopilota, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.sessioniCopilota))
        _ = spostaTagliando(\DatiVivi.partiteRischio, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.partiteRischio))
        _ = spostaTagliando(\DatiVivi.promesse, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.promesse))
        _ = spostaTagliando(\DatiVivi.confrontiDocumenti, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.confrontiDocumenti))
        _ = spostaTagliando(\DatiVivi.coperture, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.coperture))
        _ = spostaTagliando(\DatiVivi.sussurriChiusi, id: \.idTagliando, cliente: \.clienteId, da: p, a: d, soli: Set(u.sussurriChiusi))
        _ = spostaTagliando(\DatiVivi.spiegazioniTreLivelli, id: \.id, cliente: \.clienteId, da: p, a: d, soli: Set(u.spiegazioniTreLivelli))
        _ = spostaTagliando(\DatiVivi.routine.esiti, id: \.id, cliente: \.clienteId, da: Optional(p), a: Optional(d), soli: Set(u.esitiRoutine))
        // Analisi e confronto TFR tornano sulla doppia solo se lì non ne è nata un'altra nel frattempo
        if u.analisiSpostata, dati.analisi[d] == nil, let an = dati.analisi[p] {
            var x = dati.analisi
            x[d] = an
            x[p] = nil
            dati.analisi = x
        }
        if u.confrontoTFRSpostato, dati.confrontiTFR[d] == nil, let tfr = dati.confrontiTFR[p] {
            var x = dati.confrontiTFR
            x[d] = tfr
            x[p] = nil
            dati.confrontiTFR = x
        }
        // I messaggi di Vera arrivati dalla doppia tornano là (quelli scritti dopo restano sulla principale)
        if !u.messaggiVera.isEmpty, let conv = dati.conversazioni[p] {
            let ids = Set(u.messaggiVera)
            let tornano = conv.filter { ids.contains($0.id) }
            if !tornano.isEmpty {
                var x = dati.conversazioni
                let restano = conv.filter { !ids.contains($0.id) }
                x[p] = restano.isEmpty ? nil : restano
                x[d] = tornano + (x[d] ?? [])
                dati.conversazioni = x
            }
        }
        var c = dati.clienti[ip]
        // Si tolgono solo i dati messi dall'unione e ancora uguali: quello scritto dopo resta
        for (campo, valore) in u.riempiti {
            switch campo {
            case "codiceFiscale": if c.codiceFiscale == valore { c.codiceFiscale = "" }
            case "email": if c.email == valore { c.email = "" }
            case "telefono": if c.telefono == valore { c.telefono = "" }
            case "indirizzo": if c.indirizzo == valore { c.indirizzo = "" }
            case "dataNascita": if let n = c.dataNascita, RegistroStrumenti.isoData(n) == valore { c.dataNascita = nil }
            default: break
            }
        }
        // Il resto dell'anagrafica arrivato dalla doppia, anche qui solo se ancora uguale a com'è arrivato
        if let an = u.anagrafica {
            if let v = an.famiglia, c.famiglia == v { c.famiglia = [] }
            if let v = an.profilo, c.profilo == v { c.profilo = ProfiloInvestitore() }
            if let v = an.bisogni, c.bisogni == v { c.bisogni = ProfiloBisogni() }
            if let v = an.fiscale, c.fiscale == v { c.fiscale = nil }
            if let v = an.consensoCopilota, c.consensoCopilota == v { c.consensoCopilota = nil }
            if let v = an.modelloId, c.modelloId == v { c.modelloId = nil }
            if let v = an.statoCivile, c.statoCivile == v { c.statoCivile = nil }
            if let v = an.aziende, c.aziende == v { c.aziende = an.aziendePrima }
            if let v = an.professione, c.professione == v { c.professione = an.professionePrima ?? "" }
        }
        c.canali.removeAll { u.canaliAggiunti.contains($0) }
        // Consensi e «In regola» tornano com'erano solo se nessuno li ha toccati dopo l'unione
        if let dopo = u.consensiDopo, let prima = u.consensiPrima, c.consensi == dopo { c.consensi = prima }
        if u.conformitaUnita, c.conformita == u.conformitaDopo { c.conformita = u.conformitaPrima }
        if let riga = u.rigaNota, let r = c.nota.range(of: riga, options: .backwards) {
            var da = r.lowerBound
            if da > c.nota.startIndex, c.nota[c.nota.index(before: da)] == "\n" { da = c.nota.index(before: da) }
            c.nota.removeSubrange(da..<r.upperBound)
        }
        var elenco = dati.clienti
        elenco[ip] = c
        elenco[id].unitaIn = nil
        dati.clienti = elenco
        aggiornaEsitoTagliando()
        return true
    }

    /// Completa un dato vuoto dell'anagrafica con quello letto in un documento. Un dato già scritto non si sovrascrive.
    private func completaDatoTagliando(_ a: AzioneConferma) -> EsitoAzioneVera {
        let no = { (m: String) in EsitoAzioneVera(fatta: false, messaggio: m) }
        // Una scheda unita nel frattempo (in «Sistema tutto» l'unione viene prima): il dato va sulla principale
        guard let chiesto = a.argomenti["cliente"], case let id = schedaPrincipaleTagliando(chiesto),
              let i = dati.clienti.firstIndex(where: { $0.id == id }), dati.clienti[i].unitaIn == nil, let campo = a.argomenti["campo"],
              let letto = a.argomenti["valore"]?.trimmingCharacters(in: .whitespacesAndNewlines), !letto.isEmpty else {
            return no("Non trovo la scheda del cliente o il dato da completare.")
        }
        var c = dati.clienti[i]
        let valore: String
        let nome: String
        switch campo {
        case TagliandoVera.Campo.codiceFiscale.rawValue:
            guard TagliandoVera.codiceFiscaleValido(letto) else { return no("Il codice fiscale letto non sembra scritto bene: controllalo nel documento.") }
            guard c.codiceFiscale.trimmingCharacters(in: .whitespaces).isEmpty else { return no("La scheda di \(c.nome) ha già un codice fiscale: non lo sovrascrivo.") }
            valore = TagliandoVera.codiceFiscale(letto)
            c.codiceFiscale = valore
            nome = "il codice fiscale"
        case TagliandoVera.Campo.email.rawValue:
            guard TagliandoVera.emailValida(letto) else { return no("L'email letta non sembra scritta bene.") }
            guard c.email.trimmingCharacters(in: .whitespaces).isEmpty else { return no("La scheda di \(c.nome) ha già un'email: non la sovrascrivo.") }
            valore = letto
            c.email = valore
            nome = "l'email"
        case TagliandoVera.Campo.telefono.rawValue:
            guard c.telefono.trimmingCharacters(in: .whitespaces).isEmpty else { return no("La scheda di \(c.nome) ha già un telefono: non lo sovrascrivo.") }
            valore = letto
            c.telefono = valore
            nome = "il telefono"
        case TagliandoVera.Campo.indirizzo.rawValue:
            guard c.indirizzo.trimmingCharacters(in: .whitespaces).isEmpty else { return no("La scheda di \(c.nome) ha già un indirizzo: non lo sovrascrivo.") }
            valore = letto
            c.indirizzo = valore
            nome = "l'indirizzo"
        default:
            return no("Questo dato non si completa dai documenti.")
        }
        dati.clienti[i] = c
        aggiornaEsitoTagliando()
        let fonte = a.argomenti["documento"].flatMap { d in dati.documenti.first { $0.id == d }?.titolo }.map { " letto in «\($0)»" } ?? ""
        return EsitoAzioneVera(fatta: true, messaggio: "La scheda di \(c.nome) ha \(nome)\(fonte).", oggetto: id,
                               prima: Self.jsonTagliando(["campo": campo, "valore": valore]))
    }

    private func disfaDatoTagliando(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, let id = e.oggetto, let i = dati.clienti.firstIndex(where: { $0.id == id }),
              let prima = Self.daJSONTagliando([String: String].self, e.prima), let campo = prima["campo"], let valore = prima["valore"] else { return false }
        var c = dati.clienti[i]
        switch campo {
        case TagliandoVera.Campo.codiceFiscale.rawValue:
            guard c.codiceFiscale == valore else { return false }
            c.codiceFiscale = ""
        case TagliandoVera.Campo.email.rawValue:
            guard c.email == valore else { return false }
            c.email = ""
        case TagliandoVera.Campo.telefono.rawValue:
            guard c.telefono == valore else { return false }
            c.telefono = ""
        case TagliandoVera.Campo.indirizzo.rawValue:
            guard c.indirizzo == valore else { return false }
            c.indirizzo = ""
        default:
            return false
        }
        dati.clienti[i] = c
        aggiornaEsitoTagliando()
        return true
    }

    /// Il tipo del documento d'identità dal titolo del file («Passaporto di…», «Patente…», «Carta d'identità…»).
    static func tipoIdentitaTagliando(_ titolo: String) -> TipoDocumentoIdentita? {
        let t = titolo.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
            .replacingOccurrences(of: "’", with: "'")
        if t.contains("passaport") { return .passaporto }
        if t.contains("patente") { return .patente }
        if t.contains("carta d'identita") || t.contains("carta di identita") || DateItaliane.cerca(#"\bcie\b"#, t) != nil { return .cartaIdentita }
        return nil
    }

    /// Registra nella scheda (In regola) il documento d'identità letto in Documenti: numero, rilascio e scadenza.
    private func registraDocumentoTagliando(_ a: AzioneConferma, oggi: Date) -> EsitoAzioneVera {
        let no = { (m: String) in EsitoAzioneVera(fatta: false, messaggio: m) }
        // Una scheda unita nel frattempo: il documento va registrato sulla principale
        guard let chiesto = a.argomenti["cliente"], case let id = schedaPrincipaleTagliando(chiesto),
              let i = dati.clienti.firstIndex(where: { $0.id == id }), dati.clienti[i].unitaIn == nil,
              let scadenza = RegistroStrumenti.daIso(a.argomenti["scadenza"]) else { return no("Non trovo la scheda del cliente o la scadenza del documento.") }
        var c = dati.clienti[i]
        var conf = c.conformita ?? ConformitaCliente()
        let prima = conf.documento
        let titolo = a.argomenti["documento"].flatMap { d in dati.documenti.first { $0.id == d }?.titolo }
        let numero = a.argomenti["numero"]?.trimmingCharacters(in: .whitespaces)
        conf.documento = DocumentoIdentita(tipo: titolo.flatMap(Self.tipoIdentitaTagliando) ?? prima?.tipo,
                                           numero: (numero?.isEmpty ?? true) ? nil : numero,
                                           rilasciatoIl: RegistroStrumenti.daIso(a.argomenti["rilascio"]), scadenza: scadenza)
        c.conformita = MotoreConformita.normalizzata(conf)
        dati.clienti[i] = c
        aggiornaEsitoTagliando()
        let fonte = titolo.map { " (da «\($0)»)" } ?? ""
        return EsitoAzioneVera(fatta: true, messaggio: "Il documento d'identità di \(c.nome) è registrato\(fonte): scade il \(Formati.dataEstesa.string(from: scadenza)).",
                               oggetto: id, prima: prima.flatMap { Self.jsonTagliando($0) } ?? "")
    }

    private func disfaDocumentoTagliando(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, let id = e.oggetto, let i = dati.clienti.firstIndex(where: { $0.id == id }),
              let scadenza = RegistroStrumenti.daIso(a.argomenti["scadenza"]) else { return false }
        var c = dati.clienti[i]
        // Solo se nella scheda c'è ancora il documento registrato dal tagliando
        guard let ora = c.conformita?.documento?.scadenza, Calendar.current.isDate(ora, inSameDayAs: scadenza) else { return false }
        var conf = c.conformita ?? ConformitaCliente()
        conf.documento = (e.prima ?? "").isEmpty ? nil : Self.daJSONTagliando(DocumentoIdentita.self, e.prima)
        c.conformita = MotoreConformita.normalizzata(conf)
        dati.clienti[i] = c
        aggiornaEsitoTagliando()
        return true
    }
}

/// Com'era prima di «Unisci le schede» (per «Annulla»): gli elementi spostati, i dati riempiti e la riga delle note.
/// Lettura tollerante: un'unione registrata prima che i campi nuovi esistessero si annulla con quelli che ha.
private struct UnioneTagliando: Codable {
    var principale: String
    var doppione: String
    var posizioni: [String] = []
    var documenti: [String] = []
    var appuntamenti: [String] = []
    var attivita: [String] = []
    var note: [String] = []
    var messaggi: [String] = []
    var incontri: [String] = []
    var obiettivi: [String] = []
    var simulazioni: [String] = []
    var valutazioni: [String] = []
    var commenti: [String] = []
    var fotografie: [String] = []
    /// Le schede di adeguatezza (id = la posizione).
    var schedeAdeguatezza: [String] = []
    var parcelle: [String] = []
    var eventiVita: [String] = []
    var sessioniCopilota: [String] = []
    var partiteRischio: [String] = []
    var promesse: [String] = []
    var confrontiDocumenti: [String] = []
    /// Le coperture (id = il documento della polizza).
    var coperture: [String] = []
    /// Le voci chiuse del sussurro (`SussurroChiuso.idTagliando`).
    var sussurriChiusi: [String] = []
    var spiegazioniTreLivelli: [String] = []
    var esitiRoutine: [String] = []
    /// Le voci per cliente passate sulla principale (che non ne aveva una sua).
    var analisiSpostata = false
    var confrontoTFRSpostato = false
    /// I messaggi della conversazione di Vera passati in coda a quella della principale.
    var messaggiVera: [String] = []
    /// Campo → valore messo nella principale dalla scheda doppia (il campo era vuoto).
    var riempiti: [String: String] = [:]
    var canaliAggiunti: [Canale] = []
    var consensiPrima: Consensi?
    var consensiDopo: Consensi?
    /// «In regola» completato con le date della doppia (prima può essere nil: per questo c'è il segno).
    var conformitaUnita = false
    var conformitaPrima: ConformitaCliente?
    var conformitaDopo: ConformitaCliente?
    var rigaNota: String?
    /// Il resto dell'anagrafica messo nella principale dalla doppia (i campi della principale erano vuoti).
    var anagrafica: AnagraficaUnione?

    init(principale: String, doppione: String) {
        self.principale = principale
        self.doppione = doppione
    }

    /// Quanti elementi sono passati sulla principale (per il messaggio).
    var elementiSpostati: Int {
        let elenchi = [posizioni, documenti, appuntamenti, attivita, note, messaggi, incontri, obiettivi, simulazioni, valutazioni,
                       commenti, fotografie, schedeAdeguatezza, parcelle, eventiVita, sessioniCopilota, partiteRischio, promesse,
                       confrontiDocumenti, coperture, sussurriChiusi, spiegazioniTreLivelli, esitiRoutine, messaggiVera]
        return elenchi.reduce(0) { $0 + $1.count } + (analisiSpostata ? 1 : 0) + (confrontoTFRSpostato ? 1 : 0)
    }

    private enum CodingKeys: String, CodingKey {
        case principale, doppione, posizioni, documenti, appuntamenti, attivita, note, messaggi, incontri, obiettivi, simulazioni,
             valutazioni, commenti, fotografie, schedeAdeguatezza, parcelle, eventiVita, sessioniCopilota, partiteRischio, promesse,
             confrontiDocumenti, coperture, sussurriChiusi, spiegazioniTreLivelli, esitiRoutine, analisiSpostata, confrontoTFRSpostato,
             messaggiVera, riempiti, canaliAggiunti, consensiPrima, consensiDopo, conformitaUnita, conformitaPrima, conformitaDopo, rigaNota,
             anagrafica
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        principale = try c.decode(String.self, forKey: .principale)
        doppione = try c.decode(String.self, forKey: .doppione)
        func elenco(_ k: CodingKeys) -> [String] { ((try? c.decodeIfPresent([String].self, forKey: k)) ?? nil) ?? [] }
        posizioni = elenco(.posizioni)
        documenti = elenco(.documenti)
        appuntamenti = elenco(.appuntamenti)
        attivita = elenco(.attivita)
        note = elenco(.note)
        messaggi = elenco(.messaggi)
        incontri = elenco(.incontri)
        obiettivi = elenco(.obiettivi)
        simulazioni = elenco(.simulazioni)
        valutazioni = elenco(.valutazioni)
        commenti = elenco(.commenti)
        fotografie = elenco(.fotografie)
        schedeAdeguatezza = elenco(.schedeAdeguatezza)
        parcelle = elenco(.parcelle)
        eventiVita = elenco(.eventiVita)
        sessioniCopilota = elenco(.sessioniCopilota)
        partiteRischio = elenco(.partiteRischio)
        promesse = elenco(.promesse)
        confrontiDocumenti = elenco(.confrontiDocumenti)
        coperture = elenco(.coperture)
        sussurriChiusi = elenco(.sussurriChiusi)
        spiegazioniTreLivelli = elenco(.spiegazioniTreLivelli)
        esitiRoutine = elenco(.esitiRoutine)
        messaggiVera = elenco(.messaggiVera)
        analisiSpostata = ((try? c.decodeIfPresent(Bool.self, forKey: .analisiSpostata)) ?? nil) ?? false
        confrontoTFRSpostato = ((try? c.decodeIfPresent(Bool.self, forKey: .confrontoTFRSpostato)) ?? nil) ?? false
        riempiti = ((try? c.decodeIfPresent([String: String].self, forKey: .riempiti)) ?? nil) ?? [:]
        canaliAggiunti = ((try? c.decodeIfPresent([Canale].self, forKey: .canaliAggiunti)) ?? nil) ?? []
        consensiPrima = (try? c.decodeIfPresent(Consensi.self, forKey: .consensiPrima)) ?? nil
        consensiDopo = (try? c.decodeIfPresent(Consensi.self, forKey: .consensiDopo)) ?? nil
        conformitaUnita = ((try? c.decodeIfPresent(Bool.self, forKey: .conformitaUnita)) ?? nil) ?? false
        conformitaPrima = (try? c.decodeIfPresent(ConformitaCliente.self, forKey: .conformitaPrima)) ?? nil
        conformitaDopo = (try? c.decodeIfPresent(ConformitaCliente.self, forKey: .conformitaDopo)) ?? nil
        rigaNota = (try? c.decodeIfPresent(String.self, forKey: .rigaNota)) ?? nil
        anagrafica = (try? c.decodeIfPresent(AnagraficaUnione.self, forKey: .anagrafica)) ?? nil
    }
}

/// I campi dell'anagrafica che «Unisci le schede» ha preso dalla doppia (nil = non toccato), per «Annulla». Prima
/// dell'unione quei campi della principale erano vuoti: famiglia vuota, profilo e bisogni mai compilati, gli altri
/// nil; per aziende e professione si tiene anche il valore di prima (nil o vuoto, spazi).
private struct AnagraficaUnione: Codable, Equatable {
    var famiglia: [Familiare]?
    var profilo: ProfiloInvestitore?
    var bisogni: ProfiloBisogni?
    var fiscale: DatiFiscaliCliente?
    var consensoCopilota: ConsensoCopilota?
    var modelloId: String?
    var statoCivile: StatoCivile?
    var aziende: [AziendaCliente]?
    var aziendePrima: [AziendaCliente]?
    var professione: String?
    var professionePrima: String?
}

/// Un nome stabile per una voce chiusa del sussurro (non ha un id suo): la chiave e il momento della chiusura, al
/// secondo come lo salva l'archivio (.iso8601, senza frazioni), così «Annulla» la ritrova anche dopo un riavvio.
fileprivate extension SussurroChiuso {
    var idTagliando: String { "\(chiave)|\(Int(chiusoIl.timeIntervalSinceReferenceDate.rounded(.down)))" }
}

// MARK: - Prova del collegamento (dentro `Prisma --prova-vera`)

extension StatoShell {
    /// Il tagliando nell'app: controllo e registro, «Va bene così», smistamento in chat, «Sistema tutto», e i tre
    /// strumenti con il loro «Annulla» (unione delle schede senza cancellare, completa dai documenti, documento
    /// d'identità). Senza Qwen e senza disco.
    static func provaCollegamentoTagliando(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        // Marco e la sua scheda doppia «M. Bianchi»: stesso telefono, la doppia ha una posizione e il codice fiscale
        guard let im = s.dati.clienti.firstIndex(where: { $0.id == "marco" }) else {
            controlla(false, "Tagliando nell'app: Marco manca nei dati di prova")
            return
        }
        s.dati.clienti[im].telefono = "333 4445566"
        s.dati.clienti[im].codiceFiscale = ""
        var doppia = Cliente(id: "m-bianchi-prova", nome: "M. Bianchi", iniziali: "MB", tinta: .blu, tema: "", email: "",
                             telefono: "+39 333 4445566", preferito: false, nota: "", creatoIl: Date(timeIntervalSinceReferenceDate: 800_000_000))
        doppia.codiceFiscale = "BNCMRC80A01H501U"
        // Il resto dell'anagrafica: il modello del radar e la professione ci sono solo sulla doppia
        doppia.modelloId = "modello-prova-tagliando"
        doppia.professione = "Architetto"
        s.dati.clienti[im].modelloId = nil
        s.dati.clienti[im].professione = ""
        s.dati.clienti.append(doppia)
        var pos = Posizione(clienteId: doppia.id, canale: .alleanza, stato: .inEssere, area: .investimento, nome: "Piano della scheda doppia")
        pos.id = "pos-doppia-prova"
        s.dati.posizioni.append(pos)
        // Ciò che oltre alle otto raccolte di prima deve passare: il consenso privacy (solo sulla doppia), una voce chiusa
        // del sussurro e un messaggio della conversazione di Vera
        s.dati.clienti[im].consensi = Consensi()
        if let id = s.dati.clienti.firstIndex(where: { $0.id == doppia.id }) {
            s.dati.clienti[id].consensi = Consensi(privacy: true, dataPrivacy: Date(timeIntervalSinceReferenceDate: 790_000_000))
        }
        let sussurroDoppia = SussurroChiuso(clienteId: doppia.id, chiave: "prova-tagliando", chiusoIl: Date(timeIntervalSinceReferenceDate: 800_000_100.75))
        s.dati.sussurriChiusi.append(sussurroDoppia)
        let messaggioDoppia = MessaggioVera(autore: .utente, testo: "Domanda sulla scheda doppia")
        s.dati.conversazioni[doppia.id] = [messaggioDoppia]
        // Marco senza email: dopo l'unione «Completa» con la scheda doppia deve scrivere sulla principale
        s.dati.clienti[im].email = ""

        let e = s.eseguiTagliando()
        controlla(s.dati.tagliando.ultimo == e.registro || s.dati.tagliando.ultimo == nil,
                  "Tagliando nell'app: il registro dell'ultimo controllo è quello del controllo (sul Mac)")
        guard let v = e.voci.first(where: { $0.tipo == .doppione && $0.clienti.contains("marco") && $0.clienti.contains(doppia.id) }),
              let unisci = v.correzione?.azione else {
            controlla(false, "Tagliando nell'app: Marco e «M. Bianchi» con lo stesso telefono sono un doppione: \(e.voci.filter { $0.tipo == .doppione }.map(\.dettaglio))")
            return
        }
        let principale = unisci.argomenti["principale"] ?? "", dop = unisci.argomenti["doppione"] ?? ""
        guard let fatto = s.eseguiAzioneTagliando(unisci) else {
            controlla(false, "Tagliando nell'app: «Unisci le schede» è uno strumento del tagliando")
            return
        }
        controlla(fatto.fatta && s.dati.clienti.contains { $0.id == dop && $0.unitaIn == principale } && s.dati.clienti.count == 6,
                  "Tagliando nell'app: «Unisci le schede» segna la doppia come unita e non cancella niente: \(fatto.messaggio)")
        let dopoUnione = s.eseguiTagliando()
        controlla(!dopoUnione.voci.contains { $0.tipo == .doppione } && dopoUnione.schede == 5,
                  "Tagliando nell'app: dopo l'unione il doppione non torna e la scheda unita non conta più")
        controlla(!s.clienti.contains { $0.id == dop } && s.clienti.contains { $0.id == principale } && s.clientiAttivi.count == 5,
                  "Tagliando nell'app: la scheda unita esce dai clienti (resta solo in archivio)")
        if dop == doppia.id {
            controlla(s.dati.posizioni.first { $0.id == pos.id }?.clienteId == principale && s.cliente(principale)?.codiceFiscale == "BNCMRC80A01H501U",
                      "Tagliando nell'app: la posizione passa sulla principale e il codice fiscale mancante arriva dalla doppia")
        }
        controlla(s.cliente(principale)?.consensi.privacy == true,
                  "Tagliando nell'app: il consenso privacy della doppia arriva sulla principale (niente «Consenso privacy mancante» falso)")
        controlla(s.dati.sussurriChiusi.contains { $0.chiave == sussurroDoppia.chiave && $0.clienteId == principale }
                  && s.dati.conversazioni[principale]?.contains { $0.id == messaggioDoppia.id } == true
                  && (dop == principale || s.dati.conversazioni[dop] == nil),
                  "Tagliando nell'app: anche sussurro chiuso e conversazione di Vera passano sulla principale")
        if dop == doppia.id {
            controlla(s.cliente(principale)?.modelloId == "modello-prova-tagliando" && s.cliente(principale)?.professione == "Architetto",
                      "Tagliando nell'app: il resto dell'anagrafica che manca alla principale (modello del radar, professione) arriva dalla doppia")
        }
        // Un'attività per la doppia che arriva dopo l'unione (le voci del consenso commerciale in «Sistema tutto») va
        // sulla principale, non fallisce
        let attivitaDoppia = AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Segno un'attività",
                                            dettaglio: "", argomenti: ["cliente": dop, "titolo": "Rinnovare il consenso commerciale (prova)"])
        if dop != principale {
            let r = s.eseguiAzioneTagliando(attivitaDoppia)
            controlla(r?.fatta == true && s.dati.attivita.contains { $0.clienteId == principale && $0.titolo == "Rinnovare il consenso commerciale (prova)" },
                      "Tagliando nell'app: un'attività per la scheda appena unita va sulla principale: \(r?.messaggio ?? "nessun esito")")
            s.dati.attivita.removeAll { $0.titolo == "Rinnovare il consenso commerciale (prova)" }
        }
        // Dopo un riavvio le date tornano dall'archivio al secondo (.iso8601): «Annulla» ritrova lo stesso le voci chiuse
        do {
            let cod = JSONEncoder()
            cod.dateEncodingStrategy = .iso8601
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            if let riletti = try? dec.decode([SussurroChiuso].self, from: cod.encode(s.dati.sussurriChiusi)) {
                s.dati.sussurriChiusi = riletti
            }
        }
        // «Sistema tutto» mette l'unione prima di «Completa»: l'azione rimasta sulla doppia scrive sulla principale
        let completaDoppia = AzioneConferma(strumento: TagliandoVera.strumentoCompleta, app: .clienti, titolo: "Completo l'email",
                                            dettaglio: "", argomenti: ["cliente": dop, "campo": TagliandoVera.Campo.email.rawValue,
                                                                       "valore": "marco.prova@example.it"])
        if let r = s.eseguiAzioneTagliando(completaDoppia) {
            controlla(r.fatta && r.oggetto == principale && s.cliente(principale)?.email == "marco.prova@example.it"
                      && s.dati.clienti.first { $0.id == dop }?.email.isEmpty == true,
                      "Tagliando nell'app: un dato per una scheda già unita va sulla principale, non sulla doppia: \(r.messaggio)")
            var x = completaDoppia
            x.esito = r
            controlla(s.disfaAzioneTagliando(x) == true && s.cliente(principale)?.email.isEmpty == true,
                      "Tagliando nell'app: «Annulla» toglie il dato dalla principale")
        } else {
            controlla(false, "Tagliando nell'app: «Completa dai documenti» è uno strumento del tagliando")
        }
        var conEsito = unisci
        conEsito.esito = fatto
        // Una principale unita a sua volta a un'altra scheda: «Annulla» di questa unione non dice di esserci riuscito
        if let ip = s.dati.clienti.firstIndex(where: { $0.id == principale }) {
            s.dati.clienti[ip].unitaIn = "laura"
            controlla(s.disfaAzioneTagliando(conEsito) == false && s.dati.clienti.contains { $0.id == dop && $0.unitaIn == principale },
                      "Tagliando nell'app: l'unione di una principale poi unita altrove non si annulla prima dell'altra")
            s.dati.clienti[ip].unitaIn = nil
        }
        controlla(s.disfaAzioneTagliando(conEsito) == true && s.dati.clienti.allSatisfy { $0.unitaIn == nil }
                  && s.dati.posizioni.first { $0.id == pos.id }?.clienteId == doppia.id
                  && s.cliente("marco")?.codiceFiscale.isEmpty == true
                  && s.cliente("marco")?.consensi.privacy == false
                  && (principale != "marco" || (s.cliente("marco")?.modelloId == nil && s.cliente("marco")?.professione.isEmpty == true))
                  && s.dati.sussurriChiusi.contains { $0.chiave == sussurroDoppia.chiave && $0.clienteId == doppia.id }
                  && s.dati.conversazioni[doppia.id]?.contains { $0.id == messaggioDoppia.id } == true
                  && s.dati.conversazioni["marco"]?.contains { $0.id == messaggioDoppia.id } != true,
                  "Tagliando nell'app: «Annulla» rimette le due schede com'erano (anche consensi, sussurro e conversazione)")
        // Eliminare la principale di un'unione libera la scheda doppia (niente `unitaIn` verso una scheda che non c'è)
        do {
            let t = StatoShell(persistente: false)
            var p = Cliente(id: "principale-prova", nome: "Principale Prova", iniziali: "PP", tinta: .blu, tema: "", email: "",
                            telefono: "", preferito: false, nota: "", creatoIl: Date(timeIntervalSinceReferenceDate: 800_000_000))
            p.codiceFiscale = ""
            var d = Cliente(id: "doppia-prova", nome: "P. Prova", iniziali: "PP", tinta: .blu, tema: "", email: "",
                            telefono: "", preferito: false, nota: "", creatoIl: Date(timeIntervalSinceReferenceDate: 800_000_000))
            d.unitaIn = p.id
            t.dati.clienti.append(contentsOf: [p, d])
            if var r = t.dati.impostazioni.stileVera.cortesia {
                r.valore.perCliente[p.id] = .tu
                t.dati.impostazioni.stileVera.cortesia = r
            } else {
                t.dati.impostazioni.stileVera.cortesia = RegolaStile<CortesiaStile>.scritta(CortesiaStile(predefinita: .lei, perCliente: [p.id: .tu]))
            }
            t.eliminaCliente(p.id)
            controlla(t.dati.clienti.first { $0.id == d.id }?.unitaIn == nil && t.clienti.contains { $0.id == d.id }
                      && t.dati.impostazioni.stileVera.cortesia?.valore.perCliente[p.id] == nil,
                      "Tagliando nell'app: eliminata la principale, la scheda unita torna normale e l'eccezione «tu o Lei» se ne va")
        }

        // Completa dai documenti: il codice fiscale di Laura letto nella sua carta d'identità
        if let il = s.dati.clienti.firstIndex(where: { $0.id == "laura" }) {
            s.dati.clienti[il].codiceFiscale = ""
            var d = Documento(clienteId: "laura", titolo: "Carta d'identità di Laura", tipo: .altro)
            d.id = "doc-laura-cie-prova"
            d.categoria = .identita
            d.campi = [CampoEstratto(chiave: .codiceFiscale, valore: "MRTLRA80A41H501Z", pagina: 1, confermato: true),
                       CampoEstratto(chiave: .scadenza, valore: "01/01/2035", pagina: 1, confermato: true),
                       CampoEstratto(chiave: .numeroDocumento, valore: "CA12345AB", pagina: 1, confermato: true)]
            s.dati.documenti.append(d)
            let e2 = s.eseguiTagliando()
            let completa = e2.voci(cliente: "laura").compactMap { $0.correzione?.azione }.first { $0.strumento == TagliandoVera.strumentoCompleta }
            if let completa, let r = s.eseguiAzioneTagliando(completa) {
                controlla(r.fatta && s.cliente("laura")?.codiceFiscale == "MRTLRA80A41H501Z", "Tagliando nell'app: «Completa dai documenti» scrive il codice fiscale")
                var x = completa
                x.esito = r
                controlla(s.disfaAzioneTagliando(x) == true && s.cliente("laura")?.codiceFiscale.isEmpty == true, "Tagliando nell'app: «Annulla» toglie il codice fiscale scritto")
                // Di nuovo: la prima volta lo scrive, la seconda trova il dato già scritto e non lo tocca
                _ = s.eseguiAzioneTagliando(completa)
                let ripetuta = s.eseguiAzioneTagliando(completa)
                controlla(ripetuta?.fatta == false, "Tagliando nell'app: un codice fiscale già scritto non si sovrascrive")
                s.dati.clienti[il].codiceFiscale = ""
            } else {
                controlla(false, "Tagliando nell'app: il codice fiscale nella carta d'identità diventa «Completa dai documenti»")
            }
            let documento = s.eseguiTagliando().voci(cliente: "laura").compactMap { $0.correzione?.azione }.first { $0.strumento == TagliandoVera.strumentoDocumento }
            if let documento, let r = s.eseguiAzioneTagliando(documento) {
                let reg = s.cliente("laura")?.conformita?.documento
                controlla(r.fatta && reg?.numero == "CA12345AB" && reg?.tipo == .cartaIdentita && reg?.scadenza != nil,
                          "Tagliando nell'app: «Registra il documento» scrive numero, tipo e scadenza in «In regola»")
                var x = documento
                x.esito = r
                controlla(s.disfaAzioneTagliando(x) == true && s.cliente("laura")?.conformita?.documento?.numero != "CA12345AB",
                          "Tagliando nell'app: «Annulla» rimette il documento di prima")
            } else {
                controlla(false, "Tagliando nell'app: la carta d'identità in Documenti diventa «Registra il documento»")
            }
        }

        // «Va bene così» e ripristino
        let e3 = s.eseguiTagliando()
        if let prima = e3.voci.first {
            s.ignoraVoceTagliando(prima.id)
            controlla(s.esitoTagliando?.voci.contains { $0.id == prima.id } == false && s.dati.tagliando.ignorate.contains(prima.id),
                      "Tagliando nell'app: «Va bene così» toglie la voce e la ricorda")
            s.ripristinaVoceTagliando(prima.id)
            controlla(s.esitoTagliando?.voci.contains { $0.id == prima.id } == true, "Tagliando nell'app: la voce si rimette nell'elenco")
        }

        // In chat: riassunto, scheda di un cliente, «sistema tutto» dopo il tagliando; una frase d'altro non passa
        s.veraPortafoglio = true
        let chiave = VeraPortafoglio.chiave
        controlla(s.chiediTagliando("Fai il tagliando dell'archivio", chiave: chiave)
                  && s.conversazione(chiave).last?.titolo == titoloTagliando && s.conversazione(chiave).last?.tagliando == "",
                  "Tagliando in chat: «Fai il tagliando dell'archivio» risponde con il riassunto e la scheda")
        controlla(s.chiediTagliando("Sistema tutto", chiave: chiave) && s.conversazione(chiave).last?.conferma?.stato == .daConfermare
                  && s.conversazione(chiave).last?.conferma?.azioni.allSatisfy { $0.esito == nil } == true,
                  "Tagliando in chat: «Sistema tutto» prepara la scheda «Conferma», niente eseguito")
        // Un'attività già segnata non si ripropone in «Sistema tutto» (sarebbe un doppione)
        if let voce = s.esitoTagliandoAggiornato()?.voci.first(where: { $0.correzione?.azione?.strumento == RegistroStrumenti.attivitaNuova }),
           let a = voce.correzione?.azione, let cl = a.argomenti["cliente"], let titolo = a.argomenti["titolo"] {
            s.dati.attivita.append(Attivita(id: "att-tagliando-prova", clienteId: cl, titolo: titolo, scadenza: Date(), priorita: .normale, completata: false))
            let mid = s.sistemaTuttoTagliando()
            let azioni = mid.flatMap { m in s.conversazione(chiave).first { $0.id == m }?.conferma?.azioni } ?? []
            controlla(s.correzioneTagliandoInCorso(voce)
                      && !azioni.contains { $0.strumento == RegistroStrumenti.attivitaNuova && $0.argomenti["cliente"] == cl && $0.argomenti["titolo"] == titolo },
                      "Tagliando nell'app: «Sistema tutto» non ripropone l'attività già segnata")
            s.dati.attivita.removeAll { $0.id == "att-tagliando-prova" }
        }
        // L'elenco si rifà se i dati sono cambiati a pagina chiusa (un codice fiscale scritto a mano)
        if let v = s.esitoTagliandoAggiornato()?.voci.first(where: { $0.tipo == .campiVuoti }), let cl = v.clienti.first,
           let i = s.dati.clienti.firstIndex(where: { $0.id == cl }), s.dati.clienti[i].codiceFiscale.isEmpty {
            s.dati.clienti[i].codiceFiscale = "RSSMRA80A01H501U"
            let rifatto = s.esitoTagliandoAggiornato()
            controlla(s.versioneEsitoTagliando == s.versioneCalcoli && rifatto?.voci.contains { $0.id == v.id } != true,
                      "Tagliando nell'app: dopo una modifica a mano l'elenco del tagliando si rifà prima di usarlo")
        }
        controlla(s.chiediTagliando("Come sta la scheda di Laura? Tagliando di Laura", chiave: chiave) && s.conversazione(chiave).last?.tagliando == "laura",
                  "Tagliando in chat: il tagliando di un cliente nominato")
        controlla(!s.chiediTagliando("Fissa un incontro con Marco giovedì", chiave: chiave) && !s.chiediTagliando("Prenota il tagliando dell'auto", chiave: chiave),
                  "Tagliando in chat: le altre frasi non passano dal tagliando")
        controlla(testoTagliando(e3).contains("\(e3.salute)%"), "Tagliando in chat: le cifre del riassunto sono quelle del controllo")
    }
}
