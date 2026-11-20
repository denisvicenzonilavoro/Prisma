import Foundation
import Observation

/// Lo stato di un modello per l'interfaccia di Vera («Il motore di Vera»).
struct StatoModelloVera: Equatable, Identifiable {
    enum Stato: String, Equatable {
        /// Caricato in memoria: risponde subito.
        case inMemoria
        /// Scaricato e pronto: alla prima domanda si carica.
        case pronto
        /// Entra nel computer ma non è ancora scaricato.
        case daScaricare
        /// Non entra nella memoria del computer: lavora il motore più piccolo.
        case nonEntra
        /// Ollama non risponde.
        case spento

        var nome: String {
            switch self {
            case .inMemoria: return "In memoria"
            case .pronto: return "Pronto"
            case .daScaricare: return "Da scaricare"
            case .nonEntra: return "Non entra in questo computer"
            case .spento: return "Spento"
            }
        }
    }

    let ruolo: RuoloMotore
    /// Il nome in Ollama.
    let modello: String
    let famiglia: String
    let dove: DoveLavora
    let stato: Stato
    /// La memoria che vuole mentre lavora (nil se il modello non è nel catalogo).
    let memoriaGB: Double?
    /// Una riga che spiega lo stato («Vuole circa 72 GB: il tuo Mac ne ha 8»).
    let spiegazione: String

    var id: String { ruolo.rawValue }
}

/// La memoria del computer per l'interfaccia: quanta ne usano Prisma e i modelli caricati.
struct MemoriaMotore: Equatable {
    let dove: DoveLavora
    let totaleGB: Double
    let prismaGB: Double
    /// I modelli caricati in Ollama in questo momento.
    let modelliGB: Double

    var usataGB: Double { prismaGB + modelliGB }
    /// La percentuale della memoria del computer usata da Prisma e dai modelli (0-100).
    var percentuale: Int { totaleGB > 0 ? Int((min(1, usataGB / totaleGB) * 100).rounded()) : 0 }
}

/// Quello che l'interfaccia di Vera riceve sul motore: il motore attivo, lo stato dei modelli e la memoria usata.
/// È un oggetto a parte (`StatoShell.motoreVera`), osservato solo da chi lo mostra; con il computer dell'IA (tappa 2) anche
/// la sua memoria. Il ragionamento da aprire e chiudere (tappa 3) e il resoconto del turno di notte (tappa 4) si aggiungono qui.
@Observable final class StatoMotoreVera {
    /// L'ultima scelta: il motore che lavora (o ha lavorato per ultimo).
    private(set) var attivo: SceltaMotore?
    /// Lo stato dei tre ruoli, nell'ordine Lampo, Quotidiano, Profondo.
    private(set) var modelli: [StatoModelloVera] = []
    private(set) var memoria: MemoriaMotore?
    /// Il computer dell'IA collegato (nil se non c'è o non risponde): nome, memoria e modelli.
    private(set) var computerIA: StatoComputerIA?
    /// La memoria del computer dell'IA («Memoria del computer dell'IA 38%»).
    var memoriaIA: MemoriaMotore? { computerIA?.memoria }
    /// I modelli scaricati in Ollama all'ultimo controllo (nil se Ollama non ha risposto).
    @ObservationIgnored private(set) var installati: [String]?
    @ObservationIgnored private(set) var aggiornatoIl: Date?

    /// Sceglie il motore per un compito e lo segna come attivo.
    @discardableResult
    func scegli(_ compito: CompitoVera, vera: ImpostazioniVera, notte: Bool = false) -> SceltaMotore {
        let s = SceltaMotori.scegli(compito, vera: vera, installati: installati, computerIA: computerIA, notte: notte)
        if attivo != s { attivo = s }
        return s
    }

    /// Chiede a Ollama, sul Mac, i modelli scaricati e quelli in memoria (/api/tags e /api/ps), poi aggiorna lo stato.
    /// Solo indirizzi locali (lo controlla `IndirizzoLocale`); su iPhone e iPad il motore è quello del Mac e qui non si chiede.
    func aggiorna(vera: ImpostazioniVera) async {
        #if os(macOS)
        var installati: [String]?
        var caricati: [String: Double] = [:]
        if vera.fornitore == .ollama {
            let ollama = FornitoreOllama(indirizzo: vera.indirizzoLocale, modello: vera.modelloLocale)
            installati = try? await ollama.modelli()
            if installati != nil { caricati = await ollama.inMemoria() }
        } else {
            installati = try? await FornitoriVera.crea(vera).modelli()
        }
        // Il computer dell'IA, se Vera lo usa: l'ultimo indirizzo o una ricerca in rete locale (ponte cifrato)
        let ia = await ComputerIA.collega(vera)
        let totale = MemoriaComputer.totaleGB
        let stati = Self.stati(vera: vera, installati: installati, caricati: caricati, memoriaMac: totale, computerIA: ia)
        let memoria = MemoriaMotore(dove: .mac, totaleGB: totale, prismaGB: MemoriaComputer.prismaGB(),
                                    modelliGB: caricati.values.reduce(0, +))
        await MainActor.run {
            self.installati = installati
            self.aggiornatoIl = Date()
            if self.modelli != stati { self.modelli = stati }
            if self.memoria != memoria { self.memoria = memoria }
            if self.computerIA != ia { self.computerIA = ia }
        }
        #endif
    }

