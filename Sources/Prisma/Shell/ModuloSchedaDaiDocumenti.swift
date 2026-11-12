import SwiftUI
import UniformTypeIdentifiers

/// Una richiesta di aprire «La scheda dai documenti» (per `.sheet(item:)`): nuova scheda o aggiornamento.
struct RichiestaSchedaDocumenti: Identifiable {
    let id = UUID()
    var esistente: Prodotto?
}

/// «La scheda dai documenti» (12 novembre 2026): si scelgono i documenti del prodotto (KID, DIP, DIP aggiuntivo,
/// condizioni, scheda costi; PDF anche scansionati, o foto), Prisma li legge sul Mac (LetturaDocumenti: PDFKit e
/// Vision) e trova costi, trattenute, tassazione, rischio e scenari del KID (LettoreProdotto). Ogni dato mostra il
/// documento e la pagina, con la riga al passaggio del puntatore; dove due documenti non dicono la stessa cosa si
/// sceglie quale tenere. Entrano nella scheda solo le voci spuntate. Nuova scheda o aggiornamento di una scheda.
/// I documenti non escono dal Mac.
struct ModuloSchedaDaiDocumenti: View {
    @Environment(\.dismiss) private var chiudi
    @Environment(StatoShell.self) private var stato
    /// La scheda da aggiornare (nil: scheda nuova).
    let esistente: Prodotto?

    private enum Fase: Equatable { case scelta, lettura(Int, Int), revisione }

    @State private var fase = Fase.scelta
    @State private var lettura = LettoreProdotto.Lettura()
    @State private var scelte: Set<LettoreProdotto.Voce> = []
    @State private var canale: Canale = .alleanza
    @State private var area: AreaPosizione = .investimento
    @State private var sceltaFile = false
    @State private var errore: String?
    @State private var avviato = false

    private typealias M = Tema.Misura.ProdottoCliente
    private typealias C = Tema.Colore.ProdottoCliente

    /// `letti`: documenti già letti (le istantanee partono dalla revisione, senza scegliere file).
    init(esistente: Prodotto?, letti: [LettoreProdotto.DocumentoDaLeggere] = []) {
        self.esistente = esistente
        guard !letti.isEmpty else { return }
        var l = LettoreProdotto.leggi(letti)
        l.documentiLetti = letti
        _lettura = State(initialValue: l)
        _scelte = State(initialValue: Set(l.trovate.filter { !(l.dato($0)?.daScegliere ?? false) }))
        _area = State(initialValue: l.riconoscimento?.area ?? .investimento)
        _fase = State(initialValue: .revisione)
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        CorniceModulo(titolo: esistente.map { "Aggiorna «\($0.nome)» dai documenti" } ?? "Nuova scheda dai documenti") {
            VStack(alignment: .leading, spacing: 18) {
                switch fase {
                case .scelta: sceltaDocumenti
                case .lettura(let fatti, let totale): inLettura(fatti, totale)
                case .revisione: revisione
                }
            }
        } piede: {
            if fase == .revisione {
                Button { fase = .scelta } label: { Label("Altri documenti", systemImage: "doc.badge.plus") }
                    .buttonStyle(StileVetro())
            }
            Spacer()
            if fase == .revisione {
                Text("\(scelte.count) dati da mettere nella scheda")
                    .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
            }
            Button("Annulla") { chiudi() }
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button(esistente == nil ? "Crea la scheda" : "Aggiorna la scheda") { salva() }
                .buttonStyle(StileBlu())
                .disabled(!pronto)
                .opacity(pronto ? 1 : 0.5)
                .keyboardShortcut(.defaultAction)
        }
        .frame(width: M.modulo.width, height: M.modulo.height)
        .onAppear {
            guard !avviato else { return }
            avviato = true
            if let e = esistente { canale = e.canale; area = e.area } else {
                canale = stato.filtroCanaleProdotti ?? .alleanza
            }
        }
        #if os(iOS)
        .fileImporter(isPresented: $sceltaFile, allowedContentTypes: Self.tipiAccettati, allowsMultipleSelection: true) { esito in
            if case .success(let urls) = esito { leggi(urls) }
        }
        #endif
    }

    private var pronto: Bool { fase == .revisione && !scelte.isEmpty && !stato.solaLettura }

    static let tipiAccettati: [UTType] = [.pdf, .png, .jpeg, .tiff, .heic]

    // MARK: - I documenti

