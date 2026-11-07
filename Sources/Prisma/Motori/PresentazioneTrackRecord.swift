import CoreGraphics
import Foundation

// MARK: - Studio › Track record: ciò che la scheda mostra (giro 2, Design/template-novita-specifica.md §4.1.5 e §4.5.3)
// Funzioni pure, senza SwiftUI, sopra `MotoreTrackRecord` (che non cambia): l'ordine dell'elenco, l'esito da mostrare
// (con «Rimandata» letto dalla proposta collegata) e le due linee del confronto nel tempo, normalizzate su una scala
// comune. Le linee sono SEMPRE una stima: la proposta sono i valori rilevati della posizione (`MotoreAndamento`),
// l'alternativa il percorso degli stessi valori al ritmo del riferimento dell'alternativa (`MotoreRiferimenti.confronto`,
// la linea «atteso»). La cifra in euro resta quella del motore (versamenti al riferimento), non si ricava dalle linee.

enum PresentazioneTrackRecord {
    /// L'esito come lo mostra la pillola: la scelta registrata; «in attesa» diventa «rimandata» se la proposta
    /// collegata è segnata come rimandata (con la data in cui riprenderla, se c'è).
    enum Esito: Equatable {
        case accettata, rifiutata, inAttesa
        case rimandata(riprendereIl: Date?)

        var nome: String {
            switch self {
            case .accettata: return "Accettata"
            case .rifiutata: return "Rifiutata"
            case .inAttesa: return "In attesa"
            case .rimandata: return "Rimandata"
            }
        }
    }

    static func esito(_ v: TrackRecord.Voce) -> Esito {
        switch v.raccomandazione.scelta {
        case .accettata: return .accettata
        case .rifiutata: return .rifiutata
        case .inAttesa:
            guard let p = v.posizione, p.esito == .rimandata else { return .inAttesa }
            return .rimandata(riprendereIl: p.seguito?.riprendereIl)
        }
    }

    /// La differenza in euro rispetto all'alternativa, se misurata.
    static func differenza(_ v: TrackRecord.Voce) -> Double? {
        if case .scarto(let s) = v.misura { return s.differenza }
        return nil
    }

    /// Una copertura (area protezione): non ha un rendimento da confrontare, si mostra il capitale assicurato.
    static func capitaleAssicurato(_ v: TrackRecord.Voce) -> Double? {
        guard v.raccomandazione.scelta == .accettata, (v.raccomandazione.area ?? v.posizione?.area) == .protezione,
              let c = v.posizione?.capitaleAssicurato ?? v.raccomandazione.cifre.indicatori["capitaleAssicurato"],
              c.isFinite, c > 0 else { return nil }
        return c
    }

    /// L'ordine dell'elenco (§4.1.5): prima le accettate con un risultato, dalla differenza più alta; poi le accettate
    /// da misurare, le in attesa (e rimandate) e le rifiutate; dentro ogni gruppo dalla più recente.
    static func ordinate(_ voci: [TrackRecord.Voce]) -> [TrackRecord.Voce] {
        func gruppo(_ v: TrackRecord.Voce) -> Int {
            switch v.raccomandazione.scelta {
            case .accettata: return differenza(v) != nil ? 0 : 1
            case .inAttesa: return 2
            case .rifiutata: return 3
            }
        }
        return voci.sorted { a, b in
            let ga = gruppo(a), gb = gruppo(b)
            if ga != gb { return ga < gb }
            if let da = differenza(a), let db = differenza(b), da != db { return da > db }
            if a.raccomandazione.data != b.raccomandazione.data { return a.raccomandazione.data > b.raccomandazione.data }
            return a.id < b.id
        }
    }

    // MARK: - Il confronto nel tempo

    /// Le due linee di una raccomandazione accettata, normalizzate 0…1 (x nel tempo, y dal basso) su una scala comune.
    struct Linee: Equatable {
        let proposta: [CGPoint]
        /// Vuota se l'alternativa non si può ricostruire (nessun riferimento o valori mancanti).
        let alternativa: [CGPoint]
        let dal: Date
        let al: Date
    }

    /// Margine della scala comune: dal minimo × 0,995 al massimo × 1,005, come il template.
    static let margineScala = 0.005

    /// Le linee di una voce: servono un'accettata, la sua posizione e almeno due valori rilevati; senza, nil.
    static func linee(_ v: TrackRecord.Voce, tabella: TabellaRiferimenti) -> Linee? {
        guard v.raccomandazione.scelta == .accettata, let p = v.posizione,
              let a = MotoreAndamento.calcola(p), a.punti.count >= 2 else { return nil }
        let valori = a.punti.map { $0.valore }
        let date = a.punti.map { $0.data }
        var attesi: [Double] = []
        if let id = v.raccomandazione.alternativa.serieRiferimento, let serie = tabella.serie(id) {
            let c = MotoreRiferimenti.confronto(p, andamento: a, flussi: nil, serie: serie, rispettata: true, tabella: tabella)
            let x = c.punti.compactMap { $0.atteso }
            // Una linea a metà non si disegna: o tutti i punti o niente
            if x.count == c.punti.count, x.count == valori.count { attesi = x }
        }
        let n = normalizza(valori, attesi, date: date)
        return Linee(proposta: n.a, alternativa: n.b, dal: a.dal, al: a.al)
    }

    /// Due serie sulla stessa scala: y da (minimo × 0,995) a (massimo × 1,005); x in proporzione alle date (equidistanti
    /// senza date). Una serie costante sta a metà altezza, senza divisioni per zero.
    static func normalizza(_ a: [Double], _ b: [Double], date: [Date], margine: Double = margineScala)
        -> (a: [CGPoint], b: [CGPoint]) {
        let tutti = (a + b).filter { $0.isFinite }
        guard let minimo = tutti.min(), let massimo = tutti.max() else { return ([], []) }
        let basso = minimo - abs(minimo) * margine
        let alto = massimo + abs(massimo) * margine
        let ampiezza = alto - basso
        let inizio = date.first?.timeIntervalSinceReferenceDate ?? 0
        let durata = (date.last?.timeIntervalSinceReferenceDate ?? 0) - inizio
        func x(_ i: Int, di n: Int) -> CGFloat {
            if durata > 0, date.count == n {
                return CGFloat(min(max((date[i].timeIntervalSinceReferenceDate - inizio) / durata, 0), 1))
            }
            return n > 1 ? CGFloat(i) / CGFloat(n - 1) : 0
        }
        func y(_ v: Double) -> CGFloat {
            guard ampiezza > 0, v.isFinite else { return 0.5 }
            return CGFloat(min(max((v - basso) / ampiezza, 0), 1))
        }
        let pa = a.indices.map { CGPoint(x: x($0, di: a.count), y: y(a[$0])) }
        let pb = b.indices.map { CGPoint(x: x($0, di: b.count), y: y(b[$0])) }
        return (pa, pb)
    }
}
