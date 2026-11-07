import Foundation

// Prisma ovunque (Design/ovunque-fattibilita.md §4.3, giro 8): la tabella dei campi sincronizzabili, scritta a mano per
// ogni tipo, e la lettura e scrittura di un campo per nome. Niente riflessione: ogni oggetto passa dalla sua codifica
// Codable (la stessa dell'archivio) a un dizionario JSON e ritorno, e si toccano solo i campi elencati qui.
// I valori si confrontano come JSON canonico (chiavi ordinate, date ISO 8601 al secondo): uguali sul Mac e sul telefono.

/// Il JSON dello spazio: codifica compatta e canonica, la stessa su Mac, iPhone e iPad.
enum JSONOvunque {
    /// Un codificatore nuovo (ognuno il suo: lo spazio lavora anche fuori dal thread principale).
    static func codificatore() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        e.dateEncodingStrategy = .iso8601
        e.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return e
    }

    static func decodificatore() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return d
    }

    static let nullo = "null"

    /// Il JSON canonico di un valore (nil o nullo → "null").
    static func canonico(_ valore: Any?) -> String {
        guard let valore, !(valore is NSNull) else { return nullo }
        guard let dati = try? JSONSerialization.data(withJSONObject: valore, options: [.sortedKeys, .fragmentsAllowed]),
              let testo = String(data: dati, encoding: .utf8) else { return nullo }
        return testo
    }

    /// Il valore di un JSON canonico (nil per "null" o per un testo non valido).
    static func valore(_ testo: String?) -> Any? {
        guard let testo, testo != nullo,
              let v = try? JSONSerialization.jsonObject(with: Data(testo.utf8), options: [.allowFragments]),
              !(v is NSNull) else { return nil }
        return v
    }

    static func oggetto(_ testo: String?) -> [String: Any]? {
        valore(testo) as? [String: Any]
    }

    /// Imposta un campo dal suo JSON canonico ("null" lo toglie: come un facoltativo senza valore).
    static func imposta(_ oggetto: inout [String: Any], _ campo: String, _ testo: String) {
        if let v = valore(testo) {
            oggetto[campo] = v
        } else {
            oggetto.removeValue(forKey: campo)
        }
    }

    /// Un oggetto Codable come dizionario JSON.
    static func dizionario<T: Encodable>(_ x: T, con codificatore: JSONEncoder) -> [String: Any]? {
        guard let dati = try? codificatore.encode(x) else { return nil }
        return (try? JSONSerialization.jsonObject(with: dati)) as? [String: Any]
    }

    /// Un dizionario JSON come oggetto Codable (nil se non si legge).
    static func decodifica<T: Decodable>(_ tipo: T.Type, da json: [String: Any]) -> T? {
        guard JSONSerialization.isValidJSONObject(json), let dati = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return try? decodificatore().decode(tipo, from: dati)
    }
}

/// I campi sincronizzabili di ogni tipo e l'accesso agli oggetti dell'archivio per id.
enum CampiOvunque {
    struct Regole {
        /// Le chiavi JSON che il dispositivo può cambiare (il resto arriva solo con l'istantanea).
        let campi: [String]
        /// Date di servizio (ultima modifica): non fanno conflitto, vale la più recente.
        let servizio: Set<String>
        let creabile: Bool
        let eliminabile: Bool
        /// L'oggetto appartiene a un cliente (`clienteId`): senza il cliente sul Mac non entra (niente orfani).
        let conCliente: Bool
    }

