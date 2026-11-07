import SwiftUI

// Grafici di vetro delle aree di Analisi 360, generici e riusabili. Stesso linguaggio delle barre del TFR
// (BarreStradeTFR in Shell/SimulazioneTFR.swift): scala comune che parte da zero (la linea a sinistra), barre a
// capsula morbida, la cifra subito dopo la barra, la differenza in capsula nel colore del segno, etichette e note
// che vanno a capo invece di troncarsi con «…». Gettoni in TemaGraficiAnalisi.swift.
// - BarreImpilate: una o più barre fatte di tratti colorati (pensione pubblica + integrazione + divario).
// - BarraCopertura: fabbisogno contro coperto contro coperto con le proposte, la parte scoperta evidenziata.
// - Cascata: «da A a B» con voci che aggiungono e tolgono (lordo − costi − tasse = netto), orizzontale o verticale.
// - BarreConfronto: due o tre valori sulla stessa scala, con la differenza dal primo (oggi / dopo il calo).
// - TesseraCifraAnalisi: cifra grande, etichetta, una riga, tono semaforico.
// Sono fermi (nessuna animazione): vanno bene con «Riduci movimento» e nelle istantanee.

private typealias MG = Tema.Misura.GraficiAnalisi
private typealias KG = Tema.Colore.GraficiAnalisi
private typealias FG = Tema.Testo.GraficiAnalisi

// MARK: - Tono semaforico

/// Il tono di una cifra o di una differenza: colore del testo e tinta leggera della tessera.
enum TonoCifraAnalisi {
    case neutro, positivo, attenzione, negativo

    var colore: Color {
        switch self {
        case .neutro: return KG.neutro
        case .positivo: return KG.positivo
        case .attenzione: return KG.attenzione
        case .negativo: return KG.negativo
        }
    }

    /// Tinta della tessera evidenziata (nil per il tono neutro).
    var tinta: Color? {
        switch self {
        case .neutro: return nil
        case .positivo: return KG.tintaPositivo
        case .attenzione: return KG.tintaAttenzione
        case .negativo: return KG.tintaNegativo
        }
    }

    /// Il tono di una differenza: positivo se va nella direzione buona, negativo se in quella cattiva, neutro se
    /// (quasi) zero. `maggioreMeglio == false` per le grandezze in cui di meno è meglio (costi, divario).
    static func segno(_ v: Double, maggioreMeglio: Bool = true, soglia: Double = 0.5) -> TonoCifraAnalisi {
        if abs(v) < soglia { return .neutro }
        return (v > 0) == maggioreMeglio ? .positivo : .negativo
    }
}

// MARK: - Pezzi comuni

private extension View {
    /// Il suggerimento al passaggio del mouse, solo se c'è un testo.
    @ViewBuilder func aiutoGrafico(_ testo: String?) -> some View {
        if let testo, !testo.isEmpty {
            help(testo)
        } else {
            self
        }
    }
}

/// Un tratto di barra: pieno, oppure «mancante» (tinta leggera e bordo tratteggiato dello stesso colore).
private struct TrattoGrafico: View {
    let colore: Color
    var mancante: Bool = false

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: MG.raggioBarra, style: .continuous)
        if mancante {
            forma
                .fill(colore.opacity(MG.opacitaMancante))
                .overlay {
                    forma.strokeBorder(colore, style: StrokeStyle(lineWidth: MG.filoMancante,
                                                                  dash: [MG.trattoMancante, MG.trattoMancante]))
                }
        } else {
            forma.fill(colore)
        }
    }
}

/// Una voce della legenda: quadratino del colore, nome e cifra. Il nome va a capo, la cifra non si tronca.
private struct VoceLegendaGrafico: Identifiable {
    let id: String
    let etichetta: String
    let valore: String
    let colore: Color
    var mancante: Bool = false
    /// Il segno del traguardo (una lineetta verticale) invece del quadratino.
    var traguardo: Bool = false
    var coloreValore: Color = KG.cifra
}