    /// Lo stato dei tre ruoli: solo regole, per l'interfaccia e per le prove.
    static func stati(vera: ImpostazioniVera, installati: [String]?, caricati: [String: Double],
                      memoriaMac: Double, computerIA: StatoComputerIA? = nil) -> [StatoModelloVera] {
        RuoloMotore.allCases.map { (ruolo: RuoloMotore) -> StatoModelloVera in
            let nome: String
            switch ruolo {
            case .lampo: nome = vera.modello
            case .quotidiano: nome = vera.motori.modelloQuotidiano
            case .profondo: nome = vera.motori.modelloProfondo
            }
            let catalogo = CatalogoMistral.modello(nome)
            let gb = catalogo?.memoriaGB
            let famiglia = catalogo?.famiglia ?? (ruolo == .lampo ? MotoreLocale.nome(nome) : nome)
            // Quotidiano e Profondo sul computer dell'IA, se c'è e ci entrano
            if ruolo != .lampo, let ia = computerIA {
                let vuole = gb ?? CatalogoMistral.predefinito(ruolo).memoriaGB
                let stato: StatoModelloVera.Stato
                let spiegazione: String
                if vuole > MemoriaComputer.perIlModello(totale: ia.memoriaGB) {
                    stato = .nonEntra
                    spiegazione = "Vuole circa \(SceltaMotori.gb(vuole)): \(ia.nome) ne ha \(SceltaMotori.gb(ia.memoriaGB.rounded()))."
                } else if ia.inMemoria.keys.contains(where: { FornitoreOllama.stessoModello($0, nome) }) {
                    stato = .inMemoria
                    spiegazione = "Caricato su \(ia.nome): risponde subito."
                } else if ia.ha(nome) {
                    stato = .pronto
                    spiegazione = ruolo == .profondo ? "Pronto su \(ia.nome): lavora nel turno di notte." : "Pronto su \(ia.nome)."
                } else {
                    stato = .daScaricare
                    spiegazione = "Da scaricare su \(ia.nome) con «ollama pull \(nome)»."
                }
                return StatoModelloVera(ruolo: ruolo, modello: nome, famiglia: famiglia, dove: .computerIA, stato: stato,
                                        memoriaGB: gb, spiegazione: spiegazione)
            }
            let perIlModello = MemoriaComputer.perIlModello(totale: memoriaMac)
            let inMemoria = caricati.keys.contains { FornitoreOllama.stessoModello($0, nome) }
            let scaricato = installati?.contains { FornitoreOllama.stessoModello($0, nome) } ?? false
            let stato: StatoModelloVera.Stato
            let spiegazione: String
            if ruolo != .lampo, let gb, gb > perIlModello {
                stato = .nonEntra
                spiegazione = "Vuole circa \(SceltaMotori.gb(gb)): il tuo Mac ne ha \(SceltaMotori.gb(memoriaMac.rounded())). "
                    + "Finché non c'è il computer dell'IA lavora \(CatalogoMistral.famiglia(vera.modello))."
            } else if installati == nil {
                stato = .spento
                spiegazione = "Ollama non risponde sul Mac."
            } else if inMemoria {
                stato = .inMemoria
                spiegazione = "Caricato: risponde subito."
            } else if scaricato {
                stato = .pronto
                spiegazione = "Scaricato: si carica alla prima domanda."
            } else {
                stato = .daScaricare
                spiegazione = "Da scaricare con «ollama pull \(nome)»."
            }
            return StatoModelloVera(ruolo: ruolo, modello: nome, famiglia: famiglia, dove: .mac, stato: stato,
                                    memoriaGB: gb, spiegazione: spiegazione)
        }
    }
}

extension FornitoreOllama {
    /// I modelli caricati in memoria adesso (/api/ps), con la memoria che occupano in GB.
    func inMemoria() async -> [String: Double] {
        guard let j = await leggiJSON("api/ps") else { return [:] }
        return Self.inMemoria(j)
    }

    /// La risposta di /api/ps: {"models":[{"name":"ministral-3:3b","size":3400000000,…}]}.
    static func inMemoria(_ j: Any) -> [String: Double] {
        var r: [String: Double] = [:]
        for m in ((j as? [String: Any])?["models"] as? [[String: Any]]) ?? [] {
            guard let nome = (m["name"] as? String ?? m["model"] as? String)?.lowercased() else { continue }
            let byte = (m["size"] as? NSNumber)?.doubleValue ?? 0
            r[nome] = byte / 1_073_741_824
        }
        return r
    }
}
