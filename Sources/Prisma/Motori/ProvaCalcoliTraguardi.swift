import Foundation

/// Prove dei traguardi festeggiati (Design/template-luce-specifica.md §5.4.5 punto 5.2, «Luce» giro 5): l'obiettivo che
/// supera la quota diventa traguardo una sola volta, l'anniversario a 1 anno esatto e non a 2 (salvo 5, 10…), dalla data
/// d'inserimento con l'avviso, il mutuo alla scadenza, gli studi del figlio solo con un obiettivo avviato, nessuna cifra
/// senza dato, un traguardo festeggiato che non torna (con la spunta fino a domani), lo scartato e i tipi spenti, l'idea
/// per il regalo solo dalle note, le frasi senza cifre, il gruppo «Da festeggiare» non commerciale e un messaggio con un
/// tipo sconosciuto che si salta senza far fallire la lettura degli altri (`ElencoTollerante`).
/// Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliTraguardi {
    static func esegui(_ verifica: VerificaCalcoli) {
        obiettivi(verifica)
        anniversari(verifica)
        mutuoEStudi(verifica)
        festeggiatiEScartati(verifica)
        ideaRegalo(verifica)
        messaggi(verifica)
        tolleranza(verifica)
    }

    private static let cal = Calendar(identifier: .gregorian)
    private static func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }
    /// Oggi delle prove: sabato 7 novembre 2026, mezzogiorno.
    private static let oggi = d(2026, 11, 7)

    private static func cliente(_ id: String, _ nome: String, creato: Date = d(2026, 1, 10)) -> Cliente {
        Cliente(id: id, nome: nome, iniziali: String(nome.prefix(2)).uppercased(), tinta: .blu, tema: "", email: "",
                telefono: "", preferito: false, nota: "", creatoIl: creato)
    }

    private static func archivio(_ clienti: [Cliente], _ modifica: (inout DatiPrisma) -> Void = { _ in }) -> DatiPrisma {
        var dati = DatiPrisma(clienti: clienti, appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: clienti.first?.id ?? "",
                              impostazioni: Impostazioni())
        modifica(&dati)
        return dati
    }

    private static func calcola(_ dati: DatiPrisma, oggi: Date = oggi) -> [Traguardo] {
        MotoreTraguardi.calcola(dati: dati, oggi: oggi, cal: cal)
    }

    /// Nessuna cifra nella frase (il biglietto non inventa numeri).
    private static func senzaCifre(_ s: String) -> Bool { !s.contains { $0.isNumber } }

    // MARK: Obiettivi

    private static func obiettivi(_ verifica: VerificaCalcoli) {
        var o = Obiettivo(clienteId: "sofia", titolo: "Rendita integrativa", area: .pensione, importo: 120_000, scadenza: d(2026, 11, 6))
        o.id = "ob-sofia"
        o.accantonato = 120_000
        o.creatoIl = cal.date(byAdding: .month, value: -66, to: d(2026, 11, 6)) ?? oggi
        var parziale = Obiettivo(clienteId: "sofia", titolo: "Viaggio", area: .patrimonio, importo: 10_000, scadenza: d(2027, 6, 1))
        parziale.id = "ob-viaggio"
        parziale.accantonato = 4_000
        var vuoto = Obiettivo(clienteId: "sofia", titolo: "Senza importo", area: .patrimonio, importo: 0, scadenza: d(2027, 6, 1))
        vuoto.id = "ob-vuoto"
        let base = archivio([cliente("sofia", "Sofia Romano")]) { $0.obiettivi = [o, parziale, vuoto] }

        // Lo stato scrive la data la prima volta: il motore dice solo quali sono da segnare
        verifica.vero("Traguardi: da segnare solo l'obiettivo raggiunto con un importo",
                      MotoreTraguardi.daSegnareRaggiunti(dati: base) == ["ob-sofia"])
        verifica.vero("Traguardi: senza la data di raggiungimento nessun traguardo", calcola(base).isEmpty)

        var segnato = base
        segnato.obiettivi[0].raggiuntoIl = d(2026, 11, 6)
        verifica.vero("Traguardi: con la data già scritta non è più da segnare (una sola volta)",
                      MotoreTraguardi.daSegnareRaggiunti(dati: segnato).isEmpty)
        let t = calcola(segnato)
        verifica.vero("Traguardi: l'obiettivo raggiunto ieri è un traguardo", t.count == 1 && t.first?.tipo == .obiettivoRaggiunto)
        verifica.vero("Traguardi: perché «Obiettivo raggiunto ieri»", t.first?.perche == "Obiettivo raggiunto ieri")
        verifica("Traguardi: la cifra è l'importo dell'obiettivo", t.first?.cifra ?? 0, 120_000)
        verifica.vero("Traguardi: «messi al sicuro in 5 anni e mezzo» (66 mesi)",
                      t.first?.didascaliaCifra == "messi al sicuro in 5 anni e mezzo")
        verifica.vero("Traguardi: saluto «Ce l’hai fatta, Sofia.» e titolo", t.first?.saluto == "Ce l’hai fatta, Sofia."
                      && t.first?.titolo == "Ha raggiunto «Rendita integrativa»")
        verifica.vero("Traguardi: la frase dell'obiettivo non ha cifre", senzaCifre(t.first?.frase ?? "1"))
        verifica.vero("Traguardi: id stabile", t.first?.id == "obiettivoRaggiunto-sofia-ob-sofia")

        // Fuori dalla finestra di 7 giorni
        var vecchio = segnato
        vecchio.obiettivi[0].raggiuntoIl = d(2026, 10, 20)
        verifica.vero("Traguardi: raggiunto 18 giorni fa, fuori dalla finestra", calcola(vecchio).isEmpty)
        verifica.vero("Traguardi: durata sotto il mese senza didascalia",
                      TestiTraguardi.durata(da: d(2026, 11, 1), a: d(2026, 11, 6), cal: cal) == nil)
        verifica.vero("Traguardi: durata «in un anno» e «in 8 mesi»",
                      TestiTraguardi.durata(da: d(2025, 11, 6), a: d(2026, 11, 6), cal: cal) == "in un anno"
                      && TestiTraguardi.durata(da: d(2026, 3, 6), a: d(2026, 11, 6), cal: cal) == "in 8 mesi")
    }

    // MARK: Anniversari

    private static func anniversari(_ verifica: VerificaCalcoli) {
        func conPrimo(_ data: Date) -> DatiPrisma {
            archivio([cliente("giulia", "Giulia Rossi", creato: d(2026, 3, 1))]) {
                $0.appuntamenti = [Appuntamento(id: "a1", clienteId: "giulia", titolo: "Primo incontro", inizio: data, durataMinuti: 60,
                                                luogo: "", note: "", stato: .concluso, tipo: .primoIncontro),
                                   // Uno pianificato prima non conta: non è un incontro fatto
                                   Appuntamento(id: "a0", clienteId: "giulia", titolo: "Mai fatto", inizio: d(2020, 1, 1), durataMinuti: 60,
                                                luogo: "", note: "", stato: .pianificato)]
            }
        }
        let uno = calcola(conPrimo(d(2025, 11, 5)))
        verifica.vero("Traguardi: anniversario a un anno esatto (5 novembre 2025, due giorni fa)",
                      uno.count == 1 && uno.first?.tipo == .anniversario && uno.first?.titolo == "Un anno insieme")
        verifica.vero("Traguardi: perché «Il primo incontro fu il 5 novembre 2025»",
                      uno.first?.perche == "Il primo incontro fu il 5 novembre 2025")
        verifica.vero("Traguardi: l'anniversario non ha cifre (nessuno storico inventato)", uno.first?.cifra == nil)
        verifica.vero("Traguardi: a due anni nessun anniversario", calcola(conPrimo(d(2024, 11, 5))).isEmpty)
        let cinque = calcola(conPrimo(d(2021, 11, 4)))
        verifica.vero("Traguardi: a cinque anni sì («5 anni insieme»)", cinque.first?.titolo == "5 anni insieme")
        verifica.vero("Traguardi: la frase dell'anniversario a un anno non ha cifre", senzaCifre(uno.first?.frase ?? "1"))

        // Senza appuntamenti conclusi: dalla data d'inserimento, con l'avviso
        let inserito = archivio([cliente("marco", "Marco Bianchi", creato: d(2025, 11, 3))])
        let t = calcola(inserito)
        verifica.vero("Traguardi: senza incontri l'anniversario parte dall'inserimento e lo dice",
                      t.count == 1 && (t.first?.perche.contains("dalla data d’inserimento") ?? false))
        // Anniversari scelti: senza l'1 nessun anniversario a un anno
        var senzaUno = conPrimo(d(2025, 11, 5))
        senzaUno.impostazioni.traguardi.anniversari = [5, 10]
        verifica.vero("Traguardi: gli anniversari seguono le impostazioni", calcola(senzaUno).isEmpty)
    }

    // MARK: Mutuo e studi

    private static func mutuoEStudi(_ verifica: VerificaCalcoli) {
        var mutuo = Posizione(clienteId: "laura", canale: .indipendente, stato: .inEssere, area: .debiti, nome: "Mutuo casa")
        mutuo.id = "mutuo"
        mutuo.scadenza = d(2026, 11, 5)
        var futuro = mutuo
        futuro.id = "mutuo-futuro"
        futuro.scadenza = d(2026, 11, 20)
        let dati = archivio([cliente("laura", "Laura Moretti")]) { $0.posizioni = [mutuo, futuro] }
        let t = calcola(dati)
        verifica.vero("Traguardi: il mutuo arrivato alla scadenza è un traguardo (quello futuro no)",
                      t.count == 1 && t.first?.tipo == .mutuoEstinto && t.first?.titolo == "Ha finito di pagare «Mutuo casa»")

        // Il figlio compie 18 anni due giorni fa: traguardo solo con un obiettivo della famiglia avviato
        var c = cliente("marco", "Marco Bianchi")
        c.famiglia = [Familiare(id: "tommaso", nome: "Tommaso Bianchi", relazione: .figlio, dataNascita: d(2008, 11, 5))]
        let senzaPiano = calcola(archivio([c]))
        verifica.vero("Traguardi: il figlio maggiorenne senza un piano degli studi non è un traguardo",
                      !senzaPiano.contains { $0.tipo == .studiFigli })
        var studi = Obiettivo(clienteId: "marco", titolo: "Studi di Tommaso", area: .famiglia, importo: 40_000, scadenza: d(2027, 9, 1))
        studi.accantonato = 12_000
        let conPiano = calcola(archivio([c]) { $0.obiettivi = [studi] })
        verifica.vero("Traguardi: con l'obiettivo avviato sì, «il piano per gli studi è avviato»",
                      conPiano.first { $0.tipo == .studiFigli }?.titolo == "Tommaso compie 18 anni: il piano per gli studi è avviato")
    }

    // MARK: Festeggiati, scartati, tipi spenti

    private static func festeggiatiEScartati(_ verifica: VerificaCalcoli) {
        var o = Obiettivo(clienteId: "sofia", titolo: "Rendita", area: .pensione, importo: 50_000, scadenza: d(2026, 11, 6))
        o.id = "ob"
        o.accantonato = 50_000
        o.raggiuntoIl = d(2026, 11, 6)
        let base = archivio([cliente("sofia", "Sofia Romano")]) { $0.obiettivi = [o] }
        let id = "obiettivoRaggiunto-sofia-ob"

        var oggiFesteggiato = base
        oggiFesteggiato.impostazioni.traguardi.festeggiati[id] = d(2026, 11, 7)
        let tOggi = calcola(oggiFesteggiato)
        let occOggi = MotoreTraguardi.occasioni(tOggi, oggi: oggi, cal: cal)
        verifica.vero("Traguardi: festeggiato oggi resta con la spunta fino a domani",
                      occOggi.count == 1 && occOggi.first?.preparatoIl != nil)

        var ieriFesteggiato = base
        ieriFesteggiato.impostazioni.traguardi.festeggiati[id] = d(2026, 11, 6)
        verifica.vero("Traguardi: festeggiato ieri non torna in Messaggi",
                      MotoreTraguardi.occasioni(calcola(ieriFesteggiato), oggi: oggi, cal: cal).isEmpty)

        var scartato = base
        scartato.impostazioni.traguardi.scartati = [id]
        verifica.vero("Traguardi: «Non è un traguardo» non torna", calcola(scartato).isEmpty)

        var spento = base
        spento.impostazioni.traguardi.tipiSpenti = [.obiettivoRaggiunto]
        verifica.vero("Traguardi: un tipo spento non dà traguardi", calcola(spento).isEmpty)

        // La storia della settimana non propone un traguardo già festeggiato
        let pagine = MotoreStorie.settimana(dati: oggiFesteggiato, oggi: oggi, cal: cal)
        verifica.vero("Traguardi: la storia non propone un traguardo già festeggiato",
                      !pagine.contains { $0.nome == "traguardo" })
        verifica.vero("Traguardi: la storia propone quello da festeggiare",
                      MotoreStorie.settimana(dati: base, oggi: oggi, cal: cal).contains {
                          if case .traguardo(let c, _, let t) = $0 { return c == "sofia" && t == id }
                          return false
                      })
    }

    // MARK: Idea per il regalo

    private static func ideaRegalo(_ verifica: VerificaCalcoli) {
        let c = cliente("sofia", "Sofia Romano")
        verifica.vero("Traguardi: note che non parlano di regali, nessuna idea",
                      MotoreTraguardi.ideaRegalo(cliente: c, note: [Nota(clienteId: "sofia", titolo: "Viaggi", testo: "Ama la montagna.")],
                                                 obiettivi: []) == nil)
        let nota = Nota(clienteId: "sofia", titolo: "Nipoti", testo: "Ha tre nipoti. Una guida di Vienna sarebbe un bel regalo. Fine.")
        let idea = MotoreTraguardi.ideaRegalo(cliente: c, note: [nota], obiettivi: [])
        verifica.vero("Traguardi: l'idea è la frase della nota che parla del regalo, con la fonte",
                      idea?.testo == "Una guida di Vienna sarebbe un bel regalo." && idea?.fonte == "dalla nota «Nipoti»")
        var conNotaScheda = c
        conNotaScheda.nota = "Le piacciono i fiori: da regalare per l'anniversario."
        verifica.vero("Traguardi: anche dalle note della scheda",
                      MotoreTraguardi.ideaRegalo(cliente: conNotaScheda, note: [], obiettivi: [])?.fonte == "dalle note del cliente")
    }

    // MARK: Messaggi

    private static func messaggi(_ verifica: VerificaCalcoli) {
        var o = Obiettivo(clienteId: "sofia", titolo: "Rendita", area: .pensione, importo: 50_000, scadenza: d(2026, 11, 6))
        o.accantonato = 50_000
        o.raggiuntoIl = d(2026, 11, 6)
        let dati = archivio([cliente("sofia", "Sofia Romano")]) { $0.obiettivi = [o] }
        let elenco = MotoreOccasioniMessaggi.calcola(dati: dati, oggi: oggi, cal: cal)
        verifica.vero("Traguardi: in Messaggi il gruppo «Da festeggiare» ha il traguardo, prima degli altri",
                      elenco.festeggiare.count == 1 && elenco.tutte.first?.tipo == .traguardo && GruppoMessaggio.allCases.first == .festeggiare)
        verifica.vero("Traguardi: un traguardo non è commerciale", elenco.festeggiare.first?.commerciale == false)
        verifica.vero("Traguardi: in modalità cliente solo i suoi",
                      elenco.soloCliente("altro").festeggiare.isEmpty && elenco.soloCliente("sofia").festeggiare.count == 1)
        verifica.vero("Traguardi: senza traguardi il gruppo non c'è (non un gruppo vuoto)",
                      MotoreOccasioniMessaggi.calcola(dati: archivio([cliente("sofia", "Sofia Romano")]), oggi: oggi, cal: cal)
                          .festeggiare.isEmpty)
    }

    // MARK: Lettura tollerante

    private static func tolleranza(_ verifica: VerificaCalcoli) {
        func messaggio(_ tipo: TipoOccasioneMessaggio, _ rif: String) -> MessaggioCliente {
            MessaggioCliente(clienteId: "sofia", occasioneId: "\(tipo.rawValue)-sofia-\(rif)",
                             origine: OrigineMessaggio(tipo: tipo, riferimento: rif), canaleLavoro: nil, tono: .cordiale,
                             canale: .mail, oggetto: "Auguri", testo: "Ciao Sofia", cifre: [], autore: .modelloFisso, modello: nil)
        }
        let elenco = [messaggio(.compleanno, "2026"), messaggio(.traguardo, "obiettivoRaggiunto-sofia-ob")]
        guard let dati = try? JSONEncoder().encode(elenco), let testo = String(data: dati, encoding: .utf8) else {
            verifica.vero("Traguardi: messaggi codificati", false)
            return
        }
        let letti = (try? JSONDecoder().decode(ElencoTollerante<MessaggioCliente>.self, from: dati))?.elementi ?? []
        verifica.vero("Traguardi: il messaggio di un traguardo si rilegge", letti.count == 2 && letti.last?.origine.tipo == .traguardo)
        // Un tipo che questo Prisma non conosce (come vede `traguardo` un Prisma di prima): si salta, gli altri restano
        let futuro = testo.replacingOccurrences(of: "\"traguardo\"", with: "\"tipoDelFuturo\"")
        let tollerati = (try? JSONDecoder().decode(ElencoTollerante<MessaggioCliente>.self, from: Data(futuro.utf8)))?.elementi
        verifica.vero("Traguardi: un messaggio con un tipo sconosciuto si salta senza perdere gli altri",
                      tollerati?.count == 1 && tollerati?.first?.origine.tipo == .compleanno)
    }
}
