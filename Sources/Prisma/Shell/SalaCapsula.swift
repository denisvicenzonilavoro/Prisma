import SwiftUI

// Sala › La capsula del tempo («Luce» giro 15, §3.4). Stub del giro 15·0: la parte 15c sostituisce il corpo (scrittura,
// sigillo, elenco del cliente, apertura e consegna) senza cambiare la firma usata da `ContenutoPalco`.
struct CapsulaDelTempo: View {
    let cliente: Cliente
    /// Falso sulla sala opaca della presentazione.
    var modificabile = true

    var body: some View {
        let _ = ContaCorpi.segna()
        InArrivoEsperienza(esperienza: .capsula, inSala: !modificabile)
    }
}
