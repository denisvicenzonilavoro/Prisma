import Foundation

/// Prova della lettera dal futuro scritta da Vera («Luce» giro 8, Design/template-luce-specifica.md §3.1), dentro
/// `Prisma --prova-vera`, con il Qwen finto degli scenari (ServerFintoScenari): istruzioni nel pacchetto, la richiesta
/// con la scheda dei fatti in modalità lavoro, lo streaming, una lettera fedele che passa con la firma di Prisma, una con
/// una cifra inventata e una con una promessa scartate (resta la lettera di Prisma), una «senza il piano» che racconta
/// rinunce scartata (decisione 80), Qwen non pronto (resta la lettera di Prisma e Vera lo dice).
/// La scheda è DI PROVA: nessun cliente vero.
enum ProvaLetteraVera {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let istruzioni = IstruzioniVera.testo("lettera") ?? ""
        controlla(istruzioni.contains("prima persona") && istruzioni.contains("firma") && istruzioni.contains("Senza il piano"),
                  "Lettera: istruzioni di Qwen nel pacchetto (Vera/Istruzioni/lettera.md): prima persona, firma di Prisma, «senza il piano»")

        let s = SchedaLettera(nome: "Giulia", femminile: true, etaTraguardo: 67, etaIpotizzata: false, annoTraguardo: 2056,
                              meseIncontro: "novembre 2026", etaOggi: 37, obiettivo: "Casa di prova",
                              arrivoConPiano: AiutiProva.data(2029, 10, 1), arrivoSenzaPiano: AiutiProva.data(2034, 3, 1),
                              versamentoMensile: 550, pensioneConPiano: 2_160, pensioneSenzaPiano: 1_400, fondoNelPiano: true,
                              pianoPresente: true, mancanti: [])
        let vera = ImpostazioniVera()
        let configurazione = URLSessionConfiguration.ephemeral
        configurazione.protocolClasses = [ServerFintoScenari.self]
        let sessione = URLSession(configuration: configurazione)
        let motore = MotoreLocale(vera, disponibilita: .pronto, sessione: sessione)

        let fedele = """
        Cara Giulia,

        ti scrivo dal 2056. Ho 67 anni e stamattina, con il caffè in mano, ho ripensato a quella sera di novembre 2026 in cui avevamo tutti i numeri sul tavolo. L’obiettivo «Casa di prova» l’abbiamo raggiunto a ottobre 2029, come avevamo previsto, mettendo da parte 550 euro al mese con pazienza.

        Oggi la pensione arriva a circa 2.160 euro al mese, contando anche il fondo che abbiamo aperto a 37 anni. Abbiamo tempo per le persone che amiamo e per le cose che ci piacciono.

        Grazie per aver cominciato quando era il momento.

        Giulia, 67 anni
        """
        let inventata = fedele.replacingOccurrences(of: "2.160 euro", with: "2.500 euro")
        let promessa = fedele.replacingOccurrences(of: "Grazie per aver cominciato", with: "Il rendimento garantito ci ha premiato. Grazie per aver cominciato")
        let cupa = """
        Cara Giulia,

        ti scrivo dal 2056. Ho 67 anni. L’obiettivo «Casa di prova» l’abbiamo raggiunto a marzo 2034, dopo tanti sacrifici e qualche rinuncia di troppo che ancora mi pesa.

        La pensione è di circa 1.400 euro al mese e ogni mese c’è un po’ di paura. Ogni tanto ripenso a quella sera di novembre 2026 in cui avevamo tutti i numeri davanti, e a quello che potevamo fare.
        """
        ServerFintoScenari.prepara([fedele, inventata, promessa, cupa])
        let pezzi = ScatolaLettera<Int>()
        pezzi.valore = 0
        let primo = aspetta {
            await LetteraVera.scrivi(s, versione: .conPiano, posizioni: [], motore: motore, vera: vera,
                                     aggiorna: { _ in pezzi.valore = (pezzi.valore ?? 0) + 1 })
        }
        let ricevuto = ServerFintoScenari.ultimo
        let sistema = ((ricevuto["messages"] as? [[String: Any]])?.first?["content"] as? String) ?? ""
        let utente = ((ricevuto["messages"] as? [[String: Any]])?.last?["content"] as? String) ?? ""
        controlla(sistema == LetteraVera.istruzioni && utente.contains("SCHEDA DELLA LETTERA") && utente.contains("2.160")
                  && utente.contains("LETTERA DI PRISMA") && (ricevuto["think"] as? Bool) == false,
                  "Lettera, Qwen finto: istruzioni fisse, scheda con le cifre di Prisma e la lettera fissa, senza ragionamento")
        controlla(LetteraVera.piano(s, .conPiano, vera: vera).scelta.modalita == .lavoro,
                  "Lettera: Vera scrive in modalità lavoro (numeri solo da Prisma)")
        controlla(primo.autore == .vera && primo.avviso == nil && primo.testo.hasPrefix("Cara Giulia,")
                  && primo.testo.hasSuffix("Giulia, 67 anni") && primo.testo.components(separatedBy: "Giulia, 67 anni").count == 2,
                  "Lettera, Qwen finto: una lettera con le cifre della scheda passa, con la firma di Prisma una volta sola (\(primo.avviso ?? "ok"))")
        controlla((pezzi.valore ?? 0) >= 1, "Lettera, Qwen finto: il testo arriva in streaming (\(pezzi.valore ?? 0) aggiornamenti)")

