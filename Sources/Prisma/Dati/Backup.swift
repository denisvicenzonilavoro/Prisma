import Foundation

/// Un backup presente nella cartella dei backup.
struct VoceBackup: Identifiable, Equatable {
    let url: URL
    let data: Date
    let dimensione: Int64
    var id: URL { url }
    /// Il nome senza estensioni: senza «.zip» e, per i protetti, anche senza «.cifrato»
    /// (la rotazione riconosce i backup automatici dalla fine del nome).
    var nome: String {
        let senzaCifrato = cifrato ? url.deletingPathExtension() : url
        return senzaCifrato.deletingPathExtension().lastPathComponent
    }
    /// Backup protetto da password («… .zip.cifrato»): solo per l'elenco; il ripristino lo
    /// riconosce dal contenuto.
    var cifrato: Bool { url.pathExtension == GestoreBackup.estensioneCifrata }
}

/// Un ripristino di un backup protetto in attesa della password scritta dal consulente.
struct RichiestaPasswordBackup: Equatable {
    let url: URL
    let messaggio: String
}

enum ErroreBackup: LocalizedError {
    case comando(String)
    case archivioMancante
    case archivioNonValido(String)
    case cartellaNonRaggiungibile(String)
    case versionePiuRecente
    /// Backup protetto aperto senza password.
    case serveLaPassword
    /// La password non apre il backup protetto.
    case passwordErrata
    /// Backup protetto alterato, troncato o con i pezzi fuori posto.
    case backupDanneggiato
    case cifratura(String)
    /// Protezione attiva ma password non disponibile: il backup non si fa in chiaro.
    case passwordNonDisponibile
    /// Nella cartella da salvare non c'è un archivio completo: un backup così non si ripristinerebbe e, con la
    /// rotazione, sostituirebbe quelli buoni.
    case senzaArchivio

    var errorDescription: String? {
        switch self {
        case .comando(let m): return "Compressione non riuscita: \(m)"
        case .archivioMancante: return "Il file scelto non è un backup di Prisma."
        case .archivioNonValido(let m): return "Il backup non è leggibile: \(m)"
        case .cartellaNonRaggiungibile(let p): return "La cartella dei backup non è raggiungibile (\(p)): collega il disco o scegline un'altra."
        case .versionePiuRecente: return "Il backup è stato creato da una versione più recente di Prisma: aprilo con l'ultima versione."
        case .serveLaPassword: return "Questo backup è protetto da una password: scrivila per ripristinarlo."
        case .passwordErrata: return "La password non apre questo backup. Controlla di averla scritta bene: i backup fatti prima di un cambio di password si aprono con la password di allora."
        case .backupDanneggiato: return "Il backup protetto è danneggiato o incompleto e non si può aprire: prova con un altro backup."
        case .cifratura(let m): return "Protezione del backup non riuscita: \(m)"
        case .passwordNonDisponibile: return "La password dei backup non è disponibile: scrivila in Impostazioni › Archivio. Senza password il backup non si fa, per non salvarlo in chiaro."
        case .senzaArchivio: return "Nella cartella di Prisma non trovo un archivio completo da salvare: il backup non si fa, per non sostituire quelli buoni. Chiudi Prisma e riaprilo."
        }
    }

    /// true per la password sbagliata (si richiede la password invece di fermarsi).
    var passwordSbagliata: Bool {
        if case .passwordErrata = self { return true }
        return false
    }
}

/// Backup dell'intera cartella dell'archivio in file .zip, con rotazione.
/// Sul Mac usa /usr/bin/ditto, presente su ogni Mac: nessuna dipendenza esterna. Su iPhone e iPad (niente
/// `Process`) lo zip si scrive con `ScrittoreZip` e si legge con `LettoreZip`, che aprono anche i backup di ditto.
/// Con una password il backup è un «… .zip.cifrato» (vedi `CifraturaBackup`): lo zip in chiaro
/// nasce solo nella cartella temporanea del Mac e si cancella subito.
enum GestoreBackup {
    static let prefisso = "Prisma backup "
    /// Estensione aggiunta a «.zip» dai backup protetti da password.
    static let estensioneCifrata = "cifrato"
    /// Rotazione: si tengono le ultime 8 copie automatiche (8 settimane) e, a parte, le ultime 8
    /// copie fatte a mano o di sicurezza: un ripristino non consuma la storia settimanale.
    static let massimo = 8
    static let notaAutomatico = "automatico"
    /// Le cartelle che l'utente può lasciare fuori dai backup (la Biblioteca: PDF pesanti e circolari che possono essere
    /// riservate). Un ripristino da un backup che non le ha tiene quelle del Mac.
    static let cartelleEscludibili = ["Biblioteca"]

