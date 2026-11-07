import SwiftUI

// Ruby nel tema Apple: i componenti che si muovono (Design/template-apple-specifica.md §2.18-2.20, §4.7).
// - SferaRuby: il solo simbolo di Ruby. Gradiente radiale con il riflesso conico che gira in 6 s; `viva` respira in
//   4 s, `pensa` pulsa (1 → 1,1 → 1 in 0,9 s) al posto del respiro. Si muove solo quando è sullo schermo, mai con
//   «Riduci movimento» né nelle istantanee (fotogramma 0). Niente Timer: TimelineView a 30 fotogrammi, in pausa
//   appena la sfera è ferma.
// - PuntiniScrittura: i tre puntini «sta scrivendo»; fermi a 0,4 con calma e nelle istantanee.
// - TestoProgressivo: le parole compaiono una alla volta, al più una ogni 0,038 s, senza dissolvenza: è il ritmo
//   minimo di presentazione del testo che Qwen scrive in streaming, non una finta scrittura. Con calma e nelle
//   istantanee tutto il testo subito.
// - `.entrataBollaUtente(_:)` (molla di 0,42 s da y +14, scala 0,96) e `.entrataSchedaCalcoli(_:)` (0,5 s
//   `uscita` da y +10): la sequenza di una domanda (§4.7).
// Gettoni in Tema.Apple+Ruby.swift e TemaAppleMoto.swift (`Moto.Sfera`, `Moto.Puntini`, `Moto.Testo`, …).

// MARK: - Sfera di Ruby (§2.18)

/// La sfera di Ruby: 24 nella barra, 46 nel riquadro della scrivania, 120 nell'app.
///
///     SferaRuby(misura: Tema.Apple.Ruby.Sfera.ruby, viva: true, pensa: stato.rubyInCorso)
struct SferaRuby: View {
    let misura: CGFloat
    /// Respira (4 s) quando è sullo schermo.
    var viva: Bool
    /// Ruby lavora: la sfera pulsa al posto del respiro.
    var pensa: Bool

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var visibile = false
    @State private var inizioPensa: Date?

    init(misura: CGFloat, viva: Bool = true, pensa: Bool = false) {
        self.misura = misura
        self.viva = viva
        self.pensa = pensa
    }

    var body: some View {
        let muove = !fermo && visibile && (viva || pensa)
        TimelineView(.animation(minimumInterval: 1 / Tema.Apple.Ruby.Sfera.fotogrammi, paused: !muove)) { contesto in
            corpo(muove ? Self.fase(al: contesto.date, viva: viva, pensa: pensa, inizioPensa: inizioPensa) : .riposo)
        }
        .frame(width: misura, height: misura)
        .onAppear {
            visibile = true
            if pensa && inizioPensa == nil { inizioPensa = Date() }
        }
        .onDisappear { visibile = false }
        .onChange(of: pensa) { p in inizioPensa = p ? Date() : nil }
        .accessibilityHidden(true)
    }

    /// Un fotogramma della sfera: rotazione del riflesso, scala e quanto è acceso l'alone del respiro (0…1).
    struct Fase {
        var angolo: Double
        var scala: CGFloat
        var respiro: Double
        static let riposo = Fase(angolo: 0, scala: 1, respiro: 0)
    }

