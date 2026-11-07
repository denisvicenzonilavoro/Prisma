import Foundation

// MARK: - Il patrimonio nel tempo del dossier (Clienti › Nel tempo, tema Apple §4.2.4)
// La «macchina del tempo» del cliente: 36 mesi indietro e 24 avanti, mese per mese. Qui solo cifre, senza SwiftUI e
// senza `Date()` nascosti (riceve `oggi`):
// - il passato: il patrimonio netto a ogni mese dai valori registrati delle posizioni in essere (rilevazioni,
//   decorrenza con il versamento iniziale, ultimo valore: `MotoreAndamentoPortafoglio.valore`), coperture escluse e
//   debiti in negativo; le fotografie dei riesami sono le cifre salvate davvero, quindi la linea passa per loro: lo
//   scarto fra la fotografia e i valori delle posizioni si distribuisce in linea retta fra una fotografia e l'altra
//   (prima della prima resta quello, dopo l'ultima si spegne fino a oggi). L'ultimo punto è il netto di oggi;
// - il futuro: la stima centrale è quella del patrimonio nel tempo di Posizioni (`MotorePatrimonio`, anno per anno,
//   unita in linea retta sui mesi), senza e con le proposte aperte; la fascia viene dagli scenari con le probabilità
//   (`MotoreMonteCarlo.simula`, 1.000 percorsi a seme fisso) sulle posizioni esposte ai mercati: 1 caso su 10 sotto,
//   1 su 10 sopra. È una stima, non una previsione.
// Pesante quanto basta (gli scenari): la vista la tiene da parte (`CacheNelTempo`) e la rifà solo quando cambiano
// posizioni, fotografie o giorno.

/// La stima dei prossimi 24 mesi: la linea centrale e i bordi della fascia (25 punti, il primo è oggi).
struct StimaNelTempo: Equatable {
    let centrale: [Double]
    let alta: [Double]
    let bassa: [Double]
    /// true se qualcosa oscilla con i mercati (altrimenti la fascia è chiusa sulla linea).
    let esposta: Bool
    /// I percorsi simulati.
    let scenari: Int
}

/// Il patrimonio netto del cliente da 36 mesi fa a 24 mesi da oggi, con le fotografie dei riesami.
struct StoriaNelTempo {
    static let mesiIndietro = 36
    static let mesiAvanti = 24

    let oggi: Date
    /// Da −36 a 0 (37 punti): il patrimonio netto al giorno di quel mese; l'ultimo è oggi.
    let passato: [Double]
    let giorniPassato: [Date]
    /// Da 0 a 24 (25 punti).
    let giorniFuturo: [Date]
    let senzaProposte: StimaNelTempo
    /// nil se non ci sono proposte aperte da proiettare.
    let conProposte: StimaNelTempo?
    /// Tutte le fotografie dei riesami del cliente, dalla più vecchia.
    let fotografie: [FotografiaRiesame]
    /// Le fotografie dentro i 36 mesi, con il mese (da −36 a 0).
    let fotografieNelGrafico: [(mese: Int, foto: FotografiaRiesame)]

    var nettoOggi: Double { passato.last ?? 0 }
    var haProposte: Bool { conProposte != nil }

    func stima(conProposte: Bool) -> StimaNelTempo {
        conProposte ? (self.conProposte ?? senzaProposte) : senzaProposte
    }

    /// Il giorno del mese `k` (−36…24, 0 = oggi).
    func giorno(_ k: Int) -> Date {
        if k <= 0 { return giorniPassato[max(0, min(giorniPassato.count - 1, k + Self.mesiIndietro))] }
        return giorniFuturo[max(0, min(giorniFuturo.count - 1, k))]
    }

    /// Il patrimonio netto (passato) o la stima centrale (futuro) al mese `k`.
    func valore(_ k: Int, conProposte: Bool) -> Double {
        if k <= 0 { return passato[max(0, min(passato.count - 1, k + Self.mesiIndietro))] }
        let s = stima(conProposte: conProposte).centrale
        return s[max(0, min(s.count - 1, k))]
    }

    /// La fotografia più vicina al giorno dato, e se è dello stesso mese. nil senza fotografie.
    func fotografiaVicina(a data: Date, cal: Calendar = .current) -> (foto: FotografiaRiesame, stessoMese: Bool)? {
        guard let vicina = fotografie.min(by: { abs($0.data.timeIntervalSince(data)) < abs($1.data.timeIntervalSince(data)) })
        else { return nil }
        let stesso = cal.isDate(vicina.data, equalTo: data, toGranularity: .month)
        return (vicina, stesso)
    }