private struct LegendaGrafico: View {
    let voci: [VoceLegendaGrafico]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: MG.voceLegendaMinima), spacing: MG.spazioLegenda, alignment: .topLeading)],
                  alignment: .leading, spacing: MG.spazio) {
            ForEach(voci) { v in
                voce(v)
            }
        }
    }

    private func voce(_ v: VoceLegendaGrafico) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: MG.spazioQuadratino) {
            segno(v)
            VStack(alignment: .leading, spacing: MG.spazioVoceLegenda) {
                Text(v.etichetta)
                    .font(FG.legenda)
                    .foregroundColor(KG.nota)
                    .fixedSize(horizontal: false, vertical: true)
                Text(v.valore)
                    .font(FG.cifraLegenda)
                    .foregroundColor(v.coloreValore)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func segno(_ v: VoceLegendaGrafico) -> some View {
        if v.traguardo {
            Rectangle()
                .fill(v.colore)
                .frame(width: MG.segnoTraguardo, height: MG.quadratino + MG.sporgenzaTraguardo)
                .frame(width: MG.quadratino)
        } else {
            TrattoGrafico(colore: v.colore, mancante: v.mancante)
                .frame(width: MG.quadratino, height: MG.quadratino)
        }
    }
}

/// La capsula con la differenza, nel colore del tono (come sulle barre del TFR).
private struct CapsulaDifferenza: View {
    let testo: String
    let tono: TonoCifraAnalisi
    var aiuto: String? = nil

    var body: some View {
        Text(testo)
            .font(FG.differenza)
            .foregroundColor(tono.colore)
            .lineLimit(1)
            .padding(MG.margineDifferenza)
            .background { FormaVetro.capsula.fill(tono.colore.opacity(MG.opacitaDifferenza)) }
            .fixedSize()
            .aiutoGrafico(aiuto)
    }
}

/// L'etichetta di una riga a sinistra delle barre: va a capo invece di troncarsi.
private struct EtichettaRigaGrafico: View {
    let testo: String
    var forte: Bool = false

    var body: some View {
        Text(testo)
            .font(forte ? FG.etichettaTotale : FG.etichetta)
            .foregroundColor(KG.etichetta)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: MG.etichetta, alignment: .leading)
    }
}

/// Il posto della linea dello zero tra le etichette e le barre. La linea la disegna `lineaZeroGrafico()` sopra
/// tutte le righe insieme, così resta continua anche quando un'etichetta va a capo.
private struct LineaZeroGrafico: View {
    var body: some View {
        Color.clear.frame(width: Tema.Misura.filo, height: Tema.Misura.filo)
    }
}

private extension View {
    /// La linea dello zero, alta quanto tutte le righe, subito dopo la colonna delle etichette.
    func lineaZeroGrafico(_ attiva: Bool = true) -> some View {
        overlay(alignment: .topLeading) {
            if attiva {
                Rectangle()
                    .fill(KG.zero)
                    .frame(width: Tema.Misura.filo)
                    .padding(.leading, MG.etichetta)
            }
        }
    }
}

// MARK: - (a) Barre impilate

/// Una o più barre orizzontali fatte di tratti colorati sulla stessa scala, con le cifre nella legenda.
/// Esempio: pensione pubblica + integrazione dai piani + divario (mancante) fino al reddito desiderato
/// (il traguardo, segnato con una lineetta verticale).
struct BarreImpilate: View {
    struct Segmento: Identifiable {
        let id: String
        let etichetta: String
        let valore: Double
        let colore: Color
        /// La parte che manca (divario, scoperto): tinta leggera e bordo tratteggiato.
        var mancante: Bool

        init(_ etichetta: String, _ valore: Double, colore: Color, mancante: Bool = false, id: String? = nil) {
            self.id = id ?? etichetta
            self.etichetta = etichetta
            self.valore = valore
            self.colore = colore
            self.mancante = mancante
        }
    }

    struct Riga: Identifiable {
        let id: String
        /// Il nome della riga a sinistra (vuoto: la barra prende tutta la larghezza).
        let etichetta: String
        let segmenti: [Segmento]

        init(_ etichetta: String, segmenti: [Segmento], id: String? = nil) {
            self.id = id ?? etichetta
            self.etichetta = etichetta
            self.segmenti = segmenti
        }
    }

    let righe: [Riga]
    /// Il valore da raggiungere (reddito desiderato, fabbisogno): una lineetta verticale sulla scala.
    var traguardo: Double? = nil
    var etichettaTraguardo: String? = nil
    /// La legenda con le cifre dei tratti (della prima riga) e del traguardo.
    var legenda: Bool = true
    /// Il totale di ogni riga subito dopo la barra.
    var mostraTotale: Bool = true
    var formato: (Double) -> String = { Formati.euro($0) }

