import Foundation

// Il sinistro come una spedizione («Luce» giro 15, Design/template-luce-specifica.md §7.4): i conti della scheda
// Pratiche › Sinistri. Da quanti giorni è aperto (dalla denuncia, non dai fatti), la fase che viene dopo, i documenti che
// mancano, l'indennizzo detto a parole («tra 1.200 e 1.800 €», «fino a 1.500 €», «pagati 3.400 €», «da stimare»), il
// sinistro fermo (nessun fatto da più dei giorni scelti), l'ordine della barra (aperti, poi chiusi degli ultimi 90
// giorni), il passaggio di fase con il suo fatto, l'occasione di Messaggi per aggiornare il cliente (non commerciale,
// senza numero di polizza, referti né importi se non scelti) e il testo del sollecito alla compagnia (solo numero di
// polizza, numero di sinistro e assicurato). Prisma non è collegato alla compagnia: ogni fase, data e importo li segna il
// consulente. Funzioni pure: la prova è ProvaCalcoliSinistri.

enum MotoreSinistri {
    /// I sinistri chiusi restano nella barra per 90 giorni («recenti»).
    static let giorniRecenti = 90
    /// Decisione 36: solo testi brevi e generici.
    static let lunghezzaTitolo = 60
    static let lunghezzaTesto = 140

    // MARK: - Stato

    /// Pagato o respinto: il sinistro è chiuso.
    static func chiuso(_ s: Sinistro) -> Bool { s.fase == .pagato || s.fase == .respinto }

    /// Da quanti giorni è aperto: dalla data della denuncia a oggi (per un chiuso, fino alla chiusura). Mai negativo.
    static func giorniAperto(_ s: Sinistro, oggi: Date, cal: Calendar = .current) -> Int {
        var fine = oggi
        if chiuso(s), let c = s.chiusoIl, c < oggi { fine = c }
        let g = cal.dateComponents([.day], from: cal.startOfDay(for: s.apertoIl), to: cal.startOfDay(for: fine)).day ?? 0
        return max(0, g)
    }

    /// La fase del percorso che viene dopo quella di adesso (nil per «Pagato» e «Respinto»).
    static func prossimaFase(_ s: Sinistro) -> FaseSinistro? {
        guard let i = FaseSinistro.percorso.firstIndex(of: s.fase), i + 1 < FaseSinistro.percorso.count else { return nil }
        return FaseSinistro.percorso[i + 1]
    }

    /// I documenti richiesti non ancora ricevuti, nell'ordine dell'elenco.
    static func documentiMancanti(_ s: Sinistro) -> [DocumentoSinistro] {
        s.documenti.filter { $0.ricevutoIl == nil }
    }

    /// L'indennizzo a parole: «pagati 3.400 €», «tra 1.200 e 1.800 €», «fino a 1.500 €», «almeno 1.200 €», «circa
    /// 1.500 €», «nessun indennizzo» (respinto) o «da stimare». Solo le cifre scritte dal consulente.
    static func indennizzo(_ s: Sinistro) -> String {
        if s.fase == .pagato {
            if let p = s.pagato, p > 0 { return "pagati " + Formati.euro(p) }
            return "pagato"
        }
        if s.fase == .respinto { return "nessun indennizzo" }
        let minimo = s.stimaMinima.flatMap { $0 > 0 ? $0 : nil }
        let massimo = s.stimaMassima.flatMap { $0 > 0 ? $0 : nil }
        if let a = minimo, let b = massimo {
            if b > a { return "tra \(numero(a)) e \(Formati.euro(b))" }
            return "circa " + Formati.euro(a)
        }
        if let b = massimo { return "fino a " + Formati.euro(b) }
        if let a = minimo { return "almeno " + Formati.euro(a) }
        return "da stimare"
    }

    /// «1.200» (senza il simbolo, per «tra 1.200 e 1.800 €»).
    static func numero(_ v: Double) -> String {
        Formati.numeroFormatter.string(from: NSNumber(value: v.rounded())) ?? "\(Int(v.rounded()))"
    }

    /// Il giorno dell'ultimo fatto già accaduto (un fatto con data futura non conta), o la denuncia.
    static func ultimoMovimento(_ s: Sinistro, oggi: Date) -> Date {
        let passati = s.eventi.map(\.data).filter { $0 <= oggi }
        return max(passati.max() ?? s.apertoIl, s.apertoIl)
    }

    /// Da quanti giorni non succede niente (dall'ultimo fatto già accaduto, o dalla denuncia).
    static func giorniFermo(_ s: Sinistro, oggi: Date, cal: Calendar = .current) -> Int {
        let g = cal.dateComponents([.day], from: cal.startOfDay(for: ultimoMovimento(s, oggi: oggi)),
                                   to: cal.startOfDay(for: oggi)).day ?? 0
        return max(0, g)
    }

