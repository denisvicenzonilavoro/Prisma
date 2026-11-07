#if os(macOS)
import Foundation
import CoreGraphics

/// Le istantanee di Posizioni › Prova del fuoco (Design/template-novita-specifica.md §6.7), 590-598 in chiaro e in
/// scuro, tutte nello stato finale (`\.modoIstantanea`: calcolo sincrono, lista già riordinata, numeri completi):
/// - 590: «Mercati −25%»; 591: cursore a −45%; 592: «Tassi +2 punti»; 593: «Inflazione al 5%»;
/// - 594: «Come nel 2008» (card senza cursore, con la frase storica); 595: «Come nel 2020», con il recupero;
/// - 596: i cinque clienti del template, tre senza obiettivi (in fondo, con «Aggiungi un obiettivo»);
/// - 597: archivio senza clienti (card spenta e vuoto guidato); 598: finestra stretta.
///
/// DATI DI PROVA DICHIARATI: i clienti sono quelli di prova (5 del template e 30 fittizi). Gli obiettivi «di prova» dei
/// clienti del template che non ne hanno (Laura, Andrea, Sofia) e i collegamenti fra obiettivi e posizioni in essere
/// esistono SOLO dentro queste scene (lo stato dell'istantanea non si salva): servono a far lavorare il motore, come
/// dice la specifica (§6.6, «Dati di prova»). Le cifre a schermo le calcola MotoreProvaFuoco.
/// Quali dati mettere in una scena della prova del fuoco.
enum DatiScenaProvaFuoco {
    /// I 5 clienti del template e i 30 fittizi, con gli obiettivi di prova collegati alle posizioni.
    case completi
    /// Solo i 5 clienti del template, con i loro obiettivi di sempre (collegati): tre restano senza.
    case template
    /// Nessun cliente.
    case vuoto
}

extension Istantanee {
    nonisolated static var sceneProvaFuoco: [(nome: String, prepara: (StatoShell) -> Void)] {
        var scene: [(nome: String, prepara: (StatoShell) -> Void)] = []
        func coppia(_ nome: String, _ prepara: @escaping (StatoShell) -> Void) {
            scene.append((nome: nome, prepara: prepara))
            scene.append((nome: nome + "-scuro", prepara: prepara))
        }
        coppia("590-posizioni-fuoco") { s in preparaProvaFuoco(s, .mercati) }
        coppia("591-posizioni-fuoco-mercati-45") { s in preparaProvaFuoco(s, .mercati, valore: 45) }
        coppia("592-posizioni-fuoco-tassi") { s in preparaProvaFuoco(s, .tassi) }
        coppia("593-posizioni-fuoco-inflazione") { s in preparaProvaFuoco(s, .inflazione) }
        coppia("594-posizioni-fuoco-2008") { s in preparaProvaFuoco(s, .crisi2008) }
        coppia("595-posizioni-fuoco-2020") { s in preparaProvaFuoco(s, .crisi2020) }
        coppia("596-posizioni-fuoco-senza-obiettivi") { s in preparaProvaFuoco(s, .mercati, dati: .template) }
        coppia("597-posizioni-fuoco-vuoto") { s in preparaProvaFuoco(s, .mercati, dati: .vuoto) }
        coppia("598-posizioni-fuoco-stretta") { s in
            preparaProvaFuoco(s, .mercati)
            s.alternaIngrandimento(.posizioni)
            s.ridimensiona(.posizioni, dimensione: CGSize(width: 760, height: 640))
        }
        return scene
    }

    /// Posizioni › Portafoglio › Prova del fuoco con lo scenario e il valore del cursore chiesti.
    nonisolated static func preparaProvaFuoco(_ s: StatoShell, _ scelta: SceltaScenarioFuoco, valore: Double? = nil,
                                              dati: DatiScenaProvaFuoco = .completi) {
        switch dati {
        case .completi:
            // Solo clienti, posizioni e obiettivi: le impostazioni della scena (aspetto scuro) restano
            let d = ClientiFittizi.completi()
            s.dati.clienti = d.clienti
            s.dati.posizioni = d.posizioni
            s.dati.obiettivi = d.obiettivi + obiettiviDiProvaFuoco(d)
            collegaObiettiviDiProva(s)
        case .template:
            collegaObiettiviDiProva(s)
        case .vuoto:
            s.dati.clienti = []
            s.dati.posizioni = []
            s.dati.obiettivi = []
        }
        if let valore { s.provaFuoco.imposta(valore, per: scelta) }
        s.apriProvaDelFuoco(scelta)
    }

    /// Un obiettivo per i clienti del template che non ne hanno (titoli del template).
    nonisolated static func obiettiviDiProvaFuoco(_ d: DatiPrisma) -> [Obiettivo] {
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        func anni(_ n: Int) -> Date { cal.date(byAdding: .year, value: n, to: oggi) ?? oggi }
        let conObiettivi = Set(d.obiettivi.map(\.clienteId))
        let proposte: [(cliente: String, titolo: String, area: AreaBisogno, importo: Double, anni: Int)] = [
            ("laura", "Pensione a 60 anni", .pensione, 260_000, 12),
            ("andrea", "Fondo per gli imprevisti", .salute, 40_000, 2),
            ("sofia", "Rendita integrativa", .pensione, 180_000, 7),
        ]
        return proposte.compactMap { p in
            guard !conObiettivi.contains(p.cliente), d.clienti.contains(where: { $0.id == p.cliente }) else { return nil }
            var o = Obiettivo(clienteId: p.cliente, titolo: p.titolo, area: p.area, importo: p.importo, scadenza: anni(p.anni))
            o.id = "obiettivo-prova-fuoco-\(p.cliente)"
            o.priorita = .alta
            o.creatoIl = oggi
            return o
        }
    }

    /// Gli obiettivi senza posizioni in essere collegate lavorano con le posizioni finanziarie in essere del cliente
    /// (investimento, risparmio, previdenza): così la prova muove le barre.
    nonisolated static func collegaObiettiviDiProva(_ s: StatoShell) {
        var perCliente: [String: [String]] = [:]
        for p in s.dati.posizioni where p.stato == .inEssere && p.area.proiettabile && p.valore > 0 {
            perCliente[p.clienteId, default: []].append(p.id)
        }
        let inEssere = Set(perCliente.values.flatMap { $0 })
        for i in s.dati.obiettivi.indices {
            let o = s.dati.obiettivi[i]
            guard !o.posizioniCollegate.contains(where: { inEssere.contains($0) }) else { continue }
            let suoi = perCliente[o.clienteId] ?? []
            guard !suoi.isEmpty else { continue }
            s.dati.obiettivi[i].posizioniCollegate = o.posizioniCollegate + suoi
        }
    }
}
#endif
