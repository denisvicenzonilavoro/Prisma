#if os(macOS)
import AppKit
#endif
import SwiftUI

// Biblioteca · «Trova la pagina» (Design/template-luce-specifica.md §8.1.4-§8.1.6, «Luce» giro 6): le azioni.
// - la domanda: BM25 sui passi (fuori dal thread principale), poi Vera (Qwen sul Mac) risponde solo dai 6 passi e Prisma
//   verifica la frase; senza Qwen si apre la pagina più vicina con i passi evidenziati;
// - i documenti trascinati: copiati in Prisma/Biblioteca/, letti sul Mac (PDFKit, Vision), testo in `<id>.txt`;
// - «Mostra al cliente» (la pagina a tutto schermo, senza la risposta), «Copia la citazione»;
// - i sei fac-simile, caricati e tolti con i clienti di prova.
// Nessuna uscita dal Mac: a Qwen (127.0.0.1) vanno la domanda e i passi, mai dati dei clienti.

extension StatoShell {
    // MARK: - Domanda

    /// Cerca nella Biblioteca. `subito`: ricerca sincrona e niente Vera (istantanee e prove, con `applicaEsitoBiblioteca`).
    func chiediBiblioteca(_ testo: String, subito: Bool = false) {
        let domanda = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !domanda.isEmpty else { return }
        let t = trovaPagina
        t.compito?.cancel()
        t.compito = nil
        t.domanda = domanda
        t.aperta = nil
        t.cerca(domanda) { [weak self] trovati, indice in
            guard let self, t.domanda == domanda else { return }
            guard let primo = trovati.first else {
                t.risultato = RisultatoBiblioteca(domanda: domanda, stato: .nonTrovata, trovati: [], passo: nil,
                                                  pagineCercate: indice.pagine)
                return
            }
            t.risultato = RisultatoBiblioteca(domanda: domanda, stato: .cerca, trovati: trovati, passo: primo.passo,
                                              pagineCercate: indice.pagine)
            t.nuovoGiro()
            guard !subito, !self.rispostePreparate else { return }
            self.rispondiBiblioteca(domanda, trovati: trovati)
        }
    }

    /// Vera risponde dai passi (se Qwen è pronto; se l'ultima verifica non l'ha trovato, prima richiede a Ollama).
    private func rispondiBiblioteca(_ domanda: String, trovati: [PassoTrovato]) {
        let t = trovaPagina
        let documenti = biblioteca.tutti
        let passi = TrovaPaginaVera.passi(trovati, documenti: documenti)
        let nomi = dati.clienti.map(\.nome)
        let vera = dati.impostazioni.vera
        t.compito = Task { @MainActor in
            if self.generativo == nil {
                let d = await MotoreLocale.verificaDispositivo(vera)
                if self.disponibilitaLocale != d { self.disponibilitaLocale = d }
            }
            guard !Task.isCancelled, t.domanda == domanda else { return }
            guard self.generativo != nil else { return self.senzaVeraBiblioteca() }
            do {
                let esito = try await TrovaPaginaVera.chiedi(motore: self.qwen, vera: vera, domanda: domanda, passi: passi, nomiClienti: nomi)
                guard !Task.isCancelled, t.domanda == domanda else { return }
                self.applicaEsitoBiblioteca(esito)
            } catch {
                guard !Task.isCancelled, t.domanda == domanda else { return }
                self.senzaVeraBiblioteca()
            }
            t.compito = nil
        }
    }

    /// Qwen spento: la ricerca vale lo stesso, la pagina più vicina con i passi trovati evidenziati.
    func senzaVeraBiblioteca() {
        guard var r = trovaPagina.risultato else { return }
        r.stato = .senzaVera
        r.frase = nil
        r.risposta = nil
        r.avviso = r.passo.flatMap { MotoreBiblioteca.avvisoParametri($0.testo) }
        trovaPagina.risultato = r
    }

