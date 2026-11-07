import Foundation

// Inquadra e capisci (Orizzonte, giro 5; specifica §9.1.5, §9.5.3): come la scheda «Prisma sul Mac» riscrive i dati
// letti dal foglio, nella forma di Prisma (premio «90 € al mese», decorrenza «marzo 2021», riga «Tipo» che unisce
// tipologia e provenienza), il cliente probabile dal contraente, canale e area della posizione e il confronto con una
// temporanea caso morte. Solo formati e conti sui dati letti e sui motori di sempre (tariffa delle coperture in
// archivio, fabbisogno della famiglia): niente cifre inventate. Le fondamenta (lettura, campi, riquadri) stanno in
// MotoreInquadra.swift.

/// Una riga della scheda «Prisma sul Mac»: etichetta e valore nella forma di Prisma (nil = il dato non c'è sul foglio,
/// la riga resta grigia senza ✓), con i campi del foglio da cui viene (si illuminano insieme).
struct RigaInquadra: Equatable, Identifiable {
    let id: String
    let etichetta: String
    let valore: String?
    let campi: [CampoDocumento]

    var trovata: Bool { valore != nil }
}

/// Il confronto della polizza letta con una temporanea caso morte (tabella dopo «Confronta», §9.1.7).
struct ConfrontoTemporanea: Equatable {
    struct Colonna: Equatable {
        /// Quanto si spende l'anno (nil = non si sa: manca il premio o la tariffa).
        let spesaAnnua: Double?
        let capitaleCasoMorte: Double?
        let riscatto: Riscatto
    }

    enum Riscatto: Equatable {
        case cresce, no, nonNoto
    }

    let polizza: Colonna
    let temporanea: Colonna
    /// Da dove viene la tariffa della temporanea (nil = nessuna tariffa).
    let fonteTariffa: MotoreSimulatoriAnalisi.TariffaCasoMorte.Fonte?
    /// Il capitale della temporanea è il fabbisogno della famiglia (false = lo stesso della polizza).
    let dalFabbisogno: Bool
}

extension MotoreInquadra {
    /// L'ordine fisso della scheda per le polizze: Contraente · Premio · Capitale assicurato · Decorrenza · Tipo.
    static let righeScheda: [(id: String, etichetta: String, campi: [CampoDocumento])] = [
        ("contraente", "Contraente", [.contraente]),
        ("premio", "Premio", [.premio]),
        ("capitale", "Capitale assicurato", [.capitaleAssicurato]),
        ("decorrenza", "Decorrenza", [.decorrenza]),
        ("tipo", "Tipo", [.tipologia, .emittente]),
    ]

    /// Sotto questo numero di righe trovate la lettura è «solo una parte».
    static let righeMinime = 4

    /// Le righe della scheda, nell'ordine fisso, con i valori nella forma di Prisma.
    static func righe(_ d: DatiInquadrati, canale: Canale) -> [RigaInquadra] {
        righeScheda.map { r -> RigaInquadra in
            let valore: String?
            switch r.id {
            case "contraente": valore = d.contraente
            case "premio": valore = premio(d)
            case "capitale": valore = d.capitale.map { importo($0) }
            case "decorrenza": valore = d.decorrenza.map { Formati.meseAnno.string(from: $0) }
            default: valore = tipo(d, canale: canale)
            }
            return RigaInquadra(id: r.id, etichetta: r.etichetta, valore: valore, campi: r.campi)
        }
    }

    /// «90 € al mese», «1.250,50 € l'anno», «50.000 € premio unico»; senza frequenza scritta solo la cifra.
    static func premio(_ d: DatiInquadrati) -> String? {
        guard let p = d.premio else { return nil }
        let cifra = importo(p)
        guard let f = d.frequenza else { return cifra }
        switch f {
        case .mensile: return cifra + " al mese"
        case .trimestrale: return cifra + " al trimestre"
        case .semestrale: return cifra + " al semestre"
        case .annuale: return cifra + " l’anno"
        case .unica: return cifra + " premio unico"
        }
    }

    /// Euro senza decimali se la cifra è intera, con i centesimi se no.
    static func importo(_ v: Double) -> String {
        abs(v - v.rounded()) < 0.005 ? Formati.euro(v) : Formati.euroDecimali(v)
    }

