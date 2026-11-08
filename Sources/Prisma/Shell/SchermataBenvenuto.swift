import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// La schermata di blocco del template Apple (Design/template-apple-specifica.md §3.2): sopra l'acqua un velo
/// leggero e, al centro, il logo, l'ora grande e sottile, la data e in basso «Tocca per entrare in Prisma», un vetro
/// attraversato da una luce ogni 2,6 s. Si entra con un clic ovunque, con Invio o trascinando la schermata (come il
/// cursore di prima: oltre la soglia, o con un colpo rapido, si entra; altrimenti torna al suo posto).
/// È una schermata di cortesia: non protegge i dati (per quello c'è il blocco del Mac). Torna da sola quando il Mac
/// va a riposo o lo schermo si spegne (RipresaSistema). Lo sblocco passa da `StatoShell.sblocca`, che chiama il
/// punto unico `allaSblocco()` (EventiShell.swift); al primo avvio l'introduzione parte dopo (`dopoSblocco`).
/// Entrata (blocco): il velo scende da −30 in 0,5 s con la curva `uscita`; di colpo al riposo del Mac e all'avvio.
/// Uscita (sblocco): sale di 60, scala a 1,04, si sfoca di 8 e svanisce in 0,65 s. Con «Riduci movimento» solo
/// dissolvenze; nelle istantanee tutto fermo, con la luce fuori vista.
struct SchermataBenvenuto: View {
    /// L'uscita della schermata allo sblocco (la usa ShellView); l'entrata la fa la schermata da sé, perché al
    /// riposo del Mac deve comparire di colpo. Con «Riduci movimento» solo la dissolvenza.
    static var transizione: AnyTransition {
        guard !Movimenti.calmo else {
            return .asymmetric(insertion: .identity, removal: AnyTransition.opacity.animation(Tema.Moto.dissolvenzaCalma))
        }
        let s = Tema.Apple.Moto.Sblocco.self
        return .asymmetric(
            insertion: .identity,
            removal: AnyTransition.modifier(
                active: UscitaBlocco(salita: s.salita, scala: s.scala, sfocatura: s.sfocatura, opacita: 0),
                identity: UscitaBlocco(salita: 0, scala: 1, sfocatura: 0, opacita: 1))
                .animation(s.animazione))
    }

    @Environment(StatoShell.self) var stato
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    /// La schermata è arrivata (l'entrata del blocco).
    @State private var arrivata = false
    /// Si entra: il gesto non conta più (una volta sola).
    @State private var entrata = false
    /// Quanto la schermata segue il dito; torna a zero con una molla, anche se il gesto si interrompe (⌘Tab).
    @GestureState(resetTransaction: Transaction(animation: Tema.Moto.Sblocco.ritorno()))
    private var trascinamento: CGSize = .zero

    private typealias L = Tema.Apple.Lucchetto

