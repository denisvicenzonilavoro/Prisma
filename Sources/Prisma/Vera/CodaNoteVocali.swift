import CryptoKit
import Foundation
#if os(iOS)
import Security
#endif

/// Le «Note in partenza» dell'iPhone («Luce» giro 13, decisione 37): le note dettate quando il Mac non è raggiungibile
/// restano in una **coda cifrata sul telefono** (AES-GCM con una chiave del Portachiavi del dispositivo, non
/// sincronizzabile), in una cartella esclusa dal backup di iCloud, con la protezione dei file del sistema; ogni nota esce
/// dalla coda appena il Mac risponde «accettata». Al più 20 note: oltre, la nuova non entra (mai una vecchia persa in
/// silenzio). Il giornale di «Prisma ovunque» non si usa (serve un sì esplicito dell'utente). Senza `#if`: la prova gira
/// anche sul Mac.
struct CodaNoteVocali {
    static let massimo = 20
    static let nomeFile = "note-in-partenza.cifrato"
    static let nomeCartella = "NoteInPartenza"

    /// La cartella apposita (esclusa dal backup) e la chiave.
    let cartella: URL
    let chiave: SymmetricKey

    /// Una nota in coda, con i tentativi e l'ultimo motivo.
    struct VoceCoda: Codable, Equatable, Identifiable {
        var nota: NotaVocalePonte
        var tentativi: Int
        var ultimoMotivo: String?
        var id: String { nota.id }

        init(nota: NotaVocalePonte, tentativi: Int = 0, ultimoMotivo: String? = nil) {
            self.nota = nota
            self.tentativi = tentativi
            self.ultimoMotivo = ultimoMotivo
        }
    }

    var file: URL { cartella.appendingPathComponent(Self.nomeFile) }

    /// Le note in coda (vuoto se il file manca o non si apre con questa chiave).
    func leggi() -> [VoceCoda] {
        guard let cifrato = try? Data(contentsOf: file),
              let scatola = try? AES.GCM.SealedBox(combined: cifrato),
              let chiaro = try? AES.GCM.open(scatola, using: chiave),
              let voci = try? JSONDecoder().decode([VoceCoda].self, from: chiaro) else { return [] }
        return voci
    }

    /// Scrive la coda cifrata, con la scrittura atomica (temporaneo e rinomina): la cartella resta esclusa dal backup e,
    /// su iOS, il file nuovo nasce con la protezione «fino al primo sblocco».
    func scrivi(_ voci: [VoceCoda]) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: cartella, withIntermediateDirectories: true)
        var valori = URLResourceValues()
        valori.isExcludedFromBackup = true
        var c = cartella
        try c.setResourceValues(valori)
        let chiaro = try JSONEncoder().encode(Array(voci.prefix(Self.massimo)))
        guard let cifrato = try AES.GCM.seal(chiaro, using: chiave).combined else { return }
        #if os(iOS)
        try cifrato.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try cifrato.write(to: file, options: [.atomic])
        #endif
        // Anche il file nuovo, per sicurezza (la rinoma della scrittura atomica non tiene gli attributi del vecchio)
        var f = file
        try? f.setResourceValues(valori)
    }

    /// Aggiunge una nota: la stessa (stesso id) non si raddoppia; oltre 20 la nuova non entra (`tolta` = non entrata).
    static func aggiungi(_ n: NotaVocalePonte, a voci: [VoceCoda]) -> (voci: [VoceCoda], tolta: Bool) {
        if voci.contains(where: { $0.id == n.id }) { return (voci, false) }
        guard voci.count < massimo else { return (voci, true) }
        return (voci + [VoceCoda(nota: n)], false)
    }

    /// Dopo una ricevuta del Mac: «accettata» toglie la nota; un altro motivo la lascia con il motivo e un tentativo in più.
    static func dopoRicevuta(_ r: RicevutaPonte, id: String, voci: [VoceCoda]) -> [VoceCoda] {
        if r.accettato { return voci.filter { $0.id != id } }
        return voci.map { v in
            guard v.id == id else { return v }
            var x = v
            x.tentativi += 1
            x.ultimoMotivo = r.motivo
            return x
        }
    }

    /// La cartella della coda nel contenitore dell'app (Application Support/NoteInPartenza).
    static func cartellaPredefinita() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(nomeCartella, isDirectory: true)
    }
}

#if os(iOS)
/// La chiave della coda nel Portachiavi dell'iPhone: creata al primo uso, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`,
/// non sincronizzabile (non va nel backup né su altri dispositivi). Modello: `PortachiaviOvunque`.
enum PortachiaviNoteVocali {
    static let servizio = "Prisma note vocali"
    static let conto = "chiave della coda"

