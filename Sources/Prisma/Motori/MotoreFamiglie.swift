import Foundation

/// Le cifre del cliente per il confronto con le famiglie come la sua. Tutto facoltativo: una cifra che manca
/// lascia la voce senza confronto, con la frase che dice che cosa manca.
struct DatiFamigliaCliente: Equatable {
    /// Età del cliente, preso come capofamiglia.
    var eta: Int?
    /// Reddito familiare netto annuo (cliente più familiari con reddito), in euro.
    var redditoFamiliare: Double?
    /// Risparmio annuo della famiglia, in euro (risparmio libero del profilo più i versamenti delle posizioni).
    var risparmioAnnuo: Double?
    /// Patrimonio finanziario: liquidità e posizioni finanziarie in essere dei due canali, in euro.
    var ricchezzaFinanziaria: Double?
    /// Ricchezza netta: tutte le posizioni in essere tranne le coperture (immobili compresi), debiti tolti, in euro.
    var ricchezzaNetta: Double?
    /// Almeno una copertura di protezione in essere (vita o danni).
    var haProtezione: Bool?
    /// Almeno una polizza vita in essere: copertura caso morte o polizza vita di investimento o risparmio.
    var haPolizzaVita: Bool?
    /// Premi annui delle coperture in essere, in euro.
    var premiProtezione: Double?
    /// Almeno una forma di previdenza complementare in essere (PIP o fondo pensione).
    var haPrevidenzaComplementare: Bool?
    /// Contributi annui del cliente alla previdenza complementare, in euro.
    var contributiPrevidenza: Double?
    /// Il risparmio libero non è indicato: si contano solo i versamenti delle posizioni.
    var risparmioSoloVersamenti = false
    /// Il reddito netto del cliente non è indicato: si conta solo quello dei familiari.
    var redditoSoloFamiliari = false

    init(eta: Int? = nil, redditoFamiliare: Double? = nil, risparmioAnnuo: Double? = nil, ricchezzaFinanziaria: Double? = nil,
         haProtezione: Bool? = nil, premiProtezione: Double? = nil, haPrevidenzaComplementare: Bool? = nil,
         contributiPrevidenza: Double? = nil, ricchezzaNetta: Double? = nil, haPolizzaVita: Bool? = nil) {
        self.eta = eta
        self.redditoFamiliare = redditoFamiliare
        self.risparmioAnnuo = risparmioAnnuo
        self.ricchezzaFinanziaria = ricchezzaFinanziaria
        self.haProtezione = haProtezione
        self.premiProtezione = premiProtezione
        self.haPrevidenzaComplementare = haPrevidenzaComplementare
        self.contributiPrevidenza = contributiPrevidenza
        self.ricchezzaNetta = ricchezzaNetta
        self.haPolizzaVita = haPolizzaVita
    }

    /// Il tasso di risparmio (% del reddito familiare netto), se ci sono risparmio e reddito.
    var tassoRisparmio: Double? {
        guard let r = risparmioAnnuo, let red = redditoFamiliare, red > 0 else { return nil }
        return r / red * 100
    }

    /// La cifra del cliente per una voce che si confronta con un valore (non con la quota): % per il tasso di
    /// risparmio, euro altrimenti (premi e contributi per protezione e previdenza).
    func valore(_ v: VoceFamiglie) -> Double? {
        switch v {
        case .tassoRisparmio: return tassoRisparmio
        case .ricchezzaFinanziaria: return ricchezzaFinanziaria
        case .ricchezzaNetta: return ricchezzaNetta
        case .protezione: return premiProtezione
        case .previdenzaComplementare: return contributiPrevidenza
        }
    }
}

/// Come si è fatto il confronto di una voce.
enum MetodoConfrontoFamiglie: String, Equatable {
    /// Percentile stimato per interpolazione tra i quantili.
    case quantili
    /// Solo la mediana: sopra o sotto la metà delle famiglie.
    case mediana
    /// Solo la media: sopra o sotto la famiglia media.
    case media
    /// Un rapporto tra medie del gruppo (per esempio 100 − propensione al consumo): sopra o sotto.
    case rapportoMedie
    /// Quota delle famiglie che hanno la cosa (protezione, previdenza complementare).
    case quota
    /// Nessun confronto (dato del cliente o della tabella mancante).
    case nessuno
}

