import Foundation

// Vera scrive la lettera dal futuro (Design/template-luce-specifica.md §3.1, «Luce» giro 8), sul modello dei messaggi
// ai clienti (MessaggiVera): Prisma prepara la scheda dei fatti e la lettera fissa (MotoreLettera), Qwen sul Mac la
// riscrive con lo stesso nucleo (FornitoreModello, modalità lavoro, istruzioni fisse in Vera/Istruzioni/lettera.md) e il
// testo arriva in streaming. A fine flusso la verifica: ogni cifra deve stare nella scheda (CommentoVera.numeriConservati),
// niente segnaposto, promesse, prodotti o compagnie, lunghezza giusta, scritta in prima persona; nella versione «senza
// il piano» niente scenari negativi oltre le cifre (decisione 80). Se qualcosa non torna, o se Qwen non è pronto, resta
// la lettera fissa di Prisma e Vera lo dice. La firma la aggiunge sempre Prisma. Niente esce dal Mac: la lettera torna
// al consulente, che la mostra al cliente.

/// La lettera pronta, con chi l'ha scritta.
struct TestoLettera: Equatable {
    /// La lettera intera, con la firma.
    var testo: String
    var autore: AutoreMessaggio
    var modello: String?
    /// Perché è rimasta la lettera di Prisma; nil se l'ha scritta Vera.
    var avviso: String?
}

enum LetteraVera {
    static var istruzioni: String {
        IstruzioniVera.testo("lettera") ?? "Riscrivi in italiano, in prima persona, la lettera che il cliente all'età della pensione scrive a sé stesso di oggi. Usa solo le cifre della scheda, non promettere risultati, non nominare prodotti né compagnie, non scrivere la firma."
    }

    static let temperatura = 0.6
    static let massimoToken = 520
    /// Lunghezza tollerata (le istruzioni chiedono 90-200 parole).
    static let paroleMinime = 50
    static let paroleMassime = 240

    // MARK: - La richiesta

    static func scheda(_ s: SchedaLettera, _ v: VersioneLettera) -> String {
        var righe = ["SCHEDA DELLA LETTERA (fatti e cifre esatte di Prisma: usa solo questi)"]
        righe.append("Versione: \(v == .conPiano ? "con il piano" : "senza il piano")")
        righe += MotoreLettera.fatti(s, v).map { "- " + $0 }
        righe.append("")
        righe.append("LETTERA DI PRISMA (riscrivila in modo naturale, con gli stessi fatti e le stesse cifre)")
        righe.append(MotoreLettera.fissa(s, v))
        righe.append("")
        righe.append("Scrivi solo la lettera, dal saluto all'ultima frase. Non scrivere la firma: la aggiunge Prisma.")
        return righe.joined(separator: "\n")
    }

    static func messaggi(_ s: SchedaLettera, _ v: VersioneLettera) -> [MessaggioModello] {
        [MessaggioModello(ruolo: .sistema, testo: istruzioni), MessaggioModello(ruolo: .utente, testo: scheda(s, v))]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = temperatura
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.restaInMemoria = vera.restaInMemoria
        o.massimoToken = massimoToken
        return o
    }

    static func piano(_ s: SchedaLettera, _ v: VersioneLettera, vera: ImpostazioniVera) -> PianoVera {
        PianoVera(scelta: SceltaVera(modalita: .lavoro, pensa: false), messaggi: messaggi(s, v), opzioni: opzioni(vera))
    }

    // MARK: - La verifica

    /// Parole che nella versione «senza il piano» raccontano rinunce o paure oltre le cifre (decisione 80).
    static let scenariNegativi = #"paur|rinunc|rimpiant|lasciat[oi] perdere|più strett|fatica|purtroppo|preoccup|ansia|angosc|sacrific|difficolt|non ce la|stent|povert|rimorso"#

    /// Nomi che la lettera non dice mai (compagnie, prodotti): la parola «Alleanza» e i nomi e gli emittenti dei
    /// prodotti del cliente (investimento, risparmio, previdenza, protezione; non la casa né il conto).
    static func vietati(_ posizioni: [Posizione]) -> [String] {
        var r = ["Alleanza"]
        for p in posizioni where p.area.proiettabile || p.area == .protezione {
            for t in [p.nome, p.emittente] {
                let x = t.trimmingCharacters(in: .whitespacesAndNewlines)
                if x.count >= 6 { r.append(x) }
            }
        }
        return r
    }

