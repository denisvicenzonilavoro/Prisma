import SwiftUI

/// Dock delle applicazioni: capsula di vetro sottile con la Scrivania, il divisore e le app.
/// Sul Mac le icone (50 pt) si ingrandiscono al passaggio del puntatore come nel Dock di macOS
/// (template-apple-specifica.md §3.4: s = 1 + 0,36 · max(0, 1 − d/130), in 0,14 s; dal 12 novembre 2026 la capsula
/// non si alza più con le icone, che escono sopra di lei come nel Dock del Mac),
/// rimbalzano al clic e sopra l'icona compare il fumetto con il nome. Con «Riduci movimento», nelle istantanee
/// e su iPhone e iPad niente ingrandimento né rimbalzo.
/// Il Dock legge lo stato condiviso (app consentite, attiva, aperte); il passaggio vive in `FilaDock`,
/// in uno stato locale: passare sul dock non fa ricalcolare nient'altro dell'app. Le cornici delle icone
/// salgono con `ChiaveIconeDock` nel registro dello stato (`StatoFinestre.iconeDock`): le finestre ne escono e vi rientrano.
struct Dock: View {
    @Environment(StatoShell.self) var stato
    /// Quale app è davanti e quali sono aperte.
    @Environment(StatoFinestre.self) var sistema

    var body: some View {
        let _ = ContaCorpi.segna()
        let attiva = sistema.appAttiva
        let rientrano = sistema.rientrano
        let voci = AppPrisma.delDock.filter { stato.appConsentita($0) }.map { app -> VoceDock in
            // Chi rientra nell'icona (chiusa, in volo) ha già spento il pallino
            let via = rientrano.contains(app)
            return VoceDock(app: app, attiva: attiva == app && !via, aperta: sistema.aperta(app) && !via)
        }
        let shell = stato
        let registro = sistema.iconeDock
        FilaDock(voci: voci, scrivaniaAttiva: attiva == nil,
                 apri: { app in shell.apriApp(app) },
                 mostraScrivania: { shell.mostraScrivania() })
            // Si ridisegna solo se cambiano le icone o i puntini, non a ogni cambiamento dello stato
            .equatable()
            // Dove sta ogni icona (anche ingrandita): da lì escono le finestre. Non ridisegna niente
            .onPreferenceChange(ChiaveIconeDock.self) { cornici in registro.aggiorna(cornici) }
    }

    /// ⌥1…⌥9 per le prime nove app del dock.
    static func scorciatoia(_ app: AppPrisma) -> String? {
        guard let i = AppPrisma.delDock.firstIndex(of: app), i < 9 else { return nil }
        return "⌥\(i + 1)"
    }
}

/// Un'app nel dock con i suoi segni: davanti, aperta.
struct VoceDock: Equatable {
    let app: AppPrisma
    let attiva: Bool
    let aperta: Bool
}

/// La fila del dock. Lo stato è tutto qui (`@State`): quale icona ha il puntatore sopra (con il nome nel
/// fumetto), dove sta il puntatore (per l'ingrandimento) e i rimbalzi. Nessun oggetto condiviso cambia:
/// passare sul dock non fa ricalcolare nient'altro dell'app.
private struct FilaDock: View, Equatable {
    let voci: [VoceDock]
    let scrivaniaAttiva: Bool
    let apri: (AppPrisma) -> Void
    let mostraScrivania: () -> Void
    /// L'icona sotto il puntatore (0 = Scrivania), con il nome sopra.
    @State var sopra: Int? = nil
    /// La x del puntatore riportata sul dock a riposo (nil = fuori dal dock): da qui l'ingrandimento di ogni icona.
    @State var puntatore: CGFloat? = nil
    /// I clic su ogni icona (0 = Scrivania): ognuno la fa rimbalzare una volta.
    @State var rimbalzi: [Int: Int] = [:]
    @Environment(\.prismaCalmo) var calmo
    @Environment(\.modoIstantanea) var istantanea

    /// Le azioni chiamano sempre la stessa shell: contano solo le icone e i loro segni.
    nonisolated static func == (a: FilaDock, b: FilaDock) -> Bool {
        a.voci == b.voci && a.scrivaniaAttiva == b.scrivaniaAttiva
    }

