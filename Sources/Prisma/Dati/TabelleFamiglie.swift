import Foundation

// «Rispetto alle famiglie come la sua» (Analisi 360, Orizzonte giro 6, specifica §10): le tabelle aggregate delle
// famiglie italiane. Due forme dello stesso formato «prisma-famiglie» (Design/famiglie-formato.md):
// - versione 2 (quella in uso): tavole a una dimensione, come le pubblica la Banca d'Italia. Gruppi «età» e
//   «quinto di reddito» (più «tutte» per la distribuzione complessiva), ciascuno con le sue classi e per ogni classe le
//   voci disponibili con il tipo di statistica (rapporto tra medie, media, mediana, quota %, quantili). Il file
//   incluso è `Risorse/famiglie-bdi-2022.json`, convertito dalle tavole pubblicate con
//   Supporto/famiglie/converti_bdi.py: sono le tabelle predefinite;
// - versione 1 (resta leggibile): celle età × reddito con i quantili. `Risorse/famiglie-di-prova.json` è in questa
//   forma, dichiaratamente «dati di prova» con valori segnaposto: serve solo alle prove.
// Le tabelle caricate dal consulente da Impostazioni stanno nell'archivio (`DatiPrisma.famiglie`, versione 26) e quindi
// nel backup, e prevalgono su quelle incluse.

/// Le voci del confronto, sempre in questo ordine.
enum VoceFamiglie: String, Codable, CaseIterable, Identifiable {
    /// Risparmio annuo in percentuale del reddito familiare netto.
    case tassoRisparmio
    /// Attività finanziarie della famiglia, in euro.
    case ricchezzaFinanziaria
    /// Ricchezza netta della famiglia (attività reali e finanziarie meno i debiti), in euro.
    case ricchezzaNetta
    /// Protezione: nella versione 1 quota di famiglie con polizze vita o danni (o i premi annui in euro); nella
    /// versione 2 quota di famiglie con polizze vita (le tavole della Banca d'Italia non hanno i danni).
    case protezione
    /// Previdenza complementare: quota di famiglie che aderiscono (pensioni integrative), o i contributi annui in euro.
    case previdenzaComplementare

    var id: String { rawValue }
}

/// Un quantile di una distribuzione: percentile (10 = p10) e valore.
struct QuantileFamiglie: Equatable {
    let percentile: Double
    let valore: Double
}

/// La distribuzione di una voce: i quantili disponibili (quartili, decimi), la media e la quota. Tutto facoltativo:
/// la fonte può dare solo la mediana, solo la media o solo la quota delle famiglie che hanno la cosa.
struct DistribuzioneFamiglie: Codable, Equatable {
    var p10: Double?
    var p20: Double?
    var p25: Double?
    var p30: Double?
    var p40: Double?
    var p50: Double?
    var p60: Double?
    var p70: Double?
    var p75: Double?
    var p80: Double?
    var p90: Double?
    var media: Double?
    /// Quota delle famiglie che hanno la cosa (0-100): per la protezione e la previdenza complementare.
    var quota: Double?

    init(p10: Double? = nil, p20: Double? = nil, p25: Double? = nil, p30: Double? = nil, p40: Double? = nil,
         p50: Double? = nil, p60: Double? = nil, p70: Double? = nil, p75: Double? = nil, p80: Double? = nil,
         p90: Double? = nil, media: Double? = nil, quota: Double? = nil) {
        self.p10 = p10
        self.p20 = p20
        self.p25 = p25
        self.p30 = p30
        self.p40 = p40
        self.p50 = p50
        self.p60 = p60
        self.p70 = p70
        self.p75 = p75
        self.p80 = p80
        self.p90 = p90
        self.media = media
        self.quota = quota
    }

