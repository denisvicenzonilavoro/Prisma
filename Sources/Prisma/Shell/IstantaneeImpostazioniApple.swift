#if os(macOS)
import Foundation

/// Le istantanee delle Impostazioni nel tema Apple (§4.6), come PIE i01, i02 e i03: la barra laterale con le sezioni
/// e la sezione Aspetto (Chiaro / Scuro / Automatico, l'acqua della scrivania, «Riduci movimento», la dimensione del
/// testo) in chiaro e in scuro; poi Archivio e backup con la card dell'anello pieno («Backup creato adesso»), il
/// backup automatico settimanale, «Dove salvare» e «Ripristina…». Ferme nello stato finale (`\.modoIstantanea`).
extension Istantanee {
    nonisolated static var sceneImpostazioniApple: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("470-impostazioni-apple", { s in preparaImpostazioniApple(s, sezione: .aspetto) }),
            ("470-impostazioni-apple-scuro", { s in preparaImpostazioniApple(s, sezione: .aspetto) }),
            ("471-impostazioni-archivio-apple", { s in
                // Un backup appena riuscito: l'anello è pieno con la ✓
                s.dati.impostazioni.backup.ultimo = Date()
                s.dati.impostazioni.backup.ultimoErrore = nil
                preparaImpostazioniApple(s, sezione: .archivio)
            }),
        ]
    }

    /// Le Impostazioni aperte sulla sezione data.
    nonisolated static func preparaImpostazioniApple(_ s: StatoShell, sezione: SchedaImpostazioni) {
        s.ancoraImpostazioni = nil
        s.schedaImpostazioni = sezione
        s.apri(.impostazioni)
    }
}
#endif