    var body: some View {
        let lato = Tema.Misura.dockIcona
        let scale = ingrandimenti(puntatore)
        let riga = HStack(alignment: .bottom, spacing: DisposizioneDock.spazio) {
            ElementoDock(titolo: "Scrivania", etichetta: "Scrivania",
                         descrizione: "Torna alla scrivania: la tua giornata e i widget",
                         suggerimento: sopra == 0, attivo: scrivaniaAttiva, inEsecuzione: false,
                         ingrandimento: scala(scale, 0), rimbalzo: rimbalzi[0] ?? 0) {
                rimbalza(0)
                mostraScrivania()
            } icona: {
                ImmagineNitida(percorso: "Icone/Prisma.png", lato: lato)
            }
            .onHover { passa(0, $0) }
            DivisoreDock()
            ForEach(Array(voci.enumerated()), id: \.element.app) { indice, voce in
                ElementoDock(
                    titolo: voce.app.titolo,
                    etichetta: voce.app.nomeDock,
                    scorciatoia: Dock.scorciatoia(voce.app),
                    // Che cosa fa l'app, in una riga: la legge VoiceOver (il fumetto mostra solo il nome)
                    descrizione: voce.app.aiuto.inBreve,
                    suggerimento: sopra == indice + 1,
                    attivo: voce.attiva,
                    inEsecuzione: voce.aperta,
                    ingrandimento: scala(scale, indice + 1),
                    rimbalzo: rimbalzi[indice + 1] ?? 0,
                    app: voce.app
                ) {
                    rimbalza(indice + 1)
                    apri(voce.app)
                } icona: {
                    IconaApp(app: voce.app, lato: lato)
                }
                .onHover { passa(indice + 1, $0) }
            }
        }
        .padding(.vertical, DisposizioneDock.margine)
        .padding(.horizontal, DisposizioneDock.margineLato)
        .vetro(.leggero, forma: .arrotondata(Tema.Raggio.dock))
        #if os(macOS)
        return riga
            .onContinuousHover(coordinateSpace: .local) { fase in muovi(fase) }
        #else
        return riga
        #endif
    }

    /// Ingrandimento e rimbalzo: solo sul Mac, mai con «Riduci movimento» né nelle istantanee.
    private var ingrandisce: Bool {
        #if os(macOS)
        return !calmo && !istantanea
        #else
        return false
        #endif
    }

    private func scala(_ scale: [CGFloat], _ i: Int) -> CGFloat {
        i < scale.count ? scale[i] : 1
    }

    /// L'ingrandimento di ogni icona (Scrivania compresa) con il puntatore a `x` sul dock a riposo:
    /// s = 1 + 0,36 · max(0, 1 − d/130), d = distanza dal centro dell'icona a riposo.
    private func ingrandimenti(_ x: CGFloat?) -> [CGFloat] {
        let n = voci.count + 1
        guard let x, ingrandisce else { return Array(repeating: 1, count: n) }
        let d = DisposizioneDock.disposizione(icone: n)
        return d.centri.map { centro in
            Tema.Apple.Moto.IngrandimentoDock.scala(distanza: abs(x - (centro + d.larghezza / 2)))
        }
    }

    #if os(macOS)
    /// Il puntatore si muove sul dock. Il dock ingrandito è più largo e resta centrato: la x si riporta sul
    /// dock a riposo togliendo metà della crescita di adesso, così le icone non inseguono il puntatore.
    private func muovi(_ fase: HoverPhase) {
        switch fase {
        case .active(let p):
            guard ingrandisce else { return }
            let aumenti = ingrandimenti(puntatore).reduce(CGFloat(0)) { somma, s in somma + (s - 1) }
            let crescita = aumenti * Tema.Misura.dockIcona
            let x = p.x - crescita / 2
            guard let vecchia = puntatore else {
                // Entrando le icone crescono con la curva del tema
                withAnimation(Tema.Apple.Moto.IngrandimentoDock.animazione) { puntatore = x }
                return
            }
            guard abs(vecchia - x) >= Tema.Misura.filo else { return }
            // Poi seguono il puntatore quasi senza ritardo, come il Dock del Mac: una molla brevissima che si
            // riaggancia a ogni movimento (una curva a tempo fisso le farebbe inseguire il puntatore)
            withAnimation(Tema.Apple.Moto.IngrandimentoDock.segui) { puntatore = x }
        case .ended:
            guard puntatore != nil else { return }
            withAnimation(Tema.Apple.Moto.IngrandimentoDock.animazione) { puntatore = nil }
        }
    }
    #endif

