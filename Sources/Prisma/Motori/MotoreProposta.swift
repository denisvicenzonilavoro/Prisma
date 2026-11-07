import Foundation

// Pratiche › Proposta, «La proposta si costruisce da sola» (Design/template-luce-specifica.md §7.1, «Luce» giro 3).
// Motore puro: dai bisogni scoperti dalle analisi di Prisma (le proposte di `MotoreSintesi.calcolaProposte`, arricchite
// dai bisogni rilevati e confermati del profilo) costruisce le cinque tappe della proposta: il prodotto (solo dal
// catalogo dell'utente, canale sempre quello del prodotto), l'importo (solo dai motori esistenti: protezione della
// famiglia, previdenza, obiettivi, liquidità), il prospetto (CompositoreProspetti, contando le pagine senza fare il PDF),
// l'adeguatezza (MotoreAdeguatezza su una bozza in memoria: il rosso ferma tutto) e i moduli (arrivano con «Compila da
// solo», giro 10: tappa neutra, mai un elenco o un conteggio inventato). Nessun premio inventato: per le coperture
// «premio: da chiedere alla compagnia», finché il consulente non lo scrive nella posizione.

/// Un bisogno della barra laterale «Bisogni scoperti dall'analisi»: una proposta dei motori per un cliente.
struct BisognoScoperto: Identifiable, Hashable {
    /// `<clienteId>·<id della proposta>`: unico in tutto l'archivio.
    let id: String
    let clienteId: String
    /// L'identificativo della proposta di `MotoreSintesi.calcolaProposte` ("protezione-vita", "previdenza", …).
    let origine: String
    /// «La protezione di Marco», «La pensione integrativa di Giulia».
    let titolo: String
    /// La frase del motivo, con le cifre dei motori.
    let motivo: String
    let area: AreaPosizione
    let rischio: RischioCoperto?
    let capitale: Double?
    let versamentoMensile: Double?
    let importo: Double?
    /// Il collegamento per la scheda di adeguatezza: un obiettivo, un bisogno rilevato o l'area del profilo.
    let obiettivoId: String?
    let bisognoRilevatoId: String?
    let areaBisogno: AreaBisogno?
    /// Il bisogno rilevato è confermato dal consulente nel profilo dei bisogni.
    let confermato: Bool
    /// L'Analisi 360 del cliente non è salvata: le ipotesi sono quelle predefinite, il bisogno è «da confermare».
    let daConfermare: Bool
    /// La bozza aperta che risponde già a questo bisogno (stesso cliente, area e rischio), se c'è.
    let propostaId: String?
}

/// Dove porta «Rimedia» quando una tappa si ferma.
enum RimedioPasso: Hashable {
    case prodotti, analisi360, posizione
}

/// L'esito di una tappa della proposta.
enum EsitoPasso<Valore> {
    /// Fatta: il riquadro si accende.
    case fatto(Valore)
    /// Più prodotti adatti: la costruzione si ferma finché il consulente non sceglie (al più 4).
    case daScegliere([Prodotto])
    /// Manca un dato: riquadro arancio con la frase e «Rimedia»; le tappe dopo restano spente.
    case manca(String, rimedio: RimedioPasso)
    /// Non adeguata: riquadro rosso, niente moduli e niente «Proposta pronta».
    case bloccato(String)
    /// La tappa arriva con un prossimo aggiornamento: riquadro acceso in modo neutro, non blocca.
    case inArrivo(String)

    var valore: Valore? {
        if case .fatto(let v) = self { return v }
        return nil
    }

    /// true se la costruzione prosegue alla tappa dopo.
    var prosegue: Bool {
        switch self {
        case .fatto, .inArrivo: return true
        case .daScegliere, .manca, .bloccato: return false
        }
    }
}

/// L'importo della proposta: la cifra dei motori, la frase che la spiega e la riga del premio o dei costi.
struct ImportoProposta: Hashable {
    let cifra: Double
    /// «capitale per 10 anni di sostegno», «al mese, deducibili», «al mese per 8 anni».
    let spiegazione: String
    /// «premio: da chiedere alla compagnia», «fino a 5.300 € l'anno di deduzione», «costo medio 1,2% l'anno».
    let riga: String
}

/// Il prospetto della proposta: quante pagine fa (impaginato, senza generare il PDF).
struct ProspettoProposta: Hashable {
    let pagine: Int
}

