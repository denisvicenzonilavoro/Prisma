import Foundation

// La fase 3 di Vera dentro `Prisma --prova-backup`: promesse, confronti tra documenti, coperture delle polizze e il
// resoconto di un incontro tornano uguali dal backup; un archivio senza i campi nuovi si apre con le liste vuote e
// l'incontro senza resoconto; una promessa rovinata si scarta e le altre restano; la trascrizione della nota vocale
// non entra nell'istantanea di «Prisma ovunque».

extension ProvaBackup {
    static func aggiungiFaseTreVeraDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first, let k = d.incontri.indices.first else { return }
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        var p = PromessaCliente(clienteId: c.id, testo: "Mandare il confronto", frase: "Le mando il confronto entro venerdì.", fonte: .nota,
                                fonteId: "nota-backup", fonteEtichetta: "dalla nota di prova", scadenza: t, quando: "entro venerdì")
        p.id = "promessa-backup-1"
        p.creataIl = t
        var q = PromessaCliente(clienteId: c.id, testo: "Richiamare", frase: "La richiamo dopo il 15.", fonte: .messaggio,
                                fonteId: "messaggio-backup", fonteEtichetta: "dal messaggio di prova")
        q.id = "promessa-backup-2"
        q.creataIl = t
        q.stato = .rimandata
        q.rimandataAl = t.addingTimeInterval(7 * 86_400)
        d.promesse = [p, q]
        d.confrontiDocumenti = [ConfrontoDocumenti(id: "confronto-backup", clienteId: c.id, primaId: "a", oraId: "b", titoloPrima: "Polizza", titoloOra: "Proposta",
                                                   righe: [RigaDifferenza(voce: "Premio", prima: "420 €", ora: "610 €", esito: .costaDiPiu, paginaPrima: 1, paginaOra: 1)],
                                                   sintesi: "Costa di più.", creatoIl: t)]
        d.coperture = [CoperturaPolizza(documentoId: "doc-backup", clienteId: c.id, titolo: "Infortuni (fac-simile)",
                                        voci: [LimiteCopertura(tipo: .esclusione, voce: "Sport agonistici", perCliente: "Le partite di campionato no.",
                                                               articolo: "3.1", pagina: 1, frase: "Sono esclusi gli sport agonistici.")],
                                        articoliLetti: 9, creataIl: t)]
        var r = ResocontoIncontro(titolo: d.incontri[k].titolo, sezioni: [SezioneResoconto(titolo: "Presenti", righe: [c.nome])], breve: ["Uno"], fonti: [.notaVocale],
                                  trascrizione: "Trascrizione di prova.")
        r.creatoIl = t
        d.incontri[k].resoconto = r
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaFaseTreVera(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard originale.promesse.count == 2, originale.coperture.count == 1, let k = originale.incontri.firstIndex(where: { $0.resoconto != nil }) else {
            return "l'archivio di prova non ha i dati della fase 3 di Vera"
        }
        guard estratto.promesse == originale.promesse, estratto.confrontiDocumenti == originale.confrontiDocumenti,
              estratto.coperture == originale.coperture, estratto.incontri[k].resoconto == originale.incontri[k].resoconto else {
            return "promesse, confronti, coperture o resoconto non tornano uguali dal backup"
        }
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any] else { return "archivio di prova non codificato" }
        for chiave in ["promesse", "confrontiDocumenti", "coperture"] { radice.removeValue(forKey: chiave) }
        if var incontri = radice["incontri"] as? [[String: Any]] {
            for i in incontri.indices { incontri[i].removeValue(forKey: "resoconto") }
            radice["incontri"] = incontri
        }
        let senza = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard senza.promesse.isEmpty, senza.confrontiDocumenti.isEmpty, senza.coperture.isEmpty, senza.incontri.allSatisfy({ $0.resoconto == nil }),
              senza.incontri.count == originale.incontri.count, senza.clienti.count == originale.clienti.count else {
            return "un archivio senza i dati della fase 3 di Vera non si apre con le liste vuote"
        }
        guard let buona = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode([originale.promesse[0]])) as? [[String: Any]])?.first else {
            return "promessa di prova non codificata"
        }
        radice["promesse"] = [["testo": "senza id"], "rovinata", buona] as [Any]
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.promesse.map(\.id) == ["promessa-backup-1"] else {
            return "una promessa rovinata fa perdere le altre"
        }
        var conNota = originale
        conNota.promesse.append(PromessaCliente(clienteId: originale.promesse[0].clienteId, testo: "Mandare il riepilogo", frase: "Le mando il riepilogo.",
                                                fonte: .resoconto, fonteId: "x-resoconto", fonteEtichetta: "dalla nota vocale del 2 novembre"))
        let ist = SpazioOvunque.datiIstantanea(conNota)
        guard ist.incontri[k].resoconto == nil, ist.promesse.last?.frase == "", ist.promesse.last?.testo == "Mandare il riepilogo",
              ist.promesse.first?.frase == originale.promesse[0].frase else {
            return "la nota vocale (trascrizione, resoconto non firmato, frasi delle promesse) non deve entrare nell'istantanea di Prisma ovunque"
        }
        var firmato = originale
        firmato.incontri[k].resoconto?.firmatoIl = Date(timeIntervalSinceReferenceDate: 800_000_000)
        guard SpazioOvunque.datiIstantanea(firmato).incontri[k].resoconto?.breve == ["Uno"],
              SpazioOvunque.datiIstantanea(firmato).incontri[k].resoconto?.trascrizione == nil else {
            return "un resoconto firmato entra nell'istantanea senza la trascrizione"
        }
        return nil
    }
}
