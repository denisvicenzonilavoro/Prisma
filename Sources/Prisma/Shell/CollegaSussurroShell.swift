import CryptoKit
import Foundation

// «Il sussurro» nell'app (Vera/BRIEF.md, funzione 7; motore in Vera/SussurroVera.swift): aprendo la Panoramica del
// dossier, Vera mostra al massimo tre cose da sapere adesso, ognuna con un'azione. Solo codice, niente Qwen: le voci e
// le cifre le calcola il motore sui dati di Prisma.
// - Le azioni che cambiano qualcosa (un'attività da segnare, il riesame da fissare) passano sempre da una scheda
//   «Conferma» (origine `.sussurro`): il messaggio di Vera che la contiene va nella conversazione del cliente e la
//   scheda si mostra anche sotto la voce, nel dossier. Le altre portano nell'app giusta e non cambiano niente.
// - «Non ora» chiude la voce per `RegoleSussurro.giorniChiusura` giorni (`DatiPrisma.sussurriChiusi`, nel backup).
// - In modalità cliente il sussurro non c'è (sono appunti del consulente: consensi, preferenze, ritardi), né nel
//   dossier né in chat; si spegne anche in Impostazioni › Vera (`ImpostazioniVera.sussurroNelDossier`).
// - In chat: «cosa devo sapere su Marco?» risponde con le stesse voci (`chiediSussurro`). Le domande generiche («cosa
//   devo sapere sulla successione?») non sono del sussurro e passano agli altri motori.
// - Ogni azione porta negli argomenti la voce da cui nasce («sussurro», con il cliente): confermata ed eseguita, la voce
//   si chiude da sola (`chiudiSussurriConfermati`), da qualunque parte sia nata la scheda (dossier o chat).
// - Schede e risposte del sussurro, e la domanda che le chiede, hanno il titolo `titoloSussurro`: in modalità cliente
//   `messaggiPerLoSchermo` le toglie dalla conversazione mostrata (sono appunti del consulente).
extension StatoShell {
    /// Il titolo dei messaggi del sussurro (domanda, risposta e scheda): li riconosce `riservatoAlConsulente`.
    static let titoloSussurro = "Il sussurro"

    // MARK: - Le voci

    /// Il sussurro si mostra: non in modalità cliente e non se è spento in Impostazioni › Vera.
    var sussurroSiVede: Bool {
        !inModoCliente && dati.impostazioni.vera.sussurroNelDossier
    }

    /// I ricordi di Vera sul cliente (solo con la memoria accesa), dal più recente.
    func ricordiSussurro(_ clienteId: String) -> [String] {
        guard dati.impostazioni.vera.memoriaAttiva else { return [] }
        return SussurroVera.ricordi(memoriaVera.ricordi, clienteId: clienteId)
    }

    /// Le voci per la vista del dossier (si chiama nel body): i dati dei calcoli senza iscrivere la vista all'archivio
    /// intero, più le voci chiuse lette dai dati vivi (così la vista si aggiorna appena se ne chiude una).
    func vociSussurro(clienteId: String, oggi: Date = Date()) -> [VoceSussurro] {
        guard sussurroSiVede else { return [] }
        var d = datiDeiCalcoli()
        d.sussurriChiusi = dati.sussurriChiusi
        return vociSussurro(dati: d, clienteId: clienteId, oggi: oggi)
    }

    /// Le voci da un archivio dato (fuori dai body: la chat, le prove, le istantanee). Le voci chiuse nell'archivio hanno la
    /// chiave «da archivio» (`chiaveSussurroArchivio`): si ritrovano tra le candidate e si passano al motore con la loro
    /// chiave vera. Se la prima di una categoria è chiusa può comparire la seconda, quindi si ripete finché non ne
    /// spuntano altre chiuse (di solito un giro solo; nessuno senza voci chiuse).
    func vociSussurro(dati d: DatiPrisma, clienteId: String, oggi: Date = Date()) -> [VoceSussurro] {
        let ricordi = ricordiSussurro(clienteId)
        let chiuse = SussurroVera.chiuse(d.sussurriChiusi, clienteId: clienteId, oggi: oggi)
        guard var f = SussurroVera.fonte(dati: d, clienteId: clienteId, ricordi: ricordi, oggi: oggi) else { return [] }
        guard !chiuse.isEmpty else { return SussurroVera.voci(f) }
        var vere = Set<String>()
        for _ in 0..<CategoriaSussurro.allCases.count {
            f.chiuse = vere
            let nuove = SussurroVera.candidate(f).map(\.chiave).filter { chiuse.contains(Self.chiaveSussurroArchivio($0)) }
            if nuove.isEmpty { break }
            vere.formUnion(nuove)
        }
        f.chiuse = vere
        return SussurroVera.voci(f)
    }

