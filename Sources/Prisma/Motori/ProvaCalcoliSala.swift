import Foundation

/// Prove delle esperienze della Sala con un motore proprio (Design/template-luce-specifica.md §4.1.5 e §4.2.5, «Luce»
/// giro 4), chiamate da `ProvaCalcoli.esegui()`:
/// - una giornata della pensione: i numeri del template come caso di prova (1.400 → resto 90, una sola scena accesa;
///   2.160 → tutte accese, resto 290), spese fisse non coperte, regola «priorità» contro «ordine della giornata», voce
///   senza importo esclusa, «senza piano» = pubblica + rendita in essere e «con il piano» = + rendita delle proposte,
///   giornata da compilare senza costi inventati, lettura tollerante;
/// - il gioco del rischio: punteggi 0…6 sulle quattro propensioni, confronto con il dichiarato, partita incompleta senza
///   profilo, testi letti dalla risorsa (versione, «testi di prova»), valori degli scenari, strade, secondi.
enum ProvaCalcoliSala {
    static func esegui(_ verifica: VerificaCalcoli) {
        giornata(verifica)
        giornataPensione(verifica)
        giornataDati(verifica)
        rischio(verifica)
        rischioRisorsa(verifica)
    }

    // MARK: - Una giornata della pensione

    private static func giornata(_ verifica: VerificaCalcoli) {
        let g = MotoreGiornataPensione.giornataDiProva()
        // 1. I numeri del template con Giulia senza piano: 1.400 − 1.250 = 150 → colazione sì (resta 90), il resto no
        let senza = MotoreGiornataPensione.calcola(g, pensione: 1_400)
        verifica("Giornata: spese fisse del caso di prova", senza.fisse, 1_250)
        verifica("Giornata: 1.400 € al mese, restano 90 €", senza.resto, 90)
        verifica("Giornata: 1.400 € al mese, una sola scena accesa", Double(senza.scene.filter { !$0.voce.fissa && $0.ciSta }.count), 1)
        verifica.vero("Giornata: la scena accesa è la colazione", senza.scene.first { !$0.voce.fissa && $0.ciSta }?.voce.id == "colazione")
        verifica.vero("Giornata: le spese fisse coperte", senza.fisseCoperte && senza.scene.first { $0.voce.fissa }?.ciSta == true)
        verifica("Giornata: per tutta la giornata mancano 470 € al mese", senza.mancaPerTutto, 470)
        verifica("Giornata: le scene accese usano 60 €", senza.usate, 60)
        // 2. Con il piano (2.160): tutto ci sta, restano 290
        let con = MotoreGiornataPensione.calcola(g, pensione: 2_160)
        verifica("Giornata: 2.160 € al mese, restano 290 €", con.resto, 290)
        verifica.vero("Giornata: 2.160 € al mese, tutte le scene accese", con.scene.allSatisfy(\.ciSta) && con.mancaPerTutto == 0)
        // 3. Fisse non coperte: nessuna scena e resto negativo
        let poco = MotoreGiornataPensione.calcola(g, pensione: 1_070)
        verifica.vero("Giornata: fisse non coperte, nessuna scena accesa", !poco.fisseCoperte && !poco.scene.contains { $0.ciSta })
        verifica("Giornata: fisse non coperte, mancano 180 €", poco.resto, -180)
        // 4. Priorità contro ordine della giornata: una scena cara prima fa saltare la piccola dopo
        let voci = [
            VoceGiornata(id: "casa", quando: "", titolo: "Casa", frase: "", importoMensile: 1_000, fissa: true, glifo: "casa", priorita: 0),
            VoceGiornata(id: "cara", quando: "", titolo: "Cara", frase: "", importoMensile: 150, glifo: "cena", priorita: 2),
            VoceGiornata(id: "piccola", quando: "", titolo: "Piccola", frase: "", importoMensile: 100, glifo: "colazione", priorita: 1)
        ]
        let gp = GiornataPensione(voci: voci)
        let ordine = MotoreGiornataPensione.calcola(gp, pensione: 1_200, regola: .ordineDellaGiornata)
        let priorita = MotoreGiornataPensione.calcola(gp, pensione: 1_200, regola: .priorita)
        func accesa(_ e: EsitoGiornata, _ id: String) -> Bool { e.scene.first { $0.voce.id == id }?.ciSta == true }
        verifica.vero("Giornata: ordine della giornata, la cara ci sta e la piccola salta", accesa(ordine, "cara") && !accesa(ordine, "piccola"))
        verifica.vero("Giornata: con la priorità, la piccola ci sta e la cara salta", accesa(priorita, "piccola") && !accesa(priorita, "cara"))
        verifica("Giornata: con la priorità restano 100 €", priorita.resto, 100)
        // 5. Una voce senza importo è esclusa dal conto e segnalata
        var senzaNipoti = g
        if let i = senzaNipoti.voci.firstIndex(where: { $0.id == "nipoti" }) { senzaNipoti.voci[i].importoMensile = nil }
        let e5 = MotoreGiornataPensione.calcola(senzaNipoti, pensione: 1_400)
        verifica.vero("Giornata: voce senza importo esclusa e segnalata", e5.senzaImporto.map(\.id) == ["nipoti"]
                      && e5.scene.first { $0.voce.id == "nipoti" }?.ciSta == false)
        verifica("Giornata: senza i nipoti mancano 320 € per tutto", e5.mancaPerTutto, 320)
        // Lo spostamento rifà le priorità 0, 1, 2 …
        let spostate = MotoreGiornataPensione.sposta(g.voci, id: "viaggio", prima: "colazione")
        verifica.vero("Giornata: trascinata prima, la scena prende la priorità 0",
                      spostate.first?.id == "viaggio" && spostate.map(\.priorita) == Array(0..<spostate.count))
    }

