#if os(macOS)
import SwiftUI
import AppKit

// La sovrapposizione «Stanotte ho lavorato per te.» («Luce» giro 14, Design/template-luce-specifica.md §6.1.1-6.1.4):
// alone e velo, testata, pila di al più tre carte, timbri, comandi ✕ / contatore / ✓, registro «FATTO ADESSO» (clic su una
// riga = annulla), fine con l'anello, stati (notte saltata, niente da preparare, lavoro in corso). Gesti: trascinamento
// della carta davanti, scorrimento orizzontale a due dita sulla pila, → approva, ← più tardi, Esc chiude, Invio «Apri ›»,
// ⌘Z annulla l'ultima. Con «Riduci movimento» tutto compare fermo; nelle istantanee pila ferma e anello pieno.
// Valori grafici in `Tema.Apple.Notte` e `Tema.Apple.Moto.Notte`.

struct CarteNotte: View {
    @Environment(StatoShell.self) var stato
    let notte: StatoNotte

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo
    /// Lo spostamento della carta davanti (trascinamento, scorrimento, volo).
    @State private var dx: CGFloat = 0
    /// Una decisione è in volo: niente altri gesti finché non finisce.
    @State private var inVolo = false
    /// Le carte sono entrate (la cascata della prima apertura).
    @State private var entrate = false
    @State private var monitor = MonitorScorrimentoNotte()

    private typealias N = Tema.Apple.Notte
    private typealias M = Tema.Apple.Moto.Notte

    var body: some View {
        GeometryReader { geo in
            let stretta = geo.size.width < N.larghezzaStretta
            ZStack(alignment: .top) {
                sfondo(geo.size)
                VStack(spacing: 0) {
                    TestataNotte(notte: notte, stretta: stretta)
                    Spacer(minLength: 0).frame(height: N.Testata.sottoTestata)
                    contenuto(stretta: stretta)
                    Spacer(minLength: 0)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background { tasti }
        }
        .ignoresSafeArea()
        .onAppear {
            entrate = istantanea || calmo || !notte.primaApertura
            if !entrate { DispatchQueue.main.async { entrate = true } }
            if istantanea, let t = notte.trascinamentoIstantanea { dx = CGFloat(t) }
            if !istantanea { monitor.avvia(scorri: { delta in scorri(delta) }, fine: { rilascia() }) }
        }
        .onDisappear { monitor.ferma() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(TestiNotte.titoloSovrapposizione))
    }

    // MARK: Sfondo

    private func sfondo(_ misura: CGSize) -> some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(N.velo)
            RadialGradient(colors: [N.alone, N.alone.opacity(0)], center: N.centroAlone, startRadius: 0,
                           endRadius: N.raggioAlone * N.fineAlone)
                .scaleEffect(x: N.scalaAlone, y: 1, anchor: N.centroAlone)
        }
        .frame(width: misura.width, height: misura.height)
        .saturation(N.saturazione)
        .contentShape(Rectangle())
        // Il clic fuori dalla pila non chiude (si chiude con «Chiudi» o Esc)
        .onTapGesture {}
        .accessibilityHidden(true)
    }

    // MARK: Contenuto

    @ViewBuilder
    private func contenuto(stretta: Bool) -> some View {
        let rimanenti = stato.carteRimanentiNotte
        let n = stato.notteDiOggi
        if !rimanenti.isEmpty {
            disposizione(stretta: stretta) {
                VStack(spacing: N.Comandi.sottoPila) {
                    PilaNotte(carte: rimanenti, notte: n, clienti: clientiCarte(rimanenti), dx: dx, entrate: entrate, inVolo: inVolo,
                              trascina: { trascina($0) }, rilascia: { rilascia() }, apri: { stato.apriCartaNotte($0) },
                              sopra: { monitor.sopraPila = $0 })
                    ComandiNotte(posizione: notte.registro.count + 1, totale: max(notte.pila.count, notte.registro.count + 1),
                                 piuTardi: { decidi(destra: false) }, approva: { decidi(destra: true) })
                }
            }
        } else if !notte.registro.isEmpty || (n.map { !$0.carte.isEmpty && MotoreNotte.pila($0).isEmpty } ?? false) {
            disposizione(stretta: stretta) { FineNotte(conteggi: conteggiFine(n)) }
        } else if notte.inCorso {
            CartaStatoNotte(caso: .inCorso)
        } else if let n, n.esito == .fatta, n.carte.isEmpty {
            CartaStatoNotte(caso: .niente)
        } else {
            CartaStatoNotte(caso: stato.dati.impostazioni.notte.attivo ? .saltata : .spento)
        }
    }

