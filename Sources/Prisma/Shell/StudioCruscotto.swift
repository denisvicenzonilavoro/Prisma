import SwiftUI

// Studio › Cruscotto (Design/template-novita-specifica.md §2, template `studioHTML()` ramo cruscotto):
//
//   ┌── I tuoi ricavi 2026 ──┐┌─ Gli obiettivi dell'anno ─┐┌─ L'imbuto delle proposte ─┐   300
//   ┌──── Gli incassi dei prossimi 12 mesi ────┐┌──── Il valore e il tempo ────┐            338
//
// - Le cinque card in proporzione allo spazio che c'è (560 : 408 : 384 e 760 : 608, alte 300 e 338 su 654), 16 fra
//   loro; sotto i 900 di larghezza vanno in colonna. Card del tema con l'ombra, raggio 22, padding 22×24: entrano a
//   cascata (base 0,14 all'apertura, 0 al cambio di scheda) e si inclinano appena verso il puntatore (solo la card
//   sotto il puntatore).
// - Le cifre vengono tutte da MotoreStudio (`StatoShell.cruscottoStudio()`, in cache): numeri che si contano, anelli che
//   si riempiono, linee che si disegnano, barre e colonne che crescono, punti che compaiono.
// - Niente cifre inventate: senza aliquote la parte Alleanza dice «Inserisci le tue aliquote» (pulsante per
//   Impostazioni › Studio), senza obiettivi niente anelli ma «Imposta gli obiettivi», senza parcelle la parte
//   indipendente dice che arrivano con Parcelle e fatture. Con i clienti di prova ogni card porta «dati di prova».

struct CruscottoStudioVista: View {
    let stato: StatoShell
    /// La base della cascata (0,14 all'apertura, 0 dopo un cambio di scheda).
    let base: Double
    /// Il ritardo del primo anello degli obiettivi (0,32 all'apertura, 0,15 dopo un cambio di scheda).
    let ritardoAnelli: Double

    var body: some View {
        // Dalla cache del motore (calcolato una volta per versione dei calcoli e per giorno), mai qui
        let c = stato.cruscottoStudio()
        let prova = stato.haDatiDiProva
        return GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                griglia(c, prova: prova, misura: geo.size)
            }
        }
    }

    // MARK: Griglia

    @ViewBuilder private func griglia(_ c: CruscottoStudio, prova: Bool, misura: CGSize) -> some View {
        let d = Tema.Apple.Studio.Disposizione.self
        if misura.width < d.larghezzaColonna {
            VStack(alignment: .leading, spacing: d.spazio) {
                ricavi(c, prova: prova).frame(height: d.rigaAlta)
                obiettivi(c, prova: prova).frame(height: d.rigaAlta)
                imbuto(c, prova: prova).frame(height: d.rigaAlta)
                incassi(c, prova: prova).frame(height: d.rigaBassa)
                valoreTempo(c, prova: prova).frame(height: d.rigaBassa)
            }
            .frame(width: misura.width, alignment: .topLeading)
        } else {
            let disponibile = max(0, misura.height - d.spazio)
            let quotaAlta = d.rigaAlta / (d.rigaAlta + d.rigaBassa)
            let alta = max(d.rigaAltaMinima, disponibile * quotaAlta)
            let bassa = max(d.rigaBassaMinima, disponibile - alta)
            let alte = Self.larghezze(misura.width, quote: d.quoteRigaAlta, spazio: d.spazio)
            let basse = Self.larghezze(misura.width, quote: d.quoteRigaBassa, spazio: d.spazio)
            VStack(alignment: .leading, spacing: d.spazio) {
                HStack(alignment: .top, spacing: d.spazio) {
                    ricavi(c, prova: prova).frame(width: alte[0], height: alta)
                    obiettivi(c, prova: prova).frame(width: alte[1], height: alta)
                    imbuto(c, prova: prova).frame(width: alte[2], height: alta)
                }
                HStack(alignment: .top, spacing: d.spazio) {
                    incassi(c, prova: prova).frame(width: basse[0], height: bassa)
                    valoreTempo(c, prova: prova).frame(width: basse[1], height: bassa)
                }
            }
            .frame(width: misura.width, alignment: .topLeading)
        }
    }

    /// Le larghezze delle card di una riga, in proporzione alle quote del template.
    private static func larghezze(_ totale: CGFloat, quote: [CGFloat], spazio: CGFloat) -> [CGFloat] {
        let somma = quote.reduce(0, +)
        let libero = max(0, totale - spazio * CGFloat(max(quote.count - 1, 0)))
        return quote.map { somma > 0 ? libero * $0 / somma : 0 }
    }

    // MARK: Le cinque card

    private func ricavi(_ c: CruscottoStudio, prova: Bool) -> some View {
        CardRicaviStudio(ricavi: c.ricavi, annoPrima: c.annoPrecedente, variazione: c.variazione, primoAnno: c.primoAnno,
                         prova: prova, apriAliquote: { stato.apriImpostazioniStudio() })
            .cardStudio(0, base: base)
    }

    private func obiettivi(_ c: CruscottoStudio, prova: Bool) -> some View {
        CardObiettiviStudio(obiettivi: c.obiettivi, prova: prova, ritardoAnelli: ritardoAnelli,
                            imposta: { stato.apriImpostazioniStudio() })
            .cardStudio(1, base: base)
    }

    private func imbuto(_ c: CruscottoStudio, prova: Bool) -> some View {
        CardImbutoStudio(imbuto: c.imbuto, prova: prova)
            .cardStudio(2, base: base)
    }

    private func incassi(_ c: CruscottoStudio, prova: Bool) -> some View {
        CardIncassiStudio(incassi: c.incassi, prova: prova, apriAliquote: { stato.apriImpostazioniStudio() })
            .cardStudio(3, base: base)
    }

    private func valoreTempo(_ c: CruscottoStudio, prova: Bool) -> some View {
        CardValoreTempoStudio(valore: c.valoreTempo, mancaAliquote: c.mancaAliquote, prova: prova,
                              apri: { id in stato.apriCliente(id) })
            .cardStudio(4, base: base)
    }
}

