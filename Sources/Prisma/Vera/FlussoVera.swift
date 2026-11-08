import Combine
import Observation
import Foundation

/// La risposta di Vera mentre arriva. È un oggetto a parte, osservato solo dalla bolla in arrivo:
/// le parole che scorrono non ridisegnano tutta Prisma.
@Observable final class FlussoVera {
    private(set) var testo = "" { willSet { testoCambia.send(newValue) } }
    /// Il testo che sta per cambiare, con il valore di adesso all'iscrizione (al posto di `$testo`: la mini finestra di Vera).
    @ObservationIgnored let testoCambia = CurrentValueSubject<String, Never>("")
    /// Vera ragiona prima di rispondere (finché non arriva la prima parola).
    private(set) var pensa = false
    /// Modalità lavoro: Vera legge il dossier; conversazione: scrive e basta.
    private(set) var modalita = ModalitaVera.lavoro
    /// Il motore che sta scrivendo («Qwen sul Mac»).
    @ObservationIgnored private(set) var motore = ""
    /// Cresce a ogni risposta: un aggiornamento in ritardo di quella prima non tocca questa.
    @ObservationIgnored private(set) var generazione = 0

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
