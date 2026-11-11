import SwiftUI

// Barre e grafici del tema «stile Apple» (Design/template-apple-specifica.md §2.4, §2.5, §2.11).
// I componenti non calcolano nulla: ricevono frazioni, pesi o serie già pronte e le disegnano.
// Calmo e istantanee: barre piene, linee intere, aree e punti visibili, grafico già nello stato richiesto.

// MARK: - Mappa comune dei grafici

/// Punti normalizzati (0…1) nel riquadro del grafico, come `pathDa` del template:
/// x = x·larghezza, y = altezza − y·(altezza − 10) (10 di margine sopra).
private enum MappaGrafico {
    static func punto(_ p: CGPoint, in r: CGRect) -> CGPoint {
        let margine = Tema.Apple.Grafico.Tracciato.margineAlto
        return CGPoint(x: r.minX + p.x * r.width, y: r.maxY - p.y * max(0, r.height - margine))
    }

    static func cerchio(attorno c: CGPoint, raggio: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - raggio, y: c.y - raggio, width: 2 * raggio, height: 2 * raggio))
    }
}

// MARK: - Barra che si riempie (§2.11)

/// Barra alta 8, raggio 9, fondo `binario`: si riempie da 0 alla frazione in 1,2 s (`uscita`),
/// ritardo 0,15 + indice·0,09. Un nuovo valore anima dal valore mostrato.
///
///     BarraPiena(frazione: 0.85, colore: Tema.Apple.Colore.verde, indice: 0)
struct BarraPiena: View {
    let frazione: Double
    let colore: Color
    let indice: Int
    let altezza: CGFloat
    let raggio: CGFloat
    let binario: Color?

    @Environment(\.prismaStatoFinale) private var statoFinale
    /// Istantanee: lo stato finale è per sempre, niente da scrivere alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    @State private var mostrata: Double = 0

    /// - Parameters:
    ///   - frazione: 0…1 (fuori intervallo viene limitata).
    ///   - indice: posizione nella sequenza delle barre della schermata (ritardo 0,15 + indice·0,09).
    ///   - binario: fondo della barra; nil = nessun fondo (pezzi dei canali e della composizione).
    init(frazione: Double,
         colore: Color,
         indice: Int = 0,
         altezza: CGFloat = Tema.Apple.Grafico.Barra.altezza,
         raggio: CGFloat = Tema.Apple.Grafico.Barra.raggio,
         binario: Color? = Tema.Apple.Colore.binario) {
        self.frazione = min(max(frazione, 0), 1)
        self.colore = colore
        self.indice = indice
        self.altezza = altezza
        self.raggio = raggio
        self.binario = binario
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if let binario {
                RoundedRectangle(cornerRadius: raggio).fill(binario)
            }
            FormaBarraPiena(frazione: statoFinale ? frazione : mostrata, raggio: raggio)
                .fill(colore)
                .transaction { t in if statoFinale { t.animation = nil } }
        }
        .frame(height: altezza)
        .clipShape(RoundedRectangle(cornerRadius: raggio))
        .onAppear(perform: riempi)
        .onChange(of: frazione) { nuova in aggiorna(nuova) }
    }

    private func riempi() {
        guard !statoFinale else {
            if !scatto { mostrata = frazione }
            return
        }
        guard mostrata != frazione else { return }
        let moto = Tema.Apple.Moto.Barra.self
        withAnimation(moto.animazione.ritardoPrisma(moto.ritardo(indice: indice))) {
            mostrata = frazione
        }
    }

    private func aggiorna(_ nuova: Double) {
        guard !statoFinale else {
            mostrata = nuova
            return
        }
        withAnimation(Tema.Apple.Moto.Barra.animazione) {
            mostrata = nuova
        }
    }
}

/// Il riempimento: un rettangolo arrotondato largo `frazione` della barra (il raggio si adatta da solo
/// quando è più stretto del doppio del raggio, come `border-radius`).
private struct FormaBarraPiena: Shape {
    var frazione: Double
    let raggio: CGFloat

