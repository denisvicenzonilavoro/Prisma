import Foundation

// Il portafoglio di Posizioni del tema Apple nello stato (Design/template-apple-specifica.md §4.1): l'andamento
// della card, il nastro «Da fare» e le sue azioni. Le cifre vengono dai motori (MotoreAndamentoPortafoglio,
// MotoreDaFare, che incrocia seguito delle proposte, riesami, conformità, occasioni, attività e attenzioni) e si
// tengono da parte in DerivatiDati per un'ora, come la mossa del giorno. Le viste stanno in PortafoglioApple.swift.

extension StatoShell {
    // MARK: - Le cifre

    /// L'andamento di tutte le posizioni visibili (in modalità cliente solo le sue): totale, delta da gennaio,
    /// storia mese per mese, stima con le proposte e fascia d'incertezza.
    func andamentoPortafoglio() -> AndamentoPortafoglio {
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.andamentoPortafoglio, c.ora == ora { return c.valore }
        let v = MotoreAndamentoPortafoglio.calcola(posizioni, oggi: Date())
        d.andamentoPortafoglio = (ora, v)
        return v
    }

    /// L'andamento delle posizioni di un cliente (il grafico del dettaglio di una scheda «Da fare»).
    func andamentoCliente(_ id: String) -> AndamentoPortafoglio {
        let voce = voceCliente(id)
        if let v = voce.andamento { return v }
        let v = MotoreAndamentoPortafoglio.calcola(posizioniCliente(id), oggi: Date())
        voce.andamento = v
        return v
    }

    /// Il nastro «Da fare, in ordine di tempo» dei clienti visibili, dalle cache che usano già scrivania,
    /// notifiche e Portafoglio (proposte ferme, riesami, attenzioni, conformità, occasioni).
    func nastroDaFare() -> NastroDaFare {
        let d = derivatiValidi()
        let ora = DerivatiDati.ora()
        if let c = d.nastroDaFare, c.ora == ora { return c.valore }
        let v = MotoreDaFare.calcola(ingressiDaFare(adesso: Date()))
        d.nastroDaFare = (ora, v)
        return v
    }

    /// Ciò che MotoreDaFare incrocia, dalle cache di sempre: per il nastro e per tutte le voci del Territorio
    /// (`vociDaFareTutte`, «Luce» giro 11).
    func ingressiDaFare(adesso: Date) -> MotoreDaFare.Ingressi {
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: adesso)
        let fine = cal.date(byAdding: .day, value: MotoreDaFare.giorniOccasioni + 1, to: inizio) ?? inizio
        let comune = portafoglioComune()
        return MotoreDaFare.Ingressi(clienti: clienti, posizioni: posizioni, attivita: attivita,
                                     proposte: proposteInSospeso, riesami: comune.dovuti,
                                     conformita: conformitaClienti(oggi: adesso),
                                     occasioni: occasioni(da: inizio, a: fine), attenzioni: comune.attenzioni,
                                     oggi: adesso)
    }

    // MARK: - Le azioni delle schede

    /// «Segna come fatto»: registra la cosa fatta con i meccanismi di sempre, così resta nell'archivio.
    /// - attività: completata;
    /// - riesame: un incontro «Riesame annuale» concluso adesso e la fotografia della memoria del riesame;
    /// - conformità: la voce rinnovata oggi (come «Rinnova oggi» di «In regola»);
    /// - occasioni e attenzioni: un'attività completata con l'id `VoceDaFare.idSegno` (resta nell'Agenda).
    /// L'esito delle proposte e il documento d'identità chiedono un modulo: li apre la vista, non questa funzione.
    func segnaFatto(_ v: VoceDaFare) {
        guard !solaLettura else {
            mostraAvviso(TestiPortafoglioApple.solaLettura)
            return
        }
        switch v.fatto {
        case .attivita(let id):
            guard let i = dati.attivita.firstIndex(where: { $0.id == id }), !dati.attivita[i].completata else { return }
            dati.attivita[i].completata = true
        case .riesame:
            // Un minuto fa: per i riesami e per lo stato del lavoro conta un incontro già avvenuto
            var incontro = Incontro(clienteId: v.cliente.id, titolo: TestiPortafoglioApple.titoloRiesame,
                                    data: Appuntamento.alMinuto(Date().addingTimeInterval(-60)))
            incontro.stato = .concluso
            salvaIncontro(incontro)
            fotografaRiesame(v.cliente.id, origine: .incontro, avviso: false)
        case .rinnova(let tipo):
            rinnovaOggi(v.cliente.id, tipo)
        case .segna:
            guard !dati.attivita.contains(where: { $0.id == v.idSegno }) else { return }
            dati.attivita.append(Attivita(id: v.idSegno, clienteId: v.cliente.id, titolo: TestiPortafoglioApple.titoloSegno(v),
                                          scadenza: Calendar.current.startOfDay(for: Date()), priorita: .normale,
                                          completata: true, note: v.spiegazione))
        case .esitoProposta, .apriInRegola:
            break
        }
    }

    /// Il prossimo appuntamento in agenda del cliente della scheda, se c'è.
    func appuntamentoDaFare(_ v: VoceDaFare) -> Appuntamento? {
        prossimiAppuntamenti.first { $0.clienteId == v.cliente.id }
    }

    /// I report del fascicolo per l'incontro della scheda, nell'ordine del fascicolo: dall'appuntamento in agenda o,
    /// senza, da una bozza con il tipo d'incontro adatto alla scheda (come la mossa del giorno).
    func reportDaFare(_ v: VoceDaFare) -> [TipoProspetto] {
        let a = appuntamentoDaFare(v) ?? bozzaIncontroDaFare(v)
        let pid = a.posizioneId ?? v.posizioneId
        let posizione = pid.flatMap { id in posizioni.first { $0.id == id } }
        let scelti = TipoProspetto.perIncontro(a, posizione: posizione, oggi: Date())
        return TipoProspetto.inFascicolo.filter { scelti.contains($0) }
    }

    /// «Preparami l'incontro»: il fascicolo con i report adatti, in Prospetti (come la mossa del giorno).
    func preparaIncontroDaFare(_ v: VoceDaFare) {
        if let a = appuntamentoDaFare(v) {
            preparaFascicolo(per: a)
            return
        }
        clienteAttivoId = v.cliente.id
        sceltaFascicolo = Set(reportDaFare(v))
        fascicoloAppuntamento = nil
        apriProspetto(.fascicolo)
    }

    /// «Apri il dossier»: Clienti › Panoramica sul cliente della scheda.
    func apriDossierDaFare(_ v: VoceDaFare) {
        clienteAttivoId = v.cliente.id
        schedaCliente = .panoramica
        apri(.clienti)
    }

    /// La bozza (non salvata) dell'incontro di una scheda senza appuntamento in agenda.
    private func bozzaIncontroDaFare(_ v: VoceDaFare) -> Appuntamento {
        let cal = Calendar.current
        let inizio = cal.date(bySettingHour: 9, minute: 30, second: 0, of: Date()) ?? Date()
        return Appuntamento(id: "dafare-\(v.id)", clienteId: v.cliente.id, titolo: v.perche, inizio: inizio, durataMinuti: 45,
                            luogo: "", note: "", stato: .pianificato, tipo: v.tipoIncontro,
                            canale: v.canali.count == 1 ? v.canali.first : nil, posizioneId: v.posizioneId)
    }
}

