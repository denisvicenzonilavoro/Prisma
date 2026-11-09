import SwiftUI

// Sala › Il Prisma del cliente («Luce» giro 15, Design/template-luce-specifica.md §2.1). Stub del giro 15·0: la parte 15a
// sostituisce il corpo (telefono con la mini-app, voci, password, scadenza, preparazione del file) senza cambiare la firma
// usata da `ContenutoPalco`.
struct PalcoPrismaCliente: View {
    let cliente: Cliente
    /// Sulla sala opaca della presentazione: solo il telefono, centrato.
    var inSala = false

    var body: some View {
        let _ = ContaCorpi.segna()
        InArrivoEsperienza(esperienza: .prismaCliente, inSala: inSala)
    }
}
