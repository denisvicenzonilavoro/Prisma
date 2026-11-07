import Foundation

// Una giornata della pensione (Design/template-luce-specifica.md §4.2, «Luce» giro 4): la pensione mensile stimata
// (pubblica + piani in essere, «con il piano» anche le proposte: `PensioneEsperienze`, decisioni 75-77) diventa una
// giornata di scene. Le voci e i loro costi li scrive il consulente CON il cliente (decisione 83): il template inventa le
// spese fisse al 57% del reddito desiderato e gli importi delle scene, Prisma no. Una voce senza importo è esclusa dal
// conto e segnalata. Tutto in euro di oggi (come la pensione del motore previdenziale): nessuna rivalutazione.
// Regola: prima le voci fisse (se non bastano, nessun'altra scena ci sta), poi le altre nell'ordine scelto; ognuna ci
// sta se il resto basta, e se ci sta si toglie dal resto (come `giorAgg` del template). Motore puro.

/// Una voce della giornata («La colazione al bar», «La casa e la spesa», …).
struct VoceGiornata: Codable, Identifiable, Hashable {
    var id: String
    /// L'ora o il momento («07:30», «Agosto»).
    var quando: String
    var titolo: String
    var frase: String
    /// Euro di oggi al mese; nil = non ancora scritto con il cliente.
    var importoMensile: Double?
    /// La voce delle spese di tutti i mesi: si paga per prima e non si toglie.
    var fissa: Bool
    /// Il glifo della scena (`GlifoScena.rawValue`).
    var glifo: String
    /// La priorità scelta con il cliente (0 = la più importante).
    var priorita: Int
    /// Importo precompilato da un'altra cifra (il fabbisogno di oggi): «da confermare» finché non lo si riscrive.
    var daConfermare: Bool?

    init(id: String, quando: String, titolo: String, frase: String, importoMensile: Double? = nil, fissa: Bool = false,
         glifo: String, priorita: Int, daConfermare: Bool? = nil) {
        self.id = id
        self.quando = quando
        self.titolo = titolo
        self.frase = frase
        self.importoMensile = importoMensile
        self.fissa = fissa
        self.glifo = glifo
        self.priorita = priorita
        self.daConfermare = daConfermare
    }

    private enum CodingKeys: String, CodingKey {
        case id, quando, titolo, frase, importoMensile, fissa, glifo, priorita, daConfermare
    }

    /// Lettura tollerante: solo l'id è obbligatorio; un importo negativo o illeggibile è «non scritto».
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        quando = (try? c.decodeIfPresent(String.self, forKey: .quando)) ?? ""
        titolo = (try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? ""
        frase = (try? c.decodeIfPresent(String.self, forKey: .frase)) ?? ""
        let importo = (try? c.decodeIfPresent(Double.self, forKey: .importoMensile)) ?? nil
        importoMensile = importo.flatMap { $0 >= 0 && $0.isFinite ? $0 : nil }
        fissa = (try? c.decodeIfPresent(Bool.self, forKey: .fissa)) ?? false
        glifo = (try? c.decodeIfPresent(String.self, forKey: .glifo)) ?? ""
        priorita = (try? c.decodeIfPresent(Int.self, forKey: .priorita)) ?? 0
        daConfermare = (try? c.decodeIfPresent(Bool.self, forKey: .daConfermare)) ?? nil
    }
}

/// La giornata di un cliente, accanto alle sue ipotesi di previdenza (`Analisi360.giornata`, versione 27).
struct GiornataPensione: Codable, Equatable {
    var voci: [VoceGiornata]
    var aggiornataIl: Date?
    /// Vero per la giornata dei dati di prova (le cinque scene del template con i loro importi).
    var diProva: Bool?

    init(voci: [VoceGiornata], aggiornataIl: Date? = nil, diProva: Bool? = nil) {
        self.voci = voci
        self.aggiornataIl = aggiornataIl
        self.diProva = diProva
    }

    private enum CodingKeys: String, CodingKey { case voci, aggiornataIl, diProva }

    /// Lettura tollerante: una voce illeggibile si scarta, le altre restano.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        voci = ((try? c.decodeIfPresent(ElencoTollerante<VoceGiornata>.self, forKey: .voci)) ?? nil)?.elementi ?? []
        aggiornataIl = (try? c.decodeIfPresent(Date.self, forKey: .aggiornataIl)) ?? nil
        diProva = (try? c.decodeIfPresent(Bool.self, forKey: .diProva)) ?? nil
    }

    /// Nessuna voce ha ancora un importo: la giornata è da compilare.
    var daCompilare: Bool { !voci.contains { $0.importoMensile != nil } }
}

/// L'esito della giornata con una pensione.
struct EsitoGiornata: Equatable {
    struct Scena: Equatable {
        let voce: VoceGiornata
        /// Ci sta (per la voce fissa: è coperta).
        let ciSta: Bool
        /// Senza importo: esclusa dal conto.
        let senzaImporto: Bool
    }

    let pensione: Double
    /// Le spese fisse (la somma delle voci fisse con l'importo).
    let fisse: Double
    /// Le scene nell'ordine in cui si pagano (prima le fisse).
    let scene: [Scena]
    /// Quanto vanno a spendere le scene che ci stanno (fisse escluse).
    let usate: Double
    /// Quanto resta al mese; < 0 = mancano soldi già per le spese fisse.
    let resto: Double
    let fisseCoperte: Bool
    /// Quanto mancherebbe al mese per vivere tutta la giornata (0 se ci sta tutto).
    let mancaPerTutto: Double
    /// Le voci senza importo, escluse dal conto.
    var senzaImporto: [VoceGiornata] { scene.filter(\.senzaImporto).map(\.voce) }
}

