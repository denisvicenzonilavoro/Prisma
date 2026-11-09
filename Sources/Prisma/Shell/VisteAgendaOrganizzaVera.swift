import SwiftUI

// «L'agenda che si organizza» sotto le risposte di Vera (Design/template-vera.html, «// 4 · L'AGENDA CHE SI ORGANIZZA»):
// la settimana con gli impegni nel colore del cliente e gli orari proposti tratteggiati nel colore di Vera (tocca per
// scegliere); lo spostamento in blocco con il giorno da liberare e quello di arrivo. Le cifre (orari, giorni) vengono
// dal motore; qui solo il disegno. In modalità cliente gli impegni degli altri sono «Occupato», senza nomi.
// Movimento: gli orari proposti entrano di lato (`entrataLaterale`), già fermi con «Riduci movimento» e nelle istantanee.

private typealias F = Tema.Apple.FaseTreVera
private typealias G = Tema.Apple.AgendaOrganizza

/// Un blocco della griglia dell'agenda.
struct BloccoAgendaOrganizza: Identifiable {
    enum Stile {
        /// Un impegno in agenda: fondo tenue e filo a sinistra nel colore del cliente.
        case impegno
        /// L'impegno che il cliente non può fare (da sostituire): sbiadito.
        case sbiadito
        /// Dove era un impegno che si sposta: solo il contorno tratteggiato.
        case ombra
        /// Un orario proposto: tratteggiato nel colore di Vera.
        case proposta
        /// L'orario scelto: pieno, bordo continuo.
        case scelta
    }

    let id: String
    let colonna: Int
    /// Minuti dalla mezzanotte.
    let inizio: Int
    let fine: Int
    let titolo: String
    let sotto: String
    let colore: Color
    let stile: Stile
    /// Per gli orari proposti: entra di lato con questo indice.
    var entrata: Int? = nil
    var tocca: (() -> Void)? = nil
    var aiuto: String = ""
}

/// I conti della griglia (giorni e ore da mostrare), fuori dalle viste.
enum AgendaOrganizzaGriglia {
    /// I giorni di lavoro della settimana del primo orario; se gli orari cadono in settimane diverse, i soli loro giorni.
    static func giorni(_ date: [Date], orari: OrariLavoro, cal: Calendar) -> [Date] {
        let suoi = Array(Set(date.map { cal.startOfDay(for: $0) })).sorted()
        guard let primo = suoi.first else { return [] }
        let inizio = cal.dateInterval(of: .weekOfYear, for: primo)?.start ?? primo
        let settimana = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: inizio) }
            .map { cal.startOfDay(for: $0) }
            .filter { orari.giorni.contains(cal.component(.weekday, from: $0)) }
        if !settimana.isEmpty, suoi.allSatisfy({ settimana.contains($0) }) { return settimana }
        return suoi
    }

    /// Le ore intere da mostrare: le fasce di lavoro, allargate se un blocco ne esce.
    static func ore(_ orari: OrariLavoro, minuti: [Int]) -> (da: Int, a: Int) {
        var inizio = orari.fasce.map(\.inizio).min() ?? G.oraInizio * 60
        var fine = orari.fasce.map(\.fine).max() ?? G.oraFine * 60
        if let m = minuti.min() { inizio = min(inizio, m) }
        if let m = minuti.max() { fine = max(fine, m) }
        let da = max(0, inizio / 60)
        return (da, max(da + 1, min(24, (fine + 59) / 60)))
    }

    static func colonna(_ d: Date, in giorni: [Date], cal: Calendar) -> Int? {
        giorni.firstIndex { cal.isDate($0, inSameDayAs: d) }
    }

    static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + String(s.dropFirst()) }

    /// L'etichetta di un orario proposto da mostrare: in modalità cliente non nomina gli altri clienti né i loro
    /// impegni, anche se la ricerca è nata fuori da quella modalità (la conversazione del dossier è la stessa).
    static func etichetta(_ p: OrarioProposto, inModoCliente: Bool) -> String {
        guard inModoCliente, p.attaccato else { return p.etichetta }
        return p.vicinanza == .prima ? "prima di un altro incontro in studio" : "subito dopo un altro incontro in studio"
    }

    /// Le mosse dello spostamento davvero avvenute: l'impegno c'è ancora ed è all'orario di arrivo.
    static func mosseFatte(_ s: SpostamentoBlocco, appuntamenti: [Appuntamento]) -> Set<String> {
        Set(s.mosse.filter { m in appuntamenti.contains { $0.id == m.appuntamentoId && $0.inizio == m.inizio } }.map(\.appuntamentoId))
    }

    /// Le mosse il cui impegno è ancora pianificato nel giorno di partenza (tolte, non riuscite o annullate).
    static func mosseRimaste(_ s: SpostamentoBlocco, appuntamenti: [Appuntamento], cal: Calendar) -> Set<String> {
        Set(s.mosse.filter { m in
            appuntamenti.contains { $0.id == m.appuntamentoId && $0.stato == .pianificato && cal.isDate($0.inizio, inSameDayAs: s.da) }
        }.map(\.appuntamentoId))
    }

    /// Nessun impegno pianificato nel giorno (i blocchi «Non disponibile» non contano): il giorno è davvero libero.
    static func giornoLibero(_ giorno: Date, appuntamenti: [Appuntamento], cal: Calendar) -> Bool {
        !appuntamenti.contains { $0.stato == .pianificato && $0.tipo != .nonDisponibile && cal.isDate($0.inizio, inSameDayAs: giorno) }
    }

    /// Gli impegni delle mosse tolte con ✕ dalla scheda «Conferma» (non si spostano: non si disegnano come proposte).
    static func mosseTolte(_ scheda: SchedaConfermaVera?) -> Set<String> {
        guard let scheda else { return [] }
        return Set(scheda.azioni.filter { $0.strumento == RegistroStrumenti.agendaSposta && $0.tolta }
            .compactMap { $0.argomenti["appuntamento"] })
    }
}

