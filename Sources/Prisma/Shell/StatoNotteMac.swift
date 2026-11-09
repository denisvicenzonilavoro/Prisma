#if os(macOS)
import AppKit

// Il lavoro della notte e le decisioni sulle carte, solo sul Mac («Luce» giro 14, §6.1, decisioni 30, 31, 101).
// Il lavoro: controllo con `NSBackgroundActivityScheduler` (nessun temporizzatore), solo nella finestra serale, alla corrente, con
// Prisma aperto e non in uso; prima i lavori senza Qwen (fase 1, sincrona), poi al più 10 bozze di Vera una alla volta
// (fase 2: il modello si carica una volta e si libera subito; al primo avviso di memoria si ferma). Mai in rete (Qwen è su
// 127.0.0.1). «Approva» non manda mai nulla: le bozze entrano in Messaggi come bozze, i PDF nei Documenti; ogni
// approvazione si annulla.

extension StatoShell {
    // MARK: - Il lavoro

    /// Le condizioni di adesso (decisione 30). Lo schermo spento non conta (Revisione R1).
    func condizioniNotte(adesso: Date, manuale: Bool) -> CondizioniNotte {
        CondizioniNotte(adesso: adesso, impostazioni: dati.impostazioni.notte, allaCorrente: AlimentazioneMac.allaCorrente(),
                        caldo: AlimentazioneMac.caldo, risparmio: AlimentazioneMac.risparmio, backupInCorso: backupInCorso,
                        solaLettura: solaLettura, modoClienteOPresentazione: inModoCliente || presentazione != nil,
                        prismaInUso: NSApplication.shared.isActive && !bloccato, notti: dati.notti, manuale: manuale)
    }

    func controllaNotteMac(adesso: Date) {
        guard persistente, archivioPronto, !solaLettura, !notte.inCorso else { return }
        guard MotoreNotte.attesa(condizioniNotte(adesso: adesso, manuale: false)) == nil else { return }
        avviaNotte(adesso: adesso, manuale: false)
    }

    /// «Prepara adesso»: lo stesso lavoro, chiesto dall'utente (non contano finestra, corrente e «in uso»).
    func preparaAdesso() {
        guard !notte.inCorso else {
            mostraAvviso(TestiNotte.avvisoLavoroInCorso)
            return
        }
        guard !solaLettura else {
            mostraAvviso(TestiNotte.avvisoSolaLettura)
            return
        }
        if let a = MotoreNotte.attesa(condizioniNotte(adesso: Date(), manuale: true)) {
            switch a {
            case .modoCliente: mostraAvviso(TestiNotte.avvisoModoCliente)
            case .backupInCorso: mostraAvviso("C'è un backup in corso: preparo le cose di oggi appena finisce.")
            default: mostraAvviso(TestiNotte.avvisoSolaLettura)
            }
            return
        }
        avviaNotte(adesso: Date(), manuale: true)
    }

