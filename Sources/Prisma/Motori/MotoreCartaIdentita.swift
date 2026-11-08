import Foundation

// «Nuovo cliente in 10 secondi» (Design/template-luce-specifica.md §9.1, «Luce» giro 13): dal testo letto sulla carta
// d'identità (righe con il loro riquadro, `LetturaDocumenti.riconosciConRiquadri`, sull'iPhone o sul Mac) i dati
// dell'anagrafica. Due fonti: le etichette stampate sul fronte e la zona a lettura ottica (ICAO 9303: TD1 a tre righe
// da 30 caratteri della carta elettronica, TD3 a due righe da 44 del passaporto) con le cifre di controllo 7-3-1. Dove la
// zona ottica c'è e torna vince sul fronte; dove non torna il campo resta «da guardare». **Mai un campo indovinato**:
// quello che non si trova è nil e la scheda lo dice «non letto: lo scrivi tu». Motore puro, niente stato dell'app.

/// Da dove viene un campo della carta.
enum FonteCampoCarta: String, Equatable {
    case fronte, zonaOttica, aMano
}

/// I campi che la carta può dare.
enum CampoCarta: String, CaseIterable, Identifiable, Hashable {
    case cognome, nome, dataNascita, luogoNascita, sesso, codiceFiscale, numero, rilasciatoIl, scadenza, cittadinanza

    var id: String { rawValue }

    var etichetta: String {
        switch self {
        case .cognome: return "Cognome"
        case .nome: return "Nome"
        case .dataNascita: return "Data di nascita"
        case .luogoNascita: return "Luogo di nascita"
        case .sesso: return "Sesso"
        case .codiceFiscale: return "Codice fiscale"
        case .numero: return "Numero del documento"
        case .rilasciatoIl: return "Rilasciato il"
        case .scadenza: return "Scadenza"
        case .cittadinanza: return "Cittadinanza"
        }
    }

    /// I campi che servono all'anagrafica: quelli che mancano si contano nel sottotitolo («Mancano 2 dati»).
    static let essenziali: [CampoCarta] = [.cognome, .nome, .dataNascita, .luogoNascita, .codiceFiscale, .scadenza]
}

/// Un campo letto: il valore come stampato, il riquadro da accendere e la fonte.
struct CampoLetto: Equatable {
    var valore: String
    var riquadro: RiquadroPagina?
    var fonte: FonteCampoCarta
    /// La zona ottica c'era ma le cifre di controllo non tornano: il campo resta da guardare.
    var daGuardare = false

    init(valore: String, riquadro: RiquadroPagina? = nil, fonte: FonteCampoCarta, daGuardare: Bool = false) {
        self.valore = valore
        self.riquadro = riquadro
        self.fonte = fonte
        self.daGuardare = daGuardare
    }
}

/// Quello che si è letto sulla carta (fronte, retro o tutti e due).
struct LetturaCartaIdentita: Equatable {
    var tipo: TipoDocumentoIdentita?
    var campi: [CampoCarta: CampoLetto] = [:]
    var conZonaOttica = false

    init(tipo: TipoDocumentoIdentita? = nil, campi: [CampoCarta: CampoLetto] = [:], conZonaOttica: Bool = false) {
        self.tipo = tipo
        self.campi = campi
        self.conZonaOttica = conZonaOttica
    }

    subscript(_ c: CampoCarta) -> CampoLetto? {
        get { campi[c] }
        set { campi[c] = newValue }
    }

    var vuota: Bool { campi.isEmpty }

    /// Fronte e retro: i campi del secondo foglio si aggiungono, mai sopra uno già letto (salvo la zona ottica che torna,
    /// che vince su un campo del fronte o su uno da guardare).
    func unita(con altra: LetturaCartaIdentita) -> LetturaCartaIdentita {
        var r = self
        r.tipo = tipo ?? altra.tipo
        r.conZonaOttica = conZonaOttica || altra.conZonaOttica
        for (chiave, nuovo) in altra.campi {
            guard let vecchio = campi[chiave] else {
                r.campi[chiave] = nuovo
                continue
            }
            if vecchio.fonte == .aMano { continue }
            let nuovoVince = nuovo.fonte == .zonaOttica && !nuovo.daGuardare && (vecchio.fonte != .zonaOttica || vecchio.daGuardare)
            if nuovoVince { r.campi[chiave] = nuovo }
        }
        return r
    }

