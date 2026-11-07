import Foundation

// MARK: - «Da fare, in ordine di tempo» (Posizioni › Portafoglio, tema Apple §4.1)
// Il nastro delle cose da fare con i clienti, divise in Oggi / Questa settimana / Questo mese / Più avanti.
// Un punto unico che le costruisce da ciò che dicono gli altri motori, senza cifre nuove:
// - proposte ferme (MotoreSeguitoProposte.inSospeso): oggi, si chiudono con l'esito della proposta;
// - riesami dovuti (MotoreRiesame.dovuti): alla data del riesame (oggi se è scaduto o mai fatto), si chiudono
//   registrando il riesame (un incontro concluso con la fotografia della memoria del riesame);
// - scadenze di conformità (MotoreConformita, la voce più urgente di ogni cliente): si chiudono rinnovando la voce
//   oggi (il documento d'identità si aggiorna nella scheda «In regola»);
// - occasioni (MotoreOccasioni, entro `giorniOccasioni`): alla loro data;
// - attività aperte (le cose da fare dell'Agenda, senza le riprese delle proposte già sul nastro): alla scadenza;
// - attenzioni dei dossier (MotoreAttenzioni): senza data, in «Più avanti».
// Occasioni e attenzioni non hanno un esito da salvare: «Segna come fatto» aggiunge un'attività completata con
// l'id `VoceDaFare.idSegno` («fatto-…»), che resta nell'Agenda come traccia e toglie la voce dal nastro.
// Motore puro: riceve `oggi` e gli elenchi già calcolati (la Shell li prende dalle sue cache).

/// Una cosa da fare con un cliente.
struct VoceDaFare: Identifiable, Equatable {
    /// Da dove viene. L'ordine conta: a parità di data, prima le proposte, poi i riesami e così via.
    enum Tipo: Int, Equatable, Comparable {
        case proposta, riesame, conformita, occasione, attivita, attenzione

        static func < (a: Tipo, b: Tipo) -> Bool { a.rawValue < b.rawValue }
    }

    /// I gruppi del nastro, in ordine di tempo.
    enum Gruppo: Int, CaseIterable, Identifiable, Comparable {
        case oggi, settimana, mese, avanti

        var id: Int { rawValue }

        var titolo: String {
            switch self {
            case .oggi: return "Oggi"
            case .settimana: return "Questa settimana"
            case .mese: return "Questo mese"
            case .avanti: return "Più avanti"
            }
        }

        static func < (a: Gruppo, b: Gruppo) -> Bool { a.rawValue < b.rawValue }
    }

    /// Il tono della scheda (fascia e «quando»): rosso oggi, arancio in settimana, verde dopo.
    enum Tono: Equatable { case urgente, presto, sereno }

    /// L'anello dello stato del lavoro che avanza quando la cosa è fatta (MotoreStatoDelLavoro).
    enum Anello: String, Equatable {
        case inRegola, riesami, proposte
    }

    /// Che cosa fa «Segna come fatto».
    enum Fatto: Equatable {
        /// Il modulo dell'esito della proposta (accettata, rifiutata, rimandata).
        case esitoProposta(posizioneId: String)
        /// Un incontro di riesame concluso oggi, con la fotografia della memoria del riesame.
        case riesame
        /// La voce di conformità rinnovata oggi (`StatoShell.rinnovaOggi`).
        case rinnova(VoceConformita.Tipo)
        /// La scheda «In regola» del cliente (il documento d'identità chiede i dati nuovi).
        case apriInRegola
        /// L'attività completata.
        case attivita(id: String)
        /// Un'attività completata con l'id `idSegno` tiene il segno (occasioni e attenzioni).
        case segna
    }

    let id: String
    let tipo: Tipo
    let cliente: Cliente
    /// Quando va fatta; nil per le attenzioni (in «Più avanti»).
    let data: Date?
    let gruppo: Gruppo
    /// «Oggi», «Scaduto da 12 giorni», «Giovedì», «Il 24 novembre»… (si mostra in maiuscolo).
    let quando: String
    /// Il perché, breve (19 bold sulla scheda).
    let perche: String
    /// La spiegazione del dettaglio, con il dato concreto.
    let spiegazione: String
    /// I canali di cui si parla, sempre riconoscibili sulla scheda.
    let canali: [Canale]
    /// La posizione di cui si parla (proposta, occasione di un contratto).
    let posizioneId: String?
    let fatto: Fatto
    let anello: Anello?
    /// Il tipo d'incontro per «Preparami l'incontro» (sceglie i report del fascicolo).
    let tipoIncontro: TipoAppuntamento

