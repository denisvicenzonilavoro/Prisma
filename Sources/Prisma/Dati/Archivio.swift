import Foundation

/// Archivio locale in ~/Library/Application Support/Prisma.
///
/// Contenuto della cartella:
/// - Archivio/: clienti, agenda, posizioni, impostazioni, a pezzi (un indice, un file per cliente, le sezioni comuni:
///   ArchivioPezzi.swift). Fino al giro 0 di «Prisma istantaneo» era un file unico, archivio.json: si legge ancora
///   (anche dai backup di prima) e si converte da solo, tenendo archivio.json.vecchio fino alla riapertura verificata
/// - Documenti/: documenti dei clienti
/// - Vera/: impostazioni e memoria di Vera (fino al cambio di nome «Eve/»: si sposta da sola, `spostaCartellaVecchia`)
enum Archivio {
    static var supportoApplicazioni: URL {
        cartellaDiProva ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    /// Solo per la prova della fluidità (`--prova-fluidita`, lanciata anche da Impostazioni › Strumenti › «Misura la
    /// velocità su questo Mac»): una cartella vuota al posto di Application Support, così la prova non può toccare
    /// l'archivio dell'utente nemmeno per sbaglio, e alla fine controlla che sia rimasta vuota. nil nell'app vera.
    static var cartellaDiProva: URL?

    static var cartella: URL { supportoApplicazioni.appendingPathComponent("Prisma", isDirectory: true) }
    /// Il file unico dell'archivio di prima (archivio.json): si legge ancora e si converte da solo.
    static var file: URL { cartella.appendingPathComponent(nomeFileVecchio) }
    /// La cartella a pezzi dell'archivio (dal giro 0, tappa 3).
    static var cartellaPezzi: URL { ArchivioPezzi.cartellaPezzi(in: cartella) }
    static var cartellaDocumenti: URL { cartella.appendingPathComponent("Documenti", isDirectory: true) }
    static var cartellaVera: URL { cartella.appendingPathComponent("Vera", isDirectory: true) }
    /// Compatibilità: il nome della cartella di Vera negli archivi e nei backup di prima del primo cambio di nome.
    static let nomeCartellaVecchia = "Eve"
    /// Tutti i nomi di prima della cartella di Vera: «Ruby» (fino al 7 novembre 2026) ed «Eve» (fino al 5 novembre).
    static let nomiCartelleVecchie = ["Ruby", nomeCartellaVecchia]

    /// Sposta le cartelle di Vera con i nomi di prima («Ruby/», «Eve/») in «Vera/» dentro `base` (la cartella
    /// dell'archivio o quella estratta da un backup). Se ci sono già tutte e due, i file della vecchia che mancano nella
    /// nuova si spostano e la vecchia si toglie solo se resta vuota: nessun file si perde né si sovrascrive.
    static func spostaCartellaVecchia(in base: URL) {
        for nome in nomiCartelleVecchie { spostaCartella(nome, in: base) }
    }

    private static func spostaCartella(_ nomeVecchio: String, in base: URL) {
        let fm = FileManager.default
        let vecchia = base.appendingPathComponent(nomeVecchio, isDirectory: true)
        let nuova = base.appendingPathComponent("Vera", isDirectory: true)
        var cartella: ObjCBool = false
        guard fm.fileExists(atPath: vecchia.path, isDirectory: &cartella), cartella.boolValue else { return }
        guard fm.fileExists(atPath: nuova.path) else {
            try? fm.moveItem(at: vecchia, to: nuova)
            return
        }
        for voce in (try? fm.contentsOfDirectory(at: vecchia, includingPropertiesForKeys: nil)) ?? [] {
            let destinazione = nuova.appendingPathComponent(voce.lastPathComponent)
            if !fm.fileExists(atPath: destinazione.path) { try? fm.moveItem(at: voce, to: destinazione) }
        }
        if ((try? fm.contentsOfDirectory(atPath: vecchia.path)) ?? ["?"]).isEmpty { try? fm.removeItem(at: vecchia) }
    }

    /// Cartella dei backup finché l'utente non ne sceglie una (stesso Mac: va cambiata).
    static var cartellaBackupPredefinita: URL {
        supportoApplicazioni.appendingPathComponent("Prisma Backup", isDirectory: true)
    }

    static func preparaCartelle(in cartella: URL = Archivio.cartella) throws {
        let fm = FileManager.default
        spostaCartellaVecchia(in: cartella)
        for c in [cartella, cartella.appendingPathComponent("Documenti", isDirectory: true), cartella.appendingPathComponent("Vera", isDirectory: true)] {
            try fm.createDirectory(at: c, withIntermediateDirectories: true)
        }
        #if os(macOS)
        // Sul Mac nulla da aggiungere: l'archivio resta in ~/Library/Application Support/Prisma
        #elseif os(iOS)
        // Su iPhone e iPad: fuori dal backup iCloud del dispositivo (niente cloud) e illeggibile a dispositivo
        // bloccato. Dopo un ripristino la cartella è nuova: si riapplica a ogni salvataggio (costa poco).
        escludiDalBackup(cartella)
        try? fm.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: cartella.path)
        #endif
    }