/// La settimana (o i giorni) con le ore a sinistra e i blocchi posati per giorno e ora.
struct GrigliaAgendaOrganizza: View {
    let giorni: [Date]
    let daOra: Int
    let aOra: Int
    let blocchi: [BloccoAgendaOrganizza]
    /// Il giorno da segnare in rosso nell'intestazione (nil nelle istantanee).
    var oggi: Date? = nil

    private var cal: Calendar { MotorePianificazione.calendario }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: G.colonnaOre)
                ForEach(giorni, id: \.self) { g in
                    let eOggi = oggi.map { cal.isDate(g, inSameDayAs: $0) } ?? false
                    Text(Formati.giornoBreve.string(from: g))
                        .carattereApple(G.giorno)
                        .foregroundColor(eOggi ? G.coloreOggi : G.coloreGiorno)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: G.altezzaIntestazione)
            GeometryReader { geo in
                let colonna = max(0, (geo.size.width - G.colonnaOre) / CGFloat(max(1, giorni.count)))
                ZStack(alignment: .topLeading) {
                    ForEach(daOra..<aOra, id: \.self) { h in
                        VStack(alignment: .leading, spacing: 0) {
                            Rectangle().fill(G.filo).frame(height: G.spessoreFilo)
                            Text(OrariLavoro.testoOra(h * 60))
                                .carattereApple(G.ora)
                                .foregroundColor(G.coloreOra)
                                .padding(.top, G.sopraOra)
                        }
                        .frame(width: geo.size.width, alignment: .leading)
                        .offset(y: CGFloat(h - daOra) * G.altezzaOra)
                    }
                    ForEach(blocchi) { b in
                        let alto = max(G.altezzaMinima, CGFloat(b.fine - b.inizio) / 60 * G.altezzaOra - G.spazioBlocco)
                        BloccoAgendaOrganizzaVista(blocco: b, conSotto: alto >= G.sogliaSotto)
                            .frame(width: max(0, colonna - 2 * G.spazioBlocco), height: alto)
                            .offset(x: G.colonnaOre + CGFloat(b.colonna) * colonna + G.spazioBlocco,
                                    y: CGFloat(b.inizio - daOra * 60) / 60 * G.altezzaOra)
                    }
                }
            }
            .frame(height: CGFloat(aOra - daOra) * G.altezzaOra)
        }
        .accessibilityElement(children: .contain)
    }
}

