import Foundation
import Observation

// Lo stato della sovrapposizione «Stanotte ho lavorato per te.» («Luce» giro 14, §6.1): la pila di questa apertura, il
// registro delle decisioni, il lavoro in corso. Un oggetto a parte: decidere una carta non ridisegna la shell. Le parti
// del lavoro che non si osservano (compito, guardia dei 20 minuti, esecutore delle bozze, memoria, attività, pianificatore)
// stanno in `LavoroNotte`, una classe normale (niente `#if` dentro la classe osservata). Compila su Mac e iOS.

/// Una riga del registro «FATTO ADESSO».
struct RigaRegistroNotte: Identifiable, Equatable {
    /// L'id della carta.
    let id: String
    let approvata: Bool
    let testo: String
}

@Observable final class StatoNotte {
    /// Le carte di questa apertura (id), nell'ordine della pila; si fissa ad `apriNotte`.
    var pila: [String] = []
    /// Le decisioni di questa apertura, la più recente prima.
    var registro: [RigaRegistroNotte] = []
    /// La prima apertura di oggi: le carte entrano a cascata solo questa volta.
    var primaApertura = true
    /// Il giorno (chiave) della prima apertura: il giorno dopo la cascata torna.
    var giornoApertura: String?
    /// Il lavoro in corso adesso (e quante carte pronte): «Sto preparando… 3 di 8».
    var inCorso = false
    var fatte = 0
    var previste = 0
    /// Solo istantanee: lo spostamento fisso della carta davanti (761: 90).
    @ObservationIgnored var trascinamentoIstantanea: Double?
    /// Le parti del lavoro che non si osservano.
    @ObservationIgnored let lavoro = LavoroNotte()

    init() {}
}

/// Il lavoro della notte (decisioni 30 e 101). Non osservato.
final class LavoroNotte {
    /// Il compito del lavoro (fase 1 e fase 2).
    var compito: Task<Void, Never>?
    /// I 20 minuti: poi il lavoro si ferma comunque.
    var guardia: Task<Void, Never>?
    /// Le bozze di Vera in corso (per fermarle all'avviso di memoria o allo stop del Mac).
    var esecutore: EsecutoreBozzeNotte?
    /// L'avviso di memoria del sistema.
    var memoria: DispatchSourceMemoryPressure?
    /// `ProcessInfo.beginActivity` per la durata del lavoro.
    var attivita: NSObjectProtocol?
    /// Il pianificatore di macOS (`NSBackgroundActivityScheduler`, solo Mac: per iOS resta nil).
    var pianificatore: AnyObject?
    /// Il motivo con cui il lavoro è stato fermato da fuori (memoria, riposo, 20 minuti, chiusura).
    var fermatoPer: MotivoStopNotte?

    init() {}

    /// Ferma tutto (memoria, riposo, 20 minuti, chiusura): le carte fatte restano. Il compito finisce da sé dopo la bozza
    /// in corso.
    func ferma(_ motivo: MotivoStopNotte) {
        if fermatoPer == nil { fermatoPer = motivo }
        esecutore?.ferma(motivo)
        guardia?.cancel()
        guardia = nil
    }

    /// Fine del lavoro: memoria, attività e guardia via.
    func chiudi() {
        guardia?.cancel()
        guardia = nil
        memoria?.cancel()
        memoria = nil
        if let a = attivita {
            ProcessInfo.processInfo.endActivity(a)
            attivita = nil
        }
        esecutore = nil
        compito = nil
    }
}
