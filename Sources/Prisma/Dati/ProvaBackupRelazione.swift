import Foundation

// La tua settimana e i traguardi festeggiati (versione 27, «Luce» giro 5) dentro `Prisma --prova-backup`: le
// impostazioni delle storie (apertura del lunedì, settimana e anno visti), quelle dei traguardi (tipi spenti,
// anniversari, festeggiati, scartati) e la data di raggiungimento di un obiettivo tornano uguali dal backup (il messaggio
// di un traguardo e la sua lettura tollerante sono provati in ProvaCalcoliTraguardi); un archivio senza i campi nuovi si apre con i valori di base; campi rovinati tornano ai valori di
// base senza perdere il resto.

extension ProvaBackup {
    /// Porta nell'archivio di prova i campi del giro 5, tutti diversi dai valori di base.
    static func aggiungiRelazioneDiProva(_ d: inout DatiPrisma) {
        // Date a secondi interi, come le altre dell'archivio di prova
        let t = Date(timeIntervalSinceReferenceDate: 815_000_000)
        d.impostazioni.storie.aperturaLunedi = true
        d.impostazioni.storie.ultimaSettimanaVista = t
        d.impostazioni.storie.ultimoAnnoVisto = 2026
        d.impostazioni.traguardi.tipiSpenti = [.mutuoEstinto]
        d.impostazioni.traguardi.anniversari = [1, 10]
        d.impostazioni.traguardi.festeggiati = ["obiettivoRaggiunto-sofia-backup": t]
        d.impostazioni.traguardi.scartati = ["anniversario-giulia-1anni"]
        if !d.obiettivi.isEmpty { d.obiettivi[0].raggiuntoIl = t }
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaRelazione(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.impostazioni.storie.aperturaLunedi, originale.impostazioni.traguardi.tipiSpenti == [.mutuoEstinto],
              originale.obiettivi.first?.raggiuntoIl != nil else {
            return "l'archivio di prova non ha le storie, i traguardi o l'obiettivo raggiunto di prova"
        }
        guard estratto.impostazioni.storie == originale.impostazioni.storie,
              estratto.impostazioni.traguardi == originale.impostazioni.traguardi,
              estratto.obiettivi.map(\.raggiuntoIl) == originale.obiettivi.map(\.raggiuntoIl) else {
            return "storie, traguardi o data dell'obiettivo raggiunto non tornano uguali dal backup"
        }
        // 2. Un archivio senza i campi del giro 5 si apre con i valori di base e il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "storie") != nil, impostazioni.removeValue(forKey: "traguardi") != nil,
              var obiettivi = radice["obiettivi"] as? [[String: Any]], !obiettivi.isEmpty,
              obiettivi[0].removeValue(forKey: "raggiuntoIl") != nil else {
            return "archivio di prova senza i campi delle storie e dei traguardi non preparato"
        }
        radice["impostazioni"] = impostazioni
        radice["obiettivi"] = obiettivi
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard letto.impostazioni.storie == ImpostazioniStorie(), letto.impostazioni.traguardi == ImpostazioniTraguardi(),
              !letto.impostazioni.storie.aperturaLunedi,
              letto.impostazioni.traguardi.anniversari == ImpostazioniTraguardi.anniversariPredefiniti,
              letto.obiettivi.count == originale.obiettivi.count, letto.obiettivi.first?.raggiuntoIl == nil,
              letto.clienti.count == originale.clienti.count, letto.pratiche == originale.pratiche else {
            return "archivio senza storie e traguardi non letto con i valori di base (apertura del lunedì spenta, decisione 128; 1-5-10-15-20 anni)"
        }
        // 3. Campi rovinati: tornano ai valori di base senza perdere il resto; un tipo sconosciuto si salta
        impostazioni["storie"] = ["aperturaLunedi": "sì", "ultimoAnnoVisto": "duemila"] as [String: Any]
        impostazioni["traguardi"] = ["tipiSpenti": ["mutuoEstinto", "tipoDelFuturo"], "anniversari": [0, -1, 5, 5],
                                     "festeggiati": "nessuno"] as [String: Any]
        obiettivi[0]["raggiuntoIl"] = "ieri"
        radice["impostazioni"] = impostazioni
        radice["obiettivi"] = obiettivi
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard !rovinato.impostazioni.storie.aperturaLunedi, rovinato.impostazioni.storie.ultimoAnnoVisto == nil,
              rovinato.impostazioni.traguardi.tipiSpenti == [.mutuoEstinto], rovinato.impostazioni.traguardi.anniversari == [5],
              rovinato.impostazioni.traguardi.festeggiati.isEmpty,
              rovinato.obiettivi.count == originale.obiettivi.count, rovinato.obiettivi.first?.raggiuntoIl == nil,
              rovinato.clienti.count == originale.clienti.count else {
            return "storie e traguardi rovinati: archivio non aperto con i valori di base (o obiettivo perso)"
        }
        // 4. I campi stanno nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale == 27 else {
            return "storie e traguardi stanno nella versione 27 dell'archivio di Luce"
        }
        return nil
    }
}
