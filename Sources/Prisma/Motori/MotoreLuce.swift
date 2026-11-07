import Foundation

// Sala › Il prisma di luce (Design/template-luce-specifica.md §2.2.5, «Luce» giro 4): le fasce del ventaglio per vista e
// il patrimonio negli anni. Puro, senza SwiftUI: lo usano il palco (`PalcoLuce`) e `ProvaCalcoliLuce`.
// - Il totale è il patrimonio finanziario in essere (`ComposizioneInvestimenti360.totale`, decisione 82): i raggi sono
//   le classi d'investimento, e «IL PATRIMONIO FINANZIARIO DI …» lo dice.
// - Per investimento: i pezzi della composizione con valore > 0, nell'ordine delle classi.
// - Per obiettivo: quanto è già destinato a ogni obiettivo (`EsitoObiettivo.disponibileOggi`), al più 5 raggi (se sono
//   di più, i 4 più grandi e «Altri obiettivi»: il ventaglio ne regge 6), più «Liquidità e altro» = totale − obiettivi.
//   Niente minimo del 20% del template. Se gli obiettivi superano il totale (posizioni contate su più obiettivi) le
//   quote si riportano al totale degli obiettivi e il palco lo dice.
// - Per canale: `perCanale` della composizione, mai una quota fissa.
// - Negli anni: il patrimonio della linea della vita (`MotoreLineaVita`), partendo dallo stesso totale di oggi; la
//   ripartizione resta quella di oggi e il palco lo dice (decisione 82, proiezione per posizione in seconda fase).

/// Le tre viste del ventaglio.
enum VistaLuce: String, CaseIterable, Identifiable, Hashable {
    case investimento, obiettivo, canale

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .investimento: return "Per investimento"
        case .obiettivo: return "Per obiettivo"
        case .canale: return "Per canale"
        }
    }
}

/// Di che colore è una fascia: la vista lo traduce nei colori di `Tema.Apple.Luce.Raggi`.
enum TintaLuce: Hashable {
    case classe(ComposizioneInvestimenti360.Classe)
    /// Un obiettivo: la sua area e il suo posto fra gli obiettivi mostrati.
    case obiettivo(AreaBisogno, indice: Int)
    /// «Altri obiettivi» e «Liquidità e altro».
    case altro
    case canale(Canale)
}

/// Un raggio del ventaglio.
struct FasciaLuce: Equatable, Identifiable {
    let id: String
    let nome: String
    /// Euro di oggi.
    let valore: Double
    /// Quota 0…1 delle fasce della vista (sommano a 1).
    let quota: Double
    let tinta: TintaLuce
    /// Il canale (vista «Per canale»): l'etichetta lo scrive anche a parole.
    let canale: Canale?
}

/// Il patrimonio di un anno del cursore.
struct AnnoLuce: Equatable {
    let anno: Int
    let eta: Int
    let totale: Double
}

struct EsitoLuce: Equatable {
    let totaleOggi: Double
    let investimento: [FasciaLuce]
    let obiettivo: [FasciaLuce]
    let canale: [FasciaLuce]
    /// Almeno una composizione è stimata dalla tipologia o dall'SRI.
    let stimata: Bool
    /// Gli obiettivi insieme superano il patrimonio: quote sul totale degli obiettivi.
    let obiettiviOltreTotale: Bool
    /// Da oggi a vent'anni (o ai 90 anni del cliente); vuoto senza data di nascita.
    let anni: [AnnoLuce]
    /// Perché il cursore degli anni non c'è (nil se c'è).
    let motivoSenzaAnni: String?
    /// Il patrimonio più alto degli anni del cursore (per la lunghezza del ventaglio).
    let massimo: Double

    var vuota: Bool { totaleOggi <= 0 }
    var annoOggi: Int? { anni.first?.anno }
    var annoFine: Int? { anni.last?.anno }

    func fasce(_ v: VistaLuce) -> [FasciaLuce] {
        switch v {
        case .investimento: return investimento
        case .obiettivo: return obiettivo
        case .canale: return canale
        }
    }

    /// Il patrimonio dell'anno (oggi se l'anno non è sul cursore).
    func totale(anno: Int?) -> Double {
        guard let anno, let a = anni.first(where: { $0.anno == anno }) else { return totaleOggi }
        return a.totale
    }

    /// Gli euro di una fascia nell'anno: il totale dell'anno con la ripartizione di oggi.
    func valore(_ f: FasciaLuce, anno: Int?) -> Double { totale(anno: anno) * f.quota }

    /// 0…1: il patrimonio dell'anno rispetto al massimo (la lunghezza del ventaglio ne prende la radice).
    func frazione(anno: Int?) -> Double {
        massimo > 0 ? min(1, max(0, totale(anno: anno) / massimo)) : 1
    }
}

enum MotoreLuce {
    /// Il limite dello shader.
    static let fasceMassime = 6
    static let obiettiviMassimi = 5
    /// Il cursore va da oggi a vent'anni.
    static let anniCursore = 20

