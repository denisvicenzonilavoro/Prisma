import Foundation

/// Prove di Mercato, «Prisma conosce il mercato» (giro 7, chiamate da `ProvaCalcoli.esegui()`, cioè da
/// `Prisma --prova-calcoli`). Nessuna prova esce su internet: le risposte sono quelle di esempio di
/// Risorse/Mercato/Esempi (SDMX-CSV della BCE e JSON-stat di Eurostat scritti secondo la documentazione, valori
/// dimostrativi) e lo scaricamento completo passa da un protocollo di prova (`ProtocolloProvaMercato`).
/// Casi: lettori delle risposte, CSV con errori, ISIN, avvisi con le soglie (nessuna soglia = nessun avviso), «Chi è
/// toccato», valori per l'aggiornamento delle posizioni, occasioni per Messaggi e, soprattutto, nessun dato dei
/// clienti nelle richieste. Oggi fisso al 4 novembre 2026, a mezzogiorno. Nomi, ISIN («ZZ…») e importi sono DI PROVA.
enum ProvaCalcoliMercato {
    private static let cal = Calendar.current
    private static let oggi = AiutiProva.data(2026, 11, 4)
    private static let isinA = "ZZ0000000016"
    private static let isinB = "ZZ0000000024"

    private static func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }

    static func esegui(_ verifica: VerificaCalcoli) {
        lettori(verifica)
        csv(verifica)
        isin(verifica)
        toccatiEAvvisi(verifica)
        valoriPerAggiornamento(verifica)
        occasioni(verifica)
        richieste(verifica)
        scaricamentoDiProva(verifica)
        serieEArchivio(verifica)
    }

    // MARK: - Esempi

    private static func esempio(_ nome: String) -> Data? {
        guard let url = Risorse.cartella?.appendingPathComponent("Mercato/Esempi/\(nome)") else { return nil }
        return try? Data(contentsOf: url)
    }

    // MARK: - 1. Lettori delle risposte

    private static func lettori(_ verifica: VerificaCalcoli) {
        // BCE, SDMX-CSV: tasso sui depositi (giornaliero, una riga per variazione)
        let depositi = esempio("bce-depositi.csv").flatMap { String(data: $0, encoding: .utf8) } ?? ""
        verifica.vero("Mercato: risposta di esempio della BCE nel pacchetto", !depositi.isEmpty)
        let l = try? LettoreMercato.sdmxCSV(depositi, chiave: "FM.D.U2.EUR.4F.KR.DFR.LEV")
        verifica("Mercato: SDMX-CSV, 8 osservazioni del tasso sui depositi", Double(l?.punti.count ?? 0), 8)
        verifica("Mercato: SDMX-CSV, primo valore 3,75", l?.punti.first?.valore ?? 0, 3.75)
        verifica.vero("Mercato: SDMX-CSV, prima data 12 giugno 2024", l?.punti.first?.data == d(2024, 6, 12))
        verifica("Mercato: SDMX-CSV, ultimo valore 2", l?.punti.last?.valore ?? 0, 2)
        verifica.vero("Mercato: SDMX-CSV, chiave della serie riconosciuta", l?.chiavi == ["FM.D.U2.EUR.4F.KR.DFR.LEV"])
        // Rendimento mensile: l'ultima osservazione senza valore si salta
        let it = esempio("bce-rendimento-it.csv").flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let r = try? LettoreMercato.sdmxCSV(it, chiave: "IRS.M.IT.L.L40.CI.0000.EUR.N.Z")
        verifica("Mercato: SDMX-CSV mensile, 6 valori", Double(r?.punti.count ?? 0), 6)
        verifica("Mercato: SDMX-CSV mensile, osservazione vuota saltata", Double(r?.scartati ?? 0), 1)
        verifica.vero("Mercato: SDMX-CSV mensile, «2026-09» è il 1° settembre", r?.punti.last?.data == d(2026, 9, 1) && r?.punti.last?.valore == 3.42)
        // Un'altra chiave nello stesso file: nessun valore; la risposta «No results found»: serie non trovata
        verifica.vero("Mercato: SDMX-CSV, chiave diversa non letta",
                      (try? LettoreMercato.sdmxCSV(it, chiave: "IRS.M.DE.L.L40.CI.0000.EUR.N.Z")) == nil)
        do {
            _ = try LettoreMercato.sdmxCSV("No results found.", chiave: "FM.D.X")
            verifica.vero("Mercato: SDMX-CSV, «No results found» è un errore", false)
        } catch let e as ErroreMercato {
            verifica.vero("Mercato: SDMX-CSV, «No results found» = serie non trovata", e == .serieNonTrovata("FM.D.X"))
        } catch {
            verifica.vero("Mercato: SDMX-CSV, errore inatteso", false)
        }
        // Eurostat, JSON-stat 2.0 con i valori in un oggetto
        let j = esempio("eurostat-inflazione.json").flatMap { try? LettoreMercato.jsonStat($0) }
        verifica("Mercato: JSON-stat, 4 mesi di inflazione", Double(j?.punti.count ?? 0), 4)
        verifica.vero("Mercato: JSON-stat, settembre 2026 = 1,3", j?.punti.last?.data == d(2026, 9, 1) && j?.punti.last?.valore == 1.3)
        verifica.vero("Mercato: JSON-stat, codice del dataset", j?.chiavi == ["prc_hicp_manr"])
        // JSON-stat con i valori in un elenco, un valore nullo, due paesi (vale il primo) e i periodi «2026M07»
        let elenco = """
        {"version":"2.0","class":"dataset","id":["geo","time"],"size":[2,3],
         "dimension":{"geo":{"category":{"index":{"IT":0,"DE":1}}},
                      "time":{"category":{"index":["2026M07","2026M08","2026M09"]}}},
         "value":[1.6,null,1.3,2.0,2.1,2.2]}
        """
        let e2 = try? LettoreMercato.jsonStat(Data(elenco.utf8))
        verifica("Mercato: JSON-stat in elenco, 2 valori del primo paese", Double(e2?.punti.count ?? 0), 2)
        verifica("Mercato: JSON-stat in elenco, valore nullo saltato", Double(e2?.scartati ?? 0), 1)
        verifica("Mercato: JSON-stat in elenco, ultimo 1,3 (non quello del secondo paese)", e2?.punti.last?.valore ?? 0, 1.3)
        // Una risposta di errore di Eurostat
        let errore = #"{"error":{"status":"400","label":"Invalid dimension coicop"}}"#
        do {
            _ = try LettoreMercato.jsonStat(Data(errore.utf8))
            verifica.vero("Mercato: JSON-stat, risposta di errore riconosciuta", false)
        } catch let e as ErroreMercato {
            verifica.vero("Mercato: JSON-stat, risposta di errore riconosciuta", e == .rispostaDiErrore("Invalid dimension coicop"))
        } catch {
            verifica.vero("Mercato: JSON-stat, errore inatteso", false)
        }
        // Periodi
        verifica.vero("Mercato: periodo «2026-Q3» = 1° luglio", LettoreMercato.periodo("2026-Q3") == d(2026, 7, 1))
        verifica.vero("Mercato: periodo «2026» = 1° gennaio", LettoreMercato.periodo("2026") == d(2026, 1, 1))
        verifica.vero("Mercato: periodo «2026-02-30» non valido", LettoreMercato.periodo("2026-02-30") == nil)
    }

    // MARK: - 2. CSV del consulente

    private static func csv(_ verifica: VerificaCalcoli) {
        // Una serie con il punto e virgola: intestazione, decimale con la virgola, quattro righe sbagliate
        let serie = "data;valore\n2026-09-30;1.234,5\n30/10/2026;18,42\n31/10/2026;abc\n2026-11-30;5\n30/10/2026;19\n\n"
        let s = LettoreMercato.importaCSV(serie, oggi: oggi)
        verifica.vero("Mercato CSV: forma «data;valore»", s.forma == .serie)
        verifica("Mercato CSV: righe lette", Double(s.righe), 5)
        verifica("Mercato CSV: un valore buono", Double(s.punti.count), 1)
        verifica("Mercato CSV: 18,42 con la virgola", s.punti.first?.valore ?? 0, 18.42)
        verifica.vero("Mercato CSV: errori alle righe 2, 4, 5, 6", s.errori.map(\.riga) == [2, 4, 5, 6])
        verifica.vero("Mercato CSV: migliaia rifiutate", s.errori.first?.motivo == TestiMercato.erroreValore)
        verifica.vero("Mercato CSV: data futura rifiutata", s.errori.contains { $0.riga == 5 && $0.motivo == TestiMercato.erroreDataFutura })
        verifica.vero("Mercato CSV: data ripetuta rifiutata", s.errori.contains { $0.riga == 6 && $0.motivo == TestiMercato.erroreRipetuta })
        // Quote per ISIN con la virgola come separatore (decimale col punto)
        let quote = "Data,ISIN,Quota\n2026-10-30,IE00B4L5Y983,18.42\n2026-10-31,ie00 b4l5 y983,18.50\n2026-10-31,LU0000000000,10\n"
            + "2026-10-31,IE00B4L5Y983,18.6\n2026-10-29,IE00B4L5Y983,18,4\n2026-10-28,IE00B4L5Y983,-1\n"
        let q = LettoreMercato.importaCSV(quote, oggi: oggi)
        verifica.vero("Mercato CSV: forma «data;isin;valore»", q.forma == .quote)
        verifica("Mercato CSV: due quote dell'ISIN normalizzato", Double(q.quote["IE00B4L5Y983"]?.count ?? 0), 2)
        verifica("Mercato CSV: quota 18,50 del 31 ottobre", q.quote["IE00B4L5Y983"]?.last?.valore ?? 0, 18.5)
        verifica.vero("Mercato CSV: ISIN sbagliato rifiutato", q.errori.contains { $0.riga == 4 && $0.motivo == TestiMercato.erroreISIN })
        verifica.vero("Mercato CSV: decimale con la virgola e separatore virgola rifiutato",
                      q.errori.contains { $0.riga == 6 && $0.motivo == TestiMercato.erroreTroppeColonne })
        verifica.vero("Mercato CSV: quota negativa rifiutata", q.errori.contains { $0.riga == 7 && $0.motivo == TestiMercato.erroreQuotaNonPositiva })
        verifica("Mercato CSV: quattro errori nelle quote", Double(q.errori.count), 4)
        // Senza intestazione, tre colonne: quote
        let senza = LettoreMercato.importaCSV("2026-10-30;\(isinA);18,42\r\n2026-10-31;\(isinA);18.5", oggi: oggi)
        verifica.vero("Mercato CSV: senza intestazione, quote", senza.forma == .quote && senza.quote[isinA]?.count == 2 && senza.errori.isEmpty)
        verifica.vero("Mercato CSV: file vuoto", LettoreMercato.importaCSV("", oggi: oggi).righe == 0)
        // Inserimento a mano
        verifica("Mercato a mano: «−0,25»", LettoreMercato.valoreAMano("−0,25") ?? 0, -0.25)
        verifica("Mercato a mano: «3,42%»", LettoreMercato.valoreAMano("3,42%") ?? 0, 3.42)
        verifica.vero("Mercato a mano: «1.234,5» rifiutato", LettoreMercato.valoreAMano("1.234,5") == nil)
        verifica.vero("Mercato a mano: data «30.10.2026»", LettoreMercato.dataAMano("30.10.2026") == d(2026, 10, 30))
    }

    // MARK: - 3. ISIN

    private static func isin(_ verifica: VerificaCalcoli) {
        for codice in ["IE00B4L5Y983", "IT0005439275", "US0378331005", isinA, isinB] {
            verifica.vero("Mercato ISIN: \(codice) valido", MotoreMercato.isinValido(codice))
        }
        verifica.vero("Mercato ISIN: LU0000000000 non valido", !MotoreMercato.isinValido("LU0000000000"))
        verifica.vero("Mercato ISIN: « ie00 b4l5 y983 » normalizzato e valido",
                      MotoreMercato.isinValido(MotoreMercato.normalizzaISIN(" ie00 b4l5 y983 ")))
        let posizioni = [
            posizione("p1", cliente: "anna", isin: isinA, valore: 10_000),
            posizione("p2", cliente: "bruno", isin: isinA.lowercased(), valore: 5_000, canale: .alleanza),
            posizione("p3", cliente: "carla", isin: isinA, valore: 7_000),
            posizione("p4", cliente: "carla", isin: isinA, valore: 1_000),
            posizione("p5", cliente: "dario", isin: isinA, valore: 2_000, stato: .proposta),
            posizione("p6", cliente: "elena", isin: isinA, valore: 2_000, stato: .chiusa),
        ]
        let quote = [QuotaISIN(isin: isinA, nome: "Fondo di prova", punti: [PuntoMercato(data: d(2026, 10, 30), valore: 18.42)],
                               fonte: "Estratto di prova", origine: .csv, importataIl: oggi)]
        if case .trovato(let r) = MotoreMercato.cercaISIN(" zz00 0000 0016 ", posizioni: posizioni, quote: quote) {
            verifica("Mercato ISIN: nei portafogli di 3 clienti", Double(r.numeroClienti), 3)
            verifica.vero("Mercato ISIN: «Nei portafogli di 3 clienti»", r.neiPortafogli == "Nei portafogli di 3 clienti")
            verifica("Mercato ISIN: 4 posizioni in essere", Double(r.posizioni.count), 4)
            verifica("Mercato ISIN: 1 proposta a parte", Double(r.proposte.count), 1)
            verifica("Mercato ISIN: 1 cliente Alleanza", Double(r.clientiPerCanale[.alleanza] ?? 0), 1)
            verifica("Mercato ISIN: quota trovata", r.quota?.ultimo?.valore ?? 0, 18.42)
        } else {
            verifica.vero("Mercato ISIN: ricerca riuscita", false)
        }
        verifica.vero("Mercato ISIN: codice sbagliato", MotoreMercato.cercaISIN("LU0000000000", posizioni: posizioni, quote: quote) == .nonValido)
        if case .trovato(let r) = MotoreMercato.cercaISIN("IE00B4L5Y983", posizioni: posizioni, quote: quote) {
            verifica.vero("Mercato ISIN: valido ma sconosciuto", r.numeroClienti == 0 && r.quota == nil
                          && r.neiPortafogli == "Non è nei portafogli dei clienti")
        } else {
            verifica.vero("Mercato ISIN: valido ma sconosciuto", false)
        }
    }

    // MARK: - 4. «Chi è toccato» e avvisi con le soglie

    private static func clienti() -> [Cliente] {
        ["anna", "bruno", "carla", "dario"].map { id in
            Cliente(id: id, nome: id.capitalized + " Prova", iniziali: String(id.prefix(2)).uppercased(), tinta: .blu, tema: "",
                    email: "", telefono: "", preferito: false, nota: "", creatoIl: d(2020, 1, 1))
        }
    }

    private static func posizione(_ id: String, cliente: String, isin: String? = nil, valore: Double, canale: Canale = .indipendente,
                                  stato: StatoPosizione = .inEssere, _ modifica: (inout Posizione) -> Void = { _ in }) -> Posizione {
        var p = AiutiProva.posizione("Posizione \(id)", .investimento, valore, canale: canale)
        p.id = id
        p.clienteId = cliente
        p.stato = stato
        p.isin = isin
        modifica(&p)
        return p
    }

    private static func scenario() -> (archivio: ArchivioMercato, posizioni: [Posizione], obiettivi: [Obiettivo]) {
        var m = ArchivioMercato()
        m.quote = [QuotaISIN(isin: isinA, nome: "Fondo di prova", punti: [
            PuntoMercato(data: d(2026, 3, 2), valore: 19.6), PuntoMercato(data: d(2026, 9, 30), valore: 18),
            PuntoMercato(data: d(2026, 10, 30), valore: 18.42),
        ], fonte: "Estratto di prova", origine: .csv, importataIl: oggi)]
        m.serie = [
            SerieMercato(id: "indice-prova", nome: "Indice di prova", origine: .csv, fonte: "File di prova", unita: .punti,
                         tipo: .indiceAzionario, frequenza: .mensile,
                         punti: [PuntoMercato(data: d(2026, 9, 1), valore: 1_000), PuntoMercato(data: d(2026, 10, 1), valore: 980)],
                         aggiornataIl: oggi),
            SerieMercato(id: "btp-prova", codice: "IRS.M.IT.L.L40.CI.0000.EUR.N.Z", nome: "Rendimento di prova", origine: .bce, fonte: "BCE",
                         unita: .percentuale, tipo: .rendimentoStato, frequenza: .mensile,
                         punti: [PuntoMercato(data: d(2026, 9, 1), valore: 3.27), PuntoMercato(data: d(2026, 10, 1), valore: 3.42)],
                         aggiornataIl: oggi),
        ]
        let posizioni = [
            posizione("pa", cliente: "anna", isin: isinA, valore: 18_000) { $0.numeroQuote = 1_000; $0.quotaAzionaria = 100; $0.dataValore = d(2026, 9, 30) },
            posizione("pb", cliente: "bruno", isin: isinA, valore: 9_000, canale: .alleanza) { $0.quotaAzionaria = 50 },
            posizione("pb2", cliente: "bruno", isin: isinA, valore: 9_000, stato: .proposta) { $0.quotaAzionaria = 100 },
            posizione("pc", cliente: "carla", valore: 100_000) { $0.quotaAzionaria = 40 },
            posizione("pc2", cliente: "carla", valore: 50_000) { $0.tipologia = "Polizza rivalutabile Ramo I" },
            posizione("pd", cliente: "dario", valore: 20_000) {
                $0.nome = "BTP di prova"
                $0.quotaAzionaria = 0
                $0.quotaTitoliStato = 100
                $0.cedola = CedolaTitolo(tassoAnnuo: 3.5, volteAllAnno: 2, prossima: d(2026, 5, 16))
            },
            posizione("px", cliente: "sconosciuto", isin: isinA, valore: 50_000) { $0.quotaAzionaria = 100 },
        ]
        let obiettivi = [Obiettivo(clienteId: "carla", titolo: "Pensione", area: .pensione, importo: 200_000, scadenza: d(2040, 1, 1)),
                         Obiettivo(clienteId: "anna", titolo: "Auto", area: .casa, importo: 20_000, scadenza: d(2027, 6, 1))]
        return (m, posizioni, obiettivi)
    }

    private static func soglieComplete() -> ImpostazioniMercato {
        var i = ImpostazioniMercato()
        i.caloDalMassimo = 5
        i.distanzaDalRiferimento = 3
        i.giorniCedola = 15
        i.variazioneIndici = 1.5
        i.variazioneTassi = 0.1
        i.riferimenti = [isinA: "indice-prova"]
        return i
    }

    private static func toccatiEAvvisi(_ verifica: VerificaCalcoli) {
        let (m, posizioni, obiettivi) = scenario()
        let cl = clienti()
        func eventi(_ i: ImpostazioniMercato, il giorno: Date = oggi) -> [EventoMercato] {
            MotoreMercato.toccati(archivio: m, impostazioni: i, posizioni: posizioni, clienti: cl, obiettivi: obiettivi, oggi: giorno, cal: cal)
        }
        // Nessuna soglia = nessun evento e nessun avviso
        let nessuno = eventi(ImpostazioniMercato())
        verifica.vero("Mercato avvisi: nessuna soglia, nessun evento", nessuno.isEmpty)
        verifica.vero("Mercato avvisi: nessuna soglia, nessun avviso",
                      MotoreMercato.avvisi(eventi: nessuno, esistenti: [], oggi: oggi, cal: cal).isEmpty)
        let tutti = eventi(soglieComplete())
        // Calo dal massimo: 19,60 → 18,42 = −6,0%, soglia 5%
        let calo = tutti.first { $0.tipo == .caloDalMassimo }
        verifica("Mercato avvisi: calo dal massimo 6,02%", calo?.valore ?? 0, (1 - 18.42 / 19.6) * 100, tolleranza: 0.001)
        verifica.vero("Mercato avvisi: calo, solo i clienti con la posizione in essere (non la proposta, non chi non è cliente)",
                      calo?.toccati.map(\.clienteId) == ["anna", "bruno"])
        verifica("Mercato avvisi: calo di Anna dalle sue quote (1.000 × −1,18)", calo?.toccati.first?.impatto ?? 0, -1_180)
        verifica("Mercato avvisi: calo di Bruno senza quote (9.000 × −6,02%)", calo?.toccati.last?.impatto ?? 0, -9_000 * (1 - 18.42 / 19.6), tolleranza: 0.01)
        verifica.vero("Mercato avvisi: calo, canale di Bruno Alleanza", calo?.toccati.last?.canaleUnico == .alleanza)
        verifica.vero("Mercato avvisi: titolo del calo", calo?.titolo == "«Fondo di prova» è sceso del 6,0% dal massimo dell'ultimo anno")
        var soloSette = soglieComplete()
        soloSette.caloDalMassimo = 7
        verifica.vero("Mercato avvisi: soglia 7% non raggiunta", !eventi(soloSette).contains { $0.tipo == .caloDalMassimo })
        // Variazione di un indice: 1.000 → 980 = −2%, esposti per quota in azioni (separati per canale)
        let indice = tutti.first { $0.tipo == .variazioneSerie && $0.serieId == "indice-prova" }
        verifica("Mercato chi è toccato: indice −2%", indice?.valore ?? 0, -2, tolleranza: 1e-9)
        verifica.vero("Mercato chi è toccato: ordine per impatto (Carla, Anna, Bruno)", indice?.toccati.map(\.clienteId) == ["carla", "anna", "bruno"])
        verifica("Mercato chi è toccato: Carla 100.000 × 40% × −2%", indice?.toccati.first?.impatto ?? 0, -800)
        verifica("Mercato chi è toccato: Anna 18.000 × 100% × −2%", indice?.toccati.dropFirst().first?.impatto ?? 0, -360)
        verifica("Mercato chi è toccato: Bruno in Alleanza", indice?.toccati.last?.perCanale[.alleanza] ?? 0, -90)
        verifica.vero("Mercato chi è toccato: gestione separata fuori (pc2)", indice?.toccati.first?.posizioni == ["pc"])
        verifica.vero("Mercato chi è toccato: Dario senza azioni fuori", !(indice?.toccati.contains { $0.clienteId == "dario" } ?? true))
        // Variazione di un rendimento: +0,15 punti, soglia 0,10: esposti i titoli di Stato, impatto solo qualitativo
        let btp = tutti.first { $0.tipo == .variazioneSerie && $0.serieId == "btp-prova" }
        verifica("Mercato chi è toccato: rendimento +0,15 punti", btp?.valore ?? 0, 0.15, tolleranza: 1e-9)
        verifica.vero("Mercato chi è toccato: Dario tra i toccati dal rendimento", btp?.toccati.contains { $0.clienteId == "dario" && $0.impatto == nil } == true)
        verifica.vero("Mercato chi è toccato: fonte citata", btp?.fonte == "Fonte: BCE")
        var tassiAlti = soglieComplete()
        tassiAlti.variazioneTassi = 0.2
        verifica.vero("Mercato chi è toccato: sotto la soglia dei tassi nessun evento", !eventi(tassiAlti).contains { $0.serieId == "btp-prova" })
        // Cedola: la data scritta è passata, si va avanti di 6 mesi (16 novembre, tra 12 giorni)
        let cedola = tutti.first { $0.tipo == .cedolaInArrivo }
        verifica("Mercato avvisi: cedola tra 12 giorni", cedola?.valore ?? 0, 12)
        verifica.vero("Mercato avvisi: testo della cedola", cedola?.titolo == "La cedola di «BTP di prova» arriva tra 12 giorni, il 16 novembre 2026")
        var cedolaCorta = soglieComplete()
        cedolaCorta.giorniCedola = 10
        verifica.vero("Mercato avvisi: cedola oltre i 10 giorni, nessun avviso", !eventi(cedolaCorta).contains { $0.tipo == .cedolaInArrivo })
        // Distanza dal riferimento: quota +2,33% contro indice −2% in un mese = 4,3 punti
        let distanza = tutti.first { $0.tipo == .distanzaDalRiferimento }
        verifica("Mercato avvisi: distanza dal riferimento", distanza?.valore ?? 0, (18.42 / 18 - 1) * 100 + 2, tolleranza: 0.001)
        verifica.vero("Mercato avvisi: distanza, Anna e Bruno", distanza?.toccati.map(\.clienteId).sorted() == ["anna", "bruno"])
        var senzaRiferimento = soglieComplete()
        senzaRiferimento.riferimenti = [:]
        verifica.vero("Mercato avvisi: senza riferimento scelto, nessuna distanza", !eventi(senzaRiferimento).contains { $0.tipo == .distanzaDalRiferimento })
        // Inflazione: con una soglia dei tassi anche un nuovo dato tocca gli obiettivi oltre 5 anni (Carla, non Anna)
        var conInflazione = m
        conInflazione.serie.append(SerieMercato(id: "infl-prova", nome: "Inflazione di prova", origine: .eurostat, fonte: "Eurostat",
                                                unita: .percentuale, tipo: .inflazione, frequenza: .mensile,
                                                punti: [PuntoMercato(data: d(2026, 9, 1), valore: 1.6), PuntoMercato(data: d(2026, 10, 1), valore: 1.9)],
                                                aggiornataIl: oggi))
        let infl = MotoreMercato.toccati(archivio: conInflazione, impostazioni: soglieComplete(), posizioni: posizioni, clienti: cl,
                                         obiettivi: obiettivi, oggi: oggi, cal: cal).first { $0.serieId == "infl-prova" }
        verifica.vero("Mercato chi è toccato: inflazione, gli obiettivi lontani (Carla)", infl?.toccati.map(\.clienteId) == ["carla"])
        verifica.vero("Mercato chi è toccato: «Fonte: Eurostat»", infl?.fonte == "Fonte: Eurostat")
        // Dati vecchi: dopo due mesi senza dati nuovi nessun evento delle serie mensili
        verifica.vero("Mercato chi è toccato: dati vecchi, nessun evento",
                      !eventi(soglieComplete(), il: d(2027, 1, 15)).contains { $0.tipo == .variazioneSerie })

        // Avvisi: nascono nuovi, uno visto resta visto, una condizione rientrata li toglie, se torna torna nuova
        var avvisi = MotoreMercato.avvisi(eventi: tutti, esistenti: [], oggi: oggi, cal: cal)
        let attesi = tutti.reduce(0) { $0 + $1.toccati.count }
        verifica("Mercato avvisi: uno per cliente toccato", Double(avvisi.count), Double(attesi))
        verifica.vero("Mercato avvisi: tutti nuovi", avvisi.allSatisfy { $0.stato == .nuovo && $0.creatoIl == oggi })
        let idCalo = "caloDalMassimo-anna-\(isinA)"
        verifica.vero("Mercato avvisi: id stabile del calo", avvisi.contains { $0.id == idCalo })
        MotoreMercato.segnaVisto(idCalo, in: &avvisi, il: oggi)
        let domani = d(2026, 11, 5)
        let ancora = MotoreMercato.avvisi(eventi: eventi(soglieComplete(), il: domani), esistenti: avvisi, oggi: domani, cal: cal)
        verifica.vero("Mercato avvisi: già scattato non si ripete (resta visto, nato ieri)",
                      ancora.first { $0.id == idCalo }.map { $0.stato == .visto && $0.creatoIl == oggi } == true)
        verifica("Mercato avvisi: nessun doppione il giorno dopo", Double(ancora.count), Double(avvisi.count))
        let rientrato = MotoreMercato.avvisi(eventi: eventi(soloSette, il: domani), esistenti: ancora, oggi: domani, cal: cal)
        verifica.vero("Mercato avvisi: calo rientrato, avviso tolto", !rientrato.contains { $0.id == idCalo })
        verifica.vero("Mercato avvisi: eventi singoli conservati", rientrato.contains { $0.tipo == .cedolaInArrivo })
        let tornato = MotoreMercato.avvisi(eventi: eventi(soglieComplete(), il: domani), esistenti: rientrato, oggi: domani, cal: cal)
        verifica.vero("Mercato avvisi: calo tornato, avviso di nuovo nuovo", tornato.first { $0.id == idCalo }?.stato == .nuovo)
        let tardi = MotoreMercato.avvisi(eventi: [], esistenti: tornato, oggi: d(2027, 6, 1), cal: cal)
        verifica.vero("Mercato avvisi: dopo 90 giorni gli eventi singoli si tolgono", tardi.isEmpty)
    }

    // MARK: - 5. Valori per «Aggiorna valori»

    private static func valoriPerAggiornamento(_ verifica: VerificaCalcoli) {
        let (m, posizioni, _) = scenario()
        let valori = MotoreMercato.valoriDaQuote(posizioni: posizioni, quote: m.quote, oggi: oggi, cal: cal)
        let a = valori.first { $0.posizioneId == "pa" }
        verifica("Mercato valori: quota 18,42 × 1.000 quote", a?.valore ?? 0, 18_420)
        verifica.vero("Mercato valori: con data e fonte", a?.data == d(2026, 10, 30) && a?.fonte == "Fonte: Estratto di prova (file importato)")
        let b = valori.first { $0.posizioneId == "pb" }
        verifica.vero("Mercato valori: senza il numero di quote nessun valore", b != nil && b?.valore == nil && b?.motivo == TestiMercato.mancaNumeroQuote)
        verifica.vero("Mercato valori: la proposta non riceve valori", !valori.contains { $0.posizioneId == "pb2" })
        // Lo stesso percorso dell'aggiornamento in blocco: storico, valore attuale, senza valore
        var elenco = posizioni
        let righe = MotoreMercato.righeAggiornamento(valori)
        let esiti = AggiornaValori.esiti(righe, posizioni: elenco, clienti: clienti(), dataComune: oggi, oggi: oggi)
        verifica.vero("Mercato valori: Anna da aggiornare", esiti.first { $0.posizioneId == "pa" }?.stato == .aggiorna)
        verifica.vero("Mercato valori: Bruno senza valore", esiti.first { $0.riga.posizioneId == "pb" }?.stato == .senzaValore)
        _ = AggiornaValori.applica(esiti, esclusi: [], a: &elenco)
        let dopo = elenco.first { $0.id == "pa" }
        verifica("Mercato valori: nuovo controvalore", dopo?.controvalore ?? 0, 18_420)
        verifica.vero("Mercato valori: il valore di prima nello storico", dopo?.rilevazioni?.contains { $0.controvalore == 18_000 } == true)
        // Lo stesso ISIN in due posizioni: ognuna con le sue quote
        let due = [posizione("x1", cliente: "anna", isin: isinB, valore: 1_000) { $0.numeroQuote = 200 },
                   posizione("x2", cliente: "bruno", isin: isinB, valore: 1_000) { $0.numeroQuote = 300 }]
        let qb = [QuotaISIN(isin: isinB, punti: [PuntoMercato(data: d(2026, 11, 3), valore: 10.5)], fonte: "Prova", origine: .aMano, importataIl: oggi)]
        let vb = MotoreMercato.valoriDaQuote(posizioni: due, quote: qb, oggi: oggi, cal: cal)
        verifica.vero("Mercato valori: stesso ISIN, quote di ognuna (2.100 e 3.150)", vb.map { $0.valore ?? 0 } == [2_100, 3_150])
        verifica.vero("Mercato valori: inserito a mano citato", vb.first?.fonte == "Fonte: Prova (inserito a mano)")
    }

    // MARK: - 6. Occasioni per Messaggi

    private static func occasioni(_ verifica: VerificaCalcoli) {
        let (m, posizioni, obiettivi) = scenario()
        let cl = clienti()
        var archivio = m
        archivio.avvisi = MotoreMercato.avvisi(eventi: MotoreMercato.toccati(archivio: m, impostazioni: soglieComplete(), posizioni: posizioni,
                                                                              clienti: cl, obiettivi: obiettivi, oggi: oggi, cal: cal),
                                               esistenti: [], oggi: oggi, cal: cal)
        var x = DatiPrisma(clienti: cl, appuntamenti: [], attivita: [], posizioni: posizioni, clienteAttivoId: "anna", impostazioni: Impostazioni())
        x.mercato = archivio
        let o = MotoreOccasioniMessaggi.calcola(dati: x, oggi: oggi, cal: cal).tutte.filter { $0.tipo == .avvisoMercato }
        verifica.vero("Mercato messaggi: gli avvisi diventano occasioni", !o.isEmpty)
        verifica.vero("Mercato messaggi: nati oggi, «Da mandare oggi»", o.allSatisfy { $0.gruppo == .oggi })
        verifica.vero("Mercato messaggi: la frase dell'avviso è la cifra da citare",
                      o.allSatisfy { occ in archivio.avvisi.contains { $0.id == occ.origine.riferimento && occ.valore(.avviso) == $0.titolo } })
        let vecchie = MotoreOccasioniMessaggi.avvisiMercato(archivio.avvisi, clienti: Dictionary(uniqueKeysWithValues: cl.map { ($0.id, $0) }),
                                                            posizioni: [:], oggi: d(2026, 11, 20), cal: cal)
        verifica.vero("Mercato messaggi: dopo una settimana niente occasioni", vecchie.isEmpty)
        var vuoto = DatiPrisma(clienti: cl, appuntamenti: [], attivita: [], posizioni: posizioni, clienteAttivoId: "anna", impostazioni: Impostazioni())
        vuoto.mercato = m
        verifica.vero("Mercato messaggi: senza avvisi nessuna occasione di mercato",
                      !MotoreOccasioniMessaggi.calcola(dati: vuoto, oggi: oggi, cal: cal).tutte.contains { $0.tipo == .avvisoMercato })
    }

    // MARK: - 7. Nessun dato dei clienti nelle richieste

    private static func richieste(_ verifica: VerificaCalcoli) {
        guard let conf = ConfigurazioneMercato.caricaDelPacchetto() else {
            verifica.vero("Mercato rete: configurazione delle serie nel pacchetto", false)
            return
        }
        verifica("Mercato rete: 7 serie configurate", Double(conf.serie.count), 7)
        verifica.vero("Mercato rete: spread configurato", conf.calcolate.first?.id == "spread-it-de")
        verifica.vero("Mercato rete: solo BCE ed Eurostat", conf.serie.allSatisfy { $0.fonte == .bce || $0.fonte == .eurostat })
        // Interruttore spento (com'è di base): nessuna richiesta
        verifica.vero("Mercato rete: spento di base", !ImpostazioniMercato().attivo && !Impostazioni().mercato.attivo)
        verifica.vero("Mercato rete: spento, nessuna richiesta",
                      ClienteMercato.richieste(impostazioni: ImpostazioniMercato(), configurazione: conf, oggi: oggi).isEmpty)
        var acceso = ImpostazioniMercato()
        acceso.attivo = true
        let tutte = ClienteMercato.richieste(impostazioni: acceso, configurazione: conf, oggi: oggi)
        verifica("Mercato rete: una richiesta per serie", Double(tutte.count), 7)
        acceso.serieAttive = ["inflazione-it"]
        verifica("Mercato rete: solo le serie scelte", Double(ClienteMercato.richieste(impostazioni: acceso, configurazione: conf, oggi: oggi).count), 1)
        // Che cosa c'è in ogni richiesta: solo indirizzi pubblici, codici pubblici e periodi
        let forma = #"^https://(data-api\.ecb\.europa\.eu/service/data/[A-Z0-9_]+/[A-Za-z0-9_.]+|ec\.europa\.eu/eurostat/api/dissemination/statistics/1\.0/data/[a-z0-9_]+)\?[A-Za-z0-9_=&.-]+$"#
        let dati = DatiPrisma.demo()
        let sensibili = datiSensibili(dati)
        verifica.vero("Mercato rete: elenco dei dati dei clienti da cercare", sensibili.count > 20)
        var trovati: [String] = []
        var fuoriForma: [String] = []
        for (_, r) in tutte {
            let url = r.url?.absoluteString ?? ""
            if url.range(of: forma, options: .regularExpression) == nil { fuoriForma.append(url) }
            let minuscolo = url.lowercased()
            trovati += sensibili.filter { minuscolo.contains($0) }.map { "\($0) in \(url)" }
            let intestazioni = Set((r.allHTTPHeaderFields ?? [:]).keys)
            if r.httpMethod != "GET" || r.httpBody != nil || r.httpShouldHandleCookies || !intestazioni.isSubset(of: ["Accept", "User-Agent"])
                || !ClienteMercato.hostConsentiti.contains(r.url?.host ?? "") {
                fuoriForma.append("intestazioni o metodo: \(url)")
            }
        }
        for t in trovati.prefix(5) { print("ERRORE: dato del cliente nella richiesta: \(t)") }
        for t in fuoriForma.prefix(5) { print("ERRORE: richiesta fuori forma: \(t)") }
        verifica.vero("Mercato rete: nessun dato dei clienti nelle richieste", trovati.isEmpty)
        verifica.vero("Mercato rete: richieste solo verso BCE ed Eurostat, nella forma attesa", fuoriForma.isEmpty)
        // Le richieste attese, una per fonte
        let bce = tutte.first { $0.serie.id == "bce-depositi" }?.richiesta.url?.absoluteString
        verifica.vero("Mercato rete: richiesta BCE",
                      bce == "https://data-api.ecb.europa.eu/service/data/FM/D.U2.EUR.4F.KR.DFR.LEV?format=csvdata&lastNObservations=300")
        let eurostat = tutte.first { $0.serie.id == "inflazione-it" }?.richiesta.url?.absoluteString
        verifica.vero("Mercato rete: richiesta Eurostat",
                      eurostat == "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/prc_hicp_manr?format=JSON&lang=EN&coicop=CP00&geo=IT&sinceTimePeriod=2023-11")
        // Un codice che non è un codice pubblico non parte (dati scritti nella configurazione per errore)
        let base = conf.serie.first { $0.fonte == .bce }
        let eu = conf.serie.first { $0.fonte == .eurostat }
        if var cattiva = base, var filtri = eu {
            cattiva.codice = "FM.D/../Giulia Rossi?nome=x"
            verifica.vero("Mercato rete: chiave BCE fuori forma rifiutata", ClienteMercato.richiesta(cattiva, oggi: oggi) == nil)
            filtri.filtri = ["geo": "IT", "cliente": "Giulia Rossi"]
            verifica.vero("Mercato rete: filtro Eurostat fuori forma rifiutato", ClienteMercato.richiesta(filtri, oggi: oggi) == nil)
            filtri.filtri = ["geo": "IT"]
            filtri.codice = "prc_hicp_manr&isin=\(isinA)"
            verifica.vero("Mercato rete: dataset Eurostat fuori forma rifiutato", ClienteMercato.richiesta(filtri, oggi: oggi) == nil)
        } else {
            verifica.vero("Mercato rete: serie BCE ed Eurostat nella configurazione", false)
        }
        // Gli ISIN non escono mai: nessuna richiesta per le quote
        var quota = base
        quota?.fonte = .csv
        verifica.vero("Mercato rete: nessuna richiesta per CSV e quote", quota.flatMap { ClienteMercato.richiesta($0, oggi: oggi) } == nil)
    }

    /// I dati dei clienti di prova che non devono mai comparire in una richiesta: id, nomi (parole di almeno 4
    /// lettere), codici fiscali, recapiti, numeri di contratto, ISIN, importi.
    private static func datiSensibili(_ dati: DatiPrisma) -> [String] {
        var elenco = Set<String>()
        func aggiungi(_ s: String, minimo: Int = 4) {
            let t = s.trimmingCharacters(in: .whitespaces).lowercased()
            if t.count >= minimo { elenco.insert(t) }
        }
        for c in dati.clienti {
            aggiungi(c.id)
            c.nome.split { !$0.isLetter }.forEach { aggiungi(String($0)) }
            aggiungi(c.codiceFiscale)
            aggiungi(c.email)
            aggiungi(c.telefono.filter(\.isNumber), minimo: 6)
        }
        for p in dati.posizioni {
            aggiungi(p.id)
            aggiungi(p.numeroContratto)
            aggiungi(p.isin ?? "")
            if let v = p.controvalore, v >= 10_000 { aggiungi(String(Int(v.rounded())), minimo: 5) }
        }
        aggiungi(isinA)
        aggiungi("IE00B4L5Y983")
        return elenco.sorted()
    }

    // MARK: - 8. Scaricamento completo senza rete

    private static func scaricamentoDiProva(_ verifica: VerificaCalcoli) {
        guard let conf = ConfigurazioneMercato.caricaDelPacchetto(), let depositi = esempio("bce-depositi.csv"),
              let rendimento = esempio("bce-rendimento-it.csv"), let inflazione = esempio("eurostat-inflazione.json") else {
            verifica.vero("Mercato scaricamento: esempi e configurazione nel pacchetto", false)
            return
        }
        ProtocolloProvaMercato.prepara([
            "/service/data/FM/D.U2.EUR.4F.KR.DFR.LEV": depositi,
            "/service/data/IRS/M.IT.L.L40.CI.0000.EUR.N.Z": rendimento,
            "/data/prc_hicp_manr": inflazione,
        ])
        let sessione = ClienteMercato.sessione(protocolli: [ProtocolloProvaMercato.self])
        var impostazioni = ImpostazioniMercato()
        impostazioni.serieAttive = ["bce-depositi", "rendimento-it-lungo", "rendimento-de-lungo", "inflazione-it"]
        // Spento: nessuna richiesta
        let spento = attendi(ArchivioMercato(), impostazioni, conf, sessione: sessione, il: oggi)
        verifica.vero("Mercato scaricamento: spento, saltato", spento?.saltato == true)
        verifica("Mercato scaricamento: spento, nessuna richiesta", Double(ProtocolloProvaMercato.viste().count), 0)
        impostazioni.attivo = true
        guard let esito = attendi(ArchivioMercato(), impostazioni, conf, sessione: sessione, il: oggi) else {
            verifica.vero("Mercato scaricamento: finito in tempo", false)
            return
        }
        let viste = ProtocolloProvaMercato.viste()
        verifica("Mercato scaricamento: 4 richieste", Double(viste.count), 4)
        verifica.vero("Mercato scaricamento: solo BCE ed Eurostat", viste.allSatisfy { ClienteMercato.hostConsentiti.contains($0.host ?? "") })
        verifica.vero("Mercato scaricamento: tre serie lette", esito.scaricate.sorted() == ["bce-depositi", "inflazione-it", "rendimento-it-lungo"])
        verifica.vero("Mercato scaricamento: serie inesistente, errore", esito.errori["rendimento-de-lungo"] == ErroreMercato.serieNonTrovata("IRS.M.DE.L.L40.CI.0000.EUR.N.Z").descrizione)
        verifica.vero("Mercato scaricamento: ultimo errore conservato", esito.archivio.ultimoErrore?.contains("rendimento-de-lungo") == true)
        verifica.vero("Mercato scaricamento: data dell'aggiornamento", esito.archivio.ultimoAggiornamento == oggi)
        let dfr = esito.archivio.serie("bce-depositi")
        verifica.vero("Mercato scaricamento: tasso BCE potato all'ultimo valore", dfr?.punti.count == 1 && dfr?.ultimo?.valore == 2)
        verifica.vero("Mercato scaricamento: «Fonte: BCE»", dfr?.citazione == "Fonte: BCE")
        verifica("Mercato scaricamento: rendimento Italia, 6 mesi", Double(esito.archivio.serie("rendimento-it-lungo")?.punti.count ?? 0), 6)
        verifica.vero("Mercato scaricamento: inflazione, «Fonte: Eurostat»", esito.archivio.serie("inflazione-it")?.citazione == "Fonte: Eurostat")
        verifica.vero("Mercato scaricamento: spread non ricavato senza la Germania", esito.archivio.serie("spread-it-de") == nil)
        // Cache: un'ora dopo non riparte; con «Aggiorna ora» sì
        let presto = attendi(esito.archivio, impostazioni, conf, sessione: sessione, il: oggi.addingTimeInterval(3_600))
        verifica.vero("Mercato scaricamento: un'ora dopo non riparte", presto?.saltato == true && ProtocolloProvaMercato.viste().isEmpty)
        let forzato = attendi(esito.archivio, impostazioni, conf, sessione: sessione, il: oggi.addingTimeInterval(3_600), forza: true)
        verifica.vero("Mercato scaricamento: «Aggiorna ora» riparte", forzato?.saltato == false && ProtocolloProvaMercato.viste().count == 4)
        ProtocolloProvaMercato.prepara([:])
        sessione.invalidateAndCancel()
    }

    /// Aspetta un aggiornamento (al massimo 30 secondi); le richieste viste ripartono da zero.
    private static func attendi(_ archivio: ArchivioMercato, _ impostazioni: ImpostazioniMercato, _ conf: ConfigurazioneMercato,
                                sessione: URLSession, il giorno: Date, forza: Bool = false) -> EsitoAggiornamentoMercato? {
        final class Scatola: @unchecked Sendable { var esito: EsitoAggiornamentoMercato? }
        let scatola = Scatola()
        let fatto = DispatchSemaphore(value: 0)
        ProtocolloProvaMercato.azzera()
        Task.detached {
            scatola.esito = await ClienteMercato.aggiorna(archivio, impostazioni: impostazioni, configurazione: conf, oggi: giorno,
                                                          forza: forza, sessione: sessione)
            fatto.signal()
        }
        guard fatto.wait(timeout: .now() + 30) == .success else { return nil }
        return scatola.esito
    }

    // MARK: - 9. Serie: unione, spread, lettura tollerante

    private static func serieEArchivio(_ verifica: VerificaCalcoli) {
        let unite = MotoreMercato.unisci([PuntoMercato(data: d(2026, 9, 1), valore: 1), PuntoMercato(data: d(2026, 10, 1), valore: 2)],
                                         [PuntoMercato(data: d(2026, 10, 1), valore: 3)], cal: cal)
        verifica.vero("Mercato serie: a parità di giorno vince il valore nuovo", unite.map(\.valore) == [1, 3])
        let it = SerieMercato(id: "it", codice: "IT", nome: "IT", origine: .bce, fonte: "BCE", unita: .percentuale, tipo: .rendimentoStato,
                              frequenza: .mensile, punti: [PuntoMercato(data: d(2026, 9, 1), valore: 3.42), PuntoMercato(data: d(2026, 10, 1), valore: 3.5)],
                              aggiornataIl: oggi)
        let de = SerieMercato(id: "de", codice: "DE", nome: "DE", origine: .bce, fonte: "BCE", unita: .percentuale, tipo: .rendimentoStato,
                              frequenza: .mensile, punti: [PuntoMercato(data: d(2026, 9, 1), valore: 2.62)], aggiornataIl: oggi)
        let spread = MotoreMercato.differenza(it, de, id: "spread", nome: "Spread", unita: .percentuale, tipo: .spread, il: oggi, cal: cal)
        verifica.vero("Mercato serie: spread solo sulle date comuni", spread?.punti.count == 1)
        verifica("Mercato serie: spread 3,42 − 2,62", spread?.ultimo?.valore ?? 0, 0.8, tolleranza: 1e-9)
        // Quote registrate: ogni valore con la sua fonte, un ISIN sbagliato saltato
        var archivio = ArchivioMercato()
        MotoreMercato.registraQuote([isinA: [PuntoMercato(data: d(2026, 10, 30), valore: 18.42)], "LU0000000000": [PuntoMercato(data: d(2026, 10, 30), valore: 1)]],
                                    fonte: "Estratto di prova", origine: .csv, in: &archivio, il: oggi, cal: cal)
        MotoreMercato.registraQuote([isinA: [PuntoMercato(data: d(2026, 10, 31), valore: 18.5)]], fonte: "A voce", origine: .aMano,
                                    in: &archivio, il: oggi, cal: cal)
        verifica.vero("Mercato serie: quote unite con la loro fonte", archivio.quote.count == 1
                      && archivio.quote.first?.punti.map(\.fonte) == ["Estratto di prova", "A voce"])
        // Lettura tollerante di una serie: un punto senza data si scarta, un valore non numerico pure
        let testo = #"{"id":"s","nome":"Serie","punti":[{"data":"2026-10-01T10:00:00Z","valore":1},{"valore":2},{"data":"2026-10-02T10:00:00Z","valore":"tre"}]}"#
        let letta = try? Archivio.decodificatore.decode(SerieMercato.self, from: Data(testo.utf8))
        verifica.vero("Mercato serie: punto senza data scartato, gli altri restano", letta?.punti.count == 1 && letta?.origine == .aMano)
        // La frase della fascia
        verifica.vero("Mercato: «Nessun dato esce dal Mac» con l'interruttore spento", TestiMercato.riservatezza(attivo: false) == "Nessun dato esce dal Mac.")
    }
}

/// Le risposte di esempio al posto della rete (solo per le prove): per ogni percorso il contenuto, gli altri 404.
/// Tiene le richieste viste, per controllare che con l'interruttore spento non ne parta nessuna.
final class ProtocolloProvaMercato: URLProtocol {
    private static let chiave = NSLock()
    private static var risposte: [String: Data] = [:]
    private static var richieste: [URL] = []

    static func prepara(_ r: [String: Data]) {
        chiave.lock()
        risposte = r
        richieste = []
        chiave.unlock()
    }

    static func azzera() {
        chiave.lock()
        richieste = []
        chiave.unlock()
    }

    static func viste() -> [URL] {
        chiave.lock()
        defer { chiave.unlock() }
        return richieste
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        Self.chiave.lock()
        Self.richieste.append(url)
        let dati = Self.risposte.first { url.path.hasSuffix($0.key) }?.value
        Self.chiave.unlock()
        let codice = dati == nil ? 404 : 200
        guard let risposta = HTTPURLResponse(url: url, statusCode: codice, httpVersion: "HTTP/1.1", headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: risposta, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: dati ?? Data("No results found.".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
