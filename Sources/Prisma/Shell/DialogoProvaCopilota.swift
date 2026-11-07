import Foundation

/// Il dialogo di prova del copilota (Design/template-novita-specifica.md §8.1.3): le sette righe del template fra Denis e
/// Giulia e le schede che ne nascono, per le istantanee del Mac (Shell/IstantaneeCopilota.swift) e dell'iPad.
///
/// DATI DI PROVA DICHIARATI: il dialogo è quello inventato del template, il consenso di Giulia è registrato solo dentro
/// la scena (lo stato delle istantanee non si salva) e le cifre (40.000 €, 90 € al mese, 450/550/650 €) sono quelle
/// dimostrative del template. Righe, evidenze e schede sono scritte qui, già nello stato finale, senza microfono; le
/// schede sono quelle che le regole di Prisma trovano sulle stesse frasi (Vera/Esempi/copilota.json), più l'attività
/// che nasce dalla polizza di un'altra compagnia.
enum DialogoProvaCopilota {
    static let cliente = "giulia"
    static let incontro = "incontro-giulia-casa"
    static let obiettivoCasa = "obiettivo-giulia-casa"

    struct Riga {
        let chi: PezzoTrascrizione.Chi
        let testo: String
        /// Le parole da illuminare, come compaiono nel testo.
        let evidenze: [String]
    }

    /// L'anno del matrimonio: sempre il prossimo, così la scena non invecchia.
    static var annoMatrimonio: Int { Calendar(identifier: .gregorian).component(.year, from: Date()) + 1 }

    static var righe: [Riga] {
        [
            Riga(chi: .consulente, testo: "Allora Giulia, partiamo dalla casa: come sono cambiati i tempi?", evidenze: []),
            Riga(chi: .cliente, testo: "Vorremmo comprare tra tre anni, ci servono circa 40.000 euro di anticipo.",
                 evidenze: ["tra tre anni", "40.000 euro"]),
            Riga(chi: .consulente, testo: "Bene. Hai altre polizze oltre a quelle che seguiamo insieme?", evidenze: []),
            Riga(chi: .cliente, testo: "Sì, una vita intera con un’altra compagnia, pago circa 90 euro al mese.",
                 evidenze: ["vita intera", "con un’altra compagnia", "90 euro al mese"]),
            Riga(chi: .cliente, testo: "Però i soldi della casa non voglio rischiarli, i mercati mi fanno un po’ paura.",
                 evidenze: ["non voglio rischiarli"]),
            Riga(chi: .cliente, testo: "E a giugno del \(annoMatrimonio) ci sposiamo, quindi qualche spesa in più.",
                 evidenze: ["giugno del \(annoMatrimonio)", "ci sposiamo"]),
            Riga(chi: .consulente, testo: "Perfetto, ti preparo un confronto con 450, 550 e 650 euro al mese.",
                 evidenze: ["confronto", "450, 550 e 650 euro al mese"]),
        ]
    }

    /// L'intervallo (in caratteri) della prima volta che `parola` compare in `testo`.
    static func intervallo(_ parola: String, in testo: String) -> IntervalloTesto? {
        guard let r = testo.range(of: parola) else { return nil }
        return IntervalloTesto(testo.distance(from: testo.startIndex, to: r.lowerBound),
                               testo.distance(from: testo.startIndex, to: r.upperBound))
    }

    static func idPezzo(_ i: Int) -> String { "pezzo-prova-\(i + 1)" }

