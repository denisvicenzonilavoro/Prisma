#if os(macOS)
import Foundation

/// Le istantanee del portafoglio di Posizioni nel tema Apple (§4.1): la card con il totale, i tre anelli e il nastro
/// «Da fare», in chiaro e in scuro; «Con le proposte» con la stima tratteggiata e la fascia; il dettaglio della prima
/// scheda del nastro aperto. Le cifre vengono dai motori di Prisma sui dati di prova; il piano previdenziale di
/// Giulia è presentato da 50 giorni e ancora senza risposta, così sul nastro c'è una proposta ferma (date relative).
extension Istantanee {
    nonisolated static var scenePosizioniApple: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("420-posizioni-portafoglio", { s in preparaPortafoglioApple(s) }),
            ("420-posizioni-portafoglio-scuro", { s in preparaPortafoglioApple(s) }),
            ("421-posizioni-con-proposte", { s in
                preparaPortafoglioApple(s)
                RichiestaIstantaneaPortafoglio.chiedi(s, conProposte: true)
            }),
            ("422-posizioni-dettaglio-da-fare", { s in
                preparaPortafoglioApple(s)
                RichiestaIstantaneaPortafoglio.chiedi(s, dettaglio: true)
            }),
        ]
    }

    /// Posizioni › Portafoglio aperto, con la proposta di Giulia ferma da 50 giorni.
    nonisolated static func preparaPortafoglioApple(_ s: StatoShell) {
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        if let i = s.dati.posizioni.firstIndex(where: { $0.id == "pos-giulia-piano-previdenziale-integrativo" }) {
            var seguito = s.dati.posizioni[i].seguito ?? SeguitoProposta()
            seguito.presentataIl = ValoriDaDocumento.mezzogiorno(cal.date(byAdding: .day, value: -50, to: oggi) ?? oggi)
            s.dati.posizioni[i].esito = .presentata
            s.dati.posizioni[i].seguito = seguito
        }
        s.posizioneInDettaglio = nil
        s.portafoglio = true
        s.apri(.posizioni)
    }
}
#endif
