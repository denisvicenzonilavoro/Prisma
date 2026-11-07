import Foundation

// MARK: - Studio › Parcelle e fatture: totali, scadenze, numerazione e ricavi per il Cruscotto (giro 2, specifica §3.5.3)
// Motore puro, senza SwiftUI, deterministico (riceve `oggi` e il calendario). Non sceglie regole fiscali: le voci fiscali
// sono di `MotoreFattura`, con i parametri del consulente.
//
// Regole:
// - Le bozze e le annullate non contano nei totali.
// - L'importo di una parcella è il netto a pagare delle voci congelate all'emissione (quello che il cliente paga);
//   senza voci (regime non completo) è l'imponibile delle righe, segnato come provvisorio (`senzaVoci`).
// - «Incassato nell'anno» = le pagate con la data d'incasso (o, se manca, la data del documento) nell'anno.
// - «Da incassare» = le emesse non pagate: dell'anno (per la data del documento) e in tutto.
// - «Scaduta» = emessa, non pagata, con la scadenza prima di oggi.
// - Numerazione: progressiva per anno, assegnata all'emissione (la bozza non ha numero), senza buchi: il prossimo è
//   il più alto dell'anno (annullate comprese) + 1, o il numero di partenza scelto dal consulente per quell'anno.
// - Ricavi per il Cruscotto (`RicavoConsulenza`): l'imponibile delle righe (senza IVA, contributo e bollo), alla data
//   d'incasso per le pagate e alla scadenza (o alla data del documento) per le emesse.

/// I totali delle parcelle di un anno.
struct TotaliParcelle: Equatable {
    let anno: Int
    let incassato: Double
    /// Emesse non pagate con la data del documento nell'anno.
    let daIncassare: Double
    /// Emesse non pagate di tutti gli anni.
    let daIncassareInTutto: Double
    /// Emesse non pagate con la scadenza passata (di tutti gli anni) e il loro importo.
    let scadute: Int
    let importoScaduto: Double
    /// Quante parcelle per stato nell'anno (per la data del documento).
    let bozze: Int
    let emesse: Int
    let pagate: Int
    let annullate: Int
    /// Quante parcelle contate non hanno le voci fiscali (importo provvisorio = imponibile).
    let senzaVoci: Int
}

enum MotoreParcelle {
    /// L'imponibile delle righe in euro (arrotondato al centesimo riga per riga).
    static func imponibile(_ p: Parcella) -> Double {
        MotoreFattura.euro(MotoreFattura.imponibileCentesimi(p.righe))
    }

    /// Quello che il cliente paga: il netto a pagare delle voci congelate, altrimenti l'imponibile (provvisorio).
    static func importo(_ p: Parcella) -> Double {
        p.voci?.nettoAPagare ?? imponibile(p)
    }

    /// Emessa, non pagata, con la scadenza prima di oggi.
    static func scaduta(_ p: Parcella, oggi: Date, cal: Calendar = .current) -> Bool {
        guard p.stato == .emessa, let s = p.scadenza else { return false }
        return cal.startOfDay(for: s) < cal.startOfDay(for: oggi)
    }

    /// Le parcelle scadute, dalla scadenza più vecchia.
    static func scadute(_ parcelle: [Parcella], oggi: Date, cal: Calendar = .current) -> [Parcella] {
        parcelle.filter { scaduta($0, oggi: oggi, cal: cal) }
            .sorted { ($0.scadenza ?? $0.data, $0.id) < ($1.scadenza ?? $1.data, $1.id) }
    }

    /// I totali di un anno. In O(n).
    static func totali(_ parcelle: [Parcella], anno: Int, oggi: Date, cal: Calendar = .current) -> TotaliParcelle {
        var incassato = 0, daIncassare = 0, inTutto = 0, scaduto = 0
        var scadute = 0, bozze = 0, emesse = 0, pagate = 0, annullate = 0, senzaVoci = 0
        for p in parcelle {
            let nell = p.anno == anno
            let c = MotoreFattura.centesimi(importo(p))
            switch p.stato {
            case .bozza:
                if nell { bozze += 1 }
            case .annullata:
                if nell { annullate += 1 }
            case .emessa:
                inTutto += c
                if p.voci == nil { senzaVoci += 1 }
                if nell {
                    emesse += 1
                    daIncassare += c
                }
                if scaduta(p, oggi: oggi, cal: cal) {
                    scadute += 1
                    scaduto += c
                }
            case .pagata:
                if nell { pagate += 1 }
                if cal.component(.year, from: p.incassataIl ?? p.data) == anno {
                    incassato += c
                    if p.voci == nil { senzaVoci += 1 }
                }
            }
        }
        let e = MotoreFattura.euro
        return TotaliParcelle(anno: anno, incassato: e(incassato), daIncassare: e(daIncassare), daIncassareInTutto: e(inTutto),
                              scadute: scadute, importoScaduto: e(scaduto), bozze: bozze, emesse: emesse, pagate: pagate,
                              annullate: annullate, senzaVoci: senzaVoci)
    }

