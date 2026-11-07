import Foundation

// «Messaggio» dalla riga della prova del fuoco (Design/template-novita-specifica.md §6.4, §5.2): Messaggi si apre con
// un'occasione su richiesta per quel cliente, sul tema dello scenario. Le cifre sono quelle del motore (scenario,
// obiettivo con la copertura oggi e dopo, patrimonio perso) e sono le sole che il messaggio può citare. Lo scenario è
// un'ipotesi: i modelli fissi dicono sempre che non è una previsione (ModelliMessaggi, `.provaFuoco`). Niente si
// spedisce da solo.

extension MotoreProvaFuoco {
    /// L'occasione di Messaggi per una riga della prova (una al giorno per cliente e scenario).
    static func occasioneMessaggio(_ r: RigaProvaFuoco, scenario: ScenarioFuoco, canale: Canale?, oggi: Date,
                                   calendario: Calendar = .current) -> OccasioneMessaggio {
        var cifre = [CifraMessaggio(.scenario, scenario.titolo)]
        if r.obiettivoId != nil, let titolo = r.titoloObiettivo {
            cifre.append(CifraMessaggio(.obiettivo, titolo))
            cifre.append(CifraMessaggio(.coperturaOggi, percento(r.coperturaOggi)))
            cifre.append(CifraMessaggio(.coperturaDopo, percento(r.coperturaDopo)))
        }
        if r.perdita >= 0.5 { cifre.append(CifraMessaggio(.perditaScenario, Formati.euro(r.perdita))) }
        let g = calendario.dateComponents([.year, .month, .day], from: oggi)
        let giorno = String(format: "%04d%02d%02d", g.year ?? 0, g.month ?? 0, g.day ?? 0)
        let perche: String
        if r.oltreSoglia, let titolo = r.titoloObiettivo {
            perche = "«\(titolo)» scenderebbe da \(percento(r.coperturaOggi)) a \(percento(r.coperturaDopo))"
        } else if r.perdita >= 0.5 {
            perche = "Nello scenario perderebbe \(Formati.euro(r.perdita))"
        } else {
            perche = "Uno scenario difficile per parlare dei suoi obiettivi"
        }
        return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .provaFuoco, riferimento: "\(chiave(scenario))-\(giorno)"),
                                  clienteId: r.clienteId, canale: canale, gruppo: .oggi,
                                  titolo: "Prova del fuoco: \(scenario.titolo)", perche: perche,
                                  oggetto: "Il portafoglio alla prova di uno scenario difficile",
                                  cifre: cifre, priorita: r.oltreSoglia ? .alta : .media, data: oggi)
    }

    /// «74%»: la copertura (0…1) in punti interi.
    static func percento(_ copertura: Double) -> String {
        Formati.percentuale((min(1, max(0, copertura)) * 100).rounded())
    }

    /// Una chiave stabile e leggibile dello scenario («mercati-25», «tassi-2.5», «inflazione-5-3», «crisi-2008»).
    static func chiave(_ s: ScenarioFuoco) -> String {
        func n(_ v: Double) -> String { v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v) }
        switch s {
        case let .mercati(calo): return "mercati-\(n(calo))"
        case let .tassi(punti): return "tassi-\(n(punti))"
        case let .inflazione(tasso, anni): return "inflazione-\(n(tasso))-\(anni)"
        case let .crisi(anno): return "crisi-\(anno)"
        }
    }
}
