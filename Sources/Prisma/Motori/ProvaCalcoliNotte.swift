import Foundation
import CoreGraphics

/// Prove di «Stanotte Prisma ha lavorato» («Luce» giro 14, chiamate da `ProvaCalcoli.esegui()`): la finestra serale e il
/// giorno servito, le condizioni (ognuna da sola ferma, lo schermo spento no), cosa preparare (fascicolo, borsa, documento,
/// riesame solo con i dati, tetti, moduli, campagna), il ricalcolo con la fotografia, l'ordine fisso (Qwen per ultimo), gli
/// id stabili, le carte di ieri, i testi (notifica senza nomi), l'esecutore delle bozze (memoria e ordine dei lavori: una
/// alla volta, al più 10, stop alla memoria, `libera` sempre una volta) e la potatura. Oggi fisso al 9 novembre 2026,
/// calendario gregoriano. Nomi e dati DI PROVA.
enum ProvaCalcoliNotte {
    private static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone.current
        return c
    }()
    private static let giorno = Calendar(identifier: .gregorian).startOfDay(for: AiutiProva.data(2026, 11, 9))

    /// Il giorno di prova alle ore date (giorno 0 = il 9 novembre).
    private static func ora(_ h: Int, _ m: Int = 0, giorni: Int = 0) -> Date {
        let g = cal.date(byAdding: .day, value: giorni, to: giorno) ?? giorno
        return cal.date(bySettingHour: h, minute: m, second: 0, of: g) ?? g
    }

    private static func cliente(_ id: String, _ nome: String, documento: Date? = nil) -> Cliente {
        var c = Cliente(id: id, nome: nome, iniziali: Cliente.iniziali(di: nome), tinta: .blu, tema: "", email: "prova@esempio.invalid",
                        telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2020, 1, 1))
        if let d = documento {
            var conf = ConformitaCliente()
            conf.documento = DocumentoIdentita(tipo: .cartaIdentita, numero: nil, rilasciatoIl: AiutiProva.data(2017, 3, 7), scadenza: d)
            c.conformita = conf
        }
        return c
    }

    private static func posizione(_ cliente: String, _ nome: String = "Fondo di prova") -> Posizione {
        var p = AiutiProva.posizione(nome, .investimento, 12_345)
        p.clienteId = cliente
        return p
    }

    private static func appuntamento(_ id: String, _ cliente: String, _ inizio: Date, tipo: TipoAppuntamento = .analisi,
                                     posizioneId: String? = nil) -> Appuntamento {
        Appuntamento(id: id, clienteId: cliente, titolo: "Incontro di prova", inizio: inizio, durataMinuti: 45, luogo: "", note: "",
                     stato: .pianificato, tipo: tipo, posizioneId: posizioneId)
    }

    private static func dati(_ clienti: [Cliente], posizioni: [Posizione] = [], appuntamenti: [Appuntamento] = []) -> DatiPrisma {
        DatiPrisma(clienti: clienti, appuntamenti: appuntamenti, attivita: [], posizioni: posizioni,
                   clienteAttivoId: clienti.first?.id ?? "", impostazioni: Impostazioni())
    }

    /// Solo i tipi dati accesi.
    private static func solo(_ tipi: [TipoCartaNotte]) -> ImpostazioniNotte {
        var imp = ImpostazioniNotte()
        imp.preparatori = tipi
        return imp
    }

    private static func prepara(_ d: DatiPrisma, _ imp: ImpostazioniNotte = ImpostazioniNotte(), precedente: NotteDiLavoro? = nil,
                                giro: GiroGiorno? = nil, conDati: Set<String> = [], modelli: [ModelloModulo] = [],
                                occasioni: [OccasioneMessaggio] = []) -> [PreparativoNotte] {
        MotoreNotte.preparativi(dati: d, giorno: giorno, impostazioni: imp, precedente: precedente, giro: giro,
                                riesamiConDati: conDati, modelli: modelli, occasioni: occasioni, cal: cal)
    }

    static func esegui(_ verifica: VerificaCalcoli) {
        finestra(verifica)
        condizioni(verifica)
        preparativi(verifica)
        ricalcolo(verifica)
        ordine(verifica)
        idStabili(verifica)
        daIeri(verifica)
        testi(verifica)
        esecutore(verifica)
        potatura(verifica)
        #if os(macOS)
        notifica(verifica)
        #endif
    }

    // MARK: - 1 Finestra

    private static func finestra(_ verifica: VerificaCalcoli) {
        let f = { (d: Date, i: Int) in MotoreNotte.nellaFinestra(d, inizio: i, cal: cal) }
        verifica.vero("Notte: alle 21:59 fuori dalla finestra", !f(ora(21, 59), 22))
        verifica.vero("Notte: alle 22:00 dentro la finestra", f(ora(22), 22))
        verifica.vero("Notte: alle 05:59 dentro la finestra", f(ora(5, 59), 22))
        verifica.vero("Notte: alle 06:00 fuori dalla finestra", !f(ora(6), 22))
        verifica.vero("Notte: con inizio alle 23 le 22:30 sono fuori", !f(ora(22, 30), 23))
        let g = { (d: Date) in MotoreNotte.giornoServito(d, inizio: 22, cal: cal) }
        verifica.vero("Notte: alle 23:00 si serve domani", g(ora(23)) == ora(0, giorni: 1))
        verifica.vero("Notte: alle 02:00 si serve oggi", g(ora(2)) == giorno)
        verifica.vero("Notte: alle 08:00 si serve oggi", g(ora(8)) == giorno)
    }

    // MARK: - 2 Condizioni

    private static func condizioni(_ verifica: VerificaCalcoli) {
        var acceso = ImpostazioniNotte()
        acceso.attivo = true
        let buone = CondizioniNotte(adesso: ora(2, 7), impostazioni: acceso, allaCorrente: true, caldo: false, risparmio: false,
                                    backupInCorso: false, solaLettura: false, modoClienteOPresentazione: false, prismaInUso: false, notti: [])
        verifica.vero("Notte: tutte le condizioni buone → si lavora (lo schermo spento non conta)", MotoreNotte.attesa(buone, cal: cal) == nil)
        func con(_ cambia: (inout CondizioniNotte) -> Void) -> AttesaNotte? {
            var c = buone
            cambia(&c)
            return MotoreNotte.attesa(c, cal: cal)
        }
        verifica.vero("Notte: spento → non lavora", con { $0.impostazioni.attivo = false } == .spento)
        verifica.vero("Notte: fuori dalla finestra → non lavora", con { $0.adesso = ora(14, 23) } == .fuoriFinestra)
        verifica.vero("Notte: a batteria → non lavora", con { $0.allaCorrente = false } == .senzaCorrente)
        verifica.vero("Notte: alimentazione sconosciuta → non lavora", con { $0.allaCorrente = nil } == .alimentazioneSconosciuta)
        verifica.vero("Notte: Mac caldo → non lavora", con { $0.caldo = true } == .caldo)
        verifica.vero("Notte: risparmio energetico → non lavora", con { $0.risparmio = true } == .risparmioEnergetico)
        verifica.vero("Notte: backup in corso → non lavora", con { $0.backupInCorso = true } == .backupInCorso)
        verifica.vero("Notte: sola lettura → non lavora", con { $0.solaLettura = true } == .solaLettura)
        verifica.vero("Notte: modalità cliente o presentazione → non lavora", con { $0.modoClienteOPresentazione = true } == .modoCliente)
        verifica.vero("Notte: Prisma in uso → non lavora", con { $0.prismaInUso = true } == .prismaInUso)
        var fatta = NotteDiLavoro(giorno: giorno, inizio: ora(2, 3), cal: cal)
        fatta.esito = .fatta
        verifica.vero("Notte: notte già fatta → non lavora", con { $0.notti = [fatta] } == .giaFatta)
        var interrotta = fatta
        interrotta.esito = .interrotta
        verifica.vero("Notte: notte interrotta → riprende", con { $0.notti = [interrotta] } == nil)
        verifica.vero("Notte: «Prepara adesso» di giorno, spento e in uso → si lavora",
                      con { $0.manuale = true; $0.adesso = ora(9, 41); $0.impostazioni.attivo = false; $0.prismaInUso = true; $0.allaCorrente = false } == nil)
        verifica.vero("Notte: «Prepara adesso» in modalità cliente → no", con { $0.manuale = true; $0.modoClienteOPresentazione = true } == .modoCliente)
    }

    // MARK: - 3 Preparativi

    private static func preparativi(_ verifica: VerificaCalcoli) {
        let giulia = cliente("giulia", "Giulia Prova")
        let base = dati([giulia], posizioni: [posizione("giulia")],
                        appuntamenti: [appuntamento("app-1", "giulia", ora(9, 30)), appuntamento("app-2", "", ora(11, 15))])
        let p = prepara(base)
        let fascicoli = p.filter { $0.tipo == .fascicolo }
        verifica.vero("Notte: un incontro con cliente il giorno servito → fascicolo", fascicoli.count == 1 && fascicoli.first?.riferimento == "app-1")
        verifica.vero("Notte: un incontro con cliente → la borsa", p.contains { $0.tipo == .domani })
        if case let .domani(app, righe, _, km, partenza)? = p.first(where: { $0.tipo == .domani })?.dettagli {
            verifica.vero("Notte: la borsa ha solo l'incontro con il cliente", app == ["app-1"] && righe.count == 1 && righe[0].contains("Giulia: fascicolo"))
            verifica.vero("Notte: senza giro niente km né partenza", km == nil && partenza == nil)
        } else {
            verifica.vero("Notte: la borsa ha i suoi dettagli", false)
        }
        var altro = base
        altro.appuntamenti = [appuntamento("app-3", "giulia", ora(10, 10), tipo: .altro)]
        if case let .fascicolo(_, _, prospetti, solo)? = prepara(altro).first(where: { $0.tipo == .fascicolo })?.dettagli {
            let attesi = TipoProspetto.inFascicolo.filter { TipoProspetto.fascicoloPredefinito.contains($0) }.map(\.rawValue)
            verifica.vero("Notte: incontro «altro» senza posizione → i report predefiniti", prospetti == attesi && !solo)
        } else {
            verifica.vero("Notte: incontro «altro» → un fascicolo", false)
        }

        // Documento: fra 20 giorni sì, fra 40 no, scaduto sì
        let docs = dati([cliente("sofia", "Sofia Prova", documento: ora(12, giorni: 20)),
                         cliente("andrea", "Andrea Prova", documento: ora(12, giorni: 40)),
                         cliente("luca", "Luca Prova", documento: ora(12, giorni: -5))],
                        posizioni: [posizione("sofia"), posizione("andrea"), posizione("luca")])
        let d = prepara(docs, solo([.documento])).map { $0.clienteId ?? "" }
        verifica.vero("Notte: documento fra 20 giorni → carta, fra 40 no, scaduto sì", d.sorted() == ["luca", "sofia"])
        if case let .documento(_, scaduto, _, bozza)? = prepara(docs, solo([.documento])).first(where: { $0.clienteId == "luca" })?.dettagli {
            verifica.vero("Notte: documento scaduto con la bozza di richiesta (bozza, mai aperta)",
                          scaduto && bozza?.stato == .bozza && bozza?.apertoIl == nil && bozza?.origine.tipo == .documentoIdentita)
        } else {
            verifica.vero("Notte: documento scaduto → dettagli", false)
        }

        // Riesame: solo con i dati del prospetto, al più 3
        verifica.vero("Notte: riesame dovuto senza dati → nessuna carta", prepara(docs, solo([.riesame])).isEmpty)
        verifica.vero("Notte: riesame dovuto con i dati → carta", prepara(docs, solo([.riesame]), conDati: ["sofia"]).map(\.clienteId) == ["sofia"])
        let molti = (1...5).map { cliente("r\($0)", "Riesame \($0) Prova") }
        let mr = dati(molti, posizioni: molti.map { posizione($0.id) })
        verifica.vero("Notte: al più 3 riesami", prepara(mr, solo([.riesame]), conDati: Set(molti.map(\.id))).count == 3)
        let mf = dati(molti, posizioni: molti.map { posizione($0.id) },
                      appuntamenti: (0..<8).map { appuntamento("af-\($0)", molti[$0 % 5].id, ora(8 + $0, 5)) })
        verifica.vero("Notte: al più 6 fascicoli", prepara(mf, solo([.fascicolo])).count == 6)

        // Moduli: proposta con firma fra 3 giorni e fac-simile con la mappa confermata
        var proposta = posizione("giulia", "Proposta casa di prova")
        proposta.stato = .proposta
        let campo = ModelloModulo.Campo(pagina: 0, riquadro: .zero, etichetta: "Codice fiscale", dato: .codiceFiscale, origine: .mano)
        let campo2 = ModelloModulo.Campo(pagina: 0, riquadro: .zero, etichetta: "Cognome", dato: .cognome, origine: .mano)
        let modello = ModelloModulo(id: "modulo-prova", titolo: "Proposta di prova", tipo: .propostaPolizza, file: "prova.pdf", pagine: 1,
                                    campi: [campo, campo2], mappaConfermata: true, diProva: true)
        var conCF = giulia
        conCF.codiceFiscale = "PRVGLI80A41H501X"
        let mo = dati([conCF], posizioni: [proposta], appuntamenti: [appuntamento("af", "giulia", ora(16, 20, giorni: 3), tipo: .firma)])
        let carte = prepara(mo, solo([.moduli]), modelli: [modello])
        if case let .moduli(pos, _, modelli, campi, mancanti)? = carte.first?.dettagli {
            let fonte = FonteCompilazione(cliente: conCF, posizione: proposta, prodotto: nil, consulente: "", comuneConsulente: "", oggi: giorno,
                                          conservaIban: false)
            let a = CompilatoreModuli.anteprima(modello, fonte: fonte)
            verifica.vero("Notte: proposta con firma fra 3 giorni → moduli con campi e mancanti dell'anteprima",
                          carte.count == 1 && pos == proposta.id && modelli == ["modulo-prova"] && campi == a.compilati
                            && mancanti == a.datiMancanti.map(\.nome) && !mancanti.isEmpty)
        } else {
            verifica.vero("Notte: proposta con firma fra 3 giorni → moduli", false)
        }
        var senzaMappa = modello
        senzaMappa.mappaConfermata = false
        verifica.vero("Notte: modulo senza la mappa confermata → nessuna carta", prepara(mo, solo([.moduli]), modelli: [senzaMappa]).isEmpty)

        // Campagna: un gruppo con almeno due inclusi → una carta sola
        let camp = prepara(mr, solo([.campagna]))
        let gruppi = MotoreCampagne.gruppi(dati: mr, oggi: giorno, cal: cal).filter { $0.membri.filter(\.inclusoDiBase).count >= 2 }
        verifica.vero("Notte: campagna una per notte, solo con un gruppo da almeno due", camp.count == (gruppi.isEmpty ? 0 : 1))

        verifica.vero("Notte: nessun dato → nessun preparativo", prepara(dati([])).isEmpty)
    }

    // MARK: - 4 Ricalcolo

    private static func ricalcolo(_ verifica: VerificaCalcoli) {
        let d = dati([cliente("giulia", "Giulia Prova")], posizioni: [posizione("giulia")])
        let foto = MotoreNotte.attenzioni(dati: d)
        verifica.vero("Notte: prima notte (nessuna fotografia) → nessun ricalcolo", prepara(d, solo([.ricalcolo])).isEmpty)
        var ieri = NotteDiLavoro(giorno: ora(0, giorni: -1), inizio: nil, cal: cal)
        ieri.attenzioni = foto
        verifica.vero("Notte: stessa fotografia → nessun ricalcolo", prepara(d, solo([.ricalcolo]), precedente: ieri).isEmpty)
        var vuota = ieri
        vuota.attenzioni = []
        let r = prepara(d, solo([.ricalcolo]), precedente: vuota)
        if foto.isEmpty {
            verifica.vero("Notte: senza attenzioni oggi → nessun ricalcolo", r.isEmpty)
        } else if case let .ricalcolo(_, nuovi, chiavi)? = r.first?.dettagli {
            verifica.vero("Notte: un'attenzione nuova → la carta con quel cliente", nuovi == ["giulia"] && chiavi == foto)
            verifica.vero("Notte: la fotografia non ha titoli né cifre", chiavi.allSatisfy { !$0.contains(" ") })
        } else {
            verifica.vero("Notte: un'attenzione nuova → la carta", false)
        }
    }

    // MARK: - 5 Ordine

    private static func ordine(_ verifica: VerificaCalcoli) {
        verifica.vero("Notte: il messaggio (Qwen) è l'ultimo dei preparatori",
                      TipoCartaNotte.allCases.filter { $0 != .daFinire }.last == .messaggio && TipoCartaNotte.messaggio.conQwen
                        && TipoCartaNotte.allCases.filter(\.conQwen) == [.messaggio])
        let d = dati([cliente("giulia", "Giulia Prova"), cliente("sofia", "Sofia Prova", documento: ora(12, giorni: 11))],
                     posizioni: [posizione("giulia"), posizione("sofia")],
                     appuntamenti: [appuntamento("app-1", "giulia", ora(9, 30))])
        let o = OccasioneMessaggio(origine: OrigineMessaggio(tipo: .compleanno, riferimento: "2026"), clienteId: "giulia", canale: nil,
                                   gruppo: .oggi, titolo: "Compleanno di prova", perche: "Oggi", oggetto: "Auguri", cifre: [],
                                   priorita: .alta, data: giorno)
        let p = prepara(d, conDati: ["sofia"], occasioni: [o])
        let indici = p.map { TipoCartaNotte.allCases.firstIndex(of: $0.tipo) ?? 0 }
        verifica.vero("Notte: i preparativi seguono l'ordine fisso dei tipi", indici == indici.sorted() && p.last?.tipo == .messaggio)
        verifica.vero("Notte: i tipi spenti non nascono", !prepara(d, solo([.documento]), conDati: ["sofia"], occasioni: [o]).contains { $0.tipo != .documento })
        var senzaQwen = ImpostazioniNotte()
        senzaQwen.usaQwen = false
        verifica.vero("Notte: senza Vera nessuna bozza", !prepara(d, senzaQwen, occasioni: [o]).contains { $0.tipo == .messaggio })
    }

    // MARK: - 6 Id stabili

    private static func idStabili(_ verifica: VerificaCalcoli) {
        let d = dati([cliente("giulia", "Giulia Prova", documento: ora(12, giorni: 9))], posizioni: [posizione("giulia")],
                     appuntamenti: [appuntamento("app-1", "giulia", ora(9, 30))])
        let nomi = ["giulia": "Giulia Prova"]
        let a = prepara(d).map { MotoreNotte.carta($0, giorno: giorno, adesso: ora(2, 11), nomi: nomi, cal: cal) }
        let b = prepara(d).map { MotoreNotte.carta($0, giorno: giorno, adesso: ora(2, 11), nomi: nomi, cal: cal) }
        verifica.vero("Notte: due esecuzioni sugli stessi dati → stesse carte e stessi id", !a.isEmpty && a == b)
        verifica.vero("Notte: idCarta con lo stesso giorno a ore diverse è uguale",
                      MotoreNotte.idCarta(tipo: .fascicolo, riferimento: "app-1", giorno: ora(1, 3), cal: cal)
                        == MotoreNotte.idCarta(tipo: .fascicolo, riferimento: "app-1", giorno: ora(23, 41), cal: cal))
    }

    // MARK: - 7 Da ieri e scadute

    private static func daIeri(_ verifica: VerificaCalcoli) {
        let d = dati([cliente("giulia", "Giulia Prova")], posizioni: [posizione("giulia")],
                     appuntamenti: [appuntamento("app-passato", "giulia", ora(9, 30, giorni: -1)), appuntamento("app-futuro", "giulia", ora(15, 10, giorni: 2))])
        func carta(_ id: String, _ tipo: TipoCartaNotte, rif: String, perIl: Date, stato: StatoCartaNotte = .rimandata) -> CartaNotte {
            var c = CartaNotte(id: id, tipo: tipo, clienteId: "giulia", riferimento: rif, titolo: id, descrizione: "", conferma: "",
                               preparataIl: perIl, perIl: perIl)
            c.stato = stato
            return c
        }
        let ieriG = ora(0, giorni: -1)
        let passata = carta("passata", .fascicolo, rif: "app-passato", perIl: ieriG)
        let valida = carta("valida", .fascicolo, rif: "app-futuro", perIl: ieriG)
        let vecchia = carta("vecchia", .fascicolo, rif: "app-futuro", perIl: ora(0, giorni: -9))
        let approvata = carta("approvata", .fascicolo, rif: "app-futuro", perIl: ieriG, stato: .approvata)
        let adesso = ora(8, 3)
        verifica.vero("Notte: rimandata di un incontro passato → non più valida",
                      !MotoreNotte.ancoraValida(passata, dati: d, oggi: adesso, occasioni: [], gruppi: [], cal: cal))
        verifica.vero("Notte: rimandata di un incontro futuro → ancora valida",
                      MotoreNotte.ancoraValida(valida, dati: d, oggi: adesso, occasioni: [], gruppi: [], cal: cal))
        verifica.vero("Notte: oltre 7 giorni → non più valida",
                      !MotoreNotte.ancoraValida(vecchia, dati: d, oggi: adesso, occasioni: [], gruppi: [], cal: cal))
        var ieri = NotteDiLavoro(giorno: ieriG, inizio: nil, cal: cal)
        ieri.carte = [passata, valida, approvata]
        let portate = MotoreNotte.daIeri([ieri], giorno: giorno, valida: { MotoreNotte.ancoraValida($0, dati: d, oggi: adesso, occasioni: [], gruppi: [], cal: cal) }, cal: cal)
        verifica.vero("Notte: da ieri solo le valide non decise, con lo stesso id", portate.map(\.id) == ["valida"])
        var oggi = NotteDiLavoro(giorno: giorno, inizio: nil, cal: cal)
        oggi.carte = [carta("rimandata-oggi", .moduli, rif: "x", perIl: giorno), carta("nuova", .moduli, rif: "y", perIl: giorno, stato: .daDecidere)] + portate
            + [carta("decisa", .moduli, rif: "z", perIl: giorno, stato: .approvata)]
        verifica.vero("Notte: la pila = da decidere, rimandate di oggi, da ieri",
                      MotoreNotte.pila(oggi, cal: cal).map(\.id) == ["nuova", "rimandata-oggi", "valida"])
        verifica.vero("Notte: la carta di ieri è «DA IERI»", portate.first.map { MotoreNotte.daIeri($0, in: oggi, cal: cal) } == true)
        verifica.vero("Notte: il pallino conta le carte da decidere", MotoreNotte.daDecidere(oggi, cal: cal) == 3)
    }

    // MARK: - 8 Testi

    private static func testi(_ verifica: VerificaCalcoli) {
        verifica.vero("Notte: «ho preparato 1 cosa»", TestiNotte.sottotitolo(inizio: ora(2, 10), fine: ora(2, 14), carte: 1).contains("ho preparato 1 cosa."))
        verifica.vero("Notte: «Tra le 2:10 e le 2:14 ho preparato 8 cose»",
                      TestiNotte.sottotitolo(inizio: ora(2, 10), fine: ora(2, 14), carte: 8).hasPrefix("Tra le 2:10 e le 2:14 ho preparato 8 cose."))
        verifica.vero("Notte: la fine con il nome", TestiNotte.fine(approvate: 7, rimandate: 1, nome: "Denis") == "7 approvate, 1 per più tardi. Buona giornata, Denis.")
        verifica.vero("Notte: la fine senza nome", TestiNotte.fine(approvate: 7, rimandate: 1, nome: " ") == "7 approvate, 1 per più tardi. Buona giornata.")
        let senza = TestiNotte.descrizioneDomani(incontri: 2, daPortare: 4, km: nil, partenza: nil)
        verifica.vero("Notte: la borsa senza giro non dice km né partenza", !senza.contains("km") && !senza.contains("Partenza"))
        // Il giro di prova: partenza dallo studio, prima visita alle 9:50 a 35 minuti di strada (dati di prova)
        let a = appuntamento("app-giro", "giulia", ora(9, 50))
        let giro = GiroGiorno(giorno: giorno, partenza: Coordinata(lat: 45.07, lon: 7.68),
                              tappe: [TappaGiro(genere: .partenza, appuntamento: nil, cliente: nil, coordinata: Coordinata(lat: 45.07, lon: 7.68), kmDaPrima: 0, minutiDaPrima: 0),
                                      TappaGiro(genere: .visita, appuntamento: a, cliente: nil, coordinata: Coordinata(lat: 45.21, lon: 7.61), kmDaPrima: 17.1, minutiDaPrima: 35)],
                              km: 34.2, minuti: 70, suggerimenti: [], senzaLuogo: [], luogoDaIndicare: [], altrove: 0, prossimoGiorno: nil)
        let d = dati([cliente("giulia", "Giulia Prova")], posizioni: [posizione("giulia")], appuntamenti: [a])
        if case let .domani(_, _, n, km, partenza)? = prepara(d, solo([.domani]), giro: giro).first?.dettagli {
            let t = TestiNotte.descrizioneDomani(incontri: 1, daPortare: n, km: km, partenza: partenza)
            verifica.vero("Notte: la borsa con il giro dice «34 km» e «Partenza consigliata alle 09:15 (stima)»",
                          t.contains("34 km") && t.contains("Partenza consigliata alle 09:15 (stima)"))
        } else {
            verifica.vero("Notte: la borsa con il giro", false)
        }
        let nomiProva = ["Giulia", "Marco", "Sofia", "Andrea", "Laura", "Elena"]
        verifica.vero("Notte: la notifica non dice nomi di clienti",
                      TestiNotte.notifica(8) == "Stanotte ho preparato 8 cose" && !nomiProva.contains { TestiNotte.notifica(8).contains($0) })
        verifica.vero("Notte: la notifica con una carta", TestiNotte.notifica(1) == "Stanotte ho preparato 1 cosa")
    }

    // MARK: - 9 Esecutore (memoria e ordine dei lavori)

    private static func esecutore(_ verifica: VerificaCalcoli) {
        // 14 compiti, massimo 10: al più 10 scritture, mai due insieme, ordine conservato, libera una volta
        let r1 = aspetta { () -> (EsitoBozzeNotte<Int>, Int, Int, Int) in
            let e = EsecutoreBozzeNotte()
            let conti = ContiProvaNotte()
            let esito: EsitoBozzeNotte<Int> = await e.esegui(Array(0..<14), massimo: 10, carica: { () async -> Bool in conti.cariche += 1; return true },
                                       scrivi: { (c: Int) async -> Int? in conti.entra(); await Task.yield(); conti.esce(); return c },
                                       libera: { conti.liberate += 1 })
            return (esito, conti.massimoInsieme, conti.cariche, conti.liberate)
        }
        verifica.vero("Notte: al più 10 bozze, in ordine", r1.0.fatte == Array(0..<10) && r1.0.daFinire == 0 && r1.0.motivo == nil)
        verifica.vero("Notte: mai due bozze insieme, il modello caricato e liberato una volta", r1.1 == 1 && r1.2 == 1 && r1.3 == 1)

        // Avviso di memoria durante la seconda bozza: 2 fatte, 8 da finire, motivo memoria, libera una volta
        let r2 = aspetta { () -> (EsitoBozzeNotte<Int>, Int) in
            let e = EsecutoreBozzeNotte()
            let conti = ContiProvaNotte()
            let esito: EsitoBozzeNotte<Int> = await e.esegui(Array(0..<14), massimo: 10, carica: { true },
                                       scrivi: { (c: Int) async -> Int? in if c == 1 { e.ferma(.memoria) }; return c },
                                       libera: { conti.liberate += 1 })
            return (esito, conti.liberate)
        }
        verifica.vero("Notte: all'avviso di memoria si ferma dopo la bozza in corso",
                      r2.0.fatte == [0, 1] && r2.0.daFinire == 8 && r2.0.motivo == .memoria && r2.1 == 1)

        // Modello non pronto: nessuna scrittura, 10 da finire, libera una volta
        let r3 = aspetta { () -> (EsitoBozzeNotte<Int>, Int, Int) in
            let e = EsecutoreBozzeNotte()
            let conti = ContiProvaNotte()
            let esito: EsitoBozzeNotte<Int> = await e.esegui(Array(0..<14), massimo: 10, carica: { false },
                                       scrivi: { (c: Int) async -> Int? in conti.scritte += 1; return c }, libera: { conti.liberate += 1 })
            return (esito, conti.scritte, conti.liberate)
        }
        verifica.vero("Notte: Vera non pronta → nessuna bozza, 10 da finire, libera una volta",
                      r3.0.fatte.isEmpty && r3.0.daFinire == 10 && r3.0.motivo == .qwenNonPronto && r3.1 == 0 && r3.2 == 1)

        // Massimo 0: nessun caricamento
        let r4 = aspetta { () -> (EsitoBozzeNotte<Int>, Int) in
            let e = EsecutoreBozzeNotte()
            let conti = ContiProvaNotte()
            let esito: EsitoBozzeNotte<Int> = await e.esegui(Array(0..<3), massimo: 0, carica: { () async -> Bool in conti.cariche += 1; return true },
                                       scrivi: { (c: Int) async -> Int? in c }, libera: {})
            return (esito, conti.cariche)
        }
        verifica.vero("Notte: massimo 0 → il modello non si carica", r4.0.fatte.isEmpty && r4.1 == 0)
        let r5 = aspetta { () -> EsitoBozzeNotte<Int> in
            await EsecutoreBozzeNotte().esegui(Array(0..<50), massimo: 50, carica: { true }, scrivi: { (c: Int) async -> Int? in c }, libera: {})
        }
        verifica.vero("Notte: mai oltre 10 bozze, anche chiedendone 50", r5.fatte.count == 10)
    }

    /// Aspetta un lavoro asincrono dal thread delle prove (lavoro fuori dal thread principale).
    private static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaProvaNotte<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }

    // MARK: - 10 Potatura

    private static func potatura(_ verifica: VerificaCalcoli) {
        let notti = (0..<16).map { k -> NotteDiLavoro in
            var n = NotteDiLavoro(giorno: ora(0, giorni: -k), inizio: nil, cal: cal)
            n.esito = k == 1 ? .inCorso : .fatta
            return n
        }
        let potate = MotoreNotte.pota(notti.shuffled(), adesso: ora(7, 12))
        verifica.vero("Notte: restano le 14 notti più recenti", potate.count == 14 && potate.first?.giorno == giorno && potate.last?.giorno == ora(0, giorni: -13))
        verifica.vero("Notte: una notte «in corso» di ieri diventa «interrotta»", potate.first { $0.giorno == ora(0, giorni: -1) }?.esito == .interrotta)
        let tenuta = MotoreNotte.pota(notti, adesso: ora(7, 12), inCorsoAdesso: notti[1].giornoChiave)
        verifica.vero("Notte: la notte che lavora adesso resta «in corso»", tenuta.first { $0.giornoChiave == notti[1].giornoChiave }?.esito == .inCorso)
    }

    // MARK: - 11 Notifica di sistema

    #if os(macOS)
    private static func notifica(_ verifica: VerificaCalcoli) {
        var d = DatiPrisma.demo()
        var n = NotteDiLavoro(giorno: ora(0, giorni: 1), inizio: ora(2, 10, giorni: 1), cal: cal)
        n.esito = .fatta
        n.carte = (0..<8).map { k in
            CartaNotte(id: "notte-prova-\(k)", tipo: .fascicolo, clienteId: "giulia", riferimento: "r\(k)", titolo: "Giulia \(k)",
                       descrizione: "", conferma: "", preparataIl: ora(2, 10, giorni: 1), perIl: ora(0, giorni: 1))
        }
        d.notti = [n]
        d.impostazioni.notte.notificaAlMattino = true
        let voci = MotoreNotifiche.promemoria(d, impostazioni: d.impostazioni.promemoria, adesso: ora(23, 7), cal: cal).filter { $0.id.hasPrefix("prisma-notte-") }
        verifica.vero("Notte: con la notifica accesa e 8 carte una voce «Stanotte ho preparato 8 cose»",
                      voci.count == 1 && voci.first?.corpo == "Stanotte ho preparato 8 cose" && voci.first?.gruppo == "notte")
        d.impostazioni.notte.notificaAlMattino = false
        verifica.vero("Notte: con la notifica spenta nessuna voce",
                      !MotoreNotifiche.promemoria(d, impostazioni: d.impostazioni.promemoria, adesso: ora(23, 7), cal: cal).contains { $0.id.hasPrefix("prisma-notte-") })
    }
    #endif
}

/// I contatori dell'esecutore nelle prove (un compito alla volta: niente gare).
private final class ContiProvaNotte: @unchecked Sendable {
    private let serratura = NSLock()
    private var dentro = 0
    var massimoInsieme = 0
    var cariche = 0
    var liberate = 0
    var scritte = 0

    func entra() {
        serratura.lock()
        dentro += 1
        massimoInsieme = max(massimoInsieme, dentro)
        serratura.unlock()
    }

    func esce() {
        serratura.lock()
        dentro -= 1
        serratura.unlock()
    }
}

private final class ScatolaProvaNotte<T>: @unchecked Sendable {
    var valore: T?
}
