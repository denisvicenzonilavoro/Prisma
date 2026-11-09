import Foundation
import Observation

// Pratiche › Sinistri («Luce» giro 15, §7.4): lo stato della scheda e le azioni sui sinistri. Ogni fase, data e importo
// li segna il consulente (Prisma non è collegato alla compagnia). «Aggiorna …» prepara un messaggio in Messaggi (lo
// apre e lo spedisce il consulente: il segno dell'aggiornamento e la traccia nel dossier si scrivono solo quando il
// messaggio si apre davvero, `segnaAggiornamentoSinistro` da `apriMessaggio`); «Sollecita la compagnia» apre una bozza
// in Mail all'indirizzo scritto dall'utente o, per una compagnia «solo dal portale», lascia un promemoria fra le
// attività. I conti stanno in MotoreSinistri, i testi in TestiSinistri.

@Observable final class StatoSinistri {
    /// Il sinistro scelto nella barra laterale.
    var scelto: String?
    /// Il modulo «Nuovo sinistro» è aperto.
    var moduloAperto = false
    /// Solo istantanee: il sinistro da mostrare. Non pubblicato.
    @ObservationIgnored var istantanea: String?
    /// Il sinistro in modifica nel modulo (nil = nuovo).
    var inModifica: String?
    /// Il cliente e la polizza con cui si apre il modulo (dal dossier o dalla posizione).
    var clienteModulo: String?
    var polizzaModulo: String?
    /// Un file trascinato sopra la card dei documenti.
    var rilascioAttivo = false
}

extension StatoShell {
    // MARK: - Leggere

    /// I sinistri dei clienti visibili (in modalità cliente solo i suoi: ma Pratiche lì non si apre).
    var sinistriVisibili: [Sinistro] {
        let visibili = Set(clienti.map(\.id))
        return dati.sinistri.filter { visibili.contains($0.clienteId) }
    }

    func sinistro(_ id: String) -> Sinistro? { dati.sinistri.first { $0.id == id } }

    /// La polizza collegata (nil se manca o non c'è più).
    func polizzaSinistro(_ s: Sinistro) -> Posizione? {
        guard let p = s.posizioneId else { return nil }
        return dati.posizioni.first { $0.id == p }
    }

    /// Il nome del consulente per «Aggiornato da …» (il nome dell'utente di Prisma).
    var nomeConsulenteSinistri: String {
        let n = dati.impostazioni.nomeUtente.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "il tuo consulente" : n
    }

    // MARK: - Aprire

    /// Apre Pratiche › Sinistri sul sinistro dato.
    func mostraSinistro(_ id: String) {
        sinistri.scelto = id
        sinistri.moduloAperto = false
        apriPratiche(.sinistri)
    }

    /// Apre il modulo «Nuovo sinistro», con il cliente e la polizza se si parte dal dossier o dalla posizione.
    func apriNuovoSinistro(cliente: String? = nil, posizione: String? = nil) {
        guard !solaLettura else { return }
        sinistri.inModifica = nil
        sinistri.clienteModulo = cliente
        sinistri.polizzaModulo = posizione
        sinistri.moduloAperto = true
        apriPratiche(.sinistri)
    }

    /// Apre il modulo sul sinistro dato, per cambiarne i dati.
    func modificaSinistro(_ id: String) {
        guard !solaLettura, let s = sinistro(id) else { return }
        sinistri.inModifica = id
        sinistri.clienteModulo = s.clienteId
        sinistri.polizzaModulo = s.posizioneId
        sinistri.moduloAperto = true
    }

    // MARK: - Cambiare