/// Con chi si confronta: la cella età × reddito (versione 1), le famiglie della stessa età, quelle dello stesso
/// quinto di reddito o tutte le famiglie (versione 2).
enum AmbitoFamiglie: String, Equatable, CaseIterable {
    case cella, eta, reddito, tutte

    init(_ d: DimensioneFamiglie) {
        switch d {
        case .eta: self = .eta
        case .reddito: self = .reddito
        case .tutte: self = .tutte
        }
    }
}

/// Che cosa misura la barra di una voce.
enum ScalaBarraFamiglie: Equatable {
    /// Percentili 0-100 (con i quantili): la tacca è la metà delle famiglie.
    case percentili
    /// I valori (con la sola mediana, media o rapporto): la tacca è il valore del gruppo, l'avatar la cifra del
    /// cliente, nessun percentile.
    case valori
    /// Chi non ha la cosa a sinistra della tacca, chi ce l'ha a destra.
    case quota
}

/// La barra di una voce, già calcolata (posizioni 0-100 lungo la barra).
struct BarraFamiglie: Equatable {
    let scala: ScalaBarraFamiglie
    /// Dove sta l'avatar del cliente (nil = nessun avatar: manca la cifra del cliente).
    let cliente: Double?
    /// La tacca principale: la metà delle famiglie, il valore del gruppo o il confine fra chi non ha e chi ha.
    let tacca: Double
    /// Le tacche sottili dei quantili della fonte (solo con i percentili, la mediana esclusa).
    var quantili: [Double] = []
    /// La parte piena (p10-p90 se la fonte li dà); nil = piena tutta.
    var parteCentrale: ClosedRange<Double>? = nil
}

/// Il confronto di una voce con un gruppo.
struct ConfrontoVoceFamiglie: Identifiable, Equatable {
    let voce: VoceFamiglie
    let ambito: AmbitoFamiglie
    let metodo: MetodoConfrontoFamiglie
    /// La cifra del cliente usata (% per il tasso di risparmio, euro altrimenti; 1/0 per la quota).
    let valoreCliente: Double?
    /// Percentile stimato con i quantili (0-100, per difetto); nil con mediana, media, rapporto e quota: nessun
    /// percentile inventato.
    let percentile: Int?
    /// Con la mediana, la media, il rapporto o la quota: sopra (o «ha la cosa»). nil con i quantili o senza confronto.
    let sopra: Bool?
    /// Il valore del gruppo: la mediana, la media, il rapporto o la quota (con i quantili la mediana, se c'è).
    let riferimento: Double?
    /// La barra già calcolata (nil = la voce non ha dati).
    let barra: BarraFamiglie?
    /// Che cifra dà il gruppo (quantili, mediana, media, rapporto, quota), anche quando manca quella del cliente.
    let tipoGruppo: MetodoConfrontoFamiglie
    /// La frase in chiaro («Risparmia più di circa 7 famiglie su 10 come la sua.»).
    let frase: String
    /// Le cautele della voce (campione piccolo, dato stimato, dato mancante, tipo di statistica).
    let cautele: [String]

    init(voce: VoceFamiglie, ambito: AmbitoFamiglie = .cella, metodo: MetodoConfrontoFamiglie, valoreCliente: Double? = nil,
         percentile: Int? = nil, sopra: Bool? = nil, riferimento: Double? = nil, barra: BarraFamiglie? = nil,
         tipoGruppo: MetodoConfrontoFamiglie? = nil, frase: String, cautele: [String] = []) {
        self.voce = voce
        self.ambito = ambito
        self.metodo = metodo
        self.valoreCliente = valoreCliente
        self.percentile = percentile
        self.sopra = sopra
        self.riferimento = riferimento
        self.barra = barra
        self.tipoGruppo = tipoGruppo ?? metodo
        self.frase = frase
        self.cautele = cautele
    }

    var id: String { ambito.rawValue + "." + voce.rawValue }
}

/// Il confronto con un gruppo di famiglie: la cella età × reddito (versione 1) o una classe di un gruppo (versione 2).
struct GruppoConfrontoFamiglie: Identifiable, Equatable {
    let ambito: AmbitoFamiglie
    /// La classe del cliente nel gruppo (età, quinto di reddito o «tutte»); nil per la cella.
    let classe: ClasseFamiglie?
    /// Famiglie del campione nel gruppo (nil = non dichiarate).
    let famiglie: Int?
    /// Meno famiglie della soglia (o numero non dichiarato): il confronto è solo indicativo.
    let campioneRidotto: Bool
    /// Le voci che il gruppo ha, nell'ordine di `VoceFamiglie.allCases`.
    let voci: [ConfrontoVoceFamiglie]

