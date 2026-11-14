import Foundation

// Prisma ovunque (Design/template-novita-specifica.md §13, giro 8): i testi della pagina Impostazioni › iPhone e iPad,
// della pillola «Senza Mac · copia cifrata» e dell'avviso a fine sincronizzazione. Solo testi: le cifre vengono
// dall'archivio, dal giornale e dall'esito della sincronizzazione (SpazioOvunque, MotoreUnioneOvunque).

enum TestiOvunque {
    static let pillola = "Senza Mac · copia cifrata"
    static let pillolaCompatta = "Senza Mac"
    static let fraseCifratura = "Cifrato con la tua chiave: senza, il file in iCloud è illeggibile. Nessun server."
    static let avvisoPassphrase = "Senza passphrase la copia in iCloud Drive non si apre più, per nessuno: neanche per Apple. I dati restano sul Mac."
    static let confermaSpegniMac = "La copia in iCloud Drive viene cancellata. I dati restano sul Mac."
    static let confermaSpegniDispositivo = "Questo dispositivo smette di leggere la copia del Mac. I dati di qui restano, ma non si aggiornano più."

    // MARK: Numeri e nomi

    private static let numeri = ["zero", "una", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove", "dieci"]

    /// «una nota», «due attività», «un appuntamento», «tre profili dei bisogni». Oltre dieci, le cifre.
    static func quanti(_ n: Int, _ e: EntitaOvunque) -> String {
        if n == 1 {
            switch e {
            case .nota: return "una nota"
            case .attivita: return "un’attività"
            case .appuntamento: return "un appuntamento"
            case .bisogni: return "un profilo dei bisogni"
            case .eventoVita: return "un evento della linea della vita"
            case .sessioneCopilota: return "una scheda del copilota"
            case .inquadratura: return "una posizione inquadrata"
            case .pratica: return "un passo di una pratica"
            case .anagrafica: return "una scheda di un cliente"
            case .posizione: return "una posizione"
            }
        }
        let numero = n >= 0 && n < numeri.count ? numeri[n] : "\(n)"
        switch e {
        case .nota: return "\(numero) note"
        case .attivita: return "\(numero) attività"
        case .appuntamento: return "\(numero) appuntamenti"
        case .bisogni: return "\(numero) profili dei bisogni"
        case .eventoVita: return "\(numero) eventi della linea della vita"
        case .sessioneCopilota: return "\(numero) schede del copilota"
        case .inquadratura: return "\(numero) posizioni inquadrate"
        case .pratica: return "\(numero) passi delle pratiche"
        case .anagrafica: return "\(numero) schede dei clienti"
        case .posizione: return "\(numero) posizioni"
        }
    }

    /// «a, b e c».
    static func elenco(_ parti: [String]) -> String {
        guard parti.count > 1 else { return parti.first ?? "" }
        return parti.dropLast().joined(separator: ", ") + " e " + (parti.last ?? "")
    }

    /// «una nota e due attività», nell'ordine dei tipi.
    static func contenuto(_ operazioni: [OperazioneOvunque]) -> String {
        let conteggio = MotoreUnioneOvunque.conteggio(operazioni)
        let parti = EntitaOvunque.allCases.compactMap { e -> String? in
            guard let n = conteggio[e], n > 0 else { return nil }
            return quanti(n, e)
        }
        return elenco(parti)
    }

    /// «dall’iPhone», «dall’iPad», «da Mac di Denis».
    static func da(_ nome: String) -> String {
        guard let prima = nome.lowercased().first, "aeiou".contains(prima) else { return "da \(nome)" }
        return "dall’\(nome)"
    }

    // MARK: Tempi

    /// «adesso», «1 minuto fa», «12 minuti fa», «alle 09:12», «ieri alle 18:40», «lun 2 alle 9:12».
    static func quando(_ data: Date, adesso: Date = Date()) -> String {
        let secondi = adesso.timeIntervalSince(data)
        if secondi < 60 { return "adesso" }
        let minuti = Int(secondi / 60)
        if minuti < 60 { return minuti == 1 ? "1 minuto fa" : "\(minuti) minuti fa" }
        let ora = Formati.ora.string(from: data)
        let cal = Calendar.current
        if cal.isDateInToday(data) { return "alle \(ora)" }
        if cal.isDateInYesterday(data) { return "ieri alle \(ora)" }
        return "\(Formati.giornoBreve.string(from: data)) alle \(ora)"
    }

    /// Il momento della giornata: «stamattina», «oggi pomeriggio», «stasera», «ieri», «lun 2».
    static func momento(_ data: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(data) {
            let ora = cal.component(.hour, from: data)
            if ora < 13 { return "stamattina" }
            if ora < 18 { return "oggi pomeriggio" }
            return "stasera"
        }
        if cal.isDateInYesterday(data) { return "ieri" }
        return Formati.giornoBreve.string(from: data)
    }

    /// «iPhone · stamattina alle 09:12».
    static func gruppo(nome: String, data: Date) -> String {
        "\(nome) · \(momento(data)) alle \(Formati.ora.string(from: data))"
    }

    // MARK: Stato della card

    /// Il titolo della riga di stato sotto lo schema.
    static func titolo(_ s: StatoVistaOvunque, adesso: Date = Date()) -> String {
        switch s {
        case .spenta: return "La copia per iPhone e iPad è spenta"
        case .maiFatta(let mac): return mac ? "Nessuna copia ancora" : "Aspetto la copia del Mac"
        case .passphrase: return "Serve la passphrase"
        case .iCloud: return "iCloud Drive non risponde"
        case .cartella: return "Scegli di nuovo la cartella"
        case .inCorso: return "Sincronizzo…"
        case .attesaICloud: return "Aspetto che iCloud porti la copia…"
        case .errore: return "Sincronizzazione non riuscita"
        case .conflitti(let n): return "Sincronizzato · \(n == 1 ? "1 modifica" : "\(n) modifiche") da guardare"
        case .riuscita(let data):
            guard let data else { return "Sincronizzato" }
            let q = quando(data, adesso: adesso)
            return q == "adesso" ? "Sincronizzato adesso" : "Sincronizzato · \(q)"
        }
    }

    /// La frase sotto il titolo.
    static func frase(_ s: StatoVistaOvunque, mac: Bool) -> String {
        switch s {
        case .spenta:
            return mac ? "Accendila per lavorare dal cliente anche senza il Mac."
                       : "Accendila per avere su questo dispositivo la copia cifrata del Mac."
        case .maiFatta(let suMac):
            return suMac ? "La prima copia porta clienti, agenda e posizioni su iPhone e iPad, cifrati."
                         : "Il Mac non ha ancora scritto la copia nella cartella: aprilo e premi «Sincronizza ora»."
        case .passphrase:
            return "Senza passphrase la copia non si fa, per non metterla in chiaro in iCloud."
        case .iCloud:
            return mac ? "Controlla di aver acceso iCloud Drive in Impostazioni di Sistema. I dati restano sul Mac."
                       : "Controlla di aver acceso iCloud Drive in Impostazioni. I dati di qui restano."
        case .cartella:
            return "Prisma non ritrova la cartella di Prisma ovunque, o non ha più il permesso di aprirla."
        case .attesaICloud:
            return "iCloud Drive impiega da pochi secondi a qualche minuto. Riprovo da solo al prossimo controllo."
        case .errore(let m):
            return m
        case .conflitti:
            return "Lo stesso dato è cambiato sul Mac e sull’iPhone: scegli tu quale tenere."
        case .inCorso, .riuscita:
            return fraseCifratura
        }
    }

    /// L'avviso a fine sincronizzazione.
    static func avviso(unite: Int, conflitti: Int) -> String {
        var t = "Mac, iPhone e iPad allineati"
        if unite > 0 { t += " · " + (unite == 1 ? "1 modifica unita" : "\(unite) modifiche unite") }
        if conflitti > 0 { t += " · " + (conflitti == 1 ? "1 da decidere" : "\(conflitti) da decidere") }
        return t
    }

    // MARK: Modifiche in attesa

    /// «3 dall’iPhone di stamattina: una nota e due attività.» (nil se non ce ne sono).
    static func inAttesa(_ operazioni: [OperazioneOvunque], nomi: [String: String]) -> String? {
        guard !operazioni.isEmpty else { return nil }
        let dispositivi = Set(operazioni.map(\.dispositivo))
        let provenienza: String
        if dispositivi.count == 1, let id = dispositivi.first {
            let ultima = operazioni.map(\.data).max() ?? Date()
            provenienza = "\(da(nomi[id] ?? "iPhone")) di \(momento(ultima))"
        } else {
            provenienza = "da iPhone e iPad"
        }
        return "\(operazioni.count) \(provenienza): \(contenuto(operazioni))."
    }

    /// Sul dispositivo: «3 da unire al Mac: una nota e due attività.»
    static func daUnire(_ operazioni: [OperazioneOvunque]) -> String {
        guard !operazioni.isEmpty else { return "Nessuna: le modifiche di qui sono già sul Mac." }
        return "\(operazioni.count) da unire al Mac: \(contenuto(operazioni))."
    }

    static let nessunaInAttesa = "Nessuna: Mac, iPhone e iPad sono allineati."

    /// Il piede del telefono d'esempio: «3 modifiche si uniranno al Mac».
    static func piedeTelefono(_ n: Int) -> String {
        switch n {
        case 0: return "Tutto è già sul Mac"
        case 1: return "1 modifica si unirà al Mac"
        default: return "\(n) modifiche si uniranno al Mac"
        }
    }

    // MARK: Le operazioni a parole

    /// «Nota nuova», «Attività cambiata: scadenza», «Appuntamento eliminato».
    static func operazione(_ op: OperazioneOvunque) -> String {
        let (nome, femminile) = nomeEntita(op.entita)
        switch op.tipo {
        case .crea: return "\(nome) \(femminile ? "nuova" : "nuovo")"
        case .elimina: return "\(nome) \(femminile ? "eliminata" : "eliminato")"
        case .modificaCampo:
            let campo = op.campo.map(nomeCampo) ?? ""
            return "\(nome) \(femminile ? "cambiata" : "cambiato")" + (campo.isEmpty ? "" : ": \(campo)")
        }
    }

    /// Il nome del tipo con l'iniziale maiuscola e il genere.
    static func nomeEntita(_ e: EntitaOvunque) -> (String, Bool) {
        switch e {
        case .nota: return ("Nota", true)
        case .attivita: return ("Attività", true)
        case .appuntamento: return ("Appuntamento", false)
        case .bisogni: return ("Profilo dei bisogni", false)
        case .eventoVita: return ("Evento della linea della vita", false)
        case .sessioneCopilota: return ("Scheda del copilota", true)
        case .inquadratura: return ("Posizione inquadrata", true)
        case .pratica: return ("Pratica", true)
        case .anagrafica: return ("Scheda del cliente", true)
        case .posizione: return ("Posizione", true)
        }
    }

    /// Il nome di un campo per l'utente.
    static func nomeCampo(_ campo: String) -> String {
        switch campo {
        case "titolo": return "titolo"
        case "testo": return "testo"
        case "fissata": return "in evidenza"
        case "clienteId": return "cliente"
        case "scadenza": return "scadenza"
        case "priorita": return "priorità"
        case "completata": return "fatta"
        case "note", "nota": return "note"
        case "inizio": return "data e ora"
        case "durataMinuti", "durataAnni": return "durata"
        case "luogo": return "luogo"
        case "stato": return "stato"
        case "tipo": return "tipo"
        case "importo": return "importo"
        case "eta": return "età"
        case "anno": return "anno"
        case "verbale": return "verbale"
        case "schede": return "schede"
        case "passi": return "passi della pratica"
        case "conclusaIl": return "conclusione"
        case "nome": return "nome"
        case "iniziali": return "iniziali"
        case "email": return "e-mail"
        case "telefono": return "telefono"
        case "indirizzo": return "indirizzo"
        case "professione": return "professione"
        case "statoCivile": return "stato civile"
        case "dataNascita": return "data di nascita"
        case "preferito": return "preferito"
        case "tema": return "motto"
        case "versamentoIniziale": return "premio unico"
        case "premio": return "premio periodico"
        case "frequenza": return "frequenza"
        case "controvalore": return "valore di oggi"
        case "dataValore": return "data del valore"
        case "totaleVersato": return "totale versato"
        case "capitaleAssicurato": return "capitale assicurato"
        case "esito": return "esito della proposta"
        case "decorrenza": return "decorrenza"
        case "numeroContratto": return "numero di contratto"
        default: return campo
        }
    }

    /// Perché un'operazione è in «Da decidere».
    static func motivo(_ m: MotivoConflitto, dispositivo: String) -> String {
        switch m {
        case .stessoCampo: return "Lo stesso dato è cambiato sul Mac e \(sul(dispositivo)): scegli quale tenere."
        case .eliminataSulMac: return "\(maiuscola(sul(dispositivo))) l’ha cambiata, ma sul Mac non c’è più."
        case .eliminataSulDispositivo: return "\(maiuscola(sul(dispositivo))) l’ha eliminata, il Mac l’ha cambiata."
        case .clienteMancante: return "Il cliente non c’è più sul Mac: si tiene la versione del Mac, niente note orfane."
        }
    }

    /// «sull’iPhone», «sull’iPad», «su Mac di Denis».
    static func sul(_ nome: String) -> String {
        guard let prima = nome.lowercased().first, "aeiou".contains(prima) else { return "su \(nome)" }
        return "sull’\(nome)"
    }

    /// «dell’iPhone», «dell’iPad», «di Mac di Denis».
    static func di(_ nome: String) -> String {
        guard let prima = nome.lowercased().first, "aeiou".contains(prima) else { return "di \(nome)" }
        return "dell’\(nome)"
    }

    /// Il percorso della cartella con le parole del Finder: «iCloud Drive › Prisma ovunque».
    static func percorso(_ p: String?) -> String {
        guard let p, !p.isEmpty else { return "Nessuna cartella scelta" }
        let segno = "Mobile Documents/com~apple~CloudDocs"
        if let r = p.range(of: segno) {
            let resto = p[r.upperBound...].split(separator: "/").map(String.init)
            return (["iCloud Drive"] + resto).joined(separator: " › ")
        }
        let parti = p.split(separator: "/").map(String.init)
        return parti.suffix(2).joined(separator: " › ")
    }

    static func maiuscola(_ t: String) -> String {
        guard let prima = t.first else { return t }
        return prima.uppercased() + t.dropFirst()
    }

    /// Un valore JSON canonico in parole (il testo, «Sì», una data, l'oggetto in breve). nil = «Non c'è».
    static func leggibile(_ json: String?, campo: String?) -> String {
        guard let json, json != JSONOvunque.nullo else { return "Non c’è" }
        guard let v = JSONOvunque.valore(json) else { return "Non c’è" }
        return leggibile(valore: v, campo: campo)
    }

    private static func leggibile(valore v: Any, campo: String?) -> String {
        if let o = v as? [String: Any] {
            // Un oggetto intero: il titolo e il testo (o le note)
            let titolo = (o["titolo"] as? String) ?? ""
            let corpo = (o["testo"] as? String) ?? (o["note"] as? String) ?? (o["nota"] as? String) ?? ""
            let parti = [titolo, corpo].filter { !$0.isEmpty }
            return parti.isEmpty ? "—" : parti.joined(separator: " · ")
        }
        if let b = v as? Bool, CFGetTypeID(v as CFTypeRef) == CFBooleanGetTypeID() { return b ? "Sì" : "No" }
        if let s = v as? String {
            if let d = ISO8601DateFormatter().date(from: s) { return Formati.dataOra.string(from: d) }
            if campo == "priorita" || campo == "stato" || campo == "tipo" { return maiuscola(s) }
            return s.isEmpty ? "—" : s
        }
        if let n = v as? NSNumber {
            return campo == "importo" ? Formati.euro(n.doubleValue) : Formati.numeroFormatter.string(from: n) ?? "\(n)"
        }
        if let a = v as? [Any] { return a.count == 1 ? "1 elemento" : "\(a.count) elementi" }
        return "—"
    }
}

/// Lo stato mostrato dalla card dello schema (titolo, frase, pulsante, pallini).
enum StatoVistaOvunque: Equatable {
    case spenta
    /// La copia non c'è ancora (`mac`: lo dice il Mac, altrimenti il dispositivo che la aspetta).
    case maiFatta(mac: Bool)
    case passphrase
    case iCloud
    case cartella
    case inCorso
    case attesaICloud
    case errore(String)
    case conflitti(Int)
    case riuscita(Date?)

    /// I pallini corrono solo quando la copia c'è e lavora.
    var attivo: Bool {
        switch self {
        case .inCorso, .riuscita, .conflitti, .attesaICloud: return true
        default: return false
        }
    }

    /// Pallini grigi: niente scambio.
    var spento: Bool {
        switch self {
        case .spenta, .iCloud, .cartella, .passphrase: return true
        default: return false
        }
    }
}
