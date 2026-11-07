#if os(iOS)
import Combine
import SwiftUI
import UIKit

// Il tavolo con il Mac, lato iPad: una modalità a tutto schermo davanti al cliente, senza dock né altre app, che mostra
// solo ciò che il Mac sceglie (Tavolo/ProtocolloTavolo.swift, `ClienteTavolo` e `OsservatoreTavolo`).
// - Si entra da Impostazioni › Vera («Tavolo con il Mac») o dalla schermata d'apertura, con il codice del ponte di Vera.
//   La modalità comincia solo quando il Mac ha dato il benvenuto: finché cerca, l'ingresso si può annullare.
// - Al tavolo si esce SOLO dal Mac: nessun gesto né pulsante dell'iPad la chiude; esce con «fine» del Mac.
// - Se la connessione cade: schermata neutra (il logo sull'acqua, nessun dato) e l'iPad riprova da solo finché il Mac
//   non risponde di nuovo; se il Mac rifiuta più volte il codice (cambiato sul Mac) il tavolo è chiuso.
// - Su iPhone la modalità non c'è. Le istantanee usano un tavolo finto, senza rete (`mostraPerIstantanea`).
// Valori grafici in DesignSystem/Apple/Tema.Apple+TavoloiPad.swift; le schermate in SchermiTavoloiPad.swift.

/// Lo stato del tavolo sull'iPad (thread principale). Lo tiene StatoMobile (`mobile.tavolo`).
@MainActor
final class TavoloiPad: ObservableObject {
    enum Fase: Equatable {
        /// Nessun tavolo: l'iPad è il solito Prisma.
        case spento
        /// L'ingresso cerca il Mac (si può ancora annullare).
        case cerca
        /// La modalità a tutto schermo: si esce solo dal Mac.
        case alTavolo
    }

    @Published private(set) var fase: Fase = .spento
    @Published private(set) var collegamento: ClienteTavolo.Collegamento = .scollegato
    @Published private(set) var schermo: ClienteTavolo.Schermo = .neutra
    /// L'ultimo esito da mostrare all'ingresso («Il Mac ha chiuso il tavolo», «Non trovo il Mac…»).
    @Published private(set) var esito: String?
    /// Solo istantanee: il tratto già disegnato nell'area della presa visione (punti da 0 a 1).
    private(set) var trattoDiProva: [[CGPoint]] = []

    /// Dopo una caduta, quanto aspettare prima di cercare di nuovo il Mac.
    nonisolated static let attesaRiprova: UInt64 = 2_000_000_000
    /// Quante volte di fila il Mac può respingere il codice, al tavolo, prima che il tavolo sia chiuso.
    static let rifiutiMassimi = 3

    private var cliente: ClienteTavolo?
    private var osservatore: OsservatoreTavolo?
    private var codice = ""
    private var abbonamenti = Set<AnyCancellable>()
    private var riprova: Task<Void, Never>?
    private var rifiuti = 0

    /// Solo sull'iPad (su iPhone la modalità non c'è).
    static var disponibile: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var alTavolo: Bool { fase == .alTavolo }

