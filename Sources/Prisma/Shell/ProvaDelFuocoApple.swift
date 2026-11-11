import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// Posizioni › Portafoglio · Prova del fuoco (Design/template-novita-specifica.md §6, Orizzonte giro 4):
//
//   ┌ card ─────────────────────────────────────────────────────────┬──────────────┬──────────────┐
//   │ LA PROVA DEL FUOCO · TUTTO IL PORTAFOGLIO          Ricalcolo… │ 3            │ −193.387 €   │
//   │ [Mercati −25%] [Tassi +2 punti] [Inflazione al 5%] [2008] …   │ clienti …    │ di patrimonio│
//   │ Ribasso delle azioni  ───────●───────  −25%                   │              │              │
//   └───────────────────────────────────────────────────────────────┴──────────────┴──────────────┘
//   Chi chiamare, in ordine   la barra chiara è l’obiettivo oggi, quella piena dopo lo scenario
//   (EF) Elisa … ● Alleanza  ██████████░░░░ ───   dopo 74% / oggi 90%   −17.232 €  [Chiama] [Messaggio]
//
// - Le cifre vengono da MotoreProvaFuoco (fondamenta del giro 4): la base si prepara una volta per dati e giorno,
//   ogni scenario (ogni passo del cursore) si calcola fuori dal thread principale con CalcoloProvaFuoco (vince
//   l'ultimo) e si pubblica sul thread principale; «Ricalcolo…» compare solo se il calcolo tarda.
// - Movimento: mentre si trascina le barre e i numeri seguono, l'ordine resta; al rilascio (o a un passo da
//   tastiera, o cambiando chip) le righe scivolano al nuovo posto (identità stabili per cliente, `withAnimation`
//   con `Tema.Apple.Moto.Riordino`, niente Timer). «Riduci movimento»: niente scivolamento né cascata, tutto fermo
//   con la dissolvenza di 0,15 s. Istantanee: calcolo sincrono, lista già riordinata, numeri completi.
// - Prestazioni: la vista è `Equatable` sulla chiave dei dati (StatoShell pubblica spesso: qui non si ridisegna);
//   le righe sono sottoviste `Equatable`, la lista è pigra.
// - Canale riconoscibile su ogni riga (etichetta del canale delle posizioni in essere; nella riga stretta il colore).

// MARK: - Le due viste del Portafoglio

/// Il Portafoglio di Posizioni con la testata dei segmenti «Portafoglio · Prova del fuoco» e il cambio di vista
/// (`rimonta`, come le schede di Studio). In modalità cliente il Portafoglio non si apre (StatoShell.portafoglio).
struct VistePortafoglioApple<Portafoglio: View>: View {
    let stato: StatoShell
    @Bindable var prova: StatoProvaFuoco
    let portafoglio: Portafoglio

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    /// La vista a schermo: segue `prova.vista` dopo la rimonta. Parte già giusta dall'init: scriverla alla comparsa
    /// costava un secondo passaggio del portafoglio di tutti i clienti a ogni apertura.
    @State private var mostrata: VistaPosizioni
    @State private var esce = false

    init(stato: StatoShell, @ViewBuilder portafoglio: () -> Portafoglio) {
        self.stato = stato
        self.prova = stato.provaFuoco
        _mostrata = State(initialValue: stato.provaFuoco.vista)
        self.portafoglio = portafoglio()
    }

