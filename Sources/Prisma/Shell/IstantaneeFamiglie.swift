#if os(macOS)
import Foundation

/// Le istantanee di Analisi 360 › «Rispetto alle famiglie come la sua» (Orizzonte, giro 6; specifica §10.7), 445-449 in
/// chiaro e in scuro, tutte nello stato finale (`\.modoIstantanea`: cifre complete, avatar al loro posto):
/// - 445: Giulia con le tavole della Banca d'Italia incluse nell'app (`Risorse/famiglie-bdi-2022.json`): il confronto
///   doppio, con le famiglie della sua età e con quelle del suo quinto di reddito, e la fonte in piccolo;
/// - 446: Giulia con il file di prova (versione 1, celle età × reddito, valori segnaposto) caricato come se l'avesse
///   scelto il consulente: l'etichetta «Dati di prova…», la griglia 2 × 2 e la nota di prova;
/// - 447: Marco, un altro cliente, con le tavole della Banca d'Italia;
/// - 448: Giulia senza risparmio indicato e senza posizioni: «—» e «Completa nella scheda del cliente ›»;
/// - 449: Giulia senza data di nascita: resta il confronto con le famiglie del suo quinto di reddito, e la nota lo dice.
///
/// Le cifre delle famiglie sono quelle pubblicate dalla Banca d'Italia (edizione 2022), tranne la 446 che mostra di
/// proposito il file di prova; i clienti sono quelli fittizi del template. Il file di prova della 446 esiste SOLO dentro
/// la scena (lo stato dell'istantanea non si salva).
extension Istantanee {
    nonisolated static var sceneFamiglie: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
            scene.append((nome: nome + "-scuro", prepara: prepara))
        }
        coppia("445-analisi360-famiglie") { s in preparaFamiglie(s, cliente: "giulia") }
        coppia("446-analisi360-famiglie-tabelle") { s in
            s.dati.famiglie = famiglieDiProvaCaricate()
            preparaFamiglie(s, cliente: "giulia")
        }
        coppia("447-analisi360-famiglie-altro-cliente") { s in preparaFamiglie(s, cliente: "marco") }
        coppia("448-analisi360-famiglie-incompleto") { s in
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "giulia" }) { s.dati.clienti[i].profilo.risparmioAnnuo = nil }
            s.dati.posizioni = s.dati.posizioni.filter { $0.clienteId != "giulia" }
            preparaFamiglie(s, cliente: "giulia")
        }
        coppia("449-analisi360-famiglie-senza-eta") { s in
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "giulia" }) { s.dati.clienti[i].dataNascita = nil }
            preparaFamiglie(s, cliente: "giulia")
        }
        return scene
    }

    /// Analisi 360 aperta su «Rispetto alle famiglie come la sua» per il cliente dato.
    nonisolated static func preparaFamiglie(_ s: StatoShell, cliente: String) {
        s.clienteAttivoId = cliente
        s.apriFamiglieComeLaSua()
    }

    /// Il file di prova della 446 (versione 1, `diProva`, valori segnaposto) come se l'avesse caricato il consulente.
    nonisolated static func famiglieDiProvaCaricate() -> FamiglieCaricate? {
        TabelleFamiglie.tabelleDiProva.map {
            FamiglieCaricate(tabelle: $0, nomeFile: "famiglie-di-prova.json", caricateIl: Date())
        }
    }
}
#endif
