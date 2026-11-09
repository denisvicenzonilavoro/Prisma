import Foundation

// Ciò che Clienti › Potenziali e Passaparola chiedono allo stato («Luce» giro 12, §9.2.4): aggiungere, modificare,
// spostare ed eliminare un potenziale; l'arrivo in «Cliente» passa dalla scena del nuovo cliente (mai da solo); il primo
// incontro sul primo spazio libero vero dell'Agenda; «Scrivigli» solo con informativa e consenso (decisione 39); la
// richiesta di presentazione preparata in Messaggi (decisione 17). Ogni scrittura è vietata in sola lettura (iPad, copia
// di «Prisma ovunque» di sola lettura, archivio più recente).

extension StatoShell {
    /// Potenziali e Passaparola si guardano soltanto (§9.2.4): sull'iPad e sull'iPhone, che sono una copia (i passaggi di
    /// fase si fanno sul Mac), e con l'archivio in sola lettura.
    var potenzialiInSolaLettura: Bool {
        #if os(iOS)
        return true
        #else
        return solaLettura
        #endif
    }

    /// Le tinte degli avatar dei clienti nuovi, a giro.
    private static let tinteNuovi: [TintaAvatar] = [.blu, .rosa, .verde, .viola, .oro]

    /// Un potenziale nuovo (con la storia che comincia da «Da contattare»).
    func aggiungiPotenziale(_ p: PotenzialeCliente) {
        guard !solaLettura, !p.nome.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var q = p
        q.nome = q.nome.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.storia.isEmpty { q.storia = [CambioFase(fase: q.fase, il: MessaggioCliente.adesso)] }
        dati.potenziali.append(q)
        mostraAvviso("\(TestiTraguardi.primoNome(q.nome)) è fra i potenziali clienti")
    }

    /// Salva le modifiche di un potenziale (dal modulo o dal dettaglio).
    func salvaPotenziale(_ p: PotenzialeCliente) {
        guard !solaLettura else { return }
        if let i = dati.potenziali.firstIndex(where: { $0.id == p.id }) {
            guard dati.potenziali[i] != p else { return }
            dati.potenziali[i] = p
        } else {
            aggiungiPotenziale(p)
        }
    }

    /// Sposta un potenziale in una fase. In «Cliente» non va da solo: si apre il modulo del nuovo cliente.
    func spostaPotenziale(_ id: String, a fase: FasePotenziale) {
        guard !solaLettura, let i = dati.potenziali.firstIndex(where: { $0.id == id }) else { return }
        if fase == .cliente {
            proponiCliente(id)
            return
        }
        let nuovo = MotorePassaparola.sposta(dati.potenziali[i], a: fase, il: MessaggioCliente.adesso)
        guard nuovo != dati.potenziali[i] else { return }
        dati.potenziali[i] = nuovo
    }

    /// Un passo avanti (il clic sulla scheda).
    func avanzaPotenziale(_ id: String) {
        guard let p = dati.potenziali.first(where: { $0.id == id }), let s = p.fase.successiva else { return }
        spostaPotenziale(id, a: s)
    }

    /// Un passo indietro.
    func arretraPotenziale(_ id: String) {
        guard let p = dati.potenziali.first(where: { $0.id == id }), p.fase != .cliente, let s = p.fase.precedente else { return }
        spostaPotenziale(id, a: s)
    }

    /// L'arrivo in «Cliente» (§9.2.4): apre la scena del nuovo cliente con il nome già scritto e «presentato da …»;
    /// da lì la carta letta o «Scrivi a mano» creano il dossier, e solo allora la scheda resta in «Cliente». Se la scena
    /// non si apre (presentazione in corso), il modulo del nuovo cliente già compilato (AppClienti lo legge da
    /// `richiestaClienteDaPotenziale`). Già cliente: apre il suo dossier.
    func proponiCliente(_ id: String) {
        guard !potenzialiInSolaLettura, let p = dati.potenziali.first(where: { $0.id == id }) else { return }
        if let cid = p.clienteId, dati.clienti.contains(where: { $0.id == cid }) {
            clienteAttivoId = cid
            schedaCliente = .panoramica
            vistaClienti = .rubrica
            return
        }
        apriNuovoCliente(potenziale: id)
        guard !nuovoClienteAperto, !inModoCliente else { return }
        richiestaClienteDaPotenziale = id
    }

    /// Il cliente nuovo dal potenziale, da precompilare nel modulo.
    func clienteDaPotenziale(_ id: String) -> Cliente? {
        guard let p = dati.potenziali.first(where: { $0.id == id }) else { return nil }
        let tinta = Self.tinteNuovi[dati.clienti.count % Self.tinteNuovi.count]
        return MotorePassaparola.clienteDa(p, tinta: tinta, oggi: Date())
    }

    /// Il dossier è stato creato: il cliente si salva e la scheda resta in «Cliente», collegata, e compare nell'albero.
    func confermaClienteDaPotenziale(potenziale id: String, cliente: Cliente) {
        guard !solaLettura else { return }
        salvaCliente(cliente)
        if let i = dati.potenziali.firstIndex(where: { $0.id == id }) {
            dati.potenziali[i] = MotorePassaparola.diventato(dati.potenziali[i], cliente: cliente.id, il: MessaggioCliente.adesso)
        }
        richiestaClienteDaPotenziale = nil
        mostraAvviso(TestiPassaparola.benvenuto(cliente.nome))
    }

