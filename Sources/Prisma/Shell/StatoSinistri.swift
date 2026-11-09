import Foundation
import Observation

// Pratiche › Sinistri («Luce» giro 15, §7.4): lo stato della scheda. Stub del giro 15·0 (`StatoShell.sinistri`): la parte
// 15e completa la classe e aggiunge le funzioni di `StatoShell` (salva, avanza, fatti, documenti, aggiornamento al
// cliente, sollecito) senza togliere questi campi.
@Observable final class StatoSinistri {
    /// Il sinistro scelto nella barra laterale.
    var scelto: String?
    /// Il modulo «Nuovo sinistro» è aperto.
    var moduloAperto = false
    /// Solo istantanee: il sinistro da mostrare. Non pubblicato.
    @ObservationIgnored var istantanea: String?
}
