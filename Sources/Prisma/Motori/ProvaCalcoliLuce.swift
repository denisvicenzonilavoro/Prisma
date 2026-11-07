import Foundation
import CoreGraphics

/// Prove del prisma di luce (Design/template-luce-specifica.md §2.2.5, «Luce» giro 4): in ogni vista le quote sommano
/// a 1, nessun raggio a zero, al più sei; i canali restano distinti e vengono da `perCanale` (mai il 47% del template);
/// «per obiettivo» senza il minimo del 20%, con «Altri obiettivi» oltre i cinque e le quote sul totale degli obiettivi
/// quando lo superano; il patrimonio negli anni è quello di `MotoreLineaVita` partendo dallo stesso totale di oggi;
/// senza data di nascita niente anni; la geometria trova la fascia sotto il puntatore e tiene le etichette a 44; lo
/// shader si compila (se c'è Metal). Chiamata da `ProvaCalcoli.esegui()`.
enum ProvaCalcoliLuce {
    static func esegui(_ verifica: VerificaCalcoli) {
        demo(verifica)
        fasce(verifica)
        obiettivi(verifica)
        anni(verifica)
        geometria(verifica)
        verifica.vero("Luce: lo shader del prisma si compila", ProgrammaLuce.provaCompilazione())
        verifica("Luce: uniformi dello shader (56 float)", Double(ShaderLuce.Strato().impacchettate.count), 56)
    }

    private static func controllaVista(_ verifica: VerificaCalcoli, _ f: [FasciaLuce], _ nome: String) {
        guard !f.isEmpty else { return }
        verifica("Luce: \(nome), quote che sommano a 1", f.reduce(0) { $0 + $1.quota }, 1, tolleranza: 1e-9)
        verifica.vero("Luce: \(nome), nessun raggio a zero", f.allSatisfy { $0.quota > 0 && $0.valore > 0 })
        verifica.vero("Luce: \(nome), al più sei raggi", f.count <= MotoreLuce.fasceMassime)
        verifica.vero("Luce: \(nome), raggi senza doppioni", Set(f.map(\.id)).count == f.count)
    }

    /// I clienti del template: ogni vista in regola, oggi uguale alla composizione di Analisi 360.
    private static func demo(_ verifica: VerificaCalcoli) {
        let d = DatiPrisma.demo()
        for c in d.clienti {
            let e = MotoreLuce.calcola(cliente: c, posizioni: d.posizioni, obiettivi: d.obiettivi, eventi: d.eventiVita,
                                       analisi: d.analisi[c.id], oggi: AiutiProva.oggi)
            for v in VistaLuce.allCases { controllaVista(verifica, e.fasce(v), "\(c.id) \(v.rawValue)") }
            let comp = MotoreAree360.composizione(d.posizioni.filter { $0.clienteId == c.id }, cliente: c)
            verifica("Luce: \(c.id), totale = composizione di Analisi 360", e.totaleOggi, comp.totale)
            if let primo = e.anni.first {
                verifica("Luce: \(c.id), il primo anno è il totale di oggi", primo.totale, e.totaleOggi)
            }
        }
    }