    /// La riga «Tipo»: tipologia (o «Polizza») · provenienza: «Alleanza» con il canale Alleanza, altrimenti la compagnia
    /// letta, «altra compagnia» se non c'è. nil se il foglio non dice né il tipo né la compagnia.
    static func tipo(_ d: DatiInquadrati, canale: Canale) -> String? {
        guard d.tipo != nil || d.compagnia != nil || canale == .alleanza else { return nil }
        let provenienza = canale == .alleanza ? "Alleanza" : (d.compagnia ?? "altra compagnia")
        return (d.tipo ?? "Polizza") + " · " + provenienza
    }

    /// Il titolo della scheda a lettura finita, secondo il tipo di documento.
    static func titoloRiconosciuto(_ t: Documento.Tipo) -> String {
        switch t {
        case .kid: return "KID riconosciuto"
        case .estrattoConto: return "Estratto conto riconosciuto"
        default: return "Polizza riconosciuta"
        }
    }

    /// Il documento di prova per canale e area (i campi letti, non ancora confermati).
    static func documentoProvvisorio(_ d: DatiInquadrati, clienteId: String) -> Documento {
        documento(d, clienteId: clienteId, titolo: titoloDocumento(d))
    }

    /// Il titolo del documento nel dossier: «Polizza Vita intera · Esempio Vita S.p.A.» o «Polizza inquadrata».
    static func titoloDocumento(_ d: DatiInquadrati) -> String {
        let parti = [d.tipo, d.compagnia].compactMap { $0 }
        return parti.isEmpty ? "Polizza inquadrata" : "Polizza " + parti.joined(separator: " · ")
    }

    /// Canale e area proposti per la posizione (le regole di Documenti: «alleanza» nel testo → Alleanza, altrimenti
    /// indipendente; con il capitale assicurato → protezione).
    static func canaleEArea(_ d: DatiInquadrati) -> (canale: Canale, area: AreaPosizione) {
        MotoreDocumenti.canaleEArea(documentoProvvisorio(d, clienteId: ""), posizione: nil, prodotto: nil)
    }

    /// Il cliente il cui nome è il contraente (senza maiuscole, accenti e punteggiatura); nil se nessuno o più d'uno.
    static func clienteProbabile(contraente: String?, clienti: [Cliente]) -> Cliente? {
        guard let c = contraente else { return nil }
        let cercato = MotoreConfrontoDossier.normaleTesto(c)
        guard !cercato.isEmpty else { return nil }
        let trovati = clienti.filter { MotoreConfrontoDossier.normaleTesto($0.nome) == cercato }
        return trovati.count == 1 ? trovati.first : nil
    }

    // MARK: - Confronto con una temporanea

    /// Le coperture caso morte che sono temporanee (la tipologia lo dice): le vita intera costano molto di più per
    /// mille e falserebbero la tariffa.
    static func temporanee(_ posizioni: [Posizione]) -> [Posizione] {
        posizioni.filter { (p: Posizione) -> Bool in
            let t = MotoreConfrontoDossier.normaleTesto(p.tipologia + " " + p.nome)
            return t.contains("temporanea") || t.split(separator: " ").contains("tcm")
        }
    }

    /// Il riscatto dalla tipologia: vita intera, rivalutabili e miste crescono; le temporanee no.
    static func riscatto(_ tipo: String?) -> ConfrontoTemporanea.Riscatto {
        let t = MotoreConfrontoDossier.normaleTesto(tipo ?? "")
        if t.contains("temporanea") || t.split(separator: " ").contains("tcm") { return .no }
        if t.contains("vita intera") || t.contains("rivalutabil") || t.contains("mista") { return .cresce }
        return .nonNoto
    }

