import Foundation

// MARK: - Territorio («Luce» giro 11, §5.1 «Il tuo territorio»)
//
// Modelli dell'archivio (versione 27, letti con tolleranza) e della tabella dei comuni delle risorse.
// Tutto locale (decisioni 20, 21, 22): nessuna richiesta di rete, niente servizi di mappe o percorsi, niente CAP.

/// Una coordinata geografica (gradi decimali, WGS84).
struct Coordinata: Codable, Hashable {
    var lat: Double
    var lon: Double

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    /// Una coordinata con numeri finiti e dentro i limiti della Terra.
    var valida: Bool { lat.isFinite && lon.isFinite && (-90...90).contains(lat) && (-180...180).contains(lon) }
}

/// La posizione di un cliente (o della partenza del giro) messa a mano dal consulente (versione 27, «Luce» giro 11).
struct LuogoManuale: Codable, Hashable {
    var coordinata: Coordinata
    var nota: String = ""

    init(coordinata: Coordinata, nota: String = "") {
        self.coordinata = coordinata
        self.nota = nota
    }

    private enum CodingKeys: String, CodingKey { case coordinata, nota }

    /// Lettura tollerante: una coordinata non valida è un errore (chi legge con `try?` scarta il luogo e torna al comune).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let coordinata = try c.decode(Coordinata.self, forKey: .coordinata)
        guard coordinata.valida else {
            throw DecodingError.dataCorruptedError(forKey: .coordinata, in: c, debugDescription: "Coordinata fuori scala")
        }
        self.coordinata = coordinata
        nota = ((try? c.decodeIfPresent(String.self, forKey: .nota)) ?? nil) ?? ""
    }
}

/// Una zona dell'utente: un nome e i comuni che la compongono (decisione 127). Senza zone, la zona è il comune.
struct ZonaTerritorio: Codable, Hashable, Identifiable {
    var id: String
    var nome: String
    /// I codici della tabella dei comuni («BO-bologna»).
    var comuni: [String]

    init(id: String, nome: String, comuni: [String]) {
        self.id = id
        self.nome = nome
        self.comuni = comuni
    }

    private enum CodingKeys: String, CodingKey { case id, nome, comuni }

    /// Lettura tollerante: una zona senza id si scarta (errore), nome e comuni illeggibili diventano vuoti.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = try c.decode(String.self, forKey: .id)
        guard !id.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: c, debugDescription: "Zona senza id")
        }
        self.id = id
        nome = ((try? c.decodeIfPresent(String.self, forKey: .nome)) ?? nil) ?? ""
        comuni = ((try? c.decodeIfPresent([String].self, forKey: .comuni)) ?? nil) ?? []
    }
}

/// Impostazioni › Territorio (`Impostazioni.territorio`, versione 27). I valori di base sono le proposte della specifica
/// §5.1.3, dichiarati «stima» nell'interfaccia (decisione 22). Lettura tollerante: un valore fuori scala torna al
/// predefinito, le altre impostazioni restano.
struct ImpostazioniTerritorio: Codable, Equatable {
    /// Linea d'aria × fattore strada = km stimati.
    var fattoreStrada = ImpostazioniTerritorio.fattorePredefinito
    /// km/h nei tratti dentro lo stesso comune.
    var velocitaCitta = ImpostazioniTerritorio.velocitaCittaPredefinita
    /// km/h nei tratti fra comuni diversi.
    var velocitaFuori = ImpostazioniTerritorio.velocitaFuoriPredefinita
    /// Un tratto non dura mai meno di così (parcheggio, uscita).
    var minutiMinimiTratto = ImpostazioniTerritorio.minutiMinimiPredefiniti
    /// La deviazione massima, in minuti, per proporre un cliente «lungo la strada».
    var deviazioneMassima = ImpostazioniTerritorio.deviazionePredefinita
    /// La durata della visita breve proposta dal Territorio.
    var durataVisitaBreve = ImpostazioniTerritorio.visitaBrevePredefinita
    /// Le zone dell'utente (gruppi di comuni). Vuoto = le zone sono i comuni.
    var zone: [ZonaTerritorio] = []
    /// I tipi di `Attenzione` che accendono l'anello arancio (rawValue di `Attenzione.Tipo`; decisione 99 «attenzioni
    /// alte»). Vuoto di base finché l'utente non sceglie; valori sconosciuti scartati in lettura.
    var attenzioniAlte: [Int] = []
    /// La partenza del giro messa a mano, se non è la sede dello studio. nil = non impostata.
    var partenza: LuogoManuale?
    /// Il codice del comune della partenza scelto dall'elenco (alternativa a `partenza`).
    var comunePartenza: String?

    static let fattorePredefinito = 1.3
    static let velocitaCittaPredefinita = 40.0
    static let velocitaFuoriPredefinita = 70.0
    static let minutiMinimiPredefiniti = 5
    static let deviazionePredefinita = 10
    static let visitaBrevePredefinita = 30

