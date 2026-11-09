import Foundation

// I traguardi festeggiati (versione «Luce», giro 5, Design/template-luce-specifica.md §5.4): Prisma si accorge da solo
// dei momenti da festeggiare con un cliente, SOLO dai dati che ci sono (decisione 87):
// - obiettivo raggiunto: un obiettivo con `Obiettivo.raggiuntoIl` nella finestra (lo scrive lo stato la prima volta che
//   lo trova raggiunto: `daSegnareRaggiunti`); cifra = l'importo, didascalia = da quanto tempo c'era l'obiettivo;
// - anniversario del rapporto: 1, 5, 10, 15 e 20 anni (Impostazioni) dal primo appuntamento concluso, altrimenti dalla
//   data d'inserimento in Prisma con l'avviso; nessuna cifra (lo storico del patrimonio di un anno non c'è sempre);
// - mutuo estinto: una posizione dei debiti che arriva alla scadenza nella finestra;
// - studi di un figlio: un figlio o una figlia che compie 18 o 19 anni, con un obiettivo della famiglia avviato o
//   raggiunto;
// - la rendita «partita» non ha un dato proprio (decisione 87): fino ad allora resta un obiettivo raggiunto.
// Finestra: gli ultimi 7 giorni (decisione 87). Niente cifre né idee inventate: l'idea per il regalo esce solo da una
// frase delle note del dossier che parla di un regalo, con la nota da cui viene. La frase del biglietto è quella fissa
// di Prisma (nessuna cifra, nessuna proposta: un traguardo non è commerciale).
// Motore puro: riceve i dati, `oggi` e il calendario.

/// Il tipo di un traguardo. `rendita` è previsto dalla specifica ma non nasce ancora (manca lo stato «in erogazione»).
enum TipoTraguardo: String, Codable, CaseIterable, Identifiable {
    case obiettivoRaggiunto, anniversario, mutuoEstinto, studiFigli, rendita

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .obiettivoRaggiunto: return "Obiettivo raggiunto"
        case .anniversario: return "Anniversario"
        case .mutuoEstinto: return "Mutuo estinto"
        case .studiFigli: return "Studi di un figlio"
        case .rendita: return "Rendita partita"
        }
    }

    /// L'ordine d'importanza per «il momento dell'anno» (più basso = più importante).
    var importanza: Int {
        switch self {
        case .obiettivoRaggiunto, .rendita: return 0
        case .studiFigli: return 1
        case .mutuoEstinto: return 2
        case .anniversario: return 3
        }
    }
}

/// Un'idea per il regalo: una frase delle note del dossier e da dove viene.
struct IdeaRegalo: Hashable {
    let testo: String
    /// «dalla nota «Viaggi»», «dalle note del cliente», «dalle note dell'obiettivo «…»».
    let fonte: String
}

/// Un traguardo di un cliente. Non si salva: si ricalcola dai dati (festeggiato e scartato sì, in Impostazioni).
struct Traguardo: Identifiable, Hashable {
    /// Stabile: "\(tipo)-\(clienteId)-\(riferimento)".
    let id: String
    let tipo: TipoTraguardo
    let clienteId: String
    /// Il giorno del traguardo.
    let data: Date
    /// «Ha raggiunto «Rendita integrativa»» (l'iniziale maiuscola: nella testata va minuscola dopo il nome).
    let titolo: String
    /// Il titolo detto con il nome, per la storia della settimana: «Sofia ha raggiunto «Rendita integrativa».».
    let fraseBreve: String
    /// «Obiettivo raggiunto ieri», «Il primo incontro fu il 5 novembre 2025».
    let perche: String
    /// «Ce l’hai fatta, Sofia.»
    let saluto: String
    let cifra: Double?
    let didascaliaCifra: String?
    /// La frase fissa di Prisma (nessuna cifra, nessuna proposta).
    let frase: String
    /// Solo da una frase delle note del dossier; nil se le note non dicono niente.
    let ideaRegalo: IdeaRegalo?
    /// La capsula del tempo sigillata per l'obiettivo raggiunto («Luce» giro 15, `MotoreCapsule.perObiettivo`); nil per
    /// gli altri tipi. La tile del pannello compare solo se la capsula è pronta (`StatoShell.capsulaProntaDelTraguardo`).
    let capsulaId: String?
    /// Festeggiato (telefonata messa o segnato a mano): quando.
    let festeggiatoIl: Date?
    /// Per la «Frase del momento dell'anno»: la frase con il giorno, nel modello fisso di Prisma.
    let fraseMomento: String
    /// Peso per scegliere il momento dell'anno (importo dell'obiettivo, 0 per gli altri).
    let peso: Double
}

