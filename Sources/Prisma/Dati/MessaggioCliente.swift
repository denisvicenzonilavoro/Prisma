import Foundation

// I messaggi ai clienti di «Prisma scrive per te» (Design/template-novita-specifica.md §5): Prisma trova l'occasione
// (MotoreOccasioniMessaggi), Vera scrive il testo con Qwen sul Mac o resta il modello fisso di Prisma (MessaggiVera,
// ModelliMessaggi), il consulente lo apre già compilato in Mail o in Messaggi e lo spedisce lui (AperturaMessaggi).
// Prisma non spedisce mai niente da solo. Ogni messaggio preparato resta nel dossier del cliente (`DatiPrisma.messaggi`,
// archivio versione 26, letto con tolleranza) ed entra nel backup.

/// Da cosa nasce un messaggio. L'avviso di mercato nasce dagli avvisi di Mercato (giro 7, MotoreMercato.avvisi e
/// MotoreOccasioniMessaggi.avvisiMercato).
enum TipoOccasioneMessaggio: String, Codable, CaseIterable, Identifiable {
    case riepilogoIncontro, scadenzaPosizione, compleanno, consenso, riesame, occasioneAgenda, parcella, avvisoMercato
    /// Dopo la prova del fuoco di Posizioni (giro 4): uno scenario avverso e il suo effetto sull'obiettivo del cliente.
    case provaFuoco
    /// Chiesto a Vera a parole («sposta l'incontro e avvisala»: «Fallo tu»): una bozza, mai un invio.
    case richiestaVera

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .riepilogoIncontro: return "Riepilogo dell'incontro"
        case .scadenzaPosizione: return "Scadenza"
        case .compleanno: return "Compleanno"
        case .consenso: return "Consenso"
        case .riesame: return "Riesame"
        case .occasioneAgenda: return "Occasione"
        case .parcella: return "Parcella"
        case .avvisoMercato: return "Avviso di mercato"
        case .provaFuoco: return "Prova del fuoco"
        case .richiestaVera: return "Chiesto a Vera"
        }
    }

    /// Il messaggio propone un incontro di vendita o un prodotto: serve il consenso commerciale.
    var commerciale: Bool {
        switch self {
        case .riesame, .occasioneAgenda, .avvisoMercato, .provaFuoco: return true
        case .riepilogoIncontro, .scadenzaPosizione, .compleanno, .consenso, .parcella, .richiestaVera: return false
        }
    }

    /// L'ordine nell'elenco a parità di priorità (riepilogo, scadenza, compleanno, consenso, riesame, occasione…).
    var ordine: Int { TipoOccasioneMessaggio.allCases.firstIndex(of: self) ?? 0 }
}

/// L'occasione di un messaggio: il tipo e il riferimento all'oggetto dei dati da cui nasce (l'incontro, la posizione
/// con la sua scadenza, la voce di conformità con la sua data, l'occasione dell'Agenda, la parcella, l'anno del
/// compleanno, il giorno da cui è dovuto il riesame). Con il cliente forma l'id dell'occasione (`OccasioneMessaggio.id`).
struct OrigineMessaggio: Codable, Hashable {
    var tipo: TipoOccasioneMessaggio
    var riferimento: String

    init(tipo: TipoOccasioneMessaggio, riferimento: String) {
        self.tipo = tipo
        self.riferimento = riferimento
    }
}

/// Il tono del messaggio. Cordiale e breve danno del tu, formale del lei.
enum TonoMessaggio: String, Codable, CaseIterable, Identifiable {
    case cordiale, formale, breve

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .cordiale: return "Cordiale"
        case .formale: return "Formale"
        case .breve: return "Breve"
        }
    }

    var lei: Bool { self == .formale }
}

/// Dove si apre il messaggio: Mail (con l'oggetto) o Messaggi (senza oggetto).
enum CanaleMessaggio: String, Codable, CaseIterable, Identifiable {
    case mail, messaggi

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .mail: return "Mail"
        case .messaggi: return "Messaggi"
        }
    }
}

/// Una cifra o un fatto dei motori di Prisma che il messaggio può citare, già scritto come va letto
/// («Scadenza» · «17 dicembre 2026»). Nel testo non può comparire nessun numero che non sia qui.
struct CifraMessaggio: Codable, Hashable {
    var etichetta: String
    var valore: String

    init(etichetta: String, valore: String) {
        self.etichetta = etichetta
        self.valore = valore
    }

    init(_ voce: VoceCifraMessaggio, _ valore: String) {
        self.init(etichetta: voce.rawValue, valore: valore)
    }
}

