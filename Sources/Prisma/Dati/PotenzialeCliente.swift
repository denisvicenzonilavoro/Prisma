import Foundation

// I potenziali clienti di Clienti › Potenziali («Luce» giro 12, Design/template-luce-specifica.md §9.2): persone che non
// sono ancora clienti, con la fonte (chi le ha presentate o un testo libero), una stima facoltativa del patrimonio, la
// probabilità e la data di chiusura scritte dall'utente (decisione 94: nessun valore per fase), l'informativa ai terzi e
// il consenso al contatto (decisione 39). Stanno in `DatiPrisma.potenziali` (archivio versione 27, sezione «relazione»),
// entrano nel backup e in «Prisma ovunque» solo con l'interruttore apposito (`ImpostazioniOvunque.potenzialiNelloSpazio`).

/// La fase di un potenziale cliente nel percorso (Clienti › Potenziali, «Luce» giro 12).
enum FasePotenziale: String, Codable, CaseIterable, Identifiable {
    case daContattare, primoIncontro, analisi, proposta, cliente, nonInteressato

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .daContattare: return "Da contattare"
        case .primoIncontro: return "Primo incontro"
        case .analisi: return "Analisi"
        case .proposta: return "Proposta"
        case .cliente: return "Cliente"
        case .nonInteressato: return "Non interessato"
        }
    }

    /// Le cinque colonne del percorso (senza «Non interessato»).
    static let colonne: [FasePotenziale] = [.daContattare, .primoIncontro, .analisi, .proposta, .cliente]

    /// Il passo dopo: da contattare → primo incontro → analisi → proposta → cliente. Cliente e non interessato: nil.
    var successiva: FasePotenziale? {
        switch self {
        case .daContattare: return .primoIncontro
        case .primoIncontro: return .analisi
        case .analisi: return .proposta
        case .proposta: return .cliente
        case .cliente, .nonInteressato: return nil
        }
    }

    /// Il passo prima. Da contattare: nil; non interessato torna a «Da contattare» (ripristino).
    var precedente: FasePotenziale? {
        switch self {
        case .daContattare: return nil
        case .primoIncontro: return .daContattare
        case .analisi: return .primoIncontro
        case .proposta: return .analisi
        case .cliente: return .proposta
        case .nonInteressato: return .daContattare
        }
    }
}

/// Un passaggio di fase con la sua data (la storia del potenziale nel dettaglio).
struct CambioFase: Codable, Hashable {
    var fase: FasePotenziale
    var il: Date

    init(fase: FasePotenziale, il: Date) {
        self.fase = fase
        self.il = il
    }

    private enum CodingKeys: String, CodingKey { case fase, il }

    /// Lettura tollerante: senza data si scarta (ElencoTollerante tiene gli altri); fase sconosciuta → da contattare.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        il = try c.decode(Date.self, forKey: .il)
        let grezza = (try? c.decodeIfPresent(String.self, forKey: .fase)) ?? nil
        fase = grezza.flatMap { FasePotenziale(rawValue: $0) } ?? .daContattare
    }
}

/// Un potenziale cliente (versione 27 dell'archivio, `DatiPrisma.potenziali`).
struct PotenzialeCliente: Identifiable, Codable, Hashable {
    /// "pot-<uuid8>"; quelli di prova "pot-prova-<chiave>".
    var id: String
    var nome: String
    var email = ""
    var telefono = ""
    /// L'id del cliente che l'ha presentato (nil = nessuno o fonte libera).
    var presentatoDa: String?
    /// La fonte quando non è un cliente («dal sito dello studio»).
    var fonte: String?
    /// nil = non stimato (mai 0 di ripiego).
    var patrimonioStimato: Double?
    /// 0…100, scritta dall'utente (nessun valore per fase: decisione 94).
    var probabilita: Int?
    var chiusuraPrevista: Date?
    var fase: FasePotenziale = .daContattare
    var storia: [CambioFase] = []
    /// Quando è stata data l'informativa ai terzi (decisione 39). nil = da dare: niente «Scrivigli».
    var informativaIl: Date?
    /// Consenso a essere contattato (decisione 39). nil = non chiesto.
    var consensoContatto: Bool?
    /// Il cliente nato da questo potenziale (quando il dossier è stato creato).
    var clienteId: String?
    var nota = ""
    /// Al secondo, come le altre date dell'archivio: torna identico dal backup.
    var creatoIl: Date
    /// Dati di prova dichiarati: si tolgono con i clienti di prova.
    var diProva = false

