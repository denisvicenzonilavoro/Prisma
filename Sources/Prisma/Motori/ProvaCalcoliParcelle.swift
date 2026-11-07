import Foundation

/// Prove di Parcelle e fatture (chiamate da `ProvaCalcoli.esegui()`, cioè da `Prisma --prova-calcoli`): casi costruiti a
/// mano, oggi fisso al 3 novembre 2026.
/// I regimi usati qui sono REGIMI DI PROVA DICHIARATI (`ProvaFatturaPA.regimeDiProvaConIVA` e `regimeDiProvaSenzaIVA`, più
/// le varianti scritte sotto): servono a provare le formule e il tracciato, non scelgono il regime del consulente.
/// Consulente, cliente, partita IVA, codici fiscali e IBAN sono fittizi (ProvaFatturaPA.swift).
enum ProvaCalcoliParcelle {
    static func esegui(_ verifica: VerificaCalcoli) {
        let cal = Calendar(identifier: .gregorian)
        let oggi = AiutiProva.data(2026, 11, 3)
        func d(_ a: Int, _ m: Int, _ g: Int) -> Date { AiutiProva.data(a, m, g) }
        func parcella(_ id: String, _ importo: Double, _ stato: StatoParcella, anno: Int = 2026, progressivo: Int? = nil,
                      data: Date? = nil, incassata: Date? = nil, scadenza: Date? = nil) -> Parcella {
            var p = Parcella(id: id, clienteId: "anna", data: data ?? d(anno, 2, 1),
                             righe: [RigaParcella(id: "\(id)-1", descrizione: "Consulenza", importo: importo)], anno: anno, cal: cal)
            p.stato = stato
            if stato.numerata {
                p.progressivo = progressivo ?? 1
                p.numero = "\(anno)/\(progressivo ?? 1)"
            }
            p.incassataIl = incassata
            p.scadenza = scadenza
            return p
        }

        // 1. Totali: 2 pagate nell'anno, 1 pagata l'anno prima, 2 da incassare (una scaduta), 1 bozza, 1 annullata
        let elenco = [
            parcella("a", 1_000, .pagata, progressivo: 1, incassata: d(2026, 3, 10)),
            parcella("b", 500, .pagata, progressivo: 2, incassata: d(2026, 6, 1)),
            parcella("c", 700, .pagata, anno: 2025, progressivo: 9, incassata: d(2025, 12, 20)),
            parcella("e1", 300, .emessa, progressivo: 3, scadenza: d(2026, 10, 1)),
            parcella("e2", 200, .emessa, progressivo: 4, scadenza: d(2026, 12, 1)),
            parcella("bz", 999, .bozza),
            parcella("an", 400, .annullata, progressivo: 5),
        ]
        let t = MotoreParcelle.totali(elenco, anno: 2026, oggi: oggi, cal: cal)
        verifica("Parcelle: incassato nel 2026", t.incassato, 1_500)
        verifica("Parcelle: da incassare nel 2026", t.daIncassare, 500)
        verifica("Parcelle: da incassare in tutto", t.daIncassareInTutto, 500)
        verifica("Parcelle: scadute", Double(t.scadute), 1)
        verifica("Parcelle: importo scaduto", t.importoScaduto, 300)
        verifica.vero("Parcelle: conteggi per stato (bozza e annullata escluse dai totali)",
                      t.bozze == 1 && t.emesse == 2 && t.pagate == 2 && t.annullate == 1)
        verifica("Parcelle: senza voci fiscali (importo provvisorio)", Double(t.senzaVoci), 4)
        verifica.vero("Parcelle: scaduta solo la emessa con la scadenza passata",
                      MotoreParcelle.scadute(elenco, oggi: oggi, cal: cal).map(\.id) == ["e1"])
        let t2025 = MotoreParcelle.totali(elenco, anno: 2025, oggi: oggi, cal: cal)
        verifica("Parcelle: incassato nel 2025", t2025.incassato, 700)

        // 2. Ricavi per il Cruscotto: pagate alla data d'incasso, emesse alla scadenza; bozze e annullate no
        let ricavi = MotoreParcelle.ricaviConsulenza(elenco)
        verifica("Parcelle: ricavi per il Cruscotto", Double(ricavi.count), 5)
        verifica("Parcelle: ricavi incassati", ricavi.filter(\.incassata).reduce(0) { $0 + $1.importo }, 2_200)
        verifica.vero("Parcelle: ricavo da incassare alla scadenza",
                      ricavi.contains { !$0.incassata && $0.importo == 300 && cal.isDate($0.data, inSameDayAs: d(2026, 10, 1)) })
        let cruscotto = MotoreStudio.calcola(clienti: [Cliente(id: "anna", nome: "Anna", iniziali: "AN", tinta: .blu, tema: "",
                                                               email: "", telefono: "", preferito: false, nota: "",
                                                               creatoIl: d(2020, 1, 1))],
                                             posizioni: [], appuntamenti: [], incontri: [], studio: ImpostazioniStudio(),
                                             parcelle: ricavi, oggi: oggi, cal: cal)
        // Ricavi del 2026 fino a oggi: 1.000 + 500 incassate + 300 scaduta il 1° ottobre
        verifica("Parcelle: ricavi della consulenza nel Cruscotto", cruscotto.ricavi.indipendente, 1_800)

        // 3. Numerazione: progressiva per anno, senza buchi; la bozza non ha numero; annullate comprese
        var n = NumerazioneFatture()
        verifica("Parcelle: prossimo numero del 2026", Double(MotoreParcelle.prossimoProgressivo(elenco, anno: 2026, numerazione: n)), 6)
        verifica("Parcelle: a gennaio si riparte da 1", Double(MotoreParcelle.prossimoProgressivo(elenco, anno: 2027, numerazione: n)), 1)
        n.primoNumeroPerAnno[2027] = 10
        verifica("Parcelle: numero di partenza scelto per l'anno", Double(MotoreParcelle.prossimoProgressivo(elenco, anno: 2027, numerazione: n)), 10)
        n.modello = "{anno}/{numero:3}"
        verifica.vero("Parcelle: numero «2026/006»", MotoreParcelle.prossimoNumero(elenco, anno: 2026, numerazione: n) == "2026/006")
        var p2 = NumerazioneFatture()
        p2.prefisso = "P-"
        verifica.vero("Parcelle: prefisso senza modello", MotoreParcelle.numeroTesto(progressivo: 7, anno: 2026, numerazione: p2) == "P-7")
        p2.modello = "{prefisso}{numero}/{anno}"
        verifica.vero("Parcelle: modello con prefisso", MotoreParcelle.numeroTesto(progressivo: 12, anno: 2026, numerazione: p2) == "P-12/2026")
        let bozza = parcella("nuova", 100, .bozza)
        verifica.vero("Parcelle: la bozza non ha numero", bozza.numero == nil && bozza.progressivo == nil)
        let emessa = MotoreParcelle.emessa(bozza, tra: elenco, data: d(2026, 11, 3), numerazione: n, regime: RegimeFatturazione(), cal: cal)
        verifica.vero("Parcelle: all'emissione prende il numero 2026/006",
                      emessa.stato == .emessa && emessa.progressivo == 6 && emessa.numero == "2026/006" && emessa.anno == 2026)
        verifica.vero("Parcelle: senza regime le voci restano vuote (importo provvisorio)", emessa.voci == nil)
        verifica.vero("Parcelle: una parcella già emessa non cambia",
                      MotoreParcelle.emessa(emessa, tra: elenco, data: d(2026, 12, 1), numerazione: n, regime: RegimeFatturazione(), cal: cal) == emessa)
        verifica.vero("Parcelle: progressivo d'invio di 5 caratteri",
                      MotoreParcelle.progressivoInvio(1) == "00001" && MotoreParcelle.progressivoInvio(36) == "00010")

        // 4. Regime vuoto: nessuna cifra, l'elenco di ciò che manca
        let righe = [RigaParcella(id: "r1", descrizione: "Analisi", importo: 1_000), RigaParcella(id: "r2", descrizione: "Relazione", importo: 250.50)]
        let vuoto = MotoreFattura.calcola(righe: righe, regime: RegimeFatturazione())
        let codici = Set(vuoto.mancanti.map(\.codice))
        verifica.vero("Fattura: regime vuoto, nessuna cifra", vuoto.voci == nil)
        verifica.vero("Fattura: regime vuoto, mancano regime, IVA, cassa, ritenuta e bollo",
                      codici == ["regime.codice", "regime.iva", "regime.cassa", "regime.ritenuta", "regime.bollo"])
        var ambiguo = ProvaFatturaPA.regimeDiProvaConIVA()
        ambiguo.natura = .n2_2
        verifica.vero("Fattura: aliquota e natura insieme non vanno", MotoreFattura.calcola(righe: righe, regime: ambiguo).voci == nil)
        var senzaRif = ProvaFatturaPA.regimeDiProvaSenzaIVA()
        senzaRif.riferimentoNormativo = " "
        verifica.vero("Fattura: la natura vuole il riferimento normativo",
                      MotoreFattura.calcola(righe: righe, regime: senzaRif).mancanti.contains { $0.codice == "regime.riferimentoNormativo" })

        // 5. Regime di prova A (IVA 22%, contributo 4%, ritenuta 20%): 1.250,50 di righe
        if let v = MotoreFattura.calcola(righe: righe, regime: ProvaFatturaPA.regimeDiProvaConIVA()).voci {
            verifica("Fattura A: imponibile", v.imponibile, 1_250.50)
            verifica("Fattura A: contributo 4%", v.contributo ?? -1, 50.02)
            verifica("Fattura A: base IVA = imponibile + contributo", v.baseIVA, 1_300.52)
            verifica("Fattura A: IVA 22% arrotondata", v.iva ?? -1, 286.11)
            verifica("Fattura A: ritenuta 20% sull'imponibile", v.ritenuta ?? -1, 250.10)
            verifica("Fattura A: totale del documento (senza la ritenuta)", v.totaleDocumento, 1_586.63)
            verifica("Fattura A: netto a pagare", v.nettoAPagare, 1_336.53)
            verifica.vero("Fattura A: niente bollo, un riepilogo, righe con la ritenuta",
                          v.bollo == nil && v.riepiloghi.count == 1 && v.linee.count == 2 && v.linee.allSatisfy(\.ritenuta))
        } else {
            verifica.vero("Fattura A: voci calcolate", false)
        }

        // 6. Regime di prova B (natura N2.2, contributo 4%, bollo di prova 2 € sopra 77,47 € addebitato con la natura N1)
        let regimeB = ProvaFatturaPA.regimeDiProvaSenzaIVA()
        if let v = MotoreFattura.calcola(righe: [RigaParcella(descrizione: "Consulenza", importo: 500)], regime: regimeB).voci {
            verifica("Fattura B: contributo", v.contributo ?? -1, 20)
            verifica.vero("Fattura B: senza IVA (natura)", v.iva == nil && v.natura == .n2_2 && v.aliquotaIVA == nil)
            verifica("Fattura B: bollo dovuto sopra la soglia", v.bollo ?? -1, 2)
            verifica("Fattura B: totale con il bollo addebitato", v.totaleDocumento, 522)
            verifica("Fattura B: netto a pagare uguale al totale", v.nettoAPagare, 522)
            verifica.vero("Fattura B: riga e riepilogo del bollo con la sua natura",
                          v.linee.count == 2 && v.linee.last?.bollo == true && v.riepiloghi.count == 2
                            && v.riepiloghi.last?.natura == .n1 && v.riepiloghi.last?.imponibile == 2)
        } else {
            verifica.vero("Fattura B: voci calcolate", false)
        }
        if let v = MotoreFattura.calcola(righe: [RigaParcella(descrizione: "Consulenza", importo: 50)], regime: regimeB).voci {
            verifica.vero("Fattura B: sotto la soglia niente bollo", v.bollo == nil && v.totaleDocumento == 52)
        } else {
            verifica.vero("Fattura B sotto soglia: voci calcolate", false)
        }
        var stessaNatura = regimeB
        stessaNatura.bollo.naturaRiga = .n2_2
        if let v = MotoreFattura.calcola(righe: [RigaParcella(descrizione: "Consulenza", importo: 500)], regime: stessaNatura).voci {
            verifica.vero("Fattura B: bollo con la stessa natura nello stesso riepilogo",
                          v.riepiloghi.count == 1 && v.riepiloghi[0].imponibile == 522)
        } else {
            verifica.vero("Fattura B stessa natura: voci calcolate", false)
        }
        var senzaAddebito = regimeB
        senzaAddebito.bollo.aCaricoCliente = false
        if let v = MotoreFattura.calcola(righe: [RigaParcella(descrizione: "Consulenza", importo: 500)], regime: senzaAddebito).voci {
            verifica.vero("Fattura B: bollo non addebitato fuori dal totale", v.bollo == 2 && v.totaleDocumento == 520 && v.linee.count == 1)
        } else {
            verifica.vero("Fattura B senza addebito: voci calcolate", false)
        }

        // 7. Ritenuta di prova del 23% sul 50% dell'imponibile, con il contributo soggetto a ritenuta
        var quota = ProvaFatturaPA.regimeDiProvaConIVA()
        quota.cassa.soggettoARitenuta = true
        quota.ritenuta = RitenutaAcconto(tipo: .rt01, aliquota: 23, causale: "A", quotaImponibile: 50)
        if let v = MotoreFattura.calcola(righe: [RigaParcella(descrizione: "Consulenza", importo: 1_000)], regime: quota).voci {
            // (500 + 40) × 23% = 124,20
            verifica("Fattura: ritenuta su quota e contributo", v.ritenuta ?? -1, 124.20)
        } else {
            verifica.vero("Fattura quota: voci calcolate", false)
        }
        // Senza nulla di applicato: totale = imponibile
        var nulla = RegimeFatturazione()
        nulla.regimeFiscale = .rf18
        nulla.natura = .n2_2
        nulla.riferimentoNormativo = "Riferimento di prova"
        nulla.applicaCassa = false
        nulla.applicaRitenuta = false
        nulla.applicaBollo = false
        if let v = MotoreFattura.calcola(righe: righe, regime: nulla).voci {
            verifica.vero("Fattura: senza IVA, contributo, ritenuta e bollo il totale è l'imponibile",
                          v.totaleDocumento == 1_250.50 && v.nettoAPagare == 1_250.50 && v.contributo == nil && v.ritenuta == nil)
        } else {
            verifica.vero("Fattura senza voci: calcolata", false)
        }

        // 8. Arrotondamenti al centesimo (metà per eccesso)
        verifica("Fattura: 1,005 € → 101 centesimi", Double(MotoreFattura.centesimi(1.005)), 101, tolleranza: 0)
        verifica("Fattura: 2,675 € → 268 centesimi", Double(MotoreFattura.centesimi(2.675)), 268, tolleranza: 0)
        verifica("Fattura: 22% di 0,05 € → 1 centesimo", Double(MotoreFattura.percentuale(5, 22)), 1, tolleranza: 0)
        verifica.vero("Fattura: importi con il punto e 2 decimali",
                      GeneratoreFatturaPA.importo(1_234.5) == "1234.50" && GeneratoreFatturaPA.importo(0) == "0.00"
                        && GeneratoreFatturaPA.importo(-3) == "-3.00" && GeneratoreFatturaPA.aliquotaTesto(22) == "22.00")
        verifica.vero("Fattura: data aaaa-mm-gg", GeneratoreFatturaPA.data(d(2026, 3, 5), cal: cal) == "2026-03-05")

        // 9. Voci congelate: cambiare il regime dopo l'emissione non cambia la parcella emessa
        let congelata = MotoreParcelle.emessa(parcella("cong", 1_000, .bozza), tra: [], data: d(2026, 11, 3), numerazione: n,
                                              regime: ProvaFatturaPA.regimeDiProvaConIVA(), cal: cal)
        let prima = congelata.voci?.totaleDocumento
        verifica.vero("Fattura: voci congelate all'emissione",
                      prima != nil && MotoreFattura.voci(congelata, regime: RegimeFatturazione()).voci?.totaleDocumento == prima)
        verifica("Parcelle: importo della emessa = netto a pagare", MotoreParcelle.importo(congelata), congelata.voci?.nettoAPagare ?? -1)

        // 10. Controlli formali
        verifica.vero("Fattura: partita IVA con la cifra di controllo",
                      MotoreFattura.partitaIVAValida("00000000000") && MotoreFattura.partitaIVAValida("01234567897")
                        && !MotoreFattura.partitaIVAValida("01234567890") && !MotoreFattura.partitaIVAValida("1234"))
        verifica.vero("Fattura: codice fiscale di 16 caratteri", MotoreFattura.codiceFiscaleValido("prvcln80a01h501z")
                        && !MotoreFattura.codiceFiscaleValido("PRVCLN80"))
        verifica.vero("Fattura: CAP, provincia, codice destinatario",
                      MotoreFattura.capValido("00000") && !MotoreFattura.capValido("0000A") && MotoreFattura.siglaValida("xx")
                        && MotoreFattura.codiceDestinatarioValido("0000000") && !MotoreFattura.codiceDestinatarioValido("ABC"))
        verifica.vero("Fattura: IBAN con il controllo modulo 97",
                      MotoreFattura.ibanValido("IT51 X000 0000 0000 0000 0000 001") && !MotoreFattura.ibanValido("IT52X0000000000000000000001"))

        // 11. Dati mancanti: consulente vuoto, cliente senza dati fiscali, bozza
        let cliente = ProvaFatturaPA.clienteDiProva()
        let consulente = ProvaFatturaPA.consulenteDiProva(regime: ProvaFatturaPA.regimeDiProvaConIVA())
        let vuotoConsulente = Set(MotoreFattura.mancantiConsulente(DatiFatturazione()).map(\.codice))
        verifica.vero("Fattura: senza dati del consulente mancano partita IVA, regime e trasmittente",
                      vuotoConsulente.isSuperset(of: ["consulente.anagrafica", "consulente.partitaIVA", "consulente.codiceFiscale",
                                                      "consulente.sede.indirizzo", "regime.codice", "regime.iva",
                                                      "consulente.modalita", "consulente.trasmittente"]))
        var pivaSbagliata = consulente
        pivaSbagliata.partitaIVA = "01234567890"
        verifica.vero("Fattura: partita IVA senza la cifra di controllo giusta",
                      MotoreFattura.mancantiConsulente(pivaSbagliata).map(\.codice) == ["consulente.partitaIVA"])
        verifica.vero("Fattura: consulente di prova completo", MotoreFattura.mancantiConsulente(consulente).isEmpty)
        var senzaFiscale = cliente
        senzaFiscale.fiscale = nil
        let mancaCliente = Set(MotoreFattura.mancantiCliente(senzaFiscale).map(\.codice))
        verifica.vero("Fattura: cliente senza dati per la fattura",
                      mancaCliente.isSuperset(of: ["cliente.anagrafica", "cliente.codiceDestinatario", "cliente.sede.indirizzo", "cliente.sede.cap"]))
        verifica.vero("Fattura: cliente di prova completo", MotoreFattura.mancantiCliente(cliente).isEmpty)
        let soloBozza = parcella("bozza-xml", 100, .bozza)
        let senzaNumero = GeneratoreFatturaPA.genera(parcella: soloBozza, cliente: cliente, consulente: consulente, progressivoInvio: "00001")
        verifica.vero("Fattura: la bozza non ha il file XML", senzaNumero.file == nil
                        && senzaNumero.mancanti.contains { $0.codice == "parcella.numero" })
        var consulenteSenzaPIVA = consulente
        consulenteSenzaPIVA.partitaIVA = ""
        let senzaPIVA = GeneratoreFatturaPA.genera(parcella: congelata, cliente: cliente, consulente: consulenteSenzaPIVA,
                                                   progressivoInvio: "00001")
        verifica.vero("Fattura: senza partita IVA nessun file", senzaPIVA.file == nil
                        && senzaPIVA.mancanti.contains { $0.codice == "consulente.partitaIVA" })

        // 12. Il file XML degli esempi: si rilegge, ha i nodi obbligatori, le somme tornano, escape e nome giusti
        let esempi = ProvaFatturaPA.esempi()
        verifica("Fattura XML: esempi pronti", Double(esempi.compactMap(\.file).count), 2)
        if let a = esempi.first?.file {
            let l = LettoreFatturaXML()
            verifica.vero("Fattura XML: ben formato (XMLParser)", l.leggi(a.dati))
            let obbligatori = ["FatturaElettronicaHeader", "DatiTrasmissione", "IdTrasmittente", "ProgressivoInvio", "FormatoTrasmissione",
                               "CodiceDestinatario", "CedentePrestatore", "IdFiscaleIVA", "Anagrafica", "RegimeFiscale", "Sede",
                               "CessionarioCommittente", "FatturaElettronicaBody", "DatiGenerali", "DatiGeneraliDocumento",
                               "TipoDocumento", "Divisa", "Data", "Numero", "DatiRitenuta", "DatiCassaPrevidenziale",
                               "ImportoTotaleDocumento", "DatiBeniServizi", "DettaglioLinee", "DatiRiepilogo", "DatiPagamento",
                               "DettaglioPagamento"]
            verifica.vero("Fattura XML: tutti i nodi obbligatori", obbligatori.allSatisfy { l.nomi.contains($0) })
            verifica.vero("Fattura XML: FPR12, TD01, EUR",
                          l.testi("FormatoTrasmissione") == ["FPR12"] && l.testi("TipoDocumento") == ["TD01"] && l.testi("Divisa") == ["EUR"])
            verifica.vero("Fattura XML: nome del file IT + partita IVA + progressivo", a.nome == "IT01234567897_00001.xml")
            verifica.vero("Fattura XML: escape di & < > e apostrofo tipografico",
                          a.xml.contains("Analisi &amp; revisione &lt;portafoglio&gt; dell&apos;anno")
                            && l.testi("Descrizione").first == "Analisi & revisione <portafoglio> dell'anno")
            verifica.vero("Fattura XML: trattino tipografico e virgolette latine", l.testi("Descrizione").last == "Relazione «finale» - consulenza")
            verifica.vero("Fattura XML: importi e aliquote con il punto",
                          l.testi("ImportoTotaleDocumento") == ["1586.63"] && l.testi("AliquotaIVA").allSatisfy { $0 == "22.00" }
                            && l.testi("ImportoPagamento") == ["1336.53"] && l.testi("Data") == ["2026-11-04"])
            let linee = l.testi("PrezzoTotale").compactMap(Double.init).reduce(0, +)
            let contributo = l.testi("ImportoContributoCassa").compactMap(Double.init).reduce(0, +)
            let imponibile = l.testi("ImponibileImporto").compactMap(Double.init).reduce(0, +)
            let imposta = l.testi("Imposta").compactMap(Double.init).reduce(0, +)
            verifica("Fattura XML: riepilogo = righe + contributo", imponibile, linee + contributo)
            verifica("Fattura XML: totale = imponibile + imposta", Double(l.testi("ImportoTotaleDocumento").first ?? "") ?? -1, imponibile + imposta)
        }
        if let b = esempi.last?.file {
            let l = LettoreFatturaXML()
            verifica.vero("Fattura XML B: ben formato", l.leggi(b.dati))
            verifica.vero("Fattura XML B: natura, riferimento normativo e bollo",
                          l.testi("Natura").contains("N2.2") && l.testi("Natura").contains("N1")
                            && l.testi("RiferimentoNormativo").count == 2 && l.testi("BolloVirtuale") == ["SI"]
                            && l.testi("ImportoBollo") == ["2.00"] && l.testi("AliquotaIVA").allSatisfy { $0 == "0.00" })
            verifica.vero("Fattura XML B: progressivo che non si ripete", b.nome == "IT01234567897_00002.xml")
        }

        // 13. Lettura tollerante e codifica
        let json = #"[{"id":"x","clienteId":"anna","data":"2026-02-01T12:00:00Z","stato":"emessa","righe":[{"descrizione":"A","importo":10},7,{"descrizione":"B","importo":"no"}]},{"id":"senza-cliente","data":"2026-02-01T12:00:00Z"}]"#
        if let lette = try? Archivio.decodificatore.decode(ElencoTollerante<Parcella>.self, from: Data(json.utf8)).elementi {
            verifica.vero("Parcelle: lettura tollerante (senza cliente scartata, emessa senza numero torna bozza)",
                          lette.count == 1 && lette[0].stato == .bozza && lette[0].numero == nil && lette[0].righe.count == 2
                            && lette[0].righe[1].importo == 0)
        } else {
            verifica.vero("Parcelle: lettura tollerante", false)
        }
        if let codificata = try? Archivio.codificatore.encode(congelata),
           let riletta = try? Archivio.decodificatore.decode(Parcella.self, from: codificata) {
            verifica.vero("Parcelle: parcella con le voci uguale dopo codifica e lettura", riletta == congelata)
        } else {
            verifica.vero("Parcelle: parcella codificata e letta", false)
        }
        if let codificati = try? Archivio.codificatore.encode(consulente),
           let riletti = try? Archivio.decodificatore.decode(DatiFatturazione.self, from: codificati) {
            verifica.vero("Fattura: dati fiscali uguali dopo codifica e lettura", riletti == consulente)
        } else {
            verifica.vero("Fattura: dati fiscali codificati e letti", false)
        }
        let strani = #"{"partitaIVA":5,"regime":{"aliquotaIVA":-3,"regimeFiscale":"RF99","applicaBollo":true},"numerazione":{"primoNumeroPerAnno":{"2026":4,"anno":2}}}"#
        let lettiStrani = try? Archivio.decodificatore.decode(DatiFatturazione.self, from: Data(strani.utf8))
        verifica.vero("Fattura: lettura tollerante dei dati fiscali",
                      lettiStrani?.partitaIVA == "" && lettiStrani?.regime.aliquotaIVA == nil && lettiStrani?.regime.regimeFiscale == nil
                        && lettiStrani?.regime.applicaBollo == true && lettiStrani?.numerazione.primoNumeroPerAnno == [2026: 4])
        verifica.vero("Fattura: Impostazioni di Studio nuove senza nessun dato fiscale", ImpostazioniStudio().fatturazione.vuoti
                        && ImpostazioniStudio().fatturazione.regime == RegimeFatturazione())

        // 14. Prestazioni: 1.000 parcelle in un passaggio
        let molte = (0..<1_000).map { i in parcella("m\(i)", Double(i % 50 + 1), i % 3 == 0 ? .pagata : .emessa, progressivo: i + 1,
                                                  incassata: d(2026, 5, 1), scadenza: d(2026, 9, 1)) }
        let tm = MotoreParcelle.totali(molte, anno: 2026, oggi: oggi, cal: cal)
        verifica("Parcelle: 1.000 parcelle contate", Double(tm.emesse + tm.pagate), 1_000)
    }
}
