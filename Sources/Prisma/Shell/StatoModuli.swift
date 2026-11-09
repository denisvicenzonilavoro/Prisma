import Foundation
import PDFKit
import CoreGraphics

// Pratiche › Moduli · «Compila da solo» nello stato di Prisma (Design/template-luce-specifica.md §7.2, «Luce» giro 10).
// I modelli stanno in Prisma/Moduli/ (ArchivioModuli), fuori dall'archivio e da «Prisma ovunque»; nelle prove e nelle
// istantanee restano in memoria. La compilazione è un'anteprima: il PDF compilato entra nei Documenti del cliente solo con
// «Salva nel dossier», e al cliente esce solo con la password dei PDF (decisione 13). «Sì, chiediglielo» prepara una bozza
// in Messaggi con i soli nomi dei dati che mancano: niente parte da solo.

@Observable final class StatoModuli {
    private(set) var modelli: [ModelloModulo] = []
    /// Il modello mostrato (nil = il primo).
    var scelto: String?
    var pagina = 0
    /// Il cliente da compilare (nil = il cliente attivo).
    var clienteId: String?
    /// La proposta a cui si riferisce il modulo (nil = la più recente del canale del modulo).
    var posizioneId: String?
    /// La compilazione in corso: un'anteprima, finché non si salva.
    var anteprima: AnteprimaCompilazione?
    /// I valori scritti a mano in questa compilazione (non cambiano il dossier, salvo «Aggiorna anche il dossier»).
    var correzioni: [String: String] = [:]
    /// Cresce a ogni «Compila»: riparte la scrittura dei campi.
    var giro = 0
    /// La casella che si sta correggendo a mano.
    var inModifica: String?
    /// Cliente e modello a cui appartengono anteprima e correzioni («cliente|modello»).
    @ObservationIgnored var compilazionePer: String?
    /// «Sì, chiediglielo» fatto per questa compilazione.
    var richiestaPronta = false
    /// La revisione della mappa dei campi in corso (una copia del modello, salvata con «Conferma la mappa»).
    var revisione: ModelloModulo?
    var campoRevisione: String?
    /// «Aggiungi una casella»: il prossimo clic sulla pagina mette una casella.
    var aggiungiCasella = false
    var veraInCorso = false
    /// Un PDF trascinato sopra la barra o la zona di rilascio.
    var rilascioAttivo = false

    let persistente: Bool
    /// Solo istantanee: l'aspetto con Vera pronta (sfera viva) o no.
    @ObservationIgnored var veraProntaIstantanea: Bool?
    @ObservationIgnored private var caricata = false
    @ObservationIgnored private var pdfInMemoria: [String: Data] = [:]
    @ObservationIgnored private var immagini: [String: CGImage] = [:]
    /// I riquadri delle pagine già letti (il body della pagina non riapre il PDF a ogni ridisegno).
    @ObservationIgnored private var riquadri: [String: CGRect] = [:]
    private static let coda = DispatchQueue(label: "prisma.moduli", qos: .userInitiated)

    init(persistente: Bool) { self.persistente = persistente }

    /// Aspetta le scritture in coda.
    static func attendiScritture() { coda.sync {} }

    /// Dopo un ripristino: rilegge i modelli dalla cartella ripristinata.
    func ricarica() {
        Self.coda.sync {}
        caricata = false
        modelli = []
        immagini = [:]
        riquadri = [:]
        azzeraCompilazione()
        revisione = nil
        scelto = nil
        carica()
    }

    /// Legge l'elenco dei modelli la prima volta. Si chiama all'apertura delle viste (onAppear) e dalle azioni, mai
    /// dentro un body: cambia la proprietà osservata `modelli`.
    func carica() {
        guard !caricata else { return }
        caricata = true
        guard persistente else { return }
        modelli = ArchivioModuli.leggi(in: Archivio.cartella)
    }

    private func salva() {
        guard persistente else { return }
        let elenco = modelli
        Self.coda.async { try? ArchivioModuli.scrivi(elenco, in: Archivio.cartella) }
    }

