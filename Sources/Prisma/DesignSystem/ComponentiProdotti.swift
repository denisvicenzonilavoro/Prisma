import SwiftUI

// MARK: - Token della scheda prodotto (app Prodotti)

extension Tema.Colore {
    /// Scheda prodotto nel tema Apple: scala del rischio e peso dei costi.
    enum Prodotti {
        /// Caselle della scala SRI: accese fino alla classe del prodotto, spente oltre (`binario`).
        static let rischioAcceso = Tema.Apple.Colore.accento
        static let rischioSpento = Tema.Apple.Colore.binario
        /// Peso dei costi: versato, guadagno netto (il colore dell'area lo passa la scheda) e costi.
        static let versato = Tema.Apple.Colore.Composizione.liquidita
        static let costi = Tema.Apple.Colore.arancio
        /// Testi delle tessere.
        static let testo = Tema.Apple.Colore.inchiostro
        static let secondario = Tema.Apple.Colore.inchiostro2
    }
}

extension Tema.Testo {
    /// Scheda prodotto nel tema Apple: etichetta `.k`, valore 22 bold, note 12, legenda.
    enum Prodotti {
        static let etichetta = Tema.Apple.Carattere.secondario.fontLeggibile
        static let valore = Tema.Apple.AltreApp.cifraPiccola
        static let nota = Tema.Apple.AltreApp.nota.fontLeggibile
        static let legenda = Tema.Apple.AltreApp.nota.fontLeggibile
        static let cifraLegenda = Tema.Apple.Carattere(dimensione: 12, peso: .semibold, tabellare: true).fontLeggibile
    }
}

extension Tema.Misura {
    /// Scheda prodotto: tessere in testa e grafico del peso dei costi.
    enum Prodotti {
        static let altezzaCasellaRischio: CGFloat = 7
        static let spazioCaselleRischio: CGFloat = 3
        static let spazioTessera: CGFloat = 4
        static let altezzaBarraCosti: CGFloat = 14
        static let spazioSegmenti: CGFloat = 2
        static let spazioGrafico: CGFloat = 10
        static let spazioCarta: CGFloat = 22
        static let larghezzaCifra: CGFloat = 200
        static let spazioLegenda: CGFloat = 16
        static let spazioVoceLegenda: CGFloat = 6
        static let pallinoLegenda: CGFloat = 8
    }
}

extension Tema.Raggio {
    enum Prodotti {
        static let segmentoCosti: CGFloat = Tema.Apple.Raggio.bollaPiccola
    }
}

// MARK: - Tessera del rischio

/// Tessera del rischio (SRI): la classe in grande, a parole, e la scala da 1 a 7 accesa fino alla classe.
struct TesseraRischio: View {
    let sri: Int?

    /// La classe come la scrive il KID.
    static func descrizione(_ sri: Int?) -> String {
        switch sri {
        case 1: return "molto basso"
        case 2: return "basso"
        case 3: return "medio-basso"
        case 4: return "medio"
        case 5: return "medio-alto"
        case 6: return "alto"
        case 7: return "molto alto"
        default: return "non indicato"
        }
    }

    var body: some View {
        let m = Tema.Misura.Prodotti.self
        VStack(alignment: .leading, spacing: m.spazioTessera) {
            EtichettaConTermine(testo: "Rischio (SRI)", font: Tema.Testo.Prodotti.etichetta,
                                colore: Tema.Colore.Prodotti.secondario, righe: 2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .firstTextBaseline, spacing: m.spazioTessera) {
                Group {
                    if let sri {
                        NumeroCheConta(Double(sri), formato: .intero, indice: 3)
                    } else {
                        Text("—")
                    }
                }
                .carattereApple(Tema.Testo.Prodotti.valore)
                .foregroundColor(Tema.Colore.Prodotti.testo)
                Text(sri == nil ? "non indicato" : "su 7 · \(Self.descrizione(sri))")
                    .font(Tema.Testo.Prodotti.nota)
                    .foregroundColor(Tema.Colore.Prodotti.secondario)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            scala
        }
        .padding(Tema.Apple.Misura.Padding.tile)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(Tema.Apple.Superficie.tile)
        .accessibilityElement(children: .combine)
    }

    private var scala: some View {
        let m = Tema.Misura.Prodotti.self
        let classe = sri ?? 0
        return HStack(spacing: m.spazioCaselleRischio) {
            ForEach(1...7, id: \.self) { i in
                // Le caselle accese si riempiono una dopo l'altra (BarraPiena; ferme nello stato finale)
                BarraPiena(frazione: i <= classe ? 1 : 0, colore: Tema.Colore.Prodotti.rischioAcceso, indice: i - 1,
                           altezza: m.altezzaCasellaRischio, raggio: m.altezzaCasellaRischio / 2,
                           binario: Tema.Colore.Prodotti.rischioSpento)
            }
        }
        .padding(.top, m.spazioTessera)
    }
}

// MARK: - Peso dei costi

/// Il peso dei costi su un esempio: la cifra che resta in grande e una barra divisa in versato,
/// guadagno netto e costi, con la legenda in cifre.
struct PesoCostiProdotto: View {
    let titolo: String
    let versato: Double
    let netto: Double
    let costi: Double
    let coloreGuadagno: Color