    /// Cerca il Mac con il codice del ponte di Vera; al benvenuto del Mac comincia la modalità a tutto schermo.
    func entra(codice c: String) {
        guard Self.disponibile, fase == .spento else { return }
        guard PonteVera.normalizza(c) != nil else {
            esito = "Scrivi il codice del Mac: lo trovi in Prisma sul Mac, Impostazioni › Vera."
            return
        }
        codice = c
        esito = nil
        rifiuti = 0
        let nuovo = ClienteTavolo(nome: UIDevice.current.name)
        let oss = OsservatoreTavolo(nuovo)
        cliente = nuovo
        osservatore = oss
        abbonamenti.removeAll()
        oss.$collegamento
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] c in self?.collegamentoCambiato(c) }
            .store(in: &abbonamenti)
        oss.$schermo
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] s in self?.schermoCambiato(s) }
            .store(in: &abbonamenti)
        fase = .cerca
        nuovo.cerca(codice: c)
    }

    /// Solo durante la ricerca: al tavolo l'iPad non si chiude da qui.
    func annulla() {
        guard fase == .cerca else { return }
        esci(nil)
    }

    /// Il cliente ha mosso il cursore: il valore va al Mac, che ricalcola.
    func mandaValore(_ valore: Double, cursore id: String) {
        guard fase == .alTavolo else { return }
        cliente?.mandaValore(valore, cursore: id)
    }

    /// Il cliente ha preso visione: il tratto (PNG) va al Mac, che lo mette nel PDF.
    func mandaPresaVisione(richiesta id: String, tratto: Data) {
        guard fase == .alTavolo else { return }
        cliente?.mandaPresaVisione(richiesta: id, tratto: tratto)
    }

    /// Le istantanee: il tavolo finto, senza rete, con lo schermo dato.
    func mostraPerIstantanea(_ s: ClienteTavolo.Schermo, collegamento c: ClienteTavolo.Collegamento,
                             tratto: [[CGPoint]] = []) {
        trattoDiProva = tratto
        collegamento = c
        schermo = s
        fase = .alTavolo
    }

    // MARK: Dentro

    private func schermoCambiato(_ s: ClienteTavolo.Schermo) {
        guard fase != .spento else { return }
        schermo = s
    }

    private func collegamentoCambiato(_ c: ClienteTavolo.Collegamento) {
        guard fase != .spento else { return }
        collegamento = c
        switch c {
        case .collegato:
            riprova?.cancel()
            riprova = nil
            rifiuti = 0
            esito = nil
            fase = .alTavolo
        case .scollegato:
            // «fine» dal Mac: il tavolo è chiuso (all'inizio della ricerca lo stato è ancora quello di partenza)
            if fase == .alTavolo { esci("Il Mac ha chiuso il tavolo.") }
        case .rifiutato:
            if fase == .cerca {
                esci("Il Mac non riconosce questo codice: controllalo in Prisma sul Mac, Impostazioni › Vera.")
            } else {
                rifiuti += 1
                if rifiuti >= Self.rifiutiMassimi {
                    esci("Il Mac ha cambiato il codice: il tavolo è chiuso.")
                } else {
                    programmaRiprova()
                }
            }
        case .irraggiungibile:
            if fase == .cerca {
                esci("Non trovo il Mac: in Prisma sul Mac apri «Al tavolo» (in Prospetti o nella presentazione), sulla stessa rete Wi‑Fi.")
            } else {
                programmaRiprova()
            }
        case .caduto:
            if fase == .cerca {
                esci("La connessione con il Mac si è interrotta: riprova.")
            } else {
                programmaRiprova()
            }
        case .cerca, .abbinamento:
            break
        }
    }

    /// Al tavolo, dopo una caduta: la schermata resta neutra e fra poco si cerca di nuovo il Mac.
    private func programmaRiprova() {
        guard riprova == nil else { return }
        let c = codice
        riprova = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: TavoloiPad.attesaRiprova)
            guard let self, !Task.isCancelled else { return }
            self.riprova = nil
            guard self.fase == .alTavolo else { return }
            if case .collegato = self.collegamento { return }
            self.cliente?.cerca(codice: c)
        }
    }

    private func esci(_ motivo: String?) {
        riprova?.cancel()
        riprova = nil
        abbonamenti.removeAll()
        cliente?.chiudi()
        cliente = nil
        osservatore = nil
        trattoDiProva = []
        schermo = .neutra
        collegamento = .scollegato
        fase = .spento
        esito = motivo
    }
}

// MARK: - La modalità a tutto schermo

