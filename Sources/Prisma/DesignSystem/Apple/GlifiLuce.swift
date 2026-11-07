import SwiftUI

// I 29 glifi della versione «Luce» (Design/template-luce-specifica.md §1.4.1, tabelle `GL` del template, righe 1201-1205
// e 1787-1792) e il tassello colorato che li porta (`ic`, `.espI`). I glifi sono disegnati in vettoriale con l'aspetto
// originale (decisione 125: niente SF Symbols): ogni glifo è il testo SVG del template (viewBox 24×24, tratto bianco 2,
// capi e giunti tondi; i pezzi con `fill` sono anche pieni) letto una volta sola da un piccolo lettore scritto qui
// (comandi M L H V C S A Z, maiuscoli e minuscoli; `rect` con rx e `circle`). Nessuna dipendenza esterna.

/// Un glifo di Luce. Il valore grezzo è la chiave del template.
enum GlifoLuce: String, CaseIterable, Identifiable {
    // Le 15 novità davanti al cliente
    case prisma, mappa, lettera, film, disegna, storia, palestra, luce, capsula, festa, rischio, giornata, dadi, valore, ar
    // Le 14 novità per il lavoro
    case notte, proposta, modulo, cartella, sinistro, libro, lente, radar, campagna, scan, albero, azienda, voce, auto

    var id: String { rawValue }

    /// La tinta del tassello (stessa in chiaro e in scuro).
    var colore: Color {
        typealias G = Tema.Apple.Colore.Glifi
        switch self {
        case .prisma: return G.prisma
        case .mappa: return G.mappa
        case .lettera: return G.lettera
        case .film: return G.film
        case .disegna: return G.disegna
        case .storia: return G.storia
        case .palestra: return G.palestra
        case .luce: return G.luce
        case .capsula: return G.capsula
        case .festa: return G.festa
        case .rischio: return G.rischio
        case .giornata: return G.giornata
        case .dadi: return G.dadi
        case .valore: return G.valore
        case .ar: return G.ar
        case .notte: return G.notte
        case .proposta: return G.proposta
        case .modulo: return G.modulo
        case .cartella: return G.cartella
        case .sinistro: return G.sinistro
        case .libro: return G.libro
        case .lente: return G.lente
        case .radar: return G.radar
        case .campagna: return G.campagna
        case .scan: return G.scan
        case .albero: return G.albero
        case .azienda: return G.azienda
        case .voce: return G.voce
        case .auto: return G.auto
        }
    }