    /// La pila (o la fine) con il registro a destra; sotto 1100 il registro va sotto, largo come la pila.
    @ViewBuilder
    private func disposizione<C: View>(stretta: Bool, @ViewBuilder _ principale: () -> C) -> some View {
        if stretta {
            VStack(spacing: N.Registro.sottoComandi) {
                principale()
                RegistroNotte(notte: notte, stretta: true)
            }
        } else {
            HStack(alignment: .top, spacing: N.Pila.spazioRegistro) {
                principale()
                RegistroNotte(notte: notte, stretta: false)
            }
        }
    }

    /// I clienti delle carte visibili (avatar e nome).
    private func clientiCarte(_ carte: [CartaNotte]) -> [String: Cliente] {
        let ids = Set(carte.prefix(Tema.Apple.Notte.Pila.visibili).compactMap(\.clienteId))
        var elenco: [String: Cliente] = [:]
        for c in stato.dati.clienti where ids.contains(c.id) && elenco[c.id] == nil { elenco[c.id] = c }
        return elenco
    }

    private func conteggiFine(_ n: NotteDiLavoro?) -> (approvate: Int, rimandate: Int) {
        if !notte.registro.isEmpty {
            let a = notte.registro.filter(\.approvata).count
            return (a, notte.registro.count - a)
        }
        let carte = n?.carte ?? []
        return (carte.filter { $0.stato == .approvata }.count, carte.filter { $0.stato == .rimandata }.count)
    }

    // MARK: Gesti

    private func trascina(_ x: CGFloat) {
        guard !inVolo else { return }
        dx = x
    }

    private func scorri(_ delta: CGFloat) {
        guard !inVolo, !stato.carteRimanentiNotte.isEmpty else { return }
        dx += delta
    }

    /// Rilascio: oltre la soglia decide, sotto torna al centro con la molla.
    private func rilascia() {
        guard !inVolo else { return }
        if dx > N.Timbro.soglia {
            decidi(destra: true)
        } else if dx < -N.Timbro.soglia {
            decidi(destra: false)
        } else {
            withAnimation(calmo ? Tema.Moto.dissolvenzaCalma : M.animazioneRitorno) { dx = 0 }
        }
    }

    /// A destra «Approva», a sinistra «Più tardi»: la carta vola via, poi la decisione (con calmo, una dissolvenza).
    private func decidi(destra: Bool) {
        guard !inVolo, let c = stato.carteRimanentiNotte.first else { return }
        let id = c.id
        let applica = {
            if destra { stato.approvaCartaNotte(id) } else { stato.rimandaCartaNotte(id) }
        }
        if istantanea || calmo {
            withAnimation(istantanea ? nil : Tema.Moto.dissolvenzaCalma) {
                applica()
                dx = 0
            }
            return
        }
        inVolo = true
        withAnimation(M.animazioneVolo) { dx = destra ? M.distanzaVolo : -M.distanzaVolo }
        Movimenti.dopo(M.volo) {
            applica()
            dx = 0
            inVolo = false
        }
    }

