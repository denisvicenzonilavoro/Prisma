import SwiftUI

// MARK: - Dettaglio di un documento (app Documenti, giro 6)

/// Il dettaglio di un documento: il foglio è il protagonista, a tutta altezza. Sopra una barra compatta (titolo, stato
/// con il canale, l'azione che vale, Vera, il menu «⋯» e il pulsante dei dati); accanto, snello e richiudibile, il
/// pannello «Dati», «Confronto», «Testo». Il pannello non copre mai il foglio: se non c'è posto accanto si chiude da
/// solo (resta il pulsante «Dati» con il numero da confermare) e, se il consulente lo apre, diventa un cassetto in basso.
/// La vista non riscrive mai `documentoSelezionato`.
struct DettaglioDocumento: View {
    @Environment(StatoShell.self) var stato
    let voce: MotoreDocumenti.Voce
    /// Chiede conferma prima di eliminare (l'avviso sta nell'app, che lo usa anche da tastiera).
    let chiediEliminazione: (Documento) -> Void

    @State private var larghezza: CGFloat = 0
    @State private var moduloMenu = false
    @State private var moduloAzione = false
    @State private var cosaCrea: CreaDaDocumento = .scheda

    private var d: Documento { voce.documento }
    private var inLettura: Bool { stato.documentiInLettura.contains(d.id) }

    /// La scheda «Confronto» c'è per KID e polizze (specifica 9) e per identità e questionari.
    private var haConfronto: Bool {
        MotoreDocumenti.delCliente(d) || (MotoreConfrontoDossier.confrontabile(d) && !d.tipo.creatoDaPrisma)
    }

    /// La scheda che si vede: «Confronto» su un documento senza confronto mostra «Dati» (senza cambiare lo stato).
    private var schedaMostrata: VistaDocumenti.Scheda {
        let s = stato.vistaDocumenti.scheda
        return s == .confronto && !haConfronto ? .dati : s
    }

    private var opzioniSchede: [(VistaDocumenti.Scheda, String)] {
        var o: [(VistaDocumenti.Scheda, String)] = [(.dati, "Dati")]
        if haConfronto { o.append((.confronto, TestiConfrontoDossier.scheda(differenze: voce.indicatori.differenze))) }
        o.append((.testo, "Testo"))
        return o
    }

    /// Il pannello: più largo quando mostra la tabella del confronto.
    private var larghezzaScheda: CGFloat {
        schedaMostrata == .confronto ? Tema.Misura.Documenti.schedaConfronto : Tema.Misura.Documenti.scheda
    }

    /// I documenti impaginati da Prisma non hanno dati da leggere: basta il foglio, niente pannello.
    private var conPannello: Bool { d.genere != .prisma }

    /// C'è posto per il pannello accanto al foglio.
    private func affiancato(_ larghezza: CGFloat) -> Bool {
        larghezza >= Tema.Misura.Documenti.anteprimaMinima + larghezzaScheda
    }

    /// Il pannello è aperto se il consulente l'ha chiesto o, in automatico, se ci sta accanto al foglio (altrimenti
    /// resta chiuso: il foglio prende tutto lo spazio).
    private func pannelloAperto(_ larghezza: CGFloat) -> Bool {
        guard conPannello else { return false }
        if let scelta = stato.vistaDocumenti.pannelloDati { return scelta }
        return affiancato(larghezza)
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        VStack(spacing: 0) {
            barra
            GeometryReader { geo in
                corpo(geo.size)
                    .onAppear { larghezza = geo.size.width }
                    .onChange(of: geo.size.width) { stringe(a: $0) }
            }
        }
    }

    /// La finestra si stringe e il pannello aperto dal consulente non sta più accanto al foglio: si chiude da solo
    /// (torna automatico) invece di rubare spazio alla pagina; il pulsante «Dati» lo riapre come cassetto.
    private func stringe(a nuova: CGFloat) {
        let primaAccanto: Bool = affiancato(larghezza)
        larghezza = nuova
        if primaAccanto && !affiancato(nuova) && stato.vistaDocumenti.pannelloDati == true {
            stato.vistaDocumenti.pannelloDati = nil
        }
    }

    /// Una fonte «p. N»: la pagina e la riga del dato, evidenziata sul foglio. Il pannello (accanto o cassetto in
    /// basso) non copre il foglio: resta aperto e la riga si vede.
    private func mostraFonte(_ pagina: Int, _ campo: CampoDocumento) {
        guard pagina > 0 else { return }
        stato.vistaDocumenti.pagina = pagina
        stato.vistaDocumenti.evidenzia = campo
    }

    #if os(macOS)
    private static let notaImpaginato = "Impaginato da Prisma con i dati del dossier: da consultare, stampare o consegnare. Con «Apri in Anteprima» lo apri sul Mac."
    #elseif os(iOS)
    private static let notaImpaginato = "Impaginato da Prisma con i dati del dossier: da consultare, stampare o consegnare. Con «Condividi…» lo mandi al cliente o lo salvi in File."
    #endif

    // MARK: Corpo

