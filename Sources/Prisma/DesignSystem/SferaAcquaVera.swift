import SwiftUI

/// La sfera di Vera della mini finestra, dei widget e degli avvisi. «Vera ha un solo simbolo: la sfera luminosa»:
/// disegna la stessa `SferaVera` del tema Apple (DesignSystem/Apple/VeraApple.swift, §2.18), con i parametri di sempre.
/// - livello: quanto suona la voce (0…1): la sfera si gonfia appena e l'alone si accende.
/// - velocita: 1 a riposo (la sfera respira); dalla velocità del pensiero in su pulsa, come mentre Vera lavora.
/// - spenta: Qwen non è pronto (quasi grigia, ferma).
/// - animata: false = ferma (barra superiore a riposo, istantanee, «Riduci movimento»).
struct SferaAcquaVera: View {
    let lato: CGFloat
    var livello: CGFloat = 0
    var velocita: Double = 1
    var spenta = false
    var animata = true

    var body: some View {
        let c = Tema.Colore.MiniVera.Sfera.self
        let s = Tema.Apple.Vera.Sfera.self
        let lvl = min(max(livello, 0), 1)
        let pensa = animata && !spenta && velocita >= Tema.Moto.MiniVera.velocitaPensiero
        SferaVera(misura: lato, viva: animata && !spenta && !pensa, pensa: pensa)
            .saturation(spenta ? c.saturazioneSpenta : 1)
            .brightness(spenta ? c.luceSpenta : 0)
            // La voce: un alone che cresce con il livello (a riposo nessuno: c'è già l'ombra della sfera)
            .shadow(color: c.alone.opacity(spenta ? 0 : Double(lvl) * c.aloneVoce), radius: lato * (s.aloneVoce + lvl * s.aloneVoceCrescita))
            .scaleEffect(1 + lvl * s.gonfiaVoce)
            .animation(.linear(duration: s.durataVoce), value: livello)
    }
}