    static func regole(_ e: EntitaOvunque) -> Regole {
        switch e {
        case .nota:
            return Regole(campi: ["clienteId", "titolo", "testo", "fissata", "aggiornataIl"], servizio: ["aggiornataIl"],
                          creabile: true, eliminabile: true, conCliente: true)
        case .attivita:
            return Regole(campi: ["clienteId", "titolo", "scadenza", "priorita", "completata", "note", "appuntamentoId"], servizio: [],
                          creabile: true, eliminabile: true, conCliente: true)
        case .appuntamento:
            return Regole(campi: ["clienteId", "titolo", "inizio", "durataMinuti", "luogo", "note", "stato", "tipo", "canale", "posizioneId"],
                          servizio: [], creabile: true, eliminabile: true, conCliente: true)
        case .bisogni:
            // Il profilo dei bisogni non si crea né si elimina: c'è con il cliente (id = id del cliente)
            return Regole(campi: ["valutazioni", "eventi", "esiti", "aggiornatoIl"], servizio: ["aggiornatoIl"],
                          creabile: false, eliminabile: false, conCliente: false)
        case .eventoVita:
            return Regole(campi: ["clienteId", "tipo", "eta", "anno", "importo", "durataAnni", "titolo", "nota", "origine"], servizio: [],
                          creabile: true, eliminabile: true, conCliente: true)
        case .sessioneCopilota:
            // Mai la trascrizione: schede (senza le frasi del cliente), verbale e attività create
            return Regole(campi: ["incontroId", "schede", "verbale", "attivitaCreate", "conclusaIl"], servizio: [],
                          creabile: true, eliminabile: false, conCliente: true)
        case .inquadratura:
            return Regole(campi: ["clienteId"], servizio: [], creabile: true, eliminabile: true, conCliente: true)
        }
    }

    /// Solo i campi sincronizzati (senza quelli di servizio): l'oggetto «visto» da un'eliminazione.
    static func ristretto(_ oggetto: [String: Any], _ regole: Regole) -> [String: Any] {
        var r: [String: Any] = [:]
        for campo in regole.campi where !regole.servizio.contains(campo) {
            if let v = oggetto[campo], !(v is NSNull) { r[campo] = v }
        }
        return r
    }

    /// Gli oggetti di un tipo nell'archivio, per id, come dizionari JSON.
    static func oggetti(_ e: EntitaOvunque, in d: DatiPrisma) -> [String: [String: Any]] {
        let c = JSONOvunque.codificatore()
        switch e {
        case .nota: return dizionari(d.note, c)
        case .attivita: return dizionari(d.attivita, c)
        case .appuntamento: return dizionari(d.appuntamenti, c)
        case .eventoVita: return dizionari(d.eventiVita, c)
        case .sessioneCopilota: return dizionari(d.sessioniCopilota.map(senzaTrascrizione), c)
        case .inquadratura: return dizionari(d.inquadratureDaConfermare, c)
        case .bisogni:
            var r: [String: [String: Any]] = [:]
            for cliente in d.clienti {
                if let o = JSONOvunque.dizionario(cliente.bisogni, con: c) { r[cliente.id] = o }
            }
            return r
        }
    }

    /// Un oggetto per id (nil se non c'è).
    static func oggetto(_ e: EntitaOvunque, id: String, in d: DatiPrisma) -> [String: Any]? {
        let c = JSONOvunque.codificatore()
        switch e {
        case .nota: return d.note.first { $0.id == id }.flatMap { JSONOvunque.dizionario($0, con: c) }
        case .attivita: return d.attivita.first { $0.id == id }.flatMap { JSONOvunque.dizionario($0, con: c) }
        case .appuntamento: return d.appuntamenti.first { $0.id == id }.flatMap { JSONOvunque.dizionario($0, con: c) }
        case .eventoVita: return d.eventiVita.first { $0.id == id }.flatMap { JSONOvunque.dizionario($0, con: c) }
        case .sessioneCopilota:
            return d.sessioniCopilota.first { $0.id == id }.map(senzaTrascrizione).flatMap { JSONOvunque.dizionario($0, con: c) }
        case .inquadratura: return d.inquadratureDaConfermare.first { $0.id == id }.flatMap { JSONOvunque.dizionario($0, con: c) }
        case .bisogni: return d.clienti.first { $0.id == id }.flatMap { JSONOvunque.dizionario($0.bisogni, con: c) }
        }
    }

