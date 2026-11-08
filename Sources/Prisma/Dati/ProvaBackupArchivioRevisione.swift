import Foundation

// Le correzioni della revisione dell'archivio a pezzi (giro 0, tappa 3) dentro `Prisma --prova-backup`, una prova per
// ogni difetto trovato: file che adesso non si leggono (sola lettura, nulla spostato), indici scritti da un Prisma più
// recente (sola lettura, anche se non si decodificano), copie di due clienti omonimi, il formato di prima dopo un
// ripristino, un archivio.json rimasto più vecchio della cartella, una cartella con le sole sezioni, la ricostruzione
// che non riporta in vita i clienti tolti, un NaN nella conversione, le copie d'avvio interrotte, il segnaposto per le
// versioni di prima nei backup, il backup protetto della cartella a pezzi e la copia d'avvio quando l'archivio manca.
// Le transazioni (un cambio di più file interrotto a metà) sono in `provaInterrotto`.

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaRevisioneArchivio(_ base: URL) throws -> String? {
        let fm = FileManager.default
        try? fm.removeItem(at: base)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        let prove: [(String, (URL) throws -> String?)] = [
            ("NonLeggibiliOra", provaNonLeggibiliOra), ("IndiceFuturo", provaIndiceFuturo), ("Omonimi", provaOmonimi),
            ("FormatoVecchio", provaFormatoVecchioERipristino), ("VecchioStantio", provaArchivioJsonStantio),
            ("SoloSezioni", provaSoloSezioni), ("Ricostruzione", provaRicostruzioneSenzaTolti), ("NaN", provaNaN),
            ("CopiaInterrotta", provaCopiaInterrottaESegnaposto), ("Protetto", provaProtettoAPezzi), ("CopiaAvvio", provaCopiaAvvio),
            ("TransazioneRimasta", provaTransazioneRimasta), ("DueRicostruzioni", provaDueRicostruzioni),
        ]
        for (nome, prova) in prove {
            if let e = try prova(base.appendingPathComponent(nome, isDirectory: true)) { return e }
        }
        return nil
    }

    /// Un archivio a pezzi scritto e riaperto pulito una volta (così c'è la copia d'avvio).
    private static func archivioPulito(_ cartella: URL, _ d: DatiPrisma) throws -> Archivio.EsitoCarica {
        try? FileManager.default.removeItem(at: cartella)
        try Archivio.salva(d, in: cartella)
        let e = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        return e
    }

    /// I nomi dei file nella cartella dell'archivio e nella cartella a pezzi (per vedere che nulla si è mosso).
    private static func elencoFile(_ cartella: URL) -> [String] {
        (FileManager.default.subpaths(atPath: cartella.path) ?? []).filter { !$0.hasPrefix(Archivio.nomeCopiaAvvio) }.sorted()
    }

    /// Toglie un cliente e tutto ciò che è suo (come dopo «Elimina cliente»).
    private static func senzaCliente(_ d: DatiPrisma, _ id: String) -> DatiPrisma {
        var r = d
        r.clienti.removeAll { $0.id == id }
        for campo in ArchivioPezzi.campiCliente where campo.chiave != .clienti {
            var gruppi: [String: DatiPrisma] = [:]
            _ = campo.distribuisci(r, { $0 == id ? "via" : "resta" }, &gruppi)
            gruppi["via"] = nil
            campo.raccogli(gruppi, ["resta"], nil, &r)
        }
        return r
    }

    /// Un file (o l'indice) che c'è ma adesso non si legge: sola lettura, nessun file spostato, nessuna copia.
    private static func provaNonLeggibiliOra(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(ClientiFittizi.completi())
        _ = try archivioPulito(cartella, d)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let indice = try ArchivioPezzi.leggiIndice(pezzi)
        guard let voce = indice.clienti.first else { return "file non leggibili adesso: nessun cliente" }
        for (nome, file) in [("il file di un cliente", pezzi.appendingPathComponent("Clienti/" + voce.file)),
                             ("l'indice", pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice))] {
            let prima = elencoFile(cartella)
            try fm.setAttributes([.posixPermissions: 0o000], ofItemAtPath: file.path)
            defer { try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path) }
            // Chi può leggere anche senza permessi (l'amministratore) non può fare questa prova
            if (try? Data(contentsOf: file)) != nil { return nil }
            let e = Archivio.carica(in: cartella)
            Archivio.coda.sync {}
            guard e.solaLettura, !e.daRiscrivere, e.avviso?.contains("Non riesco ad aprire") == true else {
                return "file non leggibili adesso: con \(nome) non leggibile l'archivio non si apre in sola lettura (\(e.avviso ?? "nessun avviso"))"
            }
            guard elencoFile(cartella) == prima, Archivio.copieNonLeggibili(in: cartella).isEmpty else {
                return "file non leggibili adesso: con \(nome) non leggibile dei file sono stati spostati o messi da parte"
            }
        }
        let dopo = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard dopo.dati == d, dopo.avviso == nil else { return "file non leggibili adesso: tornati leggibili, l'archivio non si riapre intero" }
        return nil
    }

    /// Un indice scritto da un Prisma più recente, anche se non si decodifica: sola lettura, i file non si toccano, e
    /// un backup così è «di una versione più recente».
    private static func provaIndiceFuturo(_ base: URL) throws -> String? {
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(DatiPrisma.demo())
        _ = try archivioPulito(cartella, d)
        let fileIndice = ArchivioPezzi.indice(in: cartella)
        let originale = try Data(contentsOf: fileIndice)
        let casi = [#"{"formato": \#(ArchivioPezzi.formatoAttuale + 1), "clienti": "un formato nuovo"}"#,
                    #"{"formato": 1, "versione": \#(DatiPrisma.versioneAttuale + 1), "impostazioni": 5, "clienti": []}"#,
                    #"{"formato": \#(ArchivioPezzi.formatoAttuale + 1), "versione": \#(DatiPrisma.versioneAttuale), "clienti": []}"#]
        for (n, testo) in casi.enumerated() {
            try Data(testo.utf8).write(to: fileIndice)
            let prima = elencoFile(cartella)
            let e = Archivio.carica(in: cartella)
            Archivio.coda.sync {}
            guard e.solaLettura, e.bloccaRipristino, e.avviso == Archivio.avvisoPiuRecente, !e.daRiscrivere else {
                return "indice più recente \(n + 1): non aperto in sola lettura (\(e.avviso ?? "nessun avviso"))"
            }
            guard elencoFile(cartella) == prima, (try? Data(contentsOf: fileIndice)) == Data(testo.utf8),
                  Archivio.copieNonLeggibili(in: cartella).isEmpty else {
                return "indice più recente \(n + 1): l'archivio è stato toccato (indice spostato o file riscritti)"
            }
            do {
                _ = try Archivio.leggiPerRipristino(cartella)
                return "indice più recente \(n + 1): accettato come backup"
            } catch ErroreBackup.versionePiuRecente {
            } catch {
                return "indice più recente \(n + 1): il backup è rifiutato con «\(error.localizedDescription)» invece di «versione più recente»"
            }
        }
        try originale.write(to: fileIndice)
        let dopo = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard dopo.dati == d, dopo.avviso == nil else { return "indice più recente: rimesso quello di prima, l'archivio non si riapre intero" }
        return nil
    }

    /// Due clienti omonimi con il file rovinato nello stesso avvio: tutte e due le copie messe da parte.
    private static func provaOmonimi(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        var d = ClientiFittizi.completi()
        guard d.clienti.count >= 3 else { return "omonimi: troppi pochi clienti" }
        d.clienti[1].nome = "Mario Rossi"
        d.clienti[2].nome = "Mario Rossi"
        d = try passatoDalDisco(d)
        _ = try archivioPulito(cartella, d)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let indice = try ArchivioPezzi.leggiIndice(pezzi)
        let omonimi = indice.clienti.filter { $0.nome == "Mario Rossi" }
        guard omonimi.count == 2 else { return "omonimi: l'indice non ha i due clienti omonimi" }
        for (n, v) in omonimi.enumerated() {
            try Data("{ rovinato \(n)".utf8).write(to: pezzi.appendingPathComponent("Clienti/" + v.file))
        }
        let e = caricaEConverti(cartella)
        let copie = Archivio.copieNonLeggibili(in: cartella)
        let contenuti = Set(copie.compactMap { try? String(contentsOf: $0, encoding: .utf8) })
        guard e.dati.clienti.count == d.clienti.count - 2, copie.count == 2, contenuti == ["{ rovinato 0", "{ rovinato 1"] else {
            return "omonimi: le copie dei due file rovinati non ci sono tutte e due (\(copie.map(\.lastPathComponent)))"
        }
        guard omonimi.allSatisfy({ !fm.fileExists(atPath: pezzi.appendingPathComponent("Clienti/" + $0.file).path) }) else {
            return "omonimi: un file rovinato è rimasto nella cartella dei clienti"
        }
        return nil
    }

    /// Conversione non verificata (si scrive archivio.json), poi il ripristino di un backup a pezzi nella stessa sessione:
    /// i salvataggi dopo vanno nella cartella a pezzi ripristinata, e all'avvio dopo ci sono.
    private static func provaFormatoVecchioERipristino(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let x = try passatoDalDisco(DatiPrisma.demo())
        try archivioDiPrima(cartella, x)
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-formato-vecchio", qos: .utility))
        s.sullaCoda { $0.verificaFallitaPerProva = true }
        let e = Archivio.carica(in: cartella)
        guard e.daRiscrivere else { return "formato di prima: archivio.json non da convertire" }
        s.riscriviTutto(e.dati) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        Archivio.coda.sync {}
        guard s.sullaCoda({ $0.formatoVecchio }), !ArchivioPezzi.presente(in: cartella),
              fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileVecchio).path) else {
            return "formato di prima: una conversione non verificata non torna ad archivio.json"
        }
        // Il ripristino di un backup a pezzi (un altro archivio)
        let altra = base.appendingPathComponent("Altra/Prisma", isDirectory: true)
        let y = try passatoDalDisco(ClientiFittizi.completi())
        try Archivio.salva(y, in: altra)
        let zip = try GestoreBackup.crea(sorgente: altra, destinazione: base.appendingPathComponent("Backup", isDirectory: true))
        let estratto = try GestoreBackup.estrai(zip)
        try GestoreBackup.sostituisci(cartellaDati: cartella, con: estratto.cartella)
        s.ricomincia()
        var z = y
        z.impostazioni.nomeUtente = "Dopo il ripristino"
        s.accoda(z, generazione: 7) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        guard ArchivioPezzi.presente(in: cartella), !fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileVecchio).path) else {
            return "formato di prima: dopo il ripristino di un backup a pezzi si scrive ancora archivio.json"
        }
        let riaperto = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard riaperto.dati == z, riaperto.avviso == nil else {
            return "formato di prima: le modifiche fatte dopo il ripristino si sono perse"
        }
        return nil
    }

    /// Un archivio.json rimasto accanto alla cartella e più vecchio (la rinomina della conversione non era riuscita):
    /// con un file di un cliente rovinato vale la cartella, non archivio.json.
    private static func provaArchivioJsonStantio(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(ClientiFittizi.completi())
        _ = try archivioPulito(cartella, d)
        let vecchio = cartella.appendingPathComponent(Archivio.nomeFileVecchio)
        try Archivio.codificatore.encode(DatiPrisma.demo()).write(to: vecchio)
        try fm.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -3_600)], ofItemAtPath: vecchio.path)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let indice = try ArchivioPezzi.leggiIndice(pezzi)
        guard let rovinato = indice.clienti.first else { return "archivio.json vecchio: nessun cliente" }
        try Data("{ rovinato".utf8).write(to: pezzi.appendingPathComponent("Clienti/" + rovinato.file))
        let e = caricaEConverti(cartella)
        guard e.dati.clienti.count == d.clienti.count - 1, !e.dati.clienti.contains(where: { $0.id == rovinato.id }),
              Set(e.dati.clienti.map(\.id)).isSubset(of: Set(d.clienti.map(\.id))) else {
            return "archivio.json vecchio: con un file rovinato si è aperto archivio.json invece della cartella"
        }
        guard !fm.fileExists(atPath: vecchio.path), fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileConvertito).path) else {
            return "archivio.json vecchio: non è stato messo da parte come archivio.json.vecchio"
        }
        return nil
    }

    /// Nessun cliente ma agenda e attività, e l'indice sparito: si ricostruisce dalle sezioni (mai la copia d'avvio
    /// sopra, mai i dati di prova).
    private static func provaSoloSezioni(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let demo = DatiPrisma.demo()
        var d = ArchivioPezzi.vuoto
        d.appuntamenti = demo.appuntamenti
        d.attivita = demo.attivita
        d = try passatoDalDisco(d)
        guard !d.appuntamenti.isEmpty else { return "sole sezioni: i dati di prova non hanno appuntamenti" }
        try? fm.removeItem(at: cartella)
        try Archivio.salva(d, in: cartella)
        try fm.removeItem(at: ArchivioPezzi.indice(in: cartella))
        let e = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard e.dati.appuntamenti == d.appuntamenti, e.dati.attivita == d.attivita, e.dati.clienti.isEmpty, !e.solaLettura else {
            return "sole sezioni: senza indice e senza clienti agenda e attività sono state sostituite (\(e.dati.clienti.count) clienti, \(e.dati.appuntamenti.count) appuntamenti)"
        }
        return nil
    }

    /// La ricostruzione dell'indice non riporta in vita un cliente tolto: né se il salvataggio che lo toglieva si è
    /// interrotto prima di cancellarne il file, né se il suo file è rimasto da prima dell'ultimo avvio.
    private static func provaRicostruzioneSenzaTolti(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(ClientiFittizi.completi())
        let primo = try archivioPulito(cartella, d)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let indice = try ArchivioPezzi.leggiIndice(pezzi)
        guard let tolto = indice.clienti.last, let sulDisco = primo.sulDisco else { return "ricostruzione: nessun cliente" }
        let fileTolto = pezzi.appendingPathComponent("Clienti/" + tolto.file)
        let contenutoTolto = try Data(contentsOf: fileTolto)
        // 1. Tolto con un salvataggio interrotto dopo tutti gli spostamenti e prima di cancellare il file, poi l'indice
        //    rovinato: all'avvio il salvataggio si completa (file cancellato) e il cliente non torna
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-ricostruzione", qos: .utility))
        s.prepara(sulDisco)
        s.sullaCoda { $0.interrompi = .dopoLaConferma(spostati: 1_000) }
        s.accoda(senzaCliente(d, tolto.id), generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        guard fm.fileExists(atPath: fileTolto.path) else { return "ricostruzione: l'interruzione ha già cancellato il file" }
        try Data("indice rovinato".utf8).write(to: ArchivioPezzi.indice(in: cartella))
        let e1 = caricaEConverti(cartella)
        guard !e1.dati.clienti.contains(where: { $0.id == tolto.id }), e1.dati.clienti.count == d.clienti.count - 1 else {
            return "ricostruzione: un cliente tolto (salvataggio interrotto prima di cancellarne il file) è tornato"
        }
        // 2. Il file di un cliente tolto prima dell'ultimo avvio è ancora lì (cancellazione non riuscita): con l'indice
        //    rovinato si mette da parte, non si riprende
        let pulito = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard pulito.avviso == nil, !pulito.dati.clienti.contains(where: { $0.id == tolto.id }) else {
            return "ricostruzione: dopo la riscrittura l'archivio non si riapre pulito"
        }
        for u in Archivio.copieNonLeggibili(in: cartella) { try? fm.removeItem(at: u) }
        try contenutoTolto.write(to: fileTolto)
        try Data("indice rovinato".utf8).write(to: ArchivioPezzi.indice(in: cartella))
        let e2 = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard !e2.dati.clienti.contains(where: { $0.id == tolto.id }), e2.dati.clienti.count == d.clienti.count - 1 else {
            return "ricostruzione: il file rimasto di un cliente tolto prima dell'ultimo avvio l'ha riportato in vita"
        }
        guard Archivio.copieNonLeggibili(in: cartella).contains(where: { (try? Data(contentsOf: $0)) == contenutoTolto }) else {
            return "ricostruzione: il file rimasto di un cliente tolto non è stato messo da parte"
        }
        return nil
    }

    /// Un archivio.json di prima con un NaN si converte (la verifica confronta il JSON, non `==`).
    private static func provaNaN(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        var d = try passatoDalDisco(DatiPrisma.demo())
        guard !d.posizioni.isEmpty else { return "NaN: nessuna posizione" }
        d.posizioni[0].controvalore = .nan
        try archivioDiPrima(cartella, d)
        let e = caricaEConverti(cartella)
        guard e.daRiscrivere, ArchivioPezzi.presente(in: cartella), !fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileVecchio).path),
              fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeFileConvertito).path) else {
            return "NaN: un archivio.json con un NaN non si converte"
        }
        let riaperto = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard riaperto.avviso == nil, riaperto.dati.posizioni.first?.controvalore?.isNaN == true else {
            return "NaN: l'archivio convertito non si riapre con il NaN"
        }
        return nil
    }

    /// Una copia d'avvio interrotta («Archivio-all-avvio.tmp-…») si toglie all'avvio e non va nei backup; il backup della
    /// cartella a pezzi ha il segnaposto per le versioni di prima, che questa versione ignora.
    private static func provaCopiaInterrottaESegnaposto(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(DatiPrisma.demo())
        _ = try archivioPulito(cartella, d)
        let interrotta = cartella.appendingPathComponent(Archivio.nomeCopiaAvvio + ".tmp-1a2b3c4d", isDirectory: true)
        try fm.createDirectory(at: interrotta, withIntermediateDirectories: true)
        try Data("copia a metà".utf8).write(to: interrotta.appendingPathComponent("indice.json"))
        _ = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard !fm.fileExists(atPath: interrotta.path) else { return "copia d'avvio interrotta: resta dopo l'avvio" }
        // Nel backup no (anche se arriva dopo l'avvio)
        try fm.createDirectory(at: interrotta, withIntermediateDirectories: true)
        try Data("copia a metà".utf8).write(to: interrotta.appendingPathComponent("indice.json"))
        let zip = try GestoreBackup.crea(sorgente: cartella, destinazione: base.appendingPathComponent("Backup", isDirectory: true))
        let nomi = try LettoreZip.nomi(zip)
        guard !nomi.contains(where: { $0.contains(Archivio.nomeCopiaAvvio) }) else {
            return "copia d'avvio interrotta: è finita nel backup"
        }
        // Il segnaposto: una versione di prima lo legge come un archivio di una versione più recente
        guard let segnaposto = try LettoreZip.dati(zip, voce: "Prisma/" + Archivio.nomeFileVecchio),
              let comeVecchia = try? Archivio.decodifica(segnaposto), Archivio.diVersionePiuRecente(comeVecchia),
              comeVecchia.clienti.isEmpty, nomi.contains("Prisma/Archivio/Clienti/") || nomi.contains(where: { $0.hasPrefix("Prisma/Archivio/Clienti/") }) else {
            return "segnaposto: il backup a pezzi non ha un archivio.json che le versioni di prima leggono come «versione più recente»"
        }
        // Questa versione lo ignora e non lo porta nella cartella dell'archivio
        let estratto = try GestoreBackup.estrai(zip)
        guard estratto.dati == d, !fm.fileExists(atPath: estratto.cartella.appendingPathComponent(Archivio.nomeFileVecchio).path) else {
            GestoreBackup.pulisciEstrazione(estratto.cartella)
            return "segnaposto: il backup a pezzi non torna identico o il segnaposto resta nella cartella estratta"
        }
        let ripristino = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristino, con: estratto.cartella)
        let riaperto = Archivio.carica(in: ripristino)
        Archivio.coda.sync {}
        guard riaperto.dati == d, riaperto.avviso == nil, !fm.fileExists(atPath: ripristino.appendingPathComponent(Archivio.nomeFileVecchio).path) else {
            return "segnaposto: dopo il ripristino l'archivio non è identico o c'è archivio.json"
        }
        // Un backup con il solo segnaposto (la cartella a pezzi persa) non è un backup di Prisma
        let solo = base.appendingPathComponent("SoloSegnaposto/Prisma", isDirectory: true)
        try fm.createDirectory(at: solo, withIntermediateDirectories: true)
        try Archivio.datiSegnaposto().write(to: solo.appendingPathComponent(Archivio.nomeFileVecchio))
        do {
            _ = try Archivio.leggiPerRipristino(solo)
            return "segnaposto: il solo segnaposto è stato letto come un archivio"
        } catch ErroreBackup.archivioMancante {}
        return nil
    }

    /// Il backup protetto della cartella a pezzi: cifrato (nemmeno i nomi dei file in chiaro) e identico al ripristino.
    private static func provaProtettoAPezzi(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(ClientiFittizi.completi())
        _ = try archivioPulito(cartella, d)
        let indice = try ArchivioPezzi.leggiIndice(ArchivioPezzi.cartellaPezzi(in: cartella))
        guard let voce = indice.clienti.first else { return "backup protetto a pezzi: nessun cliente" }
        let password = "prova-pezzi-àè"
        let cifrato = try GestoreBackup.crea(sorgente: cartella, destinazione: base.appendingPathComponent("Backup", isDirectory: true),
                                             password: password, iterazioni: 1_000)
        let byte = try Data(contentsOf: cifrato)
        guard CifraturaBackup.cifrato(cifrato), byte.range(of: Data("indice.json".utf8)) == nil, byte.range(of: Data(voce.file.utf8)) == nil,
              byte.range(of: Data(voce.nome.utf8)) == nil else {
            return "backup protetto a pezzi: nel file si leggono nomi di file o di clienti"
        }
        let aperto = try GestoreBackup.estrai(cifrato, password: password)
        defer { GestoreBackup.pulisciEstrazione(aperto.cartella) }
        guard aperto.dati == d, fm.fileExists(atPath: ArchivioPezzi.cartellaPezzi(in: aperto.cartella).appendingPathComponent("Clienti/" + voce.file).path) else {
            return "backup protetto a pezzi: non torna identico (o mancano i file dei clienti)"
        }
        return nil
    }

    /// La cartella a pezzi sparita del tutto: si riprende la copia dell'ultimo avvio, con l'avviso.
    private static func provaCopiaAvvio(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(ClientiFittizi.completi())
        _ = try archivioPulito(cartella, d)
        guard fm.fileExists(atPath: cartella.appendingPathComponent(Archivio.nomeCopiaAvvio + "/" + ArchivioPezzi.nomeIndice).path) else {
            return "copia d'avvio: non c'è"
        }
        try fm.removeItem(at: ArchivioPezzi.cartellaPezzi(in: cartella))
        let e = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard e.dati == d, e.avviso?.contains("L'archivio mancava") == true, !e.solaLettura, ArchivioPezzi.presente(in: cartella) else {
            return "copia d'avvio: con la cartella a pezzi sparita non si riprende la copia dell'ultimo avvio (\(e.avviso ?? "nessun avviso"))"
        }
        return nil
    }

    /// Una transazione confermata e rimasta sul disco nella stessa sessione (una rinomina non riuscita), poi un giro che
    /// cambia un file solo: il giro dopo non la scavalca, e all'avvio l'archivio è quello dell'ultimo giro (mai la
    /// transazione di prima rimessa sopra).
    private static func provaTransazioneRimasta(_ base: URL) throws -> String? {
        let fm = FileManager.default
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        let d = try passatoDalDisco(DatiPrisma.demo())
        guard let sulDisco = try archivioPulito(cartella, d).sulDisco else { return "transazione rimasta: l'archivio non si riapre pulito" }
        guard let primo = d.clienti.first, let i = d.note.firstIndex(where: { $0.clienteId == primo.id }) else {
            return "transazione rimasta: nessuna nota di un cliente"
        }
        // Giro 1 (più file): confermato e fermo prima di ogni spostamento, come se la prima rinomina non riuscisse
        var b = d
        b.note[i].testo += " (giro 1)"
        var nuovo = Cliente.nuovo(tinta: .blu)
        nuovo.nome = "Cliente Della Transazione Rimasta"
        b.clienti.append(nuovo)
        b = try passatoDalDisco(b)
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-transazione-rimasta", qos: .utility))
        s.prepara(sulDisco)
        s.sullaCoda { $0.interrompi = .dopoLaConferma(spostati: 0) }
        s.accoda(b, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        let transazione = ArchivioPezzi.cartellaPezzi(in: cartella).appendingPathComponent(ArchivioPezzi.nomeTransazione)
        guard fm.fileExists(atPath: transazione.path) else { return "transazione rimasta: la transazione confermata non è sul disco" }
        // Giro 2 nella stessa sessione: rispetto a ciò che lo scrittore crede sul disco cambia un file solo
        var c = d
        c.note[i].testo += " (giro 2)"
        c = try passatoDalDisco(c)
        s.accoda(c, generazione: 2) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        guard !fm.fileExists(atPath: transazione.path) else { return "transazione rimasta: il giro dopo l'ha lasciata sul disco" }
        let riaperto = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        guard riaperto.dati == c, riaperto.avviso == nil else {
            return "transazione rimasta: all'avvio l'archivio non è quello dell'ultimo giro (clienti \(riaperto.dati.clienti.count) di \(c.clienti.count))"
        }
        return nil
    }

    /// Due ricostruzioni di fila senza un avvio pulito in mezzo: i clienti aggiunti dopo la prima (scritti con una
    /// generazione più alta di quella della copia d'avvio) si riprendono, non si scambiano per clienti tolti.
    private static func provaDueRicostruzioni(_ base: URL) throws -> String? {
        let cartella = base.appendingPathComponent("Prisma", isDirectory: true)
        var d = try passatoDalDisco(ClientiFittizi.completi())
        guard var sulDisco = try archivioPulito(cartella, d).sulDisco else { return "due ricostruzioni: l'archivio non si riapre pulito" }
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        // Qualche giro, così la generazione della copia d'avvio è più alta di 1
        for n in 0..<3 {
            let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-ricostruzioni-\(n)", qos: .utility))
            s.prepara(sulDisco)
            d.impostazioni.nomeUtente = "Giro \(n)"
            d = try passatoDalDisco(d)
            s.accoda(d, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
            s.attendi()
            sulDisco = try ArchivioPezzi.leggi(pezzi).lettura
        }
        _ = Archivio.carica(in: cartella)
        Archivio.coda.sync {}
        let copia = cartella.appendingPathComponent(Archivio.nomeCopiaAvvio, isDirectory: true)
        let generazioneCopia = try ArchivioPezzi.leggiIndice(copia).generazione
        guard generazioneCopia > 1 else { return "due ricostruzioni: la copia d'avvio non ha una generazione alta" }
        // Prima ricostruzione
        try Data("indice rovinato".utf8).write(to: ArchivioPezzi.indice(in: cartella))
        _ = caricaEConverti(cartella)
        guard try ArchivioPezzi.leggiIndice(pezzi).generazione > generazioneCopia else {
            return "due ricostruzioni: dopo la prima l'archivio è scritto con una generazione sotto la copia d'avvio"
        }
        // Un cliente nuovo, poi l'indice di nuovo rovinato prima di un avvio pulito
        let s = SalvataggioArchivio(cartella: cartella, coda: DispatchQueue(label: "prisma.prova-ricostruzioni-nuovo", qos: .utility))
        s.prepara(try ArchivioPezzi.leggi(pezzi).lettura)
        var nuovo = Cliente.nuovo(tinta: .blu)
        nuovo.nome = "Cliente Dopo La Ricostruzione"
        d = try ArchivioPezzi.leggi(pezzi).lettura.dati
        d.clienti.append(nuovo)
        d = try passatoDalDisco(d)
        s.accoda(d, generazione: 1) { errore in print("ERRORE: \(errore.localizedDescription)") }
        s.attendi()
        try Data("indice rovinato".utf8).write(to: ArchivioPezzi.indice(in: cartella))
        let e = caricaEConverti(cartella)
        guard e.dati.clienti.contains(where: { $0.id == nuovo.id }) else {
            return "due ricostruzioni: il cliente aggiunto dopo la prima ricostruzione non si è ripreso"
        }
        return nil
    }
}
