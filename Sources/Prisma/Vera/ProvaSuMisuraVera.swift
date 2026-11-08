import Foundation

/// Prova di «Vera su misura» (Vera/BRIEF.md, fase 5, funzione 22) dentro `Prisma --prova-vera`: anonimizzazione e
/// residui sui clienti di prova, raccolta e divisione degli esempi, pacchetto di addestramento (nessun dato dei clienti
/// in nessun byte, nessun esempio d'esame), risorse dell'addestramento, importazione in Ollama ed esame con un server
/// finto dentro il processo (niente rete, niente modello), sostituzione e ritorno alla versione di prima, frasi in chat.
enum ProvaSuMisuraVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let dati = StatoShell(persistente: false).dati.istantanea
        anonimizzazione(dati, controlla)
        raccolta(controlla)
        pacchetto(dati, controlla)
        risorse(controlla)
        importazione(controlla)
        esame(controlla)
        curva(controlla)
    }

    /// Aspetta un lavoro asincrono dal thread delle prove (solo per lavori che non toccano il thread principale).
    static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaSuMisura<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }

    /// Una sessione che parla solo con il server finto.
    static func sessioneFinta() -> URLSession {
        let c = URLSessionConfiguration.ephemeral
        c.protocolClasses = [ServerFintoSuMisura.self]
        return URLSession(configuration: c)
    }

    /// Domenica 8 novembre 2026, 10:00: sempre lo stesso giorno.
    static let oggi: Date = {
        var c = DateComponents()
        c.year = 2026
        c.month = 11
        c.day = 8
        c.hour = 10
        return Calendar(identifier: .gregorian).date(from: c) ?? Date(timeIntervalSince1970: 1_794_128_400)
    }()

    // MARK: - 1. Anonimizzazione

    private static func anonimizzazione(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        let id = IdentificativiClienti(clienti: dati.clienti, consulente: dati.impostazioni.nomeUtente)
        let frase = AnonimizzatoreVera.anonimizza("Giulia Rossi, 37 anni, via Manzoni 12, Monza, versa 550 € al mese", identificativi: id)
        controlla(frase.testo == "[Cliente], 37 anni, [Indirizzo], versa 550 € al mese",
                  "Su misura: nome e indirizzo diventano segnaposto, l'importo resta (\(frase.testo))")
        controlla(frase.sostituzioni.contains(Sostituzione(originale: "Giulia Rossi", segnaposto: AnonimizzatoreVera.cliente)),
                  "Su misura: la sostituzione è registrata per l'anteprima")
        let soloNome = AnonimizzatoreVera.anonimizza("Ciao giulia, come va con la casa?", identificativi: id).testo
        controlla(soloNome == "Ciao [Cliente], come va con la casa?", "Su misura: il nome da solo, anche minuscolo, diventa [Cliente]")
        if let marco = dati.clienti.first(where: { $0.id == "marco" }), let f = marco.famiglia.first {
            let primo = f.nome.split(separator: " ").first.map(String.init) ?? f.nome
            let t = AnonimizzatoreVera.anonimizza("Ne parlo con \(primo) domani.", identificativi: id).testo
            controlla(t == "Ne parlo con [Familiare] domani.", "Su misura: il nome di un familiare diventa [Familiare] (\(t))")
        } else {
            controlla(false, "Su misura: Marco ha un familiare nei dati di prova")
        }
        let documenti = AnonimizzatoreVera.anonimizza("CF RSSGLI87L42A944X, conto IT60 X054 2811 1010 0000 0123 456, mail anna.verdi@example.org, cellulare +39 333 1234567, polizza 1234567890",
                                                      identificativi: id).testo
        let attesi = [AnonimizzatoreVera.codiceFiscale, AnonimizzatoreVera.iban, AnonimizzatoreVera.email, AnonimizzatoreVera.telefono, AnonimizzatoreVera.numero]
        controlla(attesi.allSatisfy { documenti.contains($0) } && documenti.filter(\.isNumber).isEmpty,
                  "Su misura: codice fiscale, IBAN, email, telefono e numero di polizza diventano segnaposto (\(documenti))")
        let consulente = AnonimizzatoreVera.anonimizza("A presto, \(dati.impostazioni.nomeUtente)", identificativi: id).testo
        controlla(consulente == "A presto, \(AnonimizzatoreVera.consulente)", "Su misura: anche il nome del consulente non esce")
        let data = AnonimizzatoreVera.anonimizza("Ci vediamo il 2026-11-12 alle 15.", identificativi: id).testo
        controlla(data == "Ci vediamo il 2026-11-12 alle 15.", "Su misura: una data non diventa un numero di documento")

        // Nessun residuo per i 5 clienti del template e i clienti fittizi
        let tutti = ClientiFittizi.completi()
        let idTutti = IdentificativiClienti(clienti: tutti.clienti, consulente: tutti.impostazioni.nomeUtente)
        var sporchi: [String] = []
        for c in tutti.clienti {
            var testo = "\(c.nome) (\(c.email), \(c.telefono)) abita in \(c.indirizzo)."
            if let f = c.famiglia.first { testo += " Con lei c'è \(f.nome)." }
            if let a = c.elencoAziende.first { testo += " Lavora in \(a.ragioneSociale)." }
            let anonimo = AnonimizzatoreVera.anonimizza(testo, identificativi: idTutti).testo
            let r = AnonimizzatoreVera.residui(anonimo, identificativi: idTutti)
            if !r.isEmpty { sporchi.append("\(c.nome): \(r.joined(separator: ", "))") }
        }
        controlla(sporchi.isEmpty && tutti.clienti.count >= 35,
                  "Su misura: nessun residuo per i \(tutti.clienti.count) clienti di prova" + (sporchi.isEmpty ? "" : " (\(sporchi.prefix(3).joined(separator: " | ")))"))
        controlla(!AnonimizzatoreVera.residui("Ne ho parlato con Giulia Rossi", identificativi: id).isEmpty,
                  "Su misura: un nome rimasto è un residuo")
        let guardare = AnonimizzatoreVera.anonimizza(EsempioVera(domanda: "Ho visto Carla Neri ieri", risposta: "Bene."), identificativi: id)
        controlla(guardare.daGuardare == ["Carla Neri"], "Su misura: un nome che l'archivio non conosce è «da guardare» (\(guardare.daGuardare))")
        controlla(guardare.modalita == .lavoro, "Su misura: un esempio di prima, senza modalità, vale come lavoro")
    }

    // MARK: - 2. Raccolta e divisione

    /// Tanti esempi finti, diversi tra loro (dati di prova).
    static func molti(_ n: Int, modalita: ModalitaVera = .conversazione) -> [EsempioVera] {
        (0..<n).map { EsempioVera(domanda: "Domanda di prova numero \($0 + 1) sulla previdenza", risposta: "Risposta approvata \($0 + 1), scritta bene.",
                                  data: oggi, modalita: modalita) }
    }

    private static func raccolta(_ controlla: (Bool, String) -> Void) {
        var esempi = SuMisuraDiProva.esempi(oggi: oggi)
        esempi.append(esempi[0])                                   // un doppione
        var escluso = esempi[1]; escluso.escluso = true
        esempi[1] = escluso
        esempi.append(EsempioVera(domanda: "Il codice è RSSGLI87L42A944X", risposta: "Va bene."))
        esempi.append(EsempioVera(domanda: "Quanto ha Giulia?", risposta: "Ha 20.800 € nel fondo.", modalita: .lavoro))
        let candidati = SuMisuraVera.candidati(esempi)
        controlla(candidati.count == 12 && !candidati.contains { $0.escluso } && Set(candidati.map(\.id)).count == candidati.count,
                  "Su misura: entrano solo esempi non esclusi e non vietati, senza doppioni (\(candidati.count))")
        let raccolti = SuMisuraVera.raccogli(esempi)
        controlla(!raccolti.contains { $0.risposta.contains("20.800") } && raccolti.count == 11,
                  "Su misura: una risposta di lavoro con cifre che non sono nella domanda non entra nell'addestramento")
        controlla(SuMisuraVera.addestrabile(EsempioVera(domanda: "Spiegami l'inflazione", risposta: "Al 2% ogni anno i prezzi salgono.", modalita: .conversazione)),
                  "Su misura: in conversazione le cifre generali sono ammesse")
        controlla(SuMisuraVera.quanteDomande(60) == 12 && SuMisuraVera.quanteDomande(200) == 40 && SuMisuraVera.quanteDomande(600) == 80
                  && SuMisuraVera.quanteDomande(10) == 5,
                  "Su misura: l'esame tiene il 20% (tra 12 e 80, mai più di metà)")

        let cento = molti(100)
        let d1 = SuMisuraVera.dividi(cento, esameGia: [])
        let d2 = SuMisuraVera.dividi(cento.shuffled(), esameGia: [])
        let a1 = Set(d1.addestramento.map(\.id)), e1 = Set(d1.esame.map(\.id))
        controlla(d1.esame.count == 20 && a1.isDisjoint(with: e1) && a1.count + e1.count == 100,
                  "Su misura: esame del 20%, insiemi disgiunti (\(d1.esame.count) / \(d1.addestramento.count))")
        controlla(d1.esame.map(\.id) == d2.esame.map(\.id), "Su misura: la divisione non dipende dall'ordine")
        let gia = Array(cento.suffix(5).map(\.id))
        let d3 = SuMisuraVera.dividi(cento, esameGia: gia)
        controlla(Set(gia).isSubset(of: Set(d3.esame.map(\.id))), "Su misura: le domande d'esame già scelte restano")
        // Un esempio già esportato non entra mai nell'esame, anche quando le domande scelte sono sparite
        let usati = Array(cento.prefix(90).map(\.id))
        let d4 = SuMisuraVera.dividi(cento, esameGia: ["esempio-sparito"], usati: usati)
        controlla(Set(d4.esame.map(\.id)).isDisjoint(with: Set(usati)) && !d4.esame.isEmpty,
                  "Su misura: gli esempi già usati in un pacchetto non finiscono nell'esame")
        controlla(SuMisuraVera.raccogli(molti(12)).count < SuMisuraVera.minimoEsempi,
                  "Su misura: sotto il minimo (\(SuMisuraVera.minimoEsempi)) il pacchetto non si prepara")
    }

    // MARK: - 3. Pacchetto

    private static func pacchetto(_ dati: DatiPrisma, _ controlla: (Bool, String) -> Void) {
        let fm = FileManager.default
        let cartella = fm.temporaryDirectory.appendingPathComponent("Prisma-prova-su-misura-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: cartella) }
        let id = IdentificativiClienti(clienti: dati.clienti, consulente: dati.impostazioni.nomeUtente)
        let tutti = SuMisuraDiProva.esempi(oggi: oggi) + molti(70)
        let divisione = SuMisuraVera.dividi(tutti, esameGia: [])
        let anonimi = divisione.addestramento.map { AnonimizzatoreVera.anonimizza($0, identificativi: id) }
        let lezioni = ["Dai sempre del Lei a Giulia Rossi"].map { AnonimizzatoreVera.anonimizza($0, identificativi: id).testo }
        guard let m = try? PacchettoSuMisura.scrivi(anonimi, lezioni: lezioni, in: cartella.appendingPathComponent("pacchetto"),
                                                    oggi: oggi, modelloDiPartenza: MotoreLocale.modelloPredefinito) else {
            controlla(false, "Su misura: il pacchetto si scrive")
            return
        }
        let dir = cartella.appendingPathComponent("pacchetto")
        let jsonl = (try? String(contentsOf: dir.appendingPathComponent(SuMisuraVera.nomeFileAddestramento), encoding: .utf8)) ?? ""
        let righe = jsonl.split(separator: "\n").map(String.init)
        let valide = righe.compactMap { r -> [[String: String]]? in
            guard let d = r.data(using: .utf8), let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return nil }
            return j["messages"] as? [[String: String]]
        }
        controlla(righe.count == anonimi.filter(\.pulito).count && valide.count == righe.count && m.esempi == righe.count,
                  "Su misura: una riga JSON valida per esempio (\(righe.count))")
        controlla(valide.allSatisfy { $0.map { $0["role"] ?? "" } == ["system", "user", "assistant"] }
                  && valide.allSatisfy { ($0.first?["content"] ?? "").contains("[Cliente]") },
                  "Su misura: ruoli system/user/assistant, le lezioni (anonime) nelle istruzioni")
        let byte = (try? Data(contentsOf: dir.appendingPathComponent(SuMisuraVera.nomeFileAddestramento))) ?? Data()
        controlla(m.impronta == PacchettoSuMisura.impronta(byte) && m.nomeModello == "vera-su-misura:2026-11-08" && m.lezioni == 1,
                  "Su misura: il manifesto ha conteggi, nome e impronta giusti")
        let esame = Set(divisione.esame.map { AnonimizzatoreVera.anonimizza($0, identificativi: id).domanda })
        controlla(!valide.contains { esame.contains($0.count > 1 ? ($0[1]["content"] ?? "") : "") },
                  "Su misura: nessuna domanda dell'esame nel pacchetto")
        // Nessun dato dei clienti di prova: nelle domande e nelle risposte nemmeno una parola dei nomi, in nessun file
        // nemmeno un nome intero, un'email o un codice fiscale
        let contenuti = valide.flatMap { $0.dropFirst().map { $0["content"] ?? "" } }.joined(separator: "\n")
        var residui = AnonimizzatoreVera.residui(contenuti, identificativi: id)
        var tuttoIlTesto = ""
        for nome in (try? fm.contentsOfDirectory(atPath: dir.path)) ?? [] {
            if let t = try? String(contentsOf: dir.appendingPathComponent(nome), encoding: .utf8) { tuttoIlTesto += t + "\n" }
        }
        let minuscolo = tuttoIlTesto.lowercased()
        for c in dati.clienti {
            for x in [c.nome, c.email, c.codiceFiscale] + c.famiglia.map(\.nome) where x.count >= 3 && minuscolo.contains(x.lowercased()) {
                residui.append(x)
            }
        }
        controlla(residui.isEmpty && !contenuti.isEmpty,
                  "Su misura: nessun dato dei clienti di prova nel pacchetto" + (residui.isEmpty ? "" : " (\(residui.prefix(3).joined(separator: ", ")))"))
        let zip = cartella.appendingPathComponent("pacchetto.zip")
        let estratto = cartella.appendingPathComponent("riaperto")
        let riaperto = (try? PacchettoSuMisura.zippa(dir, a: zip)) != nil && (try? LettoreZip.estrai(zip, in: estratto)) != nil
        let manifesto = fm.enumerator(atPath: estratto.path)?.allObjects.compactMap { $0 as? String }.contains { $0.hasSuffix(SuMisuraVera.nomeFileManifesto) } ?? false
        controlla(riaperto && manifesto, "Su misura: lo zip del pacchetto si riapre")
    }

    // MARK: - 4. Risorse dell'addestramento

    private static func risorse(_ controlla: (Bool, String) -> Void) {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Addestramento/\(SuMisuraVera.nomeNotebook)"),
              let d = try? Data(contentsOf: url) else {
            #if os(iOS)
            controlla(true, "Su misura: notebook OK (non nel pacchetto iOS)")
            #else
            controlla(false, "Su misura: il notebook è nel pacchetto (Vera/Addestramento/\(SuMisuraVera.nomeNotebook))")
            #endif
            return
        }
        let json = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any]
        let testo = String(data: d, encoding: .utf8) ?? ""
        let nomi = [SuMisuraVera.nomeFileAddestramento, SuMisuraVera.nomeFileManifesto, SuMisuraVera.nomeFileRapporto, SuMisuraVera.quantizzazione]
        controlla(json?["cells"] != nil && nomi.allSatisfy { testo.contains($0) },
                  "Su misura: il notebook è JSON valido e usa gli stessi nomi di Prisma (\(nomi.joined(separator: ", ")))")
        let script = Bundle.main.resourceURL?.appendingPathComponent("Vera/Addestramento/\(SuMisuraVera.nomeScript)")
        controlla(script.map { FileManager.default.fileExists(atPath: $0.path) } ?? false, "Su misura: lo script di addestramento è nel pacchetto")
    }

    // MARK: - 5. Importazione in Ollama

    private static func importazione(_ controlla: (Bool, String) -> Void) {
        let fm = FileManager.default
        let cartella = fm.temporaryDirectory.appendingPathComponent("Prisma-prova-importa-\(UUID().uuidString)")
        try? fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: cartella) }
        let noto = cartella.appendingPathComponent("abc.txt")
        try? Data("abc".utf8).write(to: noto)
        controlla((try? ImportaSuMisura.impronta(noto)) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
                  "Su misura: l'impronta SHA256 del file, a pezzi")
        let p = ImportaSuMisura.parametri(daShow: "stop \"<|im_end|>\"\nstop \"<|endoftext|>\"\ntemperature 0.6\nnum_ctx 8192")
        controlla((p["stop"] as? [Any])?.count == 2 && (p["temperature"] as? Double) == 0.6 && (p["num_ctx"] as? Int) == 8192,
                  "Su misura: i parametri di /api/show diventano un oggetto (stop in un array, numeri come numeri)")

        let gguf = cartella.appendingPathComponent("vera.gguf")
        try? (Data("GGUF".utf8) + Data(repeating: 7, count: 2_048)).write(to: gguf)
        let finto = cartella.appendingPathComponent("finto.gguf")
        try? Data(repeating: 1, count: 64).write(to: finto)
        let impronta = (try? ImportaSuMisura.impronta(gguf)) ?? ""
        let sessione = sessioneFinta()
        let ollama = FornitoreOllama(indirizzo: FornitoreOllama.indirizzoPredefinito, modello: MotoreLocale.modelloPredefinito, sessione: sessione)
        let nome = SuMisuraVera.nomeModello(oggi)

        ServerFintoSuMisura.prepara(installati: [MotoreLocale.modelloPredefinito])
        let rifiutato = aspetta { () async -> ErroreImporta? in
            do { try await ImportaSuMisura.importa(gguf: finto, nome: nome, partenza: MotoreLocale.modelloPredefinito, fornitore: ollama); return nil }
            catch { return error as? ErroreImporta }
        }
        controlla(rifiutato == .nonGGUF && ServerFintoSuMisura.registro.isEmpty, "Su misura: un file che non è GGUF è rifiutato senza richieste")
        let lontano = FornitoreOllama(indirizzo: "http://10.0.0.5:11434", modello: MotoreLocale.modelloPredefinito, sessione: sessione)
        let fuori = aspetta { () async -> ErroreImporta? in
            do { try await ImportaSuMisura.importa(gguf: gguf, nome: nome, partenza: MotoreLocale.modelloPredefinito, fornitore: lontano); return nil }
            catch { return error as? ErroreImporta }
        }
        controlla(fuori == .nonLocale && ServerFintoSuMisura.registro.isEmpty, "Su misura: un indirizzo che non è sul Mac è rifiutato")

        let errore = aspetta { () async -> String? in
            do { try await ImportaSuMisura.importa(gguf: gguf, nome: nome, partenza: MotoreLocale.modelloPredefinito, fornitore: ollama); return nil }
            catch { return error.localizedDescription }
        }
        let percorsi = ServerFintoSuMisura.registro.map { "\($0.metodo) \($0.percorso)" }
        let blob = "/api/blobs/sha256:" + impronta
        controlla(errore == nil && percorsi == ["HEAD " + blob, "POST " + blob, "POST /api/show", "POST /api/create"],
                  "Su misura: blob (prima HEAD, poi la copia), show del modello di partenza, create (\(percorsi.joined(separator: ", "))\(errore.map { " · " + $0 } ?? ""))")
        let crea = ServerFintoSuMisura.corpo("/api/create")
        controlla((crea["files"] as? [String: String])?[ImportaSuMisura.nomeFile] == "sha256:" + impronta && (crea["model"] as? String) == nome
                  && (crea["template"] as? String) == ServerFintoSuMisura.template && ((crea["parameters"] as? [String: Any])?["stop"] as? [Any])?.count == 2,
                  "Su misura: create con il file per impronta, il template e i parametri del modello di partenza")
        ServerFintoSuMisura.prepara(installati: [])
        let eliminato = aspetta { await ImportaSuMisura.elimina(nome, fornitore: ollama) }
        controlla(eliminato && ServerFintoSuMisura.registro.map { "\($0.metodo) \($0.percorso)" } == ["DELETE /api/delete"]
                  && (ServerFintoSuMisura.corpo("/api/delete")["model"] as? String) == nome,
                  "Su misura: «Elimina il modello» manda DELETE /api/delete")
        // Lo zip dell'addestramento: il .gguf e rapporto.json si trovano anche dentro una cartella
        let zipDir = cartella.appendingPathComponent("scaricato")
        try? fm.createDirectory(at: zipDir.appendingPathComponent("vera-su-misura"), withIntermediateDirectories: true)
        try? fm.copyItem(at: gguf, to: zipDir.appendingPathComponent("vera-su-misura/vera-su-misura-Q4_K_M.gguf"))
        try? Data(#"{"passi":[{"passo":1,"errore":2.0}]}"#.utf8).write(to: zipDir.appendingPathComponent(SuMisuraVera.nomeFileRapporto))
        let zip = cartella.appendingPathComponent("vera-su-misura.zip")
        try? ScrittoreZip.crea(da: zipDir, a: zip)
        let trovato = try? ImportaSuMisura.trova(in: zip)
        controlla(trovato.map { ImportaSuMisura.eGGUF($0.gguf) && $0.rapporto != nil } ?? false, "Su misura: nello zip si trovano il modello e rapporto.json")
        if let t = trovato, t.gguf.path.hasPrefix(fm.temporaryDirectory.path) { try? fm.removeItem(at: t.gguf.deletingLastPathComponent().deletingLastPathComponent()) }
    }

    // MARK: - 6. Esame

    private static func esame(_ controlla: (Bool, String) -> Void) {
        let domande = EsameSuMisura.domandeDiProva()
        controlla(domande.count == 12, "Su misura: l'esame di prova è nel pacchetto (Vera/Esempi/esame-di-prova.json, \(domande.count) domande)")
        guard let prima = domande.first else { return }
        // Prima il codice: il punteggio di una risposta
        controlla(EsameSuMisura.punteggio(risposta: prima.attesa, domanda: prima).passata, "Esame: la risposta approvata passa")
        let inventata = EsameSuMisura.punteggio(risposta: prima.attesa + " In tutto fanno 12.400 €.", domanda: prima)
        controlla(!inventata.passata && inventata.cifreInventate == ["12.400 €"], "Esame: una cifra inventata vale 0")
        let rischio = EsameSuMisura.punteggio(risposta: prima.attesa + " È un rendimento garantito.", domanda: prima)
        controlla(!rischio.passata && !rischio.paroleARischio.isEmpty, "Esame: «rendimento garantito» vale 0")
        let lontana = EsameSuMisura.punteggio(risposta: "Oggi piove e il treno è in ritardo.", domanda: prima)
        controlla(!lontana.passata && lontana.somiglianza < EsameSuMisura.sogliaSomiglianza, "Esame: una risposta che non c'entra non passa")
        controlla(EsameSuMisura.superato(attuale: (71, 2), nuovo: (84, 0)) && !EsameSuMisura.superato(attuale: (80, 0), nuovo: (76, 0))
                  && !EsameSuMisura.superato(attuale: (60, 0), nuovo: (69, 0)) && !EsameSuMisura.superato(attuale: (71, 0), nuovo: (84, 1))
                  && !EsameSuMisura.superato(attuale: (71, 0), nuovo: (72, 0)),
                  "Esame: superato con almeno 70%, almeno 2 punti in più e non più cifre inventate")

        // L'esame vero, con il server finto: la Vera di oggi risponde male, quella su misura come le risposte approvate
        let attuale = MotoreLocale.modelloPredefinito, nuovo = SuMisuraVera.nomeModello(oggi)
        let sessione = sessioneFinta()
        ServerFintoSuMisura.prepara(installati: [attuale, nuovo],
                                    risposte: [attuale: domande.map { _ in "Non saprei, chiedi a qualcun altro." }, nuovo: domande.map(\.attesa)])
        let passi = ScatolaSuMisura<[String]>()
        passi.valore = []
        let esito = aspetta { await EsameSuMisura.esegui(domande, attuale: attuale, nuovo: nuovo, vera: ImpostazioniVera(), sessione: sessione) { passi.valore?.append($0) } }
        controlla(esito.superato && esito.percentuale(nuovo) == 100 && esito.percentuale(attuale) == 0 && esito.breve.superato,
                  "Esame: la Vera su misura migliore supera l'esame (\(esito.percentuale(attuale))% → \(esito.percentuale(nuovo))%)")
        let registro = ServerFintoSuMisura.registro.filter { $0.percorso == "/api/chat" }
        let domandeChat = registro.filter { !$0.precarica }
        let ordine = domandeChat.map(\.modello)
        controlla(ordine == Array(repeating: attuale, count: domande.count) + Array(repeating: nuovo, count: domande.count),
                  "Esame: un modello alla volta, tutte le domande del primo poi tutte del secondo")
        let liberaPrimo = registro.firstIndex { $0.precarica && $0.modello == attuale && $0.keepAlive == "0" }
        let primaDelSecondo = registro.firstIndex { !$0.precarica && $0.modello == nuovo }
        controlla(liberaPrimo != nil && primaDelSecondo != nil && liberaPrimo! < primaDelSecondo!,
                  "Esame: la memoria della Vera di oggi si libera prima della Vera su misura")
        controlla(domandeChat.allSatisfy { $0.temperatura == 0 && $0.pensa == false }, "Esame: temperatura 0 e niente ragionamento")
        controlla((passi.valore ?? []).contains("domanda 1 di \(domande.count) · Vera di oggi"), "Esame: l'avanzamento dice a che domanda è")
        // Un modello che Ollama non ha: errore, non superato
        ServerFintoSuMisura.prepara(installati: [attuale], risposte: [attuale: domande.map(\.attesa)])
        let senza = aspetta { await EsameSuMisura.esegui(domande, attuale: attuale, nuovo: nuovo, vera: ImpostazioniVera(), sessione: sessione) }
        controlla(!senza.superato && senza.errori[nuovo] != nil, "Esame: senza il modello in Ollama l'esame non è superato")
    }

    // MARK: - 8. Curva dell'errore

    private static func curva(_ controlla: (Bool, String) -> Void) {
        let passi = (1...500).map { ["passo": $0, "errore": 2.4 * exp(-Double($0) / 120) + 0.4] as [String: Any] }
        let dati = (try? JSONSerialization.data(withJSONObject: ["versione": 1, "passi": passi])) ?? Data()
        let c = SuMisuraVera.curva(daRapporto: dati) ?? []
        controlla(c.count == SuMisuraVera.puntiCurva && zip(c, c.dropFirst()).allSatisfy { $0 > $1 },
                  "Su misura: 500 passi diventano \(SuMisuraVera.puntiCurva) punti che scendono")
        controlla(SuMisuraVera.curva(daRapporto: Data("{rovinato".utf8)) == nil && SuMisuraVera.curva(daRapporto: Data(#"{"passi":[]}"#.utf8)) == nil,
                  "Su misura: un rapporto rovinato o vuoto non dà curva")
    }
}

private final class ScatolaSuMisura<T>: @unchecked Sendable {
    var valore: T?
}

/// Un server Ollama finto per «Vera su misura» e i motori: /api/tags con i modelli installati scelti dalla prova, /api/chat
/// con una coda di risposte per modello (la precarica e la liberazione non la consumano), blob, show, create e delete; tiene
/// il registro di ogni richiesta.
final class ServerFintoSuMisura: URLProtocol {
    struct Voce {
        var metodo: String
        var percorso: String
        var modello: String
        /// Richiesta senza messaggi: precarica o liberazione della memoria.
        var precarica: Bool
        var keepAlive: String
        var temperatura: Double?
        var pensa: Bool?
    }

    static let template = "{{ if .System }}<|im_start|>system\n{{ .System }}<|im_end|>\n{{ end }}<|im_start|>user\n{{ .Prompt }}<|im_end|>\n<|im_start|>assistant\n"
    private static let blocco = NSLock()
    private static var _installati: [String] = []
    private static var _code: [String: [String]] = [:]
    private static var _registro: [Voce] = []
    private static var _corpi: [String: [String: Any]] = [:]

    static func prepara(installati: [String], risposte: [String: [String]] = [:]) {
        blocco.lock(); defer { blocco.unlock() }
        _installati = installati
        _code = risposte
        _registro = []
        _corpi = [:]
    }

    static var registro: [Voce] {
        blocco.lock(); defer { blocco.unlock() }
        return _registro
    }

    static func corpo(_ percorso: String) -> [String: Any] {
        blocco.lock(); defer { blocco.unlock() }
        return _corpi[percorso] ?? [:]
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    private static func leggiCorpo(_ r: URLRequest) -> Data {
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
        return dati
    }

    private static func json(_ o: [String: Any]) -> String {
        String(data: (try? JSONSerialization.data(withJSONObject: o)) ?? Data(), encoding: .utf8) ?? ""
    }

    override func startLoading() {
        let percorso = request.url?.path ?? ""
        let metodo = request.httpMethod ?? "GET"
        let dati = Self.leggiCorpo(request)
        let c = (try? JSONSerialization.jsonObject(with: dati) as? [String: Any]) ?? [:]
        let modello = c["model"] as? String ?? ""
        let messaggi = c["messages"] as? [[String: Any]]
        let keepAlive = (c["keep_alive"] as? String) ?? (c["keep_alive"] as? NSNumber)?.stringValue ?? ""
        let opzioni = c["options"] as? [String: Any]
        var codice = 200
        var testo = ""
        Self.blocco.lock()
        let installati = Self._installati
        if percorso != "/api/version" && percorso != "/api/tags" {
            Self._registro.append(Voce(metodo: metodo, percorso: percorso, modello: modello, precarica: (messaggi ?? []).isEmpty && percorso == "/api/chat",
                                       keepAlive: keepAlive, temperatura: (opzioni?["temperature"] as? NSNumber)?.doubleValue, pensa: c["think"] as? Bool))
            if !c.isEmpty { Self._corpi[percorso] = c }
        }
        var risposta: String?
        if percorso == "/api/chat", !(messaggi ?? []).isEmpty, var coda = Self._code[modello], !coda.isEmpty {
            risposta = coda.removeFirst()
            Self._code[modello] = coda
        }
        Self.blocco.unlock()
        switch percorso {
        case "/api/version":
            testo = #"{"version":"0.12.0"}"#
        case "/api/tags":
            testo = Self.json(["models": installati.map { ["name": $0, "size": 1] as [String: Any] }])
        case "/api/chat" where !installati.contains(where: { FornitoreOllama.stessoModello($0, modello) }):
            codice = 404
            testo = #"{"error":"model not found"}"#
        case "/api/chat" where (messaggi ?? []).isEmpty:
            testo = Self.json(["model": modello, "done": true, "done_reason": "load"]) + "\n"
        case "/api/chat":
            testo = Self.json(["message": ["role": "assistant", "content": risposta ?? "Non so rispondere."], "done": false]) + "\n"
                + Self.json(["message": ["role": "assistant", "content": ""], "done": true, "eval_count": 6, "eval_duration": 300_000_000]) + "\n"
        case let p where p.hasPrefix("/api/blobs/"):
            codice = metodo == "HEAD" ? 404 : 201
        case "/api/show":
            testo = Self.json(["template": Self.template, "parameters": "stop \"<|im_end|>\"\nstop \"<|endoftext|>\"\ntemperature 0.6"])
        case "/api/create":
            testo = #"{"status":"success"}"#
        case "/api/delete":
            codice = 200
        default:
            codice = 404
            testo = #"{"error":"percorso sconosciuto"}"#
        }
        let r = HTTPURLResponse(url: request.url!, statusCode: codice, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: r, cacheStoragePolicy: .notAllowed)
        if !testo.isEmpty { client?.urlProtocol(self, didLoad: Data(testo.utf8)) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
