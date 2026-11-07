#if os(macOS)
import AppKit
#endif
import Foundation

// Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.5.2 punto 5, «Luce» giro 6): lo stato della
// ricerca, a parte (come `StatoInquadra`), così la ricerca non ridisegna le altre app. I documenti restano quelli di
// `StatoBiblioteca` (un solo elenco con «Il codice in tasca»); qui ci sono la domanda, il risultato, il documento aperto,
// le letture in corso, l'indice in memoria e il testo delle pagine (dai `<id>.txt` della cartella della Biblioteca).

/// Un documento che si sta leggendo (PDFKit, Vision per le scansioni).
struct LetturaBiblioteca: Identifiable, Equatable {
    let id: String
    var nome: String
    var lette: Int
    var totale: Int
}

/// Una pagina aperta nel vassoio (clic su un documento, su una pagina vicina, su un articolo di Vera).
struct PaginaAperta: Equatable {
    var documentoId: String
    var pagina: Int
}

/// Il risultato di una domanda.
struct RisultatoBiblioteca: Equatable {
    enum Stato: Equatable {
        /// Prisma ha trovato i passi, Vera sta scrivendo.
        case cerca
        case risposta
        case nonTrovata
        /// Vera ha risposto, ma Prisma non ha trovato la frase nel passo (o una cifra, o un nome in più).
        case nonVerificata(String)
        /// Vera (Qwen) non è pronta: la pagina più vicina con i passi evidenziati.
        case senzaVera
    }

    var domanda: String
    var stato: Stato
    var trovati: [PassoTrovato]
    /// Il passo della pagina mostrata.
    var passo: PassoBiblioteca?
    var frase: String?
    var risposta: String?
    var pagineCercate: Int
    var avviso: String?
    var vicini: [PassoBiblioteca] = []

    /// I passi da evidenziare quando non c'è una frase: quelli trovati sulla stessa pagina.
    var passiEvidenziati: [PassoBiblioteca] {
        guard frase == nil, let p = passo else { return [] }
        let stessi = trovati.map(\.passo).filter { $0.documentoId == p.documentoId && $0.pagina == p.pagina }
        return stessi.isEmpty ? [p] : stessi
    }
}

final class StatoTrovaPagina: ObservableObject {
    @Published var domanda = ""
    @Published var risultato: RisultatoBiblioteca?
    @Published var aperta: PaginaAperta?
    @Published private(set) var letture: [LetturaBiblioteca] = []
    @Published private(set) var indice: IndiceBiblioteca = .vuoto
    /// Cresce a ogni pagina nuova da raggiungere: il vassoio fa il giro delle pagine.
    @Published private(set) var giro = 0

    let persistente: Bool
    let biblioteca: StatoBiblioteca
    private var firmaIndice: String?
    private var indiceInCorso: String?
    private var inAttesa: [(IndiceBiblioteca) -> Void] = []
    var compito: Task<Void, Never>?
    /// Il testo dei documenti senza file (prove, istantanee, fac-simile in memoria).
    private var memoria: [String: [String]] = [:]
    /// Il testo letto dai file, al più ~4 milioni di caratteri (i meno recenti si dimenticano).
    private var cache: [String: [String]] = [:]
    private var ordineCache: [String] = []
    private static let tettoCache = 4_000_000
    private static let coda = DispatchQueue(label: "prisma.biblioteca.indice", qos: .utility)
    static let codaLettura = DispatchQueue(label: "prisma.biblioteca.lettura", qos: .userInitiated)

    init(biblioteca: StatoBiblioteca, persistente: Bool) {
        self.biblioteca = biblioteca
        self.persistente = persistente
    }

    static var cartella: URL { StatoBiblioteca.cartella }

    func nuovoGiro() { giro &+= 1 }

    /// Dopo un ripristino: testi, indice e risultato si rifanno dalla cartella ripristinata.
    func azzera() {
        compito?.cancel()
        compito = nil
        cache = [:]
        ordineCache = []
        firmaIndice = nil
        indiceInCorso = nil
        indice = .vuoto
        risultato = nil
        aperta = nil
    }

    // MARK: - Testo delle pagine

    /// Le pagine di un documento: dal file di testo, dalla memoria o (i testi di «Il codice in tasca» di prima) dagli
    /// articoli rimessi sulle loro pagine.
    func pagine(_ d: DocumentoBiblioteca) -> [String] {
        if let m = memoria[d.id] { return m }
        if let c = cache[d.id] { return c }
        let lette = Self.leggi(d, memoria: nil)
        guard !lette.isEmpty else { return [] }
        cache[d.id] = lette
        ordineCache.removeAll { $0 == d.id }
        ordineCache.append(d.id)
        var totale = cache.values.reduce(0) { $0 + $1.reduce(0) { $0 + $1.count } }
        while totale > Self.tettoCache, ordineCache.count > 1 {
            let via = ordineCache.removeFirst()
            totale -= cache[via]?.reduce(0) { $0 + $1.count } ?? 0
            cache[via] = nil
        }
        return lette
    }

