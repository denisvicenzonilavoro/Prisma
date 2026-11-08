import SwiftUI

/// La testata di Incontri («Luce» giro 13, §6.2.1): sul Mac «Nota dall’iPhone» (glifo `voce`) apre «Come funziona» con le
/// ultime note arrivate; sull'iPad «Nota veloce» apre la stessa schermata dell'iPhone per dettare una nota.
struct AzioniIncontri: View {
    @Environment(StatoShell.self) var stato

    var body: some View {
        let _ = ContaCorpi.segna()
        #if os(macOS)
        Button { stato.apriComeFunzionaNota() } label: {
            Label {
                Text("Nota dall’iPhone")
            } icon: {
                GlifoLuceVista(glifo: .voce, lato: Tema.Apple.NuovoCliente.Scheda.glifoTestata)
            }
        }
        .buttonStyle(.apple)
        .help("Detta una nota sull’iPhone dopo una visita: arriva qui con le proposte da confermare")
        #else
        Button { stato.notaVeloceAperta = true } label: {
            Label {
                Text("Nota veloce")
            } icon: {
                GlifoLuceVista(glifo: .voce, lato: Tema.Apple.NuovoCliente.Scheda.glifoTestata)
            }
        }
        .buttonStyle(.apple)
        #endif
    }
}
