import CryptoKit
import Foundation

// Proprietario: G2 (archivio). Giro 0 di «Prisma istantaneo», tappa 3 (Design/velocita-proposta.md, «L'archivio»).

/// L'archivio su disco a pezzi: la cartella «Archivio/» dentro ~/Library/Application Support/Prisma.
///
///     Archivio/
///       indice.json            versione del formato, generazione, versione dei dati, cliente attivo, impostazioni,
///                              elenco dei clienti (id, file, nome) e l'ordine degli elenchi divisi per cliente
///       indice-riserva.json    la copia dell'indice, scritta con lui: se l'indice si rovina si ricostruisce da lei
///                              (impostazioni, contatori di Prisma ovunque e ordine di adesso, non quelli dell'avvio)
///       Clienti/<id>-<impronta>.json   un file per cliente: anagrafica e ciò che è solo suo
///       Clienti/senza-cliente.json     gli elementi che nominano un cliente che non c'è più (mai persi)
///       agenda.json, attivita.json, conversazioni.json, prodotti.json, spazi.json, pratiche.json,
///       mercato.json, ovunque.json, studio.json, routine.json, vera.json      le sezioni comuni
///
/// La divisione (`pezzo(_:)`, uno `switch` completo su tutte le chiavi di `DatiPrisma`):
/// - nell'indice solo ciò che è piccolo e serve subito (le impostazioni danno aspetto, misura del testo e nome della
///   schermata di benvenuto; l'elenco dei clienti dà i nomi per gli avvisi), così si legge prima di tutto il resto;
/// - nel file del cliente tutto ciò che ha il suo `clienteId` (posizioni, obiettivi, documenti, note, Analisi 360,
///   eventi della vita, messaggi, parcelle…): una nota o una posizione cambiata riscrive un file piccolo;
/// - a sé le sezioni comuni grandi o di tutti (agenda e attività, che si spostano spesso insieme fra clienti diversi,
///   le conversazioni di Vera, il catalogo dei prodotti, il mercato, Prisma ovunque, lo studio).
///
/// Ogni pezzo è un oggetto JSON con le stesse chiavi di `DatiPrisma` (e la stessa lettura tollerante, la stessa
/// `init(from:)`), più la generazione in cui è stato scritto. L'ordine degli elenchi divisi per cliente sta nell'indice
/// (`ordini`, a corse «cliente × quanti»): rimettendo insieme i pezzi l'archivio torna identico, ordine compreso.
/// Le scritture sono atomiche (file temporaneo e rinomina) e l'indice si scrive per ultimo; un file non citato
/// dall'indice ma scritto dopo di lui (salvataggio interrotto prima dell'indice) si riprende, uno più vecchio si scarta.
enum ArchivioPezzi {
    /// Il numero di versione del formato su disco (diverso dalla versione dei dati, `DatiPrisma.versioneAttuale`).
    static let formatoAttuale = 1
    static let nomeCartella = "Archivio"
    static let nomeIndice = "indice.json"
    /// La copia dell'indice, scritta sempre insieme a lui (prima di lui), letta solo per ricostruire un indice rovinato.
    static let nomeRiserva = "indice-riserva.json"
    static let nomeClienti = "Clienti"
    static let nomeSenzaCliente = "senza-cliente.json"
    /// Il gruppo degli elementi senza un cliente presente (nessun id vero comincia con il carattere nullo).
    static let gruppoAltri = "\u{0}senza-cliente"
    /// Nel `userInfo` del decodificatore dei pezzi: i clienti possono mancare (`DatiPrisma.init(from:)`).
    static let chiavePezzo = CodingUserInfoKey(rawValue: "prisma.pezzoArchivio")!

    typealias Chiave = DatiPrisma.CodingKeys

    enum Pezzo: Hashable {
        case indice
        case cliente
        case sezione(String)
    }

    /// Dove sta ogni chiave dell'archivio.
    static func pezzo(_ k: Chiave) -> Pezzo {
        switch k {
        case .versione, .clienteAttivoId, .impostazioni:
            return .indice
        case .clienti, .posizioni, .simulazioni, .analisi, .incontri, .obiettivi, .documenti, .valutazioni, .commenti,
             .note, .fotografie, .schedeAdeguatezza, .confrontiTFR, .parcelle, .raccomandazioni, .messaggi, .eventiVita,
             .sessioniCopilota, .partiteRischio, .promesse, .confrontiDocumenti, .coperture, .sussurriChiusi, .spiegazioniTreLivelli:
            return .cliente
        case .appuntamenti: return .sezione("agenda")
        case .attivita: return .sezione("attivita")
        case .conversazioni: return .sezione("conversazioni")
        case .prodotti: return .sezione("prodotti")
        case .spazi: return .sezione("spazi")
        case .pratiche: return .sezione("pratiche")
        case .mercato: return .sezione("mercato")
        case .giornaleOvunque, .conflittiOvunque, .arriviOvunque, .inquadratureDaConfermare: return .sezione("ovunque")
        case .famiglie, .ocf, .portafogliModello: return .sezione("studio")
        // Vera, fase 4: le routine del consulente e i loro lanci; i dati di Vera (il tagliando dei dati)
        case .routine: return .sezione("routine")
        case .tagliando: return .sezione("vera")
        }
    }

    /// Le sezioni comuni con le loro chiavi, in ordine di nome.
    static let sezioni: [(nome: String, chiavi: Set<Chiave>)] = {
        var s: [String: Set<Chiave>] = [:]
        for k in Chiave.allCases { if case .sezione(let n) = pezzo(k) { s[n, default: []].insert(k) } }
        return s.keys.sorted().map { ($0, s[$0] ?? []) }
    }()

    static let chiaviCliente: Set<Chiave> = Set(Chiave.allCases.filter { pezzo($0) == .cliente })

    /// I campi divisi per cliente, con le loro regole (elenchi con l'ordine nell'indice, dizionari per id).
    static let campiCliente: [CampoPezzoCliente] = [
        .elenco(.clienti, \.clienti),
        .elenco(.posizioni, \.posizioni),
        .elenco(.simulazioni, \.simulazioni),
        .dizionario(.analisi, \.analisi),
        .elenco(.incontri, \.incontri),
        .elenco(.obiettivi, \.obiettivi),
        .elenco(.documenti, \.documenti),
        .elenco(.valutazioni, \.valutazioni),
        .elenco(.commenti, \.commenti),
        .elenco(.note, \.note),
        .elenco(.fotografie, \.fotografie),
        .elenco(.schedeAdeguatezza, \.schedeAdeguatezza),
        .dizionario(.confrontiTFR, \.confrontiTFR),
        .elenco(.parcelle, \.parcelle),
        .elenco(.raccomandazioni, \.raccomandazioni),
        .elenco(.messaggi, \.messaggi),
        .elenco(.eventiVita, \.eventiVita),
        .elenco(.sessioniCopilota, \.sessioniCopilota),
        .elenco(.partiteRischio, \.partiteRischio),
        .elenco(.promesse, \.promesse),
        .elenco(.confrontiDocumenti, \.confrontiDocumenti),
        .elenco(.coperture, \.coperture),
        .elenco(.sussurriChiusi, \.sussurriChiusi),
        .elenco(.spiegazioniTreLivelli, \.spiegazioniTreLivelli),
    ]

    /// Un archivio vuoto, base di ogni pezzo (le impostazioni di base si costruiscono una volta sola).
    static let vuoto = DatiPrisma(clienti: [], appuntamenti: [], attivita: [], posizioni: [], clienteAttivoId: "",
                                  impostazioni: Impostazioni())

    static func cartellaPezzi(in cartella: URL) -> URL { cartella.appendingPathComponent(nomeCartella, isDirectory: true) }
    static func indice(in cartella: URL) -> URL { cartellaPezzi(in: cartella).appendingPathComponent(nomeIndice) }
    /// true se nella cartella dell'archivio (`cartella`, la «Prisma») c'è il formato a pezzi.
    static func presente(in cartella: URL) -> Bool { FileManager.default.fileExists(atPath: indice(in: cartella).path) }

    static func nomeFileSezione(_ nome: String) -> String { nome + ".json" }

    /// Il nome del file di un cliente: l'id leggibile (minuscolo, solo lettere, cifre e trattini) più un'impronta
    /// dell'id esatto, così due id che differiscono solo per maiuscole o simboli non si scrivono sullo stesso file.
    static func nomeFile(cliente id: String) -> String {
        var base = ""
        for u in id.lowercased().unicodeScalars.prefix(40) {
            base.append(("a"..."z").contains(u) || ("0"..."9").contains(u) || u == "-" || u == "_" ? Character(u) : "-")
        }
        if base.isEmpty { base = "cliente" }
        let impronta = SHA256.hash(data: Data(id.utf8)).prefix(4).map { String(format: "%02x", $0) }.joined()
        return "\(base)-\(impronta).json"
    }

