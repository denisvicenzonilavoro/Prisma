import Foundation

// «Luce», giro 8 («Sala: racconti senza uscita», versione 27) dentro `Prisma --prova-backup`: l'inizio del rapporto
// (`Cliente.clienteDal`), l'indennizzo stimato di una polizza (`Posizione.indennizzoStimato`) e le impostazioni della
// Sala (`Impostazioni.sala`: eventi di Lancia l'anno con probabilità e fonte, anni della partita, avvertenze e titolo del
// valore) tornano uguali dal backup; un archivio senza i campi nuovi si apre senza, con il resto uguale; un evento
// rovinato si scarta e gli altri restano, una probabilità fuori scala diventa «non scritta». L'inizio del rapporto entra
// nell'istantanea di «Prisma ovunque» con il cliente. Le lettere e le partite di Lancia l'anno non si salvano.

extension ProvaBackup {
    /// DATI DI PROVA: l'inizio del rapporto del primo cliente, l'indennizzo stimato di una sua posizione e le
    /// impostazioni della Sala con un evento scritto dall'utente (probabilità e fonte di prova).
    static func aggiungiRaccontiDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        // Date a secondi interi, come le altre dell'archivio di prova
        d.clienti[0].clienteDal = Date(timeIntervalSinceReferenceDate: 700_000_000)
        if let i = d.posizioni.firstIndex(where: { $0.clienteId == c.id }) { d.posizioni[i].indennizzoStimato = 9_000 }
        var sala = ImpostazioniSala()
        sala.eventiAnno = [
            EventoAnno(id: "caldaia", titolo: "La caldaia (di prova)", effetto: .spesa, importo: 8_500, tono: .arancio,
                       probabilita: 0.05, fonte: "Fonte di prova", etaMinima: 25, etaMassima: 80),
            EventoAnno(id: "evento-utente", titolo: "Un evento dell'utente", effetto: .mancatoReddito, mesi: 4,
                       rischio: .invalidita, tono: .rosso),
        ]
        sala.anniPartita = 0
        sala.avvertenzaLettera = "Avvertenza di prova della lettera."
        sala.avvertenzaValore = "Avvertenza di prova del valore."
        sala.titoloValore = "In {periodo} insieme: {valore} (testo di prova)."
        d.impostazioni.sala = sala
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaRacconti(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard originale.clienti.first?.clienteDal != nil, originale.posizioni.contains(where: { $0.indennizzoStimato == 9_000 }),
              originale.impostazioni.sala.eventiAnno.count == 2 else {
            return "l'archivio di prova non ha l'inizio del rapporto, l'indennizzo stimato o le impostazioni della Sala"
        }
        guard estratto.clienti.map(\.clienteDal) == originale.clienti.map(\.clienteDal),
              estratto.posizioni.map(\.indennizzoStimato) == originale.posizioni.map(\.indennizzoStimato),
              estratto.impostazioni.sala == originale.impostazioni.sala else {
            return "inizio del rapporto, indennizzo stimato o impostazioni della Sala non tornano uguali dal backup"
        }
        guard let e = estratto.impostazioni.sala.eventiAnno.first, e.probabilita == 0.05, e.fonte == "Fonte di prova", e.esceACaso,
              estratto.impostazioni.sala.anniPartita == 0 else {
            return "probabilità, fonte o anni della partita persi nel backup"
        }
        // 2. Un archivio senza i campi del giro 8 si apre senza, con il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var clienti = radice["clienti"] as? [[String: Any]], !clienti.isEmpty,
              var posizioni = radice["posizioni"] as? [[String: Any]],
              var impostazioni = radice["impostazioni"] as? [String: Any],
              impostazioni.removeValue(forKey: "sala") != nil,
              clienti[0].removeValue(forKey: "clienteDal") != nil else {
            return "archivio di prova senza i campi del giro 8 non preparato"
        }
        for i in posizioni.indices { posizioni[i].removeValue(forKey: "indennizzoStimato") }
        radice["clienti"] = clienti
        radice["posizioni"] = posizioni
        radice["impostazioni"] = impostazioni
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard letto.clienti.allSatisfy({ $0.clienteDal == nil }), letto.posizioni.allSatisfy({ $0.indennizzoStimato == nil }),
              letto.impostazioni.sala == ImpostazioniSala(), letto.clienti.count == originale.clienti.count,
              letto.posizioni.count == originale.posizioni.count else {
            return "archivio senza i campi del giro 8 non letto correttamente (attesi nessun inizio, nessun indennizzo, Sala vuota)"
        }
        // 3. Un evento rovinato si scarta, gli altri restano; una probabilità fuori scala non vale; anni fuori scala no
        var sala = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(originale.impostazioni.sala)) as? [String: Any]) ?? [:]
        var eventi = sala["eventiAnno"] as? [[String: Any]] ?? []
        guard eventi.count == 2 else { return "impostazioni della Sala di prova non codificate" }
        eventi[1]["probabilita"] = 7
        sala["eventiAnno"] = [["titolo": "senza id"], "rovinato", eventi[0], eventi[1]] as [Any]
        sala["anniPartita"] = 500
        impostazioni["sala"] = sala
        radice["impostazioni"] = impostazioni
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard rovinato.impostazioni.sala.eventiAnno.map(\.id) == ["caldaia", "evento-utente"],
              rovinato.impostazioni.sala.eventiAnno[1].probabilita == nil, rovinato.impostazioni.sala.anniPartita == nil,
              rovinato.impostazioni.sala.avvertenzaLettera == "Avvertenza di prova della lettera." else {
            return "eventi rovinati della Sala: archivio non aperto tenendo solo quelli buoni"
        }
        // 4. L'inizio del rapporto entra nell'istantanea di «Prisma ovunque» con il cliente (decisione 44)
        let ist = SpazioOvunque.datiIstantanea(originale)
        guard ist.clienti.first?.clienteDal == originale.clienti.first?.clienteDal else {
            return "l'inizio del rapporto non entra nell'istantanea di Prisma ovunque"
        }
        // 5. I campi stanno nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale == 27 else { return "i campi del giro 8 stanno nella versione 27 dell'archivio di Luce" }
        return nil
    }
}
