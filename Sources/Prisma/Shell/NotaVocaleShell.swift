import Combine
import Foundation

// La nota vocale (Design/template-luce-specifica.md §6.2, «Luce» giro 13) nello stato della shell del Mac: la nota
// arriva dall'iPhone sul ponte (`riceviDalPonte`), entra sempre in `dati.noteInArrivo` (anche con Prisma bloccato) con il
// cliente riconosciuto e le proposte delle regole (Qwen, se pronto, può aggiungere); la scheda «Arriva sul Mac» si mostra
// solo fuori dal blocco, dalla modalità cliente e dalla presentazione (allo sblocco, l'ultima arrivata). Ogni voce si
// conferma o si scarta (decisione 102); il messaggio apre Messaggi con l'occasione; le note decise si tolgono dopo 30
// giorni.

extension StatoShell {
    /// Le note decise si tengono 30 giorni (poi si tolgono: il loro contenuto è già nel dossier).
    static let giorniNoteDecise = 30
    /// Le note da guardare tenute al massimo (le più vecchie decise se ne vanno prima).
    static let massimoNoteInArrivo = 200

    /// Una nota dal ponte: sempre accettata (la stessa due volte resta una), con il cliente e le proposte.
    func riceviNotaVocale(_ p: NotaVocalePonte) -> RicevutaPonte {
        osservaSbloccoNote()
        potaNoteInArrivo()
        let attuale = dati.noteInArrivo
        if attuale.contains(where: { $0.id == p.id }) { return .accettata() }
        var n = NotaInArrivo(da: p)
        let d = dati.istantanea
        switch MotoreNotaVocale.cliente(in: p.testo, clienti: d.clienti, appuntamenti: d.appuntamenti, quando: n.quando,
                                        suggerito: p.clienteId) {
        case .sicuro(let c): n.clienteId = c
        case .dubbio(let c): n.candidati = c
        case .nessuno: break
        }
        let cliente = n.clienteId.flatMap { c in d.clienti.first { $0.id == c } }
        n.proposte = MotoreNotaVocale.proposte(testo: p.testo, cliente: cliente, obiettivi: d.obiettivi, oggi: n.quando)
        var nuove = attuale
        nuove.append(n)
        if nuove.count > Self.massimoNoteInArrivo { nuove.removeFirst(nuove.count - Self.massimoNoteInArrivo) }
        dati.noteInArrivo = nuove
        if bloccato || inModoCliente || presentazione != nil {
            // La scheda porta il testo dettato e il nome di un cliente: allo sblocco (o fuori dalla modalità cliente)
            // resta la notifica, e allo sblocco si apre
            if bloccato { notaInAttesaSblocco = n.id }
        } else {
            notaVocale.mostrata = n.id
        }
        ricalcolaNotifiche()
        riconosciNotaConQwen(n.id)
        return .accettata()
    }

    /// Allo sblocco: la scheda della nota arrivata durante il blocco (abbonamento una volta sola).
    func osservaSbloccoNote() {
        guard !sbloccoNoteOsservato else { return }
        sbloccoNoteOsservato = true
        sistema.bloccatoCambiera
            .removeDuplicates()
            .sink { [weak self] bloccato in
                guard let self, !bloccato, let id = self.notaInAttesaSblocco else { return }
                self.notaInAttesaSblocco = nil
                DispatchQueue.main.async { [weak self] in
                    guard let self, !self.inModoCliente,
                          self.dati.noteInArrivo.contains(where: { $0.id == id && $0.stato == .daGuardare }) else { return }
                    self.notaVocale.mostrata = id
                }
            }
            .store(in: &abbonamenti)
    }