    /// Il decodificatore dei pezzi: quello dell'archivio, con i clienti facoltativi. Non si modifica dopo la
    /// creazione, quindi si usa da più thread insieme.
    static let decodificatore: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        d.userInfo[chiavePezzo] = true
        return d
    }()

    // MARK: - Confronto e copia campo per campo

    /// Lo stesso campo in due archivi è uguale (gli elenchi non toccati condividono la memoria: costa poco).
    static func uguale(_ k: Chiave, _ a: DatiPrisma, _ b: DatiPrisma) -> Bool {
        switch k {
        case .versione: return a.versione == b.versione
        case .clienti: return a.clienti == b.clienti
        case .appuntamenti: return a.appuntamenti == b.appuntamenti
        case .attivita: return a.attivita == b.attivita
        case .posizioni: return a.posizioni == b.posizioni
        case .simulazioni: return a.simulazioni == b.simulazioni
        case .analisi: return a.analisi == b.analisi
        case .incontri: return a.incontri == b.incontri
        case .prodotti: return a.prodotti == b.prodotti
        case .obiettivi: return a.obiettivi == b.obiettivi
        case .documenti: return a.documenti == b.documenti
        case .valutazioni: return a.valutazioni == b.valutazioni
        case .conversazioni: return a.conversazioni == b.conversazioni
        case .commenti: return a.commenti == b.commenti
        case .note: return a.note == b.note
        case .spazi: return a.spazi == b.spazi
        case .fotografie: return a.fotografie == b.fotografie
        case .schedeAdeguatezza: return a.schedeAdeguatezza == b.schedeAdeguatezza
        case .confrontiTFR: return a.confrontiTFR == b.confrontiTFR
        case .parcelle: return a.parcelle == b.parcelle
        case .raccomandazioni: return a.raccomandazioni == b.raccomandazioni
        case .messaggi: return a.messaggi == b.messaggi
        case .eventiVita: return a.eventiVita == b.eventiVita
        case .sessioniCopilota: return a.sessioniCopilota == b.sessioniCopilota
        case .giornaleOvunque: return a.giornaleOvunque == b.giornaleOvunque
        case .conflittiOvunque: return a.conflittiOvunque == b.conflittiOvunque
        case .arriviOvunque: return a.arriviOvunque == b.arriviOvunque
        case .inquadratureDaConfermare: return a.inquadratureDaConfermare == b.inquadratureDaConfermare
        case .mercato: return a.mercato == b.mercato
        case .famiglie: return a.famiglie == b.famiglie
        case .ocf: return a.ocf == b.ocf
        case .portafogliModello: return a.portafogliModello == b.portafogliModello
        case .pratiche: return a.pratiche == b.pratiche
        case .partiteRischio: return a.partiteRischio == b.partiteRischio
        case .promesse: return a.promesse == b.promesse
        case .confrontiDocumenti: return a.confrontiDocumenti == b.confrontiDocumenti
        case .coperture: return a.coperture == b.coperture
        case .routine: return a.routine == b.routine
        case .tagliando: return a.tagliando == b.tagliando
        case .sussurriChiusi: return a.sussurriChiusi == b.sussurriChiusi
        case .spiegazioniTreLivelli: return a.spiegazioniTreLivelli == b.spiegazioniTreLivelli
        case .clienteAttivoId: return a.clienteAttivoId == b.clienteAttivoId
        case .impostazioni: return a.impostazioni == b.impostazioni
        }
    }

    /// Copia un campo da un archivio (un pezzo letto) a un altro.
    static func copia(_ k: Chiave, da a: DatiPrisma, in b: inout DatiPrisma) {
        switch k {
        case .versione: b.versione = a.versione
        case .clienti: b.clienti = a.clienti
        case .appuntamenti: b.appuntamenti = a.appuntamenti
        case .attivita: b.attivita = a.attivita
        case .posizioni: b.posizioni = a.posizioni
        case .simulazioni: b.simulazioni = a.simulazioni
        case .analisi: b.analisi = a.analisi
        case .incontri: b.incontri = a.incontri
        case .prodotti: b.prodotti = a.prodotti
        case .obiettivi: b.obiettivi = a.obiettivi
        case .documenti: b.documenti = a.documenti
        case .valutazioni: b.valutazioni = a.valutazioni
        case .conversazioni: b.conversazioni = a.conversazioni
        case .commenti: b.commenti = a.commenti
        case .note: b.note = a.note
        case .spazi: b.spazi = a.spazi
        case .fotografie: b.fotografie = a.fotografie
        case .schedeAdeguatezza: b.schedeAdeguatezza = a.schedeAdeguatezza
        case .confrontiTFR: b.confrontiTFR = a.confrontiTFR
        case .parcelle: b.parcelle = a.parcelle
        case .raccomandazioni: b.raccomandazioni = a.raccomandazioni
        case .messaggi: b.messaggi = a.messaggi
        case .eventiVita: b.eventiVita = a.eventiVita
        case .sessioniCopilota: b.sessioniCopilota = a.sessioniCopilota
        case .giornaleOvunque: b.giornaleOvunque = a.giornaleOvunque
        case .conflittiOvunque: b.conflittiOvunque = a.conflittiOvunque
        case .arriviOvunque: b.arriviOvunque = a.arriviOvunque
        case .inquadratureDaConfermare: b.inquadratureDaConfermare = a.inquadratureDaConfermare
        case .mercato: b.mercato = a.mercato
        case .famiglie: b.famiglie = a.famiglie
        case .ocf: b.ocf = a.ocf
        case .portafogliModello: b.portafogliModello = a.portafogliModello
        case .pratiche: b.pratiche = a.pratiche
        case .partiteRischio: b.partiteRischio = a.partiteRischio
        case .promesse: b.promesse = a.promesse
        case .confrontiDocumenti: b.confrontiDocumenti = a.confrontiDocumenti
        case .coperture: b.coperture = a.coperture
        case .routine: b.routine = a.routine
        case .tagliando: b.tagliando = a.tagliando
        case .sussurriChiusi: b.sussurriChiusi = a.sussurriChiusi
        case .spiegazioniTreLivelli: b.spiegazioniTreLivelli = a.spiegazioniTreLivelli
        case .clienteAttivoId: b.clienteAttivoId = a.clienteAttivoId
        case .impostazioni: b.impostazioni = a.impostazioni
        }
    }

    /// Un pezzo di cliente senza nulla dentro (un gruppo «senza cliente» vuoto non ha file).
    static func vuoto(_ p: DatiPrisma) -> Bool {
        campiCliente.allSatisfy { $0.vuoto(p) }
    }

    /// Lo scheletro dell'archivio dal solo indice: impostazioni e cliente attivo, nessun dato dei clienti. Serve solo
    /// alla schermata di benvenuto mentre il resto arriva (StatoShell, `archivioPronto`): mai salvato, mai mostrato
    /// come archivio completo.
    static func scheletro(_ i: IndiceArchivio) -> DatiPrisma {
        var d = vuoto
        d.versione = i.versione
        d.clienteAttivoId = i.clienteAttivoId
        d.impostazioni = i.impostazioni
        return d
    }
}

/// Un elemento che appartiene a un cliente (per il file in cui va scritto).
protocol DelCliente {
    var idClientePezzo: String { get }
}

extension Cliente: DelCliente { var idClientePezzo: String { id } }
extension Posizione: DelCliente { var idClientePezzo: String { clienteId } }
extension Simulazione: DelCliente { var idClientePezzo: String { clienteId } }
extension Incontro: DelCliente { var idClientePezzo: String { clienteId } }
extension Obiettivo: DelCliente { var idClientePezzo: String { clienteId } }
extension Documento: DelCliente { var idClientePezzo: String { clienteId } }
extension ValutazioneInvestimento: DelCliente { var idClientePezzo: String { clienteId } }
extension CommentoReport: DelCliente { var idClientePezzo: String { clienteId } }
extension Nota: DelCliente { var idClientePezzo: String { clienteId } }
extension FotografiaRiesame: DelCliente { var idClientePezzo: String { clienteId } }
extension SchedaAdeguatezza: DelCliente { var idClientePezzo: String { clienteId } }
extension Parcella: DelCliente { var idClientePezzo: String { clienteId } }
extension Raccomandazione: DelCliente { var idClientePezzo: String { clienteId } }
extension MessaggioCliente: DelCliente { var idClientePezzo: String { clienteId } }
extension EventoLineaVita: DelCliente { var idClientePezzo: String { clienteId } }
extension SessioneCopilota: DelCliente { var idClientePezzo: String { clienteId } }
extension PartitaRischio: DelCliente { var idClientePezzo: String { clienteId } }
extension PromessaCliente: DelCliente { var idClientePezzo: String { clienteId } }
extension ConfrontoDocumenti: DelCliente { var idClientePezzo: String { clienteId } }
extension CoperturaPolizza: DelCliente { var idClientePezzo: String { clienteId } }
extension SussurroChiuso: DelCliente { var idClientePezzo: String { clienteId } }
extension SpiegazioneTreLivelli: DelCliente { var idClientePezzo: String { clienteId } }

