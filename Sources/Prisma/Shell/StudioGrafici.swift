import SwiftUI

// I due grafici nuovi del Cruscotto di Studio (Design/template-novita-specifica.md §2.2.4): le colonne impilate degli
// incassi per canale e la dispersione «il valore e il tempo». Non calcolano niente: disegnano le cifre di MotoreStudio.
// - Colonne: Alleanza sotto (`canaleAlleanza`), indipendente sopra (`canaleIndipendente` al 90%), 2 fra le parti,
//   raggi 6 fuori e 2 dentro (una parte sola: 6 dappertutto). Crescono dal basso (scala y 0 → 1, 0,8 s, curva
//   (.34, 1.3, .64, 1), ritardo 0,30 + i·0,055).
// - Dispersione: ore nell'anno (x) e ricavi (y), assi dal valore più alto arrotondato in su; i clienti in evidenza con
//   le iniziali (prima i preferiti, poi chi ha più ore, al più 5), gli altri pallini; la zona «molto tempo, poco
//   valore» oltre la mediana delle ore e sotto la mediana dei ricavi (`CruscottoStudio.ValoreTempo.criterio`). I punti
//   compaiono con la molla (0,5 s, ritardo 0,40 + min(i, 24)·0,025); un tocco apre il dossier del cliente.
// «Riduci movimento» e istantanee: colonne e punti subito alla misura.

// MARK: - Colonne impilate degli incassi

struct ColonneIncassiStudio: View {
    let mesi: [CruscottoStudio.MeseIncasso]

