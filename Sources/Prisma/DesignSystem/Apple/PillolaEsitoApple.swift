import SwiftUI

/// La pillola dell'esito di una raccomandazione nel tema Apple (Studio › Track record, §4.2.1): «Accettata» verde,
/// «Rifiutata» rossa, «Rimandata» arancio, «In attesa» neutra; capsula 12 bold con padding 4×10. Colori fissi,
/// uguali in chiaro e in scuro (`Tema.Apple.Studio.Track`).
struct PillolaEsitoApple: View {
    let esito: PresentazioneTrackRecord.Esito

    var body: some View {
        let t = Tema.Apple.Studio.Track.self
        Text(esito.nome)
            .carattereApple(t.pillola)
            .foregroundColor(colori.testo)
            .lineLimit(1)
            .fixedSize()
            .padding(t.paddingPillola)
            .background { Capsule(style: .continuous).fill(colori.fondo) }
            .accessibilityLabel(Text("Esito: \(esito.nome)"))
    }

    private var colori: (testo: Color, fondo: Color) {
        let t = Tema.Apple.Studio.Track.self
        switch esito {
        case .accettata: return (t.testoAccettata, t.fondoAccettata)
        case .rifiutata: return (t.testoRifiutata, t.fondoRifiutata)
        case .rimandata: return (t.testoRimandata, t.fondoRimandata)
        case .inAttesa: return (t.testoInAttesa, t.fondoInAttesa)
        }
    }
}
