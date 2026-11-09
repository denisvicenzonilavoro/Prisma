import CryptoKit
import Foundation

// Le chiavi delle capsule del tempo nei backup («Luce» giro 15, §3.4, decisione 42) dentro `Prisma --prova-backup`.
// Mai il Portachiavi: gli hook di `GestoreBackup` li imposta la prova con una chiave di prova, e alla fine tornano vuoti.
// - backup protetto: `chiavi-capsule.bin` entra nello zip cifrato, al ripristino la chiave torna all'hook e il file si
//   toglie dalla cartella estratta; dopo il ripristino la capsula si riapre con la chiave ritrovata;
// - backup in chiaro: il file non c'è (nemmeno il nome nello zip) e nessuna chiave si consegna;
// - nell'archivio su disco il testo della capsula non compare; senza la chiave la capsula è «non apribile».
// Dati di prova dichiarati (testo e chiave inventati per la prova).

/// Le chiavi consegnate dall'hook del ripristino durante la prova.
private final class ChiaviRitrovateProva {
    var chiavi: [Data] = []
}

extension ProvaBackup {
    /// Restituisce il motivo dell'errore (nil = tutto bene).
    static func provaCapsule(radice: URL) throws -> String? {
        let fm = FileManager.default
        let base = radice.appendingPathComponent("CapsuleNelBackup", isDirectory: true)
        let dati = base.appendingPathComponent("Prisma", isDirectory: true)
        let protetti = base.appendingPathComponent("Protetti", isDirectory: true)
        let inChiaro = base.appendingPathComponent("InChiaro", isDirectory: true)
        defer {
            try? fm.removeItem(at: base)
            GestoreBackup.chiaviCapsuleDaSalvare = { [] }
            GestoreBackup.chiaviCapsuleRitrovate = { _ in }
        }
        try fm.createDirectory(at: dati, withIntermediateDirectories: true)

        // Una capsula sigillata con una chiave di prova (non quella dei dati di prova: si vede che è la chiave del backup)
        let chiave = SymmetricKey(data: SHA256.hash(data: Data("Prisma · prova del backup delle capsule · non segreta".utf8)))
        let byteChiave = chiave.withUnsafeBytes { Data($0) }
        let testo = "Giulia, prova del backup: la chiave torna solo con la password. Numero di controllo 6271."
        let t0 = Date(timeIntervalSinceReferenceDate: 815_117_903)
        let sigillo = try SigilloCapsule.sigilla(testo, id: "capsula-prova-backup", clienteId: "giulia", chiave: chiave)
        let capsula = CapsulaTempo(id: "capsula-prova-backup", clienteId: "giulia", apertura: .data(t0.addingTimeInterval(86_400 * 731)),
                                   sigillataIl: t0, sigillo: sigillo, chiaveId: SigilloCapsule.chiaveId(chiave))
        var archivio = DatiPrisma.demo()
        archivio.capsule = [capsula]
        try Archivio.salva(archivio, in: dati)

        // Nell'archivio su disco c'è il sigillo, mai il testo
        let pezzi = ArchivioPezzi.cartellaPezzi(in: dati)
        let fileGiulia = pezzi.appendingPathComponent(ArchivioPezzi.nomeClienti, isDirectory: true)
            .appendingPathComponent(ArchivioPezzi.nomeFile(cliente: "giulia"))
        let suDisco = (try? String(contentsOf: fileGiulia, encoding: .utf8)) ?? ""
        guard suDisco.contains("capsula-prova-backup"), !suDisco.contains("Numero di controllo"), !suDisco.contains("prova del backup:") else {
            return "capsule: la capsula non è nel file del cliente o il testo compare in chiaro nell'archivio"
        }

        // Gli hook della prova (mai il Portachiavi)
        let ritrovate = ChiaviRitrovateProva()
        GestoreBackup.chiaviCapsuleDaSalvare = { [byteChiave] }
        GestoreBackup.chiaviCapsuleRitrovate = { ritrovate.chiavi.append(contentsOf: $0) }
        let password = "Capsula-Prova-Vela-37"

        // Backup protetto: la chiave dentro, ritrovata al ripristino e tolta dalla cartella estratta
        try fm.createDirectory(at: protetti, withIntermediateDirectories: true)
        let cifrato = try GestoreBackup.crea(sorgente: dati, destinazione: protetti, password: password, iterazioni: 1_000)
        let byteCifrato = try Data(contentsOf: cifrato)
        guard byteCifrato.range(of: Data(GestoreBackup.fileChiaviCapsule.utf8)) == nil, byteCifrato.range(of: byteChiave) == nil else {
            return "capsule: il nome o la chiave compaiono in chiaro nel backup protetto"
        }
        let aperto = try GestoreBackup.estrai(cifrato, password: password)
        defer { GestoreBackup.pulisciEstrazione(aperto.cartella) }
        guard ritrovate.chiavi == [byteChiave] else {
            return "capsule: la chiave non torna dal backup protetto (\(ritrovate.chiavi.count) chiavi ritrovate)"
        }
        guard !fm.fileExists(atPath: aperto.cartella.appendingPathComponent(GestoreBackup.fileChiaviCapsule).path) else {
            return "capsule: il file delle chiavi resta nella cartella estratta del backup protetto"
        }
        guard aperto.dati.capsule == [capsula] else { return "capsule: la capsula non torna uguale dal backup protetto" }
        let chiaveRitrovata = SymmetricKey(data: ritrovate.chiavi[0])
        guard let riaperta = try? SigilloCapsule.apri(aperto.dati.capsule[0], chiave: chiaveRitrovata), riaperta == testo else {
            return "capsule: dopo il ripristino la capsula non si riapre con la chiave ritrovata"
        }
        // Il ripristino vero: nella cartella dell'archivio il file delle chiavi non arriva
        let ripristinata = base.appendingPathComponent("Ripristino/Prisma", isDirectory: true)
        try GestoreBackup.sostituisci(cartellaDati: ripristinata, con: try GestoreBackup.estrai(cifrato, password: password).cartella)
        guard !fm.fileExists(atPath: ripristinata.appendingPathComponent(GestoreBackup.fileChiaviCapsule).path),
              Archivio.carica(in: ripristinata).dati.capsule == [capsula] else {
            return "capsule: il ripristino del backup protetto lascia il file delle chiavi o perde la capsula"
        }

        // Backup in chiaro con gli stessi hook: il file non entra e nessuna chiave si consegna
        ritrovate.chiavi = []
        try fm.createDirectory(at: inChiaro, withIntermediateDirectories: true)
        let chiaro = try GestoreBackup.crea(sorgente: dati, destinazione: inChiaro)
        let byteChiaro = try Data(contentsOf: chiaro)
        guard byteChiaro.range(of: Data(GestoreBackup.fileChiaviCapsule.utf8)) == nil, byteChiaro.range(of: byteChiave) == nil else {
            return "capsule: le chiavi sono entrate in un backup in chiaro"
        }
        let estratto = try GestoreBackup.estrai(chiaro)
        defer { GestoreBackup.pulisciEstrazione(estratto.cartella) }
        guard ritrovate.chiavi.isEmpty, estratto.dati.capsule == [capsula],
              !fm.fileExists(atPath: estratto.cartella.appendingPathComponent(GestoreBackup.fileChiaviCapsule).path) else {
            return "capsule: un backup in chiaro consegna chiavi o perde la capsula"
        }

        // Senza la chiave: «non apribile», e un'altra chiave non apre
        guard MotoreCapsule.stato(capsula, obiettivi: [], oggi: t0, chiavePresente: false) == .nonApribile,
              (try? SigilloCapsule.apri(capsula, chiave: SigilloCapsule.chiaveDiProva)) == nil else {
            return "capsule: senza la chiave la capsula non risulta «non apribile» o si apre con un'altra chiave"
        }

        // Gli hook tornano vuoti: un backup protetto fatto dopo non porta chiavi
        GestoreBackup.chiaviCapsuleDaSalvare = { [] }
        GestoreBackup.chiaviCapsuleRitrovate = { _ in }
        ritrovate.chiavi = []
        let dopo = try GestoreBackup.crea(sorgente: dati, destinazione: protetti, password: password, iterazioni: 1_000)
        let riletto = try GestoreBackup.estrai(dopo, password: password)
        GestoreBackup.pulisciEstrazione(riletto.cartella)
        guard ritrovate.chiavi.isEmpty else { return "capsule: con gli hook vuoti il backup protetto porta ancora chiavi" }
        return nil
    }
}