// MARK: - Cornice comune

extension View {
    /// Una card del Cruscotto: padding 22×24, card del tema con l'ombra, inclinazione leggera e cascata.
    fileprivate func cardStudio(_ indice: Int, base: Double) -> some View {
        let c = Tema.Apple.Studio.Card.self
        let forma = RoundedRectangle(cornerRadius: c.raggio, style: .continuous)
        return padding(c.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipShape(forma)
            .superficieApple(c.superficie, raggio: c.raggio)
            .inclinazione(massimo: c.inclinazione, raggio: c.raggio)
            .entrataCascata(indice, base: base)
    }
}

/// Il titolo di una card (`.lbl`), con «dati di prova» accanto quando i clienti sono quelli di prova e, a destra,
/// un contenuto facoltativo (il totale degli incassi).
private struct TitoloCardStudio<Destra: View>: View {
    let testo: String
    let prova: Bool
    let destra: Destra

    init(_ testo: String, prova: Bool, @ViewBuilder destra: () -> Destra) {
        self.testo = testo
        self.prova = prova
        self.destra = destra()
    }

    var body: some View {
        let c = Tema.Apple.Studio.Card.self
        HStack(alignment: .firstTextBaseline, spacing: c.spazioProva) {
            Text(testo)
                .carattereApple(c.etichetta)
                .foregroundColor(c.coloreEtichetta)
                .lineLimit(1)
                .layoutPriority(1)
            if prova {
                Text(TestiStudio.datiDiProva)
                    .carattereApple(c.prova)
                    .foregroundColor(c.coloreProva)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            destra
        }
    }
}

extension TitoloCardStudio where Destra == EmptyView {
    init(_ testo: String, prova: Bool) {
        self.init(testo, prova: prova) { EmptyView() }
    }
}

/// Una frase `.k` (didascalia o stato vuoto).
private struct NotaStudio: View {
    let testo: String
    var righe: Int? = nil

    init(_ testo: String, righe: Int? = nil) {
        self.testo = testo
        self.righe = righe
    }