/// Un blocco: impegno, impegno sbiadito, ombra, orario proposto o scelto.
struct BloccoAgendaOrganizzaVista: View {
    let blocco: BloccoAgendaOrganizza
    let conSotto: Bool

    var body: some View {
        if let tocca = blocco.tocca {
            Button(action: tocca) { forma }
                .buttonStyle(.plain)
                .help(blocco.aiuto)
                .accessibilityLabel(Text(blocco.aiuto.isEmpty ? blocco.titolo : blocco.aiuto))
                .modifier(EntrataBloccoAgenda(indice: blocco.entrata))
        } else {
            forma
                .accessibilityElement(children: .combine)
                .modifier(EntrataBloccoAgenda(indice: blocco.entrata))
        }
    }

    private var contenuto: some View {
        VStack(alignment: .leading, spacing: G.spazioRighe) {
            Text(blocco.titolo)
                .carattereApple(G.titoloBlocco)
                .foregroundColor(blocco.stile == .proposta || blocco.stile == .scelta ? Tema.Apple.agendaProposta : G.testoBlocco)
                .lineLimit(1)
            if conSotto, !blocco.sotto.isEmpty {
                Text(blocco.sotto)
                    .carattereApple(G.sottoBlocco)
                    .foregroundColor(G.coloreSotto)
                    .lineLimit(1)
            }
        }
        .padding(G.paddingBlocco)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private var forma: some View {
        let sagoma = RoundedRectangle(cornerRadius: G.raggioBlocco, style: .continuous)
        switch blocco.stile {
        case .impegno, .sbiadito:
            contenuto
                .padding(.leading, G.filoBlocco)
                .background {
                    sagoma.fill(blocco.colore.opacity(G.alfaFondo))
                        .overlay(alignment: .leading) { Rectangle().fill(blocco.colore).frame(width: G.filoBlocco) }
                        .clipShape(sagoma)
                }
                .opacity(blocco.stile == .sbiadito ? G.opacitaSbiadito : 1)
        case .ombra:
            contenuto
                .opacity(G.opacitaSbiadito)
                .overlay {
                    sagoma.strokeBorder(blocco.colore.opacity(G.opacitaSbiadito),
                                        style: StrokeStyle(lineWidth: G.spessoreOmbra, dash: G.trattinoOmbra))
                }
        case .proposta:
            contenuto
                .background { sagoma.fill(Tema.Apple.agendaPropostaFondo) }
                .overlay {
                    sagoma.strokeBorder(Tema.Apple.agendaProposta, style: StrokeStyle(lineWidth: G.trattoProposta, dash: G.trattino))
                }
                .contentShape(sagoma)
        case .scelta:
            contenuto
                .background { sagoma.fill(Tema.Apple.agendaPropostaScelta) }
                .overlay { sagoma.strokeBorder(Tema.Apple.agendaProposta, lineWidth: G.trattoProposta) }
                .contentShape(sagoma)
        }
    }
}

/// Gli orari proposti entrano di lato, uno dopo l'altro; gli altri blocchi sono subito al loro posto.
private struct EntrataBloccoAgenda: ViewModifier {
    let indice: Int?

