import SwiftUI

// Impostazioni nel tema Apple (Design/template-apple-specifica.md §4.6, riferimenti PIE i01-i09).
// - `.impostazioniApple()` chiede alle righe di sempre (`GruppoImpostazioni`, `RigaImpostazione`, `ValoreRiga`,
//   `NotaImpostazioni`, `TesseraImpostazioni`, `StileInterruttore`) lo stile del template: ogni riga è una card
//   senza ombra con il titolo 15 bold, la spiegazione `.k` e il controllo a destra; accende anche
//   `.superficiApple()` (etichette del canale `.chA` / `.chI`). Le altre app restano com'erano.
// - `VoceLateraleImpostazioniApple`: la voce `.rub` della barra laterale.
// - `StatoRigaApple`: lo stato a destra di una riga («● Pronto»).
// - `AnelloBackupApple`: l'anello del backup (§2.24) che si riempie mentre il backup lavora.
// - `StilePulsanteRigaImpostazioni`: i pulsanti dentro le righe (la capsula `.btn`, sul Mac e sull'iPad).
// «Riduci movimento» e istantanee: tutto è subito nello stato finale. Valori in Tema.Apple+Impostazioni.swift.

private struct ChiaveImpostazioniApple: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// true: le righe delle Impostazioni si disegnano come card del tema Apple.
    var impostazioniApple: Bool {
        get { self[ChiaveImpostazioniApple.self] }
        set { self[ChiaveImpostazioniApple.self] = newValue }
    }
}

extension View {
    /// Le righe, i gruppi, le note e gli interruttori delle Impostazioni nello stile del tema Apple.
    func impostazioniApple(_ attive: Bool = true) -> some View {
        environment(\.impostazioniApple, attive)
            .superficiApple(attive)
    }

    /// Un blocco dentro un gruppo che non è una riga (la griglia dei rendimenti): nel tema Apple sta su una card
    /// come le righe; altrimenti resta com'è.
    func cardImpostazioni() -> some View {
        modifier(CardImpostazioniApple())
    }

    /// Nel tema Apple la riga entra a cascata (base 0, dentro l'app) quando si apre la sezione; altrimenti niente.
    func cascataImpostazioni(_ indice: Int) -> some View {
        modifier(CascataImpostazioniApple(indice: indice))
    }
}

private struct CascataImpostazioniApple: ViewModifier {
    let indice: Int
    @Environment(\.impostazioniApple) private var apple

    @ViewBuilder func body(content: Content) -> some View {
        if apple {
            content.entrataCascata(indice, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
        } else {
            content
        }
    }
}

private struct CardImpostazioniApple: ViewModifier {
    @Environment(\.impostazioniApple) private var apple

    @ViewBuilder func body(content: Content) -> some View {
        if apple {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .superficieApple(Tema.Apple.Impostazioni.Riga.superficie, raggio: Tema.Apple.Impostazioni.Riga.raggio)
        } else {
            content
        }
    }
}

// MARK: - Voce della barra laterale

/// Voce `.rub` della barra laterale: titolo 14 bold con padding 11×12 e raggio 14; sotto il puntatore il fondo
/// `chip`, scelta `rgba(0,122,255,.13)` (0,25 s). Uno stato facoltativo a destra (il pallino).
struct VoceLateraleImpostazioniApple: View {
    let titolo: String
    let attiva: Bool
    var stato: Pillola.Tono? = nil
    let azione: () -> Void

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo
    @State private var sopra = false

    private typealias L = Tema.Apple.Impostazioni.Laterale