    /// Crea un backup di `sorgente` dentro `destinazione` e applica la rotazione.
    /// - creaCartella: false per la cartella scelta dall'utente: se non c'è (disco scollegato) è un
    ///   errore, non si ricrea il percorso sul disco del Mac.
    /// - proteggi: un backup da non eliminare con la rotazione (quello che si sta ripristinando).
    /// - password: con una password il backup è protetto («… .zip.cifrato»); nil = zip in chiaro.
    /// - iterazioni: solo per la prova (più bassa per la durata); l'app usa sempre quelle predefinite.
    /// - escludi: cartelle dell'archivio da lasciare fuori («Biblioteca» con «Escludi la Biblioteca dal backup», «Luce»
    ///   giro 6): il backup si fa da una copia senza quelle cartelle, nella cartella temporanea del Mac (su APFS la copia
    ///   è un clone, non occupa spazio), che si cancella subito.
    @discardableResult
    static func crea(sorgente: URL, escludi: [String] = [], destinazione: URL, nota: String? = nil, creaCartella: Bool = true,
                     proteggi: URL? = nil, password: String? = nil,
                     iterazioni: UInt32 = CifraturaBackup.iterazioniPredefinite) throws -> URL {
        if let password, password.isEmpty { throw ErroreBackup.passwordNonDisponibile }
        let fm = FileManager.default
        var sorgente = sorgente
        var copia: URL?
        defer { if let copia { try? fm.removeItem(at: copia) } }
        // Nel backup va l'archivio che varrebbe all'avvio, uno solo: la cartella a pezzi (con l'indice e senza una
        // conversione da verificare) con il segnaposto al posto di archivio.json per le versioni di Prisma di prima,
        // oppure archivio.json (e nessun pezzo sciolto). La scelta e la copia si fanno a coda dei salvataggi ferma: nel
        // backup mai un salvataggio a metà (un indice nuovo con i file dei clienti di prima). Mai la copia d'avvio
        // (nemmeno una rimasta a metà, «Archivio-all-avvio.tmp-…»), il segno della conversione o una cartella scartata.
        // Senza nessun archivio il backup non si fa: con la rotazione sostituirebbe quelli buoni
        let archivio: Set<String> = [ArchivioPezzi.nomeCartella, Archivio.nomeFileVecchio]
        func lasciaFuori(_ nome: String) -> Bool {
            escludi.contains(nome) || archivio.contains(nome) || nome.hasPrefix(Archivio.nomeCopiaAvvio) || nome == fileChiaviCapsule
                || nome == Archivio.nomeConversioneDaVerificare || nome.hasPrefix(Archivio.prefissoCartellaScartata)
        }
        let voci = try fm.contentsOfDirectory(atPath: sorgente.path)
        // «Luce» giro 15 (decisione 42): le chiavi delle capsule del tempo solo nei backup protetti, dentro lo zip che poi
        // si cifra (si passa sempre dalla copia temporanea); senza password non entrano mai
        let chiaviCapsule = password == nil ? [] : chiaviCapsuleDaSalvare()
        let soloArchivioJson = !voci.contains { lasciaFuori($0) && $0 != Archivio.nomeFileVecchio }
        if soloArchivioJson && chiaviCapsule.isEmpty {
            // Il formato di prima, niente da lasciare fuori: lo zip della cartella com'è
            guard Archivio.valeArchivioJson(in: sorgente) else { throw ErroreBackup.senzaArchivio }
        } else {
            let radice = fm.temporaryDirectory.appendingPathComponent("Prisma-copia-\(UUID().uuidString)", isDirectory: true)
            let dentro = radice.appendingPathComponent(sorgente.lastPathComponent, isDirectory: true)
            copia = radice
            try fm.createDirectory(at: dentro, withIntermediateDirectories: true)
            for nome in voci where !lasciaFuori(nome) {
                try fm.copyItem(at: sorgente.appendingPathComponent(nome), to: dentro.appendingPathComponent(nome))
            }
            let da = sorgente
            try Archivio.coda.sync {
                if Archivio.valeArchivioJson(in: da) {
                    try fm.copyItem(at: da.appendingPathComponent(Archivio.nomeFileVecchio), to: dentro.appendingPathComponent(Archivio.nomeFileVecchio))
                } else if ArchivioPezzi.presente(in: da) {
                    try fm.copyItem(at: ArchivioPezzi.cartellaPezzi(in: da), to: ArchivioPezzi.cartellaPezzi(in: dentro))
                    try Archivio.datiSegnaposto().write(to: dentro.appendingPathComponent(Archivio.nomeFileVecchio))
                } else {
                    throw ErroreBackup.senzaArchivio
                }
            }
            if !chiaviCapsule.isEmpty {
                let testi = chiaviCapsule.map { $0.base64EncodedString() }
                try JSONEncoder().encode(testi).write(to: dentro.appendingPathComponent(fileChiaviCapsule), options: .atomic)
            }
            sorgente = dentro
        }
        if creaCartella {
            try fm.createDirectory(at: destinazione, withIntermediateDirectories: true)
            #if os(macOS)
            // Sul Mac nulla cambia: la cartella dei backup la sceglie l'utente (anche iCloud Drive)
            #elseif os(iOS)
            // Le copie di sicurezza del dispositivo non vanno nel backup iCloud del telefono (niente cloud)
            Archivio.escludiDalBackup(destinazione)
            #endif
        } else {
            var cartella: ObjCBool = false
            guard fm.fileExists(atPath: destinazione.path, isDirectory: &cartella), cartella.boolValue else {
                throw ErroreBackup.cartellaNonRaggiungibile(destinazione.path)
            }
        }
        // Copie parziali rimaste da un backup interrotto: contengono dati dei clienti
        for vecchia in (try? fm.contentsOfDirectory(at: destinazione, includingPropertiesForKeys: nil)) ?? []
        where vecchia.lastPathComponent.hasPrefix(prefisso) && vecchia.lastPathComponent.hasSuffix(".parziale") {
            try? fm.removeItem(at: vecchia)
        }
        var nome = prefisso + Formati.nomeFile.string(from: Date())
        if let nota { nome += " (\(nota))" }
        let estensione = password == nil ? ".zip" : ".zip." + estensioneCifrata
        let finale = destinazione.appendingPathComponent(nome + estensione)
        let parziale = destinazione.appendingPathComponent(nome + estensione + ".parziale")
        do {
            if let password {
                // Lo zip in chiaro solo nella cartella temporanea del Mac, mai nella cartella dei
                // backup (può essere iCloud Drive): si cifra da lì e si cancella subito
                let chiaro = fm.temporaryDirectory.appendingPathComponent("Prisma-chiaro-\(UUID().uuidString).zip")
                defer { try? fm.removeItem(at: chiaro) }
                try comprimi(sorgente, in: chiaro)
                try CifraturaBackup.cifra(chiaro, in: parziale, password: password, iterazioni: iterazioni)
            } else {
                try comprimi(sorgente, in: parziale)
            }
            try? fm.removeItem(at: finale)
            try fm.moveItem(at: parziale, to: finale)
        } catch {
            try? fm.removeItem(at: parziale)
            throw error
        }
        ruota(destinazione, proteggi: proteggi)
        return finale
    }

