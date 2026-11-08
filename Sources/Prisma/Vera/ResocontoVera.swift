import AVFoundation
import Foundation
import Speech

// «Il resoconto dell'incontro» (Vera/BRIEF.md, funzione 16; template «Il resoconto dell'incontro»): dopo un incontro
// Vera scrive il verbale nel formato del consulente (Presenti, Di cosa abbiamo parlato, Cosa abbiamo deciso, Prossimi
// passi, Da raccogliere) o in breve, dagli appunti dell'incontro, dal verbale del copilota e dalla nota vocale.
// Prima il codice: Prisma compone le sezioni dai dati; Qwen le riscrive in JSON con lo schema fisso, e una cifra cambiata
// fa restare il testo di Prisma. La nota vocale (m4a, mp3, wav, fino a 60 minuti) si trascrive sul Mac, a pezzi da un
// minuto, con Speech di Apple sul dispositivo; l'audio non si salva mai, solo il testo, e solo con il consenso alla
// registrazione del cliente (lo stesso del copilota). Il resoconto si rivede e si firma: nome, data e un PDF nei
// Documenti del cliente; le attività e le promesse nascono dalla scheda di conferma.

enum ResocontoVera {
    static let titoliSezioni = ["Presenti", "Di cosa abbiamo parlato", "Cosa abbiamo deciso", "Prossimi passi", "Da raccogliere"]
    static let chiavi = ["presenti", "parlato", "deciso", "passi", "raccogliere"]
    static let estensioniAudio = ["m4a", "mp3", "wav", "aac", "caf", "aiff"]
    static let durataMassima: TimeInterval = 60 * 60