    /// I quantili presenti, dal più basso.
    var quantili: [QuantileFamiglie] {
        let tutti: [(Double, Double?)] = [(10, p10), (20, p20), (25, p25), (30, p30), (40, p40), (50, p50),
                                          (60, p60), (70, p70), (75, p75), (80, p80), (90, p90)]
        return tutti.compactMap { p, v in v.map { QuantileFamiglie(percentile: p, valore: $0) } }
    }

    /// Nessun dato in questa voce.
    var vuota: Bool { quantili.isEmpty && media == nil && quota == nil }
}

/// Una classe d'età (anni compiuti, estremi inclusi) o di reddito familiare netto annuo (euro, `da` incluso e
/// `a` escluso). `da` nil = dal basso, `a` nil = senza limite in alto.
struct ClasseFamiglie: Codable, Equatable, Identifiable {
    var id: String
    var nome: String?
    var da: Double?
    var a: Double?
}

/// Una cella età × reddito (versione 1): il numero di famiglie del campione e le voci.
struct CellaFamiglie: Codable, Equatable {
    var eta: String
    var reddito: String
    /// Famiglie del campione nella cella (nil = la fonte non lo dice).
    var famiglie: Int?
    var tassoRisparmio: DistribuzioneFamiglie?
    var ricchezzaFinanziaria: DistribuzioneFamiglie?
    var ricchezzaNetta: DistribuzioneFamiglie?
    var protezione: DistribuzioneFamiglie?
    var previdenzaComplementare: DistribuzioneFamiglie?

    func distribuzione(_ v: VoceFamiglie) -> DistribuzioneFamiglie? {
        switch v {
        case .tassoRisparmio: return tassoRisparmio
        case .ricchezzaFinanziaria: return ricchezzaFinanziaria
        case .ricchezzaNetta: return ricchezzaNetta
        case .protezione: return protezione
        case .previdenzaComplementare: return previdenzaComplementare
        }
    }
}

// MARK: Versione 2: tavole a una dimensione

/// La caratteristica del capofamiglia che divide un gruppo (versione 2).
enum DimensioneFamiglie: String, Codable, CaseIterable {
    /// Classi d'età del capofamiglia.
    case eta
    /// Classi (quinti) di reddito familiare netto.
    case reddito
    /// Tutte le famiglie insieme: una sola classe senza estremi (per esempio i decimi della ricchezza netta).
    case tutte
}

/// Il tipo di statistica di una voce (versione 2).
enum StatisticaFamiglie: String, Codable {
    /// Rapporto tra due medie del gruppo (per esempio risparmio medio ÷ reddito medio, in %): non è la media dei
    /// rapporti delle singole famiglie.
    case rapportoTraMedie
    /// Media del gruppo.
    case media
    /// Mediana del gruppo: metà delle famiglie sta sotto, metà sopra.
    case mediana
    /// Percentuale delle famiglie del gruppo che hanno la cosa (0-100).
    case quota
    /// Quantili della distribuzione del gruppo (`quantili`, almeno due).
    case quantili
}

/// Il valore di una voce in una classe (versione 2): il tipo di statistica, il valore (o i quantili) e da quale
/// tavola viene.
struct ValoreFamiglie: Codable, Equatable {
    var statistica: StatisticaFamiglie
    /// Il valore: % per il tasso di risparmio e per la quota, euro per la ricchezza. Con `quantili`, facoltativo.
    var valore: Double?
    /// Con la statistica `quantili`.
    var quantili: DistribuzioneFamiglie?
    /// La tavola della fonte (per esempio «T4»).
    var tavola: String?
    var nota: String?

    init(statistica: StatisticaFamiglie, valore: Double? = nil, quantili: DistribuzioneFamiglie? = nil,
         tavola: String? = nil, nota: String? = nil) {
        self.statistica = statistica
        self.valore = valore
        self.quantili = quantili
        self.tavola = tavola
        self.nota = nota
    }

