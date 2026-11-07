import Foundation

// Le aziende dei clienti imprenditori (Design/template-luce-specifica.md §9.3.5 punto 1, «Luce» giro 7; decisioni 67 e 96).
// - Un cliente può avere più aziende (`Cliente.aziende`, versione 27 dell'archivio, letto con tolleranza: un'azienda
//   illeggibile si scarta, le altre restano). La scheda «L'azienda» del dossier c'è quando ce n'è almeno una.
// - Tutti i dati li inserisce l'utente: nessuna cifra predefinita, nessuna fonte esterna (niente visure: Prisma non va in
//   rete). Dove un dato manca la scheda lo dice.
// - Per le quattro aree (persona chiave, TFM, welfare, passaggio dell'impresa) solo dati e stato: nessuna regola né calcolo
//   fiscale o civilistico (decisione 67). Le liste del welfare e della continuità le sceglie l'utente; Prisma propone
//   soltanto dei titoli da aggiungere (`VoceAzienda.propostePerWelfare`, `propostePerContinuita`).

/// La forma giuridica dell'azienda.
enum FormaAzienda: String, Codable, CaseIterable, Identifiable {
    case srl, spa, snc, sas, ditta, altro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .srl: return "S.r.l."
        case .spa: return "S.p.A."
        case .snc: return "S.n.c."
        case .sas: return "S.a.s."
        case .ditta: return "Ditta individuale"
        case .altro: return "Altro"
        }
    }
}

/// Una voce di una lista scelta dall'utente (welfare, passi della continuità): il titolo e se è già fatta.
struct VoceAzienda: Identifiable, Codable, Hashable {
    var id: String
    var titolo: String
    var fatta: Bool

    init(id: String = UUID().uuidString, titolo: String, fatta: Bool = false) {
        self.id = id
        self.titolo = titolo
        self.fatta = fatta
    }

    private enum CodingKeys: String, CodingKey { case id, titolo, fatta }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        titolo = try c.decode(String.self, forKey: .titolo)
        fatta = (try? c.decodeIfPresent(Bool.self, forKey: .fatta)) ?? false
    }

    /// I titoli che il modulo propone per il welfare (dalla checklist del §5.2.3): si aggiungono solo se l'utente li sceglie.
    static let propostePerWelfare = ["Buoni pasto", "Premi di risultato", "Previdenza complementare per i dipendenti",
                                     "Assistenza sanitaria integrativa"]
    /// I titoli che il modulo propone per il passaggio dell'impresa (§5.2.3): la lista vera la decide l'utente.
    static let propostePerContinuita = ["Successore indicato", "Piano di continuità", "Patto di famiglia valutato",
                                        "Coperture per i soci", "Statuto e clausole valutati"]
}

/// La persona chiave: quanti mesi di fatturato perderebbe l'azienda se il cliente si fermasse (una valutazione
/// dell'utente, non un calcolo) e quali posizioni del cliente la coprono (scelte dall'utente).
struct PersonaChiave: Codable, Hashable {
    /// Mesi di fatturato a rischio, scritti dall'utente. nil = non indicati.
    var mesiARischio: Double?
    /// Le posizioni del cliente che coprono la persona chiave («key man»), scelte dall'utente.
    var posizioniCollegate: [String] = []

    init(mesiARischio: Double? = nil, posizioniCollegate: [String] = []) {
        self.mesiARischio = mesiARischio
        self.posizioniCollegate = posizioniCollegate
    }

    private enum CodingKeys: String, CodingKey { case mesiARischio, posizioniCollegate }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mesiARischio = (try? c.decodeIfPresent(Double.self, forKey: .mesiARischio)) ?? nil
        posizioniCollegate = (try? c.decodeIfPresent([String].self, forKey: .posizioniCollegate)) ?? []
    }

    var vuota: Bool { mesiARischio == nil && posizioniCollegate.isEmpty }
}

/// Il trattamento di fine mandato degli amministratori: solo lo stato, nessun calcolo fiscale (decisione 67).
struct StatoTFM: Codable, Hashable {
    /// Accantonato sì o no. nil = non indicato.
    var accantonato: Bool?
    /// L'importo accantonato, se l'utente lo scrive.
    var importo: Double?
    var nota: String = ""

    init(accantonato: Bool? = nil, importo: Double? = nil, nota: String = "") {
        self.accantonato = accantonato
        self.importo = importo
        self.nota = nota
    }

