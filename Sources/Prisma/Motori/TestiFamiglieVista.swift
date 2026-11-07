import Foundation

/// I testi della vista «Rispetto alle famiglie come la sua» (Analisi 360, Orizzonte giro 6, specifica §10.1): il
/// segmentato, l'etichetta dei dati di prova, la frase grande, il sottotitolo dei gruppi, le righe delle voci, gli
/// stati senza dati e la nota con la fonte. Le frasi delle voci e le cautele restano quelle di `TestiFamiglie`
/// (MotoreFamiglie).
extension TestiFamiglie {
    // MARK: Segmentato ed etichetta

    static let segmentoAree = "Le quattro aree"
    static let segmentoFamiglie = "Rispetto alle famiglie come la sua"
    /// L'etichetta ben visibile se si usano tabelle di prova (solo se il consulente ne ha caricate).
    static let etichettaDiProva = "Dati di prova: in Impostazioni torna alle tavole della Banca d'Italia"
    static let aiutoEtichettaDiProva = "Apre Impostazioni › Rendimenti di confronto › Famiglie italiane"
    /// L'ancora del gruppo «Famiglie italiane» nelle Impostazioni (pagina Rendimenti di confronto).
    static let ancoraImpostazioni = "impostazioni-famiglie"

    // MARK: La frase grande (sempre la prima voce, il risparmio)

    /// «delle famiglie della sua età e del suo reddito» (cella), «delle famiglie della sua età», …
    private static func famiglieFraseGrande(_ a: AmbitoFamiglie) -> String {
        a == .cella ? "delle famiglie della sua età e del suo reddito" : famiglieDi(a)
    }

    /// La frase con la percentuale che si conta: il testo prima, il numero (già «100 − p» sotto la metà) e il testo
    /// dopo. Con il campione piccolo il numero ha «circa».
    static func fraseGrande(nome: String, percentile p: Int, ridotto: Bool,
                            ambito: AmbitoFamiglie = .cella) -> (prima: String, numero: Int, dopo: String) {
        let circa = ridotto ? " circa" : ""
        let chi = famiglieFraseGrande(ambito)
        if p >= 50 {
            return ("\(nome) risparmia più del ", p, "\(circa) \(chi).")
        }
        return ("Il ", 100 - p, "\(circa) \(chi) risparmia più di \(nome).")
    }

    /// Il formato del numero che si conta nella frase grande delle tavole a una dimensione: «28,7%».
    static var formatoTasso: FormatoCifra { .personalizzato(percentuale) }

    /// Tavole a una dimensione: il risparmio del gruppo (che si conta) e quello del cliente. «Le famiglie con
    /// capofamiglia della sua età risparmiano in media il 28,7% del reddito; Giulia il 15,0%.» Con la mediana: «Metà
    /// delle famiglie … risparmia almeno il …».
    static func fraseGrandeValore(nome: String, ambito: AmbitoFamiglie, metodo: MetodoConfrontoFamiglie, gruppo g: Double,
                                  cliente x: Double?) -> (prima: String, numero: Double, dopo: String) {
        let dopo = " del reddito" + (x.map { "; \(nome) \(ilPercentuale($0))." } ?? ".")
        let chi: String
        switch ambito {
        case .cella: chi = "famiglie come la sua"
        case .eta: chi = "famiglie con capofamiglia della sua età"
        case .reddito: chi = "famiglie del suo quinto di reddito"
        case .tutte: chi = "famiglie italiane"
        }
        if metodo == .mediana { return ("Metà delle \(chi) risparmia almeno \(articoloPercentuale(g))", g, dopo) }
        return ("Le \(chi) risparmiano in media \(articoloPercentuale(g))", g, dopo)
    }

    /// Senza percentile, quando la fonte dà solo la mediana o la media.
    static func fraseGrandeSenzaCifra(nome: String, sopra: Bool, metodo: MetodoConfrontoFamiglie) -> String {
        let confronto = metodo == .media ? "della famiglia media" : "della metà delle famiglie"
        return "\(nome) risparmia \(sopra ? "più" : "meno") \(confronto) della sua età e del suo reddito."
    }

    /// Senza il risparmio del cliente la frase grande dice solo con chi si confronta.
    static func fraseGrandeSenzaRisparmio(nome: String) -> String {
        "\(nome) a confronto con le famiglie della sua età e del suo reddito."
    }

