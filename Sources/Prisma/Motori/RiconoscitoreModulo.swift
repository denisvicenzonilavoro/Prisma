import Foundation
import PDFKit

// Il riconoscimento dei campi di un modulo vuoto (Pratiche › Moduli, «Luce» giro 10, §7.2.5 punto 2). Tutto sul Mac,
// con PDFKit:
// (a) se il PDF ha campi compilabili (AcroForm) si prendono i widget con il loro nome e riquadro, e l'etichetta dal testo
//     subito sopra la casella (o dal nome del campo);
// (b) se è piatto si cercano le etichette nel testo della pagina, divise dove c'è uno spazio largo, e la casella si mette
//     subito sotto l'etichetta (da confermare);
// (c) le etichette che le regole non riconoscono le può proporre Vera (Vera/ModuliVera.swift), sempre da confermare.
// Le domande del questionario e dell'antiriciclaggio (titolare effettivo, PEP, origine dei fondi, scopo del rapporto,
// conoscenze, obiettivi, reddito…) diventano «risposta del cliente»: Prisma non le riempie mai (decisione 62).

/// Cosa le regole associano a un'etichetta.
enum AssociazioneModulo: Equatable {
    case dato(DatoModulo)
    case firma
    /// Una risposta del cliente (decisione 62).
    case risposta
}

/// L'esito del riconoscimento.
struct EsitoRiconoscimento {
    var campi: [ModelloModulo.Campo]
    var pagine: Int
    var versione: String?
    /// Nessuna pagina leggibile (PDF protetto o senza testo né campi).
    var illeggibile: Bool
    /// Il PDF ha campi compilabili.
    var acroForm: Bool
}

enum RiconoscitoreModulo {
    /// Le regole, nell'ordine: le risposte del cliente e le firme prima di tutto, poi le frasi più precise.
    static let regole: [(frasi: [String], esito: AssociazioneModulo)] = [
        (["titolare effettivo", "titolari effettivi", "politicamente esposta", "politicamente esposto", "pep",
          "origine dei fondi", "provenienza dei fondi", "origine del patrimonio", "scopo del rapporto", "natura del rapporto",
          "scopo e natura", "conoscenza ed esperienza", "conoscenze ed esperienze", "esperienza in materia",
          "obiettivi di investimento", "tolleranza al rischio", "propensione al rischio", "situazione finanziaria",
          "orizzonte temporale", "capacita di sostenere", "reddito", "patrimonio"], .risposta),
        (["firma"], .firma),
        (["luogo e data"], .dato(.luogoData)),
        (["luogo di nascita", "comune di nascita", "nato a", "nata a"], .dato(.luogoNascita)),
        (["data di nascita", "nato il", "nata il"], .dato(.dataNascita)),
        (["codice fiscale", "cod fiscale", "c f"], .dato(.codiceFiscale)),
        (["tipo di documento", "tipo documento"], .dato(.documentoTipo)),
        (["numero del documento", "numero documento", "n documento", "estremi del documento"], .dato(.documentoNumero)),
        (["rilasciato il", "data di rilascio", "rilascio"], .dato(.documentoRilascio)),
        (["scadenza del documento", "scadenza documento", "valido fino"], .dato(.documentoScadenza)),
        (["numero di contratto", "numero contratto", "numero di polizza", "polizza n", "contratto n"], .dato(.numeroContratto)),
        (["iban"], .dato(.iban)),
        (["cap"], .dato(.cap)),
        (["provincia", "prov"], .dato(.provincia)),
        (["comune", "citta", "localita"], .dato(.comune)),
        (["indirizzo", "residenza", "via"], .dato(.indirizzo)),
        (["telefono", "cellulare", "tel"], .dato(.telefono)),
        (["email", "e mail", "posta elettronica"], .dato(.email)),
        (["professione", "occupazione", "attivita lavorativa"], .dato(.professione)),
        (["stato civile"], .dato(.statoCivile)),
        (["beneficiari", "beneficiario"], .dato(.beneficiari)),
        (["premio", "importo del versamento", "versamento"], .dato(.premio)),
        (["frequenza", "periodicita", "rateazione"], .dato(.frequenza)),
        (["decorrenza", "data di effetto"], .dato(.decorrenza)),
        (["scadenza", "durata"], .dato(.scadenza)),
        (["capitale"], .dato(.capitale)),
        (["prodotto", "tariffa"], .dato(.prodotto)),
        (["consulente", "intermediario", "collocatore"], .dato(.consulente)),
        (["cognome"], .dato(.cognome)),
        (["nome"], .dato(.nome)),
    ]

