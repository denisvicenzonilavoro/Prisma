import SwiftUI

// Analisi 360 › la griglia delle quattro aree nel tema Apple (Design/template-apple-specifica.md §4.3.1,
// riferimenti analisi-agenda/A01-A05):
//
//   QUATTRO PROSPETTIVE. UNA PERSONA.                         [◉ Giulia | ◉ Marco | ◉ Laura | …]
//   Il percorso di Giulia.
//   ┌─ ◎ 72%  PREVIDENZA ──────────────┐┌─ ◎ 64%  PROTEZIONE ─────────────┐
//   │   72% del divario coperto         ││   64% della famiglia protetta   │
//   └───────────────────────────────────┘└─────────────────────────────────┘
//   ┌─ ◎ 92%  INVESTIMENTI ────────────┐┌─ ◎ 3,5 mesi  RISPARMIO E LIQ. ──┐
//   └───────────────────────────────────┘└─────────────────────────────────┘
//   STRUMENTI [Simulatore] [Scenari] [Confronto] [TFR]
//   Le quattro aree leggono ipotesi dedicate…                         [Prepara l'incontro]
//
// - Le cifre vengono dai motori dei pannelli di sempre (MotoreAree360, in cache per cliente e dati).
// - Le card si inclinano verso il puntatore (5 gradi, solo quella sotto il puntatore) e il dettaglio nasce dalla
//   card toccata (PresentatoreDettaglio, uno per finestra): Previdenza e Protezione aprono i simulatori dal vivo
//   (SimulatoriAnalisiApple), Investimenti e Risparmio e liquidità i dettagli di Analisi360AppleDettagli.swift.
//   I pannelli completi di oggi restano nella colonna e si aprono anche dal dettaglio («Apri l'analisi completa»).
// - Cambio cliente dalle pillole: la griglia esce in 0,14 s lineare (scala 0,99), poi rientra a cascata con base 0
//   e gli anelli a 0,15 s. «Riduci movimento»: dissolvenza di 0,15 s; istantanee: di colpo.
// - Sotto la testata il segmentato «Le quattro aree · Rispetto alle famiglie come la sua» (Orizzonte giro 6,
//   `StatoShell.vistaAnalisi360`): la seconda vista è FamiglieComeLaSuaApple (FamiglieComeLaSua.swift).
// Valori in DesignSystem/Apple/Tema.Apple+Aree360.swift.

// MARK: - Gli id dei dettagli

/// I dettagli che nascono dalle card delle aree: gli id, le misure e da quale area vengono.
enum DettagliAree360 {
    static let idInvestimenti = "area360-investimenti"
    static let idRisparmio = "area360-risparmio"

    static func id(_ a: AreaAnalisi) -> String {
        switch a {
        case .previdenza: return SimulatoriAnalisiApple.idPrevidenza
        case .protezione: return SimulatoriAnalisiApple.idProtezione
        case .investimenti: return idInvestimenti
        case .risparmio: return idRisparmio
        }
    }

    static func misura(_ a: AreaAnalisi) -> CGSize {
        let d = Tema.Apple.Aree360.Dettaglio.self
        switch a {
        case .previdenza, .protezione: return SimulatoriAnalisiApple.misura
        case .investimenti: return d.misuraInvestimenti
        case .risparmio: return d.misuraLiquidita
        }
    }

    static func area(id: String) -> AreaAnalisi? {
        if let a = SimulatoriAnalisiApple.area(id: id) { return a }
        switch id {
        case idInvestimenti: return .investimenti
        case idRisparmio: return .risparmio
        default: return nil
        }
    }
}

// MARK: - Cache delle aree

/// Le cifre della griglia e dei dettagli, calcolate una volta per cliente finché non cambiano i dati dei calcoli,
/// il giorno, l'ora o la modalità cliente: la finestra si ridisegna spesso, i motori no. I valori stanno in
/// DerivatiDati (`StatoShell.aree360`), non qui: restano anche chiudendo e riaprendo Analisi 360.
final class CacheAree360: ObservableObject {
    func aree(_ stato: StatoShell, cliente id: String) -> AreeAnalisi360 {
        stato.aree360(id)
    }
}

// MARK: - Il presentatore dei dettagli

