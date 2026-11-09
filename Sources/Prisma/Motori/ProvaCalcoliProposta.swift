import Foundation

/// Prove della proposta che si costruisce da sola (Pratiche › Proposta, Design/template-luce-specifica.md §7.1,
/// «Luce» giro 3): due prodotti adatti, uno per canale → da scegliere (al più 4); catalogo vuoto → manca con «Rimedia»
/// verso Prodotti; il rischio letto dalla tipologia filtra la protezione; l'importo è quello di MotoreProtezioneFamiglia
/// (arrotondato come le proposte dei motori); il premio delle coperture non si inventa; la bozza ha il canale del
/// prodotto; un bisogno con una proposta già presentata non compare, con una bozza aperta compare già collegato;
/// adeguatezza rossa → niente moduli né «Proposta pronta»; senza modelli la tappa dei moduli è neutra e non blocca, con
/// un modello del canale dice quante caselle compila e quante restano da chiedere (CompilatoreModuli), i moduli Alleanza
/// restano neutri; la sostituzione «costi più bassi» trasferisce il valore della posizione, collega la scheda alla
/// posizione sostituita e conta il prospetto di sostituzione; la persona chiave dell'azienda chiede il capitale che manca
/// (fatturato × mesi ÷ 12 − coperture collegate), il welfare non ha cifra e salva la bozza da completare. Chiamata da
/// `ProvaCalcoli.esegui()`.
enum ProvaCalcoliProposta {
    static func esegui(_ verifica: VerificaCalcoli) {
        bisogni(verifica)
        prodotti(verifica)
        costruzione(verifica)
        adeguatezzaRossa(verifica)
        moduli(verifica)
        sostituzione(verifica)
        azienda(verifica)
        demo(verifica)
    }

    // MARK: - Dati di prova

    private static let oggi = AiutiProva.data(2026, 11, 7)

    /// Un cliente sposato, seguito con entrambi i canali, con un conto: alla famiglia manca la copertura caso morte.
    private static func cliente(canali: [Canale] = [.alleanza, .indipendente]) -> Cliente {
        var c = Cliente(id: "prova-proposta", nome: "", iniziali: "", tinta: .blu, tema: "", email: "", telefono: "",
                        preferito: false, nota: "", creatoIl: oggi)
        c.nome = "Marco Prova"
        c.iniziali = "MP"
        c.canali = canali
        c.dataNascita = AiutiProva.data(1984, 3, 10)
        c.famiglia = [Familiare(nome: "Elena", relazione: .coniuge)]
        c.profilo.redditoNettoAnnuo = 30_000
        return c
    }

    private static func conto(_ clienteId: String) -> Posizione {
        AiutiProva.posizione("Conto", .liquidita, 20_000) { $0.clienteId = clienteId }
    }

    private static func prodotto(_ id: String, _ nome: String, _ canale: Canale, _ area: AreaPosizione,
                                 tipologia: String = "") -> Prodotto {
        var p = Prodotto(nome: nome, canale: canale, area: area)
        p.id = id
        p.tipologia = tipologia
        return p
    }

    private static let tcmAlleanza = prodotto("p-tcm-a", "Temporanea caso morte", .alleanza, .protezione,
                                              tipologia: "Temporanea caso morte a capitale costante")
    private static let tcmIndipendente = prodotto("p-tcm-i", "Protezione vita", .indipendente, .protezione,
                                                  tipologia: "Temporanea caso morte")
    private static let infortuni = prodotto("p-inf", "Infortuni famiglia", .alleanza, .protezione, tipologia: "Polizza infortuni")

    private static func fonte(_ c: Cliente, posizioni: [Posizione], prodotti: [Prodotto], salvata: Bool = true) -> FonteVera {
        var analisi = Analisi360()
        analisi.confermate = [.protezione]
        return FonteVera(oggi: oggi, nomeUtente: "Prova", cliente: c, posizioni: posizioni, appuntamenti: [], attivita: [],
                         analisi: analisi, analisiSalvata: salvata, simulazioni: [], prodotti: prodotti)
    }

    private static func dati(_ c: Cliente, prodotti: [Prodotto]) -> DatiPrisma {
        var d = DatiPrisma(clienti: [], appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: "", impostazioni: Impostazioni())
        d.clienti = [c]
        d.prodotti = prodotti
        return d
    }

