import Foundation

/// Prove delle pratiche dopo la firma (Design/template-luce-specifica.md §7.3, «Luce» giro 3): ogni passo riconosciuto dai
/// dati (e quando no), il segno a mano che vince anche quando toglie, la soglia (ferma all'ottavo giorno con 7), «4 di 6»,
/// «✓ Completata», i passi non pertinenti, le concluse del mese scorso a cavallo d'anno, l'ordine, le etichette
/// dell'indipendente, la nota di Marco dei dati di prova, la nascita della pratica, il sollecito e il tempo lineare.
/// Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliPratiche {
    static func esegui(_ verifica: VerificaCalcoli) {
        riconoscimenti(verifica)
        segnoAMano(verifica)
        soglia(verifica)
        conteggi(verifica)
        meseScorso(verifica)
        ordine(verifica)
        etichette(verifica)
        datiDiProva(verifica)
        nascitaESollecito(verifica)
        carico(verifica)
    }

    private static let cal = Calendar(identifier: .gregorian)
    private static func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }
    /// Oggi delle prove: 20 novembre 2026, mezzogiorno.
    private static let oggi = d(2026, 11, 20)

    /// Un archivio minimo: un cliente, una posizione accettata (Alleanza) e la sua pratica aperta il 10 novembre.
    private static func archivio(canale: Canale = .alleanza, _ modifica: (inout DatiPrisma) -> Void = { _ in }) -> DatiPrisma {
        let c = Cliente(id: "cliente-pratica", nome: "Cliente di prova", iniziali: "CP", tinta: .blu, tema: "", email: "",
                        telefono: "", preferito: false, nota: "", creatoIl: d(2020, 1, 1))
        var p = Posizione(clienteId: c.id, canale: canale, stato: .inEssere, area: .risparmio, nome: "Piano di prova")
        p.id = "pos-pratica"
        p.esito = .accettata
        var dati = DatiPrisma(clienti: [c], appuntamenti: [], attivita: [], posizioni: [p], clienteAttivoId: c.id,
                              impostazioni: Impostazioni())
        dati.pratiche = [Pratica(id: "pratica-1", posizioneId: p.id, apertaIl: d(2026, 11, 10))]
        modifica(&dati)
        return dati
    }

    private static func stato(_ dati: DatiPrisma, oggi: Date = oggi) -> StatoPratica? {
        MotorePratiche.stati(dati, oggi: oggi, calendario: cal).first
    }

    private static func fatto(_ s: StatoPratica?, _ p: PassoPratica) -> Bool {
        s?.passi.first { $0.passo == p }?.fatto ?? false
    }

    private static func origine(_ s: StatoPratica?, _ p: PassoPratica) -> OriginePasso? {
        s?.passi.first { $0.passo == p }?.origine
    }

    // MARK: 1. Riconoscimento dai dati

    private static func riconoscimenti(_ verifica: VerificaCalcoli) {
        let vuota = stato(archivio())
        verifica.vero("Pratiche: senza dati nessun passo è fatto", vuota?.fatti == 0 && vuota?.totale == 6)
        verifica.vero("Pratiche: «Moduli completi» mai riconosciuto da solo", !fatto(vuota, .moduli))

        // Documenti informativi: tutte le voci del canale consegnate nella scheda di adeguatezza
        let conScheda = archivio { dati in
            var s = SchedaAdeguatezza(posizioneId: "pos-pratica", clienteId: "cliente-pratica", creataIl: d(2026, 11, 1))
            let voci = MotoreAdeguatezza.documenti(dati.posizioni[0], voci: dati.impostazioni.consegna.voci, tipo:
                MotoreEsperienza.classifica(dati.posizioni[0])?.tipo, sostituzione: false)
            for (i, v) in voci.enumerated() { s.consegne.append(ConsegnaDocumento(voceId: v.id, consegnatoIl: d(2026, 11, 5 + i % 3))) }
            dati.schedeAdeguatezza = [s]
        }
        let sd = stato(conScheda)
        verifica.vero("Pratiche: documenti informativi riconosciuti dalle consegne complete", fatto(sd, .documentiInformativi))
        verifica.vero("Pratiche: la data dei documenti è l'ultima consegna",
                      sd?.passi.first { $0.passo == .documentiInformativi }?.data == d(2026, 11, 7))
        let incompleta = archivio { dati in
            var s = SchedaAdeguatezza(posizioneId: "pos-pratica", clienteId: "cliente-pratica", creataIl: d(2026, 11, 1))
            if let v = MotoreAdeguatezza.documenti(dati.posizioni[0], voci: dati.impostazioni.consegna.voci, tipo:
                MotoreEsperienza.classifica(dati.posizioni[0])?.tipo, sostituzione: false).first {
                s.consegne = [ConsegnaDocumento(voceId: v.id, consegnatoIl: d(2026, 11, 5))]
            }
            dati.schedeAdeguatezza = [s]
        }
        verifica.vero("Pratiche: consegne incomplete, documenti non riconosciuti", !fatto(stato(incompleta), .documentiInformativi))

        // Documento d'identità: in Conformità con la scadenza futura sì, scaduto no; documento della categoria sì
        func conDocumento(scade: Date) -> DatiPrisma {
            archivio { dati in
                var k = ConformitaCliente()
                k.documento = DocumentoIdentita(tipo: nil, numero: "AB123", rilasciatoIl: d(2020, 1, 1), scadenza: scade)
                dati.clienti[0].conformita = k
            }
        }
        verifica.vero("Pratiche: documento d'identità valido riconosciuto", fatto(stato(conDocumento(scade: d(2030, 1, 1))), .documentoIdentita))
        verifica.vero("Pratiche: documento d'identità scaduto non riconosciuto", !fatto(stato(conDocumento(scade: d(2026, 11, 1))), .documentoIdentita))
        let carta = archivio { dati in
            var doc = Documento(clienteId: "cliente-pratica", titolo: "Carta d'identità", tipo: .altro)
            doc.categoria = .identita
            doc.importatoIl = d(2026, 11, 12)
            dati.documenti = [doc]
        }
        verifica.vero("Pratiche: documento della categoria «Documenti d'identità» riconosciuto", fatto(stato(carta), .documentoIdentita))

        // Primo premio: movimento positivo dal giorno della firma; prima della firma o negativo no
        func conMovimento(_ data: Date, _ importo: Double) -> DatiPrisma {
            archivio { $0.posizioni[0].movimenti = [Movimento(data: data, importo: importo)] }
        }
        let premio = stato(conMovimento(d(2026, 11, 14), 150))
        verifica.vero("Pratiche: movimento positivo dopo la firma → primo premio", fatto(premio, .primoPremio))
        verifica.vero("Pratiche: la data del primo premio è quella del movimento",
                      premio?.passi.first { $0.passo == .primoPremio }?.data == d(2026, 11, 14))
        verifica.vero("Pratiche: movimento prima della firma non conta", !fatto(stato(conMovimento(d(2026, 11, 2), 150)), .primoPremio))
        verifica.vero("Pratiche: movimento negativo non conta", !fatto(stato(conMovimento(d(2026, 11, 14), -150)), .primoPremio))

        // Polizza emessa: numero di contratto (senza data) o documento di polizza della posizione
        let numero = stato(archivio { $0.posizioni[0].numeroContratto = "AL-2026-1" })
        verifica.vero("Pratiche: numero di contratto → polizza emessa", fatto(numero, .polizzaEmessa))
        verifica.vero("Pratiche: dal numero di contratto nessuna data inventata",
                      numero?.passi.first { $0.passo == .polizzaEmessa }?.data == nil
                      && origine(numero, .polizzaEmessa) == .riconosciuto(da: TestiPratiche.daNumeroContratto))
        let documento = stato(archivio { dati in
            var doc = Documento(clienteId: "cliente-pratica", titolo: "Polizza", tipo: .polizza)
            doc.posizioneId = "pos-pratica"
            doc.importatoIl = d(2026, 11, 15)
            dati.documenti = [doc]
        })
        verifica.vero("Pratiche: documento di polizza della posizione → polizza emessa con la sua data",
                      fatto(documento, .polizzaEmessa) && documento?.passi.first { $0.passo == .polizzaEmessa }?.data == d(2026, 11, 15))
        let vecchio = stato(archivio { dati in
            var doc = Documento(clienteId: "cliente-pratica", titolo: "Polizza dell'anno scorso", tipo: .polizza)
            doc.posizioneId = "pos-pratica"
            doc.importatoIl = d(2025, 11, 15)
            dati.documenti = [doc]
        })
        verifica.vero("Pratiche: un documento di polizza di prima della firma non conta", !fatto(vecchio, .polizzaEmessa))
        verifica.vero("Pratiche: «Consegnata» mai riconosciuta da sola", !fatto(numero, .consegnata))
    }

    // MARK: 2. Il segno a mano vince

    private static func segnoAMano(_ verifica: VerificaCalcoli) {
        let tolto = stato(archivio { dati in
            dati.posizioni[0].numeroContratto = "AL-2026-1"
            dati.pratiche[0].passi[PassoPratica.polizzaEmessa.rawValue] = SegnoPasso(fatto: false, il: d(2026, 11, 16))
        })
        verifica.vero("Pratiche: il segno a mano toglie un passo riconosciuto", !fatto(tolto, .polizzaEmessa))
        verifica.vero("Pratiche: il passo tolto dice cosa riconoscerebbe Prisma",
                      origine(tolto, .polizzaEmessa) == .toltoAMano(riconoscibile: TestiPratiche.daNumeroContratto))
        let segnato = stato(archivio { $0.pratiche[0].passi[PassoPratica.moduli.rawValue] = SegnoPasso(fatto: true, il: d(2026, 11, 11)) })
        verifica.vero("Pratiche: il segno a mano fa un passo", fatto(segnato, .moduli) && origine(segnato, .moduli) == .aMano)
        // Segnare l'ultimo passo scrive la conclusione; toglierlo la cancella
        var dati = archivio()
        for p in PassoPratica.allCases { dati.pratiche[0].passi[p.rawValue] = SegnoPasso(fatto: true, il: d(2026, 11, 12)) }
        dati.pratiche[0].passi[PassoPratica.consegnata.rawValue] = nil
        var pr = dati.pratiche[0]
        MotorePratiche.segna(.consegnata, fatto: true, il: d(2026, 11, 18), pratica: &pr, dati: dati, oggi: oggi, calendario: cal)
        verifica.vero("Pratiche: l'ultimo passo segnato scrive la data di conclusione", pr.conclusaIl == d(2026, 11, 18))
        dati.pratiche[0] = pr
        MotorePratiche.segna(.consegnata, fatto: false, il: d(2026, 11, 19), pratica: &pr, dati: dati, oggi: oggi, calendario: cal)
        verifica.vero("Pratiche: togliere un passo cancella la conclusione", pr.conclusaIl == nil)
        MotorePratiche.togliSegno(.consegnata, pratica: &pr, dati: dati, oggi: oggi, calendario: cal)
        verifica.vero("Pratiche: «Torna ai dati» toglie il segno a mano", pr.segno(.consegnata) == nil)
    }

    // MARK: 3. Soglia

    private static func soglia(_ verifica: VerificaCalcoli) {
        func conUltimo(_ giorniFa: Int) -> StatoPratica? {
            let ultimo = cal.date(byAdding: .day, value: -giorniFa, to: oggi) ?? oggi
            return stato(archivio { dati in
                dati.pratiche[0].apertaIl = d(2026, 10, 1)
                dati.pratiche[0].passi[PassoPratica.moduli.rawValue] = SegnoPasso(fatto: true, il: ultimo)
            })
        }
        let otto = conUltimo(8), sette = conUltimo(7)
        verifica.vero("Pratiche: ultimo passo 8 giorni fa → ferma (soglia 7)", otto?.ferma == true)
        verifica.vero("Pratiche: ultimo passo 7 giorni fa → non ferma", sette?.ferma == false)
        verifica("Pratiche: giorni da fermo", Double(otto?.giorniFermo ?? 0), 8)
        verifica.vero("Pratiche: il passo di adesso di una ferma è bloccato",
                      otto?.passi.first { !$0.fatto }?.stato == .bloccato && sette?.passi.first { !$0.fatto }?.stato == .adesso)
        verifica.vero("Pratiche: dopo il passo di adesso i passi sono futuri",
                      otto?.passi.filter { $0.stato == .futuro }.count == 4)
        let soglia3 = stato(archivio { dati in
            dati.impostazioni.pratiche.giorniFerma = 3
            dati.pratiche[0].apertaIl = d(2026, 11, 16)
        })
        verifica.vero("Pratiche: la soglia viene dalle impostazioni (3 giorni, aperta 4 giorni fa → ferma)", soglia3?.ferma == true)
        // Senza passi fatti la fermata si conta dall'apertura; un passo senza data non la sposta
        let senzaData = stato(archivio { dati in
            dati.pratiche[0].apertaIl = d(2026, 11, 1)
            dati.posizioni[0].numeroContratto = "AL-1"
        })
        verifica("Pratiche: la fermata si misura dall'ultima data nota", Double(senzaData?.giorniFermo ?? 0), 19)
    }

    // MARK: 4. Conteggi

    private static func conteggi(_ verifica: VerificaCalcoli) {
        let quattro = stato(archivio { dati in
            for p in [PassoPratica.moduli, .documentiInformativi, .documentoIdentita, .primoPremio] {
                dati.pratiche[0].passi[p.rawValue] = SegnoPasso(fatto: true, il: d(2026, 11, 17))
            }
        })
        verifica.vero("Pratiche: stato «4 di 6»", quattro?.testoStato == "4 di 6")
        verifica.vero("Pratiche: adesso = polizza emessa, nota del template",
                      quattro?.mancante == .polizzaEmessa && quattro?.nota == "Emissione in corso presso la compagnia")
        verifica.vero("Pratiche: manca l'emissione → «Sollecita la compagnia»", quattro?.sollecitoCompagnia == true)
        let tutti = stato(archivio { dati in
            for p in PassoPratica.allCases { dati.pratiche[0].passi[p.rawValue] = SegnoPasso(fatto: true, il: d(2026, 10, 28)) }
        })
        verifica.vero("Pratiche: tutti fatti → conclusa, «✓ Completata»", tutti?.conclusa == true && tutti?.testoStato == "✓ Completata")
        verifica.vero("Pratiche: una conclusa non è mai ferma", tutti?.ferma == false)
        verifica.vero("Pratiche: «Completata il 28 ottobre»", tutti?.nota == "Completata il 28 ottobre")
        let senzaPremio = stato(archivio { dati in
            dati.pratiche[0].nonPertinenti = [PassoPratica.primoPremio.rawValue]
            for p in [PassoPratica.moduli, .documentiInformativi, .documentoIdentita] {
                dati.pratiche[0].passi[p.rawValue] = SegnoPasso(fatto: true, il: d(2026, 11, 17))
            }
        })
        verifica.vero("Pratiche: un passo non pertinente riduce il totale («3 di 5»)", senzaPremio?.testoStato == "3 di 5")
        verifica.vero("Pratiche: il passo non pertinente esce dalla linea", senzaPremio?.passi.contains { $0.passo == .primoPremio } == false)
        let consegna = stato(archivio { dati in
            for p in PassoPratica.allCases where p != .consegnata {
                dati.pratiche[0].passi[p.rawValue] = SegnoPasso(fatto: true, il: d(2026, 11, 17))
            }
        })
        verifica.vero("Pratiche: da consegnare, frase neutra", consegna?.nota == "Da consegnare al cliente")
    }

    // MARK: 5. Mese scorso a cavallo d'anno

    private static func meseScorso(_ verifica: VerificaCalcoli) {
        func conclusa(_ data: Date) -> StatoPratica? {
            stato(archivio { dati in
                for p in PassoPratica.allCases { dati.pratiche[0].passi[p.rawValue] = SegnoPasso(fatto: true, il: data) }
                dati.pratiche[0].apertaIl = d(2026, 11, 1)
            }, oggi: d(2027, 1, 3))
        }
        let gennaio = d(2027, 1, 3)
        let dicembre = [conclusa(d(2026, 12, 15))].compactMap { $0 }
        let r = MotorePratiche.riepilogo(dicembre, soglia: 7, oggi: gennaio, calendario: cal)
        verifica("Pratiche: il 3 gennaio contano le concluse di dicembre dell'anno prima", Double(r.concluseMeseScorso), 1)
        verifica.vero("Pratiche: il mese scorso si chiama «dicembre»", r.meseScorso == "dicembre")
        let diGennaio = [conclusa(d(2027, 1, 2))].compactMap { $0 }
        verifica("Pratiche: le concluse di gennaio non contano il 3 gennaio",
                 Double(MotorePratiche.riepilogo(diGennaio, soglia: 7, oggi: gennaio, calendario: cal).concluseMeseScorso), 0)
        let vecchie = [conclusa(d(2025, 12, 15))].compactMap { $0 }
        verifica("Pratiche: il dicembre di due anni fa non conta",
                 Double(MotorePratiche.riepilogo(vecchie, soglia: 7, oggi: gennaio, calendario: cal).concluseMeseScorso), 0)
    }

    // MARK: 6. Ordine

    private static func ordine(_ verifica: VerificaCalcoli) {
        var dati = archivio()
        let base = dati.posizioni[0]
        func posizione(_ id: String) -> Posizione { var p = base; p.id = id; return p }
        dati.posizioni = ["a", "b", "c", "d"].map(posizione)
        func pratica(_ id: String, aperta: Date, fatti: [PassoPratica]) -> Pratica {
            var p = Pratica(id: id, posizioneId: id, apertaIl: aperta)
            for f in fatti { p.passi[f.rawValue] = SegnoPasso(fatto: true, il: aperta) }
            return p
        }
        dati.pratiche = [
            pratica("a", aperta: d(2026, 11, 18), fatti: [.moduli, .documentiInformativi, .documentoIdentita]), // aperta, passo 3
            pratica("b", aperta: d(2026, 10, 1), fatti: PassoPratica.allCases),                                  // conclusa
            pratica("c", aperta: d(2026, 11, 19), fatti: [.moduli]),                                              // aperta, passo 1
            pratica("d", aperta: d(2026, 11, 1), fatti: [.moduli]),                                               // ferma
        ]
        let ordine = MotorePratiche.stati(dati, oggi: oggi, calendario: cal).map(\.id)
        verifica.vero("Pratiche: ordine ferme, poi per passo, poi concluse", ordine == ["d", "c", "a", "b"])
        var senzaPosizione = dati
        senzaPosizione.posizioni.removeAll { $0.id == "a" }
        verifica("Pratiche: una pratica senza posizione si salta", Double(MotorePratiche.stati(senzaPosizione, oggi: oggi).count), 3)
    }

    // MARK: 7. Etichette dell'indipendente

    private static func etichette(_ verifica: VerificaCalcoli) {
        let s = stato(archivio(canale: .indipendente))
        verifica.vero("Pratiche: passi dell'indipendente (D3.1)",
                      s?.passi.map(\.etichetta) == ["Moduli completi", "Documenti informativi", "Documento d'identità",
                                                    "Primo versamento", "Conferma dell'investimento", "Consegnata"])
        verifica.vero("Pratiche: passi di Alleanza",
                      stato(archivio())?.passi.map(\.etichetta) == ["Moduli completi", "Documenti informativi", "Documento d'identità",
                                                                     "Primo premio", "Polizza emessa", "Consegnata al cliente"])
    }

    // MARK: 8. I dati di prova

    private static func datiDiProva(_ verifica: VerificaCalcoli) {
        let demo = DatiPrisma.demo()
        let stati = MotorePratiche.stati(demo)
        verifica("Pratiche di prova: quattro, tutte su posizioni esistenti", Double(stati.count), 4)
        verifica.vero("Pratiche di prova: segnate «dati di prova»", demo.pratiche.allSatisfy(\.diProva))
        let marco = stati.first { $0.clienteId == "marco" }
        verifica.vero("Pratiche di prova: Marco «Fermo da 9 giorni: manca il primo premio»",
                      marco?.nota == "Fermo da 9 giorni: manca il primo premio" && marco?.testoStato == "3 di 6")
        verifica.vero("Pratiche di prova: Marco ferma in testa", stati.first?.clienteId == "marco")
        let giulia = stati.first { $0.clienteId == "giulia" }
        verifica.vero("Pratiche di prova: Giulia 4 di 6, emissione in corso",
                      giulia?.testoStato == "4 di 6" && giulia?.nota == "Emissione in corso presso la compagnia")
        let laura = stati.first { $0.clienteId == "laura" }
        verifica.vero("Pratiche di prova: Laura indipendente 5 di 6, da consegnare",
                      laura?.canale == .indipendente && laura?.testoStato == "5 di 6" && laura?.nota == "Da consegnare al cliente")
        let r = MotorePratiche.riepilogo(stati, soglia: demo.impostazioni.pratiche.giorniFerma)
        verifica.vero("Pratiche di prova: tile 3 aperte, 1 ferma, 1 conclusa il mese scorso",
                      r.aperte == 3 && r.ferme == 1 && r.concluseMeseScorso == 1)
        verifica.vero("Pratiche di prova: anche nei 35 clienti di prova", ClientiFittizi.completi().pratiche.count == 4)
    }

    // MARK: Nascita e sollecito

    private static func nascitaESollecito(_ verifica: VerificaCalcoli) {
        let dati = archivio()
        var accettata = dati.posizioni[0]
        accettata.id = "pos-nuova"
        verifica.vero("Pratiche: una proposta accettata apre la sua pratica",
                      MotorePratiche.nuova(per: accettata, esistenti: dati.pratiche, il: oggi)?.posizioneId == "pos-nuova")
        verifica.vero("Pratiche: mai una seconda pratica per la stessa posizione",
                      MotorePratiche.nuova(per: dati.posizioni[0], esistenti: dati.pratiche, il: oggi) == nil)
        var rifiutata = accettata
        rifiutata.esito = .rifiutata
        verifica.vero("Pratiche: una proposta non accettata non apre pratiche",
                      MotorePratiche.nuova(per: rifiutata, esistenti: [], il: oggi) == nil)
        // Il sollecito: una sola occasione per pratica e passo, con il passo che manca
        let marco = MotorePratiche.stati(DatiPrisma.demo()).first { $0.clienteId == "marco" }
        if let m = marco, let o = MotorePratiche.occasioneSollecito(m, oggi: Date()) {
            verifica.vero("Pratiche: il sollecito è un'occasione «pratica» con il passo che manca",
                          o.tipo == .pratica && o.origine.riferimento == "\(m.id)-primoPremio"
                          && o.valore(.passoPratica) == "il primo premio" && o.inRitardo)
            verifica.vero("Pratiche: il sollecito non è commerciale", !o.tipo.commerciale)
            let cliente = DatiPrisma.demo().clienti.first { $0.id == "marco" } ?? Cliente.nuovo(tinta: .blu)
            let testo = ModelliMessaggi.testo(o, tono: .cordiale, canale: .mail, cliente: cliente, firma: "Denis").completo
            verifica.vero("Pratiche: il testo del sollecito dice cosa manca", testo.contains("manca ancora il primo premio"))
        } else {
            verifica.vero("Pratiche: il sollecito di Marco", false)
        }
        let conclusa = stato(archivio { dati in
            for p in PassoPratica.allCases { dati.pratiche[0].passi[p.rawValue] = SegnoPasso(fatto: true, il: d(2026, 11, 12)) }
        })
        verifica.vero("Pratiche: nessun sollecito per una pratica conclusa",
                      conclusa.flatMap { MotorePratiche.occasioneSollecito($0, oggi: oggi) } == nil)
    }

    // MARK: 9. Tempo lineare

    private static func carico(_ verifica: VerificaCalcoli) {
        // 200 clienti con una pratica ciascuna e 4 documenti a testa: gli indici si costruiscono una volta sola
        var dati = archivio()
        let base = dati.posizioni[0]
        var posizioni: [Posizione] = []
        var pratiche: [Pratica] = []
        var documenti: [Documento] = []
        for i in 0..<200 {
            var p = base
            p.id = "pos-\(i)"
            p.clienteId = "cliente-\(i)"
            posizioni.append(p)
            pratiche.append(Pratica(id: "pratica-\(i)", posizioneId: p.id, apertaIl: d(2026, 11, 1)))
            for k in 0..<4 {
                var doc = Documento(clienteId: p.clienteId, titolo: "Documento \(k)", tipo: k == 0 ? .polizza : .altro)
                doc.posizioneId = p.id
                documenti.append(doc)
            }
        }
        dati.posizioni = posizioni
        dati.pratiche = pratiche
        dati.documenti = documenti
        let inizio = Date()
        let stati = MotorePratiche.stati(dati, oggi: oggi, calendario: cal)
        let durata = Date().timeIntervalSince(inizio)
        verifica("Pratiche: 200 pratiche calcolate", Double(stati.count), 200)
        verifica.vero("Pratiche: 200 pratiche in meno di mezzo secondo", durata < 0.5)
    }
}
