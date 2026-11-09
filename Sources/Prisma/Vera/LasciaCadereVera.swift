import Foundation

// «Lascia cadere qui» (Vera/BRIEF.md, funzione 9; template «Lascia cadere qui»): un documento trascinato su Vera o sulla
// scrivania viene letto sul Mac (PDFKit, Vision per le scansioni), riconosciuto (tipo e categoria con le regole di
// EstrattoreDocumento e MotoreDocumenti) e assegnato al cliente giusto: prima il codice fiscale, poi contraente,
// intestatario e assicurato, poi il nome del cliente scritto nella prima pagina. Se il cliente non è unico Vera lo dice.
// I dati letti e il promemoria della scadenza passano dalla scheda di conferma: niente si salva prima di «Conferma».
// Niente modello Apple (CLAUDE.md): Vision, regole e, dopo l'archiviazione, Qwen completa i campi come per ogni documento.

/// Quello che Prisma ha capito di un documento trascinato.
struct LetturaCaduta {
    var nomeFile: String
    var pagine: [String]
    var pagineOCR: Int
    var tipo: Documento.Tipo
    var categoria: CategoriaDocumento
    var campi: [CampoEstratto]
    /// Il cliente riconosciuto e come («dal codice fiscale», «dal contraente»…); nil se non è unico.
    var clienteId: String?
    var come: String
    /// I clienti possibili quando il riconoscimento non è unico.
    var possibili: [String] = []
}

/// Una posizione letta in un estratto conto: nome, ISIN se c'è, controvalore e pagina. Va in Posizioni solo con «Conferma».
struct PosizioneLetta: Codable, Equatable {
    var nome: String
    var isin: String?
    var valore: Double
    var pagina: Int
}

enum LasciaCadereVera {
    /// Il promemoria arriva un mese prima della scadenza (come per le posizioni).
    static let giorniPrima = 30

    static func normale(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
            .split { !$0.isLetter }.joined(separator: " ")
    }

    /// Il cliente del documento: codice fiscale, poi i nomi dei campi, poi il nome nel testo delle prime due pagine.
    static func cliente(campi: [CampoEstratto], pagine: [String], clienti: [Cliente]) -> (id: String?, come: String, possibili: [String]) {
        let testo = pagine.prefix(2).joined(separator: "\n")
        // 1. Il codice fiscale, ovunque nella prima pagina o nei campi
        let maiuscolo = testo.uppercased()
        let codici = clienti.filter { c in
            let cf = c.codiceFiscale.uppercased().replacingOccurrences(of: " ", with: "")
            return cf.count == 16 && EstrattoreDocumento.formaCodiceFiscaleValida(cf)
                && (maiuscolo.contains(cf) || campi.contains { $0.chiave == .codiceFiscale && $0.valore.uppercased().replacingOccurrences(of: " ", with: "") == cf })
        }
        if codici.count == 1 {
            // Il codice fiscale vince, a meno che il contraente indichi un solo altro cliente: allora si chiede
            let contraente = campi.first { $0.chiave == .contraente }.map { normale($0.valore) } ?? ""
            let altri = clienti.filter { c in c.id != codici[0].id && !contraente.isEmpty
                && Set(normale(c.nome).split(separator: " ")).isSubset(of: Set(contraente.split(separator: " "))) }
            if altri.count == 1 { return (nil, "più clienti nel documento", [codici[0].id, altri[0].id]) }
            return (codici[0].id, "dal codice fiscale", [])
        }
        // 2. Contraente, intestatario, assicurato
        for chiave in [CampoDocumento.contraente, .intestatario, .assicurato] {
            guard let v = campi.first(where: { $0.chiave == chiave })?.valore else { continue }
            let n = normale(v)
            let trovati = clienti.filter { c in
                let nome = normale(c.nome)
                // Parole intere: «Ugo Rossi» non è «Ugo Rossini»
                return !nome.isEmpty && ((" " + n + " ").contains(" " + nome + " ") || Set(nome.split(separator: " ")).isSubset(of: Set(n.split(separator: " "))))
            }
            if trovati.count == 1 { return (trovati[0].id, "dal \(chiave.nome.lowercased())", []) }
        }
        // 3. Il nome completo nel testo
        let n = " " + normale(testo) + " "
        let nominati = clienti.filter { c in
            let nome = normale(c.nome)
            let parti = nome.split(separator: " ")
            guard parti.count >= 2 else { return false }
            let rovescio = parti.reversed().joined(separator: " ")
            return n.contains(" \(nome) ") || n.contains(" \(rovescio) ")
        }
        if nominati.count == 1 { return (nominati[0].id, "dal nome nel documento", []) }
        return (nil, nominati.isEmpty ? "nessun cliente nel documento" : "più clienti nel documento", nominati.map(\.id))
    }