    /// Una pagina finta: le prove non impaginano (niente AppKit).
    private static let unaPagina: (ContenutoProspetto) -> Int = { _ in 3 }

    // MARK: - Bisogni

    private static func bisogni(_ verifica: VerificaCalcoli) {
        let c = cliente()
        let f = fonte(c, posizioni: [conto(c.id)], prodotti: [tcmAlleanza])
        let elenco = MotoreProposta.bisogni(fonte: f)
        let vita = elenco.first { $0.origine == "protezione-vita" }
        verifica.vero("Proposta: il bisogno di protezione caso morte è scoperto", vita != nil)
        verifica.vero("Proposta: titolo nel tono del template («La protezione di Marco»)", vita?.titolo == "La protezione di Marco")
        verifica.vero("Proposta: id unico per cliente", vita?.id == "\(c.id)·protezione-vita")
        verifica.vero("Proposta: le proposte senza area (capitali in scadenza) non sono bisogni",
                      elenco.allSatisfy { !$0.origine.hasPrefix("scadenza-") })
        // L'importo è quello del motore della protezione, arrotondato a 5.000 come le proposte di Vera
        let prot = MotoreProtezioneFamiglia.calcola(f.posizioni, cliente: c, analisi: f.analisi.protezione, data: oggi)
        let atteso = max(5_000, (prot.divarioConProposte / 5_000).rounded() * 5_000)
        verifica("Proposta: capitale del bisogno = divario di MotoreProtezioneFamiglia", vita?.capitale ?? -1, atteso)

        // Con una proposta già presentata nella stessa area e rischio il bisogno non compare
        var presentata = Posizione(clienteId: c.id, canale: .alleanza, stato: .proposta, area: .protezione, nome: "TCM presentata")
        presentata.rischio = .vita
        presentata.esito = .presentata
        presentata.capitaleAssicurato = 50_000
        let conPresentata = MotoreProposta.bisogni(fonte: fonte(c, posizioni: [conto(c.id), presentata], prodotti: [tcmAlleanza]))
        verifica.vero("Proposta: con una proposta già aperta il bisogno non compare",
                      !conPresentata.contains { $0.origine == "protezione-vita" })

        // Con una bozza aperta (tolta dalla fonte, passata a parte) il bisogno resta, collegato alla bozza
        var bozza = Posizione(clienteId: c.id, canale: .alleanza, stato: .proposta, area: .protezione, nome: "Bozza")
        bozza.rischio = .vita
        bozza.esito = .bozza
        let conBozza = MotoreProposta.bisogni(fonte: f, bozze: [bozza])
        verifica.vero("Proposta: con una bozza aperta il bisogno resta, già collegato",
                      conBozza.first { $0.origine == "protezione-vita" }?.propostaId == bozza.id)

        // Analisi 360 non salvata: il bisogno è «da confermare»
        let nonSalvata = MotoreProposta.bisogni(fonte: fonte(c, posizioni: [conto(c.id)], prodotti: [], salvata: false))
        verifica.vero("Proposta: analisi non salvata → motivo «Da confermare»",
                      nonSalvata.first.map { $0.daConfermare && $0.motivo.hasPrefix("Da confermare") } ?? false)
    }

    // MARK: - Prodotti adatti

