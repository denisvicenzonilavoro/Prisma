import Foundation

// La nota vocale e il nuovo cliente («Luce» giro 13) dentro `Prisma --prova-backup`: le note arrivate dall'iPhone
// (`noteInArrivo`, una da guardare con le proposte e una confermata) e la cittadinanza del cliente vanno e tornano da
// backup e ripristino; le note stanno nel file della sezione «ovunque» della cartella a pezzi (non nell'indice, non nel
// file del cliente); un archivio di prima, senza le chiavi, si apre con le note vuote e la cittadinanza nil; una nota con
// un pezzo illeggibile resta (la proposta di tipo sconosciuto si scarta, lo stato sconosciuto torna «proposta»); un
// cliente tolto porta via le sue note; la potatura toglie solo le decise da più di 30 giorni.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaNoteVocali(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("NoteVocaliLuce", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)

        // L'archivio con i campi nuovi (dati di prova dichiarati)
        var archivio = DatiPrisma.demo()
        guard let i = archivio.clienti.firstIndex(where: { $0.id == "giulia" }) else { return "note vocali: manca Giulia nei dati di prova" }
        archivio.clienti[i].cittadinanza = "Italiana"
        let oggi = NotaInArrivo.alSecondo(Date(timeIntervalSinceReferenceDate: 815_000_000))
        let daGuardare = NotaVocaleDiProva.inArrivo(archivio, oggi: oggi)
        var confermata = NotaVocaleDiProva.inArrivo(archivio, oggi: oggi)
        confermata.id = NotaVocaleDiProva.prefisso + "confermata"
        confermata.stato = .confermata
        confermata.decisaIl = oggi
        if !confermata.proposte.isEmpty { confermata.proposte[0].stato = .confermata }
        archivio.noteInArrivo = [daGuardare, confermata]
        guard !daGuardare.proposte.isEmpty else { return "note vocali: la nota di prova non ha proposte" }
        try Archivio.salva(archivio, in: dati)

        // Il posto su disco: la sezione «ovunque», non l'indice né il file del cliente
        let pezzi = ArchivioPezzi.cartellaPezzi(in: dati)
        let ovunque = (try? String(contentsOf: pezzi.appendingPathComponent(ArchivioPezzi.nomeFileSezione("ovunque")), encoding: .utf8)) ?? ""
        let indice = (try? String(contentsOf: pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice), encoding: .utf8)) ?? ""
        guard ArchivioPezzi.pezzo(.noteInArrivo) == .sezione("ovunque"), ovunque.contains(daGuardare.id), !indice.contains(daGuardare.id) else {
            return "note vocali: le note dall'iPhone non stanno nel file «ovunque» della cartella a pezzi"
        }

        // Backup e ripristino
        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup)
        let estratto = try GestoreBackup.estrai(creato)
        let d = estratto.dati
        GestoreBackup.pulisciEstrazione(estratto.cartella)
        guard d.noteInArrivo == archivio.noteInArrivo else { return "note vocali: le note dall'iPhone non tornano uguali dal backup" }
        guard d.clienti.first(where: { $0.id == "giulia" })?.cittadinanza == "Italiana" else {
            return "note vocali: la cittadinanza del cliente non torna dal backup"
        }
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: try GestoreBackup.estrai(creato).cartella)
        guard Archivio.carica(in: ripristinata).dati.noteInArrivo == archivio.noteInArrivo else {
            return "note vocali: le note dall'iPhone non tornano dal ripristino"
        }

        // Un archivio di prima, senza le chiavi nuove
        var vecchio = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(archivio)) as? [String: Any] ?? [:]
        vecchio["noteInArrivo"] = nil
        if var clienti = vecchio["clienti"] as? [[String: Any]] {
            for k in clienti.indices { clienti[k]["cittadinanza"] = nil }
            vecchio["clienti"] = clienti
        }
        let letto = try Archivio.decodificatore.decode(DatiPrisma.self, from: JSONSerialization.data(withJSONObject: vecchio))
        guard letto.noteInArrivo.isEmpty, letto.clienti.allSatisfy({ $0.cittadinanza == nil }) else {
            return "note vocali: un archivio di prima non si apre con le note vuote e la cittadinanza assente"
        }

        // Lettura tollerante: una proposta di tipo sconosciuto si scarta, uno stato sconosciuto torna «proposta», una nota
        // senza testo si scarta
        var nota = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(daGuardare)) as? [String: Any] ?? [:]
        var proposte = nota["proposte"] as? [[String: Any]] ?? []
        guard proposte.count >= 2 else { return "note vocali: la nota di prova ha meno di due proposte" }
        proposte[0]["stato"] = "statoDelFuturo"
        proposte[1]["tipo"] = "tipoDelFuturo"
        nota["proposte"] = proposte
        nota["stato"] = "statoDelFuturo"
        var senzaTesto = nota
        senzaTesto["testo"] = nil
        let elenco = try JSONSerialization.data(withJSONObject: [nota, senzaTesto])
        let tollerate = try Archivio.decodificatore.decode(ElencoTollerante<NotaInArrivo>.self, from: elenco).elementi
        guard tollerate.count == 1, tollerate[0].stato == .daGuardare, tollerate[0].proposte.count == daGuardare.proposte.count - 1,
              tollerate[0].proposte.first?.stato == .proposta else {
            return "note vocali: una nota con un pezzo illeggibile non si legge con tolleranza"
        }

        // Un cliente tolto porta via le sue note; la potatura toglie solo le decise da più di 30 giorni
        let s = StatoShell(persistente: false)
        var vecchia = confermata
        vecchia.id = NotaVocaleDiProva.prefisso + "vecchia"
        vecchia.clienteId = "laura"
        vecchia.decisaIl = NotaInArrivo.alSecondo(Date().addingTimeInterval(-31 * 86_400))
        var recente = confermata
        recente.id = NotaVocaleDiProva.prefisso + "recente"
        recente.clienteId = "laura"
        recente.decisaIl = NotaInArrivo.alSecondo(Date().addingTimeInterval(-2 * 86_400))
        var dubbia = daGuardare
        dubbia.id = NotaVocaleDiProva.prefisso + "dubbia"
        dubbia.clienteId = nil
        dubbia.candidati = ["giulia", "marco"]
        s.dati.noteInArrivo = [daGuardare, vecchia, recente, dubbia]
        s.potaNoteInArrivo()
        guard s.dati.noteInArrivo.map(\.id) == [daGuardare.id, recente.id, dubbia.id] else {
            return "note vocali: la potatura non toglie solo le note decise da più di 30 giorni"
        }
        s.eliminaCliente("giulia")
        guard s.dati.noteInArrivo.map(\.id) == [recente.id, dubbia.id], s.dati.noteInArrivo.last?.candidati == ["marco"] else {
            return "note vocali: un cliente tolto non porta via le sue note (o resta tra i candidati)"
        }
        return nil
    }
}
