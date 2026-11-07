import Foundation

// MARK: - Studio › Track record: le raccomandazioni registrate (versione 26 dell'archivio, «Orizzonte», giro 2)
// Specifica Design/template-novita-specifica.md §4. `DatiPrisma.raccomandazioni`: quando una proposta viene presentata
// Prisma registra una raccomandazione con le cifre dei motori di quel momento (StatoTrackRecord.swift). È un registro:
// IMMUTABILE. I campi registrati sono `let` e non hanno setter; si possono solo AGGIUNGERE note (con la data) e la
// scelta del cliente quando arriva (anche più volte: resta lo storico, vale l'ultima). Nessuna funzione toglie o cambia
// una nota o una scelta già registrata. StatoShell espone solo `registra`, `aggiungiNota` e `registraScelta`.

/// Una riga delle cifre del momento: etichetta e valore già scritto («Premio» · «450 € al mese»).
struct RigaRaccomandazione: Codable, Hashable {
    let etichetta: String
    let valore: String

    init(etichetta: String, valore: String) {
        self.etichetta = etichetta
        self.valore = valore
    }
}

/// Le cifre dei motori nel momento della raccomandazione: righe da mostrare e indicatori chiave numerici
/// (chiave → valore, per esempio «premioAnnuo», «sri», «adeguatezza.liquidita»).
struct CifreRaccomandazione: Codable, Hashable {
    let righe: [RigaRaccomandazione]
    let indicatori: [String: Double]

    init(righe: [RigaRaccomandazione] = [], indicatori: [String: Double] = [:]) {
        self.righe = righe
        self.indicatori = indicatori.filter { $0.value.isFinite }
    }

    private enum CodingKeys: String, CodingKey { case righe, indicatori }

    init(from decoder: Decoder) throws {
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self.init()
            return
        }
        let r = ((try? c.decodeIfPresent(ElencoTollerante<RigaRaccomandazione>.self, forKey: .righe)) ?? nil)?.elementi ?? []
        let i = ((try? c.decodeIfPresent([String: Double].self, forKey: .indicatori)) ?? nil) ?? [:]
        self.init(righe: r, indicatori: i)
    }
}

/// L'alternativa della raccomandazione: che cosa avrebbe fatto il cliente senza, e come ricostruirla.
struct AlternativaRaccomandazione: Codable, Hashable {
    enum Tipo: String, Codable, CaseIterable {
        /// Lo stesso capitale al ritmo di un riferimento (inflazione, TFR, gestioni separate, indice del consulente).
        case riferimento
        /// Lasciare com'è (la posizione che la proposta sostituisce, o i soldi dove sono).
        case lasciareComE
        /// Un'altra alternativa scritta a parole, senza un modo di ricostruirla.
        case altro
    }

    let tipo: Tipo
    /// «Lo stesso capitale al ritmo dell'inflazione», «Lasciare la polizza com'è».
    let descrizione: String
    /// L'id della `SerieRiferimento` con cui ricostruire l'alternativa (nil = non si ricostruisce: niente scarto).
    let serieRiferimento: String?
    /// La posizione che la proposta sostituisce, se c'è.
    let posizioneSostituitaId: String?
    /// true se l'ha ricavata Prisma (dalla scheda di adeguatezza o dal metro della posizione), non il consulente.
    let ricavata: Bool

    init(tipo: Tipo, descrizione: String, serieRiferimento: String? = nil, posizioneSostituitaId: String? = nil,
         ricavata: Bool) {
        self.tipo = tipo
        self.descrizione = descrizione
        self.serieRiferimento = serieRiferimento
        self.posizioneSostituitaId = posizioneSostituitaId
        self.ricavata = ricavata
    }

    /// Nessuna alternativa nota.
    static let nessuna = AlternativaRaccomandazione(tipo: .altro, descrizione: "", ricavata: true)

    private enum CodingKeys: String, CodingKey { case tipo, descrizione, serieRiferimento, posizioneSostituitaId, ricavata }

    init(from decoder: Decoder) throws {
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else {
            self.init(tipo: .altro, descrizione: "", ricavata: true)
            return
        }
        func leggi<T: Decodable>(_ k: CodingKeys) -> T? { (try? c.decodeIfPresent(T.self, forKey: k)) ?? nil }
        self.init(tipo: leggi(.tipo) ?? .altro, descrizione: leggi(.descrizione) ?? "", serieRiferimento: leggi(.serieRiferimento),
                  posizioneSostituitaId: leggi(.posizioneSostituitaId), ricavata: leggi(.ricavata) ?? true)
    }
}

