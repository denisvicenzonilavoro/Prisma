import SwiftUI

// Posizioni › Portafoglio nel tema Apple (Design/template-apple-specifica.md §4.1, riferimenti posizioni-clienti/
// P01-P14, movimento/02-12):
//
//   ┌──────────── Portafoglio clienti  [In essere | Con le proposte] ┐┌── Lo stato del tuo lavoro ──┐
//   │ 1.124.350 €   +38.200 € da gennaio                             ││  ◎ Clienti in regola  32 su 35│
//   │ ▬▬▬▬▬▬▬▬▬▬ canali                                              ││    Riesami dell'anno  26 su 35│
//   │ ╱╲╱── storia ┄┄ stima con la fascia                            ││    Proposte concluse   9 su 15│
//   └────────────────────────────────────────────────────────────────┘└───────────────────────────────┘
//   Da fare, in ordine di tempo · 8 cose · 3 oggi                                              ‹ ›
//   Oggi  [scheda][scheda]  Questa settimana  [scheda] …
//   (sotto, i pannelli di sempre del Portafoglio: per cliente, seguito, fine anno, riesami, scadenze…)
//
// - Le cifre vengono dai motori: MotoreAndamentoPortafoglio (totale, delta, storia, stima e fascia),
//   MotoreStatoDelLavoro (i tre anelli, gli stessi della scrivania), MotoreDaFare (il nastro).
// - Le schede si inclinano verso il puntatore (solo quella sotto il puntatore lavora) e il dettaglio nasce dalla
//   scheda toccata (PresentatoreDettaglio): «Preparami l'incontro» compone il fascicolo come la mossa del giorno,
//   «Segna come fatto» registra la cosa fatta (StatoShell.segnaFatto) e fa partire la sequenza (SequenzaFatto):
//   la scheda si spunta, l'anello giusto sale e brilla, la scheda si stringe e le altre scorrono al suo posto.
// - «Riduci movimento» e istantanee: tutto nello stato finale (lo fanno i componenti del tema).
// - Prestazioni: la testata e il nastro sono sottoviste `Equatable` che si rifanno solo con una `ChiaveVista`
//   nuova o quando cambia la sequenza; le cifre stanno in cache (DerivatiDati); un solo dettaglio alla volta.

/// Il portafoglio del tema Apple con sotto i pannelli di sempre (`sotto`): scorre tutto insieme; il dettaglio
/// di una scheda si apre sopra, centrato nello spazio del portafoglio.
struct PortafoglioApple<Sotto: View>: View {
    @ObservedObject var stato: StatoShell
    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @StateObject private var dettaglio: StatoDettaglio
    @StateObject private var sequenza = SequenzaFatto<String>()
    @StateObject private var nastro: StatoNastroDaFare
    let sotto: Sotto

    /// Le istantanee possono chiedere «Con le proposte» o il dettaglio della prima scheda già aperto
    /// (RichiestaIstantaneaPortafoglio): così sono nello stato voluto dal primo disegno.
    init(stato: StatoShell, @ViewBuilder sotto: () -> Sotto) {
        _stato = ObservedObject(wrappedValue: stato)
        self.sotto = sotto()
        // Gli oggetti nascono una volta sola (`StateObject` valuta l'espressione solo alla prima comparsa)
        _dettaglio = StateObject(wrappedValue: Self.dettaglioIniziale(stato))
        _nastro = StateObject(wrappedValue: Self.nastroIniziale(stato))
    }

    private static func dettaglioIniziale(_ stato: StatoShell) -> StatoDettaglio {
        guard RichiestaIstantaneaPortafoglio.per(stato)?.dettaglio == true,
              let primo = stato.nastroDaFare().voci.first else { return StatoDettaglio() }
        return StatoDettaglio(aperto: primo.id, misura: Tema.Apple.Posizioni.Dettaglio.misura)
    }

    private static func nastroIniziale(_ stato: StatoShell) -> StatoNastroDaFare {
        let n = StatoNastroDaFare()
        n.conProposte = RichiestaIstantaneaPortafoglio.per(stato)?.conProposte ?? false
        return n
    }

