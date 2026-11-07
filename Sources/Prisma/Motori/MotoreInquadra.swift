import Foundation

// Inquadra e capisci (Orizzonte, giro 5; specifica §9): dal testo letto con la fotocamera (righe con il loro
// riquadro sulla pagina, `LetturaDocumenti.riconosciConRiquadri`) i dati della posizione: contraente, premio con la
// frequenza, capitale, decorrenza, tipo e compagnia. Ogni campo porta l'intervallo di testo da cui viene e il
// riquadro delle sue righe, per illuminarlo sul foglio. Le regole sono quelle di `EstrattoreDocumento`: niente di
// nuovo da imparare, niente inventato. Nessun dato entra nel dossier senza conferma (`documento` dà campi da confermare).

/// Un riquadro sulla pagina in coordinate normalizzate 0…1, origine in alto a sinistra (Vision lo dà in basso a
/// sinistra: `LetturaDocumenti` lo gira).
struct RiquadroPagina: Codable, Hashable {
    var x: Double
    var y: Double
    var larghezza: Double
    var altezza: Double

    init(x: Double, y: Double, larghezza: Double, altezza: Double) {
        func limita(_ v: Double) -> Double { v.isFinite ? min(1, max(0, v)) : 0 }
        self.x = limita(x)
        self.y = limita(y)
        self.larghezza = min(1 - self.x, limita(larghezza))
        self.altezza = min(1 - self.y, limita(altezza))
    }

    /// Il riquadro che contiene tutti e due.
    func unito(_ o: RiquadroPagina) -> RiquadroPagina {
        let x0 = min(x, o.x), y0 = min(y, o.y)
        let x1 = max(x + larghezza, o.x + o.larghezza), y1 = max(y + altezza, o.y + o.altezza)
        return RiquadroPagina(x: x0, y: y0, larghezza: x1 - x0, altezza: y1 - y0)
    }

    private enum CodingKeys: String, CodingKey {
        case x, y, larghezza, altezza
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let x = try c.decode(Double.self, forKey: .x)
        let y = try c.decode(Double.self, forKey: .y)
        let l = try c.decode(Double.self, forKey: .larghezza)
        let a = try c.decode(Double.self, forKey: .altezza)
        self.init(x: x, y: y, larghezza: l, altezza: a)
    }
}

/// Una riga di testo letta sulla pagina, con il suo riquadro (nil per il testo dei PDF o scritto a mano).
struct RigaLetta: Codable, Hashable {
    var testo: String
    var riquadro: RiquadroPagina?

    init(testo: String, riquadro: RiquadroPagina? = nil) {
        self.testo = testo
        self.riquadro = riquadro
    }
}

/// Un campo trovato nel testo inquadrato: il valore, l'intervallo (in caratteri del testo unito delle righe,
/// `MotoreInquadra.testo`), le righe toccate e il riquadro da illuminare.
struct CampoInquadrato: Codable, Hashable, Identifiable {
    var campo: CampoDocumento
    var valore: String
    var intervallo: IntervalloTesto
    var righe: [Int]
    var riquadro: RiquadroPagina?

    var id: String { campo.rawValue }

    init(campo: CampoDocumento, valore: String, intervallo: IntervalloTesto, righe: [Int], riquadro: RiquadroPagina?) {
        self.campo = campo
        self.valore = valore
        self.intervallo = intervallo
        self.righe = righe
        self.riquadro = riquadro
    }
}

/// I dati della posizione letti dal foglio.
struct DatiInquadrati: Equatable {
    /// Il testo unito delle righe (a capo tra una riga e l'altra): gli intervalli si contano qui.
    var testo: String
    /// Contraente · Premio · Capitale assicurato · Decorrenza · Tipo · Compagnia, quelli trovati, in quest'ordine.
    var campi: [CampoInquadrato]
    /// I campi per il documento (da confermare), con la riga da cui vengono.
    var estratti: [CampoEstratto]
    /// La frequenza scritta sulla riga del premio (nil = non scritta).
    var frequenza: Frequenza?
    var tipoDocumento: Documento.Tipo

    func campo(_ c: CampoDocumento) -> CampoInquadrato? { campi.first { $0.campo == c } }