    /// Più righe sulla stessa scala (per esempio «Oggi» e «Con le proposte»).
    init(righe: [Riga], traguardo: Double? = nil, etichettaTraguardo: String? = nil, legenda: Bool = true,
         mostraTotale: Bool = true, formato: @escaping (Double) -> String = { Formati.euro($0) }) {
        self.righe = righe
        self.traguardo = traguardo
        self.etichettaTraguardo = etichettaTraguardo
        self.legenda = legenda
        self.mostraTotale = mostraTotale
        self.formato = formato
    }

    /// Una sola barra, larga quanto il grafico.
    init(segmenti: [Segmento], traguardo: Double? = nil, etichettaTraguardo: String? = nil, legenda: Bool = true,
         mostraTotale: Bool = true, formato: @escaping (Double) -> String = { Formati.euro($0) }) {
        self.init(righe: [Riga("", segmenti: segmenti)], traguardo: traguardo, etichettaTraguardo: etichettaTraguardo,
                  legenda: legenda, mostraTotale: mostraTotale, formato: formato)
    }

    private static func somma(_ r: Riga) -> Double {
        r.segmenti.reduce(0) { $0 + max(0, $1.valore) }
    }

    private var scala: Double {
        let massimo = righe.map(Self.somma).max() ?? 0
        return max(massimo, traguardo ?? 0, 1)
    }

    private var conEtichette: Bool { righe.contains { !$0.etichetta.isEmpty } }

