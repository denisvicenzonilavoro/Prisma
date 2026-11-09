import Foundation

/// Prova del tagliando dei dati (Vera/BRIEF.md, funzione 5) dentro `Prisma --prova-vera`: quando è dovuto (di notte,
/// o alla prima apertura dopo una notte saltata), doppioni, campi vuoti, consensi, riesame, questionario prima di un
/// incontro, documento d'identità, posizioni scadute, punteggio di salute, «Va bene così», «Sistema tutto» e la regola
/// «nulla si cancella da solo». Tutto con una data fissa: niente ora del giorno, niente rete, niente Qwen.
enum ProvaTagliandoVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        dovuto(controlla)
        doppioni(controlla)
        campi(controlla)
        consensi(controlla)
        riesame(controlla)
        questionario(controlla)
        documento(controlla)
        salute(controlla)
        correzioni(controlla)
        demo(controlla)
    }

    // MARK: - Dati di prova

    private static let cal = Calendar.current

    private static func data(_ a: Int, _ m: Int, _ g: Int, _ h: Int = 10, _ mi: Int = 0) -> Date {
        cal.date(from: DateComponents(year: a, month: m, day: g, hour: h, minute: mi)) ?? Date(timeIntervalSince1970: 0)
    }

    /// Lunedì 9 novembre 2026, 10:00.
    private static let oggi = data(2026, 11, 9)

    /// Una scheda in ordine: tutti i campi scritti bene, consenso privacy dato, nessun canale né posizione.
    private static func cliente(_ id: String, _ nome: String, cf: String? = nil, email: String? = nil,
                                telefono: String = "333 1234567") -> Cliente {
        var c = Cliente(id: id, nome: nome, iniziali: Cliente.iniziali(di: nome), tinta: .blu, tema: "", email: email ?? "\(id)@esempio.it",
                        telefono: telefono, preferito: false, nota: "", creatoIl: data(2020, 1, 1))
        c.codiceFiscale = cf ?? codiceFiscale(id)
        c.dataNascita = data(1985, 8, 1)
        c.indirizzo = "Via Roma 1, Milano"
        c.consensi.privacy = true
        c.consensi.dataPrivacy = data(2024, 3, 1)
        return c
    }

    /// Un codice fiscale scritto bene e diverso per ogni id (così le schede di prova non sembrano doppioni).
    private static func codiceFiscale(_ id: String) -> String {
        let lettere = String((id.uppercased().filter { $0.isLetter } + "XXXXXX").prefix(6))
        let n = id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 1000
        return lettere + "85M41H" + String(format: "%03d", n) + "Z"
    }

    private static func controllo(_ clienti: [Cliente], posizioni: [Posizione] = [], appuntamenti: [Appuntamento] = [],
                                  documenti: [Documento] = [], ignorate: Set<String> = []) -> EsitoTagliando {
        TagliandoVera.controlla(clienti: clienti, posizioni: posizioni, appuntamenti: appuntamenti, incontri: [], documenti: documenti,
                                regole: RegoleConformita(), oggi: oggi, ignorate: ignorate, calendario: cal)
    }

    private static func appuntamento(_ cliente: String, _ inizio: Date, tipo: TipoAppuntamento, stato: Appuntamento.Stato) -> Appuntamento {
        Appuntamento(id: "app-\(cliente)-\(Int(inizio.timeIntervalSince1970))", clienteId: cliente, titolo: "Incontro", inizio: inizio,
                     durataMinuti: 60, luogo: "In studio", note: "", stato: stato, tipo: tipo)
    }

    private static func posizione(_ cliente: String, scadenza: Date? = nil) -> Posizione {
        var p = Posizione(clienteId: cliente, canale: .alleanza, stato: .inEssere, area: .investimento, nome: "Piano di accumulo")
        p.id = "pos-\(cliente)"
        p.scadenza = scadenza
        return p
    }

    private static func identita(_ cliente: String, scadenza: String, numero: String = "CA99999ZZ", cf: String? = nil) -> Documento {
        var d = Documento(clienteId: cliente, titolo: "Carta d'identità", tipo: .altro)
        d.id = "doc-\(cliente)"
        d.categoria = .identita
        d.campi = [CampoEstratto(chiave: .scadenza, valore: scadenza, pagina: 1, confermato: true),
                   CampoEstratto(chiave: .numeroDocumento, valore: numero, pagina: 1, confermato: true)]
        if let cf { d.campi.append(CampoEstratto(chiave: .codiceFiscale, valore: cf, pagina: 1)) }
        return d
    }

    // MARK: - È dovuto adesso?

    private static func dovuto(_ controlla: (Bool, String) -> Void) {
        let i = ImpostazioniTagliando()
        let stanotte = data(2026, 11, 9, 2, 10)
        let ieriNotte = data(2026, 11, 8, 2, 10)
        controlla(TagliandoVera.dovuto(ultimo: nil, adesso: oggi, impostazioni: i, calendario: cal), "Tagliando: mai fatto, è dovuto subito")
        controlla(!TagliandoVera.dovuto(ultimo: stanotte, adesso: oggi, impostazioni: i, calendario: cal), "Tagliando: fatto stanotte alle 2:10, alle 10 non si rifà")
        controlla(TagliandoVera.dovuto(ultimo: ieriNotte, adesso: oggi, impostazioni: i, calendario: cal), "Tagliando: notte saltata, si fa alla prima apertura del giorno")
        controlla(!TagliandoVera.dovuto(ultimo: ieriNotte, adesso: data(2026, 11, 9, 1, 30), impostazioni: i, calendario: cal),
                  "Tagliando: all'1:30 il turno di stanotte non è ancora arrivato")
        controlla(TagliandoVera.dovuto(ultimo: ieriNotte, adesso: stanotte, impostazioni: i, calendario: cal), "Tagliando: alle 2:10 in punto scatta")
        controlla(TagliandoVera.dovuto(ultimo: data(2026, 11, 10, 2, 10), adesso: oggi, impostazioni: i, calendario: cal),
                  "Tagliando: un ultimo controllo nel futuro (orologio spostato) non lo blocca")
        var spento = i
        spento.attivo = false
        controlla(!TagliandoVera.dovuto(ultimo: nil, adesso: oggi, impostazioni: spento, calendario: cal), "Tagliando: spento non è mai dovuto")
        controlla(TagliandoVera.prossimoTurno(dopo: oggi, impostazioni: i, calendario: cal) == data(2026, 11, 10, 2, 10),
                  "Tagliando: il prossimo turno è domani alle 2:10")
        controlla(TagliandoVera.ultimoTurno(prima: data(2026, 11, 9, 1, 0), impostazioni: i, calendario: cal) == ieriNotte,
                  "Tagliando: prima delle 2:10 l'ultimo turno è quello di ieri")
        let letto = try? JSONDecoder().decode(ImpostazioniTagliando.self, from: Data(#"{"ora":30,"minuto":"x"}"#.utf8))
        controlla(letto?.ora == 23 && letto?.minuto == 10 && letto?.attivo == true, "Tagliando: impostazioni lette con tolleranza")
        let stato = try? JSONDecoder().decode(StatoTagliando.self, from: Data("{}".utf8))
        controlla(stato?.ultimoControllo == nil && stato?.ignorate.isEmpty == true, "Tagliando: stato vuoto letto senza errori")
    }

    // MARK: - Doppioni

    private static func doppioni(_ controlla: (Bool, String) -> Void) {
        var marco = cliente("marco", "Marco Bianchi", cf: "BNCMRC80A01H501U", telefono: "333 1111111")
        marco.professione = "Imprenditore"
        let doppio = cliente("m-bianchi", "M. Bianchi", cf: "bncmrc80a01h501u", email: "", telefono: "333 2222222")
        let elena = cliente("elena", "Elena Bianchi", cf: "", email: "", telefono: "333 1111111")
        let luca1 = cliente("luca1", "Luca Verdi", cf: "", telefono: "333 1234567")
        let luca2 = cliente("luca2", "Luca Verdi", cf: "", email: "", telefono: "+39 333 123 4567")
        let anna1 = cliente("anna1", "Anna Neri", cf: "NRENNA90A41H501A", telefono: "333 5555555")
        let anna2 = cliente("anna2", "Anna Neri", cf: "NRENNA92A41H501B", telefono: "333 5555555")
        let voci = TagliandoVera.doppioni([marco, doppio, elena, luca1, luca2, anna1, anna2])
        controlla(voci.count == 2, "Tagliando, doppioni: due coppie (stesso codice fiscale; nome uguale e stesso telefono): \(voci.map(\.dettaglio))")
        let cf = voci.first { $0.clienti.contains("marco") }
        controlla(cf?.dettaglio.contains("stesso codice fiscale") == true && cf?.dettaglio.contains("telefono diverso") == true,
                  "Tagliando, doppioni: «Marco Bianchi» e «M. Bianchi» con lo stesso codice fiscale e telefono diverso: \(cf?.dettaglio ?? "")")
        controlla(cf?.gravita == .arancio && cf?.correzione?.etichetta == "Unisci le schede", "Tagliando, doppioni: arancio, con «Unisci le schede»")
        let unisci = cf?.correzione?.azione
        controlla(unisci?.strumento == TagliandoVera.strumentoUnisci && unisci?.argomenti["principale"] == "marco" && unisci?.argomenti["doppione"] == "m-bianchi",
                  "Tagliando, doppioni: resta la scheda più completa (Marco Bianchi)")
        controlla(unisci?.dettaglio.contains("non si cancella") == true && unisci?.avviso != nil,
                  "Tagliando, doppioni: l'unione è una proposta, la scheda doppia non si cancella e il telefono diverso è un avviso")
        controlla(voci.contains { Set($0.clienti) == ["luca1", "luca2"] && $0.dettaglio.contains("stesso telefono") },
                  "Tagliando, doppioni: il +39 non conta nel confronto dei telefoni")
        controlla(!voci.contains { $0.clienti.contains("elena") }, "Tagliando, doppioni: Elena e Marco Bianchi hanno lo stesso telefono ma sono due persone")
        controlla(!voci.contains { $0.clienti.contains("anna1") }, "Tagliando, doppioni: due codici fiscali diversi sono sempre due persone")
        controlla(TagliandoVera.nomiSimili("Marco Bianchi", "Bianchi Marco") && TagliandoVera.nomiSimili("Marco Bianchi", "Marco Bianci")
                  && !TagliandoVera.nomiSimili("Marco Bianchi", "Laura Moretti"), "Tagliando, doppioni: nomi simili (ordine, iniziale, una lettera)")

        // Tre schede della stessa persona: una principale e due unioni verso quella, mai un'unione tra le due doppie
        var paolo = cliente("t1", "Paolo Neri", cf: "NRIPLA80A01H501X", telefono: "333 7000001")
        paolo.professione = "Medico"
        let paolo2 = cliente("t2", "P. Neri", cf: "nripla80a01h501x", telefono: "333 7000002")
        let paolo3 = cliente("t3", "Paolo Neri", cf: "NRIPLA80A01H501X", telefono: "333 7000003")
        let tre = TagliandoVera.doppioni([paolo, paolo2, paolo3])
        controlla(tre.count == 2 && tre.allSatisfy { $0.correzione?.azione?.argomenti["principale"] == "t1" }
                  && Set(tre.compactMap { $0.correzione?.azione?.argomenti["doppione"] }) == ["t2", "t3"],
                  "Tagliando, doppioni: tre schede dello stesso codice fiscale, due unioni verso la principale: \(tre.map(\.clienti))")
        controlla(!tre.contains { Set($0.clienti) == ["t2", "t3"] }, "Tagliando, doppioni: nessuna unione tra due schede doppie")
        let ids = tre.map(\.id)
        controlla(Set(ids).count == ids.count, "Tagliando, doppioni: un id per unione")
        // Una scheda senza codice fiscale simile a due persone con codici diversi non le mette nello stesso gruppo
        let gino1 = cliente("g1", "Gino Sala", cf: "SLAGNI80A01H501A", telefono: "333 8000000")
        let gino2 = cliente("g2", "Gino Sala", cf: "", telefono: "333 8000000")
        let gino3 = cliente("g3", "Gino Sala", cf: "SLAGNI82A01H501B", telefono: "333 8000000")
        let ponte = TagliandoVera.doppioni([gino1, gino2, gino3])
        controlla(ponte.count == 1 && !ponte.contains { $0.clienti.contains("g1") && $0.clienti.contains("g3") },
                  "Tagliando, doppioni: due codici fiscali diversi restano due persone anche attraverso una terza scheda: \(ponte.map(\.clienti))")

        // «M. Bianchi» somiglia sia a Marco sia a Matteo Bianchi, ma Marco e Matteo sono due persone: niente unione tra loro
        let marcoB = cliente("mb1", "Marco Bianchi", cf: "", telefono: "333 9000000")
        let mB = cliente("mb2", "M. Bianchi", cf: "", telefono: "333 9000000")
        let matteoB = cliente("mb3", "Matteo Bianchi", cf: "", telefono: "333 9000000")
        let catena = TagliandoVera.doppioni([marcoB, mB, matteoB])
        controlla(catena.count == 1 && !catena.contains { $0.clienti.contains("mb1") && $0.clienti.contains("mb3") },
                  "Tagliando, doppioni: Marco e Matteo Bianchi non si uniscono passando per «M. Bianchi»: \(catena.map(\.clienti))")

        // Mario e Maria Rossi con lo stesso telefono di casa sono due persone della stessa famiglia
        let mario = cliente("mario", "Mario Rossi", cf: "", telefono: "02 1234567")
        let maria = cliente("maria", "Maria Rossi", telefono: "02 1234567")
        controlla(TagliandoVera.doppioni([mario, maria]).isEmpty && !TagliandoVera.nomiSimili("Mario Rossi", "Maria Rossi")
                  && !TagliandoVera.nomiSimili("Giulio Conti", "Giulia Conti"),
                  "Tagliando, doppioni: Mario e Maria Rossi (stesso telefono) non sono la stessa persona")
        // Familiari con nomi corti simili e lo stesso telefono di casa: due persone, mai «Unisci le schede»
        let luca = cliente("lucaB", "Luca Bianchi", cf: "", telefono: "02 7654321")
        let lucia = cliente("luciaB", "Lucia Bianchi", cf: "", telefono: "02 7654321")
        let rita = cliente("ritaF", "Rita Ferri", cf: "", telefono: "02 7654321")
        let rosa = cliente("rosaF", "Rosa Ferri", cf: "", telefono: "02 7654321")
        controlla(TagliandoVera.doppioni([luca, lucia, rita, rosa]).isEmpty && !TagliandoVera.nomiSimili("Luca Bianchi", "Lucia Bianchi")
                  && !TagliandoVera.nomiSimili("Rita Ferri", "Rosa Ferri") && !TagliandoVera.nomiSimili("Gianni Conti", "Giannina Conti"),
                  "Tagliando, doppioni: Luca e Lucia Bianchi, Rita e Rosa Ferri (stesso telefono) non sono la stessa persona")
        controlla(TagliandoVera.nomiSimili("Bianci Marco", "Marco Bianchi") && TagliandoVera.nomiSimili("Elena Moretti", "Elena Moreti"),
                  "Tagliando, doppioni: il refuso in una parola resta riconosciuto anche con le parole in ordine diverso")
    }

    // MARK: - Campi vuoti

    private static func campi(_ controlla: (Bool, String) -> Void) {
        let vuota = cliente("vuota", "Paola Gialli", cf: "", email: "")
        let e = controllo([vuota], documenti: [identita("vuota", scadenza: "05/05/2031", cf: "GLLPLA80A41H501Q")])
        let v = e.voci.first { $0.tipo == .campiVuoti }
        controlla(v?.gravita == .neutro && v?.dettaglio == "Paola Gialli · senza codice fiscale e email", "Tagliando, campi vuoti: neutro, con i campi che mancano: \(v?.dettaglio ?? "")")
        let a = v?.correzione?.azione
        controlla(a?.strumento == TagliandoVera.strumentoCompleta && a?.argomenti["valore"] == "GLLPLA80A41H501Q" && a?.argomenti["campo"] == "codiceFiscale",
                  "Tagliando, campi vuoti: il codice fiscale letto nella carta d'identità diventa «Completa dai documenti»")
        controlla(a?.avviso != nil, "Tagliando, campi vuoti: un dato letto ma non confermato ha l'avviso")
        let senzaDocumenti = controllo([vuota]).voci.first { $0.tipo == .campiVuoti }
        controlla(senzaDocumenti?.correzione == .naviga(etichetta: "Completa la scheda", destinazione: .scheda(clienteId: "vuota", sezione: .anagrafica)),
                  "Tagliando, campi vuoti: senza documenti si apre la scheda")
        let storta = cliente("storta", "Ugo Blu", cf: "ABC", email: "ugo-esempio.it")
        controlla(controllo([storta]).voci.contains { $0.tipo == .datoDaControllare && $0.dettaglio.contains("codice fiscale") && $0.dettaglio.contains("email") },
                  "Tagliando: codice fiscale ed email scritti male sono da controllare")
        let riga = TagliandoVera.riepilogoCampiVuoti(controllo([vuota, cliente("v2", "Rita Viola", cf: "")]), clienti: [vuota, cliente("v2", "Rita Viola", cf: "")])
        controlla(riga == "2 schede senza codice fiscale, 1 senza email", "Tagliando: i campi vuoti in una riga, come nel template: \(riga ?? "")")
    }

    // MARK: - Consensi

    private static func consensi(_ controlla: (Bool, String) -> Void) {
        var senza = cliente("sofia", "Sofia Romano")
        senza.consensi.privacy = false
        var commerciale = cliente("laura", "Laura Moretti")
        commerciale.consensi.marketing = true
        commerciale.consensi.dataMarketing = data(2024, 5, 1)
        let e = controllo([senza, commerciale])
        let p = e.voci.first { $0.tipo == .privacy }
        controlla(p?.gravita == .rosso && p?.clienteId == "sofia" && p?.titolo == "Consenso privacy mancante", "Tagliando: consenso privacy mancante in rosso")
        let a = p?.correzione?.azione
        controlla(a?.strumento == RegistroStrumenti.attivitaNuova && a?.argomenti["cliente"] == "sofia"
                  && a?.argomenti["scadenza"] == RegistroStrumenti.isoData(cal.startOfDay(for: data(2026, 11, 16))),
                  "Tagliando: la correzione è un'attività da confermare, entro una settimana")
        let k = e.voci.first { $0.tipo == .commerciale }
        controlla(k?.gravita == .arancio && k?.clienteId == "laura" && k?.titolo == "Consenso commerciale scaduto",
                  "Tagliando: consenso commerciale dato 30 mesi fa (vale 24) è scaduto, in arancio")
        controlla(e.voci.first == p, "Tagliando: le voci rosse vengono prima")
    }

    // MARK: - Riesame

    private static func riesame(_ controlla: (Bool, String) -> Void) {
        let federico = cliente("federico", "Federico Galli")
        let giulia = cliente("giulia", "Giulia Rossi")
        let e = controllo([federico, giulia], posizioni: [posizione("federico"), posizione("giulia")],
                          appuntamenti: [appuntamento("federico", data(2025, 9, 9), tipo: .revisione, stato: .concluso),
                                         appuntamento("giulia", data(2025, 9, 9), tipo: .revisione, stato: .concluso),
                                         appuntamento("giulia", data(2026, 12, 3), tipo: .revisione, stato: .pianificato)])
        let r = e.voci.filter { $0.tipo == .riesame }
        controlla(r.count == 1 && r.first?.clienteId == "federico" && r.first?.gravita == .rosso,
                  "Tagliando, riesame: oltre i 12 mesi senza niente in agenda (con la revisione già fissata no): \(r.map(\.dettaglio))")
        controlla(r.first?.dettaglio == "Federico Galli · sono passati 14 mesi dall'ultimo incontro", "Tagliando, riesame: i mesi dall'ultimo incontro: \(r.first?.dettaglio ?? "")")
        controlla(r.first?.correzione?.etichetta == "Fissa il riesame", "Tagliando, riesame: «Fissa il riesame»")
        let recente = controllo([federico], posizioni: [posizione("federico")],
                                appuntamenti: [appuntamento("federico", data(2026, 3, 1), tipo: .revisione, stato: .concluso)])
        controlla(!recente.voci.contains { $0.tipo == .riesame }, "Tagliando, riesame: un incontro di marzo basta")
    }

    // MARK: - Questionario prima di un incontro

    private static func questionario(_ controlla: (Bool, String) -> Void) {
        let andrea = cliente("andrea", "Andrea Conti")
        let e = controllo([andrea], appuntamenti: [appuntamento("andrea", data(2026, 11, 11), tipo: .primoIncontro, stato: .pianificato)])
        let q = e.voci.filter { $0.tipo == .questionario }
        controlla(q.count == 1 && q.first?.gravita == .arancio && q.first?.titolo == "Questionario di profilatura da compilare",
                  "Tagliando, questionario: manca prima del primo incontro: \(q.map(\.dettaglio))")
        controlla(q.first?.dettaglio.contains("il primo incontro è") == true, "Tagliando, questionario: il dettaglio dice quando è l'incontro: \(q.first?.dettaglio ?? "")")
        controlla(q.first?.correzione?.azione?.argomenti["scadenza"] == RegistroStrumenti.isoData(cal.startOfDay(for: data(2026, 11, 10))),
                  "Tagliando, questionario: l'attività scade il giorno prima dell'incontro")
        let firma = controllo([andrea], appuntamenti: [appuntamento("andrea", data(2026, 11, 11), tipo: .firma, stato: .pianificato)])
        controlla(firma.voci.first { $0.tipo == .questionario }?.gravita == .rosso, "Tagliando, questionario: prima di una firma è rosso")

        // Un cliente già seguito su Alleanza, senza questionario, con una firma vicina: rosso anche lui
        var bruno = cliente("bruno", "Bruno Ferri")
        bruno.canali = [.alleanza]
        let firmaBruno = appuntamento("bruno", data(2026, 11, 21), tipo: .firma, stato: .pianificato)
        let qb = controllo([bruno], appuntamenti: [firmaBruno]).voci.filter { $0.tipo == .questionario }
        controlla(qb.count == 1 && qb.first?.gravita == .rosso && qb.first?.peso == TagliandoVera.pesoRosso,
                  "Tagliando, questionario: manca il questionario Alleanza prima di una firma, rosso: \(qb.map(\.gravita))")
        let qbIncontro = controllo([bruno], appuntamenti: [appuntamento("bruno", data(2026, 11, 21), tipo: .revisione, stato: .pianificato)])
            .voci.filter { $0.tipo == .questionario }
        controlla(qbIncontro.count == 1 && qbIncontro.first?.gravita == .arancio, "Tagliando, questionario: prima di una revisione resta arancio")
        // Questionario Alleanza che scade il 20 novembre, firma il 21: rosso
        var inScadenza = bruno
        var kb = ConformitaCliente()
        kb.questionarioAlleanza = QuestionarioAdeguatezza(compilatoIl: data(2023, 11, 20))
        inScadenza.conformita = kb
        let qs = controllo([inScadenza], appuntamenti: [firmaBruno]).voci.filter { $0.tipo == .questionario }
        controlla(qs.count == 1 && qs.first?.gravita == .rosso && qs.first?.dettaglio.contains("prima dell'incontro") == true,
                  "Tagliando, questionario: in scadenza prima della firma, rosso: \(qs.map(\.dettaglio))")
        // Firma Alleanza per un cliente seguito su entrambi i canali: il questionario indipendente che manca resta arancio
        var doppio = cliente("doppio", "Carla Neri")
        doppio.canali = [.alleanza, .indipendente]
        var kd = ConformitaCliente()
        kd.questionarioAlleanza = QuestionarioAdeguatezza(compilatoIl: data(2026, 6, 1))
        doppio.conformita = kd
        var firmaAlleanza = appuntamento("doppio", data(2026, 11, 21), tipo: .firma, stato: .pianificato)
        firmaAlleanza.canale = .alleanza
        let qd = controllo([doppio], appuntamenti: [firmaAlleanza]).voci.filter { $0.tipo == .questionario }
        controlla(qd.count == 1 && qd.first?.id.contains("indipendente-mancante") == true && qd.first?.gravita == .arancio
                  && qd.first?.peso == TagliandoVera.pesoArancio,
                  "Tagliando, questionario: una firma Alleanza non fa rosso il questionario indipendente: \(qd.map { "\($0.id) \($0.gravita)" })")
        var compilato = andrea
        var k = ConformitaCliente()
        k.questionarioIndipendente = QuestionarioAdeguatezza(compilatoIl: data(2025, 11, 1))
        compilato.conformita = k
        let ok = controllo([compilato], appuntamenti: [appuntamento("andrea", data(2026, 11, 11), tipo: .primoIncontro, stato: .pianificato)])
        controlla(!ok.voci.contains { $0.tipo == .questionario }, "Tagliando, questionario: compilato da un anno vale ancora")
        let lontano = controllo([andrea], appuntamenti: [appuntamento("andrea", data(2027, 1, 20), tipo: .primoIncontro, stato: .pianificato)])
        controlla(!lontano.voci.contains { $0.tipo == .questionario }, "Tagliando, questionario: un incontro tra due mesi non conta ancora")
    }

    // MARK: - Documento d'identità e posizioni scadute

    private static func documento(_ controlla: (Bool, String) -> Void) {
        func seguito(_ id: String, _ nome: String, scadenza: Date) -> Cliente {
            var c = cliente(id, nome)
            c.canali = [.indipendente]
            var k = ConformitaCliente()
            k.questionarioIndipendente = QuestionarioAdeguatezza(compilatoIl: data(2025, 6, 1))
            k.verificaIndipendente = AdeguataVerifica(eseguitaIl: data(2025, 6, 1), rischio: .basso)
            k.documento = DocumentoIdentita(tipo: .cartaIdentita, numero: "CA11111AA", rilasciatoIl: data(2016, 9, 1), scadenza: scadenza)
            c.conformita = k
            return c
        }
        let scaduto = seguito("scaduto", "Marta Sole", scadenza: data(2026, 9, 1))
        let vicino = seguito("vicino", "Laura Moretti", scadenza: data(2026, 12, 20))
        let nuovo = seguito("nuovo", "Piero Luna", scadenza: data(2026, 9, 1))
        let e = controllo([scaduto, vicino, nuovo], documenti: [identita("nuovo", scadenza: "05/05/2031")])
        let d1 = e.voci(cliente: "scaduto").filter { $0.tipo == .documentoIdentita }
        controlla(d1.count == 1 && d1.first?.gravita == .rosso && d1.first?.correzione?.etichetta == "Chiedi la copia nuova",
                  "Tagliando, documento: scaduto in rosso, con «Chiedi la copia nuova»")
        let d2 = e.voci(cliente: "vicino").filter { $0.tipo == .documentoIdentita }
        controlla(d2.count == 1 && d2.first?.gravita == .arancio && d2.first?.dettaglio.contains("20 dicembre 2026") == true,
                  "Tagliando, documento: in scadenza tra 41 giorni, in arancio con la data: \(d2.first?.dettaglio ?? "")")
        let d3 = e.voci(cliente: "nuovo")
        let registra = d3.first { $0.tipo == .documentoNuovo }?.correzione?.azione
        controlla(!d3.contains { $0.tipo == .documentoIdentita } && registra?.strumento == TagliandoVera.strumentoDocumento
                  && registra?.argomenti["numero"] == "CA99999ZZ" && registra?.argomenti["scadenza"] != nil,
                  "Tagliando, documento: il documento nuovo letto in Documenti si propone di registrarlo, al posto di «scaduto»")
        controlla(e.voci(cliente: "vicino").allSatisfy { $0.tipo == .documentoIdentita }, "Tagliando: una scheda seguita in regola ha solo la voce del documento")

        let pos = controllo([cliente("p", "Gino Mare")], posizioni: [posizione("p", scadenza: data(2026, 10, 1))])
        let p = pos.voci.first { $0.tipo == .posizioneScaduta }
        controlla(p?.correzione == .naviga(etichetta: "Aggiorna la posizione", destinazione: .posizione(id: "pos-p")),
                  "Tagliando: una posizione scaduta ma in essere porta a Posizioni")
    }

    // MARK: - Salute

    private static func salute(_ controlla: (Bool, String) -> Void) {
        let pulita = cliente("pulita", "Giulia Rossi")
        controlla(controllo([pulita]).voci.isEmpty && controllo([pulita]).salute == 100, "Tagliando, salute: una scheda in ordine fa 100")
        controlla(controllo([]).salute == 100 && TagliandoVera.riepilogo(controllo([])) == "Archivio in ordine", "Tagliando, salute: archivio vuoto, 100 e in ordine")
        var rossa = cliente("rossa", "Sofia Romano")
        rossa.consensi.privacy = false
        let e = controllo([pulita, rossa])
        controlla(e.saluteSchede["rossa"] == 60 && e.salute == 80, "Tagliando, salute: una voce rossa toglie 40 alla scheda, l'archivio è la media (80): \(e.salute)")
        var due = rossa
        due.codiceFiscale = ""
        due.email = ""
        let e2 = controllo([due])
        controlla(e2.salute == 100 - TagliandoVera.pesoRosso - 2 * TagliandoVera.pesoNeutro, "Tagliando, salute: rosso 40 più due campi vuoti 4 ciascuno: \(e2.salute)")
        let ignorata = controllo([pulita, rossa], ignorate: [e.voci[0].id])
        controlla(ignorata.voci.isEmpty && ignorata.ignorate.count == 1 && ignorata.salute == 100,
                  "Tagliando: «Va bene così» toglie la voce dall'elenco e dal punteggio")
        controlla(TagliandoVera.riepilogo(e) == "1 cosa da sistemare" && TagliandoVera.schede(e.schede) == "2 schede", "Tagliando: i testi della pagina")
        let r = RegistroTagliando(data: data(2026, 11, 9, 2, 10), salute: 82, schede: 35, rosse: 2, arancioni: 3, neutre: 1, voci: [])
        controlla(TagliandoVera.quando(r, oggi: oggi, calendario: cal) == "Controllate stanotte alle 2:10.", "Tagliando: «Controllate stanotte alle 2:10.»")
        controlla(TagliandoVera.nuove(e, rispetto: e.registro).isEmpty && TagliandoVera.nuove(e, rispetto: nil).count == 1,
                  "Tagliando: le voci nuove rispetto al controllo prima")
        let copia = try? JSONDecoder().decode(RegistroTagliando.self, from: JSONEncoder().encode(e.registro))
        controlla(copia == e.registro, "Tagliando: il registro si salva e si rilegge uguale")
    }

    // MARK: - Correzioni: mai eseguite, mai cancellazioni

    private static func correzioni(_ controlla: (Bool, String) -> Void) {
        var sofia = cliente("sofia", "Sofia Romano")
        sofia.consensi.privacy = false
        // Telefono diverso: il doppione deve venire dall'email, non dal telefono di base delle schede di prova
        let doppio = cliente("sofia2", "S. Romano", cf: "", email: "sofia@esempio.it", telefono: "347 9999999")
        let e = controllo([sofia, doppio, cliente("vuota", "Paola Gialli", cf: "", email: "")],
                          posizioni: [posizione("sofia", scadenza: data(2026, 1, 1))],
                          appuntamenti: [appuntamento("sofia", data(2024, 6, 1), tipo: .revisione, stato: .concluso)],
                          documenti: [identita("vuota", scadenza: "01/01/2030", cf: "GLLPLA80A41H501Q")])
        let ammessi: Set<String> = [RegistroStrumenti.attivitaNuova, TagliandoVera.strumentoUnisci, TagliandoVera.strumentoCompleta, TagliandoVera.strumentoDocumento]
        controlla(e.azioni.allSatisfy { ammessi.contains($0.strumento) && !$0.strumento.contains("elimina") && !$0.strumento.contains("cancella") },
                  "Tagliando: le correzioni sono solo proposte di strumenti noti, nessuna cancellazione: \(Set(e.azioni.map(\.strumento)))")
        controlla(e.voci.contains { $0.tipo == .doppione && $0.dettaglio.contains("stessa email") },
                  "Tagliando: «Sofia Romano» e «S. Romano» con la stessa email sono un doppione: \(e.voci.filter { $0.tipo == .doppione }.map(\.dettaglio))")
        let tutto = TagliandoVera.schedaSistemaTutto(e)
        controlla(tutto?.azioni.count == e.azioni.count && tutto?.stato == .daConfermare && tutto?.azioni.allSatisfy({ $0.esito == nil }) == true,
                  "Tagliando: «Sistema tutto» prepara una scheda da confermare, niente è già eseguito")
        controlla(e.voci.allSatisfy { $0.correzione != nil }, "Tagliando: ogni voce ha la sua correzione")
        let ids = e.voci.map(\.id)
        controlla(Set(ids).count == ids.count, "Tagliando: gli id delle voci sono unici")
        let ancora = controllo([sofia, doppio, cliente("vuota", "Paola Gialli", cf: "", email: "")],
                               posizioni: [posizione("sofia", scadenza: data(2026, 1, 1))],
                               appuntamenti: [appuntamento("sofia", data(2024, 6, 1), tipo: .revisione, stato: .concluso)],
                               documenti: [identita("vuota", scadenza: "01/01/2030", cf: "GLLPLA80A41H501Q")])
        controlla(ancora.voci.map(\.id) == ids && ancora.voci.map(\.dettaglio) == e.voci.map(\.dettaglio), "Tagliando: due controlli uguali danno le stesse voci")
        controlla(TagliandoVera.scheda(e.voci[0])?.azioni.count == 1, "Tagliando: una voce sola diventa una scheda «Conferma» con un'azione")
    }

    // MARK: - I 5 clienti di prova

    private static func demo(_ controlla: (Bool, String) -> Void) {
        let dati = StatoShell(persistente: false).dati.istantanea
        let e = TagliandoVera.controlla(dati, oggi: Date())
        let ids = Set(dati.clienti.map(\.id))
        controlla(e.schede == dati.clienti.count && (0...100).contains(e.salute), "Tagliando, dati di prova: \(e.schede) schede, salute \(e.salute)")
        controlla(e.voci.allSatisfy { !$0.clienti.isEmpty && $0.clienti.allSatisfy(ids.contains) }, "Tagliando, dati di prova: ogni voce è di un cliente dell'archivio")
        controlla(e.voci(cliente: "marco").contains { $0.tipo == .verifica || $0.tipo == .questionario },
                  "Tagliando, dati di prova: Marco ha questionario o adeguata verifica Alleanza da rinnovare")
        controlla(e.voci.map(\.id) == TagliandoVera.controlla(dati, oggi: e.oggi).voci.map(\.id), "Tagliando, dati di prova: il controllo è ripetibile")
    }
}
