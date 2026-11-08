import Foundation

/// Prova di «L'agenda che si organizza» (Vera/BRIEF.md, funzione 4) dentro `Prisma --prova-vera`: le regole che capiscono
/// la frase, Qwen controllato (giorni solo dalla frase, durata detta), la ricerca dei due orari (mai prima delle 9:30,
/// prima gli attaccati a un incontro in studio, dentro gli orari di lavoro, senza sovrapposizioni, limite dei riesami),
/// la bozza con i due orari, la scelta del cliente e lo spostamento in blocco con i messaggi da confermare.
/// Deterministica: la settimana del template (lunedì 2 – venerdì 6 novembre 2026, nessuna festività), oggi lunedì
/// 2 novembre alle 8:00, i clienti di prova di `DatiPrisma.demo()` con un'agenda scritta qui; niente rete, niente Qwen vero.
enum ProvaAgendaOrganizzaVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        regole(controlla)
        qwen(controlla)
        ricerca(controlla)
        bozzaEScelta(controlla)
        blocco(controlla)
    }

    // MARK: - Aiuti

    private static var cal: Calendar { MotorePianificazione.calendario }

    /// Il giorno di novembre 2026 a mezzanotte.
    private static func g(_ giorno: Int) -> Date {
        cal.startOfDay(for: cal.date(from: DateComponents(year: 2026, month: 11, day: giorno, hour: 12)) ?? Date(timeIntervalSince1970: 0))
    }

    private static func h(_ giorno: Int, _ ora: Int, _ minuti: Int = 0) -> Date {
        cal.date(bySettingHour: ora, minute: minuti, second: 0, of: g(giorno)) ?? g(giorno)
    }

    private static var oggi: Date { h(2, 8) }

    private static func app(_ id: String, _ cliente: String, _ titolo: String, _ inizio: Date, _ minuti: Int, _ luogo: String,
                            _ tipo: TipoAppuntamento) -> Appuntamento {
        Appuntamento(id: id, clienteId: cliente, titolo: titolo, inizio: inizio, durataMinuti: minuti, luogo: luogo, note: "",
                     stato: .pianificato, tipo: tipo)
    }

    /// La settimana del template (con Marco al posto di Federico, che tra i clienti di prova non c'è).
    private static var agenda: [Appuntamento] {
        [app("giulia-lun", "giulia", "Il punto sul progetto casa", h(2, 9, 30), 45, "In studio", .analisi),
         app("marco-lun", "marco", "Nuovi progetti di famiglia", h(2, 11), 60, "Videochiamata", .altro),
         app("sofia-lun", "sofia", "Rinnovo del consenso", h(2, 15), 30, "Telefonata", .telefonata),
         app("laura-mar", "laura", "Un progetto tutto suo", h(3, 10), 45, "In studio", .proposta),
         app("formazione", "", "Formazione Alleanza", h(3, 14, 30), 60, "Online", .altro),
         app("andrea-mer", "andrea", "Il nostro primo incontro", h(4, 15), 60, "In studio", .primoIncontro),
         app("sofia-gio", "sofia", "Uno sguardo ai prossimi mesi", h(5, 11, 30), 30, "Telefonata", .telefonata),
         app("giulia-gio", "giulia", "Firma del piano casa", h(5, 16), 60, "In studio", .firma),
         app("marco-ven", "marco", "Riesame con Marco", h(6, 9), 60, "In studio", .revisione)]
    }

    private static func contesto(_ elenco: [Appuntamento]? = nil, attivo: String? = nil) -> ContestoStrumenti {
        var d = DatiPrisma.demo()
        d.appuntamenti = elenco ?? agenda
        d.impostazioni.orari = OrariLavoro()
        return AgendaOrganizzaVera.contesto(d, oggi: oggi, attivo: attivo, cal: cal)
    }

    private static func ore(_ d: Date?) -> String {
        d.map { "\(Formati.dataBreve.string(from: $0)) \(Formati.ora.string(from: $0))" } ?? "nessuno"
    }

    // MARK: - Pacchetto

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let t = IstruzioniVera.testo("agenda-organizza") ?? ""
        controlla(t.contains("JSON") && t.contains("sposta_blocco"), "Agenda che si organizza: istruzioni nel pacchetto (Vera/Istruzioni/agenda-organizza.md)")
        controlla(AgendaOrganizzaVera.istruzioni.contains("JSON"), "Agenda che si organizza: istruzioni con il ripiego")
        let o = AgendaOrganizzaVera.opzioni(ImpostazioniVera())
        controlla(o.formato != nil && o.temperatura == 0 && !o.conLezioni, "Agenda che si organizza: Qwen risponde in JSON con lo schema fisso")
    }

    // MARK: - Regole

    private static func regole(_ controlla: (Bool, String) -> Void) {
        let x = contesto()
        let frase = "Trovami un'ora per il riesame di Marco entro giovedì, attaccata a un altro incontro in studio"
        let r = AgendaOrganizzaVera.interpreta(frase, contesto: x)
        controlla(r?.intento == .cerca && r?.clienteId == "marco" && r?.entro == g(5),
                  "Agenda che si organizza: «trovami un'ora… entro giovedì» → cerca, Marco, entro giovedì 5 (\(ore(r?.entro)))")
        controlla(r?.durataMinuti == 60 && r?.attaccato == true && r?.tipo == .revisione && r?.modo == .studio,
                  "Agenda che si organizza: un'ora, attaccata, riesame in studio")
        controlla(r?.daSpostare == "marco-ven", "Agenda che si organizza: il riesame di venerdì è quello da sostituire (\(r?.daSpostare ?? "nessuno"))")
        controlla(r.map { AgendaOrganizzaVera.domanda($0, oggi: oggi, cal: cal) == nil && !AgendaOrganizzaVera.serveQwen($0, oggi: oggi, cal: cal) } ?? false,
                  "Agenda che si organizza: richiesta completa, niente Qwen")

        let tel = AgendaOrganizzaVera.interpreta("Trovami mezz'ora per una telefonata con Sofia entro mercoledì", contesto: x)
        controlla(tel?.modo == .telefonata && tel?.tipo == .telefonata && tel?.durataMinuti == 30 && tel?.clienteId == "sofia" && tel?.entro == g(4),
                  "Agenda che si organizza: telefonata di mezz'ora con Sofia entro mercoledì")

        let ignoto = AgendaOrganizzaVera.interpreta("Trovami un'ora per il riesame di Federico entro giovedì", contesto: x)
        controlla(ignoto?.clienteId == nil && ignoto?.nomeDetto == "Federico"
                  && (ignoto.flatMap { AgendaOrganizzaVera.domanda($0, oggi: oggi, cal: cal) } ?? "").contains("Federico"),
                  "Agenda che si organizza: un nome che non è tra i clienti si chiede, non si indovina")

        // Due Bianchi tra i clienti, aperta Giulia Rossi con un riesame in agenda: «di bianchi» non sceglie il cliente aperto
        // (né il suo riesame da spostare), si chiede quale Bianchi
        var dd = DatiPrisma.demo()
        dd.clienti.append(Cliente(id: "paolo-b", nome: "Paolo Bianchi", iniziali: "PB", tinta: .blu, tema: "", email: "", telefono: "",
                                  preferito: false, nota: "", creatoIl: g(2)))
        dd.appuntamenti = agenda + [app("giulia-rie", "giulia", "Riesame con Giulia", h(6, 15), 60, "In studio", .revisione)]
        dd.impostazioni.orari = OrariLavoro()
        let xb = AgendaOrganizzaVera.contesto(dd, oggi: oggi, attivo: "giulia", cal: cal)
        let dueB = AgendaOrganizzaVera.interpreta("Trovami un'ora per il riesame di bianchi entro giovedì", contesto: xb)
        let domandaB = dueB.flatMap { AgendaOrganizzaVera.domanda($0, oggi: oggi, cal: cal) } ?? ""
        controlla(dueB?.clienteId == nil && dueB?.daSpostare == nil && domandaB.contains("Marco Bianchi") && domandaB.contains("Paolo Bianchi"),
                  "Agenda che si organizza: con due Bianchi non si usa il cliente aperto, si chiede quale (\(dueB?.clienteId ?? "nessuno"), \(domandaB))")
        let dueBQwen = AgendaOrganizzaVera.leggi(#"{"intento":"cerca","modo":"studio","tipo":"revisione"}"#,
                                                 frase: "Trovami un'ora per il riesame di bianchi entro giovedì", contesto: xb)
        controlla(dueBQwen?.clienteId == nil && dueBQwen?.daSpostare == nil
                  && (dueBQwen.flatMap { AgendaOrganizzaVera.domanda($0, oggi: oggi, cal: cal) } ?? "").contains("Paolo Bianchi"),
                  "Agenda che si organizza: anche dopo Qwen, due Bianchi non passano al cliente aperto (\(dueBQwen?.clienteId ?? "nessuno"))")

        let b = AgendaOrganizzaVera.interpreta("Libera giovedì, sposta tutto a venerdì", contesto: x)
        controlla(b?.intento == .spostaBlocco && b?.daGiorno == g(5) && b?.aGiorno == g(6),
                  "Agenda che si organizza: «libera giovedì, sposta tutto a venerdì» → da giovedì 5 a venerdì 6")
        let mezzo = AgendaOrganizzaVera.interpreta("Liberami giovedì e sposta gli impegni", contesto: x)
        controlla(mezzo.map { AgendaOrganizzaVera.serveQwen($0, oggi: oggi, cal: cal) } ?? false,
                  "Agenda che si organizza: senza il giorno di arrivo serve una domanda (o Qwen)")
        controlla(AgendaOrganizzaVera.riconosce("Quanto vale la polizza di Marco?") == nil
                  && AgendaOrganizzaVera.interpreta("Com'è andato l'incontro con Laura?", contesto: x) == nil,
                  "Agenda che si organizza: le altre domande non sono di questa funzione")
        // Partenza e arrivo dalle parole, non dall'ordine dei giorni nella frase
        let rovescio = AgendaOrganizzaVera.interpreta("Sposta tutto a venerdì, libera giovedì", contesto: x)
        controlla(rovescio?.intento == .spostaBlocco && rovescio?.daGiorno == g(5) && rovescio?.aGiorno == g(6),
                  "Agenda che si organizza: «sposta tutto a venerdì, libera giovedì» → da giovedì a venerdì (\(ore(rovescio?.daGiorno)) → \(ore(rovescio?.aGiorno)))")
        let daA = AgendaOrganizzaVera.interpreta("Sposta tutti gli appuntamenti a venerdì da giovedì", contesto: x)
        controlla(daA?.daGiorno == g(5) && daA?.aGiorno == g(6),
                  "Agenda che si organizza: «… a venerdì da giovedì» → da giovedì a venerdì (\(ore(daA?.daGiorno)) → \(ore(daA?.aGiorno)))")
        let ambiguo = AgendaOrganizzaVera.interpreta("Sposta tutto giovedì venerdì", contesto: x)
        controlla(ambiguo.map { AgendaOrganizzaVera.serveQwen($0, oggi: oggi, cal: cal) } ?? false,
                  "Agenda che si organizza: due giorni senza «a» né «da» non si indovinano (domanda o Qwen)")
        controlla(AgendaOrganizzaVera.durataDetta("un'ora e mezza") == 90 && AgendaOrganizzaVera.durataDetta("45 minuti") == 45
                  && AgendaOrganizzaVera.durataDetta("due ore") == 120, "Agenda che si organizza: durate dette a parole e in cifre")
    }

    // MARK: - Qwen

    private static func qwen(_ controlla: (Bool, String) -> Void) {
        let x = contesto()
        let frase = "Vedi se c'è un buco di 45 minuti per Laura prima di giovedì, vicino a un altro incontro"
        let json = #"{"intento":"cerca","cliente":"Laura","entro":"giovedì","durata_minuti":45,"attaccato":true,"modo":"studio","tipo":"incontro"}"#
        let r = AgendaOrganizzaVera.leggi(json, frase: frase, contesto: x)
        controlla(r?.clienteId == "laura" && r?.entro == g(5) && r?.durataMinuti == 45 && r?.attaccato == true && r?.conQwen == true,
                  "Agenda che si organizza: il JSON di Qwen diventa la richiesta (Laura, entro giovedì, 45 minuti)")
        let inventata = AgendaOrganizzaVera.leggi(json.replacingOccurrences(of: "45", with: "90"), frase: frase, contesto: x)
        controlla(inventata?.durataMinuti == 45, "Agenda che si organizza: una durata di Qwen che non è nella frase si scarta (\(inventata?.durataMinuti ?? 0))")
        controlla(AgendaOrganizzaVera.leggi("non è un JSON", frase: frase, contesto: x) == nil
                  && AgendaOrganizzaVera.leggi(#"{"intento":"altro"}"#, frase: frase, contesto: x) == nil,
                  "Agenda che si organizza: l'output non valido di Qwen si scarta")
        let blocco = AgendaOrganizzaVera.leggi(#"{"intento":"sposta_blocco","da_giorno":"giovedì","a_giorno":"venerdì"}"#,
                                               frase: "Giovedì non ci sono: porta tutto a venerdì", contesto: x)
        controlla(blocco?.intento == .spostaBlocco && blocco?.daGiorno == g(5) && blocco?.aGiorno == g(6),
                  "Agenda che si organizza: Qwen capisce lo spostamento in blocco detto in un altro modo")
        let dataFinta = AgendaOrganizzaVera.leggi(#"{"intento":"sposta_blocco","da_giorno":"giovedì","a_giorno":"2026-11-10"}"#,
                                                  frase: "Giovedì non ci sono: porta tutto a venerdì", contesto: x)
        controlla(dataFinta == nil, "Agenda che si organizza: un giorno di Qwen che non è nella frase fa scartare l'output")
        // Un numero della frase che non è una durata («entro il 30 novembre») non diventa la durata di Qwen
        let conData = AgendaOrganizzaVera.leggi(#"{"intento":"cerca","cliente":"Laura","durata_minuti":30,"modo":"studio","tipo":"incontro"}"#,
                                                frase: "Vedi se c'è un buco per Laura entro il 30 novembre", contesto: x)
        controlla(conData?.durataMinuti == 60, "Agenda che si organizza: il 30 di una data non è una durata (\(conData?.durataMinuti ?? 0) minuti)")
        // Un cliente che Qwen nomina ma la frase no non si accetta (e non sceglie l'impegno da spostare)
        let clienteFinto = AgendaOrganizzaVera.leggi(#"{"intento":"cerca","cliente":"Marco","modo":"studio","tipo":"revisione"}"#,
                                                     frase: "Trovami un buco per un riesame entro giovedì", contesto: x)
        controlla(clienteFinto != nil && clienteFinto?.clienteId == nil && clienteFinto?.daSpostare == nil,
                  "Agenda che si organizza: un cliente di Qwen che non è nella frase si scarta (\(clienteFinto?.clienteId ?? "nessuno"))")
        let clienteAperto = AgendaOrganizzaVera.leggi(#"{"intento":"cerca","cliente":"Marco","modo":"studio","tipo":"revisione"}"#,
                                                      frase: "Trovami un buco per un riesame entro giovedì", contesto: contesto(attivo: "laura"))
        controlla(clienteAperto?.clienteId == "laura", "Agenda che si organizza: senza un nome valido vale il cliente aperto")
        // Un cliente detto per nome accanto a un altro detto con nome e cognome resta valido
        let dueClienti = AgendaOrganizzaVera.leggi(#"{"intento":"cerca","cliente":"Laura","modo":"studio","tipo":"incontro"}"#,
                                                   frase: "Trovami un buco per Laura entro giovedì, prima del riesame di Marco Bianchi", contesto: x)
        controlla(dueClienti?.clienteId == "laura" && dueClienti?.nomeDetto == nil,
                  "Agenda che si organizza: «Laura» accanto a «Marco Bianchi» è la cliente Laura (\(dueClienti?.clienteId ?? dueClienti?.nomeDetto ?? "nessuno"))")
        let m = AgendaOrganizzaVera.messaggi(frase, oggi: oggi)
        controlla(m.count == 2 && m[1].testo.contains(frase) && m[1].testo.contains("2 novembre 2026"),
                  "Agenda che si organizza: a Qwen vanno solo la frase e la data di oggi")
    }

    // MARK: - Ricerca

    private static func ricerca(_ controlla: (Bool, String) -> Void) {
        let x = contesto()
        let orari = OrariLavoro()
        let r = RichiestaOrari(intento: .cerca, clienteId: "marco", entro: g(5), durataMinuti: 60, attaccato: true, modo: .studio,
                               tipo: .revisione, daSpostare: "marco-ven")
        let esito = AgendaOrganizzaVera.cerca(r, contesto: x)
        let p = esito.proposte
        controlla(p.count == 2, "Agenda che si organizza: due orari proposti (\(p.count))")
        controlla(p.first?.inizio == h(3, 11) && p.first?.etichetta == "subito dopo Laura",
                  "Agenda che si organizza: martedì alle 11:00, subito dopo Laura (\(ore(p.first?.inizio)), \(p.first?.etichetta ?? ""))")
        controlla(p.count > 1 && p[1].inizio == h(4, 16, 30) && p[1].vicinanza == .dopo && p[1].vicino == "andrea-mer",
                  "Agenda che si organizza: il secondo in un altro giorno, attaccato ad Andrea (\(ore(p.count > 1 ? p[1].inizio : nil)))")
        controlla(esito.nota == nil && p.allSatisfy { $0.attaccato }, "Agenda che si organizza: tutti attaccati, nessuna nota")
        // Nessuna sovrapposizione (con il margine), dentro gli orari, mai prima delle 9:30, entro giovedì
        let altri = agenda.filter { $0.id != "marco-ven" }
        let puliti = p.allSatisfy { o in
            let a = Appuntamento(id: "prova", clienteId: "marco", titolo: "", inizio: o.inizio, durataMinuti: 60, luogo: "In studio", note: "", stato: .pianificato)
            return MotorePianificazione.sovrapposti(a, in: altri, margine: orari.margineMinuti).isEmpty
                && !MotorePianificazione.fuoriOrario(a, orari: orari, cal: cal)
                && AgendaOrganizzaVera.minuti(o.inizio, cal: cal) >= AgendaOrganizzaVera.primaOraClienti
                && o.inizio < g(6)
        }
        controlla(puliti, "Agenda che si organizza: niente sovrapposizioni, dentro gli orari, dalle 9:30, entro giovedì")
        controlla(p.count < 2 || !(p[0].inizio < p[1].fine && p[1].inizio < p[0].fine), "Agenda che si organizza: i due orari non si sovrappongono tra loro")
        let testo = AgendaOrganizzaVera.risposta(esito, oggi: oggi, cal: cal)
        controlla(testo.contains("subito dopo Laura") && testo.contains("11:00") && testo.contains("una volta sola"),
                  "Agenda che si organizza: la risposta in chat dice gli orari e perché: \(testo)")

        // Mai prima delle 9:30, anche con la mattina che comincia alle 9:00
        let vuota = AgendaOrganizzaVera.cerca(RichiestaOrari(intento: .cerca, clienteId: "laura", entro: g(3), modo: .videochiamata),
                                              appuntamenti: [], clienti: x.clienti, orari: orari, oggi: oggi, cal: cal)
        controlla(vuota.proposte.first?.inizio == h(3, 9, 30), "Agenda che si organizza: mai prima delle 9:30 (\(ore(vuota.proposte.first?.inizio)))")
        controlla(vuota.proposte.count == 2 && vuota.proposte[1].inizio == h(3, 10, 30),
                  "Agenda che si organizza: con un solo giorno, il secondo orario dopo il primo, senza sovrapporsi")

        // Attaccato chiesto ma nessun incontro in studio: i primi liberi, e lo dice
        let senzaStudio = AgendaOrganizzaVera.cerca(RichiestaOrari(intento: .cerca, clienteId: "laura", entro: g(4), attaccato: true),
                                                    appuntamenti: [], clienti: x.clienti, orari: orari, oggi: oggi, cal: cal)
        controlla(senzaStudio.proposte.count == 2 && senzaStudio.nota?.contains("attaccato") == true,
                  "Agenda che si organizza: senza incontri in studio propone i primi liberi e lo dice")
        controlla(senzaStudio.proposte.count == 2 && !Calendar.current.isDate(senzaStudio.proposte[0].inizio, inSameDayAs: senzaStudio.proposte[1].inizio),
                  "Agenda che si organizza: i due orari, se si può, in giorni diversi")

        // Entro oggi: non resta tempo (si propone da domani)
        let tardi = AgendaOrganizzaVera.cerca(RichiestaOrari(intento: .cerca, entro: g(2)), contesto: x)
        controlla(tardi.proposte.isEmpty && tardi.nota != nil, "Agenda che si organizza: «entro oggi» non lascia giorni utili e lo dice")

        // Il limite dei riesami al giorno: martedì ne ha già uno e il limite è uno
        var unoAlGiorno = OrariLavoro()
        unoAlGiorno.riesamiAlGiorno = 1
        let conRiesame = [app("riesame-mar", "sofia", "Riesame con Sofia", h(3, 16), 60, "In studio", .revisione)]
        let limite = AgendaOrganizzaVera.cerca(RichiestaOrari(intento: .cerca, clienteId: "laura", entro: g(4), tipo: .revisione),
                                               appuntamenti: conRiesame, clienti: x.clienti, orari: unoAlGiorno, oggi: oggi, cal: cal)
        controlla(!limite.proposte.isEmpty && limite.proposte.allSatisfy { !cal.isDate($0.inizio, inSameDayAs: g(3)) },
                  "Agenda che si organizza: il limite dei riesami al giorno vale anche qui")

        // Il weekend e i giorni non lavorativi si saltano
        let weekend = AgendaOrganizzaVera.cerca(RichiestaOrari(intento: .cerca, dal: g(7), entro: g(8)), contesto: x)
        controlla(weekend.proposte.isEmpty, "Agenda che si organizza: sabato e domenica non si propongono")

        // Il luogo: telefonate e videochiamate non contano come incontri in studio
        controlla(AgendaOrganizzaVera.modo(agenda[1]) == .videochiamata && AgendaOrganizzaVera.modo(agenda[2]) == .telefonata
                  && AgendaOrganizzaVera.modo(app("f", "giulia", "Firma", h(5, 10), 30, "", .firma)) == .studio,
                  "Agenda che si organizza: il luogo dell'incontro (studio, videochiamata, telefonata)")
    }

    // MARK: - Bozza e scelta

    private static func bozzaEScelta(_ controlla: (Bool, String) -> Void) {
        let x = contesto()
        guard let marco = x.clienti.first(where: { $0.id == "marco" }) else {
            controlla(false, "Agenda che si organizza: Marco tra i clienti di prova")
            return
        }
        let r = RichiestaOrari(intento: .cerca, clienteId: "marco", entro: g(5), durataMinuti: 60, attaccato: true, modo: .studio,
                               tipo: .revisione, daSpostare: "marco-ven")
        let esito = AgendaOrganizzaVera.cerca(r, contesto: x)
        let bozza = AgendaOrganizzaVera.azioneBozza(esito, cliente: marco, impostazioni: x.impostazioni)
        let testo = bozza?.argomenti["testo"] ?? ""
        controlla(bozza?.strumento == RegistroStrumenti.messaggiPrepara && bozza?.app == .messaggi,
                  "Agenda che si organizza: i due orari al cliente sono una bozza di messaggi_prepara")
        controlla(testo.hasPrefix("Buongiorno Marco") && testo.contains("martedì 3 novembre alle 11:00") && testo.contains("mercoledì 4 novembre alle 16:30")
                  && testo.contains("riesame") && testo.contains("in studio"),
                  "Agenda che si organizza: il testo dice i due orari, il riesame e lo studio: \(testo)")
        controlla(CommentoVera.numeriConservati(bozza: esito.proposte.map { "\(Formati.dataLunga.string(from: $0.inizio)) \(Formati.ora.string(from: $0.inizio))" }.joined(separator: " "),
                                                testo: testo.components(separatedBy: " Un caro saluto")[0]),
                  "Agenda che si organizza: nella bozza solo le cifre degli orari trovati da Prisma")
        controlla(AgendaOrganizzaVera.azioneBozza(RicercaOrari(richiesta: r, proposte: [], nota: nil), cliente: marco, impostazioni: x.impostazioni) == nil,
                  "Agenda che si organizza: senza orari nessuna bozza")

        if let primo = esito.proposte.first {
            let scelta = AgendaOrganizzaVera.azioneScelta(primo, richiesta: r, cliente: marco, appuntamenti: x.appuntamenti)
            controlla(scelta.strumento == RegistroStrumenti.agendaSposta && scelta.argomenti["appuntamento"] == "marco-ven"
                      && scelta.argomenti["inizio"] == RegistroStrumenti.isoData(h(3, 11)) && scelta.argomenti["prima"] == RegistroStrumenti.isoData(h(6, 9))
                      && scelta.avviso == nil,
                      "Agenda che si organizza: la scelta del cliente sposta il riesame di venerdì (da confermare)")
            var nuovo = r
            nuovo.daSpostare = nil
            let fissa = AgendaOrganizzaVera.azioneScelta(primo, richiesta: nuovo, cliente: marco, appuntamenti: x.appuntamenti)
            controlla(fissa.strumento == RegistroStrumenti.agendaNuovo && fissa.argomenti["tipo"] == TipoAppuntamento.revisione.rawValue
                      && fissa.argomenti["durata"] == "60" && fissa.argomenti["luogo"] == "In studio",
                      "Agenda che si organizza: senza un impegno da sostituire, la scelta ne fissa uno nuovo")
        } else {
            controlla(false, "Agenda che si organizza: c'è un orario da scegliere")
        }

        // L'impegno da sostituire dura 90 minuti: la ricerca e il controllo della scelta usano la sua durata
        let lungo = agenda.map { a -> Appuntamento in
            a.id == "marco-ven" ? app("marco-ven", "marco", "Riesame con Marco", h(6, 9), 90, "In studio", .revisione) : a
        }
        let x90 = contesto(lungo)
        let esito90 = AgendaOrganizzaVera.cerca(r, contesto: x90)
        controlla(!esito90.proposte.isEmpty && esito90.proposte.allSatisfy { Int($0.fine.timeIntervalSince($0.inizio) / 60) == 90 },
                  "Agenda che si organizza: si cerca lo spazio per la durata dell'impegno che si sposta (90 minuti)")
        let altri90 = lungo.filter { $0.id != "marco-ven" }
        controlla(esito90.proposte.allSatisfy { o in
            let a = Appuntamento(id: "prova", clienteId: "marco", titolo: "", inizio: o.inizio, durataMinuti: 90, luogo: "In studio", note: "", stato: .pianificato)
            return MotorePianificazione.sovrapposti(a, in: altri90, margine: OrariLavoro().margineMinuti).isEmpty
        }, "Agenda che si organizza: i 90 minuti dell'impegno spostato non si sovrappongono a niente")
        // La proposta era di un'ora (11:00-12:00), ma l'impegno che si sposta dura 90 minuti: alle 12:15 c'è un altro incontro
        let conMezzogiorno = lungo + [app("laura-mez", "laura", "Il punto con Laura", h(3, 12, 15), 30, "In studio", .altro)]
        let unOra = OrarioProposto(id: "o", inizio: h(3, 11), fine: h(3, 12), vicino: nil, vicinanza: nil, etichetta: "")
        let scelta90 = AgendaOrganizzaVera.azioneScelta(unOra, richiesta: r, cliente: marco, contesto: contesto(conMezzogiorno))
        controlla(scelta90.strumento == RegistroStrumenti.agendaSposta && scelta90.avviso != nil,
                  "Agenda che si organizza: spostando un impegno di 90 minuti la sovrapposizione delle 12:15 si segnala")
        // Il margine degli orari di lavoro vale anche nel controllo della scelta: alle 12:05 l'incontro non tocca la fine ma il margine sì
        let conMargine = agenda + [app("laura-mar2", "laura", "Il punto con Laura", h(3, 12, 5), 30, "In studio", .altro)]
        let sceltaMargine = AgendaOrganizzaVera.azioneScelta(unOra, richiesta: r, cliente: marco, contesto: contesto(conMargine))
        controlla(sceltaMargine.avviso != nil, "Agenda che si organizza: la scelta controlla anche il margine degli orari di lavoro")
    }

    // MARK: - Spostamento in blocco

    private static func blocco(_ controlla: (Bool, String) -> Void) {
        let x = contesto()
        let orari = OrariLavoro()
        let s = AgendaOrganizzaVera.spostaBlocco(da: g(5), a: g(6), appuntamenti: agenda, orari: orari, oggi: oggi, cal: cal)
        controlla(s.mosse.count == 2 && s.mosse.allSatisfy { $0.stessaOra } && s.restano.isEmpty,
                  "Agenda che si organizza: giovedì → venerdì, i due impegni alla stessa ora (\(s.mosse.map { ore($0.inizio) }))")
        controlla(s.mosse.first?.appuntamentoId == "sofia-gio" && s.mosse.first?.inizio == h(6, 11, 30) && s.mosse.last?.inizio == h(6, 16),
                  "Agenda che si organizza: Sofia venerdì alle 11:30, Giulia venerdì alle 16:00")
        let azioni = AgendaOrganizzaVera.azioni(s, clienti: x.clienti, impostazioni: x.impostazioni, cal: cal)
        controlla(azioni.map(\.strumento) == [RegistroStrumenti.agendaSposta, RegistroStrumenti.messaggiPrepara, RegistroStrumenti.agendaSposta, RegistroStrumenti.messaggiPrepara],
                  "Agenda che si organizza: per ogni impegno lo spostamento e il messaggio al cliente, tutto da confermare")
        controlla(azioni.first?.argomenti["appuntamento"] == "sofia-gio" && azioni.first?.argomenti["inizio"] == RegistroStrumenti.isoData(h(6, 11, 30))
                  && azioni.first?.argomenti["prima"] == RegistroStrumenti.isoData(h(5, 11, 30)),
                  "Agenda che si organizza: gli argomenti dello spostamento come quelli di agenda_sposta_impegno")
        let msg = azioni.count > 1 ? azioni[1].argomenti["testo"] ?? "" : ""
        controlla(msg.contains("Sofia") && msg.contains("venerdì 6 novembre") && msg.contains("11:30") && azioni.count > 1 && azioni[1].argomenti["scopo"] == "spostamento",
                  "Agenda che si organizza: il messaggio a Sofia dice il nuovo giorno e l'ora: \(msg)")
        let scheda = AgendaOrganizzaVera.scheda(azioni, richiesta: "Libera giovedì, sposta tutto a venerdì", conQwen: false)
        controlla(scheda.stato == .daConfermare && scheda.attive.count == 4 && scheda.origine == .regole,
                  "Agenda che si organizza: la scheda «Conferma» aspetta il consulente")
        let detto = AgendaOrganizzaVera.risposta(s, oggi: oggi, cal: cal)
        controlla(detto.contains("due impegni") && detto.contains("stessa ora") && detto.contains("avvisare"),
                  "Agenda che si organizza: la risposta dello spostamento: \(detto)")

        // Venerdì alle 16 è occupato: Giulia va al primo orario libero (14:30) e la scheda lo segnala
        let pieno = agenda + [app("laura-ven", "laura", "Il piano di Laura", h(6, 16), 60, "In studio", .proposta)]
        let s2 = AgendaOrganizzaVera.spostaBlocco(da: g(5), a: g(6), appuntamenti: pieno, orari: orari, oggi: oggi, cal: cal)
        let giulia = s2.mosse.first { $0.appuntamentoId == "giulia-gio" }
        controlla(giulia?.inizio == h(6, 14, 30) && giulia?.stessaOra == false,
                  "Agenda che si organizza: stessa ora occupata → primo orario libero (\(ore(giulia?.inizio)))")
        let a2 = AgendaOrganizzaVera.azioni(s2, clienti: x.clienti, impostazioni: x.impostazioni, cal: cal)
        controlla(a2.first { $0.argomenti["appuntamento"] == "giulia-gio" && $0.strumento == RegistroStrumenti.agendaSposta }?.avviso != nil,
                  "Agenda che si organizza: lo spostamento non alla stessa ora ha l'avvertenza")

        // Mai prima delle 9:30: un impegno delle 9:00 con un cliente va alle 9:30
        let presto = [app("caffe", "marco", "Caffè con Marco", h(5, 9), 30, "In studio", .altro)]
        let s3 = AgendaOrganizzaVera.spostaBlocco(da: g(5), a: g(6), appuntamenti: presto, orari: orari, oggi: oggi, cal: cal)
        controlla(s3.mosse.first?.inizio == h(6, 9, 30) && s3.mosse.first?.stessaOra == false,
                  "Agenda che si organizza: nello spostamento mai prima delle 9:30 (\(ore(s3.mosse.first?.inizio)))")

        // Non ci sta: un impegno di cinque ore
        let lungo = [app("lungo", "laura", "Giornata di lavoro con Laura", h(5, 9, 30), 300, "In studio", .analisi)]
        let s4 = AgendaOrganizzaVera.spostaBlocco(da: g(5), a: g(6), appuntamenti: lungo, orari: orari, oggi: oggi, cal: cal)
        controlla(s4.mosse.isEmpty && s4.restano == ["Giornata di lavoro con Laura"] && s4.nota != nil,
                  "Agenda che si organizza: quello che non ci sta resta dov'è e lo si dice")

        // Arrivo di domenica, giorno uguale, giorno passato
        let domenica = AgendaOrganizzaVera.spostaBlocco(da: g(5), a: g(8), appuntamenti: agenda, orari: orari, oggi: oggi, cal: cal)
        controlla(domenica.mosse.isEmpty && domenica.nota?.contains("giorno di lavoro") == true,
                  "Agenda che si organizza: la domenica non è un giorno di arrivo")
        let stesso = AgendaOrganizzaVera.spostaBlocco(da: g(5), a: g(5), appuntamenti: agenda, orari: orari, oggi: oggi, cal: cal)
        controlla(stesso.mosse.isEmpty && stesso.nota != nil, "Agenda che si organizza: partenza e arrivo uguali non spostano niente")
        let passato = AgendaOrganizzaVera.spostaBlocco(da: g(5), a: g(2).addingTimeInterval(-86_400 * 3), appuntamenti: agenda, orari: orari, oggi: oggi, cal: cal)
        controlla(passato.mosse.isEmpty && passato.nota?.contains("passato") == true, "Agenda che si organizza: non si sposta in un giorno passato")

        // I blocchi «Non disponibile» non si spostano
        let conBlocco = agenda + [app("blocco", "", "Non disponibile", h(5, 9, 30), 60, "", .nonDisponibile)]
        let s5 = AgendaOrganizzaVera.spostaBlocco(da: g(5), a: g(6), appuntamenti: conBlocco, orari: orari, oggi: oggi, cal: cal)
        controlla(!s5.mosse.contains { $0.appuntamentoId == "blocco" }, "Agenda che si organizza: i blocchi «Non disponibile» restano dove sono")

        // Dalla frase alla scheda
        if let r = AgendaOrganizzaVera.interpreta("Libera giovedì, sposta tutto a venerdì", contesto: x),
           let s6 = AgendaOrganizzaVera.spostaBlocco(r, contesto: x) {
            controlla(s6 == s, "Agenda che si organizza: dalla frase allo stesso spostamento")
        } else {
            controlla(false, "Agenda che si organizza: dalla frase allo spostamento")
        }
    }
}
