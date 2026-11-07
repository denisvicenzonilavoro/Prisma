import Foundation

// «La tua settimana, il tuo anno» (versione «Luce», giro 5, Design/template-luce-specifica.md §5.2): le pagine delle
// due storie a tutto palco, calcolate dai motori che Prisma ha già, senza cifre inventate. Regole (§5.2.5 punto 5.2):
// - una pagina c'è solo se il suo dato c'è e non è zero (niente «0 incontri»); la prima e l'ultima ci sono sempre;
// - «settimana» = da lunedì a domenica della settimana di `oggi` (anche a cavallo di mese e d'anno);
// - incontri: gli appuntamenti della settimana con un cliente, telefonate escluse (decisione 2: proposta); «il più
//   importante» è la firma, poi la presentazione di una proposta, poi il primo;
// - in arrivo: le provvigioni Alleanza stimate dalle aliquote dell'utente (MotoreStudio.eventi) e le parcelle emesse
//   con la scadenza nella settimana, giorno per giorno (lun-ven sempre, sabato e domenica solo se hanno qualcosa: la
//   somma dei giorni è il totale); senza aliquote la pagina conta solo le parcelle e lo dice;
// - da chiamare: la mossa del giorno (MotoreMossaDelGiorno);
// - traguardo: il primo traguardo della settimana non ancora festeggiato (MotoreTraguardi);
// - anno = dal 1° gennaio a oggi: famiglie protette (una per cliente, con posizioni di protezione entrate nell'anno) e
//   capitale assicurato se scritto; patrimonio seguito e variazione da inizio anno (MotoreAndamentoPortafoglio; nil
//   al primo anno: «Da quest'anno in Prisma»); clienti nuovi dalla data d'inserimento (il passaparola non c'è ancora:
//   nessuna riga); i chilometri non ci sono ancora (giro 9): nessuna pagina e NESSUN paragone senza la tabella
//   approvata dall'utente (decisione 72); il momento dell'anno è il traguardo più importante, con la frase fissa.
// Motore puro: riceve i dati, `oggi` e il calendario.

/// Un giorno della pagina «In arrivo».
struct GiornoInArrivo: Equatable {
    let giorno: Date
    let importo: Double
}

/// Una pagina di una storia.
enum PaginaStoria: Equatable {
    case saluto(nome: String, periodo: DateInterval)
    /// Fino a 6 avatar; `principale` è la frase già composta («Il più importante: giovedì alle 16:00, la firma di Giulia.»).
    case incontri(numero: Int, clienti: [String], principale: String?)
    /// `parziale`: mancano le aliquote, la cifra conta solo le parcelle.
    case inArrivo(totale: Double, perGiorno: [GiornoInArrivo], didascalia: String, parziale: Bool)
    case daChiamare(clienteId: String, motivo: String)
    case traguardo(clienteId: String, titolo: String, traguardoId: String)
    /// `tranquilla`: la settimana non ha niente (resta solo con la prima pagina).
    case finaleSettimana(tranquilla: Bool)
    case annoTitolo(anno: Int, consulente: String)
    /// `capitale`: la somma dei capitali assicurati scritti (nil se nessuno è scritto).
    case protette(famiglie: Int, capitale: Double?)
    case patrimonio(valore: Double, serie: [Double], variazione: Double?)
    case nuoviClienti(numero: Int, daPassaparola: Int?)
    /// Arriva con Studio › Spese (giro 9). Il paragone solo da una tabella approvata dall'utente (decisione 72).
    case chilometri(km: Double, paragone: String?, stima: Bool)
    case momento(data: Date, frase: String, clienteId: String)
    case grazie

    /// Un nome stabile per la pagina (istantanee, prove, accessibilità).
    var nome: String {
        switch self {
        case .saluto: return "saluto"
        case .incontri: return "incontri"
        case .inArrivo: return "inArrivo"
        case .daChiamare: return "daChiamare"
        case .traguardo: return "traguardo"
        case .finaleSettimana: return "finaleSettimana"
        case .annoTitolo: return "annoTitolo"
        case .protette: return "protette"
        case .patrimonio: return "patrimonio"
        case .nuoviClienti: return "nuoviClienti"
        case .chilometri: return "chilometri"
        case .momento: return "momento"
        case .grazie: return "grazie"
        }
    }
}

enum MotoreStorie {
    /// Al più tanti avatar nella pagina degli incontri.
    static let avatarMassimi = 6

    // MARK: - La settimana