    private static func prodotti(_ verifica: VerificaCalcoli) {
        let c = cliente()
        guard let vita = MotoreProposta.bisogni(fonte: fonte(c, posizioni: [conto(c.id)], prodotti: [])).first(where: { $0.origine == "protezione-vita" }) else {
            verifica.vero("Proposta: bisogno caso morte per i prodotti", false)
            return
        }
        let catalogo = [tcmAlleanza, tcmIndipendente, infortuni]
        let adatti = MotoreProposta.prodottiAdatti(vita, catalogo: catalogo, canaliCliente: c.canali)
        verifica("Proposta: due prodotti caso morte adatti, uno per canale", Double(adatti.count), 2)
        verifica.vero("Proposta: il prodotto infortuni non è adatto al caso morte", !adatti.contains { $0.id == infortuni.id })
        verifica.vero("Proposta: rischio letto dalla tipologia", MotoreProposta.rischioNominato(tcmAlleanza) == .vita
                      && MotoreProposta.rischioNominato(infortuni) == .infortuni)
        let soloAlleanza = MotoreProposta.prodottiAdatti(vita, catalogo: catalogo, canaliCliente: [.alleanza])
        verifica.vero("Proposta: cliente solo Alleanza → solo prodotti Alleanza", soloAlleanza.map(\.id) == [tcmAlleanza.id])
        let ultimo = MotoreProposta.prodottiAdatti(vita, catalogo: catalogo, canaliCliente: c.canali, ultimo: tcmIndipendente.id)
        verifica.vero("Proposta: l'ultimo prodotto usato va in testa", ultimo.first?.id == tcmIndipendente.id)

        // Due prodotti: la costruzione si ferma sulla scelta
        let f = fonte(c, posizioni: [conto(c.id)], prodotti: catalogo)
        let r = MotoreProposta.costruisci(vita, fonte: f, dati: dati(c, prodotti: catalogo), contaPagine: unaPagina)
        if case .daScegliere(let elenco) = r.prodotto {
            verifica("Proposta: da scegliere con due prodotti", Double(elenco.count), 2)
        } else {
            verifica.vero("Proposta: da scegliere con due prodotti", false)
        }
        verifica.vero("Proposta: da scegliere → passi dopo spenti e nessuna bozza", r.importo == nil && r.bozza == nil && r.raggiunti == 1)

        // Cinque prodotti: al più quattro da scegliere
        let tanti = (1...5).map { prodotto("p-\($0)", "TCM \($0)", .alleanza, .protezione, tipologia: "Temporanea caso morte") }
        let rTanti = MotoreProposta.costruisci(vita, fonte: fonte(c, posizioni: [conto(c.id)], prodotti: tanti),
                                               dati: dati(c, prodotti: tanti), contaPagine: unaPagina)
        if case .daScegliere(let elenco) = rTanti.prodotto {
            verifica("Proposta: al più quattro prodotti da scegliere", Double(elenco.count), 4)
        } else {
            verifica.vero("Proposta: al più quattro prodotti da scegliere", false)
        }

        // Catalogo vuoto: manca, con il rimedio verso Prodotti
        let vuoto = MotoreProposta.costruisci(vita, fonte: fonte(c, posizioni: [conto(c.id)], prodotti: []),
                                              dati: dati(c, prodotti: []), contaPagine: unaPagina)
        if case .manca(let frase, let rimedio) = vuoto.prodotto {
            verifica.vero("Proposta: catalogo vuoto → «Rimedia» verso Prodotti", rimedio == .prodotti)
            verifica.vero("Proposta: frase del catalogo vuoto", frase == "Nessun prodotto di protezione caso morte nel catalogo.")
        } else {
            verifica.vero("Proposta: catalogo vuoto → manca", false)
        }
        verifica.vero("Proposta: catalogo vuoto → niente «Proposta pronta»", !vuoto.pronta)
    }

    // MARK: - Costruzione

