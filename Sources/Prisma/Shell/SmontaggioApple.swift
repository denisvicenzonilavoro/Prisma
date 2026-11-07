import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

// Posizioni › Smontaggio (Design/template-luce-specifica.md §8.2, «Luce» giro 2):
//
//   ┌ vassoio ─────────────────────────────────────────┐ ┌ card 1 ─────────────────────────────┐
//   │  nota ─ ─ ─ ┌ foglio ───────────────────┐         │ │ (GR) L'estratto conto di Giulia…    │
//   │             │ BANCA ESEMPIO · FAC-SIMILE│         │ │ Costi l'anno, oggi  Con la proposta │
//   │             │ Gestione   ( 2,10% l'anno )─ ─ nota │ │ 2.410 €             760 €           │
//   │             └───────────────────────────┘         │ └─────────────────────────────────────┘
//   └───────────────────────────────────────────────────┘ ┌ card 2: in dieci anni, grafico ─────┐
//
// - Le voci e le cifre vengono da MotoreSmontaggio (regole fisse, nessuna percentuale inventata), il confronto da
//   MotoreSostituzione (penale, ingresso, tasse, ipotesi di Prisma) su una posizione provvisoria mai salvata.
// - Il documento: un PDF o una foto trascinati sul vassoio (letti sul Mac), un documento del dossier, le righe
//   inquadrate dall'iPhone (InquadraturaPonte, se la vista attiva è lo Smontaggio) o l'esempio fac-simile (dati di prova).
//   La foto non si conserva (decisione 47): il foglio è sempre ricostruito dalle righe.
// - Movimento: le ellissi si disegnano una alla volta, le note arrivano dopo la loro ellisse, i numeri si contano, le
//   linee si disegnano. «Riduci movimento» e istantanee: tutto fermo nello stato finale.

/// Lo stato dello Smontaggio: il documento letto, le scelte dell'utente e la proposta da confrontare. Resta finché
/// Prisma è aperta, mai nell'archivio (la foto e le righe di un'altra banca non si salvano da sole).
final class StatoSmontaggio: ObservableObject {
    @Published var righe: [RigaLetta] = []
    @Published var titolo = ""
    /// Da dove viene il documento («Inquadrato con l'iPhone», il nome del file, «Fac-simile»).
    @Published var origine = ""
    @Published var clienteId: String?
    /// La posizione in Prisma a cui si riferisce il documento (se c'è): valore, versato e condizioni da lì.
    @Published var posizioneId: String?
    @Published var inLettura = false
    /// L'alternativa scelta: l'id di una proposta del cliente (nil = la meno costosa, decisione 5).
    @Published var propostaId: String?
    /// Righe che l'utente ha segnato come costo, con il tipo, e righe che non sono costi.
    @Published var tipiScelti: [Int: TipoCosto] = [:]
    @Published var esclusi: Set<Int> = []
    /// Solo per le istantanee: la riga con il fumetto già aperto.
    var fumettoIstantanea: Int?
    /// L'ultima inquadratura dall'iPhone già presa (non si ricarica due volte).
    var ultimaInquadratura: String?
    /// Cresce a ogni documento nuovo: le ellissi ripartono.
    @Published private(set) var giro = 0

    var vuoto: Bool { righe.isEmpty && !inLettura }

    func carica(righe: [RigaLetta], titolo: String, origine: String, clienteId: String?, posizioneId: String? = nil) {
        self.righe = righe
        self.titolo = titolo
        self.origine = origine
        self.clienteId = clienteId
        self.posizioneId = posizioneId
        propostaId = nil
        tipiScelti = [:]
        esclusi = []
        inLettura = false
        giro += 1
    }

    /// L'esempio del template, dichiarato fac-simile (dati di prova).
    func caricaEsempio(clienteId: String?) {
        carica(righe: TestiSmontaggio.righeFacSimile.map { RigaLetta(testo: $0) }, titolo: "Fondo Esempio Globale",
               origine: "Fac-simile di esempio · dati di prova", clienteId: clienteId)
    }

    func svuota() {
        righe = []
        titolo = ""
        origine = ""
        posizioneId = nil
        propostaId = nil
        giro += 1
    }
}

