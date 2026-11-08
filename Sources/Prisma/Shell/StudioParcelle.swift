import SwiftUI
import UniformTypeIdentifiers

// Studio › Parcelle e fatture (Design/template-novita-specifica.md §3, template `studioHTML()` ramo fatture):
//
//   ┌─ Incassato nel 2026 ─┬─ Da incassare ─┐  ┌──────────── tavolo `chip` ────────────┬──────────────────┐
//   │  21.300 €            │  1.650 €       │  │          ┌──────────────┐             │ Prepara il file  │
//   ├─ ◉ Andrea Conti            450 € ────┤  │          │   fattura    │             │ Salva PDF        │
//   │    senza numero · …        Bozza      │  │          │  su carta    │             │ Segna pagata     │
//   ├─ ◉ Laura Moretti           900 € ────┤  │          │   bianca     │             │ Manda con Messaggi│
//   │    2026/015 · …     Da incassare      │  │          └──────────────┘             │ nota · stato XML │
//   └─ ＋ Nuova parcella ───────────────────┘  └───────────────────────────────────────┴──────────────────┘
//
// - Barra laterale larga 440 (si stringe fino a 300): due tile con i numeri che si contano (incassato nell'anno, da
//   incassare in arancio), l'elenco delle parcelle (bozze prima, poi dalla più recente), «＋ Nuova parcella».
// - Anteprima: la fattura vera su carta bianca (FatturaCarta, le stesse pagine del PDF), centrata a sinistra della
//   colonna delle azioni. Cambia fattura con `.cambioFattura` (esce in basso in 0,16 s, entra dall'alto in 0,48 s).
// - «Prepara il file XML» è spento finché mancano dati: una tile arancio dice che cosa manca e porta a Impostazioni ›
//   Studio o al dossier del cliente. Prisma prepara SOLO il file (nessun invio al Sistema di Interscambio).
// - Nessun regime, aliquota, contributo, ritenuta o bollo predefinito: le voci fiscali vengono da MotoreFattura con i
//   dati del consulente; senza, il foglio dice «secondo il regime impostato · da completare» e il totale è provvisorio.
// - «Riduci movimento»: niente cascata, numeri fermi, il foglio cambia con una dissolvenza di 0,15 s; istantanee:
//   tutto nello stato finale.
// Valori in DesignSystem/Apple/Tema.Apple+Parcelle.swift.

// MARK: - Istantanee

/// Che cosa una scena delle istantanee chiede alla scheda (Prisma --istantanee): la parcella scelta, il file XML già
/// pronto, il modulo della nuova parcella aperto. Vale solo per lo stato della scena (riferimento debole).
final class RichiestaIstantaneaParcelle {
    nonisolated(unsafe) private static var attuale: RichiestaIstantaneaParcelle?

    private weak var stato: StatoShell?
    let parcellaId: String?
    /// Il nome del file XML già preparato per la parcella scelta.
    let fileXML: String?
    /// La bozza mostrata nel modulo «Nuova parcella», sopra la scheda.
    let modulo: Parcella?

    private init(stato: StatoShell, parcellaId: String?, fileXML: String?, modulo: Parcella?) {
        self.stato = stato
        self.parcellaId = parcellaId
        self.fileXML = fileXML
        self.modulo = modulo
    }

    static func chiedi(_ s: StatoShell, parcella: String?, fileXML: String? = nil, modulo: Parcella? = nil) {
        attuale = RichiestaIstantaneaParcelle(stato: s, parcellaId: parcella, fileXML: fileXML, modulo: modulo)
    }

    static func per(_ s: StatoShell) -> RichiestaIstantaneaParcelle? {
        guard let r = attuale, r.stato === s else { return nil }
        return r
    }
}

// MARK: - Testi

enum TestiParcelle {
    static let nuova = "＋ Nuova parcella"
    static let vuotoElenco = "Ancora nessuna parcella. Le parcelle sono della consulenza indipendente: preparane una "
        + "con «Nuova parcella»."
    static let vuotoAnteprima = "Qui vedrai la fattura su carta"
    static let notaXML = "Il file XML della fattura elettronica lo carichi tu sul portale dell’Agenzia delle Entrate, "
        + "o lo dai al commercialista. Prisma non lo invia."
    static let daIncassare = "Da incassare"
    static let provvisorio = "importi provvisori: manca il regime"
    static let xmlPronto = "✓ File XML pronto"
    static let completaImpostazioni = "Completa in Impostazioni › Studio"
    static let completaDossier = "Completa il dossier"
    /// L'ancora di Impostazioni › Studio › Dati per le fatture (SezioneDatiFatture).
    static let ancoraImpostazioni = "impostazioni-fatture"
    /// «Manda con Messaggi» su una bozza (senza numero la fattura non si manda) o su un cliente che non c'è più.
    static let messaggiNonPronto = "Emetti prima la parcella: Messaggi manda la fattura con il suo numero."
    static let aiutoMessaggi = "Apre Messaggi sul cliente con il testo pronto e la fattura PDF da allegare: la spedisci tu"