    /// La fotografia salvata prima di quella data (per «cosa era cambiato»).
    func precedente(di foto: FotografiaRiesame) -> FotografiaRiesame? {
        fotografie.last { $0.data < foto.data && $0.id != foto.id }
    }
}

enum MotoreNelTempo {
    /// I percorsi degli scenari della fascia.
    static let scenari = MotoreMonteCarlo.traiettoriePredefinite

    /// La storia e la stima del cliente. `posizioni`: quelle del cliente; `fotografie`: le sue (in qualunque ordine);
    /// `patrimonio`: il patrimonio nel tempo di Posizioni (lo stesso calcolo del pannello, in cache nel dossier).
    static func calcola(cliente id: String, posizioni: [Posizione], fotografie: [FotografiaRiesame],
                        patrimonio: PatrimonioNelTempo, oggi: Date) -> StoriaNelTempo {
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: oggi)
        let indietro = StoriaNelTempo.mesiIndietro
        let avanti = StoriaNelTempo.mesiAvanti
        func mese(_ k: Int) -> Date { cal.date(byAdding: .month, value: k, to: inizio) ?? inizio }

        // Il passato dai valori registrati delle posizioni in essere (coperture escluse, debiti in negativo)
        let inEssere = posizioni.filter { $0.stato == .inEssere && $0.area != .protezione }
        var giorniPassato: [Date] = []
        var passato: [Double] = []
        for k in -indietro...0 {
            let g = k == 0 ? oggi : mese(k)
            giorniPassato.append(g)
            if k == 0 {
                passato.append(patrimonio.nettoOggi)
            } else {
                passato.append(inEssere.reduce(0) { somma, p in
                    let v = MotoreAndamentoPortafoglio.valore(p, al: g)
                    return somma + (p.area.passivo ? -v : v)
                })
            }
        }

        // Le fotografie: le cifre salvate davvero; la linea passa per loro
        let ordinate = fotografie.sorted { $0.data < $1.data }
        var nelGrafico: [(mese: Int, foto: FotografiaRiesame)] = []
        for f in ordinate where f.data >= giorniPassato[0] && f.data < inizio {
            let m = -(cal.dateComponents([.month], from: cal.startOfDay(for: f.data), to: inizio).month ?? 0)
            let k = max(-indietro, min(-1, m))
            // Due fotografie nello stesso mese: conta l'ultima
            nelGrafico.removeAll { $0.mese == k }
            nelGrafico.append((mese: k, foto: f))
        }
        if !nelGrafico.isEmpty {
            let scarti = nelGrafico.map { (mese: $0.mese, scarto: $0.foto.patrimonioNetto - passato[$0.mese + indietro]) }
            for k in -indietro...(-1) {
                passato[k + indietro] += scarto(al: k, scarti: scarti)
            }
        }

        // Il futuro: la stima del patrimonio nel tempo, unita in linea retta sui mesi, e la fascia degli scenari
        let giorniFuturo = (0...avanti).map { k in k == 0 ? oggi : mese(k) }
        let aperte = posizioni.filter { $0.stato == .proposta && $0.esito != .rifiutata && $0.esito != .accettata && $0.area.proiettabile }
        let senza = stima(patrimonio, conProposte: false,
                          mercato: inEssere.filter(\.area.proiettabile), seme: "nel-tempo-\(id)", oggi: oggi)
        let con: StimaNelTempo? = patrimonio.conProposte == nil ? nil
            : stima(patrimonio, conProposte: true, mercato: inEssere.filter(\.area.proiettabile) + aperte,
                    seme: "nel-tempo-\(id)-proposte", oggi: oggi)

