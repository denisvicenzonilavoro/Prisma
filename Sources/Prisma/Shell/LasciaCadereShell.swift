import Foundation

/// «Lascia cadere qui» nell'app (funzione 9): il documento trascinato su Vera o sulla scrivania si legge in una cartella
/// temporanea del Mac, Vera dice cos'è e di chi è e propone la scheda (archiviazione con i dati letti, promemoria della
/// scadenza). Con «Conferma» il file entra in Documenti del cliente; «Annulla» lo toglie.
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
        // «Dopo la firma» aspettava il PDF firmato: il documento diventa il contratto del cliente (CollegaRoutineShell.swift)
        if lasciaCadereRoutine(documenti) { return }
        if !aperta(.vera) { apri(.vera) }
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
        let l = LasciaCadereVera.leggi(nomeFile: nome, pagine: pagine, pagineOCR: pagineOCR, clienti: dati.clienti)
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
            if temporanea { try? FileManager.default.removeItem(at: cartellaCopia) }
            let nomi = inModoCliente ? [] : l.possibili.compactMap { self.cliente($0)?.nome }
            let chi = nomi.isEmpty ? "Nel documento non trovo il cliente" : "Nel documento ci sono più clienti (\(nomi.joined(separator: ", ")))"
            return rispondi("Ho letto «\(nome)», \(Self.cosa(l.tipo)). \(chi): apri il suo dossier in Vera e trascinalo di nuovo.")
        }
        let azioni = LasciaCadereVera.azioni(l, cliente: c, file: copia, testo: testo, oggi: oggi)
        let scheda = SchedaConfermaVera(richiesta: nome, azioni: azioni, origine: .documento)
        let intestazione = l.clienteId == nil
            ? "È \(Self.cosa(l.tipo)). \(come.prefix(1).uppercased() + come.dropFirst())."
            : "È \(Self.cosa(l.tipo)) di \(c.nome), riconosciuto \(come)."
        return rispondi(intestazione + " Lo archivio appena confermi.", scheda)
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
        d.lettura = .letto
        d.categoria = CategoriaDocumento(rawValue: arg["categoria"] ?? "")
        // I dati letti erano nella scheda: con «Conferma» sono confermati
        let campi = (arg["campi"]?.data(using: .utf8)).flatMap { try? JSONDecoder().decode([CampoEstratto].self, from: $0) } ?? []
        d.campi = campi.map { var x = $0; x.confermato = true; return x }
        dati.documenti.append(d)
        return EsitoAzioneVera(fatta: true, messaggio: "«\(d.titolo)» è nei documenti di \(c.nome).", oggetto: d.id)
    }
}