    /// La lettura completa di un documento già trasformato in pagine di testo.
    static func leggi(nomeFile: String, pagine: [String], pagineOCR: Int, clienti: [Cliente]) -> LetturaCaduta {
        let campi = EstrattoreDocumento.conRegole(pagine)
        let tipo = EstrattoreDocumento.tipoProbabile(pagine)
        let categoria = MotoreDocumenti.categoriaProbabile(pagine, tipo: tipo)
        let c = cliente(campi: campi, pagine: pagine, clienti: clienti)
        return LetturaCaduta(nomeFile: nomeFile, pagine: pagine, pagineOCR: pagineOCR, tipo: tipo, categoria: categoria, campi: campi,
                             clienteId: c.id, come: c.come, possibili: c.possibili)
    }

    /// La scadenza letta nel documento (se c'è).
    static func scadenza(_ campi: [CampoEstratto]) -> Date? {
        EstrattoreDocumento.data(campi.first { $0.chiave == .scadenza }?.valore)
    }

    // MARK: - Estratto conto → Posizioni (template: «3 posizioni lette, da confermare»)

    /// Lo strumento della riga «Aggiungo / aggiorno in Posizioni» (eseguito in LasciaCadereShell.swift).
    static let strumentoPosizione = "posizioni_da_documento"
    /// Al massimo tante posizioni da un estratto conto.
    static let massimoPosizioni = 8

    /// Le parole delle righe che non sono posizioni: totali, movimenti, costi, intestazioni.
    private static let righeEscluse = #"\b(?:totale|totali|saldo|commission\w*|impost\w*|bollo|interess\w*|spese|competenz\w*|iban|codice fiscale|periodo|pagina|premio|rata|versament\w*|prelev\w*|bonific\w*|addebit\w*|accredit\w*|cedol\w*|dividend\w*|ritenut\w*|data)\b"#