    /// I pezzi del glifo, come nel template.
    fileprivate var pezzi: [PezzoGlifo] {
        switch self {
        case .prisma: return [.rettangolo(7, 2.5, 10, 19, 2.5), .tratto("M10.5 18.5h3")]
        case .luce: return [.tratto("M11 4.5l6.5 12.5H4.5z"), .tratto("M1 13.5h4.5M17.5 10.5l5-2.5M17.5 13l5.5 0M17.5 15.5l5 2.5")]
        case .lettera: return [.rettangolo(3, 5.5, 18, 13, 2), .tratto("M3.5 7l8.5 6 8.5-6")]
        case .film: return [.rettangolo(2.5, 5, 19, 14, 3), .pieno("M10 9.2v5.6l4.8-2.8z")]
        case .disegna: return [.tratto("M3 17c3-1 4-6 7-6s2 5 5 5 3-6 6-8"), .tratto("M17.5 3.5l3 3")]
        case .rischio: return [.tratto("M3 6l5 5 4-3 5 7 4-2"), .tratto("M17 15h4v-4")]
        case .giornata:
            return [.cerchio(12, 12, 4, pieno: false),
                    .tratto("M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5.2 5.2l1.8 1.8M17 17l1.8 1.8M5.2 18.8L7 17M17 7l1.8-1.8")]
        case .dadi:
            return [.rettangolo(4, 4, 16, 16, 3.5), .cerchio(9, 9, 1.3, pieno: true), .cerchio(15, 15, 1.3, pieno: true),
                    .cerchio(15, 9, 1.3, pieno: true), .cerchio(9, 15, 1.3, pieno: true)]
        case .valore: return [.tratto("M12 3l2.6 5.6 6 .7-4.5 4.1 1.2 6L12 16.4 6.7 19.4l1.2-6L3.4 9.3l6-.7z")]
        case .capsula: return [.tratto("M7 3h10M7 21h10M8 3v3l4 6-4 6v3M16 3v3l-4 6 4 6v3")]
        case .ar: return [.tratto("M12 3l8 4.5v9L12 21l-8-4.5v-9z"), .tratto("M12 12l8-4.5M12 12v9M12 12L4 7.5")]
        case .mappa: return [.tratto("M3 6.5l6-2.5 6 2.5 6-2.5v13.5l-6 2.5-6-2.5-6 2.5z"), .tratto("M9 4v13.5M15 6.5V20")]
        case .storia: return [.rettangolo(5, 2.5, 14, 19, 3), .tratto("M8 6h8")]
        case .palestra: return [.tratto("M4 6h10a3 3 0 0 1 3 3v2H9l-5 4z"), .tratto("M20 11v4l-3-2h-5")]
        case .festa: return [.tratto("M4 20l5-14 9 9z"), .tratto("M14 4l1 2M19 5l-2 2M20 10l-2-.5")]
        case .notte: return [.tratto("M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z")]
        case .proposta:
            return [.rettangolo(3, 3, 8, 8, 2), .rettangolo(13, 3, 8, 8, 2), .rettangolo(3, 13, 8, 8, 2), .tratto("M17 13v8M13 17h8")]
        case .modulo: return [.rettangolo(5, 3, 14, 18, 2), .tratto("M8.5 8h7M8.5 12h7M8.5 16h4")]
        case .cartella:
            return [.tratto("M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"), .tratto("M8.5 13l2.5 2.5 4.5-5")]
        case .sinistro: return [.tratto("M3 18l5-5 4 3 6-7 3 3"), .cerchio(8, 13, 1.6, pieno: false), .cerchio(18, 9, 1.6, pieno: false)]
        case .libro:
            return [.tratto("M5 4.5A1.5 1.5 0 0 1 6.5 3H19v15H6.5A1.5 1.5 0 0 0 5 19.5z"), .tratto("M5 19.5A1.5 1.5 0 0 0 6.5 21H19")]
        case .lente: return [.cerchio(10.5, 10.5, 6.5, pieno: false), .tratto("M15.5 15.5L21 21")]
        case .radar: return [.cerchio(12, 12, 9, pieno: false), .cerchio(12, 12, 4.5, pieno: false), .tratto("M12 12l6-6")]
        case .campagna: return [.tratto("M3 10v4h3l7 4V6L6 10z"), .tratto("M17 9a4 4 0 0 1 0 6")]
        case .scan:
            return [.tratto("M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3"),
                    .rettangolo(7.5, 8.5, 9, 7, 1.2)]
        case .albero:
            return [.cerchio(12, 5, 2, pieno: false), .cerchio(6, 19, 2, pieno: false), .cerchio(18, 19, 2, pieno: false),
                    .cerchio(12, 19, 2, pieno: false), .tratto("M12 7v5M6 17v-3h12v3M12 12v5")]
        case .azienda: return [.tratto("M4 21V9l6-3v3l6-3v15z"), .tratto("M8 13h1M12 13h1M8 17h1M12 17h1M16 21V10h4v11")]
        case .voce: return [.rettangolo(9, 3, 6, 11, 3), .tratto("M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21")]
        case .auto: return [.tratto("M4 16v-4l2-5h12l2 5v4z"), .cerchio(8, 16.5, 1.8, pieno: false), .cerchio(16, 16.5, 1.8, pieno: false)]
        }
    }

    /// I tracciati nel riquadro 24×24: tutti i pezzi (per il tratto) e i soli pieni. Letti una volta sola.
    fileprivate var tracciati: (tutti: Path, pieni: Path) {
        if let t = Self.cache[self] { return t }
        var tutti = Path()
        var pieni = Path()
        for p in pezzi {
            let (tracciato, pieno) = p.tracciato
            tutti.addPath(tracciato)
            if pieno { pieni.addPath(tracciato) }
        }
        Self.cache[self] = (tutti, pieni)
        return (tutti, pieni)
    }