        let secondo = aspetta { await LetteraVera.scrivi(s, versione: .conPiano, posizioni: [], motore: motore, vera: vera) }
        controlla(secondo.autore == .modelloFisso && secondo.testo == MotoreLettera.conFirma(MotoreLettera.fissa(s, .conPiano), s)
                  && (secondo.avviso ?? "").contains("cifra"),
                  "Lettera, Qwen finto: una cifra inventata (2.500 €) si scarta e resta la lettera di Prisma («\(secondo.avviso ?? "")»)")
        let terzo = aspetta { await LetteraVera.scrivi(s, versione: .conPiano, posizioni: [], motore: motore, vera: vera) }
        controlla(terzo.autore == .modelloFisso && (terzo.avviso ?? "").contains("prometteva"),
                  "Lettera, Qwen finto: una promessa di rendimento si scarta («\(terzo.avviso ?? "")»)")
        let quarto = aspetta { await LetteraVera.scrivi(s, versione: .senzaPiano, posizioni: [], motore: motore, vera: vera) }
        controlla(quarto.autore == .modelloFisso && (quarto.avviso ?? "").contains("rinunce"),
                  "Lettera, Qwen finto: «senza il piano» con rinunce e paure si scarta (decisione 80) («\(quarto.avviso ?? "")»)")
        // Un prodotto nominato si scarta
        var pip = AiutiProva.posizione("Piano previdenziale di prova", .previdenza, 0)
        pip.stato = .proposta
        let conProdotto = fedele.replacingOccurrences(of: "il fondo che abbiamo aperto", with: "il Piano previdenziale di prova che abbiamo aperto")
        controlla(LetteraVera.controlla(conProdotto, scheda: s, versione: .conPiano, vietati: LetteraVera.vietati([pip])) != nil
                  && LetteraVera.controlla(fedele, scheda: s, versione: .conPiano, vietati: LetteraVera.vietati([pip])) == nil,
                  "Lettera: il nome di un prodotto del cliente nella lettera la fa scartare")

        // Qwen non pronto: niente richiesta, resta la lettera di Prisma e Vera lo dice
        let spento = MotoreLocale(vera, disponibilita: .nonDisponibile("Ollama non risponde sul Mac."), sessione: sessione)
        let quinto = aspetta { await LetteraVera.scrivi(s, versione: .conPiano, posizioni: [], motore: spento, vera: vera) }
        controlla(quinto.autore == .modelloFisso && (quinto.avviso ?? "").hasPrefix("Vera non è pronta")
                  && (quinto.avviso ?? "").contains("la lettera è quella di Prisma"),
                  "Lettera: se Qwen non è pronto resta la lettera di Prisma e Vera lo dice («\(quinto.avviso ?? "")»)")
        let senzaMotore = aspetta { await LetteraVera.scrivi(s, versione: .senzaPiano, posizioni: [], motore: nil, vera: vera) }
        controlla(senzaMotore.autore == .modelloFisso && senzaMotore.testo.hasPrefix("Cara Giulia,")
                  && senzaMotore.testo.contains("1.400 euro"),
                  "Lettera: senza Qwen la lettera fissa «senza il piano», con le cifre della scheda")
    }

    /// Aspetta un lavoro asincrono dal thread delle prove.
    private static func aspetta<T>(_ lavoro: @escaping () async -> T) -> T {
        let scatola = ScatolaLettera<T>()
        let fatto = DispatchSemaphore(value: 0)
        Task.detached {
            scatola.valore = await lavoro()
            fatto.signal()
        }
        fatto.wait()
        return scatola.valore!
    }
}

private final class ScatolaLettera<T>: @unchecked Sendable {
    private let blocco = NSLock()
    private var _valore: T?

    var valore: T? {
        get { blocco.lock(); defer { blocco.unlock() }; return _valore }
        set { blocco.lock(); _valore = newValue; blocco.unlock() }
    }
}
