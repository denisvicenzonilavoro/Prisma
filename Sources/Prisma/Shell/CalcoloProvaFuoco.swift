import Foundation
import Combine

/// Il calcolo della prova del fuoco per la vista: la base si prepara una volta per dati e giorno, ogni scenario
/// (ogni passo del cursore) si calcola fuori dal thread principale e il risultato si pubblica sul thread principale.
/// Un ricalcolo nuovo annulla quello in corso: vince l'ultimo (`SequenzaRicalcoli`).
@MainActor
final class CalcoloProvaFuoco: ObservableObject {
    @Published private(set) var esito: EsitoProvaFuoco?
    @Published private(set) var inCorso = false

    private var base: BaseProvaFuoco?
    private var chiaveBase: Int?
    private var compito: Task<Void, Never>?
    private var sequenza = SequenzaRicalcoli()

    /// Prepara (o riusa) la base. `chiave` cambia quando cambiano i dati dei calcoli o il giorno.
    func preparaBase(chiave: Int, clienti: [Cliente], posizioni: [Posizione], obiettivi: [Obiettivo], oggi: Date) {
        guard chiave != chiaveBase || base == nil else { return }
        base = MotoreProvaFuoco.prepara(clienti: clienti, posizioni: posizioni, obiettivi: obiettivi, oggi: oggi)
        chiaveBase = chiave
    }

    /// Lancia il calcolo dello scenario (annulla quello in corso). Senza base non fa niente.
    func ricalcola(_ s: ScenarioFuoco) {
        guard let base else { return }
        compito?.cancel()
        let numero = sequenza.nuovo()
        inCorso = true
        compito = Task { @MainActor [weak self] in
            let e = await MotoreProvaFuoco.calcolaInSottofondo(s, base: base)
            guard let self, !Task.isCancelled, self.sequenza.valido(numero) else { return }
            if let e { self.esito = e }
            self.inCorso = false
            self.compito = nil
        }
    }

    /// Subito, sul thread principale (istantanee, nello stato finale; con pochi clienti).
    func calcolaSubito(_ s: ScenarioFuoco) {
        guard let base else { return }
        compito?.cancel()
        _ = sequenza.nuovo()
        esito = MotoreProvaFuoco.calcola(s, base: base)
        inCorso = false
        compito = nil
    }

    /// La vista si chiude: niente calcoli a metà.
    func ferma() {
        compito?.cancel()
        compito = nil
        _ = sequenza.nuovo()
        inCorso = false
    }
}