    /// I modelli già letti (senza leggere il disco: lo fa `carica()`).
    var tutti: [ModelloModulo] { modelli }

    var modelloScelto: ModelloModulo? {
        let t = tutti
        return t.first { $0.id == scelto } ?? t.first
    }

    func modello(_ id: String) -> ModelloModulo? { tutti.first { $0.id == id } }

    /// Il PDF vuoto di un modello.
    func pdf(_ m: ModelloModulo) -> Data? {
        if let d = pdfInMemoria[m.id] { return d }
        guard persistente else { return nil }
        return try? Data(contentsOf: ArchivioModuli.pdf(m, in: Archivio.cartella))
    }

    /// La pagina disegnata (larga `larghezza` pixel), tenuta in memoria per le ultime pagine viste.
    func immagine(_ m: ModelloModulo, pagina: Int, larghezza: CGFloat) -> CGImage? {
        let chiave = "\(m.id)-\(pagina)-\(Int(larghezza))"
        if let i = immagini[chiave] { return i }
        guard let d = pdf(m) else { return nil }
        let i: CGImage? = autoreleasepool {
            guard let doc = PDFDocument(data: d), let p = doc.page(at: pagina) else { return nil }
            return Self.disegna(p, larghezza: larghezza)
        }
        // Al più quattro pagine in memoria (Mac con 8 GB)
        if immagini.count >= 4 { immagini.removeAll() }
        immagini[chiave] = i
        return i
    }

    /// Il riquadro della pagina in punti PDF.
    func riquadroPagina(_ m: ModelloModulo, pagina: Int) -> CGRect {
        let chiave = "\(m.id)-\(pagina)"
        if let r = riquadri[chiave] { return r }
        let r: CGRect = autoreleasepool {
            guard let d = pdf(m), let p = PDFDocument(data: d)?.page(at: pagina) else { return CGRect(origin: .zero, size: FacSimileModulo.formato) }
            return p.bounds(for: .mediaBox)
        }
        riquadri[chiave] = r
        return r
    }

    static func disegna(_ pagina: PDFPage, larghezza: CGFloat) -> CGImage? {
        let b = pagina.bounds(for: .mediaBox)
        guard b.width > 0, let spazio = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let s = larghezza / b.width
        let w = Int(b.width * s), h = Int(b.height * s)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: spazio,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.scaleBy(x: s, y: s)
        ctx.translateBy(x: -b.minX, y: -b.minY)
        pagina.draw(with: .mediaBox, to: ctx)
        return ctx.makeImage()
    }

    /// Aggiunge un modello con il suo PDF (nella cartella Moduli/, o in memoria nelle prove e nelle istantanee).
    func aggiungi(_ m: ModelloModulo, pdf: Data) {
        carica()
        modelli.removeAll { $0.id == m.id }
        modelli.append(m)
        if persistente {
            let url = ArchivioModuli.pdf(m, in: Archivio.cartella)
            Self.coda.async {
                try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? pdf.write(to: url, options: Archivio.opzioniScrittura)
            }
        } else {
            pdfInMemoria[m.id] = pdf
        }
        salva()
    }

    func aggiorna(_ m: ModelloModulo) {
        carica()
        guard let i = modelli.firstIndex(where: { $0.id == m.id }) else { return }
        modelli[i] = m
        salva()
    }

    func togli(_ id: String) {
        carica()
        guard let m = modelli.first(where: { $0.id == id }) else { return }
        modelli.removeAll { $0.id == id }
        pdfInMemoria[id] = nil
        immagini = immagini.filter { !$0.key.hasPrefix(id) }
        riquadri = riquadri.filter { !$0.key.hasPrefix(id) }
        if scelto == id { scelto = nil; azzeraCompilazione() }
        if persistente {
            let url = ArchivioModuli.pdf(m, in: Archivio.cartella)
            Self.coda.async { try? FileManager.default.removeItem(at: url) }
        }
        salva()
    }

