import Foundation

// «Il tagliando dei dati» (Vera/BRIEF.md, funzione 5; template «Il tagliando dei dati»): il controllo dell'archivio.
// Solo codice (regola 5 «Prima il codice»): doppioni di clienti, campi vuoti, consensi, riesame, questionario prima di un
// incontro, documento d'identità e posizioni scadute. Le scadenze di conformità le calcola MotoreConformita (stesse regole
// di «In regola»); qui si scelgono la gravità, il testo e la correzione. Qwen non serve: i testi sono fissi.
//
// Quando gira: di notte (alle 2:10, con Prisma aperto sul Mac sempre acceso); se una notte salta, alla prima apertura del
// giorno (`dovuto`). Ogni correzione è una proposta: un'AzioneConferma da mostrare nella scheda «Conferma» oppure una
// destinazione da aprire. Il motore non esegue niente e non cancella niente: «Unisci le schede» resta una proposta e la
// scheda doppia non si elimina mai da sola (regola 2).
//
// Il punteggio di salute (0-100). Ogni scheda cliente parte da 100 e perde, per ogni voce che la riguarda:
//   rosso 40 · arancio 20 · neutro 4 (i campi vuoti 4 per campo, al massimo 12)
// fino a 0. La salute dell'archivio è la media delle schede, arrotondata; senza clienti è 100. Così due voci rosse sulla
// stessa scheda la portano a 20, e la stessa voce pesa meno in un archivio grande che in uno piccolo. Le voci che il
// consulente ha segnato «Va bene così» (`ignorate`) non contano.

// MARK: - Modelli salvati (entreranno nell'archivio)

/// Quando gira il tagliando (Impostazioni › Vera). Letto con tolleranza.
struct ImpostazioniTagliando: Codable, Equatable {
    /// Il controllo notturno è acceso.
    var attivo = true
    /// L'ora del controllo notturno (0-23) e i minuti (0-59): di base le 2:10.
    var ora = 2
    var minuto = 10

    init() {}

    private enum CodingKeys: String, CodingKey { case attivo, ora, minuto }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let base = ImpostazioniTagliando()
        attivo = (try? c.decodeIfPresent(Bool.self, forKey: .attivo)) ?? base.attivo
        ora = min(23, max(0, (try? c.decodeIfPresent(Int.self, forKey: .ora)) ?? base.ora))
        minuto = min(59, max(0, (try? c.decodeIfPresent(Int.self, forKey: .minuto)) ?? base.minuto))
    }
}

/// Il risultato di un controllo, in breve: per «Controllate stanotte alle 2:10 · 6 cose da sistemare».
struct RegistroTagliando: Codable, Equatable {
    var data: Date
    var salute: Int
    var schede: Int
    var rosse: Int
    var arancioni: Int
    var neutre: Int
    /// Gli id delle voci trovate (per dire cosa è nuovo rispetto al controllo prima).
    var voci: [String]

    init(data: Date, salute: Int, schede: Int, rosse: Int, arancioni: Int, neutre: Int, voci: [String]) {
        self.data = data
        self.salute = salute
        self.schede = schede
        self.rosse = rosse
        self.arancioni = arancioni
        self.neutre = neutre
        self.voci = voci
    }

    var daSistemare: Int { rosse + arancioni + neutre }

    private enum CodingKeys: String, CodingKey { case data, salute, schede, rosse, arancioni, neutre, voci }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = try c.decode(Date.self, forKey: .data)
        salute = min(100, max(0, (try? c.decodeIfPresent(Int.self, forKey: .salute)) ?? 100))
        schede = (try? c.decodeIfPresent(Int.self, forKey: .schede)) ?? 0
        rosse = (try? c.decodeIfPresent(Int.self, forKey: .rosse)) ?? 0
        arancioni = (try? c.decodeIfPresent(Int.self, forKey: .arancioni)) ?? 0
        neutre = (try? c.decodeIfPresent(Int.self, forKey: .neutre)) ?? 0
        voci = (try? c.decodeIfPresent([String].self, forKey: .voci)) ?? []
    }
}

/// Lo stato del tagliando da salvare: l'ultimo controllo e le voci segnate «Va bene così».
struct StatoTagliando: Codable, Equatable {
    /// L'ultimo controllo fatto (per `TagliandoVera.dovuto`).
    var ultimoControllo: Date?
    var ultimo: RegistroTagliando?
    /// Gli id delle voci che il consulente ha segnato «Va bene così»: non tornano finché la situazione non cambia (l'id
    /// contiene i dati che la descrivono: date, campi, stato).
    var ignorate: [String] = []

    init() {}

    private enum CodingKeys: String, CodingKey { case ultimoControllo, ultimo, ignorate }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ultimoControllo = (try? c.decodeIfPresent(Date.self, forKey: .ultimoControllo)) ?? nil
        ultimo = (try? c.decodeIfPresent(RegistroTagliando.self, forKey: .ultimo)) ?? nil
        ignorate = (try? c.decodeIfPresent([String].self, forKey: .ignorate)) ?? []
    }
}

// MARK: - Le voci

/// Dove porta una correzione che non è un'azione da confermare.
enum DestinazioneTagliando: Equatable {
    enum Sezione: String { case anagrafica, inRegola, documenti }
    /// La scheda del cliente, sulla sezione giusta.
    case scheda(clienteId: String, sezione: Sezione)
    /// Una posizione in Posizioni.
    case posizione(id: String)
}

/// La correzione proposta per una voce: un'azione da confermare o un posto da aprire.
enum CorrezioneTagliando: Equatable {
    case conferma(etichetta: String, azione: AzioneConferma)
    case naviga(etichetta: String, destinazione: DestinazioneTagliando)

    /// Il testo del pulsante («Unisci le schede», «Prepara il rinnovo»…).
    var etichetta: String {
        switch self {
        case .conferma(let e, _), .naviga(let e, _): return e
        }
    }

    var azione: AzioneConferma? {
        if case .conferma(_, let a) = self { return a }
        return nil
    }
}

/// Una cosa da sistemare nell'archivio.
struct VoceTagliando: Identifiable, Equatable {
    enum Gravita: Int, Comparable, CaseIterable {
        case rosso, arancio, neutro
        static func < (a: Gravita, b: Gravita) -> Bool { a.rawValue < b.rawValue }
    }

    /// L'ordine dei casi è quello dell'elenco a parità di gravità.
    enum Tipo: String, CaseIterable {
        case privacy, riesame, questionario, verifica, documentoIdentita, documentoNuovo, doppione, posizioneScaduta
        case commerciale, campiVuoti, datoDaControllare
    }

    /// Stabile tra un controllo e l'altro finché la situazione non cambia (per «Va bene così»).
    let id: String
    let tipo: Tipo
    let gravita: Gravita
    let titolo: String
    /// «Sofia Romano · dal 2 settembre: niente nuove proposte finché non lo rinnovi».
    let dettaglio: String
    /// I clienti interessati (due per un doppione).
    let clienti: [String]
    let correzione: CorrezioneTagliando?
    /// Quanto toglie alla salute di ogni scheda interessata.
    let peso: Int

    var clienteId: String? { clienti.first }
}

/// Il risultato del tagliando.
struct EsitoTagliando {
    let oggi: Date
    /// Le schede controllate (i clienti dell'archivio).
    let schede: Int
    /// Le voci da sistemare: per gravità, poi per tipo, poi per nome del cliente.
    let voci: [VoceTagliando]
    /// Le voci trovate ma segnate «Va bene così» (non contano nel punteggio).
    let ignorate: [VoceTagliando]
    /// La salute dell'archivio, 0-100 (formula in testa al file).
    let salute: Int
    /// La salute di ogni scheda (id del cliente → 0-100).
    let saluteSchede: [String: Int]