    /// Tasti invisibili: → approva, ← più tardi, Invio «Apri ›», ⌘Z annulla l'ultima (Esc è su «Chiudi»).
    private var tasti: some View {
        HStack(spacing: 0) {
            Button("") { decidi(destra: false) }.keyboardShortcut(.leftArrow, modifiers: [])
            Button("") { decidi(destra: true) }.keyboardShortcut(.rightArrow, modifiers: [])
            Button("") {
                if let c = stato.carteRimanentiNotte.first { stato.apriCartaNotte(c.id) }
            }
            .keyboardShortcut(.defaultAction)
            Button("") { stato.annullaUltimaCartaNotte() }.keyboardShortcut("z", modifiers: .command)
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }
}

// MARK: - Testata

private struct TestataNotte: View {
    @Environment(StatoShell.self) var stato
    let notte: StatoNotte
    let stretta: Bool

    private typealias T = Tema.Apple.Notte.Testata
    private typealias C = Tema.Apple.Notte.Carta

    var body: some View {
        HStack(alignment: .center, spacing: T.spazio) {
            TasselloGlifo(glifo: .notte, lato: T.tassello, tinta: Tema.Apple.Notte.Tipo.notte)
            VStack(alignment: .leading, spacing: T.spazioTitoli) {
                Text(TestiNotte.titoloSovrapposizione)
                    .carattereApple(T.titolo)
                    .foregroundColor(C.testo)
                sottotitolo
                    .carattereApple(T.sottotitolo)
                    .foregroundColor(C.testo2)
                    .lineLimit(2)
            }
            Spacer(minLength: T.spazio)
            Button(TestiNotte.chiudi) { stato.chiudiSovrapposizione() }
                .buttonStyle(.apple)
                .keyboardShortcut(.cancelAction)
                .help("Chiudi (esc)")
        }
        .padding(.horizontal, stretta ? T.margineStretto : T.margine)
        .padding(.top, T.dallAlto)
    }

    private var sottotitolo: Text {
        if notte.inCorso { return Text(TestiNotte.inCorso(fatte: notte.fatte, totale: notte.previste)) }
        guard let n = stato.notteDiOggi, !n.carte.isEmpty else { return Text(TestiNotte.istruzioni) }
        let quante = max(notte.pila.count, n.carte.filter { $0.perIl >= n.giorno }.count)
        return Text(TestiNotte.sottotitoloInizio(inizio: n.inizio, fine: n.fine))
            + Text(TestiNotte.cose(quante)).bold().foregroundColor(C.testo)
            + Text(". " + TestiNotte.istruzioni)
    }
}

// MARK: - Pila

private struct PilaNotte: View {
    let carte: [CartaNotte]
    let notte: NotteDiLavoro?
    let clienti: [String: Cliente]
    let dx: CGFloat
    let entrate: Bool
    let inVolo: Bool
    let trascina: (CGFloat) -> Void
    let rilascia: () -> Void
    let apri: (String) -> Void
    let sopra: (Bool) -> Void

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo
    @State private var cursore = false

    private typealias P = Tema.Apple.Notte.Pila
    private typealias M = Tema.Apple.Moto.Notte

    var body: some View {
        let visibili = Array(carte.prefix(P.visibili))
        ZStack(alignment: .top) {
            ForEach(Array(visibili.enumerated()).reversed(), id: \.element.id) { k, c in
                let davanti = k == 0
                CartaNotteVista(carta: c, cliente: c.clienteId.flatMap { clienti[$0] }, daIeri: notte.map { MotoreNotte.daIeri(c, in: $0) } ?? false,
                                spostamento: davanti ? dx : 0, timbri: davanti,
                                ruota: !calmo, apri: { apri(c.id) })
                    .scaleEffect(1 - CGFloat(k) * P.riduzione, anchor: .top)
                    .offset(y: CGFloat(k) * P.scarto)
                    .opacity(k == 2 ? P.opacitaTerza : 1)
                    .zIndex(Double(10 - k))
                    // La cascata della prima apertura
                    .offset(y: entrate ? 0 : M.spostamento + CGFloat(k) * P.scarto)
                    .scaleEffect(entrate ? 1 : M.scalaEntrata)
                    .opacity(entrate ? 1 : 0)
                    .animation(istantanea || calmo ? nil : M.animazioneEntrata(k), value: entrate)
                    .animation(istantanea ? nil : (calmo ? Tema.Moto.dissolvenzaCalma : M.animazionePila), value: carte.first?.id)
                    .gesture(trascinamento, including: davanti && !istantanea ? .all : .subviews)
            }
        }
        .frame(width: P.larghezza, height: P.altezza + CGFloat(P.visibili - 1) * P.scarto, alignment: .top)
        .onHover { dentro in
            sopra(dentro)
            if !dentro, cursore {
                NSCursor.pop()
                cursore = false
            } else if dentro, !cursore {
                NSCursor.openHand.push()
                cursore = true
            }
        }
        .onDisappear {
            if cursore { NSCursor.pop() }
            cursore = false
            sopra(false)
        }
    }