    /// Opzioni di scrittura dell'archivio: sul Mac solo `.atomic` (come sempre); su iPhone e iPad anche la
    /// protezione completa dei file (dati illeggibili con il dispositivo bloccato).
    static var opzioniScrittura: Data.WritingOptions {
        #if os(macOS)
        return [.atomic]
        #elseif os(iOS)
        return [.atomic, .completeFileProtection]
        #endif
    }

    #if os(macOS)
    // Sul Mac l'archivio segue le regole del sistema (Time Machine compreso): nessuna esclusione
    #elseif os(iOS)
    /// Esclude una cartella dal backup iCloud/computer del dispositivo: i dati dei clienti non vanno nel cloud.
    static func escludiDalBackup(_ cartella: URL) {
        var url = cartella
        var valori = URLResourceValues()
        valori.isExcludedFromBackup = true
        try? url.setResourceValues(valori)
    }
    #endif

    static let codificatore = nuovoCodificatore()

    /// Un codificatore dell'archivio tutto suo (il salvataggio in background ne usa uno solo per sé).
    static func nuovoCodificatore() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        // Un numero non finito (NaN, infinito) non deve bloccare ogni salvataggio
        e.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return e
    }

    /// Coda seriale delle scritture dell'archivio (salvataggi e copia d'avvio): mai sul thread principale.
    /// Chi deve vedere l'archivio aggiornato sul disco (backup, ripristino) aspetta che si svuoti.
    static let coda = DispatchQueue(label: "prisma.archivio", qos: .utility)

    static let decodificatore: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        return d
    }()

    static func decodifica(_ data: Data) throws -> DatiPrisma {
        try decodificatore.decode(DatiPrisma.self, from: data)
    }

    /// Il file unico di prima (fino al giro 0, tappa 3): si legge ancora e si converte da solo.
    static let nomeFileVecchio = "archivio.json"
    /// La copia di archivio.json tenuta dopo la conversione, fino al primo avvio che riapre bene la cartella a pezzi.
    static let nomeFileConvertito = "archivio.json.vecchio"
    /// La copia della cartella a pezzi fatta a ogni avvio (un clone su APFS: non occupa spazio finché non cambia).
    static let nomeCopiaAvvio = "Archivio-all-avvio"

    /// Copia dell'archivio di prima fatta a ogni avvio (formato a file unico).
    static var copiaAvvio: URL { cartella.appendingPathComponent("archivio-all-avvio.json") }
    static let prefissoNonLeggibile = "archivio-non-leggibile"

    /// Solo il numero di versione: si legge anche quando il resto dell'archivio non si legge.
    private struct SoloVersione: Decodable { var versione: Int? }

    static let avvisoPiuRecente = "Questo archivio è stato salvato da una versione più recente di Prisma: lo apro in sola lettura e non salvo nulla, per non perdere dati. Apri l'ultima versione di Prisma."

    /// Copie di archivi (o di pezzi dell'archivio) non leggibili non ancora gestite: finché ci sono, i backup
    /// automatici si fermano (non devono sostituire, con la rotazione, i backup buoni con dati incompleti).
    static var copieNonLeggibili: [URL] {
        ((try? FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.lastPathComponent.hasPrefix(prefissoNonLeggibile) && !$0.lastPathComponent.contains("(gestito)") }
    }

    /// Segna come gestite le copie non leggibili (dopo un ripristino o per scelta del consulente).
    static func segnaCopieGestite() {
        for u in copieNonLeggibili {
            let nuovo = u.deletingPathExtension().lastPathComponent + " (gestito).json"
            try? FileManager.default.moveItem(at: u, to: u.deletingLastPathComponent().appendingPathComponent(nuovo))
        }
    }

    /// true se in `cartella` c'è un archivio di Prisma (a pezzi o nel file unico di prima).
    static func presente(in cartella: URL) -> Bool {
        ArchivioPezzi.presente(in: cartella) || FileManager.default.fileExists(atPath: cartella.appendingPathComponent(nomeFileVecchio).path)
    }

    /// Com'è andata la lettura dell'archivio all'avvio.
    struct EsitoCarica {
        var dati: DatiPrisma
        var avviso: String?
        var solaLettura = false
        var bloccaRipristino = false
        /// La cartella a pezzi letta senza problemi: base dei salvataggi per parti. nil = il primo salvataggio
        /// riscrive tutto.
        var sulDisco: LetturaArchivio?
        /// Da riscrivere subito tutta nel formato a pezzi: conversione di archivio.json, pezzi mancanti o rovinati
        /// (messi da parte), indice ricostruito.
        var daRiscrivere = false
    }

    /// Carica l'archivio. Al primo avvio crea l'archivio con i dati di prova.
    /// - Ripristino interrotto: rimette a posto la cartella di prima.
    /// - Cartella a pezzi: prima l'indice (`indiceLetto` riceve lo scheletro: impostazioni, nessun dato), poi i file in
    ///   parallelo. Un file di un cliente (o una sezione) mancante o rovinato non ferma gli altri: si mette da parte,
    ///   l'utente viene avvisato e i backup automatici si fermano. Un indice rovinato si ricostruisce dai file.
    /// - archivio.json (formato di prima): si legge come sempre e si converte subito (`daRiscrivere`), tenendone la copia.
    /// - Archivio mancante ma cartella già usata: riprende la copia dell'ultimo avvio, mai i dati di prova in silenzio.
    /// - Versione più recente: sola lettura, i file non si toccano (salvarli perderebbe i dati che questa non conosce).
    /// - File unico non leggibile: ne conserva una copia e riparte dai dati di prova, con l'avviso.
    static func carica(in cartella: URL = Archivio.cartella, indiceLetto: ((DatiPrisma) -> Void)? = nil) -> EsitoCarica {
        let recuperato = GestoreBackup.recuperaRipristino(cartella)
        try? preparaCartelle(in: cartella)
        let fm = FileManager.default
        let avvisoRecupero = recuperato ? "Un ripristino era stato interrotto: ho rimesso l'archivio com'era prima." : nil
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let vecchio = cartella.appendingPathComponent(nomeFileVecchio)
        let clientiSciolti = !((try? fm.contentsOfDirectory(atPath: pezzi.appendingPathComponent(ArchivioPezzi.nomeClienti).path)) ?? [])
            .filter { $0.hasSuffix(".json") }.isEmpty

        // 1. La cartella a pezzi (anche senza indice, se ci sono i file dei clienti: si ricostruisce)
        if ArchivioPezzi.presente(in: cartella) || (clientiSciolti && !fm.fileExists(atPath: vecchio.path)) {
            if var e = caricaPezzi(cartella, indiceLetto: indiceLetto) {
                if e.avviso == nil { e.avviso = avvisoRecupero }
                return e
            }
            // nil: la cartella non è completa ma c'è ancora archivio.json (conversione non finita): vale lui
        }
        // 2. Il file unico di prima
        if fm.fileExists(atPath: vecchio.path) {
            var e = caricaVecchio(cartella)
            if e.avviso == nil { e.avviso = avvisoRecupero }
            return e
        }
        // 3. Niente archivio: la copia dell'ultimo avvio (a pezzi, poi quella di prima)
        let copiaPezzi = cartella.appendingPathComponent(nomeCopiaAvvio, isDirectory: true)
        if fm.fileExists(atPath: copiaPezzi.appendingPathComponent(ArchivioPezzi.nomeIndice).path) {
            try? fm.removeItem(at: pezzi)
            if (try? fm.copyItem(at: copiaPezzi, to: pezzi)) != nil, var e = caricaPezzi(cartella, indiceLetto: nil), !e.solaLettura {
                let mancava = "L'archivio mancava: ho ripreso la copia fatta all'ultimo avvio di Prisma. Controlla gli ultimi inserimenti."
                e.avviso = e.avviso.map { mancava + " " + $0 } ?? mancava
                return e
            }
        }
        let copiaVecchia = cartella.appendingPathComponent("archivio-all-avvio.json")
        if let grezzo = try? Data(contentsOf: copiaVecchia), let d = try? decodifica(grezzo), !diVersionePiuRecente(d) {
            try? salva(d, in: cartella)
            return EsitoCarica(dati: d, avviso: "L'archivio mancava: ho ripreso la copia fatta all'ultimo avvio di Prisma. Controlla gli ultimi inserimenti.")
        }
        let documenti = (try? fm.contentsOfDirectory(atPath: cartella.appendingPathComponent("Documenti").path)) ?? []
        if !documenti.isEmpty || !copieNonLeggibili(in: cartella).isEmpty {
            // La cartella è già stata usata: niente dati di prova scritti sopra
            return EsitoCarica(dati: DatiPrisma.demo(), avviso: "L'archivio di Prisma manca ma la cartella contiene documenti: non salvo nulla. Ripristina un backup da Impostazioni (o chiedi aiuto prima di continuare).", solaLettura: true)
        }
        let d = DatiPrisma.demo()
        try? salva(d, in: cartella)
        return EsitoCarica(dati: d)
    }

    static func copieNonLeggibili(in cartella: URL) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.lastPathComponent.hasPrefix(prefissoNonLeggibile) && !$0.lastPathComponent.contains("(gestito)") }
    }

    /// La cartella a pezzi. nil se non è completa e c'è ancora archivio.json, che allora vale di più.
    private static func caricaPezzi(_ cartella: URL, indiceLetto: ((DatiPrisma) -> Void)?) -> EsitoCarica? {
        let fm = FileManager.default
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let vecchio = cartella.appendingPathComponent(nomeFileVecchio)
        let vecchioPresente = fm.fileExists(atPath: vecchio.path)
        let indiceBuono = (try? ArchivioPezzi.leggiIndice(pezzi)) != nil
        if !indiceBuono, vecchioPresente { return nil }
        // Senza indice: le impostazioni della copia d'avvio, se c'è, o quelle di base
        let copia = cartella.appendingPathComponent(nomeCopiaAvvio, isDirectory: true)
        let riserva = (try? ArchivioPezzi.leggiIndice(copia)) ?? IndiceArchivio()
        let r: (lettura: LetturaArchivio, problemi: [ProblemaPezzo], scartati: [URL])
        do {
            r = try ArchivioPezzi.leggi(pezzi, indiceLetto: indiceLetto.map { f in { f(ArchivioPezzi.scheletro($0)) } },
                                        indiceDiRiserva: riserva)
        } catch {
            // Un formato su disco più recente: sola lettura, nulla si tocca
            return EsitoCarica(dati: ArchivioPezzi.vuoto, avviso: avvisoPiuRecente, solaLettura: true, bloccaRipristino: true)
        }
        let d = r.lettura.dati
        if diVersionePiuRecente(d) { return EsitoCarica(dati: d, avviso: avvisoPiuRecente, solaLettura: true, bloccaRipristino: true) }
        if !r.problemi.isEmpty, vecchioPresente { return nil }
        // I file non citati e più vecchi dell'indice (clienti tolti) e i temporanei di un salvataggio interrotto
        for u in r.scartati { try? fm.removeItem(at: u) }
        pulisciTemporanei(in: pezzi)
        if r.problemi.isEmpty && indiceBuono {
            if vecchioPresente {
                // La conversione era finita ma non la rinomina: la cartella si è appena riaperta bene
                let convertito = cartella.appendingPathComponent(nomeFileConvertito)
                try? fm.removeItem(at: convertito)
                try? fm.moveItem(at: vecchio, to: convertito)
            } else {
                // Riaperta bene dopo la conversione: la copia di archivio.json non serve più (verificata due volte)
                try? fm.removeItem(at: cartella.appendingPathComponent(nomeFileConvertito))
            }
            try? fm.removeItem(at: cartella.appendingPathComponent("archivio-all-avvio.json"))
            // La copia d'avvio in background: l'avvio non la aspetta (prima dei salvataggi, che passano dalla stessa coda)
            coda.async { copiaCartella(pezzi, in: copia) }
            return EsitoCarica(dati: d, sulDisco: r.lettura)
        }
        // Qualcosa non si è letto: si mette da parte (mai cancellato), il resto si apre e si riscrive tutto
        let quando = Formati.nomeFile.string(from: Date())
        var voci: [String] = []
        for p in r.problemi {
            let nome = p.descrizione.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: "«", with: "").replacingOccurrences(of: "»", with: "")
            let destinazione = cartella.appendingPathComponent("\(prefissoNonLeggibile) \(nome)\(p.mancante ? " (mancante)" : "") \(quando).json")
            if p.mancante {
                // Il segno che manca (ferma i backup automatici: con la rotazione sostituirebbero quelli che lo hanno)
                let segno = ["mancava": p.file.lastPathComponent, "che cosa": p.descrizione]
                try? JSONSerialization.data(withJSONObject: segno, options: [.prettyPrinted]).write(to: destinazione)
            } else {
                try? fm.moveItem(at: p.file, to: destinazione)
            }
            voci.append("\(p.descrizione) (\(p.mancante ? "manca" : "non si legge"))")
        }
        if !indiceBuono {
            let indice = pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice)
            let destinazione = cartella.appendingPathComponent("\(prefissoNonLeggibile) indice \(quando).json")
            if fm.fileExists(atPath: indice.path) {
                try? fm.moveItem(at: indice, to: destinazione)
            } else {
                try? Data(#"{"mancava": "indice.json"}"#.utf8).write(to: destinazione)
            }
            voci.insert("l'indice dell'archivio (ricostruito dai file dei clienti: controlla impostazioni e ordine)", at: 0)
        }
        let avviso = "Alcune parti dell'archivio non si sono aperte: " + voci.joined(separator: "; ")
            + ". Tutto il resto è aperto. Ne ho messo da parte una copia nella cartella di Prisma; i backup automatici sono fermi finché non ripristini un backup da Impostazioni o confermi che i dati vanno bene."
        return EsitoCarica(dati: d, avviso: avviso, daRiscrivere: true)
    }

    /// Il file unico di prima (archivio.json): si legge come sempre; poi si converte (`daRiscrivere`).
    private static func caricaVecchio(_ cartella: URL) -> EsitoCarica {
        let fm = FileManager.default
        let file = cartella.appendingPathComponent(nomeFileVecchio)
        guard let grezzo = try? Data(contentsOf: file) else {
            return EsitoCarica(dati: DatiPrisma.demo(), avviso: "Non riesco ad aprire l'archivio di Prisma: non salvo nulla. Riavvia il Mac e riprova.", solaLettura: true)
        }
        // Una lettura sola: la versione la legge già la decodifica completa
        do {
            var dati = try decodifica(grezzo)
            // Un archivio più recente si apre in sola lettura e non si copia
            if diVersionePiuRecente(dati) { return EsitoCarica(dati: dati, avviso: avvisoPiuRecente, solaLettura: true, bloccaRipristino: true) }
            // La copia d'avvio si scrive in background: l'avvio non la aspetta
            let copia = cartella.appendingPathComponent("archivio-all-avvio.json")
            let opzioni = opzioniScrittura
            coda.async { try? grezzo.write(to: copia, options: opzioni) }
            dati.versione = DatiPrisma.versioneAttuale
            return EsitoCarica(dati: dati, daRiscrivere: true)
        } catch {
            // Non leggibile: prima di tutto la versione, perché un archivio più recente può non essere leggibile da questa
            if let v = try? decodificatore.decode(SoloVersione.self, from: grezzo).versione, v > DatiPrisma.versioneAttuale {
                return EsitoCarica(dati: ArchivioPezzi.vuoto, avviso: avvisoPiuRecente, solaLettura: true, bloccaRipristino: true)
            }
            let copia = cartella.appendingPathComponent("\(prefissoNonLeggibile) \(Formati.nomeFile.string(from: Date())).json")
            try? fm.moveItem(at: file, to: copia)
            let d = DatiPrisma.demo()
            try? salva(d, in: cartella)
            return EsitoCarica(dati: d, avviso: "L'archivio non era leggibile: ne ho conservato una copia nella cartella di Prisma e caricato i dati di prova. I backup automatici sono fermi finché non ripristini un backup da Impostazioni.")
        }
    }

    /// I dati dell'archivio in una cartella estratta da un backup (a pezzi o nel file unico di prima). Severa: un pezzo
    /// mancante o rovinato rende il backup non valido (meglio sceglierne un altro che ripristinarne uno a metà).
    static func leggiPerRipristino(_ radice: URL) throws -> DatiPrisma {
        let vecchio = radice.appendingPathComponent(nomeFileVecchio)
        let vecchioPresente = FileManager.default.fileExists(atPath: vecchio.path)
        if ArchivioPezzi.presente(in: radice) {
            do {
                let r = try ArchivioPezzi.leggi(ArchivioPezzi.cartellaPezzi(in: radice))
                if r.problemi.isEmpty { return r.lettura.dati }
                if !vecchioPresente {
                    throw ErroreBackup.archivioNonValido("mancano o non si leggono " + r.problemi.map(\.descrizione).joined(separator: ", "))
                }
            } catch ErroreArchivioPezzi.formatoPiuRecente {
                throw ErroreBackup.versionePiuRecente
            } catch let e as ErroreBackup {
                throw e
            } catch {
                if !vecchioPresente { throw ErroreBackup.archivioNonValido(error.localizedDescription) }
            }
        }
        do {
            return try decodifica(Data(contentsOf: vecchio))
        } catch {
            throw ErroreBackup.archivioNonValido(error.localizedDescription)
        }
    }

    /// true se l'archivio l'ha scritto una versione di Prisma più recente di questa.
    static func diVersionePiuRecente(_ dati: DatiPrisma) -> Bool {
        dati.versione > DatiPrisma.versioneAttuale
    }

    /// Scrive tutto l'archivio nel formato a pezzi in `cartella` (dati di prova del primo avvio, prove). Con un
    /// archivio.json nella cartella è la conversione (verificata, archivio.json → archivio.json.vecchio).
    static func salva(_ dati: DatiPrisma, in cartella: URL = Archivio.cartella) throws {
        try preparaCartelle(in: cartella)
        try ScrittorePezzi(cartella: cartella).scrivi(dati)
    }

    /// Il file unico di prima, intero (solo se la conversione non si è potuta verificare).
    static func scriviVecchio(_ dati: DatiPrisma, in cartella: URL) throws {
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        try scriviAtomico(nuovoCodificatore().encode(dati), in: cartella.appendingPathComponent(nomeFileVecchio))
    }

    /// Scrittura atomica: un file temporaneo accanto («nome.tmp-xxxxxxxx») e poi la rinomina, che sostituisce il file in
    /// un colpo solo. Un'interruzione lascia al più il temporaneo (che la lettura ignora e toglie), mai un file a metà.
    static func scriviAtomico(_ data: Data, in url: URL) throws {
        let temporaneo = url.deletingLastPathComponent()
            .appendingPathComponent(url.lastPathComponent + ".tmp-" + UUID().uuidString.prefix(8).lowercased())
        #if os(macOS)
        try data.write(to: temporaneo)
        #elseif os(iOS)
        try data.write(to: temporaneo, options: [.completeFileProtection])
        #endif
        guard rename(temporaneo.path, url.path) == 0 else {
            let codice = errno
            try? FileManager.default.removeItem(at: temporaneo)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(codice))
        }
    }

    /// Toglie i temporanei lasciati da un salvataggio interrotto (nella cartella a pezzi e in quella dei clienti).
    static func pulisciTemporanei(in cartellaPezzi: URL) {
        let fm = FileManager.default
        for c in [cartellaPezzi, cartellaPezzi.appendingPathComponent(ArchivioPezzi.nomeClienti, isDirectory: true)] {
            for nome in (try? fm.contentsOfDirectory(atPath: c.path)) ?? [] where nome.contains(".tmp-") {
                try? fm.removeItem(at: c.appendingPathComponent(nome))
            }
        }
    }

    /// Copia (un clone su APFS) la cartella a pezzi in `destinazione`, sostituendo quella di prima solo a copia finita.
    static func copiaCartella(_ sorgente: URL, in destinazione: URL) {
        let fm = FileManager.default
        let temporanea = destinazione.deletingLastPathComponent()
            .appendingPathComponent(destinazione.lastPathComponent + ".tmp-" + UUID().uuidString.prefix(8).lowercased(), isDirectory: true)
        do {
            try fm.copyItem(at: sorgente, to: temporanea)
            try? fm.removeItem(at: destinazione)
            try fm.moveItem(at: temporanea, to: destinazione)
        } catch {
            try? fm.removeItem(at: temporanea)
        }
    }

    /// Percorso leggibile, con ~ al posto della cartella Inizio (su iPhone e iPad: il contenitore dell'app).
    static func percorsoBreve(_ url: URL) -> String {
        #if os(macOS)
        let casa = FileManager.default.homeDirectoryForCurrentUser.path
        #elseif os(iOS)
        let casa = NSHomeDirectory()
        #endif
        let p = url.path
        return p.hasPrefix(casa) ? "~" + p.dropFirst(casa.count) : p
    }
}