    var animatableData: Double {
        get { frazione }
        set { frazione = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let larghezza = rect.width * CGFloat(min(max(frazione, 0), 1))
        guard larghezza > 0, rect.height > 0 else { return Path() }
        let r = CGRect(x: rect.minX, y: rect.minY, width: larghezza, height: rect.height)
        return Path(roundedRect: r, cornerRadius: min(raggio, min(r.width, r.height) / 2))
    }
}

/// Un pezzo di `BarraPienaSegmenti`: peso relativo (per esempio la quota in %) e colore.
struct PezzoBarraPiena: Identifiable {
    let id: String
    var peso: Double
    var colore: Color
}

/// Barra a pezzi che si riempiono uno dopo l'altro (ciascuno nel suo spazio, da sinistra a destra),
/// con 3 di spazio tra i pezzi. I pezzi di peso 0 non si disegnano.
///
///     BarraPienaSegmenti.composizione([
///         PezzoBarraPiena(id: "azionario", peso: 40, colore: Tema.Apple.Colore.Composizione.azionario), …
///     ])
///     BarraPienaSegmenti.canali(alleanza: 47, indipendente: 53)
///         .frame(width: Tema.Apple.Grafico.Barra.larghezzaCanali)
struct BarraPienaSegmenti: View {
    let pezzi: [PezzoBarraPiena]
    let indice: Int
    let altezza: CGFloat
    let spazio: CGFloat
    let raggioPezzo: CGFloat
    let raggioContenitore: CGFloat

    /// - Parameter indice: indice del primo pezzo nella sequenza delle barre (gli altri seguono).
    init(pezzi: [PezzoBarraPiena],
         indice: Int = 0,
         altezza: CGFloat = Tema.Apple.Grafico.Barra.altezza,
         spazio: CGFloat = Tema.Apple.Grafico.Barra.spazio,
         raggioPezzo: CGFloat = Tema.Apple.Grafico.Barra.raggio,
         raggioContenitore: CGFloat = Tema.Apple.Grafico.Barra.raggio) {
        self.pezzi = pezzi
        self.indice = indice
        self.altezza = altezza
        self.spazio = spazio
        self.raggioPezzo = raggioPezzo
        self.raggioContenitore = raggioContenitore
    }

    /// Barra di composizione: alta 22, contenitore di raggio 12, pezzi di raggio 6
    /// (ritardi 0,15 / 0,24 / 0,33 / 0,42 con `indice` 0).
    static func composizione(_ pezzi: [PezzoBarraPiena], indice: Int = 0) -> BarraPienaSegmenti {
        let b = Tema.Apple.Grafico.Barra.self
        return BarraPienaSegmenti(pezzi: pezzi, indice: indice, altezza: b.altezzaComposizione,
                                  spazio: b.spazio, raggioPezzo: b.raggioPezzo,
                                  raggioContenitore: b.raggioComposizione)
    }

    /// Barra dei canali: Alleanza (blu) e indipendente (cuoio), alta 8, spazio 3.
    /// Larga 520 nel template: la larghezza la dà chi la usa.
    static func canali(alleanza: Double, indipendente: Double, indice: Int = 0) -> BarraPienaSegmenti {
        let c = Tema.Apple.Colore.self
        return BarraPienaSegmenti(pezzi: [
            PezzoBarraPiena(id: "alleanza", peso: alleanza, colore: c.canaleAlleanza),
            PezzoBarraPiena(id: "indipendente", peso: indipendente, colore: c.canaleIndipendente)
        ], indice: indice)
    }

