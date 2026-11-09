import Foundation
import simd

// Sala › La realtà aumentata (Design/template-luce-specifica.md §2.3, «Luce» giro 16): il patrimonio diventa un
// cristallo di vetro, uno strato per classe d'investimento, che cresce negli anni fino alla pensione.
// Puro, senza SwiftUI né RealityKit: lo usano il palco del Mac (`PalcoRealtaAumentata`), l'iPhone e l'iPad
// (`RealtaAumentataMobile`), il cristallo in RealityKit (`CristalloRealta`), il fermo-immagine (`CristalloFermo`),
// il tavolo (`RealtaTavolo`) e `ProvaCalcoliRealta`.
// - Gli strati sono i pezzi della composizione di Analisi 360 (`MotoreAree360.composizione`) con valore > 0,
//   nell'ordine delle classi dal basso: Azionario, Obbligazionario, Gestione separata, Liquidità.
// - Gli anni vengono dalla linea della vita (`MotoreLineaVita`), partendo dallo stesso totale di oggi, fino all'età di
//   pensione (non oltre); la ripartizione resta quella di oggi, come nel prisma di luce.
// - La maglia di uno strato è un prisma triangolare equilatero con gli angoli arrotondati, costruito qui (posizioni,
//   normali, triangoli) e trasformato in `MeshResource` solo da `CristalloRealta`.

/// Uno strato del cristallo: una classe d'investimento con la sua quota di oggi.
struct StratoRealta: Equatable, Identifiable {
    let classe: ComposizioneInvestimenti360.Classe
    let nome: String
    /// 0…1, gli strati sommano a 1.
    let quota: Double
    /// Euro di oggi.
    let valoreOggi: Double
    var id: String { classe.rawValue }
}

/// Il patrimonio di un anno del cursore.
struct AnnoRealta: Equatable {
    let anno: Int
    let eta: Int
    let totale: Double
}

/// Tutte le cifre del cristallo di un cliente.
struct EsitoRealta: Equatable {
    let totaleOggi: Double
    /// Solo le classi > 0, nell'ordine di `Classe.allCases` (dal basso).
    let strati: [StratoRealta]
    /// Da oggi all'età di pensione; vuoto senza data di nascita.
    let anni: [AnnoRealta]
    /// Almeno una composizione è stimata dalla tipologia o dall'SRI.
    let stimata: Bool
    /// Perché il cursore degli anni non c'è (nil se c'è).
    let motivoSenzaAnni: String?
    /// Il patrimonio più alto fra oggi e gli anni del cursore (per l'altezza del cristallo).
    let massimo: Double

    var vuota: Bool { totaleOggi <= 0 || strati.isEmpty }
    var annoOggi: Int? { anni.first?.anno }
    var annoFine: Int? { anni.last?.anno }

    /// Il patrimonio dell'anno (oggi se l'anno non è sul cursore).
    func totale(anno: Int?) -> Double {
        guard let anno, let a = anni.first(where: { $0.anno == anno }) else { return totaleOggi }
        return a.totale
    }

    /// Gli euro di uno strato nell'anno: il totale dell'anno con la ripartizione di oggi.
    func valore(_ s: StratoRealta, anno: Int?) -> Double { totale(anno: anno) * s.quota }

    /// n + 1 bordi cumulati da 0 a 1 (dal basso).
    var bordi: [Double] {
        var b: [Double] = [0]
        var somma = 0.0
        for s in strati {
            somma += s.quota
            b.append(min(1, somma))
        }
        if !strati.isEmpty { b[b.count - 1] = 1 }
        return b
    }

    /// L'altezza del cristallo in unità: 0,85 + 1,35 × totale/massimo.
    func altezza(anno: Int?) -> Double {
        let f = massimo > 0 ? min(1, max(0, totale(anno: anno) / massimo)) : 1
        return MotoreRealtaAumentata.altezzaBase + MotoreRealtaAumentata.altezzaVariabile * f
    }
}

/// La maglia di uno strato: posizioni, normali e triangoli per `MeshDescriptor` (costruita senza RealityKit).
struct MagliaPrisma: Equatable {
    var posizioni: [SIMD3<Float>]
    var normali: [SIMD3<Float>]
    var indici: [UInt32]
}