    var body: some View {
        let t = Tema.Apple.Studio.Incassi.self
        let massimo = mesi.map(\.totale).max() ?? 0
        return GeometryReader { geo in
            let piena = max(0, min(t.colonnaMassima, geo.size.height - t.altezzaMese - t.sottoColonna))
            HStack(alignment: .bottom, spacing: t.spazioColonne) {
                ForEach(Array(mesi.enumerated()), id: \.element.id) { i, m in
                    VStack(spacing: t.sottoColonna) {
                        ColonnaIncassoStudio(mese: m,
                                             altezza: massimo > 0 ? piena * CGFloat(m.totale / massimo) : 0,
                                             indice: i)
                        Text(TestiStudio.meseBreve(m.inizio))
                            .carattereApple(t.mese)
                            .foregroundColor(t.coloreMese)
                            .lineLimit(1)
                            .minimumScaleFactor(Tema.Apple.Studio.Card.riduzioneTesto)
                            .frame(height: t.altezzaMese)
                    }
                    .frame(maxWidth: .infinity)
                    .help(TestiStudio.mese(m))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
    }
}

/// Una colonna: le due parti dei canali, che crescono insieme dal basso.
private struct ColonnaIncassoStudio: View {
    let mese: CruscottoStudio.MeseIncasso
    let altezza: CGFloat
    let indice: Int

    @Environment(\.prismaStatoFinale) private var fermo
    /// Istantanee: lo stato finale è per sempre, niente da scrivere alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    @State private var cresciuta = false

    var body: some View {
        let t = Tema.Apple.Studio.Incassi.self
        let alleanza = max(0, mese.alleanza ?? 0)
        let indipendente = max(0, mese.indipendente)
        let totale = alleanza + indipendente
        let due = alleanza > 0 && indipendente > 0
        let utile = max(0, altezza - (due ? t.fraParti : 0))
        return VStack(spacing: t.fraParti) {
            if indipendente > 0 {
                FormaColonnaStudio(alto: t.raggioEsterno, basso: due ? t.raggioInterno : t.raggioEsterno)
                    .fill(t.coloreIndipendente)
                    .opacity(t.opacitaIndipendente)
                    .frame(height: totale > 0 ? utile * CGFloat(indipendente / totale) : 0)
            }
            if alleanza > 0 {
                FormaColonnaStudio(alto: due ? t.raggioInterno : t.raggioEsterno, basso: t.raggioEsterno)
                    .fill(t.coloreAlleanza)
                    .frame(height: totale > 0 ? utile * CGFloat(alleanza / totale) : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: altezza, alignment: .bottom)
        .scaleEffect(x: 1, y: (fermo || cresciuta) ? 1 : 0.001, anchor: .bottom)
        .onAppear(perform: cresci)
    }

    private func cresci() {
        guard !fermo else {
            if !scatto { cresciuta = true }
            return
        }
        guard !cresciuta else { return }
        let m = Tema.Apple.Studio.Moto.self
        withAnimation(m.animazioneColonne.ritardoPrisma(m.ritardoColonna(indice))) { cresciuta = true }
    }
}

/// Un rettangolo con i raggi degli angoli in alto e in basso diversi (macOS 13 non ha `UnevenRoundedRectangle`).
struct FormaColonnaStudio: Shape {
    let alto: CGFloat
    let basso: CGFloat

    func path(in r: CGRect) -> Path {
        guard r.width > 0, r.height > 0 else { return Path() }
        let metà = min(r.width, r.height) / 2
        let ra = min(alto, metà)
        let rb = min(basso, metà)
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + ra))
        p.addArc(center: CGPoint(x: r.minX + ra, y: r.minY + ra), radius: ra,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX - ra, y: r.minY))
        p.addArc(center: CGPoint(x: r.maxX - ra, y: r.minY + ra), radius: ra,
                 startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - rb))
        p.addArc(center: CGPoint(x: r.maxX - rb, y: r.maxY - rb), radius: rb,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: r.minX + rb, y: r.maxY))
        p.addArc(center: CGPoint(x: r.minX + rb, y: r.maxY - rb), radius: rb,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Dispersione «il valore e il tempo»

struct DispersioneClientiStudio: View {
    let valore: CruscottoStudio.ValoreTempo
    /// Apre il dossier del cliente (id).
    let apri: (String) -> Void

    var body: some View {
        let d = Tema.Apple.Studio.Dispersione.self
        let maxOre = Self.massimoOre(valore.punti)
        let maxRicavi = Self.massimoRicavi(valore.punti)
        let nomi = Self.inEvidenza(valore.punti)
        // Cascata: prima i clienti con le iniziali, poi gli altri; nel disegno gli altri stanno sotto
        let conNome = valore.punti.filter { nomi.contains($0.id) }
        let senzaNome = valore.punti.filter { !nomi.contains($0.id) }
        return VStack(spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack(alignment: .topLeading) {
                    zona(larghezza: w, altezza: h, maxOre: maxOre, maxRicavi: maxRicavi)
                    ForEach(Array(senzaNome.enumerated()), id: \.element.id) { i, p in
                        PuntoClienteStudio(punto: p, conNome: false, indice: conNome.count + i) { apri(p.cliente.id) }
                            .position(Self.posizione(p, lato: d.punto, w: w, h: h, maxOre: maxOre, maxRicavi: maxRicavi))
                    }
                    ForEach(Array(conNome.enumerated()), id: \.element.id) { i, p in
                        PuntoClienteStudio(punto: p, conNome: true, indice: i) { apri(p.cliente.id) }
                            .position(Self.posizione(p, lato: d.puntoNome, w: w, h: h, maxOre: maxOre, maxRicavi: maxRicavi))
                    }
                }
                .frame(width: w, height: h, alignment: .topLeading)
            }
            HStack(alignment: .lastTextBaseline) {
                Text("0 ore")
                Spacer(minLength: 0)
                Text("\(FormatoCifra.migliaia(maxOre)) ore l’anno")
            }
            .carattereApple(d.asse)
            .foregroundColor(d.coloreAsse)
            .lineLimit(1)
            .frame(height: d.margineAssi, alignment: .bottom)
        }
    }

    /// La zona «molto tempo, poco valore»: oltre la mediana delle ore e sotto la mediana dei ricavi.
    @ViewBuilder private func zona(larghezza w: CGFloat, altezza h: CGFloat, maxOre: Double, maxRicavi: Double) -> some View {
        let d = Tema.Apple.Studio.Dispersione.self
        if let so = valore.sogliaOre, let sr = valore.sogliaRicavi, maxOre > 0, maxRicavi > 0 {
            let x0 = min(w, max(0, CGFloat(so / maxOre) * w))
            let y0 = min(h, max(0, h - CGFloat(sr / maxRicavi) * h))
            let larga = w - x0
            let alta = h - y0
            if larga > 0, alta > 0 {
                RoundedRectangle(cornerRadius: d.raggioZona, style: .continuous)
                    .fill(d.zona)
                    .frame(width: larga, height: alta)
                    .position(x: x0 + larga / 2, y: y0 + alta / 2)
                Text(TestiStudio.zona)
                    .carattereApple(d.scrittaZona)
                    .foregroundColor(d.coloreScrittaZona)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: max(0, larga - 2 * d.margineScritta), alignment: .trailing)
                    .position(x: x0 + larga / 2, y: h - d.margineScritta - d.scrittaZona.dimensione / 2)
                    .help(CruscottoStudio.ValoreTempo.criterio)
            }
        }
    }

    /// Dove sta il punto: x sulle ore, y sui ricavi (in alto i più alti), sempre dentro il grafico.
    private static func posizione(_ p: CruscottoStudio.PuntoCliente, lato: CGFloat, w: CGFloat, h: CGFloat,
                                  maxOre: Double, maxRicavi: Double) -> CGPoint {
        let fx = maxOre > 0 ? CGFloat(min(max(p.ore / maxOre, 0), 1)) : 0
        let fy = maxRicavi > 0 ? CGFloat(min(max(p.ricavi / maxRicavi, 0), 1)) : 0
        let metà = lato / 2
        let x = min(max(fx * w, metà), max(metà, w - metà))
        let y = min(max(h - fy * h, metà), max(metà, h - metà))
        return CGPoint(x: x, y: y)
    }

    /// L'asse delle ore: il valore più alto arrotondato al multiplo di 5 sopra (almeno 5).
    static func massimoOre(_ punti: [CruscottoStudio.PuntoCliente]) -> Double {
        let passo = Tema.Apple.Studio.Dispersione.passoOre
        let alto = punti.map(\.ore).max() ?? 0
        return max(passo, (alto / passo).rounded(.up) * passo)
    }

    /// L'asse dei ricavi: il valore più alto con un po' di margine, arrotondato a una cifra «tonda» (0 se nessuno
    /// ha ricavi: i punti stanno tutti in basso).
    static func massimoRicavi(_ punti: [CruscottoStudio.PuntoCliente]) -> Double {
        let alto = (punti.map(\.ricavi).max() ?? 0) * Tema.Apple.Studio.Dispersione.margineRicavi
        guard alto > 0, alto.isFinite else { return 0 }
        let grandezza = pow(10, (log10(alto)).rounded(.down))
        let mezzi = grandezza / 2
        return (alto / mezzi).rounded(.up) * mezzi
    }

    /// I clienti con le iniziali: prima i preferiti, poi chi ha più ore (l'ordine dei punti), al più 5.
    static func inEvidenza(_ punti: [CruscottoStudio.PuntoCliente]) -> Set<String> {
        let massimo = Tema.Apple.Studio.Dispersione.massimoNomi
        let preferiti = punti.filter(\.cliente.preferito)
        let altri = punti.filter { !$0.cliente.preferito }
        return Set((preferiti + altri).prefix(massimo).map(\.id))
    }
}

/// Un punto della dispersione: il cerchio con le iniziali (in evidenza) o il pallino; compare con la molla, un tocco
/// apre il dossier, il fumetto dice nome, ore e ricavi.
private struct PuntoClienteStudio: View {
    let punto: CruscottoStudio.PuntoCliente
    let conNome: Bool
    let indice: Int
    let apri: () -> Void

