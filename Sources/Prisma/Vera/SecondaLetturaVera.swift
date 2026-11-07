import Foundation

// «La seconda lettura» (Vera/BRIEF.md, funzione 10; template «La seconda lettura»): prima che un messaggio si apra in
// Mail o in Messaggi, o che un prospetto, un report o una scheda di adeguatezza diventi un PDF, Prisma lo rilegge.
// Prima il codice: le parole a rischio («garantito», «sicuro», «senza rischi»…), le cifre confrontate con la scheda di
// Prisma («Mai a caso»: una cifra senza fonte, e la più vicina della scheda come correzione), il KID e i documenti da
// consegnare che mancano, la coerenza con il profilo (i controlli di MotoreAdeguatezza). Vera avvisa e propone: la
// valutazione finale resta al consulente (scelta dell'utente: avvisa, non blocca). Poi Qwen può abbozzare la
// motivazione di adeguatezza con le sole cifre di Prisma, che entra nella scheda solo con «Inserisci».

enum SecondaLetturaVera {
    /// Le parole a rischio e la correzione proposta (le due liste di Prisma unite: MessaggiVera.promesse e
    /// TestiAnnoInsieme.paroleVietate). L'ordine conta: prima le espressioni più lunghe.
    static let parole: [(schema: String, titolo: String, correzione: String?)] = [
        (#"rendimento garantit[oa]"#, "Rendimento «garantito»", "rendimento atteso, non garantito"),
        (#"rendimenti garantiti"#, "Rendimenti «garantiti»", "rendimenti attesi, non garantiti"),
        (#"guadagno (?:sicuro|garantito|certo)"#, "Un guadagno promesso", "possibile guadagno"),
        (#"senza (?:alcun |nessun )?rischi[o]?\b"#, "«Senza rischi»", "con un rischio contenuto"),
        (#"\b(?:nessun rischio|rischio zero)\b"#, "«Nessun rischio»", nil),
        (#"sicuramente (?:guadagn\w*|rend\w*)"#, "Una promessa di rendimento", nil),
        (#"\b(?:ti|le|vi|gli) assicuro (?:un|una|che)\b"#, "Una promessa", nil),
        (#"\b(?:garantito|garantita|garantiti|garantite)\b"#, "Parola a rischio «garantito»", nil),
        (#"\b(?:sicuro|sicura|sicuri|sicure)\b"#, "Parola a rischio «sicuro»", nil),
        (#"\b(?:certo|certa|certi|certe) (?:rendiment\w*|guadagn\w*|risultat\w*)"#, "Un risultato «certo»", nil),
    ]

    /// Le espressioni su garanzie vere del contratto, che non sono a rischio («garanzia di restituzione del capitale
    /// prevista dal contratto», «sicuro» in «assicurato»): si tolgono prima del controllo.
    private static let ammesse = #"assicurat\w*|assicurazion\w*|assicurativ\w*|previst[oa] dal contratto|alle condizioni del contratto|garanzia contrattuale|garanzie (?:della polizza|del contratto)|in sicurezza|capitale garantit[oa]|minimo garantit[oa]|garantito o senza mercato|non (?:è |sono |siano |sia |e )?(?:mai |né )?(?:garantit\w*|sicur\w*|cert[oaie])|né garantit\w*"#

    // MARK: - Il controllo

    /// Rilegge un testo: parole, cifre (contro le fonti di Prisma: la scheda del cliente, la bozza, i calcoli), allegati.
    /// `fonti`: il testo di Prisma con le cifre ammesse; `allegatiMancanti`: i documenti da consegnare non ancora presenti;
    /// `controlli`: i controlli di adeguatezza della proposta (rossi e gialli diventano avvisi).
    static func rileggi(_ testo: String, oggetto: String, fonti: String, fonteCliente: FonteVera?, allegatiMancanti: [String] = [],
                        controlli: [ControlloAdeguatezza] = []) -> EsitoSecondaLettura {
        var avvisi: [AvvisoLettura] = []
        let minuscolo = testo.lowercased()
        let pulito = minuscolo.replacingOccurrences(of: ammesse, with: " ", options: .regularExpression)
        var gia: Set<String> = []
        // 1. Le parole a rischio
        for p in parole {
            guard let (r, _) = DateItaliane.cerca(p.schema, pulito) else { continue }
            let trovatoMinuscolo = (pulito as NSString).substring(with: r)
            guard !gia.contains(where: { $0.contains(trovatoMinuscolo) || trovatoMinuscolo.contains($0) }) else { continue }
            gia.insert(trovatoMinuscolo)
            // Il pezzo con le maiuscole del testo originale
            let originale = testo.range(of: trovatoMinuscolo, options: .caseInsensitive).map { String(testo[$0]) } ?? trovatoMinuscolo
            avvisi.append(AvvisoLettura(tipo: .parola, gravita: .rosso, titolo: "Frase a rischio",
                                        dettaglio: "«\(originale)»: \(p.titolo.lowercased()) non si scrive se il prodotto non lo prevede per contratto.",
                                        trovato: p.correzione == nil ? nil : originale, correzione: p.correzione))
        }
        // 2. Le cifre: ogni cifra deve avere la sua fonte in Prisma («Mai a caso»)
        let registro = (fonteCliente.map(FontiVera.registro) ?? []) + FontiVera.registro(testo: fonti)
        // Solo gli importi e le percentuali: giorni, orari e numeri di telefono non sono cifre da controllare
        for c in FontiVera.abbina(testo, registro: registro) where !c.trovata {
            let n = FontiVera.numeri(c.testo).first
            guard let u = n?.unita, u == .euro || u == .percento else { continue }
            let vicina = n.flatMap { x in registro.filter { ($0.unita == x.unita || x.unita == .nessuna) && $0.valore > 0 }
                .min { abs($0.valore - x.valore) < abs($1.valore - x.valore) } }
                .flatMap { v -> VoceFonte? in
                    guard let x = n, x.valore > 0 else { return nil }
                    return abs(v.valore - x.valore) / x.valore <= 0.35 ? v : nil
                }
            if let v = vicina {
                let corretta = v.unita == .euro ? Formati.euro(v.valore) : (v.unita == .percento ? Formati.percentuale(v.valore) : FontiVera.testoValore(v.valore))
                avvisi.append(AvvisoLettura(tipo: .numero, gravita: .arancio, titolo: "Il numero non torna",
                                            dettaglio: "«\(c.testo)» non è in Prisma; nella fonte c'è \(corretta) (\(v.origine)).",
                                            trovato: c.testo, correzione: corretta))
            } else {
                avvisi.append(AvvisoLettura(tipo: .numero, gravita: .arancio, titolo: "Una cifra senza fonte",
                                            dettaglio: "«\(c.testo)» non viene dalla scheda né dai calcoli di Prisma: controllala.", trovato: nil, correzione: nil))
            }
        }
        // 3. Gli allegati
        for a in allegatiMancanti {
            avvisi.append(AvvisoLettura(tipo: .allegato, gravita: .arancio, titolo: "Manca un allegato",
                                        dettaglio: "\(a) non è tra i documenti consegnati o allegati.", trovato: nil, correzione: nil))
        }
        // 4. La coerenza con il profilo
        for c in controlli {
            switch c.semaforo {
            case .rosso:
                avvisi.append(AvvisoLettura(tipo: .profilo, gravita: .rosso, titolo: "Non coerente: \(c.tipo.rawValue)", dettaglio: c.esito, trovato: nil, correzione: nil))
            case .giallo:
                avvisi.append(AvvisoLettura(tipo: .profilo, gravita: .arancio, titolo: "Da verificare: \(c.tipo.rawValue)", dettaglio: c.esito, trovato: nil, correzione: nil))
            case .verde:
                avvisi.append(AvvisoLettura(tipo: .profilo, gravita: .verde, titolo: "Coerente con il profilo: \(c.tipo.rawValue)", dettaglio: c.esito, trovato: nil, correzione: nil))
            case .grigio:
                break
            }
        }
        return EsitoSecondaLettura(oggetto: oggetto, avvisi: avvisi.sorted { $0.gravita.rawValue < $1.gravita.rawValue })
    }

    /// I documenti da consegnare per una proposta che mancano (il KID prima di tutto).
    static func mancanti(_ esito: EsitoAdeguatezza?) -> [String] {
        (esito?.documenti ?? []).filter { !$0.nonPertinente && !$0.fatto }.map { $0.voce.titolo }
    }

    // MARK: - La bozza della motivazione di adeguatezza (Qwen, cifre di Prisma)

    /// La bozza di Prisma: obiettivo, orizzonte, profilo, controlli e documenti, con le parole dei controlli.
    static func bozzaMotivazione(_ e: EsitoAdeguatezza, cliente: Cliente) -> String {
        var frasi: [String] = []
        if let b = e.controllo(.bisogno)?.esito, !b.isEmpty { frasi.append("La proposta risponde al bisogno indicato: \(b.prefix(1).lowercased() + b.dropFirst()).") }
        for t in [ControlloAdeguatezza.Tipo.rischio, .orizzonte, .esperienza, .liquidita, .concentrazione, .sostituzione] {
            guard let c = e.controllo(t), c.semaforo != .grigio else { continue }
            frasi.append(c.esito.hasSuffix(".") ? c.esito : c.esito + ".")
        }
        if !e.documenti.isEmpty {
            frasi.append(e.documentiCompleti ? "La documentazione precontrattuale è stata consegnata." : "La documentazione precontrattuale va consegnata prima della firma.")
        }
        return frasi.joined(separator: " ")
    }

    static var istruzioniMotivazione: String {
        IstruzioniVera.testo("motivazione") ?? "Scrivi la motivazione di adeguatezza di una proposta, a partire dalla bozza di Prisma: tre o quattro frasi in italiano, formali, in terza persona sul cliente. Usa solo i fatti e le cifre della bozza, senza cambiarle e senza aggiungerne. Niente promesse di rendimento."
    }

    static func messaggiMotivazione(_ bozza: String, cliente: String) -> [MessaggioModello] {
        [MessaggioModello(ruolo: .sistema, testo: istruzioniMotivazione),
         MessaggioModello(ruolo: .utente, testo: "CLIENTE: \(cliente)\nBOZZA DI PRISMA\n\(bozza)")]
    }
}

extension FontiVera {
    /// Un numero senza unità, all'italiana («11», «7,5»).
    static func testoValore(_ v: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: v)) ?? String(v)
    }
}
