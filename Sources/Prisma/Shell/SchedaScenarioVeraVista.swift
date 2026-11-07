import SwiftUI

/// La scheda prima/dopo di uno scenario «E se…?» sotto la risposta di Vera (app Vera, Vera della scrivania, iPhone e
/// iPad): la tabella con le cifre di Prisma, «Salva nel dossier» e «Apri in Simulazioni» (in protezione «Apri in
/// Analisi 360»), poi le note sulle ipotesi.
struct SchedaScenarioVeraVista: View {
    @EnvironmentObject var stato: StatoShell
    let scheda: SchedaScenarioVera
    /// Il messaggio di Vera che la contiene (per ricordare il salvataggio).
    let messaggio: String
    /// false dove l'entrata la fa già chi la contiene (la bolla di Vera fa entrare tutte le schede dei calcoli insieme).
    var entra = true

    var body: some View {
        let t = Tema.Apple.ScenarioVera.self
        VStack(alignment: .leading, spacing: 0) {
            TabellaScenarioApple(colonnaOggi: scheda.colonnaOggi, colonnaScenario: scheda.colonnaScenario, righe: scheda.righe)
            pulsanti
                .padding(.top, t.sopraPulsanti)
            ForEach(Array(scheda.note.prefix(t.massimoNote).enumerated()), id: \.offset) { _, n in
                Text(n)
                    .carattereApple(t.nota)
                    .foregroundColor(t.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, t.sopraNote)
            }
        }
        .padding(.top, t.sopraTabella)
        .entrataTabellaScenario(entra)
    }

    private var pulsanti: some View {
        let t = Tema.Apple.ScenarioVera.self
        return HStack(spacing: t.spazioPulsanti) {
            if scheda.salvata {
                Label("Nel dossier", systemImage: "checkmark")
                    .carattereApple(.pulsante)
                    .foregroundColor(t.coloreSalvata)
            } else {
                Button("Salva nel dossier") { stato.salvaScenarioVera(scheda, messaggio: messaggio) }
                    .buttonStyle(.applePrimario)
            }
            Button(scheda.simulazione == nil ? "Apri in Analisi 360" : "Apri in Simulazioni") { stato.apriScenarioVera(scheda) }
                .buttonStyle(.apple)
        }
    }
}
