import Foundation

// Pratiche › Moduli · la revisione della mappa (Design/template-luce-specifica.md §7.2.5 punto 2c, «Luce» giro 10,
// decisione 54): Vera (Qwen sul Mac) propone il dato per le etichette che le regole di Prisma non hanno riconosciuto.
// A Qwen va solo il testo delle etichette del modulo vuoto, mai un dato del cliente (Vera/Istruzioni/moduli.md,
// Vera/Schemi/modulo.json). Prisma tiene solo le etichette che aveva dato e i codici di `DatoModulo`, mai per le
// risposte del cliente (le regole vincono: decisione 62), e ogni proposta resta da confermare. Senza Qwen: regole e mano.

enum ModuliVera {
    static let schema: [String: Any] = {
        let campo: [String: Any] = ["type": "object",
                                    "properties": ["etichetta": ["type": "string"], "dato": ["type": "string"]],
                                    "required": ["etichetta", "dato"]]
        return ["type": "object", "properties": ["campi": ["type": "array", "items": campo]], "required": ["campi"]]
    }()

    static var istruzioni: String {
        IstruzioniVera.testo("moduli") ?? "Per ogni etichetta di un modulo vuoto proponi il codice del dato del dossier che va nella casella, scegliendo solo tra: \(DatoModulo.allCases.map(\.rawValue).joined(separator: ", ")). Rispondi solo con il JSON: campi, elenco di {etichetta, dato}; dato \"\" se nessun codice va bene, sempre \"\" per firme, questionario e dichiarazioni antiriciclaggio (titolare effettivo, PEP, scopo del rapporto, origine dei fondi)."
    }

    /// Le etichette, una per riga: nient'altro.
    static func messaggi(_ etichette: [String]) -> [MessaggioModello] {
        [MessaggioModello(ruolo: .sistema, testo: istruzioni),
         MessaggioModello(ruolo: .utente, testo: "ETICHETTE DEL MODULO VUOTO\n" + etichette.map { "- \($0)" }.joined(separator: "\n"))]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.1
        o.contesto = NucleoVera.finestra
        o.massimoToken = 800
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        o.conLezioni = false
        return o
    }

    /// Le proposte verificate: solo etichette date, solo codici di `DatoModulo`, mai per le etichette che le regole
    /// dicono risposte del cliente o firme. nil = JSON non valido.
    static func leggi(_ json: String, etichette: [String]) -> [String: DatoModulo]? {
        guard let i = json.firstIndex(of: "{"), let f = json.lastIndex(of: "}"), i < f,
              let d = String(json[i...f]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              let campi = j["campi"] as? [[String: Any]] else { return nil }
        let date = Set(etichette)
        var r: [String: DatoModulo] = [:]
        for c in campi {
            guard let e = (c["etichetta"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), date.contains(e),
                  let codice = c["dato"] as? String, let dato = DatoModulo(rawValue: codice) else { continue }
            switch RiconoscitoreModulo.associa(e) {
            case .risposta?, .firma?: continue
            default: break
            }
            if r[e] == nil { r[e] = dato }
        }
        return r
    }

    /// Applica la proposta di Vera a una casella senza dato: da confermare.
    static func applica(_ proposte: [String: DatoModulo], a c: inout ModelloModulo.Campo) {
        guard c.dato == nil, !c.risposta, !c.firma, let d = proposte[c.etichetta] else { return }
        c.dato = d
        c.origine = .vera
        c.daConfermare = true
    }

    /// Chiede a Qwen (una volta; con un JSON guasto si riprova una volta).
    static func chiedi(motore: MotoreLocale, vera: ImpostazioniVera, etichette: [String]) async throws -> [String: DatoModulo] {
        guard !etichette.isEmpty else { return [:] }
        for _ in 0..<2 {
            let json = try await motore.scrivi(messaggi(etichette), opzioni: opzioni(vera)).testo
            if let r = leggi(json, etichette: etichette) { return r }
        }
        return [:]
    }
}
