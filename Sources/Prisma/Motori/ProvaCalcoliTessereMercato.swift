import Foundation

/// Prove delle tessere e dell'occhiello di Mercato (giro 7, TessereMercato.swift; Design/template-novita-specifica.md
/// §12.5.5 punti 1-3 e 8), chiamate da `ProvaCalcoli.esegui()` dopo `ProvaCalcoliMercato`. Niente rete. Cifre
/// dimostrative del template, nomi e ISIN di prova; oggi fisso al 2 novembre 2026.
enum ProvaCalcoliTessereMercato {
    private static let cal = Calendar.current
    private static let oggi = AiutiProva.data(2026, 11, 2)

    static func esegui(_ verifica: VerificaCalcoli) {
        tessere(verifica)
        linea(verifica)
        striscia(verifica)
        occhiello(verifica)
        frasi(verifica)
        datiDiProva(verifica)
    }

    /// Una serie mensile con i valori dati, l'ultimo a ottobre 2026.
    private static func mensile(_ id: String, _ tipo: TipoSerieMercato, _ unita: UnitaMercato, _ valori: [Double]) -> SerieMercato {
        let punti = valori.enumerated().map { i, v -> PuntoMercato in
            let d = cal.date(byAdding: .month, value: i - valori.count + 1, to: AiutiProva.data(2026, 10, 1)) ?? oggi
            return PuntoMercato(data: d, valore: v)
        }
        return SerieMercato(id: id, nome: id, origine: .aMano, fonte: "Dati di prova", unita: unita, tipo: tipo, frequenza: .mensile,
                            punti: punti, aggiornataIl: oggi)
    }

    // MARK: - 1 e 3. Tessere e formati

    private static func tessere(_ verifica: VerificaCalcoli) {
        let italia = MotoreMercato.tessera(mensile("azioni-italia", .indiceAzionario, .punti, [33_976, 34_180]), oggi: oggi)
        verifica.vero("Mercato tessere: «34.180» senza decimali", italia.valoreTesto == "34.180")
        verifica.vero("Mercato tessere: 34.180 su 33.976 dà «+0,6%»", italia.variazioneTesto == "+0,6%")
        verifica.vero("Mercato tessere: indice in salita, tono buono", italia.tono == .buono)
        let mondo = MotoreMercato.tessera(mensile("azioni-mondo", .indiceAzionario, .punti, [3_780, 3_712]), oggi: oggi)
        verifica.vero("Mercato tessere: 3.712 su 3.780 dà «−1,8%» col meno tipografico", mondo.variazioneTesto == "\u{2212}1,8%")
        verifica.vero("Mercato tessere: indice in discesa, tono cattivo", mondo.tono == .cattivo)
        let btp = MotoreMercato.tessera(mensile("btp", .rendimentoStato, .percentuale, [3.27, 3.42]), oggi: oggi)
        verifica.vero("Mercato tessere: «3,42%»", btp.valoreTesto == "3,42%")
        verifica.vero("Mercato tessere: BTP 3,27 → 3,42 dà «+0,15» (punti)", btp.variazioneTesto == "+0,15")
        verifica.vero("Mercato tessere: rendimento in salita, tono cattivo", btp.tono == .cattivo)
        let euribor = MotoreMercato.tessera(mensile("euribor", .tassoInterbancario, .percentuale, [2.10, 2.08]), oggi: oggi)
        verifica.vero("Mercato tessere: Euribor 2,10 → 2,08 dà «−0,02» e tono buono",
                      euribor.variazioneTesto == "\u{2212}0,02" && euribor.tono == .buono)
        let inflazione = MotoreMercato.tessera(mensile("inflazione", .inflazione, .percentuale, [1.8, 1.6]), oggi: oggi)
        verifica.vero("Mercato tessere: inflazione «1,6%» con un decimale e «−0,2»",
                      inflazione.valoreTesto == "1,6%" && inflazione.variazioneTesto == "\u{2212}0,2" && inflazione.tono == .buono)
        // Tasso BCE: fermo da più di un mese → invariato e neutro (variazione sul valore in vigore un mese prima)
        let bce = SerieMercato(id: "bce", nome: "bce", origine: .aMano, fonte: "Dati di prova", unita: .percentuale, tipo: .tassoUfficiale,
                               frequenza: .giornaliera,
                               punti: [PuntoMercato(data: AiutiProva.data(2025, 6, 11), valore: 2.25),
                                       PuntoMercato(data: AiutiProva.data(2026, 6, 11), valore: 2)],
                               aggiornataIl: oggi)
        let t = MotoreMercato.tessera(bce, oggi: oggi)
        verifica.vero("Mercato tessere: BCE 2,00 → 2,00 «invariato», tono neutro", t.variazioneTesto == "invariato" && t.tono == .neutro)
        verifica.vero("Mercato tessere: BCE recente se scaricato da poco (vale finché non cambia)", t.freschezza == .recente)
        verifica.vero("Mercato tessere: BCE «dall'11 giugno 2026»", t.dataTesto == "dall'11 giugno 2026")
        // Sotto la soglia di rumore: invariato
        let ferma = MotoreMercato.tessera(mensile("ferma", .indiceAzionario, .punti, [10_000, 10_004]), oggi: oggi)
        verifica.vero("Mercato tessere: +0,04% sotto la soglia di rumore è «invariato»", ferma.variazioneTesto == "invariato" && ferma.tono == .neutro)
        // Un dato vecchio
        let vecchia = MotoreMercato.tessera(mensile("vecchia", .indiceAzionario, .punti, [1, 2]), oggi: AiutiProva.data(2027, 3, 1))
        verifica.vero("Mercato tessere: l'ultimo dato di ottobre a marzo è vecchio", vecchia.freschezza == .vecchia)
        // Senza valori
        let vuota = MotoreMercato.tessera(mensile("vuota", .indiceAzionario, .punti, []), oggi: oggi)
        verifica.vero("Mercato tessere: senza valori «—» e nessuna linea", vuota.senzaValore && vuota.valoreTesto == "—" && vuota.linea.isEmpty)
        // Quote in euro
        verifica.vero("Mercato tessere: quota «18,42 €»",
                      MotoreMercato.testoValore(18.42, unita: .euro, decimali: 2) == "18,42\u{00A0}€")
    }