/// Una corsa dell'ordine di un elenco: `quanti` elementi di fila del gruppo `gruppo`. Su disco è `["giulia", 3]`.
struct Corsa: Codable, Equatable {
    var gruppo: String
    var quanti: Int

    init(gruppo: String, quanti: Int) {
        self.gruppo = gruppo
        self.quanti = quanti
    }

    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        gruppo = try c.decode(String.self)
        quanti = try c.decode(Int.self)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(gruppo)
        try c.encode(quanti)
    }
}

/// Un cliente nell'indice: l'id, il suo file e il nome (per gli avvisi quando il file manca o è rovinato).
struct VoceIndice: Codable, Equatable {
    var id: String
    var file: String
    var nome: String
}

/// L'indice dell'archivio a pezzi (`Archivio/indice.json`). Piccolo: si legge per primo.
struct IndiceArchivio: Codable, Equatable {
    /// La versione del formato su disco (`ArchivioPezzi.formatoAttuale`).
    var formato = ArchivioPezzi.formatoAttuale
    /// Cresce a ogni giro di scrittura: un pezzo più nuovo dell'indice viene da un salvataggio interrotto.
    var generazione = 0
    /// La versione dei dati (`DatiPrisma.versione`).
    var versione = DatiPrisma.versioneAttuale
    var clienteAttivoId = ""
    var impostazioni = Impostazioni()
    /// I clienti (uno per file), nell'ordine del loro primo elemento in `clienti`.
    var clienti: [VoceIndice] = []
    /// Il file degli elementi senza cliente (nil = nessuno).
    var senzaCliente: String?
    /// Le sezioni comuni scritte (nomi, `ArchivioPezzi.sezioni`).
    var sezioni: [String] = []
    /// L'ordine degli elenchi divisi per cliente (chiave di `DatiPrisma` → corse).
    var ordini: [String: [Corsa]] = [:]

    init() {}

    private enum CodingKeys: String, CodingKey {
        case formato, generazione, versione, clienteAttivoId, impostazioni, clienti, senzaCliente, sezioni, ordini
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        formato = try c.decode(Int.self, forKey: .formato)
        generazione = try c.decodeIfPresent(Int.self, forKey: .generazione) ?? 0
        versione = try c.decodeIfPresent(Int.self, forKey: .versione) ?? DatiPrisma.versioneAttuale
        clienteAttivoId = try c.decodeIfPresent(String.self, forKey: .clienteAttivoId) ?? ""
        impostazioni = try c.decodeIfPresent(Impostazioni.self, forKey: .impostazioni) ?? Impostazioni()
        clienti = try c.decodeIfPresent([VoceIndice].self, forKey: .clienti) ?? []
        senzaCliente = try c.decodeIfPresent(String.self, forKey: .senzaCliente)
        sezioni = try c.decodeIfPresent([String].self, forKey: .sezioni) ?? []
        // L'ordine è un aiuto: se non si legge, gli elementi tornano raggruppati per cliente, nessuno si perde
        ordini = (try? c.decodeIfPresent([String: [Corsa]].self, forKey: .ordini)) ?? [:]
    }

    /// Uguali in tutto tranne la generazione (l'indice si riscrive solo se cambia altro).
    func stessoContenuto(di altro: IndiceArchivio) -> Bool {
        var b = altro
        b.generazione = generazione
        return self == b
    }
}

/// Le regole di un campo diviso per cliente.
struct CampoPezzoCliente {
    let chiave: DatiPrisma.CodingKeys
    /// Mette in ogni pezzo (per gruppo) la sua parte del campo, vuota per i gruppi che non ne hanno; restituisce
    /// l'ordine (solo per gli elenchi) e i gruppi la cui parte è cambiata.
    let distribuisci: (_ dati: DatiPrisma, _ gruppo: (String) -> String, _ pezzi: inout [String: DatiPrisma]) -> (ordine: [Corsa]?, cambiati: Set<String>)
    /// Rimette insieme il campo dai pezzi, nell'ordine dato (gli elementi fuori dall'ordine vanno in fondo, per gruppo).
    let raccogli: (_ pezzi: [String: DatiPrisma], _ gruppi: [String], _ ordine: [Corsa]?, _ dati: inout DatiPrisma) -> Void
    let vuoto: (DatiPrisma) -> Bool

    static func elenco<T: DelCliente & Equatable>(_ k: DatiPrisma.CodingKeys, _ kp: WritableKeyPath<DatiPrisma, [T]>) -> CampoPezzoCliente {
        CampoPezzoCliente(chiave: k, distribuisci: { dati, gruppo, pezzi in
            var parti: [String: [T]] = [:]
            var ordine: [Corsa] = []
            for e in dati[keyPath: kp] {
                let g = gruppo(e.idClientePezzo)
                parti[g, default: []].append(e)
                if let u = ordine.last, u.gruppo == g {
                    ordine[ordine.count - 1].quanti += 1
                } else {
                    ordine.append(Corsa(gruppo: g, quanti: 1))
                }
            }
            var cambiati = Set<String>()
            for g in Set(parti.keys).union(pezzi.keys) {
                let nuova = parti[g] ?? []
                if (pezzi[g]?[keyPath: kp] ?? []) != nuova {
                    pezzi[g, default: ArchivioPezzi.vuoto][keyPath: kp] = nuova
                    cambiati.insert(g)
                }
            }
            return (ordine, cambiati)
        }, raccogli: { pezzi, gruppi, ordine, dati in
            var code: [String: ArraySlice<T>] = [:]
            var totale = 0
            for (g, p) in pezzi {
                let parte = p[keyPath: kp]
                if !parte.isEmpty { code[g] = parte[...]; totale += parte.count }
            }
            var r: [T] = []
            r.reserveCapacity(totale)
            for c in ordine ?? [] {
                guard let q = code[c.gruppo], !q.isEmpty else { continue }
                let n = min(c.quanti, q.count)
                r.append(contentsOf: q.prefix(n))
                code[c.gruppo] = q.dropFirst(n)
            }
            // Ciò che l'ordine non conta (un pezzo scritto dopo l'indice): in fondo, gruppo per gruppo
            for g in gruppi {
                if let q = code[g], !q.isEmpty {
                    r.append(contentsOf: q)
                    code[g] = nil
                }
            }
            for g in code.keys.sorted() { if let q = code[g] { r.append(contentsOf: q) } }
            dati[keyPath: kp] = r
        }, vuoto: { $0[keyPath: kp].isEmpty })
    }

    static func dizionario<V: Equatable>(_ k: DatiPrisma.CodingKeys, _ kp: WritableKeyPath<DatiPrisma, [String: V]>) -> CampoPezzoCliente {
        CampoPezzoCliente(chiave: k, distribuisci: { dati, gruppo, pezzi in
            var parti: [String: [String: V]] = [:]
            for (id, v) in dati[keyPath: kp] { parti[gruppo(id), default: [:]][id] = v }
            var cambiati = Set<String>()
            for g in Set(parti.keys).union(pezzi.keys) {
                let nuova = parti[g] ?? [:]
                if (pezzi[g]?[keyPath: kp] ?? [:]) != nuova {
                    pezzi[g, default: ArchivioPezzi.vuoto][keyPath: kp] = nuova
                    cambiati.insert(g)
                }
            }
            return (nil, cambiati)
        }, raccogli: { pezzi, _, _, dati in
            var r: [String: V] = [:]
            for p in pezzi.values { r.merge(p[keyPath: kp]) { primo, _ in primo } }
            dati[keyPath: kp] = r
        }, vuoto: { $0[keyPath: kp].isEmpty })
    }
}

