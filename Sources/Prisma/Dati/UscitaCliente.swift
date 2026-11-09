import Foundation

// Le cose date al cliente («Luce» giro 15, eccezione approvata l'8 novembre 2026, CLAUDE.md › Dati e privacy): la traccia
// nel dossier di ciò che è uscito dal Mac (il Prisma del cliente, il film, il biglietto, la capsula, l'aggiornamento del
// sinistro). Mai la password, mai il contenuto. Nella cartella a pezzi sta nel file del cliente; nei backup; mai in
// «Prisma ovunque».

/// Che cosa è stato dato al cliente. Un genere sconosciuto (da un Prisma più nuovo) fa scartare l'elemento da
/// `ElencoTollerante`.
enum GenereUscita: String, Codable, CaseIterable {
    case prismaCliente, film, biglietto, capsula, aggiornamentoSinistro

    var nome: String {
        switch self {
        case .prismaCliente: return "Il Prisma del cliente"
        case .film: return "Il film del piano"
        case .biglietto: return "Il biglietto del traguardo"
        case .capsula: return "La capsula del tempo"
        case .aggiornamentoSinistro: return "L'aggiornamento del sinistro"
        }
    }
}

/// Una cosa data al cliente: la traccia nel dossier.
struct UscitaCliente: Identifiable, Codable, Hashable {
    var id = "uscita-\(UUID().uuidString.prefix(8).lowercased())"
    var clienteId: String
    var genere: GenereUscita
    var quando: Date
    /// «PDF protetto · obiettivi, linea della vita, lettera».
    var descrizione: String
    /// Il servizio scelto nel foglio di condivisione («Messaggi», «AirDrop»…), nil se non noto.
    var via: String?
    /// La copia leggibile nei Documenti del cliente, se c'è (può non esserci più: la vista lo tollera).
    var documentoId: String?
    /// Uscito cifrato o protetto da password.
    var protetto: Bool
}