/// La scelta del cliente su una raccomandazione.
enum SceltaCliente: String, Codable, CaseIterable, Identifiable {
    case accettata, rifiutata, inAttesa
    var id: String { rawValue }
    var nome: String {
        switch self {
        case .accettata: return "Accettata"
        case .rifiutata: return "Rifiutata"
        case .inAttesa: return "In attesa"
        }
    }
}

/// Una scelta del cliente registrata, con la data.
struct SceltaRegistrata: Codable, Hashable {
    let scelta: SceltaCliente
    let data: Date
}

/// Una nota aggiunta alla raccomandazione, con la data.
struct NotaRaccomandazione: Codable, Hashable {
    let data: Date
    let testo: String
}

/// Una raccomandazione registrata. I campi registrati non si cambiano: si aggiungono solo note e scelte.
struct Raccomandazione: Codable, Identifiable, Hashable {
    let id: String
    /// Quando è stata registrata (la presentazione della proposta).
    let data: Date
    let clienteId: String
    /// La proposta (posizione) collegata: una sola raccomandazione per proposta.
    let posizioneId: String?
    let canale: Canale?
    let area: AreaPosizione?
    /// Che cosa è stato proposto («Piano di risparmio da 450 € al mese»).
    let proposta: String
    /// Perché: la motivazione del consulente (scheda di adeguatezza), se scritta.
    let motivazione: String
    /// Perché: le cifre dei motori in quel momento.
    let cifre: CifreRaccomandazione
    let alternativa: AlternativaRaccomandazione
    /// Lo storico delle scelte del cliente (solo aggiunte; vale l'ultima).
    private(set) var scelte: [SceltaRegistrata]
    /// Le note aggiunte (solo aggiunte).
    private(set) var note: [NotaRaccomandazione]

    init(id: String = UUID().uuidString, data: Date, clienteId: String, posizioneId: String?, canale: Canale?,
         area: AreaPosizione?, proposta: String, motivazione: String, cifre: CifreRaccomandazione,
         alternativa: AlternativaRaccomandazione) {
        self.id = id
        self.data = data
        self.clienteId = clienteId
        self.posizioneId = posizioneId
        self.canale = canale
        self.area = area
        self.proposta = proposta
        self.motivazione = motivazione
        self.cifre = cifre
        self.alternativa = alternativa
        self.scelte = []
        self.note = []
    }

    /// La scelta del cliente: l'ultima registrata, altrimenti «in attesa».
    var scelta: SceltaCliente { scelte.last?.scelta ?? .inAttesa }
    /// Quando è arrivata la scelta (nil = nessuna ancora).
    var sceltaIl: Date? { scelte.last?.data }
    /// La prima volta che il cliente ha accettato (per «ancora in essere dopo 12 mesi»).
    var accettataIl: Date? { scelte.first { $0.scelta == .accettata }?.data }

    /// Aggiunge una nota (testo non vuoto). Le note di prima restano come sono.
    @discardableResult
    mutating func aggiungiNota(_ testo: String, il data: Date) -> Bool {
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pulito.isEmpty else { return false }
        note.append(NotaRaccomandazione(data: data, testo: pulito))
        return true
    }

    /// Registra la scelta del cliente; uguale all'ultima non si ripete. Le scelte di prima restano nello storico.
    @discardableResult
    mutating func registraScelta(_ s: SceltaCliente, il data: Date) -> Bool {
        guard scelte.last?.scelta != s else { return false }
        scelte.append(SceltaRegistrata(scelta: s, data: data))
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case id, data, clienteId, posizioneId, canale, area, proposta, motivazione, cifre, alternativa, scelte, note
    }

    /// Lettura tollerante: id, data e cliente sono necessari (senza, la raccomandazione si scarta); il resto, se
    /// illeggibile, diventa vuoto.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func leggi<T: Decodable>(_ k: CodingKeys) -> T? { (try? c.decodeIfPresent(T.self, forKey: k)) ?? nil }
        id = try c.decode(String.self, forKey: .id)
        data = try c.decode(Date.self, forKey: .data)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        posizioneId = leggi(.posizioneId)
        canale = leggi(.canale)
        area = leggi(.area)
        proposta = leggi(.proposta) ?? ""
        motivazione = leggi(.motivazione) ?? ""
        cifre = leggi(.cifre) ?? CifreRaccomandazione()
        alternativa = leggi(.alternativa) ?? .nessuna
        scelte = (leggi(.scelte) as ElencoTollerante<SceltaRegistrata>?)?.elementi ?? []
        note = (leggi(.note) as ElencoTollerante<NotaRaccomandazione>?)?.elementi ?? []
    }
}
