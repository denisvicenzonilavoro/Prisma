import Foundation

// Analisi 360 › la griglia delle quattro aree nel tema Apple (Design/template-apple-specifica.md §4.3.1, §4.3.4,
// §4.3.5). Qui non c'è nessuna formula nuova: ogni cifra viene dai motori dei pannelli di sempre e il motore la
// mette in forma per l'anello, il titolo e la frase della card.
// - Previdenza: quota del divario coperta dai piani (MotoreAnalisi.previdenza: integrazione / divario) e, nella
//   frase, il divario che resta al mese (la cifra grande del pannello).
// - Protezione: quota del fabbisogno coperta dalle coperture caso morte (MotoreAnalisi.protezione) e il capitale
//   che manca (la cifra grande del pannello).
// - Investimenti: quota del capitale investito con un rischio entro il profilo (MotoreCoerenza.sriStimato e
//   sriMassimo, gli stessi del riquadro «Rischio rispetto al profilo» del pannello) e il capitale atteso netto
//   (MotoreAnalisi.investimenti, la cifra grande del pannello). La composizione viene da MotoreResistenza.composizione.
// - Risparmio e liquidità: mesi di spese da parte (liquidità in essere di MotoreLiquidita diviso il fabbisogno
//   mensile delle ipotesi, come il check-up) rispetto ai mesi di riserva delle ipotesi, e quanto manca all'obiettivo
//   di risparmio (MotoreAnalisi.risparmio, la cifra grande del pannello).
// Le formule semplificate del template (3% composto, coerenza fissa, spese 2.300 €, costo 1,4%) non si usano (§4.9).

/// Una delle quattro aree della griglia: l'anello, la cifra al centro, il titolo e la frase.
struct SintesiArea360: Equatable {
    enum Unita: Equatable { case percentuale, mesi }

    let area: AreaAnalisi
    /// Riempimento dell'anello (0…1); nil se l'area non si può misurare (anello vuoto e trattino al centro).
    let frazione: Double?
    /// Il valore al centro (percentuale intera o mesi con un decimale); nil insieme a `frazione`.
    let valore: Double?
    let unita: Unita
    /// «72% del divario coperto».
    let titolo: String
    /// La frase con la cifra principale del pannello dell'area.
    let testo: String
}

/// Come lavorano i risparmi del cliente: la composizione delle posizioni finanziarie in essere per classe di attivo,
/// con il canale di ciascun pezzo, e il rischio delle posizioni di investimento rispetto al profilo.
struct ComposizioneInvestimenti360: Equatable {
    enum Classe: String, CaseIterable, Identifiable {
        case azionario, obbligazionario, gestioneSeparata, liquidita
        var id: String { rawValue }

        var nome: String {
            switch self {
            case .azionario: return "Azionario"
            case .obbligazionario: return "Obbligazionario"
            case .gestioneSeparata: return "Gestione separata"
            case .liquidita: return "Liquidità"
            }
        }
    }

    struct Pezzo: Equatable, Identifiable {
        let classe: Classe
        /// Euro della classe, sommati su tutte le posizioni (valore × quota della composizione).
        let valore: Double
        /// Quota del totale, in % (0–100).
        let quota: Double
        /// Gli euro della classe per canale: ogni pezzo distingue Alleanza e indipendente.
        let perCanale: [Canale: Double]
        var id: String { classe.rawValue }
    }

    /// Sempre quattro pezzi, nell'ordine delle classi (anche a zero).
    let pezzi: [Pezzo]
    /// Investimento, risparmio, previdenza e liquidità in essere.
    let totale: Double
    let perCanale: [Canale: Double]
    /// Almeno una composizione è stimata dalla tipologia o dall'SRI (non indicata nella posizione).
    let stimata: Bool
    /// SRI medio delle posizioni di investimento, pesato sul valore (come nel pannello).
    let sriMedio: Double?
    let sriMassimo: Int?
    let propensione: ProfiloInvestitore.Propensione?
    /// Quota del capitale di investimento con un SRI entro il profilo, in % (nil senza investimenti o senza profilo).
    let entroProfilo: Double?
    /// Valore delle posizioni di investimento in essere.
    let investito: Double

