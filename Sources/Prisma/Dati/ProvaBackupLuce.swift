import Foundation

// «Luce», giro 1 (versione 27 dell'archivio) dentro `Prisma --prova-backup`: gli spazi di lavoro con le quattro app nuove
// (Territorio, Pratiche, Sala, Biblioteca) tornano uguali dal backup, e un archivio con un'app che questo Prisma non
// conosce (come lo leggerebbe un iPhone non ancora aggiornato) si apre lo stesso: la finestra sconosciuta si salta, lo
// spazio resta con le altre, uno spazio fatto solo di app sconosciute si toglie e gli altri restano (decisione 104).

extension ProvaBackup {
    /// Lo spazio di prova con le quattro app di Luce.
    static func spazioLuceDiProva() -> SpazioLavoro {
        SpazioLavoro(id: "spazio-luce-prova", nome: "Sala con il cliente",
                     finestre: [.sinistra(.territorio), .destra(.pratiche), .sinistra(.biblioteca), .intera(.sala)])
    }

    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func verificaLuce(originale: DatiPrisma, estratto: DatiPrisma) throws -> String? {
        // 1. Dal backup tornano uguali, con le novità viste di Luce
        guard let spazio = originale.spazi.first(where: { $0.id == "spazio-luce-prova" }),
              Set(spazio.app) == Set<AppPrisma>([.territorio, .pratiche, .biblioteca, .sala]) else {
            return "Luce: l'archivio di prova non ha lo spazio con le quattro app nuove"
        }
        guard estratto.spazi == originale.spazi,
              estratto.impostazioni.novitaViste == NovitaLuce.versione else {
            return "Luce: gli spazi con le app nuove o le novità viste «luce» non tornano uguali dal backup"
        }
        // 2. Un'app sconosciuta: la finestra si salta, lo spazio resta con le altre; uno spazio di sole app sconosciute
        //    si toglie, gli altri restano; il resto dell'archivio è uguale
        let codificato = try Archivio.codificatore.encode(originale)
        guard var radice = try JSONSerialization.jsonObject(with: codificato) as? [String: Any],
              var spazi = radice["spazi"] as? [[String: Any]],
              let i = spazi.firstIndex(where: { ($0["id"] as? String) == "spazio-luce-prova" }),
              var finestre = spazi[i]["finestre"] as? [[String: Any]], finestre.count == 4 else {
            return "Luce: archivio di prova con un'app sconosciuta non preparato"
        }
        finestre[3]["app"] = "appDiUnPrismaPiuNuovo"
        spazi[i]["finestre"] = finestre
        spazi.append(["id": "spazio-sconosciuto", "nome": "Solo app nuove",
                      "finestre": [["app": "unAltraAppNuova", "x": 0, "y": 0, "larghezza": 1, "altezza": 1, "ingrandita": true] as [String: Any]]])
        radice["spazi"] = spazi
        let letto = try Archivio.decodifica(JSONSerialization.data(withJSONObject: radice))
        let atteso = try Archivio.decodifica(codificato)
        guard let lettoLuce = letto.spazi.first(where: { $0.id == "spazio-luce-prova" }),
              lettoLuce.finestre.map(\.app) == spazio.finestre.prefix(3).map(\.app),
              !letto.spazi.contains(where: { $0.id == "spazio-sconosciuto" }),
              letto.spazi.count == originale.spazi.count,
              letto.clienti == atteso.clienti, letto.posizioni == atteso.posizioni else {
            return "Luce: uno spazio con un'app sconosciuta non si legge con tolleranza (finestra da saltare, altri spazi da tenere)"
        }
        // 3. La versione dell'archivio
        guard DatiPrisma.versioneAttuale >= 27 else {
            return "Luce: l'archivio deve essere almeno alla versione 27"
        }
        return nil
    }
}