struct SmontaggioApple: View {
    @ObservedObject var stato: StatoShell
    @ObservedObject var smontaggio: StatoSmontaggio
    @State private var fumetto: Int?
    @State private var sopraVassoio = false

    private typealias S = Tema.Apple.Posizioni.Smontaggio

    init(stato: StatoShell) {
        _stato = ObservedObject(wrappedValue: stato)
        _smontaggio = ObservedObject(wrappedValue: stato.smontaggio)
        _fumetto = State(initialValue: stato.smontaggio.fumettoIstantanea)
    }

    var body: some View {
        let cliente = smontaggio.clienteId.flatMap { id in stato.dati.clienti.first { $0.id == id } }
        let posizione = smontaggio.posizioneId.flatMap { id in stato.dati.posizioni.first { $0.id == id } }
        let costi = MotoreSmontaggio.smonta(righeEffettive, valore: posizione?.valore, versato: posizione?.totaleVersato,
                                            penaleCondizioni: nil)
        let proposte = proposteDelCliente(cliente?.id)
        let attuale = MotoreSmontaggio.posizioneProvvisoria(costi, da: posizione, clienteId: cliente?.id ?? "",
                                                            nome: smontaggio.titolo)
        let scelta = sceltaProposta(proposte, attuale: attuale)
        let esito = attuale.flatMap { a in scelta.map { MotoreSmontaggio.confronto(costi, attuale: a, proposta: $0, prodotti: stato.dati.prodotti) } }
        return GeometryReader { g in
            let m = Tema.Apple.Posizioni.Disposizione.margine
            let affiancati = g.size.width >= S.sogliaAffiancati
            let colonna = min(S.larghezzaColonna, max(S.colonnaMinima, g.size.width * 0.38))
            Group {
                if affiancati {
                    HStack(alignment: .top, spacing: S.spazio) {
                        vassoio(costi, cliente: cliente)
                            .entrataCascata(0, base: S.Moto.baseCascata)
                        ScrollView(.vertical, showsIndicators: false) {
                            colonnaCard(costi, cliente: cliente, posizione: posizione, proposte: proposte, scelta: scelta, esito: esito)
                        }
                        .frame(width: colonna)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: S.spazio) {
                            vassoio(costi, cliente: cliente).frame(minHeight: 560)
                            colonnaCard(costi, cliente: cliente, posizione: posizione, proposte: proposte, scelta: scelta, esito: esito)
                        }
                    }
                }
            }
            .padding(m)
        }
    }

    /// Le righe con le scelte dell'utente: le escluse diventano testo semplice, le segnate portano la parola del tipo.
    private var righeEffettive: [RigaLetta] {
        smontaggio.righe.enumerated().map { i, r in
            if smontaggio.esclusi.contains(i) { return RigaLetta(testo: "· " + r.testo.filter { !$0.isNumber }, riquadro: r.riquadro) }
            if let t = smontaggio.tipiScelti[i], MotoreSmontaggio.tipo(r.testo) != t {
                return RigaLetta(testo: t.nome + " " + MotoreSmontaggio.valoreScritto(r.testo), riquadro: r.riquadro)
            }
            return r
        }
    }

    private func proposteDelCliente(_ id: String?) -> [Posizione] {
        guard let id else { return [] }
        return stato.dati.posizioni.filter { $0.clienteId == id && $0.stato == .proposta && $0.area != .protezione }
    }

    /// La proposta scelta, o quella con il costo annuo più basso (decisione 5).
    private func sceltaProposta(_ proposte: [Posizione], attuale: Posizione?) -> Posizione? {
        if let id = smontaggio.propostaId, let p = proposte.first(where: { $0.id == id }) { return adatta(p, a: attuale) }
        return proposte.min { ($0.costoAnnuoPercento ?? .infinity) < ($1.costoAnnuoPercento ?? .infinity) }.map { adatta($0, a: attuale) }
    }

    /// La proposta con lo stesso capitale del documento (il confronto riparte dal valore di oggi).
    private func adatta(_ p: Posizione, a attuale: Posizione?) -> Posizione {
        var q = p
        if let v = attuale?.valore, q.versamentoIniziale <= 0 { q.versamentoIniziale = v }
        return q
    }

    // MARK: Vassoio

    @ViewBuilder private func vassoio(_ costi: SmontaggioCosti, cliente: Cliente?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: S.raggioVassoio, style: .continuous)
                .fill(S.fondoVassoio)
                .overlay(RoundedRectangle(cornerRadius: S.raggioVassoio, style: .continuous)
                    .stroke(sopraVassoio ? Tema.Apple.Colore.accento : .clear, lineWidth: 2))
            if smontaggio.inLettura {
                Text("Leggo il documento sul Mac…")
                    .carattereApple(Tema.Apple.Carattere.corpoGrande)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            } else if smontaggio.vuoto {
                vuoto(cliente)
            } else {
                // Foglio e note insieme stanno nella larghezza del vassoio: se serve si rimpiccioliscono insieme
                GeometryReader { g in
                    let scala = min(1, (g.size.width - 2 * S.sopraVassoio) / FoglioAnnotato.larghezzaTotale)
                    ScrollView(.vertical, showsIndicators: false) {
                        FoglioAnnotato(righe: smontaggio.righe, costi: costi, nomeCliente: nomeBreve(cliente),
                                       giro: smontaggio.giro, fumetto: $fumetto,
                                       togli: { smontaggio.esclusi.insert($0) },
                                       segna: { riga, tipo in smontaggio.tipiScelti[riga] = tipo; smontaggio.esclusi.remove(riga) })
                            .scaleEffect(scala, anchor: .top)
                            .padding(.top, S.sopraVassoio)
                            .frame(width: g.size.width)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        .onDrop(of: [.fileURL], isTargeted: $sopraVassoio) { fornitori in
            guard let f = fornitori.first else { return false }
            _ = f.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { stato.leggiFileSmontaggio(url) }
            }
            return true
        }
        #endif
    }

    private func vuoto(_ cliente: Cliente?) -> some View {
        VStack(spacing: 16) {
            Text(TestiSmontaggio.vuoto)
                .carattereApple(Tema.Apple.Carattere.corpoGrande)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            HStack(spacing: 10) {
                #if os(macOS)
                PulsanteInquadra()
                Button("Scegli un documento…") { scegliFile() }
                    .buttonStyle(.apple)
                #endif
                Button("Apri l'esempio (fac-simile)") { smontaggio.caricaEsempio(clienteId: cliente?.id ?? stato.clienteAttivoId) }
                    .buttonStyle(.appleSobrio)
            }
        }
        .padding(30)
    }

    #if os(macOS)
    private func scegliFile() {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.pdf, .image]
        p.allowsMultipleSelection = false
        guard p.runModal() == .OK, let url = p.url else { return }
        stato.leggiFileSmontaggio(url)
    }
    #endif

    private func nomeBreve(_ c: Cliente?) -> String {
        c?.nome.split(separator: " ").first.map(String.init) ?? "il cliente"
    }

    // MARK: Le card

    private func colonnaCard(_ costi: SmontaggioCosti, cliente: Cliente?, posizione: Posizione?, proposte: [Posizione],
                             scelta: Posizione?, esito: EsitoSostituzione?) -> some View {
        VStack(alignment: .leading, spacing: S.spazio) {
            cardDocumento(costi, cliente: cliente, posizione: posizione, scelta: scelta)
                .entrataCascata(1, base: S.Moto.baseCascata)
            cardDieciAnni(costi, proposte: proposte, scelta: scelta, esito: esito)
                .entrataCascata(2, base: S.Moto.baseCascata)
        }
    }

    private func cardDocumento(_ costi: SmontaggioCosti, cliente: Cliente?, posizione: Posizione?, scelta: Posizione?) -> some View {
        let oggi = costi.costoAnnuo
        let conTe = scelta.flatMap { p -> Double? in
            guard let v = costi.valore, let c = p.costoAnnuoPercento else { return nil }
            return v * c / 100
        }
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                if let c = cliente {
                    AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: 40)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(smontaggio.vuoto ? "Nessun documento" : "Il documento di \(nomeBreve(cliente)) · \(smontaggio.origine)")
                        .carattereApple(Tema.Apple.Carattere.secondario)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .lineLimit(2)
                    Text(smontaggio.titolo.isEmpty ? "—" : smontaggio.titolo + (costi.valore.map { " · " + Formati.euro($0) } ?? ""))
                        .carattereApple(S.titoloCard)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                }
                Spacer(minLength: 0)
                if let p = posizione { EtichettaCanaleApple(canale: p.canale, compatta: true) }
            }
            HStack(alignment: .top, spacing: S.spazioCifre) {
                cifra("Costi l'anno, oggi", oggi, colore: Tema.Apple.Colore.rosso, indice: 0)
                cifra("Con la tua proposta", conTe, colore: Tema.Apple.Colore.verde, indice: 1)
            }
            if posizione == nil, !smontaggio.vuoto {
                Text(TestiSmontaggio.provvisoria)
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
            if !smontaggio.vuoto, costi.vuoto {
                Text(TestiSmontaggio.nessunCosto)
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
        }
        .padding(S.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Superficie.cardPiatta)
    }

    @ViewBuilder private func cifra(_ titolo: String, _ v: Double?, colore: Color, indice: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo)
                .carattereApple(Tema.Apple.Carattere.secondario)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
            if let v {
                NumeroCheConta(v, indice: indice)
                    .carattereApple(S.cifra)
                    .foregroundColor(colore)
            } else {
                Text("—").carattereApple(S.cifra).foregroundColor(Tema.Apple.Colore.inchiostro3)
            }
        }
    }

    private func cardDieciAnni(_ costi: SmontaggioCosti, proposte: [Posizione], scelta: Posizione?, esito: EsitoSostituzione?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("In \(IpotesiCalcolo.orizzontePredefinito) anni, con le ipotesi di Prisma")
                    .carattereApple(Tema.Apple.Carattere.etichetta)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                Spacer(minLength: 8)
                if let p = scelta { EtichettaCanaleApple(canale: p.canale, compatta: true) }
            }
            Menu {
                if proposte.isEmpty { Text("Il cliente non ha proposte: creane una in Posizioni") }
                ForEach(proposte) { p in
                    Button(p.nome + (p.costoAnnuoPercento.map { " · costi \(TestiSmontaggio.percento($0))" } ?? "")) {
                        smontaggio.propostaId = p.id
                    }
                }
            } label: {
                Text(scelta.map { "Confronta con: \($0.nome)" } ?? TestiSmontaggio.scegliProposta)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .disabled(smontaggio.vuoto)
            if let e = esito, let fine = e.finale {
                let differenza = fine.differenza
                NumeroCheConta(differenza, indice: 2)
                    .carattereApple(S.guadagno)
                    .foregroundColor(differenza >= 0 ? Tema.Apple.Colore.verde : Tema.Apple.Colore.rosso)
                Text("per \(nomeCliente), netto, rispetto a restare. "
                     + TestiSmontaggio.didascalia(rendimento: e.resto.rendimento, anni: e.anni))
                    .carattereApple(Tema.Apple.Carattere.secondario)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                GraficoDieciAnni(serie: e.serie)
                    .frame(height: S.grafico.height)
                    .padding(.top, 4)
            } else {
                Text(smontaggio.vuoto ? "Scegli prima un documento." : TestiSmontaggio.scegliProposta + ": il confronto usa penale, costi d'ingresso e tasse.")
                    .carattereApple(Tema.Apple.Carattere.corpo)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { pulsantiProposta(scelta) }
                VStack(alignment: .leading, spacing: 10) { pulsantiProposta(scelta) }
            }
            .padding(.top, 6)
        }
        .padding(S.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(Tema.Apple.Superficie.cardPiatta)
    }

    @ViewBuilder private func pulsantiProposta(_ scelta: Posizione?) -> some View {
        Button("Crea la proposta di sostituzione") { creaProposta(scelta) }
            .buttonStyle(StilePulsanteApple(.principale, grande: true))
            .disabled(scelta == nil || stato.solaLettura)
            .fixedSize()
        #if os(macOS)
        Button("Inquadra un altro documento") { stato.apriInquadra() }
            .buttonStyle(StilePulsanteApple(.secondaria, grande: true))
            .fixedSize()
        #endif
    }

    private var nomeCliente: String {
        nomeBreve(smontaggio.clienteId.flatMap { id in stato.dati.clienti.first { $0.id == id } })
    }

    /// Apre la proposta scelta nel dossier del cliente, sulle posizioni: la sostituzione si presenta da lì (il prospetto
    /// di sostituzione esiste già). Niente si salva senza l'utente.
    private func creaProposta(_ p: Posizione?) {
        guard let p else { return }
        stato.clienteAttivoId = p.clienteId
        stato.posizioneInDettaglio = p.id
        stato.mostraAvviso("Proposta di sostituzione: \(p.nome). Il prospetto di sostituzione è nella posizione.")
    }
}

