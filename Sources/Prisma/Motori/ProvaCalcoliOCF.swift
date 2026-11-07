import Foundation

/// Prove dell'allenamento OCF (Studio › Esame OCF, Orizzonte giro 6): intervalli del ripasso (1, 3, 7, 14, 30 giorni,
/// sbagliata → 1 giorno, cambio d'ora), percentuali per materia e complessiva, domande di oggi, giorni all'esame,
/// importazione CSV e JSON con gli errori, domande di esempio, applicazione all'archivio e caso vero.
/// Chiamate da `ProvaCalcoli.esegui()`. Le domande qui sono di comodo, scritte per la prova.
enum ProvaCalcoliOCF {
    static func esegui(_ verifica: VerificaCalcoli) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        func giorno(_ a: Int, _ m: Int, _ g: Int, _ ora: Int = 10, _ minuti: Int = 0) -> Date {
            cal.date(from: DateComponents(year: a, month: m, day: g, hour: ora, minute: minuti)) ?? Date()
        }
        func stessoGiorno(_ x: Date?, _ y: Date) -> Bool { x.map { cal.isDate($0, inSameDayAs: y) } ?? false }
        func r(_ id: String, _ data: Date, _ giusta: Bool) -> RispostaOCF { RispostaOCF(domandaId: id, data: data, giusta: giusta) }

        // O1. Ripasso: sbagliata il 2/11 → 3/11; giusta il 3/11 → 6/11; 6/11 → 13/11; 13/11 → 27/11; 27/11 → 27/12;
        // al passo dei 30 giorni resta lì; sbagliata a qualunque passo → il giorno dopo
        var storia = [r("q", giorno(2026, 11, 2), false)]
        verifica.vero("O1 Sbagliata il 2/11 → torna il 3/11", stessoGiorno(MotoreOCF.ripasso("q", risposte: storia, cal: cal)?.prossima, giorno(2026, 11, 3)))
        storia.append(r("q", giorno(2026, 11, 3), true))
        verifica.vero("O1 Giusta il 3/11 → 6/11 (3 giorni)", stessoGiorno(MotoreOCF.ripasso("q", risposte: storia, cal: cal)?.prossima, giorno(2026, 11, 6)))
        storia.append(r("q", giorno(2026, 11, 6), true))
        verifica.vero("O1 Giusta il 6/11 → 13/11 (7 giorni)", stessoGiorno(MotoreOCF.ripasso("q", risposte: storia, cal: cal)?.prossima, giorno(2026, 11, 13)))
        storia.append(r("q", giorno(2026, 11, 13), true))
        verifica.vero("O1 Giusta il 13/11 → 27/11 (14 giorni)", stessoGiorno(MotoreOCF.ripasso("q", risposte: storia, cal: cal)?.prossima, giorno(2026, 11, 27)))
        storia.append(r("q", giorno(2026, 11, 27), true))
        let a30 = MotoreOCF.ripasso("q", risposte: storia, cal: cal)
        verifica.vero("O1 Giusta il 27/11 → 27/12 (30 giorni)", stessoGiorno(a30?.prossima, giorno(2026, 12, 27)) && a30?.giorni == 30)
        storia.append(r("q", giorno(2026, 12, 27), true))
        verifica.vero("O1 Al passo dei 30 giorni resta lì", MotoreOCF.ripasso("q", risposte: storia, cal: cal)?.giorni == 30)
        storia.append(r("q", giorno(2027, 1, 30), false))
        let reset = MotoreOCF.ripasso("q", risposte: storia, cal: cal)
        verifica.vero("O1 Sbagliata al passo 30 → torna il giorno dopo", stessoGiorno(reset?.prossima, giorno(2027, 1, 31)) && reset?.passo == 0)

        // O2. Giusta prima della data del ripasso: non sale. Nuova giusta al primo colpo: 3 giorni
        let presto = [r("p", giorno(2026, 11, 2), false), r("p", giorno(2026, 11, 3), true), r("p", giorno(2026, 11, 4), true)]
        verifica.vero("O2 Giusta prima della data: resta al passo dei 3 giorni",
                      MotoreOCF.ripasso("p", risposte: presto, cal: cal)?.giorni == 3
                      && stessoGiorno(MotoreOCF.ripasso("p", risposte: presto, cal: cal)?.prossima, giorno(2026, 11, 6)))
        let primoColpo = MotoreOCF.ripasso("n", risposte: [r("n", giorno(2026, 11, 2), true)], cal: cal)
        verifica.vero("O2 Nuova giusta al primo colpo → tra 3 giorni", primoColpo?.passo == 1 && stessoGiorno(primoColpo?.prossima, giorno(2026, 11, 5)))
        verifica.vero("O2 Senza risposte: nessun ripasso", MotoreOCF.ripasso("x", risposte: presto, cal: cal) == nil)

