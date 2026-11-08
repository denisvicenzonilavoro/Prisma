import Foundation
import PDFKit

/// Prove di «Compila da solo» (Design/template-luce-specifica.md §7.2.5 punto 9, «Luce» giro 10), sui fac-simile generati
/// da Prisma (mai un modulo vero): riconoscimento dei campi AcroForm e delle etichette del PDF piatto; le regole (firma
/// prima del consulente, «nome» non dentro «cognome», nome e cognome insieme non associati); compilazione con i dati di
/// prova (date gg/mm/aaaa, premio con la virgola), i mancanti e le firme; scrittura e rilettura dei valori; il PDF piatto
/// con il testo nelle caselle; l'IBAN (mod 97, mascherato, solo con l'interruttore acceso); nessuna risposta del cliente
/// (titolare effettivo, PEP, origine dei fondi, scopo) compilata, neanche con Vera o con una correzione a mano; Vera che
/// propone solo dati ammessi e per etichette date; il modulo Alleanza non compilabile (decisione 60).
/// Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliModuli {
    static func esegui(_ verifica: VerificaCalcoli) {
        regole(verifica)
        iban(verifica)
        let proposta = riconoscimento(verifica)
        compilazione(verifica, proposta)
        piatto(verifica)
        risposte(verifica)
        vera(verifica)
        caselle(verifica)
        statoCompilazione(verifica)
    }

    /// Un cliente di prova con tutto ciò che serve (dati di prova dichiarati, inventati).
    static func clienteDiProva(iban: String? = "IT60X0542811101000000123456") -> Cliente {
        var c = Cliente(id: "prova-moduli", nome: "Giulia Rossi", iniziali: "GR", tinta: .rosa, tema: "", email: "giulia.rossi@example.com",
                        telefono: "+39 333 000 1001", preferito: false, nota: "dati di prova", creatoIl: Date(timeIntervalSince1970: 1_700_000_000))
        c.dataNascita = Calendar(identifier: .gregorian).date(from: DateComponents(year: 1989, month: 3, day: 14))
        c.codiceFiscale = "rssglu89c54a944x"
        c.professione = "Architetta"
        c.luogoNascita = "Bologna (BO)"
        var f = DatiFiscaliCliente()
        f.nome = "Giulia"
        f.cognome = "Rossi"
        f.sede.indirizzo = "Via dei Mille"
        f.sede.numeroCivico = "12"
        f.sede.cap = "40121"
        f.sede.comune = "Bologna"
        f.sede.provincia = "bo"
        c.fiscale = f
        var conf = ConformitaCliente()
        conf.documento = DocumentoIdentita(tipo: .cartaIdentita, numero: "CA00000AA",
                                           rilasciatoIl: Calendar(identifier: .gregorian).date(from: DateComponents(year: 2021, month: 5, day: 3)),
                                           scadenza: Calendar(identifier: .gregorian).date(from: DateComponents(year: 2031, month: 5, day: 3)))
        c.conformita = conf
        c.iban = iban
        return c
    }

    static func fonteDiProva(_ c: Cliente, conservaIban: Bool = false) -> FonteCompilazione {
        var p = Posizione(clienteId: c.id, canale: .indipendente, stato: .proposta, area: .risparmio, nome: "Piano di accumulo (prova)")
        p.premio = 550
        p.frequenza = .mensile
        p.beneficiari = "Gli eredi legittimi"
        p.decorrenza = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 12, day: 1))
        return FonteCompilazione(cliente: c, posizione: p, prodotto: nil, consulente: "Consulente di prova", comuneConsulente: "",
                                 oggi: Date(), conservaIban: conservaIban)
    }

    private static func regole(_ verifica: VerificaCalcoli) {
        verifica.vero("Moduli: «Firma del consulente» è una firma, non il consulente",
                      RiconoscitoreModulo.associa("Firma del consulente") == .firma)
        verifica.vero("Moduli: «Nome» non scatta dentro «Cognome»",
                      RiconoscitoreModulo.associa("COGNOME") == .dato(.cognome) && RiconoscitoreModulo.associa("Nome") == .dato(.nome))
        verifica.vero("Moduli: «Nome e cognome» insieme non si associa (non si spezza a indovinare)",
                      RiconoscitoreModulo.associa("Nome e cognome") == nil)
        verifica.vero("Moduli: «Data di nascita», «Luogo di nascita» e «Luogo e data» distinti",
                      RiconoscitoreModulo.associa("Data di nascita") == .dato(.dataNascita)
                      && RiconoscitoreModulo.associa("Luogo di nascita") == .dato(.luogoNascita)
                      && RiconoscitoreModulo.associa("Luogo e data") == .dato(.luogoData))
        verifica.vero("Moduli: «Scadenza del documento» non è la scadenza del contratto",
                      RiconoscitoreModulo.associa("Scadenza del documento") == .dato(.documentoScadenza)
                      && RiconoscitoreModulo.associa("Scadenza") == .dato(.scadenza))
        let riservate = ["Titolare effettivo", "Persona politicamente esposta (PEP)", "Origine dei fondi", "Scopo del rapporto",
                         "Obiettivi di investimento", "Reddito annuo"]
        verifica.vero("Moduli: titolare effettivo, PEP, origine dei fondi, scopo, obiettivi e reddito sono risposte del cliente",
                      riservate.allSatisfy { RiconoscitoreModulo.associa($0) == .risposta })
        // Le etichette che somigliano a un dato ma ne chiedono un altro (revisione del giro 10)
        let attese: [(String, AssociazioneModulo?)] = [
            ("Indirizzo e-mail", .dato(.email)), ("Indirizzo di residenza", .dato(.indirizzo)),
            ("Frequenza del premio", .dato(.frequenza)), ("Periodicità del versamento", .dato(.frequenza)), ("Premio annuo", .dato(.premio)),
            ("Provincia di nascita", nil), ("Provincia di residenza", .dato(.provincia)),
            ("Luogo di rilascio", nil), ("Ente di rilascio", nil), ("Comune di rilascio", nil), ("Data di rilascio", .dato(.documentoRilascio)),
            ("Durata", nil), ("Durata del contratto (anni)", nil), ("Indirizzo PEC", nil),
            ("Codice fiscale del beneficiario", nil), ("Data di nascita dell'assicurato", nil), ("Cognome del legale rappresentante", nil),
            ("Beneficiari in caso di decesso", .dato(.beneficiari)), ("Firma dell'assicurato", .firma),
        ]
        let sbagliate = attese.filter { RiconoscitoreModulo.associa($0.0) != $0.1 }.map(\.0)
        verifica.vero("Moduli: email prima dell'indirizzo, frequenza prima del premio, niente dati del cliente nelle caselle di altri o di rilascio e durata (sbagliate: \(sbagliate))",
                      sbagliate.isEmpty)
        verifica.vero("Moduli: un modulo d'identificazione della clientela è un'adeguata verifica (compila solo anagrafica e documento)",
                      StatoShell.tipoModulo("Identificazione_clientela Identificazione e verifica della clientela") == .adeguataVerifica
                      && StatoShell.tipoModulo("Proposta di polizza vita") == .propostaPolizza)
        verifica.vero("Moduli: le regole tolgono accenti e punteggiatura («Città», «E-mail»)",
                      RiconoscitoreModulo.associa("Città") == .dato(.comune) && RiconoscitoreModulo.associa("E-mail:") == .dato(.email))
    }

    private static func iban(_ verifica: VerificaCalcoli) {
        verifica.vero("Moduli: IBAN di esempio valido (mod 97), anche con spazi e minuscole",
                      IBAN.valido("IT60X0542811101000000123456") && IBAN.valido("it60 x054 2811 1010 0000 0123 456")
                      && IBAN.valido("GB82WEST12345698765432"))
        verifica.vero("Moduli: IBAN con una cifra sbagliata rifiutato",
                      !IBAN.valido("IT61X0542811101000000123456") && !IBAN.valido("IT60X05428111010000001234") && !IBAN.valido(""))
        verifica.vero("Moduli: IBAN mascherato come nel template",
                      IBAN.mascherato("IT60X0542811101000000123456") == "IT•• •••• •••• •••• 3456")
        verifica.vero("Moduli: IBAN a gruppi di quattro", IBAN.aGruppi("IT60X0542811101000000123456") == "IT60 X054 2811 1010 0000 0123 456")
        let c = clienteDiProva()
        verifica.vero("Moduli: l'IBAN non si scrive con l'interruttore spento",
                      CompilatoreModuli.valore(.iban, fonteDiProva(c)) == nil
                      && CompilatoreModuli.valore(.iban, fonteDiProva(c, conservaIban: true)) == "IT60 X054 2811 1010 0000 0123 456")
        verifica.vero("Moduli: un IBAN non valido non si scrive nemmeno con l'interruttore acceso",
                      CompilatoreModuli.valore(.iban, fonteDiProva(clienteDiProva(iban: "IT00X0000000000000000000000"), conservaIban: true)) == nil)
    }

    /// Il modello della proposta fac-simile, riconosciuto dal PDF AcroForm generato da Prisma.
    private static func riconoscimento(_ verifica: VerificaCalcoli) -> ModelloModulo? {
        guard let dati = FacSimileModulo.pdf(FacSimileModulo.proposta), let doc = PDFDocument(data: dati) else {
            verifica.vero("Moduli: il fac-simile della proposta si genera", false)
            return nil
        }
        let e = RiconoscitoreModulo.riconosci(doc, tipo: .propostaPolizza)
        verifica.vero("Moduli: il fac-simile ha i campi compilabili (\(e.campi.count) caselle, 17 attese)",
                      e.acroForm && e.campi.count == 17 && e.pagine == 1 && !e.illeggibile)
        let perNome = Dictionary(e.campi.compactMap { c in c.nomeAcroForm.map { ($0, c) } }, uniquingKeysWith: { a, _ in a })
        let attesi: [(String, DatoModulo)] = [("cognome", .cognome), ("nome", .nome), ("codice_fiscale", .codiceFiscale),
                                               ("data_nascita", .dataNascita), ("luogo_nascita", .luogoNascita), ("indirizzo", .indirizzo),
                                               ("cap", .cap), ("comune", .comune), ("telefono", .telefono), ("email", .email),
                                               ("professione", .professione), ("beneficiari", .beneficiari), ("premio", .premio),
                                               ("decorrenza", .decorrenza), ("iban", .iban)]
        let sbagliati = attesi.filter { perNome[$0.0]?.dato != $0.1 }.map(\.0)
        verifica.vero("Moduli: i 15 campi associati dall'etichetta sopra la casella (sbagliati: \(sbagliati))", sbagliati.isEmpty)
        verifica.vero("Moduli: anche sul PDF compilabile le associazioni delle regole sono da confermare nella revisione",
                      e.campi.filter { $0.dato != nil }.allSatisfy(\.daConfermare))
        verifica.vero("Moduli: le due caselle della firma riconosciute come firme",
                      perNome["firma_contraente"]?.firma == true && perNome["firma_consulente"]?.firma == true)
        verifica.vero("Moduli: le etichette lette sono quelle stampate («Codice fiscale»)",
                      perNome["codice_fiscale"]?.etichetta.lowercased() == "codice fiscale")
        return ModelloModulo(titolo: "Proposta di polizza", tipo: .propostaPolizza, file: "prova.pdf", pagine: e.pagine, campi: e.campi,
                             versione: e.versione, mappaConfermata: true, diProva: true)
    }

    private static func compilazione(_ verifica: VerificaCalcoli, _ m: ModelloModulo?) {
        guard let m, let pdf = FacSimileModulo.pdf(FacSimileModulo.proposta) else { return }
        let c = clienteDiProva()
        let a = CompilatoreModuli.anteprima(m, fonte: fonteDiProva(c))
        verifica.vero("Moduli: 14 di 15 campi compilati, manca solo l'IBAN (interruttore spento) (\(a.compilati) di \(a.totale))",
                      a.compilati == 14 && a.totale == 15 && a.datiMancanti == [.iban] && a.firme.count == 2)
        func v(_ d: DatoModulo) -> String? { m.campi.first { $0.dato == d }.flatMap { a.valori[$0.id]?.testo } }
        verifica.vero("Moduli: data di nascita e decorrenza gg/mm/aaaa", v(.dataNascita) == "14/03/1989" && v(.decorrenza) == "01/12/2026")
        verifica.vero("Moduli: premio con la virgola e la frequenza («\(v(.premio) ?? "")»)",
                      v(.premio)?.hasPrefix("550,00") == true && v(.premio)?.hasSuffix("al mese") == true)
        verifica.vero("Moduli: indirizzo dalla sede fiscale con il civico, codice fiscale e provincia in maiuscolo",
                      v(.indirizzo) == "Via dei Mille 12" && v(.codiceFiscale) == "RSSGLU89C54A944X" && v(.comune) == "Bologna")
        var senzaFiscale = c
        senzaFiscale.fiscale = nil
        let b = CompilatoreModuli.anteprima(m, fonte: fonteDiProva(senzaFiscale))
        verifica.vero("Moduli: senza scheda fiscale cognome, nome e sede mancano (l'anagrafica non si spezza)",
                      Set(b.datiMancanti).isSuperset(of: [.cognome, .nome, .indirizzo, .cap, .comune]))
        // Scrittura e rilettura
        let conIban = CompilatoreModuli.anteprima(m, fonte: fonteDiProva(c, conservaIban: true))
        guard let scritto = CompilatoreModuli.scrivi(m, pdf: pdf, anteprima: conIban) else {
            verifica.vero("Moduli: il PDF compilato si scrive", false)
            return
        }
        let letti = CompilatoreModuli.valoriAcroForm(scritto)
        verifica.vero("Moduli: i valori si rileggono dal PDF compilato (\(letti.count) campi)",
                      letti["cognome"] == "Rossi" && letti["data_nascita"] == "14/03/1989" && letti["iban"] == "IT60 X054 2811 1010 0000 0123 456"
                      && letti.count == 15)
        verifica.vero("Moduli: le firme restano vuote (niente firma elettronica)",
                      letti["firma_contraente"] == nil && letti["firma_consulente"] == nil)
        // Una correzione a mano vale solo per la compilazione
        let corretta = CompilatoreModuli.anteprima(m, fonte: fonteDiProva(c), correzioni: [m.campi.first { $0.dato == .iban }?.id ?? "": "IT60 X054 2811 1010 0000 0123 456"])
        verifica.vero("Moduli: «Lo scrivo io» riempie la casella senza toccare il dossier",
                      corretta.compilati == 15 && corretta.mancanti.isEmpty && c.iban == "IT60X0542811101000000123456")
        // Alleanza (decisione 60)
        var alleanza = m
        alleanza.canale = .alleanza
        verifica.vero("Moduli: un modulo Alleanza non è compilabile, l'indipendente sì", !alleanza.compilabile && m.compilabile)
    }

    private static func piatto(_ verifica: VerificaCalcoli) {
        guard let dati = FacSimileModulo.pdf(FacSimileModulo.proposta, compilabile: false), let doc = PDFDocument(data: dati) else {
            verifica.vero("Moduli: il fac-simile piatto si genera", false)
            return
        }
        let e = RiconoscitoreModulo.riconosci(doc, tipo: .propostaPolizza)
        let dati2 = Set(e.campi.compactMap(\.dato))
        verifica.vero("Moduli: sul PDF piatto le etichette affiancate si separano e si riconoscono (\(dati2.count) dati, \(e.campi.filter(\.firma).count) firme)",
                      !e.acroForm && dati2.isSuperset(of: [.cognome, .nome, .codiceFiscale, .dataNascita, .luogoNascita, .cap, .comune, .iban])
                      && e.campi.filter(\.firma).count == 2)
        verifica.vero("Moduli: sul PDF piatto le caselle proposte sono da confermare", e.campi.allSatisfy { $0.daConfermare && $0.origine == .regole })
        // La casella proposta sta sotto l'etichetta, dove il fac-simile la disegna
        let veri = FacSimileModulo.riquadri(FacSimileModulo.proposta)
        if let cognome = e.campi.first(where: { $0.dato == .cognome }), let vero = veri.first(where: { $0.casella.nome == "cognome" }) {
            verifica.vero("Moduli: la casella del cognome proposta cade nella casella disegnata",
                          vero.riquadro.insetBy(dx: -4, dy: -4).contains(CGPoint(x: cognome.riquadro.midX - cognome.riquadro.width / 4, y: cognome.riquadro.midY)))
        }
        let m = ModelloModulo(titolo: "Proposta piatta", tipo: .propostaPolizza, file: "piatta.pdf", pagine: 1, campi: e.campi)
        let a = CompilatoreModuli.anteprima(m, fonte: fonteDiProva(clienteDiProva()))
        guard let scritto = CompilatoreModuli.scrivi(m, pdf: dati, anteprima: a), let riletto = PDFDocument(data: scritto) else {
            verifica.vero("Moduli: il PDF piatto compilato si scrive", false)
            return
        }
        let testi = riletto.page(at: 0)?.annotations.filter { $0.type == "FreeText" }.compactMap(\.contents) ?? []
        verifica.vero("Moduli: sul PDF piatto il testo va nelle caselle (\(testi.count) testi)", testi.contains("Rossi") && testi.count == a.compilati)
    }

    private static func risposte(_ verifica: VerificaCalcoli) {
        guard let dati = FacSimileModulo.pdf(FacSimileModulo.adeguataVerifica), let doc = PDFDocument(data: dati) else {
            verifica.vero("Moduli: il fac-simile dell'adeguata verifica si genera", false)
            return
        }
        let e = RiconoscitoreModulo.riconosci(doc, tipo: .adeguataVerifica)
        let r = e.campi.filter(\.risposta).compactMap(\.nomeAcroForm)
        verifica.vero("Moduli: titolare effettivo, PEP, origine dei fondi e scopo sono risposte del cliente (\(r))",
                      Set(r) == ["titolare_effettivo", "pep", "origine_fondi", "scopo_rapporto"])
        var m = ModelloModulo(titolo: "Adeguata verifica", tipo: .adeguataVerifica, file: "av.pdf", pagine: 1, campi: e.campi)
        // Anche se qualcuno le associasse a un dato, le risposte non si compilano
        for i in m.campi.indices where m.campi[i].risposta { m.campi[i].dato = .professione }
        let correzioni = Dictionary(uniqueKeysWithValues: m.risposte.map { ($0.id, "scritto a mano") })
        let a = CompilatoreModuli.anteprima(m, fonte: fonteDiProva(clienteDiProva()), correzioni: correzioni)
        let riempite = m.risposte.filter { a.valori[$0.id] != nil }
        verifica.vero("Moduli: nessuna risposta del cliente compilata, neanche con un dato o una correzione (\(riempite.count))",
                      riempite.isEmpty && a.risposte.count == 4)
        verifica.vero("Moduli: sull'adeguata verifica si compilano anagrafica e documento (\(a.compilati) di \(a.totale))",
                      a.compilati == 9 && a.totale == 9)
        let professione = ModelloModulo.Campo(pagina: 0, riquadro: .zero, etichetta: "Professione", dato: .professione, origine: .regole)
        verifica.vero("Moduli: sul questionario anche la professione resta al cliente",
                      RiconoscitoreModulo.applicaTipo(professione, .questionarioAdeguatezza).risposta
                      && !RiconoscitoreModulo.applicaTipo(professione, .propostaPolizza).risposta)
        guard let scritto = CompilatoreModuli.scrivi(m, pdf: dati, anteprima: a) else { return }
        let letti = CompilatoreModuli.valoriAcroForm(scritto)
        verifica.vero("Moduli: nel PDF compilato le dichiarazioni del cliente sono vuote",
                      ["titolare_effettivo", "pep", "origine_fondi", "scopo_rapporto"].allSatisfy { letti[$0] == nil } && letti["cognome"] == "Rossi")
    }

    private static func vera(_ verifica: VerificaCalcoli) {
        let etichette = ["Recapito telefonico", "Codice IBAN", "Titolare effettivo"]
        let messaggi = ModuliVera.messaggi(etichette)
        let inviato = messaggi.map(\.testo).joined(separator: "\n")
        verifica.vero("Moduli: a Vera vanno solo le etichette del modulo vuoto, nessun dato del cliente",
                      etichette.allSatisfy { inviato.contains($0) } && !inviato.contains("Rossi") && !inviato.contains("RSSGLU"))
        let json = #"{"campi":[{"etichetta":"Recapito telefonico","dato":"telefono"},{"etichetta":"Codice IBAN","dato":"iban"},{"etichetta":"Titolare effettivo","dato":"professione"},{"etichetta":"Inventata","dato":"email"},{"etichetta":"Codice IBAN","dato":"risposteQuestionario"}]}"#
        let p = ModuliVera.leggi(json, etichette: etichette) ?? [:]
        verifica.vero("Moduli: Vera propone solo dati ammessi, per etichette date, mai per le risposte del cliente (\(p))",
                      p == ["Recapito telefonico": .telefono, "Codice IBAN": .iban])
        var c = ModelloModulo.Campo(pagina: 0, riquadro: .zero, etichetta: "Recapito telefonico", origine: .acroForm)
        ModuliVera.applica(p, a: &c)
        verifica.vero("Moduli: la proposta di Vera resta da confermare", c.dato == .telefono && c.daConfermare && c.origine == .vera)
    }

    /// Le caselle da spuntare (consensi, scelte) non si spuntano mai da sole, anche se il nome ricorda un dato.
    private static func caselle(_ verifica: VerificaCalcoli) {
        let pagina = PDFPage()
        pagina.setBounds(CGRect(origin: .zero, size: FacSimileModulo.formato), for: .mediaBox)
        for (i, nome) in ["consenso_email", "consenso_telefono", "frequenza_mensile", "frequenza_annuale"].enumerated() {
            let w = PDFAnnotation(bounds: CGRect(x: 60, y: 700 - CGFloat(i) * 40, width: 14, height: 14), forType: .widget, withProperties: nil)
            w.widgetFieldType = .button
            w.widgetControlType = .checkBoxControl
            w.fieldName = nome
            w.buttonWidgetState = .offState
            pagina.addAnnotation(w)
        }
        let testo = PDFAnnotation(bounds: CGRect(x: 60, y: 500, width: 200, height: 20), forType: .widget, withProperties: nil)
        testo.widgetFieldType = .text
        testo.fieldName = "email"
        pagina.addAnnotation(testo)
        let doc = PDFDocument()
        doc.insert(pagina, at: 0)
        guard let dati = doc.dataRepresentation(), let riletto = PDFDocument(data: dati) else {
            verifica.vero("Moduli: il PDF di prova con le caselle si genera", false)
            return
        }
        let e = RiconoscitoreModulo.riconosci(riletto, tipo: .privacy)
        let caselle = e.campi.filter { $0.tipo == .casella }
        verifica.vero("Moduli: le caselle da spuntare non prendono un dato dalle regole (\(caselle.count) caselle)",
                      caselle.count == 4 && caselle.allSatisfy { $0.dato == nil })
        var campi = e.campi
        // Anche se una casella avesse un dato (un archivio di prima), non si riempie
        for i in campi.indices where campi[i].tipo == .casella { campi[i].dato = .email }
        let m = ModelloModulo(titolo: "Privacy (prova)", tipo: .privacy, file: "privacy.pdf", pagine: 1, campi: campi, mappaConfermata: true)
        let a = CompilatoreModuli.anteprima(m, fonte: fonteDiProva(clienteDiProva()))
        let piene = m.campi.filter { $0.tipo == .casella && a.valori[$0.id] != nil }
        verifica.vero("Moduli: nessuna casella da spuntare nell'anteprima, l'email sì", piene.isEmpty && a.compilati == 1)
        var forzata = a
        for c in m.campi where c.tipo == .casella { forzata.valori[c.id] = ValoreCampo(testo: "sì") }
        guard let scritto = CompilatoreModuli.scrivi(m, pdf: dati, anteprima: forzata), let fatto = PDFDocument(data: scritto) else {
            verifica.vero("Moduli: il PDF con le caselle si scrive", false)
            return
        }
        let spuntate = (fatto.page(at: 0)?.annotations ?? []).filter { $0.isCasella && $0.buttonWidgetState == .onState }
        verifica.vero("Moduli: nel PDF scritto nessuna casella è spuntata da Prisma (\(spuntate.count))", spuntate.isEmpty)
    }

    /// L'anteprima appartiene a un cliente e a un modello; la mappa va confermata prima di compilare; un modulo per
    /// un'altra proposta non sostituisce quello di prima nei Documenti.
    private static func statoCompilazione(_ verifica: VerificaCalcoli) {
        let s = StatoShell(persistente: false)
        let clienti = s.dati.clienti
        guard clienti.count >= 2 else {
            verifica.vero("Moduli: servono due clienti di prova", false)
            return
        }
        let a = clienti[0], b = clienti[1]
        s.caricaEsempiModuli()
        s.moduli.scelto = "modulo-prova-\(TipoModulo.propostaPolizza.rawValue)"
        s.moduli.clienteId = nil
        s.clienteAttivoId = a.id
        s.compilaModulo()
        let campo = s.moduli.modelloScelto?.campiConDato.first?.id ?? ""
        s.correggiCampoModulo(campo, "scritto per A")
        verifica.vero("Moduli: l'anteprima è del cliente attivo", s.anteprimaModulo?.clienteId == a.id && s.moduli.correzioni[campo] != nil)
        s.clienteAttivoId = b.id
        let documentiPrima = s.dati.documenti.count
        s.salvaModuloNelDossier()
        verifica.vero("Moduli: cambiato il cliente attivo l'anteprima di prima non si mostra, non si salva e non va al cliente",
                      s.anteprimaModulo == nil && s.pdfModuloCompilato() == nil && s.moduloPerCliente() == nil
                      && s.dati.documenti.count == documentiPrima)
        s.compilaModulo()
        verifica.vero("Moduli: compilando per l'altro cliente le correzioni di prima non passano",
                      s.anteprimaModulo?.clienteId == b.id && s.moduli.correzioni.isEmpty
                      && s.anteprimaModulo?.valori.values.contains { $0.testo == "scritto per A" } == false)

        // Due proposte diverse lo stesso giorno: due documenti; la stessa proposta: sostituisce
        let pdf = FacSimileModulo.pdf(FacSimileModulo.proposta) ?? Data()
        let primo = s.archiviaPDF(pdf, titolo: "Modulo · Prova", tipo: .modulo, cliente: b.id, posizioneId: "proposta-1")
        let secondo = s.archiviaPDF(pdf, titolo: "Modulo · Prova", tipo: .modulo, cliente: b.id, posizioneId: "proposta-2")
        let terzo = s.archiviaPDF(pdf, titolo: "Modulo · Prova", tipo: .modulo, cliente: b.id, posizioneId: "proposta-2")
        let restano = Set(s.dati.documenti.filter { $0.clienteId == b.id && $0.titolo == "Modulo · Prova" }.map(\.id))
        verifica.vero("Moduli: un modulo per un'altra proposta non toglie quello di prima, la stessa proposta lo sostituisce",
                      restano == Set([primo, terzo].compactMap { $0 }) && secondo != nil)

        // Un modulo caricato con la mappa da controllare non si compila
        guard let vuoto = FacSimileModulo.pdf(FacSimileModulo.proposta), let m = s.importaModulo(vuoto, nome: "Proposta caricata") else {
            verifica.vero("Moduli: il modulo caricato si legge", false)
            return
        }
        s.annullaRevisioneModulo()
        s.moduli.scelto = m.id
        s.compilaModulo()
        verifica.vero("Moduli: con la mappa da controllare non si compila e si apre la revisione",
                      s.anteprimaModulo == nil && s.moduli.anteprima == nil && s.moduli.revisione?.id == m.id)
    }
}
