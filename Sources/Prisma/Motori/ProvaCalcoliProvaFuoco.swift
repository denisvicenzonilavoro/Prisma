import Foundation

/// Prove della prova del fuoco (Posizioni, Orizzonte giro 4): perdite per scenario dal motore della resistenza,
/// copertura degli obiettivi prima e dopo coerente con `MotoreObiettivo`, soglia dei 10 punti, ordine di «Chi
/// chiamare», annullamento, dati di prova e carico. Chiamate da `ProvaCalcoli.esegui()`: gli errori si sommano.
/// Cifre tonde scelte per la prova.
enum ProvaCalcoliProvaFuoco {
    static func esegui(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 11, 4)
        func pos(_ nome: String, _ area: AreaPosizione, _ valore: Double, cliente: String = "prova",
                 _ modifica: (inout Posizione) -> Void = { _ in }) -> Posizione {
            var p = AiutiProva.posizione(nome, area, valore, modifica)
            p.clienteId = cliente
            return p
        }
        func cliente(_ id: String, _ nome: String) -> Cliente {
            Cliente(id: id, nome: nome, iniziali: Cliente.iniziali(di: nome), tinta: .blu, tema: "", email: "",
                    telefono: "", preferito: false, nota: "", creatoIl: oggi)
        }

        // P1. Mercati: fondo da 100.000 € con il 40% in azioni, mercati −25% → 10.000 €.
        do {
            let fondo = pos("Bilanciato", .investimento, 100_000) { $0.tipologia = "Fondo comune bilanciato"; $0.quotaAzionaria = 40 }
            verifica("P1 Mercati −25%: variazione del fondo al 40% in azioni (−10%)", MotoreProvaFuoco.variazione(fondo, .mercati(calo: 25)), -0.1, tolleranza: 1e-9)
            let e = MotoreProvaFuoco.calcola(.mercati(calo: 25), clienti: [cliente("prova", "Prova Uno")], posizioni: [fondo], obiettivi: [], oggi: oggi)
            verifica("P1 Mercati −25%: perdita 10.000 €", e.perditaTotale, 10_000)
            verifica.vero("P1 Quota azionaria indicata: non stimata", e.righe.first?.stimata == false)
            // Senza quota azionaria: la stima della prova di resistenza (bilanciato 50%) e la «≈»
            let stimato = pos("Bilanciato", .investimento, 100_000) { $0.tipologia = "Fondo comune bilanciato" }
            let s = MotoreProvaFuoco.calcola(.mercati(calo: 25), clienti: [cliente("prova", "Prova Uno")], posizioni: [stimato], obiettivi: [], oggi: oggi)
            verifica("P1 Senza quota: azioni stimate al 50% come la resistenza, perdita 12.500 €", s.perditaTotale, 12_500)
            verifica.vero("P1 Senza quota: posizione segnata «stima»", s.righe.first?.voci.first?.stimata == true && s.posizioniStimate == 1)
        }

        // P2. Gestione separata: Ramo I da 50.000 € non perde con mercati −45% né con tassi +4.
        do {
            let ramoI = pos("Rivalutabile", .risparmio, 50_000) { $0.tipologia = "Polizza rivalutabile (Ramo I)" }
            verifica("P2 Ramo I con mercati −45%: nessuna perdita", MotoreProvaFuoco.variazione(ramoI, .mercati(calo: 45)), 0, tolleranza: 1e-12)
            verifica("P2 Ramo I con tassi +4: nessuna perdita", MotoreProvaFuoco.variazione(ramoI, .tassi(punti: 4)), 0, tolleranza: 1e-12)
            let conto = pos("Conto", .liquidita, 20_000)
            verifica("P2 Conto con tassi +4: nessuna perdita", MotoreProvaFuoco.variazione(conto, .tassi(punti: 4)), 0, tolleranza: 1e-12)
        }

        // P3. Multiramo senza quota (50% in gestione separata), fondi tutti azionari (SRI 6), −20% → 10.000 €.
        do {
            let multi = pos("Multiramo", .investimento, 100_000) { $0.tipologia = "Polizza multiramo"; $0.sri = 6 }
            verifica("P3 Multiramo senza quota, −20%: perdita 10.000 €", -multi.valore * MotoreProvaFuoco.variazione(multi, .mercati(calo: 20)), 10_000)
        }