        // O3. Cambio d'ora: sbagliata sabato 24/10/2026 alle 23:30 → domenica 25/10, non il 26
        let notte = MotoreOCF.ripasso("o", risposte: [r("o", giorno(2026, 10, 24, 23, 30), false)], cal: cal)
        verifica.vero("O3 Cambio d'ora: torna il 25/10", stessoGiorno(notte?.prossima, giorno(2026, 10, 25)))

        // O4. Percentuali: ultima risposta di ogni domanda, minimo 5 domande per materia, media delle materie
        var a = ArchivioOCF()
        a.materie = [MateriaOCF(id: "m1", nome: "Prima"), MateriaOCF(id: "m2", nome: "Seconda"), MateriaOCF(id: "m3", nome: "Terza")]
        func domanda(_ id: String, _ m: String) -> DomandaOCF {
            DomandaOCF(id: id, materia: m, testo: "Domanda di prova \(id)", risposte: ["uno", "due", "tre", "quattro"], corretta: 0)
        }
        a.domande = (1...5).map { domanda("a\($0)", "m1") } + (1...5).map { domanda("b\($0)", "m2") } + (1...4).map { domanda("c\($0)", "m3") }
            + [domanda("nuova1", "m1"), domanda("nuova2", "m2"), domanda("nuova3", "m3")]
        let ieri = giorno(2026, 11, 3), oggi = giorno(2026, 11, 4)
        // m1: 4 giuste su 5 (a5 sbagliata, poi giusta: conta l'ultima); m2: 2 su 5; m3: solo 4 risposte → nil
        a.risposte = [r("a1", giorno(2026, 10, 20), true), r("a2", giorno(2026, 10, 20), true), r("a3", giorno(2026, 10, 20), true),
                      r("a4", giorno(2026, 10, 20), false), r("a5", giorno(2026, 10, 20), false), r("a5", giorno(2026, 10, 21), true),
                      r("b1", giorno(2026, 10, 20), true), r("b2", giorno(2026, 10, 20), true), r("b3", ieri, false),
                      r("b4", giorno(2026, 11, 3, 9), false), r("b5", oggi, false),
                      r("c1", giorno(2026, 10, 20), true), r("c2", giorno(2026, 10, 20), true), r("c3", giorno(2026, 10, 20), true),
                      r("c4", giorno(2026, 10, 20), true)]
        let prep = MotoreOCF.preparazione(a, oggi: oggi, cal: cal)
        verifica("O4 Prima materia: 4 su 5 (l'ultima risposta conta)", prep.materie.first?.percentuale ?? -1, 80)
        verifica("O4 Seconda materia: 2 su 5", prep.materie.dropFirst().first?.percentuale ?? -1, 40)
        verifica.vero("O4 Terza materia con 4 risposte: nessuna percentuale", prep.materie.last?.percentuale == nil && prep.materie.last?.risposte == 4)
        verifica("O4 Complessiva: media delle materie con un dato (80 e 40)", prep.complessiva ?? -1, 60)
        verifica.vero("O4 Punto debole: la seconda materia", prep.puntoDebole?.id == "m2")
        verifica("O4 Domande nuove disponibili", Double(prep.nuoveDisponibili), 3)
        verifica.vero("O4 Fasce: 70 verde, 69,9 arancio, 55 arancio, 54,9 rossa, nil nessuna",
                      MotoreOCF.fascia(70) == .verde && MotoreOCF.fascia(69.9) == .arancio && MotoreOCF.fascia(55) == .arancio
                      && MotoreOCF.fascia(54.9) == .rossa && MotoreOCF.fascia(nil) == .nessuna)

        // O5. Domande di oggi: ripasso scaduto prima (a4 del 20/10 è la più in ritardo), poi le nuove dalla materia più
        // debole; b5 sbagliata oggi torna domani e non c'è
        let oggiDomande = MotoreOCF.domandeDiOggi(a, oggi: oggi, cal: cal, nuove: 2)
        let ids = oggiDomande.map(\.id)
        verifica.vero("O5 Prima il ripasso più in ritardo (a4 dal 21/10)", ids.first == "a4")
        verifica.vero("O5 b3 e b4 sbagliate ieri tornano oggi", ids.contains("b3") && ids.contains("b4"))
        verifica.vero("O5 b5 sbagliata oggi torna domani: non c'è", !ids.contains("b5"))
        verifica.vero("O5 Poi due nuove: prima la materia senza dato, poi la più debole",
                      Array(ids.suffix(2)) == ["nuova3", "nuova2"])
        verifica("O5 Da ripassare oggi", Double(prep.daRipassareOggi), Double(ids.count - 2))

