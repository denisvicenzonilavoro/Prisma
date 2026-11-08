#if os(macOS)
import AppKit
#endif
import SwiftUI
import UniformTypeIdentifiers

// I fogli di Studio › Spese (Design/template-luce-specifica.md §6.3.4, «Luce» giro 9): inquadra lo scontrino (trascina
// la foto o il PDF, o scegli un file: Prisma lo legge in locale con Vision e propone la spesa da confermare), il
// dettaglio di una spesa, una scadenza, i corsi dell'anno con le ore e gli attestati, l'elenco delle visite del mese
// («Dove eri?» e i km che mancano), l'elenco delle spese e la correzione a mano dei km di un giro.
// Vera scrive, l'utente approva: niente entra nell'archivio senza un pulsante premuto dall'utente.

struct FoglioSpese: View {
    let foglio: StatoSpese.Foglio
    @Environment(StatoShell.self) private var stato

    private func chiudi() { stato.studioSpese.foglio = nil }

    var body: some View {
        switch foglio {
        case .inquadra(let url):
            FoglioInquadraScontrino(file: url, chiudi: chiudi)
        case .nuovaSpesa:
            ModuloSpesaStudio(bozza: SpesaStudio(data: Date(), descrizione: "", importo: 0), importo: nil, nuova: true,
                              file: nil, proposta: nil, chiudi: chiudi)
        case .spesa(let id):
            if let s = stato.dati.speseStudio.spese.first(where: { $0.id == id }) {
                ModuloSpesaStudio(bozza: s, importo: s.importo, nuova: false, file: nil, proposta: nil, chiudi: chiudi)
            } else {
                Color.clear.onAppear(perform: chiudi)
            }
        case .nuovaScadenza:
            ModuloScadenzaStudio(bozza: ScadenzaStudio(titolo: "", data: Date()), nuova: true, chiudi: chiudi)
        case .scadenza(let id):
            if let s = stato.dati.speseStudio.scadenze.first(where: { $0.id == id }) {
                ModuloScadenzaStudio(bozza: s, nuova: false, chiudi: chiudi)
            } else {
                Color.clear.onAppear(perform: chiudi)
            }
        case .corsi:
            FoglioCorsiStudio(chiudi: chiudi)
        case .visite:
            FoglioVisiteSpese(chiudi: chiudi)
        case .spese:
            FoglioElencoSpese(chiudi: chiudi)
        case .correzione(let chiave):
            ModuloCorrezioneKm(chiave: chiave, chiudi: chiudi)
        }
    }
}

private typealias M = Tema.Apple.Studio.Spese.Moduli

/// Una riga di testo dei fogli, con il filo sotto.
private struct RigaFoglio<Contenuto: View>: View {
    @ViewBuilder let contenuto: () -> Contenuto

    var body: some View {
        VStack(spacing: 0) {
            contenuto()
                .padding(.vertical, M.paddingRiga)
            Rectangle().fill(M.filo).frame(height: Tema.Apple.Misura.bordo)
        }
    }
}

/// Il titolo di un gruppo nei fogli.
private struct TitoloGruppoFoglio: View {
    let testo: String
    var body: some View {
        Text(testo)
            .carattereApple(M.titoloGruppo)
            .foregroundColor(M.coloreTitoloGruppo)
            .padding(.top, M.spazio)
    }
}