    func body(content: Content) -> some View {
        if let indice {
            content.entrataLaterale(indice)
        } else {
            content
        }
    }
}

// MARK: - I due orari

/// Sotto la risposta «Ti propongo due orari…»: la settimana con gli orari tratteggiati (tocca per scegliere).
struct AgendaOrganizzaOrariVista: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.modoIstantanea) private var istantanea
    let messaggio: String
    let ricerca: RicercaOrari
    let scelto: String?

    private var cal: Calendar { MotorePianificazione.calendario }

    var body: some View {
        let _ = ContaCorpi.segna()
        let orari = stato.dati.impostazioni.orari
        let giorni = AgendaOrganizzaGriglia.giorni(ricerca.proposte.map(\.inizio), orari: orari, cal: cal)
        let elenco = blocchi(giorni)
        let ore = AgendaOrganizzaGriglia.ore(orari, minuti: elenco.flatMap { [$0.inizio, $0.fine] })
        VStack(alignment: .leading, spacing: G.spazio) {
            GrigliaAgendaOrganizza(giorni: giorni, daOra: ore.da, aOra: ore.a, blocchi: elenco, oggi: istantanea ? nil : Date())
                .padding(G.paddingGriglia)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            HStack(spacing: G.spazio) {
                PillolaFaseTre(testo: "Tratteggiati", colore: Tema.Apple.agendaProposta)
                Text(scelto == nil ? "gli orari che Vera propone · tocca per scegliere" : "l'orario scelto è pieno · tocca un altro orario per cambiare")
                    .carattereApple(F.nota)
                    .foregroundColor(F.coloreDettaglio)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if !stato.inModoCliente, let primo = ricerca.proposte.first {
                    Button("Apri in Agenda") { stato.apriAgendaOrganizza(giorno: primo.inizio) }
                        .buttonStyle(.apple)
                        .fixedSize()
                }
            }
        }
        .padding(.top, F.sopraScheda)
    }

    private func blocchi(_ giorni: [Date]) -> [BloccoAgendaOrganizza] {
        let r = ricerca.richiesta
        let c = r.clienteId.flatMap { stato.cliente($0) }
        let impegni = stato.dati.appuntamenti.filter { a in
            a.stato == .pianificato && AgendaOrganizzaGriglia.colonna(a.inizio, in: giorni, cal: cal) != nil
        }
        // L'orario scelto e già in agenda (dopo «Conferma»): si vede l'impegno vero, non più la proposta
        let fissato: Appuntamento? = scelto.flatMap { s in ricerca.proposte.first { $0.id == s } }.flatMap { p in
            impegni.first { $0.clienteId == r.clienteId && $0.inizio == p.inizio }
        }
        var elenco: [BloccoAgendaOrganizza] = []
        for a in impegni {
            guard let col = AgendaOrganizzaGriglia.colonna(a.inizio, in: giorni, cal: cal) else { continue }
            let visibile = !stato.inModoCliente || (stato.visibileAlCliente(a.clienteId) && !a.clienteId.isEmpty)
            let chi = stato.cliente(a.clienteId)
            let daSostituire = a.id == r.daSpostare && a.id != fissato?.id
            let sotto = daSostituire ? "Da spostare" : [chi.map { StatoShell.primoNome($0.nome) }, a.luogo.isEmpty ? nil : a.luogo]
                .compactMap { $0 }.joined(separator: " · ")
            elenco.append(BloccoAgendaOrganizza(id: a.id, colonna: col,
                                                inizio: AgendaOrganizzaVera.minuti(a.inizio, cal: cal),
                                                fine: AgendaOrganizzaVera.minuti(a.inizio, cal: cal) + a.durataMinuti,
                                                titolo: visibile ? a.titolo : "Occupato",
                                                sotto: visibile ? sotto : "",
                                                colore: visibile ? Tema.Apple.Agenda.colore(chi) : G.occupato,
                                                stile: daSostituire ? .sbiadito : .impegno))
        }
        for (n, p) in ricerca.proposte.enumerated() {
            guard let col = AgendaOrganizzaGriglia.colonna(p.inizio, in: giorni, cal: cal) else { continue }
            if p.id == scelto, fissato != nil { continue }
            let inizio = AgendaOrganizzaVera.minuti(p.inizio, cal: cal)
            let titolo = c.map { RegistroStrumenti.titoloImpegno(r.tipo, cliente: StatoShell.primoNome($0.nome)) + "?" } ?? "Orario libero?"
            let etichetta = AgendaOrganizzaGriglia.etichetta(p, inModoCliente: stato.inModoCliente)
            let sotto = [etichetta.isEmpty ? nil : AgendaOrganizzaGriglia.maiuscola(etichetta), r.modo.luogo.isEmpty ? nil : r.modo.luogo]
                .compactMap { $0 }.joined(separator: " · ")
            let quando = DateItaliane.descrivi(p.inizio, conOra: true, oggi: Date(), cal: cal)
            elenco.append(BloccoAgendaOrganizza(id: p.id, colonna: col, inizio: inizio,
                                                fine: inizio + Int(p.fine.timeIntervalSince(p.inizio) / 60),
                                                titolo: titolo, sotto: sotto, colore: Tema.Apple.agendaProposta,
                                                stile: p.id == scelto ? .scelta : .proposta,
                                                entrata: n,
                                                tocca: { _ = stato.scegliOrarioAgenda(messaggio: messaggio, orario: p.id) },
                                                aiuto: "Scegli \(quando)" + (etichetta.isEmpty ? "" : ", \(etichetta)")))
        }
        return elenco
    }
}

