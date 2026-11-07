import Foundation

// «Il codice in tasca» (Vera/BRIEF.md, funzione 13; template «Il codice in tasca»; Luce, decisioni 68 e 93): una
// biblioteca delle norme sul Mac, solo con i PDF che porta l'utente (TUF, Regolamento Intermediari, codice delle
// assicurazioni, previdenza complementare, successioni…), ognuno con la sua edizione. Prisma divide il testo per
// articolo, cerca con BM25 e (se c'è il modello di ricerca) per significato; Qwen risponde in JSON solo dagli articoli
// trovati e cita sempre l'articolo. Se nessun articolo risponde, Vera lo dice («ho cercato in N articoli»).

struct ArticoloNorma: Codable, Identifiable, Equatable {
    var id: String
    /// «177», «12-bis».
    var numero: String
    /// La rubrica, se c'è («Diritto di recesso»).
    var rubrica: String
    /// La pagina del PDF da cui comincia.
    var pagina: Int
    var testo: String
}

struct TestoNorma: Codable, Identifiable, Equatable {
    var id = "norma-\(UUID().uuidString.prefix(8).lowercased())"
    var titolo: String
    /// «D.Lgs. 209/2005».
    var sigla: String
    /// L'edizione, scritta dall'utente o la data di importazione («aggiornato al 1° ottobre 2026»).
    var edizione: String
    /// Il PDF, relativo alla cartella della Biblioteca.
    var file: String
    var importatoIl = Date()
    var articoli: [ArticoloNorma] = []
}

/// Un articolo citato in una risposta.
struct CitazioneNorma: Codable, Equatable, Identifiable {
    var testoId: String
    var articoloId: String
    var titolo: String
    var sigla: String
    var edizione: String
    var numero: String
    var rubrica: String
    var pagina: Int
    var id: String { articoloId }

    /// «Codice delle assicurazioni private · art. 177».
    var etichetta: String { "\(titolo) · \(NormeVera.etichetta(numero))" }
}

/// La risposta di «Il codice in tasca» salvata nel messaggio: gli articoli citati, o quanti ne ha cercati.
struct RispostaNorme: Codable, Equatable {
    var citazioni: [CitazioneNorma]
    /// La norma non risponde: Vera non inventa.
    var nonRisponde: Bool
    var articoliCercati: Int
    var testiCercati: Int
}

enum NormeVera {
    // MARK: - Dividere per articolo

    private static let schemaArticolo = try? NSRegularExpression(
        pattern: #"(?m)^[ \t]*(?:Art\.|Articolo|ART\.|ARTICOLO)[ \t]*(\d{1,4}(?:\.\d{1,3})*(?:[ \t]*-?[ \t]*(?:bis|ter|quater|quinquies|sexies|septies|octies|novies|decies))?)[ \t]*\.?[ \t]*(?:[-–—][ \t]*)?(.*)$"#)

    /// Gli articoli di un testo, pagina per pagina: comincia un articolo a ogni «Art. N» a inizio riga.
    static func articoli(_ pagine: [String], testoId: String) -> [ArticoloNorma] {
        guard let re = schemaArticolo else { return [] }
        var risultato: [ArticoloNorma] = []
        var corrente: ArticoloNorma?
        var visti: [String: Int] = [:]
        for (i, pagina) in pagine.enumerated() {
            let ns = pagina as NSString
            var inizio = 0
            for m in re.matches(in: pagina, range: NSRange(location: 0, length: ns.length)) {
                if var c = corrente {
                    c.testo += ns.substring(with: NSRange(location: inizio, length: m.range.location - inizio))
                    risultato.append(c)
                }
                let numero = ns.substring(with: m.range(at: 1)).replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\t", with: "").lowercased()
                let resto = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespaces)
                // Una rubrica breve sulla stessa riga («Art. 177 – Diritto di recesso»); altrimenti è già testo
                let rubrica = resto.count <= 90 && !resto.hasSuffix(".") ? resto : ""
                let volte = visti[numero, default: 0]
                visti[numero] = volte + 1
                let id = "\(testoId)-art-\(numero)" + (volte > 0 ? "-\(volte + 1)" : "")
                corrente = ArticoloNorma(id: id, numero: numero, rubrica: rubrica, pagina: i + 1, testo: rubrica.isEmpty ? resto + "\n" : "")
                inizio = m.range.location + m.range.length
            }
            if var c = corrente {
                c.testo += ns.substring(from: inizio) + "\n"
                corrente = c
            }
        }
        if let c = corrente { risultato.append(c) }
        // Un testo senza «Art. N» (circolari, guide): si cerca e si cita pagina per pagina
        if risultato.isEmpty {
            return pagine.enumerated().compactMap { i, p in
                let s = p.trimmingCharacters(in: .whitespacesAndNewlines)
                return s.isEmpty ? nil : ArticoloNorma(id: "\(testoId)-pag-\(i + 1)", numero: "pag. \(i + 1)", rubrica: "", pagina: i + 1, testo: s)
            }
        }
        return risultato.map { a in
            var x = a
            x.testo = a.testo.trimmingCharacters(in: .whitespacesAndNewlines)
            return x
        }.filter { !$0.testo.isEmpty || !$0.rubrica.isEmpty }
    }