    /// La fase all'istante dato: il riflesso gira sempre; la pulsazione (lineare, come nel template) vince sul respiro.
    nonisolated static func fase(al data: Date, viva: Bool, pensa: Bool, inizioPensa: Date?) -> Fase {
        let m = Tema.Apple.Moto.Sfera.self
        let t = data.timeIntervalSinceReferenceDate
        let angolo = (t / m.giro).truncatingRemainder(dividingBy: 1) * 360
        if pensa, let inizio = inizioPensa {
            let u = (max(0, data.timeIntervalSince(inizio)) / m.pensa).truncatingRemainder(dividingBy: 1)
            let w = u < 0.5 ? u * 2 : (1 - u) * 2
            return Fase(angolo: angolo, scala: 1 + (m.scalaPensa - 1) * CGFloat(w), respiro: 0)
        }
        if viva {
            let u = (t / m.respiro).truncatingRemainder(dividingBy: 1)
            let w = u < 0.5 ? u * 2 : (1 - u) * 2
            // ease-in-out: al centro del ciclo la sfera è più grande e l'alone acceso
            let e = (1 - cos(Double.pi * w)) / 2
            return Fase(angolo: angolo, scala: 1 + (m.scalaRespiro - 1) * CGFloat(e), respiro: e)
        }
        return Fase(angolo: angolo, scala: 1, respiro: 0)
    }

    private func corpo(_ f: Fase) -> some View {
        let s = Tema.Apple.Ruby.Sfera.self
        let c = Tema.Apple.Colore.self
        let lato = misura
        let respiro = Tema.Apple.Ombra.respiroSfera
        let interna = Tema.Apple.Ombra.internaSfera
        let raggioRespiro = respiro.sfocatura * Tema.Apple.Ombra.raggioPerSfocatura
        let alfaRespiro = f.respiro * Tema.Apple.Ombra.opacitaApprossimata(respiro)
        return ZStack {
            Circle()
                .fill(RadialGradient(stops: c.fermateSfera, center: c.centroSfera,
                                     startRadius: 0, endRadius: lato * s.estensioneGradiente))
            // Il riflesso conico (`:after`, inset −30%) fuso in `overlay`
            AngularGradient(stops: c.fermateRiflessoSfera, center: .center,
                            startAngle: .degrees(s.inizioRiflesso), endAngle: .degrees(s.inizioRiflesso + 360))
                .frame(width: lato * s.estensioneRiflesso, height: lato * s.estensioneRiflesso)
                .rotationEffect(.degrees(f.angolo))
                .blendMode(.overlay)
            // L'ombra interna in basso (inset 0 −4 10)
            Circle()
                .stroke(interna.colore, lineWidth: s.spessoreOmbraInterna)
                .blur(radius: interna.sfocatura * Tema.Apple.Ombra.raggioPerSfocatura)
                .offset(y: interna.y)
                .frame(width: lato, height: lato)
        }
        .frame(width: lato, height: lato)
        .compositingGroup()
        .clipShape(Circle())
        .background {
            // L'ombra fuori dalla sfera (e l'alone azzurro a metà del respiro): su un cerchio dietro, mai tagliata
            Circle()
                .fill(c.fermateSfera.last?.color ?? c.accento)
                .ombraApple(.sfera)
                .shadow(color: respiro.colore.opacity(alfaRespiro), radius: raggioRespiro, x: 0, y: respiro.y)
        }
        .scaleEffect(f.scala)
    }
}

// MARK: - Puntini «sta scrivendo» (§2.19)

/// Tre cerchi da 7 (`inchiostro3`) a 4 l'uno dall'altro: ciclo di 1 s sfasato di 0,15 s; al 30% il cerchio sale
/// di 5 con opacità 1, per il resto del ciclo resta a 0,4. Con calma e nelle istantanee fermi a 0,4.
struct PuntiniScrittura: View {
    @Environment(\.prismaStatoFinale) private var fermo

    var body: some View {
        let e = Tema.Apple.Ruby.Puntini.self
        let m = Tema.Apple.Moto.Puntini.self
        TimelineView(.animation(minimumInterval: 1 / e.fotogrammi, paused: fermo)) { contesto in
            let t = contesto.date.timeIntervalSinceReferenceDate
            HStack(spacing: e.spazio) {
                ForEach(0..<3, id: \.self) { i in
                    let p: (salita: Double, luce: Double) = fermo ? (0, 0) : Self.picco(t - Double(i) * m.sfasamento)
                    Circle()
                        .fill(e.colore)
                        .frame(width: e.lato, height: e.lato)
                        .offset(y: m.salita * CGFloat(p.salita))
                        .opacity(m.opacitaCalma + (1 - m.opacitaCalma) * p.luce)
                }
            }
        }
        .padding(.vertical, e.paddingVerticale)
        .fixedSize()
        .accessibilityLabel(Text("Ruby sta scrivendo"))
    }

