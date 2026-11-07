#if os(macOS)
import Foundation

/// Le istantanee del report «Un anno insieme» (tema Apple §4.5.2): la pagina «Cosa è successo» nella sala della
/// presentazione (Prospetti su Giulia con «Un anno insieme» e la prima pagina in sala sono le scene 460 e 461). Le cifre vengono dai motori di Prisma
/// sui dati di prova; la carta resta bianca anche in scuro.
extension Istantanee {
    nonisolated static var sceneAnnoInsieme: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            // Prospetti con «Un anno insieme» e la prima pagina in sala sono già le scene 460 e 461
            // (IstantaneeProspettiApple.swift): qui solo la pagina «Cosa è successo», per non scattare due volte lo stesso
            ("462-un-anno-insieme-pdf-anno", { s in
                preparaAnnoInsieme(s)
                // Si parte già dalla seconda pagina: niente cambio di pagina animato prima dello scatto
                if let d = s.documentoProspetto(.annoInsieme) { s.presenta(d, daPagina: 1) }
            }),
        ]
    }

    /// Prospetti aperto su Giulia, con «Un anno insieme».
    nonisolated static func preparaAnnoInsieme(_ s: StatoShell) {
        s.clienteAttivoId = "giulia"
        s.apriProspetto(.annoInsieme)
    }
}
#endif