    var body: some View {
        let v = mostrata
        let m = Tema.Apple.Posizioni.Fuoco.Moto.self
        // La testata sopra e il contenuto sotto con l'altezza che resta, proposta una volta sola (TestataSopra): in un
        // VStack la ScrollView del portafoglio veniva sondata a ogni layout, e con 200 clienti costava centinaia di ms
        return TestataSopra {
            TestataVistePortafoglio(clienti: stato.clienti.count, vista: $prova.vista)
            contenuto(v)
                .id(v)
                .opacity(esce ? 0 : 1)
                .scaleEffect(esce ? m.scalaRimonta : 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Tema.Apple.Posizioni.Disposizione.fondo)
        .onChange(of: prova.vista) { nuova in cambia(nuova) }
        // Un'ancora del portafoglio (cose da sistemare, proposte da riprendere) riporta al Portafoglio
        .onChange(of: stato.ancoraPosizioni) { a in
            if AppPosizioni.ancorePortafoglio.contains(a ?? ""), prova.vista != .portafoglio { prova.vista = .portafoglio }
        }
    }

    @ViewBuilder private func contenuto(_ v: VistaPosizioni) -> some View {
        switch v {
        case .portafoglio:
            portafoglio
        case .radar:
            // Posizioni › Radar («Luce» giro 2, RadarPortafoglio.swift)
            RadarPortafoglioApple(stato: stato, chiave: stato.chiaveVista, solaLettura: stato.solaLettura,
                                  dettaglioAperto: stato.radarDettaglioIstantanea)
                .equatable()
        case .provaDelFuoco:
            ProvaDelFuocoApple(stato: stato, prova: prova, chiave: stato.chiaveVista, solaLettura: stato.solaLettura)
                .equatable()
        case .smontaggio:
            // Posizioni › Smontaggio («Luce» giro 2, SmontaggioApple.swift)
            SmontaggioApple(stato: stato)
        }
    }

    /// `rimonta`: il contenuto svanisce in 0,13 s fino a scala 0,99, poi entra la vista nuova con la sua cascata.
    private func cambia(_ nuova: VistaPosizioni) {
        guard nuova != mostrata else {
            esce = false
            return
        }
        if istantanea || calmo {
            let mostra: () -> Void = {
                mostrata = nuova
                esce = false
            }
            if istantanea { mostra() } else { withAnimation(Tema.Moto.dissolvenzaCalma) { mostra() } }
            return
        }
        let m = Tema.Apple.Posizioni.Fuoco.Moto.self
        withAnimation(m.uscitaRimonta) { esce = true }
        Movimenti.dopo(Tema.Apple.Moto.tempo(m.durataRimonta)) {
            // Un altro clic nel frattempo: entra quella scelta per ultima
            guard prova.vista == nuova else { return }
            mostrata = nuova
            esce = false
        }
    }
}

/// Due viste una sopra l'altra: la prima (la testata) alla sua altezza, la seconda con esattamente l'altezza che resta.
/// A differenza di un VStack non sonda la seconda con proposte estreme per ripartire lo spazio: la ScrollView del
/// portafoglio riceve solo la proposta finita della finestra, come prima del giro 4.
private struct TestataSopra: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard proposal.width == nil || proposal.height == nil else { return proposal.replacingUnspecifiedDimensions() }
        // Proposta aperta (raro: la finestra la dà sempre finita): la somma delle due altezze ideali
        let misure = subviews.map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) }
        return CGSize(width: proposal.width ?? misure.map(\.width).max() ?? 0,
                      height: proposal.height ?? misure.reduce(0) { $0 + $1.height })
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for (i, vista) in subviews.enumerated() {
            let ultima = i == subviews.count - 1
            let altezza = ultima ? max(0, bounds.maxY - y)
                : vista.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil)).height
            vista.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading,
                        proposal: ProposedViewSize(width: bounds.width, height: altezza))
            y += altezza
        }
    }
}

/// La testata del Portafoglio: l'occhiello con il numero dei clienti e i segmenti delle due viste.
private struct TestataVistePortafoglio: View {
    let clienti: Int
    @Binding var vista: VistaPosizioni

    var body: some View {
        let t = Tema.Apple.Posizioni.Fuoco.Testata.self
        let d = Tema.Apple.Posizioni.Disposizione.self
        return HStack(alignment: .center, spacing: d.spazio) {
            Text(TestiProvaFuoco.occhiello(clienti: clienti))
                .carattereApple(t.occhiello)
                .foregroundColor(t.coloreOcchiello)
                .lineLimit(1)
            Spacer(minLength: 0)
            #if os(macOS)
            // Inquadra e capisci (giro 5, ScenaInquadra.swift): accanto ai segmenti, come nel template
            PulsanteInquadra()
            #endif
            SegmentatoPillola(selezione: $vista, voci: VistaPosizioni.segmenti)
        }
        .padding(.horizontal, d.margine)
        .padding(.top, d.margine)
        .padding(.bottom, t.sotto)
    }
}

// MARK: - La prova del fuoco

/// La vista «Prova del fuoco»: card dello scenario, titolo della lista e «Chi chiamare, in ordine».
struct ProvaDelFuocoApple: View, Equatable {
    let stato: StatoShell
    @Bindable var prova: StatoProvaFuoco
    let chiave: ChiaveVista
    let solaLettura: Bool

    @StateObject private var calcolo = CalcoloProvaFuoco()
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    /// L'ordine mostrato (id dei clienti): cambia solo al rilascio, a una chip o con dati nuovi.
    @State private var ordine: [String] = []
    /// Il prossimo risultato riordina la lista (vale l'ultima richiesta).
    @State private var riordinaAlRisultato = true
    /// «Chiama»: la conferma (con il numero) o l'avviso che il numero manca.
    @State private var chiamata: ChiamataProvaFuoco?

    nonisolated static func == (a: ProvaDelFuocoApple, b: ProvaDelFuocoApple) -> Bool {
        a.chiave == b.chiave && a.solaLettura == b.solaLettura
    }

