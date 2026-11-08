import Foundation

/// Prove del giro 8 di «Luce», «Sala: racconti senza uscita» (Design/template-luce-specifica.md §3.1.5, §4.3.5,
/// §4.4.5), chiamate da `ProvaCalcoli.esegui()`. Casi costruiti a mano, DATI DI PROVA:
/// - la lettera dal futuro: anno del traguardo dalla data di nascita, niente pensione senza ipotesi confermate, la frase
///   sul fondo solo con una previdenza in proposta, arrivo «più lontano» senza data, saluto senza genere, nessun
///   segnaposto, «senza il piano» senza scenari negativi, obiettivo principale;
/// - Lancia l'anno: stesso seme stessa partita, z = 0, stesso risparmio nelle due vite, evento coperto con e senza
///   indennizzo, evento della linea della vita all'età giusta, nessun evento a caso senza probabilità e fonte, fine
///   della partita, nessuna proposta, importi di prova solo con i clienti di prova;
/// - Quanto vale avermi accanto: tre anni di deduzioni al 33%, una posizione che il cliente aveva già non conta, la
///   sostituzione dal 2,1% all'1,3% su 50.000 € per due anni, senza costo la voce manca, parcelle in bozza e annullate
///   escluse, rapporto senza compenso, canali che sommano al totale, «presto per misurare».
enum ProvaCalcoliRacconti {
    static func esegui(_ verifica: VerificaCalcoli) {
        lettera(verifica)
        lancia(verifica)
        lanciaEventi(verifica)
        valore(verifica)
    }

    private static let oggi = AiutiProva.data(2026, 11, 8)

    private static func cliente(_ id: String = "prova", nascita: Date? = AiutiProva.data(1989, 3, 14)) -> Cliente {
        var c = Cliente(id: id, nome: "Prova Racconti", iniziali: "PR", tinta: .blu, tema: "", email: "", telefono: "",
                        preferito: false, nota: "", creatoIl: AiutiProva.data(2020, 1, 1))
        c.dataNascita = nascita
        return c
    }

    // MARK: - La lettera dal futuro