    static func incassato(_ anno: Int) -> String { "Incassato nel \(String(anno))" }

    /// «2026/015 · Piano previdenziale», «senza numero · Primo check-up».
    static func sottoVoce(_ p: Parcella) -> String {
        let numero = p.numero ?? "senza numero"
        let descrizione = descrizione(p)
        return descrizione.isEmpty ? numero : "\(numero) · \(descrizione)"
    }

    /// La descrizione della parcella, o quella della prima riga.
    static func descrizione(_ p: Parcella) -> String {
        let d = p.descrizione.trimmingCharacters(in: .whitespacesAndNewlines)
        if !d.isEmpty { return d }
        return p.righe.first?.descrizione.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// «Bozza», «Da incassare», «Scaduta», «Pagata», «Annullata».
    static func stato(_ p: Parcella, scaduta: Bool) -> String {
        p.stato == .emessa && scaduta ? "Scaduta" : p.stato.nome
    }

    /// «partita IVA, regime fiscale (codice RF) e altri 4»: al più cinque voci.
    static func elenco(_ m: [DatoMancante], massimo: Int = 5) -> String {
        var visti = Set<String>()
        let testi = m.map(\.testo).filter { visti.insert($0).inserted }
        guard testi.count > massimo else { return testi.joined(separator: ", ") }
        let resto = testi.count - massimo
        return testi.prefix(massimo).joined(separator: ", ") + (resto == 1 ? " e un altro dato" : " e altri \(resto) dati")
    }

    /// «Per il file XML mancano: …» / «manca: …».
    static func mancano(_ m: [DatoMancante], di: String? = nil) -> String {
        let soggetto = di.map { "Per il file XML di \($0)" } ?? "Per il file XML"
        return soggetto + (m.count == 1 ? " manca: " : " mancano: ") + elenco(m)
    }
}

// MARK: - Testi della fattura dallo stato

extension StatoShell {
    /// I testi della fattura su carta di una parcella, con ciò che manca per il file XML.
    func testiFattura(_ p: Parcella) -> TestiFattura {
        let c = dati.clienti.first { $0.id == p.clienteId }
        let mancanti = MotoreFattura.mancanti(parcella: p, cliente: c, consulente: datiFatturazione)
        return TestiFattura(parcella: p, cliente: c, consulente: datiFatturazione, mancanti: mancanti,
                            prova: c.map { Self.clientiDiProva.contains($0.id) } ?? false)
    }
}

// MARK: - La scheda

/// Lo stato del file XML nella colonna delle azioni: preparato per una parcella (con l'indirizzo dove è stato salvato).
private struct FileXMLPronto: Equatable {
    let parcellaId: String
    let nome: String
    let url: URL?
}

/// Il modulo aperto: la bozza da scrivere (nuova o da modificare).
private struct ModuloParcellaAperto: Identifiable {
    let id = UUID().uuidString
    let parcella: Parcella
    let nuova: Bool
}

struct ParcelleStudioVista: View {
    @Environment(StatoShell.self) var stato
    /// La base della cascata (0,14 all'apertura, 0 dopo un cambio di scheda).
    let base: Double

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var scelta: String?
    @State private var fileXML: FileXMLPronto?
    @State private var modulo: ModuloParcellaAperto?
    @State private var daAnnullare: String?
    @State private var daEmettere: String?

    private typealias D = Tema.Apple.Parcelle.Disposizione

    init(base: Double) {
        self.base = base
    }