    private var trascinamento: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { v in
                guard !inVolo else { return }
                NSCursor.closedHand.set()
                trascina(v.translation.width)
            }
            .onEnded { _ in
                NSCursor.openHand.set()
                rilascia()
            }
    }
}

// MARK: - Carta

/// Una carta della notte (anche nella vetrina): tassello e occhiello del tipo, cliente, titolo, descrizione, piede con
/// «Apri ›», timbri durante il trascinamento.
struct CartaNotteVista: View {
    let carta: CartaNotte
    var cliente: Cliente? = nil
    var daIeri = false
    var spostamento: CGFloat = 0
    var timbri = true
    var ruota = true
    var apri: () -> Void = {}

    private typealias C = Tema.Apple.Notte.Carta
    private typealias T = Tema.Apple.Notte.Timbro
    private typealias M = Tema.Apple.Moto.Notte

    var body: some View {
        let tinta = Tema.Apple.Notte.Tipo.tinta(carta.tipo)
        let forma = RoundedRectangle(cornerRadius: C.raggio, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: C.spazioRiga) {
                TasselloGlifo(glifo: Tema.Apple.Notte.Tipo.glifo(carta.tipo), lato: C.tassello, tinta: tinta)
                Text(daIeri ? TestiNotte.daIeri + " · " + TestiNotte.occhiello(carta.tipo) : TestiNotte.occhiello(carta.tipo))
                    .carattereApple(C.occhiello)
                    .foregroundColor(tinta)
                Spacer(minLength: C.spazioRiga)
                if let c = cliente {
                    AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: C.avatar)
                    Text(c.nome)
                        .carattereApple(C.nome)
                        .foregroundColor(C.testo)
                        .lineLimit(1)
                }
            }
            Text(carta.titolo)
                .carattereApple(C.titolo)
                .foregroundColor(C.testo)
                .lineLimit(3)
                .padding(.top, C.sopraTitolo)
            Text(carta.descrizione)
                .carattereApple(C.descrizione)
                .foregroundColor(C.testo2)
                .lineLimit(5)
                .padding(.top, C.sopraDescrizione)
            Spacer(minLength: 0)
            HStack {
                Text(TestiNotte.piede(carta.preparataIl))
                    .carattereApple(C.piede)
                    .foregroundColor(C.testo2)
                Spacer()
                Button(action: apri) {
                    Text(TestiNotte.apri)
                        .carattereApple(C.apri)
                        .foregroundColor(C.accento)
                }
                .buttonStyle(StileSemplice())
            }
            .padding(.bottom, C.dalFondo - C.padding)
        }
        .padding(C.padding)
        .frame(width: Tema.Apple.Notte.Pila.larghezza, height: Tema.Apple.Notte.Pila.altezza, alignment: .topLeading)
        .background(forma.fill(C.fondo))
        .overlay(forma.strokeBorder(C.bordo, lineWidth: C.spessoreBordo))
        .overlay(alignment: .topLeading) {
            TimbroNotte(testo: TestiNotte.timbroApprova, colore: T.approva, sinistra: true)
                .opacity(timbri ? Double(max(0, spostamento) / T.soglia) : 0)
        }
        .overlay(alignment: .topTrailing) {
            TimbroNotte(testo: TestiNotte.timbroPiuTardi, colore: T.piuTardi, sinistra: false)
                .opacity(timbri ? Double(max(0, -spostamento) / T.soglia) : 0)
        }
        .clipShape(forma)
        .shadow(color: C.ombra2, radius: C.raggioOmbra2, x: 0, y: C.yOmbra2)
        .shadow(color: C.ombra1, radius: C.raggioOmbra1, x: 0, y: C.yOmbra1)
        .textSelection(.disabled)
        .offset(x: spostamento)
        .rotationEffect(.degrees(ruota ? Double(spostamento) * M.rotazionePerPunto : 0), anchor: .bottom)
        .accessibilityElement(children: .combine)
    }
}