    var id: String { ambito.rawValue }

    func voce(_ v: VoceFamiglie) -> ConfrontoVoceFamiglie? { voci.first { $0.voce == v } }
}

/// Il confronto del cliente con le famiglie come la sua.
struct ConfrontoFamiglie: Equatable {
    /// La classe d'età e quella di reddito del cliente (nella cella o nei due gruppi).
    let classeEta: ClasseFamiglie?
    let classeReddito: ClasseFamiglie?
    /// I gruppi del confronto: la cella (versione 1) o età, quinto di reddito e tutte le famiglie (versione 2).
    let gruppi: [GruppoConfrontoFamiglie]
    /// Le avvertenze generali (dati di prova, età o reddito mancanti, soglie dei quinti, capofamiglia).
    let avvisi: [String]
    let diProva: Bool
    let fonte: String
    let edizione: Int?
    let aggiornamento: String?
    /// Tavole a una dimensione (versione 2): il confronto è doppio, con l'età e con il quinto di reddito.
    let unaDimensione: Bool

    func gruppo(_ a: AmbitoFamiglie) -> GruppoConfrontoFamiglie? { gruppi.first { $0.ambito == a } }

    /// I confronti di una voce, uno per gruppo che la ha.
    func confronti(_ v: VoceFamiglie) -> [ConfrontoVoceFamiglie] { gruppi.compactMap { $0.voce(v) } }

    /// Il primo confronto di una voce (la cella, o le famiglie della sua età).
    func voce(_ v: VoceFamiglie) -> ConfrontoVoceFamiglie? { confronti(v).first }

    func voce(_ v: VoceFamiglie, ambito a: AmbitoFamiglie) -> ConfrontoVoceFamiglie? { gruppo(a)?.voce(v) }

    /// Le voci da mostrare: quelle che almeno un gruppo ha, nell'ordine di `VoceFamiglie.allCases`.
    var voci: [VoceFamiglie] { VoceFamiglie.allCases.filter { !confronti($0).isEmpty } }

    /// C'è un confronto vero: la cella, o almeno il gruppo dell'età o del reddito («tutte» da solo non basta).
    var haConfronto: Bool { gruppi.contains { $0.ambito != .tutte } }

    /// Versione 1: le famiglie della cella e il campione piccolo.
    var famiglieNellaCella: Int? { gruppo(.cella)?.famiglie }
    var campioneRidotto: Bool { gruppo(.cella)?.campioneRidotto ?? false }
}

/// Il confronto con le famiglie come quella del cliente (funzioni pure, nessuna dipendenza dalla UI).
/// Regole:
/// - versione 1: la cella è la classe d'età che contiene l'età (estremi inclusi) per la fascia di reddito che contiene
///   il reddito familiare netto (`da` incluso, `a` escluso);
/// - versione 2: il confronto è doppio, con la classe d'età e con il quinto di reddito, ognuno per conto suo (manca
///   l'età: resta il reddito, e viceversa); il gruppo «tutte» (per esempio i decimi della ricchezza netta) vale per
///   tutti;
/// - percentile (solo con almeno due quantili): interpolazione lineare tra i quantili adiacenti; sotto il primo da 0
///   (se il primo è positivo e il valore non è negativo), altrimenti 0; sopra l'ultimo si ferma al suo percentile; un
///   valore uguale a più quantili (masse, per esempio molte famiglie a zero) sta a metà tra il primo e l'ultimo di quei
///   percentili, e una massa che comincia dal primo quantile a un valore ≤ 0 parte da 0; arrotondamento per difetto;
/// - mediana, media o rapporto tra medie: sopra o sotto, nessun percentile; la barra è in valori (`scalaValori`);
/// - protezione e previdenza complementare con la quota: «ha / non ha» (sulla barra: metà della parte di chi ha, o
///   di chi non ha). Versione 1: la protezione è vita o danni; versione 2: solo polizze vita, come le tavole;
/// - cautela se il gruppo ha meno famiglie della soglia o non dice quante sono, o se la cifra del cliente è stimata.
enum MotoreFamiglie {
    /// Soglia del campione piccolo quando il file non la indica (da confermare con l'utente).
    static let sogliaPredefinita = 30

