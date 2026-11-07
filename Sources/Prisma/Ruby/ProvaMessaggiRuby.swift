import Foundation

/// Prova dei messaggi ai clienti scritti da Ruby, dentro `Prisma --prova-ruby`, con il Qwen finto degli scenari
/// (ServerFintoScenari, un server Ollama dentro il processo): istruzioni nel pacchetto, la richiesta con la scheda
/// dell'occasione e la modalità lavoro, lo streaming, un testo con le cifre giuste che passa, uno con una cifra inventata
/// che viene scartato (resta il modello fisso), Qwen non pronto (resta il modello fisso e Ruby lo dice).
/// Cliente, recapiti e polizza sono DI PROVA.
enum ProvaMessaggiRuby {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let istruzioni = IstruzioniRuby.testo("messaggi") ?? ""
        controlla(istruzioni.contains("Prisma non spedisce") && istruzioni.contains("firma") && istruzioni.contains("rendimenti"),
                  "Messaggi: istruzioni di Qwen nel pacchetto (Ruby/Istruzioni/messaggi.md): niente invii, firma di Prisma, niente promesse")

        let oggi = AiutiProva.data(2026, 11, 4)
        var marco = Cliente(id: "marco", nome: "Marco Bianchi", iniziali: "MB", tinta: .blu, tema: "", email: "marco.prova@example.com",
                            telefono: "+39 333 000 0000", preferito: false, nota: "", creatoIl: oggi)
        marco.canali = [.alleanza]
        var p = AiutiProva.posizione("Infortuni famiglia", .protezione, 0, canale: .alleanza)
        p.clienteId = "marco"
        p.scadenza = Calendar.current.date(byAdding: .day, value: 45, to: oggi)
        var dati = DatiPrisma(clienti: [marco], appuntamenti: [], attivita: [], posizioni: [p], clienteAttivoId: "marco",
                              impostazioni: Impostazioni())
        dati.messaggi = []
        guard let o = MotoreOccasioniMessaggi.calcola(dati: dati, oggi: oggi).tutte.first(where: { $0.tipo == .scadenzaPosizione }) else {
            return controlla(false, "Messaggi: occasione di prova (scadenza di Marco)")
        }
        let ruby = ImpostazioniRuby()
        let firma = ModelliMessaggi.firma(o.canale, tono: .cordiale, impostazioni: dati.impostazioni)
        let bozza = ModelliMessaggi.testo(o, tono: .cordiale, canale: .mail, cliente: marco, firma: firma)

