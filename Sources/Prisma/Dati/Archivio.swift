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
    /// Il segno di una conversione di archivio.json non ancora verificata (scritto prima di confermare la cartella a
    /// pezzi, tolto quando la cartella riletta è identica). Finché c'è, l'archivio valido è archivio.json: all'avvio la
    /// verifica si rifà, i backup prendono archivio.json. Mai nei backup.
    static let nomeConversioneDaVerificare = "conversione-da-verificare.json"
    /// Una cartella a pezzi scartata da una conversione non verificata («Archivio.scartata-xxxxxxxx»), da cancellare.
    static let prefissoCartellaScartata = "Archivio.scartata-"
    /// Il nome della copia di un archivio.json scritto da una versione di Prisma di prima accanto alla cartella a pezzi.
    static let prefissoVersionePrecedente = "archivio di una versione precedente"

    /// Copia dell'archivio di prima fatta a ogni avvio (formato a file unico).
    static var copiaAvvio: URL { cartella.appendingPathComponent("archivio-all-avvio.json") }
    static let prefissoNonLeggibile = "archivio-non-leggibile"

    /// Solo il numero di versione: si legge anche quando il resto dell'archivio non si legge.
    private struct SoloVersione: Decodable { var versione: Int? }

    /// Il segnaposto messo come archivio.json nei backup della cartella a pezzi, per le versioni di Prisma di prima
    /// (che cercano archivio.json): lo leggono come un archivio vuoto di una versione molto più recente e rispondono «Il
    /// backup è stato creato da una versione più recente di Prisma», non «non è un backup di Prisma». Questa versione lo
    /// riconosce dalla chiave `segnapostoArchivio` e lo ignora: non è mai un archivio.
    private struct Segnaposto: Decodable { var segnapostoArchivio: String? }
    static let versioneSegnaposto = 1_000_000

    static func datiSegnaposto() -> Data {
        let testo = "L'archivio di questo backup è nella cartella Archivio/: si apre con Prisma aggiornato (dal giro 0 di «Prisma istantaneo» in poi)."
        let oggetto: [String: Any] = ["versione": versioneSegnaposto, "clienti": [Any](), "segnapostoArchivio": testo]
        return (try? JSONSerialization.data(withJSONObject: oggetto, options: [.prettyPrinted, .sortedKeys])) ?? Data()
    }

    /// true se `url` è il segnaposto dei backup (piccolo, con la chiave `segnapostoArchivio`).
    static func segnaposto(_ url: URL) -> Bool {
        guard let n = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int, n < 4096,
              let grezzo = try? Data(contentsOf: url) else { return false }
        return (try? JSONDecoder().decode(Segnaposto.self, from: grezzo))?.segnapostoArchivio != nil
    }

    /// Toglie il segnaposto da una cartella (estratta da un backup o, per sicurezza, quella dell'archivio).
    static func togliSegnaposto(in cartella: URL) {
        let u = cartella.appendingPathComponent(nomeFileVecchio)
        if segnaposto(u) { try? FileManager.default.removeItem(at: u) }
    }

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

    /// true se in `cartella` un archivio.json vero (non il segnaposto) vale più della cartella a pezzi: conversione non
    /// ancora verificata (c'è il segno) oppure nessuna cartella a pezzi con l'indice. Lo usano i backup: prendono
    /// l'archivio che varrebbe all'avvio, mai una cartella a pezzi incompleta o da verificare al posto di archivio.json.
    static func valeArchivioJson(in cartella: URL) -> Bool {
        let fm = FileManager.default
        let vecchio = cartella.appendingPathComponent(nomeFileVecchio)
        guard fm.fileExists(atPath: vecchio.path), !segnaposto(vecchio) else { return false }
        return !ArchivioPezzi.presente(in: cartella) || fm.fileExists(atPath: cartella.appendingPathComponent(nomeConversioneDaVerificare).path)
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
        pulisciCopieInterrotte(in: cartella)
        togliSegnaposto(in: cartella)
        // Un salvataggio di più file confermato e interrotto si completa prima di leggere (uno non confermato si scarta)
        do {
            try ArchivioPezzi.completaTransazione(pezzi)
        } catch {
            return EsitoCarica(dati: ArchivioPezzi.vuoto, avviso: avvisoNonApribile(error), solaLettura: true)
        }
        let clientiSciolti = !((try? fm.contentsOfDirectory(atPath: pezzi.appendingPathComponent(ArchivioPezzi.nomeClienti).path)) ?? [])
            .filter { $0.hasSuffix(".json") }.isEmpty
        let sezioniSciolte = ArchivioPezzi.sezioni.contains {
            fm.fileExists(atPath: pezzi.appendingPathComponent(ArchivioPezzi.nomeFileSezione($0.nome)).path)
        } || fm.fileExists(atPath: pezzi.appendingPathComponent(ArchivioPezzi.nomeRiserva).path)
        // Le cartelle a pezzi scartate da una conversione non verificata (la cancellazione non era riuscita)
        for nome in (try? fm.contentsOfDirectory(atPath: cartella.path)) ?? [] where nome.hasPrefix(prefissoCartellaScartata) {
            try? fm.removeItem(at: cartella.appendingPathComponent(nome))
        }

        // 1. La cartella a pezzi (anche senza indice, se ci sono i file dei clienti o le sezioni: si ricostruisce)
        if ArchivioPezzi.presente(in: cartella) || clientiSciolti || sezioniSciolte {
            if var e = caricaPezzi(cartella, indiceLetto: indiceLetto) {
                if e.avviso == nil { e.avviso = avvisoRecupero }
                return e
            }
            // nil: c'è archivio.json con il segno della conversione da verificare, e la cartella riletta non è uguale
        }
        // 2. Il file unico di prima
        if fm.fileExists(atPath: vecchio.path) {
            var e = caricaVecchio(cartella)
            if e.avviso == nil { e.avviso = avvisoRecupero }
            return e
        }
        // 3. Niente archivio (nessun pezzo, nessun archivio.json): la copia dell'ultimo avvio (a pezzi, poi quella di prima).
        // Una copia che c'è ma che non si apre (più recente, non leggibile adesso) non lascia mai il posto ai dati di prova:
        // sola lettura, nulla scritto sopra
        let mancava = "L'archivio mancava: ho ripreso la copia fatta all'ultimo avvio di Prisma. Controlla gli ultimi inserimenti."
        let copiaPezzi = cartella.appendingPathComponent(nomeCopiaAvvio, isDirectory: true)
        if fm.fileExists(atPath: copiaPezzi.appendingPathComponent(ArchivioPezzi.nomeIndice).path) {
            try? fm.removeItem(at: pezzi)
            guard (try? fm.copyItem(at: copiaPezzi, to: pezzi)) != nil, var e = caricaPezzi(cartella, indiceLetto: nil) else {
                return EsitoCarica(dati: ArchivioPezzi.vuoto, avviso: "L'archivio di Prisma manca e non riesco a riprendere la copia fatta all'ultimo avvio: non salvo nulla. Chiudi Prisma e riaprilo; se succede ancora, ripristina un backup da Impostazioni.", solaLettura: true)
            }
            if !e.solaLettura { e.avviso = e.avviso.map { mancava + " " + $0 } ?? mancava }
            return e
        }
        let copiaVecchia = cartella.appendingPathComponent("archivio-all-avvio.json")
        if fm.fileExists(atPath: copiaVecchia.path) {
            guard let grezzo = try? Data(contentsOf: copiaVecchia), let d = try? decodifica(grezzo) else {
                if let v = (try? Data(contentsOf: copiaVecchia)).flatMap({ try? decodificatore.decode(SoloVersione.self, from: $0) })?.versione,
                   v > DatiPrisma.versioneAttuale {
                    return EsitoCarica(dati: ArchivioPezzi.vuoto, avviso: avvisoPiuRecente, solaLettura: true, bloccaRipristino: true)
                }
                return EsitoCarica(dati: ArchivioPezzi.vuoto, avviso: "L'archivio di Prisma manca e la copia fatta all'ultimo avvio non si apre: non salvo nulla. Ripristina un backup da Impostazioni (o chiedi aiuto prima di continuare).", solaLettura: true)
            }
            if diVersionePiuRecente(d) { return EsitoCarica(dati: d, avviso: avvisoPiuRecente, solaLettura: true, bloccaRipristino: true) }
            try? salva(d, in: cartella)
            return EsitoCarica(dati: d, avviso: mancava)
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

    /// L'avviso di un archivio che non si apre e che quindi non si tocca (sola lettura).
    static func avvisoNonApribile(_ error: Error) -> String {
        "Non riesco ad aprire l'archivio di Prisma (\(error.localizedDescription)): non salvo nulla e non tocco i file. Chiudi Prisma e riaprilo; se succede ancora, riavvia il dispositivo."
    }

    /// L'esito di una cartella a pezzi che non si deve toccare: più recente di questo Prisma, o non leggibile adesso.
    private static func nonApribile(_ error: Error) -> EsitoCarica {
        switch error {
        case ErroreArchivioPezzi.formatoPiuRecente, ErroreArchivioPezzi.versionePiuRecente:
            return EsitoCarica(dati: ArchivioPezzi.vuoto, avviso: avvisoPiuRecente, solaLettura: true, bloccaRipristino: true)
        default:
            return EsitoCarica(dati: ArchivioPezzi.vuoto, avviso: avvisoNonApribile(error), solaLettura: true)
        }
    }

    private static func dataModifica(_ url: URL) -> Date {
        ((try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date) ?? .distantPast
    }

    /// L'ultima scrittura nella cartella a pezzi (indice, sezioni, file dei clienti).
    private static func ultimaModificaPezzi(_ pezzi: URL) -> Date {
        let fm = FileManager.default
        var ultima = Date.distantPast
        for c in [pezzi, pezzi.appendingPathComponent(ArchivioPezzi.nomeClienti, isDirectory: true)] {
            for nome in (try? fm.contentsOfDirectory(atPath: c.path)) ?? [] where nome.hasSuffix(".json") {
                ultima = max(ultima, dataModifica(c.appendingPathComponent(nome)))
            }
        }
        return ultima
    }

    /// Un nome libero nella cartella dell'archivio per una copia messa da parte (mai sopra un'altra copia).
    private static func destinazioneLibera(_ base: String, in cartella: URL) -> URL {
        var u = cartella.appendingPathComponent(base + ".json")
        var n = 2
        while FileManager.default.fileExists(atPath: u.path) {
            u = cartella.appendingPathComponent("\(base) \(n).json")
            n += 1
        }
        return u
    }

    /// La cartella a pezzi, con un archivio.json accanto:
    /// - con il segno della conversione da verificare (`nomeConversioneDaVerificare`: Prisma si è fermato fra la conferma
    ///   della cartella e la verifica, o la verifica era fallita) la verifica si rifà qui: cartella riletta identica ad
    ///   archivio.json → la conversione vale; diversa (o la cartella non si legge pulita) → nil, vale archivio.json;
    /// - senza segno e più vecchio della cartella: la copia di una conversione finita (la rinomina in
    ///   archivio.json.vecchio non era riuscita), si mette da parte come archivio.json.vecchio;
    /// - senza segno e più recente: l'ha scritto una versione di Prisma di prima (che non conosce la cartella a pezzi).
    ///   Vale la cartella; archivio.json si mette da parte con il suo nome, mai usato né cancellato, e l'avviso lo dice.
    /// Un indice o un file che adesso non si legge (non rovinato), o scritto da un Prisma più recente: sola lettura.
    private static func caricaPezzi(_ cartella: URL, indiceLetto: ((DatiPrisma) -> Void)?) -> EsitoCarica? {
        let fm = FileManager.default
        let pezzi = ArchivioPezzi.cartellaPezzi(in: cartella)
        let vecchio = cartella.appendingPathComponent(nomeFileVecchio)
        let vecchioPresente = fm.fileExists(atPath: vecchio.path)
        let segno = cartella.appendingPathComponent(nomeConversioneDaVerificare)
        if !vecchioPresente { try? fm.removeItem(at: segno) }
        let daVerificare = vecchioPresente && fm.fileExists(atPath: segno.path)
        let indiceBuono: Bool
        do {
            _ = try ArchivioPezzi.leggiIndice(pezzi)
            indiceBuono = true
        } catch let e as ErroreArchivioPezzi where e.ricostruibile {
            indiceBuono = false
        } catch {
            return nonApribile(error)
        }
        // Senza indice: si ricostruisce dalla riserva dell'indice (di adesso) o, se non si legge, dall'indice della copia
        // d'avvio, o da uno vuoto
        let copia = cartella.appendingPathComponent(nomeCopiaAvvio, isDirectory: true)
        let riserva: (indice: IndiceArchivio, attuale: Bool)
        do {
            riserva = indiceBuono ? (IndiceArchivio(), true) : try ArchivioPezzi.indiceDiRiserva(pezzi, copiaAvvio: copia)
        } catch {
            return nonApribile(error)
        }
        let r: (lettura: LetturaArchivio, problemi: [ProblemaPezzo], scartati: [URL])
        do {
            // Con la conversione da verificare lo scheletro non si dà: potrebbe valere archivio.json
            r = try ArchivioPezzi.leggi(pezzi, indiceLetto: daVerificare ? nil : indiceLetto.map { f in { f(ArchivioPezzi.scheletro($0)) } },
                                        indiceDiRiserva: riserva.indice)
        } catch {
            if daVerificare { return nil }
            return nonApribile(error)
        }
        let d = r.lettura.dati
        if diVersionePiuRecente(d) { return EsitoCarica(dati: d, avviso: avvisoPiuRecente, solaLettura: true, bloccaRipristino: true) }
        let quando = Formati.nomeFile.string(from: Date())
        var avvisoVersionePrecedente: String?
        if daVerificare {
            // La verifica della conversione, come in `ScrittorePezzi.convertiSeServe` (sul JSON con le chiavi in ordine)
            let codificatore = nuovoCodificatore()
            guard let grezzo = try? Data(contentsOf: vecchio) else { return nil }
            if var v = try? decodifica(grezzo) {
                v.versione = DatiPrisma.versioneAttuale
                guard r.problemi.isEmpty, indiceBuono, let atteso = try? codificatore.encode(v),
                      let riletto = try? codificatore.encode(d), atteso == riletto else { return nil }
            } else {
                // archivio.json si è rovinato dopo la conversione: vale la cartella; lui si mette da parte, mai cancellato
                guard (try? fm.moveItem(at: vecchio, to: destinazioneLibera("\(prefissoNonLeggibile) \(quando)", in: cartella))) != nil else { return nil }
            }
            // Verificata: il segno se ne va, archivio.json diventa archivio.json.vecchio (sotto)
            try? fm.removeItem(at: segno)
        } else if vecchioPresente, dataModifica(vecchio) > ultimaModificaPezzi(pezzi) {
            // Scritto da una versione di Prisma di prima dopo la conversione: non vale e non si perde
            let destinazione = destinazioneLibera("\(prefissoVersionePrecedente) \(quando)", in: cartella)
            if (try? fm.moveItem(at: vecchio, to: destinazione)) == nil {
                return EsitoCarica(dati: d, avviso: "Una versione precedente di Prisma ha scritto archivio.json accanto all'archivio attuale e non riesco a metterlo da parte: apro l'archivio in sola lettura e non salvo nulla. Chiudi Prisma e riaprilo.", solaLettura: true)
            }
            avvisoVersionePrecedente = "Una versione precedente di Prisma ha scritto un archivio dopo il passaggio al nuovo formato: non l'ho usato e l'ho messo da parte nella cartella di Prisma («\(destinazione.lastPathComponent)»). I dati aperti sono quelli dell'archivio attuale: se in quella versione hai inserito qualcosa, va riportato a mano."
        }
        // I file non citati e più vecchi dell'indice (clienti tolti) e i temporanei di un salvataggio interrotto
        for u in r.scartati { try? fm.removeItem(at: u) }
        pulisciTemporanei(in: pezzi)
        let convertito = cartella.appendingPathComponent(nomeFileConvertito)
        let vecchioDaParte = fm.fileExists(atPath: vecchio.path)
        if vecchioDaParte {
            // Più vecchio della cartella (o appena verificato): la copia della conversione (resta archivio.json.vecchio
            // fino al prossimo avvio pulito)
            try? fm.removeItem(at: convertito)
            try? fm.moveItem(at: vecchio, to: convertito)
        }
        if r.problemi.isEmpty && indiceBuono {
            // Riaperta bene dopo la conversione: la copia di archivio.json non serve più (verificata due volte)
            if !vecchioDaParte { try? fm.removeItem(at: convertito) }
            try? fm.removeItem(at: cartella.appendingPathComponent("archivio-all-avvio.json"))
            // La copia d'avvio in background: l'avvio non la aspetta (prima dei salvataggi, che passano dalla stessa coda)
            coda.async { copiaCartella(pezzi, in: copia) }
            return EsitoCarica(dati: d, avviso: avvisoVersionePrecedente, sulDisco: r.lettura)
        }
        // Qualcosa non si è letto: si mette da parte (mai cancellato), il resto si apre e si riscrive tutto. Se una copia
        // non si riesce a mettere da parte, sola lettura: la riscrittura toglierebbe il file che l'indice nuovo non cita
        func pulito(_ t: String) -> String {
            t.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: "«", with: "").replacingOccurrences(of: "»", with: "")
        }
        var voci: [String] = []
        for p in r.problemi {
            let file = p.file.deletingPathExtension().lastPathComponent
            let destinazione = destinazioneLibera("\(prefissoNonLeggibile) \(pulito(p.descrizione)) (\(pulito(file)))\(p.mancante ? " (mancante)" : "") \(quando)", in: cartella)
            if p.mancante {
                // Il segno che manca (ferma i backup automatici: con la rotazione sostituirebbero quelli che lo hanno)
                let segno = ["mancava": p.file.lastPathComponent, "che cosa": p.descrizione]
                try? JSONSerialization.data(withJSONObject: segno, options: [.prettyPrinted]).write(to: destinazione)
            } else {
                do {
                    try fm.moveItem(at: p.file, to: destinazione)
                } catch {
                    return EsitoCarica(dati: d, avviso: "Alcune parti dell'archivio non si sono aperte (\(p.descrizione)) e non riesco a metterne da parte una copia: apro l'archivio in sola lettura e non salvo nulla, per non perderle. Chiudi Prisma e riaprilo.", solaLettura: true)
                }
            }
            voci.append("\(p.descrizione) (\(p.mancante ? "manca" : "non si legge"))")
        }
        if !indiceBuono {
            let indice = pezzi.appendingPathComponent(ArchivioPezzi.nomeIndice)
            let destinazione = destinazioneLibera("\(prefissoNonLeggibile) indice \(quando)", in: cartella)
            if fm.fileExists(atPath: indice.path) {
                do {
                    try fm.moveItem(at: indice, to: destinazione)
                } catch {
                    return EsitoCarica(dati: d, avviso: "L'indice dell'archivio non si legge e non riesco a metterne da parte una copia: apro l'archivio in sola lettura e non salvo nulla. Chiudi Prisma e riaprilo.", solaLettura: true)
                }
            } else {
                try? Data(#"{"mancava": "indice.json"}"#.utf8).write(to: destinazione)
            }
            voci.insert(riserva.attuale
                        ? "l'indice dell'archivio (ricostruito dalla sua copia di riserva e dai file dei clienti)"
                        : "l'indice dell'archivio (ricostruito dai file dei clienti e dalla copia dell'ultimo avvio: impostazioni, ordine e contatori di Prisma ovunque sono tornati a quel momento; controlla le impostazioni e, se usi Prisma ovunque, non lasciarlo unire finché non hai verificato i dati)", at: 0)
        }
        var avviso = "Alcune parti dell'archivio non si sono aperte: " + voci.joined(separator: "; ")
            + ". Tutto il resto è aperto. Ne ho messo da parte una copia nella cartella di Prisma; i backup automatici sono fermi finché non ripristini un backup da Impostazioni o confermi che i dati vanno bene."
        if let a = avvisoVersionePrecedente { avviso += " " + a }
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
        // Il segnaposto per le versioni di prima non è un archivio
        let vecchioPresente = FileManager.default.fileExists(atPath: vecchio.path) && !segnaposto(vecchio)
        let pezzi = ArchivioPezzi.cartellaPezzi(in: radice)
        // Un backup fatto con una transazione confermata e non finita (non dovrebbe succedere: si copia a salvataggi fermi)
        try? ArchivioPezzi.completaTransazione(pezzi)
        if ArchivioPezzi.presente(in: radice) {
            do {
                let r = try ArchivioPezzi.leggi(pezzi)
                if r.problemi.isEmpty { return r.lettura.dati }
                if !vecchioPresente {
                    throw ErroreBackup.archivioNonValido("mancano o non si leggono " + r.problemi.map(\.descrizione).joined(separator: ", "))
                }
            } catch ErroreArchivioPezzi.formatoPiuRecente, ErroreArchivioPezzi.versionePiuRecente {
                throw ErroreBackup.versionePiuRecente
            } catch let e as ErroreBackup {
                throw e
            } catch {
                if !vecchioPresente { throw ErroreBackup.archivioNonValido(error.localizedDescription) }
            }
        }
        guard vecchioPresente else { throw ErroreBackup.archivioMancante }
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

    /// Le opzioni di una scrittura diretta (senza `.atomic`: il temporaneo e la rinomina li fa `scriviAtomico`): su
    /// iPhone e iPad la protezione completa dei file.
    static var opzioniScritturaDiretta: Data.WritingOptions {
        #if os(macOS)
        return []
        #elseif os(iOS)
        return [.completeFileProtection]
        #endif
    }

    /// Porta sul disco ciò che è stato scritto in `url` (un file o una cartella, per le rinomine fatte dentro). Di base
    /// con una barriera (`F_BARRIERFSYNC`): tutto ciò che è scritto prima arriva sul disco prima di ciò che viene dopo
    /// (il contenuto prima della rinomina che lo mette al suo posto), senza aspettare lo svuotamento della cache del
    /// disco. `completo` (`F_FULLFSYNC`) aspetta anche quello: solo per la conferma di una transazione.
    static func sincronizza(_ url: URL, completo: Bool = false) {
        let fd = open(url.path, O_RDONLY)
        guard fd >= 0 else { return }
        defer { close(fd) }
        if fcntl(fd, completo ? F_FULLFSYNC : F_BARRIERFSYNC) == -1 { fsync(fd) }
    }

    /// Scrittura atomica: un file temporaneo accanto («nome.tmp-xxxxxxxx»), portato sul disco, e poi la rinomina, che
    /// sostituisce il file in un colpo solo. Un'interruzione (anche un Mac che si spegne) lascia al più il temporaneo
    /// (che la lettura ignora e toglie), mai un file a metà. `completo`: vedi `sincronizza`.
    static func scriviAtomico(_ data: Data, in url: URL, completo: Bool = false) throws {
        let temporaneo = url.deletingLastPathComponent()
            .appendingPathComponent(url.lastPathComponent + ".tmp-" + UUID().uuidString.prefix(8).lowercased())
        try data.write(to: temporaneo, options: opzioniScritturaDiretta)
        sincronizza(temporaneo, completo: completo)
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

    /// Toglie le copie d'avvio lasciate a metà («Archivio-all-avvio.tmp-xxxxxxxx», un'interruzione durante la copia):
    /// sono dati dei clienti in più, che nessuno legge e che i backup porterebbero con sé.
    static func pulisciCopieInterrotte(in cartella: URL) {
        let fm = FileManager.default
        for nome in (try? fm.contentsOfDirectory(atPath: cartella.path)) ?? [] where nome.hasPrefix(nomeCopiaAvvio + ".tmp-") {
            try? fm.removeItem(at: cartella.appendingPathComponent(nome))
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
