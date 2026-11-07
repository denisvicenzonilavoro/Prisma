import CommonCrypto
import CryptoKit
import Foundation
import Security

/// Cifratura dei backup protetti da password (file «… .zip.cifrato»). Solo framework Apple.
///
/// Formato (numeri big-endian):
/// - intestazione, 50 byte: «PRISMACF» (8) · versione (1) · algoritmo (1) · iterazioni PBKDF2 (4)
///   · sale casuale (16) · dimensione dei segmenti in byte (4) · verifica della password (16);
/// - poi i segmenti dello zip, ciascuno: lunghezza (4) + AES-256-GCM combinato
///   (nonce casuale 12 + cifrato + etichetta 16).
///
/// Ogni segmento autentica come dati associati l'intestazione intera, il suo indice (8) e il segno
/// di «ultimo» (1): un segmento spostato, tolto o aggiunto e un file troncato non si aprono, e
/// nessuno può cambiare iterazioni o sale. La chiave è PBKDF2-HMAC-SHA256 della password (in forma
/// Unicode normalizzata) con il sale del file: ogni backup ha una chiave sua, da cui HKDF ricava
/// due chiavi separate, una per cifrare e una per l'impronta che riconosce la password sbagliata.
/// Si cifra e decifra un segmento da 1 MiB alla volta: lo zip intero non sta mai in memoria.
///
/// Algoritmo 2 («chiave dello spazio», Prisma ovunque, Design/ovunque-fattibilita.md §3): stesso formato e stessi
/// segmenti, ma la chiave non nasce dalla password a ogni file. La chiave madre si ricava una volta con PBKDF2 dalla
/// passphrase e dal sale dello spazio (`chiaveSpazio`), e ogni file ha la sua chiave: HKDF della chiave madre con il sale
/// casuale dell'intestazione e l'uso del file («PrismaOV v1 · istantanea», «… · giornale <dispositivo>»). Il campo delle
/// iterazioni vale 0. I backup dell'algoritmo 1 si aprono come prima; un file dell'algoritmo 2 non si apre come backup.
enum CifraturaBackup {
    static let magia = Data("PRISMACF".utf8)
    static let versione: UInt8 = 1
    /// 1 = PBKDF2-HMAC-SHA256 + AES-256-GCM a segmenti.
    static let algoritmo: UInt8 = 1
    /// 2 = chiave dello spazio di Prisma ovunque (chiave madre già derivata, HKDF per file) + AES-256-GCM a segmenti.
    static let algoritmoSpazio: UInt8 = 2
    /// Le iterazioni dell'app (la prova ne può chiedere meno, solo per la durata).
    static let iterazioniPredefinite: UInt32 = 600_000
    static let dimensioneSegmento = 1 << 20
    static let lunghezzaSale = 16
    static let lunghezzaVerifica = 16
    static let lunghezzaIntestazione = 8 + 1 + 1 + 4 + 16 + 4 + 16
    /// Nonce (12) + etichetta (16) che ogni segmento aggiunge ai suoi dati.
    static let aggiuntaSegmento = 12 + 16

    private static let lunghezzaChiave = 32
    /// Limiti per un'intestazione rovinata (un numero enorme bloccherebbe Prisma).
    private static let iterazioniMassime: UInt32 = 10_000_000
    private static let segmentoMassimo = 16 << 20
    private static let testoVerifica = Data("Prisma · verifica della password dei backup".utf8)

    // MARK: - Riconoscimento

