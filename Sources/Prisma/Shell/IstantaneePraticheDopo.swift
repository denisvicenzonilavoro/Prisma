#if os(macOS)
import Foundation

/// Le istantanee di Pratiche › Dopo la firma (Design/template-luce-specifica.md §7.3.7, «Luce» giro 3), tutte nello stato
/// finale (`\.modoIstantanea`: numeri completi, passi e card fermi):
/// - 820: le quattro pratiche di prova (Marco ferma in testa, Sofia completata), chiaro e scuro;
/// - 821: nessuna pratica: tile a zero e «Nessuna pratica aperta…» con «Vai alle proposte»;
/// - 822: il dettaglio della pratica di Giulia già aperto (passi segnati a mano, l'emissione tolta a mano che Prisma
///   riconoscerebbe dal numero di contratto, note), chiaro e scuro;
/// - 823: «✓ Sollecito pronto» sulla pratica ferma di Marco.
/// DATI DI PROVA DICHIARATI: le quattro pratiche del template (`PraticheDiProva`, nota «Dati di prova») su posizioni dei
/// clienti di prova, con le date relative a oggi; stati, conteggi e frasi li calcola MotorePratiche.
extension Istantanee {
    nonisolated static var scenePraticheDopo: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("820-pratiche-dopo") { s in preparaPraticheDopo(s) }
        una("821-pratiche-dopo-vuota") { s in
            s.dati.pratiche = []
            s.apriPratiche(.dopoLaFirma)
        }
        coppia("822-pratiche-dopo-dettaglio") { s in
            preparaPraticheDopo(s)
            s.praticaDettaglioIstantanea = PraticheDiProva.prefisso + "giulia"
        }
        una("823-pratiche-dopo-sollecito") { s in
            preparaPraticheDopo(s)
            s.sollecitaPratica(PraticheDiProva.prefisso + "marco", apri: false)
        }
        return scene
    }

    /// Le pratiche di prova (quelle di `DatiPrisma.demo()`, rifatte con le date di oggi); poi Pratiche › Dopo la firma.
    nonisolated static func preparaPraticheDopo(_ s: StatoShell) {
        s.dati.pratiche = PraticheDiProva.pratiche()
        s.apriPratiche(.dopoLaFirma)
    }
}
#endif