    var body: some View {
        let utili = pezzi.filter { $0.peso > 0 }
        let totale = utili.reduce(0) { $0 + $1.peso }
        GeometryReader { geo in
            let netto = max(0, geo.size.width - spazio * CGFloat(max(0, utili.count - 1)))
            HStack(spacing: spazio) {
                ForEach(Array(utili.enumerated()), id: \.element.id) { i, pezzo in
                    BarraPiena(frazione: 1, colore: pezzo.colore, indice: indice + i,
                               altezza: altezza, raggio: raggioPezzo, binario: nil)
                        .frame(width: totale > 0 ? netto * CGFloat(pezzo.peso / totale) : 0)
                }
            }
        }
        .frame(height: altezza)
        .clipShape(RoundedRectangle(cornerRadius: raggioContenitore))
    }
}

// MARK: - Linea che si disegna (§2.4)

/// Linea che si disegna da sinistra a destra in 1,5 s (`uscita`), ritardo 0,15 + indice·0,12;
/// poi l'area sotto (gradiente del colore da 0,20 a 0) e il punto finale compaiono in 0,9 s dopo 0,6 s.
/// Il tratteggio delle stime resta anche dopo il disegno. Per ridisegnare (nuovi dati), cambia `.id`.
///
///     ZStack {
///         GrigliaGrafico(oggi: 0.6)
///         TracciatoGrafico(punti: storia, colore: Tema.Apple.Colore.anello2, area: true)
///         FasciaGrafico(sopra: alta, sotto: bassa, colore: Tema.Apple.Colore.stima)
///         TracciatoGrafico(punti: stima, colore: Tema.Apple.Colore.stima,
///                          spessore: Tema.Apple.Grafico.Tracciato.spessoreStima,
///                          tratteggio: Tema.Apple.Grafico.Tracciato.tratteggioStima, indice: 1)
///     }
///     .frame(height: 300)
struct TracciatoGrafico: View {
    let punti: [CGPoint]
    let colore: Color
    let spessore: CGFloat
    let tratteggio: [CGFloat]?
    let area: Bool
    let opacitaArea: Double
    let puntoFinale: Bool
    let indice: Int
    let ritardo: Double
    /// Durata del disegno della linea (nil = `Moto.Linea`, 1,5 s con ritardo 0,15 + indice·0,12); data, la linea parte
    /// subito (gioco del rischio: 2,2 s).
    let durata: Double?

    @Environment(\.prismaStatoFinale) private var statoFinale
    /// Istantanee: lo stato finale è per sempre, niente da scrivere alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    @State private var disegno: CGFloat = 0
    @State private var comparsa: Double = 0

    /// - Parameters:
    ///   - punti: normalizzati 0…1 (x da sinistra, y dal basso), in ordine di x.
    ///   - tratteggio: nil = linea piena; per le stime `Tracciato.tratteggioStima` (6 6).
    ///   - area: gradiente sotto la linea.
    ///   - puntoFinale: punto di raggio 5 con bordo bianco 2,5 sull'ultimo punto.
    ///   - indice: posizione tra le linee della schermata (ritardo 0,15 + indice·0,12).
    ///   - ritardo: ritardo in più, sommato alla linea e all'area.
    init(punti: [CGPoint],
         colore: Color,
         spessore: CGFloat = Tema.Apple.Grafico.Tracciato.spessore,
         tratteggio: [CGFloat]? = nil,
         area: Bool = false,
         opacitaArea: Double = Tema.Apple.Grafico.Tracciato.opacitaArea,
         puntoFinale: Bool = false,
         indice: Int = 0,
         ritardo: Double = 0,
         durata: Double? = nil) {
        self.punti = punti
        self.colore = colore
        self.spessore = spessore
        self.tratteggio = tratteggio
        self.area = area
        self.opacitaArea = opacitaArea
        self.puntoFinale = puntoFinale
        self.indice = indice
        self.ritardo = ritardo
        self.durata = durata
    }

    var body: some View {
        let t = Tema.Apple.Grafico.Tracciato.self
        let tratto = statoFinale ? 1 : disegno
        let visibile = statoFinale ? 1 : comparsa
        ZStack {
            if area {
                FormaTracciato(punti: punti, chiusa: true)
                    .fill(LinearGradient(colors: [colore.opacity(opacitaArea), colore.opacity(0)],
                                         startPoint: .top, endPoint: .bottom))
                    .opacity(visibile)
            }
            FormaTracciato(punti: punti, chiusa: false)
                .trim(from: 0, to: tratto)
                .stroke(colore, style: StrokeStyle(lineWidth: spessore, lineJoin: .round, dash: tratteggio ?? []))
            if puntoFinale, let ultimo = punti.last {
                PuntoGrafico(forma: FormaPuntoTracciato(punto: ultimo, raggio: t.raggioPunto), colore: colore)
                    .opacity(visibile)
            }
        }
        .onAppear(perform: disegna)
    }