    private static func costruzione(_ verifica: VerificaCalcoli) {
        let c = cliente()
        let catalogo = [tcmAlleanza, tcmIndipendente]
        let f = fonte(c, posizioni: [conto(c.id)], prodotti: catalogo)
        guard let vita = MotoreProposta.bisogni(fonte: f).first(where: { $0.origine == "protezione-vita" }) else {
            verifica.vero("Proposta: bisogno caso morte per la costruzione", false)
            return
        }
        let r = MotoreProposta.costruisci(vita, fonte: f, dati: dati(c, prodotti: catalogo), prodottoScelto: tcmIndipendente.id,
                                          contaPagine: unaPagina)
        let bozza = r.bozza
        verifica.vero("Proposta: bozza con il canale del prodotto (indipendente)", bozza?.canale == .indipendente)
        verifica.vero("Proposta: bozza proposta, esito bozza, con il prodotto", bozza?.stato == .proposta && bozza?.esito == .bozza
                      && bozza?.prodottoId == tcmIndipendente.id && bozza?.rischio == .vita)
        verifica("Proposta: capitale assicurato della bozza = cifra del motore", bozza?.capitaleAssicurato ?? -1, vita.capitale ?? -2)
        verifica("Proposta: premio delle coperture lasciato a zero", bozza?.premio ?? -1, 0)
        verifica.vero("Proposta: «premio: da chiedere alla compagnia»", r.importo?.valore?.riga == MotoreProposta.premioDaChiedere)
        verifica("Proposta: cifra dell'importo = capitale del bisogno", r.importo?.valore?.cifra ?? -1, vita.capitale ?? -2)
        verifica("Proposta: pagine del prospetto contate", Double(r.prospetto?.valore?.pagine ?? 0), 3)
        verifica.vero("Proposta: la scheda di adeguatezza è collegata al bisogno",
                      r.scheda?.posizioneId == bozza?.id && r.scheda?.collegamento != nil)

        // Il premio scritto a mano nella bozza esistente si mostra, non si cambia
        var aMano = bozza ?? Posizione(clienteId: c.id, canale: .indipendente, stato: .proposta, area: .protezione, nome: "")
        aMano.premio = 32
        aMano.frequenza = .mensile
        let rMano = MotoreProposta.costruisci(vita, fonte: f, dati: dati(c, prodotti: catalogo), bozzaEsistente: aMano,
                                              contaPagine: unaPagina)
        verifica.vero("Proposta: il premio scritto a mano resta", rMano.bozza?.premio == 32 && rMano.bozza?.id == aMano.id)
        verifica.vero("Proposta: riga del premio scritto a mano", rMano.importo?.valore?.riga.hasPrefix("premio: ") == true
                      && rMano.importo?.valore?.riga != MotoreProposta.premioDaChiedere)

        // I moduli: senza modelli la tappa è neutra e non blocca; il passo 5 c'è solo se l'adeguatezza prosegue
        if let a = r.adeguatezza, a.prosegue {
            verifica.vero("Proposta: senza modelli la tappa dei moduli è neutra", {
                if case .inArrivo(let frase)? = r.moduli { return frase == MotoreProposta.moduliSenzaModelli }
                return false
            }())
            verifica.vero("Proposta: cinque passi e «Proposta pronta»", r.raggiunti == 5 && r.pronta)
        } else {
            verifica.vero("Proposta: adeguatezza ferma → niente moduli", r.moduli == nil && !r.pronta)
        }
    }

    // MARK: - Adeguatezza rossa

    private static func adeguatezzaRossa(_ verifica: VerificaCalcoli) {
        var c = cliente()
        let f0 = fonte(c, posizioni: [conto(c.id)], prodotti: [tcmAlleanza])
        guard let vita = MotoreProposta.bisogni(fonte: f0).first(where: { $0.origine == "protezione-vita" }) else {
            verifica.vero("Proposta: bisogno caso morte per l'adeguatezza", false)
            return
        }
        // Il consulente ha scartato il bisogno a cui la proposta risponde: l'adeguatezza è rossa (B3)
        guard let rilevato = vita.bisognoRilevatoId else {
            verifica.vero("Proposta: il bisogno caso morte ha il bisogno rilevato", false)
            return
        }
        c.bisogni.esiti[rilevato] = false
        let f = fonte(c, posizioni: [conto(c.id)], prodotti: [tcmAlleanza])
        verifica.vero("Proposta: un bisogno scartato nel profilo non torna fra i bisogni",
                      !MotoreProposta.bisogni(fonte: f).contains { $0.origine == "protezione-vita" })
        let r = MotoreProposta.costruisci(vita, fonte: f, dati: dati(c, prodotti: [tcmAlleanza]), contaPagine: unaPagina)
        if case .bloccato(let frase)? = r.adeguatezza {
            verifica.vero("Proposta: adeguatezza rossa → «Non adeguata: …»", frase.hasPrefix("Non adeguata: "))
        } else {
            verifica.vero("Proposta: adeguatezza rossa → bloccata", false)
        }
        verifica.vero("Proposta: adeguatezza rossa → moduli non costruiti", r.moduli == nil)
        verifica.vero("Proposta: adeguatezza rossa → niente «Proposta pronta»", !r.pronta && r.raggiunti == 4)
    }

    // MARK: - Moduli