    var vuota: Bool { totale <= 0 }
}

/// Quanti mesi di spese ha da parte il cliente: liquidità in essere, spese mensili e soglia delle ipotesi.
struct Liquidita360: Equatable {
    /// Conti e depositi in essere (MotoreLiquidita.liquiditaAttuale).
    let liquidita: Double
    let perCanale: [Canale: Double]
    /// Fabbisogno mensile delle ipotesi di protezione (le spese della famiglia).
    let speseMensili: Double
    /// Mesi di spese da parte, arrotondati per difetto al decimo (nil se le spese non sono indicate).
    let mesi: Double?
    /// Mesi di riserva delle ipotesi.
    let soglia: Int
    /// Capitali in scadenza nei prossimi mesi, netti (non contano nei mesi: arrivano più avanti).
    let inScadenza: Double
    let mesiFinestraScadenze: Int
    /// Riserva che servirebbe (spese × mesi di riserva) e liquidità oltre la riserva (conti più scadenze).
    let riservaNecessaria: Double
    let eccedenza: Double
}

/// Tutto ciò che la griglia delle aree e i due dettagli (Investimenti, Liquidità) mostrano di un cliente.
struct AreeAnalisi360: Equatable {
    let aree: [SintesiArea360]
    let composizione: ComposizioneInvestimenti360
    let liquidita: Liquidita360

    func sintesi(_ a: AreaAnalisi) -> SintesiArea360? { aree.first { $0.area == a } }
}

enum MotoreAree360 {
    static func calcola(cliente: Cliente?, posizioni: [Posizione], analisi a: Analisi360, obiettivi: [Obiettivo],
                        prodotti: [Prodotto], data: Date = Date()) -> AreeAnalisi360 {
        let k = Self.composizione(posizioni, cliente: cliente)
        let l = Self.liquidita(posizioni, analisi: a, obiettivi: obiettivi, prodotti: prodotti, data: data)
        let aree = [
            Self.previdenza(a.previdenza),
            Self.protezione(a.protezione, posizioni: posizioni),
            Self.investimenti(a.investimenti, composizione: k),
            Self.risparmio(a.risparmio, liquidita: l),
        ]
        return AreeAnalisi360(aree: aree, composizione: k, liquidita: l)
    }

    /// Una percentuale intera per difetto: 99,6% resta 99%, finché non è davvero tutto coperto.
    static func percentuale(_ frazione: Double) -> Double {
        (min(max(frazione, 0), 1) * 100).rounded(.down)
    }

    // MARK: - Le quattro aree

    static func previdenza(_ i: IpotesiPrevidenza) -> SintesiArea360 {
        let e = MotoreAnalisi.previdenza(i)
        let frazione = e.divario > 0 ? min(1, max(0, e.integrazione / e.divario)) : 1
        let p = percentuale(frazione)
        let titolo = e.divario > 0 ? "\(TestiAree360.intero(p))% del divario coperto" : "Reddito desiderato coperto"
        let testo: String
        if e.divarioResiduo >= 0.5 {
            testo = "Mancano circa \(Formati.euro(e.divarioResiduo)) al mese alla pensione che desidera, a \(i.etaPensione) anni."
        } else if e.divario > 0 {
            testo = "I piani in essere colmano il divario fra la pensione pubblica e il reddito desiderato."
        } else {
            testo = "La pensione pubblica delle ipotesi arriva già al reddito desiderato."
        }
        return SintesiArea360(area: .previdenza, frazione: frazione, valore: p, unita: .percentuale,
                              titolo: titolo, testo: testo)
    }

    static func protezione(_ i: IpotesiProtezione, posizioni: [Posizione]) -> SintesiArea360 {
        let e = MotoreAnalisi.protezione(i, posizioni: posizioni)
        let frazione = e.fabbisogno > 0 ? min(1, max(0, e.capitaleVita / e.fabbisogno)) : 1
        let p = percentuale(frazione)
        let titolo = e.fabbisogno > 0 ? "\(TestiAree360.intero(p))% della famiglia protetta" : "Nessun fabbisogno"
        let testo: String
        if e.divario >= 0.5 {
            testo = "Mancano \(Formati.euro(e.divario)) di capitale caso morte"
                + (e.capitaleVita <= 0 ? ": nessuna copertura in essere." : ".")
        } else if e.fabbisogno > 0 {
            testo = "Le coperture caso morte in essere coprono il fabbisogno della famiglia."
        } else {
            testo = "Con queste ipotesi alla famiglia non servirebbe capitale caso morte."
        }
        return SintesiArea360(area: .protezione, frazione: frazione, valore: p, unita: .percentuale,
                              titolo: titolo, testo: testo)
    }

