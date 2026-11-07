import Foundation
import Security

/// La chiave della memoria di Vera (32 byte casuali: ricordi, lezioni, riassunti e la cache dei vettori) nel Portachiavi
/// del dispositivo, come la chiave di «Prisma ovunque» (`PortachiaviOvunque`): mai nell'archivio né nelle impostazioni.
/// Nel backup va solo cifrata con la password dei backup (Vera/chiave-memoria.cifrato, MemoriaVera.avvolgi).
/// Le prove non lo usano mai (la chiave si passa direttamente).
enum PortachiaviMemoria {
    static let servizio = "Prisma memoria di Vera"
    static let conto = "chiave della memoria"
    static let etichetta = "Prisma – chiave della memoria di Vera"

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