    var tono: Tono {
        switch gruppo {
        case .oggi: return .urgente
        case .settimana: return .presto
        case .mese, .avanti: return .sereno
        }
    }

    /// L'id dell'attività completata che tiene il segno «fatto» di occasioni e attenzioni.
    var idSegno: String { MotoreDaFare.prefissoSegno + id }
}

/// Il nastro: i gruppi non vuoti, ognuno con al più `MotoreDaFare.massimoPerGruppo` voci.
struct NastroDaFare: Equatable {
    struct Blocco: Identifiable, Equatable {
        let gruppo: VoceDaFare.Gruppo
        let voci: [VoceDaFare]
        /// Tutte le voci del gruppo (anche quelle oltre il massimo).
        let totale: Int

        var id: Int { gruppo.rawValue }
        var nascoste: Int { max(0, totale - voci.count) }
    }

    let blocchi: [Blocco]

    var totale: Int { blocchi.reduce(0) { $0 + $1.totale } }
    var diOggi: Int { blocchi.first { $0.gruppo == .oggi }?.totale ?? 0 }
    var vuoto: Bool { blocchi.isEmpty }
    /// Le voci mostrate, nell'ordine del nastro.
    var voci: [VoceDaFare] { blocchi.flatMap(\.voci) }
}

enum MotoreDaFare {
    /// Schede al massimo per gruppo (le altre si contano nella testata del gruppo).
    static let massimoPerGruppo = 8
    /// Fin dove guardano le occasioni.
    static let giorniOccasioni = 60
    /// Il prefisso delle attività che tengono il segno «fatto».
    static let prefissoSegno = "fatto-"

    /// Ciò che il motore incrocia, già calcolato dagli altri motori.
    struct Ingressi {
        let clienti: [Cliente]
        let posizioni: [Posizione]
        /// Tutte le attività (anche le completate: tengono i segni «fatto»).
        let attivita: [Attivita]
        /// MotoreSeguitoProposte.inSospeso
        let proposte: [PropostaInSospeso]
        /// MotoreRiesame.dovuti
        let riesami: [RiesameDovuto]
        /// MotoreConformita.calcola
        let conformita: [EsitoConformita]
        /// MotoreOccasioni.calcola da oggi a oggi + `giorniOccasioni`.
        let occasioni: [Occasione]
        /// MotoreAttenzioni.calcola
        let attenzioni: [Attenzione]
        let oggi: Date
    }

    // MARK: - Il nastro

    static func calcola(_ x: Ingressi) -> NastroDaFare {
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: x.oggi)
        let visibili = Set(x.clienti.map(\.id))
        let segni = Set(x.attivita.filter { $0.completata && $0.id.hasPrefix(prefissoSegno) }.map(\.id))
        let canaliPer = canaliDeiClienti(x.posizioni)
        func canali(_ c: Cliente) -> [Canale] {
            let suoi = canaliPer[c.id] ?? []
            return suoi.isEmpty ? Canale.allCases.filter { c.canali.contains($0) } : suoi
        }
        var voci: [VoceDaFare] = []

        // Proposte ferme: si chiamano oggi
        var riprese = Set<String>()
        for s in x.proposte where visibili.contains(s.cliente.id) {
            if let t = s.posizione.seguito?.attivitaId { riprese.insert(t) }
            voci.append(VoceDaFare(
                id: "proposta-" + s.posizione.id, tipo: .proposta, cliente: s.cliente, data: inizio,
                gruppo: .oggi, quando: s.giorni > 0 ? "Ferma da \(giorni(s.giorni))" : "Oggi",
                perche: "Riprendi «\(nomePosizione(s.posizione))»", spiegazione: spiegazioneProposta(s),
                canali: [s.posizione.canale], posizioneId: s.posizione.id,
                fatto: .esitoProposta(posizioneId: s.posizione.id), anello: .proposte, tipoIncontro: .proposta))
        }

