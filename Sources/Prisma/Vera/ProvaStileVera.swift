import Foundation

/// Prova di «Scrive come te» (Vera/BRIEF.md, funzione 15) dentro `Prisma --prova-vera`: il profilo imparato solo dai
/// messaggi aperti (tu o Lei con la soglia d'età e le eccezioni, frasi, righe, giorno e ora, firma, saluti, formule,
/// emoji), niente regole con pochi messaggi, le regole scritte dal consulente che restano, la verifica di una bozza,
/// i ritocchi del codice, le istruzioni da accodare a MessaggiVera e la lettura tollerante. Deterministica: il giorno
/// è fisso, niente rete, niente Qwen.
enum ProvaStileVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let oggi = giorno(2026, 11, 8)
        let clienti = esempioClienti()
        let messaggi = esempioMessaggi()
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let giulia = perId["giulia"], anna = perId["anna"], laura = perId["laura"], elisa = perId["elisa"]

        pacchetto(controlla)
        lettura(controlla, giulia: giulia)

        // MARK: Imparare
        let p = StileVera.impara(messaggi: messaggi, clienti: clienti, oggi: oggi)
        controlla(p.messaggiLetti == 4 && p.mailLette == 6, "Stile: impara solo dai messaggi aperti in Mail o in Messaggi (\(p.messaggiLetti) + \(p.mailLette))")
        controlla(StileVera.intestazione(p).hasPrefix("Imparato da 4 messaggi e 6 email"), "Stile: l'intestazione dice da quanti messaggi: \(StileVera.intestazione(p))")
        let c = p.cortesia?.valore
        controlla(c?.sogliaEta == 40 && c?.predefinita == .lei, "Stile: tu sotto i 40 anni, Lei agli altri (soglia \(String(describing: c?.sogliaEta)))")
        controlla(c?.perCliente == ["anna": .lei], "Stile: Anna ha 30 anni ma riceve sempre il Lei: è un'eccezione (\(String(describing: c?.perCliente)))")
        controlla(p.cortesia?.messaggi == 10 && p.cortesia?.origine == .imparata, "Stile: la regola del tu o Lei è imparata da 10 messaggi")
        controlla(p.lunghezzaFrasi?.valore == 11, "Stile: frasi al massimo di 11 parole (\(String(describing: p.lunghezzaFrasi?.valore)))")
        controlla(p.unaCosaPerRiga?.valore == true && p.primaGiornoEOra?.valore == true, "Stile: una cosa per riga e prima il giorno e l'ora")
        controlla(p.firma?.valore == "Denis", "Stile: la firma «Denis» (la bozza firmata in altro modo non conta)")
        controlla(p.chiusure?.valore == ["A presto!"], "Stile: la chiusura tipica «A presto!»")
        let ap = p.aperture?.valore ?? []
        controlla(Set(ap) == ["Ciao ‹nome›,", "Buongiorno ‹nome›,", "Gentile ‹nome›,"], "Stile: i saluti d'apertura con il segnaposto del nome: \(ap)")
        controlla(p.emoji?.valore == .soloClientiNoti, "Stile: le emoji solo con i clienti già noti")
        let vietate = p.formuleVietate?.valore ?? []
        controlla(vietate.contains("con la presente") && vietate.contains("cordiali saluti"), "Stile: le formule da ufficio mai usate sono vietate (la bozza con «con la presente» non conta)")

        // Niente invenzioni con pochi messaggi
        let pochi = StileVera.impara(messaggi: Array(messaggi.prefix(2)), clienti: clienti, oggi: oggi)
        controlla(pochi.vuoto, "Stile: con due messaggi nessuna regola imparata")

        // MARK: Il profilo da mostrare
        let voci = StileVera.voci(p, clienti: clienti)
        let cortesia = voci.first { $0.id == .cortesia }
        controlla(cortesia?.testo == "Dai del tu ai clienti sotto i 40 anni, del Lei agli altri" && cortesia?.provenienza == "imparata da 10 messaggi",
                  "Stile: la voce del tu o Lei si legge come nel template: \(cortesia?.testo ?? "")")
        controlla(cortesia?.dettaglio?.contains("del Lei a Anna Galli") == true, "Stile: le eccezioni hanno il nome del cliente")
        controlla(voci.contains { $0.testo == "Mai emoji con i clienti nuovi" } && voci.contains { $0.testo == "Firmi «Denis»" }, "Stile: le voci di emoji e firma")
        controlla(voci.count == ChiaveRegolaStile.allCases.count, "Stile: tutte le regole hanno la loro voce (\(voci.count))")

        // MARK: Verificare
        let pulita = "Ciao Giulia,\nci vediamo martedì 17 alle 15 in studio.\nPorta il documento d'identità.\nA presto!\nDenis"
        let vPulita = StileVera.verifica(pulita, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false)
        controlla(vPulita.isEmpty, "Stile: una bozza nello stile non viola niente: \(vPulita.map(\.spiegazione))")
        let generica = "Gentile Sig.ra Rossi,\ncon la presente Le ricordiamo l'appuntamento fissato per giovedì 5 novembre alle ore 16:00 presso il nostro ufficio, finalizzato alla sottoscrizione del piano.\nLa preghiamo di presentarsi munita di un documento di identità in corso di validità.\nRestiamo a disposizione per qualsiasi chiarimento.\nCordiali saluti."
        let vGen = StileVera.verifica(generica, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false)
        let regole = Set(vGen.map(\.regola))
        controlla(regole.isSuperset(of: [.cortesia, .formuleVietate, .firma, .lunghezzaFrasi, .aperture, .chiusure]),
                  "Stile: la bozza generica viola tu o Lei, formule, firma, frasi, saluti: \(vGen.map(\.regola.rawValue))")
        controlla(StileVera.motivoScarto(vGen)?.contains("Dai del tu a Giulia") == true, "Stile: la prima violazione grave è il motivo per scartare il testo")
        controlla(StileVera.motivoScarto(vPulita) == nil, "Stile: niente motivo di scarto per la bozza nello stile")
        let vAnna = StileVera.verifica("Ciao Anna,\nvenerdì 20 alle 9 ti aspetto in studio.\nA presto!\nDenis", profilo: p, cliente: anna, oggi: oggi, clienteNuovo: false)
        controlla(vAnna.contains { $0.regola == .cortesia && $0.grave }, "Stile: ad Anna il tu è sbagliato anche se ha meno di 40 anni")
        let conEmoji = "Ciao Elisa,\nci vediamo martedì 17 alle 15 in studio.\nPorta il documento d'identità 🙂\nA presto!\nDenis"
        controlla(StileVera.verifica(conEmoji, profilo: p, cliente: elisa, oggi: oggi, clienteNuovo: true).contains { $0.regola == .emoji && $0.grave },
                  "Stile: le emoji con un cliente nuovo sono una violazione grave")
        controlla(!StileVera.verifica(conEmoji, profilo: p, cliente: elisa, oggi: oggi, clienteNuovo: false).contains { $0.regola == .emoji },
                  "Stile: con un cliente noto le emoji vanno bene")
        controlla(StileVera.clienteNuovo("elisa", messaggi: messaggi) && !StileVera.clienteNuovo("giulia", messaggi: messaggi),
                  "Stile: nuovo è il cliente a cui non è uscito ancora nessun messaggio")

        // MARK: I ritocchi del codice
        let ritoccata = StileVera.applica(generica, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false)
        let t = ritoccata.testo
        controlla(t.hasPrefix("Ciao Giulia,\n") && t.hasSuffix("\nA presto!\nDenis"), "Stile: saluto, chiusura e firma del profilo: \(t)")
        controlla(!t.contains("Restiamo a disposizione") && !t.lowercased().contains("con la presente") && t.contains("\nLe ricordiamo l'appuntamento"),
                  "Stile: tolte le formule che si tolgono da sole, il resto delle parole resta")
        controlla(CommentoVera.numeriConservati(bozza: generica, testo: t), "Stile: i ritocchi non aggiungono cifre")
        let dopo = Set(StileVera.verifica(t, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false).map(\.regola))
        controlla(!dopo.contains(.firma) && !dopo.contains(.aperture) && !dopo.contains(.chiusure) && dopo.contains(.cortesia),
                  "Stile: dopo i ritocchi restano solo le regole che il codice non corregge (il Lei del corpo): \(dopo.map(\.rawValue))")
        let dueFrasi = "Ciao Giulia,\nCi vediamo martedì 17 alle 15. Porta la carta d'identità.\nA presto!\nDenis"
        controlla(StileVera.verifica(dueFrasi, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false).contains { $0.regola == .unaCosaPerRiga },
                  "Stile: due frasi sulla stessa riga violano «una cosa per riga»")
        let divisa = StileVera.applica(dueFrasi, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false)
        controlla(divisa.testo == "Ciao Giulia,\nCi vediamo martedì 17 alle 15.\nPorta la carta d'identità.\nA presto!\nDenis", "Stile: il codice manda a capo ogni frase: \(divisa.testo)")
        let senza = StileVera.applica(conEmoji, profilo: p, cliente: elisa, oggi: oggi, clienteNuovo: true)
        controlla(!StileVera.haEmoji(senza.testo) && senza.testo.contains("Porta il documento d'identità\n"), "Stile: via le emoji per un cliente nuovo: \(senza.testo)")
        controlla(StileVera.applica(pulita, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false) == BozzaInStile(testo: pulita, modifiche: []),
                  "Stile: una bozza già nello stile resta com'è")

        // L'ultima riga del corpo non è una firma solo perché è breve e maiuscola: «Fammi sapere» resta, la firma si aggiunge
        let senzaFirma = "Ciao Giulia,\nci vediamo giovedì 19 alle 16.\nFammi sapere"
        let firmata = StileVera.applica(senzaFirma, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false)
        controlla(firmata.testo == "Ciao Giulia,\nci vediamo giovedì 19 alle 16.\nFammi sapere\nDenis",
                  "Stile: «Fammi sapere» non è la firma, resta nel testo e la firma va in fondo: \(firmata.testo)")
        controlla(StileVera.struttura(senzaFirma).firma == nil && StileVera.struttura("Ciao Giulia,\nA giovedì.\nDenis V", firme: ["Denis V"]).firma == "Denis V",
                  "Stile: firma solo una riga che somiglia a un nome o la firma del profilo")

        // Gli auguri in fondo non sono una firma: «Buone Feste» resta e la firma del profilo va sotto
        let auguri = "Ciao Marco,\nti mando la proposta per la pensione.\nBuone Feste"
        controlla(StileVera.struttura(auguri, firme: ["Denis"]).firma == nil, "Stile: «Buone Feste» non è una firma")
        let conAuguri = StileVera.applica(auguri, profilo: p, cliente: perId["marco"], oggi: oggi, clienteNuovo: false)
        controlla(conAuguri.testo == auguri + "\nDenis", "Stile: gli auguri restano e la firma si aggiunge sotto: \(conAuguri.testo)")

        // MARK: Le istruzioni per Qwen
        let iGiulia = StileVera.istruzioni(p, cliente: giulia, oggi: oggi, clienteNuovo: false)
        controlla(iGiulia.contains("STILE DEL CONSULENTE") && iGiulia.contains("Dai del tu a Giulia") && iGiulia.contains("«con la presente»")
                  && iGiulia.contains("Apri con «Ciao Giulia,»") && !iGiulia.contains("Niente emoji") && !iGiulia.contains("Denis"),
                  "Stile: le istruzioni per Giulia (tu, formule, saluto; la firma la mette Prisma)")
        controlla(StileVera.istruzioni(p, cliente: elisa, oggi: oggi, clienteNuovo: true).contains("Niente emoji"), "Stile: niente emoji con un cliente nuovo")
        let iAnna = StileVera.istruzioni(p, cliente: anna, oggi: oggi, clienteNuovo: false)
        controlla(iAnna.contains("Dai del Lei a Anna") && iAnna.contains("Apri con «Gentile Anna,»"), "Stile: le istruzioni per Anna dicono il Lei")
        let base = [MessaggioModello(ruolo: .sistema, testo: "BASE"), MessaggioModello(ruolo: .utente, testo: "SCHEDA")]
        let conStile = StileVera.conStile(base, profilo: p, cliente: giulia, oggi: oggi, clienteNuovo: false)
        controlla(conStile.count == 2 && conStile[0].testo.hasPrefix("BASE\n\n") && conStile[0].testo.contains("Dai del tu") && conStile[1].testo == "SCHEDA",
                  "Stile: lo stile si accoda alle istruzioni di sistema, la scheda resta com'è")
        controlla(StileVera.conStile(base, profilo: ProfiloStile(), cliente: giulia, oggi: oggi, clienteNuovo: false) == base,
                  "Stile: senza profilo i messaggi per Qwen non cambiano")
        controlla(StileVera.tono(p, cliente: laura, oggi: oggi, richiesto: .cordiale) == .formale
                  && StileVera.tono(p, cliente: giulia, oggi: oggi, richiesto: .formale) == .cordiale
                  && StileVera.tono(p, cliente: giulia, oggi: oggi, richiesto: .breve) == .breve
                  && StileVera.tono(ProfiloStile(), cliente: laura, oggi: oggi, richiesto: .cordiale) == .cordiale,
                  "Stile: il tono passato a MessaggiVera segue il tu o Lei del profilo")
        controlla(StileVera.firma(p) == "Denis", "Stile: la firma del profilo per MessaggiVera")

        // Un soprannome («Ciao Giuly,» scritto solo a Giulia) non diventa il saluto di tutti
        let giuly = (1...5).map { i in
            messaggio("giulia", "Ciao Giuly,\nmartedì \(i + 2) alle 16 ci sentiamo per il piano.\nA presto!\nDenis", .messaggi, il: giorno(2026, 10, 12 + i))
        }
        let conSoprannome = StileVera.impara(messaggi: messaggi + giuly, clienti: clienti, oggi: oggi)
        controlla(!(conSoprannome.aperture?.valore ?? []).contains { $0.contains("Giuly") }
                  && conSoprannome.aperture?.valore.contains("Ciao ‹nome›,") == true,
                  "Stile: il saluto con un soprannome non entra nel profilo: \(conSoprannome.aperture?.valore ?? [])")
        controlla(!StileVera.istruzioni(conSoprannome, cliente: perId["marco"], oggi: oggi, clienteNuovo: false).contains("Giuly"),
                  "Stile: a Marco Vera non propone il soprannome di Giulia")

        // MARK: Le scelte del consulente restano
        var mio = p
        mio.firma?.scrivi("Denis V.")
        mio.imposta(.emoji, attiva: false)
        let rifatto = StileVera.aggiorna(mio, messaggi: messaggi, clienti: clienti, oggi: oggi)
        controlla(rifatto.firma?.valore == "Denis V." && rifatto.firma?.origine == .scritta && rifatto.firma?.provenienza == "scritta da te",
                  "Stile: la firma scritta dal consulente resta dopo un nuovo apprendimento")
        controlla(rifatto.emoji?.attiva == false && rifatto.cortesia?.attiva == true, "Stile: la regola spenta resta spenta, le altre accese")
        controlla(!StileVera.istruzioni(rifatto, cliente: elisa, oggi: oggi, clienteNuovo: true).contains("Niente emoji"), "Stile: una regola spenta non va a Qwen")
        let ridotto = StileVera.aggiorna(mio, messaggi: Array(messaggi.prefix(2)), clienti: clienti, oggi: oggi)
        controlla(ridotto.cortesia == nil && ridotto.firma?.valore == "Denis V.", "Stile: senza prove le regole imparate escono, quelle scritte restano")

        // MARK: Archivio
        let dati = try? JSONEncoder().encode(rifatto)
        let letto = dati.flatMap { try? JSONDecoder().decode(ProfiloStile.self, from: $0) }
        controlla(letto == rifatto, "Stile: il profilo torna identico dall'archivio")
    }

    // MARK: - Pacchetto e lettura

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let t = IstruzioniVera.testo("stile") ?? ""
        controlla(t.contains("STILE DEL CONSULENTE") && t.contains("firma"), "Stile: istruzioni «stile» nel pacchetto (Vera/Istruzioni/stile.md)")
    }

    private static func lettura(_ controlla: (Bool, String) -> Void, giulia: Cliente?) {
        controlla(StileVera.allocuzione(di: "Ciao Marco, ti scrivo per l'incontro.") == .tu, "Stile: «Ciao… ti scrivo» dà del tu")
        controlla(StileVera.allocuzione(di: "Gentile signora, Le scrivo perché può già firmare.") == .lei, "Stile: «Gentile… Le scrivo… può» dà del Lei")
        controlla(StileVera.allocuzione(di: "Ci vediamo giovedì.") == nil, "Stile: una frase senza tu né Lei non decide")
        // «può» e «potrebbe» con un soggetto davanti sono terze persone, non il Lei
        let terza = "Ciao Marco,\nla rata può scendere e il conto potrebbe rendere di più."
        controlla(StileVera.allocuzione(di: terza) == .tu, "Stile: «la rata può… il conto potrebbe…» non è il Lei")
        controlla(StileVera.allocuzione(di: "Buongiorno Laura,\nPuò portare il contratto?") == .lei, "Stile: «Può portare…» a inizio frase è il Lei")
        // «le invio», «la mando» minuscoli sono pronomi oggetto, non il Lei
        let oggetto = "Ciao Marco,\nho preparato le simulazioni: le invio stasera e la proposta la mando domani."
        controlla(StileVera.allocuzione(di: oggetto) == .tu, "Stile: «le invio… la mando» col tu non è il Lei")
        controlla(StileVera.allocuzione(di: "Buongiorno Laura,\nLa aspetto giovedì alle 9.") == .lei, "Stile: «La aspetto» a inizio frase resta il Lei")
        let s = StileVera.struttura("Ciao Giulia, ci vediamo giovedì alle 16.\nPorta la carta d'identità.\nA giovedì!\nDenis Vicenzoni · Consulenza finanziaria")
        controlla(s.apertura == "Ciao Giulia," && s.corpo.count == 2 && s.chiusura == "A giovedì!" && s.firma == "Denis Vicenzoni · Consulenza finanziaria",
                  "Stile: saluto sulla prima riga, corpo, chiusura e firma: \(s)")
        controlla(StileVera.modelloSaluto("Ciao Giulia,", cliente: giulia) == "Ciao ‹nome›," && StileVera.modelloSaluto("Gentile Giulia Rossi,", cliente: giulia) == "Gentile ‹nome› ‹cognome›,"
                  && StileVera.compila("Gentile Sig.ra ‹cognome›,", cliente: giulia) == "Gentile Sig.ra Rossi,",
                  "Stile: il nome del cliente diventa il segnaposto")
        // I saluti generici senza nome non nascondono un soprannome: si possono imparare
        controlla(!StileVera.restaUnNome("Gentile Cliente,") && !StileVera.restaUnNome("Gentili Signori,") && !StileVera.restaUnNome("Gent.mi Clienti,")
                  && !StileVera.restaUnNome("Cari Tutti,") && StileVera.restaUnNome("Ciao Giuly,"),
                  "Stile: «Gentile Cliente,» e «Gentili Signori,» non sono soprannomi, «Ciao Giuly,» sì")
        controlla(StileVera.frasi("Ci vediamo alle 16.00 dalla Sig.ra Rossi. Porta il contratto.").count == 2, "Stile: le frasi non si spezzano su «16.00» e «Sig.ra»")
        // Lettura tollerante: valore mancante o sbagliato → la regola si salta; il resto torna al predefinito
        let json = #"{"firma":{"valore":"Denis"},"emoji":{"valore":"boh"},"lunghezzaFrasi":{"valore":1},"cortesia":{"valore":{"predefinita":"tu","sogliaEta":3}}}"#
        let p = (try? JSONDecoder().decode(ProfiloStile.self, from: Data(json.utf8))) ?? ProfiloStile()
        controlla(p.firma?.valore == "Denis" && p.firma?.attiva == true && p.firma?.origine == .scritta && p.emoji == nil && p.lunghezzaFrasi == nil,
                  "Stile: lettura tollerante del profilo (una regola illeggibile si salta)")
        controlla(p.cortesia?.valore.predefinita == .tu && p.cortesia?.valore.sogliaEta == nil && p.cortesia?.valore.perCliente.isEmpty == true,
                  "Stile: una soglia d'età impossibile si scarta")
    }

    // MARK: - Dati di prova

    private static func giorno(_ a: Int, _ m: Int, _ g: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: a, month: m, day: g, hour: 12)) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    private static func cliente(_ id: String, _ nome: String, nato: Date) -> Cliente {
        var c = Cliente(id: id, nome: nome, iniziali: Cliente.iniziali(di: nome), tinta: .blu, tema: "", email: "", telefono: "",
                        preferito: false, nota: "", creatoIl: giorno(2025, 1, 10))
        c.dataNascita = nato
        return c
    }

    private static func esempioClienti() -> [Cliente] {
        [cliente("giulia", "Giulia Rossi", nato: giorno(1995, 3, 1)),
         cliente("marco", "Marco Bianchi", nato: giorno(1990, 5, 10)),
         cliente("laura", "Laura Verdi", nato: giorno(1970, 2, 2)),
         cliente("piero", "Piero Neri", nato: giorno(1960, 7, 7)),
         cliente("anna", "Anna Galli", nato: giorno(1996, 4, 4)),
         cliente("elisa", "Elisa Conti", nato: giorno(2000, 1, 1))]
    }

    private static func messaggio(_ cliente: String, _ testo: String, _ canale: CanaleMessaggio, il g: Date,
                                  stato: StatoMessaggio = .apertoInMail) -> MessaggioCliente {
        var m = MessaggioCliente(clienteId: cliente, occasioneId: "prova-\(cliente)-\(g.timeIntervalSinceReferenceDate)",
                                 origine: OrigineMessaggio(tipo: .richiestaVera, riferimento: "prova"), canaleLavoro: .indipendente,
                                 tono: .cordiale, canale: canale, oggetto: canale == .mail ? "Prova" : nil, testo: testo, cifre: [],
                                 autore: .vera, modello: nil, creatoIl: g)
        m.stato = stato == .apertoInMail && canale == .messaggi ? .apertoInMessaggi : stato
        if m.stato != .bozza && m.stato != .salvato { m.apertoIl = g }
        return m
    }

    /// Dieci messaggi aperti (tu per Giulia e Marco, Lei per Laura, Piero e Anna; un'emoji solo nel secondo a Giulia),
    /// più una bozza e un salvato che non contano.
    private static func esempioMessaggi() -> [MessaggioCliente] {
        func tu(_ nome: String, _ giorno: String) -> String {
            "Ciao \(nome),\nci vediamo \(giorno) alle 16 in studio.\nPorta solo la carta d'identità.\nSe hai dubbi scrivimi.\nA presto!\nDenis"
        }
        func lei(_ saluto: String, _ nome: String, _ giorno: String) -> String {
            saluto == "Gentile"
                ? "Gentile \(nome),\n\(giorno) alle 9 La aspetto in studio.\nPuò portare il contratto?\nA presto!\nDenis"
                : "\(saluto) \(nome),\n\(giorno) alle 11 in studio, La aspetto per la firma.\nPuò portare la carta d'identità?\nA presto!\nDenis"
        }
        return [
            messaggio("giulia", tu("Giulia", "giovedì 15"), .messaggi, il: giorno(2026, 10, 1)),
            messaggio("laura", lei("Buongiorno", "Laura", "giovedì 22"), .mail, il: giorno(2026, 10, 2)),
            messaggio("marco", tu("Marco", "venerdì 16"), .messaggi, il: giorno(2026, 10, 3)),
            messaggio("piero", lei("Buongiorno", "Piero", "martedì 20"), .mail, il: giorno(2026, 10, 4)),
            messaggio("anna", lei("Gentile", "Anna", "venerdì 23"), .mail, il: giorno(2026, 10, 5)),
            messaggio("giulia", "Ciao Giulia,\nlunedì 26 alle 10 ti chiamo per il preventivo.\nTieni a portata di mano la polizza 🙂\nA presto!\nDenis",
                      .messaggi, il: giorno(2026, 10, 6)),
            messaggio("marco", tu("Marco", "sabato 24"), .messaggi, il: giorno(2026, 10, 7)),
            messaggio("laura", lei("Buongiorno", "Laura", "mercoledì 28"), .mail, il: giorno(2026, 10, 8)),
            messaggio("piero", lei("Buongiorno", "Piero", "giovedì 29"), .mail, il: giorno(2026, 10, 9)),
            messaggio("anna", lei("Gentile", "Anna", "venerdì 30"), .mail, il: giorno(2026, 10, 10)),
            messaggio("giulia", "Gentile Giulia,\ncon la presente Le comunico la data.\nCordiali saluti.\nDott. Vicenzoni", .mail, il: giorno(2026, 10, 11), stato: .bozza),
            messaggio("laura", "Gentile Laura,\ncon la presente Le invio il documento.\nDistinti saluti.\nStudio Vicenzoni", .mail, il: giorno(2026, 10, 12), stato: .salvato),
        ]
    }
}
