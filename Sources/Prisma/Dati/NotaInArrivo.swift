import Foundation

// La nota vocale arrivata dall'iPhone («Luce» giro 13, Design/template-luce-specifica.md §6.2): il testo dettato (già
// trascritto sul telefono: l'audio non esiste), il cliente di cui si parla e le proposte di Prisma (nota, attività,
// messaggio, obiettivo), tutte da confermare sul Mac (decisione 102). Sta nell'archivio (versione 27, sezione «ovunque»
// della cartella a pezzi) e nei backup, mai in «Prisma ovunque» (decisione 44); le note decise si tolgono dopo 30 giorni.
// Tutte le date sono al secondo, come le scrive l'archivio (`.iso8601`): così si rileggono identiche.

/// Che cosa propone una voce della nota.
enum TipoPropostaNota: String, Codable, CaseIterable {
    case nota, attivita, messaggio, obiettivo
}

/// Lo stato di una proposta: un valore sconosciuto torna «proposta» (mai applicata per sbaglio).
enum StatoPropostaNota: String, Codable {
    case proposta, confermata, scartata
}

/// Una voce proposta dalla nota.
struct PropostaNota: Identifiable, Codable, Hashable {
    /// Stabile: «nota», «attivita-<chiave>», «messaggio-<chiave>», «obiettivo-<area>».
    var id: String
    var tipo: TipoPropostaNota
    /// «Risentire Giulia per il mutuo · gennaio».
    var titolo: String
    /// La frase da cui nasce.
    var frase: String
    /// La scadenza dell'attività (al secondo).
    var scadenza: Date?
    /// «a gennaio» senza l'anno: la data è il primo gennaio prossimo, da confermare.
    var scadenzaDaConfermare = false
    /// L'obiettivo da aggiornare (mai creato da qui).
    var obiettivoId: String?
    /// «anticipare di un anno» = -1.
    var anniSpostamento: Int?
    var area: AreaBisogno?
    /// Solo le cifre dette nel testo.
    var importi: [Double] = []
    var frequenza: Frequenza?
    var origine: SchedaCopilota.Origine = .regole
    var stato: StatoPropostaNota = .proposta
    /// La nota, l'attività o l'obiettivo creati o toccati dalla conferma.
    var elementoId: String?

    init(id: String, tipo: TipoPropostaNota, titolo: String, frase: String) {
        self.id = id
        self.tipo = tipo
        self.titolo = titolo
        self.frase = frase
    }

    private enum CodingKeys: String, CodingKey {
        case id, tipo, titolo, frase, scadenza, scadenzaDaConfermare, obiettivoId, anniSpostamento, area, importi, frequenza
        case origine, stato, elementoId
    }

    /// Lettura tollerante: id e tipo obbligatori (senza, la proposta si scarta); uno stato sconosciuto torna «proposta».
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tipo = try c.decode(TipoPropostaNota.self, forKey: .tipo)
        titolo = ((try? c.decodeIfPresent(String.self, forKey: .titolo)) ?? nil) ?? ""
        frase = ((try? c.decodeIfPresent(String.self, forKey: .frase)) ?? nil) ?? ""
        scadenza = ((try? c.decodeIfPresent(Date.self, forKey: .scadenza)) ?? nil).map(NotaInArrivo.alSecondo)
        scadenzaDaConfermare = ((try? c.decodeIfPresent(Bool.self, forKey: .scadenzaDaConfermare)) ?? nil) ?? false
        obiettivoId = (try? c.decodeIfPresent(String.self, forKey: .obiettivoId)) ?? nil
        anniSpostamento = (try? c.decodeIfPresent(Int.self, forKey: .anniSpostamento)) ?? nil
        area = (try? c.decodeIfPresent(AreaBisogno.self, forKey: .area)) ?? nil
        importi = (((try? c.decodeIfPresent([Double].self, forKey: .importi)) ?? nil) ?? []).filter(\.isFinite)
        frequenza = (try? c.decodeIfPresent(Frequenza.self, forKey: .frequenza)) ?? nil
        origine = ((try? c.decodeIfPresent(SchedaCopilota.Origine.self, forKey: .origine)) ?? nil) ?? .regole
        stato = ((try? c.decodeIfPresent(StatoPropostaNota.self, forKey: .stato)) ?? nil) ?? .proposta
        elementoId = (try? c.decodeIfPresent(String.self, forKey: .elementoId)) ?? nil
    }

    /// Il titolo al passato dopo la conferma («Nota salvata nel dossier»…), o da proporre.
    var titoloVoce: String {
        switch (tipo, stato) {
        case (.nota, .confermata): return "Nota salvata nel dossier"
        case (.attivita, .confermata): return "Attività creata"
        case (.messaggio, .confermata): return "Messaggio preparato"
        case (.obiettivo, .confermata): return "Obiettivo aggiornato"
        case (.nota, _): return "Nota per il dossier"
        case (.attivita, _): return "Attività da creare"
        case (.messaggio, _): return "Messaggio da preparare"
        case (.obiettivo, _): return "Obiettivo da aggiornare"
        }
    }
}