    /// Il lunedì (inizio del giorno) della settimana di `oggi`.
    static func lunedi(di oggi: Date, cal: Calendar = .current) -> Date {
        let inizio = cal.startOfDay(for: oggi)
        let giorno = cal.component(.weekday, from: inizio)   // 1 = domenica … 7 = sabato
        let indietro = (giorno + 5) % 7
        return cal.date(byAdding: .day, value: -indietro, to: inizio) ?? inizio
    }

    /// La settimana di `oggi`, da lunedì a lunedì dopo (la fine esclusa).
    static func settimanaDi(_ oggi: Date, cal: Calendar = .current) -> DateInterval {
        let l = lunedi(di: oggi, cal: cal)
        let fine = cal.date(byAdding: .day, value: 7, to: l) ?? l
        return DateInterval(start: l, end: fine)
    }

    /// Le pagine della storia della settimana.
    static func settimana(dati: DatiPrisma, oggi: Date, cal: Calendar = .current) -> [PaginaStoria] {
        let periodo = settimanaDi(oggi, cal: cal)
        var pagine: [PaginaStoria] = [.saluto(nome: TestiTraguardi.primoNome(dati.impostazioni.nomeUtente), periodo: periodo)]
        let clienti = Dictionary(dati.clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        // Incontri
        let incontri = dati.appuntamenti
            .filter { a in a.inizio >= periodo.start && a.inizio < periodo.end && a.tipo != .telefonata && clienti[a.clienteId] != nil }
            .sorted { $0.inizio < $1.inizio }
        if !incontri.isEmpty {
            var ids: [String] = []
            for a in incontri where !ids.contains(a.clienteId) { ids.append(a.clienteId) }
            let principale = incontri.first { $0.tipo == .firma } ?? incontri.first { $0.tipo == .proposta } ?? incontri.first
            let frase = principale.flatMap { a in clienti[a.clienteId].map { TestiStorie.principale(a, cliente: $0, numero: incontri.count) } }
            pagine.append(.incontri(numero: incontri.count, clienti: Array(ids.prefix(avatarMassimi)), principale: frase))
        }

        // In arrivo
        if let p = inArrivo(dati: dati, periodo: periodo, clienti: clienti, cal: cal) { pagine.append(p) }

        // Da chiamare: la mossa del giorno
        let mossa = MotoreMossaDelGiorno.calcola(clienti: dati.clienti, posizioni: dati.posizioni, appuntamenti: dati.appuntamenti,
                                                 attivita: dati.attivita, incontri: dati.incontri, prodotti: dati.prodotti,
                                                 analisi: dati.analisi, regoleOccasioni: dati.impostazioni.occasioni,
                                                 sogliaSeguito: dati.impostazioni.giorniSeguitoProposte, oggi: oggi).mossa
        if let m = mossa { pagine.append(.daChiamare(clienteId: m.cliente.id, motivo: m.motivo)) }

        // Un traguardo da festeggiare (non ancora festeggiato)
        if let t = MotoreTraguardi.calcola(dati: dati, oggi: oggi, cal: cal).first(where: { $0.festeggiatoIl == nil }) {
            pagine.append(.traguardo(clienteId: t.clienteId, titolo: t.fraseBreve, traguardoId: t.id))
        }

        pagine.append(.finaleSettimana(tranquilla: pagine.count == 1))
        return pagine
    }

    /// La pagina «In arrivo»: provvigioni stimate (con le aliquote) e parcelle emesse che scadono nella settimana.
    static func inArrivo(dati: DatiPrisma, periodo: DateInterval, clienti: [String: Cliente], cal: Calendar) -> PaginaStoria? {
        let studio = dati.impostazioni.studio
        var perGiorno: [Date: Double] = [:]
        var tipi: Set<MotoreStudio.TipoProvvigione> = []
        var senzaAliquota = false
        for p in dati.posizioni where clienti[p.clienteId] != nil {
            for e in MotoreStudio.eventi(p, studio: studio, da: periodo.start, a: periodo.end, cal: cal) {
                guard let importo = e.importo else {
                    senzaAliquota = true
                    continue
                }
                guard importo > 0 else { continue }
                perGiorno[cal.startOfDay(for: e.data), default: 0] += importo
                tipi.insert(e.tipo)
            }
        }
        var parcelle = 0
        for r in MotoreParcelle.ricaviConsulenza(dati.parcelle) where !r.incassata && clienti[r.clienteId] != nil {
            guard r.data >= periodo.start, r.data < periodo.end, r.importo > 0 else { continue }
            perGiorno[cal.startOfDay(for: r.data), default: 0] += r.importo
            parcelle += 1
        }
        let totale = perGiorno.values.reduce(0, +)
        guard totale > 0 else { return nil }
        var giorni: [GiornoInArrivo] = []
        for k in 0..<7 {
            guard let g = cal.date(byAdding: .day, value: k, to: periodo.start) else { continue }
            let importo = perGiorno[g] ?? 0
            // Lunedì-venerdì sempre; sabato e domenica solo se hanno qualcosa
            if k < 5 || importo > 0 { giorni.append(GiornoInArrivo(giorno: g, importo: importo)) }
        }
        let parziale = senzaAliquota
        return .inArrivo(totale: totale, perGiorno: giorni,
                         didascalia: TestiStorie.didascaliaInArrivo(tipi: tipi, parcelle: parcelle, parziale: parziale),
                         parziale: parziale)
    }

    // MARK: - L'anno

    /// Le pagine della storia dell'anno (dal 1° gennaio di `anno` a `oggi`).
    static func anno(dati: DatiPrisma, anno: Int, oggi: Date, cal: Calendar = .current) -> [PaginaStoria] {
        let inizio = cal.date(from: DateComponents(year: anno, month: 1, day: 1)) ?? cal.startOfDay(for: oggi)
        let fine = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: oggi)) ?? oggi
        var pagine: [PaginaStoria] = [.annoTitolo(anno: anno, consulente: consulente(dati.impostazioni))]
        let ids = Set(dati.clienti.map(\.id))