enum MotoreRealtaAumentata {
    static let altezzaBase = 0.85
    static let altezzaVariabile = 1.35
    /// Il raggio del triangolo (dal centro ai vertici), in unità.
    static let raggio: Float = 0.42
    /// Il raggio degli angoli arrotondati in pianta.
    static let arrotondamento: Float = 0.05
    /// Lo spazio fra uno strato e l'altro.
    static let fessura: Float = 0.008
    /// Quanto sale ogni strato con «Esploso» (× indice).
    static let salitaEsploso: Float = 0.2
    /// Gli spicchi di ogni angolo arrotondato.
    static let segmentiAngolo = 6

    /// Tutte le cifre del cristallo per un cliente. `obiettivi` ed `eventi` come nella linea della vita, `analisi` quella
    /// salvata (nil se il cliente non l'ha).
    static func calcola(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventi: [EventoLineaVita],
                        analisi: Analisi360?, oggi: Date = Date()) -> EsitoRealta {
        let proprie = posizioni.filter { $0.clienteId == cliente.id }
        let comp = MotoreAree360.composizione(proprie, cliente: cliente)
        let totale = comp.totale
        let strati = Self.strati(comp)
        let prep = MotoreLineaVita.prepara(cliente: cliente, posizioni: proprie, obiettivi: obiettivi, eventi: eventi,
                                           analisi: analisi, oggi: oggi)
        let anni = totale > 0
            ? Self.anni(prep.ingresso, totaleOggi: totale, annoOggi: Calendar.current.component(.year, from: oggi))
            : []
        let primo = TestiRealta.primoNome(cliente.nome)
        let motivo: String? = anni.isEmpty ? TestiRealta.senzaAnni(primo) : nil
        let massimo = max(totale, anni.map(\.totale).max() ?? 0)
        return EsitoRealta(totaleOggi: totale, strati: strati, anni: anni, stimata: comp.stimata,
                           motivoSenzaAnni: motivo, massimo: massimo)
    }

    /// Le classi con valore > 0, nell'ordine delle classi, con quote che sommano a 1.
    /// (`Pezzo.quota` è in % 0-100: la quota si ricalcola dai valori, così la somma è esatta.)
    static func strati(_ c: ComposizioneInvestimenti360) -> [StratoRealta] {
        let validi = c.pezzi.filter { $0.valore > 0 && $0.valore.isFinite }
        let somma = validi.reduce(0) { $0 + $1.valore }
        guard somma > 0 else { return [] }
        return validi.map { StratoRealta(classe: $0.classe, nome: $0.classe.nome, quota: $0.valore / somma, valoreOggi: $0.valore) }
    }

    /// Il patrimonio da oggi all'età di pensione (non oltre), come `MotoreLuce.proiezione`, partendo da `totaleOggi`.
    /// Valori sotto zero mostrati a 0.
    static func anni(_ ingresso: IngressoLineaVita?, totaleOggi: Double, annoOggi: Int) -> [AnnoRealta] {
        guard var i = ingresso else { return [] }
        i.patrimonioIniziale = totaleOggi
        let esito = MotoreLineaVita.calcola(i)
        let ultimaEta = max(i.etaOggi, min(i.etaPensione, esito.etaFine))
        return esito.punti.filter { $0.eta <= ultimaEta }.map {
            AnnoRealta(anno: annoOggi + ($0.eta - i.etaOggi), eta: $0.eta, totale: max(0, $0.valore))
        }
    }

    // MARK: - La geometria

    /// Basso e alto dello strato `i` (unità), con la fessura, l'esploso (0…1) e la crescita (0…1) intorno alla base.
    static func estremi(strato i: Int, bordi: [Double], altezza: Double, esploso: Double, crescita: Double) -> (basso: Float, alto: Float) {
        guard i >= 0, i + 1 < bordi.count else { return (0, 0.001) }
        let n = bordi.count - 1
        let h = Float(max(0, altezza) * max(0, crescita))
        var basso = Float(bordi[i]) * h
        var alto = Float(bordi[i + 1]) * h
        if i > 0 { basso += fessura / 2 }
        if i < n - 1 { alto -= fessura / 2 }
        let salita = salitaEsploso * Float(i) * Float(min(1, max(0, esploso)))
        basso += salita
        alto += salita
        if alto < basso + 0.001 { alto = basso + 0.001 }
        return (basso, alto)
    }