    /// Quota entro il profilo come la mostrano card e dettaglio: per difetto, tra 0 e 100.
    static func quotaEntroProfilo(_ entro: Double) -> Double { min(max(entro, 0), 100).rounded(.down) }

    static func investimenti(_ i: IpotesiInvestimento, composizione c: ComposizioneInvestimenti360) -> SintesiArea360 {
        let e = MotoreAnalisi.investimenti(i)
        let atteso = "Capitale atteso tra \(i.anni) \(i.anni == 1 ? "anno" : "anni"): \(Formati.euro(e.esito.netto)) netti."
        guard c.investito > 0 else {
            return SintesiArea360(area: .investimenti, frazione: nil, valore: nil, unita: .percentuale,
                                  titolo: "Nessun investimento in essere", testo: atteso)
        }
        guard let entro = c.entroProfilo, let pr = c.propensione else {
            let sri = c.sriMedio.map { "SRI medio \(TestiAree360.decimale($0)) su 7, profilo di rischio da rilevare. " } ?? ""
            return SintesiArea360(area: .investimenti, frazione: nil, valore: nil, unita: .percentuale,
                                  titolo: "Profilo da rilevare", testo: sri + atteso)
        }
        let p = quotaEntroProfilo(entro)
        let giudizio = p >= 100
            ? "Il rischio delle posizioni è in linea con il profilo \(pr.nome.lowercased())."
            : "Una parte del capitale ha un rischio oltre il profilo \(pr.nome.lowercased()): da riequilibrare."
        return SintesiArea360(area: .investimenti, frazione: p / 100, valore: p, unita: .percentuale,
                              titolo: "\(TestiAree360.intero(p))% entro il profilo", testo: giudizio + " " + atteso)
    }

    static func risparmio(_ i: IpotesiRisparmio, liquidita l: Liquidita360) -> SintesiArea360 {
        let r = MotoreAnalisi.risparmio(i)
        let obiettivo = r.mancante >= 0.5
            ? "Per l'obiettivo di risparmio mancano \(Formati.euro(r.mancante)) tra \(i.anni) \(i.anni == 1 ? "anno" : "anni")."
            : "L'obiettivo di risparmio è alla portata del piano."
        guard let mesi = l.mesi else {
            return SintesiArea360(area: .risparmio, frazione: nil, valore: nil, unita: .mesi,
                                  titolo: "Spese mensili da indicare", testo: obiettivo)
        }
        let soglia = Double(l.soglia)
        let frazione = soglia > 0 ? min(1, mesi / soglia) : 1
        let riserva = mesi >= soglia
            ? "Oltre la soglia di \(l.soglia) mesi delle ipotesi."
            : "Sotto la soglia di \(l.soglia) mesi delle ipotesi: ne mancano \(TestiAree360.mesi(soglia - mesi))."
        return SintesiArea360(area: .risparmio, frazione: frazione, valore: mesi, unita: .mesi,
                              titolo: "\(TestiAree360.mesiConNome(mesi)) di spese da parte", testo: riserva + " " + obiettivo)
    }

    // MARK: - Composizione e rischio