    @Environment(\.prismaStatoFinale) private var fermo
    @Environment(\.prismaScatto) private var scatto
    @State private var comparso = false

    var body: some View {
        let d = Tema.Apple.Studio.Dispersione.self
        let lato = conNome ? d.puntoNome : d.punto
        return Group {
            if conNome {
                AvatarCliente(iniziali: punto.cliente.iniziali, tinta: punto.cliente.tinta.colori, lato: lato)
                    .shadow(color: d.ombraNome, radius: d.raggioOmbraNome, x: 0, y: d.yOmbraNome)
            } else {
                Circle()
                    .fill(d.colorePunto)
                    .opacity(d.opacitaPunto)
            }
        }
        .frame(width: lato, height: lato)
        .contentShape(Circle())
        .scaleEffect((fermo || comparso) ? 1 : 0.001)
        .onTapGesture(perform: apri)
        .help(TestiStudio.punto(punto))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(TestiStudio.punto(punto)))
        .accessibilityAddTraits(.isButton)
        .onAppear(perform: compari)
    }

    private func compari() {
        guard !fermo else {
            if !scatto { comparso = true }
            return
        }
        guard !comparso else { return }
        let m = Tema.Apple.Studio.Moto.self
        withAnimation(m.animazionePunti.ritardoPrisma(m.ritardoPunto(indice))) { comparso = true }
    }
}