    // MARK: - Numerazione

    /// Il prossimo numero progressivo dell'anno: il più alto già usato (annullate comprese) + 1, almeno il numero di
    /// partenza scelto dal consulente per quell'anno (senza: 1).
    static func prossimoProgressivo(_ parcelle: [Parcella], anno: Int, numerazione: NumerazioneFatture) -> Int {
        let massimo = parcelle.filter { $0.anno == anno && $0.stato.numerata }.compactMap(\.progressivo).max() ?? 0
        return max(massimo + 1, numerazione.primoNumeroPerAnno[anno] ?? 1)
    }

    /// Il numero scritto nel formato del consulente: `{anno}`, `{numero}`, `{numero:N}` (almeno N cifre) e `{prefisso}`;
    /// con il modello vuoto, il prefisso seguito dal numero.
    static func numeroTesto(progressivo: Int, anno: Int, numerazione n: NumerazioneFatture) -> String {
        let modello = n.modello.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !modello.isEmpty else { return n.prefisso + String(progressivo) }
        var testo = modello.replacingOccurrences(of: "{anno}", with: String(anno))
            .replacingOccurrences(of: "{prefisso}", with: n.prefisso)
        // {numero:N}
        while let inizio = testo.range(of: "{numero:"), let fine = testo.range(of: "}", range: inizio.upperBound..<testo.endIndex) {
            let cifre = Int(testo[inizio.upperBound..<fine.lowerBound]).map { min(max($0, 1), 10) } ?? 1
            let base = String(progressivo)
            let riempito = String(repeating: "0", count: max(0, cifre - base.count)) + base
            testo.replaceSubrange(inizio.lowerBound..<fine.upperBound, with: riempito)
        }
        return testo.replacingOccurrences(of: "{numero}", with: String(progressivo))
    }

    /// Il prossimo numero dell'anno, già scritto.
    static func prossimoNumero(_ parcelle: [Parcella], anno: Int, numerazione: NumerazioneFatture) -> String {
        numeroTesto(progressivo: prossimoProgressivo(parcelle, anno: anno, numerazione: numerazione), anno: anno,
                    numerazione: numerazione)
    }

    /// La parcella emessa alla data: prende l'anno, il numero progressivo e il numero scritto, e congela le voci fiscali
    /// se il regime è completo (altrimenti restano nil: l'importo è provvisorio). Una parcella già numerata non cambia.
    static func emessa(_ p: Parcella, tra parcelle: [Parcella], data: Date, numerazione: NumerazioneFatture,
                       regime: RegimeFatturazione, cal: Calendar = .current) -> Parcella {
        guard p.stato == .bozza else { return p }
        var e = p
        let anno = cal.component(.year, from: data)
        let altre = parcelle.filter { $0.id != p.id }
        let progressivo = prossimoProgressivo(altre, anno: anno, numerazione: numerazione)
        e.stato = .emessa
        e.anno = anno
        e.data = data
        e.progressivo = progressivo
        e.numero = numeroTesto(progressivo: progressivo, anno: anno, numerazione: numerazione)
        e.voci = MotoreFattura.calcola(righe: p.righe, regime: regime).voci
        return e
    }

    /// Il progressivo d'invio del file XML (5 caratteri, in base 36: «00001», «0000A»…), che non si ripete.
    static func progressivoInvio(_ n: Int) -> String {
        let testo = String(max(1, n), radix: 36, uppercase: true)
        return String(repeating: "0", count: max(0, 5 - testo.count)) + testo
    }

    // MARK: - Ricavi per il Cruscotto

    /// I ricavi della consulenza per `MotoreStudio` (StatoShell.ricaviConsulenzaStudio): pagate ed emesse.
    static func ricaviConsulenza(_ parcelle: [Parcella]) -> [RicavoConsulenza] {
        parcelle.compactMap { p in
            let importo = imponibile(p)
            guard importo > 0 else { return nil }
            switch p.stato {
            case .pagata:
                return RicavoConsulenza(clienteId: p.clienteId, data: p.incassataIl ?? p.data, importo: importo, incassata: true)
            case .emessa:
                return RicavoConsulenza(clienteId: p.clienteId, data: p.scadenza ?? p.data, importo: importo, incassata: false)
            case .bozza, .annullata:
                return nil
            }
        }
    }
}