// MARK: - Lo spostamento in blocco

/// Sotto «Sposto due impegni a venerdì…»: il giorno da liberare e quello di arrivo, con i nuovi orari tratteggiati
/// finché non confermi; dopo «Conferma» sono pieni nel giorno di arrivo solo gli impegni davvero spostati (letti
/// dall'agenda di adesso): quelli tolti, non riusciti o annullati restano nel giorno di partenza.
struct AgendaOrganizzaSpostamentoVista: View {
    @Environment(StatoShell.self) var stato
    @Environment(\.modoIstantanea) private var istantanea
    let spostamento: SpostamentoBlocco
    let eseguito: Bool
    /// La scheda «Conferma» del messaggio: le righe tolte con ✕ non si disegnano come proposte.
    var scheda: SchedaConfermaVera? = nil

    private var cal: Calendar { MotorePianificazione.calendario }

    /// Annullato, lasciato stare o sostituito: le mosse non si possono più confermare, la griglia mostra solo gli
    /// impegni di adesso con una pillola neutra.
    private var chiusa: String? {
        switch scheda?.stato {
        case .annullata: return "Annullato"
        case .rinunciata: return "Lasciato stare"
        case .sostituita: return "Sostituito"
        default: return nil
        }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let giorni = [cal.startOfDay(for: spostamento.da), cal.startOfDay(for: spostamento.a)]
        let elenco = blocchi(giorni)
        let ore = AgendaOrganizzaGriglia.ore(stato.dati.impostazioni.orari, minuti: elenco.flatMap { [$0.inizio, $0.fine] })
        VStack(alignment: .leading, spacing: G.spazio) {
            GrigliaAgendaOrganizza(giorni: giorni, daOra: ore.da, aOra: ore.a, blocchi: elenco, oggi: istantanea ? nil : Date())
                .padding(G.paddingGriglia)
                .superficieApple(Tema.Apple.Vera.SchedaCalcoli.superficie, raggio: Tema.Apple.Raggio.tile)
            HStack(spacing: G.spazio) {
                if let chiusa {
                    PillolaFaseTre(testo: chiusa, colore: G.occupato)
                } else if eseguito {
                    let appuntamenti = stato.dati.appuntamenti
                    let fatte = AgendaOrganizzaGriglia.mosseFatte(spostamento, appuntamenti: appuntamenti)
                    let rimaste = AgendaOrganizzaGriglia.mosseRimaste(spostamento, appuntamenti: appuntamenti, cal: cal)
                    // «È libero» solo se nel giorno di partenza non resta davvero nessun impegno (anche di altri
                    // clienti, quando lo spostamento era di un cliente solo): lo dice l'agenda di adesso
                    if rimaste.isEmpty, !fatte.isEmpty,
                       AgendaOrganizzaGriglia.giornoLibero(spostamento.da, appuntamenti: appuntamenti, cal: cal) {
                        PillolaFaseTre(testo: "\(AgendaOrganizzaGriglia.maiuscola(Formati.giornoSettimana.string(from: spostamento.da))) è libero ✓", colore: F.verde)
                    } else {
                        PillolaFaseTre(testo: "Spostati \(fatte.count) di \(spostamento.mosse.count)", colore: F.arancio)
                    }
                } else {
                    PillolaFaseTre(testo: "Tratteggiati", colore: Tema.Apple.agendaProposta)
                    Text("i nuovi orari · con «Conferma» li sposto e preparo i messaggi per i clienti")
                        .carattereApple(F.nota)
                        .foregroundColor(F.coloreDettaglio)
                        .lineLimit(2)
                }
                if chiusa == nil, !spostamento.restano.isEmpty {
                    PillolaFaseTre(testo: spostamento.restano.count == 1 ? "Uno resta dov'è" : "\(spostamento.restano.count) restano dove sono", colore: F.arancio)
                }
                Spacer(minLength: 0)
                if !stato.inModoCliente {
                    Button("Apri in Agenda") { stato.apriAgendaOrganizza(giorno: spostamento.a) }
                        .buttonStyle(.apple)
                        .fixedSize()
                }
            }
        }
        .padding(.top, F.sopraScheda)
    }