    func azzeraCompilazione() {
        compilazionePer = nil
        anteprima = nil
        correzioni = [:]
        inModifica = nil
        richiestaPronta = false
    }
}

// MARK: - Nello stato di Prisma

extension StatoShell {
    /// Il cliente da compilare: quello scelto in «Compila per», altrimenti il cliente attivo.
    var clienteModulo: Cliente? {
        if let id = moduli.clienteId, let c = cliente(id) { return c }
        return clienteAttivo
    }

    /// I clienti come chip in «Compila per»: il cliente attivo, quello scelto e quelli con proposte aperte, al più 5.
    var clientiRecentiModulo: [Cliente] {
        var ids: [String] = []
        for id in [moduli.clienteId, clienteAttivo?.id].compactMap({ $0 }) where !ids.contains(id) { ids.append(id) }
        let conProposte = dati.posizioni.filter { $0.stato == .proposta && $0.esito != .rifiutata }
            .sorted { $0.creataIl > $1.creataIl }.map(\.clienteId)
        for id in conProposte where !ids.contains(id) { ids.append(id) }
        for c in dati.clienti where !ids.contains(c.id) { ids.append(c.id) }
        return ids.prefix(Self.chipModuli).compactMap { cliente($0) }
    }

    static let chipModuli = 5

    /// Le proposte del cliente nel canale del modulo (la più recente prima).
    func proposteModulo(_ c: Cliente, _ m: ModelloModulo) -> [Posizione] {
        dati.posizioni.filter { $0.clienteId == c.id && $0.stato == .proposta && $0.esito != .rifiutata
            && (m.canale == nil || $0.canale == m.canale) }
            .sorted { $0.creataIl > $1.creataIl }
    }

    /// Le fonti della compilazione: anagrafica, scheda fiscale, documento, la proposta, i dati del consulente.
    func fonteModulo(_ c: Cliente, _ m: ModelloModulo, oggi: Date = Date()) -> FonteCompilazione {
        let proposte = proposteModulo(c, m)
        let p = proposte.first { $0.id == moduli.posizioneId } ?? proposte.first
        let f = dati.impostazioni.studio.fatturazione
        let consulente = [f.nome, f.cognome].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
        return FonteCompilazione(cliente: c, posizione: p, prodotto: p?.prodottoId.flatMap { id in dati.prodotti.first { $0.id == id } },
                                 consulente: consulente, comuneConsulente: f.sede.comune, oggi: oggi,
                                 conservaIban: dati.impostazioni.pratiche.ibanConservato)
    }

    /// L'anteprima di adesso, solo se è del cliente e del modello mostrati: cambiato il cliente attivo (o tolto quello
    /// di «Compila per»), l'anteprima di prima non si mostra, non si salva nel dossier e non va al cliente.
    var anteprimaModulo: AnteprimaCompilazione? {
        guard let a = moduli.anteprima, let c = clienteModulo, let m = moduli.modelloScelto,
              a.clienteId == c.id, a.modelloId == m.id else { return nil }
        return a
    }

    /// Le correzioni a mano valgono per un cliente e un modello: con un altro si riparte da capo.
    private func allineaCompilazione(_ c: Cliente, _ m: ModelloModulo) {
        let chiave = "\(c.id)|\(m.id)"
        guard moduli.compilazionePer != chiave else { return }
        moduli.azzeraCompilazione()
        moduli.compilazionePer = chiave
    }

    /// Vera è pronta per il riquadro dei dati che mancano (sfera viva) e per la revisione della mappa.
    var veraPerModuli: Bool { moduli.veraProntaIstantanea ?? (generativo != nil) }

    // MARK: Scelte

    func scegliModulo(_ id: String) {
        guard moduli.scelto != id else { return }
        moduli.scelto = id
        moduli.pagina = 0
        moduli.azzeraCompilazione()
    }

    func scegliClienteModulo(_ id: String) {
        guard moduli.clienteId != id || moduli.anteprima != nil else { return }
        moduli.clienteId = id
        moduli.posizioneId = nil
        moduli.azzeraCompilazione()
    }

