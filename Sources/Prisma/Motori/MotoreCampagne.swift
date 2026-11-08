import Foundation

// Le campagne di Messaggi › Campagne («Luce» giro 12, Design/template-luce-specifica.md §9.4): i gruppi di clienti con lo
// stesso bisogno, presi solo dai bisogni che i motori di Prisma calcolano già (decisione 97).

/// Il tipo di un gruppo con lo stesso bisogno. `Codable` perché finisce nella `Campagna` salvata.
enum TipoGruppoCampagna: String, Codable, CaseIterable, Identifiable {
    /// Bisogno «protezione-famiglia» di `MotoreBisogni`, non scartato.
    case protezioneFamiglia
    /// Posizioni in essere con la scadenza nello stesso mese, entro sei mesi.
    case scadenzaNelMese
    /// Compiono 40, 50 o 60 anni l'anno prossimo.
    case etaTonda
    /// Posizioni di previdenza in essere senza versamenti da dodici mesi (movimenti assenti = non valutata).
    case previdenzaFerma
    /// Bisogno «previdenza-assente» di `MotoreBisogni`, non scartato.
    case previdenzaAssente
    /// Bisogno «liquidita-ferma» di `MotoreBisogni`, non scartato.
    case liquiditaFerma

    var id: String { rawValue }

    /// L'id del bisogno di `MotoreBisogni` da cui nasce (nil per scadenze, età e previdenza ferma): serve al
    /// collegamento «Scrivi a tutti quelli con lo stesso bisogno» dalla scheda Bisogni del dossier.
    var bisognoId: String? {
        switch self {
        case .protezioneFamiglia: return "protezione-famiglia"
        case .previdenzaAssente: return "previdenza-assente"
        case .liquiditaFerma: return "liquidita-ferma"
        case .scadenzaNelMese, .etaTonda, .previdenzaFerma: return nil
        }
    }
}
