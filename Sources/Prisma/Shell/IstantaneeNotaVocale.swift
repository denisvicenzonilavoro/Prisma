#if os(macOS)
import Foundation

/// Le istantanee della nota vocale sul Mac (Design/template-luce-specifica.md §6.2, «Luce» giro 13), nello stato finale:
/// - 770: Incontri con il pulsante «Nota dall’iPhone» nella testata (chiara e scura);
/// - 771: la scheda «Arriva sul Mac» con la nota del template su Giulia e le quattro voci proposte (chiara e scura);
/// - 772: la stessa dopo «Conferma tutto» (titoli al passato); 773: due «Marco»: «Di chi si parla?»;
/// - 774: «Come funziona», il telefono disegnato in ascolto con il testo e l'onda al secondo 2 (chiara e scura).
///
/// DATI DI PROVA DICHIARATI: la nota del template (`NotaVocaleDiProva`, id con il prefisso «nota-prova-»), il secondo
/// «Marco» (Marco Verdi) e l'ora 11:42 del telefono disegnato esistono SOLO dentro queste scene.
extension Istantanee {
    nonisolated static var sceneNotaVocale: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("770-incontri-nota-pulsante") { s in
            s.apriApp(.incontri)
        }
        coppia("771-nota-arrivata") { s in
            notaDiProvaScena(s)
        }
        una("772-nota-confermata") { s in
            let id = notaDiProvaScena(s)
            s.confermaNota(id, proposte: Set(s.dati.noteInArrivo.first { $0.id == id }?.proposte.filter { $0.tipo != .messaggio }.map(\.id) ?? []))
            s.notaVocale.mostrata = id
        }
        una("773-nota-cliente-dubbio") { s in
            var altro = Cliente.nuovo(tinta: .verde)
            altro.nome = "Marco Verdi"
            altro.iniziali = "MV"
            s.dati.clienti.append(altro)
            notaDiProvaScena(s, testo: "Marco vuole rivedere la copertura infortuni. Richiamarlo a febbraio per i capitali.")
        }
        coppia("774-nota-come-funziona") { s in
            s.apriApp(.incontri)
            s.apriComeFunzionaNota()
        }
        return scene
    }

    /// Incontri davanti con la nota di prova arrivata e la scheda «Arriva sul Mac» aperta.
    @discardableResult
    nonisolated static func notaDiProvaScena(_ s: StatoShell, testo: String = NotaVocaleDiProva.testo) -> String {
        let oggi = NotaInArrivo.alSecondo(Date())
        let n = NotaVocaleDiProva.inArrivo(s.dati.istantanea, oggi: oggi, testo: testo)
        s.dati.noteInArrivo = [n]
        s.apriApp(.incontri)
        s.notaVocale.mostrata = n.id
        return n.id
    }
}
#endif
