import Foundation

/// Prove di Messaggi, «Prisma scrive per te» (casi M1–M12, chiamate da `ProvaCalcoli.esegui()`, cioè da
/// `Prisma --prova-calcoli`): le occasioni per fonte (riepilogo, scadenza, compleanno, consenso, riesame, parcella),
/// la divisione «Da mandare oggi» / «Questa settimana», l'esclusione delle occasioni già coperte da un messaggio, ordine e
/// massimo per gruppo, i modelli fissi compilati (solo cifre della scheda, saluto, firma dai dati, lunghezze), la verifica
/// dei testi di Vera, gli indirizzi mailto: e sms: e i clienti di prova. Oggi fisso al 4 novembre 2026, a mezzogiorno.
/// Nomi, recapiti e importi sono DI PROVA.
enum ProvaCalcoliMessaggi {
    private static let cal = Calendar.current
    private static let oggi = AiutiProva.data(2026, 11, 4)

    private static func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }

    private static func cliente(_ id: String, _ nome: String, nascita: Date? = nil, email: String = "", telefono: String = "") -> Cliente {
        var c = Cliente(id: id, nome: nome, iniziali: Cliente.iniziali(di: nome), tinta: .blu, tema: "", email: email, telefono: telefono,
                        preferito: false, nota: "", creatoIl: d(2020, 1, 1))
        c.dataNascita = nascita
        return c
    }

    private static func dati(_ clienti: [Cliente], posizioni: [Posizione] = [], incontri: [Incontro] = [],
                             appuntamenti: [Appuntamento] = [], parcelle: [Parcella] = [], messaggi: [MessaggioCliente] = [],
                             impostazioni: Impostazioni = Impostazioni()) -> DatiPrisma {
        var x = DatiPrisma(clienti: clienti, appuntamenti: appuntamenti, attivita: [], posizioni: posizioni, incontri: incontri,
                           clienteAttivoId: clienti.first?.id ?? "", impostazioni: impostazioni)
        x.parcelle = parcelle
        x.messaggi = messaggi
        return x
    }

    private static func calcola(_ x: DatiPrisma, il giorno: Date = oggi) -> OccasioniMessaggi {
        MotoreOccasioniMessaggi.calcola(dati: x, oggi: giorno, cal: cal)
    }

    /// Un messaggio per un'occasione, nello stato dato e creato al momento dato.
    private static func messaggio(_ o: OccasioneMessaggio, stato: StatoMessaggio, il quando: Date) -> MessaggioCliente {
        var m = MessaggioCliente(clienteId: o.clienteId, occasioneId: o.id, origine: o.origine, canaleLavoro: o.canale, tono: .cordiale,
                                 canale: .mail, oggetto: o.oggetto, testo: "Testo di prova", cifre: o.cifre, autore: .modelloFisso,
                                 modello: nil, creatoIl: quando)
        m.stato = stato
        return m
    }

    static func esegui(_ verifica: VerificaCalcoli) {
        riepilogo(verifica)
        scadenze(verifica)
        compleanni(verifica)
        consensi(verifica)
        riesami(verifica)
        parcelle(verifica)
        ordine(verifica)
        modelliFissi(verifica)
        verificaVera(verifica)
        indirizzi(verifica)
        clientiDiProva(verifica)
    }

    // MARK: - M1 Riepilogo dell'incontro

    private static func incontroDiProva(_ giorno: Date, stato: Incontro.Stato = .concluso) -> Incontro {
        var i = Incontro(clienteId: "giulia", titolo: "Incontro di prova",
                         data: cal.date(bySettingHour: 9, minute: 30, second: 0, of: giorno) ?? giorno)
        i.id = "incontro-prova-\(MotoreOccasioniMessaggi.timbro(giorno, cal: cal))"
        i.stato = stato
        i.decisioni = "Aprire il piano di accumulo da 200 € al mese"
        i.prossimaAttivita = "Mandare il modulo firmato"
        i.prossimoIncontro = d(2026, 12, 3)
        return i
    }

    private static func riepilogo(_ verifica: VerificaCalcoli) {
        let giulia = cliente("giulia", "Giulia Rossi")
        let i = incontroDiProva(oggi)
        let x = dati([giulia], incontri: [i])
        let r = calcola(x)
        let o = r.oggi.first { $0.tipo == .riepilogoIncontro }
        verifica.vero("M1 Riepilogo: incontro concluso oggi alle 09:30 → «Da mandare oggi», «Incontro di stamattina alle 09:30»",
                      o?.perche == "Incontro di stamattina alle 09:30" && o?.titolo == "Il riepilogo dell'incontro di oggi"
                      && o?.id == "riepilogoIncontro-giulia-\(i.id)")
        verifica.vero("M1 Riepilogo: tra le cifre le decisioni, il prossimo passo e il prossimo incontro",
                      o?.valore(.decisioni) == i.decisioni && o?.valore(.prossimoPasso) == i.prossimaAttivita
                      && o?.valore(.prossimoIncontro) == Formati.dataEstesa.string(from: d(2026, 12, 3)))
        verifica.vero("M1 Riepilogo: un incontro in preparazione non è un riepilogo",
                      calcola(dati([giulia], incontri: [incontroDiProva(oggi, stato: .preparazione)])).nessuna)
        let tre = calcola(dati([giulia], incontri: [incontroDiProva(d(2026, 11, 2))])).tutte.first
        verifica.vero("M1 Riepilogo: l'incontro di due giorni fa va in «Questa settimana» («\(tre?.perche ?? "")»)",
                      tre?.gruppo == .settimana && tre?.perche == "Incontro del 2 novembre alle 09:30")
        verifica.vero("M1 Riepilogo: un incontro di dieci giorni fa non si propone più",
                      calcola(dati([giulia], incontri: [incontroDiProva(d(2026, 10, 25))])).nessuna)
        guard let o else { return verifica.vero("M1 Riepilogo: occasione trovata", false) }
        // Coperta da un messaggio: oggi resta con la spunta, domani esce; una bozza non copre
        let salvatoOggi = messaggio(o, stato: .salvato, il: cal.date(bySettingHour: 10, minute: 42, second: 0, of: oggi) ?? oggi)
        var conMessaggio = x
        conMessaggio.messaggi = [salvatoOggi]
        let oggiCoperta = calcola(conMessaggio).occasione(o.id)
        verifica.vero("M1 Riepilogo: con il messaggio salvato oggi resta nell'elenco, segnata come preparata",
                      oggiCoperta?.preparatoIl == salvatoOggi.creatoIl)
        verifica.vero("M1 Riepilogo: il giorno dopo il messaggio salvato la toglie",
                      calcola(conMessaggio, il: d(2026, 11, 5)).occasione(o.id) == nil)
        let ieri = calcola(x, il: d(2026, 11, 5)).occasione(o.id)
        verifica.vero("M1 Riepilogo: senza messaggio, il giorno dopo è «Incontro di ieri alle 09:30», ancora da mandare oggi",
                      ieri?.perche == "Incontro di ieri alle 09:30" && ieri?.gruppo == .oggi)
        var conBozza = x
        conBozza.messaggi = [messaggio(o, stato: .bozza, il: d(2026, 11, 4))]
        verifica.vero("M1 Riepilogo: una bozza non copre l'occasione",
                      calcola(conBozza, il: d(2026, 11, 5)).occasione(o.id)?.preparatoIl == nil
                      && calcola(conBozza, il: d(2026, 11, 5)).occasione(o.id) != nil)
        var aperto = messaggio(o, stato: .apertoInMail, il: d(2026, 11, 4))
        aperto.occasioneId = "un-id-di-prima"
        var conAperto = x
        conAperto.messaggi = [aperto]
        verifica.vero("M1 Riepilogo: un messaggio aperto in Mail per lo stesso incontro la copre anche con un altro id",
                      calcola(conAperto, il: d(2026, 11, 5)).occasione(o.id) == nil)
    }

    // MARK: - M2 Scadenze

    private static func polizza(_ id: String, scade giorni: Int, stato: StatoPosizione = .inEssere) -> Posizione {
        var p = AiutiProva.posizione("Infortuni famiglia", .protezione, 0, canale: .alleanza)
        p.id = id
        p.clienteId = "marco"
        p.stato = stato
        p.scadenza = cal.date(byAdding: .day, value: giorni, to: oggi)
        p.premio = 320
        p.frequenza = .annuale
        return p
    }

    private static func scadenze(_ verifica: VerificaCalcoli) {
        let marco = cliente("marco", "Marco Bianchi")
        let r = calcola(dati([marco], posizioni: [polizza("p45", scade: 45), polizza("p30", scade: 30), polizza("p3", scade: 3),
                                                   polizza("p46", scade: 46), polizza("pieri", scade: -1),
                                                   polizza("pchiusa", scade: 20, stato: .chiusa)]))
        let tutte = r.tutte.filter { $0.tipo == .scadenzaPosizione }
        func di(_ id: String) -> OccasioneMessaggio? { tutte.first { $0.origine.riferimento.hasPrefix(id + "-") } }
        verifica.vero("M2 Scadenza: a 45 giorni il primo giorno della soglia, in «Da mandare oggi» («\(di("p45")?.perche ?? "")»)",
                      di("p45")?.gruppo == .oggi && di("p45")?.perche == "Scadenza tra 45 giorni"
                      && di("p45")?.titolo == "«Infortuni famiglia» scade il 19 dicembre" && di("p45")?.canale == .alleanza)
        verifica.vero("M2 Scadenza: a 30 giorni in «Questa settimana», a 3 giorni di nuovo oggi",
                      di("p30")?.gruppo == .settimana && di("p30")?.perche == "Scadenza tra 30 giorni" && di("p3")?.gruppo == .oggi
                      && di("p3")?.priorita == .alta)
        verifica.vero("M2 Scadenza: oltre la soglia, già scaduta o chiusa niente",
                      di("p46") == nil && di("pieri") == nil && di("pchiusa") == nil && tutte.count == 3)
        verifica.vero("M2 Scadenza: tra le cifre data, giorni, canale e premio",
                      di("p45")?.valore(.scadenza) == "19 dicembre 2026" && di("p45")?.valore(.giorniAllaScadenza) == "45"
                      && di("p45")?.valore(.canale) == "Alleanza" && di("p45")?.valore(.premio)?.hasSuffix("· annuale") == true)
        var imp = Impostazioni()
        imp.messaggi.giorniScadenza = 30
        let corta = calcola(dati([marco], posizioni: [polizza("p45", scade: 45), polizza("p30", scade: 30)], impostazioni: imp)).tutte
            .filter { $0.tipo == .scadenzaPosizione }
        verifica.vero("M2 Scadenza: con l'anticipo a 30 giorni la polizza a 45 non c'è e quella a 30 è da mandare oggi",
                      corta.count == 1 && corta.first?.gruppo == .oggi && corta.first?.valore(.giorniAllaScadenza) == "30")
    }

    // MARK: - M3 Compleanni

    private static func compleanni(_ verifica: VerificaCalcoli) {
        let r = calcola(dati([cliente("anna", "Anna Verdi", nascita: d(1979, 11, 4)), cliente("chiara", "Chiara Marino", nascita: d(1979, 11, 5)),
                              cliente("bruno", "Bruno Neri", nascita: d(1980, 11, 8)), cliente("dario", "Dario Gialli", nascita: d(1980, 11, 11))]))
        func di(_ id: String) -> OccasioneMessaggio? { r.tutte.first { $0.clienteId == id && $0.tipo == .compleanno } }
        verifica.vero("M3 Compleanno: oggi e domani in «Da mandare oggi» («\(di("anna")?.perche ?? "")», «\(di("chiara")?.perche ?? "")»)",
                      di("anna")?.perche == "Oggi compie 47 anni" && di("chiara")?.perche == "Domani compie 47 anni"
                      && di("anna")?.gruppo == .oggi && di("chiara")?.gruppo == .oggi)
        verifica.vero("M3 Compleanno: fra quattro giorni in «Questa settimana» («\(di("bruno")?.perche ?? "")»), fra sette giorni no",
                      di("bruno")?.gruppo == .settimana && di("bruno")?.perche == "L'8 novembre compie 46 anni" && di("dario") == nil)
        verifica.vero("M3 Compleanno: mai commerciale, con l'età tra le cifre",
                      di("anna")?.commerciale == false && di("anna")?.valore(.eta) == "47 anni")
        let bisestile = calcola(dati([cliente("elena", "Elena Blu", nascita: d(2000, 2, 29))]), il: d(2027, 2, 28)).tutte.first
        verifica.vero("M3 Compleanno: nata il 29 febbraio, nel 2027 gli auguri il 28 («\(bisestile?.perche ?? "")»)",
                      bisestile?.perche == "Oggi compie 27 anni")
    }

    // MARK: - M5 Consensi

    private static func consensi(_ verifica: VerificaCalcoli) {
        var sofia = cliente("sofia", "Sofia Esposito")
        sofia.consensi.marketing = true
        sofia.consensi.dataMarketing = d(2024, 10, 4)
        var luca = cliente("luca", "Luca Galli")
        luca.consensi.marketing = true
        luca.consensi.dataMarketing = d(2024, 11, 20)
        var paola = cliente("paola", "Paola Riva")
        paola.consensi.privacy = true
        paola.consensi.dataPrivacy = d(2025, 1, 10)
        let senza = calcola(dati([sofia, luca, paola])).tutte.filter { $0.tipo == .consenso }
        func di(_ id: String) -> OccasioneMessaggio? { senza.first { $0.clienteId == id } }
        verifica.vero("M5 Consenso: commerciale dato 25 mesi fa (24 mesi di validità) → scaduto («\(di("sofia")?.perche ?? "")»)",
                      di("sofia")?.perche == "Consenso scaduto il 4 ottobre 2026" && di("sofia")?.inRitardo == true
                      && di("sofia")?.gruppo == .settimana && di("sofia")?.titolo == "Il consenso commerciale da rinnovare")
        verifica.vero("M5 Consenso: in scadenza entro 30 giorni («\(di("luca")?.perche ?? "")»)",
                      di("luca")?.perche == "Il consenso scade il 20 novembre 2026" && di("luca")?.inRitardo == false)
        verifica.vero("M5 Consenso: il consenso al trattamento non scade (senza informativa aggiornata niente)", di("paola") == nil)
        var imp = Impostazioni()
        imp.conformita.informativaAggiornataIl = d(2026, 6, 1)
        let conInformativa = calcola(dati([paola], impostazioni: imp)).tutte.first { $0.tipo == .consenso }
        verifica.vero("M5 Consenso: informativa aggiornata dopo la firma → da firmare di nuovo («\(conInformativa?.perche ?? "")»)",
                      conInformativa?.titolo == "L'informativa privacy da firmare di nuovo"
                      && conInformativa?.valore(.informativaAggiornata) == "1 giugno 2026")
    }

    // MARK: - M6 Riesami

    private static func riesami(_ verifica: VerificaCalcoli) {
        let laura = cliente("laura", "Laura Conti")
        var p = AiutiProva.posizione("Piano di prova", .risparmio, 10_000, canale: .indipendente)
        p.clienteId = "laura"
        var incontro = Incontro(clienteId: "laura", titolo: "Riesame di prova", data: d(2025, 9, 1))
        incontro.stato = .concluso
        let r = calcola(dati([laura], posizioni: [p], incontri: [incontro])).tutte.first { $0.tipo == .riesame }
        verifica.vero("M6 Riesame: un anno dall'ultimo incontro, niente in agenda → «Questa settimana» («\(r?.perche ?? "")»)",
                      r?.gruppo == .settimana && r?.perche == "Più di un anno dall'ultimo incontro, l'1 settembre 2025"
                      && r?.canale == .indipendente && r?.commerciale == true)
        let fissato = Appuntamento(id: "app-prova", clienteId: "laura", titolo: "Riesame", inizio: d(2026, 11, 20), durataMinuti: 60,
                                   luogo: "", note: "", stato: .pianificato)
        let conAppuntamento = calcola(dati([laura], posizioni: [p], incontri: [incontro], appuntamenti: [fissato]))
        verifica.vero("M6 Riesame: con un appuntamento in agenda niente messaggio",
                      !conAppuntamento.tutte.contains { $0.tipo == .riesame })
    }

    // MARK: - M8 Parcelle

    private static func parcelle(_ verifica: VerificaCalcoli) {
        let anna = cliente("anna", "Anna Verdi")
        func parcella(_ id: String, stato: StatoParcella, data: Date, scadenza: Date? = nil, numero: String? = nil) -> Parcella {
            var p = Parcella(id: id, clienteId: "anna", data: data, righe: [RigaParcella(id: "\(id)-1", descrizione: "Consulenza", importo: 300)],
                             cal: cal)
            p.stato = stato
            p.numero = numero
            p.scadenza = scadenza
            return p
        }
        let r = calcola(dati([anna], parcelle: [
            parcella("nuova", stato: .emessa, data: d(2026, 11, 3), scadenza: d(2026, 12, 3), numero: "2026/014"),
            parcella("vecchia", stato: .emessa, data: d(2026, 10, 1), scadenza: d(2026, 10, 31), numero: "2026/011"),
            parcella("bozza", stato: .bozza, data: d(2026, 11, 4)),
            parcella("pagata", stato: .pagata, data: d(2026, 11, 2), numero: "2026/013"),
        ]))
        let invio = r.tutte.first { $0.origine.riferimento == "nuova-invio" }
        let sollecito = r.tutte.first { $0.origine.riferimento == "vecchia-sollecito" }
        verifica.vero("M8 Parcella: emessa ieri → da mandare oggi («\(invio?.titolo ?? "")», «\(invio?.perche ?? "")»)",
                      invio?.gruppo == .oggi && invio?.titolo == "La parcella n. 2026/014 da mandare" && invio?.perche == "Emessa ieri"
                      && invio?.canale == .indipendente && invio?.valore(.importo) == Formati.euroDecimali(300))
        verifica.vero("M8 Parcella: scaduta → promemoria in «Questa settimana» («\(sollecito?.perche ?? "")»)",
                      sollecito?.gruppo == .settimana && sollecito?.perche == "Scaduta il 31 ottobre 2026" && sollecito?.inRitardo == true)
        verifica.vero("M8 Parcella: bozze e pagate no", r.tutte.filter { $0.tipo == .parcella }.count == 2)
    }

    // MARK: - M7 Ordine, gruppi, massimo, id stabili

    private static func ordine(_ verifica: VerificaCalcoli) {
        var clienti = (0..<10).map { cliente("c\($0)", "Cliente \($0)", nascita: d(1979, 11, 4)) }
        clienti.append(cliente("giulia", "Giulia Rossi"))
        let x = dati(clienti, incontri: [incontroDiProva(oggi)])
        let a = calcola(x), b = calcola(x)
        verifica.vero("M7 Ordine: due calcoli danno le stesse occasioni con gli stessi id", a == b && a.tutte.map(\.id) == b.tutte.map(\.id))
        verifica("M7 Ordine: al massimo 8 occasioni per gruppo", Double(a.oggi.count), Double(RegoleMessaggi.massimoPerGruppo))
        verifica.vero("M7 Ordine: in testa il riepilogo dell'incontro (stessa priorità, prima per tipo)",
                      a.oggi.first?.tipo == .riepilogoIncontro)
        verifica.vero("M7 Ordine: i gruppi hanno solo le loro occasioni, in ordine di priorità",
                      a.oggi.allSatisfy { $0.gruppo == .oggi } && a.settimana.allSatisfy { $0.gruppo == .settimana }
                      && zip(a.oggi, a.oggi.dropFirst()).allSatisfy { coppia in coppia.0.priorita <= coppia.1.priorita })
        verifica.vero("M7 Ordine: in modalità cliente solo le sue", a.soloCliente("giulia").tutte.allSatisfy { $0.clienteId == "giulia" }
                      && a.soloCliente("giulia").tutte.count == 1)
    }

    // MARK: - M9 Modelli fissi

    /// Tutte le occasioni dei casi qui sopra, insieme, con i loro clienti.
    private static func campionario() -> (dati: DatiPrisma, occasioni: [OccasioneMessaggio]) {
        var sofia = cliente("sofia", "Sofia Esposito")
        sofia.consensi.marketing = true
        sofia.consensi.dataMarketing = d(2024, 10, 4)
        var paola = cliente("paola", "Paola Riva")
        paola.consensi.privacy = true
        paola.consensi.dataPrivacy = d(2025, 1, 10)
        var piano = AiutiProva.posizione("Piano di prova", .risparmio, 10_000)
        piano.clienteId = "laura"
        var vecchio = Incontro(clienteId: "laura", titolo: "Riesame di prova", data: d(2025, 9, 1))
        vecchio.stato = .concluso
        var parcella = Parcella(id: "nuova", clienteId: "anna", data: d(2026, 11, 3),
                                righe: [RigaParcella(id: "r1", descrizione: "Consulenza", importo: 1_250.5)], cal: cal)
        parcella.stato = .emessa
        parcella.numero = "2026/014"
        var scaduta = Parcella(id: "vecchia", clienteId: "anna", data: d(2026, 10, 1),
                               righe: [RigaParcella(id: "r2", descrizione: "Consulenza", importo: 300)], cal: cal)
        scaduta.stato = .emessa
        scaduta.numero = "2026/011"
        scaduta.scadenza = d(2026, 10, 31)
        var imp = Impostazioni()
        imp.conformita.informativaAggiornataIl = d(2026, 6, 1)
        let x = dati([cliente("giulia", "Giulia Rossi"), cliente("marco", "Marco ed Elena Bianchi"),
                      cliente("chiara", "Chiara Marino", nascita: d(1979, 11, 5)), sofia, paola, cliente("laura", "Laura Conti"),
                      cliente("anna", "Anna Verdi")],
                     posizioni: [polizza("p45", scade: 45), piano], incontri: [incontroDiProva(oggi), vecchio],
                     parcelle: [parcella, scaduta], impostazioni: imp)
        var occasioni = calcola(x).tutte
        // L'avviso di mercato (giro 7) non nasce dal motore: qui uno costruito a mano, per il suo modello fisso
        occasioni.append(OccasioneMessaggio(origine: OrigineMessaggio(tipo: .avvisoMercato, riferimento: "prova"), clienteId: "giulia",
                                            canale: .indipendente, gruppo: .settimana, titolo: "I mercati di oggi", perche: "Mercati in calo",
                                            oggetto: "I mercati di questi giorni",
                                            cifre: [CifraMessaggio(.avviso, "il fondo azionario è sceso del 4,2% in una settimana")],
                                            priorita: .media, data: oggi))
        // La prova del fuoco (giro 4) apre Messaggi su richiesta: una riga di prova con l'obiettivo e una senza
        let conObiettivo = RigaProvaFuoco(clienteId: "marco", nome: "Marco ed Elena Bianchi", telefono: "", obiettivoId: "ob-prova",
                                          titoloObiettivo: "Studi di Tommaso", coperturaOggi: 0.58, coperturaDopo: 0.44,
                                          perdita: 41_392, voci: [], collegateAssenti: false)
        occasioni.append(MotoreProvaFuoco.occasioneMessaggio(conObiettivo, scenario: .mercati(calo: 25), canale: .indipendente,
                                                             oggi: oggi, calendario: cal))
        let senzaObiettivo = RigaProvaFuoco(clienteId: "laura", nome: "Laura Conti", telefono: "", obiettivoId: nil,
                                            titoloObiettivo: nil, coperturaOggi: 0, coperturaDopo: 0,
                                            perdita: 12_500, voci: [], collegateAssenti: false)
        occasioni.append(MotoreProvaFuoco.occasioneMessaggio(senzaObiettivo, scenario: .tassi(punti: 2.5), canale: nil,
                                                             oggi: oggi, calendario: cal))
        // Il sollecito di una pratica dopo la firma («Luce» giro 3): il passo che manca, al cliente o per la compagnia
        for (passo, rif) in [("il primo premio", "pratica-prova-primoPremio"), ("l'emissione della polizza", "pratica-prova-polizzaEmessa")] {
            occasioni.append(OccasioneMessaggio(origine: OrigineMessaggio(tipo: .pratica, riferimento: rif), clienteId: "marco",
                                                canale: .alleanza, gruppo: .oggi, titolo: "Sollecito: «Infortuni famiglia»",
                                                perche: "Fermo da 9 giorni", oggetto: "La pratica di «Infortuni famiglia»",
                                                cifre: [CifraMessaggio(.posizione, "Infortuni famiglia"), CifraMessaggio(.passoPratica, passo),
                                                        CifraMessaggio(.canale, "Alleanza"), CifraMessaggio(.giorniPratica, "9")],
                                                priorita: .alta, data: oggi, inRitardo: true))
        }
        // Un traguardo da festeggiare («Luce» giro 5): il fatto, mai una cifra in più né una proposta
        occasioni.append(OccasioneMessaggio(origine: OrigineMessaggio(tipo: .traguardo, riferimento: "obiettivoRaggiunto-sofia-prova"),
                                            clienteId: "sofia", canale: nil, gruppo: .festeggiare,
                                            titolo: "Ha raggiunto «Rendita integrativa»", perche: "Obiettivo raggiunto ieri",
                                            oggetto: "Ha raggiunto «Rendita integrativa»",
                                            cifre: [CifraMessaggio(.traguardo, "Ha raggiunto «Rendita integrativa»")],
                                            priorita: .alta, data: oggi))
        // I dati che mancano per un modulo («Luce» giro 10): solo i nomi dei dati, mai i valori
        let modello = ModelloModulo(id: "modulo-prova", titolo: "Proposta di polizza", tipo: .propostaPolizza,
                                    file: "modulo-prova.pdf", pagine: 1, campi: [])
        if let giulia = x.clienti.first(where: { $0.id == "giulia" }),
           let o = CompilatoreModuli.occasioneDatiMancanti(cliente: giulia, modello: modello, dati: [.iban, .cap], oggi: oggi) {
            occasioni.append(o)
        }
        // Una campagna («Luce» giro 12): il bisogno di Marco e due orari liberi, con le sole cifre di Marco
        let membro = MembroCampagna(clienteId: "marco", motivo: "«Piano Pensione» senza versamenti dal 3 ottobre 2025",
                                    cifre: [CifraMessaggio(.bisogno, "il fondo pensione è fermo dal 3 ottobre 2025"),
                                            CifraMessaggio(.ultimoVersamento, "3 ottobre 2025")],
                                    consenso: true, recapitoMail: true, recapitoMessaggi: true, giaContattato: nil,
                                    ultimaCampagna: nil, canaleLavoro: .alleanza, inclusoDiBase: true, anchein: [])
        let gruppo = GruppoCampagna(id: "previdenzaFerma", tipo: .previdenzaFerma, titolo: "Fondo pensione fermo da un anno",
                                    membri: [membro], nonValutati: 0, notaNonValutati: nil)
        occasioni.append(MotoreCampagne.occasione(gruppo: gruppo, membro: membro, campagnaId: "campagna-prova",
                                                  appuntamenti: [d(2026, 11, 10), d(2026, 11, 11)]))
        // La richiesta di presentazione (Clienti › Passaparola): il fatto di Sofia, mai cifre né nomi d'altri
        let momento = MomentoPerChiedere(id: "sofia-obiettivo-prova", clienteId: "sofia",
                                         fatto: "ha raggiunto «Rendita integrativa» ieri", riferimento: "obiettivo-prova",
                                         data: oggi)
        occasioni.append(MotorePassaparola.occasioneRichiesta(momento, cliente: sofia, posizioni: []))
        // Il messaggio detto nella nota vocale («Luce» giro 13): solo la cosa promessa, nessuna cifra in più
        if let giulia = x.clienti.first(where: { $0.id == "giulia" }) {
            let nota = NotaVocaleDiProva.inArrivo(x, oggi: oggi)
            if let p = nota.proposte.first(where: { $0.tipo == .messaggio }) {
                occasioni.append(ApplicaNotaVocale.occasioneMessaggio(p, nota: nota, cliente: giulia))
            }
        }
        // L'aggiornamento del sinistro di prova di Marco («Luce» giro 15): titolo, fase e ultimo fatto, mai polizza né importi
        if let marco = x.clienti.first(where: { $0.id == "marco" }),
           let sinistro = SinistriDiProva.sinistri(oggi: oggi).first(where: { $0.id == SinistriDiProva.idMarco }) {
            occasioni.append(MotoreSinistri.occasione(sinistro, cliente: marco, consulente: "Denis", oggi: oggi))
        }
        // La richiesta del documento d'identità della notte («Luce» giro 14), su Giulia, con una scadenza fra 20 giorni
        if let giulia = x.clienti.first(where: { $0.id == "giulia" }),
           let scadenza = Calendar.current.date(byAdding: .day, value: 20, to: oggi) {
            occasioni.append(MotoreNotte.occasioneDocumento(giulia, scadenza: scadenza, scaduto: false, documento: "Carta d'identità",
                                                            riferimento: "campionario-documento"))
        }
        return (x, occasioni)
    }

    private static func modelliFissi(_ verifica: VerificaCalcoli) {
        let (x, occasioni) = campionario()
        let tipi = Set(occasioni.map(\.tipo))
        // Le bozze di «Fallo tu» (`.richiestaVera`) non nascono da un'occasione: le scrive Vera su richiesta (FalloTuShell)
        verifica.vero("M9 Modelli: il campionario ha tutti i tipi tranne (forse) l'occasione dell'Agenda (\(tipi.count) tipi)",
                      tipi.isSuperset(of: Set(TipoOccasioneMessaggio.allCases).subtracting([.occasioneAgenda, .richiestaVera])))
        var sbagliati: [String] = []
        for o in occasioni {
            guard let c = x.clienti.first(where: { $0.id == o.clienteId }) else { sbagliati.append("cliente di \(o.id)"); continue }
            for tono in TonoMessaggio.allCases {
                for canale in CanaleMessaggio.allCases {
                    let firma = ModelliMessaggi.firma(o.canale, tono: tono, impostazioni: x.impostazioni)
                    let t = ModelliMessaggi.testo(o, tono: tono, canale: canale, cliente: c, firma: firma)
                    let nome = "\(o.tipo.rawValue)/\(tono.rawValue)/\(canale.rawValue)"
                    // Solo le cifre della scheda (la bozza stessa non conta: si controlla contro i fatti)
                    let soloFatti = MessaggiVera.ammessi(o, cliente: c, bozza: TestoMessaggio(oggetto: nil, corpo: "", chiusura: t.chiusura))
                    if !CommentoVera.cifre(t.completo).isSubset(of: CommentoVera.cifre(soloFatti)) { sbagliati.append("\(nome): cifre") }
                    let apertura = tono == .formale ? "Gentile \(c.nome)," : "Ciao \(ModelliMessaggi.primoNome(c.nome)),"
                    if !t.corpo.hasPrefix(apertura) { sbagliati.append("\(nome): saluto") }
                    if !t.completo.hasSuffix("Denis") { sbagliati.append("\(nome): firma") }
                    if tono == .breve, t.completo.count > RegoleMessaggi.caratteriBreve { sbagliati.append("\(nome): lunghezza") }
                    if canale == .messaggi, t.oggetto != nil { sbagliati.append("\(nome): oggetto in Messaggi") }
                    if canale == .mail, (t.oggetto ?? "").isEmpty || (t.oggetto ?? "").count > RegoleMessaggi.caratteriOggetto {
                        sbagliati.append("\(nome): oggetto")
                    }
                    if let motivo = MessaggiVera.controlla(t.corpo, occasione: o, cliente: c, tono: tono, bozza: t) {
                        sbagliati.append("\(nome): \(motivo)")
                    }
                }
            }
        }
        verifica.vero("M9 Modelli: per ogni tipo, tono e canale solo cifre della scheda, saluto giusto, firma, lunghezze"
                      + (sbagliati.isEmpty ? "" : " (\(sbagliati.prefix(6).joined(separator: "; ")))"), sbagliati.isEmpty)
        // Il riepilogo di Giulia, cordiale, con le cifre al posto giusto
        if let o = occasioni.first(where: { $0.tipo == .riepilogoIncontro }), let c = x.clienti.first(where: { $0.id == "giulia" }) {
            let t = ModelliMessaggi.testo(o, tono: .cordiale, canale: .mail, cliente: c, firma: "Denis")
            verifica.vero("M9 Modelli: il riepilogo cordiale cita data, decisioni e prossimo incontro",
                          t.corpo.contains("del 4 novembre 2026") && t.corpo.contains("200 € al mese") && t.corpo.contains("3 dicembre 2026")
                          && t.chiusura == "\n\nUn saluto,\nDenis")
        }
        if let o = occasioni.first(where: { $0.tipo == .compleanno }), let c = x.clienti.first(where: { $0.id == "marco" }) {
            verifica.vero("M9 Modelli: «Marco ed Elena Bianchi» → «Ciao Marco ed Elena,»",
                          ModelliMessaggi.saluto(c, tono: .cordiale) == "Ciao Marco ed Elena," && !o.commerciale)
        }
        // La firma viene dai dati: per canale, poi dai dati di fatturazione (formale), poi dal nome; senza dati niente
        var imp = Impostazioni()
        imp.messaggi.firmaIndipendente = "Firma di prova indipendente"
        verifica.vero("M9 Firma: quella del canale scritta in Impostazioni, altrimenti il nome dell'utente",
                      ModelliMessaggi.firma(.indipendente, tono: .cordiale, impostazioni: imp) == "Firma di prova indipendente"
                      && ModelliMessaggi.firma(.alleanza, tono: .cordiale, impostazioni: imp) == "Denis"
                      && ModelliMessaggi.firma(nil, tono: .breve, impostazioni: imp) == "Denis")
        imp.studio.fatturazione.nome = "Nome"
        imp.studio.fatturazione.cognome = "Di prova"
        verifica.vero("M9 Firma: per il tono formale nome e cognome dei dati di fatturazione",
                      ModelliMessaggi.firma(.alleanza, tono: .formale, impostazioni: imp) == "Nome Di prova")
        var vuote = Impostazioni()
        vuote.nomeUtente = " "
        verifica.vero("M9 Firma: senza nessun dato nessuna firma inventata",
                      ModelliMessaggi.firma(.alleanza, tono: .cordiale, impostazioni: vuote) == nil
                      && ModelliMessaggi.chiusura(tono: .cordiale, firma: nil) == "\n\nUn saluto."
                      && ModelliMessaggi.chiusura(tono: .formale, firma: nil) == "\n\nCordiali saluti."
                      && ModelliMessaggi.chiusura(tono: .breve, firma: nil).isEmpty)
        let lungo = ModelliMessaggi.breve("Ciao Giulia,", necessarie: [String(repeating: "parola ", count: 80)], facoltative: ["In più."], limite: 120)
        verifica.vero("M9 Modelli: il tono breve si taglia a parola intera entro il limite", lungo.count <= 120 && lungo.hasSuffix("…"))
    }

    // MARK: - M10 Verifica dei testi di Vera

    private static func verificaVera(_ verifica: VerificaCalcoli) {
        let marco = cliente("marco", "Marco Bianchi")
        guard let o = calcola(dati([marco], posizioni: [polizza("p45", scade: 45)])).tutte.first(where: { $0.tipo == .scadenzaPosizione }) else {
            return verifica.vero("M10 Verifica: occasione di prova", false)
        }
        let bozza = ModelliMessaggi.testo(o, tono: .cordiale, canale: .mail, cliente: marco, firma: "Denis")
        func passa(_ t: String) -> Bool { MessaggiVera.controlla(t, occasione: o, cliente: marco, tono: .cordiale, bozza: bozza) == nil }
        verifica.vero("M10 Verifica: un testo con le cifre della scheda passa",
                      passa("Ciao Marco,\n\nla tua «Infortuni famiglia» scade il 19 dicembre 2026, tra 45 giorni: guardiamola insieme?"))
        verifica.vero("M10 Verifica: una cifra inventata, «55 mila», una promessa o un segnaposto non passano",
                      !passa("Ciao Marco, la polizza scade il 19 dicembre 2026 e rende il 4% all'anno.")
                      && !passa("Ciao Marco, con 55 mila euro potresti coprire tutto.")
                      && !passa("Ciao Marco, con un rendimento garantito stai tranquillo.")
                      && !passa("Ciao Marco, ci vediamo? [Il tuo nome]"))
        let fatti = MessaggiVera.ammessi(o, cliente: marco, bozza: bozza)
        verifica.vero("M10 Verifica: nel flusso una cifra inventata ferma la comparsa, la cifra che sta arrivando no",
                      MessaggiVera.mostrabile("Ciao Marco, la tua «Infortuni famiglia» scade il 1", fatti: fatti)
                      && MessaggiVera.mostrabile("Ciao Marco, scade il 19 dicembre 2026, tra 45 giorni", fatti: fatti)
                      && !MessaggiVera.mostrabile("Ciao Marco, risparmieresti 120 € all'anno", fatti: fatti)
                      && !MessaggiVera.mostrabile("Ciao Marco, con un rendimento garantito", fatti: fatti))
        verifica.vero("M10 Verifica: un testo troppo lungo non passa",
                      !passa("Ciao Marco, " + String(repeating: "davvero ", count: RegoleMessaggi.paroleTollerate)))
        let pulito = MessaggiVera.pulisci("Oggetto: La tua polizza\n**Ciao Marco,**\n\nGuardiamola insieme.\n\nUn saluto,\nDenis", firma: "Denis")
        verifica.vero("M10 Verifica: dal testo di Vera si tolgono oggetto, grassetti, chiusura e firma (le mette Prisma)",
                      pulito == "Ciao Marco,\n\nGuardiamola insieme.")
        verifica.vero("M10 Verifica: una firma diversa in fondo si toglie lo stesso",
                      MessaggiVera.pulisci("Ciao Marco,\n\nA presto!\nDenis Vicenzoni", firma: "Denis") == "Ciao Marco,")
    }

    // MARK: - M11 Indirizzi mailto: e sms:

    private static func indirizzi(_ verifica: VerificaCalcoli) {
        let mail = AperturaMessaggi.indirizzoMail(a: "giulia.rossi@example.com", oggetto: "Perché è così",
                                                  corpo: "Riga 1 & 2\nCosto: 10 €")?.absoluteString ?? ""
        verifica.vero("M11 Indirizzi: mailto: con accenti, «&», a capo ed euro codificati («\(mail)»)",
                      mail == "mailto:giulia.rossi@example.com?subject=Perch%C3%A9%20%C3%A8%20cos%C3%AC&body=Riga%201%20%26%202%0D%0ACosto%3A%2010%20%E2%82%AC")
        let sms = AperturaMessaggi.indirizzoSMS(a: "+393331234567", corpo: "Ciao è\nok?")?.absoluteString ?? ""
        verifica.vero("M11 Indirizzi: sms: con numero e corpo codificati («\(sms)»)", sms == "sms:+393331234567&body=Ciao%20%C3%A8%0Aok%3F")
        verifica.vero("M11 Indirizzi: il numero con sole cifre e il «+», il prefisso mai aggiunto da solo",
                      AperturaMessaggi.telefonoNormalizzato("+39 333 123 4567") == "+393331234567"
                      && AperturaMessaggi.telefonoNormalizzato("0039 333 1234567") == "+393331234567"
                      && AperturaMessaggi.telefonoNormalizzato("333-123.4567") == "3331234567"
                      && AperturaMessaggi.telefonoNormalizzato("12") == nil && AperturaMessaggi.telefonoNormalizzato("") == nil)
        let senza = cliente("x", "Cliente Senza Recapiti")
        let con = cliente("y", "Cliente Con Recapiti", email: " cliente@example.com ", telefono: "+39 333 000 1111")
        verifica.vero("M11 Indirizzi: senza email o telefono il pulsante dice cosa manca",
                      AperturaMessaggi.titoloPulsante(senza, canale: .mail) == "Manca l'indirizzo email nel dossier"
                      && AperturaMessaggi.titoloPulsante(senza, canale: .messaggi) == "Manca il numero di telefono nel dossier"
                      && AperturaMessaggi.titoloPulsante(con, canale: .mail) == "Apri in Mail"
                      && AperturaMessaggi.titoloPulsante(con, canale: .messaggi) == "Apri in Messaggi"
                      && AperturaMessaggi.email(con) == "cliente@example.com"
                      && AperturaMessaggi.email(cliente("z", "Z", email: "non è una mail")) == nil)
    }

    // MARK: - M12 Clienti di prova e archivio

    private static func clientiDiProva(_ verifica: VerificaCalcoli) {
        let x = DatiPrisma.demo()
        let adesso = Date()
        let r = MotoreOccasioniMessaggi.calcola(dati: x, oggi: adesso)
        let id = Set(x.clienti.map(\.id))
        verifica.vero("M12 Clienti di prova: \(r.oggi.count) occasioni oggi e \(r.settimana.count) in settimana, ognuna di un cliente",
                      r.tutte.allSatisfy { id.contains($0.clienteId) } && Set(r.tutte.map(\.id)).count == r.tutte.count
                      && r.oggi.count <= RegoleMessaggi.massimoPerGruppo && r.settimana.count <= RegoleMessaggi.massimoPerGruppo)
        var sbagliati: [String] = []
        for o in r.tutte {
            guard let c = x.clienti.first(where: { $0.id == o.clienteId }) else { continue }
            for tono in TonoMessaggio.allCases {
                let t = ModelliMessaggi.testo(o, tono: tono, canale: .mail, cliente: c, firma: "Denis")
                if MessaggiVera.controlla(t.corpo, occasione: o, cliente: c, tono: tono, bozza: t) != nil { sbagliati.append("\(o.id)/\(tono.rawValue)") }
            }
        }
        verifica.vero("M12 Clienti di prova: i modelli fissi passano la verifica delle cifre"
                      + (sbagliati.isEmpty ? "" : " (\(sbagliati.prefix(4).joined(separator: ", ")))"), sbagliati.isEmpty)
        // Un messaggio torna identico dall'archivio
        if let o = r.tutte.first ?? campionario().occasioni.first {
            var m = messaggio(o, stato: .apertoInMessaggi, il: d(2026, 11, 4))
            m.apertoIl = d(2026, 11, 4)
            m.autore = .vera
            m.modello = "qwen3.5:4b"
            let letto = (try? Archivio.codificatore.encode(m)).flatMap { try? Archivio.decodificatore.decode(MessaggioCliente.self, from: $0) }
            verifica.vero("M12 Archivio: il messaggio si salva e si rilegge uguale", letto == m)
        }
    }
}