    /// Qwen (se pronto) legge la nota e può aggiungere attività che le regole non hanno trovato; le regole vincono.
    func riconosciNotaConQwen(_ id: String) {
        guard disponibilitaLocale.pronto, let n = dati.noteInArrivo.first(where: { $0.id == id }) else { return }
        let obiettivi = dati.obiettivi.filter { $0.clienteId == n.clienteId }
        let contesto = ContestoCopilota(obiettivi: obiettivi, oggi: n.quando)
        let messaggi = RiconoscitoreCopilota.messaggi(pezzo: n.testo, contesto: contesto, cliente: n.clienteId.flatMap { cliente($0)?.nome })
        let opzioni = RiconoscitoreCopilota.opzioni(dati.impostazioni.vera)
        let motore = qwen
        Task { @MainActor in
            guard let r = try? await motore.scrivi(messaggi, opzioni: opzioni),
                  let schede = RiconoscitoreCopilota.leggiJSON(r.testo, pezzo: n.testo, contesto: contesto),
                  let i = self.dati.noteInArrivo.firstIndex(where: { $0.id == id }),
                  self.dati.noteInArrivo[i].stato == .daGuardare else { return }
            var x = self.dati.noteInArrivo[i]
            x.proposte = MotoreNotaVocale.unisciQwen(regole: x.proposte, qwen: schede, testo: x.testo)
            x.conQwen = true
            self.dati.noteInArrivo[i] = x
        }
    }

    /// «Di chi si parla?»: il cliente scelto dall'utente; le proposte si ricalcolano con lui.
    func scegliClienteNota(_ id: String, clienteId: String) {
        guard let i = dati.noteInArrivo.firstIndex(where: { $0.id == id }), let c = cliente(clienteId) else { return }
        var n = dati.noteInArrivo[i]
        n.clienteId = c.id
        n.candidati = []
        // Le decisioni già prese restano; le proposte aperte si rifanno con il cliente scelto
        let decise = n.proposte.filter { $0.stato != .proposta }
        let nuove = MotoreNotaVocale.proposte(testo: n.testo, cliente: c, obiettivi: dati.obiettivi, oggi: n.quando)
        n.proposte = decise + nuove.filter { p in !decise.contains { $0.id == p.id } }
        dati.noteInArrivo[i] = n
        ricalcolaNotifiche()
    }

    /// Conferma le voci indicate (nil = «Conferma tutto»): una sola assegnazione ai dati. Il messaggio apre Messaggi.
    func confermaNota(_ id: String, proposte ids: Set<String>?, oggi: Date = Date()) {
        guard !solaLettura, let i = dati.noteInArrivo.firstIndex(where: { $0.id == id }) else { return }
        var n = dati.noteInArrivo[i]
        guard let clienteId = n.clienteId, let c = cliente(clienteId) else {
            mostraAvviso("Scegli prima il cliente di cui si parla.")
            return
        }
        var d = dati.istantanea
        let esito = ApplicaNotaVocale.applica(ids, nota: &n, a: &d, oggi: oggi)
        if let k = d.noteInArrivo.firstIndex(where: { $0.id == id }) { d.noteInArrivo[k] = n }
        // Un solo cambio di `dati`: un solo salvataggio
        dati.carica(d)
        ricalcolaNotifiche()
        var parti: [String] = []
        if esito.note > 0 { parti.append("la nota") }
        if esito.attivita > 0 { parti.append(esito.attivita == 1 ? "un'attività" : "\(esito.attivita) attività") }
        if esito.obiettivi > 0 { parti.append("l'obiettivo aggiornato") }
        if !parti.isEmpty { mostraAvviso("Nel dossier di \(c.nome): " + parti.joined(separator: ", ") + ".") }
        // Il messaggio non scrive nell'archivio: si apre Messaggi con l'occasione già pronta
        if let pid = esito.messaggi.first, let p = n.proposte.first(where: { $0.id == pid }) {
            preparaMessaggio(clienteId: c.id, occasione: ApplicaNotaVocale.occasioneMessaggio(p, nota: n, cliente: c))
        }
    }

