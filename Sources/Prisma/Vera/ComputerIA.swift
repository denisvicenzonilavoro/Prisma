import Foundation
import Network

// Il computer dell'IA (motori Mistral, tappa 2): un Mac dello studio, con tanta memoria, che fa girare i motori grandi
// (Mistral Small 4 e, di notte, Mistral Large 4). Ha Prisma aperto con «Questo Mac è il computer dell'IA» acceso.
// Il Mac di lavoro gli parla con il ponte cifrato di Vera (PonteVera.swift, lo stesso di iPhone e iPad): buste
// ChaChaPoly con la chiave del codice di abbinamento, solo in rete locale, mai internet. Il computer dell'IA accetta
// il modello chiesto solo se ce l'ha già scaricato; altrimenti risponde con il suo modello, come per il telefono.
// Se il computer dell'IA è spento o non si trova, Vera lavora sul Mac con il modello più grande che ci entra.

/// Le impostazioni del computer dell'IA (dentro le impostazioni di Vera: archivio e backup).
struct ImpostazioniComputerIA: Codable, Equatable {
    /// Su questo Mac: è il computer dell'IA. Con il collegamento di Impostazioni › iPhone e iPad acceso (lo stesso
    /// ascolto cifrato), accetta i modelli Mistral chiesti dal Mac di lavoro e gli dice memoria e modelli.
    var questoMac = false
    /// Sul Mac di lavoro: usa il computer dell'IA per i motori che non entrano qui.
    var usa = false
    /// Il codice di abbinamento del computer dell'IA (quello che compare là in Impostazioni › iPhone e iPad).
    var codice = ""

    init() {}

    private enum CodingKeys: String, CodingKey { case questoMac, usa, codice }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        questoMac = (try? c.decodeIfPresent(Bool.self, forKey: .questoMac)) ?? false
        usa = (try? c.decodeIfPresent(Bool.self, forKey: .usa)) ?? false
        codice = (try? c.decodeIfPresent(String.self, forKey: .codice)) ?? ""
    }

    /// Il Mac di lavoro cerca il computer dell'IA: acceso e con un codice valido.
    var attivo: Bool { usa && PonteVera.normalizza(codice) != nil }
}

/// Come sta il computer dell'IA, visto dal Mac di lavoro (dal suo «prisma/stato»).
struct StatoComputerIA: Equatable {
    /// «Mac Studio dello studio».
    let nome: String
    /// http://192.168.1.30:47620
    let indirizzo: String
    let memoriaGB: Double
    let prismaGB: Double
    /// I modelli scaricati là.
    let installati: [String]
    /// I modelli caricati in memoria là, con i GB che occupano.
    let inMemoria: [String: Double]

    /// Il modello è scaricato sul computer dell'IA?
    func ha(_ modello: String) -> Bool { installati.contains { FornitoreOllama.stessoModello($0, modello) } }

    /// La memoria del computer dell'IA per l'interfaccia («Memoria del computer dell'IA 38%»).
    var memoria: MemoriaMotore {
        MemoriaMotore(dove: .computerIA, totaleGB: memoriaGB, prismaGB: prismaGB, modelliGB: inMemoria.values.reduce(0, +))
    }

    /// Dallo stato del ponte; nil se chi risponde non è un computer dell'IA (un Mac qualsiasi con il ponte acceso).
    init?(_ s: StatoPonte, indirizzo: String) {
        guard s.computerIA == true, let m = s.memoriaGB, m > 0 else { return nil }
        nome = s.mac
        self.indirizzo = indirizzo
        memoriaGB = m
        prismaGB = s.prismaGB ?? 0
        installati = (s.installati ?? []).map { $0.lowercased() }
        inMemoria = s.inMemoria ?? [:]
    }

    init(nome: String, indirizzo: String, memoriaGB: Double, prismaGB: Double = 0, installati: [String], inMemoria: [String: Double] = [:]) {
        self.nome = nome
        self.indirizzo = indirizzo
        self.memoriaGB = memoriaGB
        self.prismaGB = prismaGB
        self.installati = installati.map { $0.lowercased() }
        self.inMemoria = inMemoria
    }
}

enum ComputerIA {
    /// Il fornitore per un modello del computer dell'IA: il ponte cifrato con il suo codice.
    static func fornitore(_ vera: ImpostazioniVera, stato: StatoComputerIA, modello: String,
                          sessione: URLSession = .shared) -> FornitorePonte {
        FornitorePonte(indirizzo: stato.indirizzo, codice: vera.computerIA.codice, tipo: .ollama, modello: modello,
                       sessione: sessione, mac: stato.nome)
    }