    /// Salita (0…1) e luce (0…1) di un puntino: la salita va da 0 al 30% e torna a 100%; la luce torna giù al 60%.
    nonisolated static func picco(_ tempo: Double) -> (salita: Double, luce: Double) {
        let m = Tema.Apple.Moto.Puntini.self
        let ciclo = m.ciclo
        let r = tempo.truncatingRemainder(dividingBy: ciclo)
        let k = (r < 0 ? r + ciclo : r) / ciclo
        func morbido(_ x: Double) -> Double { let y = min(max(x, 0), 1); return y * y * (3 - 2 * y) }
        let salita = k < m.picco ? morbido(k / m.picco) : 1 - morbido((k - m.picco) / (1 - m.picco))
        let luce: Double
        if k < m.picco {
            luce = morbido(k / m.picco)
        } else if k < 2 * m.picco {
            luce = 1 - morbido((k - m.picco) / m.picco)
        } else {
            luce = 0
        }
        return (salita, luce)
    }
}

// MARK: - Testo parola per parola (§2.20)

/// Il testo che compare una parola alla volta, al più una ogni `passo` secondi, senza dissolvenza.
/// Il carattere si dà fuori (`.carattereApple(…)`). Un testo che cresce (streaming) continua da dove era arrivato.
///
///     TestoProgressivo(testo: flusso.testo, staffetta: .consegna) { scorriInFondo() }
struct TestoProgressivo: View {
    /// La bolla in arrivo consegna alla risposta finita le parole già mostrate: la risposta riparte da lì.
    enum Staffetta { case nessuna, consegna, riceve }

    let testo: String
    var passo: Double = Tema.Apple.Moto.Testo.parola
    /// false: tutto subito (i messaggi già letti).
    var anima = true
    var staffetta: Staffetta = .nessuna
    /// A ogni parola (la chat scorre in fondo).
    var avanza: (() -> Void)? = nil
    /// Quando l'ultima parola è comparsa (o subito, se il testo è già tutto).
    var finito: (() -> Void)? = nil

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var mostrate = 0
    @State private var partito = false
    @State private var concluso = false
    @State private var ultimoPasso = Date.distantPast

    /// Le parole mostrate dalla bolla in arrivo e quando (vale per poco: è la stessa risposta).
    @MainActor private static var consegnate: (parole: Int, quando: Date)? = nil
    /// Oltre questo tempo la consegna non vale più (era una risposta di prima).
    private static let validitaConsegna: TimeInterval = 2

    init(testo: String, passo: Double = Tema.Apple.Moto.Testo.parola, anima: Bool = true, staffetta: Staffetta = .nessuna,
         avanza: (() -> Void)? = nil, finito: (() -> Void)? = nil) {
        // «164.000 €» e «− 200 €» non si spezzano a fine riga
        self.testo = CifreDoc.unisciAlSegno(testo)
        self.passo = passo
        self.anima = anima
        self.staffetta = staffetta
        self.avanza = avanza
        self.finito = finito
    }

    var body: some View {
        let fini = Self.fini(testo)
        let tutto = fermo || !anima
        let n = tutto ? fini.count : min(mostrate, fini.count)
        Text(Self.prefisso(testo, fini: fini, parole: n))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear { parti(totale: fini.count) }
            .task(id: fini.count) { await scorri(totale: fini.count) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(testo))
    }