    /// Il clic fa rimbalzare l'icona: −16, 0, −7, 0 in 0,7 s (prima del cambio di stato dell'app, che va dopo).
    private func rimbalza(_ indice: Int) {
        guard ingrandisce else { return }
        withAnimation(Tema.Apple.Moto.RimbalzoIcona.animazione) {
            rimbalzi[indice] = (rimbalzi[indice] ?? 0) + 1
        }
    }

    /// Il puntatore entra o esce da un'icona: il fumetto compare subito, senza attesa, come nel Dock del Mac.
    /// Uscendo si spegne solo se è ancora quello dell'icona lasciata (l'ingresso nella vicina può arrivare prima).
    private func passa(_ indice: Int, _ dentro: Bool) {
        if dentro {
            if sopra != indice { withAnimation(Tema.Moto.Dock.suggerimento) { sopra = indice } }
        } else if sopra == indice {
            withAnimation(Tema.Moto.Dock.suggerimento) { sopra = nil }
        }
    }
}

/// Misure e disposizione del dock, fuori dalla vista: le usa anche lo stato delle finestre (da dove si apre
/// un'app, dove va a ridursi), che non sta sul thread delle viste.
enum DisposizioneDock {
    /// Spazio fra le icone e margini (in frazioni del lato dell'icona, come nel tema).
    static var spazio: CGFloat { Tema.Misura.dockIcona * Tema.Misura.dockSpazioQuota }
    static var margine: CGFloat { Tema.Misura.dockIcona * Tema.Misura.dockMargineQuota }
    /// Il margine laterale tiene dentro la capsula anche i nomi lunghi sotto la prima e l'ultima icona
    /// («Impostazioni» è più largo dell'icona); `disposizione` lo conta.
    static var margineLato: CGFloat {
        margine + Tema.Misura.Shell.margineDockLato + Tema.Misura.PannelliShell.etichetteDockLato * Tipo.fattore
    }
    /// Il divisore: un filo con il suo margine (oltre lo spazio fra gli elementi).
    static var rientroDivisore: CGFloat { max(0, Tema.Misura.Shell.divisoreMargine - spazio) }
    static var larghezzaDivisore: CGFloat { Tema.Misura.filo * 2 + 2 * rientroDivisore }

    /// Centri delle icone (Scrivania compresa) rispetto al centro del dock e larghezza del dock.
    static func disposizione(icone numero: Int) -> (centri: [CGFloat], larghezza: CGFloat) {
        let lato = Tema.Misura.dockIcona
        var x = margineLato
        var centri: [CGFloat] = []
        for i in 0..<max(0, numero) {
            centri.append(x + lato / 2)
            x += lato + spazio
            // Dopo la Scrivania c'è il divisore
            if i == 0 { x += larghezzaDivisore + spazio }
        }
        let larghezza = x - spazio + margineLato
        return (centri.map { $0 - larghezza / 2 }, larghezza)
    }

    /// Altezza sotto l'icona: nome e puntino dell'app aperta.
    static var altezzaSotto: CGFloat {
        let m = Tema.Misura.Shell.self
        return m.etichettaSpazio + m.etichettaDock + m.puntinoSpazio + Tema.Misura.puntinoDock
    }

    /// Centro dell'icona dell'app nel dock a riposo, nelle coordinate della shell (`ShellView.spazioShell`) grande
    /// `misura`. `elenco`: le app del dock (quelle consentite). Con il dock nascosto l'icona è sul bordo in basso.
    static func centroIcona(_ app: AppPrisma, tra elenco: [AppPrisma], in misura: CGSize, nascosto: Bool) -> CGPoint? {
        guard let i = elenco.firstIndex(of: app), misura.width > 0, misura.height > 0 else { return nil }
        // La Scrivania è la prima icona
        let centri = disposizione(icone: elenco.count + 1).centri
        guard i + 1 < centri.count else { return nil }
        let lato = Tema.Misura.dockIcona
        let y = misura.height - Tema.Misura.dockDalBasso - margine - altezzaSotto - lato / 2
        return CGPoint(x: misura.width / 2 + centri[i + 1],
                       y: nascosto ? min(y + Misure.Dock.corsaNascosto, misura.height) : y)
    }
}