    /// 6. «Senza piano» = pubblica + rendita dei piani in essere; «con il piano» = + rendita delle proposte (Giulia dei dati
    /// di prova ha un PIP in proposta), con le stesse cifre di MotorePrevidenza.
    private static func giornataPensione(_ verifica: VerificaCalcoli) {
        let d = DatiPrisma.demo()
        guard let giulia = d.clienti.first(where: { $0.id == "giulia" }) else {
            verifica.vero("Giornata: Giulia nei dati di prova", false)
            return
        }
        let oggi = AiutiProva.data(2026, 11, 3)
        let posizioni = d.posizioni.filter { $0.clienteId == giulia.id }
        var analisi = Analisi360(cliente: giulia, posizioni: posizioni)
        analisi.previdenza.pensionePubblica = 1_400
        analisi.previdenza.redditoDesiderato = 2_200
        analisi.confermate = [.previdenza]
        let e = MotorePrevidenza.calcola(posizioni, cliente: giulia, analisi: analisi.previdenza, data: oggi)
        guard case .pronto(let c) = PensioneEsperienze.calcola(cliente: giulia, posizioni: d.posizioni, analisi: analisi, data: oggi) else {
            verifica.vero("Giornata: con la Previdenza confermata le cifre ci sono", false)
            return
        }
        verifica("Giornata: senza piano = pubblica + rendita in essere", c.senzaPiano, e.pensionePubblica + e.renditaInEssere)
        if e.proposte.isEmpty {
            verifica.vero("Giornata: senza proposte nessun «con il piano»", c.conPiano == nil)
        } else {
            verifica("Giornata: con il piano = senza + rendita delle proposte", c.conPiano ?? -1, c.senzaPiano + e.renditaProposte)
        }
        // Senza conferma della Previdenza la giornata non ha cifre (mai i valori predefiniti)
        analisi.confermate = []
        verifica.vero("Giornata: ipotesi non confermate, nessuna pensione",
                      PensioneEsperienze.calcola(cliente: giulia, posizioni: d.posizioni, analisi: analisi, data: oggi) == .ipotesiDaConfermare)
    }

