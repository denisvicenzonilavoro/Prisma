import Foundation

/// Il documento letto in attesa che il consulente scelga di chi è (più clienti possibili).
struct SceltaClienteCaduto: Equatable {
    var copia: URL
    var testo: URL
    var pagine: [String]
    var pagineOCR: Int
    var possibili: [String]
}

/// Una riga di «Archiviati da Vera oggi» (template «Lascia cadere qui»).
struct ArchiviatoVera: Identifiable, Equatable {
    var id: String { documentoId }
    var documentoId: String
    var titolo: String
    var tipo: Documento.Tipo
    var categoria: CategoriaDocumento
    var clienteId: String
    var cliente: String
    /// «Documenti», «Posizioni» o «Anagrafica».
    var dove: String
    var dettaglio: String
    var quando: Date
}

/// «Lascia cadere qui» nell'app (funzione 9): il documento trascinato su Vera o sulla scrivania si legge in una cartella
/// temporanea del Mac, Vera dice cos'è e di chi è e propone la scheda (archiviazione con i dati letti, che si correggono
/// uno per uno; le posizioni di un estratto conto in Posizioni; la scadenza del documento d'identità in anagrafica; il
/// promemoria della scadenza). Con più clienti possibili si sceglie dalla risposta. Con «Conferma» il file entra in
/// Documenti del cliente; «Annulla» lo toglie. «Archiviati da Vera oggi» li elenca.
extension StatoShell {
    static let cartellaInArrivo = FileManager.default.temporaryDirectory.appendingPathComponent("Prisma-in-arrivo", isDirectory: true)
    private static let codaCaduti = DispatchQueue(label: "prisma.lascia-cadere", qos: .userInitiated)

    /// I documenti trascinati (al massimo quattro alla volta): Vera li legge e risponde con una scheda per ognuno.
    func lasciaCadere(_ urls: [URL]) {
        // Fase 3: una nota vocale diventa il resoconto dell'incontro (con il consenso del cliente, l'audio non si salva)
        if let audio = urls.first(where: { ResocontoVera.estensioniAudio.contains($0.pathExtension.lowercased()) }) {
            guard !solaLettura else { return mostraAvviso("Archivio in sola lettura: aggiorna Prisma per scrivere resoconti.") }
            // Una cosa alla volta: la nota vocale ora, i documenti trascinati insieme li chiedo di nuovo
            if urls.contains(where: { LetturaDocumenti.estensioniAccettate.contains($0.pathExtension.lowercased()) }) {
                mostraAvviso("Prima trascrivo la nota vocale: trascina di nuovo i documenti quando ho finito.")
            }
            notaVocale(audio, chiave: chiaveConversazione)
            return
        }
        let documenti = urls.filter { LetturaDocumenti.estensioniAccettate.contains($0.pathExtension.lowercased()) }
        guard !documenti.isEmpty else { return }
        guard !solaLettura else { return mostraAvviso("Archivio in sola lettura: aggiorna Prisma per archiviare documenti.") }
        guard !veraInCorso else { return mostraAvviso("Vera sta ancora rispondendo: trascina il documento tra poco.") }
        // Vera si apre prima di tutto: anche la scheda di «Dopo la firma» deve vedersi (apri non cambia la conversazione)
        if !aperta(.vera) { apri(.vera) }
        // «Dopo la firma» aspettava il PDF firmato: il documento diventa il contratto del cliente (CollegaRoutineShell.swift)
        if lasciaCadereRoutine(documenti) { return }
        let chiave = chiaveConversazione
        let fm = FileManager.default
        ripulisciInArrivoVecchi()
        var copie: [URL] = []
        for url in documenti.prefix(4) {
            let cartella = Self.cartellaInArrivo.appendingPathComponent(UUID().uuidString, isDirectory: true)
            let copia = cartella.appendingPathComponent(url.lastPathComponent)
            do {
                try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
                try fm.copyItem(at: url, to: copia)
            } catch {
                mostraAvviso("Non riesco a leggere «\(url.lastPathComponent)»: \(error.localizedDescription)")
                continue
            }
            aggiungiMessaggio(MessaggioVera(autore: .utente, testo: "📄 \(url.lastPathComponent)"), cliente: chiave, parla: false)
            copie.append(copia)
        }
        if documenti.count > 4 { mostraAvviso("Leggo i primi quattro documenti: trascina gli altri dopo.") }
        guard !copie.isEmpty else { return }
        // Tutte le letture in un blocco: Vera torna libera una volta sola, alla fine
        veraInCorso = true
        Self.codaCaduti.async {
            let esiti = copie.map { ($0, LetturaDocumenti.leggi($0)) }
            DispatchQueue.main.async {
                self.veraInCorso = false
                for (copia, esito) in esiti {
                    self.rispondiDocumentoCaduto(copia, pagine: esito?.pagine ?? [], pagineOCR: esito?.pagineOCR ?? 0, chiave: chiave)
                }
            }
        }
    }

