import Foundation

/// Prova della palestra della trattativa dentro `Prisma --prova-vera` («Luce» giro 5, Studio › Palestra): istruzioni,
/// schema ed esempi nel pacchetto, la scheda della recita con le cifre di Prisma, i tre livelli di difficoltà, la lettura
/// del JSON (valido, illeggibile, con cifre inventate), il giudizio misto (le regole di Prisma vincono su Qwen), il
/// punteggio, un allenamento intero con il Qwen finto (ServerFintoScenari), «Qwen non è pronto» e il registro leggero.
enum ProvaPalestraVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        pacchetto(controlla)
        let s = StatoShell(persistente: false)
        guard let f = s.fonteVera("giulia") else { return controlla(false, "Palestra: fonte di Giulia") }
        let scheda = PalestraVera.scheda(f)
        schedaRecita(scheda, s, controlla)
        livelli(scheda, controlla)
        lettura(scheda, controlla)
        giudizio(scheda, controlla)
        modelloFinto(scheda, controlla)
        #if os(macOS)
        allenamento(controlla)
        nonPronta(controlla)
        #endif
        registro(controlla)
        studio(controlla)
    }

    // MARK: - Pacchetto

    private static func pacchetto(_ controlla: (Bool, String) -> Void) {
        let istruzioni = IstruzioniVera.testo("palestra") ?? ""
        controlla(istruzioni.contains("JSON") && istruzioni.contains("Difficile") && istruzioni.contains("cifra che non viene da Prisma")
                  && istruzioni.contains("prossimaObiezione"),
                  "Palestra: istruzioni di Qwen nel pacchetto (Vera/Istruzioni/palestra.md), solo JSON e nessuna cifra inventata")
        let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Schemi/palestra.json")
        let file = url.flatMap { try? Data(contentsOf: $0) }.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }
        func chiavi(_ s: [String: Any]) -> Set<String> { Set(((s["properties"] as? [String: Any]) ?? [:]).keys) }
        func richiesti(_ s: [String: Any]) -> Set<String> { Set((s["required"] as? [String]) ?? []) }
        controlla(file.map { chiavi($0) == chiavi(PalestraVera.schemaInterno) && richiesti($0) == richiesti(PalestraVera.schemaInterno) } ?? false,
                  "Palestra: schema JSON nel pacchetto (Vera/Schemi/palestra.json), uguale a quello nel codice")
        let esempi = leggiEsempi()
        controlla((esempi?.obiezioni.count ?? 0) >= 6 && (esempi?.risposte.count ?? 0) >= 6,
                  "Palestra: esempi di prova nel pacchetto (Vera/Esempi/palestra.json), frasi anonime")
    }

    struct Esempi {
        var obiezioni: [String]
        var risposte: [(testo: String, massimo: GiudizioPalestra)]
    }

    static func leggiEsempi() -> Esempi? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Esempi/palestra.json"),
              let d = try? Data(contentsOf: url),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return nil }
        let obiezioni = (j["obiezioni"] as? [String]) ?? []
        let risposte = ((j["risposte"] as? [[String: Any]]) ?? []).compactMap { r -> (String, GiudizioPalestra)? in
            guard let t = r["testo"] as? String, let m = (r["massimo"] as? String).flatMap(GiudizioPalestra.init(rawValue:)) else { return nil }
            return (t, m)
        }
        return Esempi(obiezioni: obiezioni, risposte: risposte.map { (testo: $0.0, massimo: $0.1) })
    }

    // MARK: - La scheda della recita

    private static func schedaRecita(_ scheda: SchedaRecita, _ s: StatoShell, _ controlla: (Bool, String) -> Void) {
        let t = scheda.testo
        controlla(t.contains("Giulia Rossi") && t.contains("architetta") && t.contains("Luca") && t.contains("CIFRE DI PRISMA")
                  && t.contains("60.000") && t.contains("26%") && !scheda.scarna,
                  "Palestra: la scheda di Giulia ha chi è, timori, obiettivo e le cifre dei motori (60.000 €, imposta 26%)" + (t.contains("60.000") ? "" : "\n" + t))
        controlla(t.count <= PalestraVera.limiteScheda && !t.contains("Verificare tempi"),
                  "Palestra: la scheda resta corta (\(t.count) caratteri) e senza le note interne del consulente")
        var scarno = s.clienti[0]
        scarno.dataNascita = nil
        scarno.professione = ""
        scarno.famiglia = []
        scarno.profilo.propensione = nil
        let fonte = FonteVera(oggi: Date(), nomeUtente: "Denis", cliente: scarno, posizioni: [], appuntamenti: [], attivita: [],
                              analisi: s.analisi360(scarno.id), analisiSalvata: false, simulazioni: [])
        let povera = PalestraVera.scheda(fonte)
        controlla(povera.scarna && povera.testo.contains("Prisma sa poco") && povera.cifre.isEmpty,
                  "Palestra: profilo scarno, Vera lo sa e non inventa (nessuna cifra)")
        var inventato = ProfiloInventatoPalestra()
        inventato.eta = "45"
        inventato.lavoro = "Commerciante"
        inventato.timori = "i costi nascosti"
        let i = PalestraVera.scheda(inventato: inventato)
        controlla(i.clienteId == nil && i.chiE == "45 anni, commerciante" && i.timori == "i costi nascosti" && i.cifre.isEmpty,
                  "Palestra: il profilo inventato ha solo età, lavoro e timori")
    }

    // MARK: - Tre livelli

    private static func livelli(_ scheda: SchedaRecita, _ controlla: (Bool, String) -> Void) {
        let tutti = DifficoltaPalestra.allCases
        controlla(tutti == [.facile, .realistica, .difficile] && tutti.map(\.convinzioneIniziale) == [60, 40, 20]
                  && tutti.map(\.passoMassimo) == [35, 25, 15],
                  "Palestra: tre livelli (Facile 60, Realistica 40, Difficile 20 di convinzione iniziale)")
        let messaggi = tutti.map { PalestraVera.messaggi(scheda: scheda, difficolta: $0, turni: []).last?.testo ?? "" }
        controlla(zip(tutti, messaggi).allSatisfy { d, m in m.contains(d.regola) && m.contains("Convinzione di partenza: \(d.convinzioneIniziale)") }
                  && Set(messaggi).count == 3,
                  "Palestra: la difficoltà arriva a Qwen con la sua regola e la convinzione di partenza")
        controlla(PalestraVera.convinzione(precedente: 40, proposta: 90, difficolta: .realistica) == 65
                  && PalestraVera.convinzione(precedente: 20, proposta: 90, difficolta: .difficile) == 35
                  && PalestraVera.convinzione(precedente: 60, proposta: 90, difficolta: .facile) == 90
                  && PalestraVera.convinzione(precedente: 40, proposta: nil, difficolta: .realistica) == 40
                  && PalestraVera.convinzione(precedente: 10, proposta: 0, difficolta: .facile) == 0,
                  "Palestra: la convinzione cambia al più del passo del livello (Difficile cede piano)")
        let o = PalestraVera.opzioni(ImpostazioniVera())
        controlla(o.temperatura == 0.5 && !o.pensa && o.contesto == NucleoVera.finestra && o.formato != nil,
                  "Palestra: Qwen a temperatura 0,5, senza ragionamento, finestra di sempre, risposta vincolata allo schema")
    }

    // MARK: - Lettura del JSON

    static func primoTurno(obiezione: String = "Mi piace l'idea, ma se mi servono i soldi per la casa restano bloccati?",
                           suggerite: [String]) -> String {
        json(["giudizio": "nessuno", "motivo": "", "replica": "", "convinta": 40, "prossimaObiezione": obiezione,
              "suggerite": suggerite, "strumento": "nessuno"])
    }

    static func turno(giudizio: String, replica: String, convinta: Int, prossima: String, suggerite: [String],
                      strumento: String = "lineaVita") -> String {
        json(["giudizio": giudizio, "motivo": "Ha ascoltato il timore.", "replica": replica, "convinta": convinta,
              "prossimaObiezione": prossima, "suggerite": suggerite, "strumento": strumento])
    }

    static func json(_ o: [String: Any]) -> String {
        String(data: (try? JSONSerialization.data(withJSONObject: o)) ?? Data(), encoding: .utf8) ?? ""
    }

    static let suggeriteBuone = ["Non si preoccupi, è un ottimo prodotto.",
                                 "Guardiamo insieme la linea della vita: l'anticipo di 60.000 € resta al primo posto.",
                                 "Il piano prevede riscatti parziali, come dicono le condizioni del prodotto."]

    private static func lettura(_ scheda: SchedaRecita, _ controlla: (Bool, String) -> Void) {
        let ammesse = PalestraVera.cifreAmmesse(scheda: scheda, turni: [])
        if case .valida(let r) = PalestraVera.leggi("```json\n" + primoTurno(suggerite: suggeriteBuone) + "\n```", ammesse: ammesse, primo: true, ultimo: false) {
            controlla(r.prossimaObiezione?.contains("bloccati") == true && r.suggerite.count == 3 && r.replica.isEmpty && r.convinta == 40,
                      "Palestra: risposta valida letta (obiezione, tre suggerite con le cifre della scheda)")
        } else {
            controlla(false, "Palestra: risposta valida letta")
        }
        controlla(PalestraVera.leggi("Certo! Ecco la mia obiezione: ho paura.", ammesse: ammesse, primo: true, ultimo: false)
                    == .scartata("La risposta di Vera non era un JSON leggibile.")
                  && { if case .scartata = PalestraVera.leggi("{\"replica\": \"ok\", ", ammesse: ammesse, primo: false, ultimo: false) { return true }; return false }(),
                  "Palestra: un JSON non valido si scarta")
        let inventata = turno(giudizio: "buona", replica: "Ma la banca mi dà il 4,5% senza rischi.", convinta: 45,
                              prossima: "E i costi?", suggerite: suggeriteBuone)
        controlla(PalestraVera.leggi(inventata, ammesse: ammesse, primo: false, ultimo: false) == .scartata("Vera ha scritto una cifra che non viene da Prisma."),
                  "Palestra: una replica con una cifra che non viene dai motori si rifiuta")
        let obiezioneInventata = primoTurno(obiezione: "Ho letto che rende l'8% l'anno, è vero?", suggerite: suggeriteBuone)
        controlla({ if case .scartata = PalestraVera.leggi(obiezioneInventata, ammesse: ammesse, primo: true, ultimo: false) { return true }; return false }(),
                  "Palestra: anche un'obiezione con una cifra inventata si rifiuta" + " [\(CommentoVera.cifre(ammesse).sorted().joined(separator: " "))]")
        let conSuggeritaFinta = primoTurno(suggerite: ["Con noi rende il 6% garantito.", suggeriteBuone[1], suggeriteBuone[2]])
        if case .valida(let r) = PalestraVera.leggi(conSuggeritaFinta, ammesse: ammesse, primo: true, ultimo: false) {
            controlla(r.suggerite == [suggeriteBuone[1], suggeriteBuone[2]],
                      "Palestra: una suggerita con una cifra inventata si toglie, le altre restano")
        } else {
            controlla(false, "Palestra: suggerita con una cifra inventata")
        }
        // La cifra detta dal consulente può tornare nella replica
        let detta = [TurnoPalestra(id: 0, obiezione: "E se mi servono 15.000 € nel 2028?", suggerite: [], risposta: "Ritirando 15.000 € nel 2028 la casa arriva lo stesso.")]
        let replica = turno(giudizio: "ottima", replica: "Se anche con 15.000 € in meno ci arrivo, mi tranquillizza.", convinta: 55,
                            prossima: "E i costi?", suggerite: [])
        controlla({ if case .valida = PalestraVera.leggi(replica, ammesse: PalestraVera.cifreAmmesse(scheda: scheda, turni: detta), primo: false, ultimo: false) { return true }; return false }(),
                  "Palestra: le cifre dette dal consulente possono tornare nella replica")
        let ultima = turno(giudizio: "buona", replica: "Va bene, ne parlo con Luca.", convinta: 60, prossima: "Ancora una?", suggerite: suggeriteBuone)
        if case .valida(let r) = PalestraVera.leggi(ultima, ammesse: ammesse, primo: false, ultimo: true) {
            controlla(r.prossimaObiezione == nil && r.suggerite.isEmpty, "Palestra: dopo l'ultima obiezione niente obiezione nuova né suggerite")
        } else {
            controlla(false, "Palestra: ultima risposta")
        }
        controlla(PalestraVera.campoParziale(#"{"giudizio":"buona","motivo":"","replica":"Ah, quindi non è tutto bl"#, chiave: "replica") == "Ah, quindi non è tutto bl"
                  && PalestraVera.campoParziale(#"{"giudizio":"buona""#, chiave: "replica") == nil,
                  "Palestra: la replica si vede mentre Qwen la scrive")
    }

    // MARK: - Giudizio e punteggio

    private static func giudizio(_ scheda: SchedaRecita, _ controlla: (Bool, String) -> Void) {
        let ammesse = PalestraVera.cifreAmmesse(scheda: scheda, turni: [])
        if let e = leggiEsempi() {
            let sbagliati = e.risposte.filter { PalestraVera.giudizioRegole($0.testo, scheda: scheda, ammesse: ammesse).massimo != $0.massimo }
            controlla(sbagliati.isEmpty, "Palestra: regole del giudizio sugli esempi (\(sbagliati.map(\.testo).joined(separator: " | ")))")
        }
        let pressione = PalestraVera.giudizioRegole("La proposta vale solo fino a venerdì.", scheda: scheda, ammesse: ammesse)
        controlla(PalestraVera.giudizioFinale(regole: pressione.massimo, qwen: .ottima) == .debole
                  && PalestraVera.giudizioFinale(regole: .ottima, qwen: .buona) == .buona
                  && PalestraVera.giudizioFinale(regole: .ottima, qwen: nil) == .buona
                  && PalestraVera.giudizioFinale(regole: .ottima, qwen: .ottima) == .ottima,
                  "Palestra: una risposta di pressione è sempre «debole» qualunque cosa dica Qwen; vale il giudizio più prudente")
        let inventata = PalestraVera.giudizioRegole("Con il 9% l'anno l'anticipo per la casa arriva prima.", scheda: scheda, ammesse: ammesse)
        controlla(inventata.massimo == .buona, "Palestra: una cifra del consulente che Prisma non ha calcolato vale al più «buona»")
        controlla(PalestraVera.punteggio([.ottima, .buona, .debole]) == 56 && PalestraVera.punteggio([.ottima, .ottima, .ottima]) == 100
                  && PalestraVera.punteggio([]) == 0 && PalestraVera.punteggio([.ottima, .ottima, .ottima, .ottima], obiezioni: 3) == 100,
                  "Palestra: punteggio 3/2/0 su 3 per obiezione, sempre fra 0 e 100")
        controlla(PalestraVera.fraseFinale(convinta: 70, scheda: scheda, ultimaReplica: "Ne parlo con Luca, ma mi convince.")
                    == "Giulia ha detto: «Ne parlo con Luca, ma mi convince»."
                  && PalestraVera.fraseFinale(convinta: 30, scheda: scheda, ultimaReplica: "Mah.") == "Con Giulia resta qualche dubbio.",
                  "Palestra: la frase finale la decide la convinzione del cliente")
        controlla(PalestraVera.strumentiDaUsare([]) == [.lineaVita, .lanciaAnno, .film]
                  && PalestraVera.strumentiDaUsare([.film, .film, .provaFuoco]) == [.film, .provaFuoco],
                  "Palestra: «Cosa potevi usare» dagli strumenti indicati (altrimenti i tre del template)")
    }

    // MARK: - Qwen finto

    static func sessioneFinta() -> URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.protocolClasses = [ServerFintoScenari.self]
        return URLSession(configuration: c)
    }

    private static func modelloFinto(_ scheda: SchedaRecita, _ controlla: (Bool, String) -> Void) {
        let vera = ImpostazioniVera()
        let motore = MotoreLocale(vera, disponibilita: .pronto, sessione: sessioneFinta())
        ServerFintoScenari.prepara(["Certo, ecco: niente JSON", primoTurno(suggerite: suggeriteBuone)])
        let r = aspetta { try? await PalestraVera.turno(motore: motore, vera: vera, scheda: scheda, difficolta: .difficile, turni: []) }
        let ricevuto = ServerFintoScenari.ultimo
        let utente = ((ricevuto["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        let temperatura = ((ricevuto["options"] as? [String: Any])?["temperature"] as? Double) ?? -1
        controlla(r?.prossimaObiezione?.contains("bloccati") == true && r?.suggerite.count == 3,
                  "Palestra, Qwen finto: un JSON non valido si scarta e il turno si richiede una volta")
        controlla(ricevuto["format"] != nil && temperatura == 0.5 && utente.contains("SCHEDA DEL CLIENTE CHE RECITI") && utente.contains("Difficile")
                  && utente.contains("ATTENZIONE: la risposta di prima è stata scartata"),
                  "Palestra, Qwen finto: la richiesta porta scheda, difficoltà, schema e il perché dello scarto")
        let finta = turno(giudizio: "ottima", replica: "Mi hanno detto che rende il 12%.", convinta: 70, prossima: "E i costi?", suggerite: [])
        ServerFintoScenari.prepara([finta, finta])
        let turni = [TurnoPalestra(id: 0, obiezione: "Restano bloccati?", suggerite: [], risposta: "Guardiamo la linea della vita.")]
        let errore = aspetta { () -> String? in
            do {
                _ = try await PalestraVera.turno(motore: motore, vera: vera, scheda: scheda, difficolta: .realistica, turni: turni)
                return nil
            } catch {
                return (error as? ErroreVera)?.messaggio
            }
        }
        controlla(errore?.contains("cifra che non viene da Prisma") == true,
                  "Palestra, Qwen finto: due risposte con cifre inventate, il turno non passa e Vera lo dice")
    }

    #if os(macOS)
    /// Un allenamento intero con il Qwen finto: tre obiezioni, una risposta di pressione «debole» anche se Qwen dice
    /// «ottima», la fine con il punteggio.
    private static func allenamento(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "giulia"
        s.disponibilitaLocale = .pronto
        let p = s.palestra
        p.sessione = sessioneFinta()
        p.difficolta = .realistica
        ServerFintoScenari.prepara([primoTurno(suggerite: suggeriteBuone)])
        p.inizia(s)
        attendi { p.fase == .tuoTurno }
        controlla(p.turni.count == 1 && p.turni[0].suggerite.count == 3 && p.convinta == 40,
                  "Palestra, allenamento: la prima obiezione con tre risposte suggerite (convinzione 40 in Realistica)")
        ServerFintoScenari.prepara([turno(giudizio: "ottima", replica: "Vederlo così mi aiuta: la casa resta al primo posto.", convinta: 90,
                                          prossima: "La banca mi propone un conto senza rischi. Perché dovrei fare altro?", suggerite: suggeriteBuone)])
        p.rispondi(suggeriteBuone[1], stato: s)
        attendi { p.fase == .tuoTurno && p.turni.count == 2 }
        controlla(p.turni[0].giudizio == .ottima && p.turni[0].replica?.contains("casa") == true && p.convinta == 65 && p.turni.count == 2,
                  "Palestra, allenamento: giudizio «Ottima», replica e obiezione dopo; la convinzione sale al più di 25")
        ServerFintoScenari.prepara([turno(giudizio: "ottima", replica: "Così mi mette fretta, però…", convinta: 50,
                                          prossima: "Ci devo pensare. Ne parlo con Luca stasera.", suggerite: suggeriteBuone)])
        p.rispondi("La proposta vale solo fino a venerdì.", stato: s)
        attendi { p.fase == .tuoTurno && p.turni.count == 3 }
        controlla(p.turni[1].giudizio == .debole && (p.turni[1].motivo ?? "").contains("fretta"),
                  "Palestra, allenamento: la risposta di pressione è «debole» anche se Qwen la giudica ottima")
        ServerFintoScenari.prepara([turno(giudizio: "buona", replica: "Va bene, ne parlo con Luca stasera.", convinta: 55,
                                          prossima: "", suggerite: [], strumento: "film")])
        p.campo = "Fissiamo già il prossimo incontro con tutti e due, così vi preparo il film del piano?"
        p.rispondi(p.campo, stato: s)
        attendi { p.fase == .fine }
        controlla(p.fase == .fine && p.punteggio == PalestraVera.punteggio([.ottima, .debole, .buona]) && p.campo.isEmpty
                  && PalestraVera.strumentiDaUsare(p.strumenti).contains(.film),
                  "Palestra, allenamento: dopo tre obiezioni la fine con il punteggio (\(p.punteggio ?? -1)%) e gli strumenti indicati")
        controlla(s.dati.impostazioni.palestra.allenamenti.isEmpty,
                  "Palestra: nelle prove (e in sola lettura) l'esito non si registra")
        p.azzera()
        controlla(p.turni.isEmpty && p.fase == .attesa, "Palestra: «Rifai» riparte da capo, conversazione vuota")
    }

    /// Qwen spento: la palestra lo dice e non parte (nessuna obiezione finta).
    private static func nonPronta(_ controlla: (Bool, String) -> Void) {
        let s = StatoShell(persistente: false)
        s.clienteAttivoId = "marco"
        s.disponibilitaLocale = .nonDisponibile("Ollama non risponde sul Mac.")
        s.dati.impostazioni.vera.indirizzoLocale = "http://127.0.0.1:9"
        let p = s.palestra
        p.inizia(s)
        attendi(8) { if case .nonPronta = p.fase { return true }; return false }
        if case .nonPronta(let m) = p.fase {
            controlla(p.turni.isEmpty && !m.isEmpty, "Palestra: se Qwen non è pronto la palestra lo dice e non parte («\(m.prefix(50))…»)")
        } else {
            controlla(false, "Palestra: Qwen non pronto (fase \(p.fase))")
        }
    }

    private static func attendi(_ secondi: TimeInterval = 10, finche condizione: () -> Bool) {
        let fine = Date().addingTimeInterval(secondi)
        while !condizione() && Date() < fine { RunLoop.main.run(until: Date().addingTimeInterval(0.02)) }
    }
    #endif

    // MARK: - Registro e Studio

    private static func registro(_ controlla: (Bool, String) -> Void) {
        var r = ImpostazioniPalestra()
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        for i in 0..<55 {
            r.registra(EsitoPalestra(data: t.addingTimeInterval(Double(i) * 86_400), clienteId: "giulia", difficolta: .facile, punteggio: i * 3))
        }
        controlla(r.allenamenti.count == PalestraVera.massimoEsiti && r.allenamenti.first?.punteggio == 15
                  && r.allenamenti.allSatisfy { (0...100).contains($0.punteggio) },
                  "Palestra: il registro tiene gli ultimi 50 allenamenti, i più vecchi si tolgono")
    }

    private static func studio(_ controlla: (Bool, String) -> Void) {
        controlla(SchedaStudio.allCases.contains(.palestra) && SchedaStudio.palestra.titolo == "Palestra" && SchedaStudio.palestra.prossima == nil
                  && SchedaStudio.ocf.titolo == "OCF" && SchedaStudio.fatture.titolo == "Parcelle",
                  "Palestra: nuova scheda di Studio (Cruscotto · Parcelle · Track record · OCF · Palestra)")
        let s = StatoShell(persistente: false)
        s.apriVoceNovita(NovitaLuce.palestra)
        controlla(NovitaLuce.palestra.disponibile && s.appAttiva == .studio && s.schedaStudio == .palestra,
                  "Novità: «La palestra della trattativa» apre Studio › Palestra")
    }

    /// Aspetta un lavoro asincrono dal thread delle prove.
    private static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaPalestra<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }
}

private final class ScatolaPalestra<T>: @unchecked Sendable {
    var valore: T?
}
