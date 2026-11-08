import SwiftUI

// La faccia del pulsante di registrazione della nota vocale (Design/template-luce-specifica.md §6.2.1, «Luce» giro 13):
// cerchio da 68 con il bordo bianco all'85%; dentro il quadrato rosso da 28 che «respira» (1,6 s, `repeatForever`,
// niente Timer). A nota finita: bordo verde e cerchio pieno verde da 50 (molla, 0,5 s). Con «Riduci movimento» e nelle
// istantanee il quadrato è fermo. Serve al telefono disegnato del Mac («Come funziona»), alla schermata vera dell'iPhone
// (con i gesti, iOS/NotaVocaleTelefono.swift) e alla vetrina. Valori in `Tema.Apple.NotaVocale.Registra`.

struct FacciaPulsanteRegistra: View {
    /// In ascolto: il quadrato rosso respira.
    let ascolta: Bool
    /// A nota finita: il cerchio verde.
    let fatto: Bool
    /// Il colore del bordo a riposo (bianco sul telefono scuro, grigio sull'iPhone in chiaro).
    var bordo: Color = Tema.Apple.NotaVocale.Registra.coloreBordo

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.prismaScatto) private var scatto
    @State private var respiro = false

    private typealias R = Tema.Apple.NotaVocale.Registra

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(fatto ? R.verde : bordo, lineWidth: R.bordo)
            if fatto {
                Circle()
                    .fill(R.verde)
                    .frame(width: R.fatto, height: R.fatto)
                    .transition(.scale.combined(with: .opacity))
            } else {
                RoundedRectangle(cornerRadius: R.raggioQuadrato, style: .continuous)
                    .fill(R.rosso)
                    .frame(width: R.quadrato, height: R.quadrato)
                    .scaleEffect(ascolta && respiro && !calmo && !scatto ? R.scalaRespiro : 1)
            }
        }
        .frame(width: R.diametro, height: R.diametro)
        .animation(calmo || scatto ? nil : Tema.Apple.Moto.NotaVocale.fine, value: fatto)
        .onAppear(perform: avviaRespiro)
        .onChange(of: ascolta) { _ in avviaRespiro() }
        .accessibilityHidden(true)
    }

    private func avviaRespiro() {
        guard ascolta, !calmo, !scatto else {
            respiro = false
            return
        }
        withAnimation(Tema.Apple.Moto.NotaVocale.animazioneRespiro) { respiro = true }
    }
}
