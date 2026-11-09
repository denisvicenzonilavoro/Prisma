#if os(iOS)
import SwiftUI

// Le schermate del tavolo sull'iPad (ModalitaTavoloiPad in TavoloiPad.swift): tutte di sola lettura, con i dati già
// calcolati dal Mac, tranne il cursore lasciato al cliente e l'area della presa visione.
// - Neutra: il logo sull'acqua, nessun dato.
// - Pagina e prospetto: il foglio (PNG del Mac, sempre su carta bianca) a tutto schermo su fondo scuro, come la sala.
// - Macchina del tempo e famiglia: una finestra di vetro sull'acqua nel tema Apple. In alto la cosa principale grande
//   (il patrimonio di oggi, le persone), poi ciò che serve per capire (il grafico, le scoperture), poi la nota.
// - Cursore: il valore grande e il cursore del tema; ogni spostamento va al Mac, che rimanda il risultato ricalcolato.
// - Presa visione: la scritta esatta, l'area per il tratto (dito o Pencil: un Canvas di SwiftUI con DragGesture,
//   leggero e uguale ovunque), «Annulla» (cancella il tratto) e «Conferma» (il PNG va al Mac).
// Valori grafici in DesignSystem/Apple/Tema.Apple+TavoloiPad.swift (e quelli del dossier per tempo e famiglia).

private typealias T = Tema.Apple.Tavolo.iPad

// MARK: - Schermata neutra

/// Il logo sull'acqua, nient'altro; sotto, solo se l'iPad non è collegato, una riga sullo stato del collegamento.
struct NeutraTavoloiPad: View {
    let collegamento: ClienteTavolo.Collegamento