    /// Solo dal thread principale (le viste): niente serrature.
    private static var cache: [GlifoLuce: (tutti: Path, pieni: Path)] = [:]
}

/// Un pezzo del glifo nel riquadro 24×24.
private enum PezzoGlifo {
    /// Un tracciato SVG solo a tratto.
    case tratto(String)
    /// Un tracciato SVG a tratto e pieno (`fill="#fff"`).
    case pieno(String)
    /// `rect` a tratto: x, y, larghezza, altezza, rx.
    case rettangolo(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
    /// `circle`: centro, raggio, pieno o no.
    case cerchio(CGFloat, CGFloat, CGFloat, pieno: Bool)

    var tracciato: (Path, Bool) {
        switch self {
        case .tratto(let d): return (LettoreTracciatoSVG.leggi(d), false)
        case .pieno(let d): return (LettoreTracciatoSVG.leggi(d), true)
        case let .rettangolo(x, y, w, h, r):
            return (Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r, style: .circular), false)
        case let .cerchio(cx, cy, r, pieno):
            return (Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)), pieno)
        }
    }
}

/// Un lettore minimo dell'attributo `d` dei tracciati SVG: M L H V C S A Z (assoluti e relativi). Basta ai glifi di Luce,
/// che hanno solo archi circolari senza rotazione.
enum LettoreTracciatoSVG {
    static func leggi(_ d: String) -> Path {
        var lettore = Lettura(Array(d.utf8))
        var p = Path()
        var corrente = CGPoint.zero
        var inizio = CGPoint.zero
        var ultimoControllo: CGPoint?
        var comando: UInt8 = 0
        while let c = lettore.prossimoComando(precedente: comando) {
            comando = c
            let relativo = c >= 97   // minuscola
            let base = relativo ? corrente : .zero
            switch c | 0x20 {   // in minuscolo
            case UInt8(ascii: "m"):
                guard let x = lettore.numero(), let y = lettore.numero() else { return p }
                corrente = CGPoint(x: base.x + x, y: base.y + y)
                inizio = corrente
                p.move(to: corrente)
                ultimoControllo = nil
                // Le coppie dopo M sono linee
                comando = relativo ? UInt8(ascii: "l") : UInt8(ascii: "L")
            case UInt8(ascii: "l"):
                guard let x = lettore.numero(), let y = lettore.numero() else { return p }
                corrente = CGPoint(x: base.x + x, y: base.y + y)
                p.addLine(to: corrente)
                ultimoControllo = nil
            case UInt8(ascii: "h"):
                guard let x = lettore.numero() else { return p }
                corrente = CGPoint(x: (relativo ? corrente.x : 0) + x, y: corrente.y)
                p.addLine(to: corrente)
                ultimoControllo = nil
            case UInt8(ascii: "v"):
                guard let y = lettore.numero() else { return p }
                corrente = CGPoint(x: corrente.x, y: (relativo ? corrente.y : 0) + y)
                p.addLine(to: corrente)
                ultimoControllo = nil
            case UInt8(ascii: "c"):
                guard let x1 = lettore.numero(), let y1 = lettore.numero(), let x2 = lettore.numero(),
                      let y2 = lettore.numero(), let x = lettore.numero(), let y = lettore.numero() else { return p }
                let c1 = CGPoint(x: base.x + x1, y: base.y + y1)
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                corrente = CGPoint(x: base.x + x, y: base.y + y)
                p.addCurve(to: corrente, control1: c1, control2: c2)
                ultimoControllo = c2
            case UInt8(ascii: "s"):
                guard let x2 = lettore.numero(), let y2 = lettore.numero(),
                      let x = lettore.numero(), let y = lettore.numero() else { return p }
                // Il primo punto di controllo è il riflesso del secondo della curva prima
                let c1 = ultimoControllo.map { CGPoint(x: 2 * corrente.x - $0.x, y: 2 * corrente.y - $0.y) } ?? corrente
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                corrente = CGPoint(x: base.x + x, y: base.y + y)
                p.addCurve(to: corrente, control1: c1, control2: c2)
                ultimoControllo = c2
            case UInt8(ascii: "a"):
                guard let rx = lettore.numero(), let ry = lettore.numero(), lettore.numero() != nil,
                      let grande = lettore.numero(), let verso = lettore.numero(),
                      let x = lettore.numero(), let y = lettore.numero() else { return p }
                let fine = CGPoint(x: base.x + x, y: base.y + y)
                arco(&p, da: corrente, a: fine, raggio: max(abs(rx), abs(ry)), grande: grande != 0, verso: verso != 0)
                corrente = fine
                ultimoControllo = nil
            case UInt8(ascii: "z"):
                p.closeSubpath()
                corrente = inizio
                ultimoControllo = nil
            default:
                return p
            }
        }
        return p
    }