/// Il salvataggio dell'archivio in background: confronto, codifica e scrittura sulla coda `Archivio.coda`, così il
/// thread principale (e le animazioni) non le aspettano. Scrive solo i file cambiati della cartella a pezzi
/// (`ScrittorePezzi`, che vive solo sulla coda). Ogni modifica dei dati è una generazione nuova: una generazione già
/// accodata non si scrive due volte. Da usare dal thread principale.
final class SalvataggioArchivio {
    /// La cartella dell'archivio («Prisma»).
    let cartella: URL
    private let coda: DispatchQueue
    /// Solo sulla coda.
    private let scrittore: ScrittorePezzi
    /// L'ultima generazione accodata (quella dei dati sul disco, a coda vuota).
    private(set) var accodata: Int

    /// `generazione`: quella dei dati già sul disco (all'avvio, quelli appena letti).
    init(cartella: URL = Archivio.cartella, coda: DispatchQueue = Archivio.coda, generazione: Int = 0) {
        self.cartella = cartella
        self.coda = coda
        scrittore = ScrittorePezzi(cartella: cartella)
        accodata = generazione
    }

    /// Ciò che c'è sul disco, appena letto senza problemi: i salvataggi scrivono solo le differenze. nil = il prossimo
    /// salvataggio riscrive tutto.
    func prepara(_ sulDisco: LetturaArchivio?) {
        let s = scrittore
        coda.async { s.riparti(da: sulDisco) }
    }