    /// La chiave di una voce chiusa come va nell'archivio: quelle delle preferenze contengono l'inizio di un ricordo di
    /// Vera (che sta solo nella memoria cifrata), quindi nell'archivio e nei backup ne va solo l'impronta.
    static func chiaveSussurroArchivio(_ chiave: String) -> String {
        guard chiave.hasPrefix("preferenza-") else { return chiave }
        let impronta = SHA256.hash(data: Data(chiave.utf8)).prefix(6).map { String(format: "%02x", $0) }.joined()
        return "preferenza-#" + impronta
    }

    // MARK: - Chiudere una voce

    /// «Non ora» (o azione fatta): la voce non torna per una settimana. Le righe più vecchie della settimana si tolgono:
    /// non servono più e l'elenco resta corto.
    func chiudiSussurro(_ v: VoceSussurro, oggi: Date = Date()) {
        chiudiSussurro(clienteId: v.clienteId, chiave: Self.chiaveSussurroArchivio(v.chiave), oggi: oggi)
    }

    /// La stessa chiusura con la chiave già pronta per l'archivio (passata da `chiaveSussurroArchivio`).
    func chiudiSussurro(clienteId: String, chiave: String, oggi: Date = Date()) {
        guard !solaLettura else { return }
        let cal = Calendar.current
        var elenco = dati.sussurriChiusi.filter { s in
            !(s.clienteId == clienteId && s.chiave == chiave)
                && MotoreOccasioniMessaggi.giorni(da: s.chiusoIl, a: oggi, cal: cal) < RegoleSussurro.giorniChiusura
        }
        elenco.append(SussurroChiuso(clienteId: clienteId, chiave: chiave, chiusoIl: oggi))
        dati.sussurriChiusi = elenco
    }

    /// Dopo «Conferma» di una scheda del sussurro (da chiamare in `confermaSchedaVera` quando `origine == .sussurro`):
    /// ogni azione attiva eseguita davvero chiude la sua voce, così il dossier non la ripropone e l'attività non si
    /// segna due volte. Le azioni senza la voce negli argomenti (schede salvate prima) restano come sono.
    func chiudiSussurriConfermati(_ s: SchedaConfermaVera, oggi: Date = Date()) {
        guard s.origine == .sussurro else { return }
        for a in s.attive where a.esito?.fatta == true {
            guard let chiave = a.argomenti[Self.argomentoSussurro], let id = a.argomenti["cliente"] else { continue }
            chiudiSussurro(clienteId: id, chiave: Self.chiaveSussurroArchivio(chiave), oggi: oggi)
        }
        ritiraDoppioniSussurro(s)
    }

    /// Dopo «Conferma», le altre schede del sussurro ancora in attesa per le stesse voci (nate in un'altra conversazione:
    /// dal portafoglio, dal dossier di un altro cliente o dal pulsante del dossier) perdono quelle azioni: confermarle
    /// segnerebbe la stessa attività una seconda volta. Rimaste senza azioni, sono lasciate stare.
    func ritiraDoppioniSussurro(_ s: SchedaConfermaVera) {
        guard s.origine == .sussurro, !solaLettura else { return }
        let fatte = Set(s.attive.filter { $0.esito?.fatta == true }.compactMap { a -> String? in
            guard let chiave = a.argomenti[Self.argomentoSussurro], let id = a.argomenti["cliente"] else { return nil }
            return id + "\u{1F}" + chiave
        })
        guard !fatte.isEmpty else { return }
        for id in messaggiSussurroInAttesa() {
            aggiornaSchedaVera(messaggio: id) { x in
                guard x.id != s.id, x.origine == .sussurro, x.stato == .daConfermare else { return }
                for i in x.azioni.indices where !x.azioni[i].tolta {
                    guard let chiave = x.azioni[i].argomenti[Self.argomentoSussurro],
                          let cliente = x.azioni[i].argomenti["cliente"],
                          fatte.contains(cliente + "\u{1F}" + chiave) else { continue }
                    x.azioni[i].tolta = true
                }
                if x.attive.isEmpty { x.stato = .rinunciata }
            }
        }
    }

