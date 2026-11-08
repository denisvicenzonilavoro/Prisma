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
}
