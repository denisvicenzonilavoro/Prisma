import Foundation

// «Vera su misura» (Vera/BRIEF.md, fase 5, funzione 22). Ogni tanto Vera impara il tuo modo di lavorare: gli esempi che
// hai approvato con 👍 (e le lezioni delle tue correzioni) diventano, resi anonimi e dopo la tua approvazione, un pacchetto
// che porti tu a un addestramento fuori dal Mac (Unsloth su una GPU gratuita in cloud, Vera/Addestramento). Prisma non fa
// nessuna richiesta di rete per questo. Il modello addestrato torna sul Mac, entra in Ollama (API locali, 127.0.0.1) e fa
// l'esame: le domande tenute da parte (mai uscite dal Mac) poste alla Vera di oggi e a quella nuova, un modello alla
// volta, con il punteggio calcolato dal codice. La nuova Vera prende il posto di quella di oggi solo se supera l'esame;
// si torna sempre alla versione di prima.

/// L'esito breve di un esame, salvato con la versione.
struct EsitoEsameBreve: Codable, Equatable {
    var domande: Int
    var percentualeAttuale: Int
    var percentualeNuova: Int
    var cifreInventateAttuale: Int
    var cifreInventateNuova: Int
    var fattoIl: Date
    var superato: Bool
}

/// Una versione addestrata di Vera (Impostazioni › Vera › Vera su misura). Letta con tolleranza.
struct VersioneSuMisura: Codable, Equatable, Identifiable {
    enum Stato: String, Codable {
        /// In Ollama, in attesa dell'esame.
        case importata
        /// Esame superato: si può usare.
        case superata
        /// Esame non superato: la sostituzione è bloccata.
        case nonSuperata
        /// È la Vera di adesso.
        case inUso
        /// Era in uso, poi sei tornato alla Vera di prima: resta in Ollama e si può riprovare.
        case ritirata
        /// Tolta da Ollama.
        case eliminata
    }

    /// Il nome in Ollama: «vera-su-misura:2026-11-08».
    var id: String
    var creataIl: Date
    /// Il modello da cui è partito l'addestramento («qwen3.5:4b»).
    var modelloDiPartenza: String
    var esempi: Int
    var stato: Stato
    var esame: EsitoEsameBreve?
    /// L'errore per passo da rapporto.json, al massimo 60 punti.
    var curva: [Double]?
    /// true = fac-simile (istantanee): la pagina scrive «Numeri di esempio».
    var diProva: Bool?

    init(id: String, creataIl: Date, modelloDiPartenza: String, esempi: Int, stato: Stato) {
        self.id = id
        self.creataIl = creataIl
        self.modelloDiPartenza = modelloDiPartenza
        self.esempi = esempi
        self.stato = stato
    }

    private enum CodingKeys: String, CodingKey { case id, creataIl, modelloDiPartenza, esempi, stato, esame, curva, diProva }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Senza id o con uno stato sconosciuto la versione si scarta (ElencoTollerante tiene le altre)
        id = try c.decode(String.self, forKey: .id)
        stato = try c.decode(Stato.self, forKey: .stato)
        guard !id.isEmpty else { throw DecodingError.dataCorruptedError(forKey: .id, in: c, debugDescription: "versione senza nome") }
        creataIl = (try? c.decodeIfPresent(Date.self, forKey: .creataIl)) ?? Date(timeIntervalSince1970: 0)
        modelloDiPartenza = (try? c.decodeIfPresent(String.self, forKey: .modelloDiPartenza)) ?? MotoreLocale.modelloPredefinito
        esempi = max(0, (try? c.decodeIfPresent(Int.self, forKey: .esempi)) ?? 0)
        esame = (try? c.decodeIfPresent(EsitoEsameBreve.self, forKey: .esame)) ?? nil
        curva = (try? c.decodeIfPresent([Double].self, forKey: .curva)) ?? nil
        diProva = (try? c.decodeIfPresent(Bool.self, forKey: .diProva)) ?? nil
    }
}

/// Lo stato salvato di «Vera su misura» (dentro ImpostazioniVera: niente nell'istantanea di Prisma ovunque, che azzera `vera`).
struct ImpostazioniSuMisura: Codable, Equatable {
    /// Al massimo `SuMisuraVera.massimoVersioni`.
    var versioni: [VersioneSuMisura] = []
    /// Il modello di prima, per «Torna alla Vera di prima».
    var modelloPrecedente: String?
    /// Gli id degli EsempioVera tenuti per l'esame: non entrano mai nel pacchetto.
    var esame: [String] = []
    /// Gli id già esportati in un pacchetto (al massimo `MemoriaVera.massimoEsempi`): non entrano mai nell'esame.
    var usati: [String] = []
    var ultimoPacchetto: Date?
    var esempiNelPacchetto = 0

    init() {}

    private enum CodingKeys: String, CodingKey { case versioni, modelloPrecedente, esame, usati, ultimoPacchetto, esempiNelPacchetto }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        versioni = Array((((try? c.decodeIfPresent(ElencoTollerante<VersioneSuMisura>.self, forKey: .versioni)) ?? nil)?.elementi ?? [])
            .suffix(SuMisuraVera.massimoVersioni))
        modelloPrecedente = (try? c.decodeIfPresent(String.self, forKey: .modelloPrecedente)) ?? nil
        esame = (try? c.decodeIfPresent([String].self, forKey: .esame)) ?? []
        usati = Array(((try? c.decodeIfPresent([String].self, forKey: .usati)) ?? []).suffix(MemoriaVera.massimoEsempi))
        ultimoPacchetto = (try? c.decodeIfPresent(Date.self, forKey: .ultimoPacchetto)) ?? nil
        esempiNelPacchetto = max(0, (try? c.decodeIfPresent(Int.self, forKey: .esempiNelPacchetto)) ?? 0)
    }

    /// La versione in uso, se c'è.
    var inUso: VersioneSuMisura? { versioni.last { $0.stato == .inUso } }
}

enum SuMisuraVera {
    static let prefissoModello = "vera-su-misura"
    /// Sotto questo numero di esempi pronti il pacchetto non si prepara (da confermare con l'utente).
    static let minimoEsempi = 60
    /// La parte degli esempi tenuta per l'esame, tra un minimo e un massimo di domande.
    static let quotaEsame = 0.2
    static let minimoEsame = 12
    static let massimoEsame = 80
    static let massimoVersioni = 6
    static let nomeFileAddestramento = "addestramento.jsonl"
    static let nomeFileManifesto = "manifest.json"
    static let nomeFileRapporto = "rapporto.json"
    static let nomeNotebook = "vera-su-misura.ipynb"
    static let nomeScript = "addestra.py"
    static let quantizzazione = "q4_k_m"
    /// I punti della curva dell'errore tenuti con la versione.
    static let puntiCurva = 60
}