/// Il divisore fra la Scrivania e le app: un filo verticale che sfuma in alto e in basso.
struct DivisoreDock: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Tema.Colore.pozzettoScuro.opacity(0), Tema.Colore.pozzettoScuro,
                                          Tema.Colore.pozzettoScuro.opacity(0)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: Tema.Misura.filo * 2, height: Tema.Misura.dockIcona)
            .padding(.horizontal, DisposizioneDock.rientroDivisore)
            .padding(.bottom, DisposizioneDock.altezzaSotto)
    }
}

/// Elemento del dock: l'icona, il nome sotto, il puntino se l'app è aperta e, con il puntatore sopra
/// (lo decide la fila), il fumetto scuro con il nome dell'app, come nel Dock del Mac.
struct ElementoDock<Icona: View>: View {
    let titolo: String
    /// Il nome breve sotto l'icona.
    let etichetta: String
    var scorciatoia: String? = nil
    /// A che cosa serve l'app: solo per VoiceOver, non compare sullo schermo.
    var descrizione: String? = nil
    /// Il puntatore è sopra: compare il fumetto con il nome.
    var suggerimento = false
    let attivo: Bool
    let inEsecuzione: Bool
    /// Quanto è ingrandita l'icona dal puntatore (1 = a riposo): cresce dal basso, la voce si allarga.
    var ingrandimento: CGFloat = 1
    /// I clic sull'icona: a ogni nuovo clic rimbalza (RimbalzoIconaDock).
    var rimbalzo: Int = 0
    /// L'app dell'icona: la sua cornice sale nel registro del dock (le finestre ne escono). nil = Scrivania.
    var app: AppPrisma? = nil
    let azione: () -> Void
    @ViewBuilder let icona: () -> Icona
    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    var body: some View {
        let lato = Tema.Misura.dockIcona
        let m = Tema.Misura.Shell.self
        let acceso = inEsecuzione || attivo
        Button(action: azione) {
            VStack(spacing: 0) {
                icona()
                    .frame(width: lato, height: lato)
                    // Una scala (l'immagine resta nitida: le icone sono PNG da 512 px). La cella si allarga (le vicine
                    // fanno posto) ma non si alza: l'icona esce sopra la capsula e il dock resta dov'è, come sul Mac
                    .scaleEffect(ingrandimento, anchor: .bottom)
                    .frame(width: lato * ingrandimento, height: lato, alignment: .bottom)
                    .corniceIconaDock(app)
                    .modifier(RimbalzoIconaDock(fase: CGFloat(rimbalzo)))
                Text(etichetta)
                    .font(Tema.Testo.Shell.etichettaDock)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                    .lineLimit(1)
                    // Mai rimpicciolito: un nome lungo («Impostazioni») sborda appena dalla cella dell'icona,
                    // ma resta dentro la capsula grazie al margine laterale del dock (`DisposizioneDock.margineLato`)
                    .fixedSize()
                    .frame(width: lato, height: m.etichettaDock)
                    .padding(.top, m.etichettaSpazio)
                Circle()
                    .fill(Tema.Colore.Shell.puntinoDock)
                    .frame(width: Tema.Misura.puntinoDock, height: Tema.Misura.puntinoDock)
                    .opacity(acceso ? 1 : 0)
                    .animation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.PuntinoDock.animazione,
                                                     calmo: calmo, istantanea: istantanea), value: acceso)
                    .padding(.top, m.puntinoSpazio)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(StileIconaDock())
        .accessibilityLabel(Text(titolo))
        .accessibilityHint(Text(aiutoVoiceOver))
        // Il fumetto sta sopra il dock (in un overlay: non sposta niente) e non prende il puntatore
        .overlay(alignment: .top) {
            if suggerimento {
                SuggerimentoDock(testo: titolo)
                    .fixedSize()
                    // La punta del fumetto sta `suggerimentoDistanza` sopra l'icona, fuori dalla capsula del dock
                    .alignmentGuide(VerticalAlignment.top) { d in
                        d[VerticalAlignment.bottom] + m.suggerimentoDistanza
                    }
                    // Sopra l'icona ingrandita, che esce dalla cella
                    .offset(y: -(ingrandimento - 1) * lato)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .zIndex(suggerimento ? 1 : 0)
    }

    /// Per VoiceOver: che cosa fa l'app e la scorciatoia.
    private var aiutoVoiceOver: String {
        [descrizione, scorciatoia.map { "Scorciatoia \($0)" }].compactMap { $0 }.joined(separator: ". ")
    }
}

/// Icona premuta: più scura (brightness .82 del tema).
private struct StileIconaDock: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? Tema.Misura.Shell.premutoDock : 0)
    }
}

