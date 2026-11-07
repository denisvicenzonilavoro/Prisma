import Foundation

/// Il motore di Vera: il modello sul Mac, raggiunto con il fornitore scelto (Ollama o un server compatibile
/// OpenAI), sempre a un indirizzo del Mac stesso: nessun dato dei clienti esce dal computer.
/// Sul MacBook Pro M1 da 8 GB la taglia giusta è la 4B (circa 3,5 GB di memoria mentre lavora).
struct MotoreLocale: MotoreVera, MotoreGenerativo {
    static let indirizzoPredefinito = FornitoreOllama.indirizzoPredefinito
    /// Qwen 3.5 da 4 miliardi di parametri (ollama.com/library/qwen3.5).
    static let modelloPredefinito = "qwen3.5:4b"
    /// Il modello predefinito delle versioni di prima: chi non l'aveva cambiato passa al nuovo.
    static let modelloPrecedente = "qwen3:4b"
    /// Dopo l'ultima risposta il modello resta in memoria per un po', poi la RAM torna libera.
    static let restaInMemoria = "10m"
    /// Il ragionamento può tacere a lungo prima della prima parola.
    static let attesaMassima: TimeInterval = 180

    let fornitore: FornitoreModello
    let disponibilita: DisponibilitaVera
    let restaInMemoria: String

    init(_ vera: ImpostazioniVera, disponibilita: DisponibilitaVera, sessione: URLSession = .shared) {
        // Con la sessione di sempre il fornitore di questo dispositivo (su iPhone e iPad il ponte verso il Mac);
        // con una sessione data (le prove, il server finto) quello delle impostazioni, come sul Mac
        fornitore = sessione === URLSession.shared ? FornitoriVera.diQuestoDispositivo(vera) : FornitoriVera.crea(vera, sessione: sessione)
        self.disponibilita = disponibilita
        restaInMemoria = vera.restaInMemoria
    }

    var modello: String { fornitore.modello }

    /// «Qwen sul Mac», «Gemma sul Mac»…: il nome del modello, senza la taglia.
    var nome: String { Self.nome(modello) }

    static func nome(_ modello: String) -> String {
        let famiglia = modello.split(separator: ":").first.map(String.init) ?? modello
        let lettere = famiglia.prefix { $0.isLetter }
        return lettere.isEmpty ? "Modello sul Mac" : String(lettere.prefix(1)).uppercased() + String(lettere.dropFirst()) + " sul Mac"
    }

    #if os(iOS)
    var descrizione: String { "\(modello) sul Mac, in Wi‑Fi e cifrato: nessun dato esce dai tuoi dispositivi." }
    #else
    var descrizione: String { "\(modello) con \(fornitore.nome), sul Mac: nessun dato esce dal computer." }
    #endif

    // MARK: - Disponibilità

    /// Pronto se il fornitore risponde e ha il modello scelto.
    static func verifica(_ vera: ImpostazioniVera) async -> DisponibilitaVera {
        let f = FornitoriVera.crea(vera)
        guard IndirizzoLocale.url(f.indirizzo) != nil else {
            return .nonDisponibile("L'indirizzo di \(f.nome) deve essere sul Mac (127.0.0.1): un altro computer riceverebbe i dati dei clienti.")
        }
        return await f.verifica()
    }

    /// Pronto su questo dispositivo: sul Mac il modello locale; su iPhone e iPad Qwen del Mac abbinato, in rete
    /// locale (PonteVera). Se il Mac non c'è, Vera lo dice e non risponde.
    static func verificaDispositivo(_ vera: ImpostazioniVera) async -> DisponibilitaVera {
        #if os(iOS)
        return await PonteVera.collega(vera)
        #else
        return await verifica(vera)
        #endif
    }

    // MARK: - Risposte

    /// Una risposta intera, per commenti e spiegazioni (modalità lavoro, senza ragionamento).
    func genera(istruzioni: String, richiesta: String) async throws -> String {
        var opzioni = OpzioniModello()
        // La stessa finestra di tutte le chiamate (Ollama non ricarica il modello); niente lezioni nelle estrazioni a righe fisse
        opzioni.contesto = NucleoVera.finestra
        opzioni.conLezioni = false
        opzioni.restaInMemoria = restaInMemoria
        return try await scrivi([MessaggioModello(ruolo: .sistema, testo: istruzioni), MessaggioModello(ruolo: .utente, testo: richiesta)],
                                opzioni: opzioni).testo
    }