    private static func lettera(_ verifica: VerificaCalcoli) {
        let c = cliente()
        var analisi = Analisi360(cliente: c, posizioni: [])
        analisi.previdenza.pensionePubblica = 1_400
        analisi.previdenza.redditoDesiderato = 2_200
        var casa = Obiettivo(clienteId: "prova", titolo: "Casa di prova", area: .casa, importo: 60_000,
                             scadenza: AiutiProva.data(2029, 11, 1))
        casa.priorita = .alta
        casa.versamentoMensile = 550
        var viaggio = Obiettivo(clienteId: "prova", titolo: "Viaggio di prova", area: .salute, importo: 5_000,
                                scadenza: AiutiProva.data(2027, 6, 1))
        viaggio.priorita = .media

        // Senza ipotesi confermate: nessuna pensione, la lettera non ne parla; età ipotizzata 67
        guard let s = MotoreLettera.scheda(cliente: c, posizioni: [], obiettivi: [viaggio, casa], analisi: analisi, oggi: oggi) else {
            return verifica.vero("Lettera: con la data di nascita la scheda c'è", false)
        }
        verifica("Lettera: anno del traguardo = anno di nascita + età di pensione (1989 + 67)", Double(s.annoTraguardo), 2056)
        verifica.vero("Lettera: età di pensione ipotizzata segnata", s.etaIpotizzata && s.etaTraguardo == 67)
        verifica.vero("Lettera: senza Previdenza confermata nessuna pensione", s.pensioneSenzaPiano == nil && s.mancanti.contains(.previdenza))
        let fissa = MotoreLettera.fissa(s, .conPiano)
        verifica.vero("Lettera: senza pensione nessuna frase sulla pensione", !fissa.contains("pensione"))
        verifica.vero("Lettera: obiettivo principale = priorità più alta", s.obiettivo == "Casa di prova")
        verifica.vero("Lettera: senza genere il saluto è «Prova,»", MotoreLettera.saluto(s) == "Prova," && fissa.hasPrefix("Prova,"))
        verifica.vero("Lettera: la lettera fissa non ha segnaposto", !fissa.contains("{") && !MotoreLettera.fissa(s, .senzaPiano).contains("{"))
        verifica.vero("Lettera: il versamento previsto (550 euro) nella versione con il piano", fissa.contains("550 euro al mese"))
        verifica.vero("Lettera: con un versamento previsto il piano c'è", s.pianoPresente && !s.mancanti.contains(.piano))

        // Con le ipotesi confermate e senza proposte: «con» = «senza», nessuna frase sul fondo
        analisi.confermate = [.previdenza]
        guard let s2 = MotoreLettera.scheda(cliente: c, posizioni: [], obiettivi: [casa], analisi: analisi, oggi: oggi) else { return }
        verifica("Lettera: senza piano la pensione è la pubblica, a 10 €", s2.pensioneSenzaPiano ?? -1, 1_400)
        verifica.vero("Lettera: senza proposte di previdenza nessuna pensione «con il piano» propria", s2.pensioneConPiano == nil)
        verifica.vero("Lettera: senza previdenza in proposta nessuna frase sul fondo",
                      !s2.fondoNelPiano && !MotoreLettera.fissa(s2, .conPiano).contains("fondo"))
        // Con una previdenza in proposta: la frase sul fondo entra e la pensione con il piano è più alta
        var pip = AiutiProva.posizione("PIP di prova", .previdenza, 0)
        pip.stato = .proposta
        pip.premio = 200
        pip.frequenza = .mensile
        pip.rendimentoAtteso = 3
        guard let s3 = MotoreLettera.scheda(cliente: c, posizioni: [pip], obiettivi: [casa], analisi: analisi, oggi: oggi) else { return }
        verifica.vero("Lettera: con una previdenza in proposta la frase sul fondo",
                      s3.fondoNelPiano && MotoreLettera.fissa(s3, .conPiano).contains("il fondo che abbiamo aperto a 37 anni"))
        verifica.vero("Lettera: con il piano la pensione è più alta", (s3.pensioneConPiano ?? 0) > (s3.pensioneSenzaPiano ?? 0))
        // Senza versamento non ci si arriva in 30 anni: «più lontano», senza data
        var lontano = casa
        lontano.importo = 5_000_000
        lontano.versamentoMensile = 0
        guard let s4 = MotoreLettera.scheda(cliente: c, posizioni: [], obiettivi: [lontano], analisi: analisi, oggi: oggi) else { return }
        let senza = MotoreLettera.fissa(s4, .senzaPiano)
        verifica.vero("Lettera: arrivo oltre 30 anni → «più lontano» senza data", s4.arrivoSenzaPiano == nil && senza.contains("più lontano"))
        verifica.vero("Lettera: «senza il piano» senza scenari negativi oltre le cifre (decisione 80)",
                      senza.range(of: LetteraVera.scenariNegativi, options: [.regularExpression, .caseInsensitive]) == nil
                        && MotoreLettera.fissa(s3, .senzaPiano).range(of: LetteraVera.scenariNegativi, options: [.regularExpression, .caseInsensitive]) == nil)
        verifica.vero("Lettera: la lettera fissa passa i controlli di Vera (cifre, prima persona, niente promesse)",
                      LetteraVera.controlla(MotoreLettera.fissa(s3, .conPiano), scheda: s3, versione: .conPiano, vietati: []) == nil)
        // Senza data di nascita: niente lettera
        verifica.vero("Lettera: senza data di nascita nessuna scheda",
                      MotoreLettera.scheda(cliente: cliente(nascita: nil), posizioni: [], obiettivi: [], analisi: analisi, oggi: oggi) == nil)
    }

    // MARK: - Lancia l'anno

    private static func posizioniLancia(proposta: Bool, rendimentoProposta: Double = IpotesiLiquidita.conto) -> [Posizione] {
        var conto = AiutiProva.posizione("Conto di prova", .liquidita, 20_000)
        conto.rendimentoAtteso = IpotesiLiquidita.conto
        var r = [conto]
        if proposta {
            // Una proposta senza volatilità né costi al rendimento del conto: le due vite devono coincidere a z = 0
            var p = AiutiProva.posizione("Piano di prova", .risparmio, 0)
            p.stato = .proposta
            p.premio = 100
            p.frequenza = .mensile
            p.rendimentoAtteso = rendimentoProposta
            p.volatilita = 0
            p.regimeFiscale = .deposito
            p.conBollo = false
            r.append(p)
        }
        return r
    }