    /// Cerca il computer dell'IA: prima l'ultimo indirizzo, poi tutti i Mac con il ponte in rete (Bonjour). Vale solo
    /// quello che apre le buste con il codice del computer dell'IA e dice di esserlo. nil se non c'è.
    static func collega(_ vera: ImpostazioniVera, sessione: URLSession = .shared) async -> StatoComputerIA? {
        guard vera.computerIA.attivo else { return nil }
        var candidati: [String] = []
        if let ultimo = indirizzo { candidati.append(ultimo) }
        if let s = await prova(candidati, vera: vera, sessione: sessione) { return s }
        candidati = await RicercaMac.tutti().filter { $0 != indirizzo }
        guard let s = await prova(candidati, vera: vera, sessione: sessione) else { return nil }
        indirizzo = s.indirizzo
        return s
    }

    /// Il primo indirizzo che risponde come computer dell'IA.
    static func prova(_ indirizzi: [String], vera: ImpostazioniVera, sessione: URLSession = .shared) async -> StatoComputerIA? {
        for i in indirizzi {
            let f = FornitorePonte(indirizzo: i, codice: vera.computerIA.codice, tipo: .ollama, modello: vera.modello, sessione: sessione)
            if let st = await f.stato(attesa: 2), let c = StatoComputerIA(st, indirizzo: i) { return c }
        }
        return nil
    }

    private static let blocco = NSLock()
    private static var _indirizzo: String?

    /// L'ultimo indirizzo del computer dell'IA (solo in memoria: la rete dello studio può cambiare).
    static var indirizzo: String? {
        get { blocco.lock(); defer { blocco.unlock() }; return _indirizzo }
        set { blocco.lock(); _indirizzo = newValue; blocco.unlock() }
    }
}

extension RicercaMac {
    /// Tutti i Mac con il ponte acceso in rete, trovati entro `attesa` secondi (per il computer dell'IA: il Mac di lavoro
    /// può avere il suo ponte acceso per l'iPhone, e lo scarta perché non apre le buste con il codice del computer dell'IA).
    static func tutti(attesa: TimeInterval = RicercaMac.attesa) async -> [String] {
        await withCheckedContinuation { (fine: CheckedContinuation<[String], Never>) in
            RicercaTutti(fine, attesa: attesa).avvia()
        }
    }

    private final class RicercaTutti: @unchecked Sendable {
        private var fine: CheckedContinuation<[String], Never>?
        private var browser: NWBrowser?
        private var connessioni: [NWConnection] = []
        private var trovati: [String] = []
        private let attesa: TimeInterval
        private let coda = DispatchQueue(label: "prisma.ponte.ricerca.tutti")

        init(_ fine: CheckedContinuation<[String], Never>, attesa: TimeInterval) {
            self.fine = fine
            self.attesa = attesa
        }

        func avvia() {
            let parametri = NWParameters.tcp
            parametri.includePeerToPeer = false
            let b = NWBrowser(for: .bonjour(type: PonteVera.servizio, domain: nil), using: parametri)
            browser = b
            b.browseResultsChangedHandler = { [weak self] risultati, _ in
                guard let self else { return }
                for r in risultati { self.risolvi(r.endpoint) }
            }
            b.stateUpdateHandler = { [weak self] s in
                if case .failed = s { self?.chiudi() }
            }
            b.start(queue: coda)
            // La ricerca tiene vivo l'oggetto fino alla fine (il ciclo si rompe in `chiudi`)
            coda.asyncAfter(deadline: .now() + attesa) { self.chiudi() }
        }

        private func risolvi(_ e: NWEndpoint) {
            let p = NWParameters.tcp
            if let ip = p.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options { ip.version = .v4 }
            let c = NWConnection(to: e, using: p)
            connessioni.append(c)
            c.stateUpdateHandler = { [weak self, weak c] s in
                guard let self, let c else { return }
                if case .ready = s, case let .hostPort(host, porta)? = c.currentPath?.remoteEndpoint {
                    var h = "\(host)"
                    if let i = h.firstIndex(of: "%") { h = String(h[..<i]) }
                    let indirizzo = "http://\(h):\(porta.rawValue)"
                    if !self.trovati.contains(indirizzo) { self.trovati.append(indirizzo) }
                    c.cancel()
                }
            }
            c.start(queue: coda)
        }

        private func chiudi() {
            guard let f = fine else { return }
            fine = nil
            browser?.cancel()
            connessioni.forEach { $0.cancel() }
            connessioni = []
            f.resume(returning: trovati)
        }
    }
}