    // MARK: - 2. Mini linea

    private static func linea(_ verifica: VerificaCalcoli) {
        let mondo = mensile("azioni-mondo", .indiceAzionario, .punti, [3_500, 3_560, 3_610, 3_580, 3_690, 3_760, 3_790, 3_780, 3_712])
        let l = MotoreMercato.linea(mondo, oggi: oggi)
        verifica("Mercato linea: 9 punti", Double(l.count), 9)
        verifica("Mercato linea: minimo 3.500 a 0", l.first ?? -1, 0)
        verifica("Mercato linea: massimo 3.790 a 1", l[6], 1)
        verifica("Mercato linea: 3.712 a (3.712 − 3.500) / 290", l.last ?? -1, 212.0 / 290.0, tolleranza: 0.0001)
        let lunga = mensile("lunga", .indiceAzionario, .punti, Array(repeating: 1, count: 14).enumerated().map { Double($0.offset) })
        verifica("Mercato linea: al massimo 9 punti (gli ultimi)", Double(MotoreMercato.linea(lunga, oggi: oggi).count), 9)
        let piatta = MotoreMercato.normalizza([2, 2, 2, 2])
        verifica.vero("Mercato linea: serie piatta in fondo, nessuna divisione per zero", piatta == [0, 0, 0, 0])
        verifica.vero("Mercato linea: un solo valore, nessuna linea", MotoreMercato.normalizza([5]).isEmpty)
        // Il tasso BCE giornaliero si legge alla fine di ognuno degli ultimi 9 mesi: una scala
        let bce = SerieMercato(id: "bce", nome: "bce", origine: .aMano, fonte: "x", unita: .percentuale, tipo: .tassoUfficiale,
                               frequenza: .giornaliera,
                               punti: [PuntoMercato(data: AiutiProva.data(2025, 1, 1), valore: 2.5),
                                       PuntoMercato(data: AiutiProva.data(2026, 6, 11), valore: 2)], aggiornataIl: oggi)
        let scala = MotoreMercato.linea(bce, oggi: oggi)
        verifica.vero("Mercato linea: il tasso BCE a scala su 9 mesi", scala.count == 9 && scala.first == 1 && scala.last == 0)
        // La serie lunga del dettaglio: x per data, chiusa a oggi per il tasso BCE
        let dettaglio = MotoreMercato.lineaLunga(bce, oggi: oggi)
        verifica.vero("Mercato dettaglio: la serie di 12 mesi parte dal valore in vigore e arriva a oggi",
                      dettaglio.map { $0.punti.first?.x == 0 && $0.punti.last?.x == 1 && $0.minimo == 2 && $0.massimo == 2.5 } == true)
    }

    // MARK: - La striscia