/// Una nota sotto i campi.
private struct NotaFoglio: View {
    let testo: String
    var colore: Color = M.coloreRigaSotto
    var body: some View {
        Text(testo)
            .carattereApple(M.rigaSotto)
            .foregroundColor(colore)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Inquadra lo scontrino

/// Trascina la foto o il PDF dello scontrino (o scegli un file): Prisma legge il testo sul Mac e propone la spesa.
private struct FoglioInquadraScontrino: View {
    let chiudi: () -> Void
    @State private var file: URL?
    @State private var leggendo = false
    @State private var letti: LettoreScontrino.Campi?
    @State private var errore: String?
    @State private var sopra = false

    init(file: URL?, chiudi: @escaping () -> Void) {
        _file = State(initialValue: file)
        self.chiudi = chiudi
    }

    var body: some View {
        if let file, let letti {
            ModuloSpesaStudio(bozza: bozza(letti), importo: letti.totale, nuova: true, file: file, proposta: letti, chiudi: chiudi)
        } else {
            CorniceModulo(titolo: TestiSpese.inquadra) {
                VStack(alignment: .leading, spacing: M.spazio) {
                    zona
                    if let errore {
                        NotaFoglio(testo: errore, colore: M.coloreAvviso)
                    }
                    NotaFoglio(testo: "Prisma legge lo scontrino qui sul Mac e ti propone data, importo ed esercente: "
                               + "controlli e scegli tu la categoria. Niente esce dal Mac.")
                }
            } piede: {
                Spacer()
                Button("Annulla", action: chiudi)
                    .buttonStyle(StileVetro())
                    .keyboardShortcut(.cancelAction)
            }
            .frame(width: M.foglio.width, height: M.foglio.height)
            .onAppear { if let file, letti == nil { leggi(file) } }
        }
    }

    private var zona: some View {
        let forma = RoundedRectangle(cornerRadius: M.raggioZona, style: .continuous)
        return VStack(spacing: M.spazio) {
            if leggendo {
                ProgressView()
                Text("Leggo lo scontrino…")
                    .carattereApple(M.testoZona)
                    .foregroundColor(M.coloreTestoZona)
            } else {
                Image(systemName: "doc.viewfinder")
                    .carattereApple(Tema.Apple.Carattere.titoloGruppo)
                    .foregroundColor(M.coloreTestoZona)
                Text("Trascina qui la foto o il PDF dello scontrino")
                    .carattereApple(M.testoZona)
                    .foregroundColor(M.coloreTestoZona)
                #if os(macOS)
                Button("Scegli un file…", action: scegli)
                    .buttonStyle(.apple)
                #endif
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: M.zona)
        .background(forma.fill(M.fondoZona))
        .overlay(forma.strokeBorder(sopra ? M.bordoZonaAttiva : M.bordoZona,
                                    style: StrokeStyle(lineWidth: M.spessoreZona, dash: M.tratteggioZona)))
        .onDrop(of: [.fileURL], isTargeted: $sopra) { fornitori in
            guard let f = fornitori.first else { return false }
            _ = f.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { accetta(url) }
            }
            return true
        }
    }

    private func accetta(_ url: URL) {
        guard LetturaDocumenti.estensioniAccettate.contains(url.pathExtension.lowercased()) else {
            errore = "Prisma legge foto (JPG, PNG, HEIC, TIFF) e PDF: questo file non lo riconosce."
            return
        }
        file = url
        leggi(url)
    }

    #if os(macOS)
    private func scegli() {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.pdf, .image]
        p.allowsMultipleSelection = false
        p.message = "Scegli la foto o il PDF dello scontrino"
        guard p.runModal() == .OK, let url = p.url else { return }
        accetta(url)
    }
    #endif

    private func leggi(_ url: URL) {
        leggendo = true
        errore = nil
        Task.detached(priority: .userInitiated) {
            let accesso = url.startAccessingSecurityScopedResource()
            defer { if accesso { url.stopAccessingSecurityScopedResource() } }
            let testo = LetturaDocumenti.leggi(url)?.pagine.joined(separator: "\n")
            let campi = testo.map { LettoreScontrino.leggi($0) }
            await MainActor.run {
                leggendo = false
                if let campi {
                    letti = campi
                } else {
                    errore = "Non riesco a leggere questo file. Puoi aggiungere la spesa a mano."
                    file = nil
                }
            }
        }
    }

    private func bozza(_ c: LettoreScontrino.Campi) -> SpesaStudio {
        SpesaStudio(data: c.data ?? Date(), descrizione: c.categoria?.nome ?? "", esercente: c.esercente,
                    importo: c.totale ?? 0, iva: c.iva, categoria: c.categoria ?? .altro, letta: true, daControllare: c.incerto)
    }
}

// MARK: - Una spesa

/// Il modulo di una spesa (nuova, letta da uno scontrino o già salvata): campi modificabili, scontrino, elimina.
struct ModuloSpesaStudio: View {
    @Environment(StatoShell.self) private var stato
    @State private var bozza: SpesaStudio
    @State private var importo: Double?
    @State private var daEliminare = false
    let nuova: Bool
    /// Il file dello scontrino appena inquadrato (si copia solo con «Aggiungi la spesa»).
    let file: URL?
    /// I campi letti dallo scontrino (per dire cosa è stato proposto).
    let proposta: LettoreScontrino.Campi?
    let chiudi: () -> Void

