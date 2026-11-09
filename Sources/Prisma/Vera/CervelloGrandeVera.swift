import Foundation

// «Il cervello grande» (Vera/BRIEF.md, fase 5, funzione 25): l'aggancio a un motore esterno, più grande, per le domande
// generali. In questa fase è predisposto e NON collegato: nessuna richiesta parte, nessuna chiave è salvata. Le regole
// sono bloccate nel codice e non si spengono dalle impostazioni: i dati dei clienti non escono mai dal Mac, il motore
// esterno riceve solo domande della modalità conversazione (senza schede, documenti o numeri dei clienti) e sotto ogni
// risposta c'è l'etichetta di chi l'ha scritta.

/// Che tipo di motore esterno l'utente collegherà un domani (solo la scelta: resta non collegato).
enum TipoMotoreEsterno: String, Codable, CaseIterable, Identifiable {
    /// Un modello grande su un tuo computer o server.
    case server
    /// Un servizio a pagamento.
    case servizio

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .server: return "Un tuo server"
        case .servizio: return "Un servizio a pagamento"
        }
    }

    var spiegazione: String {
        switch self {
        case .server: return "Un modello grande su un tuo computer: le domande generali restano tue, anche fuori dal Mac."
        case .servizio: return "Un servizio in cloud, a pagamento: riceve solo le domande generali, mai i dati dei clienti."
        }
    }
}

/// Le impostazioni del motore esterno: solo il tipo scelto. Nessun indirizzo, nessuna chiave (quando l'utente collegherà,
/// la chiave andrà nel Portachiavi, mai nell'archivio).
struct ImpostazioniMotoreEsterno: Codable, Equatable {
    var tipo = TipoMotoreEsterno.server

    init() {}

    private enum CodingKeys: String, CodingKey { case tipo }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tipo = (try? c.decodeIfPresent(TipoMotoreEsterno.self, forKey: .tipo)) ?? .server
    }
}

// MARK: - Il guardiano (regole bloccate nel codice)

/// I soli messaggi che un motore esterno può ricevere. L'inizializzatore è `fileprivate`: li crea solo
/// `CervelloGrandeVera.guardiano`, in questo file. Nessun altro file può costruire messaggi per il motore esterno: è un
/// errore di compilazione, non una regola a parole.
struct MessaggiAmmessi: Equatable {
    let messaggi: [MessaggioModello]
    fileprivate init(_ m: [MessaggioModello]) { messaggi = m }
}

/// L'esito del guardiano: i messaggi ammessi, o perché la domanda resta sul Mac.
enum EsitoGuardiano: Equatable {
    case ammesso(MessaggiAmmessi)
    case bloccato(String)

    var messaggi: [MessaggioModello]? {
        if case .ammesso(let m) = self { return m.messaggi }
        return nil
    }
}

/// Un motore esterno: riceve solo `MessaggiAmmessi`.
protocol MotoreEsternoVera {
    var nome: String { get }
    func scrivi(_ messaggi: MessaggiAmmessi) async throws -> String
}

/// L'unico motore esterno di questa fase: non collegato. Non costruisce richieste (nessun indirizzo, nessuna chiave) e
/// lancia sempre un errore.
struct MotoreEsternoNonCollegato: MotoreEsternoVera {
    var nome: String { CervelloGrandeVera.nome }

    func scrivi(_ messaggi: MessaggiAmmessi) async throws -> String {
        throw ErroreVera(messaggio: CervelloGrandeVera.nonCollegato)
    }
}

enum CervelloGrandeVera {
    /// Nessuna richiesta parte: il motore esterno non è collegato. Si cambia solo quando l'utente deciderà di collegarlo.
    static let collegamentoAmmesso = false
    static let nome = "Motore esterno"
    static let nonCollegato = "Il motore esterno non è collegato: oggi Vera lavora tutta sul Mac."
    /// Le battute di conversazione portate al motore esterno, al massimo.
    static let massimoBattute = 12

    /// Le tre regole della pagina, tutte bloccate (non si spengono dalle impostazioni).
    static let regole: [(titolo: String, sotto: String, avviso: String)] = [
        ("I dati dei clienti non escono mai dal Mac", "Questa regola non si può spegnere", "Questa regola non si spegne: i dati dei clienti restano sul Mac"),
        ("Il motore esterno lavora solo nelle conversazioni generali", "Schede, documenti e numeri restano a Qwen",
         "Questa regola non si spegne: schede, documenti e numeri restano a Qwen"),
        ("Mostra sempre chi sta rispondendo", "Un'etichetta sotto ogni risposta", "Questa regola non si spegne: sotto ogni risposta c'è chi l'ha scritta"),
    ]

