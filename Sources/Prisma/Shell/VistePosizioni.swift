import Foundation

/// Le viste del Portafoglio di Posizioni (segmenti della testata), nell'ordine del template di Luce
/// (Design/template-luce-specifica.md §8.2.1.1): Portafoglio · Radar · Prova del fuoco · Smontaggio. Il radar
/// e lo smontaggio arrivano con il giro 2 di Luce.
enum VistaPosizioni: Hashable, CaseIterable {
    case portafoglio, radar, provaDelFuoco, smontaggio

    var titolo: String {
        switch self {
        case .portafoglio: return "Portafoglio"
        case .radar: return "Radar"
        case .provaDelFuoco: return "Prova del fuoco"
        case .smontaggio: return "Smontaggio"
        }
    }

    /// I segmenti della testata, in ordine.
    static var segmenti: [(VistaPosizioni, String)] { allCases.map { ($0, $0.titolo) } }
}