    /// La stessa cifra nella forma del confronto: mediana come p50, media e rapporto come media, la quota come quota.
    var distribuzione: DistribuzioneFamiglie {
        switch statistica {
        case .rapportoTraMedie, .media: return DistribuzioneFamiglie(media: valore)
        case .mediana: return DistribuzioneFamiglie(p50: valore)
        case .quota: return DistribuzioneFamiglie(quota: valore)
        case .quantili: return quantili ?? DistribuzioneFamiglie()
        }
    }
}

/// Una classe di un gruppo (versione 2): gli estremi, le famiglie del campione e le voci disponibili (chiave =
/// `VoceFamiglie.rawValue`).
struct ClasseGruppoFamiglie: Codable, Equatable, Identifiable {
    var id: String
    var nome: String?
    var da: Double?
    var a: Double?
    /// Famiglie del campione nella classe (nil = la fonte non lo dice).
    var famiglie: Int?
    var voci: [String: ValoreFamiglie]

    /// Gli estremi come classe del confronto.
    var classe: ClasseFamiglie { ClasseFamiglie(id: id, nome: nome, da: da, a: a) }

    func valore(_ v: VoceFamiglie) -> ValoreFamiglie? { voci[v.rawValue] }
}

/// Un gruppo (versione 2): una caratteristica del capofamiglia e le sue classi.
struct GruppoFamiglie: Codable, Equatable, Identifiable {
    var id: String
    var dimensione: DimensioneFamiglie
    var nome: String?
    var nota: String?
    var classi: [ClasseGruppoFamiglie]
}

/// Il file delle tabelle (formato «prisma-famiglie», versione 1 o 2).
struct TabelleFamiglie: Codable, Equatable {
    static let formatoAtteso = "prisma-famiglie"
    /// Le versioni che Prisma legge; la 2 è quella in uso.
    static let versioniLette = [1, 2]
    static let versioneAttuale = 2
    /// Le tabelle predefinite incluse nell'app (tavole pubblicate dalla Banca d'Italia), nella cartella Risorse.
    static let filePredefinito = "famiglie-bdi-2022.json"
    /// Il file di prova (versione 1, valori segnaposto), nella cartella Risorse: solo per le prove.
    static let fileDiProva = "famiglie-di-prova.json"

    var formato: String
    var versione: Int
    /// Fonte delle tabelle (per esempio il nome dell'indagine e l'ente), in chiaro.
    var fonte: String
    /// Anno dell'indagine (nil = non indicato).
    var edizione: Int?
    /// Aggiornamento della pubblicazione (per esempio «ottobre 2025»), in chiaro.
    var aggiornamento: String?
    var licenza: String?
    var note: String?
    /// true = dati di prova, non statistiche: la vista lo scrive in chiaro.
    var diProva: Bool
    /// Sotto quante famiglie nel campione il confronto è solo indicativo (nil = `MotoreFamiglie.sogliaPredefinita`).
    var sogliaFamiglie: Int?
    /// Che cosa misura ogni voce, con l'unità (chiave = `VoceFamiglie.rawValue`).
    var descrizioni: [String: String]?
    /// Versione 1: classi e celle età × reddito (vuote nella versione 2).
    var classiEta: [ClasseFamiglie]
    var classiReddito: [ClasseFamiglie]
    var celle: [CellaFamiglie]
    /// Versione 2: i gruppi a una dimensione (vuoti nella versione 1).
    var gruppi: [GruppoFamiglie]

    init(formato: String = TabelleFamiglie.formatoAtteso, versione: Int, fonte: String, edizione: Int? = nil,
         aggiornamento: String? = nil, licenza: String? = nil, note: String? = nil, diProva: Bool,
         sogliaFamiglie: Int? = nil, descrizioni: [String: String]? = nil, classiEta: [ClasseFamiglie] = [],
         classiReddito: [ClasseFamiglie] = [], celle: [CellaFamiglie] = [], gruppi: [GruppoFamiglie] = []) {
        self.formato = formato
        self.versione = versione
        self.fonte = fonte
        self.edizione = edizione
        self.aggiornamento = aggiornamento
        self.licenza = licenza
        self.note = note
        self.diProva = diProva
        self.sogliaFamiglie = sogliaFamiglie
        self.descrizioni = descrizioni
        self.classiEta = classiEta
        self.classiReddito = classiReddito
        self.celle = celle
        self.gruppi = gruppi
    }