    // MARK: Classi

    static func classe(eta: Int, in classi: [ClasseFamiglie]) -> ClasseFamiglie? {
        let e = Double(eta)
        return classi.first { c in (c.da.map { e >= $0 } ?? true) && (c.a.map { e <= $0 } ?? true) }
    }

    static func classe(reddito: Double, in classi: [ClasseFamiglie]) -> ClasseFamiglie? {
        guard reddito.isFinite else { return nil }
        return classi.first { c in (c.da.map { reddito >= $0 } ?? true) && (c.a.map { reddito < $0 } ?? true) }
    }

    /// La classe d'età (versione 1: `classiEta`; versione 2: il gruppo «età»).
    static func classeEta(_ eta: Int, in t: TabelleFamiglie) -> ClasseFamiglie? {
        classe(eta: eta, in: t.unaDimensione ? (t.gruppo(.eta)?.classi.map(\.classe) ?? []) : t.classiEta)
    }

    /// La classe di reddito (versione 1: `classiReddito`; versione 2: il gruppo «reddito»).
    static func classeReddito(_ reddito: Double, in t: TabelleFamiglie) -> ClasseFamiglie? {
        classe(reddito: reddito, in: t.unaDimensione ? (t.gruppo(.reddito)?.classi.map(\.classe) ?? []) : t.classiReddito)
    }

    /// La cella età × reddito (versione 1).
    static func cella(eta: Int, reddito: Double, in t: TabelleFamiglie) -> CellaFamiglie? {
        guard let e = classeEta(eta, in: t), let r = classeReddito(reddito, in: t) else { return nil }
        return t.cella(eta: e.id, reddito: r.id)
    }

    // MARK: Percentile

    /// Il percentile stimato di `v` tra i quantili (non arrotondato, 0-100); nil con meno di due quantili.
    static func percentile(_ v: Double, quantili: [QuantileFamiglie]) -> Double? {
        let q = quantili.filter { $0.valore.isFinite && $0.percentile.isFinite }.sorted { $0.percentile < $1.percentile }
        guard q.count >= 2, v.isFinite, let primo = q.first, let ultimo = q.last else { return nil }
        let tolleranza = 1e-9
        let uguali = q.filter { abs($0.valore - v) <= tolleranza }
        if let basso = uguali.first, let alto = uguali.last {
            // Una massa che comincia dal primo quantile a zero (o sotto) parte dal fondo della distribuzione
            let inizio = (basso == primo && v <= 0 && uguali.count > 1) ? 0 : basso.percentile
            return (inizio + alto.percentile) / 2
        }
        if v < primo.valore {
            guard primo.valore > 0, v >= 0 else { return 0 }
            return primo.percentile * v / primo.valore
        }
        if v > ultimo.valore { return ultimo.percentile }
        for k in q.indices.dropFirst() where v < q[k].valore {
            let a = q[k - 1], b = q[k]
            let passo = b.valore - a.valore
            guard passo > 0 else { return b.percentile }
            return a.percentile + (b.percentile - a.percentile) * (v - a.valore) / passo
        }
        return ultimo.percentile
    }

    /// Il percentile per la barra, arrotondato per difetto tra 0 e 100.
    static func percentileIntero(_ p: Double) -> Int { Int(min(max(p, 0), 100).rounded(.down)) }

    // MARK: La barra in valori

    /// La barra in valori, quando la fonte dà solo un valore del gruppo (mediana, media, rapporto): la scala va da
    /// `basso` = min(0, gruppo, cliente) ad `alto` = max(2 × gruppo − basso, cliente + 15% della distanza da basso,
    /// basso + 1), così il valore del gruppo sta a metà finché il cliente non lo supera di molto; se `basso` è negativo
    /// si lascia un margine del 10% a sinistra. Restituisce le posizioni 0-100 del cliente (nil se manca) e della tacca.
    static func scalaValori(cliente x: Double?, gruppo r: Double) -> (cliente: Double?, tacca: Double) {
        let cliente = x.flatMap { $0.isFinite ? $0 : nil }
        guard r.isFinite else { return (nil, 50) }
        var basso = min(0, r, cliente ?? r)
        let arrivo = cliente ?? r
        let alto = max(2 * r - basso, arrivo + 0.15 * abs(arrivo - basso), basso + 1)
        if basso < 0 { basso -= 0.1 * (alto - basso) }
        let ampiezza = alto - basso
        func posizione(_ v: Double) -> Double { min(max((v - basso) / ampiezza * 100, 0), 100) }
        return (cliente.map(posizione), posizione(r))
    }