/// I testi del portafoglio di Posizioni del tema Apple.
enum TestiPortafoglioApple {
    static let solaLettura = "Archivio in sola lettura: aggiorna Prisma per segnare le cose fatte."
    static let titoloRiesame = "Riesame annuale"
    static let titoloCard = "Portafoglio clienti"
    static let titoloLavoro = "Lo stato del tuo lavoro"
    static let titoloNastro = "Da fare, in ordine di tempo"
    static let invitoAnelli = "Chiudi le cose da fare qui sotto: gli anelli si riempiono."
    static let nastroVuoto = "Niente da fare con i clienti per ora: proposte, riesami, conformità e scadenze sono in ordine."
    static let cifreDaiMotori = "Le cifre vengono dai motori di Prisma"

    /// Il titolo dell'attività che tiene il segno di una scheda fatta.
    static func titoloSegno(_ v: VoceDaFare) -> String { "Fatto: " + v.perche }

    /// «12 cose · 3 oggi».
    static func conteggio(_ n: NastroDaFare) -> String {
        let cose = n.totale == 1 ? "1 cosa" : "\(n.totale) cose"
        return n.diOggi > 0 ? "\(cose) · \(n.diOggi) oggi" : cose
    }

    /// «+38.200 € da gennaio» (o «da ottobre 2025» se la storia parte dall'anno prima).
    static func delta(_ a: AndamentoPortafoglio, oggi: Date = Date()) -> String {
        let segno = a.delta >= 0 ? "+" : Formati.meno
        let cal = Calendar.current
        var da = ""
        if let inizio = a.inizio {
            let stessoAnno = cal.component(.year, from: inizio) == cal.component(.year, from: oggi)
            da = " da " + (stessoAnno ? meseNome.string(from: inizio) : Formati.meseAnno.string(from: inizio))
        }
        return segno + Formati.euro(abs(a.delta)) + da
    }

    /// «+46.564 € con le 6 proposte aperte».
    static func deltaProposte(_ a: AndamentoPortafoglio) -> String {
        let proposte = a.proposteAperte == 1 ? "con la proposta aperta" : "con le \(a.proposteAperte) proposte aperte"
        return "+" + Formati.euro(a.valoreProposte) + " " + proposte
    }

    /// «35 clienti · 6 proposte aperte».
    static func sottoDelta(clienti: Int, proposte: Int) -> String {
        let c = clienti == 1 ? "1 cliente" : "\(clienti) clienti"
        let p = proposte == 1 ? "1 proposta aperta" : "\(proposte) proposte aperte"
        return "\(c) · \(p)"
    }

    /// «se le proposte vanno in porto · stima a maggio 2027».
    static func sottoProposte(_ a: AndamentoPortafoglio) -> String {
        guard let fine = a.fineStima else { return "se le proposte vanno in porto" }
        return "se le proposte vanno in porto · stima a \(Formati.meseAnno.string(from: fine))"
    }

    /// «stima maggio 2027» (sul grafico).
    static func etichettaStima(_ a: AndamentoPortafoglio) -> String {
        guard let fine = a.fineStima else { return "stima" }
        return "stima \(Formati.meseAnno.string(from: fine))"
    }

    /// «Riesami dell'anno: 27 su 35.»
    static func esitoAnello(_ nome: String, _ c: StatoDelLavoro.Conteggio) -> String {
        "\(nome): \(c.fatti) su \(c.totale)."
    }

    /// Il nome del mese («gennaio»).
    static let meseNome = Formati.formato("MMMM")
    /// Il mese breve dell'asse del grafico («gen»).
    static let meseAsse = Formati.formato("MMM")
    /// Il primo mese sotto il grafico del dettaglio («gen 2026»).
    static let meseAnnoAsse = Formati.formato("MMM yyyy")
}