    var body: some View {
        let d = Tema.Apple.Posizioni.Disposizione.self
        let chiave = stato.chiaveVista
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    TestaPortafoglioApple(stato: stato, chiave: chiave, nastro: nastro, sequenza: sequenza)
                        .equatable()
                    NastroDaFareApple(stato: stato, chiave: chiave, nastro: nastro, sequenza: sequenza,
                                      apri: { apri($0) })
                        .equatable()
                }
                .padding(.horizontal, d.margine)
                .padding(.top, d.margine)
                sotto
                    .padding(.top, d.spazioPannelli)
            }
        }
        .background(d.fondo)
        .presentatoreDettaglio(dettaglio) { id in
            dettaglioScheda(id)
        }
        .onDisappear { dettaglio.chiudi(subito: true) }
        .onChange(of: stato.richiestaEsito) { r in
            if r == nil { dopoEsito() }
        }
    }

    // MARK: - Dettaglio

    @ViewBuilder private func dettaglioScheda(_ id: String) -> some View {
        if let v = nastro.voce(id, in: stato.nastroDaFare()) {
            DettaglioDaFareApple(voce: v, nastro: nastro,
                                 prepara: { prepara(v) },
                                 fatto: { segna(v) },
                                 dossier: {
                                     dettaglio.chiudi(subito: true)
                                     stato.apriDossierDaFare(v)
                                 })
        }
    }

    private func apri(_ v: VoceDaFare) {
        guard sequenza.fase(v.id) == .inAttesa else { return }
        nastro.preparando = nil
        dettaglio.apri(v.id, misura: Tema.Apple.Posizioni.Dettaglio.misura)
    }

    /// «Preparami l'incontro»: la lista «Ti preparo» si spunta; alla fine il fascicolo si apre in Prospetti.
    private func prepara(_ v: VoceDaFare) {
        nastro.preparando = v.id
    }

    /// «Segna come fatto»: l'esito della proposta e «In regola» chiedono un modulo; il resto si registra e parte
    /// la sequenza quando il dettaglio è tornato sulla scheda.
    private func segna(_ v: VoceDaFare) {
        guard !stato.solaLettura else {
            stato.mostraAvviso(TestiPortafoglioApple.solaLettura)
            return
        }
        switch v.fatto {
        case .esitoProposta(let pid):
            guard let p = stato.posizioni.first(where: { $0.id == pid }) else { return }
            dettaglio.chiudi(poi: {
                nastro.attesaEsito = v
                nastro.trattieni(v)
                stato.apriEsito(p, passo: .scelta, origine: .posizioni)
            })
        case .apriInRegola:
            dettaglio.chiudi(subito: true)
            stato.apriInRegola(v.cliente.id)
        default:
            dettaglio.chiudi(poi: { avviaSequenza(v, registra: true) })
        }
    }

    /// Il modulo dell'esito si è chiuso: se la proposta non è più ferma, la scheda fa la sua sequenza.
    private func dopoEsito() {
        guard let v = nastro.attesaEsito else { return }
        nastro.attesaEsito = nil
        let ancoraFerma = stato.proposteInSospeso.contains { "proposta-" + $0.posizione.id == v.id }
        if ancoraFerma {
            nastro.lascia(v.id)
        } else {
            avviaSequenza(v, registra: false)
        }
    }

    /// La sequenza «fatto» (§2.14): la scheda resta sul nastro finché non è tolta, anche se i dati la tolgono prima.
    private func avviaSequenza(_ v: VoceDaFare, registra: Bool) {
        let s = stato
        let n = nastro
        let animazione = Tema.Apple.Moto.animazione(Tema.Apple.Moto.Nastro.animazione, calmo: calmo, istantanea: istantanea)
        n.trattieni(v)
        n.anello = v.anello
        sequenza.segna(v.id, calmo: calmo, istantanea: istantanea,
                       anello: { if registra { s.segnaFatto(v) } },
                       stringi: { s.mostraAvviso("\(v.cliente.nome): fatto") },
                       togli: { withAnimation(animazione) { n.lascia(v.id) } })
    }

}

// MARK: - Lo stato del nastro

/// Ciò che il nastro ricorda fra un disegno e l'altro: le schede che stanno uscendo (restano finché la sequenza
/// non le toglie), l'anello che ha appena brillato, la proposta di cui si aspetta l'esito, la scheda che si prepara.
final class StatoNastroDaFare: ObservableObject {
    @Published private(set) var trattenute: [VoceDaFare] = []
    /// L'anello dell'ultima cosa fatta: brilla e il testo sotto la legenda dice a che punto è.
    @Published var anello: VoceDaFare.Anello?
    /// La scheda del dettaglio aperto su cui è partito «Preparami l'incontro».
    @Published var preparando: String?
    /// «Con le proposte» nella card del portafoglio.
    @Published var conProposte = false
    /// La proposta di cui si aspetta l'esito (il modulo è aperto).
    var attesaEsito: VoceDaFare?

    func trattieni(_ v: VoceDaFare) {
        guard !trattenute.contains(where: { $0.id == v.id }) else { return }
        trattenute.append(v)
    }

    func lascia(_ id: String) {
        trattenute.removeAll { $0.id == id }
    }

    /// Una voce del nastro (anche se sta uscendo).
    func voce(_ id: String, in n: NastroDaFare) -> VoceDaFare? {
        n.voci.first { $0.id == id } ?? trattenute.first { $0.id == id }
    }

