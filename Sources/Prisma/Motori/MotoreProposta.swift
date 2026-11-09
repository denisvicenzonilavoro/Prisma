import Foundation

// Pratiche › Proposta, «La proposta si costruisce da sola» (Design/template-luce-specifica.md §7.1, «Luce» giro 3).
// Motore puro: dai bisogni scoperti dalle analisi di Prisma (le proposte di `MotoreSintesi.calcolaProposte`, arricchite
// dai bisogni rilevati e confermati del profilo) costruisce le cinque tappe della proposta: il prodotto (solo dal
// catalogo dell'utente, canale sempre quello del prodotto), l'importo (solo dai motori esistenti: protezione della
// famiglia, previdenza, obiettivi, liquidità), il prospetto (CompositoreProspetti, contando le pagine senza fare il PDF),
// l'adeguatezza (MotoreAdeguatezza su una bozza in memoria: il rosso ferma tutto) e i moduli («Compila da solo»:
// `CompilatoreModuli.anteprima` sui modelli del canale e del prodotto, con «N campi compilati · M da chiedere»; senza
// modelli, o per i moduli Alleanza che Prisma non compila, la tappa resta neutra e non ferma la proposta). Nessun premio
// inventato: per le coperture «premio: da chiedere alla compagnia», finché il consulente non lo scrive nella posizione.
// Oltre ai bisogni delle analisi: la sostituzione «costi più bassi» (una posizione in essere con un prodotto del catalogo
// meno costoso, `MotoreCosti.alternativa` e `MotoreSostituzione`; o quella chiesta dallo Smontaggio) e i bisogni
// dell'azienda del cliente imprenditore (persona chiave con il capitale che manca da `MotoreAzienda`; welfare per i
// dipendenti solo su richiesta dal dossier, senza cifra: l'importo lo scrive il consulente).

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
    var propostaId: String?
    /// La sostituzione «costi più bassi»: la posizione in essere da sostituire (nil per gli altri bisogni o per un
    /// documento dello Smontaggio mai registrato, che porta la sua posizione provvisoria in `attualeProvvisoria`).
    var posizioneSostituitaId: String? = nil
    /// La posizione provvisoria dello Smontaggio (in memoria, mai salvata): l'estratto di un'altra banca.
    var attualeProvvisoria: Posizione? = nil
    /// Il prodotto già scelto (l'alternativa dei costi, la proposta scelta nello Smontaggio).
    var prodottoSuggerito: String? = nil
    /// L'azienda del cliente imprenditore da cui nasce il bisogno (persona chiave, welfare).
    var aziendaId: String? = nil

    /// Il bisogno di sostituzione «costi più bassi».
    var sostituzione: Bool { origine.hasPrefix(MotoreProposta.prefissoSostituzione) }
    /// L'area dell'azienda da cui nasce il bisogno (nil per gli altri).
    var areaAzienda: AreaAzienda? {
        if origine.hasPrefix(MotoreProposta.prefissoPersonaChiave) { return .personaChiave }
        if origine.hasPrefix(MotoreProposta.prefissoWelfare) { return .welfare }
        return nil
    }
}

/// Un modulo della proposta: quante caselle Prisma compila e quante restano da chiedere al cliente.
struct ModuloProposta: Hashable, Identifiable {
    let modelloId: String
    let titolo: String
    let compilati: Int
    let daChiedere: Int
    let firme: Int
    var id: String { modelloId }

    /// «18 campi compilati · 1 da chiedere».
    var riga: String {
        let c = "\(compilati) \(compilati == 1 ? "campo compilato" : "campi compilati")"
        return daChiedere > 0 ? "\(c) · \(daChiedere) da chiedere" : c
    }
}

/// Dove porta «Rimedia» quando una tappa si ferma.
enum RimedioPasso: Hashable {
    case prodotti, analisi360, posizione
    /// I dati dell'azienda nel dossier (fatturato, mesi a rischio).
    case azienda
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
    /// La sostituzione: la posizione in essere che la proposta sostituisce (il prospetto è quello di sostituzione).
    var attualeId: String? = nil
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
    let moduli: EsitoPasso<[ModuloProposta]>?
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
    /// La tappa 5 senza modelli caricati per il canale o il prodotto: neutra, non ferma la proposta.
    static let moduliSenzaModelli = "Nessun modulo per questo canale: caricali in Pratiche › Moduli e si compileranno da soli."
    /// I moduli Alleanza non si compilano in Prisma (decisione 60): si fanno con gli strumenti della compagnia.
    static let moduliAlleanza = "I moduli Alleanza si compilano con gli strumenti della compagnia."
    static let premioDaChiedere = "premio: da chiedere alla compagnia"
    static let riepilogoPronta = "prodotto, importo, prospetto e adeguatezza pronti. Controlla e firma."
    static let prefissoSostituzione = "sostituzione-"
    static let prefissoPersonaChiave = "azienda-persona-chiave-"
    static let prefissoWelfare = "azienda-welfare-"

