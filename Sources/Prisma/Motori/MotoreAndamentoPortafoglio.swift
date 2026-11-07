import Foundation

// MARK: - L'andamento del portafoglio (Posizioni › Portafoglio, tema Apple §4.1)
// La card del portafoglio mostra il totale in essere, il delta da inizio anno e il grafico «In essere / Con le
// proposte». Qui si calcolano le cifre, senza SwiftUI e senza `Date()` nascosti (riceve `oggi`):
// - la storia: mese per mese dal 1° gennaio a oggi, il valore delle posizioni in essere (debiti esclusi) dalle
//   loro rilevazioni (`Posizione.rilevazioni`, la decorrenza con il versamento iniziale, l'ultimo valore),
//   interpolato in linea retta fra due valori noti; l'ultimo punto è il valore di oggi (lo stesso del riepilogo);
// - la stima con le proposte: da oggi a `mesiStima` mesi, la crescita attesa delle posizioni in essere
//   (MotorePatrimonio.serie, un anno, distribuita sui mesi) più le proposte aperte che entrano un po' alla volta
//   (`RiepilogoPosizioni.valoreProposte`: versamento iniziale e un anno di premi);
// - la fascia d'incertezza: 1 caso su 10 sopra e 1 su 10 sotto, con la volatilità delle posizioni pesata sul valore
//   (MotoreMonteCarlo.volatilita, correlazione piena come nel Monte Carlo) e l'ampiezza che cresce con √t.
// Non si salvano: si rifanno quando cambiano i dati (la Shell li tiene da parte, DerivatiDati).

/// Le cifre della card del portafoglio: totali, delta e serie del grafico (in euro).
struct AndamentoPortafoglio: Equatable {
    /// Il valore in essere oggi (debiti esclusi), come `RiepilogoPosizioni.attivita`.
    let inEssere: Double
    /// In essere più le proposte aperte.
    let conProposte: Double
    /// Proposte aperte (bozza o presentata) e il loro valore.
    let proposteAperte: Int
    let valoreProposte: Double
    /// I giorni della storia (primo del mese, l'ultimo è oggi) e i valori, punto per punto.
    let giorniStoria: [Date]
    let storia: [Double]
    /// I mesi della stima (il primo è oggi) e i valori, con i bordi della fascia.
    let giorniStima: [Date]
    let stima: [Double]
    let stimaAlta: [Double]
    let stimaBassa: [Double]
    /// La volatilità annua usata per la fascia (0,08 = 8%).
    let volatilita: Double

    /// Dal primo punto della storia a oggi.
    var delta: Double { (storia.last ?? 0) - (storia.first ?? 0) }
    /// Il giorno da cui parte il delta.
    var inizio: Date? { giorniStoria.first }
    /// La data della stima finale.
    var fineStima: Date? { giorniStima.last }
    /// Niente da mostrare: nessuna posizione in essere e nessuna proposta.
    var vuoto: Bool { inEssere < 0.5 && valoreProposte < 0.5 }
}

enum MotoreAndamentoPortafoglio {
    /// Mesi della stima con le proposte (il grafico si allarga di altrettanti mesi).
    static let mesiStima = 6
    /// Il percentile della fascia: 1 caso su 10 sopra, 1 su 10 sotto (z del 90° percentile della normale).
    static let zFascia = 1.2816
    /// Con meno di tre mesi dall'inizio dell'anno la storia parte da `mesiMinimi` mesi prima (il grafico non resta
    /// di due punti a gennaio e febbraio).
    static let mesiMinimi = 3

    /// L'andamento delle posizioni date (di tutti i clienti o di uno solo).
    static func calcola(_ posizioni: [Posizione], oggi: Date) -> AndamentoPortafoglio {
        let cal = Calendar.current
        let inEssere = posizioni.filter { $0.stato == .inEssere && !$0.area.passivo }
        let riepilogo = RiepilogoPosizioni(posizioni)
        let attuale = riepilogo.attivita

        // La storia: il 1° di ogni mese da gennaio (o da qualche mese prima), poi oggi
        let giorni = giorniStoria(oggi: oggi)
        var storia = giorni.dropLast().map { g in inEssere.reduce(0) { $0 + valore($1, al: g) } }
        storia.append(attuale)

        // La crescita attesa delle posizioni in essere in un anno (con i versamenti), distribuita sui mesi
        let serie = MotorePatrimonio.serie(inEssere, anni: 1, oggi: oggi)
        let crescitaAnnua = serie.count > 1 ? serie[1].valore - serie[0].valore : 0

        // La volatilità pesata sul valore (in essere e proposte aperte)
        let aperte = posizioni.filter { $0.stato == .proposta && $0.esito != .accettata && $0.esito != .rifiutata }
        let volatilita = volatilitaPesata(inEssere: inEssere, proposte: aperte)

        var giorniStima: [Date] = []
        var stima: [Double] = []
        var alta: [Double] = []
        var bassa: [Double] = []
        for k in 0...mesiStima {
            let t = Double(k) / 12
            let v = attuale + crescitaAnnua * t + riepilogo.valoreProposte * Double(k) / Double(mesiStima)
            let ampiezza = zFascia * volatilita * t.squareRoot()
            giorniStima.append(k == 0 ? oggi : (cal.date(byAdding: .month, value: k, to: oggi) ?? oggi))
            stima.append(v)
            alta.append(v * exp(ampiezza))
            bassa.append(v * exp(-ampiezza))
        }

        return AndamentoPortafoglio(inEssere: attuale, conProposte: attuale + riepilogo.valoreProposte,
                                    proposteAperte: riepilogo.proposteAperte, valoreProposte: riepilogo.valoreProposte,
                                    giorniStoria: giorni, storia: storia, giorniStima: giorniStima, stima: stima,
                                    stimaAlta: alta, stimaBassa: bassa, volatilita: volatilita)
    }

