import Foundation
import CoreGraphics

// Sala › Disegna il tuo futuro (Design/template-luce-specifica.md §3.3.5, «Luce» giro 4): il cliente disegna come
// vorrebbe che crescesse il patrimonio fino a 90 anni; Prisma lo confronta con il piano di oggi (la linea della vita,
// `MotoreLineaVita`, in euro di oggi) e dice quanto servirebbe in più al mese. Puro, senza SwiftUI.
// - Il disegno vale da oggi a 90 anni: prima del primo punto vale il primo, dopo l'ultimo l'ultimo (`disegnata` del
//   template); si accettano solo punti che vanno verso destra (uno più a sinistra di 2 punti si scarta).
// - Il confronto è alla pensione (decisione 113); se dopo la pensione il disegno sta sopra il piano lo si dice, senza
//   cifre in più.
// - Il versamento in più: `calcola` è affine nel risparmio annuo (x = x·(1+r) + risparmio fino alla pensione), quindi
//   Δ al mese = (disegno − piano alla pensione) / (valore alla pensione di 1 € l'anno) / 12. Si mostra arrotondato a
//   10 €; il rendimento è quello reale della linea della vita, non il 2,5% fisso del template.
// - A differenza della proposta della specifica il tratto si tiene in età ed euro (non in punti della tela): così l'asse
//   può allargarsi di un gradino quando il tratto tocca il bordo alto senza spostare ciò che è già disegnato.

/// Il tratto del cliente: punti (x = età, anche frazionaria; y = euro di oggi).
struct TrattoDisegno: Equatable {
    var punti: [CGPoint] = []
}

/// Gli assi della tela: età da oggi a 90 anni, euro da 0 al massimo, e il rettangolo del grafico nella tela.
struct AssiDisegno: Equatable {
    let etaOggi: Int
    let etaFine: Int
    let massimo: Double
    let area: CGRect

    var anni: Double { Double(max(1, etaFine - etaOggi)) }

    func x(_ eta: Double) -> CGFloat { area.minX + CGFloat((eta - Double(etaOggi)) / anni) * area.width }
    func y(_ valore: Double) -> CGFloat { area.maxY - CGFloat(valore / max(1, massimo)) * area.height }
    func eta(_ x: CGFloat) -> Double { Double(etaOggi) + Double((x - area.minX) / max(1, area.width)) * anni }
    func valore(_ y: CGFloat) -> Double { Double((area.maxY - y) / max(1, area.height)) * massimo }

    /// Un punto della tela in età ed euro (l'euro non scende sotto zero).
    func dato(_ p: CGPoint) -> CGPoint { CGPoint(x: eta(p.x), y: max(0, valore(p.y))) }
    /// Un punto in età ed euro nella tela.
    func punto(_ d: CGPoint) -> CGPoint { CGPoint(x: x(Double(d.x)), y: y(Double(d.y))) }
}

struct EsitoDisegno: Equatable {
    /// Un valore per età, da `etaOggi` a `etaFine`.
    let disegno: [Double]
    /// La curva del piano di oggi (`EsitoLineaVita.punti`, sotto zero mostrata a 0), stesse età.
    let possibile: [Double]
    let etaOggi: Int
    let etaPensione: Int
    let alDisegno: Double
    let alPiano: Double
    /// Il versamento mensile in più, arrotondato a 10 €; nil se il disegno è alla portata (o la pensione è già qui).
    let versamentoInPiu: Double?
    /// Lo stesso, non arrotondato (per la prova: con questo il piano arriva al disegno).
    let versamentoEsatto: Double
    /// Dopo la pensione il disegno sta sopra la curva del piano.
    let sopraDopoPensione: Bool
    /// Il rendimento reale della stima (%).
    let rendimentoReale: Double
    /// Dopo la pensione la curva del piano è solo indicativa (manca il reddito desiderato o la pensione pubblica).
    let dopoPensioneIndicativa: Bool
}

enum MotoreDisegno {
    /// L'asse y arriva a 2,1 volte il massimo della curva possibile (o del patrimonio di oggi).
    static let scalaMassimo = 2.1
    /// Quando il tratto tocca il bordo alto l'asse cresce di un gradino (×1,5), al più tre volte.
    static let gradino = 1.5
    static let gradiniMassimi = 3
    /// Un tratto con meno di 4 punti torna «vuota».
    static let puntiMinimi = 4
    /// Un punto più a sinistra di 2 punti (della tela) rispetto all'ultimo si scarta.
    static let scartoIndietro: CGFloat = 2
    /// Il versamento si mostra arrotondato a 10 €.
    static let arrotondamento = 10.0
    /// Sopra il piano dopo la pensione: almeno l'1% (sotto è un tremolio della mano).
    static let tolleranzaSopra = 0.01

    /// Gli assi per la curva del piano e il rettangolo del grafico.
    static func assi(_ esito: EsitoLineaVita, area: CGRect, gradini: Int = 0) -> AssiDisegno {
        let alto = max(esito.punti.map { max(0, $0.valore) }.max() ?? 0, 1000)
        let k = pow(gradino, Double(min(max(0, gradini), gradiniMassimi)))
        return AssiDisegno(etaOggi: esito.punti.first?.eta ?? 0, etaFine: esito.etaFine, massimo: alto * scalaMassimo * k, area: area)
    }