    /// Le correzioni scritte a mano nella scheda: un testo vuoto toglie il campo, gli altri diventano «scritto da te».
    func conCorrezioni(_ correzioni: [CampoCarta: String]) -> LetturaCartaIdentita {
        var r = self
        for (chiave, testo) in correzioni {
            let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty {
                r.campi[chiave] = nil
            } else {
                r.campi[chiave] = CampoLetto(valore: t, riquadro: campi[chiave]?.riquadro, fonte: .aMano)
            }
        }
        return r
    }

    // MARK: Valori già interpretati per la scheda e la creazione

    var dataNascita: Date? { campi[.dataNascita].flatMap { MotoreCartaIdentita.data($0.valore) } }
    var scadenza: Date? { campi[.scadenza].flatMap { MotoreCartaIdentita.data($0.valore) } }
    var rilasciatoIl: Date? { campi[.rilasciatoIl].flatMap { MotoreCartaIdentita.data($0.valore) } }

    var sessoLetto: SessoAnagrafico? {
        guard let v = campi[.sesso]?.valore.trimmingCharacters(in: .whitespaces).uppercased(), let primo = v.first else { return nil }
        if primo == "F" { return .femmina }
        if primo == "M" { return .maschio }
        return nil
    }

    /// «Elena Marchi» (dalla carta arrivano in maiuscolo). Nil se mancano tutti e due.
    var nomeCompleto: String? {
        let parti = [campi[.nome]?.valore, campi[.cognome]?.valore]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map(MotoreCartaIdentita.maiuscoleIniziali)
        return parti.isEmpty ? nil : parti.joined(separator: " ")
    }

    /// Il codice fiscale pulito (maiuscolo, senza spazi), o nil.
    var codiceFiscale: String? {
        guard let v = campi[.codiceFiscale]?.valore else { return nil }
        let p = CodiceFiscale.pulito(v)
        return p.isEmpty ? nil : p
    }

    /// Il luogo di nascita come va sui moduli («Bologna (BO)»).
    var luogoNascita: String? {
        guard let v = campi[.luogoNascita]?.valore.trimmingCharacters(in: .whitespaces), !v.isEmpty else { return nil }
        return MotoreCartaIdentita.luogo(v)
    }

    /// La cittadinanza per il dossier: «ITA» della zona ottica diventa «Italiana»; le altre sigle restano come sono.
    var cittadinanza: String? {
        guard let v = campi[.cittadinanza]?.valore.trimmingCharacters(in: .whitespaces), !v.isEmpty else { return nil }
        if v.uppercased() == "ITA" { return "Italiana" }
        return v.count == 3 ? v.uppercased() : MotoreCartaIdentita.maiuscoleIniziali(v)
    }

    /// Il numero del documento, senza spazi.
    var numero: String? {
        guard let v = campi[.numero]?.valore else { return nil }
        let n = v.uppercased().filter { $0.isLetter || $0.isNumber }
        return n.isEmpty ? nil : n
    }

    /// Il documento d'identità per la conformità del cliente.
    var documento: DocumentoIdentita {
        DocumentoIdentita(tipo: tipo, numero: numero, rilasciatoIl: rilasciatoIl, scadenza: scadenza)
    }
}

/// Una riga della scheda «Nuovo cliente», nell'ordine del template (cinque).
struct RigaNuovoCliente: Identifiable, Equatable {
    enum Stato: Equatable { case letta, scrittaDaTe, mancante, daGuardare }
    /// "nome", "nascita", "cf", "documento", "eta".
    let id: String
    /// «Nome e cognome», «Nata il» / «Nato il», «Codice fiscale», «Documento», «Età».
    let etichetta: String
    /// Il valore o «non letto: lo scrivi tu».
    let valore: String
    let stato: Stato
    /// I riquadri veri da accendere (`CampoLetto.riquadro`).
    let riquadri: [RiquadroPagina]
    /// I campi che si modificano sul posto da questa riga.
    let campi: [CampoCarta]
    /// Una nota sotto la riga («Per l'identificazione serve un documento valido»), o nil.
    var nota: String? = nil
}