    // MARK: Confronto

    static func confronta(_ d: DatiFamigliaCliente, tabelle t: TabelleFamiglie) -> ConfrontoFamiglie {
        t.unaDimensione ? confrontaGruppi(d, tabelle: t) : confrontaCella(d, tabelle: t)
    }

    /// Le cautele del campione di un gruppo: poche famiglie o numero non dichiarato.
    private static func cauteleCampione(_ famiglie: Int?, soglia: Int) -> (ridotto: Bool, cautele: [String]) {
        guard let n = famiglie else { return (true, [TestiFamiglie.famiglieNonDichiarate]) }
        return n < soglia ? (true, [TestiFamiglie.pocheFamiglie(n)]) : (false, [])
    }

    /// Versione 1: la cella età × reddito.
    private static func confrontaCella(_ d: DatiFamigliaCliente, tabelle t: TabelleFamiglie) -> ConfrontoFamiglie {
        var avvisi: [String] = []
        if t.diProva { avvisi.append(TestiFamiglie.avvisoDiProva) }
        let classeE = d.eta.flatMap { classeEta($0, in: t) }
        let classeR = d.redditoFamiliare.flatMap { classeReddito($0, in: t) }
        let cella = classeE.flatMap { e in classeR.flatMap { r in t.cella(eta: e.id, reddito: r.id) } }
        if d.eta == nil || d.redditoFamiliare == nil {
            avvisi.append(TestiFamiglie.servonoEtaReddito)
        } else if cella == nil {
            avvisi.append(TestiFamiglie.cellaNonTrovata)
        }
        if d.redditoSoloFamiliari { avvisi.append(TestiFamiglie.redditoSoloFamiliari) }
        var gruppi: [GruppoConfrontoFamiglie] = []
        if let c = cella {
            let campione = cauteleCampione(c.famiglie, soglia: t.sogliaFamiglie ?? sogliaPredefinita)
            let voci = VoceFamiglie.allCases.compactMap { v -> ConfrontoVoceFamiglie? in
                guard let dist = c.distribuzione(v) else { return nil }
                return confrontaVoce(v, dati: d, distribuzione: dist, cautele: campione.cautele)
            }
            gruppi.append(GruppoConfrontoFamiglie(ambito: .cella, classe: nil, famiglie: c.famiglie,
                                                  campioneRidotto: campione.ridotto, voci: voci))
        }
        return ConfrontoFamiglie(classeEta: classeE, classeReddito: classeR, gruppi: gruppi, avvisi: avvisi,
                                 diProva: t.diProva, fonte: t.fonte, edizione: t.edizione,
                                 aggiornamento: t.aggiornamento, unaDimensione: false)
    }

