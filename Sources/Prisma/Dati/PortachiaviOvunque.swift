import Foundation
import Security

/// La chiave madre dello spazio di Prisma ovunque (32 byte, non la passphrase) nel Portachiavi del dispositivo.
/// Mai nell'archivio né nelle impostazioni: l'archivio finisce nei backup e nell'istantanea.
/// - Mac: Portachiavi di login, come `PortachiaviBackup` (servizio «Prisma ovunque»). Niente portachiavi «data protection»:
///   con la firma ad-hoc darebbe -34018. Dopo un aggiornamento di Prisma il Mac può chiedere una volta il permesso.
/// - iPhone e iPad: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, non sincronizzabile: non va nel backup iCloud né su
///   altri dispositivi e si legge solo a dispositivo sbloccato. Dopo una reinstallazione si riscrive la passphrase.
/// Se la chiave non apre più lo spazio (passphrase cambiata sul Mac) la verifica del descrittore lo dice.
/// Le prove non lo usano mai (la chiave si passa direttamente).
enum PortachiaviOvunque {
    static let servizio = "Prisma ovunque"
    static let conto = "chiave dello spazio"
    static let etichetta = "Prisma – chiave di Prisma ovunque"

    private static var ricerca: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: servizio,
         kSecAttrAccount as String: conto]
    }

    /// Salva (o sostituisce) la chiave. false se il Portachiavi non l'ha accettata.
    @discardableResult
    static func salva(_ chiave: Data) -> Bool {
        guard !chiave.isEmpty else { return false }
        let modifica: [String: Any] = [kSecValueData as String: chiave]
        let aggiornata = SecItemUpdate(ricerca as CFDictionary, modifica as CFDictionary)
        if aggiornata == errSecSuccess { return true }
        if aggiornata != errSecItemNotFound { _ = SecItemDelete(ricerca as CFDictionary) }
        var nuova = ricerca
        nuova[kSecValueData as String] = chiave
        nuova[kSecAttrLabel as String] = etichetta
        #if os(macOS)
        // Portachiavi di login: nessun attributo di accessibilità (porterebbe al portachiavi «data protection»)
        #elseif os(iOS)
        nuova[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        nuova[kSecAttrSynchronizable as String] = false
        #endif
        return SecItemAdd(nuova as CFDictionary, nil) == errSecSuccess
    }

    /// La chiave salvata (nil se non c'è o se il dispositivo non ne ha dato il permesso).
    static func leggi() -> Data? {
        var domanda = ricerca
        domanda[kSecReturnData as String] = true
        domanda[kSecMatchLimit as String] = kSecMatchLimitOne
        var risultato: CFTypeRef?
        guard SecItemCopyMatching(domanda as CFDictionary, &risultato) == errSecSuccess,
              let dati = risultato as? Data, !dati.isEmpty else { return nil }
        return dati
    }

    static func elimina() {
        _ = SecItemDelete(ricerca as CFDictionary)
    }
}