    func scegliPropostaModulo(_ id: String?) {
        moduli.posizioneId = id
        if anteprimaModulo != nil { compilaModulo() }
    }

    func paginaModulo(_ delta: Int) {
        guard let m = moduli.modelloScelto else { return }
        moduli.pagina = min(max(0, moduli.pagina + delta), max(0, m.pagine - 1))
    }

    // MARK: Compilazione

    /// «✦ Compila con i dati di …»: l'anteprima con tutto ciò che Prisma sa riempire, i mancanti e le firme.
    func compilaModulo() {
        moduli.carica()
        guard let m = moduli.modelloScelto, m.compilabile, let c = clienteModulo else { return }
        // La mappa si controlla una volta prima di compilare (decisione 61)
        guard m.mappaConfermata else {
            mostraAvviso("Controlla prima la mappa dei campi di «\(m.titolo)»")
            avviaRevisioneModulo(m.id)
            return
        }
        allineaCompilazione(c, m)
        moduli.anteprima = CompilatoreModuli.anteprima(m, fonte: fonteModulo(c, m), correzioni: moduli.correzioni)
        moduli.giro += 1
        moduli.inModifica = nil
        moduli.richiestaPronta = false
    }

    /// Una casella corretta a mano: vale solo per questo modulo compilato.
    func correggiCampoModulo(_ campoId: String, _ testo: String) {
        let t = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let m = moduli.modelloScelto, m.mappaConfermata, let c = clienteModulo, anteprimaModulo != nil else {
            moduli.inModifica = nil
            return
        }
        moduli.correzioni[campoId] = t.isEmpty ? nil : t
        moduli.inModifica = nil
        moduli.anteprima = CompilatoreModuli.anteprima(m, fonte: fonteModulo(c, m), correzioni: moduli.correzioni)
    }

    /// La casella si può riportare nel dossier («Aggiorna anche il dossier»): dato strutturato, IBAN solo se conservato.
    func campoAggiornabileModulo(_ campo: ModelloModulo.Campo) -> Bool {
        guard !solaLettura, let d = campo.dato, CompilatoreModuli.aggiornabile(d) else { return false }
        return d != .iban || dati.impostazioni.pratiche.ibanConservato
    }

    /// Il valore che il dossier ha oggi per una casella (per la conferma «da … a …»), nil se manca.
    func valoreDossierModulo(_ campo: ModelloModulo.Campo) -> String? {
        guard let d = campo.dato, let m = moduli.modelloScelto, let c = clienteModulo else { return nil }
        return CompilatoreModuli.valore(d, fonteModulo(c, m))
    }

    /// «Aggiorna anche il dossier», dopo la conferma: il valore corretto entra nel dossier del cliente (o nella proposta,
    /// per beneficiari e numero di contratto) e la casella torna a leggere il dossier. false se il valore non si riporta.
    @discardableResult
    func aggiornaDossierDaModulo(_ campoId: String, _ testo: String) -> Bool {
        guard !solaLettura, let m = moduli.modelloScelto, let campo = m.campi.first(where: { $0.id == campoId }), let d = campo.dato,
              let c = clienteModulo, let i = dati.clienti.firstIndex(where: { $0.id == c.id }) else { return false }
        var cliente = dati.clienti[i]
        let prima = fonteModulo(c, m).posizione
        var posizione = prima
        guard CompilatoreModuli.aggiornaDossier(d, testo: testo, cliente: &cliente, posizione: &posizione,
                                                conservaIban: dati.impostazioni.pratiche.ibanConservato) else {
            mostraAvviso("Questo valore resta solo nel modulo: il dossier non lo può prendere così.")
            return false
        }
        if cliente != dati.clienti[i] { dati.clienti[i] = cliente }
        if let posizione, posizione != prima { salvaPosizione(posizione) }
        // La casella ora legge il dossier: la correzione a mano non serve più
        moduli.correzioni[campoId] = nil
        moduli.inModifica = nil
        moduli.anteprima = CompilatoreModuli.anteprima(m, fonte: fonteModulo(c, m), correzioni: moduli.correzioni)
        mostraAvviso("Dossier di \(Self.nomeDiBattesimo(c)) aggiornato: \(d.nomeInFrase).")
        return true
    }

