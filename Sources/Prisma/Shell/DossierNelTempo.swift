import SwiftUI

// Scheda «Nel tempo» del dossier nel tema Apple (Design/template-apple-specifica.md §4.2.4, PC C17-C18, MO 13-14):
// la macchina del tempo del cliente. Card intera con `.lbl` «Il patrimonio, tre anni indietro e due avanti», la
// legenda e, se ci sono proposte aperte, «Con le proposte · Senza» a pillola; il grafico (passato 36 mesi su 600 pt
// con area e linea blu, futuro 25 mesi su 400 pt con la fascia viola e la stima tratteggiata 6 6 anche a disegno
// finito, griglia di 4 righe con i valori a destra, «oggi» tratteggiata 2 4, date ai lati); sotto il cursore sul
// tempo e accanto il momento scelto:
// - a sinistra (passato) il patrimonio di allora e il riesame più vicino dalle fotografie (canali, debiti, proposte,
//   check-up, cosa era cambiato, le note dell'incontro); se quel mese non ha un riesame lo dice;
// - a destra (futuro) la stima con la fascia degli scenari, sempre «stima, non una previsione».
// Le cifre vengono da `MotoreNelTempo` (in cache: `CacheNelTempo`), mai dal +5,5% fisso del template.
// In modalità cliente e in presentazione le note interne (appunti degli incontri e del taccuino) non compaiono.
// La scheda non scorre nel dossier (`SchedaCliente.scorreNelDossier`): prende tutta l'altezza che resta.
// Valori in DesignSystem/Apple/Tema.Apple+NelTempoFamiglia.swift.

struct NelTempoDossier: View {
    let cliente: Cliente
    @EnvironmentObject var stato: StatoShell
    /// Il mese scelto con il cursore (−36…24); nil = oggi, o quello chiesto da un'istantanea.
    @State private var meseScelto: Double?
    @State private var conProposte = true