/// «APPROVA» verde a sinistra (−12°) e «PIÙ TARDI» arancio a destra (+12°).
struct TimbroNotte: View {
    let testo: String
    let colore: Color
    let sinistra: Bool

    private typealias T = Tema.Apple.Notte.Timbro

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: T.raggio, style: .continuous)
        Text(testo)
            .carattereApple(T.carattere)
            .foregroundColor(colore)
            .padding(T.padding)
            .background(forma.fill(T.fondo))
            .overlay(forma.strokeBorder(colore, lineWidth: T.bordo))
            .rotationEffect(.degrees(sinistra ? -T.rotazione : T.rotazione))
            .padding(.top, T.dallAlto)
            .padding(sinistra ? .leading : .trailing, T.dalLato)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Comandi

private struct ComandiNotte: View {
    let posizione: Int
    let totale: Int
    let piuTardi: () -> Void
    let approva: () -> Void

    private typealias K = Tema.Apple.Notte.Comandi

    var body: some View {
        HStack(spacing: K.spazio) {
            PulsanteTondoNotte(segno: "✕", colore: K.piuTardi, aiuto: TestiNotte.piuTardi, azione: piuTardi)
            Text(TestiNotte.contatore(min(posizione, totale), di: totale))
                .carattereApple(K.carattereContatore)
                .foregroundColor(Tema.Apple.Notte.Carta.testo)
                .frame(width: K.contatore)
            PulsanteTondoNotte(segno: "✓", colore: K.approva, aiuto: TestiNotte.approva, azione: approva)
        }
    }
}

private struct PulsanteTondoNotte: View {
    let segno: String
    let colore: Color
    let aiuto: String
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @State private var sopra = false

    private typealias K = Tema.Apple.Notte.Comandi

    var body: some View {
        Button(action: azione) {
            Text(segno)
                .carattereApple(K.glifo)
                .foregroundColor(colore)
                .frame(width: K.pulsante, height: K.pulsante)
                .background(Circle().fill(K.fondo))
                .overlay(Circle().strokeBorder(K.bordo, lineWidth: Tema.Apple.Notte.Carta.spessoreBordo))
                .shadow(color: Tema.Apple.Notte.Carta.ombra2, radius: Tema.Apple.Notte.Carta.raggioOmbra2, x: 0,
                        y: Tema.Apple.Notte.Carta.yOmbra2)
                .contentShape(Circle())
        }
        .buttonStyle(StileSemplice())
        .scaleEffect(sopra && !calmo ? K.scalaSopra : 1)
        .animation(calmo ? nil : Tema.Apple.Moto.PulsantePremuto.animazione, value: sopra)
        .onHover { sopra = $0 }
        .help(aiuto)
        .accessibilityLabel(Text(aiuto))
    }
}

// MARK: - Registro

private struct RegistroNotte: View {
    @Environment(StatoShell.self) var stato
    let notte: StatoNotte
    let stretta: Bool

    @Environment(\.modoIstantanea) private var istantanea
    @Environment(\.prismaCalmo) private var calmo

