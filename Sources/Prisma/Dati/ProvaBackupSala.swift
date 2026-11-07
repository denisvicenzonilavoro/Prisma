import Foundation

// La Sala (versione 27, «Luce» giro 4) dentro `Prisma --prova-backup`: la giornata della pensione nell'Analisi 360 e
// le partite del gioco del rischio salvate nel dossier tornano uguali dal backup; un archivio senza i campi nuovi si apre
// senza giornate e senza partite; una partita o una voce rovinata si scarta e le altre restano; le partite non entrano
// nell'istantanea di «Prisma ovunque» (decisione 44).

extension ProvaBackup {
    /// Porta nell'archivio di prova una giornata compilata (dati di prova più una scena aggiunta) e due partite.
    static func aggiungiSalaDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        // Date a secondi interi, come le altre dell'archivio di prova
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        var a = d.analisi[c.id] ?? Analisi360(cliente: c, posizioni: d.posizioni.filter { $0.clienteId == c.id })
        var g = MotoreGiornataPensione.giornataDiProva()
        g.voci.append(VoceGiornata(id: "scena-backup", quando: "Domenica", titolo: "Il pranzo dai figli", frase: "una volta al mese",
                                   importoMensile: 40, glifo: GlifoScena.sole.rawValue, priorita: 5, daConfermare: true))
        g.aggiornataIl = t
        a.giornata = g
        a.confermate = [.previdenza]
        d.analisi[c.id] = a
        let versione = MotoreGiocoRischio.caricati?.versione ?? "prova"
        d.partiteRischio = [
            PartitaRischio(id: "partita-backup-1", clienteId: c.id, data: t, versioneScenari: versione,
                           risposte: [RispostaRischio(scenario: "calo", scelta: 1, secondi: 1.5),
                                      RispostaRischio(scenario: "risalita", scelta: 1, secondi: 2.25),
                                      RispostaRischio(scenario: "strade", scelta: 2, secondi: 0.75)],
                           vistaDalConsulenteIl: t.addingTimeInterval(60)),
            PartitaRischio(id: "partita-backup-2", clienteId: c.id, data: t.addingTimeInterval(86_400), versioneScenari: versione,
                           risposte: [RispostaRischio(scenario: "calo", scelta: 0, secondi: 3)])
        ]
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaSala(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.partiteRischio.count == 2, let id = originale.clienti.first?.id,
              originale.analisi[id]?.giornata?.voci.count == 6 else {
            return "l'archivio di prova non ha la giornata della pensione o le partite del gioco del rischio"
        }
        guard estratto.partiteRischio == originale.partiteRischio, estratto.analisi == originale.analisi else {
            return "giornata della pensione o partite del gioco del rischio non tornano uguali dal backup"
        }
        guard let g = estratto.analisi[id]?.giornata, g.voci.last?.daConfermare == true, g.diProva == true,
              g.voci.first(where: \.fissa)?.importoMensile == 1_250,
              estratto.partiteRischio.first?.risposte.map(\.secondi) == [1.5, 2.25, 0.75] else {
            return "voci, importi o tempi di decisione persi nel backup"
        }
        // 2. Un archivio senza i campi del giro 4 si apre senza giornate e senza partite, con il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "partiteRischio") != nil,
              var analisi = radice["analisi"] as? [String: Any],
              var delCliente = analisi[id] as? [String: Any],
              delCliente.removeValue(forKey: "giornata") != nil else {
            return "archivio di prova senza i campi della Sala non preparato"
        }
        analisi[id] = delCliente
        radice["analisi"] = analisi
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.partiteRischio.isEmpty, letto.analisi[id]?.giornata == nil,
              letto.analisi[id]?.confermate == atteso.analisi[id]?.confermate,
              letto.clienti.count == originale.clienti.count, letto.posizioni == atteso.posizioni,
              letto.pratiche == atteso.pratiche else {
            return "archivio senza la Sala non letto correttamente (attese nessuna giornata e nessuna partita, il resto uguale)"
        }
        // 3. Una partita rovinata si scarta, le altre restano; una voce senza id si scarta; una giornata illeggibile non
        //    fa perdere l'analisi
        guard let buona = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode([originale.partiteRischio[0]])) as? [[String: Any]])?.first else {
            return "partita di prova non codificata"
        }
        radice["partiteRischio"] = [["clienteId": "senza-id"], "rovinata", 7, buona] as [Any]
        delCliente["giornata"] = ["voci": [["titolo": "senza id"], ["id": "x", "importoMensile": 50, "fissa": true]]] as [String: Any]
        analisi[id] = delCliente
        radice["analisi"] = analisi
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.partiteRischio.map(\.id) == ["partita-backup-1"],
              rovinato.analisi[id]?.giornata?.voci.map(\.id) == ["x"],
              rovinato.clienti.count == originale.clienti.count else {
            return "partite o voci rovinate: archivio non aperto tenendo solo quelle buone"
        }
        delCliente["giornata"] = "illeggibile"
        analisi[id] = delCliente
        radice["analisi"] = analisi
        let senzaGiornata = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard senzaGiornata.analisi[id]?.giornata == nil, senzaGiornata.analisi[id]?.confermate == [.previdenza] else {
            return "una giornata illeggibile fa perdere l'Analisi 360 del cliente"
        }
        // 4. Le partite restano sul Mac: non entrano nell'istantanea di «Prisma ovunque»; la giornata sì (è nell'analisi)
        let ist = SpazioOvunque.datiIstantanea(originale)
        guard ist.partiteRischio.isEmpty, ist.analisi[id]?.giornata != nil else {
            return "le partite del gioco del rischio non devono entrare nell'istantanea di Prisma ovunque"
        }
        // 5. I campi stanno nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale == 27 else {
            return "giornata e partite stanno nella versione 27 dell'archivio di Luce"
        }
        return nil
    }
}
