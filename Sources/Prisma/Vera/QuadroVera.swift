import Foundation

// Il quadro visivo sotto una risposta di Vera: si capisce guardando, non solo leggendo.
// Le cifre le calcola sempre Prisma dai dati (posizioni, scadenze), mai il modello: Qwen racconta, il quadro mostra.
// Lo usano la Vera della scrivania (Shell/VeraScrivania.swift) e l'app Vera, sotto l'ultima risposta.

/// Un quadro: barre (aree o canali) oppure la linea del tempo delle scadenze.
struct QuadroVera: Equatable {
    /// Il colore di una barra: quello del canale o quello dell'area.
    enum Tinta: Equatable {
        case canale(Canale)
        case area(AreaPosizione)
    }

    struct Barra: Equatable, Identifiable {
        var id: String
        var titolo: String
        var importo: Double
        var tinta: Tinta
    }

    enum Forma: Equatable {
        case barre([Barra])
        case linea(LineaTempoMiniVera)
    }

    var titolo: String
    var totale: Double
    var forma: Forma
    var fonte = "Cifre dai calcoli di Prisma"

    /// Massimo di scadenze sulla linea del portafoglio: oltre, le etichette si sovrappongono.
    static let massimoScadenze = 6

    // MARK: - Cliente

    /// Il quadro per una domanda su un cliente: le scadenze (linea del tempo) o il patrimonio per area o per canale.
    /// nil se la domanda non parla di cifre che si possono mostrare.
    static func perCliente(domanda: String, posizioni: [Posizione], obiettivi: [Obiettivo], oggi: Date = Date()) -> QuadroVera? {
        let t = NucleoVera.semplice(domanda)
        let argomento = SpuntoVera.argomento(domanda) ?? SpuntoVera.da(domanda)
        let suScadenze = argomento == .scadenze || argomento == .liquidita
            || ["scad", "svincol", "in arrivo", "prossimi mesi"].contains { t.contains($0) }
        if suScadenze {
            // La stessa linea della mini Vera (CifreMiniVera): le scadenze in essere dei prossimi 12 mesi
            let cal = Calendar.current
            let limite = cal.date(byAdding: .month, value: Tema.Misura.MiniVera.mesiLineaTempo, to: oggi) ?? oggi
            let inScadenza = posizioni
                .filter { $0.stato == .inEssere && ($0.scadenza.map { $0 >= cal.startOfDay(for: oggi) && $0 <= limite } ?? false) }
                .sorted { ($0.scadenza ?? oggi) < ($1.scadenza ?? oggi) }
            guard !inScadenza.isEmpty else { return nil }
            let l = CifreMiniVera.linea(inScadenza, obiettivi: obiettivi, oggi: oggi, limite: limite)
            return QuadroVera(titolo: l.titolo, totale: inScadenza.reduce(0) { $0 + $1.valore }, forma: .linea(l),
                             fonte: "Cifre dai calcoli di Posizioni")
        }
        let suArgomento = argomento.map { [SpuntoVera.riepilogo, .checkUp, .resoconto, .pensione].contains($0) } ?? false
        let suPatrimonio = suArgomento
            || ["posizion", "portafogl", "patrimon", "investiment", "polizz", "alleanza", "indipendent", "canal", "riepilog",
                "riassum", "dossier", "check", "quanto ha", "valore", "area", "aree", "previd", "risparm"].contains { t.contains($0) }
        guard suPatrimonio else { return nil }
        let inEssere = posizioni.filter { $0.stato == .inEssere && !$0.area.passivo }
        if suCanali(t) { return canali(inEssere, titolo: "Il patrimonio per canale") }
        return aree(inEssere, titolo: "Il patrimonio per area")
    }

    // MARK: - Portafoglio

    /// Il quadro per una domanda sul portafoglio (tutti i clienti): le aree o i canali, oppure le scadenze.
    static func perPortafoglio(domanda: String, posizioni: [Posizione], oggi: Date = Date()) -> QuadroVera? {
        let t = NucleoVera.semplice(domanda)
        let inEssere = posizioni.filter { $0.stato == .inEssere && !$0.area.passivo }
        switch SpuntoPortafoglio.da(domanda) {
        case .scadenze:
            let cal = Calendar.current
            let limite = cal.date(byAdding: .month, value: Tema.Misura.MiniVera.mesiLineaTempo, to: oggi) ?? oggi
            let inScadenza = inEssere.filter { ($0.scadenza.map { $0 >= cal.startOfDay(for: oggi) && $0 <= limite } ?? false) }
            guard !inScadenza.isEmpty else { return nil }
            // Le maggiori, in ordine di data: la linea resta leggibile
            let scelte = inScadenza.sorted { $0.valore > $1.valore }.prefix(massimoScadenze)
                .sorted { ($0.scadenza ?? oggi) < ($1.scadenza ?? oggi) }
            let titolo = inScadenza.count > scelte.count ? "Le scadenze maggiori · prossimi 12 mesi" : "In scadenza · prossimi 12 mesi"
            let l = CifreMiniVera.linea(Array(scelte), obiettivi: [], oggi: oggi, limite: limite, titolo: titolo)
            return QuadroVera(titolo: l.titolo, totale: scelte.reduce(0) { $0 + $1.valore }, forma: .linea(l),
                             fonte: "Cifre dai calcoli del Portafoglio")
        case .quadro, .concentrazione:
            if suCanali(t) { return canali(inEssere, titolo: "Il portafoglio per canale") }
            return aree(inEssere, titolo: "Il portafoglio per area")
        default:
            return nil
        }
    }

