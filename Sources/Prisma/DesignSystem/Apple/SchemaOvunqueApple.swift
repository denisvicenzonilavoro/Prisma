import SwiftUI

// Prisma ovunque (Design/template-novita-specifica.md §13.2-13.3, giro 8): i pezzi disegnati della pagina
// Impostazioni › iPhone e iPad.
//
//      ┌──────┐   · ─ ─ ● ─ ─ ·      ☁︎🔒     · ─ ─ ● ─ ─ ·    ┌──┐
//      │ Mac  │  ●              ●             ●            ●   │  │
//      └──────┘                                                └──┘
//      Il tuo Mac            iCloud Drive                iPhone e iPad
//                         solo un file cifrato
//
// - `SchemaOvunqueApple`: il disegno 670×170 (coordinate del template, scala con la larghezza), con i quattro pallini
//   verdi che corrono sugli archi tratteggiati, uno in andata e uno in ritorno per arco, a velocità costante (2,4 s a
//   giro, 0,8 s mentre si sincronizza: la fase è continua, la velocità cambia senza salti). Niente Timer:
//   `TimelineView(.animation)`, in pausa quando la finestra non si vede.
//   «Riduci movimento»: pallini fermi a metà di ciascun arco. Istantanee: andata al 25%, ritorno al 75%.
// - `PillolaSenzaMacApple`: «Senza Mac · copia cifrata», arancio, nella barra di iPhone e iPad e nel telefono d'esempio.
// - `TelefonoEsempioOvunque`: il telefono d'esempio (300×620 ridotto a 0,86), con lo schermo sempre chiaro.
// Valori in Tema.Apple+Ovunque.swift.

// MARK: - Archi

/// Una bézier cubica misurata: un punto a una frazione della LUNGHEZZA (non del parametro), per la velocità costante.
struct ArcoOvunque {
    let p0: CGPoint
    let p1: CGPoint
    let p2: CGPoint
    let p3: CGPoint
    private let punti: [CGPoint]
    private let lunghezze: [CGFloat]

    init(_ p: (CGPoint, CGPoint, CGPoint, CGPoint), campioni: Int = Tema.Apple.Ovunque.Schema.campioniArco) {
        p0 = p.0
        p1 = p.1
        p2 = p.2
        p3 = p.3
        let n = max(2, campioni)
        var elenco: [CGPoint] = []
        var cumulate: [CGFloat] = []
        var totale: CGFloat = 0
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let q = ArcoOvunque.bezier(t, p.0, p.1, p.2, p.3)
            if let ultimo = elenco.last { totale += hypot(q.x - ultimo.x, q.y - ultimo.y) }
            elenco.append(q)
            cumulate.append(totale)
        }
        punti = elenco
        lunghezze = cumulate
    }

    static func bezier(_ t: CGFloat, _ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> CGPoint {
        let u = 1 - t
        let x = u * u * u * a.x + 3 * u * u * t * b.x + 3 * u * t * t * c.x + t * t * t * d.x
        let y = u * u * u * a.y + 3 * u * u * t * b.y + 3 * u * t * t * c.y + t * t * t * d.y
        return CGPoint(x: x, y: y)
    }

    /// Il punto a `frazione` (0…1) della lunghezza.
    func punto(_ frazione: Double) -> CGPoint {
        guard let totale = lunghezze.last, totale > 0, punti.count > 1 else { return p0 }
        let obiettivo = CGFloat(min(max(frazione, 0), 1)) * totale
        var basso = 0
        var alto = lunghezze.count - 1
        while alto - basso > 1 {
            let mezzo = (basso + alto) / 2
            if lunghezze[mezzo] < obiettivo { basso = mezzo } else { alto = mezzo }
        }
        let tratto = lunghezze[alto] - lunghezze[basso]
        let f = tratto > 0 ? (obiettivo - lunghezze[basso]) / tratto : 0
        let a = punti[basso]
        let b = punti[alto]
        return CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
    }

    var percorso: Path {
        var p = Path()
        p.move(to: p0)
        p.addCurve(to: p3, control1: p1, control2: p2)
        return p
    }

    static let macNuvola = ArcoOvunque(Tema.Apple.Ovunque.Schema.arcoMacNuvola)
    static let nuvolaTelefono = ArcoOvunque(Tema.Apple.Ovunque.Schema.arcoNuvolaTelefono)
}

