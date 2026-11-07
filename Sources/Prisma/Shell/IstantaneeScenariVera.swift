#if os(macOS)
import Foundation

/// Le istantanee degli scenari «E se…?» di Vera: la risposta con la scheda prima/dopo (tabella a tre colonne, la colonna
/// dello scenario in viola, «Salva nel dossier» e «Apri in Simulazioni»), chiara e scura, e la stessa tabella nella mini
/// finestra. Senza Qwen: il racconto è quello di Prisma, le cifre sono quelle di MotoreScenari sui dati di prova.
extension Istantanee {
    nonisolated static let domandaScenarioVera = "E se Marco va in pensione a 63 anni e smette di versare?"

    nonisolated static var sceneScenariVera: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("484-vera-scenario", { s in preparaScenarioVera(s) }),
            ("484-vera-scenario-scuro", { s in preparaScenarioVera(s) }),
            ("484-vera-mini-scenario", { s in
                preparaMiniVera(s)
                s.disponibilitaLocale = .pronto
                s.clienteAttivoId = "marco"
                s.apriMiniVera(.scrivi)
                s.inviaMiniVera(DomandaMiniVera(testo: domandaScenarioVera))
            }),
        ]
    }

    /// L'app Vera su Marco Bianchi con lo scenario della pensione a 63 anni senza versamenti già calcolato.
    nonisolated static func preparaScenarioVera(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.veraPortafoglio = false
        s.chiediVera(domandaScenarioVera)
        s.apri(.vera)
    }
}
#endif