    /// La direzione orizzontale di un angolo (0 = verso −z, il vertice in alto della pianta).
    private static func direzione(_ a: Float) -> SIMD2<Float> { SIMD2(sin(a), -cos(a)) }

    /// La pianta del triangolo arrotondato: `3 × (segmenti + 1)` punti (x, z) in ordine, con la normale orizzontale di
    /// ciascuno (uguale alla direzione dell'arco: sui lati dritti le due estremità hanno la stessa normale).
    static func piantaConNormali(raggio: Float = raggio, arrotondamento: Float = arrotondamento,
                                 segmenti: Int = segmentiAngolo) -> [(punto: SIMD2<Float>, normale: SIMD2<Float>)] {
        let s = max(1, segmenti)
        let r = min(max(0.0001, arrotondamento), raggio / 3)
        // Il centro dell'arco sta sulla retta centro-vertice a `R − 2r` (angolo di 60°: r / sin 30° = 2r)
        let distanza = raggio - 2 * r
        var punti: [(SIMD2<Float>, SIMD2<Float>)] = []
        for k in 0..<3 {
            let phi = Float(k) * 2 * Float.pi / 3
            let centro = direzione(phi) * distanza
            for j in 0...s {
                let a = phi - Float.pi / 3 + Float(j) * (2 * Float.pi / 3) / Float(s)
                let n = direzione(a)
                punti.append((centro + n * r, n))
            }
        }
        return punti.map { (punto: $0.0, normale: $0.1) }
    }

    /// La pianta del triangolo arrotondato (per l'ombra dipinta e per `CristalloFermo`): punti (x, z) in ordine.
    static func pianta(raggio: Float = raggio, arrotondamento: Float = arrotondamento, segmenti: Int = segmentiAngolo) -> [SIMD2<Float>] {
        piantaConNormali(raggio: raggio, arrotondamento: arrotondamento, segmenti: segmenti).map(\.punto)
    }

    /// Il prisma triangolare con gli angoli arrotondati (vertice verso −z), estruso fra `basso` e `alto`: facce laterali
    /// con normali orizzontali, coperchi sopra e sotto. Ogni triangolo gira in senso antiorario visto da fuori (la sua
    /// normale geometrica va nel verso della normale dei vertici).
    static func maglia(basso: Float, alto: Float, raggio: Float = raggio, arrotondamento: Float = arrotondamento,
                       segmenti: Int = segmentiAngolo) -> MagliaPrisma {
        let anello = piantaConNormali(raggio: raggio, arrotondamento: arrotondamento, segmenti: segmenti)
        let y0 = min(basso, alto)
        let y1 = max(alto, basso + 0.001)
        var posizioni: [SIMD3<Float>] = []
        var normali: [SIMD3<Float>] = []
        var indici: [UInt32] = []

        func triangolo(_ a: Int, _ b: Int, _ c: Int, verso: SIMD3<Float>) {
            let pa = posizioni[a], pb = posizioni[b], pc = posizioni[c]
            let n = simd_cross(pb - pa, pc - pa)
            if simd_dot(n, verso) >= 0 {
                indici.append(contentsOf: [UInt32(a), UInt32(b), UInt32(c)])
            } else {
                indici.append(contentsOf: [UInt32(a), UInt32(c), UInt32(b)])
            }
        }

        // Le facce laterali: due vertici (sotto e sopra) per punto della pianta
        let m = anello.count
        for p in anello {
            let n = SIMD3<Float>(p.normale.x, 0, p.normale.y)
            posizioni.append(SIMD3(p.punto.x, y0, p.punto.y)); normali.append(n)
            posizioni.append(SIMD3(p.punto.x, y1, p.punto.y)); normali.append(n)
        }
        for i in 0..<m {
            let j = (i + 1) % m
            // Due punti consecutivi nella stessa posizione (non succede con r > 0) darebbero triangoli vuoti
            if simd_distance(anello[i].punto, anello[j].punto) < 1e-6 { continue }
            let a = 2 * i, b = 2 * i + 1, c = 2 * j, d = 2 * j + 1
            let meta = simd_normalize(SIMD3<Float>(anello[i].normale.x + anello[j].normale.x, 0,
                                                   anello[i].normale.y + anello[j].normale.y))
            triangolo(a, c, d, verso: meta)
            triangolo(a, d, b, verso: meta)
        }

        // I coperchi: un ventaglio dal centro, con i vertici propri (normale verticale)
        for (y, verso) in [(y1, SIMD3<Float>(0, 1, 0)), (y0, SIMD3<Float>(0, -1, 0))] {
            let centro = posizioni.count
            posizioni.append(SIMD3(0, y, 0)); normali.append(verso)
            let primo = posizioni.count
            for p in anello {
                posizioni.append(SIMD3(p.punto.x, y, p.punto.y)); normali.append(verso)
            }
            for i in 0..<m {
                let j = (i + 1) % m
                if simd_distance(anello[i].punto, anello[j].punto) < 1e-6 { continue }
                triangolo(centro, primo + i, primo + j, verso: verso)
            }
        }
        return MagliaPrisma(posizioni: posizioni, normali: normali, indici: indici)
    }