    private static var ricerca: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: servizio,
         kSecAttrAccount as String: conto]
    }

    /// La chiave (creata e salvata la prima volta). Nil se il Portachiavi non risponde.
    static func chiave() -> SymmetricKey? {
        var domanda = ricerca
        domanda[kSecReturnData as String] = true
        domanda[kSecMatchLimit as String] = kSecMatchLimitOne
        var risultato: CFTypeRef?
        if SecItemCopyMatching(domanda as CFDictionary, &risultato) == errSecSuccess, let d = risultato as? Data, d.count == 32 {
            return SymmetricKey(data: d)
        }
        let nuova = SymmetricKey(size: .bits256)
        let dati = nuova.withUnsafeBytes { Data($0) }
        _ = SecItemDelete(ricerca as CFDictionary)
        var elemento = ricerca
        elemento[kSecValueData as String] = dati
        elemento[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        elemento[kSecAttrSynchronizable as String] = false
        guard SecItemAdd(elemento as CFDictionary, nil) == errSecSuccess else { return nil }
        return nuova
    }
}
#endif

/// Prova della coda («Luce» giro 13, §4.2 punto 7), dentro `ProvaNotaVocale` (Mac e simulatore iOS): scrivi e leggi
/// uguale; il file non contiene il testo in chiaro; con un'altra chiave non si apre; la 21ª nota non entra e non toglie
/// le vecchie; la cartella è esclusa dal backup; la ricevuta «accettata» toglie la nota, «Mac non trovato» la lascia.
enum ProvaCodaNoteVocali {
    static func esegui(_ controlla: (Bool, String) -> Void) {
        let fm = FileManager.default
        let radice = fm.temporaryDirectory.appendingPathComponent("Prisma-prova-coda-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: radice) }
        let cartella = radice.appendingPathComponent(CodaNoteVocali.nomeCartella, isDirectory: true)
        let chiave = SymmetricKey(size: .bits256)
        let coda = CodaNoteVocali(cartella: cartella, chiave: chiave)
        let n = NotaVocaleDiProva.ponte(quando: Date(timeIntervalSinceReferenceDate: 815_000_000), id: NotaVocaleDiProva.prefisso + "coda")
        var voci = CodaNoteVocali.aggiungi(n, a: []).voci
        do {
            try coda.scrivi(voci)
            try coda.scrivi(voci)
        } catch {
            return controlla(false, "Nota, coda: la coda cifrata non si scrive (\(error.localizedDescription))")
        }
        controlla(coda.leggi() == voci, "Nota, coda: la coda cifrata si scrive e si rilegge uguale")
        let byte = (try? Data(contentsOf: coda.file)) ?? Data()
        controlla(!byte.isEmpty && String(decoding: byte, as: UTF8.self).range(of: "Giulia") == nil
                  && byte.range(of: Data("Giulia".utf8)) == nil,
                  "Nota, coda: il file della coda non contiene il testo in chiaro")
        controlla(CodaNoteVocali(cartella: cartella, chiave: SymmetricKey(size: .bits256)).leggi().isEmpty,
                  "Nota, coda: con un'altra chiave la coda non si apre")
        let esclusa = (try? cartella.resourceValues(forKeys: [.isExcludedFromBackupKey]))?.isExcludedFromBackup == true
        controlla(esclusa, "Nota, coda: la cartella delle note in partenza è esclusa dal backup")
        var piene: [CodaNoteVocali.VoceCoda] = []
        for k in 0..<CodaNoteVocali.massimo {
            var x = n
            x.id = NotaVocaleDiProva.prefisso + "coda-\(k)"
            piene = CodaNoteVocali.aggiungi(x, a: piene).voci
        }
        var ventunesima = n
        ventunesima.id = NotaVocaleDiProva.prefisso + "coda-21"
        let oltre = CodaNoteVocali.aggiungi(ventunesima, a: piene)
        controlla(oltre.tolta && oltre.voci == piene && piene.count == CodaNoteVocali.massimo,
                  "Nota, coda: la 21ª nota non entra e non toglie nessuna vecchia")
        controlla(CodaNoteVocali.aggiungi(n, a: voci).voci.count == 1, "Nota, coda: la stessa nota non si raddoppia")
        let lasciata = CodaNoteVocali.dopoRicevuta(.rifiutata(PonteVera.macNonTrovato), id: n.id, voci: voci)
        controlla(lasciata.count == 1 && lasciata.first?.tentativi == 1 && RicevutaPonte.rifiutata(PonteVera.macNonTrovato).macIrraggiungibile,
                  "Nota, coda: con il Mac non raggiungibile la nota resta in coda")
        voci = CodaNoteVocali.dopoRicevuta(.accettata(), id: n.id, voci: lasciata)
        controlla(voci.isEmpty, "Nota, coda: la ricevuta «accettata» del Mac toglie la nota dalla coda")
    }
}
