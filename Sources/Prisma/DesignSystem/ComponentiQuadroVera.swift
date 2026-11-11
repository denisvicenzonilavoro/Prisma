import SwiftUI

// MARK: - Il quadro visivo di Vera
// Sotto una risposta di Vera: barre che crescono una dopo l'altra, cifre che contano fino al valore, la linea
// del tempo delle scadenze con le aste che salgono. Le cifre le calcola Prisma (Vera/QuadroVera.swift), mai Qwen.
// Con «Riduci movimento» e nelle istantanee tutto è già al suo posto, fermo.
// LineaTempoVista e CrescitaMiniVera vengono dalla mini Vera (Shell/VistaMiniVera.swift), che le usa ancora.

/// Una cifra che conta da zero fino al valore (o dal valore di prima a quello nuovo).
struct CifraContata: View {
    let valore: Double
    var formato: (Double) -> String = { Formati.euro($0) }
    /// Aspetta tanto prima di contare (le barre crescono una dopo l'altra).
    var ritardo: Double = 0
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea
    @State private var mostrato: Double?

    init(valore: Double, formato: @escaping (Double) -> String = { Formati.euro($0) }, ritardo: Double = 0) {
        self.valore = valore
        self.formato = formato
        self.ritardo = ritardo
    }

    var body: some View {
        let fermo = movimentoRidotto || modoIstantanea
        EmptyView()
            .modifier(ConteggioCifra(valore: fermo ? valore : (mostrato ?? 0), formato: formato))
            .onAppear {
                guard !fermo, mostrato == nil else { return }
                withAnimation(Tema.Moto.VeraScrivania.conteggio.ritardoPrisma(ritardo)) { mostrato = valore }
            }
            .onChange(of: valore) { nuovo in
                guard !fermo else { return }
                withAnimation(Tema.Moto.VeraScrivania.conteggio) { mostrato = nuovo }
            }
            .accessibilityLabel(formato(valore))
    }
}

/// Il testo della cifra mentre conta: SwiftUI interpola il valore, il testo si riscrive a ogni fotogramma.
private struct ConteggioCifra: ViewModifier, Animatable {
    var valore: Double
    let formato: (Double) -> String

    var animatableData: Double {
        get { valore }
        set { valore = newValue }
    }

    func body(content: Content) -> some View {
        Text(formato(valore)).monospacedDigit()
    }
}

/// La scheda dei calcoli sotto la risposta (modello grafico fisso del template, §4.7): le barre o la linea del tempo,
/// poi la fonte. Le cifre le calcola Prisma; con «Riduci movimento» e nelle istantanee è già tutta al suo posto.
struct QuadroVisivoVera: View {
    let quadro: QuadroVera