/// Fumetto sopra l'icona, come nel Dock del Mac: rettangolo arrotondato scuro con la punta in basso al centro
/// e il solo nome dell'app in bianco. Uguale in chiaro e in scuro (in scuro con un filo chiaro attorno).
struct SuggerimentoDock: View {
    let testo: String

    var body: some View {
        let m = Tema.Misura.Shell.self
        let forma = FormaFumettoDock(raggio: Tema.Raggio.Shell.fumettoDock,
                                     larghezzaPunta: m.fumettoPuntaLarghezza, altezzaPunta: m.fumettoPuntaAltezza)
        Text(testo)
            .font(Tema.Testo.Shell.suggerimentoDock)
            .foregroundColor(Tema.Colore.Shell.testoFumettoDock)
            .lineLimit(1)
            .padding(m.suggerimentoMargine)
            // Lo spazio della punta, sotto il testo
            .padding(.bottom, m.fumettoPuntaAltezza)
            .background(forma.fill(Tema.Colore.Shell.fondoFumettoDock))
            .overlay(forma.stroke(Tema.Colore.Shell.filoFumettoDock, lineWidth: Tema.Misura.filo * 2))
            .ombraTema(Tema.Ombra.Shell.fumettoDock)
    }
}

/// Il contorno del fumetto: un rettangolo arrotondato e, sotto al centro, la punta che indica l'icona.
/// Un solo tracciato, così il filo attorno non passa fra il corpo e la punta.
private struct FormaFumettoDock: Shape {
    var raggio: CGFloat
    var larghezzaPunta: CGFloat
    var altezzaPunta: CGFloat

    func path(in r: CGRect) -> Path {
        let corpo = CGRect(x: r.minX, y: r.minY, width: r.width, height: max(0, r.height - altezzaPunta))
        let k = min(raggio, corpo.height / 2, corpo.width / 2)
        let meta = min(larghezzaPunta / 2, max(0, corpo.width / 2 - k))
        var p = Path()
        p.move(to: CGPoint(x: corpo.minX + k, y: corpo.minY))
        p.addArc(tangent1End: CGPoint(x: corpo.maxX, y: corpo.minY), tangent2End: CGPoint(x: corpo.maxX, y: corpo.maxY), radius: k)
        p.addArc(tangent1End: CGPoint(x: corpo.maxX, y: corpo.maxY), tangent2End: CGPoint(x: corpo.minX, y: corpo.maxY), radius: k)
        p.addLine(to: CGPoint(x: corpo.midX + meta, y: corpo.maxY))
        p.addLine(to: CGPoint(x: corpo.midX, y: corpo.maxY + altezzaPunta))
        p.addLine(to: CGPoint(x: corpo.midX - meta, y: corpo.maxY))
        p.addArc(tangent1End: CGPoint(x: corpo.minX, y: corpo.maxY), tangent2End: CGPoint(x: corpo.minX, y: corpo.minY), radius: k)
        p.addArc(tangent1End: CGPoint(x: corpo.minX, y: corpo.minY), tangent2End: CGPoint(x: corpo.maxX, y: corpo.minY), radius: k)
        p.closeSubpath()
        return p
    }
}