        // Riesami dovuti: alla data (oggi se scaduto o mai fatto)
        for r in x.riesami where visibili.contains(r.cliente.id) {
            let data = max(inizio, cal.startOfDay(for: r.dovutoDal ?? inizio))
            let g = gruppo(data, oggi: x.oggi)
            let quando: String
            if r.ultimoContatto == nil {
                quando = "Mai fatto"
            } else if let d = r.dovutoDal, cal.startOfDay(for: d) < inizio {
                quando = "Scaduto da \(giorni(MotoreSeguitoProposte.giorni(da: d, a: x.oggi)))"
            } else {
                quando = testoQuando(data, gruppo: g, oggi: x.oggi)
            }
            let spiegazione: String
            if let u = r.ultimoContatto {
                spiegazione = "L'ultimo incontro è del \(Formati.dataEstesa.string(from: u)): è il momento di rivedere insieme posizioni, obiettivi e coperture."
            } else {
                spiegazione = "Ha posizioni in essere ma nessun incontro registrato in Prisma: il primo riesame fissa il punto di partenza."
            }
            voci.append(VoceDaFare(
                id: "riesame-" + r.cliente.id, tipo: .riesame, cliente: r.cliente, data: data, gruppo: g, quando: quando,
                perche: r.ultimoContatto == nil ? "Primo riesame annuale" : "Riesame annuale",
                spiegazione: spiegazione, canali: canali(r.cliente), posizioneId: nil,
                fatto: .riesame, anello: .riesami, tipoIncontro: .revisione))
        }

        // Conformità: la voce più urgente di ogni cliente
        for e in x.conformita where visibili.contains(e.cliente.id) {
            let daSistemare = e.daSistemare
            guard let v = daSistemare.first else { continue }
            let urgente = v.stato == .scaduta || v.stato == .mancante
            let data = urgente ? inizio : max(inizio, cal.startOfDay(for: v.scadenza ?? inizio))
            let g = gruppo(data, oggi: x.oggi)
            let quando: String
            if v.stato == .mancante {
                quando = "Da raccogliere"
            } else if v.stato == .scaduta, let s = v.scadenza {
                quando = "Scaduto da \(giorni(max(1, MotoreSeguitoProposte.giorni(da: s, a: x.oggi))))"
            } else {
                quando = testoQuando(data, gruppo: g, oggi: x.oggi)
            }
            var spiegazione = TestiConformita.maiuscola(TestiConformita.breve(v)) + "."
            if daSistemare.count > 1 {
                let altre = daSistemare.count - 1
                spiegazione += altre == 1 ? " C'è un'altra voce da sistemare in «In regola»." : " Ci sono altre \(altre) voci da sistemare in «In regola»."
            }
            voci.append(VoceDaFare(
                id: "conformita-" + e.cliente.id, tipo: .conformita, cliente: e.cliente, data: data, gruppo: g,
                quando: quando,
                perche: TestiConformita.nomeBreveMaiuscolo(v) + (v.stato == .mancante ? " da raccogliere" : " da rinnovare"),
                spiegazione: spiegazione, canali: v.canale.map { [$0] } ?? canali(e.cliente), posizioneId: nil,
                fatto: v.tipo == .documento ? .apriInRegola : .rinnova(v.tipo), anello: .inRegola, tipoIncontro: .revisione))
        }

        // Occasioni: alla loro data
        let perId = Dictionary(x.clienti.map { ($0.id, $0) }, uniquingKeysWith: { primo, _ in primo })
        for o in x.occasioni {
            guard let c = perId[o.clienteId] else { continue }
            let id = "occasione-" + o.id
            guard !segni.contains(prefissoSegno + id), cal.startOfDay(for: o.data) >= inizio else { continue }
            let data = cal.startOfDay(for: o.data)
            let g = gruppo(data, oggi: x.oggi)
            voci.append(VoceDaFare(
                id: id, tipo: .occasione, cliente: c, data: data, gruppo: g, quando: testoQuando(data, gruppo: g, oggi: x.oggi),
                perche: o.titolo, spiegazione: o.dettaglio, canali: o.canale.map { [$0] } ?? canali(c),
                posizioneId: o.posizioneId, fatto: .segna, anello: nil,
                tipoIncontro: o.tipo.gruppo == .contratti ? .analisi : .revisione))
        }