    private func disegna() {
        guard !statoFinale else {
            if !scatto {
                disegno = 1
                comparsa = 1
            }
            return
        }
        guard disegno < 1 else { return }
        let linea = Tema.Apple.Moto.Linea.self
        let fondo = Tema.Apple.Moto.Area.self
        let animazione = durata.map { Tema.Apple.Moto.Curva.uscita.animazione($0).ritardoPrisma(ritardo) }
            ?? linea.animazione.ritardoPrisma(ritardo + linea.ritardo(indice: indice))
        withAnimation(animazione) {
            disegno = 1
        }
        withAnimation(fondo.animazione.ritardoPrisma(ritardo + fondo.ritardo)) {
            comparsa = 1
        }
    }
}

/// Fascia di incertezza tra due linee (normalizzate 0…1), opacità 0,13: compare con l'area (0,9 s dopo 0,6 s).
struct FasciaGrafico: View {
    let sopra: [CGPoint]
    let sotto: [CGPoint]
    let colore: Color
    let opacita: Double
    let ritardo: Double

    @Environment(\.prismaStatoFinale) private var statoFinale
    /// Istantanee: lo stato finale è per sempre, niente da scrivere alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    @State private var comparsa: Double = 0

    /// - Parameters:
    ///   - sopra: bordo alto della fascia, da sinistra a destra.
    ///   - sotto: bordo basso della fascia, da sinistra a destra.
    init(sopra: [CGPoint],
         sotto: [CGPoint],
         colore: Color,
         opacita: Double = Tema.Apple.Grafico.Tracciato.opacitaFascia,
         ritardo: Double = 0) {
        self.sopra = sopra
        self.sotto = sotto
        self.colore = colore
        self.opacita = opacita
        self.ritardo = ritardo
    }

    var body: some View {
        FormaFascia(sopra: sopra, sotto: sotto)
            .fill(colore.opacity(opacita))
            .opacity(statoFinale ? 1 : comparsa)
            .onAppear {
                guard !statoFinale else {
                    if !scatto { comparsa = 1 }
                    return
                }
                guard comparsa < 1 else { return }
                let fondo = Tema.Apple.Moto.Area.self
                withAnimation(fondo.animazione.ritardoPrisma(ritardo + fondo.ritardo)) {
                    comparsa = 1
                }
            }
    }
}

/// Griglia leggera: righe orizzontali del colore `separatore` (dal basso al margine alto, a passi uguali)
/// e, se data, la riga verticale «oggi» tratteggiata 2 4. Ferma: non si anima.
struct GrigliaGrafico: View {
    let righe: Int
    let oggi: CGFloat?

    /// - Parameters:
    ///   - righe: quante righe orizzontali (4 nel grafico «Nel tempo»).
    ///   - oggi: posizione x normalizzata (0…1) della riga verticale, nil = nessuna.
    init(righe: Int = Tema.Apple.Grafico.Tracciato.righeGriglia, oggi: CGFloat? = nil) {
        self.righe = righe
        self.oggi = oggi
    }

