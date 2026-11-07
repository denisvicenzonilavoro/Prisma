import Foundation

/// La strada di un obiettivo mese per mese, per il cursore del versamento del dettaglio (tema Apple, §4.2.3):
/// ciò che c'è già (posizioni collegate con le loro ipotesi, costi e imposte, più l'accantonato) e il netto di
/// 1 € versato ogni mese al rendimento dell'obiettivo, campionati a ogni anno intero e alla scadenza con
/// `MotoreObiettivo` (gli stessi conti del piano); fra due campioni si interpola. Il versamento del cursore entra
/// in modo lineare, quindi copertura, data di arrivo e scarto si ricalcolano dal vivo a ogni passo senza rifare la
/// proiezione. Il versamento previsto già salvato nell'obiettivo NON è dentro `base`: è il valore del cursore.
struct CurvaObiettivo {
    /// Il giorno da cui partono i mesi.
    let inizio: Date
    /// Mesi da oggi alla scadenza (0 se è passata).
    let mesiScadenza: Int
    /// Fin dove si cerca la data di arrivo: 30 anni oltre la scadenza, come «Spostare la data».
    let mesiMassimi: Int
    /// I mesi dei campioni, crescenti: 0, 12, 24… e la scadenza.
    private let mesi: [Int]
    /// Ciò che c'è già, netto, a ogni campione.
    private let base: [Double]
    /// Il netto di 1 € al mese a ogni campione.
    private let unita: [Double]
    /// Importo in euro di oggi e inflazione annua (l'obiettivo si rivaluta mese per mese).
    private let importo: Double
    private let inflazione: Double

    /// Anni oltre la scadenza in cui si cerca ancora la data di arrivo.
    static let anniOltreScadenza = 30

    init(_ o: Obiettivo, posizioni: [Posizione], data: Date = Date()) {
        let cal = Calendar.current
        inizio = data
        let scadenza = max(0, cal.dateComponents([.month], from: data, to: o.scadenza).month ?? 0)
        mesiScadenza = scadenza
        mesiMassimi = scadenza + Self.anniOltreScadenza * 12
        importo = o.importo
        inflazione = IpotesiCalcolo.inflazione
        let collegate = posizioni.filter { o.posizioniCollegate.contains($0.id) && $0.stato == .inEssere }
        var campioni = Array(stride(from: 0, through: mesiMassimi, by: 12))
        if !campioni.contains(scadenza) { campioni.append(scadenza) }
        if campioni.last != mesiMassimi { campioni.append(mesiMassimi) }
        campioni.sort()
        mesi = campioni
        base = campioni.map { m in
            let dallePosizioni = collegate.reduce(0.0) {
                $0 + MotoreObiettivo.contributoPosizione($1, obiettivo: o, scarto: 0, mesiProiezione: m, data: data).nettoScadenza
            }
            return dallePosizioni + o.accantonato * pow(1 + o.rendimento / 100, Double(m) / 12)
        }
        unita = campioni.map { MotoreObiettivo.nettoDiUnEuroAlMese(rendimento: o.rendimento, mesi: $0) }
    }

    // MARK: Valori a un mese

    /// L'obiettivo rivalutato all'inflazione dopo `m` mesi.
    func traguardo(_ m: Int) -> Double {
        importo * pow(1 + inflazione / 100, Double(m) / 12)
    }

    /// Ciò che c'è dopo `m` mesi con `versamento` € al mese in più.
    func valore(_ m: Int, versamento: Double) -> Double {
        let (b, u) = interpolati(m)
        return b + max(versamento, 0) * u
    }

    /// La copertura alla scadenza (0…1) con `versamento` € al mese: segue il cursore.
    func copertura(versamento: Double) -> Double {
        let t = traguardo(mesiScadenza)
        guard t > 0 else { return 1 }
        return min(1, max(0, valore(mesiScadenza, versamento: versamento) / t))
    }

    /// Quanto manca alla scadenza con `versamento` € al mese (0 se ci arriva).
    func mancante(versamento: Double) -> Double {
        max(0, traguardo(mesiScadenza) - valore(mesiScadenza, versamento: versamento))
    }

    /// Il primo mese in cui si arriva all'obiettivo (rivalutato) con `versamento` € al mese; 0 se c'è già,
    /// nil se non ci si arriva entro `mesiMassimi`.
    func mesiArrivo(versamento: Double) -> Int? {
        guard importo > 0 else { return 0 }
        for m in 0...mesiMassimi where valore(m, versamento: versamento) >= traguardo(m) {
            return m
        }
        return nil
    }

    /// La data di arrivo (nil se non ci si arriva).
    func arrivo(versamento: Double) -> Date? {
        mesiArrivo(versamento: versamento).flatMap { Calendar.current.date(byAdding: .month, value: $0, to: inizio) }
    }

    /// Il versamento mensile che porta la copertura a 1 alla scadenza (0 se basta ciò che c'è; nil se la scadenza
    /// è passata e non basta).
    var versamentoNecessario: Double? {
        let manca = mancante(versamento: 0)
        guard manca > 0 else { return 0 }
        let u = interpolati(mesiScadenza).1
        guard u > 0 else { return nil }
        return manca / u
    }

    // MARK: Interpolazione

    /// Base e unità al mese `m`: esatte sui campioni, lineari fra due campioni.
    private func interpolati(_ m: Int) -> (Double, Double) {
        guard let primo = mesi.first, let ultimo = mesi.last else { return (0, 0) }
        if m <= primo { return (base[0], unita[0]) }
        if m >= ultimo { return (base[base.count - 1], unita[unita.count - 1]) }
        // Ricerca binaria del campione subito dopo m
        var basso = 0, alto = mesi.count - 1
        while alto - basso > 1 {
            let medio = (basso + alto) / 2
            if mesi[medio] <= m { basso = medio } else { alto = medio }
        }
        let m0 = mesi[basso], m1 = mesi[alto]
        guard m1 > m0 else { return (base[basso], unita[basso]) }
        let f = Double(m - m0) / Double(m1 - m0)
        return (base[basso] + (base[alto] - base[basso]) * f,
                unita[basso] + (unita[alto] - unita[basso]) * f)
    }
}

extension CacheMotoriAnalisi {
    /// Le strade degli obiettivi già calcolate (schede e dettaglio della scheda Obiettivi), per chiave
    /// dell'obiettivo senza il versamento previsto, delle sue posizioni e del giorno.
    nonisolated(unsafe) private static var memoriaCurve: [Int: CurvaObiettivo] = [:]
    private static let massimoCurve = 24

    /// La strada mese per mese dell'obiettivo (`CurvaObiettivo`), ricordata: si rifà solo se cambiano l'obiettivo
    /// (non il versamento previsto, che è il cursore), le posizioni collegate o il giorno.
    static func curva(_ o: Obiettivo, posizioni: [Posizione], data: Date = Date()) -> CurvaObiettivo {
        let collegate = posizioni.filter { o.posizioniCollegate.contains($0.id) }
        var senzaVersamento = o
        senzaVersamento.versamentoMensile = 0
        var h = Hasher()
        h.combine(senzaVersamento)
        h.combine(collegate)
        h.combine(Calendar.current.startOfDay(for: data))
        let chiave = h.finalize()
        if let c = memoriaCurve[chiave] { return c }
        let c = CurvaObiettivo(o, posizioni: collegate, data: Calendar.current.startOfDay(for: data))
        if memoriaCurve.count >= massimoCurve { memoriaCurve.removeAll() }
        memoriaCurve[chiave] = c
        return c
    }
}