// MARK: - Il foglio annotato

/// Il foglio ricostruito dalle righe, con le ellissi rosse disegnate a mano sui valori delle voci di costo e le note
/// fuori dal foglio, alternate a destra e a sinistra, legate all'ellisse da una linea tratteggiata.
struct FoglioAnnotato: View {
    let righe: [RigaLetta]
    let costi: SmontaggioCosti
    let nomeCliente: String
    let giro: Int
    @Binding var fumetto: Int?
    let togli: (Int) -> Void
    let segna: (Int, TipoCosto) -> Void
    /// Nelle istantanee i popover di sistema non si vedono: il fumetto si disegna sotto il valore.
    @Environment(\.modoIstantanea) private var istantanea

    private typealias S = Tema.Apple.Posizioni.Smontaggio
    private typealias P = Tema.Apple.Carta

    /// Foglio scalato più i due margini delle note.
    static var larghezzaTotale: CGFloat {
        let s = Tema.Apple.Posizioni.Smontaggio.self
        return s.larghezzaFoglio * s.scalaFoglio + 2 * (s.larghezzaNota + s.distanzaNota)
    }

    var body: some View {
        let voci = Dictionary(costi.voci.map { ($0.riga, $0) }, uniquingKeysWith: { a, _ in a })
        let ordine = costi.voci.map(\.riga)
        let foglio = VStack(alignment: .leading, spacing: 0) {
            testata(voci: voci)
            Rectangle().fill(P.testo).frame(height: S.filoTabella).padding(.top, S.sopraTabella)
            ForEach(Array(righe.enumerated()).filter { $0.offset >= inizioTabella }, id: \.offset) { i, r in
                rigaFoglio(i, r, voce: voci[i], ordine: ordine.firstIndex(of: i))
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(0..<S.righeFinte, id: \.self) { k in
                    RoundedRectangle(cornerRadius: 3).fill(S.rigaFinta)
                        .frame(width: S.larghezzaFoglio * (k % 2 == 0 ? 0.62 : 0.48), height: S.altezzaRigaFinta)
                }
            }
            .padding(.top, 22)
        }
        .padding(S.paddingFoglio)
        .frame(width: S.larghezzaFoglio, alignment: .leading)
        .superficieApple(Tema.Apple.Superficie.carta)
        .environment(\.colorScheme, .light)

        return foglio
            .scaleEffect(S.scalaFoglio, anchor: .top)
            .frame(width: S.larghezzaFoglio * S.scalaFoglio)
            // Le note stanno nei margini ai lati del foglio: lo spazio si mette prima di disegnarle
            .padding(.horizontal, S.larghezzaNota + S.distanzaNota)
            .overlayPreferenceValue(ChiaveValoriFoglio.self) { ancore in
                GeometryReader { g in note(ancore: ancore, geo: g, voci: voci, ordine: ordine) }
            }
            .id(giro)
    }