    var body: some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let storia = storiaCliente
        let mese = meseMostrato
        let proposte = conProposte && storia.haProposte
        return VStack(alignment: .leading, spacing: 0) {
            intestazione(storia, proposte: proposte)
            GeometryReader { g in
                if g.size.width >= n.larghezzaAffiancata {
                    HStack(alignment: .top, spacing: n.spazioMomento) {
                        colonnaGrafico(storia, mese: mese, proposte: proposte, altezzaLibera: g.size.height)
                        ScrollView(.vertical, showsIndicators: false) {
                            momento(storia, mese: mese, proposte: proposte)
                        }
                        .frame(width: n.larghezzaMomento)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: n.spazioBlocchiMomento) {
                            colonnaGrafico(storia, mese: mese, proposte: proposte, altezzaLibera: nil)
                            momento(storia, mese: mese, proposte: proposte)
                        }
                    }
                }
            }
            .padding(.top, n.sopraGrafico)
        }
        .padding(n.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(n.superficie)
        .entrataDossier(0)
    }

    /// La storia del cliente (in cache finché non cambiano posizioni, fotografie o giorno).
    private var storiaCliente: StoriaNelTempo {
        let id = cliente.id
        let s = stato
        return CacheNelTempo.storia(cliente: id, posizioni: s.posizioniCliente(id), fotografie: s.fotografieCliente(id),
                                    patrimonio: { s.analisiDossier(id).patrimonio })
    }

    /// Il mese mostrato: quello scelto, altrimenti quello chiesto dall'istantanea, altrimenti oggi.
    private var meseMostrato: Int {
        let grezzo = meseScelto ?? RichiestaIstantaneaNelTempo.per(stato).map { Double($0) } ?? 0
        let k = Int(grezzo.rounded())
        return max(-StoriaNelTempo.mesiIndietro, min(StoriaNelTempo.mesiAvanti, k))
    }

    // MARK: Intestazione

    private func intestazione(_ storia: StoriaNelTempo, proposte: Bool) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        return HStack(alignment: .center, spacing: n.spazioIntestazione) {
            Text("Il patrimonio, tre anni indietro e due avanti")
                .carattereApple(n.titolo)
                .foregroundColor(n.coloreTitolo)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: n.spazioIntestazione)
            legenda(storia, proposte: proposte)
            if storia.haProposte {
                SegmentatoPillola(selezione: $conProposte, voci: [(true, "Con le proposte"), (false, "Senza")])
                    .fixedSize()
            }
        }
    }

    private func legenda(_ storia: StoriaNelTempo, proposte: Bool) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let testoStima = storia.haProposte ? (proposte ? "stima con le proposte" : "stima senza le proposte") : "stima"
        return HStack(spacing: n.spazioLegenda) {
            HStack(spacing: n.spazioSegnoLegenda) {
                Text("━").foregroundColor(n.colorePassato)
                Text("com'era").foregroundColor(n.coloreLegenda)
            }
            HStack(spacing: n.spazioSegnoLegenda) {
                Text("┅").foregroundColor(proposte ? n.coloreStima : n.coloreStimaSenza)
                Text(testoStima).foregroundColor(n.coloreLegenda)
            }
        }
        .carattereApple(n.legenda)
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    // MARK: Grafico, date e cursore

    private func colonnaGrafico(_ storia: StoriaNelTempo, mese: Int, proposte: Bool, altezzaLibera: CGFloat?) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let altezza = altezzaGrafico(altezzaLibera)
        return VStack(alignment: .leading, spacing: 0) {
            GraficoNelTempo(storia: storia, conProposte: proposte, mese: mese)
                .frame(height: altezza)
            dateAsse(storia)
                .frame(height: n.altezzaDate)
            HStack(spacing: 0) {
                CursoreApple(valore: valoreCursore, intervallo: Double(-StoriaNelTempo.mesiIndietro)...Double(StoriaNelTempo.mesiAvanti),
                             passo: 1, etichetta: "Il momento nel tempo, in mesi da oggi")
                    // La manopola centrata sul mese: il binario sporge di mezza manopola ai lati del grafico
                    .padding(.horizontal, -Tema.Apple.Misura.Controllo.manopolaCursore / 2)
                Color.clear.frame(width: n.colonnaValori, height: 1)
            }
            .padding(.top, n.sopraCursore)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// Il grafico prende lo spazio che resta sopra date e cursore, fra il minimo e il massimo del template.
    private func altezzaGrafico(_ libera: CGFloat?) -> CGFloat {
        let n = Tema.Apple.Clienti.NelTempo.self
        guard let libera else { return n.altezzaMinimaGrafico }
        let resto = libera - n.altezzaDate - n.sopraCursore - Tema.Apple.Misura.Controllo.manopolaCursore
        return max(n.altezzaMinimaGrafico, min(n.altezzaMassimaGrafico, resto))
    }

    private var valoreCursore: Binding<Double> {
        Binding(get: { Double(meseMostrato) }, set: { meseScelto = $0 })
    }

    /// «nov 2023» a sinistra, «oggi» sotto la riga di oggi, «nov 2028» a destra.
    private func dateAsse(_ storia: StoriaNelTempo) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let inizio = Self.meseAsse.string(from: storia.giorno(-StoriaNelTempo.mesiIndietro))
        let fine = Self.meseAsse.string(from: storia.giorno(StoriaNelTempo.mesiAvanti))
        return HStack(spacing: 0) {
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Text(inizio)
                        .carattereApple(n.date)
                        .foregroundColor(n.coloreAsse)
                        .frame(width: g.size.width, alignment: .leading)
                    Text("oggi")
                        .carattereApple(n.oggi)
                        .foregroundColor(n.coloreOggi)
                        .fixedSize()
                        .position(x: g.size.width * n.quotaPassato, y: g.size.height / 2)
                    Text(fine)
                        .carattereApple(n.date)
                        .foregroundColor(n.coloreAsse)
                        .frame(width: g.size.width, alignment: .trailing)
                }
                .frame(width: g.size.width, height: g.size.height)
            }
            Color.clear.frame(width: n.colonnaValori, height: 1)
        }
        .lineLimit(1)
        .accessibilityHidden(true)
    }

    // MARK: Il momento scelto

    private func momento(_ storia: StoriaNelTempo, mese: Int, proposte: Bool) -> some View {
        MomentoNelTempo(cliente: cliente, storia: storia, mese: mese, conProposte: proposte,
                        riservato: stato.inModoCliente || stato.presentazione != nil)
    }

    /// «nov 2023» per le date sotto il grafico.
    static let meseAsse = Formati.formato("MMM yyyy")
}