/// Mette sopra tutta l'app Analisi 360 il dettaglio che nasce da una card delle aree (un solo presentatore per
/// finestra: il dettaglio si centra nell'app e la sfoca dietro con una sola sfocatura). Si chiude da solo cambiando
/// cliente, area o strumento. Le istantanee possono chiederlo già aperto (`RichiestaIstantaneaAnalisi360` per
/// Investimenti e Liquidità, `RichiestaIstantaneaSimulatore` per i simulatori).
struct PresentatoreAree360<Contenuto: View>: View {
    let stato: StatoShell
    @StateObject private var dettaglio: StatoDettaglio
    @StateObject private var cache = CacheAree360()
    let contenuto: Contenuto

    init(stato: StatoShell, @ViewBuilder contenuto: () -> Contenuto) {
        self.stato = stato
        self.contenuto = contenuto()
        // L'oggetto nasce una volta sola (`StateObject` valuta l'espressione solo alla prima comparsa)
        _dettaglio = StateObject(wrappedValue: Self.dettaglioIniziale(stato))
    }

    private static func dettaglioIniziale(_ stato: StatoShell) -> StatoDettaglio {
        if let a = RichiestaIstantaneaAnalisi360.per(stato)?.area {
            return StatoDettaglio(aperto: DettagliAree360.id(a), misura: DettagliAree360.misura(a))
        }
        return SimulatoriAnalisiApple.dettaglioIniziale(stato)
    }

    var body: some View {
        contenuto
            .presentatoreDettaglio(dettaglio) { id in
                DettaglioArea360Apple(id: id)
            }
            .environmentObject(cache)
            .onChange(of: stato.clienteAttivoId) { _ in dettaglio.chiudi(subito: true) }
            .onChange(of: stato.areaAnalisi) { _ in dettaglio.chiudi(subito: true) }
            .onChange(of: stato.strumentoAnalisi) { _ in dettaglio.chiudi(subito: true) }
            .onDisappear { dettaglio.chiudi(subito: true) }
    }
}

/// Il contenuto del dettaglio aperto, secondo l'id della card da cui è nato.
struct DettaglioArea360Apple: View {
    @Environment(StatoShell.self) var stato
    let id: String

    var body: some View {
        let _ = ContaCorpi.segna()
        if SimulatoriAnalisiApple.area(id: id) != nil {
            DettaglioSimulatoreAnalisiApple(id: id)
        } else if let c = stato.cliente(stato.clienteAttivoId), let area = DettagliAree360.area(id: id) {
            switch area {
            case .investimenti:
                DettaglioInvestimentiApple(cliente: c).id(c.id)
            case .risparmio:
                DettaglioLiquiditaApple(cliente: c).id(c.id)
            case .previdenza, .protezione:
                EmptyView()
            }
        }
    }
}

/// Ciò che una scena delle istantanee chiede ad Analisi 360 (Prisma --istantanee): il dettaglio Investimenti o
/// Risparmio e liquidità già aperto. Vale solo per lo stato della scena (riferimento debole: le scene dopo non lo
/// vedono).
final class RichiestaIstantaneaAnalisi360 {
    nonisolated(unsafe) private static var attuale: RichiestaIstantaneaAnalisi360?

    private weak var stato: StatoShell?
    let area: AreaAnalisi

    private init(stato: StatoShell, area: AreaAnalisi) {
        self.stato = stato
        self.area = area
    }

    static func chiedi(_ s: StatoShell, area: AreaAnalisi) {
        attuale = RichiestaIstantaneaAnalisi360(stato: s, area: area)
    }

    static func per(_ s: StatoShell) -> RichiestaIstantaneaAnalisi360? {
        guard let r = attuale, r.stato === s else { return nil }
        return r
    }
}

// MARK: - La griglia delle aree

/// La schermata delle aree di Analisi 360 (al posto della panoramica di prima): testata con le pillole dei clienti,
/// le quattro card con l'anello e il piede con gli strumenti e le ipotesi.
struct Analisi360Apple: View {
    @Environment(StatoShell.self) var stato
    @EnvironmentObject var cache: CacheAree360
    @Environment(\.statoDettaglioApple) private var dettaglio
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea

    /// Il cliente della griglia: resta quello di prima finché la griglia non è uscita.
    @State private var clienteMostrato: String?
    @State private var esce = false
    /// Dopo il primo cambio di cliente la cascata parte da 0 e gli anelli a 0,15 s.
    @State private var cambiato = false
    /// La vista mostrata (le quattro aree o le famiglie come la sua): resta quella di prima finché non è uscita.
    @State private var vistaMostrata: VistaAnalisi360?
    @State private var esceVista = false

    private var base: Double {
        let t = Tema.Apple.Aree360.Tempi.self
        return cambiato ? t.baseCambio : t.baseApertura
    }

    private var ritardoAnelli: Double {
        let t = Tema.Apple.Aree360.Tempi.self
        return cambiato ? t.anelliCambio : t.anelliApertura
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let d = Tema.Apple.Aree360.Disposizione.self
        let id = clienteMostrato ?? stato.clienteAttivoId
        return GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    testata(id)
                        .entrataCascata(Tema.Apple.Aree360.Tempi.indiceTestata, base: base)
                    // Le quattro aree o «Rispetto alle famiglie come la sua» (giro 6, FamiglieComeLaSua.swift)
                    RigaVisteAnalisi360(vista: Bindable(stato).vistaAnalisi360, diProva: stato.tabelleFamiglie?.diProva ?? false,
                                        modoCliente: stato.inModoCliente,
                                        apriImpostazioni: { stato.apriImpostazioniFamiglie() })
                        .padding(.top, d.testataSotto)
                        .entrataCascata(Tema.Apple.Aree360.Tempi.indiceTestata, base: base)
                    contenutoVista(id, misura: geo.size)
                        .padding(.top, Tema.Apple.Famiglie.sottoSegmentato)
                }
                .padding(d.margine)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .background(d.fondo)
        // Nelle istantanee (e nella prova di fluidità) il cambio è di colpo (`cambiaCliente`): nil vuol dire «quello
        // dello stato», e scriverlo alla comparsa rifarebbe subito tutta la griglia
        .onAppear {
            if !istantanea {
                clienteMostrato = stato.clienteAttivoId
                vistaMostrata = stato.vistaAnalisi360
            }
        }
        .onChange(of: stato.clienteAttivoId) { nuovo in cambiaCliente(nuovo) }
        .onChange(of: stato.vistaAnalisi360) { nuova in cambiaVista(nuova) }
    }

    // MARK: Le due viste

    /// Le quattro aree con il piede, o il confronto con le famiglie come la sua. Cambiando vista il contenuto esce
    /// (`rimonta`, 0,13 s) e rientra con la sua cascata; cambiando cliente esce e rientra come la griglia.
    @ViewBuilder private func contenutoVista(_ id: String, misura: CGSize) -> some View {
        let d = Tema.Apple.Aree360.Disposizione.self
        let t = Tema.Apple.Famiglie.Tempi.self
        let v = vistaMostrata ?? stato.vistaAnalisi360
        Group {
            switch v {
            case .aree:
                VStack(alignment: .leading, spacing: 0) {
                    griglia(id, misura: misura)
                    piede(id)
                        .padding(.top, d.piedeSopra)
                        .entrataCascata(Tema.Apple.Aree360.Tempi.indicePiede, base: base)
                }
            case .famiglie:
                FamiglieComeLaSuaApple(stato: stato, clienteId: id, chiave: stato.chiaveVista, base: base)
                    .equatable()
                    // Un altro cliente: le card si rifanno, entrano a cascata, le cifre ricontano e gli avatar ripartono
                    .id(id)
                    .opacity(esce ? 0 : 1)
                    .scaleEffect(esce ? Tema.Apple.Moto.CambioGriglia.scala : 1)
            }
        }
        .id(v)
        .opacity(esceVista ? 0 : 1)
        .scaleEffect(esceVista ? t.scalaRimonta : 1)
    }

    /// `rimonta`: il contenuto svanisce in 0,13 s fino a scala 0,99, poi entra la vista nuova con la sua cascata.
    /// «Riduci movimento»: dissolvenza di 0,15 s; istantanee: di colpo.
    private func cambiaVista(_ nuova: VistaAnalisi360) {
        guard nuova != vistaMostrata else {
            esceVista = false
            return
        }
        if istantanea || calmo {
            let mostra: () -> Void = {
                vistaMostrata = nuova
                esceVista = false
            }
            if istantanea { mostra() } else { withAnimation(Tema.Moto.dissolvenzaCalma) { mostra() } }
            return
        }
        let t = Tema.Apple.Famiglie.Tempi.self
        withAnimation(t.uscitaRimonta) { esceVista = true }
        Movimenti.dopo(Tema.Apple.Moto.tempo(t.durataRimonta)) {
            // Un altro clic nel frattempo: entra quella scelta per ultima
            guard stato.vistaAnalisi360 == nuova else { return }
            vistaMostrata = nuova
            esceVista = false
        }
    }

    // MARK: Testata

    private func testata(_ id: String) -> some View {
        let t = Tema.Apple.Aree360.Testata.self
        let nome = stato.cliente(id).map(StatoShell.nomeBreve) ?? "cliente"
        return HStack(alignment: .top, spacing: t.spazioPillole) {
            VStack(alignment: .leading, spacing: t.spazioTitolo) {
                Text("Quattro prospettive. Una persona.")
                    .carattereApple(t.occhiello)
                    .foregroundColor(t.coloreOcchiello)
                    .lineLimit(1)
                Text("Il percorso di \(nome).")
                    .carattereApple(t.titolo)
                    .foregroundColor(t.coloreTitolo)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let k = stato.completezzaCliente(id) {
                    rigaCompletezza(k, cliente: id)
                        .padding(.top, t.completezzaSopra - t.spazioTitolo)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
            pillole
        }
    }

    /// I dati per l'analisi del cliente: quanto sono completi e quante ipotesi sono stimate, con il passaggio
    /// alla scheda del cliente per completarli (non in modalità cliente).
    private func rigaCompletezza(_ k: CompletezzaCliente, cliente id: String) -> some View {
        let t = Tema.Apple.Aree360.Testata.self
        return HStack(alignment: .firstTextBaseline, spacing: t.spazioCompletezza) {
            Text(TestiCompletezza.rigaAnalisi(k))
                .carattereApple(t.completezza)
                .foregroundColor(k.livello == .completo ? t.coloreCompleti : t.coloreIncompleti)
                .lineLimit(1)
                .help(TestiCompletezza.metodo)
            if !k.daCompletare.isEmpty && !stato.inModoCliente {
                Button { stato.apriCliente(id) } label: {
                    Text(TestiCompletezza.completaNellaScheda + " ›")
                }
                .buttonStyle(.appleSobrio)
            }
        }
    }

    /// Le pillole dei clienti (avatar 24 e nome): cinque, poi quattro e tre se lo spazio manca; il cliente attivo
    /// c'è sempre. Gli altri si scelgono dalla colonna, come prima.
    /// Le voci si preparano qui una volta sola (l'ordine dei clienti si calcola una volta, non per variante) e le
    /// pillole sono una vista `Equatable`: le tre varianti di ViewThatFits si rifanno solo se cambiano le voci o il
    /// cliente scelto, non a ogni giro del body della griglia.
    @ViewBuilder private var pillole: some View {
        let t = Tema.Apple.Aree360.Testata.self
        if stato.clienti.count > 1 {
            let attivo = stato.clienteAttivoId
            let varianti = PilloleClienti.varianti(stato.clienti, attivo: stato.clienteAttivo,
                                                   numeri: [t.pilloleMassime, t.pilloleMassime - 1, t.pilloleMinime])
            PilloleClienti(lunga: varianti[0], media: varianti[1], corta: varianti[2],
                           scelto: attivo, scegli: { stato.clienteAttivoId = $0 })
                .equatable()
        }
    }

    // MARK: Griglia 2×2

    private func griglia(_ id: String, misura: CGSize) -> some View {
        let d = Tema.Apple.Aree360.Disposizione.self
        let aree = cache.aree(stato, cliente: id)
        let ingressi = ingressiCard(cliente: id)
        let altezza = Self.altezzaArea(misura.height)
        let larghezza = max(0, (misura.width - d.margine.leading - d.margine.trailing - d.spazio) / 2)
        let lato = Self.latoAnello(larghezza: larghezza, altezza: altezza)
        return VStack(spacing: d.spazio) {
            // Righe larghe quanto lo spazio: una card non può allargare la griglia oltre la finestra
            HStack(spacing: d.spazio) {
                card(.previdenza, aree, ingressi, lato: lato, altezza: altezza)
                card(.protezione, aree, ingressi, lato: lato, altezza: altezza)
            }
            .frame(width: max(0, misura.width - d.margine.leading - d.margine.trailing))
            HStack(spacing: d.spazio) {
                card(.investimenti, aree, ingressi, lato: lato, altezza: altezza)
                card(.risparmio, aree, ingressi, lato: lato, altezza: altezza)
            }
            .frame(width: max(0, misura.width - d.margine.leading - d.margine.trailing))
        }
        // Un altro cliente: le card si rifanno, entrano a cascata e le cifre ricontano da 0
        .id(id)
        .opacity(esce ? 0 : 1)
        .scaleEffect(esce ? Tema.Apple.Moto.CambioGriglia.scala : 1)
    }

    /// Le due righe dividono lo spazio che resta sotto la testata e sopra il piede, fra 236 e 319.
    private static func altezzaArea(_ totale: CGFloat) -> CGFloat {
        let d = Tema.Apple.Aree360.Disposizione.self
        let libero = (totale - d.margine.top - d.margine.bottom - d.riservatoTestataPiede
                      - Tema.Apple.Famiglie.riservatoRigaVista - d.spazio) / 2
        return min(d.altezzaMassimaArea, max(d.altezzaMinimaArea, libero))
    }

    /// L'anello 170 se c'è posto, più piccolo nelle card basse o strette (mai sotto 110).
    private static func latoAnello(larghezza: CGFloat, altezza: CGFloat) -> CGFloat {
        let a = Tema.Apple.Aree360.Area.self
        let alto = altezza - a.padding.top - a.padding.bottom
        let largo = (larghezza - a.padding.leading - a.padding.trailing) * a.quotaAnello
        return max(a.anelloMinimo, min(a.anello.misura, alto, largo))
    }

    private func card(_ area: AreaAnalisi, _ aree: AreeAnalisi360, _ ingressi: IngressiCard360, lato: CGFloat,
                      altezza: CGFloat) -> some View {
        let t = Tema.Apple.Aree360.Tempi.self
        let indice = t.indicePrimaArea + (AreaAnalisi.allCases.firstIndex(of: area) ?? 0)
        let sintesi = aree.sintesi(area) ?? SintesiArea360(area: area, frazione: nil, valore: nil, unita: .percentuale,
                                                          titolo: TestiAree360.nomeArea(area), testo: "")
        let ipotesi = statoIpotesi(area, ingressi)
        return CardArea360Apple(area: area, sintesi: sintesi, statoIpotesi: ipotesi.testo, coloreStato: ipotesi.colore,
                                priorita: ingressi.prioritarie.contains(area), canali: canali(area, ingressi),
                                lato: lato, ritardoAnello: ritardoAnelli, indice: indice - t.indicePrimaArea,
                                apri: { apri(area) })
            // Ingressi semplici: a ogni giro del body della griglia (StatoShell cambiato, cliente scritto alla
            // comparsa) la card non si rifà se le sue cifre e i suoi testi sono gli stessi
            .equatable()
            .frame(maxWidth: .infinity)
            .frame(height: altezza)
            .entrataCascata(indice, base: base)
    }

    /// Ciò che le quattro card leggono dallo stato, letto una volta per la griglia e non una volta per card:
    /// le aree confermate, la completezza, le tre priorità e le posizioni in essere del cliente.
    private struct IngressiCard360 {
        let confermate: [AreaAnalisi]
        let completezza: CompletezzaCliente?
        let prioritarie: [AreaAnalisi]
        let inEssere: [Posizione]
    }

    private func ingressiCard(cliente id: String) -> IngressiCard360 {
        // Solo l'analisi salvata ha aree confermate: la prima stesura dalle posizioni non si rifà a ogni card
        let confermate = stato.dati.analisi[id]?.confermate ?? []
        // Le tre priorità del cliente, dalla ruota dei bisogni della sua scheda
        var prioritarie: [AreaAnalisi] = []
        if let c = stato.cliente(id) {
            prioritarie = MotoreBisogni.priorita(stato.bisogniRilevati(c.id), profilo: c.bisogni).prefix(3).map(\.areaAnalisi)
        }
        return IngressiCard360(confermate: confermate,
                               completezza: stato.completezzaCliente(id),
                               prioritarie: prioritarie,
                               inEssere: stato.posizioniCliente(id).filter { $0.stato == .inEssere })
    }

    /// Le ipotesi dell'area: quante sono stimate (dati ancora da completare), confermate o da verificare.
    private func statoIpotesi(_ area: AreaAnalisi, _ ingressi: IngressiCard360) -> (testo: String, colore: Color) {
        let a = Tema.Apple.Aree360.Area.self
        let confermata = ingressi.confermate.contains(area)
        var stimate = 0
        if !confermata, let k = ingressi.completezza {
            stimate = k.voci(per: MotoreCompletezza.analisi(perArea: area)).count
        }
        if stimate > 0 { return (TestiCompletezza.ipotesiArea(stimate), a.coloreStimate) }
        if confermata { return ("Dati confermati", a.coloreConfermate) }
        return ("Ipotesi da verificare", a.coloreDaVerificare)
    }

    /// I canali delle posizioni in essere dell'area (Risparmio e liquidità conta anche i conti).
    private func canali(_ area: AreaAnalisi, _ ingressi: IngressiCard360) -> [Canale] {
        let aree: Set<AreaPosizione> = area == .risparmio ? [.risparmio, .liquidita] : [area.areaPosizioni]
        let presenti = Set(ingressi.inEssere.filter { aree.contains($0.area) }.map(\.canale))
        return Canale.allCases.filter { presenti.contains($0) }
    }

    private func apri(_ area: AreaAnalisi) {
        dettaglio?.apri(DettagliAree360.id(area), misura: DettagliAree360.misura(area))
    }

    // MARK: Piede

    private func piede(_ id: String) -> some View {
        let p = Tema.Apple.Aree360.Piede.self
        let ipotesi = stato.analisiSalvata(id)
            ? "Ipotesi corrette per questo cliente; le coperture si leggono sempre dalle posizioni."
            : "Ipotesi ricavate dalle posizioni in essere e dall'anagrafica: rivedile con il cliente."
        return VStack(alignment: .leading, spacing: p.spazioRighe) {
            HStack(spacing: p.spazioPulsanti) {
                Text("Strumenti")
                    .carattereApple(p.etichetta)
                    .foregroundColor(p.coloreEtichetta)
                    .padding(.trailing, max(0, p.spazioEtichetta - p.spazioPulsanti))
                ForEach(StrumentoAnalisi.allCases) { s in
                    Button { stato.scegliStrumentoAnalisi(s) } label: {
                        Label(s.titolo, systemImage: s.simbolo)
                    }
                    .buttonStyle(.apple)
                }
                Spacer(minLength: 0)
            }
            HStack(alignment: .center, spacing: p.spazioNota) {
                Text("Le quattro aree leggono ipotesi dedicate allo stesso cliente. Capitale e versamenti possono sovrapporsi: verifica le allocazioni prima di sommare i piani. " + ipotesi)
                    .carattereApple(p.nota)
                    .foregroundColor(p.coloreNota)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                // Dopo l'analisi, l'incontro con il cliente
                Button {
                    stato.filtroClienteAgenda = id
                    stato.apri(.agenda)
                } label: {
                    Label("Prepara l'incontro", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.applePrimario)
                .fixedSize()
            }
        }
    }

    // MARK: Cambio cliente

    private func cambiaCliente(_ nuovo: String) {
        guard nuovo != clienteMostrato else {
            esce = false
            return
        }
        if istantanea || calmo {
            let mostra: () -> Void = {
                cambiato = true
                clienteMostrato = nuovo
                esce = false
            }
            if istantanea {
                mostra()
            } else {
                withAnimation(Tema.Moto.dissolvenzaCalma) { mostra() }
            }
            return
        }
        let g = Tema.Apple.Moto.CambioGriglia.self
        withAnimation(g.uscita) { esce = true }
        Movimenti.dopo(Tema.Apple.Moto.tempo(g.durataUscita)) {
            // Un clic su un altro cliente nel frattempo: entra quello, con il suo giro
            guard stato.clienteAttivoId == nuovo else { return }
            cambiato = true
            clienteMostrato = nuovo
            esce = false
        }
    }
}

// MARK: - Card di un'area

/// Una card della griglia: l'anello nel colore dell'area con la cifra al centro, `.lbl`, titolo «{grande} {testo}»,
/// la frase con la cifra principale del pannello, le ipotesi e i canali, il collegamento al dettaglio.
private struct CardArea360Apple: View, Equatable {
    let area: AreaAnalisi
    let sintesi: SintesiArea360
    let statoIpotesi: String
    let coloreStato: Color
    let priorita: Bool
    let canali: [Canale]
    let lato: CGFloat
    let ritardoAnello: Double
    let indice: Int
    /// Apre il dettaglio dell'area: resta fuori dal confronto (fa sempre la stessa cosa per la stessa area).
    let apri: () -> Void

    static func == (a: Self, b: Self) -> Bool {
        a.area == b.area && a.sintesi == b.sintesi && a.statoIpotesi == b.statoIpotesi && a.coloreStato == b.coloreStato
            && a.priorita == b.priorita && a.canali == b.canali && a.lato == b.lato
            && a.ritardoAnello == b.ritardoAnello && a.indice == b.indice
    }

    var body: some View {
        let a = Tema.Apple.Aree360.Area.self
        let colore = Tema.Apple.Aree360.colore(area)
        let forma = RoundedRectangle(cornerRadius: a.raggio, style: .continuous)
        return HStack(alignment: .center, spacing: a.spazioAnello) {
            anello(colore)
            testi(colore)
            Spacer(minLength: 0)
        }
        .padding(a.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(forma)
        .onTapGesture(perform: apri)
        .superficieApple(a.superficie, raggio: a.raggio)
        .inclinazione(massimo: a.inclinazione, raggio: a.raggio)
        .origineDettaglio(id: DettagliAree360.id(area))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { apri() }
    }

    private var collegamento: String {
        area == .previdenza || area == .protezione ? "Prova il simulatore ›" : "Vedi il dettaglio ›"
    }

    private func anello(_ colore: Color) -> some View {
        let a = Tema.Apple.Aree360.Area.self
        let spessore = a.anello.spessore * lato / a.anello.misura
        return Anello(frazione: sintesi.frazione ?? 0, colore: colore, misura: lato, spessore: spessore,
                      ritardo: ritardoAnello) {
            centro
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: max(0, lato - 2 * spessore - a.spazioEtichetta))
        }
    }

    /// Al centro la percentuale che si conta, i mesi con la virgola o il trattino se l'area non si misura.
    @ViewBuilder private var centro: some View {
        let a = Tema.Apple.Aree360.Area.self
        if let v = sintesi.valore, sintesi.unita == .percentuale {
            NumeroCheConta(v, formato: .percentuale, indice: indice)
                .carattereApple(a.centro)
                .foregroundColor(a.coloreCentro)
        } else if let v = sintesi.valore {
            // Anche i mesi si contano fino al valore, con la virgola («3,5 mesi»)
            NumeroCheConta(v, formato: .personalizzato(TestiAree360.mesiConNome), indice: indice)
                .carattereApple(TestiAree360.mesiConNome(v).count > a.lunghezzaCentroCorto ? a.centroLungo : a.centro)
                .foregroundColor(a.coloreCentro)
        } else {
            Text("—")
                .carattereApple(a.centro)
                .foregroundColor(a.coloreTrattino)
        }
    }

    private func testi(_ colore: Color) -> some View {
        let a = Tema.Apple.Aree360.Area.self
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: a.spazioEtichetta) {
                Text(TestiAree360.nomeArea(area))
                    .carattereApple(a.etichetta)
                    .foregroundColor(colore)
                    .lineLimit(1)
                if priorita {
                    Text("★ Priorità")
                        .carattereApple(a.priorita)
                        .foregroundColor(a.colorePriorita)
                        .lineLimit(1)
                        .fixedSize()
                        .help("Priorità del cliente, dalla ruota dei bisogni nella sua scheda")
                }
            }
            Text(sintesi.titolo)
                .carattereApple(a.titolo)
                .foregroundColor(a.coloreTitolo)
                // Nelle card strette (iPad in verticale) il titolo va a capo invece di perdere la cifra
                .lineLimit(2)
                .minimumScaleFactor(a.riduzioneTitolo)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, a.titoloSopra)
            Text(sintesi.testo)
                .carattereApple(a.descrizione)
                .foregroundColor(a.coloreDescrizione)
                .lineLimit(a.righeDescrizione)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: a.larghezzaDescrizione, alignment: .leading)
                .padding(.top, a.descrizioneSopra)
            // Se canali e stato non stanno su una riga, lo stato va sotto le etichette: le due etichette fisse
            // non allargano più la card oltre la sua colonna
            ViewThatFits(in: .horizontal) {
                HStack(spacing: a.spazioStato) {
                    etichetteCanali
                    testoStato
                }
                VStack(alignment: .leading, spacing: a.spazioStato) {
                    HStack(spacing: a.spazioStato) { etichetteCanali }
                    testoStato
                }
            }
            .padding(.top, a.statoSopra)
            Text(collegamento)
                .carattereApple(a.collegamento)
                .foregroundColor(a.coloreCollegamento)
                .padding(.top, a.collegamentoSopra)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var etichetteCanali: some View {
        ForEach(canali) { c in
            EtichettaCanaleApple(canale: c, compatta: true)
        }
    }

    private var testoStato: some View {
        Text(statoIpotesi)
            .carattereApple(Tema.Apple.Aree360.Area.stato)
            .foregroundColor(coloreStato)
            // Accanto a due etichette dei canali va a capo invece di finire con «…»
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Vera e proposte dalle aree

extension StatoShell {
    /// «Chiedi a Vera di spiegarlo»: apre Vera e, dopo 0,7 s (subito con «Riduci movimento»), le manda la domanda
    /// sull'area del cliente attivo, con lo spunto che porta i dati di Prisma di quell'area.
    func chiediVeraArea360(_ area: AreaAnalisi) {
        guard appConsentita(.vera) else {
            apri(.vera)
            return
        }
        let nome = clienteAttivo.map(StatoShell.nomeBreve) ?? "il cliente"
        let testo = TestiAree360.domandaVera(area, nome: nome)
        let spunto = TestiAree360.spuntoVera(area)
        if veraPortafoglio { veraPortafoglio = false }
        apri(.vera)
        let attesa = Movimenti.calmo ? 0 : Tema.Apple.Moto.DomandaDaScrivania.ritardo
        DispatchQueue.main.asyncAfter(deadline: .now() + attesa) { [weak self] in
            _ = self?.chiediVera(testo, spunto: spunto)
        }
    }

    /// «Salva come proposta»: la prima azione che le analisi di Prisma suggeriscono per l'area (le stesse proposte di
    /// Vera, MotoreSintesi.calcolaProposte) diventa una bozza di proposta nel dossier, sul canale scelto.
    /// Restituisce se è stata salvata e il testo dell'avviso.
    func salvaPropostaArea360(_ area: AreaAnalisi, canale: Canale) -> (salvata: Bool, testo: String) {
        guard !solaLettura else { return (false, TestiAree360.solaLettura) }
        guard let c = clienteAttivo else { return (false, TestiAree360.nessunaProposta(area, nome: "il cliente")) }
        guard let fonte = fonteVera(c.id),
              let p = MotoreAree360.proposta(per: area, tra: MotoreSintesi.calcolaProposte(fonte)),
              let areaPosizione = p.area else {
            return (false, TestiAree360.nessunaProposta(area, nome: c.nome))
        }
        var nuova = Posizione(clienteId: c.id, canale: canale, stato: .proposta, area: areaPosizione, nome: p.titolo)
        nuova.esito = .bozza
        nuova.tipologia = "Da Analisi 360"
        nuova.contraente = c.nome
        nuova.rischio = p.rischio
        nuova.capitaleAssicurato = p.capitale
        if let v = p.versamentoMensile {
            nuova.premio = v
            nuova.frequenza = .mensile
        }
        if let i = p.importo, p.versamentoMensile == nil { nuova.versamentoIniziale = i }
        nuova.note = "Da Analisi 360 (\(TestiAree360.nomeArea(area))): \(p.perche) Scegli il prodotto e completa i dati."
        salvaPosizione(nuova)
        return (true, TestiAree360.propostaSalvata(nome: c.nome))
    }
}
