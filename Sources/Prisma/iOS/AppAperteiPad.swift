#if os(iOS)
import SwiftUI

/// Le app aperte sull'iPad (lo switcher, largo al massimo 760, schede di almeno 150 punti) nel tema Apple: il pannello
/// come la finestra (`Tema.Apple.AppAperte`), le schede come `tile` e i pulsanti a capsula. Si apre dalla barra
/// (il nome dell'app). Un tocco porta l'app nella finestra con il suo stato; «Scrivania» torna ai riquadri;
/// «Chiudi tutte» chiude le app (lo stato dei dati resta).
struct AppAperteiPad: View {
    @Environment(StatoShell.self) var stato
    @EnvironmentObject var mobile: StatoMobile
    @EnvironmentObject var sistema: StatoFinestre

    private typealias P = Tema.Misura.Mobile.Pannelli

    var body: some View {
        let _ = ContaCorpi.segna()
        let aperte = Array(sistema.elenco.reversed())
        VStack(alignment: .leading, spacing: P.sottoTitolo) {
            Text("App aperte")
                .carattereApple(A.titolo)
                .foregroundColor(A.coloreTitolo)
            if aperte.isEmpty {
                Text("Nessuna app aperta: aprine una dal dock.")
                    .carattereApple(A.vuoto)
                    .foregroundColor(A.coloreContesto)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: P.schedaApp), spacing: P.spazioAppAperte)],
                              spacing: P.spazioAppAperte) {
                        ForEach(aperte) { f in
                            SchedaAppApertaMobile(finestra: f, davanti: f.app == mobile.appAperta) {
                                mobile.passaA(f.app)
                            }
                        }
                    }
                }
            }
            HStack(spacing: Tema.Misura.Shell.pulsantiSpazio) {
                Button("Scrivania") { mobile.mostraHome() }
                    .buttonStyle(.apple)
                if !aperte.isEmpty {
                    Button("Chiudi tutte") { chiudiTutte(aperte) }
                        .buttonStyle(.apple)
                }
                Spacer(minLength: 0)
                Button("Fatto") { mobile.pannello = nil }
                    .buttonStyle(.applePrimario)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(P.margineAppAperte)
        .superficieApple(A.superficie, raggio: A.raggio)
    }

    private typealias A = Tema.Apple.AppAperte

    /// Chiude tutte le app aperte (StatoShell le toglie come sul Mac) e torna alla scrivania.
    private func chiudiTutte(_ aperte: [StatoShell.Finestra]) {
        mobile.mostraHome()
        for f in aperte { stato.chiudi(f.app) }
    }
}

/// Una scheda dello switcher (.sw-card): l'icona, il nome, di chi parla e se è nella finestra.
private struct SchedaAppApertaMobile: View {
    @Environment(StatoShell.self) var stato
    let finestra: StatoShell.Finestra
    let davanti: Bool
    let azione: () -> Void

    private typealias P = Tema.Misura.Mobile.Pannelli

    private typealias A = Tema.Apple.AppAperte

    var body: some View {
        let _ = ContaCorpi.segna()
        let forma = RoundedRectangle(cornerRadius: A.raggioScheda, style: .continuous)
        Button(action: azione) {
            VStack(spacing: P.spazioSchedaApp) {
                IconaApp(app: finestra.app, lato: P.iconaSchedaApp)
                Text(finestra.app.titolo)
                    .carattereApple(A.nome)
                    .foregroundColor(A.coloreTitolo)
                // Il cliente (o il contesto) di questa app; una riga vuota tiene le schede alte uguali
                Text(stato.contesto(di: finestra.app) ?? " ")
                    .carattereApple(A.contesto)
                    .foregroundColor(A.coloreContesto)
                Text(davanti ? "Nella finestra" : "Aperta")
                    .carattereApple(A.stato)
                    .foregroundColor(A.coloreStato)
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity)
            .padding(P.margineSchedaApp)
            .superficieApple(A.schedaSuperficie, raggio: A.raggioScheda)
            .overlay {
                if davanti {
                    forma.fill(A.fondoDavanti)
                    forma.strokeBorder(A.filoDavanti, lineWidth: A.spessoreFiloDavanti)
                }
            }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        // Alla pressione la scheda scende a 0,98, come le schede del tema sul touch
        .inclinazione(raggio: A.raggioScheda)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(davanti ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}
#endif