    /// Un testo con un dato di un cliente (nomi, email, telefoni, codici fiscali, date di nascita, numeri di documenti) o
    /// con le parti che Prisma aggiunge alle domande di lavoro.
    static func haDatiDeiClienti(_ testo: String, identificativi: IdentificativiClienti) -> Bool {
        if identificativi.contiene(testo) || MemoriaVera.vietato(testo) != nil { return true }
        if !AnonimizzatoreVera.intervalli(schema: AnonimizzatoreVera.schemaEmail, in: testo).isEmpty
            || !AnonimizzatoreVera.intervalli(schema: AnonimizzatoreVera.schemaCodiceFiscale, in: testo).isEmpty
            || !AnonimizzatoreVera.intervalli(schema: AnonimizzatoreVera.schemaTelefono, in: testo).isEmpty { return true }
        let segni = ["CONTESTO:", "SCHEDA DEL CLIENTE", "cliente attivo", "BOZZA PREPARATA DA PRISMA", "CALCOLI DI PRISMA",
                     "DAI DOCUMENTI E DALLE NOTE", "RICORDI (", "IL FILO DELLA CONVERSAZIONE"]
        return segni.contains { testo.localizedCaseInsensitiveContains($0) }
    }

    /// Ricostruisce i messaggi per il motore esterno: le istruzioni della conversazione, le sole battute di conversazione
    /// senza dati dei clienti, la domanda senza riga di contesto, senza scheda, brani, ricordi o riassunto. Blocca il
    /// collegamento spento, la modalità cliente, la modalità lavoro e ogni domanda con un dato di un cliente.
    static func guardiano(domanda: String, scelta: SceltaVera, storia: [MessaggioVera], inModoCliente: Bool,
                          identificativi: IdentificativiClienti, ammesso: Bool = collegamentoAmmesso) -> EsitoGuardiano {
        guard ammesso else { return .bloccato(nonCollegato) }
        guard !inModoCliente else { return .bloccato("In modalità cliente risponde solo Vera sul Mac.") }
        guard scelta.modalita == .conversazione, !scelta.conScheda else { return .bloccato("Schede, documenti e numeri restano a Qwen, sul Mac.") }
        let d = domanda.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !d.isEmpty else { return .bloccato("Nessuna domanda.") }
        guard !haDatiDeiClienti(d, identificativi: identificativi) else { return .bloccato("La domanda contiene un dato di un cliente: resta sul Mac.") }
        // Le battute: una tua domanda entra solo se la risposta di Vera che la segue era di conversazione; mai le risposte
        // delle regole e dei calcoli di Prisma, mai una battuta con un dato di un cliente
        var battute: [MessaggioModello] = []
        for (i, m) in storia.enumerated() {
            let pulita = !haDatiDeiClienti(m.testo, identificativi: identificativi)
            switch m.autore {
            case .utente:
                let risposta = storia[(i + 1)...].first { $0.autore == .vera }
                guard pulita, let r = risposta, r.modalita == .conversazione, CorsiaVera.da(motore: r.motore) != .regole else { continue }
                battute.append(MessaggioModello(ruolo: .utente, testo: m.testo))
            case .vera:
                guard pulita, m.modalita == .conversazione, CorsiaVera.da(motore: m.motore) != .regole, m.fonti == nil else { continue }
                // Solo dopo una tua domanda ammessa (le battute restano alternate)
                guard battute.last?.ruolo == .utente else { continue }
                battute.append(MessaggioModello(ruolo: .assistente, testo: m.testo))
            }
        }
        if battute.last?.ruolo == .utente { battute.removeLast() }
        let sistema = MessaggioModello(ruolo: .sistema, testo: IstruzioniVera.conversazione)
        return .ammesso(MessaggiAmmessi([sistema] + battute.suffix(massimoBattute) + [MessaggioModello(ruolo: .utente, testo: d)]))
    }
}

// MARK: - L'etichetta sotto ogni risposta (regola bloccata: sempre visibile)

/// Chi ha scritto una risposta: testo e tono dell'etichetta sotto la bolla.
struct EtichettaMotore: Equatable {
    enum Tono: Equatable {
        /// Un modello sul Mac (verde).
        case sulMac
        /// Il motore esterno (blu).
        case esterno
        /// Regole e calcoli di Prisma, senza modello (grigio).
        case prisma
    }

    var testo: String
    var tono: Tono

    /// nil per i messaggi dell'utente e per quelli senza motore.
    static func per(_ m: MessaggioVera) -> EtichettaMotore? {
        guard m.autore == .vera, let motore = m.motore, !motore.isEmpty else { return nil }
        switch CorsiaVera.da(motore: motore) {
        case .regole: return EtichettaMotore(testo: "Sul Mac · regole e calcoli di Prisma", tono: .prisma)
        case .esterno: return EtichettaMotore(testo: "Motore esterno · nessun dato dei clienti", tono: .esterno)
        case .apple: return EtichettaMotore(testo: "Sul Mac · modello Apple", tono: .sulMac)
        case .qwen:
            let nome = motore.hasSuffix(" sul Mac") ? String(motore.dropLast(" sul Mac".count)) : motore
            if nome == "Vera su misura" { return EtichettaMotore(testo: "Sul Mac · Vera su misura", tono: .sulMac) }
            return EtichettaMotore(testo: "Sul Mac · \(nome)" + (m.modalita == .lavoro ? " · dati del cliente" : ""), tono: .sulMac)
        }
    }
}
