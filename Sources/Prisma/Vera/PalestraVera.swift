import Foundation

// La palestra della trattativa (Design/template-luce-specifica.md §5.3, «Luce» giro 5): Vera recita un cliente, con il
// suo profilo vero dal dossier o con un profilo inventato (solo età, lavoro e timori), e il consulente si allena a
// rispondere alle sue obiezioni. È un percorso a parte di Vera (decisione 112), non un terzo caso di `ModalitaVera`:
// stesso Qwen locale, stesso fornitore e stessa finestra, ma istruzioni proprie (Vera/Istruzioni/palestra.md) e lo
// schema fisso Vera/Schemi/palestra.json, passato a Ollama in «format».
//
// - Una sola chiamata per turno: Qwen giudica la risposta del consulente, scrive la replica del cliente, la sua
//   convinzione e la prossima obiezione con tre risposte suggerite. Al primo turno solo l'obiezione e le suggerite.
// - Le cifre: la scheda della recita la prepara Prisma (età, obiettivi, proposte, aliquote fiscali dei motori). Una
//   replica o un'obiezione con una cifra che non è nella scheda (né nella risposta del consulente) si scarta e si
//   riprova una volta; una suggerita con una cifra inventata si toglie. Un JSON che non si legge si scarta.
// - Il giudizio è misto: prima le regole di Prisma (pressione, promesse di rendimento, critiche, risposte generiche),
//   poi Qwen; vale il più prudente dei due. Il punteggio (3/2/0, somma su 3·N) è indicativo; la frase finale la decide
//   la convinzione del cliente.
// - Si salva solo un registro leggero (data, cliente, difficoltà, punteggio: `Impostazioni.palestra`, decisione 51):
//   la conversazione è una prova, non un fatto del cliente, e non entra nel dossier.

/// Quanto è difficile il cliente recitato (§5.3 della specifica, «5.3 Difficoltà»).
enum DifficoltaPalestra: String, Codable, CaseIterable, Identifiable {
    case facile, realistica, difficile

    var id: String { rawValue }

    var titolo: String {
        switch self {
        case .facile: return "Facile"
        case .realistica: return "Realistica"
        case .difficile: return "Difficile"
        }
    }

    /// La convinzione del cliente prima della prima obiezione (0-100).
    var convinzioneIniziale: Int {
        switch self {
        case .facile: return 60
        case .realistica: return 40
        case .difficile: return 20
        }
    }

    /// Di quanto la convinzione può cambiare in un turno: Prisma ferma Qwen se esagera.
    var passoMassimo: Int {
        switch self {
        case .facile: return 35
        case .realistica: return 25
        case .difficile: return 15
        }
    }

    /// La regola per Qwen, nell'ultimo messaggio.
    var regola: String {
        switch self {
        case .facile:
            return "Facile: sei abbastanza convinto e una risposta buona ti basta per passare oltre."
        case .realistica:
            return "Realistica: ti serve una risposta ottima, o due buone, per convincerti un po' di più."
        case .difficile:
            return "Difficile: sei scettico, torni sui tuoi dubbi, chiedi numeri; con risposte deboli puoi chiudere con un no gentile."
        }
    }
}

/// Il giudizio su una risposta del consulente.
enum GiudizioPalestra: String, Codable, CaseIterable {
    case debole, buona, ottima

    /// Punti del template: 3 ottima, 2 buona, 0 debole.
    var punti: Int {
        switch self {
        case .ottima: return 3
        case .buona: return 2
        case .debole: return 0
        }
    }

    /// La riga sotto la bolla del consulente (`.pFb` del template).
    var testo: String {
        switch self {
        case .ottima: return "✓ Ottima: hai usato Prisma per farglielo vedere"
        case .buona: return "○ Buona: chiara e corretta"
        case .debole: return "△ Debole: generica o di pressione"
        }
    }

    /// Il più prudente dei due.
    static func prudente(_ a: GiudizioPalestra, _ b: GiudizioPalestra) -> GiudizioPalestra {
        a.punti <= b.punti ? a : b
    }
}

