import SwiftUI

/// Il confronto di due voci del dossier (posizioni in essere, proposte, scenari del simulatore) con le stesse
/// regole. Testata con l'orizzonte, «Inverti», «Restare o cambiare…» e il prospetto in PDF (l'ex elenco laterale
/// di Confronti); in alto la differenza netta, poi le due voci, il grafico e la tabella. Senza cornice: sul Mac
/// sta negli strumenti di Analisi 360, su iPhone e iPad anche nell'app Confronti.
struct ConfrontoIpotesi: View {
    @Environment(StatoShell.self) var stato
    /// Dentro Analisi 360: «Apri il simulatore» passa allo strumento Simulatore nella stessa finestra.
    var inAnalisi = false
    @State private var mostraMetodo = false

    private typealias M = Tema.Misura.StrumentiAnalisi
    private typealias K = Tema.Colore.StrumentiAnalisi
    private typealias F = Tema.Testo.StrumentiAnalisi
    private typealias A = Tema.Apple.Strumenti360

    private var cliente: String { stato.clienteAttivoId }

    /// Tutte le voci confrontabili del cliente.
    private var voci: [ElementoConfronto] { ElementoConfronto.elenco(stato.dati, cliente: cliente) }

    var body: some View {
        let _ = ContaCorpi.segna()
        let tutte = voci
        let scelta = ElementoConfronto.coppia(tutte, a: stato.confrontoA, b: stato.confrontoB, posizioni: stato.posizioniCliente(cliente))
        VStack(spacing: 0) {
            testata(scelta.0, scelta.1)
            if let a = scelta.0, let b = scelta.1 {
                confronto(a, b, voci: tutte)
            } else {
                vuoto
            }
        }
    }

    // MARK: - Testata

    private func orizzonteComune(_ a: ElementoConfronto?, _ b: ElementoConfronto?) -> Int {
        max(a?.parametri.anni ?? IpotesiCalcolo.orizzontePredefinito, b?.parametri.anni ?? IpotesiCalcolo.orizzontePredefinito)
    }

    private func testata(_ a: ElementoConfronto?, _ b: ElementoConfronto?) -> some View {
        HStack(spacing: M.spazioTestata) {
            SpiaStrumentoApple()
            Text("Orizzonte")
                .titoloTestataStrumentoApple()
            SegmentiAnalisi(opzioni: [(false, "Ognuno il suo"), (true, "Comune")],
                            selezione: Binding(get: { stato.orizzonteConfronto != nil },
                                               set: { stato.orizzonteConfronto = $0 ? orizzonteComune(a, b) : nil }))
                .frame(width: A.segmentiOrizzonte)
                .help("Con l'orizzonte comune A e B si leggono sullo stesso numero di anni: il confronto è più equo")
            if let anni = stato.orizzonteConfronto {
                Stepper(value: Binding(get: { anni },
                                       set: { stato.orizzonteConfronto = min(max($0, M.orizzonteMinimo), M.orizzonteMassimo) }),
                        in: M.orizzonteMinimo...M.orizzonteMassimo) {
                    Text("\(anni) \(anni == 1 ? "anno" : "anni")")
                        .carattereApple(A.testoStepper)
                        .foregroundColor(A.coloreTitoloTestata)
                }
                .fixedSize()
            }
            Spacer(minLength: M.spazioTestata)
            ViewThatFits(in: .horizontal) {
                azioni(a, b, soloIcone: false)
                azioni(a, b, soloIcone: true)
            }
        }
        .testataColonna()
    }

    private func etichetta(_ testo: String, _ simbolo: String, soloIcone: Bool) -> some View {
        Group {
            if soloIcone { Image(systemName: simbolo) } else { Label(testo, systemImage: simbolo) }
        }
        .help(testo)
    }

    private func azioni(_ a: ElementoConfronto?, _ b: ElementoConfronto?, soloIcone: Bool) -> some View {
        HStack(spacing: M.spazioTestata) {
            Button {
                stato.confrontoA = b?.voce
                stato.confrontoB = a?.voce
            } label: {
                etichetta("Inverti A e B", "arrow.left.arrow.right", soloIcone: soloIcone)
            }
            .buttonStyle(.apple)
            .disabled(a == nil || b == nil)
            if let a, let b {
                if case .posizione(let ia) = a.voce, case .posizione(let ib) = b.voce {
                    Button { stato.apriProspetto(.sostituzione(ia, ib, report: false)) } label: {
                        etichetta("Restare o cambiare…", "arrow.triangle.branch", soloIcone: soloIcone)
                    }
                    .buttonStyle(.apple)
                }
                Button { stato.apriProspetto(.confronto(a.voce, b.voce)) } label: {
                    etichetta("Prospetto in PDF", "doc.text", soloIcone: soloIcone)
                }
                .buttonStyle(.applePrimario)
                .help("Ipotesi, esiti e differenze anno per anno, impaginati su carta")
            }
        }
        .fixedSize()
    }