    /// Un arco circolare SVG (senza rotazione) dal punto corrente: centro ricavato dai due estremi, dal raggio e dalle
    /// due bandierine (SVG 1.1, F.6.5). `verso` = 1: angoli crescenti (in senso orario sullo schermo).
    private static func arco(_ p: inout Path, da a: CGPoint, a b: CGPoint, raggio: CGFloat, grande: Bool, verso: Bool) {
        guard raggio > 0, a != b else {
            p.addLine(to: b)
            return
        }
        let x1 = (a.x - b.x) / 2, y1 = (a.y - b.y) / 2
        var r = raggio
        let lambda = (x1 * x1 + y1 * y1) / (r * r)
        if lambda > 1 { r *= lambda.squareRoot() }
        let r2 = r * r
        let somma = x1 * x1 + y1 * y1
        let segno: CGFloat = grande != verso ? 1 : -1
        let quota = somma > 0 ? max(0, (r2 - somma) / somma).squareRoot() * segno : 0
        let centro = CGPoint(x: quota * y1 + (a.x + b.x) / 2, y: -quota * x1 + (a.y + b.y) / 2)
        let partenza = atan2(a.y - centro.y, a.x - centro.x)
        let arrivo = atan2(b.y - centro.y, b.x - centro.x)
        p.addArc(center: centro, radius: r, startAngle: .radians(Double(partenza)), endAngle: .radians(Double(arrivo)),
                 clockwise: !verso)
    }

    /// Lo scorrere dei caratteri: comandi e numeri (anche «.7», «-2.8», «2-2»).
    private struct Lettura {
        let byte: [UInt8]
        var i = 0

        init(_ byte: [UInt8]) { self.byte = byte }

        private static func separatore(_ c: UInt8) -> Bool {
            c == UInt8(ascii: " ") || c == UInt8(ascii: ",") || c == UInt8(ascii: "\n") || c == UInt8(ascii: "\t")
        }

        private static func lettera(_ c: UInt8) -> Bool {
            (c >= 65 && c <= 90) || (c >= 97 && c <= 122)
        }

        mutating func salta() {
            while i < byte.count, Self.separatore(byte[i]) { i += 1 }
        }

        /// Il comando che segue: una lettera, oppure (se segue un numero) lo stesso comando ripetuto.
        mutating func prossimoComando(precedente: UInt8) -> UInt8? {
            salta()
            guard i < byte.count else { return nil }
            let c = byte[i]
            if Self.lettera(c) {
                i += 1
                return c
            }
            // Coordinate in più dopo lo stesso comando (mai dopo Z)
            guard precedente != 0, precedente | 0x20 != UInt8(ascii: "z") else { return nil }
            return precedente
        }

        mutating func numero() -> CGFloat? {
            salta()
            guard i < byte.count else { return nil }
            let partenza = i
            if byte[i] == UInt8(ascii: "-") || byte[i] == UInt8(ascii: "+") { i += 1 }
            var punto = false
            while i < byte.count {
                let c = byte[i]
                if c >= 48 && c <= 57 {
                    i += 1
                } else if c == UInt8(ascii: "."), !punto {
                    punto = true
                    i += 1
                } else {
                    break
                }
            }
            guard i > partenza, let testo = String(bytes: byte[partenza..<i], encoding: .ascii), let v = Double(testo) else {
                return nil
            }
            return CGFloat(v)
        }
    }
}

