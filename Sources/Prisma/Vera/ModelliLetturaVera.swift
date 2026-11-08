import Foundation

// I dati della fase 3 di Vera (Vera/BRIEF.md, «Lettura e controllo»): le promesse ai clienti (8), i confronti tra due
// documenti (11), le coperture lette da una polizza (12) e il resoconto dell'incontro (16). Stanno nell'archivio
// (DatiPrisma.promesse, confrontiDocumenti, coperture; Incontro.resoconto), entrano nel backup e si leggono con
// tolleranza. La seconda lettura (10) non salva niente: avvisa prima che un testo esca.

// MARK: - 8 · Le promesse

/// Un impegno preso con un cliente, con la frase da cui viene. Non è una «promessa di rendimento»: quelle sono vietate
/// (MessaggiVera.promesse); qui sono le cose che il consulente ha detto di fare («le mando il confronto entro venerdì»).
struct PromessaCliente: Codable, Identifiable, Equatable {
    enum Fonte: String, Codable { case nota, incontro, resoconto, messaggio, verbale }
    enum Stato: String, Codable { case aperta, fatta, rimandata, scartata }

    var id = "promessa-\(UUID().uuidString.prefix(8).lowercased())"
    var clienteId: String
    /// «Mandare a Marco il confronto per gli studi di Tommaso».
    var testo: String
    /// La frase esatta da cui viene (si ritrova sempre nella fonte).
    var frase: String
    var fonte: Fonte
    var fonteId: String
    /// «dalla nota del 12 settembre», «dal messaggio del 6 novembre».
    var fonteEtichetta: String
    var creataIl = Date()
    var scadenza: Date?
    /// Il quando con le parole della frase («entro venerdì 6»).
    var quando: String?
    var stato = Stato.aperta
    var rimandataAl: Date?
    var fattaIl: Date?

    /// La scadenza che conta: quella rimandata, se c'è.
    var scadenzaAttuale: Date? { rimandataAl ?? scadenza }

    private enum CodingKeys: String, CodingKey {
        case id, clienteId, testo, frase, fonte, fonteId, fonteEtichetta, creataIl, scadenza, quando, stato, rimandataAl, fattaIl
    }

    init(clienteId: String, testo: String, frase: String, fonte: Fonte, fonteId: String, fonteEtichetta: String,
         scadenza: Date? = nil, quando: String? = nil) {
        self.clienteId = clienteId
        self.testo = testo
        self.frase = frase
        self.fonte = fonte
        self.fonteId = fonteId
        self.fonteEtichetta = fonteEtichetta
        self.scadenza = scadenza
        self.quando = quando
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        testo = (try? c.decodeIfPresent(String.self, forKey: .testo)) ?? ""
        frase = (try? c.decodeIfPresent(String.self, forKey: .frase)) ?? ""
        fonte = (try? c.decodeIfPresent(Fonte.self, forKey: .fonte)) ?? .nota
        fonteId = (try? c.decodeIfPresent(String.self, forKey: .fonteId)) ?? ""
        fonteEtichetta = (try? c.decodeIfPresent(String.self, forKey: .fonteEtichetta)) ?? ""
        creataIl = (try? c.decodeIfPresent(Date.self, forKey: .creataIl)) ?? Date.distantPast
        scadenza = (try? c.decodeIfPresent(Date.self, forKey: .scadenza)) ?? nil
        quando = (try? c.decodeIfPresent(String.self, forKey: .quando)) ?? nil
        stato = (try? c.decodeIfPresent(Stato.self, forKey: .stato)) ?? .aperta
        rimandataAl = (try? c.decodeIfPresent(Date.self, forKey: .rimandataAl)) ?? nil
        fattaIl = (try? c.decodeIfPresent(Date.self, forKey: .fattaIl)) ?? nil
    }
}

// MARK: - 11 · Trova le differenze

/// Una voce confrontata tra due documenti.
struct RigaDifferenza: Codable, Equatable, Identifiable {
    enum Esito: String, Codable { case migliora, peggiora, cambia, uguale, costaDiPiu, nuova, tolta }

    var id: String { voce }
    var voce: String
    var prima: String
    var ora: String
    var esito: Esito
    var paginaPrima: Int?
    var paginaOra: Int?

    var etichetta: String {
        switch esito {
        case .migliora: return "migliora"
        case .peggiora: return "peggiora"
        case .cambia: return "cambia"
        case .uguale: return "uguale"
        case .costaDiPiu: return "costa di più"
        case .nuova: return "nuova"
        case .tolta: return "tolta"
        }
    }
}

/// Il confronto salvato nella scheda del cliente («Metti il confronto nella scheda»).
struct ConfrontoDocumenti: Codable, Equatable, Identifiable {
    var id = "confronto-\(UUID().uuidString.prefix(8).lowercased())"
    var clienteId: String
    var primaId: String
    var oraId: String
    var titoloPrima: String
    var titoloOra: String
    var righe: [RigaDifferenza]
    /// La sintesi dell'effetto sul cliente (di Prisma o riscritta da Qwen con le stesse cifre).
    var sintesi: String
    var creatoIl = Date()

