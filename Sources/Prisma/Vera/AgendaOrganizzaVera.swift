import Foundation

// «L'agenda che si organizza» (Vera/BRIEF.md, funzione 4; template «// 4 · L'AGENDA CHE SI ORGANIZZA»): Vera trova gli
// orari giusti, attacca gli appuntamenti a quelli già fissati in studio, sposta gli impegni in blocco e prepara la bozza
// con i due orari da proporre al cliente.
// Qwen serve solo a capire la frase (JSON con lo schema fisso, l'output non valido si scarta); la ricerca la fa il
// codice. Le decisioni dell'utente, fisse:
// - mai prima delle 9:30 per gli appuntamenti con i clienti (`primaOraClienti`);
// - prima gli orari attaccati (subito prima o subito dopo) a un altro incontro in studio, così si viene una volta sola;
// - solo dentro gli orari di lavoro (Impostazioni › Orari di lavoro: `OrariLavoro`, con margine, giorni e festivi;
//   giorni lavorativi e festività da `MotorePianificazione`).
// Niente si esegue qui: il motore prepara le azioni per la scheda «Conferma» (agenda_sposta_impegno,
// agenda_nuovo_impegno, messaggi_prepara), con gli stessi argomenti che usa RegistroStrumenti.
// Solo Foundation e i modelli: nessuna dipendenza da StatoShell né da SwiftUI; `oggi` arriva sempre da fuori.

/// Dove si tiene un incontro.
enum ModoIncontro: String, Codable, CaseIterable {
    case studio, videochiamata, telefonata, altro

    /// Il luogo da scrivere nell'appuntamento.
    var luogo: String {
        switch self {
        case .studio: return "In studio"
        case .videochiamata: return "Videochiamata"
        case .telefonata: return "Telefonata"
        case .altro: return ""
        }
    }

    /// «in studio», «in videochiamata», «per telefono» (vuoto per gli altri).
    var dove: String {
        switch self {
        case .studio: return "in studio"
        case .videochiamata: return "in videochiamata"
        case .telefonata: return "per telefono"
        case .altro: return ""
        }
    }
}

/// Cosa ha chiesto il consulente, capito dalle regole o da Qwen.
struct RichiestaOrari: Codable, Equatable {
    enum Intento: String, Codable {
        /// «Trovami un'ora per il riesame di Federico entro giovedì».
        case cerca
        /// «Libera giovedì, sposta tutto a venerdì».
        case spostaBlocco
    }

    var intento: Intento
    /// Il cliente risolto (nil se non nominato o non trovato).
    var clienteId: String?
    /// Il nome come l'ha detto il consulente, quando non si trova tra i clienti («Federico»).
    var nomeDetto: String?
    /// I clienti tra cui la frase non sceglie («il riesame di bianchi» con due Bianchi, nessuno dei due aperto): si chiede quale.
    var ambigui: [String]? = nil
    /// Da quale giorno cercare (nil = da domani).
    var dal: Date?
    /// Entro quale giorno (compreso; nil = le prossime due settimane).
    var entro: Date?
    var durataMinuti: Int
    /// «Attaccata a un altro incontro in studio».
    var attaccato: Bool
    var modo: ModoIncontro
    var tipo: TipoAppuntamento
    /// Spostamento in blocco: il giorno da liberare e quello di arrivo.
    var daGiorno: Date?
    var aGiorno: Date?
    /// L'impegno già in agenda che questa ricerca sostituisce (il riesame di venerdì che il cliente non può fare):
    /// non occupa tempo nella ricerca e la scelta lo sposta invece di crearne uno nuovo.
    var daSpostare: String?
    var conQwen: Bool

    init(intento: Intento, clienteId: String? = nil, nomeDetto: String? = nil, dal: Date? = nil, entro: Date? = nil,
         durataMinuti: Int = 60, attaccato: Bool = false, modo: ModoIncontro = .studio, tipo: TipoAppuntamento = .altro,
         daGiorno: Date? = nil, aGiorno: Date? = nil, daSpostare: String? = nil, conQwen: Bool = false) {
        self.intento = intento
        self.clienteId = clienteId
        self.nomeDetto = nomeDetto
        self.dal = dal
        self.entro = entro
        self.durataMinuti = durataMinuti
        self.attaccato = attaccato
        self.modo = modo
        self.tipo = tipo
        self.daGiorno = daGiorno
        self.aGiorno = aGiorno
        self.daSpostare = daSpostare
        self.conQwen = conQwen
    }
}

/// Un orario proposto da Vera.
struct OrarioProposto: Codable, Equatable, Identifiable {
    enum Vicinanza: String, Codable { case prima, dopo }

    var id: String
    var inizio: Date
    var fine: Date
    /// L'incontro in studio a cui è attaccato (nil = un orario libero qualunque).
    var vicino: String?
    var vicinanza: Vicinanza?
    /// «subito dopo Laura», «prima della firma di Giulia» (vuoto se non è attaccato).
    var etichetta: String

    var attaccato: Bool { vicino != nil }
}

/// Il risultato di una ricerca: fino a due orari senza sovrapposizioni, più una nota quando serve.
struct RicercaOrari: Codable, Equatable {
    var richiesta: RichiestaOrari
    var proposte: [OrarioProposto]
    /// «Non c'è un orario attaccato…», «Entro giovedì non c'è un'ora libera…».
    var nota: String?
}

/// Un impegno dello spostamento in blocco.
struct MossaBlocco: Codable, Equatable, Identifiable {
    var id: String { appuntamentoId }
    var appuntamentoId: String
    var clienteId: String
    var titolo: String
    var luogo: String
    var canale: Canale?
    var durataMinuti: Int
    var prima: Date
    var inizio: Date
    /// true = la stessa ora del giorno di arrivo; false = il primo orario libero.
    var stessaOra: Bool
}

/// Lo spostamento in blocco: cosa va dove, e cosa non ci sta.
struct SpostamentoBlocco: Codable, Equatable {
    var da: Date
    var a: Date
    var mosse: [MossaBlocco]
    /// I titoli degli impegni che nel giorno di arrivo non ci stanno (restano dove sono).
    var restano: [String]
    var nota: String?
}

enum AgendaOrganizzaVera {
    /// Mai prima delle 9:30 per gli appuntamenti con i clienti (decisione dell'utente).
    static let primaOraClienti = 9 * 60 + 30
    /// Gli inizi si propongono ogni mezz'ora, come in Agenda e in «Pianifica».
    static var passo: Int { MotorePianificazione.passoMinuti }
    /// Senza «entro» si cerca nelle prossime due settimane.
    static let giorniSenzaScadenza = 14
    /// Si propone dal giorno dopo: il tempo di avvisare il cliente.
    static let preavvisoGiorni = 1
    /// Quanti orari si propongono al cliente.
    static let quanti = 2