    private static func lancia(_ verifica: VerificaCalcoli) {
        var c = cliente()
        c.profilo.risparmioAnnuo = 6_000
        func partita(_ seme: UInt64, proposta: Bool = true, anni: Int? = nil) -> PartitaLanciaAnno? {
            try? MotoreLanciaAnno.prepara(cliente: c, posizioni: posizioniLancia(proposta: proposta), obiettivi: [], eventiCliente: [],
                                          tabella: [], diProva: false, anniScelti: anni, oggi: oggi, seme: seme).get()
        }
        // 1. Stesso seme, stessa partita; semi diversi, partite diverse
        func volatile(_ seme: UInt64) -> PartitaLanciaAnno? {
            var etf = AiutiProva.posizione("ETF di prova", .investimento, 10_000)
            etf.volatilita = 15
            etf.rendimentoAtteso = 5
            return try? MotoreLanciaAnno.prepara(cliente: c, posizioni: posizioniLancia(proposta: true) + [etf], obiettivi: [],
                                                 eventiCliente: [], tabella: [], diProva: false, anniScelti: nil, oggi: oggi,
                                                 seme: seme).get()
        }
        guard var a = volatile(42), var b = volatile(42), var d = volatile(43) else {
            return verifica.vero("Lancia l'anno: la partita di prova si prepara", false)
        }
        for _ in 0..<5 { MotoreLanciaAnno.lancia(&a); MotoreLanciaAnno.lancia(&b); MotoreLanciaAnno.lancia(&d) }
        verifica.vero("Lancia l'anno: stesso seme → stessa partita", a.anni == b.anni && a.con.serie == b.con.serie)
        verifica.vero("Lancia l'anno: semi diversi → partite diverse", a.anni.map(\.rendimento) != d.anni.map(\.rendimento))
        // 2. z = 0, senza eventi: la vita senza piano cresce del conto e del risparmio
        guard var z = partita(1) else { return }
        MotoreLanciaAnno.lancia(&z, z: 0)
        verifica("Lancia l'anno: z = 0, senza piano = 20.000 × 1,005 + 6.000", z.senza.valore, 20_000 * 1.005 + 6_000, tolleranza: 0.5)
        // 3. Stesso risparmio: con una proposta al rendimento del conto, senza volatilità e costi, le vite coincidono
        verifica("Lancia l'anno: stesso risparmio nelle due vite (z = 0, proposta come il conto)", z.con.valore, z.senza.valore, tolleranza: 0.5)
        verifica("Lancia l'anno: il piano chiede 1.200 € l'anno", z.chiedeIlPiano, 1_200)
        // 7. Fine della partita all'anno massimo
        guard var corta = partita(5, anni: 3) else { return }
        for _ in 0..<3 { MotoreLanciaAnno.lancia(&corta) }
        verifica.vero("Lancia l'anno: fine della partita all'anno massimo", corta.finita && MotoreLanciaAnno.lancia(&corta) == nil
                        && corta.anni.count == 3)
        verifica("Lancia l'anno: senza scelta 12 anni", Double(partita(5)?.anniMassimi ?? 0), 12)
        verifica("Lancia l'anno: «fino alla pensione» a 37 anni con 67 = 30 anni",
                 Double(MotoreLanciaAnno.anniPartita(0, eta: 37, etaPensione: 67)), 30)
        // 8. Nessuna proposta: le due vite coincidono e lo stato lo dice
        guard var sola = partita(9, proposta: false) else { return }
        for _ in 0..<4 { MotoreLanciaAnno.lancia(&sola) }
        verifica.vero("Lancia l'anno: senza proposte le due vite sono uguali", sola.senzaPiano && sola.con.serie == sola.senza.serie)
        // Dati mancanti: senza risparmio libero non si gioca
        var senzaRisparmio = c
        senzaRisparmio.profilo.risparmioAnnuo = nil
        let manca = MotoreLanciaAnno.prepara(cliente: senzaRisparmio, posizioni: posizioniLancia(proposta: true), obiettivi: [],
                                             eventiCliente: [], tabella: [], diProva: false, anniScelti: nil, oggi: oggi, seme: 1)
        verifica.vero("Lancia l'anno: senza risparmio libero «servono il patrimonio e il risparmio»", (try? manca.get()) == nil)
    }