    /// I giorni della storia: il 1° di ogni mese da gennaio dell'anno di `oggi` (da `mesiMinimi` mesi prima se
    /// l'anno è appena cominciato) fino al mese scorso, più oggi come ultimo punto: il mese in corso è oggi, così
    /// i punti restano a un mese l'uno dall'altro e l'asse non scrive due volte lo stesso mese.
    static func giorniStoria(oggi: Date) -> [Date] {
        let cal = Calendar.current
        let inizioOggi = cal.startOfDay(for: oggi)
        let inizioMese = cal.dateInterval(of: .month, for: inizioOggi)?.start ?? inizioOggi
        let mese = cal.component(.month, from: inizioOggi)
        let indietro = max(mese - 1, mesiMinimi)
        var giorni: [Date] = []
        for k in stride(from: indietro, through: 1, by: -1) {
            if let g = cal.date(byAdding: .month, value: -k, to: inizioMese) { giorni.append(g) }
        }
        giorni.append(oggi)
        return giorni
    }

    /// Il valore di una posizione a una data passata: 0 prima della decorrenza, poi i valori noti (versamento
    /// iniziale alla decorrenza, rilevazioni, ultimo valore alla sua data) uniti in linea retta. Prima del primo
    /// valore noto resta quel valore; dopo l'ultimo, l'ultimo.
    static func valore(_ p: Posizione, al giorno: Date) -> Double {
        if let d = p.decorrenza, d > giorno { return 0 }
        var punti: [(data: Date, valore: Double)] = (p.rilevazioni ?? []).map { (data: $0.data, valore: $0.controvalore) }
        if let d = p.dataValore { punti.append((data: d, valore: p.valore)) }
        punti.sort { $0.data < $1.data }
        if let d = p.decorrenza, p.versamentoIniziale > 0, punti.first.map({ $0.data > d }) ?? true {
            punti.insert((data: d, valore: p.versamentoIniziale), at: 0)
        }
        guard let primo = punti.first, let ultimo = punti.last else { return p.valore }
        if giorno <= primo.data { return primo.valore }
        if giorno >= ultimo.data { return ultimo.valore }
        for i in 1..<punti.count where punti[i].data >= giorno {
            let a = punti[i - 1]
            let b = punti[i]
            let durata = b.data.timeIntervalSince(a.data)
            guard durata > 0 else { return b.valore }
            let f = giorno.timeIntervalSince(a.data) / durata
            return a.valore + (b.valore - a.valore) * f
        }
        return ultimo.valore
    }

    /// La volatilità annua (frazione) pesata sul valore: posizioni in essere e versamento delle proposte aperte.
    static func volatilitaPesata(inEssere: [Posizione], proposte: [Posizione]) -> Double {
        var peso = 0.0
        var somma = 0.0
        for p in inEssere where p.valore > 0 {
            peso += p.valore
            somma += p.valore * MotoreMonteCarlo.volatilita(p) / 100
        }
        for p in proposte {
            let v = p.versamentoIniziale + p.premioAnnuo
            guard v > 0 else { continue }
            peso += v
            somma += v * MotoreMonteCarlo.volatilita(p) / 100
        }
        return peso > 0 ? somma / peso : 0
    }
}