    /// Le etichette che non si associano da sole (nome e cognome insieme non si spezzano: decisione del §7.2.5 punto 5).
    static let ambigue = ["nome e cognome", "cognome e nome", "nominativo"]

    /// Minuscolo, senza accenti, solo lettere e cifre separate da uno spazio.
    static func normalizza(_ s: String) -> String {
        let senza = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "it_IT"))
        let parti = senza.lowercased().map { $0.isLetter || $0.isNumber ? $0 : " " }
        return String(parti).split(separator: " ").joined(separator: " ")
    }

    /// L'associazione delle regole per un'etichetta (nil = non riconosciuta).
    static func associa(_ etichetta: String) -> AssociazioneModulo? {
        let n = " " + normalizza(etichetta) + " "
        guard n.count > 2 else { return nil }
        if ambigue.contains(where: { n.contains(" \($0) ") }) { return nil }
        for r in regole where r.frasi.contains(where: { n.contains(" \($0) ") }) { return r.esito }
        return nil
    }

    /// Un'etichetta ha la forma di un'etichetta: breve, senza punto finale.
    static func formaDiEtichetta(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return (2...48).contains(t.count) && !t.hasSuffix(".") && !t.hasSuffix(":") || (t.hasSuffix(":") && t.count <= 40)
    }

    // MARK: - Riconoscimento

    /// Riconosce i campi di un modulo vuoto. `tipo`: sui moduli con le risposte del cliente (questionario, adeguata
    /// verifica) solo anagrafica e documento restano associati, il resto diventa «risposta del cliente».
    static func riconosci(_ documento: PDFDocument, tipo: TipoModulo) -> EsitoRiconoscimento {
        guard !documento.isLocked else { return EsitoRiconoscimento(campi: [], pagine: 0, versione: nil, illeggibile: true, acroForm: false) }
        var campi: [ModelloModulo.Campo] = []
        var conTesto = false
        var versione: String?
        let n = documento.pageCount
        for i in 0..<n {
            autoreleasepool {
                guard let pagina = documento.page(at: i) else { return }
                let testo = pagina.string ?? ""
                if !testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { conTesto = true }
                if versione == nil { versione = PropostaBiblioteca.edizione(testo) }
                let widget = pagina.annotations.filter { $0.type == "Widget" && $0.widgetFieldType != .button || $0.isCasella }
                if widget.isEmpty {
                    campi += piatti(pagina, indice: i)
                } else {
                    campi += widget.map { campoAcroForm($0, pagina: pagina, indice: i) }
                }
            }
        }
        campi = campi.map { applicaTipo($0, tipo) }
        let illeggibile = n == 0 || (!conTesto && campi.isEmpty)
        let acro = campi.contains { $0.origine == .acroForm }
        return EsitoRiconoscimento(campi: campi, pagine: n, versione: versione, illeggibile: illeggibile, acroForm: acro)
    }

    /// Sui moduli con le risposte del cliente solo anagrafica e documento (decisione 62).
    static func applicaTipo(_ c: ModelloModulo.Campo, _ tipo: TipoModulo) -> ModelloModulo.Campo {
        guard tipo.risposteDelCliente, let d = c.dato, !d.anagrafico else { return c }
        var x = c
        x.dato = nil
        x.risposta = true
        return x
    }

    /// Un campo compilabile: nome, riquadro e l'etichetta letta sopra la casella (o il nome del campo).
    static func campoAcroForm(_ a: PDFAnnotation, pagina: PDFPage, indice: Int) -> ModelloModulo.Campo {
        let b = a.bounds
        let nome = a.fieldName ?? ""
        let sopra = pagina.selection(for: CGRect(x: b.minX, y: b.maxY, width: max(b.width, 40), height: 14))?.string?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let daNome = nome.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: ".", with: " ")
        let etichetta = sopra.isEmpty || sopra.count > 60 ? daNome : sopra
        let associazione = associa(etichetta) ?? associa(daNome)
        var c = ModelloModulo.Campo(pagina: indice, riquadro: b, nomeAcroForm: nome.isEmpty ? nil : nome,
                                    etichetta: etichetta.isEmpty ? "Campo senza nome" : etichetta, origine: .acroForm)
        if a.isCasella { c.tipo = .casella }
        if a.widgetFieldType == .signature { c.tipo = .firma }
        applica(associazione, a: &c)
        return c
    }

    private static func applica(_ associazione: AssociazioneModulo?, a c: inout ModelloModulo.Campo) {
        switch associazione {
        case .dato(let d)?:
            c.dato = d
            if c.tipo == .testo { c.tipo = d.tipoCampo }
        case .firma?:
            c.tipo = .firma
        case .risposta?:
            c.risposta = true
        case nil:
            break
        }
    }

    /// Un PDF piatto: le etichette riconosciute dalle regole, con la casella subito sotto (da confermare).
    static func piatti(_ pagina: PDFPage, indice: Int) -> [ModelloModulo.Campo] {
        var campi: [ModelloModulo.Campo] = []
        let pezzi = etichette(pagina)
        // Il margine destro: dove finisce il testo più a destra della pagina
        let margine = pezzi.map(\.1.maxX).max() ?? pagina.bounds(for: .mediaBox).maxX
        for (testo, b) in pezzi where formaDiEtichetta(testo) {
            guard let associazione = associa(testo) else { continue }
            let alta: CGFloat = associazione == .firma ? 44 : 24
            // La casella va dall'etichetta fino a quella accanto sulla stessa riga, o fino al margine
            let accanto = pezzi.filter { abs($0.1.midY - b.midY) < sogliaRiga && $0.1.minX > b.maxX }.map(\.1.minX).min()
            let destra = accanto.map { $0 - spazioCaselle } ?? margine
            let r = CGRect(x: b.minX, y: b.minY - 3 - alta, width: max(destra - b.minX, b.width), height: alta)
            var c = ModelloModulo.Campo(pagina: indice, riquadro: r, etichetta: testo, origine: .regole, daConfermare: true)
            applica(associazione, a: &c)
            campi.append(c)
        }
        return campi
    }

    /// I pezzi di testo della pagina con il loro riquadro: ogni riga divisa dove uno spazio è largo (più di 10 punti),
    /// perché PDFKit mette sulla stessa riga le etichette affiancate, e dove una lettera cambia riga o è ruotata (una
    /// filigrana come «FAC-SIMILE» che PDFKit unisce all'etichetta vicina).
    static func etichette(_ pagina: PDFPage) -> [(String, CGRect)] {
        guard let testo = pagina.string, !testo.isEmpty else { return [] }
        let ns = testo as NSString
        var pezzi: [(String, CGRect)] = []
        var inizio = 0
        var precedente: CGRect?
        func chiudi(_ fine: Int, salta: Bool) {
            defer { inizio = salta ? fine + 1 : fine; precedente = nil }
            guard fine > inizio else { return }
            let r = NSRange(location: inizio, length: fine - inizio)
            let s = ns.substring(with: r).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty, let sel = pagina.selection(for: r) else { return }
            pezzi.append((s, sel.bounds(for: pagina)))
        }
        for i in 0..<ns.length {
            let c = ns.character(at: i)
            if c == 10 || c == 13 || c == 9 {
                chiudi(i, salta: true)
                continue
            }
            guard let b = pagina.selection(for: NSRange(location: i, length: 1))?.bounds(for: pagina) else { continue }
            if c == 32 {
                if b.width > sogliaSpazio { chiudi(i, salta: true) }
                continue
            }
            // Una lettera fuori dalla riga della precedente (altra altezza o ruotata) apre un pezzo nuovo
            if let p = precedente, abs(b.minY - p.minY) > sogliaRiga || b.height > p.height * 1.5 || p.height > b.height * 1.5 {
                chiudi(i, salta: false)
            }
            precedente = b
        }
        chiudi(ns.length, salta: false)
        return pezzi
    }

    /// Uno spazio più largo di così separa due etichette affiancate (punti PDF).
    static let sogliaSpazio: CGFloat = 10
    /// Due lettere della stessa etichetta non si scostano in altezza più di così (punti PDF).
    static let sogliaRiga: CGFloat = 2
    /// Lo spazio lasciato fra due caselle affiancate (punti PDF).
    static let spazioCaselle: CGFloat = 9

    /// Le etichette che le regole non hanno riconosciuto (per Vera): campi senza dato, non firme né risposte.
    static func nonRiconosciute(_ campi: [ModelloModulo.Campo]) -> [String] {
        var viste = Set<String>()
        return campi.filter { $0.dato == nil && !$0.firma && !$0.risposta }.map(\.etichetta)
            .filter { viste.insert($0).inserted }
    }
}

extension PDFAnnotation {
    /// Un widget casella (✓).
    var isCasella: Bool { type == "Widget" && widgetFieldType == .button && widgetControlType == .checkBoxControl }
}