    @MainActor private func parti(totale: Int) {
        guard !partito else { return }
        partito = true
        if fermo || !anima {
            mostrate = totale
            return
        }
        switch staffetta {
        case .riceve:
            if let c = Self.consegnate, Date().timeIntervalSince(c.quando) < Self.validitaConsegna {
                mostrate = min(c.parole, totale)
            }
            Self.consegnate = nil
        case .consegna:
            Self.consegnate = (0, Date())
        case .nessuna:
            break
        }
    }

    @MainActor private func scorri(totale: Int) async {
        parti(totale: totale)
        if anima && !fermo {
            while mostrate < totale {
                let attesa = passo - Date().timeIntervalSince(ultimoPasso)
                if attesa > 0 { try? await Task.sleep(nanoseconds: UInt64(attesa * 1_000_000_000)) }
                if Task.isCancelled { return }
                mostrate += 1
                ultimoPasso = Date()
                if staffetta == .consegna { Self.consegnate = (mostrate, ultimoPasso) }
                avanza?()
            }
        }
        if !concluso {
            concluso = true
            finito?()
        }
    }

    /// Dove finisce ogni parola (una parola è una corsa di caratteri che non sono spazi).
    nonisolated static func fini(_ s: String) -> [String.Index] {
        var esito: [String.Index] = []
        var i = s.startIndex
        while i < s.endIndex {
            let dopo = s.index(after: i)
            if !s[i].isWhitespace && (dopo == s.endIndex || s[dopo].isWhitespace) { esito.append(dopo) }
            i = dopo
        }
        return esito
    }

    /// Il testo fino alla parola `n` compresa, con gli spazi e gli a capo di Qwen.
    nonisolated static func prefisso(_ s: String, fini: [String.Index], parole n: Int) -> String {
        guard n > 0, !fini.isEmpty else { return "" }
        if n >= fini.count { return s }
        return String(s[..<fini[n - 1]])
    }
}

// MARK: - Entrate della sequenza di una domanda (§4.7)

/// La bolla dell'utente entra con la molla di 0,42 s, da y +14 e scala 0,96 (con calma una dissolvenza).
private struct EntrataBollaUtente: ViewModifier {
    let attiva: Bool
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var entrata = false

    func body(content: Content) -> some View {
        let m = Tema.Apple.Moto.BollaUtente.self
        let fuori = attiva && !entrata && !istantanea
        let sposta = fuori && !calmo
        return content
            .opacity(fuori ? 0 : 1)
            .scaleEffect(sposta ? m.scala : 1, anchor: .bottomTrailing)
            .offset(y: sposta ? m.spostamento : 0)
            .onAppear {
                guard attiva, !entrata, !istantanea else { return }
                withAnimation(Tema.Apple.Moto.animazione(m.animazione, calmo: calmo)) { entrata = true }
            }
    }
}

/// La scheda dei calcoli entra dopo il testo: 0,5 s con la curva `uscita`, da y +10.
private struct EntrataSchedaCalcoli: ViewModifier {
    let attiva: Bool
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var entrata = false

    func body(content: Content) -> some View {
        let m = Tema.Apple.Moto.SchedaCalcoli.self
        let fuori = attiva && !entrata && !istantanea
        return content
            .opacity(fuori ? 0 : 1)
            .offset(y: fuori && !calmo ? m.spostamento : 0)
            .onAppear {
                guard attiva, !entrata, !istantanea else { return }
                withAnimation(Tema.Apple.Moto.animazione(m.animazione, calmo: calmo)) { entrata = true }
            }
    }
}

extension View {
    /// La bolla della domanda appena fatta entra a molla (`attiva` false: c'era già, nessuna entrata).
    func entrataBollaUtente(_ attiva: Bool) -> some View {
        modifier(EntrataBollaUtente(attiva: attiva))
    }

    /// La scheda dei calcoli della risposta appena arrivata entra dal basso (`attiva` false: c'era già).
    func entrataSchedaCalcoli(_ attiva: Bool) -> some View {
        modifier(EntrataSchedaCalcoli(attiva: attiva))
    }
}