enum MotoreTraguardi {
    /// I giorni della finestra dei traguardi (decisione 87).
    static let finestraGiorni = 7
    /// Le età in cui un figlio va verso l'università.
    static let etaStudi = [18, 19]
    /// Le parole che fanno di una frase delle note un'idea per il regalo.
    static let paroleRegalo = ["regal"]

    // MARK: - Calcolo

    /// I traguardi dei clienti dei dati con il giorno negli ultimi `finestraGiorni` giorni (oggi compreso), senza i tipi
    /// spenti e gli scartati; i festeggiati ci sono, con `festeggiatoIl`. Dal più recente; a parità, per nome.
    static func calcola(dati: DatiPrisma, oggi: Date, finestraGiorni: Int = finestraGiorni,
                        cal: Calendar = .current) -> [Traguardo] {
        let fine = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: oggi)) ?? oggi
        let inizio = cal.date(byAdding: .day, value: -max(0, finestraGiorni), to: cal.startOfDay(for: oggi)) ?? oggi
        return calcola(dati: dati, da: inizio, a: fine, oggi: oggi, cal: cal)
    }

    /// I traguardi con il giorno in [`da`, `a`) (per «Il tuo anno»: dal 1° gennaio a domani).
    static func calcola(dati: DatiPrisma, da: Date, a: Date, oggi: Date, cal: Calendar = .current) -> [Traguardo] {
        let regole = dati.impostazioni.traguardi
        let spenti = Set(regole.tipiSpenti)
        let scartati = Set(regole.scartati)
        var elenco: [Traguardo] = []
        let clienti = Dictionary(dati.clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let posizioni = Dictionary(grouping: dati.posizioni, by: \.clienteId)
        let obiettivi = Dictionary(grouping: dati.obiettivi, by: \.clienteId)
        let appuntamenti = Dictionary(grouping: dati.appuntamenti, by: \.clienteId)
        let note = Dictionary(grouping: dati.note, by: \.clienteId)
        func dentro(_ d: Date) -> Bool { d >= da && d < a }

        for c in dati.clienti {
            let idea = ideaRegalo(cliente: c, note: note[c.id] ?? [], obiettivi: obiettivi[c.id] ?? [])
            func aggiungi(_ tipo: TipoTraguardo, riferimento: String, data: Date, titolo: String, fraseBreve: String,
                          perche: String, saluto: String, cifra: Double?, didascalia: String?, frase: String,
                          momento: String, peso: Double = 0, capsula: String? = nil) {
                let id = "\(tipo.rawValue)-\(c.id)-\(riferimento)"
                guard !spenti.contains(tipo), !scartati.contains(id) else { return }
                elenco.append(Traguardo(id: id, tipo: tipo, clienteId: c.id, data: data, titolo: titolo, fraseBreve: fraseBreve,
                                        perche: perche, saluto: saluto, cifra: cifra, didascaliaCifra: didascalia, frase: frase,
                                        ideaRegalo: idea, capsulaId: capsula, festeggiatoIl: regole.festeggiati[id],
                                        fraseMomento: momento, peso: peso))
            }
            let nome = TestiTraguardi.primoNome(c.nome)

            // Obiettivi raggiunti
            for o in obiettivi[c.id] ?? [] {
                guard let quando = o.raggiuntoIl, dentro(quando), o.importo > 0 else { continue }
                let titolo = TestiTraguardi.titoloObiettivo(o.titolo)
                aggiungi(.obiettivoRaggiunto, riferimento: o.id, data: quando, titolo: titolo,
                         fraseBreve: "\(nome) ha raggiunto «\(o.titolo)».",
                         perche: "Obiettivo raggiunto " + TestiTraguardi.quando(quando, oggi: oggi, cal: cal),
                         saluto: "Ce l’hai fatta, \(nome).", cifra: o.importo,
                         didascalia: TestiTraguardi.durata(da: o.creatoIl, a: quando, cal: cal).map { "messi al sicuro " + $0 },
                         frase: TestiTraguardi.fraseObiettivo,
                         momento: "\(TestiTraguardi.ilGiorno(quando)) \(nome) ha raggiunto «\(o.titolo)».", peso: o.importo,
                         // «Luce» giro 15: la capsula del tempo sigillata per questo obiettivo (la tile «Apri la capsula»)
                         capsula: MotoreCapsule.perObiettivo(dati.capsule, obiettivoId: o.id)?.id)
            }

            // Anniversari del rapporto
            let conclusi = (appuntamenti[c.id] ?? []).filter { $0.stato == .concluso && $0.inizio <= oggi }
            let primo = conclusi.map(\.inizio).min()
            let inizioRapporto = primo ?? c.creatoIl
            for anni in regole.anniversari {
                guard let giorno = cal.date(byAdding: .year, value: anni, to: inizioRapporto), dentro(giorno) else { continue }
                let quanti = TestiTraguardi.anni(anni)
                let perche = primo != nil
                    ? "Il primo incontro fu il " + Formati.dataEstesa.string(from: inizioRapporto)
                    : "In Prisma dal " + Formati.dataEstesa.string(from: inizioRapporto) + " (dalla data d’inserimento)"
                aggiungi(.anniversario, riferimento: "\(anni)anni", data: giorno, titolo: TestiTraguardi.maiuscola(quanti) + " insieme",
                         fraseBreve: "\(nome): \(quanti) insieme.", perche: perche,
                         saluto: TestiTraguardi.maiuscola(quanti) + " insieme, \(nome).", cifra: nil, didascalia: nil,
                         frase: TestiTraguardi.fraseAnniversario(anni),
                         momento: "\(TestiTraguardi.ilGiorno(giorno)) \(nome) ha festeggiato \(quanti) con te.")
            }

            // Mutuo estinto: una posizione dei debiti arrivata alla scadenza
            for p in posizioni[c.id] ?? [] where p.area == .debiti {
                guard let scadenza = p.scadenza, dentro(scadenza), scadenza <= oggi else { continue }
                aggiungi(.mutuoEstinto, riferimento: p.id, data: scadenza, titolo: "Ha finito di pagare «\(p.nome)»",
                         fraseBreve: "\(nome) ha finito di pagare «\(p.nome)».",
                         perche: "Ultima rata " + TestiTraguardi.quando(scadenza, oggi: oggi, cal: cal),
                         saluto: "Fatto, \(nome).", cifra: nil, didascalia: nil, frase: TestiTraguardi.fraseMutuo,
                         momento: "\(TestiTraguardi.ilGiorno(scadenza)) \(nome) ha finito di pagare «\(p.nome)».")
            }

            // Studi di un figlio: 18 o 19 anni con un obiettivo della famiglia avviato o raggiunto
            let famiglia = (obiettivi[c.id] ?? []).filter { o in
                o.area == .famiglia && (o.raggiuntoIl != nil || o.accantonato > 0 || !o.posizioniCollegate.isEmpty)
            }
            if !famiglia.isEmpty {
                for f in c.famiglia where f.relazione == .figlio || f.relazione == .figlia {
                    guard let nascita = f.dataNascita else { continue }
                    for eta in etaStudi {
                        guard let compleanno = cal.date(byAdding: .year, value: eta, to: nascita), dentro(compleanno),
                              compleanno <= oggi else { continue }
                        let figlio = TestiTraguardi.primoNome(f.nome)
                        let pronto = famiglia.contains { $0.raggiuntoIl != nil }
                        let piano = pronto ? "il piano per gli studi è pronto" : "il piano per gli studi è avviato"
                        aggiungi(.studiFigli, riferimento: "\(f.id)-\(eta)", data: compleanno,
                                 titolo: "\(figlio) compie \(eta) anni: \(piano)",
                                 fraseBreve: "\(figlio) compie \(eta) anni: \(piano).",
                                 perche: "Compleanno di \(figlio) " + TestiTraguardi.quando(compleanno, oggi: oggi, cal: cal),
                                 saluto: "Auguri a \(figlio), \(nome).", cifra: nil, didascalia: nil,
                                 frase: TestiTraguardi.fraseStudi(figlio: figlio, pronto: pronto),
                                 momento: "\(TestiTraguardi.ilGiorno(compleanno)) \(figlio) ha compiuto \(eta) anni con \(piano).")
                    }
                }
            }
        }
        return elenco.sorted { x, y in
            if x.data != y.data { return x.data > y.data }
            let nx = clienti[x.clienteId]?.nome ?? "", ny = clienti[y.clienteId]?.nome ?? ""
            if nx != ny { return nx.localizedCompare(ny) == .orderedAscending }
            return x.id < y.id
        }
    }

    /// Gli obiettivi raggiunti che non hanno ancora la data (importo > 0, accantonato ≥ importo): lo stato scrive
    /// `raggiuntoIl` a oggi la prima volta che li trova (il motore non scrive).
    static func daSegnareRaggiunti(dati: DatiPrisma) -> [String] {
        dati.obiettivi.compactMap { o in
            guard o.raggiuntoIl == nil, o.importo > 0 else { return nil }
            return AvanzamentoObiettivo(o, posizioni: dati.posizioni).accantonato >= o.importo ? o.id : nil
        }
    }

    /// «Il momento dell'anno»: il traguardo più importante (obiettivo prima, poi studi, mutuo, anniversario; a parità
    /// l'importo più alto, poi il più recente).
    static func momento(_ traguardi: [Traguardo]) -> Traguardo? {
        traguardi.min { x, y in
            if x.tipo.importanza != y.tipo.importanza { return x.tipo.importanza < y.tipo.importanza }
            if x.peso != y.peso { return x.peso > y.peso }
            return x.data > y.data
        }
    }

    // MARK: - Idea per il regalo

    /// La prima frase delle note del cliente che parla di un regalo: prima le note intitolate al regalo, poi le altre
    /// note, le note della scheda e quelle degli obiettivi. nil se nessuna ne parla (mai un'idea inventata).
    static func ideaRegalo(cliente: Cliente, note: [Nota], obiettivi: [Obiettivo]) -> IdeaRegalo? {
        let ordinate = note.sorted { a, b in
            let ra = contieneRegalo(a.titolo), rb = contieneRegalo(b.titolo)
            if ra != rb { return ra }
            return a.aggiornataIl > b.aggiornataIl
        }
        for n in ordinate {
            if contieneRegalo(n.titolo), let prima = frasi(n.testo).first {
                return IdeaRegalo(testo: prima, fonte: "dalla nota «\(n.titoloMostrato)»")
            }
            if let f = frasi(n.testo).first(where: contieneRegalo) {
                return IdeaRegalo(testo: f, fonte: "dalla nota «\(n.titoloMostrato)»")
            }
        }
        if let f = frasi(cliente.nota).first(where: contieneRegalo) {
            return IdeaRegalo(testo: f, fonte: "dalle note del cliente")
        }
        for o in obiettivi {
            if let f = frasi(o.note).first(where: contieneRegalo) {
                return IdeaRegalo(testo: f, fonte: "dalle note dell’obiettivo «\(o.titolo)»")
            }
        }
        return nil
    }

    static func contieneRegalo(_ s: String) -> Bool {
        let t = s.lowercased()
        return paroleRegalo.contains { t.contains($0) }
    }

    /// Le frasi di un testo (divise al punto, al punto esclamativo o interrogativo e agli a capo), senza spazi in più.
    static func frasi(_ testo: String) -> [String] {
        var elenco: [String] = []
        var corrente = ""
        for ch in testo {
            if ch == "\n" {
                elenco.append(corrente)
                corrente = ""
                continue
            }
            corrente.append(ch)
            if ch == "." || ch == "!" || ch == "?" {
                elenco.append(corrente)
                corrente = ""
            }
        }
        elenco.append(corrente)
        return elenco.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    // MARK: - Messaggi

    /// Le occasioni del gruppo «Da festeggiare» di Messaggi: una per traguardo; quelli festeggiati prima di oggi
    /// escono, quelli festeggiati oggi restano con la spunta fino a domani. Non commerciali.
    static func occasioni(_ traguardi: [Traguardo], oggi: Date, cal: Calendar = .current) -> [OccasioneMessaggio] {
        let inizio = cal.startOfDay(for: oggi)
        return traguardi.compactMap { t in
            if let f = t.festeggiatoIl, f < inizio { return nil }
            var cifre = [CifraMessaggio(.traguardo, t.titolo)]
            if let v = t.cifra { cifre.append(CifraMessaggio(.importo, FormatoCifra.euro.testo(v))) }
            return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .traguardo, riferimento: t.id), clienteId: t.clienteId,
                                      canale: nil, gruppo: .festeggiare, titolo: t.titolo, perche: t.perche,
                                      oggetto: t.titolo, cifre: cifre, priorita: .alta, data: t.data,
                                      preparatoIl: t.festeggiatoIl)
        }
    }
}