    /// La risposta di Vera, già verificata da `TrovaPaginaVera.leggi`.
    func applicaEsitoBiblioteca(_ esito: EsitoTrovaPagina) {
        guard var r = trovaPagina.risultato else { return }
        let prima = r.passo.map { "\($0.documentoId)#\($0.pagina)" }
        switch esito {
        case let .risposta(passo, frase, testo):
            r.stato = .risposta
            r.passo = passo
            r.frase = frase
            r.risposta = testo
            r.avviso = MotoreBiblioteca.avvisoParametri(passo.testo)
            r.vicini = []
        case .nonTrovata:
            r.stato = .nonTrovata
            r.vicini = MotoreBiblioteca.pagineVicine(r.trovati)
            r.passo = nil
            r.frase = nil
            r.risposta = nil
            r.avviso = nil
        case let .nonVerificata(passo, motivo):
            r.stato = .nonVerificata(motivo)
            r.passo = passo
            r.frase = nil
            r.risposta = nil
            r.avviso = MotoreBiblioteca.avvisoParametri(passo.testo)
        }
        trovaPagina.risultato = r
        // Un'altra pagina da raggiungere: il giro riparte
        if let p = r.passo, "\(p.documentoId)#\(p.pagina)" != prima { trovaPagina.nuovoGiro() }
    }

    /// Le domande di prova del template (con i fac-simile), oppure dalle intestazioni dei documenti dell'utente. In
    /// modalità cliente senza nomi (decisione 5).
    var suggerimentiBiblioteca: [String] {
        let documenti = biblioteca.tutti
        if documenti.contains(where: { $0.diProva == true }) {
            return ["Il riscatto nei primi anni ha penali?", "Quanto si deduce del fondo pensione?",
                    inModoCliente ? "Se il cliente non paga la temporanea?" : "Se Marco non paga la temporanea?"]
        }
        var visti = Set<String>()
        var r: [String] = []
        for p in trovaPagina.indice.passi where !p.intestazione.isEmpty {
            let rubrica = p.intestazioneVista.components(separatedBy: " · ").dropFirst().joined(separator: " · ")
            guard !rubrica.isEmpty, rubrica.count <= 40, visti.insert(rubrica.lowercased()).inserted else { continue }
            r.append("Cosa dicono i documenti su «\(rubrica)»?")
            if r.count == 3 { break }
        }
        return r
    }

    /// Dal pannello Novità: la Biblioteca sulla domanda (niente documento aperto davanti alla risposta).
    func apriBibliotecaTrovaPagina() {
        trovaPagina.aperta = nil
        apriApp(.biblioteca)
        trovaPagina.preparaIndice()
    }

    // MARK: - Documenti

    /// Il documento di un passo o di una pagina.
    func documentoBiblioteca(_ id: String) -> DocumentoBiblioteca? { biblioteca.tutti.first { $0.id == id } }

    /// Apre un documento intero nel vassoio (alla prima pagina, o a quella data).
    func apriDocumentoBiblioteca(_ id: String, pagina: Int = 1) {
        guard let d = documentoBiblioteca(id) else { return }
        trovaPagina.aperta = PaginaAperta(documentoId: id, pagina: min(max(1, pagina), max(1, d.numeroPagine)))
    }

    /// Torna dalla pagina aperta alla risposta (clic sulla chip della pagina).
    func tornaAllaRisposta() {
        trovaPagina.aperta = nil
    }