    // MARK: - Il movimento

    /// La crescita con il rimbalzo del template: 1 − e^(−6t)·cos(9t) (t in secondi; 0 prima, 1 oltre 1,5 s).
    static func crescita(_ t: Double) -> Double {
        guard t > 0 else { return 0 }
        guard t < 1.5 else { return 1 }
        return 1 - exp(-6 * t) * cos(9 * t)
    }

    /// Inseguimento esponenziale: a + (b − a)·(1 − e^(−k·dt)).
    static func insegui(_ a: Double, verso b: Double, velocita k: Double, dt: Double) -> Double {
        guard dt > 0, k > 0 else { return a }
        return a + (b - a) * (1 - exp(-k * dt))
    }
}

/// Le frasi della realtà aumentata, in un posto solo: Mac, iPad e iPhone le condividono, e `ProvaCalcoliRealta`
/// controlla che nessuna porti cifre inventate. I nomi arrivano sempre da fuori.
enum TestiRealta {
    static let etichettaColonna = "SUL TAVOLO, DAVANTI A"
    static let titolo = "Il patrimonio diventa un cristallo che si può guardare da ogni lato."
    static let testo = "Ogni strato di vetro è un tipo di investimento. Fai scorrere gli anni e il cristallo cresce; «Esploso» separa gli strati e mostra quanto vale ciascuno. La luce che li attraversa colora il tavolo."
    static let notaAnteprima = "Anteprima simulata. Sull'iPad e sull'iPhone veri il cristallo si posa sul tavolo con la fotocamera, e si guarda girandoci intorno."
    static let marchio = "◉ Prisma · AR"
    static let cercoSuperficie = "Cerco una superficie…"
    static let tavoloTrovato = "✓ Tavolo trovato"
    static let guida = "Muovi l'iPad per trovare il tavolo"
    static let guidaTelefono = "Muovi l'iPhone per trovare il tavolo"
    static let serveLuce = "Serve più luce"
    static let piuLentamente = "Muovi l'iPad più lentamente"
    static let esploso = "Esploso"
    static let fine = "Fine"
    static let apri = "Apri in realtà aumentata"
    static let stimata = "Composizione in parte stimata"
    static let fotocameraAssente = "La fotocamera non è disponibile: il cristallo resta sul tavolo virtuale"
    static let consentiImpostazioni = "Consenti in Impostazioni"
    static let fotocameraNegata = "Prisma non ha il permesso della fotocamera: il cristallo resta sul tavolo virtuale"
    static let scattoSoloAlTavolo = "Lo scatto arriva nel dossier solo al tavolo con il Mac"
    static let scattoConStanzaTitolo = "Lo scatto può comprendere la stanza"
    static let scattoConStanzaAiuto = "Di base lo scatto è solo il cristallo su fondo neutro. Acceso, sull'iPad del tavolo si può scattare anche la foto con la stanza, con una conferma a ogni scatto. Mai nel Rullino: la foto va solo nel dossier del cliente sul Mac."
    static let stanzaNonPermessa = "Lo scatto con la stanza non è permesso (Impostazioni › Sala)"
    static let scattoGuasto = "Lo scatto è arrivato guasto: rifallo."
    static let notaFoglio = "Rappresentazione del patrimonio di oggi (o stimato per l'anno): non è una previsione."
    static let rigaStanza = "La foto comprende la stanza in cui è stata scattata."
    static let attesaTavolo = "Apri il tavolo e collega l'iPad per mostrarlo"
    static let rispondeSulliPad = "Il cliente risponde sull'iPad"
    static let lanciaSulliPad = "Il cliente lancia l'anno sull'iPad"
    static let disegnaSulliPad = "Il cliente disegna sull'iPad"
    static let scriviPrimaLettera = "Scrivi prima la lettera sul palco"
    static let dopoPensioneDisegno = "Dopo la pensione il disegno è solo un'indicazione: il confronto guarda l'età di pensione."
    static let aiutoCapsula = "Scrivi con calma: puoi anche dettare con il microfono della tastiera. Il messaggio si sigilla sul Mac e nessuno lo legge prima del giorno giusto."
    static let confermaSigillo = "Dopo il sigillo il messaggio non si può rileggere né correggere fino al giorno giusto."
    static let sigilla = "✉︎ Sigilla la capsula"