    /// Fermo: aperto e senza fatti da più dei giorni della soglia (con 14 giorni diventa fermo al quindicesimo).
    static func fermo(_ s: Sinistro, oggi: Date, soglia: Int, cal: Calendar = .current) -> Bool {
        guard !chiuso(s), soglia > 0 else { return false }
        return giorniFermo(s, oggi: oggi, cal: cal) > soglia
    }

    /// I nodi della linea della spedizione: le cinque fasi del percorso (fatte, adesso, future; a «Pagato» tutte fatte)
    /// o, per un respinto, le fasi raggiunte prima del rifiuto (dai fatti) e il nodo rosso. Come `Sinistro.perIlCliente`.
    static func linea(_ s: Sinistro) -> [(fase: FaseSinistro, stato: SinistroMini.StatoFase)] {
        if s.fase == .respinto {
            let raggiunte = s.eventi.compactMap(\.fase).compactMap { FaseSinistro.percorso.firstIndex(of: $0) }
            let ultima = raggiunte.max() ?? 0
            var nodi: [(fase: FaseSinistro, stato: SinistroMini.StatoFase)] = []
            for (i, f) in FaseSinistro.percorso.enumerated() where i <= ultima && f != .pagato {
                nodi.append((fase: f, stato: .fatta))
            }
            nodi.append((fase: .respinto, stato: .respinta))
            return nodi
        }
        let attuale = FaseSinistro.percorso.firstIndex(of: s.fase) ?? 0
        return FaseSinistro.percorso.enumerated().map { (i, f) -> (fase: FaseSinistro, stato: SinistroMini.StatoFase) in
            let stato: SinistroMini.StatoFase
            if i < attuale || s.fase == .pagato { stato = .fatta } else if i == attuale { stato = .adesso } else { stato = .futura }
            return (fase: f, stato: stato)
        }
    }

    /// Fin dove arriva la barra della linea (0…1): alla fase di adesso; piena a «Pagato» e al nodo rosso.
    static func riempimento(_ s: Sinistro) -> Double {
        if s.fase == .pagato || s.fase == .respinto { return 1 }
        let n = FaseSinistro.percorso.count
        guard n > 1, let i = FaseSinistro.percorso.firstIndex(of: s.fase) else { return 0 }
        return Double(i) / Double(n - 1)
    }

    /// Il giorno della chiusura (o dell'ultimo fatto, o della denuncia) di un sinistro chiuso.
    static func dataChiusura(_ s: Sinistro) -> Date {
        s.chiusoIl ?? s.ultimoEvento?.data ?? s.apertoIl
    }

    /// La barra laterale: prima gli aperti (dalla denuncia più recente), poi i chiusi degli ultimi 90 giorni (dalla
    /// chiusura più recente). I chiusi più vecchi escono dalla barra (restano nei dati e nel dossier).
    static func elenco(_ tutti: [Sinistro], oggi: Date, cal: Calendar = .current) -> [Sinistro] {
        let aperti = tutti.filter { !chiuso($0) }.sorted { a, b in
            a.apertoIl != b.apertoIl ? a.apertoIl > b.apertoIl : a.id < b.id
        }
        let limite = cal.date(byAdding: .day, value: -giorniRecenti, to: cal.startOfDay(for: oggi)) ?? oggi
        let chiusi = tutti.filter { chiuso($0) && dataChiusura($0) >= limite }.sorted { a, b in
            dataChiusura(a) != dataChiusura(b) ? dataChiusura(a) > dataChiusura(b) : a.id < b.id
        }
        return aperti + chiusi
    }

    // MARK: - Cambiare

    /// Porta il sinistro alla fase data, con il giorno scelto (oggi di base, modificabile), e aggiunge il fatto
    /// corrispondente in «Cosa è successo». «Pagato» segna l'importo pagato (se maggiore di zero) e la chiusura;
    /// «Respinto» la chiusura; ogni altra fase riapre e toglie l'importo pagato.
    static func avanza(_ s: inout Sinistro, a fase: FaseSinistro, il data: Date, pagato: Double?,
                       id: String = "evento-\(UUID().uuidString.prefix(8).lowercased())") {
        s.fase = fase
        switch fase {
        case .pagato:
            s.pagato = pagato.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
            s.chiusoIl = data
        case .respinto:
            s.pagato = nil
            s.chiusoIl = data
        case .denuncia, .documenti, .perizia, .liquidazione:
            s.pagato = nil
            s.chiusoIl = nil
        }
        s.eventi.append(EventoSinistro(id: id, data: data, testo: TestiSinistri.fattoDellaFase(fase, pagato: s.pagato), fase: fase))
    }

    /// Un testo breve per i sinistri: senza spazi in testa e in coda, su una riga, al più `limite` caratteri.
    static func breve(_ t: String, limite: Int) -> String {
        let una = t.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return String(una.prefix(limite))
    }