/// L'esito dell'adeguatezza per il riquadro: colore, frase e dettaglio.
struct AdeguatezzaProposta: Hashable {
    /// nil = la scheda non serve (liquidità).
    let semaforo: Semaforo?
    let titolo: String
    let dettaglio: String
}

/// Le cinque tappe costruite per un bisogno, con la bozza pronta da salvare.
struct PropostaCostruita {
    let bisogno: BisognoScoperto
    let prodotto: EsitoPasso<Prodotto>
    let importo: EsitoPasso<ImportoProposta>?
    let prospetto: EsitoPasso<ProspettoProposta>?
    let adeguatezza: EsitoPasso<AdeguatezzaProposta>?
    let moduli: EsitoPasso<Void>?
    /// La bozza (Posizione proposta, esito bozza) con prodotto, canale del prodotto e importi dei motori: c'è quando
    /// prodotto e importo sono fatti.
    let bozza: Posizione?
    /// La scheda di adeguatezza collegata al bisogno.
    let scheda: SchedaAdeguatezza?

    /// Quante tappe si accendono (spente quelle dopo la prima che si ferma).
    var raggiunti: Int {
        var n = 1
        guard prodotto.prosegue else { return n }
        for p in [importo?.prosegue, prospetto?.prosegue, adeguatezza?.prosegue, moduli?.prosegue] {
            guard let p else { return n }
            n += 1
            if !p { return n }
        }
        return n
    }

    /// Tutte e cinque le tappe arrivate in fondo: «Proposta pronta».
    var pronta: Bool { raggiunti == 5 && (moduli?.prosegue ?? false) }
}

enum MotoreProposta {
    /// La frase della tappa 5 finché «Compila da solo» (giro 10) non c'è.
    static let moduliInArrivo = "I moduli si compileranno da soli con «Compila da solo», in arrivo."
    static let premioDaChiedere = "premio: da chiedere alla compagnia"
    static let riepilogoPronta = "prodotto, importo, prospetto e adeguatezza pronti. Controlla e firma."

    // MARK: - Bisogni

    /// I bisogni scoperti di un cliente. `fonte` porta le posizioni del cliente SENZA le bozze aperte (così il bisogno
    /// già costruito resta visibile), `bozze` le bozze aperte del cliente, per ritrovare quella che risponde al bisogno.
    /// Le proposte senza area (solo attività, come i capitali in scadenza) non sono bisogni di proposta.
    static func bisogni(fonte: FonteVera, bozze: [Posizione] = []) -> [BisognoScoperto] {
        let c = fonte.cliente
        let rilevati = MotoreBisogni.rileva(cliente: c, posizioni: fonte.posizioni, analisi: fonte.analisi, oggi: fonte.oggi)
        let confermati = Set(MotoreBisogni.confermati(rilevati, profilo: c.bisogni).map(\.id))
        let scartati = Set(rilevati.filter { c.bisogni.esiti[$0.id] == false }.map(\.id))
        let nome = primoNome(c.nome)
        var elenco: [BisognoScoperto] = []
        for p in MotoreSintesi.calcolaProposte(fonte) {
            guard let area = p.area else { continue }
            let obiettivoId = p.id.hasPrefix("obiettivo-") ? String(p.id.dropFirst("obiettivo-".count)) : nil
            let obiettivo = obiettivoId.flatMap { id in fonte.obiettivi.first { $0.id == id } }
            let candidati = rilevatiPer(p.id).filter { id in rilevati.contains { $0.id == id } }
            let bozza = bozze.first { b in
                b.stato == .proposta && b.esito == .bozza && b.area == area && (p.rischio == nil || b.rischio == p.rischio)
            }
            // Un bisogno scartato dal consulente nel profilo non torna fra quelli da proporre (se la proposta è già
            // costruita resta, perché la sua adeguatezza lo dica)
            if bozza == nil, !candidati.isEmpty, candidati.allSatisfy({ scartati.contains($0) }) { continue }
            let rilevato = candidati.first { confermati.contains($0) } ?? candidati.first
            var motivo = maiuscola(p.perche)
            if !fonte.analisiSalvata { motivo = "Da confermare: " + p.perche }
            elenco.append(BisognoScoperto(
                id: "\(c.id)·\(p.id)", clienteId: c.id, origine: p.id,
                titolo: titolo(p, area: area, nome: nome, obiettivo: obiettivo?.titolo), motivo: motivo,
                area: area, rischio: p.rischio, capitale: p.capitale, versamentoMensile: p.versamentoMensile,
                importo: p.importo, obiettivoId: obiettivo?.id,
                bisognoRilevatoId: obiettivo == nil ? rilevato : nil,
                areaBisogno: areaBisogno(area, rischio: p.rischio),
                confermato: rilevato.map { confermati.contains($0) } ?? false,
                daConfermare: !fonte.analisiSalvata, propostaId: bozza?.id))
        }
        // I bisogni confermati dal consulente vengono prima (a parità, l'ordine di urgenza dei motori)
        return elenco.enumerated().sorted { a, b in
            a.element.confermato != b.element.confermato ? a.element.confermato : a.offset < b.offset
        }.map(\.element)
    }