    var rosse: [VoceTagliando] { voci.filter { $0.gravita == .rosso } }
    var arancioni: [VoceTagliando] { voci.filter { $0.gravita == .arancio } }
    var neutre: [VoceTagliando] { voci.filter { $0.gravita == .neutro } }
    var inOrdine: Bool { voci.isEmpty }

    /// Le voci di un cliente.
    func voci(cliente id: String) -> [VoceTagliando] { voci.filter { $0.clienti.contains(id) } }

    /// Le azioni da confermare di «Sistema tutto» (le voci che portano a una schermata restano fuori).
    var azioni: [AzioneConferma] { voci.compactMap { $0.correzione?.azione } }

    /// Il riassunto da salvare.
    var registro: RegistroTagliando {
        RegistroTagliando(data: oggi, salute: salute, schede: schede, rosse: rosse.count, arancioni: arancioni.count,
                          neutre: neutre.count, voci: voci.map(\.id))
    }
}

// MARK: - Il motore

enum TagliandoVera {
    static let pesoRosso = 40
    static let pesoArancio = 20
    static let pesoNeutro = 4
    static let pesoMassimoCampi = 12
    /// Quanto avanti si guarda l'agenda per il questionario prima di un incontro.
    static let giorniIncontro = 14

    /// I nomi degli strumenti nuovi che il tagliando propone (da aggiungere all'esecutore di FalloTuShell): unire due
    /// schede (la doppia non si cancella), completare un dato dell'anagrafica letto da un documento, registrare un
    /// documento d'identità letto in Documenti.
    static let strumentoUnisci = "clienti_unisci_schede"
    static let strumentoCompleta = "cliente_completa_dati"
    static let strumentoDocumento = "cliente_aggiorna_documento"

    // MARK: È dovuto adesso?