    init(bozza: SpesaStudio, importo: Double?, nuova: Bool, file: URL?, proposta: LettoreScontrino.Campi?, chiudi: @escaping () -> Void) {
        _bozza = State(initialValue: bozza)
        _importo = State(initialValue: importo)
        self.nuova = nuova
        self.file = file
        self.proposta = proposta
        self.chiudi = chiudi
    }

    private var valido: Bool { (importo ?? 0) > 0 && (importo ?? 0) < 1_000_000 }

    var body: some View {
        CorniceModulo(titolo: nuova ? (file == nil ? "Aggiungi una spesa" : "La spesa letta dallo scontrino") : "La spesa") {
            HStack(alignment: .top, spacing: M.spazio) {
                VStack(alignment: .leading, spacing: M.spazioRighe) {
                    if let p = proposta {
                        NotaFoglio(testo: p.incerto
                                   ? "Non ho trovato con certezza \(p.totale == nil ? "l'importo" : "la data"): controlla prima di aggiungerla."
                                   : "Ho letto lo scontrino: controlla i campi e scegli la categoria.",
                                   colore: p.incerto ? M.coloreAvviso : M.coloreRigaSotto)
                    }
                    CampoModulo(etichetta: "Data") {
                        DatePicker("", selection: $bozza.data, displayedComponents: [.date])
                            .labelsHidden()
                            .stileDataCampo()
                            .environment(\.locale, Formati.italiano)
                    }
                    CampoModulo(etichetta: "Descrizione") {
                        TextField("Pranzo, carburante…", text: $bozza.descrizione).textFieldStyle(.roundedBorder)
                    }
                    CampoModulo(etichetta: "Esercente") {
                        TextField("", text: testo(\.esercente)).textFieldStyle(.roundedBorder)
                    }
                    CampoModulo(etichetta: "Importo") {
                        CampoCifraFacoltativa(valore: $importo, unita: "€", larghezza: M.campoImporto)
                    }
                    CampoModulo(etichetta: "IVA indicata") {
                        CampoCifraFacoltativa(valore: $bozza.iva, unita: "€, se stampata", larghezza: M.campoImporto)
                    }
                    CampoModulo(etichetta: "Categoria") {
                        VStack(alignment: .leading, spacing: M.spazioNota) {
                            MenuTendina(selezione: $bozza.categoria, opzioni: CategoriaSpesa.allCases.map { ($0, $0.nome) },
                                        larghezza: M.sceltaPresso)
                            if proposta?.categoria != nil, bozza.categoria == proposta?.categoria {
                                NotaFoglio(testo: "proposta da Prisma: la scegli tu")
                            }
                        }
                    }
                    CampoModulo(etichetta: "Canale") {
                        MenuTendina(selezione: $bozza.canale,
                                    opzioni: [(Canale?.none, "Non indicato")] + Canale.allCases.map { (Optional($0), $0.nomeBreve) },
                                    larghezza: M.sceltaPresso)
                    }
                    CampoModulo(etichetta: "Legata al cliente") {
                        MenuTendina(selezione: $bozza.clienteId,
                                    opzioni: [(String?.none, "Nessuno")] + stato.clienti.map { (Optional($0.id), $0.nome) },
                                    larghezza: M.campoTesto)
                    }
                    CampoModulo(etichetta: "Pagamento") {
                        TextField("Carta, contanti…", text: testo(\.pagamento)).textFieldStyle(.roundedBorder)
                    }
                    CampoModulo(etichetta: "Nota") {
                        TextField("", text: $bozza.nota).textFieldStyle(.roundedBorder)
                    }
                    if bozza.letta {
                        CampoModulo(etichetta: "Controllo") {
                            Toggle("Da controllare", isOn: $bozza.daControllare).stileCasella()
                        }
                    }
                    NotaFoglio(testo: "Prisma riporta solo i fatti: deducibilità e IVA le valuta il tuo commercialista.")
                }
                anteprima
            }
        } piede: {
            if !nuova {
                Button {
                    daEliminare = true
                } label: {
                    Text("Elimina").foregroundColor(Colori.Rubrica.pericolo)
                }
                .buttonStyle(StileVetro())
            }
            Spacer()
            Button("Annulla", action: chiudi)
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button(nuova ? "Aggiungi la spesa" : "Salva") {
                var s = bozza
                s.importo = ((importo ?? 0) * 100).rounded() / 100
                if stato.salvaSpesa(s, fileScontrino: file, evidenzia: nuova && file != nil) { chiudi() }
            }
            .buttonStyle(StileBlu())
            .disabled(!valido || stato.solaLettura)
            .opacity(valido ? 1 : M.opacitaDisattivo)
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: M.foglioLargo.width, height: M.foglioLargo.height)
        .alert("Eliminare la spesa?", isPresented: $daEliminare) {
            Button("Elimina", role: .destructive) {
                stato.eliminaSpesa(bozza.id)
                chiudi()
            }
            Button("Lascia com’è", role: .cancel) {}
        } message: {
            Text("La spesa e il file del suo scontrino si tolgono da Prisma. Restano nei backup già fatti.")
        }
    }