    var body: some View {
        let f = Tema.Apple.Posizioni.Fuoco.self
        let d = Tema.Apple.Posizioni.Disposizione.self
        let e = esito
        let vuoto = stato.clienti.isEmpty
        return GeometryReader { g in
            VStack(alignment: .leading, spacing: 0) {
                CardScenarioFuoco(prova: prova, esito: e, inCorso: calcolo.inCorso && !istantanea, spenta: vuoto,
                                  stretta: g.size.width < f.Card.sogliaStretta,
                                  scegli: { scegli($0) },
                                  valore: valoreCursore,
                                  rilascio: { ricalcola(riordina: true) })
                    .entrataCascata(0, base: f.Moto.baseCascata)
                if vuoto {
                    vuotoGuidato
                } else {
                    titoloLista
                        .entrataCascata(1, base: f.Moto.baseCascata)
                    lista(e, misura: MisuraRigaFuoco(larghezza: g.size.width))
                }
            }
            .padding(.horizontal, d.margine)
            .padding(.top, d.margine)
            .frame(width: g.size.width, height: g.size.height, alignment: .topLeading)
        }
        .background(d.fondo)
        .onAppear(perform: avvia)
        .onDisappear { calcolo.ferma() }
        .onChange(of: chiave) { _ in avvia() }
        .onChange(of: calcolo.esito) { nuovo in applica(nuovo) }
        .alert(chiamata?.titolo ?? "", isPresented: presenteChiamata, presenting: chiamata) { c in
            if let numero = c.numero {
                Button(TestiProvaFuoco.chiama) { Self.telefona(numero) }
                Button(TestiProvaFuoco.annulla, role: .cancel) {}
            } else {
                Button(TestiProvaFuoco.apriDossier) { apriDossier(c.clienteId, scheda: .anagrafica, obiettivo: nil) }
                Button(TestiProvaFuoco.nonOra, role: .cancel) {}
            }
        } message: { c in
            Text(c.messaggio)
        }
    }

    // MARK: Esito e ordine

    /// L'esito da mostrare. Nelle istantanee si calcola subito qui (pochi clienti, stato finale dal primo disegno).
    private var esito: EsitoProvaFuoco? {
        if istantanea {
            return MotoreProvaFuoco.calcola(prova.scenario, clienti: stato.clienti, posizioni: stato.posizioni,
                                            obiettivi: stato.dati.obiettivi, oggi: chiave.giorno)
        }
        return calcolo.esito
    }

    private var chiaveBase: Int {
        var h = Hasher()
        h.combine(chiave.calcoli)
        h.combine(chiave.giorno)
        h.combine(chiave.modo)
        return h.finalize()
    }

    private func avvia() {
        guard !istantanea else { return }
        calcolo.preparaBase(chiave: chiaveBase, clienti: stato.clienti, posizioni: stato.posizioni,
                            obiettivi: stato.dati.obiettivi, oggi: chiave.giorno)
        ricalcola(riordina: true)
    }

    /// Un ricalcolo dello scenario scelto; `riordina` dice se il risultato riordina la lista (vince l'ultima richiesta).
    private func ricalcola(riordina: Bool) {
        guard !istantanea else { return }
        riordinaAlRisultato = riordina
        calcolo.ricalcola(prova.scenario)
    }

    /// Il risultato è arrivato: con clienti nuovi o diversi l'ordine si prende di colpo; altrimenti, se il risultato
    /// deve riordinare, le righe scivolano al nuovo posto (calmo: di colpo).
    private func applica(_ e: EsitoProvaFuoco?) {
        guard let e else { return }
        let nuovo = e.righe.map(\.id)
        guard nuovo != ordine else { return }
        var senza = Transaction()
        senza.disablesAnimations = true
        if Set(nuovo) != Set(ordine) {
            withTransaction(senza) { ordine = nuovo }
            return
        }
        guard riordinaAlRisultato else { return }
        if calmo {
            withTransaction(senza) { ordine = nuovo }
        } else {
            withAnimation(Tema.Apple.Moto.Riordino.animazione) { ordine = nuovo }
        }
    }

    /// Le righe nell'ordine mostrato (quello dell'esito finché l'ordine non ha gli stessi clienti).
    private func righeMostrate(_ e: EsitoProvaFuoco) -> [RigaProvaFuoco] {
        guard !istantanea, ordine.count == e.righe.count else { return e.righe }
        var perId: [String: RigaProvaFuoco] = [:]
        for r in e.righe { perId[r.id] = r }
        let mostrate = ordine.compactMap { perId[$0] }
        return mostrate.count == e.righe.count ? mostrate : e.righe
    }