        // P4. Tassi: 60.000 € tutti obbligazionari, +2 punti. La posizione non ha la durata: durata predefinita della
        // tipologia (obbligazionari 6 anni → 7.200 €; a breve termine 2 anni → 2.400 €) e riga «stimata».
        do {
            let obbl = pos("Obbligazionario", .investimento, 60_000) { $0.tipologia = "Fondo obbligazionario"; $0.quotaAzionaria = 0; $0.quotaTitoliStato = 50 }
            let breve = pos("Breve", .investimento, 60_000) { $0.tipologia = "Fondo obbligazionario breve termine"; $0.quotaAzionaria = 0 }
            verifica("P4 Tassi +2, obbligazionario (6 anni): perdita 7.200 €", -obbl.valore * MotoreProvaFuoco.variazione(obbl, .tassi(punti: 2)), 7_200)
            verifica("P4 Tassi +2, breve termine (2 anni): perdita 2.400 €", -breve.valore * MotoreProvaFuoco.variazione(breve, .tassi(punti: 2)), 2_400)
            let e = MotoreProvaFuoco.calcola(.tassi(punti: 2), clienti: [cliente("prova", "Prova")], posizioni: [obbl], obiettivi: [], oggi: oggi)
            verifica.vero("P4 Durata predefinita: posizione «stimata»", e.righe.first?.voci.first?.stimata == true)
            verifica("P4 Tassi: azioni pure non perdono", MotoreProvaFuoco.variazione(pos("ETF", .investimento, 10_000) { $0.tipologia = "ETF azionario"; $0.quotaAzionaria = 100 }, .tassi(punti: 4)), 0, tolleranza: 1e-12)
        }

        // P5. Inflazione: con 5% e 3 anni la funzione nuova dà la perdita della prova di resistenza (che non cambia).
        do {
            let conto = pos("Conto", .liquidita, 10_000)
            let fondo = pos("Fondo", .investimento, 30_000) { $0.rendimentoAtteso = 2; $0.costoAnnuo = 1 }
            let r = MotoreResistenza.calcola([conto, fondo], profilo: nil)
            let e = MotoreProvaFuoco.calcola(.inflazione(tasso: 5, anni: 3), clienti: [cliente("prova", "Prova")], posizioni: [conto, fondo], obiettivi: [], oggi: oggi)
            verifica("P5 Inflazione 5% per 3 anni: uguale alla prova di resistenza", e.perditaTotale, r.scenario(.inflazione)?.perdita ?? -1, tolleranza: 0.01)
            verifica("P5 Conto di 10.000 € senza rendimento: 10.000 × (1 − 1/1,05³)", MotoreResistenza.perditaInflazione(conto, tasso: 5, anni: 3) ?? -1, 1_361.62, tolleranza: 0.01)
        }

        // P6. Inflazione sull'obiettivo: 50.000 € di oggi fra 10 anni, 5% per 3 anni poi il 2% → 50.000 × 1,05³ × 1,02⁷.
        do {
            verifica("P6 Traguardo con l'inflazione dello scenario", MotoreObiettivo.importoAScadenza(50_000, anni: 10, inflazioneIniziale: (tasso: 5, anni: 3)), 66_487.36, tolleranza: 0.01)
            verifica("P6 Senza scenario: l'inflazione di Prisma", MotoreObiettivo.importoAScadenza(50_000, anni: 10), 50_000 * pow(1.02, 10), tolleranza: 0.0001)
        }

        // Il portafoglio di prova: Anna (azioni collegate all'obiettivo), Bruno (conto collegato), Carla (senza obiettivi
        // validi, con una proposta), Dario (niente posizioni, obiettivo già scaduto).
        let anna = cliente("anna", "Anna Prova"), bruno = cliente("bruno", "Bruno Prova")
        let carla = cliente("carla", "Carla Prova"), dario = cliente("dario", "Dario Prova")
        let azioni = pos("Azionario", .investimento, 100_000, cliente: "anna") {
            $0.tipologia = "ETF azionario"; $0.quotaAzionaria = 100; $0.rendimentoAtteso = 5; $0.totaleVersato = 100_000
        }
        let conto = pos("Conto", .liquidita, 50_000, cliente: "bruno")
        let fondoCarla = pos("Bilanciato", .investimento, 100_000, cliente: "carla") { $0.tipologia = "Fondo comune bilanciato"; $0.quotaAzionaria = 40 }
        var propostaCarla = pos("Proposta", .investimento, 50_000, cliente: "carla") { $0.tipologia = "ETF azionario"; $0.quotaAzionaria = 100 }
        propostaCarla.stato = .proposta
        var obAnna = Obiettivo(clienteId: "anna", titolo: "Studi", area: .famiglia, importo: 150_000, scadenza: AiutiProva.data(2036, 11, 4))
        obAnna.id = "ob-anna"
        obAnna.posizioniCollegate = [azioni.id]
        var obBruno = Obiettivo(clienteId: "bruno", titolo: "Casa", area: .casa, importo: 100_000, scadenza: AiutiProva.data(2031, 11, 4))
        obBruno.id = "ob-bruno"
        obBruno.posizioniCollegate = [conto.id]
        var obCarla = Obiettivo(clienteId: "carla", titolo: "Senza importo", area: .casa, importo: 0, scadenza: AiutiProva.data(2030, 1, 1))
        obCarla.id = "ob-carla"
        var obDario = Obiettivo(clienteId: "dario", titolo: "Scaduto", area: .casa, importo: 20_000, scadenza: AiutiProva.data(2025, 1, 1))
        obDario.id = "ob-dario"
        let clienti = [dario, carla, bruno, anna]
        let posizioni = [azioni, conto, fondoCarla, propostaCarla]
        let obiettivi = [obAnna, obBruno, obCarla, obDario]