    enum CodingKeys: String, CodingKey {
        case formato, versione, fonte, edizione, aggiornamento, licenza, note, diProva, sogliaFamiglie, descrizioni
        case classiEta, classiReddito, celle, gruppi
    }

    /// La versione 2 chiede `gruppi`, la 1 (e ogni altra, che poi la validazione rifiuta) classi e celle: così un
    /// campo che manca esce con il suo nome.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        formato = try c.decode(String.self, forKey: .formato)
        versione = try c.decode(Int.self, forKey: .versione)
        fonte = try c.decode(String.self, forKey: .fonte)
        edizione = try c.decodeIfPresent(Int.self, forKey: .edizione)
        aggiornamento = try c.decodeIfPresent(String.self, forKey: .aggiornamento)
        licenza = try c.decodeIfPresent(String.self, forKey: .licenza)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        diProva = try c.decode(Bool.self, forKey: .diProva)
        sogliaFamiglie = try c.decodeIfPresent(Int.self, forKey: .sogliaFamiglie)
        descrizioni = try c.decodeIfPresent([String: String].self, forKey: .descrizioni)
        if versione == 2 {
            gruppi = try c.decode([GruppoFamiglie].self, forKey: .gruppi)
            classiEta = []
            classiReddito = []
            celle = []
        } else {
            classiEta = try c.decode([ClasseFamiglie].self, forKey: .classiEta)
            classiReddito = try c.decode([ClasseFamiglie].self, forKey: .classiReddito)
            celle = try c.decode([CellaFamiglie].self, forKey: .celle)
            gruppi = []
        }
    }

    /// Tavole a una dimensione (versione 2).
    var unaDimensione: Bool { versione >= 2 }

    /// Le tabelle predefinite incluse nell'app: le tavole pubblicate dalla Banca d'Italia (nil se il file manca o non è
    /// valido: la prova dei calcoli lo segnala).
    static let tabellePredefinite: TabelleFamiglie? = leggiRisorsa(filePredefinito)

    /// Le tabelle di prova incluse nell'app (versione 1, valori segnaposto): solo per le prove e le istantanee.
    static let tabelleDiProva: TabelleFamiglie? = leggiRisorsa(fileDiProva)

    private static func leggiRisorsa(_ nome: String) -> TabelleFamiglie? {
        guard let url = Risorse.cartella?.appendingPathComponent(nome),
              let dati = try? Data(contentsOf: url) else { return nil }
        return try? TabelleFamiglie.leggi(dati)
    }

    /// La cella di due classi (versione 1).
    func cella(eta: String, reddito: String) -> CellaFamiglie? {
        celle.first { $0.eta == eta && $0.reddito == reddito }
    }

    /// Il gruppo di una dimensione (versione 2).
    func gruppo(_ d: DimensioneFamiglie) -> GruppoFamiglie? {
        gruppi.first { $0.dimensione == d }
    }
}

/// Le tabelle caricate dal consulente da Impostazioni (nell'archivio e nel backup): prevalgono su quelle incluse.
struct FamiglieCaricate: Codable, Equatable {
    var tabelle: TabelleFamiglie
    /// Il nome del file scelto, come promemoria.
    var nomeFile: String
    var caricateIl: Date
}

/// Un errore del file delle tabelle: il campo (come nel file, per esempio «celle[3].tassoRisparmio») e il motivo.
struct ErroreTabelleFamiglie: Error, Equatable {
    let campo: String
    let motivo: String

    /// Il messaggio per Impostazioni.
    var messaggio: String { campo.isEmpty ? motivo : "\(campo): \(motivo)" }
}