    private static func striscia(_ verifica: VerificaCalcoli) {
        let configurazione = ConfigurazioneMercato(serie: [
            .init(id: "bce", nome: "Tasso BCE", fonte: .bce, codice: "FM.D.U2.EUR.4F.KR.DFR.LEV", unita: .percentuale,
                  frequenza: .giornaliera, tipo: .tassoUfficiale),
            .init(id: "it", nome: "Italia", fonte: .bce, codice: "IRS.M.IT.L.L40.CI.0000.EUR.N.Z", unita: .percentuale,
                  frequenza: .mensile, tipo: .rendimentoStato),
            .init(id: "de", nome: "Germania", fonte: .bce, codice: "IRS.M.DE.L.L40.CI.0000.EUR.N.Z", unita: .percentuale,
                  frequenza: .mensile, tipo: .rendimentoStato),
            .init(id: "infl-bce", nome: "Inflazione BCE", fonte: .bce, codice: "ICP.M.IT.N.000000.4.ANR", unita: .percentuale,
                  frequenza: .mensile, tipo: .inflazione),
            .init(id: "stoxx", nome: "Euro Stoxx 50", fonte: .bce, codice: "FM.M.U2.EUR.DS.EI.DJES50I.HSTA", unita: .punti,
                  frequenza: .mensile, tipo: .indiceAzionario),
            .init(id: "infl", nome: "Inflazione", fonte: .eurostat, codice: "prc_hicp_manr", filtri: ["geo": "IT", "coicop": "CP00"],
                  unita: .percentuale, frequenza: .mensile, tipo: .inflazione),
        ], calcolate: [.init(id: "spread", nome: "Spread", da: "it", meno: "de", unita: .percentuale, tipo: .spread)])
        var archivio = ArchivioMercato()
        archivio.serie = [mensile("it", .rendimentoStato, .percentuale, [3.27, 3.42]), mensile("de", .rendimentoStato, .percentuale, [2.6, 2.68]),
                          mensile("infl", .inflazione, .percentuale, [1.8, 1.6]), mensile("stoxx", .indiceAzionario, .punti, [3_780, 3_712])]
        var acceso = ImpostazioniMercato()
        acceso.attivo = true
        let ids = MotoreMercato.tessere(archivio: archivio, configurazione: configurazione, impostazioni: acceso, oggi: oggi).map(\.id)
        verifica.vero("Mercato striscia: ordine del template (azioni, rendimento, spread, inflazione, BCE)",
                      ids == ["stoxx", "it", "spread", "infl", "bce"])
        verifica.vero("Mercato striscia: la Germania serve solo allo spread e non si mostra", !ids.contains("de"))
        verifica.vero("Mercato striscia: una sola inflazione, quella con i valori", !ids.contains("infl-bce"))
        let spento = MotoreMercato.tessere(archivio: archivio, configurazione: configurazione, impostazioni: ImpostazioniMercato(), oggi: oggi)
        verifica.vero("Mercato striscia: spento solo le serie che l'archivio ha già (niente «—» da scaricare)",
                      spento.allSatisfy { !$0.senzaValore } && !spento.contains { $0.id == "bce" })
        verifica.vero("Mercato striscia: archivio vuoto e spento, nessuna tessera",
                      MotoreMercato.tessere(archivio: ArchivioMercato(), configurazione: configurazione, impostazioni: ImpostazioniMercato(),
                                            oggi: oggi).isEmpty)
        // Dati vecchi
        let vecchie = MotoreMercato.tessere(archivio: archivio, configurazione: nil, impostazioni: ImpostazioniMercato(),
                                            oggi: AiutiProva.data(2027, 3, 1))
        verifica.vero("Mercato striscia: tutte vecchie → «dall'ultimo aggiornamento»", MotoreMercato.datiVecchi(vecchie))
        verifica.vero("Mercato striscia: fresche → «oggi»",
                      !MotoreMercato.datiVecchi(MotoreMercato.tessere(archivio: archivio, configurazione: nil,
                                                                      impostazioni: ImpostazioniMercato(), oggi: oggi)))
    }

    // MARK: - 8. Occhiello