        // P7. Crisi del passato: la perdita del cliente è quella di `MotoreResistenza.crisi`.
        do {
            for anno in [2008, 2020] {
                let e = MotoreProvaFuoco.calcola(.crisi(anno: anno), clienti: [carla], posizioni: [fondoCarla, propostaCarla], obiettivi: [], oggi: oggi)
                let k = MotoreResistenza.crisi([fondoCarla, propostaCarla], profilo: nil).first { $0.crisi.anno == anno }
                verifica("P7 Come nel \(anno): perdita uguale alla crisi della prova di resistenza", e.perditaTotale, k?.perdita ?? -1, tolleranza: 0.005)
            }
            verifica.vero("P7 «Come nel 2008» e «Come nel 2020» vengono da CrisiStoriche",
                          ScenarioFuoco.crisi(anno: 2008).crisiStorica?.anno == 2008 && ScenarioFuoco.crisi(anno: 2020).crisiStorica?.anno == 2020)
        }

        // P8-P13. Coperture, soglia, ordine, obiettivi non validi, proposte, perdita totale.
        do {
            let e = MotoreProvaFuoco.calcola(.mercati(calo: 25), clienti: clienti, posizioni: posizioni, obiettivi: obiettivi, oggi: oggi)
            let r = Dictionary(uniqueKeysWithValues: e.righe.map { ($0.clienteId, $0) })
            verifica("P8 Tutti i clienti ricalcolati", Double(e.righe.count), 4)
            verifica.vero("P8 Mercati: la copertura dopo non supera quella di oggi", e.righe.allSatisfy { $0.coperturaDopo <= $0.coperturaOggi + 1e-12 })
            verifica.vero("P8 Anna scende di più di 10 punti", (r["anna"]?.calo ?? 0) > 10)
            verifica("P8 Bruno (conto): nessun calo", r["bruno"]?.calo ?? -1, 0, tolleranza: 1e-9)
            verifica("P10 Oltre la soglia: solo Anna", Double(e.oltreSoglia), 1)
            verifica.vero("P11 Ordine: Anna, Bruno, Carla, Dario", e.righe.map(\.clienteId) == ["anna", "bruno", "carla", "dario"])
            verifica("P11 Perdita totale: 25.000 + 10.000 (anche chi non ha obiettivi)", e.perditaTotale, 35_000)
            verifica.vero("P12 Obiettivo senza importo o scaduto: non entra", r["carla"]?.obiettivoId == nil && r["dario"]?.obiettivoId == nil)
            verifica("P13 Proposte: non perdono (Carla perde solo il fondo in essere)", r["carla"]?.perdita ?? -1, 10_000)

            // P9. Coerenza con il piano: senza scenario la copertura è quella di `MotoreObiettivo.calcola`
            var piano = Obiettivo(clienteId: "anna", titolo: "Piano", area: .famiglia, importo: 200_000, scadenza: AiutiProva.data(2038, 6, 30))
            piano.posizioniCollegate = [azioni.id, conto.id]
            piano.accantonato = 5_000
            piano.versamentoMensile = 100
            let pianoPos = [azioni, conto, fondoCarla]
            verifica("P9 Copertura leggera uguale a MotoreObiettivo.calcola", MotoreObiettivo.coperturaAScadenza(piano, posizioni: pianoPos, data: oggi),
                     MotoreObiettivo.calcola(piano, posizioni: pianoPos, data: oggi).copertura, tolleranza: 0.0001)
            verifica("P9 Copertura di Anna oggi uguale a MotoreObiettivo.calcola", r["anna"]?.coperturaOggi ?? -1,
                     MotoreObiettivo.calcola(obAnna, posizioni: posizioni, data: oggi).copertura, tolleranza: 0.0001)

            // P8. Tassi su chi non ha obbligazioni: la copertura non cambia
            let t = MotoreProvaFuoco.calcola(.tassi(punti: 2), clienti: [anna], posizioni: [azioni], obiettivi: [obAnna], oggi: oggi)
            verifica("P8 Tassi senza obbligazioni: copertura dopo = oggi", (t.righe.first?.coperturaDopo ?? -1) - (t.righe.first?.coperturaOggi ?? 0), 0, tolleranza: 1e-12)
            // Inflazione: il conto perde potere d'acquisto e l'obiettivo di Bruno costa di più
            let i = MotoreProvaFuoco.calcola(.inflazione(tasso: 5, anni: 3), clienti: [bruno], posizioni: [conto], obiettivi: [obBruno], oggi: oggi)
            verifica.vero("P8 Inflazione: la copertura di Bruno scende anche con il conto fermo", (i.righe.first?.calo ?? 0) > 0)
            verifica.vero("P8 Bruno: l'obiettivo ha la posizione collegata", i.righe.first?.collegateAssenti == false)
        }