    var body: some View {
        let t = Tema.Apple.Grafico.Tracciato.self
        ZStack {
            FormaGriglia(righe: righe)
                .stroke(t.coloreGriglia, lineWidth: t.spessoreGriglia)
            if let oggi {
                FormaRigaVerticale(x: oggi)
                    .stroke(t.coloreOggi, style: StrokeStyle(lineWidth: t.spessoreGriglia, dash: t.tratteggioOggi))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct FormaTracciato: Shape {
    let punti: [CGPoint]
    let chiusa: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let primo = punti.first, let ultimo = punti.last else { return p }
        p.move(to: MappaGrafico.punto(primo, in: rect))
        for q in punti.dropFirst() {
            p.addLine(to: MappaGrafico.punto(q, in: rect))
        }
        if chiusa {
            p.addLine(to: CGPoint(x: MappaGrafico.punto(ultimo, in: rect).x, y: rect.maxY))
            p.addLine(to: CGPoint(x: MappaGrafico.punto(primo, in: rect).x, y: rect.maxY))
            p.closeSubpath()
        }
        return p
    }
}

private struct FormaFascia: Shape {
    let sopra: [CGPoint]
    let sotto: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let primo = sopra.first, !sotto.isEmpty else { return p }
        p.move(to: MappaGrafico.punto(primo, in: rect))
        for q in sopra.dropFirst() {
            p.addLine(to: MappaGrafico.punto(q, in: rect))
        }
        for q in sotto.reversed() {
            p.addLine(to: MappaGrafico.punto(q, in: rect))
        }
        p.closeSubpath()
        return p
    }
}

private struct FormaPuntoTracciato: Shape {
    let punto: CGPoint
    let raggio: CGFloat

    func path(in rect: CGRect) -> Path {
        MappaGrafico.cerchio(attorno: MappaGrafico.punto(punto, in: rect), raggio: raggio)
    }
}

private struct FormaGriglia: Shape {
    let righe: Int

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard righe > 0 else { return p }
        let passi = max(1, righe - 1)
        for k in 0..<righe {
            let y = MappaGrafico.punto(CGPoint(x: 0, y: CGFloat(k) / CGFloat(passi)), in: rect).y
            p.move(to: CGPoint(x: rect.minX, y: y))
            p.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return p
    }
}

private struct FormaRigaVerticale: Shape {
    let x: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let posizione = rect.minX + x * rect.width
        p.move(to: CGPoint(x: posizione, y: rect.minY))
        p.addLine(to: CGPoint(x: posizione, y: rect.maxY))
        return p
    }
}

/// Punto pieno del colore con il bordo bianco (prima il riempimento, poi il bordo, come l'SVG).
private struct PuntoGrafico<Forma: Shape>: View {
    let forma: Forma
    let colore: Color

    var body: some View {
        let t = Tema.Apple.Grafico.Tracciato.self
        ZStack {
            forma.fill(colore)
            forma.stroke(t.colorePuntoBordo, lineWidth: t.bordoPunto)
        }
    }
}

// MARK: - Grafico «In essere / Con le proposte» (§2.5)

/// I dati del grafico, già calcolati da Prisma (valori nella stessa unità, per esempio migliaia di euro).
struct DatiGraficoPortafoglio {
    /// Valori mese per mese fino a oggi (l'ultimo è il valore attuale).
    var storia: [Double]
    /// Stima con le proposte, da oggi in avanti: il primo valore coincide con l'ultimo della storia.
    var stima: [Double]
    /// Bordo alto della fascia di incertezza, punto per punto con `stima`.
    var stimaAlta: [Double]
    /// Bordo basso della fascia di incertezza, punto per punto con `stima`.
    var stimaBassa: [Double]
    /// Nomi dei mesi per tutto l'asse (storia e stima), uno per punto.
    var mesi: [String]
    /// Minimo dell'asse y.
    var minimo: Double
    /// Massimo dell'asse y «In essere».
    var massimoInEssere: Double
    /// Massimo dell'asse y «Con le proposte».
    var massimoConProposte: Double
    /// Per esempio «stima giugno 2027».
    var etichettaStima: String
}

/// Grafico del portafoglio: con `progresso` 0 la storia («In essere»), con 1 anche la stima («Con le proposte»).
/// Al cambio di `progresso` l'asse x si allarga a destra (la storia si comprime a sinistra), il massimo y
/// sale e compaiono la stima tratteggiata, la fascia di incertezza, il punto finale e la sua etichetta,
/// in 0,9 s con la quartica. Al montaggio la linea della storia si disegna (dopo 0,2 s).
/// Grande 818×92 più la fascia dei mesi; la larghezza la dà il contenitore.
///
///     GraficoPortafoglio(dati: dati, progresso: conProposte ? 1 : 0)
struct GraficoPortafoglio: View {
    let dati: DatiGraficoPortafoglio
    let progresso: Double
    let ritardo: Double