    // MARK: Interazioni

    private func scegli(_ s: SceltaScenarioFuoco) {
        guard s != prova.scelta else { return }
        // La riga del cursore si sostituisce senza animazione; poi ricalcolo e riordino
        var senza = Transaction()
        senza.disablesAnimations = true
        withTransaction(senza) { prova.scelta = s }
        ricalcola(riordina: true)
    }

    /// Il valore del cursore: a ogni passo del trascinamento ricalcola senza riordinare.
    private var valoreCursore: Binding<Double> {
        let p = prova
        return Binding(get: { p.valore(p.scelta) },
                       set: { nuovo in
                           guard nuovo != p.valore(p.scelta) else { return }
                           p.imposta(nuovo, per: p.scelta)
                           ricalcola(riordina: false)
                       })
    }

    private func chiama(_ r: RigaProvaFuoco) {
        let numero = AperturaMessaggi.telefonoNormalizzato(r.telefono)
        chiamata = ChiamataProvaFuoco(clienteId: r.clienteId, nome: r.nome, numero: numero)
    }

    private func scrivi(_ r: RigaProvaFuoco, canali: [Canale], scenario: ScenarioFuoco) {
        let o = MotoreProvaFuoco.occasioneMessaggio(r, scenario: scenario, canale: canali.count == 1 ? canali.first : nil,
                                                    oggi: Date())
        stato.preparaMessaggio(clienteId: r.clienteId, occasione: o)
    }

    /// Il dossier del cliente, sulla scheda chiesta (Obiettivi con l'obiettivo mostrato, o Anagrafica per il telefono).
    private func apriDossier(_ clienteId: String, scheda: SchedaCliente, obiettivo: String?) {
        stato.clienteAttivoId = clienteId
        stato.schedaCliente = scheda
        if let obiettivo { stato.obiettivoSelezionato = obiettivo }
        stato.apri(.clienti)
    }

    /// Apre il numero con `tel:` (sul Mac FaceTime o l'iPhone con Continuity). Mai una chiamata senza conferma.
    @MainActor
    static func telefona(_ numero: String) {
        guard let url = URL(string: "tel:" + AperturaMessaggi.codifica(numero, anche: "+")) else { return }
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif os(iOS)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        #endif
    }

    private var presenteChiamata: Binding<Bool> {
        Binding(get: { chiamata != nil }, set: { acceso in if !acceso { chiamata = nil } })
    }

    // MARK: Parti della schermata

    private var titoloLista: some View {
        let t = Tema.Apple.Posizioni.Fuoco.Titolo.self
        return HStack(alignment: .firstTextBaseline, spacing: t.spazioNota) {
            Text(TestiProvaFuoco.titoloLista)
                .carattereApple(t.titolo)
                .foregroundColor(t.coloreTitolo)
                .lineLimit(1)
                .layoutPriority(1)
            Text(TestiProvaFuoco.notaLista)
                .carattereApple(t.nota)
                .foregroundColor(t.coloreNota)
                .lineLimit(1)
                .help(MotoreProvaFuoco.criterioOrdine)
            Spacer(minLength: 0)
        }
        .padding(.top, t.sopra)
        .padding(.horizontal, t.lati)
        .padding(.bottom, t.sotto)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func lista(_ e: EsitoProvaFuoco?, misura: MisuraRigaFuoco) -> some View {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        if let e {
            let clienti = Dictionary(stato.dati.clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let canali = Self.canaliInEssere(stato.posizioni)
            let righe = righeMostrate(e)
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: r.passo) {
                    ForEach(righe) { riga in
                        let c = clienti[riga.clienteId]
                        let suoi = canali[riga.clienteId] ?? c?.canali ?? []
                        RigaProvaFuocoApple(riga: riga, iniziali: c?.iniziali ?? "", tinta: c?.tinta ?? .blu, canali: suoi,
                                            misura: misura,
                                            chiama: { chiama(riga) },
                                            scrivi: { scrivi(riga, canali: suoi, scenario: e.scenario) },
                                            apri: { apriDossier(riga.clienteId, scheda: .obiettivi, obiettivo: riga.obiettivoId) })
                            .equatable()
                    }
                    if e.posizioniStimate > 0 {
                        Text(TestiProvaFuoco.notaStime(e.posizioniStimate))
                            .carattereApple(r.nota)
                            .foregroundColor(r.coloreNota)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, r.notaSopra)
                            .padding(.horizontal, Tema.Apple.Posizioni.Fuoco.Titolo.lati)
                    }
                }
                .padding(.trailing, r.margineScorrimento)
                .padding(.bottom, r.fondoLista)
            }
        } else {
            Spacer(minLength: 0)
        }
    }

    private var vuotoGuidato: some View {
        VuotoGuidato(
            icona: "flame",
            titolo: TestiProvaFuoco.vuotoTitolo,
            perche: TestiProvaFuoco.vuotoPerche,
            passi: TestiProvaFuoco.vuotoPassi,
            pulsante: TestiProvaFuoco.vuotoPulsante,
            azione: {
                stato.richiestaNuovoCliente = true
                stato.apri(.clienti)
            },
            secondario: (TestiProvaFuoco.vuotoSecondario, { stato.apri(.impostazioni) })
        )
        .disabled(solaLettura)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// I canali delle posizioni in essere di ogni cliente, nell'ordine dei canali (Alleanza, indipendente).
    static func canaliInEssere(_ posizioni: [Posizione]) -> [String: [Canale]] {
        var insiemi: [String: Set<Canale>] = [:]
        for p in posizioni where p.stato == .inEssere {
            insiemi[p.clienteId, default: []].insert(p.canale)
        }
        return insiemi.mapValues { s in Canale.allCases.filter { s.contains($0) } }
    }
}

