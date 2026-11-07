import Foundation

/// Le raccolte della barra laterale di Documenti.
enum RaccoltaDocumenti: String, CaseIterable, Identifiable {
    case tutti, daLeggere, conDifferenze, daCollegare, collegati

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .tutti: return "Tutti i documenti"
        case .daLeggere: return "Da leggere"
        case .conDifferenze: return "Cosa non torna"
        case .daCollegare: return "Da collegare"
        case .collegati: return "Collegati"
        }
    }

    /// Simbolo SF (tutti disponibili da macOS 13).
    var simbolo: String {
        switch self {
        case .tutti: return "tray.full"
        case .daLeggere: return "circle.fill"
        case .conDifferenze: return "exclamationmark.triangle"
        case .daCollegare: return "link.badge.plus"
        case .collegati: return "link"
        }
    }
}

/// Cosa mostra l'app Documenti (in StatoShell, così le istantanee, la ricerca ⌘K, le notifiche e Prodotti la impostano).
/// Il testo della ricerca non sta qui: è uno stato della vista (scrivere non ridisegna le altre finestre).
struct VistaDocumenti: Equatable {
    enum Scheda: Hashable { case dati, confronto, testo }

    var scheda: Scheda = .dati
    var raccolta = RaccoltaDocumenti.tutti
    var categoria: CategoriaDocumento?
    var canale: Canale?
    /// Pagina dell'anteprima (da 1) e il dato di cui evidenziare la riga.
    var pagina = 1
    var evidenzia: CampoDocumento?
    /// Il pannello dei dati accanto al documento. nil = automatico: aperto se ci sta accanto all'anteprima
    /// (`anteprimaMinima` + `scheda`), altrimenti chiuso. Aperto dal consulente dove non ci sta, è un cassetto sotto
    /// il foglio: non lo copre mai.
    var pannelloDati: Bool?
    /// L'elenco dei documenti nella scheda del cliente. nil = automatico: aperto se la scheda è larga almeno
    /// `Tema.Misura.Documenti.elencoAutomatico` o se un filtro è attivo, purché alla pagina resti `anteprimaMinima`
    /// (con il pannello dei dati accanto); altrimenti stretto (le sole tessere).
    var elenco: Bool?
}