    /// Il nastro da mostrare: quello dei dati più le schede che stanno uscendo, al loro posto.
    func mostrato(_ n: NastroDaFare) -> NastroDaFare {
        guard !trattenute.isEmpty else { return n }
        let presenti = Set(n.voci.map(\.id))
        let extra = trattenute.filter { !presenti.contains($0.id) }
        guard !extra.isEmpty else { return n }
        var blocchi = n.blocchi
        for v in extra {
            if let i = blocchi.firstIndex(where: { $0.gruppo == v.gruppo }) {
                let voci = (blocchi[i].voci + [v]).sorted(by: MotoreDaFare.precede)
                blocchi[i] = NastroDaFare.Blocco(gruppo: v.gruppo, voci: voci, totale: blocchi[i].totale + 1)
            } else {
                blocchi.append(NastroDaFare.Blocco(gruppo: v.gruppo, voci: [v], totale: 1))
                blocchi.sort { $0.gruppo < $1.gruppo }
            }
        }
        return NastroDaFare(blocchi: blocchi)
    }
}

/// Ciò che una scena delle istantanee chiede al portafoglio (Prisma --istantanee): «Con le proposte» o il dettaglio
/// della prima scheda aperto. Vale solo per lo stato della scena (riferimento debole: le scene dopo non lo vedono).
final class RichiestaIstantaneaPortafoglio {
    nonisolated(unsafe) private static var attuale: RichiestaIstantaneaPortafoglio?

    private weak var stato: StatoShell?
    let conProposte: Bool
    let dettaglio: Bool

    private init(stato: StatoShell, conProposte: Bool, dettaglio: Bool) {
        self.stato = stato
        self.conProposte = conProposte
        self.dettaglio = dettaglio
    }

    static func chiedi(_ s: StatoShell, conProposte: Bool = false, dettaglio: Bool = false) {
        attuale = RichiestaIstantaneaPortafoglio(stato: s, conProposte: conProposte, dettaglio: dettaglio)
    }

    static func per(_ s: StatoShell) -> RichiestaIstantaneaPortafoglio? {
        guard let r = attuale, r.stato === s else { return nil }
        return r
    }
}

// MARK: - Testata: card del portafoglio e stato del lavoro

private struct TestaPortafoglioApple: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    @ObservedObject var nastro: StatoNastroDaFare
    @ObservedObject var sequenza: SequenzaFatto<String>

    nonisolated static func == (a: TestaPortafoglioApple, b: TestaPortafoglioApple) -> Bool { a.chiave == b.chiave }

    var body: some View {
        let d = Tema.Apple.Posizioni.Disposizione.self
        GeometryReader { geo in
            let larghezze = Self.larghezze(geo.size.width)
            HStack(alignment: .top, spacing: d.spazio) {
                CardPortafoglioApple(andamento: stato.andamentoPortafoglio(), riepilogo: stato.riepilogoTuttePosizioni,
                                     clienti: stato.clienti.count, conProposte: $nastro.conProposte)
                    .frame(width: larghezze.card, height: d.altezzaRiga)
                    .entrataCascata(0)
                CardLavoroApple(lavoro: stato.statoDelLavoro(), larghezza: larghezze.lavoro, anello: nastro.anello,
                                impulso: sequenza.impulsoBrillio)
                    .frame(width: larghezze.lavoro, height: d.altezzaRiga)
                    .entrataCascata(1)
            }
        }
        .frame(height: d.altezzaRiga)
    }

    /// Card e stato del lavoro in proporzione (870 / 498), lo stato del lavoro mai sotto il suo minimo.
    private static func larghezze(_ totale: CGFloat) -> (card: CGFloat, lavoro: CGFloat) {
        let d = Tema.Apple.Posizioni.Disposizione.self
        let libero = max(0, totale - d.spazio)
        let somma = d.quoteRiga.reduce(0, +)
        let quota = somma > 0 ? d.quoteRiga[1] / somma : 0.5
        let lavoro = min(libero, max(d.larghezzaMinimaLavoro, libero * quota))
        return (max(0, libero - lavoro), lavoro)
    }
}

/// La card del portafoglio: totale che si conta, delta, barra dei canali e grafico «In essere / Con le proposte».
private struct CardPortafoglioApple: View {
    let andamento: AndamentoPortafoglio
    let riepilogo: RiepilogoPosizioni
    let clienti: Int
    @Binding var conProposte: Bool