    /// La polizza letta contro una temporanea: capitale della temporanea = fabbisogno della famiglia arrotondato a
    /// 10.000 € (se c'è), altrimenti lo stesso capitale della polizza; spesa = tariffa × capitale / 1.000, arrotondata a
    /// 10 €. Senza tariffa la spesa resta nil («—»).
    static func confronta(_ d: DatiInquadrati, fabbisogno: Double?, tariffa: MotoreSimulatoriAnalisi.TariffaCasoMorte?) -> ConfrontoTemporanea {
        let spesaPolizza = d.premioAnnuo ?? (d.frequenza == nil ? d.premio : nil)
        let polizza = ConfrontoTemporanea.Colonna(spesaAnnua: spesaPolizza, capitaleCasoMorte: d.capitale, riscatto: riscatto(d.tipo))
        let daFabbisogno = (fabbisogno ?? 0) > 0
        let capitale: Double? = daFabbisogno ? ((fabbisogno ?? 0) / 10_000).rounded() * 10_000 : d.capitale
        let spesa: Double? = {
            guard let t = tariffa, t.perMille > 0, let c = capitale, c > 0 else { return nil }
            return (t.perMille * c / 1_000 / 10).rounded() * 10
        }()
        let temporanea = ConfrontoTemporanea.Colonna(spesaAnnua: spesa, capitaleCasoMorte: capitale, riscatto: .no)
        return ConfrontoTemporanea(polizza: polizza, temporanea: temporanea, fonteTariffa: tariffa?.fonte, dalFabbisogno: daFabbisogno)
    }

    /// Le parole del riscatto nella tabella.
    static func testoRiscatto(_ r: ConfrontoTemporanea.Riscatto) -> String {
        switch r {
        case .cresce: return "sì, cresce nel tempo"
        case .no: return "no"
        case .nonNoto: return "da verificare"
        }
    }

    /// La nota sotto la tabella.
    static func notaConfronto(_ c: ConfrontoTemporanea) -> String {
        guard let fonte = c.fonteTariffa else {
            return "Manca una tariffa della temporanea: servono in archivio coperture temporanee caso morte con capitale e premio."
        }
        let capitale = c.dalFabbisogno ? "copre il fabbisogno della famiglia" : "a parità di capitale costa meno"
        let tariffa = fonte == .cliente ? "dalle temporanee del cliente" : "dalla media delle temporanee in archivio"
        return "La vita intera accumula anche un valore di riscatto; la temporanea \(capitale). Spesa \(tariffa): cifre indicative."
    }
}

// MARK: - Il foglio di prova

/// Il foglio di prova delle istantanee e della scena senza iPhone: una vita intera di una compagnia inventata
/// (DATI DI PROVA DICHIARATI, come in `ProvaCalcoliInquadra.foglio`: nessun dato vero), letta riga per riga con il
/// riquadro. Mai mischiato con i dati veri: vive solo nelle istantanee.
enum FoglioInquadraDiProva {
    static func righe(contraente: String = "Giulia Rossi") -> [RigaLetta] {
        [
            RigaLetta(testo: "COMPAGNIA ESEMPIO VITA", riquadro: RiquadroPagina(x: 0.10, y: 0.05, larghezza: 0.50, altezza: 0.04)),
            RigaLetta(testo: "Polizza n. VI-2021-004512", riquadro: RiquadroPagina(x: 0.10, y: 0.12, larghezza: 0.40, altezza: 0.03)),
            RigaLetta(testo: "Contraente: \(contraente)", riquadro: RiquadroPagina(x: 0.10, y: 0.18, larghezza: 0.45, altezza: 0.03)),
            RigaLetta(testo: "Premio: 90,00 € al mese", riquadro: RiquadroPagina(x: 0.10, y: 0.24, larghezza: 0.42, altezza: 0.03)),
            RigaLetta(testo: "Capitale assicurato: € 50.000,00", riquadro: RiquadroPagina(x: 0.10, y: 0.30, larghezza: 0.55, altezza: 0.03)),
            RigaLetta(testo: "Decorrenza: 01/03/2021", riquadro: RiquadroPagina(x: 0.10, y: 0.36, larghezza: 0.35, altezza: 0.03)),
            RigaLetta(testo: "Tipo: Vita intera a premio ricorrente", riquadro: RiquadroPagina(x: 0.10, y: 0.42, larghezza: 0.60, altezza: 0.03)),
            RigaLetta(testo: "Compagnia: Esempio Vita S.p.A.", riquadro: RiquadroPagina(x: 0.10, y: 0.48, larghezza: 0.50, altezza: 0.03)),
        ]
    }

    /// Lo stesso foglio letto solo in parte (contraente e premio): la scena «pochi dati».
    static func parziale(contraente: String = "Giulia Rossi") -> [RigaLetta] {
        Array(righe(contraente: contraente).prefix(4))
    }
}
