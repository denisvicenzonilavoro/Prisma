import Foundation

/// Lo stato del ripasso di una domanda, ricavato dallo storico.
struct StatoRipassoOCF: Equatable {
    let domandaId: String
    /// Indice in `MotoreOCF.intervalli` (0 = torna dopo 1 giorno … 4 = dopo 30 giorni).
    let passo: Int
    /// Giorni dell'intervallo in corso.
    var giorni: Int { MotoreOCF.intervalli[passo] }
    /// L'ultima risposta.
    let ultima: Date
    let ultimaGiusta: Bool
    /// Il giorno (inizio del giorno) in cui la domanda torna nel ripasso.
    let prossima: Date
    /// Risposte date in tutto.
    let risposte: Int
}

/// La preparazione di una materia.
struct PreparazioneMateriaOCF: Identifiable, Equatable {
    let materia: MateriaOCF
    /// Quota (0-100) delle domande giuste all'ultima risposta, tra quelle risposte; nil sotto `MotoreOCF.minimoRisposte`.
    let percentuale: Double?
    /// Domande della materia con almeno una risposta.
    let risposte: Int
    /// Di quelle, giuste all'ultima risposta.
    let giuste: Int
    /// Domande della materia nell'archivio.
    let domande: Int

    var id: String { materia.id }
}

/// La preparazione complessiva.
struct PreparazioneOCF: Equatable {
    /// Media semplice delle materie con una percentuale; nil se nessuna ce l'ha.
    let complessiva: Double?
    /// Nell'ordine dell'archivio.
    let materie: [PreparazioneMateriaOCF]
    /// Domande con il ripasso scaduto oggi o prima.
    let daRipassareOggi: Int
    /// Domande mai viste.
    let nuoveDisponibili: Int
    /// La materia più bassa tra quelle con una percentuale.
    let puntoDebole: MateriaOCF?
    /// Giorni di calendario da oggi all'esame (0 = oggi, negativo = passato); nil senza data.
    let giorniAllEsame: Int?
    let domandeDisponibili: Int
}

/// Il «caso vero»: una posizione o un documento dell'archivio che fa da esempio per una domanda.
struct CasoVeroOCF: Equatable {
    let caso: CasoOCF
    /// Il testo del pulsante, con il nome vero («Guarda la polizza rivalutabile di Giulia»).
    let testo: String
    let clienteId: String
    let posizioneId: String?
    let documentoId: String?
}

/// L'allenamento OCF (funzioni pure, nessuna dipendenza dalla UI). Regole:
/// - ripasso a intervalli tipo Leitner, per giorni di calendario: 1, 3, 7, 14, 30 giorni. Una risposta sbagliata
///   porta la domanda al passo 1 giorno; una giusta alla data del ripasso (o dopo) la fa salire di un passo, fino a
///   30 giorni, dove resta; una giusta prima della data non cambia niente. Una domanda nuova giusta al primo colpo
///   parte dal passo dei 3 giorni;
/// - percentuale di una materia: quota delle domande giuste all'ultima risposta, tra quelle a cui si è risposto,
///   con almeno `minimoRisposte` domande; complessiva = media semplice delle materie con un dato;
/// - domande di oggi: prima quelle del ripasso scaduto (dalla più in ritardo), poi le nuove, a rotazione dalla
///   materia più debole, fino a `nuovePerGiorno` meno le nuove già viste oggi;
/// - caso vero: dal caso della domanda o, senza, da quello della materia; prima il cliente attivo, poi la posizione
///   di valore più alto (i KID: il più recente).
enum MotoreOCF {
    static let intervalli = [1, 3, 7, 14, 30]
    /// Domande risposte che servono per dare la percentuale di una materia (da confermare con l'utente).
    static let minimoRisposte = 5
    /// Soglie delle fasce (come il template: verde da 70, arancio da 55).
    static let sogliaVerde = 70.0
    static let sogliaArancio = 55.0

    // MARK: Ripasso

    /// Lo stato del ripasso di una domanda (nil se non ha risposte).
    static func ripasso(_ domandaId: String, risposte: [RispostaOCF], cal: Calendar) -> StatoRipassoOCF? {
        let sue = risposte.filter { $0.domandaId == domandaId }
        return ripasso(ordinate: sue.sorted { $0.data < $1.data }, domandaId: domandaId, cal: cal)
    }

    /// Lo stato del ripasso di tutte le domande con almeno una risposta.
    static func ripassi(_ risposte: [RispostaOCF], cal: Calendar) -> [String: StatoRipassoOCF] {
        var perDomanda: [String: [RispostaOCF]] = [:]
        for r in risposte { perDomanda[r.domandaId, default: []].append(r) }
        var esito: [String: StatoRipassoOCF] = [:]
        for (id, elenco) in perDomanda {
            if let s = ripasso(ordinate: elenco.sorted { $0.data < $1.data }, domandaId: id, cal: cal) { esito[id] = s }
        }
        return esito
    }

