import Foundation

// «Stanotte Prisma ha lavorato» («Luce» giro 14) dentro `Prisma --prova-backup`: le notti di lavoro (una con tutti i nove
// tipi di carta, il materiale e gli effetti dell'approvazione, una interrotta con il motivo) e `Impostazioni.notte` cambiata
// vanno e tornano da backup e ripristino; le notti stanno nel file della sezione «relazione» della cartella a pezzi (non
// nell'indice, non nel file del cliente); un archivio di prima, senza le chiavi, si apre con le notti vuote e le impostazioni
// di base (spento); una carta di tipo sconosciuto si scarta, uno stato sconosciuto torna «daDecidere», un esito sconosciuto
// «interrotta», i limiti delle impostazioni tengono; un cliente tolto porta via le sue carte. Dati di prova dichiarati.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaNotte(radice: URL) throws -> String? {
        guard DatiPrisma.versioneAttuale == 27 else { return "notte: la versione dei dati non è più la 27" }
        let fm = FileManager.default
        let base = radice.appendingPathComponent("NotteLuce", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let backup = base.appendingPathComponent("Backup", isDirectory: true)
        defer { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)

        // L'archivio con i campi nuovi (dati di prova dichiarati: date fisse al secondo, nessuna dipendenza da oggi)
        var archivio = DatiPrisma.demo()
        let cal = Calendar(identifier: .gregorian)
        let giorno = cal.startOfDay(for: Date(timeIntervalSinceReferenceDate: 815_013_000))
        let ieri = cal.date(byAdding: .day, value: -1, to: giorno) ?? giorno
        let alle = NotaInArrivo.alSecondo(giorno.addingTimeInterval(2 * 3600 + 11 * 60 + 7))
        var piena = NotteDiLavoro(giorno: giorno, inizio: alle, cal: cal)
        piena.fine = alle.addingTimeInterval(243)
        piena.esito = .fatta
        piena.attenzioni = ["giulia·beneficiari", "marco·radar"]
        piena.apertaDaSola = true
        for (k, tipo) in TipoCartaNotte.allCases.enumerated() {
            var c = CartaNotte(id: "notte-prova-\(tipo.rawValue)-\(piena.giornoChiave)", tipo: tipo,
                               clienteId: k % 2 == 0 ? "giulia" : "marco", riferimento: "rif-\(k)",
                               titolo: "Titolo di prova \(k)", descrizione: "Descrizione di prova \(k)", conferma: "Fatto \(k)",
                               preparataIl: alle.addingTimeInterval(Double(k * 17)), perIl: k == 3 ? ieri : giorno)
            c.prospetti = ["patrimonio", "rendimenti"]
            c.clienti = ["giulia", "marco"]
            c.modelli = ["fac-simile"]
            c.righe = ["09:37 Giulia: fascicolo"]
            c.appuntamenti = ["app-prova-1"]
            c.daFinire = tipo == .daFinire ? 3 : 0
            c.creati = ["documento-prova-\(k)"]
            c.noteAggiunte = ["app-prova-1": "\nDa portare: fascicolo"]
            if tipo == .messaggio || tipo == .documento {
                var b = MessaggioCliente(clienteId: c.clienteId ?? "", occasioneId: "occasione-prova-\(k)",
                                         origine: OrigineMessaggio(tipo: .compleanno, riferimento: "2026"), canaleLavoro: nil,
                                         tono: .cordiale, canale: .mail, oggetto: "Oggetto di prova", testo: "Testo di prova",
                                         cifre: [], autore: .vera, modello: "qwen3.5:4b", creatoIl: alle)
                b.id = "messaggio-notte-prova-\(k)"
                c.bozze = [b]
            }
            if k == 1 { c.stato = .approvata; c.decisaIl = alle.addingTimeInterval(9000) }
            if k == 2 { c.stato = .rimandata; c.decisaIl = alle.addingTimeInterval(9100) }
            piena.carte.append(c)
        }
        var interrotta = NotteDiLavoro(giorno: ieri, inizio: alle.addingTimeInterval(-86_400), cal: cal)
        interrotta.esito = .interrotta
        interrotta.motivoStop = .memoria
        archivio.notti = [piena, interrotta]
        var imp = ImpostazioniNotte()
        imp.attivo = true
        imp.inizio = 23
        imp.massimoBozze = 5
        imp.notificaAlMattino = true
        imp.preparatori = imp.preparatori.filter { $0 != .campagna }
        archivio.impostazioni.notte = imp
        guard piena.carte.count == 9 else { return "notte: la notte di prova non ha i nove tipi di carta" }
        try Archivio.salva(archivio, in: dati)

        // Il posto su disco: la sezione «relazione», non l'indice né il file del cliente
        let pezzi = ArchivioPezzi.cartellaPezzi(in: dati)
        let relazione = (try? String(contentsOf: pezzi.appendingPathComponent(ArchivioPezzi.nomeFileSezione("relazione")), encoding: .utf8)) ?? ""
        let indice = (try? String(contentsOf: pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice), encoding: .utf8)) ?? ""
        guard ArchivioPezzi.pezzo(.notti) == .sezione("relazione"), relazione.contains(piena.carte[0].id),
              !indice.contains(piena.carte[0].id) else {
            return "notte: le notti di lavoro non stanno nel file «relazione» della cartella a pezzi"
        }
        let clientiCartella = pezzi.appendingPathComponent("Clienti", isDirectory: true)
        for nome in (try? fm.contentsOfDirectory(atPath: clientiCartella.path)) ?? [] {
            let testo = (try? String(contentsOf: clientiCartella.appendingPathComponent(nome), encoding: .utf8)) ?? ""
            if testo.contains(piena.carte[0].id) { return "notte: una carta della notte è finita nel file di un cliente" }
        }

        // Backup e ripristino
        let creato = try GestoreBackup.crea(sorgente: dati, destinazione: backup)
        let estratto = try GestoreBackup.estrai(creato)
        let d = estratto.dati
        GestoreBackup.pulisciEstrazione(estratto.cartella)
        guard d.notti == archivio.notti else { return "notte: le notti di lavoro non tornano uguali dal backup" }
        guard d.impostazioni.notte == imp else { return "notte: le impostazioni di «Stanotte» non tornano uguali dal backup" }
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: try GestoreBackup.estrai(creato).cartella)
        let dopo = Archivio.carica(in: ripristinata).dati
        guard dopo.notti == archivio.notti, dopo.impostazioni.notte == imp else {
            return "notte: le notti o le impostazioni di «Stanotte» non tornano dal ripristino"
        }

        // Un archivio di prima, senza le chiavi nuove
        var vecchio = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(archivio)) as? [String: Any] ?? [:]
        vecchio["notti"] = nil
        if var i = vecchio["impostazioni"] as? [String: Any] {
            i["notte"] = nil
            vecchio["impostazioni"] = i
        }
        let letto = try Archivio.decodificatore.decode(DatiPrisma.self, from: JSONSerialization.data(withJSONObject: vecchio))
        guard letto.notti.isEmpty, letto.impostazioni.notte == ImpostazioniNotte(), !letto.impostazioni.notte.attivo else {
            return "notte: un archivio di prima non si apre con le notti vuote e «Stanotte» spento"
        }

        // Lettura tollerante
        var notte = try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(piena)) as? [String: Any] ?? [:]
        var carte = notte["carte"] as? [[String: Any]] ?? []
        guard carte.count == 9 else { return "notte: la notte di prova non si codifica con nove carte" }
        carte[0]["tipo"] = "tipoDelFuturo"
        carte[1]["stato"] = "statoDelFuturo"
        notte["carte"] = carte
        notte["esito"] = "esitoDelFuturo"
        var senzaGiorno = notte
        senzaGiorno["giorno"] = nil
        let elenco = try JSONSerialization.data(withJSONObject: [notte, senzaGiorno])
        let tollerate = try Archivio.decodificatore.decode(ElencoTollerante<NotteDiLavoro>.self, from: elenco).elementi
        guard tollerate.count == 1, tollerate[0].carte.count == 8, tollerate[0].carte[0].stato == .daDecidere,
              tollerate[0].esito == .interrotta, tollerate[0].giornoChiave == piena.giornoChiave else {
            return "notte: una notte con un pezzo illeggibile non si legge con tolleranza"
        }
        let strane = try JSONSerialization.data(withJSONObject: ["massimoBozze": 50, "inizio": 3, "attivo": true,
                                                                  "preparatori": ["fascicolo", "tipoDelFuturo", "daFinire", "fascicolo"]])
        let lette = try Archivio.decodificatore.decode(ImpostazioniNotte.self, from: strane)
        guard lette.massimoBozze == 10, lette.inizio == 22, lette.attivo, lette.preparatori == [.fascicolo],
              !lette.notificaAlMattino else {
            return "notte: le impostazioni di «Stanotte» fuori dai limiti non tornano nei limiti"
        }

        // Un cliente tolto porta via le sue carte (e il suo id dalle carte degli altri)
        let s = StatoShell(persistente: false)
        s.dati.notti = [piena]
        s.eliminaCliente("giulia")
        guard let rimasta = s.dati.notti.first, !rimasta.carte.contains(where: { $0.clienteId == "giulia" }),
              rimasta.carte.count == 4, rimasta.carte.allSatisfy({ !$0.clienti.contains("giulia") }),
              !rimasta.attenzioni.contains("giulia·beneficiari") else {
            return "notte: un cliente tolto non porta via le sue carte della notte"
        }
        return nil
    }
}