/// Lo strumento di Prisma che avrebbe aiutato il consulente.
enum StrumentoPalestra: String, Codable, CaseIterable {
    case lineaVita, lanciaAnno, film, provaFuoco

    var nome: String {
        switch self {
        case .lineaVita: return "la linea della vita"
        case .lanciaAnno: return "«Lancia l’anno»"
        case .film: return "il film del piano"
        case .provaFuoco: return "la prova del fuoco"
        }
    }

    /// Quelli del template, se Qwen non ne indica nessuno.
    static let predefiniti: [StrumentoPalestra] = [.lineaVita, .lanciaAnno, .film]
}

/// Un profilo inventato: solo età, lavoro e timori (decisione 51). Non si salva.
struct ProfiloInventatoPalestra: Equatable {
    var eta = ""
    var lavoro = ""
    var timori = ""

    var vuoto: Bool {
        eta.trimmingCharacters(in: .whitespaces).isEmpty && lavoro.trimmingCharacters(in: .whitespaces).isEmpty
            && timori.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// La scheda della recita: ciò che il cliente sa di sé, con le cifre preparate da Prisma. Niente provvigioni né giudizi
/// interni del consulente (le note del dossier non entrano).
struct SchedaRecita: Equatable {
    var clienteId: String?
    var nome: String
    var iniziali: String
    /// «37 anni, architetta, convivente con Luca Ferri».
    var chiE: String?
    /// «il rischio dei mercati; il mutuo: se succedesse qualcosa…».
    var timori: String?
    /// «Anticipo per la casa entro novembre 2029».
    var obiettivo: String?
    /// Le altre righe per Qwen: proposte in corso, orizzonte.
    var dettagli: [String] = []
    /// Le cifre calcolate da Prisma (obiettivi, proposte, aliquote): le sole che Vera e le suggerite possono usare.
    var cifre: [String] = []

    var nomeBreve: String { nome.split(separator: " ").first.map(String.init) ?? nome }

    /// Senza età, timori né obiettivi l'allenamento sarà generico (§1.7 «Profilo scarno»).
    var scarna: Bool { chiE == nil || (timori == nil && obiettivo == nil) }

    /// Il testo che arriva a Qwen.
    var testo: String {
        var r = ["CLIENTE: \(nome)."]
        if let chiE { r.append("Chi è: \(chiE).") }
        if let timori { r.append("I suoi timori: \(timori).") }
        if let obiettivo { r.append("L'obiettivo: \(obiettivo).") }
        r.append(contentsOf: dettagli)
        if !cifre.isEmpty {
            r.append("CIFRE DI PRISMA (le sole che puoi usare, così come sono):")
            r.append(contentsOf: cifre.map { "- " + $0 })
        }
        if scarna { r.append("Di questo cliente Prisma sa poco: resta generico e non inventare dettagli.") }
        return String(r.joined(separator: "\n").prefix(PalestraVera.limiteScheda))
    }
}

/// La risposta di Qwen a un turno, già controllata.
struct RispostaPalestra: Equatable {
    var giudizio: GiudizioPalestra?
    var motivo: String
    var replica: String
    var convinta: Int?
    var prossimaObiezione: String?
    var suggerite: [String]
    var strumento: StrumentoPalestra?
}

/// Un turno dell'allenamento: l'obiezione, le suggerite, la risposta del consulente, il giudizio e la replica.
struct TurnoPalestra: Identifiable, Equatable {
    var id: Int
    var obiezione: String
    var suggerite: [String]
    var risposta: String?
    var giudizio: GiudizioPalestra?
    var motivo: String?
    var replica: String?
}

enum PalestraVera {
    /// Le obiezioni di un allenamento (3 come nel template, decisione 6).
    static let obiezioni = 3
    /// Le risposte suggerite per obiezione.
    static let suggerite = 3
    /// Tentativi per turno: una risposta scartata si richiede una volta.
    static let tentativi = 2
    /// Lunghezza massima della scheda della recita (istruzioni + scheda + 3 turni stanno negli 8.192 token).
    static let limiteScheda = 1_600
    /// Da questa convinzione il cliente dice di sì (frase finale).
    static let sogliaConvinta = 60
    /// Allenamenti ricordati nelle impostazioni.
    static let massimoEsiti = 50

    // MARK: - Istruzioni e schema

    static var istruzioni: String {
        IstruzioniVera.testo("palestra") ?? "Reciti un cliente di un consulente finanziario italiano, in prima persona, frasi brevi. Rispondi solo con un oggetto JSON: giudizio (ottima, buona, debole, nessuno), motivo, replica, convinta (0-100), prossimaObiezione, suggerite (tre risposte), strumento (lineaVita, lanciaAnno, film, provaFuoco, nessuno). Usa solo le cifre della scheda."
    }

    /// Lo schema di Vera/Schemi/palestra.json dal pacchetto (in sviluppo: quello nel codice).
    static var schema: [String: Any] {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Vera/Schemi/palestra.json"),
           let d = try? Data(contentsOf: url), let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] {
            return j
        }
        return schemaInterno
    }

    /// Lo stesso schema nel codice (la prova controlla che coincida con quello della cartella Vera/Schemi).
    static let schemaInterno: [String: Any] = {
        var p: [String: Any] = [:]
        p["giudizio"] = ["type": "string", "enum": ["ottima", "buona", "debole", "nessuno"]]
        p["motivo"] = ["type": "string"]
        p["replica"] = ["type": "string"]
        p["convinta"] = ["type": "integer", "minimum": 0, "maximum": 100]
        p["prossimaObiezione"] = ["type": "string"]
        p["suggerite"] = ["type": "array", "items": ["type": "string"], "maxItems": 3] as [String: Any]
        p["strumento"] = ["type": "string", "enum": ["lineaVita", "lanciaAnno", "film", "provaFuoco", "nessuno"]]
        let richiesti = ["giudizio", "motivo", "replica", "convinta", "prossimaObiezione", "suggerite", "strumento"]
        return ["type": "object", "properties": p, "required": richiesti]
    }()

    /// Un po' di varietà (0,5, più della modalità lavoro), niente ragionamento lungo, la finestra di sempre, lo schema.
    static func opzioni(_ vera: ImpostazioniVera) -> OpzioniModello {
        var o = OpzioniModello()
        o.temperatura = 0.5
        o.pensa = false
        o.contesto = NucleoVera.finestra
        o.massimoToken = 520
        o.restaInMemoria = vera.restaInMemoria
        o.formato = schema
        return o
    }

    // MARK: - La scheda della recita

    /// La scheda di un cliente dell'archivio, con le cifre dei motori di Prisma.
    static func scheda(_ f: FonteVera) -> SchedaRecita {
        let c = f.cliente
        var s = SchedaRecita(clienteId: c.id, nome: c.nome, iniziali: c.iniziali)
        var chi: [String] = []
        if let eta = c.eta { chi.append("\(eta) anni") }
        if !c.professione.isEmpty { chi.append(c.professione.lowercased()) }
        if let p = c.profilo.propensione { chi.append(aggettivo(p)) }
        if let compagno = c.famiglia.first(where: { [.coniuge, .convivente].contains($0.relazione) }) {
            chi.append("decide insieme a \(compagno.nome.split(separator: " ").first.map(String.init) ?? compagno.nome)")
        }
        let figli = c.famiglia.filter { $0.relazione == .figlio }.count
        if figli > 0 { chi.append(figli == 1 ? "un figlio" : "\(figli) figli") }
        s.chiE = chi.isEmpty ? nil : chi.joined(separator: ", ")

        var timori: [String] = []
        if let p = c.profilo.propensione { timori.append(timore(p)) }
        if let u = f.incontri.filter({ $0.stato == .concluso }).max(by: { $0.data < $1.data }), !u.preoccupazioni.isEmpty {
            // Senza il punto finale e con la minuscola (la frase continua dopo il punto e virgola)
            var t = String(u.preoccupazioni.prefix(160)).trimmingCharacters(in: CharacterSet(charactersIn: ". \n"))
            if let primo = t.first, t.dropFirst().first?.isUppercase != true { t = primo.lowercased() + t.dropFirst() }
            timori.append(t)
        }
        s.timori = timori.isEmpty ? nil : timori.joined(separator: "; ")

        let obiettivi = f.obiettivi.sorted { ($0.priorita.rawValue, $1.scadenza) > ($1.priorita.rawValue, $0.scadenza) }
        if let o = obiettivi.first {
            s.obiettivo = "\(o.titolo.lowercased()) entro \(Formati.meseAnno.string(from: o.scadenza))"
        }
        for o in obiettivi.prefix(2) {
            let a = AvanzamentoObiettivo(o, posizioni: f.posizioni)
            var r = "\(o.titolo): \(Formati.euro(o.importo)) entro \(Formati.meseAnno.string(from: o.scadenza)), già da parte \(Formati.euro(a.accantonato))"
            if let v = a.versamentoNecessario { r += ", versamento necessario \(Formati.euro(v)) al mese" }
            s.cifre.append(r)
        }
        let proposte = f.posizioni.filter { $0.stato == .proposta }
        for p in proposte.prefix(2) { s.cifre.append("Proposta in corso: " + ContestoVera.riga(p)) }
        if let o = c.profilo.orizzonteAnni { s.dettagli.append("Orizzonte dichiarato: \(o) anni.") }
        if !c.tema.isEmpty { s.dettagli.append("Il suo progetto: \(c.tema)") }
        if !s.cifre.isEmpty || !proposte.isEmpty {
            s.cifre.append("Imposta sui rendimenti finanziari \(CifreDoc.percento(RegoleFiscali.ordinaria, decimali: 0)), sui titoli di Stato \(CifreDoc.percento(RegoleFiscali.titoliStato, decimali: 1)) (regole fiscali di Prisma)")
        }
        return s
    }

    /// La scheda di un profilo inventato: solo quello che il consulente ha scritto.
    static func scheda(inventato p: ProfiloInventatoPalestra) -> SchedaRecita {
        let pulito = { (t: String) in t.trimmingCharacters(in: .whitespacesAndNewlines) }
        var s = SchedaRecita(clienteId: nil, nome: nomeInventato, iniziali: "CI")
        var chi: [String] = []
        if !pulito(p.eta).isEmpty { chi.append(pulito(p.eta).allSatisfy(\.isNumber) ? "\(pulito(p.eta)) anni" : pulito(p.eta)) }
        if !pulito(p.lavoro).isEmpty { chi.append(pulito(p.lavoro).lowercased()) }
        s.chiE = chi.isEmpty ? nil : chi.joined(separator: ", ")
        s.timori = pulito(p.timori).isEmpty ? nil : pulito(p.timori)
        return s
    }

    static let nomeInventato = "Cliente inventato"

    private static func aggettivo(_ p: ProfiloInvestitore.Propensione) -> String {
        switch p {
        case .prudente: return "molto prudente"
        case .moderata: return "prudente"
        case .dinamica: return "aperto al rischio"
        case .aggressiva: return "molto aperto al rischio"
        }
    }

    private static func timore(_ p: ProfiloInvestitore.Propensione) -> String {
        switch p {
        case .prudente: return "perdere anche solo una parte dei risparmi"
        case .moderata: return "i soldi bloccati e il rischio dei mercati"
        case .dinamica: return "lasciare i soldi fermi senza farli crescere"
        case .aggressiva: return "i costi che si mangiano il rendimento"
        }
    }

    // MARK: - La richiesta a Qwen

    /// L'ultimo messaggio: scheda, difficoltà, conversazione fin qui e compito del turno. `turni` sono quelli già
    /// giocati; l'ultimo, se ha la risposta del consulente ma non la replica, è quello da giudicare.
    static func messaggi(scheda: SchedaRecita, difficolta: DifficoltaPalestra, turni: [TurnoPalestra]) -> [MessaggioModello] {
        var parti = ["SCHEDA DEL CLIENTE CHE RECITI (preparata da Prisma)\n" + scheda.testo]
        parti.append("DIFFICOLTÀ: \(difficolta.regola) Convinzione di partenza: \(difficolta.convinzioneIniziale).")
        if !turni.isEmpty {
            var storia: [String] = []
            for t in turni {
                storia.append("Cliente: \(t.obiezione)")
                if let r = t.risposta { storia.append("Consulente: \(r)") }
                if let r = t.replica { storia.append("Cliente: \(r)") }
            }
            parti.append("CONVERSAZIONE FIN QUI\n" + storia.joined(separator: "\n"))
        }
        let numero = turni.count
        if numero == 0 {
            parti.append("COMPITO: è il primo turno. giudizio \"nessuno\", motivo e replica \"\", convinta \(difficolta.convinzioneIniziale); scrivi la prima obiezione (1 di \(obiezioni)) e tre suggerite per il consulente.")
        } else if numero < obiezioni {
            parti.append("COMPITO: il consulente ha appena risposto all'obiezione \(numero) di \(obiezioni). Giudica la sua risposta, scrivi la tua replica, aggiorna la convinzione, poi scrivi l'obiezione \(numero + 1) di \(obiezioni) con tre suggerite.")
        } else {
            parti.append("COMPITO: il consulente ha appena risposto all'ultima obiezione (\(numero) di \(obiezioni)). Giudica la sua risposta, scrivi la tua replica finale e la convinzione; prossimaObiezione \"\" e suggerite [].")
        }
        return [MessaggioModello(ruolo: .sistema, testo: istruzioni),
                MessaggioModello(ruolo: .utente, testo: parti.joined(separator: "\n\n"))]
    }

    /// Le cifre che Vera può scrivere in questo turno: quelle della scheda e quelle dette dal consulente.
    static func cifreAmmesse(scheda: SchedaRecita, turni: [TurnoPalestra]) -> String {
        ([scheda.testo] + turni.compactMap(\.risposta)).joined(separator: "\n")
    }

    // MARK: - Lettura della risposta

    enum Lettura: Equatable {
        case valida(RispostaPalestra)
        case scartata(String)
    }

    /// Legge il JSON di Qwen (anche tra altre parole o tra ```). `primo`: il primo turno (niente replica da leggere);
    /// `ultimo`: dopo l'ultima obiezione (niente obiezione nuova). Scarta un JSON illeggibile, una replica o
    /// un'obiezione con cifre che non stanno in `ammesse`; toglie le suggerite con cifre inventate.
    static func leggi(_ testo: String, ammesse: String, primo: Bool, ultimo: Bool) -> Lettura {
        guard let inizio = testo.firstIndex(of: "{"), let fine = testo.lastIndex(of: "}"), inizio < fine,
              let d = String(testo[inizio...fine]).data(using: .utf8),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else {
            return .scartata("La risposta di Vera non era un JSON leggibile.")
        }
        func stringa(_ k: String) -> String { ((j[k] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
        let replica = stringa("replica")
        let obiezione = stringa("prossimaObiezione")
        if !primo && replica.isEmpty { return .scartata("Manca la replica del cliente.") }
        if !ultimo && obiezione.isEmpty { return .scartata("Manca l'obiezione del cliente.") }
        for t in [replica, ultimo ? "" : obiezione] where !t.isEmpty {
            if !CommentoVera.numeriConservati(bozza: ammesse, testo: t) {
                return .scartata("Vera ha scritto una cifra che non viene da Prisma.")
            }
        }
        var suggerite: [String] = []
        if !ultimo {
            for s in (j["suggerite"] as? [Any]) ?? [] {
                guard let t = (s as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty,
                      !suggerite.contains(t), CommentoVera.numeriConservati(bozza: ammesse, testo: t) else { continue }
                suggerite.append(t)
                if suggerite.count == Self.suggerite { break }
            }
        }
        var convinta: Int?
        if let n = j["convinta"] as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() {
            convinta = min(100, max(0, Int(n.doubleValue.rounded())))
        }
        return .valida(RispostaPalestra(giudizio: GiudizioPalestra(rawValue: stringa("giudizio").lowercased()),
                                        motivo: stringa("motivo"), replica: primo ? "" : replica, convinta: convinta,
                                        prossimaObiezione: ultimo ? nil : obiezione, suggerite: suggerite,
                                        strumento: StrumentoPalestra(rawValue: stringa("strumento"))))
    }

    /// Un turno con Qwen: chiede, legge e, se la risposta è da scartare, richiede una volta dicendo perché.
    /// `aggiorna` riceve la replica (o l'obiezione, al primo turno) mentre si scrive.
    static func turno(motore: MotoreLocale, vera: ImpostazioniVera, scheda: SchedaRecita, difficolta: DifficoltaPalestra,
                      turni: [TurnoPalestra], aggiorna: ((String) -> Void)? = nil) async throws -> RispostaPalestra {
        let primo = turni.isEmpty
        let ultimo = turni.count >= obiezioni
        var messaggi = Self.messaggi(scheda: scheda, difficolta: difficolta, turni: turni)
        let ammesse = cifreAmmesse(scheda: scheda, turni: turni)
        var motivo = ""
        for _ in 0..<tentativi {
            try Task.checkCancellation()
            let r = try await motore.scrivi(messaggi, opzioni: opzioni(vera)) { p in
                if let aggiorna, let t = campoParziale(p.testo, chiave: primo ? "prossimaObiezione" : "replica") { aggiorna(t) }
            }
            switch leggi(r.testo, ammesse: ammesse, primo: primo, ultimo: ultimo) {
            case .valida(let risposta):
                return risposta
            case .scartata(let m):
                motivo = m
                aggiorna?("")
                if let u = messaggi.last {
                    messaggi[messaggi.count - 1].testo = u.testo + "\n\nATTENZIONE: la risposta di prima è stata scartata (\(m)) Rispondi solo con il JSON dello schema e usa solo le cifre della scheda."
                }
            }
        }
        throw ErroreVera(messaggio: motivo + " Vera non è riuscita a recitare il turno: riprova.")
    }

    /// Il valore di una chiave di testo del JSON mentre arriva (`"replica":"Ah, quindi…` → «Ah, quindi…»).
    static func campoParziale(_ testo: String, chiave: String) -> String? {
        guard let k = testo.range(of: "\"\(chiave)\"") else { return nil }
        var resto = testo[k.upperBound...].drop { $0 == " " || $0 == ":" || $0 == "\n" }
        guard resto.first == "\"" else { return nil }
        resto = resto.dropFirst()
        var uscita = ""
        var fuga = false
        for ch in resto {
            if fuga {
                uscita.append(ch == "n" ? " " : ch)
                fuga = false
            } else if ch == "\\" {
                fuga = true
            } else if ch == "\"" {
                break
            } else {
                uscita.append(ch)
            }
        }
        return uscita
    }

    // MARK: - Il giudizio di Prisma

    /// Pressione, scadenze inventate, promesse di rendimento e critiche: sempre «debole».
    static let pressione = #"vale solo fino a|solo fino a (lunedi|martedi|mercoledi|giovedi|venerdi|sabato|domenica|domani|fine mese)|ultim[ie] giorn|ultima occasione|scade (oggi|domani|a breve)|(firmi|firmiamo|decida|decidiamo) (subito|oggi|adesso|ora)|deve decidere (subito|oggi|adesso|ora)|non ci saranno piu|dopo sara tardi|offerta limitata"#
    static let promesse = #"garantit|rendimento sicuro|senza (alcun )?rischi|non (puo|potra|si puo) perdere|zero rischi|sicuro al cento|guadagno certo"#
    static let critiche = #"pensano solo a (loro|se)|le banche (rubano|ti fregano|la fregano)|sono (dei )?ladri"#
    /// Le parole che dicono che il consulente fa vedere qualcosa con Prisma.
    static let strumenti = #"linea della vita|lancia l.anno|film del piano|prova del fuoco|simulaz|grafico|prospetto|guardiamo insieme|le faccio vedere|le preparo|vediamo insieme|scenario|scenari"#

    /// Il giudizio più alto che le regole di Prisma concedono, con il motivo quando abbassano.
    static func giudizioRegole(_ risposta: String, scheda: SchedaRecita, ammesse: String) -> (massimo: GiudizioPalestra, motivo: String?) {
        let t = NucleoVera.semplice(risposta).lowercased()
        if DateItaliane.cerca(pressione, t) != nil {
            return (.debole, "Mette fretta: in una trattativa vera la pressione fa perdere la fiducia.")
        }
        if DateItaliane.cerca(promesse, t) != nil {
            return (.debole, "Promette un rendimento o l'assenza di rischi: non si può.")
        }
        if DateItaliane.cerca(critiche, t) != nil {
            return (.debole, "Critica gli altri invece di spiegare il piano.")
        }
        let parole = t.split { !$0.isLetter && !$0.isNumber }.count
        let cifre = risposta.range(of: #"\d"#, options: .regularExpression) != nil
        let strumento = DateItaliane.cerca(strumenti, t) != nil
        let sue = parolePersonali(scheda).contains { t.contains($0) }
        if !cifre && !strumento && !sue {
            if parole < 8 { return (.debole, "Generica: non risponde al suo timore.") }
            return (.buona, "Chiara, ma senza i suoi numeri né il suo obiettivo.")
        }
        if cifre && !CommentoVera.numeriConservati(bozza: ammesse, testo: risposta) {
            return (.buona, "Usa una cifra che Prisma non ha calcolato: in una trattativa vera va verificata.")
        }
        return (.ottima, nil)
    }

    /// Le parole dell'obiettivo e dei timori del cliente (almeno 5 lettere): se la risposta le riprende, ascolta.
    static func parolePersonali(_ s: SchedaRecita) -> [String] {
        let testo = NucleoVera.semplice([s.obiettivo, s.timori].compactMap { $0 }.joined(separator: " ")).lowercased()
        let vuote: Set<String> = ["anche", "sono", "della", "delle", "degli", "nella", "entro", "quello", "questo", "perdere", "solo", "parte"]
        return Array(Set(testo.split { !$0.isLetter }.map(String.init).filter { $0.count >= 5 && !vuote.contains($0) }))
    }

    /// Il giudizio finale: il più prudente fra regole e Qwen (senza giudizio di Qwen, al massimo «buona»).
    static func giudizioFinale(regole: GiudizioPalestra, qwen: GiudizioPalestra?) -> GiudizioPalestra {
        GiudizioPalestra.prudente(regole, qwen ?? .buona)
    }

    /// La convinzione dopo un turno: quella di Qwen, ma senza salti più grandi del passo della difficoltà.
    static func convinzione(precedente: Int, proposta: Int?, difficolta: DifficoltaPalestra) -> Int {
        guard let p = proposta else { return precedente }
        let passo = difficolta.passoMassimo
        return min(100, max(0, min(precedente + passo, max(precedente - passo, p))))
    }

    /// Il punteggio indicativo (0-100): somma dei punti su 3 per obiezione.
    static func punteggio(_ giudizi: [GiudizioPalestra], obiezioni n: Int = obiezioni) -> Int {
        let massimo = 3 * max(n, 1)
        let somma = giudizi.reduce(0) { $0 + $1.punti }
        return min(100, max(0, Int((Double(somma) / Double(massimo) * 100).rounded())))
    }

    /// Il titolo della fine: dalla convinzione del cliente.
    static func fraseFinale(convinta: Int, scheda: SchedaRecita, ultimaReplica: String?) -> String {
        if convinta >= sogliaConvinta, let r = ultimaReplica, !r.isEmpty {
            return "\(scheda.nomeBreve) ha detto: «\(r.trimmingCharacters(in: CharacterSet(charactersIn: "«»\" .")))»."
        }
        return convinta >= sogliaConvinta ? "\(scheda.nomeBreve) è più vicino al sì." : "Con \(scheda.nomeBreve) resta qualche dubbio."
    }

    /// «Cosa potevi usare»: gli strumenti indicati da Vera nei turni, altrimenti quelli del template.
    static func strumentiDaUsare(_ indicati: [StrumentoPalestra]) -> [StrumentoPalestra] {
        var r: [StrumentoPalestra] = []
        for s in indicati where !r.contains(s) { r.append(s) }
        return r.isEmpty ? StrumentoPalestra.predefiniti : r
    }
}
