import SwiftUI

// «La tua settimana, il tuo anno» (versione «Luce», giro 5, Design/template-luce-specifica.md §5.2): la storia a tutto
// palco sopra la scrivania (SovrapposizioneLuce.storia), una pagina alla volta, testo bianco su fondi colorati fissi.
//
//   ━━━━━━ ━━━━━━ ──────  ──────                                                          (✕)
//                         [logo]
//                   Buongiorno, Denis.
//          Ecco la tua settimana · 2 – 8 novembre
//
// - Barre in alto (una per pagina): le viste piene, quella in corso si riempie in 5,2 s; sull'ultima la storia resta.
// - Clic sulla metà destra = avanti, sulla sinistra = indietro (da 60 in giù); ← → da tastiera; Esc o «✕» chiudono.
// - Il passaggio automatico è un `Task` che dorme 5,2 s (niente Timer), annullato a ogni cambio di pagina e alla
//   chiusura; il blocco e il riposo del Mac chiudono la storia (StatoShellFinestre.blocca).
// - «Riduci movimento»: niente cascate né salti, la pagina compare ferma con la dissolvenza di 0,15 s, la barra è piena
//   subito; il passaggio automatico resta a 5,2 s (decisione 128). Istantanee: pagina ferma, barra corrente a metà.
// - Le storie sono del consulente: non si aprono in modalità cliente (come Studio).
// Le pagine sono in PagineStoria.swift; i valori in DesignSystem/Apple/Tema.Apple+Storie.swift.

/// Le pagine della storia aperta e quella in corso. Un oggetto a parte: sfogliare non ridisegna la shell.
final class StatoStoria: ObservableObject {
    @Published var tipo: TipoStoria = .settimana
    @Published var pagine: [PaginaStoria] = []
    @Published var pagina = 0
    /// La settimana raccontata (per «Ecco la tua settimana · …»).
    var periodo: DateInterval?
    /// I dati sono quelli di prova: «dati di prova» in piccolo sulla prima pagina.
    var diProva = false
    /// Solo istantanee: l'invito «La tua settimana è pronta» sulla scrivania anche se oggi non è lunedì.
    var invitoIstantanea = false

    var corrente: PaginaStoria? { pagine.indices.contains(pagina) ? pagine[pagina] : nil }
    var ultima: Bool { pagina >= pagine.count - 1 }
}

extension PaginaStoria {
    /// Il fondo della pagina (coppie del template, §5.2.1).
    var tinta: Tema.Apple.Storia.Tinta {
        switch self {
        case .saluto: return .blu
        case .incontri: return .viola
        case .inArrivo: return .verde
        case .daChiamare: return .rosso
        case .traguardo: return .ambra
        case .finaleSettimana: return .mare
        case .annoTitolo: return .notte
        case .protette: return .corallo
        case .patrimonio: return .cielo
        case .nuoviClienti: return .prato
        case .chilometri: return .cuoio
        case .momento: return .lavanda
        case .grazie: return .blu
        }
    }
}

extension StatoShell {
    /// Apre la storia della settimana o dell'anno (voce Novità, pulsante della scrivania, «▶︎ Il tuo anno» di Studio,
    /// ultima pagina della settimana). In modalità cliente non si apre: le storie parlano del lavoro del consulente.
    func apriStoria(_ tipo: TipoStoria, oggi: Date = Date()) {
        guard !inModoCliente else {
            mostraAvviso("In modalità cliente le storie non si aprono: parlano del tuo lavoro e di tutti i clienti.")
            return
        }
        let cal = Calendar.current
        let pagine: [PaginaStoria]
        switch tipo {
        case .settimana:
            pagine = MotoreStorie.settimana(dati: dati, oggi: oggi, cal: cal)
            storia.periodo = MotoreStorie.settimanaDi(oggi, cal: cal)
        case .anno:
            pagine = MotoreStorie.anno(dati: dati, anno: cal.component(.year, from: oggi), oggi: oggi, cal: cal)
        }
        storia.tipo = tipo
        storia.pagine = pagine
        storia.pagina = 0
        storia.diProva = haDatiDiProva
        segnaStoriaVista(tipo, oggi: oggi)
        if sistema.sovrapposizione?.storiaAperta != nil {
            // Dall'ultima pagina della settimana all'anno: la sovrapposizione resta, cambia la storia
            sistema.sovrapposizione = .storia(tipo)
        } else {
            apriSovrapposizione(.storia(tipo))
        }
    }

