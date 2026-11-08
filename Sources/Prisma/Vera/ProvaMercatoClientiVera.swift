import Foundation

/// Prova di «Il mercato per i tuoi clienti» (Vera/BRIEF.md, funzione 14) dentro `Prisma --prova-vera`: il riconoscimento
/// a regole delle frasi (tassi BCE, inflazione, borse, misure mancanti, «e se»), gli eventi dalle serie e dagli avvisi di
/// Mercato, i clienti toccati con motivo, azione e cifre di Prisma (quattro clienti di prova con date fisse), le bozze
/// fisse nel tono giusto, le bozze di Qwen controllate (cifre, promesse, altri clienti, tu e Lei), le azioni per la
/// scheda «Conferma» e i cinque clienti del template. Deterministica: `oggi` fisso, niente rete, niente Qwen vero.
enum ProvaMercatoClientiVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        riconoscimento(controlla)
        serie(controlla)
        borse(controlla)
        tassi(controlla)
        inflazione(controlla)
        bozzeFisse(controlla)
        qwen(controlla)
        conferma(controlla)
        template(controlla)
    }

    // MARK: - Dati di prova (date fisse)

    private static let cal = Calendar(identifier: .gregorian)

    private static func giorno(_ a: Int, _ m: Int, _ g: Int, _ ora: Int = 12) -> Date {
        cal.date(from: DateComponents(year: a, month: m, day: g, hour: ora)) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    /// Lunedì 9 novembre 2026, a mezzogiorno.
    private static var oggi: Date { giorno(2026, 11, 9) }

    private static func cliente(_ id: String, _ nome: String, nato: Date, telefono: String = "", email: String = "") -> Cliente {
        var c = Cliente(id: id, nome: nome, iniziali: Cliente.iniziali(di: nome), tinta: .blu, tema: "", email: email, telefono: telefono,
                        preferito: false, nota: "", creatoIl: giorno(2024, 1, 10))
        c.dataNascita = nato
        return c
    }

    private static func posizione(_ id: String, _ cliente: String, _ canale: Canale, _ area: AreaPosizione, _ nome: String,
                                  valore: Double, _ configura: (inout Posizione) -> Void = { _ in }) -> Posizione {
        var p = Posizione(clienteId: cliente, canale: canale, stato: .inEssere, area: area, nome: nome)
        p.id = id
        p.controvalore = valore
        configura(&p)
        return p
    }

    /// Anna (32 anni, tutto in un ETF azionario, poca liquidità), Bruno (60 anni, fondo bilanciato, rivalutabile in
    /// scadenza, molta liquidità, mutuo variabile), Carla (prudente, obiettivo casa, incontro giovedì), Dario (solo
    /// una polizza di protezione: mai toccato).
    private static func dati() -> DatiMercatoClienti {
        let anna = cliente("anna", "Anna Verdi", nato: giorno(1994, 3, 1), telefono: "333 1234567", email: "anna@esempio.it")
        var bruno = cliente("bruno", "Bruno Neri", nato: giorno(1966, 5, 10), email: "bruno@esempio.it")
        bruno.profilo.propensione = .moderata
        var carla = cliente("carla", "Carla Bassi", nato: giorno(1980, 6, 1), telefono: "347 7654321")
        carla.profilo.propensione = .prudente
        let dario = cliente("dario", "Dario Galli", nato: giorno(1975, 2, 2))
        let posizioni = [
            posizione("anna-etf", "anna", .indipendente, .investimento, "ETF azionario globale", valore: 40_000) {
                $0.tipologia = "ETF azionario"; $0.quotaAzionaria = 100
            },
            posizione("anna-conto", "anna", .indipendente, .liquidita, "Conto corrente", valore: 9_000),
            posizione("bruno-fondo", "bruno", .indipendente, .investimento, "Fondo bilanciato", valore: 60_000) {
                $0.tipologia = "Fondo comune bilanciato"; $0.quotaAzionaria = 60
            },
            posizione("bruno-rivalutabile", "bruno", .alleanza, .risparmio, "Polizza rivalutabile", valore: 50_000) {
                $0.tipologia = "Polizza rivalutabile a premio unico (Ramo I)"; $0.scadenza = giorno(2027, 3, 15); $0.rendimentoAtteso = 2.5
            },
            posizione("bruno-conto", "bruno", .indipendente, .liquidita, "Conto deposito", valore: 30_000),
            posizione("bruno-mutuo", "bruno", .indipendente, .debiti, "Mutuo casa", valore: 100_000) {
                $0.tipologia = "Mutuo a tasso variabile"; $0.tassoDebito = 4; $0.scadenza = giorno(2036, 11, 9)
            },
            posizione("carla-fondo", "carla", .indipendente, .investimento, "Fondo bilanciato prudente", valore: 20_000) {
                $0.tipologia = "Fondo comune bilanciato"; $0.quotaAzionaria = 40
            },
            posizione("carla-conto", "carla", .indipendente, .liquidita, "Conto corrente", valore: 3_000),
            posizione("dario-tcm", "dario", .alleanza, .protezione, "Temporanea caso morte", valore: 0) {
                $0.rischio = .vita; $0.capitaleAssicurato = 100_000
            },
        ]
        var casa = Obiettivo(clienteId: "carla", titolo: "Casa nuova", area: .casa, importo: 80_000, scadenza: giorno(2030, 11, 9))
        casa.id = "obiettivo-carla-casa"
        let incontro = Appuntamento(id: "carla-incontro", clienteId: "carla", titolo: "Riesame", inizio: giorno(2026, 11, 12, 10),
                                    durataMinuti: 60, luogo: "In studio", note: "", stato: .pianificato)
        var analisiAnna = Analisi360(cliente: nil, posizioni: [])
        analisiAnna.protezione.fabbisognoMensile = 2_000
        var analisiBruno = Analisi360(cliente: nil, posizioni: [])
        analisiBruno.protezione.fabbisognoMensile = 2_000
        return DatiMercatoClienti(oggi: oggi, clienti: [anna, bruno, carla, dario], posizioni: posizioni, obiettivi: [casa],
                                  appuntamenti: [incontro], analisi: ["anna": analisiAnna, "bruno": analisiBruno], calendario: cal)
    }

    private static func evento(_ frase: String) -> EventoMercatoVera? {
        if case .evento(let e) = MercatoClientiVera.riconosci(frase, oggi: oggi, cal: cal) { return e }
        return nil
    }

    private static func toccato(_ esito: EsitoMercatoVera, _ id: String) -> ClienteToccatoVera? {
        esito.toccati.first { $0.clienteId == id }
    }

    // MARK: - Pacchetto

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let t = IstruzioniVera.testo("mercato-clienti") ?? ""
        controlla(t.contains("JSON") && t.contains("bozze"), "Mercato per i clienti: istruzioni nel pacchetto (Vera/Istruzioni/mercato-clienti.md)")
        controlla(MercatoClientiVera.istruzioni.contains("JSON"), "Mercato per i clienti: le istruzioni (o il ripiego) chiedono il JSON")
    }

    // MARK: - Riconoscimento

    private static func riconoscimento(_ controlla: (Bool, String) -> Void) {
        let borse = evento("Le borse hanno perso l'8% in una settimana")
        controlla(borse?.tipo == .borse && borse?.misura == -8 && borse?.periodo == "in una settimana" && borse?.origine == .aParole,
                  "Mercato per i clienti: «le borse hanno perso l'8% in una settimana» → borse −8% in una settimana")
        controlla(borse?.titolo == "Le borse perdono l'8% in una settimana", "Mercato per i clienti: il titolo delle borse con l'articolo giusto: \(borse?.titolo ?? "")")
        let tagli = evento("La BCE taglia i tassi di 25 punti base")
        controlla(tagli?.tipo == .tassiBCE && tagli?.misura == -0.25, "Mercato per i clienti: «25 punti base» → tassi −0,25 punti")
        controlla(tagli?.titolo == "La BCE taglia i tassi di 0,25 punti", "Mercato per i clienti: titolo del taglio: \(tagli?.titolo ?? "")")
        controlla(evento("la Bce ha tagliato i tassi di 0,25 punti")?.misura == -0.25, "Mercato per i clienti: «0,25 punti» resta 0,25")
        controlla(evento("La BCE alza i tassi di mezzo punto")?.misura == 0.5, "Mercato per i clienti: «mezzo punto» in salita → +0,5")
        let inflazione = evento("L'inflazione sale al 3%")
        controlla(inflazione?.tipo == .inflazione && inflazione?.misura == 3 && inflazione?.verso == 1,
                  "Mercato per i clienti: «l'inflazione sale al 3%» → inflazione al 3%, in salita")
        controlla(inflazione?.titolo == "L'inflazione sale al 3%", "Mercato per i clienti: titolo dell'inflazione: \(inflazione?.titolo ?? "")")
        controlla(evento("l'inflazione è all'8 per cento")?.titolo == "L'inflazione è all'8%", "Mercato per i clienti: «all'8%» con l'apostrofo")
        controlla(evento("Piazza Affari crolla del −12%")?.misura == -12, "Mercato per i clienti: il segno scritto vale (−12%)")
        controlla(evento("Le borse guadagnano il 5% da inizio anno")?.misura == 5, "Mercato per i clienti: un rialzo delle borse (+5%)")
        if case .incompleto(let t, _) = MercatoClientiVera.riconosci("La BCE ha tagliato i tassi", oggi: oggi, cal: cal) {
            controlla(t == .tassiBCE, "Mercato per i clienti: senza la misura Vera chiede di quanti punti")
        } else {
            controlla(false, "Mercato per i clienti: senza la misura Vera chiede di quanti punti")
        }
        if case .incompleto = MercatoClientiVera.riconosci("I tassi BCE sono al 2%", oggi: oggi, cal: cal) {
            controlla(true, "Mercato per i clienti: «al 2%» è un livello, non una variazione: Vera chiede")
        } else {
            controlla(false, "Mercato per i clienti: «al 2%» è un livello, non una variazione: Vera chiede")
        }
        controlla(MercatoClientiVera.riconosci("Fissa un incontro con Marco giovedì alle 10", oggi: oggi, cal: cal) == .nessuno,
                  "Mercato per i clienti: un comando d'agenda non è un evento di mercato")
        controlla(MercatoClientiVera.riconosci("E se le borse perdessero il 20%?", oggi: oggi, cal: cal) == .nessuno,
                  "Mercato per i clienti: un «e se» resta agli scenari")
        // «Il tasso d'inflazione» è l'inflazione, non i tassi della BCE
        let tassoInflazione = evento("Il tasso di inflazione è salito al 3%")
        controlla(tassoInflazione?.tipo == .inflazione && tassoInflazione?.misura == 3 && tassoInflazione?.verso == 1,
                  "Mercato per i clienti: «il tasso di inflazione è salito al 3%» è l'inflazione al 3%, non i tassi BCE")
        // «dal 2,5% al 3%»: vale il livello nuovo, il vecchio è il precedente, il verso viene dal confronto
        let passa = evento("L'inflazione passa dal 2,5% al 3%")
        controlla(passa?.misura == 3 && passa?.precedente == 2.5 && passa?.verso == 1,
                  "Mercato per i clienti: «passa dal 2,5% al 3%» → al 3% (era 2,5%), in salita: \(String(describing: passa?.misura))")
        let scende = evento("l'inflazione scende dal 3% al 2,4%")
        controlla(scende?.misura == 2.4 && scende?.precedente == 3 && scende?.verso == -1, "Mercato per i clienti: «dal 3% al 2,4%» → al 2,4%, in discesa")
        // Lo smistamento: le domande normali con «azioni» o «tasso» non sono eventi
        controlla(!MercatoClientiVera.eUnEvento("Quali azioni mi suggerisci per Marco?"), "Mercato per i clienti: «quali azioni mi suggerisci» non è un evento")
        controlla(!MercatoClientiVera.eUnEvento("Che tasso ha il mutuo di Marco?"), "Mercato per i clienti: «che tasso ha il mutuo» non è un evento")
        // Il tasso di un cliente con un verbo forte («salito») resta una domanda, non un evento della BCE
        controlla(!MercatoClientiVera.eUnEvento("Il tasso del mutuo di Marco è salito?"),
                  "Mercato per i clienti: «il tasso del mutuo di Marco è salito?» non è un evento")
        controlla(MercatoClientiVera.eUnEvento("La BCE ha tagliato i tassi") && MercatoClientiVera.eUnEvento("Le borse hanno perso l'8% in una settimana"),
                  "Mercato per i clienti: un evento (anche senza misura, se nomina la BCE) resta un evento")
        // «su», «aumentare», «riduco» stanno anche nelle domande normali: non fanno un evento
        controlla(!MercatoClientiVera.eUnEvento("Che tasso c'è su questo mutuo?"), "Mercato per i clienti: «che tasso c'è su questo mutuo» non è un evento")
        controlla(!MercatoClientiVera.eUnEvento("Posso aumentare le azioni di Marco del 10%?")
                    && MercatoClientiVera.riconosci("Posso aumentare le azioni di Marco del 10%?", oggi: oggi, cal: cal) == .nessuno,
                  "Mercato per i clienti: «posso aumentare le azioni di Marco del 10%» non è un evento delle borse")
        controlla(!MercatoClientiVera.eUnEvento("Riduco le azioni di Bruno?"), "Mercato per i clienti: «riduco le azioni di Bruno» non è un evento")
        controlla(evento("Le azioni perdono il 5%")?.misura == -5, "Mercato per i clienti: «le azioni perdono il 5%» con il verso resta delle borse")
        // Privacy: l'evento non porta dati dei clienti
        let json = (try? JSONEncoder().encode(borse)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        controlla(!json.isEmpty && !json.contains("Anna") && !json.contains("@"), "Mercato per i clienti: l'evento si salva senza dati dei clienti")
    }

    // MARK: - Dalle serie e dagli avvisi di Mercato

    private static func serie(_ controlla: (Bool, String) -> Void) {
        var archivio = ArchivioMercato()
        archivio.serie = [
            SerieMercato(id: "bce-depositi", codice: "FM.D.U2.EUR.4F.KR.DFR.LEV", nome: "Tasso sui depositi BCE", origine: .bce, fonte: "BCE",
                         unita: .percentuale, tipo: .tassoUfficiale, frequenza: .giornaliera,
                         punti: [PuntoMercato(data: giorno(2026, 9, 10), valore: 2.25), PuntoMercato(data: giorno(2026, 11, 5), valore: 2.0)],
                         aggiornataIl: giorno(2026, 11, 5)),
            SerieMercato(id: "inflazione-it", codice: "prc_hicp_manr", nome: "Inflazione Italia", origine: .eurostat, fonte: "Eurostat",
                         unita: .percentuale, tipo: .inflazione, frequenza: .mensile,
                         punti: [PuntoMercato(data: giorno(2026, 9, 1), valore: 2.1), PuntoMercato(data: giorno(2026, 10, 1), valore: 2.6)],
                         aggiornataIl: giorno(2026, 11, 1)),
            SerieMercato(id: "stoxx", nome: "Euro Stoxx 50", origine: .csv, fonte: "Borsa", unita: .punti, tipo: .indiceAzionario,
                         frequenza: .giornaliera,
                         punti: [PuntoMercato(data: giorno(2026, 10, 29), valore: 5_000), PuntoMercato(data: giorno(2026, 11, 6), valore: 4_600)],
                         aggiornataIl: giorno(2026, 11, 6)),
            // Un tasso fermo non fa nascere eventi
            SerieMercato(id: "fermo", nome: "Tasso fermo", origine: .bce, fonte: "BCE", unita: .percentuale, tipo: .tassoUfficiale,
                         frequenza: .giornaliera,
                         punti: [PuntoMercato(data: giorno(2026, 11, 1), valore: 2.0), PuntoMercato(data: giorno(2026, 11, 6), valore: 2.0)],
                         aggiornataIl: giorno(2026, 11, 6)),
        ]
        let eventi = MercatoClientiVera.eventi(archivio: archivio, impostazioni: ImpostazioniMercato(), oggi: oggi, cal: cal)
        let tassi = eventi.first { $0.tipo == .tassiBCE }
        controlla(eventi.count == 3, "Mercato per i clienti: dalle serie tre eventi (tassi, inflazione, borse), nessuno dal tasso fermo: \(eventi.map(\.titolo))")
        controlla(tassi?.misura == -0.25 && tassi?.fonte == "Fonte: BCE" && tassi?.origine == .serie,
                  "Mercato per i clienti: il taglio della BCE dalla serie, con la fonte")
        let infl = eventi.first { $0.tipo == .inflazione }
        controlla(infl?.misura == 2.6 && infl?.precedente == 2.1 && infl?.verso == 1 && infl?.fonte == "Fonte: Eurostat",
                  "Mercato per i clienti: l'inflazione Eurostat al 2,6% (era 2,1%)")
        let borse = eventi.first { $0.tipo == .borse }
        controlla(borse?.misura == -8 && borse?.periodo == "in una settimana" && (borse?.fonte.contains("file importato") ?? false),
                  "Mercato per i clienti: l'indice importato da CSV −8% in una settimana: \(borse?.fonte ?? "")")
        // Due serie della stessa inflazione (BCE ed Eurostat): un evento solo, con id unici
        var doppia = archivio
        doppia.serie.append(SerieMercato(id: "inflazione-it-bce", codice: "ICP.M.IT.N.000000.4.ANR", nome: "Inflazione Italia (BCE)", origine: .bce,
                                         fonte: "BCE", unita: .percentuale, tipo: .inflazione, frequenza: .mensile,
                                         punti: [PuntoMercato(data: giorno(2026, 9, 1), valore: 2.1), PuntoMercato(data: giorno(2026, 10, 1), valore: 2.6)],
                                         aggiornataIl: giorno(2026, 11, 1)))
        let senzaDoppi = MercatoClientiVera.eventi(archivio: doppia, impostazioni: ImpostazioniMercato(), oggi: oggi, cal: cal)
        controlla(senzaDoppi.filter { $0.tipo == .inflazione }.count == 1 && Set(senzaDoppi.map(\.id)).count == senzaDoppi.count,
                  "Mercato per i clienti: due serie della stessa inflazione fanno un evento solo: \(senzaDoppi.map(\.id))")
        // Due inflazioni diverse nello stesso giorno (Italia ed euro, importata da CSV): due eventi, nessuna sparisce
        var dueAree = archivio
        dueAree.serie.append(SerieMercato(id: "inflazione-euro", nome: "Inflazione area euro", origine: .csv, fonte: "Eurostat",
                                          unita: .percentuale, tipo: .inflazione, frequenza: .mensile,
                                          punti: [PuntoMercato(data: giorno(2026, 9, 1), valore: 2.4), PuntoMercato(data: giorno(2026, 10, 1), valore: 2.2)],
                                          aggiornataIl: giorno(2026, 11, 1)))
        let aree = MercatoClientiVera.eventi(archivio: dueAree, impostazioni: ImpostazioniMercato(), oggi: oggi, cal: cal).filter { $0.tipo == .inflazione }
        controlla(aree.count == 2 && Set(aree.map(\.misura)) == [2.6, 2.2],
                  "Mercato per i clienti: inflazione Italia (2,6%) ed euro (2,2%) nello stesso giorno restano due eventi: \(aree.map(\.id))")
        // Dopo Pasqua 2026 (Venerdì Santo 3/4, Pasquetta 6/4): l'ultimo dato prima della settimana è di giovedì 2/4
        var pasqua = ArchivioMercato()
        pasqua.serie = [
            SerieMercato(id: "ftse-mib", nome: "FTSE MIB", origine: .csv, fonte: "Borsa", unita: .punti, tipo: .indiceAzionario,
                         frequenza: .giornaliera,
                         punti: [PuntoMercato(data: giorno(2026, 4, 1), valore: 40_000), PuntoMercato(data: giorno(2026, 4, 2), valore: 40_000),
                                 PuntoMercato(data: giorno(2026, 4, 13), valore: 36_800)],
                         aggiornataIl: giorno(2026, 4, 13)),
        ]
        let dopoPasqua = MercatoClientiVera.eventi(archivio: pasqua, impostazioni: ImpostazioniMercato(), oggi: giorno(2026, 4, 14), cal: cal)
        controlla(dopoPasqua.count == 1 && dopoPasqua.first?.misura == -8,
                  "Mercato per i clienti: dopo Pasqua il calo dell'8% del FTSE MIB in una settimana resta un evento: \(dopoPasqua.map(\.titolo))")
        // Una serie azionaria mensile: il punto di prima è di un mese fa, non c'è un «in una settimana»
        var mensile = ArchivioMercato()
        mensile.serie = [
            SerieMercato(id: "stoxx-mese", nome: "Euro Stoxx 50 (media mensile)", origine: .bce, fonte: "BCE", unita: .punti, tipo: .indiceAzionario,
                         frequenza: .mensile,
                         punti: [PuntoMercato(data: giorno(2026, 10, 1), valore: 5_000), PuntoMercato(data: giorno(2026, 11, 1), valore: 4_600)],
                         aggiornataIl: giorno(2026, 11, 1)),
        ]
        controlla(MercatoClientiVera.eventi(archivio: mensile, impostazioni: ImpostazioniMercato(), oggi: oggi, cal: cal).isEmpty,
                  "Mercato per i clienti: una serie mensile non fa nascere borse «in una settimana»")
        // Dati vecchi: nessun evento
        let tardi = MercatoClientiVera.eventi(archivio: archivio, impostazioni: ImpostazioniMercato(), oggi: giorno(2027, 6, 1), cal: cal)
        controlla(tardi.isEmpty, "Mercato per i clienti: i dati vecchi non fanno nascere eventi")
        // Dall'avviso di Mercato
        let avviso = AvvisoMercato(id: "variazioneSerie-bruno-bce-depositi-20261105", tipo: .variazioneSerie, clienteId: "bruno",
                                   serieId: "bce-depositi", titolo: "Tasso BCE −0,25 punti", dettaglio: "", valore: -0.25, soglia: 0.1,
                                   dataDato: giorno(2026, 11, 5), fonte: "Fonte: BCE", creatoIl: giorno(2026, 11, 5))
        let daAvviso = MercatoClientiVera.evento(da: avviso, archivio: archivio, cal: cal)
        controlla(daAvviso?.tipo == .tassiBCE && daAvviso?.misura == -0.25 && daAvviso?.origine == .avviso,
                  "Mercato per i clienti: l'avviso di variazione della BCE diventa l'evento dei tassi")
        var cedola = avviso
        cedola.tipo = .cedolaInArrivo
        controlla(MercatoClientiVera.evento(da: cedola, archivio: archivio, cal: cal) == nil, "Mercato per i clienti: un avviso di cedola non è un evento per tutti")
    }

    // MARK: - Borse

    private static func borse(_ controlla: (Bool, String) -> Void) {
        guard let e = evento("Le borse hanno perso l'8% in una settimana") else { return controlla(false, "Mercato per i clienti: evento borse") }
        let esito = MercatoClientiVera.toccati(e, dati: dati())
        controlla(esito.toccati.map(\.clienteId) == ["carla", "bruno", "anna"],
                  "Mercato per i clienti: borse −8% tocca Carla, Bruno e Anna, dal più urgente: \(esito.toccati.map(\.clienteId))")
        controlla(esito.intestazione == "Tocca 3 dei tuoi clienti" && esito.etichettaBozze == "Prepara 3 messaggi", "Mercato per i clienti: intestazione e pulsante")
        controlla(toccato(esito, "dario") == nil, "Mercato per i clienti: chi ha solo una polizza di protezione non è toccato dalle borse")
        let carla = toccato(esito, "carla")
        controlla(carla?.azione == .chiamaOggi && carla?.etichettaAzione == "Chiama Carla oggi" && (carla?.motivo.contains("prudente") ?? false),
                  "Mercato per i clienti: Carla è prudente → «Chiama Carla oggi» (anche con l'incontro giovedì)")
        controlla((carla?.motivo.contains("40%") ?? false) && (carla?.motivo.contains("640") ?? false),
                  "Mercato per i clienti: Carla, 40% in azioni e circa 640 € di calo, calcolati da Prisma: \(carla?.motivo ?? "")")
        let bruno = toccato(esito, "bruno")
        controlla(bruno?.azione == .rassicura && (bruno?.motivo.contains("33%") ?? false) && (bruno?.motivo.contains("2.880") ?? false),
                  "Mercato per i clienti: Bruno, 33% in azioni (36.000 €), calo di 2.880 € → «Rassicura»: \(bruno?.motivo ?? "")")
        let anna = toccato(esito, "anna")
        controlla(anna?.azione == .dueRighe && (anna?.motivo.contains("35 anni davanti") ?? false) && (anna?.motivo.contains("3.200") ?? false),
                  "Mercato per i clienti: Anna ha 35 anni alla pensione → «Manda due righe»: \(anna?.motivo ?? "")")
        controlla(anna?.canale == .indipendente && bruno?.motivi.first?.canale == .indipendente, "Mercato per i clienti: il canale delle posizioni toccate resta riconoscibile")
        // Un rialzo: solo chi ha almeno metà in azioni, per il ribilanciamento
        if let su = evento("Le borse guadagnano il 6%") {
            let r = MercatoClientiVera.toccati(su, dati: dati())
            controlla(r.toccati.map(\.clienteId) == ["anna"] && r.toccati.first?.azione == .ribilancia,
                      "Mercato per i clienti: borse +6% → solo Anna (100% in azioni), da ribilanciare")
        }
        let chat = MercatoClientiVera.testoChat(esito)
        controlla(chat.contains("Le borse perdono l'8%") && chat.contains("Chiama Carla oggi") && chat.contains("le mandi tu"),
                  "Mercato per i clienti: la risposta in chat con evento, clienti, azioni e «le mandi tu»")
    }

    // MARK: - Tassi

    private static func tassi(_ controlla: (Bool, String) -> Void) {
        guard let e = evento("La BCE taglia i tassi di 25 punti base") else { return controlla(false, "Mercato per i clienti: evento tassi") }
        let esito = MercatoClientiVera.toccati(e, dati: dati())
        controlla(esito.toccati.map(\.clienteId) == ["bruno", "carla"],
                  "Mercato per i clienti: il taglio tocca Bruno e Carla, non Anna (4,5 mesi di spese): \(esito.toccati.map(\.clienteId))")
        let bruno = toccato(esito, "bruno")
        let regole = bruno?.motivi.map(\.regola) ?? []
        controlla(regole == [.rivalutabileInScadenza, .liquiditaFerma, .mutuoVariabile],
                  "Mercato per i clienti: Bruno, prima la rivalutabile in scadenza, poi la liquidità ferma e il mutuo: \(regole)")
        controlla(bruno?.azione == .decidiScadenza && (bruno?.motivo.contains("marzo 2027") ?? false) && (bruno?.motivo.contains("50.000") ?? false),
                  "Mercato per i clienti: la rivalutabile da 50.000 € scade a marzo 2027 → «Decidete prima della scadenza»: \(bruno?.motivo ?? "")")
        let liquidita = bruno?.motivi.first { $0.regola == .liquiditaFerma }
        controlla((liquidita?.testo.contains("15 mesi") ?? false) && (liquidita?.testo.contains("75") ?? false) && liquidita?.azione == .preparaIpotesi,
                  "Mercato per i clienti: 15 mesi di spese ferme, circa 75 € di interessi in meno all'anno: \(liquidita?.testo ?? "")")
        let mutuo = bruno?.motivi.first { $0.regola == .mutuoVariabile }
        // 100.000 € al 4% per 120 mesi: rata di circa 1.012 €; al 3,75% circa 1.001 €
        let euro12 = TestiMercatoClienti.euro(12)
        controlla(mutuo?.cifre.first { $0.etichetta == "Rata più bassa di circa" }?.valore == euro12
                    && (mutuo?.testo.contains("scendere di circa \(euro12) al mese") ?? false) && mutuo?.azione == .dueRighe,
                  "Mercato per i clienti: la rata del mutuo variabile scende di circa 12 € al mese: \(mutuo?.testo ?? "")")
        let carla = toccato(esito, "carla")
        controlla(carla?.motivi.first?.regola == .obiettivoCasa && carla?.azione == .parlaneIncontro
                    && carla?.etichettaAzione == "Parlane giovedì 12 novembre",
                  "Mercato per i clienti: Carla, obiettivo casa e incontro giovedì → «Parlane giovedì 12 novembre»: \(carla?.etichettaAzione ?? "")")
        // La firma segue il motivo principale: Bruno ha canali misti, ma il messaggio parla della rivalutabile Alleanza
        if let b = bruno, let cb = dati().clienti.first(where: { $0.id == "bruno" }) {
            let bozza = MercatoClientiVera.bozzaFissa(b, evento: e, cliente: cb, stile: stile(), oggi: oggi, cal: cal)
            controlla(b.canale == nil && b.canaleFirma == .alleanza && bozza.hasSuffix("\n\nDenis Vicenzoni · Alleanza"),
                      "Mercato per i clienti: la bozza sulla rivalutabile Alleanza di Bruno (canali misti) ha la firma Alleanza: \(bozza)")
            let json = #"{"bozze":[{"cliente":"bruno","testo":"Buongiorno Bruno, la Sua polizza rivalutabile scade a marzo 2027: decidiamo insieme prima della scadenza?\n\nDenis"}]}"#
            let lette = MercatoClientiVera.leggi(json, esito: esito, clienti: dati().clienti, stile: stile(), oggi: oggi, cal: cal)
            if case .success(let testo)? = lette?["bruno"] {
                controlla(testo.hasSuffix("\n\nDenis Vicenzoni · Alleanza") && !testo.contains("?\n\nDenis\n"),
                          "Mercato per i clienti: la bozza di Qwen per Bruno perde la firma sbagliata e prende quella Alleanza: \(testo)")
            }
        }
        controlla(MercatoClientiVera.coda(stile(), canale: nil).isEmpty,
                  "Mercato per i clienti: con canali misti e senza un motivo di canale niente firma scelta a caso")
        // In salita: mutuo da rivedere, conto deposito, obbligazioni
        if let su = evento("La BCE alza i tassi di mezzo punto") {
            let r = MercatoClientiVera.toccati(su, dati: dati())
            let b = toccato(r, "bruno")
            let rb = Set(b?.motivi.map(\.regola) ?? [])
            controlla(rb == [.mutuoVariabile, .rivalutabileInScadenza, .contoDeposito, .obbligazioni] && b?.azione == .decidiScadenza,
                      "Mercato per i clienti: tassi in salita, per Bruno mutuo, rinnovo, conto deposito e obbligazioni: \(rb)")
            controlla(b?.motivi.first { $0.regola == .mutuoVariabile }?.testo.contains("salire") ?? false, "Mercato per i clienti: con i tassi su la rata sale")
        }
    }

    // MARK: - Inflazione

    private static func inflazione(_ controlla: (Bool, String) -> Void) {
        guard let e = evento("L'inflazione sale al 3%") else { return controlla(false, "Mercato per i clienti: evento inflazione") }
        let esito = MercatoClientiVera.toccati(e, dati: dati())
        controlla(Set(esito.toccati.map(\.clienteId)) == ["anna", "bruno", "carla"], "Mercato per i clienti: l'inflazione al 3% tocca Anna, Bruno e Carla")
        let anna = toccato(esito, "anna")
        controlla((anna?.motivo.contains("9.000") ?? false) && (anna?.motivo.contains("270") ?? false) && anna?.azione == .fissaRiesame,
                  "Mercato per i clienti: Anna, 9.000 € fermi perdono circa 270 € in un anno: \(anna?.motivo ?? "")")
        let bruno = toccato(esito, "bruno")
        let sotto = bruno?.motivi.first { $0.regola == .rivalutabileSottoInflazione }
        controlla((sotto?.testo.contains("2,5%") ?? false), "Mercato per i clienti: la rivalutabile al 2,5% lordo rende meno del 3%: \(sotto?.testo ?? "")")
        let carla = toccato(esito, "carla")
        let casa = carla?.motivi.first { $0.regola == .obiettivoInflazione }
        // 80.000 € × 1,03^4 = 90.041 €, arrotondato al centinaio
        controlla((casa?.testo.contains("90.000") ?? false) && (casa?.testo.contains("4 anni") ?? false),
                  "Mercato per i clienti: l'obiettivo casa di Carla fra 4 anni costerebbe circa 90.000 €: \(casa?.testo ?? "")")
        controlla(carla?.speseStimate == true && anna?.speseStimate == false, "Mercato per i clienti: senza analisi salvata le spese sono segnate come stimate")
    }

    // MARK: - Bozze fisse

    private static func stile() -> StileBozzeVera {
        var s = StileBozzeVera()
        s.firmaIndipendente = "Denis"
        s.firmaAlleanza = "Denis Vicenzoni · Alleanza"
        s.toni["bruno"] = .formale
        return s
    }

    private static func bozzeFisse(_ controlla: (Bool, String) -> Void) {
        guard let e = evento("Le borse hanno perso l'8% in una settimana") else { return }
        let d = dati()
        let esito = MercatoClientiVera.toccati(e, dati: d)
        let s = stile()
        let perId = Dictionary(uniqueKeysWithValues: d.clienti.map { ($0.id, $0) })
        guard let anna = toccato(esito, "anna"), let bruno = toccato(esito, "bruno"), let ca = perId["anna"], let cb = perId["bruno"] else {
            return controlla(false, "Mercato per i clienti: bozze fisse")
        }
        let ba = MercatoClientiVera.bozzaFissa(anna, evento: e, cliente: ca, stile: s, oggi: oggi, cal: cal)
        controlla(ba.hasPrefix("Ciao Anna,") && ba.contains("le borse hanno perso l'8% in una settimana") && ba.hasSuffix("\n\nDenis"),
                  "Mercato per i clienti: la bozza fissa di Anna dà del tu e ha la firma dell'indipendente: \(ba)")
        let bb = MercatoClientiVera.bozzaFissa(bruno, evento: e, cliente: cb, stile: s, oggi: oggi, cal: cal)
        controlla(bb.hasPrefix("Buongiorno Bruno,") && bb.contains("Suoi") && DateItaliane.cerca(#"\b(?:ti|tuo|tuoi)\b"#, bb.lowercased()) == nil,
                  "Mercato per i clienti: la bozza fissa di Bruno dà del Lei: \(bb)")
        let nessuna = MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: s, json: nil, oggi: oggi, cal: cal)
        controlla(nessuna.count == 3 && nessuna.allSatisfy { $0.autore == .modelloFisso && ($0.avviso?.contains("Vera non è pronta") ?? false) },
                  "Mercato per i clienti: senza Qwen restano le bozze di Prisma, con l'avviso")
        controlla(nessuna.first { $0.clienteId == "bruno" }?.canale == .mail && nessuna.first { $0.clienteId == "anna" }?.canale == .messaggi,
                  "Mercato per i clienti: Messaggi con il cellulare, Mail senza")
    }

    // MARK: - Qwen controllato

    private static func qwen(_ controlla: (Bool, String) -> Void) {
        guard let e = evento("Le borse hanno perso l'8% in una settimana") else { return }
        let d = dati()
        let esito = MercatoClientiVera.toccati(e, dati: d)
        let s = stile()
        // Le richieste a Qwen: nomi sì (solo il primo), recapiti no
        let richiesta = MercatoClientiVera.messaggi(esito, toccati: esito.toccati, clienti: d.clienti, stile: s, oggi: oggi, cal: cal)
        let testo = richiesta.map(\.testo).joined(separator: "\n")
        controlla(testo.contains("id=anna") && testo.contains("dai del Lei") && !testo.contains("@") && !testo.contains("1234567") && !testo.contains("Verdi"),
                  "Mercato per i clienti: a Qwen vanno id, primo nome, tono e fatti, mai recapiti o cognomi")
        controlla(MercatoClientiVera.opzioni(ImpostazioniVera()).formato != nil, "Mercato per i clienti: Qwen risponde con lo schema JSON")
        let json = #"""
        {"bozze":[
          {"cliente":"anna","testo":"Ciao Anna, le borse hanno perso l'8% in una settimana. Il tuo piano guarda lontano: per ora nessuna mossa. Ne parliamo quando vuoi?"},
          {"cliente":"bruno","testo":"Ciao Bruno, ti chiamo per guardare i numeri insieme."},
          {"cliente":"carla","testo":"Ciao Carla, le borse hanno perso l'8%: hai perso circa 5.000 €. Ti chiamo oggi."},
          {"cliente":"sconosciuto","testo":"Ciao!"}
        ]}
        """#
        let bozze = MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: s, json: json, modello: "qwen3.5:4b", oggi: oggi, cal: cal)
        let anna = bozze.first { $0.clienteId == "anna" }
        controlla(anna?.autore == .vera && anna?.modello == "qwen3.5:4b" && (anna?.testo.hasSuffix("\n\nDenis") ?? false),
                  "Mercato per i clienti: la bozza di Qwen per Anna passa, con la firma di Prisma")
        let bruno = bozze.first { $0.clienteId == "bruno" }
        controlla(bruno?.autore == .modelloFisso && (bruno?.avviso?.contains("tu") ?? false), "Mercato per i clienti: a Bruno (Lei) una bozza col tu si scarta: \(bruno?.avviso ?? "")")
        let carla = bozze.first { $0.clienteId == "carla" }
        controlla(carla?.autore == .modelloFisso && (carla?.avviso?.contains("cifra") ?? false), "Mercato per i clienti: una cifra inventata (5.000 €) si scarta")
        controlla(bozze.count == 3, "Mercato per i clienti: una bozza per cliente toccato, niente per gli sconosciuti")
        let promessa = #"{"bozze":[{"cliente":"anna","testo":"Ciao Anna, niente paura: con il tuo ETF hai un rendimento garantito."}]}"#
        controlla(MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: s, json: promessa, oggi: oggi, cal: cal).first { $0.clienteId == "anna" }?.autore == .modelloFisso,
                  "Mercato per i clienti: una promessa di rendimento si scarta")
        let altro = #"{"bozze":[{"cliente":"anna","testo":"Ciao Anna, anche Carla mi ha chiesto delle borse: ne parliamo?"}]}"#
        controlla(MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: s, json: altro, oggi: oggi, cal: cal).first { $0.clienteId == "anna" }?.autore == .modelloFisso,
                  "Mercato per i clienti: una bozza che nomina un altro cliente si scarta")
        // Un numero in parole che i fatti non dicono si scarta come una cifra inventata
        let inParole = #"{"bozze":[{"cliente":"anna","testo":"Ciao Anna, le borse hanno perso l'8% in una settimana: un terzo del tuo piano è da rivedere. Ne parliamo?"}]}"#
        let bozzaParole = MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: s, json: inParole, oggi: oggi, cal: cal).first { $0.clienteId == "anna" }
        controlla(bozzaParole?.autore == .modelloFisso && (bozzaParole?.avviso?.contains("cifra") ?? false),
                  "Mercato per i clienti: «un terzo» che Prisma non ha calcolato si scarta: \(bozzaParole?.avviso ?? "")")
        // Il Lei a chi riceve il tu si scarta (Anna riceve il tu)
        let leiAdAnna = #"{"bozze":[{"cliente":"anna","testo":"Ciao Anna, La chiamo oggi per guardare i Suoi numeri."}]}"#
        let bozzaLei = MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: s, json: leiAdAnna, oggi: oggi, cal: cal).first { $0.clienteId == "anna" }
        controlla(bozzaLei?.autore == .modelloFisso && (bozzaLei?.avviso?.contains("Lei") ?? false),
                  "Mercato per i clienti: ad Anna (tu) una bozza col Lei si scarta: \(bozzaLei?.avviso ?? "")")
        // Il tu senza «ti» o «tuo» («ciao», «vuoi») a chi riceve il Lei si scarta (Bruno riceve il Lei)
        let tuABruno = #"{"bozze":[{"cliente":"bruno","testo":"Ciao Bruno, hai visto le borse? Se vuoi ne parliamo giovedì."}]}"#
        let bozzaTu = MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: s, json: tuABruno, oggi: oggi, cal: cal).first { $0.clienteId == "bruno" }
        controlla(bozzaTu?.autore == .modelloFisso && (bozzaTu?.avviso?.contains("del tu") ?? false),
                  "Mercato per i clienti: a Bruno (Lei) «Ciao Bruno, se vuoi ne parliamo» si scarta: \(bozzaTu?.avviso ?? "")")
        // Le parole che somigliano a numeri non lo sono («ventaglio», «meta», «per mezzo di», «Trentino», «quarantena»)
        let fattiParole = "Le borse hanno perso l'8% in una settimana."
        controlla(MercatoClientiVera.numeriInParoleConservati(fatti: fattiParole,
                      testo: "Valutiamo un ventaglio di soluzioni per la tua meta, per mezzo di un piano per l'anno venturo: dal Trentino, niente quarantena."),
                  "Mercato per i clienti: «ventaglio», «meta», «per mezzo di», «venturo», «Trentino», «quarantena» non sono numeri")
        controlla(!MercatoClientiVera.numeriInParoleConservati(fatti: fattiParole, testo: "Hai ventidue fondi, metà della quota e mezzo punto in più."),
                  "Mercato per i clienti: «ventidue», «metà della» e «mezzo punto» restano numeri da controllare")
        controlla(!MercatoClientiVera.numeriInParoleConservati(fatti: fattiParole, testo: "La metà della quota."),
                  "Mercato per i clienti: «metà della» resta un numero da controllare")
        let rotta = MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: s, json: "non è JSON", oggi: oggi, cal: cal)
        controlla(rotta.allSatisfy { $0.autore == .modelloFisso && $0.avviso != nil }, "Mercato per i clienti: un JSON illeggibile lascia le bozze di Prisma")
    }

    // MARK: - La scheda «Conferma»

    private static func conferma(_ controlla: (Bool, String) -> Void) {
        guard let e = evento("Le borse hanno perso l'8% in una settimana") else { return }
        let d = dati()
        let esito = MercatoClientiVera.toccati(e, dati: d)
        let bozze = MercatoClientiVera.bozze(esito, clienti: d.clienti, stile: stile(), json: nil, oggi: oggi, cal: cal)
        let azioni = MercatoClientiVera.azioni(esito, bozze: bozze, clienti: d.clienti, oggi: oggi, cal: cal)
        let messaggi = azioni.filter { $0.strumento == RegistroStrumenti.messaggiPrepara }
        let attivita = azioni.filter { $0.strumento == RegistroStrumenti.attivitaNuova }
        controlla(messaggi.count == 3 && attivita.count == 2, "Mercato per i clienti: tre bozze e due attività (Anna ha solo le due righe)")
        controlla(azioni.allSatisfy { RegistroStrumenti.strumento($0.strumento) != nil && $0.esito == nil },
                  "Mercato per i clienti: le azioni usano gli strumenti del registro e non sono eseguite")
        let chiamata = attivita.first { $0.argomenti["cliente"] == "carla" }
        controlla(chiamata?.argomenti["scadenza"] == RegistroStrumenti.isoData(cal.startOfDay(for: oggi)) && (chiamata?.argomenti["titolo"]?.hasPrefix("Chiama Carla oggi") ?? false),
                  "Mercato per i clienti: «Chiama Carla oggi» è un'attività per oggi")
        controlla(messaggi.allSatisfy { ($0.argomenti["testo"]?.isEmpty == false) && $0.argomenti["scopo"] == "altro" },
                  "Mercato per i clienti: ogni messaggio porta il testo della bozza")
        let scheda = MercatoClientiVera.scheda(esito, bozze: bozze, clienti: d.clienti, richiesta: "Le borse hanno perso l'8%", oggi: oggi, cal: cal)
        controlla(scheda.stato == .daConfermare && scheda.attive.count == 5, "Mercato per i clienti: tutto passa dalla scheda «Conferma»")
    }

    // MARK: - I clienti del template

    private static func template(_ controlla: (Bool, String) -> Void) {
        let demo = DatiPrisma.demo()
        let adesso = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
        let d = DatiMercatoClienti(dati: demo, oggi: adesso)
        if case .evento(let tagli) = MercatoClientiVera.riconosci("La BCE taglia i tassi di 0,25 punti", oggi: adesso) {
            let esito = MercatoClientiVera.toccati(tagli, dati: d)
            let sofia = esito.toccati.first { $0.clienteId == "sofia" }
            controlla(sofia?.motivi.contains { $0.regola == .rivalutabileInScadenza && $0.canale == .alleanza } ?? false,
                      "Mercato per i clienti (template): Sofia, la rivalutabile Alleanza in scadenza")
            let marco = esito.toccati.first { $0.clienteId == "marco" }
            controlla(marco?.motivi.contains { $0.regola == .mutuoVariabile } ?? false, "Mercato per i clienti (template): Marco, il mutuo variabile")
            let giulia = esito.toccati.first { $0.clienteId == "giulia" }
            controlla(giulia?.motivi.contains { $0.regola == .obiettivoCasa } ?? false, "Mercato per i clienti (template): Giulia, l'obiettivo casa")
        } else {
            controlla(false, "Mercato per i clienti (template): evento dei tassi")
        }
        if case .evento(let calo) = MercatoClientiVera.riconosci("Le borse hanno perso l'8% in una settimana", oggi: adesso) {
            let esito = MercatoClientiVera.toccati(calo, dati: d)
            controlla(esito.toccati.contains { $0.clienteId == "giulia" } && !esito.toccati.contains { $0.clienteId == "andrea" },
                      "Mercato per i clienti (template): le borse toccano Giulia (ETF azionario), non Andrea (solo liquidità)")
        }
    }
}