    private var vociLegenda: [VoceLegendaGrafico] {
        var voci: [VoceLegendaGrafico] = (righe.first?.segmenti ?? []).filter { $0.valore > 0 }.map { s in
            VoceLegendaGrafico(id: s.id, etichetta: s.etichetta, valore: formato(s.valore), colore: s.colore,
                               mancante: s.mancante, coloreValore: s.mancante ? s.colore : KG.cifra)
        }
        if let t = traguardo, let e = etichettaTraguardo {
            voci.append(VoceLegendaGrafico(id: "traguardo", etichetta: e, valore: formato(t), colore: KG.traguardo, traguardo: true))
        }
        return voci
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MG.spazio) {
            // Righe senza spazio tra loro: la linea dello zero resta continua
            VStack(alignment: .leading, spacing: 0) {
                ForEach(righe) { r in
                    riga(r)
                }
            }
            .lineaZeroGrafico(conEtichette)
            if legenda {
                LegendaGrafico(voci: vociLegenda)
                    .padding(.leading, conEtichette ? MG.etichetta + Tema.Misura.filo : 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func riga(_ r: Riga) -> some View {
        HStack(spacing: 0) {
            if conEtichette {
                EtichettaRigaGrafico(testo: r.etichetta)
                LineaZeroGrafico()
            }
            GeometryReader { geo in
                areaBarra(r, larghezza: geo.size.width, altezza: geo.size.height)
            }
            .frame(height: MG.rigaBarraSpessa)
        }
    }

    private func areaBarra(_ r: Riga, larghezza: CGFloat, altezza: CGFloat) -> some View {
        let spazio = max(0, larghezza - (mostraTotale ? MG.riservaTotale : 0))
        let s = scala
        return ZStack(alignment: .leading) {
            HStack(spacing: MG.spazioCifra) {
                barra(r, spazio: spazio, scala: s)
                if mostraTotale {
                    Text(formato(Self.somma(r)))
                        .font(FG.cifra)
                        .foregroundColor(KG.cifra)
                        .lineLimit(1)
                        .fixedSize()
                }
                Spacer(minLength: 0)
            }
            if let t = traguardo {
                Rectangle()
                    .fill(KG.traguardo)
                    .frame(width: MG.segnoTraguardo, height: MG.barraSpessa + MG.sporgenzaTraguardo * 2)
                    .offset(x: spazio * CGFloat(min(t / s, 1)) - MG.segnoTraguardo / 2)
            }
        }
        .frame(width: larghezza, height: altezza, alignment: .leading)
    }

    private func barra(_ r: Riga, spazio: CGFloat, scala: Double) -> some View {
        let visibili = r.segmenti.filter { $0.valore > 0 }
        return HStack(spacing: MG.stacco) {
            ForEach(visibili) { seg in
                TrattoGrafico(colore: seg.colore, mancante: seg.mancante)
                    .frame(width: max(MG.barraMinima, spazio * CGFloat(seg.valore / scala) - MG.stacco))
            }
        }
        .frame(height: MG.barraSpessa)
    }
}

// MARK: - (b) Barra di copertura

/// Fabbisogno contro coperto contro coperto con le proposte: il coperto pieno nel colore dell'area, la parte che
/// aggiungerebbero le proposte più chiara, la parte scoperta tratteggiata in rosso fino al segno del fabbisogno.
/// Dopo la barra la quota coperta («62%», oppure «62% → 85%» con le proposte).
struct BarraCopertura: View {
    let fabbisogno: Double
    let coperto: Double
    /// Il coperto contando anche le proposte aperte (il totale, non solo l'aggiunta); nil se non ce ne sono.
    var conProposte: Double? = nil
    var colore: Color = Tema.Colore.GraficiAnalisi.principale
    var etichettaFabbisogno: String = "Fabbisogno"
    var etichettaCoperto: String = "Coperto"
    var etichettaProposte: String = "Con le proposte"
    var etichettaScoperto: String = "Scoperto"
    var legenda: Bool = true
    var formato: (Double) -> String = { Formati.euro($0) }

    private var f: Double { max(0, fabbisogno) }
    private var c: Double { max(0, coperto) }
    private var p: Double { max(c, conProposte ?? c) }
    private var scala: Double { max(f, p, 1) }
    private var scoperto: Double { max(0, f - p) }
    private var aggiunta: Double { p - c }

    private func quota(_ v: Double) -> String {
        guard f > 0 else { return "—" }
        return "\(Int((min(v / f, 9.99) * 100).rounded(.down)))%"
    }

    private var tonoQuota: TonoCifraAnalisi {
        guard f > 0 else { return .neutro }
        if p >= f { return .positivo }
        return p >= f / 2 ? .attenzione : .negativo
    }

    private var vociLegenda: [VoceLegendaGrafico] {
        var voci = [VoceLegendaGrafico(id: "coperto", etichetta: etichettaCoperto, valore: formato(c), colore: colore)]
        if aggiunta > 0 {
            voci.append(VoceLegendaGrafico(id: "proposte", etichetta: etichettaProposte, valore: "+ " + formato(aggiunta),
                                           colore: colore.opacity(MG.opacitaProposte)))
        }
        if scoperto > 0 {
            voci.append(VoceLegendaGrafico(id: "scoperto", etichetta: etichettaScoperto, valore: formato(scoperto),
                                           colore: KG.negativo, mancante: true, coloreValore: KG.negativo))
        }
        voci.append(VoceLegendaGrafico(id: "fabbisogno", etichetta: etichettaFabbisogno, valore: formato(f),
                                       colore: KG.traguardo, traguardo: true))
        return voci
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MG.spazio) {
            GeometryReader { geo in
                area(larghezza: geo.size.width)
            }
            .frame(height: MG.rigaBarraSpessa)
            if legenda {
                LegendaGrafico(voci: vociLegenda)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func area(larghezza: CGFloat) -> some View {
        let spazio = max(0, larghezza - MG.riservaTotale)
        return ZStack(alignment: .leading) {
            HStack(spacing: MG.spazioCifra) {
                barra(spazio: spazio)
                testoQuota
                Spacer(minLength: 0)
            }
            Rectangle()
                .fill(KG.traguardo)
                .frame(width: MG.segnoTraguardo, height: MG.barraSpessa + MG.sporgenzaTraguardo * 2)
                .offset(x: spazio * CGFloat(f / scala) - MG.segnoTraguardo / 2)
        }
        .frame(width: larghezza, height: MG.rigaBarraSpessa, alignment: .leading)
    }

    private var testoQuota: some View {
        let testo = aggiunta > 0 ? "\(quota(c)) → \(quota(p))" : quota(c)
        return Text(testo)
            .font(FG.cifra)
            .foregroundColor(tonoQuota.colore)
            .lineLimit(1)
            .fixedSize()
            .help("Quota del fabbisogno coperta")
    }

    private func lunghezza(_ v: Double, _ spazio: CGFloat) -> CGFloat {
        v > 0 ? max(MG.barraMinima, spazio * CGFloat(v / scala) - MG.stacco) : 0
    }

    private func barra(spazio: CGFloat) -> some View {
        HStack(spacing: MG.stacco) {
            if c > 0 {
                TrattoGrafico(colore: colore).frame(width: lunghezza(c, spazio))
            }
            if aggiunta > 0 {
                TrattoGrafico(colore: colore.opacity(MG.opacitaProposte)).frame(width: lunghezza(aggiunta, spazio))
            }
            if scoperto > 0 {
                TrattoGrafico(colore: KG.negativo, mancante: true).frame(width: lunghezza(scoperto, spazio))
            }
        }
        .frame(height: MG.barraSpessa)
    }
}

// MARK: - (c) Cascata

/// «Da A a B»: una voce di partenza, voci che aggiungono e tolgono, un totale. Ogni gradino parte dove finisce il
/// precedente (una lineetta li raccorda). Esempi: debiti + sostegno alla famiglia − capitale disponibile =
/// fabbisogno; lordo − costi − tasse = netto. Orizzontale (righe con le cifre allineate a destra, come un conto)
/// o verticale (colonne).
struct Cascata: View {
    struct Voce: Identifiable {
        enum Tipo { case partenza, aggiunta, sottrazione, totale }

        let id: String
        let etichetta: String
        /// L'importo, sempre positivo: il segno lo dà il tipo. Per partenza e totale è il valore stesso.
        let valore: Double
        let tipo: Tipo
        /// Nil: il colore predefinito del tipo.
        var colore: Color?

        init(_ etichetta: String, _ valore: Double, tipo: Tipo, colore: Color? = nil, id: String? = nil) {
            self.id = id ?? etichetta
            self.etichetta = etichetta
            self.valore = valore
            self.tipo = tipo
            self.colore = colore
        }
    }

    enum Orientamento { case orizzontale, verticale }

    let voci: [Voce]
    var orientamento: Orientamento = .orizzontale
    var formato: (Double) -> String = { Formati.euro($0) }

    /// Un gradino: la voce, dove comincia e dove finisce sulla scala, e dove era arrivato il conto prima.
    private struct Gradino: Identifiable {
        let voce: Voce
        let inizio: Double
        let fine: Double
        let prima: Double?
        var id: String { voce.id }
        var basso: Double { min(inizio, fine) }
        var alto: Double { max(inizio, fine) }
    }

    private var gradini: [Gradino] {
        var conto = 0.0
        var esito: [Gradino] = []
        for (i, v) in voci.enumerated() {
            let prima: Double? = i == 0 ? nil : conto
            let importo = abs(v.valore)
            switch v.tipo {
            case .partenza, .totale:
                esito.append(Gradino(voce: v, inizio: 0, fine: v.valore, prima: prima))
                conto = v.valore
            case .aggiunta:
                esito.append(Gradino(voce: v, inizio: conto, fine: conto + importo, prima: prima))
                conto += importo
            case .sottrazione:
                esito.append(Gradino(voce: v, inizio: conto - importo, fine: conto, prima: prima))
                conto -= importo
            }
        }
        return esito
    }

    private static func dominio(_ g: [Gradino]) -> (basso: Double, ampiezza: Double) {
        let basso = min(0, g.map(\.basso).min() ?? 0)
        let alto = max(0, g.map(\.alto).max() ?? 0)
        return (basso, max(alto - basso, 1))
    }

    private static func colore(_ v: Voce) -> Color {
        if let c = v.colore { return c }
        switch v.tipo {
        case .partenza, .totale: return KG.cascataTotale
        case .aggiunta: return KG.cascataAggiunta
        case .sottrazione: return KG.cascataSottrazione
        }
    }

    private func cifra(_ v: Voce) -> String {
        switch v.tipo {
        case .partenza: return formato(v.valore)
        case .aggiunta: return "+ " + formato(abs(v.valore))
        case .sottrazione: return CifreDoc.meno + " " + formato(abs(v.valore))
        case .totale: return "= " + formato(v.valore)
        }
    }

    var body: some View {
        let g = gradini
        let d = Self.dominio(g)
        Group {
            switch orientamento {
            case .orizzontale: orizzontale(g, d)
            case .verticale: verticale(g, d)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Orizzontale

    private func orizzontale(_ g: [Gradino], _ d: (basso: Double, ampiezza: Double)) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(g) { gradino in
                rigaOrizzontale(gradino, d)
            }
        }
        .lineaZeroGrafico()
    }

    private func rigaOrizzontale(_ g: Gradino, _ d: (basso: Double, ampiezza: Double)) -> some View {
        let forte = g.voce.tipo == .totale
        return HStack(spacing: 0) {
            EtichettaRigaGrafico(testo: g.voce.etichetta, forte: forte)
            LineaZeroGrafico()
            GeometryReader { geo in
                gradinoOrizzontale(g, d, larghezza: geo.size.width, altezza: geo.size.height)
            }
            .frame(height: MG.rigaBarra)
            Text(cifra(g.voce))
                .font(forte ? FG.cifraTotale : FG.cifra)
                .foregroundColor(KG.cifra)
                .lineLimit(1)
                .fixedSize()
                .frame(minWidth: MG.cifraCascata, alignment: .trailing)
        }
    }

    private func gradinoOrizzontale(_ g: Gradino, _ d: (basso: Double, ampiezza: Double),
                                    larghezza: CGFloat, altezza: CGFloat) -> some View {
        let spazio = max(0, larghezza - MG.spazioCifra)
        func x(_ v: Double) -> CGFloat { spazio * CGFloat((v - d.basso) / d.ampiezza) }
        let lunghezza = max(MG.barraMinima, x(g.alto) - x(g.basso))
        return ZStack(alignment: .topLeading) {
            if let prima = g.prima {
                Rectangle()
                    .fill(KG.raccordo)
                    .frame(width: Tema.Misura.filo, height: altezza / 2)
                    .offset(x: x(prima))
            }
            TrattoGrafico(colore: Self.colore(g.voce))
                .frame(width: lunghezza, height: MG.barra)
                .offset(x: x(g.basso), y: (altezza - MG.barra) / 2)
        }
        .frame(width: larghezza, height: altezza, alignment: .topLeading)
    }

    // MARK: Verticale

    private func verticale(_ g: [Gradino], _ d: (basso: Double, ampiezza: Double)) -> some View {
        HStack(alignment: .top, spacing: MG.spazioColonne) {
            ForEach(g) { gradino in
                colonna(gradino, d)
            }
        }
    }

    private func colonna(_ g: Gradino, _ d: (basso: Double, ampiezza: Double)) -> some View {
        let forte = g.voce.tipo == .totale
        return VStack(spacing: MG.spazio) {
            Text(cifra(g.voce))
                .font(forte ? FG.cifraTotale : FG.cifraLegenda)
                .foregroundColor(KG.cifra)
                .lineLimit(1)
                .minimumScaleFactor(MG.scalaMinimaCifra)
            GeometryReader { geo in
                gradinoVerticale(g, d, larghezza: geo.size.width, altezza: geo.size.height)
            }
            .frame(height: MG.altezzaColonne)
            Text(g.voce.etichetta)
                .font(forte ? FG.etichettaTotale : FG.nota)
                .foregroundColor(KG.etichetta)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func gradinoVerticale(_ g: Gradino, _ d: (basso: Double, ampiezza: Double),
                                  larghezza: CGFloat, altezza: CGFloat) -> some View {
        func y(_ v: Double) -> CGFloat { altezza * CGFloat(1 - (v - d.basso) / d.ampiezza) }
        let colonna = min(larghezza, MG.colonnaMassima)
        let sinistra = (larghezza - colonna) / 2
        let lunghezza = max(MG.barraMinima, y(g.basso) - y(g.alto))
        return ZStack(alignment: .topLeading) {
            // Linea dello zero
            Rectangle()
                .fill(KG.zero)
                .frame(width: larghezza, height: Tema.Misura.filo)
                .offset(y: y(0))
            if let prima = g.prima {
                Rectangle()
                    .fill(KG.raccordo)
                    .frame(width: sinistra + MG.spazioColonne, height: Tema.Misura.filo)
                    .offset(x: -MG.spazioColonne, y: y(prima))
            }
            TrattoGrafico(colore: Self.colore(g.voce))
                .frame(width: colonna, height: lunghezza)
                .offset(x: sinistra, y: y(g.alto))
        }
        .frame(width: larghezza, height: altezza, alignment: .topLeading)
    }
}

// MARK: - (d) Barre a confronto

/// Due o tre valori sulla stessa scala che parte da zero, come le strade del TFR: il nome a sinistra, la barra, la
/// cifra subito dopo e la differenza dal primo valore in capsula nel colore del segno.
/// Esempio: capitale oggi / dopo il calo dei mercati (`maggioreMeglio: true`, la differenza è rossa).
struct BarreConfronto: View {
    struct Voce: Identifiable {
        let id: String
        let etichetta: String
        let valore: Double
        let colore: Color

        init(_ etichetta: String, _ valore: Double, colore: Color, id: String? = nil) {
            self.id = id ?? etichetta
            self.etichetta = etichetta
            self.valore = valore
            self.colore = colore
        }
    }

    let voci: [Voce]
    /// La differenza dal primo valore accanto alle altre barre.
    var differenze: Bool = true
    /// False per le grandezze in cui di meno è meglio (costi, divario): la differenza negativa diventa verde.
    var maggioreMeglio: Bool = true
    var aiutoDifferenza: String? = nil
    var formato: (Double) -> String = { Formati.euro($0) }
    var formatoDifferenza: (Double) -> String = { CifreDoc.euroSegno($0) }

    private var massimo: Double { max(voci.map(\.valore).max() ?? 0, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(voci.enumerated()), id: \.element.id) { i, v in
                riga(v, differenza: i > 0 && differenze ? v.valore - (voci.first?.valore ?? 0) : nil)
            }
        }
        .lineaZeroGrafico()
        .accessibilityElement(children: .combine)
    }

    private func riga(_ v: Voce, differenza: Double?) -> some View {
        HStack(spacing: 0) {
            EtichettaRigaGrafico(testo: v.etichetta)
            LineaZeroGrafico()
            GeometryReader { geo in
                area(v, differenza: differenza, larghezza: geo.size.width, altezza: geo.size.height)
            }
            .frame(height: MG.rigaBarra)
        }
    }

    private func area(_ v: Voce, differenza: Double?, larghezza: CGFloat, altezza: CGFloat) -> some View {
        let spazio = max(0, larghezza - MG.riservaCifra)
        let lunghezza = max(MG.barraMinima, spazio * CGFloat(max(0, v.valore) / massimo))
        return HStack(spacing: MG.spazioCifra) {
            TrattoGrafico(colore: v.colore)
                .frame(width: lunghezza, height: MG.barra)
            Text(formato(v.valore))
                .font(FG.cifra)
                .foregroundColor(KG.cifra)
                .lineLimit(1)
                .fixedSize()
            if let d = differenza {
                CapsulaDifferenza(testo: formatoDifferenza(d), tono: .segno(d, maggioreMeglio: maggioreMeglio),
                                  aiuto: aiutoDifferenza)
            }
            Spacer(minLength: 0)
        }
        .frame(width: larghezza, height: altezza, alignment: .leading)
    }
}

// MARK: - (e) Tessera con una cifra

/// Una tessera di vetro: etichetta, cifra grande nel colore del tono, una riga breve sotto. Niente è troncato:
/// l'etichetta e la riga vanno a capo, la cifra si rimpicciolisce un poco se lo spazio è stretto.
/// `evidenziata` stende la tinta del tono sulla tessera (il vantaggio, l'allarme). La spiegazione lunga va in `aiuto`.
struct TesseraCifraAnalisi: View {
    let titolo: String
    let valore: String
    var nota: String? = nil
    var tono: TonoCifraAnalisi = .neutro
    var evidenziata: Bool = false
    var aiuto: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: MG.spazioTessera) {
            Text(titolo)
                .font(FG.titoloTessera)
                .foregroundColor(KG.nota)
                .fixedSize(horizontal: false, vertical: true)
            Text(valore)
                .font(FG.valoreTessera)
                .tracking(FG.spaziaturaValore)
                .foregroundColor(tono.colore)
                .lineLimit(1)
                .minimumScaleFactor(MG.scalaMinimaCifra)
            if let nota {
                Text(nota)
                    .font(FG.notaTessera)
                    .foregroundColor(KG.nota)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Tema.Misura.Componenti.tessera)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .vetro(.sottile, forma: .arrotondata(Tema.Raggio.tessera), tinta: evidenziata ? tono.tinta : nil)
        .aiutoGrafico(aiuto)
        .accessibilityElement(children: .combine)
    }
}
