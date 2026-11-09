import SwiftUI

// Sala › Il film del piano («Luce» giro 15, §3.2). Stub del giro 15·0: la parte 15b sostituisce il corpo (schermo,
// comandi, esportazione del video, condivisione) senza cambiare la firma usata da `ContenutoPalco`.
struct FilmDelPiano: View {
    let cliente: Cliente
    /// Falso sulla sala opaca della presentazione (si guarda, senza esportare né condividere).
    var modificabile = true

    var body: some View {
        let _ = ContaCorpi.segna()
        InArrivoEsperienza(esperienza: .film, inSala: !modificabile)
    }
}
