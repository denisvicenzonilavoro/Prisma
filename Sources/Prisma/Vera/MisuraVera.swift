import Foundation

/// La misura dei tempi di Vera sul Mac (giro 0 di «Prisma istantaneo»): quanto ci mette Qwen a caricarsi da zero,
/// quanto a dire la prima parola e quante parole scrive al secondo. Da Impostazioni › Strumenti › «Misura Vera»,
/// con lo stesso FornitoreModello di Vera (Ollama sul Mac, solo indirizzi locali) e le stesse opzioni delle sue
/// risposte (la finestra `NucleoVera.finestra`, la memoria scelta): così la misura dice anche se una domanda dopo
/// il caricamento fa ricaricare il modello. La domanda è fissa e generica: nessun dato dei clienti.
///
/// I passi, ognuno con l'orologio dato (le prove lo fingono):
/// 1. il fornitore è pronto? Se no, la misura lo dice con il messaggio di Vera («Ollama non è aperto…»);
/// 2. il modello si libera e si ricarica: il caricamento da zero;
/// 3. la prima domanda, subito dopo il caricamento: la prima parola (se è molto più lenta della seconda, il modello
///    si è ricaricato per opzioni diverse);
/// 4. la seconda domanda, con il modello già pronto: la prima parola e le parole al secondo.
enum MisuraVera {
    /// La domanda delle due misure: generica, senza dati dei clienti.
    static let domanda = "Spiega in tre frasi semplici che cos'è l'interesse composto."
    static let istruzioni = "Rispondi in italiano, in modo semplice e breve."
    /// Abbastanza parole per una velocità affidabile, senza far aspettare troppo.
    static let massimoToken = 160

    /// I tempi misurati (secondi), nil dove la misura non è riuscita.
    struct Tempi: Equatable {
        var fornitore: String
        var modello: String
        /// Dal comando di caricamento al modello pronto in memoria (dopo averlo liberato).
        var caricamento: Double?
        /// Prima domanda subito dopo il caricamento: dalla domanda alla prima parola visibile.
        var primaParolaDopoCaricamento: Double?
        /// Seconda domanda, con il modello già pronto: dalla domanda alla prima parola visibile.
        var primaParola: Double?
        /// Parole della seconda risposta e secondi dalla prima parola all'ultima.
        var parole: Int = 0
        var secondiScrittura: Double?
        /// I token al secondo contati dal fornitore (Ollama: eval_count / eval_duration), se li dà.
        var tokenAlSecondo: Double?
        /// Un problema durante le domande (il caricamento è riuscito, una risposta no).
        var errore: String?

        /// Le parole dopo la prima, diviso il tempo dalla prima all'ultima: la velocità di scrittura che si vede.
        var paroleAlSecondo: Double? {
            guard parole > 1, let s = secondiScrittura, s > 0 else { return nil }
            return Double(parole - 1) / s
        }
    }

    enum Esito: Equatable {
        case misurato(Tempi)
        /// Il fornitore non è pronto: il motivo, con le parole di Vera.
        case nonDisponibile(String)
    }

    /// Una risposta misurata: la prima parola dall'inizio, la scrittura dalla prima parola alla fine.
    struct Risposta {
        var testo = ""
        var primaParola: Double?
        var secondiScrittura: Double?
        var statistiche: StatisticheModello?
    }