/// Un pezzo da scrivere: le chiavi di `DatiPrisma` scelte e la generazione.
private struct PezzoDaScrivere: Encodable {
    let dati: DatiPrisma
    let chiavi: Set<DatiPrisma.CodingKeys>
    let generazione: Int

    private enum Meta: String, CodingKey { case generazionePezzo }

    func encode(to encoder: Encoder) throws {
        try dati.codifica(in: encoder, solo: chiavi)
        var m = encoder.container(keyedBy: Meta.self)
        try m.encode(generazione, forKey: .generazionePezzo)
    }
}

/// Solo la generazione di un pezzo (per i file che l'indice non cita).
private struct MetaPezzo: Decodable {
    var generazionePezzo: Int?
}

// MARK: - Lettura

/// L'archivio letto dalla cartella a pezzi, con l'indice com'era sul disco.
struct LetturaArchivio {
    var dati: DatiPrisma
    var indice: IndiceArchivio
}

/// Un pezzo che non si è potuto leggere.
struct ProblemaPezzo: Equatable {
    var file: URL
    /// «il file di Giulia Rossi», «l'agenda»…
    var descrizione: String
    var mancante: Bool
}

enum ErroreArchivioPezzi: LocalizedError {
    /// L'indice c'è ma il contenuto non si decodifica (rovinato): si può ricostruire dai file.
    case indiceNonLeggibile(String)
    /// L'indice non c'è: si può ricostruire dai file.
    case indiceMancante
    /// Formato su disco più recente di questo Prisma: sola lettura, nulla si tocca.
    case formatoPiuRecente
    /// Versione dei dati più recente (letta anche da un indice che questo Prisma non sa decodificare): sola lettura.
    case versionePiuRecente
    /// Un file che c'è ma che adesso non si legge (errore del disco, permessi, protezione dei dati di iPhone e iPad a
    /// dispositivo bloccato): non è rovinato, quindi non si mette da parte né si ricostruisce. Sola lettura.
    case nonLeggibileOra(String)

    var errorDescription: String? {
        switch self {
        case .indiceNonLeggibile(let m): return "L'indice dell'archivio non è leggibile: \(m)"
        case .indiceMancante: return "L'indice dell'archivio non c'è."
        case .formatoPiuRecente, .versionePiuRecente: return "L'archivio è stato scritto da una versione più recente di Prisma."
        case .nonLeggibileOra(let m): return "In questo momento non riesco a leggere \(m)."
        }
    }

    /// true se l'archivio si può ricostruire dai file presenti (indice rovinato o mancante); false se va aperto in sola
    /// lettura senza toccare nulla (versione più recente, file non leggibili adesso).
    var ricostruibile: Bool {
        switch self {
        case .indiceNonLeggibile, .indiceMancante: return true
        case .formatoPiuRecente, .versionePiuRecente, .nonLeggibileOra: return false
        }
    }
}

/// Solo formato e versione dell'indice: si leggono anche quando il resto non si decodifica (un indice scritto da un
/// Prisma più recente, con un campo che questo non conosce, non è un indice rovinato).
private struct SoloFormatoIndice: Decodable {
    var formato: Int?
    var versione: Int?
}

extension ArchivioPezzi {
    /// I nomi leggibili delle sezioni, per gli avvisi.
    static func descrizione(sezione nome: String) -> String {
        switch nome {
        case "agenda": return "l'agenda"
        case "attivita": return "le attività"
        case "conversazioni": return "le conversazioni con Vera"
        case "prodotti": return "le schede prodotto"
        case "spazi": return "gli spazi di lavoro"
        case "pratiche": return "le pratiche"
        case "mercato": return "i dati di Mercato"
        case "ovunque": return "Prisma ovunque"
        case "studio": return "lo studio (portafogli modello, famiglie, esame OCF)"
        case "routine": return "le routine di Vera"
        case "vera": return "i dati di Vera (il tagliando dei dati)"
        default: return "la sezione «\(nome)»"
        }
    }

    /// Legge l'indice (piccolo). Lancia sempre un `ErroreArchivioPezzi`: `.indiceMancante`, `.nonLeggibileOra` (c'è ma
    /// adesso non si apre), `.formatoPiuRecente` / `.versionePiuRecente` (scritto da un Prisma più recente, anche se il
    /// resto non si decodifica: come `SoloVersione` per archivio.json) oppure `.indiceNonLeggibile` (rovinato).
    static func leggiIndice(_ cartellaPezzi: URL) throws -> IndiceArchivio {
        try leggiIndice(file: cartellaPezzi.appendingPathComponent(nomeIndice))
    }

    /// Come `leggiIndice(_:)`, per un file qualsiasi (l'indice, la sua riserva, quello della copia d'avvio).
    static func leggiIndice(file url: URL) throws -> IndiceArchivio {
        let grezzo: Data
        do {
            grezzo = try Data(contentsOf: url)
        } catch {
            guard FileManager.default.fileExists(atPath: url.path) else { throw ErroreArchivioPezzi.indiceMancante }
            throw ErroreArchivioPezzi.nonLeggibileOra("l'indice dell'archivio (\(error.localizedDescription))")
        }
        let indice: IndiceArchivio
        do {
            indice = try decodificatore.decode(IndiceArchivio.self, from: grezzo)
        } catch {
            if let v = try? decodificatore.decode(SoloFormatoIndice.self, from: grezzo) {
                if let f = v.formato, f > formatoAttuale { throw ErroreArchivioPezzi.formatoPiuRecente }
                if let n = v.versione, n > DatiPrisma.versioneAttuale { throw ErroreArchivioPezzi.versionePiuRecente }
            }
            throw ErroreArchivioPezzi.indiceNonLeggibile(error.localizedDescription)
        }
        guard indice.formato <= formatoAttuale else { throw ErroreArchivioPezzi.formatoPiuRecente }
        return indice
    }

    /// L'indice da cui ricostruire un indice rovinato o mancante: la sua riserva (scritta con lui, quindi di adesso), se
    /// si legge e non è più vecchia della copia d'avvio; altrimenti l'indice della copia d'avvio (impostazioni, contatori
    /// di Prisma ovunque e ordine dell'ultimo avvio: `attuale` false, l'avviso lo dice); senza nessuno dei due, uno vuoto.
    /// Lancia `.formatoPiuRecente` / `.versionePiuRecente` se la riserva è di un Prisma più recente (sola lettura).
    static func indiceDiRiserva(_ cartellaPezzi: URL, copiaAvvio: URL) throws -> (indice: IndiceArchivio, attuale: Bool) {
        let copia = try? leggiIndice(copiaAvvio)
        do {
            let r = try leggiIndice(file: cartellaPezzi.appendingPathComponent(nomeRiserva))
            if r.versione > DatiPrisma.versioneAttuale { throw ErroreArchivioPezzi.versionePiuRecente }
            if r.generazione >= (copia?.generazione ?? Int.min) { return (r, true) }
        } catch ErroreArchivioPezzi.formatoPiuRecente {
            throw ErroreArchivioPezzi.formatoPiuRecente
        } catch ErroreArchivioPezzi.versionePiuRecente {
            throw ErroreArchivioPezzi.versionePiuRecente
        } catch {}
        if let copia { return (copia, false) }
        return (IndiceArchivio(), false)
    }