    var contraente: String? { campo(.contraente)?.valore }
    var premio: Double? { EstrattoreDocumento.numero(campo(.premio)?.valore) }
    var capitale: Double? { EstrattoreDocumento.numero(campo(.capitaleAssicurato)?.valore) }
    var decorrenza: Date? { EstrattoreDocumento.data(campo(.decorrenza)?.valore) }
    var tipo: String? { campo(.tipologia)?.valore }
    var compagnia: String? { campo(.emittente)?.valore }

    /// Il premio dell'anno con la frequenza letta (nil se manca il premio o la frequenza, o se è un premio unico).
    var premioAnnuo: Double? {
        guard let p = premio, let f = frequenza, f != .unica else { return nil }
        return p * Double(f.volteAllAnno)
    }
}

enum MotoreInquadra {
    /// I campi della posizione, nell'ordine della scheda.
    static let campiPosizione: [CampoDocumento] = [.contraente, .premio, .capitaleAssicurato, .decorrenza, .tipologia, .emittente]

    /// Le coperture riconosciute nel testo quando il foglio non ha la riga «Tipo:» (il nome com'è scritto).
    static let tipiNoti = #"\b(vita intera|temporanea caso morte|temporanea|caso morte|tcm|long term care|ltc|infortuni|fondo pensione|piano individuale pensionistico|pip|unit linked|multiramo|rivalutabile|mista)\b"#

    /// Il testo unito delle righe: una riga per riga letta (gli a capo dentro una riga diventano spazi).
    static func testo(_ righe: [RigaLetta]) -> String {
        righe.map { pulisci($0.testo) }.joined(separator: "\n")
    }

    private static func pulisci(_ s: String) -> String {
        s.replacingOccurrences(of: "\r\n", with: " ").replacingOccurrences(of: "\r", with: " ").replacingOccurrences(of: "\n", with: " ")
    }

    /// Dal testo semplice (un PDF, una prova): righe senza riquadro.
    static func leggi(testo: String) -> DatiInquadrati {
        leggi(testo.components(separatedBy: "\n").map { RigaLetta(testo: $0) })
    }

    /// I dati della posizione dalle righe lette.
    static func leggi(_ righe: [RigaLetta]) -> DatiInquadrati {
        let t = testo(righe)
        // Le stesse sostituzioni di `EstrattoreDocumento.conRegole`, con lo stesso numero di caratteri
        let piatto = t.replacingOccurrences(of: "\u{2212}", with: "-").replacingOccurrences(of: "\n", with: " ")
        var inizi: [Int] = []
        var posizione = 0
        for r in righe {
            inizi.append(posizione)
            posizione += pulisci(r.testo).count + 1
        }
        var estratti = EstrattoreDocumento.conRegole([t])
        var campi: [CampoInquadrato] = []

        func righeToccate(_ x: IntervalloTesto) -> [Int] {
            righe.indices.filter { i in
                let a = inizi[i], b = inizi[i] + pulisci(righe[i].testo).count
                return x.inizio < max(b, a + 1) && x.fine > a
            }
        }
        func riquadro(_ indici: [Int]) -> RiquadroPagina? {
            indici.compactMap { righe[$0].riquadro }.reduce(Optional<RiquadroPagina>.none) { u, r in u.map { $0.unito(r) } ?? r }
        }

        for chiave in campiPosizione {
            guard let e = estratti.first(where: { $0.chiave == chiave }), let x = intervallo(di: e, in: piatto) else { continue }
            let intervalloCampo = chiave == .premio ? conFrequenza(x, in: t) : x
            let indici = righeToccate(intervalloCampo)
            campi.append(CampoInquadrato(campo: chiave, valore: e.valore, intervallo: intervalloCampo, righe: indici, riquadro: riquadro(indici)))
        }
        // Il tipo di copertura scritto nel testo, se manca la riga «Tipo:»
        if !campi.contains(where: { $0.campo == .tipologia }), let trovato = DateItaliane.cerca(tipiNoti, piatto),
           let x = IntervalloTesto.da(trovato.0, in: piatto), let parole = x.testo(in: t) {
            let valore = maiuscola(parole)
            let indici = righeToccate(x)
            let campo = CampoInquadrato(campo: .tipologia, valore: valore, intervallo: x, righe: indici, riquadro: riquadro(indici))
            let ordine = campiPosizione.firstIndex(of: .tipologia) ?? campi.count
            let dove = campi.firstIndex { (campiPosizione.firstIndex(of: $0.campo) ?? 0) > ordine } ?? campi.count
            campi.insert(campo, at: dove)
            let riga = indici.first.map { pulisci(righe[$0].testo) } ?? parole
            estratti.append(CampoEstratto(chiave: .tipologia, valore: valore, pagina: 1, estratto: String(riga.prefix(160))))
        }
        // La frequenza: sulla riga intera del premio (la cifra e quello che segue)
        var frequenza: Frequenza?
        if let p = campi.first(where: { $0.campo == .premio }) {
            let riga = p.righe.map { pulisci(righe[$0].testo) }.joined(separator: " ")
            frequenza = MotoreConfrontoDossier.frequenzaPremio(riga.isEmpty ? (estratti.first { $0.chiave == .premio }?.estratto ?? "") : riga)
        }
        return DatiInquadrati(testo: t, campi: campi, estratti: estratti, frequenza: frequenza,
                              tipoDocumento: EstrattoreDocumento.tipoProbabile([t]))
    }