enum MotoreCartaIdentita {

    static let nonLetto = "non letto: lo scrivi tu"
    static let notaScaduto = "Per l’identificazione serve un documento valido"

    // MARK: - Lettura

    /// Legge le righe di una faccia (fronte o retro): prima il fronte, poi la zona ottica che, dove torna, vince.
    static func leggi(_ righe: [RigaLetta]) -> LetturaCartaIdentita {
        let fronte = leggiFronte(righe)
        guard let zona = zonaOttica(righe.map(\.testo)) else { return fronte }
        var r = fronte
        r.conZonaOttica = true
        r.tipo = zona.tipo ?? fronte.tipo
        for (chiave, campo) in zona.campi {
            if let f = fronte.campi[chiave] {
                if campo.daGuardare {
                    // Le cifre di controllo non tornano: resta il valore del fronte, da guardare
                    var g = f
                    g.daGuardare = true
                    r.campi[chiave] = g
                } else if chiave == .cognome || chiave == .nome {
                    // I nomi della zona non hanno accenti né apostrofi: il fronte resta
                    continue
                } else {
                    var z = campo
                    z.riquadro = f.riquadro
                    r.campi[chiave] = z
                }
            } else {
                r.campi[chiave] = campo
            }
        }
        return r
    }

    /// Testo per il confronto delle etichette: maiuscolo, senza accenti né punteggiatura finale.
    private static func piegato(_ s: String) -> String {
        let p = s.folding(options: [.diacriticInsensitive], locale: Formati.italiano).uppercased()
            .replacingOccurrences(of: "’", with: "'")
        return p.trimmingCharacters(in: CharacterSet(charactersIn: " :.-\t"))
    }

    /// Le etichette stampate sui documenti italiani, dalla più lunga (così «NOME» non scatta dentro altre).
    private static let etichette: [(String, CampoCarta)] = [
        ("LUOGO E DATA DI NASCITA", .dataNascita),
        ("DATA DI NASCITA", .dataNascita),
        ("LUOGO DI NASCITA", .luogoNascita),
        ("CODICE FISCALE", .codiceFiscale),
        ("CITTADINANZA", .cittadinanza),
        ("NATO/A IL", .dataNascita),
        ("NATA IL", .dataNascita),
        ("NATO IL", .dataNascita),
        ("SCADENZA", .scadenza),
        ("EMISSIONE", .rilasciatoIl),
        ("COGNOME", .cognome),
        ("SESSO", .sesso),
        ("NOME", .nome),
    ]

    /// Il campo di un'etichetta e il testo che resta dopo, se la riga è un'etichetta. «A» vale solo da sola.
    private static func etichetta(_ testo: String) -> (campo: CampoCarta, etichetta: String, resto: String)? {
        let p = piegato(testo)
        if p == "A" { return (.luogoNascita, "A", "") }
        for (e, campo) in etichette {
            if p == e { return (campo, e, "") }
            if p.hasPrefix(e + " ") || p.hasPrefix(e + ":") {
                let resto = String(p.dropFirst(e.count)).trimmingCharacters(in: CharacterSet(charactersIn: " :.-\t"))
                return (campo, e, resto)
            }
        }
        return nil
    }

    /// La riga che sta sotto l'etichetta (riquadro più in basso che si sovrappone in orizzontale), non un'altra etichetta.
    private static func rigaSotto(_ i: Int, in righe: [RigaLetta]) -> Int? {
        guard let r = righe[i].riquadro else {
            let j = i + 1
            return j < righe.count && etichetta(righe[j].testo) == nil ? j : nil
        }
        var migliore: (Int, Double)?
        for (j, riga) in righe.enumerated() where j != i {
            guard let q = riga.riquadro, etichetta(riga.testo) == nil else { continue }
            let sotto = q.y >= r.y + r.altezza * 0.5
            let sovrapposta = q.x < r.x + max(r.larghezza, 0.05) && r.x < q.x + q.larghezza
            let distanza = q.y - r.y
            guard sotto, sovrapposta, distanza < 0.2 else { continue }
            if migliore == nil || distanza < (migliore?.1 ?? 1) { migliore = (j, distanza) }
        }
        return migliore?.0
    }

