#if os(macOS)
import Foundation

/// Le istantanee di «Stanotte Prisma ha lavorato» sul Mac (Design/template-luce-specifica.md §6.1.7, «Luce» giro 14), nello
/// stato finale (pila ferma, timbri nascosti tranne la 761, registro scritto, anello pieno):
/// - 760: le otto carte, la prima davanti, registro vuoto (chiara e scura); 761: la prima carta trascinata a destra di 90
///   con il timbro «APPROVA»; 762: un sì e un più tardi, «3 di 8» (chiara e scura); 763: tutte decise, «Tutto fatto.»
///   (chiara e scura); 764: nessuna notte di oggi, «Stanotte il Mac dormiva.» con «Prepara adesso»; 765: due carte e
///   «Da finire» terza; 766: la finestra stretta, registro sotto i comandi; 767: la scrivania con «☾ Stanotte» e il pallino.
///
/// DATI DI PROVA DICHIARATI: le carte di `NotteDiProva` (id «notte-prova-»), solo dentro queste scene. Le decisioni sono
/// scritte nel registro senza effetti (niente PDF nelle istantanee).
extension Istantanee {
    nonisolated static var sceneNotte: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func una(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
        }
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            una(nome, prepara)
            una(nome + "-scuro", prepara)
        }
        coppia("760-notte-carte") { s in notteScena(s) }
        una("761-notte-trascina") { s in
            s.notte.trascinamentoIstantanea = Double(Tema.Apple.Notte.Timbro.istantanea)
            notteScena(s)
        }
        coppia("762-notte-registro") { s in notteScena(s, decise: [(0, true), (1, false)]) }
        coppia("763-notte-fine") { s in notteScena(s, decise: (0..<8).map { ($0, $0 != 6) }) }
        una("764-notte-saltata") { s in
            s.dati.impostazioni.notte.attivo = true
            s.dati.notti = []
            s.apriNotte()
        }
        una("765-notte-da-finire") { s in
            notteScena(s, notte: NotteDiProva.conDaFinire(s.dati.istantanea, oggi: Date(), cal: Calendar.current))
        }
        una("766-notte-stretta") { s in notteScena(s) }
        una("767-scrivania-stanotte") { s in
            s.dati.notti = [NotteDiProva.notte(s.dati.istantanea, oggi: Date(), cal: Calendar.current)]
        }
        return scene
    }

    /// Le carte della notte di prova aperte; `decise`: (indice della carta, approvata) scritte nel registro senza effetti.
    nonisolated static func notteScena(_ s: StatoShell, notte: NotteDiLavoro? = nil, decise: [(Int, Bool)] = []) {
        let n = notte ?? NotteDiProva.notte(s.dati.istantanea, oggi: Date(), cal: Calendar.current)
        var decisa = n
        for (k, approvata) in decise where k < decisa.carte.count {
            decisa.carte[k].stato = approvata ? .approvata : .rimandata
        }
        s.dati.notti = [n]
        s.apriNotte()
        s.notte.primaApertura = false
        for (k, approvata) in decise where k < n.carte.count {
            let c = n.carte[k]
            s.notte.registro.insert(RigaRegistroNotte(id: c.id, approvata: approvata,
                                                      testo: approvata ? c.conferma : TestiNotte.rigaRimandata(c.titolo)), at: 0)
        }
        if !decise.isEmpty { s.dati.notti = [decisa] }
    }
}
#endif
