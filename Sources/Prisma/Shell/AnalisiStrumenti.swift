import SwiftUI

/// Gli strumenti di Analisi 360 (simulatore, scenari, confronto, TFR): le app accorpate Simulazioni e
/// Confronti vivono qui, senza la loro cornice (cornice ed elenco laterale sono quelli di Analisi 360).
/// AppAnalisi360 lo mostra nel contenuto quando `stato.strumentoAnalisi != nil`. Le stesse viste
/// (`SimulatoreIpotesi`, `ScenariSalvati`, `ConfrontoIpotesi`, `SchedaTFR`) le usano anche le app
/// Simulazioni e Confronti di iPhone e iPad. Tutti nel tema Apple (`.strumentiApple()`): caratteri, superfici,
/// cursori, segmentati ed etichette del canale; contenuti e calcoli quelli di sempre.
struct StrumentiAnalisi360: View {
    @EnvironmentObject var stato: StatoShell

    var body: some View {
        Group {
            switch stato.strumentoAnalisi {
            case .simulatore: SimulatoreIpotesi(inAnalisi: true)
            case .scenari: ScenariSalvati(inAnalisi: true)
            case .confronto: ConfrontoIpotesi(inAnalisi: true)
            case .tfr: StrumentoTFR()
            case nil: EmptyView()
            }
        }
        .strumentiApple()
    }
}

/// Lo strumento TFR: la testata (come gli altri strumenti) sopra la `SchedaTFR` così com'è.
struct StrumentoTFR: View {
    private typealias M = Tema.Misura.StrumentiAnalisi
    private typealias K = Tema.Colore.StrumentiAnalisi
    private typealias F = Tema.Testo.StrumentiAnalisi

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: M.spazioTestata) {
                SpiaStrumentoApple()
                Text("TFR · in azienda o nel fondo pensione")
                    .titoloTestataStrumentoApple()
                Spacer(minLength: M.spazioTestata)
            }
            .testataColonna()
            SchedaTFR()
        }
    }
}

extension AppPrisma {
    /// Il nome con cui l'app si trova in Prisma: sul Mac le accorpate dicono dove stanno
    /// («Analisi 360 · Simulazioni», «Clienti · Documenti»); su iPhone e iPad il titolo di sempre.
    var titoloInPrisma: String {
        #if os(macOS)
        if let o = ospite { return "\(o.titolo) · \(titolo)" }
        #endif
        return titolo
    }
}

extension StatoShell {
    /// Sceglie uno strumento di Analisi 360 (nil = le aree). Tiene allineata la scheda di Simulazioni,
    /// che le viste del simulatore leggono ancora.
    func scegliStrumentoAnalisi(_ s: StrumentoAnalisi?) {
        if strumentoAnalisi != s { strumentoAnalisi = s }
        switch s {
        case .simulatore: if schedaSimulazioni != .simulatore { schedaSimulazioni = .simulatore }
        case .scenari: if schedaSimulazioni != .scenari { schedaSimulazioni = .scenari }
        case .tfr: if schedaSimulazioni != .tfr { schedaSimulazioni = .tfr }
        case .confronto, nil: break
        }
    }

    /// Apre uno strumento di Analisi 360 da un'altra app: sul Mac dentro Analisi 360 (il reindirizzamento
    /// di `apri`), su iPhone e iPad nell'app Simulazioni o Confronti, sulla scheda giusta.
    func apriStrumentoAnalisi(_ s: StrumentoAnalisi) {
        switch s {
        case .simulatore: schedaSimulazioni = .simulatore
        case .scenari: schedaSimulazioni = .scenari
        case .tfr: schedaSimulazioni = .tfr
        case .confronto: break
        }
        apri(s == .confronto ? .confronti : .simulazioni)
    }

    /// Lo strumento che corrisponde alla scheda di Simulazioni.
    static func strumento(per scheda: SchedaSimulazioni) -> StrumentoAnalisi {
        switch scheda {
        case .simulatore: return .simulatore
        case .scenari: return .scenari
        case .tfr: return .tfr
        }
    }
}