    var body: some View {
        let c = Tema.Apple.Studio.Card.self
        Text(testo)
            .carattereApple(c.nota)
            .foregroundColor(c.coloreNota)
            .lineLimit(righe)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Card 1 · I tuoi ricavi

private struct CardRicaviStudio: View {
    let ricavi: CruscottoStudio.Ricavi
    let annoPrima: CruscottoStudio.Ricavi
    let variazione: Double?
    let primoAnno: Bool
    let prova: Bool
    let apriAliquote: () -> Void

    /// Né aliquote né parcelle: Prisma non sa niente dei ricavi, niente cifre.
    private var nienteDaContare: Bool { ricavi.mancaAliquote && ricavi.nessunaParcella }

    var body: some View {
        let r = Tema.Apple.Studio.Ricavi.self
        return VStack(alignment: .leading, spacing: 0) {
            TitoloCardStudio("I tuoi ricavi \(String(ricavi.anno))", prova: prova)
            HStack(alignment: .bottom, spacing: r.spazioTotale) {
                Group {
                    if nienteDaContare {
                        Text(verbatim: "—")
                    } else {
                        NumeroCheConta(ricavi.totale, formato: .euro, indice: 0)
                    }
                }
                .carattereApple(r.totale)
                .foregroundColor(r.coloreTotale)
                .lineLimit(1)
                .minimumScaleFactor(r.riduzioneTotale)
                .layoutPriority(1)
                variazioneTesto
                    .lineLimit(1)
                    .minimumScaleFactor(r.riduzioneValore)
                    .padding(.bottom, r.sottoVariazione)
            }
            .padding(.top, r.totaleSopra)
            HStack(alignment: .top, spacing: r.spazioTessere) {
                TesseraCanaleStudio(canale: .alleanza, valore: ricavi.alleanza, indice: 1,
                                    didascalia: didascaliaAlleanza,
                                    azione: ricavi.mancaAliquote ? apriAliquote : nil)
                TesseraCanaleStudio(canale: .indipendente, valore: ricavi.nessunaParcella ? nil : ricavi.indipendente,
                                    indice: 2,
                                    didascalia: ricavi.nessunaParcella ? TestiStudio.parcelleInArrivo : TestiStudio.parcelleConsulenza,
                                    azione: nil)
            }
            .padding(.top, r.tessereSopra)
            if ricavi.haDati || (!primoAnno && annoPrima.haDati) {
                LineaRicaviStudio(ricavi: ricavi, annoPrima: primoAnno ? nil : annoPrima)
                    .frame(height: r.altezzaGrafico)
                    .padding(.top, r.graficoSopra)
            } else {
                NotaStudio(nienteDaContare
                           ? "La linea dell’anno compare con i primi ricavi."
                           : "Ancora nessun ricavo nel \(String(ricavi.anno)). Le provvigioni arrivano dalle posizioni Alleanza in essere, le parcelle da Parcelle e fatture.",
                           righe: 2)
                    .padding(.top, r.graficoSopra)
            }
            Spacer(minLength: 0)
        }
    }

    private var didascaliaAlleanza: String {
        if ricavi.mancaAliquote { return TestiStudio.inserisciAliquote }
        if ricavi.stima { return "stima · " + TestiStudio.senzaAliquota(ricavi.posizioniSenzaAliquota) }
        return TestiStudio.provvigioniStimate
    }

    /// «+18% sul 2025» (verde, rosso se scende), «primo anno in Prisma», oppure «solo consulenza» senza aliquote.
    @ViewBuilder private var variazioneTesto: some View {
        let r = Tema.Apple.Studio.Ricavi.self
        if nienteDaContare {
            EmptyView()
        } else if primoAnno {
            Text(TestiStudio.primoAnno)
                .carattereApple(r.variazione)
                .foregroundColor(r.colorePrimoAnno)
        } else if let v = variazione {
            Text(TestiStudio.variazione(v, annoPrima: annoPrima.anno) + (ricavi.mancaAliquote ? " · solo consulenza" : ""))
                .carattereApple(r.variazione)
                .foregroundColor(v >= 0 ? r.coloreSale : r.coloreScende)
        } else {
            Text("nessun ricavo nel \(String(annoPrima.anno)) a questa data")
                .carattereApple(r.variazione)
                .foregroundColor(r.colorePrimoAnno)
        }
    }
}

/// La tessera di un canale: etichetta del canale, cifra che si conta (o «—») e didascalia (o il pulsante per le
/// aliquote).
private struct TesseraCanaleStudio: View {
    let canale: Canale
    let valore: Double?
    let indice: Int
    let didascalia: String
    let azione: (() -> Void)?

    var body: some View {
        let r = Tema.Apple.Studio.Ricavi.self
        let c = Tema.Apple.Studio.Card.self
        return VStack(alignment: .leading, spacing: r.spazioTessera) {
            EtichettaCanaleApple(canale: canale, compatta: true)
            Group {
                if let valore {
                    NumeroCheConta(valore, formato: .euro, indice: indice)
                } else {
                    Text(verbatim: "—")
                }
            }
            .carattereApple(r.valoreTessera)
            .foregroundColor(r.coloreValore)
            .lineLimit(1)
            .minimumScaleFactor(r.riduzioneValore)
            if let azione {
                Button(action: azione) {
                    Text(didascalia + " ›")
                        .lineLimit(1)
                }
                .buttonStyle(.appleSobrio)
                .help(CruscottoStudio.fraseSenzaAliquote)
            } else {
                Text(didascalia)
                    .carattereApple(c.nota)
                    .foregroundColor(c.coloreNota)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(r.paddingTessera)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(r.tessera, raggio: r.raggioTessera)
    }
}

/// I ricavi cumulati dell'anno (linea blu piena, fino a oggi) e dell'anno prima (tratteggiata, fino a dicembre).
private struct LineaRicaviStudio: View {
    let ricavi: CruscottoStudio.Ricavi
    let annoPrima: CruscottoStudio.Ricavi?

    var body: some View {
        let r = Tema.Apple.Studio.Ricavi.self
        let anno = ricavi.cumulati
        let prima = annoPrima?.cumulati ?? []
        let massimo = max(anno.last ?? 0, prima.last ?? 0, 1) * r.margineScala
        let puntiAnno = Self.punti(anno, massimo: massimo)
        let puntiPrima = Self.punti(prima, massimo: massimo)
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if puntiPrima.count > 1 {
                    TracciatoGrafico(punti: puntiPrima, colore: r.colorePrima, spessore: r.spessorePrima,
                                     tratteggio: r.tratteggioPrima, indice: 1)
                    etichetta(String(annoPrima?.anno ?? 0), carattere: r.etichettaPrima, colore: r.colorePrima,
                              punto: puntiPrima.last, sopra: false, misura: geo.size)
                }
                if puntiAnno.count > 1 {
                    TracciatoGrafico(punti: puntiAnno, colore: r.coloreAnno, spessore: r.spessoreAnno, indice: 0)
                    etichetta(String(ricavi.anno), carattere: r.etichettaAnno, colore: r.coloreAnno,
                              punto: puntiAnno.last, sopra: true, misura: geo.size)
                }
            }
        }
    }

    /// I punti normalizzati: il 1° gennaio e la fine di ogni mese (x = i/12), y sul massimo della scala.
    private static func punti(_ valori: [Double], massimo: Double) -> [CGPoint] {
        guard massimo > 0 else { return [] }
        return valori.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) / 12, y: CGFloat(min(max(v / massimo, 0), 1)))
        }
    }