    var body: some View {
        let s = Tema.Apple.Vera.SchedaCalcoli.self
        VStack(alignment: .leading, spacing: 0) {
            switch quadro.forma {
            case .linea(let l):
                LineaTempoVista(linea: l)
            case .barre(let barre):
                BarreQuadroVera(titolo: quadro.titolo, totale: quadro.totale, barre: barre)
            }
            HStack(spacing: s.spazioFonte) {
                Image(systemName: s.simboloFonte)
                Text(quadro.fonte).lineLimit(1)
            }
            .carattereApple(s.fonte)
            .foregroundColor(s.coloreFonte)
            .padding(.top, s.sopraFonte)
        }
        .frame(maxWidth: s.larghezzaMassima, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Le aree o i canali come barre da 8 che si riempiono una dopo l'altra (BarraPiena), con le cifre che contano
/// (NumeroCheConta): tile col filo, `.lbl` con il totale 22 bold a destra.
struct BarreQuadroVera: View {
    let titolo: String
    let totale: Double
    let barre: [QuadroVera.Barra]

    var body: some View {
        let s = Tema.Apple.Vera.SchedaCalcoli.self
        let massimo = max(barre.map(\.importo).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: s.fraColonne) {
                Text(titolo)
                    .carattereApple(s.titolo)
                    .foregroundColor(s.coloreTitolo)
                    .lineLimit(1)
                Spacer(minLength: s.fraColonne)
                NumeroCheConta(totale)
                    .carattereApple(s.totale)
                    .foregroundColor(s.coloreTotale)
            }
            .padding(.bottom, s.sottoTitolo)
            VStack(spacing: s.fraRighe) {
                ForEach(Array(barre.enumerated()), id: \.element.id) { i, b in
                    HStack(spacing: s.fraColonne) {
                        Text(b.titolo)
                            .carattereApple(s.etichetta)
                            .foregroundColor(s.coloreEtichetta)
                            .lineLimit(1)
                            .frame(width: s.larghezzaEtichetta, alignment: .leading)
                        BarraPiena(frazione: b.importo / massimo, colore: s.tinta(b.tinta), indice: i)
                        NumeroCheConta(b.importo, indice: i + 1)
                            .carattereApple(s.cifra)
                            .foregroundColor(s.coloreCifra)
                            .frame(width: s.larghezzaCifra, alignment: .trailing)
                    }
                }
            }
        }
        .padding(s.padding)
        .superficieApple(s.superficie, raggio: s.raggio)
    }
}

/// Una barra che cresce da sinistra con una molla, dopo `ritardo`.
private struct CrescitaBarraVera<Contenuto: View>: View {
    let ritardo: Double
    @ViewBuilder let contenuto: () -> Contenuto
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea
    @State private var cresciuta = false

    var body: some View {
        let fermo = movimentoRidotto || modoIstantanea
        contenuto()
            .scaleEffect(x: fermo || cresciuta ? 1 : 0.001, y: 1, anchor: .leading)
            .onAppear {
                guard !fermo else { return }
                withAnimation(Tema.Moto.VeraScrivania.barra.ritardoPrisma(ritardo)) { cresciuta = true }
            }
    }
}

/// La linea del tempo delle scadenze (.tl): 12 mesi, il puntino di oggi, un'asta per scadenza nel colore del canale.
struct LineaTempoVista: View {
    let linea: LineaTempoMiniVera

    var body: some View {
        let m = Tema.Misura.MiniVera.self
        let s = Tema.Apple.Vera.SchedaCalcoli.self
        // Nel tema Apple è una scheda dei calcoli come le altre: tile col filo, `.lbl` e il totale 22 bold
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: s.fraColonne) {
                Text(linea.titolo)
                    .carattereApple(s.titolo)
                    .foregroundColor(s.coloreTitolo)
                    .lineLimit(1)
                Spacer(minLength: s.fraColonne)
                Text(linea.totale)
                    .carattereApple(s.totale)
                    .foregroundColor(s.coloreTotale)
            }
            GeometryReader { g in disegno(larghezza: g.size.width) }
                .frame(height: m.altezzaLineaTempo)
        }
        .padding(s.padding)
        .superficieApple(s.superficie, raggio: s.raggio)
    }

    /// Le misure della linea in una larghezza: margini di 10, dodici mesi uguali.
    private struct Scala {
        let x0: CGFloat
        let x1: CGFloat
        let y: CGFloat
        let passo: CGFloat
        func x(_ mesi: Double) -> CGFloat { x0 + passo * CGFloat(mesi) }
    }

    private func disegno(larghezza w: CGFloat) -> some View {
        let m = Tema.Misura.MiniVera.self
        let s = Scala(x0: 10, x1: w - 10, y: m.asseLineaTempo, passo: (w - 20) / CGFloat(m.mesiLineaTempo))
        return ZStack(alignment: .topLeading) {
            asse(s)
            mesi(s)
            oggi(s)
            ForEach(Array(linea.punti.enumerated()), id: \.offset) { i, p in
                // .pin del template: ogni asta cresce dall'asse con una molla, una dopo l'altra
                CrescitaMiniVera(indice: i, ancora: UnitPoint(x: s.x(p.mesi) / max(w, 1), y: s.y / m.altezzaLineaTempo)) {
                    punto(p, s)
                }
            }
            if let o = linea.oltre { oltre(o, s) }
        }
    }

    private func asse(_ s: Scala) -> some View {
        let m = Tema.Misura.MiniVera.self
        return Path { p in
            p.move(to: CGPoint(x: s.x0, y: s.y))
            p.addLine(to: CGPoint(x: s.x1, y: s.y))
            for i in 0..<m.mesiLineaTempo {
                p.move(to: CGPoint(x: s.x(Double(i)), y: s.y - m.tacca))
                p.addLine(to: CGPoint(x: s.x(Double(i)), y: s.y + m.tacca))
            }
        }
        .stroke(Tema.Colore.MiniVera.separatore, lineWidth: 1)
    }

