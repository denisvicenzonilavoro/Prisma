import Foundation

// «Tre livelli» (Vera/BRIEF.md, funzione 17; template «// 17 · TRE LIVELLI»): la stessa spiegazione per il consulente
// (tecnica), per il cliente (semplice, con il tu) e in una pagina da stampare o consegnare, con gli STESSI numeri.
// Prima il codice: le cifre le calcolano i motori di Prisma (MotorePrevidenza, MotoreProtezioneFamiglia,
// MotoreLiquidita, RegoleFiscali) e la bozza a regole dei tre livelli si scrive solo con quelle cifre, già formattate.
// Poi Qwen (se è pronto) riscrive in JSON {tecnico, cliente, pagina}: ogni livello con una cifra che non è di Prisma,
// senza una delle cifre essenziali, con cifre in parole o (per il cliente) con una promessa si scarta e resta quello
// della bozza. La pagina diventa un ContenutoProspetto per il PDF su carta bianca, con l'avvertenza.
// Il motore non esegue niente: «Manda al cliente» è un'AzioneConferma per la scheda «Conferma».

// MARK: - Modelli (Codable: più avanti entrano nell'archivio)

/// Gli argomenti che Prisma sa già calcolare.
enum ArgomentoTreLivelli: String, Codable, CaseIterable, Identifiable {
    case previdenza, protezione, liquidita

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .previdenza: return "Il fondo pensione"
        case .protezione: return "La protezione della famiglia"
        case .liquidita: return "La liquidità"
        }
    }

    /// Il titolo della pagina da consegnare.
    var titoloPagina: String {
        switch self {
        case .previdenza: return "Il fondo pensione, in una pagina"
        case .protezione: return "La protezione della famiglia, in una pagina"
        case .liquidita: return "La tua liquidità, in una pagina"
        }
    }

    /// Il motore di Prisma da cui vengono le cifre (per la nota del PDF e per la scheda).
    var motore: String {
        switch self {
        case .previdenza: return "piano previdenziale"
        case .protezione: return "protezione della famiglia"
        case .liquidita: return "capitale in scadenza e liquidità"
        }
    }
}

/// I tre livelli della spiegazione.
enum LivelloTreLivelli: String, Codable, CaseIterable, Identifiable {
    case tecnico, cliente, pagina

    var id: String { rawValue }

    /// L'etichetta del selettore («Per te», «Per Marco», «In una pagina»).
    func etichetta(cliente: String) -> String {
        switch self {
        case .tecnico: return "Per te"
        case .cliente: return "Per \(cliente)"
        case .pagina: return "In una pagina"
        }
    }
}

/// Una cifra calcolata da Prisma, già scritta come compare nei tre livelli.
struct CifraTreLivelli: Codable, Equatable, Identifiable {
    /// La chiave («divario», «recupero100»…).
    var id: String
    /// Per l'indicatore del PDF e per l'elenco dato a Qwen.
    var etichetta: String
    var valore: Double
    /// Come si scrive («1.100 €», «33%», «67 anni», «0,3 punti»): la stessa scrittura in tutti e tre i livelli.
    var testo: String
    /// Deve comparire in tutti e tre i livelli.
    var essenziale = false
}

struct SezionePaginaTreLivelli: Codable, Equatable {
    var titolo: String
    var righe: [String]
}

struct PaginaTreLivelli: Codable, Equatable {
    var titolo: String
    var sezioni: [SezionePaginaTreLivelli]

    /// Tutto il testo della pagina (titolo, titoli delle sezioni, righe), per il controllo delle cifre.
    var testo: String {
        ([titolo] + sezioni.flatMap { [$0.titolo] + $0.righe }).joined(separator: "\n")
    }
}

/// Una spiegazione in tre livelli, con le cifre di Prisma da cui nasce.
struct SpiegazioneTreLivelli: Codable, Equatable, Identifiable {
    var id = "tre-livelli-\(UUID().uuidString.prefix(8).lowercased())"
    var clienteId: String
    var nomeCliente: String
    var argomento: ArgomentoTreLivelli
    /// La domanda del consulente («Perché il fondo pensione conviene a Marco?»).
    var domanda: String
    var creataIl: Date
    var cifre: [CifraTreLivelli]
    var tecnico: [String]
    var cliente: String
    var pagina: PaginaTreLivelli
    /// Il canale in evidenza nella pagina (nil se l'argomento tocca entrambi i canali o nessuno).
    var canale: Canale?
    /// Nomi (cliente, posizioni, salvadanai) che possono contenere numeri: non sono cifre inventate.
    var nomi: [String] = []
    /// Note per il consulente (dati mancanti, ipotesi da confermare): senza cifre, non vanno nella pagina.
    var note: [String] = []
    /// I livelli riscritti da Qwen e passati dal controllo; gli altri sono quelli di Prisma.
    var livelliQwen: [LivelloTreLivelli] = []

    var conQwen: Bool { !livelliQwen.isEmpty }
    var essenziali: [CifraTreLivelli] { cifre.filter(\.essenziale) }

    /// Il testo da controllare di un livello (senza i segni dell'elenco).
    func testoDaControllare(_ l: LivelloTreLivelli) -> String {
        switch l {
        case .tecnico: return tecnico.joined(separator: "\n")
        case .cliente: return cliente
        case .pagina: return pagina.testo
        }
    }

    /// Il testo di un livello per la chat.
    func testo(_ l: LivelloTreLivelli) -> String {
        switch l {
        case .tecnico: return tecnico.map { "• \($0)" }.joined(separator: "\n")
        case .cliente: return cliente
        case .pagina:
            return ([pagina.titolo] + pagina.sezioni.map { s in ([s.titolo] + s.righe.map { "• \($0)" }).joined(separator: "\n") })
                .joined(separator: "\n\n") + "\n\n" + TreLivelliVera.avvertenza
        }
    }
}

extension SpiegazioneTreLivelli {
    private enum CodingKeys: String, CodingKey {
        case id, clienteId, nomeCliente, argomento, domanda, creataIl, cifre, tecnico, cliente, pagina, canale, nomi, note, livelliQwen
    }

    /// Ogni campo si legge con tolleranza (archivio e backup di versioni diverse).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? "tre-livelli-\(UUID().uuidString.prefix(8).lowercased())"
        clienteId = (try? c.decodeIfPresent(String.self, forKey: .clienteId)) ?? ""
        nomeCliente = (try? c.decodeIfPresent(String.self, forKey: .nomeCliente)) ?? ""
        argomento = (try? c.decodeIfPresent(ArgomentoTreLivelli.self, forKey: .argomento)) ?? .previdenza
        domanda = (try? c.decodeIfPresent(String.self, forKey: .domanda)) ?? ""
        creataIl = (try? c.decodeIfPresent(Date.self, forKey: .creataIl)) ?? Date(timeIntervalSince1970: 0)
        cifre = (try? c.decodeIfPresent([CifraTreLivelli].self, forKey: .cifre)) ?? []
        tecnico = (try? c.decodeIfPresent([String].self, forKey: .tecnico)) ?? []
        cliente = (try? c.decodeIfPresent(String.self, forKey: .cliente)) ?? ""
        pagina = (try? c.decodeIfPresent(PaginaTreLivelli.self, forKey: .pagina)) ?? PaginaTreLivelli(titolo: "", sezioni: [])
        canale = (try? c.decodeIfPresent(Canale.self, forKey: .canale)) ?? nil
        nomi = (try? c.decodeIfPresent([String].self, forKey: .nomi)) ?? []
        note = (try? c.decodeIfPresent([String].self, forKey: .note)) ?? []
        livelliQwen = (try? c.decodeIfPresent([LivelloTreLivelli].self, forKey: .livelliQwen)) ?? []
    }
}

