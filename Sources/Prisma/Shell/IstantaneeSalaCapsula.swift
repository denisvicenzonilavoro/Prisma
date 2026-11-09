#if os(macOS)
import Foundation

/// Le istantanee di Sala › La capsula del tempo (giro 15 di «Luce», §3.4.7 e §6 del piano), tutte nello stato finale
/// (`\.modoIstantanea`: elenco fermo, nessuna pulsazione, capsula aperta con il foglio fuori e il testo intero):
/// - 653: Giulia, campo vuoto, le chip dei suoi obiettivi, l'elenco solo delle sue capsule (chiaro e scuro);
/// - 654: Sofia, la tile arancio della capsula pronta, ferma (chiaro e scuro);
/// - 655: Sofia, la capsula aperta: velo, foglio, testo intero, «Stampala su carta per Sofia» (chiaro e scuro);
/// - 656: Andrea senza obiettivi né capsule (la scena toglie i suoi obiettivi e la data di nascita);
/// - 657: la chiave che manca su questo Mac: la riga «Non si può aprire su questo Mac».
/// DATI DI PROVA DICHIARATI: le capsule di `CapsuleDiProva` (chiave di prova pubblica) e la password di prova del PDF
/// condiviso (mai una password vera); lo stato della scena non si salva.
extension Istantanee {
    nonisolated static var sceneSalaCapsula: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("653-sala-capsula") { s in
            s.apriEsperienza(.capsula, cliente: "giulia")
        }
        coppia("654-sala-capsula-pronta") { s in
            s.apriEsperienza(.capsula, cliente: "sofia")
        }
        coppia("655-sala-capsula-aperta") { s in
            s.sala.provaUscite.capsulaApertaId = CapsuleDiProva.idSofia
            s.sala.provaUscite.passwordDiProva = TestiCapsule.passwordDiProvaIstantanee
            s.apriEsperienza(.capsula, cliente: "sofia")
        }
        una("656-sala-capsula-vuota") { s in
            if let i = s.dati.clienti.firstIndex(where: { $0.id == "andrea" }) { s.dati.clienti[i].dataNascita = nil }
            s.dati.obiettivi.removeAll { $0.clienteId == "andrea" }
            s.dati.capsule.removeAll { $0.clienteId == "andrea" }
            s.apriEsperienza(.capsula, cliente: "andrea")
        }
        una("657-sala-capsula-chiave-mancante") { s in
            s.sala.provaUscite.capsulaChiaveMancante = true
            s.apriEsperienza(.capsula, cliente: "giulia")
        }
        return scene
    }
}
#endif