    private typealias R = Tema.Apple.Notte.Registro
    private typealias M = Tema.Apple.Moto.Notte

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: R.raggio, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            Text(TestiNotte.registro)
                .carattereApple(Tema.Apple.Carattere.etichetta)
                .foregroundColor(Tema.Apple.Notte.Carta.testo2)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(notte.registro) { r in
                        riga(r)
                            .transition(istantanea || calmo ? .opacity
                                : .asymmetric(insertion: .offset(x: M.spostamentoRiga).combined(with: .opacity), removal: .opacity))
                    }
                }
                .animation(istantanea ? nil : (calmo ? Tema.Moto.dissolvenzaCalma : M.animazioneRiga), value: notte.registro)
            }
        }
        .padding(R.padding)
        .frame(width: stretta ? Tema.Apple.Notte.Pila.larghezza : R.larghezza,
               height: stretta ? R.altezzaStretta : R.altezza, alignment: .topLeading)
        .background(forma.fill(R.fondo))
        .overlay(forma.strokeBorder(R.bordo, lineWidth: Tema.Apple.Notte.Carta.spessoreBordo))
    }

    private func riga(_ r: RigaRegistroNotte) -> some View {
        Button {
            stato.annullaCartaNotte(r.id)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: R.spazioRiga) {
                Text(r.approvata ? "✓" : "↺")
                    .carattereApple(R.segnoCarattere)
                    .foregroundColor(r.approvata ? R.approvata : R.rimandata)
                    .frame(width: R.segno, alignment: .leading)
                Text(r.testo)
                    .carattereApple(R.riga)
                    .foregroundColor(Tema.Apple.Notte.Carta.testo)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, R.paddingRiga)
            .overlay(alignment: .bottom) { Rectangle().fill(R.bordo).frame(height: Tema.Apple.Notte.Carta.spessoreBordo) }
        }
        .buttonStyle(StileSemplice())
        .help("Clic per annullare")
    }
}

// MARK: - Fine

private struct FineNotte: View {
    @Environment(StatoShell.self) var stato
    let conteggi: (approvate: Int, rimandate: Int)

    private typealias F = Tema.Apple.Notte.Fine
    private typealias C = Tema.Apple.Notte.Carta

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: C.raggio, style: .continuous)
        VStack(spacing: 0) {
            AnelliConcentrici(voci: [VoceAnello(id: "notte", valore: 100, colore: F.colore)], misura: F.anello, spessore: F.spessore,
                              ritardo: Tema.Apple.Moto.Notte.ritardoAnello) {
                Text("✓")
                    .carattereApple(F.segno)
                    .foregroundColor(F.colore)
            }
            Text(TestiNotte.tuttoFatto)
                .carattereApple(F.titolo)
                .foregroundColor(C.testo)
                .padding(.top, F.sopraTitolo)
            Text(TestiNotte.fine(approvate: conteggi.approvate, rimandate: conteggi.rimandate, nome: stato.nomeUtente))
                .carattereApple(F.testo)
                .foregroundColor(C.testo2)
                .multilineTextAlignment(.center)
                .padding(.top, F.spazio)
            Button(TestiNotte.vaiAllaScrivania) { stato.chiudiSovrapposizione() }
                .buttonStyle(.applePrimarioGrande)
                .padding(.top, F.sopraTitolo)
        }
        .padding(C.padding)
        .frame(width: Tema.Apple.Notte.Pila.larghezza, height: Tema.Apple.Notte.Pila.altezza)
        .background(forma.fill(C.fondo))
        .overlay(forma.strokeBorder(C.bordo, lineWidth: C.spessoreBordo))
        .shadow(color: C.ombra1, radius: C.raggioOmbra1, x: 0, y: C.yOmbra1)
    }
}

// MARK: - Stati

/// La carta al posto della pila: notte saltata (lavoro acceso o spento), niente da preparare, lavoro in corso.
private struct CartaStatoNotte: View {
    enum Caso { case saltata, spento, niente, inCorso }

    @Environment(StatoShell.self) var stato
    let caso: Caso

