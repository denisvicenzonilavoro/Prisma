#if os(macOS)
import SwiftUI

// Impostazioni › Vera › «Stanotte» («Luce» giro 14, §5.5 e §6.1.6): il lavoro della notte, spento di base; l'ora di
// inizio (fino alle 6:00), le bozze con Vera (al più 10, una alla volta), l'apertura delle carte al mattino, la notifica
// del Mac (spenta di base, senza nomi), i tipi di carta. Un gruppo nella pagina di Vera, non una pagina nuova.
struct GruppoImpostazioniNotte: View {
    @Environment(StatoShell.self) var stato

    private typealias M = Tema.Misura.Impostazioni

    var body: some View {
        let n = stato.dati.impostazioni.notte
        VStack(alignment: .leading, spacing: Tema.Apple.Impostazioni.Riga.fraRighe) {
            GruppoImpostazioni(titolo: TestiNotte.gruppoImpostazioni) {
                RigaImpostazione(titolo: TestiNotte.rigaAttivo, sottotitolo: "Prepara le cose di domani mentre non usi Prisma.",
                                 aiuto: TestiNotte.notaImpostazioni) {
                    interruttore(n.attivo) { v in stato.impostaNotte { $0.attivo = v } }
                }
                RigaImpostazione(titolo: TestiNotte.rigaInizio, sottotitolo: TestiNotte.fineFinestra) {
                    MenuTendina(selezione: Binding(get: { n.inizio }, set: { v in stato.impostaNotte { $0.inizio = v } }),
                                opzioni: ImpostazioniNotte.oreScelta.map { ($0, TestiNotte.oraInizio($0)) }, larghezza: M.menuStretto)
                        .disabled(stato.solaLettura)
                }
                RigaImpostazione(titolo: TestiNotte.rigaBozze, sottotitolo: TestiNotte.notaBozze,
                                 aiuto: "Qwen sul Mac si carica una volta, scrive le bozze una alla volta e libera subito la memoria") {
                    interruttore(n.usaQwen) { v in stato.impostaNotte { $0.usaQwen = v } }
                }
                RigaImpostazione(titolo: TestiNotte.rigaApri, sottotitolo: "Una volta, dopo lo sblocco; mai con un cliente davanti.") {
                    interruttore(n.apriAlMattino) { v in stato.impostaNotte { $0.apriAlMattino = v } }
                }
                RigaImpostazione(titolo: TestiNotte.rigaNotifica, sottotitolo: "All'inizio della mattina di lavoro.",
                                 aiuto: TestiNotte.aiutoNotifica, ultima: true) {
                    interruttore(n.notificaAlMattino) { v in stato.impostaNotte { $0.notificaAlMattino = v } }
                }
            }
            GruppoImpostazioni(titolo: "Cosa preparare") {
                let tipi = TipoCartaNotte.allCases.filter { $0 != .daFinire }
                ForEach(Array(tipi.enumerated()), id: \.element.rawValue) { i, tipo in
                    RigaImpostazione(titolo: tipo.nome, ultima: i == tipi.count - 1) {
                        interruttore(n.prepara(tipo)) { acceso in
                            stato.impostaNotte { imp in
                                imp.preparatori.removeAll { $0 == tipo }
                                if acceso {
                                    // L'ordine resta quello fisso del lavoro (prima i senza Qwen)
                                    imp.preparatori = TipoCartaNotte.allCases.filter { $0 == tipo || imp.preparatori.contains($0) }
                                }
                            }
                        }
                    }
                }
            }
            NotaImpostazioni(TestiNotte.notaImpostazioni)
        }
    }

    private func interruttore(_ valore: Bool, _ cambia: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: { valore }, set: cambia)) { EmptyView() }
            .toggleStyle(.appleSenzaEtichetta)
            .disabled(stato.solaLettura)
    }
}
#endif