    /// nil se la lettera di Qwen va bene; altrimenti il motivo per cui resta quella di Prisma.
    static func controlla(_ testo: String, scheda s: SchedaLettera, versione v: VersioneLettera, vietati: [String]) -> String? {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "la lettera di Vera è vuota" }
        if t.contains("[") || t.contains("]") || t.contains("{") || t.contains("}") || t.contains("<") || t.contains(">") {
            return "la lettera di Vera ha dei segnaposto da completare"
        }
        guard CommentoVera.numeriConservati(bozza: MotoreLettera.ammessi(s, v), testo: t) else {
            return "una cifra non era nelle stime di Prisma"
        }
        if t.range(of: MessaggiVera.promesse, options: [.regularExpression, .caseInsensitive]) != nil
            || t.range(of: #"garantit|sicuramente|di sicuro|certamente avr"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return "la lettera di Vera prometteva un risultato"
        }
        let minuscolo = t.lowercased()
        if let nome = vietati.first(where: { minuscolo.contains($0.lowercased()) }) {
            return "la lettera di Vera nominava «\(nome)»"
        }
        if v == .senzaPiano, t.range(of: scenariNegativi, options: [.regularExpression, .caseInsensitive]) != nil {
            return "la lettera di Vera raccontava rinunce o paure oltre le cifre"
        }
        // Prima persona: chi scrive parla di sé («ho», «sono», «ti scrivo»)
        guard t.range(of: #"\b(ho|sono|ti scrivo|abbiamo)\b"#, options: [.regularExpression, .caseInsensitive]) != nil else {
            return "la lettera di Vera non era scritta in prima persona"
        }
        let parole = t.split(whereSeparator: { $0.isWhitespace }).count
        if parole > paroleMassime { return "la lettera di Vera era troppo lunga" }
        if parole < paroleMinime { return "la lettera di Vera era troppo corta" }
        return nil
    }

    /// Un pezzo del flusso si può mostrare: le cifre già scritte per intero sono nella scheda e non c'è una promessa.
    static func mostrabile(_ parziale: String, ammessi: String) -> Bool {
        MessaggiVera.mostrabile(parziale, fatti: ammessi)
    }

    /// Toglie grassetti, titoli e, in fondo, una firma scritta da Qwen (la mette Prisma).
    static func pulisci(_ testo: String, scheda s: SchedaLettera) -> String {
        MessaggiVera.pulisci(testo, firma: "\(s.nome) \(s.etaTraguardo) anni")
    }

    // MARK: - Scrivere

    /// La lettera fissa, con l'avviso del perché (nil se è la scelta di chi non ha Qwen in questo momento).
    static func fissa(_ s: SchedaLettera, _ v: VersioneLettera, avviso: String?) -> TestoLettera {
        TestoLettera(testo: MotoreLettera.conFirma(MotoreLettera.fissa(s, v), s), autore: .modelloFisso, modello: nil, avviso: avviso)
    }

    /// «Vera non è pronta: la lettera è quella di Prisma» (§3.1.6).
    static func avvisoNonPronta(_ motivo: String?) -> String {
        let m = (motivo ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".").union(.whitespaces))
        return "Vera non è pronta" + (m.isEmpty ? "" : " (\(m))") + ": la lettera è quella di Prisma."
    }

    /// Scrive la lettera con Qwen in streaming (`aggiorna` riceve il testo fin qui, senza firma, da qualunque thread).
    /// A fine flusso la verifica; se non passa, o se `motore` manca o non è pronto, resta la lettera fissa con l'avviso.
    static func scrivi(_ s: SchedaLettera, versione v: VersioneLettera, posizioni: [Posizione], motore: MotoreLocale?,
                       vera: ImpostazioniVera, aggiorna: ((String) -> Void)? = nil) async -> TestoLettera {
        guard let motore else { return fissa(s, v, avviso: avvisoNonPronta(nil)) }
        guard motore.disponibilita.pronto else { return fissa(s, v, avviso: avvisoNonPronta(motore.disponibilita.motivo)) }
        let ammessi = MotoreLettera.ammessi(s, v)
        do {
            var suPezzo: ((ParzialeVera) -> Void)?
            if let aggiorna {
                // Il flusso si mostra solo finché le cifre già arrivate sono quelle della scheda
                suPezzo = { parziale in
                    let t = pulisci(parziale.testo, scheda: s)
                    if mostrabile(t, ammessi: ammessi) { aggiorna(t) }
                }
            }
            let r = try await motore.scrivi(piano(s, v, vera: vera), aggiorna: suPezzo)
            let pulito = pulisci(r.testo, scheda: s)
            if let motivo = controlla(pulito, scheda: s, versione: v, vietati: vietati(posizioni)) {
                return fissa(s, v, avviso: maiuscola(motivo) + ": la lettera è quella di Prisma.")
            }
            return TestoLettera(testo: MotoreLettera.conFirma(pulito, s), autore: .vera, modello: motore.modello, avviso: nil)
        } catch is CancellationError {
            return fissa(s, v, avviso: "Scrittura interrotta: la lettera è quella di Prisma.")
        } catch {
            let m = (error as? ErroreVera)?.messaggio ?? error.localizedDescription
            return fissa(s, v, avviso: "Vera non ha potuto scrivere la lettera (\(m)): la lettera è quella di Prisma.")
        }
    }

    private static func maiuscola(_ s: String) -> String {
        guard let primo = s.first else { return s }
        return primo.uppercased() + s.dropFirst()
    }
}