    // MARK: - Il cliente e la compagnia

    /// L'occasione di Messaggi per aggiornare il cliente: tipo `.sinistro` (non commerciale), riferimento
    /// «<id>-<fase>», gruppo «Da mandare oggi», canale della polizza (nil senza polizza). Le cifre sono solo il titolo,
    /// la fase, l'ultimo fatto scritto dal consulente, il giorno e, se acceso nel sinistro, l'importo pagato: mai il
    /// numero di polizza o di sinistro, la descrizione, le stime o i documenti (decisione 11).
    static func occasione(_ s: Sinistro, cliente: Cliente, consulente: String, oggi: Date,
                          polizza: Posizione? = nil) -> OccasioneMessaggio {
        var cifre: [CifraMessaggio] = [CifraMessaggio(.sinistro, s.titolo), CifraMessaggio(.faseSinistro, s.fase.nome)]
        if let u = s.ultimoEvento?.testo.trimmingCharacters(in: .whitespacesAndNewlines), !u.isEmpty {
            cifre.append(CifraMessaggio(.ultimoFatto, u))
        }
        cifre.append(CifraMessaggio(.aggiornatoIl, Formati.dataEstesa.string(from: oggi)))
        if s.importoAlCliente == true, s.fase == .pagato, let p = s.pagato, p > 0 {
            cifre.append(CifraMessaggio(.importoPagato, Formati.euro(p)))
        }
        return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .sinistro, riferimento: "\(s.id)-\(s.fase.rawValue)"),
                                  clienteId: cliente.id, canale: polizza?.canale, gruppo: .oggi,
                                  titolo: TestiSinistri.titoloOccasione(s), perche: TestiSinistri.percheOccasione(s),
                                  oggetto: TestiSinistri.oggettoOccasione(s), cifre: cifre, priorita: .alta, data: oggi)
    }

    /// L'id del sinistro da un riferimento di Messaggi («<id>-<fase>»: tutto fino all'ultimo «-»).
    static func idDaRiferimento(_ riferimento: String) -> String? {
        guard let i = riferimento.lastIndex(of: "-"), i != riferimento.startIndex else { return nil }
        let fase = String(riferimento[riferimento.index(after: i)...])
        guard FaseSinistro(rawValue: fase) != nil else { return nil }
        return String(riferimento[..<i])
    }

    /// Il sollecito alla compagnia (D4.3): oggetto e corpo con solo numero di polizza, numero di sinistro e assicurato.
    /// Mai il titolo, la descrizione, i fatti o i documenti (possono essere dati sanitari). La firma, se c'è, in fondo.
    static func sollecito(_ s: Sinistro, polizza: Posizione?, assicurato: String,
                          firma: String? = nil) -> (oggetto: String, corpo: String) {
        let numeroPolizza = (polizza?.numeroContratto ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let numeroSinistro = (s.numeroSinistro ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let chi = assicurato.trimmingCharacters(in: .whitespacesAndNewlines)
        var oggetto = "Sollecito sinistro"
        if !numeroSinistro.isEmpty { oggetto += " n. \(numeroSinistro)" }
        if !numeroPolizza.isEmpty { oggetto += " · polizza n. \(numeroPolizza)" }
        var righe: [String] = []
        if !numeroPolizza.isEmpty { righe.append("Numero di polizza: \(numeroPolizza)") }
        if !numeroSinistro.isEmpty { righe.append("Numero di sinistro: \(numeroSinistro)") }
        if !chi.isEmpty { righe.append("Assicurato: \(chi)") }
        var corpo = "Buongiorno,\n\nvi chiedo cortesemente un aggiornamento sullo stato del sinistro indicato qui sotto."
        if !righe.isEmpty { corpo += "\n\n" + righe.joined(separator: "\n") }
        corpo += "\n\nGrazie per l'attenzione.\n\nCordiali saluti"
        if let f = firma?.trimmingCharacters(in: .whitespacesAndNewlines), !f.isEmpty { corpo += ",\n" + f } else { corpo += "." }
        return (oggetto, corpo)
    }

    /// L'indirizzo dei sinistri scritto dall'utente per la compagnia della polizza (confronto senza maiuscole e spazi).
    static func indirizzo(compagnia: String, in elenco: [IndirizzoCompagnia]) -> IndirizzoCompagnia? {
        let chiave = compagnia.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !chiave.isEmpty else { return nil }
        return elenco.first { $0.compagnia.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == chiave }
    }

    /// Le polizze a cui si può collegare un sinistro: protezione in essere del cliente.
    static func polizzeAdatte(_ posizioni: [Posizione], clienteId: String) -> [Posizione] {
        posizioni.filter { $0.clienteId == clienteId && $0.area == .protezione && $0.stato == .inEssere }
    }
}