    private enum CodingKeys: String, CodingKey { case accantonato, importo, nota }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accantonato = (try? c.decodeIfPresent(Bool.self, forKey: .accantonato)) ?? nil
        importo = (try? c.decodeIfPresent(Double.self, forKey: .importo)) ?? nil
        nota = (try? c.decodeIfPresent(String.self, forKey: .nota)) ?? ""
    }

    var vuoto: Bool { accantonato == nil && importo == nil && nota.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

/// Una lista di voci scelte dall'utente (welfare aziendale, passi della continuità), letta con tolleranza.
struct ListaAzienda: Codable, Hashable {
    var voci: [VoceAzienda] = []
    var nota: String = ""

    init(voci: [VoceAzienda] = [], nota: String = "") {
        self.voci = voci
        self.nota = nota
    }

    private enum CodingKeys: String, CodingKey { case voci, nota }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        voci = ((try? c.decodeIfPresent(ElencoTollerante<VoceAzienda>.self, forKey: .voci)) ?? nil)?.elementi ?? []
        nota = (try? c.decodeIfPresent(String.self, forKey: .nota)) ?? ""
    }

    var vuota: Bool { voci.isEmpty && nota.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

/// Un'azienda del cliente.
struct AziendaCliente: Identifiable, Codable, Hashable {
    var id: String
    var ragioneSociale: String
    var forma: FormaAzienda?
    var partitaIVA: String?
    var settore: String?
    var dipendenti: Int?
    /// Fatturato dell'ultimo anno (€) e l'anno a cui si riferisce.
    var fatturato: Double?
    var annoFatturato: Int?
    var utile: Double?
    /// La quota del cliente, in % (0…100).
    var quota: Double?
    var amministratore: Bool?
    /// Titolare (ditta individuale).
    var titolare: Bool?
    /// Compensi e utili che il cliente ne ricava all'anno (€).
    var redditoDalCliente: Double?
    var personaChiave: PersonaChiave?
    var tfm: StatoTFM?
    /// Le voci di welfare che l'utente considera, con quelle già attive.
    var welfare: ListaAzienda?
    /// I passi della continuità che l'utente considera, con quelli già fatti.
    var continuita: ListaAzienda?
    var nota: String = ""
    /// Azienda dei dati di prova (il piede della scheda lo dice). nil = vera.
    var diProva: Bool?

    init(id: String = UUID().uuidString, ragioneSociale: String) {
        self.id = id
        self.ragioneSociale = ragioneSociale
    }

    private enum CodingKeys: String, CodingKey {
        case id, ragioneSociale, forma, partitaIVA, settore, dipendenti, fatturato, annoFatturato, utile, quota
        case amministratore, titolare, redditoDalCliente, personaChiave, tfm, welfare, continuita, nota, diProva
    }

    /// Lettura tollerante: senza id o ragione sociale l'azienda si scarta (`ElencoTollerante`); ogni altro campo
    /// illeggibile diventa «non indicato» e non fa perdere l'azienda.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        ragioneSociale = try c.decode(String.self, forKey: .ragioneSociale)
        forma = (try? c.decodeIfPresent(FormaAzienda.self, forKey: .forma)) ?? nil
        partitaIVA = (try? c.decodeIfPresent(String.self, forKey: .partitaIVA)) ?? nil
        settore = (try? c.decodeIfPresent(String.self, forKey: .settore)) ?? nil
        dipendenti = ((try? c.decodeIfPresent(Int.self, forKey: .dipendenti)) ?? nil).flatMap { $0 >= 0 ? $0 : nil }
        fatturato = ((try? c.decodeIfPresent(Double.self, forKey: .fatturato)) ?? nil).flatMap { $0 >= 0 ? $0 : nil }
        annoFatturato = (try? c.decodeIfPresent(Int.self, forKey: .annoFatturato)) ?? nil
        utile = (try? c.decodeIfPresent(Double.self, forKey: .utile)) ?? nil
        quota = ((try? c.decodeIfPresent(Double.self, forKey: .quota)) ?? nil).flatMap { (0...100).contains($0) ? $0 : nil }
        amministratore = (try? c.decodeIfPresent(Bool.self, forKey: .amministratore)) ?? nil
        titolare = (try? c.decodeIfPresent(Bool.self, forKey: .titolare)) ?? nil
        redditoDalCliente = (try? c.decodeIfPresent(Double.self, forKey: .redditoDalCliente)) ?? nil
        personaChiave = (try? c.decodeIfPresent(PersonaChiave.self, forKey: .personaChiave)) ?? nil
        tfm = (try? c.decodeIfPresent(StatoTFM.self, forKey: .tfm)) ?? nil
        welfare = (try? c.decodeIfPresent(ListaAzienda.self, forKey: .welfare)) ?? nil
        continuita = (try? c.decodeIfPresent(ListaAzienda.self, forKey: .continuita)) ?? nil
        nota = (try? c.decodeIfPresent(String.self, forKey: .nota)) ?? ""
        diProva = (try? c.decodeIfPresent(Bool.self, forKey: .diProva)) ?? nil
    }

    /// Il nome da mostrare: la ragione sociale, o «Azienda senza nome».
    var nomeMostrato: String {
        let n = ragioneSociale.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Azienda senza nome" : n
    }

    /// Gli insiemi vuoti tornano nil (il modulo li crea alla prima scrittura).
    mutating func ripulisci() {
        ragioneSociale = ragioneSociale.trimmingCharacters(in: .whitespacesAndNewlines)
        if let p = partitaIVA?.trimmingCharacters(in: .whitespacesAndNewlines) { partitaIVA = p.isEmpty ? nil : p }
        if let s = settore?.trimmingCharacters(in: .whitespacesAndNewlines) { settore = s.isEmpty ? nil : s }
        if personaChiave?.vuota == true { personaChiave = nil }
        if tfm?.vuoto == true { tfm = nil }
        welfare?.voci.removeAll { $0.titolo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        continuita?.voci.removeAll { $0.titolo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if welfare?.vuota == true { welfare = nil }
        if continuita?.vuota == true { continuita = nil }
    }
}

/// Le aziende di prova (dichiarate «di prova»): quella del template sul cliente di prova Marco Bianchi e una con il
/// solo nome per un cliente fittizio (Francesco Moretti, imprenditore edile).
enum AziendeDiProva {
    static let idBianchi = "azienda-prova-bianchi-serramenti"
    static let idMoretti = "azienda-prova-moretti-costruzioni"

    /// «Bianchi Serramenti S.r.l.», 14 dipendenti, Marco socio al 70% e amministratore, 2,1 mln € nel 2025 (template,
    /// §9.3.5 punto 8). Le liste del welfare e della continuità sono di prova: le vere le sceglie l'utente.
    static func bianchiSerramenti() -> AziendaCliente {
        var a = AziendaCliente(id: idBianchi, ragioneSociale: "Bianchi Serramenti S.r.l.")
        a.forma = .srl
        a.settore = "Serramenti"
        a.dipendenti = 14
        a.fatturato = 2_100_000
        a.annoFatturato = 2025
        a.quota = 70
        a.amministratore = true
        a.personaChiave = PersonaChiave(mesiARischio: 6)
        a.tfm = StatoTFM(accantonato: false)
        a.welfare = ListaAzienda(voci: [
            VoceAzienda(id: "welfare-prova-buoni", titolo: "Buoni pasto", fatta: true),
            VoceAzienda(id: "welfare-prova-premi", titolo: "Premi di risultato"),
            VoceAzienda(id: "welfare-prova-previdenza", titolo: "Previdenza complementare per i dipendenti"),
        ])
        a.continuita = ListaAzienda(voci: [
            VoceAzienda(id: "continuita-prova-successore", titolo: "Successore indicato"),
            VoceAzienda(id: "continuita-prova-piano", titolo: "Piano di continuità"),
            VoceAzienda(id: "continuita-prova-patto", titolo: "Patto di famiglia valutato"),
            VoceAzienda(id: "continuita-prova-soci", titolo: "Coperture per i soci"),
            VoceAzienda(id: "continuita-prova-statuto", titolo: "Statuto e clausole valutati", fatta: true),
        ])
        a.diProva = true
        return a
    }

    /// Un'azienda con il solo nome (lo stato «da completare»).
    static func morettiCostruzioni() -> AziendaCliente {
        var a = AziendaCliente(id: idMoretti, ragioneSociale: "Moretti Costruzioni")
        a.diProva = true
        return a
    }
}