    /// «Lo scrivo io»: apre la casella del primo dato che manca (o di quello dato).
    func scriviDatoModulo(_ dato: DatoModulo? = nil) {
        guard let a = anteprimaModulo else { return }
        let campo = a.mancanti.first { dato == nil || $0.dato == dato }
        guard let campo else { return }
        if let m = moduli.modelloScelto, campo.pagina != moduli.pagina, campo.pagina < m.pagine { moduli.pagina = campo.pagina }
        moduli.inModifica = campo.id
    }

    /// «Sì, chiediglielo»: la bozza in Messaggi con i nomi dei dati che mancano. `apri`: false lascia Pratiche davanti.
    func chiediDatiModulo(apri: Bool = true) {
        guard let m = moduli.modelloScelto, let c = clienteModulo, let a = anteprimaModulo,
              let o = CompilatoreModuli.occasioneDatiMancanti(cliente: c, modello: m, dati: a.datiMancanti, oggi: Date()) else { return }
        moduli.richiestaPronta = true
        if apri {
            preparaMessaggio(clienteId: c.id, occasione: o)
            mostraAvviso("Messaggio a \(Self.nomeDiBattesimo(c)) pronto in Messaggi")
        } else {
            occasioniSuRichiesta.removeAll { $0.id == o.id }
            occasioniSuRichiesta.insert(o, at: 0)
        }
    }

    /// Il PDF compilato dell'anteprima (nil se manca il PDF o la compilazione).
    func pdfModuloCompilato() -> Data? {
        guard let m = moduli.modelloScelto, let a = anteprimaModulo, let vuoto = moduli.pdf(m) else { return nil }
        return CompilatoreModuli.scrivi(m, pdf: vuoto, anteprima: a)
    }

    /// «Salva nel dossier»: il PDF compilato nei Documenti del cliente, con i dati che mancavano e le firme da raccogliere.
    func salvaModuloNelDossier() {
        guard !solaLettura else {
            mostraAvviso(TestiSeguito.solaLettura)
            return
        }
        guard let m = moduli.modelloScelto, let c = clienteModulo, let a = anteprimaModulo, let pdf = pdfModuloCompilato() else {
            mostraAvviso("Non riesco a scrivere il modulo compilato.")
            return
        }
        let comp = CompilazioneModulo(modelloId: m.id, titoloModello: m.titolo, compilatoIl: Appuntamento.alMinuto(Date()),
                                      mancanti: a.datiMancanti, firme: a.firme.count,
                                      correzioni: a.valori.values.filter(\.aMano).count)
        let posizione = fonteModulo(c, m).posizione
        // Il titolo dice anche la proposta: lo stesso modulo per un'altra proposta è un altro documento
        let titolo = "Modulo · \(m.titolo)" + (posizione.map { " · \($0.nome)" } ?? "")
        guard archiviaPDF(pdf, titolo: titolo, tipo: .modulo, cliente: c.id, posizioneId: posizione?.id, modulo: comp) != nil else { return }
        mostraAvviso("Modulo salvato nei Documenti di \(Self.nomeDiBattesimo(c))")
    }

    /// «Dai al cliente…»: il PDF compilato da salvare con la password dei PDF per il cliente (decisione 13).
    func moduloPerCliente() -> PDFDaSalvare? {
        guard let m = moduli.modelloScelto, let c = clienteModulo, let pdf = pdfModuloCompilato() else { return nil }
        return PDFDaSalvare(dati: pdf, nome: "\(m.titolo) · \(c.nome).pdf", cliente: c)
    }

    /// Il nome di battesimo per i pulsanti («Compila con i dati di Giulia»): la scheda fiscale, altrimenti la prima parola.
    static func nomeDiBattesimo(_ c: Cliente) -> String {
        if let n = c.fiscale?.nome.trimmingCharacters(in: .whitespaces), !n.isEmpty { return n }
        return c.nome.split(separator: " ").first.map(String.init) ?? c.nome
    }