// MARK: - Schema

/// Come si muove lo schema: i pallini corrono (`attivo`), corrono veloci (`veloce`, si sincronizza), sono grigi
/// (`spento`), la nuvola è grigia (`nuvolaSpenta`, iCloud Drive non risponde). `rimbalzo` cresce a ogni fine
/// sincronizzazione: il lucchetto fa un piccolo rimbalzo.
struct AspettoSchemaOvunque: Equatable {
    var attivo = true
    var veloce = false
    var spento = false
    var nuvolaSpenta = false
    var rimbalzo = 0
    /// La finestra non si vede (coperta, Prisma bloccato): i pallini si fermano dove sono.
    var inPausa = false
}

struct SchemaOvunqueApple: View {
    let aspetto: AspettoSchemaOvunque
    /// La scritta sotto il telefono («iPhone e iPad»).
    var nomeTelefono = "iPhone e iPad"

    private typealias S = Tema.Apple.Ovunque.Schema

    init(aspetto: AspettoSchemaOvunque, nomeTelefono: String = "iPhone e iPad") {
        self.aspetto = aspetto
        self.nomeTelefono = nomeTelefono
    }

    var body: some View {
        GeometryReader { g in
            let scala = min(1, g.size.width / S.larghezza)
            disegno
                .frame(width: S.larghezza, height: S.altezza)
                .scaleEffect(scala, anchor: .topLeading)
        }
        .aspectRatio(S.larghezza / S.altezza, contentMode: .fit)
        .frame(maxWidth: S.larghezza)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Il tuo Mac, iCloud Drive con solo un file cifrato, \(nomeTelefono)"))
    }

    private var disegno: some View {
        ZStack(alignment: .topLeading) {
            archi
            mac
            NuvolaOvunque(spenta: aspetto.nuvolaSpenta, rimbalzo: aspetto.rimbalzo)
            telefono
            PalliniOvunque(aspetto: aspetto)
        }
        .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
    }

    private var archi: some View {
        let stile = StrokeStyle(lineWidth: S.spessoreArco, lineCap: .butt, dash: S.tratteggio)
        return ZStack {
            ArcoOvunque.macNuvola.percorso.stroke(S.coloreArco, style: stile)
            ArcoOvunque.nuvolaTelefono.percorso.stroke(S.coloreArco, style: stile)
        }
        .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
    }

    private var mac: some View {
        let o = S.origineMac
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: S.raggioSchermoMac, style: .continuous)
                .stroke(S.colore, lineWidth: S.spessore)
                .frame(width: S.schermoMac.width, height: S.schermoMac.height)
                .position(x: o.x + S.schermoMac.midX, y: o.y + S.schermoMac.midY)
            RoundedRectangle(cornerRadius: S.raggioBaseMac, style: .continuous)
                .fill(S.colore)
                .frame(width: S.baseMac.width, height: S.baseMac.height)
                .position(x: o.x + S.baseMac.midX, y: o.y + S.baseMac.midY)
            ScrittaSchema(testo: "Il tuo Mac", punto: CGPoint(x: o.x + S.etichettaMac.x, y: o.y + S.etichettaMac.y))
        }
        .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
    }

    private var telefono: some View {
        let o = S.origineTelefono
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: S.raggioTelefono, style: .continuous)
                .stroke(S.colore, lineWidth: S.spessore)
                .frame(width: S.corpoTelefono.width, height: S.corpoTelefono.height)
                .position(x: o.x + S.corpoTelefono.midX, y: o.y + S.corpoTelefono.midY)
            RoundedRectangle(cornerRadius: S.raggioAltoparlante, style: .continuous)
                .fill(S.colore)
                .frame(width: S.altoparlante.width, height: S.altoparlante.height)
                .position(x: o.x + S.altoparlante.midX, y: o.y + S.altoparlante.midY)
            ScrittaSchema(testo: nomeTelefono, punto: CGPoint(x: o.x + S.etichettaTelefono.x, y: o.y + S.etichettaTelefono.y))
        }
        .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
    }
}