    static let scalaFattore: ClosedRange<Double> = 1...3
    static let scalaVelocita: ClosedRange<Double> = 5...130
    static let scalaMinutiMinimi: ClosedRange<Int> = 0...60
    static let scalaDeviazione: ClosedRange<Int> = 1...60
    static let scalaVisitaBreve: ClosedRange<Int> = 10...180

    init() {}

    private enum CodingKeys: String, CodingKey {
        case fattoreStrada, velocitaCitta, velocitaFuori, minutiMinimiTratto, deviazioneMassima, durataVisitaBreve
        case zone, attenzioniAlte, partenza, comunePartenza
    }

    /// Lettura tollerante: un numero illeggibile, non finito o fuori scala torna al predefinito; una zona illeggibile si
    /// scarta (le altre restano); i tipi di attenzione sconosciuti si scartano; una partenza non valida diventa nil.
    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        func numero(_ k: CodingKeys, _ scala: ClosedRange<Double>, _ base: Double) -> Double {
            guard let v = (try? c.decodeIfPresent(Double.self, forKey: k)) ?? nil, v.isFinite, scala.contains(v) else { return base }
            return v
        }
        func intero(_ k: CodingKeys, _ scala: ClosedRange<Int>, _ base: Int) -> Int {
            guard let v = (try? c.decodeIfPresent(Int.self, forKey: k)) ?? nil, scala.contains(v) else { return base }
            return v
        }
        fattoreStrada = numero(.fattoreStrada, Self.scalaFattore, Self.fattorePredefinito)
        velocitaCitta = numero(.velocitaCitta, Self.scalaVelocita, Self.velocitaCittaPredefinita)
        velocitaFuori = numero(.velocitaFuori, Self.scalaVelocita, Self.velocitaFuoriPredefinita)
        minutiMinimiTratto = intero(.minutiMinimiTratto, Self.scalaMinutiMinimi, Self.minutiMinimiPredefiniti)
        deviazioneMassima = intero(.deviazioneMassima, Self.scalaDeviazione, Self.deviazionePredefinita)
        durataVisitaBreve = intero(.durataVisitaBreve, Self.scalaVisitaBreve, Self.visitaBrevePredefinita)
        zone = ((try? c.decodeIfPresent(ElencoTollerante<ZonaTerritorio>.self, forKey: .zone)) ?? nil)?.elementi ?? []
        let tipi = ((try? c.decodeIfPresent(ElencoTollerante<Int>.self, forKey: .attenzioniAlte)) ?? nil)?.elementi ?? []
        var visti = Set<Int>()
        attenzioniAlte = tipi.filter { Attenzione.Tipo(rawValue: $0) != nil && visti.insert($0).inserted }
        partenza = (try? c.decodeIfPresent(LuogoManuale.self, forKey: .partenza)) ?? nil
        comunePartenza = ((try? c.decodeIfPresent(String.self, forKey: .comunePartenza)) ?? nil).flatMap { $0.isEmpty ? nil : $0 }
    }
}

// MARK: - La tabella dei comuni (risorsa, non archivio)

/// Una riga della tabella dei comuni. Mai il codice catastale (decisione 70).
struct ComuneTabella: Hashable {
    /// «<SIGLA>-<nome normalizzato>», per esempio «BO-bologna»: lo stesso nella tabella di prova e in quella ISTAT.
    let codice: String
    let nome: String
    /// La sigla della provincia, due lettere.
    let provincia: String
    let centro: Coordinata
    /// √(area/π): serve per sparpagliare i clienti dello stesso comune.
    let raggioKm: Double
}

/// La tabella dei comuni delle risorse (`Risorse/Territorio/comuni.json`).
struct TabellaComuni {
    let fonte: String
    let licenza: String
    let edizione: String
    /// Vero per la tabella ridotta di prova (32 comuni, coordinate approssimate a mano: non ISTAT).
    let diProva: Bool
    let comuni: [ComuneTabella]
    let perCodice: [String: ComuneTabella]
    /// Nome normalizzato → comuni (più di uno = omonimi in province diverse).
    let perNome: [String: [ComuneTabella]]

    init(fonte: String, licenza: String, edizione: String, diProva: Bool, comuni: [ComuneTabella]) {
        self.fonte = fonte
        self.licenza = licenza
        self.edizione = edizione
        self.diProva = diProva
        self.comuni = comuni
        var codici: [String: ComuneTabella] = [:]
        var nomi: [String: [ComuneTabella]] = [:]
        for c in comuni {
            codici[c.codice] = c
            nomi[TabellaTerritorio.normalizza(c.nome), default: []].append(c)
        }
        perCodice = codici
        perNome = nomi
    }
}

/// I confini di una provincia (`Risorse/Territorio/confini/<SIGLA>.json`): per codice del comune, gli anelli come
/// lat e lon alternati ([lat0, lon0, lat1, lon1, …]).
struct ConfiniProvincia: Decodable {
    let provincia: String
    let diProva: Bool
    let comuni: [String: [[Double]]]
}
