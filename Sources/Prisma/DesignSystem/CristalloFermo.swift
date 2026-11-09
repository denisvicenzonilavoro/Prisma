import SwiftUI
import simd

// Il cristallo della realtà aumentata disegnato in SwiftUI («Luce» giro 16, §2.3.3 e decisione 27): il fermo-immagine
// delle istantanee, il ripiego quando RealityKit non c'è (o Metal manca) e **lo scatto su fondo neutro**, che è sempre
// questo disegno e mai un'immagine della fotocamera (stesso risultato su Mac, iPad e iPhone). Il prisma triangolare
// arrotondato (`MotoreRealtaAumentata.pianta`) in assonometria: facce laterali più scure, faccia alta chiara con il logo,
// ombra colorata sotto. Niente Canvas né filtri: solo forme e gradienti (le istantanee li disegnano sempre).
// Più il foglio dello scatto per i Documenti del cliente (`FoglioScattoRealta`, A4 su carta bianca).

/// Il fondo dietro il cristallo fermo.
enum FondoCristallo: Equatable {
    /// Il fondo chiaro del palco del Mac.
    case palco
    /// La stanza calda sfocata con il tavolo di legno (schermo dell'iPad del palco, ripiego dell'iPhone e dell'iPad).
    case tavoloLegno
    /// Bianco: lo scatto per il dossier.
    case neutro
}

/// La proiezione del cristallo: punti del prisma (x, y, z in unità) sullo schermo.
struct ProiezioneCristallo {
    let centro: CGPoint
    let scala: CGFloat
    let rotazione: Double
    let schiacciamento: CGFloat

    func punto(_ x: Float, _ y: Float, _ z: Float) -> CGPoint {
        let c = cos(rotazione), s = sin(rotazione)
        let xr = Double(x) * c - Double(z) * s
        let zr = Double(x) * s + Double(z) * c
        return CGPoint(x: centro.x + scala * CGFloat(xr), y: centro.y - scala * CGFloat(y) + scala * schiacciamento * CGFloat(zr))
    }

    /// La profondità di una normale orizzontale dopo la rotazione (> 0: guarda verso chi osserva).
    func versoOsservatore(_ n: SIMD2<Float>) -> Double {
        Double(n.x) * sin(rotazione) + Double(n.y) * cos(rotazione)
    }
}

/// Un poligono chiuso da punti già proiettati.
struct PoligonoCristallo: Shape {
    let punti: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let primo = punti.first else { return p }
        p.move(to: primo)
        for q in punti.dropFirst() { p.addLine(to: q) }
        p.closeSubpath()
        return p
    }
}

/// Il cristallo fermo: strati, logo e ombra su uno dei tre fondi.
struct CristalloFermo: View {
    let esito: EsitoRealta
    var anno: Int?
    var esploso = false
    var scelto: String?
    var fondo: FondoCristallo = .palco

