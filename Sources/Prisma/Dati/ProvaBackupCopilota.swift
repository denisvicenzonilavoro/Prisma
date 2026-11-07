import Foundation

// Il consenso all'ascolto e le sessioni del copilota (versione 26, «Orizzonte», giro 5) dentro `Prisma --prova-backup`:
// tornano uguali dal backup; un archivio senza i campi nuovi si apre con le sessioni vuote, senza consenso e il resto
// uguale; una sessione illeggibile si scarta da sola; un consenso senza modo non vale (mai il contrario); la
// trascrizione di una sessione senza «Conserva la trascrizione» non si scrive mai nell'archivio.

extension ProvaBackup {
    /// Il consenso di prova (date al secondo: l'archivio le salva così).
    static func consensoCopilotaDiProva() -> ConsensoCopilota {
        ConsensoCopilota(data: Date(timeIntervalSinceReferenceDate: 815_000_000), modo: .scritto, nota: "Nota di prova")
    }

    /// Due sessioni di prova: una conclusa con la trascrizione conservata, una conclusa senza (solo il verbale).
    static func sessioniCopilotaDiProva(clienteId: String) -> [SessioneCopilota] {
        let consenso = consensoCopilotaDiProva()
        let quando = Date(timeIntervalSinceReferenceDate: 815_000_060)
        var conservata = SessioneCopilota(clienteId: clienteId, incontroId: "incontro-prova", data: quando, consenso: consenso)
        conservata.id = "copilota-prova-conservata"
        conservata.conservaTrascrizione = true
        var pezzo = PezzoTrascrizione(testo: "Testo di prova tra tre anni.", quando: quando, chi: .cliente, dispositivo: "iPad",
                                      evidenze: [IntervalloTesto(15, 27)])
        pezzo.id = "pezzo-prova"
        conservata.trascrizione = [pezzo]
        var scheda = SchedaCopilota(id: "obiettivo-casa", tipo: .obiettivo, titolo: "Casa tra 3 anni · 40.000 €", azione: .creaObiettivo,
                                    frase: "Testo di prova tra tre anni", evidenze: [IntervalloTesto(15, 27)], pezzoId: "pezzo-prova")
        scheda.cifre.area = .casa
        scheda.cifre.importo = 40_000
        scheda.cifre.anniDaOggi = 3
        scheda.stato = .confermata
        scheda.applicataIl = quando
        scheda.elementoId = "obiettivo-prova"
        var attivita = SchedaCopilota(id: "attivita-prova", tipo: .attivita, titolo: "Attività di prova", azione: .creaAttivita, frase: "")
        attivita.cifre.importi = [450, 550, 650]
        attivita.cifre.frequenza = .mensile
        attivita.cifre.scadenza = quando
        attivita.origine = .qwen
        attivita.dispositivo = "iPad"
        attivita.stato = .scartata
        conservata.schede = [scheda, attivita]
        conservata.verbale = VerbaleCopilota(punti: ["Punto di prova."], attivita: ["Attività di prova"], dossier: ["Voce di prova"], confermatoIl: quando)
        conservata.attivitaCreate = ["attivita-creata-prova"]
        conservata.conclusaIl = quando
        var senza = SessioneCopilota(clienteId: clienteId, data: quando, consenso: consenso)
        senza.id = "copilota-prova-verbale"
        var profilo = SchedaCopilota(id: "profilo-casa", tipo: .profilo, titolo: "Prudente sui soldi della casa", azione: .annotaProfilo, frase: "")
        profilo.cifre.propensione = .prudente
        profilo.cifre.area = .casa
        senza.schede = [profilo]
        senza.verbale = VerbaleCopilota(punti: ["Sui soldi della casa preferisce non rischiare."])
        senza.conclusaIl = quando
        return [conservata, senza]
    }