    private static func occhiello(_ verifica: VerificaCalcoli) {
        let oggi18 = cal.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 18)) ?? oggi
        let ieri18 = cal.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 18)) ?? oggi
        let ottobre = cal.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 18)) ?? oggi
        let adesso = cal.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 19)) ?? oggi
        verifica.vero("Mercato occhiello: «Aggiornato oggi alle 18:00»",
                      MotoreMercato.occhiello(ultimo: oggi18, inCorso: false, datiDiProva: false, oggi: adesso, cal: cal) == "Aggiornato oggi alle 18:00")
        verifica.vero("Mercato occhiello: «Aggiornato ieri alle 18:00»",
                      MotoreMercato.occhiello(ultimo: ieri18, inCorso: false, datiDiProva: false, oggi: adesso, cal: cal) == "Aggiornato ieri alle 18:00")
        verifica.vero("Mercato occhiello: «Aggiornato il 28 ottobre»",
                      MotoreMercato.occhiello(ultimo: ottobre, inCorso: false, datiDiProva: false, oggi: adesso, cal: cal) == "Aggiornato il 28 ottobre")
        verifica.vero("Mercato occhiello: «Mai aggiornato»",
                      MotoreMercato.occhiello(ultimo: nil, inCorso: false, datiDiProva: false, oggi: adesso, cal: cal) == "Mai aggiornato")
        verifica.vero("Mercato occhiello: «· valori di prova» solo con i dati di prova",
                      MotoreMercato.occhiello(ultimo: oggi18, inCorso: false, datiDiProva: true, oggi: adesso, cal: cal)
                        == "Aggiornato oggi alle 18:00 · valori di prova")
        verifica.vero("Mercato occhiello: «Aggiornamento in corso…»",
                      MotoreMercato.occhiello(ultimo: oggi18, inCorso: true, datiDiProva: false, oggi: adesso, cal: cal) == "Aggiornamento in corso…")
        var a = ArchivioMercato()
        verifica.vero("Mercato occhiello: archivio vuoto, nessun arrivo", MotoreMercato.ultimoArrivo(a) == nil)
        a.quote = [QuotaISIN(isin: "ZZ0000000016", punti: [], fonte: "x", origine: .csv, importataIl: ottobre)]
        verifica.vero("Mercato occhiello: anche un'importazione è un arrivo", MotoreMercato.ultimoArrivo(a) == ottobre)
    }

    // MARK: - Frasi di «Chi è toccato» e quote

    private static func frasi(_ verifica: VerificaCalcoli) {
        verifica("Mercato circa: 2.980 → 3.000", MotoreMercato.circa(318_400 * 0.52 * 0.018), 3_000)
        verifica("Mercato circa: 640 → 640", MotoreMercato.circa(640), 640)
        verifica("Mercato circa: −12.345 → −12.000", MotoreMercato.circa(-12_345), -12_000)
        let t = ClienteToccato(clienteId: "marco", posizioni: ["a", "b"], impatto: -2_980,
                               perCanale: [.alleanza: -2_000, .indipendente: -980], canali: [.alleanza, .indipendente])
        let e = EventoMercato(id: "e", tipo: .variazioneSerie, titolo: "t", dettaglio: "d", valore: -1.8, soglia: 1, data: oggi,
                              fonte: "Fonte: BCE", serieId: nil, isin: nil, posizioneId: nil, toccati: [t])
        let frase = TestiAppMercato.fraseToccati(e, tipoSerie: .indiceAzionario, nomi: ["marco": "Marco Bianchi"])
        verifica.vero("Mercato frasi: «il portafoglio di Marco perde circa 3.000 €»", frase.contains("il portafoglio di Marco perde circa 3.000"))
        verifica.vero("Mercato frasi: i canali restano separati", frase.contains(Canale.alleanza.nomeBreve) && frase.contains(Canale.indipendente.nomeBreve))
        let btp = EventoMercato(id: "b", tipo: .variazioneSerie, titolo: "t", dettaglio: "d", valore: 0.15, soglia: 0.1, data: oggi,
                                fonte: "Fonte: BCE", serieId: nil, isin: nil, posizioneId: nil,
                                toccati: [ClienteToccato(clienteId: "sofia", posizioni: ["x"], impatto: nil, perCanale: [:], canali: [.alleanza])])
        verifica.vero("Mercato frasi: rendimenti in salita «il valore scende un po’, la cedola resta quella»",
                      TestiAppMercato.fraseToccati(btp, tipoSerie: .rendimentoStato, nomi: ["sofia": "Sofia Romano"]).contains("la cedola resta quella"))
        // Da inizio anno: 17,36 € a fine 2025, 18,42 € oggi → +6,1%
        let q = QuotaISIN(isin: "ZZ0000000016", punti: [PuntoMercato(data: AiutiProva.data(2025, 12, 31), valore: 17.36),
                                                         PuntoMercato(data: AiutiProva.data(2026, 10, 30), valore: 18.42)],
                          fonte: "x", origine: .csv, importataIl: oggi)
        verifica("Mercato quote: da inizio anno +6,1%", MotoreMercato.daInizioAnno(q, oggi: oggi) ?? 0, 6.106, tolleranza: 0.01)
    }

    // MARK: - I codici di prova delle istantanee

    private static func datiDiProva(_ verifica: VerificaCalcoli) {
        verifica.vero("Mercato prova: gli ISIN di prova superano la cifra di controllo",
                      [MercatoDiProva.isinFondo, MercatoDiProva.isinBTP, MercatoDiProva.isinSconosciuto].allSatisfy(MotoreMercato.isinValido))
        verifica.vero("Mercato prova: «LU0000000000» non la supera", !MotoreMercato.isinValido(MercatoDiProva.isinSbagliato))
        verifica.vero("Mercato prova: gli ISIN di prova non sono di nessun paese (ZZ)",
                      [MercatoDiProva.isinFondo, MercatoDiProva.isinBTP, MercatoDiProva.isinSconosciuto].allSatisfy { $0.hasPrefix("ZZ") })
    }
}
