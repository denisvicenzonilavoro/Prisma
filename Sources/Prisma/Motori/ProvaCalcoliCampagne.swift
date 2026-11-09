import Foundation

/// Prove di Messaggi › Campagne («Luce» giro 12, chiamate da `ProvaCalcoli.esegui()`): gruppi solo dai motori e con
/// almeno due membri (decisione 97), bisogno scartato fuori, consenso commerciale (decisione 16), recapito, 90 e 30 giorni,
/// previdenza senza movimenti non valutata, scadenze nello stesso mese e «Titoli di Stato», età tonde, un cliente in due
/// gruppi con «anche in», testi senza altri clienti e brevi entro il limite, bozze mai aperte da sole (decisione 15), le
/// bozze fuori dal limite di «Da mandare oggi», seme stabile, clienti fittizi con i gruppi. Oggi fisso al 4 novembre 2026.
/// Nomi, recapiti e importi DI PROVA.
enum ProvaCalcoliCampagne {
    private static let cal = Calendar(identifier: .gregorian)
    private static let oggi = AiutiProva.data(2026, 11, 4)

    private static func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }

    private static func cliente(_ id: String, _ nome: String, nascita: Date? = nil, consenso: Bool = true,
                                email: String = "prova@esempio.invalid") -> Cliente {
        var c = Cliente(id: id, nome: nome, iniziali: Cliente.iniziali(di: nome), tinta: .blu, tema: "", email: email,
                        telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2020, 1, 1))
        c.dataNascita = nascita
        c.consensi.marketing = consenso
        c.consensi.dataMarketing = consenso ? AiutiProva.data(2026, 6, 1) : nil
        return c
    }

    private static func dati(_ clienti: [Cliente], posizioni: [Posizione] = []) -> DatiPrisma {
        DatiPrisma(clienti: clienti, appuntamenti: [], attivita: [], posizioni: posizioni, clienteAttivoId: clienti.first?.id ?? "",
                   impostazioni: Impostazioni())
    }

    private static func gruppi(_ x: DatiPrisma) -> [GruppoCampagna] { MotoreCampagne.gruppi(dati: x, oggi: oggi, cal: cal) }

    private static func previdenza(_ cliente: String, movimenti: [Movimento]?) -> Posizione {
        var p = AiutiProva.posizione("Fondo \(cliente)", .previdenza, 20_000)
        p.clienteId = cliente
        p.movimenti = movimenti
        return p
    }

    static func esegui(_ verifica: VerificaCalcoli) {
        regole(verifica)
        previdenzaFerma(verifica)
        scadenze(verifica)
        eta(verifica)
        testi(verifica)
        dividi(verifica)
        seme(verifica)
        fittizi(verifica)
        #if os(macOS)
        bozze(verifica)
        #endif
    }

    // MARK: - 1-5 Regole dei gruppi

    private static func regole(_ verifica: VerificaCalcoli) {
        // Senza previdenza in essere MotoreBisogni rileva «previdenza-assente»
        let solo = gruppi(dati([cliente("a", "Anna Uno")]))
        verifica.vero("Campagne: un solo cliente con un bisogno → nessun gruppo", !solo.contains { $0.tipo == .previdenzaAssente })
        var scartato = cliente("b", "Bruno Due")
        scartato.bisogni.esiti["previdenza-assente"] = false
        let g = gruppi(dati([cliente("a", "Anna Uno"), scartato, cliente("c", "Carla Tre", consenso: false), cliente("e", "Elena Cinque", email: "")]))
        let prev = g.first { $0.tipo == .previdenzaAssente }
        verifica.vero("Campagne: il bisogno scartato dal consulente resta fuori",
                      prev != nil && !(prev?.membri.contains { $0.clienteId == "b" } ?? true))
        let carla = prev?.membri.first { $0.clienteId == "c" }
        verifica.vero("Campagne: senza consenso commerciale nel gruppo, fuori dall'invio di base",
                      carla != nil && carla?.consenso == false && carla?.inclusoDiBase == false)
        let elena = prev?.membri.first { $0.clienteId == "e" }
        verifica.vero("Campagne: senza recapito fuori dall'invio di base",
                      elena?.recapitoMail == false && elena?.inclusoDiBase == false)
        verifica.vero("Campagne: con consenso e recapito incluso di base", prev?.membri.first { $0.clienteId == "a" }?.inclusoDiBase == true)
        // 5. Già contattato per lo stesso bisogno (30 giorni fa), un'altra campagna 10 giorni fa, una di 31 giorni fa
        var x = dati([cliente("a", "Anna Uno"), cliente("f", "Franco Sei"), cliente("h", "Ugo Otto")])
        let trenta = cal.date(byAdding: .day, value: -30, to: oggi) ?? oggi
        let dieci = cal.date(byAdding: .day, value: -10, to: oggi) ?? oggi
        let trentuno = cal.date(byAdding: .day, value: -31, to: oggi) ?? oggi
        x.campagne = [Campagna(id: "camp-stesso", gruppoId: "previdenzaAssente", gruppoTipo: .previdenzaAssente, titolo: "Prova",
                               avviataIl: trentuno, tono: .cordiale, canale: .mail, clienti: ["a"], appuntamenti: [], messaggi: []),
                      Campagna(id: "camp-altro", gruppoId: "etaTonda-50-2027", gruppoTipo: .etaTonda, titolo: "Prova",
                               avviataIl: dieci, tono: .cordiale, canale: .mail, clienti: ["f"], appuntamenti: [], messaggi: [])]
        var aperto = MessaggioCliente(clienteId: "a", occasioneId: "campagna-a-camp-stesso",
                                      origine: OrigineMessaggio(tipo: .campagna, riferimento: "camp-stesso"), canaleLavoro: nil,
                                      tono: .cordiale, canale: .mail, oggetto: nil, testo: "Testo di prova", cifre: [],
                                      autore: .modelloFisso, modello: nil, creatoIl: trenta)
        aperto.stato = .apertoInMail
        aperto.apertoIl = trenta
        x.messaggi = [aperto]
        let p = gruppi(x).first { $0.tipo == .previdenzaAssente }
        let a = p?.membri.first { $0.clienteId == "a" }, f = p?.membri.first { $0.clienteId == "f" }
        let h = p?.membri.first { $0.clienteId == "h" }
        verifica.vero("Campagne: già scritto 30 giorni fa per lo stesso bisogno → «già contattato», fuori di base",
                      a?.giaContattato != nil && a?.inclusoDiBase == false)
        verifica.vero("Campagne: una campagna di 10 giorni fa su un altro gruppo → ultima campagna, fuori di base",
                      f?.ultimaCampagna != nil && f?.giaContattato == nil && f?.inclusoDiBase == false)
        verifica.vero("Campagne: una campagna di 31 giorni fa non conta più", a?.ultimaCampagna == nil && h?.inclusoDiBase == true)
    }

    // MARK: - 6 Previdenza ferma

    private static func previdenzaFerma(_ verifica: VerificaCalcoli) {
        let tredici = cal.date(byAdding: .month, value: -13, to: oggi) ?? oggi
        let due = cal.date(byAdding: .month, value: -2, to: oggi) ?? oggi
        let x = dati([cliente("a", "Anna Uno"), cliente("b", "Bruno Due"), cliente("c", "Carla Tre"), cliente("e", "Elena Cinque")],
                     posizioni: [previdenza("a", movimenti: [Movimento(data: tredici, importo: 1_000)]),
                                 previdenza("b", movimenti: [Movimento(data: tredici, importo: 500), Movimento(data: due, importo: -200)]),
                                 previdenza("c", movimenti: nil),
                                 previdenza("e", movimenti: [Movimento(data: due, importo: 300)])])
        let g = gruppi(x).first { $0.tipo == .previdenzaFerma }
        verifica.vero("Campagne: fondo senza versamenti da 13 mesi nel gruppo (un riscatto non è un versamento)",
                      Set(g?.membri.map(\.clienteId) ?? []) == ["a", "b"])
        verifica.vero("Campagne: senza movimenti registrati non valutato, con la nota",
                      g?.nonValutati == 1 && g?.notaNonValutati != nil)
    }

    // MARK: - 7 Scadenze

    private static func scadenze(_ verifica: VerificaCalcoli) {
        func pos(_ c: String, _ scadenza: Date, btp: Bool) -> Posizione {
            var p = AiutiProva.posizione("Titolo \(c)", .investimento, 10_000)
            p.clienteId = c
            p.scadenza = scadenza
            p.quotaTitoliStato = btp ? 1 : nil
            return p
        }
        let x = dati([cliente("a", "Anna Uno"), cliente("b", "Bruno Due"), cliente("c", "Carla Tre")],
                     posizioni: [pos("a", d(2027, 3, 10), btp: true), pos("b", d(2027, 3, 25), btp: true), pos("c", d(2027, 7, 10), btp: true)])
        let g = gruppi(x).filter { $0.tipo == .scadenzaNelMese }
        verifica.vero("Campagne: due scadenze a marzo entro sei mesi → «Titoli di Stato in scadenza a marzo» («\(g.first?.titolo ?? "")»)",
                      g.count == 1 && g.first?.id == "scadenzaNelMese-2027-03" && g.first?.titolo == "Titoli di Stato in scadenza a marzo"
                      && g.first?.membri.count == 2)
        let y = dati([cliente("a", "Anna Uno"), cliente("b", "Bruno Due")],
                     posizioni: [pos("a", d(2027, 3, 10), btp: true), pos("b", d(2027, 3, 25), btp: false)])
        verifica.vero("Campagne: «Titoli di Stato» solo se tutte le posizioni lo sono",
                      gruppi(y).first { $0.tipo == .scadenzaNelMese }?.titolo == "Posizioni in scadenza a marzo")
    }

    // MARK: - 8, 9 Età tonde e un cliente in due gruppi

    private static func eta(_ verifica: VerificaCalcoli) {
        let x = dati([cliente("a", "Anna Uno", nascita: d(1977, 5, 1)), cliente("b", "Bruno Due", nascita: d(1977, 9, 1)),
                      cliente("c", "Carla Tre", nascita: d(1980, 1, 1))])
        let g = gruppi(x)
        let tonda = g.first { $0.tipo == .etaTonda }
        verifica.vero("Campagne: due clienti che compiono 50 anni l'anno prossimo («\(tonda?.titolo ?? "")»)",
                      tonda?.titolo == "Compiono 50 anni nel 2027" && tonda?.membri.count == 2)
        // Anna è anche nel gruppo della previdenza assente: un pallino per gruppo, con «anche in»
        let annaEta = tonda?.membri.first { $0.clienteId == "a" }
        let annaPrev = g.first { $0.tipo == .previdenzaAssente }?.membri.first { $0.clienteId == "a" }
        verifica.vero("Campagne: lo stesso cliente in due gruppi → due membri con «anche in» reciproco",
                      annaEta?.anchein.contains("Senza previdenza integrativa") == true
                      && annaPrev?.anchein.contains("Compiono 50 anni nel 2027") == true)
    }

    // MARK: - 10 Testi

    private static func testi(_ verifica: VerificaCalcoli) {
        let clienti = [cliente("a", "Anna Uno", nascita: d(1977, 5, 1)), cliente("b", "Bruno Due", nascita: d(1977, 9, 1)),
                       cliente("c", "Carla Tre")]
        let tredici = cal.date(byAdding: .month, value: -13, to: oggi) ?? oggi
        let x = dati(clienti, posizioni: [previdenza("a", movimenti: [Movimento(data: tredici, importo: 1_000)]),
                                          previdenza("b", movimenti: [Movimento(data: tredici, importo: 800)])])
        var sbagliati: [String] = []
        let orari = [d(2026, 11, 10), d(2026, 11, 11)]
        for g in gruppi(x) {
            for m in g.membri {
                guard let c = clienti.first(where: { $0.id == m.clienteId }) else { continue }
                let o = MotoreCampagne.occasione(gruppo: g, membro: m, campagnaId: "campagna-prova", appuntamenti: orari)
                for tono in TonoMessaggio.allCases {
                    let t = ModelliMessaggi.testo(o, tono: tono, canale: .mail, cliente: c, firma: "Denis")
                    for altro in clienti where altro.id != c.id && t.completo.contains(altro.nome) {
                        sbagliati.append("\(g.id)/\(tono.rawValue): nomina \(altro.nome)")
                    }
                    if tono == .breve, t.completo.count > RegoleMessaggi.caratteriBreve { sbagliati.append("\(g.id): breve troppo lungo") }
                    let fatti = MessaggiVera.ammessi(o, cliente: c, bozza: TestoMessaggio(oggetto: nil, corpo: "", chiusura: t.chiusura))
                    if !CommentoVera.cifre(t.completo).isSubset(of: CommentoVera.cifre(fatti)) { sbagliati.append("\(g.id)/\(tono.rawValue): cifre") }
                }
                // Le cifre sono solo del membro: nessun nome d'altri nemmeno lì
                if m.cifre.contains(where: { cifra in clienti.contains { $0.id != c.id && cifra.valore.contains($0.nome) } }) {
                    sbagliati.append("\(g.id): cifre di un altro cliente")
                }
            }
        }
        verifica.vero("Campagne: ogni messaggio è per una persona sola (nessun altro nome, cifre della scheda, breve nel limite)"
                      + (sbagliati.isEmpty ? "" : " (\(sbagliati.prefix(4).joined(separator: "; ")))"), sbagliati.isEmpty)
    }

    // MARK: - 11b Le bozze fuori dal limite di «Da mandare oggi»

    private static func dividi(_ verifica: VerificaCalcoli) {
        let clienti = (0..<11).map { cliente("c\($0)", "Cliente \($0)") }
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let normali = (0..<8).map { i in
            OccasioneMessaggio(origine: OrigineMessaggio(tipo: .riesame, riferimento: "r\(i)"), clienteId: "c\(i)", canale: nil,
                               gruppo: .oggi, titolo: "Riesame", perche: "Prova", oggetto: "Prova", cifre: [], priorita: .media, data: oggi)
        }
        let bozze = (8..<11).map { i in
            OccasioneMessaggio(origine: OrigineMessaggio(tipo: .campagna, riferimento: "campagna-prova"), clienteId: "c\(i)", canale: nil,
                               gruppo: .oggi, titolo: "Campagna", perche: "Campagna: prova", oggetto: "Prova", cifre: [], priorita: .bassa, data: oggi)
        }
        let r = MotoreOccasioniMessaggi.dividi(normali + bozze, messaggi: [], clienti: perId, oggi: oggi, cal: cal)
        let prima = MotoreOccasioniMessaggi.dividi(normali, messaggi: [], clienti: perId, oggi: oggi, cal: cal)
        verifica("Campagne: «Da mandare oggi» = le 8 occasioni e tutte le 3 bozze", Double(r.oggi.count), 11)
        verifica.vero("Campagne: le bozze non scacciano le altre occasioni",
                      Array(r.oggi.prefix(8)).map(\.id) == prima.oggi.map(\.id))
        // Le bozze compaiono in «Da mandare oggi», le aperte no
        var x = dati([cliente("a", "Anna Uno"), cliente("b", "Bruno Due")])
        x.campagne = [Campagna(id: "camp-bozze", gruppoId: "previdenzaAssente", gruppoTipo: .previdenzaAssente,
                               titolo: "Senza previdenza integrativa", avviataIl: oggi, tono: .cordiale, canale: .mail,
                               clienti: ["a", "b"], appuntamenti: [], messaggi: [])]
        for id in ["a", "b"] {
            var m = MessaggioCliente(clienteId: id, occasioneId: OccasioneMessaggio.id(tipo: .campagna, clienteId: id, riferimento: "camp-bozze"),
                                     origine: OrigineMessaggio(tipo: .campagna, riferimento: "camp-bozze"), canaleLavoro: nil,
                                     tono: .cordiale, canale: .mail, oggetto: "Prova", testo: "Testo di prova", cifre: [],
                                     autore: .modelloFisso, modello: nil, creatoIl: oggi)
            if id == "b" {
                m.stato = .apertoInMail
                m.apertoIl = oggi
            }
            x.messaggi.append(m)
        }
        let o = MotoreCampagne.occasioniDaBozze(dati: x, oggi: oggi)
        verifica.vero("Campagne: in «Da mandare oggi» la bozza da aprire, con il perché «Campagna: …», e non quella aperta",
                      o.count == 1 && o.first?.clienteId == "a" && o.first?.perche == "Campagna: Senza previdenza integrativa"
                      && o.first?.id == x.messaggi.first?.occasioneId)
    }

    // MARK: - 13 Seme

    private static func seme(_ verifica: VerificaCalcoli) {
        verifica.vero("Campagne: il seme dei pallini è stabile (FNV-1a, mai hashValue)",
                      MotoreCampagne.seme("campagna-prova") == 8_007_064_738_886_908_182)
        let r = (0..<50).map { MotoreCampagne.casuale(MotoreCampagne.seme("x"), $0) }
        verifica.vero("Campagne: le posizioni di partenza stanno in 0…1", r.allSatisfy { $0 >= 0 && $0 < 1 })
        verifica("Campagne: raggio del cerchio con 7 clienti", MotoreCampagne.raggio(membri: 7), 95)
        verifica("Campagne: raggio massimo", MotoreCampagne.raggio(membri: 40), 120)
    }

    // MARK: - 15 Clienti fittizi

    private static func fittizi(_ verifica: VerificaCalcoli) {
        let g = MotoreCampagne.gruppi(dati: ClientiFittizi.completi(), oggi: Date())
        verifica.vero("Campagne: con i clienti fittizi almeno due gruppi (\(g.count))", g.count >= 2)
        let (dentro, altri) = MotoreCampagne.disposizione(g)
        verifica.vero("Campagne: al più sei gruppi nella mappa, gli altri in «Altri bisogni»",
                      dentro.count == min(6, g.count) && altri.count == max(0, g.count - 6))
        // I gruppi del template per le istantanee 862-868 (CampagneDiProva, solo nei dati della scena)
        let scena = MotoreCampagne.gruppi(dati: CampagneDiProva.datiScena(), oggi: Date())
        let tipi = Set(scena.map(\.tipo))
        verifica.vero("Campagne: i dati della scena hanno i gruppi del template (scadenze, compleanni tondi, fondi fermi)",
                      tipi.isSuperset(of: [.scadenzaNelMese, .etaTonda, .previdenzaFerma]))
        verifica.vero("Campagne: i dati della scena non toccano l'archivio di prova dei clienti fittizi",
                      !ClientiFittizi.completi().posizioni.contains { $0.id.hasPrefix(CampagneDiProva.prefisso) })
    }

    // MARK: - 11, 12 Bozze (StatoShell)

    #if os(macOS)
    private static func bozze(_ verifica: VerificaCalcoli) {
        let stato = StatoShell(persistente: false)
        stato.dati.carica(dati([cliente("a", "Anna Uno"), cliente("b", "Bruno Due"), cliente("c", "Carla Tre", consenso: false)]))
        guard let g = MotoreCampagne.gruppi(dati: stato.dati.istantanea, oggi: Date()).first(where: { $0.tipo == .previdenzaAssente }) else {
            return verifica.vero("Campagne: gruppo di prova per le bozze", false)
        }
        let inclusi = g.membri.filter(\.inclusoDiBase).map(\.clienteId)
        let primaDi = stato.dati.messaggi.count
        guard let campagna = stato.avviaCampagna(g, inclusi: inclusi, appuntamenti: [d(2026, 11, 10)], tono: .cordiale, canale: .mail) else {
            return verifica.vero("Campagne: «Avvia la campagna» crea la campagna", false)
        }
        let nuove = stato.dati.messaggi.filter { campagna.messaggi.contains($0.id) }
        verifica.vero("Campagne: una bozza per ogni incluso, nessuna aperta da sola",
                      nuove.count == inclusi.count && stato.dati.messaggi.count == primaDi + inclusi.count
                      && nuove.allSatisfy { $0.stato == .bozza && $0.apertoIl == nil && $0.origine.tipo == .campagna })
        verifica.vero("Campagne: l'id dell'occasione di ogni bozza è quello dell'occasione ricostruita",
                      nuove.allSatisfy { $0.occasioneId == OccasioneMessaggio.id(tipo: .campagna, clienteId: $0.clienteId, riferimento: campagna.id)
                          && $0.occasioneId == TestiMessaggi.occasioneDalDossier($0).id })
        verifica.vero("Campagne: chi è senza consenso non riceve la bozza di base", !nuove.contains { $0.clienteId == "c" })
        // Aprire una bozza (senza aprire davvero Mail): stesso id, nessun doppione
        if let m = nuove.first {
            let scritto = TestoScrittoMessaggio(oggetto: m.oggetto, testo: m.testo, autore: m.autore, modello: m.modello, avviso: nil)
            stato.salvaMessaggio(TestiMessaggi.occasioneDalDossier(m), tono: m.tono, canale: m.canale, scritto: scritto,
                                 stato: .apertoInMail, id: m.id)
            verifica.vero("Campagne: la bozza aperta resta un solo messaggio e non è più «da mandare»",
                          stato.dati.messaggi.count == primaDi + inclusi.count
                          && !MotoreCampagne.occasioniDaBozze(dati: stato.dati.istantanea, oggi: Date()).contains { $0.id == m.occasioneId })
            verifica.vero("Campagne: con una bozza aperta la campagna non si annulla", !stato.annullaCampagna(campagna.id))
        }
        // Un'altra campagna mai aperta si annulla e porta via le sue bozze
        stato.dati.campagne = []
        stato.dati.messaggi.removeAll { $0.origine.tipo == .campagna }
        if let seconda = stato.avviaCampagna(g, inclusi: inclusi, appuntamenti: [], tono: .breve, canale: .messaggi) {
            verifica.vero("Campagne: «Annulla la campagna» toglie le bozze e lo storico",
                          stato.annullaCampagna(seconda.id) && stato.dati.campagne.isEmpty
                          && !stato.dati.messaggi.contains { $0.origine.tipo == .campagna })
        } else {
            verifica.vero("Campagne: seconda campagna di prova", false)
        }
    }
    #endif
}