    var body: some View {
        let _ = ContaCorpi.segna()
        let fermo = istantanea || calmo
        let dentro = arrivata || istantanea
        ZStack(alignment: .top) {
            // Il velo sopra l'acqua (la scrivania sotto è nascosta: niente sfocatura a tutto schermo)
            Tema.Apple.Colore.veloBlocco
            colonna
                .offset(fermo ? .zero : trascinamento)
        }
        .opacity(dentro ? 1 : 0)
        .offset(y: dentro || fermo ? 0 : Tema.Apple.Moto.Blocco.spostamento)
        .contentShape(Rectangle())
        .gesture(gestoSblocco)
        // Invio: un pulsante senza scritta e senza misura, solo per il tasto
        .background {
            Button("") { entra() }
                .buttonStyle(StileSemplice())
                .keyboardShortcut(.defaultAction)
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tocca per entrare in Prisma")
        .accessibilityAction { entra() }
        .onAppear(perform: arriva)
    }

    /// Logo, ora, data e, in fondo, il pulsante.
    private var colonna: some View {
        VStack(spacing: 0) {
            LogoPrisma(colore: Tema.Apple.Colore.logo)
                .frame(height: L.logo)
                .padding(.top, L.logoDallAlto)
                .accessibilityHidden(true)
            OrologioBlocco()
                .padding(.top, L.oraSottoLogo)
            Spacer(minLength: 0)
            PulsanteEntraBlocco()
                .padding(.bottom, L.pulsanteDalFondo)
        }
        .foregroundColor(Tema.Apple.Colore.inchiostroAcqua)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// L'entrata del blocco: animata dal lucchetto; di colpo all'avvio, al riposo del Mac (il blocco è già
    /// «stabile» quando la schermata compare) e nelle istantanee. Il cursore lascia il campo sotto la schermata.
    private func arriva() {
        #if os(macOS)
        NSApp.keyWindow?.makeFirstResponder(nil)
        #elseif os(iOS)
        _ = UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
        guard !arrivata else { return }
        if istantanea || stato.sistema.bloccatoStabile || !stato.persistente {
            arrivata = true
            return
        }
        withAnimation(Tema.Apple.Moto.animazione(Tema.Apple.Moto.Blocco.animazione, calmo: calmo)) { arrivata = true }
    }

    /// Un clic (pressione quasi ferma) fa entrare; un trascinamento oltre la soglia, o un colpo rapido, anche.
    private var gestoSblocco: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($trascinamento) { g, valore, _ in
                valore = CGSize(width: g.translation.width * L.seguito, height: g.translation.height * L.seguito)
            }
            .onEnded { g in rilascia(g) }
    }

    private func rilascia(_ g: DragGesture.Value) {
        let d = SchermataBenvenuto.lunghezza(g.translation)
        let prevista = SchermataBenvenuto.lunghezza(g.predictedEndTranslation)
        let clic = Tema.Misura.Shell.clicManopola
        if d <= clic {
            entra()
            return
        }
        guard d >= L.sogliaTrascinamento || prevista >= L.sogliaTrascinamento * L.quotaPrevista else { return }
        entra(velocita: Movimenti.velocita(traslazione: d, prevista: prevista, distanza: L.sogliaTrascinamento))
    }

    private static func lunghezza(_ s: CGSize) -> CGFloat {
        (s.width * s.width + s.height * s.height).squareRoot()
    }

    /// Si entra una volta sola.
    private func entra(velocita: Double = 0) {
        guard !entrata else { return }
        entrata = true
        stato.sblocca(velocita: velocita)
    }
}

/// L'uscita della schermata allo sblocco: sale, si allarga appena, si sfoca e svanisce.
/// La sfocatura vale 0 a riposo (nessun filtro) e c'è solo durante l'uscita.
private struct UscitaBlocco: ViewModifier {
    let salita: CGFloat
    let scala: CGFloat
    let sfocatura: CGFloat
    let opacita: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scala)
            .offset(y: -salita)
            .blur(radius: sfocatura)
            .opacity(opacita)
    }
}

/// L'ora grande e sottile e, sotto, la data («lunedì 2 novembre»). Si aggiorna allo scoccare del minuto.
private struct OrologioBlocco: View {
    @Environment(\.modoIstantanea) private var istantanea