        // Attività aperte (le riprese delle proposte sono già sul nastro con la proposta)
        for a in x.attivita where !a.completata && !riprese.contains(a.id) && !a.id.hasPrefix(prefissoSegno) {
            guard let c = perId[a.clienteId] else { continue }
            let data = max(inizio, cal.startOfDay(for: a.scadenza))
            let g = gruppo(data, oggi: x.oggi)
            let quando: String
            if cal.startOfDay(for: a.scadenza) < inizio {
                quando = "Scaduta da \(giorni(MotoreSeguitoProposte.giorni(da: a.scadenza, a: x.oggi)))"
            } else {
                quando = testoQuando(data, gruppo: g, oggi: x.oggi)
            }
            let nota = a.note.trimmingCharacters(in: .whitespacesAndNewlines)
            voci.append(VoceDaFare(
                id: "attivita-" + a.id, tipo: .attivita, cliente: c, data: data, gruppo: g, quando: quando,
                perche: a.titolo.isEmpty ? "Attività senza titolo" : a.titolo,
                spiegazione: nota.isEmpty ? "Un'attività dell'Agenda, priorità \(a.priorita.nome.lowercased())." : nota,
                canali: canali(c), posizioneId: nil, fatto: .attivita(id: a.id), anello: nil, tipoIncontro: .telefonata))
        }

        // Attenzioni dei dossier: senza data
        for a in x.attenzioni where visibili.contains(a.cliente.id) {
            let id = "attenzione-" + a.id
            guard !segni.contains(prefissoSegno + id) else { continue }
            voci.append(VoceDaFare(
                id: id, tipo: .attenzione, cliente: a.cliente, data: nil, gruppo: .avanti, quando: "Quando puoi",
                perche: a.titolo, spiegazione: a.dettaglio, canali: canali(a.cliente), posizioneId: nil,
                fatto: .segna, anello: nil, tipoIncontro: .analisi))
        }

        return nastro(voci)
    }

    /// Le voci divise nei gruppi e ordinate (data, tipo, cliente), al più `massimoPerGruppo` per gruppo.
    static func nastro(_ voci: [VoceDaFare]) -> NastroDaFare {
        var visti = Set<String>()
        let uniche = voci.filter { visti.insert($0.id).inserted }
        let gruppi = Dictionary(grouping: uniche, by: \.gruppo)
        let blocchi = VoceDaFare.Gruppo.allCases.compactMap { g -> NastroDaFare.Blocco? in
            guard let elenco = gruppi[g], !elenco.isEmpty else { return nil }
            let ordinate = elenco.sorted(by: precede)
            return NastroDaFare.Blocco(gruppo: g, voci: Array(ordinate.prefix(massimoPerGruppo)), totale: ordinate.count)
        }
        return NastroDaFare(blocchi: blocchi)
    }

    /// L'ordine del nastro dentro un gruppo: data, tipo, nome del cliente, id.
    static func precede(_ a: VoceDaFare, _ b: VoceDaFare) -> Bool {
        let da = a.data ?? .distantFuture
        let db = b.data ?? .distantFuture
        if da != db { return da < db }
        if a.tipo != b.tipo { return a.tipo < b.tipo }
        let nomi = a.cliente.nome.localizedCompare(b.cliente.nome)
        if nomi != .orderedSame { return nomi == .orderedAscending }
        return a.id < b.id
    }

    /// Il gruppo di una data: oggi (o prima), entro la fine della settimana, entro la fine del mese, più avanti.
    static func gruppo(_ data: Date?, oggi: Date) -> VoceDaFare.Gruppo {
        guard let data else { return .avanti }
        let cal = Calendar.current
        let inizio = cal.startOfDay(for: oggi)
        let giorno = cal.startOfDay(for: data)
        if giorno <= inizio { return .oggi }
        let fineSettimana = cal.dateInterval(of: .weekOfYear, for: inizio)?.end ?? inizio
        if giorno < fineSettimana { return .settimana }
        let fineMese = cal.dateInterval(of: .month, for: inizio)?.end ?? inizio
        if giorno < fineMese { return .mese }
        return .avanti
    }

    /// «Oggi», «Domani», «Giovedì», «Il 24 novembre».
    static func testoQuando(_ data: Date, gruppo: VoceDaFare.Gruppo, oggi: Date) -> String {
        let n = MotoreSeguitoProposte.giorni(da: oggi, a: data)
        if n <= 0 { return "Oggi" }
        if n == 1 { return "Domani" }
        if gruppo == .settimana { return TestiConformita.maiuscola(Formati.giornoSettimana.string(from: data)) }
        return "Il \(Formati.giornoMese.string(from: data))"
    }

    // MARK: - Aiuti

    private static func giorni(_ n: Int) -> String { n == 1 ? "un giorno" : "\(n) giorni" }

    private static func nomePosizione(_ p: Posizione) -> String { p.nome.isEmpty ? "Proposta" : p.nome }

    private static func spiegazioneProposta(_ s: PropostaInSospeso) -> String {
        switch s.motivo {
        case .senzaRisposta:
            return "Presentata \(giorni(s.giorni)) fa e ancora senza risposta: l'analisi è fatta, manca solo una telefonata."
        case .daRiprendere:
            if s.fonte == .ripresa {
                return s.giorni <= 0 ? "Rimandata dal cliente: la ripresa è fissata per oggi."
                                     : "Rimandata dal cliente: andava ripresa \(giorni(s.giorni)) fa."
            }
            return "Rimandata dal cliente e ferma da \(giorni(s.giorni)): conviene riprenderla."
        }
    }

    /// I canali delle posizioni aperte (in essere e proposte) di ogni cliente, nell'ordine di `Canale.allCases`.
    private static func canaliDeiClienti(_ posizioni: [Posizione]) -> [String: [Canale]] {
        var insiemi: [String: Set<Canale>] = [:]
        for p in posizioni where p.stato != .chiusa {
            insiemi[p.clienteId, default: []].insert(p.canale)
        }
        return insiemi.mapValues { s in Canale.allCases.filter { s.contains($0) } }
    }
}