    /// L'ultimo appuntamento notturno passato (o di adesso): oggi all'ora scelta se è già passata, altrimenti ieri.
    /// Nel giorno del cambio d'ora, se l'ora non esiste (le 2:10 di fine marzo) vale la prima ora valida dopo.
    static func ultimoTurno(prima adesso: Date, impostazioni: ImpostazioniTagliando = ImpostazioniTagliando(),
                            calendario cal: Calendar = .current) -> Date {
        let oggi = turno(del: adesso, impostazioni, cal)
        if oggi <= adesso { return oggi }
        let ieri = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: adesso)) ?? adesso
        return turno(del: ieri, impostazioni, cal)
    }

    /// Il prossimo appuntamento notturno dopo `adesso` (per programmare il controllo).
    static func prossimoTurno(dopo adesso: Date, impostazioni: ImpostazioniTagliando = ImpostazioniTagliando(),
                              calendario cal: Calendar = .current) -> Date {
        let oggi = turno(del: adesso, impostazioni, cal)
        if oggi > adesso { return oggi }
        let domani = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: adesso)) ?? adesso
        return turno(del: domani, impostazioni, cal)
    }

    /// Il tagliando è dovuto adesso: acceso, e nessun controllo dall'ultimo appuntamento notturno. Di notte scatta
    /// all'ora scelta; se quella notte Prisma era chiuso, scatta alla prima apertura del giorno. Un ultimo controllo nel
    /// futuro (orologio spostato indietro) non blocca: il controllo si rifà.
    static func dovuto(ultimo: Date?, adesso: Date, impostazioni: ImpostazioniTagliando = ImpostazioniTagliando(),
                       calendario cal: Calendar = .current) -> Bool {
        guard impostazioni.attivo else { return false }
        guard let ultimo else { return true }
        if ultimo > adesso { return true }
        return ultimo < ultimoTurno(prima: adesso, impostazioni: impostazioni, calendario: cal)
    }

    private static func turno(del giorno: Date, _ i: ImpostazioniTagliando, _ cal: Calendar) -> Date {
        let inizio = cal.startOfDay(for: giorno)
        if let d = cal.date(bySettingHour: i.ora, minute: i.minuto, second: 0, of: inizio), cal.isDate(d, inSameDayAs: inizio) { return d }
        var c = DateComponents()
        c.hour = i.ora
        c.minute = i.minuto
        return cal.nextDate(after: inizio, matching: c, matchingPolicy: .nextTime) ?? inizio
    }

    // MARK: Il controllo

    /// Il tagliando di tutto l'archivio.
    static func controlla(_ dati: DatiPrisma, oggi: Date, ignorate: Set<String> = [], calendario: Calendar = .current) -> EsitoTagliando {
        controlla(clienti: dati.clienti, posizioni: dati.posizioni, appuntamenti: dati.appuntamenti, incontri: dati.incontri,
                  documenti: dati.documenti, regole: dati.impostazioni.conformita, oggi: oggi, ignorate: ignorate, calendario: calendario)
    }

    /// Il tagliando a partire dai pezzi dell'archivio.
    static func controlla(clienti: [Cliente], posizioni: [Posizione], appuntamenti: [Appuntamento], incontri: [Incontro],
                          documenti: [Documento], regole: RegoleConformita, oggi: Date, ignorate: Set<String> = [],
                          calendario cal: Calendar = .current) -> EsitoTagliando {
        let posizioniPer = Dictionary(grouping: posizioni, by: \.clienteId)
        let appuntamentiPer = Dictionary(grouping: appuntamenti, by: \.clienteId)
        let incontriPer = Dictionary(grouping: incontri, by: \.clienteId)
        let documentiPer = Dictionary(grouping: documenti, by: \.clienteId)

        var tutte = doppioni(clienti, posizioni: posizioniPer, documenti: documentiPer)
        for c in clienti {
            let pos = posizioniPer[c.id] ?? []
            let app = appuntamentiPer[c.id] ?? []
            let doc = documentiPer[c.id] ?? []
            let esito = MotoreConformita.calcola(cliente: c, posizioni: pos, regole: regole, oggi: oggi, calendario: cal)
            tutte += campi(c, documenti: doc, oggi: oggi, calendario: cal)
            tutte += consensi(c, esito: esito, oggi: oggi, calendario: cal)
            tutte += riesame(c, posizioni: pos, appuntamenti: app, incontri: incontriPer[c.id] ?? [], oggi: oggi, calendario: cal)
            tutte += questionari(c, esito: esito, appuntamenti: app, regole: regole, oggi: oggi, calendario: cal)
            tutte += verifiche(c, esito: esito, oggi: oggi, calendario: cal)
            tutte += documentoIdentita(c, esito: esito, documenti: doc, posizioni: pos, oggi: oggi, calendario: cal)
            tutte += posizioniScadute(c, posizioni: pos, oggi: oggi, calendario: cal)
        }

        let nomi = Dictionary(clienti.map { ($0.id, $0.nome) }, uniquingKeysWith: { a, _ in a })
        let ordine = Dictionary(VoceTagliando.Tipo.allCases.enumerated().map { ($1, $0) }, uniquingKeysWith: { a, _ in a })
        let ordinate = tutte.sorted {
            ($0.gravita.rawValue, ordine[$0.tipo] ?? 0, nomi[$0.clienteId ?? ""] ?? "", $0.id)
                < ($1.gravita.rawValue, ordine[$1.tipo] ?? 0, nomi[$1.clienteId ?? ""] ?? "", $1.id)
        }
        let attive = ordinate.filter { !ignorate.contains($0.id) }
        let scartate = ordinate.filter { ignorate.contains($0.id) }
        let s = salute(clienti: clienti.map(\.id), voci: attive)
        return EsitoTagliando(oggi: oggi, schede: clienti.count, voci: attive, ignorate: scartate, salute: s.archivio, saluteSchede: s.schede)
    }

    /// La salute di ogni scheda e dell'archivio (formula in testa al file).
    static func salute(clienti: [String], voci: [VoceTagliando]) -> (archivio: Int, schede: [String: Int]) {
        var schede: [String: Int] = [:]
        for id in clienti { schede[id] = 100 }
        for v in voci {
            for id in v.clienti where schede[id] != nil { schede[id] = max(0, (schede[id] ?? 100) - v.peso) }
        }
        guard !clienti.isEmpty else { return (100, schede) }
        let somma = clienti.reduce(0) { $0 + (schede[$1] ?? 100) }
        let media = (Double(somma) / Double(clienti.count)).rounded()
        return (min(100, max(0, Int(media))), schede)
    }

    // MARK: Doppioni

    /// Due schede per la stessa persona: stesso codice fiscale, oppure nome simile con lo stesso telefono o la stessa
    /// email. Due codici fiscali scritti e diversi sono due persone, sempre. Le schede doppie della stessa persona
    /// formano un gruppo (anche tre o più): resta una sola scheda principale e ogni altra ha la sua unione verso quella,
    /// mai un'unione tra due schede doppie.
    static func doppioni(_ clienti: [Cliente], posizioni: [String: [Posizione]] = [:], documenti: [String: [Documento]] = [:]) -> [VoceTagliando] {
        var voci: [VoceTagliando] = []
        guard clienti.count > 1 else { return voci }
        // Gruppi (union-find): ogni gruppo ricorda i codici fiscali scritti dei suoi membri, così due persone diverse
        // non finiscono nello stesso gruppo passando per una scheda senza codice fiscale
        var capo = Array(clienti.indices)
        var codici: [Set<String>] = clienti.map { c in
            let cf = codiceFiscale(c.codiceFiscale)
            return cf.isEmpty ? [] : [cf]
        }
        var motivi: [String: String] = [:]
        func radice(_ i: Int) -> Int {
            var r = i
            while capo[r] != r { r = capo[r] }
            var k = i
            while capo[k] != r { let dopo = capo[k]; capo[k] = r; k = dopo }
            return r
        }
        // Prima tutti i motivi diretti, poi i gruppi: una scheda entra in un gruppo solo se somiglia direttamente a
        // ogni sua scheda (legame completo). Così «Marco Bianchi» e «Matteo Bianchi» non finiscono insieme passando
        // per «M. Bianchi», che somiglia a tutti e due
        for i in 0..<(clienti.count - 1) {
            for j in (i + 1)..<clienti.count {
                if let motivo = motivoDoppione(clienti[i], clienti[j]) { motivi["\(i)-\(j)"] = motivo }
            }
        }
        var membri: [[Int]] = clienti.indices.map { [$0] }
        for i in 0..<(clienti.count - 1) {
            for j in (i + 1)..<clienti.count where motivi["\(i)-\(j)"] != nil {
                let ri = radice(i), rj = radice(j)
                guard ri != rj else { continue }
                let insieme = codici[ri].union(codici[rj])
                guard insieme.count <= 1 else { continue }
                let tutti = membri[ri].allSatisfy { x in
                    membri[rj].allSatisfy { y in motivi["\(min(x, y))-\(max(x, y))"] != nil }
                }
                guard tutti else { continue }
                capo[rj] = ri
                codici[ri] = insieme
                membri[ri] += membri[rj]
                membri[rj] = []
            }
        }
        let gruppi = Dictionary(grouping: clienti.indices, by: { radice($0) }).values
            .filter { $0.count > 1 }
            .sorted { ($0.min() ?? 0) < ($1.min() ?? 0) }
        for gruppo in gruppi {
            // Resta la scheda più completa (a parità, la più vecchia; poi la prima dell'elenco)
            let punti = Dictionary(gruppo.map { k -> (Int, Int) in
                let c = clienti[k]
                return (k, completezza(c, posizioni: posizioni[c.id]?.count ?? 0, documenti: documenti[c.id]?.count ?? 0))
            }, uniquingKeysWith: { x, _ in x })
            guard let principale = gruppo.min(by: { x, y in
                let px = punti[x] ?? 0, py = punti[y] ?? 0
                if px != py { return px > py }
                if clienti[x].creatoIl != clienti[y].creatoIl { return clienti[x].creatoIl < clienti[y].creatoIl }
                return x < y
            }) else { continue }
            let resta = clienti[principale]
            for k in gruppo.sorted() where k != principale {
                let doppia = clienti[k]
                let (primo, secondo) = (min(principale, k), max(principale, k))
                // Il motivo diretto della coppia (nel gruppo ogni coppia ne ha uno)
                guard let motivo = motivi["\(primo)-\(secondo)"] else { continue }
                var differenze: [String] = []
                if !resta.telefono.isEmpty, !doppia.telefono.isEmpty, telefono(resta.telefono) != telefono(doppia.telefono) { differenze.append("telefono") }
                if !resta.email.isEmpty, !doppia.email.isEmpty, email(resta.email) != email(doppia.email) { differenze.append("email") }
                let diversi = differenze.isEmpty ? "" : ", \(differenze.joined(separator: " e ")) divers\(differenze.count == 1 ? "o" : "i")"
                let azione = AzioneConferma(
                    strumento: strumentoUnisci, app: .clienti,
                    titolo: "Unisco «\(doppia.nome)» in «\(resta.nome)»",
                    dettaglio: "Resta la scheda di «\(resta.nome)»: posizioni, documenti, appuntamenti e note dell'altra passano qui. La scheda doppia non si cancella: resta in archivio, segnata come unita.",
                    argomenti: ["principale": resta.id, "doppione": doppia.id],
                    avviso: differenze.isEmpty ? nil : "Le due schede hanno \(differenze.joined(separator: " e ")) divers\(differenze.count == 1 ? "o" : "i"): resta quello di «\(resta.nome)», l'altro passa nelle note.")
                let ids = [resta.id, doppia.id].sorted()
                let (a, b) = (clienti[primo], clienti[secondo])
                voci.append(VoceTagliando(
                    id: "doppione-\(ids[0])-\(ids[1])", tipo: .doppione, gravita: .arancio,
                    titolo: "Due schede per la stessa persona",
                    dettaglio: "«\(a.nome)» e «\(b.nome)»: \(motivo)\(diversi)",
                    clienti: [resta.id, doppia.id], correzione: .conferma(etichetta: "Unisci le schede", azione: azione), peso: pesoArancio))
            }
        }
        return voci
    }

    /// Perché due schede sembrano la stessa persona (nil: non lo sono).
    static func motivoDoppione(_ a: Cliente, _ b: Cliente) -> String? {
        let cfA = codiceFiscale(a.codiceFiscale), cfB = codiceFiscale(b.codiceFiscale)
        if !cfA.isEmpty, !cfB.isEmpty { return cfA == cfB ? "stesso codice fiscale" : nil }
        guard nomiSimili(a.nome, b.nome) else { return nil }
        let ta = telefono(a.telefono), tb = telefono(b.telefono)
        if ta.count >= 6, ta == tb { return "nome simile e stesso telefono" }
        let ea = email(a.email), eb = email(b.email)
        if ea.contains("@"), ea == eb { return "nome simile e stessa email" }
        return nil
    }

    /// Quanto è completa una scheda (per scegliere quella che resta).
    static func completezza(_ c: Cliente, posizioni: Int = 0, documenti: Int = 0) -> Int {
        let campi = [!c.codiceFiscale.isEmpty, !c.email.isEmpty, !c.telefono.isEmpty, c.dataNascita != nil, !c.indirizzo.isEmpty,
                     !c.professione.isEmpty, c.consensi.privacy, c.conformita != nil].filter { $0 }.count
        return campi + 2 * posizioni + documenti
    }

    /// «Marco Bianchi» e «M. Bianchi», «Bianchi Marco», «Marco Bianci»: simili. «Elena Bianchi» e «Marco Bianchi» no.
    static func nomiSimili(_ a: String, _ b: String) -> Bool {
        let pa = parole(a), pb = parole(b)
        guard !pa.isEmpty, !pb.isEmpty else { return false }
        if pa.sorted() == pb.sorted() { return true }
        let (corte, lunghe) = pa.count <= pb.count ? (pa, pb) : (pb, pa)
        // Ogni parola della più corta si ritrova nell'altra, intera o come iniziale; almeno una intera e lunga
        var usate = Set<Int>()
        var intere = 0
        for p in corte {
            // L'iniziale vale nei due versi: «S. Romano» e «Sofia Romano» hanno lo stesso numero di parole
            guard let k = lunghe.indices.first(where: { !usate.contains($0) && (lunghe[$0] == p || (p.count == 1 && lunghe[$0].hasPrefix(p))
                                                                                || (lunghe[$0].count == 1 && p.hasPrefix(lunghe[$0]))) })
            else { usate = []; intere = -1; break }
            usate.insert(k)
            if lunghe[k] == p, p.count >= 3 { intere += 1 }
        }
        if intere > 0 { return true }
        // Un errore di battitura: al massimo due lettere diverse su nomi non troppo corti. Ma non tra due nomi che
        // cambiano solo nella vocale finale (Mario e Maria, Giulio e Giulia, Francesco e Francesca): sono due persone
        // della stessa famiglia, spesso con lo stesso telefono di casa
        if pa.contains(where: { x in !pb.contains(x) && pb.contains { y in !pa.contains(y) && varianteFinale(x, y) } }) { return false }
        // Parola per parola, mai sulla stringa intera: «Luca Bianchi» e «Lucia Bianchi» distano una lettera ma sono due
        // persone. Stesso numero di parole, almeno una uguale, e una sola parola con un refuso (vedi `refuso`)
        guard pa.count == pb.count else { return false }
        var restoA: [String] = [], restoB = pb
        for x in pa {
            if let k = restoB.firstIndex(of: x) { restoB.remove(at: k) } else { restoA.append(x) }
        }
        let uguali = pa.filter { x in !restoA.contains(x) && x.count >= 3 }.count
        guard uguali >= 1, restoA.count == 1, restoB.count == 1 else { return false }
        return refuso(restoA[0], restoB[0])
    }

    /// Un errore di battitura in una parola: una sola lettera diversa, parole di almeno 5 lettere, nessuna delle due
    /// contenuta nell'altra (Gianni e Giannina) e non solo la vocale finale (Mario e Maria). Luca e Lucia, Rita e Rosa: no.
    static func refuso(_ a: String, _ b: String) -> Bool {
        guard a != b, min(a.count, b.count) >= 5, !a.contains(b), !b.contains(a), !varianteFinale(a, b) else { return false }
        return distanza(a, b) <= 1
    }

    /// Due parole uguali tranne la vocale finale («mario» e «maria», «rossi» e «rosso»).
    static func varianteFinale(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count, a.count >= 3, a != b, let fa = a.last, let fb = b.last else { return false }
        let vocali: Set<Character> = ["a", "e", "i", "o", "u"]
        return vocali.contains(fa) && vocali.contains(fb) && a.dropLast() == b.dropLast()
    }

    static func parole(_ nome: String) -> [String] {
        nome.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT"))
            .split { !$0.isLetter }.map(String.init)
    }

    /// La distanza di Levenshtein (nomi brevi: costo trascurabile).
    static func distanza(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        guard !x.isEmpty else { return y.count }
        guard !y.isEmpty else { return x.count }
        var prima = Array(0...y.count)
        for i in 1...x.count {
            var riga = [i] + Array(repeating: 0, count: y.count)
            for j in 1...y.count {
                riga[j] = min(prima[j] + 1, riga[j - 1] + 1, prima[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1))
            }
            prima = riga
        }
        return prima[y.count]
    }

    /// Solo le cifre, senza il prefisso italiano (+39 / 0039).
    static func telefono(_ s: String) -> String {
        var c = s.filter(\.isNumber)
        if c.hasPrefix("0039"), c.count >= 12 { c.removeFirst(4) } else if c.hasPrefix("39"), c.count >= 11, s.contains("+") || c.count == 12 { c.removeFirst(2) }
        return c
    }

    static func email(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    static func codiceFiscale(_ s: String) -> String { s.uppercased().filter { $0.isLetter || $0.isNumber } }

    /// 16 caratteri (persona) o 11 cifre (società).
    static func codiceFiscaleValido(_ s: String) -> Bool {
        let c = codiceFiscale(s)
        if c.count == 11 { return c.allSatisfy(\.isNumber) }
        guard c.count == 16 else { return false }
        return DateItaliane.cerca(#"^[A-Z]{6}[0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{3}[A-Z]$"#, c) != nil
    }

    static func emailValida(_ s: String) -> Bool {
        DateItaliane.cerca(#"^[^@\s]+@[^@\s]+\.[a-z]{2,}$"#, email(s)) != nil
    }

    // MARK: Campi vuoti e dati da controllare

    /// I campi dell'anagrafica che il tagliando guarda, nell'ordine dei testi.
    enum Campo: String, CaseIterable {
        case codiceFiscale, email, telefono, dataNascita, indirizzo
        var nome: String {
            switch self {
            case .codiceFiscale: return "codice fiscale"
            case .email: return "email"
            case .telefono: return "telefono"
            case .dataNascita: return "data di nascita"
            case .indirizzo: return "indirizzo"
            }
        }
    }

    static func vuoti(_ c: Cliente) -> [Campo] {
        Campo.allCases.filter { campo in
            switch campo {
            case .codiceFiscale: return c.codiceFiscale.trimmingCharacters(in: .whitespaces).isEmpty
            case .email: return c.email.trimmingCharacters(in: .whitespaces).isEmpty
            case .telefono: return c.telefono.trimmingCharacters(in: .whitespaces).isEmpty
            case .dataNascita: return c.dataNascita == nil
            case .indirizzo: return c.indirizzo.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
    }

    /// Il codice fiscale del cliente letto nei suoi documenti (il più recente, solo se scritto bene).
    static func codiceFiscaleDaiDocumenti(_ documenti: [Documento]) -> (valore: String, documento: Documento, confermato: Bool)? {
        for d in documenti.sorted(by: { $0.importatoIl > $1.importatoIl }) {
            guard let campo = d.campo(.codiceFiscale), codiceFiscaleValido(campo.valore) else { continue }
            return (codiceFiscale(campo.valore), d, campo.confermato)
        }
        return nil
    }

    private static func campi(_ c: Cliente, documenti: [Documento], oggi: Date, calendario cal: Calendar) -> [VoceTagliando] {
        var voci: [VoceTagliando] = []
        let mancano = vuoti(c)
        if !mancano.isEmpty {
            let elenco = mancano.map(\.nome)
            let testo = elenco.count == 1 ? elenco[0] : elenco.dropLast().joined(separator: ", ") + " e " + (elenco.last ?? "")
            var correzione = CorrezioneTagliando.naviga(etichetta: "Completa la scheda", destinazione: .scheda(clienteId: c.id, sezione: .anagrafica))
            if mancano.contains(.codiceFiscale), let trovato = codiceFiscaleDaiDocumenti(documenti) {
                let azione = AzioneConferma(
                    strumento: strumentoCompleta, app: .clienti, titolo: "Completo la scheda di \(c.nome)",
                    dettaglio: "Codice fiscale \(trovato.valore) · letto in «\(trovato.documento.titolo)»",
                    argomenti: ["cliente": c.id, "campo": Campo.codiceFiscale.rawValue, "valore": trovato.valore, "documento": trovato.documento.id],
                    avviso: trovato.confermato ? nil : "Il dato letto nel documento non è ancora confermato: controllalo prima.")
                correzione = .conferma(etichetta: "Completa dai documenti", azione: azione)
            }
            voci.append(VoceTagliando(
                id: "campi-\(c.id)-\(mancano.map(\.rawValue).joined(separator: ","))", tipo: .campiVuoti, gravita: .neutro,
                titolo: "Campi vuoti", dettaglio: "\(c.nome) · senza \(testo)", clienti: [c.id], correzione: correzione,
                peso: min(pesoMassimoCampi, pesoNeutro * mancano.count)))
        }
        var sbagliati: [String] = []
        if !mancano.contains(.codiceFiscale), !codiceFiscaleValido(c.codiceFiscale) { sbagliati.append("il codice fiscale") }
        if !mancano.contains(.email), !emailValida(c.email) { sbagliati.append("l'email") }
        if !mancano.contains(.telefono), c.telefono.filter(\.isNumber).count < 6 { sbagliati.append("il telefono") }
        if let n = c.dataNascita, n > oggi { sbagliati.append("la data di nascita") }
        if !sbagliati.isEmpty {
            let testo = sbagliati.count == 1 ? sbagliati[0] : sbagliati.dropLast().joined(separator: ", ") + " e " + (sbagliati.last ?? "")
            voci.append(VoceTagliando(
                id: "controllo-\(c.id)-\(sbagliati.count)-\(c.codiceFiscale)|\(c.email)|\(c.telefono)", tipo: .datoDaControllare, gravita: .neutro,
                titolo: "Dati da controllare", dettaglio: "\(c.nome) · da controllare \(testo)",
                clienti: [c.id], correzione: .naviga(etichetta: "Controlla la scheda", destinazione: .scheda(clienteId: c.id, sezione: .anagrafica)),
                peso: pesoNeutro))
        }
        return voci
    }

    // MARK: Consensi

    private static func consensi(_ c: Cliente, esito: EsitoConformita, oggi: Date, calendario cal: Calendar) -> [VoceTagliando] {
        var voci: [VoceTagliando] = []
        if let p = esito.voce(.privacy) {
            switch p.stato {
            case .mancante:
                voci.append(VoceTagliando(
                    id: "privacy-\(c.id)-mancante", tipo: .privacy, gravita: .rosso, titolo: "Consenso privacy mancante",
                    dettaglio: "\(c.nome) · niente nuove proposte finché non lo raccogli",
                    clienti: [c.id], correzione: attivita(c, "Raccogliere il consenso privacy di \(c.nome)", entro: piu(7, oggi, cal),
                                                           etichetta: "Prepara il consenso", oggi: oggi, calendario: cal), peso: pesoRosso))
            case .scaduta:
                let dal = p.scadenza.map { " · dal \(TestiConformita.data($0))" } ?? ""
                voci.append(VoceTagliando(
                    id: "privacy-\(c.id)-scaduta-\(giorno(p.scadenza, cal))", tipo: .privacy, gravita: .rosso, titolo: "Consenso privacy scaduto",
                    dettaglio: "\(c.nome)\(dal): niente nuove proposte finché non lo rinnovi",
                    clienti: [c.id], correzione: attivita(c, "Rinnovare il consenso privacy di \(c.nome)", entro: piu(7, oggi, cal),
                                                           etichetta: "Prepara il rinnovo", oggi: oggi, calendario: cal), peso: pesoRosso))
            case .entro30:
                let dal = p.scadenza.map { " dal \(TestiConformita.data($0))" } ?? ""
                voci.append(VoceTagliando(
                    id: "privacy-\(c.id)-entro30-\(giorno(p.scadenza, cal))", tipo: .privacy, gravita: .arancio, titolo: "Informativa privacy da riconsegnare",
                    dettaglio: "\(c.nome) · vale la nuova informativa\(dal)",
                    clienti: [c.id], correzione: attivita(c, "Consegnare a \(c.nome) la nuova informativa privacy", entro: p.scadenza ?? piu(7, oggi, cal),
                                                           etichetta: "Prepara il rinnovo", oggi: oggi, calendario: cal), peso: pesoArancio))
            default: break
            }
        }
        if let k = esito.voce(.commerciale) {
            switch k.stato {
            case .scaduta:
                let dal = k.scadenza.map { " · scaduto il \(TestiConformita.data($0))" } ?? ""
                voci.append(VoceTagliando(
                    id: "commerciale-\(c.id)-scaduta-\(giorno(k.scadenza, cal))", tipo: .commerciale, gravita: .arancio,
                    titolo: "Consenso commerciale scaduto", dettaglio: "\(c.nome)\(dal): niente comunicazioni promozionali finché non lo riconferma",
                    clienti: [c.id], correzione: attivita(c, "Chiedere a \(c.nome) di riconfermare il consenso commerciale", entro: piu(14, oggi, cal),
                                                           etichetta: "Chiedi la conferma", oggi: oggi, calendario: cal), peso: pesoArancio))
            case .mancante:
                voci.append(VoceTagliando(
                    id: "commerciale-\(c.id)-senzadata", tipo: .commerciale, gravita: .neutro,
                    titolo: "Consenso commerciale senza data", dettaglio: "\(c.nome) · il consenso c'è ma non si sa quando è stato dato",
                    clienti: [c.id], correzione: .naviga(etichetta: "Scrivi la data", destinazione: .scheda(clienteId: c.id, sezione: .inRegola)), peso: pesoNeutro))
            case .entro30:
                voci.append(VoceTagliando(
                    id: "commerciale-\(c.id)-entro30-\(giorno(k.scadenza, cal))", tipo: .commerciale, gravita: .neutro,
                    titolo: "Consenso commerciale in scadenza", dettaglio: "\(c.nome) · \(TestiConformita.inScadenza(k))",
                    clienti: [c.id], correzione: attivita(c, "Chiedere a \(c.nome) di riconfermare il consenso commerciale", entro: k.scadenza ?? piu(14, oggi, cal),
                                                           etichetta: "Chiedi la conferma", oggi: oggi, calendario: cal), peso: pesoNeutro))
            default: break
            }
        }
        return voci
    }

    // MARK: Riesame

    /// L'ultimo contatto con il cliente: appuntamenti e incontri prima di oggi.
    static func ultimoContatto(appuntamenti: [Appuntamento], incontri: [Incontro], oggi: Date) -> Date? {
        (appuntamenti.filter { $0.inizio < oggi && $0.tipo != .nonDisponibile }.map(\.inizio) + incontri.filter { $0.data < oggi }.map(\.data)).max()
    }

    /// Riesame oltre i 12 mesi: cliente con posizioni in essere, ultimo contatto più di un anno fa (o nessun contatto e
    /// scheda di più di un anno) e nessun appuntamento in agenda.
    private static func riesame(_ c: Cliente, posizioni: [Posizione], appuntamenti: [Appuntamento], incontri: [Incontro],
                                oggi: Date, calendario cal: Calendar) -> [VoceTagliando] {
        guard posizioni.contains(where: { $0.stato == .inEssere }) else { return [] }
        let inizio = cal.startOfDay(for: oggi)
        guard !appuntamenti.contains(where: { $0.stato == .pianificato && $0.inizio >= inizio }) else { return [] }
        let mesi = MotoreRiesame.mesiRiesame
        let ultimo = ultimoContatto(appuntamenti: appuntamenti, incontri: incontri, oggi: oggi)
        let riferimento = ultimo ?? c.creatoIl
        guard let dovuto = cal.date(byAdding: .month, value: mesi, to: riferimento), dovuto < inizio else { return [] }
        let passati = cal.dateComponents([.month], from: riferimento, to: oggi).month ?? mesi
        let dettaglio = ultimo == nil
            ? "\(c.nome) · nessun incontro registrato da quando è cliente"
            : "\(c.nome) · sono passati \(passati) mesi dall'ultimo incontro"
        return [VoceTagliando(
            id: "riesame-\(c.id)-\(ultimo.map { giorno($0, cal) } ?? "nessuno")", tipo: .riesame, gravita: .rosso,
            titolo: "Riesame oltre i 12 mesi", dettaglio: dettaglio, clienti: [c.id],
            correzione: attivita(c, "Fissare il riesame annuale con \(c.nome)", entro: piu(7, oggi, cal), etichetta: "Fissa il riesame", oggi: oggi, calendario: cal),
            peso: pesoRosso)]
    }

    // MARK: Questionari e adeguata verifica

    /// Il prossimo incontro con il cliente entro due settimane (le telefonate e i blocchi non contano).
    static func prossimoIncontro(_ appuntamenti: [Appuntamento], oggi: Date, calendario cal: Calendar) -> Appuntamento? {
        let inizio = cal.startOfDay(for: oggi)
        let limite = cal.date(byAdding: .day, value: giorniIncontro + 1, to: inizio) ?? inizio
        return appuntamenti.filter { $0.stato == .pianificato && $0.inizio >= inizio && $0.inizio < limite
            && $0.tipo != .telefonata && $0.tipo != .nonDisponibile }.min { $0.inizio < $1.inizio }
    }

    /// Il questionario del canale vale ancora il giorno dell'incontro.
    static func questionarioValido(_ c: Cliente, canale: Canale, il giorno: Date, regole: RegoleConformita, calendario cal: Calendar) -> Bool {
        let conf = c.conformita ?? ConformitaCliente()
        if conf.nonRichiesta(VoceConformita.Tipo.questionarioDi(canale).rawValue) { return true }
        guard let q = conf.questionario(canale), let compilato = q.compilatoIl else { return false }
        let scadenza = MotoreConformita.aggiungiMesi(MotoreConformita.mesi(q.validitaMesi ?? regole.mesiQuestionario(canale)), a: compilato, calendario: cal)
        return cal.startOfDay(for: scadenza) >= cal.startOfDay(for: giorno)
    }

    private static func questionari(_ c: Cliente, esito: EsitoConformita, appuntamenti: [Appuntamento], regole: RegoleConformita,
                                    oggi: Date, calendario cal: Calendar) -> [VoceTagliando] {
        var voci: [VoceTagliando] = []
        let incontro = prossimoIncontro(appuntamenti, oggi: oggi, calendario: cal)
        let quandoIncontro = incontro.map { " · \(nomeIncontro($0)) è \(DateItaliane.descrivi($0.inizio, conOra: false, oggi: oggi, cal: cal))" } ?? ""
        let entroIncontro = incontro.flatMap { cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: $0.inizio)) }.map { max($0, cal.startOfDay(for: oggi)) }
        // Prima di una firma un questionario che manca o scade prima dell'incontro blocca: rosso, come quello scaduto
        // e come la voce dell'incontro per chi non è ancora seguito
        let firma = incontro?.tipo == .firma
        var coperti = Set<Canale>()
        for canale in Canale.allCases {
            guard let v = esito.voce(.questionarioDi(canale)) else { continue }
            let nome = TestiConformita.nomeBreve(.questionarioDi(canale))
            let titoloAttivita = "Preparare il \(nome) di \(c.nome)"
            // La firma blocca solo il questionario del suo canale (o di tutti, se non indica il canale)
            let bloccaCanale = firma && (incontro?.canale == nil || incontro?.canale == canale)
            switch v.stato {
            case .scaduta:
                coperti.insert(canale)
                voci.append(VoceTagliando(
                    id: "questionario-\(c.id)-\(canale.rawValue)-scaduta-\(giorno(v.scadenza, cal))", tipo: .questionario,
                    gravita: incontro != nil ? .rosso : .arancio,
                    titolo: "Questionario di profilatura scaduto",
                    dettaglio: "\(c.nome) · \(TestiConformita.scaduta(v))\(quandoIncontro)", clienti: [c.id],
                    correzione: attivita(c, titoloAttivita, entro: entroIncontro ?? piu(14, oggi, cal), etichetta: "Prepara il questionario", oggi: oggi, calendario: cal),
                    peso: incontro != nil ? pesoRosso : pesoArancio))
            case .mancante:
                coperti.insert(canale)
                voci.append(VoceTagliando(
                    id: "questionario-\(c.id)-\(canale.rawValue)-mancante", tipo: .questionario, gravita: bloccaCanale ? .rosso : .arancio,
                    titolo: "Questionario di profilatura da compilare",
                    dettaglio: "\(c.nome) · manca il \(nome)\(quandoIncontro)", clienti: [c.id],
                    correzione: attivita(c, titoloAttivita, entro: entroIncontro ?? piu(14, oggi, cal), etichetta: "Prepara il questionario", oggi: oggi, calendario: cal),
                    peso: bloccaCanale ? pesoRosso : pesoArancio))
            case .entro30:
                coperti.insert(canale)
                var primaIncontro = false
                if let i = incontro, let s = v.scadenza { primaIncontro = cal.startOfDay(for: s) < cal.startOfDay(for: i.inizio) }
                let blocca = primaIncontro && bloccaCanale
                voci.append(VoceTagliando(
                    id: "questionario-\(c.id)-\(canale.rawValue)-entro30-\(giorno(v.scadenza, cal))", tipo: .questionario, gravita: blocca ? .rosso : .arancio,
                    titolo: "Questionario di profilatura in scadenza",
                    dettaglio: "\(c.nome) · \(TestiConformita.inScadenza(v))\(primaIncontro ? ", prima dell'incontro" : "")\(quandoIncontro)", clienti: [c.id],
                    correzione: attivita(c, titoloAttivita, entro: entroIncontro ?? v.scadenza ?? piu(14, oggi, cal), etichetta: "Prepara il questionario", oggi: oggi, calendario: cal),
                    peso: blocca ? pesoRosso : pesoArancio))
            default: break
            }
        }
        // Prima di un incontro: il questionario serve anche a chi non è ancora seguito su nessun canale (primo incontro)
        if let incontro {
            let canali: [Canale] = incontro.canale.map { [$0] } ?? c.canali
            let validi: Bool
            if canali.isEmpty {
                validi = Canale.allCases.contains { questionarioValido(c, canale: $0, il: incontro.inizio, regole: regole, calendario: cal) }
            } else {
                validi = canali.allSatisfy { coperti.contains($0) || questionarioValido(c, canale: $0, il: incontro.inizio, regole: regole, calendario: cal) }
            }
            let giaDetto = canali.isEmpty ? !coperti.isEmpty : canali.allSatisfy { coperti.contains($0) }
            if !validi, !giaDetto {
                let chiave = canali.isEmpty ? "nessuno" : canali.map(\.rawValue).joined(separator: ",")
                voci.append(VoceTagliando(
                    id: "questionario-\(c.id)-incontro-\(chiave)-\(giorno(incontro.inizio, cal))", tipo: .questionario,
                    gravita: firma ? .rosso : .arancio, titolo: "Questionario di profilatura da compilare",
                    dettaglio: "\(c.nome)\(quandoIncontro)", clienti: [c.id],
                    correzione: attivita(c, "Preparare il questionario di profilatura di \(c.nome)", entro: entroIncontro ?? oggi,
                                         etichetta: "Prepara il questionario", oggi: oggi, calendario: cal),
                    peso: firma ? pesoRosso : pesoArancio))
            }
        }
        return voci
    }

    private static func nomeIncontro(_ a: Appuntamento) -> String {
        switch a.tipo {
        case .primoIncontro: return "il primo incontro"
        case .firma: return "la firma"
        case .proposta: return "la presentazione della proposta"
        case .revisione: return "la revisione"
        default: return "l'incontro"
        }
    }

    private static func verifiche(_ c: Cliente, esito: EsitoConformita, oggi: Date, calendario cal: Calendar) -> [VoceTagliando] {
        var voci: [VoceTagliando] = []
        for canale in Canale.allCases {
            guard let v = esito.voce(.verificaDi(canale)) else { continue }
            let gravita: VoceTagliando.Gravita
            let titolo: String
            switch v.stato {
            case .scaduta: gravita = .rosso; titolo = "Adeguata verifica scaduta"
            case .mancante: gravita = .arancio; titolo = "Adeguata verifica da fare"
            case .entro30: gravita = .arancio; titolo = "Adeguata verifica in scadenza"
            default: continue
            }
            voci.append(VoceTagliando(
                id: "verifica-\(c.id)-\(canale.rawValue)-\(v.stato)-\(giorno(v.scadenza, cal))", tipo: .verifica, gravita: gravita, titolo: titolo,
                dettaglio: "\(c.nome) · \(TestiConformita.breve(v))", clienti: [c.id],
                correzione: attivita(c, "Rinnovare l'\(TestiConformita.nomeBreve(.verificaDi(canale))) di \(c.nome)",
                                     entro: v.stato == .entro30 ? (v.scadenza ?? piu(14, oggi, cal)) : piu(14, oggi, cal),
                                     etichetta: "Prepara la verifica", oggi: oggi, calendario: cal),
                peso: gravita == .rosso ? pesoRosso : pesoArancio))
        }
        return voci
    }

    // MARK: Documento d'identità

    /// Il documento d'identità più recente letto in Documenti (numero, scadenza, rilascio), se ha almeno una scadenza.
    struct IdentitaLetta: Equatable {
        let documentoId: String
        let titolo: String
        let numero: String?
        let rilascio: Date?
        let scadenza: Date
        let confermata: Bool
    }

    static func identitaDaiDocumenti(_ documenti: [Documento]) -> IdentitaLetta? {
        let letti = documenti.filter { $0.genere == .identita }.compactMap { d -> IdentitaLetta? in
            guard let campo = d.campo(.scadenza), let s = EstrattoreDocumento.data(campo.valore) else { return nil }
            let numero = d.campo(.numeroDocumento)?.valore.trimmingCharacters(in: .whitespaces)
            return IdentitaLetta(documentoId: d.id, titolo: d.titolo, numero: (numero?.isEmpty ?? true) ? nil : numero,
                                 rilascio: EstrattoreDocumento.data(d.campo(.dataRilascio)?.valore), scadenza: s,
                                 confermata: campo.confermato)
        }
        return letti.max { $0.scadenza < $1.scadenza }
    }

    private static func documentoIdentita(_ c: Cliente, esito: EsitoConformita, documenti: [Documento], posizioni: [Posizione],
                                          oggi: Date, calendario cal: Calendar) -> [VoceTagliando] {
        guard let v = esito.voce(.documento) else { return [] }
        let letto = identitaDaiDocumenti(documenti)
        let registrata = c.conformita?.documento?.scadenza
        let inizio = cal.startOfDay(for: oggi)

        // In Documenti c'è un documento più nuovo di quello registrato nella scheda: si propone di registrarlo
        if let letto, registrata.map({ cal.startOfDay(for: letto.scadenza) > cal.startOfDay(for: $0) }) ?? true,
           v.stato != .nonRichiesta || registrata == nil {
            let valido = cal.startOfDay(for: letto.scadenza) >= inizio
            if valido {
                var parti = ["scade il \(TestiConformita.data(letto.scadenza))"]
                if let n = letto.numero { parti.insert("numero \(n)", at: 0) }
                var argomenti = ["cliente": c.id, "documento": letto.documentoId, "scadenza": RegistroStrumenti.isoData(letto.scadenza)]
                if let n = letto.numero { argomenti["numero"] = n }
                if let r = letto.rilascio { argomenti["rilascio"] = RegistroStrumenti.isoData(r) }
                let azione = AzioneConferma(
                    strumento: strumentoDocumento, app: .clienti, titolo: "Registro il documento d'identità di \(c.nome)",
                    dettaglio: parti.joined(separator: " · ") + " · letto in «\(letto.titolo)»", argomenti: argomenti,
                    avviso: letto.confermata ? nil : "La scadenza letta nel documento non è ancora confermata: controllala prima.")
                let scaduto = v.stato == .scaduta
                return [VoceTagliando(
                    id: "documentonuovo-\(letto.documentoId)-\(giorno(letto.scadenza, cal))", tipo: .documentoNuovo,
                    gravita: scaduto ? .arancio : .neutro,
                    titolo: "Documento d'identità nuovo da registrare",
                    dettaglio: scaduto ? "\(c.nome) · la scheda ha ancora quello scaduto, in Documenti c'è il nuovo"
                                       : "\(c.nome) · in Documenti c'è un documento più recente di quello nella scheda",
                    clienti: [c.id], correzione: .conferma(etichetta: "Registra il documento", azione: azione),
                    peso: scaduto ? pesoArancio : pesoNeutro)]
            }
        }

        // Nella scheda non c'è, ma in Documenti ce n'è uno (scaduto): vale quello letto
        if registrata == nil, let letto, v.stato != .nonRichiesta {
            return [VoceTagliando(
                id: "documento-\(c.id)-letto-scaduto-\(giorno(letto.scadenza, cal))", tipo: .documentoIdentita, gravita: .rosso,
                titolo: "Documento d'identità scaduto",
                dettaglio: "\(c.nome) · quello in Documenti è scaduto il \(TestiConformita.data(letto.scadenza))", clienti: [c.id],
                correzione: attivita(c, "Chiedere a \(c.nome) la copia del documento d'identità nuovo", entro: piu(7, oggi, cal),
                                     etichetta: "Chiedi la copia nuova", oggi: oggi, calendario: cal), peso: pesoRosso)]
        }

        let titoloAttivita = "Chiedere a \(c.nome) la copia del documento d'identità nuovo"
        switch v.stato {
        case .scaduta:
            return [VoceTagliando(
                id: "documento-\(c.id)-scaduta-\(giorno(v.scadenza, cal))", tipo: .documentoIdentita, gravita: .rosso,
                titolo: "Documento d'identità scaduto",
                dettaglio: "\(c.nome) · scaduto il \(v.scadenza.map { TestiConformita.data($0) } ?? "—")", clienti: [c.id],
                correzione: attivita(c, titoloAttivita, entro: piu(7, oggi, cal), etichetta: "Chiedi la copia nuova", oggi: oggi, calendario: cal),
                peso: pesoRosso)]
        case .entro30, .entro60:
            let scadenza = v.scadenza ?? piu(30, oggi, cal)
            return [VoceTagliando(
                id: "documento-\(c.id)-inscadenza-\(giorno(v.scadenza, cal))", tipo: .documentoIdentita, gravita: .arancio,
                titolo: "Documento d'identità in scadenza",
                dettaglio: "\(c.nome) · scade il \(TestiConformita.data(scadenza))", clienti: [c.id],
                correzione: attivita(c, titoloAttivita, entro: min(scadenza, piu(14, oggi, cal)), etichetta: "Chiedi la copia nuova", oggi: oggi, calendario: cal),
                peso: pesoArancio)]
        case .mancante:
            return [VoceTagliando(
                id: "documento-\(c.id)-mancante", tipo: .documentoIdentita, gravita: .arancio,
                titolo: "Documento d'identità non registrato",
                dettaglio: "\(c.nome) · mancano tipo, numero e scadenza del documento", clienti: [c.id],
                correzione: .naviga(etichetta: "Registra il documento", destinazione: .scheda(clienteId: c.id, sezione: .inRegola)),
                peso: pesoArancio)]
        default:
            return []
        }
    }

    // MARK: Posizioni scadute

    /// Una posizione in essere con la scadenza già passata (i debiti no): va chiusa, rinnovata o aggiornata.
    private static func posizioniScadute(_ c: Cliente, posizioni: [Posizione], oggi: Date, calendario cal: Calendar) -> [VoceTagliando] {
        let inizio = cal.startOfDay(for: oggi)
        return posizioni.filter { $0.stato == .inEssere && !$0.area.passivo && ($0.scadenza.map { $0 < inizio } ?? false) }.map { p in
            VoceTagliando(
                id: "posizione-\(p.id)-\(giorno(p.scadenza, cal))", tipo: .posizioneScaduta, gravita: .arancio,
                titolo: "Posizione scaduta ma ancora in essere",
                dettaglio: "\(c.nome) · «\(p.nome)» è scaduta il \(p.scadenza.map { TestiConformita.data($0) } ?? "—")", clienti: [c.id],
                correzione: .naviga(etichetta: "Aggiorna la posizione", destinazione: .posizione(id: p.id)), peso: pesoArancio)
        }
    }

    // MARK: Le correzioni

    /// Un'attività da confermare, con gli stessi argomenti di «Fallo tu» (RegistroStrumenti.attivitaNuova).
    static func attivita(_ c: Cliente, _ titolo: String, entro: Date, etichetta: String, oggi: Date, calendario cal: Calendar) -> CorrezioneTagliando {
        let scadenza = max(cal.startOfDay(for: entro), cal.startOfDay(for: oggi))
        let azione = AzioneConferma(strumento: RegistroStrumenti.attivitaNuova, app: .attivita, titolo: "Segno un'attività per \(c.nome)",
                                    dettaglio: "«\(titolo)» · entro \(DateItaliane.descrivi(scadenza, conOra: false, oggi: oggi, cal: cal))",
                                    argomenti: ["cliente": c.id, "titolo": titolo, "scadenza": RegistroStrumenti.isoData(scadenza)])
        return .conferma(etichetta: etichetta, azione: azione)
    }

    /// La scheda «Conferma» di «Sistema tutto»: tutte le azioni del tagliando, da confermare insieme (nil se non ce ne sono).
    static func schedaSistemaTutto(_ e: EsitoTagliando) -> SchedaConfermaVera? {
        let azioni = e.azioni
        guard !azioni.isEmpty else { return nil }
        return SchedaConfermaVera(richiesta: "Sistema tutto (tagliando dei dati)", azioni: azioni, origine: .regole)
    }

    /// La scheda «Conferma» di una voce sola (nil se la voce porta a una schermata).
    static func scheda(_ v: VoceTagliando) -> SchedaConfermaVera? {
        guard let a = v.correzione?.azione else { return nil }
        return SchedaConfermaVera(richiesta: "\(v.titolo): \(v.correzione?.etichetta ?? "")", azioni: [a], origine: .regole)
    }

    // MARK: I testi della pagina

    /// «6 cose da sistemare», «1 cosa da sistemare», «Archivio in ordine».
    static func riepilogo(_ e: EsitoTagliando) -> String {
        let n = e.voci.count
        if n == 0 { return "Archivio in ordine" }
        return n == 1 ? "1 cosa da sistemare" : "\(n) cose da sistemare"
    }

    /// «35 schede», «1 scheda».
    static func schede(_ n: Int) -> String { n == 1 ? "1 scheda" : "\(n) schede" }

    /// «Controllate stanotte alle 2:10.», «Controllate oggi alle 9:12.», «Controllate ieri alle 2:10.», «Controllate il 3 novembre.»
    static func quando(_ r: RegistroTagliando, oggi: Date, calendario cal: Calendar = .current) -> String {
        let ora = "\(cal.component(.hour, from: r.data)):" + String(format: "%02d", cal.component(.minute, from: r.data))
        if cal.isDate(r.data, inSameDayAs: oggi) {
            return cal.component(.hour, from: r.data) < 6 ? "Controllate stanotte alle \(ora)." : "Controllate oggi alle \(ora)."
        }
        if let ieri = cal.date(byAdding: .day, value: -1, to: oggi), cal.isDate(r.data, inSameDayAs: ieri) {
            return "Controllate ieri alle \(ora)."
        }
        return "Controllate il \(TestiConformita.data(r.data))."
    }

    /// Le voci trovate in questo controllo che nel precedente non c'erano.
    static func nuove(_ e: EsitoTagliando, rispetto precedente: RegistroTagliando?) -> [VoceTagliando] {
        guard let precedente else { return e.voci }
        let gia = Set(precedente.voci)
        return e.voci.filter { !gia.contains($0.id) }
    }

    /// I campi vuoti di tutto l'archivio in una riga sola, come nel template: «7 schede senza codice fiscale, 3 senza email».
    static func riepilogoCampiVuoti(_ e: EsitoTagliando, clienti: [Cliente]) -> String? {
        let suoi = Set(e.voci.filter { $0.tipo == .campiVuoti }.compactMap(\.clienteId))
        guard !suoi.isEmpty else { return nil }
        let conti = Campo.allCases.compactMap { campo -> (Campo, Int)? in
            let n = clienti.filter { suoi.contains($0.id) && vuoti($0).contains(campo) }.count
            return n > 0 ? (campo, n) : nil
        }
        return conti.enumerated().map { i, x in
            i == 0 ? "\(schede(x.1)) senza \(x.0.nome)" : "\(x.1) senza \(x.0.nome)"
        }.joined(separator: ", ")
    }

    // MARK: Aiuti

    private static func piu(_ giorni: Int, _ d: Date, _ cal: Calendar) -> Date {
        cal.date(byAdding: .day, value: giorni, to: cal.startOfDay(for: d)) ?? d
    }

    /// «20261109»: il giorno di una data per gli id (senza formattatori, indipendente dalla lingua).
    static func giorno(_ d: Date?, _ cal: Calendar) -> String {
        guard let d else { return "senzadata" }
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
