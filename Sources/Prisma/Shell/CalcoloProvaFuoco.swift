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
    /// La base che si sta preparando fuori dal thread principale, con la sua chiave.
    private var compitoBase: Task<Void, Never>?
    private var chiaveInPreparazione: Int?
    /// Lo scenario chiesto mentre la base si prepara: si calcola appena la base c'è (vince l'ultimo).
    private var scenarioInAttesa: ScenarioFuoco?

    /// Prepara (o riusa) la base. `chiave` cambia quando cambiano i dati dei calcoli o il giorno.
    /// La base passa in rassegna tutti i clienti (composizione di ogni posizione, copertura di ogni obiettivo con le
    /// sue proiezioni): si prepara fuori dal thread principale, così aprire la prova del fuoco non ferma la finestra.
    /// Intanto gli scenari chiesti aspettano (`scenarioInAttesa`) e «Ricalcolo…» segue `inCorso`, come per lo scenario.
    func preparaBase(chiave: Int, clienti: [Cliente], posizioni: [Posizione], obiettivi: [Obiettivo], oggi: Date) {
        if compitoBase != nil {
            if chiave == chiaveInPreparazione { return }
        } else if chiave == chiaveBase, base != nil {
            return
        }
        compitoBase?.cancel()
        // Uno scenario sulla base di prima non vale più: si rifà sulla nuova
        compito?.cancel()
        compito = nil
        _ = sequenza.nuovo()
        chiaveInPreparazione = chiave
        inCorso = true
        compitoBase = Task { @MainActor [weak self] in
            // Annullabile come `MotoreProvaFuoco.calcolaInSottofondo`: annullato il compito, la preparazione si ferma
            // al cliente successivo e il risultato è nil
            let lavoro = Task.detached(priority: .userInitiated) { () -> BaseProvaFuoco? in
                MotoreProvaFuoco.prepara(clienti: clienti, posizioni: posizioni, obiettivi: obiettivi, oggi: oggi,
                                         annullato: { Task.isCancelled })
            }
            let nuova = await withTaskCancellationHandler { await lavoro.value } onCancel: { lavoro.cancel() }
            guard let self, !Task.isCancelled, self.chiaveInPreparazione == chiave, let nuova else { return }
            self.base = nuova
            self.chiaveBase = chiave
            self.chiaveInPreparazione = nil
            self.compitoBase = nil
            if let s = self.scenarioInAttesa {
                self.scenarioInAttesa = nil
                self.ricalcola(s)
            } else {
                self.inCorso = false
            }
        }
    }

    /// Lancia il calcolo dello scenario (annulla quello in corso). Con la base in preparazione lo scenario aspetta
    /// la base; senza base non fa niente.
    func ricalcola(_ s: ScenarioFuoco) {
        if compitoBase != nil {
            scenarioInAttesa = s
            inCorso = true
            return
        }
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

    /// La vista si chiude: niente calcoli a metà (neppure la base: la prossima apertura la riprepara).
    func ferma() {
        compito?.cancel()
        compito = nil
        compitoBase?.cancel()
        compitoBase = nil
        chiaveInPreparazione = nil
        scenarioInAttesa = nil
        _ = sequenza.nuovo()
        inCorso = false
    }
}