// MARK: - Lettura e validazione

extension TabelleFamiglie {
    /// Legge e controlla un file delle tabelle. Il primo errore trovato esce con il campo e il motivo.
    static func leggi(_ dati: Data) throws -> TabelleFamiglie {
        let t: TabelleFamiglie
        do {
            t = try JSONDecoder().decode(TabelleFamiglie.self, from: dati)
        } catch let DecodingError.keyNotFound(chiave, contesto) {
            throw ErroreTabelleFamiglie(campo: percorso(contesto.codingPath + [chiave]), motivo: TestiFamiglie.campoMancante)
        } catch let DecodingError.typeMismatch(_, contesto) {
            throw ErroreTabelleFamiglie(campo: percorso(contesto.codingPath), motivo: TestiFamiglie.tipoSbagliato)
        } catch let DecodingError.valueNotFound(_, contesto) {
            throw ErroreTabelleFamiglie(campo: percorso(contesto.codingPath), motivo: TestiFamiglie.valoreVuoto)
        } catch let DecodingError.dataCorrupted(contesto) where !contesto.codingPath.isEmpty {
            // Per esempio una dimensione o una statistica che Prisma non conosce
            throw ErroreTabelleFamiglie(campo: percorso(contesto.codingPath), motivo: TestiFamiglie.valoreSconosciuto)
        } catch {
            throw ErroreTabelleFamiglie(campo: "", motivo: TestiFamiglie.nonJSON)
        }
        try t.valida()
        return t
    }

    /// «celle[3].tassoRisparmio» da un percorso di decodifica.
    private static func percorso(_ chiavi: [CodingKey]) -> String {
        var s = ""
        for k in chiavi {
            if let i = k.intValue { s += "[\(i)]" } else { s += s.isEmpty ? k.stringValue : ".\(k.stringValue)" }
        }
        return s
    }