    /// Il testo di un documento senza toccare lo stato (anche fuori dal thread principale).
    private static func leggi(_ d: DocumentoBiblioteca, memoria: [String]?) -> [String] {
        if let memoria { return memoria }
        if let nome = d.testo, let t = try? String(contentsOf: cartella.appendingPathComponent(nome), encoding: .utf8) {
            return t.components(separatedBy: LetturaDocumenti.separatorePagine)
        }
        guard !d.articoli.isEmpty else { return [] }
        let n = max(1, d.articoli.map(\.pagina).max() ?? 1)
        var pagine = Array(repeating: "", count: n)
        for a in d.articoli {
            let titolo = NormeVera.etichetta(a.numero).capitalized(with: Locale(identifier: "it_IT")) + (a.rubrica.isEmpty ? "" : " – \(a.rubrica)")
            pagine[max(0, a.pagina - 1)] += (pagine[max(0, a.pagina - 1)].isEmpty ? "" : "\n\n") + titolo + "\n\n" + a.testo
        }
        return pagine
    }

    /// Salva il testo di un documento accanto al PDF (o solo in memoria, fuori dall'app).
    func salvaTesto(_ id: String, _ pagine: [String]) {
        guard persistente else {
            memoria[id] = pagine
            return
        }
        cache[id] = pagine
        ordineCache.append(id)
        let testo = pagine.joined(separator: LetturaDocumenti.separatorePagine)
        Self.codaLettura.async {
            try? FileManager.default.createDirectory(at: Self.cartella, withIntermediateDirectories: true)
            try? Data(testo.utf8).write(to: Self.cartella.appendingPathComponent("\(id).txt"), options: Archivio.opzioniScrittura)
        }
    }

    func dimentica(_ id: String) {
        memoria[id] = nil
        cache[id] = nil
        ordineCache.removeAll { $0 == id }
        if persistente {
            let file = Self.cartella.appendingPathComponent("\(id).txt")
            Self.codaLettura.async { try? FileManager.default.removeItem(at: file) }
        }
    }

    // MARK: - Indice

    private var firmaAttuale: String {
        biblioteca.tutti.filter { !$0.illeggibile }.map { "\($0.id):\($0.numeroPagine):\($0.titolo)" }.joined(separator: "|")
    }

    /// L'indice aggiornato: subito se c'è già; altrimenti si costruisce fuori dal thread principale (coda propria,
    /// priorità bassa) e `poi` arriva sul thread principale. Fuori dall'app (prove, istantanee) si costruisce subito.
    func conIndice(_ poi: @escaping (IndiceBiblioteca) -> Void) {
        let firma = firmaAttuale
        if firma == firmaIndice { return poi(indice) }
        let documenti = biblioteca.tutti.filter { !$0.illeggibile }
        let memorie = documenti.map { memoria[$0.id] }
        guard persistente else {
            let fonti = zip(documenti, memorie).map { d, m in
                MotoreBiblioteca.Fonte(id: d.id, titolo: d.titolo, pagine: Self.leggi(d, memoria: m), importatoIl: d.importatoIl)
            }
            indice = MotoreBiblioteca.indice(fonti)
            firmaIndice = firma
            return poi(indice)
        }
        inAttesa.append(poi)
        guard indiceInCorso != firma else { return }
        indiceInCorso = firma
        Self.coda.async { [weak self] in
            let fonti = zip(documenti, memorie).map { d, m in
                autoreleasepool {
                    MotoreBiblioteca.Fonte(id: d.id, titolo: d.titolo, pagine: Self.leggi(d, memoria: m), importatoIl: d.importatoIl)
                }
            }
            let nuovo = MotoreBiblioteca.indice(fonti)
            DispatchQueue.main.async {
                guard let self, self.indiceInCorso == firma else { return }
                self.indice = nuovo
                self.firmaIndice = firma
                self.indiceInCorso = nil
                let attese = self.inAttesa
                self.inAttesa = []
                attese.forEach { $0(nuovo) }
            }
        }
    }

    /// Prepara l'indice all'apertura della Biblioteca (fuori dal thread principale).
    func preparaIndice() { conIndice { _ in } }

    /// Cerca i passi: la ricerca BM25 gira sulla coda dell'indice, il risultato arriva sul thread principale.
    func cerca(_ domanda: String, poi: @escaping ([PassoTrovato], IndiceBiblioteca) -> Void) {
        conIndice { indice in
            guard self.persistente else { return poi(MotoreBiblioteca.cerca(domanda, in: indice), indice) }
            Self.coda.async {
                let trovati = MotoreBiblioteca.cerca(domanda, in: indice)
                DispatchQueue.main.async { poi(trovati, indice) }
            }
        }
    }

    // MARK: - Letture

    func iniziaLettura(_ l: LetturaBiblioteca) { letture.append(l) }

    func avanza(_ id: String, lette: Int, totale: Int) {
        guard let i = letture.firstIndex(where: { $0.id == id }) else { return }
        letture[i].lette = lette
        letture[i].totale = totale
    }

    func finisciLettura(_ id: String) { letture.removeAll { $0.id == id } }

    /// Solo per le istantanee: letture ferme a metà.
    func mostraLetture(_ l: [LetturaBiblioteca]) { letture = l }
}