    /// Versione 2: il confronto doppio, con le famiglie della stessa età e con quelle dello stesso quinto di reddito,
    /// più il gruppo di tutte le famiglie se il file lo ha.
    private static func confrontaGruppi(_ d: DatiFamigliaCliente, tabelle t: TabelleFamiglie) -> ConfrontoFamiglie {
        var avvisi: [String] = []
        if t.diProva { avvisi.append(TestiFamiglie.avvisoDiProva) }
        let gEta = t.gruppo(.eta)
        let gReddito = t.gruppo(.reddito)
        let classeE = d.eta.flatMap { e in gEta.flatMap { g in classe(eta: e, in: g.classi.map(\.classe)) } }
        let classeR = d.redditoFamiliare.flatMap { r in gReddito.flatMap { g in classe(reddito: r, in: g.classi.map(\.classe)) } }
        switch (d.eta, d.redditoFamiliare) {
        case (nil, nil): avvisi.append(TestiFamiglie.servonoEtaReddito)
        case (nil, _): if gEta != nil { avvisi.append(TestiFamiglie.mancaEta) }
        case (_, nil): if gReddito != nil { avvisi.append(TestiFamiglie.mancaReddito) }
        default: break
        }
        if d.eta != nil, gEta != nil, classeE == nil { avvisi.append(TestiFamiglie.etaFuoriClassi) }
        if d.redditoFamiliare != nil, gReddito != nil, classeR == nil { avvisi.append(TestiFamiglie.redditoFuoriClassi) }
        if d.redditoSoloFamiliari, classeR != nil { avvisi.append(TestiFamiglie.redditoSoloFamiliari) }
        if classeR != nil, let e = t.edizione { avvisi.append(TestiFamiglie.sogliePerAnno(e)) }
        if classeE != nil || classeR != nil { avvisi.append(TestiFamiglie.capofamiglia) }

        let soglia = t.sogliaFamiglie ?? sogliaPredefinita
        var gruppi: [GruppoConfrontoFamiglie] = []
        for g in t.gruppi {
            let scelta: ClasseGruppoFamiglie?
            switch g.dimensione {
            case .eta: scelta = classeE.flatMap { c in g.classi.first { $0.id == c.id } }
            case .reddito: scelta = classeR.flatMap { c in g.classi.first { $0.id == c.id } }
            case .tutte: scelta = g.classi.first
            }
            guard let k = scelta else { continue }
            let ambito = AmbitoFamiglie(g.dimensione)
            let campione = cauteleCampione(k.famiglie, soglia: soglia)
            let voci = VoceFamiglie.allCases.compactMap { v -> ConfrontoVoceFamiglie? in
                guard let x = k.valore(v) else { return nil }
                var cautele = campione.cautele
                if ambito == .tutte { cautele.append(TestiFamiglie.distribuzioneComplessiva) }
                return confrontaVoce(v, dati: d, distribuzione: x.distribuzione, cautele: cautele, ambito: ambito,
                                     statistica: x.statistica)
            }
            gruppi.append(GruppoConfrontoFamiglie(ambito: ambito, classe: k.classe, famiglie: k.famiglie,
                                                  campioneRidotto: campione.ridotto, voci: voci))
        }
        // Prima l'età, poi il reddito, poi tutte le famiglie, qualunque sia l'ordine nel file
        let ordine: [AmbitoFamiglie] = [.eta, .reddito, .tutte]
        gruppi.sort { (ordine.firstIndex(of: $0.ambito) ?? 9) < (ordine.firstIndex(of: $1.ambito) ?? 9) }
        return ConfrontoFamiglie(classeEta: classeE, classeReddito: classeR, gruppi: gruppi, avvisi: avvisi,
                                 diProva: t.diProva, fonte: t.fonte, edizione: t.edizione,
                                 aggiornamento: t.aggiornamento, unaDimensione: true)
    }