    /// Dopo «Annulla» di una scheda del sussurro (da chiamare in `annullaSchedaVera` quando `origine == .sussurro`, con la
    /// scheda già aggiornata): le voci delle azioni annullate davvero (`esito.annullata`) si riaprono e il pulsante torna
    /// nel dossier. Quelle delle azioni rimaste fatte restano chiuse.
    func riapriSussurriAnnullati(_ s: SchedaConfermaVera) {
        guard s.origine == .sussurro, !solaLettura else { return }
        for a in s.attive where a.esito?.annullata == true {
            guard let chiave = a.argomenti[Self.argomentoSussurro], let id = a.argomenti["cliente"] else { continue }
            let k = Self.chiaveSussurroArchivio(chiave)
            dati.sussurriChiusi.removeAll { $0.clienteId == id && $0.chiave == k }
        }
    }

    /// Riapre una voce chiusa (la riporta tra le voci del cliente).
    func riapriSussurro(_ v: VoceSussurro) {
        guard !solaLettura else { return }
        let chiave = Self.chiaveSussurroArchivio(v.chiave)
        dati.sussurriChiusi.removeAll { $0.clienteId == v.clienteId && $0.chiave == chiave }
    }

    // MARK: - Le azioni

    /// L'argomento dell'azione con la chiave della voce da cui nasce (la usano la chiusura dopo «Conferma» e la vista
    /// del dossier per ritrovare la scheda). È la chiave della voce com'è: la conversazione resta sul Mac e fuori
    /// dall'istantanea di «Prisma ovunque»; nell'archivio delle voci chiuse va solo `chiaveSussurroArchivio`.
    static let argomentoSussurro = "sussurro"

    /// L'azione da confermare per una voce: l'attività del motore (rinnovo, scaletta, invito, copia del documento) o il
    /// riesame nel primo spazio libero dell'agenda, con la voce e il cliente negli argomenti. nil = la voce porta solo
    /// in un'app.
    func azioneSussurro(_ v: VoceSussurro, cliente c: Cliente, oggi: Date = Date()) -> AzioneConferma? {
        var a: AzioneConferma
        if let x = SussurroVera.conferma(v, cliente: c, oggi: oggi) {
            a = x
        } else if v.azione.tipo == .fissaRiesame, let x = azioneRiesameSussurro(c, oggi: oggi) {
            a = x
        } else {
            return nil
        }
        a.argomenti[Self.argomentoSussurro] = v.chiave
        a.argomenti["cliente"] = c.id
        return a
    }

    /// Gli id dei messaggi di Vera con una scheda del sussurro ancora da confermare, in tutte le conversazioni (salvate e
    /// temporanee): una scheda chiesta in chat dal portafoglio o dal dossier di un altro cliente non sta nella
    /// conversazione del cliente della voce.
    func messaggiSussurroInAttesa() -> [String] {
        let tutte = (dati.impostazioni.vera.conservaConversazioni ? Array(dati.conversazioni.values) : []) + Array(conversazioniTemporanee.values)
        return tutte.flatMap { elenco in
            elenco.filter { m in m.conferma.map { $0.origine == .sussurro && $0.stato == .daConfermare } ?? false }.map(\.id)
        }
    }

    /// L'id del messaggio con una scheda del sussurro in attesa che ha ancora (attiva) l'azione della voce, cercato in
    /// tutte le conversazioni. nil se non ce n'è.
    func schedaSussurroInAttesaOvunque(_ v: VoceSussurro) -> String? {
        messaggiSussurroInAttesa().last { id in
            messaggioVera(id)?.conferma?.attive.contains {
                $0.argomenti[Self.argomentoSussurro] == v.chiave && $0.argomenti["cliente"] == v.clienteId
            } ?? false
        }
    }