/// Le etichette delle cifre che i motori preparano per i messaggi (e che i modelli fissi leggono).
enum VoceCifraMessaggio: String, CaseIterable {
    case dataIncontro = "Data dell'incontro"
    case oraIncontro = "Ora dell'incontro"
    case decisioni = "Decisioni"
    case prossimoPasso = "Prossimo passo"
    case prossimoIncontro = "Prossimo incontro"
    case posizione = "Posizione"
    case scadenza = "Scadenza"
    case giorniAllaScadenza = "Giorni alla scadenza"
    case capitaleAssicurato = "Capitale assicurato"
    case premio = "Premio"
    case canale = "Canale"
    case compleanno = "Compleanno"
    case eta = "Età"
    case consenso = "Consenso"
    case firmatoIl = "Firmato il"
    case informativaAggiornata = "Informativa aggiornata il"
    case ultimoContatto = "Ultimo contatto"
    case riesameDovutoDal = "Riesame dovuto dal"
    case occasione = "Occasione"
    case dataOccasione = "Data dell'occasione"
    case cosaCambia = "Cosa cambia"
    case parcella = "Parcella"
    case importo = "Importo"
    case emessaIl = "Emessa il"
    case avviso = "Avviso"
    case scenario = "Scenario"
    case obiettivo = "Obiettivo"
    case coperturaOggi = "Copertura dell'obiettivo oggi"
    case coperturaDopo = "Copertura dopo lo scenario"
    case perditaScenario = "Patrimonio perso nello scenario"
}

/// A che punto è un messaggio. Prisma non spedisce: «aperto» vuol dire aperto già compilato nell'app del Mac
/// (o dell'iPhone), e la spedizione la fa il consulente.
enum StatoMessaggio: String, Codable, CaseIterable {
    case bozza, apertoInMail, apertoInMessaggi, salvato

    var nome: String {
        switch self {
        case .bozza: return "Bozza"
        case .apertoInMail: return "Aperto in Mail"
        case .apertoInMessaggi: return "Aperto in Messaggi"
        case .salvato: return "Salvato nel dossier"
        }
    }

    /// Aperto o salvato: l'occasione è coperta e non si ripropone.
    var copreOccasione: Bool { self != .bozza }
}

/// Chi ha scritto il testo: Vera con Qwen (il modello è in `MessaggioCliente.modello`) o il modello fisso di Prisma.
enum AutoreMessaggio: String, Codable, CaseIterable {
    // Compatibilità: negli archivi, nei backup e nei giornali di «Prisma ovunque» il valore salvato resta «eve» (il vecchio nome).
    case vera = "eve", modelloFisso

    var nome: String {
        switch self {
        case .vera: return "Vera"
        case .modelloFisso: return "Testo di Prisma"
        }
    }
}

/// Un messaggio preparato per un cliente (dalla versione 26 dell'archivio, `DatiPrisma.messaggi`).
struct MessaggioCliente: Identifiable, Codable, Hashable {
    var id = "messaggio-\(UUID().uuidString.prefix(8).lowercased())"
    var clienteId: String
    /// Al secondo, come le altre date dell'archivio: torna identico dal backup.
    var creatoIl = MessaggioCliente.adesso
    /// L'id dell'occasione da cui nasce (`OccasioneMessaggio.id`): serve a non riproporla.
    var occasioneId: String
    var origine: OrigineMessaggio
    /// Il canale di lavoro dell'occasione (Alleanza o indipendente), quando c'è.
    var canaleLavoro: Canale?
    var tono: TonoMessaggio
    var canale: CanaleMessaggio
    /// Solo per Mail; nil per Messaggi.
    var oggetto: String?
    var testo: String
    /// Le cifre dei motori che il testo poteva citare (le stesse della scheda passata a Vera).
    var cifre: [CifraMessaggio] = []
    var stato = StatoMessaggio.bozza
    /// Quando è stato aperto in Mail o in Messaggi (nil se non è mai stato aperto).
    var apertoIl: Date?
    var autore: AutoreMessaggio
    /// Il modello che ha scritto il testo (per esempio «qwen3.5:4b»); nil per il modello fisso.
    var modello: String?