/// I testi fissi dei traguardi (nessuna cifra, nessuna proposta: decisione 87).
enum TestiTraguardi {
    static let fraseObiettivo = "L’obiettivo che avevamo progettato insieme è raggiunto. È il frutto della tua costanza: "
        + "grazie per la fiducia di questi anni."
    static let fraseMutuo = "Il mutuo è finito: un traguardo che merita di essere festeggiato. Grazie per avermi voluto "
        + "accanto in questo percorso."
    static let notaColonna = "Prisma si accorge da solo dei traguardi: obiettivi raggiunti, anniversari, un mutuo estinto, "
        + "un figlio all’università con il piano pronto."
    static let scrittaDaPrisma = "Frase scritta da Prisma: Vera la riscriverà con un prossimo aggiornamento."
    static let senzaIdea = "Nessuna idea dalle note"
    static let titoloMomento = "Il momento, già pronto"
    static let biglietto = "Il biglietto animato"
    static let bigliettoNota = "si potrà mandare con un prossimo aggiornamento"
    static let telefonata = "Una telefonata"
    static let regalo = "L’idea per un regalo"
    static let datiDiProva = "dati di prova"
    static let festeggiato = "✓ Festeggiato oggi"

    static func fraseAnniversario(_ anni: Int) -> String {
        let quando = anni == 1 ? "Un anno fa" : "\(anni) anni fa"
        return "\(quando) ci siamo conosciuti: grazie per la fiducia che mi dai e per il percorso che stiamo facendo insieme."
    }