    @Environment(\.prismaStatoFinale) private var statoFinale
    /// Istantanee: lo stato finale è per sempre, niente da scrivere alla comparsa (`prismaScatto`).
    @Environment(\.prismaScatto) private var scatto
    @State private var mostrato: Double
    @State private var disegno: CGFloat = 0
    @State private var comparsa: Double = 0

    /// - Parameters:
    ///   - progresso: 0 «In essere», 1 «Con le proposte» (anche valori intermedi).
    ///   - ritardo: attesa prima che la storia si disegni al montaggio.
    init(dati: DatiGraficoPortafoglio,
         progresso: Double,
         ritardo: Double = Tema.Apple.Grafico.Portafoglio.ritardoDisegno) {
        let p = min(max(progresso, 0), 1)
        self.dati = dati
        self.progresso = p
        self.ritardo = ritardo
        _mostrato = State(initialValue: p)
    }

    var body: some View {
        let g = Tema.Apple.Grafico.Portafoglio.self
        let p = statoFinale ? progresso : mostrato
        GeometryReader { geo in
            let riquadro = CGSize(width: geo.size.width, height: g.altezza)
            ZStack(alignment: .topLeading) {
                StratoFormePortafoglio(dati: dati, progresso: p,
                                       disegno: statoFinale ? 1 : disegno,
                                       comparsa: statoFinale ? 1 : comparsa)
                    .frame(width: riquadro.width, height: riquadro.height)
                StratoTestiPortafoglio(dati: dati, progresso: p, riquadro: riquadro)
            }
            // Calmo e istantanee: il grafico passa subito allo stato chiesto, senza allargarsi.
            .transaction { t in if statoFinale { t.animation = nil } }
        }
        .frame(height: g.altezza + g.fasciaMesi)
        .onAppear(perform: disegna)
        .onChange(of: progresso) { nuovo in
            guard !statoFinale else {
                mostrato = nuovo
                return
            }
            withAnimation(Tema.Apple.Moto.MorphProposte.animazione) {
                mostrato = nuovo
            }
        }
    }

    private func disegna() {
        guard !statoFinale else {
            if !scatto {
                mostrato = progresso
                disegno = 1
                comparsa = 1
            }
            return
        }
        guard disegno < 1 else { return }
        let linea = Tema.Apple.Moto.Linea.self
        let fondo = Tema.Apple.Moto.Area.self
        withAnimation(linea.animazione.ritardoPrisma(ritardo + linea.ritardo(indice: 0))) {
            disegno = 1
        }
        withAnimation(fondo.animazione.ritardoPrisma(ritardo + fondo.ritardo)) {
            comparsa = 1
        }
    }
}

/// Le forme del grafico, nell'ordine dell'SVG: area, storia, fascia, stima, punto della stima, punto di oggi.
private struct StratoFormePortafoglio: View {
    let dati: DatiGraficoPortafoglio
    let progresso: Double
    let disegno: CGFloat
    let comparsa: Double