    /// Gli identificativi dei bisogni rilevati (MotoreBisogni) a cui risponde una proposta dei motori.
    static func rilevatiPer(_ origine: String) -> [String] {
        switch origine {
        case "protezione-vita": return ["protezione-famiglia", "tutela-mutuo"]
        case "protezione-invalidita": return ["rischi-persona"]
        case "liquidita-riserva": return ["riserva-imprevisti"]
        case "previdenza": return ["previdenza-assente", "previdenza-divario"]
        case "liquidita-destinare": return ["liquidita-ferma"]
        default: return []
        }
    }

    /// L'area del profilo dei bisogni quando nessun bisogno rilevato corrisponde.
    static func areaBisogno(_ a: AreaPosizione, rischio: RischioCoperto?) -> AreaBisogno? {
        switch a {
        case .protezione: return rischio == .vita ? .famiglia : .salute
        case .previdenza: return .pensione
        case .liquidita: return .salute
        case .investimento, .risparmio: return .patrimonio
        default: return nil
        }
    }

    /// Il titolo della voce, nel tono del template: i dati restano dei motori, la frase nasce da area e nome.
    static func titolo(_ p: PropostaVera, area: AreaPosizione, nome: String, obiettivo: String?) -> String {
        if let obiettivo { return "Il piano per «\(obiettivo)» di \(nome)" }
        switch p.id {
        case "protezione-vita": return "La protezione di \(nome)"
        case "protezione-invalidita": return "Il reddito di \(nome), se si ferma"
        case "liquidita-riserva": return "La riserva di \(nome)"
        case "previdenza": return "La pensione integrativa di \(nome)"
        case "liquidita-destinare": return "Il capitale di \(nome) oltre la riserva"
        default: return "\(area.nome) per \(nome)"
        }
    }

    static func primoNome(_ nome: String) -> String {
        nome.split(separator: " ").first.map(String.init) ?? nome
    }

    private static func maiuscola(_ s: String) -> String {
        guard let prima = s.first else { return s }
        return prima.uppercased() + s.dropFirst()
    }

    // MARK: - Prodotti adatti

    /// Il rischio che il prodotto nomina nel nome o nella tipologia (nil se non ne nomina nessuno): nessun campo nuovo
    /// nel catalogo, la regola legge le parole.
    static func rischioNominato(_ p: Prodotto) -> RischioCoperto? {
        let t = (p.nome + " " + p.tipologia).lowercased()
        if t.contains("caso morte") || t.contains("decesso") || t.contains("tcm") || t.contains("temporanea") { return .vita }
        if t.contains("infortun") { return .infortuni }
        if t.contains("ltc") || t.contains("non autosufficien") { return .ltc }
        if t.contains("invalidit") { return .invalidita }
        if t.contains("malattia") || t.contains("salute") { return .salute }
        if t.contains("casa") || t.contains("danni") { return .casa }
        if t.contains("responsabilit") { return .rc }
        return nil
    }

