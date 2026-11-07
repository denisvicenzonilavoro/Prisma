import Foundation

// Il radar del portafoglio (versione 27, «Luce» giro 2) dentro `Prisma --prova-backup`: portafogli modello, tolleranza,
// modello dei clienti e segno delle bozze di riequilibrio tornano uguali dal backup; un archivio senza i campi nuovi si
// apre con i modelli vuoti e il resto uguale; un modello illeggibile si scarta, un colore sconosciuto torna verde, una
// tolleranza negativa o illeggibile diventa «non scritta».

extension ProvaBackup {
    /// Porta nell'archivio di prova un modello con la sua tolleranza e una bozza di riequilibrio (i modelli e i clienti
    /// assegnati vengono già dai dati di prova).
    static func aggiungiRadarDiProva(_ d: inout DatiPrisma) {
        if d.portafogliModello.isEmpty { PortafogliModelloDiProva.applica(&d) }
        if let i = d.portafogliModello.indices.first { d.portafogliModello[i].tolleranza = 4 }
        guard let c = d.clienti.first(where: { $0.modelloId != nil }) else { return }
        var bozza = Posizione(clienteId: c.id, canale: .indipendente, stato: .proposta, area: .investimento,
                              nome: "Riequilibrio di prova")
        bozza.id = "pos-prova-riequilibrio"
        bozza.esito = .bozza
        // Date a secondi interi, come le altre dell'archivio di prova
        bozza.creataIl = Date(timeIntervalSinceReferenceDate: 800_000_000)
        bozza.riequilibrio = OrigineRiequilibrio(modelloId: c.modelloId ?? "", distanza: 9.5,
                                                 creataIl: Date(timeIntervalSinceReferenceDate: 800_000_000))
        d.posizioni.append(bozza)
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaRadar(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.portafogliModello.count == 3, originale.impostazioni.tolleranzaRadar != nil,
              originale.clienti.contains(where: { $0.modelloId != nil }),
              originale.posizioni.contains(where: { $0.riequilibrio != nil }) else {
            return "l'archivio di prova non ha portafogli modello, tolleranza, clienti assegnati o bozze di riequilibrio"
        }
        guard estratto.portafogliModello == originale.portafogliModello,
              estratto.impostazioni.tolleranzaRadar == originale.impostazioni.tolleranzaRadar,
              estratto.clienti.map(\.modelloId) == originale.clienti.map(\.modelloId),
              estratto.posizioni.first(where: { $0.id == "pos-prova-riequilibrio" })?.riequilibrio
                == originale.posizioni.first(where: { $0.id == "pos-prova-riequilibrio" })?.riequilibrio,
              estratto.portafogliModello.first?.tolleranza == 4 else {
            return "portafogli modello, tolleranza, modello dei clienti o bozze di riequilibrio non tornano uguali dal backup"
        }
        // 2. Un archivio senza i campi del giro 2 si apre con i modelli vuoti e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "portafogliModello") != nil,
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "tolleranzaRadar") != nil,
              var clienti = radice["clienti"] as? [[String: Any]],
              var posizioni = radice["posizioni"] as? [[String: Any]] else {
            return "archivio di prova senza i campi del radar non preparato"
        }
        for i in clienti.indices { clienti[i].removeValue(forKey: "modelloId") }
        for i in posizioni.indices { posizioni[i].removeValue(forKey: "riequilibrio") }
        radice["impostazioni"] = impostazioni
        radice["clienti"] = clienti
        radice["posizioni"] = posizioni
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.portafogliModello.isEmpty, letto.impostazioni.tolleranzaRadar == nil,
              letto.clienti.allSatisfy({ $0.modelloId == nil }), letto.posizioni.allSatisfy({ $0.riequilibrio == nil }),
              letto.clienti.count == originale.clienti.count, letto.posizioni.count == originale.posizioni.count,
              letto.obiettivi == atteso.obiettivi, letto.messaggi == atteso.messaggi else {
            return "archivio senza i campi del radar non letto correttamente (attesi vuoti, il resto uguale)"
        }
        // 3. Un modello illeggibile si scarta, un colore sconosciuto torna verde, una tolleranza negativa non vale
        guard let primo = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.portafogliModello)) as? [[String: Any]])?.first else {
            return "modello di prova non codificato"
        }
        var strano = primo
        strano["colore"] = "oro zecchino"
        strano["tolleranza"] = "tanta"
        radice["portafogliModello"] = [["nome": "senza id"], 7, strano] as [Any]
        impostazioni["tolleranzaRadar"] = -3
        radice["impostazioni"] = impostazioni
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard illeggibile.portafogliModello.count == 1, let m = illeggibile.portafogliModello.first,
              m.colore == .verde, m.tolleranza == nil, m.pesi == originale.portafogliModello.first?.pesi,
              illeggibile.impostazioni.tolleranzaRadar == nil,
              illeggibile.clienti.count == originale.clienti.count else {
            return "portafogli modello illeggibili: archivio non aperto tenendo solo quelli buoni"
        }
        // 4. I campi del radar stanno nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale >= 27 else {
            return "il radar chiede almeno la versione 27 dell'archivio"
        }
        return nil
    }
}
