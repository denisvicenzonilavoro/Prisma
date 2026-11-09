import CryptoKit
import Foundation
import Security

/// L'anello delle chiavi delle capsule del tempo («Luce» giro 15, §3.4, decisioni 41 e 42): chiavi casuali di 32 byte nel
/// Portachiavi del Mac, servizio «Prisma capsule», conto = `SigilloCapsule.chiaveId` della chiave. Ogni capsula ricorda
/// quale chiave l'ha sigillata (`CapsulaTempo.chiaveId`); si sigilla sempre con l'ultima creata.
/// - Mai la chiave di Prisma ovunque né una sua derivata: sono chiavi a parte, create qui.
/// - Mai nell'archivio né nelle impostazioni; nei backup **solo se protetti da password** (`CapsuleNelBackup`, dentro lo
///   zip cifrato), mai nel Portachiavi di iCloud: sul Mac il Portachiavi di login, come `PortachiaviOvunque` (niente
///   portachiavi «data protection»: con la firma ad-hoc darebbe -34018; gli elementi del Portachiavi di login non si
///   sincronizzano), su iPhone e iPad `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` e non sincronizzabile.
/// - Le prove non lo usano mai: le chiavi si passano direttamente (o con gli hook del backup impostati dalla prova).
enum PortachiaviCapsule {
    static let servizio = "Prisma capsule"
    static let etichetta = "Prisma – chiave delle capsule del tempo"
    static let lunghezza = 32

    private static var base: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: servizio]
    }

    /// L'ultima chiave creata (quella con cui si sigilla); nil se non ce n'è o il Portachiavi non risponde.
    static func attiva() -> SymmetricKey? {
        let voci = elementi()
        guard let ultima = voci.max(by: { $0.creata < $1.creata }) else { return nil }
        return SymmetricKey(data: ultima.dati)
    }

    /// L'ultima chiave, o una nuova se l'anello è vuoto. nil se il Portachiavi non l'accetta (allora non si sigilla).
    static func creaSeManca() -> SymmetricKey? {
        if let gia = attiva() { return gia }
        guard let casuali = try? CifraturaBackup.casuali(lunghezza) else { return nil }
        let chiave = SymmetricKey(data: casuali)
        guard salva(casuali, conto: SigilloCapsule.chiaveId(chiave)) else { return nil }
        return chiave
    }

    /// La chiave con quell'id (nil se su questo Mac non c'è).
    static func chiave(id: String) -> SymmetricKey? {
        var domanda = base
        domanda[kSecAttrAccount as String] = id
        domanda[kSecReturnData as String] = true
        domanda[kSecMatchLimit as String] = kSecMatchLimitOne
        var risultato: CFTypeRef?
        guard SecItemCopyMatching(domanda as CFDictionary, &risultato) == errSecSuccess,
              let dati = risultato as? Data, dati.count == lunghezza else { return nil }
        return SymmetricKey(data: dati)
    }

    /// Tutte le chiavi dell'anello (per i backup protetti).
    static func tutte() -> [Data] {
        elementi().sorted { $0.creata < $1.creata }.map(\.dati)
    }

    /// Aggiunge le chiavi ritrovate in un backup protetto (quelle già presenti restano come sono).
    static func aggiungi(_ chiavi: [Data]) {
        for dati in chiavi where dati.count == lunghezza {
            let id = SigilloCapsule.chiaveId(SymmetricKey(data: dati))
            if chiave(id: id) == nil { salva(dati, conto: id) }
        }
    }

    // MARK: Portachiavi

    @discardableResult
    private static func salva(_ dati: Data, conto: String) -> Bool {
        var nuova = base
        nuova[kSecAttrAccount as String] = conto
        nuova[kSecValueData as String] = dati
        nuova[kSecAttrLabel as String] = etichetta
        #if os(macOS)
        // Portachiavi di login: nessun attributo di accessibilità (porterebbe al portachiavi «data protection»)
        #elseif os(iOS)
        nuova[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        nuova[kSecAttrSynchronizable as String] = false
        #endif
        return SecItemAdd(nuova as CFDictionary, nil) == errSecSuccess
    }

    /// Gli elementi dell'anello con la data di creazione. Prima gli attributi di tutti (sul Mac il Portachiavi di login
    /// non restituisce i dati di più elementi insieme), poi la chiave di ciascuno.
    private static func elementi() -> [(dati: Data, creata: Date)] {
        var domanda = base
        domanda[kSecReturnAttributes as String] = true
        domanda[kSecMatchLimit as String] = kSecMatchLimitAll
        var risultato: CFTypeRef?
        guard SecItemCopyMatching(domanda as CFDictionary, &risultato) == errSecSuccess,
              let voci = risultato as? [[String: Any]] else { return [] }
        var elenco: [(dati: Data, creata: Date)] = []
        for v in voci {
            guard let conto = v[kSecAttrAccount as String] as? String, let k = chiave(id: conto) else { continue }
            let dati = k.withUnsafeBytes { Data($0) }
            let creata = v[kSecAttrCreationDate as String] as? Date ?? .distantPast
            elenco.append((dati: dati, creata: creata))
        }
        return elenco
    }
}

enum CapsuleNelBackup {
    /// All'avvio vero: le chiavi entrano nei backup protetti e tornano dal ripristino (decisione 42). Mai nelle prove.
    static func installa() {
        GestoreBackup.chiaviCapsuleDaSalvare = { PortachiaviCapsule.tutte() }
        GestoreBackup.chiaviCapsuleRitrovate = { PortachiaviCapsule.aggiungi($0) }
    }
}