/// «Chiama»: il cliente, il nome e il numero (nil se manca o non sembra un numero).
private struct ChiamataProvaFuoco: Identifiable {
    let clienteId: String
    let nome: String
    let numero: String?
    var id: String { clienteId }

    var titolo: String { numero == nil ? TestiProvaFuoco.mancaTelefono(nome) : TestiProvaFuoco.chiamare(nome) }
    var messaggio: String { numero.map(TestiProvaFuoco.confermaChiamata) ?? TestiProvaFuoco.aggiungiTelefono }
}

/// Le tre misure della riga, dalla larghezza della lista: piena, stretta (blocchi più corti, il canale col solo
/// pallino), minima (blocchi ancora più corti, pulsanti con il simbolo). I pulsanti restano sempre interi.
enum MisuraRigaFuoco: Equatable {
    case piena, stretta, minima

    init(larghezza: CGFloat) {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        if larghezza < r.sogliaMinima {
            self = .minima
        } else if larghezza < r.sogliaStretta {
            self = .stretta
        } else {
            self = .piena
        }
    }

    var larghezzaNome: CGFloat {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        switch self {
        case .piena: return r.larghezzaNome
        case .stretta: return r.larghezzaNomeStretta
        case .minima: return r.larghezzaNomeMinima
        }
    }

    var larghezzaPercento: CGFloat {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        switch self {
        case .piena: return r.larghezzaPercento
        case .stretta: return r.larghezzaPercentoStretta
        case .minima: return r.larghezzaPercentoMinima
        }
    }

    var larghezzaPerdita: CGFloat {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        switch self {
        case .piena: return r.larghezzaPerdita
        case .stretta: return r.larghezzaPerditaStretta
        case .minima: return r.larghezzaPerditaMinima
        }
    }
}

// MARK: - Card dello scenario

private struct CardScenarioFuoco: View {
    @Bindable var prova: StatoProvaFuoco
    let esito: EsitoProvaFuoco?
    let inCorso: Bool
    let spenta: Bool
    let stretta: Bool
    let scegli: (SceltaScenarioFuoco) -> Void
    let valore: Binding<Double>
    let rilascio: () -> Void