    // MARK: - Riconoscere la domanda

    /// Una domanda sulle norme (la biblioteca non è vuota). Le parole forti (norma, legge, articolo, TUF, IVASS…) bastano;
    /// le altre (recesso, termini, imposte…) valgono solo se la frase non parla di un cliente o di una sua polizza.
    static func eUnaDomanda(_ testo: String, clienti: [ClienteNoto] = []) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        guard testo.contains("?") || DateItaliane.cerca(#"^(cosa dice|che dice|secondo|in base a|dimmi cosa prevede)"#, t) != nil else { return false }
        let forti = #"\b(norma|norme|legge|leggi|articolo|art\.|codice delle|decreto|d\.?lgs|regolamento|tuf|ivass|consob|covip|mifid|idd)\b"#
        if DateItaliane.cerca(forti, t) != nil { return true }
        guard InterpreteComandi.clientiNominati(t, clienti).isEmpty,
              DateItaliane.cerca(#"\b(?:del|della|dei|delle|di) (?:mio |mia |suo |sua )?(?:cliente|polizza|piano|contratto|fondo)\b"#, t) == nil else { return false }
        let deboli = #"\b(obblig(?:o|hi|atori[oa]|atoriet[aà])|termine|termini|entro quant|recesso|recedere|ripensa|revoca|successione|eredit|impost[ae]\b|tassazion|deducib|adeguatezza|profilatura|conflitto di interess|reclamo|prescrizion|pignorab|sequestrab)"#
        return DateItaliane.cerca(deboli, t) != nil
    }

    // MARK: - Cercare

    static let finestraPezzo = 2_500
    static let sovrapposizione = 300

    /// «art. 177», oppure «pag. 3» per i testi senza articoli.
    static func etichetta(_ numero: String) -> String { numero.hasPrefix("pag.") ? numero : "art. \(numero)" }

    /// I pezzi da cercare: ogni articolo con il suo numero nel testo (così «articolo 177» lo trova); gli articoli lunghi in
    /// più finestre sovrapposte (id «…#1», «…#2»), così anche i commi finali si trovano.
    static func pezzi(_ testi: [TestoNorma]) -> [PezzoRicerca] {
        testi.flatMap { t in
            t.articoli.flatMap { a -> [PezzoRicerca] in
                let testa = (a.numero.hasPrefix("pag.") ? "" : "Articolo \(a.numero) (art. \(a.numero))\n") + (a.rubrica.isEmpty ? "" : a.rubrica + "\n")
                let c = Array(a.testo)
                let lunghezza = max(500, finestraPezzo - testa.count)
                var risultato: [PezzoRicerca] = []
                var i = 0, k = 0
                repeat {
                    let fine = min(c.count, i + lunghezza)
                    risultato.append(PezzoRicerca(id: k == 0 ? a.id : "\(a.id)#\(k)", tipo: .norma, clienteId: nil,
                                                  fonte: "\(t.titolo) · \(etichetta(a.numero))", testo: testa + String(c[i..<fine])))
                    i += lunghezza - sovrapposizione
                    k += 1
                } while i < c.count - sovrapposizione
                return risultato
            }
        }
    }

    static func citazione(_ articoloId: String, in testi: [TestoNorma]) -> CitazioneNorma? {
        let base = articoloId.split(separator: "#").first.map(String.init) ?? articoloId
        for t in testi {
            if let a = t.articoli.first(where: { $0.id == base }) {
                return CitazioneNorma(testoId: t.id, articoloId: a.id, titolo: t.titolo, sigla: t.sigla, edizione: t.edizione,
                                      numero: a.numero, rubrica: a.rubrica, pagina: a.pagina)
            }
        }
        return nil
    }

    // MARK: - Qwen risponde dagli articoli (JSON)

    static let schema: [String: Any] = {
        let p: [String: Any] = ["risponde": ["type": "boolean"], "risposta": ["type": "string"],
                                "articoli": ["type": "array", "items": ["type": "string"]]]
        return ["type": "object", "properties": p, "required": ["risponde", "risposta", "articoli"]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("norme") ?? "Rispondi alla domanda di un consulente finanziario usando solo gli articoli di legge dati, che il consulente ha caricato nella sua biblioteca. Rispondi solo con il JSON: risponde (false se gli articoli non rispondono alla domanda), risposta (in italiano, breve e chiara, con i termini e le cifre così come sono scritti negli articoli), articoli (gli id degli articoli da cui viene la risposta). Non usare conoscenze tue e non inventare."
    }

    static func messaggi(_ domanda: String, trovati: [(PezzoRicerca, CitazioneNorma)]) -> [MessaggioModello] {
        let blocchi = trovati.map { p, c in "[id: \(c.articoloId)] \(c.titolo) (\(c.sigla), \(c.edizione)) · \(etichetta(c.numero))\(c.rubrica.isEmpty ? "" : " – \(c.rubrica)")\n\(p.testo)" }
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "ARTICOLI TROVATI DA PRISMA\n\(blocchi.joined(separator: "\n\n"))\n\nDOMANDA DEL CONSULENTE\n\(domanda)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.1
        o.contesto = NucleoVera.finestra
        o.massimoToken = 700
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    /// La risposta di Qwen, se è valida: un testo e solo articoli tra quelli dati; le cifre devono venire dagli articoli.
    /// nil = JSON non valido (si scarta); `risponde == false` = la norma non risponde.
    static func leggi(_ json: String, trovati: [(PezzoRicerca, CitazioneNorma)]) -> (risponde: Bool, testo: String, citazioni: [CitazioneNorma])? {
        guard let i = json.firstIndex(of: "{"), let f = json.lastIndex(of: "}"), i < f,
              let d = String(json[i...f]).data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let risponde = j["risponde"] as? Bool else { return nil }
        guard risponde else { return (false, "", []) }
        let testo = ((j["risposta"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let ids = (j["articoli"] as? [String]) ?? []
        let citazioni = ids.compactMap { id in trovati.first { $0.1.articoloId == id }?.1 }
        // Senza articolo la risposta non vale (regola: cita sempre l'articolo); le cifre devono stare negli articoli citati
        guard !testo.isEmpty, !citazioni.isEmpty else { return nil }
        let fonti = trovati.filter { t in citazioni.contains { $0.articoloId == t.1.articoloId } }.map(\.0.testo).joined(separator: "\n")
            + "\n" + trovati.map { "\($0.1.etichetta) \($0.1.sigla) \($0.1.edizione)" }.joined(separator: "\n")
        guard CommentoVera.numeriConservati(bozza: fonti, testo: testo) else { return nil }
        return (true, testo, citazioni)
    }
}
