import Foundation

// La seconda revisione dell'archivio a pezzi (giro 0, tappa 3) dentro `Prisma --prova-backup`, una prova per ogni
// difetto: la ricostruzione dell'indice dalla sua riserva (impostazioni e contatori di Prisma ovunque di adesso, un
// cliente tolto che non torna), la conversione interrotta fra la conferma e la verifica, la copia d'avvio che non si
// apre quando l'archivio manca (mai i dati di prova sopra), archivio.json scritto da una versione di prima dopo la
// conversione, il backup che prende sempre l'archivio valido (mai la copia d'avvio, il segno della conversione o pezzi
// sciolti), il ripristino interrotto di un archivio a pezzi, il rifiuto dei backup a pezzi più recenti e la lettura
// delle prove che non completa le transazioni rimaste.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaSecondaRevisioneArchivio(_ base: URL) throws -> String? {
        let fm = FileManager.default
        try? fm.removeItem(at: base)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        let prove: [(String, (URL) throws -> String?)] = [
            ("Riserva", provaRiservaIndice), ("RiservaRovinata", provaRiservaRovinata),
            ("ConversioneInterrotta", provaConversioneInterrotta), ("CopiaAvvioRecente", provaCopiaAvvioPiuRecente),
            ("VersionePrecedente", provaArchivioJsonVersionePrecedente), ("BackupValido", provaBackupArchivioValido),
            ("ConversioneFallita", provaConversioneFallitaEBackup), ("RipristinoInterrotto", provaRipristinoInterrottoAPezzi),
            ("BackupRecente", provaBackupAPezziPiuRecente), ("LetturaProve", provaLetturaSenzaToccare),
        ]
        for (nome, prova) in prove {
            if let e = try prova(base.appendingPathComponent(nome, isDirectory: true)) { return e }
        }
        return nil
    }

    /// Un archivio a pezzi scritto e riaperto pulito una volta (così c'è la copia d'avvio).
    private static func archivioPulitoBis(_ cartella: URL, _ d: DatiPrisma) throws -> Archivio.EsitoCarica {
        try? FileManager.default.removeItem(at: cartella)
        try Archivio.salva(d, in: cartella)
        let e = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        return e
    }

    /// I contatori di Prisma ovunque di un archivio di prova.
    private static func conContatori(_ d: DatiPrisma, visto: Int, lamport: Int, seq: Int) -> DatiPrisma {
        var r = d
        r.impostazioni.ovunque.vistoFinoA = ["dispositivo-ipad": visto]
        r.impostazioni.ovunque.lamport = lamport
        r.impostazioni.ovunque.prossimoSeq = seq
        r.impostazioni.ovunque.generazione = visto
        return r
    }

    /// L'indice rovinato si ricostruisce dalla sua riserva: impostazioni e contatori di Prisma ovunque sono quelli di
    /// adesso (non quelli dell'avvio, che riapplicherebbero operazioni già unite) e un cliente aggiunto e tolto nella
    /// sessione, il cui file non si era potuto cancellare, non torna in vita (si mette da parte).
    private static func provaRiservaIndice(_ base: URL) throws -> String? {
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        var d = try passatoDalDisco(conContatori(ClientiFittizi.completi(), visto: 100, lamport: 50, seq: 7))
        guard let sulDisco = try archivioPulitoBis(cartella, d).sulDisco else { return "riserva: l'archivio non si riapre pulito" }
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-riserva", qos: .utility))
        s.prepara(sulDisco)
        var generazione = 0
        func salva(_ x: DatiPrisma) {
            generazione += 1
            s.accoda(x, generazione: generazione) { errore in print("ERRORE: \(errore.localizedDescription)") }
            s.attendi()
        }
        // Un cliente aggiunto e poi tolto; la cancellazione del suo file «non riesce» (il file torna com'era)
        var nuovo = Cliente.nuovo(tinta: .blu)
        nuovo.nome = "Cliente Tolto Nella Sessione"
        var conNuovo = d
        conNuovo.clienti.append(nuovo)
        conNuovo = try passatoDalDisco(conNuovo)
        salva(conNuovo)
        guard let voce = try ArchivioPezzi.leggiIndice(pezzi).clienti.first(where: { $0.id == nuovo.id }) else {
            return "riserva: il cliente nuovo non è nell'indice"
        }
        let fileNuovo = pezzi.appendingPathComponent("Clienti/" + voce.file)
        let contenuto = try Data(contentsOf: fileNuovo)
        salva(d)
        try contenuto.write(to: fileNuovo)
        // L'iPad unito fino a 130: i contatori vanno avanti
        d = try passatoDalDisco(conContatori(d, visto: 130, lamport: 80, seq: 12))
        salva(d)
        try Data("indice rovinato".utf8).write(to: ArchivioPezzi.indice(in: cartella))
        let e = caricaEConverti(cartella)
        guard e.dati.impostazioni.ovunque == d.impostazioni.ovunque, e.dati.impostazioni == d.impostazioni else {
            return "riserva: ricostruito l'indice, i contatori di Prisma ovunque sono tornati a quelli dell'avvio (visti \(e.dati.impostazioni.ovunque.vistoFinoA))"
        }
        guard !e.dati.clienti.contains(where: { $0.id == nuovo.id }), e.dati == d else {
            return "riserva: ricostruito l'indice, l'archivio non è quello dell'ultimo salvataggio (o il cliente tolto è tornato)"
        }
        guard e.avviso?.contains("copia di riserva") == true, e.daRiscrivere else {
            return "riserva: manca l'avviso della ricostruzione dalla riserva (\(e.avviso ?? "nessun avviso"))"
        }
        guard Archivio.copieNonLeggibili(in: cartella).contains(where: { (try? Data(contentsOf: $0)) == contenuto }) else {
            return "riserva: il file rimasto del cliente tolto non è stato messo da parte"
        }
        return nil
    }

    /// Indice e riserva rovinati insieme: resta la copia d'avvio, e l'avviso dice che impostazioni e contatori di Prisma
    /// ovunque sono tornati all'ultimo avvio (il limite che resta, con due file rovinati insieme).
    private static func provaRiservaRovinata(_ base: URL) throws -> String? {
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d0 = try passatoDalDisco(conContatori(DatiPrisma.demo(), visto: 100, lamport: 50, seq: 7))
        guard let sulDisco = try archivioPulitoBis(cartella, d0).sulDisco else { return "riserva rovinata: l'archivio non si riapre pulito" }
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-riserva-rovinata", qos: .utility))
        s.prepara(sulDisco)
        let d1 = try passatoDalDisco(conContatori(d0, visto: 130, lamport: 80, seq: 12))
        s.accoda(d1, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        for nome in [ArchivioPezzi.nomeIndice, ArchivioPezzi.nomeRiserva] {
            try Data("rovinato".utf8).write(to: pezzi.appendingPathComponent(nome))
        }
        let e = caricaEConverti(cartella)
        guard e.dati.clienti.map(\.id) == d0.clienti.map(\.id), e.dati.impostazioni.ovunque == d0.impostazioni.ovunque,
              e.avviso?.contains("Prisma ovunque") == true else {
            return "riserva rovinata: senza riserva l'archivio non si ricostruisce dalla copia d'avvio con l'avviso su Prisma ovunque (\(e.avviso ?? "nessun avviso"))"
        }
        return nil
    }

    /// La conversione di archivio.json interrotta fra la conferma della cartella e la verifica: all'avvio la verifica si
    /// rifà. Cartella identica → vale lei (archivio.json diventa archivio.json.vecchio); diversa (un campo perso nella
    /// divisione) → vale archivio.json, che si converte di nuovo. Mai archivio.json messo da parte senza confronto.
    private static func provaConversioneInterrotta(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let x = try passatoDalDisco(DatiPrisma.demo())
        guard let notaVia = x.note.first else { return "conversione interrotta: nessuna nota" }
        for (n, scritti) in [x, { var y = x; y.note.removeAll { $0.id == notaVia.id }; return y }()].enumerated() {
            let cartella = base.appendingPathComponent("Prisma-\(n)", isDirectory: true)
            try archivioDiPrima(cartella, x)
            let w = ScrittorePezzi(cartella: cartella)
            w.fermaPrimaDellaVerificaPerProva = true
            try Archivio.preparaCartelle(in: cartella)
            try w.scrivi(scritti)
            let segno = cartella.appendingPathComponent(Archivio.nomeConversioneDaVerificare)
            let vecchio = cartella.appendingPathComponent(Archivio.nomeFileVecchio)
            guard ArchivioPezzi.presente(in: cartella), fm.fileExists(atPath: segno.path), fm.fileExists(atPath: vecchio.path) else {
                return "conversione interrotta \(n + 1): manca il segno della conversione da verificare"
            }
            let e = caricaEConverti(cartella)
            guard e.dati == x else {
                return "conversione interrotta \(n + 1): all'avvio non si apre l'archivio di archivio.json (note \(e.dati.note.count) di \(x.note.count))"
            }
            if n == 0 {
                guard !e.daRiscrivere, e.avviso == nil, !fm.fileExists(atPath: vecchio.path), !fm.fileExists(atPath: segno.path),
                      fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileConvertito).path) else {
                    return "conversione interrotta 1: verificata all'avvio, archivio.json non è diventato archivio.json.vecchio (o il segno resta)"
                }
            } else {
                guard e.daRiscrivere, !fm.fileExists(atPath: segno.path), !fm.fileExists(atPath: vecchio.path) else {
                    return "conversione interrotta 2: con la cartella diversa archivio.json non ha vinto (o non si è convertito di nuovo)"
                }
            }
            let riaperto = Archivio.carica(in: cartella)
            Archivio.coda.sync {}
            guard riaperto.dati == x, riaperto.avviso == nil else {
                return "conversione interrotta \(n + 1): dopo la verifica l'archivio non si riapre identico"
            }
        }
        return nil
    }

    /// L'archivio manca e la copia d'avvio l'ha scritta un Prisma più recente: sola lettura, mai i dati di prova scritti
    /// sopra (né nella cartella né nella copia d'avvio, l'unica copia rimasta), anche all'avvio dopo.
    private static func provaCopiaAvvioPiuRecente(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(ClientiFittizi.completi())
        _ = try archivioPulitoBis(cartella, d)
        let copia = cartella.appendingPathComponent(Archivio.nomeCopiaAvvio, isDirectory: true)
        let fileIndiceCopia = copia.appendingPathComponent(ArchivioPezzi.nomeIndice)
        guard var oggetto = try JSONSerialization.jsonObject(with: Data(contentsOf: fileIndiceCopia)) as? [String: Any] else {
            return "copia d'avvio più recente: l'indice della copia non si legge"
        }
        oggetto["versione"] = DatiPrisma.versioneAttuale + 1
        let indiceRecente = try JSONSerialization.data(withJSONObject: oggetto, options: [.sortedKeys])
        try indiceRecente.write(to: fileIndiceCopia)
        try fm.removeItem(at: ArchivioPezzi.cartellaPezzi(in: cartella))
        for giro in 1...2 {
            let e = Archivio.carica(in: cartella)
            Archivio.coda.sync {}
            guard e.solaLettura, !e.daRiscrivere else {
                return "copia d'avvio più recente, avvio \(giro): non aperta in sola lettura (\(e.avviso ?? "nessun avviso"))"
            }
            guard (try? Data(contentsOf: fileIndiceCopia)) == indiceRecente,
                  (try? ArchivioPezzi.leggiIndice(ArchivioPezzi.cartellaPezzi(in: cartella)))?.clienti.count == d.clienti.count else {
                return "copia d'avvio più recente, avvio \(giro): i dati di prova (o altro) sono stati scritti sopra la copia"
            }
        }
        return nil
    }

    /// Una versione di Prisma di prima scrive archivio.json dopo la conversione (non conosce la cartella a pezzi): vale
    /// la cartella, con le modifiche fatte dopo la conversione; archivio.json si mette da parte, mai usato né perso.
    private static func provaArchivioJsonVersionePrecedente(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(ClientiFittizi.completi())
        guard let sulDisco = try archivioPulitoBis(cartella, d).sulDisco else { return "versione precedente: l'archivio non si riapre pulito" }
        var dopo = d
        var nuovo = Cliente.nuovo(tinta: .blu)
        nuovo.nome = "Cliente Dopo La Conversione"
        dopo.clienti.append(nuovo)
        dopo = try passatoDalDisco(dopo)
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-versione-precedente", qos: .utility))
        s.prepara(sulDisco)
        s.accoda(dopo, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        // La versione di prima: non trova archivio.json e scrive i dati di prova (o la copia di prima)
        let vecchio = cartella.appendingPathComponent(Archivio.nomeFileVecchio)
        let scrittoDallaVecchia = try Archivio.codificatore.encode(DatiPrisma.demo())
        try scrittoDallaVecchia.write(to: vecchio)
        try fm.setAttributes([.modificationDate: Date(timeIntervalSinceNow: 120)], ofItemAtPath: vecchio.path)
        let e = caricaEConverti(cartella)
        guard e.dati == dopo, e.dati.clienti.contains(where: { $0.id == nuovo.id }) else {
            return "versione precedente: archivio.json scritto dalla versione di prima ha preso il posto della cartella a pezzi"
        }
        guard e.avviso?.contains("versione precedente") == true, !fm.fileExists(atPath: vecchio.path) else {
            return "versione precedente: manca l'avviso (o archivio.json resta al suo posto)"
        }
        let messi = ((try? fm.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.lastPathComponent.hasPrefix(Archivio.prefissoVersionePrecedente) }
        guard messi.count == 1, (try? Data(contentsOf: messi[0])) == scrittoDallaVecchia else {
            return "versione precedente: archivio.json della versione di prima non è stato messo da parte intero"
        }
        let riaperto = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard riaperto.dati == dopo, riaperto.avviso == nil else { return "versione precedente: all'avvio dopo l'archivio non è quello di adesso" }
        return nil
    }

    /// I nomi in uno zip di backup, senza la cartella «Prisma/» davanti.
    private static func nomiNelBackup(_ zip: URL) throws -> [String] {
        try LettoreZip.nomi(zip).map { $0.hasPrefix("Prisma/") ? String($0.dropFirst(7)) : $0 }
    }

    /// Il backup prende l'archivio che varrebbe all'avvio: con la conversione da verificare archivio.json (non i pezzi e
    /// non il segnaposto); con pezzi sciolti senza indice archivio.json; senza nessun archivio non si fa. Mai la copia
    /// d'avvio, il segno della conversione o una cartella scartata.
    private static func provaBackupArchivioValido(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let x = try passatoDalDisco(DatiPrisma.demo())
        // 1. Conversione da verificare (interrotta), con i pezzi diversi
        let primo = base.appendingPathComponent("Uno/Prisma", isDirectory: true)
        try archivioDiPrima(primo, x)
        let w = ScrittorePezzi(cartella: primo)
        w.fermaPrimaDellaVerificaPerProva = true
        try Archivio.preparaCartelle(in: primo)
        try w.scrivi(ClientiFittizi.completi())
        let zip1 = try GestoreBackup.crea(sorgente: primo, destinazione: base.appendingPathComponent("Backup1", isDirectory: true))
        let nomi1 = try nomiNelBackup(zip1)
        guard !nomi1.contains(where: { $0.hasPrefix(ArchivioPezzi.nomeCartella + "/") }), !nomi1.contains(Archivio.nomeConversioneDaVerificare),
              let dentro1 = try LettoreZip.dati(zip1, voce: "Prisma/" + Archivio.nomeFileVecchio),
              (try? Archivio.decodifica(dentro1)) == x else {
            return "backup valido 1: con la conversione da verificare il backup non ha archivio.json (o ha i pezzi o il segno: \(nomi1.filter { !$0.hasPrefix("Vera/") }.sorted()))"
        }
        let estratto1 = try GestoreBackup.estrai(zip1)
        GestoreBackup.pulisciEstrazione(estratto1.cartella)
        guard estratto1.dati == x else { return "backup valido 1: il ripristino non dà archivio.json" }

        // 2. Pezzi sciolti senza indice (una cancellazione a metà) e una copia d'avvio vecchia accanto ad archivio.json
        let secondo = base.appendingPathComponent("Due/Prisma", isDirectory: true)
        try archivioDiPrima(secondo, x)
        let sciolti = ArchivioPezzi.cartellaPezzi(in: secondo).appendingPathComponent(ArchivioPezzi.nomeClienti, isDirectory: true)
        try fm.createDirectory(at: sciolti, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: sciolti.appendingPathComponent("rimasto-1234abcd.json"))
        let altra = base.appendingPathComponent("Altra/Prisma", isDirectory: true)
        try Archivio.salva(ClientiFittizi.completi(), in: altra)
        try fm.copyItem(at: ArchivioPezzi.cartellaPezzi(in: altra), to: secondo.appendingPathComponent(Archivio.nomeCopiaAvvio, isDirectory: true))
        let zip2 = try GestoreBackup.crea(sorgente: secondo, destinazione: base.appendingPathComponent("Backup2", isDirectory: true))
        let nomi2 = try nomiNelBackup(zip2)
        guard !nomi2.contains(where: { $0.hasPrefix(ArchivioPezzi.nomeCartella + "/") || $0.hasPrefix(Archivio.nomeCopiaAvvio) }),
              let dentro2 = try LettoreZip.dati(zip2, voce: "Prisma/" + Archivio.nomeFileVecchio), (try? Archivio.decodifica(dentro2)) == x else {
            return "backup valido 2: con pezzi sciolti senza indice il backup non ha archivio.json (o ha i pezzi o la copia d'avvio)"
        }

        // 3. Nessun archivio (solo pezzi sciolti): il backup non si fa
        let terzo = base.appendingPathComponent("Tre/Prisma", isDirectory: true)
        try fm.createDirectory(at: terzo.appendingPathComponent("Documenti"), withIntermediateDirectories: true)
        try fm.createDirectory(at: ArchivioPezzi.cartellaPezzi(in: terzo), withIntermediateDirectories: true)
        try fm.copyItem(at: sciolti, to: ArchivioPezzi.cartellaPezzi(in: terzo).appendingPathComponent(ArchivioPezzi.nomeClienti))
        do {
            try GestoreBackup.crea(sorgente: terzo, destinazione: base.appendingPathComponent("Backup3", isDirectory: true))
            return "backup valido 3: fatto un backup senza archivio"
        } catch ErroreBackup.senzaArchivio {}
        guard GestoreBackup.elenca(base.appendingPathComponent("Backup3", isDirectory: true)).isEmpty else {
            return "backup valido 3: è rimasto un backup senza archivio"
        }
        return nil
    }

    /// Una conversione che non si verifica: la cartella a pezzi se ne va tutta (con una rinomina, niente pezzi sciolti) e
    /// con lei la copia d'avvio della cartella a pezzi (di un altro giorno); il backup prende archivio.json e nient'altro
    /// dell'archivio, e il ripristino lo riapre.
    private static func provaConversioneFallitaEBackup(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let x = try passatoDalDisco(DatiPrisma.demo())
        try archivioDiPrima(cartella, x)
        let altra = base.appendingPathComponent("Altra/Prisma", isDirectory: true)
        try Archivio.salva(ClientiFittizi.completi(), in: altra)
        let copia = cartella.appendingPathComponent(Archivio.nomeCopiaAvvio, isDirectory: true)
        try fm.copyItem(at: ArchivioPezzi.cartellaPezzi(in: altra), to: copia)
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-conversione-fallita", qos: .utility))
        s.sullaCoda { $0.verificaFallitaPerProva = true }
        let e = Archivio.carica(in: cartella)
        s.riscriviTutto(e.dati) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        Archivio.coda.sync {}
        let nomi = (try? fm.contentsOfDirectory(atPath: cartella.path)) ?? []
        guard s.sullaCoda({ $0.formatoVecchio }), !fm.fileExists(atPath: ArchivioPezzi.cartellaPezzi(in: cartella).path),
              !fm.fileExists(atPath: copia.path), !nomi.contains(where: { $0.hasPrefix(Archivio.prefissoCartellaScartata) }),
              fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeConversioneDaVerificare).path) else {
            return "conversione fallita: restano la cartella a pezzi, la copia d'avvio o una cartella scartata (o manca il segno: \(nomi.sorted()))"
        }
        // Un salvataggio in formato di prima, poi il backup
        var y = x
        y.impostazioni.nomeUtente = "Dopo la conversione fallita"
        s.accoda(y, generazione: 3) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        let zip = try GestoreBackup.crea(sorgente: cartella, destinazione: base.appendingPathComponent("Backup", isDirectory: true))
        let nomiZip = try nomiNelBackup(zip)
        guard !nomiZip.contains(where: { $0.hasPrefix(Archivio.nomeCopiaAvvio) || $0.hasPrefix(ArchivioPezzi.nomeCartella + "/") }),
              !nomiZip.contains(Archivio.nomeConversioneDaVerificare) else {
            return "conversione fallita: nel backup c'è la copia d'avvio, la cartella a pezzi o il segno"
        }
        let estratto = try GestoreBackup.estrai(zip)
        let ripristino = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        guard estratto.dati == y else {
            GestoreBackup.pulisciEstrazione(estratto.cartella)
            return "conversione fallita: il backup non ha l'ultimo archivio.json"
        }
        try GestoreBackup.sostituisci(cartellaDati: ripristino, con: estratto.cartella)
        let riaperto = Archivio.carica(in: ripristino)
        Archivio.coda.sync {}
        guard riaperto.dati.impostazioni.nomeUtente == y.impostazioni.nomeUtente, riaperto.dati.clienti == y.clienti else {
            return "conversione fallita: dopo il ripristino l'archivio non è quello salvato"
        }
        return nil
    }

    /// Un ripristino interrotto con l'archivio di prima a pezzi in «Prisma.precedente»: all'avvio torna al suo posto (con
    /// la cartella dell'archivio sparita, o rimasta con i soli documenti).
    private static func provaRipristinoInterrottoAPezzi(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let d = try passatoDalDisco(ClientiFittizi.completi())
        for (n, conDocumenti) in [false, true].enumerated() {
            let cartella = base.appendingPathComponent("Caso\(n)/Prisma", isDirectory: true)
            let (_, precedente) = GestoreBackup.cartelleRipristino(cartella)
            try Archivio.salva(d, in: precedente)
            if conDocumenti { try fm.createDirectory(at: cartella.appendingPathComponent("Documenti"), withIntermediateDirectories: true) }
            let e = Archivio.carica(in: cartella)
            Archivio.coda.sync {}
            guard ArchivioPezzi.presente(in: cartella), !fm.fileExists(atPath: precedente.path), e.dati == d,
                  e.avviso?.contains("ripristino era stato interrotto") == true else {
                return "ripristino interrotto a pezzi \(n + 1): l'archivio di prima non è tornato al suo posto (\(e.avviso ?? "nessun avviso"))"
            }
        }
        return nil
    }

    /// Un backup a pezzi con l'indice di un formato o di una versione più recente non si ripristina («versione più
    /// recente», non «non è un backup»).
    private static func provaBackupAPezziPiuRecente(_ base: URL) throws -> String? {
        let d = try passatoDalDisco(DatiPrisma.demo())
        let casi = [#"{"formato": \#(ArchivioPezzi.formatoAttuale + 1), "clienti": "un formato nuovo"}"#,
                    #"{"formato": 1, "versione": \#(DatiPrisma.versioneAttuale + 1), "clienti": []}"#]
        for (n, testo) in casi.enumerated() {
            let cartella = base.appendingPathComponent("Caso\(n)/Prisma", isDirectory: true)
            try Archivio.salva(d, in: cartella)
            try Data(testo.utf8).write(to: ArchivioPezzi.indice(in: cartella))
            let zip = try GestoreBackup.crea(sorgente: cartella, destinazione: base.appendingPathComponent("Backup\(n)", isDirectory: true))
            do {
                let e = try GestoreBackup.estrai(zip)
                GestoreBackup.pulisciEstrazione(e.cartella)
                return "backup a pezzi più recente \(n + 1): accettato"
            } catch ErroreBackup.versionePiuRecente {
            } catch {
                return "backup a pezzi più recente \(n + 1): rifiutato con «\(error.localizedDescription)» invece di «versione più recente»"
            }
        }
        return nil
    }

    /// La lettura delle prove (`archivioSulDisco`) vede una transazione confermata e non completata (che
    /// `leggiPerRipristino` completerebbe): una prova non controlla mai un archivio che ha aggiustato lei.
    private static func provaLetturaSenzaToccare(_ base: URL) throws -> String? {
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(DatiPrisma.demo())
        guard let sulDisco = try archivioPulitoBis(cartella, d).sulDisco, let primo = d.clienti.first else {
            return "lettura delle prove: l'archivio non si riapre pulito"
        }
        guard archivioSulDisco(cartella) == d else { return "lettura delle prove: l'archivio pulito non si legge" }
        var b = d
        b.note.append(Nota(clienteId: primo.id, titolo: "Nuova", testo: "nella transazione"))
        b = try passatoDalDisco(b)
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-lettura", qos: .utility))
        s.prepara(sulDisco)
        s.sullaCoda { $0.interrompi = .dopoLaConferma(spostati: 0) }
        s.accoda(b, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        guard archivioSulDisco(cartella) == nil else {
            return "lettura delle prove: una transazione rimasta non si vede"
        }
        return nil
    }
}
