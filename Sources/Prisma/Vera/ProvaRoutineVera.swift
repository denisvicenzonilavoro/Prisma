import Foundation

/// Prova di «Le routine» (Vera/BRIEF.md, funzione 3) dentro `Prisma --prova-vera`: le quattro routine pronte, il
/// riconoscimento della frase, «Prepara l'incontro» con la scaletta e i minuti, «Il mio lunedì», «Fine mese» (con i
/// chilometri «in attesa»), «Dopo la firma» con le sole azioni da confermare, la programmazione (quali routine sono
/// dovute adesso), le routine nuove a parole (prima le regole, poi Qwen con i soli passi del catalogo) e l'archivio.
/// Deterministica: `oggi` passato sempre, niente rete, niente Qwen vero.
enum ProvaRoutineVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        pronte(controlla)
        riconosci(controlla)
        preparaIncontro(controlla)
        ilMioLunedi(controlla)
        fineMese(controlla)
        dopoLaFirma(controlla)
        programmazione(controlla)
        nuoveARegole(controlla)
        nuoveConQwen(controlla)
        archivio(controlla)
        correzioniRevisione(controlla)
    }

    private static let cal = Calendar.current

    private static func giorno(_ a: Int, _ m: Int, _ g: Int, _ h: Int = 9, _ min: Int = 0) -> Date {
        cal.date(from: DateComponents(year: a, month: m, day: g, hour: h, minute: min)) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    /// Oggi alle 8:00: i dati di prova partono da oggi, l'ora del giorno non conta.
    private static var oggiDemo: Date {
        cal.date(byAdding: .hour, value: 8, to: cal.startOfDay(for: Date())) ?? Date()
    }

    private static func noti(_ d: DatiPrisma) -> [ClienteNoto] { d.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) } }

    private static func routine(_ id: String) -> RoutineVera {
        RoutineVera.pronte().first { $0.id == id } ?? RoutineVera.pronte()[0]
    }

    private static func appuntamento(_ id: String, _ cliente: String, _ titolo: String, _ inizio: Date, _ durata: Int,
                                     _ tipo: TipoAppuntamento, _ luogo: String = "In studio", posizione: String? = nil) -> Appuntamento {
        Appuntamento(id: id, clienteId: cliente, titolo: titolo, inizio: inizio, durataMinuti: durata, luogo: luogo, note: "",
                     stato: .pianificato, tipo: tipo, posizioneId: posizione)
    }

    // MARK: - Pacchetto e pronte

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let t = IstruzioniVera.testo("routine") ?? ""
        controlla(t.contains("catalogo") && t.contains("JSON"), "Routine: istruzioni «routine» nel pacchetto (Vera/Istruzioni/routine.md)")
    }

    private static func pronte(_ controlla: (Bool, String) -> Void) {
        let p = RoutineVera.pronte()
        controlla(p.map(\.titolo) == ["Prepara l'incontro", "Il mio lunedì", "Fine mese", "Dopo la firma"], "Routine: le quattro pronte del template, in ordine")
        controlla(p.map(\.passi.count) == [5, 4, 4, 4], "Routine: 5, 4, 4 e 4 passi come nel template: \(p.map(\.passi.count))")
        controlla(Set(p.map(\.id)).count == 4 && p.allSatisfy(\.pronta), "Routine: id distinti, segnate «pronte»")
        controlla(p[1].etichetta == "Ogni lunedì alle 8:30" && p[2].etichetta == "L'ultimo giorno del mese" && p[3].etichetta == "Dopo ogni firma",
                  "Routine: le etichette della programmazione: \(p.map(\.etichetta))")
        var usata = p[0]
        controlla(usata.etichetta == "Mai usata", "Routine: «Mai usata» prima del primo lancio")
        for _ in 0..<23 { usata = RoutineVera.lanciata(usata, il: oggiDemo) }
        controlla(usata.etichetta == "Usata 23 volte" && usata.ultimoLancio == oggiDemo, "Routine: «Usata 23 volte» e l'ultimo lancio")
        controlla(RoutineVera.ripartisci(45, pesi: [2, 4, 3]) == [10, 20, 15], "Routine: la scaletta del template, 10, 20 e 15 minuti su 45")
        controlla(RoutineVera.ripartisci(60, pesi: [2, 4, 3]).reduce(0, +) == 60, "Routine: i minuti fanno sempre la durata dell'incontro")
        // Durate brevi o non multiple di 5: la somma è la durata arrotondata al passo, ogni punto a multipli di 5 (almeno 5)
        let durate = [10, 15, 20, 42, 43, 47, 60, 90]
        let tutte = durate.allSatisfy { d -> Bool in
            let m = RoutineVera.ripartisci(d, pesi: [2, 4, 3])
            let arrotondata = RoutineVera.durataScaletta(d)
            return m.reduce(0, +) == arrotondata && m.allSatisfy { $0 >= 5 && $0 % 5 == 0 } && m.count == min(3, arrotondata / 5)
        }
        controlla(tutte, "Routine: con durate brevi o non multiple di 5 la somma torna e i minuti sono multipli di 5: \(durate.map { RoutineVera.ripartisci($0, pesi: [2, 4, 3]) })")
        controlla(RoutineVera.ripartisci(10, pesi: [2, 4, 3]) == [5, 5] && RoutineVera.ripartisci(42, pesi: [2, 4, 3]).reduce(0, +) == 40,
                  "Routine: 10 minuti bastano per due punti, 42 minuti diventano 40")
    }

    // MARK: - Riconoscere la frase

    private static func riconosci(_ controlla: (Bool, String) -> Void) {
        let d = DatiPrisma.demo()
        let tutte = RoutineVera.pronte()
        let a = RoutineVera.riconosci("Vera, prepara l'incontro con Marco", routine: tutte, clienti: noti(d), attivo: nil)
        controlla(a?.routine.id == RoutineVera.idPrepara && a?.clienteId == "marco", "Routine: «prepara l'incontro con Marco» → Prepara l'incontro, Marco")
        let b = RoutineVera.riconosci("Vera, com'è la settimana?", routine: tutte, clienti: noti(d), attivo: "giulia")
        controlla(b?.routine.id == RoutineVera.idLunedi && b?.clienteId == nil, "Routine: «com'è la settimana?» → Il mio lunedì, senza cliente")
        let c = RoutineVera.riconosci("Ruby, chiudiamo il mese", routine: tutte, clienti: noti(d), attivo: nil)
        controlla(c?.routine.id == RoutineVera.idFineMese, "Routine: «chiudiamo il mese» → Fine mese (anche con il nome di prima)")
        let f = RoutineVera.riconosci("Ho firmato con Giulia", routine: tutte, clienti: noti(d), attivo: nil)
        controlla(f?.routine.id == RoutineVera.idDopoFirma && f?.clienteId == "giulia", "Routine: «ho firmato con Giulia» → Dopo la firma, Giulia")
        let aperto = RoutineVera.riconosci("prepara l'incontro", routine: tutte, clienti: noti(d), attivo: "laura")
        controlla(aperto?.clienteId == "laura", "Routine: senza nome vale il cliente aperto")
        // Un nome che non è un cliente non è «nessun nome»: niente cliente aperto, la routine chiederà per chi
        let ignoto = RoutineVera.riconosci("Ho firmato con Fumagalli", routine: tutte, clienti: noti(d), attivo: "marco")
        controlla(ignoto?.routine.id == RoutineVera.idDopoFirma && ignoto?.clienteId == nil,
                  "Routine: «ho firmato con Fumagalli» (non cliente) non parte sul cliente aperto: \(ignoto?.clienteId ?? "nil")")
        let conVera = RoutineVera.riconosci("ho firmato, Vera, dopo la firma con Alleanza", routine: tutte, clienti: noti(d), attivo: "marco")
        controlla(conVera?.clienteId == "marco", "Routine: «con Alleanza» non è un nome di cliente, vale il cliente aperto")
        controlla(RoutineVera.riconosci("che tempo fa domani?", routine: tutte, clienti: noti(d), attivo: nil) == nil, "Routine: una frase qualsiasi non lancia niente")
        var spenta = tutte
        spenta[2].attiva = false
        controlla(RoutineVera.riconosci("chiudiamo il mese", routine: spenta, clienti: noti(d), attivo: nil) == nil, "Routine: una routine spenta non si lancia")
    }

    // MARK: - 1 · Prepara l'incontro

    private static func preparaIncontro(_ controlla: (Bool, String) -> Void) {
        let d = DatiPrisma.demo()
        let oggi = oggiDemo
        let r = routine(RoutineVera.idPrepara)
        let e = RoutineVera.esegui(r, richiesta: "Vera, prepara l'incontro con Marco", contesto: ContestoRoutine(dati: d, oggi: oggi, clienteId: "marco"))
        controlla(e.domanda == nil && e.passi.count == 5 && e.passi.allSatisfy { $0.stato != .impossibile },
                  "Prepara l'incontro: cinque passi eseguiti: \(e.passi.map(\.stato.rawValue))")
        guard e.passi.count == 5 else { return }
        controlla(e.passi.first?.titolo == "Apro la scheda di Marco Bianchi" && (e.passi.first?.dettaglio.contains("oggi alle 11:00 in videochiamata") ?? false),
                  "Prepara l'incontro: la scheda e il prossimo incontro: \(e.passi.first?.dettaglio ?? "")")
        controlla(e.passi[2].dettaglio.contains("Infortuni famiglia"), "Prepara l'incontro: la scadenza dell'Infortuni famiglia: \(e.passi[2].dettaglio)")
        controlla(e.scaletta.count == 3 && e.scaletta.map(\.minuti).reduce(0, +) == 60,
                  "Prepara l'incontro: tre punti per i 60 minuti della videochiamata: \(e.scaletta.map { "\($0.testo) \($0.minuti)" })")
        if e.scaletta.count == 3 {
            controlla(e.scaletta[0].testo.hasPrefix("Rinnovo di «Infortuni famiglia» entro il"), "Prepara l'incontro: primo punto il rinnovo: \(e.scaletta[0].testo)")
            controlla(e.scaletta[1].testo == "Una protezione per Elena", "Prepara l'incontro: poi la protezione di Elena: \(e.scaletta[1].testo)")
            controlla(e.scaletta[2].testo.contains("Anna"), "Prepara l'incontro: poi il piano per gli studi di Anna: \(e.scaletta[2].testo)")
            controlla(e.scaletta[1].minuti > e.scaletta[0].minuti, "Prepara l'incontro: la protezione ha più tempo del rinnovo")
        }
        controlla(e.risultato.titolo == "La scaletta per le 11:00 · Videochiamata", "Prepara l'incontro: il titolo del risultato: \(e.risultato.titolo)")
        controlla(e.risultato.righe.count == 3 && e.risultato.righe.allSatisfy { $0.hasSuffix("minuti") }, "Prepara l'incontro: la scaletta nel risultato, con i minuti")
        controlla(e.azioni.count == 1 && e.azioni.first?.strumento == RegistroStrumenti.messaggiPrepara && e.azioni.allSatisfy { $0.esito == nil },
                  "Prepara l'incontro: l'ordine del giorno è solo una bozza da confermare")
        controlla(e.schedaConferma?.stato == .daConfermare, "Prepara l'incontro: la scheda «Conferma» con l'azione")
        controlla(e.risultato.pulsanti.map(\.app) == [.incontri, .messaggi], "Prepara l'incontro: «Apri in Incontri» e «Manda a Marco l'ordine del giorno»: \(e.risultato.pulsanti.map(\.titolo))")
        // Senza cliente: la domanda, nessun passo
        let senza = RoutineVera.esegui(r, richiesta: "prepara l'incontro", contesto: ContestoRoutine(dati: d, oggi: oggi))
        controlla(senza.domanda == "Per quale cliente?" && senza.passi.isEmpty && senza.azioni.isEmpty, "Prepara l'incontro: senza cliente chiede «Per quale cliente?»")
    }

    // MARK: - 2 · Il mio lunedì

    private static func ilMioLunedi(_ controlla: (Bool, String) -> Void) {
        var d = DatiPrisma.demo()
        let oggi = giorno(2026, 11, 2, 8, 30)   // lunedì 2 novembre 2026, come nel template
        d.appuntamenti = [
            appuntamento("r-1", "giulia", "Il punto sul progetto casa", giorno(2026, 11, 2, 9, 30), 45, .revisione),
            appuntamento("r-2", "marco", "Nuovi progetti di famiglia", giorno(2026, 11, 2, 11, 0), 60, .analisi, "Videochiamata"),
            appuntamento("r-3", "sofia", "Rinnovo del consenso", giorno(2026, 11, 2, 15, 0), 30, .telefonata, "Telefonata"),
            appuntamento("r-4", "laura", "Un progetto tutto suo", giorno(2026, 11, 3, 10, 0), 45, .proposta),
            appuntamento("r-5", "", "Formazione Alleanza", giorno(2026, 11, 3, 14, 30), 60, .altro, "Online"),
            appuntamento("r-6", "andrea", "Il nostro primo incontro", giorno(2026, 11, 4, 15, 0), 60, .primoIncontro),
            appuntamento("r-7", "sofia", "Uno sguardo ai prossimi mesi", giorno(2026, 11, 5, 11, 30), 30, .telefonata, "Telefonata"),
            appuntamento("r-8", "giulia", "Firma del piano casa", giorno(2026, 11, 5, 16, 0), 60, .firma),
            appuntamento("r-9", "marco", "Rinnovo della copertura infortuni", giorno(2026, 11, 6, 9, 0), 60, .revisione),
        ]
        d.attivita = [Attivita(id: "task-fascicolo", clienteId: "laura", titolo: "Preparare il fascicolo di Laura", scadenza: giorno(2026, 11, 4, 0, 0),
                               priorita: .normale, completata: false)]
        d.promesse = [PromessaCliente(clienteId: "sofia", testo: "Mandare a Sofia il riepilogo della rivalutabile", frase: "Le mando il riepilogo della rivalutabile.",
                                      fonte: .nota, fonteId: "nota-sofia", fonteEtichetta: "dalla nota di prova", scadenza: giorno(2026, 10, 30))]
        let e = RoutineVera.esegui(routine(RoutineVera.idLunedi), richiesta: "Vera, com'è la settimana?", contesto: ContestoRoutine(dati: d, oggi: oggi))
        controlla(e.passi.count == 4 && e.domanda == nil, "Il mio lunedì: quattro passi, senza cliente")
        guard e.passi.count == 4 else { return }
        controlla(e.passi.first?.dettaglio == "9 impegni da lunedì 2 a venerdì 6", "Il mio lunedì: l'agenda della settimana: \(e.passi.first?.dettaglio ?? "")")
        controlla(e.risultato.righe.first == "Lunedì è il giorno pieno: Giulia, Marco e la telefonata a Sofia", "Il mio lunedì: il giorno pieno: \(e.risultato.righe.first ?? "")")
        controlla(e.passi[1].dettaglio.hasPrefix("Mercoledì mattina è libero"), "Il mio lunedì: il primo buco è mercoledì mattina: \(e.passi[1].dettaglio)")
        controlla(e.risultato.righe.contains("Mercoledì mattina è libero: buono per «Preparare il fascicolo di Laura»"), "Il mio lunedì: il buco con l'attività da fare")
        controlla(e.passi[2].dettaglio.hasPrefix("1 promessa in ritardo"), "Il mio lunedì: la promessa in ritardo: \(e.passi[2].dettaglio)")
        controlla(e.risultato.righe.contains("In ritardo: mandare a Sofia il riepilogo della rivalutabile"), "Il mio lunedì: il ritardo nel risultato")
        controlla(e.passi[3].stato == .fatto || e.passi[3].stato == .vuoto, "Il mio lunedì: la mossa della settimana dal motore della mossa del giorno")
        controlla(e.azioni.isEmpty, "Il mio lunedì: solo lettura, nessuna azione")
        controlla(e.risultato.pulsanti.first?.app == .agenda, "Il mio lunedì: «Apri l'agenda»")

        // Le festività non sono mezze giornate libere: martedì 8 dicembre 2026 (Immacolata) si salta
        var festa = DatiPrisma.demo()
        festa.impostazioni.orari = OrariLavoro()
        festa.appuntamenti = [appuntamento("f-1", "giulia", "Mattina piena", giorno(2026, 12, 7, 9, 0), 240, .analisi),
                              appuntamento("f-2", "marco", "Pomeriggio pieno", giorno(2026, 12, 7, 14, 30), 240, .analisi)]
        festa.attivita = []
        festa.promesse = []
        let ef = RoutineVera.esegui(routine(RoutineVera.idLunedi), richiesta: "Vera, com'è la settimana?",
                                    contesto: ContestoRoutine(dati: festa, oggi: giorno(2026, 12, 7, 8, 30)))
        controlla(ef.passi.count == 4 && ef.passi[1].dettaglio.hasPrefix("Mercoledì mattina è libero"),
                  "Il mio lunedì: la festività non è un buco, il primo è mercoledì mattina: \(ef.passi.count == 4 ? ef.passi[1].dettaglio : "")")
    }

    // MARK: - 3 · Fine mese

    private static func fineMese(_ controlla: (Bool, String) -> Void) {
        controlla(RoutineVera.meseDaChiudere(giorno(2026, 11, 30, 18), cal: cal).start == giorno(2026, 11, 1, 0)
                  && RoutineVera.meseDaChiudere(giorno(2026, 12, 1, 9), cal: cal).start == giorno(2026, 11, 1, 0)
                  && RoutineVera.meseDaChiudere(giorno(2026, 12, 10, 9), cal: cal).start == giorno(2026, 12, 1, 0),
                  "Fine mese: il mese da chiudere (quello prima nei primi giorni del mese)")
        var d = DatiPrisma.demo()
        var pagata = Parcella(clienteId: "laura", data: giorno(2026, 11, 5), descrizione: "Consulenza", righe: [RigaParcella(descrizione: "Consulenza", importo: 1_000)])
        pagata.stato = .pagata
        pagata.incassataIl = giorno(2026, 11, 10)
        let bozza = Parcella(clienteId: "laura", data: giorno(2026, 11, 28), descrizione: "Riesame", righe: [RigaParcella(descrizione: "Riesame", importo: 500)])
        var emessa = Parcella(clienteId: "giulia", data: giorno(2026, 9, 1), descrizione: "Analisi", righe: [RigaParcella(descrizione: "Analisi", importo: 300)])
        emessa.stato = .emessa
        emessa.scadenza = giorno(2026, 10, 1)
        d.parcelle = [pagata, bozza, emessa]
        var infortuni = Posizione(clienteId: "marco", canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Infortuni famiglia")
        infortuni.id = "r-infortuni"
        infortuni.scadenza = giorno(2026, 12, 17)
        var tcm = Posizione(clienteId: "giulia", canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Temporanea caso morte")
        tcm.id = "r-tcm"
        tcm.scadenza = giorno(2026, 12, 20)
        var mutuo = Posizione(clienteId: "giulia", canale: .indipendente, stato: .inEssere, area: .debiti, nome: "Mutuo casa")
        mutuo.id = "r-mutuo"
        mutuo.scadenza = giorno(2026, 12, 10)
        d.posizioni = [infortuni, tcm, mutuo]
        d.appuntamenti = [appuntamento("r-rinnovo", "marco", "Rinnovo della copertura infortuni", giorno(2026, 12, 1, 16, 30), 30, .revisione, posizione: "r-infortuni")]
        d.attivita = []
        let e = RoutineVera.esegui(routine(RoutineVera.idFineMese), richiesta: "Vera, chiudiamo il mese", contesto: ContestoRoutine(dati: d, oggi: giorno(2026, 11, 30, 18)))
        controlla(e.passi.count == 4, "Fine mese: quattro passi")
        guard e.passi.count == 4 else { return }
        controlla(e.passi[0].dettaglio.contains(Formati.euro(1_000)) && e.passi[0].dettaglio.contains("novembre"),
                  "Fine mese: le parcelle incassate a novembre, da MotoreParcelle: \(e.passi[0].dettaglio)")
        controlla(e.passi[1].stato == .inAttesa && e.passi[1].dettaglio.contains("non registra ancora"), "Fine mese: i chilometri restano «in attesa», senza cifre inventate")
        controlla(e.passi[2].dettaglio.contains("1 parcella da fatturare") && e.passi[2].dettaglio.contains("1 scaduta"), "Fine mese: bozze da fatturare e scadute: \(e.passi[2].dettaglio)")
        controlla(e.azioni.count == 1 && e.azioni.first?.strumento == RegistroStrumenti.attivitaNuova && e.azioni.first?.argomenti["cliente"] == "giulia",
                  "Fine mese: un'attività da confermare per la scadenza di dicembre non ancora in agenda (il mutuo non conta)")
        controlla(e.risultato.righe.contains("2 scadenze di dicembre: 1 da mettere in agenda (da confermare)"), "Fine mese: le scadenze del mese dopo nel risultato: \(e.risultato.righe)")
        controlla(e.risultato.titolo == "Il mese è chiuso" && e.azioni.allSatisfy { $0.esito == nil }, "Fine mese: il mese è chiuso, niente eseguito")
    }

    // MARK: - 4 · Dopo la firma

    private static func dopoLaFirma(_ controlla: (Bool, String) -> Void) {
        let d = DatiPrisma.demo()
        let oggi = oggiDemo
        let r = routine(RoutineVera.idDopoFirma)
        let e = RoutineVera.esegui(r, richiesta: "Vera, ho firmato con Giulia", contesto: ContestoRoutine(dati: d, oggi: oggi, clienteId: "giulia"))
        controlla(e.passi.count == 4 && e.passi.first?.stato == .inAttesa, "Dopo la firma: senza il PDF il contratto aspetta di essere trascinato")
        controlla(e.azioni.map(\.strumento) == [RoutineVera.strumentoPosizioneFirmata, RegistroStrumenti.agendaNuovo, RegistroStrumenti.messaggiPrepara],
                  "Dopo la firma: posizione, controllo e messaggio, tutti da confermare: \(e.azioni.map(\.strumento))")
        controlla(e.azioni.allSatisfy { $0.esito == nil } && e.passi.dropFirst().allSatisfy { $0.stato == .daConfermare }, "Dopo la firma: niente eseguito dal motore")
        if e.azioni.count == 3 {
            controlla(e.azioni[0].argomenti["posizione"] == "pos-giulia-piano-previdenziale-integrativo" && e.azioni[0].dettaglio.hasPrefix("\(Formati.euro(200)) al mese da"),
                      "Dopo la firma: la proposta presentata di Giulia, con il premio di Prisma: \(e.azioni[0].dettaglio)")
            let nomeGiulia = d.clienti.first(where: { $0.id == "giulia" })?.nome ?? "?"
            controlla(e.azioni[0].titolo.hasSuffix(" di \(nomeGiulia)"),
                      "Dopo la firma: il titolo dell'azione nomina il cliente: \(e.azioni[0].titolo)")
            let inizio = RegistroStrumenti.daIso(e.azioni[1].argomenti["inizio"])
            let mesi = inizio.flatMap { cal.dateComponents([.month], from: cal.startOfDay(for: oggi), to: $0).month }
            let feriale = inizio.map { d.impostazioni.orari.giorni.contains(cal.component(.weekday, from: $0)) } ?? false
            controlla(mesi == 6 && feriale && e.azioni[1].argomenti["tipo"] == TipoAppuntamento.revisione.rawValue,
                      "Dopo la firma: il primo controllo fra sei mesi, in un giorno di lavoro: \(e.azioni[1].dettaglio)")
            let testo = e.azioni[2].argomenti["testo"] ?? ""
            let mese = inizio.map { Formati.formato("MMMM").string(from: $0) } ?? "?"
            controlla(testo.hasPrefix("Buongiorno Giulia") && testo.contains("«Piano previdenziale integrativo»") && testo.contains("a \(mese) per il primo controllo"),
                      "Dopo la firma: il benvenuto nomina il piano e il mese del controllo: \(testo)")
        }
        controlla(e.risultato.titolo == "Tutto in ordine dopo la firma", "Dopo la firma: il titolo del risultato")
        orarioControllo(controlla)
        // Con il PDF trascinato anche l'archiviazione diventa un'azione da confermare
        let conFile = RoutineVera.esegui(r, richiesta: "ho firmato con Giulia",
                                         contesto: ContestoRoutine(dati: d, oggi: oggi, clienteId: "giulia", file: "/tmp/contratto-giulia.pdf"))
        controlla(conFile.azioni.first?.strumento == RegistroStrumenti.documentiArchivia && conFile.azioni.first?.argomenti["file"] == "/tmp/contratto-giulia.pdf"
                  && conFile.passi.first?.stato == .daConfermare, "Dopo la firma: con il PDF, «Archivio il contratto» da confermare")
        // La posizione indicata dall'evento vince sulla proposta più recente
        let indicata = RoutineVera.posizioneFirmata(cliente: d.clienti.first(where: { $0.id == "marco" })!, posizioneId: "pos-marco-piano-per-gli-studi-di-anna", posizioni: d.posizioni)
        controlla(indicata?.nome == "Piano per gli studi di Anna", "Dopo la firma: la posizione dell'evento firma")
    }

    /// Il primo controllo: festività, fasce di lavoro, margine, e nil quando non c'è spazio.
    private static func orarioControllo(_ controlla: (Bool, String) -> Void) {
        var d = DatiPrisma.demo()
        d.impostazioni.orari = OrariLavoro()
        d.appuntamenti = []
        // Un mese dopo domenica 8 novembre è martedì 8 dicembre, festivo: si va a mercoledì 9 alle 9:30
        let festa = RoutineVera.orarioControllo(mesi: 1, dati: d, oggi: giorno(2026, 11, 8, 10), cal: cal)
        controlla(festa == giorno(2026, 12, 9, 9, 30), "Dopo la firma: il controllo salta la festività dell'8 dicembre: \(festa.map { Formati.dataBreve.string(from: $0) } ?? "nessuno")")
        // Pomeriggio spento e mattina di mercoledì 9 piena: giovedì 10 alle 9:30, mai il pomeriggio
        var mattina = d
        mattina.impostazioni.orari.pomeriggioAttivo = false
        mattina.appuntamenti = [appuntamento("c-1", "laura", "Mattina piena", giorno(2026, 12, 9, 9, 0), 240, .analisi)]
        let soloMattina = RoutineVera.orarioControllo(mesi: 1, dati: mattina, oggi: giorno(2026, 11, 9, 10), cal: cal)
        let dentro = soloMattina.map { t in
            !MotorePianificazione.fuoriOrario(appuntamento("p", "giulia", "", t, 60, .revisione), orari: mattina.impostazioni.orari, cal: cal)
        } ?? false
        controlla(soloMattina == giorno(2026, 12, 10, 9, 30) && dentro, "Dopo la firma: il controllo resta dentro gli orari di lavoro (pomeriggio spento)")
        // Un impegno alle 11:00: le 10:00 toccherebbero il margine, si propone alle 9:30
        var conImpegno = d
        conImpegno.appuntamenti = [appuntamento("c-2", "laura", "Alle undici", giorno(2026, 12, 9, 11, 0), 60, .analisi)]
        let margine = RoutineVera.orarioControllo(mesi: 1, dati: conImpegno, oggi: giorno(2026, 11, 9, 10), cal: cal)
        let lontano = margine.map { t in
            MotorePianificazione.sovrapposti(appuntamento("p", "giulia", "", t, 60, .revisione), in: conImpegno.appuntamenti,
                                             margine: conImpegno.impostazioni.orari.margineMinuti).isEmpty
        } ?? false
        controlla(margine == giorno(2026, 12, 9, 9, 30) && lontano, "Dopo la firma: il controllo rispetta il margine degli orari di lavoro")
        // Tre settimane tutte occupate: nessun orario (mai uno occupato)
        var pieno = d
        pieno.appuntamenti = [appuntamento("c-3", "", "Tutto occupato", giorno(2026, 12, 9, 0, 0), 22 * 24 * 60, .altro)]
        controlla(RoutineVera.orarioControllo(mesi: 1, dati: pieno, oggi: giorno(2026, 11, 9, 10), cal: cal) == nil,
                  "Dopo la firma: senza spazio libero il controllo non propone un orario occupato")
    }

    // MARK: - Programmazione

    private static func programmazione(_ controlla: (Bool, String) -> Void) {
        let lunedi = routine(RoutineVera.idLunedi)
        controlla(RoutineVera.dovute([lunedi], adesso: giorno(2026, 11, 2, 9, 0), cal: cal).count == 1, "Programmazione: lunedì alle 9:00 «Il mio lunedì» è dovuta")
        controlla(RoutineVera.dovute([lunedi], adesso: giorno(2026, 11, 2, 8, 0), cal: cal).isEmpty, "Programmazione: lunedì alle 8:00 non ancora (e la settimana prima è passata)")
        var fatta = lunedi
        fatta.ultimoLancio = giorno(2026, 11, 2, 8, 45)
        controlla(RoutineVera.dovute([fatta], adesso: giorno(2026, 11, 2, 10, 0), cal: cal).isEmpty, "Programmazione: già lanciata stamattina, non torna")
        var vecchia = lunedi
        vecchia.ultimoLancio = giorno(2026, 10, 26, 9, 0)
        controlla(RoutineVera.dovute([vecchia], adesso: giorno(2026, 11, 4, 10, 0), cal: cal).count == 1, "Programmazione: Prisma chiuso lunedì, mercoledì si recupera")
        controlla(RoutineVera.dovute([vecchia], adesso: giorno(2026, 11, 5, 10, 0), cal: cal).isEmpty, "Programmazione: oltre tre giorni non si recupera più")
        var spenta = lunedi
        spenta.attiva = false
        controlla(RoutineVera.dovute([spenta], adesso: giorno(2026, 11, 2, 9, 0), cal: cal).isEmpty, "Programmazione: una routine spenta non parte")
        let fine = routine(RoutineVera.idFineMese)
        controlla(RoutineVera.dovute([fine], adesso: giorno(2026, 11, 30, 18, 0), cal: cal).count == 1, "Programmazione: l'ultimo giorno del mese alle 18 «Fine mese» è dovuta")
        controlla(RoutineVera.dovute([fine], adesso: giorno(2026, 11, 30, 12, 0), cal: cal).isEmpty, "Programmazione: il 30 a mezzogiorno non ancora")
        var fineVecchia = fine
        fineVecchia.ultimoLancio = giorno(2026, 10, 31, 18, 0)
        controlla(RoutineVera.dovute([fineVecchia], adesso: giorno(2026, 12, 2, 9, 0), cal: cal).count == 1, "Programmazione: il 2 dicembre si recupera la fine di novembre")
        controlla(RoutineVera.ultimaOccorrenza(fine.programmazione!, finoA: giorno(2027, 2, 28, 18, 0), cal: cal) == giorno(2027, 2, 28, 17, 30),
                  "Programmazione: febbraio finisce il 28")
        let firma = routine(RoutineVera.idDopoFirma)
        controlla(RoutineVera.dovute([firma], adesso: giorno(2026, 11, 2, 9, 0), cal: cal).isEmpty
                  && RoutineVera.perEvento(.dopoFirma, RoutineVera.pronte()).map(\.id) == [RoutineVera.idDopoFirma],
                  "Programmazione: «Dopo la firma» parte con l'evento, non con l'orologio")
    }

    // MARK: - Routine nuove: regole

    private static func nuoveARegole(_ controlla: (Bool, String) -> Void) {
        let oggi = oggiDemo
        guard let r = RoutineVera.daParole("Ogni volta che firmo, archivia il contratto e fissa il controllo a sei mesi", oggi: oggi) else {
            controlla(false, "Routine nuove: «ogni volta che firmo…» riconosciuta dalle regole")
            return
        }
        controlla(r.programmazione?.tipo == .dopoFirma && r.passi.map(\.tipo) == [.archiviaContratto, .fissaControllo] && r.passi.last?.mesi == 6,
                  "Routine nuove: dopo ogni firma, archivio e controllo a sei mesi: \(r.passi.map(\.tipo.rawValue))")
        controlla(r.titolo == "Quando firmo" && !r.pronta, "Routine nuove: il titolo dalle regole: \(r.titolo)")
        let d = DatiPrisma.demo()
        let lancio = RoutineVera.riconosci("ho firmato con Laura", routine: RoutineVera.pronte() + [r], clienti: noti(d), attivo: nil)
        controlla(lancio?.routine.id == r.id && lancio?.clienteId == "laura", "Routine nuove: la routine del consulente vince su quella pronta")
        let e = RoutineVera.esegui(r, richiesta: "ho firmato con Laura", contesto: ContestoRoutine(dati: d, oggi: oggi, clienteId: "laura"))
        controlla(e.passi.count == 2 && e.azioni.map(\.strumento) == [RegistroStrumenti.agendaNuovo], "Routine nuove: eseguita, il controllo resta da confermare")
        let settimana = RoutineVera.daParole("Ogni venerdì alle 17 guarda l'agenda e controlla le promesse", oggi: oggi)
        controlla(settimana?.programmazione == ProgrammazioneRoutine(tipo: .settimanale, giorno: 6, ora: 17, minuto: 0)
                  && settimana?.passi.map(\.tipo) == [.agendaSettimana, .promesseScadenze],
                  "Routine nuove: ogni venerdì alle 17, agenda e promesse: \(settimana?.passi.map(\.tipo.rawValue) ?? [])")
        controlla(RoutineVera.mesiDa("fissa il riesame tra 3 mesi") == 3 && RoutineVera.mesiDa("il controllo dopo un anno") == 12, "Routine nuove: i mesi letti dalla frase")
        controlla(RoutineVera.daParole("che bella giornata", oggi: oggi) == nil, "Routine nuove: senza passi del catalogo le regole non bastano (tocca a Qwen)")
    }

    // MARK: - Routine nuove: Qwen

    private static func nuoveConQwen(_ controlla: (Bool, String) -> Void) {
        let oggi = oggiDemo
        let richiesta = "quando firmo archivia tutto e metti un controllo fra tre mesi"
        let r = RoutineVera.leggi(#"{"titolo":"Dopo ogni firma","frase":"Vera, ho firmato","passi":[{"tipo":"archiviaContratto"},{"tipo":"cancellaCliente"},{"tipo":"fissaControllo"},{"tipo":"archiviaContratto"}]}"#,
                                  richiesta: richiesta, oggi: oggi)
        controlla(r?.passi.map(\.tipo) == [.archiviaContratto, .fissaControllo] && r?.passi.last?.mesi == 3,
                  "Routine con Qwen: solo i passi del catalogo, senza doppioni; i mesi dalla frase")
        controlla(r?.programmazione?.tipo == .dopoFirma && r?.titolo == "Dopo ogni firma" && r?.frase == "Vera, ho firmato", "Routine con Qwen: titolo e frase controllati, la programmazione dalle regole")
        controlla(RoutineVera.leggi(#"{"titolo":"Pulizia","passi":[{"tipo":"cancellaTutto"}]}"#, richiesta: "cancella tutto", oggi: oggi) == nil,
                  "Routine con Qwen: senza passi del catalogo la risposta si scarta")
        controlla(RoutineVera.leggi("Ecco la tua routine!", richiesta: richiesta, oggi: oggi) == nil, "Routine con Qwen: l'output non valido si scarta")
        let inventa = RoutineVera.leggi(#"{"titolo":"Controllo a 12 mesi","passi":[{"tipo":"fissaControllo"}]}"#, richiesta: "fissa sempre il controllo", oggi: oggi)
        controlla(inventa != nil && inventa?.titolo.contains("12") == false && inventa?.programmazione == nil && inventa?.passi.first?.mesi == RoutineVera.mesiControllo,
                  "Routine con Qwen: niente cifre inventate nel titolo, niente programmazione non detta")
        let m = RoutineVera.messaggi(richiesta)
        controlla(m.count == 2 && m[1].testo.contains("fissaControllo") && m[1].testo.contains(richiesta), "Routine con Qwen: il catalogo e la richiesta nel messaggio")
        controlla(RoutineVera.opzioni(ImpostazioniVera()).formato != nil && RoutineVera.opzioni(ImpostazioniVera()).temperatura == 0, "Routine con Qwen: JSON con lo schema, temperatura 0")
    }

    // MARK: - Archivio

    private static func archivio(_ controlla: (Bool, String) -> Void) {
        let d = DatiPrisma.demo()
        let oggi = oggiDemo
        guard let nuova = RoutineVera.daParole("Ogni volta che firmo, archivia il contratto e fissa il controllo a sei mesi", oggi: oggi) else {
            controlla(false, "Archivio: la routine nuova di prova")
            return
        }
        let esito = RoutineVera.esegui(routine(RoutineVera.idPrepara), richiesta: "prepara l'incontro con Marco", contesto: ContestoRoutine(dati: d, oggi: oggi, clienteId: "marco"))
        let a = ArchivioRoutine(routine: [nuova], esiti: [esito])
        let codificato = try? JSONEncoder().encode(a)
        let letto = codificato.flatMap { try? JSONDecoder().decode(ArchivioRoutine.self, from: $0) }
        controlla(letto == a, "Archivio: routine ed esiti tornano uguali dal JSON")
        controlla(a.tutte.count == 5 && a.tutte.prefix(4).allSatisfy(\.pronta), "Archivio: le pronte più quelle del consulente")
        let tollerante = #"{"routine":[{"id":"r-x","titolo":"Mista","passi":[{"tipo":"passoDelFuturo"},{"tipo":"agendaSettimana"}]},{"id":"r-y","passi":[{"tipo":"altroFuturo"}]},{"titolo":"senza id"}],"esiti":[{"rotto":true}]}"#
        let t = try? JSONDecoder().decode(ArchivioRoutine.self, from: Data(tollerante.utf8))
        controlla(t?.routine.count == 1 && t?.routine.first?.passi.map(\.tipo) == [.agendaSettimana] && t?.esiti.isEmpty == true,
                  "Archivio: letto con tolleranza (passi sconosciuti saltati, routine senza passi o senza id scartate)")
        var reg = ArchivioRoutine()
        for i in 0..<25 {
            var e = esito
            e.routineId = RoutineVera.idLunedi
            e.data = oggi.addingTimeInterval(Double(i) * 3600)
            reg = RoutineVera.registra(e, in: reg)
        }
        let lunedi = reg.routine.first { $0.id == RoutineVera.idLunedi }
        controlla(lunedi?.usata == 25 && lunedi?.ultimoLancio == oggi.addingTimeInterval(24 * 3600) && reg.esiti.count == ArchivioRoutine.esitiMassimi,
                  "Archivio: ogni lancio conta, gli esiti restano gli ultimi \(ArchivioRoutine.esitiMassimi)")
        let salva = RoutineVera.azioneSalva(nuova)
        let decodificatore = JSONDecoder()
        decodificatore.dateDecodingStrategy = .iso8601
        let tornata = salva.argomenti["routine"].flatMap { try? decodificatore.decode(RoutineVera.self, from: Data($0.utf8)) }
        controlla(salva.strumento == RoutineVera.strumentoSalva && tornata?.id == nuova.id && tornata?.passi == nuova.passi,
                  "Archivio: salvare una routine nuova passa dalla scheda «Conferma»")
    }

    // MARK: - Correzioni della revisione

    private static func correzioniRevisione(_ controlla: (Bool, String) -> Void) {
        let d = DatiPrisma.demo()
        let tutte = RoutineVera.pronte()
        // Una routine «dopo la firma» del consulente prende il posto della pronta: niente azioni doppie
        var mia = routine(RoutineVera.idDopoFirma)
        mia.id = "routine-mia-firma"
        mia.pronta = false
        let perFirma = RoutineVera.perEvento(.dopoFirma, tutte + [mia])
        controlla(perFirma.map(\.id) == [mia.id], "Revisione: con una sua routine «dopo la firma» parte solo quella: \(perFirma.map(\.id))")
        controlla(RoutineVera.perEvento(.dopoFirma, tutte).map(\.id) == [RoutineVera.idDopoFirma], "Revisione: senza, parte la pronta")
        // Con passi sul cliente non parte da sola all'ora
        let lunedi = RoutineVera.daParole("Ogni lunedì prepara la scaletta e guarda l'agenda della settimana", oggi: oggiDemo)
        controlla(lunedi != nil && lunedi?.programmazione == nil, "Revisione: una routine all'ora con passi sul cliente non resta programmata")
        // Frasi che non sono routine
        for frase in ["quali promesse scadono a fine mese", "Il resoconto dell'incontro con Marco l'ha firmato",
                      "prepara un messaggio per Federico per spostare l'appuntamento"] {
            let r = RoutineVera.riconosci(frase, routine: tutte, clienti: noti(d), attivo: nil)
            controlla(r == nil, "Revisione: «\(frase)» non lancia routine: \(r?.routine.id ?? "nil")")
        }
        let firma = RoutineVera.riconosci("Vera, ho firmato con Giulia", routine: tutte, clienti: noti(d), attivo: nil)
        controlla(firma?.routine.id == RoutineVera.idDopoFirma, "Revisione: «Vera, ho firmato con Giulia» lancia ancora Dopo la firma")
        let mese = RoutineVera.riconosci("la fine del mese", routine: tutte, clienti: noti(d), attivo: nil)
        controlla(mese?.routine.id == RoutineVera.idFineMese, "Revisione: «la fine del mese» lancia ancora Fine mese")
        // «Dopo la firma» ricorda la posizione (per il contratto trascinato dopo)
        let e = RoutineVera.esegui(routine(RoutineVera.idDopoFirma), richiesta: "ho firmato con Giulia",
                                   contesto: ContestoRoutine(dati: d, oggi: oggiDemo, clienteId: "giulia"))
        controlla(e.posizioneId == "pos-giulia-piano-previdenziale-integrativo", "Revisione: l'esito di «Dopo la firma» porta la posizione: \(e.posizioneId ?? "nil")")
    }
}