    /// Un modello del canale indipendente con cognome, codice fiscale (che manca al cliente di prova), capitale e una firma.
    private static func modello(canale: Canale?, prodotti: [String] = [], confermato: Bool = true) -> ModelloModulo {
        let r = CGRect(x: 40, y: 600, width: 180, height: 18)
        var m = ModelloModulo(id: "modulo-prova-proposta", titolo: "Proposta di polizza", tipo: .propostaPolizza, canale: canale,
                              file: "prova.pdf", pagine: 1,
                              campi: [ModelloModulo.Campo(pagina: 0, riquadro: r, etichetta: "Cognome", dato: .cognome, origine: .regole),
                                      ModelloModulo.Campo(pagina: 0, riquadro: r, etichetta: "Codice fiscale", dato: .codiceFiscale, origine: .regole),
                                      ModelloModulo.Campo(pagina: 0, riquadro: r, etichetta: "Capitale", dato: .capitale, origine: .regole),
                                      ModelloModulo.Campo(pagina: 0, riquadro: r, etichetta: "Firma", tipo: .firma, origine: .regole)],
                              mappaConfermata: confermato)
        m.prodottoIds = prodotti
        return m
    }

    private static func moduli(_ verifica: VerificaCalcoli) {
        var c = cliente()
        c.fiscale = DatiFiscaliCliente()
        c.fiscale?.cognome = "Prova"
        let catalogo = [tcmAlleanza, tcmIndipendente]
        let f = fonte(c, posizioni: [conto(c.id)], prodotti: catalogo)
        guard let vita = MotoreProposta.bisogni(fonte: f).first(where: { $0.origine == "protezione-vita" }) else {
            verifica.vero("Proposta: bisogno caso morte per i moduli", false)
            return
        }
        let d = dati(c, prodotti: catalogo)
        let conModello = MotoreProposta.costruisci(vita, fonte: f, dati: d, prodottoScelto: tcmIndipendente.id,
                                                   modelli: [modello(canale: .indipendente)], contaPagine: unaPagina)
        if conModello.adeguatezza?.prosegue == true {
            if case .fatto(let elenco)? = conModello.moduli, let m = elenco.first {
                verifica.vero("Proposta: un modulo del canale nella tappa 5", elenco.count == 1 && m.titolo == "Proposta di polizza")
                verifica("Proposta: caselle compilate dal dossier (cognome e capitale)", Double(m.compilati), 2)
                verifica("Proposta: caselle da chiedere (codice fiscale)", Double(m.daChiedere), 1)
                verifica.vero("Proposta: «2 campi compilati · 1 da chiedere»", m.riga == "2 campi compilati · 1 da chiedere")
                verifica.vero("Proposta: con i moduli il riquadro finale li conta",
                              MotoreProposta.riepilogo(conModello).contains("1 modulo compilato"))
            } else {
                verifica.vero("Proposta: con un modello la tappa 5 elenca i moduli", false)
            }
            verifica.vero("Proposta: con i moduli la proposta è pronta", conModello.pronta)
        }
        // Un modello di un altro prodotto o con la mappa da controllare non entra
        let altri = MotoreProposta.modelli(per: conModello.bozza ?? conto(c.id), prodotto: tcmIndipendente,
                                           tra: [modello(canale: .indipendente, prodotti: ["altro"]),
                                                 modello(canale: .indipendente, confermato: false),
                                                 modello(canale: .alleanza)])
        verifica.vero("Proposta: modelli di altri prodotti, canali o con la mappa da controllare esclusi", altri.isEmpty)
        // Alleanza: Prisma non compila i moduli (decisione 60), la tappa resta neutra
        let alleanza = MotoreProposta.costruisci(vita, fonte: f, dati: d, prodottoScelto: tcmAlleanza.id,
                                                 modelli: [modello(canale: nil)], contaPagine: unaPagina)
        if alleanza.adeguatezza?.prosegue == true {
            verifica.vero("Proposta: i moduli Alleanza restano neutri", {
                if case .inArrivo(let frase)? = alleanza.moduli { return frase == MotoreProposta.moduliAlleanza }
                return false
            }())
        }
    }

    // MARK: - Sostituzione «costi più bassi»

