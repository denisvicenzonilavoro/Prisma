import CryptoKit
import Foundation
import SwiftUI

// Il film del piano («Luce» giro 15, Design/template-luce-specifica.md §3.2): dai motori di Prisma i dati del film, già
// scritti come vanno letti (titolo, mese, percentuali, cifre, etichette). Puro: niente stato, niente viste (SwiftUI solo
// per leggere i colori fissi degli obiettivi). Le regole:
// - obiettivi: come il Prisma del cliente (importo > 0, priorità e poi scadenza, al più tre), con la quota già da parte
//   (`MotoreObiettivo.calcola` → `disponibileOggi / importo`, decisione 81), fra 0 e 1;
// - versamento: il primo obiettivo con `versamentoMensile > 0` non ancora raggiunto;
// - pensione: `MotorePrevidenza.calcola(…).contributiProposte / 12` solo con l'area Previdenza confermata e proposte
//   previdenziali (D-F8): altrimenti la riga non c'è;
// - curva: `MotoreLineaVita` (euro di oggi) dall'età di oggi a quella di pensione;
// - arrivo: `SchedaLettera.arrivoConPiano` con l'obiettivo principale, nil se cade oltre la curva;
// - una scena senza dati si salta; con solo titolo e chiusura niente film (nil).

/// Un colore del film in sRGB (0…1), fisso: il film è sempre scuro.
struct ColoreFilm: Equatable, Sendable {
    var r: Double
    var g: Double
    var b: Double

    /// «#RRGGBB» (senza «#» va bene lo stesso); un testo non valido dà il bianco.
    static func hex(_ s: String) -> ColoreFilm {
        let pulito = s.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard pulito.count == 6, let v = UInt32(pulito, radix: 16) else { return ColoreFilm(r: 1, g: 1, b: 1) }
        return ColoreFilm(r: Double((v >> 16) & 0xFF) / 255, g: Double((v >> 8) & 0xFF) / 255, b: Double(v & 0xFF) / 255)
    }

    /// Un colore del tema risolto nell'aspetto scuro (il fondo del film è scuro).
    static func da(_ c: Color) -> ColoreFilm {
        var env = EnvironmentValues()
        env.colorScheme = .dark
        let r = c.resolve(in: env)
        func f(_ v: Float) -> Double { min(max(Double(v), 0), 1) }
        return ColoreFilm(r: f(r.red), g: f(r.green), b: f(r.blue))
    }

    /// «#RRGGBB» (per l'impronta).
    var esadecimale: String {
        func h(_ v: Double) -> String { String(format: "%02X", Int((min(max(v, 0), 1) * 255).rounded())) }
        return "#" + h(r) + h(g) + h(b)
    }
}

struct ObiettivoFilm: Equatable, Sendable {
    var nome: String
    /// Il già da parte sull'importo, fra 0 e 1.
    var quota: Double
    var colore: ColoreFilm
}

struct VersamentoFilm: Equatable, Sendable {
    var cifra: Double
    var obiettivo: String
}

/// Il punto della curva in cui si arriva all'obiettivo: `indice` = anni da oggi (punto della curva).
struct ArrivoFilm: Equatable, Sendable {
    var indice: Int
    /// «ottobre 2029 · Anticipo casa».
    var testo: String
}

/// Il punto finale della curva: l'età di pensione e il patrimonio, in euro di oggi.
struct FineFilm: Equatable, Sendable {
    var eta: Int
    var valore: Double
}

/// La firma della chiusura secondo il canale (decisione 57): il nome, il colore del canale sul fondo scuro; mai il logo.
struct FirmaFilm: Equatable, Sendable {
    var testo: String
    var colore: ColoreFilm?
}

enum ScenaFilm: Int, CaseIterable, Sendable {
    case titolo, oggi, ogniMese, futuro, chiusura
}

struct DatiFilm: Equatable, Sendable {
    /// «Il piano di Giulia».
    let titolo: String
    /// «novembre 2026» (il mese di oggi).
    let data: String
    let obiettivi: [ObiettivoFilm]
    let versamento: VersamentoFilm?
    /// I contributi previdenziali delle proposte al mese.
    let pensione: Double?
    /// Il patrimonio anno per anno da oggi all'età di pensione, in euro di oggi.
    let curva: [Double]
    let arrivo: ArrivoFilm?
    let fine: FineFilm?
    let firme: [FirmaFilm]
    let avvertenza: String
    /// Le scene da mostrare, in ordine (le vuote saltate).
    let scene: [ScenaFilm]
    /// La durata di ogni scena di `scene`.
    let durate: [Double]
    let diProva: Bool

    var durataTotale: Double { durate.reduce(0, +) }

