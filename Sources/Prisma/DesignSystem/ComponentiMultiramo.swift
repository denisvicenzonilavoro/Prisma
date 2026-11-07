import SwiftUI

// MARK: - Barra della composizione di una multiramo

/// La barra a due colori di una multiramo: gestione separata e fondi, larghi come le quote, staccati e
/// arrotondati come la barra dei canali. Sopra, se richiesto, le etichette «Gestione separata 40% · 24.800 €»
/// e «Fondi 60% · 37.200 €».
struct BarraComposizione: View {
    /// Quota (0–1) in gestione separata.
    let gestione: Double
    /// Euro della parte in gestione separata e dei fondi (nil: solo le quote).
    var euroGestione: Double? = nil
    var euroFondi: Double? = nil
    /// false: solo la barra (per esempio sotto il cursore della quota, che ha già il suo riepilogo).
    var conEtichette = true

    private typealias M = Tema.Misura.Multiramo
    private typealias C = Tema.Colore.Multiramo

    private var quotaLimitata: Double { min(max(gestione, 0), 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: M.spazioBarra) {
            if conEtichette {
                HStack(alignment: .firstTextBaseline, spacing: M.spazioRiga) {
                    etichetta(C.gestione, "Gestione separata", quotaLimitata, euroGestione)
                    Spacer(minLength: M.spazioRiga)
                    etichetta(C.fondi, "Fondi", 1 - quotaLimitata, euroFondi)
                }
            }
            barra
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gestione separata \(Self.percento(quotaLimitata)), fondi \(Self.percento(1 - quotaLimitata))")
    }

    private var barra: some View {
        GeometryReader { geo in
            let q = quotaLimitata
            let stacco: CGFloat = (q > 0 && q < 1) ? M.staccoBarra : 0
            let utile = max(0, geo.size.width - stacco)
            HStack(spacing: stacco) {
                if q > 0 {
                    RoundedRectangle(cornerRadius: M.raggioBarra, style: .continuous)
                        .fill(C.gestione)
                        .frame(width: q < 1 ? utile * CGFloat(q) : utile)
                }
                if q < 1 {
                    RoundedRectangle(cornerRadius: M.raggioBarra, style: .continuous)
                        .fill(C.fondi)
                }
            }
        }
        .frame(height: M.barra)
    }

    private func etichetta(_ colore: Color, _ nome: String, _ q: Double, _ euro: Double?) -> some View {
        HStack(alignment: .center, spacing: M.spazioEtichetta * 2) {
            Circle()
                .fill(colore)
                .frame(width: M.pallino, height: M.pallino)
            Text("\(nome) \(Self.percento(q))" + (euro.map { " · \(Formati.euro($0))" } ?? ""))
                .font(Tema.Testo.Multiramo.barra)
                .foregroundColor(C.testoBarra)
                .lineLimit(1)
        }
    }

    /// "40%": la quota (0–1) in percentuale.
    static func percento(_ q: Double) -> String { Formati.percentuale(q * 100) }
}

/// Il pallino del colore di una parte con il suo nome: testata delle colonne e legende.
struct PallinoParte: View {
    let colore: Color
    let testo: String

    var body: some View {
        HStack(alignment: .center, spacing: Tema.Misura.Multiramo.spazioEtichetta * 2) {
            Circle()
                .fill(colore)
                .frame(width: Tema.Misura.Multiramo.pallino, height: Tema.Misura.Multiramo.pallino)
            Text(testo)
                .font(Tema.Testo.Multiramo.testataColonna)
                .foregroundColor(Tema.Colore.inchiostro)
        }
    }
}

// MARK: - Lordo → netto

/// Il rendimento di una parte a colpo d'occhio: «3,00% → 1,70%» con sotto la barra del lordo, piena del
/// colore della parte per quanto va al cliente e chiara per quanto va in costi.
struct TrattoRendimento: View {
    let lordo: Double
    let netto: Double
    let colore: Color
    /// Didascalia sotto la barra: «trattenuto 1,30 punti», «costi 2,30%».
    let costo: String
    /// Il lordo più alto tra le parti mostrate, perché le barre si confrontino (nil: la barra è piena).
    var scala: Double? = nil
    /// Didascalia del netto: «al cliente» (gestione separata) o «netto» (fondi).
    var nomeNetto = "al cliente"

    private typealias M = Tema.Misura.Multiramo
    private typealias C = Tema.Colore.Multiramo
    private typealias T = Tema.Testo.Multiramo