    /// Lo scontrino: l'anteprima del file (appena inquadrato o salvato) e «Apri lo scontrino».
    @ViewBuilder private var anteprima: some View {
        let t = Tema.Apple.Studio.Spese.Scontrino.self
        let url = file ?? bozza.scontrino.map { Archivio.cartellaScontrini().appendingPathComponent($0) }
        if let url {
            VStack(alignment: .leading, spacing: M.spazioRighe) {
                AnteprimaScontrino(url: url)
                    .frame(width: t.anteprima.width, height: t.anteprima.height)
                #if os(macOS)
                if FileManager.default.fileExists(atPath: url.path) {
                    Button("Apri lo scontrino") { NSWorkspace.shared.open(url) }
                        .buttonStyle(.appleSobrio)
                }
                #endif
            }
        }
    }

    private func testo(_ k: WritableKeyPath<SpesaStudio, String?>) -> Binding<String> {
        Binding(get: { bozza[keyPath: k] ?? "" },
                set: { bozza[keyPath: k] = $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 })
    }
}

/// L'anteprima di uno scontrino (foto o prima pagina del PDF), letta una volta fuori dal thread principale.
private struct AnteprimaScontrino: View {
    let url: URL
    @State private var immagine: ImmaginePiattaforma?
    @State private var cercata = false

    var body: some View {
        let t = Tema.Apple.Studio.Spese.Scontrino.self
        let forma = RoundedRectangle(cornerRadius: t.raggioAnteprima, style: .continuous)
        ZStack {
            forma.fill(t.fondo)
            if let immagine {
                #if os(macOS)
                Image(nsImage: immagine).resizable().scaledToFit()
                #else
                Image(uiImage: immagine).resizable().scaledToFit()
                #endif
            } else {
                VStack(spacing: M.spazioRighe) {
                    Image(systemName: "doc.text")
                        .carattereApple(Tema.Apple.Carattere.titoloGruppo)
                        .foregroundColor(t.coloreSimbolo)
                    Text(cercata ? "Scontrino non trovato sul Mac" : "Scontrino")
                        .carattereApple(M.rigaSotto)
                        .foregroundColor(M.coloreRigaSotto)
                        .multilineTextAlignment(.center)
                }
                .padding(M.spazio)
            }
        }
        .clipShape(forma)
        .overlay(forma.strokeBorder(t.bordo, lineWidth: Tema.Apple.Misura.bordo))
        .task(id: url) {
            let u = url
            let i = await Task.detached(priority: .utility) { LetturaDocumenti.anteprima(u, lato: 900) }.value
            immagine = i
            cercata = true
        }
    }
}

// MARK: - Una scadenza

private struct ModuloScadenzaStudio: View {
    @Environment(StatoShell.self) private var stato
    @State private var bozza: ScadenzaStudio
    @State private var fatta: Bool
    @State private var daEliminare = false
    let nuova: Bool
    let chiudi: () -> Void

    init(bozza: ScadenzaStudio, nuova: Bool, chiudi: @escaping () -> Void) {
        _bozza = State(initialValue: bozza)
        _fatta = State(initialValue: bozza.fattaIl != nil)
        self.nuova = nuova
        self.chiudi = chiudi
    }