    /// Il fronte: etichette con il valore sotto o accanto, il codice fiscale anche senza etichetta, il tipo dal titolo.
    static func leggiFronte(_ righe: [RigaLetta]) -> LetturaCartaIdentita {
        var l = LetturaCartaIdentita()
        for riga in righe {
            let p = piegato(riga.testo)
            if l.tipo == nil {
                if p.contains("CARTA D'IDENTITA") || p.contains("CARTA DI IDENTITA") { l.tipo = .cartaIdentita }
                else if p.contains("PASSAPORTO") || p.contains("PASSPORT") { l.tipo = .passaporto }
            }
        }
        for (i, riga) in righe.enumerated() {
            guard let e = etichetta(riga.testo) else { continue }
            var valore = e.resto
            var riquadro = riga.riquadro
            if valore.isEmpty, let j = rigaSotto(i, in: righe) {
                valore = righe[j].testo.trimmingCharacters(in: .whitespaces)
                riquadro = righe[j].riquadro
            }
            guard !valore.isEmpty else { continue }
            if e.etichetta == "LUOGO E DATA DI NASCITA" {
                if let separati = separaData(valore) {
                    if l[.dataNascita] == nil { l[.dataNascita] = CampoLetto(valore: separati.0, riquadro: riquadro, fonte: .fronte) }
                    if !separati.1.isEmpty, l[.luogoNascita] == nil {
                        l[.luogoNascita] = CampoLetto(valore: separati.1, riquadro: riquadro, fonte: .fronte)
                    }
                }
                continue
            }
            switch e.campo {
            case .dataNascita, .scadenza, .rilasciatoIl:
                // Solo una data vera: mai un valore preso a caso
                guard data(valore) != nil else { continue }
            case .codiceFiscale:
                guard CodiceFiscale.pulito(valore).count == 16 else { continue }
            case .sesso:
                let s = valore.uppercased()
                guard s == "F" || s == "M" || s.hasPrefix("F ") || s.hasPrefix("M ") || s.hasPrefix("F/") || s.hasPrefix("M/") else { continue }
            default:
                break
            }
            if l[e.campo] == nil { l[e.campo] = CampoLetto(valore: valore, riquadro: riquadro, fonte: .fronte) }
        }
        // Il codice fiscale anche senza etichetta: la prima parola con la forma giusta (omocodie comprese)
        if l[.codiceFiscale] == nil {
            parole: for riga in righe {
                for parola in riga.testo.split(whereSeparator: { $0 == " " || $0 == "\t" }) {
                    let w = String(parola)
                    if w.count == 16, EstrattoreDocumento.formaCodiceFiscaleValida(CodiceFiscale.senzaOmocodia(w)) {
                        l[.codiceFiscale] = CampoLetto(valore: w.uppercased(), riquadro: riga.riquadro, fonte: .fronte)
                        break parole
                    }
                }
            }
        }
        // Il numero della carta elettronica (due lettere, cinque cifre, due lettere), stampato senza etichetta
        if l[.numero] == nil {
            numero: for riga in righe {
                for parola in riga.testo.split(separator: " ") where String(parola).range(of: #"^[A-Z]{2}\d{5}[A-Z]{2}$"#, options: .regularExpression) != nil {
                    l[.numero] = CampoLetto(valore: String(parola), riquadro: riga.riquadro, fonte: .fronte)
                    break numero
                }
            }
        }
        return l
    }

    /// «BOLOGNA (BO) 03.04.1990» → («03.04.1990», «BOLOGNA (BO)»).
    private static func separaData(_ s: String) -> (String, String)? {
        guard let r = s.range(of: schemaData, options: .regularExpression) else { return nil }
        let dataTesto = String(s[r])
        let luogo = s.replacingCharacters(in: r, with: " ").trimmingCharacters(in: CharacterSet(charactersIn: " ,-"))
        return (dataTesto, luogo)
    }