enum MotoreGiornataPensione {
    /// In che ordine si pagano le scene dopo le spese fisse.
    enum Regola {
        /// L'ordine dell'orologio della giornata (il template).
        case ordineDellaGiornata
        /// La priorità scelta con il cliente (decisione 83, la regola di Prisma).
        case priorita
    }

    /// Il numero massimo di voci (le cinque del template più una).
    static let massimoVoci = 6

    /// Le voci nell'ordine in cui si pagano: prima le fisse, poi le altre (priorità o ordine dato).
    static func ordinate(_ voci: [VoceGiornata], regola: Regola) -> [VoceGiornata] {
        let fisse = voci.filter(\.fissa)
        var altre = voci.filter { !$0.fissa }
        if regola == .priorita {
            // Ordinamento stabile: a parità di priorità resta l'ordine dato
            altre = altre.enumerated().sorted { a, b in
                a.element.priorita != b.element.priorita ? a.element.priorita < b.element.priorita : a.offset < b.offset
            }.map(\.element)
        }
        return fisse + altre
    }

    static func calcola(_ g: GiornataPensione, pensione: Double, regola: Regola = .priorita) -> EsitoGiornata {
        let voci = ordinate(g.voci, regola: regola)
        let fisse = voci.filter { $0.fissa }.compactMap(\.importoMensile).reduce(0, +)
        let fisseCoperte = pensione >= fisse
        var resto = pensione - fisse
        var usate = 0.0
        var tutte = fisse
        var scene: [EsitoGiornata.Scena] = []
        for v in voci {
            guard let importo = v.importoMensile else {
                scene.append(.init(voce: v, ciSta: false, senzaImporto: true))
                continue
            }
            if v.fissa {
                scene.append(.init(voce: v, ciSta: fisseCoperte, senzaImporto: false))
                continue
            }
            tutte += importo
            let ciSta = fisseCoperte && resto >= importo
            if ciSta {
                resto -= importo
                usate += importo
            }
            scene.append(.init(voce: v, ciSta: ciSta, senzaImporto: false))
        }
        return EsitoGiornata(pensione: pensione, fisse: fisse, scene: scene, usate: usate, resto: resto,
                             fisseCoperte: fisseCoperte, mancaPerTutto: max(0, tutte - pensione))
    }

    /// Le cinque scene del template senza importi: la giornata da compilare con il cliente. Titoli, ore e glifi sono
    /// quelli del template (`SCN`, righe 1351-1355); nessun costo.
    static func scenePredefinite() -> [VoceGiornata] {
        [
            VoceGiornata(id: "colazione", quando: "07:30", titolo: "La colazione al bar", frase: "con gli amici di sempre",
                         glifo: "colazione", priorita: 0),
            VoceGiornata(id: "casa", quando: "10:00", titolo: "La casa e la spesa", frase: "le spese di tutti i mesi",
                         fissa: true, glifo: "casa", priorita: 1),
            VoceGiornata(id: "nipoti", quando: "16:30", titolo: "I nipoti", frase: "il nuoto, la merenda, un regalo",
                         glifo: "nipoti", priorita: 2),
            VoceGiornata(id: "cena", quando: "20:30", titolo: "La cena fuori", frase: "una volta a settimana",
                         glifo: "cena", priorita: 3),
            VoceGiornata(id: "viaggio", quando: "Agosto", titolo: "Il viaggio dell’estate", frase: "due settimane, una volta l’anno",
                         glifo: "viaggio", priorita: 4)
        ]
    }

    /// La giornata da compilare, con le spese fisse precompilate dal fabbisogno di oggi della famiglia solo se l'area
    /// Protezione è confermata con il cliente, e comunque «da confermare» (decisione 83).
    static func daCompilare(fabbisognoConfermato: Double?) -> GiornataPensione {
        var voci = scenePredefinite()
        if let f = fabbisognoConfermato, f > 0, let i = voci.firstIndex(where: \.fissa) {
            voci[i].importoMensile = f
            voci[i].daConfermare = true
        }
        return GiornataPensione(voci: voci)
    }

    /// DATI DI PROVA: le cinque scene del template con i loro importi (spese fisse 1.250, il 57% di 2.200 arrotondato a
    /// 10; colazione 60, nipoti 150, cena 160, viaggio 250), per le istantanee e le prove. Mai nell'archivio reale.
    static func giornataDiProva() -> GiornataPensione {
        let importi: [String: Double] = ["colazione": 60, "casa": 1_250, "nipoti": 150, "cena": 160, "viaggio": 250]
        var voci = scenePredefinite()
        for i in voci.indices { voci[i].importoMensile = importi[voci[i].id] }
        return GiornataPensione(voci: voci, diProva: true)
    }

    /// La priorità rifatta dall'ordine dato (dopo un trascinamento): 0, 1, 2, …
    static func riordina(_ voci: [VoceGiornata]) -> [VoceGiornata] {
        voci.enumerated().map { i, v in
            var x = v
            x.priorita = i
            return x
        }
    }

    /// Sposta una voce prima di un'altra (trascinamento) e rifà le priorità.
    static func sposta(_ voci: [VoceGiornata], id: String, prima di: String?) -> [VoceGiornata] {
        guard let da = voci.firstIndex(where: { $0.id == id }) else { return voci }
        var elenco = voci
        let v = elenco.remove(at: da)
        if let di, let a = elenco.firstIndex(where: { $0.id == di }) {
            elenco.insert(v, at: a)
        } else {
            elenco.append(v)
        }
        return riordina(elenco)
    }
}