    static func composizione(_ posizioni: [Posizione], cliente: Cliente?) -> ComposizioneInvestimenti360 {
        typealias C = ComposizioneInvestimenti360.Classe
        let finanziarie = posizioni.filter { $0.stato == .inEssere && $0.valore > 0 && ($0.area.proiettabile || $0.area == .liquidita) }
        var valori: [C: Double] = [:]
        var canali: [C: [Canale: Double]] = [:]
        var perCanale: [Canale: Double] = [:]
        var stimata = false
        for p in finanziarie {
            guard let k = MotoreResistenza.composizione(p) else { continue }
            stimata = stimata || k.stimata
            let quote: [(C, Double)] = [
                (.azionario, k.azioni), (.obbligazionario, k.governativi + k.societarie),
                (.gestioneSeparata, k.gestioneSeparata), (.liquidita, k.liquidita),
            ]
            for (classe, q) in quote where q > 0 {
                let v = p.valore * q
                valori[classe, default: 0] += v
                canali[classe, default: [:]][p.canale, default: 0] += v
                perCanale[p.canale, default: 0] += v
            }
        }
        let totale = valori.values.reduce(0, +)
        let pezzi = C.allCases.map { classe -> ComposizioneInvestimenti360.Pezzo in
            let v = valori[classe] ?? 0
            return ComposizioneInvestimenti360.Pezzo(classe: classe, valore: v, quota: totale > 0 ? v / totale * 100 : 0,
                                                     perCanale: canali[classe] ?? [:])
        }

        // Il rischio rispetto al profilo: le posizioni di investimento in essere, come nel pannello Investimenti
        let investimenti = posizioni.filter { $0.stato == .inEssere && $0.area == .investimento && $0.valore > 0 }
        let investito = investimenti.reduce(0.0) { $0 + $1.valore }
        let sriMedio: Double? = investito > 0
            ? investimenti.reduce(0.0) { $0 + $1.valore * Double(MotoreCoerenza.sriStimato($1)) } / investito
            : nil
        let propensione = cliente?.profilo.propensione
        let massimo = propensione.map(MotoreCoerenza.sriMassimo)
        var entro: Double?
        if let m = massimo, investito > 0 {
            let dentro = investimenti.filter { MotoreCoerenza.sriStimato($0) <= m }.reduce(0.0) { $0 + $1.valore }
            entro = dentro / investito * 100
        }
        return ComposizioneInvestimenti360(pezzi: pezzi, totale: totale, perCanale: perCanale, stimata: stimata,
                                           sriMedio: sriMedio, sriMassimo: massimo, propensione: propensione,
                                           entroProfilo: entro, investito: investito)
    }

    // MARK: - Liquidità

    static func liquidita(_ posizioni: [Posizione], analisi a: Analisi360, obiettivi: [Obiettivo], prodotti: [Prodotto],
                          data: Date) -> Liquidita360 {
        let e = MotoreLiquidita.calcola(posizioni, obiettivi: obiettivi, analisi: a.protezione, prodotti: prodotti, data: data)
        let spese = max(0, a.protezione.fabbisognoMensile)
        var canali: [Canale: Double] = [:]
        for p in e.liquidita { canali[p.canale, default: 0] += p.valore }
        // Per difetto al decimo: 5,96 mesi restano 5,9, sotto la soglia di 6
        let mesi: Double? = spese > 0 ? (e.liquiditaAttuale / spese * 10).rounded(.down) / 10 : nil
        return Liquidita360(liquidita: e.liquiditaAttuale, perCanale: canali, speseMensili: spese, mesi: mesi,
                            soglia: max(1, a.protezione.mesiRiserva), inScadenza: e.nettoInScadenza,
                            mesiFinestraScadenze: IpotesiLiquidita.finestraMesi,
                            riservaNecessaria: e.riservaNecessaria, eccedenza: e.eccedenza)
    }

    // MARK: - La proposta di un'area

    /// La proposta che «Salva come proposta» registra per un'area: la prima che le analisi di Prisma suggeriscono
    /// per quell'area (MotoreSintesi.calcolaProposte, le stesse di Vera), nil se non ce n'è nessuna o ce n'è già una
    /// aperta.
    static func proposta(per area: AreaAnalisi, tra elenco: [PropostaVera]) -> PropostaVera? {
        let prefissi: [String]
        switch area {
        case .previdenza: prefissi = ["previdenza"]
        case .protezione: prefissi = ["protezione-vita", "protezione-invalidita"]
        case .investimenti: prefissi = ["liquidita-destinare"]
        case .risparmio: prefissi = ["liquidita-riserva", "obiettivo-", "liquidita-destinare"]
        }
        for prefisso in prefissi {
            if let p = elenco.first(where: { $0.id.hasPrefix(prefisso) && $0.area != nil }) { return p }
        }
        return nil
    }
}

