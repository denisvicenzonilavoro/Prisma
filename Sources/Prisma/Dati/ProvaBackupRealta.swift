import Foundation

// La realtà aumentata (versione 27, «Luce» giro 16) dentro `Prisma --prova-backup`: lo scatto nei Documenti del cliente
// (`Documento.scattoRealta`) e l'interruttore «Lo scatto può comprendere la stanza» tornano uguali dal backup; un
// archivio senza le chiavi nuove si apre senza scatto e con l'interruttore spento; uno scatto rovinato o di un'origine
// sconosciuta non fa perdere il documento; lo scatto non entra nell'istantanea di «Prisma ovunque» (decisione 27).

extension ProvaBackup {
    static let titoloScattoDiProva = "Il cristallo · prova"

    /// DATI DI PROVA: un documento-scatto del primo cliente (senza file, come i documenti di prova) e l'interruttore acceso.
    static func aggiungiRealtaDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        var doc = Documento(clienteId: c.id, titolo: titoloScattoDiProva, tipo: .report)
        doc.id = "doc-scatto-prova"
        // Date a secondi interi, come le altre dell'archivio di prova
        doc.importatoIl = Date(timeIntervalSinceReferenceDate: 800_000_000)
        doc.scattoRealta = ScattoRealta(anno: 2_030, esploso: true, conStanza: false, origine: .ipad)
        d.documenti.append(doc)
        d.impostazioni.sala.scattoConStanza = true
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaRealta(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali
        guard let scatto = originale.documenti.first(where: { $0.id == "doc-scatto-prova" }),
              scatto.scattoRealta != nil, originale.impostazioni.sala.scattoConStanza else {
            return "l'archivio di prova non ha lo scatto della realtà aumentata"
        }
        guard let tornato = estratto.documenti.first(where: { $0.id == scatto.id }), tornato.scattoRealta == scatto.scattoRealta,
              tornato.scattoRealta?.origine == .ipad, tornato.scattoRealta?.anno == 2_030,
              estratto.impostazioni.sala.scattoConStanza else {
            return "lo scatto della realtà aumentata o l'interruttore della stanza non tornano uguali dal backup"
        }
        // 2. Un archivio senza le chiavi nuove: niente scatto, interruttore spento, il resto uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var documenti = radice["documenti"] as? [[String: Any]],
              let i = documenti.firstIndex(where: { ($0["id"] as? String) == scatto.id }),
              var impostazioni = radice["impostazioni"] as? [String: Any],
              var sala = impostazioni["sala"] as? [String: Any] else {
            return "archivio di prova senza i campi della realtà aumentata non preparato"
        }
        documenti[i].removeValue(forKey: "scattoRealta")
        sala.removeValue(forKey: "scattoConStanza")
        impostazioni["sala"] = sala
        radice["impostazioni"] = impostazioni
        radice["documenti"] = documenti
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard letto.documenti.first(where: { $0.id == scatto.id })?.scattoRealta == nil,
              letto.documenti.count == atteso.documenti.count, !letto.impostazioni.sala.scattoConStanza,
              letto.impostazioni.sala.eventiAnno == atteso.impostazioni.sala.eventiAnno,
              letto.clienti.count == originale.clienti.count, letto.posizioni == atteso.posizioni else {
            return "archivio senza la realtà aumentata non letto correttamente (atteso nessuno scatto e l'interruttore spento)"
        }
        // 3. Uno scatto rovinato e un'origine sconosciuta non fanno perdere il documento
        documenti[i]["scattoRealta"] = ["anno": "x"]
        radice["documenti"] = documenti
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard let r = rovinato.documenti.first(where: { $0.id == scatto.id }), r.scattoRealta == nil,
              r.titolo == titoloScattoDiProva else {
            return "uno scatto rovinato fa perdere il documento"
        }
        documenti[i]["scattoRealta"] = ["anno": 2_031, "esploso": false, "conStanza": false, "origine": "visore"] as [String: Any]
        radice["documenti"] = documenti
        let sconosciuto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard sconosciuto.documenti.first(where: { $0.id == scatto.id })?.scattoRealta == ScattoRealta(anno: 2_031, esploso: false,
                                                                                                       conStanza: false, origine: .mac) else {
            return "uno scatto di un'origine sconosciuta fa perdere il documento o l'anno"
        }
        // 4. Lo scatto resta sul Mac: non entra nell'istantanea di «Prisma ovunque»
        let ist = SpazioOvunque.datiIstantanea(estratto)
        guard !ist.documenti.contains(where: { $0.scattoRealta != nil || $0.id == scatto.id }) else {
            return "lo scatto della realtà aumentata non deve entrare nell'istantanea di Prisma ovunque"
        }
        // 5. I campi stanno nella versione 27 dell'archivio di Luce
        guard DatiPrisma.versioneAttuale == 27 else {
            return "lo scatto e l'interruttore stanno nella versione 27 dell'archivio di Luce"
        }
        return nil
    }
}
