import SwiftUI
import Observation

// Posizioni › Portafoglio · Prova del fuoco (Design/template-novita-specifica.md §6.1, §6.4): la vista scelta, lo
// scenario e il valore dei tre cursori. Non si salvano nell'archivio: restano finché Prisma è aperta (§6.4, ultima
// riga). Stanno in un oggetto proprio (`StatoShell.provaFuoco`), così trascinare il cursore non pubblica StatoShell
// e le altre app aperte non si ridisegnano.

/// Le cinque chip degli scenari, nell'ordine del template.
enum SceltaScenarioFuoco: String, CaseIterable, Identifiable {
    case mercati, tassi, inflazione, crisi2008, crisi2020

    var id: String { rawValue }

    /// Il testo della chip: fisso, non segue il cursore (come nel template).
    var titolo: String {
        switch self {
        case .mercati: return "Mercati \(Formati.meno)25%"
        case .tassi: return "Tassi +2 punti"
        case .inflazione: return "Inflazione al 5%"
        case .crisi2008: return "Come nel 2008"
        case .crisi2020: return "Come nel 2020"
        }
    }

    /// L'anno della crisi storica (nil per gli scenari con il cursore).
    var annoCrisi: Int? {
        switch self {
        case .crisi2008: return 2008
        case .crisi2020: return 2020
        default: return nil
        }
    }

    /// Il cursore dello scenario: etichetta, limiti, passo, valore iniziale (nil per gli storici).
    var cursore: CursoreScenarioFuoco? {
        switch self {
        case .mercati: return CursoreScenarioFuoco(etichetta: "Ribasso delle azioni", intervallo: 5...45, passo: 1, iniziale: 25)
        case .tassi: return CursoreScenarioFuoco(etichetta: "Rialzo dei tassi", intervallo: 0.5...4, passo: 0.5, iniziale: 2)
        case .inflazione: return CursoreScenarioFuoco(etichetta: "Inflazione per 3 anni", intervallo: 2.5...9, passo: 0.5, iniziale: 5)
        case .crisi2008, .crisi2020: return nil
        }
    }
}

/// I limiti di un cursore della prova del fuoco (§6.1.2, tabella dei cursori).
struct CursoreScenarioFuoco {
    let etichetta: String
    let intervallo: ClosedRange<Double>
    let passo: Double
    let iniziale: Double
}

/// Lo stato della prova del fuoco che resta finché l'app è aperta.
@Observable final class StatoProvaFuoco {
    /// Gli anni dell'inflazione alta (il cursore cambia solo il tasso).
    static let anniInflazione = 3

    var vista: VistaPosizioni = .portafoglio
    var scelta: SceltaScenarioFuoco = .mercati
    /// I valori dei tre cursori: ognuno resta il suo quando si cambia chip.
    var calo: Double = SceltaScenarioFuoco.mercati.cursore?.iniziale ?? 25
    var punti: Double = SceltaScenarioFuoco.tassi.cursore?.iniziale ?? 2
    var tasso: Double = SceltaScenarioFuoco.inflazione.cursore?.iniziale ?? 5

    /// Lo scenario scelto con il valore del suo cursore.
    var scenario: ScenarioFuoco { scenario(scelta) }

    func scenario(_ s: SceltaScenarioFuoco) -> ScenarioFuoco {
        switch s {
        case .mercati: return .mercati(calo: calo)
        case .tassi: return .tassi(punti: punti)
        case .inflazione: return .inflazione(tasso: tasso, anni: Self.anniInflazione)
        case .crisi2008: return .crisi(anno: 2008)
        case .crisi2020: return .crisi(anno: 2020)
        }
    }

    /// Il valore del cursore dello scenario scelto (0 per gli storici).
    func valore(_ s: SceltaScenarioFuoco) -> Double {
        switch s {
        case .mercati: return calo
        case .tassi: return punti
        case .inflazione: return tasso
        case .crisi2008, .crisi2020: return 0
        }
    }

    func imposta(_ v: Double, per s: SceltaScenarioFuoco) {
        switch s {
        case .mercati: if calo != v { calo = v }
        case .tassi: if punti != v { punti = v }
        case .inflazione: if tasso != v { tasso = v }
        case .crisi2008, .crisi2020: break
        }
    }

    /// Il valore scritto a destra del cursore: «−25%», «+2,5 punti», «5,5%».
    static func testoValore(_ v: Double, per s: SceltaScenarioFuoco) -> String {
        let n = Formati.numeroFormatter.string(from: NSNumber(value: v)) ?? "\(v)"
        switch s {
        case .mercati: return "\(Formati.meno)\(n)%"
        case .tassi: return "+\(n) punti"
        case .inflazione: return "\(n)%"
        case .crisi2008, .crisi2020: return ""
        }
    }

    /// La frase degli scenari storici al posto del cursore, composta dai dati di `CrisiStoriche` (azioni e titoli di
    /// Stato del periodo), con il recupero: Prisma mostra il punto più basso, la ripresa la dice la frase.
    static func fraseStorica(_ s: SceltaScenarioFuoco) -> String? {
        guard let anno = s.annoCrisi, let k = MotoreResistenza.crisiDelPassato.first(where: { $0.anno == anno }) else { return nil }
        func v(_ x: Double) -> String {
            let n = Formati.numeroFormatter.string(from: NSNumber(value: abs(x))) ?? "\(abs(x))"
            return (x < 0 ? Formati.meno : "+") + n + "%"
        }
        let azioni = "Azioni \(v(k.variazione(.azioni)))"
        let stato = "titoli di Stato \(v(k.variazione(.governativi)))"
        return "\(azioni), \(stato) (\(k.periodo)): le variazioni storiche applicate a ogni portafoglio, senza la ripresa. \(k.recupero)"
    }
}

extension StatoShell {
    /// Posizioni › Portafoglio sulla vista «Prova del fuoco» (dal pannello Novità e dalle istantanee), con lo scenario
    /// chiesto se c'è. In modalità cliente non si apre: parla di tutti i clienti.
    func apriProvaDelFuoco(_ scelta: SceltaScenarioFuoco? = nil) {
        guard !inModoCliente else {
            mostraAvviso("In modalità cliente la prova del fuoco non si apre: parla di tutti i clienti.")
            return
        }
        posizioneInDettaglio = nil
        portafoglio = true
        if let scelta { provaFuoco.scelta = scelta }
        provaFuoco.vista = .provaDelFuoco
        apriApp(.posizioni)
    }
}