    /// true se il file è un backup protetto: si riconosce dal contenuto (la firma iniziale), non
    /// dall'estensione. Gli zip in chiaro cominciano con «PK».
    static func cifrato(_ url: URL) -> Bool {
        guard let lettura = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? lettura.close() }
        guard let inizio = try? lettura.read(upToCount: magia.count) else { return false }
        return inizio == magia
    }

    /// Le iterazioni scritte nell'intestazione di un backup protetto (nil se non lo è).
    static func iterazioni(in url: URL) -> UInt32? {
        guard let lettura = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? lettura.close() }
        guard let dati = try? leggi(lettura, lunghezzaIntestazione),
              let intestazione = try? Intestazione(dati) else { return nil }
        return intestazione.iterazioni
    }

    // MARK: - Cifratura

    /// Cifra il file `chiaro` in `destinazione` (che viene sostituita).
    static func cifra(_ chiaro: URL, in destinazione: URL, password: String,
                      iterazioni: UInt32 = iterazioniPredefinite) throws {
        guard !password.isEmpty else { throw ErroreBackup.passwordNonDisponibile }
        guard iterazioni > 0, iterazioni <= iterazioniMassime else { throw ErroreBackup.cifratura("numero di iterazioni non valido") }
        let sale = try casuali(lunghezzaSale)
        let chiave = try derivaChiave(password: password, sale: sale, iterazioni: iterazioni)
        let chiaveDati = sottochiave(chiave, uso: usoCifratura)
        let intestazione = Intestazione(iterazioni: iterazioni, sale: sale, segmento: dimensioneSegmento,
                                        verifica: verifica(chiave))
        let fm = FileManager.default
        try? fm.removeItem(at: destinazione)
        guard fm.createFile(atPath: destinazione.path, contents: nil) else {
            throw ErroreBackup.cifratura("il file del backup non si può creare")
        }
        let lettura = try FileHandle(forReadingFrom: chiaro)
        defer { try? lettura.close() }
        let scrittura = try FileHandle(forWritingTo: destinazione)
        defer { try? scrittura.close() }

        try scrittura.write(contentsOf: intestazione.byte)
        var corrente = try leggi(lettura, dimensioneSegmento)
        var indice: UInt64 = 0
        while true {
            // Si legge il segmento dopo prima di cifrare questo: così si sa se è l'ultimo
            let prossimo: Data
            if corrente.count < dimensioneSegmento {
                prossimo = Data()
            } else {
                prossimo = try leggi(lettura, dimensioneSegmento)
            }
            let ultimo = prossimo.isEmpty
            let associati = datiAssociati(intestazione.byte, indice: indice, ultimo: ultimo)
            try autoreleasepool {
                let scatola = try AES.GCM.seal(corrente, using: chiaveDati, nonce: AES.GCM.Nonce(), authenticating: associati)
                guard let unito = scatola.combined else { throw ErroreBackup.cifratura("segmento non cifrato") }
                try scrittura.write(contentsOf: byte(UInt32(unito.count)))
                try scrittura.write(contentsOf: unito)
            }
            if ultimo { break }
            corrente = prossimo
            indice += 1
        }
        try scrittura.synchronize()
    }

    // MARK: - Decifratura

    /// Decifra il backup protetto `cifrato` nello zip `destinazione` (che viene sostituita).
    /// Password sbagliata → `.passwordErrata`; file alterato, troncato o riordinato → `.backupDanneggiato`.
    /// Se qualcosa non torna la destinazione viene cancellata: niente dati non autenticati in giro.
    static func decifra(_ cifrato: URL, in destinazione: URL, password: String) throws {
        let fm = FileManager.default
        let lettura = try FileHandle(forReadingFrom: cifrato)
        defer { try? lettura.close() }
        let intestazione = try Intestazione(leggi(lettura, lunghezzaIntestazione))
        // Un file di Prisma ovunque (algoritmo 2) non è un backup: non si apre con la password
        guard intestazione.algoritmo == algoritmo else { throw ErroreBackup.archivioMancante }
        guard intestazione.iterazioni > 0, intestazione.iterazioni <= iterazioniMassime,
              intestazione.segmento > 0, intestazione.segmento <= segmentoMassimo else {
            throw ErroreBackup.backupDanneggiato
        }
        let chiave = try derivaChiave(password: password, sale: intestazione.sale, iterazioni: intestazione.iterazioni)
        guard verifica(chiave) == intestazione.verifica else { throw ErroreBackup.passwordErrata }
        let chiaveDati = sottochiave(chiave, uso: usoCifratura)

        try? fm.removeItem(at: destinazione)
        guard fm.createFile(atPath: destinazione.path, contents: nil) else {
            throw ErroreBackup.cifratura("il file temporaneo non si può creare")
        }
        do {
            let scrittura = try FileHandle(forWritingTo: destinazione)
            defer { try? scrittura.close() }
            let massimo = intestazione.segmento + aggiuntaSegmento
            var corrente = try leggiSegmento(lettura, massimo: massimo)
            guard corrente != nil else { throw ErroreBackup.backupDanneggiato }
            var indice: UInt64 = 0
            while let segmento = corrente {
                // Il segmento dopo dice se questo è l'ultimo (un file troncato non torna)
                let prossimo = try leggiSegmento(lettura, massimo: massimo)
                let associati = datiAssociati(intestazione.byte, indice: indice, ultimo: prossimo == nil)
                try autoreleasepool {
                    let chiaro: Data
                    do {
                        let scatola = try AES.GCM.SealedBox(combined: segmento)
                        chiaro = try AES.GCM.open(scatola, using: chiaveDati, authenticating: associati)
                    } catch {
                        throw ErroreBackup.backupDanneggiato
                    }
                    try scrittura.write(contentsOf: chiaro)
                }
                corrente = prossimo
                indice += 1
            }
        } catch {
            try? fm.removeItem(at: destinazione)
            throw error
        }
    }

    // MARK: - Algoritmo 2: chiave dello spazio (Prisma ovunque)

    /// La chiave madre dello spazio: PBKDF2-HMAC-SHA256 della passphrase (normalizzata) con il sale dello spazio.
    /// Si calcola una volta per sessione; poi la si tiene nel Portachiavi del dispositivo (`PortachiaviOvunque`).
    static func chiaveSpazio(passphrase: String, sale: Data, iterazioni: UInt32) throws -> SymmetricKey {
        guard !passphrase.isEmpty else { throw ErroreBackup.passwordNonDisponibile }
        guard iterazioni > 0, iterazioni <= iterazioniMassime, sale.count == lunghezzaSale else {
            throw ErroreBackup.cifratura("parametri dello spazio non validi")
        }
        return try derivaChiave(password: passphrase, sale: sale, iterazioni: iterazioni)
    }

    /// L'impronta della chiave madre scritta in chiaro nel descrittore dello spazio: riconosce la passphrase sbagliata
    /// senza aprire nessun file. Non rivela la chiave (HMAC con una sottochiave dedicata).
    static func verificaSpazio(_ madre: SymmetricKey) -> Data {
        let codice = HMAC<SHA256>.authenticationCode(for: testoVerificaSpazio, using: sottochiave(madre, uso: usoVerificaSpazio))
        let tutto = codice.withUnsafeBytes { Data($0) }
        return Data(tutto.prefix(lunghezzaVerifica))
    }

    /// Cifra `chiaro` con la chiave madre dello spazio per l'uso `uso` (algoritmo 2). Il risultato è un file «PRISMACF»
    /// completo: intestazione, poi i segmenti da 1 MiB autenticati come nei backup.
    static func cifra(_ chiaro: Data, chiave madre: SymmetricKey, uso: String) throws -> Data {
        let sale = try casuali(lunghezzaSale)
        let chiaveFile = chiaveDelFile(madre, uso: uso, sale: sale)
        let intestazione = Intestazione(iterazioni: 0, sale: sale, segmento: dimensioneSegmento, verifica: verifica(chiaveFile),
                                        algoritmo: algoritmoSpazio)
        let chiaveDati = sottochiave(chiaveFile, uso: usoCifratura)
        let byteChiari = [UInt8](chiaro)
        var uscita = intestazione.byte
        var inizio = 0
        var indice: UInt64 = 0
        repeat {
            let fine = min(inizio + dimensioneSegmento, byteChiari.count)
            let ultimo = fine >= byteChiari.count
            let associati = datiAssociati(intestazione.byte, indice: indice, ultimo: ultimo)
            let scatola = try AES.GCM.seal(Data(byteChiari[inizio..<fine]), using: chiaveDati, nonce: AES.GCM.Nonce(),
                                           authenticating: associati)
            guard let unito = scatola.combined else { throw ErroreBackup.cifratura("segmento non cifrato") }
            uscita.append(byte(UInt32(unito.count)))
            uscita.append(unito)
            inizio = fine
            indice += 1
        } while inizio < byteChiari.count
        return uscita
    }

    /// Decifra un file dell'algoritmo 2. Chiave o uso sbagliati → `.passwordErrata`; file alterato, troncato o riordinato
    /// → `.backupDanneggiato`; un backup dell'algoritmo 1 non è un file dello spazio → `.backupDanneggiato`.
    static func decifra(_ cifrato: Data, chiave madre: SymmetricKey, uso: String) throws -> Data {
        let b = [UInt8](cifrato)
        guard b.count > lunghezzaIntestazione else { throw ErroreBackup.backupDanneggiato }
        let intestazione = try Intestazione(Data(b[0..<lunghezzaIntestazione]))
        guard intestazione.algoritmo == algoritmoSpazio, intestazione.segmento > 0, intestazione.segmento <= segmentoMassimo else {
            throw ErroreBackup.backupDanneggiato
        }
        let chiaveFile = chiaveDelFile(madre, uso: uso, sale: intestazione.sale)
        guard verifica(chiaveFile) == intestazione.verifica else { throw ErroreBackup.passwordErrata }
        let chiaveDati = sottochiave(chiaveFile, uso: usoCifratura)
        let massimo = intestazione.segmento + aggiuntaSegmento
        var chiaro = Data()
        var posizione = lunghezzaIntestazione
        var indice: UInt64 = 0
        while posizione < b.count {
            guard b.count - posizione >= 4 else { throw ErroreBackup.backupDanneggiato }
            let lunghezza = Int(numero(b[posizione..<(posizione + 4)]))
            posizione += 4
            guard lunghezza >= aggiuntaSegmento, lunghezza <= massimo, b.count - posizione >= lunghezza else {
                throw ErroreBackup.backupDanneggiato
            }
            let segmento = Data(b[posizione..<(posizione + lunghezza)])
            posizione += lunghezza
            // Il segno «ultimo» autenticato: un file troncato dopo un segmento intero non torna
            let associati = datiAssociati(intestazione.byte, indice: indice, ultimo: posizione >= b.count)
            do {
                let scatola = try AES.GCM.SealedBox(combined: segmento)
                let aperto = try AES.GCM.open(scatola, using: chiaveDati, authenticating: associati)
                chiaro.append(aperto)
            } catch {
                throw ErroreBackup.backupDanneggiato
            }
            indice += 1
        }
        return chiaro
    }

    /// La chiave di un file dello spazio: HKDF della chiave madre con il sale del file e il suo uso.
    private static func chiaveDelFile(_ madre: SymmetricKey, uso: String, sale: Data) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(inputKeyMaterial: madre, salt: sale, info: Data(uso.utf8), outputByteCount: lunghezzaChiave)
    }

    private static let usoVerificaSpazio = Data("PrismaOV v1 · verifica".utf8)
    private static let testoVerificaSpazio = Data("Prisma ovunque · verifica della passphrase dello spazio".utf8)

    // MARK: - Parti

    private struct Intestazione {
        let algoritmo: UInt8
        let iterazioni: UInt32
        let sale: Data
        let segmento: Int
        let verifica: Data
        /// I byte dell'intestazione, autenticati con ogni segmento.
        let byte: Data

        init(iterazioni: UInt32, sale: Data, segmento: Int, verifica: Data, algoritmo: UInt8 = CifraturaBackup.algoritmo) {
            self.algoritmo = algoritmo
            self.iterazioni = iterazioni
            self.sale = sale
            self.segmento = segmento
            self.verifica = verifica
            var b = CifraturaBackup.magia
            b.append(contentsOf: [CifraturaBackup.versione, algoritmo])
            b.append(CifraturaBackup.byte(iterazioni))
            b.append(sale)
            b.append(CifraturaBackup.byte(UInt32(segmento)))
            b.append(verifica)
            byte = b
        }

        init(_ dati: Data) throws {
            let b = [UInt8](dati)
            guard b.count == CifraturaBackup.lunghezzaIntestazione, Data(b[0..<8]) == CifraturaBackup.magia else {
                throw ErroreBackup.backupDanneggiato
            }
            // Un formato che questa versione non conosce: lo apre una versione più recente di Prisma
            guard b[8] == CifraturaBackup.versione,
                  b[9] == CifraturaBackup.algoritmo || b[9] == CifraturaBackup.algoritmoSpazio else {
                throw ErroreBackup.versionePiuRecente
            }
            algoritmo = b[9]
            iterazioni = CifraturaBackup.numero(b[10..<14])
            sale = Data(b[14..<30])
            segmento = Int(CifraturaBackup.numero(b[30..<34]))
            verifica = Data(b[34..<50])
            byte = Data(b)
        }
    }

    /// PBKDF2-HMAC-SHA256 (CommonCrypto) → chiave AES a 256 bit.
    private static func derivaChiave(password: String, sale: Data, iterazioni: UInt32) throws -> SymmetricKey {
        let testo = password.precomposedStringWithCanonicalMapping
        let lunghezza = testo.utf8.count
        let byteSale = [UInt8](sale)
        var derivata = [UInt8](repeating: 0, count: lunghezzaChiave)
        defer {
            for i in derivata.indices { derivata[i] = 0 }
        }
        let esito: Int32 = testo.withCString { pw in
            byteSale.withUnsafeBufferPointer { s in
                derivata.withUnsafeMutableBufferPointer { d in
                    CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), pw, lunghezza,
                                         s.baseAddress, s.count,
                                         CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), iterazioni,
                                         d.baseAddress, d.count)
                }
            }
        }
        guard esito == 0 else { throw ErroreBackup.cifratura("derivazione della chiave non riuscita") }
        return SymmetricKey(data: derivata)
    }

    /// Dalla chiave della password due chiavi separate (HKDF): una cifra i dati, l'altra fa l'impronta di verifica.
    private static let usoCifratura = Data("PrismaCF v1 · cifratura".utf8)
    private static let usoVerifica = Data("PrismaCF v1 · verifica".utf8)

    private static func sottochiave(_ chiave: SymmetricKey, uso: Data) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(inputKeyMaterial: chiave, info: uso, outputByteCount: lunghezzaChiave)
    }

    /// Un'impronta della chiave: distingue la password sbagliata da un file danneggiato.
    private static func verifica(_ chiave: SymmetricKey) -> Data {
        let codice = HMAC<SHA256>.authenticationCode(for: testoVerifica, using: sottochiave(chiave, uso: usoVerifica))
        let tutto = codice.withUnsafeBytes { Data($0) }
        return Data(tutto.prefix(lunghezzaVerifica))
    }

    /// Byte casuali dal generatore del sistema (anche per il sale dello spazio di Prisma ovunque).
    static func casuali(_ quanti: Int) throws -> Data {
        var b = [UInt8](repeating: 0, count: quanti)
        let esito = b.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, quanti, buffer.baseAddress!)
        }
        guard esito == errSecSuccess else { throw ErroreBackup.cifratura("generatore casuale non disponibile") }
        return Data(b)
    }

    private static func datiAssociati(_ intestazione: Data, indice: UInt64, ultimo: Bool) -> Data {
        var d = intestazione
        d.append(byte(indice))
        d.append(contentsOf: [ultimo ? UInt8(1) : UInt8(0)])
        return d
    }

    /// Legge fino a `quanti` byte (meno solo alla fine del file).
    private static func leggi(_ lettura: FileHandle, _ quanti: Int) throws -> Data {
        var dati = Data()
        while dati.count < quanti {
            guard let pezzo = try lettura.read(upToCount: quanti - dati.count), !pezzo.isEmpty else { break }
            dati.append(pezzo)
        }
        return dati
    }

    /// Il prossimo segmento (lunghezza + dati), nil alla fine del file.
    private static func leggiSegmento(_ lettura: FileHandle, massimo: Int) throws -> Data? {
        let testa = try leggi(lettura, 4)
        if testa.isEmpty { return nil }
        guard testa.count == 4 else { throw ErroreBackup.backupDanneggiato }
        let lunghezza = Int(numero(testa))
        guard lunghezza >= aggiuntaSegmento, lunghezza <= massimo else { throw ErroreBackup.backupDanneggiato }
        let segmento = try leggi(lettura, lunghezza)
        guard segmento.count == lunghezza else { throw ErroreBackup.backupDanneggiato }
        return segmento
    }

    /// Un intero in byte big-endian.
    static func byte<T: FixedWidthInteger>(_ valore: T) -> Data {
        let quanti = T.bitWidth / 8
        return Data((0..<quanti).reversed().map { UInt8(truncatingIfNeeded: valore >> ($0 * 8)) })
    }

    /// Un UInt32 da byte big-endian.
    static func numero<S: Sequence>(_ byte: S) -> UInt32 where S.Element == UInt8 {
        byte.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }
}