    /// Il foglio prende tutto lo spazio; il pannello sta accanto o, se non c'è posto, in un cassetto sotto il foglio.
    /// Mai sopra: la pagina si vede sempre intera in larghezza. Il foglio sta sempre nello stesso posto della
    /// gerarchia, così aprire o chiudere il pannello non lo ricrea (zoom e pagina restano).
    private func corpo(_ misura: CGSize) -> some View {
        let aperto = pannelloAperto(misura.width)
        let accanto = aperto && affiancato(misura.width)
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                AnteprimaDocumento(documento: d)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if accanto {
                    DivisoreColonne()
                    colonnaScheda
                        .frame(width: larghezzaScheda)
                        .frame(maxHeight: .infinity)
                }
            }
            if aperto && !accanto {
                cassetto(altezza: misura.height)
            }
        }
    }

    /// Il pannello come cassetto sotto il foglio (dettaglio stretto): largo quanto il foglio, una parte dell'altezza.
    private func cassetto(altezza: CGFloat) -> some View {
        let m = Tema.Misura.Documenti.self
        let quota: CGFloat = altezza * m.quotaCassetto
        let alto: CGFloat = min(max(quota, m.cassettoMinimo), m.cassettoMassimo)
        return colonnaScheda
            .frame(maxWidth: .infinity)
            .frame(height: alto)
            .bordoAlto(Tema.Apple.Colore.separatore)
    }

    private var colonnaScheda: some View {
        let m = Tema.Misura.Documenti.self
        return VStack(spacing: 0) {
            SchedeRisultati(opzioni: opzioniSchede,
                            selezione: Binding(get: { schedaMostrata }, set: { stato.vistaDocumenti.scheda = $0 })) {
                PulsanteIcona(simbolo: "xmark", aiuto: "Chiudi i dati: resta solo il documento", taglia: .compatta,
                              vetro: false) {
                    stato.vistaDocumenti.pannelloDati = false
                }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: m.spazioSezioni) {
                    switch schedaMostrata {
                    case .dati:
                        SchedaDatiDocumento(voce: voce, mostraFonte: mostraFonte)
                    case .confronto:
                        if MotoreDocumenti.delCliente(d) {
                            ConfrontoClienteVista(documento: d, mostraFonte: mostraFonte)
                        } else {
                            ConfrontoDossierVista(documento: d)
                        }
                    case .testo:
                        SchedaTestoDocumento(documento: d)
                    }
                }
                .padding(m.margineScheda)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Barra

    /// Una barra sola: tessera, titolo con lo stato sotto; a destra l'azione che vale, Vera, «⋯» e i dati.
    private var barra: some View {
        let m = Tema.Misura.Documenti.self
        return HStack(alignment: .center, spacing: m.spazioRiga) {
            TesseraDocumento(categoria: d.genere)
                .help(d.genere == .prisma ? Self.notaImpaginato : d.genere.nome)
            VStack(alignment: .leading, spacing: m.spazioRigheBarra) {
                titolo
                rigaStato
            }
            .frame(minWidth: m.titoloMinimo, maxWidth: .infinity, alignment: .leading)
            azioni
                .layoutPriority(1)
        }
        .padding(m.barraDettaglio)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bordoBasso(Tema.Apple.Colore.separatore)
        // Il modulo «Crea…» si apre dal menu «⋯»
        .popover(isPresented: $moduloMenu, arrowEdge: .bottom) {
            ModuloCreaDaDocumento(documento: d, cosa: cosaCrea) { moduloMenu = false }
                .environment(stato)
        }
    }

    /// Il titolo si corregge sul posto: passa all'archivio poco dopo l'ultimo tasto, con il tipo di quel momento.
    private var titolo: some View {
        TestoRinviato(testo: Binding(get: { d.titolo },
                                     set: { stato.rinominaDocumento(d.id, titolo: $0, tipo: stato.documento(d.id)?.tipo ?? d.tipo) }),
                      salvaOra: { stato.salvaOra() }) { bozza in
            TextField("Titolo", text: bozza)
                .textFieldStyle(.plain)
                .font(Tema.Testo.Documenti.titolo)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
                .lineLimit(1)
        }
        .id(d.id)
        .disabled(stato.solaLettura)
        .help(meta)
    }

    /// «KID · 3 pagine · 184 KB · importato il 26 ottobre 2026 · 1 pagina letta dalla scansione».
    private var meta: String {
        var parti = [d.genere.breve]
        if d.pagine > 0 { parti.append("\(d.pagine) \(d.pagine == 1 ? "pagina" : "pagine")") }
        if d.dimensione > 0 { parti.append(Formati.dimensione(d.dimensione)) }
        parti.append("importato il \(Formati.dataEstesa.string(from: d.importatoIl))")
        if d.pagineOCR > 0 { parti.append(d.pagineOCR == 1 ? "1 pagina letta dalla scansione" : "\(d.pagineOCR) pagine lette dalla scansione") }
        if d.file == nil { parti.append("documento di prova") }
        return parti.joined(separator: " · ")
    }

    /// Sotto il titolo, su una riga: lo stato, il collegamento con il canale e, se c'è posto, tipo e pagine.
    private var rigaStato: some View {
        ViewThatFits(in: .horizontal) {
            filaStato(conMeta: true, conNome: true)
            filaStato(conMeta: false, conNome: true)
            // L'ultima scelta si stringe ma tiene il canale (CLAUDE.md: canale sempre riconoscibile)
            filaStato(conMeta: false, conNome: false)
        }
    }

    /// «KID · 3 pagine · 31 ott»: la versione corta di `meta`.
    private var metaBreve: String {
        var parti = [d.genere.breve]
        parti.append(RigaDocumento.meta(d))
        return parti.joined(separator: " · ")
    }

    private func filaStato(conMeta: Bool, conNome: Bool, conCollegamento: Bool = true) -> some View {
        let m = Tema.Misura.Documenti.self
        let s = voce.indicatori.stato
        let nota = s.nota(voce.indicatori, nome: voce.nomeCollegato)
        return HStack(spacing: m.spazioBarra) {
            if s == .inLettura {
                ProgressView().controlSize(.small)
                Text(s.etichetta)
                    .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(1)
            } else {
                Pillola(testo: s.etichetta, tono: Self.tono(s))
                    .help(nota.isEmpty ? s.etichetta : nota)
            }
            if conCollegamento { collegamento(conNome: conNome) }
            if conMeta {
                Text(metaBreve)
                    .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .lineLimit(1)
            }
        }
        // L'ultima versione si stringe (il testo si tronca) invece di uscire dalla barra
        .fixedSize(horizontal: conNome, vertical: false)
    }

    /// Il collegamento (posizione o scheda con il canale; «In regola» per i documenti del cliente). Il canale si
    /// vede sempre: quello del documento o, se non si sa ancora, una pillola neutra.
    @ViewBuilder private func collegamento(conNome: Bool) -> some View {
        let spazio = Tema.Misura.Componenti.spazioSimboloPulsante
        if MotoreDocumenti.delCliente(d) {
            Button { stato.apriInRegola(d.clienteId) } label: {
                HStack(spacing: spazio) {
                    Text("In regola")
                    Image(systemName: "arrow.up.right")
                }
            }
            .buttonStyle(StileCollegamento())
            .fixedSize()
            .help("Documento del cliente: si confronta con il dossier. Apri «In regola»")
        } else if let b = stato.collegamentoMostrato(d), let n = stato.nomeBersaglio(b) {
            Button { stato.apriCollegamentoDocumento(b) } label: {
                HStack(spacing: spazio) {
                    if conNome {
                        Text("\(Self.genere(b)) «\(n.nome)»").lineLimit(1)
                    } else {
                        Image(systemName: "link")
                    }
                    Image(systemName: "arrow.up.right")
                }
            }
            .buttonStyle(StileCollegamento())
            .help("Apri \(Self.genere(b).lowercased()) «\(n.nome)»")
            EtichettaCanale(canale: n.canale, compatta: !conNome)
        } else if d.genere != .prisma {
            if let c = voce.canale {
                EtichettaCanale(canale: c, compatta: true)
            } else {
                // Nella fila corta la pillola si accorcia, come collegamento e canale
                Pillola(testo: conNome ? "Canale da indicare" : "Canale ?", tono: .neutro)
                    .help("Collega il documento a una posizione o a una scheda prodotto: il canale viene da lì")
                    .accessibilityLabel(Text("Canale da indicare"))
            }
        }
    }

    static func tono(_ s: MotoreDocumenti.Stato) -> Pillola.Tono {
        switch s {
        case .conDifferenze: return .attenzione
        case .illeggibile: return .errore
        case .collegato: return .ok
        default: return .neutro
        }
    }

    private static func genere(_ b: BersaglioConfronto) -> String {
        switch b {
        case .posizione: return "Posizione"
        case .prodotto: return "Scheda"
        }
    }

    /// Le azioni: mai una parola tagliata. Prima l'azione che vale con la scritta, poi (stretto) con la sola icona.
    private var azioni: some View {
        ViewThatFits(in: .horizontal) {
            filaAzioni(compatta: false)
            filaAzioni(compatta: true)
        }
        // Fuori da ViewThatFits: un popover solo, qualunque fila si veda
        .popover(isPresented: $moduloAzione, arrowEdge: .bottom) {
            ModuloCreaDaDocumento(documento: d, cosa: cosaCrea) { moduloAzione = false }
                .environment(stato)
        }
    }

    private func filaAzioni(compatta: Bool) -> some View {
        let m = Tema.Misura.Documenti.self
        return HStack(spacing: m.spazioBarra) {
            azionePrincipaleVista(compatta: compatta)
            if d.genere != .prisma {
                PulsanteIcona(simbolo: "sparkles", aiuto: "Apri con Vera: spiega il documento e lo confronta con il dossier") {
                    TestiRinviati.scriviOra()
                    stato.spiegaDocumentoConVera(d.id)
                }
                .disabled(stato.veraInCorso || inLettura)
            }
            MenuAzioni(voci: { vociMenu() }, margine: m.pulsanteIcona, taglia: .normale) {
                Image(systemName: "ellipsis")
            }
            .help("Tipo, collegamento, crea e altre azioni")
            .accessibilityLabel("Altre azioni")
            if conPannello {
                pulsantePannello(compatto: compatta)
            }
        }
        .fixedSize()
    }

    /// «Dati» apre e chiude il pannello; da chiuso dice quanti dati aspettano la conferma.
    private func pulsantePannello(compatto: Bool) -> some View {
        let m = Tema.Misura.Documenti.self
        let aperto = pannelloAperto(larghezza)
        let n = voce.indicatori.daControllare
        let aiuto = aperto ? "Nascondi i dati letti" : (n > 0 ? "Mostra i dati letti: \(n) da confermare" : "Mostra i dati letti")
        return Button {
            stato.vistaDocumenti.pannelloDati = !aperto
        } label: {
            HStack(spacing: m.spazioStatoRiga) {
                Image(systemName: "sidebar.right")
                if !compatto { Text("Dati") }
                if n > 0 && !aperto {
                    Text("\(n)")
                        .font(Tema.Testo.Documenti.contatore)
                        .foregroundColor(Tema.Colore.Documenti.testoContatore)
                        .padding(m.contatore)
                        .background { FormaVetro.capsula.fill(Tema.Colore.Documenti.contatore) }
                }
            }
        }
        .buttonStyle(StileVetro(margine: m.pulsante, taglia: .normale))
        .help(aiuto)
        .accessibilityLabel(aiuto)
    }

    // MARK: Menu «⋯»: Vera, collega, crea, tipo e il resto

    private func vociMenu() -> [VoceMenuAzioni] {
        var voci: [VoceMenuAzioni] = []
        if d.genere != .prisma {
            let id = d.id
            voci.append(VoceMenuAzioni.azione("Apri con Vera", attiva: !stato.veraInCorso && !inLettura) {
                TestiRinviati.scriviOra()
                stato.spiegaDocumentoConVera(id)
            })
            if !stato.solaLettura {
                if !MotoreDocumenti.delCliente(d) {
                    voci.append(VoceMenuAzioni.separatore)
                    voci.append(VoceMenuAzioni.sezione("Collega a…"))
                    voci.append(contentsOf: vociCollega())
                }
                if !inLettura {
                    voci.append(VoceMenuAzioni.separatore)
                    voci.append(VoceMenuAzioni.sezione("Crea…"))
                    voci.append(contentsOf: vociCrea())
                }
                voci.append(VoceMenuAzioni.separatore)
                voci.append(VoceMenuAzioni.sezione("Tipo di documento"))
                voci.append(contentsOf: vociTipo())
            }
            voci.append(VoceMenuAzioni.separatore)
        }
        voci.append(contentsOf: vociAltro())
        return voci
    }

    private func vociTipo() -> [VoceMenuAzioni] {
        let id = d.id
        let attuale = d.genere
        let categorie: [CategoriaDocumento] = CategoriaDocumento.allCases.filter { $0.selezionabile }
        return categorie.map { c in
            VoceMenuAzioni.azione(c.breve, spuntata: c == attuale) {
                TestiRinviati.scriviOra()
                stato.impostaCategoria(id, c)
            }
        }
    }

    private func vociCollega() -> [VoceMenuAzioni] {
        let id = d.id
        let candidate = stato.candidateCollegamento(d)
        let collegati = stato.bersagli(d)
        let posizioni = candidate.filter { c in
            if case .posizione = c.0 { return true }
            return false
        }
        let schede = candidate.filter { c in
            if case .prodotto = c.0 { return true }
            return false
        }
        var voci: [VoceMenuAzioni] = []
        if !posizioni.isEmpty {
            voci.append(VoceMenuAzioni.sezione("Posizioni di \(stato.cliente(d.clienteId)?.nome ?? "questo cliente")"))
            for (b, etichetta) in posizioni {
                voci.append(VoceMenuAzioni.azione(etichetta, spuntata: collegati.contains(b)) { stato.collegaDocumento(id, a: b) })
            }
        }
        if !schede.isEmpty {
            voci.append(VoceMenuAzioni.sezione("Schede prodotto"))
            for (b, etichetta) in schede {
                voci.append(VoceMenuAzioni.azione(etichetta, spuntata: collegati.contains(b)) { stato.collegaDocumento(id, a: b) })
            }
        }
        if candidate.isEmpty { voci.append(VoceMenuAzioni.sezione("Nessuna posizione o scheda da collegare")) }
        voci.append(VoceMenuAzioni.separatore)
        voci.append(VoceMenuAzioni.azione("Non collegato", spuntata: collegati.isEmpty) {
            for b in collegati { stato.scollegaDocumento(id, da: b) }
        })
        return voci
    }

    private func vociCrea() -> [VoceMenuAzioni] {
        [
            VoceMenuAzioni.azione("Scheda prodotto…") { apriModuloDalMenu(.scheda) },
            VoceMenuAzioni.azione("Posizione in essere…") { apriModuloDalMenu(.posizione) },
            VoceMenuAzioni.azione("Proposta…") { apriModuloDalMenu(.proposta) },
        ]
    }

    private func apriModuloDalMenu(_ cosa: CreaDaDocumento) {
        cosaCrea = cosa
        moduloMenu = true
    }

    private func vociAltro() -> [VoceMenuAzioni] {
        let id = d.id
        let documento = d
        let file = stato.urlDocumento(d).flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        let collegati = stato.bersagli(d)
        #if os(macOS)
        var voci: [VoceMenuAzioni] = [
            VoceMenuAzioni.azione("Apri in Anteprima", attiva: file != nil) {
                if let file { ApriFile.apri(file) }
            },
            VoceMenuAzioni.azione("Mostra nel Finder", attiva: file != nil) { stato.mostraNelFinder(documento) },
        ]
        #elseif os(iOS)
        // Su iPhone e iPad: il foglio di condivisione (AirDrop, Mail, Salva su File) e la stampa con AirPrint
        var voci: [VoceMenuAzioni] = [
            VoceMenuAzioni.azione("Condividi…", attiva: file != nil) {
                if let file { StampaCarta.condividi(file, nome: documento.titolo) }
            },
            VoceMenuAzioni.azione("Stampa…", attiva: file != nil) {
                if let file { StampaCarta.stampa(file: file) }
            },
        ]
        #endif
        if d.genere != .prisma {
            voci.append(VoceMenuAzioni.azione("Rileggi il documento", attiva: file != nil && !inLettura && !stato.solaLettura) {
                TestiRinviati.scriviOra()
                stato.leggiDocumento(id)
            })
        }
        voci.append(VoceMenuAzioni.separatore)
        if !collegati.isEmpty {
            voci.append(VoceMenuAzioni.azione("Scollega", attiva: !stato.solaLettura) {
                for b in collegati { stato.scollegaDocumento(id, da: b) }
            })
        }
        voci.append(VoceMenuAzioni.azione("Elimina…", attiva: !stato.solaLettura) { chiediEliminazione(documento) })
        return voci
    }

    // MARK: Azione principale

    private enum AzionePrincipale {
        case rileggi
        case vediDifferenze(Int)
        case aggiornaValore
        case collega(BersaglioConfronto, String)
        case creaProposta(Prodotto)
        case creaScheda
        case creaPosizione
        case conferma(Int)

        var titolo: String {
            switch self {
            case .rileggi: return "Rileggi"
            case .vediDifferenze(let n): return "Vedi cosa non torna (\(n))"
            case .aggiornaValore: return "Aggiorna il valore"
            case .collega(_, let nome): return "Collega a «\(nome)»"
            case .creaProposta: return "Crea una proposta"
            case .creaScheda: return "Crea la scheda prodotto"
            case .creaPosizione: return "Crea la posizione in essere"
            case .conferma(let n): return n == 1 ? "Conferma il dato" : "Conferma i \(n) dati"
            }
        }

        /// L'icona davanti al titolo.
        var simbolo: String {
            switch self {
            case .rileggi: return "arrow.clockwise"
            case .vediDifferenze: return "exclamationmark.triangle"
            case .aggiornaValore: return "arrow.triangle.2.circlepath"
            case .collega: return "link"
            case .creaProposta, .creaScheda, .creaPosizione: return "plus"
            case .conferma: return "checkmark"
            }
        }

        /// Scrive nell'archivio: in sola lettura resta spenta.
        var scrive: Bool {
            if case .vediDifferenze = self { return false }
            return true
        }
    }

    /// La prima azione che vale (Documenti §6.5.1).
    private var azionePrincipale: AzionePrincipale? {
        let i = voce.indicatori
        if inLettura || i.stato == .inLettura { return nil }
        if d.lettura == .illeggibile, stato.urlDocumento(d) != nil, d.genere != .prisma { return .rileggi }
        if i.differenze > 0 { return .vediDifferenze(i.differenze) }
        if stato.valoreEstrattoDaRegistrare(d) != nil { return .aggiornaValore }
        if d.genere == .prisma { return nil }
        if MotoreDocumenti.delCliente(d) { return i.daControllare > 0 ? .conferma(i.daControllare) : nil }
        if !i.collegato, let s = stato.suggerimentoCollegamento(d), let n = stato.nomeBersaglio(s.0) {
            return .collega(s.0, n.nome)
        }
        if d.genere == .kid {
            for b in stato.bersagli(d) {
                if case .prodotto(let pid) = b, let p = stato.prodotto(pid) { return .creaProposta(p) }
            }
            if !i.collegato { return .creaScheda }
        }
        if d.genere == .contratto, !i.collegato { return .creaPosizione }
        if i.daControllare > 0 { return .conferma(i.daControllare) }
        return nil
    }

    /// Il blu del documento: la prima azione che vale; stretta, con la sola icona (il titolo nell'aiuto).
    @ViewBuilder private func azionePrincipaleVista(compatta: Bool) -> some View {
        if let a = azionePrincipale {
            Button { esegui(a) } label: {
                if compatta {
                    Image(systemName: a.simbolo)
                } else {
                    Label(a.titolo, systemImage: a.simbolo)
                }
            }
            .buttonStyle(StileBlu())
            .disabled(a.scrive && stato.solaLettura)
            .fixedSize()
            .help(a.titolo)
            .accessibilityLabel(a.titolo)
        }
    }

    private func esegui(_ a: AzionePrincipale) {
        switch a {
        case .rileggi:
            TestiRinviati.scriviOra()
            stato.leggiDocumento(d.id)
        case .vediDifferenze:
            stato.vistaDocumenti.scheda = .confronto
            stato.vistaDocumenti.pannelloDati = true
        case .aggiornaValore:
            TestiRinviati.scriviOra()
            stato.aggiornaValoreDaDocumento(d.id)
        case .collega(let b, _):
            stato.collegaDocumento(d.id, a: b)
        case .creaProposta(let p):
            TestiRinviati.scriviOra()
            stato.creaDaDocumento(d.id, cosa: .proposta, canale: p.canale, area: p.area, confermaPrima: false)
        case .creaScheda:
            cosaCrea = .scheda
            moduloAzione = true
        case .creaPosizione:
            cosaCrea = .posizione
            moduloAzione = true
        case .conferma:
            TestiRinviati.scriviOra()
            stato.confermaTutti(d.id)
        }
    }
}

// MARK: - Modulo «Crea da un documento»

/// Popover per creare dal documento una scheda prodotto, una posizione in essere o una proposta: canale (riconoscibile
/// prima di creare) e area, con quanti dati entrano.
struct ModuloCreaDaDocumento: View {
    @Environment(StatoShell.self) var stato
    let documento: Documento
    let cosa: CreaDaDocumento
    let chiudi: () -> Void

    @State private var canale: Canale = .alleanza
    @State private var area: AreaPosizione = .investimento

    private var titolo: String {
        switch cosa {
        case .scheda: return "Crea la scheda prodotto"
        case .posizione: return "Crea la posizione in essere"
        case .proposta: return "Crea una proposta"
        }
    }

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.Documenti.self
        let d = stato.documento(documento.id) ?? documento
        let confermati = d.campi.filter(\.confermato).count
        let daControllare = d.campi.count - confermati
        let aree: [(AreaPosizione, String)] = AreaPosizione.allCases.filter { $0 != .immobili && !$0.passivo }
            .map { ($0, $0.nome) }
        VStack(alignment: .leading, spacing: m.spazioModulo) {
            Text(titolo)
                .font(Tema.Apple.AltreApp.titoloRiga.fontLeggibile)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            SegmentiAnalisi(opzioni: [(Canale.alleanza, "Alleanza"), (Canale.indipendente, "Indipendente")], selezione: $canale)
            EtichettaCanale(canale: canale)
            MenuTendina(selezione: $area, opzioni: aree, larghezza: m.menuArea)
            Text(Self.testoDati(confermati: confermati, daControllare: daControllare))
                .font(Tema.Apple.Carattere.secondario.fontLeggibile)
                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .trailing, spacing: m.spazioBarra) {
                if daControllare > 0 {
                    Button("Conferma i \(daControllare) e crea") { crea(confermaPrima: true) }
                        .buttonStyle(StileBlu())
                    Button("Crea solo con i confermati") { crea(confermaPrima: false) }
                        .buttonStyle(StileVetro(margine: m.pulsante))
                        .disabled(confermati == 0)
                } else {
                    Button("Crea") { crea(confermaPrima: false) }
                        .buttonStyle(StileBlu())
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .disabled(stato.solaLettura)
        }
        .padding(m.margineModulo)
        .frame(width: m.modulo)
        .onAppear { proponi(d) }
    }

    static func testoDati(confermati c: Int, daControllare n: Int) -> String {
        let entrano = c == 1 ? "Entra 1 dato confermato." : "Entrano i \(c) dati confermati."
        guard n > 0 else { return entrano }
        return entrano + (n == 1 ? " 1 da controllare resta fuori." : " \(n) da controllare restano fuori.")
    }

    /// Canale e area iniziali: dal bersaglio collegato o, se non c'è, da quello suggerito, poi dal testo.
    private func proponi(_ d: Documento) {
        var posizione: Posizione?
        var prodotto: Prodotto?
        var candidati = stato.bersagli(d)
        if let s = stato.suggerimentoCollegamento(d) { candidati.append(s.0) }
        for b in candidati {
            switch b {
            case .posizione(let id):
                if posizione == nil { posizione = stato.dati.posizioni.first { $0.id == id } }
            case .prodotto(let id):
                if prodotto == nil { prodotto = stato.prodotto(id) }
            }
        }
        let proposti = MotoreDocumenti.canaleEArea(d, posizione: posizione, prodotto: prodotto)
        canale = proposti.canale
        area = proposti.area == .immobili || proposti.area.passivo ? .investimento : proposti.area
    }

    private func crea(confermaPrima: Bool) {
        TestiRinviati.scriviOra()
        stato.creaDaDocumento(documento.id, cosa: cosa, canale: canale, area: area, confermaPrima: confermaPrima)
        chiudi()
    }
}

// MARK: - Scheda «Dati»

/// La scheda leggibile di un documento: banner, sezioni (Chi, Che cosa, Cifre chiave, Costi, Rischio, Date) con la
/// fonte di ogni dato, i dati non trovati da aggiungere a mano e ciò che il documento ha già portato in Prisma.
struct SchedaDatiDocumento: View {
    @Environment(StatoShell.self) var stato
    let voce: MotoreDocumenti.Voce
    let mostraFonte: (Int, CampoDocumento) -> Void

    @State private var aggiungi: CampoDocumento?
    @State private var valoreNuovo = ""

    private var d: Documento { voce.documento }

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.Documenti.self
        let sezioni = MotoreDocumenti.scheda(d, cliente: stato.dati.clienti.first { $0.id == d.clienteId }, oggi: Date())
        let inLettura = stato.documentiInLettura.contains(d.id)
        VStack(alignment: .leading, spacing: m.spazioSezioni) {
            banner
            if inLettura {
                HStack(spacing: m.spazioBarra) {
                    ProgressView().controlSize(.small)
                    Text("Prisma sta leggendo il documento…")
                        .font(Tema.Apple.AltreApp.corpoPiccolo.fontLeggibile)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                }
            } else if sezioni.isEmpty && d.lettura != .illeggibile {
                NotaMetodo(testo: "Nessun dato riconosciuto: guarda il foglio e aggiungi qui sotto quelli che servono.")
            }
            ForEach(sezioni) { s in
                SezioneSchedaDocumento(documento: d, sezione: s, mostraFonte: mostraFonte)
            }
            mancanti
            portatoInPrisma
        }
    }

    // MARK: Banner

    @ViewBuilder private var banner: some View {
        let i = voce.indicatori
        if i.differenze > 0 {
            BannerDocumento(tono: .attenzione, simbolo: "exclamationmark.triangle.fill", testo: testoDifferenze(i.differenze),
                            pulsante: "Vedi il confronto") {
                stato.vistaDocumenti.scheda = .confronto
            }
        } else if !i.collegato, d.genere != .prisma, let s = stato.suggerimentoCollegamento(d), let n = stato.nomeBersaglio(s.0) {
            BannerDocumento(tono: .informazione, simbolo: "link", testo: testoSuggerimento(s.0, nome: n.nome),
                            pulsante: "Collega", attivo: !stato.solaLettura) {
                stato.collegaDocumento(d.id, a: s.0)
            }
        } else if i.daControllare > 0 {
            BannerDocumento(tono: .informazione, simbolo: "checkmark.circle", testo: testoDaControllare(i.daControllare),
                            pulsante: "Conferma tutti", attivo: !stato.solaLettura) {
                TestiRinviati.scriviOra()
                stato.confermaTutti(d.id)
            }
            .help("Solo i dati confermati entrano nel dossier: clic sul cerchio per confermarne uno, doppio clic sul valore per correggerlo.")
        } else if let n = clientiToccati, n > 0 {
            BannerDocumento(tono: .attenzione, simbolo: "person.2.fill",
                            testo: "Il KID è più rischioso o più caro: tocca \(n == 1 ? "1 cliente" : "\(n) clienti").",
                            pulsante: "Vedi chi") {
                stato.vistaDocumenti.scheda = .confronto
            }
        } else if d.lettura == .illeggibile {
            BannerDocumento(tono: .errore, simbolo: "exclamationmark.octagon",
                            testo: "Non sono riuscito a leggere il testo: prova con una scansione più nitida o con il PDF originale.",
                            pulsante: stato.urlDocumento(d) == nil ? nil : "Rileggi",
                            attivo: !stato.solaLettura && !stato.documentiInLettura.contains(d.id)) {
                stato.leggiDocumento(d.id)
            }
        }
    }

    private func testoDifferenze(_ n: Int) -> String {
        let con = MotoreDocumenti.delCliente(d) ? "con il dossier" : (voce.nomeCollegato.map { "con «\($0)»" } ?? "con il dossier")
        return n == 1 ? "1 cosa non torna \(con)." : "\(n) cose non tornano \(con)."
    }

    private func testoSuggerimento(_ b: BersaglioConfronto, nome: String) -> String {
        switch b {
        case .posizione:
            let cliente = stato.cliente(d.clienteId)?.nome
            return "Sembra la posizione «\(nome)»" + (cliente.map { " di \($0)." } ?? ".")
        case .prodotto:
            return "Sembra la scheda prodotto «\(nome)»."
        }
    }

    private func testoDaControllare(_ n: Int) -> String {
        n == 1 ? "1 dato da confermare" : "\(n) dati da confermare"
    }

    /// I clienti toccati da un KID più rischioso o più caro della scheda collegata (specifica 9).
    private var clientiToccati: Int? {
        guard d.genere == .kid else { return nil }
        for b in stato.bersagli(d) {
            guard case .prodotto = b, let c = stato.confronto(d, b), let e = stato.impatto(c) else { continue }
            return e.clienti.count
        }
        return nil
    }

    // MARK: Non trovati

    @ViewBuilder private var mancanti: some View {
        let m = Tema.Misura.Documenti.self
        let elenco = d.genere == .prisma ? [] : MotoreDocumenti.mancanti(d)
        if !elenco.isEmpty {
            VStack(alignment: .leading, spacing: m.spazioChip) {
                Text("Non trovati nel documento:")
                    .font(Tema.Apple.Carattere.secondario.fontLeggibile)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                DisposizioneAcapoRicerca(spazio: m.spazioChip) {
                    ForEach(elenco) { campo in
                        Button {
                            valoreNuovo = ""
                            aggiungi = campo
                        } label: {
                            Chip(testo: "+ \(campo.nome)")
                        }
                        .buttonStyle(StileSemplice())
                        .disabled(stato.solaLettura)
                        .help("Aggiungi il dato a mano")
                        .popover(isPresented: Binding(get: { aggiungi == campo }, set: { if !$0 { aggiungi = nil } }),
                                 arrowEdge: .bottom) {
                            popoverAggiungi(campo)
                        }
                    }
                }
            }
        }
    }

    private func popoverAggiungi(_ campo: CampoDocumento) -> some View {
        let m = Tema.Misura.Documenti.self
        let id = d.id
        return VStack(alignment: .leading, spacing: m.spazioBarra) {
            Text(campo.nome)
                .font(Tema.Apple.AltreApp.titoloRiga.fontLeggibile)
                .foregroundColor(Tema.Apple.Colore.inchiostro)
            HStack(spacing: m.spazioStatoRiga) {
                TextField(campo.data ? "gg/mm/aaaa" : "Valore", text: $valoreNuovo)
                    .campoTesto()
                    .frame(width: m.campoAggiungi)
                    .onSubmit { scrivi(campo, id) }
                if !campo.unita.isEmpty {
                    Text(campo.unita)
                        .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                }
            }
            HStack {
                Spacer(minLength: 0)
                Button { scrivi(campo, id) } label: { Label("Aggiungi", systemImage: "plus") }
                    .buttonStyle(StileBlu())
                    .disabled(valoreNuovo.trimmingCharacters(in: .whitespaces).isEmpty || stato.solaLettura)
            }
        }
        .padding(m.popover)
    }

    private func scrivi(_ campo: CampoDocumento, _ id: String) {
        stato.aggiungiCampo(id, campo, valore: valoreNuovo)
        valoreNuovo = ""
        aggiungi = nil
    }

    // MARK: Portato in Prisma

    @ViewBuilder private var portatoInPrisma: some View {
        let m = Tema.Misura.Documenti.self
        let elenchi: [(BersaglioConfronto, [VariazioneDossier])] = stato.bersagli(d).map { b in
            (b, stato.variazioni(b).filter { $0.documentoId == d.id })
        }
        .filter { !$0.1.isEmpty }
        if !elenchi.isEmpty {
            VStack(alignment: .leading, spacing: m.spazioNote) {
                Text("PORTATO IN PRISMA")
                    .font(Tema.Apple.AltreApp.etichettaPiccola.fontLeggibile)
                    .foregroundColor(Colori.Strumenti.occhiello)
                ForEach(Array(elenchi.enumerated()), id: \.offset) { _, e in
                    let b = e.0
                    if elenchi.count > 1, let n = stato.nomeBersaglio(b) {
                        Text("In «\(n.nome)»")
                            .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    }
                    ElencoVariazioni(variazioni: e.1, limite: 5,
                                     ripristinabile: { v in ripristinabile(v, in: b) },
                                     ripristina: { v in stato.ripristina(v.id, in: b) })
                }
            }
        }
    }

    private func ripristinabile(_ v: VariazioneDossier, in b: BersaglioConfronto) -> Bool {
        switch b {
        case .posizione(let id):
            guard let p = stato.dati.posizioni.first(where: { $0.id == id }) else { return false }
            return MotoreConfrontoDossier.ripristinabile(v, in: p)
        case .prodotto(let id):
            guard let p = stato.prodotto(id) else { return false }
            return MotoreConfrontoDossier.ripristinabile(v, in: p)
        }
    }
}