    /// «Famiglie italiane con capofamiglia tra i 35 e i 44 anni e un reddito familiare netto tra 40.000 e 50.000 €
    /// l'anno. 100 famiglie nel campione.»
    static func sottotitoloGruppo(eta: ClasseFamiglie?, reddito: ClasseFamiglie?, famiglie: Int?) -> String {
        var s = "Famiglie italiane con capofamiglia \(descriviEta(eta)) e un reddito familiare netto \(descriviReddito(reddito))."
        if let n = famiglie { s += " \(FormatoCifra.migliaia(Double(n))) famiglie nel campione." }
        return s
    }

    /// Tavole a una dimensione: «A confronto con le famiglie con capofamiglia tra i 35 e i 44 anni (860 nel campione)
    /// e con le famiglie del 4° quinto di reddito familiare netto, tra 35.594 € e 51.543 € l'anno nel 2022 (1.925 nel
    /// campione).»
    static func sottotitoloGruppi(_ c: ConfrontoFamiglie) -> String {
        func campione(_ g: GruppoConfrontoFamiglie) -> String {
            g.famiglie.map { " (\(FormatoCifra.migliaia(Double($0))) nel campione)" } ?? ""
        }
        var parti: [String] = []
        if let g = c.gruppo(.eta) {
            parti.append("famiglie con capofamiglia \(descriviEta(g.classe))" + campione(g))
        }
        if let g = c.gruppo(.reddito) {
            let anno = c.edizione.map { " nel \($0)" } ?? ""
            parti.append("famiglie \(quinto(g.classe)) di reddito familiare netto, \(descriviReddito(g.classe))\(anno)" + campione(g))
        }
        guard !parti.isEmpty else { return "" }
        return "A confronto con le " + parti.joined(separator: " e con le ") + "."
    }

    /// «del 4° quinto» (dal nome della classe), «della sua fascia» senza nome.
    private static func quinto(_ c: ClasseFamiglie?) -> String {
        guard let n = c?.nome, !n.isEmpty else { return "della sua fascia" }
        return "del \(n)"
    }

    /// L'etichetta della riga di un gruppo nella card di una voce (nil per la cella: una riga sola).
    static func etichettaGruppo(_ g: GruppoConfrontoFamiglie) -> String? {
        switch g.ambito {
        case .cella: return nil
        case .eta: return "Capofamiglia \(descriviEta(g.classe))"
        case .reddito: return "\(g.classe?.nome ?? "Fascia") di reddito"
        case .tutte: return "Tutte le famiglie italiane"
        }
    }

    /// Il valore del gruppo a destra della riga: «28,7%», «8.500 €», «20,0%» (nil se non c'è).
    static func valoreGruppo(_ c: ConfrontoVoceFamiglie) -> String? {
        guard let r = c.riferimento else { return nil }
        return c.barra?.scala == .quota ? percentuale(r) : cifra(c.voce, r)
    }

    /// La cifra del cliente in testa alla card: «15,0%», «30.000 €», «sì» / «no» con la quota, «—» se manca.
    static func valoreCliente(_ confronti: [ConfrontoVoceFamiglie]) -> String {
        guard let c = confronti.first(where: { $0.valoreCliente != nil }), let x = c.valoreCliente else { return cifraMancante }
        if c.metodo == .quota { return x > 0 ? "sì" : "no" }
        return cifra(c.voce, x)
    }

    /// «tra i 35 e i 44 anni», «fino a 34 anni», «dai 65 anni in su».
    static func descriviEta(_ c: ClasseFamiglie?) -> String {
        guard let c else { return "della sua età" }
        let da = c.da.map { Int($0) }
        let a = c.a.map { Int($0) }
        switch (da, a) {
        case let (d?, f?): return "tra \(articolo(d)) \(d) e \(articolo(f)) \(f) anni"
        case let (nil, f?): return "fino a \(f) anni"
        case let (d?, nil): return "\(articolo(d) == "gli" ? "dagli" : "dai") \(d) anni in su"
        case (nil, nil): return "di ogni età"
        }
    }

