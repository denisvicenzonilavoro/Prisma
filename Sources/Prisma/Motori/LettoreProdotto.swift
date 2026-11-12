import Foundation

/// «La scheda dai documenti» (12 novembre 2026): dai documenti ufficiali di un prodotto (KID, DIP, DIP aggiuntivo,
/// condizioni di contratto o di assicurazione, scheda costi) la scheda del catalogo, con costi, trattenute, tassazione,
/// rischio, periodo raccomandato, garanzie e i quattro scenari del KID. Solo regole di Prisma (le formule dei documenti
/// sono quelle del Regolamento PRIIPs e del Regolamento IVASS 41/2018): ogni dato porta il documento, la pagina e la
/// riga da cui viene, più documenti si uniscono per voce (il KID per costi e scenari, il DIP aggiuntivo per trattenuto,
/// penali e fiscalità) e dove due documenti non dicono la stessa cosa il dato resta «da scegliere». Nessun dato entra
/// nella scheda senza la conferma del consulente (`applica` prende solo le voci scelte). I testi restano sul Mac.
enum LettoreProdotto {

    // MARK: - Che cosa si legge

    /// Un documento già trasformato in testo (LetturaDocumenti: PDFKit e Vision), una stringa per pagina.
    struct DocumentoDaLeggere {
        var nome: String
        var pagine: [String]
    }

    enum TipoDocumento: String, CaseIterable {
        case kid, dipAggiuntivo, dip, condizioni, schedaCosti, altro

        var nome: String {
            switch self {
            case .kid: return "KID"
            case .dipAggiuntivo: return "DIP aggiuntivo"
            case .dip: return "DIP"
            case .condizioni: return "Condizioni"
            case .schedaCosti: return "Scheda costi"
            case .altro: return "Documento"
            }
        }

        /// Quanto vale questo documento per una voce (più alto = vince): il KID per costi, rischio e scenari, il DIP
        /// aggiuntivo per gestione separata, riscatto e fiscalità, le condizioni come riserva.
        func peso(per v: Voce) -> Int {
            switch (self, v.gruppo) {
            case (.kid, .kid): return 5
            case (.schedaCosti, .kid): return 3
            case (.dipAggiuntivo, .contratto), (.dipAggiuntivo, .fisco): return 5
            case (.condizioni, .contratto), (.condizioni, .fisco): return 4
            case (.dipAggiuntivo, .kid): return 2
            case (.kid, _): return 3
            case (.dipAggiuntivo, _), (.dip, _): return 2
            case (.condizioni, _), (.schedaCosti, _): return 1
            case (.altro, _): return 0
            }
        }
    }

    /// Le voci della scheda che i documenti possono dare.
    enum Voce: String, CaseIterable, Identifiable {
        case nome, emittente, tipologia, isin, dataDocumento
        case sri, periodoRaccomandato, esempioKID
        case costoIngresso, costoUscita, costoGestione, costiTransazione, commissioniPerformance
        case incidenzaUnAnno, incidenzaPeriodo, rendimentoPrimaCosti
        case scenarioStress, scenarioSfavorevole, scenarioModerato, scenarioFavorevole
        case trattenuto, minimoGarantito, caricamento, costoFisso, penali, bloccoRiscatto
        case impostaPremi, aliquota, quotaTitoliStato

        var id: String { rawValue }

        enum Gruppo { case identita, kid, contratto, fisco }

        var gruppo: Gruppo {
            switch self {
            case .nome, .emittente, .tipologia, .isin, .dataDocumento: return .identita
            case .sri, .periodoRaccomandato, .esempioKID, .costoIngresso, .costoUscita, .costoGestione, .costiTransazione,
                 .commissioniPerformance, .incidenzaUnAnno, .incidenzaPeriodo, .rendimentoPrimaCosti,
                 .scenarioStress, .scenarioSfavorevole, .scenarioModerato, .scenarioFavorevole: return .kid
            case .trattenuto, .minimoGarantito, .caricamento, .costoFisso, .penali, .bloccoRiscatto: return .contratto
            case .impostaPremi, .aliquota, .quotaTitoliStato: return .fisco
            }
        }