    private static func ripasso(ordinate: [RispostaOCF], domandaId: String, cal: Calendar) -> StatoRipassoOCF? {
        guard let ultima = ordinate.last else { return nil }
        var passo: Int?
        var prossima: Date?
        for r in ordinate {
            let giorno = cal.startOfDay(for: r.data)
            let nuovo: Int
            if !r.giusta {
                nuovo = 0
            } else if let p = passo {
                // Giusta prima della data del ripasso: niente cambia
                if let d = prossima, giorno < d { continue }
                nuovo = min(p + 1, intervalli.count - 1)
            } else {
                nuovo = 1
            }
            passo = nuovo
            prossima = cal.date(byAdding: .day, value: intervalli[nuovo], to: giorno) ?? giorno
        }
        guard let p = passo, let d = prossima else { return nil }
        return StatoRipassoOCF(domandaId: domandaId, passo: p, ultima: ultima.data, ultimaGiusta: ultima.giusta,
                               prossima: d, risposte: ordinate.count)
    }

    /// Le domande con il ripasso scaduto oggi o prima, dalla più in ritardo (a pari data, per id).
    static func daRipassare(_ a: ArchivioOCF, oggi: Date, cal: Calendar) -> [DomandaOCF] {
        let stati = ripassi(a.risposte, cal: cal)
        let giorno = cal.startOfDay(for: oggi)
        return a.domande.compactMap { d -> (DomandaOCF, Date)? in
            guard let s = stati[d.id], s.prossima <= giorno else { return nil }
            return (d, s.prossima)
        }
        .sorted { $0.1 == $1.1 ? $0.0.id < $1.0.id : $0.1 < $1.1 }
        .map { $0.0 }
    }

    /// Le domande di oggi: prima il ripasso, poi le nuove (`nuove` nil = `nuovePerGiorno` dell'archivio, meno le
    /// nuove già viste oggi), a rotazione dalla materia più debole (senza percentuale = prima di tutte).
    static func domandeDiOggi(_ a: ArchivioOCF, oggi: Date, cal: Calendar, nuove: Int? = nil) -> [DomandaOCF] {
        let ripasso = daRipassare(a, oggi: oggi, cal: cal)
        let giorno = cal.startOfDay(for: oggi)
        var primaRisposta: [String: Date] = [:]
        for r in a.risposte where primaRisposta[r.domandaId].map({ r.data < $0 }) ?? true { primaRisposta[r.domandaId] = r.data }
        let giaOggi = primaRisposta.values.filter { cal.startOfDay(for: $0) == giorno }.count
        let quante = max(0, (nuove ?? a.nuovePerGiorno) - (nuove == nil ? giaOggi : 0))
        guard quante > 0 else { return ripasso }

        // Le nuove per materia, nell'ordine dell'archivio; materie dalla più debole
        let prep = preparazione(a, oggi: oggi, cal: cal)
        let ordineMaterie = prep.materie.enumerated().sorted { x, y in
            let px = x.element.percentuale ?? -1, py = y.element.percentuale ?? -1
            return px == py ? x.offset < y.offset : px < py
        }.map { $0.element.materia.id }
        var code: [String: [DomandaOCF]] = [:]
        for d in a.domande where primaRisposta[d.id] == nil { code[d.materia, default: []].append(d) }
        // Le domande di una materia non elencata vanno in coda
        let altre = code.keys.filter { !ordineMaterie.contains($0) }.sorted()
        let giro = ordineMaterie + altre
        var scelte: [DomandaOCF] = []
        var indice = 0
        while scelte.count < quante, giro.contains(where: { !(code[$0] ?? []).isEmpty }) {
            let m = giro[indice % giro.count]
            if var coda = code[m], !coda.isEmpty {
                scelte.append(coda.removeFirst())
                code[m] = coda
            }
            indice += 1
        }
        return ripasso + scelte
    }

    // MARK: Preparazione