    /// Il confronto di una voce con un gruppo. `statistica` (versione 2) dice di che cifra si tratta; senza, la si
    /// ricava dalla distribuzione (versione 1). Fuori dalla cella (versione 2) la protezione è «polizze vita».
    static func confrontaVoce(_ v: VoceFamiglie, dati d: DatiFamigliaCliente, distribuzione: DistribuzioneFamiglie?,
                              cautele cauteleGruppo: [String], ambito: AmbitoFamiglie = .cella,
                              statistica: StatisticaFamiglie? = nil) -> ConfrontoVoceFamiglie {
        func senza(_ frase: String, _ cautele: [String] = [], riferimento: Double? = nil,
                   barra: BarraFamiglie? = nil, tipo: MetodoConfrontoFamiglie = .nessuno) -> ConfrontoVoceFamiglie {
            ConfrontoVoceFamiglie(voce: v, ambito: ambito, metodo: .nessuno, riferimento: riferimento, barra: barra,
                                  tipoGruppo: tipo, frase: frase, cautele: cautele)
        }
        guard let dist = distribuzione, !dist.vuota else { return senza(TestiFamiglie.voceSenzaDati) }
        var cautele = cauteleGruppo
        if v == .tassoRisparmio, d.risparmioSoloVersamenti { cautele.append(TestiFamiglie.risparmioSoloVersamenti) }

        // Protezione e previdenza con la quota: ha / non ha
        if v == .protezione || v == .previdenzaComplementare, let quota = dist.quota {
            let soloVita = ambito != .cella
            let ha: Bool? = v == .protezione ? (soloVita ? d.haPolizzaVita : d.haProtezione) : d.haPrevidenzaComplementare
            let tacca = 100 - quota
            guard let ha else {
                return senza(TestiFamiglie.manca(v), cautele, riferimento: quota,
                             barra: BarraFamiglie(scala: .quota, cliente: nil, tacca: tacca), tipo: .quota)
            }
            cautele.append(TestiFamiglie.soloRegistrate)
            let posizione = ha ? 100 - quota / 2 : (100 - quota) / 2
            let frase = ambito == .cella ? TestiFamiglie.fraseQuota(v, ha: ha, quota: quota)
                : TestiFamiglie.fraseQuota(v, ha: ha, quota: quota, ambito: ambito)
            return ConfrontoVoceFamiglie(voce: v, ambito: ambito, metodo: .quota, valoreCliente: ha ? 1 : 0, sopra: ha,
                                         riferimento: quota, barra: BarraFamiglie(scala: .quota, cliente: posizione, tacca: tacca),
                                         frase: frase, cautele: cautele)
        }

        if v == .ricchezzaNetta { cautele.append(TestiFamiglie.nettaSoloRegistrate) }
        let quantili = dist.quantili
        let conQuantili = quantili.count >= 2 && (statistica == nil || statistica == .quantili)
        let riferimento = dist.p50 ?? dist.media
        let x = d.valore(v).flatMap { $0.isFinite ? $0 : nil }

        // Con i quantili: il percentile
        if conQuantili {
            let tacche = quantili.map(\.percentile).filter { $0 != 50 }
            let centrale: ClosedRange<Double>? = dist.p10 != nil && dist.p90 != nil ? 10...90 : nil
            guard let x, let p = percentile(x, quantili: quantili) else {
                return senza(TestiFamiglie.manca(v), cautele, riferimento: riferimento,
                             barra: BarraFamiglie(scala: .percentili, cliente: nil, tacca: 50, quantili: tacche, parteCentrale: centrale),
                             tipo: .quantili)
            }
            let intero = percentileIntero(p)
            return ConfrontoVoceFamiglie(voce: v, ambito: ambito, metodo: .quantili, valoreCliente: x, percentile: intero,
                                         riferimento: riferimento,
                                         barra: BarraFamiglie(scala: .percentili, cliente: Double(intero), tacca: 50,
                                                              quantili: tacche, parteCentrale: centrale),
                                         frase: TestiFamiglie.frasePercentile(v, percentile: intero, ambito: ambito),
                                         cautele: cautele)
        }

        // Con un solo valore del gruppo: sopra o sotto, la barra in valori
        let metodo: MetodoConfrontoFamiglie
        let gruppo: Double
        switch (statistica, dist.p50, dist.media) {
        case (.mediana?, let m?, _), (nil, let m?, _):
            metodo = .mediana
            gruppo = m
            cautele.append(TestiFamiglie.soloMediana)
        case (.rapportoTraMedie?, _, let m?):
            metodo = .rapportoMedie
            gruppo = m
            cautele.append(TestiFamiglie.rapportoTraMedie(v))
        case (_, _, let m?):
            metodo = .media
            gruppo = m
            cautele.append(TestiFamiglie.soloMedia)
        default:
            return senza(TestiFamiglie.voceSenzaDati, cautele)
        }
        let scala = scalaValori(cliente: x, gruppo: gruppo)
        let barra = BarraFamiglie(scala: .valori, cliente: scala.cliente, tacca: scala.tacca)
        guard let x else { return senza(TestiFamiglie.manca(v), cautele, riferimento: gruppo, barra: barra, tipo: metodo) }
        let pari = abs(x - gruppo) < 1e-9
        let frase: String
        if ambito == .cella {
            frase = metodo == .mediana ? TestiFamiglie.fraseMediana(v, sopra: x > gruppo, pari: pari)
                : TestiFamiglie.fraseMedia(v, sopra: x > gruppo, pari: pari)
        } else {
            frase = TestiFamiglie.fraseValore(v, metodo: metodo, cliente: x, gruppo: gruppo, ambito: ambito)
        }
        return ConfrontoVoceFamiglie(voce: v, ambito: ambito, metodo: metodo, valoreCliente: x, sopra: x > gruppo,
                                     riferimento: gruppo, barra: barra, frase: frase, cautele: cautele)
    }

    // MARK: Le cifre del cliente dai motori esistenti

