import Foundation

// Vera scrive i messaggi ai clienti (Messaggi, «Prisma scrive per te»), sul modello del commento dei report (CommentoVera)
// e del racconto degli scenari (ScenariVera): Prisma prepara la scheda con le cifre dell'occasione e la bozza fissa
// (ModelliMessaggi), Qwen sul Mac la riscrive in modo naturale con lo stesso nucleo (FornitoreModello, modalità lavoro,
// istruzioni fisse in Vera/Istruzioni/messaggi.md), il testo arriva in streaming. A fine flusso la verifica: ogni numero
// del testo deve stare nella scheda (CommentoVera.numeriConservati), niente segnaposto, niente promesse di rendimento,
// lunghezza giusta. Se qualcosa non torna, o se Qwen non è pronto, resta il modello fisso e Vera lo dice.
// Chiusura e firma le aggiunge sempre Prisma. Nella scheda va solo il nome del cliente: niente recapiti, niente altri clienti.

/// Il testo pronto per un messaggio, con chi l'ha scritto.
struct TestoScrittoMessaggio: Equatable {
    var oggetto: String?
    /// Il messaggio intero, con la chiusura e la firma.
    var testo: String
    var autore: AutoreMessaggio
    /// Il modello di Qwen che l'ha scritto; nil per il modello fisso.
    var modello: String?
    /// Perché è rimasto il testo di Prisma («Vera non è pronta…», «una cifra non è nella scheda…»); nil se l'ha scritto Vera.
    var avviso: String?
}

enum MessaggiVera {
    /// Le istruzioni fisse di Vera/Istruzioni/messaggi.md (con un ripiego minimo in sviluppo).
    static var istruzioni: String {
        IstruzioniVera.testo("messaggi") ?? "Scrivi in italiano, a nome del consulente, un messaggio breve a un suo cliente partendo dalla bozza di Prisma. Usa solo i fatti e i numeri della scheda, non promettere rendimenti, non scrivere oggetto, chiusura né firma."
    }

    // MARK: - La richiesta a Qwen

    /// La scheda dell'occasione: il nome del cliente, tono, canale e lunghezza, perché adesso, i fatti con le cifre
    /// esatte di Prisma e la bozza da riscrivere.
    static func scheda(_ o: OccasioneMessaggio, cliente: Cliente, tono: TonoMessaggio, canale: CanaleMessaggio,
                       bozza: TestoMessaggio) -> String {
        let nome = cliente.nome.trimmingCharacters(in: .whitespacesAndNewlines)
        var righe = ["SCHEDA DEL MESSAGGIO (fatti e numeri esatti di Prisma: usa solo questi)"]
        switch tono {
        case .cordiale: righe.append("Cliente: \(ModelliMessaggi.primoNome(nome)) (dai del tu)")
        case .formale: righe.append("Cliente: \(nome) (dai del lei)")
        case .breve: righe.append("Cliente: \(ModelliMessaggi.primoNome(nome)) (dai del tu)")
        }
        righe.append("Tono: \(tono.nome.lowercased())")
        switch canale {
        case .mail: righe.append("Canale: mail, al massimo \(RegoleMessaggi.parole) parole")
        case .messaggi: righe.append("Canale: messaggio sul telefono, senza oggetto")
        }
        if tono == .breve {
            righe.append("Lunghezza: al massimo \(max(0, RegoleMessaggi.caratteriBreve - bozza.chiusura.count)) caratteri, su una riga")
        }
        if let c = o.canale { righe.append("Canale di lavoro: \(c.nomeBreve)") }
        righe.append("Occasione: \(o.tipo.nome) · \(o.titolo)")
        righe.append("Perché adesso: \(o.perche)")
        righe.append("FATTI")
        righe += o.cifre.map { "- \($0.etichetta): \($0.valore)" }
        righe.append("")
        righe.append("BOZZA DI PRISMA (riscrivila in modo naturale, con gli stessi fatti e gli stessi numeri)")
        righe.append(bozza.corpo)
        righe.append("")
        righe.append("Scrivi solo il testo del messaggio, dal saluto all'invito finale. Non scrivere l'oggetto, la chiusura («Un saluto», «Cordiali saluti») né la firma: le aggiunge Prisma.")
        return righe.joined(separator: "\n")
    }