    /// Le righe che cambiano davvero.
    var cambiate: [RigaDifferenza] { righe.filter { $0.esito != .uguale } }
}

// MARK: - 12 · Cosa non copre

/// Un limite della copertura letto da una polizza, con il suo articolo.
struct LimiteCopertura: Codable, Equatable, Identifiable {
    enum Tipo: String, Codable, CaseIterable {
        case esclusione, carenza, franchigia, massimale

        var titolo: String {
            switch self {
            case .esclusione: return "Non copre"
            case .carenza: return "Carenze"
            case .franchigia: return "Franchigie"
            case .massimale: return "Massimali"
            }
        }
    }

    var id = "limite-\(UUID().uuidString.prefix(8).lowercased())"
    var tipo: Tipo
    /// Per il consulente («Gli sport a livello agonistico»).
    var voce: String
    /// Con le parole del cliente («Se Tommaso si fa male in una partita di campionato, la polizza non paga»).
    var perCliente: String
    /// L'articolo («3.1», «12-bis») e la pagina: senza articolo la voce non esiste.
    var articolo: String
    var pagina: Int
    /// La frase dell'articolo da cui viene.
    var frase: String
}

/// Le coperture lette da una polizza (per documento).
struct CoperturaPolizza: Codable, Equatable, Identifiable {
    var id: String { documentoId }
    var documentoId: String
    var clienteId: String
    var titolo: String
    var voci: [LimiteCopertura]
    var articoliLetti: Int
    var creataIl = Date()
    /// Le voci riscritte da Qwen (false: solo le regole di Prisma).
    var conQwen = false

    func voci(_ t: LimiteCopertura.Tipo) -> [LimiteCopertura] { voci.filter { $0.tipo == t } }
}

// MARK: - 16 · Il resoconto dell'incontro

struct SezioneResoconto: Codable, Hashable {
    var titolo: String
    var righe: [String]
}

/// Il resoconto di un incontro: le sezioni nel formato del consulente (o in breve), da dove viene, chi l'ha firmato.
struct ResocontoIncontro: Codable, Hashable {
    enum Formato: String, Codable { case completo, breve }
    enum Fonte: String, Codable { case appunti, copilota, notaVocale }

    var titolo: String
    var sezioni: [SezioneResoconto]
    var breve: [String]
    var formato = Formato.completo
    var fonti: [Fonte]
    var creatoIl = Date()
    /// Riscritto da Qwen (con le stesse cifre) o composto da Prisma.
    var conQwen = false
    var firmatoIl: Date?
    var firmatoDa: String?
    /// Il PDF firmato nei Documenti del cliente.
    var documentoId: String?
    /// Il consenso alla registrazione, com'era quando è stata trascritta la nota vocale.
    var consenso: ConsensoCopilota?
    /// Il testo trascritto della nota vocale (l'audio non si salva mai).
    var trascrizione: String?

    var firmato: Bool { firmatoIl != nil }

    var sezioniMostrate: [SezioneResoconto] {
        formato == .breve ? [SezioneResoconto(titolo: "In breve", righe: breve)] : sezioni
    }
}

// MARK: - 10 · La seconda lettura

/// Un avviso della seconda lettura.
struct AvvisoLettura: Codable, Equatable, Identifiable {
    enum Gravita: Int, Codable { case rosso = 0, arancio = 1, verde = 2 }
    enum Tipo: String, Codable { case parola, numero, allegato, profilo }

    var id: String { "\(tipo.rawValue)-\(titolo)-\(dettaglio)" }
    var tipo: Tipo
    var gravita: Gravita
    var titolo: String
    var dettaglio: String
    /// Il pezzo di testo da correggere e la correzione proposta (nil se non si corregge nel testo).
    var trovato: String?
    var correzione: String?
}

/// L'esito della seconda lettura: avvisi in ordine di gravità. La valutazione finale resta al consulente.
struct EsitoSecondaLettura: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    var oggetto: String
    var avvisi: [AvvisoLettura]

    var daGuardare: [AvvisoLettura] { avvisi.filter { $0.gravita != .verde } }
    var pulito: Bool { daGuardare.isEmpty }

    /// Il testo con tutte le correzioni proposte applicate.
    func corretto(_ testo: String) -> String {
        avvisi.reduce(testo) { t, a in
            guard let x = a.trovato, let y = a.correzione, !x.isEmpty else { return t }
            // Una cifra si cambia solo intera: «5%» non tocca «15%» né «1,5%»; le parole solo come parole
            let inizio = x.first?.isNumber == true ? #"(?<![\d.,])"# : #"(?<![\p{L}])"#
            let fine = x.last?.isNumber == true ? #"(?![\d.,]?\d)"# : #"(?![\p{L}])"#
            let modello = inizio + NSRegularExpression.escapedPattern(for: x) + fine
            return t.replacingOccurrences(of: modello, with: NSRegularExpression.escapedTemplate(for: y), options: [.regularExpression, .caseInsensitive])
        }
    }
}
