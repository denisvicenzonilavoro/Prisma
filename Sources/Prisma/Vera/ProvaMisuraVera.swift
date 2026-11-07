import Foundation

/// La prova della misura dei tempi di Vera (MisuraVera.swift, giro 0 di «Prisma istantaneo»), dentro `--prova-vera`:
/// con il server finto di Ollama (ServerFinto) e un orologio finto che dà istanti noti, il caricamento, la prima
/// parola, le parole al secondo e i token al secondo devono venire esattamente dai conti attesi; senza il modello e
/// senza Ollama la misura lo dice con le parole di Vera.
enum ProvaMisuraVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let configurazione = URLSessionConfiguration.ephemeral
        configurazione.protocolClasses = [ServerFinto.self]
        let sessione = URLSession(configuration: configurazione)
        ServerFinto.azzera()
        let vera = ImpostazioniVera()
        let ollama = FornitoreOllama(indirizzo: vera.indirizzoLocale, modello: "qwen3.5:4b", sessione: sessione)

        // L'orologio finto: gli istanti in cui la misura lo legge, in ordine (caricamento: 10 → 12,5; prima domanda:
        // 13 → 13,8 → 15; seconda domanda: 20 → 20,4 → 22,4)
        let orologio = OrologioFinto([10, 12.5, 13, 13.8, 15, 20, 20.4, 22.4])
        let opzioni = MisuraVera.opzioni(vera)
        let esito = aspetta { await MisuraVera.esegui(fornitore: ollama, opzioni: opzioni, orologio: { orologio.leggi() }) }
        guard case .misurato(let t) = esito else {
            return controlla(false, "Misura di Vera: con il server finto la misura riesce (\(esito))")
        }
        controlla(t.errore == nil && orologio.letture == 8, "Misura di Vera: otto letture dell'orologio, nessun errore (\(orologio.letture), \(t.errore ?? "—"))")
        controlla(vicino(t.caricamento, 2.5), "Misura di Vera: caricamento da zero = 2,5 s (\(MisuraVera.secondi(t.caricamento)))")
        controlla(vicino(t.primaParolaDopoCaricamento, 0.8), "Misura di Vera: prima parola appena caricato = 0,8 s (\(MisuraVera.secondi(t.primaParolaDopoCaricamento)))")
        controlla(vicino(t.primaParola, 0.4), "Misura di Vera: prima parola già pronto = 0,4 s (\(MisuraVera.secondi(t.primaParola)))")
        // «Ciao Denis, ecco la risposta.»: 5 parole, 4 dopo la prima in 2 secondi
        controlla(t.parole == 5 && vicino(t.secondiScrittura, 2) && vicino(t.paroleAlSecondo, 2),
                  "Misura di Vera: 5 parole, 4 dopo la prima in 2 s = 2 parole al secondo (\(t.parole), \(MisuraVera.velocita(t.paroleAlSecondo, unita: "parole/s")))")
        // Il server finto dice eval_count 6 in eval_duration 0,3 s
        controlla(vicino(t.tokenAlSecondo, 20), "Misura di Vera: token al secondo dal conteggio di Ollama = 20 (\(MisuraVera.velocita(t.tokenAlSecondo, unita: "token/s")))")
        // Il modello si libera prima di caricarlo da zero, poi si carica con la memoria scelta
        controlla(ServerFinto.caricamenti == ["0", vera.restaInMemoria], "Misura di Vera: libera il modello e lo ricarica (\(ServerFinto.caricamenti))")
        // Le domande vanno con la stessa finestra di Vera (Ollama non ricarica) e senza dati dei clienti
        let ricevuto = ServerFinto.ricevuto("/api/chat")
        let finestra = ((ricevuto?["options"] as? [String: Any])?["num_ctx"] as? NSNumber)?.intValue
        let testi = ((ricevuto?["messages"] as? [[String: Any]]) ?? []).compactMap { $0["content"] as? String }.joined(separator: " ")
        let nomi = StatoShell(persistente: false).clienti.map(\.nome)
        controlla(finestra == NucleoVera.finestra && (ricevuto?["think"] as? Bool) == false && !nomi.contains { testi.contains($0) },
                  "Misura di Vera: la stessa finestra delle risposte di Vera (\(finestra.map(String.init) ?? "—")), niente ragionamento, nessun dato dei clienti")
        let tabella = MisuraVera.markdown(t)
        controlla(tabella.contains("| Prima parola, già pronto | 0,40 s |") && tabella.contains("2,0 parole/s"),
                  "Misura di Vera: la tabella da copiare riporta i tempi con la virgola")

        // Le parole al secondo non si inventano: con una parola sola o senza tempo non c'è velocità
        var una = MisuraVera.Tempi(fornitore: "Ollama", modello: "qwen3.5:4b")
        una.parole = 1
        una.secondiScrittura = 1
        var senzaTempo = una
        senzaTempo.parole = 10
        senzaTempo.secondiScrittura = 0
        controlla(una.paroleAlSecondo == nil && senzaTempo.paroleAlSecondo == nil && MisuraVera.secondi(nil) == "—",
                  "Misura di Vera: senza abbastanza parole o tempo la velocità resta «—»")

        // Senza il modello e senza Ollama la misura lo dice, con il messaggio di Vera
        let manca = FornitoreOllama(indirizzo: vera.indirizzoLocale, modello: "assente:1b", sessione: sessione)
        let senzaModello = aspetta { await MisuraVera.esegui(fornitore: manca, opzioni: opzioni) }
        if case .nonDisponibile(let motivo) = senzaModello {
            controlla(motivo.contains("manca il modello assente:1b"), "Misura di Vera: senza il modello lo dice (\(motivo.prefix(70)))")
        } else {
            controlla(false, "Misura di Vera: senza il modello lo dice")
        }
        // Un indirizzo del Mac dove non risponde nessuno (porta 9): «Ollama non è aperto»
        let spento = FornitoreOllama(indirizzo: "http://127.0.0.1:9", modello: "qwen3.5:4b")
        let senzaOllama = aspetta { await MisuraVera.esegui(fornitore: spento, opzioni: opzioni) }
        if case .nonDisponibile(let motivo) = senzaOllama {
            controlla(motivo.contains("Ollama non è aperto"), "Misura di Vera: senza Ollama lo dice (\(motivo.prefix(70)))")
        } else {
            controlla(false, "Misura di Vera: senza Ollama lo dice")
        }
    }

    private static func vicino(_ a: Double?, _ b: Double) -> Bool {
        guard let a else { return false }
        return abs(a - b) < 0.000_1
    }

    private static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaMisuraVera<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }
}

/// Un orologio che dà gli istanti scritti, uno a ogni lettura (poi resta sull'ultimo).
private final class OrologioFinto: @unchecked Sendable {
    private let blocco = NSLock()
    private let istanti: [Double]
    private(set) var letture = 0

    init(_ istanti: [Double]) { self.istanti = istanti }

    func leggi() -> Double {
        blocco.lock(); defer { blocco.unlock() }
        let i = min(letture, istanti.count - 1)
        letture += 1
        return istanti[i]
    }
}

private final class ScatolaMisuraVera<T>: @unchecked Sendable {
    var valore: T?
}