// MARK: - Il grafico

/// Il grafico «Nel tempo»: griglia, passato con area e linea, fascia e stima tratteggiata, i riesami sulla linea e il
/// momento scelto. I punti sono normalizzati (0…1) sulla stessa scala per le due stime, così «Con le proposte · Senza»
/// non cambia l'asse.
struct GraficoNelTempo: View {
    let storia: StoriaNelTempo
    let conProposte: Bool
    let mese: Int

    var body: some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let scala = ScalaNelTempo(storia)
        let stima = storia.stima(conProposte: conProposte)
        let coloreStima = conProposte && storia.haProposte ? n.coloreStima : n.coloreStimaSenza
        return HStack(spacing: 0) {
            ZStack {
                GrigliaGrafico(righe: Tema.Apple.Grafico.Tracciato.righeGriglia, oggi: n.quotaPassato)
                TracciatoGrafico(punti: scala.passato(storia), colore: n.colorePassato, spessore: n.spessorePassato,
                                 area: true, indice: 0, ritardo: n.ritardoLinee)
                stimaDisegnata(scala: scala, stima: stima, colore: coloreStima)
                    .id(conProposte)
                riesami(scala)
                momento(scala, colore: mese > 0 ? coloreStima : n.colorePassato)
            }
            valoriAsse(scala)
                .frame(width: n.colonnaValori)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(descrizione))
    }

    @ViewBuilder private func stimaDisegnata(scala: ScalaNelTempo, stima: StimaNelTempo, colore: Color) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        ZStack {
            if stima.esposta {
                FasciaGrafico(sopra: scala.futuro(stima.alta), sotto: scala.futuro(stima.bassa), colore: colore,
                              ritardo: n.ritardoLinee)
            }
            TracciatoGrafico(punti: scala.futuro(stima.centrale), colore: colore, spessore: n.spessoreStima,
                             tratteggio: n.tratteggioStima, indice: 1, ritardo: n.ritardoLinee)
        }
    }

    /// I riesami salvati: cerchi vuoti sulla linea del passato.
    private func riesami(_ scala: ScalaNelTempo) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let punti = storia.fotografieNelGrafico.map { scala.punto(mese: $0.mese, valore: storia.valore($0.mese, conProposte: false)) }
        return ZStack {
            FormaPuntiNelTempo(punti: punti, raggio: n.raggioRiesame)
                .fill(n.fondoRiesame)
            FormaPuntiNelTempo(punti: punti, raggio: n.raggioRiesame)
                .stroke(n.colorePassato, lineWidth: n.bordoRiesame)
        }
        .allowsHitTesting(false)
    }

    /// Il momento del cursore: la riga verticale (non a oggi, che ha già la sua) e il punto sulla linea.
    private func momento(_ scala: ScalaNelTempo, colore: Color) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let p = scala.punto(mese: mese, valore: storia.valore(mese, conProposte: conProposte))
        return ZStack {
            if mese != 0 {
                FormaRigaNelTempo(x: p.x)
                    .stroke(n.coloreMomento, lineWidth: n.spessoreMomento)
            }
            FormaPuntiNelTempo(punti: [p], raggio: n.raggioMomento)
                .fill(colore)
            FormaPuntiNelTempo(punti: [p], raggio: n.raggioMomento)
                .stroke(n.coloreBordoMomento, lineWidth: n.bordoMomento)
        }
        .allowsHitTesting(false)
    }

    /// I valori delle quattro righe della griglia, a destra («318k €»).
    private func valoriAsse(_ scala: ScalaNelTempo) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let righe = Tema.Apple.Grafico.Tracciato.righeGriglia
        let passi = max(1, righe - 1)
        return GeometryReader { g in
            ForEach(0..<righe, id: \.self) { k in
                let f = CGFloat(k) / CGFloat(passi)
                Text(Formati.euroBreve(scala.valore(frazione: Double(f))))
                    .carattereApple(n.valoriAsse)
                    .foregroundColor(n.coloreAsse)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: g.size.width, alignment: .trailing)
                    .position(x: g.size.width / 2, y: ScalaNelTempo.yAsse(f, altezza: g.size.height))
            }
        }
        .accessibilityHidden(true)
    }

    private var descrizione: String {
        let oggi = Formati.euro(storia.nettoOggi)
        let fine = Formati.euro(storia.valore(StoriaNelTempo.mesiAvanti, conProposte: conProposte))
        return "Patrimonio netto: oggi \(oggi); stima tra due anni \(fine), una stima e non una previsione."
    }
}