/// Una scritta dello schema centrata su un punto di base (come `text-anchor: middle` dell'SVG).
private struct ScrittaSchema: View {
    let testo: String
    let punto: CGPoint
    var piccola = false

    private typealias S = Tema.Apple.Ovunque.Schema

    var body: some View {
        Text(testo)
            .carattereApple(piccola ? S.sottoEtichetta : S.etichetta)
            .foregroundColor(piccola ? S.coloreSottoEtichetta : S.colore)
            .lineLimit(1)
            .fixedSize()
            .position(x: punto.x, y: punto.y - (piccola ? S.alzataSottoEtichetta : S.alzataEtichetta))
    }
}

/// La nuvola blu con il lucchetto pieno; grigia quando iCloud Drive non risponde. A fine sincronizzazione il
/// lucchetto rimbalza (scala da 0,3 a 1 con la molla), mai con «Riduci movimento» e nelle istantanee.
private struct NuvolaOvunque: View {
    let spenta: Bool
    let rimbalzo: Int

    @Environment(\.prismaStatoFinale) private var fermo
    @State private var scala: CGFloat = 1

    private typealias S = Tema.Apple.Ovunque.Schema

    var body: some View {
        let o = S.origineNuvola
        let colore = spenta ? S.bluSpento : S.blu
        ZStack(alignment: .topLeading) {
            FormaNuvola()
                .stroke(colore, style: StrokeStyle(lineWidth: S.spessore, lineJoin: .round))
                .frame(width: S.larghezza, height: S.altezza)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: S.raggioLucchetto, style: .continuous)
                    .fill(colore)
                    .frame(width: S.corpoLucchetto.width, height: S.corpoLucchetto.height)
                    .position(x: o.x + S.corpoLucchetto.midX, y: o.y + S.corpoLucchetto.midY)
                ArcoLucchetto()
                    .stroke(colore, style: StrokeStyle(lineWidth: S.spessore, lineCap: .butt))
                    .frame(width: S.larghezza, height: S.altezza)
            }
            .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
            .scaleEffect(scala, anchor: UnitPoint(x: (o.x + S.corpoLucchetto.midX) / S.larghezza,
                                                  y: (o.y + S.corpoLucchetto.minY) / S.altezza))
            ScrittaSchema(testo: "iCloud Drive", punto: CGPoint(x: o.x + S.etichettaNuvola.x, y: o.y + S.etichettaNuvola.y))
            ScrittaSchema(testo: "solo un file cifrato", punto: CGPoint(x: o.x + S.sottoNuvola.x, y: o.y + S.sottoNuvola.y),
                          piccola: true)
        }
        .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
        .onChange(of: rimbalzo) { _ in
            guard !fermo else { return }
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { scala = Tema.Apple.Ovunque.Moto.scalaRimbalzo }
            DispatchQueue.main.async {
                withAnimation(Tema.Apple.Ovunque.Moto.rimbalzo) { scala = 1 }
            }
        }
    }
}