        return StoriaNelTempo(oggi: oggi, passato: passato, giorniPassato: giorniPassato, giorniFuturo: giorniFuturo,
                              senzaProposte: senza, conProposte: con, fotografie: ordinate, fotografieNelGrafico: nelGrafico)
    }

    /// Lo scarto fra fotografie e posizioni al mese `k`: in linea retta fra due fotografie, uguale alla prima prima
    /// di lei, e dopo l'ultima che scende fino a zero a oggi (oggi le posizioni sono esatte).
    static func scarto(al k: Int, scarti: [(mese: Int, scarto: Double)]) -> Double {
        guard let primo = scarti.first, let ultimo = scarti.last else { return 0 }
        if k <= primo.mese { return primo.scarto }
        if k >= ultimo.mese {
            let durata = Double(-ultimo.mese)
            guard durata > 0 else { return 0 }
            return ultimo.scarto * Double(-k) / durata
        }
        for i in 1..<scarti.count where scarti[i].mese >= k {
            let a = scarti[i - 1]
            let b = scarti[i]
            let durata = Double(b.mese - a.mese)
            guard durata > 0 else { return b.scarto }
            return a.scarto + (b.scarto - a.scarto) * Double(k - a.mese) / durata
        }
        return ultimo.scarto
    }

    /// La stima centrale (dal patrimonio nel tempo) e la fascia degli scenari sulle posizioni esposte ai mercati.
    static func stima(_ p: PatrimonioNelTempo, conProposte: Bool, mercato: [Posizione], seme: String, oggi: Date) -> StimaNelTempo {
        let avanti = StoriaNelTempo.mesiAvanti
        let centrale = (0...avanti).map { k -> Double in
            let anno = k / 12
            let resto = Double(k % 12) / 12
            let a = p.valore(anno, conProposte: conProposte)
            let b = p.valore(min(p.anni, anno + 1), conProposte: conProposte)
            return a + (b - a) * resto
        }

        // Gli scenari: le linee del Monte Carlo come negli obiettivi (le proposte partono dal versamento iniziale)
        let linee = mercato.map { q -> LineaMonteCarlo in
            var l = MotoreMonteCarlo.linea(q, rendimentoPredefinito: IpotesiCalcolo.rendimentoPredefinito, mesi: avanti, data: oggi)
            if q.stato == .proposta { l.capitale = max(0, q.versamentoIniziale) }
            return l
        }
        let esposta = linee.contains { $0.volatilita > 0 && $0.capitale + $0.versamento > 0 }
        guard esposta else {
            return StimaNelTempo(centrale: centrale, alta: centrale, bassa: centrale, esposta: false, scenari: 0)
        }
        let esito = MotoreMonteCarlo.simula(linee, mesi: avanti, traguardo: 0, traiettorie: scenari,
                                            seme: MotoreMonteCarlo.seme(seme))
        func ampiezze(_ anno: Int) -> (su: Double, giu: Double) {
            guard let a = esito.anni.first(where: { $0.anno == anno }) else { return (0, 0) }
            return (max(0, a.p90 - a.p50), max(0, a.p50 - a.p10))
        }
        let uno = ampiezze(1)
        let due = ampiezze(2)
        var alta: [Double] = []
        var bassa: [Double] = []
        for k in 0...avanti {
            let su: Double
            let giu: Double
            if k <= 12 {
                // Nel primo anno l'incertezza cresce con la radice del tempo
                let f = (Double(k) / 12).squareRoot()
                su = uno.su * f
                giu = uno.giu * f
            } else {
                let f = Double(k - 12) / 12
                su = uno.su + (due.su - uno.su) * f
                giu = uno.giu + (due.giu - uno.giu) * f
            }
            alta.append(centrale[k] + su)
            bassa.append(centrale[k] - giu)
        }
        return StimaNelTempo(centrale: centrale, alta: alta, bassa: bassa, esposta: true, scenari: esito.traiettorie)
    }
}

/// La storia nel tempo già calcolata, per cliente: si rifà quando cambiano posizioni, fotografie, proposte o giorno.
/// Solo dal thread principale (le viste).
enum CacheNelTempo {
    nonisolated(unsafe) private static var memoria: [Int: StoriaNelTempo] = [:]
    private static let massimo = 12

    static func storia(cliente id: String, posizioni: [Posizione], fotografie: [FotografiaRiesame],
                       patrimonio: () -> PatrimonioNelTempo, oggi: Date = Date()) -> StoriaNelTempo {
        var h = Hasher()
        h.combine(id)
        h.combine(posizioni)
        for f in fotografie {
            h.combine(f.id)
            h.combine(f.data)
            h.combine(f.patrimonioNetto)
        }
        h.combine(Calendar.current.startOfDay(for: oggi))
        let chiave = h.finalize()
        if let s = memoria[chiave] { return s }
        let s = MotoreNelTempo.calcola(cliente: id, posizioni: posizioni, fotografie: fotografie,
                                       patrimonio: patrimonio(), oggi: oggi)
        if memoria.count >= massimo { memoria.removeAll() }
        memoria[chiave] = s
        return s
    }
}
