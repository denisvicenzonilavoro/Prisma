import Foundation

// «Trova le differenze» (Vera/BRIEF.md, funzione 11; template «Trova le differenze»): due documenti a confronto (il KID
// vecchio e quello nuovo, la polizza del cliente e la proposta). Prima il codice: le voci si allineano per chiave
// (i dati letti dai documenti, CampoEstratto, e per le polizze i limiti di «Cosa non copre»), si confrontano come valori
// (numeri, date, testi normalizzati) e ogni riga dice se migliora, peggiora o cambia per il cliente. La sintesi la
// scrive Prisma con le cifre della tabella; Qwen la può rendere più scorrevole, ma una cifra cambiata la scarta.

enum DifferenzeVera {
    /// Le voci da confrontare, nell'ordine della tabella, e come si leggono: per i costi e il rischio salire è peggio,
    /// per capitale e rendimento meglio, per il premio «costa di più».
    enum Verso { case piuAltoPeggio, piuAltoMeglio, premio, neutro }

    static let voci: [(CampoDocumento, String, Verso)] = [
        (.capitaleAssicurato, "Capitale assicurato", .piuAltoMeglio),
        (.premio, "Premio", .premio),
        (.costoIngresso, "Costi d'ingresso", .piuAltoPeggio),
        (.costoUscita, "Costi d'uscita", .piuAltoPeggio),
        (.costoAnnuo, "Costi correnti annui", .piuAltoPeggio),
        (.incidenzaCosti, "Costi totali annui", .piuAltoPeggio),
        (.sri, "Indicatore di rischio", .piuAltoPeggio),
        (.periodoDetenzione, "Periodo di detenzione raccomandato", .neutro),
        (.rendimentoModerato, "Scenario moderato", .piuAltoMeglio),
        (.decorrenza, "Decorrenza", .neutro),
        (.scadenza, "Scadenza", .neutro),
        (.beneficiari, "Beneficiari", .neutro),
        (.emittente, "Compagnia o emittente", .neutro),
        (.nomeProdotto, "Prodotto", .neutro),
    ]

    static func normale(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
            .split { !$0.isLetter && !$0.isNumber && $0 != "," && $0 != "." }.joined(separator: " ")
    }

    /// Il confronto voce per voce. Le voci che nessuno dei due documenti ha non entrano.
    static func righe(prima a: Documento, ora b: Documento, coperturePrima: CoperturaPolizza? = nil, copertureOra: CoperturaPolizza? = nil) -> [RigaDifferenza] {
        var righe: [RigaDifferenza] = []
        for (campo, nome, verso) in voci {
            let x = a.campo(campo), y = b.campo(campo)
            guard x != nil || y != nil else { continue }
            let vx = x?.valore.trimmingCharacters(in: .whitespacesAndNewlines) ?? "—"
            let vy = y?.valore.trimmingCharacters(in: .whitespacesAndNewlines) ?? "—"
            let esito: RigaDifferenza.Esito
            // Una voce che compare o sparisce: «nuova» e «tolta» solo per quello che è un bene (capitale, rendimento);
            // un costo o un premio che compare peggiora, uno che sparisce migliora; il resto cambia
            if x == nil {
                esito = verso == .piuAltoMeglio ? .nuova : (verso == .premio ? .peggiora : .cambia)
            } else if y == nil {
                esito = verso == .piuAltoMeglio ? .tolta : .cambia
            } else if let nx = EstrattoreDocumento.numero(vx), let ny = EstrattoreDocumento.numero(vy), campo != .decorrenza, campo != .scadenza {
                if abs(nx - ny) <= max(0.005, abs(nx) * 0.0005) { esito = .uguale } else {
                    switch verso {
                    case .piuAltoPeggio: esito = ny > nx ? .peggiora : .migliora
                    case .piuAltoMeglio: esito = ny > nx ? .migliora : .peggiora
                    case .premio: esito = ny > nx ? .costaDiPiu : .migliora
                    case .neutro: esito = .cambia
                    }
                }
            } else if let dx = EstrattoreDocumento.data(vx), let dy = EstrattoreDocumento.data(vy) {
                esito = Calendar.current.isDate(dx, inSameDayAs: dy) ? .uguale : .cambia
            } else {
                esito = normale(vx) == normale(vy) ? .uguale : .cambia
            }
            righe.append(RigaDifferenza(voce: nome, prima: vx, ora: vy, esito: esito, paginaPrima: x?.pagina, paginaOra: y?.pagina))
        }
        // Le polizze: le coperture lette per articolo (carenze, franchigie, massimali, esclusioni)
        if let p = coperturePrima, let o = copertureOra {
            righe += copertura(p, o)
        }
        return righe
    }