    private var sceltaDocumenti: some View {
        VStack(alignment: .leading, spacing: 12) {
            OcchielloSezione(titolo: "I documenti del prodotto")
            Text("Scegli insieme KID, DIP o DIP aggiuntivo, condizioni di contratto o di assicurazione e scheda costi. Prisma li legge sul Mac e trova costi, trattenute, tassazione, rischio e scenari del KID: ogni dato con il documento e la pagina, da confermare.")
                .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
                .fixedSize(horizontal: false, vertical: true)
            Button { apriFile() } label: { Label("Scegli i documenti…", systemImage: "doc.text.magnifyingglass") }
                .buttonStyle(StileBlu())
            if let errore {
                Text(errore).font(Tipo.campoEtichetta).foregroundColor(C.avviso)
            }
            if !lettura.documenti.isEmpty {
                Text("Letti finora: " + lettura.documenti.map { "\($0.nome) (\($0.tipo.nome))" }.joined(separator: ", "))
                    .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { fornitori in
            raccogli(fornitori)
            return true
        }
    }

    private func inLettura(_ fatti: Int, _ totale: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            OcchielloSezione(titolo: "Lettura")
            ProgressView(value: Double(fatti), total: Double(max(totale, 1)))
            Text("Leggo il documento \(min(fatti + 1, totale)) di \(totale)…")
                .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
        }
    }

    private func apriFile() {
        #if os(macOS)
        let p = NSOpenPanel()
        p.allowedContentTypes = Self.tipiAccettati
        p.allowsMultipleSelection = true
        p.prompt = "Leggi"
        p.message = "Scegli i documenti del prodotto (KID, DIP, condizioni, scheda costi): restano sul Mac."
        if p.runModal() == .OK { leggi(p.urls) }
        #else
        sceltaFile = true
        #endif
    }

    private func raccogli(_ fornitori: [NSItemProvider]) {
        var urls: [URL] = []
        let gruppo = DispatchGroup()
        let coda = DispatchQueue(label: "prisma.scheda-documenti")
        for f in fornitori {
            gruppo.enter()
            _ = f.loadObject(ofClass: URL.self) { url, _ in
                coda.async {
                    if let url { urls.append(url) }
                    gruppo.leave()
                }
            }
        }
        gruppo.notify(queue: .main) { if !urls.isEmpty { leggi(urls) } }
    }

    /// Legge i documenti fuori dal thread principale (PDF e Vision), poi unisce con quelli già letti.
    private func leggi(_ urls: [URL]) {
        let validi = urls.filter { LetturaDocumenti.estensioniAccettate.contains($0.pathExtension.lowercased()) }
        guard !validi.isEmpty else {
            errore = "Questi file non si leggono: servono PDF o immagini."
            return
        }
        errore = nil
        let giaLetti = lettura.documentiLetti
        fase = .lettura(0, validi.count)
        DispatchQueue.global(qos: .userInitiated).async {
            var documenti = giaLetti
            for (i, url) in validi.enumerated() {
                let accesso = url.startAccessingSecurityScopedResource()
                defer { if accesso { url.stopAccessingSecurityScopedResource() } }
                if let esito = LetturaDocumenti.leggi(url) {
                    documenti.append(.init(nome: url.lastPathComponent, pagine: esito.pagine))
                }
                DispatchQueue.main.async { fase = .lettura(i + 1, validi.count) }
            }
            var nuova = LettoreProdotto.leggi(documenti)
            nuova.documentiLetti = documenti
            DispatchQueue.main.async {
                lettura = nuova
                // Spuntate all'inizio tutte le voci trovate senza dubbi; quelle con valori diversi si guardano prima
                scelte = Set(nuova.trovate.filter { !(nuova.dato($0)?.daScegliere ?? false) })
                if esistente == nil, let r = nuova.riconoscimento { area = r.area }
                fase = documenti.isEmpty ? .scelta : .revisione
                if documenti.isEmpty { errore = "Non sono riuscito a leggere i documenti." }
            }
        }
    }

    // MARK: - La revisione

    private var revisione: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                OcchielloSezione(titolo: "La scheda")
                if esistente == nil {
                    CampoModulo(etichetta: "Canale") {
                        Picker("", selection: $canale) {
                            ForEach(Canale.allCases) { Text($0.nomeBreve).tag($0) }
                        }
                        .labelsHidden().pickerStyle(.segmented).fixedSize()
                    }
                    CampoModulo(etichetta: "Area") {
                        MenuTendina(selezione: $area, opzioni: AreaPosizione.allCases.map { ($0, $0.nome) }, larghezza: 220)
                    }
                }
                if let r = lettura.riconoscimento {
                    Text("Dai documenti: \(r.tipologia).").font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
                }
                Text("Documenti: " + lettura.documenti.map { "\($0.nome) (\($0.tipo.nome))" }.joined(separator: ", "))
                    .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
                    .fixedSize(horizontal: false, vertical: true)
                if !lettura.mancantiKID.isEmpty {
                    Text("Non trovati: " + lettura.mancantiKID.map(\.etichetta).joined(separator: ", ") + ". Si scrivono a mano nella scheda.")
                        .font(Tipo.campoEtichetta).foregroundColor(C.avviso)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            gruppo("Il prodotto", [.nome, .emittente, .tipologia, .isin, .dataDocumento, .sri, .periodoRaccomandato, .esempioKID])
            gruppo("I costi (KID)", [.costoIngresso, .costoUscita, .costoGestione, .costiTransazione, .commissioniPerformance,
                                    .incidenzaUnAnno, .incidenzaPeriodo])
            gruppo("Gli scenari del KID (rendimento medio annuo)", LettoreProdotto.Voce.scenari + [.rendimentoPrimaCosti])
            gruppo("Il contratto", [.trattenuto, .minimoGarantito, .caricamento, .costoFisso, .penali, .bloccoRiscatto])
            gruppo("La fiscalità", [.aliquota, .quotaTitoliStato, .impostaPremi])
            Text("Il rendimento atteso della scheda è lordo: Prisma lo ricava dallo scenario moderato con i costi del KID (lo scenario è al netto dei costi). Con gli scenari del KID le simulazioni usano lo sfavorevole e il favorevole del KID invece dei ±2 punti.")
                .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private func gruppo(_ titolo: String, _ voci: [LettoreProdotto.Voce]) -> some View {
        let trovate = voci.filter { lettura.dato($0) != nil }
        if !trovate.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                OcchielloSezione(titolo: titolo)
                ForEach(trovate) { v in riga(v) }
            }
        }
    }