    /// Il pianificatore di macOS (circa ogni ora, quando il Mac è libero) e un controllo poco dopo l'avvio. Non si rimanda
    /// con lo schermo spento (`lavoriInPausa` è vero anche allora: Revisione R1).
    func avviaPianificatoreNotte() {
        guard persistente, notte.lavoro.pianificatore == nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + StatoShell.primoControlloNotte) { [weak self] in
            self?.controllaNotte()
        }
        let attivita = NSBackgroundActivityScheduler(identifier: "local.prisma.notte")
        attivita.repeats = true
        attivita.interval = StatoShell.intervalloNotte
        attivita.tolerance = StatoShell.tolleranzaNotte
        attivita.qualityOfService = .background
        attivita.schedule { [weak self] fatto in
            DispatchQueue.main.async {
                self?.controllaNotte()
                fatto(.finished)
            }
        }
        notte.lavoro.pianificatore = attivita
    }

    static let primoControlloNotte: Double = 90
    static let intervalloNotte: TimeInterval = 3600
    static let tolleranzaNotte: TimeInterval = 900

    /// Il lavoro: attività di sistema (al più 20 minuti), fase 1 senza Qwen, poi le bozze di Vera, poi la fine.
    private func avviaNotte(adesso: Date, manuale: Bool) {
        guard !notte.inCorso, notte.lavoro.compito == nil else { return }
        let imp = dati.impostazioni.notte
        let lavoro = notte.lavoro
        lavoro.fermatoPer = nil
        lavoro.attivita = ProcessInfo.processInfo.beginActivity(options: [.background, .idleSystemSleepDisabled],
                                                                reason: "Prisma prepara le carte di domani")
        lavoro.guardia = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(ImpostazioniNotte.minutiMassimi) * 60 * 1_000_000_000)
            if !Task.isCancelled { self?.fermaLavoroNotte(.tempo) }
        }
        notte.inCorso = true
        let fase = preparaFaseUno(adesso: adesso)
        let compiti = imp.usaQwen && imp.prepara(.messaggio) ? fase.compiti : []
        notte.fatte = fase.carte.count
        notte.previste = fase.carte.count + compiti.count
        if sistema.sovrapposizione == .notte { aggiungiAllaPilaNotte(fase.carte.map(\.id)) }
        let giorno = fase.giorno
        lavoro.compito = Task { @MainActor [weak self] in
            guard let self else { return }
            if !compiti.isEmpty { await self.scriviBozzeNotte(compiti, giorno: giorno) }
            self.finisciNotte(giorno: giorno)
        }
    }

    /// Le carte nate mentre la sovrapposizione è aperta entrano in fondo alla pila.
    private func aggiungiAllaPilaNotte(_ ids: [String]) {
        let nuovi = ids.filter { !notte.pila.contains($0) }
        if !nuovi.isEmpty { notte.pila += nuovi }
    }

    /// Fase 1 (sincrona, provabile): i preparativi senza Qwen, le carte nella notte del giorno servito (le rimandate ancora
    /// valide delle notti prima in fondo, con lo stesso id). Restituisce le carte nuove.
    @discardableResult
    func preparaNotteSenzaQwen(adesso: Date = Date()) -> [CartaNotte] {
        preparaFaseUno(adesso: adesso).carte
    }

    private func preparaFaseUno(adesso: Date) -> (carte: [CartaNotte], compiti: [OccasioneMessaggio], giorno: Date) {
        let cal = Calendar.current
        let imp = dati.impostazioni.notte
        let giorno = MotoreNotte.giornoServito(adesso, inizio: imp.inizio, cal: cal)
        let chiave = NotteDiLavoro.chiave(giorno, cal: cal)
        guard !solaLettura else { return ([], [], giorno) }
        let istantanea = dati.istantanea
        var notti = MotoreNotte.pota(istantanea.notti, adesso: adesso, inCorsoAdesso: chiave)
        let precedente = notti.filter { $0.giorno < giorno }.max { $0.giorno < $1.giorno }

        // Il giro del Territorio (stima in linea d'aria, mai la rete): la tabella si carica e, se non serviva, si libera
        let aveva = territorio.tabella != nil
        var giro: GiroGiorno?
        if imp.prepara(.domani) {
            territorio.caricaSeServe()
            if territorio.tabella != nil, partenzaTerritorio() != nil { giro = giroTerritorio(giorno) }
            if !aveva && !aperta(.territorio) { territorio.chiudi() }
        }
        // I riesami con i dati del prospetto (gli altri non nascono: mai inventare)
        var conDati = Set<String>()
        if imp.prepara(.riesame) {
            for r in MotoreRiesame.dovuti(clienti: istantanea.clienti, posizioni: istantanea.posizioni,
                                          appuntamenti: istantanea.appuntamenti, incontri: istantanea.incontri, oggi: giorno)
            where fonteVera(r.cliente.id) != nil {
                conDati.insert(r.cliente.id)
            }
        }
        var modelli: [ModelloModulo] = []
        if imp.prepara(.moduli) {
            moduli.carica()
            modelli = moduli.tutti.filter { $0.compilabile && $0.mappaConfermata }
        }
        let occasioni = MotoreOccasioniMessaggi.calcola(dati: istantanea, oggi: giorno).tutte
        let gruppi = MotoreCampagne.gruppi(dati: istantanea, oggi: giorno).map(\.id)
        let preparativi = MotoreNotte.preparativi(dati: istantanea, giorno: giorno, impostazioni: imp, precedente: precedente,
                                                  giro: giro, riesamiConDati: conDati, modelli: modelli, occasioni: occasioni, cal: cal)
        let daIeri = MotoreNotte.daIeri(notti, giorno: giorno, valida: {
            MotoreNotte.ancoraValida($0, dati: istantanea, oggi: adesso, occasioni: occasioni.map(\.id), gruppi: gruppi, cal: cal)
        }, cal: cal)

        var n = notti.first { $0.giornoChiave == chiave } ?? NotteDiLavoro(giorno: giorno, inizio: nil, cal: cal)
        n.esito = .inCorso
        n.motivoStop = nil
        n.fine = nil
        if n.inizio == nil || n.carte.isEmpty { n.inizio = NotaInArrivo.alSecondo(adesso) }
        n.attenzioni = MotoreNotte.attenzioni(dati: istantanea)
        let nomi = Dictionary(istantanea.clienti.map { ($0.id, $0.nome) }, uniquingKeysWith: { a, _ in a })
        let giaDaIeri = Set(daIeri.map { "\($0.tipo.rawValue)·\($0.riferimento)" })
        var nuove: [CartaNotte] = []
        for p in preparativi where !p.tipo.conQwen {
            let c = MotoreNotte.carta(p, giorno: giorno, adesso: adesso, nomi: nomi, cal: cal)
            // Rifare il lavoro non duplica: una carta con lo stesso id resta com'è (con la sua decisione)
            guard !n.carte.contains(where: { $0.id == c.id }), !giaDaIeri.contains("\(c.tipo.rawValue)·\(c.riferimento)") else { continue }
            n.carte.append(c)
            nuove.append(c)
        }
        for c in daIeri where !n.carte.contains(where: { $0.id == c.id }) { n.carte.append(c) }
        if let i = notti.firstIndex(where: { $0.giornoChiave == chiave }) { notti[i] = n } else { notti.insert(n, at: 0) }
        dati.notti = MotoreNotte.pota(notti, adesso: adesso, inCorsoAdesso: chiave)
        let compiti = MotoreNotte.compitiMessaggi(occasioni, dati: istantanea, massimo: imp.massimoBozze)
            .filter { o in !n.carte.contains { $0.tipo == .messaggio && $0.riferimento == o.id } }
        return (nuove, compiti, giorno)
    }

    /// Una bozza da scrivere: l'occasione con il cliente e la firma letti sul thread principale.
    private struct CompitoBozzaNotte {
        let occasione: OccasioneMessaggio
        let cliente: Cliente
        let firma: String?
    }

    private struct BozzaScrittaNotte {
        let compito: CompitoBozzaNotte
        let scritto: TestoScrittoMessaggio
    }

    /// Fase 2: le bozze di Vera, una alla volta (decisione 101). Vera non pronta → una carta «Da finire».
    @MainActor
    func scriviBozzeNotte(_ occasioni: [OccasioneMessaggio], giorno: Date) async {
        let imp = dati.impostazioni.notte
        let massimo = min(ImpostazioniNotte.tettoBozze, imp.massimoBozze)
        let lista: [CompitoBozzaNotte] = occasioni.prefix(massimo).compactMap { (o: OccasioneMessaggio) -> CompitoBozzaNotte? in
            guard let c = dati.clienti.first(where: { $0.id == o.clienteId }) else { return nil }
            return CompitoBozzaNotte(occasione: o, cliente: c, firma: firmaMessaggio(o.canale, tono: .cordiale))
        }
        guard !lista.isEmpty else { return }
        var impostazioniVera = dati.impostazioni.vera
        impostazioniVera.restaInMemoria = ImpostazioniNotte.restaInMemoriaNotte
        let vera = impostazioniVera
        let disponibilita = await MotoreLocale.verifica(vera)
        guard disponibilita.pronto, notte.lavoro.fermatoPer == nil else {
            aggiungiDaFinire(lista.count, motivo: notte.lavoro.fermatoPer ?? .qwenNonPronto, giorno: giorno)
            return
        }
        let motore = MotoriVera.qwen(vera, locale: disponibilita)
        let esecutore = EsecutoreBozzeNotte()
        notte.lavoro.esecutore = esecutore
        let sorgente = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        sorgente.setEventHandler { [weak esecutore] in esecutore?.ferma(.memoria) }
        sorgente.resume()
        notte.lavoro.memoria = sorgente
        let esito: EsitoBozzeNotte<BozzaScrittaNotte> = await esecutore.esegui(
            lista, massimo: massimo,
            carica: { await motore.fornitore.precarica(restaInMemoria: ImpostazioniNotte.restaInMemoriaNotte) },
            scrivi: { (c: CompitoBozzaNotte) async -> BozzaScrittaNotte? in
                let s = await MessaggiVera.scrivi(c.occasione, cliente: c.cliente, tono: .cordiale, canale: .mail, firma: c.firma,
                                                  motore: motore, vera: vera)
                // Le bozze della notte sono di Vera: il modello fisso resta in Messaggi, non diventa una carta
                guard s.autore == .vera, s.avviso == nil else { return nil }
                return BozzaScrittaNotte(compito: c, scritto: s)
            },
            libera: { await motore.fornitore.libera() })
        sorgente.cancel()
        notte.lavoro.memoria = nil
        notte.lavoro.esecutore = nil
        aggiungiBozzeNotte(esito.fatte, giorno: giorno)
        if esito.daFinire > 0 { aggiungiDaFinire(esito.daFinire, motivo: esito.motivo ?? .qwenNonPronto, giorno: giorno) }
    }

    /// Le bozze scritte diventano carte «messaggio» (una sola assegnazione).
    private func aggiungiBozzeNotte(_ fatte: [BozzaScrittaNotte], giorno: Date) {
        guard !fatte.isEmpty, !solaLettura else { return }
        let chiave = NotteDiLavoro.chiave(giorno)
        var notti = dati.notti
        guard let i = notti.firstIndex(where: { $0.giornoChiave == chiave }) else { return }
        let adesso = Date()
        var nuove: [String] = []
        for b in fatte {
            let o = b.compito.occasione
            let s = b.scritto
            var m = MessaggioCliente(clienteId: o.clienteId, occasioneId: o.id, origine: o.origine, canaleLavoro: o.canale,
                                     tono: .cordiale, canale: .mail, oggetto: s.oggetto, testo: s.testo, cifre: o.cifre,
                                     autore: s.autore, modello: s.modello, creatoIl: NotaInArrivo.alSecondo(adesso))
            m.id = "messaggio-notte-\(chiave)-\(o.id)"
            let p = PreparativoNotte(tipo: .messaggio, clienteId: o.clienteId, riferimento: o.id,
                                     dettagli: .messaggio(occasione: o.id, titolo: o.titolo, perche: o.perche, bozza: m,
                                                          firma: b.compito.firma != nil))
            let c = MotoreNotte.carta(p, giorno: giorno, adesso: adesso, nomi: [o.clienteId: b.compito.cliente.nome])
            guard !notti[i].carte.contains(where: { $0.id == c.id }) else { continue }
            notti[i].carte.append(c)
            nuove.append(c.id)
        }
        dati.notti = notti
        notte.fatte += nuove.count
        if sistema.sovrapposizione == .notte { aggiungiAllaPilaNotte(nuove) }
    }

    /// Una sola carta «Da finire» con le bozze che mancano.
    func aggiungiDaFinire(_ n: Int, motivo: MotivoStopNotte, giorno: Date) {
        guard n > 0, !solaLettura else { return }
        let chiave = NotteDiLavoro.chiave(giorno)
        var notti = dati.notti
        guard let i = notti.firstIndex(where: { $0.giornoChiave == chiave }) else { return }
        let p = PreparativoNotte(tipo: .daFinire, clienteId: nil, riferimento: "bozze", dettagli: .daFinire(bozze: n, motivo: motivo))
        let c = MotoreNotte.carta(p, giorno: giorno, adesso: Date(), nomi: [:])
        if let k = notti[i].carte.firstIndex(where: { $0.id == c.id }) {
            guard !notti[i].carte[k].decisa else { return }
            notti[i].carte[k] = c
        } else {
            notti[i].carte.append(c)
        }
        dati.notti = notti
        if sistema.sovrapposizione == .notte { aggiungiAllaPilaNotte([c.id]) }
    }

    /// Fine del lavoro: fatta o interrotta (con il motivo), attività e memoria via, promemoria e notifiche aggiornati.
    func finisciNotte(giorno: Date) {
        let chiave = NotteDiLavoro.chiave(giorno)
        let motivo = notte.lavoro.fermatoPer
        notte.lavoro.chiudi()
        notte.inCorso = false
        if !solaLettura {
            var notti = dati.notti
            if let i = notti.firstIndex(where: { $0.giornoChiave == chiave }) {
                notti[i].fine = NotaInArrivo.alSecondo(Date())
                notti[i].esito = motivo == nil ? .fatta : .interrotta
                notti[i].motivoStop = motivo
                dati.notti = notti
            }
        }
        ricalcolaNotifiche()
        aggiornaPromemoria()
    }

    // MARK: - Decidere

    /// La posizione della carta nella notte di oggi.
    private func indiceCartaNotte(_ id: String) -> (notte: Int, carta: Int)? {
        guard let n = notteDiOggi, let i = dati.notti.firstIndex(where: { $0.giornoChiave == n.giornoChiave }),
              let k = dati.notti[i].carte.firstIndex(where: { $0.id == id }) else { return nil }
        return (i, k)
    }

    /// Cambia una carta con una sola assegnazione.
    private func cambiaCartaNotte(_ id: String, _ cambia: (inout CartaNotte) -> Void) {
        guard let pos = indiceCartaNotte(id) else { return }
        var notti = dati.notti
        cambia(&notti[pos.notte].carte[pos.carta])
        dati.notti = notti
    }

    /// «Approva» (→, ✓, trascinamento a destra): l'effetto del tipo, mai un invio. Tutto si annulla.
    func approvaCartaNotte(_ id: String) {
        guard !solaLettura else {
            mostraAvviso(TestiSeguito.solaLettura)
            return
        }
        guard let c = cartaNotte(id), !c.decisa else { return }
        var creati: [String] = []
        var note: [String: String] = [:]
        var conferma = c.conferma
        var scaduta = false
        switch c.tipo {
        case .fascicolo:
            guard let a = dati.appuntamenti.first(where: { $0.id == c.riferimento }) else { scaduta = true; break }
            if fascicoloArchiviato(per: a) != nil {
                // Già nei Documenti: non si rifà (l'annullamento non potrebbe rimettere la copia di prima)
                conferma = TestiNotte.confermaFascicoloGiaPronto
            } else {
                let scelta = Set(c.prospetti.compactMap { TipoProspetto(rawValue: $0) })
                guard let fatto = pdfNotte(cliente: a.clienteId, scelta: scelta, appuntamento: a.id, crea: { self.documentoFascicolo() }),
                      let doc = archiviaPDF(fatto.0, titolo: "Report · " + StatoShell.titoloFascicolo(a.inizio), tipo: .report, cliente: a.clienteId) else {
                    mostraAvviso("Non riesco a preparare il fascicolo adesso.")
                    return
                }
                creati = [doc]
            }
        case .riesame:
            guard let cid = c.clienteId, let fatto = pdfNotte(cliente: cid, scelta: nil, appuntamento: nil,
                                                              crea: { self.documentoProspetto(.riesame) }),
                  let doc = archiviaProspetto(fatto.0, documento: fatto.1, cliente: cid) else {
                mostraAvviso("Non riesco a preparare il riesame adesso.")
                return
            }
            creati = [doc]
        case .messaggio:
            creati = salvaBozzeNotte(c.bozze)
        case .documento:
            creati = salvaBozzeNotte(c.bozze)
            if let cid = c.clienteId, let cl = dati.clienti.first(where: { $0.id == cid }) {
                let idAttivita = "notte-\(c.id)"
                if !dati.attivita.contains(where: { $0.id == idAttivita }) {
                    let scadenza = cl.conformita?.documento?.scadenza ?? Date()
                    let att = Attivita(id: idAttivita, clienteId: cid, titolo: TestiNotte.attivitaDocumento(nome: cl.nome),
                                       scadenza: Calendar.current.startOfDay(for: max(scadenza, Date())), priorita: .normale, completata: false)
                    dati.attivita = dati.attivita + [att]
                    creati.append(idAttivita)
                }
            }
        case .ricalcolo, .daFinire:
            break
        case .moduli:
            creati = archiviaModuliNotte(c)
            if creati.isEmpty {
                mostraAvviso("Non riesco a scrivere i moduli compilati adesso.")
                return
            }
        case .campagna:
            guard let g = gruppiCampagne().first(where: { $0.id == c.riferimento }) else { scaduta = true; break }
            guard let campagna = avviaCampagna(g, inclusi: c.clienti, appuntamenti: spaziCampagna().map(\.inizio), tono: .cordiale,
                                               canale: .mail) else {
                scaduta = true
                break
            }
            creati = [campagna.id]
        case .domani:
            var appuntamenti = dati.appuntamenti
            for (k, aid) in c.appuntamenti.enumerated() where k < c.righe.count {
                guard let i = appuntamenti.firstIndex(where: { $0.id == aid }) else { continue }
                let testo = (appuntamenti[i].note.isEmpty ? "" : "\n") + TestiNotte.notaBorsa + c.righe[k]
                appuntamenti[i].note += testo
                note[aid] = testo
            }
            if !note.isEmpty { dati.appuntamenti = appuntamenti }
        }
        if scaduta { mostraAvviso("«\(c.titolo)» non serve più: la tolgo dalle carte.") }
        let adesso = NotaInArrivo.alSecondo(Date())
        cambiaCartaNotte(id) { x in
            x.stato = scaduta ? .scaduta : .approvata
            x.decisaIl = adesso
            x.creati = creati
            x.noteAggiunte = note
        }
        notte.registro.insert(RigaRegistroNotte(id: id, approvata: !scaduta, testo: scaduta ? TestiNotte.rigaRimandata(c.titolo) : conferma), at: 0)
        ricalcolaNotifiche()
    }

    /// Le bozze nella lista di Messaggi (stato «bozza», mai aperte), senza doppioni.
    private func salvaBozzeNotte(_ bozze: [MessaggioCliente]) -> [String] {
        let esistenti = Set(dati.messaggi.map(\.id))
        let clienti = Set(dati.clienti.map(\.id))
        let nuove = bozze.filter { !esistenti.contains($0.id) && clienti.contains($0.clienteId) }
            .map { b -> MessaggioCliente in
                var m = b
                m.stato = .bozza
                m.apertoIl = nil
                return m
            }
        if !nuove.isEmpty { dati.messaggi = dati.messaggi + nuove }
        return nuove.map(\.id)
    }

    /// Il PDF di un prospetto di un altro cliente, cambiando per un momento il cliente attivo (Revisione R5): cliente,
    /// scelta del fascicolo, appuntamento e scenario in sospeso tornano com'erano. Mai in modalità cliente.
    private func pdfNotte(cliente: String, scelta: Set<TipoProspetto>?, appuntamento: String?,
                          crea: () -> DocumentoStampabile?) -> (Data, DocumentoStampabile)? {
        guard !inModoCliente, presentazione == nil else { return nil }
        let primaCliente = dati.clienteAttivoId
        let primaScelta = sceltaFascicolo
        let primoAppuntamento = fascicoloAppuntamento
        let primoScenario = scenarioInSospeso
        defer {
            // Prima il cliente (il suo setter azzera appuntamento e scenario), poi il resto
            clienteAttivoId = primaCliente
            sceltaFascicolo = primaScelta
            fascicoloAppuntamento = primoAppuntamento
            scenarioInSospeso = primoScenario
        }
        clienteAttivoId = cliente
        if let s = scelta { sceltaFascicolo = s }
        fascicoloAppuntamento = appuntamento
        guard let d = crea(), let pdf = MainActor.assumeIsolated({ StampaCarta.pdf(d) }) else { return nil }
        return (pdf, d)
    }

    /// I moduli compilati con i dati di adesso, nei Documenti del cliente (come «Salva nel dossier»).
    private func archiviaModuliNotte(_ c: CartaNotte) -> [String] {
        moduli.carica()
        guard let cid = c.clienteId, let cl = dati.clienti.first(where: { $0.id == cid }),
              let p = dati.posizioni.first(where: { $0.id == c.riferimento }) else { return [] }
        let f = dati.impostazioni.studio.fatturazione
        let consulente = [f.nome, f.cognome].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
        let fonte = FonteCompilazione(cliente: cl, posizione: p, prodotto: p.prodottoId.flatMap { id in dati.prodotti.first { $0.id == id } },
                                      consulente: consulente, comuneConsulente: f.sede.comune, oggi: Date(),
                                      conservaIban: dati.impostazioni.pratiche.ibanConservato)
        var creati: [String] = []
        for mid in c.modelli {
            guard let m = moduli.modello(mid), let base = moduli.pdf(m) else { continue }
            let a = CompilatoreModuli.anteprima(m, fonte: fonte)
            guard let pdf = CompilatoreModuli.scrivi(m, pdf: base, anteprima: a) else { continue }
            let comp = CompilazioneModulo(modelloId: m.id, titoloModello: m.titolo, compilatoIl: Appuntamento.alMinuto(Date()),
                                          mancanti: a.datiMancanti, firme: a.firme.count)
            if let doc = archiviaPDF(pdf, titolo: "Modulo · \(m.titolo) · \(p.nome)", tipo: .modulo, cliente: cid, posizioneId: p.id,
                                     modulo: comp) {
                creati.append(doc)
            }
        }
        return creati
    }

    /// «Più tardi» (←, ✕, trascinamento a sinistra): la carta resta e torna alla prossima apertura (domani «DA IERI»).
    func rimandaCartaNotte(_ id: String) {
        guard !solaLettura else {
            mostraAvviso(TestiSeguito.solaLettura)
            return
        }
        guard let c = cartaNotte(id), !c.decisa else { return }
        let adesso = NotaInArrivo.alSecondo(Date())
        cambiaCartaNotte(id) { x in
            x.stato = .rimandata
            x.decisaIl = adesso
        }
        notte.registro.insert(RigaRegistroNotte(id: id, approvata: false, testo: TestiNotte.rigaRimandata(c.titolo)), at: 0)
    }

    /// «Annulla» (clic sulla riga del registro, ⌘Z sull'ultima): l'effetto si toglie, la carta torna in cima alla pila.
    func annullaCartaNotte(_ id: String) {
        guard !solaLettura, let c = cartaNotte(id) else { return }
        if c.stato == .approvata {
            // Prima la campagna: se una sua bozza è già stata aperta resta, e allora nulla si tocca (la carta resta approvata)
            for cid in c.creati where dati.campagne.contains(where: { $0.id == cid }) {
                guard annullaCampagna(cid) else {
                    mostraAvviso("Una bozza della campagna è già stata aperta: la campagna resta.")
                    return
                }
            }
            for doc in c.creati where dati.documenti.contains(where: { $0.id == doc }) { eliminaDocumento(doc) }
            let bozze = Set(c.creati)
            if dati.messaggi.contains(where: { bozze.contains($0.id) && $0.stato == .bozza }) {
                dati.messaggi = dati.messaggi.filter { !(bozze.contains($0.id) && $0.stato == .bozza) }
            }
            for aid in c.creati where dati.attivita.contains(where: { $0.id == aid && !$0.completata }) { eliminaAttivita(aid) }
            if !c.noteAggiunte.isEmpty {
                var appuntamenti = dati.appuntamenti
                var cambiato = false
                for (aid, testo) in c.noteAggiunte {
                    guard let i = appuntamenti.firstIndex(where: { $0.id == aid }), appuntamenti[i].note.hasSuffix(testo) else { continue }
                    appuntamenti[i].note = String(appuntamenti[i].note.dropLast(testo.count))
                    cambiato = true
                }
                if cambiato { dati.appuntamenti = appuntamenti }
            }
        }
        cambiaCartaNotte(id) { x in
            x.stato = .daDecidere
            x.decisaIl = nil
            x.creati = []
            x.noteAggiunte = [:]
        }
        notte.registro.removeAll { $0.id == id }
        notte.pila.removeAll { $0 == id }
        notte.pila.insert(id, at: 0)
        ricalcolaNotifiche()
    }

    /// ⌘Z: annulla l'ultima decisione.
    func annullaUltimaCartaNotte() {
        guard let ultima = notte.registro.first else { return }
        annullaCartaNotte(ultima.id)
    }

    /// «Apri ›»: chiude la sovrapposizione senza decidere e porta al posto giusto.
    func apriCartaNotte(_ id: String) {
        guard let c = cartaNotte(id) else { return }
        chiudiSovrapposizione()
        switch c.tipo {
        case .fascicolo:
            if let a = dati.appuntamenti.first(where: { $0.id == c.riferimento }) { preparaFascicolo(per: a) }
        case .riesame:
            if let cid = c.clienteId {
                clienteAttivoId = cid
                apriProspetto(.riesame)
            }
        case .messaggio, .documento:
            preparaMessaggio(clienteId: c.clienteId, bozza: c.bozze.first)
        case .ricalcolo:
            if c.clienti.count == 1, let cid = c.clienti.first {
                apriClienteDalRadar(cid)
            } else {
                portafoglio = true
                posizioneInDettaglio = nil
                ancoraPosizioni = "attenzioni"
                apri(.posizioni)
            }
        case .moduli:
            if let cid = c.clienteId {
                scegliClienteModulo(cid)
                scegliPropostaModulo(c.riferimento)
            }
            apriPratiche(.moduli)
        case .campagna:
            apriCampagne(gruppiCampagne().first { $0.id == c.riferimento }?.tipo)
        case .domani:
            apriAgendaGiorno(c.perIl)
        case .daFinire:
            preparaMessaggio()
        }
    }
}
#endif