    /// Dove sta il valore del campo nel testo: dentro la riga da cui viene (l'estratto), altrimenti la prima volta
    /// che compare; nil se non si trova.
    static func intervallo(di e: CampoEstratto, in piatto: String) -> IntervalloTesto? {
        let valore = e.valore.trimmingCharacters(in: .whitespaces)
        guard !valore.isEmpty else { return nil }
        // L'estratto del premio ha anche la coda della riga: si cerca la parte con la cifra
        let candidati = [e.estratto, String(e.estratto.prefix(160))].filter { !$0.isEmpty }
        for estratto in candidati {
            if let zona = piatto.range(of: estratto, options: [.caseInsensitive]) ?? piatto.range(of: estratto.trimmingCharacters(in: .whitespaces), options: [.caseInsensitive]),
               let r = piatto.range(of: valore, options: [.caseInsensitive], range: zona) {
                return IntervalloTesto(piatto.distance(from: piatto.startIndex, to: r.lowerBound),
                                       piatto.distance(from: piatto.startIndex, to: r.upperBound))
            }
        }
        guard let r = piatto.range(of: valore, options: [.caseInsensitive]) else { return nil }
        return IntervalloTesto(piatto.distance(from: piatto.startIndex, to: r.lowerBound), piatto.distance(from: piatto.startIndex, to: r.upperBound))
    }

    /// Il premio con la valuta e la frequenza che lo seguono sulla stessa riga («90,00 € al mese»).
    static let codaFrequenza = #"^[ \t]*(?:€|eur(?:o)?\b)?[ \t]*(?:(?:di premio |circa )?(?:al mese|ogni mese|a mese|al trimestre|al semestre|all['’] ?anno|l['’] ?anno|ogni anno|mensil\w*|trimestral\w*|semestral\w*|annu\w*)\b)?"#

    /// (sul testo con gli a capo: la coda si ferma alla fine della riga)
    private static func conFrequenza(_ x: IntervalloTesto, in t: String) -> IntervalloTesto {
        guard x.fine <= t.count else { return x }
        let coda = String(t[t.index(t.startIndex, offsetBy: x.fine)...].prefix(60))
        guard let trovato = DateItaliane.cerca(codaFrequenza, coda), trovato.0.length > 0,
              let y = IntervalloTesto.da(trovato.0, in: coda), let parole = y.testo(in: coda) else { return x }
        let senzaSpazi = parole.replacingOccurrences(of: #"\s+$"#, with: "", options: .regularExpression)
        return IntervalloTesto(x.inizio, x.fine + senzaSpazi.count)
    }

    private static func maiuscola(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespaces)
        if ["tcm", "ltc", "pip"].contains(t.lowercased()) { return t.uppercased() }
        return t.prefix(1).uppercased() + t.dropFirst()
    }

    /// Il documento del cliente con i dati letti, tutti da confermare (non entra niente nel dossier senza conferma).
    static func documento(_ d: DatiInquadrati, clienteId: String, titolo: String, quando: Date = Date()) -> Documento {
        var doc = Documento(clienteId: clienteId, titolo: titolo, tipo: d.tipoDocumento == .altro ? .polizza : d.tipoDocumento)
        doc.importatoIl = quando
        doc.lettura = .letto
        doc.pagine = 1
        doc.pagineOCR = 1
        doc.campi = d.estratti.map {
            var c = $0
            c.confermato = false
            return c
        }
        return doc
    }
}