    var body: some View {
        TimelineView(.everyMinute) { contesto in
            // Nelle istantanee l'ora è ferma, come nella barra
            let adesso = OraIstantanee.mostrata(contesto.date, istantanea: istantanea)
            VStack(spacing: Tema.Apple.Lucchetto.dataSottoOra) {
                Text(Formati.ora.string(from: adesso))
                    .carattereApple(Tema.Apple.Carattere.oraBlocco)
                    .lineLimit(1)
                    .fixedSize()
                Text(Formati.dataLunga.string(from: adesso))
                    .carattereApple(Tema.Apple.Lucchetto.data)
                    .opacity(Tema.Apple.Lucchetto.opacitaData)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// «Tocca per entrare in Prisma»: capsula di vetro con la luce che la attraversa. Non prende i clic: li prende
/// la schermata intera.
private struct PulsanteEntraBlocco: View {
    var body: some View {
        let L = Tema.Apple.Lucchetto.self
        Text("Tocca per entrare in Prisma")
            .carattereApple(L.pulsante)
            .lineLimit(1)
            .padding(L.paddingPulsante)
            .superficieApple(L.superficiePulsante)
            .overlay { LuceDelPulsante().clipShape(Capsule(style: .continuous)) }
            .allowsHitTesting(false)
    }
}

/// La luce del pulsante: attraversa da sinistra a destra nel primo 60% di ogni ciclo di 2,6 s (ease-in-out), poi
/// resta fuori vista. La fase si ricava dall'ora in una TimelineView (al massimo 30 fotogrammi al secondo), senza
/// Timer. Ferma e fuori vista con «Riduci movimento» e nelle istantanee.
private struct LuceDelPulsante: View {
    @Environment(\.prismaStatoFinale) private var fermo

    var body: some View {
        let L = Tema.Apple.Lucchetto.self
        let M = Tema.Apple.Moto.LuceBlocco.self
        return TimelineView(.animation(minimumInterval: M.intervallo, paused: fermo)) { contesto in
            GeometryReader { g in
                let w = g.size.width
                let p = fermo ? -1 : LuceDelPulsante.posizione(contesto.date)
                LinearGradient(stops: L.fermateLuce, startPoint: L.inizioLuce, endPoint: L.fineLuce)
                    .frame(width: w, height: g.size.height)
                    .offset(x: CGFloat(p) * w)
            }
        }
        .opacity(fermo ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Da −1 (fuori a sinistra) a +1 (fuori a destra) nel primo 60% del ciclo, poi fermo a +1.
    static func posizione(_ data: Date) -> Double {
        let M = Tema.Apple.Moto.LuceBlocco.self
        let fase = data.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: M.ciclo) / M.ciclo
        let t = min(fase / M.attraversamento, 1)
        return -1 + 2 * Tema.Apple.Moto.Curva.easeInOut.valore(t)
    }
}

/// «Le tue app aperte»: le finestre aperte, in primo piano o ridotte, ognuna con il suo cliente
/// (o il suo contesto), con un clic per tornarci. Pannello di vetro del tema (switcher).
struct PannelloAppAperte: View {
    @Environment(StatoShell.self) var stato
    /// Le finestre aperte e quella in primo piano.
    @Environment(StatoFinestre.self) var sistema

    var body: some View {
        let _ = ContaCorpi.segna()
        GeometryReader { geo in
            let m = Tema.Misura.Shell.self
            ZStack {
                Tema.Colore.Shell.veloPannello
                    .contentShape(Rectangle())
                    .onTapGesture { stato.pannelloAppAperte = false }
                // Il velo fa solo la dissolvenza; la scheda entra dal centro, come ⌘Tab
                pannello
                    .frame(width: max(0, min(m.appAperteLarghezza, geo.size.width - 2 * m.appAperteBordo)))
                    .frame(maxHeight: max(0, min(m.appAperteAltezza, geo.size.height - 2 * m.appAperteBordo)))
                    .entrataScheda(Tema.Moto.Pannelli.appAperte, scala: Tema.Moto.Pannelli.appAperteScala, ancora: .center)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var pannello: some View {
        let m = Tema.Misura.Shell.self
        return VStack(alignment: .leading, spacing: m.appAperteSpazio) {
            Text("Le tue app aperte")
                .font(Tema.Testo.sezione)
                .tracking(Tema.Testo.spaziaturaSezione)
                .foregroundColor(Tema.Colore.inchiostro)
            // Alto quanto le schede; oltre l'altezza massima le schede scorrono
            ViewThatFits(in: .vertical) {
                griglia
                ScrollView { griglia }
            }
            HStack(spacing: m.pulsantiSpazio) {
                Spacer()
                Button("Mostra la scrivania") {
                    stato.mostraScrivania()
                    stato.pannelloAppAperte = false
                }
                .buttonStyle(StileVetro())
                Button("Chiudi") { stato.pannelloAppAperte = false }
                    .buttonStyle(StileBlu())
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(m.appAperteMargine)
        .vetro(.pannello, forma: .arrotondata(Tema.Raggio.appAperte), riempimento: Tema.Colore.PannelliShell.coprente)
    }

    @ViewBuilder private var griglia: some View {
        let m = Tema.Misura.Shell.self
        let aperte = Array(sistema.elenco.reversed())
        if aperte.isEmpty {
            VStack(spacing: m.rigaTestoSpazio) {
                Text("La scrivania è tutta tua.")
                    .font(Tema.Testo.titolo)
                    .foregroundColor(Tema.Colore.inchiostro)
                Text("Apri un'app dal dock per iniziare.")
                    .font(Tema.Testo.secondario)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, m.appAperteMargine * 2)
        } else if aperte.count < colonne {
            // Meno app delle colonne: le schede, larghe come nella griglia, stanno al centro
            HStack(spacing: m.appAperteSpazio) {
                ForEach(aperte) { f in
                    SchedaAppAperta(finestra: f, inPrimoPiano: f.app == sistema.appAttiva)
                        .frame(width: larghezzaScheda)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: m.schedaAppMinima), spacing: m.appAperteSpazio)],
                      spacing: m.appAperteSpazio) {
                ForEach(aperte) { f in
                    SchedaAppAperta(finestra: f, inPrimoPiano: f.app == sistema.appAttiva)
                }
            }
        }
    }

    /// Lo spazio dentro il pannello (largo al massimo `appAperteLarghezza`) e le colonne della griglia adattiva.
    private var larghezzaInterna: CGFloat {
        let m = Tema.Misura.Shell.self
        return m.appAperteLarghezza - 2 * m.appAperteMargine
    }

    private var colonne: Int {
        let m = Tema.Misura.Shell.self
        return max(1, Int((larghezzaInterna + m.appAperteSpazio) / (m.schedaAppMinima + m.appAperteSpazio)))
    }

    /// La larghezza che una scheda avrebbe nella griglia piena.
    private var larghezzaScheda: CGFloat {
        let m = Tema.Misura.Shell.self
        let n = CGFloat(colonne)
        return max(m.schedaAppMinima, (larghezzaInterna - m.appAperteSpazio * (n - 1)) / n)
    }
}

/// Una scheda di «Le tue app aperte»: icona, nome, cliente o contesto della finestra, stato.
private struct SchedaAppAperta: View {
    @Environment(StatoShell.self) var stato
    let finestra: StatoShell.Finestra
    let inPrimoPiano: Bool
    @State var sopra = false

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.Shell.self
        let forma = RoundedRectangle(cornerRadius: Tema.Raggio.schedaApp, style: .continuous)
        Button {
            // Prima la modifica animata (il ripristino dal dock), poi la chiusura del pannello
            stato.apri(finestra.app)
            stato.pannelloAppAperte = false
        } label: {
            VStack(spacing: m.schedaAppSpazio) {
                IconaApp(app: finestra.app, lato: Tema.Misura.iconaAppAperte)
                    .padding(.bottom, m.schedaAppSpazio)
                Text(finestra.app.titolo)
                    .font(Tema.Testo.Shell.nomeAppAperta)
                    .foregroundColor(Tema.Colore.inchiostro)
                // Il cliente (o il contesto) di questa finestra; una riga vuota tiene le schede alte uguali
                Text(stato.contesto(di: finestra.app) ?? " ")
                    .font(Tema.Testo.Shell.contestoAppAperta)
                    .foregroundColor(Tema.Colore.inchiostroSecondario)
                Text(finestra.ridotta ? "Ridotta nel dock" : inPrimoPiano ? "In primo piano" : "Aperta")
                    .font(Tema.Testo.Shell.statoAppAperta)
                    .foregroundColor(Tema.Colore.inchiostroTerziario)
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity)
            .padding(m.schedaAppMargine)
            // Pozzetto e filo: in chiaro le schede si staccano dal fondo del pannello
            .background(forma.fill(sopra ? Tema.Colore.chipControlloSopra : Tema.Colore.pozzetto))
            .overlay(forma.strokeBorder(Tema.Colore.separatore, lineWidth: Tema.Misura.filo))
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { s in withAnimation(Tema.Moto.passaggio) { sopra = s } }
    }
}