    @ViewBuilder private func riga(_ v: LettoreProdotto.Voce) -> some View {
        if let d = lettura.dato(v) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Toggle("", isOn: Binding(get: { scelte.contains(v) }, set: { if $0 { scelte.insert(v) } else { scelte.remove(v) } }))
                    .stileCasella()
                    .labelsHidden()
                Text(v.etichetta).font(Tipo.campoEtichetta).foregroundColor(Tema.Colore.inchiostroSecondario)
                    .frame(width: Tema.Misura.PannelliShell.etichettaModulo, alignment: .leading)
                if d.daScegliere {
                    MenuTendina(selezione: Binding(get: { 0 }, set: { scegliAlternativa(v, $0) }),
                                opzioni: ([d] + d.alternative).enumerated().map { ($0.offset, "\($0.element.testo) · \($0.element.tipo.nome)") },
                                larghezza: M.tendinaCliente)
                } else {
                    Text(d.testo).font(Tipo.campoValore).foregroundColor(Tema.Colore.inchiostro)
                        .lineLimit(2)
                }
                Spacer(minLength: 6)
                Text("\(d.tipo.nome) p. \(d.pagina)")
                    .font(Tipo.campoEtichetta).foregroundColor(C.testoSecondario)
                    .help("«\(d.estratto)» — \(d.documento), pagina \(d.pagina)")
            }
        }
    }

    /// Sceglie un'alternativa: diventa il valore della voce, quello di prima passa fra le alternative.
    private func scegliAlternativa(_ v: LettoreProdotto.Voce, _ indice: Int) {
        guard indice > 0, var d = lettura.dati[v], indice - 1 < d.alternative.count else { return }
        var nuovo = d.alternative.remove(at: indice - 1)
        d.alternative = []
        nuovo.alternative = [d] + lettura.dati[v]!.alternative.enumerated().filter { $0.offset != indice - 1 }.map(\.element)
        lettura.dati[v] = nuovo
        scelte.insert(v)
    }

    private func salva() {
        guard pronto else { return }
        if var p = esistente {
            LettoreProdotto.applica(lettura, scelte: scelte, a: &p)
            stato.salvaProdotto(p)
            stato.mostraAvviso("Scheda «\(p.nome)» aggiornata con \(scelte.count) dati dei documenti.")
        } else {
            let p = LettoreProdotto.prodotto(da: lettura, scelte: scelte, canale: canale, area: area)
            stato.salvaProdotto(p)
            stato.mostraAvviso("Scheda «\(p.nome)» creata dai documenti: \(scelte.count) dati confermati.")
        }
        chiudi()
    }
}
