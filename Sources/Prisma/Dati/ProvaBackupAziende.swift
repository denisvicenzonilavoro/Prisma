import Foundation

// Le aziende dei clienti imprenditori (versione 27, «Luce» giro 7) dentro `Prisma --prova-backup`: un'azienda completa
// (con le coperture della persona chiave collegate, TFM, welfare e continuità) e una con il solo nome tornano uguali dal
// backup; un archivio senza aziende si apre con nessuna azienda e il resto uguale; un'azienda senza id si scarta e le altre
// restano; un campo illeggibile (forma sconosciuta, quota fuori scala, una voce senza titolo) diventa «non indicato».

extension ProvaBackup {
    /// L'azienda di prova di Marco (dai dati di prova) con una copertura collegata, e una con il solo nome a un altro
    /// cliente.
    static func aggiungiAziendeDiProva(_ d: inout DatiPrisma) {
        guard let i = d.clienti.firstIndex(where: { !$0.elencoAziende.isEmpty }) ?? d.clienti.indices.first else { return }
        if d.clienti[i].elencoAziende.isEmpty { d.clienti[i].aziende = [AziendeDiProva.bianchiSerramenti()] }
        let id = d.clienti[i].id
        if let p = d.posizioni.first(where: { $0.clienteId == id && $0.stato == .inEssere }) {
            d.clienti[i].aziende?[0].personaChiave?.posizioniCollegate = [p.id]
        }
        d.clienti[i].aziende?[0].tfm = StatoTFM(accantonato: true, importo: 45_000, nota: "Da rivedere a fine anno")
        if let j = d.clienti.indices.first(where: { $0 != i }) {
            d.clienti[j].aziende = [AziendeDiProva.morettiCostruzioni()]
        }
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaAziende(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        let conAziende = originale.clienti.filter { !$0.elencoAziende.isEmpty }
        guard conAziende.count >= 2,
              conAziende.contains(where: { $0.elencoAziende.contains { $0.fatturato == nil && $0.forma == nil } }),
              conAziende.contains(where: { $0.elencoAziende.contains { $0.tfm?.accantonato == true && $0.welfare != nil } }) else {
            return "l'archivio di prova non ha un'azienda completa e una con il solo nome"
        }
        guard estratto.clienti.map(\.aziende) == originale.clienti.map(\.aziende) else {
            return "le aziende dei clienti non tornano uguali dal backup"
        }
        // 2. Un archivio senza aziende si apre con nessuna azienda e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var clienti = radice["clienti"] as? [[String: Any]] else {
            return "archivio di prova senza le aziende non preparato"
        }
        let originaliJSON = clienti
        for i in clienti.indices { clienti[i].removeValue(forKey: "aziende") }
        radice["clienti"] = clienti
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.clienti.allSatisfy({ $0.aziende == nil }), letto.clienti.count == originale.clienti.count,
              letto.clienti.map(\.famiglia) == atteso.clienti.map(\.famiglia), letto.posizioni == atteso.posizioni else {
            return "archivio senza le aziende non letto correttamente (attese nessuna azienda, il resto uguale)"
        }
        // 3. Un'azienda senza id si scarta, le altre restano; i campi illeggibili diventano «non indicati»
        guard let i = originaliJSON.firstIndex(where: { ($0["aziende"] as? [[String: Any]])?.first?["welfare"] != nil }),
              var azienda = (originaliJSON[i]["aziende"] as? [[String: Any]])?.first else {
            return "azienda di prova non codificata"
        }
        azienda["forma"] = "cooperativa di un Prisma più nuovo"
        azienda["quota"] = 140
        azienda["dipendenti"] = "tanti"
        if var welfare = azienda["welfare"] as? [String: Any] {
            welfare["voci"] = [["id": "senza-titolo"], ["id": "buona", "titolo": "Buoni pasto", "fatta": true]] as [Any]
            azienda["welfare"] = welfare
        }
        var strani = originaliJSON
        strani[i]["aziende"] = [["ragioneSociale": "Senza id"], 7, azienda] as [Any]
        radice["clienti"] = strani
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard illeggibile.clienti.count == originale.clienti.count, let a = illeggibile.clienti[i].aziende, a.count == 1,
              let buona = a.first else {
            return "aziende illeggibili: archivio non aperto tenendo solo l'azienda buona (lette \(illeggibile.clienti[i].aziende?.count ?? 0))"
        }
        guard buona.forma == nil, buona.quota == nil, buona.dipendenti == nil,
              buona.welfare?.voci.map(\.titolo) == ["Buoni pasto"],
              buona.ragioneSociale == originale.clienti[i].elencoAziende.first?.ragioneSociale,
              buona.fatturato == originale.clienti[i].elencoAziende.first?.fatturato else {
            return "aziende illeggibili: campi illeggibili non tornati «non indicati» o campi leggibili persi"
        }
        // 4. Le aziende stanno nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale >= 27 else {
            return "le aziende chiedono almeno la versione 27 dell'archivio"
        }
        return nil
    }
}
