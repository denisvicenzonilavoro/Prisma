import Combine
import Foundation

/// La risposta di Vera mentre arriva. È un oggetto a parte, osservato solo dalla bolla in arrivo:
/// le parole che scorrono non ridisegnano tutta Prisma.
final class FlussoVera: ObservableObject {
    @Published private(set) var testo = ""
    /// Vera ragiona prima di rispondere (finché non arriva la prima parola).
    @Published private(set) var pensa = false
    /// Modalità lavoro: Vera legge il dossier; conversazione: scrive e basta.
    @Published private(set) var modalita = ModalitaVera.lavoro
    /// Il motore che sta scrivendo («Qwen sul Mac»).
    private(set) var motore = ""
    /// Cresce a ogni risposta: un aggiornamento in ritardo di quella prima non tocca questa.
    private(set) var generazione = 0

    @discardableResult
    func inizia(_ scelta: SceltaVera, motore: String) -> Int {
        generazione &+= 1
        testo = ""
        pensa = scelta.pensa
        modalita = scelta.modalita
        self.motore = motore
        return generazione
    }

    func aggiorna(_ p: ParzialeVera, generazione g: Int) {
        guard g == generazione else { return }
        if testo != p.testo { testo = p.testo }
        let ragiona = p.pensa && p.testo.isEmpty
        if pensa != ragiona && (ragiona || !p.testo.isEmpty) { pensa = ragiona }
    }

    func chiudi() {
        generazione &+= 1
        testo = ""
        pensa = false
    }
}
