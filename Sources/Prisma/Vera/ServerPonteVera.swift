#if os(macOS)
import CryptoKit
import Foundation
import Network

/// Il Mac nel ponte di Vera (PonteVera.swift): ascolta in rete locale sulla porta 47620, si annuncia con Bonjour
/// e passa a Qwen, sul Mac stesso, le buste cifrate di iPhone e iPad. Le righe della risposta tornano cifrate,
/// una per pezzo, mentre Qwen scrive. Senza il codice di abbinamento non si apre nessuna busta.
/// Acceso solo con il collegamento acceso in Impostazioni › iPhone e iPad (Migliorie d'uso 39); leggero: nessun lavoro
/// quando nessuno chiede.
final class ServerPonteVera: @unchecked Sendable {
    static let condiviso = ServerPonteVera()

    private let coda = DispatchQueue(label: "prisma.ponte.server")
    private let blocco = NSLock()
    private var ascolto: NWListener?
    private var vera = ImpostazioniVera()
    private var chiave: SymmetricKey?
    /// La sessione verso il modello sul Mac (le prove ne passano una finta).
    private var sessione: URLSession = .shared
    private var annuncia = true
    /// Chi riceve i messaggi nuovi (schede del copilota, testi inquadrati): sul Mac lo stato dell'app
    /// (`StatoShell.riceviDalPonte`), nelle prove una raccolta. nil = il Mac non riceve ancora (ricevuta rifiutata).
    private var consegna: ((ArrivoPonte) async -> RicevutaPonte)?
    /// Migliorie d'uso 39: chi annota che un dispositivo si è fatto vivo (busta aperta con il codice giusto): sul Mac il
    /// registro dei dispositivi (`RegistroDispositivi`, in memoria). Leggero: una chiamata per busta, niente altro.
    private var contatto: (() -> Void)?

    /// La porta su cui ascolta davvero (nelle prove una porta libera qualsiasi).
    private(set) var porta: UInt16?
    /// Nome del Mac per il telefono: «MacBook Pro di Denis».
    let nomeMac = Host.current().localizedName ?? "Mac"

    /// Accende, aggiorna o spegne il ponte secondo le impostazioni di Vera.
    func aggiorna(_ e: ImpostazioniVera, sessione s: URLSession = .shared, porta p: UInt16 = PonteVera.porta, annuncia a: Bool = true) {
        blocco.lock()
        vera = e
        chiave = e.ponte.condividi ? PonteVera.chiave(e.ponte.codice) : nil
        sessione = s
        annuncia = a
        let acceso = chiave != nil
        let gia = ascolto != nil
        blocco.unlock()
        if acceso, !gia { avvia(p) } else if !acceso, gia { ferma() }
    }

    /// Chi riceve i messaggi nuovi del ponte (versione 2 del protocollo).
    func consegnaArrivi(_ f: ((ArrivoPonte) async -> RicevutaPonte)?) {
        blocco.lock()
        consegna = f
        blocco.unlock()
    }

    /// Chi annota i contatti (Migliorie d'uso 39); nil = nessuno.
    func annotaContatti(_ f: (() -> Void)?) {
        blocco.lock()
        contatto = f
        blocco.unlock()
    }

    private func annotatore() -> (() -> Void)? {
        blocco.lock(); defer { blocco.unlock() }
        return contatto
    }

    private func destinatario() -> ((ArrivoPonte) async -> RicevutaPonte)? {
        blocco.lock(); defer { blocco.unlock() }
        return consegna
    }

    func ferma() {
        blocco.lock()
        let a = ascolto
        ascolto = nil
        porta = nil
        blocco.unlock()
        a?.cancel()
    }

    var acceso: Bool {
        blocco.lock(); defer { blocco.unlock() }
        return ascolto != nil
    }

    private func avvia(_ p: UInt16) {
        let parametri = NWParameters.tcp
        parametri.includePeerToPeer = false
        guard let a = try? NWListener(using: parametri, on: p == 0 ? .any : (NWEndpoint.Port(rawValue: p) ?? .any)) else {
            DiagnosticaVoce.annota("Ponte di Vera: la porta \(p) non è libera")
            return
        }
        blocco.lock()
        if annuncia { a.service = NWListener.Service(name: nomeMac, type: PonteVera.servizio) }
        ascolto = a
        blocco.unlock()
        a.stateUpdateHandler = { [weak self, weak a] s in
            guard let self, let a else { return }
            switch s {
            case .ready:
                self.blocco.lock()
                self.porta = a.port?.rawValue
                self.blocco.unlock()
            case .failed(let e):
                DiagnosticaVoce.annota("Ponte di Vera: \(e.localizedDescription)")
                self.ferma()
            default: break
            }
        }
        a.newConnectionHandler = { [weak self] c in self?.accogli(c) }
        a.start(queue: coda)
    }