    private static func righe(_ testo: String) -> [String] {
        PromesseVera.frasi(testo).map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "-•· ")) }.filter { !$0.isEmpty }
    }

    /// Le sezioni composte da Prisma: dagli appunti dell'incontro, dal verbale del copilota e dalla trascrizione.
    static func componi(_ i: Incontro, cliente c: Cliente, consulente: String, verbale: VerbaleCopilota?, trascrizione: String?,
                        analisiSalvata: Bool) -> ResocontoIncontro {
        var presenti = [c.nome]
        let testoTutto = [i.testoAscolto, trascrizione ?? ""].joined(separator: "\n").lowercased()
        for f in c.famiglia {
            let primo = f.nome.split(separator: " ").first.map(String.init) ?? f.nome
            if primo.count >= 3, testoTutto.contains(primo.lowercased()) { presenti.append(f.nome) }
        }
        if !consulente.isEmpty { presenti.append(consulente) }
        var parlato = righe(i.preoccupazioni) + righe(i.progetti) + righe(i.esperienza) + righe(i.appunti)
        parlato += verbale?.punti ?? []
        if parlato.isEmpty, let t = trascrizione { parlato = Array(righe(t).prefix(6)) }
        let deciso = righe(i.decisioni)
        var passi: [String] = []
        if !i.prossimaAttivita.isEmpty {
            passi.append(i.prossimaAttivita + (i.scadenzaAttivita.map { " · entro il \(Formati.dataEstesa.string(from: $0))" } ?? ""))
        }
        if let p = i.prossimoIncontro { passi.append("Prossimo incontro · \(Formati.dataLunga.string(from: p)), \(Formati.ora.string(from: p))") }
        passi += verbale?.attivita ?? []
        let promesse = PromesseVera.conRegole(FontePromesse(clienteId: c.id, tipo: .resoconto, id: i.id, etichetta: "", data: i.data,
                                                            testo: [i.appunti, i.decisioni, trascrizione ?? ""].joined(separator: "\n")), nome: c.nome.split(separator: " ").first.map(String.init) ?? c.nome)
        passi += promesse.map { $0.testo + ($0.quando.map { " · \($0)" } ?? "") }
        var raccogliere: [String] = []
        if !analisiSalvata { raccogliere.append("Fabbisogno mensile della famiglia (Analisi 360)") }
        if c.professione.isEmpty { raccogliere.append("Professione del cliente") }
        if c.dataNascita == nil { raccogliere.append("Data di nascita del cliente") }
        let sezioni = [SezioneResoconto(titolo: titoliSezioni[0], righe: [presenti.joined(separator: ", ")]),
                       SezioneResoconto(titolo: titoliSezioni[1], righe: unici(parlato)),
                       SezioneResoconto(titolo: titoliSezioni[2], righe: unici(deciso)),
                       SezioneResoconto(titolo: titoliSezioni[3], righe: unici(passi)),
                       SezioneResoconto(titolo: titoliSezioni[4], righe: raccogliere.isEmpty ? ["Niente: i dati per i calcoli ci sono."] : raccogliere)]
        var fonti: [ResocontoIncontro.Fonte] = []
        if !i.vuoto { fonti.append(.appunti) }
        if verbale != nil { fonti.append(.copilota) }
        if trascrizione != nil { fonti.append(.notaVocale) }
        let breve = Array((unici(deciso) + unici(passi).prefix(2) + (raccogliere.isEmpty ? [] : ["Da raccogliere: " + raccogliere.joined(separator: ", ").lowercased()])).prefix(5))
        return ResocontoIncontro(titolo: i.titolo, sezioni: sezioni, breve: breve.isEmpty ? Array(unici(parlato).prefix(3)) : breve, fonti: fonti,
                                 trascrizione: trascrizione)
    }

    private static func unici(_ r: [String]) -> [String] {
        var visti: Set<String> = []
        return r.filter { visti.insert(PromesseVera.normale($0)).inserted }
    }

    // MARK: - Qwen (JSON, cifre di Prisma)

    static let schema: [String: Any] = {
        var p: [String: Any] = ["presenti": ["type": "string"]]
        for k in chiavi.dropFirst() { p[k] = ["type": "array", "items": ["type": "string"]] }
        p["breve"] = ["type": "array", "items": ["type": "string"]]
        return ["type": "object", "properties": p, "required": chiavi + ["breve"]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("resoconto") ?? "Riscrivi il resoconto di un incontro preparato da Prisma nel formato del consulente: presenti, parlato (di cosa abbiamo parlato), deciso, passi (prossimi passi), raccogliere (dati da raccogliere), più breve (al massimo quattro punti). Frasi brevi, in italiano. Usa solo i fatti e le cifre del resoconto di Prisma e della trascrizione: non aggiungere niente, non cambiare cifre, date o nomi. Rispondi solo con il JSON."
    }

    static func messaggi(_ r: ResocontoIncontro, cliente: String) -> [MessaggioModello] {
        let sezioni = r.sezioni.map { "\($0.titolo.uppercased())\n" + $0.righe.map { "- \($0)" }.joined(separator: "\n") }.joined(separator: "\n\n")
        let nota = r.trascrizione.map { "\n\nTRASCRIZIONE DELLA NOTA VOCALE\n" + String($0.prefix(6_000)) } ?? ""
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "CLIENTE: \(cliente)\nRESOCONTO DI PRISMA\n\(sezioni)\(nota)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.2
        o.contesto = NucleoVera.finestra
        o.massimoToken = 1_200
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    /// Le sezioni di Qwen dove le cifre tornano con quelle di Prisma e della trascrizione; le altre restano di Prisma.
    static func applica(_ json: String, a r: ResocontoIncontro) -> ResocontoIncontro {
        guard let i = json.firstIndex(of: "{"), let f = json.lastIndex(of: "}"), i < f,
              let d = String(json[i...f]).data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return r }
        let fonte = r.sezioni.flatMap(\.righe).joined(separator: "\n") + "\n" + (r.trascrizione ?? "")
        var nuovo = r
        var cambiato = false
        for (n, k) in chiavi.enumerated() where n > 0 {
            guard let righe = (j[k] as? [String])?.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }).filter({ !$0.isEmpty }), !righe.isEmpty,
                  CommentoVera.numeriConservati(bozza: fonte, testo: righe.joined(separator: "\n")) else { continue }
            nuovo.sezioni[n].righe = righe
            cambiato = true
        }
        if let b = (j["breve"] as? [String])?.filter({ !$0.isEmpty }), !b.isEmpty, CommentoVera.numeriConservati(bozza: fonte, testo: b.joined(separator: "\n")) {
            nuovo.breve = Array(b.prefix(5))
            cambiato = true
        }
        nuovo.conQwen = cambiato
        return nuovo
    }

    /// Il PDF firmato: le sezioni come prospetto, con la firma, la data e da dove viene.
    static func contenuto(_ r: ResocontoIncontro, incontro i: Incontro, cliente: String) -> ContenutoProspetto {
        var blocchi: [BloccoProspetto] = []
        for (n, s) in r.sezioniMostrate.enumerated() {
            blocchi.append(.sezione(numero: String(format: "%02d", n + 1), titolo: s.titolo))
            blocchi.append(.testo(s.righe.map { "• \($0)" }.joined(separator: "\n")))
        }
        let fonti = r.fonti.map { f -> String in
            switch f {
            case .appunti: return "dagli appunti dell'incontro"
            case .copilota: return "dal copilota dell'incontro"
            case .notaVocale: return "dalla nota vocale (trascritta sul Mac, l'audio non è conservato)"
            }
        }
        var nota = "Scritto con Vera \(fonti.joined(separator: ", ")). Rivisto e firmato"
        if let chi = r.firmatoDa { nota += " da \(chi)" }
        if let quando = r.firmatoIl { nota += " il \(Formati.dataEstesa.string(from: quando))" }
        nota += "."
        if let c = r.consenso { nota += " Consenso alla registrazione del \(Formati.dataEstesa.string(from: c.data))." }
        blocchi.append(.nota(nota))
        return ContenutoProspetto(occhiello: "Resoconto dell'incontro", titolo: "Resoconto · \(r.titolo) · \(Formati.dataBreve.string(from: i.data)) \(Formati.ora.string(from: i.data))", sottotitolo: "\(Formati.dataLunga.string(from: i.data)), \(Formati.ora.string(from: i.data))",
                                  cliente: cliente, blocchi: blocchi)
    }
}

