import Foundation

/// Le serie pubbliche che Mercato sa scaricare: chiavi della BCE (Data Portal, SDMX) e codici di Eurostat
/// (dissemination API, JSON-stat). Non stanno nel codice ma in un file di configurazione modificabile:
/// `Sources/Prisma/Risorse/Mercato/serie-mercato.json` (nel pacchetto dell'app) oppure, se il consulente lo mette,
/// `~/Library/Application Support/Prisma/serie-mercato.json`, che vale al posto di quello del pacchetto.
/// Una chiave che non rispetta la forma dei codici pubblici si scarta (ClienteMercato.richiesta non la manda).
struct ConfigurazioneMercato: Codable, Equatable {
    /// Una serie da scaricare.
    struct Serie: Codable, Equatable, Identifiable {
        /// L'id locale (diventa `SerieMercato.id`).
        var id: String
        var nome: String
        /// Da chi si scarica: solo `bce` o `eurostat`.
        var fonte: OrigineDatoMercato
        /// BCE: la chiave completa con il flusso davanti («FM.D.U2.EUR.4F.KR.DFR.LEV»). Eurostat: il codice del
        /// dataset («prc_hicp_manr»).
        var codice: String
        /// Eurostat: i filtri delle dimensioni («geo»: «IT», «coicop»: «CP00»). Solo codici pubblici.
        var filtri: [String: String]?
        var unita: UnitaMercato
        var frequenza: FrequenzaMercato
        var tipo: TipoSerieMercato
        /// Il dato è di terzi, ridistribuito dalla fonte (Euribor: EMMI; Euro Stoxx 50: STOXX).
        var terzi: String?
        /// Una nota per chi modifica il file (non entra nei calcoli).
        var nota: String?
    }

    /// Una serie ricavata da altre due: `da` meno `meno`, sulle stesse date (lo spread BTP-Bund).
    struct Calcolata: Codable, Equatable, Identifiable {
        var id: String
        var nome: String
        var da: String
        var meno: String
        var unita: UnitaMercato
        var tipo: TipoSerieMercato
    }

    var versione: Int
    var serie: [Serie]
    var calcolate: [Calcolata]

    init(versione: Int = 1, serie: [Serie], calcolate: [Calcolata] = []) {
        self.versione = versione
        self.serie = serie
        self.calcolate = calcolate
    }

    private enum CodingKeys: String, CodingKey { case versione, serie, calcolate }

    /// Lettura tollerante: una serie scritta male si scarta, le altre restano.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        versione = ((try? c.decodeIfPresent(Int.self, forKey: .versione)) ?? nil) ?? 1
        serie = (((try? c.decodeIfPresent(ElencoTollerante<Serie>.self, forKey: .serie)) ?? nil)?.elementi ?? [])
            .filter { $0.fonte.scaricato }
        calcolate = ((try? c.decodeIfPresent(ElencoTollerante<Calcolata>.self, forKey: .calcolate)) ?? nil)?.elementi ?? []
    }

    static let nomeFile = "serie-mercato.json"

    /// Il file del consulente, che vale al posto di quello del pacchetto.
    static var filePersonale: URL { Archivio.cartella.appendingPathComponent(nomeFile) }

    /// Il file del pacchetto dell'app.
    static var fileDelPacchetto: URL? { Risorse.cartella?.appendingPathComponent("Mercato/\(nomeFile)") }

    /// La configurazione da usare: quella del consulente se c'è e si legge, altrimenti quella del pacchetto
    /// (nil se nemmeno quella si legge).
    static func carica() -> ConfigurazioneMercato? {
        if let dati = try? Data(contentsOf: filePersonale), let c = leggi(dati), !c.serie.isEmpty { return c }
        return caricaDelPacchetto()
    }

    static func caricaDelPacchetto() -> ConfigurazioneMercato? {
        guard let url = fileDelPacchetto, let dati = try? Data(contentsOf: url) else { return nil }
        return leggi(dati)
    }

    static func leggi(_ dati: Data) -> ConfigurazioneMercato? {
        try? JSONDecoder().decode(ConfigurazioneMercato.self, from: dati)
    }

    func serie(_ id: String) -> Serie? { serie.first { $0.id == id } }

    /// Le serie da scaricare con le scelte dell'utente: tutte (nil) o quelle scelte, nell'ordine scelto.
    func attive(_ impostazioni: ImpostazioniMercato) -> [Serie] {
        guard let scelte = impostazioni.serieAttive else { return serie }
        return scelte.compactMap { id in serie.first { $0.id == id } }
    }
}