    static func automatico(_ v: VoceBackup) -> Bool { v.nome.hasSuffix("(\(notaAutomatico))") }

    /// Backup presenti, dal più recente.
    static func elenca(_ cartella: URL) -> [VoceBackup] {
        let chiavi: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey]
        let file = (try? FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: chiavi)) ?? []
        return file
            // In chiaro e protetti insieme: la rotazione li conta come un'unica serie
            .filter { url in
                let n = url.lastPathComponent
                return n.hasPrefix(prefisso) && (n.hasSuffix(".zip") || n.hasSuffix(".zip." + estensioneCifrata))
            }
            .map { url in
                let v = try? url.resourceValues(forKeys: Set(chiavi))
                return VoceBackup(url: url, data: v?.contentModificationDate ?? .distantPast, dimensione: Int64(v?.fileSize ?? 0))
            }
            .sorted { $0.data > $1.data }
    }

    /// Elimina i backup più vecchi oltre le ultime `massimo` copie, contando a parte quelle automatiche.
    static func ruota(_ cartella: URL, proteggi: URL? = nil) {
        let tutti = elenca(cartella)
        let troppi = Array(tutti.filter(automatico).dropFirst(massimo)) + Array(tutti.filter { !automatico($0) }.dropFirst(massimo))
        for vecchio in troppi where vecchio.url.standardizedFileURL != proteggi?.standardizedFileURL {
            try? FileManager.default.removeItem(at: vecchio.url)
        }
    }

    /// Estrae un backup in una cartella temporanea e ne verifica l'archivio.
    /// Restituisce i dati e la cartella "Prisma" estratta.
    /// Un backup protetto si riconosce dal contenuto (non dall'estensione) e si apre con la
    /// password: senza → `.serveLaPassword`, sbagliata → `.passwordErrata`. I vecchi .zip in
    /// chiaro si ripristinano come sempre (la password, se c'è, non serve).
    static func estrai(_ backup: URL, password: String? = nil) throws -> (dati: DatiPrisma, cartella: URL) {
        guard CifraturaBackup.cifrato(backup) else {
            let estratto = try estraiZip(backup)
            togliChiaviCapsule(in: estratto.cartella, consegna: false)
            return estratto
        }
        guard let password, !password.isEmpty else { throw ErroreBackup.serveLaPassword }
        // Lo zip decifrato vive solo nella cartella temporanea, il tempo di estrarlo
        let chiaro = FileManager.default.temporaryDirectory.appendingPathComponent("Prisma-decifrato-\(UUID().uuidString).zip")
        defer { try? FileManager.default.removeItem(at: chiaro) }
        try CifraturaBackup.decifra(backup, in: chiaro, password: password)
        let estratto = try estraiZip(chiaro)
        togliChiaviCapsule(in: estratto.cartella, consegna: true)
        return estratto
    }

    /// Le chiavi delle capsule di un backup protetto: si consegnano a `chiaviCapsuleRitrovate` e il file si toglie
    /// prima di restituire la cartella (non arriva mai nella cartella dell'archivio). Da un backup in chiaro (non
    /// dovrebbe averle) il file si toglie e basta.
    private static func togliChiaviCapsule(in cartella: URL, consegna: Bool) {
        let url = cartella.appendingPathComponent(fileChiaviCapsule)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        defer { try? FileManager.default.removeItem(at: url) }
        guard consegna, let dati = try? Data(contentsOf: url),
              let testi = try? JSONDecoder().decode([String].self, from: dati) else { return }
        let chiavi = testi.compactMap { Data(base64Encoded: $0) }
        if !chiavi.isEmpty { chiaviCapsuleRitrovate(chiavi) }
    }

    private static func estraiZip(_ zip: URL) throws -> (dati: DatiPrisma, cartella: URL) {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("Prisma-ripristino-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        do {
            try decomprimi(zip, in: tmp)
            let candidati = [tmp.appendingPathComponent("Prisma", isDirectory: true), tmp]
            // Un backup nuovo ha la cartella a pezzi, uno di prima archivio.json: si leggono tutti e due
            guard let radice = candidati.first(where: { Archivio.presente(in: $0) }) else {
                throw ErroreBackup.archivioMancante
            }
            let dati = try Archivio.leggiPerRipristino(radice)
            // Il segnaposto per le versioni di prima non deve arrivare nella cartella dell'archivio
            Archivio.togliSegnaposto(in: radice)
            // Un backup di una versione più recente perderebbe i dati che questa non conosce
            guard !Archivio.diVersionePiuRecente(dati) else { throw ErroreBackup.versionePiuRecente }
            return (dati, radice)
        } catch {
            // Niente copie dei dati dei clienti lasciate nella cartella temporanea
            try? fm.removeItem(at: tmp)
            throw error
        }
    }

    /// Elimina la cartella temporanea di un'estrazione (anche se il ripristino non va a buon fine).
    static func pulisciEstrazione(_ estratta: URL) {
        let temporanea = [estratta, estratta.deletingLastPathComponent()]
            .first { $0.lastPathComponent.hasPrefix("Prisma-ripristino-") }
        if let temporanea { try? FileManager.default.removeItem(at: temporanea) }
    }

    /// Sostituisce la cartella dell'archivio con quella estratta, senza mai lasciarla a metà:
    /// prepara la nuova cartella accanto («Prisma.ripristino»), sposta quella attuale in
    /// «Prisma.precedente» e mette la nuova al suo posto (spostamenti sullo stesso disco, istantanei).
    /// Se qualcosa va storto torna la cartella di prima; un'interruzione la recupera `recuperaRipristino`.
    static func sostituisci(cartellaDati: URL, con estratta: URL) throws {
        let fm = FileManager.default
        defer { pulisciEstrazione(estratta) }
        let (nuova, precedente) = cartelleRipristino(cartellaDati)
        try? fm.removeItem(at: nuova)
        try? fm.removeItem(at: precedente)
        try fm.createDirectory(at: cartellaDati.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.copyItem(at: estratta, to: nuova)
        // Un backup di prima del cambio di nome ha la cartella di Vera col vecchio nome
        Archivio.spostaCartellaVecchia(in: nuova)
        // Un backup fatto con «Escludi la Biblioteca» non la porta: resta quella del Mac
        for esclusa in cartelleEscludibili
        where !fm.fileExists(atPath: nuova.appendingPathComponent(esclusa).path) && fm.fileExists(atPath: cartellaDati.appendingPathComponent(esclusa).path) {
            try? fm.copyItem(at: cartellaDati.appendingPathComponent(esclusa), to: nuova.appendingPathComponent(esclusa))
        }
        // Le copie degli archivi non leggibili restano: possono contenere gli unici dati veri
        for voce in (try? fm.contentsOfDirectory(at: cartellaDati, includingPropertiesForKeys: nil)) ?? []
        where voce.lastPathComponent.hasPrefix(Archivio.prefissoNonLeggibile) {
            try? fm.copyItem(at: voce, to: nuova.appendingPathComponent(voce.lastPathComponent))
        }
        let cera = fm.fileExists(atPath: cartellaDati.path)
        if cera { try fm.moveItem(at: cartellaDati, to: precedente) }
        do {
            try fm.moveItem(at: nuova, to: cartellaDati)
        } catch {
            if cera { try? fm.moveItem(at: precedente, to: cartellaDati) }
            try? fm.removeItem(at: nuova)
            throw error
        }
        try? fm.removeItem(at: precedente)
    }

    static func cartelleRipristino(_ cartellaDati: URL) -> (nuova: URL, precedente: URL) {
        let genitore = cartellaDati.deletingLastPathComponent()
        let nome = cartellaDati.lastPathComponent
        return (genitore.appendingPathComponent(nome + ".ripristino", isDirectory: true),
                genitore.appendingPathComponent(nome + ".precedente", isDirectory: true))
    }

    /// Dopo un ripristino interrotto (Mac spento a metà): se l'archivio manca ma c'è la cartella di
    /// prima, la rimette al suo posto. Restituisce true se ha recuperato qualcosa.
    @discardableResult
    static func recuperaRipristino(_ cartellaDati: URL) -> Bool {
        let fm = FileManager.default
        let (nuova, precedente) = cartelleRipristino(cartellaDati)
        guard !Archivio.presente(in: cartellaDati) else {
            try? fm.removeItem(at: nuova)
            return false
        }
        for candidata in [precedente, nuova] where Archivio.presente(in: candidata) {
            if fm.fileExists(atPath: cartellaDati.path) {
                let messa = cartellaDati.deletingLastPathComponent().appendingPathComponent(cartellaDati.lastPathComponent + ".incompleta \(UUID().uuidString.prefix(6))")
                try? fm.moveItem(at: cartellaDati, to: messa)
            }
            if (try? fm.moveItem(at: candidata, to: cartellaDati)) != nil { return true }
        }
        return false
    }

    /// Lo zip della cartella `sorgente` (la cartella stessa compresa, come `--keepParent`) nel file `zip`.
    private static func comprimi(_ sorgente: URL, in zip: URL) throws {
        #if os(macOS)
        try ditto(["-c", "-k", "--sequesterRsrc", "--keepParent", sorgente.path, zip.path])
        #elseif os(iOS)
        do {
            try ScrittoreZip.crea(da: sorgente, a: zip)
        } catch let errore as ErroreZip {
            throw ErroreBackup.comando(errore.localizedDescription)
        }
        #endif
    }

    /// Estrae lo zip `zip` nella cartella `cartella`.
    private static func decomprimi(_ zip: URL, in cartella: URL) throws {
        #if os(macOS)
        try ditto(["-x", "-k", zip.path, cartella.path])
        #elseif os(iOS)
        do {
            try LettoreZip.estrai(zip, in: cartella)
        } catch let errore as ErroreZip {
            throw ErroreBackup.archivioNonValido(errore.localizedDescription)
        }
        #endif
    }

    #if os(macOS)
    /// /usr/bin/ditto con gli argomenti dati (anche per la prova di confronto con `LettoreZip`).
    static func ditto(_ argomenti: [String]) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        p.arguments = argomenti
        let errore = Pipe()
        p.standardError = errore
        try p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else {
            let testo = String(data: errore.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ErroreBackup.comando(testo.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    #endif
}

/// Le chiavi delle capsule del tempo nei backup protetti («Luce» giro 15, decisione 42). Gli hook li imposta solo
/// l'«Avvio vero» (`CapsuleNelBackup.installa()`, con il Portachiavi) o la prova del backup (con chiavi di prova): di base
/// nessuna chiave entra e nessuna si consegna.
extension GestoreBackup {
    nonisolated(unsafe) static var chiaviCapsuleDaSalvare: () -> [Data] = { [] }
    nonisolated(unsafe) static var chiaviCapsuleRitrovate: ([Data]) -> Void = { _ in }
    /// Il file dentro lo zip cifrato: JSON con le chiavi in base64.
    static let fileChiaviCapsule = "chiavi-capsule.bin"
}