/// Ciò che serve per calcolare le cifre: i dati di un cliente, già filtrati.
struct FonteTreLivelli {
    let oggi: Date
    let cliente: Cliente
    /// Le posizioni del cliente (in essere, proposte, chiuse: i motori scelgono le loro).
    let posizioni: [Posizione]
    let analisi: Analisi360
    /// false = prima stesura dell'Analisi 360, con ipotesi ancora da confermare.
    var analisiSalvata = true
    var obiettivi: [Obiettivo] = []
    var prodotti: [Prodotto] = []
}

// MARK: - Motore

enum TreLivelliVera {
    /// In fondo a ogni pagina stampabile (template: «Stime di Prisma con le ipotesi della scheda…»).
    static let avvertenza = "Stime di Prisma con le ipotesi della scheda. Non sono una promessa di risultato."

    // MARK: Fonti

    /// Dai dati di Prisma (nil se il cliente non c'è). L'Analisi 360 è quella salvata o la prima stesura.
    static func fonte(dati: DatiPrisma, clienteId: String, oggi: Date) -> FonteTreLivelli? {
        guard let c = dati.clienti.first(where: { $0.id == clienteId }) else { return nil }
        let mie = dati.posizioni.filter { $0.clienteId == clienteId }
        let salvata = dati.analisi[clienteId]
        return FonteTreLivelli(oggi: oggi, cliente: c, posizioni: mie, analisi: salvata ?? Analisi360(cliente: c, posizioni: mie),
                               analisiSalvata: salvata != nil, obiettivi: dati.obiettivi.filter { $0.clienteId == clienteId },
                               prodotti: dati.prodotti)
    }

    /// Dalla fonte che Vera usa già per la chat (`StatoShell.fonteVera`).
    static func fonte(_ f: FonteVera) -> FonteTreLivelli {
        FonteTreLivelli(oggi: f.oggi, cliente: f.cliente, posizioni: f.posizioni, analisi: f.analisi,
                        analisiSalvata: f.analisiSalvata, obiettivi: f.obiettivi, prodotti: f.prodotti)
    }

    // MARK: Riconoscimento

