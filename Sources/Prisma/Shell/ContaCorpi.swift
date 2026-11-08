import Foundation
import SwiftUI

/// Conta le rivalutazioni dei body delle viste che leggono StatoShell (la prova della fluidità, colonna «corpi»).
///
/// Con `ObservableObject` la prova contava gli `objectWillChange` di StatoShell: ognuno rivalutava tutte le viste che
/// lo osservavano. Con Observation (giro 0 di «Prisma istantaneo») non c'è più un avviso unico: ogni vista si
/// aggiorna solo per ciò che legge. Si contano allora i body davvero rivalutati, che è la misura della proposta
/// (Design/velocita-proposta.md, «viste rivalutate per modifica»). Spento fuori dalla prova: costa un confronto.
enum ContaCorpi {
    nonisolated(unsafe) static var attivo = false
    nonisolated(unsafe) private(set) static var conteggio = 0

    /// Da chiamare in testa al body (`let _ = ContaCorpi.segna()`), solo sul thread principale.
    @inline(__always)
    static func segna() {
        if attivo { conteggio &+= 1 }
    }

    static func azzera() { conteggio = 0 }
}
