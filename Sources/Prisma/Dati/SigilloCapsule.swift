import CryptoKit
import Foundation

// Il sigillo delle capsule del tempo («Luce» giro 15, §3.4, decisioni 41 e 42): il testo del cliente si cifra con
// `CifraturaBackup` algoritmo 2 (una chiave per capsula con HKDF dalla chiave delle capsule, AES-256-GCM a segmenti).
// L'uso della sottochiave porta l'id del cliente e della capsula: una capsula spostata su un altro cliente non si apre.
// La chiave delle capsule è a parte (`PortachiaviCapsule`): mai quella di Prisma ovunque né una sua derivata. Il testo in
// chiaro non si scrive mai su disco, non va nei log, non passa da Vera e non entra nella ricerca.

enum SigilloCapsule {
    /// Versione del formato del sigillo (`CapsulaTempo.schemaSigillo`).
    static let schema = 1

    /// L'uso della sottochiave: una capsula non si sposta su un altro cliente (né cambia id).
    static func uso(clienteId: String, id: String) -> String { "capsula:\(clienteId):\(id)" }

    /// Quale chiave dell'anello: i primi 8 byte dello SHA-256 della chiave, in esadecimale (non rivela la chiave).
    static func chiaveId(_ chiave: SymmetricKey) -> String {
        let byte = chiave.withUnsafeBytes { Data($0) }
        let impronta = SHA256.hash(data: byte)
        return impronta.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    /// Cifra il testo della capsula. Il risultato va in `CapsulaTempo.sigillo`.
    static func sigilla(_ testo: String, id: String, clienteId: String, chiave: SymmetricKey) throws -> Data {
        try CifraturaBackup.cifra(Data(testo.utf8), chiave: chiave, uso: uso(clienteId: clienteId, id: id))
    }

    /// Decifra il testo (solo in memoria). Chiave sbagliata o capsula spostata → `ErroreBackup.passwordErrata`;
    /// sigillo rovinato → `ErroreBackup.backupDanneggiato`.
    static func apri(_ c: CapsulaTempo, chiave: SymmetricKey) throws -> String {
        let chiaro = try CifraturaBackup.decifra(c.sigillo, chiave: chiave, uso: uso(clienteId: c.clienteId, id: c.id))
        guard let testo = String(data: chiaro, encoding: .utf8) else { throw ErroreBackup.backupDanneggiato }
        return testo
    }

    /// La chiave delle capsule di prova (DATI DI PROVA DICHIARATI): scritta nel codice pubblico, non è un segreto e non
    /// apre capsule vere. Vale solo per le capsule con `diProva == true` dei clienti di prova.
    static let chiaveDiProva = SymmetricKey(data: SHA256.hash(data: Data("Prisma · capsule di prova · non segreta".utf8)))

    static var chiaveIdDiProva: String { chiaveId(chiaveDiProva) }
}