    static let segniArgomento: [(ArgomentoTreLivelli, String)] = [
        (.previdenza, #"\bfondo pensione\b|\bfondi pensione\b|\bprevidenz\w*|\bpip\b|\bpension\w*|\b(?:pensione|previdenza) integrativa\b"#),
        (.protezione, #"\bprotezion\w*|\btcm\b|\bcaso morte\b|\bpolizza vita\b|\bassicurazion\w* sulla vita\b|\bse (?:gli|le|mi|ti) (?:succede|capita)\w*"#),
        (.liquidita, #"\bliquidit\w*|\briserva\b|\bsoldi fermi\b|\bconto corrente\b|\bcapitali? in scadenza\b|\bsalvadana\w*"#),
    ]

    /// L'argomento di una domanda (nil se non è uno dei tre).
    static func argomento(_ domanda: String) -> ArgomentoTreLivelli? {
        let t = InterpreteComandi.pulisci(domanda)
        return segniArgomento.first { DateItaliane.cerca($0.1, t) != nil }?.0
    }

    /// «Perché il fondo pensione conviene a Marco?», «spiegami la protezione di Giulia in tre livelli»,
    /// «la liquidità di Sofia in una pagina», «spiegalo in parole semplici a Laura».
    static func eUnaRichiesta(_ testo: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        guard argomento(t) != nil else { return false }
        // Le azioni (agenda, messaggi) e le domande sui documenti vanno ai loro motori
        if DateItaliane.cerca(#"^(?:fissa|sposta|blocca|ricordami|manda|scrivi a|invia|cancella)\b|\b(?:esclusion\w*|franchigi\w*|carenz\w*)\b"#, t) != nil { return false }
        return DateItaliane.cerca(#"\btre livelli\b|\bin (?:una|1) pagina\b|\bperch[eé]\b|\bspieg\w*|\bconvien\w*|\bparole semplici\b|\bper il cliente\b|\bda (?:stampare|consegnare)\b"#, t) != nil
    }

    /// Il livello che il consulente chiede per primo (quello che la scheda apre); di base il tecnico.
    static func livelloChiesto(_ testo: String) -> LivelloTreLivelli {
        let t = InterpreteComandi.pulisci(testo)
        if DateItaliane.cerca(#"\bin (?:una|1) pagina\b|\bstampabil\w*|\bda (?:stampare|consegnare)\b|\bpdf\b"#, t) != nil { return .pagina }
        if DateItaliane.cerca(#"\bper il cliente\b|\bparole semplici\b|\bsemplice\b|\bspiegal[oa] a\b|\bcome (?:lo|la) spiego a\b"#, t) != nil { return .cliente }
        return .tecnico
    }

    // MARK: Cifre e bozza

    /// Le cifre di Prisma per un argomento (le stesse della bozza).
    static func cifre(_ a: ArgomentoTreLivelli, _ f: FonteTreLivelli) -> [CifraTreLivelli] {
        bozza(a, f, domanda: "").cifre
    }

    /// La bozza a regole dei tre livelli, scritta solo con le cifre di Prisma.
    static func bozza(_ a: ArgomentoTreLivelli, _ f: FonteTreLivelli, domanda: String) -> SpiegazioneTreLivelli {
        let p: Parti
        switch a {
        case .previdenza: p = previdenza(f)
        case .protezione: p = protezione(f)
        case .liquidita: p = liquidita(f)
        }
        var note = p.note
        if !f.analisiSalvata {
            note.append("Le ipotesi dell'Analisi 360 sono una prima stesura ricavata dalle posizioni: vanno confermate con il cliente.")
        }
        return SpiegazioneTreLivelli(clienteId: f.cliente.id, nomeCliente: f.cliente.nome, argomento: a,
                                     domanda: domanda.trimmingCharacters(in: .whitespacesAndNewlines), creataIl: f.oggi,
                                     cifre: p.cifre.elenco, tecnico: p.tecnico, cliente: p.cliente, pagina: p.pagina,
                                     canale: p.canale, nomi: [f.cliente.nome] + f.posizioni.map(\.nome) + p.nomi, note: note)
    }

    /// «Marco Bianchi» → «Marco»; «Marco ed Elena Bianchi» → «Marco ed Elena».
    static func primoNome(_ nome: String) -> String {
        let parole = nome.split(separator: " ").map(String.init)
        if let i = parole.firstIndex(where: { $0 == "e" || $0 == "ed" }), i + 1 < parole.count {
            return parole[0...(i + 1)].joined(separator: " ")
        }
        return parole.first ?? nome
    }

    /// Le cifre mentre si scrive la bozza: ogni cifra entra una volta, con la sua scrittura.
    private struct Cifre {
        var elenco: [CifraTreLivelli] = []

        subscript(_ k: String) -> String { elenco.first { $0.id == k }?.testo ?? "" }

        mutating func aggiungi(_ k: String, _ etichetta: String, _ valore: Double, _ testo: String, essenziale: Bool) {
            elenco.removeAll { $0.id == k }
            elenco.append(CifraTreLivelli(id: k, etichetta: etichetta, valore: valore, testo: testo, essenziale: essenziale))
        }

        mutating func euro(_ k: String, _ etichetta: String, _ v: Double, essenziale: Bool = false) {
            aggiungi(k, etichetta, v.rounded(), CifreDoc.euro(v), essenziale: essenziale)
        }

        mutating func percento(_ k: String, _ etichetta: String, _ v: Double, essenziale: Bool = false) {
            aggiungi(k, etichetta, v, CifreDoc.condizione(v), essenziale: essenziale)
        }

        mutating func anni(_ k: String, _ etichetta: String, _ n: Int, essenziale: Bool = false) {
            aggiungi(k, etichetta, Double(n), n == 1 ? "1 anno" : "\(n) anni", essenziale: essenziale)
        }

        mutating func mesi(_ k: String, _ etichetta: String, _ n: Int, essenziale: Bool = false) {
            aggiungi(k, etichetta, Double(n), n == 1 ? "1 mese" : "\(n) mesi", essenziale: essenziale)
        }

        mutating func punti(_ k: String, _ etichetta: String, _ v: Double) {
            let n = Formati.numeroFormatter.string(from: NSNumber(value: v)) ?? "\(v)"
            aggiungi(k, etichetta, v, "\(n) punti", essenziale: false)
        }
    }

    /// Le parti della bozza di un argomento.
    private struct Parti {
        var cifre = Cifre()
        var tecnico: [String] = []
        var cliente = ""
        var pagina = PaginaTreLivelli(titolo: "", sezioni: [])
        var canale: Canale?
        var nomi: [String] = []
        var note: [String] = []
    }

    /// Il canale in evidenza: solo se le posizioni dell'argomento sono tutte dello stesso canale.
    private static func canaleUnico(_ elenco: [Posizione]) -> Canale? {
        let canali = Set(elenco.map(\.canale))
        return canali.count == 1 ? canali.first : nil
    }

    private static func canali(_ elenco: [Posizione]) -> String {
        Canale.allCases.filter { c in elenco.contains { $0.canale == c } }.map(\.nomeBreve).joined(separator: " e ")
    }

    // MARK: Previdenza (MotorePrevidenza, RegoleFiscali)

    private static func previdenza(_ f: FonteTreLivelli) -> Parti {
        let e = MotorePrevidenza.calcola(f.posizioni, cliente: f.cliente, analisi: f.analisi.previdenza, data: f.oggi)
        var p = Parti()
        let n = primoNome(f.cliente.nome)
        let conDivario = e.divario >= 1

        p.cifre.euro("desiderato", "Ti servirà, al mese", e.redditoDesiderato)
        p.cifre.euro("pubblica", "Pensione pubblica stimata, al mese", e.pensionePubblica)
        if conDivario { p.cifre.euro("divario", "Ti mancano, al mese", e.divario, essenziale: true) }
        p.cifre.anni("etaPensione", "Età della pensione", e.etaPensione)
        if e.anniAccumulo > 0 { p.cifre.anni("anniAccumulo", "Anni alla pensione", e.anniAccumulo) }

        // Fisco dei versamenti
        var recupero = false
        if let reddito = e.reddito, let marginale = e.aliquotaMarginale {
            recupero = true
            p.cifre.percento("marginale", "Aliquota IRPEF marginale", marginale)
            p.cifre.euro("riferimento", "Versamento di riferimento", 100)
            p.cifre.euro("recupero100", "Ogni 100 € versati recuperi", RegoleFiscali.risparmioDeduzione(reddito: reddito, deduzione: 100), essenziale: true)
            p.cifre.euro("limite", "Limite annuo di deducibilità", RegoleFiscali.limiteDeducibilita)
        } else {
            p.note.append("Manca il reddito lordo annuo nel profilo: senza, Prisma non calcola il risparmio IRPEF dei versamenti.")
        }
        p.cifre.percento("rendimenti", "Imposta sui rendimenti del fondo", RegoleFiscali.previdenzaRendimenti)
        p.cifre.percento("ordinaria", "Imposta sui rendimenti di un investimento normale", RegoleFiscali.ordinaria)
        p.cifre.percento("titoliStato", "Imposta sulla parte in titoli di Stato", RegoleFiscali.titoliStato)
        p.cifre.percento("aliquotaBase", "Imposta massima alla pensione", RegoleFiscali.previdenzaBase, essenziale: true)
        p.cifre.punti("riduzione", "Riduzione per ogni anno oltre il quindicesimo", RegoleFiscali.previdenzaRiduzione)
        p.cifre.percento("aliquotaMinima", "Imposta minima alla pensione", RegoleFiscali.previdenzaMinima)

        // Per te · tecnica
        var tec: [String] = []
        if recupero {
            tec.append("Contributi deducibili dal reddito fino a \(p.cifre["limite"]) l'anno, contributi del datore di lavoro compresi e TFR escluso: con un'aliquota IRPEF marginale del \(p.cifre["marginale"]), ogni \(p.cifre["riferimento"]) versati fanno risparmiare \(p.cifre["recupero100"]) di IRPEF.")
            if e.deducibiliOggi >= 1 {
                p.cifre.euro("dedotti", "Contributi dedotti ogni anno", e.deducibiliOggi)
                p.cifre.euro("risparmio", "IRPEF risparmiata ogni anno", e.risparmioOggi)
                var r = "Oggi deduce \(p.cifre["dedotti"]) l'anno e risparmia \(p.cifre["risparmio"]) di IRPEF"
                if e.spazioResiduo >= 1 {
                    p.cifre.euro("spazio", "Spazio deducibile che resta", e.spazioResiduo)
                    p.cifre.euro("risparmioPossibile", "Risparmio IRPEF in più usando tutto lo spazio", e.risparmioPossibile)
                    r += "; restano \(p.cifre["spazio"]) di spazio deducibile\(e.proposte.isEmpty ? "" : " (proposte comprese)"), che varrebbero altri \(p.cifre["risparmioPossibile"]) di risparmio"
                }
                tec.append(r + ".")
            }
        }
        tec.append("Rendimenti tassati ogni anno dentro il fondo al \(p.cifre["rendimenti"]) invece del \(p.cifre["ordinaria"]) di un investimento normale; al \(p.cifre["titoliStato"]) sulla parte in titoli di Stato.")
        var prestazione = "Prestazione tassata al \(p.cifre["aliquotaBase"]) fino al quindicesimo anno di partecipazione, poi \(p.cifre["riduzione"]) in meno per ogni anno, fino al \(p.cifre["aliquotaMinima"])."
        if let piano = e.inEssere.first {
            p.cifre.anni("anniPiano", "Anni di partecipazione alla pensione", piano.anniAllaPensione)
            p.cifre.percento("aliquotaPiano", "Imposta del piano alla pensione", piano.aliquota)
            prestazione += " Con «\(piano.posizione.nome)» (\(piano.posizione.canale.nomeBreve)) arriva alla pensione con \(p.cifre["anniPiano"]) di partecipazione: aliquota del \(p.cifre["aliquotaPiano"])."
        }
        tec.append(prestazione)
        let tra = e.anniAccumulo > 0 ? ", tra \(p.cifre["anniAccumulo"])" : ""
        if conDivario {
            tec.append("Il divario di \(n): \(p.cifre["divario"]) al mese tra pensione pubblica stimata (\(p.cifre["pubblica"])) e tenore desiderato (\(p.cifre["desiderato"])), con la pensione a \(p.cifre["etaPensione"])\(tra).")
        } else {
            tec.append("La pensione pubblica stimata (\(p.cifre["pubblica"]) al mese) copre il tenore desiderato (\(p.cifre["desiderato"])), con la pensione a \(p.cifre["etaPensione"])\(tra).")
        }
        let conPiani = conDivario && !e.inEssere.isEmpty && e.renditaInEssere >= 1
        if conPiani {
            p.cifre.euro("renditaInEssere", "Rendita dei piani in essere, al mese", e.renditaInEssere)
            p.cifre.euro("divarioResiduo", "Divario che resta, al mese", e.divarioResiduo)
            tec.append("I piani in essere (\(canali(e.inEssere.map(\.posizione)))) aggiungono circa \(p.cifre["renditaInEssere"]) al mese; restano \(p.cifre["divarioResiduo"]).")
        }
        var conVersamento = false
        if let v = e.versamentoMancante, v >= 1, e.divarioConProposte >= 1 {
            conVersamento = true
            p.cifre.euro("versamentoMancante", "Versamento in più che servirebbe, al mese", v)
            tec.append("Per colmare il resto servirebbero circa \(p.cifre["versamentoMancante"]) al mese in più.")
        }
        p.tecnico = tec

        // Per il cliente · semplice
        var frasi: [String] = []
        frasi.append(conDivario
            ? "\(n), quando andrai in pensione ti mancheranno circa \(p.cifre["divario"]) al mese rispetto a quello che vorresti."
            : "\(n), la pensione pubblica dovrebbe bastare per il tenore che desideri: il fondo serve a stare più larghi e a pagare meno tasse.")
        if recupero {
            frasi.append("Ogni \(p.cifre["riferimento"]) che metti nel fondo, con la dichiarazione dei redditi ne recuperi circa \(p.cifre["recupero100"]).")
        }
        frasi.append("Quello che il fondo guadagna paga meno tasse di un investimento normale: il \(p.cifre["rendimenti"]) invece del \(p.cifre["ordinaria"]).")
        frasi.append("E alla pensione pagherai al massimo il \(p.cifre["aliquotaBase"]): meno, fino al \(p.cifre["aliquotaMinima"]), se resti nel fondo a lungo.")
        p.cliente = frasi.joined(separator: "\n")

        // In una pagina
        var quanto = ["Ti servirà: \(p.cifre["desiderato"]) al mese", "Pensione pubblica stimata: \(p.cifre["pubblica"]) al mese"]
        quanto.append(conDivario ? "Ti mancano: \(p.cifre["divario"]) al mese" : "La pensione pubblica copre quello che desideri")
        if conPiani { quanto.append("Il piano che hai già ne copre circa \(p.cifre["renditaInEssere"]) al mese") }
        var perche: [String] = []
        if recupero { perche.append("Ogni \(p.cifre["riferimento"]) versati ne recuperi circa \(p.cifre["recupero100"]) con la dichiarazione dei redditi.") }
        perche.append("I guadagni del fondo pagano meno tasse: il \(p.cifre["rendimenti"]) invece del \(p.cifre["ordinaria"]).")
        perche.append("Alla pensione paghi al massimo il \(p.cifre["aliquotaBase"]), fino al \(p.cifre["aliquotaMinima"]) se resti a lungo.")
        var sezioni = [SezionePaginaTreLivelli(titolo: "Quanto ti servirà", righe: quanto),
                       SezionePaginaTreLivelli(titolo: "Perché il fondo", righe: perche)]
        if conVersamento {
            sezioni.append(SezionePaginaTreLivelli(titolo: "Il prossimo passo",
                                                   righe: ["Per colmare quello che manca servirebbero circa \(p.cifre["versamentoMancante"]) al mese in più."]))
        }
        p.pagina = PaginaTreLivelli(titolo: ArgomentoTreLivelli.previdenza.titoloPagina, sezioni: sezioni)
        p.canale = canaleUnico(e.piani.map(\.posizione))
        return p
    }

    // MARK: Protezione della famiglia (MotoreProtezioneFamiglia)

    private static func protezione(_ f: FonteTreLivelli) -> Parti {
        let e = MotoreProtezioneFamiglia.calcola(f.posizioni, cliente: f.cliente, analisi: f.analisi.protezione, data: f.oggi)
        let i = e.ipotesi
        var p = Parti()
        let n = primoNome(f.cliente.nome)
        let conFabbisogno = e.fabbisogno >= 1
        let conCoperto = e.capitaleVita >= 1
        let conDivario = e.divario >= 1
        let conProposte = conDivario && !e.proposte.isEmpty && e.divarioConProposte < e.divario - 0.5

        p.cifre.euro("fabbisogno", "Servirebbero alla famiglia", e.fabbisogno, essenziale: conFabbisogno)
        if i.debiti >= 1 { p.cifre.euro("debiti", "Debiti da chiudere", i.debiti) }
        if i.speseImmediate >= 1 { p.cifre.euro("spese", "Spese immediate", i.speseImmediate) }
        p.cifre.euro("mensile", "Per la famiglia, al mese", i.fabbisognoMensile)
        p.cifre.anni("anniSostegno", "Anni di sostegno", i.anniSostegno)
        if i.capitaleDisponibile >= 1 { p.cifre.euro("disponibile", "Capitale già disponibile", i.capitaleDisponibile) }
        if conCoperto { p.cifre.euro("coperto", "Coperto oggi dalle polizze", e.capitaleVita, essenziale: true) }
        if conDivario { p.cifre.euro("divario", "Mancano", e.divario, essenziale: true) }
        if conProposte { p.cifre.euro("divarioProposte", "Mancherebbero con la proposta", e.divarioConProposte) }

        // Per te · tecnica
        var tec: [String] = []
        var parti: [String] = []
        if i.debiti >= 1 { parti.append("debiti \(p.cifre["debiti"])") }
        if i.speseImmediate >= 1 { parti.append("spese immediate \(p.cifre["spese"])") }
        parti.append("\(p.cifre["mensile"]) al mese per \(p.cifre["anniSostegno"])")
        let meno = i.capitaleDisponibile >= 1 ? ", meno \(p.cifre["disponibile"]) già disponibili" : ""
        tec.append("Fabbisogno caso morte: \(p.cifre["fabbisogno"]) (\(parti.joined(separator: ", "))\(meno)).")
        if conCoperto {
            let vita = e.coperture.filter { ($0.capitaleAssicurato ?? 0) > 0 }
            let dove = vita.isEmpty ? "" : " (\(canali(vita)))"
            tec.append("Capitali caso morte in essere\(dove): \(p.cifre["coperto"])" + (conDivario ? "; divario \(p.cifre["divario"])." : ", che coprono il fabbisogno stimato."))
        } else if conDivario {
            tec.append("Nessun capitale caso morte in essere: il divario è tutto il fabbisogno, \(p.cifre["divario"]).")
        }
        if conProposte { tec.append("Con le proposte il divario scende a \(p.cifre["divarioProposte"]).") }
        if e.riservaMancante >= 1 {
            p.cifre.euro("ammanco", "Ammanco al mese in caso di invalidità o malattia lunga", e.ammanco)
            p.cifre.mesi("mesiRiserva", "Mesi da coprire con la riserva", i.mesiRiserva)
            p.cifre.euro("riserva", "Riserva necessaria", e.riservaNecessaria)
            p.cifre.euro("riservaMancante", "Riserva che manca", e.riservaMancante)
            tec.append("Invalidità o malattia lunga: mancherebbero \(p.cifre["ammanco"]) al mese; per \(p.cifre["mesiRiserva"]) serve una riserva di \(p.cifre["riserva"]), ne mancano \(p.cifre["riservaMancante"]).")
        }
        if e.premiAnnui >= 1 {
            p.cifre.euro("premi", "Premi annui delle coperture", e.premiAnnui)
            var r = "Premi delle coperture: \(p.cifre["premi"]) l'anno"
            if e.detrazione >= 1 {
                p.cifre.percento("detrazionePercento", "Detrazione IRPEF sui premi", RegoleFiscali.detrazionePremi)
                p.cifre.euro("limitePremi", "Premi detraibili per caso morte, invalidità e infortuni", RegoleFiscali.limitePremiVita)
                p.cifre.euro("detrazione", "Detrazione IRPEF ogni anno", e.detrazione)
                r += "; detrazione IRPEF del \(p.cifre["detrazionePercento"]) (caso morte, invalidità e infortuni fino a \(p.cifre["limitePremi"]) di premi): \(p.cifre["detrazione"]) l'anno"
            }
            tec.append(r + ".")
        }
        p.tecnico = tec

        // Per il cliente · semplice
        var frasi: [String] = []
        if conFabbisogno {
            frasi.append("\(n), se domani ti succedesse qualcosa, alla tua famiglia servirebbero circa \(p.cifre["fabbisogno"]) per andare avanti come oggi.")
            if conCoperto {
                frasi.append("Le polizze che hai già ne coprono \(p.cifre["coperto"])" + (conDivario ? ": ne mancano \(p.cifre["divario"])." : ": bastano."))
            } else if conDivario {
                frasi.append("Oggi nessuna polizza li copre: mancano tutti i \(p.cifre["divario"]).")
            }
            if conProposte { frasi.append("Con la soluzione che ti ho proposto ne mancherebbero \(p.cifre["divarioProposte"]).") }
            frasi.append("La cifra tiene conto di \(p.cifre["mensile"]) al mese per \(p.cifre["anniSostegno"])" + (i.debiti >= 1 ? " e dei debiti da chiudere." : "."))
        } else {
            frasi.append("\(n), con quello che la tua famiglia ha già da parte, non servirebbe un capitale in più per andare avanti come oggi.")
            if conCoperto { frasi.append("Le polizze che hai già aggiungono \(p.cifre["coperto"]) di tranquillità.") }
        }
        p.cliente = frasi.joined(separator: "\n")

        // In una pagina
        var quanto: [String] = []
        quanto.append(conFabbisogno ? "Servirebbero: \(p.cifre["fabbisogno"])" : "Con quello che c'è da parte non servirebbe un capitale in più")
        quanto.append(conCoperto ? "Coperto oggi: \(p.cifre["coperto"])" : "Coperto oggi: nessuna polizza caso morte")
        if conFabbisogno { quanto.append(conDivario ? "Mancano: \(p.cifre["divario"])" : "Le polizze di oggi bastano") }
        var origine = ["\(p.cifre["mensile"]) al mese per \(p.cifre["anniSostegno"])"]
        if i.debiti >= 1 { origine.append("Debiti da chiudere: \(p.cifre["debiti"])") }
        if i.speseImmediate >= 1 { origine.append("Spese immediate: \(p.cifre["spese"])") }
        if i.capitaleDisponibile >= 1 { origine.append("Meno quello che c'è già: \(p.cifre["disponibile"])") }
        var sezioni = [SezionePaginaTreLivelli(titolo: "Quanto servirebbe", righe: quanto),
                       SezionePaginaTreLivelli(titolo: "Da dove nasce la cifra", righe: origine)]
        if conProposte {
            sezioni.append(SezionePaginaTreLivelli(titolo: "Con la proposta", righe: ["Mancherebbero \(p.cifre["divarioProposte"])."]))
        }
        p.pagina = PaginaTreLivelli(titolo: ArgomentoTreLivelli.protezione.titoloPagina, sezioni: sezioni)
        p.canale = canaleUnico(e.coperture + e.proposte)
        return p
    }

    // MARK: Liquidità (MotoreLiquidita)

    private static func liquidita(_ f: FonteTreLivelli) -> Parti {
        let e = MotoreLiquidita.calcola(f.posizioni, obiettivi: f.obiettivi, analisi: f.analisi.protezione, prodotti: f.prodotti, data: f.oggi)
        var p = Parti()
        let n = primoNome(f.cliente.nome)
        let conScadenze = !e.scadenze.isEmpty
        let conEccedenza = e.eccedenza >= 1
        let conVantaggio = conEccedenza && e.vantaggioDestinare >= 1

        if conScadenze {
            p.cifre.euro("liquidita", "Liquidità oggi", e.liquiditaAttuale)
            p.cifre.euro("scadenze", "Capitali in scadenza, netti", e.nettoInScadenza)
            p.cifre.euro("imposteScadenze", "Imposte sui capitali in scadenza", e.imposteScadenze)
            p.cifre.mesi("finestra", "Finestra delle scadenze", IpotesiLiquidita.finestraMesi)
        }
        p.cifre.euro("totale", conScadenze ? "Disponibile tra conti e scadenze" : "Liquidità oggi", e.totale, essenziale: e.totale >= 1)
        p.cifre.euro("riserva", "Riserva da tenere", e.riservaNecessaria, essenziale: e.riservaNecessaria >= 1)
        p.cifre.mesi("mesiRiserva", "Mesi di spese nella riserva", e.mesiRiserva)
        p.cifre.euro("spese", "Spese al mese", e.fabbisognoMensile)
        if conEccedenza { p.cifre.euro("eccedenza", "Da far lavorare", e.eccedenza, essenziale: true) }
        if conVantaggio {
            p.cifre.anni("anniConfronto", "Anni del confronto", IpotesiLiquidita.anniConfronto)
            p.cifre.euro("perdita", "Potere d'acquisto perso se resta fermo", e.perditaFermo)
            p.cifre.euro("vantaggio", "In più se si destina", e.vantaggioDestinare)
        }

        // Per te · tecnica
        var tec: [String] = []
        tec.append(conScadenze
            ? "Liquidità oggi \(p.cifre["liquidita"]); nei prossimi \(p.cifre["finestra"]) arrivano \(p.cifre["scadenze"]) netti da capitali in scadenza (imposte \(p.cifre["imposteScadenze"])): in tutto \(p.cifre["totale"])."
            : "Liquidità oggi \(p.cifre["totale"]); nessun capitale in scadenza a breve.")
        tec.append("Riserva da tenere: \(p.cifre["riserva"]), cioè \(p.cifre["mesiRiserva"]) di spese da \(p.cifre["spese"]).")
        tec.append(conEccedenza ? "Eccedenza da destinare: \(p.cifre["eccedenza"])." : "Il totale non supera la riserva: niente da spostare.")
        let pieni = e.salvadanai.filter { $0.importo >= 1 }
        if conEccedenza, !pieni.isEmpty {
            var righe: [String] = []
            for s in pieni {
                let k = "salvadanaio-\(s.tipo.rawValue)"
                p.cifre.euro(k, s.titolo, s.importo)
                p.nomi.append(contentsOf: [s.titolo, s.orizzonte])
                righe.append("\(s.titolo) \(p.cifre[k]) (\(s.orizzonte))")
            }
            tec.append("Salvadanai: " + righe.joined(separator: "; ") + ".")
        }
        if conVantaggio {
            tec.append("In \(p.cifre["anniConfronto"]), lasciato fermo, il capitale perde \(p.cifre["perdita"]) di potere d'acquisto; destinato ai salvadanai ne guadagna \(p.cifre["vantaggio"]) in più.")
        }
        p.tecnico = tec

        // Per il cliente · semplice
        var frasi = ["\(n), oggi hai \(p.cifre["totale"]) tra conti e risparmi pronti\(conScadenze ? ", contando i capitali in scadenza" : "")."]
        frasi.append("Per stare tranquillo te ne servono \(p.cifre["riserva"]) a portata di mano: \(p.cifre["mesiRiserva"]) di spese.")
        if conEccedenza {
            frasi.append("Gli altri \(p.cifre["eccedenza"]) possono lavorare meglio" + (conVantaggio
                ? ": lasciati fermi, in \(p.cifre["anniConfronto"]) i tuoi risparmi perderebbero circa \(p.cifre["perdita"]) di valore."
                : "."))
        } else {
            frasi.append("Quello che hai serve tutto come riserva: va bene così.")
        }
        p.cliente = frasi.joined(separator: "\n")

        // In una pagina
        var quanto = ["Disponibile: \(p.cifre["totale"])", "Riserva da tenere: \(p.cifre["riserva"])"]
        quanto.append(conEccedenza ? "Da far lavorare: \(p.cifre["eccedenza"])" : "Tutto serve come riserva")
        var sezioni = [SezionePaginaTreLivelli(titolo: "Quanto hai", righe: quanto),
                       SezionePaginaTreLivelli(titolo: "Perché una riserva", righe: ["\(p.cifre["mesiRiserva"]) di spese a portata di mano, per gli imprevisti."])]
        if conVantaggio {
            sezioni.append(SezionePaginaTreLivelli(titolo: "Se resta fermo", righe: [
                "In \(p.cifre["anniConfronto"]) perderebbe circa \(p.cifre["perdita"]) di potere d'acquisto.",
                "Destinato con criterio guadagnerebbe \(p.cifre["vantaggio"]) in più.",
            ]))
        }
        p.pagina = PaginaTreLivelli(titolo: ArgomentoTreLivelli.liquidita.titoloPagina, sezioni: sezioni)
        p.canale = nil
        return p
    }

    // MARK: Controllo delle cifre (stessi numeri nelle tre versioni)

    /// Un numero ammesso o trovato: il valore (senza segno) con la sua unità.
    struct CifraControllo: Equatable {
        var valore: Double
        var unita: UnitaCifra
    }

    /// Gli anni scritti da soli (1900-2100, senza unità e senza separatori) che FontiVera.numeri lascia fuori come date:
    /// qui si controllano, perché un «nel 2049» o «circa 2000 al mese» di Qwen non viene da Prisma.
    private static let schemaAnni = try? NSRegularExpression(
        pattern: #"(?<![\p{L}\d.,:/+\-−])(\d{4})(?![\d/°ª]|[.,]\d)(?!\s?(?:€|euro\b|%|per cento\b|anni\b|anno\b|mesi\b|mese\b))"#,
        options: [.caseInsensitive])

    /// I numeri di un testo con la loro unità: quelli di FontiVera.numeri (orari e giorni con il mese restano fuori)
    /// più gli anni scritti da soli, che FontiVera salta e qui invece contano.
    static func numeriConUnita(_ testo: String) -> [NumeroNelTesto] {
        var trovati = FontiVera.numeri(testo)
        if let re = schemaAnni {
            let ns = testo as NSString
            for m in re.matches(in: testo, range: NSRange(location: 0, length: ns.length)) {
                let cifra = ns.substring(with: m.range(at: 1))
                guard let v = Double(cifra), v >= 1900, v <= 2100 else { continue }
                trovati.append(NumeroNelTesto(testo: cifra, valore: v, unita: .nessuna, posizione: m.range(at: 1)))
            }
        }
        return trovati
    }

    /// I numeri di un testo come valori (senza segno), anni compresi.
    static func numeri(_ testo: String) -> [Double] {
        numeriConUnita(testo).map { abs($0.valore) }
    }

    /// I numeri di un testo come valore e unità.
    static func cifreControllo(_ testo: String) -> [CifraControllo] {
        numeriConUnita(testo).map { CifraControllo(valore: abs($0.valore), unita: $0.unita) }
    }

    /// I valori come si leggono nella scrittura di una cifra («1.100 €» → 1100 €, «0,3 punti» → 0,3 senza unità).
    static func valori(_ c: CifraTreLivelli) -> [CifraControllo] {
        let v = cifreControllo(c.testo)
        return v.isEmpty ? [CifraControllo(valore: abs(c.valore), unita: .nessuna)] : v
    }

    /// Tutti i numeri ammessi: quelli delle cifre di Prisma, più quelli dentro i nomi (cliente, posizioni, salvadanai).
    static func ammessi(_ s: SpiegazioneTreLivelli) -> [CifraControllo] {
        s.cifre.flatMap(valori) + s.nomi.flatMap(cifreControllo)
    }

    private static func uguale(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.005 }

    /// Un numero trovato corrisponde a uno ammesso se il valore è lo stesso e l'unità pure; un numero scritto senza
    /// unità («1.100 al mese») non cambia il significato e vale per qualunque unità. «67 €» non è «67 anni», «35%» non è «35 €».
    static func corrisponde(_ trovato: CifraControllo, _ ammesso: CifraControllo) -> Bool {
        uguale(trovato.valore, ammesso.valore) && (trovato.unita == ammesso.unita || trovato.unita == .nessuna)
    }

    /// I numerali scritti in lettere (da due in su, decine e composti, cento e centinaia, mille, mila, milioni, miliardi,
    /// «per cento», «metà»), anche in una parola sola («duemila», «centocinquanta», «millecinquecento», «seimila»).
    /// «sei» da solo resta fuori perché è anche il verbo, ma «sei mesi», «sei anni», «sei euro» sono cifre;
    /// «tutti e due» e «tutte e tre» restano fuori.
    private static let numeraliInLettere: String = {
        // I pezzi di un numerale: una parola fatta solo di questi pezzi è un numerale («ventitré», «duecentomila»)
        let pezzi = "diciassette|diciotto|diciannove|quattordici|undici|dodici|tredici|quindici|sedici|dieci"
            + "|quattro|cinque|sette|otto|nove|uno|due|tre|tré|sei"
            + "|venti?|trenta?|quaranta?|cinquanta?|sessanta?|settanta?|ottanta?|novanta?"
            + "|cento|cent|mille|mila|milion[ei]|miliard[oi]"
        return #"\d\s*(?:mila|mln|milion\w*|miliard\w*)\b"#
            + #"|\bsei\s+(?:anni|anno|mesi|mese|euro|volte|punti|per\s+cento)\b"#
            + #"|\bper\s+cento\b|\bmetà\b"#
            + #"|\b(?:"# + pezzi + #")+\b"#
    }()

    /// Le parole fatte di pezzi di numerale che da sole non sono cifre: «sei» (il verbo), «uno» (l'articolo), i troncamenti.
    private static let nonNumerali: Set<String> = ["sei", "uno", "cent", "vent", "trent", "quarant", "cinquant", "sessant", "settant", "ottant", "novant"]

    private static let schemaNumerali = try? NSRegularExpression(pattern: numeraliInLettere, options: [.caseInsensitive])

    /// Le cifre scritte in lettere di un testo, in minuscolo («venti», «per cento», «diciotto», «duemila»): anche
    /// Ragiona a passi le usa, per scartare le cifre in lettere della spiegazione di Qwen.
    static func paroleNumeriche(_ testo: String) -> Set<String> {
        guard let re = schemaNumerali else { return [] }
        let t = testo.lowercased().replacingOccurrences(of: #"\btutt[ie]\s+e\s+(?:due|tre)\b"#, with: " ", options: .regularExpression)
        let ns = t as NSString
        return Set(re.matches(in: t, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range).replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        }.filter { !nonNumerali.contains($0) })
    }

    /// true se il testo ha cifre scritte in lettere («venti per cento», «trentacinque euro», «tra diciotto anni»).
    static func cifreInParole(_ testo: String) -> Bool {
        !paroleNumeriche(testo).isEmpty
    }

    /// I problemi di un testo per un livello: vuoto = va bene. Una cifra non di Prisma (anche con l'unità scambiata),
    /// una cifra essenziale che manca, cifre in parole; per il cliente e la pagina anche una promessa di risultato.
    static func problemi(_ testo: String, livello: LivelloTreLivelli, spiegazione s: SpiegazioneTreLivelli) -> [String] {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return ["\(livello.rawValue): vuoto"] }
        var p: [String] = []
        let minuscolo = t.lowercased()
        // I nomi (cliente, posizioni, salvadanai) possono contenere parole come «Tre» o «Cento»: non sono cifre
        let senzaNomi = s.nomi.filter { !$0.isEmpty }.reduce(t) { $0.replacingOccurrences(of: $1, with: " ") }
        if cifreInParole(senzaNomi) {
            p.append("\(livello.rawValue): cifre in parole")
        }
        if livello != .tecnico, DateItaliane.cerca(#"\bgarantit\w*|\bsicuramente\b|\bdi sicuro\b|\bsenza (?:alcun )?rischi\w*"#, minuscolo) != nil {
            p.append("\(livello.rawValue): promessa di risultato")
        }
        let consentiti = ammessi(s)
        let trovati = numeriConUnita(t)
        let cifreTrovate = trovati.map { CifraControllo(valore: abs($0.valore), unita: $0.unita) }
        for (n, c) in zip(trovati, cifreTrovate) where !consentiti.contains(where: { corrisponde(c, $0) }) {
            p.append("\(livello.rawValue): cifra non di Prisma «\(n.testo)»")
        }
        for c in s.essenziali where !valori(c).contains(where: { v in cifreTrovate.contains { corrisponde($0, v) } }) {
            p.append("\(livello.rawValue): manca «\(c.etichetta)» (\(c.testo))")
        }
        return p
    }

    /// I problemi di ogni livello della spiegazione (vuoto per ogni livello = stessi numeri nelle tre versioni).
    static func verifica(_ s: SpiegazioneTreLivelli) -> [LivelloTreLivelli: [String]] {
        var r: [LivelloTreLivelli: [String]] = [:]
        for l in LivelloTreLivelli.allCases {
            r[l] = problemi(s.testoDaControllare(l), livello: l, spiegazione: s)
        }
        return r
    }

    /// true se i tre livelli usano solo le cifre di Prisma e tutti dicono le cifre essenziali.
    static func stessiNumeri(_ s: SpiegazioneTreLivelli) -> Bool {
        verifica(s).values.allSatisfy(\.isEmpty)
    }

    // MARK: Qwen (JSON)

    static let schema: [String: Any] = {
        let testo: [String: Any] = ["type": "string"]
        let elenco: [String: Any] = ["type": "array", "items": testo]
        let sezione: [String: Any] = ["type": "object", "required": ["titolo", "righe"],
                                      "properties": ["titolo": testo, "righe": elenco] as [String: Any]]
        let pagina: [String: Any] = ["type": "object", "required": ["titolo", "sezioni"],
                                     "properties": ["titolo": testo, "sezioni": ["type": "array", "items": sezione] as [String: Any]] as [String: Any]]
        return ["type": "object", "required": ["tecnico", "cliente", "pagina"],
                "properties": ["tecnico": elenco, "cliente": testo, "pagina": pagina] as [String: Any]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("tre-livelli") ?? "Riscrivi in tre versioni una spiegazione preparata da Prisma: tecnico (punti brevi per il consulente, con i termini tecnici), cliente (un testo semplice con il tu e il nome del cliente, senza termini tecnici) e pagina (titolo e da due a quattro sezioni con titolo e righe brevi). Usa solo le cifre dell'elenco di Prisma, scritte come sono; quelle segnate «in tutte e tre» devono stare in tutte e tre le versioni. Non fare conti, non scrivere cifre in parole, non numerare, nessuna promessa di risultato. Rispondi solo con il JSON: tecnico (elenco), cliente (testo), pagina (titolo, sezioni con titolo e righe)."
    }

    static func messaggi(_ s: SpiegazioneTreLivelli) -> [MessaggioModello] {
        let cifre = s.cifre.map { "- \($0.etichetta): \($0.testo)\($0.essenziale ? " [in tutte e tre]" : "")" }.joined(separator: "\n")
        let pagina = s.pagina.sezioni.map { "\($0.titolo)\n" + $0.righe.map { "- \($0)" }.joined(separator: "\n") }.joined(separator: "\n")
        let domanda = s.domanda.isEmpty ? "" : "\nDOMANDA DEL CONSULENTE: \(s.domanda)"
        let testo = """
        CLIENTE: \(s.nomeCliente) (con il tu: \(primoNome(s.nomeCliente)))
        ARGOMENTO: \(s.argomento.nome)\(domanda)

        CIFRE DI PRISMA
        \(cifre)

        BOZZA · PER TE
        \(s.tecnico.map { "- \($0)" }.joined(separator: "\n"))

        BOZZA · PER IL CLIENTE
        \(s.cliente)

        BOZZA · IN UNA PAGINA
        \(s.pagina.titolo)
        \(pagina)
        """
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni), MessaggioModello(ruolo: .utente, testo: testo)]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.2
        o.contesto = NucleoVera.finestra
        o.massimoToken = 1_400
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    /// Una riga di Qwen senza i segni dell'elenco e la numerazione («- », «• », «1. »).
    static func pulisciRiga(_ r: String) -> String {
        r.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: #"^\s*(?:[-•*·]|\d{1,2}[\.\)])\s+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// La spiegazione con i livelli di Qwen che passano il controllo; gli altri restano quelli della bozza di Prisma.
    /// Un JSON non valido lascia la bozza com'è.
    static func leggi(_ json: String, bozza b: SpiegazioneTreLivelli) -> SpiegazioneTreLivelli {
        guard let i = json.firstIndex(of: "{"), let fine = json.lastIndex(of: "}"), i < fine,
              let d = String(json[i...fine]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return b }
        var s = b
        var presi: [LivelloTreLivelli] = []

        if let elenco = j["tecnico"] as? [String] {
            let righe = elenco.map(pulisciRiga).filter { !$0.isEmpty }
            if !righe.isEmpty, righe.count <= 10, problemi(righe.joined(separator: "\n"), livello: .tecnico, spiegazione: b).isEmpty {
                s.tecnico = righe
                presi.append(.tecnico)
            }
        }
        if let testo = (j["cliente"] as? String)?.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespacesAndNewlines),
           testo.count >= 20, problemi(testo, livello: .cliente, spiegazione: b).isEmpty {
            s.cliente = testo
            presi.append(.cliente)
        }
        if let p = j["pagina"] as? [String: Any], let elenco = p["sezioni"] as? [[String: Any]] {
            let titolo = ((p["titolo"] as? String).map(pulisciRiga)).flatMap { $0.isEmpty ? nil : $0 } ?? b.pagina.titolo
            let sezioni = elenco.compactMap { v -> SezionePaginaTreLivelli? in
                guard let t = (v["titolo"] as? String).map(pulisciRiga), !t.isEmpty,
                      let righe = (v["righe"] as? [String])?.map(pulisciRiga).filter({ !$0.isEmpty }), !righe.isEmpty, righe.count <= 6 else { return nil }
                return SezionePaginaTreLivelli(titolo: t, righe: righe)
            }
            let pagina = PaginaTreLivelli(titolo: titolo, sezioni: sezioni)
            if sezioni.count == elenco.count, (1...5).contains(sezioni.count),
               problemi(pagina.testo, livello: .pagina, spiegazione: b).isEmpty {
                s.pagina = pagina
                presi.append(.pagina)
            }
        }
        s.livelliQwen = presi
        return s
    }

    // MARK: Uscite

    /// La pagina come prospetto per il PDF su carta bianca: le cifre essenziali come indicatori, le sezioni, l'avvertenza.
    static func contenuto(_ s: SpiegazioneTreLivelli) -> ContenutoProspetto {
        var blocchi: [BloccoProspetto] = []
        if !s.essenziali.isEmpty {
            blocchi.append(.indicatori(s.essenziali.map { IndicatoreProspetto(etichetta: $0.etichetta, valore: $0.testo) }))
        }
        for (n, sezione) in s.pagina.sezioni.enumerated() {
            blocchi.append(.sezione(numero: String(format: "%02d", n + 1), titolo: sezione.titolo))
            blocchi.append(.testo(sezione.righe.map { "• \($0)" }.joined(separator: "\n")))
        }
        blocchi.append(.nota(avvertenza + " I numeri sono calcolati da Prisma (\(s.argomento.motore)), le parole sono di Vera."))
        return ContenutoProspetto(occhiello: "Per \(s.nomeCliente)", titolo: s.pagina.titolo, sottotitolo: s.argomento.nome,
                                  cliente: s.nomeCliente, data: s.creataIl, canale: s.canale, blocchi: blocchi)
    }

    /// «Manda al cliente»: la bozza del messaggio con il testo semplice, da confermare (Vera non invia).
    static func azioneManda(_ s: SpiegazioneTreLivelli, cliente c: Cliente) -> AzioneConferma {
        let canale: CanaleMessaggio = c.telefono.filter(\.isNumber).count >= 6 ? .messaggi : .mail
        return AzioneConferma(strumento: RegistroStrumenti.messaggiPrepara, app: .messaggi,
                              titolo: "Preparo un messaggio per \(c.nome)",
                              dettaglio: RegistroStrumenti.dettaglioMessaggio(s.cliente, canale: canale),
                              argomenti: ["cliente": c.id, "scopo": "altro", "testo": s.cliente, "canale": canale.rawValue,
                                          "spiegazione": s.id],
                              avviso: stessiNumeri(s) ? nil : "Le cifre dei tre livelli non tornano: rileggi prima di mandare.")
    }

    /// La risposta in chat: il livello chiesto, con il titolo dell'argomento.
    static func risposta(_ s: SpiegazioneTreLivelli, livello: LivelloTreLivelli) -> RispostaVera {
        var testo = s.testo(livello)
        if livello == .tecnico, !s.note.isEmpty { testo += "\n\n" + s.note.joined(separator: "\n") }
        return RispostaVera(titolo: "\(s.argomento.nome) · \(livello.etichetta(cliente: primoNome(s.nomeCliente)))", testo: testo)
    }
}