    private typealias F = Tema.Apple.RealtaAumentata.Fermo
    private typealias R = Tema.Apple.RealtaAumentata

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let proiezione = ProiezioneCristallo(centro: CGPoint(x: w * F.centro.x, y: h * F.centro.y),
                                                 scala: min(w, h) * F.quotaScala, rotazione: F.rotazione,
                                                 schiacciamento: F.schiacciamento)
            ZStack {
                sfondo(w: w, h: h)
                if !esito.vuota {
                    ombra(proiezione)
                    ForEach(Array(esito.strati.enumerated()), id: \.element.id) { i, s in
                        strato(i, s, proiezione)
                    }
                    logo(proiezione)
                }
            }
            .frame(width: w, height: h)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Il cristallo del patrimonio"))
    }

    @ViewBuilder
    private func sfondo(w: CGFloat, h: CGFloat) -> some View {
        switch fondo {
        case .palco:
            RadialGradient(colors: [R.Fondo.centro, R.Fondo.bordo], center: R.Fondo.punto, startRadius: 0,
                           endRadius: max(w, h) * 0.75)
        case .neutro:
            F.neutro
        case .tavoloLegno:
            ZStack(alignment: .top) {
                LinearGradient(colors: [F.stanzaAlto, F.stanzaBasso], startPoint: .top, endPoint: .bottom)
                ForEach(0..<F.quanteBolle, id: \.self) { i in
                    let x = w * (F.bollaX + F.bollaPassoX * CGFloat(i))
                    let y = h * (F.bollaY + F.bollaPassoY * CGFloat(i % 3))
                    let d = min(w, h) * (F.bollaLato + F.bollaPassoLato * CGFloat(i % 2))
                    Circle()
                        .fill(RadialGradient(colors: [F.bolle[i % F.bolle.count], .clear], center: .center,
                                             startRadius: 0, endRadius: d / 2))
                        .frame(width: d, height: d)
                        .position(x: x, y: y)
                }
                LinearGradient(colors: [R.Tavolo.legnoChiaro, R.Tavolo.legnoScuro], startPoint: .top, endPoint: .bottom)
                    .frame(height: h * (1 - F.orizzonte))
                    .offset(y: h * F.orizzonte)
            }
            .frame(width: w, height: h, alignment: .top)
            .clipped()
        }
    }

    private func colore(_ s: StratoRealta) -> Color { R.Strati.colore(s.classe) }

    private func opacita(_ s: StratoRealta) -> Double {
        guard let scelto, scelto != s.id else { return F.opacitaFacce }
        return F.opacitaFacce * R.Strato.opacitaAltri
    }

    private func strato(_ i: Int, _ s: StratoRealta, _ p: ProiezioneCristallo) -> some View {
        let e = MotoreRealtaAumentata.estremi(strato: i, bordi: esito.bordi, altezza: esito.altezza(anno: anno),
                                              esploso: esploso ? 1 : 0, crescita: 1)
        let anello = MotoreRealtaAumentata.piantaConNormali()
        let m = anello.count
        // Le facce che guardano chi osserva, dalla più lontana alla più vicina
        let facce: [(profondita: Double, punti: [CGPoint])] = (0..<m).compactMap { k in
            let j = (k + 1) % m
            let n = SIMD2<Float>((anello[k].normale.x + anello[j].normale.x) / 2, (anello[k].normale.y + anello[j].normale.y) / 2)
            let d = p.versoOsservatore(n)
            guard d > 0 else { return nil }
            let a = anello[k].punto, b = anello[j].punto
            return (d, [p.punto(a.x, e.basso, a.y), p.punto(b.x, e.basso, b.y), p.punto(b.x, e.alto, b.y), p.punto(a.x, e.alto, a.y)])
        }.sorted { $0.profondita < $1.profondita }
        let alto = anello.map { p.punto($0.punto.x, e.alto, $0.punto.y) }
        let tinta = colore(s)
        return ZStack {
            ForEach(Array(facce.enumerated()), id: \.offset) { _, f in
                PoligonoCristallo(punti: f.punti)
                    .fill(tinta.opacity(1 - F.scuroFacce * (1 - f.profondita)))
            }
            PoligonoCristallo(punti: alto)
                .fill(LinearGradient(colors: [Color.white.opacity(F.chiaroAlto), tinta], startPoint: .top, endPoint: .bottom))
            PoligonoCristallo(punti: alto).stroke(F.bordo, lineWidth: F.spessoreBordo)
        }
        .opacity(opacita(s))
    }

    /// Il logo inciso sulla faccia alta dell'ultimo strato presente.
    @ViewBuilder
    private func logo(_ p: ProiezioneCristallo) -> some View {
        let n = esito.strati.count
        if n > 0 {
            let e = MotoreRealtaAumentata.estremi(strato: n - 1, bordi: esito.bordi, altezza: esito.altezza(anno: anno),
                                                  esploso: esploso ? 1 : 0, crescita: 1)
            let centro = p.punto(0, e.alto, 0)
            let lato = p.scala * F.logo
            LogoPrisma(colore: F.coloreLogo)
                .frame(width: lato, height: lato)
                .scaleEffect(x: 1, y: p.schiacciamento * F.schiacciamentoLogo)
                .position(centro)
        }
    }

    /// L'ombra colorata ovale sul tavolo, spostata verso la luce.
    private func ombra(_ p: ProiezioneCristallo) -> some View {
        let s = Tema.Apple.RealtaAumentata.Ombra.spostamento
        let centro = p.punto(s.x, 0, s.y)
        let larghezza = p.scala * CGFloat(MotoreRealtaAumentata.raggio) * 2 * F.quotaOmbra
        let colori = esito.strati.map { colore($0).opacity(Tema.Apple.RealtaAumentata.Ombra.opacita) }
        return Ellipse()
            .fill(RadialGradient(colors: (colori.isEmpty ? [F.ombra] : colori) + [.clear], center: .center,
                                 startRadius: 0, endRadius: larghezza / 2))
            .frame(width: larghezza, height: larghezza * p.schiacciamento)
            .position(centro)
    }

    /// Il punto dello schermo sopra la faccia alta (per la targhetta), in una vista di misura `misura`.
    static func puntoTarghetta(_ esito: EsitoRealta, anno: Int?, esploso: Bool, misura: CGSize) -> CGPoint {
        let p = proiezione(misura)
        let n = esito.strati.count
        guard n > 0 else { return p.centro }
        let e = MotoreRealtaAumentata.estremi(strato: n - 1, bordi: esito.bordi, altezza: esito.altezza(anno: anno),
                                              esploso: esploso ? 1 : 0, crescita: 1)
        return p.punto(0, e.alto, -MotoreRealtaAumentata.raggio * F.quotaTarghetta)
    }

    /// Il punto accanto a ogni strato (per le pillole con «Esploso»).
    static func puntiStrati(_ esito: EsitoRealta, anno: Int?, esploso: Bool, misura: CGSize) -> [String: CGPoint] {
        let p = proiezione(misura)
        var punti: [String: CGPoint] = [:]
        for (i, s) in esito.strati.enumerated() {
            let e = MotoreRealtaAumentata.estremi(strato: i, bordi: esito.bordi, altezza: esito.altezza(anno: anno),
                                                  esploso: esploso ? 1 : 0, crescita: 1)
            punti[s.id] = p.punto(MotoreRealtaAumentata.raggio * F.quotaPillole, (e.basso + e.alto) / 2, 0)
        }
        return punti
    }

    private static func proiezione(_ misura: CGSize) -> ProiezioneCristallo {
        ProiezioneCristallo(centro: CGPoint(x: misura.width * F.centro.x, y: misura.height * F.centro.y),
                            scala: min(misura.width, misura.height) * F.quotaScala, rotazione: F.rotazione,
                            schiacciamento: F.schiacciamento)
    }

    /// Lo scatto su fondo neutro (decisione 27): il cristallo in un'immagine quadrata, mai la fotocamera.
    @MainActor
    static func scatto(_ esito: EsitoRealta, anno: Int?, esploso: Bool, lato: CGFloat = Tema.Apple.RealtaAumentata.Foglio.lato) -> CGImage? {
        let r = ImageRenderer(content: CristalloFermo(esito: esito, anno: anno, esploso: esploso, fondo: .neutro)
            .frame(width: lato, height: lato)
            .environment(\.colorScheme, .light))
        r.proposedSize = ProposedViewSize(width: lato, height: lato)
        r.scale = 1
        return r.immaginePrisma
    }
}