    /// Il riesame nel primo spazio libero degli orari di lavoro (come «Fissa» della striscia dei riesami in Agenda).
    /// nil se non c'è uno spazio libero: allora la voce apre l'Agenda e l'orario lo sceglie il consulente.
    func azioneRiesameSussurro(_ c: Cliente, oggi: Date = Date()) -> AzioneConferma? {
        guard let p = pianificaRiesame(c.id, oggi: oggi), p.spazio != nil else { return nil }
        let a = p.appuntamento
        let luogo = a.luogo.isEmpty ? "" : " · \(a.luogo)"
        return AzioneConferma(strumento: RegistroStrumenti.agendaNuovo, app: .agenda, titolo: "Fisso «\(a.titolo)» con \(c.nome)",
                              dettaglio: "\(RegistroStrumenti.quando(a.inizio))\(luogo) · \(a.durataMinuti) minuti",
                              argomenti: ["cliente": c.id, "inizio": RegistroStrumenti.isoData(a.inizio), "tipo": a.tipo.rawValue,
                                          "durata": String(a.durataMinuti), "luogo": a.luogo, "titolo": a.titolo])
    }

    /// Il pulsante della voce. Se l'azione cambia qualcosa prepara la scheda «Conferma» e restituisce l'id del messaggio
    /// di Vera che la contiene (la vista la mostra sotto la voce); altrimenti porta nell'app giusta e restituisce nil.
    /// «Tienilo a mente» chiude la voce.
    @discardableResult
    func eseguiSussurro(_ v: VoceSussurro, oggi: Date = Date()) -> String? {
        guard let c = cliente(v.clienteId) else { return nil }
        if v.azione.tipo == .tieniAMente {
            chiudiSussurro(v, oggi: oggi)
            return nil
        }
        if let a = azioneSussurro(v, cliente: c, oggi: oggi) {
            // Una scheda della stessa voce ancora da confermare: si riusa, niente doppioni
            if let id = schedaSussurroAperta(v) ?? schedaSussurroInAttesaOvunque(v) { return id }
            guard !solaLettura else {
                mostraAvviso("Prisma è in sola lettura: non posso segnare niente.")
                return nil
            }
            return schedaSussurro([a], voce: v, cliente: c)
        }
        apriFonteSussurro(v)
        return nil
    }

    /// Mette la scheda «Conferma» nella conversazione del cliente (senza parlare: nasce dal dossier) e dà l'id del
    /// messaggio. Niente si esegue prima di «Conferma».
    func schedaSussurro(_ azioni: [AzioneConferma], voce v: VoceSussurro, cliente c: Cliente) -> String {
        var m = MessaggioVera(autore: .vera, testo: "Dal sussurro su \(c.nome): \(v.testo) Lo segno solo con «Conferma».",
                              titolo: Self.titoloSussurro, motore: Self.motoreAzioni)
        m.conferma = SchedaConfermaVera(richiesta: "\(v.azione.titolo): \(v.testo)", azioni: azioni, origine: .sussurro)
        aggiungiMessaggio(m, cliente: c.id, parla: false)
        return m.id
    }

    /// true per i messaggi del sussurro (la domanda, la risposta, la scheda): appunti del consulente.
    static func riservatoAlConsulente(_ m: MessaggioVera) -> Bool {
        m.titolo == titoloSussurro || m.conferma?.origine == .sussurro
    }

    /// La conversazione come si mostra sullo schermo: in modalità cliente senza i messaggi del sussurro (da usare in
    /// VeraScrivania, MiniVera e ogni vista che mostra la conversazione di un cliente).
    /// Anche i messaggi salvati prima delle correzioni che in modalità cliente direbbero di altri clienti: l'esito di una
    /// routine di portafoglio o di un altro cliente, uno spostamento in blocco (porta gli impegni di tutti), un piano a
    /// passi su un altro cliente.
    func messaggiPerLoSchermo(_ elenco: [MessaggioVera]) -> [MessaggioVera] {
        inModoCliente ? elenco.filter { !Self.riservatoAlConsulente($0) && !nascostoInModoCliente($0) } : elenco
    }

    private func nascostoInModoCliente(_ m: MessaggioVera) -> Bool {
        if let e = m.esitoRoutine, !routineVisibile(e) { return true }
        if m.agendaSpostamento != nil { return true }
        if let p = m.pianoPassi, !visibileAlCliente(p.richiesta.clienteId) { return true }
        return false
    }

    /// Lo stato della scheda «Conferma» di una voce (nil se il messaggio non c'è più).
    func statoSchedaSussurro(_ messaggio: String) -> SchedaConfermaVera.Stato? {
        messaggioVera(messaggio)?.conferma?.stato
    }

    // MARK: - Dove porta

