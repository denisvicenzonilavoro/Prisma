#if os(macOS)
import Foundation

/// Le istantanee di Prospetti nel tema Apple (§4.5.1, §4.5.3), come PIE p01 e p10: la barra laterale con Giulia,
/// «Per l'incontro» con «Un anno insieme» scelto («nuovo»), la card «Fascicolo dell'incontro» e l'anteprima su carta
/// della prima pagina del report, in chiaro e in scuro (la carta resta bianca); poi la sala della presentazione con la
/// stessa pagina, «1 di N» e «Chiudi». Le cifre vengono dai motori di Prisma sui dati di prova.
extension Istantanee {
    nonisolated static var sceneProspettiApple: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("460-prospetti-apple", { s in preparaProspettiApple(s) }),
            ("460-prospetti-apple-scuro", { s in preparaProspettiApple(s) }),
            ("461-prospetti-sala", { s in
                preparaProspettiApple(s)
                if let d = s.documentoProspetto(sceltaProspettiApple) { s.presenta(d) }
            }),
        ]
    }

    /// «Un anno insieme» di Giulia: il primo della lista «Per l'incontro», come nel template.
    nonisolated static var sceltaProspettiApple: SceltaProspetto { .annoInsieme }

    /// Prospetti aperto su Giulia, con il report scelto.
    nonisolated static func preparaProspettiApple(_ s: StatoShell) {
        s.clienteAttivoId = "giulia"
        s.apriProspetto(sceltaProspettiApple)
    }
}
#endif
