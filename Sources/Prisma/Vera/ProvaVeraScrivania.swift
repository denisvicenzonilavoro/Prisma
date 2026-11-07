import Foundation

// Prova della Vera della scrivania (dentro `Prisma --prova-vera`): le due pagine, il gesto che decide con soglia
// e velocità, il ritorno ai widget (dock, blocco) e il quadro visivo calcolato da Prisma.
extension ProvaVera {
    static func provaVeraScrivania() -> [(Bool, String)] {
        var esiti: [(Bool, String)] = []
        func controlla(_ ok: Bool, _ d: String) { esiti.append((ok, d)) }

        let s = StatoShell(persistente: false)
        controlla(s.sistema.paginaVera == 0 && s.scrivaniaPerVera, "Vera della scrivania: si parte dai widget, scrivania libera")
        s.mostraVeraScrivania()
        controlla(s.sistema.paginaVera == 1 && s.veraScrivaniaAperta, "Vera della scrivania: si apre")
        s.mostraScrivania()
        controlla(s.sistema.paginaVera == 0, "Vera della scrivania: «Scrivania» nel dock torna ai widget")

        // Il gesto: oltre metà corsa cambia pagina, prima torna indietro, con un colpo veloce cambia comunque
        let g = s.sistema.gestoVera
        func gesto(da partenza: CGFloat, dito: CGFloat, velocita: CGFloat) -> CGFloat {
            s.sistema.paginaVera = partenza
            g.partenza = partenza
            g.attivo = true
            g.segui(dito: dito, larghezza: 1000)
            s.concludiGestoVera(velocita: velocita)
            return s.sistema.paginaVera
        }
        controlla(gesto(da: 0, dito: -600, velocita: 0) == 1, "Gesto: oltre metà corsa verso sinistra si apre Vera")
        controlla(gesto(da: 0, dito: -300, velocita: 0) == 0, "Gesto: a un terzo della corsa si torna ai widget")
        controlla(gesto(da: 0, dito: -150, velocita: 2) == 1, "Gesto: un colpo veloce verso sinistra apre Vera")
        controlla(gesto(da: 1, dito: 200, velocita: -2) == 0, "Gesto: un colpo veloce verso destra torna ai widget")
        controlla(gesto(da: 1, dito: 100, velocita: 0) == 1, "Gesto: un piccolo spostamento lascia Vera aperta")
        controlla(g.spostamento == 0 && !g.attivo, "Gesto: a gesto finito lo spostamento si azzera")
        g.partenza = 0
        g.segui(dito: -5000, larghezza: 1000)
        controlla(g.spostamento > 1 && g.spostamento < 1.1, "Gesto: oltre Vera il movimento rallenta (elastico)")
        g.spostamento = 0

        // Il blocco (anche quello del Mac a riposo) riporta ai widget
        s.mostraVeraScrivania()
        s.blocca(animato: false)
        controlla(s.bloccato && s.sistema.paginaVera == 0, "Blocco: sotto la schermata si torna ai widget")
        controlla(!s.scrivaniaPerVera, "Blocco: con la schermata di benvenuto il gesto non apre Vera")
        s.sblocca()
        s.apri(.posizioni)
        controlla(!s.scrivaniaPerVera, "Con una finestra davanti il gesto non apre Vera")

        // Il quadro visivo: cifre di Prisma, mai del modello
        let posizioni = s.posizioniCliente("giulia")
        let inEssere = posizioni.filter { $0.stato == .inEssere && !$0.area.passivo && $0.valore > 0 }
        if let q = QuadroVera.perCliente(domanda: "Come è diviso il patrimonio di Giulia?", posizioni: posizioni, obiettivi: []),
           case .barre(let barre) = q.forma {
            let atteso = inEssere.reduce(0) { $0 + $1.valore }
            controlla(abs(q.totale - atteso) < 0.01, "Quadro: il patrimonio per area somma le posizioni in essere")
            controlla(barre.map(\.importo) == barre.map(\.importo).sorted(by: >), "Quadro: le aree dalla più grande")
        } else {
            controlla(false, "Quadro: il patrimonio di Giulia ha le barre per area")
        }
        if let q = QuadroVera.perPortafoglio(domanda: "Come si divide il portafoglio tra Alleanza e indipendente?", posizioni: s.posizioni),
           case .barre(let barre) = q.forma {
            controlla(barre.allSatisfy { if case .canale(_) = $0.tinta { return true } else { return false } },
                      "Quadro: il portafoglio per canale ha i colori dei canali")
        } else {
            controlla(false, "Quadro: il portafoglio per canale ha le barre")
        }
        controlla(QuadroVera.perCliente(domanda: "Raccontami una barzelletta", posizioni: posizioni, obiettivi: []) == nil,
                  "Quadro: niente quadro se la domanda non parla di cifre")
        var libera = MessaggioVera(autore: .vera, testo: "Ciao!")
        libera.modalita = .conversazione
        controlla(!QuadroVera.ammessa(libera), "Quadro: niente quadro in conversazione libera")
        controlla(!QuadroVera.ammessa(MessaggioVera(autore: .vera, testo: "", titolo: "Qwen non è pronto")),
                  "Quadro: niente quadro se Qwen non è pronto")
        return esiti
    }
}