    /// Aggiunge un punto della tela al tratto (in età ed euro) se va verso destra. true se l'ha preso.
    @discardableResult
    static func aggiungi(_ p: CGPoint, a t: inout TrattoDisegno, assi: AssiDisegno) -> Bool {
        if let ultimo = t.punti.last, p.x < assi.x(Double(ultimo.x)) - scartoIndietro { return false }
        let x = min(max(p.x, assi.area.minX), assi.area.maxX)
        t.punti.append(assi.dato(CGPoint(x: x, y: p.y)))
        return true
    }

    /// Il tratto tocca il bordo alto della tela: l'asse va allargato.
    static func toccaIlBordo(_ t: TrattoDisegno, assi: AssiDisegno) -> Bool {
        guard let ultimo = t.punti.last else { return false }
        return Double(ultimo.y) >= assi.massimo * 0.98
    }

    /// Un valore per età, da `etaOggi` a `etaFine`, interpolando il tratto (prima del primo punto il primo, dopo
    /// l'ultimo l'ultimo). Vuoto senza punti.
    static func valori(_ t: TrattoDisegno, assi: AssiDisegno) -> [Double] {
        guard let primo = t.punti.first, let ultimo = t.punti.last else { return [] }
        return (assi.etaOggi...max(assi.etaOggi, assi.etaFine)).map { e in
            let a = Double(e)
            if Double(primo.x) >= a { return Double(primo.y) }
            for i in 1..<t.punti.count where Double(t.punti[i].x) >= a {
                let p0 = t.punti[i - 1], p1 = t.punti[i]
                let dx = Double(p1.x - p0.x)
                let k = dx > 0 ? (a - Double(p0.x)) / dx : 1
                return Double(p0.y) + Double(p1.y - p0.y) * k
            }
            return Double(ultimo.y)
        }
    }

    /// Il valore alla pensione di 1 € l'anno versato da oggi (con il rendimento reale): il calcolo è affine nel
    /// risparmio, la differenza fra due calcoli lo dà esatto.
    static func fattoreVersamento(_ i: IngressoLineaVita) -> Double {
        var piu = i
        piu.risparmioAnnuo += 1
        return MotoreLineaVita.calcola(piu).allaPensione - MotoreLineaVita.calcola(i).allaPensione
    }

    /// Il confronto fra il tratto e il piano di oggi. nil se il tratto ha meno di `puntiMinimi` punti.
    static func esito(_ t: TrattoDisegno, ingresso: IngressoLineaVita, assi: AssiDisegno) -> EsitoDisegno? {
        guard t.punti.count >= puntiMinimi else { return nil }
        let piano = MotoreLineaVita.calcola(ingresso)
        let disegno = valori(t, assi: assi)
        let possibile = piano.punti.map { max(0, $0.valore) }
        let pensione = min(max(ingresso.etaPensione, assi.etaOggi), assi.etaFine)
        let k = pensione - assi.etaOggi
        let alDisegno = k < disegno.count ? disegno[k] : (disegno.last ?? 0)
        let alPiano = k < possibile.count ? possibile[k] : (possibile.last ?? 0)
        let fattore = fattoreVersamento(ingresso)
        let annuo = fattore > 0 ? (alDisegno - piano.allaPensione) / fattore : 0
        let esatto = max(0, annuo / 12)
        let arrotondato = (esatto / arrotondamento).rounded() * arrotondamento
        let inPiu: Double? = esatto > 0.5 ? max(arrotondamento, arrotondato) : nil
        var sopra = false
        if k + 1 < min(disegno.count, possibile.count) {
            for j in (k + 1)..<min(disegno.count, possibile.count)
            where disegno[j] > possibile[j] * (1 + tolleranzaSopra) && disegno[j] - possibile[j] > 1 {
                sopra = true
                break
            }
        }
        return EsitoDisegno(disegno: disegno, possibile: possibile, etaOggi: assi.etaOggi, etaPensione: pensione,
                            alDisegno: alDisegno, alPiano: alPiano, versamentoInPiu: inPiu, versamentoEsatto: esatto,
                            sopraDopoPensione: sopra, rendimentoReale: ingresso.rendimentoReale,
                            dopoPensioneIndicativa: piano.dopoPensioneIndicativa)
    }

    /// Le etichette dell'asse in italiano: «0 €», «350 mila», «1,4 milioni» (non «k»).
    static func etichettaAsse(_ v: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        if v <= 0.5 { return "0 €" }
        if v >= 999_500 { return "\(f.string(from: NSNumber(value: v / 1_000_000)) ?? "") milioni".replacingOccurrences(of: "^1 milioni", with: "1 milione", options: .regularExpression) }
        if v >= 1000 { return "\(Int((v / 1000).rounded())) mila" }
        return Formati.euro(v)
    }

    /// Il giorno in cui il cliente compie l'età di pensione (scadenza dell'obiettivo salvato).
    static func dataPensione(nascita: Date?, eta: Int) -> Date? {
        guard let nascita else { return nil }
        return Calendar.current.date(byAdding: .year, value: eta, to: nascita)
    }
}
