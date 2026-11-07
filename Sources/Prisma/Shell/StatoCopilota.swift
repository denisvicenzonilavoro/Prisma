import Foundation

// Il copilota dell'incontro e i messaggi nuovi del ponte nello stato (Orizzonte, giro 5; specifica §8 e §9).
// - Il consenso all'ascolto si registra nel dossier del cliente; senza consenso nessuna sessione parte
//   (`GuardiaCopilota`, l'unica porta).
// - Ogni pezzo di trascrizione (solo testo) passa dalle regole di Prisma e, se Qwen è pronto, da Qwen; le schede
//   nascono proposte e restano nella sessione finché il consulente non le conferma (una o tutte).
// - Alla chiusura si scrive il verbale; senza «Conserva la trascrizione» il testo del cliente si dimentica.
// - Dal ponte arrivano le schede riconosciute sull'iPad e i testi inquadrati con l'iPhone: le prime entrano nella
//   sessione come proposte, i secondi aspettano in `inquadratureInArrivo`.

extension StatoShell {
    /// Quanti testi inquadrati restano in arrivo (i più vecchi se ne vanno).
    static let massimoInquadrature = 5
    /// Quanti pezzi di trascrizione tiene una sessione (oltre, i più vecchi lasciano solo le loro schede).
    static let massimoPezziCopilota = 3_000

    // MARK: - Consenso

    /// Registra il consenso del cliente all'ascolto (data, modo, nota) nel dossier.
    func registraConsensoCopilota(clienteId: String, modo: ConsensoCopilota.Modo, nota: String = "", data: Date = Date()) {
        guard !solaLettura, var c = cliente(clienteId) else { return }
        c.consensoCopilota = ConsensoCopilota(data: data, modo: modo, nota: nota.trimmingCharacters(in: .whitespacesAndNewlines))
        salvaCliente(c)
    }

    /// Toglie il consenso: le sessioni aperte del cliente si chiudono senza conservare la trascrizione.
    func revocaConsensoCopilota(clienteId: String, oggi: Date = Date()) {
        guard !solaLettura, var c = cliente(clienteId) else { return }
        c.consensoCopilota = nil
        salvaCliente(c)
        for s in dati.sessioniCopilota where s.clienteId == clienteId && s.aperta {
            chiudiSessioneCopilota(s.id, conservaTrascrizione: false, oggi: oggi)
        }
    }

    // MARK: - Sessioni

    func sessioneCopilota(_ id: String) -> SessioneCopilota? {
        dati.sessioniCopilota.first { $0.id == id }
    }

    /// Le sessioni del cliente, dalla più recente.
    func sessioniCopilotaCliente(_ clienteId: String) -> [SessioneCopilota] {
        dati.sessioniCopilota.filter { $0.clienteId == clienteId }.sorted { $0.data > $1.data }
    }

    /// La sessione ancora aperta del cliente (la più recente).
    func sessioneCopilotaAperta(clienteId: String) -> SessioneCopilota? {
        sessioniCopilotaCliente(clienteId).first { $0.aperta }
    }

    /// Avvia l'ascolto per il cliente: l'id della sessione (quella aperta dello stesso incontro, se c'è già), oppure
    /// nil con l'avviso del motivo (senza consenso il copilota non parte).
    @discardableResult
    func avviaSessioneCopilota(clienteId: String, incontroId: String? = nil, data: Date = Date()) -> String? {
        guard !solaLettura else {
            mostraAvviso("Archivio in sola lettura: aggiorna Prisma per usare il copilota.")
            return nil
        }
        let c = cliente(clienteId)
        if let motivo = GuardiaCopilota.motivoBlocco(c, adesso: data) {
            mostraAvviso(motivo)
            return nil
        }
        if let aperta = dati.sessioniCopilota.first(where: { $0.clienteId == clienteId && $0.aperta && $0.incontroId == incontroId }) {
            return aperta.id
        }
        guard let nuova = SessioneCopilota.nuova(cliente: c, incontroId: incontroId, data: data) else { return nil }
        dati.sessioniCopilota.append(nuova)
        return nuova.id
    }

    /// Il contesto del riconoscitore per la sessione: gli obiettivi del cliente e l'ultimo obiettivo citato.
    func contestoCopilota(_ s: SessioneCopilota, oggi: Date) -> ContestoCopilota {
        let ultima = s.schede.last { $0.tipo == .obiettivo && $0.stato != .scartata }?.cifre.area
        return ContestoCopilota(obiettivi: dati.obiettivi.filter { $0.clienteId == s.clienteId }, ultimaArea: ultima, oggi: oggi)
    }