    /// Il modulo annullato: il potenziale resta (o torna) in «Proposta».
    func annullaClienteDaPotenziale(_ id: String) {
        richiestaClienteDaPotenziale = nil
        guard !solaLettura, let i = dati.potenziali.firstIndex(where: { $0.id == id }),
              dati.potenziali[i].fase != .cliente, dati.potenziali[i].fase != .proposta else { return }
        dati.potenziali[i] = MotorePassaparola.sposta(dati.potenziali[i], a: .proposta, il: MessaggioCliente.adesso)
    }

    /// Elimina un potenziale (dopo la conferma). I clienti e le campagne non cambiano.
    func eliminaPotenziale(_ id: String) {
        guard !solaLettura, dati.potenziali.contains(where: { $0.id == id }) else { return }
        dati.potenziali.removeAll { $0.id == id }
    }

    /// «Fissa il primo incontro»: un appuntamento «Primo incontro» di mezz'ora sul primo spazio libero vero dell'Agenda.
    /// Tocca solo l'agenda.
    @discardableResult
    func fissaPrimoIncontro(_ id: String) -> Appuntamento? {
        guard !solaLettura, let p = dati.potenziali.first(where: { $0.id == id }) else { return nil }
        let domani = Calendar.current.date(byAdding: .day, value: MotorePianificazione.preavvisoGiorni,
                                           to: Calendar.current.startOfDay(for: Date())) ?? Date()
        guard let s = MotorePianificazione.primoSpazio(durata: 30, da: domani, appuntamenti: dati.appuntamenti,
                                                        orari: dati.impostazioni.orari) else {
            mostraAvviso(TestiPassaparola.agendaPiena)
            return nil
        }
        let a = Appuntamento(id: "event-\(UUID().uuidString.prefix(8).lowercased())", clienteId: "",
                             titolo: "Primo incontro · \(p.nome)", inizio: s.inizio, durataMinuti: 30, luogo: "", note: "",
                             stato: .pianificato, tipo: .primoIncontro)
        dati.appuntamenti.append(a)
        mostraAvviso(TestiPassaparola.primoIncontroFissato + " · " + Formati.giornoBreve.string(from: a.inizio)
                     + " alle " + Formati.ora.string(from: a.inizio))
        return a
    }

    /// «Scrivigli»: solo con l'informativa data e il consenso al contatto. Apre Mail o Messaggi con il solo saluto
    /// (un cliente temporaneo, mai salvato): Prisma non spedisce.
    @MainActor
    func scriviAPotenziale(_ id: String, canale: CanaleMessaggio) {
        guard let p = dati.potenziali.first(where: { $0.id == id }) else { return }
        guard p.contattabile else {
            mostraAvviso(TestiPassaparola.scrivigliNonPronto)
            return
        }
        let temporaneo = Cliente(id: "potenziale-\(p.id)", nome: p.nome, iniziali: Cliente.iniziali(di: p.nome), tinta: .blu,
                                 tema: "", email: p.email, telefono: p.telefono, preferito: false, nota: "", creatoIl: Date())
        let firma = firmaMessaggio(nil, tono: .cordiale)
        let testo = ModelliMessaggi.saluto(temporaneo, tono: .cordiale) + "\n\n" + ModelliMessaggi.chiusura(tono: .cordiale, firma: firma)
            .trimmingCharacters(in: .newlines)
        let esito = AperturaMessaggi.apri(testo: testo, oggetto: canale == .mail ? "Piacere di conoscerti" : nil, canale: canale,
                                          cliente: temporaneo)
        mostraAvviso(esito.messaggio)
    }

    /// «Prepara la richiesta»: apre Messaggi sull'occasione della richiesta di presentazione (commerciale). La spunta
    /// «✓ Messaggio pronto» compare solo quando il messaggio esiste (`richiestaPreparata`).
    func preparaRichiestaPresentazione(_ m: MomentoPerChiedere) {
        guard let c = dati.clienti.first(where: { $0.id == m.clienteId }) else { return }
        let o = MotorePassaparola.occasioneRichiesta(m, cliente: c, posizioni: dati.posizioni)
        potenziali.occasioniRichieste[m.id] = o.id
        vistaMessaggi = .messaggi
        preparaMessaggio(occasione: o)
    }

    /// Il messaggio della richiesta esiste (preparato, aperto o salvato) da quando il momento è nato.
    func richiestaPreparata(_ m: MomentoPerChiedere) -> Bool {
        let id = potenziali.occasioniRichieste[m.id]
            ?? OccasioneMessaggio.id(tipo: .richiestaPresentazione, clienteId: m.clienteId, riferimento: m.riferimento)
        return dati.messaggi.contains { $0.occasioneId == id && $0.creatoIl >= Calendar.current.startOfDay(for: m.data) }
    }
}