    private static func sostituzione(_ verifica: VerificaCalcoli) {
        let c = cliente(canali: [.indipendente])
        let fondo = AiutiProva.posizione("Fondo Esempio Globale", .investimento, 87_350) {
            $0.clienteId = c.id
            $0.canale = .indipendente
            $0.costoAnnuo = 2.1
            $0.totaleVersato = 78_400
        }
        var efficiente = prodotto("p-fondo-eff", "Fondo efficiente", .indipendente, .investimento, tipologia: "Fondo azionario")
        efficiente.costoAnnuo = 0.65
        let f = fonte(c, posizioni: [conto(c.id), fondo], prodotti: [efficiente])
        // Il bisogno automatico c'è se e solo se i motori dei costi trovano l'alternativa
        let automatico = MotoreProposta.bisogni(fonte: f).contains { $0.posizioneSostituitaId == fondo.id }
        let alternativa = MotoreCosti.alternativa(fondo, prodotti: [efficiente], cliente: c.id) != nil
        verifica.vero("Proposta: la sostituzione automatica segue MotoreCosti.alternativa", automatico == alternativa)

        let b = MotoreProposta.bisognoSostituzione(attuale: fondo, cliente: c, motivo: "prova", prodotto: efficiente.id)
        verifica.vero("Proposta: bisogno di sostituzione riconosciuto", b.sostituzione && b.posizioneSostituitaId == fondo.id)
        let r = MotoreProposta.costruisci(b, fonte: f, dati: dati(c, prodotti: [efficiente]), contaPagine: unaPagina,
                                          contaSostituzione: { _, _ in 3 })
        verifica.vero("Proposta: la sostituzione sceglie il prodotto dello Smontaggio", r.prodotto.valore?.id == efficiente.id)
        verifica("Proposta: la sostituzione trasferisce il valore della posizione", r.importo?.valore?.cifra ?? -1, 87_350)
        verifica.vero("Proposta: riga «costi da … a … l'anno»", r.importo?.valore?.riga.hasPrefix("costi da ") == true)
        verifica.vero("Proposta: la scheda di adeguatezza dice la posizione sostituita", r.scheda?.posizioneSostituitaId == fondo.id)
        verifica.vero("Proposta: il prospetto è quello di sostituzione", r.prospetto?.valore?.attualeId == fondo.id)
        // Una posizione provvisoria dello Smontaggio: niente posizione sostituita, prospetto della posizione
        let provvisoria = MotoreProposta.bisognoSostituzione(attuale: fondo, cliente: c, motivo: "prova", prodotto: efficiente.id,
                                                             provvisoria: true)
        let rp = MotoreProposta.costruisci(provvisoria, fonte: fonte(c, posizioni: [conto(c.id)], prodotti: [efficiente]),
                                           dati: dati(c, prodotti: [efficiente]), contaPagine: unaPagina, contaSostituzione: { _, _ in 3 })
        verifica.vero("Proposta: dallo Smontaggio provvisorio niente posizione sostituita né prospetto di sostituzione",
                      rp.scheda?.posizioneSostituitaId == nil && rp.prospetto?.valore?.attualeId == nil
                      && rp.importo?.valore?.cifra == 87_350)
    }

    // MARK: - Azienda