    /// Legge tutta la cartella a pezzi. Non scrive nulla: chi chiama decide che fare dei pezzi non leggibili.
    /// - indiceLetto: chiamato appena l'indice è letto (e solo se il formato e la versione sono di questo Prisma),
    ///   prima dei file dei clienti: StatoShell parte con la schermata di benvenuto senza aspettare il resto.
    /// - indiceDiRiserva: se l'indice è rovinato o manca (mai se è di un Prisma più recente o se adesso non si apre), si
    ///   ricostruisce l'archivio dai file presenti partendo da questo indice (la riserva dell'indice o quello della copia
    ///   fatta all'avvio, `indiceDiRiserva(_:copiaAvvio:)`): i
    ///   clienti che cita si cercano come sempre (un file che manca si segnala), un file che non cita si riprende solo se
    ///   è stato scritto dopo di lui, altrimenti è il resto di un cliente tolto e si mette da parte (non torna in vita).
    ///   Senza riserva lancia l'errore dell'indice.
    /// Lancia `.nonLeggibileOra` se un file c'è ma adesso non si legge: non è rovinato, non si deve mettere da parte.
    /// I file dei clienti e le sezioni si leggono in parallelo.
    static func leggi(_ cartellaPezzi: URL, indiceLetto: ((IndiceArchivio) -> Void)? = nil,
                      indiceDiRiserva: IndiceArchivio? = nil) throws -> (lettura: LetturaArchivio, problemi: [ProblemaPezzo], scartati: [URL]) {
        let fm = FileManager.default
        var indice: IndiceArchivio
        var ricostruito = false
        do {
            indice = try leggiIndice(cartellaPezzi)
        } catch let e as ErroreArchivioPezzi where e.ricostruibile {
            guard var riserva = indiceDiRiserva else { throw e }
            // Ricostruzione: i clienti e la generazione della copia d'avvio, le sezioni tutte
            riserva.sezioni = sezioni.map(\.nome)
            indice = riserva
            ricostruito = true
        }
        guard indice.formato <= formatoAttuale else { throw ErroreArchivioPezzi.formatoPiuRecente }
        if indice.versione <= DatiPrisma.versioneAttuale, !ricostruito { indiceLetto?(indice) }

        let cartellaClienti = cartellaPezzi.appendingPathComponent(nomeClienti, isDirectory: true)
        enum Compito { case cliente(VoceIndice), senzaCliente(String), sezione(String), sciolto(String) }
        var compiti: [Compito] = indice.clienti.map { .cliente($0) }
        if let s = indice.senzaCliente { compiti.append(.senzaCliente(s)) }
        let citati = Set(indice.clienti.map(\.file) + [indice.senzaCliente].compactMap { $0 })
        let presenti = ((try? fm.contentsOfDirectory(atPath: cartellaClienti.path)) ?? []).filter { $0.hasSuffix(".json") }
        for nome in presenti.sorted() where !citati.contains(nome) { compiti.append(.sciolto(nome)) }
        for s in sezioni where indice.sezioni.contains(s.nome) { compiti.append(.sezione(s.nome)) }

        enum Esito { case letto(DatiPrisma, generazione: Int?), manca, rovinato(String), nonLeggibileOra(String) }
        var esiti = [Esito](repeating: .manca, count: compiti.count)
        let blocco = NSLock()
        DispatchQueue.concurrentPerform(iterations: compiti.count) { i in
            let url: URL
            var serveGenerazione = false
            switch compiti[i] {
            case .cliente(let v): url = cartellaClienti.appendingPathComponent(v.file)
            case .senzaCliente(let f): url = cartellaClienti.appendingPathComponent(f)
            case .sciolto(let f):
                url = cartellaClienti.appendingPathComponent(f)
                serveGenerazione = true
            case .sezione(let n): url = cartellaPezzi.appendingPathComponent(nomeFileSezione(n))
            }
            let esito: Esito
            do {
                let grezzo = try Data(contentsOf: url)
                do {
                    let d = try decodificatore.decode(DatiPrisma.self, from: grezzo)
                    let g = serveGenerazione ? (try? decodificatore.decode(MetaPezzo.self, from: grezzo))?.generazionePezzo : nil
                    esito = .letto(d, generazione: g)
                } catch {
                    esito = .rovinato(error.localizedDescription)
                }
            } catch {
                // Rovinato è solo un contenuto che non si decodifica: un file che c'è e non si apre è un problema del
                // momento (disco, permessi, dispositivo bloccato), non va messo da parte né riscritto
                esito = fm.fileExists(atPath: url.path) ? .nonLeggibileOra("«\(url.lastPathComponent)» (\(error.localizedDescription))") : .manca
            }
            blocco.lock()
            esiti[i] = esito
            blocco.unlock()
        }

        for e in esiti { if case .nonLeggibileOra(let m) = e { throw ErroreArchivioPezzi.nonLeggibileOra(m) } }

        var pezzi: [String: DatiPrisma] = [:]
        var gruppi: [String] = []
        var sezioniLette: [String: DatiPrisma] = [:]
        var problemi: [ProblemaPezzo] = []
        var scartati: [URL] = []
        for (i, compito) in compiti.enumerated() {
            switch (compito, esiti[i]) {
            case (_, .nonLeggibileOra):
                break // già lanciato sopra
            case (.cliente(let v), .letto(let d, _)):
                pezzi[v.id] = d
                gruppi.append(v.id)
            case (.cliente(let v), .manca):
                problemi.append(ProblemaPezzo(file: cartellaClienti.appendingPathComponent(v.file), descrizione: "il file di «\(v.nome)»", mancante: true))
            case (.cliente(let v), .rovinato):
                problemi.append(ProblemaPezzo(file: cartellaClienti.appendingPathComponent(v.file), descrizione: "il file di «\(v.nome)»", mancante: false))
            case (.senzaCliente, .letto(let d, _)):
                pezzi[gruppoAltri] = d
                gruppi.append(gruppoAltri)
            case (.senzaCliente(let f), let e):
                if case .letto = e { break }
                let mancante: Bool
                if case .manca = e { mancante = true } else { mancante = false }
                problemi.append(ProblemaPezzo(file: cartellaClienti.appendingPathComponent(f), descrizione: "il file degli elementi senza cliente", mancante: mancante))
            case (.sciolto(let f), .letto(let d, let g)):
                // Scritto dopo l'indice: si riprende. Più vecchio: un cliente tolto il cui file non si era ancora
                // cancellato; con l'indice buono si scarta, in una ricostruzione si mette da parte (mai perso, ma il
                // cliente tolto non torna in vita)
                if (g ?? Int.min) > indice.generazione {
                    let gruppo = f == nomeSenzaCliente ? gruppoAltri : (d.clienti.first?.id ?? "file:" + f)
                    if pezzi[gruppo] == nil {
                        pezzi[gruppo] = d
                        gruppi.append(gruppo)
                    }
                } else if ricostruito {
                    problemi.append(ProblemaPezzo(file: cartellaClienti.appendingPathComponent(f),
                                                  descrizione: "il file «\(f)» (non era nell'archivio all'ultimo avvio)", mancante: false))
                } else {
                    scartati.append(cartellaClienti.appendingPathComponent(f))
                }
            case (.sciolto(let f), _):
                // Un file non citato e illeggibile: non si perde (si mette da parte come gli altri rovinati)
                problemi.append(ProblemaPezzo(file: cartellaClienti.appendingPathComponent(f), descrizione: "il file «\(f)»", mancante: false))
            case (.sezione(let n), .letto(let d, _)):
                sezioniLette[n] = d
            case (.sezione(let n), let e):
                let mancante: Bool
                if case .manca = e { mancante = true } else { mancante = false }
                problemi.append(ProblemaPezzo(file: cartellaPezzi.appendingPathComponent(nomeFileSezione(n)), descrizione: descrizione(sezione: n), mancante: mancante))
            }
        }

        var dati = scheletro(indice)
        for campo in campiCliente {
            campo.raccogli(pezzi, gruppi, indice.ordini[campo.chiave.rawValue], &dati)
        }
        for s in sezioni {
            guard let p = sezioniLette[s.nome] else { continue }
            for k in s.chiavi { copia(k, da: p, in: &dati) }
        }
        if ricostruito, dati.clienteAttivoId.isEmpty || !dati.clienti.contains(where: { $0.id == dati.clienteAttivoId }) {
            dati.clienteAttivoId = dati.clienti.first?.id ?? ""
        }
        return (LetturaArchivio(dati: dati, indice: indice), problemi, scartati)
    }
}

// MARK: - Transazioni (un cambio che tocca più file)

/// Il manifesto di una transazione (`Archivio/in-corso/conferma.json`). È il punto di conferma: si scrive per ultimo,
/// dopo tutti i file nuovi, con la sincronizzazione completa del disco. Prima di lui nulla è stato toccato fuori dalla
/// cartella «in-corso» (un'interruzione lascia l'archivio com'era); dopo di lui la transazione si completa sempre, subito
/// o al primo avvio (`ArchivioPezzi.completaTransazione`): l'archivio è quello nuovo, tutto intero.
struct ConfermaTransazione: Codable {
    /// Coppie [file dentro «in-corso», destinazione relativa ad «Archivio/»], l'indice per ultimo.
    var sposta: [[String]]
    /// File da togliere (relativi ad «Archivio/»), dopo l'indice nuovo che non li cita più.
    var togli: [String]
}

enum ErroreTransazione: LocalizedError {
    case nonCompletata(String)

    var errorDescription: String? {
        switch self {
        case .nonCompletata(let m): return "L'ultimo salvataggio dell'archivio non si è potuto completare: \(m)"
        }
    }
}

extension ArchivioPezzi {
    static let nomeTransazione = "in-corso"
    static let nomeConferma = "conferma.json"