    private static let schemaData = #"\b\d{1,2}[./\- ]\d{1,2}[./\- ]\d{4}\b"#

    // MARK: - Zona a lettura ottica

    /// La zona a lettura ottica: TD1 (tre righe da 30) o TD3 (due righe da 44). Nil se non c'è.
    static func zonaOttica(_ righe: [String]) -> LetturaCartaIdentita? {
        let pulite = righe.map { $0.uppercased().filter { !$0.isWhitespace } }
        func zona(_ s: String) -> Bool {
            s.contains("<") && s.allSatisfy { ($0.isASCII && ($0.isUppercase || $0.isNumber)) || $0 == "<" }
        }
        for i in pulite.indices where i + 2 < pulite.count {
            let a = pulite[i], b = pulite[i + 1], c = pulite[i + 2]
            if a.count == 30, b.count == 30, c.count == 30, zona(a), zona(b), zona(c) { return td1(a, b, c) }
        }
        for i in pulite.indices where i + 1 < pulite.count {
            let a = pulite[i], b = pulite[i + 1]
            if a.count == 44, b.count == 44, zona(a), zona(b) { return td3(a, b) }
        }
        return nil
    }

    /// Pesi 7-3-1; «<» vale 0, le cifre il loro valore, A = 10 … Z = 35.
    static func cifraDiControllo(_ s: String) -> Int {
        let pesi = [7, 3, 1]
        var somma = 0
        for (i, c) in s.enumerated() {
            let v: Int
            if c == "<" { v = 0 }
            else if let n = c.wholeNumberValue, c.isASCII { v = n }
            else if let a = c.asciiValue, a >= 65, a <= 90 { v = Int(a) - 55 }
            else { v = 0 }
            somma += v * pesi[i % 3]
        }
        return somma % 10
    }

    private static func pezzo(_ s: String, _ da: Int, _ lunghezza: Int) -> String {
        let a = Array(s)
        guard da >= 0, da + lunghezza <= a.count else { return "" }
        return String(a[da..<(da + lunghezza)])
    }

    private static func torna(_ campo: String, _ cifra: String) -> Bool {
        guard let n = Int(cifra) else { return false }
        return cifraDiControllo(campo) == n
    }

    private static func senzaRiempitivo(_ s: String) -> String {
        s.replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
    }

    /// AAMMGG → «gg.mm.aaaa» (per la nascita il secolo dal confronto con l'anno di oggi; per la scadenza sempre 2000).
    private static func dataZona(_ aammgg: String, nascita: Bool) -> String? {
        guard aammgg.count == 6, let aa = Int(pezzo(aammgg, 0, 2)), let mm = Int(pezzo(aammgg, 2, 2)), let gg = Int(pezzo(aammgg, 4, 2)),
              (1...12).contains(mm), (1...31).contains(gg) else { return nil }
        let annoOggi = Calendar(identifier: .gregorian).component(.year, from: Date()) % 100
        let anno = nascita ? (aa > annoOggi ? 1900 + aa : 2000 + aa) : 2000 + aa
        return String(format: "%02d.%02d.%04d", gg, mm, anno)
    }

    private static func tipoZona(_ codice: String) -> TipoDocumentoIdentita? {
        if codice.hasPrefix("P") { return .passaporto }
        if codice.hasPrefix("C") || codice.hasPrefix("I") { return .cartaIdentita }
        return nil
    }

    private static func nomiZona(_ s: String, in l: inout LetturaCartaIdentita) {
        let parti = s.components(separatedBy: "<<")
        let cognome = senzaRiempitivo(parti.first ?? "")
        let nome = senzaRiempitivo(parti.dropFirst().joined(separator: " "))
        if !cognome.isEmpty { l[.cognome] = CampoLetto(valore: cognome, fonte: .zonaOttica) }
        if !nome.isEmpty { l[.nome] = CampoLetto(valore: nome, fonte: .zonaOttica) }
    }