        // O6. Giorni all'esame: dal 3/11/2026 al 18/2/2027 sono 107; il giorno stesso 0
        var conEsame = a
        conEsame.dataEsame = giorno(2027, 2, 18, 9)
        verifica("O6 Giorni all'esame", Double(MotoreOCF.preparazione(conEsame, oggi: giorno(2026, 11, 3, 22), cal: cal).giorniAllEsame ?? -1), 107)
        verifica("O6 L'esame è oggi", Double(MotoreOCF.preparazione(conEsame, oggi: giorno(2027, 2, 18, 18), cal: cal).giorniAllEsame ?? -1), 0)

        importazione(verifica, archivio: a)
        casoVero(verifica)
    }

    // MARK: Importazione

    private static func importazione(_ verifica: VerificaCalcoli, archivio a: ArchivioOCF) {
        let adesso = AiutiProva.data(2026, 11, 4)
        // O7. CSV con BOM e «;», colonne in ordine libero, corretta «b» minuscola, materia per nome senza accenti,
        // una materia nuova, una riga con una risposta vuota, un caso sconosciuto ignorato, un id già presente cambiato
        let csv = "\u{FEFF}materia;domanda;corretta;a;b;c;d;spiegazione;caso;id\n"
            + "prima;Quanto fa due più due?;b;3;4;5;6;Somma semplice;gestione-separata;\n"
            + "Materia nuova;Una domanda nuova;A;sì;no;forse;mai;;viaggio sulla luna;\n"
            + "prima;Manca una risposta;c;uno;due;;quattro;;;\n"
            + "prima;Risposta corretta sbagliata;E;uno;due;tre;quattro;;;\n"
            + "m2;Testo cambiato della b1;1;uno;due;tre;quattro;;;b1\n"
            + "m2;Domanda di prova b2;1;uno;due;tre;quattro;;;b2\n"
        guard let i = try? ImportaOCF.leggi(Data(csv.utf8), nomeFile: "prova.csv", archivio: a, adesso: adesso) else {
            verifica.vero("O7 CSV di prova leggibile", false)
            return
        }
        verifica("O7 Due domande nuove", Double(i.nuove.count), 2)
        verifica.vero("O7 «b» minuscola → indice 1, materia trovata per nome", i.nuove.first?.corretta == 1 && i.nuove.first?.materia == "m1")
        verifica.vero("O7 Caso scritto con il trattino riconosciuto", i.nuove.first?.caso == .gestioneSeparata)
        verifica.vero("O7 Caso sconosciuto ignorato, la riga resta", i.nuove.last?.caso == nil && i.nuove.last?.testo == "Una domanda nuova")
        verifica.vero("O7 Materia nuova nel riepilogo", i.materieNuove.map(\.id) == ["materia-nuova"] && i.materieNuove.first?.nome == "Materia nuova")
        verifica.vero("O7 Righe scartate con il numero e il motivo",
                      i.scartate == [RigaScartataOCF(riga: 4, motivo: TestiOCF.mancaRisposta(2)),
                                     RigaScartataOCF(riga: 5, motivo: TestiOCF.correttaNonValida("E", daCSV: true))])
        verifica.vero("O7 Id già presente con testo diverso: aggiornata", i.aggiornate.map(\.id) == ["b1"])
        verifica("O7 Riga uguale a quella dell'archivio", Double(i.uguali), 1)
        verifica.vero("O7 Riepilogo leggibile", i.riepilogo.hasPrefix("2 domande nuove · 1 aggiornata · 1 uguale") && i.riepilogo.contains("riga 4 (manca la risposta C)"))
        verifica.vero("O7 Id ricavato dal contenuto, stabile", i.nuove.first?.id == ImportaOCF.impronta("m1", "Quanto fa due più due?"))
        // Applicata: lo storico resta, la domanda aggiornata cambia testo, la materia nuova entra
        var b = a
        b.applica(i)
        verifica.vero("O7 Applicata: domande, materia nuova e storico conservato",
                      b.domande.count == a.domande.count + 2 && b.materia("materia-nuova") != nil
                      && b.domanda("b1")?.testo == "Testo cambiato della b1" && b.risposte == a.risposte)
        // Reimportare lo stesso file non crea doppioni
        let di2 = try? ImportaOCF.leggi(Data(csv.utf8), nomeFile: "prova.csv", archivio: b, adesso: adesso)
        verifica.vero("O7 Reimportato: nessuna domanda nuova", di2?.nuove.isEmpty == true && di2?.aggiornate.isEmpty == true && di2?.uguali == 4)
        // Intestazione senza le colonne obbligatorie
        do {
            _ = try ImportaOCF.daCSV("materia;domanda;a;b\nprima;x;1;2\n", archivio: a)
            verifica.vero("O7 Colonne mancanti: errore", false)
        } catch let e as ErroreImportaOCF {
            verifica.vero("O7 Colonne mancanti: errore leggibile", e.messaggio == TestiOCF.mancanoColonne(["c", "d", "corretta"]))
        } catch {
            verifica.vero("O7 Colonne mancanti: errore leggibile", false)
        }

        // O8. JSON: formato e versione, corretta come indice o lettera, domande illeggibili scartate col numero
        func json(_ s: String) -> Result<ImportazioneOCF, ErroreImportaOCF> {
            do { return .success(try ImportaOCF.leggi(Data(s.utf8), nomeFile: "prova.json", archivio: a, adesso: adesso)) } catch let e as ErroreImportaOCF {
                return .failure(e)
            } catch {
                return .failure(ErroreImportaOCF(messaggio: "?"))
            }
        }
        func errore(_ r: Result<ImportazioneOCF, ErroreImportaOCF>) -> String? {
            if case .failure(let e) = r { return e.messaggio }
            return nil
        }
        verifica.vero("O8 Versione sconosciuta", errore(json(#"{"formato":"prisma-domande-ocf","versione":2,"domande":[]}"#)) == TestiOCF.versioneSconosciuta(2))
        verifica.vero("O8 Formato sconosciuto", errore(json(#"{"formato":"quiz","versione":1,"domande":[]}"#)) == TestiOCF.formatoSconosciuto("quiz"))
        verifica.vero("O8 JSON rotto", errore(json(#"{"formato":"prisma-domande-ocf","#)) == TestiOCF.jsonRotto)
        verifica.vero("O8 Senza domande", errore(json(#"{"formato":"prisma-domande-ocf","versione":1,"domande":[]}"#)) == TestiOCF.fileVuoto)
        let buono = json("""
        {"formato":"prisma-domande-ocf","versione":1,"fonte":"Appunti di prova",
         "materie":[{"id":"nuova","nome":"Materia dichiarata","caso":"casoMorte"}],
         "domande":[
          {"id":"j1","materia":"nuova","testo":"Prima domanda JSON","risposte":["a","b","c","d"],"corretta":"C"},
          {"id":"j2","materia":"m1","testo":"Seconda domanda JSON","risposte":["a","b","c"],"corretta":0},
          {"id":"j3","materia":"m1","testo":"Terza domanda JSON","risposte":["a","b","c","d"],"corretta":7},
          {"id":"j4","materia":"m1","testo":"Quarta","risposte":["a","b","c","d"],"corretta":true},
          "non è una domanda",
          {"id":"j6","materia":"Seconda","testo":"Sesta domanda JSON","risposte":["a","b","c","d"],"corretta":3,"spiegazione":"Perché sì."}
         ]}
        """)
        guard case .success(let j) = buono else {
            verifica.vero("O8 JSON di prova leggibile", false)
            return
        }
        verifica.vero("O8 Corretta «C» → 2 e materia dichiarata", j.nuove.first?.corretta == 2 && j.materieNuove.first?.caso == .casoMorte)
        verifica.vero("O8 Indice da 0 e materia per nome", j.nuove.last?.corretta == 3 && j.nuove.last?.materia == "m2")
        verifica.vero("O8 Fonte del file nelle domande", j.nuove.first?.fonte == "Appunti di prova")
        verifica.vero("O8 Scartate: 3 risposte, indice fuori, tipo sbagliato, non oggetto",
                      j.scartate.map(\.riga) == [2, 3, 4, 5] && j.scartate.first?.motivo == TestiOCF.risposteNonQuattro(3) && !j.daCSV)

        // O9. Le domande di esempio di Prisma: da 5 a 8, tutte valide, origine «esempio», nessuna scartata
        let es = ImportaOCF.esempio(archivio: ArchivioOCF(), adesso: adesso)
        verifica.vero("O9 Domande di esempio leggibili", es != nil)
        if let es {
            verifica.vero("O9 Tra 5 e 8 domande, nessuna scartata", (5...8).contains(es.nuove.count) && es.scartate.isEmpty)
            verifica.vero("O9 Tutte valide e di origine «esempio»", es.nuove.allSatisfy { $0.valida && $0.origine == .esempio })
            verifica("O9 Quattro materie generiche", Double(es.materieNuove.count), 4)
            var vuoto = ArchivioOCF()
            vuoto.applica(es)
            let dopo = ImportaOCF.esempio(archivio: vuoto, adesso: adesso)
            verifica.vero("O9 Aggiunte due volte: nessun doppione", dopo?.nuove.isEmpty == true && dopo?.materieNuove.isEmpty == true)
        }

        // O10. Archivio tollerante: una domanda senza quattro risposte e un caso sconosciuto
        let grezzo = #"{"materie":[{"id":"m"}],"domande":[{"id":"x","materia":"m","testo":"t","risposte":["a","b"],"corretta":0},"#
            + #"{"id":"y","materia":"m","testo":"t","risposte":["a","b","c","d"],"corretta":1,"caso":"marziano","origine":"ignota"}],"#
            + #""risposte":[{"id":"r","domandaId":"y","data":"2026-11-04T10:00:00Z","giusta":true},7],"nuovePerGiorno":"tante"}"#
        let letto = try? Archivio.decodificatore.decode(ArchivioOCF.self, from: Data(grezzo.utf8))
        verifica.vero("O10 Archivio OCF letto con tolleranza",
                      letto?.domande.map(\.id) == ["y"] && letto?.domande.first?.caso == nil && letto?.domande.first?.origine == .importata
                      && letto?.risposte.count == 1 && letto?.materie.first?.nome == "m" && letto?.nuovePerGiorno == ArchivioOCF.nuovePredefinite)
    }

    // MARK: Caso vero

    private static func casoVero(_ verifica: VerificaCalcoli) {
        let demo = DatiPrisma.demo()
        let rivalutabile = MotoreOCF.casoVero(.gestioneSeparata, clienti: demo.clienti, posizioni: demo.posizioni,
                                              documenti: demo.documenti, clienteAttivo: "giulia")
        let pos = demo.posizioni.first { $0.id == rivalutabile?.posizioneId }
        verifica.vero("O11 Gestione separata → una rivalutabile in essere di Giulia",
                      pos?.gestioneSeparata == true && pos?.stato == .inEssere && rivalutabile?.clienteId == "giulia"
                      && rivalutabile?.testo == "Guarda la polizza rivalutabile di Giulia")
        let pip = MotoreOCF.casoVero(.previdenzaComplementare, clienti: demo.clienti, posizioni: demo.posizioni,
                                     documenti: demo.documenti, clienteAttivo: nil)
        verifica.vero("O11 Previdenza → un piano previdenziale in essere",
                      demo.posizioni.first { $0.id == pip?.posizioneId }.map { $0.regime == .previdenza && $0.stato == .inEssere } == true)
        let tcm = MotoreOCF.casoVero(.casoMorte, clienti: demo.clienti, posizioni: demo.posizioni, documenti: demo.documenti, clienteAttivo: "giulia")
        verifica.vero("O11 Protezione → una temporanea caso morte in essere",
                      demo.posizioni.first { $0.id == tcm?.posizioneId }.map { $0.rischio == .vita && $0.stato == .inEssere } == true)
        let kid = MotoreOCF.casoVero(.kid, clienti: demo.clienti, posizioni: demo.posizioni, documenti: demo.documenti, clienteAttivo: "giulia")
        verifica.vero("O11 KID → un documento KID di Giulia",
                      demo.documenti.first { $0.id == kid?.documentoId }.map { $0.tipo == .kid && $0.clienteId == "giulia" } == true)
        // Il caso della materia vale per le domande senza un caso proprio
        var dati = demo
        dati.ocf.materie = [MateriaOCF(id: "prev", nome: "Previdenza", caso: .previdenzaComplementare)]
        let d = DomandaOCF(id: "d", materia: "prev", testo: "t", risposte: ["a", "b", "c", "d"], corretta: 0)
        verifica.vero("O11 Senza caso proprio vale quello della materia", MotoreOCF.casoVero(per: d, dati: dati, clienteAttivo: nil)?.caso == .previdenzaComplementare)
        let senzaMateria = DomandaOCF(id: "e", materia: "altra", testo: "t", risposte: ["a", "b", "c", "d"], corretta: 0)
        verifica.vero("O11 Senza caso né materia collegata: nessun pulsante", MotoreOCF.casoVero(per: senzaMateria, dati: dati, clienteAttivo: nil) == nil)
        let vuoto = CasoOCF.allCases.compactMap { MotoreOCF.casoVero($0, clienti: [], posizioni: [], documenti: [], clienteAttivo: nil) }
        verifica.vero("O11 Archivio vuoto: nessun caso vero", vuoto.isEmpty)
    }
}