    /// Le copie rimaste nella cartella temporanea da più di un giorno (schede mai confermate) si cancellano.
    func ripulisciInArrivoVecchi() {
        let fm = FileManager.default
        let limite = Date().addingTimeInterval(-86_400)
        for u in (try? fm.contentsOfDirectory(at: Self.cartellaInArrivo, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        where ((try? u.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) < limite {
            try? fm.removeItem(at: u)
        }
    }

    /// La risposta di Vera per un documento letto: cos'è, di chi è, e la scheda da confermare.
    @discardableResult
    func rispondiDocumentoCaduto(_ copia: URL, pagine: [String], pagineOCR: Int, chiave: String, oggi: Date = Date()) -> MessaggioVera {
        let nome = copia.lastPathComponent
        func rispondi(_ testo: String, _ scheda: SchedaConfermaVera? = nil) -> MessaggioVera {
            var m = MessaggioVera(autore: .vera, testo: testo, motore: Self.motoreAzioni)
            m.conferma = scheda
            aggiungiMessaggio(m, cliente: chiave)
            return m
        }
        let cartellaCopia = copia.deletingLastPathComponent()
        let temporanea = cartellaCopia.path.hasPrefix(Self.cartellaInArrivo.path)
        guard pagine.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            if temporanea { try? FileManager.default.removeItem(at: cartellaCopia) }
            return rispondi("Non riesco a leggere «\(nome)»: forse è protetto o è un'immagine troppo sfocata.")
        }
        // Si riconosce su tutti i clienti; in modalità cliente un documento di un altro cliente non si archivia (senza nomi)
        let l = LasciaCadereVera.leggi(nomeFile: nome, pagine: pagine, pagineOCR: pagineOCR, clienti: clientiAttivi)
        if inModoCliente, (l.clienteId.map { $0 != clienteAttivoId } ?? false) || (l.clienteId == nil && !l.possibili.isEmpty && !l.possibili.contains(clienteAttivoId)) {
            if temporanea { try? FileManager.default.removeItem(at: cartellaCopia) }
            return rispondi("Ho letto «\(nome)», ma non è di questo cliente: non lo archivio qui.")
        }
        let testo = copia.deletingPathExtension().appendingPathExtension("txt")
        try? pagine.joined(separator: LetturaDocumenti.separatorePagine).write(to: testo, atomically: true, encoding: .utf8)
        var come = l.come
        var cliente = l.clienteId.flatMap { self.cliente($0) }
        if cliente == nil, !veraPortafoglio, let attivo = self.cliente(clienteAttivoId), l.possibili.isEmpty || l.possibili.contains(attivo.id) {
            cliente = attivo
            come = "nel documento non ho trovato il cliente: lo metto in \(attivo.nome), il cliente aperto"
        }
        guard let c = cliente else {
            let possibili = inModoCliente ? [] : l.possibili.filter { self.cliente($0) != nil }
            // Più clienti possibili: si sceglie dalla risposta (la copia resta nella cartella temporanea fino alla scelta)
            if possibili.count >= 2 {
                let nomi = possibili.compactMap { self.cliente($0)?.nome }
                var m = MessaggioVera(autore: .vera, testo: "Ho letto «\(nome)», \(Self.cosa(l.tipo)). Nel documento ci sono più clienti (\(nomi.joined(separator: ", "))): dimmi di chi è.",
                                      titolo: Self.titoloSceltaCaduto, motore: Self.motoreAzioni)
                m.conferma = nil
                scelteClienteCaduto[m.id] = SceltaClienteCaduto(copia: copia, testo: testo, pagine: pagine, pagineOCR: pagineOCR, possibili: possibili)
                aggiungiMessaggio(m, cliente: chiave)
                return m
            }
            if temporanea { try? FileManager.default.removeItem(at: cartellaCopia) }
            return rispondi("Ho letto «\(nome)», \(Self.cosa(l.tipo)). Nel documento non trovo il cliente: apri il suo dossier in Vera e trascinalo di nuovo.")
        }
        let azioni = LasciaCadereVera.azioni(l, cliente: c, file: copia, testo: testo, oggi: oggi, posizioni: dati.posizioni)
        let scheda = SchedaConfermaVera(richiesta: nome, azioni: azioni, origine: .documento)
        let intestazione = l.clienteId == nil
            ? "È \(Self.cosa(l.tipo)). \(come.prefix(1).uppercased() + come.dropFirst())."
            : "È \(Self.cosa(l.tipo)) di \(c.nome), riconosciuto \(come)."
        return rispondi(intestazione + Self.dove(azioni) + " Lo archivio appena confermi: i dati letti li puoi correggere uno per uno.", scheda)
    }

    static let titoloSceltaCaduto = "Di chi è questo documento?"

    /// Dove va il documento oltre a Documenti: le posizioni lette, l'anagrafica.
    private static func dove(_ azioni: [AzioneConferma]) -> String {
        let posizioni = azioni.filter { $0.strumento == LasciaCadereVera.strumentoPosizione }.count
        if posizioni > 0 {
            return posizioni == 1 ? " Ho letto una posizione: va in Posizioni." : " Ho letto \(SchedaConfermaVera.numero(posizioni)) posizioni: vanno in Posizioni, da confermare."
        }
        if azioni.contains(where: { $0.strumento == TagliandoVera.strumentoDocumento }) { return " La scadenza va in anagrafica, nella scheda." }
        return ""
    }

    /// Dalla risposta: il consulente sceglie di chi è il documento e Vera prepara la scheda per quel cliente.
    @discardableResult
    func scegliClienteCaduto(messaggio id: String, cliente clienteId: String, chiave: String, oggi: Date = Date()) -> MessaggioVera? {
        guard let x = scelteClienteCaduto[id], x.possibili.contains(clienteId), let c = cliente(clienteId) else { return nil }
        guard !inModoCliente || clienteId == clienteAttivoId else { return nil }
        scelteClienteCaduto[id] = nil
        guard FileManager.default.fileExists(atPath: x.copia.path) || !persistente else {
            var m = MessaggioVera(autore: .vera, testo: "Il file non c'è più: trascinalo di nuovo.", motore: Self.motoreAzioni)
            m.conferma = nil
            aggiungiMessaggio(m, cliente: chiave)
            return m
        }
        let nome = x.copia.lastPathComponent
        let l = LasciaCadereVera.leggi(nomeFile: nome, pagine: x.pagine, pagineOCR: x.pagineOCR, clienti: clientiAttivi)
        let azioni = LasciaCadereVera.azioni(l, cliente: c, file: x.copia, testo: x.testo, oggi: oggi, posizioni: dati.posizioni)
        var m = MessaggioVera(autore: .vera, testo: "Va bene: è \(Self.cosa(l.tipo)) di \(c.nome).\(Self.dove(azioni)) Lo archivio appena confermi.", motore: Self.motoreAzioni)
        m.conferma = SchedaConfermaVera(richiesta: nome, azioni: azioni, origine: .documento)
        aggiungiMessaggio(m, cliente: chiave)
        return m
    }

    /// Un dato letto corretto dal consulente prima di «Conferma»: cambia nella scheda (e nelle righe che ne dipendono).
    func correggiCampoCaduto(messaggio id: String, campo: CampoDocumento, valore: String, oggi: Date = Date()) {
        guard let s = messaggioVera(id)?.conferma, s.origine == .documento, s.stato == .daConfermare,
              let cid = s.azioni.first(where: { $0.strumento == RegistroStrumenti.documentiArchivia })?.argomenti["cliente"],
              let c = cliente(cid) else { return }
        aggiornaSchedaVera(messaggio: id) { scheda in
            scheda.azioni = LasciaCadereVera.correggi(scheda.azioni, campo: campo, valore: valore, cliente: c, oggi: oggi)
        }
    }

    /// Il valore di una posizione letta corretto prima di «Conferma».
    func correggiPosizioneCaduta(messaggio id: String, azione: String, valore: Double) {
        guard valore > 0, let s = messaggioVera(id)?.conferma, s.origine == .documento, s.stato == .daConfermare,
              let a = s.azioni.first(where: { $0.id == azione && $0.strumento == LasciaCadereVera.strumentoPosizione }),
              let cid = a.argomenti["cliente"], let c = cliente(cid) else { return }
        var p = PosizioneLetta(nome: a.argomenti["nome"] ?? "", isin: a.argomenti["isin"], valore: valore, pagina: Int(a.argomenti["pagina"] ?? "") ?? 1)
        if p.nome.isEmpty { p.nome = "Posizione" }
        let esistente = a.argomenti["posizione"].flatMap { pid in dati.posizioni.first { $0.id == pid } }
        var nuova = LasciaCadereVera.azionePosizione(p, cliente: c, esistente: esistente,
                                                     data: RegistroStrumenti.daIso(a.argomenti["data"]) ?? Date(), titoloDocumento: a.argomenti["documento"] ?? "")
        nuova.id = a.id
        aggiornaSchedaVera(messaggio: id) { scheda in
            if let i = scheda.azioni.firstIndex(where: { $0.id == azione }) { scheda.azioni[i] = nuova }
        }
    }

    // MARK: - Estratto conto → Posizioni

    /// Esegue una riga «Aggiungo / aggiorno in Posizioni»: il valore letto entra nello storico della posizione che c'è
    /// (`ValoriDaDocumento.applica`), oppure nasce una posizione in essere, indipendente, con la nota da dove viene.
    func eseguiPosizioneCaduta(_ a: AzioneConferma) -> EsitoAzioneVera {
        let arg = a.argomenti
        guard let cid = arg["cliente"], let c = cliente(cid), let valore = Double(arg["valore"] ?? ""), valore > 0 else {
            return EsitoAzioneVera(fatta: false, messaggio: "Non ho trovato il cliente o il valore della posizione.")
        }
        let data = ValoriDaDocumento.mezzogiorno(RegistroStrumenti.daIso(arg["data"]) ?? Date())
        if let pid = arg["posizione"], let i = dati.posizioni.firstIndex(where: { $0.id == pid && $0.clienteId == cid }) {
            let prima = dati.posizioni[i]
            var p = prima
            _ = ValoriDaDocumento.applica(ValoriDaDocumento.Valore(data: data, valore: valore, versato: nil), a: &p)
            dati.posizioni[i] = p
            let json = (try? JSONEncoder().encode(prima)).flatMap { String(data: $0, encoding: .utf8) }
            return EsitoAzioneVera(fatta: true, messaggio: "«\(p.nome)» di \(c.nome) ha il valore letto: \(Formati.euro(valore)).", oggetto: pid, prima: json)
        }
        let nome = arg["nome"] ?? "Posizione letta"
        var p = Posizione(clienteId: cid, canale: .indipendente, stato: .inEssere,
                          area: AreaPosizione(rawValue: arg["area"] ?? "") ?? .investimento, nome: nome)
        p.controvalore = valore
        p.dataValore = data
        p.note = "Letta con Vera da «\(arg["documento"] ?? "un estratto conto")»" + (arg["isin"].map { ", ISIN \($0)" } ?? "") + "."
        dati.posizioni.append(p)
        return EsitoAzioneVera(fatta: true, messaggio: "«\(nome)» è tra le posizioni di \(c.nome).", oggetto: p.id)
    }

    /// «Annulla»: la posizione aggiunta si toglie, quella aggiornata torna com'era (solo se nessuno l'ha cambiata dopo).
    func disfaPosizioneCaduta(_ a: AzioneConferma) -> Bool {
        guard let e = a.esito, e.fatta, let id = e.oggetto, let i = dati.posizioni.firstIndex(where: { $0.id == id }) else { return false }
        if let json = e.prima, let d = json.data(using: .utf8), let prima = try? JSONDecoder().decode(Posizione.self, from: d) {
            dati.posizioni[i] = prima
        } else {
            dati.posizioni.remove(at: i)
        }
        return true
    }

    // MARK: - «Archiviati da Vera oggi»

    /// I documenti archiviati oggi da «Lascia cadere qui» (le schede confermate e non annullate), con dove sono andati:
    /// Documenti, Posizioni (le posizioni lette) o Anagrafica (il documento d'identità). In modalità cliente solo i suoi.
    func archiviatiDaVeraOggi(oggi: Date = Date()) -> [ArchiviatoVera] {
        let cal = Calendar.current
        let tutte = (dati.impostazioni.vera.conservaConversazioni ? Array(dati.conversazioni.values) : []) + Array(conversazioniTemporanee.values)
        var r: [ArchiviatoVera] = []
        for m in tutte.joined() {
            guard let s = m.conferma, s.origine == .documento, s.stato == .eseguita else { continue }
            let fatte = s.attive.filter { $0.esito?.fatta == true && $0.esito?.annullata != true }
            guard let a = fatte.first(where: { $0.strumento == RegistroStrumenti.documentiArchivia }), let did = a.esito?.oggetto,
                  let d = documento(did), case let quando = d.importatoIl, cal.isDate(quando, inSameDayAs: oggi),
                  visibileAlCliente(d.clienteId), let c = cliente(d.clienteId) else { continue }
            let posizioni = fatte.filter { $0.strumento == LasciaCadereVera.strumentoPosizione }.count
            let identita = fatte.first { $0.strumento == TagliandoVera.strumentoDocumento }
            let promemoria = fatte.first { $0.strumento == RegistroStrumenti.attivitaNuova }
            let dove: String
            let dettaglio: String
            if posizioni > 0 {
                dove = "Posizioni"
                dettaglio = posizioni == 1 ? "Una posizione letta e confermata" : "\(SchedaConfermaVera.numero(posizioni).capitalized) posizioni lette e confermate"
            } else if let i = identita, let sc = RegistroStrumenti.daIso(i.argomenti["scadenza"]) {
                dove = "Anagrafica"
                dettaglio = "Scade il \(Formati.dataEstesa.string(from: sc))"
            } else if let p = promemoria, let quando = RegistroStrumenti.daIso(p.argomenti["scadenza"]) {
                dove = "Documenti"
                dettaglio = (p.argomenti["titolo"].map { $0.replacingOccurrences(of: "«\(d.titolo)» ", with: "") } ?? "Con la scadenza") + " · promemoria il \(Formati.dataEstesa.string(from: quando))"
            } else {
                dove = "Documenti"
                dettaglio = d.campi.first.map { "\($0.chiave.nome): \($0.valore)" } ?? "Archiviato con i dati letti"
            }
            r.append(ArchiviatoVera(documentoId: d.id, titolo: d.titolo, tipo: d.tipo, categoria: d.genere, clienteId: c.id, cliente: c.nome,
                                    dove: dove, dettaglio: dettaglio, quando: quando))
        }
        return r.sorted { $0.quando > $1.quando }
    }

    /// «una polizza», «un KID», «un estratto conto»…
    private static func cosa(_ t: Documento.Tipo) -> String {
        switch t {
        case .kid: return "un KID"
        case .polizza: return "una polizza"
        case .estrattoConto: return "un estratto conto"
        case .proposta: return "una proposta"
        case .prospetto: return "un prospetto di Prisma"
        case .report: return "un report di Prisma"
        case .modulo: return "un modulo compilato"
        case .altro: return "un documento"
        }
    }

    /// Esegue l'archiviazione: il file e il suo testo in Documenti del cliente, con i dati letti confermati.
    func archiviaDocumentoCaduto(_ a: AzioneConferma) -> EsitoAzioneVera {
        let arg = a.argomenti
        guard let id = arg["cliente"], let c = cliente(id), let percorso = arg["file"] else {
            return EsitoAzioneVera(fatta: false, messaggio: "Non ho trovato il cliente del documento.")
        }
        let origine = URL(fileURLWithPath: percorso)
        let fm = FileManager.default
        guard fm.fileExists(atPath: origine.path) else {
            return EsitoAzioneVera(fatta: false, messaggio: "Il file trascinato non c'è più: trascinalo di nuovo.")
        }
        var d = Documento(clienteId: id, titolo: arg["titolo"] ?? origine.deletingPathExtension().lastPathComponent,
                          tipo: Documento.Tipo(rawValue: arg["tipo"] ?? "") ?? .altro)
        d.importatoIl = Appuntamento.alMinuto(Date())
        // Il contratto firmato resta legato alla sua posizione, solo se è dello stesso cliente
        if let p = arg["posizione"], dati.posizioni.contains(where: { $0.id == p && $0.clienteId == id }) { d.posizioneId = p }
        let estensione = origine.pathExtension.lowercased()
        let cartella = Archivio.cartellaDocumenti.appendingPathComponent(id, isDirectory: true)
        let destinazione = cartella.appendingPathComponent("\(d.id).\(estensione)")
        guard persistente else {
            // Nelle prove e nelle istantanee il file non si copia: il documento entra solo nei dati
            d.file = "\(id)/\(d.id).\(estensione)"
            return registra(d, a, c)
        }
        do {
            try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
            try fm.copyItem(at: origine, to: destinazione)
            if let t = arg["testo"] {
                try? fm.copyItem(at: URL(fileURLWithPath: t), to: destinazione.deletingPathExtension().appendingPathExtension("txt"))
            }
        } catch {
            return EsitoAzioneVera(fatta: false, messaggio: "Non riesco a copiare il documento: \(error.localizedDescription)")
        }
        d.file = "\(id)/\(d.id).\(estensione)"
        d.dimensione = (try? fm.attributesOfItem(atPath: destinazione.path)[.size] as? Int64) ?? 0
        try? fm.removeItem(at: origine.deletingLastPathComponent())
        return registra(d, a, c)
    }

    private func registra(_ documento: Documento, _ a: AzioneConferma, _ c: Cliente) -> EsitoAzioneVera {
        var d = documento
        let arg = a.argomenti
        d.pagine = Int(arg["pagine"] ?? "") ?? 0
        d.pagineOCR = Int(arg["pagineOCR"] ?? "") ?? 0
        // Senza testo letto (un contratto da cui non esce testo, una scheda di prima) il documento si rilegge dopo
        let senzaTesto = arg["testo"] == nil
        d.lettura = senzaTesto ? .daLeggere : .letto
        d.categoria = CategoriaDocumento(rawValue: arg["categoria"] ?? "")
        // I dati letti erano nella scheda: con «Conferma» sono confermati
        let campi = (arg["campi"]?.data(using: .utf8)).flatMap { try? JSONDecoder().decode([CampoEstratto].self, from: $0) } ?? []
        d.campi = campi.map { var x = $0; x.confermato = true; return x }
        dati.documenti.append(d)
        if senzaTesto { leggiDocumento(d.id) }
        return EsitoAzioneVera(fatta: true, messaggio: "«\(d.titolo)» è nei documenti di \(c.nome).", oggetto: d.id)
    }
}