    static func fraseStudi(figlio: String, pronto: Bool) -> String {
        pronto
            ? "\(figlio) arriva all’università e il piano che avevamo preparato per i suoi studi è pronto. Grazie per la fiducia."
            : "\(figlio) arriva all’università e il piano per i suoi studi è avviato. Grazie per la fiducia."
    }

    /// «domani alle 10:30», «giovedì 12 novembre alle 9:00».
    static func quandoTelefonata(_ d: Date, oggi: Date, cal: Calendar = .current) -> String {
        let g = cal.dateComponents([.day], from: cal.startOfDay(for: oggi), to: cal.startOfDay(for: d)).day ?? 0
        let ora = Formati.ora.string(from: d)
        if g == 1 { return "domani alle \(ora)" }
        return Formati.giornoSettimana.string(from: d).lowercased() + " " + Formati.giornoMese.string(from: d) + " alle \(ora)"
    }

    /// «Ha raggiunto «Rendita integrativa»».
    static func titoloObiettivo(_ titolo: String) -> String { "Ha raggiunto «\(titolo)»" }

    /// «un anno», «5 anni».
    static func anni(_ n: Int) -> String { n == 1 ? "un anno" : "\(n) anni" }

    /// «oggi», «ieri», «il 3 novembre».
    static func quando(_ d: Date, oggi: Date, cal: Calendar) -> String {
        let g = cal.dateComponents([.day], from: cal.startOfDay(for: d), to: cal.startOfDay(for: oggi)).day ?? 0
        switch g {
        case 0: return "oggi"
        case 1: return "ieri"
        default: return ilGiorno(d).lowercased()
        }
    }