    /// Le schede che nascono dalle prime `n` righe, nell'ordine in cui compaiono.
    static func schede(righe n: Int) -> [SchedaCopilota] {
        let r = righe
        func scheda(_ id: String, _ tipo: SchedaCopilota.Tipo, riga i: Int, cifre: CifreCopilota,
                    azione: SchedaCopilota.Azione? = nil, titolo: String? = nil) -> SchedaCopilota {
            var x = SchedaCopilota(id: id, tipo: tipo, titolo: titolo ?? "", azione: azione ?? .di(tipo), frase: r[i].testo,
                                   evidenze: r[i].evidenze.compactMap { intervallo($0, in: r[i].testo) },
                                   pezzoId: idPezzo(i), cifre: cifre)
            if titolo == nil { x.titolo = RiconoscitoreCopilota.titolo(x) }
            return x
        }
        var esito: [SchedaCopilota] = []
        if n >= 2 {
            var c = CifreCopilota()
            c.area = .casa
            c.importo = 40_000
            c.anniDaOggi = 3
            // Giulia ha già l'obiettivo casa: si aggiorna
            var x = scheda("obiettivo-casa", .obiettivo, riga: 1, cifre: c, azione: .aggiornaObiettivo)
            x.obiettivoId = obiettivoCasa
            esito.append(x)
        }
        if n >= 4 {
            var c = CifreCopilota()
            c.tipoPolizza = "vita intera"
            c.importo = 90
            c.frequenza = .mensile
            esito.append(scheda("polizzaEsterna-vita-intera", .polizzaEsterna, riga: 3, cifre: c))
            esito.append(scheda("attivita-chiedere-polizza-vita-intera", .attivita, riga: 3, cifre: CifreCopilota(),
                                titolo: "Chiedere la polizza vita intera per il confronto"))
        }
        if n >= 5 {
            var c = CifreCopilota()
            c.propensione = .prudente
            c.area = .casa
            esito.append(scheda("profilo-casa", .profilo, riga: 4, cifre: c))
        }
        if n >= 6 {
            var c = CifreCopilota()
            c.evento = .matrimonio
            c.anno = annoMatrimonio
            c.mese = 6
            esito.append(scheda("evento-matrimonio", .evento, riga: 5, cifre: c))
        }
        if n >= 7 {
            var c = CifreCopilota()
            c.importi = [450, 550, 650]
            c.frequenza = .mensile
            esito.append(scheda("attivita-preparare-un-confronto", .attivita, riga: 6, cifre: c,
                                titolo: "Preparare un confronto · 450 / 550 / 650 € al mese"))
        }
        return esito
    }

    /// Prepara la scena: Giulia con il consenso (se `consenso`), l'incontro di oggi aperto nel copilota e, con `righe`
    /// maggiore di zero, la sessione con le prime righe e le loro schede. Restituisce l'id della sessione.
    @discardableResult
    static func prepara(_ s: StatoShell, righe n: Int, consenso: Bool = true) -> String? {
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        let inizio = cal.date(bySettingHour: 9, minute: 30, second: 0, of: oggi) ?? oggi
        s.clienteAttivoId = cliente
        s.incontroAperto = incontro
        s.schedaIncontro = .ascolto
        s.copilota.modo = .copilota
        guard consenso else { return nil }
        // Mai nel futuro (le istantanee possono girare prima delle 9:30): la guardia lo rifiuterebbe
        s.registraConsensoCopilota(clienteId: cliente, modo: .aVoce, nota: "Dati di prova",
                                   data: min(inizio.addingTimeInterval(-300), Date()))
        guard n > 0, let sid = s.avviaSessioneCopilota(clienteId: cliente, incontroId: incontro, data: inizio),
              let k = s.dati.sessioniCopilota.firstIndex(where: { $0.id == sid }) else { return nil }
        let elenco = Array(righe.prefix(n))
        s.dati.sessioniCopilota[k].trascrizione = elenco.enumerated().map { i, r in
            var p = PezzoTrascrizione(testo: r.testo, quando: inizio.addingTimeInterval(Double(i) * 20), chi: r.chi,
                                      evidenze: r.evidenze.compactMap { intervallo($0, in: r.testo) })
            p.id = idPezzo(i)
            return p
        }
        s.dati.sessioniCopilota[k].schede = schede(righe: n)
        return sid
    }
}