/// Il contorno della nuvola del template (`M20 58h62a20 20 0 0 0 0-40 28 28 0 0 0-54-4 22 22 0 0 0-8 44z`), con gli
/// archi SVG già risolti in centro e angoli. Coordinate del disegno 670×170 (la nuvola sta a 285,40).
private struct FormaNuvola: Shape {
    func path(in rect: CGRect) -> Path {
        typealias S = Tema.Apple.Ovunque.Schema
        let o = S.origineNuvola
        func q(_ p: CGPoint) -> CGPoint { CGPoint(x: o.x + p.x, y: o.y + p.y) }
        var p = Path()
        p.move(to: q(S.nuvolaInizio))
        p.addLine(to: q(S.nuvolaFondo))
        var da = S.nuvolaFondo
        // Gli archi SVG con sweep 0: angolo che scende (nelle coordinate con la y in giù), `clockwise: true` per SwiftUI
        for arco in [S.nuvolaDestra, S.nuvolaAlto, S.nuvolaSinistra] {
            let c = arco.centro
            let raggio = hypot(da.x - c.x, da.y - c.y)
            let inizio = atan2(Double(da.y - c.y), Double(da.x - c.x))
            var fine = atan2(Double(arco.arrivo.y - c.y), Double(arco.arrivo.x - c.x))
            // L'angolo scende: la fine sta sotto l'inizio
            while fine > inizio { fine -= 2 * Double.pi }
            p.addArc(center: q(c), radius: raggio, startAngle: .radians(inizio), endAngle: .radians(fine), clockwise: true)
            da = arco.arrivo
        }
        p.closeSubpath()
        return p
    }
}

/// L'arco del lucchetto (`M45 28 v-5 a6 6 0 0 1 12 0 v5`): sale, gira sopra il centro (51,23), riscende.
private struct ArcoLucchetto: Shape {
    func path(in rect: CGRect) -> Path {
        typealias S = Tema.Apple.Ovunque.Schema
        let o = S.origineNuvola
        let c = CGPoint(x: o.x + S.centroArcoLucchetto.x, y: o.y + S.centroArcoLucchetto.y)
        let r = S.raggioArcoLucchetto
        var p = Path()
        p.move(to: CGPoint(x: c.x - r, y: o.y + S.baseArcoLucchetto))
        p.addLine(to: CGPoint(x: c.x - r, y: c.y))
        // Sweep 1: l'angolo sale da 180° a 360° passando da 270° (in alto, con la y in giù): `clockwise: false`
        p.addArc(center: c, radius: r, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        p.addLine(to: CGPoint(x: c.x + r, y: o.y + S.baseArcoLucchetto))
        return p
    }
}

// MARK: - Pallini

/// I quattro pallini: Mac→iCloud e iCloud→iPhone in andata, iCloud→Mac e iPhone→iCloud in ritorno, con le partenze
/// sfalsate del template. La fase si conta in giri dalla `ancora`: quando cambia la velocità, l'ancora si sposta
/// all'istante del cambio con la fase raggiunta, così i pallini non saltano.
private struct PalliniOvunque: View {
    let aspetto: AspettoSchemaOvunque

    @Environment(\.prismaStatoFinale) private var finale
    @Environment(\.prismaScatto) private var scatto
    @State private var ancoraData = Date()
    @State private var ancoraFase: Double = 0
    @State private var periodo = Tema.Apple.Ovunque.Moto.giro

    private typealias S = Tema.Apple.Ovunque.Schema
    private typealias M = Tema.Apple.Ovunque.Moto

    var body: some View {
        Group {
            if finale || !aspetto.attivo {
                // Istantanee e copia ferma: andata al 25%, ritorno al 75%; «Riduci movimento»: a metà dell'arco
                let calmo = finale && !scatto && aspetto.attivo
                fermi(andata: calmo ? S.fermoCalmo : S.fermoAndata, ritorno: calmo ? S.fermoCalmo : S.fermoRitorno)
            } else {
                TimelineView(.animation(minimumInterval: 1 / M.fotogrammi, paused: aspetto.inPausa)) { contesto in
                    let fase = ancoraFase + contesto.date.timeIntervalSince(ancoraData) / periodo
                    inMoto(fase)
                }
            }
        }
        .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
        .allowsHitTesting(false)
        .onAppear {
            periodo = aspetto.veloce ? M.giroVeloce : M.giro
            ancoraData = Date()
        }
        .onChange(of: aspetto.veloce) { veloce in
            let adesso = Date()
            ancoraFase += adesso.timeIntervalSince(ancoraData) / periodo
            ancoraData = adesso
            periodo = veloce ? M.giroVeloce : M.giro
        }
    }

