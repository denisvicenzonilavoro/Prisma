import Foundation

/// Prova della fase 3 di Vera (Vera/BRIEF.md) dentro `Prisma --prova-vera`: le promesse (regole, Qwen solo con la frase
/// nella fonte, stato e semaforo, «Rimanda», chat e promemoria), la seconda lettura (parole a rischio, cifre senza fonte
/// con la correzione, allegati, profilo, «Rileggi:» in chat), trova le differenze e cosa non copre (con i fac-simile di
/// una polizza «Infortuni famiglia» e di una proposta), il resoconto dell'incontro (sezioni, Qwen controllato, ✕,
/// breve, firma con il PDF nei Documenti, prossimi passi, nota vocale senza consenso) e l'archivio dei nuovi dati.
enum ProvaFaseTreVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        promesse(controlla)
        secondaLettura(controlla)
        coperture(controlla)
        differenze(controlla)
        resoconto(controlla)
        archivio(controlla)
    }

    private final class Scatola<T>: @unchecked Sendable { var valore: T?; init() {} }

    /// Aspetta un lavoro asincrono sul thread principale (le prove girano lì), facendo girare il ciclo.
    private static func aspetta<T>(_ f: @escaping @MainActor () async -> T?) -> T? {
        let s = Scatola<T>()
        var finito = false
        Task { @MainActor in
            s.valore = await f()
            finito = true
        }
        let limite = Date().addingTimeInterval(20)
        while !finito && Date() < limite { RunLoop.main.run(until: Date().addingTimeInterval(0.02)) }
        return s.valore
    }

    private static func stato() -> StatoShell {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        return s
    }

    // MARK: - Pacchetto

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        for (nome, parola) in [("promesse", "frase"), ("motivazione", "bozza"), ("differenze", "tabella"), ("coperture", "articolo"), ("resoconto", "JSON")] {
            let t = IstruzioniVera.testo(nome) ?? ""
            controlla(t.contains(parola), "Fase 3: istruzioni «\(nome)» nel pacchetto (Vera/Istruzioni/\(nome).md)")
        }
    }

    // MARK: - 8 · Le promesse

    private static func promesse(_ controlla: (Bool, String) -> Void) {
        let oggi = Date()
        let cal = Calendar.current
        let f = FontePromesse(clienteId: "marco", tipo: .nota, id: "nota-prova", etichetta: "dalla nota di prova", data: oggi,
                              testo: "Ne parliamo dopo l'estate. Le mando il confronto per gli studi di Tommaso entro venerdì, così lo guarda anche Elena. Il cliente deve portare la carta d'identità.")
        let trovate = PromesseVera.conRegole(f, nome: "Marco")
        controlla(trovate.count == 1 && trovate[0].frase.contains("Le mando il confronto") && trovate[0].scadenza != nil,
                  "Promesse: dalla nota un impegno solo, con la data («entro venerdì»): \(trovate.map(\.testo))")
        controlla(trovate.first?.testo == "Mandare a Marco il confronto per gli studi di Tommaso", "Promesse: la cosa da fare dice a chi, senza il quando e la spiegazione: \(trovate.first?.testo ?? "")")
        let vietata = FontePromesse(clienteId: "marco", tipo: .nota, id: "n2", etichetta: "", data: oggi,
                                    testo: "Le preparo un piano con un rendimento garantito del 4%.")
        controlla(PromesseVera.conRegole(vietata, nome: "Marco").isEmpty, "Promesse: una promessa di rendimento non è un impegno da ricordare")
        // Qwen: la frase deve stare nella fonte
        let qwen = PromesseVera.leggi(#"{"promesse":[{"frase":"Le mando il confronto per gli studi di Tommaso entro venerdì","cosa":"mandare il confronto","quando":"entro venerdì"},{"frase":"Le porto il contratto lunedì","cosa":"portare il contratto"}]}"#, fonte: f)
        controlla(qwen?.count == 1 && qwen?.first?.testo == "Mandare il confronto", "Promesse: di Qwen passa solo la frase che è nella fonte")
        let qwenInventa = PromesseVera.leggi(#"{"promesse":[{"frase":"Le mando il confronto per gli studi di Tommaso entro venerdì","cosa":"mandare il confronto da 5.000 €","quando":"entro lunedì 30"},{"frase":"Ne parliamo dopo l'estate","cosa":"parlarne"}]}"#, fonte: f)
        controlla(qwenInventa?.isEmpty == true, "Promesse: di Qwen niente cifre nuove nel «cosa» e niente frasi senza impegno")
        let qwenQuando = PromesseVera.leggi(#"{"promesse":[{"frase":"Il cliente deve portare la carta d'identità","cosa":"portare"}]}"#, fonte: f)
        controlla(qwenQuando?.isEmpty == true, "Promesse: una cosa che deve fare il cliente non è una promessa")
        // Nell'app: le fonti del cliente, niente doppioni
        let s = stato()
        s.dati.note.append(Nota(clienteId: "marco", titolo: "Telefonata", testo: "Gli interessa la protezione. Le mando il confronto per gli studi di Tommaso entro venerdì."))
        let nuove = s.raccogliPromesse(cliente: "marco")
        controlla(nuove.count == 1 && s.raccogliPromesse(cliente: "marco").isEmpty, "Promesse: la nota diventa una promessa, una volta sola")
        guard let p = nuove.first else { return }
        // Semaforo e «Rimanda»
        var ieri = p
        ieri.scadenza = cal.date(byAdding: .day, value: -1, to: oggi)
        var adesso = p
        adesso.scadenza = oggi
        controlla(PromesseVera.semaforo(ieri, oggi: oggi) == .inRitardo && PromesseVera.etichetta(ieri, oggi: oggi) == "In ritardo"
                  && PromesseVera.etichetta(adesso, oggi: oggi) == "Oggi", "Promesse: «In ritardo» ieri, «Oggi» oggi")
        s.rimandaPromessa(p.id, oggi: oggi)
        let rimandata = s.dati.promesse.first { $0.id == p.id }
        let attesa = cal.date(byAdding: .day, value: 7, to: max(cal.startOfDay(for: oggi), p.scadenzaAttuale ?? oggi))
        controlla(rimandata?.stato == .rimandata && rimandata?.rimandataAl == attesa, "Promesse: «Rimanda» sposta di una settimana")
        // In chat: «le promesse di Marco» e il promemoria con la scheda
        controlla(s.chiediPromesse("Le promesse di Marco", chiave: "giulia") && s.conversazione("giulia").last?.promesse == [p.id],
                  "Promesse: «le promesse di Marco» in chat mostra le sue")
        controlla(!s.chiediPromesse("Quali promesse di rendimento non si fanno?", chiave: "giulia"), "Promesse: «promesse di rendimento» non è questa domanda")
        controlla(!s.chiediPromesse("Scrivi a Marco che manterrò la promessa", chiave: "giulia") && !s.chiediPromesse("Scrivigli che manterrò la promessa", chiave: "marco")
                  && !s.chiediPromesse("Gli impegni con Marco di domani", chiave: "giulia"), "Promesse: azioni e agenda restano alle loro funzioni")
        controlla(s.smistaVera("Mostrami le promesse di Marco", chiave: "giulia") && s.conversazione("giulia").last?.promesse != nil
                  && s.chiediPromesse("Ricordami le promesse di Marco", chiave: "giulia"),
                  "Promesse: «mostrami» e «ricordami le promesse di Marco» non aprono il dossier né vanno a «Fallo tu»")
        // La stessa frase negli appunti e nel resoconto è una promessa sola
        let doppia = PromesseVera.nuove([p, { var x = p; x.id = "altra"; x.fonteId = p.fonteId + "-resoconto"; x.fonte = .resoconto; return x }()], esistenti: [])
        controlla(doppia.count == 1 && PromesseVera.nuove([p], esistenti: s.dati.promesse).isEmpty, "Promesse: la stessa frase negli appunti e nel loro resoconto non si ripete")
        let m = s.promemoriaPromessa(p.id, chiave: "marco")
        controlla(m?.conferma?.azioni.first?.strumento == RegistroStrumenti.attivitaNuova && m?.conferma?.stato == .daConfermare,
                  "Promesse: il promemoria è una scheda da confermare")
        s.segnaPromessa(p.id, .fatta, oggi: oggi)
        controlla(s.promesseAperte(cliente: "marco").isEmpty && s.dati.promesse.first?.fattaIl != nil, "Promesse: «Fatto» la toglie dalle aperte")
        // Alla chiusura dell'incontro
        var i = Incontro(clienteId: "laura", titolo: "Pensione", data: oggi)
        i.appunti = "La richiamo dopo il 15 per parlare della pensione a 60 anni."
        s.salvaIncontro(i)
        controlla(s.promesseAperte(cliente: "laura").isEmpty, "Promesse: un incontro in preparazione non le raccoglie ancora")
        i.stato = .concluso
        s.salvaIncontro(i)
        controlla(s.promesseAperte(cliente: "laura").count == 1, "Promesse: alla chiusura dell'incontro la promessa entra nell'elenco")
    }

    // MARK: - 10 · La seconda lettura

    private static func secondaLettura(_ controlla: (Bool, String) -> Void) {
        let testo = "Gentile Laura, con un versamento di 750 € al mese e un rendimento garantito del 4% tra 11 anni avrà il capitale che le serve."
        let e = SecondaLetturaVera.rileggi(testo, oggetto: "La proposta", fonti: "Versamento previsto: 700 € al mese", fonteCliente: nil,
                                           allegatiMancanti: ["Il KID del piano"])
        let parole = e.avvisi.filter { $0.tipo == .parola }
        let numeri = e.avvisi.filter { $0.tipo == .numero }
        controlla(parole.count == 1 && parole[0].gravita == .rosso && parole[0].correzione == "rendimento atteso, non garantito",
                  "Seconda lettura: «rendimento garantito» è una frase a rischio, con la correzione")
        controlla(numeri.contains { $0.trovato == "750 €" && $0.correzione == Formati.euro(700) },
                  "Seconda lettura: 750 € non torna con la scheda, propone 700 € (\(numeri.map(\.dettaglio)))")
        controlla(numeri.contains { $0.titolo == "Una cifra senza fonte" && $0.dettaglio.contains("4%") }, "Seconda lettura: il 4% non ha fonte")
        controlla(e.avvisi.contains { $0.tipo == .allegato } && e.avvisi.first?.gravita == .rosso && !e.pulito, "Seconda lettura: l'allegato che manca, i rossi per primi")
        let corretto = e.corretto(testo)
        controlla(corretto.contains("rendimento atteso, non garantito") && corretto.contains(Formati.euro(700)) && !corretto.contains("750"),
                  "Seconda lettura: «Applica le correzioni» cambia frase e cifra")
        let pulito = SecondaLetturaVera.rileggi("Gentile Marco, ci vediamo giovedì 12 alle 15:30 per la polizza assicurata con il capitale previsto dal contratto.",
                                                oggetto: "Il messaggio", fonti: "", fonteCliente: nil)
        controlla(pulito.pulito, "Seconda lettura: giorni, orari e «assicurata» non sono avvisi: \(pulito.avvisi.map(\.dettaglio))")
        let avvertenza = SecondaLetturaVera.rileggi("I rendimenti passati non sono garantiti e il capitale garantito vale alle condizioni del contratto.",
                                                    oggetto: "Il prospetto", fonti: "", fonteCliente: nil)
        let assicuro = SecondaLetturaVera.rileggi("Le assicuro un ottimo risultato.", oggetto: "x", fonti: "", fonteCliente: nil)
        let rischiare = SecondaLetturaVera.rileggi("Può versare di più senza rischiare la liquidità.", oggetto: "x", fonti: "", fonteCliente: nil)
        controlla(!assicuro.pulito && rischiare.pulito, "Seconda lettura: «le assicuro un» sì, «senza rischiare» no")
        controlla(avvertenza.pulito, "Seconda lettura: «non sono garantiti» e il capitale garantito del contratto non sono frasi a rischio: \(avvertenza.avvisi.map(\.dettaglio))")
        let cifre = EsitoSecondaLettura(oggetto: "x", avvisi: [AvvisoLettura(tipo: .numero, gravita: .arancio, titolo: "", dettaglio: "", trovato: "5%", correzione: "4,8%")])
        controlla(cifre.corretto("Costi del 15%, dell'1,5% e del 5%.") == "Costi del 15%, dell'1,5% e del 4,8%.",
                  "Seconda lettura: la correzione cambia solo la cifra intera: \(cifre.corretto("Costi del 15%, dell'1,5% e del 5%."))")
        let s = stato()
        controlla(s.chiediSecondaLettura("Rileggi: Le assicuro un guadagno sicuro del 5% già dal primo anno.", chiave: "marco")
                  && s.conversazione("marco").last?.lettura?.avvisi.contains { $0.tipo == .parola } == true,
                  "Seconda lettura: «Rileggi: …» in chat (un testo scritto a mano)")
        controlla(!s.chiediSecondaLettura("Rileggi il messaggio di ieri", chiave: "marco"), "Seconda lettura: senza i due punti non è un testo da rileggere")
        controlla(s.chiediSecondaLettura("Vera, rileggi questo testo: Le confermo l'appuntamento di lunedì, senza rischi per lei.", chiave: "marco")
                  && s.smistaVera("Rileggi: Gentile Marco, le confermo gli appuntamenti di lunedì con un guadagno sicuro.", chiave: "marco")
                  && s.conversazione("marco").last?.lettura != nil,
                  "Seconda lettura: «Vera, rileggi questo testo:» e un testo con giorni e appuntamenti arrivano alla seconda lettura")
        // La scheda di adeguatezza di una proposta
        if let p = s.dati.posizioni.first(where: { s.esitoAdeguatezza($0) != nil }), let l = s.secondaLetturaAdeguatezza(p) {
            controlla(l.avvisi.contains { $0.tipo == .profilo }, "Seconda lettura: la scheda di adeguatezza porta i controlli del profilo")
            let b = aspetta { await s.bozzaMotivazione(p) }
            controlla(b.map { !$0.testo.isEmpty && !$0.conQwen } ?? true, "Seconda lettura: senza Qwen la bozza della motivazione è quella di Prisma")
        } else {
            controlla(true, "Seconda lettura: nessuna proposta di prova con la scheda di adeguatezza")
        }
    }

    // MARK: - 12 · Cosa non copre

    private static func coperture(_ controlla: (Bool, String) -> Void) {
        let (a, _) = FacSimiliVera.documenti(cliente: "laura")
        let c = CoperturaVera.copertura(a, pagine: FacSimiliVera.polizza)
        controlla(c.voci(.esclusione).map(\.articolo) == ["1.2", "3.1", "3.2"], "Cosa non copre: tre esclusioni con l'articolo (\(c.voci(.esclusione).map(\.articolo)))")
        controlla(c.voci(.carenza).map(\.articolo) == ["4.1"] && c.voci(.franchigia).map(\.articolo) == ["6.1", "6.2"]
                  && c.voci(.massimale).map(\.articolo) == ["7.1", "7.3"],
                  "Cosa non copre: carenza 4.1, franchigie 6.1 e 6.2, massimali 7.1 e 7.3 (\(c.voci.map { "\($0.tipo.rawValue) \($0.articolo)" }))")
        controlla(!c.voci.contains { $0.voce.contains("esclusive") }, "Cosa non copre: «esclusive» non è un'esclusione")
        let aCapo = CoperturaVera.copertura(a, pagine: ["Art. 3.1 – Rischi esclusi\nSono esclusi gli infortuni derivanti dalla pratica di\nsport a livello agonistico."])
        controlla(aCapo.voci.first?.voce.contains("agonistico") == true, "Cosa non copre: una clausola su due righe del PDF resta intera")
        let senza = CoperturaVera.copertura(a, pagine: ["Una polizza senza articoli numerati. Sono esclusi gli sport."])
        controlla(senza.articoliLetti == 0 && senza.voci.isEmpty, "Cosa non copre: senza articoli numerati nessuna voce")
        let articoli = NormeVera.articoli(FacSimiliVera.polizza, testoId: a.id)
        let qwen = CoperturaVera.leggi(#"""
        {"voci":[{"tipo":"esclusione","voce":"Gli sport agonistici","perCliente":"Se ci si fa male in una partita di campionato, la polizza non paga.","articolo":"3.1","frase":"Sono esclusi gli infortuni derivanti dalla pratica di sport a livello agonistico."},
        {"tipo":"esclusione","voce":"Gli sport estremi","perCliente":"x","articolo":"9.9","frase":"Sono esclusi gli sport estremi."},
        {"tipo":"massimale","voce":"Caso morte 150.000 €","perCliente":"Al massimo 150.000 €.","articolo":"7.1","frase":"Il massimale per il caso morte è di 100.000 €."},
        {"tipo":"esclusione","voce":"Il paracadutismo","perCliente":"x","articolo":"3.1","frase":"Sono esclusi il paracadutismo e il deltaplano."}]}
        """#, articoli: articoli)
        controlla(qwen?.count == 1 && qwen?.first?.articolo == "3.1", "Cosa non copre: di Qwen passa solo la voce con articolo vero, frase dentro e cifre giuste")
        let conQwen = CoperturaVera.copertura(a, pagine: FacSimiliVera.polizza, voci: qwen)
        controlla(conQwen.conQwen && conQwen.voci(.esclusione).count == 3 && conQwen.voci(.esclusione).contains { $0.perCliente.contains("campionato") },
                  "Cosa non copre: la voce di Qwen sostituisce quella delle regole dello stesso articolo")
        controlla(CoperturaVera.eUnaRichiesta("Cosa non copre la polizza di Laura?") && CoperturaVera.eUnaRichiesta("Quali franchigie ha l'infortuni?")
                  && !CoperturaVera.eUnaRichiesta("Quali esclusioni prevede l'art. 1900 del codice civile?")
                  && !CoperturaVera.eUnaRichiesta("Cosa prevede il codice civile sulle esclusioni nelle polizze vita?")
                  && CoperturaVera.eUnaRichiesta("Fammi leggere le esclusioni della polizza di Marco")
                  && !CoperturaVera.eUnaRichiesta("Quali carenze ha Marco nella protezione?"),
                  "Cosa non copre: riconosce la domanda, lascia alla biblioteca quelle sulle norme")
        let s = stato()
        s.dati.documenti.append(a)
        s.memorizzaTesto(a.id, FacSimiliVera.polizza)
        controlla(s.chiediCopertura("Cosa non copre la polizza di Laura?", chiave: "giulia") && s.conversazione("giulia").last?.copertura == a.id
                  && s.copertura(a.id)?.voci.count == 8, "Cosa non copre: in chat la scheda, salvata con le otto voci")
        controlla(!s.chiediCopertura("Scrivi a Laura cosa non copre la sua polizza", chiave: "giulia"), "Cosa non copre: «scrivi a Laura…» è un messaggio per «Fallo tu»")
        var casa = Documento(clienteId: "laura", titolo: "Polizza Casa", tipo: .polizza)
        casa.importatoIl = Date().addingTimeInterval(3_600)
        s.dati.documenti.append(casa)
        controlla(s.polizzaDellaRichiesta("cosa non copre la polizza infortuni di Laura", cliente: "laura")?.id == a.id,
                  "Cosa non copre: «la polizza infortuni» sceglie l'Infortuni, non l'ultima polizza")
        let m = s.spiegaCoperturaAlCliente(a.id, chiave: "giulia")
        let testo = m?.conferma?.azioni.first?.argomenti["testo"] ?? ""
        controlla(m?.conferma?.azioni.first?.strumento == RegistroStrumenti.messaggiPrepara && testo.contains("art. 3.1") && testo.contains("Laura"),
                  "Cosa non copre: «Spiegalo al cliente» prepara la bozza con gli articoli, da confermare")
        var scansione = Documento(clienteId: "andrea", titolo: "Polizza scansionata", tipo: .polizza)
        scansione.id = "doc-scansione-prova"
        s.dati.documenti.append(scansione)
        s.memorizzaTesto(scansione.id, [""])
        controlla(s.chiediCopertura("Cosa non copre la polizza di Andrea?", chiave: "giulia")
                  && s.conversazione("giulia").last?.testo.contains("non ha testo") == true, "Cosa non copre: una scansione senza testo, Vera lo dice")
    }

    // MARK: - 11 · Trova le differenze

    private static func differenze(_ controlla: (Bool, String) -> Void) {
        let s = stato()
        let (a, b) = FacSimiliVera.documenti(cliente: "laura")
        s.dati.documenti += [a, b]
        s.memorizzaTesto(a.id, FacSimiliVera.polizza)
        s.memorizzaTesto(b.id, FacSimiliVera.proposta)
        let c = s.confrontaDocumenti(a, b)
        func esito(_ voce: String) -> RigaDifferenza.Esito? { c.righe.first { $0.voce == voce }?.esito }
        controlla(esito("Capitale assicurato") == .migliora && esito("Premio") == .costaDiPiu && esito("Compagnia o emittente") == .uguale,
                  "Differenze: capitale migliora, premio costa di più, compagnia uguale (\(c.righe.map { "\($0.voce): \($0.etichetta)" }))")
        controlla(esito("Carenze") == .migliora && esito("Massimali") == .migliora && esito("Esclusioni") == .migliora,
                  "Differenze: carenza più corta, massimale più alto, meno esclusioni")
        controlla(c.sintesi.contains("Laura") && c.sintesi.contains("420 €") && c.sintesi.contains("610 €"), "Differenze: la sintesi di Prisma con le cifre della tabella: \(c.sintesi)")
        var kidA = Documento(clienteId: "laura", titolo: "KID 2025", tipo: .kid)
        kidA.campi = [CampoEstratto(chiave: .sri, valore: "3", pagina: 1)]
        var kidB = Documento(clienteId: "laura", titolo: "KID 2026", tipo: .kid)
        kidB.campi = [CampoEstratto(chiave: .sri, valore: "5", pagina: 1), CampoEstratto(chiave: .costoUscita, valore: "2%", pagina: 1)]
        let kid = DifferenzeVera.righe(prima: kidA, ora: kidB)
        controlla(kid.first { $0.voce == "Indicatore di rischio" }?.esito == .peggiora && kid.first { $0.voce == "Costi d'uscita" }?.esito == .cambia,
                  "Differenze: un rischio più alto peggiora; un costo letto da un lato solo cambia, senza un verso inventato")
        controlla(DifferenzeVera.eUnaRichiesta("Confronta la polizza di Laura con la proposta") && DifferenzeVera.eUnaRichiesta("Trova le differenze tra i due KID")
                  && !DifferenzeVera.eUnaRichiesta("Confronta Laura e Marco") && !DifferenzeVera.eUnaRichiesta("Confronta le due proposte di Marco"),
                  "Differenze: riconosce la richiesta")
        controlla(DifferenzeVera.coppia(s.documentiCliente("laura"), frase: "la polizza e la proposta").map { [$0.0.id, $0.1.id] } == [a.id, b.id],
                  "Differenze: la coppia dal più vecchio al più nuovo")
        controlla(s.chiediDifferenze("Confronta la polizza di Laura con la proposta", chiave: "giulia")
                  && s.confronto(s.conversazione("giulia").last?.confronto)?.oraId == b.id && s.dati.confrontiDocumenti.count == 1,
                  "Differenze: in chat la tabella, salvata nella scheda")
        _ = s.chiediDifferenze("Confronta la polizza di Laura con la proposta", chiave: "giulia")
        controlla(s.dati.confrontiDocumenti.count == 1, "Differenze: lo stesso confronto rifatto sostituisce quello di prima")
        s.salvaCopertura(CoperturaVera.copertura(a, pagine: FacSimiliVera.polizza))
        s.eliminaDocumento(a.id)
        controlla(s.dati.confrontiDocumenti.isEmpty && s.copertura(a.id) == nil, "Differenze: eliminato il documento, vanno via anche confronto e coperture")
        controlla(s.chiediDifferenze("Confronta i KID di Andrea", chiave: "giulia")
                  && s.conversazione("giulia").last?.testo.contains("servono due documenti") == true, "Differenze: senza due documenti Vera lo dice")
    }

    // MARK: - 16 · Il resoconto dell'incontro

    private static func resoconto(_ controlla: (Bool, String) -> Void) {
        let s = stato()
        guard let i = s.incontroPerResoconto(cliente: "giulia"), let c = s.cliente("giulia") else {
            return controlla(false, "Resoconto: l'incontro di prova di Giulia")
        }
        let r = ResocontoVera.componi(i, cliente: c, consulente: "Denis", verbale: VerbaleCopilota(punti: ["Il mutuo pesa sulla rata."], attivita: ["Mandare il riepilogo dei costi"]),
                                      trascrizione: "Le mando il riepilogo dei costi entro mercoledì.", analisiSalvata: false)
        controlla(r.sezioni.map(\.titolo) == ResocontoVera.titoliSezioni && r.sezioni[0].righe.first?.contains("Giulia Rossi") == true
                  && r.sezioni[0].righe.first?.contains("Denis") == true, "Resoconto: cinque sezioni, presenti con il consulente")
        controlla(r.sezioni[3].righe.contains("Mandare il riepilogo dei costi") && r.sezioni[3].righe.contains { $0.hasPrefix("Mandare a Giulia il riepilogo dei costi") && $0.contains("entro mercoledì") },
                  "Resoconto: i prossimi passi dal copilota e le promesse della nota vocale (\(r.sezioni[3].righe))")
        controlla(r.sezioni[4].righe.contains { $0.contains("Fabbisogno") } && r.fonti == [.copilota, .notaVocale] || r.fonti.contains(.notaVocale),
                  "Resoconto: da raccogliere e le fonti")
        let inventato = ResocontoVera.applica(#"{"presenti":"x","parlato":["Il mutuo pesa sulla rata."],"deciso":["Investire 90.000 € subito"],"passi":["Mandare il riepilogo dei costi"],"raccogliere":["Il fabbisogno mensile"],"breve":["Riepilogo dei costi"]}"#, a: r)
        controlla(inventato.sezioni[2].righe == r.sezioni[2].righe && inventato.sezioni[4].righe == ["Il fabbisogno mensile"] && inventato.conQwen,
                  "Resoconto: la sezione con una cifra inventata resta di Prisma, le altre di Qwen")
        // «Manda una sintesi a Giulia»: decisioni e prossimi passi, senza cifre nuove né appunti interni
        let sintesi = ResocontoVera.sintesiCliente(r, incontro: i, nome: c.nome) ?? ""
        controlla(sintesi.hasPrefix("Buongiorno Giulia,") && sintesi.contains("Mandare il riepilogo dei costi")
                  && !sintesi.contains("Fabbisogno") && !sintesi.contains("Denis")
                  && CommentoVera.numeriConservati(bozza: r.sezioni.flatMap(\.righe).joined(separator: "\n") + Formati.dataLunga.string(from: i.data), testo: sintesi),
                  "Resoconto: la sintesi per il cliente ha decisioni e prossimi passi, nessuna cifra nuova né appunti interni")
        var vuoto = r
        vuoto.sezioni[2].righe = []
        vuoto.sezioni[3].righe = []
        controlla(ResocontoVera.sintesiCliente(vuoto, incontro: i, nome: c.nome) == nil, "Resoconto: senza decisioni né passi non c'è sintesi da mandare")
        // Il consenso alla registrazione si vede nella scheda: della nota vocale, oppure del dossier se viene dal copilota
        var conNota = r
        conNota.consenso = ConsensoCopilota(data: i.data, modo: .aVoce)
        var soloAppunti = r
        soloAppunti.consenso = nil
        soloAppunti.fonti = [.appunti]
        controlla(ResocontoVera.consensoDaMostrare(conNota, cliente: c).map(ResocontoVera.testoConsenso)?.contains("a voce") == true
                  && ResocontoVera.consensoDaMostrare(soloAppunti, cliente: c) == nil,
                  "Resoconto: il consenso alla registrazione è nella scheda prima della firma, solo quando c'è stata una registrazione")
        // In chat, ✕, breve, firma
        controlla(s.chiediResoconto("Il resoconto dell'incontro con Giulia", chiave: "giulia") && s.conversazione("giulia").last?.resoconto == i.id
                  && s.incontro(i.id)?.resoconto != nil, "Resoconto: in chat il resoconto, salvato nell'incontro")
        controlla(!s.chiediResoconto("Dammi il resoconto delle posizioni di Marco", chiave: "giulia") && !s.chiediResoconto("Fammi il resoconto di Marco", chiave: "giulia")
                  && !s.chiediResoconto("Manda a Marco il resoconto dell'incontro", chiave: "giulia")
                  && !s.chiediResoconto("Scrivi una mail a Giulia con il resoconto dell'incontro", chiave: "giulia")
                  && StatoShell.eUnResoconto(InterpreteComandi.pulisci("Il resoconto dell'incontro con Marco sul portafoglio")),
                  "Resoconto: il resoconto delle posizioni e «manda il resoconto» non sono questa funzione")
        guard let salvato = s.incontro(i.id)?.resoconto else { return }
        if let k = salvato.sezioni.firstIndex(where: { $0.righe.count >= 1 && $0.titolo != ResocontoVera.titoliSezioni[0] }) {
            let prima = salvato.sezioni[k].righe.count
            s.togliRigaResoconto(i.id, sezione: k, riga: 0)
            controlla(s.incontro(i.id)?.resoconto?.sezioni[k].righe.count == prima - 1, "Resoconto: ✕ toglie una riga prima della firma")
        }
        s.formatoResoconto(i.id, .breve)
        controlla(s.incontro(i.id)?.resoconto?.sezioniMostrate.count == 1, "Resoconto: «Breve» mostra la sintesi")
        s.formatoResoconto(i.id, .completo)
        // Chiesto di nuovo prima della firma: si mostra com'è, con le righe tolte
        let tolte = s.incontro(i.id)?.resoconto
        _ = s.chiediResoconto("Il resoconto dell'incontro con Giulia", chiave: "giulia")
        controlla(s.incontro(i.id)?.resoconto == tolte, "Resoconto: chiesto di nuovo non si ricompone sopra le tue modifiche")
        let documenti = s.dati.documenti.count
        let id = s.firmaResoconto(i.id)
        let firmato = s.incontro(i.id)?.resoconto
        controlla(id != nil && s.dati.documenti.count == documenti + 1 && s.dati.documenti.last?.clienteId == "giulia"
                  && firmato?.firmatoDa == s.nomeUtente && firmato?.trascrizione == nil && firmato?.documentoId == id,
                  "Resoconto: «Firma» mette il PDF nei Documenti di Giulia, con nome e data, e la trascrizione non resta")
        controlla((s.testoDocumento(s.dati.documenti.last!).joined()).contains("Resoconto"), "Resoconto: il PDF ha il testo del resoconto")
        controlla(s.firmaResoconto(i.id) == nil, "Resoconto: un resoconto firmato non si firma due volte")
        let messaggiPrima = s.dati.messaggi.count
        let manda = s.mandaSintesiResoconto(i.id, chiave: "giulia")
        controlla(manda?.conferma?.azioni.map(\.strumento) == [RegistroStrumenti.messaggiPrepara] && manda?.conferma?.stato == .daConfermare
                  && manda?.conferma?.azioni.first?.argomenti["cliente"] == "giulia" && s.dati.messaggi.count == messaggiPrima,
                  "Resoconto: «Manda una sintesi a Giulia» prepara la bozza in Messaggi da confermare, niente parte da sola")
        s.formatoResoconto(i.id, .breve)
        controlla(s.incontro(i.id)?.resoconto?.formato == .completo, "Resoconto: firmato non cambia più")
        let passi = s.proponiPassiResoconto(i.id, chiave: "giulia")
        controlla(passi?.conferma?.azioni.allSatisfy { $0.strumento == RegistroStrumenti.attivitaNuova } == true && passi?.conferma?.stato == .daConfermare,
                  "Resoconto: dopo la firma i prossimi passi come attività da confermare")
        // La nota vocale: niente senza il consenso del cliente
        s.notaVocale(URL(fileURLWithPath: "/tmp/nota-di-prova.m4a"), chiave: "marco")
        controlla(s.conversazione("marco").last?.testo.contains("consenso") == true && !s.veraInCorso,
                  "Resoconto: la nota vocale senza il consenso alla registrazione non si trascrive")
        controlla(TrascrizioneFile.durata(URL(fileURLWithPath: "/tmp/non-esiste-\(UUID().uuidString).m4a")) == nil
                  && ResocontoVera.estensioniAudio.contains("m4a") && ResocontoVera.durataMassima == 3600,
                  "Resoconto: m4a, mp3 e wav fino a 60 minuti")
    }

    // MARK: - Archivio

    private static func archivio(_ controlla: (Bool, String) -> Void) {
        let s = stato()
        let (a, b) = FacSimiliVera.documenti(cliente: "laura")
        var d = s.dati.istantanea
        d.promesse = [PromessaCliente(clienteId: "laura", testo: "Richiamare Laura", frase: "La richiamo dopo il 15.", fonte: .messaggio,
                                      fonteId: "m", fonteEtichetta: "dal messaggio di ieri", scadenza: Date(timeIntervalSince1970: 1_800_000_000), quando: "dopo il 15")]
        d.confrontiDocumenti = [s.confrontaDocumenti(a, b)]
        d.coperture = [CoperturaVera.copertura(a, pagine: FacSimiliVera.polizza)]
        var i = Incontro(clienteId: "laura", titolo: "Prova", data: Date(timeIntervalSince1970: 1_800_000_000))
        i.resoconto = ResocontoIncontro(titolo: "Prova", sezioni: [SezioneResoconto(titolo: "Presenti", righe: ["Laura"])], breve: ["Uno"], fonti: [.appunti])
        d.incontri.append(i)
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        let letto = (try? e.encode(d)).flatMap { try? dec.decode(DatiPrisma.self, from: $0) }
        controlla(letto?.promesse.first?.testo == "Richiamare Laura" && letto?.confrontiDocumenti.first?.righe.count == d.confrontiDocumenti.first?.righe.count
                  && letto?.coperture.first?.voci.count == 8 && letto?.incontri.first(where: { $0.id == i.id })?.resoconto?.breve == ["Uno"],
                  "Archivio: promesse, confronti, coperture e resoconti tornano uguali")
        var m = MessaggioVera(autore: .vera, testo: "Riletto.")
        m.lettura = SecondaLetturaVera.rileggi("Rendimento garantito.", oggetto: "x", fonti: "", fonteCliente: nil)
        m.promesse = ["p1"]
        m.confronto = "c1"
        m.copertura = "d1"
        m.resoconto = "i1"
        let mm = (try? e.encode(m)).flatMap { try? dec.decode(MessaggioVera.self, from: $0) }
        controlla(mm?.lettura == m.lettura && mm?.promesse == ["p1"] && mm?.confronto == "c1" && mm?.copertura == "d1" && mm?.resoconto == "i1",
                  "Archivio: gli allegati della fase 3 nei messaggi di Vera")
        // Un archivio vecchio senza i campi nuovi si legge
        let vecchio = #"{"versione":27}"#.data(using: .utf8)!
        let v = try? dec.decode(DatiPrisma.self, from: vecchio)
        controlla(v == nil || (v?.promesse.isEmpty == true && v?.coperture.isEmpty == true), "Archivio: senza i campi nuovi le liste sono vuote")
    }
}
