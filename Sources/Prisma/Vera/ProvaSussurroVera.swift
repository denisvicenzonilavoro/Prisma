import Foundation

/// Prova del «Sussurro» (Vera/BRIEF.md, funzione 7) dentro `Prisma --prova-vera`: le regole (consensi, promesse,
/// scadenze, riesame, documento, liquidità, compleanni, anniversario, preferenze dai ricordi), al massimo tre voci con
/// al massimo due dello stesso tono, niente doppioni, ordine fisso, voci chiuse, la scheda di conferma per le azioni che
/// cambiano qualcosa e i clienti del template. Deterministica: `oggi` fisso, niente rete, niente Qwen.
enum ProvaSussurroVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        calma(controlla)
        comeNelTemplate(controlla)
        regole(controlla)
        limiti(controlla)
        ordine(controlla)
        chiuse(controlla)
        conferma(controlla)
        template(controlla)
    }

    // MARK: - Dati di prova

    private static let cal = Calendar.current
    /// Domenica 8 novembre 2026, mezzogiorno.
    private static let oggi = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 12)) ?? Date(timeIntervalSince1970: 1_794_052_800)

    private static func giorno(_ g: Int) -> Date { cal.date(byAdding: .day, value: g, to: oggi) ?? oggi }

    private static func data(_ a: Int, _ m: Int, _ g: Int) -> Date {
        cal.date(from: DateComponents(year: a, month: m, day: g, hour: 9)) ?? oggi
    }

    /// Una cliente in regola: consenso privacy dato, canale Alleanza, cliente dal 1° marzo 2024.
    private static func cliente() -> Cliente {
        var c = Cliente(id: "prova", nome: "Sofia Romano", iniziali: "SR", tinta: .rosa, tema: "", email: "", telefono: "",
                        preferito: false, nota: "", creatoIl: data(2024, 3, 1))
        c.consensi = Consensi(privacy: true, dataPrivacy: giorno(-400))
        c.canali = [.alleanza]
        return c
    }

    private static func posizione(_ id: String, _ area: AreaPosizione, _ nome: String, scadenza: Date? = nil, valore: Double? = nil) -> Posizione {
        var p = Posizione(clienteId: "prova", canale: .alleanza, stato: .inEssere, area: area, nome: nome)
        p.id = id
        p.scadenza = scadenza
        p.controvalore = valore
        return p
    }

    private static func promessa(_ id: String, _ testo: String, scadenza: Date?, quando: String? = nil) -> PromessaCliente {
        var p = PromessaCliente(clienteId: "prova", testo: testo, frase: testo, fonte: .nota, fonteId: "nota-\(id)",
                                fonteEtichetta: "dalla nota di prova", scadenza: scadenza, quando: quando)
        p.id = id
        return p
    }

    /// Un incontro di due mesi fa (niente riesame saltato) e un piano di risparmio senza scadenza.
    private static func fonte(_ c: Cliente? = nil, posizioni: [Posizione]? = nil, appuntamenti: [Appuntamento] = [],
                              incontri: [Incontro]? = nil, promesse: [PromessaCliente] = [], analisi: Analisi360? = nil,
                              regole: RegoleConformita = RegoleConformita(), ricordi: [String] = [], chiuse: Set<String> = []) -> FonteSussurro {
        FonteSussurro(oggi: oggi, cliente: c ?? cliente(),
                      posizioni: posizioni ?? [posizione("piano", .risparmio, "Piano di risparmio")],
                      appuntamenti: appuntamenti,
                      incontri: incontri ?? [Incontro(clienteId: "prova", titolo: "Punto", data: giorno(-60))],
                      promesse: promesse, analisi: analisi, regole: regole, ricordi: ricordi, chiuse: chiuse)
    }

    // MARK: - Niente da dire

    private static func calma(_ controlla: (Bool, String) -> Void) {
        let v = SussurroVera.candidate(fonte())
        controlla(v.isEmpty, "Sussurro: una cliente in regola, senza scadenze né promesse, non ha voci: \(v.map(\.testo))")
    }

    // MARK: - La scena del template (Sofia)

    private static func comeNelTemplate(_ controlla: (Bool, String) -> Void) {
        var c = cliente()
        c.consensi = Consensi()
        c.famiglia = [Familiare(nome: "Paolo Romano", relazione: .coniuge)]
        let rivalutabile = posizione("rivalutabile", .risparmio, "Polizza rivalutabile", scadenza: giorno(70))
        let giovedi = Appuntamento(id: "giovedi", clienteId: "prova", titolo: "Revisione", inizio: giorno(4), durataMinuti: 45,
                                   luogo: "In studio", note: "", stato: .pianificato, tipo: .revisione)
        let v = SussurroVera.voci(fonte(c, posizioni: [rivalutabile], appuntamenti: [giovedi], ricordi: ["Decide sempre insieme a Paolo"]))
        controlla(v.map(\.tono) == [.rosso, .arancio, .blu], "Sussurro: tre voci, rossa, arancio e blu: \(v.map(\.tono))")
        controlla(v.map(\.categoria) == [.consensoPrivacy, .scadenza, .preferenza], "Sussurro: consenso, scadenza e preferenza: \(v.map(\.categoria))")
        controlla(v.first?.testo == "Manca il consenso privacy: raccoglilo prima di nuove proposte." && v.first?.azione.tipo == .rinnovaConsenso,
                  "Sussurro: il consenso privacy mancante è rosso, con «Raccogli il consenso»: \(v.first?.testo ?? "")")
        controlla(v.count > 1 && v[1].azione.tipo == .mettiInScaletta && v[1].azione.riferimento == "giovedi" && v[1].testo.contains("ne parlate"),
                  "Sussurro: la scadenza con un incontro in agenda va «in scaletta» di quell'incontro: \(v.count > 1 ? v[1].testo : "")")
        controlla(v.count > 2 && v[2].azione.tipo == .invita && v[2].azione.titolo == "Invita Paolo" && v[2].testo == "Decide sempre insieme a Paolo.",
                  "Sussurro: dal ricordo «decide insieme a Paolo» l'azione è «Invita Paolo»: \(v.count > 2 ? v[2].azione.titolo : "")")
        controlla(v.allSatisfy { !$0.fonte.isEmpty }, "Sussurro: ogni voce ha la sua fonte")
    }

    // MARK: - Le regole una per una

    private static func regole(_ controlla: (Bool, String) -> Void) {
        // Consenso privacy da firmare di nuovo (informativa aggiornata il 2 settembre)
        var r = RegoleConformita()
        r.informativaAggiornataIl = giorno(-67)
        let privacy = SussurroVera.candidate(fonte(regole: r))
        controlla(privacy.first?.testo == "Il consenso privacy è scaduto il 2 settembre: rinnovalo prima di nuove proposte." && privacy.first?.tono == .rosso,
                  "Sussurro: il consenso privacy scaduto è rosso, con la data: \(privacy.first?.testo ?? "")")

        // Polizza in scadenza senza incontro: «Prepara il rinnovo»
        let infortuni = posizione("infortuni", .protezione, "Infortuni famiglia", scadenza: giorno(39))
        let s = SussurroVera.candidate(fonte(posizioni: [infortuni]))
        controlla(s.first?.testo == "«Infortuni famiglia» scade il 17 dicembre." && s.first?.tono == .arancio && s.first?.azione.tipo == .preparaRinnovo,
                  "Sussurro: la polizza che scade fra 39 giorni è arancio, con «Prepara il rinnovo»: \(s.first?.testo ?? "")")
        let vicina = SussurroVera.candidate(fonte(posizioni: [posizione("infortuni", .protezione, "Infortuni famiglia", scadenza: giorno(12))]))
        controlla(vicina.first?.tono == .rosso, "Sussurro: entro 30 giorni la scadenza è rossa")
        let lontana = SussurroVera.candidate(fonte(posizioni: [posizione("infortuni", .protezione, "Infortuni famiglia", scadenza: giorno(120))]))
        controlla(lontana.isEmpty, "Sussurro: una scadenza fra quattro mesi non si sussurra")
        let due = SussurroVera.candidate(fonte(posizioni: [infortuni, posizione("casa", .protezione, "Casa", scadenza: giorno(80))]))
        controlla(due.count == 1 && due[0].testo.contains("Ne scade anche un'altra"), "Sussurro: due scadenze, una voce sola con la più vicina: \(due.map(\.testo))")

        // Promesse
        let presto = promessa("p-presto", "Mandare a Sofia il riepilogo della rivalutabile", scadenza: giorno(3), quando: "entro mercoledì")
        let p = SussurroVera.candidate(fonte(promesse: [presto]))
        controlla(p.first?.testo == "Gli hai promesso di mandare a Sofia il riepilogo della rivalutabile entro mercoledì." && p.first?.tono == .arancio
                  && p.first?.azione.tipo == .apriPromessa && p.first?.azione.riferimento == "p-presto",
                  "Sussurro: la promessa di questa settimana è arancio, con «Apri la promessa»: \(p.first?.testo ?? "")")
        let tardi = promessa("p-tardi", "Mandare a Sofia il riepilogo", scadenza: giorno(-9))
        let t = SussurroVera.candidate(fonte(promesse: [tardi]))
        controlla(t.first?.testo == "Promessa in ritardo: mandare a Sofia il riepilogo, era per il 30 ottobre." && t.first?.tono == .rosso,
                  "Sussurro: la promessa in ritardo è rossa: \(t.first?.testo ?? "")")
        var fatta = tardi
        fatta.stato = .fatta
        let inTempo = promessa("p-tempo", "Richiamare Sofia", scadenza: giorno(20))
        controlla(SussurroVera.candidate(fonte(promesse: [fatta, inTempo])).isEmpty, "Sussurro: promesse fatte o in tempo non si sussurrano")
        // Dopo un rimando le parole della frase non valgono più: conta la nuova data
        var rimandata = promessa("p-rimandata", "Mandare a Sofia il KID", scadenza: giorno(-2), quando: "entro venerdì 6")
        rimandata.stato = .rimandata
        rimandata.rimandataAl = giorno(4)
        let r1 = SussurroVera.candidate(fonte(promesse: [rimandata]))
        controlla(r1.first?.testo == "Gli hai promesso di mandare a Sofia il KID entro il 12 novembre." && r1.first?.tono == .arancio,
                  "Sussurro: la promessa rimandata dice la nuova data, non «entro venerdì 6»: \(r1.first?.testo ?? "")")
        // Un «domani» scritto ieri è oggi: si scrive la data
        let domani = promessa("p-domani", "Richiamare Sofia", scadenza: giorno(1), quando: "domani")
        let r2 = SussurroVera.candidate(fonte(promesse: [domani]))
        controlla(r2.first?.testo == "Gli hai promesso di richiamare Sofia entro il 9 novembre.",
                  "Sussurro: un'espressione relativa («domani») diventa la data calcolata: \(r2.first?.testo ?? "")")
        controlla(SussurroVera.quandoRelativo("tra tre giorni") && SussurroVera.quandoRelativo("la settimana prossima")
                  && !SussurroVera.quandoRelativo("entro venerdì 6") && !SussurroVera.quandoRelativo("entro mercoledì"),
                  "Sussurro: le espressioni relative si riconoscono, i giorni scritti no")

        // Riesame saltato: 14 mesi dall'ultimo incontro, niente in agenda
        let rie = SussurroVera.candidate(fonte(incontri: [Incontro(clienteId: "prova", titolo: "Punto", data: giorno(-430))]))
        controlla(rie.first?.categoria == .riesame && rie.first?.testo == "Il riesame è saltato: sono passati 14 mesi dall'ultimo incontro."
                  && rie.first?.azione.tipo == .fissaRiesame, "Sussurro: il riesame saltato è rosso, con i mesi: \(rie.first?.testo ?? "")")

        // Documento d'identità
        var c = cliente()
        var conf = ConformitaCliente()
        conf.documento = DocumentoIdentita(tipo: .cartaIdentita, scadenza: giorno(71))
        c.conformita = conf
        let d = SussurroVera.candidate(fonte(c))
        controlla(d.first?.testo == "Il documento d'identità scade il 18 gennaio." && d.first?.tono == .arancio && d.first?.azione.tipo == .chiediCopia,
                  "Sussurro: il documento che scade fra 71 giorni è arancio, con «Chiedi la copia»: \(d.first?.testo ?? "")")

        // Liquidità in mesi di spese (solo con l'analisi salvata)
        var a = Analisi360()
        a.protezione.fabbisognoMensile = 2_000
        let nove = SussurroVera.candidate(fonte(posizioni: [posizione("conto", .liquidita, "Conto", valore: 18_000)], analisi: a))
        controlla(nove.first?.testo == "Ha 9 mesi di spese ferme in liquidità." && nove.first?.tono == .arancio,
                  "Sussurro: 9 mesi di spese ferme sono arancio: \(nove.first?.testo ?? "")")
        let sette = SussurroVera.candidate(fonte(posizioni: [posizione("conto", .liquidita, "Conto", valore: 15_000)], analisi: a))
        controlla(sette.first?.testo == "Ha 7,5 mesi di spese ferme in liquidità." && sette.first?.tono == .blu,
                  "Sussurro: 7,5 mesi sono blu, con la virgola: \(sette.first?.testo ?? "")")
        let sei = SussurroVera.candidate(fonte(posizioni: [posizione("conto", .liquidita, "Conto", valore: 12_000)], analisi: a))
        let stimata = SussurroVera.candidate(fonte(posizioni: [posizione("conto", .liquidita, "Conto", valore: 18_000)]))
        controlla(sei.isEmpty && stimata.isEmpty, "Sussurro: sei mesi non bastano e senza analisi salvata niente liquidità")

        // Compleanni e anniversario
        var tondo = cliente()
        tondo.dataNascita = data(1976, 12, 20)
        let ct = SussurroVera.candidate(fonte(tondo))
        controlla(ct.first?.testo == "A dicembre compie 50 anni: è il momento giusto per parlare della pensione." && ct.first?.azione.tipo == .mettiInScaletta,
                  "Sussurro: il compleanno tondo va in scaletta: \(ct.first?.testo ?? "")")
        var amico = Cliente(id: "prova", nome: "Sofia Romano", iniziali: "SR", tinta: .rosa, tema: "", email: "", telefono: "",
                        preferito: false, nota: "", creatoIl: data(2021, 11, 10))
        amico.consensi = Consensi(privacy: true, dataPrivacy: giorno(-400))
        amico.canali = [.alleanza]
        let an = SussurroVera.candidate(fonte(amico))
        controlla(an.first?.testo == "Il 10 novembre sono 5 anni da quando è tuo cliente." && an.first?.tono == .blu,
                  "Sussurro: l'anniversario della relazione: \(an.first?.testo ?? "")")

        // Preferenze dai ricordi
        let video = SussurroVera.candidate(fonte(ricordi: ["Ha un cane di nome Briciola", "preferisce le videochiamate al mattino"]))
        controlla(video.first?.testo == "Preferisce le videochiamate al mattino." && video.first?.azione.tipo == .proponiOrario,
                  "Sussurro: «videochiamate al mattino» porta a «Proponi un orario»: \(video.first?.testo ?? "")")
        let rischio = SussurroVera.candidate(fonte(ricordi: ["Non ama il rischio", "Preferisce le telefonate"]))
        controlla(rischio.count == 1 && rischio.first?.azione.tipo == .tieniAMente, "Sussurro: una preferenza sola, la più recente: \(rischio.map(\.testo))")
        controlla(SussurroVera.conChi("Decide insieme a lui", cliente: cliente()) == nil, "Sussurro: «insieme a lui» non è un nome")
        // Le parole si cercano intere o a inizio di parola, non dentro altre parole
        let onorari = SussurroVera.candidate(fonte(ricordi: ["Chiede sempre degli onorari"]))
        controlla(onorari.isEmpty, "Sussurro: «onorari» non è «orari», nessun «Proponi un orario»: \(onorari.map(\.azione.titolo))")
        let orario = SussurroVera.candidate(fonte(ricordi: ["Chiede sempre un orario preciso"]))
        controlla(orario.count == 1 && orario.first?.azione.tipo == .proponiOrario,
                  "Sussurro: «un orario preciso» (singolare) porta a «Proponi un orario»: \(orario.map(\.azione.titolo))")
        let custodia = SussurroVera.candidate(fonte(ricordi: ["Tiene i titoli in custodia", "Chiama spesso la figlia"]))
        controlla(custodia.isEmpty, "Sussurro: «custodia» non contiene «odia» e «chiama» non contiene «ama»: \(custodia.map(\.testo))")
        controlla(SussurroVera.contieneParola("non ama il rischio", SussurroVera.parolePreferenze)
                  && SussurroVera.contieneParola("preferisce di sera", SussurroVera.paroleOrari),
                  "Sussurro: le parole intere e le radici a inizio di parola si trovano ancora")
        // «tiene a» va trovato intero: «tiene alcuni risparmi» non è una preferenza
        let alcuni = SussurroVera.candidate(fonte(ricordi: ["Tiene alcuni risparmi sul conto"]))
        controlla(alcuni.isEmpty && !SussurroVera.contieneParola("tiene alcuni risparmi sul conto", SussurroVera.parolePreferenze),
                  "Sussurro: «tiene alcuni» non contiene «tiene a»: \(alcuni.map(\.testo))")
        controlla(SussurroVera.contieneParola("tiene a vederlo di persona", SussurroVera.parolePreferenze)
                  && SussurroVera.contieneParola("tiene alla puntualita", SussurroVera.parolePreferenze)
                  && SussurroVera.contieneParola("tiene all'educazione dei figli", SussurroVera.parolePreferenze),
                  "Sussurro: «tiene a», «tiene alla» e «tiene all'» restano preferenze")
    }

    // MARK: - Mai più di tre, niente doppioni

    private static func limiti(_ controlla: (Bool, String) -> Void) {
        var c = cliente()
        c.consensi = Consensi()
        var conf = ConformitaCliente()
        conf.documento = DocumentoIdentita(tipo: .cartaIdentita, scadenza: giorno(-5))
        c.conformita = conf
        let posizioni = [posizione("infortuni", .protezione, "Infortuni famiglia", scadenza: giorno(10))]
        let promesse = [promessa("p1", "Mandare a Sofia il riepilogo", scadenza: giorno(-9)),
                        promessa("p2", "Mandare a Sofia il KID", scadenza: giorno(-2))]
        let rossi = SussurroVera.voci(fonte(c, posizioni: posizioni, incontri: [], promesse: promesse))
        controlla(rossi.count == 3 && rossi.allSatisfy { $0.tono == .rosso }, "Sussurro: solo voci rosse: tre rosse, mai di più: \(rossi.map(\.categoria))")
        controlla(rossi.map(\.categoria) == [.consensoPrivacy, .promessa, .scadenza], "Sussurro: prima il consenso, poi la promessa, poi la scadenza: \(rossi.map(\.categoria))")
        controlla(rossi.count > 1 && rossi[1].testo.hasPrefix("Hai 2 promesse in ritardo") && rossi[1].azione.riferimento == "p1",
                  "Sussurro: due promesse in ritardo fanno una voce sola, sulla più vecchia: \(rossi.count > 1 ? rossi[1].testo : "")")
        let tutte = SussurroVera.candidate(fonte(c, posizioni: posizioni, incontri: [], promesse: promesse))
        controlla(Set(tutte.map(\.chiave)).count == tutte.count && Set(tutte.map(\.categoria)).count == tutte.count,
                  "Sussurro: nessun doppione tra le voci possibili (\(tutte.count))")

        c.dataNascita = data(1976, 11, 9)
        let misto = SussurroVera.voci(fonte(c, posizioni: posizioni, incontri: [], promesse: promesse))
        controlla(misto.count == 3 && misto.filter { $0.tono == .rosso }.count == 2 && misto.last?.categoria == .compleanno,
                  "Sussurro: con una voce blu, al massimo due rosse: \(misto.map(\.categoria))")
        controlla(misto.last?.testo == "Domani compie 50 anni." && misto.last?.azione.tipo == .faiAuguri,
                  "Sussurro: il compleanno di domani (anche tondo) è una voce sola, gli auguri: \(misto.last?.testo ?? "")")
    }

    // MARK: - Ordine fisso

    private static func ordine(_ controlla: (Bool, String) -> Void) {
        var c = cliente()
        c.consensi = Consensi()
        c.dataNascita = data(1976, 12, 20)
        var a = Analisi360()
        a.protezione.fabbisognoMensile = 2_000
        let posizioni = [posizione("infortuni", .protezione, "Infortuni famiglia", scadenza: giorno(39)),
                         posizione("casa", .protezione, "Casa", scadenza: giorno(80)),
                         posizione("conto", .liquidita, "Conto", valore: 15_000)]
        let promesse = [promessa("p1", "Mandare a Sofia il riepilogo", scadenza: giorno(2)),
                        promessa("p2", "Mandare a Sofia il KID", scadenza: giorno(5))]
        let ricordi = ["Preferisce le videochiamate al mattino"]
        let uno = SussurroVera.voci(fonte(c, posizioni: posizioni, promesse: promesse, analisi: a, ricordi: ricordi))
        let due = SussurroVera.voci(fonte(c, posizioni: Array(posizioni.reversed()), promesse: Array(promesse.reversed()), analisi: a, ricordi: ricordi))
        controlla(uno == due && !uno.isEmpty, "Sussurro: lo stesso risultato con i dati in un altro ordine")
        controlla(uno == SussurroVera.voci(fonte(c, posizioni: posizioni, promesse: promesse, analisi: a, ricordi: ricordi)), "Sussurro: due calcoli uguali")
        let tutte = SussurroVera.candidate(fonte(c, posizioni: posizioni, promesse: promesse, analisi: a, ricordi: ricordi))
        let ordinate = zip(tutte, tutte.dropFirst()).allSatisfy { !SussurroVera.precede($0.1, $0.0) }
        controlla(ordinate, "Sussurro: le voci possibili sono in ordine di tono e priorità: \(tutte.map(\.categoria))")
    }

    // MARK: - Voci chiuse

    private static func chiuse(_ controlla: (Bool, String) -> Void) {
        var c = cliente()
        c.consensi = Consensi()
        let aperta = SussurroVera.voci(fonte(c))
        let chiusa = SussurroVera.voci(fonte(c, chiuse: ["privacy"]))
        controlla(aperta.first?.chiave == "privacy" && chiusa.isEmpty, "Sussurro: una voce chiusa non torna")
        let elenco = [SussurroChiuso(clienteId: "prova", chiave: "privacy", chiusoIl: giorno(-2)),
                      SussurroChiuso(clienteId: "prova", chiave: "liquidita", chiusoIl: giorno(-10)),
                      SussurroChiuso(clienteId: "altro", chiave: "riesame-mai", chiusoIl: giorno(-1))]
        controlla(SussurroVera.chiuse(elenco, clienteId: "prova", oggi: oggi) == ["privacy"],
                  "Sussurro: le voci chiuse valgono una settimana e solo per il loro cliente")
        let dati = try? JSONEncoder().encode(elenco)
        let letto = dati.flatMap { try? JSONDecoder().decode([SussurroChiuso].self, from: $0) }
        controlla(letto == elenco, "Sussurro: le voci chiuse si salvano e si rileggono (Codable)")
        let voce = aperta.first
        let rilette = (try? JSONEncoder().encode(aperta)).flatMap { try? JSONDecoder().decode([VoceSussurro].self, from: $0) }
        controlla(voce != nil && rilette == aperta, "Sussurro: le voci si salvano e si rileggono (Codable)")
    }

    // MARK: - Prima di agire, conferma

    private static func conferma(_ controlla: (Bool, String) -> Void) {
        var c = cliente()
        var conf = ConformitaCliente()
        conf.documento = DocumentoIdentita(tipo: .cartaIdentita, scadenza: giorno(71))
        c.conformita = conf
        guard let voce = SussurroVera.voci(fonte(c)).first else {
            controlla(false, "Sussurro: manca la voce del documento")
            return
        }
        let azione = SussurroVera.conferma(voce, cliente: c, oggi: oggi)
        controlla(azione?.strumento == RegistroStrumenti.attivitaNuova && azione?.app == .attivita && azione?.argomenti["cliente"] == "prova"
                  && azione?.argomenti["titolo"] == "Chiedere a Sofia la copia del nuovo documento d'identità"
                  && azione?.argomenti["scadenza"] == RegistroStrumenti.isoData(cal.startOfDay(for: giorno(71))),
                  "Sussurro: «Chiedi la copia» diventa un'attività da confermare, non si esegue da sola: \(azione?.dettaglio ?? "nessuna")")
        let voceP = SussurroVera.voci(fonte(promesse: [promessa("p", "Richiamare Sofia", scadenza: giorno(1))])).first
        controlla(voceP.map { SussurroVera.conferma($0, cliente: c, oggi: oggi) == nil } == true && voceP?.azione.cambia == false,
                  "Sussurro: «Apri la promessa» porta solo alla promessa, senza scheda di conferma")
        var vecchia = voce
        vecchia.azione.entro = giorno(-20)
        controlla(SussurroVera.conferma(vecchia, cliente: c, oggi: oggi)?.argomenti["scadenza"] == RegistroStrumenti.isoData(cal.startOfDay(for: oggi)),
                  "Sussurro: un'attività non nasce mai già scaduta")
    }

    // MARK: - I clienti del template

    private static func template(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        let dati = s.dati.istantanea
        var ok = !dati.clienti.isEmpty
        var dettaglio: [String] = []
        for c in dati.clienti {
            let uno = SussurroVera.voci(dati: dati, clienteId: c.id, ricordi: [], oggi: oggi)
            let due = SussurroVera.voci(dati: dati, clienteId: c.id, ricordi: [], oggi: oggi)
            let unici = Set(uno.map(\.chiave)).count == uno.count
            if uno.count > RegoleSussurro.massimoVoci || !unici || uno != due || uno.contains(where: { $0.clienteId != c.id }) { ok = false }
            dettaglio.append("\(c.id): \(uno.count)")
        }
        controlla(ok, "Sussurro: per i clienti del template al massimo tre voci, senza doppioni, sempre uguali (\(dettaglio.joined(separator: ", ")))")
        controlla(SussurroVera.voci(dati: dati, clienteId: "nessuno", ricordi: [], oggi: oggi).isEmpty, "Sussurro: un cliente che non c'è non ha voci")
    }
}
