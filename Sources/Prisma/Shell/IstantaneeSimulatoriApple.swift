#if os(macOS)
import Foundation

/// Le istantanee dei simulatori dal vivo di Analisi 360 nel tema Apple (§4.3.2, §4.3.3): l'area Previdenza e l'area
/// Protezione di Marco espanse nel simulatore, con il cursore spostato dal valore di partenza (il versamento di oggi
/// più 150 € al mese; 100.000 € di capitale caso morte in più). Le cifre vengono dai motori di Prisma sui dati di
/// prova; il dettaglio si apre già aperto con `RichiestaIstantaneaSimulatore` (lo legge
/// `SimulatoriAnalisiApple.dettaglioIniziale`, nel presentatore della griglia delle aree).
extension Istantanee {
    nonisolated static var sceneSimulatoriApple: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("441-analisi360-previdenza-simulatore", { s in
                s.clienteAttivoId = "marco"
                s.areaAnalisi = nil
                let oggi = s.analisi360("marco").previdenza.versamentoMensile
                let passo = Tema.Apple.SimulatoriAnalisi.Previdenza.passo
                RichiestaIstantaneaSimulatore.chiedi(s, area: .previdenza, valore: ((oggi + 150) / passo).rounded() * passo)
                s.apri(.analisi360)
            }),
            ("442-analisi360-protezione-simulatore", { s in
                s.clienteAttivoId = "marco"
                s.areaAnalisi = nil
                RichiestaIstantaneaSimulatore.chiedi(s, area: .protezione, valore: 100_000)
                s.apri(.analisi360)
            }),
        ]
    }
}
#endif