    private var colore: Color { aspetto.spento ? S.colorePallinoSpento : S.colorePallino }

    private func fermi(andata: Double, ritorno: Double) -> some View {
        ZStack(alignment: .topLeading) {
            pallino(ArcoOvunque.macNuvola.punto(andata))
            pallino(ArcoOvunque.nuvolaTelefono.punto(andata))
            pallino(ArcoOvunque.macNuvola.punto(ritorno))
            pallino(ArcoOvunque.nuvolaTelefono.punto(ritorno))
        }
        .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
    }

    private func inMoto(_ fase: Double) -> some View {
        let scarti = M.partenze.map { $0 / M.giro }
        func avanzamento(_ i: Int) -> Double {
            let x = fase - (i < scarti.count ? scarti[i] : 0)
            return x - x.rounded(.down)
        }
        return ZStack(alignment: .topLeading) {
            pallino(ArcoOvunque.macNuvola.punto(avanzamento(0)))
            pallino(ArcoOvunque.nuvolaTelefono.punto(avanzamento(1)))
            pallino(ArcoOvunque.macNuvola.punto(1 - avanzamento(2)))
            pallino(ArcoOvunque.nuvolaTelefono.punto(1 - avanzamento(3)))
        }
        .frame(width: S.larghezza, height: S.altezza, alignment: .topLeading)
    }

    private func pallino(_ p: CGPoint) -> some View {
        Circle()
            .fill(colore)
            .frame(width: S.pallino * 2, height: S.pallino * 2)
            .position(p)
    }
}

// MARK: - Pillola «Senza Mac»

/// «Senza Mac · copia cifrata»: capsula arancio al 16% con il testo `#B45309`. `barra`: la versione della barra di
/// iPhone e iPad, un filo più grande; `compatta`: solo «Senza Mac» (iPhone, dove la barra è stretta).
struct PillolaSenzaMacApple: View {
    var barra = false
    var compatta = false

    private typealias P = Tema.Apple.Ovunque.Pillola

    init(barra: Bool = false, compatta: Bool = false) {
        self.barra = barra
        self.compatta = compatta
    }

    var body: some View {
        Text(compatta ? TestiOvunque.pillolaCompatta : TestiOvunque.pillola)
            .carattereApple(barra ? P.carattereBarra : P.carattere)
            .foregroundColor(P.testo)
            .lineLimit(1)
            .fixedSize()
            .padding(barra ? P.paddingBarra : P.padding)
            .background(Capsule(style: .continuous).fill(P.fondo))
            .accessibilityLabel(Text(TestiOvunque.pillola))
    }
}

// MARK: - Telefono d'esempio

/// Cosa mostra il telefono d'esempio: il cliente dell'ultima modifica in attesa (o uno dei clienti di prova), il suo
/// patrimonio netto, due aree di Analisi 360, la nota nuova e quante modifiche si uniranno al Mac.
struct EsempioTelefonoOvunque: Equatable {
    struct Area: Equatable {
        let nome: String
        let valore: String
    }

    var nome: String
    var sottotitolo: String?
    var patrimonio: String
    var aree: [Area]
    var titoloNota: String
    var nota: String?
    var piede: String
}

/// Il telefono d'esempio del template: cornice scura ridotta a 0,86, schermo sempre chiaro (anche nell'aspetto
/// scuro), la pillola «Senza Mac · copia cifrata». Non è interattivo.
struct TelefonoEsempioOvunque: View {
    let esempio: EsempioTelefonoOvunque