    private var valido: Bool { !bozza.titolo.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        CorniceModulo(titolo: nuova ? "Aggiungi una scadenza" : "La scadenza") {
            VStack(alignment: .leading, spacing: M.spazioRighe) {
                if nuova {
                    NotaFoglio(testo: "Puoi partire da un titolo. " + TestiSpese.verificaCommercialista)
                    HStack(spacing: M.spazioRighe) {
                        ForEach(ScadenzaStudio.titoliSuggeriti, id: \.titolo) { s in
                            Button(s.titolo) {
                                bozza.titolo = s.titolo
                                bozza.tipo = s.tipo
                            }
                            .buttonStyle(.apple)
                        }
                    }
                }
                CampoModulo(etichetta: "Titolo") {
                    TextField("", text: $bozza.titolo).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Data") {
                    DatePicker("", selection: $bozza.data, displayedComponents: [.date])
                        .labelsHidden()
                        .stileDataCampo()
                        .environment(\.locale, Formati.italiano)
                }
                CampoModulo(etichetta: "Tipo") {
                    MenuTendina(selezione: $bozza.tipo, opzioni: TipoScadenza.allCases.map { ($0, $0.nome) }, larghezza: M.campoTesto)
                }
                CampoModulo(etichetta: "Ricorrenza") {
                    MenuTendina(selezione: $bozza.ricorrenza,
                                opzioni: [(RicorrenzaScadenza?.none, "Una volta sola")] + RicorrenzaScadenza.allCases.map { (Optional($0), $0.nome) },
                                larghezza: M.sceltaPresso)
                }
                CampoModulo(etichetta: "Importo") {
                    CampoCifraFacoltativa(valore: $bozza.importo, unita: "€, se lo conosci", larghezza: M.campoImporto)
                }
                CampoModulo(etichetta: "Nota") {
                    TextField("come impostato con il commercialista…", text: $bozza.nota).textFieldStyle(.roundedBorder)
                }
                if !nuova {
                    CampoModulo(etichetta: "Stato") {
                        Toggle(bozza.ricorrenza == nil ? "Fatta" : "Fatta (nasce la prossima)", isOn: $fatta).stileCasella()
                    }
                }
                NotaFoglio(testo: "Prisma non conosce il calendario fiscale: le scadenze sono quelle che scrivi tu.")
            }
        } piede: {
            if !nuova {
                Button {
                    daEliminare = true
                } label: {
                    Text("Elimina").foregroundColor(Colori.Rubrica.pericolo)
                }
                .buttonStyle(StileVetro())
            }
            Spacer()
            Button("Annulla", action: chiudi)
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button(nuova ? "Aggiungi" : "Salva") {
                var s = bozza
                s.titolo = s.titolo.trimmingCharacters(in: .whitespaces)
                let eraFatta = s.fattaIl != nil
                if !fatta { s.fattaIl = nil }
                stato.salvaScadenza(s)
                if fatta && !eraFatta { stato.segnaScadenzaFatta(s.id) }
                chiudi()
            }
            .buttonStyle(StileBlu())
            .disabled(!valido || stato.solaLettura)
            .opacity(valido ? 1 : M.opacitaDisattivo)
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: M.foglioLargo.width, height: M.foglio.height)
        .alert("Eliminare la scadenza?", isPresented: $daEliminare) {
            Button("Elimina", role: .destructive) {
                stato.eliminaScadenza(bozza.id)
                chiudi()
            }
            Button("Lascia com’è", role: .cancel) {}
        } message: {
            Text("La scadenza si toglie da Prisma. Resta nei backup già fatti.")
        }
    }
}

// MARK: - I corsi dell'anno

private struct FoglioCorsiStudio: View {
    @Environment(StatoShell.self) private var stato
    let chiudi: () -> Void
    @State private var bozza = CorsoAggiornamento(titolo: "", data: Date(), ore: 0)
    @State private var ore: Double?
    @State private var attestato: URL?
    @State private var modifica = false
    /// Il corso da togliere, dopo la conferma (si toglie anche il suo attestato).
    @State private var daEliminare: CorsoAggiornamento?