        // Qwen finto: un testo fedele, poi uno con una cifra inventata
        let configurazione = URLSessionConfiguration.ephemeral
        configurazione.protocolClasses = [ServerFintoScenari.self]
        let sessione = URLSession(configuration: configurazione)
        let motore = MotoreLocale(ruby, disponibilita: .pronto, sessione: sessione)
        let fedele = "Ciao Marco,\n\nla tua «Infortuni famiglia» scade il 19 dicembre 2026, tra 45 giorni: è il momento giusto per guardarla insieme.\n\nTi va di vederci nei prossimi giorni?\n\nUn saluto,\nDenis"
        let inventato = "Ciao Marco,\n\nla tua «Infortuni famiglia» scade il 19 dicembre 2026: rinnovandola risparmieresti 120 € all'anno.\n\nTi va di vederci?"
        ServerFintoScenari.prepara([fedele, inventato])
        let pezzi = ScatolaMessaggiRuby<Int>()
        pezzi.valore = 0
        let primo = aspetta {
            await MessaggiRuby.scrivi(o, cliente: marco, tono: .cordiale, canale: .mail, firma: firma, motore: motore, ruby: ruby,
                                     aggiorna: { _ in pezzi.aggiungi() })
        }
        let ricevuto = ServerFintoScenari.ultimo
        let sistema = ((ricevuto["messages"] as? [[String: Any]])?.first?["content"] as? String) ?? ""
        let utente = ((ricevuto["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        let opzioni = ricevuto["options"] as? [String: Any] ?? [:]
        controlla(sistema == MessaggiRuby.istruzioni && utente.contains("SCHEDA DEL MESSAGGIO") && utente.contains("19 dicembre 2026")
                  && utente.contains("BOZZA DI PRISMA") && utente.contains("Marco (dai del tu)") && (ricevuto["think"] as? Bool) == false
                  && (opzioni["num_ctx"] as? Int) == NucleoRuby.finestra,
                  "Messaggi, Qwen finto: istruzioni fisse, scheda con le cifre e la bozza, senza ragionamento, stessa finestra")
        controlla(!utente.contains("marco.prova@example.com") && !utente.contains("333"),
                  "Messaggi, Qwen finto: nella scheda il nome del cliente, mai email e telefono")
        controlla(MessaggiRuby.piano(o, cliente: marco, tono: .cordiale, canale: .mail, bozza: bozza, ruby: ruby).scelta.modalita == .lavoro,
                  "Messaggi: Ruby scrive in modalità lavoro (numeri solo da Prisma)")
        controlla(primo.autore == .ruby && primo.modello == motore.modello && primo.avviso == nil
                  && primo.testo.hasPrefix("Ciao Marco,\n\nla tua «Infortuni famiglia» scade il 19 dicembre 2026")
                  && primo.testo.hasSuffix("Ti va di vederci nei prossimi giorni?\n\nUn saluto,\nDenis")
                  && primo.testo.components(separatedBy: "Un saluto").count == 2 && primo.oggetto == bozza.oggetto,
                  "Messaggi, Qwen finto: un testo con le cifre della scheda passa, con la chiusura e la firma di Prisma una volta sola")
        controlla((pezzi.valore ?? 0) >= 1, "Messaggi, Qwen finto: il testo arriva in streaming (\(pezzi.valore ?? 0) aggiornamenti)")

        let secondo = aspetta {
            await MessaggiRuby.scrivi(o, cliente: marco, tono: .cordiale, canale: .mail, firma: firma, motore: motore, ruby: ruby)
        }
        controlla(secondo.autore == .modelloFisso && secondo.testo == bozza.completo && secondo.modello == nil
                  && (secondo.avviso ?? "").contains("cifra"),
                  "Messaggi, Qwen finto: un testo con una cifra inventata (120 €) si scarta e resta il modello fisso («\(secondo.avviso ?? "")»)")

        // Qwen non pronto: niente richiesta, resta il modello fisso e Ruby lo dice
        let spento = MotoreLocale(ruby, disponibilita: .nonDisponibile("Ollama non risponde sul Mac."), sessione: sessione)
        let terzo = aspetta {
            await MessaggiRuby.scrivi(o, cliente: marco, tono: .breve, canale: .messaggi, firma: firma, motore: spento, ruby: ruby)
        }
        let bozzaBreve = ModelliMessaggi.testo(o, tono: .breve, canale: .messaggi, cliente: marco, firma: firma)
        controlla(terzo.autore == .modelloFisso && terzo.testo == bozzaBreve.completo && terzo.oggetto == nil
                  && (terzo.avviso ?? "").hasPrefix("Ruby non è pronta") && (terzo.avviso ?? "").contains("Ollama non risponde"),
                  "Messaggi: se Qwen non è pronto resta il modello fisso e Ruby lo dice («\(terzo.avviso ?? "")»)")
        let senzaMotore = aspetta {
            await MessaggiRuby.scrivi(o, cliente: marco, tono: .formale, canale: .mail, firma: firma, motore: nil, ruby: ruby)
        }
        controlla(senzaMotore.autore == .modelloFisso && senzaMotore.testo.hasPrefix("Gentile Marco Bianchi,"),
                  "Messaggi: senza Qwen il modello fisso formale, già compilato")
    }

    /// Aspetta un lavoro asincrono dal thread delle prove.
    private static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaMessaggiRuby<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }
}

private final class ScatolaMessaggiRuby<T>: @unchecked Sendable {
    private let blocco = NSLock()
    private var _valore: T?

    var valore: T? {
        get { blocco.lock(); defer { blocco.unlock() }; return _valore }
        set { blocco.lock(); _valore = newValue; blocco.unlock() }
    }
}

private extension ScatolaMessaggiRuby where T == Int {
    func aggiungi() { valore = (valore ?? 0) + 1 }
}
