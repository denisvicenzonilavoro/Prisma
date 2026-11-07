#if os(macOS)
import Foundation

/// Le istantanee della scheda «La linea della vita» del dossier (Orizzonte, giro 4; specifica §7.7), chiare e scure,
/// tutte nello stato finale (curva tracciata, cifre complete, gettoni fermi):
/// - 437: Giulia con gli eventi del template (matrimonio, casa, figlio, eredità), l'obiettivo della riserva e la
///   pensione; senza Analisi 360 salvata la curva dopo la pensione è solo indicativa;
/// - 438: Sofia con l'Analisi 360 salvata (reddito desiderato 2.200 € al mese, pensione 1.500 €): il prelievo in
///   pensione fa finire il patrimonio prima dei 90 anni, con il punto rosso;
/// - 439: Andrea senza data di nascita: la frase e «Completa l'anagrafica ›».
/// Le cifre vengono da `MotoreLineaVita` sui dati di prova.
extension Istantanee {
    nonisolated static var sceneLineaVita: [(nome: String, prepara: (StatoShell) -> Void)] {
        [
            ("437-clienti-linea-vita", { s in giulia(s) }),
            ("437-clienti-linea-vita-scuro", { s in giulia(s) }),
            ("438-clienti-linea-vita-finisce", { s in sofia(s) }),
            ("438-clienti-linea-vita-finisce-scuro", { s in sofia(s) }),
            ("439-clienti-linea-vita-dati-mancanti", { s in senzaNascita(s) }),
            ("439-clienti-linea-vita-dati-mancanti-scuro", { s in senzaNascita(s) }),
        ]
    }

    nonisolated private static func giulia(_ s: StatoShell) {
        s.clienteAttivoId = "giulia"
        s.schedaCliente = .lineaVita
        s.apri(.clienti)
    }

    /// Sofia con l'Analisi 360 salvata: reddito desiderato e pensione pubblica a mano (solo per l'istantanea).
    nonisolated private static func sofia(_ s: StatoShell) {
        var a = s.analisi360("sofia")
        a.previdenza.redditoDesiderato = 2_200
        a.previdenza.pensionePubblica = 1_500
        s.salvaAnalisi("sofia", a)
        s.clienteAttivoId = "sofia"
        s.schedaCliente = .lineaVita
        s.apri(.clienti)
    }

    nonisolated private static func senzaNascita(_ s: StatoShell) {
        if let i = s.dati.clienti.firstIndex(where: { $0.id == "andrea" }) { s.dati.clienti[i].dataNascita = nil }
        s.clienteAttivoId = "andrea"
        s.schedaCliente = .lineaVita
        s.apri(.clienti)
    }
}
#endif