    /// SHA256 dei campi senza `data`: cambia se cambia il piano, non se cambia il mese.
    var impronta: String {
        func c(_ v: Double) -> String { String(format: "%.2f", v) }
        var parti: [String] = [titolo]
        parti += obiettivi.map { "o|\($0.nome)|\(c($0.quota))|\($0.colore.esadecimale)" }
        if let v = versamento { parti.append("v|\(c(v.cifra))|\(v.obiettivo)") }
        if let p = pensione { parti.append("p|\(c(p))") }
        parti.append("c|" + curva.map(c).joined(separator: ","))
        if let a = arrivo { parti.append("a|\(a.indice)|\(a.testo)") }
        if let f = fine { parti.append("f|\(f.eta)|\(c(f.valore))") }
        parti += firme.map { "s|\($0.testo)|\($0.colore?.esadecimale ?? "")" }
        parti.append("w|\(avvertenza)")
        parti.append("e|" + scene.map { String($0.rawValue) }.joined(separator: ","))
        parti.append("d|\(diProva)")
        let digest = SHA256.hash(data: Data(parti.joined(separator: "\n").utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum MotoreFilm {
    static let durate: [ScenaFilm: Double] = Dictionary(uniqueKeysWithValues: ScenaFilm.allCases.map { s in
        (s, Tema.Apple.Moto.Film.durate[s.rawValue])
    })
    static let massimoObiettivi = 3
    /// Fotogrammi al secondo del video e dell'avanzamento della barra.
    static let fps = 30

    static func dati(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventi: [EventoLineaVita], analisi: Analisi360?,
                     scheda: SchedaLettera?, firme: [FirmaFilm], avvertenza: String, oggi: Date, diProva: Bool) -> DatiFilm? {
        let mie = posizioni.filter { $0.clienteId == cliente.id }
        let propri = obiettivi.filter { $0.clienteId == cliente.id }
        let ordinati = obiettiviOrdinati(propri)

        // Scena 1: le quote già da parte
        let elenco = ordinati.prefix(massimoObiettivi).map { o in
            ObiettivoFilm(nome: o.titolo, quota: quota(o, posizioni: mie, oggi: oggi),
                          colore: ColoreFilm.da(Tema.Apple.Clienti.Obiettivi.colore(o.area)))
        }

        // Scena 2: il versamento di ogni mese e la pensione delle proposte
        let versamento = ordinati.first { $0.versamentoMensile > 0 && $0.versamentoMensile.isFinite && $0.raggiuntoIl == nil }
            .map { VersamentoFilm(cifra: $0.versamentoMensile, obiettivo: $0.titolo) }
        let pensione = pensioneProposte(cliente: cliente, posizioni: mie, analisi: analisi, oggi: oggi)

        // Scena 3: la curva fino alla pensione, in euro di oggi
        let preparazione = MotoreLineaVita.prepara(cliente: cliente, posizioni: posizioni, obiettivi: obiettivi, eventi: eventi,
                                                   analisi: analisi, oggi: oggi)
        let (curva, fine) = curvaFinoAllaPensione(preparazione)
        let puntoArrivo = Self.arrivo(scheda: scheda, curva: curva, oggi: oggi)

        var scene: [ScenaFilm] = [.titolo]
        if !elenco.isEmpty { scene.append(.oggi) }
        if versamento != nil || pensione != nil { scene.append(.ogniMese) }
        if curva.count >= 2 { scene.append(.futuro) }
        scene.append(.chiusura)
        guard scene.count > 2 else { return nil }

        return DatiFilm(titolo: TestiFilm.titolo(ModelliMessaggi.primoNome(cliente.nome)),
                        data: Formati.meseAnno.string(from: oggi),
                        obiettivi: Array(elenco), versamento: versamento, pensione: pensione,
                        curva: curva, arrivo: curva.count >= 2 ? puntoArrivo : nil, fine: curva.count >= 2 ? fine : nil,
                        firme: firme, avvertenza: avvertenza, scene: scene,
                        durate: scene.map { durate[$0] ?? 0 }, diProva: diProva)
    }

    /// Gli obiettivi con un importo, per priorità e poi per scadenza.
    static func obiettiviOrdinati(_ obiettivi: [Obiettivo]) -> [Obiettivo] {
        obiettivi.filter { $0.importo > 0 && $0.importo.isFinite }
            .sorted { a, b in a.priorita != b.priorita ? a.priorita > b.priorita : a.scadenza < b.scadenza }
    }

    /// La quota già da parte (decisione 81): `disponibileOggi / importo`, fra 0 e 1.
    static func quota(_ o: Obiettivo, posizioni: [Posizione], oggi: Date) -> Double {
        guard o.importo > 0 else { return 0 }
        let q = MotoreObiettivo.calcola(o, posizioni: posizioni, data: oggi).disponibileOggi / o.importo
        guard q.isFinite else { return 0 }
        return min(1, max(0, q))
    }

    /// «+ X € per la pensione» (D-F8): i contributi delle proposte previdenziali al mese, solo con l'area Previdenza
    /// confermata con il cliente; nil se non ci sono proposte.
    static func pensioneProposte(cliente: Cliente, posizioni: [Posizione], analisi: Analisi360?, oggi: Date) -> Double? {
        guard let a = analisi, a.confermate.contains(.previdenza) else { return nil }
        let esito = MotorePrevidenza.calcola(posizioni.filter { $0.clienteId == cliente.id }, cliente: cliente,
                                             analisi: a.previdenza, data: oggi)
        let mese = esito.contributiProposte / 12
        guard mese.isFinite, mese > 0.5 else { return nil }
        return mese
    }

    /// I punti della linea della vita dall'età di oggi a quella di pensione (euro di oggi) e il punto finale.
    static func curvaFinoAllaPensione(_ p: PreparazioneLineaVita) -> ([Double], FineFilm?) {
        guard let i = p.ingresso, i.etaPensione > i.etaOggi else { return ([], nil) }
        let r = MotoreLineaVita.calcola(i)
        let punti = r.punti.filter { $0.eta <= i.etaPensione }
        let valori = punti.map(\.valore).filter(\.isFinite)
        guard valori.count == punti.count, valori.count >= 2, let ultimo = punti.last else { return ([], nil) }
        return (valori, FineFilm(eta: ultimo.eta, valore: ultimo.valore))
    }

    /// Il punto d'arrivo dell'obiettivo principale: anni da oggi, nil se oltre la curva o prima di oggi.
    static func arrivo(scheda: SchedaLettera?, curva: [Double], oggi: Date, cal: Calendar = .current) -> ArrivoFilm? {
        guard let s = scheda, let quando = s.arrivoConPiano, let obiettivo = s.obiettivo, curva.count >= 2 else { return nil }
        let anni = cal.component(.year, from: quando) - cal.component(.year, from: oggi)
        guard anni >= 0, anni <= curva.count - 1 else { return nil }
        return ArrivoFilm(indice: anni, testo: TestiFilm.arrivo(Formati.meseAnno.string(from: quando), obiettivo: obiettivo))
    }

    // MARK: Il tempo

    /// La scena (indice in `d.scene`) e il tempo dentro la scena all'istante `tempo` del film (limitato a 0…totale).
    static func scena(al tempo: Double, _ d: DatiFilm) -> (scena: Int, t: Double) {
        guard !d.durate.isEmpty else { return (0, 0) }
        var resto = min(max(tempo, 0), d.durataTotale)
        for (k, durata) in d.durate.enumerated() {
            if resto < durata || k == d.durate.count - 1 { return (k, min(resto, durata)) }
            resto -= durata
        }
        return (d.durate.count - 1, d.durate.last ?? 0)
    }

    /// L'istante in cui comincia la scena `indice` (indice in `d.scene`).
    static func inizio(scena indice: Int, _ d: DatiFilm) -> Double {
        d.durate.prefix(max(0, min(indice, d.durate.count))).reduce(0, +)
    }

    /// Il numero di fotogrammi del video (20,2 s × 30 = 606).
    static func fotogrammi(_ d: DatiFilm) -> Int {
        Int((d.durataTotale * Double(fps)).rounded())
    }
}

/// La geometria pura della scena del futuro (in punti del film), usata dal disegno e dalla prova.
enum GeometriaFilm {
    typealias F = Tema.Apple.SalaRacconti.Film

    /// I limiti verticali della curva: dal minimo (mai sopra lo zero) al massimo più il 12%.
    static func limiti(_ curva: [Double]) -> (minimo: Double, massimo: Double) {
        let minimo = min(0, curva.min() ?? 0)
        var massimo = (curva.max() ?? 1) * (1 + F.margineMassimo)
        if massimo <= minimo { massimo = minimo + 1 }
        return (minimo, massimo)
    }

    /// Il punto `indice` della curva nell'area.
    static func punto(_ indice: Int, di curva: [Double], area: CGRect = F.areaCurva) -> CGPoint {
        guard curva.count >= 2, curva.indices.contains(indice) else { return CGPoint(x: area.minX, y: area.maxY) }
        let (minimo, massimo) = limiti(curva)
        let x = area.minX + area.width * CGFloat(indice) / CGFloat(curva.count - 1)
        let y = area.maxY - area.height * CGFloat((curva[indice] - minimo) / (massimo - minimo))
        return CGPoint(x: x, y: y)
    }

    /// Il bordo sinistro di un'etichetta larga `larghezza` centrata su `x`, tenuta dentro l'area.
    static func sinistraEtichetta(centro x: CGFloat, larghezza: CGFloat, area: CGRect = F.areaCurva) -> CGFloat {
        let desiderato = x - larghezza / 2
        return min(max(desiderato, area.minX), max(area.minX, area.maxX - larghezza))
    }

    /// Il bordo sinistro dell'etichetta finale, allineata a destra 14 a sinistra del punto, mai fuori dall'area.
    static func sinistraEtichettaFine(punto x: CGFloat, larghezza: CGFloat, area: CGRect = F.areaCurva) -> CGFloat {
        max(area.minX, x - F.lontanoEtichettaFine - larghezza)
    }
}