    private static func campiZona(numero: String, cifraNumero: String, nascita: String, cifraNascita: String, sesso: String,
                                  scadenza: String, cifraScadenza: String, cittadinanza: String, in l: inout LetturaCartaIdentita) {
        let n = senzaRiempitivo(numero)
        if !n.isEmpty { l[.numero] = CampoLetto(valore: n, fonte: .zonaOttica, daGuardare: !torna(numero, cifraNumero)) }
        if let d = dataZona(nascita, nascita: true) {
            l[.dataNascita] = CampoLetto(valore: d, fonte: .zonaOttica, daGuardare: !torna(nascita, cifraNascita))
        }
        if sesso == "F" || sesso == "M" { l[.sesso] = CampoLetto(valore: sesso, fonte: .zonaOttica) }
        if let d = dataZona(scadenza, nascita: false) {
            l[.scadenza] = CampoLetto(valore: d, fonte: .zonaOttica, daGuardare: !torna(scadenza, cifraScadenza))
        }
        let citt = senzaRiempitivo(cittadinanza)
        if !citt.isEmpty { l[.cittadinanza] = CampoLetto(valore: citt, fonte: .zonaOttica) }
    }

    private static func td1(_ a: String, _ b: String, _ c: String) -> LetturaCartaIdentita {
        var l = LetturaCartaIdentita(tipo: tipoZona(pezzo(a, 0, 2)), conZonaOttica: true)
        campiZona(numero: pezzo(a, 5, 9), cifraNumero: pezzo(a, 14, 1), nascita: pezzo(b, 0, 6), cifraNascita: pezzo(b, 6, 1),
                  sesso: pezzo(b, 7, 1), scadenza: pezzo(b, 8, 6), cifraScadenza: pezzo(b, 14, 1), cittadinanza: pezzo(b, 15, 3), in: &l)
        nomiZona(c, in: &l)
        return l
    }

    private static func td3(_ a: String, _ b: String) -> LetturaCartaIdentita {
        var l = LetturaCartaIdentita(tipo: tipoZona(pezzo(a, 0, 2)), conZonaOttica: true)
        campiZona(numero: pezzo(b, 0, 9), cifraNumero: pezzo(b, 9, 1), nascita: pezzo(b, 13, 6), cifraNascita: pezzo(b, 19, 1),
                  sesso: pezzo(b, 20, 1), scadenza: pezzo(b, 21, 6), cifraScadenza: pezzo(b, 27, 1), cittadinanza: pezzo(b, 10, 3), in: &l)
        nomiZona(pezzo(a, 5, 39), in: &l)
        return l
    }

    // MARK: - Testi

    /// «03.04.1990», «03 04 1990», «03/04/1990», «3-4-1990» → il giorno a mezzanotte (calendario gregoriano, fuso del Mac).
    static func data(_ s: String) -> Date? {
        guard let r = s.range(of: schemaData, options: .regularExpression) else { return nil }
        let numeri = s[r].split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard numeri.count == 3, (1...31).contains(numeri[0]), (1...12).contains(numeri[1]), (1900...2100).contains(numeri[2]) else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let comp = DateComponents(year: numeri[2], month: numeri[1], day: numeri[0])
        guard let d = cal.date(from: comp), cal.component(.day, from: d) == numeri[0] else { return nil }
        return d
    }

    /// «MARCHI» → «Marchi», «DE ANGELIS» → «De Angelis», «D'ANGELO» → «D'Angelo».
    static func maiuscoleIniziali(_ s: String) -> String {
        var risultato = ""
        var inizio = true
        for c in s.lowercased() {
            if c.isLetter {
                if inizio { risultato += c.uppercased() } else { risultato.append(c) }
                inizio = false
            } else {
                risultato.append(c)
                inizio = c == " " || c == "'" || c == "’" || c == "-"
            }
        }
        return risultato
    }