/// Il glifo bianco a tratto, grande `lato` (il riquadro 24×24 scalato), con il tratto di 2 su 24 e i pezzi pieni.
struct GlifoLuceVista: View {
    let glifo: GlifoLuce
    let lato: CGFloat
    var colore: Color = Tema.Apple.Tassello.coloreGlifo

    var body: some View {
        let t = glifo.tracciati
        let scala = lato / 24
        let trasformazione = CGAffineTransform(scaleX: scala, y: scala)
        ZStack {
            t.pieni.applying(trasformazione).fill(colore)
            t.tutti.applying(trasformazione)
                .stroke(colore, style: StrokeStyle(lineWidth: lato * Tema.Apple.Tassello.trattoGlifo,
                                                   lineCap: .round, lineJoin: .round))
        }
        .frame(width: lato, height: lato)
        .accessibilityHidden(true)
    }
}

/// Il tassello di Luce: un quadrato arrotondato a tinta piena con il glifo bianco a metà del lato, il filo di luce in
/// alto e l'ombra sotto. `raggio` nil = 0,3 del lato (pannello Novità, `ic`); la Sala usa 14, il palco 10.
struct TasselloGlifo: View {
    let glifo: GlifoLuce
    var lato: CGFloat = Tema.Apple.Tassello.latoPredefinito
    var raggio: CGFloat? = nil
    /// Al posto della tinta del glifo (per gli stati spenti).
    var tinta: Color? = nil

    private typealias T = Tema.Apple.Tassello

    var body: some View {
        let r = raggio ?? (lato * T.quotaRaggio).rounded()
        let forma = RoundedRectangle(cornerRadius: r, style: .continuous)
        ZStack {
            forma.fill(tinta ?? glifo.colore)
                .shadow(color: T.ombra, radius: T.ombraRaggio, x: 0, y: T.ombraY)
            // Il filo di luce in alto (inset 0 1 0): la forma meno sé stessa spostata in basso
            FiloTassello(raggio: r, spessore: T.spessoreFilo)
                .fill(T.filoLuce, style: FillStyle(eoFill: true))
                .clipShape(forma)
            GlifoLuceVista(glifo: glifo, lato: (lato * T.quotaGlifo).rounded())
        }
        .frame(width: lato, height: lato)
        .accessibilityHidden(true)
    }
}

/// Il filo interno in alto del tassello.
private struct FiloTassello: Shape {
    let raggio: CGFloat
    let spessore: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = RoundedRectangle(cornerRadius: raggio, style: .continuous).path(in: rect)
        p.addPath(RoundedRectangle(cornerRadius: raggio, style: .continuous).path(in: rect.offsetBy(dx: 0, dy: spessore)))
        return p
    }
}

/// La tavola dei 29 glifi nei loro tasselli (istantanea `619-glifi-luce` e vetrina): per confrontarli con il template.
struct TavolaGlifiLuce: View {
    var lato: CGFloat = Tema.Apple.Tassello.latoSala
    var colonne = Tema.Apple.TavoleLuce.colonneGlifi

    private typealias T = Tema.Apple.TavoleLuce

    var body: some View {
        // Righe fisse (niente griglie pigre: nelle istantanee si disegna tutto subito)
        let tutti = GlifoLuce.allCases
        let righe = stride(from: 0, to: tutti.count, by: max(1, colonne)).map { Array(tutti[$0..<min($0 + max(1, colonne), tutti.count)]) }
        VStack(alignment: .leading, spacing: T.spazioRigheGlifi) {
            ForEach(Array(righe.enumerated()), id: \.offset) { _, riga in
                HStack(alignment: .top, spacing: T.spazioColonneGlifi) {
                    ForEach(riga) { g in
                        VStack(spacing: T.sottoTassello) {
                            TasselloGlifo(glifo: g, lato: lato)
                            Text(g.rawValue)
                                .carattereApple(Tema.Apple.Carattere.asse)
                                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                                .lineLimit(1)
                        }
                        .frame(width: lato + T.ariaColonnaGlifo)
                    }
                }
            }
        }
    }
}
