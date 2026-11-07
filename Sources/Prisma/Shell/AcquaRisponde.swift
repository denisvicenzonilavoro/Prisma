import SwiftUI

/// «L'acqua risponde» dalla shell (SfondoAcquaRisposta.swift): una vista vuota accanto all'acqua della scrivania
/// (ShellView sul Mac e sull'iPad, la radice di iPhone e iPad) che guarda lo stato e chiede all'acqua:
/// - una goccia sulla campanella quando arriva una notifica nuova (non con Prisma bloccata);
/// - la vibrazione intorno alla sfera di Vera mentre Vera risponde (`veraInCorso`: da quando la domanda parte a Qwen a
///   quando la risposta è scritta), sulla scrivania se la sfera c'è, altrimenti nella barra;
/// - allo sblocco una goccia grande al centro, che apre la scrivania.
/// Dice anche all'acqua se può rispondere: «L'acqua della scrivania» e lo sfondo animato accesi, senza «Riduci
/// movimento» (`\.prismaCalmo`) e fuori dalle istantanee. Non disegna niente e non prende i clic.
struct OsservatoreAcqua: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var sistema: StatoFinestre
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var modoIstantanea
    /// Le notifiche nuove viste l'ultima volta: una goccia solo quando crescono.
    @State private var nuoveDiPrima: Int?

    init(sistema: StatoFinestre) {
        self.sistema = sistema
    }

    private var consentita: Bool {
        let i = stato.dati.impostazioni
        return i.acquaDellaScrivania && i.sfondoAnimato && !calmo && !modoIstantanea
    }

    var body: some View {
        let si = consentita
        let nuove = stato.notificheNuove
        let parla = stato.veraInCorso
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                RispostaAcqua.condivisa.consenti(si)
                nuoveDiPrima = nuove
                if parla { vibraIntornoAVera() }
            }
            .onChange(of: si) { ora in
                RispostaAcqua.condivisa.consenti(ora)
                // Riaccesa mentre Vera risponde: l'acqua torna a vibrare
                if ora && stato.veraInCorso { vibraIntornoAVera() }
            }
            .onChange(of: nuove) { n in notificheCambiate(n) }
            .onChange(of: parla) { ora in
                if ora { vibraIntornoAVera() } else { RispostaAcqua.condivisa.fermaVibrazioni() }
            }
            .onChange(of: sistema.bloccato) { bloccato in
                // Lo sblocco: una goccia apre la scrivania
                if !bloccato { RispostaAcqua.condivisa.gocciaAlCentro(peso: Tema.Apple.Acqua.Goccia.pesoSblocco) }
            }
    }

    private func notificheCambiate(_ n: Int) {
        let prima = nuoveDiPrima ?? n
        nuoveDiPrima = n
        guard n > prima, !sistema.bloccato else { return }
        RispostaAcqua.condivisa.goccia(su: .campanella, peso: Tema.Apple.Acqua.Goccia.pesoNotifica)
    }

    private func vibraIntornoAVera() {
        let durata = Tema.Apple.Acqua.Vibrazione.durataMassima
        if !RispostaAcqua.condivisa.vibra(intorno: .sferaVera, durata: durata) {
            RispostaAcqua.condivisa.vibra(intorno: .sferaVeraBarra, durata: durata)
        }
    }
}