/// La trascrizione di una nota vocale sul Mac (Speech di Apple, sul dispositivo), a pezzi da un minuto: la versione
/// classica regge circa un minuto per richiesta. L'audio non si salva: si legge dal file scelto e si butta.
enum TrascrizioneFile {
    static let pezzo: TimeInterval = 55

    enum Errore: LocalizedError {
        case formato, troppoLunga, permesso, riconoscimento(String)

        var errorDescription: String? {
            switch self {
            case .formato: return "Questo file audio non si apre: usa m4a, mp3 o wav."
            case .troppoLunga: return "La nota vocale è più lunga di 60 minuti: dividila in più parti."
            case .permesso: return "Il riconoscimento vocale non è permesso: consentilo in Impostazioni di Sistema › Privacy."
            case .riconoscimento(let m): return "Non riesco a trascrivere la nota vocale: \(m)"
            }
        }
    }

    /// La durata del file in secondi.
    static func durata(_ url: URL) -> TimeInterval? {
        guard let f = try? AVAudioFile(forReading: url) else { return nil }
        return Double(f.length) / f.processingFormat.sampleRate
    }

    /// Il testo della nota vocale: pezzo per pezzo, in ordine. `avanza` riceve la frazione fatta (0...1).
    static func trascrivi(_ url: URL, avanza: @escaping (Double) -> Void = { _ in }) async throws -> String {
        guard let file = try? AVAudioFile(forReading: url) else { throw Errore.formato }
        let formato = file.processingFormat
        let totale = Double(file.length) / formato.sampleRate
        guard totale <= ResocontoVera.durataMassima else { throw Errore.troppoLunga }
        let stato = await withCheckedContinuation { c in SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) } }
        guard stato == .authorized else { throw Errore.permesso }
        guard let riconoscitore = SFSpeechRecognizer(locale: Locale(identifier: "it-IT")), riconoscitore.isAvailable else {
            throw Errore.riconoscimento("il riconoscimento in italiano non è disponibile su questo Mac.")
        }
        // Solo sul Mac: senza il modello italiano sul dispositivo l'audio andrebbe ai server di Apple, e non deve uscire
        guard riconoscitore.supportsOnDeviceRecognition else {
            throw Errore.riconoscimento("il riconoscimento in italiano sul Mac non è installato (Impostazioni di Sistema › Tastiera › Dettatura): l'audio non esce dal Mac.")
        }
        let cornici = AVAudioFrameCount(pezzo * formato.sampleRate)
        var testi: [String] = []
        var letto: AVAudioFramePosition = 0
        let cartella = FileManager.default.temporaryDirectory.appendingPathComponent("Prisma-nota-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: cartella) }
        var n = 0
        while letto < file.length {
            try Task.checkCancellation()
            guard let buffer = AVAudioPCMBuffer(pcmFormat: formato, frameCapacity: cornici) else { throw Errore.formato }
            file.framePosition = letto
            try file.read(into: buffer, frameCount: cornici)
            guard buffer.frameLength > 0 else { break }
            letto += AVAudioFramePosition(buffer.frameLength)
            // Il pezzo in un file temporaneo (cancellato subito), poi una richiesta sul dispositivo
            let pezzoURL = cartella.appendingPathComponent("pezzo-\(n).caf")
            n += 1
            do {
                let uscita = try AVAudioFile(forWriting: pezzoURL, settings: formato.settings)
                try uscita.write(from: buffer)
            }
            let richiesta = SFSpeechURLRecognitionRequest(url: pezzoURL)
            richiesta.requiresOnDeviceRecognition = true
            richiesta.shouldReportPartialResults = false
            let testo: String = try await withCheckedThrowingContinuation { c in
                var finito = false
                riconoscitore.recognitionTask(with: richiesta) { r, e in
                    guard !finito else { return }
                    if let r, r.isFinal { finito = true; c.resume(returning: r.bestTranscription.formattedString) } else if let e {
                        finito = true
                        // Un pezzo di silenzio non è un errore
                        let nsE = e as NSError
                        if nsE.domain == "kAFAssistantErrorDomain" && nsE.code == 1110 { c.resume(returning: "") } else { c.resume(throwing: Errore.riconoscimento(e.localizedDescription)) }
                    }
                }
            }
            try? FileManager.default.removeItem(at: pezzoURL)
            if !testo.isEmpty { testi.append(testo) }
            avanza(min(1, Double(letto) / Double(file.length)))
        }
        return testi.joined(separator: " ")
    }
}