/// La scala del grafico: x da −36 a 24 mesi («oggi» al 60%), y dal minimo al massimo di passato e stime (con i
/// margini del template), normalizzati 0…1.
struct ScalaNelTempo {
    let basso: Double
    let alto: Double

    init(_ s: StoriaNelTempo) {
        let n = Tema.Apple.Clienti.NelTempo.self
        var valori = s.passato
        for st in [s.senzaProposte] + (s.conProposte.map { [$0] } ?? []) {
            valori += st.centrale
            valori += st.alta
            valori += st.bassa
        }
        let minimo = valori.min() ?? 0
        let massimo = valori.max() ?? 1
        var b = minimo - abs(minimo) * (1 - n.margineSotto)
        var a = massimo + abs(massimo) * (n.margineSopra - 1)
        if a - b < 1 {
            b -= 0.5
            a = b + 1
        }
        basso = b
        alto = a
    }

    func x(mese k: Int) -> CGFloat {
        let q = Tema.Apple.Clienti.NelTempo.quotaPassato
        if k <= 0 { return q * CGFloat(k + StoriaNelTempo.mesiIndietro) / CGFloat(StoriaNelTempo.mesiIndietro) }
        return q + (1 - q) * CGFloat(k) / CGFloat(StoriaNelTempo.mesiAvanti)
    }

    func y(_ v: Double) -> CGFloat { CGFloat((v - basso) / (alto - basso)) }

    func punto(mese k: Int, valore v: Double) -> CGPoint { CGPoint(x: x(mese: k), y: y(v)) }

    func valore(frazione f: Double) -> Double { basso + (alto - basso) * f }

    func passato(_ s: StoriaNelTempo) -> [CGPoint] {
        s.passato.enumerated().map { i, v in punto(mese: i - StoriaNelTempo.mesiIndietro, valore: v) }
    }

    func futuro(_ serie: [Double]) -> [CGPoint] {
        serie.enumerated().map { k, v in punto(mese: k, valore: v) }
    }

    /// Come i grafici del tema: y = altezza − y·(altezza − 10), 10 di margine sopra.
    static func yAsse(_ f: CGFloat, altezza: CGFloat) -> CGFloat {
        altezza - f * max(0, altezza - Tema.Apple.Grafico.Tracciato.margineAlto)
    }
}

/// Cerchi attorno a punti normalizzati (stessa mappa dei grafici del tema).
private struct FormaPuntiNelTempo: Shape {
    let punti: [CGPoint]
    let raggio: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        for q in punti {
            let c = CGPoint(x: rect.minX + q.x * rect.width, y: rect.minY + ScalaNelTempo.yAsse(q.y, altezza: rect.height))
            p.addEllipse(in: CGRect(x: c.x - raggio, y: c.y - raggio, width: 2 * raggio, height: 2 * raggio))
        }
        return p
    }
}

/// La riga verticale del momento scelto (x normalizzata).
private struct FormaRigaNelTempo: Shape {
    let x: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let posizione = rect.minX + x * rect.width
        p.move(to: CGPoint(x: posizione, y: rect.minY))
        p.addLine(to: CGPoint(x: posizione, y: rect.maxY))
        return p
    }
}

// MARK: - Il momento scelto

/// La colonna accanto al grafico: oggi, un mese passato con il riesame più vicino, o un mese futuro con la stima.
struct MomentoNelTempo: View {
    let cliente: Cliente
    let storia: StoriaNelTempo
    let mese: Int
    let conProposte: Bool
    /// Modalità cliente o presentazione: niente note interne.
    let riservato: Bool
    @EnvironmentObject var stato: StatoShell

    /// Un incontro o una nota «di quel riesame»: entro tre settimane dalla fotografia.
    static let giorniVicini: Double = 21