    private static func fasce(_ verifica: VerificaCalcoli) {
        var c = Cliente.nuovo(tinta: .blu)
        c.nome = "Cliente di prova"
        let azioni = AiutiProva.posizione("Fondo azionario", .investimento, 60_000, canale: .indipendente) {
            $0.clienteId = c.id
            $0.quotaAzionaria = 100
            $0.quotaTitoliStato = 0
        }
        let conto = AiutiProva.posizione("Conto", .liquidita, 20_000, canale: .alleanza) { $0.clienteId = c.id }
        let comp = MotoreAree360.composizione([azioni, conto], cliente: c)
        let inv = MotoreLuce.fasceInvestimento(comp)
        controllaVista(verifica, inv, "prova per investimento")
        verifica.vero("Luce: classi a zero escluse", !inv.contains { $0.nome == "Obbligazionario" || $0.nome == "Gestione separata" })
        let can = MotoreLuce.fasceCanale(comp)
        controllaVista(verifica, can, "prova per canale")
        verifica("Luce: due canali, due raggi", Double(can.count), 2)
        verifica.vero("Luce: canali distinti e dichiarati", Set(can.compactMap(\.canale)) == [.alleanza, .indipendente])
        verifica("Luce: quota Alleanza dai dati (non il 47% del template)",
                 can.first { $0.canale == .alleanza }?.quota ?? 0, (comp.perCanale[.alleanza] ?? 0) / comp.totale, tolleranza: 1e-9)
        let solo = MotoreLuce.fasceCanale(MotoreAree360.composizione([azioni], cliente: c))
        verifica.vero("Luce: un canale solo, un raggio pieno", solo.count == 1 && abs(solo[0].quota - 1) < 1e-12)
        let vuota = MotoreLuce.calcola(cliente: c, posizioni: [], obiettivi: [], eventi: [], analisi: nil, oggi: AiutiProva.oggi)
        verifica.vero("Luce: senza posizioni il prisma è spento", vuota.vuota && VistaLuce.allCases.allSatisfy { vuota.fasce($0).isEmpty })
    }

    private static func obiettivi(_ verifica: VerificaCalcoli) {
        var c = Cliente.nuovo(tinta: .blu)
        c.nome = "Cliente di prova"
        func obiettivo(_ titolo: String, _ accantonato: Double) -> Obiettivo {
            var o = Obiettivo(clienteId: c.id, titolo: titolo, area: .casa, importo: 500_000,
                              scadenza: AiutiProva.data(2040, 1, 1))
            o.accantonato = accantonato
            return o
        }
        // Un obiettivo che copre il 95%: «Liquidità e altro» al 5% (nel template almeno il 20%)
        let (grande, oltre1) = MotoreLuce.fasceObiettivo([obiettivo("Casa", 95_000)], posizioni: [], totale: 100_000)
        controllaVista(verifica, grande, "per obiettivo")
        verifica("Luce: niente minimo del 20% per «Liquidità e altro»", grande.last?.quota ?? 0, 0.05, tolleranza: 1e-9)
        verifica.vero("Luce: obiettivi entro il totale", !oltre1)
        // Sette obiettivi: i quattro più grandi, «Altri obiettivi» e «Liquidità e altro»
        let sette = (1...7).map { obiettivo("Obiettivo \($0)", Double($0) * 1000) }
        let (molti, _) = MotoreLuce.fasceObiettivo(sette, posizioni: [], totale: 100_000)
        controllaVista(verifica, molti, "sette obiettivi")
        verifica("Luce: sette obiettivi in sei raggi", Double(molti.count), 6)
        verifica.vero("Luce: i più piccoli in «Altri obiettivi»", molti.contains { $0.nome == "Altri obiettivi" && abs($0.valore - 6000) < 0.01 })
        // Obiettivi oltre il totale: quote sul totale degli obiettivi, niente «Liquidità e altro»
        let (troppi, oltre2) = MotoreLuce.fasceObiettivo([obiettivo("Casa", 80_000), obiettivo("Auto", 60_000)], posizioni: [], totale: 100_000)
        controllaVista(verifica, troppi, "obiettivi oltre il totale")
        verifica.vero("Luce: obiettivi oltre il totale segnalati", oltre2 && !troppi.contains { $0.id == "liquidita-altro" })
        let (nessuno, _) = MotoreLuce.fasceObiettivo([obiettivo("Vuoto", 0)], posizioni: [], totale: 100_000)
        verifica.vero("Luce: obiettivi senza nulla da parte, nessun raggio", nessuno.isEmpty)
    }