    private static func lanciaEventi(_ verifica: VerificaCalcoli) {
        var c = cliente()
        c.profilo.risparmioAnnuo = 6_000
        c.profilo.redditoNettoAnnuo = 24_000
        var polizza = AiutiProva.posizione("Infortuni di prova", .protezione, 0)
        polizza.stato = .proposta
        polizza.rischio = .infortuni
        let spesa = EventoAnno(id: "e-spesa", titolo: "Spesa di prova", effetto: .spesa, importo: 12_000, rischio: .infortuni, tono: .rosso)
        func partita(_ coperture: [Posizione], tabella: [EventoAnno] = [], eventi: [EventoLineaVita] = [], diProva: Bool = false) -> PartitaLanciaAnno? {
            try? MotoreLanciaAnno.prepara(cliente: c, posizioni: posizioniLancia(proposta: true) + coperture, obiettivi: [],
                                          eventiCliente: eventi, tabella: tabella, diProva: diProva, anniScelti: nil, oggi: oggi,
                                          seme: 7).get()
        }
        // 4. Evento coperto con l'indennizzo stimato: −spesa (con l'inflazione del primo anno) + indennizzo (fisso)
        polizza.indennizzoStimato = 9_000
        guard var p = partita([polizza]), let a = MotoreLanciaAnno.lancia(&p, cartaAMano: spesa, z: 0) else {
            return verifica.vero("Lancia l'anno: partita con la polizza di prova", false)
        }
        let infl = 1 + IpotesiCalcolo.inflazione / 100
        // La spesa cresce con l'inflazione, l'indennizzo scritto dalle condizioni no
        verifica("Lancia l'anno: evento coperto, con il piano −12.000 + 9.000", a.effettoCon.importo ?? 0, -12_000 * infl + 9_000, tolleranza: 0.5)
        verifica("Lancia l'anno: evento coperto solo dalla proposta, senza piano −12.000", a.effettoSenza.importo ?? 0, -12_000 * infl, tolleranza: 0.5)
        verifica.vero("Lancia l'anno: la carta dice la polizza che copre", a.copertura?.id == polizza.id && a.aMano)
        // Senza indennizzo: nessuna cifra per la parte coperta
        polizza.indennizzoStimato = nil
        guard var q = partita([polizza]), let b = MotoreLanciaAnno.lancia(&q, cartaAMano: spesa, z: 0) else { return }
        verifica.vero("Lancia l'anno: senza indennizzo stimato «dipende dalle condizioni», nessuna cifra coperta",
                      b.effettoCon.frase.contains("dipende dalle condizioni") && b.effettoCon.importo == b.effettoSenza.importo)
        // Mancato reddito: mesi × reddito netto / 12
        let malattia = EventoAnno(id: "e-mesi", titolo: "Mesi di prova", effetto: .mancatoReddito, mesi: 6, tono: .rosso)
        guard var m = partita([]), let mm = MotoreLanciaAnno.lancia(&m, cartaAMano: malattia, z: 0) else { return }
        verifica("Lancia l'anno: sei mesi senza reddito = 12.000 €", mm.effettoSenza.importo ?? 0, -12_000 * infl, tolleranza: 0.5)
        // Importi di prova solo con i clienti di prova
        let diProva = EventoAnno(id: "e-prova", titolo: "Evento di prova", effetto: .spesa, tono: .arancio, importoDiProva: 9_000)
        guard var r1 = partita([]), let x1 = MotoreLanciaAnno.lancia(&r1, cartaAMano: diProva, z: 0),
              var r2 = partita([], diProva: true), let x2 = MotoreLanciaAnno.lancia(&r2, cartaAMano: diProva, z: 0) else { return }
        verifica.vero("Lancia l'anno: un importo di prova non vale con un cliente vero", x1.effettoCon.importo == nil && !x1.diProva)
        verifica.vero("Lancia l'anno: con un cliente di prova l'importo di prova vale ed è segnato", x2.effettoCon.importo != nil && x2.diProva)
        // 5. Evento della linea della vita all'età giusta (38 anni = il primo anno: oggi 37)
        let vita = EventoLineaVita(clienteId: "prova", tipo: .eredita, eta: 39, importo: 10_000)
        guard var v = partita([], eventi: [vita]) else { return }
        let primo = MotoreLanciaAnno.lancia(&v, z: 0)
        let secondo = MotoreLanciaAnno.lancia(&v, z: 0)
        verifica.vero("Lancia l'anno: l'evento della linea della vita arriva all'età giusta (39 anni)",
                      primo?.eventoCliente == nil && secondo?.eventoCliente != nil && secondo?.eta == 39)
        // 6. Un evento senza probabilità non esce mai a caso; con probabilità 1 e la fonte sì
        let senzaProbabilita = EventoAnno(id: "e-no", titolo: "Senza probabilità", effetto: .spesa, importo: 1_000, tono: .arancio)
        guard var n = partita([], tabella: [senzaProbabilita]) else { return }
        for _ in 0..<12 { MotoreLanciaAnno.lancia(&n) }
        verifica.vero("Lancia l'anno: un evento senza probabilità non esce mai a caso", n.anni.allSatisfy { $0.evento == nil } && !n.eventiACaso)
        var conFonte = senzaProbabilita
        conFonte.probabilita = 1
        conFonte.fonte = "Fonte di prova"
        var senzaFonte = senzaProbabilita
        senzaFonte.probabilita = 1
        guard var f = partita([], tabella: [conFonte]), var g = partita([], tabella: [senzaFonte]) else { return }
        MotoreLanciaAnno.lancia(&f)
        MotoreLanciaAnno.lancia(&g)
        verifica.vero("Lancia l'anno: con probabilità e fonte l'evento esce; senza fonte no",
                      f.anni.first?.evento?.id == "e-no" && g.anni.first?.evento == nil)
        // La risorsa: solo testi di prova, nessuna probabilità
        if let t = MotoreLanciaAnno.caricati {
            verifica.vero("Lancia l'anno: la risorsa eventi-anno.json è «testi di prova» senza probabilità",
                          t.testiDiProva && !t.eventi.isEmpty && t.eventi.allSatisfy { $0.probabilita == nil && $0.importo == nil })
        }
        // Le voci dell'utente sostituiscono quelle della risorsa con lo stesso id
        let unite = MotoreLanciaAnno.eventi(risorsa: [senzaProbabilita, malattia], utente: [conFonte, spesa])
        verifica.vero("Lancia l'anno: eventi dell'utente al posto di quelli della risorsa, i nuovi in fondo",
                      unite.map(\.id) == ["e-no", "e-mesi", "e-spesa"] && unite[0].fonte == "Fonte di prova")
    }