    var body: some View {
        let c = Tema.Apple.Posizioni.Card.self
        let a = andamento
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(TestiPortafoglioApple.titoloCard)
                    .carattereApple(c.etichetta)
                    .foregroundColor(c.coloreEtichetta)
                    .lineLimit(1)
                Spacer(minLength: 0)
                SegmentatoPillola(selezione: $conProposte, voci: [(false, "In essere"), (true, "Con le proposte")])
            }
            totale
                .padding(.top, c.totaleSopra)
            BarraPienaSegmenti.canali(alleanza: riepilogo.quota(.alleanza) * 100,
                                      indipendente: riepilogo.quota(.indipendente) * 100, indice: c.indiceBarra)
                .frame(maxWidth: c.larghezzaBarra)
                .frame(height: Tema.Apple.Grafico.Barra.altezza)
                .padding(.top, c.barraSopra)
                .padding(.bottom, c.barraSotto)
            canali
            Spacer(minLength: 0)
        }
        .padding(c.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Il grafico in fondo alla card, 26 dai lati (come nel template: sta sotto le cifre, non le spinge)
        .overlay(alignment: .bottom) {
            if !a.vuoto {
                GraficoPortafoglio(dati: Self.dati(a), progresso: conProposte ? 1 : 0)
                    .padding(.horizontal, c.padding.leading)
                    .padding(.bottom, c.graficoSotto)
            }
        }
        .superficieApple(c.superficie, raggio: c.raggio)
    }

    private var totale: some View {
        let c = Tema.Apple.Posizioni.Card.self
        let a = andamento
        let coloreDelta: Color = conProposte ? c.coloreDeltaProposte : (a.delta >= 0 ? c.coloreDelta : c.coloreDeltaNegativo)
        let delta = conProposte ? TestiPortafoglioApple.deltaProposte(a) : TestiPortafoglioApple.delta(a)
        let sotto = conProposte ? TestiPortafoglioApple.sottoProposte(a)
                                : TestiPortafoglioApple.sottoDelta(clienti: clienti, proposte: a.proposteAperte)
        return HStack(alignment: .bottom, spacing: c.spazioDelta) {
            NumeroCheConta(conProposte ? a.conProposte : a.inEssere, formato: .euro, indice: c.indiceTotale)
                .carattereApple(c.totale)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(c.riduzioneTotale)
                .layoutPriority(1)
            VStack(alignment: .leading, spacing: 2) {
                Text(delta)
                    .carattereApple(c.delta)
                    .foregroundColor(coloreDelta)
                    .lineLimit(1)
                Text(sotto)
                    .carattereApple(c.sottoDelta)
                    .foregroundColor(c.coloreSottoDelta)
                    // «… · stima a maggio 2027» non finisce con «…»: va a capo
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, c.deltaSotto)
        }
    }

    /// I due canali, sempre riconoscibili: l'etichetta e il valore in essere che si conta.
    private var canali: some View {
        let c = Tema.Apple.Posizioni.Card.self
        return HStack(spacing: c.spazioCanale) {
            ForEach(Array(Canale.allCases.enumerated()), id: \.element) { i, canale in
                if i > 0 { Spacer().frame(width: c.spazioFraCanali) }
                EtichettaCanaleApple(canale: canale)
                NumeroCheConta(riepilogo.perCanale[canale] ?? 0, formato: .euro, indice: c.indiceCanali + i)
                    .carattereApple(c.cifraCanale)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
            }
        }
    }

    /// I dati del grafico: storia, stima, fascia e mesi dell'asse (uno per punto), con i limiti in euro.
    static func dati(_ a: AndamentoPortafoglio) -> DatiGraficoPortafoglio {
        let mesi = (a.giorniStoria + a.giorniStima.dropFirst()).map { TestiPortafoglioApple.meseAsse.string(from: $0) }
        let tutti = a.storia + a.stimaBassa + a.stimaAlta
        let basso = tutti.min() ?? 0
        let altoStoria = a.storia.max() ?? 0
        let altoStima = max(altoStoria, (a.stimaAlta + a.stima).max() ?? 0)
        // Un po' d'aria sopra e sotto (4% del campo, mai zero)
        let campo = max(altoStima - basso, max(altoStima, 1) * 0.02)
        let aria = campo * 0.04
        return DatiGraficoPortafoglio(storia: a.storia, stima: a.stima, stimaAlta: a.stimaAlta, stimaBassa: a.stimaBassa,
                                      mesi: mesi, minimo: max(0, basso - aria),
                                      massimoInEssere: max(altoStoria + aria, basso + aria * 2),
                                      massimoConProposte: altoStima + aria,
                                      etichettaStima: TestiPortafoglioApple.etichettaStima(a))
    }
}

/// «Lo stato del tuo lavoro»: tre anelli (in regola, riesami dell'anno, proposte concluse) con la legenda che conta.
private struct CardLavoroApple: View {
    let lavoro: StatoDelLavoro
    let larghezza: CGFloat
    let anello: VoceDaFare.Anello?
    let impulso: Int

