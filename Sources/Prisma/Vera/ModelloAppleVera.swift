import Foundation

// Il modello Apple sul Mac (Apple Intelligence, macOS 26) per le cose rapide di «Due velocità» (fase 5, funzione 23):
// predisposto e SPENTO. CLAUDE.md: «Niente modello Apple» (scelta dell'utente); si accende solo dopo la sua decisione,
// cambiando `ammesso`. Il framework FoundationModels non c'è su macOS 14 e 15: per non legare Prisma a un framework che
// manca (Prisma non partirebbe), il codice che lo usa si compila solo con la condizione PRISMA_MODELLO_APPLE, oggi non
// definita. Quando l'utente deciderà: definirla, verificare che il collegamento sia «weak» (`otool -L` nel workflow) e
// aggiungere la «guided generation» della regola 6 del brief; intanto la validazione la fa `SmistamentoVera.valida`.

enum ModelloAppleVera {
    /// Spento per scelta dell'utente (CLAUDE.md, «Niente modello Apple»). Si cambia solo dopo la sua decisione.
    static let ammesso = false
    static let nome = "Modello Apple sul Mac"

    /// Il modello si può usare su questo Mac (false sotto macOS 26 e senza il framework compilato); mai un errore.
    static var disponibile: Bool {
        #if PRISMA_MODELLO_APPLE && compiler(>=6.2) && canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) { return MotoreVeloceApple.pronto }
        #endif
        return false
    }

    /// Solo informativo, per la pagina dei motori.
    static var descrizioneDisponibilita: String {
        if #available(macOS 26.0, iOS 26.0, *) {
            return disponibile ? "Disponibile su questo Mac" : "macOS 26 presente · non collegato a Prisma"
        }
        return "Richiede macOS 26"
    }

    /// nil se non ammesso o non disponibile: la domanda va a Qwen.
    static func motore() -> MotoreVeloce? {
        guard ammesso, disponibile else { return nil }
        #if PRISMA_MODELLO_APPLE && compiler(>=6.2) && canImport(FoundationModels)
        if #available(macOS 26.0, iOS 26.0, *) { return MotoreVeloceApple() }
        #endif
        return nil
    }
}

#if PRISMA_MODELLO_APPLE && compiler(>=6.2) && canImport(FoundationModels)
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
struct MotoreVeloceApple: MotoreVeloce {
    var nome: String { ModelloAppleVera.nome }

    static var pronto: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    func rispondi(istruzioni: String, domanda: String) async throws -> String {
        let sessione = LanguageModelSession(instructions: istruzioni)
        return try await sessione.respond(to: domanda).content
    }
}
#endif