    init(id: String = "pot-\(UUID().uuidString.prefix(8).lowercased())", nome: String,
         creatoIl: Date = MessaggioCliente.adesso) {
        self.id = id
        self.nome = nome
        self.creatoIl = creatoIl
    }

    /// Pronto per «Scrivigli»: informativa data e consenso al contatto.
    var contattabile: Bool { informativaIl != nil && consensoContatto == true }

    /// Ha stima e probabilità: entra nei totali.
    var stimato: Bool { patrimonioStimato != nil && probabilita != nil }

    private enum CodingKeys: String, CodingKey {
        case id, nome, email, telefono, presentatoDa, fonte, patrimonioStimato, probabilita, chiusuraPrevista, fase, storia
        case informativaIl, consensoContatto, clienteId, nota, creatoIl, diProva
    }

    /// Lettura tollerante: senza id o nome si scarta (ElencoTollerante tiene gli altri); fase sconosciuta → da contattare;
    /// probabilità fuori 0…100 → nil; stima negativa o non finita → nil; stringhe vuote → nil.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        nome = try c.decode(String.self, forKey: .nome)
        guard !id.isEmpty, !nome.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .nome, in: c, debugDescription: "Potenziale senza id o nome")
        }
        email = ((try? c.decodeIfPresent(String.self, forKey: .email)) ?? nil) ?? ""
        telefono = ((try? c.decodeIfPresent(String.self, forKey: .telefono)) ?? nil) ?? ""
        presentatoDa = ((try? c.decodeIfPresent(String.self, forKey: .presentatoDa)) ?? nil).flatMap { $0.isEmpty ? nil : $0 }
        fonte = ((try? c.decodeIfPresent(String.self, forKey: .fonte)) ?? nil).flatMap { $0.isEmpty ? nil : $0 }
        patrimonioStimato = ((try? c.decodeIfPresent(Double.self, forKey: .patrimonioStimato)) ?? nil)
            .flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
        probabilita = ((try? c.decodeIfPresent(Int.self, forKey: .probabilita)) ?? nil).flatMap { (0...100).contains($0) ? $0 : nil }
        chiusuraPrevista = (try? c.decodeIfPresent(Date.self, forKey: .chiusuraPrevista)) ?? nil
        let grezza = (try? c.decodeIfPresent(String.self, forKey: .fase)) ?? nil
        fase = grezza.flatMap { FasePotenziale(rawValue: $0) } ?? .daContattare
        storia = ((try? c.decodeIfPresent(ElencoTollerante<CambioFase>.self, forKey: .storia)) ?? nil)?.elementi ?? []
        informativaIl = (try? c.decodeIfPresent(Date.self, forKey: .informativaIl)) ?? nil
        consensoContatto = (try? c.decodeIfPresent(Bool.self, forKey: .consensoContatto)) ?? nil
        clienteId = ((try? c.decodeIfPresent(String.self, forKey: .clienteId)) ?? nil).flatMap { $0.isEmpty ? nil : $0 }
        nota = ((try? c.decodeIfPresent(String.self, forKey: .nota)) ?? nil) ?? ""
        creatoIl = ((try? c.decodeIfPresent(Date.self, forKey: .creatoIl)) ?? nil) ?? MessaggioCliente.adesso
        diProva = ((try? c.decodeIfPresent(Bool.self, forKey: .diProva)) ?? nil) ?? false
    }
}