/// Prove dell'andamento del portafoglio (chiamate da `ProvaCalcoli.esegui()`).
enum ProvaAndamentoPortafoglio {
    static func esegui(_ verifica: VerificaCalcoli) {
        let oggi = AiutiProva.data(2026, 11, 3)

        // Il valore a una data: 0 prima della decorrenza, poi in linea retta fra versamento e rilevazioni.
        // Un conto (liquidità senza rendimento): la stima cresce solo con le proposte
        let p = AiutiProva.posizione("Conto", .liquidita, 12_000) { p in
            p.decorrenza = AiutiProva.data(2025, 1, 1)
            p.versamentoIniziale = 10_000
            p.dataValore = AiutiProva.data(2026, 11, 1)
            p.rilevazioni = [Rilevazione(data: AiutiProva.data(2025, 12, 31), controvalore: 10_000),
                             Rilevazione(data: AiutiProva.data(2026, 6, 1), controvalore: 11_000)]
        }
        verifica("Andamento: prima della decorrenza vale 0", MotoreAndamentoPortafoglio.valore(p, al: AiutiProva.data(2024, 12, 1)), 0)
        verifica("Andamento: alla decorrenza il versamento", MotoreAndamentoPortafoglio.valore(p, al: AiutiProva.data(2025, 1, 1)), 10_000)
        verifica("Andamento: alla rilevazione il suo valore", MotoreAndamentoPortafoglio.valore(p, al: AiutiProva.data(2026, 6, 1)), 11_000)
        let meta = MotoreAndamentoPortafoglio.valore(p, al: AiutiProva.data(2026, 8, 31))
        verifica.vero("Andamento: fra due valori in linea retta", meta > 11_000 && meta < 12_000)
        verifica("Andamento: dopo l'ultimo valore resta quello", MotoreAndamentoPortafoglio.valore(p, al: AiutiProva.data(2026, 12, 1)), 12_000)

        // I giorni della storia: da gennaio a oggi (i primi del mese da gennaio a ottobre più oggi, che fa da
        // novembre), all'inizio dell'anno qualche mese prima
        let giorni = MotoreAndamentoPortafoglio.giorniStoria(oggi: oggi)
        verifica("Andamento: punti della storia a novembre", Double(giorni.count), 11)
        verifica.vero("Andamento: il mese in corso non si ripete",
                      giorni.dropLast().allSatisfy { Calendar.current.component(.month, from: $0) != 11 })
        verifica.vero("Andamento: la storia parte il 1° gennaio", giorni.first.map { Calendar.current.component(.month, from: $0) == 1 } ?? false)
        let gennaio = MotoreAndamentoPortafoglio.giorniStoria(oggi: AiutiProva.data(2027, 1, 20))
        verifica("Andamento: a gennaio si parte tre mesi prima", Double(gennaio.count), 4)

        // Il quadro: in essere uguale al riepilogo, con le proposte più il loro valore, debiti esclusi
        var proposta = AiutiProva.posizione("Proposta", .investimento, 0) { p in
            p.stato = .proposta
            p.esito = .presentata
            p.versamentoIniziale = 5_000
            p.controvalore = nil
        }
        proposta.sri = 3
        let debito = AiutiProva.posizione("Mutuo", .debiti, 80_000)
        let a = MotoreAndamentoPortafoglio.calcola([p, proposta, debito], oggi: oggi)
        verifica("Andamento: in essere senza debiti", a.inEssere, 12_000)
        verifica("Andamento: con le proposte", a.conProposte, 17_000)
        verifica("Andamento: proposte aperte", Double(a.proposteAperte), 1)
        verifica("Andamento: l'ultimo punto della storia è oggi", a.storia.last ?? 0, 12_000)
        verifica("Andamento: il delta da gennaio", a.delta, 2_000, tolleranza: 10)
        verifica("Andamento: punti della stima", Double(a.stima.count), Double(MotoreAndamentoPortafoglio.mesiStima + 1))
        verifica("Andamento: la stima parte da oggi", a.stima.first ?? 0, 12_000)
        verifica("Andamento: la stima finale comprende le proposte", a.stima.last ?? 0, 17_000)
        var dentro = true
        for i in a.stima.indices where a.stimaAlta[i] < a.stima[i] - 0.001 || a.stimaBassa[i] > a.stima[i] + 0.001 {
            dentro = false
        }
        verifica.vero("Andamento: la fascia contiene la stima", dentro)
        verifica.vero("Andamento: la fascia si allarga nel tempo",
                      ((a.stimaAlta.last ?? 0) - (a.stimaBassa.last ?? 0)) > ((a.stimaAlta[1]) - (a.stimaBassa[1])))
        verifica("Andamento: oggi la fascia è chiusa", (a.stimaAlta.first ?? 0) - (a.stimaBassa.first ?? 0), 0)

        // Senza niente: vuoto
        let vuoto = MotoreAndamentoPortafoglio.calcola([], oggi: oggi)
        verifica.vero("Andamento: senza posizioni è vuoto", vuoto.vuoto && vuoto.delta == 0)
    }
}