    /// Il nome del posto dove porta la voce, per il menu «…» (nil quando ci porta già il pulsante o non porta da nessuna parte).
    func doveSussurro(_ v: VoceSussurro) -> String? {
        let pulsanteNaviga = !v.azione.cambia && v.azione.tipo != .fissaRiesame
        if pulsanteNaviga { return nil }
        switch v.azione.tipo {
        case .rinnovaConsenso, .chiediCopia: return "Apri «In regola»"
        case .preparaRinnovo: return "Apri la posizione"
        case .mettiInScaletta: return v.azione.riferimento == nil ? "Apri l'Agenda" : "Apri l'incontro in Agenda"
        case .fissaRiesame: return "Apri l'Agenda"
        case .invita: return "Apri la famiglia"
        case .apriPromessa, .preparaIpotesi, .proponiOrario, .faiAuguri, .tieniAMente: return nil
        }
    }

    /// Porta nell'app giusta per la voce, sul cliente della voce (usa `riferimento`). Non cambia niente.
    func apriFonteSussurro(_ v: VoceSussurro) {
        let id = v.clienteId
        guard let c = cliente(id) else { return }
        let rif = v.azione.riferimento
        switch v.azione.tipo {
        case .rinnovaConsenso, .chiediCopia:
            clienteAttivoId = id
            schedaCliente = .inRegola
            apri(.clienti)
        case .invita:
            clienteAttivoId = id
            schedaCliente = .famiglia
            apri(.clienti)
        case .apriPromessa:
            clienteAttivoId = id
            veraPortafoglio = false
            rispondiPromesse(cliente: id, nuove: 0, chiave: id, motore: MotoriVera.sintesi.nome)
            apri(.vera)
        case .preparaRinnovo:
            if let p = rif.flatMap({ r in dati.posizioni.first { $0.id == r } }) { apriPosizione(p) } else { apriAgendaSussurro(id) }
        case .preparaIpotesi:
            if rif == "liquidita" {
                clienteAttivoId = id
                areaAnalisi = .risparmio
                apri(.analisi360)
            } else if let p = rif.flatMap({ r in dati.posizioni.first { $0.id == r } }) {
                simula(p)
            } else {
                clienteAttivoId = id
                apri(.analisi360)
            }
        case .mettiInScaletta:
            if let a = rif.flatMap({ r in dati.appuntamenti.first { $0.id == r } }) { mostraInAgenda(a) } else { apriAgendaSussurro(id) }
        case .fissaRiesame:
            apriAgendaSussurro(id)
        case .proponiOrario:
            // Gli orari liberi li cerca «L'agenda che si organizza» in chat, con la preferenza del cliente sotto gli occhi
            clienteAttivoId = id
            veraPortafoglio = false
            apri(.vera)
            chiediVera("Trova due orari per un incontro con \(c.nome)")
        case .faiAuguri:
            preparaMessaggio(clienteId: id, occasioneId: rif)
        case .tieniAMente:
            chiudiSussurro(v)
        }
    }

    /// L'Agenda sul cliente (come «Fissa un incontro in Agenda ›» del prossimo incontro).
    private func apriAgendaSussurro(_ id: String) {
        clienteAttivoId = id
        if !inModoCliente { filtroClienteAgenda = id }
        apri(.agenda)
    }

    // MARK: - In chat

    /// «Cosa devo sapere su Marco?», «che cosa c'è da sapere su Laura», «sussurrami Sofia»: le stesse voci del dossier.
    /// L'inizio della frase; il resto (gruppo 1) lo controlla `fraseSussurro`.
    static let richiestaSussurro = #"^(?:(?:e )?(?:che )?(?:cosa|cos'è che) (?:devo|dovrei|mi serve|c'è da|ce da|è bene) sapere|(?:dimmi )?(?:le )?(?:tre )?cose da sapere|sussurrami)\b(.*)$"#
    /// Dopo «sapere»: su, di, riguardo a, a proposito di (con un «adesso» o «oggi» davanti, se c'è) e poi la persona.
    static let introSussurro = #"^(?:(?:adesso|ora|oggi) )?(?:(?:a proposito di|riguardo a|riguardo|sulla|sul|su|della|del|di|per) )?(.*)$"#
    /// Il cliente detto con un pronome («su di lui», «di lei», «su questo cliente»).
    static let pronomeSussurro = #"^(?:di )?(?:lui|lei|loro|questo cliente|questa cliente|il cliente|la cliente|(?:il |la )?mi[oa] cliente)$"#