    /// Il nome di battesimo («Giulia» da «Giulia Rossi»).
    static func primoNome(_ nome: String) -> String {
        nome.split(separator: " ").first.map(String.init) ?? nome
    }

    static func colonna(_ primo: String) -> String { "\(etichettaColonna) \(primo.uppercased())" }
    static func senzaAnni(_ primo: String) -> String { "Per far crescere il cristallo negli anni serve la data di nascita di \(primo)." }
    static func senzaPosizioni(_ primo: String) -> String {
        "\(primo) non ha ancora posizioni in essere: il cristallo nasce dal suo patrimonio"
    }
    static func patrimonioNel(_ anno: Int) -> String { "Patrimonio nel \(anno)" }
    static func targhetta(_ primo: String, anno: Int) -> String { "\(primo) · \(anno)" }
    static func fotoSalvata(_ cliente: String) -> String { "Foto salvata nel dossier di \(cliente)" }
    static func confermaStanza(_ primo: String) -> String { "La foto comprende la stanza: la mando nel dossier di \(primo)?" }
    static func confermaCifre(_ primo: String) -> String { "Sull'iPad compaiono le cifre di \(primo). Vanno bene per chi è al tavolo?" }
    static func titoloFoglio(_ cliente: String, anno: Int) -> String { "Il cristallo di \(cliente) · \(anno)" }
    static func titoloDocumento(anno: Int, ora: String) -> String { "Il cristallo · \(anno) · \(ora)" }
    static func capsulaArrivata(_ primo: String) -> String { "Il messaggio di \(primo) è arrivato dall'iPad ed è sigillato" }

    /// Tutte le frasi fisse (per la prova delle cifre inventate).
    static var tutte: [String] {
        [etichettaColonna, titolo, testo, notaAnteprima, marchio, cercoSuperficie, tavoloTrovato, guida, guidaTelefono,
         serveLuce, piuLentamente, esploso, fine, apri, stimata, fotocameraAssente, consentiImpostazioni, fotocameraNegata,
         scattoSoloAlTavolo, scattoConStanzaTitolo, scattoConStanzaAiuto, stanzaNonPermessa, scattoGuasto, notaFoglio,
         rigaStanza, attesaTavolo, rispondeSulliPad, lanciaSulliPad, disegnaSulliPad, scriviPrimaLettera,
         dopoPensioneDisegno, aiutoCapsula, confermaSigillo, sigilla]
    }
}