    private typealias T = Tema.Apple.Ovunque.Telefono

    var body: some View {
        corpo
            .frame(width: T.larghezza, height: T.altezza)
            .scaleEffect(T.scala, anchor: .topLeading)
            .frame(width: T.larghezza * T.scala, height: T.altezza * T.scala, alignment: .topLeading)
            .environment(\.colorScheme, .light)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
    }

    private var corpo: some View {
        let cornice = RoundedRectangle(cornerRadius: T.raggio, style: .continuous)
        let schermo = RoundedRectangle(cornerRadius: T.raggioSchermo, style: .continuous)
        return ZStack(alignment: .top) {
            cornice
                .fill(T.corpo)
                .shadow(color: T.ombra, radius: T.ombraRaggio, x: 0, y: T.ombraY)
            cornice.strokeBorder(T.filo, lineWidth: T.spessoreFilo)
            contenuto
                .padding(T.paddingSchermo)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(LinearGradient(colors: T.schermo, startPoint: T.inizioSchermo, endPoint: T.fineSchermo))
                .clipShape(schermo)
                .padding(T.rientro)
            RoundedRectangle(cornerRadius: T.raggioIsola, style: .continuous)
                .fill(T.coloreIsola)
                .frame(width: T.isola.width, height: T.isola.height)
                .padding(.top, T.isolaDallAlto)
        }
    }

    private var contenuto: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(T.oraFinta)
                    .carattereApple(T.stato)
                    .foregroundColor(T.testo)
                Spacer(minLength: 0)
                PillolaSenzaMacApple()
            }
            Text(esempio.nome)
                .carattereApple(T.nome)
                .foregroundColor(T.testo)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, T.sopraNome)
            if let s = esempio.sottotitolo {
                Text(s)
                    .carattereApple(T.sottoNome)
                    .foregroundColor(T.testo2)
                    .lineLimit(1)
            }
            VStack(alignment: .leading, spacing: T.fraEtichettaValore) {
                Text("Patrimonio netto")
                    .carattereApple(T.etichettaTessera)
                    .foregroundColor(T.testo2)
                Text(esempio.patrimonio)
                    .carattereApple(T.cifra)
                    .foregroundColor(T.testo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(T.paddingTessera)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: T.raggioTessera, style: .continuous)
                    .fill(T.tessera)
                    .shadow(color: T.ombraTessera, radius: T.ombraTesseraRaggio, x: 0, y: T.ombraTesseraY)
            )
            .padding(.top, T.sopraTessera)
            HStack(spacing: T.spazioAffiancate) {
                ForEach(Array(esempio.aree.prefix(2).enumerated()), id: \.offset) { i, a in
                    VStack(alignment: .leading, spacing: T.fraEtichettaValore) {
                        Text(a.nome)
                            .carattereApple(T.etichettaPiccola)
                            .foregroundColor(T.testo2)
                            .lineLimit(1)
                        Text(a.valore)
                            .carattereApple(T.valorePiccola)
                            .foregroundColor(i == 0 ? T.coloreArea1 : T.coloreArea2)
                            .lineLimit(1)
                    }
                    .padding(T.paddingPiccola)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: T.raggioPiccola, style: .continuous).fill(T.tessera))
                }
            }
            .padding(.top, T.sopraAffiancate)
            if let nota = esempio.nota {
                (Text(esempio.titoloNota).bold() + Text(" · ") + Text(nota))
                    .carattereApple(T.nota)
                    .foregroundColor(T.testo)
                    .lineLimit(3)
                    .padding(T.paddingPiccola)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: T.raggioPiccola, style: .continuous).fill(T.tessera))
                    .padding(.top, T.sopraNota)
            }
            Text(esempio.piede)
                .carattereApple(T.piede)
                .foregroundColor(T.testo2)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, T.sopraPiede)
        }
    }
}