    var body: some View {
        let anno = Calendar.current.component(.year, from: Date())
        let corsi = MotoreSpese.corsi(stato.dati.speseStudio.corsi, anno: anno)
        let fatte = MotoreSpese.ore(stato.dati.speseStudio.corsi, anno: anno)
        let obiettivo = stato.dati.impostazioni.studio.spese.oreAggiornamentoAnno[anno]
        return CorniceModulo(titolo: "I tuoi corsi del \(String(anno))") {
            VStack(alignment: .leading, spacing: M.spazioRighe) {
                NotaFoglio(testo: obiettivo.map { "\(FormatoCifra.mesi.testo(fatte)) ore su \(FormatoCifra.mesi.testo($0)) richieste (le hai scritte tu in Impostazioni › Studio)." }
                           ?? "\(FormatoCifra.mesi.testo(fatte)) ore. Le ore richieste per l’anno le scrivi tu in Impostazioni › Studio.")
                if corsi.isEmpty {
                    NotaFoglio(testo: "Nessun corso nel \(String(anno)). Aggiungi i corsi con le ore e l’attestato.")
                }
                ForEach(corsi) { c in
                    RigaFoglio {
                        HStack(alignment: .firstTextBaseline, spacing: M.spazio) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(c.titolo).carattereApple(M.rigaForte).foregroundColor(M.coloreRiga)
                                Text([TestiSpese.giorno(c.data), c.ente, c.canale?.nomeBreve ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .carattereApple(M.rigaSotto).foregroundColor(M.coloreRigaSotto)
                            }
                            Spacer()
                            Text("\(FormatoCifra.mesi.testo(c.ore)) ore").carattereApple(M.rigaForte).foregroundColor(M.coloreRiga)
                            #if os(macOS)
                            if let a = c.attestato {
                                Button("Attestato") { NSWorkspace.shared.open(Archivio.cartellaAttestati().appendingPathComponent(a)) }
                                    .buttonStyle(.appleSobrio)
                            }
                            #endif
                            Button {
                                bozza = c
                                ore = c.ore
                                attestato = nil
                                modifica = true
                            } label: { Image(systemName: "pencil") }
                            .buttonStyle(.plain)
                            .help("Modifica il corso")
                            Button { daEliminare = c } label: { Image(systemName: "minus.circle") }
                                .buttonStyle(.plain)
                                .help("Togli il corso e il suo attestato")
                        }
                    }
                }
                TitoloGruppoFoglio(testo: modifica ? "Modifica il corso" : "Aggiungi un corso")
                CampoModulo(etichetta: "Titolo") {
                    TextField("", text: $bozza.titolo).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Ente") {
                    TextField("", text: $bozza.ente).textFieldStyle(.roundedBorder)
                }
                CampoModulo(etichetta: "Data") {
                    DatePicker("", selection: $bozza.data, displayedComponents: [.date])
                        .labelsHidden()
                        .stileDataCampo()
                        .environment(\.locale, Formati.italiano)
                }
                CampoModulo(etichetta: "Ore") {
                    CampoCifraFacoltativa(valore: $ore, unita: "ore", larghezza: M.campoKm)
                }
                CampoModulo(etichetta: "Canale") {
                    MenuTendina(selezione: $bozza.canale,
                                opzioni: [(Canale?.none, "Non indicato")] + Canale.allCases.map { (Optional($0), $0.nomeBreve) },
                                larghezza: M.sceltaPresso)
                }
                #if os(macOS)
                CampoModulo(etichetta: "Attestato") {
                    HStack(spacing: M.spazioRighe) {
                        Button(attestato == nil ? "Scegli il file…" : "Cambia file…", action: scegliAttestato)
                            .buttonStyle(.apple)
                        if let attestato {
                            Text(attestato.lastPathComponent).carattereApple(M.rigaSotto).foregroundColor(M.coloreRigaSotto).lineLimit(1)
                        } else if bozza.attestato != nil {
                            Text("già allegato").carattereApple(M.rigaSotto).foregroundColor(M.coloreRigaSotto)
                        }
                    }
                }
                #endif
                HStack {
                    Spacer()
                    if modifica {
                        Button("Annulla la modifica", action: azzera).buttonStyle(StileVetro())
                    }
                    Button(modifica ? "Salva il corso" : "Aggiungi il corso") {
                        var c = bozza
                        c.ore = ore ?? 0
                        c.titolo = c.titolo.trimmingCharacters(in: .whitespaces)
                        stato.salvaCorso(c, fileAttestato: attestato)
                        azzera()
                    }
                    .buttonStyle(StileBlu())
                    .disabled(bozza.titolo.trimmingCharacters(in: .whitespaces).isEmpty || (ore ?? 0) <= 0 || stato.solaLettura)
                }
            }
        } piede: {
            Spacer()
            Button("Fine", action: chiudi)
                .buttonStyle(StileBlu())
                .keyboardShortcut(.defaultAction)
        }
        .frame(width: M.foglioLargo.width, height: M.foglioLargo.height)
        .alert("Togliere il corso?", isPresented: Binding(get: { daEliminare != nil }, set: { if !$0 { daEliminare = nil } })) {
            Button("Togli", role: .destructive) {
                if let c = daEliminare {
                    stato.eliminaCorso(c.id)
                    if bozza.id == c.id { azzera() }
                }
                daEliminare = nil
            }
            Button("Lascia com’è", role: .cancel) { daEliminare = nil }
        } message: {
            Text(daEliminare?.attestato == nil
                 ? "Il corso «\(daEliminare?.titolo ?? "")» si toglie da Prisma. Resta nei backup già fatti."
                 : "Il corso «\(daEliminare?.titolo ?? "")» e il file del suo attestato si tolgono da Prisma. Restano nei backup già fatti.")
        }
    }