    var body: some View {
        let l = Tema.Apple.Posizioni.Lavoro.self
        let interno = larghezza - l.padding.leading - l.padding.trailing
        let lato = min(l.anelli, max(l.anelliMinimi, interno - l.spazioAnelli - l.larghezzaLegenda))
        return VStack(alignment: .leading, spacing: 0) {
            Text(TestiPortafoglioApple.titoloLavoro)
                .carattereApple(Tema.Apple.Posizioni.Card.etichetta)
                .foregroundColor(Tema.Apple.Posizioni.Card.coloreEtichetta)
                .lineLimit(1)
            HStack(alignment: .center, spacing: l.spazioAnelli) {
                AnelliConcentrici(voci: voci, misura: lato, spessore: l.spessoreAnelli * lato / l.anelli,
                                  ritardo: Tema.Apple.Moto.Anello.ritardoFinestra,
                                  brilla: anello?.rawValue, impulsoBrillio: impulso)
                legenda
            }
            .padding(.top, l.anelliSopra)
            Spacer(minLength: 0)
        }
        .padding(l.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .superficieApple(l.superficie, raggio: l.raggio)
    }

    private var voci: [VoceAnello] {
        let l = Tema.Apple.Posizioni.Lavoro.self
        return [
            VoceAnello(id: VoceDaFare.Anello.inRegola.rawValue, valore: Double(lavoro.inRegola.fatti),
                       massimo: Double(lavoro.inRegola.totale), colore: l.coloreInRegola),
            VoceAnello(id: VoceDaFare.Anello.riesami.rawValue, valore: Double(lavoro.riesami.fatti),
                       massimo: Double(lavoro.riesami.totale), colore: l.coloreRiesami),
            VoceAnello(id: VoceDaFare.Anello.proposte.rawValue, valore: Double(lavoro.proposte.fatti),
                       massimo: Double(lavoro.proposte.totale), colore: l.coloreProposte),
        ]
    }

    private static let nomi: [(VoceDaFare.Anello, String, String)] = [
        (.inRegola, "Clienti in regola", "Clienti senza scadenze di conformità da sistemare"),
        (.riesami, "Riesami dell'anno", "Clienti con posizioni in essere visti negli ultimi 12 mesi"),
        (.proposte, "Proposte concluse", "Proposte presentate concluse, accettate o rifiutate"),
    ]

    private func conteggio(_ a: VoceDaFare.Anello) -> StatoDelLavoro.Conteggio {
        switch a {
        case .inRegola: return lavoro.inRegola
        case .riesami: return lavoro.riesami
        case .proposte: return lavoro.proposte
        }
    }

    private func colore(_ a: VoceDaFare.Anello) -> Color {
        let l = Tema.Apple.Posizioni.Lavoro.self
        switch a {
        case .inRegola: return l.coloreInRegola
        case .riesami: return l.coloreRiesami
        case .proposte: return l.coloreProposte
        }
    }

    private var legenda: some View {
        let l = Tema.Apple.Posizioni.Lavoro.self
        let invito: String
        if let a = anello, let nome = Self.nomi.first(where: { $0.0 == a })?.1 {
            invito = TestiPortafoglioApple.esitoAnello(nome, conteggio(a))
        } else {
            invito = TestiPortafoglioApple.invitoAnelli
        }
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.nomi.enumerated()), id: \.offset) { i, voce in
                rigaLegenda(voce.0, nome: voce.1, aiuto: voce.2, indice: i, ultima: i == Self.nomi.count - 1)
            }
            Text(invito)
                .carattereApple(l.invito)
                .foregroundColor(l.coloreInvito)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, l.invitoSopra)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rigaLegenda(_ a: VoceDaFare.Anello, nome: String, aiuto: String, indice: Int, ultima: Bool) -> some View {
        let l = Tema.Apple.Posizioni.Lavoro.self
        let c = conteggio(a)
        return HStack(spacing: l.spazioLegenda) {
            Circle()
                .fill(colore(a))
                .frame(width: l.pallino, height: l.pallino)
            Text(nome)
                .carattereApple(l.nome)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                // Card stretta: il nome va a capo invece di finire con «…»
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer(minLength: 4)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                NumeroCheConta(Double(c.fatti), formato: .intero, indice: indice)
                    .carattereApple(l.numero)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                Text("su \(c.totale)")
                    .carattereApple(l.su)
                    .foregroundColor(l.coloreSu)
            }
            .fixedSize()
        }
        .padding(.vertical, l.rigaLegenda)
        .overlay(alignment: .bottom) {
            if !ultima {
                Rectangle().fill(l.filetto).frame(height: Tema.Apple.Misura.bordo)
            }
        }
        .help(aiuto)
    }
}

// MARK: - Nastro «Da fare, in ordine di tempo»

private struct NastroDaFareApple: View, Equatable {
    let stato: StatoShell
    let chiave: ChiaveVista
    @ObservedObject var nastro: StatoNastroDaFare
    @ObservedObject var sequenza: SequenzaFatto<String>
    let apri: (VoceDaFare) -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    /// L'elemento del nastro da cui partono le frecce (gruppi e schede, nell'ordine).
    @State private var posizione = 0

    nonisolated static func == (a: NastroDaFareApple, b: NastroDaFareApple) -> Bool { a.chiave == b.chiave }