    private struct Segmento: Identifiable {
        let id: String
        let valore: Double
        let colore: Color
    }

    /// Il guadagno che il prodotto darebbe senza costi.
    private var guadagnoSenzaCosti: Double { netto + costi - versato }

    /// La parte di quel guadagno che si prendono i costi (nil se non c'è guadagno).
    private var quotaCosti: Double? {
        guard costi > 0, guadagnoSenzaCosti > 0 else { return nil }
        return min(costi / guadagnoSenzaCosti, 1)
    }

    private var segmenti: [Segmento] {
        let c = Tema.Colore.Prodotti.self
        return [Segmento(id: "versato", valore: max(min(netto, versato), 0), colore: c.versato),
                Segmento(id: "guadagno", valore: max(netto - versato, 0), colore: coloreGuadagno),
                Segmento(id: "costi", valore: max(costi, 0), colore: c.costi)]
            .filter { $0.valore > 0 }
    }

    var body: some View {
        let m = Tema.Misura.Prodotti.self
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: m.spazioCarta) {
                cifra.frame(width: m.larghezzaCifra, alignment: .leading)
                grafico
            }
            VStack(alignment: .leading, spacing: m.spazioGrafico) {
                cifra
                grafico
            }
        }
        .padding(Tema.Apple.Misura.Padding.tile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Superficie.tile)
        .help("Stima su un versamento unico, dopo costi e imposte: i costi sono la differenza con lo stesso prodotto senza costi")
    }

    private var cifra: some View {
        VStack(alignment: .leading, spacing: Tema.Misura.Prodotti.spazioTessera) {
            Text(titolo)
                .font(Tema.Testo.Prodotti.etichetta)
                .foregroundColor(Tema.Colore.Prodotti.secondario)
                .lineLimit(1)
            // La cifra del motore (MotoreProiezione) si conta fino al valore
            NumeroCheConta(netto, formato: .personalizzato(Formati.euro), indice: 5)
                .carattereApple(Tema.Testo.Prodotti.valore)
                .foregroundColor(Tema.Colore.Prodotti.testo)
                .lineLimit(1)
            Text(quotaCosti.map { "i costi si prendono il \(Formati.percentuale(($0 * 100).rounded())) del guadagno" } ?? "dopo costi e imposte")
                .font(Tema.Testo.Prodotti.nota)
                .foregroundColor(Tema.Colore.Prodotti.secondario)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var grafico: some View {
        let m = Tema.Misura.Prodotti.self
        return VStack(alignment: .leading, spacing: m.spazioGrafico) {
            barra
            ViewThatFits(in: .horizontal) {
                HStack(spacing: m.spazioLegenda) { voci }
                VStack(alignment: .leading, spacing: m.spazioVoceLegenda) { voci }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Versato, guadagno e costi: i pezzi si riempiono uno dopo l'altro (`BarraPienaSegmenti`).
    private var barra: some View {
        let m = Tema.Misura.Prodotti.self
        let pezzi = segmenti.map { PezzoBarraPiena(id: $0.id, peso: $0.valore, colore: $0.colore) }
        return BarraPienaSegmenti(pezzi: pezzi, indice: 0, altezza: m.altezzaBarraCosti, spazio: m.spazioSegmenti,
                                  raggioPezzo: Tema.Raggio.Prodotti.segmentoCosti,
                                  raggioContenitore: Tema.Raggio.Prodotti.segmentoCosti)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var voci: some View {
        let c = Tema.Colore.Prodotti.self
        voce(c.versato, "Versati", Formati.euro(versato))
        voce(coloreGuadagno, "Guadagno netto", Formati.euro(netto - versato))
        voce(c.costi, "Costi", Formati.euro(costi))
    }

    private func voce(_ colore: Color, _ etichetta: String, _ valore: String) -> some View {
        let m = Tema.Misura.Prodotti.self
        return HStack(spacing: m.spazioVoceLegenda) {
            Circle().fill(colore).frame(width: m.pallinoLegenda, height: m.pallinoLegenda)
            Text(etichetta)
                .font(Tema.Testo.Prodotti.legenda)
                .foregroundColor(Tema.Colore.Prodotti.secondario)
            Text(valore)
                .font(Tema.Testo.Prodotti.cifraLegenda)
                .foregroundColor(Tema.Colore.Prodotti.testo)
        }
        .lineLimit(1)
        .fixedSize()
    }
}