    /// Le opzioni di Vera per la misura: la stessa finestra di tutte le chiamate (Ollama non ricarica il modello),
    /// niente ragionamento, una risposta breve.
    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.contesto = NucleoVera.finestra
        o.pensa = false
        o.restaInMemoria = vera.restaInMemoria
        o.massimoToken = massimoToken
        o.conLezioni = false
        return o
    }

    /// La misura intera. `orologio` dà i secondi (in salita); `avanzamento` dice a che punto è.
    static func esegui(fornitore: FornitoreModello, opzioni: OpzioniModello,
                       orologio: @escaping () -> Double = { ProcessInfo.processInfo.systemUptime },
                       avanzamento: @escaping (String) -> Void = { _ in }) async -> Esito {
        avanzamento("Controllo \(fornitore.nome)…")
        let disponibile = await fornitore.verifica()
        if let motivo = disponibile.motivo { return .nonDisponibile(motivo) }
        var tempi = Tempi(fornitore: fornitore.nome, modello: fornitore.modello)

        avanzamento("Carico \(fornitore.modello) da zero…")
        await fornitore.libera()
        let inizioCarico = orologio()
        let caricato = await fornitore.precarica(restaInMemoria: opzioni.restaInMemoria ?? MotoreLocale.restaInMemoria)
        let fineCarico = orologio()
        guard caricato else {
            return .nonDisponibile("\(fornitore.nome) non è riuscito a caricare \(fornitore.modello): riprova tra poco.")
        }
        tempi.caricamento = fineCarico - inizioCarico

        do {
            avanzamento("Prima domanda, appena caricato…")
            let prima = try await rispondi(fornitore, opzioni: opzioni, orologio: orologio)
            tempi.primaParolaDopoCaricamento = prima.primaParola
            avanzamento("Seconda domanda, già pronto…")
            let seconda = try await rispondi(fornitore, opzioni: opzioni, orologio: orologio)
            tempi.primaParola = seconda.primaParola
            tempi.parole = parole(seconda.testo)
            tempi.secondiScrittura = seconda.secondiScrittura
            tempi.tokenAlSecondo = seconda.statistiche?.tokenAlSecondo
        } catch {
            tempi.errore = error.localizedDescription
        }
        return .misurato(tempi)
    }

    /// Una domanda in streaming: l'orologio all'inizio, alla prima parola visibile (senza il ragionamento) e alla fine.
    static func rispondi(_ fornitore: FornitoreModello, opzioni: OpzioniModello,
                         orologio: () -> Double) async throws -> Risposta {
        let messaggi = [MessaggioModello(ruolo: .sistema, testo: istruzioni), MessaggioModello(ruolo: .utente, testo: domanda)]
        var r = Risposta()
        var filtro = FiltroPensiero()
        let inizio = orologio()
        var istantePrima: Double?
        for try await pezzo in fornitore.flusso(messaggi, opzioni: opzioni) {
            switch pezzo {
            case .testo(let t):
                let visibile = filtro.filtra(t).testo
                if istantePrima == nil, visibile.contains(where: { !$0.isWhitespace }) { istantePrima = orologio() }
                r.testo += visibile
            case .fine(let s):
                r.statistiche = s
            case .ragionamento, .strumento:
                break
            }
        }
        r.testo += filtro.svuota()
        let fine = orologio()
        if let istantePrima {
            r.primaParola = istantePrima - inizio
            r.secondiScrittura = fine - istantePrima
        }
        guard !r.testo.isEmpty else {
            throw ErroreVera(messaggio: "\(fornitore.nome) non ha scritto nulla: riprova tra poco.")
        }
        return r
    }

    /// Le parole di un testo (separate da spazi e a capo).
    static func parole(_ testo: String) -> Int {
        testo.split(whereSeparator: { $0.isWhitespace }).count
    }

    // MARK: - La tabella

    /// «1,2 s», «—» se manca.
    static func secondi(_ s: Double?) -> String {
        guard let s else { return "—" }
        return String(format: s < 10 ? "%.2f s" : "%.1f s", s).replacingOccurrences(of: ".", with: ",")
    }

    static func velocita(_ v: Double?, unita: String) -> String {
        guard let v else { return "—" }
        return String(format: "%.1f \(unita)", v).replacingOccurrences(of: ".", with: ",")
    }

    /// Le righe da mostrare e copiare: (che cosa, quanto).
    static func righe(_ t: Tempi) -> [(voce: String, valore: String)] {
        var r: [(String, String)] = [
            ("Caricamento di \(t.modello) da zero", secondi(t.caricamento)),
            ("Prima parola, appena caricato", secondi(t.primaParolaDopoCaricamento)),
            ("Prima parola, già pronto", secondi(t.primaParola)),
            ("Parole al secondo", velocita(t.paroleAlSecondo, unita: "parole/s")),
        ]
        if t.tokenAlSecondo != nil { r.append(("Token al secondo (\(t.fornitore))", velocita(t.tokenAlSecondo, unita: "token/s"))) }
        return r
    }

    /// La tabella in Markdown, per «Copia».
    static func markdown(_ t: Tempi, data: Date = Date()) -> String {
        var testo = ["### Tempi di Vera · \(t.modello) con \(t.fornitore)", "", "| Misura | Tempo |", "|---|---:|"]
        for r in righe(t) { testo.append("| \(r.voce) | \(r.valore) |") }
        testo.append("")
        testo.append("Domanda fissa senza dati dei clienti, al massimo \(massimoToken) token; parole al secondo = parole "
                     + "dopo la prima ÷ secondi dalla prima all'ultima (\(t.parole) parole).")
        if let e = t.errore { testo.append("Problema: \(e)") }
        testo.append("Misurato il \(DateFormatter.localizedString(from: data, dateStyle: .short, timeStyle: .short)).")
        return testo.joined(separator: "\n")
    }
}