    /// true se la frase pulita è del sussurro: «cosa devo sapere» da sola, oppure seguita da un pronome o da un cliente
    /// nominato. «Cosa devo sapere sulla successione?» o «come spengo il sussurro?» non lo sono.
    func fraseSussurro(_ t: String) -> Bool {
        guard let gruppi = DateItaliane.cerca(Self.richiestaSussurro, t)?.1 else { return false }
        // gruppi[0] è la frase intera, gruppi[1] quello che viene dopo «sapere»
        let coda = (gruppi.count > 1 ? gruppi[1] : "").trimmingCharacters(in: CharacterSet(charactersIn: " ,:?!."))
        if coda.isEmpty { return true }
        let intro = DateItaliane.cerca(Self.introSussurro, coda)?.1
        let persona = (intro.map { $0.count > 1 ? $0[1] : coda } ?? coda).trimmingCharacters(in: .whitespaces)
        if persona.isEmpty { return true }
        if DateItaliane.cerca(Self.pronomeSussurro, persona) != nil { return true }
        let noti = clientiAttivi.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        return !InterpreteComandi.clientiNominati(persona, noti).isEmpty
    }

    /// true se la frase era per il sussurro (e Vera ha risposto). Senza un cliente (nel portafoglio, nessun nome) la frase
    /// torna alla chat. In modalità cliente il sussurro non c'è: la frase passa ai motori successivi.
    func chiediSussurro(_ testo: String, chiave: String, oggi: Date = Date()) -> Bool {
        guard !inModoCliente else { return false }
        let t = InterpreteComandi.pulisci(testo)
        guard fraseSussurro(t),
              // «Scrivi a Marco cosa deve sapere» è per «Fallo tu»
              DateItaliane.cerca(Self.verboAzione, t) == nil else { return false }
        guard let id = clienteDellaRichiesta(testo, chiave: chiave) else { return false }
        // La domanda porta il titolo del sussurro: in modalità cliente non si mostra, come la risposta
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo, titolo: Self.titoloSussurro), cliente: chiave)
        domandaVera = ""
        rispondiSussurro(cliente: id, chiave: chiave, oggi: oggi)
        return true
    }

    /// La risposta in chat: le voci con la loro fonte e, se qualcuna cambia qualcosa, una sola scheda «Conferma».
    @discardableResult
    func rispondiSussurro(cliente id: String, chiave: String, oggi: Date = Date()) -> MessaggioVera? {
        guard let c = cliente(id) else { return nil }
        let voci = vociSussurro(dati: dati.istantanea, clienteId: id, oggi: oggi)
        let nome = Self.primoNome(c.nome)
        guard !voci.isEmpty else {
            let m = MessaggioVera(autore: .vera, testo: "Su \(nome), adesso, non c'è niente di urgente da sapere.",
                                  titolo: Self.titoloSussurro, motore: MotoriVera.sintesi.nome)
            aggiungiMessaggio(m, cliente: chiave)
            return m
        }
        let quante = voci.count == 1 ? "Una cosa da sapere" : "\(SchedaConfermaVera.numero(voci.count).prefix(1).uppercased() + SchedaConfermaVera.numero(voci.count).dropFirst()) cose da sapere"
        var righe = ["\(quante) su \(nome), adesso:"]
        righe += voci.map { "• \($0.testo) (\($0.fonte))" }
        // Le voci che hanno già una scheda in attesa (nata dal dossier o da un'altra domanda) non ne hanno una seconda
        let inAttesa = voci.filter { schedaSussurroInAttesaOvunque($0) != nil }.map(\.chiave)
        let azioni = voci.filter { !inAttesa.contains($0.chiave) }.compactMap { azioneSussurro($0, cliente: c, oggi: oggi) }
        if !inAttesa.isEmpty {
            righe.append(inAttesa.count == voci.count
                         ? "Per queste voci c'è già una scheda «Conferma» che aspetta: non ne preparo una seconda."
                         : "Per alcune voci c'è già una scheda «Conferma» che aspetta: non ne preparo una seconda.")
        }
        if !azioni.isEmpty, !solaLettura {
            righe.append(azioni.count == 1 ? "L'attività la segno solo con «Conferma»." : "Le segno solo con «Conferma»: togli quelle che non ti servono.")
        }
        var m = MessaggioVera(autore: .vera, testo: righe.joined(separator: "\n"), titolo: Self.titoloSussurro,
                              motore: azioni.isEmpty ? MotoriVera.sintesi.nome : Self.motoreAzioni)
        if !azioni.isEmpty, !solaLettura {
            m.conferma = SchedaConfermaVera(richiesta: "Cosa devo sapere su \(nome)?", azioni: azioni, origine: .sussurro)
        }
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }
}