    var body: some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        return VStack(alignment: .leading, spacing: n.spazioBlocchiMomento) {
            if mese < 0 {
                passato
            } else if mese > 0 {
                futuro
            } else {
                oggi
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: Oggi

    @ViewBuilder private var oggi: some View {
        let r = stato.riepilogoPosizioniCliente(cliente.id)
        testata(quando: "Oggi · \(TestiMemoria.data(storia.oggi))", valore: storia.nettoOggi, sotto: "patrimonio netto")
        VStack(alignment: .leading, spacing: Tema.Apple.Clienti.NelTempo.spazioRigheMomento) {
            ForEach(Canale.allCases) { c in
                if let v = r.perCanale[c], abs(v) >= 0.5 { rigaCanale(c, v) }
            }
            if r.debiti >= 0.5 { riga("Debiti", Formati.euro(-r.debiti)) }
            riga("Proposte aperte", "\(r.proposteAperte)")
        }
        if let ultima = storia.fotografie.last {
            nota("Ultimo riesame il \(TestiMemoria.data(ultima.data)). Sposta il cursore a sinistra per rivederlo, a destra per la stima.")
        } else {
            nota("Sposta il cursore a sinistra per il patrimonio di allora, a destra per la stima dei prossimi due anni.")
        }
    }

    // MARK: Passato

    @ViewBuilder private var passato: some View {
        let giorno = storia.giorno(mese)
        let tempo = TestiMemoria.tempoFa(mesi: -mese)
        testata(quando: "\(Formati.meseAnno.string(from: giorno)) · \(tempo)", valore: storia.valore(mese, conProposte: false),
                sotto: "patrimonio netto di allora")
        if let vicina = storia.fotografiaVicina(a: giorno) {
            riesame(vicina.foto, stessoMese: vicina.stessoMese, giorno: giorno)
        } else {
            nota("Nessuna fotografia dei riesami: le cifre di allora vengono dai valori registrati delle posizioni.")
            posizioniDiAllora(giorno)
        }
    }

    @ViewBuilder private func riesame(_ foto: FotografiaRiesame, stessoMese: Bool, giorno: Date) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        VStack(alignment: .leading, spacing: n.spazioRigheMomento) {
            Text("Al riesame del \(TestiMemoria.data(foto.data))")
                .carattereApple(n.titoloRiesame)
                .foregroundColor(n.coloreRiga)
                .fixedSize(horizontal: false, vertical: true)
            if !stessoMese {
                nota("A \(Formati.meseAnno.string(from: giorno)) non c'è un riesame: questo è il più vicino.")
            }
            ForEach(Canale.allCases) { c in
                if abs(foto.patrimonio(c)) >= 0.5 { rigaCanale(c, foto.patrimonio(c)) }
            }
            if foto.debiti >= 0.5 { riga("Debiti", Formati.euro(-foto.debiti)) }
            riga("Patrimonio netto", Formati.euro(foto.patrimonioNetto))
            riga("Proposte aperte", "\(foto.proposteAperte)")
            if let checkUp = Self.checkUp(foto) { riga("Check-up", checkUp) }
        }
        cambiato(foto)
        noteRiesame(foto)
        Button("Apri i riesami ›") { stato.schedaCliente = .riesami }
            .buttonStyle(.appleSobrio)
            .help("La scheda Riesami del dossier: tutte le fotografie salvate")
    }

    /// «Cosa era cambiato» dalla fotografia precedente (le prime variazioni del motore della memoria).
    @ViewBuilder private func cambiato(_ foto: FotografiaRiesame) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        if let prima = storia.precedente(di: foto) {
            let variazioni = Array(MotoreMemoria.variazioni(da: prima, a: foto).prefix(n.massimoVariazioni))
            if !variazioni.isEmpty {
                VStack(alignment: .leading, spacing: n.spazioRigheMomento) {
                    Text("Rispetto al \(TestiMemoria.data(prima.data))")
                        .carattereApple(n.quando)
                        .foregroundColor(n.coloreQuando)
                    ForEach(variazioni) { v in
                        nota(v.testo)
                    }
                }
            }
        }
    }