    /// Il prossimo appuntamento del cliente per le firme (preferendo quelli di firma).
    func appuntamentoFirma(_ c: Cliente, oggi: Date = Date()) -> Appuntamento? {
        let futuri = dati.appuntamenti.filter { $0.clienteId == c.id && $0.inizio >= Calendar.current.startOfDay(for: oggi) && $0.stato == .pianificato }
            .sorted { $0.inizio < $1.inizio }
        return futuri.first { $0.tipo == .firma } ?? futuri.first
    }

    // MARK: Caricare un modulo

    /// Carica i PDF scelti o trascinati: riconosce i campi e apre la revisione della mappa dell'ultimo.
    func importaModuli(_ urls: [URL]) {
        guard !solaLettura else {
            mostraAvviso(TestiSeguito.solaLettura)
            return
        }
        for url in urls where url.pathExtension.lowercased() == "pdf" {
            let accesso = url.startAccessingSecurityScopedResource()
            defer { if accesso { url.stopAccessingSecurityScopedResource() } }
            guard let dati = try? Data(contentsOf: url) else {
                mostraAvviso("Non riesco a leggere questo PDF")
                continue
            }
            let nome = url.deletingPathExtension().lastPathComponent
            importaModulo(dati, nome: nome)
        }
    }

    /// Un PDF vuoto diventa un modello (canale indipendente: decisione 60) e si apre la revisione della mappa.
    @discardableResult
    func importaModulo(_ pdf: Data, nome: String, diProva: Bool = false) -> ModelloModulo? {
        guard let doc = PDFDocument(data: pdf), !doc.isLocked else {
            mostraAvviso("Non riesco a leggere questo PDF")
            return nil
        }
        let testo = doc.page(at: 0)?.string ?? ""
        let tipo = Self.tipoModulo(nome + " " + testo)
        let e = RiconoscitoreModulo.riconosci(doc, tipo: tipo)
        guard !e.illeggibile else {
            mostraAvviso("Non riesco a leggere questo PDF")
            return nil
        }
        let campi = diProva ? e.campi.map { var c = $0; c.daConfermare = false; return c } : e.campi
        let titoloPDF = (doc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String)?.trimmingCharacters(in: .whitespaces)
        let id = "modulo-\(UUID().uuidString.prefix(8).lowercased())"
        let m = ModelloModulo(id: id, titolo: (titoloPDF?.isEmpty == false ? titoloPDF : nil) ?? nome, tipo: tipo, file: "\(id).pdf",
                              pagine: e.pagine, campi: campi, caricatoIl: Appuntamento.alMinuto(Date()), versione: e.versione,
                              mappaConfermata: diProva, diProva: diProva ? true : nil)
        moduli.aggiungi(m, pdf: pdf)
        moduli.scelto = m.id
        moduli.pagina = 0
        moduli.azzeraCompilazione()
        if !diProva { avviaRevisioneModulo(m.id) }
        return m
    }

    /// Il tipo del modulo dalle parole del nome e della prima pagina (l'utente lo cambia nella revisione).
    static func tipoModulo(_ testo: String) -> TipoModulo {
        let t = RiconoscitoreModulo.normalizza(testo)
        // Nel dubbio vince l'adeguata verifica: compila meno (solo anagrafica e documento, decisione 62)
        let antiriciclaggio = ["adeguata verifica", "antiriciclaggio", "verifica della clientela", "identificazione della clientela",
                               "titolare effettivo", "titolari effettivi", "politicamente esposta", "politicamente esposte",
                               "origine dei fondi"]
        if antiriciclaggio.contains(where: { t.contains($0) }) { return .adeguataVerifica }
        if t.contains("questionario") { return .questionarioAdeguatezza }
        if t.contains("mandato") { return .mandato }
        if t.contains("privacy") || t.contains("trattamento dei dati") { return .privacy }
        if t.contains("proposta") || t.contains("polizza") { return .propostaPolizza }
        return .altro
    }