    /// Carenze, franchigie e massimali per tipo; le esclusioni come elenco (meno esclusioni = meglio).
    static func copertura(_ p: CoperturaPolizza, _ o: CoperturaPolizza) -> [RigaDifferenza] {
        var righe: [RigaDifferenza] = []
        for t in [LimiteCopertura.Tipo.carenza, .franchigia, .massimale] {
            let a = p.voci(t), b = o.voci(t)
            guard !a.isEmpty || !b.isEmpty else { continue }
            let ta = a.map(\.voce).joined(separator: "; "), tb = b.map(\.voce).joined(separator: "; ")
            let na = a.compactMap { FontiVera.numeri($0.voce).first?.valore }.first, nb = b.compactMap { FontiVera.numeri($0.voce).first?.valore }.first
            var esito = normale(ta) == normale(tb) ? RigaDifferenza.Esito.uguale : .cambia
            if let na, let nb, na != nb { esito = (t == .massimale) == (nb > na) ? .migliora : .peggiora }
            if a.isEmpty { esito = t == .massimale ? .nuova : .peggiora }
            if b.isEmpty { esito = t == .massimale ? .tolta : .migliora }
            righe.append(RigaDifferenza(voce: t.titolo, prima: a.isEmpty ? "Nessuna" : ta, ora: b.isEmpty ? "Nessuna" : tb, esito: esito,
                                        paginaPrima: a.first?.pagina, paginaOra: b.first?.pagina))
        }
        let ea = p.voci(.esclusione), eb = o.voci(.esclusione)
        if !ea.isEmpty || !eb.isEmpty {
            let esito: RigaDifferenza.Esito = eb.count < ea.count ? .migliora : (eb.count > ea.count ? .peggiora : (Set(ea.map { normale($0.voce) }) == Set(eb.map { normale($0.voce) }) ? .uguale : .cambia))
            righe.append(RigaDifferenza(voce: "Esclusioni", prima: "\(ea.count) esclusioni", ora: "\(eb.count) esclusioni", esito: esito,
                                        paginaPrima: ea.first?.pagina, paginaOra: eb.first?.pagina))
        }
        return righe
    }

    /// La sintesi di Prisma: cosa cambia per il cliente, con le cifre della tabella.
    static func sintesi(_ righe: [RigaDifferenza], cliente: String) -> String {
        let cambiate = righe.filter { $0.esito != .uguale }
        guard !cambiate.isEmpty else { return "Per \(cliente) non cambia niente nelle voci che Prisma ha letto." }
        let peggio = cambiate.filter { $0.esito == .peggiora || $0.esito == .costaDiPiu || $0.esito == .tolta }
        let meglio = cambiate.filter { $0.esito == .migliora || $0.esito == .nuova }
        var frasi: [String] = []
        if let p = peggio.first {
            frasi.append("Per \(cliente) \(peggio.count == 1 ? "peggiora una voce" : "peggiorano \(peggio.count) voci"): \(p.voce.lowercased()) passa da \(p.prima) a \(p.ora)")
        }
        if !meglio.isEmpty {
            frasi.append("\(meglio.count == 1 ? "migliora" : "migliorano") \(meglio.map { $0.voce.lowercased() }.joined(separator: ", "))")
        }
        let altre = cambiate.count - peggio.count - meglio.count
        if altre > 0 { frasi.append("\(altre == 1 ? "un'altra voce cambia" : "altre \(altre) voci cambiano") senza un verso chiaro") }
        let testo = frasi.joined(separator: "; ")
        return testo.prefix(1).uppercased() + testo.dropFirst() + ". Il resto è uguale."
    }

    static var istruzioni: String {
        IstruzioniVera.testo("differenze") ?? "Ti do la tabella del confronto tra due documenti di un cliente (voce, prima, ora, esito) e la sintesi di Prisma. Riscrivi la sintesi in due frasi, per il consulente: cosa cambia davvero per il cliente. Usa solo le cifre della tabella, senza cambiarle e senza fare conti nuovi."
    }

    static func messaggi(_ righe: [RigaDifferenza], sintesi: String, cliente: String) -> [MessaggioModello] {
        let tabella = righe.filter { $0.esito != .uguale }.map { "\($0.voce): \($0.prima) → \($0.ora) (\($0.etichetta))" }.joined(separator: "\n")
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: "CLIENTE: \(cliente)\nTABELLA\n\(tabella)\n\nSINTESI DI PRISMA\n\(sintesi)")]
    }

    /// I due documenti da confrontare per una frase («confronta il KID nuovo con il vecchio»): gli ultimi due dello stesso
    /// tipo del cliente (lo stesso prodotto se c'è), dal più vecchio al più nuovo.
    /// La frase sceglie il tipo da guardare prima («la polizza e la proposta» → polizze; «il KID» → KID).
    static func coppia(_ documenti: [Documento], frase: String = "") -> (Documento, Documento)? {
        let leggibili = documenti.filter { ($0.tipo == .kid || $0.tipo == .polizza || $0.tipo == .proposta) && !$0.campi.isEmpty }
        let polizzePrima = DateItaliane.cerca(#"polizz|propost|contratt|condizion"#, frase.lowercased()) != nil
            && DateItaliane.cerca(#"\bkid\b"#, frase.lowercased()) == nil
        for tipo in polizzePrima ? [Documento.Tipo.polizza, .kid] : [Documento.Tipo.kid, .polizza] {
            let stessi = leggibili.filter { $0.tipo == tipo || (tipo == .polizza && $0.tipo == .proposta) }.sorted { $0.importatoIl < $1.importatoIl }
            if let prodotto = stessi.last?.prodottoId {
                let s = stessi.filter { $0.prodottoId == prodotto }
                if s.count >= 2 { return (s[s.count - 2], s[s.count - 1]) }
            }
            if stessi.count >= 2 { return (stessi[stessi.count - 2], stessi[stessi.count - 1]) }
        }
        return nil
    }

    /// «Confronta…», «trova le differenze», «cosa cambia nel KID…».
    static func eUnaRichiesta(_ testo: String) -> Bool {
        let t = InterpreteComandi.pulisci(testo)
        return DateItaliane.cerca(#"^(?:confronta|metti a confronto|trova le differenze|cosa cambia (?:nel|nella|tra|fra)|che differenz)"#, t) != nil
            // Una «proposta» da sola è una proposta di posizione (Posizioni): servono KID, polizza o documento
            && DateItaliane.cerca(#"\b(kid|polizz|document|contratt|condizion)"#, t) != nil
    }
}