    /// L'anno in fondo alla sua linea, allineato a destra: sopra la linea dell'anno, sotto quella dell'anno prima.
    @ViewBuilder private func etichetta(_ testo: String, carattere: Tema.Apple.Carattere, colore: Color,
                                        punto: CGPoint?, sopra: Bool, misura: CGSize) -> some View {
        let r = Tema.Apple.Studio.Ricavi.self
        if let p = punto {
            // Come TracciatoGrafico: y = altezza − valore·(altezza − margine)
            let margine = Tema.Apple.Grafico.Tracciato.margineAlto
            let x = p.x * misura.width
            let y = misura.height - p.y * max(0, misura.height - margine)
            let centro = sopra ? y - r.sopraLinea - r.centroEtichetta : y + r.sottoLinea - r.centroEtichetta
            Text(testo)
                .carattereApple(carattere)
                .foregroundColor(colore)
                .lineLimit(1)
                .frame(width: r.larghezzaEtichetta, alignment: .trailing)
                .position(x: x - r.larghezzaEtichetta / 2, y: centro)
        }
    }
}

// MARK: - Card 2 · Gli obiettivi dell'anno

private struct CardObiettiviStudio: View {
    let obiettivi: CruscottoStudio.Obiettivi
    let prova: Bool
    let ritardoAnelli: Double
    let imposta: () -> Void