    // MARK: - Una richiesta

    private func accogli(_ c: NWConnection) {
        c.start(queue: coda)
        Task { await self.servi(c) }
    }

    private func impostazioni() -> (ImpostazioniVera, SymmetricKey?, URLSession) {
        blocco.lock(); defer { blocco.unlock() }
        return (vera, chiave, sessione)
    }

    private func servi(_ c: NWConnection) async {
        defer { c.cancel() }
        guard let richiesta = await leggiRichiesta(c) else { return await rispondi(c, 400, "richiesta non valida") }
        let (testa, corpo) = richiesta
        guard testa.hasPrefix("POST /\(PonteVera.percorso) ") else { return await rispondi(c, 404, "percorso sconosciuto") }
        let (e, k, s) = impostazioni()
        guard let k, let busta = BustaPonte.apri(corpo, k) else { return await rispondi(c, 403, "codice di abbinamento diverso") }
        annotatore()?()
        // Migliorie d'uso 39: ciò che l'utente ha spento in Impostazioni › iPhone e iPad si rifiuta (i messaggi nuovi con
        // la ricevuta, il modello con un errore breve in chiaro, come lo darebbe Ollama)
        if let motivo = e.ponte.rifiuto(percorso: busta.percorso) {
            switch busta.percorso {
            case BustaPonte.copilota, BustaPonte.inquadra, BustaPonte.carta, BustaPonte.nota:
                guard let dati = try? PonteVera.sigilla(JSONEncoder().encode(RicevutaPonte.rifiutata(motivo)), k) else {
                    return await rispondi(c, 500, "errore")
                }
                await scrivi(c, Self.testata(200) + dati)
                return
            default:
                return await rispondi(c, 403, motivo)
            }
        }
        let fornitore = FornitoriVera.crea(e, sessione: s)
        switch busta.percorso {
        case BustaPonte.stato:
            let d: DisponibilitaVera = await fornitore.verifica()
            var st = StatoPonte(pronto: d.pronto, motivo: d.motivo, fornitore: e.fornitore, modello: e.modello, mac: nomeMac,
                                versione: PonteVera.versioneProtocollo)
            // Il computer dell'IA dice anche memoria e modelli (nessun dato dei clienti: solo nomi dei modelli e GB)
            if e.computerIA.questoMac {
                st.computerIA = true
                st.memoriaGB = MemoriaComputer.totaleGB
                st.prismaGB = MemoriaComputer.prismaGB()
                st.installati = (try? await fornitore.modelli()) ?? []
                if let o = fornitore as? FornitoreOllama { st.inMemoria = await o.inMemoria() }
            }
            guard let dati = try? PonteVera.sigilla(JSONEncoder().encode(st), k) else { return await rispondi(c, 500, "errore") }
            await scrivi(c, Self.testata(200) + dati)
        case BustaPonte.precarica:
            let memoria = busta.corpo.flatMap { String(data: $0, encoding: .utf8) } ?? e.restaInMemoria
            let ok = await fornitore.precarica(restaInMemoria: memoria.isEmpty ? e.restaInMemoria : memoria)
            await rispondi(c, ok ? 200 : 503, ok ? "pronto" : "non caricato")
        case BustaPonte.copilota, BustaPonte.inquadra, BustaPonte.carta, BustaPonte.nota:
            // Versione 2: un messaggio nuovo dall'iPad o dall'iPhone. Solo testo; chi lo riceve decide (consenso, conferma).
            // Versione 3 («Luce» giro 13): in più la carta d'identità e la nota vocale
            guard let arrivo = ArrivoPonte.leggi(busta) else { return await rispondi(c, 400, "messaggio non valido") }
            let ricevuta: RicevutaPonte
            if let f = destinatario() {
                ricevuta = await f(arrivo)
            } else {
                ricevuta = .rifiutata("Prisma sul Mac non è pronto a ricevere: aprilo e riprova.")
            }
            guard let dati = try? PonteVera.sigilla(JSONEncoder().encode(ricevuta), k) else { return await rispondi(c, 500, "errore") }
            await scrivi(c, Self.testata(200) + dati)
        case let p where PonteVera.percorsiAmmessi.contains(p):
            // Il computer dell'IA usa il modello chiesto dal Mac di lavoro se l'ha già scaricato; gli altri Mac sempre il loro
            var installati: [String] = []
            if e.computerIA.questoMac { installati = (try? await fornitore.modelli()) ?? [] }
            await inoltra(c, p, busta.corpo, fornitore: fornitore, modello: e.modello, ammessi: installati, sessione: s, chiave: k)
        default:
            await rispondi(c, 404, "percorso sconosciuto")
        }
    }