    private static func giornataDati(_ verifica: VerificaCalcoli) {
        // Da compilare: nessun costo inventato; le fisse dal fabbisogno solo se dato, e «da confermare»
        let vuota = MotoreGiornataPensione.daCompilare(fabbisognoConfermato: nil)
        verifica.vero("Giornata: da compilare, cinque scene senza importi", vuota.voci.count == 5 && vuota.daCompilare
                      && vuota.voci.filter(\.fissa).count == 1)
        let fabbisogno = MotoreGiornataPensione.daCompilare(fabbisognoConfermato: 1_800)
        let fissa = fabbisogno.voci.first(where: \.fissa)
        verifica.vero("Giornata: spese fisse dal fabbisogno, da confermare", fissa?.importoMensile == 1_800 && fissa?.daConfermare == true
                      && fabbisogno.voci.filter { !$0.fissa }.allSatisfy { $0.importoMensile == nil })
        let e = MotoreGiornataPensione.calcola(vuota, pensione: 1_400)
        verifica.vero("Giornata: senza importi nessuna scena accesa e nulla speso", e.scene.allSatisfy(\.senzaImporto) && e.usate == 0 && e.resto == 1_400)
        // Lettura tollerante: una voce senza id si scarta, un importo negativo è «non scritto»
        let json = #"{"voci":[{"titolo":"senza id"},{"id":"a","titolo":"A","importoMensile":-5,"glifo":"cena"},{"id":"b","importoMensile":70}],"diProva":true}"#
        let letta = try? JSONDecoder().decode(GiornataPensione.self, from: Data(json.utf8))
        verifica.vero("Giornata: lettura tollerante delle voci", letta?.voci.map(\.id) == ["a", "b"]
                      && letta?.voci.first?.importoMensile == nil && letta?.voci.last?.importoMensile == 70 && letta?.diProva == true)
        // L'Analisi 360 senza giornata si legge come prima
        let analisi = try? JSONDecoder().decode(Analisi360.self, from: Data(#"{"confermate":["previdenza"]}"#.utf8))
        verifica.vero("Giornata: Analisi 360 senza giornata letta come prima", analisi?.giornata == nil && analisi?.confermate == [.previdenza])
    }

    // MARK: - Il gioco del rischio

    private static func rischio(_ verifica: VerificaCalcoli) {
        // 1. Punteggi 0…6 → le quattro propensioni (decisione 84)
        let attese: [ProfiloInvestitore.Propensione] = [.prudente, .prudente, .moderata, .moderata, .dinamica, .dinamica, .aggressiva]
        verifica.vero("Rischio: punteggi 0…6 sulle quattro propensioni", (0...6).map { MotoreGiocoRischio.profilo(punteggio: $0) } == attese)
        // Su un massimo diverso il punteggio si riporta a 6
        verifica.vero("Rischio: punteggio riportato sulla scala 0-6", MotoreGiocoRischio.profilo(punteggio: 8, massimo: 8) == .aggressiva
                      && MotoreGiocoRischio.profilo(punteggio: 2, massimo: 8) == .moderata)
        // 2. Confronto con il dichiarato
        verifica.vero("Rischio: confronto uguale", MotoreGiocoRischio.confronto(emerso: .moderata, dichiarato: .moderata) == .uguale)
        verifica.vero("Rischio: emerso più audace", MotoreGiocoRischio.confronto(emerso: .dinamica, dichiarato: .moderata) == .piuAudace)
        verifica.vero("Rischio: emerso più prudente", MotoreGiocoRischio.confronto(emerso: .prudente, dichiarato: .dinamica) == .piuPrudente)
        verifica.vero("Rischio: nessun dichiarato", MotoreGiocoRischio.confronto(emerso: .prudente, dichiarato: nil) == .nessunDichiarato)
        // La perdita sopportata è quella di MotoreResistenza
        verifica.vero("Rischio: perdita sopportata come MotoreResistenza", ProfiloInvestitore.Propensione.allCases.allSatisfy {
            MotoreGiocoRischio.perditaSopportata($0) == MotoreResistenza.sopportabile($0)
        })
        verifica.vero("Rischio: secondi con la virgola", MotoreGiocoRischio.secondi(1.04) == "1,0 s" && MotoreGiocoRischio.secondi(2.36) == "2,4 s")
        // Le due strade: 100 all'inizio, ×1,02 ogni anno la sicura
        let sicura = MotoreGiocoRischio.punti(StradaRischio(nome: "sicuro 2%", rendimenti: Array(repeating: 2, count: 10)))
        verifica("Rischio: strada sicura dopo dieci anni", sicura.last ?? 0, 121.90, tolleranza: 0.01)
        verifica("Rischio: strada con undici punti", Double(sicura.count), 11)
    }

    private static func rischioRisorsa(_ verifica: VerificaCalcoli) {
        // 4. I testi dalla risorsa: versione, «testi di prova», tre scenari da tre risposte
        guard let s = MotoreGiocoRischio.scenari() else {
            verifica.vero("Rischio: testi del gioco letti dalla risorsa", false)
            return
        }
        verifica.vero("Rischio: testi del gioco letti dalla risorsa", s.scenari.count == 3 && s.scenari.allSatisfy { $0.risposte.count == 3 })
        verifica.vero("Rischio: testi segnati «testi di prova» finché l'utente non li approva", s.testiDiProva)
        verifica("Rischio: punteggio massimo 6", Double(s.massimo), 6)
        verifica.vero("Rischio: soglie della decisione 84", s.soglie == SoglieGiocoRischio())
        // La versione degli scenari entra nella partita; B, B, C = 4 → dinamica (il template direbbe «Equilibrato»)
        let partita = PartitaRischio(clienteId: "giulia", data: AiutiProva.data(2026, 3, 12), versioneScenari: s.versione,
                                     risposte: zip(s.scenari, [1, 1, 2]).map { RispostaRischio(scenario: $0.id, scelta: $1, secondi: 1) })
        verifica.vero("Rischio: la partita porta la versione dei testi", partita.versioneScenari == s.versione && !s.versione.isEmpty)
        verifica.vero("Rischio: B, B, C fanno 4 e la propensione dinamica", partita.punteggio == 4
                      && MotoreGiocoRischio.profilo(partita, scenari: s) == .dinamica)
        // 3. Una partita incompleta non dà profilo
        var incompleta = partita
        incompleta.risposte.removeLast()
        verifica.vero("Rischio: partita incompleta senza profilo", MotoreGiocoRischio.profilo(incompleta, scenari: s) == nil)
        // I valori degli scenari: 100.000 → 80.000 (scende), 80.000 → 112.000 (sale, il conteggio parte da 80.000)
        let calo = s.scenari[0], risalita = s.scenari[1]
        verifica("Rischio: scenario 1 finisce a 80.000 €", MotoreGiocoRischio.valoreFinale(calo) ?? 0, 80_000)
        verifica("Rischio: scenario 2 parte da 80.000 €", MotoreGiocoRischio.valorePartenza(risalita) ?? 0, 80_000)
        verifica("Rischio: scenario 2 finisce a 112.000 €", MotoreGiocoRischio.valoreFinale(risalita) ?? 0, 112_000)
        verifica.vero("Rischio: il calo scende, la risalita sale", MotoreGiocoRischio.scende(calo) && !MotoreGiocoRischio.scende(risalita))
        verifica.vero("Rischio: scenario 3 a due strade", s.scenari[2].andamento == nil && s.scenari[2].strade?.count == 2)
        // L'ultima partita del cliente è la più recente
        var dopo = partita
        dopo.id = "dopo"
        dopo.data = AiutiProva.data(2026, 6, 1)
        verifica.vero("Rischio: l'ultima partita è la più recente", MotoreGiocoRischio.ultima([partita, dopo], cliente: "giulia")?.id == "dopo"
                      && MotoreGiocoRischio.ultima([partita], cliente: "marco") == nil)
        // Testi non validi: nessun gioco (mai scenari inventati)
        verifica.vero("Rischio: testi illeggibili o con una sola risposta rifiutati", MotoreGiocoRischio.leggi(Data("{}".utf8)) == nil
                      && MotoreGiocoRischio.leggi(Data(#"{"versione":"x","testiDiProva":true,"avvertenza":"","notaFinale":"","soglie":{"prudenteFino":1,"moderataFino":3,"dinamicaFino":5},"scenari":[{"id":"a","domanda":"?","etichetta":"e","andamento":[100,90],"risposte":["sola"]}]}"#.utf8)) == nil)
    }
}
