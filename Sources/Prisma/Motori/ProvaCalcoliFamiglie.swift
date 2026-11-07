import Foundation

/// Prove di «Rispetto alle famiglie come la sua» (Analisi 360, Orizzonte giro 6).
/// - F1-F11, formato versione 1 con il file di prova (valori segnaposto tondi, non statistiche: le prove controllano i
///   calcoli, non i dati): la cella età × reddito sui bordi, il percentile per interpolazione (masse a zero, sotto il
///   primo e sopra l'ultimo quantile), mediana e media sole, la quota, le frasi, le cautele, le cifre del cliente e la
///   validazione del file;
/// - B1-B10, formato versione 2 con le tavole vere della Banca d'Italia incluse (`famiglie-bdi-2022.json`): le cifre
///   del file controllate contro le tavole pubblicate (T4, T7, T15, T17, T23, T29), le classi d'età e i quinti sui
///   bordi, il confronto doppio (età e quinto) con rapporto tra medie, mediana, quota e decimi, la barra in valori
///   senza percentili inventati, le frasi, i dati mancanti e la validazione dei gruppi.
/// Chiamate da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliFamiglie {
    static func esegui(_ verifica: VerificaCalcoli) {
        tavoleBancaItalia(verifica)

        // F1. Il file di prova incluso nell'app si legge, è dichiarato di prova e ha una cella per coppia
        guard let t = TabelleFamiglie.tabelleDiProva else {
            verifica.vero("F1 File delle famiglie di prova leggibile", false)
            return
        }
        verifica.vero("F1 File di prova dichiarato «di prova»", t.diProva && t.fonte.contains("PROVA"))
        verifica("F1 Cinque classi d'età", Double(t.classiEta.count), 5)
        verifica("F1 Cinque fasce di reddito", Double(t.classiReddito.count), 5)
        verifica("F1 Una cella per coppia", Double(t.celle.count), 25)

        // F2. Classi sui bordi: età con estremi inclusi, reddito con «a» escluso
        verifica.vero("F2 34 anni nella prima classe", MotoreFamiglie.classeEta(34, in: t)?.id == "e1")
        verifica.vero("F2 35 anni nella seconda", MotoreFamiglie.classeEta(35, in: t)?.id == "e2")
        verifica.vero("F2 65 anni nell'ultima", MotoreFamiglie.classeEta(65, in: t)?.id == "e5")
        verifica.vero("F2 99 anni nell'ultima (senza limite)", MotoreFamiglie.classeEta(99, in: t)?.id == "e5")
        verifica.vero("F2 Reddito 9.999 nella prima fascia", MotoreFamiglie.classeReddito(9_999, in: t)?.id == "r1")
        verifica.vero("F2 Reddito 10.000 nella seconda («a» escluso)", MotoreFamiglie.classeReddito(10_000, in: t)?.id == "r2")
        verifica.vero("F2 Reddito 1.000.000 nell'ultima", MotoreFamiglie.classeReddito(1_000_000, in: t)?.id == "r5")
        verifica.vero("F2 Cella di 40 anni e 25.000 €", MotoreFamiglie.cella(eta: 40, reddito: 25_000, in: t).map { $0.eta == "e2" && $0.reddito == "r3" } == true)

        // F3. Percentile tra i quantili segnaposto della ricchezza (10.000 · 20.000 · 50.000 · 100.000 · 200.000)
        let ricchezza = t.cella(eta: "e2", reddito: "r3")?.ricchezzaFinanziaria?.quantili ?? []
        verifica("F3 Uguale alla mediana → 50", MotoreFamiglie.percentile(50_000, quantili: ricchezza) ?? -1, 50)
        verifica("F3 A metà tra p50 e p75 → 62,5", MotoreFamiglie.percentile(75_000, quantili: ricchezza) ?? -1, 62.5)
        verifica("F3 Sotto il primo: da 0 → 5", MotoreFamiglie.percentile(5_000, quantili: ricchezza) ?? -1, 5)
        verifica("F3 Sopra l'ultimo: si ferma a 90", MotoreFamiglie.percentile(900_000, quantili: ricchezza) ?? -1, 90)
        verifica("F3 Negativo sotto il primo → 0", MotoreFamiglie.percentile(-1_000, quantili: ricchezza) ?? -1, 0)
        verifica("F3 Arrotondamento per difetto (62,5 → 62)", Double(MotoreFamiglie.percentileIntero(62.5)), 62)
        verifica.vero("F3 Meno di due quantili: nessun percentile",
                      MotoreFamiglie.percentile(10, quantili: [QuantileFamiglie(percentile: 50, valore: 10)]) == nil)

        // F4. Masse: molte famiglie a zero (p10 = p25 = p50 = 0) → lo zero sta a metà della massa (25)
        let massa = DistribuzioneFamiglie(p10: 0, p25: 0, p50: 0, p75: 500, p90: 2_000).quantili
        verifica("F4 Zero con la massa a zero fino a p50 → 25", MotoreFamiglie.percentile(0, quantili: massa) ?? -1, 25)
        verifica("F4 250 tra p50 e p75 → 62,5", MotoreFamiglie.percentile(250, quantili: massa) ?? -1, 62.5)
        let piatta = DistribuzioneFamiglie(p10: 100, p25: 200, p50: 200, p75: 200, p90: 400).quantili
        verifica("F4 Massa in mezzo (p25…p75 = 200) → 50", MotoreFamiglie.percentile(200, quantili: piatta) ?? -1, 50)

        // F5. Frasi: la soglia dei 50, «su 10» per difetto
        verifica.vero("F5 72 → «più di circa 7 famiglie su 10»",
                      TestiFamiglie.frasePercentile(.tassoRisparmio, percentile: 72) == "Risparmia più di circa 7 famiglie su 10 come la sua.")
        verifica.vero("F5 50 → frase positiva",
                      TestiFamiglie.frasePercentile(.ricchezzaFinanziaria, percentile: 50) == "Ha più patrimonio finanziario di circa 5 famiglie su 10 come la sua.")
        verifica.vero("F5 49 → «meno di circa 5 su 10»",
                      TestiFamiglie.frasePercentile(.tassoRisparmio, percentile: 49) == "Risparmia meno di circa 5 famiglie su 10 come la sua.")
        verifica.vero("F5 0 → «meno di quasi tutte»",
                      TestiFamiglie.frasePercentile(.tassoRisparmio, percentile: 0) == "Risparmia meno di quasi tutte le famiglie come la sua.")
        verifica.vero("F5 Quota 40%, ha la polizza",
                      TestiFamiglie.fraseQuota(.protezione, ha: true, quota: 40) == "Ha almeno una polizza di protezione: ce l'hanno circa 4 famiglie su 10 come la sua.")
        verifica.vero("F5 Quota 3%, non aderisce: «quasi tutte»",
                      TestiFamiglie.fraseQuota(.previdenzaComplementare, ha: false, quota: 3).contains("quasi tutte le famiglie"))

        // F6. Il confronto completo con il file di prova: 40 anni, 25.000 € di reddito, 5.000 € di risparmio (20%),
        // 75.000 € di patrimonio, con una polizza e senza previdenza complementare
        var d = DatiFamigliaCliente(eta: 40, redditoFamiliare: 25_000, risparmioAnnuo: 5_000, ricchezzaFinanziaria: 75_000,
                                    haProtezione: true, premiProtezione: 300, haPrevidenzaComplementare: false, contributiPrevidenza: 0)
        let c = MotoreFamiglie.confronta(d, tabelle: t)
        verifica.vero("F6 Avviso «dati di prova»", c.diProva && c.avvisi.contains(TestiFamiglie.avvisoDiProva))
        verifica.vero("F6 Le quattro voci del file nell'ordine",
                      c.voci == [.tassoRisparmio, .ricchezzaFinanziaria, .protezione, .previdenzaComplementare] && !c.unaDimensione)
        verifica("F6 Tasso di risparmio 20% → 50", Double(c.voce(.tassoRisparmio)?.percentile ?? -1), 50)
        verifica("F6 Patrimonio 75.000 → 62", Double(c.voce(.ricchezzaFinanziaria)?.percentile ?? -1), 62)
        verifica.vero("F6 Protezione con la quota: ha la polizza, 75 sulla barra, nessun percentile",
                      c.voce(.protezione)?.metodo == .quota && c.voce(.protezione)?.sopra == true
                      && c.voce(.protezione)?.barra?.cliente == 75 && c.voce(.protezione)?.percentile == nil)
        verifica("F6 Previdenza senza adesione: 25 sulla barra", c.voce(.previdenzaComplementare)?.barra?.cliente ?? -1, 25)
        verifica("F6 Quota 50%: la tacca a 50", c.voce(.previdenzaComplementare)?.barra?.tacca ?? -1, 50)
        verifica.vero("F6 Cella con 100 famiglie: niente cautela del campione",
                      !c.campioneRidotto && c.famiglieNellaCella == 100 && (c.voce(.tassoRisparmio)?.cautele.isEmpty ?? false))

        // F7. Campione piccolo: la prima cella del file ha 10 famiglie (sotto la soglia di 30)
        let piccola = MotoreFamiglie.confronta(DatiFamigliaCliente(eta: 30, redditoFamiliare: 5_000, risparmioAnnuo: 500), tabelle: t)
        verifica.vero("F7 Campione ridotto con la cautela", piccola.campioneRidotto
                      && (piccola.voce(.tassoRisparmio)?.cautele.contains(TestiFamiglie.pocheFamiglie(10)) ?? false))

        // F8. Dati mancanti: senza età nessuna voce; senza risparmio solo quella voce resta senza confronto
        let senzaEta = MotoreFamiglie.confronta(DatiFamigliaCliente(redditoFamiliare: 25_000), tabelle: t)
        verifica.vero("F8 Senza età: nessun confronto e l'avviso",
                      senzaEta.gruppi.isEmpty && !senzaEta.haConfronto && senzaEta.avvisi.contains(TestiFamiglie.servonoEtaReddito))
        d.risparmioAnnuo = nil
        let senzaRisparmio = MotoreFamiglie.confronta(d, tabelle: t)
        verifica.vero("F8 Senza risparmio: la voce dice che cosa manca",
                      senzaRisparmio.voce(.tassoRisparmio)?.metodo == .nessuno
                      && senzaRisparmio.voce(.tassoRisparmio)?.frase == TestiFamiglie.manca(.tassoRisparmio)
                      && senzaRisparmio.voce(.ricchezzaFinanziaria)?.metodo == .quantili)
        let fuori = MotoreFamiglie.confronta(DatiFamigliaCliente(eta: 40, redditoFamiliare: .nan), tabelle: t)
        verifica.vero("F8 Reddito non finito: nessuna cella, nessun crash", fuori.classeReddito == nil && fuori.gruppi.isEmpty)

        // F9. Solo mediana o solo media (fonti che non danno i quantili); premi senza quota con i quantili
        let soloMediana = MotoreFamiglie.confrontaVoce(.ricchezzaFinanziaria, dati: DatiFamigliaCliente(ricchezzaFinanziaria: 2_000),
                                                       distribuzione: DistribuzioneFamiglie(p50: 1_000), cautele: [])
        verifica.vero("F9 Solo mediana: sopra, senza percentile, barra in valori",
                      soloMediana.metodo == .mediana && soloMediana.sopra == true && soloMediana.percentile == nil
                      && soloMediana.barra?.scala == .valori && soloMediana.riferimento == 1_000)
        let soloMedia = MotoreFamiglie.confrontaVoce(.ricchezzaFinanziaria, dati: DatiFamigliaCliente(ricchezzaFinanziaria: 500),
                                                     distribuzione: DistribuzioneFamiglie(media: 1_000), cautele: [])
        verifica.vero("F9 Solo media: sotto", soloMedia.metodo == .media && soloMedia.sopra == false
                      && soloMedia.frase == "Ha meno patrimonio finanziario di una famiglia media come la sua.")
        let premi = MotoreFamiglie.confrontaVoce(.protezione, dati: DatiFamigliaCliente(haProtezione: true, premiProtezione: 750),
                                                 distribuzione: DistribuzioneFamiglie(p50: 500, p75: 1_000), cautele: [])
        verifica("F9 Premi senza quota: percentile tra p50 e p75", Double(premi.percentile ?? -1), 62)

        // F10. Le cifre del cliente dai motori: reddito del cliente più i familiari, risparmio libero più versamenti
        var cliente = Cliente.nuovo(tinta: .blu)
        cliente.nome = "Prova Famiglie"
        cliente.dataNascita = AiutiProva.data(1980, 6, 15)
        cliente.profilo.redditoNettoAnnuo = 20_000
        cliente.profilo.risparmioAnnuo = 3_000
        cliente.famiglia = [Familiare(nome: "Partner", relazione: .coniuge, redditoNettoAnnuo: 10_000),
                            Familiare(nome: "Figlio", relazione: .figlio)]
        func sua(_ p: Posizione) -> Posizione { var q = p; q.clienteId = cliente.id; return q }
        let posizioni = [
            sua(AiutiProva.posizione("Conto", .liquidita, 10_000)),
            sua(AiutiProva.posizione("Piano", .investimento, 20_000) { $0.premio = 100; $0.frequenza = .mensile }),
            sua(AiutiProva.posizione("TCM", .protezione, 0) { $0.rischio = .vita; $0.premio = 30; $0.frequenza = .mensile }),
            sua(AiutiProva.posizione("Casa", .immobili, 300_000)),
            AiutiProva.posizione("Di un altro", .investimento, 99_000),
        ]
        let dc = MotoreFamiglie.dati(cliente: cliente, posizioni: posizioni, oggi: AiutiProva.data(2026, 11, 4))
        verifica("F10 Età al 4/11/2026", Double(dc.eta ?? -1), 46)
        verifica("F10 Reddito familiare: 20.000 + 10.000", dc.redditoFamiliare ?? -1, 30_000)
        verifica("F10 Risparmio: 3.000 liberi + 1.200 di versamenti", dc.risparmioAnnuo ?? -1, 4_200)
        verifica("F10 Patrimonio finanziario: conto e piano (non la casa, non le posizioni di altri)", dc.ricchezzaFinanziaria ?? -1, 30_000)
        verifica.vero("F10 Protezione in essere, nessuna previdenza complementare",
                      dc.haProtezione == true && dc.haPrevidenzaComplementare == false && !dc.risparmioSoloVersamenti)
        verifica("F10 Premi di protezione annui", dc.premiProtezione ?? -1, 360)
        verifica("F10 Ricchezza netta: conto, piano e casa (non la copertura, non le posizioni di altri)", dc.ricchezzaNetta ?? -1, 330_000)
        verifica.vero("F10 Polizza vita: la TCM caso morte conta", dc.haPolizzaVita == true)
        cliente.profilo.redditoNettoAnnuo = nil
        cliente.profilo.risparmioAnnuo = nil
        let parziale = MotoreFamiglie.dati(cliente: cliente, posizioni: posizioni, oggi: AiutiProva.data(2026, 11, 4))
        verifica.vero("F10 Senza il reddito del cliente: solo i familiari, con la cautela",
                      parziale.redditoFamiliare == 10_000 && parziale.redditoSoloFamiliari)
        verifica.vero("F10 Senza risparmio libero: solo i versamenti, con la cautela",
                      parziale.risparmioAnnuo == 1_200 && parziale.risparmioSoloVersamenti)
        let vuoto = MotoreFamiglie.dati(cliente: Cliente.nuovo(tinta: .rosa), posizioni: [], oggi: AiutiProva.data(2026, 11, 4))
        verifica.vero("F10 Cliente vuoto: età, reddito, risparmio e patrimonio mancanti",
                      vuoto.eta == nil && vuoto.redditoFamiliare == nil && vuoto.risparmioAnnuo == nil && vuoto.ricchezzaFinanziaria == nil)

        // F11. Validazione del file: ogni errore dice il campo giusto
        validazione(verifica)
    }

    /// Modifica il file di prova e controlla l'errore.
    private static func validazione(_ verifica: VerificaCalcoli) {
        guard let url = Risorse.cartella?.appendingPathComponent(TabelleFamiglie.fileDiProva),
              let dati = try? Data(contentsOf: url),
              let radice = (try? JSONSerialization.jsonObject(with: dati)) as? [String: Any] else {
            verifica.vero("F11 File di prova leggibile come JSON", false)
            return
        }
        func errore(_ modifica: (inout [String: Any]) -> Void) -> ErroreTabelleFamiglie? {
            var r = radice
            modifica(&r)
            guard let d = try? JSONSerialization.data(withJSONObject: r) else { return nil }
            do {
                _ = try TabelleFamiglie.leggi(d)
                return nil
            } catch let e as ErroreTabelleFamiglie {
                return e
            } catch {
                return nil
            }
        }
        func cella(_ r: inout [String: Any], _ i: Int, _ modifica: (inout [String: Any]) -> Void) {
            guard var celle = r["celle"] as? [[String: Any]], i < celle.count else { return }
            modifica(&celle[i])
            r["celle"] = celle
        }
        verifica.vero("F11 Il file di prova passa la validazione", errore { _ in } == nil)
        verifica.vero("F11 Formato sconosciuto", errore { $0["formato"] = "altro" }?.campo == "formato")
        verifica.vero("F11 Versione sconosciuta", errore { $0["versione"] = 3 }?.campo == "versione")
        verifica.vero("F11 Versione 2 senza gruppi: campo mancante", errore { $0["versione"] = 2 }?.campo == "gruppi")
        verifica.vero("F11 Quantili non crescenti", errore { r in
            cella(&r, 0) { $0["ricchezzaFinanziaria"] = ["p10": 10_000, "p25": 5_000, "p50": 50_000] }
        }?.campo == "celle[0].ricchezzaFinanziaria.p25")
        verifica.vero("F11 Quota oltre 100", errore { r in cella(&r, 3) { $0["protezione"] = ["quota": 120] } }?.campo == "celle[3].protezione.quota")
        verifica.vero("F11 Famiglie a zero", errore { r in cella(&r, 2) { $0["famiglie"] = 0 } }?.campo == "celle[2].famiglie")
        verifica.vero("F11 Famiglie scritte a parole: campo e tipo", errore { r in cella(&r, 1) { $0["famiglie"] = "cento" } }?.campo.contains("famiglie") == true)
        verifica.vero("F11 Cella mancante", errore { r in
            if var celle = r["celle"] as? [[String: Any]] { celle.removeLast(); r["celle"] = celle }
        }?.campo == "celle")
        verifica.vero("F11 Cella doppia", errore { r in
            if var celle = r["celle"] as? [[String: Any]], let prima = celle.first { celle.append(prima); r["celle"] = celle }
        }?.motivo.contains("due volte") == true)
        verifica.vero("F11 Classi d'età sovrapposte", errore { r in
            if var classi = r["classiEta"] as? [[String: Any]] { classi[1]["da"] = 30; r["classiEta"] = classi }
        }?.campo == "classiEta[1].da")
        verifica.vero("F11 Buco tra le fasce di reddito", errore { r in
            if var classi = r["classiReddito"] as? [[String: Any]] { classi[2]["da"] = 25_000; r["classiReddito"] = classi }
        }?.motivo == TestiFamiglie.buco)
        verifica.vero("F11 Fonte mancante", errore { _ = $0.removeValue(forKey: "fonte") }?.campo == "fonte")
        let rotto = (try? TabelleFamiglie.leggi(Data("non è JSON".utf8))) == nil
        verifica.vero("F11 Testo che non è JSON: errore", rotto)
    }

    // MARK: - Le tavole della Banca d'Italia (versione 2)

    /// B1-B10: le tavole pubblicate incluse nell'app. Le cifre attese sono quelle delle tavole (edizione 2022,
    /// aggiornamento ottobre 2025), lette a mano dagli xlsx della Banca d'Italia.
    private static func tavoleBancaItalia(_ verifica: VerificaCalcoli) {
        // B1. Il file incluso si legge ed è dichiarato per quello che è
        guard let t = TabelleFamiglie.tabellePredefinite else {
            verifica.vero("B1 Tavole della Banca d'Italia leggibili", false)
            return
        }
        verifica.vero("B1 Versione 2, non di prova, fonte ed edizione",
                      t.versione == 2 && t.unaDimensione && !t.diProva && t.fonte.contains("Banca d'Italia")
                      && t.fonte.contains("edizione 2022") && t.edizione == 2022 && t.aggiornamento == "ottobre 2025")
        verifica.vero("B1 Gruppi età, quinto di reddito e tutte",
                      t.gruppo(.eta)?.classi.count == 5 && t.gruppo(.reddito)?.classi.count == 5 && t.gruppo(.tutte)?.classi.count == 1)

        // B2. Le cifre vere, a campione, contro le tavole
        func valore(_ d: DimensioneFamiglie, _ classe: String, _ v: VoceFamiglie) -> ValoreFamiglie? {
            t.gruppo(d)?.classi.first { $0.id == classe }?.valore(v)
        }
        let r35 = valore(.eta, "eta-2", .tassoRisparmio)
        verifica("B2 T4, 35-44 anni: risparmio 100 − 71,3 = 28,7%", r35?.valore ?? -1, 28.7, tolleranza: 1e-9)
        verifica.vero("B2 T4: è un rapporto tra medie", r35?.statistica == .rapportoTraMedie && r35?.tavola == "T4")
        verifica("B2 T4, 1° quinto: risparmio 100 − 105,2 = −5,2%", valore(.reddito, "quinto-1", .tassoRisparmio)?.valore ?? 0, -5.2, tolleranza: 1e-9)
        verifica("B2 T4, 5° quinto: risparmio 100 − 55,2 = 44,8%", valore(.reddito, "quinto-5", .tassoRisparmio)?.valore ?? 0, 44.8, tolleranza: 1e-9)
        verifica("B2 T17, 35-44 anni: attività finanziarie mediane 8.500 €", valore(.eta, "eta-2", .ricchezzaFinanziaria)?.valore ?? -1, 8_500)
        verifica("B2 T17, 5° quinto: ricchezza netta mediana 388.800 €", valore(.reddito, "quinto-5", .ricchezzaNetta)?.valore ?? -1, 388_800)
        verifica("B2 T23, 55-64 anni: polizze vita 17,3%", valore(.eta, "eta-4", .protezione)?.valore ?? -1, 17.3, tolleranza: 1e-9)
        verifica("B2 T23, 5° quinto: pensioni integrative 25,7%", valore(.reddito, "quinto-5", .previdenzaComplementare)?.valore ?? -1, 25.7, tolleranza: 1e-9)
        verifica.vero("B2 T17 mediana, T23 quota", valore(.eta, "eta-1", .ricchezzaNetta)?.statistica == .mediana
                      && valore(.eta, "eta-1", .protezione)?.statistica == .quota)
        let quinti = t.gruppo(.reddito)?.classi ?? []
        verifica.vero("B2 T7: estremi dei quinti 17.809 · 26.005 · 35.594 · 51.543 €",
                      quinti.map(\.a) == [17_809, 26_005, 35_594, 51_543, nil] && quinti.map(\.da) == [nil, 17_809, 26_005, 35_594, 51_543])
        verifica("B2 T29: famiglie intervistate con capofamiglia di 35-44 anni", Double(t.gruppo(.eta)?.classi[1].famiglie ?? -1), 860)
        let decimi = t.gruppo(.tutte)?.classi.first?.valore(.ricchezzaNetta)
        verifica.vero("B2 T15: decimi della ricchezza netta (2.200 … 152.051 … 545.150 €)",
                      decimi?.statistica == .quantili && decimi?.quantili?.p10 == 2_200 && decimi?.quantili?.p50 == 152_051
                      && decimi?.quantili?.p90 == 545_150 && decimi?.quantili?.quantili.count == 9)

        // B3. Classi sui bordi: età con estremi inclusi, quinti con «a» escluso
        verifica.vero("B3 44 anni nella classe 35-44", MotoreFamiglie.classeEta(44, in: t)?.id == "eta-2")
        verifica.vero("B3 45 anni nella classe 45-54", MotoreFamiglie.classeEta(45, in: t)?.id == "eta-3")
        verifica.vero("B3 65 anni nell'ultima", MotoreFamiglie.classeEta(65, in: t)?.id == "eta-5")
        verifica.vero("B3 35.593 € nel 3° quinto", MotoreFamiglie.classeReddito(35_593, in: t)?.id == "quinto-3")
        verifica.vero("B3 35.594 € nel 4° quinto («a» escluso)", MotoreFamiglie.classeReddito(35_594, in: t)?.id == "quinto-4")
        verifica.vero("B3 17.808 € nel 1° quinto, 51.543 € nel 5°", MotoreFamiglie.classeReddito(17_808, in: t)?.id == "quinto-1"
                      && MotoreFamiglie.classeReddito(51_543, in: t)?.id == "quinto-5")

        // B4. Il confronto doppio: 40 anni (35-44), 30.000 € di reddito (3° quinto), 4.500 € di risparmio (15%),
        // 30.000 € di attività finanziarie, 160.000 € di ricchezza netta, una polizza vita, nessuna pensione integrativa
        let d = DatiFamigliaCliente(eta: 40, redditoFamiliare: 30_000, risparmioAnnuo: 4_500, ricchezzaFinanziaria: 30_000,
                                    haProtezione: true, premiProtezione: 400, haPrevidenzaComplementare: false,
                                    contributiPrevidenza: 0, ricchezzaNetta: 160_000, haPolizzaVita: true)
        let c = MotoreFamiglie.confronta(d, tabelle: t)
        verifica.vero("B4 Tre gruppi: età, quinto, tutte", c.gruppi.map(\.ambito) == [.eta, .reddito, .tutte]
                      && c.classeEta?.id == "eta-2" && c.classeReddito?.id == "quinto-3" && c.haConfronto && c.unaDimensione)
        verifica.vero("B4 Cinque voci", c.voci == VoceFamiglie.allCases && !c.diProva)
        let rEta = c.voce(.tassoRisparmio, ambito: .eta)
        verifica.vero("B4 Risparmio e famiglie della sua età: rapporto tra medie, sotto, nessun percentile",
                      rEta?.metodo == .rapportoMedie && rEta?.riferimento == 28.7 && rEta?.sopra == false && rEta?.percentile == nil
                      && rEta?.cautele.contains(TestiFamiglie.rapportoTraMedie(.tassoRisparmio)) == true)
        verifica.vero("B4 Frase del risparmio, età",
                      rEta?.frase == "Con il 15,0% del reddito risparmiato sta sotto la media delle famiglie della sua età (28,7%).")
        verifica.vero("B4 Risparmio e famiglie del 3° quinto: 24,0%, sotto",
                      c.voce(.tassoRisparmio, ambito: .reddito)?.riferimento == 24.0 && c.voce(.tassoRisparmio, ambito: .reddito)?.sopra == false)
        verifica("B4 Barra in valori: la media del gruppo a metà", rEta?.barra?.tacca ?? -1, 50)
        verifica("B4 Barra in valori: il cliente a 15 ÷ 57,4", rEta?.barra?.cliente ?? -1, 15 / 57.4 * 100)
        let fEta = c.voce(.ricchezzaFinanziaria, ambito: .eta)
        verifica.vero("B4 Attività finanziarie: sopra la mediana di 8.500 €",
                      fEta?.metodo == .mediana && fEta?.sopra == true && fEta?.percentile == nil
                      && fEta?.frase == "Con 30.000\u{00A0}€ di attività finanziarie sta sopra almeno metà delle famiglie della sua età (mediana 8.500\u{00A0}€).")
        verifica.vero("B4 Ricchezza netta: sopra la mediana della sua età (114.000 €), sotto quella del 3° quinto (161.757 €)",
                      c.voce(.ricchezzaNetta, ambito: .eta)?.sopra == true && c.voce(.ricchezzaNetta, ambito: .reddito)?.sopra == false
                      && c.voce(.ricchezzaNetta, ambito: .reddito)?.riferimento == 161_757)
        let nTutte = c.voce(.ricchezzaNetta, ambito: .tutte)
        verifica("B4 Ricchezza netta fra tutte le famiglie: 160.000 € tra p50 e p60 → 51", Double(nTutte?.percentile ?? -1), 51)
        verifica.vero("B4 Decimi: frase «in Italia» e la cautela della distribuzione complessiva",
                      nTutte?.metodo == .quantili && nTutte?.frase == "Ha più ricchezza netta di circa 5 famiglie su 10 in Italia."
                      && nTutte?.cautele.contains(TestiFamiglie.distribuzioneComplessiva) == true && nTutte?.barra?.parteCentrale == 10...90)
        let vita = c.voce(.protezione, ambito: .eta)
        verifica.vero("B4 Polizze vita della sua età: 20,0%, ha la polizza, la frase dice che i danni non ci sono",
                      vita?.metodo == .quota && vita?.sopra == true && vita?.percentile == nil
                      && vita?.frase == "Ha una polizza vita, come il 20,0% delle famiglie della sua età. Le tavole non contano le polizze danni.")
        verifica("B4 Polizze vita: avatar a metà di chi ce l'ha (100 − 20 ÷ 2)", vita?.barra?.cliente ?? -1, 90)
        verifica("B4 Polizze vita: tacca a 80", vita?.barra?.tacca ?? -1, 80)
        let integrativa = c.voce(.previdenzaComplementare, ambito: .reddito)
        verifica.vero("B4 Pensioni integrative del 3° quinto: 8,7%, non aderisce, «l'8,7%»",
                      integrativa?.sopra == false
                      && integrativa?.frase == "Non aderisce a una pensione integrativa; lo fa l'8,7% delle famiglie del suo quinto di reddito.")
        verifica("B4 Pensioni integrative: avatar a metà di chi non aderisce", integrativa?.barra?.cliente ?? -1, (100 - 8.7) / 2)
        verifica.vero("B4 Avvisi: quinti del 2022 e capofamiglia",
                      c.avvisi.contains(TestiFamiglie.sogliePerAnno(2022)) && c.avvisi.contains(TestiFamiglie.capofamiglia))

        // B5. La protezione conta solo le polizze vita: una copertura danni da sola non basta
        var soloDanni = d
        soloDanni.haPolizzaVita = false
        let danni = MotoreFamiglie.confronta(soloDanni, tabelle: t).voce(.protezione, ambito: .eta)
        verifica.vero("B5 Solo danni: «Non ha polizze vita registrate»", danni?.sopra == false
                      && danni?.frase == "Non ha polizze vita registrate; ce l'ha il 20,0% delle famiglie della sua età. Le tavole non contano le polizze danni.")

        // B6. La frase grande: il risparmio del gruppo che si conta, il cliente accanto
        let grande = TestiFamiglie.fraseGrandeValore(nome: "Giulia", ambito: .eta, metodo: .rapportoMedie, gruppo: 28.7, cliente: 15)
        verifica.vero("B6 Frase grande con l'età",
                      grande.prima + TestiFamiglie.formatoTasso.testo(grande.numero) + grande.dopo
                      == "Le famiglie con capofamiglia della sua età risparmiano in media il 28,7% del reddito; Giulia il 15,0%.")
        let grandeQuinto = TestiFamiglie.fraseGrandeValore(nome: "Marco", ambito: .reddito, metodo: .rapportoMedie, gruppo: -5.2, cliente: 8)
        verifica.vero("B6 Frase grande con il quinto, risparmio negativo e «l'8,0%»",
                      grandeQuinto.prima + TestiFamiglie.formatoTasso.testo(grandeQuinto.numero) + grandeQuinto.dopo
                      == "Le famiglie del suo quinto di reddito risparmiano in media il \(Formati.meno)5,2% del reddito; Marco l'8,0%.")

        // B7. Età o reddito mancanti: resta l'altro confronto; senza tutti e due nessun confronto
        let senzaEta = MotoreFamiglie.confronta(DatiFamigliaCliente(redditoFamiliare: 60_000, risparmioAnnuo: 12_000), tabelle: t)
        verifica.vero("B7 Senza età: solo il 5° quinto (e tutte), con l'avviso",
                      senzaEta.gruppi.map(\.ambito) == [.reddito, .tutte] && senzaEta.haConfronto
                      && senzaEta.classeReddito?.id == "quinto-5" && senzaEta.avvisi.contains(TestiFamiglie.mancaEta)
                      && senzaEta.voce(.tassoRisparmio, ambito: .reddito)?.sopra == false)
        let senzaReddito = MotoreFamiglie.confronta(DatiFamigliaCliente(eta: 70), tabelle: t)
        verifica.vero("B7 Senza reddito: solo l'età (65 e più), senza quinti del 2022",
                      senzaReddito.gruppi.first?.ambito == .eta && senzaReddito.avvisi.contains(TestiFamiglie.mancaReddito)
                      && !senzaReddito.avvisi.contains(TestiFamiglie.sogliePerAnno(2022))
                      && senzaReddito.voce(.tassoRisparmio, ambito: .eta)?.frase == TestiFamiglie.manca(.tassoRisparmio)
                      && senzaReddito.voce(.tassoRisparmio, ambito: .eta)?.riferimento == 31.8)
        let niente = MotoreFamiglie.confronta(DatiFamigliaCliente(), tabelle: t)
        verifica.vero("B7 Senza età né reddito: nessun confronto", !niente.haConfronto
                      && niente.avvisi.contains(TestiFamiglie.servonoEtaReddito))

        // B8. La barra in valori (nessun percentile): scala e bordi
        let s1 = MotoreFamiglie.scalaValori(cliente: 30_000, gruppo: 8_500)
        verifica("B8 30.000 contro 8.500: tacca a 8.500 ÷ 34.500", s1.tacca, 8_500 / 34_500 * 100)
        verifica("B8 30.000 contro 8.500: cliente a 30.000 ÷ 34.500", s1.cliente ?? -1, 30_000 / 34_500 * 100)
        let s2 = MotoreFamiglie.scalaValori(cliente: nil, gruppo: 28.7)
        verifica.vero("B8 Senza cliente: tacca a metà, nessun avatar", s2.cliente == nil && abs(s2.tacca - 50) < 1e-9)
        let s3 = MotoreFamiglie.scalaValori(cliente: 15, gruppo: -5.2)
        verifica.vero("B8 Gruppo negativo: dentro la barra, tacca a sinistra del cliente",
                      s3.tacca > 0 && s3.tacca < 15 && (s3.cliente ?? 0) > s3.tacca && (s3.cliente ?? 101) < 100)

        // B9. Articoli davanti alle percentuali
        verifica.vero("B9 il 20,0% · l'8,7% · l'11,2% · l'1,5% · il 17,0% · l'80,5%",
                      TestiFamiglie.ilPercentuale(20) == "il 20,0%" && TestiFamiglie.ilPercentuale(8.7) == "l'8,7%"
                      && TestiFamiglie.ilPercentuale(11.2) == "l'11,2%" && TestiFamiglie.ilPercentuale(1.5) == "l'1,5%"
                      && TestiFamiglie.ilPercentuale(17) == "il 17,0%" && TestiFamiglie.ilPercentuale(80.5) == "l'80,5%")

        // B10. Validazione della versione 2: ogni errore dice il campo giusto
        validazioneGruppi(verifica)
    }

    /// Modifica il file della Banca d'Italia e controlla l'errore.
    private static func validazioneGruppi(_ verifica: VerificaCalcoli) {
        guard let url = Risorse.cartella?.appendingPathComponent(TabelleFamiglie.filePredefinito),
              let dati = try? Data(contentsOf: url),
              let radice = (try? JSONSerialization.jsonObject(with: dati)) as? [String: Any] else {
            verifica.vero("B10 File della Banca d'Italia leggibile come JSON", false)
            return
        }
        func errore(_ modifica: (inout [String: Any]) -> Void) -> ErroreTabelleFamiglie? {
            var r = radice
            modifica(&r)
            guard let d = try? JSONSerialization.data(withJSONObject: r) else { return nil }
            do {
                _ = try TabelleFamiglie.leggi(d)
                return nil
            } catch let e as ErroreTabelleFamiglie {
                return e
            } catch {
                return nil
            }
        }
        /// Modifica la classe `k` del gruppo `g`.
        func classe(_ r: inout [String: Any], _ g: Int, _ k: Int, _ modifica: (inout [String: Any]) -> Void) {
            guard var gruppi = r["gruppi"] as? [[String: Any]], g < gruppi.count,
                  var classi = gruppi[g]["classi"] as? [[String: Any]], k < classi.count else { return }
            modifica(&classi[k])
            gruppi[g]["classi"] = classi
            r["gruppi"] = gruppi
        }
        func voce(_ r: inout [String: Any], _ g: Int, _ k: Int, _ nome: String, _ valore: Any) {
            classe(&r, g, k) { c in
                var voci = (c["voci"] as? [String: Any]) ?? [:]
                voci[nome] = valore
                c["voci"] = voci
            }
        }
        verifica.vero("B10 Il file della Banca d'Italia passa la validazione", errore { _ in } == nil)
        verifica.vero("B10 Quota oltre 100", errore { r in
            voce(&r, 0, 1, "protezione", ["statistica": "quota", "valore": 120])
        }?.campo == "gruppi[0].classi[1].voci.protezione.valore")
        verifica.vero("B10 Quota sul risparmio: non vale", errore { r in
            voce(&r, 0, 0, "tassoRisparmio", ["statistica": "quota", "valore": 20])
        }?.campo == "gruppi[0].classi[0].voci.tassoRisparmio.statistica")
        verifica.vero("B10 Voce sconosciuta", errore { r in
            voce(&r, 1, 2, "polizzeDanni", ["statistica": "quota", "valore": 10])
        }?.campo == "gruppi[1].classi[2].voci.polizzeDanni")
        verifica.vero("B10 Statistica sconosciuta: campo e motivo", errore { r in
            voce(&r, 1, 0, "ricchezzaNetta", ["statistica": "moda", "valore": 10])
        }.map { $0.campo.contains("statistica") && $0.motivo == TestiFamiglie.valoreSconosciuto } == true)
        verifica.vero("B10 Valore mancante", errore { r in
            voce(&r, 0, 3, "ricchezzaFinanziaria", ["statistica": "mediana"])
        }?.campo == "gruppi[0].classi[3].voci.ricchezzaFinanziaria.valore")
        verifica.vero("B10 Decimi decrescenti", errore { r in
            voce(&r, 2, 0, "ricchezzaNetta", ["statistica": "quantili", "quantili": ["p10": 5_000, "p20": 1_000]])
        }?.campo == "gruppi[2].classi[0].voci.ricchezzaNetta.quantili.p20")
        verifica.vero("B10 Quinti con un buco", errore { r in classe(&r, 1, 2) { $0["da"] = 27_000 } }?.motivo == TestiFamiglie.buco)
        verifica.vero("B10 Due gruppi per l'età", errore { r in
            if var gruppi = r["gruppi"] as? [[String: Any]] { gruppi[1]["dimensione"] = "eta"; r["gruppi"] = gruppi }
        }?.campo == "gruppi[1].dimensione")
        verifica.vero("B10 Tutte le famiglie con due classi", errore { r in
            if var gruppi = r["gruppi"] as? [[String: Any]], var classi = gruppi[2]["classi"] as? [[String: Any]], let prima = classi.first {
                classi.append(prima)
                gruppi[2]["classi"] = classi
                r["gruppi"] = gruppi
            }
        }?.campo == "gruppi[2].classi")
        verifica.vero("B10 Famiglie a zero", errore { r in classe(&r, 0, 4) { $0["famiglie"] = 0 } }?.campo == "gruppi[0].classi[4].famiglie")
    }
}