    /// Passa la richiesta al modello sul Mac e rimanda le righe cifrate. Il modello è quello scelto qui, salvo sul
    /// computer dell'IA, dove vale quello chiesto se è tra gli `ammessi` (i modelli già scaricati).
    private func inoltra(_ c: NWConnection, _ percorso: String, _ corpo: Data?, fornitore: FornitoreModello,
                         modello: String, ammessi: [String] = [], sessione: URLSession, chiave k: SymmetricKey) async {
        guard let corpo, var j = (try? JSONSerialization.jsonObject(with: corpo)) as? [String: Any],
              let u = try? fornitore.url(percorso) else { return await rispondi(c, 400, "corpo non valido") }
        j["model"] = Self.modelloDaUsare(chiesto: j["model"] as? String, delMac: modello, ammessi: ammessi)
        var r = URLRequest(url: u, timeoutInterval: MotoreLocale.attesaMassima)
        r.httpMethod = "POST"
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try? JSONSerialization.data(withJSONObject: j)
        do {
            let (byte, risposta) = try await sessione.bytes(for: r)
            let codice = (risposta as? HTTPURLResponse)?.statusCode ?? 502
            guard codice == 200 else {
                // L'errore del modello (modello mancante, memoria): breve e in chiaro, come lo darebbe Ollama
                var testo = ""
                for try await riga in byte.lines {
                    testo += riga
                    if testo.count > 300 { break }
                }
                return await rispondi(c, codice, testo)
            }
            guard await scrivi(c, Self.testata(200)) else { return }
            for try await riga in byte.lines {
                guard !riga.trimmingCharacters(in: .whitespaces).isEmpty, let s = try? PonteVera.sigillaRiga(riga, k) else { continue }
                // Il telefono ha chiuso: si smette di leggere e la connessione con il modello si chiude
                guard await scrivi(c, Data((s + "\n").utf8)) else { return }
            }
        } catch {
            await rispondi(c, 502, "\(fornitore.nome) non ha risposto sul Mac")
        }
    }

    /// Il modello della richiesta: quello chiesto se è tra gli ammessi (computer dell'IA), altrimenti quello del Mac.
    static func modelloDaUsare(chiesto: String?, delMac: String, ammessi: [String]) -> String {
        guard let chiesto, ammessi.contains(where: { FornitoreOllama.stessoModello($0, chiesto) }) else { return delMac }
        return chiesto
    }

    // MARK: - HTTP essenziale

    private static func testata(_ codice: Int) -> Data {
        Data("HTTP/1.1 \(codice) \(codice == 200 ? "OK" : "Errore")\r\nContent-Type: application/octet-stream\r\nConnection: close\r\n\r\n".utf8)
    }

    private func rispondi(_ c: NWConnection, _ codice: Int, _ testo: String) async {
        await scrivi(c, Self.testata(codice) + Data(testo.utf8))
    }

    @discardableResult
    private func scrivi(_ c: NWConnection, _ dati: Data) async -> Bool {
        await withCheckedContinuation { (fine: CheckedContinuation<Bool, Never>) in
            c.send(content: dati, completion: .contentProcessed { e in fine.resume(returning: e == nil) })
        }
    }

    private func ricevi(_ c: NWConnection) async -> Data? {
        await withCheckedContinuation { (fine: CheckedContinuation<Data?, Never>) in
            c.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { dati, _, finito, errore in
                if let dati, !dati.isEmpty { return fine.resume(returning: dati) }
                fine.resume(returning: (finito || errore != nil) ? nil : Data())
            }
        }
    }

    /// La prima riga della richiesta e il corpo (Content-Length), entro i limiti del ponte.
    private func leggiRichiesta(_ c: NWConnection) async -> (String, Data)? {
        var dati = Data()
        let separatore = Data("\r\n\r\n".utf8)
        var fineTesta: Range<Data.Index>?
        while fineTesta == nil {
            guard dati.count < 16_384, let pezzo = await ricevi(c) else { return nil }
            dati.append(pezzo)
            fineTesta = dati.range(of: separatore)
        }
        guard let f = fineTesta, let testa = String(data: dati[..<f.lowerBound], encoding: .utf8) else { return nil }
        let righe = testa.components(separatedBy: "\r\n")
        let lunghezza = righe.dropFirst().compactMap { r -> Int? in
            let parti = r.split(separator: ":", maxSplits: 1)
            guard parti.count == 2, parti[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length" else { return nil }
            return Int(parti[1].trimmingCharacters(in: .whitespaces))
        }.first ?? 0
        guard lunghezza > 0, lunghezza <= PonteVera.massimoBusta else { return nil }
        var corpo = Data(dati[f.upperBound...])
        while corpo.count < lunghezza {
            guard let pezzo = await ricevi(c) else { return nil }
            corpo.append(pezzo)
        }
        return (righe.first ?? "", corpo.prefix(lunghezza))
    }
}
#endif
