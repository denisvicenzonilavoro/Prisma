import Foundation

// Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.5.2 punto 3, «Luce» giro 6, decisione 93):
// Vera risponde solo dai passi che Prisma ha trovato con BM25 (Motori/MotoreBiblioteca.swift). A Qwen vanno la domanda e
// i 6 passi con la loro etichetta ([P1] «Titolo», pagina 14, Art. 9 · Riscatto: …), mai dati dei clienti. Qwen risponde in
// JSON (Vera/Istruzioni/biblioteca.md, Vera/Schemi/biblioteca.json); Prisma verifica:
// - la frase deve stare parola per parola dentro il passo indicato (spazi, a capo e sillabazioni normalizzati);
// - le cifre della risposta devono comparire nel passo;
// - nella risposta nessun nome di cliente che non sia già nella domanda.
// Se una verifica fallisce la risposta non si mostra come citazione: si apre la pagina del passo con «guarda il passo».

/// Un passo dato a Vera, con il documento da cui viene.
struct PassoPerVera: Equatable {
    let etichetta: String
    let passo: PassoBiblioteca
    let titolo: String
    let edizione: String
}

/// Cosa ha risposto Vera, dopo la verifica di Prisma.
enum EsitoTrovaPagina: Equatable {
    /// La risposta con la frase trovata davvero nel passo.
    case risposta(passo: PassoBiblioteca, frase: String, testo: String)
    /// Nessun passo risponde alla domanda (lo dice Vera).
    case nonTrovata
    /// Una risposta che Prisma non ha potuto verificare: si mostra il passo, senza citazione.
    case nonVerificata(passo: PassoBiblioteca, motivo: String)
}

