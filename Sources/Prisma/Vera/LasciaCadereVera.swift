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

    /// Le righe della scheda: l'archiviazione con i dati letti e, se c'è una scadenza futura, il promemoria.
    static func azioni(_ l: LetturaCaduta, cliente c: Cliente, file: URL, testo: URL, oggi: Date, cal: Calendar = .current) -> [AzioneConferma] {
        let campi = l.campi.filter { !$0.valore.isEmpty }
        let dati = campi.prefix(4).map { "\($0.chiave.nome): \($0.valore) (pag. \($0.pagina))" }.joined(separator: " · ")
        let titolo = (l.nomeFile as NSString).deletingPathExtension
        let json = (try? JSONEncoder().encode(campi)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        var righe = [AzioneConferma(strumento: RegistroStrumenti.documentiArchivia, app: .documenti,
                                    titolo: "Archivio «\(titolo)» in \(c.nome) · Documenti",
                                    dettaglio: "\(l.tipo.nome)" + (dati.isEmpty ? " · nessun dato letto" : " · \(dati)") + " · i dati letti si confermano con «Conferma»",
                                    argomenti: ["cliente": c.id, "file": file.path, "testo": testo.path, "titolo": titolo, "tipo": l.tipo.rawValue,
                                                "categoria": l.categoria.rawValue, "campi": json, "pagine": String(l.pagine.count),
                                                "pagineOCR": String(l.pagineOCR)])]
        if let s = scadenza(l.campi), s > oggi {
            let quando = max(cal.startOfDay(for: oggi), cal.date(byAdding: .day, value: -giorniPrima, to: s) ?? s)
            righe.append(AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Promemoria per la scadenza",
                                        dettaglio: "«Scade «\(titolo)» il \(Formati.dataEstesa.string(from: s))» · \(c.nome) · il \(Formati.dataEstesa.string(from: quando))",
                                        argomenti: ["cliente": c.id, "titolo": "Scade «\(titolo)» il \(Formati.dataEstesa.string(from: s))",
                                                    "scadenza": RegistroStrumenti.isoData(quando)]))
        }
        return righe
    }
}