/// Il foglio dello scatto nei Documenti del cliente: A4 su carta bianca, il titolo, l'immagine, le classi con quota e
/// valore dell'anno, la nota (e la riga della stanza quando la foto la comprende).
struct FoglioScattoRealta: View {
    let cliente: String
    let anno: Int
    let immagine: CGImage
    let esito: EsitoRealta
    let annoEsito: Int?
    let conStanza: Bool

    private typealias G = Tema.Apple.RealtaAumentata.Foglio

    var body: some View {
        VStack(alignment: .leading, spacing: G.spazio) {
            Text(TestiRealta.titoloFoglio(cliente, anno: anno))
                .carattereApple(G.titolo)
                .foregroundStyle(G.inchiostro)
            Image(decorative: immagine, scale: 1)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: G.altezzaImmagine)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(esito.strati) { s in
                    HStack(spacing: G.spazioRiga) {
                        RoundedRectangle(cornerRadius: G.raggioQuadratino).fill(Tema.Apple.RealtaAumentata.Strati.colore(s.classe))
                            .frame(width: G.quadratino, height: G.quadratino)
                        Text(s.nome)
                        Spacer(minLength: G.spazioRiga)
                        Text(Formati.percentuale((s.quota * 100).rounded()))
                        Text(Formati.euro(esito.valore(s, anno: annoEsito)))
                            .frame(minWidth: G.larghezzaValore, alignment: .trailing)
                    }
                    .carattereApple(G.riga)
                    .foregroundStyle(G.inchiostro)
                    .padding(.vertical, G.paddingRiga)
                    .overlay(alignment: .bottom) { Rectangle().fill(G.filo).frame(height: 1) }
                }
            }
            if esito.stimata {
                Text(TestiRealta.stimata).carattereApple(G.nota).foregroundStyle(G.inchiostro2)
            }
            Spacer(minLength: 0)
            if conStanza {
                Text(TestiRealta.rigaStanza).carattereApple(G.nota).foregroundStyle(G.inchiostro2)
            }
            Text(TestiRealta.notaFoglio).carattereApple(G.nota).foregroundStyle(G.inchiostro2)
        }
        .padding(G.margine)
        .frame(width: G.formato.width, height: G.formato.height, alignment: .topLeading)
        .background(Tema.Apple.Carta.fondo)
        .environment(\.colorScheme, .light)
    }
}