    private func mesi(_ s: Scala) -> some View {
        let m = Tema.Misura.MiniVera.self
        let cal = Calendar.current
        return ForEach(0..<m.mesiLineaTempo, id: \.self) { i in
            Text(Formati.meseBreve.string(from: cal.date(byAdding: .month, value: i, to: linea.inizio) ?? linea.inizio).lowercased())
                .font(Tema.Testo.MiniVera.mese)
                .foregroundColor(Tema.Colore.MiniVera.testoTerziario)
                .fixedSize()
                .position(x: s.x(Double(i)) + s.passo / 2, y: s.y + 11)
        }
    }

    private func oggi(_ s: Scala) -> some View {
        let m = Tema.Misura.MiniVera.self
        let c = Tema.Colore.MiniVera.self
        let xo = s.x(mesiDa(linea.inizio, a: linea.oggi))
        return ZStack(alignment: .topLeading) {
            Circle().fill(c.accento)
                .frame(width: m.puntoOggi * 2, height: m.puntoOggi * 2)
                .position(x: xo, y: s.y)
            Text("oggi").font(Tema.Testo.MiniVera.oggi).foregroundColor(c.accento)
                .fixedSize()
                .position(x: xo + 16, y: s.y - 10)
        }
    }

    private func punto(_ p: LineaTempoMiniVera.Punto, _ s: Scala) -> some View {
        let m = Tema.Misura.MiniVera.self
        let c = Tema.Colore.MiniVera.self
        let massimo = max(linea.punti.map(\.importo).max() ?? 1, 1)
        let h = m.astaMinima + CGFloat((max(p.importo, 0) / massimo).squareRoot()) * m.astaVariabile
        let px = s.x(p.mesi)
        let colore = Tema.Colore.canale(p.canale)
        return ZStack(alignment: .topLeading) {
            Path { q in
                q.move(to: CGPoint(x: px, y: s.y))
                q.addLine(to: CGPoint(x: px, y: s.y - h))
            }
            .stroke(colore, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            Circle().fill(colore)
                .overlay(Circle().stroke(c.bordoPunto, lineWidth: 1.5))
                .frame(width: m.puntoScadenza * 2, height: m.puntoScadenza * 2)
                .position(x: px, y: s.y - h)
            Text(p.etichetta).font(Tema.Testo.MiniVera.importoPunto).foregroundColor(c.testo)
                .fixedSize()
                .position(x: px, y: s.y - h - 20)
            Text(p.giorno).font(Tema.Testo.MiniVera.dataPunto).foregroundColor(c.testoSecondario)
                .fixedSize()
                .position(x: px, y: s.y - h - 10)
        }
    }

    private func oltre(_ testo: String, _ s: Scala) -> some View {
        let c = Tema.Colore.MiniVera.self
        return ZStack(alignment: .topLeading) {
            Text(testo).font(Tema.Testo.MiniVera.dataPunto).foregroundColor(c.testoSecondario)
                .fixedSize()
                .frame(width: 160, alignment: .trailing)
                .position(x: s.x1 - 2 - 80, y: s.y - 38)
            Path { q in
                q.move(to: CGPoint(x: s.x1 - 60, y: s.y - 28))
                q.addLine(to: CGPoint(x: s.x1, y: s.y - 28))
            }
            .stroke(c.testoTerziario, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        }
    }

    private func mesiDa(_ inizio: Date, a d: Date) -> Double {
        let cal = Calendar.current
        let giorni = Double(cal.range(of: .day, in: .month, for: inizio)?.count ?? 30)
        return Double(cal.dateComponents([.day], from: inizio, to: d).day ?? 0) / giorni
    }
}

/// .pin: l'asta di una scadenza cresce dall'asse con una molla, dopo la comparsa della linea del tempo.
struct CrescitaMiniVera<Contenuto: View>: View {
    let indice: Int
    let ancora: UnitPoint
    @ViewBuilder let contenuto: () -> Contenuto
    @Environment(\.accessibilityReduceMotion) private var movimentoRidotto
    @Environment(\.modoIstantanea) private var modoIstantanea
    @State private var cresciuta = false

    var body: some View {
        let fermo = movimentoRidotto || modoIstantanea
        contenuto()
            .scaleEffect(x: 1, y: fermo || cresciuta ? 1 : 0.001, anchor: ancora)
            .opacity(fermo || cresciuta ? 1 : 0)
            .onAppear {
                guard !fermo else { return }
                withAnimation(Tema.Moto.MiniVera.asta.ritardoPrisma(Tema.Moto.MiniVera.ritardoAsta + Tema.Moto.MiniVera.passoAsta * Double(indice))) {
                    cresciuta = true
                }
            }
    }
}

