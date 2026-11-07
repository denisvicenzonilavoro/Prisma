#if os(macOS)
import Foundation

/// Le istantanee delle schede Panoramica e Obiettivi del dossier nel tema Apple (§4.2.2, §4.2.3): la Panoramica di
/// Marco (dati per l'analisi con l'anello e le voci da completare, «Da ricordare», il prossimo incontro), gli
/// obiettivi di Giulia (due card e il posto libero) e il dettaglio dell'anticipo casa aperto con il cursore. Le cifre
/// vengono dai motori di Prisma sui dati di prova.
extension Istantanee {
    nonisolated static var sceneDossierApple: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("431-clienti-panoramica-apple", { s in
                s.clienteAttivoId = "marco"
                s.schedaCliente = .panoramica
                s.apri(.clienti)
            }),
            ("432-clienti-obiettivi-apple", { s in
                s.clienteAttivoId = "giulia"
                s.schedaCliente = .obiettivi
                s.apri(.clienti)
            }),
            ("433-clienti-obiettivo-dettaglio", { s in
                s.clienteAttivoId = "giulia"
                s.schedaCliente = .obiettivi
                RichiestaIstantaneaDossier.chiedi(s, dettaglio: "obiettivo-giulia-casa")
                s.apri(.clienti)
            }),
        ]
    }
}
#endif
