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
// - In chat: «cosa devo sapere su Marco?» risponde con le stesse voci (`chiediSussurro`).
extension StatoShell {
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
        guard !solaLettura else { return }
        let cal = Calendar.current
        let chiave = Self.chiaveSussurroArchivio(v.chiave)
        var elenco = dati.sussurriChiusi.filter { s in
            !(s.clienteId == v.clienteId && s.chiave == chiave)
                && MotoreOccasioniMessaggi.giorni(da: s.chiusoIl, a: oggi, cal: cal) < RegoleSussurro.giorniChiusura
        }
        elenco.append(SussurroChiuso(clienteId: v.clienteId, chiave: chiave, chiusoIl: oggi))
        dati.sussurriChiusi = elenco
    }

    /// Riapre una voce chiusa (la riporta tra le voci del cliente).
    func riapriSussurro(_ v: VoceSussurro) {
        guard !solaLettura else { return }
        let chiave = Self.chiaveSussurroArchivio(v.chiave)
        dati.sussurriChiusi.removeAll { $0.clienteId == v.clienteId && $0.chiave == chiave }
    }

    // MARK: - Le azioni

    /// L'azione da confermare per una voce: l'attività del motore (rinnovo, scaletta, invito, copia del documento) o il
    /// riesame nel primo spazio libero dell'agenda. nil = la voce porta solo in un'app.
    func azioneSussurro(_ v: VoceSussurro, cliente c: Cliente, oggi: Date = Date()) -> AzioneConferma? {
        if let a = SussurroVera.conferma(v, cliente: c, oggi: oggi) { return a }
        guard v.azione.tipo == .fissaRiesame else { return nil }
        return azioneRiesameSussurro(c, oggi: oggi)
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
                              motore: Self.motoreAzioni)
        m.conferma = SchedaConfermaVera(richiesta: "\(v.azione.titolo): \(v.testo)", azioni: azioni, origine: .sussurro)
        aggiungiMessaggio(m, cliente: c.id, parla: false)
        return m.id
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
    static let richiestaSussurro = #"(?:^(?:e )?(?:che )?(?:cosa|cos'è che) (?:devo|dovrei|mi serve|c'è da|ce da|è bene) sapere\b|^(?:dimmi )?(?:le )?(?:tre )?cose da sapere\b|\bsussurr)"#

    /// true se la frase era per il sussurro (e Vera ha risposto). Senza un cliente (nel portafoglio, nessun nome) la frase
    /// torna alla chat.
    func chiediSussurro(_ testo: String, chiave: String, oggi: Date = Date()) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        guard DateItaliane.cerca(Self.richiestaSussurro, t) != nil,
              // «Scrivi a Marco cosa deve sapere» è per «Fallo tu»
              DateItaliane.cerca(Self.verboAzione, t) == nil else { return false }
        if inModoCliente {
            aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
            domandaVera = ""
            aggiungiMessaggio(MessaggioVera(autore: .vera, testo: "In modalità cliente il sussurro resta nascosto: lo ritrovi quando giri lo schermo verso di te.",
                                            motore: Self.motoreAzioni), cliente: chiave)
            return true
        }
        guard let id = clienteDellaRichiesta(testo, chiave: chiave) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
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
                                  titolo: "Il sussurro", motore: MotoriVera.sintesi.nome)
            aggiungiMessaggio(m, cliente: chiave)
            return m
        }
        let quante = voci.count == 1 ? "Una cosa da sapere" : "\(SchedaConfermaVera.numero(voci.count).prefix(1).uppercased() + SchedaConfermaVera.numero(voci.count).dropFirst()) cose da sapere"
        var righe = ["\(quante) su \(nome), adesso:"]
        righe += voci.map { "• \($0.testo) (\($0.fonte))" }
        let azioni = voci.compactMap { azioneSussurro($0, cliente: c, oggi: oggi) }
        if !azioni.isEmpty, !solaLettura {
            righe.append(azioni.count == 1 ? "L'attività la segno solo con «Conferma»." : "Le segno solo con «Conferma»: togli quelle che non ti servono.")
        }
        var m = MessaggioVera(autore: .vera, testo: righe.joined(separator: "\n"), titolo: "Il sussurro",
                              motore: azioni.isEmpty ? MotoriVera.sintesi.nome : Self.motoreAzioni)
        if !azioni.isEmpty, !solaLettura {
            m.conferma = SchedaConfermaVera(richiesta: "Cosa devo sapere su \(nome)?", azioni: azioni, origine: .sussurro)
        }
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }
}