    /// Un pezzo di trascrizione (solo testo) nella sessione aperta: le regole di Prisma lo leggono subito e le schede
    /// nuove o aggiornate tornano indietro. Niente entra nel dossier. Senza consenso (tolto nel frattempo) niente.
    @discardableResult
    func ascoltaPezzoCopilota(_ testo: String, sessione id: String, chi: PezzoTrascrizione.Chi = .sconosciuto,
                              dispositivo: String? = nil, quando: Date = Date()) -> [SchedaCopilota] {
        guard let i = dati.sessioniCopilota.firstIndex(where: { $0.id == id }), dati.sessioniCopilota[i].aperta,
              GuardiaCopilota.puoPartire(cliente(dati.sessioniCopilota[i].clienteId), adesso: quando) else { return [] }
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pulito.isEmpty else { return [] }
        var s = dati.sessioniCopilota[i]
        var contesto = contestoCopilota(s, oggi: quando)
        var pezzo = PezzoTrascrizione(testo: String(pulito.prefix(PonteVera.massimoTestoPezzo)), quando: quando, chi: chi, dispositivo: dispositivo)
        let esito = RiconoscitoreCopilota.leggi(pezzo.testo, pezzoId: pezzo.id, contesto: &contesto)
        pezzo.evidenze = esito.evidenze
        s.trascrizione.append(pezzo)
        if s.trascrizione.count > Self.massimoPezziCopilota { s.trascrizione.removeFirst(s.trascrizione.count - Self.massimoPezziCopilota) }
        s.schede = RiconoscitoreCopilota.unisci(s.schede, esito.schede)
        dati.sessioniCopilota[i] = s
        let ids = Set(esito.schede.map(\.id))
        return s.schede.filter { ids.contains($0.id) }
    }

    /// Schede arrivate da fuori (Qwen, l'iPad): entrano solo come proposte, con l'azione rifatta sul dossier del Mac.
    func aggiungiSchedeCopilota(_ schede: [SchedaCopilota], sessione id: String, dispositivo: String? = nil, oggi: Date = Date()) {
        guard let i = dati.sessioniCopilota.firstIndex(where: { $0.id == id }), dati.sessioniCopilota[i].aperta else { return }
        var s = dati.sessioniCopilota[i]
        let contesto = contestoCopilota(s, oggi: oggi)
        let pulite = schede.prefix(PonteVera.massimoSchede).map { x -> SchedaCopilota in
            var y = RiconoscitoreCopilota.adatta(x, contesto: contesto)
            // Mai confermate da fuori: la conferma la dà il consulente sul Mac
            y.stato = .proposta
            y.applicataIl = nil
            y.elementoId = nil
            if let d = dispositivo { y.dispositivo = d }
            if y.tipo != .attivita { y.titolo = RiconoscitoreCopilota.titolo(y) }
            return y
        }
        s.schede = RiconoscitoreCopilota.unisci(s.schede, Array(pulite))
        dati.sessioniCopilota[i] = s
    }

    /// Conferma le schede (nil = tutte le proposte) e le porta nel dossier. Restituisce quante modifiche e attività.
    @discardableResult
    func confermaSchedeCopilota(_ ids: Set<String>?, sessione id: String, oggi: Date = Date()) -> EsitoCopilota {
        guard !solaLettura, let i = dati.sessioniCopilota.firstIndex(where: { $0.id == id }) else { return EsitoCopilota() }
        var s = dati.sessioniCopilota[i]
        var d = dati
        let esito = ApplicaCopilota.applica(ids, sessione: &s, a: &d, oggi: oggi)
        guard !esito.vuoto else { return esito }
        if let k = d.sessioniCopilota.firstIndex(where: { $0.id == id }) { d.sessioniCopilota[k] = s }
        // Un solo cambio di `dati`: un solo salvataggio
        dati = d
        mostraAvviso("Nel dossier: " + ApplicaCopilota.avviso(esito))
        return esito
    }

    func scartaSchedaCopilota(_ schedaId: String, sessione id: String) {
        guard let i = dati.sessioniCopilota.firstIndex(where: { $0.id == id }) else { return }
        ApplicaCopilota.scarta(schedaId, sessione: &dati.sessioniCopilota[i])
    }

    /// Chiude l'ascolto: il verbale con frasi fisse; senza «Conserva la trascrizione» il testo del cliente si dimentica
    /// (resta il verbale, con le schede senza frasi).
    func chiudiSessioneCopilota(_ id: String, conservaTrascrizione: Bool, oggi: Date = Date()) {
        guard let i = dati.sessioniCopilota.firstIndex(where: { $0.id == id }) else { return }
        var s = dati.sessioniCopilota[i]
        s.conservaTrascrizione = conservaTrascrizione
        s.verbale = ApplicaCopilota.verbale(s)
        if s.conclusaIl == nil { s.conclusaIl = oggi }
        if !conservaTrascrizione { s.dimenticaTrascrizione() }
        dati.sessioniCopilota[i] = s
    }

    /// Il verbale confermato dal consulente (le schede si confermano a parte).
    func confermaVerbaleCopilota(_ id: String, oggi: Date = Date()) {
        guard let i = dati.sessioniCopilota.firstIndex(where: { $0.id == id }) else { return }
        var v = dati.sessioniCopilota[i].verbale ?? ApplicaCopilota.verbale(dati.sessioniCopilota[i])
        v.confermatoIl = oggi
        dati.sessioniCopilota[i].verbale = v
    }

