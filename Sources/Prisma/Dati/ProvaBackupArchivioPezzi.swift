import Foundation

// L'archivio a pezzi (giro 0 di «Prisma istantaneo», tappa 3: ArchivioPezzi.swift) dentro `Prisma --prova-backup`:
// un archivio.json di prima si converte da solo e si riapre identico; la cartella a pezzi va nel backup e torna
// identica; un backup di prima (zip con archivio.json) si ripristina e si converte; un file di un cliente rovinato o
// mancante non fa perdere gli altri e l'avviso c'è; una modifica a un cliente riscrive solo il suo file (e l'indice
// solo se serve); un salvataggio interrotto a metà non perde nulla.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaArchivioPezzi(radice: URL, originale: DatiPrisma) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("ArchivioPezzi", isDirectory: true)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)

        // Ogni chiave ha il suo posto e la scrittura intera le scrive tutte (come quella sintetizzata di prima)
        var conFamiglie = originale
        if conFamiglie.famiglie == nil, let tabelle = TabelleFamiglie.tabellePredefinite {
            conFamiglie.famiglie = FamiglieCaricate(tabelle: tabelle, nomeFile: "prova", caricateIl: Date(timeIntervalSinceReferenceDate: 0))
        }
        let chiaviScritte = (try JSONSerialization.jsonObject(with: Archivio.codificatore.encode(conFamiglie)) as? [String: Any])?.keys.count ?? 0
        // Senza tabelle caricate la chiave «famiglie» non si scrive (come prima)
        guard chiaviScritte == DatiPrisma.CodingKeys.allCases.count - (conFamiglie.famiglie == nil ? 1 : 0) else {
            return "archivio a pezzi: la scrittura intera ha \(chiaviScritte) chiavi, DatiPrisma ne ha \(DatiPrisma.CodingKeys.allCases.count)"
        }
        guard Mirror(reflecting: originale).children.count == DatiPrisma.CodingKeys.allCases.count else {
            return "archivio a pezzi: DatiPrisma ha un campo senza chiave"
        }

        let casi: [(String, DatiPrisma)] = [("dati di prova", DatiPrisma.demo()), ("clienti fittizi", ClientiFittizi.completi()),
                                            ("archivio della prova", originale)]
        for (n, (nome, d)) in casi.enumerated() {
            if let e = try provaConversione(base.appendingPathComponent("Conversione-\(n)", isDirectory: true), nome: nome, dati: d) {
                return "archivio a pezzi, \(nome): \(e)"
            }
        }
        if let e = try provaVecchioBackup(base.appendingPathComponent("VecchioBackup", isDirectory: true), dati: originale) {
            return "archivio a pezzi: \(e)"
        }
        if let e = try provaPezziRovinati(base.appendingPathComponent("Rovinati", isDirectory: true)) {
            return "archivio a pezzi: \(e)"
        }
        if let e = try provaSoloCambiati(base.appendingPathComponent("SoloCambiati", isDirectory: true)) {
            return "archivio a pezzi: \(e)"
        }
        if let e = try provaInterrotto(base.appendingPathComponent("Interrotto", isDirectory: true)) {
            return "archivio a pezzi: \(e)"
        }
        if let e = try provaRevisioneArchivio(base.appendingPathComponent("Revisione", isDirectory: true)) {
            return "archivio a pezzi: \(e)"
        }
        if let e = try provaSecondaRevisioneArchivio(base.appendingPathComponent("SecondaRevisione", isDirectory: true)) {
            return "archivio a pezzi: \(e)"
        }
        print("OK    archivio a pezzi: conversione, backup e ripristino, backup di prima, file rovinati e mancanti, scrittura dei soli file cambiati, salvataggi interrotti (transazioni), file non leggibili adesso, indici più recenti, copie omonime, formato di prima dopo un ripristino, archivio.json vecchio, sole sezioni, ricostruzione senza clienti tolti, NaN, copie d'avvio interrotte, segnaposto per le versioni di prima, backup protetto, copia d'avvio, transazione rimasta nella stessa sessione, due ricostruzioni di fila, riserva dell'indice (impostazioni e Prisma ovunque di adesso, clienti tolti che non tornano), conversione interrotta prima della verifica, copia d'avvio più recente, archivio.json di una versione precedente, backup dell'archivio valido (mai copia d'avvio, segno o pezzi sciolti), ripristino interrotto a pezzi e backup a pezzi più recenti")
        return nil
    }

    /// L'archivio a pezzi sul disco com'è, senza toccarlo (al contrario di `Archivio.leggiPerRipristino`, che completa una
    /// transazione rimasta): nil se è rimasta una transazione («in-corso»), se un pezzo non si legge, se l'indice manca
    /// o se la sua riserva non è uguale a lui. Così le prove vedono ciò che lo scrittore ha lasciato davvero.
    static func archivioSulDisco(_ cartella: URL) -> DatiPrisma? {
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        guard !FileManager.default.fileExists(atPath: pezzi.appendingPathComponent(ArchivioPezzi.nomeTransazione).path),
              let indice = try? Data(contentsOf: pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice)),
              (try? Data(contentsOf: pezzi.appendingPathComponent(ArchivioPezzi.nomeRiserva))) == indice,
              let r = try? ArchivioPezzi.leggi(pezzi), r.problemi.isEmpty else { return nil }
        return r.lettura.dati
    }

    /// Com'è un archivio dopo il giro nel JSON (date al secondo): ciò che si rilegge dal disco.
    static func passatoDalDisco(_ d: DatiPrisma) throws -> DatiPrisma {
        try Archivio.decodifica(Archivio.codificatore.encode(d))
    }

    /// Una cartella dell'archivio («Prisma») con archivio.json di prima e un documento.
    static func archivioDiPrima(_ cartella: URL, _ d: DatiPrisma) throws {
        let fm = FileManager.default
        try? fm.removeItem(at: cartella)
        try fm.createDirectory(at: cartella.appendingPathComponent("Documenti"), withIntermediateDirectories: true)
        try Archivio.codificatore.encode(d).write(to: cartella.appendingPathComponent(Archivio.nomeFileVecchio))
        try Data("documento di prova".utf8).write(to: cartella.appendingPathComponent("Documenti/prova.txt"))
    }

    /// Converte come all'avvio: carica e, se serve, riscrive tutto (come `StatoShell.completaAvvio`).
    static func caricaEConverti(_ cartella: URL) -> Archivio.EsitoCarica {
        let e = Archivio.carica(in: cartella)
        if e.daRiscrivere, !e.solaLettura {
            let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-pezzi", qos: .utility))
            s.riscriviTutto(e.dati) { errore in print("ERRORE nella conversione: \(errore.localizedDescription)") }
            s.attendi()
        }
        // La copia d'avvio si fa sulla coda dell'archivio
        Archivio.coda.sync {}
        return e
    }

    /// Vecchio archivio.json → conversione → riapertura identica; poi backup → ripristino identico.
    private static func provaConversione(_ base: URL, nome: String, dati d: DatiPrisma) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        try archivioDiPrima(cartella, d)
        var atteso = try passatoDalDisco(d)
        atteso.versione = DatiPrisma.versioneAttuale

        let primo = caricaEConverti(cartella)
        guard primo.dati == atteso, primo.daRiscrivere, primo.avviso == nil else { return "archivio.json di prima non letto come sempre" }
        guard ArchivioPezzi.presente(in: cartella),
              !fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileVecchio).path),
              fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileConvertito).path) else {
            return "conversione non fatta (o archivio.json non tenuto come archivio.json.vecchio)"
        }
        let indice = try ArchivioPezzi.leggiIndice(ArchivioPezzi.cartellaPezzi(in: cartella))
        let fileClienti = try fm.contentsOfDirectory(atPath: ArchivioPezzi.cartellaPezzi(in: cartella).appendingPathComponent("Clienti").path)
        guard indice.formato == ArchivioPezzi.formatoAttuale, indice.clienti.count == Set(d.clienti.map(\.id)).count,
              fileClienti.filter({ $0 != ArchivioPezzi.nomeSenzaCliente }).count == indice.clienti.count else {
            return "l'indice non cita un file per cliente (\(indice.clienti.count) voci, \(fileClienti.count) file)"
        }
        // Riapertura: identica, in due tempi (prima l'indice con lo scheletro), e la copia di archivio.json se ne va
        var scheletro: DatiPrisma?
        let secondo = Archivio.carica(in: cartella, indiceLetto: { scheletro = $0 })
        Archivio.coda.sync {}
        guard secondo.dati == atteso, secondo.avviso == nil, !secondo.daRiscrivere, secondo.sulDisco?.dati == atteso else {
            return "dopo la conversione l'archivio non si riapre identico"
        }
        guard let s = scheletro, s.clienti.isEmpty, s.impostazioni == atteso.impostazioni, s.clienteAttivoId == atteso.clienteAttivoId else {
            return "l'indice non arriva prima, con le impostazioni e senza i dati dei clienti"
        }
        guard !fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileConvertito).path) else {
            return "archivio.json.vecchio resta anche dopo la riapertura verificata"
        }
        guard fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeCopiaAvvio).appendingPathComponent(ArchivioPezzi.nomeIndice).path) else {
            return "la copia d'avvio della cartella a pezzi non c'è"
        }

        // Backup della cartella a pezzi → ripristino identico (la copia d'avvio resta fuori dal backup)
        let zip = try GestoreBackup.crea(sorgente: cartella, destinazione: base.appendingPathComponent("Backup", isDirectory: true))
        let estratto = try GestoreBackup.estrai(zip)
        guard estratto.dati == atteso else {
            GestoreBackup.pulisciEstrazione(estratto.cartella)
            return "il backup della cartella a pezzi non torna identico"
        }
        guard ArchivioPezzi.presente(in: estratto.cartella),
              !fm.fileExists(atPath: estratto.cartella.appendingPathComponent(Archivio.nomeCopiaAvvio).path) else {
            GestoreBackup.pulisciEstrazione(estratto.cartella)
            return "il backup non comprende la cartella a pezzi (o comprende la copia d'avvio)"
        }
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: estratto.cartella)
        let riaperta = Archivio.carica(in: ripristinata)
        Archivio.coda.sync {}
        guard riaperta.dati == atteso, riaperta.avviso == nil,
              (try? String(contentsOf: ripristinata.appendingPathComponent("Documenti/prova.txt"), encoding: .utf8)) == "documento di prova" else {
            return "dopo il ripristino del backup a pezzi l'archivio (o un documento) non è identico"
        }
        return nil
    }

    /// Un backup di prima (zip con archivio.json) si ripristina come sempre e si converte.
    private static func provaVecchioBackup(_ base: URL, dati d: DatiPrisma) throws -> String? {
        let fm = FileManager.default
        let vecchia = base.appendingPathComponent("Vecchia/Prisma", isDirectory: true)
        try archivioDiPrima(vecchia, d)
        let zip = try GestoreBackup.crea(sorgente: vecchia, destinazione: base.appendingPathComponent("Backup", isDirectory: true))
        let estratto = try GestoreBackup.estrai(zip)
        let atteso = try passatoDalDisco(d)
        guard estratto.dati == atteso else {
            GestoreBackup.pulisciEstrazione(estratto.cartella)
            return "un backup di prima non si legge come sempre"
        }
        // Il Mac ha già la cartella a pezzi (un altro archivio): il ripristino la sostituisce con quella del backup
        let cartella = base.appendingPathComponent("Mac/Prisma", isDirectory: true)
        try Archivio.salva(ClientiFittizi.completi(), in: cartella)
        try GestoreBackup.sostituisci(cartellaDati: cartella, con: estratto.cartella)
        guard !ArchivioPezzi.presente(in: cartella), fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileVecchio).path) else {
            return "il ripristino di un backup di prima non ha rimesso archivio.json al posto della cartella a pezzi"
        }
        // Come StatoShell dopo il ripristino: `ricomincia` e salvataggio (qui: il salvataggio di uno scrittore nuovo)
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-pezzi-ripristino", qos: .utility))
        s.ricomincia()
        s.accoda(estratto.dati, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        guard ArchivioPezzi.presente(in: cartella), fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileConvertito).path) else {
            return "il backup di prima ripristinato non si è convertito"
        }
        let riaperta = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard riaperta.dati == atteso, riaperta.avviso == nil else { return "il backup di prima convertito non si riapre identico" }
        return nil
    }

    /// Un file di un cliente rovinato o mancante (o l'indice rovinato): gli altri si aprono, l'avviso c'è, il file
    /// rovinato è messo da parte e i backup automatici si fermano.
    private static func provaPezziRovinati(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let d = try passatoDalDisco(ClientiFittizi.completi())
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        try Archivio.salva(d, in: cartella)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let indice = try ArchivioPezzi.leggiIndice(pezzi)
        guard indice.clienti.count >= 3 else { return "troppi pochi clienti per la prova" }
        let rovinato = indice.clienti[1], mancante = indice.clienti[2]
        try Data("{ non è json".utf8).write(to: pezzi.appendingPathComponent("Clienti/\(rovinato.file)"))
        try fm.removeItem(at: pezzi.appendingPathComponent("Clienti/\(mancante.file)"))

        let e = caricaEConverti(cartella)
        // Atteso: tutto tranne ciò che è dei due clienti
        var atteso = d
        let via: Set<String> = [rovinato.id, mancante.id]
        var gruppi: [String: DatiPrisma] = [:]
        let noti = Set(d.clienti.map(\.id))
        for campo in ArchivioPezzi.campiCliente {
            _ = campo.distribuisci(d, { noti.contains($0) ? $0 : ArchivioPezzi.gruppoAltri }, &gruppi)
        }
        for g in via { gruppi[g] = nil }
        let ordineGruppi = d.clienti.map(\.id).filter { !via.contains($0) } + [ArchivioPezzi.gruppoAltri]
        for campo in ArchivioPezzi.campiCliente {
            campo.raccogli(gruppi, ordineGruppi, indice.ordini[campo.chiave.rawValue], &atteso)
        }
        guard e.dati == atteso, e.dati.clienti.count == d.clienti.count - 2 else {
            return "con un file rovinato e uno mancante gli altri clienti non si aprono interi (\(e.dati.clienti.count) di \(d.clienti.count))"
        }
        guard let avviso = e.avviso, avviso.contains(rovinato.nome), avviso.contains(mancante.nome), e.daRiscrivere else {
            return "manca l'avviso dei file rovinati o mancanti"
        }
        let copie = Archivio.copieNonLeggibili(in: cartella)
        guard copie.count == 2, copie.contains(where: { $0.lastPathComponent.contains(rovinato.nome) }),
              (try? Data(contentsOf: copie.first(where: { $0.lastPathComponent.contains(rovinato.nome) })!)) == Data("{ non è json".utf8) else {
            return "il file rovinato non è stato messo da parte (o manca il segno del file mancante)"
        }
        // Dopo la riscrittura l'archivio si riapre pulito (senza i due clienti, con l'avviso dato una volta)
        let dopo = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard dopo.dati == atteso, dopo.avviso == nil else { return "dopo la riscrittura l'archivio non si riapre pulito" }

        // L'indice rovinato: si ricostruisce dai file dei clienti, nessun cliente si perde
        try Data("indice rovinato".utf8).write(to: pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice))
        let ricostruito = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard Set(ricostruito.dati.clienti.map(\.id)) == Set(atteso.clienti.map(\.id)), ricostruito.dati.posizioni.count == atteso.posizioni.count,
              ricostruito.dati.note.count == atteso.note.count, ricostruito.dati.appuntamenti == atteso.appuntamenti,
              ricostruito.avviso?.contains("indice") == true, ricostruito.daRiscrivere else {
            return "con l'indice rovinato l'archivio non si ricostruisce dai file dei clienti"
        }
        return nil
    }

    /// Le date di modifica dei file della cartella a pezzi.
    private static func date(_ pezzi: URL) -> [String: Date] {
        var r: [String: Date] = [:]
        let fm = FileManager.default
        for c in ["", "Clienti/"] {
            for nome in (try? fm.contentsOfDirectory(atPath: pezzi.appendingPathComponent(c).path)) ?? [] where nome.hasSuffix(".json") {
                r[c + nome] = (try? fm.attributesOfItem(atPath: pezzi.appendingPathComponent(c + nome).path))?[.modificationDate] as? Date
            }
        }
        return r
    }

    /// Una modifica a un cliente riscrive solo il suo file, l'indice solo se cambia (ordine, nomi, impostazioni).
    private static func provaSoloCambiati(_ base: URL) throws -> String? {
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        var d = try passatoDalDisco(ClientiFittizi.completi())
        try Archivio.salva(d, in: cartella)
        let letto = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard let sulDisco = letto.sulDisco else { return "l'archivio scritto non si riapre pulito" }
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-solo-cambiati", qos: .utility))
        s.prepara(sulDisco)
        var generazione = 0
        let indice = try ArchivioPezzi.leggiIndice(pezzi)
        guard let nota = d.note.firstIndex(where: { n in d.clienti.contains { $0.id == n.clienteId } }),
              let voce = indice.clienti.first(where: { $0.id == d.note[nota].clienteId }) else { return "nessuna nota di un cliente" }
        let fileCliente = "Clienti/" + voce.file

        func salva(_ passo: String, attesi: Set<String>, nonAttesi: Set<String> = []) -> String? {
            let prima = date(pezzi)
            generazione += 1
            s.accoda(d, generazione: generazione) { errore in print("ERRORE: \(errore.localizedDescription)") }
            s.attendi()
            let scritti = Set(s.sullaCoda { $0.ultimiScritti })
            guard scritti == attesi else { return "\(passo): scritti \(scritti.sorted()), attesi \(attesi.sorted())" }
            let dopo = date(pezzi)
            let cambiati = Set(dopo.keys.filter { prima[$0] != dopo[$0] })
            guard cambiati == attesi.subtracting(nonAttesi) else { return "\(passo): date di modifica cambiate per \(cambiati.sorted())" }
            guard let riletto = archivioSulDisco(cartella), let atteso = try? passatoDalDisco(d), riletto == atteso else {
                return "\(passo): l'archivio riletto non è quello salvato (o è rimasta una transazione, o la riserva dell'indice non è uguale all'indice)"
            }
            return nil
        }

        // Un tasto in una nota: solo il file del cliente
        d.note[nota].testo += " modificata"
        if let e = salva("una nota modificata", attesi: [fileCliente]) { return e }
        // Niente cambiato: niente scritto
        generazione += 1
        s.accoda(d, generazione: generazione) { _ in }
        s.attendi()
        guard s.sullaCoda({ $0.ultimiScritti }).isEmpty else { return "dati uguali riscritti" }
        // Una nota nuova: il file del cliente e l'indice (l'ordine delle note cambia)
        d.note.append(Nota(clienteId: voce.id, titolo: "Nuova", testo: "testo"))
        if let e = salva("una nota nuova", attesi: [fileCliente, "indice-riserva.json", "indice.json"]) { return e }
        // Un appuntamento spostato: solo l'agenda
        if !d.appuntamenti.isEmpty {
            d.appuntamenti[0].titolo += " spostato"
            if let e = salva("un appuntamento", attesi: ["agenda.json"]) { return e }
        }
        // Un'impostazione: solo l'indice
        d.impostazioni.nomeUtente = "Prova pezzi"
        if let e = salva("un'impostazione", attesi: ["indice-riserva.json", "indice.json"]) { return e }
        // Il nome di un cliente: il suo file e l'indice (che ha i nomi)
        if let i = d.clienti.firstIndex(where: { $0.id == voce.id }) {
            d.clienti[i].nome += " Bis"
            if let e = salva("il nome di un cliente", attesi: [fileCliente, "indice-riserva.json", "indice.json"]) { return e }
        }
        // Un cliente tolto (con i suoi elementi): l'indice, e il suo file sparisce
        if let tolto = indice.clienti.last(where: { $0.id != voce.id }) {
            d.clienti.removeAll { $0.id == tolto.id }
            for campo in ArchivioPezzi.campiCliente where campo.chiave != .clienti {
                var gruppi: [String: DatiPrisma] = [:]
                _ = campo.distribuisci(d, { $0 == tolto.id ? "via" : "resta" }, &gruppi)
                gruppi["via"] = nil
                campo.raccogli(gruppi, ["resta"], nil, &d)
            }
            if let e = salva("un cliente tolto", attesi: ["indice-riserva.json", "indice.json"]) { return e }
            guard !FileManager.default.fileExists(atPath: pezzi.appendingPathComponent("Clienti/" + tolto.file).path) else {
                return "il file del cliente tolto è rimasto"
            }
        }
        return nil
    }

    /// Un salvataggio interrotto a metà: un temporaneo lasciato, o i file dei clienti scritti senza l'indice.
    private static func provaInterrotto(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let a = try passatoDalDisco(DatiPrisma.demo())
        try Archivio.salva(a, in: cartella)
        // 1. Temporanei lasciati da una scrittura interrotta prima della rinomina: si ignorano e si tolgono
        let indice = try ArchivioPezzi.leggiIndice(pezzi)
        guard let primo = indice.clienti.first else { return "nessun cliente" }
        try Data("{ a metà".utf8).write(to: pezzi.appendingPathComponent("Clienti/\(primo.file).tmp-1a2b3c4d"))
        try Data("{ a metà".utf8).write(to: pezzi.appendingPathComponent("agenda.json.tmp-5e6f7a8b"))
        let e1 = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard e1.dati == a, e1.avviso == nil else { return "un temporaneo lasciato cambia l'archivio riaperto" }
        let restati = ((try? fm.contentsOfDirectory(atPath: pezzi.appendingPathComponent("Clienti").path)) ?? []) + ((try? fm.contentsOfDirectory(atPath: pezzi.path)) ?? [])
        guard !restati.contains(where: { $0.contains(".tmp-") }) else { return "i temporanei di un salvataggio interrotto restano" }

        // 2. Un giro di più file (una nota cambiata, un cliente nuovo, l'indice) interrotto prima della conferma:
        // l'archivio resta quello di prima, tutto intero, e i file nuovi a metà se ne vanno
        guard let sulDisco = e1.sulDisco else { return "l'archivio non si riapre pulito" }
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-interrotto", qos: .utility))
        s.prepara(sulDisco)
        var b = a
        if let i = b.note.firstIndex(where: { $0.clienteId == primo.id }) { b.note[i].testo += " cambiata" }
        var nuovo = Cliente.nuovo(tinta: .blu)
        nuovo.nome = "Cliente Arrivato In Una Transazione"
        nuovo.creatoIl = Date(timeIntervalSinceReferenceDate: 800_000_000)
        b.clienti.append(nuovo)
        b.posizioni.append(Posizione(clienteId: nuovo.id, canale: .indipendente, stato: .inEssere, area: .liquidita, nome: "Conto"))
        b.note.append(Nota(clienteId: primo.id, titolo: "Nuova", testo: "nella transazione"))
        b = try passatoDalDisco(b)
        s.sullaCoda { $0.interrompi = .primaDellaConferma }
        s.accoda(b, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        let transazione = pezzi.appendingPathComponent(ArchivioPezzi.nomeTransazione)
        guard (try? ArchivioPezzi.leggiIndice(pezzi)) == indice, fm.fileExists(atPath: transazione.path) else {
            return "l'interruzione prima della conferma non ha lasciato l'archivio com'era"
        }
        let e2 = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard e2.dati == a, e2.avviso == nil, !fm.fileExists(atPath: transazione.path) else {
            return "dopo un salvataggio interrotto prima della conferma l'archivio non è quello di prima (o i file a metà restano)"
        }

        // 3. Lo stesso giro confermato e interrotto dopo un solo file al suo posto: all'avvio si completa, tutto nuovo
        guard let sulDisco2 = e2.sulDisco else { return "l'archivio non si riapre pulito" }
        let s2 = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-interrotto-2", qos: .utility))
        s2.prepara(sulDisco2)
        s2.sullaCoda { $0.interrompi = .dopoLaConferma(spostati: 1) }
        s2.accoda(b, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s2.attendi()
        guard (try? ArchivioPezzi.leggiIndice(pezzi)) == indice else { return "l'indice è al suo posto prima degli altri file" }
        let e3 = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard e3.dati == b, e3.avviso == nil, !fm.fileExists(atPath: transazione.path) else {
            return "un salvataggio confermato e interrotto non si completa all'avvio (clienti \(e3.dati.clienti.count) di \(b.clienti.count), note \(e3.dati.note.count) di \(b.note.count))"
        }

        // 4. Una nota spostata da un cliente a un altro (due file dei clienti): mai persa né doppia, a ogni interruzione
        guard let altro = b.clienti.first(where: { $0.id != primo.id && $0.id != nuovo.id }),
              let i = b.note.firstIndex(where: { $0.clienteId == primo.id }) else { return "mancano i clienti per spostare una nota" }
        var c = b
        c.note[i].clienteId = altro.id
        let idNota = c.note[i].id
        for (n, interruzione) in [ScrittorePezzi.Interruzione.primaDellaConferma, .dopoLaConferma(spostati: 1)].enumerated() {
            guard let base = Archivio.carica(in: cartella).sulDisco else { return "l'archivio non si riapre pulito" }
            Archivio.coda.sync {}
            let sn = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-sposta-\(n)", qos: .utility))
            sn.prepara(base)
            sn.sullaCoda { $0.interrompi = interruzione }
            sn.accoda(c, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
            sn.attendi()
            let riaperto = Archivio.carica(in: cartella)
            Archivio.coda.sync {}
            let atteso = n == 0 ? b : c
            guard riaperto.dati.note.filter({ $0.id == idNota }).count == 1, riaperto.dati == atteso else {
                return "una nota spostata fra due clienti, interruzione \(n + 1): la nota c'è \(riaperto.dati.note.filter { $0.id == idNota }.count) volte"
            }
        }
        return nil
    }
}