        // Famiglie protette: una per cliente, con posizioni di protezione entrate nell'anno
        let protezioni = dati.posizioni.filter { p in
            guard ids.contains(p.clienteId), p.area == .protezione else { return false }
            if p.stato == .inEssere, let d = p.decorrenza, d >= inizio, d < fine { return true }
            if p.esito == .accettata, let d = p.seguito?.esitoIl, d >= inizio, d < fine { return true }
            return false
        }
        let famiglie = Set(protezioni.map(\.clienteId)).count
        if famiglie > 0 {
            let capitali = protezioni.compactMap(\.capitaleAssicurato).filter { $0 > 0 }
            pagine.append(.protette(famiglie: famiglie, capitale: capitali.isEmpty ? nil : capitali.reduce(0, +)))
        }

        // Patrimonio seguito
        let andamento = MotoreAndamentoPortafoglio.calcola(dati.posizioni.filter { ids.contains($0.clienteId) }, oggi: oggi)
        if andamento.inEssere > 0 {
            // Il valore al 1° gennaio dalle rilevazioni delle posizioni (0 = niente prima di quest'anno: primo anno)
            let attive = dati.posizioni.filter { ids.contains($0.clienteId) && $0.stato == .inEssere && !$0.area.passivo }
            let alInizio = attive.reduce(0) { $0 + MotoreAndamentoPortafoglio.valore($1, al: inizio) }
            let variazione: Double? = alInizio > 0 ? (andamento.inEssere - alInizio) / alInizio : nil
            var serie = zip(andamento.giorniStoria, andamento.storia).filter { $0.0 >= inizio }.map(\.1)
            if serie.count < 2 { serie = [alInizio, andamento.inEssere] }
            pagine.append(.patrimonio(valore: andamento.inEssere, serie: serie, variazione: variazione))
        }

        // Clienti nuovi (dalla data d'inserimento in Prisma)
        let nuovi = dati.clienti.filter { $0.creatoIl >= inizio && $0.creatoIl < fine }.count
        if nuovi > 0 { pagine.append(.nuoviClienti(numero: nuovi, daPassaparola: nil)) }

        // Il momento dell'anno
        if let t = MotoreTraguardi.momento(MotoreTraguardi.calcola(dati: dati, da: inizio, a: fine, oggi: oggi, cal: cal)) {
            pagine.append(.momento(data: t.data, frase: t.fraseMomento, clienteId: t.clienteId))
        }

        pagine.append(.grazie)
        return pagine
    }

    /// Il nome del consulente per la prima pagina dell'anno: nome e cognome dei dati per le fatture, altrimenti il nome
    /// del profilo.
    static func consulente(_ i: Impostazioni) -> String {
        let f = i.studio.fatturazione
        let completo = [f.nome, f.cognome].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            .joined(separator: " ")
        return completo.isEmpty ? i.nomeUtente.trimmingCharacters(in: .whitespacesAndNewlines) : completo
    }
}