    /// Qwen legge il pezzo in background (se è pronto): le sue schede, controllate sulle cifre della frase, si
    /// uniscono a quelle delle regole, che vincono sulle stesse cose. Se Qwen non è pronto restano le regole.
    func riconosciConQwenCopilota(pezzo pezzoId: String, sessione id: String) {
        guard disponibilitaLocale.pronto, let s = sessioneCopilota(id), s.aperta,
              let pezzo = s.trascrizione.first(where: { $0.id == pezzoId }) else { return }
        let contesto = contestoCopilota(s, oggi: pezzo.quando)
        let messaggi = RiconoscitoreCopilota.messaggi(pezzo: pezzo.testo, contesto: contesto, cliente: cliente(s.clienteId)?.nome)
        let opzioni = RiconoscitoreCopilota.opzioni(dati.impostazioni.vera)
        let motore = qwen
        Task { @MainActor in
            guard let r = try? await motore.scrivi(messaggi, opzioni: opzioni),
                  let schede = RiconoscitoreCopilota.leggiJSON(r.testo, pezzo: pezzo.testo, pezzoId: pezzo.id, contesto: contesto),
                  let attuale = self.sessioneCopilota(id), attuale.aperta else { return }
            let regole = attuale.schede.filter { $0.pezzoId == pezzo.id }
            let unite = RiconoscitoreCopilota.conQwen(regole: regole, modello: schede)
            self.aggiungiSchedeCopilota(unite.filter { u in !regole.contains { $0 == u } }, sessione: id)
        }
    }

    // MARK: - Il ponte: messaggi da iPad e iPhone

    /// Un messaggio nuovo del ponte (dal server del Mac, sul thread principale): le schede dell'iPad entrano nella
    /// sessione del cliente come proposte (solo con il consenso), i testi inquadrati aspettano in arrivo.
    func riceviDalPonte(_ arrivo: ArrivoPonte) -> RicevutaPonte {
        guard !solaLettura else { return .rifiutata("L’archivio del Mac è in sola lettura: aggiorna Prisma sul Mac.") }
        switch arrivo {
        case .schedeCopilota(let p):
            guard let c = cliente(p.clienteId) else { return .rifiutata("Il cliente non è nell’archivio del Mac.") }
            if let motivo = GuardiaCopilota.motivoBlocco(c) { return .rifiutata(motivo) }
            let sid: String
            if let id = p.sessioneId, let s = sessioneCopilota(id), s.aperta, s.clienteId == p.clienteId {
                sid = id
            } else if let s = sessioneCopilotaAperta(clienteId: p.clienteId) {
                sid = s.id
            } else if let nuova = avviaSessioneCopilota(clienteId: p.clienteId) {
                sid = nuova
            } else {
                return .rifiutata(GuardiaCopilota.senzaConsenso(c.nome))
            }
            if let i = dati.sessioniCopilota.firstIndex(where: { $0.id == sid }) {
                var s = dati.sessioniCopilota[i]
                for var x in p.pezzi.prefix(PonteVera.massimoPezzi) where !s.trascrizione.contains(where: { $0.id == x.id }) {
                    x.dispositivo = p.dispositivo
                    x.testo = String(x.testo.prefix(PonteVera.massimoTestoPezzo))
                    s.trascrizione.append(x)
                }
                dati.sessioniCopilota[i] = s
            }
            aggiungiSchedeCopilota(p.schede, sessione: sid, dispositivo: p.dispositivo)
            return .accettata()
        case .inquadratura(let x):
            inquadratureInArrivo.removeAll { $0.id == x.id }
            inquadratureInArrivo.append(x)
            if inquadratureInArrivo.count > Self.massimoInquadrature {
                inquadratureInArrivo.removeFirst(inquadratureInArrivo.count - Self.massimoInquadrature)
            }
            mostraAvviso("È arrivato il testo inquadrato con \(x.dispositivo): controllalo prima di aggiungerlo a Posizioni.")
            return .accettata()
        }
    }

    /// Il documento del cliente con i dati di un testo inquadrato, da confermare in Documenti (niente entra nel
    /// dossier senza conferma). L'inquadratura esce da quelle in arrivo.
    @discardableResult
    func documentoDaInquadratura(_ id: String, clienteId: String, titolo: String = "Polizza inquadrata") -> Documento? {
        guard !solaLettura, cliente(clienteId) != nil, let x = inquadratureInArrivo.first(where: { $0.id == id }) else { return nil }
        let d = MotoreInquadra.documento(x.dati, clienteId: clienteId, titolo: titolo, quando: x.quando)
        dati.documenti.append(d)
        inquadratureInArrivo.removeAll { $0.id == id }
        return d
    }
}