    /// I prodotti del catalogo adatti al bisogno: stessa area; per la protezione, stesso rischio se il prodotto ne
    /// nomina uno; solo i canali con cui il cliente è seguito (tutti se non ne ha). Mai un prodotto fuori catalogo.
    /// `ultimo` mette in testa il prodotto usato l'ultima volta.
    static func prodottiAdatti(_ b: BisognoScoperto, catalogo: [Prodotto], canaliCliente: [Canale],
                               ultimo: String? = nil) -> [Prodotto] {
        let adatti = catalogo.filter { p in
            guard p.area == b.area else { return false }
            if b.area == .protezione, let r = b.rischio, let rp = rischioNominato(p), rp != r { return false }
            return canaliCliente.isEmpty || canaliCliente.contains(p.canale)
        }
        guard let ultimo, let i = adatti.firstIndex(where: { $0.id == ultimo }) else { return adatti }
        var ordinati = adatti
        ordinati.insert(ordinati.remove(at: i), at: 0)
        return ordinati
    }

    /// «di protezione caso morte», «di previdenza»: per la frase del catalogo vuoto.
    static func descrizione(_ b: BisognoScoperto) -> String {
        if b.area == .protezione, let r = b.rischio { return "di protezione \(r.nome.lowercased())" }
        return "di \(b.area.nome.lowercased())"
    }

    /// Un prodotto del catalogo d'esempio di Prisma (si vede l'etichetta «dati di prova»).
    static func diProva(_ p: Prodotto) -> Bool {
        p.fonte.hasPrefix("Esempio didattico") || p.note.localizedCaseInsensitiveContains("dati di prova")
    }

    // MARK: - Costruzione

    /// Costruisce le cinque tappe. `fonte` come per `bisogni` (posizioni senza le bozze aperte); `bozzaEsistente` è la
    /// bozza già collegata al bisogno (si aggiorna, con il suo premio scritto a mano); `prodottoScelto` la scelta del
    /// consulente fra più prodotti adatti. `contaPagine` impagina il prospetto (le prove possono passarne una finta).
    static func costruisci(_ b: BisognoScoperto, fonte: FonteVera, dati: DatiPrisma, bozzaEsistente: Posizione? = nil,
                           prodottoScelto: String? = nil, ultimo: String? = nil,
                           contaPagine: (ContenutoProspetto) -> Int) -> PropostaCostruita {
        let adatti = prodottiAdatti(b, catalogo: fonte.prodotti, canaliCliente: fonte.cliente.canali, ultimo: ultimo)
        func ferma(_ prodotto: EsitoPasso<Prodotto>) -> PropostaCostruita {
            PropostaCostruita(bisogno: b, prodotto: prodotto, importo: nil, prospetto: nil, adeguatezza: nil, moduli: nil,
                              bozza: nil, scheda: nil)
        }
        // 1. Il prodotto
        let scelto: Prodotto
        if let id = bozzaEsistente?.prodottoId, let p = fonte.prodotti.first(where: { $0.id == id }) {
            scelto = p
        } else if let id = prodottoScelto, let p = adatti.first(where: { $0.id == id }) {
            scelto = p
        } else if adatti.count == 1 {
            scelto = adatti[0]
        } else if adatti.isEmpty {
            return ferma(.manca("Nessun prodotto \(descrizione(b)) nel catalogo.", rimedio: .prodotti))
        } else {
            return ferma(.daScegliere(Array(adatti.prefix(Tema.Apple.Pratiche.Proposta.maxProdottiScelta))))
        }

        // 2. L'importo, dai motori
        var bozza = bozzaEsistente ?? Posizione(clienteId: b.clienteId, canale: scelto.canale, stato: .proposta,
                                                area: b.area, nome: scelto.nome)
        bozza.stato = .proposta
        bozza.esito = .bozza
        bozza.canale = scelto.canale
        bozza.area = scelto.area
        bozza.nome = scelto.nome
        bozza.rischio = b.area == .protezione ? (b.rischio ?? rischioNominato(scelto)) : nil
        ImportaPosizioni.applica(scelto, a: &bozza)
        if bozza.emittente.isEmpty && scelto.canale == .alleanza { bozza.emittente = "Alleanza Assicurazioni" }
        bozza.periodoRaccomandato = bozza.periodoRaccomandato ?? scelto.periodoConsigliato
        guard let importo = importo(b, prodotto: scelto, fonte: fonte, bozza: &bozza) else {
            return PropostaCostruita(bisogno: b, prodotto: .fatto(scelto),
                                     importo: .manca("L'analisi non dà ancora una cifra per questo bisogno.", rimedio: .analisi360),
                                     prospetto: nil, adeguatezza: nil, moduli: nil, bozza: nil, scheda: nil)
        }
        if bozza.note.isEmpty {
            bozza.note = "Costruita in Pratiche › Proposta dal bisogno «\(b.titolo)»: \(b.motivo)"
        }
        var scheda = SchedaAdeguatezza(posizioneId: bozza.id, clienteId: b.clienteId, creataIl: fonte.oggi)
        if let o = b.obiettivoId {
            scheda.collegamento = .obiettivo(o)
        } else if let r = b.bisognoRilevatoId {
            scheda.collegamento = .rilevato(r)
        } else if let a = b.areaBisogno {
            scheda.collegamento = .area(a)
        }

        // 3. Il prospetto
        let pagine = contaPagine(CompositoreProspetti.posizione(bozza, dati: dati))
        let prospetto: EsitoPasso<ProspettoProposta> = pagine > 0
            ? .fatto(ProspettoProposta(pagine: pagine))
            : .manca("Il prospetto non si è potuto impaginare.", rimedio: .posizione)

        // 4. L'adeguatezza, su una bozza in memoria
        let adeguatezza: EsitoPasso<AdeguatezzaProposta>? = prospetto.prosegue
            ? self.adeguatezza(bozza, scheda: scheda, fonte: fonte, voci: dati.impostazioni.consegna.voci) : nil

        // 5. I moduli: arrivano con «Compila da solo» (giro 10)
        let moduli: EsitoPasso<Void>? = (adeguatezza?.prosegue ?? false) ? .inArrivo(moduliInArrivo) : nil

        return PropostaCostruita(bisogno: b, prodotto: .fatto(scelto), importo: .fatto(importo), prospetto: prospetto,
                                 adeguatezza: adeguatezza, moduli: moduli, bozza: bozza, scheda: scheda)
    }