    func rispondi(_ r: RichiestaVera) async throws -> RispostaVera {
        var vera = ImpostazioniVera()
        vera.restaInMemoria = restaInMemoria
        let testo = try await scrivi(NucleoVera.piano(r, impostazioni: vera, ambiente: AmbienteVera(cliente: r.fonte.cliente.nome))).testo
        return RispostaVera(titolo: nil, testo: testo)
    }

    func scrivi(_ piano: PianoVera, aggiorna: ((ParzialeVera) -> Void)? = nil) async throws -> (testo: String, statistiche: StatisticheModello?) {
        try await scrivi(piano.messaggi, opzioni: piano.opzioni, aggiorna: aggiorna)
    }

    /// La risposta mentre arriva: `aggiorna` riceve il testo visibile fin qui (senza ragionamento) al massimo
    /// una volta ogni `intervalloAggiornamenti`, così l'interfaccia non ridisegna a ogni parola.
    func scrivi(_ messaggi: [MessaggioModello], opzioni: OpzioniModello,
                aggiorna: ((ParzialeVera) -> Void)? = nil) async throws -> (testo: String, statistiche: StatisticheModello?) {
        let r = try await raccogli(messaggi, opzioni: opzioni, aggiorna: aggiorna)
        guard !r.testo.isEmpty else {
            throw ErroreVera(messaggio: "Il modello non ha prodotto una risposta. Riprova con una domanda più precisa.")
        }
        return (r.testo, r.statistiche)
    }

    /// Una risposta con gli strumenti (OpzioniModello.strumenti): il testo, se c'è, e le chiamate chieste dal modello.
    /// Un turno di sole chiamate è valido; senza testo né chiamate il modello non ha risposto.
    func chiediConStrumenti(_ messaggi: [MessaggioModello], opzioni: OpzioniModello) async throws -> RispostaConStrumenti {
        let r = try await raccogli(messaggi, opzioni: opzioni, aggiorna: nil)
        guard !r.testo.isEmpty || !r.chiamate.isEmpty else {
            throw ErroreVera(messaggio: "Il modello non ha prodotto una risposta. Riprova con una richiesta più precisa.")
        }
        return r
    }

    private func raccogli(_ messaggi: [MessaggioModello], opzioni: OpzioniModello,
                          aggiorna: ((ParzialeVera) -> Void)?) async throws -> RispostaConStrumenti {
        // «Impara dalle correzioni»: le lezioni del consulente in fondo alle istruzioni di ogni risposta a testo libero
        let messaggi = LezioniVera.applica(messaggi, opzioni: opzioni)
        var chiamate: [ChiamataStrumento] = []
        var filtro = FiltroPensiero()
        var testo = "", pensiero = ""
        var statistiche: StatisticheModello?
        var ultimo = Date.distantPast
        var parlato = false
        for try await pezzo in fornitore.flusso(messaggi, opzioni: opzioni) {
            switch pezzo {
            case .testo(let t):
                let f = filtro.filtra(t)
                testo += f.testo
                pensiero += f.ragionamento
            case .ragionamento(let t):
                pensiero += t
            case .strumento(let c):
                // «Fallo tu»: le azioni chieste dal modello (RegistroStrumenti); Prisma le esegue solo dopo «Conferma»
                chiamate.append(c)
            case .fine(let s):
                statistiche = s
            }
            // La prima parola si vede subito, poi al massimo un aggiornamento ogni `intervalloAggiornamenti`
            let prima = !testo.isEmpty && !parlato
            if let aggiorna, prima || Date().timeIntervalSince(ultimo) >= Self.intervalloAggiornamenti {
                ultimo = Date()
                parlato = !testo.isEmpty
                aggiorna(ParzialeVera(testo: NucleoVera.pulisci(testo), pensa: !pensiero.isEmpty))
            }
        }
        testo += filtro.svuota()
        let finale = NucleoVera.pulisci(testo)
        aggiorna?(ParzialeVera(testo: finale, pensa: !pensiero.isEmpty))
        return RispostaConStrumenti(testo: finale, chiamate: chiamate, statistiche: statistiche)
    }

    static let intervalloAggiornamenti: TimeInterval = 0.06
}

/// Una risposta del modello con gli strumenti: il testo visibile e le chiamate chieste.
struct RispostaConStrumenti {
    var testo: String
    var chiamate: [ChiamataStrumento]
    var statistiche: StatisticheModello?
}

/// Il testo di una risposta mentre arriva.
struct ParzialeVera: Equatable {
    var testo: String
    /// Il modello sta ragionando (o ha ragionato) prima di rispondere.
    var pensa: Bool
}