    /// Salva un sinistro (nuovo o cambiato): titolo e testi brevi (decisione 36), una riga sola. Lo sceglie nella barra.
    func salvaSinistro(_ s: Sinistro) {
        guard !solaLettura else { return }
        var x = s
        x.titolo = MotoreSinistri.breve(x.titolo, limite: MotoreSinistri.lunghezzaTitolo)
        x.descrizione = MotoreSinistri.breve(x.descrizione, limite: MotoreSinistri.lunghezzaTesto)
        x.numeroSinistro = x.numeroSinistro.flatMap { n in
            let t = n.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        if let i = dati.sinistri.firstIndex(where: { $0.id == x.id }) {
            dati.sinistri[i] = x
        } else {
            dati.sinistri.append(x)
        }
        sinistri.scelto = x.id
    }

    func eliminaSinistro(_ id: String) {
        guard !solaLettura else { return }
        dati.sinistri.removeAll { $0.id == id }
        if sinistri.scelto == id { sinistri.scelto = nil }
    }

    /// Cambia un sinistro sul posto (nessuna scrittura se non c'è o in sola lettura).
    private func cambiaSinistro(_ id: String, _ cambia: (inout Sinistro) -> Void) {
        guard !solaLettura, let i = dati.sinistri.firstIndex(where: { $0.id == id }) else { return }
        var s = dati.sinistri[i]
        cambia(&s)
        if s != dati.sinistri[i] { dati.sinistri[i] = s }
    }

    /// Porta il sinistro a una fase (clic su un nodo), con il giorno scelto e, per «Pagato», l'importo.
    func avanzaSinistro(_ id: String, a fase: FaseSinistro, il data: Date, pagato: Double?) {
        cambiaSinistro(id) { MotoreSinistri.avanza(&$0, a: fase, il: data, pagato: pagato) }
    }

    /// «+ Aggiungi» in «Cosa è successo»: un fatto breve con la sua data (la fase di adesso).
    func aggiungiFattoSinistro(_ id: String, data: Date, testo: String) {
        let t = MotoreSinistri.breve(testo, limite: MotoreSinistri.lunghezzaTesto)
        guard !t.isEmpty else { return }
        cambiaSinistro(id) { s in
            s.eventi.append(EventoSinistro(id: "evento-\(UUID().uuidString.prefix(8).lowercased())", data: data, testo: t, fase: s.fase))
        }
    }

    func togliFattoSinistro(_ id: String, evento: String) {
        cambiaSinistro(id) { s in s.eventi.removeAll { $0.id == evento } }
    }

    /// Clic sul cerchio di un documento: ricevuto oggi (un secondo clic lo torna mancante).
    func segnaDocumentoRicevuto(_ id: String, documento: String, oggi: Date = Date()) {
        cambiaSinistro(id) { s in
            guard let i = s.documenti.firstIndex(where: { $0.id == documento }) else { return }
            s.documenti[i].ricevutoIl = s.documenti[i].ricevutoIl == nil ? Appuntamento.alMinuto(oggi) : nil
        }
    }

    /// Un documento richiesto in più (titolo breve).
    func aggiungiDocumentoSinistro(_ id: String, titolo: String) {
        let t = MotoreSinistri.breve(titolo, limite: MotoreSinistri.lunghezzaTitolo)
        guard !t.isEmpty else { return }
        cambiaSinistro(id) { s in
            s.documenti.append(DocumentoSinistro(id: "documento-\(UUID().uuidString.prefix(8).lowercased())", titolo: t,
                                                 ricevutoIl: nil, documentoId: nil))
        }
    }

    func togliDocumentoSinistro(_ id: String, documento: String) {
        cambiaSinistro(id) { s in s.documenti.removeAll { $0.id == documento } }
    }

    /// File trascinati su un documento (o sulla card): vanno nei Documenti del cliente (collegati alla polizza del
    /// sinistro) e il documento risulta ricevuto oggi; senza un documento scelto ognuno diventa un documento ricevuto.
    func importaFileSinistro(_ id: String, documento: String?, urls: [URL]) {
        guard persistente else { return }
        guard !solaLettura else {
            mostraAvviso("Archivio in sola lettura: aggiorna Prisma per importare documenti.")
            return
        }
        guard let s = sinistro(id) else { return }
        let fm = FileManager.default
        let cartella = Archivio.cartellaDocumenti.appendingPathComponent(s.clienteId, isDirectory: true)
        try? fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        var nuovi: [(id: String, titolo: String)] = []
        for url in urls where LetturaDocumenti.estensioniAccettate.contains(url.pathExtension.lowercased()) {
            var d = Documento(clienteId: s.clienteId, titolo: url.deletingPathExtension().lastPathComponent, tipo: .altro)
            d.importatoIl = Appuntamento.alMinuto(Date())
            d.posizioneId = s.posizioneId
            let nome = "\(d.id).\(url.pathExtension.lowercased())"
            let destinazione = cartella.appendingPathComponent(nome)
            do {
                try fm.copyItem(at: url, to: destinazione)
            } catch {
                mostraAvviso("Non riesco a copiare \(url.lastPathComponent): \(error.localizedDescription)")
                continue
            }
            d.file = "\(s.clienteId)/\(nome)"
            d.dimensione = (try? fm.attributesOfItem(atPath: destinazione.path)[.size] as? Int64) ?? 0
            dati.documenti.append(d)
            leggiDocumento(d.id)
            nuovi.append((d.id, d.titolo))
        }
        guard !nuovi.isEmpty else { return }
        let oggi = Appuntamento.alMinuto(Date())
        cambiaSinistro(id) { x in
            var resto = nuovi
            if let documento, let i = x.documenti.firstIndex(where: { $0.id == documento }), let primo = resto.first {
                x.documenti[i].ricevutoIl = oggi
                x.documenti[i].documentoId = primo.id
                resto.removeFirst()
            }
            for n in resto {
                x.documenti.append(DocumentoSinistro(id: "documento-\(UUID().uuidString.prefix(8).lowercased())",
                                                     titolo: MotoreSinistri.breve(n.titolo, limite: MotoreSinistri.lunghezzaTitolo),
                                                     ricevutoIl: oggi, documentoId: n.id))
            }
        }
        mostraAvviso(nuovi.count == 1 ? "Il file è nei Documenti del cliente" : "\(nuovi.count) file nei Documenti del cliente")
    }

    /// «Mettilo in Agenda»: un fatto con una data futura diventa un'attività del cliente quel giorno.
    func mettiInAgendaFattoSinistro(_ id: String, evento: String) {
        guard !solaLettura, let s = sinistro(id), let e = s.eventi.first(where: { $0.id == evento }) else { return }
        var a = Attivita.nuova(clienteId: s.clienteId, scadenza: e.data)
        a.titolo = TestiSinistri.titoloAttivita(e.testo, sinistro: s.titolo)
        salvaAttivita(a)
        mostraAvviso(TestiSinistri.attivitaCreata)
    }

    /// Un fatto ha già la sua attività in Agenda (stesso cliente, stesso giorno, stesso titolo).
    func fattoInAgenda(_ s: Sinistro, evento e: EventoSinistro) -> Bool {
        let titolo = TestiSinistri.titoloAttivita(e.testo, sinistro: s.titolo)
        let giorno = Calendar.current.startOfDay(for: e.data)
        return dati.attivita.contains { $0.clienteId == s.clienteId && $0.titolo == titolo && $0.scadenza == giorno }
    }

    // MARK: - Il cliente

    /// «Aggiorna …»: prepara in Messaggi l'aggiornamento per il cliente (bozza; lo apre e lo spedisce il consulente).
    /// Spento se gli aggiornamenti per quel sinistro sono spenti (D4.7).
    func aggiornaClienteSinistro(_ id: String) {
        guard let s = sinistro(id), s.mostraAlCliente == true, let c = cliente(s.clienteId) else { return }
        let o = MotoreSinistri.occasione(s, cliente: c, consulente: nomeConsulenteSinistri, oggi: Date(), polizza: polizzaSinistro(s))
        preparaMessaggio(clienteId: c.id, occasione: o)
        let nelFile = c.prismaCliente?.contenuti.contains("sinistri") == true
        mostraAvviso(TestiSinistri.aggiornamentoPronto(ModelliMessaggi.primoNome(c.nome), nelFile: nelFile))
    }

    /// Dopo l'apertura riuscita del messaggio in Mail o Messaggi (`apriMessaggio`): il giorno dell'ultimo aggiornamento
    /// nel sinistro e la traccia nel dossier (mai il testo).
    func segnaAggiornamentoSinistro(_ o: OccasioneMessaggio, canale: CanaleMessaggio) {
        guard o.tipo == .sinistro, let id = MotoreSinistri.idDaRiferimento(o.origine.riferimento),
              let s = sinistro(id) else { return }
        let adesso = Appuntamento.alMinuto(Date())
        cambiaSinistro(id) { $0.ultimoAggiornamentoCliente = adesso }
        registraUscita(clienteId: s.clienteId, genere: .aggiornamentoSinistro,
                       descrizione: "Aggiornamento del sinistro · fase \(s.fase.nome)", via: canale.nome, documentoId: nil,
                       protetto: false)
    }

    // MARK: - La compagnia

    /// L'indirizzo dei sinistri scritto dall'utente per la compagnia della polizza (nil senza polizza o senza indirizzo).
    func indirizzoSinistri(_ s: Sinistro) -> IndirizzoCompagnia? {
        guard let p = polizzaSinistro(s) else { return nil }
        return MotoreSinistri.indirizzo(compagnia: p.emittente, in: dati.impostazioni.pratiche.indirizziSinistri ?? [])
    }

    /// «Sollecita la compagnia»: bozza in Mail all'indirizzo scritto dall'utente, con solo numero di polizza, numero di
    /// sinistro e assicurato; per una compagnia «solo dal portale» un promemoria fra le attività; senza indirizzo lo dice.
    @MainActor
    func sollecitaCompagnia(_ id: String) -> EsitoApertura {
        guard let s = sinistro(id) else { return .nonRiuscito("Il sinistro non c'è più") }
        guard let indirizzo = indirizzoSinistri(s) else { return .mancaRecapito(TestiSinistri.senzaIndirizzo) }
        if indirizzo.soloPortale {
            guard !solaLettura else { return .nonRiuscito("Archivio in sola lettura") }
            var a = Attivita.nuova(clienteId: s.clienteId, scadenza: Date())
            a.titolo = TestiSinistri.titoloPromemoriaPortale(s)
            salvaAttivita(a)
            return .aperto(TestiSinistri.promemoriaCreato)
        }
        let email = indirizzo.email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return .mancaRecapito(TestiSinistri.senzaIndirizzo) }
        let polizza = polizzaSinistro(s)
        let chi = (polizza?.assicurato ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let assicurato = chi.isEmpty ? (cliente(s.clienteId)?.nome ?? "") : chi
        let testo = MotoreSinistri.sollecito(s, polizza: polizza, assicurato: assicurato,
                                             firma: ModelliMessaggi.firma(polizza?.canale, tono: .formale, impostazioni: dati.impostazioni))
        let esito = AperturaMessaggi.apriMail(a: email, oggetto: testo.oggetto, corpo: testo.corpo)
        return esito.aperto ? .aperto(TestiSinistri.sollecitoPronto) : esito
    }

    /// Il pulsante del sollecito: «Promemoria: sollecita dal portale» per le compagnie «solo dal portale».
    func titoloSollecito(_ s: Sinistro) -> String {
        indirizzoSinistri(s)?.soloPortale == true ? TestiSinistri.promemoriaPortale : TestiSinistri.sollecita
    }
}
