#if os(macOS)
import Foundation

/// Le istantanee degli scenari «E se…?» di Ruby: la risposta con la scheda prima/dopo (tabella a tre colonne, la colonna
/// dello scenario in viola, «Salva nel dossier» e «Apri in Simulazioni»), chiara e scura, e la stessa tabella nella mini
/// finestra. Senza Qwen: il racconto è quello di Prisma, le cifre sono quelle di MotoreScenari sui dati di prova.
extension Istantanee {
    nonisolated static let domandaScenarioRuby = "E se Marco va in pensione a 63 anni e smette di versare?"

    nonisolated static var sceneScenariRuby: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("484-ruby-scenario", { s in preparaScenarioRuby(s) }),
            ("484-ruby-scenario-scuro", { s in preparaScenarioRuby(s) }),
            ("484-ruby-mini-scenario", { s in
                preparaMiniRuby(s)
                s.disponibilitaLocale = .pronto
                s.clienteAttivoId = "marco"
                s.apriMiniRuby(.scrivi)
                s.inviaMiniRuby(DomandaMiniRuby(testo: domandaScenarioRuby))
            }),
        ]
    }

    /// L'app Ruby su Marco Bianchi con lo scenario della pensione a 63 anni senza versamenti già calcolato.
    nonisolated static func preparaScenarioRuby(_ s: StatoShell) {
        s.rispostePreparate = true
        s.disponibilitaLocale = .pronto
        s.clienteAttivoId = "marco"
        s.rubyPortafoglio = false
        s.chiediRuby(domandaScenarioRuby)
        s.apri(.ruby)
    }
}
#endif
