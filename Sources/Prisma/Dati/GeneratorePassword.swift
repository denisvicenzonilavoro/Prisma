import Foundation

// La password delle cose date al cliente («Luce» giro 15, decisione 4): tre parole e un numero («Lago-Vela-Pino-27»,
// 2048³ × 90 ≈ 7,7 × 10¹¹ combinazioni con l'elenco minimo), facile da dettare a voce. Una proposta nuova a ogni file;
// scritta a mano almeno 12 caratteri, mai con nome, cognome, data di nascita o codice fiscale del cliente. Mai conservata
// e mai nel testo del messaggio che accompagna il file. Le parole stanno in `Risorse/PrismaCliente/parole.txt`: nomi
// comuni neutri scritti per Prisma (nessun dato), solo a-z senza accenti, 4-7 lettere, una per riga.
enum GeneratorePassword {
    static let fileParole = "PrismaCliente/parole.txt"
    static let paroleMinime = 2048
    static let lunghezzaMinimaAMano = 12
    /// Il numero in fondo: da 10 a 99 (90 valori, sempre due cifre).
    static let numeri = 10...99

    /// Le parole del pacchetto (lette una volta).
    static var parole: [String] { caricate }

    private static let caricate: [String] = {
        guard let url = Risorse.cartella?.appendingPathComponent(fileParole),
              let testo = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return leggi(testo)
    }()

    /// Le righe valide di un elenco (minuscole, solo a-z, 4-7 lettere), senza doppioni, nell'ordine del file.
    static func leggi(_ testo: String) -> [String] {
        var viste = Set<String>()
        var esito: [String] = []
        for riga in testo.split(whereSeparator: \.isNewline) {
            let p = riga.trimmingCharacters(in: .whitespaces)
            guard valida(p), viste.insert(p).inserted else { continue }
            esito.append(p)
        }
        return esito
    }

    /// Una parola ammessa nell'elenco.
    static func valida(_ p: String) -> Bool {
        (4...7).contains(p.count) && p.unicodeScalars.allSatisfy { $0.value >= 97 && $0.value <= 122 }
    }

    /// Una proposta nuova: tre parole a caso (uniformi) con l'iniziale maiuscola e un numero di due cifre, separati da «-».
    /// Con il cliente si ripete finché la proposta non va bene per lui (una parola può coincidere con un nome: «rosa»).
    static func nuova(parole: [String] = parole, cliente: Cliente? = nil) -> String {
        var proposta = una(parole)
        var tentativi = 0
        while motivoNonValida(proposta, cliente: cliente) != nil && tentativi < 100 {
            proposta = una(parole)
            tentativi += 1
        }
        return proposta
    }

    private static func una(_ parole: [String]) -> String {
        let elenco = parole.count >= 3 ? parole : riserva
        let tre = (0..<3).map { _ in elenco[uniforme(elenco.count)].capitalized }
        let numero = numeri.lowerBound + uniforme(numeri.count)
        return (tre + [String(numero)]).joined(separator: "-")
    }

    /// Solo se l'elenco del pacchetto non si legge (la verifica delle risorse lo segnala): sillabe a caso, mai una
    /// password vuota.
    private static var riserva: [String] {
        let consonanti = Array("bcdfglmnprstv")
        let vocali = Array("aeiou")
        return (0..<64).map { _ in
            String((0..<3).flatMap { _ in [consonanti[uniforme(consonanti.count)], vocali[uniforme(vocali.count)]] })
        }
    }

    /// Un intero uniforme in 0..<n da 4 byte casuali del sistema (`CifraturaBackup.casuali`), con il rifiuto dei valori
    /// oltre l'ultimo multiplo di n (niente sbilanciamento del modulo).
    static func uniforme(_ n: Int) -> Int {
        guard n > 1 else { return 0 }
        let limite = UInt64(UInt32.max) + 1
        let soglia = limite - (limite % UInt64(n))
        for _ in 0..<64 {
            guard let b = try? CifraturaBackup.casuali(4), b.count == 4 else { break }
            let v = b.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            if v < soglia { return Int(v % UInt64(n)) }
        }
        var generatore = SystemRandomNumberGenerator()
        return Int.random(in: 0..<n, using: &generatore)
    }

    /// Perché una password non va bene (nil = va bene): almeno 12 caratteri; mai il nome o il cognome del cliente (parti
    /// di almeno 3 lettere, senza accenti e maiuscole), la sua data di nascita (ggmmaaaa, gg/mm/aaaa o l'anno) o il
    /// codice fiscale.
    static func motivoNonValida(_ p: String, cliente: Cliente?) -> String? {
        let pulita = p.trimmingCharacters(in: .whitespacesAndNewlines)
        if pulita.count < lunghezzaMinimaAMano {
            return "Almeno \(lunghezzaMinimaAMano) caratteri"
        }
        guard let c = cliente else { return nil }
        let piegata = piega(pulita)
        let parti = c.nome.split(whereSeparator: { !$0.isLetter }).map { piega(String($0)) }.filter { $0.count >= 3 }
        if parti.contains(where: { piegata.contains($0) }) {
            return "Senza il nome o il cognome del cliente"
        }
        if let nascita = c.dataNascita {
            let cifre = String(pulita.filter(\.isNumber))
            let k = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: nascita)
            if let a = k.year, let m = k.month, let g = k.day {
                let anno = String(format: "%04d", a)
                let intera = String(format: "%02d%02d%04d", g, m, a)
                if cifre.contains(intera) || pulita.contains(anno) {
                    return "Senza la data di nascita del cliente"
                }
            }
        }
        let cf = c.codiceFiscale.uppercased().filter { $0.isLetter || $0.isNumber }
        if cf.count >= 6 && pulita.uppercased().filter({ $0.isLetter || $0.isNumber }).contains(cf) {
            return "Senza il codice fiscale del cliente"
        }
        return nil
    }

    private static func piega(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Formati.italiano).lowercased()
    }

    /// Per `Prisma --verifica-risorse`: nil = l'elenco c'è, ha abbastanza parole e tutte valide.
    static func verificaRisorse() -> String? {
        guard let url = Risorse.cartella?.appendingPathComponent(fileParole),
              let testo = try? String(contentsOf: url, encoding: .utf8) else {
            return "\(fileParole) non leggibile dal bundle"
        }
        let righe = testo.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let valide = leggi(testo)
        guard valide.count == righe.count else { return "\(fileParole): righe non valide o doppie" }
        guard valide.count >= paroleMinime else { return "\(fileParole): \(valide.count) parole, ne servono almeno \(paroleMinime)" }
        return nil
    }
}