    /// Completa una transazione confermata rimasta a metà, o scarta quella non confermata (i file nuovi non erano
    /// ancora al loro posto: l'archivio è quello di prima). Si può ripetere quante volte serve: un file già spostato
    /// non si sposta di nuovo. Lancia se non riesce a finire (allora l'archivio non va letto né scritto). Restituisce i
    /// file da togliere che non si sono potuti togliere (da riprovare).
    /// - limite: solo per la prova, quanti spostamenti fare prima di fermarsi, mai i file da togliere (un'interruzione a
    ///   metà).
    @discardableResult
    static func completaTransazione(_ cartellaPezzi: URL, limite: Int? = nil) throws -> [String] {
        let fm = FileManager.default
        let tx = cartellaPezzi.appendingPathComponent(nomeTransazione, isDirectory: true)
        guard fm.fileExists(atPath: tx.path) else { return [] }
        let fileConferma = tx.appendingPathComponent(nomeConferma)
        let grezzo: Data
        do {
            grezzo = try Data(contentsOf: fileConferma)
        } catch {
            guard !fm.fileExists(atPath: fileConferma.path) else {
                throw ErroreTransazione.nonCompletata("la conferma non si legge (\(error.localizedDescription))")
            }
            // Mai confermata: via i file nuovi, l'archivio resta com'era
            try? fm.removeItem(at: tx)
            return []
        }
        guard let conferma = try? JSONDecoder().decode(ConfermaTransazione.self, from: grezzo) else {
            // La conferma si scrive con una rinomina: un contenuto rovinato vuol dire un disco rovinato. Si scarta
            try? fm.removeItem(at: tx)
            return []
        }
        var fatti = 0
        for coppia in conferma.sposta where coppia.count == 2 {
            let da = tx.appendingPathComponent(coppia[0])
            let a = cartellaPezzi.appendingPathComponent(coppia[1])
            guard fm.fileExists(atPath: da.path) else { continue } // già al suo posto
            if let limite, fatti >= limite { return [] }
            try? fm.createDirectory(at: a.deletingLastPathComponent(), withIntermediateDirectories: true)
            guard rename(da.path, a.path) == 0 else {
                throw ErroreTransazione.nonCompletata("«\(coppia[1])» non si sposta (errore \(errno))")
            }
            fatti += 1
        }
        // La prova si ferma comunque prima di togliere i file
        if limite != nil { return [] }
        // Le rinomine sul disco prima di togliere i file e la conferma
        Archivio.sincronizza(cartellaPezzi)
        Archivio.sincronizza(cartellaPezzi.appendingPathComponent(nomeClienti, isDirectory: true))
        var falliti: [String] = []
        for f in conferma.togli {
            let u = cartellaPezzi.appendingPathComponent(f)
            if fm.fileExists(atPath: u.path), (try? fm.removeItem(at: u)) == nil { falliti.append(f) }
        }
        try? fm.removeItem(at: fileConferma)
        try? fm.removeItem(at: tx)
        return falliti
    }
}

// MARK: - Scrittura

/// La scrittura della cartella a pezzi: tutta (la prima volta, dopo un ripristino, se l'indice sul disco non è più
/// quello scritto) o solo i file cambiati. Si usa da una coda sola (`Archivio.coda` per l'app): tiene in memoria
/// ciò che c'è sul disco per confrontarlo con i dati nuovi.
///
/// Quali clienti sono cambiati lo dice il confronto, fuori dal thread principale: per ogni campo diviso per cliente
/// che non è più lo stesso (un confronto che per gli elenchi non toccati costa quanto un puntatore), si rifà la
/// parte di ogni cliente e si scrivono solo i file dei clienti la cui parte è diversa. Così nessuna strada di
/// modifica (un tasto, `carica`, Prisma ovunque, un'importazione) può dimenticare di segnare un cliente.
///
/// Un giro che scrive un file solo (il caso di ogni tasto) lo sostituisce con una rinomina. Un giro che tocca più file
/// (una nota spostata da un cliente a un altro, un cliente nuovo con l'indice, un cliente tolto) è una transazione:
/// tutto o niente anche se il Mac si spegne a metà (`ConfermaTransazione`).
final class ScrittorePezzi {
    /// La cartella dell'archivio («Prisma»): i pezzi vanno in «Archivio/».
    let cartella: URL
    var cartellaPezzi: URL { ArchivioPezzi.cartellaPezzi(in: cartella) }
    var cartellaClienti: URL { cartellaPezzi.appendingPathComponent(ArchivioPezzi.nomeClienti, isDirectory: true) }
    var fileIndice: URL { cartellaPezzi.appendingPathComponent(ArchivioPezzi.nomeIndice) }

    /// Ciò che è sul disco, com'è stato scritto o letto.
    private struct Scritto {
        var dati: DatiPrisma
        var pezzi: [String: DatiPrisma]
        var file: [String: String]
        var indice: IndiceArchivio
        var firma: [FileAttributeKey: AnyHashable]
    }
    private var scritto: Scritto?

    /// Un file da scrivere: il nome relativo ad «Archivio/» e il pezzo.
    private typealias Lavoro = (nome: String, pezzo: PezzoDaScrivere)

    /// Solo per le prove: dove si ferma il prossimo giro, come se il Mac si spegnesse lì.
    enum Interruzione {
        /// I file nuovi scritti in «in-corso», la conferma no.
        case primaDellaConferma
        /// Confermato, ma solo `spostati` file messi al loro posto e nessun file tolto.
        case dopoLaConferma(spostati: Int)
    }

    /// I file scritti nell'ultimo giro (nomi relativi a «Archivio/»), per la prova.
    private(set) var ultimiScritti: [String] = []
    /// Solo per la prova: il prossimo giro si interrompe a metà.
    var interrompi: Interruzione?
    /// Solo per la prova: la verifica della conversione fallisce (come se la cartella riletta fosse diversa).
    var verificaFallitaPerProva = false
    /// Solo per la prova: la scrittura completa si ferma dopo la conferma, prima della verifica della conversione (come
    /// se Prisma si interrompesse lì).
    var fermaPrimaDellaVerificaPerProva = false
    /// La conversione non si è potuta verificare: si continua a scrivere archivio.json come prima (finché nella cartella
    /// non torna una cartella a pezzi, per esempio con un ripristino).
    private(set) var formatoVecchio = false
    /// File di clienti tolti che non si sono potuti cancellare: si riprova al giro dopo.
    private var daTogliereInSospeso = Set<String>()

    init(cartella: URL) {
        self.cartella = cartella
    }

    /// Ciò che c'è sul disco (appena letto senza problemi): i salvataggi dopo scrivono solo le differenze.
    /// nil = il prossimo salvataggio riscrive tutto.
    func riparti(da lettura: LetturaArchivio?) {
        ultimiScritti = []
        guard let lettura else {
            scritto = nil
            return
        }
        var pezzi: [String: DatiPrisma] = [:]
        let gruppo = gruppoDi(lettura.dati)
        for campo in ArchivioPezzi.campiCliente { _ = campo.distribuisci(lettura.dati, gruppo, &pezzi) }
        var file: [String: String] = [:]
        for v in lettura.indice.clienti { file[v.id] = v.file }
        if let s = lettura.indice.senzaCliente { file[ArchivioPezzi.gruppoAltri] = s }
        scritto = Scritto(dati: lettura.dati, pezzi: pezzi, file: file, indice: lettura.indice, firma: firma())
    }

    private func gruppoDi(_ d: DatiPrisma) -> (String) -> String {
        let noti = Set(d.clienti.map(\.id))
        return { noti.contains($0) ? $0 : ArchivioPezzi.gruppoAltri }
    }

    /// La firma dell'indice sul disco (numero del file, data e dimensione): se cambia, qualcuno ha sostituito la
    /// cartella (un ripristino) e il prossimo giro riscrive tutto.
    private func firma() -> [FileAttributeKey: AnyHashable] {
        let a = (try? FileManager.default.attributesOfItem(atPath: fileIndice.path)) ?? [:]
        var f: [FileAttributeKey: AnyHashable] = [:]
        for k in [FileAttributeKey.systemFileNumber, .modificationDate, .size] { if let v = a[k] as? AnyHashable { f[k] = v } }
        return f
    }