/// Prove del nastro «Da fare» (chiamate da `ProvaCalcoli.esegui()`): gruppi, ordine, segni e riprese.
enum ProvaDaFare {
    static func esegui(_ verifica: VerificaCalcoli) {
        // Martedì 3 novembre 2026
        let oggi = AiutiProva.data(2026, 11, 3)
        func cliente(_ id: String) -> Cliente {
            Cliente(id: id, nome: id.capitalized, iniziali: String(id.prefix(2)).uppercased(), tinta: .blu, tema: "", email: "",
                    telefono: "", preferito: false, nota: "", creatoIl: AiutiProva.data(2020, 1, 1))
        }
        let anna = cliente("anna")
        let bruno = cliente("bruno")
        let estraneo = cliente("estraneo")

        // I gruppi delle date
        verifica.vero("Da fare: ieri è oggi", MotoreDaFare.gruppo(AiutiProva.data(2026, 11, 2), oggi: oggi) == .oggi)
        verifica.vero("Da fare: oggi è oggi", MotoreDaFare.gruppo(oggi, oggi: oggi) == .oggi)
        verifica.vero("Da fare: senza data è più avanti", MotoreDaFare.gruppo(nil, oggi: oggi) == .avanti)
        verifica.vero("Da fare: a fine anno è più avanti", MotoreDaFare.gruppo(AiutiProva.data(2026, 12, 20), oggi: oggi) == .avanti)
        verifica.vero("Da fare: il 25 novembre è questo mese", MotoreDaFare.gruppo(AiutiProva.data(2026, 11, 25), oggi: oggi) == .mese)
        verifica.vero("Da fare: domani è questa settimana", MotoreDaFare.gruppo(AiutiProva.data(2026, 11, 4), oggi: oggi) == .settimana)
        verifica.vero("Da fare: «Domani»", MotoreDaFare.testoQuando(AiutiProva.data(2026, 11, 4), gruppo: .settimana, oggi: oggi) == "Domani")

        // Una proposta ferma con la sua ripresa, un riesame mai fatto, due attività, un'attività di un cliente non visibile,
        // un'attenzione già segnata come fatta e una no
        var proposta = AiutiProva.posizione("PIP", .previdenza, 0) { p in
            p.clienteId = "anna"
            p.stato = .proposta
            p.esito = .presentata
            p.canale = .alleanza
        }
        var seguito = SeguitoProposta()
        seguito.attivitaId = "ripresa"
        proposta.seguito = seguito
        let ferma = PropostaInSospeso(posizione: proposta, cliente: anna, motivo: .senzaRisposta, dal: AiutiProva.data(2026, 9, 1),
                                      fonte: .presentazione, giorni: 63, urgente: true)
        let riesame = RiesameDovuto(cliente: bruno, ultimoContatto: nil, dovutoDal: nil)
        let attivita = [
            Attivita(id: "ripresa", clienteId: "anna", titolo: "Riprendere la proposta", scadenza: oggi, priorita: .alta, completata: false),
            Attivita(id: "t1", clienteId: "bruno", titolo: "Mandare il KID", scadenza: AiutiProva.data(2026, 11, 20), priorita: .normale, completata: false),
            Attivita(id: "t2", clienteId: "anna", titolo: "Chiamare il notaio", scadenza: AiutiProva.data(2026, 10, 30), priorita: .normale, completata: false),
            Attivita(id: "t3", clienteId: "estraneo", titolo: "Non visibile", scadenza: oggi, priorita: .normale, completata: false),
            Attivita(id: "fatto-attenzione-anna·0·Beneficiari", clienteId: "anna", titolo: "Fatto", scadenza: oggi, priorita: .normale, completata: true),
        ]
        let attenzioni = [
            Attenzione(cliente: anna, tipo: .beneficiari, titolo: "Beneficiari", dettaglio: "Da indicare."),
            Attenzione(cliente: bruno, tipo: .costi, titolo: "Costi alti", dettaglio: "Oltre il 2%."),
        ]
        let x = MotoreDaFare.Ingressi(clienti: [anna, bruno], posizioni: [proposta], attivita: attivita, proposte: [ferma],
                                      riesami: [riesame], conformita: [], occasioni: [], attenzioni: attenzioni, oggi: oggi)
        let n = MotoreDaFare.calcola(x)
        _ = estraneo
        // Oggi: la proposta, il riesame mai fatto, l'attività scaduta; questo mese: il KID; più avanti: un'attenzione
        verifica("Da fare: voci in tutto", Double(n.totale), 5)
        verifica("Da fare: voci di oggi", Double(n.diOggi), 3)
        verifica.vero("Da fare: prima la proposta, poi il riesame",
                      n.blocchi.first?.voci.map(\.tipo) == [.proposta, .riesame, .attivita])
        verifica.vero("Da fare: la ripresa della proposta non si ripete", !n.voci.contains { $0.id == "attivita-ripresa" })
        verifica.vero("Da fare: il cliente non visibile non c'è", !n.voci.contains { $0.cliente.id == "estraneo" })
        verifica.vero("Da fare: l'attenzione segnata non torna", !n.voci.contains { $0.id == "attenzione-anna·0·Beneficiari" })
        verifica.vero("Da fare: la proposta porta l'esito e l'anello", n.voci.first.map { $0.fatto == .esitoProposta(posizioneId: proposta.id) && $0.anello == .proposte } ?? false)
        verifica.vero("Da fare: la proposta ha il suo canale", n.voci.first?.canali == [.alleanza])
        verifica.vero("Da fare: il riesame mai fatto", n.voci.first { $0.tipo == .riesame }?.quando == "Mai fatto")
        verifica.vero("Da fare: l'attività scaduta lo dice", n.voci.first { $0.id == "attivita-t2" }?.quando == "Scaduta da 4 giorni")
        verifica.vero("Da fare: i gruppi in ordine", n.blocchi.map(\.gruppo) == [.oggi, .mese, .avanti])
        verifica.vero("Da fare: le attenzioni in fondo", n.blocchi.last?.voci.first?.tipo == .attenzione)
        verifica.vero("Da fare: il segno ha il prefisso", n.voci.last?.idSegno == "fatto-" + (n.voci.last?.id ?? ""))

        // Il massimo per gruppo: le altre si contano
        let tante = (0..<12).map { i in
            Attivita(id: "m\(i)", clienteId: "bruno", titolo: "Attività \(i)", scadenza: oggi, priorita: .normale, completata: false)
        }
        let molte = MotoreDaFare.calcola(MotoreDaFare.Ingressi(clienti: [bruno], posizioni: [], attivita: tante, proposte: [],
                                                               riesami: [], conformita: [], occasioni: [], attenzioni: [], oggi: oggi))
        verifica("Da fare: schede mostrate per gruppo", Double(molte.blocchi.first?.voci.count ?? 0), Double(MotoreDaFare.massimoPerGruppo))
        verifica("Da fare: nascoste contate", Double(molte.blocchi.first?.nascoste ?? 0), Double(12 - MotoreDaFare.massimoPerGruppo))

        // Vuoto
        let vuoto = MotoreDaFare.calcola(MotoreDaFare.Ingressi(clienti: [], posizioni: [], attivita: [], proposte: [], riesami: [],
                                                               conformita: [], occasioni: [], attenzioni: [], oggi: oggi))
        verifica.vero("Da fare: senza clienti è vuoto", vuoto.vuoto && vuoto.totale == 0)
    }
}