    var body: some View {
        let n = Tema.Apple.Posizioni.Nastro.self
        let mostrato = nastro.mostrato(stato.nastroDaFare())
        return VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { lettore in
                VStack(alignment: .leading, spacing: n.testataSotto) {
                    testata(mostrato, lettore: lettore)
                    if mostrato.vuoto {
                        Text(TestiPortafoglioApple.nastroVuoto)
                            .carattereApple(n.vuoto)
                            .foregroundColor(n.coloreVuoto)
                            .padding(.vertical, n.padding.top)
                            .padding(.horizontal, Tema.Apple.Posizioni.Disposizione.margine)
                    } else {
                        schede(mostrato)
                    }
                }
            }
        }
        .padding(.top, n.testataSopra)
        .entrataCascata(2)
    }

    private func testata(_ m: NastroDaFare, lettore: ScrollViewProxy) -> some View {
        let n = Tema.Apple.Posizioni.Nastro.self
        let elementi = Self.elementi(m)
        return HStack(alignment: .center, spacing: n.spazioConteggio) {
            Text(TestiPortafoglioApple.titoloNastro)
                .carattereApple(n.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
            if !m.vuoto {
                Text(TestiPortafoglioApple.conteggio(m))
                    .carattereApple(n.conteggio)
                    .foregroundColor(n.coloreConteggio)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if elementi.count > 1 {
                HStack(spacing: n.spazioFrecce) {
                    FrecciaNastroApple(simbolo: "chevron.left", aiuto: "Indietro") { sposta(-1, elementi, lettore) }
                    FrecciaNastroApple(simbolo: "chevron.right", aiuto: "Avanti") { sposta(1, elementi, lettore) }
                }
            }
        }
        .padding(.horizontal, Tema.Apple.Posizioni.Disposizione.margine / 3)
    }

    private func schede(_ m: NastroDaFare) -> some View {
        let n = Tema.Apple.Posizioni.Nastro.self
        let s = Tema.Apple.Posizioni.Scheda.self
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: n.spazio) {
                ForEach(m.blocchi) { b in
                    TestaGruppoDaFareApple(blocco: b)
                        .id(Self.idGruppo(b))
                        .transition(.opacity)
                    ForEach(b.voci) { v in
                        SchedaDaFareApple(voce: v, patrimonio: stato.riepilogoPosizioniCliente(v.cliente.id).attivita,
                                          fase: sequenza.fase(v.id), apri: { apri(v) })
                            .id(v.id)
                    }
                }
            }
            .padding(n.padding)
            .frame(height: s.misura.height + n.padding.top + n.padding.bottom, alignment: .top)
        }
        .padding(.horizontal, -n.sbordo)
        .mask { mascheraNastro }
    }

    /// 30 sfumati a sinistra, 60 a destra.
    private var mascheraNastro: some View {
        let n = Tema.Apple.Posizioni.Nastro.self
        return HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: n.sfumaturaSinistra)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: n.sfumaturaDestra)
        }
    }

    private static func idGruppo(_ b: NastroDaFare.Blocco) -> String { "gruppo-\(b.gruppo.rawValue)" }

    /// Gli id del nastro, nell'ordine: il gruppo, poi le sue schede.
    private static func elementi(_ m: NastroDaFare) -> [String] {
        m.blocchi.flatMap { b in [idGruppo(b)] + b.voci.map(\.id) }
    }

    /// Le frecce: due schede avanti o indietro (il ±500 del template), con la curva `uscita` in 0,7 s.
    private func sposta(_ verso: Int, _ elementi: [String], _ lettore: ScrollViewProxy) {
        guard !elementi.isEmpty else { return }
        let passo = Tema.Apple.Posizioni.Nastro.schedePerFreccia
        let nuova = min(max(0, posizione + verso * passo), elementi.count - 1)
        posizione = nuova
        let animazione = Tema.Apple.Moto.animazione(Tema.Apple.Moto.Nastro.animazione, calmo: calmo, istantanea: istantanea)
        withAnimation(animazione) {
            lettore.scrollTo(elementi[nuova], anchor: .leading)
        }
    }
}

/// Una freccia del nastro: cerchio da 32 su `cardPiena` con il bordo.
private struct FrecciaNastroApple: View {
    let simbolo: String
    let aiuto: String
    let azione: () -> Void

    var body: some View {
        let lato = Tema.Apple.Posizioni.Nastro.freccia
        Button(action: azione) {
            Image(systemName: simbolo)
                .carattereApple(Tema.Apple.Carattere.pulsante)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .frame(width: lato, height: lato)
                .background { Circle().fill(Tema.Apple.Colore.cardPiena) }
                .overlay { Circle().strokeBorder(Tema.Apple.Colore.separatore, lineWidth: Tema.Apple.Misura.bordo) }
                .contentShape(Circle())
        }
        .buttonStyle(StileSemplice())
        .help(aiuto)
        .accessibilityLabel(Text(aiuto))
    }
}

/// La testata di un gruppo: «Oggi» 22 bold e il conteggio.
private struct TestaGruppoDaFareApple: View {
    let blocco: NastroDaFare.Blocco