    /// I controlli del formato. Comuni: formato, versione, fonte, edizione, soglia. Versione 1: classi senza buchi né
    /// sovrapposizioni, una cella per ogni coppia, quantili non decrescenti, quote tra 0 e 100, famiglie maggiori di
    /// zero. Versione 2: gruppi con id unici e al più uno per dimensione, classi come nella versione 1 (il gruppo
    /// «tutte» ha una sola classe senza estremi), voci conosciute con il loro valore.
    func valida() throws {
        typealias E = ErroreTabelleFamiglie
        guard formato == Self.formatoAtteso else { throw E(campo: "formato", motivo: TestiFamiglie.formatoSconosciuto(formato)) }
        guard Self.versioniLette.contains(versione) else { throw E(campo: "versione", motivo: TestiFamiglie.versioneSconosciuta(versione)) }
        guard !fonte.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw E(campo: "fonte", motivo: TestiFamiglie.fonteVuota) }
        if let e = edizione, !(1900...2200).contains(e) { throw E(campo: "edizione", motivo: TestiFamiglie.edizioneFuori) }
        if let s = sogliaFamiglie, s < 1 { throw E(campo: "sogliaFamiglie", motivo: TestiFamiglie.sogliaFuori) }
        if unaDimensione {
            try validaGruppi()
            return
        }
        try Self.validaClassi(classiEta, nome: "classiEta", interi: true)
        try Self.validaClassi(classiReddito, nome: "classiReddito", interi: false)
        let idEta = Set(classiEta.map(\.id))
        let idReddito = Set(classiReddito.map(\.id))
        var viste = Set<String>()
        for (i, c) in celle.enumerated() {
            let campo = "celle[\(i)]"
            guard idEta.contains(c.eta) else { throw E(campo: "\(campo).eta", motivo: TestiFamiglie.classeSconosciuta(c.eta)) }
            guard idReddito.contains(c.reddito) else { throw E(campo: "\(campo).reddito", motivo: TestiFamiglie.classeSconosciuta(c.reddito)) }
            guard viste.insert(c.eta + "|" + c.reddito).inserted else { throw E(campo: campo, motivo: TestiFamiglie.cellaDoppia(c.eta, c.reddito)) }
            if let n = c.famiglie, n < 1 { throw E(campo: "\(campo).famiglie", motivo: TestiFamiglie.famiglieFuori) }
            for v in VoceFamiglie.allCases {
                guard let d = c.distribuzione(v) else { continue }
                try Self.validaDistribuzione(d, voce: v, campo: "\(campo).\(v.rawValue)")
            }
        }
        // Una cella per ogni coppia età × reddito
        for e in classiEta {
            for r in classiReddito where !viste.contains(e.id + "|" + r.id) {
                throw E(campo: "celle", motivo: TestiFamiglie.cellaMancante(e.id, r.id))
            }
        }
    }

    /// Quantili finiti e non decrescenti, media finita, quota tra 0 e 100, tasso di risparmio tra −100 e 100.
    private static func validaDistribuzione(_ d: DistribuzioneFamiglie, voce v: VoceFamiglie, campo cv: String) throws {
        typealias E = ErroreTabelleFamiglie
        let q = d.quantili
        if let cattivo = q.first(where: { !$0.valore.isFinite }) {
            throw E(campo: "\(cv).p\(Int(cattivo.percentile))", motivo: TestiFamiglie.numeroNonValido)
        }
        for k in q.indices.dropFirst() where q[k].valore < q[k - 1].valore {
            throw E(campo: "\(cv).p\(Int(q[k].percentile))", motivo: TestiFamiglie.quantiliDecrescenti)
        }
        if let m = d.media, !m.isFinite { throw E(campo: "\(cv).media", motivo: TestiFamiglie.numeroNonValido) }
        if let quota = d.quota, !(quota.isFinite && (0...100).contains(quota)) {
            throw E(campo: "\(cv).quota", motivo: TestiFamiglie.quotaFuori)
        }
        if v == .tassoRisparmio, let fuori = q.first(where: { !(-100...100).contains($0.valore) }) {
            throw E(campo: "\(cv).p\(Int(fuori.percentile))", motivo: TestiFamiglie.tassoFuori)
        }
    }

    /// Versione 2: i gruppi, le loro classi e le voci.
    private func validaGruppi() throws {
        typealias E = ErroreTabelleFamiglie
        guard !gruppi.isEmpty else { throw E(campo: "gruppi", motivo: TestiFamiglie.gruppiVuoti) }
        var id = Set<String>()
        var dimensioni = Set<DimensioneFamiglie>()
        for (i, g) in gruppi.enumerated() {
            let campo = "gruppi[\(i)]"
            guard !g.id.trimmingCharacters(in: .whitespaces).isEmpty else { throw E(campo: "\(campo).id", motivo: TestiFamiglie.idVuoto) }
            guard id.insert(g.id).inserted else { throw E(campo: "\(campo).id", motivo: TestiFamiglie.idDoppio(g.id)) }
            guard dimensioni.insert(g.dimensione).inserted else {
                throw E(campo: "\(campo).dimensione", motivo: TestiFamiglie.dimensioneDoppia(g.dimensione.rawValue))
            }
            if g.dimensione == .tutte {
                guard g.classi.count == 1, let unica = g.classi.first, unica.da == nil, unica.a == nil else {
                    throw E(campo: "\(campo).classi", motivo: TestiFamiglie.tutteUnaClasse)
                }
            }
            try Self.validaClassi(g.classi.map(\.classe), nome: "\(campo).classi", interi: g.dimensione == .eta)
            for (k, c) in g.classi.enumerated() {
                let cc = "\(campo).classi[\(k)]"
                if let n = c.famiglie, n < 1 { throw E(campo: "\(cc).famiglie", motivo: TestiFamiglie.famiglieFuori) }
                for chiave in c.voci.keys.sorted() {
                    let cv = "\(cc).voci.\(chiave)"
                    guard let v = VoceFamiglie(rawValue: chiave), let valore = c.voci[chiave] else {
                        throw E(campo: cv, motivo: TestiFamiglie.voceSconosciuta(chiave))
                    }
                    try Self.validaValore(valore, voce: v, campo: cv)
                }
            }
        }
    }

    /// Versione 2: il valore di una voce secondo la sua statistica.
    private static func validaValore(_ x: ValoreFamiglie, voce v: VoceFamiglie, campo cv: String) throws {
        typealias E = ErroreTabelleFamiglie
        if x.statistica == .quantili {
            guard let q = x.quantili, q.quantili.count >= 2 else { throw E(campo: "\(cv).quantili", motivo: TestiFamiglie.servonoQuantili) }
            try validaDistribuzione(q, voce: v, campo: "\(cv).quantili")
            if let valore = x.valore, !valore.isFinite { throw E(campo: "\(cv).valore", motivo: TestiFamiglie.numeroNonValido) }
            return
        }
        guard let valore = x.valore else { throw E(campo: "\(cv).valore", motivo: TestiFamiglie.campoMancante) }
        guard valore.isFinite else { throw E(campo: "\(cv).valore", motivo: TestiFamiglie.numeroNonValido) }
        switch x.statistica {
        case .quota:
            guard v == .protezione || v == .previdenzaComplementare else { throw E(campo: "\(cv).statistica", motivo: TestiFamiglie.quotaSoloPossesso) }
            guard (0...100).contains(valore) else { throw E(campo: "\(cv).valore", motivo: TestiFamiglie.quotaFuori) }
        case .rapportoTraMedie, .media, .mediana:
            if v == .tassoRisparmio, !(-100...100).contains(valore) { throw E(campo: "\(cv).valore", motivo: TestiFamiglie.tassoFuori) }
        case .quantili:
            break
        }
    }

    /// Classi in ordine, senza buchi né sovrapposizioni: solo la prima può non avere `da`, solo l'ultima `a`.
    /// Età (interi, estremi inclusi): la classe dopo comincia all'anno successivo. Reddito (`a` escluso): dove
    /// finisce la precedente.
    private static func validaClassi(_ classi: [ClasseFamiglie], nome: String, interi: Bool) throws {
        typealias E = ErroreTabelleFamiglie
        guard !classi.isEmpty else { throw E(campo: nome, motivo: TestiFamiglie.classiVuote) }
        var id = Set<String>()
        for (i, c) in classi.enumerated() {
            let campo = "\(nome)[\(i)]"
            guard !c.id.trimmingCharacters(in: .whitespaces).isEmpty else { throw E(campo: "\(campo).id", motivo: TestiFamiglie.idVuoto) }
            guard id.insert(c.id).inserted else { throw E(campo: "\(campo).id", motivo: TestiFamiglie.idDoppio(c.id)) }
            if c.da == nil, i > 0 { throw E(campo: "\(campo).da", motivo: TestiFamiglie.daMancante) }
            if c.a == nil, i < classi.count - 1 { throw E(campo: "\(campo).a", motivo: TestiFamiglie.aMancante) }
            if let da = c.da, let a = c.a, (interi ? a < da : a <= da) { throw E(campo: campo, motivo: TestiFamiglie.estremiInvertiti) }
            if interi, let da = c.da, da != da.rounded() { throw E(campo: "\(campo).da", motivo: TestiFamiglie.etaIntera) }
            if interi, let a = c.a, a != a.rounded() { throw E(campo: "\(campo).a", motivo: TestiFamiglie.etaIntera) }
            if i > 0, let prima = classi[i - 1].a, let da = c.da {
                let atteso = interi ? prima + 1 : prima
                if da < atteso { throw E(campo: "\(campo).da", motivo: TestiFamiglie.sovrapposte) }
                if da > atteso { throw E(campo: "\(campo).da", motivo: TestiFamiglie.buco) }
            }
        }
    }
}