// MARK: - Prova

extension StatoShell {
    /// Il sussurro in chat e dopo «Conferma» (da chiamare in `Prisma --prova-vera`, accanto a `ProvaCollegaSussurroVera`):
    /// le domande generiche non sono del sussurro, le azioni portano la voce negli argomenti e confermate la chiudono,
    /// in modalità cliente la frase passa oltre e i messaggi del sussurro non si mostrano.
    static func provaSussurroChatEChiusura(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        let oggi = Date()
        guard let i = s.dati.clienti.firstIndex(where: { $0.id == "sofia" }) else {
            return controlla(false, "Sussurro in chat: manca Sofia tra i dati di prova")
        }
        s.dati.clienti[i].consensi = Consensi()
        s.veraPortafoglio = false
        s.clienteAttivoId = "sofia"
        // Le frasi: del sussurro solo con la persona (nominata o con un pronome) o da sole
        for f in ["Cosa devo sapere?", "Cosa devo sapere su Sofia?", "che cosa c'è da sapere su di lei", "sussurrami Sofia", "Cosa dovrei sapere adesso su Sofia?"] {
            controlla(s.fraseSussurro(InterpreteComandi.pulisci(f)), "Sussurro in chat: «\(f)» è del sussurro")
        }
        let prima = s.conversazione("sofia").count
        for f in ["Cosa devo sapere sulla successione?", "Come spengo il sussurro?", "Cosa dovrei sapere sul PIP prima di proporlo?"] {
            controlla(!s.chiediSussurro(f, chiave: "sofia") && s.conversazione("sofia").count == prima,
                      "Sussurro in chat: «\(f)» nel dossier di Sofia non è del sussurro e passa agli altri motori")
        }
        // Le azioni portano la voce e il cliente
        guard let v = s.vociSussurro(dati: s.dati.istantanea, clienteId: "sofia", oggi: oggi).first(where: { $0.azione.cambia }),
              let c = s.cliente("sofia"), let a = s.azioneSussurro(v, cliente: c, oggi: oggi) else {
            return controlla(false, "Sussurro in chat: per Sofia senza consenso manca una voce con un'attività")
        }
        controlla(a.argomenti[argomentoSussurro] == v.chiave && a.argomenti["cliente"] == "sofia",
                  "Sussurro in chat: l'azione porta la voce e il cliente negli argomenti")
        // Dalla chat: confermata, la voce si chiude e non torna (né nel dossier né in chat)
        controlla(s.chiediSussurro("Cosa devo sapere su Sofia?", chiave: "sofia"), "Sussurro in chat: la domanda su Sofia ha risposta")
        guard let m = s.conversazione("sofia").last, m.conferma?.origine == .sussurro else {
            return controlla(false, "Sussurro in chat: la risposta non ha la scheda «Conferma»")
        }
        controlla(s.conversazione("sofia").suffix(2).allSatisfy(riservatoAlConsulente),
                  "Sussurro in chat: domanda e risposta sono segnate come appunti del consulente")
        let attivita = s.dati.attivita.count
        _ = s.confermaSchedaVera(messaggio: m.id)
        if let eseguita = s.messaggioVera(m.id)?.conferma { s.chiudiSussurriConfermati(eseguita, oggi: oggi) }
        controlla(s.dati.attivita.count > attivita && !s.vociSussurro(dati: s.dati.istantanea, clienteId: "sofia", oggi: oggi).contains { $0.chiave == v.chiave },
                  "Sussurro in chat: dopo «Conferma» la voce è chiusa e il dossier non ripropone la stessa attività")
        // Modalità cliente: la frase passa oltre, niente messaggi; quelli del sussurro non si mostrano
        s.modoCliente = "sofia"
        let n = s.conversazione("sofia").count
        controlla(!s.chiediSussurro("Cosa devo sapere su Sofia?", chiave: "sofia") && s.conversazione("sofia").count == n,
                  "Sussurro in chat: in modalità cliente la frase passa ai motori successivi, senza messaggi")
        controlla(!s.messaggiPerLoSchermo(s.conversazione("sofia")).contains(where: riservatoAlConsulente),
                  "Sussurro in chat: in modalità cliente i messaggi del sussurro non si mostrano")
        s.modoCliente = nil
        controlla(s.messaggiPerLoSchermo(s.conversazione("sofia")).count == s.conversazione("sofia").count,
                  "Sussurro in chat: fuori dalla modalità cliente la conversazione è intera")
        provaSussurroSchedeAltrove(oggi: oggi, controlla)
    }

