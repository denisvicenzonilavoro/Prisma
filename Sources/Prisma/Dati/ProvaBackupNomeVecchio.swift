import Foundation

// I cambi di nome dell'assistente (Eve → Ruby il 5 novembre 2026, Ruby → Vera il 7 novembre) dentro `Prisma --prova-backup`: un archivio e un backup scritti prima
// del cambio (chiave «eve» nelle impostazioni, autore «eve» nelle conversazioni e nei messaggi, l'app «eve» negli spazi
// di lavoro, la cartella «Eve/» accanto all'archivio) si aprono interi. I valori salvati restano quelli di prima, così
// anche un iPhone o un iPad non ancora aggiornato (Prisma ovunque, ponte) li legge; le cartelle «Eve/» e «Ruby/»
// diventano «Vera/».

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaNomeVecchio(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("NomeVecchio", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        let destinazione = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        let vecchioNome = Archivio.nomeCartellaVecchia
        defer { try? fm.removeItem(at: base) }

        // 1. I valori singoli scritti dalle versioni con il vecchio nome
        let dec = JSONDecoder()
        guard let m = try? dec.decode(MessaggioVera.self, from: Data(#"{"id":"msg-vecchio","autore":"eve","testo":"Ciao, sono Eve."}"#.utf8)),
              m.autore == .vera, m.testo == "Ciao, sono Eve." else { return "nome vecchio: un messaggio con autore «eve» non si legge" }
        guard (try? dec.decode([AppPrisma].self, from: Data(#"["clienti","eve"]"#.utf8))) == [.clienti, .vera] else {
            return "nome vecchio: l'app «eve» degli spazi di lavoro non si legge"
        }
        guard (try? dec.decode([AutoreMessaggio].self, from: Data(#"["eve"]"#.utf8))) == [.vera],
              (try? dec.decode([OrigineDomandaOCF].self, from: Data(#"["eve"]"#.utf8))) == [.vera] else {
            return "nome vecchio: l'autore «eve» dei messaggi o delle domande OCF non si legge"
        }
        guard let imp = try? dec.decode(Impostazioni.self, from: Data(#"{"nomeUtente":"Denis","eve":{"leggiTutto":true,"velocitaVoce":1.25}}"#.utf8)),
              imp.vera.leggiTutto, imp.vera.velocitaVoce == 1.25, imp.nomeUtente == "Denis" else {
            return "nome vecchio: le impostazioni sotto la chiave «eve» non si leggono"
        }

        // 2. Un archivio completo come lo scriveva Prisma prima del cambio di nome
        var vecchio = DatiPrisma.demo()
        let clienteId = vecchio.clienti.first?.id ?? "giulia"
        vecchio.conversazioni[clienteId] = [
            MessaggioVera(autore: .utente, testo: "Fammi un riepilogo del cliente"),
            MessaggioVera(autore: .vera, testo: "Il quadro…", titolo: "Il quadro", motore: "Sintesi dai dati"),
        ]
        vecchio.spazi = [SpazioLavoro(nome: "Incontro", finestre: [.sinistra(.clienti), .destra(.vera)])]
        vecchio.messaggi = messaggiDiProva(clienteId: clienteId)
        vecchio.impostazioni.vera.leggiTutto = true
        vecchio.impostazioni.vera.velocitaVoce = 1.25
        let grezzo = try Archivio.codificatore.encode(vecchio)
        // Il formato su disco non cambia: chi scriveva «eve» e chi lo legge oggi usano gli stessi byte
        guard let json = try JSONSerialization.jsonObject(with: grezzo) as? [String: Any],
              let impostazioni = json["impostazioni"] as? [String: Any], impostazioni[vecchioNome.lowercased()] != nil, impostazioni["vera"] == nil,
              let conversazione = (json["conversazioni"] as? [String: Any])?[clienteId] as? [[String: Any]],
              conversazione.last?["autore"] as? String == vecchioNome.lowercased() else {
            return "nome vecchio: l'archivio non usa più le chiavi di prima («eve»)"
        }
        let atteso = try Archivio.decodifica(grezzo)
        guard atteso.conversazioni[clienteId]?.last?.autore == .vera, atteso.spazi.first?.finestre.map(\.app) == [.clienti, .vera],
              atteso.impostazioni.vera.leggiTutto, atteso.impostazioni.vera.velocitaVoce == 1.25,
              atteso.messaggi.first?.autore == .vera, atteso.clienti.count == vecchio.clienti.count else {
            return "nome vecchio: l'archivio di prima non si apre intero"
        }

        // 3. La cartella dell'archivio di prima, con «Eve/», va in un backup e torna con «Vera/»
        let cartellaVecchia = dati.appendingPathComponent(vecchioNome, isDirectory: true)
        try fm.createDirectory(at: dati.appendingPathComponent("Documenti", isDirectory: true), withIntermediateDirectories: true)
        try fm.createDirectory(at: cartellaVecchia, withIntermediateDirectories: true)
        try grezzo.write(to: dati.appendingPathComponent("archivio.json"))
        try Data("documento di prova".utf8).write(to: dati.appendingPathComponent("Documenti/prova.txt"))
        let memoria = Data(#"{"memoria":"di prima"}"#.utf8)
        try memoria.write(to: cartellaVecchia.appendingPathComponent("memoria.json"))
        let copia = try GestoreBackup.crea(sorgente: dati, destinazione: backup, nota: "nome vecchio")
        let estratto = try GestoreBackup.estrai(copia)
        guard estratto.dati == atteso else { return "nome vecchio: i dati del backup di prima non tornano identici" }
        try GestoreBackup.sostituisci(cartellaDati: destinazione, con: estratto.cartella)
        let ripristinato = try Archivio.decodifica(Data(contentsOf: destinazione.appendingPathComponent("archivio.json")))
        guard ripristinato == atteso else { return "nome vecchio: l'archivio ripristinato non coincide" }
        guard (try? Data(contentsOf: destinazione.appendingPathComponent("Vera/memoria.json"))) == memoria,
              !fm.fileExists(atPath: destinazione.appendingPathComponent(vecchioNome).path),
              (try? Data(contentsOf: destinazione.appendingPathComponent("Documenti/prova.txt"))) == Data("documento di prova".utf8) else {
            return "nome vecchio: dopo il ripristino la cartella «\(vecchioNome)/» non è diventata «Vera/» con tutti i file"
        }

        // 4. Al primo avvio la cartella di prima si sposta; con tutte e due non si perde né si sovrascrive nulla
        Archivio.spostaCartellaVecchia(in: dati)
        guard (try? Data(contentsOf: dati.appendingPathComponent("Vera/memoria.json"))) == memoria,
              !fm.fileExists(atPath: cartellaVecchia.path) else {
            return "nome vecchio: all'avvio la cartella «\(vecchioNome)/» non diventa «Vera/»"
        }
        try fm.createDirectory(at: cartellaVecchia, withIntermediateDirectories: true)
        try Data("vecchia".utf8).write(to: cartellaVecchia.appendingPathComponent("memoria.json"))
        try Data("solo nella vecchia".utf8).write(to: cartellaVecchia.appendingPathComponent("altro.json"))
        Archivio.spostaCartellaVecchia(in: dati)
        guard (try? Data(contentsOf: dati.appendingPathComponent("Vera/memoria.json"))) == memoria,
              (try? Data(contentsOf: dati.appendingPathComponent("Vera/altro.json"))) == Data("solo nella vecchia".utf8),
              (try? Data(contentsOf: cartellaVecchia.appendingPathComponent("memoria.json"))) == Data("vecchia".utf8) else {
            return "nome vecchio: con «\(vecchioNome)/» e «Vera/» insieme un file si è perso o è stato sovrascritto"
        }
        // 5. La cartella «Ruby/» (il nome dal 5 al 7 novembre 2026) va anche lei in «Vera/», senza perdere nulla
        let cartellaRuby = dati.appendingPathComponent("Ruby", isDirectory: true)
        try fm.createDirectory(at: cartellaRuby, withIntermediateDirectories: true)
        try Data("solo in Ruby".utf8).write(to: cartellaRuby.appendingPathComponent("lezioni.json"))
        try Data("Ruby".utf8).write(to: cartellaRuby.appendingPathComponent("memoria.json"))
        Archivio.spostaCartellaVecchia(in: dati)
        guard (try? Data(contentsOf: dati.appendingPathComponent("Vera/lezioni.json"))) == Data("solo in Ruby".utf8),
              (try? Data(contentsOf: dati.appendingPathComponent("Vera/memoria.json"))) == memoria else {
            return "nome vecchio: la cartella «Ruby/» non diventa «Vera/» o un file è stato sovrascritto"
        }
        print("OK: archivio e backup con i nomi vecchi dell'assistente (Eve, Ruby) aperti interi, cartelle spostate in «Vera/»")
        return nil
    }
}