    var body: some View {
        let o = Tema.Apple.Studio.Obiettivi.self
        let c = Tema.Apple.Studio.Card.self
        return VStack(alignment: .leading, spacing: 0) {
            TitoloCardStudio("Gli obiettivi dell’anno", prova: prova)
            if obiettivi.nessunoImpostato {
                // Niente anelli finti: il consulente dà i suoi traguardi in Impostazioni › Studio
                NotaStudio("Nessun obiettivo per il \(String(obiettivi.anno)): Prisma non li inventa. Scrivi i tuoi "
                           + "traguardi di produzione Alleanza, nuovi clienti e ricavi della consulenza.")
                    .padding(.top, c.vuotoSopra)
                Button(TestiStudio.imposta + " ›", action: imposta)
                    .buttonStyle(.apple)
                    .padding(.top, c.pulsanteSopra)
                    .help(CruscottoStudio.fraseSenzaObiettivi)
            } else {
                HStack(alignment: .center, spacing: o.spazio) {
                    AnelliConcentrici(voci: Self.voci(obiettivi), misura: o.anelli, spessore: o.spessore,
                                      ritardo: ritardoAnelli)
                    legenda
                }
                .padding(.top, o.sopra)
            }
            Spacer(minLength: 0)
        }
    }

    /// Gli anelli dei soli obiettivi con un traguardo, dall'esterno nell'ordine delle voci.
    private static func voci(_ o: CruscottoStudio.Obiettivi) -> [VoceAnello] {
        o.impostati.map { v in
            VoceAnello(id: v.voce.rawValue, valore: v.frazioneAnello ?? 0, massimo: 1, colore: Tema.Apple.Studio.colore(v.voce))
        }
    }