    /// Scrive `dati`: solo i file cambiati, oppure tutto. Con un archivio.json ancora nella cartella (archivio di
    /// prima o backup di prima appena ripristinato) la scrittura completa è la conversione: si rilegge la cartella e,
    /// se torna identica, archivio.json diventa archivio.json.vecchio.
    func scrivi(_ dati: DatiPrisma) throws {
        ultimiScritti = []
        if formatoVecchio {
            let fm = FileManager.default
            // Un ripristino ha rimesso la cartella a pezzi (senza il segno della conversione da verificare, che i backup
            // non portano) o tolto archivio.json: si torna a scrivere i pezzi
            let segno = fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeConversioneDaVerificare).path)
            if (ArchivioPezzi.presente(in: cartella) && !segno) || !fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileVecchio).path) {
                formatoVecchio = false
                scritto = nil
            } else {
                try Archivio.scriviVecchio(dati, in: cartella)
                return
            }
        }
        // Una transazione rimasta sul disco (un giro di prima che non si è completato, per esempio una rinomina non
        // riuscita): si completa e si riscrive tutto. Con le sole differenze un giro di un file solo la scavalcherebbe e
        // all'avvio dopo la transazione rimetterebbe il contenuto di prima sopra quello nuovo
        if scritto != nil, FileManager.default.fileExists(atPath: cartellaPezzi.appendingPathComponent(ArchivioPezzi.nomeTransazione).path) {
            scritto = nil
        }
        guard let s = scritto, !s.firma.isEmpty, s.firma == firma() else {
            try scriviTutto(dati)
            return
        }
        try scriviCambi(dati, rispetto: s)
    }

    private func scriviTutto(_ dati: DatiPrisma) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: cartellaClienti, withIntermediateDirectories: true)
        // Una transazione confermata e non finita va completata prima di leggere l'indice di adesso
        daTogliereInSospeso.formUnion(try ArchivioPezzi.completaTransazione(cartellaPezzi))
        // Mai sotto la copia d'avvio: dopo una ricostruzione (indice rovinato e messo da parte) i file nuovi devono
        // risultare scritti dopo di lei, altrimenti una seconda ricostruzione li scambierebbe per clienti tolti
        let copiaAvvio = cartella.appendingPathComponent(Archivio.nomeCopiaAvvio, isDirectory: true)
        let generazione = max(scritto?.indice.generazione ?? (try? ArchivioPezzi.leggiIndice(cartellaPezzi))?.generazione ?? 0,
                              (try? ArchivioPezzi.leggiIndice(copiaAvvio))?.generazione ?? 0) &+ 1
        var pezzi: [String: DatiPrisma] = [:]
        var ordini: [String: [Corsa]] = [:]
        let gruppo = gruppoDi(dati)
        for campo in ArchivioPezzi.campiCliente {
            let (o, _) = campo.distribuisci(dati, gruppo, &pezzi)
            if let o { ordini[campo.chiave.rawValue] = o }
        }
        pezzi = pezzi.filter { $0.key != ArchivioPezzi.gruppoAltri || !ArchivioPezzi.vuoto($0.value) }
        let file = assegnaFile(Set(pezzi.keys), dati: dati, precedenti: scritto?.file ?? [:])
        var lavori: [Lavoro] = []
        for (g, p) in pezzi {
            let f = file[g] ?? ArchivioPezzi.nomeFile(cliente: g)
            lavori.append((ArchivioPezzi.nomeClienti + "/" + f, PezzoDaScrivere(dati: p, chiavi: ArchivioPezzi.chiaviCliente, generazione: generazione)))
        }
        for s in ArchivioPezzi.sezioni {
            lavori.append((ArchivioPezzi.nomeFileSezione(s.nome), PezzoDaScrivere(dati: dati, chiavi: s.chiavi, generazione: generazione)))
        }
        let indice = nuovoIndice(dati, file: file, ordini: ordini, generazione: generazione)
        // Via (nella stessa transazione, dopo l'indice) tutto ciò che il nuovo indice non cita: file di prima, pezzi di
        // una conversione interrotta
        let validi = Set(file.values)
        let togli = ((try? fm.contentsOfDirectory(atPath: cartellaClienti.path)) ?? [])
            .filter { !validi.contains($0) && !$0.contains(".tmp-") }
            .map { ArchivioPezzi.nomeClienti + "/" + $0 }
        // Con un archivio.json vero accanto è la conversione: prima di confermare la cartella si lascia il segno che va
        // ancora verificata. Finché c'è, vale archivio.json (all'avvio la verifica si rifà, i backup prendono lui)
        let vecchio = cartella.appendingPathComponent(Archivio.nomeFileVecchio)
        let segno = cartella.appendingPathComponent(Archivio.nomeConversioneDaVerificare)
        if fm.fileExists(atPath: vecchio.path), !Archivio.segnaposto(vecchio) {
            if !fm.fileExists(atPath: segno.path) {
                try Archivio.scriviAtomico(Data("{}".utf8), in: segno)
                Archivio.sincronizza(cartella)
            }
        } else {
            try? fm.removeItem(at: segno)
        }
        guard try applica(lavori, indice: Archivio.nuovoCodificatore().encode(indice), togli: togli) else { return }
        Archivio.pulisciTemporanei(in: cartellaPezzi)
        scritto = Scritto(dati: dati, pezzi: pezzi, file: file, indice: indice, firma: firma())
        if fermaPrimaDellaVerificaPerProva { return }
        try convertiSeServe(dati)
    }

    private func scriviCambi(_ dati: DatiPrisma, rispetto s: Scritto) throws {
        var pezzi = s.pezzi
        var ordini = s.indice.ordini
        let tutti = Set(dati.clienti.map(\.id)) != Set(s.dati.clienti.map(\.id))
        let gruppo = gruppoDi(dati)
        var cambiati = Set<String>()
        for campo in ArchivioPezzi.campiCliente where tutti || !ArchivioPezzi.uguale(campo.chiave, dati, s.dati) {
            let (o, c) = campo.distribuisci(dati, gruppo, &pezzi)
            cambiati.formUnion(c)
            if let o { ordini[campo.chiave.rawValue] = o }
        }
        // I gruppi senza più nulla (un cliente tolto, nessun elemento senza cliente) non hanno file
        let noti = Set(dati.clienti.map(\.id))
        var daTogliere: [String] = []
        for (g, p) in pezzi where !noti.contains(g) && (g != ArchivioPezzi.gruppoAltri || ArchivioPezzi.vuoto(p)) {
            pezzi[g] = nil
            cambiati.remove(g)
            if let f = s.file[g] { daTogliere.append(f) }
        }
        let file = assegnaFile(Set(pezzi.keys), dati: dati, precedenti: s.file)
        let generazione = s.indice.generazione &+ 1
        var lavori: [Lavoro] = []
        for g in cambiati.sorted() {
            guard let p = pezzi[g], let f = file[g] else { continue }
            lavori.append((ArchivioPezzi.nomeClienti + "/" + f, PezzoDaScrivere(dati: p, chiavi: ArchivioPezzi.chiaviCliente, generazione: generazione)))
        }
        // Anche le sezioni che l'indice di prima non cita (nate in una versione dopo, come «routine» e «vera» della fase 4
        // di Vera): l'indice nuovo le cita tutte, quindi il loro file va scritto anche se il contenuto non è cambiato
        for sez in ArchivioPezzi.sezioni where !s.indice.sezioni.contains(sez.nome)
            || sez.chiavi.contains(where: { !ArchivioPezzi.uguale($0, dati, s.dati) }) {
            lavori.append((ArchivioPezzi.nomeFileSezione(sez.nome), PezzoDaScrivere(dati: dati, chiavi: sez.chiavi, generazione: generazione)))
        }
        var indice = nuovoIndice(dati, file: file, ordini: ordini, generazione: generazione)
        var datiIndice: Data?
        if indice.stessoContenuto(di: s.indice) {
            indice = s.indice
        } else {
            datiIndice = try Archivio.nuovoCodificatore().encode(indice)
        }
        // Solo dopo l'indice nuovo, che non li cita più (con quelli rimasti dai giri prima)
        let validi = Set(file.values)
        let togli = Set(daTogliere.map { ArchivioPezzi.nomeClienti + "/" + $0 }).union(daTogliereInSospeso)
            .filter { !validi.contains(String($0.dropFirst(ArchivioPezzi.nomeClienti.count + 1))) }
        guard try applica(lavori, indice: datiIndice, togli: togli.sorted()) else { return }
        scritto = Scritto(dati: dati, pezzi: pezzi, file: file, indice: indice, firma: firma())
    }

    /// Scrive i file di un giro. Uno solo e niente da togliere: temporaneo e rinomina. Il solo indice: la riserva e poi
    /// l'indice, ognuno con la sua rinomina (un'interruzione in mezzo lascia una riserva più nuova dell'indice, con gli
    /// stessi file: innocua). Altrimenti una transazione: i file nuovi (indice e riserva compresi) in «in-corso», poi la
    /// conferma, poi tutti al loro posto, l'indice per ultimo. L'indice si scrive sempre con la sua riserva.
    /// false solo se la prova ha interrotto il giro.
    private func applica(_ lavori: [Lavoro], indice: Data?, togli: [String]) throws -> Bool {
        let fm = FileManager.default
        let nomi = lavori.map(\.nome) + (indice == nil ? [] : [ArchivioPezzi.nomeRiserva, ArchivioPezzi.nomeIndice])
        if togli.isEmpty, lavori.count + (indice == nil ? 0 : 1) <= 1 {
            if let l = lavori.first {
                try Archivio.scriviAtomico(Archivio.nuovoCodificatore().encode(l.pezzo), in: cartellaPezzi.appendingPathComponent(l.nome))
            } else if let indice {
                try Archivio.scriviAtomico(indice, in: cartellaPezzi.appendingPathComponent(ArchivioPezzi.nomeRiserva))
                try Archivio.scriviAtomico(indice, in: fileIndice)
            }
            ultimiScritti = nomi
            return true
        }
        // Una transazione di prima confermata e non finita si completa; una non confermata si scarta
        daTogliereInSospeso.formUnion(try ArchivioPezzi.completaTransazione(cartellaPezzi))
        let tx = cartellaPezzi.appendingPathComponent(ArchivioPezzi.nomeTransazione, isDirectory: true)
        try fm.createDirectory(at: tx, withIntermediateDirectories: true)
        var confermata = false
        var interrotta = false
        // Un errore prima della conferma: via i file nuovi, l'archivio resta com'era
        defer { if !confermata, !interrotta { try? fm.removeItem(at: tx) } }
        var errori = [Error?](repeating: nil, count: lavori.count)
        let blocco = NSLock()
        DispatchQueue.concurrentPerform(iterations: lavori.count) { i in
            do {
                let u = tx.appendingPathComponent("\(i).json")
                try Archivio.nuovoCodificatore().encode(lavori[i].pezzo).write(to: u, options: Archivio.opzioniScritturaDiretta)
                Archivio.sincronizza(u)
            } catch {
                blocco.lock()
                errori[i] = error
                blocco.unlock()
            }
        }
        if let e = errori.compactMap({ $0 }).first { throw e }
        var sposta = lavori.indices.map { ["\($0).json", lavori[$0].nome] }
        if let indice {
            // La riserva prima dell'indice: l'indice resta l'ultimo file messo al suo posto
            for nome in [ArchivioPezzi.nomeRiserva, ArchivioPezzi.nomeIndice] {
                let u = tx.appendingPathComponent(nome)
                try indice.write(to: u, options: Archivio.opzioniScritturaDiretta)
                Archivio.sincronizza(u)
                sposta.append([nome, nome])
            }
        }
        if case .primaDellaConferma = interrompi {
            interrompi = nil
            interrotta = true
            return false
        }
        // La conferma: con la sincronizzazione completa (tutti i file scritti prima sono sul disco), poi la rinomina
        let conferma = try JSONEncoder().encode(ConfermaTransazione(sposta: sposta, togli: togli))
        try Archivio.scriviAtomico(conferma, in: tx.appendingPathComponent(ArchivioPezzi.nomeConferma), completo: true)
        Archivio.sincronizza(tx)
        confermata = true
        if case .dopoLaConferma(let k) = interrompi {
            interrompi = nil
            _ = try ArchivioPezzi.completaTransazione(cartellaPezzi, limite: k)
            return false
        }
        let falliti = try ArchivioPezzi.completaTransazione(cartellaPezzi)
        daTogliereInSospeso = Set(falliti)
        ultimiScritti = nomi
        return true
    }

    /// Il file di ogni gruppo: quello di prima se c'era, altrimenti uno nuovo che non si sovrappone a nessun altro.
    private func assegnaFile(_ gruppi: Set<String>, dati: DatiPrisma, precedenti: [String: String]) -> [String: String] {
        var file: [String: String] = [:]
        var usati = Set<String>()
        for g in gruppi.sorted() {
            if let f = precedenti[g], !usati.contains(f.lowercased()) {
                file[g] = f
                usati.insert(f.lowercased())
            }
        }
        for g in gruppi.sorted() where file[g] == nil {
            var nome = g == ArchivioPezzi.gruppoAltri ? ArchivioPezzi.nomeSenzaCliente : ArchivioPezzi.nomeFile(cliente: g)
            var n = 2
            while usati.contains(nome.lowercased()) {
                nome = String(nome.dropLast(5)) + "-\(n).json"
                n += 1
            }
            file[g] = nome
            usati.insert(nome.lowercased())
        }
        return file
    }

    private func nuovoIndice(_ dati: DatiPrisma, file: [String: String], ordini: [String: [Corsa]], generazione: Int) -> IndiceArchivio {
        var i = IndiceArchivio()
        i.generazione = generazione
        i.versione = dati.versione
        i.clienteAttivoId = dati.clienteAttivoId
        i.impostazioni = dati.impostazioni
        var visti = Set<String>()
        for c in dati.clienti where visti.insert(c.id).inserted {
            i.clienti.append(VoceIndice(id: c.id, file: file[c.id] ?? ArchivioPezzi.nomeFile(cliente: c.id), nome: c.nome))
        }
        i.senzaCliente = file[ArchivioPezzi.gruppoAltri]
        i.sezioni = ArchivioPezzi.sezioni.map(\.nome)
        i.ordini = ordini
        return i
    }

    /// Dopo una scrittura completa: se nella cartella c'è ancora archivio.json, la conversione si verifica rileggendo
    /// la cartella; uguale ai dati (passati per il JSON come archivio.json) → archivio.json.vecchio. Diversa (non deve
    /// succedere) → via la cartella a pezzi, archivio.json resta e si continua a scrivere lui.
    /// Il confronto è sul JSON (con le chiavi in ordine), non con `==`: un NaN salvato come "nan" non è uguale a se
    /// stesso, e con `==` la conversione fallirebbe a ogni avvio.
    private func convertiSeServe(_ dati: DatiPrisma) throws {
        let fm = FileManager.default
        let vecchio = cartella.appendingPathComponent(Archivio.nomeFileVecchio)
        guard fm.fileExists(atPath: vecchio.path), !Archivio.segnaposto(vecchio) else { return }
        let codificatore = Archivio.nuovoCodificatore()
        let atteso = try codificatore.encode(Archivio.decodifica(codificatore.encode(dati)))
        let riletto = try? ArchivioPezzi.leggi(cartellaPezzi)
        let rilettoJSON = riletto.flatMap { r in r.problemi.isEmpty ? try? codificatore.encode(r.lettura.dati) : nil }
        let segno = cartella.appendingPathComponent(Archivio.nomeConversioneDaVerificare)
        // Verificata: via il segno (se non si toglie, la conversione non vale: all'avvio vincerebbe archivio.json, che non
        // avrebbe le modifiche di dopo), poi archivio.json da parte. Se la rinomina non riesce archivio.json resta, più
        // vecchio della cartella e senza segno: all'avvio vale la cartella e archivio.json si mette da parte
        if rilettoJSON == atteso, !verificaFallitaPerProva, (try? fm.removeItem(at: segno)) != nil || !fm.fileExists(atPath: segno.path) {
            Archivio.sincronizza(cartella)
            let copia = cartella.appendingPathComponent(Archivio.nomeFileConvertito)
            try? fm.removeItem(at: copia)
            try fm.moveItem(at: vecchio, to: copia)
        } else {
            // La cartella a pezzi non va: via con una rinomina (tutta o niente; poi si cancella con calma), così non
            // restano pezzi sciolti che all'avvio o in un backup sembrino l'archivio. Il segno resta: anche se la
            // rinomina non riuscisse, all'avvio e nei backup vale archivio.json. Via anche la copia d'avvio della
            // cartella a pezzi: è di un altro giorno e non deve fare da riserva
            let scartata = cartella.appendingPathComponent(Archivio.prefissoCartellaScartata + UUID().uuidString.prefix(8).lowercased(), isDirectory: true)
            if rename(cartellaPezzi.path, scartata.path) == 0 { try? fm.removeItem(at: scartata) }
            try? fm.removeItem(at: cartella.appendingPathComponent(Archivio.nomeCopiaAvvio, isDirectory: true))
            scritto = nil
            formatoVecchio = true
            try Archivio.scriviVecchio(dati, in: cartella)
        }
    }
}