    private static func anni(_ verifica: VerificaCalcoli) {
        let d = DatiPrisma.demo()
        guard let giulia = d.clienti.first(where: { $0.id == "giulia" }) else {
            verifica.vero("Luce: Giulia nei dati di prova", false)
            return
        }
        let e = MotoreLuce.calcola(cliente: giulia, posizioni: d.posizioni, obiettivi: d.obiettivi, eventi: d.eventiVita,
                                   analisi: d.analisi["giulia"], oggi: AiutiProva.oggi)
        let prep = MotoreLineaVita.prepara(cliente: giulia, posizioni: d.posizioni, obiettivi: d.obiettivi,
                                           eventi: d.eventiVita, analisi: d.analisi["giulia"], oggi: AiutiProva.oggi)
        if var i = prep.ingresso {
            i.patrimonioIniziale = e.totaleOggi
            let punti = MotoreLineaVita.calcola(i).punti
            let uguali = e.anni.allSatisfy { a in
                guard let p = punti.first(where: { $0.eta == a.eta }) else { return false }
                return abs(max(0, p.valore) - a.totale) < 0.01
            }
            verifica.vero("Luce: patrimonio negli anni uguale alla linea della vita", uguali && !e.anni.isEmpty)
            verifica("Luce: cursore di vent'anni", Double(e.anni.count), Double(MotoreLuce.anniCursore + 1))
            verifica.vero("Luce: il massimo è il più alto degli anni", e.massimo >= (e.anni.map(\.totale).max() ?? 0))
        } else {
            verifica.vero("Luce: linea della vita di Giulia", false)
        }
        // Le quote di oggi valgono anche negli anni (ripartizione di oggi, dichiarata)
        if let f = e.investimento.first, let fine = e.annoFine {
            verifica("Luce: fascia negli anni = totale dell'anno × quota", e.valore(f, anno: fine), e.totale(anno: fine) * f.quota)
        }
        var senza = giulia
        senza.dataNascita = nil
        let s = MotoreLuce.calcola(cliente: senza, posizioni: d.posizioni, obiettivi: d.obiettivi, eventi: d.eventiVita,
                                   analisi: d.analisi["giulia"], oggi: AiutiProva.oggi)
        verifica.vero("Luce: senza data di nascita niente anni, e il motivo", s.anni.isEmpty && s.motivoSenzaAnni != nil)
        // Oltre i 90 anni il cursore si ferma
        var ingresso = IngressoLineaVita(etaOggi: 80, etaPensione: 67, patrimonioIniziale: 100_000, risparmioAnnuo: 0,
                                         rendimentoReale: 1, redditoDesiderato: nil)
        ingresso.etaFine = 90
        verifica("Luce: il cursore si ferma a 90 anni", Double(MotoreLuce.proiezione(ingresso, totaleOggi: 100_000, annoOggi: 2026).count), 11)
    }

    private static func geometria(_ verifica: VerificaCalcoli) {
        let geo = GeometriaLuce(misura: CGSize(width: 1384, height: 600))
        verifica("Luce: raggio del cristallo", Double(geo.raggio), 150)
        let bordi = GeometriaLuce.bordi([0.38, 0.34, 0.2, 0.08])
        verifica("Luce: bordi da 0 a 1", bordi.last ?? 0, 1, tolleranza: 1e-12)
        let l = geo.lunghezza(rot: 0, frazione: 1)
        let x = geo.uscita(0)
        // Al centro angolare della prima fascia, a 200 punti da X
        let a = geo.direzione(0) - 0.25 + 0.19 * 0.5
        let p = CGPoint(x: x.x + CGFloat(cos(a)) * 200, y: x.y + CGFloat(sin(a)) * 200)
        verifica("Luce: il puntatore trova la prima fascia", Double(geo.fascia(p, rot: 0, bordi: bordi, lunghezza: l) ?? -1), 0)
        let vicino = CGPoint(x: x.x + 30, y: x.y)
        verifica.vero("Luce: troppo vicino al cristallo nessuna fascia", geo.fascia(vicino, rot: 0, bordi: bordi, lunghezza: l) == nil)
        let etichette = geo.etichette(rot: 0, bordi: GeometriaLuce.bordi([0.3, 0.3, 0.2, 0.1, 0.05, 0.05]), lunghezza: l)
        let distanze = zip(etichette.dropFirst(), etichette).map { $0.y - $1.y }
        verifica.vero("Luce: etichette ad almeno 44 punti", distanze.allSatisfy { $0 >= Tema.Apple.Luce.Etichetta.distanzaMinima - 0.5 })
    }
}