    /// Ricorda che la storia di questa settimana (o di quest'anno) è stata vista: non si ripropone. Mai nelle
    /// istantanee, nelle prove o in sola lettura.
    func segnaStoriaVista(_ tipo: TipoStoria, oggi: Date = Date()) {
        guard persistente, !solaLettura else { return }
        let cal = Calendar.current
        switch tipo {
        case .settimana:
            let l = MotoreStorie.lunedi(di: oggi, cal: cal)
            if dati.impostazioni.storie.ultimaSettimanaVista != l { dati.impostazioni.storie.ultimaSettimanaVista = l }
        case .anno:
            let a = cal.component(.year, from: oggi)
            if dati.impostazioni.storie.ultimoAnnoVisto != a { dati.impostazioni.storie.ultimoAnnoVisto = a }
        }
    }

    /// La storia di questa settimana non è ancora stata vista ed è lunedì: la scrivania mostra l'invito.
    func invitoSettimana(oggi: Date = Date()) -> Bool {
        if storia.invitoIstantanea { return true }
        let cal = Calendar.current
        guard cal.component(.weekday, from: oggi) == 2, !inModoCliente else { return false }
        return dati.impostazioni.storie.ultimaSettimanaVista != MotoreStorie.lunedi(di: oggi, cal: cal)
    }

    /// Dopo lo sblocco, il lunedì: la storia della settimana si apre da sola una volta (Impostazioni › Studio la
    /// spegne), 1,7 s dopo lo sblocco come le novità, solo sul Mac, solo se nel frattempo non si è aperto altro e
    /// se le novità non si stanno aprendo da sole (in quel caso la storia aspetta il prossimo sblocco).
    func proponiStoriaDopoSblocco(oggi: Date = Date()) {
        #if os(macOS)
        guard persistente, !solaLettura, dati.impostazioni.storie.aperturaLunedi,
              dati.impostazioni.novitaViste == NovitaLuce.versione, invitoSettimana(oggi: oggi) else { return }
        let attesa = max(0, Tema.Apple.Moto.PannelloNovita.aperturaAutomatica - Tema.Moto.Sblocco.durataEntrata)
        Movimenti.dopo(attesa) { [weak self] in
            guard let self, !self.bloccato, self.presentazione == nil, !self.inModoCliente,
                  self.sistema.guida == nil, !self.pannelloRicerca, !self.pannelloSpazi, !self.pannelloAppAperte,
                  !self.sistema.pannelloNovita, self.sistema.sovrapposizione == nil,
                  self.invitoSettimana() else { return }
            self.apriStoria(.settimana)
        }
        #endif
    }

    /// «Festeggialo ›»: chiude la storia e apre Messaggi sul traguardo di quel cliente.
    func festeggiaDallaStoria(_ traguardoId: String, clienteId: String) {
        chiudiSovrapposizione()
        apriTraguardo(traguardoId, clienteId: clienteId)
    }

    /// «Apri ›» delle pagine: chiude la storia e porta dove nasce la cifra.
    func apriDallaStoria(_ pagina: PaginaStoria) {
        chiudiSovrapposizione()
        switch pagina {
        case .incontri:
            giornoAgenda = Calendar.current.startOfDay(for: storia.periodo?.start ?? Date())
            apri(.agenda)
        case .inArrivo:
            apriStudio(.cruscotto)
        case .daChiamare(let id, _):
            clienteAttivoId = id
            apri(.clienti)
        default:
            break
        }
    }
}

// MARK: - La sovrapposizione

/// La storia a tutto palco: fondo, pagina, barre, «✕», zone di tocco e tasti.
struct StoriaLuce: View {
    @EnvironmentObject var stato: StatoShell
    @ObservedObject var storia: StatoStoria

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo
    /// La barra della pagina in corso (0…1).
    @State private var avanzamento: CGFloat = 0
    @State private var passaggio: Task<Void, Never>?