    /// I PDF e le immagini trascinati o scelti: copiati nella cartella della Biblioteca, letti sul Mac pagina per pagina
    /// (PDFKit, Vision per le scansioni) con l'avanzamento nella barra. Genere, canale ed edizione li propone Prisma.
    func importaInBiblioteca(_ urls: [URL]) {
        let t = trovaPagina
        let persistente = self.persistente
        for url in urls where LetturaDocumenti.estensioniAccettate.contains(url.pathExtension.lowercased()) {
            let nome = url.deletingPathExtension().lastPathComponent
            let lettura = LetturaBiblioteca(id: UUID().uuidString, nome: nome, lette: 0, totale: max(1, LetturaDocumenti.numeroPagine(url)))
            t.iniziaLettura(lettura)
            let dimensione = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
            StatoTrovaPagina.codaLettura.async {
                let file = "\(UUID().uuidString.prefix(8).lowercased())-\(url.lastPathComponent)"
                if persistente {
                    try? FileManager.default.createDirectory(at: StatoTrovaPagina.cartella, withIntermediateDirectories: true)
                    try? FileManager.default.copyItem(at: url, to: StatoTrovaPagina.cartella.appendingPathComponent(file))
                }
                let esito = LetturaDocumenti.leggi(url) { lette, totale in
                    DispatchQueue.main.async { t.avanza(lettura.id, lette: lette, totale: totale) }
                }
                DispatchQueue.main.async {
                    t.finisciLettura(lettura.id)
                    guard let esito else {
                        if persistente { try? FileManager.default.removeItem(at: StatoTrovaPagina.cartella.appendingPathComponent(file)) }
                        return self.mostraAvviso("Non riesco ad aprire «\(url.lastPathComponent)».")
                    }
                    self.aggiungiLettoInBiblioteca(titolo: nome, file: file, pagine: esito.pagine, pagineOCR: esito.pagineOCR,
                                                   dimensione: dimensione)
                }
            }
        }
    }

