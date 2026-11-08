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

/// Rivaluta `contenuto` quando cambia un `ObservableObject` che una vista legge attraverso StatoShell (per esempio
/// `stato.sessioneMercato`). Con `ObservableObject` StatoShell pubblicava così spesso che queste letture si
/// aggiornavano «per caso»; con Observation ogni vista si aggiorna solo per ciò che osserva davvero.
struct OsservaOggetto<Oggetto: ObservableObject, Contenuto: View>: View {
    @ObservedObject private var oggetto: Oggetto
    private let contenuto: () -> Contenuto

    init(_ oggetto: Oggetto, @ViewBuilder contenuto: @escaping () -> Contenuto) {
        _oggetto = ObservedObject(wrappedValue: oggetto)
        self.contenuto = contenuto
    }

    var body: some View { contenuto() }
}
