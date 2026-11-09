import Foundation

// Lo Smontaggio (versione 27, «Luce» §8.2.5 punto 5) dentro `Prisma --prova-backup`: un documento entrato nel dossier
// dallo Smontaggio torna dal backup con le sue voci di costo (`Documento.costiTrovati`) uguali; un archivio senza la
// chiave nuova si apre con le voci a nil; una voce rovinata non fa perdere le altre né il documento.

extension ProvaBackup {
    static let idDocumentoSmontaggioDiProva = "doc-smontaggio-prova"

    /// DATI DI PROVA: l'estratto conto fac-simile del primo cliente con due voci (una scritta, una calcolata da Prisma).
    static func aggiungiSmontaggioDiProva(_ d: inout DatiPrisma) {
        guard let c = d.clienti.first else { return }
        var doc = Documento(clienteId: c.id, titolo: "Fondo Esempio Globale · prova", tipo: .estrattoConto)
        doc.id = idDocumentoSmontaggioDiProva
        doc.importatoIl = Date(timeIntervalSinceReferenceDate: 800_000_600)
        doc.lettura = .letto
        doc.costiTrovati = [
            VoceCostoTrovata(tipo: .gestione, etichetta: "Commissione di gestione", valoreScritto: "2,10% l'anno", euroAnno: 1_834.35,
                             euroUnaVolta: nil, finoAl: nil, fonte: .calcolata, riga: 3, riquadro: nil,
                             conto: "2,10% × 87.350 € = 1.834 €", motivoMancante: nil),
            VoceCostoTrovata(tipo: .uscita, etichetta: "Penale di rimborso", valoreScritto: "1,5% fino al 2028", euroAnno: nil,
                             euroUnaVolta: 1_310.25, finoAl: 2_028, fonte: .calcolata, riga: 6,
                             riquadro: RiquadroPagina(x: 0.12, y: 0.41, larghezza: 0.5, altezza: 0.03), conto: nil, motivoMancante: nil)
        ]
        d.documenti.append(doc)
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaSmontaggio(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        guard let doc = originale.documenti.first(where: { $0.id == idDocumentoSmontaggioDiProva }), let voci = doc.costiTrovati,
              voci.count == 2 else {
            return "l'archivio di prova non ha il documento dello Smontaggio con le voci di costo"
        }
        guard let tornato = estratto.documenti.first(where: { $0.id == doc.id }), tornato.costiTrovati == voci else {
            return "le voci di costo dello Smontaggio non tornano uguali dal backup"
        }
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var documenti = radice["documenti"] as? [[String: Any]],
              let i = documenti.firstIndex(where: { ($0["id"] as? String) == doc.id }),
              var elenco = documenti[i]["costiTrovati"] as? [[String: Any]] else {
            return "archivio di prova senza le voci dello Smontaggio non preparato"
        }
        // Una voce rovinata: si salta, l'altra e il documento restano
        elenco[0]["tipo"] = "voce-sconosciuta"
        documenti[i]["costiTrovati"] = elenco
        radice["documenti"] = documenti
        let rovinato = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard let r = rovinato.documenti.first(where: { $0.id == doc.id }), r.costiTrovati == [voci[1]] else {
            return "una voce di costo rovinata fa perdere le altre o il documento"
        }
        // Un archivio di prima, senza la chiave: nessuna voce, il resto uguale
        documenti[i].removeValue(forKey: "costiTrovati")
        radice["documenti"] = documenti
        let vecchio = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        guard let v = vecchio.documenti.first(where: { $0.id == doc.id }), v.costiTrovati == nil, v.titolo == doc.titolo,
              vecchio.documenti.count == originale.documenti.count else {
            return "un archivio senza le voci dello Smontaggio non si legge (atteso il documento senza voci)"
        }
        guard DatiPrisma.versioneAttuale == 27 else {
            return "le voci dello Smontaggio stanno nella versione 27 dell'archivio di Luce"
        }
        return nil
    }
}
