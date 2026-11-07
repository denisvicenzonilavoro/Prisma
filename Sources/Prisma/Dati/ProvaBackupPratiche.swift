import Foundation

// Le pratiche dopo la firma (versione 27, «Luce» giro 3) dentro `Prisma --prova-backup`: pratiche con passi segnati e
// tolti a mano, passi non pertinenti, note, conclusione e sollecito tornano uguali dal backup, con la soglia delle
// impostazioni; un archivio senza i campi nuovi si apre senza pratiche e con la soglia di 7 giorni; una pratica rovinata
// si scarta e le altre restano; un segno illeggibile si salta senza perdere la pratica.

extension ProvaBackup {
    /// Porta nell'archivio di prova una pratica completa di tutto (le quattro dei dati di prova ci sono già) e una
    /// soglia diversa da quella di base.
    static func aggiungiPraticheDiProva(_ d: inout DatiPrisma) {
        if d.pratiche.isEmpty { d.pratiche = PraticheDiProva.pratiche() }
        guard let pos = d.posizioni.first else { return }
        // Date a secondi interi, come le altre dell'archivio di prova
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        var p = Pratica(id: "pratica-backup", posizioneId: pos.id, apertaIl: t)
        p.passi[PassoPratica.moduli.rawValue] = SegnoPasso(fatto: true, il: t.addingTimeInterval(86_400))
        p.passi[PassoPratica.polizzaEmessa.rawValue] = SegnoPasso(fatto: false, il: t.addingTimeInterval(2 * 86_400),
                                                                 nota: "Il numero è del contratto precedente")
        p.nonPertinenti = [PassoPratica.primoPremio.rawValue]
        p.note = [NotaPratica(data: t.addingTimeInterval(3 * 86_400), testo: "Chiamata la sede per l'emissione")]
        p.conclusaIl = nil
        p.sollecitoOccasioneId = "pratica-\(pos.clienteId)-pratica-backup-documentiInformativi"
        d.pratiche.append(p)
        d.impostazioni.pratiche.giorniFerma = 10
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaPratiche(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.pratiche.count >= 5, originale.pratiche.contains(where: { $0.id == "pratica-backup" }),
              originale.pratiche.contains(where: { $0.conclusaIl != nil }), originale.impostazioni.pratiche.giorniFerma == 10 else {
            return "l'archivio di prova non ha le pratiche dopo la firma o la soglia di prova"
        }
        guard estratto.pratiche == originale.pratiche,
              estratto.impostazioni.pratiche == originale.impostazioni.pratiche else {
            return "pratiche dopo la firma o soglia delle pratiche non tornano uguali dal backup"
        }
        guard let b = estratto.pratiche.first(where: { $0.id == "pratica-backup" }),
              b.segno(.polizzaEmessa)?.fatto == false, b.segno(.moduli)?.fatto == true,
              b.nonPertinenti == [PassoPratica.primoPremio.rawValue], b.note?.count == 1, b.sollecitoOccasioneId != nil else {
            return "segni a mano, passi non pertinenti, note o sollecito della pratica persi nel backup"
        }
        // 2. Un archivio senza i campi del giro 3 si apre senza pratiche, con la soglia di 7 giorni e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "pratiche") != nil,
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "pratiche") != nil else {
            return "archivio di prova senza i campi delle pratiche non preparato"
        }
        radice["impostazioni"] = impostazioni
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.pratiche.isEmpty, letto.impostazioni.pratiche.giorniFerma == 7,
              letto.clienti.count == originale.clienti.count, letto.posizioni == atteso.posizioni,
              letto.messaggi == atteso.messaggi, letto.portafogliModello == atteso.portafogliModello else {
            return "archivio senza le pratiche non letto correttamente (attese vuote e soglia 7, il resto uguale)"
        }
        // 3. Una pratica rovinata si scarta, le altre restano; un segno illeggibile si salta; una soglia assurda torna 7
        guard var buona = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode([b])) as? [[String: Any]])?.first else {
            return "pratica di prova non codificata"
        }
        buona["passi"] = ["moduli": ["fatto": true, "il": "ieri"], "consegnata": ["fatto": true, "il": "2026-05-10T12:00:00Z"],
                          "passoDelFuturo": ["fatto": true, "il": "2026-05-10T12:00:00Z"]] as [String: Any]
        buona["note"] = [["testo": "senza data"], ["data": "2026-05-10T12:00:00Z", "testo": "buona"]]
        radice["pratiche"] = [["posizioneId": "senza-id"], "rovinata", 12, buona] as [Any]
        impostazioni["pratiche"] = ["giorniFerma": 0]
        radice["impostazioni"] = impostazioni
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.pratiche.count == 1, let r = rovinato.pratiche.first, r.id == "pratica-backup",
              r.segno(.moduli) == nil, r.segno(.consegnata)?.fatto == true, r.passi["passoDelFuturo"] != nil,
              r.note?.count == 1, rovinato.impostazioni.pratiche.giorniFerma == 7,
              rovinato.clienti.count == originale.clienti.count else {
            return "pratiche rovinate: archivio non aperto tenendo solo quelle buone (o soglia 0 non tornata a 7)"
        }
        // 4. Il campo sta nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale == 27 else {
            return "le pratiche stanno nella versione 27 dell'archivio di Luce"
        }
        return nil
    }
}