    // MARK: - Pezzi

    private static func suCanali(_ t: String) -> Bool {
        ["canal", "alleanza", "indipendent"].contains { t.contains($0) }
    }

    /// Una barra per area, dalla più grande (le aree vuote non ci sono).
    static func aree(_ posizioni: [Posizione], titolo: String) -> QuadroVera? {
        var somme: [AreaPosizione: Double] = [:]
        for p in posizioni where p.valore > 0 { somme[p.area, default: 0] += p.valore }
        let barre = AreaPosizione.allCases.compactMap { a in
            somme[a].map { Barra(id: a.rawValue, titolo: a.nome, importo: $0, tinta: .area(a)) }
        }.sorted { $0.importo > $1.importo }
        guard !barre.isEmpty else { return nil }
        return QuadroVera(titolo: titolo, totale: barre.reduce(0) { $0 + $1.importo }, forma: .barre(barre))
    }

    /// Alleanza e indipendente: sempre riconoscibili, nel colore del canale.
    static func canali(_ posizioni: [Posizione], titolo: String) -> QuadroVera? {
        let barre = Canale.allCases.compactMap { c -> Barra? in
            let somma = posizioni.filter { $0.canale == c && $0.valore > 0 }.reduce(0) { $0 + $1.valore }
            return somma > 0 ? Barra(id: c.rawValue, titolo: c.nomeBreve, importo: somma, tinta: .canale(c)) : nil
        }
        guard !barre.isEmpty else { return nil }
        return QuadroVera(titolo: titolo, totale: barre.reduce(0) { $0 + $1.importo }, forma: .barre(barre))
    }

    /// Le risposte senza quadro: errori, Qwen non pronto, azioni fatte da Prisma, conversazione libera.
    static func ammessa(_ m: MessaggioVera) -> Bool {
        guard m.autore == .vera, m.azione == nil, m.modalita != .conversazione else { return false }
        // Le risposte con una scheda propria (norme, 30 secondi, clientela, conferma) non portano il quadro del patrimonio
        guard m.norme == nil, m.trenta == nil, m.clientela == nil, m.conferma == nil, m.promesse == nil, m.lettura == nil,
              m.confronto == nil, m.copertura == nil, m.resoconto == nil else { return false }
        // Fase 4: routine, agenda che si organizza, tagliando, mercato per i clienti, stile, tre livelli e piano a passi
        guard m.esitoRoutine == nil, m.agendaOrari == nil, m.agendaSpostamento == nil, m.tagliando == nil, m.mercatoClienti == nil,
              m.stileVera == nil, m.treLivelli == nil, m.pianoPassi == nil else { return false }
        if let t = m.titolo, t == "Qwen non è pronto" || t == "Vera non ha potuto rispondere" { return false }
        return m.motore != StatoShell.motoreAzioni
    }
}

extension StatoShell {
    /// Il quadro visivo di una risposta di Vera, ricavato dalla domanda che la precede e dai dati di oggi.
    /// `portafoglio`: la conversazione è quella di tutti i clienti.
    func quadroVera(per m: MessaggioVera, in elenco: [MessaggioVera], portafoglio: Bool) -> QuadroVera? {
        // Gli scenari «E se…?» hanno già la loro scheda prima/dopo (SchedaScenarioVeraVista)
        guard QuadroVera.ammessa(m), m.scenario == nil, let i = elenco.firstIndex(where: { $0.id == m.id }),
              let domanda = elenco[..<i].last(where: { $0.autore == .utente })?.testo else { return nil }
        if portafoglio { return QuadroVera.perPortafoglio(domanda: domanda, posizioni: posizioni) }
        let id = clienteAttivoId
        guard cliente(id) != nil else { return nil }
        return QuadroVera.perCliente(domanda: domanda, posizioni: posizioniCliente(id), obiettivi: obiettiviCliente(id))
    }
}