    var body: some View {
        let g = Tema.Apple.Grafico.Portafoglio.self
        ZStack {
            FormaStoriaPortafoglio(dati: dati, progresso: progresso, chiusa: true)
                .fill(LinearGradient(colors: [g.coloreStoria.opacity(g.opacitaArea), g.coloreStoria.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
                .opacity(comparsa)
            FormaStoriaPortafoglio(dati: dati, progresso: progresso, chiusa: false)
                .trim(from: 0, to: disegno)
                .stroke(g.coloreStoria, style: StrokeStyle(lineWidth: g.spessoreStoria, lineJoin: .round))
            if dati.stima.count > 1 {
                stima
            }
            PuntoGrafico(forma: FormaPuntoPortafoglio(dati: dati, progresso: progresso, dellaStima: false),
                         colore: g.coloreStoria)
                .opacity(comparsa)
        }
    }

    @ViewBuilder private var stima: some View {
        let g = Tema.Apple.Grafico.Portafoglio.self
        FormaFasciaPortafoglio(dati: dati, progresso: progresso)
            .fill(g.coloreStima)
            .opacity(g.opacitaFascia * progresso)
        FormaStimaPortafoglio(dati: dati, progresso: progresso)
            .stroke(g.coloreStima, style: StrokeStyle(lineWidth: g.spessoreStima, dash: g.tratteggioStima))
            .opacity(progresso)
        PuntoGrafico(forma: FormaPuntoPortafoglio(dati: dati, progresso: progresso, dellaStima: true),
                     colore: g.coloreStima)
            .opacity(progresso)
    }
}

/// Le coordinate del grafico per un dato `progresso` (come `graficoP(p)` del template).
private struct GeometriaPortafoglio {
    let dati: DatiGraficoPortafoglio
    let progresso: Double
    let riquadro: CGRect

    /// Indice dell'ultimo punto della storia (oggi).
    var oggi: Double { Double(max(dati.storia.count - 1, 0)) }
    /// Indice dell'ultimo punto della stima sull'asse.
    var fine: Double { oggi + Double(max(dati.stima.count - 1, 0)) }
    /// Ultimo indice visibile sull'asse x: da oggi (p = 0) alla fine della stima (p = 1).
    var massimoX: Double { max(oggi + (fine - oggi) * progresso, 1) }

    func x(_ i: Double) -> CGFloat {
        riquadro.minX + CGFloat(i / massimoX) * riquadro.width
    }

    func y(_ v: Double) -> CGFloat {
        let alto = dati.massimoInEssere + (dati.massimoConProposte - dati.massimoInEssere) * progresso
        let campo = alto - dati.minimo
        guard campo > 0 else { return riquadro.maxY }
        let utile = max(0, riquadro.height - Tema.Apple.Grafico.Tracciato.margineAlto)
        return riquadro.maxY - CGFloat((v - dati.minimo) / campo) * utile
    }

    func punto(_ i: Double, _ v: Double) -> CGPoint { CGPoint(x: x(i), y: y(v)) }
}

private struct FormaStoriaPortafoglio: Shape {
    let dati: DatiGraficoPortafoglio
    var progresso: Double
    let chiusa: Bool

    var animatableData: Double {
        get { progresso }
        set { progresso = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let geo = GeometriaPortafoglio(dati: dati, progresso: progresso, riquadro: rect)
        var p = Path()
        guard !dati.storia.isEmpty else { return p }
        for (i, v) in dati.storia.enumerated() {
            let q = geo.punto(Double(i), v)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        if chiusa {
            p.addLine(to: CGPoint(x: geo.x(geo.oggi), y: rect.maxY))
            p.addLine(to: CGPoint(x: geo.x(0), y: rect.maxY))
            p.closeSubpath()
        }
        return p
    }
}

private struct FormaStimaPortafoglio: Shape {
    let dati: DatiGraficoPortafoglio
    var progresso: Double

    var animatableData: Double {
        get { progresso }
        set { progresso = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let geo = GeometriaPortafoglio(dati: dati, progresso: progresso, riquadro: rect)
        var p = Path()
        for (i, v) in dati.stima.enumerated() {
            let q = geo.punto(geo.oggi + Double(i), v)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        return p
    }
}

private struct FormaFasciaPortafoglio: Shape {
    let dati: DatiGraficoPortafoglio
    var progresso: Double

    var animatableData: Double {
        get { progresso }
        set { progresso = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let geo = GeometriaPortafoglio(dati: dati, progresso: progresso, riquadro: rect)
        var p = Path()
        guard !dati.stimaAlta.isEmpty, !dati.stimaBassa.isEmpty else { return p }
        for (i, v) in dati.stimaAlta.enumerated() {
            let q = geo.punto(geo.oggi + Double(i), v)
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        for (i, v) in dati.stimaBassa.enumerated().reversed() {
            p.addLine(to: geo.punto(geo.oggi + Double(i), v))
        }
        p.closeSubpath()
        return p
    }
}

private struct FormaPuntoPortafoglio: Shape {
    let dati: DatiGraficoPortafoglio
    var progresso: Double
    let dellaStima: Bool

    var animatableData: Double {
        get { progresso }
        set { progresso = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let geo = GeometriaPortafoglio(dati: dati, progresso: progresso, riquadro: rect)
        let raggio = Tema.Apple.Grafico.Tracciato.raggioPunto
        if dellaStima {
            guard let v = dati.stima.last else { return Path() }
            return MappaGrafico.cerchio(attorno: geo.punto(geo.fine, v), raggio: raggio)
        }
        guard let v = dati.storia.last else { return Path() }
        return MappaGrafico.cerchio(attorno: geo.punto(geo.oggi, v), raggio: raggio)
    }
}

/// Mesi sotto il grafico (uno ogni 2, uno ogni 3 quando p > 0,5, a scatto) ed etichetta della stima.
/// `Animatable`: segue il `progresso` fotogramma per fotogramma, come le forme.
private struct StratoTestiPortafoglio: View, Animatable {
    let dati: DatiGraficoPortafoglio
    var progresso: Double
    let riquadro: CGSize

    var animatableData: Double {
        get { progresso }
        set { progresso = newValue }
    }

    private var geometria: GeometriaPortafoglio {
        GeometriaPortafoglio(dati: dati, progresso: progresso, riquadro: CGRect(origin: .zero, size: riquadro))
    }

    /// Gli indici dei mesi da scrivere.
    private var indiciMesi: [Int] {
        let g = Tema.Apple.Grafico.Portafoglio.self
        let passo = progresso > g.sogliaPassoMesi ? g.passoMesiProposte : g.passoMesi
        let geo = geometria
        var indici: [Int] = []
        var i = 0
        while Double(i) <= geo.massimoX + 0.001, Double(i) <= geo.fine, i < dati.mesi.count {
            indici.append(i)
            i += passo
        }
        return indici
    }

    var body: some View {
        let g = Tema.Apple.Grafico.Portafoglio.self
        let asse = Tema.Apple.Carattere.asse
        let geo = geometria
        let yMesi = riquadro.height + g.distanzaMesi - asse.dimensione * Tema.Apple.Grafico.rapportoLineaBase
        ZStack(alignment: .topLeading) {
            ForEach(indiciMesi, id: \.self) { i in
                Text(dati.mesi[i])
                    .carattereApple(asse)
                    .foregroundColor(Tema.Apple.Colore.inchiostro3)
                    .lineLimit(1)
                    .fixedSize()
                    .position(x: geo.x(Double(i)), y: yMesi)
                    .transition(.identity)
            }
            if progresso > 0, dati.stima.count > 1, let ultimo = dati.stima.last {
                etichettaStima(in: geo.punto(geo.fine, ultimo))
            }
        }
        .frame(width: riquadro.width, height: riquadro.height + g.fasciaMesi, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    /// «stima giugno 2027»: allineata a destra, 8 a sinistra e 11 sopra il punto (linea di base).
    private func etichettaStima(in punto: CGPoint) -> some View {
        let g = Tema.Apple.Grafico.Portafoglio.self
        let c = Tema.Apple.Carattere.etichettaStima
        return Text(dati.etichettaStima)
            .carattereApple(c)
            .foregroundColor(g.coloreStima)
            .lineLimit(1)
            .frame(width: g.larghezzaEtichetta, alignment: .trailing)
            .position(x: punto.x - g.scostamentoEtichetta.width - g.larghezzaEtichetta / 2,
                      y: punto.y - g.scostamentoEtichetta.height - c.dimensione * Tema.Apple.Grafico.rapportoLineaBase)
            .opacity(progresso)
            .transition(.identity)
    }
}
