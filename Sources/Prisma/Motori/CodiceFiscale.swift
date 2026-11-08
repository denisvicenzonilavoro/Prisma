import Foundation

/// Il sesso anagrafico come lo scrive il codice fiscale (giorno + 40 per le donne) e la carta d'identità («F»/«M»).
/// Nome diverso da ogni tipo esistente: serve solo al controllo del codice fiscale e alla carta («Luce» giro 13).
enum SessoAnagrafico: String, Codable, Equatable {
    case femmina, maschio
}

/// Le parti del codice fiscale che si possono confrontare con i dati della persona senza tabelle esterne.
enum ParteCodiceFiscale: String, Equatable, CaseIterable {
    case cognome, nome, anno, mese, giorno, sesso, controllo

    /// Come si dice nella scheda («non torna con il cognome»). Anno, mese e giorno sono tutti «la data di nascita».
    var nome: String {
        switch self {
        case .cognome: return "il cognome"
        case .nome: return "il nome"
        case .anno, .mese, .giorno: return "la data di nascita"
        case .sesso: return "il sesso"
        case .controllo: return "il carattere di controllo"
        }
    }
}

/// L'esito del confronto fra un codice fiscale e i dati letti. Mai «corretto» da solo: Prisma dice cosa torna e cosa no.
enum CoerenzaCodiceFiscale: Equatable {
    /// Tutto torna, comune compreso (mai finché non c'è la tabella dei codici catastali: decisione 70).
    case coerente
    /// Tutto torna tranne il comune, che non si controlla: «✓ coerente (comune non controllato)».
    case coerenteSenzaComune
    /// Qualcosa non torna con i dati della persona: «non torna con …: controllalo».
    case diverso([ParteCodiceFiscale])
    /// Lunghezza, alfabeto, posizioni o carattere di controllo sbagliati.
    case formaNonValida
    /// Mancano nome, cognome o data di nascita: non si può confrontare.
    case nonVerificabile

    /// Le frasi esatte della scheda «Nuovo cliente».
    var testo: String {
        switch self {
        case .coerente: return "✓ coerente"
        case .coerenteSenzaComune: return "✓ coerente (comune non controllato)"
        case .diverso(let parti):
            var nomi: [String] = []
            for p in parti where !nomi.contains(p.nome) { nomi.append(p.nome) }
            let elenco: String
            if nomi.count <= 1 {
                elenco = nomi.first ?? "i dati letti"
            } else {
                elenco = nomi.dropLast().joined(separator: ", ") + " e " + (nomi.last ?? "")
            }
            return "non torna con \(elenco): controllalo"
        case .formaNonValida: return "non ha la forma di un codice fiscale: controllalo"
        case .nonVerificabile: return "da controllare: mancano i dati per confrontarlo"
        }
    }

    /// Vero quando la riga va guardata (segno arancio «!»).
    var daGuardare: Bool {
        switch self {
        case .coerente, .coerenteSenzaComune: return false
        case .diverso, .formaNonValida, .nonVerificabile: return true
        }
    }
}

/// Il codice fiscale delle persone fisiche (algoritmo pubblico del D.M. 23 dicembre 1976): carattere di controllo con le
/// tabelle dei caratteri pari e dispari, omocodie (lettere al posto delle cifre) accettate, confronto con cognome, nome,
/// data di nascita e sesso. **Il comune non si controlla** (decisione 70: nessuna tabella dei codici catastali approvata).
/// Motore puro, senza stato dell'app («Luce» giro 13, §9.1 della specifica).
enum CodiceFiscale {

    /// Decisione 70: vero solo quando nelle risorse ci sarà la tabella dei codici catastali approvata dall'utente.
    static let comuneControllato = false

    /// Le lettere dei mesi (gennaio = A … dicembre = T).
    static let lettereMesi: [Character] = ["A", "B", "C", "D", "E", "H", "L", "M", "P", "R", "S", "T"]

    /// Le lettere che sostituiscono le cifre nelle omocodie (L = 0 … V = 9).
    static let lettereOmocodia: [Character] = ["L", "M", "N", "P", "Q", "R", "S", "T", "U", "V"]

    /// Le sette posizioni (da 0) che di norma sono cifre: anno, giorno e le tre cifre del comune.
    static let posizioniNumeriche = [6, 7, 9, 10, 12, 13, 14]

    /// Valori dei caratteri in posizione dispari (1ª, 3ª, … contando da 1).
    private static let dispari: [Character: Int] = [
        "0": 1, "1": 0, "2": 5, "3": 7, "4": 9, "5": 13, "6": 15, "7": 17, "8": 19, "9": 21,
        "A": 1, "B": 0, "C": 5, "D": 7, "E": 9, "F": 13, "G": 15, "H": 17, "I": 19, "J": 21, "K": 2, "L": 4, "M": 18,
        "N": 20, "O": 11, "P": 3, "Q": 6, "R": 8, "S": 12, "T": 14, "U": 16, "V": 10, "W": 22, "X": 25, "Y": 24, "Z": 23,
    ]

