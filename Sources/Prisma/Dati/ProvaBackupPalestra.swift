import Foundation

// Il registro della palestra della trattativa (versione 27, «Luce» giro 5) dentro `Prisma --prova-backup`: gli esiti
// degli allenamenti (data, cliente, difficoltà, punteggio) tornano uguali dal backup; un archivio senza il campo si apre
// senza allenamenti; un esito rovinato si scarta e gli altri restano; una difficoltà sconosciuta vale «Realistica» e un
// punteggio fuori scala torna fra 0 e 100. Le conversazioni non ci sono mai.

extension ProvaBackup {
    /// Porta nell'archivio di prova tre allenamenti: con un cliente, con un profilo inventato e uno difficile.
    static func aggiungiPalestraDiProva(_ d: inout DatiPrisma) {
        // Date a secondi interi, come le altre dell'archivio di prova
        let t = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let cliente = d.clienti.first?.id
        var p = ImpostazioniPalestra()
        p.registra(EsitoPalestra(data: t, clienteId: cliente, difficolta: .facile, punteggio: 78))
        p.registra(EsitoPalestra(data: t.addingTimeInterval(86_400), clienteId: nil, difficolta: .realistica, punteggio: 56))
        p.registra(EsitoPalestra(data: t.addingTimeInterval(2 * 86_400), clienteId: cliente, difficolta: .difficile, punteggio: 33))
        d.impostazioni.palestra = p
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaPalestra(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.impostazioni.palestra.allenamenti.count == 3 else {
            return "l'archivio di prova non ha gli allenamenti della palestra"
        }
        guard estratto.impostazioni.palestra == originale.impostazioni.palestra,
              estratto.impostazioni.palestra.allenamenti.map(\.difficolta) == [.facile, .realistica, .difficile],
              estratto.impostazioni.palestra.allenamenti[1].clienteId == nil else {
            return "gli allenamenti della palestra non tornano uguali dal backup"
        }
        // 2. Un archivio senza il campo del giro 5 si apre senza allenamenti e con il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var impostazioni = radice["impostazioni"] as? [String: Any],
              var palestra = impostazioni.removeValue(forKey: "palestra") as? [String: Any] else {
            return "archivio di prova senza la palestra non preparato"
        }
        radice["impostazioni"] = impostazioni
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.impostazioni.palestra.allenamenti.isEmpty, letto.clienti.count == originale.clienti.count,
              letto.impostazioni.pratiche == atteso.impostazioni.pratiche, letto.posizioni == atteso.posizioni else {
            return "archivio senza la palestra non letto correttamente (atteso nessun allenamento, il resto uguale)"
        }
        // 3. Un esito rovinato si scarta, gli altri restano; difficoltà sconosciuta e punteggio fuori scala si sistemano
        guard var buono = (palestra["allenamenti"] as? [[String: Any]])?.first else {
            return "allenamento di prova non codificato"
        }
        buono["difficolta"] = "impossibile"
        buono["punteggio"] = 250
        palestra["allenamenti"] = [["data": "ieri"], "rovinato", 7, buono] as [Any]
        impostazioni["palestra"] = palestra
        radice["impostazioni"] = impostazioni
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.impostazioni.palestra.allenamenti.count == 1, let r = rovinato.impostazioni.palestra.allenamenti.first,
              r.difficolta == .realistica, r.punteggio == 100, rovinato.clienti.count == originale.clienti.count else {
            return "allenamenti rovinati: archivio non aperto tenendo solo quelli buoni (o difficoltà e punteggio non sistemati)"
        }
        // 4. Nessuna conversazione nel registro e il campo sta nella versione 27 dell'archivio di Luce
        let testo = String(data: codificato, encoding: .utf8) ?? ""
        guard !testo.contains("\"obiezione\""), !testo.contains("\"replica\""), DatiPrisma.versioneAttuale == 27 else {
            return "il registro della palestra non deve contenere le conversazioni (versione 27 dell'archivio di Luce)"
        }
        return nil
    }
}