    var body: some View {
        let n = Tema.Apple.Posizioni.Nastro.self
        VStack(alignment: .leading, spacing: 2) {
            Text(blocco.gruppo.titolo)
                .carattereApple(n.titoloGruppo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
            Text(blocco.totale == 1 ? "1 cosa" : "\(blocco.totale) cose")
                .carattereApple(n.conteggioGruppo)
                .foregroundColor(n.coloreConteggioGruppo)
            if blocco.nascoste > 0 {
                Text("\(blocco.voci.count) qui, \(blocco.nascoste) in Agenda e nei dossier")
                    .carattereApple(n.conteggioGruppo)
                    .foregroundColor(n.coloreConteggioGruppo)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, n.gruppoSopra)
        .frame(width: n.larghezzaGruppo, alignment: .topLeading)
    }
}

/// Una scheda «Da fare» (232×270): fascia nel tono, quando, perché, canali e cliente. Si inclina verso il
/// puntatore e il dettaglio nasce da lei; nella sequenza «fatto» si spunta e si stringe.
private struct SchedaDaFareApple: View {
    let voce: VoceDaFare
    let patrimonio: Double
    let fase: FaseFatto
    let apri: () -> Void

    var body: some View {
        let s = Tema.Apple.Posizioni.Scheda.self
        let tono = s.colore(voce.tono)
        let forma = RoundedRectangle(cornerRadius: s.raggio, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            Text(voce.quando)
                .carattereApple(s.quando)
                .foregroundColor(tono)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(voce.perche)
                .carattereApple(s.perche)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(s.righePerche)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, s.percheSopra)
            Spacer(minLength: 0)
            if !voce.canali.isEmpty {
                HStack(spacing: s.spazioCanali) {
                    ForEach(voce.canali, id: \.self) { c in
                        EtichettaCanaleApple(canale: c, compatta: true)
                    }
                }
                .padding(.top, s.canaliSopra)
            }
            HStack(spacing: s.spazioCliente) {
                AvatarCliente(iniziali: voce.cliente.iniziali, tinta: voce.cliente.tinta.colori, lato: s.avatar)
                VStack(alignment: .leading, spacing: s.spazioNomePatrimonio) {
                    Text(voce.cliente.nome)
                        .carattereApple(s.nome)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .lineLimit(1)
                    Text(Formati.euro(patrimonio))
                        .carattereApple(s.patrimonio)
                        .foregroundColor(s.colorePatrimonio)
                        .lineLimit(1)
                }
            }
            .padding(.top, s.clienteSopra)
        }
        .padding(s.padding)
        .padding(.top, s.fascia)
        .frame(width: s.misura.width, height: s.misura.height, alignment: .topLeading)
        .overlay(alignment: .top) {
            // La fascia nel tono, che segue gli angoli tondi della scheda
            forma.fill(tono)
                .mask(alignment: .top) { Rectangle().frame(height: s.fascia) }
                .allowsHitTesting(false)
        }
        .contentShape(forma)
        .onTapGesture(perform: apri)
        .superficieApple(s.superficie, raggio: s.raggio)
        .inclinazione(massimo: s.inclinazione, raggio: s.raggio, attiva: fase == .inAttesa)
        .origineDettaglio(id: voce.id)
        .schedaFatta(fase, larghezza: s.misura.width, raggio: s.raggio)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Dettaglio di una scheda (880×520)

private struct DettaglioDaFareApple: View {
    let voce: VoceDaFare
    @ObservedObject var nastro: StatoNastroDaFare
    let prepara: () -> Void
    let fatto: () -> Void
    let dossier: () -> Void

    @EnvironmentObject var stato: StatoShell
    @Environment(\.statoDettaglioApple) private var dettaglio

    var body: some View {
        let d = Tema.Apple.Posizioni.Dettaglio.self
        VStack(alignment: .leading, spacing: 0) {
            testata
            Text(voce.perche)
                .carattereApple(d.perche)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: d.larghezzaTesto, alignment: .leading)
                .padding(.top, d.percheSopra)
                .padding(.bottom, d.percheSotto)
            Text(voce.spiegazione)
                .carattereApple(d.spiegazione)
                .foregroundColor(d.coloreSpiegazione)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: d.larghezzaTesto, alignment: .leading)
            GeometryReader { geo in
                colonne(larghezza: geo.size.width)
            }
            .padding(.top, d.colonneSopra)
            piede
        }
    }

    private var testata: some View {
        let d = Tema.Apple.Posizioni.Dettaglio.self
        let margine = max(0, d.margineChiudi - Tema.Apple.Misura.Padding.dettaglio.trailing)
        return HStack(alignment: .center, spacing: d.spazioTestata) {
            AvatarCliente(iniziali: voce.cliente.iniziali, tinta: voce.cliente.tinta.colori, lato: d.avatar)
            VStack(alignment: .leading, spacing: 2) {
                Text(voce.quando)
                    .carattereApple(d.quando)
                    .foregroundColor(Tema.Apple.Posizioni.Scheda.colore(voce.tono))
                    .lineLimit(1)
                Text(voce.cliente.nome)
                    .carattereApple(d.nome)
                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            HStack(spacing: d.spazioCanali) {
                ForEach(voce.canali, id: \.self) { c in
                    EtichettaCanaleApple(canale: c)
                }
            }
            .padding(.trailing, margine)
        }
    }

    private func colonne(larghezza: CGFloat) -> some View {
        let d = Tema.Apple.Posizioni.Dettaglio.self
        let libero = max(0, larghezza - d.spazioColonne)
        let sinistra = libero * d.quotaSinistra / (d.quotaSinistra + 1)
        return HStack(alignment: .top, spacing: d.spazioColonne) {
            cifre(larghezza: sinistra)
                .frame(width: sinistra, alignment: .topLeading)
            ListaTiPreparo(voci: vociFascicolo, avviata: nastro.preparando == voce.id, poi: { fascicoloPronto() })
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    /// Patrimonio, capitale assicurato e proposte aperte del cliente, con il suo patrimonio da gennaio.
    private func cifre(larghezza: CGFloat) -> some View {
        let d = Tema.Apple.Posizioni.Dettaglio.self
        let r = stato.riepilogoPosizioniCliente(voce.cliente.id)
        let a = stato.andamentoCliente(voce.cliente.id)
        let w = min(d.grafico.width, larghezza)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: d.spazioCifre) {
                cifra("Patrimonio", r.attivita, formato: .euro, indice: 0)
                cifra("Capitale assicurato", r.capitaleAssicurato, formato: .euro, indice: 1)
                cifra("Proposte aperte", Double(r.proposteAperte), formato: .intero, indice: 2)
            }
            if a.storia.count > 1 {
                TracciatoGrafico(punti: Self.punti(a.storia),
                                 colore: Tema.Apple.Posizioni.coloreCliente(voce.cliente.tinta),
                                 spessore: d.spessoreGrafico, area: true, opacitaArea: d.opacitaAreaGrafico)
                    .frame(width: w, height: d.grafico.height)
                    .padding(.top, d.graficoSopra)
                HStack {
                    Text(a.inizio.map { TestiPortafoglioApple.meseAnnoAsse.string(from: $0) } ?? "")
                    Spacer(minLength: 0)
                    Text("oggi")
                }
                .carattereApple(d.asse)
                .foregroundColor(d.coloreAsse)
                .frame(width: w)
                .padding(.top, d.asseSopra)
            }
        }
    }

    private func cifra(_ titolo: String, _ valore: Double, formato: FormatoCifra, indice: Int) -> some View {
        let d = Tema.Apple.Posizioni.Dettaglio.self
        return VStack(alignment: .leading, spacing: 2) {
            Text(titolo)
                .carattereApple(d.etichettaCifra)
                .foregroundColor(d.coloreEtichettaCifra)
                .lineLimit(1)
            NumeroCheConta(valore, formato: formato, indice: indice)
                .carattereApple(d.cifra)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    /// I valori del cliente normalizzati per il tracciato (come `pathDa` del template: −2% sotto, +1% sopra).
    private static func punti(_ storia: [Double]) -> [CGPoint] {
        let basso = (storia.min() ?? 0) * 0.98
        let alto = max((storia.max() ?? 0) * 1.01, basso + 1)
        let n = max(storia.count - 1, 1)
        return storia.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) / CGFloat(n), y: CGFloat((v - basso) / (alto - basso)))
        }
    }

    /// I report del fascicolo che «Ti preparo» spunta.
    private var vociFascicolo: [String] {
        let nomi = stato.reportDaFare(voce).map(\.nome)
        return nomi.isEmpty ? ["Il fascicolo dell'incontro"] : nomi
    }

    /// Le voci sono spuntate: il dettaglio si chiude e il fascicolo si apre in Prospetti, già composto.
    private func fascicoloPronto() {
        guard nastro.preparando == voce.id else { return }
        nastro.preparando = nil
        dettaglio?.chiudi(subito: true)
        stato.preparaIncontroDaFare(voce)
        stato.mostraAvviso("Fascicolo per \(voce.cliente.nome) pronto in Prospetti")
    }

    private var piede: some View {
        let d = Tema.Apple.Posizioni.Dettaglio.self
        let preparando = nastro.preparando == voce.id
        return HStack(spacing: d.spazioPulsanti) {
            Button(action: prepara) {
                Text("Preparami l'incontro")
            }
            .buttonStyle(StilePulsanteApple(.principale, grande: true))
            .disabled(preparando)
            Button(action: fatto) {
                Text(voce.fatto == .apriInRegola ? "Apri «In regola»" : "Segna come fatto")
            }
            .buttonStyle(.appleGrande)
            .disabled(stato.solaLettura || preparando)
            Button(action: dossier) {
                Text("Apri il dossier")
            }
            .buttonStyle(.appleGrande)
            Spacer(minLength: 0)
            Text(TestiPortafoglioApple.cifreDaiMotori)
                .carattereApple(d.nota)
                .foregroundColor(d.coloreNota)
                .lineLimit(1)
        }
    }
}