        // P10. La soglia: 10,0 punti non contano, 10,01 sì; arancio sopra 5, rosso sopra 10.
        do {
            func riga(_ oggi: Double, _ dopo: Double) -> RigaProvaFuoco {
                RigaProvaFuoco(clienteId: "x", nome: "X", telefono: "", obiettivoId: "o", titoloObiettivo: "O", coperturaOggi: oggi,
                               coperturaDopo: dopo, perdita: 0, voci: [], collegateAssenti: false)
            }
            verifica("P10 0,9 → 0,8: esattamente 10,0 punti", riga(0.9, 0.8).calo, 10, tolleranza: 1e-9)
            verifica.vero("P10 10,0 punti non sono oltre la soglia", !riga(0.9, 0.8).oltreSoglia)
            verifica.vero("P10 10,01 punti sono oltre la soglia", riga(0.9, 0.7999).oltreSoglia)
            verifica.vero("P10 Livelli: 5 tranquillo, 5,01 attenzione, 10 attenzione, 10,01 allarme",
                          MotoreProvaFuoco.livello(calo: 5) == .tranquillo && MotoreProvaFuoco.livello(calo: 5.01) == .attenzione
                          && MotoreProvaFuoco.livello(calo: 10) == .attenzione && MotoreProvaFuoco.livello(calo: 10.01) == .allarme)
            // P11. A pari calo vince la perdita più alta; i clienti senza obiettivo in fondo, per perdita
            let a = RigaProvaFuoco(clienteId: "a", nome: "A", telefono: "", obiettivoId: "o", titoloObiettivo: "O", coperturaOggi: 0.8,
                                   coperturaDopo: 0.7, perdita: 1_000, voci: [], collegateAssenti: false)
            let b = RigaProvaFuoco(clienteId: "b", nome: "B", telefono: "", obiettivoId: "o", titoloObiettivo: "O", coperturaOggi: 0.8,
                                   coperturaDopo: 0.7, perdita: 5_000, voci: [], collegateAssenti: false)
            let c = RigaProvaFuoco(clienteId: "c", nome: "C", telefono: "", obiettivoId: nil, titoloObiettivo: nil, coperturaOggi: 0,
                                   coperturaDopo: 0, perdita: 90_000, voci: [], collegateAssenti: false)
            let d = RigaProvaFuoco(clienteId: "d", nome: "D", telefono: "", obiettivoId: nil, titoloObiettivo: nil, coperturaOggi: 0,
                                   coperturaDopo: 0, perdita: 100_000, voci: [], collegateAssenti: false)
            let e = RigaProvaFuoco(clienteId: "e", nome: "E", telefono: "", obiettivoId: "o", titoloObiettivo: "O", coperturaOggi: 0.9,
                                   coperturaDopo: 0.5, perdita: 10, voci: [], collegateAssenti: false)
            verifica.vero("P11 Ordine: calo, poi perdita; senza obiettivi in fondo per perdita",
                          MotoreProvaFuoco.ordina([c, a, d, b, e]).map(\.clienteId) == ["e", "b", "a", "d", "c"])
        }