    private func azzera() {
        bozza = CorsoAggiornamento(titolo: "", data: Date(), ore: 0)
        ore = nil
        attestato = nil
        modifica = false
    }

    #if os(macOS)
    private func scegliAttestato() {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.pdf, .image]
        p.allowsMultipleSelection = false
        p.message = "Scegli l'attestato del corso"
        guard p.runModal() == .OK, let url = p.url else { return }
        attestato = url
    }
    #endif
}

// MARK: - Le visite del mese

/// Tutte le visite del mese con i km: «Dove eri?» per quelle senza luogo, i km di andata e ritorno che mancano.
private struct FoglioVisiteSpese: View {
    @Environment(StatoShell.self) private var stato
    let chiudi: () -> Void

    var body: some View {
        let imp = stato.dati.impostazioni.studio.spese
        let mese = stato.studioSpese.mese(impostazioni: imp)
        let km = MotoreChilometri.riepilogo(mese: mese, appuntamenti: stato.dati.appuntamenti, impostazioni: imp,
                                            kmClienti: stato.dati.kmClienti)
        return CorniceModulo(titolo: "Le visite di \(TestiSpese.mese(mese))") {
            VStack(alignment: .leading, spacing: M.spazioRighe) {
                NotaFoglio(testo: "I km sono quelli di andata e ritorno che scrivi per ogni cliente; se un giro unisce più "
                           + "clienti, correggilo a mano con il doppio clic sui km nella card. Prisma non usa servizi di percorso.")
                if km.vuoto {
                    NotaFoglio(testo: TestiSpese.nessunKm(mese))
                }
                ForEach(km.giri) { g in
                    TitoloGruppoFoglio(testo: TestiSpese.giorno(g.giorno) + " · " + TestiSpese.km(g.km)
                                       + (g.corretto ? " · corretto a mano" : ""))
                    ForEach(g.visite) { v in
                        RigaFoglio { riga(v, imp: imp) }
                    }
                }
            }
        } piede: {
            Button("Impostazioni dei km") {
                chiudi()
                stato.apriImpostazioniSpese()
            }
            .buttonStyle(StileVetro())
            Spacer()
            Button("Fine", action: chiudi)
                .buttonStyle(StileBlu())
                .keyboardShortcut(.defaultAction)
        }
        .frame(width: M.foglioLargo.width, height: M.foglioLargo.height)
    }

    private func riga(_ v: MotoreChilometri.Visita, imp: ImpostazioniSpese) -> some View {
        let nome = v.clienteId.isEmpty ? "Senza cliente" : stato.nomeClienteSpese(v.clienteId)
        return HStack(alignment: .center, spacing: M.spazio) {
            VStack(alignment: .leading, spacing: 0) {
                Text(nome).carattereApple(M.rigaForte).foregroundColor(M.coloreRiga).lineLimit(1)
                Text(Formati.ora.string(from: v.inizio) + motivo(v))
                    .carattereApple(M.rigaSotto)
                    .foregroundColor(v.km == nil ? M.coloreAvviso : M.coloreRigaSotto)
                    .lineLimit(1)
            }
            Spacer(minLength: M.spazio)
            MenuTendina(selezione: Binding(get: { v.presso }, set: { stato.impostaPresso(v.appuntamentoId, $0) }),
                        opzioni: [(LuogoIncontro?.none, "Dove eri?")] + LuogoIncontro.allCases.map { (Optional($0), $0.nome) },
                        larghezza: M.sceltaPresso)
                .disabled(stato.solaLettura)
            if !v.clienteId.isEmpty {
                CampoCifraFacoltativa(valore: Binding(get: { stato.dati.kmClienti[v.clienteId] },
                                                      set: { stato.impostaKmCliente(v.clienteId, $0) }),
                                      unita: "km a/r", larghezza: M.campoKm)
                    .disabled(stato.solaLettura)
            }
        }
    }