    /// I messaggi per il fornitore: le istruzioni fisse (Ollama le tiene in cache) e la scheda nell'ultimo messaggio.
    static func messaggi(_ o: OccasioneMessaggio, cliente: Cliente, tono: TonoMessaggio, canale: CanaleMessaggio,
                         bozza: TestoMessaggio) -> [MessaggioModello] {
        [MessaggioModello(ruolo: .sistema, testo: istruzioni),
         MessaggioModello(ruolo: .utente, testo: scheda(o, cliente: cliente, tono: tono, canale: canale, bozza: bozza))]
    }

    /// Le opzioni: senza ragionamento, la finestra di sempre, una risposta corta.
    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = temperatura
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.restaInMemoria = vera.restaInMemoria
        o.massimoToken = massimoToken
        return o
    }

    static let temperatura = 0.4
    static let massimoToken = 450

    /// Il piano per il nucleo: modalità lavoro (numeri solo da Prisma e dalla scheda), senza ragionamento.
    static func piano(_ o: OccasioneMessaggio, cliente: Cliente, tono: TonoMessaggio, canale: CanaleMessaggio,
                      bozza: TestoMessaggio, vera: ImpostazioniVera) -> PianoVera {
        PianoVera(scelta: SceltaVera(modalita: .lavoro, pensa: false),
                 messaggi: messaggi(o, cliente: cliente, tono: tono, canale: canale, bozza: bozza), opzioni: opzioni(vera))
    }

    // MARK: - La verifica

    /// Tutto il testo da cui possono venire i numeri del messaggio: le cifre dell'occasione, titolo, perché, oggetto,
    /// il nome del cliente e la bozza di Prisma.
    static func ammessi(_ o: OccasioneMessaggio, cliente: Cliente, bozza: TestoMessaggio) -> String {
        ([o.titolo, o.perche, o.oggetto, cliente.nome, bozza.oggetto ?? "", bozza.completo]
            + o.cifre.map { "\($0.etichetta): \($0.valore)" }).joined(separator: "\n")
    }

    /// Promesse che un messaggio non fa mai.
    static let promesse = #"rendimento garantit|rendimenti garantit|guadagno (sicuro|garantit|certo)|guadagn(erai|erà|erete|erebbe)|render(à|a|anno) (il|almeno|sicuramente)|senza (alcun |nessun )?risch|nessun rischio|rischio zero|sicuramente (guadagn|rend)|ti assicuro un"#

    /// nil se il testo di Qwen va bene; altrimenti il motivo per cui resta il testo di Prisma.
    static func controlla(_ testo: String, occasione o: OccasioneMessaggio, cliente: Cliente, tono: TonoMessaggio,
                          bozza: TestoMessaggio) -> String? {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "il testo di Vera è vuoto" }
        if t.contains("[") || t.contains("]") || t.contains("{") || t.contains("}") || t.contains("<") || t.contains(">") {
            return "il testo di Vera ha dei segnaposto da completare"
        }
        guard CommentoVera.numeriConservati(bozza: ammessi(o, cliente: cliente, bozza: bozza), testo: t) else {
            return "il testo di Vera citava una cifra che non è nella scheda"
        }
        if t.range(of: promesse, options: [.regularExpression, .caseInsensitive]) != nil {
            return "il testo di Vera prometteva un risultato"
        }
        if tono == .breve {
            if (t + bozza.chiusura).count > RegoleMessaggi.caratteriBreve { return "il testo di Vera era troppo lungo" }
        } else if t.split(whereSeparator: { $0.isWhitespace }).count > RegoleMessaggi.paroleTollerate {
            return "il testo di Vera era troppo lungo"
        }
        return nil
    }

    /// Un pezzo del flusso si può mostrare: ogni cifra già scritta per intera (non quella che sta arrivando in fondo)
    /// è nella scheda e non c'è una promessa di rendimento. Il controllo completo resta `controlla`, a fine flusso.
    static func mostrabile(_ parziale: String, fatti: String) -> Bool {
        let arrivato = parziale.replacingOccurrences(of: #"[0-9.,]+$"#, with: "", options: .regularExpression)
        return CommentoVera.numeriConservati(bozza: fatti, testo: arrivato)
            && arrivato.range(of: promesse, options: [.regularExpression, .caseInsensitive]) == nil
    }

    /// Toglie dal testo di Qwen grassetti, titoli, la riga dell'oggetto e, in fondo, chiusure e firme: le mette Prisma.
    static func pulisci(_ testo: String, firma: String?) -> String {
        var righe = testo.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "__", with: "")
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }
        if let i = righe.firstIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
           righe[i].trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("oggetto") {
            righe.remove(at: i)
        }
        let paroleFirma = Set((firma ?? "").lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init).filter { $0.count >= 3 })
        var tolte = 0
        while let ultima = righe.last, tolte < 4 {
            let r = ultima.trimmingCharacters(in: .whitespaces)
            let semplice = r.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ",.;:!–- "))
            let parole = semplice.split(whereSeparator: { !$0.isLetter }).map(String.init)
            let chiusura = chiusure.contains { semplice.hasPrefix($0) } && parole.count <= 6
            let firmaScritta = !parole.isEmpty && parole.count <= 5 && parole.contains { paroleFirma.contains($0) }
            if r.isEmpty || chiusura || firmaScritta {
                righe.removeLast()
                if !r.isEmpty { tolte += 1 }
            } else {
                break
            }
        }
        return righe.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let chiusure = ["un saluto", "un caro saluto", "cari saluti", "cordiali saluti", "distinti saluti", "saluti",
                           "a presto", "un abbraccio", "buona giornata", "buona serata", "grazie e a presto", "con i migliori saluti"]

    // MARK: - Scrivere

    /// Il modello fisso, con l'avviso del perché (nil se l'ha chiesto il consulente).
    static func fisso(_ bozza: TestoMessaggio, avviso: String?) -> TestoScrittoMessaggio {
        TestoScrittoMessaggio(oggetto: bozza.oggetto, testo: bozza.completo, autore: .modelloFisso, modello: nil, avviso: avviso)
    }

    /// «Vera non è pronta: …». Il motivo viene dalla verifica di Qwen (DisponibilitaVera).
    static func avvisoNonPronta(_ motivo: String?) -> String {
        // I motivi di DisponibilitaVera finiscono con il punto: qui il punto lo mette la frase
        let m = (motivo ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".").union(.whitespaces))
        return "Vera non è pronta" + (m.isEmpty ? "" : ": \(m)") + ". Resta il testo di Prisma, con le cifre esatte: lo puoi correggere tu."
    }

    /// Scrive il messaggio con Qwen in streaming (`aggiorna` riceve il testo fin qui, già pulito, da qualunque thread:
    /// la vista lo porta sul thread principale). A fine flusso la verifica; se non passa, o se `motore` manca o non è
    /// pronto, resta il modello fisso con l'avviso. Mai un invio: il testo torna al consulente.
    static func scrivi(_ o: OccasioneMessaggio, cliente: Cliente, tono: TonoMessaggio, canale: CanaleMessaggio, firma: String?,
                       motore: MotoreLocale?, vera: ImpostazioniVera,
                       aggiorna: ((String) -> Void)? = nil) async -> TestoScrittoMessaggio {
        let bozza = ModelliMessaggi.testo(o, tono: tono, canale: canale, cliente: cliente, firma: firma)
        guard let motore else { return fisso(bozza, avviso: avvisoNonPronta(nil)) }
        guard motore.disponibilita.pronto else { return fisso(bozza, avviso: avvisoNonPronta(motore.disponibilita.motivo)) }
        let p = piano(o, cliente: cliente, tono: tono, canale: canale, bozza: bozza, vera: vera)
        do {
            var suPezzo: ((ParzialeVera) -> Void)?
            if let aggiorna {
                // Il flusso si mostra solo finché le cifre già arrivate sono quelle della scheda: una cifra inventata
                // ferma la comparsa (e a fine flusso la verifica tiene il testo di Prisma)
                let fatti = ammessi(o, cliente: cliente, bozza: bozza)
                suPezzo = { parziale in
                    let t = pulisci(parziale.testo, firma: firma)
                    if mostrabile(t, fatti: fatti) { aggiorna(t) }
                }
            }
            let r = try await motore.scrivi(p, aggiorna: suPezzo)
            let pulito = pulisci(r.testo, firma: firma)
            if let motivo = controlla(pulito, occasione: o, cliente: cliente, tono: tono, bozza: bozza) {
                return fisso(bozza, avviso: maiuscola(motivo) + ": resta il testo di Prisma, con le cifre esatte.")
            }
            return TestoScrittoMessaggio(oggetto: bozza.oggetto, testo: pulito + bozza.chiusura, autore: .vera,
                                         modello: motore.modello, avviso: nil)
        } catch is CancellationError {
            return fisso(bozza, avviso: "Riscrittura interrotta: resta il testo di Prisma.")
        } catch {
            let m = (error as? ErroreVera)?.messaggio ?? error.localizedDescription
            return fisso(bozza, avviso: "Vera non ha potuto scrivere il messaggio (\(m)). Resta il testo di Prisma.")
        }
    }

    private static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.uppercased() + s.dropFirst()
    }
}