    private func blocchi(_ giorni: [Date]) -> [BloccoAgendaOrganizza] {
        let appuntamenti = stato.dati.appuntamenti
        // Le mosse da disegnare nel giorno di arrivo: dopo «Conferma» solo quelle avvenute davvero, prima le righe non tolte
        let tolte = AgendaOrganizzaGriglia.mosseTolte(scheda)
        let disegnate: Set<String> = chiusa != nil ? []
            : eseguito
            ? AgendaOrganizzaGriglia.mosseFatte(spostamento, appuntamenti: appuntamenti)
            : Set(spostamento.mosse.map(\.appuntamentoId)).subtracting(tolte)
        var elenco: [BloccoAgendaOrganizza] = []
        // Gli altri impegni dei due giorni, letti dall'agenda di adesso (anche quelli delle mosse rimaste dove sono)
        for a in appuntamenti where a.stato == .pianificato && !disegnate.contains(a.id) {
            guard let col = AgendaOrganizzaGriglia.colonna(a.inizio, in: giorni, cal: cal) else { continue }
            let visibile = !stato.inModoCliente || (stato.visibileAlCliente(a.clienteId) && !a.clienteId.isEmpty)
            let chi = stato.cliente(a.clienteId)
            let inizio = AgendaOrganizzaVera.minuti(a.inizio, cal: cal)
            elenco.append(BloccoAgendaOrganizza(id: a.id, colonna: col, inizio: inizio, fine: inizio + a.durataMinuti,
                                                titolo: visibile ? a.titolo : "Occupato",
                                                sotto: visibile ? [chi.map { StatoShell.primoNome($0.nome) }, a.luogo.isEmpty ? nil : a.luogo].compactMap { $0 }.joined(separator: " · ") : "",
                                                colore: visibile ? Tema.Apple.Agenda.colore(chi) : G.occupato, stile: .impegno))
        }
        for (n, m) in spostamento.mosse.enumerated() where disegnate.contains(m.appuntamentoId) {
            // In modalità cliente le mosse degli altri clienti sono «Occupato», senza nomi né colore del cliente
            let visibile = !stato.inModoCliente || (stato.visibileAlCliente(m.clienteId) && !m.clienteId.isEmpty)
            let chi = visibile ? stato.cliente(m.clienteId) : nil
            let colore = visibile ? Tema.Apple.Agenda.colore(chi) : G.occupato
            let titolo = visibile ? m.titolo : "Occupato"
            let sotto = visibile ? [chi.map { StatoShell.primoNome($0.nome) }, m.luogo.isEmpty ? nil : m.luogo].compactMap { $0 }.joined(separator: " · ") : ""
            let prima = AgendaOrganizzaVera.minuti(m.prima, cal: cal)
            let dopo = AgendaOrganizzaVera.minuti(m.inizio, cal: cal)
            if !eseguito {
                elenco.append(BloccoAgendaOrganizza(id: m.id + "-prima", colonna: 0, inizio: prima, fine: prima + m.durataMinuti,
                                                    titolo: titolo, sotto: sotto, colore: colore, stile: .ombra))
            }
            let alle = m.stessaOra || !visibile ? sotto : "Alle \(Formati.ora.string(from: m.inizio))" + (sotto.isEmpty ? "" : " · " + sotto)
            elenco.append(BloccoAgendaOrganizza(id: m.id + "-dopo", colonna: 1, inizio: dopo, fine: dopo + m.durataMinuti,
                                                titolo: titolo,
                                                sotto: alle,
                                                colore: eseguito ? colore : Tema.Apple.agendaProposta,
                                                stile: eseguito ? .impegno : .proposta,
                                                entrata: eseguito ? nil : n))
        }
        return elenco
    }
}
