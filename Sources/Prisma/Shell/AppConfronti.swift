import SwiftUI

/// Ciò che entra in un confronto, già tradotto in ipotesi di calcolo.
struct ElementoConfronto: Identifiable {
    let voce: VoceConfronto
    let titolo: String
    let sottotitolo: String
    let canale: Canale?
    let parametri: ParametriProiezione

    var id: VoceConfronto { voce }

    /// Le voci confrontabili di un cliente: posizioni proiettabili (prima quelle in essere) e scenari salvati.
    static func elenco(_ dati: DatiPrisma, cliente: String) -> [ElementoConfronto] {
        let orizzonte = dati.clienti.first { $0.id == cliente }?.profilo.orizzonteAnni
        let posizioni = dati.posizioni
            .filter { $0.clienteId == cliente && $0.area.proiettabile && $0.stato != .chiusa }
            .sorted { ($0.stato == .inEssere ? 0 : 1, $0.nome) < ($1.stato == .inEssere ? 0 : 1, $1.nome) }
            .map { p in
                ElementoConfronto(voce: .posizione(p.id), titolo: p.nome,
                                  sottotitolo: "\(p.stato == .proposta ? "Proposta" : "In essere") · \(p.area.nome)",
                                  canale: p.canale, parametri: ParametriProiezione(posizione: p, orizzonteCliente: orizzonte))
            }
        let scenari = dati.simulazioni.filter { $0.clienteId == cliente }.sorted { $0.creataIl > $1.creataIl }.map { s in
            ElementoConfronto(voce: .simulazione(s.id), titolo: s.titolo, sottotitolo: "Scenario del simulatore",
                              canale: s.canale, parametri: s.parametri)
        }
        return posizioni + scenari
    }

    /// Le due voci da mettere a fronte: quelle scelte o, se nessuna, una proposta contro la posizione in essere più vicina.
    static func coppia(_ tutte: [ElementoConfronto], a sceltaA: VoceConfronto?, b sceltaB: VoceConfronto?,
                       posizioni: [Posizione]) -> (ElementoConfronto?, ElementoConfronto?) {
        func trova(_ v: VoceConfronto?) -> ElementoConfronto? { v.flatMap { x in tutte.first { $0.voce == x } } }
        var a = trova(sceltaA)
        var b = trova(sceltaB)
        if a == nil && b == nil {
            if let proposta = posizioni.first(where: { $0.stato == .proposta && $0.area.proiettabile }) {
                let inEssere = posizioni.filter { $0.stato == .inEssere && $0.area.proiettabile }
                a = trova((inEssere.first { $0.area == proposta.area } ?? inEssere.first).map { .posizione($0.id) })
                b = trova(.posizione(proposta.id))
            }
            if a == nil { a = tutte.first }
            if b == nil { b = tutte.first { $0.voce != a?.voce } }
        }
        return (a, b)
    }
}

/// App Confronti (.os-app-comparisons): due voci del dossier fianco a fianco, per esempio la posizione in essere
/// e la proposta, Alleanza e indipendente, con lo stesso orizzonte. Sul Mac è accorpata negli strumenti di
/// Analisi 360 (`StrumentiAnalisi360`); qui resta l'involucro di iPhone e iPad attorno a `ConfrontoIpotesi`.
struct AppConfronti: View {
    @EnvironmentObject var stato: StatoShell

    private var voci: Int { ElementoConfronto.elenco(stato.dati, cliente: stato.clienteAttivoId).count }

    var body: some View {
        CorniceStrumento(
            notaStato: "Calcoli eseguiti in locale · stesso motore delle Posizioni · le ipotesi non sono previsioni",
            notaDestra: "\(voci) voci confrontabili"
        ) {
            DossierRail()
            CollegatiRail(app: [.posizioni, .analisi360], strumenti: [.simulatore, .scenari])
        } contenuto: {
            // La stessa vista di Analisi 360 sul Mac, nel tema Apple
            ConfrontoIpotesi()
                .strumentiApple()
        }
    }
}