        // P15. Annullamento: il calcolo si ferma appena il cursore si muove di nuovo; vince l'ultimo ricalcolo.
        do {
            guard let base = MotoreProvaFuoco.prepara(clienti: clienti, posizioni: posizioni, obiettivi: obiettivi, oggi: oggi) else {
                verifica.vero("P15 Base della prova preparata", false)
                return
            }
            verifica.vero("P15 Annullato subito: nessun risultato", MotoreProvaFuoco.calcola(.mercati(calo: 25), base: base, annullato: { true }) == nil)
            var controlli = 0
            let fermato = MotoreProvaFuoco.calcola(.mercati(calo: 25), base: base, annullato: { controlli += 1; return controlli > 2 })
            verifica.vero("P15 Annullato a metà: nessun risultato parziale", fermato == nil && controlli == 3)
            verifica.vero("P15 Preparazione annullata: nessuna base", MotoreProvaFuoco.prepara(clienti: clienti, posizioni: posizioni, obiettivi: obiettivi, oggi: oggi, annullato: { true }) == nil)
            verifica.vero("P15 Base riusata: stesso esito del calcolo in un colpo",
                          MotoreProvaFuoco.calcola(.mercati(calo: 25), base: base)
                            == MotoreProvaFuoco.calcola(.mercati(calo: 25), clienti: clienti, posizioni: posizioni, obiettivi: obiettivi, oggi: oggi))
            var sequenza = SequenzaRicalcoli()
            let primo = sequenza.nuovo(), secondo = sequenza.nuovo()
            verifica.vero("P15 L'ultimo vince: il primo ricalcolo non si pubblica", !sequenza.valido(primo) && sequenza.valido(secondo))
        }

        // P16. I dati di prova (5 clienti del template e 30 fittizi): tutti gli scenari, ordine e monotonia; carico.
        do {
            let d = ClientiFittizi.completi()
            let scenari: [ScenarioFuoco] = [.mercati(calo: 25), .tassi(punti: 2), .inflazione(tasso: 5, anni: 3), .crisi(anno: 2008), .crisi(anno: 2020)]
            let inizio = DispatchTime.now().uptimeNanoseconds
            guard let base = MotoreProvaFuoco.prepara(clienti: d.clienti, posizioni: d.posizioni, obiettivi: d.obiettivi, oggi: oggi) else {
                verifica.vero("P16 Base dei dati di prova", false)
                return
            }
            let preparata = DispatchTime.now().uptimeNanoseconds
            var esiti: [EsitoProvaFuoco] = []
            for s in scenari { if let e = MotoreProvaFuoco.calcola(s, base: base) { esiti.append(e) } }
            let fine = DispatchTime.now().uptimeNanoseconds
            verifica("P16 Dati di prova: cinque scenari calcolati", Double(esiti.count), 5)
            verifica.vero("P16 Dati di prova: tutti i clienti in ogni scenario", esiti.allSatisfy { $0.righe.count == d.clienti.count })
            verifica.vero("P16 Dati di prova: l'elenco segue il criterio dichiarato", esiti.allSatisfy { $0.righe == MotoreProvaFuoco.ordina($0.righe) })
            verifica.vero("P16 Dati di prova: oltre la soglia mai più dei clienti con obiettivo",
                          esiti.allSatisfy { e in e.oltreSoglia <= e.righe.filter { $0.obiettivoId != nil }.count })
            let m25 = MotoreProvaFuoco.calcola(.mercati(calo: 25), base: base)?.perditaTotale ?? 0
            let m45 = MotoreProvaFuoco.calcola(.mercati(calo: 45), base: base)?.perditaTotale ?? -1
            verifica.vero("P16 Mercati −45% perdono più di −25%", m45 >= m25 && m25 > 0)
            verifica.vero("P16 Tassi e mercati: nessun guadagno", esiti.prefix(2).allSatisfy { $0.perditaTotale >= 0 })
            let msPrepara = Double(preparata - inizio) / 1_000_000
            let msPasso = Double(fine - preparata) / 1_000_000 / Double(scenari.count)
            print("Prova del fuoco su \(d.clienti.count) clienti: preparazione \(String(format: "%.1f", msPrepara)) ms, passo del cursore \(String(format: "%.2f", msPasso)) ms")
            verifica.vero("P16 Carico: un passo del cursore sotto i 50 ms con \(d.clienti.count) clienti", msPasso < 50)
        }
    }
}