    private typealias S = Tema.Apple.Storia
    private typealias M = Tema.Apple.Moto.Storia

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if let p = storia.corrente {
                    ZStack {
                        S.fondo(p.tinta, larghezza: geo.size.width)
                        PaginaStoriaVista(pagina: p, storia: storia)
                            .padding(S.Contenuto.margini)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .id(storia.pagina)
                    .transition(.opacity)
                }
                barre(geo.size.width)
                chiudi
                    .frame(width: geo.size.width, alignment: .topTrailing)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { tocco in
                guard tocco.location.y >= S.Contenuto.sopraZone else { return }
                if tocco.location.x < geo.size.width / 2 { indietro() } else { avanti() }
            })
            .background { tasti }
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .dark)
        .onAppear { parti() }
        .onChange(of: storia.pagina) { _ in parti() }
        .onChange(of: storia.tipo) { _ in parti() }
        .onDisappear {
            passaggio?.cancel()
            passaggio = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(storia.tipo == .settimana ? "La tua settimana" : "Il tuo anno"))
    }

    // MARK: Barre e chiusura

    private func barre(_ larghezza: CGFloat) -> some View {
        let b = S.Barre.self
        let n = max(storia.pagine.count, 1)
        return HStack(spacing: b.spazio) {
            ForEach(0..<n, id: \.self) { i in
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(b.binario)
                        Capsule().fill(b.piena)
                            .frame(width: g.size.width * riempimento(i))
                    }
                }
                .frame(height: b.altezza)
            }
        }
        .padding(.leading, b.margineSinistro)
        .padding(.trailing, b.margineDestro)
        .padding(.top, b.alto)
        .frame(width: larghezza, alignment: .leading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func riempimento(_ i: Int) -> CGFloat {
        if i < storia.pagina { return 1 }
        if i > storia.pagina { return 0 }
        if istantanea { return M.barraIstantanea }
        return avanzamento
    }

    private var chiudi: some View {
        let c = S.Chiudi.self
        return Button {
            stato.chiudiSovrapposizione()
        } label: {
            Text("✕")
                .carattereApple(c.carattere)
                .foregroundColor(S.testo)
                .frame(width: c.lato, height: c.lato)
                .background(Circle().fill(c.fondo))
                .contentShape(Circle())
        }
        .buttonStyle(StileSemplice())
        .keyboardShortcut(.cancelAction)
        .help("Chiudi (esc)")
        .accessibilityLabel(Text("Chiudi la storia"))
        .padding(.top, c.alto)
        .padding(.trailing, c.destra)
    }

    /// ← → da tastiera (pulsanti invisibili, come nella presentazione dei prospetti: `onKeyPress` c'è solo da macOS 14).
    private var tasti: some View {
        HStack(spacing: 0) {
            Button("") { indietro() }.keyboardShortcut(.leftArrow, modifiers: [])
            Button("") { avanti() }.keyboardShortcut(.rightArrow, modifiers: [])
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    // MARK: Sfogliare

    private var transizione: Animation {
        calmo ? Tema.Moto.dissolvenzaCalma : M.animazioneApre
    }

    private func avanti() {
        guard !storia.ultima else { return }
        withAnimation(istantanea ? nil : transizione) { storia.pagina += 1 }
    }

    private func indietro() {
        guard storia.pagina > 0 else { return }
        withAnimation(istantanea ? nil : transizione) { storia.pagina -= 1 }
    }

    /// La barra della pagina si riempie in 5,2 s (con calmo è piena subito) e, se non è l'ultima, un `Task` passa alla
    /// pagina dopo. Nelle istantanee niente.
    private func parti() {
        passaggio?.cancel()
        passaggio = nil
        guard !istantanea else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { avanzamento = calmo ? 1 : 0 }
        if !calmo {
            DispatchQueue.main.async {
                withAnimation(.linear(duration: M.durataPagina)) { avanzamento = 1 }
            }
        }
        guard !storia.ultima else { return }
        let pagina = storia.pagina
        passaggio = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(M.durataPagina * 1_000_000_000))
            guard !Task.isCancelled, storia.pagina == pagina, stato.sistema.sovrapposizione?.storiaAperta != nil else { return }
            avanti()
        }
    }
}
