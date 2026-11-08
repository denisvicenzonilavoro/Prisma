import Foundation

// La fase 4 di Vera dentro `Prisma --prova-backup` (Vera/BRIEF.md, funzioni 3, 4, 5, 7, 14, 15, 17 e 20). Per ognuna:
// i dati tornano uguali dal backup (l'archivio della prova è scritto a pezzi, quindi passa anche dai file dei clienti e
// dalle sezioni nuove «routine» e «vera»); un archivio senza i campi nuovi si apre con i valori di base; un dato rovinato
// si scarta senza far perdere il resto; ciò che deve restare sul Mac non entra nell'istantanea di «Prisma ovunque».
// In più: un archivio a pezzi scritto prima della fase 4 (indice senza le sezioni nuove) prende i file delle sezioni nuove
// al primo salvataggio per differenze, anche se il loro contenuto non è cambiato.

extension ProvaBackup {
    /// Tutti i dati di prova della fase 4 (chiamata subito dopo `aggiungiFaseTreVeraDiProva`).
    static func aggiungiFaseQuattroVeraDiProva(_ d: inout DatiPrisma) {
        aggiungiRoutineVeraDiProva(&d)
        aggiungiAgendaOrganizzaDiProva(&d)
        aggiungiTagliandoDiProva(&d)
        aggiungiSussurroDiProva(&d)
        aggiungiMercatoClientiVeraDiProva(&d)
        aggiungiStileVeraDiProva(&d)
        aggiungiTreLivelliDiProva(&d)
        aggiungiPassiVeraDiProva(&d)
    }

    /// Tutte le verifiche della fase 4. Restituisce il motivo del primo errore (nil = tutto bene).
    static func verificaFaseQuattroVera(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        if let e = try verificaRoutineVera(originale: originale, estratto: estratto) { return e }
        if let e = try verificaAgendaOrganizza(originale: originale, estratto: estratto) { return e }
        if let e = try verificaTagliando(originale: originale, estratto: estratto) { return e }
        if let e = try verificaSussurro(originale: originale, estratto: estratto) { return e }
        if let e = try verificaMercatoClientiVera(originale: originale, estratto: estratto) { return e }
        if let e = try verificaStileVera(originale: originale, estratto: estratto) { return e }
        if let e = try verificaTreLivelli(originale: originale, estratto: estratto) { return e }
        if let e = try verificaPassiVera(originale: originale, estratto: estratto) { return e }
        if let e = try verificaSezioniNuoveFaseQuattro(originale: originale) { return e }
        return nil
    }

    // MARK: - Un archivio a pezzi di prima: le sezioni nuove si scrivono al primo salvataggio