    /// Dopo un ripristino (la cartella è quella del backup, magari nel formato di prima): il prossimo salvataggio
    /// riscrive tutto (e converte un archivio.json ripristinato).
    func ricomincia() {
        prepara(nil)
    }

    /// Riscrive subito tutto (conversione di archivio.json, archivio aperto con pezzi messi da parte).
    func riscriviTutto(_ dati: DatiPrisma, fallito: @escaping (Error) -> Void) {
        let s = scrittore
        coda.async {
            s.riparti(da: nil)
            do {
                try s.scrivi(dati)
            } catch {
                DispatchQueue.main.async { fallito(error) }
            }
        }
    }

    /// Accoda la scrittura di `dati` (generazione `generazione`). false se quella generazione era già accodata:
    /// niente da scrivere. Se la scrittura non riesce, `fallito` arriva sul thread principale e la stessa
    /// generazione si potrà riscrivere.
    @discardableResult
    func accoda(_ dati: DatiPrisma, generazione: Int, fallito: @escaping (Error) -> Void) -> Bool {
        guard generazione != accodata else { return false }
        accodata = generazione
        let s = scrittore
        coda.async { [weak self] in
            do {
                try s.scrivi(dati)
            } catch {
                // Il prossimo giro riscrive tutto: niente confronti con uno stato del disco che non è certo
                s.riparti(da: nil)
                DispatchQueue.main.async {
                    if self?.accodata == generazione { self?.accodata = Int.min }
                    fallito(error)
                }
            }
        }
        return true
    }

    /// Torna quando le scritture accodate sono sul disco.
    func attendi() {
        coda.sync {}
    }

    /// Solo per le prove: lo scrittore, sulla sua coda.
    func sullaCoda<T>(_ lavoro: (ScrittorePezzi) -> T) -> T {
        coda.sync { lavoro(scrittore) }
    }
}