    private var legenda: some View {
        let o = Tema.Apple.Studio.Obiettivi.self
        let voci = obiettivi.voci
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(voci.enumerated()), id: \.element.id) { i, v in
                HStack(alignment: .firstTextBaseline, spacing: o.spazioPallino) {
                    Circle()
                        .fill(v.impostato ? Tema.Apple.Studio.colore(v.voce) : o.pallinoSenza)
                        .frame(width: o.pallino, height: o.pallino)
                    VStack(alignment: .leading, spacing: o.spazioTesti) {
                        Text(v.voce.nome)
                            .carattereApple(o.voce)
                            .foregroundColor(o.coloreVoce)
                            .lineLimit(1)
                        Text(Self.dettaglio(v))
                            .carattereApple(o.dettaglio)
                            .foregroundColor(o.coloreDettaglio)
                            .lineLimit(1)
                            .minimumScaleFactor(Tema.Apple.Studio.Card.riduzioneTesto)
                        if let a = Self.avviso(v) {
                            Text(a)
                                .carattereApple(o.avviso)
                                .foregroundColor(o.coloreAvviso)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.vertical, o.paddingVoce)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) {
                    if i < voci.count - 1 {
                        Rectangle()
                            .fill(o.filo)
                            .frame(height: Tema.Apple.Misura.bordo)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// «410.000 € di 500.000 €», «7 su 10»; oltre il traguardo anche la percentuale; senza traguardo quanto è fatto.
    private static func dettaglio(_ v: CruscottoStudio.Obiettivo) -> String {
        let fatto = v.voce == .nuoviClienti ? FormatoCifra.migliaia(v.fatto) : TestiStudio.euro(v.fatto)
        guard v.impostato, let t = v.traguardo else { return fatto + " · senza traguardo" }
        let traguardo = v.voce == .nuoviClienti ? FormatoCifra.migliaia(t) : TestiStudio.euro(t)
        let testo = fatto + (v.voce == .nuoviClienti ? " su " : " di ") + traguardo
        if let f = v.frazione, f > 1 { return testo + " · " + FormatoCifra.migliaia(f * 100) + "%" }
        return testo
    }

    private static func avviso(_ v: CruscottoStudio.Obiettivo) -> String? {
        switch v.avviso {
        case .dallaDataDiInserimento?: return "dalla data di inserimento in Prisma"
        case .nessunaParcella?: return TestiStudio.parcelleInArrivo
        case nil: return nil
        }
    }
}

// MARK: - Card 3 · L'imbuto delle proposte

private struct CardImbutoStudio: View {
    let imbuto: CruscottoStudio.Imbuto
    let prova: Bool

    var body: some View {
        let t = Tema.Apple.Studio.Imbuto.self
        let c = Tema.Apple.Studio.Card.self
        return VStack(alignment: .leading, spacing: 0) {
            TitoloCardStudio("L’imbuto delle proposte", prova: prova)
            if imbuto.vuoto {
                NotaStudio("Nessuna proposta nel \(String(imbuto.anno)).")
                    .padding(.top, c.vuotoSopra)
            } else {
                riga("Preparate", imbuto.preparate, colore: t.colorePreparate, indice: 0)
                    .padding(.top, t.primaSopra)
                riga("Presentate", imbuto.presentate, colore: t.colorePresentate, indice: 1)
                    .padding(.top, t.fraRighe)
                riga("Firmate", imbuto.firmate, colore: t.coloreFirmate, indice: 2)
                    .padding(.top, t.fraRighe)
                HStack(alignment: .top, spacing: t.spazioCifre) {
                    cifra(didascalia: "vanno in porto") {
                        NumeroCheConta(((imbuto.tassoChiusura ?? 0) * 100).rounded(), formato: .percentuale, indice: 6)
                    }
                    cifra(didascalia: imbuto.giorniMediAllaFirma == nil ? "alla firma: servono le date" : "alla firma, in media") {
                        Text(imbuto.giorniMediAllaFirma.map { FormatoCifra.migliaia($0) + " gg" } ?? "—")
                    }
                }
                .padding(.top, t.cifreSopra)
                NotaStudio(frase, righe: 2)
                    .padding(.top, t.fraseSopra)
            }
            Spacer(minLength: 0)
        }
    }

    /// «Si fermano soprattutto dopo la presentazione: 12 proposte.»
    private var frase: String {
        switch imbuto.fase {
        case .dopoLaPresentazione?:
            return "Si fermano soprattutto dopo la presentazione: \(TestiStudio.proposte(imbuto.ferme))."
        case .primaDellaPresentazione?:
            return "Si fermano soprattutto prima della presentazione: \(TestiStudio.proposte(imbuto.ferme))."
        case nil:
            return "Nessuna proposta ferma: tutte quelle preparate sono andate in porto."
        }
    }

    private func riga(_ nome: String, _ n: Int, colore: Color, indice: Int) -> some View {
        let t = Tema.Apple.Studio.Imbuto.self
        let frazione = imbuto.preparate > 0 ? Double(n) / Double(imbuto.preparate) : 0
        return VStack(alignment: .leading, spacing: t.barraSopra) {
            HStack(alignment: .firstTextBaseline) {
                Text(nome)
                    .carattereApple(t.riga)
                    .foregroundColor(t.coloreRiga)
                    .lineLimit(1)
                Spacer(minLength: 0)
                NumeroCheConta(Double(n), formato: .intero, indice: indice + 3)
                    .carattereApple(t.numero)
                    .foregroundColor(t.coloreRiga)
            }
            BarraPiena(frazione: frazione, colore: colore, indice: indice, altezza: t.barra, raggio: t.raggioBarra)
        }
    }

    private func cifra<V: View>(didascalia: String, @ViewBuilder valore: () -> V) -> some View {
        let t = Tema.Apple.Studio.Imbuto.self
        let c = Tema.Apple.Studio.Card.self
        return VStack(alignment: .leading, spacing: 0) {
            valore()
                .carattereApple(t.cifra)
                .foregroundColor(t.coloreCifra)
                .lineLimit(1)
            Text(didascalia)
                .carattereApple(c.nota)
                .foregroundColor(c.coloreNota)
                .lineLimit(1)
        }
    }
}

// MARK: - Card 4 · Gli incassi dei prossimi 12 mesi

private struct CardIncassiStudio: View {
    let incassi: CruscottoStudio.Incassi
    let prova: Bool
    let apriAliquote: () -> Void

    var body: some View {
        let t = Tema.Apple.Studio.Incassi.self
        let c = Tema.Apple.Studio.Card.self
        let senzaCifre = incassi.mancaAliquote && incassi.totaleIndipendente <= 0
        return VStack(alignment: .leading, spacing: 0) {
            TitoloCardStudio("Gli incassi dei prossimi 12 mesi", prova: prova) {
                if !senzaCifre {
                    NumeroCheConta(incassi.totale, formato: .euro, indice: 7)
                        .carattereApple(t.totale)
                        .foregroundColor(t.coloreTotale)
                        .lineLimit(1)
                }
            }
            NotaStudio(didascalia, righe: 2)
            if incassi.mancaAliquote {
                Button(CruscottoStudio.fraseSenzaAliquote + " ›", action: apriAliquote)
                    .buttonStyle(.apple)
                    .padding(.top, c.pulsanteSopra)
            }
            if incassi.vuoto {
                if !incassi.mancaAliquote {
                    NotaStudio("Nessun incasso previsto nei prossimi 12 mesi.")
                        .padding(.top, c.vuotoSopra)
                }
                Spacer(minLength: 0)
            } else {
                // I due canali, sempre riconoscibili: Alleanza sotto, indipendente sopra
                HStack(spacing: t.spazioLegenda) {
                    EtichettaCanaleApple(canale: .alleanza, compatta: true)
                    EtichettaCanaleApple(canale: .indipendente, compatta: true)
                }
                .padding(.top, t.legendaSopra)
                ColonneIncassiStudio(mesi: incassi.mesi)
                    .frame(maxHeight: t.altezza)
                    .padding(.top, t.sopra)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private var didascalia: String {
        let base = "Rinnovi e premi ricorrenti Alleanza, parcelle già firmate."
        if incassi.mancaAliquote { return base + " Senza le tue aliquote la parte Alleanza resta vuota." }
        if incassi.posizioniSenzaAliquota > 0 {
            return base + " Stima con le tue aliquote · " + TestiStudio.senzaAliquota(incassi.posizioniSenzaAliquota) + "."
        }
        return base + " Stima con le tue aliquote."
    }
}

// MARK: - Card 5 · Il valore e il tempo

private struct CardValoreTempoStudio: View {
    let valore: CruscottoStudio.ValoreTempo
    let mancaAliquote: Bool
    let prova: Bool
    let apri: (String) -> Void

    var body: some View {
        let d = Tema.Apple.Studio.Dispersione.self
        let c = Tema.Apple.Studio.Card.self
        return VStack(alignment: .leading, spacing: 0) {
            TitoloCardStudio("Il valore e il tempo", prova: prova)
            NotaStudio(TestiStudio.didascaliaValore, righe: 2)
            if valore.vuoto {
                NotaStudio(TestiStudio.senzaOre)
                    .padding(.top, c.vuotoSopra)
                Spacer(minLength: 0)
            } else {
                DispersioneClientiStudio(valore: valore, apri: apri)
                    .frame(maxHeight: d.altezza)
                    .padding(.top, d.sopra)
                    .frame(maxHeight: .infinity, alignment: .top)
                if let nota {
                    NotaStudio(nota, righe: 1)
                        .help(CruscottoStudio.ValoreTempo.criterio)
                }
            }
        }
    }

    /// Cosa manca per leggere il grafico per intero (una riga).
    private var nota: String? {
        if mancaAliquote { return "Ricavi per cliente senza le tue aliquote: per ora contano solo le ore." }
        if valore.sogliaOre == nil {
            return "La zona «\(TestiStudio.zona)» compare con almeno \(CruscottoStudio.ValoreTempo.minimoClienti) clienti."
        }
        if valore.ricaviParziali { return "Ricavi per cliente parziali: le parcelle arrivano con Parcelle e fatture." }
        return nil
    }
}
