import Foundation

// Prova della Ruby della scrivania (dentro `Prisma --prova-ruby`): le due pagine, il gesto che decide con soglia
// e velocità, il ritorno ai widget (dock, blocco) e il quadro visivo calcolato da Prisma.
extension ProvaRuby {
    static func provaRubyScrivania() -> [(Bool, String)] {
        var esiti: [(Bool, String)] = []
        func controlla(_ ok: Bool, _ d: String) { esiti.append((ok, d)) }

        let s = StatoShell(persistente: false)
        controlla(s.sistema.paginaRuby == 0 && s.scrivaniaPerRuby, "Ruby della scrivania: si parte dai widget, scrivania libera")
        s.mostraRubyScrivania()
        controlla(s.sistema.paginaRuby == 1 && s.rubyScrivaniaAperta, "Ruby della scrivania: si apre")
        s.mostraScrivania()
        controlla(s.sistema.paginaRuby == 0, "Ruby della scrivania: «Scrivania» nel dock torna ai widget")

        // Il gesto: oltre metà corsa cambia pagina, prima torna indietro, con un colpo veloce cambia comunque
        let g = s.sistema.gestoRuby
        func gesto(da partenza: CGFloat, dito: CGFloat, velocita: CGFloat) -> CGFloat {
            s.sistema.paginaRuby = partenza
            g.partenza = partenza
            g.attivo = true
            g.segui(dito: dito, larghezza: 1000)
            s.concludiGestoRuby(velocita: velocita)
            return s.sistema.paginaRuby
        }
        controlla(gesto(da: 0, dito: -600, velocita: 0) == 1, "Gesto: oltre metà corsa verso sinistra si apre Ruby")
        controlla(gesto(da: 0, dito: -300, velocita: 0) == 0, "Gesto: a un terzo della corsa si torna ai widget")
        controlla(gesto(da: 0, dito: -150, velocita: 2) == 1, "Gesto: un colpo veloce verso sinistra apre Ruby")
        controlla(gesto(da: 1, dito: 200, velocita: -2) == 0, "Gesto: un colpo veloce verso destra torna ai widget")
        controlla(gesto(da: 1, dito: 100, velocita: 0) == 1, "Gesto: un piccolo spostamento lascia Ruby aperta")
        controlla(g.spostamento == 0 && !g.attivo, "Gesto: a gesto finito lo spostamento si azzera")
        g.partenza = 0
        g.segui(dito: -5000, larghezza: 1000)
        controlla(g.spostamento > 1 && g.spostamento < 1.1, "Gesto: oltre Ruby il movimento rallenta (elastico)")
        g.spostamento = 0

        // Il blocco (anche quello del Mac a riposo) riporta ai widget
        s.mostraRubyScrivania()
        s.blocca(animato: false)
        controlla(s.bloccato && s.sistema.paginaRuby == 0, "Blocco: sotto la schermata si torna ai widget")
        controlla(!s.scrivaniaPerRuby, "Blocco: con la schermata di benvenuto il gesto non apre Ruby")
        s.sblocca()
        s.apri(.posizioni)
        controlla(!s.scrivaniaPerRuby, "Con una finestra davanti il gesto non apre Ruby")

        // Il quadro visivo: cifre di Prisma, mai del modello
        let posizioni = s.posizioniCliente("giulia")
        let inEssere = posizioni.filter { $0.stato == .inEssere && !$0.area.passivo && $0.valore > 0 }
        if let q = QuadroRuby.perCliente(domanda: "Come è diviso il patrimonio di Giulia?", posizioni: posizioni, obiettivi: []),
           case .barre(let barre) = q.forma {
            let atteso = inEssere.reduce(0) { $0 + $1.valore }
            controlla(abs(q.totale - atteso) < 0.01, "Quadro: il patrimonio per area somma le posizioni in essere")
            controlla(barre.map(\.importo) == barre.map(\.importo).sorted(by: >), "Quadro: le aree dalla più grande")
        } else {
            controlla(false, "Quadro: il patrimonio di Giulia ha le barre per area")
        }
        if let q = QuadroRuby.perPortafoglio(domanda: "Come si divide il portafoglio tra Alleanza e indipendente?", posizioni: s.posizioni),
           case .barre(let barre) = q.forma {
            controlla(barre.allSatisfy { if case .canale(_) = $0.tinta { return true } else { return false } },
                      "Quadro: il portafoglio per canale ha i colori dei canali")
        } else {
            controlla(false, "Quadro: il portafoglio per canale ha le barre")
        }
        controlla(QuadroRuby.perCliente(domanda: "Raccontami una barzelletta", posizioni: posizioni, obiettivi: []) == nil,
                  "Quadro: niente quadro se la domanda non parla di cifre")
        var libera = MessaggioRuby(autore: .ruby, testo: "Ciao!")
        libera.modalita = .conversazione
        controlla(!QuadroRuby.ammessa(libera), "Quadro: niente quadro in conversazione libera")
        controlla(!QuadroRuby.ammessa(MessaggioRuby(autore: .ruby, testo: "", titolo: "Qwen non è pronto")),
                  "Quadro: niente quadro se Qwen non è pronto")
        return esiti
    }
}
