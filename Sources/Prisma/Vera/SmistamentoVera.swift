import Foundation
import Observation

// «Due velocità» (Vera/BRIEF.md, fase 5, funzione 23): una funzione di codice smista ogni richiesta. Prima le regole a
// parole (i comandi di oggi, StatoShell.smistaVera ed eseguiComandoVera), poi il modello Apple (predisposto ma SPENTO
// per scelta dell'utente, CLAUDE.md «Niente modello Apple»), infine Qwen. Se la risposta veloce non è valida la domanda
// passa a Qwen; sotto macOS 26, o con il modello Apple spento, tutto ciò che non è regole va a Qwen senza errori.

/// Chi ha risposto a una richiesta.
enum CorsiaVera: String, Codable, CaseIterable {
    /// Regole e calcoli di Prisma, senza modello.
    case regole
    /// Il modello Apple sul Mac (spento).
    case apple
    /// Qwen sul Mac (anche la Vera su misura).
    case qwen
    /// Il motore esterno (non collegato).
    case esterno

    /// Dal motore scritto sotto la risposta: «Azione», «Prisma», «Calcoli di Prisma» → regole; il motore esterno; il
    /// modello Apple; altrimenti Qwen.
    static func da(motore: String?) -> CorsiaVera {
        guard let m = motore, !m.isEmpty else { return .regole }
        if m == StatoShell.motoreAzioni || m == "Prisma" || m == MotoriVera.sintesi.nome { return .regole }
        if m == CervelloGrandeVera.nome { return .esterno }
        if m == ModelloAppleVera.nome { return .apple }
        return .qwen
    }
}

/// Una richiesta smistata, per la pagina «Due velocità» (solo in memoria).
struct RichiestaSmistata: Identifiable, Equatable {
    var id = UUID().uuidString
    var testo: String
    var corsia: CorsiaVera
    var secondi: Double
    var quando: Date
}

/// Le richieste smistate oggi: al massimo 40, solo in memoria (mai nell'archivio né nei backup), contano quelle del giorno.
@Observable final class StatoDueVelocita {
    static let massimo = 40
    private(set) var voci: [RichiestaSmistata] = []

    func registra(_ testo: String, corsia: CorsiaVera, secondi: Double, quando: Date = Date()) {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        voci.append(RichiestaSmistata(testo: t, corsia: corsia, secondi: max(0, secondi), quando: quando))
        if voci.count > Self.massimo { voci.removeFirst(voci.count - Self.massimo) }
    }

    func richieste(_ c: CorsiaVera, oggi: Date = Date()) -> [RichiestaSmistata] {
        voci.filter { $0.corsia == c && Calendar.current.isDate($0.quando, inSameDayAs: oggi) }
    }

    /// I secondi medi di oggi nella corsia (nil senza richieste).
    func media(_ c: CorsiaVera, oggi: Date = Date()) -> Double? {
        let r = richieste(c, oggi: oggi)
        guard !r.isEmpty else { return nil }
        return r.reduce(0) { $0 + $1.secondi } / Double(r.count)
    }

    func azzera() { voci = [] }
}

/// Un motore veloce per le domande brevi (il modello Apple, quando l'utente lo accenderà).
protocol MotoreVeloce {
    var nome: String { get }
    func rispondi(istruzioni: String, domanda: String) async throws -> String
}

enum SmistamentoVera {
    static let massimoParole = 25
    static let massimoCaratteri = 600

    /// Il modello Apple si usa solo se ammesso (costante, oggi false) E disponibile E la domanda è adatta; altrimenti Qwen.
    static func corsiaModello(_ scelta: SceltaVera, domanda: String, ammesso: Bool = ModelloAppleVera.ammesso,
                              disponibile: Bool = ModelloAppleVera.disponibile) -> CorsiaVera {
        ammesso && disponibile && adattaAlVeloce(scelta, domanda: domanda) ? .apple : .qwen
    }

    /// Adatta al veloce: conversazione (mai la scheda del cliente), senza ragionamento, al massimo 25 parole, nessuno spunto.
    static func adattaAlVeloce(_ scelta: SceltaVera, domanda: String) -> Bool {
        guard scelta.modalita == .conversazione, !scelta.conScheda, !scelta.pensa, SpuntoVera.da(domanda) == nil else { return false }
        return domanda.split(whereSeparator: \.isWhitespace).count <= massimoParole
    }

    /// Valida: non vuota, al massimo 600 caratteri, nessuna cifra che non sia nella domanda.
    static func valida(_ risposta: String, domanda: String) -> Bool {
        let r = risposta.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !r.isEmpty, r.count <= massimoCaratteri else { return false }
        return SuMisuraVera.cifreSenzaFonte(r, fonte: domanda).isEmpty
    }

    /// Prova il veloce; se fallisce o la risposta non è valida, Qwen. Restituisce il testo e la corsia che ha risposto.
    static func rispondi(_ piano: PianoVera, domanda: String, veloce: MotoreVeloce?, qwen: MotoreLocale,
                         aggiorna: ((ParzialeVera) -> Void)? = nil) async throws -> (testo: String, corsia: CorsiaVera) {
        if let veloce {
            if let t = try? await veloce.rispondi(istruzioni: IstruzioniVera.conversazione, domanda: domanda), valida(t, domanda: domanda) {
                let pulito = t.trimmingCharacters(in: .whitespacesAndNewlines)
                aggiorna?(ParzialeVera(testo: pulito, pensa: false))
                return (pulito, .apple)
            }
        }
        let r = try await qwen.scrivi(piano, aggiorna: aggiorna)
        return (r.testo, .qwen)
    }
}