    static func preparazione(_ a: ArchivioOCF, oggi: Date, cal: Calendar) -> PreparazioneOCF {
        // L'ultima risposta di ogni domanda
        var ultima: [String: RispostaOCF] = [:]
        for r in a.risposte where ultima[r.domandaId].map({ r.data >= $0.data }) ?? true { ultima[r.domandaId] = r }
        let materie = a.materie.map { m -> PreparazioneMateriaOCF in
            let sue = a.domande.filter { $0.materia == m.id }
            let risposte = sue.compactMap { ultima[$0.id] }
            let giuste = risposte.filter(\.giusta).count
            let percentuale = risposte.count >= minimoRisposte ? Double(giuste) / Double(risposte.count) * 100 : nil
            return PreparazioneMateriaOCF(materia: m, percentuale: percentuale, risposte: risposte.count, giuste: giuste, domande: sue.count)
        }
        let conDato = materie.compactMap { m in m.percentuale.map { (m.materia, $0) } }
        let complessiva = conDato.isEmpty ? nil : conDato.reduce(0) { $0 + $1.1 } / Double(conDato.count)
        let debole = conDato.min { $0.1 < $1.1 }?.0
        let giorni = a.dataEsame.flatMap { cal.dateComponents([.day], from: cal.startOfDay(for: oggi), to: cal.startOfDay(for: $0)).day }
        let nuove = a.domande.filter { ultima[$0.id] == nil }.count
        return PreparazioneOCF(complessiva: complessiva, materie: materie, daRipassareOggi: daRipassare(a, oggi: oggi, cal: cal).count,
                               nuoveDisponibili: nuove, puntoDebole: debole, giorniAllEsame: giorni, domandeDisponibili: a.domande.count)
    }

    /// La fascia di una percentuale: verde da 70, arancio da 55, rossa sotto; nil = nessuna.
    enum Fascia: Equatable { case verde, arancio, rossa, nessuna }

    static func fascia(_ p: Double?) -> Fascia {
        guard let p else { return .nessuna }
        return p >= sogliaVerde ? .verde : (p >= sogliaArancio ? .arancio : .rossa)
    }

    // MARK: Caso vero

    /// Il caso che vale per una domanda: il suo o, senza, quello della materia.
    static func caso(di d: DomandaOCF, in a: ArchivioOCF) -> CasoOCF? {
        d.caso ?? a.materia(d.materia)?.caso
    }

    /// Il caso vero di una domanda nell'archivio di Prisma (nil = nessun esempio: il pulsante non compare).
    static func casoVero(per d: DomandaOCF, dati: DatiPrisma, clienteAttivo: String?) -> CasoVeroOCF? {
        guard let c = caso(di: d, in: dati.ocf) else { return nil }
        return casoVero(c, clienti: dati.clienti, posizioni: dati.posizioni, documenti: dati.documenti, clienteAttivo: clienteAttivo)
    }

    /// Regole del caso vero, una per caso, solo su posizioni in essere (non scadute) e documenti dei clienti.
    static func casoVero(_ caso: CasoOCF, clienti: [Cliente], posizioni: [Posizione], documenti: [Documento],
                         clienteAttivo: String?) -> CasoVeroOCF? {
        let conosciuti = Set(clienti.map(\.id))
        func nome(_ id: String) -> String {
            let n = clienti.first { $0.id == id }?.nome ?? ""
            return n.split(separator: " ").first.map(String.init) ?? n
        }
        if caso == .kid {
            let kid = documenti.filter { $0.tipo == .kid && conosciuti.contains($0.clienteId) }
                .sorted { x, y in
                    let ax = x.clienteId == clienteAttivo, ay = y.clienteId == clienteAttivo
                    return ax != ay ? ax : (x.importatoIl == y.importatoIl ? x.id < y.id : x.importatoIl > y.importatoIl)
                }.first
            return kid.map { CasoVeroOCF(caso: caso, testo: TestiOCF.casoVero(caso, nome: nome($0.clienteId)),
                                         clienteId: $0.clienteId, posizioneId: nil, documentoId: $0.id) }
        }
        let danni: Set<RischioCoperto> = [.invalidita, .salute, .ltc, .infortuni, .casa, .rc]
        let regola: (Posizione) -> Bool
        switch caso {
        case .gestioneSeparata: regola = { $0.gestioneSeparata }
        case .multiramo: regola = { $0.multiramo }
        case .fondo: regola = { $0.regime == .fondo && $0.area != .liquidita }
        case .previdenzaComplementare: regola = { $0.regime == .previdenza }
        case .casoMorte: regola = { $0.area == .protezione && $0.rischio == .vita }
        case .protezioneDanni: regola = { $0.area == .protezione && $0.rischio.map { danni.contains($0) } == true }
        case .kid: regola = { _ in false }
        }
        let scelta = posizioni.filter { $0.stato == .inEssere && !$0.scaduta && conosciuti.contains($0.clienteId) && regola($0) }
            .sorted { x, y in
                let ax = x.clienteId == clienteAttivo, ay = y.clienteId == clienteAttivo
                if ax != ay { return ax }
                let vx = x.area == .protezione ? (x.capitaleAssicurato ?? 0) : x.valore
                let vy = y.area == .protezione ? (y.capitaleAssicurato ?? 0) : y.valore
                return vx == vy ? x.id < y.id : vx > vy
            }.first
        return scelta.map { CasoVeroOCF(caso: caso, testo: TestiOCF.casoVero(caso, nome: nome($0.clienteId)),
                                        clienteId: $0.clienteId, posizioneId: $0.id, documentoId: nil) }
    }
}