    init(clienteId: String, occasioneId: String, origine: OrigineMessaggio, canaleLavoro: Canale?, tono: TonoMessaggio,
         canale: CanaleMessaggio, oggetto: String?, testo: String, cifre: [CifraMessaggio], autore: AutoreMessaggio,
         modello: String?, creatoIl: Date = MessaggioCliente.adesso) {
        self.clienteId = clienteId
        self.occasioneId = occasioneId
        self.origine = origine
        self.canaleLavoro = canaleLavoro
        self.tono = tono
        self.canale = canale
        self.oggetto = oggetto
        self.testo = testo
        self.cifre = cifre
        self.autore = autore
        self.modello = modello
        self.creatoIl = creatoIl
    }

    /// L'archivio salva le date al secondo: i messaggi nascono già così.
    static var adesso: Date { Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate.rounded(.down)) }

    /// La data da mostrare nel dossier: quando è stato aperto, altrimenti quando è stato preparato.
    var dataMostrata: Date { apertoIl ?? creatoIl }

    /// Dal più recente.
    static func ordina(_ a: MessaggioCliente, _ b: MessaggioCliente) -> Bool {
        (a.dataMostrata, a.id) > (b.dataMostrata, b.id)
    }

    private enum CodingKeys: String, CodingKey {
        case id, clienteId, creatoIl, occasioneId, origine, canaleLavoro, tono, canale, oggetto, testo, cifre, stato, apertoIl
        case autore, modello
    }

    /// Lettura tollerante: un tono, un canale o uno stato sconosciuti tornano al predefinito; senza cliente,
    /// occasione o testo il messaggio si scarta (ElencoTollerante tiene gli altri).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        creatoIl = (try? c.decodeIfPresent(Date.self, forKey: .creatoIl)) ?? Date.distantPast
        origine = try c.decode(OrigineMessaggio.self, forKey: .origine)
        occasioneId = (try? c.decodeIfPresent(String.self, forKey: .occasioneId)) ?? "\(origine.tipo.rawValue)-\(clienteId)-\(origine.riferimento)"
        canaleLavoro = (try? c.decodeIfPresent(Canale.self, forKey: .canaleLavoro)) ?? nil
        tono = (try? c.decodeIfPresent(TonoMessaggio.self, forKey: .tono)) ?? .cordiale
        canale = (try? c.decodeIfPresent(CanaleMessaggio.self, forKey: .canale)) ?? .mail
        oggetto = (try? c.decodeIfPresent(String.self, forKey: .oggetto)) ?? nil
        testo = try c.decode(String.self, forKey: .testo)
        cifre = ((try? c.decodeIfPresent(ElencoTollerante<CifraMessaggio>.self, forKey: .cifre)) ?? nil)?.elementi ?? []
        stato = (try? c.decodeIfPresent(StatoMessaggio.self, forKey: .stato)) ?? .salvato
        apertoIl = (try? c.decodeIfPresent(Date.self, forKey: .apertoIl)) ?? nil
        autore = (try? c.decodeIfPresent(AutoreMessaggio.self, forKey: .autore)) ?? .modelloFisso
        modello = (try? c.decodeIfPresent(String.self, forKey: .modello)) ?? nil
    }
}

/// Le scelte del consulente sui messaggi (Impostazioni › Messaggi, dalla versione 26, lette con tolleranza).
/// Le firme sono dati del consulente: vuote finché non le scrive (allora valgono i dati che Prisma ha già,
/// `ModelliMessaggi.firma`, e se mancano anche quelli il messaggio non ha firma: mai una firma inventata).
struct ImpostazioniMessaggi: Codable, Equatable, Hashable {
    /// La firma dei messaggi del canale Alleanza (per esempio con ruolo e agenzia).
    var firmaAlleanza = ""
    /// La firma dei messaggi della consulenza indipendente.
    var firmaIndipendente = ""
    /// Con quanti giorni d'anticipo una scadenza diventa un messaggio da mandare.
    var giorniScadenza = RegoleMessaggi.giorniScadenzaPredefiniti

    init() {}

    func firma(_ c: Canale) -> String {
        (c == .alleanza ? firmaAlleanza : firmaIndipendente).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private enum CodingKeys: String, CodingKey { case firmaAlleanza, firmaIndipendente, giorniScadenza }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        firmaAlleanza = (try? c.decodeIfPresent(String.self, forKey: .firmaAlleanza)) ?? ""
        firmaIndipendente = (try? c.decodeIfPresent(String.self, forKey: .firmaIndipendente)) ?? ""
        let g = (try? c.decodeIfPresent(Int.self, forKey: .giorniScadenza)) ?? RegoleMessaggi.giorniScadenzaPredefiniti
        giorniScadenza = (1...365).contains(g) ? g : RegoleMessaggi.giorniScadenzaPredefiniti
    }
}