/// Il tavolo davanti al cliente: una schermata alla volta, con la dissolvenza del tema. Nessun pulsante e nessun gesto
/// per uscire; niente barra di stato né indicatore della Home; lo schermo non si spegne. Se l'iPad non è collegato
/// lo schermo è sempre neutro, qualunque cosa sia rimasta in memoria.
struct ModalitaTavoloiPad: View {
    @ObservedObject var tavolo: TavoloiPad
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.istantaneaSchermo) private var istantanea

    var body: some View {
        ZStack {
            schermata
                .id(chiave)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(Tema.Apple.Moto.animazione(Tema.Apple.Tavolo.iPad.cambio, calmo: calmo, istantanea: istantanea),
                   value: chiave)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    /// Ciò che si vede: neutro se l'iPad non è collegato al Mac.
    private var visibile: ClienteTavolo.Schermo {
        if case .collegato = tavolo.collegamento { return tavolo.schermo }
        return .neutra
    }

    private var chiave: String {
        switch visibile {
        case .neutra: return "neutra"
        case .mostra(let m): return "mostra-" + m.id
        case .cursore(let x): return "cursore-" + x.id
        case .presaVisione(let r): return "presa-" + r.id
        }
    }

    @ViewBuilder private var schermata: some View {
        switch visibile {
        case .neutra:
            NeutraTavoloiPad(collegamento: tavolo.collegamento)
        case .mostra(let m):
            mostra(m)
        case .cursore(let x):
            CursoreTavoloiPad(cursore: x) { v in tavolo.mandaValore(v, cursore: x.id) }
        case .presaVisione(let r):
            PresaVisioneTavoloiPad(richiesta: r, trattoIniziale: tavolo.trattoDiProva) { png in
                tavolo.mandaPresaVisione(richiesta: r.id, tratto: png)
            }
        }
    }

    @ViewBuilder private func mostra(_ m: MostraTavolo) -> some View {
        switch m.genere {
        case .pagina, .prospetto:
            if m.pagine.isEmpty {
                NeutraTavoloiPad(collegamento: tavolo.collegamento)
            } else {
                PagineTavoloiPad(mostra: m)
            }
        case .nelTempo:
            if let n = m.nelTempo {
                NelTempoTavoloiPad(mostra: m, dati: n)
            } else {
                NeutraTavoloiPad(collegamento: tavolo.collegamento)
            }
        case .famiglia:
            if let f = m.famiglia {
                FamigliaTavoloiPad(mostra: m, dati: f)
            } else {
                NeutraTavoloiPad(collegamento: tavolo.collegamento)
            }
        case .lineaVita:
            if let v = m.lineaVita {
                LineaVitaTavoloiPad(mostra: m, dati: v)
            } else {
                NeutraTavoloiPad(collegamento: tavolo.collegamento)
            }
        }
    }
}

// MARK: - L'ingresso (Impostazioni › Vera e schermata d'apertura)

/// «Tavolo con il Mac»: il pulsante per mettersi al tavolo, la ricerca del Mac (annullabile) e l'ultimo esito.
/// `conCodice`: anche il campo del codice (nella schermata d'apertura; in Impostazioni c'è già la riga del codice).
struct IngressoTavoloiPad: View {
    @EnvironmentObject var mobile: StatoMobile
    var conCodice = false

    var body: some View {
        IngressoTavoloiPadCorpo(tavolo: mobile.tavolo, conCodice: conCodice)
    }
}

/// Il corpo dell'ingresso: osserva il tavolo (StatoMobile non si ridisegna per i suoi cambiamenti).
private struct IngressoTavoloiPadCorpo: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var tavolo: TavoloiPad
    let conCodice: Bool

    private typealias T = Tema.Apple.Tavolo.iPad

    var body: some View {
        VStack(alignment: .leading, spacing: T.spazioIngresso) {
            if conCodice {
                TextField("Codice del Mac (ABCD-EFGH-JKLM)", text: $stato.dati.impostazioni.vera.ponte.codice)
                    .campoTesto()
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit(entra)
                    .disabled(tavolo.fase != .spento)
            }
            HStack(spacing: T.spazioIngresso) {
                if tavolo.fase == .cerca {
                    ProgressView()
                    Text("Cerco il Mac…")
                        .carattereApple(T.sottotitolo)
                        .foregroundColor(T.coloreSottotitolo)
                    Spacer(minLength: 0)
                    Button("Annulla") { tavolo.annulla() }
                        .buttonStyle(StilePulsanteApple(.secondaria))
                } else {
                    Button(action: entra) {
                        Label("Al tavolo con il Mac", systemImage: "rectangle.on.rectangle")
                    }
                    .buttonStyle(StilePulsanteApple(.principale))
                    .disabled(!stato.dati.impostazioni.vera.ponte.abbinato)
                    Spacer(minLength: 0)
                }
            }
            if let esito = tavolo.esito, tavolo.fase == .spento {
                Text(esito)
                    .carattereApple(T.esito)
                    .foregroundColor(T.coloreEsito)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func entra() {
        guard tavolo.fase == .spento else { return }
        tavolo.entra(codice: stato.dati.impostazioni.vera.ponte.codice)
    }
}

/// Il gruppo «Tavolo con il Mac» in Impostazioni › Vera dell'iPad (su iPhone non c'è).
struct GruppoTavoloiPad: View {
    var body: some View {
        if TavoloiPad.disponibile {
            GruppoImpostazioni(titolo: "Tavolo con il Mac") {
                RigaImpostazione(titolo: "Al tavolo",
                                 sottotitolo: "L'iPad davanti al cliente mostra solo ciò che sceglie il Mac",
                                 aiuto: "Sul Mac apri «Al tavolo» in Prospetti o nella presentazione: stesso codice di Vera, stessa rete Wi‑Fi, tutto cifrato. Si esce solo dal Mac",
                                 ultima: true) {
                    EmptyView()
                }
                IngressoTavoloiPad()
                    .padding(Tema.Misura.Componenti.margineRiga)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
#endif
