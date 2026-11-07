import Foundation

/// Prova degli scenari «E se…?» dentro `Prisma --prova-vera`: istruzioni e schema nel pacchetto, riconoscimento delle
/// frasi di Vera/Esempi/scenari.json, estrazione con le regole e dal JSON di un Qwen finto (un server Ollama finto dentro
/// il processo, ServerFintoScenari), la domanda quando manca un dato, i calcoli di MotoreScenari sui clienti di prova
/// (Marco a 63 anni senza versamenti: rendita più bassa e divario più alto di oggi), il racconto fedele alle cifre,
/// il salvataggio nel dossier, l'apertura nel simulatore e «Qwen non è pronto».
enum ProvaScenariVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        let esempi = leggiEsempi()
        controlla(esempi != nil, "Scenari: esempi nel pacchetto (Vera/Esempi/scenari.json)")
        if let esempi {
            riconoscimento(esempi, controlla)
            estrazione(esempi, controlla)
        }
        motore(controlla)
        corpi(controlla)
        modelloFinto(controlla)
        conversazione(controlla)
        #if os(macOS)
        // Su iPhone e iPad la verifica cerca il Mac in rete (PonteVera): lì la prova la fa il ponte (ProvaNucleoVera)
        nonPronto(controlla)
        #endif
    }

    // MARK: - Istruzioni, schema, esempi

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let istruzioni = IstruzioniVera.testo("scenari") ?? ""
        controlla(istruzioni.contains("JSON") && istruzioni.contains("etaPensione") && istruzioni.contains("Non fare conti"),
                  "Scenari: istruzioni di Qwen nel pacchetto (Vera/Istruzioni/scenari.md), solo JSON e niente conti")
        let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Schemi/scenario.json")
        let file = url.flatMap { try? Data(contentsOf: $0) }.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
        controlla(file != nil, "Scenari: schema JSON nel pacchetto (Vera/Schemi/scenario.json)")
        guard let file else { return }
        func chiavi(_ s: [String: Any]) -> Set<String> { Set(((s["properties"] as? [String: Any]) ?? [:]).keys) }
        func richiesti(_ s: [String: Any]) -> Set<String> { Set((s["required"] as? [String]) ?? []) }
        func aree(_ s: [String: Any]) -> [String] { (((s["properties"] as? [String: Any])?["area"] as? [String: Any])?["enum"] as? [String]) ?? [] }
        let interno = ScenariVera.schemaInterno
        controlla(chiavi(file) == chiavi(interno) && richiesti(file) == richiesti(interno) && aree(file) == aree(interno)
                  && chiavi(file).isSuperset(of: ["cliente", "etaPensione", "versamentoMensile", "smetteDiVersare", "capitale", "rendimento", "durata", "area", "mancanti"]),
                  "Scenari: lo schema della cartella coincide con quello nel codice (campi \(chiavi(file).sorted().joined(separator: ", ")))")
    }

    struct Esempio {
        let frase: String
        let attivo: String
        let regole: Bool
        let domanda: Bool
        let modello: [String: Any]
        let atteso: ParametriScenarioVera
    }

    private static func leggiEsempi() -> (esempi: [Esempio], nonScenari: [String])? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Esempi/scenari.json"),
              let d = try? Data(contentsOf: url), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let elenco = j["esempi"] as? [[String: Any]] else { return nil }
        let esempi = elenco.compactMap { e -> Esempio? in
            guard let frase = e["frase"] as? String, let attivo = e["attivo"] as? String,
                  let modello = e["modello"] as? [String: Any], let a = e["atteso"] as? [String: Any] else { return nil }
            var p = ParametriScenarioVera()
            p.clienteId = a["clienteId"] as? String
            p.area = (a["area"] as? String).flatMap { AreaScenarioVera(rawValue: $0) }
            p.etaPensione = (a["etaPensione"] as? NSNumber)?.intValue
            p.versamentoMensile = (a["versamentoMensile"] as? NSNumber)?.doubleValue
            p.variazioneVersamento = (a["variazioneVersamento"] as? NSNumber)?.doubleValue
            p.smetteDiVersare = (a["smetteDiVersare"] as? Bool) ?? false
            p.capitale = (a["capitale"] as? NSNumber)?.doubleValue
            p.rendimento = (a["rendimento"] as? NSNumber)?.doubleValue
            p.durata = (a["durata"] as? NSNumber)?.intValue
            return Esempio(frase: frase, attivo: attivo, regole: (e["regole"] as? Bool) ?? false, domanda: (e["domanda"] as? Bool) ?? false,
                           modello: modello, atteso: p)
        }
        return (esempi, (j["nonScenari"] as? [String]) ?? [])
    }

    // MARK: - Riconoscimento ed estrazione

    private static func riconoscimento(_ e: (esempi: [Esempio], nonScenari: [String]), _ controlla: (Bool, String) -> Void) {
        let mancati = e.esempi.filter { !ScenariVera.sembraScenario($0.frase) }.map(\.frase)
        controlla(mancati.isEmpty && !e.esempi.isEmpty, "Scenari: riconosciute le \(e.esempi.count) frasi «E se…?»" + (mancati.isEmpty ? "" : " (mancano: \(mancati.joined(separator: " | ")))"))
        let sbagliati = e.nonScenari.filter { ScenariVera.sembraScenario($0) }
        controlla(sbagliati.isEmpty, "Scenari: domande, spunti e comandi restano tali" + (sbagliati.isEmpty ? "" : " (presi per scenari: \(sbagliati.joined(separator: " | ")))"))
    }

    private static func estrazione(_ e: (esempi: [Esempio], nonScenari: [String]), _ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        let noti = s.dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        for x in e.esempi {
            let r = ScenariVera.regole(x.frase, clienti: noti, attivo: x.attivo, etaPensioneAttuale: { s.etaPensioneScenario($0) })
            if x.regole {
                controlla(r.stessi(x.atteso), "Scenari, regole: «\(x.frase)» → \(r.descrizione)")
            }
            let json = String(data: (try? JSONSerialization.data(withJSONObject: x.modello)) ?? Data(), encoding: .utf8) ?? ""
            let letto = ScenariVera.leggiJSON("Ecco:\n```json\n" + json + "\n```", clienti: noti, attivo: x.attivo)
            controlla(letto?.scenario == true && (letto?.parametri.stessi(x.atteso) ?? false),
                      "Scenari, JSON di Qwen: «\(x.frase)» → \(letto?.parametri.descrizione ?? "non letto")")
            let unito = ScenariVera.unisci(modello: letto?.parametri ?? ParametriScenarioVera(), regole: r)
            controlla(unito.stessi(x.atteso), "Scenari, Qwen e regole insieme: «\(x.frase)»")
            let domanda = ScenariVera.domandaMancante(unito, cliente: unito.clienteId.flatMap { s.cliente($0) })
            controlla((domanda != nil) == x.domanda, x.domanda ? "Scenari: manca l'area, Vera chiede «\(domanda ?? "")»" : "Scenari: «\(x.frase)» si calcola senza domande")
        }
        // Un modello che sbaglia una cifra scritta nella frase: vincono le regole
        let frase = "E se Marco va in pensione a 63 anni e smette di versare?"
        let regole = ScenariVera.regole(frase, clienti: noti, attivo: "giulia")
        let sbagliato = ScenariVera.leggiJSON(#"{"scenario":true,"cliente":"Giulia","area":"investimenti","etaPensione":65,"smetteDiVersare":false,"mancanti":[]}"#,
                                             clienti: noti, attivo: "giulia")
        let corretto = ScenariVera.unisci(modello: sbagliato?.parametri ?? ParametriScenarioVera(), regole: regole)
        controlla(corretto.etaPensione == 63 && corretto.clienteId == "marco" && corretto.smetteDiVersare && corretto.area == .previdenza,
                  "Scenari: le cifre e il cliente scritti nella frase vincono su quelli di Qwen")
        controlla(ScenariVera.leggiJSON("Non saprei.", clienti: noti, attivo: "giulia") == nil, "Scenari: una risposta senza JSON non si legge")
        let numeri = ScenariVera.leggiJSON(#"{"scenario":true,"cliente":"","area":"risparmio","capitale":"50.000","durata":0,"smetteDiVersare":false,"mancanti":[]}"#,
                                          clienti: noti, attivo: "giulia")
        controlla(numeri?.parametri.capitale == 50_000 && numeri?.parametri.durata == nil,
                  "Scenari: importi scritti come testo e zeri al posto di «non c'è»")
        controlla(ScenariVera.euro("20", "mila") == 20_000 && ScenariVera.euro("1.500,50") == 1_500.5 && ScenariVera.euro("2.500") == 2_500,
                  "Scenari: importi all'italiana («20 mila», «1.500,50»)")
    }

    // MARK: - I calcoli di Prisma

    private static func motore(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        guard let marco = s.fonteVera("marco") else { return controlla(false, "Scenari: fonte di Marco") }
        var p = ParametriScenarioVera()
        p.clienteId = "marco"
        p.area = .previdenza
        p.etaPensione = 63
        p.smetteDiVersare = true
        guard let x = MotoreScenari.calcola(p, fonte: marco, chiave: "marco") else { return controlla(false, "Scenari: scheda di Marco") }
        func coppia(_ k: String) -> (Double, Double) { x.riga(k).map { ($0.valoreOggi, $0.valoreScenario) } ?? (0, 0) }
        let rendita = coppia("rendita"), divario = coppia("divario"), pubblica = coppia("pensionePubblica"), capitale = coppia("capitale")
        controlla(rendita.1 < rendita.0 && rendita.1 > 0, "Scenari, Marco a 63 anni senza versamenti: rendita dei piani più bassa (\(Int(rendita.0)) → \(Int(rendita.1)) € al mese)")
        controlla(divario.1 > divario.0, "Scenari, Marco a 63 anni: divario da coprire più alto (\(Int(divario.0)) → \(Int(divario.1)) € al mese)")
        controlla(pubblica.1 < pubblica.0 && capitale.1 < capitale.0,
                  "Scenari, Marco a 63 anni: pensione pubblica più bassa con la stima contributiva (\(Int(pubblica.0)) → \(Int(pubblica.1))) e meno capitale nei piani")
        let oggi = MotorePrevidenza.calcola(marco.posizioni.filter { $0.stato != .proposta }, cliente: marco.cliente, analisi: marco.analisi.previdenza, data: marco.oggi)
        controlla(abs(rendita.0 - oggi.renditaInEssere) < 0.01 && abs(divario.0 - oggi.divarioResiduo) < 0.01,
                  "Scenari: la colonna «oggi» è quella del piano previdenziale di Prisma, con le ipotesi del cliente")
        controlla(x.colonnaOggi == "Oggi (\(oggi.etaPensione) anni)" && x.colonnaScenario == "Scenario (63 anni)",
                  "Scenari: le colonne dicono le due età (\(x.colonnaOggi) · \(x.colonnaScenario))")
        controlla(x.simulazione?.versamentoMensile == 0 && x.simulazione?.anni == 63 - oggi.eta && x.simulazione?.clienteId == "marco",
                  "Scenari: l'ipotesi per il simulatore ha i versamenti fermi e gli anni fino ai 63")
        controlla(x.racconto.contains("anticipata") || x.racconto.contains("requisiti"),
                  "Scenari: a 63 anni Prisma avvisa dei requisiti della pensione anticipata")
        controlla(CommentoVera.numeriConservati(bozza: x.bozza, testo: x.racconto) && x.racconto.contains("63"),
                  "Scenari: il racconto di Prisma usa solo le cifre della scheda («\(x.racconto.prefix(90))…»)")
        let ilMarcoDiOggi = MotoreScenari.calcola(ParametriScenarioVera.conArea(.previdenza, cliente: "marco"), fonte: marco, chiave: "marco")
        controlla(ilMarcoDiOggi?.righe.allSatisfy { abs($0.valoreOggi - $0.valoreScenario) < 0.01 } ?? false,
                  "Scenari: senza cambiamenti le due colonne coincidono")

        // Le altre aree sui clienti di prova
        if let laura = s.fonteVera("laura") {
            var q = ParametriScenarioVera.conArea(.investimenti, cliente: "laura")
            q.capitale = 20_000
            q.durata = 10
            q.rendimento = 4
            let y = MotoreScenari.calcola(q, fonte: laura, chiave: "laura")
            let c = y?.riga("capitaleIniziale")
            controlla(c.map { abs($0.valoreScenario - $0.valoreOggi - 20_000) < 0.01 } ?? false
                      && (y?.riga("capitaleScadenza").map { $0.valoreScenario > $0.valoreOggi } ?? false) && y?.simulazione?.anni == 10,
                      "Scenari, Laura: 20.000 € in più negli investimenti per 10 anni al 4%")
            var smette = ParametriScenarioVera.conArea(.previdenza, cliente: "laura")
            smette.smetteDiVersare = true
            let z = MotoreScenari.calcola(smette, fonte: laura, chiave: "laura")
            controlla(z?.riga("rendita").map { $0.valoreScenario < $0.valoreOggi } ?? false, "Scenari, Laura smette di versare nel fondo pensione: rendita più bassa")
        }
        if let giulia = s.fonteVera("giulia") {
            var q = ParametriScenarioVera.conArea(.risparmio, cliente: "giulia")
            q.versamentoMensile = 400
            let y = MotoreScenari.calcola(q, fonte: giulia, chiave: "giulia")
            controlla(y?.riga("versamento")?.valoreScenario == 400 && y?.riga("copertura") != nil, "Scenari, Giulia: 400 € al mese per la casa")
        }
        if let sofia = s.fonteVera("sofia") {
            var q = ParametriScenarioVera.conArea(.previdenza, cliente: "sofia")
            q.etaPensione = 65
            let y = MotoreScenari.calcola(q, fonte: sofia, chiave: "sofia")
            controlla(y?.riga("pensionePubblica").map { $0.valoreScenario < $0.valoreOggi } ?? false, "Scenari, Sofia due anni prima: pensione pubblica più bassa")
        }
        var tutela = ParametriScenarioVera.conArea(.protezione, cliente: "marco")
        tutela.capitale = 100_000
        let w = MotoreScenari.calcola(tutela, fonte: marco, chiave: "marco")
        controlla((w?.riga("capitaleVita").map { abs($0.valoreScenario - $0.valoreOggi - 100_000) < 0.01 } ?? false)
                  && (w?.riga("divario").map { $0.valoreScenario <= $0.valoreOggi } ?? false) && w?.simulazione == nil,
                  "Scenari, Marco: 100.000 € di copertura caso morte in più riducono il divario (in protezione si apre Analisi 360)")
    }

    // MARK: - Le richieste a Qwen

    private static func corpi(_ controlla: (Bool, String) -> Void) {
        let vera = ImpostazioniVera()
        let o = ScenariVera.opzioniEstrazione(vera)
        let messaggi = [MessaggioModello(ruolo: .utente, testo: "x")]
        let ollama = FornitoreOllama.corpo(modello: "qwen3.5:4b", messaggi: messaggi, opzioni: o)
        let formato = ollama["format"] as? [String: Any]
        let opzioni = ollama["options"] as? [String: Any] ?? [:]
        controlla((formato?["required"] as? [String])?.contains("smetteDiVersare") == true && (ollama["think"] as? Bool) == false
                  && (opzioni["temperature"] as? Double) == 0 && (opzioni["num_ctx"] as? Int) == NucleoVera.finestra,
                  "Scenari: a Ollama lo schema in «format», temperatura 0, senza ragionamento, stessa finestra")
        let openAI = FornitoreCompatibileOpenAI.corpo(modello: "m", messaggi: messaggi, opzioni: o)
        controlla(((openAI["response_format"] as? [String: Any])?["type"] as? String) == "json_schema",
                  "Scenari: al server compatibile OpenAI lo schema in «response_format»")
        controlla(FornitoreOllama.corpo(modello: "m", messaggi: messaggi, opzioni: OpzioniModello())["format"] == nil,
                  "Scenari: le altre risposte restano testo libero")
    }

    /// Estrazione e racconto con un Qwen finto: il JSON dello schema, poi un racconto fedele e uno con una cifra inventata.
    private static func modelloFinto(_ controlla: (Bool, String) -> Void) {
        let configurazione = URLSessionConfiguration.ephemeral
        configurazione.protocolClasses = [ServerFintoScenari.self]
        let sessione = URLSession(configuration: configurazione)
        let vera = ImpostazioniVera()
        let motore = MotoreLocale(vera, disponibilita: .pronto, sessione: sessione)
        let s = StatoShell(persistente: false)
        let noti = s.dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        let frase = "E se Marco va in pensione a 63 anni e smette di versare?"
        let json = #"{"scenario":true,"cliente":"Marco","area":"previdenza","etaPensione":63,"smetteDiVersare":true,"mancanti":[]}"#
        ServerFintoScenari.prepara([json])
        let messaggi = ScenariVera.messaggiEstrazione(frase: frase, attivo: s.cliente("giulia"), etaPensione: s.etaPensioneScenario("giulia"), clienti: noti)
        let r = aspetta { try? await motore.scrivi(messaggi, opzioni: ScenariVera.opzioniEstrazione(vera)).testo }
        let ricevuto = ServerFintoScenari.ultimo
        let sistema = ((ricevuto["messages"] as? [[String: Any]])?.first?["content"] as? String) ?? ""
        let utente = ((ricevuto["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        controlla(sistema.contains("E se") && utente.contains("Marco Bianchi") && utente.contains(frase) && ricevuto["format"] != nil,
                  "Scenari, Qwen finto: la richiesta porta istruzioni, nomi dei clienti, frase e schema")
        let letto = r.flatMap { ScenariVera.leggiJSON($0, clienti: noti, attivo: "giulia") }
        controlla(letto?.parametri.clienteId == "marco" && letto?.parametri.etaPensione == 63 && letto?.parametri.smetteDiVersare == true,
                  "Scenari, Qwen finto: il JSON in streaming ricomposto e letto (\(letto?.parametri.descrizione ?? r ?? "niente"))")
        guard let p = letto?.parametri, let fonte = s.fonteVera("marco"), let scheda = MotoreScenari.calcola(p, fonte: fonte, chiave: "giulia") else {
            return controlla(false, "Scenari, Qwen finto: scheda di Marco")
        }
        let fedele = "Andando in pensione prima e fermando i versamenti, Marco avrebbe meno rendita e un divario più ampio: ne parlerei con lui."
        let inventato = "Marco perderebbe circa 999.999 € e la pensione scenderebbe del 47%."
        ServerFintoScenari.prepara([fedele, inventato])
        let racconto = ScenariVera.messaggiRacconto(scheda, domanda: frase, ambiente: AmbienteVera(cliente: "Giulia Rossi"))
        let primo = aspetta { try? await motore.scrivi(racconto, opzioni: OpzioniModello()).testo } ?? ""
        let secondo = aspetta { try? await motore.scrivi(racconto, opzioni: OpzioniModello()).testo } ?? ""
        let corpoRacconto = ((ServerFintoScenari.ultimo["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        controlla(corpoRacconto.contains("SCENARIO CALCOLATO DA PRISMA") && scheda.righe.allSatisfy { corpoRacconto.contains($0.scenario) },
                  "Scenari, Qwen finto: il racconto riceve la scheda di Prisma con le cifre esatte")
        controlla(primo == fedele && CommentoVera.numeriConservati(bozza: scheda.bozza + "\n" + frase, testo: primo)
                  && !CommentoVera.numeriConservati(bozza: scheda.bozza + "\n" + frase, testo: secondo),
                  "Scenari, Qwen finto: un racconto con una cifra inventata non passa (resta quello di Prisma)")
    }

    // MARK: - Nella conversazione

    private static func conversazione(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.rispostePreparate = true
        s.clienteAttivoId = "marco"
        s.chiediVera("E se Marco va in pensione a 63 anni e smette di versare?")
        let m = s.conversazione("marco").last
        controlla(m?.scenario?.clienteId == "marco" && m?.scenario?.area == .previdenza && m?.motore == MotoriVera.sintesi.nome
                  && s.conversazione("marco").count == 2,
                  "Scenari nella conversazione: domanda e risposta con la scheda prima/dopo")
        controlla(m.map { s.quadroVera(per: $0, in: s.conversazione("marco"), portafoglio: false) == nil } ?? false,
                  "Scenari: sotto lo scenario niente altro quadro")
        // Salva nel dossier e apri in Simulazioni
        if let scheda = m?.scenario, let id = m?.id {
            let prima = s.simulazioniCliente("marco").count
            s.salvaScenarioVera(scheda, messaggio: id)
            let dopo = s.conversazione("marco").last?.scenario
            controlla(s.simulazioniCliente("marco").count == prima + 1 && dopo?.salvataId != nil
                      && s.simulazioniCliente("marco").contains { $0.id == dopo?.salvataId && $0.versamentoMensile == 0 },
                      "Scenari: «Salva nel dossier» lo mette tra gli scenari del cliente e la scheda lo ricorda")
            s.salvaScenarioVera(dopo ?? scheda, messaggio: id)
            controlla(s.simulazioniCliente("marco").count == prima + 1, "Scenari: salvato una volta sola")
            s.clienteAttivoId = "giulia"
            s.apriScenarioVera(scheda)
            controlla(s.bozzaSimulazione == scheda.simulazione && s.schedaSimulazioni == .simulatore && s.clienteAttivoId == "marco",
                      "Scenari: «Apri in Simulazioni» porta nel simulatore con i parametri dello scenario")
        }
        // In protezione: la nota del taccuino
        s.clienteAttivoId = "marco"
        s.chiediVera("Ipotizziamo che Marco aumenti la copertura caso morte di 100.000 €")
        if let t = s.conversazione("marco").last, let scheda = t.scenario {
            let note = s.dati.note.count
            s.salvaScenarioVera(scheda, messaggio: t.id)
            controlla(s.dati.note.count == note + 1 && s.conversazione("marco").last?.scenario?.notaId != nil,
                      "Scenari: in protezione «Salva nel dossier» scrive una nota del taccuino")
            s.apriScenarioVera(scheda)
            controlla(s.areaAnalisi == .protezione, "Scenari: in protezione si apre l'area di Analisi 360")
        } else {
            controlla(false, "Scenari: scenario di protezione")
        }
        // Manca l'area: Vera chiede, la risposta completa lo scenario
        s.clienteAttivoId = "giulia"
        s.chiediVera("Che succede se versa 100 € in più al mese?")
        let domanda = s.conversazione("giulia").last
        controlla(domanda?.motore == StatoShell.motoreAzioni && domanda?.scenario == nil && s.scenarioInSospeso != nil
                  && (domanda?.testo ?? "").contains("previdenza, investimenti, risparmio o protezione"),
                  "Scenari: se manca l'area Vera la chiede («\(domanda?.testo ?? "")»)")
        s.chiediVera("Sul risparmio")
        let completo = s.conversazione("giulia").last?.scenario
        controlla(completo?.area == .risparmio && completo?.parametri.variazioneVersamento == 100 && s.scenarioInSospeso == nil,
                  "Scenari: la risposta completa lo scenario (risparmio, 100 € in più al mese)")
        s.chiediVera("E se versasse 200 € al mese?")
        s.chiediVera("lascia stare")
        controlla(s.scenarioInSospeso == nil && (s.conversazione("giulia").last?.testo ?? "").contains("lascio stare"),
                  "Scenari: «lascia stare» chiude lo scenario in sospeso")
        // Le altre domande restano domande
        let prima = s.conversazione("giulia").count
        s.chiediVera("Cos'è un PIP?")
        controlla(s.conversazione("giulia").count == prima + 2 && s.conversazione("giulia").last?.scenario == nil,
                  "Scenari: «Cos'è un PIP?» resta una domanda a Vera")
        // Dal portafoglio: solo con un cliente nominato
        s.veraPortafoglio = true
        s.chiediVeraPortafoglio("E se Laura smette di versare nel fondo pensione?")
        controlla(s.conversazione(VeraPortafoglio.chiave).last?.scenario?.clienteId == "laura",
                  "Scenari: anche dalla conversazione del portafoglio, sul cliente nominato")
        s.veraPortafoglio = false
        // In modalità cliente niente scenari di altri clienti
        s.clienteAttivoId = "marco"
        s.entraModoCliente()
        s.chiediVera("E se Laura smette di versare nel fondo pensione?")
        controlla(s.conversazione("marco").last?.scenario == nil && (s.conversazione("marco").last?.testo ?? "").contains("modalità cliente"),
                  "Scenari: in modalità cliente Vera resta sul cliente davanti a te")

        // La scheda si conserva con la conversazione (archivio e backup)
        if let originale = m, let d = try? JSONEncoder().encode(originale), let letto = try? JSONDecoder().decode(MessaggioVera.self, from: d) {
            controlla(letto == originale && letto.scenario?.righe.count == originale.scenario?.righe.count,
                      "Scenari: la scheda prima/dopo si salva e si rilegge con il messaggio")
        } else {
            controlla(false, "Scenari: messaggio con la scheda da salvare")
        }
    }

    #if os(macOS)
    /// Qwen spento: Vera lo dice e non risponde (niente scheda inventata, niente cifre).
    private static func nonPronto(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "marco"
        s.disponibilitaLocale = .nonDisponibile("Ollama non risponde sul Mac.")
        // Un indirizzo del Mac dove non ascolta nessuno: la verifica fallisce subito
        s.dati.impostazioni.vera.indirizzoLocale = "http://127.0.0.1:9"
        let partita = s.chiediVera("E se Marco va in pensione a 63 anni e smette di versare?")
        let fine = Date().addingTimeInterval(8)
        while s.conversazione("marco").last?.autore != .vera && Date() < fine {
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        let ultimo = s.conversazione("marco").last
        controlla(partita && ultimo?.titolo == "Qwen non è pronto" && ultimo?.scenario == nil && !s.veraInCorso,
                  "Scenari: se Qwen non è pronto Vera lo dice e non risponde («\(ultimo?.testo.prefix(60) ?? "")…»)")
    }
    #endif

    /// Aspetta un lavoro asincrono dal thread delle prove.
    private static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaScenari<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }
}

private final class ScatolaScenari<T>: @unchecked Sendable {
    var valore: T?
}

extension ParametriScenarioVera {
    /// Uno scenario vuoto su un'area e un cliente (per le prove).
    static func conArea(_ a: AreaScenarioVera, cliente: String) -> ParametriScenarioVera {
        var p = ParametriScenarioVera()
        p.area = a
        p.clienteId = cliente
        return p
    }
}

/// Un Qwen finto: un server Ollama dentro il processo che risponde, una dopo l'altra, con le risposte preparate
/// (il JSON dello schema o un racconto), in streaming a pezzi come dalla rete; ricorda l'ultima richiesta.
final class ServerFintoScenari: URLProtocol {
    private static let blocco = NSLock()
    private static var coda: [String] = []
    private static var _ultimo: [String: Any] = [:]

    static func prepara(_ risposte: [String]) {
        blocco.lock(); defer { blocco.unlock() }
        coda = risposte
    }

    static var ultimo: [String: Any] {
        blocco.lock(); defer { blocco.unlock() }
        return _ultimo
    }

    private static func prossima(_ corpo: [String: Any]) -> String {
        blocco.lock(); defer { blocco.unlock() }
        _ultimo = corpo
        return coda.isEmpty ? "" : coda.removeFirst()
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    private static func corpo(_ r: URLRequest) -> [String: Any] {
        var dati = r.httpBody ?? Data()
        if dati.isEmpty, let s = r.httpBodyStream {
            s.open()
            var buffer = [UInt8](repeating: 0, count: 4_096)
            while s.hasBytesAvailable {
                let n = s.read(&buffer, maxLength: buffer.count)
                if n <= 0 { break }
                dati.append(buffer, count: n)
            }
            s.close()
        }
        return (try? JSONSerialization.jsonObject(with: dati) as? [String: Any]) ?? [:]
    }

    private static func json(_ o: [String: Any]) -> String {
        String(data: (try? JSONSerialization.data(withJSONObject: o)) ?? Data(), encoding: .utf8) ?? ""
    }

    /// Una risposta preparata fatta di chiamate a strumenti (come le manda Ollama con «tools»): da passare a `prepara`.
    static func strumenti(_ chiamate: [(String, [String: Any])], testo: String = "") -> String {
        prefissoStrumenti + json(["testo": testo, "chiamate": chiamate.map { ["function": ["name": $0.0, "arguments": $0.1] as [String: Any]] }])
    }

    private static let prefissoStrumenti = "§STRUMENTI§"

    /// Un vettore finto per /api/embed: le parole del testo (con RicercaVera.parole) sparse su 64 dimensioni, normalizzato.
    /// Testi con parole in comune si somigliano: basta per provare la ricerca senza il modello vero.
    static func vettoreFinto(_ testo: String) -> [Double] {
        var v = [Double](repeating: 0, count: 64)
        for p in RicercaVera.parole(testo.replacingOccurrences(of: RicercaVera.istruzione, with: "")) {
            let h = p.unicodeScalars.reduce(5381) { ($0 &* 33 &+ Int($1.value)) & 0x7fffffff }
            v[h % 64] += 1
        }
        let n = sqrt(v.reduce(0) { $0 + $1 * $1 })
        return n > 0 ? v.map { $0 / n } : v
    }

    private static let blocchoEmbed = NSLock()
    private static var _chiamateEmbed = 0
    static var chiamateEmbed: Int { blocchoEmbed.lock(); defer { blocchoEmbed.unlock() }; return _chiamateEmbed }

    override func startLoading() {
        if request.url?.path.hasSuffix("api/embed") == true {
            let corpo = Self.corpo(request)
            let testi = corpo["input"] as? [String] ?? []
            Self.blocchoEmbed.lock(); Self._chiamateEmbed += 1; Self.blocchoEmbed.unlock()
            let dati = (try? JSONSerialization.data(withJSONObject: ["model": corpo["model"] ?? "", "embeddings": testi.map(Self.vettoreFinto)])) ?? Data()
            let r = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: r, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: dati)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        var risposta = Self.prossima(Self.corpo(request))
        var righe: [String] = []
        // Le chiamate a strumenti arrivano in una riga sola, con il contenuto vuoto (come da Ollama)
        if risposta.hasPrefix(Self.prefissoStrumenti),
           let d = risposta.dropFirst(Self.prefissoStrumenti.count).data(using: .utf8),
           let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
            righe.append(Self.json(["message": ["role": "assistant", "content": "", "tool_calls": j["chiamate"] ?? []] as [String: Any], "done": false]))
            risposta = j["testo"] as? String ?? ""
        }
        // La risposta in pezzi da 9 caratteri, una riga NDJSON per pezzo, poi la riga finale
        var resto = Substring(risposta)
        while !resto.isEmpty {
            let pezzo = resto.prefix(9)
            resto = resto.dropFirst(pezzo.count)
            righe.append(Self.json(["message": ["role": "assistant", "content": String(pezzo)], "done": false]))
        }
        righe.append(Self.json(["message": ["role": "assistant", "content": ""], "done": true]))
        let r = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/x-ndjson"])!
        client?.urlProtocol(self, didReceive: r, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data((righe.joined(separator: "\n") + "\n").utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