    var body: some View {
        VStack(spacing: T.spazioLogo) {
            LogoPrisma(colore: T.coloreLogo)
                .frame(height: T.logo)
            Text(stato ?? " ")
                .carattereApple(T.stato)
                .foregroundColor(T.coloreStato)
                .opacity(stato == nil ? 0 : 1)
                .accessibilityHidden(stato == nil)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var stato: String? {
        switch collegamento {
        case .collegato: return nil
        case .cerca, .abbinamento: return "Mi collego al Mac…"
        case .scollegato, .rifiutato, .caduto, .irraggiungibile: return "In attesa del Mac…"
        }
    }
}

// MARK: - Pagina e prospetto

/// Il foglio a tutto schermo su fondo scuro (la sala); un prospetto intero si sfoglia di lato.
struct PagineTavoloiPad: View {
    let mostra: MostraTavolo
    @State private var indice = 0

    var body: some View {
        ZStack {
            T.fondoPagina
                .ignoresSafeArea()
            if mostra.pagine.count == 1, let pagina = mostra.pagine.first {
                FoglioTavoloiPad(pagina: pagina)
            } else {
                TabView(selection: $indice) {
                    ForEach(Array(mostra.pagine.enumerated()), id: \.offset) { i, pagina in
                        FoglioTavoloiPad(pagina: pagina)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .overlay(alignment: .bottom) {
            Text(didascalia)
                .carattereApple(T.didascalia)
                .foregroundColor(T.coloreDidascalia)
                .lineLimit(1)
                .frame(height: T.altezzaDidascalia)
                .padding(.horizontal, T.marginePagina)
        }
    }

    private var didascalia: String {
        let i = min(max(indice, 0), max(mostra.pagine.count - 1, 0))
        guard mostra.pagine.indices.contains(i) else { return mostra.titolo }
        let p = mostra.pagine[i]
        return "Pagina \(p.numero) di \(p.totale) · \(mostra.titolo)"
    }
}

/// Un foglio: il PNG si apre quando la pagina compare e si lascia quando se ne va (un prospetto lungo non resta
/// tutto in memoria).
private struct FoglioTavoloiPad: View {
    let pagina: PaginaTavolo
    @State private var immagine: CGImage?

    var body: some View {
        GeometryReader { g in
            let w = CGFloat(max(pagina.larghezza, 1))
            let h = CGFloat(max(pagina.altezza, 1))
            let libera = CGSize(width: max(0, g.size.width - 2 * T.marginePagina),
                                height: max(0, g.size.height - 2 * T.marginePagina - T.altezzaDidascalia))
            let scala = min(libera.width / w, libera.height / h)
            Group {
                if let immagine {
                    Image(immagine, scale: Tema.Apple.Tavolo.scalaPagina, label: Text("Pagina \(pagina.numero) di \(pagina.totale)"))
                        .resizable()
                        .interpolation(.high)
                } else {
                    Tema.Apple.Carta.fondo
                }
            }
            .frame(width: w * scala, height: h * scala)
            .ombraApple(.carta)
            .position(x: g.size.width / 2, y: T.marginePagina + libera.height / 2)
        }
        .onAppear { immagine = ProtocolloTavolo.immagine(pagina.png) }
        .onDisappear { immagine = nil }
    }
}

// MARK: - La finestra di vetro e la testata

/// La finestra di vetro al centro, sopra l'acqua (come quelle del Mac); scorre se il contenuto è lungo.
private struct FinestraTavoloiPad<Contenuto: View>: View {
    var scorre = true
    @ViewBuilder let contenuto: () -> Contenuto

    var body: some View {
        GeometryReader { g in
            if scorre {
                ScrollView {
                    finestra
                        .frame(minHeight: g.size.height)
                }
            } else {
                finestra
                    .frame(width: g.size.width, height: g.size.height)
            }
        }
    }

    private var finestra: some View {
        VStack(alignment: .leading, spacing: T.spazioBlocchi) {
            contenuto()
        }
        .padding(T.padding)
        .frame(maxWidth: T.larghezzaMassima, alignment: .leading)
        .superficieApple(T.superficie)
        .padding(T.margineEsterno)
        .frame(maxWidth: .infinity)
    }
}

/// «IL PATRIMONIO NEL TEMPO», il titolo grande e il canale (sempre riconoscibile) a destra.
private struct TestataTavoloiPad: View {
    let sopratitolo: String
    let titolo: String
    var sottotitolo: String? = nil
    var canale: Canale? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: T.spazioTestata) {
            Text(sopratitolo)
                .carattereApple(T.sopratitolo)
                .foregroundColor(T.coloreSopratitolo)
                .lineLimit(1)
            HStack(alignment: .center, spacing: T.spazioRighe) {
                Text(titolo)
                    .carattereApple(T.titolo)
                    .foregroundColor(T.coloreTitolo)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if let canale {
                    EtichettaCanaleApple(canale: canale)
                }
            }
            if let sottotitolo {
                Text(sottotitolo)
                    .carattereApple(T.sottotitolo)
                    .foregroundColor(T.coloreSottotitolo)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .entrataCascata(0, base: Tema.Apple.Moto.Cascata.baseDentroApp)
    }
}

// MARK: - La macchina del tempo

/// Il patrimonio netto tre anni indietro e due avanti, già calcolato dal Mac: oggi grande, poi il grafico e la nota.
struct NelTempoTavoloiPad: View {
    let mostra: MostraTavolo
    let dati: NelTempoTavolo

    private typealias N = Tema.Apple.Clienti.NelTempo

    var body: some View {
        FinestraTavoloiPad {
            TestataTavoloiPad(sopratitolo: mostra.titolo, titolo: mostra.cliente, canale: mostra.canale)
            VStack(alignment: .leading, spacing: T.spazioTestata) {
                Text("Patrimonio netto oggi")
                    .carattereApple(T.titoloRisultato)
                    .foregroundColor(T.coloreTitoloRisultato)
                NumeroCheConta(dati.nettoOggi, formato: .euro)
                    .carattereApple(T.cifraRisultato)
                    .foregroundColor(T.coloreCifra)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            VStack(alignment: .leading, spacing: N.sopraGrafico) {
                legenda
                GraficoNelTempoTavoloiPad(dati: dati)
                    .frame(height: T.altezzaGraficoNelTempo)
                dateAsse
            }
            .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            Text(dati.nota)
                .carattereApple(T.nota)
                .foregroundColor(T.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
        }
    }

    private var legenda: some View {
        HStack(spacing: N.spazioLegenda) {
            voce("Com'è andato", colore: N.colorePassato, tratteggio: false)
            voce("Stima", colore: N.coloreStimaSenza, tratteggio: true)
            if dati.centraleConProposte != nil {
                voce("Con le proposte", colore: N.coloreStima, tratteggio: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func voce(_ testo: String, colore: Color, tratteggio: Bool) -> some View {
        HStack(spacing: N.spazioSegnoLegenda) {
            SegnoLegendaTavolo()
                .stroke(colore, style: StrokeStyle(lineWidth: N.spessoreStima, lineCap: .round,
                                                   dash: tratteggio ? T.tratteggioLegenda : []))
                .frame(width: T.segnoLegenda, height: N.spessoreStima)
            Text(testo)
                .carattereApple(N.legenda)
                .foregroundColor(N.coloreLegenda)
        }
    }

    /// «nov 2023» a sinistra, «oggi» al 60%, «nov 2028» a destra (scritte dal Mac).
    private var dateAsse: some View {
        GeometryReader { g in
            let larghezza = max(0, g.size.width - N.colonnaValori)
            ZStack(alignment: .topLeading) {
                Text(dati.inizio)
                    .carattereApple(N.date)
                    .foregroundColor(N.coloreAsse)
                    .frame(width: larghezza, alignment: .leading)
                Text(dati.fine)
                    .carattereApple(N.date)
                    .foregroundColor(N.coloreAsse)
                    .frame(width: larghezza, alignment: .trailing)
                Text(dati.oggi)
                    .carattereApple(N.oggi)
                    .foregroundColor(N.coloreOggi)
                    .fixedSize()
                    .position(x: larghezza * N.quotaPassato, y: N.altezzaDate / 2)
            }
        }
        .frame(height: N.altezzaDate)
        .accessibilityHidden(true)
    }
}

/// Il segno della legenda: una linea orizzontale.
private struct SegnoLegendaTavolo: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

/// Il grafico della macchina del tempo con i pezzi del tema (griglia, tracciati, fascia) e la scala del dossier:
/// x con «oggi» al 60%, y fra il minimo e il massimo di tutte le serie con i margini del template.
private struct GraficoNelTempoTavoloiPad: View {
    let dati: NelTempoTavolo

    private typealias N = Tema.Apple.Clienti.NelTempo

    var body: some View {
        let s = Scala(dati)
        let stimaSenza = s.futuro(dati.centrale)
        return HStack(spacing: 0) {
            ZStack {
                GrigliaGrafico(oggi: N.quotaPassato)
                TracciatoGrafico(punti: s.passato(dati.passato), colore: N.colorePassato, spessore: N.spessorePassato,
                                 area: true, indice: 0, ritardo: N.ritardoLinee)
                if dati.esposta {
                    FasciaGrafico(sopra: s.futuro(dati.alta), sotto: s.futuro(dati.bassa), colore: N.coloreStimaSenza,
                                  ritardo: N.ritardoLinee)
                }
                TracciatoGrafico(punti: stimaSenza, colore: N.coloreStimaSenza, spessore: N.spessoreStima,
                                 tratteggio: N.tratteggioStima, indice: 1, ritardo: N.ritardoLinee)
                if let con = dati.centraleConProposte {
                    TracciatoGrafico(punti: s.futuro(con), colore: N.coloreStima, spessore: N.spessoreStima,
                                     tratteggio: N.tratteggioStima, indice: 2, ritardo: N.ritardoLinee)
                }
                riesami(s)
            }
            valoriAsse(s)
                .frame(width: N.colonnaValori)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Patrimonio netto: oggi \(Formati.euro(dati.nettoOggi)). \(dati.nota)"))
    }

    /// I riesami: cerchi vuoti sulla linea del passato.
    private func riesami(_ s: Scala) -> some View {
        GeometryReader { g in
            ForEach(Array(dati.fotografie.enumerated()), id: \.offset) { _, foto in
                let p = s.punto(mese: foto.mese, valore: foto.valore)
                Circle()
                    .fill(N.fondoRiesame)
                    .overlay(Circle().stroke(N.colorePassato, lineWidth: N.bordoRiesame))
                    .frame(width: 2 * N.raggioRiesame, height: 2 * N.raggioRiesame)
                    .position(x: p.x * g.size.width, y: ScalaNelTempo.yAsse(p.y, altezza: g.size.height))
            }
        }
        .allowsHitTesting(false)
    }

    /// I valori delle righe della griglia, a destra («318k €»).
    private func valoriAsse(_ s: Scala) -> some View {
        let righe = Tema.Apple.Grafico.Tracciato.righeGriglia
        let passi = max(1, righe - 1)
        return GeometryReader { g in
            ForEach(0..<righe, id: \.self) { k in
                let f = CGFloat(k) / CGFloat(passi)
                Text(Formati.euroBreve(s.valore(frazione: Double(f))))
                    .carattereApple(N.valoriAsse)
                    .foregroundColor(N.coloreAsse)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: g.size.width, alignment: .trailing)
                    .position(x: g.size.width / 2, y: ScalaNelTempo.yAsse(f, altezza: g.size.height))
            }
        }
        .accessibilityHidden(true)
    }

    /// La scala del grafico sui dati ricevuti (le serie possono avere lunghezze qualsiasi).
    struct Scala {
        let basso: Double
        let alto: Double
        let mesiIndietro: Int
        let mesiAvanti: Int

        init(_ d: NelTempoTavolo) {
            let valori = d.passato + d.centrale + d.alta + d.bassa + (d.centraleConProposte ?? [])
                + d.fotografie.map(\.valore)
            let minimo = valori.min() ?? 0
            let massimo = valori.max() ?? 1
            var b = minimo - abs(minimo) * (1 - N.margineSotto)
            var a = massimo + abs(massimo) * (N.margineSopra - 1)
            if a - b < 1 {
                b -= 0.5
                a = b + 1
            }
            basso = b
            alto = a
            mesiIndietro = max(1, d.passato.count - 1)
            mesiAvanti = max(1, d.centrale.count - 1)
        }

        /// Il mese da −mesiIndietro a +mesiAvanti (0 = oggi).
        func x(mese k: Int) -> CGFloat {
            let q = N.quotaPassato
            if k <= 0 { return q * CGFloat(k + mesiIndietro) / CGFloat(mesiIndietro) }
            return q + (1 - q) * CGFloat(k) / CGFloat(mesiAvanti)
        }

        func punto(mese k: Int, valore v: Double) -> CGPoint {
            CGPoint(x: x(mese: k), y: CGFloat((v - basso) / (alto - basso)))
        }

        func valore(frazione f: Double) -> Double { basso + (alto - basso) * f }

        func passato(_ serie: [Double]) -> [CGPoint] {
            serie.enumerated().map { i, v in punto(mese: i - mesiIndietro, valore: v) }
        }

        func futuro(_ serie: [Double]) -> [CGPoint] {
            serie.enumerated().map { k, v in punto(mese: k, valore: v) }
        }
    }
}

// MARK: - La linea della vita

/// La linea della vita del cliente, già calcolata dal Mac e ferma (i gettoni si spostano sul Mac): in alto grande
/// fino a quando basta il patrimonio, poi le due cifre, il grafico del dossier, gli eventi e la nota.
struct LineaVitaTavoloiPad: View {
    let mostra: MostraTavolo
    let dati: LineaVitaTavolo

    private typealias L = Tema.Apple.Clienti.LineaVita

    var body: some View {
        let esito = dati.esito
        let basta: String = dati.etaEsaurimento.map { "fino a \($0) anni" } ?? "oltre i \(dati.etaFine) anni"
        return FinestraTavoloiPad {
            TestataTavoloiPad(sopratitolo: mostra.titolo, titolo: mostra.cliente, sottotitolo: "Da oggi a \(dati.etaFine) anni, in euro di oggi")
            VStack(alignment: .leading, spacing: T.spazioTestata) {
                Text("Il patrimonio basta")
                    .carattereApple(T.titoloRisultato)
                    .foregroundColor(T.coloreTitoloRisultato)
                Text(basta)
                    .carattereApple(T.cifraRisultato)
                    .foregroundColor(esito.basta ? L.coloreBasta : L.coloreFinisce)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            VStack(alignment: .leading, spacing: T.spazioRighe) {
                riga("A \(dati.etaPensione) anni, in pensione", FormatoCifra.euro.testo(max(0, dati.allaPensione)))
                riga("Al massimo, a \(dati.etaMassimo) anni", FormatoCifra.euro.testo(max(0, dati.massimo)))
                GraficoLineaVita(esito: esito, etaOggi: dati.etaOggi,
                                 entrate: dati.eventi.filter { ($0.importo ?? 0) > 0 }.map(\.eta),
                                 uscite: dati.eventi.filter { ($0.importo ?? 0) < 0 }.map(\.eta))
                    .frame(height: L.altezzaGraficoTavolo)
                    .padding(.top, L.sopraGrafico)
            }
            .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            if !dati.eventi.isEmpty {
                VStack(alignment: .leading, spacing: T.spazioRighe) {
                    ForEach(Array(dati.eventi.enumerated()), id: \.offset) { _, e in
                        riga("\(e.nome) · \(e.eta) anni", e.importo.map { FormatoCifra.euro.testo($0) } ?? "senza cifra")
                    }
                }
                .entrataCascata(3, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
            }
            Text(dati.nota)
                .carattereApple(T.nota)
                .foregroundColor(T.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .entrataCascata(4, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
        }
    }

    private func riga(_ etichetta: String, _ valore: String) -> some View {
        HStack(spacing: T.spazioRighe) {
            Text(etichetta)
                .carattereApple(T.riga)
                .foregroundColor(T.coloreRiga)
                .lineLimit(1)
            Spacer(minLength: T.spazioRighe)
            Text(valore)
                .carattereApple(T.valoreRiga)
                .foregroundColor(T.coloreRiga)
                .lineLimit(1)
        }
    }
}

// MARK: - La famiglia

/// Le persone del nucleo con le loro scoperture, in sola lettura (le capsule non portano da nessuna parte).
struct FamigliaTavoloiPad: View {
    let mostra: MostraTavolo
    let dati: FamigliaTavolo

    private typealias F = Tema.Apple.Clienti.Famiglia

    var body: some View {
        let colonne = min(F.colonneMassime, max(F.colonneMinime, dati.persone.count))
        let griglia = Array(repeating: GridItem(.flexible(), spacing: F.spazio, alignment: .top), count: colonne)
        return FinestraTavoloiPad {
            TestataTavoloiPad(sopratitolo: mostra.titolo, titolo: mostra.cliente, canale: mostra.canale)
            LazyVGrid(columns: griglia, alignment: .leading, spacing: F.spazio) {
                ForEach(Array(dati.persone.enumerated()), id: \.offset) { i, persona in
                    SchedaPersonaTavoloiPad(persona: persona, tinta: Self.tinte[i % Self.tinte.count].colori)
                        .entrataCascata(i + 1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                }
            }
            Text(dati.nota)
                .carattereApple(F.fonte)
                .foregroundColor(F.coloreFonte)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Le tinte degli avatar a giro, come nel dossier.
    private static let tinte: [TintaAvatar] = [.blu, .rosa, .verde, .viola, .oro]
}

private struct SchedaPersonaTavoloiPad: View {
    let persona: PersonaTavolo
    let tinta: Colori.Avatar.Tinta

    private typealias F = Tema.Apple.Clienti.Famiglia

    var body: some View {
        VStack(spacing: 0) {
            AvatarCliente(iniziali: persona.iniziali, tinta: tinta, lato: F.avatar)
            Text(persona.nome)
                .carattereApple(F.nome)
                .foregroundColor(F.coloreNome)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.top, F.sopraNome)
            Text(persona.descrizione)
                .carattereApple(F.descrizione)
                .foregroundColor(F.coloreDescrizione)
                .lineLimit(2)
                .padding(.top, F.spazioNomeDescrizione)
            if !persona.scoperture.isEmpty {
                VStack(spacing: F.fraCapsule) {
                    ForEach(Array(persona.scoperture.enumerated()), id: \.offset) { _, s in
                        capsula(s)
                    }
                }
                .padding(.top, F.sopraCapsule)
            }
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .padding(F.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .superficieApple(F.superficie)
        .accessibilityElement(children: .combine)
    }

    private func capsula(_ s: ScoperturaTavolo) -> some View {
        let tono = colore(s.tono)
        return Text(s.testo)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .carattereApple(F.capsula)
            .foregroundColor(tono)
            .padding(F.paddingCapsula)
            .background { Capsule(style: .continuous).fill(tono.opacity(F.opacitaFondoCapsula)) }
    }

    private func colore(_ t: TonoTavolo) -> Color {
        switch t {
        case .rosso: return F.rosso
        case .arancio: return F.arancio
        case .verde: return F.verde
        }
    }
}

// MARK: - Il cursore lasciato al cliente

/// Il valore grande e il cursore del tema con i limiti del Mac; sotto il risultato ricalcolato dal Mac, attenuato
/// finché il Mac non ha risposto per il valore scelto.
struct CursoreTavoloiPad: View {
    let cursore: CursoreTavolo
    let manda: (Double) -> Void

    /// Il valore sotto il dito: nasce con il cursore del Mac (una schermata nuova per ogni cursore nuovo) e non
    /// segue le risposte del Mac, che possono arrivare per valori già superati.
    @State private var valore: Double
    @State private var inviato: Double

    init(cursore: CursoreTavolo, manda: @escaping (Double) -> Void) {
        self.cursore = cursore
        self.manda = manda
        _valore = State(initialValue: cursore.valore)
        _inviato = State(initialValue: cursore.valore)
    }

    var body: some View {
        FinestraTavoloiPad(scorre: false) {
            TestataTavoloiPad(sopratitolo: cursore.titolo, titolo: cursore.posizione, canale: cursore.canale)
            sceltaDelCliente
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            Rectangle()
                .fill(T.filo)
                .frame(height: T.spessoreFilo)
            risultato
                .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
        }
        .onChange(of: valore) { v in
            let x = cursore.valido(v)
            guard x != inviato else { return }
            inviato = x
            manda(x)
        }
    }

    private var intervallo: ClosedRange<Double> {
        cursore.minimo...max(cursore.minimo, cursore.massimo)
    }

    private var sceltaDelCliente: some View {
        VStack(alignment: .leading, spacing: T.spazioRighe) {
            HStack(alignment: .firstTextBaseline, spacing: T.spazioTestata) {
                Text(FormatoCifra.intero.testo(cursore.valido(valore)))
                    .carattereApple(T.valoreCursore)
                    .foregroundColor(T.coloreValore)
                    .lineLimit(1)
                Text(cursore.unita)
                    .carattereApple(T.unita)
                    .foregroundColor(T.coloreUnita)
                    .lineLimit(1)
            }
            .accessibilityHidden(true)
            CursoreApple(valore: $valore, intervallo: intervallo, passo: cursore.passo,
                         etichetta: "\(cursore.titolo), \(cursore.unita)")
            HStack {
                Text(Formati.euro(cursore.minimo))
                Spacer(minLength: 0)
                Text(Formati.euro(cursore.massimo))
            }
            .carattereApple(T.limiti)
            .foregroundColor(T.coloreLimiti)
            .accessibilityHidden(true)
        }
    }

    /// true finché il risultato mostrato non è quello del valore scelto.
    private var ricalcolo: Bool {
        guard let r = cursore.risultato else { return true }
        return abs(r.valore - cursore.valido(valore)) > 0.000_1
    }

    @ViewBuilder private var risultato: some View {
        if let r = cursore.risultato {
            VStack(alignment: .leading, spacing: T.spazioRighe) {
                Text(r.titolo)
                    .carattereApple(T.titoloRisultato)
                    .foregroundColor(T.coloreTitoloRisultato)
                NumeroCheConta(r.cifra, formato: .euro, da: nil)
                    .carattereApple(T.cifraRisultato)
                    .foregroundColor(T.coloreCifra)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                VStack(spacing: 0) {
                    ForEach(Array(r.righe.enumerated()), id: \.offset) { i, riga in
                        HStack(alignment: .firstTextBaseline) {
                            Text(riga.etichetta)
                                .carattereApple(T.riga)
                                .foregroundColor(T.coloreRiga)
                            Spacer(minLength: T.spazioRighe)
                            Text(Formati.euro(riga.cifra))
                                .carattereApple(T.valoreRiga)
                                .foregroundColor(T.coloreRiga)
                        }
                        .padding(.vertical, T.spazioRighe)
                        if i < r.righe.count - 1 {
                            Rectangle()
                                .fill(T.filo)
                                .frame(height: T.spessoreFilo)
                        }
                    }
                }
                Text(r.nota)
                    .carattereApple(T.nota)
                    .foregroundColor(T.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(ricalcolo ? T.opacitaRicalcolo : 1)
            .accessibilityElement(children: .combine)
        } else {
            Text("Il Mac sta calcolando…")
                .carattereApple(T.sottotitolo)
                .foregroundColor(T.coloreSottotitolo)
        }
    }
}

// MARK: - La presa visione

/// La richiesta del Mac: la scritta esatta, l'area per il tratto, «Annulla» e «Conferma». Confermata, il tratto va al
/// Mac e l'area si ferma: sarà il Mac a cambiare schermata, dopo aver archiviato il documento.
struct PresaVisioneTavoloiPad: View {
    let richiesta: RichiestaPresaVisioneTavolo
    let conferma: (Data) -> Void

    @State private var tratti: [[CGPoint]]
    @State private var corrente: [CGPoint] = []
    @State private var inviata = false
    @State private var errore: String?

    init(richiesta: RichiestaPresaVisioneTavolo, trattoIniziale: [[CGPoint]] = [], conferma: @escaping (Data) -> Void) {
        self.richiesta = richiesta
        self.conferma = conferma
        _tratti = State(initialValue: trattoIniziale)
    }

    private var vuoto: Bool { tratti.isEmpty && corrente.isEmpty }

    var body: some View {
        FinestraTavoloiPad(scorre: false) {
            TestataTavoloiPad(sopratitolo: "Presa visione", titolo: richiesta.titolo, sottotitolo: sottotitolo)
            // La scritta esatta, sempre quella del protocollo (la stessa del PDF)
            Text(ProtocolloTavolo.testoPresaVisione)
                .carattereApple(T.testoPresaVisione)
                .foregroundColor(T.coloreTestoPresaVisione)
                .fixedSize(horizontal: false, vertical: true)
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            AreaTrattoTavoloiPad(tratti: $tratti, corrente: $corrente, attiva: !inviata)
                .frame(maxWidth: .infinity)
                .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp, sfocatura: false)
            HStack(spacing: T.spazioPulsanti) {
                Button("Annulla") {
                    tratti = []
                    corrente = []
                    errore = nil
                }
                .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
                .disabled(vuoto || inviata)
                Spacer(minLength: 0)
                if inviata {
                    Text("Mandata al Mac")
                        .carattereApple(T.avviso)
                        .foregroundColor(T.coloreAvviso)
                }
                Button("Conferma", action: confermaTratto)
                    .buttonStyle(StilePulsanteApple(.principale, grande: true))
                    .disabled(vuoto || inviata)
            }
            if let errore {
                Text(errore)
                    .carattereApple(T.esito)
                    .foregroundColor(T.coloreEsito)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var sottotitolo: String {
        let pagine = richiesta.pagine == 1 ? "1 pagina" : "\(richiesta.pagine) pagine"
        return "\(richiesta.cliente) · \(pagine)"
    }

    private func confermaTratto() {
        guard !inviata else { return }
        var tutti = tratti
        if !corrente.isEmpty { tutti.append(corrente) }
        guard !tutti.isEmpty else { return }
        guard let png = TrattoTavoloiPad.png(tutti), png.count <= ProtocolloTavolo.massimoTratto else {
            errore = "Non riesco a preparare il tratto: cancellalo con «Annulla» e riprova."
            return
        }
        errore = nil
        inviata = true
        conferma(png)
    }
}

/// L'area del tratto: carta bianca con la riga su cui firmare; il dito o la Pencil disegnano con l'inchiostro fisso
/// del PDF. I punti sono in frazioni dell'area (0…1), così il PNG non dipende dalla misura sullo schermo.
private struct AreaTrattoTavoloiPad: View {
    @Binding var tratti: [[CGPoint]]
    @Binding var corrente: [CGPoint]
    let attiva: Bool

    var body: some View {
        GeometryReader { g in
            let misura = g.size
            ZStack {
                RoundedRectangle(cornerRadius: T.raggioArea, style: .continuous)
                    .fill(T.fondoArea)
                RigaFirmaTavolo(quota: T.quotaRigaArea, margine: T.margineRigaArea)
                    .stroke(T.rigaArea, lineWidth: T.spessoreRigaArea)
                if tratti.isEmpty && corrente.isEmpty {
                    Text("Con il dito o con la Pencil")
                        .carattereApple(T.suggerimentoArea)
                        .foregroundColor(T.coloreSuggerimento)
                        .position(x: misura.width / 2, y: misura.height * (1 + T.quotaRigaArea) / 2)
                }
                Canvas { contesto, dimensione in
                    let stile = StrokeStyle(lineWidth: T.spessoreTratto, lineCap: .round, lineJoin: .round)
                    for t in tratti {
                        contesto.stroke(TrattoTavoloiPad.percorso(t, in: dimensione), with: .color(T.inchiostro), style: stile)
                    }
                    if !corrente.isEmpty {
                        contesto.stroke(TrattoTavoloiPad.percorso(corrente, in: dimensione), with: .color(T.inchiostro), style: stile)
                    }
                }
                RoundedRectangle(cornerRadius: T.raggioArea, style: .continuous)
                    .strokeBorder(T.bordoArea, lineWidth: T.spessoreBordoArea)
            }
            .clipShape(RoundedRectangle(cornerRadius: T.raggioArea, style: .continuous))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { v in
                        guard attiva, misura.width > 0, misura.height > 0 else { return }
                        let x = min(max(v.location.x / misura.width, 0), 1)
                        let y = min(max(v.location.y / misura.height, 0), 1)
                        corrente.append(CGPoint(x: x, y: y))
                    }
                    .onEnded { _ in
                        guard !corrente.isEmpty else { return }
                        tratti.append(corrente)
                        corrente = []
                    }
            )
        }
        .aspectRatio(T.rapportoArea, contentMode: .fit)
        .frame(maxWidth: T.larghezzaArea)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Area per la presa visione"))
        .accessibilityValue(Text(tratti.isEmpty ? "Vuota" : "Tratto presente"))
    }
}

/// La riga su cui firmare.
private struct RigaFirmaTavolo: Shape {
    let quota: CGFloat
    let margine: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = rect.minY + rect.height * quota
        p.move(to: CGPoint(x: rect.minX + margine, y: y))
        p.addLine(to: CGPoint(x: rect.maxX - margine, y: y))
        return p
    }
}

/// Il tratto: il percorso morbido (curve fra i punti medi) e il PNG per il Mac, trasparente, con l'inchiostro fisso.
enum TrattoTavoloiPad {
    /// Il percorso di un tratto (punti 0…1) in un'area della misura data; un tocco solo diventa un punto.
    static func percorso(_ punti: [CGPoint], in misura: CGSize) -> Path {
        var p = Path()
        let q = punti.map { CGPoint(x: $0.x * misura.width, y: $0.y * misura.height) }
        guard let primo = q.first else { return p }
        p.move(to: primo)
        guard q.count > 1 else {
            p.addLine(to: primo)
            return p
        }
        for i in 1..<q.count {
            let medio = CGPoint(x: (q[i - 1].x + q[i].x) / 2, y: (q[i - 1].y + q[i].y) / 2)
            p.addQuadCurve(to: medio, control: q[i - 1])
        }
        if let ultimo = q.last { p.addLine(to: ultimo) }
        return p
    }

    /// Il PNG del tratto nelle proporzioni dell'area (e del riquadro del PDF), a `scalaTratto` pixel per punto.
    static func png(_ tratti: [[CGPoint]]) -> Data? {
        let misura = CGSize(width: T.larghezzaArea, height: T.larghezzaArea / T.rapportoArea)
        let w = Int((misura.width * T.scalaTratto).rounded())
        let h = Int((misura.height * T.scalaTratto).rounded())
        guard w > 0, h > 0, let spazio = CGColorSpace(name: CGColorSpace.sRGB),
              let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: spazio,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // I punti hanno l'origine in alto, come sullo schermo
        c.translateBy(x: 0, y: CGFloat(h))
        c.scaleBy(x: T.scalaTratto, y: -T.scalaTratto)
        c.setStrokeColor(T.inchiostroCG)
        c.setLineWidth(T.spessoreTratto)
        c.setLineCap(.round)
        c.setLineJoin(.round)
        for t in tratti {
            c.addPath(percorso(t, in: misura).cgPath)
            c.strokePath()
        }
        guard let immagine = c.makeImage() else { return nil }
        return ProtocolloTavolo.png(immagine)
    }

    /// Un tratto di prova (istantanee): le stesse curve di `TrattoProvaTavolo` del Mac, in frazioni dell'area.
    static let prova: [[CGPoint]] = {
        let segmenti: [(CGPoint, CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: 40, y: 150), CGPoint(x: 80, y: 20), CGPoint(x: 150, y: 200), CGPoint(x: 200, y: 70)),
            (CGPoint(x: 200, y: 70), CGPoint(x: 250, y: -20), CGPoint(x: 320, y: 210), CGPoint(x: 380, y: 130)),
            (CGPoint(x: 380, y: 130), CGPoint(x: 430, y: 60), CGPoint(x: 500, y: 170), CGPoint(x: 560, y: 90)),
        ]
        var punti: [CGPoint] = []
        for (a, b, c, d) in segmenti {
            for k in 0...24 {
                let t = CGFloat(k) / 24
                let u = 1 - t
                // I pesi della curva di Bézier cubica (espressioni spezzate per il controllo dei tipi)
                let p0: CGFloat = u * u * u
                let p1: CGFloat = 3 * u * u * t
                let p2: CGFloat = 3 * u * t * t
                let p3: CGFloat = t * t * t
                let x: CGFloat = p0 * a.x + p1 * b.x + p2 * c.x + p3 * d.x
                let y: CGFloat = p0 * a.y + p1 * b.y + p2 * c.y + p3 * d.y
                punti.append(CGPoint(x: x / 600, y: min(max(y / 240, 0), 1)))
            }
        }
        return [punti]
    }()
}

// MARK: - Il doppio senso («Luce» giro 16, decisioni 48 e 113)

/// Il gioco del rischio sull'iPad: lo scenario con il grafico e le tre risposte (i secondi si misurano da quando le
/// risposte compaiono), poi il risultato con il profilo emerso. Niente confronto con il dichiarato: resta sul Mac.
struct RischioTavoloiPad: View {
    let mostra: MostraTavolo
    let dati: RischioTavolo
    let risponde: (_ scenario: String, _ scelta: Int, _ secondi: Double) -> Void

    @State private var scelta: Int?
    @State private var comparsa = Date()

    private typealias R = Tema.Apple.Tavolo.iPad.Rischio

    var body: some View {
        FinestraTavoloiPad {
            if let sc = dati.scenario {
                TestataTavoloiPad(sopratitolo: "\(mostra.titolo) · \(dati.indice + 1) di \(dati.totale)", titolo: sc.domanda,
                                  sottotitolo: dati.testiDiProva ? "Testi di prova" : nil)
                GraficoScenarioRischio(scenario: sc)
                    .frame(height: R.altezzaGrafico)
                    .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
                VStack(spacing: R.spazioOpzioni) {
                    ForEach(Array(sc.risposte.enumerated()), id: \.offset) { i, testo in
                        OpzioneLettera(lettera: ["A", "B", "C"][min(i, 2)], testo: testo, esito: esito(i), larghezza: R.larghezzaOpzioni) {
                            guard scelta == nil else { return }
                            scelta = i
                            risponde(sc.id, i, max(0, Date().timeIntervalSince(comparsa)))
                        }
                        .disabled(scelta != nil)
                    }
                }
                .entrataCascata(2, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            } else {
                TestataTavoloiPad(sopratitolo: mostra.titolo, titolo: "Il profilo emerso",
                                  sottotitolo: dati.testiDiProva ? "Testi di prova" : nil)
                HStack(spacing: Tema.Apple.Tavolo.iPad.spazioBlocchi) {
                    Anello(frazione: Double(dati.punteggio ?? 0) / Double(max(1, dati.massimo ?? 1)), colore: R.coloreAnello,
                           misura: R.anello) {
                        Text("\(dati.punteggio ?? 0)/\(dati.massimo ?? 0)")
                            .carattereApple(Tema.Apple.Tavolo.iPad.valoreRiga)
                    }
                    Text(dati.emerso.flatMap(ProfiloInvestitore.Propensione.init(rawValue:))?.nome ?? "—")
                        .carattereApple(R.profilo)
                        .foregroundColor(Tema.Apple.Tavolo.iPad.coloreTitolo)
                }
                .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            }
            Text(dati.avvertenza)
                .carattereApple(Tema.Apple.Tavolo.iPad.nota)
                .foregroundColor(Tema.Apple.Tavolo.iPad.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { comparsa = Date() }
        .onChange(of: dati.indice) { _, _ in
            scelta = nil
            comparsa = Date()
        }
    }

    private func esito(_ i: Int) -> OpzioneLettera.Esito {
        guard let scelta else { return .aperta }
        return scelta == i ? .scelta : .attenuata
    }
}

/// Lancia l'anno sull'iPad: le due vite affiancate, l'ultima carta e «Lancia l'anno» (un tocco = un anno, spento finché
/// il Mac non risponde e a partita finita).
struct LanciaAnnoTavoloiPad: View {
    let mostra: MostraTavolo
    let dati: LanciaAnnoTavolo
    let lancia: () -> Void

    @State private var inAttesa = false

    private typealias L = Tema.Apple.Tavolo.iPad.Lancia

    var body: some View {
        FinestraTavoloiPad {
            TestataTavoloiPad(sopratitolo: "\(mostra.titolo) · \(dati.anniLanciati) di \(dati.anniMassimi)", titolo: dati.nome,
                              sottotitolo: "Due vite affiancate, con e senza piano · \(dati.annoCorrente)")
            HStack(spacing: L.spazioVite) {
                vita("Con il piano", dati.valoreCon, colore: L.con)
                vita("Senza piano", dati.valoreSenza, colore: L.senza)
            }
            .entrataCascata(1, base: Tema.Apple.Moto.Cascata.baseDentroApp)
            if let carta = dati.ultimaCarta {
                VStack(alignment: .leading, spacing: Tema.Apple.Tavolo.iPad.spazioRighe) {
                    Text("\(String(carta.anno)) · \(carta.titolo)")
                        .carattereApple(L.titoloCarta)
                        .foregroundColor(L.toni[carta.tono] ?? Tema.Apple.Tavolo.iPad.coloreTitolo)
                    Text(carta.fraseCon).carattereApple(L.fraseCarta).foregroundColor(L.con)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(carta.fraseSenza).carattereApple(L.fraseCarta).foregroundColor(L.senza)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(L.paddingVita)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: L.raggioVita, style: .continuous).fill(L.fondoVita))
                .id("carta-\(carta.anno)")
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Button {
                inAttesa = true
                lancia()
            } label: {
                Text(dati.finita ? "La partita è finita" : "Lancia l’anno").frame(maxWidth: .infinity)
            }
            .buttonStyle(.applePrimario)
            .disabled(dati.finita || inAttesa)
            Text(dati.avvertenza)
                .carattereApple(Tema.Apple.Tavolo.iPad.nota)
                .foregroundColor(Tema.Apple.Tavolo.iPad.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onChange(of: dati.anniLanciati) { _, _ in inAttesa = false }
    }

    private func vita(_ titolo: String, _ valore: Double, colore: Color) -> some View {
        VStack(alignment: .leading, spacing: Tema.Apple.Tavolo.iPad.spazioTestata) {
            Text(titolo).carattereApple(L.etichettaVita).foregroundColor(colore)
            NumeroCheConta(valore, da: nil)
                .carattereApple(L.cifraVita)
                .foregroundColor(Tema.Apple.Tavolo.iPad.coloreCifra)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(L.paddingVita)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: L.raggioVita, style: .continuous).fill(L.fondoVita))
    }
}

/// Disegna il tuo futuro sull'iPad: la tela con gli assi già scritti; il cliente disegna con il dito, i punti
/// normalizzati (0…1, y = 0 in basso) vanno al Mac al rilascio; il risultato torna come immagine disegnata dal Mac.
struct DisegnoTavoloiPad: View {
    let mostra: MostraTavolo
    let dati: DisegnoTavolo
    var trattoIniziale: [CGPoint] = []
    let manda: ([PuntoTavolo]) -> Void

    @State private var tratto: [CGPoint] = []
    /// Un tratto in corso: il primo tocco di un tratto nuovo cancella il precedente (il Mac può averlo scartato).
    @State private var inCorso = false

    private typealias D = Tema.Apple.Tavolo.iPad.Disegno

    var body: some View {
        FinestraTavoloiPad {
            TestataTavoloiPad(sopratitolo: mostra.titolo, titolo: dati.risultato == nil ? "Disegna come vorresti il tuo patrimonio" : mostra.cliente,
                              sottotitolo: "Da \(dati.etaOggi) a \(dati.etaFine) anni · pensione a \(dati.etaPensione)")
            if let r = dati.risultato, let immagine = ProtocolloTavolo.immagine(r.png) {
                Image(decorative: immagine, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: D.altezzaRisultato)
            } else {
                tela
            }
            if let frase = dati.frase {
                Text(frase)
                    .carattereApple(Tema.Apple.Tavolo.iPad.nota)
                    .foregroundColor(Tema.Apple.Tavolo.iPad.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear { if tratto.isEmpty { tratto = trattoIniziale } }
    }

    private var tela: some View {
        GeometryReader { g in
            let area = CGRect(x: D.margineAsse, y: 0, width: max(1, g.size.width - D.margineAsse), height: g.size.height)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Tema.Apple.Raggio.voce, style: .continuous).fill(D.fondo)
                ForEach(Array(dati.etichetteAsse.enumerated()), id: \.offset) { i, e in
                    let f = dati.etichetteAsse.count > 1 ? CGFloat(i) / CGFloat(dati.etichetteAsse.count - 1) : 0
                    Path { p in
                        p.move(to: CGPoint(x: area.minX, y: area.maxY - f * area.height))
                        p.addLine(to: CGPoint(x: area.maxX, y: area.maxY - f * area.height))
                    }
                    .stroke(D.griglia, lineWidth: D.spessoreGriglia)
                    Text(e)
                        .carattereApple(D.asse)
                        .foregroundColor(D.coloreAsse)
                        .position(x: D.margineAsse / 2, y: min(area.maxY - D.margineEtichetta, max(D.margineEtichetta, area.maxY - f * area.height)))
                }
                let anni = Double(max(1, dati.etaFine - dati.etaOggi))
                let xp = area.minX + CGFloat(Double(dati.etaPensione - dati.etaOggi) / anni) * area.width
                Path { p in
                    p.move(to: CGPoint(x: xp, y: 0))
                    p.addLine(to: CGPoint(x: xp, y: area.maxY))
                }
                .stroke(D.pensione, style: StrokeStyle(lineWidth: D.spessorePensione, dash: D.tratteggioPensione))
                TrattoTavoloiPad.percorso(tratto, in: area.size)
                    .offsetBy(dx: area.minX, dy: 0)
                    .stroke(D.inchiostro, style: StrokeStyle(lineWidth: D.spessore, lineCap: .round, lineJoin: .round))
                RoundedRectangle(cornerRadius: Tema.Apple.Raggio.voce, style: .continuous).strokeBorder(D.bordo, lineWidth: D.spessoreGriglia)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { v in
                        let x = min(max((v.location.x - area.minX) / area.width, 0), 1)
                        let y = min(max(v.location.y / area.height, 0), 1)
                        if !inCorso {
                            inCorso = true
                            tratto = []
                        }
                        // Si disegna da sinistra a destra: un punto più indietro dell'ultimo si salta
                        if let ultimo = tratto.last, x < ultimo.x { return }
                        tratto.append(CGPoint(x: x, y: y))
                    }
                    .onEnded { _ in
                        inCorso = false
                        guard tratto.count >= MotoreDisegno.puntiMinimi else {
                            tratto = []
                            return
                        }
                        let punti = tratto.suffix(ProtocolloTavolo.massimiPuntiTratto).map { PuntoTavolo(x: Double($0.x), y: Double(1 - $0.y)) }
                        manda(Array(punti))
                    }
            )
        }
        .aspectRatio(D.rapporto, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("La tela del disegno"))
        .accessibilityValue(Text(tratto.isEmpty ? "Vuota" : "Tratto presente"))
    }
}

/// La capsula del tempo sull'iPad (D-C4): il cliente scrive (anche dettando con la tastiera), conferma l'invio e il
/// testo va al Mac, dove entra nel campo della capsula come bozza e si sigilla solo con la conferma del consulente.
/// Il testo vive solo in questa vista e si svuota all'uscita.
struct CapsulaTavoloiPad: View {
    let mostra: MostraTavolo
    let dati: CapsulaTavolo
    var testoIniziale = ""
    let manda: (String) -> Void

    @State private var testo = ""
    @State private var conferma = false

    private typealias K = Tema.Apple.Tavolo.iPad.Capsula

    var body: some View {
        FinestraTavoloiPad {
            TestataTavoloiPad(sopratitolo: mostra.titolo, titolo: dati.nome, sottotitolo: dati.siApre)
            TextEditor(text: $testo)
                .carattereApple(K.testo)
                .foregroundColor(K.inchiostro)
                .scrollContentBackground(.hidden)
                .padding(Tema.Apple.Tavolo.iPad.spazioRighe)
                .frame(height: K.altezzaCampo)
                .background(RoundedRectangle(cornerRadius: K.raggioCampo, style: .continuous).fill(K.fondoCampo))
                .overlay(RoundedRectangle(cornerRadius: K.raggioCampo, style: .continuous).strokeBorder(K.bordoCampo, lineWidth: 1))
                .onChange(of: testo) { _, t in
                    if t.count > ProtocolloTavolo.massimoTestoCapsula { testo = String(t.prefix(ProtocolloTavolo.massimoTestoCapsula)) }
                }
            Text(dati.aiuto)
                .carattereApple(Tema.Apple.Tavolo.iPad.nota)
                .foregroundColor(Tema.Apple.Tavolo.iPad.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
            Button { conferma = true } label: { Text(TestiRealta.mandaAlMac).frame(maxWidth: .infinity) }
                .buttonStyle(.applePrimario)
                .disabled(testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .confirmationDialog(TestiRealta.confermaInvio, isPresented: $conferma, titleVisibility: .visible) {
            Button(TestiRealta.manda) {
                let t = testo
                testo = ""
                manda(t)
            }
            Button("Annulla", role: .cancel) {}
        }
        .onAppear { if testo.isEmpty { testo = testoIniziale } }
        .onDisappear { testo = "" }
    }
}
#endif
