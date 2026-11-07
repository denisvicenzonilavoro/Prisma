import Foundation

/// La biblioteca delle norme sul Mac (funzione 13): i PDF che porta l'utente stanno in Prisma/Biblioteca/ con il loro
/// indice per articolo (biblioteca.json). Entra nel backup con il resto della cartella dell'archivio. Su iPhone e iPad non
/// c'è (decisione 114 di Luce). Nelle prove e nelle istantanee resta in memoria.
final class StatoBiblioteca: ObservableObject {
    @Published private(set) var testi: [TestoNorma] = []
    @Published var scelto: String?
    @Published var articoloScelto: String?
    @Published var cerca = ""
    @Published private(set) var inLettura: [String] = []

    let persistente: Bool
    private var caricata = false
    private static let coda = DispatchQueue(label: "prisma.biblioteca", qos: .userInitiated)

    init(persistente: Bool) { self.persistente = persistente }

    /// Aspetta le scritture in coda (prima di un ripristino).
    static func attendiScritture() { coda.sync {} }

    /// Dopo un ripristino: rilegge l'indice della cartella ripristinata.
    func ricarica() {
        Self.coda.sync {}
        caricata = false
        testi = []
        scelto = nil
        articoloScelto = nil
        carica()
    }

    static var cartella: URL { Archivio.cartella.appendingPathComponent("Biblioteca", isDirectory: true) }
    static var indice: URL { cartella.appendingPathComponent("biblioteca.json") }

    func carica() {
        guard !caricata else { return }
        caricata = true
        guard persistente, let d = try? Data(contentsOf: Self.indice) else { return }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        testi = ((try? dec.decode(ElencoTollerante<TestoNorma>.self, from: d)) ?? nil)?.elementi ?? []
    }

    private func salva() {
        guard persistente else { return }
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        guard let d = try? e.encode(testi) else { return }
        Self.coda.async {
            try? FileManager.default.createDirectory(at: Self.cartella, withIntermediateDirectories: true)
            try? d.write(to: Self.indice, options: Archivio.opzioniScrittura)
        }
    }

    var tutti: [TestoNorma] { carica(); return testi }

    var articoliTotali: Int { tutti.reduce(0) { $0 + $1.articoli.count } }

    /// Aggiunge un testo già letto (le prove e l'importazione).
    @discardableResult
    func aggiungi(titolo: String, sigla: String, edizione: String, file: String, pagine: [String]) -> TestoNorma {
        carica()
        var t = TestoNorma(titolo: titolo, sigla: sigla, edizione: edizione, file: file)
        t.importatoIl = Appuntamento.alMinuto(Date())
        t.articoli = NormeVera.articoli(pagine, testoId: t.id)
        testi.append(t)
        scelto = t.id
        salva()
        return t
    }

    /// Importa i PDF scelti: copia nella cartella, legge (PDFKit, Vision per le scansioni) e divide per articolo.
    func importa(_ urls: [URL], avviso: @escaping (String) -> Void) {
        carica()
        for url in urls where url.pathExtension.lowercased() == "pdf" {
            let nome = url.deletingPathExtension().lastPathComponent
            inLettura.append(nome)
            Self.coda.async {
                let fm = FileManager.default
                let file = "\(UUID().uuidString.prefix(8).lowercased())-\(url.lastPathComponent)"
                var pagine: [String] = []
                if self.persistente {
                    try? fm.createDirectory(at: Self.cartella, withIntermediateDirectories: true)
                    try? fm.copyItem(at: url, to: Self.cartella.appendingPathComponent(file))
                }
                pagine = LetturaDocumenti.leggi(url)?.pagine ?? []
                DispatchQueue.main.async {
                    self.inLettura.removeAll { $0 == nome }
                    guard !pagine.isEmpty else {
                        // Niente copie orfane nella Biblioteca (entrerebbero in ogni backup)
                        if self.persistente { try? FileManager.default.removeItem(at: Self.cartella.appendingPathComponent(file)) }
                        return avviso("Non riesco a leggere «\(url.lastPathComponent)».")
                    }
                    let t = self.aggiungi(titolo: nome, sigla: "", edizione: "importato il \(Formati.dataEstesa.string(from: Date()))", file: file, pagine: pagine)
                    let perPagina = t.articoli.first?.numero.hasPrefix("pag.") == true
                    avviso(perPagina ? "«\(nome)»: non ho trovato articoli («Art. 1…»): Vera lo cercherà pagina per pagina."
                                     : "«\(nome)» è nella Biblioteca: \(t.articoli.count) articoli.")
                }
            }
        }
    }