enum TrovaPaginaVera {
    static let schema: [String: Any] = {
        let p: [String: Any] = ["trovato": ["type": "boolean"], "passo": ["type": "string"],
                                "frase": ["type": "string"], "risposta": ["type": "string"]]
        return ["type": "object", "properties": p, "required": ["trovato", "passo", "frase", "risposta"]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("biblioteca") ?? "Rispondi alla domanda di un consulente finanziario usando solo i passi dati, presi dai documenti della sua biblioteca. Rispondi solo con il JSON: trovato (false se nessun passo risponde), passo (l'etichetta, es. P2), frase (la frase del passo che risponde, copiata parola per parola), risposta (breve, in italiano, con le cifre scritte nel passo). Non usare conoscenze tue e non inventare."
    }

    /// I passi con la loro etichetta, nell'ordine della ricerca.
    static func passi(_ trovati: [PassoTrovato], documenti: [DocumentoBiblioteca]) -> [PassoPerVera] {
        trovati.enumerated().map { i, t in
            let d = documenti.first { $0.id == t.passo.documentoId }
            return PassoPerVera(etichetta: "P\(i + 1)", passo: t.passo, titolo: d?.titolo ?? "", edizione: d?.edizione ?? "")
        }
    }

    static func messaggi(_ domanda: String, passi: [PassoPerVera]) -> [MessaggioModello] {
        let blocchi = passi.map { p in
            let articolo = p.passo.intestazioneVista.isEmpty ? "" : ", \(p.passo.intestazioneVista)"
            let edizione = p.edizione.isEmpty ? "" : " (\(p.edizione))"
            return "[\(p.etichetta)] «\(p.titolo)»\(edizione), pagina \(p.passo.pagina)\(articolo):\n\(p.passo.testo)"
        }
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "PASSI TROVATI DA PRISMA\n\(blocchi.joined(separator: "\n\n"))\n\nDOMANDA DEL CONSULENTE\n\(domanda)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.1
        o.contesto = NucleoVera.finestra
        o.massimoToken = 600
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        o.conLezioni = false
        return o
    }

    /// La risposta di Qwen verificata da Prisma. nil = JSON non valido.
    /// - nomiClienti: i nomi dei clienti di Prisma: nella risposta solo quelli già scritti nella domanda.
    static func leggi(_ json: String, passi: [PassoPerVera], domanda: String, nomiClienti: [String] = []) -> EsitoTrovaPagina? {
        guard let i = json.firstIndex(of: "{"), let f = json.lastIndex(of: "}"), i < f,
              let d = String(json[i...f]).data(using: .utf8), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let trovato = j["trovato"] as? Bool else { return nil }
        guard trovato else { return .nonTrovata }
        let etichetta = ((j["passo"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "").uppercased()
        let frase = MotoreBiblioteca.frasePulita((j["frase"] as? String) ?? "")
        let testo = ((j["risposta"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        // Un passo che non è tra quelli dati: la risposta non vale (si mostra il primo passo trovato)
        guard let p = passi.first(where: { $0.etichetta == etichetta }) else {
            guard let primo = passi.first else { return .nonTrovata }
            return .nonVerificata(passo: primo.passo, motivo: "Vera ha citato un passo che Prisma non le aveva dato.")
        }
        guard !testo.isEmpty else { return nil }
        guard MotoreBiblioteca.fraseNelPasso(frase, p.passo) else {
            return .nonVerificata(passo: p.passo, motivo: "Vera non ha trovato una frase che lo dica esattamente.")
        }
        let fonte = p.passo.testo + "\n" + p.passo.intestazione
        guard CommentoVera.numeriConservati(bozza: fonte, testo: testo) else {
            return .nonVerificata(passo: p.passo, motivo: "La risposta di Vera aveva una cifra che non è nel passo.")
        }
        if nomeAggiunto(testo, domanda: domanda, nomi: nomiClienti) {
            return .nonVerificata(passo: p.passo, motivo: "La risposta di Vera nominava un cliente che non era nella domanda.")
        }
        return .risposta(passo: p.passo, frase: frase, testo: testo)
    }

    /// Un nome di cliente nella risposta che non è nella domanda (Vera non personalizza da sola: decisione 6).
    static func nomeAggiunto(_ testo: String, domanda: String, nomi: [String]) -> Bool {
        let parole = Set(MotoreBiblioteca.paroleSemplici(testo))
        let chieste = Set(MotoreBiblioteca.paroleSemplici(domanda))
        return nomi.flatMap { MotoreBiblioteca.paroleSemplici($0) }.filter { $0.count >= 3 }
            .contains { parole.contains($0) && !chieste.contains($0) }
    }

    /// Chiede a Qwen e verifica la risposta (una volta sola: con un JSON guasto si riprova una volta).
    static func chiedi(motore: MotoreLocale, vera: ImpostazioniVera, domanda: String, passi: [PassoPerVera],
                       nomiClienti: [String]) async throws -> EsitoTrovaPagina {
        let messaggi = messaggi(domanda, passi: passi)
        for _ in 0..<2 {
            let json = try await motore.scrivi(messaggi, opzioni: opzioni(vera)).testo
            if let esito = leggi(json, passi: passi, domanda: domanda, nomiClienti: nomiClienti) { return esito }
        }
        guard let primo = passi.first else { return .nonTrovata }
        return .nonVerificata(passo: primo.passo, motivo: "Vera non ha dato una risposta leggibile.")
    }

    // MARK: - «Cerca nella Biblioteca» da Vera (§8.1.5.2 punto 6)

    /// Le parole delle condizioni e dei documenti di prodotto: riscatto, penali, carenze, franchigie, esclusioni,
    /// massimali, premi non pagati, deducibilità, KID, set informativo, nota informativa, circolari, condizioni.
    private static let paroleCondizioni = #"\b(condizion\w*|riscatt\w*|penal[ei]\b|penalit\w*|carenz\w*|franchigi\w*|esclusion\w*|massimal\w*|non pag\w*|sospension\w*|rivalutazion\w*|deduc\w*|kid\b|set informativo|nota informativa|circolar\w*|recesso)"#

    /// Una domanda su condizioni o normativa a cui la Biblioteca può rispondere con la pagina («Il riscatto nei primi
    /// anni ha penali?», «Cosa dice la norma sul recesso?»): una domanda (punto di domanda o «cosa dice…») con le parole
    /// delle condizioni, oppure una domanda sulle norme come per «Il codice in tasca» (`NormeVera.eUnaDomanda`).
    static func proponeBiblioteca(_ domanda: String, clienti: [ClienteNoto] = []) -> Bool {
        if NormeVera.eUnaDomanda(domanda, clienti: clienti) { return true }
        let t = InterpreteComandi.pulisci(domanda)
        guard domanda.contains("?") || DateItaliane.cerca(#"^(cosa dice|che dice|cosa dicono|che dicono|secondo|in base a)"#, t) != nil else { return false }
        return DateItaliane.cerca(paroleCondizioni, t) != nil
    }
}
