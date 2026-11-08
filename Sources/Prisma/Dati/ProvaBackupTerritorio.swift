import Foundation

// «Luce», giro 11 (Territorio, versione 27) dentro `Prisma --prova-backup`: la posizione a mano del cliente
// (`Cliente.luogo`), l'appuntamento proposto dal Territorio da confermare (`Appuntamento.daConfermare`) e le impostazioni
// del Territorio (`Impostazioni.territorio`) tornano uguali dal backup; un archivio senza i campi nuovi si apre senza, con
// il resto uguale; la lettura è tollerante (coordinata fuori scala, numeri fuori scala, zona senza id, tipo di attenzione
// sconosciuto, booleano di tipo sbagliato). Le tabelle dei comuni e dei confini sono risorse, non archivio.

extension ProvaBackup {
    /// DATI DI PROVA: una posizione a mano per il primo cliente, un appuntamento da confermare e impostazioni del
    /// Territorio diverse da quelle di base (fattore, velocità, una zona, un'attenzione «alta», il comune di partenza).
    static func aggiungiTerritorioDiProva(_ d: inout DatiPrisma) {
        guard !d.clienti.isEmpty else { return }
        d.clienti[0].luogo = LuogoManuale(coordinata: Coordinata(lat: 44.5, lon: 11.35), nota: "Posizione di prova")
        if let i = d.appuntamenti.indices.first {
            d.appuntamenti[i].daConfermare = true
        }
        var t = ImpostazioniTerritorio()
        t.fattoreStrada = 1.4
        t.velocitaCitta = 35
        t.velocitaFuori = 80
        t.zone = [ZonaTerritorio(id: "zona-prova", nome: "Zona di prova", comuni: ["BO-bologna", "MO-modena"])]
        t.attenzioniAlte = [2]
        t.comunePartenza = "BO-bologna"
        d.impostazioni.territorio = t
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaTerritorio(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.clienti.first?.luogo != nil, originale.appuntamenti.contains(where: { $0.daConfermare == true }),
              originale.impostazioni.territorio.zone.count == 1 else {
            return "l'archivio di prova non ha la posizione a mano, l'appuntamento da confermare o le impostazioni del Territorio"
        }
        guard estratto.clienti.map(\.luogo) == originale.clienti.map(\.luogo),
              estratto.appuntamenti.map(\.daConfermare) == originale.appuntamenti.map(\.daConfermare),
              estratto.impostazioni.territorio == originale.impostazioni.territorio else {
            return "posizione a mano, appuntamento da confermare o impostazioni del Territorio non tornano uguali dal backup"
        }
        // 2. Un archivio senza i campi del giro 11 si apre senza, con il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var clienti = radice["clienti"] as? [[String: Any]], !clienti.isEmpty,
              var appuntamenti = radice["appuntamenti"] as? [[String: Any]], !appuntamenti.isEmpty,
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "territorio") != nil,
              clienti[0].removeValue(forKey: "luogo") != nil else {
            return "archivio di prova senza i campi del giro 11 non preparato"
        }
        for i in appuntamenti.indices { appuntamenti[i].removeValue(forKey: "daConfermare") }
        radice["clienti"] = clienti
        radice["appuntamenti"] = appuntamenti
        radice["impostazioni"] = impostazioni
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard letto.clienti.allSatisfy({ $0.luogo == nil }), letto.appuntamenti.allSatisfy({ $0.daConfermare == nil }),
              letto.impostazioni.territorio == ImpostazioniTerritorio(), letto.clienti.count == originale.clienti.count,
              letto.appuntamenti.count == originale.appuntamenti.count,
              letto.clienti.map(\.nome) == originale.clienti.map(\.nome) else {
            return "archivio senza i campi del giro 11 non letto correttamente (attesi nessun luogo, appuntamenti confermati, Territorio di base)"
        }
        // 3. Lettura tollerante
        clienti[0]["luogo"] = ["coordinata": ["lat": 500, "lon": 11], "nota": "fuori scala"]
        appuntamenti[0]["daConfermare"] = "sì"
        var territorio = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.impostazioni.territorio)) as? [String: Any]) ?? [:]
        guard let zone = territorio["zone"] as? [Any], zone.count == 1 else { return "impostazioni del Territorio di prova non codificate" }
        territorio["fattoreStrada"] = -1
        territorio["velocitaCitta"] = 0
        territorio["zone"] = [["nome": "senza id", "comuni": []], "rovinata", zone[0]] as [Any]
        territorio["attenzioniAlte"] = [2, 99]
        impostazioni["territorio"] = territorio
        radice["clienti"] = clienti
        radice["appuntamenti"] = appuntamenti
        radice["impostazioni"] = impostazioni
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let t = rovinato.impostazioni.territorio
        guard rovinato.clienti.first?.luogo == nil, rovinato.appuntamenti.first?.daConfermare == nil,
              rovinato.appuntamenti.count == originale.appuntamenti.count,
              t.fattoreStrada == ImpostazioniTerritorio.fattorePredefinito,
              t.velocitaCitta == ImpostazioniTerritorio.velocitaCittaPredefinita,
              t.velocitaFuori == 80, t.zone.map(\.id) == ["zona-prova"], t.attenzioniAlte == [2],
              t.comunePartenza == "BO-bologna" else {
            return "Territorio: valori rovinati non letti con tolleranza (luogo fuori scala, fattore, velocità, zone, attenzioni, daConfermare)"
        }
        // 4. La posizione a mano e le impostazioni del Territorio entrano nell'istantanea di «Prisma ovunque» (decisione 44)
        let ist = SpazioOvunque.datiIstantanea(originale)
        guard ist.clienti.first?.luogo == originale.clienti.first?.luogo,
              ist.impostazioni.territorio == originale.impostazioni.territorio else {
            return "la posizione a mano o le impostazioni del Territorio non entrano nell'istantanea di Prisma ovunque"
        }
        // 5. I campi stanno nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale == 27 else { return "i campi del giro 11 stanno nella versione 27 dell'archivio di Luce" }
        return nil
    }
}