    func modifica(_ id: String, titolo: String, sigla: String, edizione: String) {
        guard let i = testi.firstIndex(where: { $0.id == id }) else { return }
        testi[i].titolo = titolo.trimmingCharacters(in: .whitespacesAndNewlines)
        testi[i].sigla = sigla.trimmingCharacters(in: .whitespacesAndNewlines)
        testi[i].edizione = edizione.trimmingCharacters(in: .whitespacesAndNewlines)
        salva()
    }

    func elimina(_ id: String) {
        guard let t = testi.first(where: { $0.id == id }) else { return }
        if persistente { try? FileManager.default.removeItem(at: Self.cartella.appendingPathComponent(t.file)) }
        testi.removeAll { $0.id == id }
        if scelto == id { scelto = testi.first?.id }
        salva()
    }

    /// Apre un articolo (dalla risposta di Vera: «Apri l'articolo»).
    func mostra(_ c: CitazioneNorma) {
        scelto = c.testoId
        articoloScelto = c.articoloId
        cerca = ""
    }
}

extension StatoShell {
    /// «Il codice in tasca»: una domanda sulle norme con la biblioteca non vuota. true se l'ha gestita.
    func chiediNorme(_ testo: String, chiave: String) -> Bool {
        #if os(macOS)
        let testi = biblioteca.tutti
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        guard !testi.isEmpty, NormeVera.eUnaDomanda(testo, clienti: noti) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        conQwen(cliente: chiave) { _ in
            let motore = self.qwen
            let vera = self.dati.impostazioni.vera
            self.veraInCorso = true
            self.compitoVera = Task { @MainActor in
                let pezzi = NormeVera.pezzi(testi)
                var vettori: [String: [Float]] = [:]
                var q: [Float]?
                if vera.fornitore == .ollama {
                    let f = FornitoreOllama(indirizzo: vera.indirizzoLocale, modello: vera.modelloLocale)
                    if let v = await self.indiceVera.vettori(per: pezzi, domanda: testo, fornitore: f, modello: vera.modelloRicerca,
                                                             liberaPrima: { await f.libera() }) {
                        vettori = v.pezzi
                        q = v.domanda
                    }
                }
                let trovati = RicercaVera.cerca(testo, in: pezzi, vettori: vettori, domandaVettore: q, quanti: 4)
                    .compactMap { t in NormeVera.citazione(t.pezzo.id, in: testi).map { (t.pezzo, $0) } }
                    .reduce(into: [(PezzoRicerca, CitazioneNorma)]()) { r, x in if !r.contains(where: { $0.1.articoloId == x.1.articoloId }) { r.append(x) } }
                var risposta: String?
                var guasto = false
                if !trovati.isEmpty {
                    do {
                        risposta = try await motore.scrivi(NormeVera.messaggi(testo, trovati: trovati), opzioni: NormeVera.opzioni(vera)).testo
                    } catch is CancellationError {
                        self.veraInCorso = false
                        self.compitoVera = nil
                        return
                    } catch {
                        guasto = true
                    }
                }
                self.veraInCorso = false
                self.compitoVera = nil
                // Se Qwen non ha risposto Vera lo dice: non è «la norma non risponde»
                if guasto { self.qwenNonPronto(cliente: chiave) } else {
                    self.rispondiNorme(risposta, domanda: testo, trovati: trovati, chiave: chiave, motore: motore.nome)
                }
            }
        }
        return true
        #else
        return false
        #endif
    }