    /// Maiuscolo, senza spazi né separatori.
    static func pulito(_ s: String) -> String {
        s.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Il valore di un carattere in posizione pari (cifre 0-9, lettere A = 0 … Z = 25).
    private static func valorePari(_ c: Character) -> Int? {
        if let n = c.wholeNumberValue, c.isASCII { return n }
        guard let a = c.asciiValue, c.isUppercase, a >= 65, a <= 90 else { return nil }
        return Int(a) - 65
    }

    /// Il carattere di controllo dei primi 15 caratteri (nil se non sono 15 caratteri validi).
    static func carattereDiControllo(_ primi15: String) -> Character? {
        let s = Array(pulito(primi15))
        guard s.count == 15 else { return nil }
        var somma = 0
        for (i, c) in s.enumerated() {
            if i % 2 == 0 {
                guard let v = dispari[c] else { return nil }
                somma += v
            } else {
                guard let v = valorePari(c) else { return nil }
                somma += v
            }
        }
        return Character(Unicode.Scalar(UInt8(65 + somma % 26)))
    }

    /// Vero se il 16° carattere è quello calcolato sui primi 15.
    static func carattereDiControlloValido(_ cf: String) -> Bool {
        let s = pulito(cf)
        guard s.count == 16, let atteso = carattereDiControllo(String(s.prefix(15))) else { return false }
        return s.last == atteso
    }

    /// Le lettere delle omocodie tornano cifre nelle sette posizioni numeriche (il controllo resta com'è).
    static func senzaOmocodia(_ cf: String) -> String {
        var s = Array(pulito(cf))
        for i in posizioniNumeriche where i < s.count {
            if let n = lettereOmocodia.firstIndex(of: s[i]) { s[i] = Character(String(n)) }
        }
        return String(s)
    }

    /// Solo le lettere A-Z, senza accenti, apostrofi, spazi né cifre.
    private static func soloLettere(_ s: String) -> [Character] {
        let piegato = MotoreDocumenti.normale(s).uppercased()
        return piegato.filter { c in
            guard let a = c.asciiValue else { return false }
            return a >= 65 && a <= 90
        }.map { $0 }
    }

    private static let vocali: Set<Character> = ["A", "E", "I", "O", "U"]

    /// Le tre lettere del cognome: consonanti, poi vocali, poi X.
    static func lettereCognome(_ s: String) -> String {
        let l = soloLettere(s)
        let consonanti = l.filter { !vocali.contains($0) }
        let voc = l.filter { vocali.contains($0) }
        return String((consonanti + voc + ["X", "X", "X"]).prefix(3))
    }

    /// Le tre lettere del nome: con quattro consonanti o più la 1ª, la 3ª e la 4ª; altrimenti come il cognome.
    static func lettereNome(_ s: String) -> String {
        let l = soloLettere(s)
        let consonanti = l.filter { !vocali.contains($0) }
        if consonanti.count >= 4 { return String([consonanti[0], consonanti[2], consonanti[3]]) }
        let voc = l.filter { vocali.contains($0) }
        return String((consonanti + voc + ["X", "X", "X"]).prefix(3))
    }

    /// Il sesso dal giorno (oltre 40 = femmina). Nil se il codice non ha la forma giusta.
    static func sesso(_ cf: String) -> SessoAnagrafico? {
        guard let g = giornoCodificato(cf) else { return nil }
        return g > 40 ? .femmina : .maschio
    }

    /// Il giorno come è scritto nel codice (con il +40 per le donne).
    private static func giornoCodificato(_ cf: String) -> Int? {
        let s = Array(senzaOmocodia(cf))
        guard s.count >= 11 else { return nil }
        return Int(String(s[9...10]))
    }

    /// Anno, mese e giorno scritti nel codice; il secolo lo sceglie chi chiama (dalle due cifre dell'anno).
    static func nascita(_ cf: String, secolo: (Int) -> Int) -> DateComponents? {
        let s = Array(senzaOmocodia(cf))
        guard s.count >= 11, let aa = Int(String(s[6...7])), let m = lettereMesi.firstIndex(of: s[8]),
              let g = giornoCodificato(cf) else { return nil }
        let giorno = g > 40 ? g - 40 : g
        guard (1...31).contains(giorno) else { return nil }
        return DateComponents(year: secolo(aa) + aa, month: m + 1, day: giorno)
    }

    /// Lunghezza, alfabeto e posizioni (dopo le omocodie) e carattere di controllo.
    static func formaValida(_ cf: String) -> Bool {
        let s = pulito(cf)
        guard s.count == 16 else { return false }
        return EstrattoreDocumento.formaCodiceFiscaleValida(senzaOmocodia(s)) && carattereDiControlloValido(s)
    }

    /// Il confronto con i dati della persona. Senza la tabella dei comuni il meglio possibile è `.coerenteSenzaComune`.
    static func coerenza(_ cf: String, cognome: String, nome: String, nascita: Date?, sesso: SessoAnagrafico?,
                         calendario: Calendar = Calendar(identifier: .gregorian)) -> CoerenzaCodiceFiscale {
        let s = pulito(cf)
        guard formaValida(s) else { return .formaNonValida }
        let cognomePulito = cognome.trimmingCharacters(in: .whitespaces)
        let nomePulito = nome.trimmingCharacters(in: .whitespaces)
        guard !cognomePulito.isEmpty, !nomePulito.isEmpty, let nascita else { return .nonVerificabile }
        let c = Array(senzaOmocodia(s))
        var diverse: [ParteCodiceFiscale] = []
        if String(c[0...2]) != lettereCognome(cognomePulito) { diverse.append(.cognome) }
        if String(c[3...5]) != lettereNome(nomePulito) { diverse.append(.nome) }
        let parti = calendario.dateComponents([.year, .month, .day], from: nascita)
        if let anno = parti.year, Int(String(c[6...7])) != anno % 100 { diverse.append(.anno) }
        if let mese = parti.month, mese >= 1, mese <= 12, c[8] != lettereMesi[mese - 1] { diverse.append(.mese) }
        if let giorno = parti.day, let g = giornoCodificato(s) {
            let giornoScritto = g > 40 ? g - 40 : g
            if giornoScritto != giorno {
                diverse.append(.giorno)
            } else if let sesso, (g > 40) != (sesso == .femmina) {
                diverse.append(.sesso)
            }
        }
        guard diverse.isEmpty else { return .diverso(diverse) }
        return comuneControllato ? .coerente : .coerenteSenzaComune
    }
}