    /// La frase del riquadro finale: con i moduli compilati, quanti.
    static func riepilogo(_ r: PropostaCostruita) -> String {
        guard case .fatto(let elenco)? = r.moduli, !elenco.isEmpty else { return riepilogoPronta }
        let n = elenco.count
        return "prodotto, importo, prospetto, adeguatezza e \(n) \(n == 1 ? "modulo compilato" : "moduli compilati"). Controlla e firma."
    }

    // MARK: - Bisogni

    /// I bisogni scoperti di un cliente. `fonte` porta le posizioni del cliente SENZA le bozze aperte (così il bisogno
    /// già costruito resta visibile), `bozze` le bozze aperte del cliente, per ritrovare quella che risponde al bisogno.
    /// Le proposte senza area (solo attività, come i capitali in scadenza) non sono bisogni di proposta.
    /// `schede`: le schede di adeguatezza delle bozze, per ritrovare la bozza di una sostituzione.
    static func bisogni(fonte: FonteVera, bozze: [Posizione] = [], schede: [SchedaAdeguatezza] = []) -> [BisognoScoperto] {
        let c = fonte.cliente
        // Le bozze di una sostituzione o di un bisogno dell'azienda non rispondono ai bisogni delle analisi
        let sostituzioni = Set(schede.filter { $0.posizioneSostituitaId != nil }.map(\.posizioneId))
        let bozzeAnalisi = bozze.filter { b in !sostituzioni.contains(b.id) && !b.note.contains(notaAzienda) }
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
            let bozza = bozzeAnalisi.first { b in
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
        elenco += bisogniSostituzione(fonte: fonte, bozze: bozze, schede: schede)
        elenco += bisogniAzienda(fonte: fonte, bozze: bozze)
        // I bisogni confermati dal consulente vengono prima (a parità, l'ordine di urgenza dei motori)
        return elenco.enumerated().sorted { a, b in
            a.element.confermato != b.element.confermato ? a.element.confermato : a.offset < b.offset
        }.map(\.element)
    }

    // MARK: - Sostituzione «costi più bassi»

    /// Le posizioni in essere (investimento e risparmio) per cui il catalogo ha un prodotto dello stesso rischio con costi
    /// più bassi che lascia di più, uscita compresa (`MotoreCosti.alternativa`, solo nei canali del cliente). Salta le
    /// aree con una proposta già presentata, come i bisogni delle analisi.
    static func bisogniSostituzione(fonte f: FonteVera, bozze: [Posizione], schede: [SchedaAdeguatezza]) -> [BisognoScoperto] {
        let c = f.cliente
        let catalogo = f.prodotti.filter { c.canali.isEmpty || c.canali.contains($0.canale) }
        let aperte = Set(f.posizioni.filter { $0.stato == .proposta && $0.esito != .rifiutata && $0.esito != .accettata }.map(\.area))
        var elenco: [BisognoScoperto] = []
        for p in f.posizioni where p.stato == .inEssere && (p.area == .investimento || p.area == .risparmio) {
            let bozza = bozze.first { b in schede.contains { $0.posizioneId == b.id && $0.posizioneSostituitaId == p.id } }
            if bozza == nil && aperte.contains(p.area) { continue }
            let alternativa = MotoreCosti.alternativa(p, prodotti: catalogo, cliente: c.id)
            guard bozza != nil || alternativa != nil else { continue }
            var motivo = "Una proposta di sostituzione è già in bozza."
            if let a = alternativa {
                let da = p.costoComplessivo.map { CifreDoc.percento($0) } ?? "—"
                motivo = "Costi dal \(da) al \(CifreDoc.percento(a.costoAnnuo)) l'anno con «\(a.prodotto.nome)»: in \(a.anni) anni "
                    + "circa \(CifreDoc.euro(a.guadagno)) in più, uscita compresa."
            }
            elenco.append(bisognoSostituzione(attuale: p, cliente: c, motivo: motivo,
                                              prodotto: bozza?.prodottoId ?? alternativa?.prodotto.id,
                                              propostaId: bozza?.id, daConfermare: !f.analisiSalvata))
        }
        return elenco
    }

    /// Il bisogno di sostituzione di una posizione (in essere o provvisoria dello Smontaggio), con il prodotto scelto.
    static func bisognoSostituzione(attuale p: Posizione, cliente c: Cliente, motivo: String, prodotto: String?,
                                    propostaId: String? = nil, provvisoria: Bool = false, daConfermare: Bool = false) -> BisognoScoperto {
        var b = BisognoScoperto(
            id: "\(c.id)·\(prefissoSostituzione)\(p.id)", clienteId: c.id, origine: prefissoSostituzione + p.id,
            titolo: "«\(p.nome)» di \(primoNome(c.nome)), con costi più bassi", motivo: motivo, area: p.area, rischio: nil,
            capitale: p.valore > 0 ? p.valore : nil, versamentoMensile: nil, importo: p.valore > 0 ? p.valore : nil,
            obiettivoId: nil, bisognoRilevatoId: nil, areaBisogno: areaBisogno(p.area, rischio: nil), confermato: false,
            daConfermare: daConfermare, propostaId: propostaId)
        b.posizioneSostituitaId = provvisoria ? nil : p.id
        b.attualeProvvisoria = provvisoria ? p : nil
        b.prodottoSuggerito = prodotto
        return b
    }

    // MARK: - L'azienda del cliente imprenditore

    /// Il segno nella nota della bozza nata da un bisogno dell'azienda (la bozza si ritrova anche dopo la riapertura).
    static let notaAzienda = "· azienda del cliente ·"

    /// La persona chiave delle aziende del cliente quando il fabbisogno (fatturato × mesi a rischio scritti dall'utente)
    /// supera il capitale delle coperture collegate. Il welfare non ha cifre: nasce solo dal dossier.
    static func bisogniAzienda(fonte f: FonteVera, bozze: [Posizione]) -> [BisognoScoperto] {
        (f.cliente.aziende ?? []).compactMap { a in
            guard let b = bisognoAzienda(a, area: .personaChiave, fonte: f, bozze: bozze),
                  b.capitale != nil || b.propostaId != nil else { return nil }
            return b
        }
    }

    /// Il bisogno di un'area dell'azienda (persona chiave o welfare); nil se l'area è segnata «non pertinente» o non è
    /// un bisogno di proposta. Per la persona chiave il capitale è quello che manca al fabbisogno (nil se non manca nulla
    /// o se mancano fatturato e mesi a rischio).
    static func bisognoAzienda(_ a: AziendaCliente, area: AreaAzienda, fonte f: FonteVera, bozze: [Posizione] = []) -> BisognoScoperto? {
        let c = f.cliente
        guard (c.datiNonPertinenti ?? [:])[MotoreAzienda.chiaveNonPertinente(azienda: a.id, area: area)] == nil else { return nil }
        let titolo: String
        let motivo: String
        var capitale: Double?
        let areaPosizione: AreaPosizione
        let rischio: RischioCoperto?
        let prefisso: String
        switch area {
        case .personaChiave:
            prefisso = prefissoPersonaChiave
            areaPosizione = .protezione
            rischio = .vita
            titolo = "La persona chiave di \(a.ragioneSociale)"
            let mesi = a.personaChiave?.mesiARischio
            let fabbisogno = MotoreAzienda.fabbisognoPersonaChiave(fatturato: a.fatturato, mesi: mesi)
            let coperto = MotoreAzienda.capitalePersonaChiave(a, posizioni: f.posizioni)
            if let fabbisogno, let mesi {
                let manca = fabbisogno - coperto
                capitale = manca > 0 ? manca : nil
                motivo = "Con \(TestiAzienda.mesi(mesi)) \(mesi == 1 ? "mese" : "mesi") di fatturato a rischio servono \(CifreDoc.euro(fabbisogno)); "
                    + (coperto > 0 ? "le coperture key man ne coprono \(CifreDoc.euro(coperto))." : "nessuna copertura key man.")
            } else {
                motivo = fraseServonoDatiAzienda
            }
        case .welfare:
            prefisso = prefissoWelfare
            areaPosizione = .previdenza
            rischio = nil
            titolo = "Il welfare per i dipendenti di \(a.ragioneSociale)"
            let v = MotoreAzienda.valuta(a, cliente: c, posizioni: f.posizioni, oggi: f.oggi).first { $0.area == .welfare }
            motivo = v?.frase ?? "Il piano di welfare per i dipendenti: l'importo lo decidi con l'azienda."
        case .tfm, .passaggio:
            return nil
        }
        let bozza = bozze.first { $0.note.contains("«\(titolo)»") }
        var b = BisognoScoperto(
            id: "\(c.id)·\(prefisso)\(a.id)", clienteId: c.id, origine: prefisso + a.id, titolo: titolo, motivo: motivo,
            area: areaPosizione, rischio: rischio, capitale: capitale, versamentoMensile: nil, importo: nil, obiettivoId: nil,
            bisognoRilevatoId: nil, areaBisogno: areaBisogno(areaPosizione, rischio: rischio), confermato: false,
            daConfermare: false, propostaId: bozza?.id)
        b.aziendaId = a.id
        return b
    }

    static let fraseServonoDatiAzienda = "Servono il fatturato e i mesi a rischio dell'azienda per la cifra."

    /// I prodotti del catalogo per un bisogno dell'azienda (decisione 74): per la persona chiave prima quelli che dicono
    /// «key man» o «persona chiave», poi le temporanee caso morte; per il welfare solo quelli che dicono welfare o
    /// previdenza collettiva. Sempre nei canali del cliente, mai fuori catalogo.
    static func prodottiAzienda(area: AreaAzienda, catalogo: [Prodotto], canaliCliente: [Canale]) -> [Prodotto] {
        func nomina(_ p: Prodotto, _ parole: [String]) -> Bool {
            let t = (p.nome + " " + p.tipologia).lowercased()
            return parole.contains { t.contains($0) }
        }
        let nei = catalogo.filter { canaliCliente.isEmpty || canaliCliente.contains($0.canale) }
        switch area {
        case .personaChiave:
            let parole = ["key man", "keyman", "key-man", "persona chiave", "uomo chiave"]
            let nominati = nei.filter { nomina($0, parole) }
            let temporanee = nei.filter { $0.area == .protezione && rischioNominato($0) == .vita && !nomina($0, parole) }
            return nominati + temporanee
        case .welfare:
            return nei.filter { nomina($0, ["welfare", "collettiv", "aziendal", "dipendenti"]) }
        case .tfm, .passaggio:
            return []
        }
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
        switch b.areaAzienda {
        case .personaChiave?: return "key man (persona chiave)"
        case .welfare?: return "per il welfare aziendale"
        default: break
        }
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
    /// `modelli`: i modelli di Pratiche › Moduli (per la tappa 5). `contaSostituzione` impagina il prospetto di
    /// sostituzione (nil: si conta quello della posizione).
    static func costruisci(_ b: BisognoScoperto, fonte: FonteVera, dati: DatiPrisma, bozzaEsistente: Posizione? = nil,
                           prodottoScelto: String? = nil, ultimo: String? = nil, modelli: [ModelloModulo] = [],
                           contaPagine: (ContenutoProspetto) -> Int,
                           contaSostituzione: ((EsitoSostituzione, Cliente) -> Int)? = nil) -> PropostaCostruita {
        let adatti: [Prodotto] = {
            if let area = b.areaAzienda {
                return prodottiAzienda(area: area, catalogo: fonte.prodotti, canaliCliente: fonte.cliente.canali)
            }
            var elenco = prodottiAdatti(b, catalogo: fonte.prodotti, canaliCliente: fonte.cliente.canali, ultimo: ultimo)
            // La sostituzione non propone il prodotto che il cliente ha già
            if b.sostituzione, let attuale = attuale(b, fonte: fonte) {
                elenco.removeAll { $0.id == attuale.prodottoId || $0.nome == attuale.nome }
            }
            return elenco
        }()
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
        } else if let id = b.prodottoSuggerito, let p = fonte.prodotti.first(where: { $0.id == id }) {
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
        if bozza.note.isEmpty {
            bozza.note = "Costruita in Pratiche › Proposta dal bisogno «\(b.titolo)»: \(b.motivo)"
                + (b.aziendaId != nil ? " \(notaAzienda)" : "")
        }
        var scheda = SchedaAdeguatezza(posizioneId: bozza.id, clienteId: b.clienteId, creataIl: fonte.oggi)
        if let o = b.obiettivoId {
            scheda.collegamento = .obiettivo(o)
        } else if let r = b.bisognoRilevatoId {
            scheda.collegamento = .rilevato(r)
        } else if let a = b.areaBisogno {
            scheda.collegamento = .area(a)
        }
        scheda.posizioneSostituitaId = b.posizioneSostituitaId
        guard let importo = importo(b, prodotto: scelto, fonte: fonte, bozza: &bozza) else {
            // Il welfare non ha una cifra dei motori: la bozza si salva perché il consulente scriva l'importo
            if b.areaAzienda == .welfare {
                return PropostaCostruita(bisogno: b, prodotto: .fatto(scelto),
                                         importo: .manca(fraseImportoWelfare, rimedio: .posizione),
                                         prospetto: nil, adeguatezza: nil, moduli: nil, bozza: bozza, scheda: scheda)
            }
            let frase: String
            let rimedio: RimedioPasso
            switch b.areaAzienda {
            case .personaChiave?:
                frase = b.motivo == fraseServonoDatiAzienda ? "Servono il fatturato e i mesi a rischio dell'azienda."
                    : "Le coperture key man arrivano già al fabbisogno."
                rimedio = .azienda
            default:
                frase = b.sostituzione ? "Manca il valore della posizione da sostituire." : "L'analisi non dà ancora una cifra per questo bisogno."
                rimedio = b.sostituzione ? .posizione : .analisi360
            }
            return PropostaCostruita(bisogno: b, prodotto: .fatto(scelto), importo: .manca(frase, rimedio: rimedio),
                                     prospetto: nil, adeguatezza: nil, moduli: nil, bozza: nil, scheda: nil)
        }

        // 3. Il prospetto: quello di sostituzione per «costi più bassi» (se la posizione è in Prisma), altrimenti quello
        // della posizione
        let prospetto: EsitoPasso<ProspettoProposta>
        if b.sostituzione, b.posizioneSostituitaId != nil, let a = attuale(b, fonte: fonte), let conta = contaSostituzione {
            let pagine = conta(esitoSostituzione(attuale: a, bozza: bozza, fonte: fonte), fonte.cliente)
            prospetto = pagine > 0 ? .fatto(ProspettoProposta(pagine: pagine, attualeId: a.id))
                : .manca("Il prospetto non si è potuto impaginare.", rimedio: .posizione)
        } else {
            let pagine = contaPagine(CompositoreProspetti.posizione(bozza, dati: dati))
            prospetto = pagine > 0
                ? .fatto(ProspettoProposta(pagine: pagine))
                : .manca("Il prospetto non si è potuto impaginare.", rimedio: .posizione)
        }

        // 4. L'adeguatezza, su una bozza in memoria
        let adeguatezza: EsitoPasso<AdeguatezzaProposta>? = prospetto.prosegue
            ? self.adeguatezza(bozza, scheda: scheda, fonte: fonte, voci: dati.impostazioni.consegna.voci) : nil

        // 5. I moduli: «Compila da solo» sui modelli del canale e del prodotto
        let moduli: EsitoPasso<[ModuloProposta]>? = (adeguatezza?.prosegue ?? false)
            ? self.moduli(bozza, prodotto: scelto, cliente: fonte.cliente, modelli: modelli, dati: dati, oggi: fonte.oggi) : nil

        return PropostaCostruita(bisogno: b, prodotto: .fatto(scelto), importo: .fatto(importo), prospetto: prospetto,
                                 adeguatezza: adeguatezza, moduli: moduli, bozza: bozza, scheda: scheda)
    }

    /// La cifra, la frase e la riga del premio, dai motori; scrive gli importi nella bozza. nil se i motori non danno
    /// una cifra (mai un numero inventato).
    static func importo(_ b: BisognoScoperto, prodotto: Prodotto, fonte: FonteVera,
                        bozza: inout Posizione) -> ImportoProposta? {
        let f = fonte
        if b.sostituzione {
            guard let a = attuale(b, fonte: f), a.valore > 0 else { return nil }
            if bozza.versamentoIniziale <= 0 { bozza.versamentoIniziale = a.valore }
            let e = esitoSostituzione(attuale: a, bozza: bozza, fonte: f)
            return ImportoProposta(cifra: bozza.versamentoIniziale, spiegazione: "trasferiti da «\(a.nome)»",
                                   riga: "costi da \(CifreDoc.euro(e.resto.costiPrimoAnno)) a \(CifreDoc.euro(e.cambio.costiPrimoAnno)) l'anno")
        }
        switch b.areaAzienda {
        case .personaChiave?:
            guard let capitale = b.capitale, capitale > 0 else { return nil }
            if (bozza.capitaleAssicurato ?? 0) <= 0 { bozza.capitaleAssicurato = capitale }
            let premio = bozza.premio > 0
                ? "premio: \(CifreDoc.euro(bozza.premio)) \(bozza.frequenza.nome.lowercased())"
                : premioDaChiedere
            return ImportoProposta(cifra: bozza.capitaleAssicurato ?? capitale, spiegazione: "capitale che manca alla copertura key man",
                                   riga: premio)
        case .welfare?:
            // Nessuna cifra dei motori (decisione 67): vale solo l'importo scritto dal consulente nella proposta
            let scritto = bozza.premio > 0 ? bozza.premio : bozza.versamentoIniziale
            guard scritto > 0 else { return nil }
            let quando = bozza.premio > 0 ? (CompilatoreModuli.perFrequenza(bozza.frequenza) ?? "una volta") : "una volta"
            return ImportoProposta(cifra: scritto, spiegazione: "\(quando), scritto da te", riga: rigaCosti(prodotto))
        default:
            break
        }
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

    // MARK: - Sostituzione e moduli

    static let fraseImportoWelfare = "L'importo del piano lo decidi con l'azienda: scrivilo nella proposta."

    /// La posizione da sostituire: quella in Prisma o la provvisoria dello Smontaggio.
    static func attuale(_ b: BisognoScoperto, fonte: FonteVera) -> Posizione? {
        if let id = b.posizioneSostituitaId { return fonte.posizioni.first { $0.id == id } ?? b.attualeProvvisoria }
        return b.attualeProvvisoria
    }

    /// Restare o cambiare, con le ipotesi di Prisma (penale, ingresso, tasse).
    static func esitoSostituzione(attuale a: Posizione, bozza: Posizione, fonte f: FonteVera) -> EsitoSostituzione {
        MotoreSostituzione.calcola(attuale: a, alternativa: bozza, prodotti: f.prodotti,
                                   orizzonteCliente: f.cliente.profilo.orizzonteAnni, data: f.oggi)
    }

    /// I modelli di Pratiche › Moduli della proposta: stesso canale (o nessuno) e, se il modello ne nomina, stesso
    /// prodotto; solo quelli con la mappa confermata.
    static func modelli(per bozza: Posizione, prodotto: Prodotto?, tra modelli: [ModelloModulo]) -> [ModelloModulo] {
        modelli.filter { m in
            m.mappaConfermata && (m.canale == nil || m.canale == bozza.canale)
                && (m.prodottoIds.isEmpty || prodotto.map { m.prodottoIds.contains($0.id) } == true)
        }
    }

    /// La tappa 5: per ogni modello l'anteprima di `CompilatoreModuli` (caselle compilate e da chiedere). Neutra per i
    /// moduli Alleanza (decisione 60) e senza modelli: non ferma la proposta e non inventa un elenco.
    static func moduli(_ bozza: Posizione, prodotto: Prodotto, cliente: Cliente, modelli elenco: [ModelloModulo],
                       dati: DatiPrisma, oggi: Date) -> EsitoPasso<[ModuloProposta]> {
        guard bozza.canale != .alleanza else { return .inArrivo(moduliAlleanza) }
        let scelti = modelli(per: bozza, prodotto: prodotto, tra: elenco).filter(\.compilabile)
        guard !scelti.isEmpty else { return .inArrivo(moduliSenzaModelli) }
        let f = dati.impostazioni.studio.fatturazione
        let consulente = [f.nome, f.cognome].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
        let fonte = FonteCompilazione(cliente: cliente, posizione: bozza, prodotto: prodotto, consulente: consulente,
                                      comuneConsulente: f.sede.comune, oggi: oggi,
                                      conservaIban: dati.impostazioni.pratiche.ibanConservato)
        return .fatto(scelti.map { m in
            let a = CompilatoreModuli.anteprima(m, fonte: fonte)
            return ModuloProposta(modelloId: m.id, titolo: m.titolo, compilati: a.compilati, daChiedere: a.datiMancanti.count,
                                  firme: a.firme.count)
        })
    }

    private static func minuscola(_ s: String) -> String {
        guard let prima = s.first else { return s }
        // Le sigle (SRI, KID) restano maiuscole
        let secondaMaiuscola = s.dropFirst().first.map { $0.isUppercase } ?? false
        return secondaMaiuscola ? s : prima.lowercased() + s.dropFirst()
    }
}