    // MARK: Revisione della mappa

    func avviaRevisioneModulo(_ id: String) {
        moduli.carica()
        guard let m = moduli.modello(id) else { return }
        moduli.scelto = id
        moduli.revisione = m
        moduli.campoRevisione = m.campi.first?.id
        moduli.aggiungiCasella = false
        moduli.pagina = 0
        moduli.azzeraCompilazione()
        if schedaPratiche != .moduli || appAttiva != .pratiche { apriPratiche(.moduli) }
    }

    /// Cambia il dato di una casella nella revisione: un dato, «lascia vuota» (nil) o «risposta del cliente».
    func associaCampoRevisione(_ campoId: String, dato: DatoModulo?, risposta: Bool = false, firma: Bool = false) {
        guard var r = moduli.revisione, let i = r.campi.firstIndex(where: { $0.id == campoId }) else { return }
        // Sui moduli con le risposte del cliente solo anagrafica e documento (decisione 62)
        let ammesso = dato.map { !r.tipo.risposteDelCliente || $0.anagrafico } ?? true
        // Una casella da spuntare resta una casella senza dato: Prisma non la spunta mai (scelte e consensi del cliente)
        let casella = r.campi[i].tipo == .casella && !firma
        r.campi[i].dato = risposta || firma || !ammesso || casella ? nil : dato
        r.campi[i].risposta = risposta || (!ammesso && !casella)
        r.campi[i].tipo = casella ? .casella : (firma ? .firma : (dato?.tipoCampo ?? (r.campi[i].tipo == .firma ? .testo : r.campi[i].tipo)))
        r.campi[i].daConfermare = false
        if r.campi[i].origine == .vera { r.campi[i].origine = .mano }
        moduli.revisione = r
    }

    func cambiaTipoRevisione(_ tipo: TipoModulo) {
        guard var r = moduli.revisione else { return }
        r.tipo = tipo
        r.campi = r.campi.map { RiconoscitoreModulo.applicaTipo($0, tipo) }
        moduli.revisione = r
    }

    func rinominaRevisione(_ titolo: String) {
        let t = titolo.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        moduli.revisione?.titolo = t
    }

    /// «Aggiungi una casella»: una casella segnata a mano nel punto toccato della pagina (punti PDF).
    func aggiungiCasellaRevisione(pagina: Int, punto: CGPoint) {
        guard var r = moduli.revisione else { return }
        let s = Tema.Apple.Pratiche.Moduli.casellaAMano
        let c = ModelloModulo.Campo(pagina: pagina, riquadro: CGRect(x: punto.x, y: punto.y - s.height, width: s.width, height: s.height),
                                    etichetta: "Casella \(r.campi.count + 1)", origine: .mano)
        r.campi.append(c)
        moduli.revisione = r
        moduli.campoRevisione = c.id
        moduli.aggiungiCasella = false
    }

    func togliCasellaRevisione(_ id: String) {
        moduli.revisione?.campi.removeAll { $0.id == id }
        if moduli.campoRevisione == id { moduli.campoRevisione = moduli.revisione?.campi.first?.id }
    }

    /// «Conferma la mappa»: tutte le caselle controllate, il modello pronto da compilare.
    func confermaRevisioneModulo() {
        guard var r = moduli.revisione else { return }
        r.mappaConfermata = true
        r.campi = r.campi.map { var c = $0; c.daConfermare = false; return c }
        moduli.aggiorna(r)
        moduli.revisione = nil
        moduli.aggiungiCasella = false
        mostraAvviso("Mappa di «\(r.titolo)» confermata: il modulo è pronto da compilare")
    }

    func annullaRevisioneModulo() {
        moduli.revisione = nil
        moduli.aggiungiCasella = false
    }