    // MARK: - Luogo e tempi

    /// Dove si tiene un appuntamento: dal luogo scritto, altrimenti dal tipo (un primo incontro, un'analisi, una
    /// proposta, una firma o un riesame senza luogo si fanno in studio).
    static func modo(_ a: Appuntamento) -> ModoIncontro {
        let l = a.luogo.lowercased()
        if l.contains("studio") || l.contains("ufficio") { return .studio }
        if l.contains("video") || l.contains("online") || l.contains("zoom") || l.contains("meet") || l.contains("teams") { return .videochiamata }
        if l.contains("telefon") { return .telefonata }
        if a.tipo == .telefonata { return .telefonata }
        if a.tipo == .nonDisponibile { return .altro }
        let inStudio: [TipoAppuntamento] = [.primoIncontro, .analisi, .proposta, .firma, .revisione]
        if l.trimmingCharacters(in: .whitespaces).isEmpty, inStudio.contains(a.tipo) { return .studio }
        return .altro
    }

    /// I minuti dalla mezzanotte.
    static func minuti(_ d: Date, cal: Calendar) -> Int {
        let c = cal.dateComponents([.hour, .minute], from: d)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// Gli inizi possibili di un giorno negli orari di lavoro, sulla griglia di mezz'ora; per i clienti dalle 9:30.
    static func inizi(giorno: Date, durata: Int, orari: OrariLavoro, conCliente: Bool, cal: Calendar) -> [Date] {
        var elenco: [Date] = []
        let p = max(1, passo)
        for f in orari.fasce {
            var m = conCliente ? max(f.inizio, primaOraClienti) : f.inizio
            m = ((m + p - 1) / p) * p
            while m + durata <= f.fine {
                elenco.append(MotorePianificazione.orario(giorno, minuti: m, cal: cal))
                m += p
            }
        }
        return elenco
    }

    /// L'orario sta tutto dentro una fascia di lavoro (per i clienti, dalle 9:30).
    static func dentroOrari(_ inizio: Date, durata: Int, orari: OrariLavoro, conCliente: Bool, cal: Calendar) -> Bool {
        let m = minuti(inizio, cal: cal)
        return orari.fasce.contains { f in
            let i = conCliente ? max(f.inizio, primaOraClienti) : f.inizio
            return m >= i && m + durata <= f.fine
        }
    }

    private typealias Intervallo = (inizio: Date, fine: Date)

    /// Gli appuntamenti come intervalli occupati, allargati del margine.
    private static func occupati(_ elenco: [Appuntamento], margine: Int) -> [Intervallo] {
        let m = TimeInterval(max(0, margine) * 60)
        return elenco.map { (inizio: $0.inizio.addingTimeInterval(-m), fine: $0.fine.addingTimeInterval(m)) }
    }

    /// Confronti stretti: due intervalli che si toccano soltanto non si sovrappongono.
    private static func libero(_ inizio: Date, _ fine: Date, _ occupati: [Intervallo]) -> Bool {
        !occupati.contains { $0.inizio < fine && inizio < $0.fine }
    }

    /// «giovedì 5 novembre» → «Giovedì 5 novembre».
    private static func maiuscola(_ s: String) -> String { s.prefix(1).uppercased() + String(s.dropFirst()) }

    private static func primoNome(_ nome: String) -> String {
        nome.split(separator: " ").first.map(String.init) ?? nome
    }

    // MARK: - Ricerca di due orari

    /// Fino a `quanti` orari liberi senza sovrapposizioni, negli orari di lavoro, dal giorno `dal` (o da domani) fino
    /// a `entro` compreso: prima quelli attaccati a un altro incontro in studio (per gli incontri in studio), poi gli
    /// altri; i due orari, se si può, in giorni diversi.
    static func cerca(_ r: RichiestaOrari, appuntamenti: [Appuntamento], clienti: [Cliente], orari: OrariLavoro, oggi: Date,
                      cal: Calendar = MotorePianificazione.calendario, quanti: Int = AgendaOrganizzaVera.quanti) -> RicercaOrari {
        // L'impegno da sostituire si sposta con la sua durata (agenda_sposta_impegno non la cambia): si cerca lo spazio per quella
        let durata = max(10, min(600, durataDaSostituire(r.daSpostare, appuntamenti: appuntamenti) ?? r.durataMinuti))
        let oggiGiorno = cal.startOfDay(for: oggi)
        let domani = cal.date(byAdding: .day, value: preavvisoGiorni, to: oggiGiorno) ?? oggiGiorno
        let primo = r.dal.map { max(cal.startOfDay(for: $0), oggiGiorno) } ?? domani
        let ultimo = r.entro.map { cal.startOfDay(for: $0) }
            ?? (cal.date(byAdding: .day, value: giorniSenzaScadenza - 1, to: primo) ?? primo)
        guard ultimo >= primo else {
            let quando = r.entro.map { DateItaliane.descrivi($0, conOra: false, oggi: oggi, cal: cal) } ?? "la data che mi hai detto"
            return RicercaOrari(richiesta: r, proposte: [], nota: "Entro \(quando) non resta un giorno utile per proporre un orario: dimmi un'altra data.")
        }
        let altri = appuntamenti.filter { $0.id != r.daSpostare }
        let tutti = occupati(altri, margine: orari.margineMinuti)
        let inStudio = altri.filter { $0.stato == .pianificato && modo($0) == .studio }
        let preferisciAttaccati = r.modo == .studio
        let tolleranza = max(0, orari.margineMinuti) + max(1, passo) - 1
        // I riesami già in agenda per giorno: oltre il limite di Impostazioni il giorno non va bene per un altro riesame
        var riesami: [Date: Int] = [:]
        if r.tipo == .revisione, orari.riesamiAlGiorno > 0 {
            for a in altri where a.tipo == .revisione { riesami[cal.startOfDay(for: a.inizio), default: 0] += 1 }
        }

        var candidati: [OrarioProposto] = []
        var giorno = primo
        while giorno <= ultimo {
            defer { giorno = cal.date(byAdding: .day, value: 1, to: giorno).map { cal.startOfDay(for: $0) } ?? ultimo.addingTimeInterval(86_400) }
            guard MotorePianificazione.lavorativo(giorno, orari: orari, cal: cal) else { continue }
            if r.tipo == .revisione, orari.riesamiAlGiorno > 0, (riesami[giorno] ?? 0) >= orari.riesamiAlGiorno { continue }
            let delGiorno = inStudio.filter { cal.isDate($0.inizio, inSameDayAs: giorno) }
            for t in inizi(giorno: giorno, durata: durata, orari: orari, conCliente: true, cal: cal) where t >= oggi {
                let fine = t.addingTimeInterval(TimeInterval(durata * 60))
                guard libero(t, fine, tutti) else { continue }
                var proposta = OrarioProposto(id: "orario-\(Int(t.timeIntervalSinceReferenceDate))", inizio: t, fine: fine,
                                              vicino: nil, vicinanza: nil, etichetta: "")
                if preferisciAttaccati {
                    // Il vicino più stretto: subito dopo (dalla sua fine all'inizio proposto) o subito prima
                    var migliore: (scarto: Int, a: Appuntamento, v: OrarioProposto.Vicinanza)?
                    for a in delGiorno {
                        let dopo = Int(t.timeIntervalSince(a.fine) / 60)
                        if (0...tolleranza).contains(dopo), migliore.map({ dopo < $0.scarto }) ?? true {
                            migliore = (scarto: dopo, a: a, v: OrarioProposto.Vicinanza.dopo)
                        }
                        let prima = Int(a.inizio.timeIntervalSince(fine) / 60)
                        if (0...tolleranza).contains(prima), migliore.map({ prima < $0.scarto }) ?? true {
                            migliore = (scarto: prima, a: a, v: OrarioProposto.Vicinanza.prima)
                        }
                    }
                    if let m = migliore {
                        proposta.vicino = m.a.id
                        proposta.vicinanza = m.v
                        proposta.etichetta = etichetta(m.v, m.a, clienti: clienti)
                    }
                }
                candidati.append(proposta)
            }
        }

        // La scelta: prima gli attaccati, poi un giorno diverso da quello già scelto, poi il più presto
        var scelti: [OrarioProposto] = []
        func punteggio(_ c: OrarioProposto) -> Int {
            (preferisciAttaccati && !c.attaccato ? 2 : 0) + (scelti.contains { cal.isDate($0.inizio, inSameDayAs: c.inizio) } ? 1 : 0)
        }
        while scelti.count < max(0, quanti) {
            let restanti = candidati.filter { c in !scelti.contains { s in s.inizio < c.fine && c.inizio < s.fine } }
            guard let migliore = restanti.min(by: { (punteggio($0), $0.inizio) < (punteggio($1), $1.inizio) }) else { break }
            scelti.append(migliore)
        }
        scelti.sort { $0.inizio < $1.inizio }

        var nota: String?
        if scelti.isEmpty {
            let quando = r.entro.map { "Entro " + DateItaliane.descrivi($0, conOra: false, oggi: oggi, cal: cal) } ?? "Nelle prossime due settimane"
            nota = "\(quando) non c'è un orario libero di \(durata) minuti negli orari di lavoro (\(orari.descrizione))."
        } else if r.attaccato && preferisciAttaccati && !scelti.contains(where: { $0.attaccato }) {
            nota = "Non c'è un orario attaccato a un altro incontro in studio: ti propongo i primi liberi."
        }
        return RicercaOrari(richiesta: r, proposte: scelti, nota: nota)
    }

    static func cerca(_ r: RichiestaOrari, contesto x: ContestoStrumenti) -> RicercaOrari {
        cerca(r, appuntamenti: x.appuntamenti, clienti: x.clienti, orari: x.impostazioni.orari, oggi: x.oggi, cal: x.calendario)
    }

    /// «subito dopo Laura», «prima della firma di Giulia», «subito dopo «Formazione»».
    static func etichetta(_ v: OrarioProposto.Vicinanza, _ a: Appuntamento, clienti: [Cliente]) -> String {
        guard let nome = clienti.first(where: { $0.id == a.clienteId }).map({ primoNome($0.nome) }) else {
            return v == .dopo ? "subito dopo «\(a.titolo)»" : "prima di «\(a.titolo)»"
        }
        switch (v, a.tipo) {
        case (.dopo, .firma): return "subito dopo la firma di \(nome)"
        case (.dopo, .revisione): return "subito dopo il riesame di \(nome)"
        case (.dopo, _): return "subito dopo \(nome)"
        case (.prima, .firma): return "prima della firma di \(nome)"
        case (.prima, .revisione): return "prima del riesame di \(nome)"
        case (.prima, _): return "prima dell'incontro con \(nome)"
        }
    }

    /// La risposta di Vera in chat: «Ti propongo due orari, così in studio si viene una volta sola: martedì 3 novembre
    /// alle 11:00, subito dopo Laura, oppure giovedì 5 novembre alle 14:30, prima della firma di Giulia.»
    static func risposta(_ r: RicercaOrari, oggi: Date, cal: Calendar = MotorePianificazione.calendario) -> String {
        guard !r.proposte.isEmpty else { return r.nota ?? "Non ho trovato orari liberi." }
        let pezzi = r.proposte.map { p -> String in
            let quando = DateItaliane.descrivi(p.inizio, conOra: true, oggi: oggi, cal: cal)
            return p.etichetta.isEmpty ? quando : "\(quando), \(p.etichetta)"
        }
        let tuttiAttaccati = r.proposte.allSatisfy { $0.attaccato }
        let perche = tuttiAttaccati && r.richiesta.modo == .studio ? ", così in studio si viene una volta sola" : ""
        var testo = r.proposte.count == 1
            ? "Ti propongo un orario\(perche): \(pezzi[0])."
            : "Ti propongo \(SchedaConfermaVera.numero(r.proposte.count)) orari\(perche): \(pezzi.dropLast().joined(separator: ", ")), oppure \(pezzi[pezzi.count - 1])."
        if let n = r.nota { testo += " " + n }
        return testo
    }

    // MARK: - Bozza per il cliente e scelta

    /// «il nostro riesame», «la firma»…
    private static func oggetto(_ t: TipoAppuntamento) -> String {
        switch t {
        case .revisione: return "il nostro riesame"
        case .firma: return "la firma"
        case .proposta: return "la presentazione della proposta"
        case .analisi: return "l'analisi delle sue posizioni"
        case .telefonata: return "la nostra telefonata"
        case .primoIncontro: return "il nostro primo incontro"
        default: return "il nostro incontro"
        }
    }

    /// «Buongiorno Federico, per il nostro riesame le propongo due orari in studio: martedì 3 novembre alle 11:00
    /// oppure giovedì 5 novembre alle 15:00. Quale preferisce? Un caro saluto, Denis»
    static func testoOrari(_ proposte: [OrarioProposto], cliente c: Cliente, tipo: TipoAppuntamento, modo: ModoIncontro, firma: String?) -> String {
        let nome = primoNome(c.nome)
        let dove = modo.dove.isEmpty ? "" : " \(modo.dove)"
        let orari = proposte.map { "\(Formati.dataLunga.string(from: $0.inizio)) alle \(Formati.ora.string(from: $0.inizio))" }
        let saluto = firma.map { " Un caro saluto, \($0)" } ?? " Un caro saluto."
        let corpo: String
        switch orari.count {
        case 0: corpo = "per \(oggetto(tipo)) le scrivo appena ho un orario libero."
        case 1: corpo = "per \(oggetto(tipo)) le propongo \(orari[0])\(dove). Le va bene?"
        default:
            corpo = "per \(oggetto(tipo)) le propongo \(SchedaConfermaVera.numero(orari.count)) orari\(dove): \(orari.dropLast().joined(separator: ", ")) oppure \(orari[orari.count - 1]). Quale preferisce?"
        }
        return "Buongiorno \(nome), \(corpo)\(saluto)"
    }

    /// La bozza con gli orari proposti (messaggi_prepara, scopo «orari»): resta una bozza da aprire in Mail o in
    /// Messaggi, la spedisce il consulente. nil senza orari.
    static func azioneBozza(_ r: RicercaOrari, cliente c: Cliente, impostazioni: Impostazioni, canale: Canale? = nil) -> AzioneConferma? {
        guard !r.proposte.isEmpty else { return nil }
        let firma = ModelliMessaggi.firma(canale, tono: .formale, impostazioni: impostazioni)
        let testo = testoOrari(r.proposte, cliente: c, tipo: r.richiesta.tipo, modo: r.richiesta.modo, firma: firma)
        let via: CanaleMessaggio = c.telefono.filter(\.isNumber).count >= 6 ? .messaggi : .mail
        var argomenti = ["cliente": c.id, "scopo": "orari", "testo": testo, "canale": via.rawValue,
                         "orari": r.proposte.map { RegistroStrumenti.isoData($0.inizio) }.joined(separator: ",")]
        if let id = r.richiesta.daSpostare { argomenti["appuntamento"] = id }
        return AzioneConferma(strumento: RegistroStrumenti.messaggiPrepara, app: .messaggi,
                              titolo: r.proposte.count == 1 ? "Preparo l'orario per \(c.nome)" : "Preparo i \(SchedaConfermaVera.numero(r.proposte.count)) orari per \(c.nome)",
                              dettaglio: RegistroStrumenti.dettaglioMessaggio(testo, canale: via), argomenti: argomenti)
    }

    /// La durata dell'impegno da sostituire (nil se non c'è o non si trova).
    static func durataDaSostituire(_ id: String?, appuntamenti: [Appuntamento]) -> Int? {
        guard let id else { return nil }
        return appuntamenti.first { $0.id == id }?.durataMinuti
    }

    /// Il cliente ha scelto un orario: sposta l'impegno che la ricerca sostituisce, oppure ne fissa uno nuovo.
    /// Il controllo delle sovrapposizioni usa il margine degli orari di lavoro e, per lo spostamento, la durata
    /// dell'impegno che si sposta (resta la sua, non quella della proposta).
    static func azioneScelta(_ p: OrarioProposto, richiesta r: RichiestaOrari, cliente c: Cliente, appuntamenti: [Appuntamento],
                             margine: Int = OrariLavoro().margineMinuti) -> AzioneConferma {
        let altri = appuntamenti.filter { $0.id != r.daSpostare && $0.stato == .pianificato }
        let durata = durataDaSostituire(r.daSpostare, appuntamenti: appuntamenti) ?? Int(p.fine.timeIntervalSince(p.inizio) / 60)
        let prova = Appuntamento(id: r.daSpostare ?? "nuovo", clienteId: c.id, titolo: "", inizio: p.inizio, durataMinuti: durata,
                                 luogo: "", note: "", stato: .pianificato)
        let avviso = MotorePianificazione.sovrapposti(prova, in: altri, margine: margine).first
            .map { "A quell'ora c'è già «\($0.titolo)», alle \(Formati.ora.string(from: $0.inizio)): l'agenda è cambiata dopo la proposta." }
        if let id = r.daSpostare, let imp = appuntamenti.first(where: { $0.id == id }) {
            let luogo = imp.luogo.isEmpty ? "" : " · \(imp.luogo)"
            return AzioneConferma(strumento: RegistroStrumenti.agendaSposta, app: .agenda, titolo: "Sposto «\(imp.titolo)»",
                                  dettaglio: "\(RegistroStrumenti.quando(imp.inizio)) → \(RegistroStrumenti.quando(p.inizio))\(luogo)",
                                  argomenti: ["appuntamento": imp.id, "cliente": c.id, "inizio": RegistroStrumenti.isoData(p.inizio),
                                              "prima": RegistroStrumenti.isoData(imp.inizio), "luogo": imp.luogo],
                                  avviso: avviso)
        }
        let luogo = r.modo.luogo
        let titolo = RegistroStrumenti.titoloImpegno(r.tipo, cliente: c.nome)
        return AzioneConferma(strumento: RegistroStrumenti.agendaNuovo, app: .agenda, titolo: "Fisso «\(titolo)»",
                              dettaglio: "\(RegistroStrumenti.quando(p.inizio))\(luogo.isEmpty ? "" : " · \(luogo)") · \(durata) minuti",
                              argomenti: ["cliente": c.id, "inizio": RegistroStrumenti.isoData(p.inizio), "tipo": r.tipo.rawValue,
                                          "durata": String(durata), "luogo": luogo, "titolo": titolo],
                              avviso: avviso)
    }

    static func azioneScelta(_ p: OrarioProposto, richiesta r: RichiestaOrari, cliente c: Cliente, contesto x: ContestoStrumenti) -> AzioneConferma {
        azioneScelta(p, richiesta: r, cliente: c, appuntamenti: x.appuntamenti, margine: x.impostazioni.orari.margineMinuti)
    }

    // MARK: - Spostamento in blocco

    /// «Libera giovedì, sposta tutto a venerdì»: ogni impegno pianificato del giorno da liberare (non i blocchi «Non
    /// disponibile», non quelli già passati) va alla stessa ora del giorno di arrivo se è libera e dentro gli orari,
    /// altrimenti al primo orario libero di quel giorno; quello che non ci sta resta dov'è e lo si dice.
    static func spostaBlocco(da: Date, a: Date, appuntamenti: [Appuntamento], orari: OrariLavoro, oggi: Date,
                             cal: Calendar = MotorePianificazione.calendario) -> SpostamentoBlocco {
        let daG = cal.startOfDay(for: da)
        let aG = cal.startOfDay(for: a)
        let giornoA = DateItaliane.descrivi(aG, conOra: false, oggi: oggi, cal: cal)
        var esito = SpostamentoBlocco(da: daG, a: aG, mosse: [], restano: [], nota: nil)
        guard daG != aG else {
            esito.nota = "Il giorno da liberare e quello di arrivo sono lo stesso."
            return esito
        }
        guard aG >= cal.startOfDay(for: oggi) else {
            esito.nota = "\(maiuscola(Formati.dataLunga.string(from: aG))) è già passato."
            return esito
        }
        guard MotorePianificazione.lavorativo(aG, orari: orari, cal: cal) else {
            esito.nota = "\(maiuscola(giornoA)) non è un giorno di lavoro: dimmi un altro giorno."
            return esito
        }
        let daMuovere = appuntamenti
            .filter { $0.stato == .pianificato && $0.tipo != .nonDisponibile && cal.isDate($0.inizio, inSameDayAs: daG) && $0.inizio >= oggi }
            .sorted { $0.inizio < $1.inizio }
        guard !daMuovere.isEmpty else {
            esito.nota = "\(maiuscola(DateItaliane.descrivi(daG, conOra: false, oggi: oggi, cal: cal))) non hai impegni da spostare."
            return esito
        }
        let ids = Set(daMuovere.map(\.id))
        let domani = MotorePianificazione.orario(aG, minuti: 24 * 60, cal: cal)
        let restanti = appuntamenti.filter { !ids.contains($0.id) && $0.inizio < domani && $0.fine > aG }
        var occupato = occupati(restanti, margine: orari.margineMinuti)
        let margine = TimeInterval(max(0, orari.margineMinuti) * 60)
        for x in daMuovere {
            let conCliente = !x.clienteId.isEmpty
            let durata = x.durataMinuti
            let stessa = MotorePianificazione.orario(aG, minuti: minuti(x.inizio, cal: cal), cal: cal)
            var scelto: Date?
            var stessaOra = false
            if stessa >= oggi, dentroOrari(stessa, durata: durata, orari: orari, conCliente: conCliente, cal: cal),
               libero(stessa, stessa.addingTimeInterval(TimeInterval(durata * 60)), occupato) {
                scelto = stessa
                stessaOra = true
            } else {
                scelto = inizi(giorno: aG, durata: durata, orari: orari, conCliente: conCliente, cal: cal).first { t in
                    t >= oggi && libero(t, t.addingTimeInterval(TimeInterval(durata * 60)), occupato)
                }
            }
            guard let inizio = scelto else {
                esito.restano.append(x.titolo)
                continue
            }
            let fine = inizio.addingTimeInterval(TimeInterval(durata * 60))
            occupato.append((inizio: inizio.addingTimeInterval(-margine), fine: fine.addingTimeInterval(margine)))
            esito.mosse.append(MossaBlocco(appuntamentoId: x.id, clienteId: x.clienteId, titolo: x.titolo, luogo: x.luogo, canale: x.canale,
                                           durataMinuti: durata, prima: x.inizio, inizio: inizio, stessaOra: stessaOra))
        }
        if !esito.restano.isEmpty {
            let elenco = esito.restano.map { "«\($0)»" }.joined(separator: ", ")
            esito.nota = "\(elenco) non \(esito.restano.count == 1 ? "ci sta" : "ci stanno"): \(giornoA) non c'è un orario libero abbastanza lungo, \(esito.restano.count == 1 ? "resta" : "restano") dove \(esito.restano.count == 1 ? "è" : "sono")."
        }
        return esito
    }

    static func spostaBlocco(_ r: RichiestaOrari, contesto x: ContestoStrumenti) -> SpostamentoBlocco? {
        guard let da = r.daGiorno, let a = r.aGiorno else { return nil }
        return spostaBlocco(da: da, a: a, appuntamenti: x.appuntamenti, orari: x.impostazioni.orari, oggi: x.oggi, cal: x.calendario)
    }

    /// Le azioni per la scheda «Conferma»: per ogni impegno lo spostamento (agenda_sposta_impegno) e, se è con un
    /// cliente, il messaggio per avvisarlo (messaggi_prepara, scopo «spostamento», testo scritto da Prisma).
    static func azioni(_ s: SpostamentoBlocco, clienti: [Cliente], impostazioni: Impostazioni,
                       cal: Calendar = MotorePianificazione.calendario) -> [AzioneConferma] {
        var elenco: [AzioneConferma] = []
        for m in s.mosse {
            let luogo = m.luogo.isEmpty ? "" : " · \(m.luogo)"
            let avviso = m.stessaOra ? nil
                : "Alle \(Formati.ora.string(from: m.prima)) \(Formati.giornoSettimana.string(from: m.inizio)) non c'è posto: lo metto alle \(Formati.ora.string(from: m.inizio)), il primo orario libero."
            elenco.append(AzioneConferma(strumento: RegistroStrumenti.agendaSposta, app: .agenda, titolo: "Sposto «\(m.titolo)»",
                                         dettaglio: "\(RegistroStrumenti.quando(m.prima)) → \(RegistroStrumenti.quando(m.inizio))\(luogo)",
                                         argomenti: ["appuntamento": m.appuntamentoId, "cliente": m.clienteId,
                                                     "inizio": RegistroStrumenti.isoData(m.inizio), "prima": RegistroStrumenti.isoData(m.prima),
                                                     "luogo": m.luogo],
                                         avviso: avviso))
            guard let c = clienti.first(where: { $0.id == m.clienteId }) else { continue }
            let firma = ModelliMessaggi.firma(m.canale, tono: .formale, impostazioni: impostazioni)
            let testo = RegistroStrumenti.testoSpostamento(c, inizio: m.inizio, luogo: m.luogo, firma: firma)
            let via: CanaleMessaggio = c.telefono.filter(\.isNumber).count >= 6 ? .messaggi : .mail
            elenco.append(AzioneConferma(strumento: RegistroStrumenti.messaggiPrepara, app: .messaggi, titolo: "Preparo un messaggio per \(c.nome)",
                                         dettaglio: RegistroStrumenti.dettaglioMessaggio(testo, canale: via),
                                         argomenti: ["cliente": c.id, "scopo": "spostamento", "testo": testo, "canale": via.rawValue,
                                                     "appuntamento": m.appuntamentoId]))
        }
        return elenco
    }

    /// La risposta di Vera in chat: «Sposto due impegni a venerdì 6 novembre, alla stessa ora. Preparo i messaggi per
    /// avvisare i clienti: li spedisci tu.»
    static func risposta(_ s: SpostamentoBlocco, oggi: Date, cal: Calendar = MotorePianificazione.calendario) -> String {
        guard !s.mosse.isEmpty else { return s.nota ?? "Non ho niente da spostare." }
        let n = s.mosse.count
        let giorno = DateItaliane.descrivi(s.a, conOra: false, oggi: oggi, cal: cal)
        let quanti = n == 1 ? "un impegno" : "\(SchedaConfermaVera.numero(n)) impegni"
        var testo: String
        if s.mosse.allSatisfy({ $0.stessaOra }) {
            testo = "Sposto \(quanti) a \(giorno), alla stessa ora."
        } else {
            let altri = s.mosse.filter { !$0.stessaOra }
                .map { "«\($0.titolo)» alle \(Formati.ora.string(from: $0.inizio))" }.joined(separator: ", ")
            testo = "Sposto \(quanti) a \(giorno): \(altri) (alla stessa ora non c'era posto), gli altri alla stessa ora."
            if s.mosse.allSatisfy({ !$0.stessaOra }) { testo = "Sposto \(quanti) a \(giorno): \(altri), alla stessa ora non c'era posto." }
        }
        if s.mosse.contains(where: { !$0.clienteId.isEmpty }) { testo += " Preparo i messaggi per avvisare i clienti: li spedisci tu." }
        if let nota = s.nota { testo += " " + nota }
        return testo
    }

    /// La scheda di conferma con le azioni (origine: regole o Qwen).
    static func scheda(_ azioni: [AzioneConferma], richiesta: String, conQwen: Bool) -> SchedaConfermaVera {
        SchedaConfermaVera(richiesta: richiesta, azioni: azioni, origine: conQwen ? .qwen : .regole)
    }

    // MARK: - Capire la frase: prima le regole

    private static func normale(_ frase: String) -> String {
        frase.lowercased().replacingOccurrences(of: "’", with: "'")
    }

    private static func trova(_ schema: String, _ t: String) -> Bool { DateItaliane.cerca(schema, t) != nil }

    /// Cosa chiede la frase, se è una richiesta di questa funzione.
    static func riconosce(_ frase: String) -> RichiestaOrari.Intento? {
        let t = normale(frase)
        if trova(#"\b(libera|liberami|svuota|svuotami)\b.*\b(sposta|spostando|spostami|metti|mettendo|porta)\b"#, t)
            || trova(#"\bsposta(mi)? (tutto|tutti|tutte|gli impegni|gli appuntamenti|la giornata)\b"#, t) {
            return .spostaBlocco
        }
        if trova(#"\b(trova|trovami|cerca|cercami|proponi|proponimi|dammi|vedi se c'è)\b.*\b(ora|orario|orari|spazio|buco|momento|posto|mezz'ora)\b"#, t)
            || trova(#"\b(un'ora|un orario|due orari|mezz'ora)\b.*\b(per|con)\b"#, t) && trova(#"\b(entro|attaccat|libero|liber[ao]|trova|cerca)"#, t) {
            return .cerca
        }
        return nil
    }

    private static let schemaGiorni = #"\b(?:(?:il |la )?prossim[oa] )?(?:luned[iì]|marted[iì]|mercoled[iì]|gioved[iì]|venerd[iì]|sabato|domenica)(?: prossim[oa])?|\bdopodomani\b|\bdomani\b|\boggi\b|\b\d{1,2}(?: |/)(?:\d{1,2}|"# + DateItaliane.mesi.joined(separator: "|") + #")(?:(?: |/)\d{4})?"#

    /// I giorni nominati nella frase, nell'ordine in cui compaiono, con il testo che li precede.
    private static func giorniConPrima(_ frase: String, oggi: Date, cal: Calendar) -> [(giorno: Date, prima: String)] {
        let t = normale(frase)
        guard let re = try? NSRegularExpression(pattern: schemaGiorni, options: [.caseInsensitive]) else { return [] }
        let ns = t as NSString
        return re.matches(in: t, range: NSRange(location: 0, length: ns.length)).compactMap { m in
            guard let g = DateItaliane.trova(ns.substring(with: m.range), oggi: oggi, cal: cal).giorno else { return nil }
            return (giorno: cal.startOfDay(for: g), prima: ns.substring(to: m.range.location))
        }
    }

    /// I giorni nominati nella frase, nell'ordine in cui compaiono.
    static func giorniNominati(_ frase: String, oggi: Date, cal: Calendar) -> [Date] {
        giorniConPrima(frase, oggi: oggi, cal: cal).map(\.giorno)
    }

    /// Spostamento in blocco: il giorno da liberare e quello di arrivo, dalle parole che li precedono, non dall'ordine
    /// («a/al/su/per venerdì» è l'arrivo; «libera/da/di giovedì» la partenza). Con un solo giorno senza indicazione è la
    /// partenza (la domanda chiede l'arrivo); se resta ambiguo nessuno dei due, così si chiede o si passa a Qwen.
    static func partenzaArrivo(_ frase: String, oggi: Date, cal: Calendar) -> (da: Date?, a: Date?) {
        var partenze: [Date] = [], arrivi: [Date] = [], senza: [Date] = []
        func aggiungi(_ g: Date, _ elenco: inout [Date]) { if !elenco.contains(g) { elenco.append(g) } }
        for (g, prima) in giorniConPrima(frase, oggi: oggi, cal: cal) {
            if trova(#"\b(?:a|ad|al|alla|allo|su|sul|sulla|per|verso)\s*$"#, prima) {
                aggiungi(g, &arrivi)
            } else if trova(#"\b(?:libera|liberami|liberare|liberando|svuota|svuotami|svuotare|da|dal|dalla|di|del|della)\s*$"#, prima) {
                aggiungi(g, &partenze)
            } else {
                aggiungi(g, &senza)
            }
        }
        senza.removeAll { partenze.contains($0) || arrivi.contains($0) }
        // Due partenze o due arrivi diversi: non si indovina
        guard partenze.count <= 1, arrivi.count <= 1 else { return (nil, nil) }
        var da = partenze.first, a = arrivi.first
        if da == nil, a != nil, senza.count == 1 { da = senza[0] }
        else if a == nil, da != nil, senza.count == 1 { a = senza[0] }
        else if da == nil, a == nil, senza.count == 1 { da = senza[0] }
        else if !senza.isEmpty { return (nil, nil) }
        return (da, a)
    }

    /// La durata detta: «45 minuti», «mezz'ora», «un'ora e mezza», «due ore» (nil se non c'è).
    static func durataDetta(_ frase: String) -> Int? {
        let t = normale(frase)
        if case let (_, g)? = DateItaliane.cerca(#"\b(\d{1,3})\s*(?:min|minuti)\b"#, t), let n = Int(g[1]), n > 0 { return n }
        if trova(#"\bun'ora e mezz[ao]\b"#, t) { return 90 }
        if case let (_, g)? = DateItaliane.cerca(#"\b(\d|due|tre)\s+ore\b"#, t), let n = DateItaliane.numero(g[1]) { return n * 60 }
        if trova(#"\bmezz'ora\b"#, t) { return 30 }
        if trova(#"\bun'ora\b"#, t) { return 60 }
        return nil
    }

    /// La durata di sempre per il tipo: telefonata 20 minuti, riesame un'ora (come «Pianifica»), gli altri un'ora.
    static func durataPredefinita(_ tipo: TipoAppuntamento, modo: ModoIncontro) -> Int {
        if tipo == .telefonata || modo == .telefonata { return 20 }
        if tipo == .revisione { return MotorePianificazione.durataRiesame }
        return 60
    }

    private static func modoDetto(_ t: String) -> ModoIncontro {
        if trova(#"video|online|on line|zoom|meet\b|teams"#, t) { return .videochiamata }
        if trova(#"telefon|chiamat|\bchiamar"#, t) { return .telefonata }
        return .studio
    }

    private static func tipoDetto(_ t: String, modo: ModoIncontro) -> TipoAppuntamento {
        if trova(#"riesam|revision"#, t) { return .revisione }
        var tipo = RegistroStrumenti.tipo(t)
        if modo == .videochiamata && tipo == .telefonata { tipo = .altro }
        if modo == .telefonata && tipo == .altro { tipo = .telefonata }
        return tipo
    }

    /// Il nome detto dopo «di», «con», «per», «a» con la maiuscola («il riesame di Federico» → Federico).
    private static func nomeDetto(_ frase: String) -> String? {
        let esclusi: Set<String> = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica", "Alleanza", "Prisma", "Vera"]
        // Qui le maiuscole contano (DateItaliane.cerca non le distingue): la prima parola con la maiuscola dopo la preposizione
        guard let re = try? NSRegularExpression(pattern: #"\b(?:di|con|per|a|al)\s+([A-ZÀ-Ý][a-zà-ÿ]{2,})"#) else { return nil }
        let ns = frase as NSString
        for m in re.matches(in: frase, range: NSRange(location: 0, length: ns.length)) {
            let n = ns.substring(with: m.range(at: 1))
            if !esclusi.contains(n) { return n }
        }
        return nil
    }

    /// L'impegno del cliente che la ricerca sostituisce: il prossimo pianificato dello stesso tipo.
    static func impegnoDaSostituire(cliente: String, tipo: TipoAppuntamento, appuntamenti: [Appuntamento], oggi: Date) -> Appuntamento? {
        guard tipo != .altro else { return nil }
        return appuntamenti.filter { $0.clienteId == cliente && $0.tipo == tipo && $0.stato == .pianificato && $0.inizio >= oggi }
            .min { $0.inizio < $1.inizio }
    }

    /// La richiesta capita con le regole (nil se la frase non è di questa funzione). Può restare incompleta: vedi `domanda`.
    static func interpreta(_ frase: String, contesto x: ContestoStrumenti) -> RichiestaOrari? {
        guard let intento = riconosce(frase) else { return nil }
        let t = normale(frase)
        let giorni = giorniNominati(frase, oggi: x.oggi, cal: x.calendario)
        switch intento {
        case .spostaBlocco:
            let (da, a) = partenzaArrivo(frase, oggi: x.oggi, cal: x.calendario)
            return RichiestaOrari(intento: .spostaBlocco, daGiorno: da, aGiorno: a)
        case .cerca:
            var r = RichiestaOrari(intento: .cerca)
            r.modo = modoDetto(t)
            r.tipo = tipoDetto(t, modo: r.modo)
            r.durataMinuti = durataDetta(frase) ?? durataPredefinita(r.tipo, modo: r.modo)
            r.attaccato = trova(#"attaccat|una volta sola|subito (prima|dopo)|(vicino|accanto|insieme|attorno) a(d)? (un altro|un'altro|altri)|stesso giro"#, t)
            if case let (_, g)? = DateItaliane.cerca(#"\bentro\s+(.+)$"#, t) {
                r.entro = DateItaliane.trova(g[1], oggi: x.oggi, cal: x.calendario).giorno.map { x.calendario.startOfDay(for: $0) }
            } else if let g = giorni.first {
                // «Trovami un'ora giovedì»: proprio quel giorno
                r.dal = g
                r.entro = g
            }
            // Il cliente aperto vale solo se la frase non nomina nessun cliente: con due Bianchi si chiede quale
            let risolto = RegistroStrumenti.cliente(frase, x)
            if case .trovato(let c) = risolto {
                r.clienteId = c.id
            } else if case .ambiguo(let cs) = risolto {
                r.ambigui = cs.map(\.nome)
            } else if let n = nomeDetto(frase) {
                r.nomeDetto = n
            } else if let id = x.attivo, x.clienti.contains(where: { $0.id == id }) {
                r.clienteId = id
            }
            if let id = r.clienteId {
                r.daSpostare = impegnoDaSostituire(cliente: id, tipo: r.tipo, appuntamenti: x.appuntamenti, oggi: x.oggi)?.id
                r.durataMinuti = durataDaSostituire(r.daSpostare, appuntamenti: x.appuntamenti) ?? r.durataMinuti
            }
            return r
        }
    }

    /// Cosa manca per procedere, come domanda di Vera (nil = si può procedere).
    static func domanda(_ r: RichiestaOrari, oggi: Date, cal: Calendar = MotorePianificazione.calendario) -> String? {
        switch r.intento {
        case .spostaBlocco:
            guard let da = r.daGiorno else { return "Quale giorno ti libero?" }
            guard r.aGiorno != nil else { return "A quale giorno sposto gli impegni di \(DateItaliane.descrivi(da, conOra: false, oggi: oggi, cal: cal))?" }
            return nil
        case .cerca:
            if r.clienteId == nil, let a = r.ambigui, a.count > 1 { return "Quale cliente intendi: \(a.joined(separator: " o "))?" }
            if r.clienteId == nil, let n = r.nomeDetto { return "Non trovo «\(n)» tra i clienti: con chi è l'incontro?" }
            return nil
        }
    }

    /// Serve Qwen per capire la frase: le regole non l'hanno riconosciuta o la richiesta è rimasta incompleta.
    static func serveQwen(_ r: RichiestaOrari?, oggi: Date, cal: Calendar = MotorePianificazione.calendario) -> Bool {
        guard let r else { return true }
        return domanda(r, oggi: oggi, cal: cal) != nil
    }

    // MARK: - Capire la frase: Qwen (solo JSON, poi i controlli di Prisma)

    static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "intento": ["type": "string", "enum": ["cerca", "sposta_blocco", "altro"]] as [String: Any],
            "cliente": ["type": "string"],
            "entro": ["type": "string"],
            "dal": ["type": "string"],
            "durata_minuti": ["type": "integer"],
            "attaccato": ["type": "boolean"],
            "modo": ["type": "string", "enum": ["studio", "videochiamata", "telefonata"]] as [String: Any],
            "tipo": ["type": "string", "enum": ["incontro", "revisione", "firma", "proposta", "analisi", "primo incontro", "telefonata"]] as [String: Any],
            "da_giorno": ["type": "string"],
            "a_giorno": ["type": "string"],
        ] as [String: Any],
        "required": ["intento"],
    ]

    static var istruzioni: String {
        IstruzioniVera.testo("agenda-organizza") ?? "Capisci la richiesta del consulente sull'agenda. intento: cerca (trovare un orario per un incontro), sposta_blocco (liberare un giorno spostando tutto a un altro), altro. Per cerca: cliente (il nome come detto), entro e dal (il giorno come detto), durata_minuti solo se detta, attaccato (true se vuole l'orario vicino a un altro incontro in studio), modo, tipo. Per sposta_blocco: da_giorno e a_giorno come detti. Non calcolare orari e non inventare giorni, nomi o durate: lascia vuoto quello che non c'è. Rispondi solo con il JSON."
    }

    static func messaggi(_ frase: String, oggi: Date) -> [MessaggioModello] {
        [MessaggioModello(ruolo: .sistema, testo: istruzioni),
         MessaggioModello(ruolo: .utente, testo: "OGGI: \(Formati.dataLunga.string(from: oggi)) \(Formati.dataEstesa.string(from: oggi))\nRICHIESTA: \(frase)")]
    }

    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0
        o.contesto = 2_048
        o.massimoToken = 200
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        o.conLezioni = false
        return o
    }

    /// La richiesta capita da Qwen, controllata da Prisma: i giorni devono essere tra quelli nominati nella frase,
    /// la durata detta (o quella di sempre), il cliente tra i clienti. Output non valido → nil.
    static func leggi(_ json: String, frase: String, contesto x: ContestoStrumenti) -> RichiestaOrari? {
        guard let i = json.firstIndex(of: "{"), let f = json.lastIndex(of: "}"), i < f,
              let d = String(json[i...f]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return nil }
        let a = ArgomentiStrumento(j)
        let cal = x.calendario
        let nominati = giorniNominati(frase, oggi: x.oggi, cal: cal)
        // Un giorno vale solo se è tra quelli della frase: Qwen non inventa date
        func giorno(_ chiave: String) -> Date? {
            guard let g = RegistroStrumenti.giorno(a.testo(chiave), oggi: x.oggi, cal: cal) else { return nil }
            return nominati.contains(g) ? g : nil
        }
        switch a.testo("intento") {
        case "sposta_blocco"?:
            guard let da = giorno("da_giorno"), let al = giorno("a_giorno"), da != al else { return nil }
            return RichiestaOrari(intento: .spostaBlocco, daGiorno: da, aGiorno: al, conQwen: true)
        case "cerca"?:
            let t = normale(frase)
            var r = RichiestaOrari(intento: .cerca, conQwen: true)
            switch a.testo("modo") {
            case "videochiamata"?: r.modo = .videochiamata
            case "telefonata"?: r.modo = .telefonata
            default: r.modo = .studio
            }
            r.tipo = trova(#"riesam|revision"#, (a.testo("tipo") ?? "").lowercased()) ? .revisione : RegistroStrumenti.tipo(a.testo("tipo"))
            if r.modo == .telefonata && r.tipo == .altro { r.tipo = .telefonata }
            // La durata di Qwen vale solo se è proprio quella detta nella frase («45 minuti»): un numero che compare altrove
            // («entro il 30 novembre») non è una durata. Altrimenti la durata detta o quella di sempre.
            let detta = durataDetta(frase)
            if let n = a.numero("durata_minuti").map({ Int($0) }), n >= 10, n <= 600, n == detta {
                r.durataMinuti = n
            } else {
                r.durataMinuti = detta ?? durataPredefinita(r.tipo, modo: r.modo)
            }
            r.attaccato = (j["attaccato"] as? Bool) ?? false
            r.entro = giorno("entro")
            r.dal = giorno("dal")
            if let dal = r.dal, let entro = r.entro, entro < dal { return nil }
            // Il cliente di Qwen vale solo se è nominato nella frase (come i giorni): un nome inventato non sceglie
            // né il cliente né l'impegno da spostare; senza un nome valido vale il cliente aperto. Il cliente si controlla
            // da solo: un altro cliente detto con nome e cognome nella stessa frase non deve nasconderlo
            var nomeValido = false
            if let nome = a.testo("cliente") {
                if case .trovato(let c) = RegistroStrumenti.cliente(nome, x),
                   !InterpreteComandi.clientiNominati(t, [ClienteNoto(id: c.id, nome: c.nome)]).isEmpty {
                    r.clienteId = c.id
                    nomeValido = true
                } else if nome.count >= 3, t.contains(nome.lowercased()) {
                    r.nomeDetto = nome
                    nomeValido = true
                }
            }
            // Una frase che nomina più clienti senza sceglierne uno (due Bianchi) non passa al cliente aperto: si chiede quale
            if r.clienteId == nil, case .ambiguo(let cs) = RegistroStrumenti.cliente(frase, x) {
                r.ambigui = cs.map(\.nome)
                nomeValido = true
            }
            if !nomeValido, let id = x.attivo, x.clienti.contains(where: { $0.id == id }) {
                r.clienteId = id
            }
            if let id = r.clienteId {
                r.daSpostare = impegnoDaSostituire(cliente: id, tipo: r.tipo, appuntamenti: x.appuntamenti, oggi: x.oggi)?.id
                r.durataMinuti = durataDaSostituire(r.daSpostare, appuntamenti: x.appuntamenti) ?? r.durataMinuti
            }
            return r
        default:
            return nil
        }
    }

    // MARK: - Contesto

    /// Il contesto degli strumenti dai dati di Prisma (`oggi` sempre da fuori).
    static func contesto(_ d: DatiPrisma, oggi: Date, attivo: String? = nil, cal: Calendar = MotorePianificazione.calendario) -> ContestoStrumenti {
        ContestoStrumenti(oggi: oggi, clienti: d.clienti, appuntamenti: d.appuntamenti, posizioni: d.posizioni, attivo: attivo,
                          impostazioni: d.impostazioni, inModoCliente: false, calendario: cal)
    }
}