    /// La cifra, la frase e la riga del premio, dai motori; scrive gli importi nella bozza. nil se i motori non danno
    /// una cifra (mai un numero inventato).
    static func importo(_ b: BisognoScoperto, prodotto: Prodotto, fonte: FonteVera,
                        bozza: inout Posizione) -> ImportoProposta? {
        let f = fonte
        switch b.area {
        case .protezione:
            let prot = MotoreProtezioneFamiglia.calcola(f.posizioni, cliente: f.cliente, analisi: f.analisi.protezione, data: f.oggi)
            let premio = bozza.premio > 0
                ? "premio: \(CifreDoc.euro(bozza.premio)) \(bozza.frequenza.nome.lowercased())"
                : premioDaChiedere
            if b.rischio == .vita {
                guard let capitale = b.capitale, capitale > 0 else { return nil }
                let anni = prot.ipotesi.anniSostegno
                bozza.capitaleAssicurato = capitale
                if bozza.decorrenza == nil { bozza.decorrenza = f.oggi }
                if bozza.scadenza == nil { bozza.scadenza = Calendar.current.date(byAdding: .year, value: anni, to: f.oggi) }
                return ImportoProposta(cifra: capitale, spiegazione: "capitale per \(anni) \(anni == 1 ? "anno" : "anni") di sostegno",
                                       riga: premio)
            }
            let capitale = prot.riservaMancante
            guard capitale > 0 else { return nil }
            bozza.capitaleAssicurato = capitale
            let mesi = prot.ipotesi.mesiRiserva
            return ImportoProposta(cifra: capitale, spiegazione: "per \(mesi) mesi di stop al lavoro", riga: premio)
        case .previdenza:
            guard let mensile = b.versamentoMensile, mensile > 0 else { return nil }
            bozza.premio = mensile
            bozza.frequenza = .mensile
            let prev = MotorePrevidenza.calcola(f.posizioni, cliente: f.cliente, analisi: f.analisi.previdenza, data: f.oggi)
            return ImportoProposta(cifra: mensile, spiegazione: "al mese, deducibili",
                                   riga: "fino a \(CifreDoc.euro(prev.limiteClienteConProposte)) l'anno di deduzione")
        case .risparmio:
            guard let mensile = b.versamentoMensile, mensile > 0 else { return nil }
            bozza.premio = mensile
            bozza.frequenza = .mensile
            var spiegazione = "al mese"
            if let id = b.obiettivoId, let o = f.obiettivi.first(where: { $0.id == id }) {
                let e = MotoreObiettivo.calcola(o, posizioni: f.posizioni, data: f.oggi)
                let anni = max(1, Int((e.anni).rounded()))
                spiegazione = "al mese per \(anni) \(anni == 1 ? "anno" : "anni")"
                if bozza.scadenza == nil { bozza.scadenza = o.scadenza }
            }
            return ImportoProposta(cifra: mensile, spiegazione: spiegazione, riga: rigaCosti(prodotto))
        case .investimento:
            guard let i = b.importo, i > 0 else { return nil }
            bozza.versamentoIniziale = i
            return ImportoProposta(cifra: i, spiegazione: "da investire, oltre la riserva", riga: rigaCosti(prodotto))
        case .liquidita:
            guard let mensile = b.versamentoMensile, mensile > 0 else { return nil }
            bozza.premio = mensile
            bozza.frequenza = .mensile
            return ImportoProposta(cifra: mensile, spiegazione: "al mese per un anno", riga: rigaCosti(prodotto))
        default:
            return nil
        }
    }

