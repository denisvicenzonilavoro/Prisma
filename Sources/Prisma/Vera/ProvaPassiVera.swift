import Foundation

/// Prova di «Ragiona a passi» (Vera/BRIEF.md, funzione 20) dentro `Prisma --prova-vera`: il riconoscimento a regole, la
/// lettura della richiesta, il piano delle regole e il controllo del piano di Qwen (catalogo, cinque passi, ordine,
/// titoli senza cifre), l'esecuzione un passo alla volta con i motori di Prisma (protezione, tariffa caso morte,
/// obiettivi), le tre divisioni e la regola della scelta, i vincoli, la spiegazione di Qwen controllata, la risposta con
/// e senza ragionamento, le azioni da confermare e i modelli salvati. Dati fissi con un `oggi` fisso: niente rete, niente
/// Qwen vero, niente dipendenza dall'ora (tranne l'ultima prova sui dati del template, che vivono intorno a oggi).
enum ProvaPassiVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        riconoscimento(controlla)
        let (dati, richiesta) = caso()
        lettura(controlla, dati)
        pianoQwen(controlla, dati, richiesta)
        esecuzione(controlla, dati, richiesta)
        spiegazione(controlla, dati, richiesta)
        casiDifficili(controlla, dati)
        modelli(controlla, dati, richiesta)
        datiDelTemplate(controlla)
    }

    // MARK: - Dati fissi

    private static let cal = Calendar.current
    private static func giorno(_ a: Int, _ m: Int, _ g: Int, ora: Int = 12) -> Date {
        cal.date(from: DateComponents(year: a, month: m, day: g, hour: ora)) ?? Date(timeIntervalSinceReferenceDate: 0)
    }
    private static let oggi = giorno(2026, 11, 8)
    private static let frase = "Marco ha 400 € al mese: vuole proteggere Elena e continuare con gli studi di Tommaso. Come li divido?"

    /// Marco (anagrafica del template), una temporanea caso morte da 150.000 € a 45 € al mese, l'Infortuni famiglia che
    /// scade il 17 dicembre, l'obiettivo «Università di Anna» (25.000 € per settembre 2036, 5.400 € da parte) e una
    /// protezione che chiede 725.000 € (3.000 € al mese per 20 anni + 15.000 € − 10.000 €).
    private static func caso() -> (DatiPassi, RichiestaPassi) {
        let demo = StatoShell(persistente: false).dati
        let marco = demo.clienti.first { $0.id == "marco" } ?? demo.clienti[0]
        var tcm = Posizione(clienteId: marco.id, canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Temporanea caso morte")
        tcm.id = "pos-prova-tcm"
        tcm.premio = 45; tcm.frequenza = .mensile; tcm.capitaleAssicurato = 150_000; tcm.rischio = .vita
        tcm.capitaleDecrescente = false; tcm.decorrenza = giorno(2023, 1, 1); tcm.scadenza = giorno(2045, 1, 1); tcm.controvalore = 0
        var infortuni = Posizione(clienteId: marco.id, canale: .alleanza, stato: .inEssere, area: .protezione, nome: "Infortuni famiglia")
        infortuni.id = "pos-prova-infortuni"
        infortuni.premio = 380; infortuni.frequenza = .annuale; infortuni.capitaleAssicurato = 200_000; infortuni.rischio = .infortuni
        infortuni.decorrenza = giorno(2025, 12, 17); infortuni.scadenza = giorno(2026, 12, 17); infortuni.controvalore = 0
        var studi = Obiettivo(clienteId: marco.id, titolo: "Università di Anna", area: .famiglia, importo: 25_000, scadenza: giorno(2036, 9, 1))
        studi.id = "obiettivo-prova-studi"
        studi.priorita = .alta; studi.accantonato = 5_400; studi.rendimento = 2.5
        var casa = Obiettivo(clienteId: marco.id, titolo: "Casa al lago", area: .casa, importo: 40_000, scadenza: giorno(2034, 6, 1))
        casa.id = "obiettivo-prova-casa"
        casa.priorita = .media; casa.accantonato = 2_000; casa.rendimento = 2
        var protezione = IpotesiProtezione()
        protezione.fabbisognoMensile = 3_000; protezione.anniSostegno = 20; protezione.debiti = 0
        protezione.speseImmediate = 15_000; protezione.capitaleDisponibile = 10_000
        var cliente = marco
        cliente.profilo.redditoNettoAnnuo = 31_500
        let dati = DatiPassi(oggi: oggi, cliente: cliente, posizioni: [tcm, infortuni], archivio: [tcm, infortuni],
                             obiettivi: [studi, casa], protezione: protezione)
        let r = RichiestaPassi(testo: frase, clienteId: cliente.id, budgetMensile: 400, protezione: true,
                               obiettiviIds: [studi.id], protetta: "Elena")
        return (dati, r)
    }

    // MARK: - Pacchetto

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        for (nome, parola) in [("passi", "scegli_e_spiega"), ("passi-spiega", "JSON")] {
            controlla((IstruzioniVera.testo(nome) ?? "").contains(parola), "Ragiona a passi: istruzioni «\(nome)» nel pacchetto (Vera/Istruzioni/\(nome).md)")
        }
        controlla(StrumentoPasso.allCases.count == 5 && StrumentoPasso.allCases.allSatisfy(\.soloLettura),
                  "Ragiona a passi: il catalogo ha cinque strumenti, tutti di sola lettura")
        let proprieta = PassiVera.schemaPiano["properties"] as? [String: Any]
        let passi = proprieta?["passi"] as? [String: Any]
        let voce = passi?["items"] as? [String: Any]
        let campi = voce?["properties"] as? [String: Any]
        let strumento = campi?["strumento"] as? [String: Any]
        let ammessi = (strumento?["enum"] as? [String]) ?? []
        controlla(ammessi.sorted() == StrumentoPasso.allCases.map(\.rawValue).sorted() && (passi?["maxItems"] as? Int) == 5,
                  "Ragiona a passi: lo schema del piano ammette solo gli strumenti del catalogo")
    }

    // MARK: - Riconoscimento

    private static func riconoscimento(_ controlla: (Bool, String) -> Void) {
        controlla(PassiVera.eUnaRichiesta(frase), "Riconoscimento: la richiesta del template merita il ragionamento a passi")
        controlla(PassiVera.eUnaRichiesta("Giulia ha 300 euro al mese da dividere tra la casa e la pensione"),
                  "Riconoscimento: un budget da dividere tra due obiettivi")
        controlla(PassiVera.eUnaRichiesta("Ragiona a passi: con 250 € al mese meglio la protezione o l'università di Anna?"),
                  "Riconoscimento: «ragiona a passi» con un budget e due voci")
        for testo in ["Sposta l'incontro con Marco a giovedì", "Quanto versa Marco al mese nel PIP?",
                      "Marco versa 400 € al mese nel piano di accumulo", "Come divido i 400 € al mese di Marco?",
                      "Cosa non copre la polizza infortuni di Marco?"] {
            controlla(!PassiVera.eUnaRichiesta(testo), "Riconoscimento: «\(testo)» non è una richiesta a passi")
        }
        controlla(PassiVera.budget("Ha 1.200 euro mensili da investire") == 1_200 && PassiVera.budget("€ 350 al mese") == 350
                  && PassiVera.budget("400 € al mese") == 400 && PassiVera.budget("ha 400 euro") == nil,
                  "Riconoscimento: il budget mensile si legge in tutte le forme, e non senza «al mese»")
    }

    // MARK: - Lettura della richiesta

    private static func lettura(_ controlla: (Bool, String) -> Void, _ dati: DatiPassi) {
        if case .richiesta(let r) = PassiVera.capisci(frase, cliente: dati.cliente, obiettivi: dati.obiettivi) {
            controlla(r.budgetMensile == 400 && r.protezione && r.obiettiviIds == ["obiettivo-prova-studi"] && r.protetta == "Elena",
                      "Richiesta: 400 € al mese, protezione per Elena, gli studi ritrovati in «Università di Anna»: \(r)")
        } else {
            controlla(false, "Richiesta: la frase del template si capisce")
        }
        if case .domanda(let d) = PassiVera.capisci("Marco vuole proteggere Elena e pensare agli studi. Come li divido?", cliente: dati.cliente, obiettivi: dati.obiettivi) {
            controlla(d.contains("ogni mese"), "Richiesta: senza budget Vera lo chiede: \(d)")
        } else {
            controlla(false, "Richiesta: senza budget Vera chiede quanto al mese")
        }
        if case .domanda(let d) = PassiVera.capisci("Marco ha 400 € al mese per proteggere la famiglia e un altro progetto: come li divido?", cliente: dati.cliente, obiettivi: dati.obiettivi) {
            controlla(d.contains("Università di Anna") && d.contains("Casa al lago"), "Richiesta: senza obiettivo riconosciuto Vera chiede quale, con l'elenco: \(d)")
        } else {
            controlla(false, "Richiesta: senza obiettivo riconosciuto Vera chiede quale")
        }
        if case .richiesta(let r) = PassiVera.capisci("Marco ha 500 € al mese da dividere tra la casa e gli studi", cliente: dati.cliente, obiettivi: dati.obiettivi) {
            controlla(!r.protezione && Set(r.obiettiviIds) == ["obiettivo-prova-studi", "obiettivo-prova-casa"] && r.obiettiviIds.first == "obiettivo-prova-studi",
                      "Richiesta: due obiettivi senza protezione, il più importante per primo: \(r.obiettiviIds)")
        } else {
            controlla(false, "Richiesta: due obiettivi senza protezione si capiscono")
        }
        let clienti = StatoShell(persistente: false).dati.clienti
        controlla(PassiVera.cliente(nel: frase, clienti: clienti, attivo: "giulia")?.id == "marco"
                  && PassiVera.cliente(nel: "Ha 300 € al mese da dividere", clienti: clienti, attivo: "giulia")?.id == "giulia",
                  "Richiesta: il cliente nominato, altrimenti quello aperto")
        // Due clienti nominati: vale quello aperto se è tra loro, altrimenti nessuno (Vera chiede), mai il primo dell'archivio.
        let nominabili = clienti.filter { c in PassiVera.parole(c.nome).contains { $0.count >= 3 } }
        if nominabili.count >= 3,
           let n1 = PassiVera.parole(nominabili[0].nome).first(where: { $0.count >= 3 }),
           let n2 = PassiVera.parole(nominabili[1].nome).first(where: { $0.count >= 3 }) {
            let due = "\(n1) e \(n2) hanno 300 € al mese da dividere tra la casa e gli studi"
            let terzo = nominabili.first { c in
                c.id != nominabili[0].id && c.id != nominabili[1].id && !PassiVera.parole(c.nome).contains { $0 == n1 || $0 == n2 }
            }
            let scelto = PassiVera.cliente(nel: due, clienti: clienti, attivo: nominabili[1].id)
            controlla(PassiVera.cliente(nel: due, clienti: clienti, attivo: nil) == nil
                      && (terzo.map { PassiVera.cliente(nel: due, clienti: clienti, attivo: $0.id) == nil } ?? true)
                      && scelto?.id == nominabili[1].id,
                      "Richiesta: con due clienti nominati Vera non prende il primo dell'archivio né un cliente non nominato")
        } else {
            controlla(false, "Richiesta: i clienti di prova bastano per la verifica dei due nominati")
        }
    }

    // MARK: - Il piano di Qwen

    private static func pianoQwen(_ controlla: (Bool, String) -> Void, _ dati: DatiPassi, _ r: RichiestaPassi) {
        let regole = PassiVera.pianoConRegole(r, dati: dati)
        controlla(regole.map(\.strumento) == [.leggiProtezione, .leggiObiettivo, .simulaDivisioni, .controllaVincoli, .scegliESpiega]
                  && regole.map(\.id) == [1, 2, 3, 4, 5] && regole[1].titolo.contains("Università di Anna"),
                  "Piano: le regole danno cinque passi in ordine, ognuno con il suo strumento: \(regole.map(\.titolo))")

        let buono = #"{"passi":[{"strumento":"leggi_protezione","titolo":"Leggo la protezione di Elena"},{"strumento":"leggi_obiettivo","titolo":"Guardo gli studi","obiettivo":"Università di Anna"},{"strumento":"simula_divisioni","titolo":"Simulo 3 divisioni"},{"strumento":"scegli_e_spiega","titolo":"Scelgo e spiego"}]}"#
        let letto = PassiVera.leggiPiano(buono, richiesta: r, dati: dati)
        controlla(letto?.count == 4 && letto?[1].obiettivoId == "obiettivo-prova-studi" && letto?[0].titolo == "Leggo la protezione di Elena",
                  "Piano di Qwen: valido, con l'obiettivo risolto e i titoli di Qwen: \(letto?.map(\.titolo) ?? [])")
        controlla(letto?[2].titolo == "Simulo tre divisioni dei 400 €", "Piano di Qwen: un titolo con cifre lascia il posto a quello di Prisma: \(letto?[2].titolo ?? "")")

        let senzaScelta = #"{"passi":[{"strumento":"leggi_protezione","titolo":"Leggo"},{"strumento":"leggi_obiettivo","titolo":"Guardo"},{"strumento":"simula_divisioni","titolo":"Simulo"},{"strumento":"controlla_vincoli","titolo":"Controllo"}]}"#
        controlla(PassiVera.leggiPiano(senzaScelta, richiesta: r, dati: dati)?.last?.strumento == .scegliESpiega,
                  "Piano di Qwen: «scegli e spiega» si aggiunge in fondo se manca e c'è posto")

        let rifiutati: [(String, String)] = [
            ("sei passi", #"{"passi":[{"strumento":"leggi_protezione","titolo":"a"},{"strumento":"leggi_obiettivo","titolo":"b"},{"strumento":"leggi_obiettivo","titolo":"c","obiettivo":"Università di Anna"},{"strumento":"simula_divisioni","titolo":"d"},{"strumento":"controlla_vincoli","titolo":"e"},{"strumento":"scegli_e_spiega","titolo":"f"}]}"#),
            ("uno strumento fuori catalogo", #"{"passi":[{"strumento":"leggi_protezione","titolo":"a"},{"strumento":"pratiche_apri","titolo":"b"},{"strumento":"simula_divisioni","titolo":"c"},{"strumento":"scegli_e_spiega","titolo":"d"}]}"#),
            ("la scelta in mezzo", #"{"passi":[{"strumento":"leggi_protezione","titolo":"a"},{"strumento":"scegli_e_spiega","titolo":"b"},{"strumento":"simula_divisioni","titolo":"c"}]}"#),
            ("una lettura dopo la simulazione", #"{"passi":[{"strumento":"simula_divisioni","titolo":"a"},{"strumento":"leggi_protezione","titolo":"b"},{"strumento":"scegli_e_spiega","titolo":"c"}]}"#),
            ("senza simulazione", #"{"passi":[{"strumento":"leggi_protezione","titolo":"a"},{"strumento":"scegli_e_spiega","titolo":"b"}]}"#),
            ("un obiettivo che non c'è", #"{"passi":[{"strumento":"leggi_obiettivo","titolo":"a","obiettivo":"Barca a vela"},{"strumento":"simula_divisioni","titolo":"b"},{"strumento":"scegli_e_spiega","titolo":"c"}]}"#),
            ("cinque passi senza la scelta", #"{"passi":[{"strumento":"leggi_protezione","titolo":"a"},{"strumento":"leggi_obiettivo","titolo":"b"},{"strumento":"leggi_obiettivo","titolo":"c","obiettivo":"Università di Anna"},{"strumento":"simula_divisioni","titolo":"d"},{"strumento":"controlla_vincoli","titolo":"e"}]}"#),
            ("testo che non è JSON", "Ecco il piano: prima leggo la protezione."),
        ]
        for (nome, json) in rifiutati {
            controlla(PassiVera.leggiPiano(json, richiesta: r, dati: dati) == nil, "Piano di Qwen: rifiutato con \(nome)")
        }
        let p = PassiVera.piano(r, dati: dati, passiQwen: letto)
        let q = PassiVera.piano(r, dati: dati, passiQwen: nil)
        controlla(p.conQwen && p.passi.count == 4 && !q.conQwen && q.passi.count == 5, "Piano: quello di Qwen se valido, altrimenti quello delle regole")

        // Il piano di Qwen senza «controlla_vincoli»: i rinnovi non spariscono, «scegli e spiega» li controlla lo stesso
        let fatto = PassiVera.eseguiTutto(p, dati: dati)
        controlla(!fatto.passi.contains { $0.strumento == .controllaVincoli } && fatto.vincoli.contains { $0.tipo == .rinnovo && $0.posizioneId == "pos-prova-infortuni" }
                  && fatto.spiegazione.contains("Prima, però:")
                  && PassiVera.azioni(fatto, cliente: dati.cliente).contains { $0.strumento == RegistroStrumenti.attivitaNuova },
                  "Piano di Qwen senza «controlla_vincoli»: il rinnovo resta nei vincoli, nella spiegazione e nelle azioni: \(fatto.vincoli.map(\.testo))")
    }

    // MARK: - Esecuzione, divisioni e scelta

    private static func esecuzione(_ controlla: (Bool, String) -> Void, _ dati: DatiPassi, _ r: RichiestaPassi) {
        var piano = PassiVera.piano(r, dati: dati)
        // Un passo alla volta: dopo il primo solo il primo è fatto
        let altri = PassiVera.eseguiPasso(&piano, dati: dati)
        controlla(altri && piano.passi[0].stato == .fatto && piano.passi[1...].allSatisfy { $0.stato == .daFare },
                  "Esecuzione: un passo alla volta")
        controlla(piano.passi[0].esito.contains("725.000 €") && piano.passi[0].esito.contains("150.000 €") && piano.passi[0].esito.contains("al mese"),
                  "Esecuzione: la protezione letta da Prisma (fabbisogno, coperture e premio per colmare): \(piano.passi[0].esito)")
        piano = PassiVera.eseguiTutto(piano, dati: dati)
        controlla(piano.finito && piano.passi.allSatisfy { !$0.esito.isEmpty }, "Esecuzione: tutti i passi fatti, ognuno con il suo esito")
        controlla(piano.passi[1].esito.contains("25.000 €") && piano.passi[1].esito.contains("settembre 2036") && piano.passi[1].esito.contains("5.400 €"),
                  "Esecuzione: l'obiettivo letto da Prisma: \(piano.passi[1].esito)")

        let d = piano.divisioni
        controlla(d.map(\.tipo) == TipoDivisione.allCases && d.map(\.titolo) == ["Più protezione", "Equilibrio", "Più per «Università di Anna»"],
                  "Divisioni: tre, con i nomi del template: \(d.map(\.titolo))")
        controlla(d.allSatisfy { abs($0.protezioneMensile + $0.totaleObiettivi - 400) < 0.01 }, "Divisioni: ognuna usa tutti i 400 €")
        let bisogno = PassiVera.bisogno(dati.obiettivi[0], dati)
        let eq = d.first { $0.tipo == .equilibrio }
        controlla(bisogno > 120 && bisogno < 280 && eq?.totaleObiettivi == bisogno,
                  "Divisioni: l'equilibrio dà agli studi quanto basta per arrivare in tempo (\(CifreDoc.euro(bisogno)) al mese)")
        let capitali = d.compactMap(\.capitaleAggiunto)
        controlla(capitali.count == 3 && capitali[0] >= capitali[1] && capitali[1] > capitali[2]
                  && capitali.allSatisfy { $0.truncatingRemainder(dividingBy: 5_000) == 0 },
                  "Divisioni: il capitale dalla tariffa di Prisma (3,6 € ogni 1.000 €), a multipli di 5.000 €: \(capitali.map { CifreDoc.euro($0) })")
        // 120 € al mese di premio = 1.440 € l'anno = 400.000 € di capitale con la tariffa del cliente
        controlla(d.last?.capitaleAggiunto == 400_000, "Divisioni: 120 € al mese comprano 400.000 € di capitale caso morte")
        controlla(d[0].reggeObiettivi == false && d[1].reggeObiettivi && d[2].reggeObiettivi,
                  "Divisioni: con 120 € gli studi arrivano tardi, con l'equilibrio e di più arrivano in tempo")
        controlla(d[2].quote[0].anniAnticipo >= 1 && (d[0].quote[0].anniRitardo ?? 0) >= 1,
                  "Divisioni: più versamento arriva prima, meno arriva dopo (\(d[2].quote[0].anniAnticipo) anni prima, \(d[0].quote[0].anniRitardo ?? -1) dopo)")
        controlla(piano.consigliata == .equilibrio && piano.regge, "Scelta: la regola consiglia l'equilibrio, che regge su tutti gli obiettivi e protegge di più")
        if let scelta = PassiVera.scegli(d) {
            let altre = d.filter { $0.reggeObiettivi && $0.tipo != scelta.tipo }
            controlla(altre.allSatisfy { ($0.coperturaProtezione ?? 0) <= (scelta.coperturaProtezione ?? 0) + PassiVera.tolleranza },
                      "Scelta: nessun'altra divisione che regge protegge di più")
        }
        let rinnovo = piano.vincoli.first { $0.tipo == .rinnovo }
        controlla(rinnovo?.testo == "Infortuni famiglia da rinnovare entro il 17 dicembre" && rinnovo?.posizioneId == "pos-prova-infortuni",
                  "Vincoli: l'Infortuni famiglia da rinnovare entro il 17 dicembre: \(piano.vincoli.map(\.testo))")
        controlla(!piano.vincoli.contains { $0.tipo == .sostenibilita || $0.tipo == .budgetCorto || $0.tipo == .senzaTariffa },
                  "Vincoli: 400 € su 31.500 € netti l'anno sono sostenibili e bastano per gli studi")
        controlla(piano.spiegazione.hasPrefix("Ti consiglio «Equilibrio»") && piano.spiegazione.contains("Elena")
                  && piano.spiegazione.contains("settembre 2036") && piano.spiegazione.contains("Prima, però: Infortuni famiglia da rinnovare entro il 17 dicembre"),
                  "Spiegazione: la bozza di Prisma dice la scelta, il perché e il vincolo: \(piano.spiegazione)")
        controlla(!piano.spiegazioneConQwen, "Spiegazione: senza Qwen resta la bozza di Prisma")
    }

    // MARK: - La spiegazione di Qwen

    private static func spiegazione(_ controlla: (Bool, String) -> Void, _ dati: DatiPassi, _ r: RichiestaPassi) {
        let piano = PassiVera.eseguiTutto(PassiVera.piano(r, dati: dati), dati: dati)
        let m = PassiVera.messaggiSpiegazione(piano)
        controlla(m.count == 2 && m[1].testo.contains("Equilibrio") && m[1].testo.contains(PassiVera.regola),
                  "Spiegazione: a Qwen vanno la regola, la scelta di Prisma e il riepilogo")
        let buona = #"{"spiegazione":"Ti consiglio Equilibrio: porta «Università di Anna» in tempo per settembre 2036 e intanto protegge Elena. Prima, però, rinnova Infortuni famiglia entro il 17 dicembre."}"#
        let p = PassiVera.conSpiegazione(buona, piano: piano)
        controlla(p.spiegazioneConQwen && p.spiegazione.hasPrefix("Ti consiglio Equilibrio"), "Spiegazione: il testo di Qwen con le cifre di Prisma si tiene")
        let cifraNuova = #"{"spiegazione":"Ti consiglio Equilibrio: rende il 9,5% l'anno e protegge Elena."}"#
        controlla(PassiVera.leggiSpiegazione(cifraNuova, piano: piano) == nil, "Spiegazione: una cifra inventata da Qwen fa tenere la bozza")
        let altraScelta = #"{"spiegazione":"Ti consiglio Più protezione: Elena è al sicuro."}"#
        controlla(PassiVera.leggiSpiegazione(altraScelta, piano: piano) == nil, "Spiegazione: se Qwen cambia la divisione scelta resta la bozza")
        let nonBasta = #"{"spiegazione":"L'Equilibrio non basta: ti consiglio Più protezione, così Elena è al sicuro."}"#
        controlla(PassiVera.leggiSpiegazione(nonBasta, piano: piano) == nil,
                  "Spiegazione: «L'Equilibrio non basta: ti consiglio Più protezione» nomina la scelta ma ne consiglia un'altra, resta la bozza")
        let confronto = #"{"spiegazione":"Ti consiglio Equilibrio: rispetto a Più protezione porta «Università di Anna» in tempo per settembre 2036 e protegge Elena."}"#
        controlla(PassiVera.leggiSpiegazione(confronto, piano: piano) != nil,
                  "Spiegazione: consigliare la scelta di Prisma confrontandola con un'altra divisione va bene")
        if let scelta = piano.divisioneConsigliata {
            let divs = piano.divisioni
            controlla(scelta.tipo == .equilibrio
                      && !PassiVera.consigliaSolo(scelta, tra: divs, testo: "L'Equilibrio non basta: ti consiglio i +400.000 € di Più protezione."),
                      "Spiegazione: il punto delle migliaia («400.000») non chiude la frase, il consiglio di un'altra divisione si vede")
            controlla(!PassiVera.consigliaSolo(scelta, tra: divs, testo: "Equilibrio regge su tutto, ma ti raccomando Più protezione per Elena.")
                      && !PassiVera.consigliaSolo(scelta, tra: divs, testo: "Equilibrio regge su tutto, ma la scelta migliore è Più protezione."),
                      "Spiegazione: «ti raccomando» e «la scelta migliore è» un'altra divisione fanno tenere la bozza")
            controlla(PassiVera.consigliaSolo(scelta, tra: divs, testo: "Ti consiglio Equilibrio: protegge Elena meglio di Più protezione.")
                      && PassiVera.consigliaSolo(scelta, tra: divs, testo: "Equilibrio conviene più di Più protezione per Elena.")
                      && !PassiVera.consigliaSolo(scelta, tra: divs, testo: "Equilibrio regge, ma meglio Più protezione."),
                      "Spiegazione: «meglio di / conviene più di» un'altra divisione è un paragone, non un consiglio")
            controlla(!PassiVera.consigliaSolo(scelta, tra: divs, testo: "Equilibrio regge su tutto, ma Più protezione è la scelta migliore per Elena.")
                      && !PassiVera.consigliaSolo(scelta, tra: divs, testo: "Ti consiglio Equilibrio, anche se Più protezione sarebbe meglio."),
                      "Spiegazione: «Più protezione è la scelta migliore» o «sarebbe meglio», con la divisione prima della parola, fanno tenere la bozza")
            controlla(PassiVera.consigliaSolo(scelta, tra: divs, testo: "Più protezione copre di più, ma Equilibrio è la scelta migliore per Elena."),
                      "Spiegazione: «Equilibrio è la scelta migliore» dopo aver nominato un'altra divisione consiglia la scelta di Prisma")
        } else {
            controlla(false, "Spiegazione: manca la divisione consigliata per le prove di consigliaSolo")
        }
        let prosa = "Ti consiglio Equilibrio: porta «Università di Anna» in tempo e protegge Elena."
        controlla(PassiVera.leggiSpiegazione(prosa, piano: piano) == nil && PassiVera.leggiSpiegazione("{\"spiegazione\": \"" + prosa, piano: piano) == nil,
                  "Spiegazione: la prosa senza JSON o un JSON rotto non valgono, anche con la divisione giusta")
        let inLettere = #"{"spiegazione":"Ti consiglio Equilibrio: metti venti euro in più sulla protezione di Elena."}"#
        controlla(PassiVera.leggiSpiegazione(inLettere, piano: piano) == nil, "Spiegazione: una cifra in lettere che la bozza non dice fa tenere la bozza")
        let comeBozza = #"{"spiegazione":"Ti consiglio Equilibrio: delle due divisioni che portano «Università di Anna» in tempo è quella che protegge di più Elena."}"#
        controlla(piano.spiegazione.contains("Delle due divisioni") && PassiVera.leggiSpiegazione(comeBozza, piano: piano) != nil,
                  "Spiegazione: le parole della bozza («delle due divisioni») restano ammesse")
        let dueAnni = #"{"spiegazione":"Ti consiglio Equilibrio: delle due divisioni che portano «Università di Anna» in tempo è quella che protegge di più Elena, e tra due anni l'università è pagata."}"#
        controlla(PassiVera.leggiSpiegazione(dueAnni, piano: piano) == nil,
                  "Spiegazione: «due» della bozza riusato con un altro significato («tra due anni») fa tenere la bozza")
        controlla(PassiVera.leggiSpiegazione(#"{"altro":"x"}"#, piano: piano) == nil && PassiVera.leggiSpiegazione("", piano: piano) == nil,
                  "Spiegazione: JSON senza spiegazione o vuoto non vale")
    }

    // MARK: - Casi difficili

    private static func casiDifficili(_ controlla: (Bool, String) -> Void, _ dati: DatiPassi) {
        // Budget troppo piccolo: nessuna divisione regge, la regola sceglie la meno scoperta
        let poco = RichiestaPassi(testo: "", clienteId: dati.cliente.id, budgetMensile: 100, protezione: true, obiettiviIds: ["obiettivo-prova-studi"], protetta: "Elena")
        let p1 = PassiVera.eseguiTutto(PassiVera.piano(poco, dati: dati), dati: dati)
        let minimi = p1.divisioni.map(\.minimo)
        controlla(!p1.regge && p1.divisioni.allSatisfy { !$0.reggeObiettivi } && (p1.divisioneConsigliata?.minimo ?? -1) >= (minimi.max() ?? 0) - PassiVera.tolleranza,
                  "Scelta: con 100 € nessuna divisione regge e si consiglia quella che lascia meno indietro")
        controlla(p1.spiegazione.contains("Nessuna divisione dei 100 €") && p1.vincoli.contains { $0.tipo == .budgetCorto },
                  "Spiegazione: con 100 € Vera dice che nessuna divisione regge e che gli studi chiederebbero di più: \(p1.spiegazione)")

        // Senza tariffa caso morte: il capitale non si stima e Vera lo dice
        var senza = dati
        senza.posizioni = dati.posizioni.filter { $0.rischio != .vita }
        senza.archivio = senza.posizioni
        let r = RichiestaPassi(testo: "", clienteId: dati.cliente.id, budgetMensile: 400, protezione: true, obiettiviIds: ["obiettivo-prova-studi"], protetta: "Elena")
        let p2 = PassiVera.eseguiTutto(PassiVera.piano(r, dati: senza), dati: senza)
        controlla(p2.divisioni.allSatisfy { $0.capitaleAggiunto == nil } && p2.vincoli.contains { $0.tipo == .senzaTariffa }
                  && p2.passi[0].esito.contains("preventivo"),
                  "Protezione: senza tariffa in archivio il capitale non si inventa, va chiesto in preventivo")
        controlla(p2.consigliata != nil, "Scelta: anche senza tariffa la regola sceglie (sugli obiettivi)")

        // Due obiettivi senza protezione
        let due = RichiestaPassi(testo: "", clienteId: dati.cliente.id, budgetMensile: 500, protezione: false,
                                 obiettiviIds: ["obiettivo-prova-studi", "obiettivo-prova-casa"], protetta: "la famiglia")
        let p3 = PassiVera.eseguiTutto(PassiVera.piano(due, dati: dati), dati: dati)
        controlla(p3.passi.count == 4 && !p3.passi.contains { $0.strumento == .leggiProtezione },
                  "Piano: senza protezione niente lettura della protezione: \(p3.passi.map(\.titolo))")
        controlla(p3.divisioni.count == 3 && p3.divisioni.allSatisfy { $0.coperturaProtezione == nil && $0.protezioneMensile == 0 && abs($0.totaleObiettivi - 500) < 0.01 }
                  && p3.divisioni[0].titolo == "Più per «Università di Anna»" && p3.divisioni[2].titolo == "Più per «Casa al lago»",
                  "Divisioni: tra due obiettivi, tutti i 500 € agli obiettivi: \(p3.divisioni.map(\.titolo))")
        controlla(p3.consigliata != nil, "Scelta: tra due obiettivi la regola sceglie")

        // Il budget alto rispetto al reddito è un vincolo
        let tanto = RichiestaPassi(testo: "", clienteId: dati.cliente.id, budgetMensile: 900, protezione: true, obiettiviIds: ["obiettivo-prova-studi"], protetta: "Elena")
        controlla(PassiVera.vincoli(tanto, dati: dati).contains { $0.tipo == .sostenibilita }, "Vincoli: 900 € al mese su 31.500 € netti l'anno vanno verificati")
    }

    // MARK: - Risposta, azioni e modelli

    private static func modelli(_ controlla: (Bool, String) -> Void, _ dati: DatiPassi, _ r: RichiestaPassi) {
        let piano = PassiVera.eseguiTutto(PassiVera.piano(r, dati: dati), dati: dati)
        let con = PassiVera.testoRisposta(piano, mostraRagionamento: true)
        let senza = PassiVera.testoRisposta(piano, mostraRagionamento: false)
        controlla(con.contains("Il piano di Vera") && con.contains("1. Leggo la protezione della famiglia") && con.contains("La regola:"),
                  "Risposta: con «mostra il ragionamento» si vedono il piano e la regola")
        controlla(!senza.contains("Il piano di Vera") && senza.contains("Equilibrio (Vera consiglia)") && senza.contains(piano.spiegazione),
                  "Risposta: senza ragionamento restano le divisioni e la spiegazione")

        let azioni = PassiVera.azioni(piano, cliente: dati.cliente)
        controlla(azioni.map(\.strumento) == [RegistroStrumenti.notaNuova, RegistroStrumenti.attivitaNuova]
                  && azioni[0].argomenti["testo"]?.contains("«Equilibrio»") == true && azioni[1].argomenti["titolo"] == "Rinnovare Infortuni famiglia"
                  && azioni.allSatisfy { $0.argomenti["cliente"] == dati.cliente.id && $0.esito == nil },
                  "Azioni: la divisione nel taccuino e il rinnovo in attività, da confermare (niente eseguito)")

        let codifica = JSONEncoder()
        let decodifica = JSONDecoder()
        let copia = (try? codifica.encode(piano)).flatMap { try? decodifica.decode(PianoPassi.self, from: $0) }
        controlla(copia == piano, "Modelli: il piano si salva e si rilegge uguale")
        let minimo = #"{"id":"passi-x","richiesta":{"testo":"","clienteId":"marco","budgetMensile":400,"protezione":true,"obiettiviIds":[],"protetta":"Elena"}}"#
        let tollerato = try? decodifica.decode(PianoPassi.self, from: Data(minimo.utf8))
        controlla(tollerato?.passi.isEmpty == true && tollerato?.consigliata == nil, "Modelli: un piano salvato con pochi campi si legge con tolleranza")
        let impostazioni = try? decodifica.decode(ImpostazioniPassiVera.self, from: Data("{}".utf8))
        controlla(impostazioni?.mostraRagionamento == true && impostazioni?.attivo == true, "Modelli: «mostra il ragionamento» acceso di base")
    }

    // MARK: - Dati del template

    /// I dati di prova vivono intorno al giorno di oggi (l'Infortuni scade tra 45 giorni): qui `oggi` è adesso.
    private static func datiDelTemplate(_ controlla: (Bool, String) -> Void) {
        let demo = StatoShell(persistente: false).dati
        guard let dati = PassiVera.datiDa(demo) else {
            controlla(false, "Template: i dati di Marco si leggono dall'archivio")
            return
        }
        guard case .richiesta(let r) = PassiVera.capisci(frase, cliente: dati.cliente, obiettivi: dati.obiettivi) else {
            controlla(false, "Template: la frase del template si capisce sui dati di Marco")
            return
        }
        let piano = PassiVera.eseguiTutto(PassiVera.piano(r, dati: dati), dati: dati)
        controlla(r.obiettiviIds == ["obiettivo-marco-studi"] && piano.divisioni.count == 3 && piano.consigliata != nil && piano.passi.count <= PassiVera.massimoPassi,
                  "Template: Marco, 400 € al mese, l'università di Anna: tre divisioni e una scelta")
        controlla(piano.vincoli.contains { $0.tipo == .rinnovo && $0.posizioneId == "pos-marco-infortuni-famiglia" },
                  "Template: tra i vincoli il rinnovo dell'Infortuni famiglia")
    }
}

private extension PassiVera {
    /// I dati di Marco dal template, con `oggi` adesso.
    static func datiDa(_ d: DatiPrisma) -> DatiPassi? { DatiPassi.da(d, clienteId: "marco", oggi: Date()) }
}