    /// «BOLOGNA (BO)» → «Bologna (BO)»: la sigla della provincia resta maiuscola.
    static func luogo(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespaces)
        guard let aperta = t.firstIndex(of: "(") else { return maiuscoleIniziali(t) }
        let citta = maiuscoleIniziali(String(t[..<aperta]).trimmingCharacters(in: .whitespaces))
        let provincia = String(t[aperta...]).uppercased()
        return citta.isEmpty ? provincia : citta + " " + provincia
    }

    /// «Bologna (BO)» → «Bologna», per la riga «3 aprile 1990, a Bologna».
    static func luogoBreve(_ s: String) -> String {
        let l = luogo(s)
        guard let aperta = l.firstIndex(of: "(") else { return l }
        return String(l[..<aperta]).trimmingCharacters(in: .whitespaces)
    }

    static func etaAnni(_ nascita: Date, oggi: Date, calendario: Calendar = Calendar(identifier: .gregorian)) -> Int {
        max(0, calendario.dateComponents([.year], from: calendario.startOfDay(for: nascita), to: calendario.startOfDay(for: oggi)).year ?? 0)
    }

    /// Il nome del tipo in minuscolo, come nella riga del template («carta d'identità»).
    static func nomeTipo(_ t: TipoDocumentoIdentita?) -> String {
        guard let t else { return "documento" }
        let n = t.nome
        return n.prefix(1).lowercased() + n.dropFirst()
    }

    /// I campi essenziali che mancano («Mancano 2 dati»).
    static func mancanti(_ l: LetturaCartaIdentita) -> [CampoCarta] {
        CampoCarta.essenziali.filter { l[$0] == nil }
    }

    /// «Anagrafica completa», «Manca 1 dato», «Mancano 2 dati».
    static func sottotitolo(_ l: LetturaCartaIdentita) -> String {
        let n = mancanti(l).count
        if n == 0 { return "Anagrafica completa" }
        return n == 1 ? "Manca 1 dato" : "Mancano \(n) dati"
    }

    // MARK: - Righe della scheda

    /// Le righe della scheda, nell'ordine del template (cinque), con lo stato di ognuna. Le correzioni scritte a mano
    /// valgono sopra la lettura.
    static func righe(_ lettura: LetturaCartaIdentita, correzioni: [CampoCarta: String], oggi: Date,
                      calendario: Calendar = Calendar(identifier: .gregorian)) -> [RigaNuovoCliente] {
        let l = lettura.conCorrezioni(correzioni)
        func riquadri(_ campi: [CampoCarta]) -> [RiquadroPagina] { campi.compactMap { l[$0]?.riquadro } }
        func stato(_ campi: [CampoCarta]) -> RigaNuovoCliente.Stato {
            let presenti = campi.compactMap { l[$0] }
            if presenti.isEmpty { return .mancante }
            if presenti.contains(where: \.daGuardare) { return .daGuardare }
            return presenti.contains(where: { $0.fonte == .aMano }) ? .scrittaDaTe : .letta
        }
        let giorno = Formati.dataEstesa
        var righe: [RigaNuovoCliente] = []

        // 1. Nome e cognome
        let campiNome: [CampoCarta] = [.nome, .cognome]
        righe.append(RigaNuovoCliente(id: "nome", etichetta: "Nome e cognome", valore: l.nomeCompleto ?? nonLetto,
                                      stato: stato(campiNome), riquadri: riquadri(campiNome), campi: campiNome))

        // 2. Nata il / Nato il (dal sesso della carta o, per la sola etichetta, dal codice fiscale)
        let sessoEtichetta = l.sessoLetto ?? l.codiceFiscale.flatMap { CodiceFiscale.sesso($0) }
        let etichettaNascita = sessoEtichetta == .femmina ? "Nata il" : (sessoEtichetta == .maschio ? "Nato il" : "Data di nascita")
        var valoreNascita = nonLetto
        if let d = l.dataNascita {
            valoreNascita = giorno.string(from: d)
            if let luogo = l.luogoNascita { valoreNascita += ", a " + luogoBreve(luogo) }
        }
        let statoNascita: RigaNuovoCliente.Stato = l.dataNascita == nil ? .mancante : stato([.dataNascita, .luogoNascita])
        righe.append(RigaNuovoCliente(id: "nascita", etichetta: etichettaNascita, valore: valoreNascita, stato: statoNascita,
                                      riquadri: riquadri([.dataNascita, .luogoNascita]), campi: [.dataNascita, .luogoNascita]))

        // 3. Codice fiscale, ricontrollato con i dati (anche quelli scritti a mano)
        if let cf = l.codiceFiscale {
            let coerenza = CodiceFiscale.coerenza(cf, cognome: l[.cognome]?.valore ?? "", nome: l[.nome]?.valore ?? "",
                                                  nascita: l.dataNascita, sesso: l.sessoLetto, calendario: calendario)
            let s: RigaNuovoCliente.Stato = coerenza.daGuardare ? .daGuardare : stato([.codiceFiscale])
            righe.append(RigaNuovoCliente(id: "cf", etichetta: "Codice fiscale", valore: "\(cf) · \(coerenza.testo)", stato: s,
                                          riquadri: riquadri([.codiceFiscale]), campi: [.codiceFiscale]))
        } else {
            righe.append(RigaNuovoCliente(id: "cf", etichetta: "Codice fiscale", valore: nonLetto, stato: .mancante,
                                          riquadri: [], campi: [.codiceFiscale]))
        }

        // 4. Documento
        let campiDocumento: [CampoCarta] = [.numero, .scadenza]
        if let scade = l.scadenza {
            let tipo = nomeTipo(l.tipo)
            if calendario.startOfDay(for: scade) < calendario.startOfDay(for: oggi) {
                righe.append(RigaNuovoCliente(id: "documento", etichetta: "Documento", valore: "\(tipo) · scaduta il \(giorno.string(from: scade))",
                                              stato: .daGuardare, riquadri: riquadri(campiDocumento), campi: campiDocumento, nota: notaScaduto))
            } else {
                let anno = calendario.component(.year, from: scade)
                righe.append(RigaNuovoCliente(id: "documento", etichetta: "Documento", valore: "\(tipo) · scade nel \(anno)",
                                              stato: stato([.scadenza]), riquadri: riquadri(campiDocumento), campi: campiDocumento))
            }
        } else {
            righe.append(RigaNuovoCliente(id: "documento", etichetta: "Documento", valore: nonLetto, stato: .mancante,
                                          riquadri: riquadri(campiDocumento), campi: campiDocumento))
        }

        // 5. Età (dalla data di nascita)
        if let d = l.dataNascita {
            let anni = etaAnni(d, oggi: oggi, calendario: calendario)
            righe.append(RigaNuovoCliente(id: "eta", etichetta: "Età", valore: anni == 1 ? "1 anno" : "\(anni) anni",
                                          stato: stato([.dataNascita]), riquadri: riquadri([.dataNascita]), campi: [.dataNascita]))
        } else {
            righe.append(RigaNuovoCliente(id: "eta", etichetta: "Età", valore: nonLetto, stato: .mancante, riquadri: [], campi: [.dataNascita]))
        }
        return righe
    }

    // MARK: - Doppioni

    /// Doppione: stesso codice fiscale; o stesso nome normalizzato (anche con cognome e nome invertiti) e stessa data di
    /// nascita. Il solo nome non basta.
    static func clienteGiaPresente(_ l: LetturaCartaIdentita, clienti: [Cliente],
                                   calendario: Calendar = Calendar(identifier: .gregorian)) -> Cliente? {
        if let cf = l.codiceFiscale, let c = clienti.first(where: { !$0.codiceFiscale.isEmpty && CodiceFiscale.pulito($0.codiceFiscale) == cf }) {
            return c
        }
        guard let nome = l.nomeCompleto, let nascita = l.dataNascita else { return nil }
        let chiave = ImportaPosizioni.piega(nome)
        guard !chiave.isEmpty else { return nil }
        return clienti.first { c in
            guard let d = c.dataNascita, ImportaPosizioni.piega(c.nome) == chiave else { return false }
            let a = calendario.dateComponents([.year, .month, .day], from: d)
            let b = calendario.dateComponents([.year, .month, .day], from: nascita)
            return a.year == b.year && a.month == b.month && a.day == b.day
        }
    }
}
