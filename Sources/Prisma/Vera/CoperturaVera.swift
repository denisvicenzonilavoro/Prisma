import Foundation

// «Cosa non copre» (Vera/BRIEF.md, funzione 12; template «Cosa non copre»): da una polizza, esclusioni, carenze,
// franchigie e massimali. Prima il codice: le condizioni si dividono per articolo (la stessa divisione della biblioteca
// delle norme, NormeVera.articoli) e le parole chiave scelgono gli articoli e le frasi che parlano di limiti. Qwen (se è
// pronto) le riscrive in JSON, per il consulente e con le parole del cliente: ogni voce vale solo se cita un articolo
// dato e la sua frase si ritrova in quell'articolo. Senza articolo la voce non compare. Una polizza scansionata senza
// testo non si legge, e Vera lo dice.

enum CoperturaVera {
    /// Le parole che dicono il tipo di limite (in ordine: la prima che si trova vince).
    static let segni: [(LimiteCopertura.Tipo, String)] = [
        (.carenza, #"\bcarenz\w*|\bdecorr\w* dalle ore|\bdecorre (?:dal|dalle)|\bdopo (?:\d+|trenta|novanta|centottanta|sessanta) giorni dalla"#),
        (.franchigia, #"\bfranchigi\w*|\bscopert\w*|\bnon si fa luogo a indennizzo fino\b|\bdal (?:terzo|secondo|quarto|quinto) giorno\b"#),
        (.massimale, #"\bmassimal\w*|\bsomm[ae] assicurat\w*|\blimite di indennizzo|\bfino a (?:un massimo di )?[\d\.]+(?:,\d+)? ?€|\bfino a euro\b"#),
        (.esclusione, #"\besclus[oaie]\b|\besclusion\w*|\bnon (?:sono|è) (?:coperti|coperto|coperte|indennizzabil\w*|assicurat\w*)\b|\bnon (?:indennizza|copre|risponde)\b|\brischi esclusi\b"#),
    ]

    static func tipo(_ frase: String) -> LimiteCopertura.Tipo? {
        let t = frase.lowercased()
        return segni.first { DateItaliane.cerca($0.1, t) != nil }?.0
    }

    /// Le voci con le regole: per ogni articolo, le frasi con un segno di limite (la frase così com'è, per il consulente).
    static func conRegole(_ articoli: [ArticoloNorma]) -> [LimiteCopertura] {
        var voci: [LimiteCopertura] = []
        for a in articoli {
            // Il testo del PDF va a capo a ogni riga stampata: dentro un articolo le righe si uniscono prima delle frasi
            let corpo = a.testo.replacingOccurrences(of: #"\s*\n\s*"#, with: " ", options: .regularExpression)
            let testo = (a.rubrica.isEmpty ? "" : a.rubrica + ". ") + corpo
            for frase in PromesseVera.frasi(testo) {
                guard let t = tipo(frase) else { continue }
                // La rubrica da sola («Rischi esclusi.») non è una voce
                guard frase.count >= 20 else { continue }
                let voce = frase.replacingOccurrences(of: #"^\d+(?:\.\d+)*[\.\)]?\s*"#, with: "", options: .regularExpression)
                voci.append(LimiteCopertura(tipo: t, voce: voce, perCliente: voce, articolo: a.numero, pagina: a.pagina, frase: frase))
            }
        }
        return voci
    }

    /// Gli articoli che parlano di limiti (quelli da dare a Qwen: al massimo `massimo`, per la memoria del Mac).
    static func articoliConLimiti(_ articoli: [ArticoloNorma], massimo: Int = 16) -> [ArticoloNorma] {
        Array(articoli.filter { a in segni.contains { DateItaliane.cerca($0.1, (a.rubrica + " " + a.testo).lowercased()) != nil } }.prefix(massimo))
    }

    // MARK: - Qwen (JSON, ogni voce con il suo articolo)

    static let schema: [String: Any] = {
        let tipi = LimiteCopertura.Tipo.allCases.map(\.rawValue)
        let voce: [String: Any] = ["type": "object", "required": ["tipo", "voce", "perCliente", "articolo", "frase"],
                                   "properties": ["tipo": ["type": "string", "enum": tipi], "voce": ["type": "string"], "perCliente": ["type": "string"],
                                                  "articolo": ["type": "string"], "frase": ["type": "string"]] as [String: Any]]
        return ["type": "object", "properties": ["voci": ["type": "array", "items": voce]], "required": ["voci"]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("coperture") ?? "Leggi gli articoli delle condizioni di una polizza e trova esclusioni, carenze, franchigie e massimali. Rispondi solo con il JSON: voci, ognuna con tipo (esclusione, carenza, franchigia, massimale), voce (breve, per il consulente), perCliente (una frase semplice, con le parole di tutti i giorni, senza dare del tu né del lei), articolo (il numero dato, es. 3.1) e frase (copiata parola per parola dall'articolo). Non inventare voci né cifre: senza articolo la voce non vale."
    }

    static func messaggi(_ articoli: [ArticoloNorma], cliente: String, polizza: String) -> [MessaggioModello] {
        let testo = articoli.map { "Art. \($0.numero)\($0.rubrica.isEmpty ? "" : " – \($0.rubrica)")\n\($0.testo)" }.joined(separator: "\n\n")
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "POLIZZA: \(polizza) di \(cliente)\nARTICOLI\n\(testo)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.contesto = NucleoVera.finestra
        o.massimoToken = 1_200
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    /// Le voci di Qwen che passano il controllo: articolo dato, frase dentro l'articolo, cifre della voce nell'articolo.
    static func leggi(_ json: String, articoli: [ArticoloNorma]) -> [LimiteCopertura]? {
        guard let i = json.firstIndex(of: "{"), let fine = json.lastIndex(of: "}"), i < fine,
              let d = String(json[i...fine]).data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let elenco = j["voci"] as? [[String: Any]] else { return nil }
        return elenco.compactMap { v in
            guard let t = (v["tipo"] as? String).flatMap(LimiteCopertura.Tipo.init(rawValue:)),
                  let numero = (v["articolo"] as? String)?.lowercased().replacingOccurrences(of: "art.", with: "").trimmingCharacters(in: .whitespaces),
                  let a = articoli.first(where: { $0.numero == numero }),
                  let voce = (v["voce"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !voce.isEmpty,
                  let frase = (v["frase"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), frase.count >= 10 else { return nil }
            let articolo = PromesseVera.normale(a.rubrica + " " + a.testo)
            guard articolo.contains(PromesseVera.normale(frase)) else { return nil }
            let perCliente = ((v["perCliente"] as? String) ?? voce).trimmingCharacters(in: .whitespacesAndNewlines)
            // Le cifre della voce e della spiegazione devono stare nell'articolo
            guard CommentoVera.numeriConservati(bozza: a.rubrica + " " + a.testo, testo: voce + " " + perCliente) else { return nil }
            return LimiteCopertura(tipo: t, voce: voce, perCliente: perCliente.isEmpty ? voce : perCliente, articolo: a.numero, pagina: a.pagina, frase: frase)
        }
    }

    /// Le coperture di una polizza: con le regole sempre; con le voci di Qwen al loro posto quando ci sono.
    static func copertura(_ d: Documento, pagine: [String], voci qwen: [LimiteCopertura]? = nil) -> CoperturaPolizza {
        // Solo gli articoli numerati: una polizza senza «Art. N» non si cita (NormeVera la dividerebbe per pagina)
        let articoli = NormeVera.articoli(pagine, testoId: d.id).filter { !$0.numero.hasPrefix("pag.") }
        let regole = conRegole(articoli)
        var voci = regole
        if let qwen, !qwen.isEmpty {
            // Le voci di Qwen sostituiscono quelle delle regole dello stesso articolo e tipo; le altre delle regole restano
            let coperti = Set(qwen.map { "\($0.articolo)|\($0.tipo.rawValue)" })
            voci = qwen + regole.filter { !coperti.contains("\($0.articolo)|\($0.tipo.rawValue)") }
        }
        let ordine = LimiteCopertura.Tipo.allCases
        voci.sort { (ordine.firstIndex(of: $0.tipo) ?? 0, $0.pagina) < (ordine.firstIndex(of: $1.tipo) ?? 0, $1.pagina) }
        return CoperturaPolizza(documentoId: d.id, clienteId: d.clienteId, titolo: d.titolo, voci: voci, articoliLetti: articoli.count, conQwen: !(qwen ?? []).isEmpty)
    }

    /// «Cosa non copre la polizza di Marco?», «esclusioni della polizza», «franchigie e massimali…».
    static func eUnaRichiesta(_ testo: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        // Una domanda sulle norme («le esclusioni dell'art. 1900 del codice civile») va alla biblioteca delle norme
        if DateItaliane.cerca(#"\b(?:codice civile|codice delle assicurazioni|legge|decreto|regolamento ivass|ivass|normativ\w*|art\.? ?\d{3,})\b"#, t) != nil { return false }
        if DateItaliane.cerca(#"\bnorm[ae]\b"#, t) != nil, DateItaliane.cerca(#"polizz|copertur|contratt|propost"#, t) == nil { return false }
        if DateItaliane.cerca(#"\b(cosa non copre|cosa (?:non )?esclude|esclusion\w*|franchigi\w*|limiti della (?:polizza|copertura))\b"#, t) != nil { return true }
        // «Carenze» e «massimali» da soli parlano anche di protezione o liquidità: servono la polizza o la copertura
        return DateItaliane.cerca(#"\b(carenz\w*|massimal\w*)\b"#, t) != nil
            && DateItaliane.cerca(#"polizz|copertur|contratt|condizion|infortun"#, t) != nil
    }

    /// Il messaggio per il cliente: le voci con le sue parole, ognuna con l'articolo.
    static func messaggioCliente(_ c: CoperturaPolizza, nome: String) -> String {
        var righe = ["Gentile \(nome), le riassumo i limiti della sua polizza «\(c.titolo)», con l'articolo delle condizioni:"]
        for t in LimiteCopertura.Tipo.allCases {
            let v = c.voci(t)
            guard !v.isEmpty else { continue }
            righe.append("\(t.titolo): " + v.map { "\($0.perCliente) (art. \($0.articolo))" }.joined(separator: "; ") + ".")
        }
        righe.append("Resto a disposizione per qualsiasi chiarimento.")
        return righe.joined(separator: "\n")
    }
}
