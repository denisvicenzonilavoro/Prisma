import Foundation

// Gli eventi della linea della vita e il risparmio annuo libero del profilo (versione 26, «Orizzonte», giro 4) dentro
// `Prisma --prova-backup`: tornano uguali dal backup, un archivio senza i campi nuovi si apre con gli eventi vuoti
// e il resto uguale, un evento illeggibile si scarta da solo, tipo e origine sconosciuti tornano «altro» e «manuale».

extension ProvaBackup {
    /// Tre eventi di prova: uno per età con importo e durata, uno per anno dal copilota, uno senza cifra.
    static func eventiVitaDiProva(clienteId: String) -> [EventoLineaVita] {
        var figlio = EventoLineaVita(clienteId: clienteId, tipo: .figlio, eta: 41, importo: -4_000, durataAnni: 22,
                                     titolo: "Un figlio", nota: "Nota di prova")
        figlio.id = "vita-prova-figlio"
        var eredita = EventoLineaVita(clienteId: clienteId, tipo: .eredita, anno: 2040, importo: 80_000, origine: .copilota)
        eredita.id = "vita-prova-eredita"
        var sabbatico = EventoLineaVita(clienteId: clienteId, tipo: .annoSabbatico, eta: 50)
        sabbatico.id = "vita-prova-sabbatico"
        return [figlio, eredita, sabbatico]
    }

    /// Controlla eventi e risparmio libero dopo il ripristino e la lettura di un archivio senza.
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaEventiVita(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.eventiVita.count == 3, let cid = originale.eventiVita.first?.clienteId,
              originale.clienti.first(where: { $0.id == cid })?.profilo.risparmioAnnuo == 6_000 else {
            return "l'archivio di prova non ha eventi della linea della vita né risparmio libero"
        }
        guard estratto.eventiVita == originale.eventiVita,
              let figlio = estratto.eventiVita.first(where: { $0.id == "vita-prova-figlio" }),
              figlio.importo == -4_000, figlio.durataAnni == 22, figlio.eta == 41, figlio.titolo == "Un figlio", figlio.origine == .manuale,
              let eredita = estratto.eventiVita.first(where: { $0.id == "vita-prova-eredita" }),
              eredita.anno == 2040, eredita.eta == nil, eredita.origine == .copilota, eredita.importo == 80_000,
              estratto.eventiVita.first(where: { $0.id == "vita-prova-sabbatico" })?.importo == nil,
              estratto.clienti.first(where: { $0.id == cid })?.profilo.risparmioAnnuo == 6_000 else {
            return "gli eventi della linea della vita o il risparmio libero non tornano uguali dal backup"
        }
        // 2. Un archivio senza i campi nuovi del giro 4 si apre con gli eventi vuoti e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              radice.removeValue(forKey: "eventiVita") != nil,
              var clienti = radice["clienti"] as? [[String: Any]],
              let i = clienti.firstIndex(where: { ($0["id"] as? String) == cid }),
              var profilo = clienti[i]["profilo"] as? [String: Any],
              profilo.removeValue(forKey: "risparmioAnnuo") != nil else {
            return "archivio di prova senza eventi della linea della vita non preparato"
        }
        clienti[i]["profilo"] = profilo
        radice["clienti"] = clienti
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.eventiVita.isEmpty, letto.clienti.first(where: { $0.id == cid })?.profilo.risparmioAnnuo == nil,
              letto.clienti.count == atteso.clienti.count, letto.posizioni == atteso.posizioni, letto.obiettivi == atteso.obiettivi,
              letto.messaggi == atteso.messaggi, letto.impostazioni == atteso.impostazioni else {
            return "archivio senza eventi della linea della vita non letto correttamente (attesi vuoti)"
        }
        // 3. Un evento illeggibile si scarta, gli altri restano; tipo e origine sconosciuti tornano al predefinito
        guard let primo = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.eventiVita)) as? [[String: Any]])?.first else {
            return "evento di prova non codificato"
        }
        var strano = primo
        strano["tipo"] = "viaggio sulla luna"
        strano["origine"] = "telepatia"
        strano["durataAnni"] = "tanti"
        radice["eventiVita"] = [["id": "senza-cliente", "tipo": "casa"], 7, "non è un evento", strano] as [Any]
        let illeggibile = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard illeggibile.eventiVita.count == 1, let e = illeggibile.eventiVita.first, e.tipo == .altro, e.origine == .manuale,
              e.durataAnni == nil, e.importo == -4_000, e.id == "vita-prova-figlio",
              illeggibile.clienti.count == originale.clienti.count else {
            return "eventi della linea della vita illeggibili: archivio non aperto tenendo solo quelli buoni"
        }
        // 4. La versione dell'archivio resta la 26
        guard DatiPrisma.versioneAttuale >= 26 else {
            return "gli eventi della linea della vita chiedono almeno la versione 26 dell'archivio"
        }
        return nil
    }
}