    private func motivo(_ v: MotoreChilometri.Visita) -> String {
        switch v.motivo {
        case .luogoMancante: return " · dove eri?"
        case .distanzaMancante: return " · mancano i km di andata e ritorno"
        case .altrove: return " · altrove: correggi il giro a mano"
        case .senzaCliente: return " · senza cliente: correggi il giro a mano"
        case nil: return ""
        }
    }
}

// MARK: - L'elenco delle spese

private struct FoglioElencoSpese: View {
    @Environment(StatoShell.self) private var stato
    let chiudi: () -> Void

    var body: some View {
        let imp = stato.dati.impostazioni.studio.spese
        let mese = stato.studioSpese.mese(impostazioni: imp)
        let spese = MotoreSpese.delMese(stato.dati.speseStudio.spese, mese: mese)
        return CorniceModulo(titolo: "Le spese di \(TestiSpese.mese(mese))") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(spese) { s in
                    RigaFoglio {
                        HStack(spacing: M.spazio) {
                            MiniaturaScontrino(conScontrino: s.scontrino != nil)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(s.descrizione.isEmpty ? s.categoria.nome : s.descrizione)
                                    .carattereApple(M.rigaForte).foregroundColor(M.coloreRiga)
                                Text(TestiSpese.giorno(s.data) + " · " + s.categoria.nome + (s.daControllare ? " · da controllare" : ""))
                                    .carattereApple(M.rigaSotto)
                                    .foregroundColor(s.daControllare ? M.coloreAvviso : M.coloreRigaSotto)
                            }
                            Spacer()
                            Text(Formati.euroDecimali(s.importo)).carattereApple(M.rigaForte).foregroundColor(M.coloreRiga)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { stato.studioSpese.foglio = .spesa(s.id) }
                    }
                }
                ForEach(MotoreSpese.perCategoria(spese), id: \.categoria) { c in
                    HStack {
                        Text(c.categoria.nome).carattereApple(M.rigaSotto).foregroundColor(M.coloreRigaSotto)
                        Spacer()
                        Text(Formati.euroDecimali(c.totale)).carattereApple(M.rigaSotto).foregroundColor(M.coloreRigaSotto)
                    }
                    .padding(.top, M.spazioRighe)
                }
            }
        } piede: {
            Text("Totale " + Formati.euroDecimali(MotoreSpese.totale(spese)))
                .carattereApple(M.rigaForte)
                .foregroundColor(M.coloreRiga)
            Spacer()
            Button("Fine", action: chiudi)
                .buttonStyle(StileBlu())
                .keyboardShortcut(.defaultAction)
        }
        .frame(width: M.foglio.width, height: M.foglio.height)
    }
}

// MARK: - La correzione dei km di un giro

private struct ModuloCorrezioneKm: View {
    @Environment(StatoShell.self) private var stato
    let chiave: String
    let chiudi: () -> Void
    @State private var km: Double?
    @State private var letto = false

    var body: some View {
        let imp = stato.dati.impostazioni.studio.spese
        let corretto = imp.kmCorretti[chiave]
        return CorniceModulo(titolo: "I km del giro") {
            VStack(alignment: .leading, spacing: M.spazioRighe) {
                CampoModulo(etichetta: "Km del giro") {
                    CampoCifraFacoltativa(valore: $km, unita: "km, andata e ritorno compresi", larghezza: M.campoKm)
                }
                NotaFoglio(testo: "La correzione vince sui km dei clienti e si segna «corretto a mano».")
            }
        } piede: {
            if corretto != nil {
                Button("Togli la correzione") {
                    stato.correggiKmGiro(chiave, nil)
                    chiudi()
                }
                .buttonStyle(StileVetro())
            }
            Spacer()
            Button("Annulla", action: chiudi)
                .buttonStyle(StileVetro())
                .keyboardShortcut(.cancelAction)
            Button("Salva") {
                stato.correggiKmGiro(chiave, km)
                chiudi()
            }
            .buttonStyle(StileBlu())
            .disabled(km == nil || stato.solaLettura)
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: M.correzione.width, height: M.correzione.height)
        .onAppear {
            guard !letto else { return }
            letto = true
            km = corretto
        }
    }
}