/// Lo stato della nota: un valore sconosciuto torna «da guardare».
enum StatoNotaInArrivo: String, Codable {
    case daGuardare, confermata, scartata
}

/// Una nota dettata sull'iPhone e arrivata sul Mac.
struct NotaInArrivo: Identifiable, Codable, Hashable {
    /// = `NotaVocalePonte.id`: ricevere due volte non duplica.
    var id: String
    var testo: String
    var quando: Date
    var durata: Double
    var dispositivo: String
    /// Il cliente scelto (riconosciuto con sicurezza o dall'utente).
    var clienteId: String?
    /// I clienti possibili quando Prisma non è sicuro.
    var candidati: [String] = []
    var appuntamentoId: String?
    var proposte: [PropostaNota] = []
    var stato: StatoNotaInArrivo = .daGuardare
    var arrivataIl: Date
    var decisaIl: Date?
    var conQwen = false

    /// L'archivio salva le date al secondo: una data con i decimali tornerebbe diversa dal disco.
    static func alSecondo(_ d: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: d.timeIntervalSinceReferenceDate.rounded(.down))
    }

    init(da p: NotaVocalePonte, arrivataIl: Date = Nota.adesso) {
        id = p.id
        testo = p.testo
        quando = NotaInArrivo.alSecondo(p.quando)
        durata = p.durata.isFinite ? max(0, p.durata) : 0
        dispositivo = p.dispositivo
        clienteId = p.clienteId
        appuntamentoId = p.appuntamentoId
        self.arrivataIl = NotaInArrivo.alSecondo(arrivataIl)
    }

    private enum CodingKeys: String, CodingKey {
        case id, testo, quando, durata, dispositivo, clienteId, candidati, appuntamentoId, proposte, stato, arrivataIl, decisaIl, conQwen
    }

    /// Lettura tollerante: id e testo obbligatori (senza, `ElencoTollerante` scarta la nota); il resto con `try?`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        testo = try c.decode(String.self, forKey: .testo)
        let quandoLetto = ((try? c.decodeIfPresent(Date.self, forKey: .quando)) ?? nil) ?? Date(timeIntervalSinceReferenceDate: 0)
        quando = NotaInArrivo.alSecondo(quandoLetto)
        let d = ((try? c.decodeIfPresent(Double.self, forKey: .durata)) ?? nil) ?? 0
        durata = d.isFinite ? max(0, d) : 0
        dispositivo = ((try? c.decodeIfPresent(String.self, forKey: .dispositivo)) ?? nil) ?? ""
        clienteId = (try? c.decodeIfPresent(String.self, forKey: .clienteId)) ?? nil
        candidati = ((try? c.decodeIfPresent([String].self, forKey: .candidati)) ?? nil) ?? []
        appuntamentoId = (try? c.decodeIfPresent(String.self, forKey: .appuntamentoId)) ?? nil
        proposte = ((try? c.decodeIfPresent(ElencoTollerante<PropostaNota>.self, forKey: .proposte)) ?? nil)?.elementi ?? []
        stato = ((try? c.decodeIfPresent(StatoNotaInArrivo.self, forKey: .stato)) ?? nil) ?? .daGuardare
        arrivataIl = NotaInArrivo.alSecondo(((try? c.decodeIfPresent(Date.self, forKey: .arrivataIl)) ?? nil) ?? quandoLetto)
        decisaIl = ((try? c.decodeIfPresent(Date.self, forKey: .decisaIl)) ?? nil).map(NotaInArrivo.alSecondo)
        conQwen = ((try? c.decodeIfPresent(Bool.self, forKey: .conQwen)) ?? nil) ?? false
    }

    /// Le proposte ancora da decidere.
    var proposteAperte: [PropostaNota] { proposte.filter { $0.stato == .proposta } }
}