    /// «tra 40.000 e 50.000 € l'anno», «fino a 10.000 € l'anno», «da 40.000 € l'anno in su».
    static func descriviReddito(_ c: ClasseFamiglie?) -> String {
        guard let c else { return "simile" }
        func euro(_ v: Double) -> String { FormatoCifra.migliaia(v) + "\u{00A0}€" }
        switch (c.da, c.a) {
        case let (d?, f?): return "tra \(euro(d)) e \(euro(f)) l'anno"
        case let (nil, f?): return "fino a \(euro(f)) l'anno"
        case let (d?, nil): return "da \(euro(d)) l'anno in su"
        case (nil, nil): return "di ogni livello"
        }
    }

    /// «i 35», ma «gli 80» e «gli 11».
    private static func articolo(_ n: Int) -> String {
        let s = String(n)
        return s.hasPrefix("8") || s == "11" ? "gli" : "i"
    }

    // MARK: Le voci

    /// La cifra a destra dell'etichetta quando non c'è una percentuale: «sì» / «no» con la quota, «sopra» / «sotto»
    /// con la sola mediana o media, «in linea» se uguale.
    static func parolaVoce(_ c: ConfrontoVoceFamiglie) -> String? {
        guard let sopra = c.sopra else { return nil }
        switch c.metodo {
        case .quota: return sopra ? "sì" : "no"
        case .mediana, .media, .rapportoMedie: return sopra ? "sopra" : "sotto"
        case .quantili, .nessuno: return nil
        }
    }

    static let circa = "circa"
    static let cifraMancante = "—"

    /// La scritta sotto la tacca: la metà delle famiglie (percentili), il valore del gruppo (mediana, media) o, con la
    /// quota, il confine fra chi non ha la cosa (a sinistra) e chi l'ha.
    static func scrittaTacca(_ c: ConfrontoVoceFamiglie) -> String {
        switch c.barra?.scala {
        case .quota?:
            if c.voce == .previdenzaComplementare { return "da qui chi aderisce" }
            return c.ambito == .cella ? "da qui chi è protetto" : "da qui chi ha una polizza vita"
        case .valori?:
            return c.tipoGruppo == .mediana ? "mediana del gruppo" : "media del gruppo"
        default:
            return "metà delle famiglie"
        }
    }

    /// La frase che si legge con VoiceOver: «Risparmio, capofamiglia tra i 35 e i 44 anni: 28,7%, sotto. …»
    static func accessibilitaVoce(_ c: ConfrontoVoceFamiglie, gruppo: String? = nil) -> String {
        let cifra = c.percentile.map { "\($0)%" } ?? [valoreGruppo(c), parolaVoce(c)].compactMap { $0 }.joined(separator: ", ")
        let testa = gruppo.map { "\(nome(c.voce)), \($0)" } ?? nome(c.voce)
        return "\(testa): \(cifra.isEmpty ? "dato mancante" : cifra). \(c.frase)"
    }

    // MARK: Stati senza confronto

    static func servonoEtaRedditoDi(_ nome: String) -> String {
        "Per confrontare \(nome) servono età e reddito della famiglia."
    }
    static let completaNellaScheda = TestiCompletezza.completaNellaScheda + " ›"
    static let senzaTabelle = "Le tavole delle famiglie non si leggono: caricale da Impostazioni › Rendimenti di confronto."
    static let caricaInImpostazioni = "Carica le tabelle in Impostazioni ›"

    // MARK: Nota

    static let notaDiProva = "Confronto di prova: il file caricato ha valori segnaposto, non statistiche vere. "
        + "Le tavole della Banca d’Italia incluse in Prisma tornano con «Usa le tavole incluse» in Impostazioni."

    /// «Fonte: Banca d'Italia, …, edizione 2022 (…). Tabelle caricate il 3 novembre 2026: restano sul Mac, niente
    /// internet.» L'anno si aggiunge solo se la fonte non lo dice già.
    static func notaFonte(_ fonte: String, edizione: Int?, caricateIl data: Date?) -> String {
        var s = "Fonte: \(fonte)"
        if let e = edizione, !fonte.contains(String(e)) { s += ", \(e)" }
        s += "."
        if let d = data { s += " Tabelle caricate il \(d.formatted(date: .long, time: .omitted)): restano sul Mac, niente internet." }
        return s
    }

    /// Sotto la fonte, per le tavole a una dimensione.
    static let notaUnaDimensione = "Le tavole danno una caratteristica alla volta, età oppure quinto di reddito, non incrociate: per questo i confronti sono due."
}
