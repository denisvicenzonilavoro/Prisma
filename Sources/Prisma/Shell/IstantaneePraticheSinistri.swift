#if os(macOS)
import Foundation

/// Le istantanee di Pratiche › Sinistri, il sinistro come una spedizione (Design/template-luce-specifica.md §7.4.7,
/// «Luce» giro 15), tutte nello stato finale (`\.modoIstantanea`: barra alla fase, nodo di adesso fermo con l'alone):
/// - 830: Marco, «Infortunio di Pietro» in perizia, con il telefono «Così lo vede Marco», chiara e scura;
/// - 831: Sofia, «Danni da acqua in cucina» pagato (barra tutta verde, «pagati 3.400 €», «polizza da collegare»), chiara
///   e scura;
/// - 832: nessun sinistro (i sinistri di prova tolti nella scena);
/// - 833: il modulo «Nuovo sinistro» aperto da Marco e dalla sua polizza;
/// - 834: Marco con gli aggiornamenti spenti (la colonna del telefono spenta, «Aggiorna Marco» spento);
/// - 835: Giulia, «Furto della bicicletta» respinto (il nodo rosso dopo le fasi raggiunte).
/// DATI DI PROVA DICHIARATI: i tre sinistri di `SinistriDiProva` (fatti, numeri e importi fittizi); le scene 834 e 835
/// cambiano un sinistro di prova nel solo stato dell'istantanea (che non si salva).
extension Istantanee {
    nonisolated static var scenePraticheSinistri: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("830-pratiche-sinistri") { s in mostraSinistro(s, SinistriDiProva.idMarco) }
        coppia("831-pratiche-sinistri-pagato") { s in mostraSinistro(s, SinistriDiProva.idSofia) }
        una("832-pratiche-sinistri-vuoto") { s in
            s.dati.sinistri = []
            s.sinistri.istantanea = nil
            s.sinistri.scelto = nil
            s.apriPratiche(.sinistri)
        }
        una("833-pratiche-sinistri-nuovo") { s in
            mostraSinistro(s, SinistriDiProva.idMarco)
            s.apriNuovoSinistro(cliente: "marco", posizione: SinistriDiProva.polizzaMarco)
        }
        una("834-pratiche-sinistri-senza-aggiornamenti") { s in
            if let i = s.dati.sinistri.firstIndex(where: { $0.id == SinistriDiProva.idMarco }) {
                s.dati.sinistri[i].mostraAlCliente = nil
            }
            mostraSinistro(s, SinistriDiProva.idMarco)
        }
        una("835-pratiche-sinistri-respinto") { s in
            if let i = s.dati.sinistri.firstIndex(where: { $0.id == SinistriDiProva.idGiulia }) {
                var x = s.dati.sinistri[i]
                let giorno = x.eventi.last.map { $0.data.addingTimeInterval(2 * 86_400) } ?? x.apertoIl
                MotoreSinistri.avanza(&x, a: .respinto, il: giorno, pagato: nil, id: "evento-prova-giulia-respinto")
                s.dati.sinistri[i] = x
            }
            mostraSinistro(s, SinistriDiProva.idGiulia)
        }
        return scene
    }

    /// Pratiche › Sinistri sul sinistro di prova dato (il cliente attivo è il suo).
    nonisolated static func mostraSinistro(_ s: StatoShell, _ id: String) {
        if let x = s.dati.sinistri.first(where: { $0.id == id }) { s.clienteAttivoId = x.clienteId }
        s.sinistri.istantanea = id
        s.sinistri.scelto = id
        s.apriPratiche(.sinistri)
    }
}
#endif