    func scartaPropostaNota(_ id: String, proposta: String) {
        guard let i = dati.noteInArrivo.firstIndex(where: { $0.id == id }) else { return }
        var n = dati.noteInArrivo[i]
        ApplicaNotaVocale.scarta(proposta, nota: &n)
        dati.noteInArrivo[i] = n
        ricalcolaNotifiche()
    }

    /// Scarta tutta la nota (nessuna voce entra).
    func scartaNota(_ id: String, oggi: Date = Date()) {
        guard let i = dati.noteInArrivo.firstIndex(where: { $0.id == id }) else { return }
        var n = dati.noteInArrivo[i]
        for k in n.proposte.indices where n.proposte[k].stato == .proposta { n.proposte[k].stato = .scartata }
        n.stato = n.proposte.contains { $0.stato == .confermata } ? .confermata : .scartata
        n.decisaIl = NotaInArrivo.alSecondo(oggi)
        dati.noteInArrivo[i] = n
        if notaVocale.mostrata == id { notaVocale.mostrata = nil }
        ricalcolaNotifiche()
    }

    /// Il testo e la data di una voce, modificati sul posto prima di confermare.
    func modificaPropostaNota(_ id: String, proposta: String, titolo: String, scadenza: Date?) {
        guard let i = dati.noteInArrivo.firstIndex(where: { $0.id == id }),
              let k = dati.noteInArrivo[i].proposte.firstIndex(where: { $0.id == proposta }),
              dati.noteInArrivo[i].proposte[k].stato == .proposta else { return }
        var n = dati.noteInArrivo[i]
        let t = titolo.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { n.proposte[k].titolo = t }
        if n.proposte[k].tipo == .attivita {
            n.proposte[k].scadenza = scadenza.map(NotaInArrivo.alSecondo)
            n.proposte[k].scadenzaDaConfermare = false
        }
        dati.noteInArrivo[i] = n
    }

    /// Toglie le note decise da più di 30 giorni (all'avvio e a ogni arrivo); una sola assegnazione, solo se serve.
    func potaNoteInArrivo(oggi: Date = Date()) {
        guard let limite = Calendar(identifier: .gregorian).date(byAdding: .day, value: -Self.giorniNoteDecise, to: oggi) else { return }
        let vecchia: (NotaInArrivo) -> Bool = { n in n.stato != .daGuardare && (n.decisaIl ?? n.arrivataIl) < limite }
        guard dati.noteInArrivo.contains(where: vecchia) else { return }
        dati.noteInArrivo.removeAll(where: vecchia)
    }

    /// Le note ancora da guardare, la più recente in alto (in modalità cliente nessuna: portano i nomi di altri).
    var noteDaGuardare: [NotaInArrivo] {
        guard !inModoCliente else { return [] }
        return dati.noteInArrivo.filter { $0.stato == .daGuardare }.sorted { $0.quando > $1.quando }
    }

    /// «Nota dall’iPhone» nella testata di Incontri: «Come funziona» con le ultime note arrivate.
    func apriComeFunzionaNota() {
        apriSovrapposizione(.scena(.notaVocale))
    }

    /// Dal pannello Novità (voce 13): Incontri, poi «Come funziona» dopo 0,5 s se Incontri era già davanti, 0,9 s se no.
    func apriNotaVocaleDaNovita() {
        #if os(macOS)
        let davanti = appAttiva == .incontri
        apriApp(.incontri)
        let m = Tema.Apple.Moto.NotaVocale.self
        Movimenti.dopo(davanti ? m.aperturaDaNovita : m.aperturaDaNovitaFinestra) { [weak self] in
            self?.apriComeFunzionaNota()
        }
        #else
        apriApp(.incontri)
        #endif
    }

    /// Apre la scheda «Arriva sul Mac» di una nota (dalla colonna Oggi di Incontri o da «Come funziona»).
    func mostraNotaVocale(_ id: String) {
        guard !inModoCliente else { return }
        if sovrapposizione == .scena(.notaVocale) { chiudiSovrapposizione() }
        notaVocale.mostrata = id
    }
}
