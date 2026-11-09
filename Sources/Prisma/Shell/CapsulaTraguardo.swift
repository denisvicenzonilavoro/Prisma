import SwiftUI

// La tile «La capsula del tempo di … è pronta» nel pannello del traguardo («Luce» giro 15, §3.4 e §5.4): viola, con
// «Apri la capsula», che porta nella Sala con il cliente giusto e apre subito la consegna. Si vede solo se il traguardo ha
// una capsula pronta (`StatoShell.capsulaProntaDelTraguardo`); mai il testo. La parte 15d la mette nel pannello del
// traguardo. Firma fissa.
struct TileCapsulaTraguardo: View {
    @Environment(StatoShell.self) var stato
    let traguardo: Traguardo

    @Environment(\.modoIstantanea) private var istantanea

    private typealias K = Tema.Apple.SalaRacconti.Capsula

    var body: some View {
        let _ = ContaCorpi.segna()
        if let c = stato.capsulaProntaDelTraguardo(traguardo), let cliente = stato.cliente(traguardo.clienteId) {
            let forma = RoundedRectangle(cornerRadius: K.raggioTraguardo, style: .continuous)
            HStack(alignment: .center, spacing: K.spazioTraguardo) {
                SigilloCapsula(colore: K.colore)
                    .scaleEffect(K.scalaSigilloTraguardo)
                    .frame(width: K.latoSigilloTraguardo, height: K.latoSigilloTraguardo)
                VStack(alignment: .leading, spacing: K.spazioTesti) {
                    Text(TestiCapsule.titoloTraguardo(nome: StatoShell.nomeBreve(cliente)))
                        .carattereApple(K.titoloTraguardo)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    Text(TestiCapsule.percheTraguardo(c))
                        .carattereApple(K.percheTraguardo)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button(TestiCapsule.apriDalTraguardo) { stato.apriCapsulaDalTraguardo(c.id, cliente: cliente.id) }
                    .buttonStyle(.apple)
                    .disabled(istantanea)
            }
            .padding(K.paddingTraguardo)
            .background(forma.fill(K.colore.opacity(K.opacitaFondoTraguardo)))
            .overlay(forma.strokeBorder(K.colore.opacity(K.opacitaBordoTraguardo), lineWidth: K.spessoreBordoPronta))
        }
    }
}