    /// Bozze prima (dalla più recente), poi le numerate dalla più recente (anno e numero decrescenti).
    static func ordinate(_ parcelle: [Parcella]) -> [Parcella] {
        parcelle.sorted { a, b in
            if (a.stato == .bozza) != (b.stato == .bozza) { return a.stato == .bozza }
            if a.stato == .bozza { return (a.data, a.id) > (b.data, b.id) }
            return (a.anno, a.progressivo ?? 0, a.id) > (b.anno, b.progressivo ?? 0, b.id)
        }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let elenco = Self.ordinate(stato.parcelle)
        let richiesta = RichiestaIstantaneaParcelle.per(stato)
        let idScelto = scelta ?? richiesta?.parcellaId
        let p = idScelto.flatMap { id in elenco.first { $0.id == id } } ?? elenco.first
        let totali = stato.totaliParcelle()
        let xml: FileXMLPronto? = fileXML ?? richiesta?.fileXML.flatMap { nome in
            p.map { FileXMLPronto(parcellaId: $0.id, nome: nome, url: nil) }
        }
        return GeometryReader { geo in
            let laterale = min(D.larghezzaLaterale, max(D.larghezzaLateraleMinima, geo.size.width * D.quotaLaterale))
            HStack(alignment: .top, spacing: D.spazio) {
                barra(elenco, scelta: p?.id, totali: totali)
                    .frame(width: laterale)
                    .frame(maxHeight: .infinity, alignment: .top)
                anteprima(p, xml: xml)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .entrataCascata(min(elenco.count, 8), base: base)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .overlay {
            // Nelle istantanee il foglio del modulo non si disegna: il modulo sta sopra la scheda, con il velo
            if istantanea, let bozza = richiesta?.modulo {
                ZStack {
                    Tema.Apple.Parcelle.Modulo.velo
                    ModuloParcella(parcella: bozza, nuova: true, salva: { _, _ in }, chiudi: {})
                }
            }
        }
        .sheet(item: $modulo) { m in
            ModuloParcella(parcella: m.parcella, nuova: m.nuova, salva: { bozza, emetti in
                salva(bozza, emetti: emetti)
            }, chiudi: { modulo = nil })
            .environment(stato)
        }
        .alert("Annullare la fattura?", isPresented: presente($daAnnullare)) {
            Button("Annulla la fattura", role: .destructive) {
                if let id = daAnnullare { stato.annullaParcella(id) }
                daAnnullare = nil
            }
            Button("Lascia com’è", role: .cancel) { daAnnullare = nil }
        } message: {
            Text("Il numero resta e la fattura non conta più nei totali. Per correggerla fai una nota di credito con il tuo commercialista.")
        }
        .alert("Emettere la parcella?", isPresented: presente($daEmettere)) {
            Button("Emetti") {
                if let id = daEmettere, let b = stato.parcella(id) { emetti(b) }
                daEmettere = nil
            }
            Button("Non ora", role: .cancel) { daEmettere = nil }
        } message: {
            Text(testoEmissione(daEmettere))
        }
    }

    /// Un `Binding<Bool>` acceso finché l'id non è nil.
    private func presente(_ id: Binding<String?>) -> Binding<Bool> {
        Binding(get: { id.wrappedValue != nil }, set: { acceso in if !acceso { id.wrappedValue = nil } })
    }

    // MARK: Barra laterale

    private func barra(_ elenco: [Parcella], scelta: String?, totali: TotaliParcelle) -> some View {
        let forma = RoundedRectangle(cornerRadius: D.raggioLaterale, style: .continuous)
        let T = Tema.Apple.Parcelle.Totali.self
        let prova = stato.haDatiDiProva && !elenco.isEmpty
        let oggi = Date()
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: T.spazio) {
                TileTotaleParcelle(etichetta: TestiParcelle.incassato(totali.anno), valore: totali.incassato,
                                   colore: T.coloreValore, indice: 0, prova: prova,
                                   nota: totali.senzaVoci > 0 ? TestiParcelle.provvisorio : nil)
                TileTotaleParcelle(etichetta: TestiParcelle.daIncassare, valore: totali.daIncassareInTutto,
                                   colore: totali.daIncassareInTutto > 0 ? T.coloreDaIncassare : T.coloreValore,
                                   indice: 1, prova: prova,
                                   nota: totali.scadute > 0 ? (totali.scadute == 1 ? "1 scaduta" : "\(totali.scadute) scadute") : nil)
            }
            .padding(.bottom, T.sotto)
            if elenco.isEmpty {
                Text(TestiParcelle.vuotoElenco)
                    .carattereApple(Tema.Apple.Parcelle.vuoto)
                    .foregroundColor(Tema.Apple.Parcelle.coloreVuoto)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Tema.Apple.Parcelle.rientroVuoto)
                    .entrataCascata(0, base: base)
                Spacer(minLength: 0)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Tema.Apple.Parcelle.Voce.fraVoci) {
                        ForEach(Array(elenco.enumerated()), id: \.element.id) { i, p in
                            VoceParcellaApple(parcella: p, cliente: stato.cliente(p.clienteId), scelta: p.id == scelta,
                                              scaduta: MotoreParcelle.scaduta(p, oggi: oggi)) {
                                scegli(p.id)
                            }
                            .contextMenu { menu(p) }
                            .entrataCascata(min(i, 8), base: base, sfocatura: false)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            Button { apriNuova() } label: {
                Text(TestiParcelle.nuova)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.applePrimarioGrande)
            .disabled(stato.solaLettura || stato.clienti.isEmpty)
            .help("Una parcella della consulenza indipendente: il cliente, la consulenza e l’importo")
            .padding(.top, Tema.Apple.Parcelle.nuovaSopra)
        }
        .padding(D.paddingLaterale)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(forma)
        .superficieApple(D.superficieLaterale, raggio: D.raggioLaterale)
    }

    @ViewBuilder private func menu(_ p: Parcella) -> some View {
        switch p.stato {
        case .bozza:
            Button("Modifica la bozza…") { modulo = ModuloParcellaAperto(parcella: p, nuova: false) }
            Button("Emetti…") { daEmettere = p.id }
            Button("Elimina la bozza", role: .destructive) { stato.eliminaBozzaParcella(p.id) }
        case .emessa:
            Button("Segna come pagata oggi") { segnaPagata(p) }
            Button("Annulla la fattura…") { daAnnullare = p.id }
        case .pagata:
            Button("Segna da incassare") { stato.annullaIncassoParcella(p.id) }
            Button("Annulla la fattura…") { daAnnullare = p.id }
        case .annullata:
            EmptyView()
        }
        Button("Duplica come bozza") { duplica(p) }
        Divider()
        Button("Apri il dossier del cliente") { stato.apriCliente(p.clienteId) }
    }

    // MARK: Anteprima

    private func anteprima(_ p: Parcella?, xml: FileXMLPronto?) -> some View {
        let a = Tema.Apple.Parcelle.Anteprima.self
        let z = Tema.Apple.Parcelle.Azioni.self
        let forma = RoundedRectangle(cornerRadius: a.raggio, style: .continuous)
        return GeometryReader { geo in
            let spazioFoglio = max(1, geo.size.width - z.larghezza - z.margine * 2)
            ZStack(alignment: .topLeading) {
                if let p {
                    let testi = stato.testiFattura(p)
                    FoglioFatturaAnteprima(testi: testi, scala: Self.scala(larghezza: spazioFoglio, altezza: geo.size.height))
                        .equatable()
                        .frame(width: spazioFoglio, alignment: .top)
                        .padding(.top, a.margineAlto)
                        .id(p.id)
                        .transition(.cambioFattura(calmo: calmo))
                    azioni(p, testi: testi, xml: xml?.parcellaId == p.id ? xml : nil)
                        .frame(width: z.larghezza, alignment: .topLeading)
                        .padding(.top, z.margine)
                        .padding(.trailing, z.margine)
                        .frame(width: geo.size.width, alignment: .topTrailing)
                } else {
                    Text(TestiParcelle.vuotoAnteprima)
                        .carattereApple(a.vuoto)
                        .foregroundColor(a.coloreVuoto)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .background { forma.fill(a.fondo) }
        // Il foglio che entra o esce non va fuori dal tavolo
        .clipShape(forma)
    }

    /// La scala del foglio: quella del template (0,66) se c'è posto, altrimenti quanto entra.
    static func scala(larghezza: CGFloat, altezza: CGFloat) -> CGFloat {
        let a = Tema.Apple.Parcelle.Anteprima.self
        let f = Tema.Apple.CartaFattura.Misura.formato
        let adatta = min((larghezza - a.margineLati * 2) / f.width, (altezza - a.margineAlto - a.margineBasso) / f.height)
        return min(a.scalaMassima, max(a.scalaMinima, adatta))
    }

    // MARK: Azioni

    private func azioni(_ p: Parcella, testi: TestiFattura, xml: FileXMLPronto?) -> some View {
        let z = Tema.Apple.Parcelle.Azioni.self
        let cliente = stato.cliente(p.clienteId)
        let mancanti = MotoreFattura.mancanti(parcella: p, cliente: cliente, consulente: stato.datiFatturazione)
        return VStack(alignment: .leading, spacing: z.spazio) {
            Button { preparaXML(p) } label: {
                Text("Prepara il file XML").frame(maxWidth: .infinity)
            }
            .buttonStyle(.applePrimarioGrande)
            .disabled(!mancanti.isEmpty || stato.solaLettura)
            .help(mancanti.isEmpty ? "Scrive il file del tracciato FatturaPA e ti chiede dove salvarlo"
                                   : TestiParcelle.mancano(mancanti))
            Button { salvaPDF(p, testi: testi) } label: {
                Text("Salva PDF").frame(maxWidth: .infinity)
            }
            .buttonStyle(.appleGrande)
            switch p.stato {
            case .bozza:
                Button { daEmettere = p.id } label: {
                    Text("Emetti").frame(maxWidth: .infinity)
                }
                .buttonStyle(.appleGrande)
                .disabled(stato.solaLettura || !MotoreFattura.mancantiParcella(p).allSatisfy { $0.codice == "parcella.numero" })
                Button { modulo = ModuloParcellaAperto(parcella: p, nuova: false) } label: {
                    Text("Modifica la bozza").frame(maxWidth: .infinity)
                }
                .buttonStyle(.appleGrande)
                .disabled(stato.solaLettura)
            case .emessa:
                Button { segnaPagata(p) } label: {
                    Text("Segna pagata").frame(maxWidth: .infinity)
                }
                .buttonStyle(.appleGrande)
                .disabled(stato.solaLettura)
                .help("Segna l’incasso con la data di oggi")
            case .pagata, .annullata:
                EmptyView()
            }
            Button { mandaConMessaggi(p, testi: testi) } label: {
                Text("Manda con Messaggi").frame(maxWidth: .infinity)
            }
            .buttonStyle(.appleGrande)
            .disabled(p.stato == .annullata || p.stato == .bozza)
            .help(p.stato == .bozza ? TestiParcelle.messaggiNonPronto : TestiParcelle.aiutoMessaggi)
            if p.stato == .pagata, let il = p.incassataIl {
                Text("Pagata il " + TestiFattura.data(il))
                    .carattereApple(z.incasso)
                    .foregroundColor(z.coloreIncasso)
                    .padding(.top, z.notaSopra)
            }
            Text(TestiParcelle.notaXML)
                .carattereApple(z.nota)
                .foregroundColor(z.coloreNota)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, z.notaSopra)
            statoFile(p, cliente: cliente, mancanti: mancanti, xml: xml)
        }
    }

    @ViewBuilder private func statoFile(_ p: Parcella, cliente: Cliente?, mancanti: [DatoMancante], xml: FileXMLPronto?) -> some View {
        let z = Tema.Apple.Parcelle.Azioni.self
        if let xml {
            TileStatoFattura(bordo: z.bordoPronto) {
                Text(TestiParcelle.xmlPronto)
                    .carattereApple(z.pronto)
                    .foregroundColor(z.colorePronto)
                Text(xml.nome + " · formato fattura elettronica")
                    .carattereApple(z.dettaglio)
                    .foregroundColor(z.coloreDettaglio)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, z.sottoTitolo)
                #if os(macOS)
                if let url = xml.url {
                    Button("Mostra nel Finder") { FileFattura.mostra(url) }
                        .buttonStyle(.appleSobrio)
                        .padding(.top, z.collegamentoSopra)
                }
                #endif
            }
            .padding(.top, z.statoSopra - z.spazio)
            .transition(transizionePronto)
        } else if !mancanti.isEmpty {
            let consulente = mancanti.filter { $0.dove == .consulente }
            let delCliente = mancanti.filter { $0.dove == .cliente }
            let parcella = mancanti.filter { $0.dove == .parcella }
            VStack(alignment: .leading, spacing: z.spazio) {
                if !consulente.isEmpty {
                    tileMancano(TestiParcelle.mancano(consulente), collegamento: TestiParcelle.completaImpostazioni) {
                        stato.apriImpostazioniFatture()
                    }
                }
                if !delCliente.isEmpty {
                    tileMancano(TestiParcelle.mancano(delCliente, di: cliente?.nome ?? "questo cliente"),
                                collegamento: cliente == nil ? nil : TestiParcelle.completaDossier) {
                        apriDossier(p.clienteId)
                    }
                }
                if !parcella.isEmpty {
                    tileMancano(TestiParcelle.mancano(parcella, di: "questa parcella"), collegamento: nil) {}
                }
            }
            .padding(.top, z.statoSopra - z.spazio)
        }
    }

    private func tileMancano(_ testo: String, collegamento: String?, azione: @escaping () -> Void) -> some View {
        let z = Tema.Apple.Parcelle.Azioni.self
        return TileStatoFattura(bordo: z.bordoMancano) {
            Text(testo)
                .carattereApple(z.dettaglio)
                .foregroundColor(z.coloreDettaglio)
                .fixedSize(horizontal: false, vertical: true)
            if let collegamento {
                Button(collegamento, action: azione)
                    .buttonStyle(.appleSobrio)
                    .disabled(stato.inModoCliente)
                    .padding(.top, z.collegamentoSopra)
            }
        }
    }

    private var transizionePronto: AnyTransition {
        if istantanea { return .identity }
        if calmo { return AnyTransition.opacity.animation(Tema.Moto.dissolvenzaCalma) }
        let m = Tema.Apple.Parcelle.Moto.self
        return AnyTransition.scale(scale: m.scalaPronto).combined(with: .opacity).animation(m.animazionePronto)
    }

    // MARK: Fare

    private func scegli(_ id: String) {
        guard id != scelta else { return }
        let animazione = Tema.Apple.Moto.animazione(Tema.Apple.Parcelle.Moto.entrata, calmo: calmo, istantanea: istantanea)
        let cambia = {
            scelta = id
            fileXML = nil
        }
        if let animazione {
            withAnimation(animazione) { cambia() }
        } else {
            cambia()
        }
    }

    private func apriNuova() {
        let clienti = stato.clienti
        guard !stato.solaLettura,
              let cliente = clienti.first(where: { $0.id == stato.clienteAttivoId }) ?? clienti.first else { return }
        let cal = Calendar.current
        let oggi = cal.startOfDay(for: Date())
        var p = Parcella(clienteId: cliente.id, data: oggi, righe: [RigaParcella(descrizione: "", importo: 0)])
        if let g = stato.datiFatturazione.giorniPagamento { p.scadenza = cal.date(byAdding: .day, value: g, to: oggi) }
        modulo = ModuloParcellaAperto(parcella: p, nuova: true)
    }

    private func salva(_ bozza: Parcella, emetti: Bool) {
        stato.salvaParcella(bozza)
        if emetti, let b = stato.parcella(bozza.id) { self.emetti(b) }
        modulo = nil
        scegli(bozza.id)
    }

    private func emetti(_ p: Parcella) {
        guard let e = stato.emettiParcella(p.id, data: p.data) else { return }
        stato.mostraAvviso("Parcella emessa: N. \(e.numero ?? "")")
    }

    private func testoEmissione(_ id: String?) -> String {
        guard let id, let p = stato.parcella(id) else { return "" }
        let numero = MotoreParcelle.prossimoNumero(stato.dati.parcelle, anno: Calendar.current.component(.year, from: p.data),
                                                   numerazione: stato.datiFatturazione.numerazione)
        if MotoreFattura.mancantiRegime(stato.datiFatturazione.regime).isEmpty {
            return "Prende il numero \(numero) e le voci fiscali si fissano con il regime impostato. Dopo non si modifica più."
        }
        return "Il regime fiscale non è completo: la parcella prende il numero \(numero) con l’importo provvisorio, e il file "
            + "XML si prepara quando completi Impostazioni › Studio. Dopo non si modifica più."
    }

    private func segnaPagata(_ p: Parcella) {
        stato.segnaParcellaPagata(p.id)
        stato.mostraAvviso("Segnata pagata oggi")
    }

    private func duplica(_ p: Parcella) {
        guard !stato.solaLettura else { return }
        let oggi = Calendar.current.startOfDay(for: Date())
        let copia = Parcella(clienteId: p.clienteId, data: oggi, descrizione: p.descrizione,
                             righe: p.righe.map { RigaParcella(descrizione: $0.descrizione, importo: $0.importo) },
                             ricorrente: p.ricorrente)
        stato.salvaParcella(copia)
        scegli(copia.id)
    }

    private func apriDossier(_ clienteId: String) {
        stato.clienteAttivoId = clienteId
        stato.schedaCliente = .anagrafica
        stato.apri(.clienti)
    }

    /// Scrive il file XML (se ci sono tutti i dati), chiede dove salvarlo e solo dopo lo registra nella parcella:
    /// il progressivo d'invio si consuma una volta sola e non si ripete.
    private func preparaXML(_ p: Parcella) {
        let f = stato.datiFatturazione
        let progressivo = p.progressivoInvio ?? MotoreParcelle.progressivoInvio(f.numerazione.ultimoProgressivoInvio + 1)
        let esito = GeneratoreFatturaPA.genera(parcella: p, cliente: stato.dati.clienti.first { $0.id == p.clienteId },
                                               consulente: f, progressivoInvio: progressivo)
        guard let file = esito.file else {
            stato.mostraAvviso(TestiParcelle.mancano(esito.mancanti))
            return
        }
        let url: URL?
        // I clienti di prova: «PROVA_…», il file non vale per lo SdI
        let nome = stato.nomeFileFatturaPA(file, clienteId: p.clienteId)
        switch FileFattura.salva(file.dati, nome: nome, tipo: .xml, messaggio: FileFattura.messaggioXML) {
        case .salvato(let indirizzo): url = indirizzo
        case .condiviso: url = nil
        case .annullato: return
        case .errore(let motivo):
            stato.mostraAvviso("Non sono riuscito a salvare il file: \(motivo)")
            return
        }
        _ = stato.preparaFatturaPA(p.id)
        let pronto = FileXMLPronto(parcellaId: p.id, nome: nome, url: url)
        if let a = Tema.Apple.Moto.animazione(Tema.Apple.Parcelle.Moto.animazionePronto, calmo: calmo, istantanea: istantanea) {
            withAnimation(a) { fileXML = pronto }
        } else {
            fileXML = pronto
        }
    }

    private func salvaPDF(_ p: Parcella, testi: TestiFattura) {
        guard let dati = StampaCarta.pdf(DocumentoStampabile(testi)) else {
            stato.mostraAvviso("Non sono riuscito a preparare il PDF della fattura.")
            return
        }
        let nome = FileFattura.nomePDF(testi)
        switch FileFattura.salva(dati, nome: nome, tipo: .pdf, messaggio: FileFattura.messaggioPDF) {
        case .salvato, .condiviso:
            stato.aggiungiDocumentoParcella(p.id, DocumentoParcella(formato: .pdf, nomeFile: nome, creatoIl: Date()))
            stato.mostraAvviso("PDF della fattura salvato, su carta bianca")
        case .annullato:
            break
        case .errore(let motivo):
            stato.mostraAvviso("Non sono riuscito a salvare il file: \(motivo)")
        }
    }

    /// Apre Messaggi sul cliente della fattura con l'occasione della parcella (da mandare o da saldare) e il PDF della
    /// fattura da allegare: una copia va nei Documenti del cliente (non in sola lettura), un'altra col suo nome nella
    /// cartella temporanea per l'allegato. Senza allegati possibili (mailto:) l'avviso di Messaggi dice di allegarlo.
    private func mandaConMessaggi(_ p: Parcella, testi: TestiFattura) {
        guard let o = stato.occasioneParcella(p) else {
            stato.mostraAvviso(TestiParcelle.messaggiNonPronto)
            return
        }
        var allegati: [URL] = []
        let documento = DocumentoStampabile(testi)
        if let dati = StampaCarta.pdf(documento) {
            let nome = FileFattura.nomePDF(testi)
            if !stato.solaLettura, let id = stato.archiviaProspetto(dati, documento: documento, cliente: p.clienteId) {
                stato.aggiungiDocumentoParcella(p.id, DocumentoParcella(formato: .pdf, nomeFile: nome, creatoIl: Date(), documentoId: id))
            }
            // Nelle istantanee e nelle prove nessun file
            if stato.persistente, let url = AllegatiMessaggi.copia(dati, nome: nome) { allegati = [url] }
        }
        stato.preparaMessaggio(occasione: o, allegati: allegati)
    }
}

extension StatoShell {
    /// Apre Impostazioni › Studio sui dati per le fatture.
    func apriImpostazioniFatture() {
        schedaImpostazioni = .studio
        ancoraImpostazioni = TestiParcelle.ancoraImpostazioni
        apri(.impostazioni)
    }
}

// MARK: - Componenti

/// Una tile dei totali: `.k` sopra e il valore display 26 che si conta, con la nota facoltativa sotto.
private struct TileTotaleParcelle: View {
    let etichetta: String
    let valore: Double
    let colore: Color
    let indice: Int
    let prova: Bool
    let nota: String?

    var body: some View {
        let T = Tema.Apple.Parcelle.Totali.self
        VStack(alignment: .leading, spacing: T.spazioValore) {
            Text(etichetta)
                .carattereApple(T.etichetta)
                .foregroundColor(T.coloreEtichetta)
                .lineLimit(1)
            NumeroCheConta(valore, formato: .euro, indice: indice)
                .carattereApple(T.valore)
                .foregroundColor(colore)
                .lineLimit(1)
                .minimumScaleFactor(T.riduzioneValore)
            if let testo = nota ?? (prova ? TestiStudio.datiDiProva : nil) {
                Text(testo)
                    .carattereApple(T.nota)
                    .foregroundColor(T.coloreNota)
                    .lineLimit(1)
                    .minimumScaleFactor(Tema.Apple.Studio.Card.riduzioneTesto)
            }
        }
        .padding(T.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(T.superficie, raggio: T.raggio)
    }
}

/// Una tile dello stato del file XML (pronto, o i dati che mancano), con il bordo colorato.
private struct TileStatoFattura<Contenuto: View>: View {
    let bordo: Color
    @ViewBuilder let contenuto: () -> Contenuto

    var body: some View {
        let z = Tema.Apple.Parcelle.Azioni.self
        let forma = RoundedRectangle(cornerRadius: z.raggioStato, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            contenuto()
        }
        .padding(z.paddingStato)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficieApple(z.superficieStato, raggio: z.raggioStato)
        .overlay { forma.strokeBorder(bordo, lineWidth: z.spessoreBordo).allowsHitTesting(false) }
    }
}

/// Una voce dell'elenco (`.rub`): avatar 34, nome 14 bold e «numero · descrizione» 12; a destra l'importo 13,5 bold e
/// lo stato colorato. Sotto il puntatore `chip`, scelta `selezioneVoce`, il fondo cambia in 0,25 s.
private struct VoceParcellaApple: View {
    let parcella: Parcella
    let cliente: Cliente?
    let scelta: Bool
    let scaduta: Bool
    let azione: () -> Void

    @Environment(\.prismaCalmo) private var calmo
    @Environment(\.modoIstantanea) private var istantanea
    @State private var sopra = false

    private typealias V = Tema.Apple.Parcelle.Voce

    var body: some View {
        let forma = RoundedRectangle(cornerRadius: V.raggio, style: .continuous)
        return Button(action: azione) {
            HStack(spacing: V.spazioAvatar) {
                avatar
                VStack(alignment: .leading, spacing: V.spazioTitoli) {
                    Text(cliente?.nome ?? "Cliente non trovato")
                        .carattereApple(V.nome)
                        .foregroundColor(V.coloreNome)
                    Text(TestiParcelle.sottoVoce(parcella))
                        .carattereApple(V.sotto)
                        .foregroundColor(V.coloreSotto)
                        .truncationMode(.tail)
                }
                .lineLimit(1)
                Spacer(minLength: V.spazioDestra)
                VStack(alignment: .trailing, spacing: V.spazioTitoli) {
                    Text(TestiFattura.importo(MotoreParcelle.importo(parcella)))
                        .carattereApple(V.importo)
                        .foregroundColor(V.coloreImporto)
                    Text(TestiParcelle.stato(parcella, scaduta: scaduta))
                        .carattereApple(V.stato)
                        .foregroundColor(V.colore(parcella.stato, scaduta: scaduta))
                }
                .lineLimit(1)
                .fixedSize()
            }
            .padding(V.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { fondo }
            .contentShape(forma)
        }
        .buttonStyle(StileSemplice())
        .onHover { dentro in sopra = dentro && !istantanea }
        .animation(animazione, value: scelta)
        .animation(animazione, value: sopra)
        .accessibilityAddTraits(scelta ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    @ViewBuilder private var avatar: some View {
        if let c = cliente {
            AvatarCliente(iniziali: c.iniziali, tinta: c.tinta.colori, lato: V.avatar)
                .overlay { Circle().strokeBorder(V.coloreBordoAvatar, lineWidth: V.bordoAvatar).allowsHitTesting(false) }
                .shadow(color: V.ombraAvatar, radius: V.raggioOmbraAvatar, x: 0, y: V.yOmbraAvatar)
        } else {
            Circle()
                .fill(Tema.Apple.Colore.chip)
                .frame(width: V.avatar, height: V.avatar)
        }
    }

    @ViewBuilder private var fondo: some View {
        let forma = RoundedRectangle(cornerRadius: V.raggio, style: .continuous)
        if scelta {
            forma.fill(V.fondoScelta)
        } else if sopra {
            forma.fill(V.fondoSopra)
        }
    }

    private var animazione: Animation? {
        Tema.Apple.Moto.animazione(V.animazioneFondo, calmo: calmo, istantanea: istantanea)
    }
}

/// Il foglio della fattura nell'anteprima: la prima pagina vera (la stessa del PDF), sempre su carta bianca con l'ombra
/// della carta. Si rifà solo quando cambiano i testi o la scala.
private struct FoglioFatturaAnteprima: View, Equatable {
    let testi: TestiFattura
    let scala: CGFloat

    nonisolated static func == (a: FoglioFatturaAnteprima, b: FoglioFatturaAnteprima) -> Bool {
        a.testi == b.testi && a.scala == b.scala
    }

    var body: some View {
        let f = Tema.Apple.CartaFattura.Misura.formato
        let pagina = FatturaCarta.pagine(testi).first ?? AnyView(EmptyView())
        return pagina
            // La carta resta come sulla carta: «Dimensione del testo» non la ingrandisce
            .prismaScalaTesto(1)
            .frame(width: f.width, height: f.height)
            .scaleEffect(scala, anchor: .top)
            .frame(width: f.width * scala, height: f.height * scala, alignment: .top)
            .superficieApple(Tema.Apple.Parcelle.Anteprima.carta)
    }
}