    /// Scrive (sostituisce o aggiunge) un oggetto dal suo dizionario. false se il dizionario non si legge.
    @discardableResult
    static func scrivi(_ e: EntitaOvunque, id: String, json: [String: Any], in d: inout DatiPrisma) -> Bool {
        switch e {
        case .nota: return metti(json, id: id, in: &d.note)
        case .attivita: return metti(json, id: id, in: &d.attivita)
        case .appuntamento: return metti(json, id: id, in: &d.appuntamenti)
        case .eventoVita: return metti(json, id: id, in: &d.eventiVita)
        case .inquadratura: return metti(json, id: id, in: &d.inquadratureDaConfermare)
        case .bisogni:
            guard let i = d.clienti.firstIndex(where: { $0.id == id }),
                  let profilo = JSONOvunque.decodifica(ProfiloBisogni.self, da: json) else { return false }
            d.clienti[i].bisogni = profilo
            return true
        case .sessioneCopilota:
            guard var nuova = JSONOvunque.decodifica(SessioneCopilota.self, da: json), nuova.id == id else { return false }
            if let i = d.sessioniCopilota.firstIndex(where: { $0.id == id }) {
                // Sul Mac la trascrizione conservata resta: il dispositivo non la vede e non la tocca
                let vecchia = d.sessioniCopilota[i]
                if vecchia.conservaTrascrizione {
                    nuova.conservaTrascrizione = true
                    nuova.trascrizione = vecchia.trascrizione
                    for j in nuova.schede.indices where nuova.schede[j].frase.isEmpty {
                        if let prima = vecchia.scheda(nuova.schede[j].id) {
                            nuova.schede[j].frase = prima.frase
                            nuova.schede[j].evidenze = prima.evidenze
                        }
                    }
                }
                d.sessioniCopilota[i] = nuova
            } else {
                d.sessioniCopilota.append(nuova)
            }
            return true
        }
    }

    /// Toglie un oggetto. false se non c'era.
    @discardableResult
    static func togli(_ e: EntitaOvunque, id: String, in d: inout DatiPrisma) -> Bool {
        func via<T: Identifiable>(_ elenco: inout [T]) -> Bool where T.ID == String {
            let prima = elenco.count
            elenco.removeAll { $0.id == id }
            return elenco.count != prima
        }
        switch e {
        case .nota: return via(&d.note)
        case .attivita: return via(&d.attivita)
        case .appuntamento: return via(&d.appuntamenti)
        case .eventoVita: return via(&d.eventiVita)
        case .sessioneCopilota: return via(&d.sessioniCopilota)
        case .inquadratura: return via(&d.inquadratureDaConfermare)
        case .bisogni: return false
        }
    }

    // MARK: - Parti

    /// La sessione come la vede lo spazio: senza trascrizione né frasi del cliente.
    static func senzaTrascrizione(_ s: SessioneCopilota) -> SessioneCopilota {
        var x = s
        x.dimenticaTrascrizione()
        x.conservaTrascrizione = false
        return x
    }

    private static func dizionari<T: Encodable & Identifiable>(_ elenco: [T], _ c: JSONEncoder) -> [String: [String: Any]] where T.ID == String {
        var r: [String: [String: Any]] = [:]
        for x in elenco {
            if let o = JSONOvunque.dizionario(x, con: c) { r[x.id] = o }
        }
        return r
    }

    private static func metti<T: Decodable & Identifiable>(_ json: [String: Any], id: String, in elenco: inout [T]) -> Bool where T.ID == String {
        guard let x = JSONOvunque.decodifica(T.self, da: json), x.id == id else { return false }
        if let i = elenco.firstIndex(where: { $0.id == id }) {
            elenco[i] = x
        } else {
            elenco.append(x)
        }
        return true
    }
}