    /// «costo medio 1,2% l'anno» dalla scheda prodotto (l'incidenza del KID prima); se la scheda non lo dice, lo dice.
    static func rigaCosti(_ p: Prodotto) -> String {
        guard let c = p.incidenzaCostiKID ?? p.costoAnnuo else { return "costi: non indicati nella scheda prodotto" }
        return "costo medio \(CifreDoc.percento(c)) l'anno"
    }

    /// L'adeguatezza della bozza: verde «Adeguata», giallo «Da motivare» (fatta, con il controllo da motivare), rosso
    /// bloccata, grigio ferma con «Rimedia». La liquidità non ha scheda.
    static func adeguatezza(_ bozza: Posizione, scheda: SchedaAdeguatezza, fonte f: FonteVera,
                            voci: [VoceDocumento]) -> EsitoPasso<AdeguatezzaProposta> {
        guard MotoreAdeguatezza.pertinente(bozza, scheda: scheda) else {
            return .fatto(AdeguatezzaProposta(semaforo: nil, titolo: "Non richiesta",
                                              dettaglio: "per la liquidità non serve la scheda di adeguatezza"))
        }
        let bisogni = MotoreBisogni.rileva(cliente: f.cliente, posizioni: f.posizioni, analisi: f.analisi, oggi: f.oggi)
        let ingresso = IngressoAdeguatezza(
            proposta: bozza, cliente: f.cliente, posizioni: f.posizioni.filter { $0.id != bozza.id } + [bozza],
            prodotti: f.prodotti, obiettivi: f.obiettivi, bisogni: bisogni, protezione: f.analisi.protezione,
            ipotesiConfermate: f.analisiSalvata && f.analisi.confermate.contains(.protezione),
            scheda: scheda, voci: voci, oggi: f.oggi)
        let esito = MotoreAdeguatezza.calcola(ingresso)
        func primo(_ s: Semaforo) -> ControlloAdeguatezza? { esito.controlli.first { $0.semaforo == s } }
        switch esito.complessivo {
        case .verde:
            return .fatto(AdeguatezzaProposta(semaforo: .verde, titolo: "Adeguata",
                                              dettaglio: "coerente con profilo, obiettivo e orizzonte"))
        case .giallo:
            return .fatto(AdeguatezzaProposta(semaforo: .giallo, titolo: "Da motivare",
                                              dettaglio: primo(.giallo).map { minuscola($0.esito) } ?? "un controllo da motivare"))
        case .rosso:
            return .bloccato("Non adeguata: " + (primo(.rosso).map { minuscola($0.esito) } ?? "un controllo è rosso"))
        case .grigio:
            if !f.analisiSalvata {
                return .manca("Conferma le ipotesi dell'Analisi 360.", rimedio: .analisi360)
            }
            return .manca("Da completare: " + (primo(.grigio).map { minuscola($0.esito) } ?? "mancano dati per l'adeguatezza"),
                          rimedio: .posizione)
        }
    }

    private static func minuscola(_ s: String) -> String {
        guard let prima = s.first else { return s }
        // Le sigle (SRI, KID) restano maiuscole
        let secondaMaiuscola = s.dropFirst().first.map { $0.isUppercase } ?? false
        return secondaMaiuscola ? s : prima.lowercased() + s.dropFirst()
    }
}