    /// Le schede nate fuori dalla conversazione del cliente (dal portafoglio): il pulsante del dossier e una nuova domanda
    /// le riusano, dopo «Conferma» un doppione in attesa perde l'azione (l'attività non si segna due volte), «Annulla»
    /// riapre la voce.
    private static func provaSussurroSchedeAltrove(oggi: Date, _ controlla: (Bool, String) -> Void) {
        let t = StatoShell(persistente: false)
        t.rispostePreparate = true
        guard let j = t.dati.clienti.firstIndex(where: { $0.id == "sofia" }) else { return }
        t.dati.clienti[j].consensi = Consensi()
        t.veraPortafoglio = true
        guard let w = t.vociSussurro(dati: t.dati.istantanea, clienteId: "sofia", oggi: oggi).first(where: { $0.azione.cambia }),
              let c = t.cliente("sofia"), let a = t.azioneSussurro(w, cliente: c, oggi: oggi) else {
            return controlla(false, "Sussurro altrove: per Sofia senza consenso manca una voce con un'attività")
        }
        controlla(t.chiediSussurro("Cosa devo sapere su Sofia?", chiave: VeraPortafoglio.chiave),
                  "Sussurro altrove: la domanda su Sofia nel portafoglio ha risposta")
        guard let mp = t.conversazione(VeraPortafoglio.chiave).last, mp.conferma?.stato == .daConfermare else {
            return controlla(false, "Sussurro altrove: la risposta nel portafoglio non ha la scheda «Conferma»")
        }
        controlla(t.eseguiSussurro(w, oggi: oggi) == mp.id,
                  "Sussurro altrove: il pulsante del dossier riusa la scheda nata nel portafoglio, niente seconda scheda")
        _ = t.chiediSussurro("Cosa devo sapere su Sofia?", chiave: "sofia")
        let seconda = t.conversazione("sofia").last?.conferma?.attive.contains { $0.argomenti[argomentoSussurro] == w.chiave } ?? false
        controlla(!seconda, "Sussurro altrove: la domanda nel dossier non prepara una seconda scheda per la stessa voce")
        // Un doppione già in attesa (schede salvate prima): dopo «Conferma» della prima perde l'azione
        let doppione = t.schedaSussurro([a], voce: w, cliente: c)
        let attivita = t.dati.attivita.count
        _ = t.confermaSchedaVera(messaggio: mp.id)
        controlla(t.messaggioVera(doppione)?.conferma?.stato == .rinunciata && t.confermaSchedaVera(messaggio: doppione) == nil
                  && t.dati.attivita.count > attivita,
                  "Sussurro altrove: confermata una scheda, il doppione in attesa è lasciato stare e l'attività non si segna due volte")
        controlla(!t.vociSussurro(dati: t.dati.istantanea, clienteId: "sofia", oggi: oggi).contains { $0.chiave == w.chiave },
                  "Sussurro altrove: dopo «Conferma» la voce è chiusa")
        // «Annulla»: la voce torna (la chiamata a riapriSussurriAnnullati va in annullaSchedaVera; qui si ripete, è idempotente)
        t.annullaSchedaVera(messaggio: mp.id)
        if let annullata = t.messaggioVera(mp.id)?.conferma, annullata.attive.contains(where: { $0.esito?.annullata == true }) {
            t.riapriSussurriAnnullati(annullata)
            controlla(t.vociSussurro(dati: t.dati.istantanea, clienteId: "sofia", oggi: oggi).contains { $0.chiave == w.chiave },
                      "Sussurro altrove: dopo «Annulla» la voce torna tra quelle di Sofia")
        }
    }
}