        var etichetta: String {
            switch self {
            case .nome: return "Nome del prodotto"
            case .emittente: return "Compagnia o emittente"
            case .tipologia: return "Tipologia"
            case .isin: return "ISIN"
            case .dataDocumento: return "Data del documento"
            case .sri: return "Rischio (SRI)"
            case .periodoRaccomandato: return "Periodo raccomandato"
            case .esempioKID: return "Esempio del KID"
            case .costoIngresso: return "Costi d'ingresso"
            case .costoUscita: return "Costi d'uscita"
            case .costoGestione: return "Costi di gestione"
            case .costiTransazione: return "Costi di transazione"
            case .commissioniPerformance: return "Commissioni di performance"
            case .incidenzaUnAnno: return "Incidenza dei costi a 1 anno"
            case .incidenzaPeriodo: return "Incidenza dei costi al periodo"
            case .rendimentoPrimaCosti: return "Rendimento prima dei costi"
            case .scenarioStress: return "Scenario di stress"
            case .scenarioSfavorevole: return "Scenario sfavorevole"
            case .scenarioModerato: return "Scenario moderato"
            case .scenarioFavorevole: return "Scenario favorevole"
            case .trattenuto: return "Trattenuto sul rendimento"
            case .minimoGarantito: return "Minimo garantito"
            case .caricamento: return "Caricamento sul premio"
            case .costoFisso: return "Costi fissi"
            case .penali: return "Penali di riscatto"
            case .bloccoRiscatto: return "Riscatto possibile dopo"
            case .impostaPremi: return "Imposta sui premi"
            case .aliquota: return "Tassazione dei rendimenti"
            case .quotaTitoliStato: return "Titoli di Stato (12,5%)"
            }
        }

        static let scenari: [Voce] = [.scenarioStress, .scenarioSfavorevole, .scenarioModerato, .scenarioFavorevole]
    }

    /// Un dato letto: il testo da mostrare, i numeri (per gli scenari: rendimento medio a 1 anno e al periodo; per le
    /// penali: una per anno dal secondo), la fonte e le alternative degli altri documenti.
    struct DatoLetto: Equatable {
        var voce: Voce
        var testo: String
        var numeri: [Double] = []
        var documento: String
        var tipo: TipoDocumento
        var pagina: Int
        var estratto: String
        /// Lo stesso dato in altri documenti, con un valore diverso: si sceglie a mano.
        var alternative: [DatoLetto] = []

        var numero: Double? { numeri.first }
        var daScegliere: Bool { !alternative.isEmpty }
    }

    /// Il tipo di prodotto riconosciuto dalle parole dei documenti.
    struct Riconoscimento: Equatable {
        var area: AreaPosizione
        var tipologia: String
        var gestioneSeparata: Bool
    }

    /// Quello che i documenti dicono, voce per voce.
    struct Lettura {
        var documenti: [(nome: String, tipo: TipoDocumento)] = []
        var dati: [Voce: DatoLetto] = [:]
        var riconoscimento: Riconoscimento?
        /// Il testo dei documenti letti, per aggiungerne altri senza rileggerli.
        var documentiLetti: [DocumentoDaLeggere] = []

        func dato(_ v: Voce) -> DatoLetto? { dati[v] }
        /// Le voci trovate, nell'ordine della scheda.
        var trovate: [Voce] { Voce.allCases.filter { dati[$0] != nil } }
        /// Le voci del KID che mancano (per dire che cosa non si è trovato).
        var mancantiKID: [Voce] {
            [.sri, .periodoRaccomandato, .costoIngresso, .costoGestione, .incidenzaPeriodo, .scenarioModerato]
                .filter { dati[$0] == nil }
        }
    }

    // MARK: - Lettura

    /// Legge tutti i documenti e unisce i dati: per ogni voce vince il documento più adatto (`TipoDocumento.peso`); se un
    /// altro documento ha un valore diverso, resta fra le alternative.
    static func leggi(_ documenti: [DocumentoDaLeggere]) -> Lettura {
        var l = Lettura()
        var tutti: [Voce: [DatoLetto]] = [:]
        var testoIntero = ""
        for d in documenti {
            let pagine = d.pagine.map(normalizza)
            let tipo = tipo(di: pagine)
            l.documenti.append((d.nome, tipo))
            testoIntero += pagine.joined(separator: "\n") + "\n"
            for dato in leggi(pagine: pagine, nome: d.nome, tipo: tipo) { tutti[dato.voce, default: []].append(dato) }
        }
        for (voce, elenco) in tutti {
            let ordinati = elenco.enumerated().sorted { a, b in
                let pa = a.element.tipo.peso(per: voce), pb = b.element.tipo.peso(per: voce)
                return pa != pb ? pa > pb : a.offset < b.offset
            }.map(\.element)
            guard var primo = ordinati.first else { continue }
            var visti: [String] = [chiave(primo)]
            for altro in ordinati.dropFirst() where !visti.contains(chiave(altro)) {
                visti.append(chiave(altro))
                primo.alternative.append(altro)
            }
            l.dati[voce] = primo
        }
        l.riconoscimento = riconosci(testoIntero)
        // La tipologia riconosciuta da Prisma è più chiara della riga «Tipo:» del KID (che va spesso a capo): la riga
        // resta come fonte
        if let r = l.riconoscimento {
            let fonte = l.dati[.tipologia]
            l.dati[.tipologia] = DatoLetto(voce: .tipologia, testo: r.tipologia, documento: fonte?.documento ?? (l.documenti.first?.nome ?? ""),
                                          tipo: fonte?.tipo ?? (l.documenti.first?.tipo ?? .altro), pagina: fonte?.pagina ?? 1,
                                          estratto: fonte.map { "Riconosciuta da Prisma; nel documento: «\($0.testo)»" } ?? "Riconosciuta da Prisma dalle parole dei documenti")
        }
        return l
    }