    /// Tutte le cifre del palco per un cliente. `obiettivi` nell'ordine del dossier, `analisi` quella salvata.
    static func calcola(cliente: Cliente, posizioni: [Posizione], obiettivi: [Obiettivo], eventi: [EventoLineaVita],
                        analisi: Analisi360?, oggi: Date = Date()) -> EsitoLuce {
        let proprie = posizioni.filter { $0.clienteId == cliente.id }
        let comp = MotoreAree360.composizione(proprie, cliente: cliente)
        let totale = comp.totale
        let (perObiettivo, oltre) = fasceObiettivo(obiettivi.filter { $0.clienteId == cliente.id }, posizioni: proprie,
                                                   totale: totale, oggi: oggi)
        let prep = MotoreLineaVita.prepara(cliente: cliente, posizioni: proprie, obiettivi: obiettivi, eventi: eventi,
                                           analisi: analisi, oggi: oggi)
        let anni = proiezione(prep.ingresso, totaleOggi: totale, annoOggi: Calendar.current.component(.year, from: oggi))
        let primo = cliente.nome.split(separator: " ").first.map(String.init) ?? cliente.nome
        let motivo: String? = anni.isEmpty ? "Per vedere il patrimonio negli anni serve la data di nascita di \(primo)." : nil
        let massimo = max(totale, anni.map(\.totale).max() ?? 0)
        return EsitoLuce(totaleOggi: totale, investimento: fasceInvestimento(comp), obiettivo: perObiettivo,
                         canale: fasceCanale(comp), stimata: comp.stimata, obiettiviOltreTotale: oltre, anni: anni,
                         motivoSenzaAnni: motivo, massimo: massimo)
    }

    // MARK: - Le fasce

    /// I pezzi della composizione con valore > 0, nell'ordine delle classi.
    static func fasceInvestimento(_ c: ComposizioneInvestimenti360) -> [FasciaLuce] {
        normalizza(c.pezzi.filter { $0.valore > 0 }.map {
            (id: "classe-\($0.classe.rawValue)", nome: $0.classe.nome, valore: $0.valore, tinta: TintaLuce.classe($0.classe), canale: nil)
        })
    }

    /// Alleanza e indipendente con valore > 0, sempre distinti.
    static func fasceCanale(_ c: ComposizioneInvestimenti360) -> [FasciaLuce] {
        normalizza(Canale.allCases.compactMap { k in
            guard let v = c.perCanale[k], v > 0 else { return nil }
            return (id: "canale-\(k.rawValue)", nome: k.nomeBreve, valore: v, tinta: TintaLuce.canale(k), canale: k)
        })
    }

    /// Quanto è già destinato a ogni obiettivo, più «Liquidità e altro». Restituisce anche se gli obiettivi superano il
    /// totale. Vuoto senza obiettivi con qualcosa da parte.
    static func fasceObiettivo(_ obiettivi: [Obiettivo], posizioni: [Posizione], totale: Double,
                               oggi: Date = Date()) -> ([FasciaLuce], Bool) {
        var voci = obiettivi.compactMap { o -> (Obiettivo, Double)? in
            let v = MotoreObiettivo.calcola(o, posizioni: posizioni, data: oggi).disponibileOggi
            return v > 0 && v.isFinite ? (o, v) : nil
        }
        guard !voci.isEmpty, totale > 0 else { return ([], false) }
        var altri = 0.0
        if voci.count > obiettiviMassimi {
            // I più grandi restano (nell'ordine del dossier), i più piccoli vanno in «Altri obiettivi»
            let tenuti = Set(voci.sorted { $0.1 > $1.1 }.prefix(obiettiviMassimi - 1).map(\.0.id))
            altri = voci.filter { !tenuti.contains($0.0.id) }.reduce(0) { $0 + $1.1 }
            voci = voci.filter { tenuti.contains($0.0.id) }
        }
        var righe = voci.enumerated().map { i, v in
            (id: "obiettivo-\(v.0.id)", nome: v.0.titolo, valore: v.1, tinta: TintaLuce.obiettivo(v.0.area, indice: i), canale: Canale?.none)
        }
        if altri > 0 {
            righe.append((id: "obiettivi-altri", nome: "Altri obiettivi", valore: altri, tinta: .altro, canale: nil))
        }
        let somma = righe.reduce(0) { $0 + $1.valore }
        let oltre = somma > totale + 0.5
        if !oltre, totale - somma > 0.5 {
            righe.append((id: "liquidita-altro", nome: "Liquidità e altro", valore: totale - somma, tinta: .altro, canale: nil))
        }
        return (normalizza(righe), oltre)
    }

    /// Quote che sommano a 1, al più `fasceMassime` fasce, nessuna a zero.
    static func normalizza(_ righe: [(id: String, nome: String, valore: Double, tinta: TintaLuce, canale: Canale?)]) -> [FasciaLuce] {
        let valide = Array(righe.filter { $0.valore > 0 && $0.valore.isFinite }.prefix(fasceMassime))
        let somma = valide.reduce(0) { $0 + $1.valore }
        guard somma > 0 else { return [] }
        return valide.map { FasciaLuce(id: $0.id, nome: $0.nome, valore: $0.valore, quota: $0.valore / somma, tinta: $0.tinta, canale: $0.canale) }
    }

    // MARK: - Gli anni

    /// Il patrimonio da oggi a vent'anni (fermandosi ai `etaFine` anni) con la linea della vita, partendo da
    /// `totaleOggi` (lo stesso numero del ventaglio di oggi). Valori sotto zero mostrati a 0.
    static func proiezione(_ ingresso: IngressoLineaVita?, totaleOggi: Double, annoOggi: Int) -> [AnnoLuce] {
        guard var i = ingresso else { return [] }
        i.patrimonioIniziale = totaleOggi
        let esito = MotoreLineaVita.calcola(i)
        let ultimaEta = min(i.etaOggi + anniCursore, esito.etaFine)
        return esito.punti.filter { $0.eta <= ultimaEta }.map {
            AnnoLuce(anno: annoOggi + ($0.eta - i.etaOggi), eta: $0.eta, totale: max(0, $0.valore))
        }
    }
}
