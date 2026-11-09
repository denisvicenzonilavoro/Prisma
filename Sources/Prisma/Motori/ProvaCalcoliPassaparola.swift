import Foundation

/// Prove di Clienti › Potenziali e Passaparola («Luce» giro 12, chiamate da `ProvaCalcoli.esegui()`): totali con e senza
/// stima, probabilità e data (decisione 94), nessuna probabilità per fase, albero a tre generazioni con «+ N» e cicli
/// interrotti, ambasciatori con «portato» e «in arrivo» separati (decisione 95), spostamenti e cliente nuovo, momento
/// giusto con consenso e 180 giorni (decisione 17), nuovi per anno e quota, dati di prova, testo della richiesta senza
/// nomi d'altri né cifre. Oggi fisso al 4 novembre 2026. Nomi e importi DI PROVA.
enum ProvaCalcoliPassaparola {
    private static let cal = Calendar(identifier: .gregorian)
    private static let oggi = AiutiProva.data(2026, 11, 4)

    private static func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }

    private static func cliente(_ id: String, _ nome: String, da: String? = nil, il: Date? = nil,
                                creato: Date = AiutiProva.data(2024, 5, 10)) -> Cliente {
        var c = Cliente(id: id, nome: nome, iniziali: Cliente.iniziali(di: nome), tinta: .blu, tema: "", email: "", telefono: "",
                        preferito: false, nota: "", creatoIl: creato)
        c.presentatoDa = da
        c.presentatoIl = il
        return c
    }

    private static func potenziale(_ id: String, da: String? = nil, stima: Double? = nil, prob: Int? = nil, chiusura: Date? = nil,
                                   fase: FasePotenziale = .daContattare) -> PotenzialeCliente {
        var p = PotenzialeCliente(id: id, nome: "Potenziale \(id)", creatoIl: d(2026, 9, 1))
        p.presentatoDa = da
        p.patrimonioStimato = stima
        p.probabilita = prob
        p.chiusuraPrevista = chiusura
        p.fase = fase
        return p
    }

    private static func liquidita(_ cliente: String, _ valore: Double) -> Posizione {
        var p = AiutiProva.posizione("Conto \(cliente)", .liquidita, valore)
        p.clienteId = cliente
        return p
    }

    static func esegui(_ verifica: VerificaCalcoli) {
        totali(verifica)
        albero(verifica)
        ambasciatori(verifica)
        cambi(verifica)
        momento(verifica)
        anni(verifica)
        datiDiProva(verifica)
        testoRichiesta(verifica)
        dallaCarta(verifica)
    }

    // MARK: - 1, 2 Totali

    private static func totali(_ verifica: VerificaCalcoli) {
        let clienti = [cliente("marco", "Marco Bianchi")]
        let elenco = [potenziale("a", da: "marco", prob: 40, chiusura: d(2026, 12, 1)),               // senza stima
                      potenziale("b", stima: 100_000, chiusura: d(2026, 12, 1)),                       // senza probabilità
                      potenziale("c", stima: 200_000, prob: 50, chiusura: d(2027, 2, 1)),              // l'anno dopo
                      potenziale("d", da: "marco", stima: 80_000, prob: 25, chiusura: d(2026, 12, 31)), // completo
                      potenziale("e", stima: 500_000, prob: 100, fase: .cliente),
                      potenziale("f", stima: 300_000, prob: 90, fase: .nonInteressato)]
        let t = MotorePassaparola.totali(elenco, clienti: clienti, oggi: oggi, cal: cal)
        verifica("Passaparola: potenziali delle prime quattro colonne", Double(t.conteggio), 4)
        verifica("Passaparola: senza stima contati a parte", Double(t.senzaStima), 1)
        verifica("Passaparola: patrimonio stimato = solo le stime note", t.patrimonioStimato, 380_000)
        verifica("Passaparola: dal passaparola (presentatore cliente)", Double(t.dalPassaparola), 2)
        verifica("Passaparola: probabile entro fine anno = solo il completo (80.000 × 25%)", t.probabileEntroAnno, 20_000)
        verifica("Passaparola: esclusi dal probabile", Double(t.esclusiDalProbabile), 3)
        let p = MotorePassaparola.percorso(elenco, oggi: oggi, cal: cal)
        verifica.vero("Passaparola: i non interessati non compaiono nelle colonne",
                      !FasePotenziale.colonne.contains { (p[$0] ?? []).contains { $0.id == "f" } })
        // 2. Nessuna probabilità per fase
        let spostato = MotorePassaparola.sposta(potenziale("g"), a: .analisi, il: oggi)
        verifica.vero("Passaparola: spostato in Analisi resta senza probabilità (nessun valore per fase)",
                      spostato.fase == .analisi && spostato.probabilita == nil)
    }

    // MARK: - 3 Albero

    private static func albero(_ verifica: VerificaCalcoli) {
        let clienti = [cliente("a", "Anna Uno"), cliente("b", "Bruno Due", da: "a", il: d(2016, 3, 1)),
                       cliente("c", "Carla Tre", da: "b", il: d(2018, 1, 1)), cliente("dd", "Dario Quattro", da: "c", il: d(2020, 1, 1)),
                       cliente("x", "Xenia Ciclo", da: "y"), cliente("y", "Yuri Ciclo", da: "x"),
                       cliente("o", "Orfano Presentato", da: "non-piu-in-archivio")]
        let alb = MotorePassaparola.albero(clienti: clienti, potenziali: [potenziale("p1", da: "a")], posizioni: [])
        let a = alb.primoLivello.first { $0.id == "c-a" }
        let b = a?.figli.first { $0.id == "c-b" }
        let c = b?.figli.first { $0.id == "c-c" }
        verifica.vero("Passaparola: tre generazioni (A → B → C)", a != nil && b != nil && c != nil && c?.livello == 3)
        if case .altri(let n)? = c?.figli.first?.tipo {
            verifica("Passaparola: la quarta generazione diventa «+ 1»", Double(n), 1)
        } else {
            verifica.vero("Passaparola: la quarta generazione diventa «+ N»", false)
        }
        verifica.vero("Passaparola: il potenziale presentato è figlio del suo presentatore",
                      a?.figli.contains { $0.tipo == .potenziale("p1") } == true)
        verifica.vero("Passaparola: il ciclo X ↔ Y è interrotto e segnalato",
                      !alb.ciclo.isEmpty && Set(alb.ciclo).isSubset(of: ["x", "y"])
                      && alb.primoLivello.filter { $0.id == "c-x" || $0.id == "c-y" }.count == 1)
        verifica.vero("Passaparola: presentatore non più in archivio → primo livello", alb.primoLivello.contains { $0.id == "c-o" })
        verifica("Passaparola: l'anno della presentazione più vecchia", Double(alb.annoPiuVecchio ?? 0), 2016)
        verifica.vero("Passaparola: con presentazioni l'albero non è vuoto", !alb.vuoto)
        let vuoto = MotorePassaparola.albero(clienti: [cliente("a", "Anna Uno")], potenziali: [], posizioni: [])
        verifica.vero("Passaparola: senza presentazioni l'albero è vuoto e senza anno", vuoto.vuoto && vuoto.annoPiuVecchio == nil)
        // Oltre otto presentati per persona: «+ N»
        let molti = [cliente("m", "Molti Presentati")] + (0..<11).map { cliente("f\($0)", "Figlio \($0)", da: "m") }
        let m = MotorePassaparola.albero(clienti: molti, potenziali: [], posizioni: []).primoLivello.first { $0.id == "c-m" }
        if case .altri(let n)? = m?.figli.last?.tipo {
            verifica("Passaparola: oltre otto presentati «+ 3»", Double(n), 3)
        } else {
            verifica.vero("Passaparola: oltre otto presentati «+ N»", false)
        }
    }

    // MARK: - 4 Ambasciatori

    private static func ambasciatori(_ verifica: VerificaCalcoli) {
        let clienti = [cliente("marco", "Marco Bianchi"), cliente("c1", "Primo", da: "marco"), cliente("c2", "Secondo", da: "marco"),
                       cliente("sofia", "Sofia Romano"), cliente("c3", "Terzo", da: "sofia")]
        let posizioni = [liquidita("c1", 100_000), liquidita("c2", 50_000), liquidita("c3", 70_000)]
        let r = MotorePassaparola.ambasciatori(clienti: clienti, potenziali: [potenziale("p", da: "marco", stima: 30_000)],
                                               posizioni: posizioni)
        let marco = r.first { $0.id == "marco" }
        verifica("Passaparola: Marco ha presentato tre persone", Double(marco?.presentati ?? 0), 3)
        verifica("Passaparola: «portato» = patrimonio netto dei clienti presentati", marco?.portato ?? 0, 150_000)
        verifica("Passaparola: «in arrivo» = stime dei potenziali, mai sommate al portato", marco?.inArrivo ?? 0, 30_000)
        verifica.vero("Passaparola: con una sola presentazione non è ambasciatore", !r.contains { $0.id == "sofia" })
    }

    // MARK: - 5 Cambi

    private static func cambi(_ verifica: VerificaCalcoli) {
        let p = potenziale("s", da: "marco")
        let avanti = MotorePassaparola.sposta(p, a: .primoIncontro, il: oggi)
        verifica.vero("Passaparola: lo spostamento aggiunge alla storia", avanti.storia.last == CambioFase(fase: .primoIncontro, il: oggi))
        let cliente = MotorePassaparola.sposta(avanti, a: .cliente, il: oggi)
        verifica.vero("Passaparola: «sposta» non porta mai in Cliente (serve il dossier)", cliente.fase == .primoIncontro)
        let nuovo = MotorePassaparola.clienteDa(p, tinta: .verde, oggi: oggi)
        verifica.vero("Passaparola: il cliente nuovo porta chi l'ha presentato e quando",
                      nuovo.presentatoDa == "marco" && nuovo.presentatoIl == p.creatoIl && nuovo.nome == p.nome)
    }

    // MARK: - 5b Dalla carta d'identità (§9.1.4 «È un potenziale cliente», §9.2.4 «Diventa cliente»)

    private static func dallaCarta(_ verifica: VerificaCalcoli) {
        let sofia = cliente("sofia", "Sofia Romano")
        var elena = potenziale("elena", da: "sofia", fase: .proposta)
        elena.nome = "Elena Marchi"
        elena.email = "elena.prova@example.invalid"
        elena.nota = "Nota di prova"
        var vecchia = potenziale("elena-vecchia", fase: .daContattare)
        vecchia.nome = "Elena Marchi"
        vecchia.creatoIl = d(2025, 3, 1)
        var gia = potenziale("gia", fase: .cliente)
        gia.nome = "Paolo Ferri"
        let elenco = [vecchia, elena, gia]
        let trovata = MotorePassaparola.potenzialeCorrispondente(nome: "MARCHI élena", potenziali: elenco, clienti: [sofia])
        verifica.vero("Passaparola: la carta riconosce il potenziale per nome (ordine, maiuscole e accenti non contano), il più recente",
                      trovata?.id == "elena")
        verifica.vero("Passaparola: nessun nome letto o nome diverso = nessun potenziale (mai indovinato)",
                      MotorePassaparola.potenzialeCorrispondente(nome: nil, potenziali: elenco, clienti: []) == nil
                      && MotorePassaparola.potenzialeCorrispondente(nome: "Elena Marchetti", potenziali: elenco, clienti: []) == nil)
        verifica.vero("Passaparola: un potenziale già in «Cliente» non si riconosce di nuovo",
                      MotorePassaparola.potenzialeCorrispondente(nome: "Paolo Ferri", potenziali: elenco, clienti: []) == nil)
        var collegata = elena
        collegata.clienteId = "sofia"
        verifica.vero("Passaparola: un potenziale collegato a un dossier che esiste non si riconosce",
                      MotorePassaparola.potenzialeCorrispondente(nome: "Elena Marchi", potenziali: [collegata], clienti: [sofia]) == nil)

        // Il cliente nato dalla carta porta chi l'ha presentata e i recapiti scritti dall'utente, non sovrascrive la carta
        var daCarta = cliente("nuova", "Elena Marchi", creato: oggi)
        daCarta.telefono = "000 0000000"
        let nuovo = MotorePassaparola.cliente(daCarta, dalPotenziale: elena)
        verifica.vero("Passaparola: dalla carta, il cliente porta presentatoDa e la data della presentazione",
                      nuovo.presentatoDa == "sofia" && nuovo.presentatoIl == elena.creatoIl && nuovo.nome == "Elena Marchi")
        verifica.vero("Passaparola: dalla carta, recapiti e nota del potenziale solo dove mancano",
                      nuovo.email == elena.email && nuovo.telefono == "000 0000000" && nuovo.nota == "Nota di prova")
        let senzaNome = MotorePassaparola.cliente(cliente("vuota", "", creato: oggi), dalPotenziale: elena)
        verifica.vero("Passaparola: «Scrivi a mano» senza nome letto prende il nome del potenziale",
                      senzaNome.nome == "Elena Marchi" && senzaNome.iniziali == Cliente.iniziali(di: "Elena Marchi"))
        let libera = MotorePassaparola.cliente(daCarta, dalPotenziale: vecchia)
        verifica.vero("Passaparola: una fonte libera non diventa un presentatore", libera.presentatoDa == nil && libera.presentatoIl == nil)

        let diventata = MotorePassaparola.diventato(elena, cliente: "nuova", il: oggi)
        verifica.vero("Passaparola: il potenziale diventato cliente passa in «Cliente», collegato, con la storia",
                      diventata.fase == .cliente && diventata.clienteId == "nuova"
                      && diventata.storia.last == CambioFase(fase: .cliente, il: oggi))

        // La frase della scena: il genere dalla carta, mai indovinato
        verifica.vero("Passaparola: «è tra i potenziali, presentata da Sofia» con la carta di una donna",
                      TestiPassaparola.traIPotenziali(elena, clienti: [sofia], femminile: true)
                        == "Elena Marchi è tra i potenziali, presentata da Sofia")
        verifica.vero("Passaparola: «presentato da» per un uomo, «su presentazione di» se il genere non si sa",
                      TestiPassaparola.traIPotenziali(elena, nome: "Elio Marchi", clienti: [sofia], femminile: false)
                        == "Elio Marchi è tra i potenziali, presentato da Sofia"
                      && TestiPassaparola.traIPotenziali(elena, clienti: [sofia], femminile: nil)
                        == "Elena Marchi è tra i potenziali, su presentazione di Sofia")
        var dalSito = vecchia
        dalSito.fonte = "dal sito dello studio"
        verifica.vero("Passaparola: senza presentatore la fonte libera tra parentesi, o solo «è tra i potenziali»",
                      TestiPassaparola.traIPotenziali(dalSito, clienti: [sofia], femminile: true)
                        == "Elena Marchi è tra i potenziali (dal sito dello studio)"
                      && TestiPassaparola.traIPotenziali(vecchia, clienti: [], femminile: true) == "Elena Marchi è tra i potenziali")
    }

    // MARK: - 6 Momento giusto

    private static func momento(_ verifica: VerificaCalcoli) {
        func dati(consenso: Bool, richiesta: Date? = nil, pratica: Bool = false) -> DatiPrisma {
            var sofia = cliente("sofia", "Sofia Romano")
            sofia.consensi.marketing = consenso
            sofia.consensi.dataMarketing = consenso ? d(2026, 6, 1) : nil
            var x = DatiPrisma(clienti: [sofia], appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: "sofia",
                               impostazioni: Impostazioni())
            if pratica {
                var p = AiutiProva.posizione("Piano Futuro", .risparmio, 10_000)
                p.clienteId = "sofia"
                p.stato = .proposta
                p.esito = .accettata
                p.id = "pos-firma"
                x.posizioni = [p]
                x.pratiche = [Pratica(id: "pratica-firma", posizioneId: "pos-firma", apertaIl: d(2026, 11, 1))]
            } else {
                var o = Obiettivo(clienteId: "sofia", titolo: "Rendita integrativa", area: .pensione, importo: 120_000, scadenza: d(2026, 11, 3))
                o.id = "obiettivo-momento"
                o.accantonato = 120_000
                o.creatoIl = d(2021, 1, 1)
                o.raggiuntoIl = d(2026, 11, 3)
                x.obiettivi = [o]
            }
            if let r = richiesta {
                var m = MessaggioCliente(clienteId: "sofia", occasioneId: "richiestaPresentazione-sofia-vecchia",
                                         origine: OrigineMessaggio(tipo: .richiestaPresentazione, riferimento: "vecchia"),
                                         canaleLavoro: nil, tono: .cordiale, canale: .mail, oggetto: nil, testo: "Testo di prova",
                                         cifre: [], autore: .modelloFisso, modello: nil, creatoIl: r)
                m.stato = .apertoInMail
                m.apertoIl = r
                x.messaggi = [m]
            }
            return x
        }
        let uno = MotorePassaparola.momentoGiusto(dati: dati(consenso: true), oggi: oggi, cal: cal)
        verifica.vero("Passaparola: traguardo ieri e consenso valido → il momento giusto, con un fatto («\(uno.first?.fatto ?? "")»)",
                      uno.count == 1 && uno.first?.fatto.contains("ha raggiunto") == true
                      && uno.first?.fatto.contains("content") == false)
        verifica.vero("Passaparola: senza consenso commerciale nessun momento",
                      MotorePassaparola.momentoGiusto(dati: dati(consenso: false), oggi: oggi, cal: cal).isEmpty)
        let cento = cal.date(byAdding: .day, value: -100, to: oggi) ?? oggi
        let duecento = cal.date(byAdding: .day, value: -200, to: oggi) ?? oggi
        verifica.vero("Passaparola: una richiesta di 100 giorni fa → nessun momento",
                      MotorePassaparola.momentoGiusto(dati: dati(consenso: true, richiesta: cento), oggi: oggi, cal: cal).isEmpty)
        verifica("Passaparola: una richiesta di 200 giorni fa → il momento c'è",
                 Double(MotorePassaparola.momentoGiusto(dati: dati(consenso: true, richiesta: duecento), oggi: oggi, cal: cal).count), 1)
        let firma = MotorePassaparola.momentoGiusto(dati: dati(consenso: true, pratica: true), oggi: oggi, cal: cal)
        verifica.vero("Passaparola: una firma di 3 giorni fa (pratica aperta) → il momento giusto",
                      firma.count == 1 && firma.first?.riferimento == "pos-firma" && firma.first?.fatto.hasPrefix("ha firmato") == true)
    }

    // MARK: - 7 Anni e quota

    private static func anni(_ verifica: VerificaCalcoli) {
        var vecchio = cliente("v", "Vecchio Cliente", creato: d(2015, 1, 1))
        vecchio.clienteDal = d(2015, 1, 1)
        var nuovo1 = cliente("n1", "Nuovo Uno", da: "v", creato: d(2026, 3, 1))
        nuovo1.clienteDal = d(2026, 3, 1)
        let nuovo2 = cliente("n2", "Nuovo Due", creato: d(2025, 6, 1))
        let clienti = [vecchio, nuovo1, nuovo2]
        let anni = MotorePassaparola.nuoviPerAnno(clienti: clienti, oggi: oggi, cal: cal)
        verifica.vero("Passaparola: cinque colonne, l'ultima l'anno in corso con 1 su 1",
                      anni.count == 5 && anni.last?.anno == 2026 && anni.last?.dalPassaparola == 1 && anni.last?.totali == 1)
        let q = MotorePassaparola.quotaPassaparola(clienti: clienti, posizioni: [liquidita("n1", 30_000), liquidita("n2", 10_000)],
                                                   oggi: oggi, cal: cal)
        verifica("Passaparola: quota del patrimonio nuovo dal passaparola", q?.quota ?? -1, 0.75)
        verifica("Passaparola: contati solo con la data della scheda (la nota)", Double(q?.senzaDataVera ?? -1), 1)
        verifica.vero("Passaparola: senza clienti negli ultimi tre anni nessuna quota",
                      MotorePassaparola.quotaPassaparola(clienti: [vecchio], posizioni: [], oggi: oggi, cal: cal) == nil)
    }

    // MARK: - 8 Dati di prova

    private static func datiDiProva(_ verifica: VerificaCalcoli) {
        let p = PotenzialiDiProva.potenziali(oggi: oggi, calendario: cal)
        verifica.vero("Passaparola: otto potenziali di prova, tutti dichiarati, nessuno in Cliente",
                      p.count == 8 && p.allSatisfy { $0.diProva && $0.id.hasPrefix(PotenzialiDiProva.prefisso) } && !p.contains { $0.fase == .cliente })
        let t = MotorePassaparola.totali(p, clienti: DatiDemo.clienti(), oggi: oggi, cal: cal)
        verifica.vero("Passaparola: nei dati di prova la tile del probabile esclude chi chiude l'anno dopo",
                      t.esclusiDalProbabile == 3 && t.dalPassaparola == 6)
        var x = DatiPrisma.demo()
        var tolti = x.potenziali
        PotenzialiDiProva.togli(&tolti)
        x.potenziali = tolti
        verifica.vero("Passaparola: i potenziali di prova si tolgono con i dati di prova", x.potenziali.isEmpty)
    }

    // MARK: - 9 Testo della richiesta

    private static func testoRichiesta(_ verifica: VerificaCalcoli) {
        let sofia = cliente("sofia", "Sofia Romano")
        let altri = DatiDemo.clienti().filter { $0.id != "sofia" }
        let m = MomentoPerChiedere(id: "sofia-prova", clienteId: "sofia", fatto: "ha raggiunto «Rendita integrativa» ieri",
                                   riferimento: "prova", data: oggi)
        let o = MotorePassaparola.occasioneRichiesta(m, cliente: sofia, posizioni: [])
        var sbagliati: [String] = []
        for tono in TonoMessaggio.allCases {
            let t = ModelliMessaggi.testo(o, tono: tono, canale: .mail, cliente: sofia, firma: "Denis")
            if altri.contains(where: { t.completo.contains($0.nome) || t.completo.contains(TestiTraguardi.primoNome($0.nome) + " ") }) {
                sbagliati.append("\(tono.rawValue): nome di un altro cliente")
            }
            let fatti = MessaggiVera.ammessi(o, cliente: sofia, bozza: TestoMessaggio(oggetto: nil, corpo: "", chiusura: t.chiusura))
            if !CommentoVera.cifre(t.completo).isSubset(of: CommentoVera.cifre(fatti)) { sbagliati.append("\(tono.rawValue): cifre") }
        }
        verifica.vero("Passaparola: la richiesta di presentazione non cita altri clienti né cifre"
                      + (sbagliati.isEmpty ? "" : " (\(sbagliati.joined(separator: "; ")))"), sbagliati.isEmpty && o.commerciale)
    }
}