    /// «Chiedi a Vera»: le etichette che le regole non hanno riconosciuto, solo il testo del modulo vuoto (decisione 54).
    func chiediAVeraModulo() {
        guard let r = moduli.revisione else { return }
        let etichette = RiconoscitoreModulo.nonRiconosciute(r.campi)
        guard !etichette.isEmpty else { return }
        let vera = dati.impostazioni.vera
        moduli.veraInCorso = true
        Task { @MainActor in
            defer { self.moduli.veraInCorso = false }
            if self.generativo == nil {
                let d = await MotoreLocale.verificaDispositivo(vera)
                if self.disponibilitaLocale != d { self.disponibilitaLocale = d }
            }
            guard self.generativo != nil else {
                self.mostraAvviso("Vera non è pronta: associa tu le caselle che mancano.")
                return
            }
            guard let proposte = try? await ModuliVera.chiedi(motore: self.qwen, vera: vera, etichette: etichette),
                  var attuale = self.moduli.revisione, attuale.id == r.id else { return }
            for i in attuale.campi.indices { ModuliVera.applica(proposte, a: &attuale.campi[i]) }
            self.moduli.revisione = attuale
            self.mostraAvviso(proposte.isEmpty ? "Vera non ha proposte per queste caselle." : "Vera ha proposto \(proposte.count) caselle: controllale")
        }
    }

    // MARK: Fac-simile di prova

    /// I due fac-simile di Prisma (proposta di polizza e adeguata verifica), con i clienti di prova.
    func caricaEsempiModuli() {
        moduli.carica()
        let presenti = Set(moduli.tutti.filter { $0.diProva == true }.map(\.titolo))
        for (pagina, titolo, tipo) in [(FacSimileModulo.proposta, "Proposta di polizza", TipoModulo.propostaPolizza),
                                       (FacSimileModulo.adeguataVerifica, "Adeguata verifica (antiriciclaggio)", TipoModulo.adeguataVerifica)]
        where !presenti.contains(titolo) {
            guard let pdf = FacSimileModulo.pdf(pagina), let doc = PDFDocument(data: pdf) else { continue }
            let e = RiconoscitoreModulo.riconosci(doc, tipo: tipo)
            let id = "modulo-prova-\(tipo.rawValue)"
            // Il fac-simile lo disegna Prisma: la sua mappa è già controllata
            let campi = e.campi.map { var c = $0; c.daConfermare = false; return c }
            let m = ModelloModulo(id: id, titolo: titolo, tipo: tipo, file: "\(id).pdf", pagine: e.pagine, campi: campi,
                                  caricatoIl: Appuntamento.alMinuto(Date()), versione: FacSimileModulo.versione,
                                  mappaConfermata: true, diProva: true)
            moduli.aggiungi(m, pdf: pdf)
        }
        moduli.scelto = nil
    }

    func togliEsempiModuli() {
        moduli.carica()
        for m in moduli.tutti where m.diProva == true { moduli.togli(m.id) }
    }

    // MARK: IBAN (decisione 40)

    /// «Conserva l'IBAN nel dossier»: spegnendolo si tolgono gli IBAN già salvati.
    func impostaConservaIban(_ acceso: Bool) {
        guard !solaLettura else { return }
        dati.impostazioni.pratiche.conservaIban = acceso ? true : nil
        guard !acceso else { return }
        for i in dati.clienti.indices where dati.clienti[i].iban != nil { dati.clienti[i].iban = nil }
    }

    /// Quanti clienti hanno un IBAN salvato.
    var clientiConIban: Int { dati.clienti.filter { $0.iban != nil }.count }

    /// Salva l'IBAN di un cliente (solo con l'interruttore acceso e solo valido). true se salvato o tolto.
    @discardableResult
    func impostaIban(_ clienteId: String, _ testo: String) -> Bool {
        guard !solaLettura, let i = dati.clienti.firstIndex(where: { $0.id == clienteId }) else { return false }
        let t = IBAN.pulito(testo)
        if t.isEmpty {
            dati.clienti[i].iban = nil
            return true
        }
        guard dati.impostazioni.pratiche.ibanConservato, IBAN.valido(t) else { return false }
        dati.clienti[i].iban = t
        return true
    }
}