/// Una sezione della scheda in un riquadro: occhiello, righe dei dati (con la scala SRI) e le note della sezione.
private struct SezioneSchedaDocumento: View {
    let documento: Documento
    let sezione: MotoreDocumenti.SezioneScheda
    let mostraFonte: (Int, CampoDocumento) -> Void

    var body: some View {
        let m = Tema.Misura.Documenti.self
        VStack(alignment: .leading, spacing: 0) {
            Text(sezione.sezione.titolo.uppercased())
                .font(Tema.Apple.AltreApp.etichettaPiccola.fontLeggibile)
                .foregroundColor(Colori.Strumenti.occhiello)
                .padding(m.occhielloSezione)
            ForEach(sezione.righe) { r in
                RigaDatoDocumento(documento: documento, riga: r, mostraFonte: mostraFonte)
                if r.campo.chiave == .sri {
                    ScalaRischio(valore: Int(r.campo.valore.trimmingCharacters(in: .whitespaces).prefix(1)))
                        .padding(.leading, m.rigaDato.leading + m.spuntaDato + m.spazioRigaDato)
                        .padding(.bottom, m.spazioRigaDato)
                }
            }
            if !sezione.note.isEmpty {
                VStack(alignment: .leading, spacing: m.spazioNote) {
                    ForEach(Array(sezione.note.enumerated()), id: \.offset) { _, nota in
                        Text(nota)
                            .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(m.noteSezione)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .riquadroStrumento()
    }
}

/// Una riga della scheda: spunta, nome del dato sopra il valore leggibile (doppio clic o matita per correggerlo),
/// nota e fonte.
private struct RigaDatoDocumento: View {
    @Environment(StatoShell.self) var stato
    let documento: Documento
    let riga: MotoreDocumenti.RigaScheda
    let mostraFonte: (Int, CampoDocumento) -> Void

    @State private var modifica = false
    @State private var sopra = false

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.Documenti.self
        let c = riga.campo
        let id = documento.id
        let evidenziata = stato.vistaDocumenti.evidenzia == c.chiave
        HStack(alignment: .firstTextBaseline, spacing: m.spazioRigaDato) {
            Button {
                // Un valore appena corretto si conferma da solo: prima lui, poi la spunta che si vede
                TestiRinviati.scriviOra()
                stato.confermaCampo(id, c.chiave, !c.confermato)
            } label: {
                Image(systemName: c.confermato ? "checkmark.circle.fill" : "circle")
                    .font(Tema.Testo.Documenti.spunta)
                    .foregroundColor(c.confermato ? Tema.Colore.Documenti.confermato : Tema.Colore.Documenti.daControllare)
                    .frame(width: m.spuntaDato)
            }
            .buttonStyle(StileSemplice())
            .disabled(stato.solaLettura)
            .help(c.confermato ? "Confermato: clic per rimetterlo da controllare" : "Da controllare: clic per confermare")
            // Nel pannello snello il nome sta sopra il valore: il valore ha tutta la riga
            VStack(alignment: .leading, spacing: m.spazioEtichettaValore) {
                Text(c.chiave.nome)
                    .font(Tema.Testo.Documenti.etichettaDato)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
                if modifica {
                    // Il valore passa all'archivio (e si conferma) poco dopo l'ultimo tasto
                    TestoRinviato(testo: Binding(get: { stato.documento(id)?.campo(c.chiave)?.valore ?? c.valore },
                                                 set: { stato.modificaCampo(id, c.chiave, valore: $0) }),
                                  salvaOra: { stato.salvaOra() }) { bozza in
                        TextField("", text: bozza)
                            .font(Tema.Testo.Documenti.valore)
                            .campoTesto()
                            .onSubmit { modifica = false }
                    }
                    .id("\(id)-\(c.id)")
                } else {
                    Text(riga.testo)
                        .font(Tema.Testo.Documenti.valore)
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                        .fixedSize(horizontal: false, vertical: true)
                        .onTapGesture(count: 2) { if !stato.solaLettura { modifica = true } }
                }
                if let nota = riga.nota {
                    Text(nota)
                        .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if modifica {
                Button {
                    TestiRinviati.scriviOra()
                    modifica = false
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(Tema.Apple.Colore.accento)
                }
                .buttonStyle(StileSemplice())
                .help("Fine")
            } else if sopra && !stato.solaLettura {
                Button { modifica = true } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                }
                .buttonStyle(StileSemplice())
                .help("Correggi il valore: diventa confermato")
            }
            FonteDato(campo: c) { mostraFonte(c.pagina, c.chiave) }
        }
        .padding(m.rigaDato)
        .background {
            if evidenziata {
                FormaVetro.arrotondata(Tema.Raggio.Documenti.evidenza).fill(Tema.Colore.Documenti.evidenzia)
            }
        }
        // Scegliere un dato porta il foglio alla sua pagina e ne illumina la riga (senza ritardare il doppio clic)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            guard c.pagina > 0 else { return }
            stato.vistaDocumenti.pagina = c.pagina
            stato.vistaDocumenti.evidenzia = c.chiave
        })
        .onHover { sopra = $0 }
        .contextMenu {
            #if os(iOS)
            // Al tocco non c'è il passaggio del puntatore che mostra la matita: la correzione sta anche qui
            Button { modifica = true } label: { Label("Correggi il valore", systemImage: "pencil") }
                .disabled(stato.solaLettura || modifica)
            #endif
            Button("Togli questo dato") { stato.togliCampo(id, c.chiave) }
                .disabled(stato.solaLettura)
        }
    }
}

// MARK: - Confronto dei documenti del cliente

/// Identità e questionari contro il dossier e «In regola» (giro 4): stessa forma della tabella della specifica 9, con
/// i gettoni dell'app Documenti. Si aggiornano solo i dati confermati e scelti.
struct ConfrontoClienteVista: View {
    @Environment(StatoShell.self) var stato
    let documento: Documento
    var mostraFonte: (Int, CampoDocumento) -> Void = { _, _ in }

    /// Il canale scelto per un questionario che non lo dice da sé.
    @State private var canaleScelto: Canale?
    @State private var scelte: Set<CampoDocumento> = []
    @State private var sceltePer = ""

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.Documenti.self
        let d = stato.documento(documento.id) ?? documento
        let questionario = d.genere == .questionario
        let canaleLetto = MotoreDocumenti.canaleQuestionario(d)
        let canale = questionario ? (canaleLetto ?? canaleScelto) : nil
        let righe = stato.confrontoCliente(d, canale: canale) ?? []
        let nomeCanale: String = canale?.rawValue ?? "-"
        let firma: String = righe.map { r in "\(r.id)=\(r.esito)\(r.aggiornabile)" }.joined(separator: ",")
        let chiave: String = "\(d.id)|\(nomeCanale)|" + firma
        let valide = scelte.filter { c in righe.contains { $0.campo == c && $0.aggiornabile } }
        VStack(alignment: .leading, spacing: m.spazioConfronto) {
            TitoloStrumento(occhiello: "Documento contro dossier", titolo: "Dal documento al dossier",
                            testo: "Nel documento a sinistra, nel dossier a destra. Spunta ciò che vuoi aggiornare: il resto non cambia.")
            HStack(spacing: m.spazioBarra) {
                Text("Dossier di \(stato.cliente(d.clienteId)?.nome ?? "questo cliente")")
                    .font(Tema.Apple.Carattere.secondario.fontLeggibile)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                Button { stato.apriInRegola(d.clienteId) } label: {
                    HStack(spacing: Tema.Misura.Componenti.spazioSimboloPulsante) {
                        Text("In regola")
                        Image(systemName: "arrow.up.right")
                    }
                }
                .buttonStyle(StileCollegamento())
                .fixedSize()
                .help("Apri «In regola» nel dossier del cliente")
            }
            if questionario {
                if let c = canaleLetto {
                    HStack(spacing: m.spazioBarra) {
                        Text("Canale del questionario")
                            .font(Tema.Apple.Carattere.secondario.fontLeggibile)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        EtichettaCanale(canale: c)
                    }
                } else {
                    VStack(alignment: .leading, spacing: m.spazioStatoRiga) {
                        Text("Canale del questionario")
                            .font(Tema.Apple.Carattere.secondario.fontLeggibile)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        HStack(spacing: m.spazioBarra) {
                            SegmentiAnalisi(opzioni: [(Optional(Canale.alleanza), "Alleanza"), (Optional(Canale.indipendente), "Indipendente")],
                                            selezione: $canaleScelto)
                                .frame(maxWidth: m.menuArea)
                            if let c = canaleScelto { EtichettaCanale(canale: c) }
                        }
                    }
                }
            }
            if righe.isEmpty {
                NotaMetodo(testo: "Nessun dato da confrontare: conferma i dati nella scheda «Dati» o aggiungili a mano.")
            } else {
                tabella(righe, documento: d)
            }
            ForEach(Array(MotoreDocumenti.noteCliente(d).enumerated()), id: \.offset) { _, nota in
                Text(nota)
                    .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer(minLength: 0)
                Button {
                    TestiRinviati.scriviOra()
                    stato.aggiornaClienteDaDocumento(d.id, campi: valide, canale: canale)
                } label: {
                    Label(valide.count == 1 ? "Aggiorna 1 dato nel dossier" : "Aggiorna \(valide.count) dati nel dossier",
                          systemImage: "arrow.triangle.2.circlepath")
                }
                // Il blu del dettaglio è l'azione in alto: qui l'azione consigliata del pannello, in vetro dell'accento
                .buttonStyle(StileVetro(accento: true))
                .fixedSize()
                .disabled(valide.isEmpty || stato.solaLettura)
            }
        }
        .onAppear { preseleziona(righe, chiave: chiave) }
        .onChange(of: chiave) { nuova in preseleziona(righe, chiave: nuova) }
    }

    /// Le scelte ripartono quando cambiano documento, canale o righe: spuntate le righe diverse o nuove aggiornabili.
    private func preseleziona(_ righe: [MotoreDocumenti.RigaCliente], chiave: String) {
        guard sceltePer != chiave else { return }
        sceltePer = chiave
        scelte = Set(righe.filter { $0.aggiornabile && ($0.esito == .diverso || $0.esito == .nuovo) }.map(\.campo))
    }

    private func tabella(_ righe: [MotoreDocumenti.RigaCliente], documento d: Documento) -> some View {
        let m = Tema.Misura.Documenti.self
        return TabellaStrumento {
            CellaTesta(testo: "", larghezza: m.spuntaConfronto)
            CellaTesta(testo: "Dato", larghezza: m.colonnaDatoConfronto)
            CellaTesta(testo: "Nel documento")
            CellaTesta(testo: "Nel dossier")
            CellaTesta(testo: "Esito", larghezza: m.colonnaEsito, destra: true)
        } righe: {
            ForEach(Array(righe.enumerated()), id: \.element.id) { i, r in
                RigaStrumento(indice: i) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Button {
                                if scelte.contains(r.campo) { scelte.remove(r.campo) } else { scelte.insert(r.campo) }
                            } label: {
                                Image(systemName: scelte.contains(r.campo) && r.aggiornabile ? "checkmark.square.fill" : "square")
                                    .foregroundColor(r.aggiornabile ? Tema.Apple.Colore.accento : Tema.Apple.Colore.inchiostro3)
                                    .frame(width: m.spuntaConfronto)
                            }
                            .buttonStyle(StileSemplice())
                            .disabled(!r.aggiornabile || stato.solaLettura)
                            VStack(alignment: .leading, spacing: m.spazioTestiRiga) {
                                Text(r.etichetta)
                                    .font(Tema.Apple.AltreApp.titoloRiga.fontLeggibile)
                                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let c = d.campo(r.campo) {
                                    FonteDato(campo: c) { mostraFonte(c.pagina, c.chiave) }
                                }
                            }
                            .padding(Misure.Analisi.cellaMargine)
                            .frame(width: m.colonnaDatoConfronto, alignment: .leading)
                            Text(r.nelDocumento)
                                .font(Tema.Apple.AltreApp.corpoPiccolo.fontLeggibile)
                                .foregroundColor(r.esito == .diverso ? Tema.Colore.Documenti.diverso : Tema.Apple.Colore.inchiostro)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(Misure.Analisi.cellaMargine)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .leading, spacing: m.spazioTestiRiga) {
                                Text(r.nelDossier)
                                    .font(Tema.Apple.AltreApp.corpoPiccolo.fontLeggibile)
                                    .foregroundColor(Tema.Apple.Colore.inchiostro)
                                    .fixedSize(horizontal: false, vertical: true)
                                if r.esito == .nuovo {
                                    Text("da aggiungere")
                                        .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                                        .foregroundColor(Tema.Colore.Documenti.daAggiungere)
                                }
                            }
                            .padding(Misure.Analisi.cellaMargine)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Self.pillola(r.esito)
                                .padding(Misure.Analisi.cellaMargine)
                                .frame(width: m.colonnaEsito, alignment: .trailing)
                        }
                        if let nota = r.nota {
                            Text(nota)
                                .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                                .foregroundColor(Tema.Apple.Colore.inchiostro2)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(Misure.Analisi.cellaMargine)
                                .padding(.leading, m.spuntaConfronto)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    static func pillola(_ e: MotoreDocumenti.RigaCliente.Esito) -> Pillola {
        switch e {
        case .uguale: return Pillola(testo: "Uguale", tono: .ok)
        case .diverso: return Pillola(testo: "Diverso", tono: .attenzione)
        case .nuovo: return Pillola(testo: "Da aggiungere", tono: .neutro)
        case .indicativo: return Pillola(testo: "Da verificare", tono: .neutro)
        case .daConfermare: return Pillola(testo: "Da confermare", tono: .neutro)
        }
    }
}

// MARK: - Scheda «Testo»

/// Il testo letto, pagina per pagina (la stessa pagina dell'anteprima), con le righe dei dati letti evidenziate.
private struct SchedaTestoDocumento: View {
    @Environment(StatoShell.self) var stato
    let documento: Documento

    var body: some View {
        let _ = ContaCorpi.segna()
        let m = Tema.Misura.Documenti.self
        let pagine = stato.testoDocumento(documento)
        VStack(alignment: .leading, spacing: m.spazioSezioni) {
            if pagine.isEmpty {
                Text(stato.documentiInLettura.contains(documento.id) ? "Prisma sta leggendo il testo sul Mac…" : "Il testo non è ancora disponibile.")
                    .font(Tema.Apple.AltreApp.corpoPiccolo.fontLeggibile)
                    .foregroundColor(Tema.Apple.Colore.inchiostro2)
            } else {
                let n = min(max(stato.vistaDocumenti.pagina, 1), pagine.count)
                let qui = documento.campi.filter { $0.pagina == n }
                HStack(spacing: m.spazioPagine) {
                    PulsanteIcona(simbolo: "chevron.left", aiuto: "Pagina precedente", taglia: .compatta, vetro: false) {
                        stato.vistaDocumenti.pagina = n - 1
                    }
                    .disabled(n <= 1)
                    Text("Pagina \(n) di \(pagine.count)")
                        .font(Tema.Apple.AltreApp.titoloRiga.fontLeggibile)
                        .monospacedDigit()
                        .foregroundColor(Tema.Apple.Colore.inchiostro)
                    PulsanteIcona(simbolo: "chevron.right", aiuto: "Pagina successiva", taglia: .compatta, vetro: false) {
                        stato.vistaDocumenti.pagina = n + 1
                    }
                    .disabled(n >= pagine.count)
                    Spacer(minLength: 0)
                }
                if !qui.isEmpty {
                    Text("Su questa pagina: \(qui.map(\.chiave.nome).joined(separator: ", "))")
                        .font(Tema.Apple.AltreApp.nota.fontLeggibile)
                        .foregroundColor(Tema.Apple.Colore.inchiostro2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                let righe = pagine[n - 1].components(separatedBy: "\n")
                VStack(alignment: .leading, spacing: 0) {
                    if pagine[n - 1].isEmpty {
                        Text("(pagina vuota)")
                            .font(Tema.Testo.Strumenti.testoLetto)
                            .foregroundColor(Tema.Apple.Colore.inchiostro2)
                    }
                    ForEach(Array(righe.enumerated()), id: \.offset) { _, riga in
                        Text(riga.isEmpty ? " " : riga)
                            .font(Tema.Testo.Strumenti.testoLetto)
                            .foregroundColor(Tema.Apple.Colore.inchiostro)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                if qui.contains(where: { PaginaTestoDocumento.evidenziata(riga, estratto: $0.estratto) }) {
                                    FormaVetro.arrotondata(Tema.Raggio.Documenti.evidenza).fill(Tema.Colore.Documenti.evidenzia)
                                }
                            }
                    }
                }
                .textSelection(.enabled)
                .padding(m.riquadroTesto)
                .frame(maxWidth: .infinity, alignment: .leading)
                .riquadroStrumento()
            }
        }
    }
}