    /// Controlla consenso e sessioni dopo il ripristino e la lettura di un archivio senza.
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaCopilota(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.sessioniCopilota.count == 2, let cid = originale.sessioniCopilota.first?.clienteId,
              originale.clienti.first(where: { $0.id == cid })?.consensoCopilota == consensoCopilotaDiProva() else {
            return "l'archivio di prova non ha sessioni del copilota né consenso all'ascolto"
        }
        guard estratto.sessioniCopilota == originale.sessioniCopilota,
              let c = estratto.sessioniCopilota.first(where: { $0.id == "copilota-prova-conservata" }),
              c.trascrizione.first?.testo == "Testo di prova tra tre anni.", c.trascrizione.first?.chi == .cliente,
              c.trascrizione.first?.evidenze == [IntervalloTesto(15, 27)], c.schede.count == 2,
              c.scheda("obiettivo-casa")?.stato == .confermata, c.scheda("obiettivo-casa")?.cifre.importo == 40_000,
              c.scheda("attivita-prova")?.stato == .scartata, c.scheda("attivita-prova")?.cifre.importi == [450, 550, 650],
              c.scheda("attivita-prova")?.origine == .qwen, c.verbale?.confermatoIl != nil, c.attivitaCreate == ["attivita-creata-prova"],
              let v = estratto.sessioniCopilota.first(where: { $0.id == "copilota-prova-verbale" }),
              v.trascrizione.isEmpty, v.scheda("profilo-casa")?.cifre.propensione == .prudente, v.verbale?.punti.count == 1,
              estratto.clienti.first(where: { $0.id == cid })?.consensoCopilota?.modo == .scritto else {
            return "le sessioni del copilota o il consenso all'ascolto non tornano uguali dal backup"
        }
        // 2. Un archivio senza i campi nuovi del giro 5 si apre con le sessioni vuote, senza consenso e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "sessioniCopilota") != nil,
              var clienti = radice["clienti"] as? [[String: Any]],
              let i = clienti.firstIndex(where: { ($0["id"] as? String) == cid }),
              clienti[i].removeValue(forKey: "consensoCopilota") != nil else {
            return "archivio di prova senza copilota non preparato"
        }
        radice["clienti"] = clienti
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.sessioniCopilota.isEmpty, letto.clienti.first(where: { $0.id == cid })?.consensoCopilota == nil,
              letto.clienti.count == atteso.clienti.count, letto.posizioni == atteso.posizioni, letto.eventiVita == atteso.eventiVita,
              letto.incontri == atteso.incontri, letto.impostazioni == atteso.impostazioni else {
            return "archivio senza copilota non letto correttamente (attesi vuoti)"
        }
        // 3. Una sessione illeggibile si scarta, le altre restano; un consenso senza modo non vale; stato sconosciuto = proposta
        guard let prima = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.sessioniCopilota)) as? [[String: Any]])?.first,
              var schede = prima["schede"] as? [[String: Any]], !schede.isEmpty else {
            return "sessione di prova non codificata"
        }
        var strana = prima
        schede[0]["stato"] = "telepatica"
        schede.append(["id": "senza-tipo", "titolo": "Scheda senza tipo"])
        strana["schede"] = schede
        radice["sessioniCopilota"] = [["id": "senza-cliente"], 7, "non è una sessione", strana] as [Any]
        clienti[i]["consensoCopilota"] = ["data": "2026-11-04T10:00:00Z", "modo": "telepatico"]
        radice["clienti"] = clienti
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard illeggibile.sessioniCopilota.count == 1, let s = illeggibile.sessioniCopilota.first, s.id == "copilota-prova-conservata",
              s.schede.count == 2, s.scheda("obiettivo-casa")?.stato == .proposta,
              illeggibile.clienti.first(where: { $0.id == cid })?.consensoCopilota == nil,
              illeggibile.clienti.count == originale.clienti.count else {
            return "sessioni del copilota illeggibili: archivio non aperto tenendo solo quelle buone (o consenso illeggibile preso per buono)"
        }
        // 4. Senza «Conserva la trascrizione» il testo del cliente non si scrive, nemmeno con la sessione aperta
        var aperta = originale.sessioniCopilota[0]
        aperta.conservaTrascrizione = false
        aperta.conclusaIl = nil
        let scritta = String(decoding: try Archivio.codificatore.encode(aperta), as: UTF8.self)
        guard !scritta.contains("Testo di prova"), !scritta.contains("\"trascrizione\""),
              let riletta = try? Archivio.decodificatore.decode(SessioneCopilota.self, from: Data(scritta.utf8)),
              riletta.trascrizione.isEmpty, riletta.schede.allSatisfy({ $0.frase.isEmpty }), riletta.schede.count == 2 else {
            return "la trascrizione di una sessione senza «Conserva la trascrizione» finisce nell'archivio"
        }
        // 5. La versione dell'archivio resta la 26
        guard DatiPrisma.versioneAttuale >= 26 else {
            return "il copilota chiede almeno la versione 26 dell'archivio"
        }
        return nil
    }
}