    /// Le posizioni di un estratto conto, solo con le regole: una riga con un nome e un importo in euro alla fine
    /// («Fondo Azionario Europa · ISIN LU… · 12.340,50 €»), senza date (i movimenti) né parole di totali e costi.
    static func posizioniLette(_ pagine: [String]) -> [PosizioneLetta] {
        var lette: [PosizioneLetta] = []
        let importo = #"(?<![\d.,])(\d{1,3}(?:\.\d{3})+|\d+),\d{2}(?![\d,])"#
        for (n, pagina) in pagine.enumerated() {
            for rigaGrezza in pagina.components(separatedBy: .newlines) {
                let riga = rigaGrezza.trimmingCharacters(in: .whitespaces)
                let piegata = normale(riga)
                guard riga.count <= 160,
                      DateItaliane.cerca(righeEscluse, piegata) == nil,
                      riga.range(of: #"\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}"#, options: .regularExpression) == nil,
                      let re = try? NSRegularExpression(pattern: importo),
                      let ultimo = re.matches(in: riga, range: NSRange(riga.startIndex..., in: riga)).last,
                      let r = Range(ultimo.range, in: riga),
                      let valore = EstrattoreDocumento.numero(String(riga[r])), valore > 0 else { continue }
                // L'ISIN in maiuscolo (DateItaliane.cerca ignora le maiuscole: una parola di 12 lettere finita in cifra passerebbe)
                let isin = riga.range(of: #"\b[A-Z]{2}[A-Z0-9]{9}\d\b"#, options: .regularExpression).map { String(riga[$0]) }
                // Il nome: il testo prima del primo numero o dell'ISIN, senza le parole del valore
                var nome = String(riga[..<r.lowerBound])
                if let i = nome.range(of: #"\bISIN\b|[A-Z]{2}[A-Z0-9]{9}\d|\d"#, options: .regularExpression) { nome = String(nome[..<i.lowerBound]) }
                nome = nome.replacingOccurrences(of: #"(?i)\b(controvalore|valore|quote|n\.|nr\.|eur|euro)\b"#, with: " ", options: .regularExpression)
                nome = nome.trimmingCharacters(in: CharacterSet(charactersIn: " .:;,-–—·|€\t"))
                    .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
                guard nome.filter(\.isLetter).count >= 4,
                      !lette.contains(where: { normale($0.nome) == normale(nome) }) else { continue }
                lette.append(PosizioneLetta(nome: nome, isin: isin, valore: valore, pagina: n + 1))
                if lette.count == massimoPosizioni { return lette }
            }
        }
        return lette
    }

    /// L'area più probabile di una posizione letta dal nome.
    static func areaProbabile(_ nome: String) -> AreaPosizione {
        let t = normale(nome)
        if DateItaliane.cerca(#"\b(?:fondo pensione|pip|previdenz\w*)\b"#, t) != nil { return .previdenza }
        if DateItaliane.cerca(#"\b(?:conto|deposito|libretto|conto deposito)\b"#, t) != nil { return .liquidita }
        return .investimento
    }

    /// La posizione del cliente che una riga letta aggiorna: in essere, non coperture né debiti, con il nome che torna a
    /// parole intere (in un senso o nell'altro). Solo se è una: mai a caso tra due.
    static func posizioneEsistente(_ p: PosizioneLetta, tra posizioni: [Posizione], cliente: String) -> Posizione? {
        let letta = Set(normale(p.nome).split(separator: " "))
        let trovate = posizioni.filter { x in
            guard x.clienteId == cliente, x.stato == .inEssere, x.area != .protezione, !x.area.passivo else { return false }
            let sua = Set(normale(x.nome).split(separator: " "))
            return !sua.isEmpty && (sua.isSubset(of: letta) || letta.isSubset(of: sua))
        }
        return trovate.count == 1 ? trovate.first : nil
    }

    /// La riga della scheda per una posizione letta: aggiorna il valore di quella che c'è o ne aggiunge una nuova (in
    /// essere, canale indipendente: non l'hai collocata tu), sempre da confermare.
    static func azionePosizione(_ p: PosizioneLetta, cliente c: Cliente, esistente: Posizione?, data: Date, titoloDocumento: String) -> AzioneConferma {
        let valore = Formati.euro(p.valore)
        var argomenti = ["cliente": c.id, "nome": p.nome, "valore": String(p.valore), "data": RegistroStrumenti.isoData(data),
                         "area": areaProbabile(p.nome).rawValue, "documento": titoloDocumento, "pagina": String(p.pagina)]
        if let i = p.isin { argomenti["isin"] = i }
        if let e = esistente {
            argomenti["posizione"] = e.id
            return AzioneConferma(strumento: strumentoPosizione, app: .posizioni, titolo: "Aggiorno «\(e.nome)» in Posizioni",
                                  dettaglio: "\(valore) al \(Formati.dataEstesa.string(from: data)) · letto a pag. \(p.pagina)", argomenti: argomenti)
        }
        return AzioneConferma(strumento: strumentoPosizione, app: .posizioni, titolo: "Aggiungo «\(p.nome)» in Posizioni",
                              dettaglio: "\(areaProbabile(p.nome).nome) · \(valore) al \(Formati.dataEstesa.string(from: data))"
                                + (p.isin.map { " · ISIN \($0)" } ?? "") + " · in essere, indipendente · letto a pag. \(p.pagina)",
                              argomenti: argomenti)
    }

    /// La data del valore di un estratto conto: quella letta, altrimenti la data del documento, altrimenti oggi.
    static func dataValore(_ campi: [CampoEstratto], oggi: Date) -> Date {
        let letta = EstrattoreDocumento.data(campi.first { $0.chiave == .dataValore }?.valore)
            ?? EstrattoreDocumento.data(campi.first { $0.chiave == .dataDocumento }?.valore)
        return letta.map { min($0, oggi) } ?? oggi
    }

    // MARK: - Carta d'identità → Anagrafica (template: «Scade il 14 marzo 2031»)

    /// La riga «Registro il documento d'identità in anagrafica» (strumento del tagliando: In regola della scheda).
    static func azioneIdentita(_ campi: [CampoEstratto], cliente c: Cliente, titoloDocumento: String) -> AzioneConferma? {
        guard let s = scadenza(campi) else { return nil }
        let numero = campi.first { $0.chiave == .numeroDocumento }?.valore.trimmingCharacters(in: .whitespaces) ?? ""
        let rilascio = EstrattoreDocumento.data(campi.first { $0.chiave == .dataRilascio }?.valore)
        var argomenti = ["cliente": c.id, "scadenza": RegistroStrumenti.isoData(s), "titoloDocumento": titoloDocumento]
        if !numero.isEmpty { argomenti["numero"] = numero }
        if let r = rilascio { argomenti["rilascio"] = RegistroStrumenti.isoData(r) }
        var parti = ["Scade il \(Formati.dataEstesa.string(from: s))"]
        if !numero.isEmpty { parti.insert("numero \(numero)", at: 0) }
        return AzioneConferma(strumento: TagliandoVera.strumentoDocumento, app: .clienti, titolo: "Registro il documento d'identità di \(c.nome) in anagrafica",
                              dettaglio: parti.joined(separator: " · ") + " · In regola, nella scheda", argomenti: argomenti)
    }

    /// I campi di una scheda, corretti uno per uno dal consulente prima della conferma: la riga dell'archiviazione porta
    /// i campi nuovi (e il dettaglio), le righe che ne dipendono (promemoria della scadenza, documento d'identità) si rifanno.
    static func correggi(_ azioni: [AzioneConferma], campo: CampoDocumento, valore: String, cliente c: Cliente, oggi: Date,
                         cal: Calendar = .current) -> [AzioneConferma] {
        guard let i = azioni.firstIndex(where: { $0.strumento == RegistroStrumenti.documentiArchivia }) else { return azioni }
        var a = azioni[i]
        var campi = (a.argomenti["campi"]?.data(using: .utf8)).flatMap { try? JSONDecoder().decode([CampoEstratto].self, from: $0) } ?? []
        let pulito = valore.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let k = campi.firstIndex(where: { $0.chiave == campo }), campi[k].valore != pulito else { return azioni }
        campi[k].valore = pulito
        a.argomenti["campi"] = (try? JSONEncoder().encode(campi)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let titolo = a.argomenti["titolo"] ?? ""
        let tipo = Documento.Tipo(rawValue: a.argomenti["tipo"] ?? "") ?? .altro
        a.dettaglio = dettaglioArchiviazione(tipo: tipo, campi: campi)
        var r = azioni
        r[i] = a
        // Le righe che dipendono dai campi: si tolgono e si rifanno con i valori corretti (le altre restano)
        let dipendenti = [RegistroStrumenti.attivitaNuova, TagliandoVera.strumentoDocumento]
        let tolte = Set(r.filter { dipendenti.contains($0.strumento) && $0.tolta }.map(\.strumento))
        r.removeAll { dipendenti.contains($0.strumento) }
        let categoria = CategoriaDocumento(rawValue: a.argomenti["categoria"] ?? "")
        for var x in righeDipendenti(campi: campi, categoria: categoria, titolo: titolo, cliente: c, oggi: oggi, cal: cal) {
            if tolte.contains(x.strumento) { x.tolta = true }
            r.append(x)
        }
        return r
    }

    /// «Polizza · Contraente: … (pag. 1) · …»: i primi quattro dati letti.
    static func dettaglioArchiviazione(tipo: Documento.Tipo, campi: [CampoEstratto]) -> String {
        let dati = campi.filter { !$0.valore.isEmpty }.prefix(4).map { "\($0.chiave.nome): \($0.valore) (pag. \($0.pagina))" }.joined(separator: " · ")
        return "\(tipo.nome)" + (dati.isEmpty ? " · nessun dato letto" : " · \(dati)") + " · i dati letti si confermano con «Conferma»"
    }

    /// Le righe che nascono dai campi: il documento d'identità in anagrafica oppure il promemoria della scadenza.
    static func righeDipendenti(campi: [CampoEstratto], categoria: CategoriaDocumento?, titolo: String, cliente c: Cliente, oggi: Date,
                                cal: Calendar) -> [AzioneConferma] {
        if categoria == .identita {
            return azioneIdentita(campi, cliente: c, titoloDocumento: titolo).map { [$0] } ?? []
        }
        guard let s = scadenza(campi), s > oggi else { return [] }
        let quando = max(cal.startOfDay(for: oggi), cal.date(byAdding: .day, value: -giorniPrima, to: s) ?? s)
        return [AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Promemoria per la scadenza",
                               dettaglio: "«Scade «\(titolo)» il \(Formati.dataEstesa.string(from: s))» · \(c.nome) · il \(Formati.dataEstesa.string(from: quando))",
                               argomenti: ["cliente": c.id, "titolo": "Scade «\(titolo)» il \(Formati.dataEstesa.string(from: s))",
                                           "scadenza": RegistroStrumenti.isoData(quando)])]
    }

    /// Le righe della scheda: l'archiviazione con i dati letti; poi, secondo il documento, le posizioni lette (estratto
    /// conto → Posizioni), il documento d'identità (→ Anagrafica) o il promemoria della scadenza.
    static func azioni(_ l: LetturaCaduta, cliente c: Cliente, file: URL, testo: URL, oggi: Date, posizioni: [Posizione] = [],
                       cal: Calendar = .current) -> [AzioneConferma] {
        let campi = l.campi.filter { !$0.valore.isEmpty }
        let titolo = (l.nomeFile as NSString).deletingPathExtension
        let json = (try? JSONEncoder().encode(campi)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        var righe = [AzioneConferma(strumento: RegistroStrumenti.documentiArchivia, app: .documenti,
                                    titolo: "Archivio «\(titolo)» in \(c.nome) · Documenti",
                                    dettaglio: dettaglioArchiviazione(tipo: l.tipo, campi: campi),
                                    argomenti: ["cliente": c.id, "file": file.path, "testo": testo.path, "titolo": titolo, "tipo": l.tipo.rawValue,
                                                "categoria": l.categoria.rawValue, "campi": json, "pagine": String(l.pagine.count),
                                                "pagineOCR": String(l.pagineOCR)])]
        if l.tipo == .estrattoConto {
            let data = dataValore(l.campi, oggi: oggi)
            for p in posizioniLette(l.pagine) {
                righe.append(azionePosizione(p, cliente: c, esistente: posizioneEsistente(p, tra: posizioni, cliente: c.id), data: data, titoloDocumento: titolo))
            }
        }
        righe += righeDipendenti(campi: l.campi, categoria: l.categoria, titolo: titolo, cliente: c, oggi: oggi, cal: cal)
        return righe
    }
}