    /// Le cifre del cliente dall'archivio: età al giorno `oggi`; reddito netto del cliente più quello dei familiari;
    /// risparmio libero del profilo più i versamenti annui delle posizioni finanziarie in essere (come la linea della
    /// vita); patrimonio finanziario = liquidità e posizioni di investimento, risparmio e previdenza in essere dei due
    /// canali (come la linea della vita); protezione dalle coperture in essere di `MotoreProtezioneFamiglia`;
    /// ricchezza netta = tutte le posizioni in essere tranne le coperture, debiti tolti; polizze vita = coperture caso
    /// morte o polizze vita di investimento o risparmio in essere; previdenza complementare dai piani in essere di
    /// `MotorePrevidenza`.
    static func dati(cliente: Cliente, posizioni: [Posizione], oggi: Date = Date()) -> DatiFamigliaCliente {
        let proprie = posizioni.filter { $0.clienteId == cliente.id }
        var d = DatiFamigliaCliente()
        d.eta = MotorePensionePubblica.etaAl(cliente.dataNascita, oggi)

        // Reddito familiare netto: cliente più familiari con reddito
        let proprio = cliente.profilo.redditoNettoAnnuo.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        let familiari = cliente.famiglia.compactMap { $0.redditoNettoAnnuo }.filter { $0.isFinite && $0 > 0 }.reduce(0, +)
        let totale = (proprio ?? 0) + familiari
        d.redditoFamiliare = totale > 0 ? totale : nil
        d.redditoSoloFamiliari = proprio == nil && familiari > 0

        // Patrimonio e risparmio: le posizioni finanziarie in essere, come la linea della vita
        let finanziarie = proprie.filter { $0.stato == .inEssere && $0.valore > 0 && ($0.area.proiettabile || $0.area == .liquidita) }
        d.ricchezzaFinanziaria = finanziarie.isEmpty ? nil : finanziarie.reduce(0) { $0 + $1.valore }

        // Ricchezza netta: tutte le posizioni in essere tranne le coperture, immobili compresi, debiti tolti
        let patrimoniali = proprie.filter { $0.stato == .inEssere && $0.area != .protezione }
        d.ricchezzaNetta = patrimoniali.isEmpty ? nil : patrimoniali.reduce(0) { $0 + ($1.area.passivo ? -$1.valore : $1.valore) }
        let versamenti = proprie.filter { $0.stato == .inEssere && $0.area.proiettabile }.reduce(0) { $0 + $1.premioAnnuo }
        if let libero = cliente.profilo.risparmioAnnuo, libero.isFinite, libero >= 0 {
            d.risparmioAnnuo = libero + versamenti
        } else if versamenti > 0 {
            d.risparmioAnnuo = versamenti
            d.risparmioSoloVersamenti = true
        }

        // Protezione: le coperture in essere del motore della protezione
        let protezione = MotoreProtezioneFamiglia.calcola(proprie, cliente: cliente, analisi: IpotesiProtezione(), data: oggi)
        d.haProtezione = !protezione.coperture.isEmpty
        d.premiProtezione = protezione.premiAnnui
        // Polizze vita, come le conta l'indagine: copertura caso morte o polizza vita di investimento o risparmio
        d.haPolizzaVita = proprie.contains { p in
            p.stato == .inEssere && ((p.area == .protezione && p.rischio == .vita)
                || ((p.area == .investimento || p.area == .risparmio) && p.regime == .polizza))
        }

        // Previdenza complementare: i piani in essere del motore della previdenza
        var ipotesi = IpotesiPrevidenza()
        if let eta = d.eta { ipotesi.eta = eta }
        let previdenza = MotorePrevidenza.calcola(proprie, cliente: cliente, analisi: ipotesi, data: oggi)
        d.haPrevidenzaComplementare = !previdenza.inEssere.isEmpty
        d.contributiPrevidenza = previdenza.contributiInEssere
        return d
    }

    /// Il confronto del cliente con le tabelle in uso (quelle caricate o, senza, le tavole incluse della Banca d'Italia).
    static func confronta(cliente: Cliente, posizioni: [Posizione], tabelle: TabelleFamiglie, oggi: Date = Date()) -> ConfrontoFamiglie {
        confronta(dati(cliente: cliente, posizioni: posizioni, oggi: oggi), tabelle: tabelle)
    }
}