    private var vuoto: some View {
        VStack(spacing: A.spazioVuoto) {
            Text("⇄").carattereApple(A.simboloVuoto).foregroundColor(A.coloreSimboloVuoto)
            Text("Servono almeno due voci da confrontare").carattereApple(A.titoloVuoto).foregroundColor(A.coloreCifra)
            Text("Aggiungi una posizione o una proposta di investimento, risparmio o previdenza, oppure salva uno scenario nel simulatore.")
                .carattereApple(A.testoVuoto)
                .foregroundColor(A.coloreNota)
                .multilineTextAlignment(.center)
                .frame(maxWidth: A.larghezzaTestoVuoto)
            HStack {
                Button("Apri Posizioni") {
                    stato.portafoglio = false
                    stato.apri(.posizioni)
                }
                .buttonStyle(.apple)
                Button("Apri il simulatore") {
                    if inAnalisi { stato.scegliStrumentoAnalisi(.simulatore) } else { stato.apri(.simulazioni) }
                }
                .buttonStyle(.applePrimario)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Confronto

    private func parametri(_ e: ElementoConfronto) -> ParametriProiezione {
        var p = e.parametri
        if let anni = stato.orizzonteConfronto { p.anni = anni }
        return p
    }

    private func confronto(_ a: ElementoConfronto, _ b: ElementoConfronto, voci: [ElementoConfronto]) -> some View {
        let pa = parametri(a)
        let pb = parametri(b)
        let ea = MotoreProiezione.calcola(pa)
        let eb = MotoreProiezione.calcola(pb)
        let ia = MotoreProiezione.impattoCosti(pa)
        let ib = MotoreProiezione.impattoCosti(pb)
        return ScrollView {
            VStack(alignment: .leading, spacing: M.spazioContenuto) {
                // La cifra principale in alto: quanto netto in più, poi le due voci
                verdetto(ea, eb, ia, ib, pa, pb)
                HStack(alignment: .top, spacing: M.spazioSchede) {
                    schedaVoce("A", a, colore: Colori.Strumenti.serie[0], voci: voci) { stato.confrontoA = $0 }
                    schedaVoce("B", b, colore: Colori.Strumenti.serie[1], voci: voci) { stato.confrontoB = $0 }
                }
                PannelloAnalisi(titolo: "L'andamento nel tempo", nota: "Valore prima delle imposte; tratteggiato il versato di A") {
                    EmptyView()
                } contenuto: {
                    VStack(alignment: .leading, spacing: M.spazioGrafico) {
                        GraficoProiezione(serie: [
                            .init(id: "b", punti: eb.punti, colore: Colori.Strumenti.serie[1]),
                            .init(id: "a", punti: ea.punti, colore: Colori.Strumenti.serie[0], principale: true),
                        ])
                        HStack(spacing: M.spazioLegenda) {
                            LegendaLinea(colore: Colori.Strumenti.serie[0], testo: "A · \(a.titolo)")
                            LegendaLinea(colore: Colori.Strumenti.serie[1], testo: "B · \(b.titolo)")
                            LegendaLinea(colore: Colori.Analisi.lineaTratteggiata, testo: "Versato di A", tratteggio: true)
                        }
                    }
                }
                tabella(pa, pb, ea, eb, ia, ib)
                HStack {
                    Spacer()
                    Button { mostraMetodo.toggle() } label: {
                        Label(mostraMetodo ? "Nascondi" : "Prima di trarre conclusioni",
                              systemImage: mostraMetodo ? "chevron.up" : "questionmark.circle")
                    }
                    .buttonStyle(.appleSobrio)
                }
                if mostraMetodo {
                    NotaMetodo(testo: "Il confronto mette sullo stesso piano numeri dichiarati: rendimenti attesi, costi e fiscalità vanno verificati sui documenti (KID, set informativo, prospetto). Garanzie, rischio, liquidabilità e coperture assicurative non entrano nel calcolo ma contano nella scelta: leggili nel dettaglio delle posizioni.",
                               titolo: "Prima di trarre conclusioni")
                }
            }
            .padding(M.margineContenuto)
        }
    }

    private func schedaVoce(_ lettera: String, _ e: ElementoConfronto, colore: Color, voci: [ElementoConfronto],
                            scegli: @escaping (VoceConfronto) -> Void) -> some View {
        VStack(alignment: .leading, spacing: A.spazioScheda) {
            HStack(spacing: A.spazioScheda) {
                Text(lettera)
                    .carattereApple(A.lettera)
                    .foregroundColor(A.coloreLettera)
                    .frame(width: A.latoLettera, height: A.latoLettera)
                    .background(Circle().fill(colore))
                VStack(alignment: .leading, spacing: A.spazioTitoloScheda) {
                    Text(e.titolo)
                        .carattereApple(A.titoloVoce)
                        .foregroundColor(A.coloreTitoloVoce)
                        .lineLimit(1)
                    Text(e.sottotitolo)
                        .carattereApple(A.sottotitoloVoce)
                        .foregroundColor(A.coloreSottotitoloVoce)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if let c = e.canale { EtichettaCanale(canale: c, compatta: true) }
            }
            MenuTendina(selezione: Binding(get: { e.voce }, set: { scegli($0) }),
                        opzioni: voci.map { v in (v.voce, "\(v.titolo) — \(v.sottotitolo)") })
        }
        .padding(A.paddingScheda)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            // La barretta del colore della voce dentro il bordo sinistro (come le schede di sempre)
            Capsule(style: .continuous)
                .fill(colore)
                .frame(width: A.barretta)
                .padding(.vertical, A.margineBarretta)
                .padding(.leading, A.staccoBarretta)
                .allowsHitTesting(false)
        }
        .superficieApple(A.schedaVoce)
    }

    /// La cifra principale: quanto netto in più arriva la voce migliore; accanto quanto tolgono i costi
    /// ad A e a B, e gli avvisi (orizzonti o versato diversi) come pillole invece di una frase lunga.
    private func verdetto(_ ea: EsitoProiezione, _ eb: EsitoProiezione, _ ia: Double, _ ib: Double,
                          _ pa: ParametriProiezione, _ pb: ParametriProiezione) -> some View {
        let differenza = eb.netto - ea.netto
        let pari = abs(differenza) < 1
        let migliore = differenza > 0 ? "B" : "A"
        let stessoOrizzonte = pa.anni == pb.anni
        let versatoDiverso = abs(ea.versato - eb.versato) >= 1
        // Testi già pronti (String): il controllo dei tipi non deve risolvere ternari dentro Text
        let occhiello: String = pari ? "A E B ARRIVANO ALLO STESSO NETTO" : "\(migliore) ARRIVA PIÙ IN ALTO, AL NETTO"
        let cifra: String = pari ? "=" : "+" + Formati.euro(abs(differenza))
        let anni: String = pa.anni == 1 ? "anno" : "anni"
        let orizzonte: String = stessoOrizzonte ? "in \(pa.anni) \(anni)" : "su orizzonti diversi: \(pa.anni) e \(pb.anni) anni"
        return HStack(alignment: .center, spacing: M.spazioVerdetto) {
            VStack(alignment: .leading, spacing: M.spazioCifra) {
                Text(occhiello)
                    .carattereApple(A.occhiello)
                    .foregroundColor(A.coloreOcchiello)
                Group {
                    if pari {
                        Text(cifra)
                    } else {
                        // La differenza si conta fino al valore (il testo è quello di sempre: «+12.345 €»)
                        NumeroCheConta(abs(differenza), formato: .personalizzato({ "+" + Formati.euro($0) }))
                    }
                }
                .carattereApple(A.cifra)
                .foregroundColor(pari ? A.coloreCifra : A.positivo)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                Text(orizzonte)
                    .carattereApple(A.nota)
                    .foregroundColor(A.coloreNota)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: M.spazioCifra) {
                Text("I COSTI TOLGONO")
                    .carattereApple(A.occhiello)
                    .foregroundColor(A.coloreOcchiello)
                HStack(spacing: M.spazioCosti) {
                    costo("A", ia, colore: Colori.Strumenti.serie[0])
                    costo("B", ib, colore: Colori.Strumenti.serie[1])
                }
                if !stessoOrizzonte || versatoDiverso {
                    HStack(spacing: M.spazioPillole) {
                        if !stessoOrizzonte {
                            Pillola(testo: "Orizzonte: scegli «Comune»", tono: .attenzione)
                                .help("Per un confronto equo, A e B sullo stesso numero di anni")
                        }
                        if versatoDiverso {
                            Pillola(testo: "Versato diverso", tono: .attenzione)
                                .help("A \(Formati.euro(ea.versato)) · B \(Formati.euro(eb.versato))")
                        }
                    }
                }
            }
        }
        .padding(M.margineCifra)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(A.riquadroVerdetto)
    }

    private func costo(_ lettera: String, _ valore: Double, colore: Color) -> some View {
        HStack(spacing: M.spazioPallino) {
            Circle().fill(colore).frame(width: M.pallino, height: M.pallino)
            Text("\(lettera) \(Formati.euro(valore))")
                .carattereApple(A.costo)
                .foregroundColor(A.coloreCosto)
                .lineLimit(1)
        }
    }

    /// Riga della tabella: B rispetto ad A, con il verso "meno è meglio" per costi e imposte.
    struct RigaConfronto {
        let etichetta: String
        let a: String
        let b: String
        var scarto: Double? = nil
        var menoEMeglio = false
        var forte = false
    }

    private func tabella(_ pa: ParametriProiezione, _ pb: ParametriProiezione, _ ea: EsitoProiezione, _ eb: EsitoProiezione,
                         _ ia: Double, _ ib: Double) -> some View {
        let w = Misure.Strumenti.colonnaConfronto
        let versamento: (ParametriProiezione) -> String = { p in
            p.versamento > 0 && p.frequenza != .unica ? "\(Formati.euro(p.versamento)) \(p.frequenza.nome.lowercased())" : "—"
        }
        let righe: [RigaConfronto] = [
            .init(etichetta: "Capitale iniziale", a: Formati.euro(pa.capitaleIniziale), b: Formati.euro(pb.capitaleIniziale)),
            .init(etichetta: "Versamenti periodici", a: versamento(pa), b: versamento(pb)),
            .init(etichetta: "Orizzonte", a: "\(pa.anni) anni", b: "\(pb.anni) anni"),
            // Equivalenti di un comparto unico: per una multiramo a due parti pesati sulle quote, altrimenti
            // rendimento, costo annuo e aliquota di sempre
            .init(etichetta: "Rendimento atteso", a: Formati.percentuale(pa.rendimentoEquivalente), b: Formati.percentuale(pb.rendimentoEquivalente)),
            .init(etichetta: "Costo d'ingresso", a: Formati.percentuale(pa.costoIngresso), b: Formati.percentuale(pb.costoIngresso)),
            .init(etichetta: "Costo annuo", a: Formati.percentuale(pa.costoAnnuoEquivalente), b: Formati.percentuale(pb.costoAnnuoEquivalente)),
            .init(etichetta: "Fiscalità sul guadagno", a: Formati.percentuale(pa.aliquotaEquivalente), b: Formati.percentuale(pb.aliquotaEquivalente)),
            .init(etichetta: "Totale versato", a: Formati.euro(ea.versato), b: Formati.euro(eb.versato), scarto: eb.versato - ea.versato),
            .init(etichetta: "Costi nel periodo", a: Formati.euro(ea.costi), b: Formati.euro(eb.costi),
                  scarto: eb.costi - ea.costi, menoEMeglio: true),
            .init(etichetta: "Quanto tolgono i costi", a: Formati.euro(ia), b: Formati.euro(ib), scarto: ib - ia, menoEMeglio: true),
            .init(etichetta: "Imposte", a: Formati.euro(ea.imposte), b: Formati.euro(eb.imposte),
                  scarto: eb.imposte - ea.imposte, menoEMeglio: true),
            .init(etichetta: "Valore finale netto", a: Formati.euro(ea.netto), b: Formati.euro(eb.netto),
                  scarto: eb.netto - ea.netto, forte: true),
            .init(etichetta: "Guadagno netto", a: Formati.euro(ea.guadagnoNetto), b: Formati.euro(eb.guadagnoNetto),
                  scarto: eb.guadagnoNetto - ea.guadagnoNetto),
            .init(etichetta: "In euro di oggi", a: Formati.euro(ea.reale), b: Formati.euro(eb.reale), scarto: eb.reale - ea.reale),
        ]
        return TabellaStrumento {
            CellaTesta(testo: "")
            CellaTesta(testo: "A", larghezza: w, destra: true)
            CellaTesta(testo: "B", larghezza: w, destra: true)
            CellaTesta(testo: "B rispetto ad A", larghezza: w, destra: true)
        } righe: {
            ForEach(Array(righe.enumerated()), id: \.offset) { i, r in
                RigaStrumento(indice: i) {
                    CellaTabella(testo: r.etichetta, forte: r.forte)
                    CellaTabella(testo: r.a, larghezza: w, destra: true, forte: r.forte)
                    CellaTabella(testo: r.b, larghezza: w, destra: true, forte: r.forte)
                    CellaTabella(testo: testoScarto(r.scarto), larghezza: w, destra: true, forte: r.forte,
                                 colore: coloreScarto(r))
                }
            }
        }
    }

    private func testoScarto(_ v: Double?) -> String {
        guard let v else { return "—" }
        guard abs(v) >= 1 else { return "=" }
        return "\(v > 0 ? "+" : "−")\(Formati.euro(abs(v)))"
    }

    private func coloreScarto(_ r: RigaConfronto) -> Color {
        guard let v = r.scarto, abs(v) >= 1 else { return A.coloreCellaNota }
        return (v > 0) != r.menoEMeglio ? A.positivo : A.negativo
    }
}