    /// La risposta con gli articoli citati, oppure «la norma non risponde» (con quanti articoli Prisma ha cercato).
    @discardableResult
    func rispondiNorme(_ json: String?, domanda: String, trovati: [(PezzoRicerca, CitazioneNorma)], chiave: String, motore: String) -> MessaggioVera {
        let testi = biblioteca.tutti
        let articoli = testi.reduce(0) { $0 + $1.articoli.count }
        let letta = json.flatMap { NormeVera.leggi($0, trovati: trovati) }
        var m: MessaggioVera
        if let letta, letta.risponde {
            m = MessaggioVera(autore: .vera, testo: letta.testo, motore: motore)
            m.norme = RispostaNorme(citazioni: letta.citazioni, nonRisponde: false, articoliCercati: articoli, testiCercati: testi.count)
        } else if json != nil, letta == nil, !trovati.isEmpty {
            // Una risposta che non si può verificare (cifre che non sono negli articoli, JSON guasto): niente lacuna inventata
            let vicini = Array(trovati.prefix(2).map(\.1))
            m = MessaggioVera(autore: .vera, testo: "Non riesco a darti una risposta verificata: guarda tu gli articoli più vicini, \(vicini.map(\.etichetta).joined(separator: " e ")).",
                              motore: motore)
            m.norme = RispostaNorme(citazioni: vicini, nonRisponde: false, articoliCercati: articoli, testiCercati: testi.count)
        } else {
            let dove = trovati.isEmpty ? "" : " Gli articoli più vicini sono \(trovati.prefix(2).map(\.1.etichetta).joined(separator: " e ")), ma non rispondono alla domanda."
            m = MessaggioVera(autore: .vera, testo: "La norma non risponde: ho cercato in \(articoli) articoli di \(testi.count == 1 ? "1 testo" : "\(testi.count) testi") della tua biblioteca e non l'ho trovato. Non lo invento.\(dove)",
                              motore: motore)
            m.norme = RispostaNorme(citazioni: [], nonRisponde: true, articoliCercati: articoli, testiCercati: testi.count)
        }
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    /// «Apri l'articolo»: la Biblioteca sull'articolo citato.
    func apriArticolo(_ c: CitazioneNorma) {
        biblioteca.mostra(c)
        apri(.biblioteca)
    }

    // MARK: - Il cliente in 30 secondi

    /// «Raccontami Marco»: le cinque sezioni di Prisma, rese scorrevoli da Qwen se è pronto. true se l'ha gestita.
    func chiediTrentaSecondi(_ testo: String, chiave: String) -> Bool {
        let noti = dati.clienti.map { ClienteNoto(id: $0.id, nome: $0.nome) }
        guard let id = TrentaSecondiVera.cliente(testo, clienti: noti, attivo: veraPortafoglio ? nil : clienteAttivoId) else { return false }
        guard !inModoCliente || id == clienteAttivoId else { return false }
        guard let fonte = fonteVera(id) else { return false }
        aggiungiMessaggio(MessaggioVera(autore: .utente, testo: testo), cliente: chiave)
        domandaVera = ""
        let scheda = TrentaSecondiVera.scheda(fonte, messaggi: dati.messaggi, ricordi: dati.impostazioni.vera.memoriaAttiva ? memoriaVera.ricordi : [])
        guard !rispostePreparate, generativo != nil else {
            rispondiTrentaSecondi(scheda, chiave: chiave, motore: MotoriVera.sintesi.nome)
            return true
        }
        let motore = qwen
        veraInCorso = true
        compitoVera = Task { @MainActor in
            let json = try? await motore.scrivi(TrentaSecondiVera.messaggi(scheda), opzioni: TrentaSecondiVera.opzioni(self.dati.impostazioni.vera)).testo
            let finale = json.map { TrentaSecondiVera.applica($0, a: scheda) } ?? scheda
            self.rispondiTrentaSecondi(finale, chiave: chiave, motore: finale == scheda ? MotoriVera.sintesi.nome : motore.nome)
            self.veraInCorso = false
            self.compitoVera = nil
        }
        return true
    }

    @discardableResult
    func rispondiTrentaSecondi(_ s: SchedaTrentaSecondi, chiave: String, motore: String) -> MessaggioVera {
        var m = MessaggioVera(autore: .vera, testo: "\(s.nome) in 30 secondi.", motore: motore)
        m.trenta = s
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }
}