    /// Un documento letto entra nella Biblioteca. Le norme tengono anche gli articoli per «Il codice in tasca».
    @discardableResult
    func aggiungiLettoInBiblioteca(titolo: String, file: String, pagine: [String], pagineOCR: Int, dimensione: Int64?) -> DocumentoBiblioteca? {
        let leggibile = pagine.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= LetturaDocumenti.sogliaTesto }
        let inizio = pagine.prefix(3).joined(separator: "\n")
        let genere = PropostaBiblioteca.genere(inizio)
        let canale = PropostaBiblioteca.canale(inizio, genere: genere)
        let edizione = PropostaBiblioteca.edizione(inizio) ?? "importato il \(Formati.dataEstesa.string(from: Date()))"
        let d = biblioteca.aggiungi(titolo: titolo, sigla: "", edizione: edizione, file: file,
                                    pagine: genere == .normativa && leggibile ? pagine : [])
        biblioteca.aggiorna(d.id) { x in
            x.genere = genere
            x.canale = canale
            x.confermato = false
            x.pagine = pagine.count
            x.pagineOCR = pagineOCR
            x.dimensione = dimensione
            x.testo = leggibile ? "\(d.id).txt" : nil
        }
        if leggibile { trovaPagina.salvaTesto(d.id, pagine) }
        mostraAvviso(leggibile ? "«\(titolo)» è nella Biblioteca: \(pagine.count == 1 ? "1 pagina" : "\(pagine.count) pagine"). Conferma genere e canale."
                               : "«\(titolo)» è illeggibile: non posso cercarci dentro.")
        return documentoBiblioteca(d.id)
    }

    /// Genere e canale scelti dall'utente (o confermati così come li ha proposti Prisma).
    func classificaBiblioteca(_ id: String, genere: GenereBiblioteca? = nil, canale: Canale?? = nil) {
        guard let d = documentoBiblioteca(id) else { return }
        let nuovoGenere = genere ?? d.genereVisto
        let pagine = nuovoGenere == .normativa && d.articoli.isEmpty ? self.trovaPagina.pagine(d) : []
        biblioteca.aggiorna(id) { x in
            x.genere = nuovoGenere
            if let canale { x.canale = canale }
            if nuovoGenere.diRiferimento && canale == nil { x.canale = nil }
            x.confermato = true
            // Diventata normativa: gli articoli per «Il codice in tasca»
            if nuovoGenere == .normativa && x.articoli.isEmpty { x.articoli = NormeVera.articoli(pagine, testoId: id) }
        }
    }

    func collegaProdottoBiblioteca(_ id: String, prodotto: String?) {
        biblioteca.aggiorna(id) { $0.prodottoId = prodotto }
    }

    /// Toglie un documento (PDF, testo e voce dell'indice).
    func togliDallaBiblioteca(_ id: String) {
        trovaPagina.dimentica(id)
        biblioteca.elimina(id)
        if trovaPagina.aperta?.documentoId == id { trovaPagina.aperta = nil }
        if trovaPagina.risultato?.passo?.documentoId == id || trovaPagina.risultato?.trovati.contains(where: { $0.passo.documentoId == id }) == true {
            trovaPagina.risultato = nil
        }
    }

    #if os(macOS)
    func mostraNelFinderBiblioteca(_ id: String) {
        guard persistente, let d = documentoBiblioteca(id) else { return }
        let url = StatoTrovaPagina.cartella.appendingPathComponent(d.file)
        NSWorkspace.shared.activateFileViewerSelecting([FileManager.default.fileExists(atPath: url.path) ? url : StatoTrovaPagina.cartella])
    }

    /// «Aggiungi…»: il pannello per scegliere i PDF (o le immagini delle scansioni).
    func scegliDocumentiBiblioteca() {
        let p = NSOpenPanel()
        p.allowedContentTypes = [.pdf, .png, .jpeg, .tiff, .heic]
        p.allowsMultipleSelection = true
        p.prompt = "Aggiungi"
        p.message = "Scegli i PDF che usi (condizioni, KID, circolari, normativa): restano sul Mac, nella Biblioteca di Prisma."
        if p.runModal() == .OK { importaInBiblioteca(p.urls) }
    }
    #endif

    // MARK: - Citazione e cliente

    /// «Titolo», pagina N, Art. …: "frase".
    func citazioneBiblioteca() -> String? {
        guard let r = trovaPagina.risultato, let p = r.passo, let frase = r.frase, let d = documentoBiblioteca(p.documentoId) else { return nil }
        let articolo = p.intestazioneVista.isEmpty ? "" : ", \(p.intestazioneVista)"
        let edizione = d.edizione.isEmpty ? "" : " (\(d.edizione))"
        return "«\(d.titolo)»\(edizione), pagina \(p.pagina)\(articolo): \"\(frase)\""
    }

    func copiaCitazioneBiblioteca() {
        guard let c = citazioneBiblioteca(), let r = trovaPagina.risultato, let p = r.passo, let d = documentoBiblioteca(p.documentoId) else { return }
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(c, forType: .string)
        #endif
        mostraAvviso("Citazione copiata: «\(d.titolo)», pagina \(p.pagina)")
    }

    /// «Mostra al cliente»: la pagina a tutto schermo nella presentazione, carta bianca, la frase evidenziata e niente
    /// risposta di Vera (la frase del documento parla da sola). Esc chiude.
    func mostraBibliotecaAlCliente() {
        #if os(iOS)
        // L'impaginazione per la presentazione (DocumentoStampabile con formato) c'è solo sul Mac (TavoloMac.swift)
        mostraAvviso(StatoShell.soloSulMacPerOra)
        #else
        guard let r = trovaPagina.risultato, let p = r.passo, let d = documentoBiblioteca(p.documentoId) else { return }
        let pagine = trovaPagina.pagine(d)
        guard p.pagina - 1 < pagine.count else { return }
        let foglio = FoglioBiblioteca(documento: d, pagina: p.pagina, testo: pagine[p.pagina - 1], frase: r.frase,
                                      passi: r.passiEvidenziati.map(\.testo), avanzamento: 1)
        let doc = DocumentoStampabile(titolo: d.titolo, cliente: "pagina \(p.pagina)", genere: "Biblioteca",
                                      formato: Tema.Apple.Biblioteca.formatoPresentazione, pagine: [AnyView(foglio)], tipo: .altro)
        presenta(doc, delCliente: false)
        #endif
    }

    // MARK: - Collegamenti (§8.1.5.2 punto 6) ed edizioni (§8.1.6 punto 3)

    /// «C'è anche un'edizione più vecchia: …» sotto l'edizione della risposta (stesso prodotto, edizioni diverse).
    func avvisoEdizioneBiblioteca(_ d: DocumentoBiblioteca) -> String? {
        MotoreBiblioteca.avvisoEdizione(d, tra: biblioteca.tutti)
    }

    /// Il documento collegato a un prodotto, per «Condizioni nella Biblioteca» nella scheda di Prodotti. Solo sul Mac:
    /// la Biblioteca non va su iPhone e iPad (decisione 114).
    func condizioniInBiblioteca(_ prodottoId: String) -> DocumentoBiblioteca? {
        #if os(macOS)
        return MotoreBiblioteca.condizioniDelProdotto(prodottoId, tra: biblioteca.tutti)
        #else
        return nil
        #endif
    }

    /// «Condizioni nella Biblioteca»: la Biblioteca con il documento collegato aperto alla prima pagina.
    func apriCondizioniInBiblioteca(_ prodottoId: String) {
        guard let d = condizioniInBiblioteca(prodottoId) else { return }
        biblioteca.scelto = d.id
        apriApp(.biblioteca)
        trovaPagina.preparaIndice()
        apriDocumentoBiblioteca(d.id)
    }

    /// «Cerca nella Biblioteca» da Vera (app e scrivania): la stessa ricerca di «Trova la pagina», con la risposta e il
    /// collegamento alla pagina nella Biblioteca.
    /// `subito`: come in `chiediBiblioteca` (prove e istantanee, senza Qwen).
    func cercaNellaBiblioteca(_ domanda: String, subito: Bool = false) {
        apriApp(.biblioteca)
        trovaPagina.preparaIndice()
        chiediBiblioteca(domanda, subito: subito)
    }

    /// La domanda dell'ultima risposta di Vera, se parla di condizioni o normativa e la Biblioteca ha documenti in cui
    /// cercare: Vera propone «Cerca nella Biblioteca». Solo sul Mac (decisione 114); nil durante una risposta in corso.
    func domandaPerBiblioteca(in elenco: [MessaggioVera]) -> String? {
        #if os(macOS)
        guard !veraInCorso, let ultima = elenco.last, ultima.autore == .vera, elenco.count >= 2 else { return nil }
        let domanda = elenco[elenco.count - 2]
        guard domanda.autore == .utente else { return nil }
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        guard TrovaPaginaVera.proponeBiblioteca(domanda.testo, clienti: noti),
              biblioteca.tutti.contains(where: { !$0.illeggibile && ($0.testo != nil || !$0.articoli.isEmpty) }) else { return nil }
        return domanda.testo
        #else
        return nil
        #endif
    }

    // MARK: - Fac-simile di prova

    /// I sei fac-simile (Risorse/Biblioteca), con i clienti di prova di Impostazioni › Strumenti.
    func caricaEsempiBiblioteca() {
        let presenti = Set(biblioteca.tutti.filter { $0.diProva == true }.map(\.titolo))
        for e in EsempiBiblioteca.elenco where !presenti.contains(e.titolo) {
            guard let pagine = EsempiBiblioteca.pagine(e.risorsa) else { continue }
            let d = biblioteca.aggiungi(titolo: e.titolo, sigla: "", edizione: e.edizione, file: "esempio",
                                        pagine: e.genere == .normativa ? pagine : [])
            biblioteca.aggiorna(d.id) { x in
                x.file = "\(d.id).txt"
                x.testo = "\(d.id).txt"
                x.genere = e.genere
                x.canale = e.canale
                x.confermato = true
                x.pagine = pagine.count
                x.pagineOCR = 0
                x.diProva = true
            }
            trovaPagina.salvaTesto(d.id, pagine)
        }
        biblioteca.scelto = nil
    }

    func togliEsempiBiblioteca() {
        for d in biblioteca.tutti where d.diProva == true { togliDallaBiblioteca(d.id) }
    }
}

extension StatoShell {
    /// Le cartelle dell'archivio che restano fuori dai backup («Escludi la Biblioteca dal backup», Impostazioni › Archivio).
    var cartelleEscluseBackup: [String] {
        dati.impostazioni.backup.escludiBiblioteca == true ? GestoreBackup.cartelleEscludibili : []
    }

    /// La misura della cartella della Biblioteca (PDF e testi), per Impostazioni › Archivio.
    static func misuraBiblioteca() -> Int64 {
        let fm = FileManager.default
        guard let elenco = fm.enumerator(at: StatoBiblioteca.cartella, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var totale: Int64 = 0
        for case let url as URL in elenco {
            totale += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return totale
    }
}