    /// Un archivio a pezzi scritto prima della fase 4 non ha «routine.json» né «vera.json» e il suo indice non le cita.
    /// Il primo salvataggio per differenze scrive l'indice nuovo (che le cita) e deve scrivere anche i due file, se no
    /// all'avvio dopo mancherebbero.
    static func verificaSezioniNuoveFaseQuattro(originale: DatiPrisma) throws -> String? {
        let fm = FileManager.default
        let cartella = fm.temporaryDirectory.appendingPathComponent("prova-sezioni-fase4-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: cartella) }
        try Archivio.salva(originale, in: cartella)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        // Come un archivio di prima: l'indice senza le due sezioni, i loro file tolti
        let nuove = ["routine", "vera"]
        let urlIndice = ArchivioPezzi.indice(in: cartella)
        guard var indice = try JSONSerialization.jsonObject(with: Data(contentsOf: urlIndice)) as? [String: Any],
              let sezioni = indice["sezioni"] as? [String], nuove.allSatisfy(sezioni.contains) else {
            return "l'indice dell'archivio a pezzi non cita le sezioni «routine» e «vera»"
        }
        indice["sezioni"] = sezioni.filter { !nuove.contains($0) }
        try JSONSerialization.data(withJSONObject: indice).write(to: urlIndice)
        for n in nuove { try? fm.removeItem(at: pezzi.appendingPathComponent(ArchivioPezzi.nomeFileSezione(n))) }
        let prima = try ArchivioPezzi.leggi(pezzi)
        guard prima.problemi.isEmpty, prima.lettura.dati.routine == ArchivioRoutine(), prima.lettura.dati.tagliando == StatoTagliando() else {
            return "un archivio a pezzi senza le sezioni della fase 4 non si apre con le routine e il tagliando di base"
        }
        // Un salvataggio per differenze che non tocca routine e tagliando
        let scrittore = ScrittorePezzi(cartella: cartella)
        scrittore.riparti(da: prima.lettura)
        var cambiati = prima.lettura.dati
        guard !cambiati.clienti.isEmpty else { return "l'archivio di prova non ha clienti" }
        cambiati.clienti[0].nota += " · prova delle sezioni nuove"
        try scrittore.scrivi(cambiati)
        let dopo = try ArchivioPezzi.leggi(pezzi)
        guard dopo.problemi.isEmpty, nuove.allSatisfy({ fm.fileExists(atPath: pezzi.appendingPathComponent(ArchivioPezzi.nomeFileSezione($0)).path) }),
              dopo.lettura.dati.clienti[0].nota == cambiati.clienti[0].nota else {
            return "dopo il primo salvataggio un archivio a pezzi di prima non ha i file delle sezioni «routine» e «vera»"
        }
        return nil
    }

    // MARK: - 3 · Le routine

    static func aggiungiRoutineVeraDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        var r = RoutineVera(id: "routine-backup-1", titolo: "Quando firmo", frase: "Vera, ho firmato con…", inneschi: [#"\bho firmato\b"#],
                            passi: [PassoRoutine(.archiviaContratto), PassoRoutine(.fissaControllo, mesi: 3)],
                            programmazione: ProgrammazioneRoutine(tipo: .dopoFirma), creataIl: t)
        r.usata = 2
        r.ultimoLancio = t
        // «Il mio lunedì» spenta: la copia salvata tiene lo stato della pronta
        var spenta = RoutineVera.pronte()[1]
        spenta.attiva = false
        var e = EsitoRoutine(routineId: r.id, titolo: r.titolo, richiesta: "Vera, ho firmato con \(c.nome)", clienteId: c.id, data: t)
        e.id = "esito-routine-backup"
        e.passi = [EsitoPassoRoutine(tipo: .archiviaContratto, titolo: "Archivio il contratto firmato", dettaglio: "Trascina su Vera il PDF firmato",
                                     stato: .inAttesa, fonte: "Documenti")]
        e.risultato = RisultatoRoutine(titolo: "Tutto in ordine dopo la firma", righe: ["Primo controllo a febbraio (da confermare)"],
                                       pulsanti: [PulsanteRoutine(titolo: "Apri la scheda", app: .clienti, clienteId: c.id)])
        e.scaletta = [RigaScaletta(testo: "Il punto sulla situazione", minuti: 45)]
        e.azioni = [AzioneConferma(strumento: RegistroStrumenti.agendaNuovo, app: .agenda, titolo: "Fisso il primo controllo", dettaglio: "Fra tre mesi",
                                   argomenti: ["cliente": c.id])]
        d.routine = ArchivioRoutine(routine: [r, spenta], esiti: [e])
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaRoutineVera(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard originale.routine.routine.count == 2, originale.routine.esiti.count == 1 else {
            return "l'archivio di prova non ha le routine di Vera"
        }
        guard estratto.routine == originale.routine else {
            return "le routine di Vera e i loro lanci non tornano uguali dal backup"
        }
        guard estratto.routine.tutte.count == 5, estratto.routine.tutte.first(where: { $0.id == RoutineVera.idLunedi })?.attiva == false else {
            return "dal backup le routine pronte non tengono il loro stato (spenta) o manca quella del consulente"
        }
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] else { return "archivio di prova non codificato" }
        radice.removeValue(forKey: "routine")
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard senza.routine == ArchivioRoutine(), senza.routine.tutte.map(\.id) == RoutineVera.pronte().map(\.id),
              senza.clienti.count == originale.clienti.count else {
            return "un archivio senza le routine non si apre con le sole quattro routine pronte"
        }
        // Una routine rovinata (non un oggetto, oppure senza passi leggibili) si scarta, le altre restano
        guard var buona = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.routine)) as? [String: Any],
              var elenco = buona["routine"] as? [Any] else { return "routine di prova non codificate" }
        elenco.insert(["id": "senza-passi", "titolo": "Rotta", "passi": [["tipo": "passoCheNonEsiste"]]] as [String: Any], at: 0)
        elenco.insert("rovinata", at: 0)
        buona["routine"] = elenco
        radice["routine"] = buona
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard letto.routine.routine.map(\.id) == originale.routine.routine.map(\.id), letto.routine.esiti == originale.routine.esiti else {
            return "una routine rovinata fa perdere le altre"
        }
        // Prisma ovunque: le routine sì, i lanci no (la frase del consulente e le bozze restano sul Mac)
        let ist = SpazioOvunque.datiIstantanea(originale)
        guard ist.routine.routine == originale.routine.routine, ist.routine.esiti.isEmpty else {
            return "i lanci delle routine (frasi e bozze) non devono entrare nell'istantanea di Prisma ovunque"
        }
        return nil
    }

    // MARK: - 4 · L'agenda che si organizza

    static func aggiungiAgendaOrganizzaDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let r = RichiestaOrari(intento: .cerca, clienteId: c.id, entro: t.addingTimeInterval(3 * 86_400), durataMinuti: 60, attaccato: true,
                               modo: .studio, tipo: .revisione, daSpostare: "app-agenda-backup")
        let p = OrarioProposto(id: "orario-backup-1", inizio: t.addingTimeInterval(86_400), fine: t.addingTimeInterval(86_400 + 3_600),
                               vicino: "app-vicino-backup", vicinanza: .dopo, etichetta: "subito dopo Laura")
        let q = OrarioProposto(id: "orario-backup-2", inizio: t.addingTimeInterval(2 * 86_400), fine: t.addingTimeInterval(2 * 86_400 + 3_600),
                               vicino: nil, vicinanza: nil, etichetta: "")
        var m = MessaggioVera(autore: .vera, testo: "Ti propongo due orari.", titolo: "Due orari", motore: "Calcoli di Prisma")
        m.id = "msg-agenda-orari-backup"
        m.data = t
        m.agendaOrari = RicercaOrari(richiesta: r, proposte: [p, q], nota: "Nota di prova.")
        m.agendaOrariScelto = p.id
        var n = MessaggioVera(autore: .vera, testo: "Sposto un impegno.", titolo: "Giovedì → venerdì", motore: "Azione")
        n.id = "msg-agenda-blocco-backup"
        n.data = t
        n.agendaSpostamento = SpostamentoBlocco(da: t, a: t.addingTimeInterval(86_400),
                                                mosse: [MossaBlocco(appuntamentoId: "app-blocco-backup", clienteId: c.id, titolo: "Firma del piano casa",
                                                                    luogo: "In studio", canale: .alleanza, durataMinuti: 60, prima: t,
                                                                    inizio: t.addingTimeInterval(86_400), stessaOra: true)],
                                                restano: ["Telefonata"], nota: "«Telefonata» non ci sta.")
        d.conversazioni[c.id, default: []] += [m, n]
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaAgendaOrganizza(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard let c = originale.clienti.first,
              let m = originale.conversazioni[c.id]?.first(where: { $0.id == "msg-agenda-orari-backup" }),
              let n = originale.conversazioni[c.id]?.first(where: { $0.id == "msg-agenda-blocco-backup" }),
              m.agendaOrari?.proposte.count == 2, n.agendaSpostamento != nil else {
            return "l'archivio di prova non ha gli orari dell'agenda che si organizza"
        }
        let tornati = estratto.conversazioni[c.id] ?? []
        guard tornati.first(where: { $0.id == m.id }) == m, tornati.first(where: { $0.id == n.id }) == n else {
            return "gli orari proposti, l'orario scelto o lo spostamento in blocco non tornano uguali dal backup"
        }
        // Un messaggio salvato prima della funzione 4 (senza i campi nuovi) si apre senza orari
        guard var j = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(m)) as? [String: Any] else {
            return "messaggio di prova non codificato"
        }
        for chiave in ["agendaOrari", "agendaOrariScelto", "agendaSpostamento"] { j.removeValue(forKey: chiave) }
        let senza = try Archivio.decodificatore.decode(MessaggioVera.self, from: JSONSerialization.data(withJSONObject: j))
        guard senza.agendaOrari == nil, senza.agendaOrariScelto == nil, senza.agendaSpostamento == nil, senza.testo == m.testo else {
            return "un messaggio di Vera senza i campi dell'agenda che si organizza non si apre"
        }
        // Orari rovinati: si perdono solo gli orari, il messaggio resta
        j["agendaOrari"] = ["richiesta": "rovinata", "proposte": 3] as [String: Any]
        j["agendaSpostamento"] = "rovinato"
        let rovinato = try Archivio.decodificatore.decode(MessaggioVera.self, from: JSONSerialization.data(withJSONObject: j))
        guard rovinato.agendaOrari == nil, rovinato.agendaSpostamento == nil, rovinato.id == m.id, rovinato.testo == m.testo else {
            return "orari rovinati fanno perdere il messaggio di Vera"
        }
        // Le conversazioni (con gli orari e gli spostamenti) non entrano nell'istantanea di Prisma ovunque
        guard SpazioOvunque.datiIstantanea(originale).conversazioni.isEmpty else {
            return "gli orari dell'agenda che si organizza (nelle conversazioni) non devono entrare nell'istantanea di Prisma ovunque"
        }
        return nil
    }

    // MARK: - 5 · Il tagliando dei dati

    static func aggiungiTagliandoDiProva(_ d: inout DatiPrisma) {
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        var s = StatoTagliando()
        s.ultimoControllo = t
        s.ultimo = RegistroTagliando(data: t, salute: 82, schede: d.clienti.count, rosse: 2, arancioni: 3, neutre: 1,
                                     voci: ["privacy-prova-mancante", "doppione-a-b"])
        s.ignorate = ["campi-prova-email"]
        d.tagliando = s
        var i = ImpostazioniTagliando()
        i.attivo = false
        i.ora = 3
        i.minuto = 40
        d.impostazioni.tagliando = i
        if d.clienti.count > 1 { d.clienti[d.clienti.count - 1].unitaIn = d.clienti[0].id }
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaTagliando(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard originale.tagliando.ultimo != nil, originale.clienti.contains(where: { $0.unitaIn != nil }) else {
            return "l'archivio di prova non ha i dati del tagliando"
        }
        guard estratto.tagliando == originale.tagliando, estratto.impostazioni.tagliando == originale.impostazioni.tagliando,
              estratto.clienti.map(\.unitaIn) == originale.clienti.map(\.unitaIn) else {
            return "il tagliando (registro, voci «Va bene così», impostazioni, schede unite) non torna uguale dal backup"
        }
        // Un archivio di prima, senza le chiavi nuove
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] else { return "archivio di prova non codificato" }
        radice.removeValue(forKey: "tagliando")
        if var imp = radice["impostazioni"] as? [String: Any] {
            imp.removeValue(forKey: "tagliando")
            radice["impostazioni"] = imp
        }
        if var clienti = radice["clienti"] as? [[String: Any]] {
            for k in clienti.indices { clienti[k].removeValue(forKey: "unitaIn") }
            radice["clienti"] = clienti
        }
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard senza.tagliando == StatoTagliando(), senza.impostazioni.tagliando == ImpostazioniTagliando(),
              senza.clienti.allSatisfy({ $0.unitaIn == nil }), senza.clienti.count == originale.clienti.count else {
            return "un archivio senza il tagliando non si apre con il tagliando vuoto, acceso alle 2:10"
        }
        // Valori rovinati: si leggono con tolleranza e non fanno perdere altro
        radice["tagliando"] = ["ultimoControllo": "ieri", "ultimo": ["salute": 50], "ignorate": "x"] as [String: Any]
        if var imp = radice["impostazioni"] as? [String: Any] {
            imp["tagliando"] = ["ora": 99, "attivo": "sì"] as [String: Any]
            radice["impostazioni"] = imp
        }
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.tagliando.ultimoControllo == nil, rovinato.tagliando.ultimo == nil, rovinato.tagliando.ignorate.isEmpty,
              rovinato.impostazioni.tagliando.ora == 23, rovinato.impostazioni.tagliando.attivo,
              rovinato.clienti.count == originale.clienti.count else {
            return "un tagliando rovinato non si legge con tolleranza o fa perdere altro"
        }
        // La scrittura a pezzi (sezione «vera» e file dei clienti) e la rilettura
        let fm = FileManager.default
        let cartella = fm.temporaryDirectory.appendingPathComponent("prova-tagliando-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: cartella) }
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        try Archivio.salva(originale, in: cartella)
        let riletto = Archivio.carica(in: cartella).dati
        guard riletto.tagliando == originale.tagliando, riletto.impostazioni.tagliando == originale.impostazioni.tagliando,
              riletto.clienti.map(\.unitaIn) == originale.clienti.map(\.unitaIn) else {
            return "il tagliando non torna uguale dall'archivio a pezzi"
        }
        // Prisma ovunque: gli id delle voci contengono dati delle schede, il tagliando resta sul Mac
        guard SpazioOvunque.datiIstantanea(originale).tagliando == StatoTagliando() else {
            return "il tagliando non deve entrare nell'istantanea di Prisma ovunque"
        }
        return nil
    }

    // MARK: - 7 · Il sussurro

    static func aggiungiSussurroDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        d.sussurriChiusi = [SussurroChiuso(clienteId: c.id, chiave: "privacy", chiusoIl: t),
                            SussurroChiuso(clienteId: c.id, chiave: "scadenza-pos-backup-20261217", chiusoIl: t.addingTimeInterval(86_400))]
        d.impostazioni.vera.sussurroNelDossier = false
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaSussurro(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard originale.sussurriChiusi.count == 2, !originale.impostazioni.vera.sussurroNelDossier else {
            return "l'archivio di prova non ha le voci chiuse del sussurro"
        }
        guard estratto.sussurriChiusi == originale.sussurriChiusi else {
            return "le voci chiuse del sussurro non tornano uguali dal backup"
        }
        guard estratto.impostazioni.vera.sussurroNelDossier == false else {
            return "l'interruttore del sussurro (Impostazioni › Vera) non torna uguale dal backup"
        }
        // Nel formato a pezzi le voci chiuse stanno nel file del cliente
        guard ArchivioPezzi.pezzo(.sussurriChiusi) == .cliente, ArchivioPezzi.campiCliente.contains(where: { $0.chiave == .sussurriChiusi }) else {
            return "le voci chiuse del sussurro non vanno nel file del cliente dell'archivio a pezzi"
        }
        // Un archivio senza il campo: elenco vuoto e sussurro acceso
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] else { return "archivio di prova non codificato" }
        radice.removeValue(forKey: "sussurriChiusi")
        if var imp = radice["impostazioni"] as? [String: Any], var vera = imp["eve"] as? [String: Any] {
            vera.removeValue(forKey: "sussurroNelDossier")
            imp["eve"] = vera
            radice["impostazioni"] = imp
        }
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard senza.sussurriChiusi.isEmpty, senza.impostazioni.vera.sussurroNelDossier, senza.clienti.count == originale.clienti.count else {
            return "un archivio senza le voci chiuse del sussurro non si apre con l'elenco vuoto e il sussurro acceso"
        }
        // Una riga rovinata si scarta, le altre restano
        guard let buona = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode([originale.sussurriChiusi[0]])) as? [[String: Any]])?.first else {
            return "voce chiusa di prova non codificata"
        }
        radice["sussurriChiusi"] = [["chiave": "senza cliente"], "rovinata", buona] as [Any]
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.sussurriChiusi == [originale.sussurriChiusi[0]] else {
            return "una voce chiusa rovinata fa perdere le altre"
        }
        // La scheda «Conferma» del sussurro torna uguale (origine compresa)
        let azione = AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Segno un'attività",
                                    dettaglio: "«Rinnovare il consenso privacy» · entro oggi",
                                    argomenti: ["cliente": originale.clienti[0].id, "titolo": "Rinnovare il consenso privacy"])
        let scheda = SchedaConfermaVera(richiesta: "Prepara il rinnovo", azioni: [azione], origine: .sussurro)
        let letta = try JSONDecoder().decode(SchedaConfermaVera.self, from: JSONEncoder().encode(scheda))
        guard letta.origine == .sussurro, letta.azioni == scheda.azioni else {
            return "la scheda «Conferma» del sussurro non torna uguale"
        }
        // La chiave di una preferenza (inizio di un ricordo di Vera) nell'archivio va solo come impronta
        let preferenza = StatoShell.chiaveSussurroArchivio("preferenza-decide sempre insieme a paolo")
        guard preferenza.hasPrefix("preferenza-#"), !preferenza.contains("paolo"),
              StatoShell.chiaveSussurroArchivio("privacy") == "privacy" else {
            return "la chiave di una preferenza chiusa porta nell'archivio il testo del ricordo"
        }
        return nil
    }

    // MARK: - 14 · Il mercato per i tuoi clienti

    static func esitoMercatoClientiDiProva(cliente c: Cliente) -> EsitoMercatoVera {
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let cal = Calendar(identifier: .gregorian)
        let e = EventoMercatoVera(tipo: .borse, misura: -8, verso: -1, periodo: "in una settimana", origine: .aParole, fonte: "Detto a Vera",
                                  data: t, frase: "Le borse hanno perso l'8% in una settimana", cal: cal)
        let motivo = MotivoMercatoVera(regola: .azioniCalo,
                                       testo: "Il 52% del suo investito è in azioni (36.400 €): con un calo dell'8% sono circa 2.912 € in meno.",
                                       cifre: [CifraMercatoVera(etichetta: "Quota in azioni", valore: "52%"),
                                               CifraMercatoVera(etichetta: "Calo stimato", valore: "2.912 €")],
                                       azione: .chiamaOggi, posizioni: ["pos-backup"], obiettivoId: nil, canale: .alleanza, impatto: -2_912)
        let toccato = ClienteToccatoVera(clienteId: c.id, nome: c.nome, motivi: [motivo], azione: .chiamaOggi,
                                         etichettaAzione: "Chiama \(StatoShell.primoNome(c.nome)) oggi", canale: .alleanza,
                                         incontro: t.addingTimeInterval(3 * 86_400), speseStimate: true)
        return EsitoMercatoVera(evento: e, sintesi: TestiMercatoClienti.sintesi(e), toccati: [toccato], oltre: 2, calcolatoIl: t)
    }

    static func aggiungiMercatoClientiVeraDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        var m = MessaggioVera(autore: .vera, testo: "Tocca 3 dei tuoi clienti.", titolo: "Le borse perdono l'8% in una settimana", motore: "Calcoli di Prisma")
        m.id = "msg-mercato-backup"
        m.mercatoClienti = esitoMercatoClientiDiProva(cliente: c)
        m.mercatoBozze = "msg-mercato-bozze-backup"
        d.conversazioni[VeraPortafoglio.chiave, default: []].append(m)
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaMercatoClientiVera(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        let id = "msg-mercato-backup"
        guard let o = originale.conversazioni[VeraPortafoglio.chiave]?.first(where: { $0.id == id }), let esito = o.mercatoClienti,
              esito.toccati.count == 1, o.mercatoBozze != nil else {
            return "l'archivio di prova non ha l'elenco del mercato per i clienti"
        }
        guard let x = estratto.conversazioni[VeraPortafoglio.chiave]?.first(where: { $0.id == id }), x == o,
              x.mercatoClienti?.toccati.first?.motivi.first?.cifre == esito.toccati[0].motivi[0].cifre,
              x.mercatoClienti?.evento.id == esito.evento.id else {
            return "l'elenco del mercato per i clienti (evento, clienti toccati, cifre, bozze) non torna uguale dal backup"
        }
        // Un messaggio salvato da un Prisma di prima (senza i campi nuovi) e uno con l'elenco rovinato
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var conversazioni = radice["conversazioni"] as? [String: Any],
              var portafoglio = conversazioni[VeraPortafoglio.chiave] as? [[String: Any]],
              let i = portafoglio.firstIndex(where: { ($0["id"] as? String) == id }) else {
            return "archivio di prova non codificato"
        }
        portafoglio[i].removeValue(forKey: "mercatoClienti")
        portafoglio[i].removeValue(forKey: "mercatoBozze")
        conversazioni[VeraPortafoglio.chiave] = portafoglio
        radice["conversazioni"] = conversazioni
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard let s = senza.conversazioni[VeraPortafoglio.chiave]?.first(where: { $0.id == id }), s.mercatoClienti == nil, s.mercatoBozze == nil,
              s.testo == o.testo, senza.clienti.count == originale.clienti.count else {
            return "un messaggio di Vera senza l'elenco del mercato non si apre"
        }
        portafoglio[i]["mercatoClienti"] = ["evento": "rovinato", "toccati": 3] as [String: Any]
        conversazioni[VeraPortafoglio.chiave] = portafoglio
        radice["conversazioni"] = conversazioni
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard let r = rovinato.conversazioni[VeraPortafoglio.chiave]?.first(where: { $0.id == id }), r.mercatoClienti == nil,
              r.testo == o.testo, r.titolo == o.titolo,
              rovinato.conversazioni[VeraPortafoglio.chiave]?.count == originale.conversazioni[VeraPortafoglio.chiave]?.count else {
            return "un elenco del mercato rovinato fa perdere il messaggio o la conversazione"
        }
        // Prisma ovunque: le conversazioni (e quindi l'elenco con i nomi e le cifre dei clienti) non vanno nell'istantanea
        guard SpazioOvunque.datiIstantanea(originale).conversazioni.isEmpty else {
            return "l'elenco del mercato per i clienti non deve entrare nell'istantanea di Prisma ovunque"
        }
        return nil
    }

    // MARK: - 15 · Scrive come te

    static func aggiungiStileVeraDiProva(_ d: inout DatiPrisma) {
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        var p = ProfiloStile()
        p.cortesia = .imparata(CortesiaStile(predefinita: .lei, sogliaEta: 40, perCliente: [d.clienti.first?.id ?? "giulia": .tu]), da: 214)
        p.lunghezzaFrasi = .imparata(14, da: 252)
        p.unaCosaPerRiga = .imparata(true, da: 188)
        p.primaGiornoEOra = .imparata(true, da: 96)
        p.firma = .scritta("Denis")
        p.formuleVietate = .imparata(["con la presente", "cordiali saluti"], da: 252)
        var emoji = RegolaStile<UsoEmoji>.imparata(.soloClientiNoti, da: 252)
        emoji.attiva = false
        p.emoji = emoji
        p.aperture = .imparata(["Ciao ‹nome›,", "Gentile ‹nome›,"], da: 201)
        p.chiusure = .scritta(["A presto!"])
        p.messaggiLetti = 214
        p.mailLette = 38
        p.aggiornatoIl = t
        d.impostazioni.stileVera = p
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaStileVera(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        let p = originale.impostazioni.stileVera
        guard p.firma?.valore == "Denis", p.emoji?.attiva == false, p.messaggiLetti == 214 else {
            return "l'archivio di prova non ha il profilo di stile di Vera"
        }
        guard estratto.impostazioni.stileVera == p else {
            return "il profilo di stile (Scrive come te) non torna uguale dal backup"
        }
        guard estratto.impostazioni.stileVera.firma?.origine == .scritta, estratto.impostazioni.stileVera.emoji?.attiva == false,
              estratto.impostazioni.stileVera.cortesia?.valore.sogliaEta == 40 else {
            return "il profilo di stile perde l'origine «scritta da te» o una regola spenta"
        }
        // Un archivio senza il profilo (di prima della funzione 15) si apre con il profilo vuoto
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var impostazioni = radice["impostazioni"] as? [String: Any] else { return "archivio di prova non codificato" }
        impostazioni.removeValue(forKey: "stileVera")
        radice["impostazioni"] = impostazioni
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard senza.impostazioni.stileVera == ProfiloStile(), senza.impostazioni.stileVera.vuoto,
              senza.impostazioni.nomeUtente == originale.impostazioni.nomeUtente, senza.clienti.count == originale.clienti.count else {
            return "un archivio senza il profilo di stile non si apre con il profilo vuoto"
        }
        // Una regola rovinata si scarta, le altre restano (e un profilo rovinato del tutto non fa perdere le impostazioni)
        guard var profilo = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(p)) as? [String: Any] else {
            return "profilo di prova non codificato"
        }
        profilo["firma"] = "rovinata"
        profilo["lunghezzaFrasi"] = ["valore": 1, "origine": "imparata", "messaggi": 3] as [String: Any]
        impostazioni["stileVera"] = profilo
        radice["impostazioni"] = impostazioni
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.impostazioni.stileVera.firma == nil, rovinato.impostazioni.stileVera.lunghezzaFrasi == nil,
              rovinato.impostazioni.stileVera.cortesia == p.cortesia, rovinato.impostazioni.stileVera.chiusure == p.chiusure else {
            return "una regola di stile rovinata fa perdere le altre"
        }
        impostazioni["stileVera"] = "rovinato del tutto"
        radice["impostazioni"] = impostazioni
        let tuttoRovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard tuttoRovinato.impostazioni.stileVera.vuoto, tuttoRovinato.impostazioni.nomeUtente == originale.impostazioni.nomeUtente else {
            return "un profilo di stile illeggibile fa perdere le impostazioni"
        }
        // Prisma ovunque: il profilo (solo regole) va nell'istantanea; le impostazioni di Vera no, come prima
        guard SpazioOvunque.datiIstantanea(originale).impostazioni.stileVera == p else {
            return "il profilo di stile non entra nell'istantanea di Prisma ovunque"
        }
        // Un cambio di stile non rifà i calcoli
        var cambiato = originale.impostazioni
        cambiato.stileVera.firma = .scritta("Denis V.")
        guard cambiato.stessiCalcoli(di: originale.impostazioni) else {
            return "un cambio del profilo di stile non deve rifare i calcoli (Impostazioni.stessiCalcoli)"
        }
        return nil
    }

    // MARK: - 17 · Tre livelli

    static func aggiungiTreLivelliDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        var s = SpiegazioneTreLivelli(clienteId: c.id, nomeCliente: c.nome, argomento: .previdenza,
                                      domanda: "Perché il fondo pensione conviene?", creataIl: t,
                                      cifre: [CifraTreLivelli(id: "divario", etichetta: "Ti mancano, al mese", valore: 1100, testo: "1.100 €", essenziale: true),
                                              CifraTreLivelli(id: "aliquotaBase", etichetta: "Imposta massima alla pensione", valore: 15, testo: "15%", essenziale: true),
                                              CifraTreLivelli(id: "riduzione", etichetta: "Riduzione per ogni anno oltre il quindicesimo", valore: 0.3, testo: "0,3 punti")],
                                      tecnico: ["Il divario: 1.100 € al mese.", "Prestazione tassata al 15%, poi 0,3 punti in meno per ogni anno."],
                                      cliente: "Ti mancheranno circa 1.100 € al mese.\nAlla pensione pagherai al massimo il 15%.",
                                      pagina: PaginaTreLivelli(titolo: "Il fondo pensione, in una pagina",
                                                               sezioni: [SezionePaginaTreLivelli(titolo: "Quanto ti servirà", righe: ["Ti mancano: 1.100 € al mese"]),
                                                                         SezionePaginaTreLivelli(titolo: "Perché il fondo", righe: ["Alla pensione paghi al massimo il 15%."])]),
                                      canale: .alleanza, nomi: [c.nome, "Piano 2030"],
                                      note: ["Manca il reddito lordo annuo nel profilo."], livelliQwen: [.cliente, .pagina])
        s.id = "tre-livelli-backup-1"
        var elenco = [s]
        if let altro = d.clienti.dropFirst().first {
            var l = SpiegazioneTreLivelli(clienteId: altro.id, nomeCliente: altro.nome, argomento: .liquidita, domanda: "La liquidità in una pagina",
                                          creataIl: t, cifre: [CifraTreLivelli(id: "totale", etichetta: "Liquidità oggi", valore: 42_000, testo: "42.000 €", essenziale: true)],
                                          tecnico: ["Liquidità oggi 42.000 €."], cliente: "Oggi hai 42.000 € tra conti e risparmi pronti.",
                                          pagina: PaginaTreLivelli(titolo: "La tua liquidità, in una pagina",
                                                                   sezioni: [SezionePaginaTreLivelli(titolo: "Quanto hai", righe: ["Disponibile: 42.000 €"])]))
            l.id = "tre-livelli-backup-2"
            elenco.append(l)
        }
        d.spiegazioniTreLivelli = elenco
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaTreLivelli(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard originale.spiegazioniTreLivelli.count == 2 else { return "l'archivio di prova non ha le spiegazioni in tre livelli" }
        guard estratto.spiegazioniTreLivelli == originale.spiegazioniTreLivelli else {
            return "le spiegazioni in tre livelli non tornano uguali dal backup"
        }
        // A pezzi: ogni spiegazione nel pezzo del suo cliente; rimesse insieme tornano identiche, ordine compreso
        guard ArchivioPezzi.pezzo(.spiegazioniTreLivelli) == .cliente,
              let campo = ArchivioPezzi.campiCliente.first(where: { $0.chiave == .spiegazioniTreLivelli }) else {
            return "le spiegazioni in tre livelli non vanno nel file del cliente dell'archivio a pezzi"
        }
        let noti = Set(originale.clienti.map(\.id))
        let gruppo: (String) -> String = { noti.contains($0) ? $0 : ArchivioPezzi.gruppoAltri }
        var pezzi: [String: DatiPrisma] = [:]
        let (ordine, _) = campo.distribuisci(originale, gruppo, &pezzi)
        for (g, p) in pezzi where !p.spiegazioniTreLivelli.allSatisfy({ gruppo($0.clienteId) == g }) {
            return "una spiegazione in tre livelli finisce nel file di un altro cliente"
        }
        var rimesso = ArchivioPezzi.vuoto
        campo.raccogli(pezzi, pezzi.keys.sorted(), ordine, &rimesso)
        guard rimesso.spiegazioniTreLivelli == originale.spiegazioniTreLivelli else {
            return "le spiegazioni in tre livelli non tornano uguali dai pezzi"
        }
        // Un archivio di prima, senza il campo: lista vuota, il resto intatto
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] else { return "archivio di prova non codificato" }
        radice.removeValue(forKey: "spiegazioniTreLivelli")
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard senza.spiegazioniTreLivelli.isEmpty, senza.clienti.count == originale.clienti.count else {
            return "un archivio senza le spiegazioni in tre livelli non si apre con la lista vuota"
        }
        // Una spiegazione rovinata si scarta, le altre restano
        guard let buona = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode([originale.spiegazioniTreLivelli[0]])) as? [[String: Any]])?.first else {
            return "spiegazione di prova non codificata"
        }
        radice["spiegazioniTreLivelli"] = ["rovinata", 42, buona] as [Any]
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.spiegazioniTreLivelli.map(\.id) == ["tre-livelli-backup-1"],
              rovinato.spiegazioniTreLivelli.first == originale.spiegazioniTreLivelli[0] else {
            return "una spiegazione in tre livelli rovinata fa perdere le altre"
        }
        // Restano sul Mac: niente nell'istantanea di Prisma ovunque
        guard SpazioOvunque.datiIstantanea(originale).spiegazioniTreLivelli.isEmpty else {
            return "le spiegazioni in tre livelli non devono entrare nell'istantanea di Prisma ovunque"
        }
        return nil
    }

    // MARK: - 20 · Ragiona a passi

    static let idMessaggioPassiDiProva = "msg-backup-passi"

    static func aggiungiPassiVeraDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let r = RichiestaPassi(testo: "Ha 400 € al mese: proteggere la famiglia e gli studi, come li divido?", clienteId: c.id, budgetMensile: 400,
                               protezione: true, obiettiviIds: ["obiettivo-backup-passi"], protetta: "la famiglia")
        var piano = PianoPassi(richiesta: r, passi: [
            PassoPiano(id: 1, strumento: .leggiProtezione, titolo: "Leggo la protezione della famiglia", obiettivoId: nil, stato: .fatto,
                       esito: "Da Prisma: servono 620.000 €, oggi ce ne sono 150.000 €"),
            PassoPiano(id: 2, strumento: .simulaDivisioni, titolo: "Simulo tre divisioni dei 400 €", obiettivoId: nil, stato: .fatto,
                       esito: "Con il simulatore di Prisma"),
            PassoPiano(id: 3, strumento: .scegliESpiega, titolo: "Scelgo e spiego", obiettivoId: nil, stato: .fatto,
                       esito: "Equilibrio: la divisione che regge su tutti gli obiettivi"),
        ], conQwen: true, creatoIl: t)
        piano.id = "passi-backup"
        piano.divisioni = [DivisioneBudget(tipo: .equilibrio, titolo: "Equilibrio", protezioneMensile: 200,
                                           quote: [QuotaObiettivo(obiettivoId: "obiettivo-backup-passi", titolo: "Studi", mensile: 200, scadenza: t,
                                                                  importoScadenza: 30_000, proiezione: 31_000, copertura: 1, inTempo: true,
                                                                  anniAnticipo: 1, anniRitardo: nil, raggiunto: t)],
                                           capitaleAggiunto: 280_000, coperturaProtezione: 0.7, scopertoProtezione: 190_000)]
        piano.consigliata = .equilibrio
        piano.regge = true
        piano.vincoli = [VincoloPassi(tipo: .rinnovo, testo: "Infortuni famiglia da rinnovare entro il 17 dicembre", data: t, posizioneId: "pos-backup")]
        piano.spiegazione = "Ti consiglio «Equilibrio» (200 € alla protezione e 200 € a «Studi»)."
        piano.spiegazioneConQwen = true
        var m = MessaggioVera(autore: .vera, testo: piano.spiegazione, titolo: StatoShell.titoloPassi, motore: "Qwen sul Mac")
        m.id = idMessaggioPassiDiProva
        m.pianoPassi = piano
        d.conversazioni[c.id, default: []].append(m)
        // Valori diversi da quelli di base, per vedere che tornano
        d.impostazioni.vera.passi.mostraRagionamento = false
        d.impostazioni.vera.passi.attivo = false
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaPassiVera(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard let c = originale.clienti.first,
              let m = originale.conversazioni[c.id]?.first(where: { $0.id == idMessaggioPassiDiProva }), let piano = m.pianoPassi,
              !originale.impostazioni.vera.passi.attivo, !originale.impostazioni.vera.passi.mostraRagionamento else {
            return "l'archivio di prova non ha il ragionamento a passi"
        }
        guard estratto.conversazioni[c.id]?.first(where: { $0.id == m.id })?.pianoPassi == piano,
              estratto.impostazioni.vera.passi == originale.impostazioni.vera.passi else {
            return "il piano del ragionamento a passi o le sue impostazioni non tornano uguali dal backup"
        }

        // Scrittura a pezzi: il piano sta con la conversazione e torna uguale
        let fm = FileManager.default
        let cartella = fm.temporaryDirectory.appendingPathComponent("prova-passi-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: cartella) }
        try ScrittorePezzi(cartella: cartella).scrivi(originale)
        let letto = try ArchivioPezzi.leggi(ArchivioPezzi.cartellaPezzi(in: cartella)).lettura.dati
        guard letto.conversazioni[c.id]?.first(where: { $0.id == m.id })?.pianoPassi == piano,
              letto.impostazioni.vera.passi == originale.impostazioni.vera.passi else {
            return "il piano del ragionamento a passi non torna uguale dall'archivio a pezzi"
        }

        // Un archivio di prima: senza «pianoPassi» nei messaggi e senza «passi» nelle impostazioni di Vera (chiave «eve»)
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] else { return "archivio di prova non codificato" }
        func conMessaggio(_ cambia: (inout [String: Any]) -> Void) {
            guard var conv = radice["conversazioni"] as? [String: Any], var elenco = conv[c.id] as? [[String: Any]] else { return }
            for i in elenco.indices where elenco[i]["id"] as? String == m.id { cambia(&elenco[i]) }
            conv[c.id] = elenco
            radice["conversazioni"] = conv
        }
        conMessaggio { $0.removeValue(forKey: "pianoPassi") }
        if var imp = radice["impostazioni"] as? [String: Any], var vera = imp["eve"] as? [String: Any] {
            vera.removeValue(forKey: "passi")
            imp["eve"] = vera
            radice["impostazioni"] = imp
        }
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard let ms = senza.conversazioni[c.id]?.first(where: { $0.id == m.id }), ms.pianoPassi == nil, ms.testo == m.testo,
              senza.impostazioni.vera.passi == ImpostazioniPassiVera(), senza.clienti.count == originale.clienti.count else {
            return "un archivio senza il ragionamento a passi non si apre con il messaggio intero e le impostazioni di base"
        }

        // Un piano rovinato: il messaggio resta, senza piano
        conMessaggio { $0["pianoPassi"] = "rovinato" }
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard let mr = rovinato.conversazioni[c.id]?.first(where: { $0.id == m.id }), mr.pianoPassi == nil, mr.testo == m.testo else {
            return "un piano del ragionamento a passi rovinato fa perdere il messaggio"
        }

        // Prisma ovunque: i piani (nelle conversazioni) e le impostazioni di Vera restano sul Mac
        let ist = SpazioOvunque.datiIstantanea(originale)
        guard ist.conversazioni.isEmpty, ist.impostazioni.vera.passi == ImpostazioniPassiVera() else {
            return "il ragionamento a passi (piani nelle conversazioni, impostazioni di Vera) non deve entrare nell'istantanea di Prisma ovunque"
        }
        return nil
    }
}