    init(titolo: String, attiva: Bool, stato: Pillola.Tono? = nil, azione: @escaping () -> Void) {
        self.titolo = titolo
        self.attiva = attiva
        self.stato = stato
        self.azione = azione
    }

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: L.raggioVoce, style: .continuous)
        Button(action: azione) {
            HStack(spacing: Tema.Apple.Impostazioni.Stato.spazio) {
                Text(titolo)
                    .carattereApple(L.titoloVoce)
                    .foregroundColor(L.coloreVoce)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
                if let stato {
                    Circle()
                        .fill(StatoRigaApple.colore(stato))
                        .frame(width: Tema.Apple.Impostazioni.Stato.pallino, height: Tema.Apple.Impostazioni.Stato.pallino)
                        .accessibilityHidden(true)
                }
            }
            .padding(L.paddingVoce)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { forma.fill(fondo) }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { dentro in
            guard !istantanea else { return }
            withAnimation(Tema.Apple.Moto.animazione(L.animazioneFondo, calmo: calmo)) { sopra = dentro }
        }
        .animation(Tema.Apple.Moto.animazione(L.animazioneFondo, calmo: calmo, istantanea: istantanea), value: attiva)
        .accessibilityLabel(Text(titolo))
        .accessibilityAddTraits(attiva ? Self.trattiAttiva : Self.trattiVoce)
    }

    private var fondo: Color {
        if attiva { return L.fondoScelta }
        return sopra ? L.fondoSopra : Color.clear
    }

    private static var trattiVoce: AccessibilityTraits { .isButton }
    private static var trattiAttiva: AccessibilityTraits { [.isButton, .isSelected] }
}

// MARK: - Stato della riga

/// Lo stato a destra di una riga nel tema Apple: pallino 8 nel colore del tono e testo 13 semibold («● Pronto»).
struct StatoRigaApple: View {
    let testo: String
    let tono: Pillola.Tono

    private typealias S = Tema.Apple.Impostazioni.Stato

    static func colore(_ tono: Pillola.Tono) -> Color {
        switch tono {
        case .ok: return S.ok
        case .attenzione: return S.attenzione
        case .errore: return S.errore
        case .neutro: return S.neutro
        }
    }