    /// Le note di quel riesame: le decisioni dell'incontro e, fuori dalla modalità cliente, gli appunti e la nota.
    @ViewBuilder private func noteRiesame(_ foto: FotografiaRiesame) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let righe = righeNote(foto)
        if !righe.isEmpty {
            VStack(alignment: .leading, spacing: n.spazioRigheMomento) {
                Text("Le note di allora")
                    .carattereApple(n.quando)
                    .foregroundColor(n.coloreQuando)
                ForEach(righe, id: \.self) { r in
                    nota(r)
                }
            }
        }
    }

    private func righeNote(_ foto: FotografiaRiesame) -> [String] {
        let vicino = Self.giorniVicini * 86_400
        let id = cliente.id
        let incontri = stato.dati.incontri.filter {
            $0.clienteId == id && $0.stato == .concluso && abs($0.data.timeIntervalSince(foto.data)) <= vicino
        }
        func distanza(_ i: Incontro) -> Double { abs(i.data.timeIntervalSince(foto.data)) }
        let diRiesame = incontri.filter { stato.incontroDiRiesame($0) }
        let incontro = diRiesame.min { distanza($0) < distanza($1) } ?? incontri.min { distanza($0) < distanza($1) }
        var righe: [String] = []
        if let i = incontro {
            let decisioni = i.decisioni.trimmingCharacters(in: .whitespacesAndNewlines)
            if !decisioni.isEmpty { righe.append("Decisioni: \(Self.corto(decisioni))") }
            let appunti = i.appunti.trimmingCharacters(in: .whitespacesAndNewlines)
            if !riservato, !appunti.isEmpty { righe.append("Appunti: \(Self.corto(appunti))") }
        }
        if !riservato, let nota = stato.dati.note
            .filter({ $0.clienteId == id && abs($0.creataIl.timeIntervalSince(foto.data)) <= vicino })
            .min(by: { abs($0.creataIl.timeIntervalSince(foto.data)) < abs($1.creataIl.timeIntervalSince(foto.data)) }) {
            righe.append("Nota: \(Self.corto(nota.titoloMostrato))")
        }
        return righe
    }

    /// Le posizioni di allora (senza fotografie): le più grandi al valore registrato di quel giorno.
    @ViewBuilder private func posizioniDiAllora(_ giorno: Date) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let voci = stato.posizioniCliente(cliente.id)
            .filter { $0.stato == .inEssere && !$0.area.passivo && $0.area != .protezione }
            .map { PosizioneDiAllora(posizione: $0, valore: MotoreAndamentoPortafoglio.valore($0, al: giorno)) }
            .filter { $0.valore >= 0.5 }
            .sorted { $0.valore > $1.valore }
        let prime = Array(voci.prefix(n.massimoPosizioni))
        if !prime.isEmpty {
            VStack(alignment: .leading, spacing: n.spazioRigheMomento) {
                ForEach(prime) { v in
                    HStack(spacing: n.spazioRiga) {
                        EtichettaCanaleApple(canale: v.posizione.canale, compatta: true)
                        Text(v.posizione.nome)
                            .carattereApple(n.riga)
                            .foregroundColor(n.coloreRiga)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: n.minimoRiga)
                        Text(Formati.euro(v.valore))
                            .carattereApple(n.valoreRiga)
                            .foregroundColor(n.coloreRiga)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }
        }
    }

    // MARK: Futuro

    @ViewBuilder private var futuro: some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        let giorno = storia.giorno(mese)
        let stima = storia.stima(conProposte: conProposte)
        let tra = mese == 1 ? "tra 1 mese" : "tra \(mese) mesi"
        Text("Stima, non una previsione")
            .carattereApple(n.quando)
            .foregroundColor(n.coloreAvvisoStima)
        testata(quando: "\(Formati.meseAnno.string(from: giorno)) · \(tra)", valore: stima.centrale[mese],
                sotto: storia.haProposte ? (conProposte ? "con le proposte aperte" : "senza le proposte aperte") : "con le posizioni di oggi")
        if stima.esposta {
            VStack(alignment: .leading, spacing: n.spazioRigheMomento) {
                riga("1 caso su 10 sotto", Formati.euro(stima.bassa[mese]))
                riga("1 caso su 10 sopra", Formati.euro(stima.alta[mese]))
            }
            nota("Rendimenti ipotizzati delle posizioni e oscillazioni dal loro profilo di rischio, su \(Formati.numeroFormatter.string(from: NSNumber(value: stima.scenari)) ?? "\(stima.scenari)") scenari; immobili al valore di oggi, debiti che si estinguono, prima delle imposte finali.")
        } else {
            nota("Le posizioni non oscillano con i mercati: la stima segue i rendimenti ipotizzati, immobili al valore di oggi e debiti che si estinguono.")
        }
    }

    // MARK: Pezzi comuni

    @ViewBuilder private func testata(quando: String, valore: Double, sotto: String) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        VStack(alignment: .leading, spacing: n.spazioTestata) {
            Text(quando)
                .carattereApple(n.quando)
                .foregroundColor(n.coloreQuando)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(Formati.euro(valore))
                .carattereApple(n.valore)
                .foregroundColor(n.coloreValore)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sotto)
                .carattereApple(n.sottoValore)
                .foregroundColor(n.coloreSottoValore)
        }
    }

    private func rigaCanale(_ c: Canale, _ v: Double) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        return HStack(spacing: n.spazioRiga) {
            EtichettaCanaleApple(canale: c, compatta: true)
            Spacer(minLength: n.minimoRiga)
            Text(Formati.euro(v))
                .carattereApple(n.valoreRiga)
                .foregroundColor(n.coloreRiga)
                .lineLimit(1)
        }
    }

    private func riga(_ etichetta: String, _ valore: String) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        return HStack(spacing: n.spazioRiga) {
            Text(etichetta)
                .carattereApple(n.riga)
                .foregroundColor(n.coloreNota)
                .lineLimit(1)
            Spacer(minLength: n.minimoRiga)
            Text(valore)
                .carattereApple(n.valoreRiga)
                .foregroundColor(n.coloreRiga)
                .lineLimit(1)
        }
    }

    private func nota(_ testo: String) -> some View {
        let n = Tema.Apple.Clienti.NelTempo.self
        return Text(testo)
            .carattereApple(n.nota)
            .foregroundColor(n.coloreNota)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Il check-up della fotografia in breve: «2 rossi · 1 giallo · 4 verdi».
    static func checkUp(_ foto: FotografiaRiesame) -> String? {
        guard !foto.semafori.isEmpty else { return nil }
        let colori: [(colore: Semaforo, uno: String, piu: String)] = [
            (colore: .rosso, uno: "rosso", piu: "rossi"),
            (colore: .giallo, uno: "giallo", piu: "gialli"),
            (colore: .verde, uno: "verde", piu: "verdi"),
        ]
        let parti = colori.compactMap { voce -> String? in
            let k = foto.conta(voce.colore)
            return k > 0 ? "\(k) \(k == 1 ? voce.uno : voce.piu)" : nil
        }
        return parti.isEmpty ? nil : parti.joined(separator: " · ")
    }

    static func corto(_ testo: String) -> String {
        let limite = Tema.Apple.Clienti.NelTempo.caratteriNota
        let una = testo.replacingOccurrences(of: "\n", with: " ")
        guard una.count > limite else { return una }
        return String(una.prefix(limite)).trimmingCharacters(in: .whitespaces) + "…"
    }
}

/// Una posizione al valore registrato di un giorno passato.
private struct PosizioneDiAllora: Identifiable {
    let posizione: Posizione
    let valore: Double
    var id: String { posizione.id }
}

// MARK: - Istantanee

/// Il mese che una scena delle istantanee chiede al cursore di «Nel tempo» (Prisma --istantanee). Vale solo per lo
/// stato della scena (riferimento debole: le scene dopo non lo vedono).
final class RichiestaIstantaneaNelTempo {
    nonisolated(unsafe) private static var attuale: RichiestaIstantaneaNelTempo?

    private weak var stato: StatoShell?
    let mese: Int

    private init(stato: StatoShell, mese: Int) {
        self.stato = stato
        self.mese = mese
    }

    static func chiedi(_ s: StatoShell, mese: Int) {
        attuale = RichiestaIstantaneaNelTempo(stato: s, mese: mese)
    }

    static func per(_ s: StatoShell) -> Int? {
        guard let r = attuale, r.stato === s else { return nil }
        return r.mese
    }
}