    /// Due dati sono «lo stesso» se hanno gli stessi numeri (o lo stesso testo, senza numeri).
    private static func chiave(_ d: DatoLetto) -> String {
        d.numeri.isEmpty ? d.testo.lowercased() : d.numeri.map { String(format: "%.3f", $0) }.joined(separator: "|")
    }

    /// Spazi e simboli dei PDF: il meno tipografico diventa il trattino, gli spazi duri spazi, le tabulazioni spazi.
    static func normalizza(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{2212}", with: "-")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{2009}", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
    }

    /// Il tipo di un documento dalle sue prime pagine.
    static func tipo(di pagine: [String]) -> TipoDocumento {
        let t = pagine.prefix(2).joined(separator: " ").lowercased()
        if t.contains("dip aggiuntivo") || t.contains("documento informativo precontrattuale aggiuntivo") { return .dipAggiuntivo }
        if t.contains("documento contenente le informazioni chiave") || t.contains("key information document")
            || t.contains("informazioni chiave per gli investitori") { return .kid }
        if t.contains("documento informativo precontrattuale") || t.range(of: #"\bdip\b"#, options: .regularExpression) != nil { return .dip }
        if t.contains("condizioni di assicurazione") || t.contains("condizioni contrattuali") || t.contains("condizioni generali") { return .condizioni }
        if t.contains("scheda costi") || t.contains("indicatore sintetico dei costi") || t.contains("scheda dei costi") { return .schedaCosti }
        return .altro
    }

    // MARK: - Le regole

    private static let numero = #"(-?\d{1,3}(?:\.\d{3})*(?:,\d+)?|-?\d+(?:[.,]\d+)?)"#
    private static let percento = numero + #"\s*%"#
    private static let importo = #"(\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?|\d+(?:,\d{1,2})?)\s*(?:€|eur(?:o)?)"#
    private static let nonAddebitati = #"(non (?:addebitiamo|applichiamo|sono previst|è previst|vengono applicat|si applica|ci sono)|nessun (?:costo|caricamento)|non applicabil|n\.?\s?a\.?\b)"#

    /// I dati di un documento. Ogni regola dà la prima occorrenza nelle pagine, con pagina e riga.
    static func leggi(pagine: [String], nome: String, tipo: TipoDocumento) -> [DatoLetto] {
        var dati: [DatoLetto] = []
        func aggiungi(_ v: Voce, _ testo: String, _ numeri: [Double], pagina: Int, estratto: String) {
            guard !dati.contains(where: { $0.voce == v }) else { return }
            dati.append(DatoLetto(voce: v, testo: testo, numeri: numeri, documento: nome, tipo: tipo,
                                  pagina: pagina, estratto: String(estratto.replacingOccurrences(of: "\n", with: " ").prefix(180))))
        }
        // Prima i dati che il lettore dei documenti di Prisma sa già (nome, emittente, SRI, periodo, ISIN, data…)
        for c in EstrattoreDocumento.conRegole(pagine) {
            let v: Voce?
            switch c.chiave {
            case .nomeProdotto: v = .nome
            case .emittente: v = .emittente
            case .tipologia: v = .tipologia
            case .isin: v = .isin
            case .dataDocumento: v = .dataDocumento
            case .sri: v = .sri
            case .periodoDetenzione: v = .periodoRaccomandato
            case .rendimentoPrimaCosti: v = .rendimentoPrimaCosti
            default: v = nil
            }
            guard let v else { continue }
            let n = EstrattoreDocumento.numero(c.valore.components(separatedBy: CharacterSet(charactersIn: "0123456789,.-").inverted)
                .first { !$0.isEmpty && $0.contains(where: \.isNumber) })
            let numeri: [Double]
            switch v {
            case .sri, .periodoRaccomandato, .rendimentoPrimaCosti: numeri = n.map { [$0] } ?? []
            default: numeri = []
            }
            if (v == .sri || v == .periodoRaccomandato || v == .rendimentoPrimaCosti) && numeri.isEmpty { continue }
            // Un nome o una compagnia con cifre è una riga presa per sbaglio («trattenuto dalla compagnia: 1,30 punti…»)
            if (v == .nome || v == .emittente) && c.valore.range(of: #"\d+[,.]?\d*\s*(%|punti)"#, options: .regularExpression) != nil { continue }
            let testo: String
            switch v {
            case .sri: testo = "\(Int(numeri[0])) su 7"
            case .periodoRaccomandato: testo = "\(Int(numeri[0])) anni"
            case .rendimentoPrimaCosti: testo = Formati.percentuale(numeri[0])
            default: testo = c.valore
            }
            aggiungi(v, testo, numeri, pagina: c.pagina, estratto: c.estratto)
        }
        for (i, pagina) in pagine.enumerated() {
            let n = i + 1
            let righe = pagina.components(separatedBy: "\n")
            // L'esempio del KID: «Esempio di investimento: 10.000 EUR», «Premio annuo: 1.000 EUR»
            if let m = trova(#"(?:esempio di investimento|investimento|premio (?:annuo|unico|ricorrente))\s*[:\-–]?\s*(?:€\s*)?(\d{1,3}(?:\.\d{3})+|\d{3,6})\s*(?:€|eur)"#, pagina) {
                let x = EstrattoreDocumento.numero(m.gruppo) ?? 0
                let annuo = m.riga.lowercased().contains("annuo") || m.riga.lowercased().contains("ricorrente")
                aggiungi(.esempioKID, "\(Formati.euro(x))\(annuo ? " l'anno" : "")", [x, annuo ? 1 : 0], pagina: n, estratto: m.riga)
            }
            // Composizione dei costi (KID): la percentuale della riga, oppure «non addebitiamo»
            costo(.costoIngresso, #"costi di (?:ingresso|sottoscrizione)"#, righe, n, &dati, nome, tipo)
            costo(.costoUscita, #"costi di (?:uscita|rimborso)"#, righe, n, &dati, nome, tipo)
            costo(.costoGestione, #"(?:commissioni di gestione e altri costi amministrativi o di esercizio|costi correnti|commissioni di gestione)"#, righe, n, &dati, nome, tipo)
            costo(.costiTransazione, #"costi di transazione"#, righe, n, &dati, nome, tipo)
            costo(.commissioniPerformance, #"commissioni (?:di performance|legate al rendimento|di incentivo)"#, righe, n, &dati, nome, tipo)
            // Costi nel tempo: «Incidenza annuale dei costi (*) 5,7% 2,0% ogni anno»: la prima a 1 anno, l'ultima al periodo
            if let m = trova(#"incidenza annuale dei costi(?:\s*\(\*+\))?([^\n]{0,140})"#, pagina) {
                let p = percentuali(m.gruppo)
                if let primo = p.first { aggiungi(.incidenzaUnAnno, "\(Formati.percentuale(primo))", [primo], pagina: n, estratto: m.riga) }
                if p.count > 1, let ultimo = p.last { aggiungi(.incidenzaPeriodo, "\(Formati.percentuale(ultimo))", [ultimo], pagina: n, estratto: m.riga) }
            }
            // Gli scenari: dopo il nome, la riga del rendimento medio annuo (prima colonna 1 anno, ultima il periodo)
            for (v, nomeScenario) in [(Voce.scenarioStress, "stress"), (.scenarioSfavorevole, "sfavorevole"),
                                      (.scenarioModerato, "moderato"), (.scenarioFavorevole, "favorevole")] {
                let schema = #"(?:scenario\s+)?\b"# + nomeScenario + #"\b[\s\S]{0,320}?rendimento medio[^\n%]{0,60}?([^\n]{0,120})"#
                guard let m = trova(schema, pagina), case let p = percentuali(m.gruppo), !p.isEmpty else { continue }
                // «sfavorevole» non vale per «favorevole»: \b vuole la parola intera
                let unAnno = p.first ?? 0, periodo = p.last ?? 0
                aggiungi(v, p.count > 1 ? "\(Formati.percentuale(unAnno)) a 1 anno · \(Formati.percentuale(periodo)) al periodo"
                                        : Formati.percentuale(unAnno), p.count > 1 ? [unAnno, periodo] : [unAnno],
                         pagina: n, estratto: m.riga)
            }
            // DIP aggiuntivo e condizioni: gestione separata, caricamenti, costi fissi, riscatto
            if let m = trova(#"(?:rendimento trattenuto|trattenut[oa] (?:dalla compagnia|dall'impresa|sul rendimento)|commissione di gestione[^\n]{0,60}?trattenut|trattiene[^\n]{0,60}?)[^\n%]{0,80}?"# + numero + #"\s*(?:%|punti percentuali)"#, pagina) {
                if let x = EstrattoreDocumento.numero(m.gruppo) { aggiungi(.trattenuto, "\(Formati.percentuale(x)) l'anno", [x], pagina: n, estratto: m.riga) }
            }
            if let m = trova(#"(?:tasso (?:di rendimento )?minimo garantito|rendimento minimo garantito|minimo garantito)[^\n%]{0,60}?"# + percento, pagina) {
                if let x = EstrattoreDocumento.numero(m.gruppo) { aggiungi(.minimoGarantito, "\(Formati.percentuale(x)) l'anno", [x], pagina: n, estratto: m.riga) }
            } else if let m = trova(#"(garanzia (?:di restituzione|di conservazione) del capitale|capitale garantito)"#, pagina) {
                aggiungi(.minimoGarantito, "Capitale garantito (0%)", [0], pagina: n, estratto: m.riga)
            }
            if let m = trova(#"caricament[oi][^\n%]{0,80}?"# + percento, pagina) {
                if let x = EstrattoreDocumento.numero(m.gruppo) { aggiungi(.caricamento, "\(Formati.percentuale(x)) del premio", [x], pagina: n, estratto: m.riga) }
            }
            if let m = trova(#"(?:diritti fissi|spese fisse|costo fisso|spese di emissione|costi fissi)[^\n\d]{0,60}?"# + importo + #"([^\n]{0,30})"#, pagina) {
                if let x = EstrattoreDocumento.numero(m.gruppo) {
                    let coda = m.riga.lowercased()
                    if coda.contains("una tantum") || coda.contains("emissione") && !coda.contains("ann") {
                        aggiungi(.costoFisso, "\(Formati.euro(x)) una tantum", [x, 0], pagina: n, estratto: m.riga)
                    } else {
                        let volte: Double = coda.contains("trimestr") ? 4 : coda.contains("mens") ? 12 : coda.contains("semestr") ? 2 : 1
                        aggiungi(.costoFisso, "\(Formati.euro(x * volte)) l'anno", [x * volte, 1], pagina: n, estratto: m.riga)
                    }
                }
            }
            if let (penali, riga) = penaliDiRiscatto(pagina) {
                aggiungi(.penali, penali.enumerated().map { "\($0.offset + 2)° anno \(Formati.percentuale($0.element))" }
                    .joined(separator: " · "), penali, pagina: n, estratto: riga)
            }
            if let m = trova(#"riscatt[oa][^\n.]{0,80}?(?:trascors[oi]|dopo|decorso|almeno)\s*(?:almeno\s*)?(un|uno|due|tre|\d{1,2})\s*(anno|anni|mes[ei])"#, pagina) {
                let parole = ["un": 1, "uno": 1, "due": 2, "tre": 3]
                let q = Int(m.gruppo) ?? parole[m.gruppo.lowercased()] ?? 1
                let mesi = m.riga.lowercased().contains("mes") ? q : q * 12
                aggiungi(.bloccoRiscatto, "\(mesi) mesi dalla decorrenza", [Double(mesi)], pagina: n, estratto: m.riga)
            }
            // Fiscalità
            if let m = trova(#"imposta sui premi[^\n%]{0,60}?"# + percento, pagina) {
                if let x = EstrattoreDocumento.numero(m.gruppo) { aggiungi(.impostaPremi, Formati.percentuale(x), [x], pagina: n, estratto: m.riga) }
            }
            if let m = trova(#"(?:imposta sostitutiva|tassazione|aliquota|ritenuta)[^\n%]{0,80}?(26|20|15|12,5)\s*%"#, pagina) {
                if let x = EstrattoreDocumento.numero(m.gruppo) { aggiungi(.aliquota, Formati.percentuale(x), [x], pagina: n, estratto: m.riga) }
            }
            if let m = trova(#"titoli (?:di stato|pubblici)[^\n%]{0,80}?(\d{1,3}(?:,\d+)?)\s*%"#, pagina),
               !m.riga.contains("12,5"), let x = EstrattoreDocumento.numero(m.gruppo), x > 0, x <= 100 {
                aggiungi(.quotaTitoliStato, "\(Formati.percentuale(x)) del portafoglio", [x], pagina: n, estratto: m.riga)
            }
        }
        return dati
    }

    /// Un costo della composizione dei costi del KID: la percentuale sulla riga dell'etichetta o sulla seguente
    /// (le tabelle a due colonne vanno spesso a capo), oppure zero se il documento dice che non si applica.
    private static func costo(_ v: Voce, _ etichetta: String, _ righe: [String], _ pagina: Int, _ dati: inout [DatoLetto],
                              _ nome: String, _ tipo: TipoDocumento) {
        guard !dati.contains(where: { $0.voce == v }) else { return }
        for (i, riga) in righe.enumerated() where riga.range(of: etichetta, options: [.regularExpression, .caseInsensitive]) != nil {
            let insieme = ([riga] + righe.dropFirst(i + 1).prefix(1)).joined(separator: " ")
            let dopo = insieme.range(of: etichetta, options: [.regularExpression, .caseInsensitive]).map { String(insieme[$0.upperBound...]) } ?? insieme
            if dopo.range(of: nonAddebitati, options: [.regularExpression, .caseInsensitive]) != nil,
               percentuali(String(dopo.prefix(60))).isEmpty {
                dati.append(DatoLetto(voce: v, testo: "Nessuno", numeri: [0], documento: nome, tipo: tipo, pagina: pagina,
                                      estratto: String(insieme.prefix(180))))
                return
            }
            if let x = percentuali(dopo).first {
                dati.append(DatoLetto(voce: v, testo: Formati.percentuale(x), numeri: [x], documento: nome, tipo: tipo,
                                      pagina: pagina, estratto: String(insieme.prefix(180))))
                return
            }
        }
    }

    /// Le penali di riscatto per anno: «nel 2° anno 3%, 3° anno 2%…», oppure una tabella «Anno 2 3,00%».
    /// Indice 0 = secondo anno (come `CondizioniContratto.penali`). nil se nella pagina non ci sono penali.
    static func penaliDiRiscatto(_ pagina: String) -> ([Double], String)? {
        let basso = pagina.lowercased()
        guard let r = basso.range(of: #"(penal[ei] di riscatto|riscatto[^\n]{0,80}penal|costi di riscatto)"#, options: .regularExpression) else { return nil }
        let tratto = String(pagina[r.lowerBound...].prefix(700))
        let ordinali = ["primo": 1, "secondo": 2, "terzo": 3, "quarto": 4, "quinto": 5, "sesto": 6, "settimo": 7, "ottavo": 8,
                        "nono": 9, "decimo": 10]
        var perAnno: [Int: Double] = [:]
        let schema = #"(?:(\d{1,2})\s*[°ºa]?\s*anno|anno\s*(\d{1,2})|(primo|secondo|terzo|quarto|quinto|sesto|settimo|ottavo|nono|decimo)\s+anno)[^%\n]{0,40}?"# + percento
        guard let regex = try? NSRegularExpression(pattern: schema, options: [.caseInsensitive]) else { return nil }
        let ns = tratto as NSString
        for m in regex.matches(in: tratto, range: NSRange(location: 0, length: ns.length)) {
            var anno: Int?
            for g in 1...3 where m.range(at: g).location != NSNotFound {
                let s = ns.substring(with: m.range(at: g)).lowercased()
                anno = Int(s) ?? ordinali[s]
            }
            guard let a = anno, a >= 1, a <= 15, perAnno[a] == nil,
                  let x = EstrattoreDocumento.numero(ns.substring(with: m.range(at: 4))) else { continue }
            perAnno[a] = x
        }
        let anni = perAnno.keys.filter { $0 >= 2 }.sorted()
        guard let ultimo = anni.last, anni.count >= 1 else { return nil }
        let penali = (2...ultimo).map { perAnno[$0] ?? 0 }
        return (penali, String(tratto.prefix(180)))
    }

    /// Il tipo di prodotto dalle parole di tutti i documenti.
    static func riconosci(_ testo: String) -> Riconoscimento? {
        let t = testo.lowercased()
        func c(_ parole: String...) -> Bool { parole.contains { t.contains($0) } }
        let gs = c("gestione separata", "gestione interna separata", "rivalutabile", "rivalutazione")
        let fondi = c("fondo interno", "fondi interni", "oicr", "unit linked", "unit-linked")
        if c("forma pensionistica", "previdenza complementare", "piano individuale pensionistico", "fondo pensione") {
            let pip = c("piano individuale pensionistico", "pip ")
            return Riconoscimento(area: .previdenza, tipologia: pip ? "Piano individuale pensionistico (PIP)" : "Fondo pensione",
                                  gestioneSeparata: gs)
        }
        if c("temporanea caso morte", "temporanea per il caso di morte", "tcm") && !c("scenari di performance") {
            return Riconoscimento(area: .protezione, tipologia: "Temporanea caso morte (TCM)", gestioneSeparata: false)
        }
        if c("long term care", "non autosufficienza", "infortuni", "malattia") && !c("scenari di performance") {
            return Riconoscimento(area: .protezione, tipologia: "Assicurazione di protezione", gestioneSeparata: false)
        }
        let ricorrente = c("premi ricorrenti", "premio annuo", "premi annui", "piano di accumulo", "premi periodici")
        let area: AreaPosizione = ricorrente ? .risparmio : .investimento
        if c("multiramo") || (gs && fondi) {
            return Riconoscimento(area: area, tipologia: "Polizza multiramo (Ramo I e III)", gestioneSeparata: true)
        }
        if gs { return Riconoscimento(area: area, tipologia: ricorrente ? "Polizza rivalutabile a premi ricorrenti (Ramo I)" : "Polizza rivalutabile (Ramo I)", gestioneSeparata: true) }
        if c("unit linked", "unit-linked") || (fondi && c("assicurazion", "polizza")) {
            return Riconoscimento(area: area, tipologia: "Unit linked (Ramo III)", gestioneSeparata: false)
        }
        if c("exchange traded", "etf") { return Riconoscimento(area: area, tipologia: "ETF", gestioneSeparata: false) }
        if c("fondo comune", "sicav", "oicvm", "comparto") { return Riconoscimento(area: area, tipologia: "Fondo comune (OICR)", gestioneSeparata: false) }
        return nil
    }

    // MARK: - Aiuti

    private struct Trovato { var gruppo: String; var riga: String }

    /// La prima occorrenza di uno schema (gruppo 1) e la riga intera in cui sta.
    private static func trova(_ schema: String, _ testo: String) -> Trovato? {
        guard let regex = try? NSRegularExpression(pattern: schema, options: [.caseInsensitive]) else { return nil }
        let ns = testo as NSString
        guard let m = regex.firstMatch(in: testo, range: NSRange(location: 0, length: ns.length)), m.numberOfRanges > 1,
              m.range(at: 1).location != NSNotFound else { return nil }
        let gruppo = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
        return Trovato(gruppo: gruppo, riga: ns.substring(with: m.range))
    }

    /// Le percentuali di un tratto di testo, nell'ordine («-27,7% -6,5%» → [-27.7, -6.5]).
    static func percentuali(_ s: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: percento) else { return [] }
        let ns = s as NSString
        return regex.matches(in: s, range: NSRange(location: 0, length: ns.length)).compactMap {
            EstrattoreDocumento.numero(ns.substring(with: $0.range(at: 1)))
        }
    }

    // MARK: - Dalla lettura alla scheda

    /// Mette nella scheda le sole voci scelte (confermate). Ciò che la scheda aveva e i documenti non dicono resta.
    /// - Costo annuo = gestione + transazione (+ performance in percentuale): i costi correnti del KID, ogni anno.
    /// - Rendimento atteso lordo: quello «prima dei costi» se il KID lo scrive, altrimenti ricavato dallo scenario
    ///   moderato con `MotoreConfrontoDossier.lordoImplicito` (lo scenario è netto: i costi non si contano due volte).
    /// - Le condizioni tengono i quattro scenari, il periodo, l'esempio, le penali, il blocco del riscatto e le aliquote.
    static func applica(_ l: Lettura, scelte: Set<Voce>, a p: inout Prodotto, oggi: Date = Date()) {
        func x(_ v: Voce) -> Double? { scelte.contains(v) ? l.dati[v]?.numero : nil }
        func t(_ v: Voce) -> String? {
            guard scelte.contains(v), let s = l.dati[v]?.testo.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
            return s
        }
        if let s = t(.nome) { p.nome = s }
        if let s = t(.emittente) { p.emittente = s }
        if let s = t(.tipologia) { p.tipologia = s } else if p.tipologia.isEmpty, let r = l.riconoscimento { p.tipologia = r.tipologia }
        if let v = x(.sri) { p.sri = min(7, max(1, Int(v))) }
        if let v = x(.periodoRaccomandato) { p.periodoRaccomandato = Int(v) }
        if let v = x(.costoIngresso) { p.costoIngresso = v } else if let v = x(.caricamento) { p.costoIngresso = v }
        let correnti = [Voce.costoGestione, .costiTransazione, .commissioniPerformance].compactMap(x)
        let correntiTotali = correnti.reduce(0, +)
        // Gestione separata: nei costi correnti del KID c'è già il trattenuto, che Prisma conta a parte
        // (`MotoreGestioneSeparata.trattenuto`): nel costo annuo resta il resto, così non si conta due volte
        let gestioneSeparata = l.riconoscimento?.gestioneSeparata == true
        let trattenuto = gestioneSeparata ? x(.trattenuto) : nil
        if !correnti.isEmpty {
            p.costoAnnuo = (max(0, correntiTotali - (trattenuto ?? 0)) * 100).rounded() / 100
        }
        if let v = x(.incidenzaPeriodo) { p.incidenzaCostiKID = v }
        if let v = trattenuto { p.trattenuto = v }
        if let v = x(.minimoGarantito) { p.minimoGarantito = v }
        // Fiscalità: la previdenza ha la sua (15% che scende al 9%), le altre il 26% con la parte in titoli di Stato al 12,5%
        if p.area == .previdenza {
            p.aliquotaFiscale = RegoleFiscali.previdenzaBase
        } else if let a = x(.aliquota), a == RegoleFiscali.ordinaria || a == RegoleFiscali.titoliStato {
            p.aliquotaFiscale = a
        } else if p.aliquotaFiscale == nil, p.area != .protezione {
            p.aliquotaFiscale = RegoleFiscali.ordinaria
        }
        if let q = x(.quotaTitoliStato), p.area != .previdenza {
            let base = RegoleFiscali.ordinaria
            p.aliquotaFiscale = ((base - q / 100 * (base - RegoleFiscali.titoliStato)) * 100).rounded() / 100
        }
        // Rendimento lordo
        let anni = x(.periodoRaccomandato).map { Int($0) } ?? p.periodoConsigliato
        if let lordo = x(.rendimentoPrimaCosti) {
            p.rendimentoAtteso = lordo
        } else if let mod = scelte.contains(.scenarioModerato) ? l.dati[.scenarioModerato]?.numeri.last : nil,
                  let a = anni, let lordo = MotoreConfrontoDossier.lordoImplicito(moderato: mod, ingresso: p.costoIngresso ?? 0,
                                                                              annuo: correnti.isEmpty ? (p.costoAnnuo ?? 0) : correntiTotali,
                                                                              anni: a) {
            p.rendimentoAtteso = (lordo * 100).rounded() / 100
        }
        // Le condizioni
        var c = p.condizioni ?? CondizioniContratto()
        if let v = x(.periodoRaccomandato) { c.periodoRaccomandato = Int(v); c.anniKID = Int(v) }
        let scenari: [(Voce, String)] = [(.scenarioStress, "Stress"), (.scenarioSfavorevole, "Sfavorevole"),
                                         (.scenarioModerato, "Moderato"), (.scenarioFavorevole, "Favorevole")]
        let letti = scenari.compactMap { v, nome -> ScenarioKID? in
            guard scelte.contains(v), let d = l.dati[v], !d.numeri.isEmpty else { return nil }
            return ScenarioKID(nome: nome, unAnno: d.numeri.count > 1 ? d.numeri.first : nil, periodo: d.numeri.last)
        }
        if !letti.isEmpty { c.scenariKID = letti }
        if scelte.contains(.esempioKID), let e = l.dati[.esempioKID] { c.esempioKID = e.testo }
        if let v = x(.costoIngresso) ?? x(.caricamento) { c.costoIngresso = v }
        if scelte.contains(.penali), let pen = l.dati[.penali]?.numeri, !pen.isEmpty { c.penali = pen }
        if let v = x(.bloccoRiscatto) { c.mesiBloccoRiscatto = Int(v) }
        if scelte.contains(.dataDocumento), let d = EstrattoreDocumento.data(l.dati[.dataDocumento]?.testo) { c.dataDocumenti = d }
        c.fonti = l.documenti.map { "\($0.tipo.nome): \($0.nome)" }.joined(separator: " · ")
        p.condizioni = c
        if p.periodoRaccomandato == nil { p.periodoRaccomandato = c.periodoRaccomandato }
        // Garanzie in parole, se la scheda non le ha
        if p.garanzie.isEmpty, let g = x(.minimoGarantito) {
            p.garanzie = g > 0 ? "Rendimento minimo garantito del \(Formati.percentuale(g)) l'anno." : "Capitale garantito."
        }
        p.fonte = l.documenti.map { "\($0.tipo.nome) «\($0.nome)»" }.joined(separator: ", ")
        p.verificatoIl = Calendar.current.startOfDay(for: oggi)
    }

    /// Una scheda nuova dai documenti: area e canale dal riconoscimento (canale scelto dal consulente).
    static func prodotto(da l: Lettura, scelte: Set<Voce>, canale: Canale, area: AreaPosizione? = nil, oggi: Date = Date()) -> Prodotto {
        let nome = scelte.contains(.nome) ? (l.dati[.nome]?.testo ?? "") : ""
        var p = Prodotto(nome: nome.isEmpty ? (l.documenti.first?.nome ?? "Prodotto") : nome, canale: canale,
                         area: area ?? l.riconoscimento?.area ?? .investimento)
        if canale == .alleanza, !scelte.contains(.emittente) { p.emittente = "Alleanza Assicurazioni" }
        applica(l, scelte: scelte, a: &p, oggi: oggi)
        return p
    }
}