    /// Le prime righe che non sono costi e vengono prima del primo costo: occhiello, titolo, sottotitolo, valore.
    private var inizioTabella: Int {
        let primo = costi.voci.map(\.riga).min() ?? righe.count
        return min(primo, min(4, righe.count))
    }

    @ViewBuilder private func testata(voci: [Int: VoceCostoTrovata]) -> some View {
        let testa = Array(righe.prefix(inizioTabella).enumerated())
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(testa.filter { !$0.element.testo.lowercased().contains("valore") }, id: \.offset) { k, r in
                    Text(r.testo)
                        .carattereApple(k == 0 ? S.occhiello : (k == 1 ? S.titolo : S.sottotitolo))
                        .foregroundColor(k == 0 ? S.coloreOcchiello : (k == 1 ? P.testo : P.sottotitolo))
                }
            }
            Spacer(minLength: 16)
            if let v = costi.valore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Valore").carattereApple(S.etichettaValore).foregroundColor(P.piede)
                    Text(Formati.euro(v)).carattereApple(S.valoreFoglio).foregroundColor(P.testo)
                }
            }
        }
    }

    @ViewBuilder private func rigaFoglio(_ i: Int, _ r: RigaLetta, voce: VoceCostoTrovata?, ordine: Int?) -> some View {
        HStack(alignment: .center) {
            Text(voce?.etichetta ?? r.testo)
                .carattereApple(S.riga)
                .foregroundColor(P.testoCorrente)
            Spacer(minLength: 12)
            if let v = voce {
                Text(v.valoreScritto)
                    .carattereApple(S.valoreRiga)
                    .foregroundColor(P.testo)
                    .overlay {
                        CerchioAMano(indice: ordine ?? 0, tratteggiato: v.fonte == .mancante)
                            .padding(.horizontal, -S.margineCerchio)
                            .frame(height: S.altezzaCerchio)
                    }
                    .anchorPreference(key: ChiaveValoriFoglio.self, value: .bounds) { [i: $0] }
                    .onTapGesture { fumetto = fumetto == i ? nil : i }
                    .popover(isPresented: Binding(get: { fumetto == i && !istantanea }, set: { if !$0 { fumetto = nil } })) {
                        FumettoCosto(voce: v, togli: { fumetto = nil; togli(i) })
                    }
                    .overlay(alignment: .topTrailing) {
                        if istantanea, fumetto == i {
                            FumettoCosto(voce: v, togli: {})
                                .superficieApple(Tema.Apple.Superficie.dettaglio, raggio: Tema.Apple.Raggio.voce)
                                .fixedSize()
                                .offset(y: S.altezzaCerchio)
                                .zIndex(10)
                        }
                    }
            }
        }
        .padding(S.paddingRiga)
        .overlay(alignment: .bottom) { Rectangle().fill(P.filetto).frame(height: 1) }
        .contentShape(Rectangle())
        .contextMenu {
            if voce == nil {
                Text("Segna come costo")
                ForEach(TipoCosto.allCases) { t in Button(t.nome) { segna(i, t) } }
            } else {
                Button("Non è un costo") { togli(i) }
            }
        }
    }

    /// Le note: pari a destra del foglio, dispari a sinistra, all'altezza della loro ellisse.
    @ViewBuilder private func note(ancore: [Int: Anchor<CGRect>], geo: GeometryProxy, voci: [Int: VoceCostoTrovata],
                                   ordine: [Int]) -> some View {
        let conNota = ordine.compactMap { riga -> (Int, String)? in
            guard let v = voci[riga], let n = TestiSmontaggio.nota(v, in: costi, nomeCliente: nomeCliente) else { return nil }
            return (riga, n)
        }
        ZStack(alignment: .topLeading) {
            ForEach(Array(conNota.enumerated()), id: \.element.0) { k, coppia in
                if let a = ancore[coppia.0] {
                    let r = geo[a]
                    let destra = k % 2 == 0
                    let x = destra ? geo.size.width - S.larghezzaNota : 0
                    // A destra la linea parte dall'ellisse; a sinistra dal bordo del foglio, senza attraversare la riga
                    let attacco = CGPoint(x: destra ? r.maxX + S.margineCerchio : S.larghezzaNota + S.distanzaNota, y: r.midY)
                    let arrivo = CGPoint(x: destra ? x : S.larghezzaNota, y: r.midY)
                    NotaRichiamo(testo: coppia.1, destra: destra, da: attacco, a: arrivo,
                                 indice: ordine.firstIndex(of: coppia.0) ?? k)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                        .overlay(alignment: .topLeading) {
                            Text(coppia.1)
                                .carattereApple(S.nota)
                                .foregroundColor(S.coloreNota)
                                .multilineTextAlignment(destra ? .leading : .trailing)
                                .frame(width: S.larghezzaNota, alignment: destra ? .leading : .trailing)
                                .offset(x: x, y: r.midY - 10)
                                .modifier(ComparsaNota(indice: ordine.firstIndex(of: coppia.0) ?? k))
                        }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ChiaveValoriFoglio: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// L'ellisse rossa disegnata a mano: si traccia in 0,70 s dopo 0,50 + i·0,65 s, ruotata di −2°. Tratteggiata quando la
/// cifra in euro non si può calcolare.
struct CerchioAMano: View {
    let indice: Int
    let tratteggiato: Bool
    @State private var disegno: CGFloat = 0
    @Environment(\.prismaStatoFinale) private var fermo
    private typealias S = Tema.Apple.Posizioni.Smontaggio

    var body: some View {
        Ellipse()
            .trim(from: 0, to: fermo ? 1 : disegno)
            .stroke(S.coloreCerchio, style: StrokeStyle(lineWidth: S.spessoreCerchio, lineCap: .round,
                                                        dash: tratteggiato ? S.tratteggioMancante : []))
            .rotationEffect(.degrees(S.rotazioneCerchio))
            .allowsHitTesting(false)
            .onAppear {
                guard !fermo else { return }
                withAnimation(S.Moto.animazione.delay(S.Moto.partenza(indice))) { disegno = 1 }
            }
    }
}

/// La linea tratteggiata dall'ellisse alla nota.
private struct NotaRichiamo: View {
    let testo: String
    let destra: Bool
    let da: CGPoint
    let a: CGPoint
    let indice: Int
    private typealias S = Tema.Apple.Posizioni.Smontaggio

    var body: some View {
        Path { p in
            p.move(to: da)
            p.addLine(to: a)
        }
        .stroke(S.coloreCerchio, style: StrokeStyle(lineWidth: S.spessoreRichiamo, dash: S.tratteggioRichiamo))
        .modifier(ComparsaNota(indice: indice))
    }
}

/// La nota arriva 0,40 s dopo la sua ellisse, da 6 più in basso, in 0,50 s.
private struct ComparsaNota: ViewModifier {
    let indice: Int
    @State private var dentro = false
    @Environment(\.prismaStatoFinale) private var fermo
    private typealias M = Tema.Apple.Posizioni.Smontaggio.Moto

    func body(content: Content) -> some View {
        let visibile = fermo || dentro
        return content
            .opacity(visibile ? 1 : 0)
            .offset(y: visibile ? 0 : M.spostamentoNota)
            .onAppear {
                guard !fermo else { return }
                withAnimation(Tema.Apple.Moto.Curva.uscita.animazione(M.durataNota).delay(M.partenza(indice) + M.ritardoNota)) {
                    dentro = true
                }
            }
    }
}

/// Il fumetto di un'ellisse: la riga letta, il conto e la fonte; «Non è un costo» toglie la voce.
private struct FumettoCosto: View {
    let voce: VoceCostoTrovata
    let togli: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(voce.tipo.nome).carattereApple(Tema.Apple.Carattere.titoloRiga)
            Text("Scritto: \(voce.etichetta) \(voce.valoreScritto)").carattereApple(Tema.Apple.Carattere.secondario)
            if let c = voce.conto { Text(c).carattereApple(Tema.Apple.Carattere.corpo) }
            Text(fonte).carattereApple(Tema.Apple.Carattere.secondario).foregroundColor(Tema.Apple.Colore.inchiostro2)
            Button("Non è un costo", action: togli).buttonStyle(.appleSobrio)
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
    }

    private var fonte: String {
        switch voce.fonte {
        case .scritta: return "Scritto nel documento."
        case .calcolata: return "Calcolato da Prisma (stima)."
        case .mancante: return voce.motivoMancante.map { TestiSmontaggio.maiuscola($0) + "." } ?? "Cifra non calcolabile."
        }
    }
}

/// Le due linee a dieci anni (netto restando e netto cambiando) con l'area fra le due, e le etichette a destra.
private struct GraficoDieciAnni: View {
    let serie: [AnnoSostituzione]
    private typealias S = Tema.Apple.Posizioni.Smontaggio

    var body: some View {
        let valori = serie.flatMap { [$0.nettoResto, $0.nettoCambio] }
        let minimo = (valori.min() ?? 0) * 0.98
        let massimo = max((valori.max() ?? 1) * 1.01, minimo + 1)
        let n = max(1, serie.count - 1)
        func punti(_ v: (AnnoSostituzione) -> Double) -> [CGPoint] {
            serie.enumerated().map { i, a in CGPoint(x: CGFloat(i) / CGFloat(n), y: CGFloat((v(a) - minimo) / (massimo - minimo))) }
        }
        let oggi = punti(\.nettoResto)
        let conTe = punti(\.nettoCambio)
        return HStack(spacing: 8) {
            ZStack {
                FasciaGrafico(sopra: conTe, sotto: oggi, colore: S.lineaConTe, opacita: S.opacitaArea, ritardo: 0.6)
                TracciatoGrafico(punti: oggi, colore: S.lineaOggi, spessore: S.spessoreOggi, indice: 0)
                TracciatoGrafico(punti: conTe, colore: S.lineaConTe, spessore: S.spessoreConTe, indice: 1)
            }
            VStack(alignment: .leading) {
                Text("con te").carattereApple(S.etichettaLinea).foregroundColor(S.lineaConTe)
                Spacer()
                Text("oggi").carattereApple(S.etichettaLinea).foregroundColor(S.lineaOggi)
            }
            .frame(width: 44)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Grafico a \(serie.count - 1) anni: con la proposta \(Formati.euro(serie.last?.nettoCambio ?? 0)), restando \(Formati.euro(serie.last?.nettoResto ?? 0))")
    }
}

// MARK: - Azioni

extension StatoShell {
    /// Posizioni › Smontaggio (dal pannello Novità e dalle istantanee). In modalità cliente il Portafoglio non si apre.
    func apriSmontaggio() {
        guard !inModoCliente else {
            mostraAvviso("In modalità cliente lo smontaggio non si apre: si apre dal Portafoglio.")
            return
        }
        posizioneInDettaglio = nil
        portafoglio = true
        provaFuoco.vista = .smontaggio
        apriApp(.posizioni)
    }

    /// Un PDF o una foto trascinati sul vassoio: letti sul Mac (PDFKit, Vision), mai conservati da soli.
    func leggiFileSmontaggio(_ url: URL) {
        let estensione = url.pathExtension.lowercased()
        guard LetturaDocumenti.estensioniAccettate.contains(estensione) else {
            mostraAvviso("\(url.lastPathComponent) non si legge: Prisma legge PDF e immagini (PNG, JPEG, TIFF, HEIC).")
            return
        }
        smontaggio.inLettura = true
        let cliente = clienteAttivoId
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let righe: [RigaLetta] = autoreleasepool {
                guard let esito = LetturaDocumenti.leggi(url),
                      let pagina = esito.pagine.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { return [] }
                return pagina.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .map { RigaLetta(testo: $0) }
            }
            DispatchQueue.main.async {
                guard let self else { return }
                if righe.isEmpty {
                    self.smontaggio.inLettura = false
                    self.mostraAvviso("Non sono riuscita a leggere \(url.lastPathComponent).")
                    return
                }
                self.smontaggio.carica(righe: righe, titolo: url.deletingPathExtension().lastPathComponent,
                                       origine: url.lastPathComponent, clienteId: cliente)
            }
        }
    }

    /// Le righe arrivate dall'iPhone mentre la vista attiva è lo Smontaggio: le legge MotoreSmontaggio, non Inquadra.
    func prendiInquadraturaSmontaggio(_ x: InquadraturaPonte) {
        smontaggio.carica(righe: x.righe, titolo: x.righe.first(where: { MotoreSmontaggio.tipo($0.testo) == nil && $0.testo.count > 3 })?.testo ?? "Documento inquadrato",
                          origine: "inquadrato con \(x.dispositivo)", clienteId: x.clienteId ?? clienteAttivoId)
    }
}

extension Posizione {
    /// Il costo annuo in % della posizione (gestione, se indicato), per scegliere la proposta meno costosa.
    var costoAnnuoPercento: Double? { costoAnnuo }
}
