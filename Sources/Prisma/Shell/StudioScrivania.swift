import SwiftUI

// Il riquadro «Il tuo studio · <mese>» della scrivania (versione «Orizzonte», Design/template-novita-specifica.md
// §1.5, §2.4, §3.3): sul Mac al posto di «Da fare oggi», in basso a sinistra accanto a «In scadenza entro 90 giorni».
//
//   ◎◎◎  Il tuo studio · novembre                                   Apri Studio
//        Ricavi del mese     Da incassare     Obiettivo consulenza
//        6.240 €             1.650 €          77%
//
// - Tre anelli concentrici (116, tratto 11) degli obiettivi dell'anno: produzione Alleanza (#2563EB), nuovi clienti
//   (#30B15C), ricavi della consulenza (#B06E12), fissi in chiaro e in scuro. Un obiettivo senza traguardo resta solo
//   binario: niente anelli finti. Partono dopo i tre del portafoglio (+3 passi di 0,13 s).
// - Le cifre vengono da MotoreStudio (cache di StatoShell) e contano come quelle della scrivania (indici 2, 3, 4).
//   «Ricavi del mese»: provvigioni stimate dalle aliquote più parcelle del mese; senza aliquote né parcelle «—».
//   «Da incassare»: le parcelle non ancora incassate (0 € finché Parcelle e fatture non c'è). «Obiettivo consulenza»:
//   la quota dei ricavi della consulenza sul traguardo; senza traguardo «—».
// - Un clic in qualunque punto (anche su «Apri Studio») apre Studio › Cruscotto. In modalità cliente le cifre dello
//   studio non si mostrano.

struct RiquadroStudioScrivania: View {
    @EnvironmentObject var stato: StatoShell
    let pronto: Bool
    let ritardoAnelli: Double
    /// L'altezza della riga: sugli schermi bassi gli anelli si stringono per restare nel riquadro.
    let altezza: CGFloat

    var body: some View {
        let s = Tema.Apple.Studio.Scrivania.self
        let r = Tema.Apple.Scrivania.Riquadro.self
        let lato = min(s.anelli, max(s.anelliMinimi, altezza - r.padding.top - r.padding.bottom))
        CorpoStudioScrivania(stato: stato, chiave: stato.chiaveVista, pronto: pronto,
                             ritardoAnelli: ritardoAnelli + Double(s.anelliPrima) * Tema.Apple.Moto.Anello.passo,
                             latoAnelli: lato)
            .equatable()
            .riquadroScrivania(apre: { stato.apriStudio(.cruscotto) })
    }
}