    var body: some View {
        VStack(alignment: .leading, spacing: M.spazioBarra) {
            HStack(alignment: .lastTextBaseline, spacing: M.spazioFreccia) {
                cifra(TrattoRendimento.percento(lordo), "lordo", font: T.cifraLordo, colore: C.didascalia)
                Image(systemName: "arrow.right")
                    .font(T.freccia)
                    .foregroundColor(C.didascalia)
                cifra(TrattoRendimento.percento(netto), nomeNetto, font: T.cifraGrande, colore: netto < 0 ? C.negativo : C.cifra)
            }
            barra
            Text(costo)
                .font(T.didascalia)
                .foregroundColor(C.didascalia)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rendimento lordo \(TrattoRendimento.percento(lordo)), \(nomeNetto) \(TrattoRendimento.percento(netto)), \(costo)")
    }

    private func cifra(_ valore: String, _ didascalia: String, font: Font, colore: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(valore)
                .font(font)
                .foregroundColor(colore)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(didascalia)
                .font(T.didascalia)
                .foregroundColor(C.didascalia)
                .lineLimit(1)
        }
    }

    /// Binario della scala, tratto del lordo (chiaro) e, sopra, quanto va al cliente (pieno).
    private var barra: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let fondo = max(scala ?? max(lordo, netto), max(lordo, netto), 0.000_1)
            let l = CGFloat(max(lordo, 0) / fondo) * w
            let n = CGFloat(max(netto, 0) / fondo) * w
            ZStack(alignment: .leading) {
                Capsule().fill(C.binario)
                Capsule().fill(colore.opacity(M.opacitaCosto)).frame(width: l)
                Capsule().fill(colore).frame(width: n)
            }
        }
        .frame(height: M.barraRendimento)
    }

    /// "3,00%"
    static func percento(_ v: Double) -> String { CifreDoc.percento(v, decimali: 2) }
}

// MARK: - Gettoni

/// Un gettone in capsula con icona: garanzia, consolidamento, ribilanciamento, azioni, volatilità. La
/// spiegazione sta nel tooltip.
struct GettoneMultiramo: View {
    enum Tono { case ok, attenzione, neutro }

    let icona: String
    let testo: String
    var tono: Tono = .neutro
    /// Spiegazione nel tooltip (nil: nessuna).
    var aiuto: String? = nil

    private typealias M = Tema.Misura.Multiramo
    private typealias C = Tema.Colore.Multiramo
    private typealias T = Tema.Testo.Multiramo

    private var coloreIcona: Color {
        switch tono {
        case .ok: return C.gettoneOk
        case .attenzione: return C.gettoneAttenzione
        case .neutro: return C.gettoneNeutro
        }
    }

    var body: some View {
        HStack(spacing: M.spazioIconaGettone) {
            Image(systemName: icona)
                .font(T.iconaGettone)
                .foregroundColor(coloreIcona)
            Text(testo)
                .font(T.gettone)
                .foregroundColor(C.testoGettone)
                .lineLimit(1)
        }
        .padding(.horizontal, M.margineGettone)
        .frame(height: M.gettone)
        .background { FormaVetro.capsula.fill(C.fondoGettone) }
        .fixedSize()
        .help(aiuto ?? testo)
    }
}

// MARK: - Tessera con una cifra

/// Una cifra in una tessera di vetro, con il colore che serve (per esempio rosso se in perdita), un'icona
/// facoltativa e una nota breve sotto. La «i» del glossario accanto al titolo la mette l'etichetta.
struct TesseraCifra: View {
    let titolo: String
    let valore: String
    var nota: String? = nil
    var colore: Color = Tema.Colore.Multiramo.cifra
    var icona: String? = nil

    private typealias M = Tema.Misura.Multiramo
    private typealias T = Tema.Testo.Multiramo

    var body: some View {
        VStack(alignment: .leading, spacing: M.spazioEtichetta) {
            EtichettaConTermine(testo: titolo, font: Tema.Testo.secondario, colore: Tema.Colore.inchiostroSecondario, righe: 2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .firstTextBaseline, spacing: M.spazioIconaGettone) {
                if let icona {
                    Image(systemName: icona).font(T.freccia)
                }
                Text(valore)
                    .font(T.cifraTessera)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundColor(colore)
            if let nota {
                Text(nota)
                    .font(T.didascalia)
                    .foregroundColor(Tema.Colore.Multiramo.didascalia)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(M.margineTessera)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .vetro(.sottile, forma: .arrotondata(M.raggioTessera))
    }
}

// MARK: - Barra di una quota

/// Una quota (0–1) come barra sottile sul binario: le righe della media ponderata.
struct BarraQuotaMultiramo: View {
    let quota: Double
    let colore: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Tema.Colore.Multiramo.binario)
                Capsule().fill(colore).frame(width: geo.size.width * CGFloat(min(max(quota, 0), 1)))
            }
        }
        .frame(height: Tema.Misura.Multiramo.barraMediaVisiva)
    }
}