    private static func azienda(_ verifica: VerificaCalcoli) {
        var c = cliente(canali: [.indipendente])
        var a = AziendaCliente(id: "az-prova", ragioneSociale: "Serramenti Prova S.r.l.")
        a.fatturato = 1_284_500
        a.personaChiave = PersonaChiave(mesiARischio: 5, posizioniCollegate: ["km-prova"])
        a.welfare = ListaAzienda()
        c.aziende = [a]
        let keyman = AiutiProva.posizione("Key man", .protezione, 0) {
            $0.id = "km-prova"
            $0.clienteId = c.id
            $0.capitaleAssicurato = 137_500
        }
        let km = prodotto("p-km", "Key man impresa", .indipendente, .protezione, tipologia: "Temporanea key man")
        let welfare = prodotto("p-wf", "Piano welfare dipendenti", .indipendente, .previdenza, tipologia: "Previdenza collettiva")
        let f = fonte(c, posizioni: [conto(c.id), keyman], prodotti: [tcmIndipendente, km, welfare])
        guard let b = MotoreProposta.bisogni(fonte: f).first(where: { $0.areaAzienda == .personaChiave }) else {
            verifica.vero("Proposta: bisogno della persona chiave dell'azienda", false)
            return
        }
        let atteso = 1_284_500.0 * 5 / 12 - 137_500
        verifica("Proposta: capitale della persona chiave = fabbisogno − coperture", b.capitale ?? -1, atteso)
        let adatti = MotoreProposta.prodottiAzienda(area: .personaChiave, catalogo: [tcmIndipendente, km, welfare], canaliCliente: c.canali)
        verifica.vero("Proposta: prima i prodotti key man, poi le temporanee", adatti.map(\.id) == [km.id, tcmIndipendente.id])
        let r = MotoreProposta.costruisci(b, fonte: f, dati: dati(c, prodotti: [tcmIndipendente, km, welfare]), prodottoScelto: km.id,
                                          contaPagine: unaPagina)
        verifica("Proposta: la bozza key man ha il capitale che manca", r.bozza?.capitaleAssicurato ?? -1, atteso)
        verifica.vero("Proposta: la bozza key man si ritrova dalla nota", r.bozza?.note.contains(MotoreProposta.notaAzienda) == true)
        // Il welfare: solo dal dossier, senza cifra; la bozza si salva per scrivere l'importo
        guard let w = MotoreProposta.bisognoAzienda(a, area: .welfare, fonte: f) else {
            verifica.vero("Proposta: bisogno del welfare dell'azienda", false)
            return
        }
        verifica.vero("Proposta: il welfare non nasce da solo",
                      !MotoreProposta.bisogni(fonte: f).contains { $0.areaAzienda == .welfare })
        let rw = MotoreProposta.costruisci(w, fonte: f, dati: dati(c, prodotti: [km, welfare]), contaPagine: unaPagina)
        verifica.vero("Proposta: il welfare usa solo i prodotti welfare", rw.prodotto.valore?.id == welfare.id)
        verifica.vero("Proposta: il welfare senza importo si ferma con la bozza da completare", {
            if case .manca(let frase, let rimedio)? = rw.importo { return frase == MotoreProposta.fraseImportoWelfare && rimedio == .posizione }
            return false
        }() && rw.bozza != nil)
        // Senza prodotti welfare: «nessun prodotto» con Rimedia verso Prodotti
        let senza = MotoreProposta.costruisci(w, fonte: fonte(c, posizioni: [conto(c.id)], prodotti: [km]), dati: dati(c, prodotti: [km]),
                                              contaPagine: unaPagina)
        verifica.vero("Proposta: welfare senza prodotti adatti → Rimedia verso Prodotti", {
            if case .manca(_, let rimedio) = senza.prodotto { return rimedio == .prodotti }
            return false
        }())
    }

    // MARK: - Dati di prova

    /// Sui clienti di prova: ogni bisogno ha un'area, le cifre sono positive e un canale di prodotto.
    private static func demo(_ verifica: VerificaCalcoli) {
        let d = DatiPrisma.demo()
        var tutti: [BisognoScoperto] = []
        for c in d.clienti {
            let posizioni = d.posizioni.filter { $0.clienteId == c.id && !($0.stato == .proposta && $0.esito == .bozza) }
            let f = FonteVera(oggi: oggi, nomeUtente: "Prova", cliente: c, posizioni: posizioni, appuntamenti: [], attivita: [],
                              analisi: d.analisi[c.id] ?? Analisi360(cliente: c, posizioni: posizioni), analisiSalvata: d.analisi[c.id] != nil, simulazioni: [],
                              obiettivi: d.obiettivi.filter { $0.clienteId == c.id }, prodotti: d.prodotti)
            tutti += MotoreProposta.bisogni(fonte: f)
        }
        verifica.vero("Proposta: i clienti di prova hanno bisogni scoperti", !tutti.isEmpty)
        verifica.vero("Proposta: bisogni di prova con cifre dei motori",
                      tutti.allSatisfy { ($0.capitale ?? $0.versamentoMensile ?? $0.importo ?? 0) > 0 || $0.rischio == .invalidita })
        verifica.vero("Proposta: id dei bisogni senza doppioni", Set(tutti.map(\.id)).count == tutti.count)
    }
}
