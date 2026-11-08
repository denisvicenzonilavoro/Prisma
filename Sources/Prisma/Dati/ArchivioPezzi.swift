import CryptoKit
import Foundation

// Proprietario: G2 (archivio). Giro 0 di «Prisma istantaneo», tappa 3 (Design/velocita-proposta.md, «L'archivio»).

/// L'archivio su disco a pezzi: la cartella «Archivio/» dentro ~/Library/Application Support/Prisma.
///
///     Archivio/
///       indice.json            versione del formato, generazione, versione dei dati, cliente attivo, impostazioni,
///                              elenco dei clienti (id, file, nome) e l'ordine degli elenchi divisi per cliente
///       Clienti/<id>-<impronta>.json   un file per cliente: anagrafica e ciò che è solo suo
///       Clienti/senza-cliente.json     gli elementi che nominano un cliente che non c'è più (mai persi)
///       agenda.json, attivita.json, conversazioni.json, prodotti.json, spazi.json, pratiche.json,
///       mercato.json, ovunque.json, studio.json      le sezioni comuni
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
             .sessioniCopilota, .partiteRischio, .promesse, .confrontiDocumenti, .coperture:
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
    case indiceNonLeggibile(String)
    case formatoPiuRecente

    var errorDescription: String? {
        switch self {
        case .indiceNonLeggibile(let m): return "L'indice dell'archivio non è leggibile: \(m)"
        case .formatoPiuRecente: return "L'archivio è stato scritto da una versione più recente di Prisma."
        }
    }
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
        default: return "la sezione «\(nome)»"
        }
    }

    /// Legge l'indice (piccolo). Lancia se manca o non si legge.
    static func leggiIndice(_ cartellaPezzi: URL) throws -> IndiceArchivio {
        let grezzo = try Data(contentsOf: cartellaPezzi.appendingPathComponent(nomeIndice))
        do {
            return try decodificatore.decode(IndiceArchivio.self, from: grezzo)
        } catch {
            throw ErroreArchivioPezzi.indiceNonLeggibile(error.localizedDescription)
        }
    }

    /// Legge tutta la cartella a pezzi. Non scrive nulla: chi chiama decide che fare dei pezzi non leggibili.
    /// - indiceLetto: chiamato appena l'indice è letto (e solo se il formato e la versione sono di questo Prisma),
    ///   prima dei file dei clienti: StatoShell parte con la schermata di benvenuto senza aspettare il resto.
    /// - indiceDiRiserva: se l'indice non si legge, si ricostruisce l'archivio dai file presenti con queste
    ///   impostazioni (quelle della copia fatta all'avvio); senza, lancia `.indiceNonLeggibile`.
    /// I file dei clienti e le sezioni si leggono in parallelo.
    static func leggi(_ cartellaPezzi: URL, indiceLetto: ((IndiceArchivio) -> Void)? = nil,
                      indiceDiRiserva: IndiceArchivio? = nil) throws -> (lettura: LetturaArchivio, problemi: [ProblemaPezzo], scartati: [URL]) {
        let fm = FileManager.default
        var indice: IndiceArchivio
        var ricostruito = false
        do {
            indice = try leggiIndice(cartellaPezzi)
        } catch {
            guard var riserva = indiceDiRiserva else { throw error }
            // Ricostruzione: nessun cliente citato (si riprendono tutti i file presenti), le sezioni tutte
            riserva.clienti = []
            riserva.senzaCliente = nil
            riserva.generazione = Int.min
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

        enum Esito { case letto(DatiPrisma, generazione: Int?), manca, rovinato(String) }
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
            if let grezzo = try? Data(contentsOf: url) {
                do {
                    let d = try decodificatore.decode(DatiPrisma.self, from: grezzo)
                    let g = serveGenerazione ? (try? decodificatore.decode(MetaPezzo.self, from: grezzo))?.generazionePezzo : nil
                    esito = .letto(d, generazione: g)
                } catch {
                    esito = .rovinato(error.localizedDescription)
                }
            } else {
                esito = fm.fileExists(atPath: url.path) ? .rovinato("non si apre") : .manca
            }
            blocco.lock()
            esiti[i] = esito
            blocco.unlock()
        }

        var pezzi: [String: DatiPrisma] = [:]
        var gruppi: [String] = []
        var sezioniLette: [String: DatiPrisma] = [:]
        var problemi: [ProblemaPezzo] = []
        var scartati: [URL] = []
        for (i, compito) in compiti.enumerated() {
            switch (compito, esiti[i]) {
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
                // Scritto dopo l'indice (salvataggio interrotto prima dell'indice): si riprende; più vecchio: un
                // cliente tolto il cui file non si era ancora cancellato
                if (g ?? Int.min) > indice.generazione || ricostruito {
                    let gruppo = f == nomeSenzaCliente ? gruppoAltri : (d.clienti.first?.id ?? "file:" + f)
                    if pezzi[gruppo] == nil {
                        pezzi[gruppo] = d
                        gruppi.append(gruppo)
                    }
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

// MARK: - Scrittura

/// La scrittura della cartella a pezzi: tutta (la prima volta, dopo un ripristino, se l'indice sul disco non è più
/// quello scritto) o solo i file cambiati. Si usa da una coda sola (`Archivio.coda` per l'app): tiene in memoria
/// ciò che c'è sul disco per confrontarlo con i dati nuovi.
///
/// Quali clienti sono cambiati lo dice il confronto, fuori dal thread principale: per ogni campo diviso per cliente
/// che non è più lo stesso (un confronto che per gli elenchi non toccati costa quanto un puntatore), si rifà la
/// parte di ogni cliente e si scrivono solo i file dei clienti la cui parte è diversa. Così nessuna strada di
/// modifica (un tasto, `carica`, Prisma ovunque, un'importazione) può dimenticare di segnare un cliente.
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

    /// I file scritti nell'ultimo giro (nomi relativi a «Archivio/»), per la prova.
    private(set) var ultimiScritti: [String] = []
    /// Solo per la prova: il giro si ferma dopo i pezzi, prima dell'indice (un salvataggio interrotto a metà).
    var interrompiPrimaDellIndice = false
    /// La conversione non si è potuta verificare: si continua a scrivere archivio.json come prima.
    private(set) var formatoVecchio = false

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
            try Archivio.scriviVecchio(dati, in: cartella)
            return
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
        let generazione = (scritto?.indice.generazione ?? (try? ArchivioPezzi.leggiIndice(cartellaPezzi))?.generazione ?? 0) &+ 1
        var pezzi: [String: DatiPrisma] = [:]
        var ordini: [String: [Corsa]] = [:]
        let gruppo = gruppoDi(dati)
        for campo in ArchivioPezzi.campiCliente {
            let (o, _) = campo.distribuisci(dati, gruppo, &pezzi)
            if let o { ordini[campo.chiave.rawValue] = o }
        }
        pezzi = pezzi.filter { $0.key != ArchivioPezzi.gruppoAltri || !ArchivioPezzi.vuoto($0.value) }
        let file = assegnaFile(Set(pezzi.keys), dati: dati, precedenti: scritto?.file ?? [:])
        var lavori: [(nome: String, url: URL, pezzo: PezzoDaScrivere)] = []
        for (g, p) in pezzi {
            let f = file[g] ?? ArchivioPezzi.nomeFile(cliente: g)
            lavori.append((ArchivioPezzi.nomeClienti + "/" + f, cartellaClienti.appendingPathComponent(f),
                           PezzoDaScrivere(dati: p, chiavi: ArchivioPezzi.chiaviCliente, generazione: generazione)))
        }
        for s in ArchivioPezzi.sezioni {
            let f = ArchivioPezzi.nomeFileSezione(s.nome)
            lavori.append((f, cartellaPezzi.appendingPathComponent(f), PezzoDaScrivere(dati: dati, chiavi: s.chiavi, generazione: generazione)))
        }
        try scriviInParallelo(lavori)
        let indice = nuovoIndice(dati, file: file, ordini: ordini, generazione: generazione)
        if interrompiPrimaDellIndice { return }
        try Archivio.scriviAtomico(Archivio.nuovoCodificatore().encode(indice), in: fileIndice)
        ultimiScritti.append(ArchivioPezzi.nomeIndice)
        // Via tutto ciò che il nuovo indice non cita (file di prima, pezzi di una conversione interrotta, temporanei)
        let validi = Set(file.values)
        for nome in (try? fm.contentsOfDirectory(atPath: cartellaClienti.path)) ?? [] where !validi.contains(nome) {
            try? fm.removeItem(at: cartellaClienti.appendingPathComponent(nome))
        }
        Archivio.pulisciTemporanei(in: cartellaPezzi)
        scritto = Scritto(dati: dati, pezzi: pezzi, file: file, indice: indice, firma: firma())
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
        var lavori: [(nome: String, url: URL, pezzo: PezzoDaScrivere)] = []
        for g in cambiati.sorted() {
            guard let p = pezzi[g], let f = file[g] else { continue }
            lavori.append((ArchivioPezzi.nomeClienti + "/" + f, cartellaClienti.appendingPathComponent(f),
                           PezzoDaScrivere(dati: p, chiavi: ArchivioPezzi.chiaviCliente, generazione: generazione)))
        }
        for sez in ArchivioPezzi.sezioni where sez.chiavi.contains(where: { !ArchivioPezzi.uguale($0, dati, s.dati) }) {
            let f = ArchivioPezzi.nomeFileSezione(sez.nome)
            lavori.append((f, cartellaPezzi.appendingPathComponent(f), PezzoDaScrivere(dati: dati, chiavi: sez.chiavi, generazione: generazione)))
        }
        try scriviInParallelo(lavori)
        var indice = nuovoIndice(dati, file: file, ordini: ordini, generazione: generazione)
        if interrompiPrimaDellIndice { return }
        if indice.stessoContenuto(di: s.indice) {
            indice = s.indice
        } else {
            try Archivio.scriviAtomico(Archivio.nuovoCodificatore().encode(indice), in: fileIndice)
            ultimiScritti.append(ArchivioPezzi.nomeIndice)
        }
        // Solo dopo l'indice nuovo, che non li cita più
        for f in daTogliere where !file.values.contains(f) {
            try? FileManager.default.removeItem(at: cartellaClienti.appendingPathComponent(f))
        }
        scritto = Scritto(dati: dati, pezzi: pezzi, file: file, indice: indice, firma: firma())
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

    /// Codifica in parallelo (un codificatore per lavoro) e scrive ogni file in modo atomico.
    private func scriviInParallelo(_ lavori: [(nome: String, url: URL, pezzo: PezzoDaScrivere)]) throws {
        guard !lavori.isEmpty else { return }
        var errori = [Error?](repeating: nil, count: lavori.count)
        let blocco = NSLock()
        DispatchQueue.concurrentPerform(iterations: lavori.count) { i in
            do {
                let data = try Archivio.nuovoCodificatore().encode(lavori[i].pezzo)
                try Archivio.scriviAtomico(data, in: lavori[i].url)
            } catch {
                blocco.lock()
                errori[i] = error
                blocco.unlock()
            }
        }
        if let e = errori.compactMap({ $0 }).first { throw e }
        ultimiScritti.append(contentsOf: lavori.map(\.nome))
    }

    /// Dopo una scrittura completa: se nella cartella c'è ancora archivio.json, la conversione si verifica rileggendo
    /// la cartella; uguale ai dati (passati per il JSON come archivio.json) → archivio.json.vecchio. Diversa (non deve
    /// succedere) → via la cartella a pezzi, archivio.json resta e si continua a scrivere lui.
    private func convertiSeServe(_ dati: DatiPrisma) throws {
        let fm = FileManager.default
        let vecchio = cartella.appendingPathComponent(Archivio.nomeFileVecchio)
        guard fm.fileExists(atPath: vecchio.path) else { return }
        let atteso = try Archivio.decodifica(Archivio.codificatore.encode(dati))
        let riletto = try? ArchivioPezzi.leggi(cartellaPezzi)
        if let riletto, riletto.problemi.isEmpty, riletto.lettura.dati == atteso {
            let copia = cartella.appendingPathComponent(Archivio.nomeFileConvertito)
            try? fm.removeItem(at: copia)
            try fm.moveItem(at: vecchio, to: copia)
        } else {
            try? fm.removeItem(at: cartellaPezzi)
            scritto = nil
            formatoVecchio = true
            try Archivio.scriviVecchio(dati, in: cartella)
        }
    }
}