    // MARK: - Quanto vale avermi accanto

    private static func raccomandazione(_ id: String, _ p: Posizione, accettata: Date, sostituita: String? = nil) -> Raccomandazione {
        var r = Raccomandazione(id: id, data: accettata, clienteId: p.clienteId, posizioneId: p.id, canale: p.canale, area: p.area,
                                proposta: p.nome, motivazione: "", cifre: CifreRaccomandazione(),
                                alternativa: AlternativaRaccomandazione(tipo: .altro, descrizione: "Prova", posizioneSostituitaId: sostituita,
                                                                        ricavata: false))
        r.registraScelta(.accettata, il: accettata)
        return r
    }

    private static func valore(_ verifica: VerificaCalcoli) {
        var c = cliente()
        c.profilo.redditoLordoAnnuo = 40_000
        c.clienteDal = AiutiProva.data(2023, 11, 1)
        c.canali = [.indipendente, .alleanza]
        let tabella = TabellaRiferimenti(RiferimentiRendimento())
        // 1. Un fondo pensione accettato tre anni fa, 2.000 € l'anno, reddito 40.000: tre anni al 33%
        var fondo = AiutiProva.posizione("Fondo di prova", .previdenza, 6_500)
        fondo.decorrenza = AiutiProva.data(2023, 11, 10)
        fondo.premio = 2_000
        fondo.frequenza = .annuale
        // 2. Un fondo che il cliente aveva già: non conta
        var giaSuo = AiutiProva.posizione("Fondo già del cliente", .previdenza, 9_000)
        giaSuo.decorrenza = AiutiProva.data(2015, 1, 10)
        giaSuo.premio = 3_000
        giaSuo.frequenza = .annuale
        // 3. Una sostituzione dal 2,1% all'1,3% su 50.000 € accettata due anni fa
        var vecchio = AiutiProva.posizione("Vecchio di prova", .investimento, 0)
        vecchio.stato = .chiusa
        vecchio.costoAnnuo = 2.1
        var nuovo = AiutiProva.posizione("Nuovo di prova", .investimento, 50_000, canale: .alleanza)
        nuovo.costoAnnuo = 1.3
        nuovo.decorrenza = AiutiProva.data(2024, 11, 8)
        let racc = [raccomandazione("r-fondo", fondo, accettata: AiutiProva.data(2023, 11, 5)),
                    raccomandazione("r-nuovo", nuovo, accettata: AiutiProva.data(2024, 11, 8), sostituita: vecchio.id)]
        var parcelle: [Parcella] = []
        for (i, stato) in [StatoParcella.pagata, .bozza, .annullata].enumerated() {
            var p = Parcella(id: "par-\(i)", clienteId: "prova", data: AiutiProva.data(2025, 5, 1),
                             righe: [RigaParcella(id: "r\(i)", descrizione: "Prova", importo: 1_000)])
            p.stato = stato
            if stato == .pagata { p.incassataIl = AiutiProva.data(2025, 5, 20) }
            parcelle.append(p)
        }
        let posizioni = [fondo, giaSuo, vecchio, nuovo]
        let v = MotoreValoreConsulente.calcola(cliente: c, posizioni: posizioni, raccomandazioni: racc, schede: [], parcelle: parcelle,
                                               studio: ImpostazioniStudio(), tabella: tabella, oggi: oggi)
        let attese = 3 * RegoleFiscali.risparmioDeduzione(reddito: 40_000, deduzione: 2_000)
        verifica("Valore: tre anni di deduzioni del fondo nato dal consiglio (3 × 660)", v.voce(.tasse)?.totale ?? -1, attese)
        verifica("Valore: 660 € l'anno al 33%", attese / 3, 660)
        verifica.vero("Valore: il fondo che il cliente aveva già non conta",
                      v.voce(.tasse)?.dettagli.allSatisfy { !$0.titolo.contains("già del cliente") } == true)
        verifica("Valore: sostituzione dal 2,1% all'1,3% su 50.000 € per due anni = 800 €", v.voce(.costi)?.totale ?? -1, 800, tolleranza: 3)
        verifica.vero("Valore: senza riferimenti il track record non ha misure", v.voce(.alternativa)?.totale == nil
                        && v.voce(.alternativa)?.motivoAssente?.contains("track record") == true)
        verifica.vero("Valore: qualche voce senza dati → «almeno»", v.parziale)
        verifica("Valore: solo la parcella pagata (bozza e annullata escluse)", v.parcellePagate, MotoreParcelle.importo(parcelle[0]))
        let perCanale = v.totalePerCanale.values.reduce(0, +)
        verifica("Valore: le parti per canale sommano al totale", perCanale, v.totale ?? -1)
        verifica.vero("Valore: canali distinti (Alleanza la sostituzione, indipendente il fondo)",
                      (v.totalePerCanale[.alleanza] ?? 0) > 0 && (v.totalePerCanale[.indipendente] ?? 0) > 0)
        verifica.vero("Valore: senza aliquote le provvigioni Alleanza non sono stimate", v.provvigioniStimate == nil && v.provvigioniNonStimate)
        verifica.vero("Valore: con un compenso il rapporto c'è", v.rapporto != nil)
        // Senza il costo della sostituita la voce non si conta e lo dice
        var senzaCosto = vecchio
        senzaCosto.costoAnnuo = nil
        let w = MotoreValoreConsulente.calcola(cliente: c, posizioni: [fondo, senzaCosto, nuovo], raccomandazioni: racc, schede: [],
                                               parcelle: [], studio: ImpostazioniStudio(), tabella: tabella, oggi: oggi)
        verifica.vero("Valore: senza il costo della sostituita la voce manca con il motivo",
                      w.voce(.costi)?.totale == nil && w.voce(.costi)?.motivoAssente?.contains("costo") == true)
        verifica.vero("Valore: senza compenso nessun rapporto", w.rapporto == nil)
        // Meno di 12 mesi: presto per misurare
        var nuovoCliente = c
        nuovoCliente.clienteDal = AiutiProva.data(2026, 6, 1)
        let presto = MotoreValoreConsulente.calcola(cliente: nuovoCliente, posizioni: posizioni, raccomandazioni: [], schede: [],
                                                    parcelle: [], studio: ImpostazioniStudio(), tabella: tabella, oggi: oggi)
        verifica.vero("Valore: meno di 12 mesi → «presto per misurare», nessun totale", presto.presto && presto.totale == nil)
        // L'inizio del rapporto senza clienteDal: la prima raccomandazione accettata
        var senzaData = c
        senzaData.clienteDal = nil
        let (inizio, origine) = MotoreValoreConsulente.inizio(senzaData, raccomandazioni: racc)
        verifica.vero("Valore: senza «cliente dal» vale la prima raccomandazione accettata",
                      origine == .primaRaccomandazione && inizio == AiutiProva.data(2023, 11, 5))
        verifica.vero("Valore: titolo con «almeno» quando una voce manca",
                      MotoreValoreConsulente.titolo(ImpostazioniSala.titoloValoreDiProva, valore: "1.000 €", mesi: 36, parziale: true)
                        == "In tre anni il nostro lavoro vale almeno 1.000 €.")
    }
}