    var body: some View {
        let c = Tema.Apple.Posizioni.Fuoco.Card.self
        return Group {
            if stretta {
                // Card stretta: le cifre sotto lo scenario, in due colonne
                VStack(alignment: .leading, spacing: c.spazioCifreSotto) {
                    scenario
                    Rectangle()
                        .fill(c.filo)
                        .frame(height: c.spessoreFilo)
                        .accessibilityHidden(true)
                    HStack(alignment: .top, spacing: c.spazioColonne) {
                        clienti
                            .frame(maxWidth: c.larghezzaClientiStretta, alignment: .leading)
                        filo
                        patrimonio
                            .frame(maxWidth: c.larghezzaPatrimonioStretta, alignment: .leading)
                        Spacer(minLength: 0)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(alignment: .center, spacing: c.spazioColonne) {
                    scenario
                        .frame(maxWidth: .infinity, alignment: .leading)
                    filo
                    clienti
                        .frame(width: c.larghezzaClienti, alignment: .leading)
                    filo
                    patrimonio
                        .frame(width: c.larghezzaPatrimonio, alignment: .leading)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(c.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(c.superficie, raggio: c.raggio)
    }

    private var filo: some View {
        let c = Tema.Apple.Posizioni.Fuoco.Card.self
        return Rectangle()
            .fill(c.filo)
            .frame(width: c.spessoreFilo)
            .frame(maxHeight: .infinity)
            .accessibilityHidden(true)
    }

    private var scenario: some View {
        let c = Tema.Apple.Posizioni.Fuoco.Card.self
        let s = prova.scelta
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: c.spazioChip) {
                Text(TestiProvaFuoco.etichettaCard)
                    .carattereApple(c.etichetta)
                    .foregroundColor(c.coloreEtichetta)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(TestiProvaFuoco.ricalcolo)
                    .carattereApple(c.ricalcolo)
                    .foregroundColor(c.coloreRicalcolo)
                    .lineLimit(1)
                    .opacity(inCorso ? 1 : 0)
                    .animation(inCorso ? Tema.Apple.Moto.IndicatoreCalcolo.entrata : Tema.Apple.Moto.IndicatoreCalcolo.uscita,
                               value: inCorso)
                    .accessibilityHidden(!inCorso)
            }
            DisposizioneAcapoRicerca(spazio: c.spazioChip) {
                ForEach(SceltaScenarioFuoco.allCases) { x in
                    ChipApple(titolo: x.titolo, accesa: x == s) { scegli(x) }
                }
            }
            .padding(.top, c.chipSopra)
            .disabled(spenta)
            Group {
                if let cursore = s.cursore {
                    HStack(alignment: .center, spacing: c.spazioCursore) {
                        Text(cursore.etichetta)
                            .carattereApple(c.etichettaCursore)
                            .foregroundColor(c.coloreEtichettaCursore)
                            .lineLimit(1)
                            .frame(width: stretta ? nil : c.larghezzaEtichettaCursore, alignment: .leading)
                        CursoreApple(valore: valore, intervallo: cursore.intervallo, passo: cursore.passo,
                                     etichetta: cursore.etichetta, alRilascio: rilascio)
                        Text(StatoProvaFuoco.testoValore(prova.valore(s), per: s))
                            .carattereApple(c.valoreCursore)
                            .foregroundColor(c.coloreValoreCursore)
                            .lineLimit(1)
                            .frame(width: c.larghezzaValoreCursore, alignment: .trailing)
                            .accessibilityHidden(true)
                    }
                    .disabled(spenta)
                } else if let frase = StatoProvaFuoco.fraseStorica(s) {
                    Text(frase)
                        .carattereApple(c.frase)
                        .foregroundColor(c.coloreFrase)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, c.cursoreSopra)
        }
    }

    private var clienti: some View {
        let c = Tema.Apple.Posizioni.Fuoco.Card.self
        let n = esito?.oltreSoglia ?? 0
        return VStack(alignment: .leading, spacing: c.spazioSottoCifra) {
            NumeroCheConta(Double(n), formato: .intero)
                .carattereApple(c.numeroClienti)
                .foregroundColor(n == 0 ? c.coloreNessuno : c.coloreCifre)
                .lineLimit(1)
            Text(TestiProvaFuoco.sottoClienti(n))
                .carattereApple(c.sottoCifra)
                .foregroundColor(c.coloreSottoCifra)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var patrimonio: some View {
        let c = Tema.Apple.Posizioni.Fuoco.Card.self
        let perdita = esito?.perditaTotale ?? 0
        return VStack(alignment: .leading, spacing: c.spazioSottoCifra) {
            NumeroCheConta(-perdita, formato: .euro)
                .carattereApple(c.cifraPatrimonio)
                .foregroundColor(perdita >= 0.5 ? c.coloreCifre : c.coloreGuadagno)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(TestiProvaFuoco.sottoPatrimonio)
                .carattereApple(c.sottoCifra)
                .foregroundColor(c.coloreSottoCifra)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Una riga di «Chi chiamare»

private struct RigaProvaFuocoApple: View, Equatable {
    let riga: RigaProvaFuoco
    let iniziali: String
    let tinta: TintaAvatar
    let canali: [Canale]
    let misura: MisuraRigaFuoco
    let chiama: () -> Void
    let scrivi: () -> Void
    let apri: () -> Void

    nonisolated static func == (a: RigaProvaFuocoApple, b: RigaProvaFuocoApple) -> Bool {
        a.riga == b.riga && a.iniziali == b.iniziali && a.tinta == b.tinta && a.canali == b.canali && a.misura == b.misura
    }

    private var stretta: Bool { misura != .piena }

    var body: some View {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        let spazio = misura == .minima ? r.spazioMinimo : r.spazio
        return HStack(alignment: .center, spacing: spazio) {
            HStack(alignment: .center, spacing: spazio) {
                AvatarCliente(iniziali: iniziali, tinta: tinta.colori, lato: r.avatar)
                nome
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: apri)
            .help(TestiProvaFuoco.aiutoRiga)
            canaliVista
            barra
                .frame(minWidth: misura == .minima ? r.barraMinimaStretta : r.barraMinima, maxWidth: .infinity)
            percento
                .frame(width: misura.larghezzaPercento, alignment: .trailing)
            perdita
                .frame(width: misura.larghezzaPerdita, alignment: .trailing)
            pulsante(TestiProvaFuoco.chiama, simbolo: r.simboloChiama, azione: chiama)
            pulsante(TestiProvaFuoco.messaggio, simbolo: r.simboloMessaggio, azione: scrivi)
        }
        .padding(r.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(r.superficie, raggio: r.raggio)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(TestiProvaFuoco.voceRiga(riga)))
    }

    private var nome: some View {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        return VStack(alignment: .leading, spacing: r.spazioRighe) {
            Text(riga.nome)
                .carattereApple(r.nome)
                .foregroundColor(r.coloreNome)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(riga.titoloObiettivo ?? TestiProvaFuoco.senzaObiettivo)
                .carattereApple(r.obiettivo)
                .foregroundColor(r.coloreObiettivo)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: misura.larghezzaNome, alignment: .leading)
    }

    /// «Chiama» e «Messaggio»: interi sempre; nella riga minima il solo simbolo (con il nome per VoiceOver).
    @ViewBuilder private func pulsante(_ titolo: String, simbolo: String, azione: @escaping () -> Void) -> some View {
        if misura == .minima {
            Button(action: azione) {
                Image(systemName: simbolo)
                    .accessibilityHidden(true)
            }
            .buttonStyle(.apple)
            .fixedSize()
            .help(titolo)
            .accessibilityLabel(Text(titolo))
        } else {
            Button(titolo, action: azione)
                .buttonStyle(.apple)
                .fixedSize()
        }
    }

    /// Il canale delle posizioni in essere: l'etichetta compatta (nella riga stretta solo il pallino del colore).
    @ViewBuilder private var canaliVista: some View {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        if !canali.isEmpty {
            if stretta {
                HStack(spacing: r.spazioCanali) {
                    ForEach(canali) { c in
                        Circle()
                            .fill(r.coloreCanale(c))
                            .frame(width: r.pallinoCanale, height: r.pallinoCanale)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(canali.map(\.nome).joined(separator: ", ")))
                .help(canali.map(\.nome).joined(separator: " · "))
            } else {
                VStack(alignment: .leading, spacing: r.spazioCanali) {
                    ForEach(canali) { c in
                        EtichettaCanaleApple(canale: c, compatta: true)
                    }
                }
                .fixedSize()
            }
        }
    }

    @ViewBuilder private var barra: some View {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        if riga.obiettivoId != nil {
            BarraOggiDopo(oggi: riga.coperturaOggi, dopo: riga.coperturaDopo,
                          colore: Tema.Apple.Posizioni.Fuoco.Barra.colore(MotoreProvaFuoco.livello(calo: riga.calo)))
        } else {
            HStack(spacing: r.spazio) {
                Text(TestiProvaFuoco.nessunObiettivo)
                    .carattereApple(r.senzaObiettivo)
                    .foregroundColor(r.coloreSenzaObiettivo)
                    .lineLimit(1)
                Button(TestiProvaFuoco.aggiungiObiettivo, action: apri)
                    .buttonStyle(.appleSobrio)
                    .fixedSize()
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder private var percento: some View {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        if riga.obiettivoId != nil {
            let allarme = riga.oltreSoglia
            VStack(alignment: .trailing, spacing: r.spazioRighe) {
                HStack(spacing: r.spazioStima) {
                    if riga.stimata {
                        Text(TestiProvaFuoco.segnoStima)
                            .carattereApple(r.stima)
                            .foregroundColor(r.coloreStima)
                            .help(TestiProvaFuoco.aiutoStima)
                    }
                    Text(TestiProvaFuoco.dopo(riga.coperturaDopo))
                        .carattereApple(r.dopo)
                        .foregroundColor(allarme ? r.coloreDopoAllarme : r.coloreDopo)
                        .lineLimit(1)
                }
                Text(TestiProvaFuoco.oggi(riga.coperturaOggi))
                    .carattereApple(r.oggi)
                    .foregroundColor(r.coloreOggi)
                    .lineLimit(1)
                if riga.collegateAssenti && riga.calo == 0 {
                    Text(TestiProvaFuoco.nessunaCollegata)
                        .carattereApple(r.oggi)
                        .foregroundColor(r.coloreOggi)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        } else {
            Color.clear.frame(height: 1)
        }
    }

    private var perdita: some View {
        let r = Tema.Apple.Posizioni.Fuoco.Riga.self
        let p = riga.perdita
        return Text(TestiProvaFuoco.perdita(p))
            .carattereApple(r.perdita)
            .foregroundColor(p >= 0.5 ? r.colorePerdita : (p <= -0.5 ? r.coloreGuadagno : r.coloreOggi))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

// MARK: - Testi

/// I testi della prova del fuoco (template §6.1, parole esatte dove il template le dà).
enum TestiProvaFuoco {
    static func occhiello(clienti n: Int) -> String {
        "\(n) \(n == 1 ? "cliente" : "clienti") · aggiornato adesso"
    }

    static let etichettaCard = "La prova del fuoco · tutto il portafoglio"
    static let ricalcolo = "Ricalcolo…"
    static let titoloLista = "Chi chiamare, in ordine"
    static let notaLista = "la barra chiara è l’obiettivo oggi, quella piena dopo lo scenario"

    private static var soglia: String {
        Formati.numeroFormatter.string(from: NSNumber(value: MotoreProvaFuoco.sogliaAllarme)) ?? "10"
    }

    static func sottoClienti(_ n: Int) -> String {
        n == 1 ? "cliente scende di più di \(soglia) punti sul suo obiettivo"
               : "clienti scendono di più di \(soglia) punti sui loro obiettivi"
    }

    static let sottoPatrimonio = "di patrimonio, su tutto il portafoglio"

    static func dopo(_ c: Double) -> String { "dopo " + MotoreProvaFuoco.percento(c) }
    static func oggi(_ c: Double) -> String { "oggi " + MotoreProvaFuoco.percento(c) }

    /// «−17.232 €»; un guadagno con il «+»; sotto mezzo euro «0 €».
    static func perdita(_ p: Double) -> String {
        if p >= 0.5 { return Formati.euro(-p) }
        if p <= -0.5 { return "+" + Formati.euro(-p) }
        return Formati.euro(0)
    }

    static let senzaObiettivo = "Nessun obiettivo"
    static let nessunObiettivo = "Nessun obiettivo nel dossier"
    static let aggiungiObiettivo = "Aggiungi un obiettivo"
    static let nessunaCollegata = "nessuna posizione collegata"
    static let segnoStima = "≈"
    static let aiutoStima = "Composizione stimata dalla tipologia e dall'SRI"
    static let aiutoRiga = "Apri il dossier sulla scheda Obiettivi"

    static func notaStime(_ n: Int) -> String {
        n == 1 ? "Su 1 posizione la composizione è stimata: completala nella scheda della posizione."
               : "Su \(n) posizioni la composizione è stimata: completale nella scheda della posizione."
    }

    static let chiama = "Chiama"
    static let messaggio = "Messaggio"
    static let annulla = "Annulla"
    static let nonOra = "Non ora"
    static let apriDossier = "Apri il dossier"
    static func chiamare(_ nome: String) -> String { "Chiamare \(nome)?" }
    static func confermaChiamata(_ numero: String) -> String {
        "Il numero \(numero) si apre con l’app del telefono (sul Mac con l’iPhone vicino o FaceTime)."
    }
    static func mancaTelefono(_ nome: String) -> String { "Manca il telefono di \(nome)" }
    static let aggiungiTelefono = "Aggiungilo nel dossier, nella scheda Anagrafica."

    static let vuotoTitolo = "Nessun cliente da mettere alla prova"
    static let vuotoPerche = "La prova del fuoco applica uno scenario difficile a tutti i portafogli insieme e dice chi chiamare per primo: servono i clienti con le loro posizioni e i loro obiettivi."
    static let vuotoPassi: [(String, String)] = [
        ("Aggiungi un cliente", "Da Clienti, con «Nuovo cliente»."),
        ("Oppure carica i dati di prova", "Da Impostazioni, nella parte dei dati di prova."),
        ("Poi gli obiettivi", "Nel dossier, scheda Obiettivi, collegati alle posizioni."),
    ]
    static let vuotoPulsante = "Nuovo cliente"
    static let vuotoSecondario = "Apri Impostazioni"

    /// Per VoiceOver: nome, obiettivo, coperture e perdita.
    static func voceRiga(_ r: RigaProvaFuoco) -> String {
        var parti = [r.nome]
        if let t = r.titoloObiettivo, r.obiettivoId != nil {
            parti.append("\(t): \(oggi(r.coperturaOggi)), \(dopo(r.coperturaDopo))")
        } else {
            parti.append(nessunObiettivo)
        }
        parti.append("perdita \(perdita(r.perdita))")
        return parti.joined(separator: ", ")
    }
}