private struct CorpoStudioScrivania: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    let pronto: Bool
    let ritardoAnelli: Double
    let latoAnelli: CGFloat

    nonisolated static func == (a: CorpoStudioScrivania, b: CorpoStudioScrivania) -> Bool {
        a.chiave == b.chiave && a.pronto == b.pronto && a.ritardoAnelli == b.ritardoAnelli && a.latoAnelli == b.latoAnelli
    }

    var body: some View {
        let s = Tema.Apple.Studio.Scrivania.self
        let riservato = chiave.modo != nil
        // Dalla cache del motore (una volta per versione dei calcoli e per giorno)
        let c = stato.cruscottoStudio()
        let prova = stato.haDatiDiProva
        let mese = Calendar.current.component(.month, from: c.oggi)
        return HStack(alignment: .center, spacing: s.spazio) {
            anelli(c, riservato: riservato)
            VStack(alignment: .leading, spacing: 0) {
                testata(c, prova: prova && !riservato)
                if riservato {
                    Text(TestiStudio.testoRiservato)
                        .carattereApple(s.nota)
                        .foregroundColor(s.coloreNota)
                        .lineLimit(2)
                        .padding(.top, s.cifreSopra)
                } else {
                    HStack(alignment: .top, spacing: s.spazioCifre) {
                        cifraRicavi(c, mese: mese)
                        cifraDaIncassare
                        cifraObiettivo(c)
                    }
                    .padding(.top, s.cifreSopra)
                    if let nota = Self.nota(c) {
                        Text(nota)
                            .carattereApple(s.nota)
                            .foregroundColor(s.coloreNota)
                            .lineLimit(1)
                            .minimumScaleFactor(Tema.Apple.Studio.Card.riduzioneTesto)
                            .padding(.top, s.notaSopra)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: Anelli

    @ViewBuilder private func anelli(_ c: CruscottoStudio, riservato: Bool) -> some View {
        let s = Tema.Apple.Studio.Scrivania.self
        // Lo spessore resta in proporzione (11 su 116)
        let spessore = s.spessore * latoAnelli / s.anelli
        if pronto {
            AnelliConcentrici(voci: Self.voci(c, riservato: riservato), misura: latoAnelli, spessore: spessore,
                              ritardo: ritardoAnelli)
        } else {
            Color.clear.frame(width: latoAnelli, height: latoAnelli)
        }
    }

    /// Sempre i tre anelli, dall'esterno; un obiettivo senza traguardo (o in modalità cliente) resta solo binario.
    private static func voci(_ c: CruscottoStudio, riservato: Bool) -> [VoceAnello] {
        VoceObiettivoStudio.allCases.map { v in
            let frazione = riservato ? 0 : (c.obiettivi.voce(v)?.frazioneAnello ?? 0)
            return VoceAnello(id: v.rawValue, valore: frazione, massimo: 1, colore: Tema.Apple.Studio.colore(v))
        }
    }

    // MARK: Testata

    private func testata(_ c: CruscottoStudio, prova: Bool) -> some View {
        let s = Tema.Apple.Studio.Scrivania.self
        let card = Tema.Apple.Studio.Card.self
        return HStack(alignment: .firstTextBaseline, spacing: card.spazioProva) {
            Text("Il tuo studio · \(TestiStudio.mese(c.oggi))")
                .carattereApple(s.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .layoutPriority(1)
            if prova {
                Text(TestiStudio.datiDiProva)
                    .carattereApple(card.prova)
                    .foregroundColor(card.coloreProva)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            // Solo un'etichetta, come nel template: il clic sul riquadro fa lo stesso
            Button { stato.apriStudio(.cruscotto) } label: {
                Text("Apri Studio")
                    .carattereApple(s.collegamento)
                    .foregroundColor(s.coloreCollegamento)
                    .lineLimit(1)
            }
            .buttonStyle(StileSemplice())
        }
    }

    // MARK: Le tre cifre

    private func cifra<V: View>(_ etichetta: String, colore: Color, @ViewBuilder valore: () -> V) -> some View {
        let s = Tema.Apple.Studio.Scrivania.self
        return VStack(alignment: .leading, spacing: 0) {
            Text(etichetta)
                .carattereApple(s.etichetta)
                .foregroundColor(s.coloreEtichetta)
                .lineLimit(1)
            valore()
                .carattereApple(s.cifra)
                .foregroundColor(colore)
                .lineLimit(1)
                .minimumScaleFactor(s.riduzioneCifra)
        }
    }

    /// Provvigioni stimate più parcelle del mese; senza aliquote né parcelle Prisma non sa niente: «—».
    private func cifraRicavi(_ c: CruscottoStudio, mese: Int) -> some View {
        let s = Tema.Apple.Studio.Scrivania.self
        let ignoti = c.ricavi.mancaAliquote && c.ricavi.nessunaParcella
        let valore = c.ricavi.perMese.indices.contains(mese - 1) ? c.ricavi.perMese[mese - 1] : 0
        return cifra("Ricavi del mese", colore: s.coloreCifra) {
            if ignoti {
                Text(verbatim: "—")
            } else {
                CifraScrivania(valore: valore, formato: .euro, indice: 2, pronto: pronto)
            }
        }
    }

    /// Le parcelle non ancora incassate (in questo giro non ce ne sono: 0 €).
    private var cifraDaIncassare: some View {
        let s = Tema.Apple.Studio.Scrivania.self
        let daIncassare = stato.ricaviConsulenzaStudio.filter { !$0.incassata }.reduce(0) { $0 + $1.importo }
        return cifra("Da incassare", colore: daIncassare > 0 ? s.coloreDaIncassare : s.coloreCifra) {
            CifraScrivania(valore: daIncassare, formato: .euro, indice: 3, pronto: pronto)
        }
    }

    /// Ricavi della consulenza sul traguardo dell'anno (anche oltre il 100%); senza traguardo «—».
    private func cifraObiettivo(_ c: CruscottoStudio) -> some View {
        let s = Tema.Apple.Studio.Scrivania.self
        let frazione = c.obiettivi.voce(.ricaviConsulenza)?.frazione
        return cifra("Obiettivo consulenza", colore: s.coloreCifra) {
            if let f = frazione {
                CifraScrivania(valore: (f * 100).rounded(), formato: .percentuale, indice: 4, pronto: pronto)
            } else {
                Text(verbatim: "—")
            }
        }
    }

    /// Una riga sotto le cifre quando manca qualcosa: le aliquote, gli obiettivi.
    private static func nota(_ c: CruscottoStudio) -> String? {
        var parti: [String] = []
        if c.mancaAliquote { parti.append("Ricavi: " + TestiStudio.senzaAliquoteScrivania) }
        if c.obiettivi.nessunoImpostato { parti.append(TestiStudio.obiettiviScrivania) }
        return parti.isEmpty ? nil : parti.joined(separator: " · ")
    }
}