    private typealias C = Tema.Apple.Notte.Carta
    private typealias F = Tema.Apple.Notte.Fine

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: C.raggio, style: .continuous)
        VStack(spacing: 0) {
            if caso == .niente {
                AnelliConcentrici(voci: [VoceAnello(id: "notte", valore: 100, colore: F.colore)], misura: F.anello,
                                  spessore: F.spessore, ritardo: Tema.Apple.Moto.Notte.ritardoAnello) {
                    Text("✓").carattereApple(F.segno).foregroundColor(F.colore)
                }
            } else {
                TasselloGlifo(glifo: .notte, lato: Tema.Apple.Notte.Testata.tassello, tinta: Tema.Apple.Notte.Tipo.notte)
                    .opacity(caso == .inCorso ? 1 : C.opacitaSpento)
            }
            Text(titolo)
                .carattereApple(F.titolo)
                .foregroundColor(C.testo)
                .multilineTextAlignment(.center)
                .padding(.top, F.sopraTitolo)
            Text(testo)
                .carattereApple(C.descrizione)
                .foregroundColor(C.testo2)
                .multilineTextAlignment(.center)
                .padding(.top, F.spazio)
            if caso == .saltata || caso == .spento {
                HStack(spacing: C.spazioPulsanti) {
                    Button(TestiNotte.chiudi) { stato.chiudiSovrapposizione() }
                        .buttonStyle(.apple)
                    Button(TestiNotte.preparaAdesso) { stato.preparaAdesso() }
                        .buttonStyle(.applePrimario)
                }
                .padding(.top, F.sopraTitolo)
            }
        }
        .padding(C.padding)
        .frame(width: Tema.Apple.Notte.Pila.larghezza, height: Tema.Apple.Notte.Pila.altezza)
        .background(forma.fill(C.fondo))
        .overlay(forma.strokeBorder(C.bordo, lineWidth: C.spessoreBordo))
        .shadow(color: C.ombra1, radius: C.raggioOmbra1, x: 0, y: C.yOmbra1)
    }

    private var titolo: String {
        switch caso {
        case .saltata: return TestiNotte.saltataTitolo
        case .spento: return TestiNotte.saltataSpentoTitolo
        case .niente: return TestiNotte.nienteTitolo
        case .inCorso: return TestiNotte.inCorsoTitolo
        }
    }

    private var testo: String {
        switch caso {
        case .saltata: return TestiNotte.saltataTesto
        case .spento: return TestiNotte.saltataSpentoTesto
        case .niente: return TestiNotte.nienteTesto
        case .inCorso: return TestiNotte.inCorsoTesto
        }
    }
}

// MARK: - Scorrimento a due dita

/// Il monitor locale dello scorrimento orizzontale (come GestoVeraScrivania): attivo solo con le carte aperte e il
/// puntatore sulla pila; la fine del gesto è il rilascio.
@Observable final class MonitorScorrimentoNotte {
    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored var sopraPila = false
    @ObservationIgnored private var scorri: ((CGFloat) -> Void)?
    @ObservationIgnored private var fine: (() -> Void)?

    func avvia(scorri: @escaping (CGFloat) -> Void, fine: @escaping () -> Void) {
        self.scorri = scorri
        self.fine = fine
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] e in
            guard let self else { return e }
            return self.gestisci(e)
        }
    }

    func ferma() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
        scorri = nil
        fine = nil
    }

    deinit {
        if let m = monitor { NSEvent.removeMonitor(m) }
    }

    private func gestisci(_ e: NSEvent) -> NSEvent? {
        // Solo il trackpad, con le fasi del gesto; l'inerzia dopo il rilascio si ignora
        guard sopraPila, e.hasPreciseScrollingDeltas, e.momentumPhase.isEmpty, !e.phase.isEmpty else { return e }
        if e.phase.contains(.ended) || e.phase.contains(.cancelled) {
            fine?()
            return nil
        }
        guard abs(e.scrollingDeltaX) > abs(e.scrollingDeltaY) else { return e }
        let segno: CGFloat = e.isDirectionInvertedFromDevice ? 1 : -1
        scorri?(e.scrollingDeltaX * segno)
        return nil
    }
}
#endif