// MARK: - Testi

/// Le parole della griglia e dei dettagli: mesi con la virgola, accordo al genere, domande a Vera.
enum TestiAree360 {
    static let cifreDaiMotori = "Le cifre vengono dai motori di Prisma"
    static let solaLettura = "In sola lettura le proposte non si salvano."

    static func intero(_ v: Double) -> String { String(Int(v.rounded())) }

    /// «3,5» oppure «6»: un decimale con la virgola, nessuno se è intero (mai il punto del template, §4.9.7).
    static func mesi(_ v: Double) -> String {
        let decimi = Int((max(0, v) * 10).rounded())
        return decimi % 10 == 0 ? String(decimi / 10) : "\(decimi / 10),\(decimi % 10)"
    }

    /// «1 mese», «3,5 mesi».
    static func mesiConNome(_ v: Double) -> String {
        let t = mesi(v)
        return t == "1" ? "1 mese" : "\(t) mesi"
    }

    /// «3,4»: sempre un decimale.
    static func decimale(_ v: Double) -> String {
        let decimi = Int((v * 10).rounded())
        let segno = decimi < 0 ? Formati.meno : ""
        let m = decimi.magnitude
        return "\(segno)\(m / 10),\(m % 10)"
    }

    /// Il genere dal codice fiscale (giorno di nascita oltre 40 = donna); nil se il codice non c'è o non si legge.
    static func femminile(_ c: Cliente?) -> Bool? {
        guard let cf = c?.codiceFiscale.uppercased(), cf.count == 16 else { return nil }
        let caratteri = Array(cf)
        // Omocodia: le cifre possono essere sostituite da queste lettere
        let omocodici: [Character: Character] = ["L": "0", "M": "1", "N": "2", "P": "3", "Q": "4",
                                                 "R": "5", "S": "6", "T": "7", "U": "8", "V": "9"]
        let cifre = [caratteri[9], caratteri[10]].map { omocodici[$0] ?? $0 }
        guard let giorno = Int(String(cifre)) else { return nil }
        return giorno > 40
    }

    /// «Quanti mesi può stare tranquilla senza entrate», accordato al genere (§4.9.6); senza il codice fiscale
    /// la frase non ha un genere.
    static func titoloLiquidita(_ c: Cliente?) -> String {
        switch femminile(c) {
        case .some(true): return "Quanti mesi può stare tranquilla senza entrate"
        case .some(false): return "Quanti mesi può stare tranquillo senza entrate"
        case .none: return "Quanti mesi di spese ha da parte, senza entrate"
        }
    }

    static func nomeArea(_ a: AreaAnalisi) -> String {
        a == .risparmio ? "Risparmio e liquidità" : a.nome
    }

    /// La domanda che «Chiedi a Vera di spiegarlo» manda, con il nome del cliente.
    static func domandaVera(_ a: AreaAnalisi, nome: String) -> String {
        switch a {
        case .previdenza: return "Spiegami la previdenza di \(nome)"
        case .protezione: return "Spiegami la protezione di \(nome)"
        case .investimenti: return "Spiegami come lavorano gli investimenti di \(nome)"
        case .risparmio: return "Spiegami la liquidità di \(nome): quanti mesi di spese ha da parte"
        }
    }

    /// Lo spunto di Vera dell'area: decide quali dati di Prisma accompagnano la domanda.
    static func spuntoVera(_ a: AreaAnalisi) -> SpuntoVera {
        switch a {
        case .previdenza: return .pensione
        case .protezione: return .protezione
        case .investimenti: return .resistenza
        case .risparmio: return .liquidita
        }
    }

    static func nessunaProposta(_ a: AreaAnalisi, nome: String) -> String {
        "Per \(nome) le analisi non suggeriscono nuove proposte in \(nomeArea(a).lowercased()), o ce n'è già una aperta"
    }

    static func propostaSalvata(nome: String) -> String {
        "Proposta salvata nel dossier di \(nome): completala in Posizioni"
    }
}