    /// «Il 14 marzo», «L’8 marzo», «L’11 aprile».
    static func ilGiorno(_ d: Date) -> String {
        let t = Formati.giornoMese.string(from: d)
        return t.hasPrefix("8 ") || t.hasPrefix("11 ") ? "L’" + t : "Il " + t
    }

    /// Da quanto c'era l'obiettivo: «in 5 anni e mezzo», «in un anno», «in 8 mesi»; nil sotto il mese.
    static func durata(da: Date, a: Date, cal: Calendar) -> String? {
        let mesi = cal.dateComponents([.month], from: da, to: a).month ?? 0
        guard mesi >= 1 else { return nil }
        if mesi < 12 { return mesi == 1 ? "in un mese" : "in \(mesi) mesi" }
        var anni = mesi / 12
        let resto = mesi % 12
        if resto >= 9 { anni += 1 }
        let base = anni == 1 ? "un anno" : "\(anni) anni"
        if (3...8).contains(resto) { return "in \(base) e mezzo" }
        return "in \(base)"
    }

    static func primoNome(_ nome: String) -> String {
        String(nome.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").first ?? "")
    }

    static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    /// «Sofia Romano: ha raggiunto «Rendita integrativa»» (il titolo con l'iniziale minuscola dopo il nome).
    static func testata(nome: String, titolo: String) -> String {
        "\(nome): " + titolo.prefix(1).lowercased() + titolo.dropFirst()
    }
}