    var body: some View {
        HStack(spacing: S.spazio) {
            Circle()
                .fill(Self.colore(tono))
                .frame(width: S.pallino, height: S.pallino)
            Text(testo)
                .carattereApple(S.carattere)
                .foregroundColor(S.coloreTesto)
                .lineLimit(1)
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Pulsanti nelle righe

/// I pulsanti dentro le righe delle Impostazioni: la capsula del tema Apple (`.btn`, o il blu `.btn.pri` per l'azione
/// principale), sul Mac e sull'iPad.
struct StilePulsanteRigaImpostazioni: ButtonStyle {
    var principale = false
    var grande = false

    init(principale: Bool = false, grande: Bool = false) {
        self.principale = principale
        self.grande = grande
    }

    func makeBody(configuration: Configuration) -> some View {
        StilePulsanteApple(principale ? .principale : .secondaria, grande: grande).makeBody(configuration: configuration)
    }
}

// MARK: - Anello del backup (§2.24)

/// L'anello del backup 110/12 verde. A riposo è pieno con la ✓ se l'ultimo backup è in regola, vuoto con il simbolo
/// del giro se non ce n'è ancora uno (o con «!» arancio se l'ultimo non è riuscito). Durante il backup riparte da 0
/// e sale in 1,6 s con la curva `(0.4,0,0.2,1)` fino a `frazioneAttesa` (il backup non dice quanto manca); a backup
/// finito si chiude e a 1,7 s dall'inizio compare la ✓ con la molla. 1,6 s è la durata minima mostrata.
/// «Riduci movimento» e istantanee: subito lo stato finale (pieno con la ✓, o fermo a metà durante il backup).
struct AnelloBackupApple: View {
    /// Il backup sta lavorando.
    let inCorso: Bool
    /// A riposo: pieno (ultimo backup in regola) o vuoto.
    let pieno: Bool
    /// L'ultimo backup non è riuscito: «!» al centro.
    var errore = false

    @Environment(\.prismaStatoFinale) private var statoFinale
    @State private var mostrata: Double = 0
    @State private var spunta = false
    @State private var inizio: Date?
    /// Cresce a ogni giro: un'attesa vecchia (asyncAfter) non tocca un backup nuovo.
    @State private var giro = 0

    private typealias B = Tema.Apple.Impostazioni.Backup
    private typealias Moto = Tema.Apple.Moto.Backup

    init(inCorso: Bool, pieno: Bool, errore: Bool = false) {
        self.inCorso = inCorso
        self.pieno = pieno
        self.errore = errore
    }

    /// Lo stato finale, senza animazioni.
    private var frazioneFinale: Double { inCorso ? B.frazioneAttesa : (pieno ? 1 : 0) }
    private var spuntaFinale: Bool { !inCorso && pieno }

    var body: some View {
        let frazione = statoFinale ? frazioneFinale : mostrata
        let conSpunta = statoFinale ? spuntaFinale : spunta
        let diametro = B.anello - B.spessore
        ZStack {
            Circle()
                .stroke(B.colore.opacity(B.opacitaBinario), lineWidth: B.spessore)
                .frame(width: diametro, height: diametro)
            Circle()
                .trim(from: 0, to: CGFloat(frazione))
                .stroke(B.colore, style: StrokeStyle(lineWidth: B.spessore, lineCap: .round))
                .rotationEffect(Tema.Apple.Grafico.Anello.inizio)
                .frame(width: diametro, height: diametro)
            centro(spunta: conSpunta)
        }
        .frame(width: B.anello, height: B.anello)
        .onAppear {
            mostrata = frazioneFinale
            spunta = spuntaFinale
        }
        .onChange(of: inCorso) { lavora in
            if lavora { parti() } else { chiudi() }
        }
        .onChange(of: pieno) { _ in
            guard !inCorso, inizio == nil else { return }
            mostrata = frazioneFinale
            spunta = spuntaFinale
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(inCorso ? "Backup in corso" : (pieno ? "Backup in regola" : "Nessun backup recente")))
    }

    @ViewBuilder private func centro(spunta conSpunta: Bool) -> some View {
        if conSpunta {
            Image(systemName: "checkmark")
                .font(B.spunta.font)
                .foregroundColor(B.coloreSpunta)
                .transition(.scale(scale: Moto.scalaSpunta).combined(with: .opacity))
        } else if !inCorso {
            Image(systemName: errore ? "exclamationmark" : "arrow.triangle.2.circlepath")
                .font(B.attesa.font)
                .foregroundColor(errore ? B.coloreErrore : B.coloreAttesa)
                .transition(.opacity)
        }
    }

    /// Il backup comincia: l'anello si svuota e sale fino all'attesa in 1,6 s.
    private func parti() {
        giro += 1
        inizio = Date()
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            spunta = false
            mostrata = 0
        }
        guard !statoFinale else { return }
        // Al giro dopo: lo 0 è già disegnato e la salita parte da lì
        DispatchQueue.main.async {
            withAnimation(Moto.animazione) { mostrata = B.frazioneAttesa }
        }
    }

    /// Il backup è finito: dopo almeno 1,6 s dall'inizio l'anello si chiude (o torna vuoto se non è riuscito) e
    /// poco dopo compare la ✓.
    private func chiudi() {
        let questo = giro
        let trascorso = inizio.map { Date().timeIntervalSince($0) } ?? Moto.durata
        let attesa = statoFinale ? 0 : max(0, Moto.durata - trascorso)
        let riuscito = pieno
        DispatchQueue.main.asyncAfter(deadline: .now() + attesa) {
            guard questo == giro else { return }
            inizio = nil
            guard !statoFinale else {
                mostrata = riuscito ? 1 : 0
                spunta = riuscito
                return
            }
            withAnimation(B.animazioneChiusura) { mostrata = riuscito ? 1 : 0 }
            guard riuscito else { return }
            let dopo = B.durataChiusura + max(0, Moto.ritardoSpunta - Moto.durata)
            DispatchQueue.main.asyncAfter(deadline: .now() + dopo) {
                guard questo == giro else { return }
                withAnimation(Moto.spunta) { spunta = true }
            }
        }
    }
}
