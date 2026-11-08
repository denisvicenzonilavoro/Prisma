import Foundation
import CoreGraphics

// Pratiche › Moduli · «Compila da solo» (Design/template-luce-specifica.md §7.2, «Luce» giro 10). I modelli di modulo
// sono i PDF vuoti che carica l'utente, per canale, con la mappa dei campi controllata da lui una volta (decisione 61).
// Stanno in Prisma/Moduli/ accanto all'archivio: i PDF (`<id>.pdf`) e l'elenco `moduli.json`, come la Biblioteca. Entrano
// nei backup con la cartella dell'archivio e non vanno mai in «Prisma ovunque» (decisione 44). Nel repository c'è solo il
// fac-simile generato da Prisma (FacSimileModulo.swift), mai un modulo vero.
// Regole fisse:
// - le risposte del questionario di adeguatezza e le dichiarazioni dell'adeguata verifica (titolare effettivo, PEP, scopo
//   del rapporto, origine dei fondi) non sono in `DatoModulo`: le dà il cliente ogni volta (decisione 62);
// - le firme sono solo caselle evidenziate, niente firma elettronica (decisione 63);
// - i moduli Alleanza non si compilano finché la compagnia non lo approva (decisione 60): i modelli sono del canale
//   indipendente.

/// Che modulo è.
enum TipoModulo: String, Codable, CaseIterable, Identifiable {
    case propostaPolizza, privacy, mandato, questionarioAdeguatezza, adeguataVerifica, altro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .propostaPolizza: return "Proposta di polizza"
        case .privacy: return "Informativa privacy"
        case .mandato: return "Mandato di consulenza"
        case .questionarioAdeguatezza: return "Questionario di adeguatezza"
        case .adeguataVerifica: return "Adeguata verifica (antiriciclaggio)"
        case .altro: return "Altro modulo"
        }
    }

    /// Le risposte le dà il cliente (decisione 62): su questi moduli Prisma scrive solo anagrafica e documento.
    var risposteDelCliente: Bool { self == .questionarioAdeguatezza || self == .adeguataVerifica }
}

/// Il tipo di una casella del modulo.
enum TipoCampoModulo: String, Codable, CaseIterable {
    case testo, data, casella, firma
}

/// Da dove viene l'associazione di una casella.
enum OrigineCampoModulo: String, Codable {
    /// Un campo compilabile del PDF (AcroForm), con il suo nome.
    case acroForm
    /// Un'etichetta del PDF piatto riconosciuta dalle regole di Prisma.
    case regole
    /// Proposta da Vera (Qwen sul Mac) leggendo il testo delle etichette: sempre da confermare (decisione 54).
    case vera
    /// Segnata dall'utente nella revisione della mappa.
    case mano

    var nome: String {
        switch self {
        case .acroForm: return "campo del PDF"
        case .regole: return "riconosciuto dalle regole"
        case .vera: return "proposto da Vera"
        case .mano: return "segnato da te"
        }
    }
}

/// Ciò che Prisma sa scrivere in un modulo, con la sua fonte nel dossier. Le risposte del cliente non ci sono.
enum DatoModulo: String, Codable, CaseIterable, Identifiable {
    case cognome, nome, codiceFiscale, dataNascita, luogoNascita, indirizzo, cap, comune, provincia
    case telefono, email, professione, statoCivile
    case documentoTipo, documentoNumero, documentoRilascio, documentoScadenza
    case beneficiari, premio, frequenza, decorrenza, scadenza, capitale, prodotto, numeroContratto
    case iban, luogoData, consulente

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .cognome: return "Cognome"
        case .nome: return "Nome"
        case .codiceFiscale: return "Codice fiscale"
        case .dataNascita: return "Data di nascita"
        case .luogoNascita: return "Luogo di nascita"
        case .indirizzo: return "Indirizzo"
        case .cap: return "CAP"
        case .comune: return "Comune"
        case .provincia: return "Provincia"
        case .telefono: return "Telefono"
        case .email: return "Email"
        case .professione: return "Professione"
        case .statoCivile: return "Stato civile"
        case .documentoTipo: return "Tipo di documento"
        case .documentoNumero: return "Numero del documento"
        case .documentoRilascio: return "Rilascio del documento"
        case .documentoScadenza: return "Scadenza del documento"
        case .beneficiari: return "Beneficiari"
        case .premio: return "Premio"
        case .frequenza: return "Frequenza dei versamenti"
        case .decorrenza: return "Decorrenza"
        case .scadenza: return "Scadenza del contratto"
        case .capitale: return "Capitale assicurato"
        case .prodotto: return "Prodotto"
        case .numeroContratto: return "Numero di contratto"
        case .iban: return "IBAN per l'addebito"
        case .luogoData: return "Luogo e data"
        case .consulente: return "Consulente"
        }
    }

    /// Il nome dentro una frase: minuscola iniziale, tranne le sigle («IBAN per l'addebito», «CAP», «codice fiscale»).
    var nomeInFrase: String {
        let n = nome
        guard n.count > 1, let secondo = n.dropFirst().first, !secondo.isUppercase else { return n }
        return n.prefix(1).lowercased() + n.dropFirst()
    }

    /// Dove Prisma lo prende (per la revisione della mappa e per i dati che mancano).
    var fonte: String {
        switch self {
        case .cognome, .nome: return "dalla scheda fiscale del cliente"
        case .indirizzo, .cap, .comune, .provincia: return "dalla sede nella scheda fiscale"
        case .codiceFiscale, .dataNascita, .luogoNascita, .telefono, .email, .professione, .statoCivile: return "dall'anagrafica"
        case .documentoTipo, .documentoNumero, .documentoRilascio, .documentoScadenza: return "dal documento d'identità in Conformità"
        case .beneficiari, .premio, .frequenza, .decorrenza, .scadenza, .capitale, .prodotto, .numeroContratto: return "dalla proposta"
        case .iban: return "dall'anagrafica, se conservi l'IBAN"
        case .luogoData: return "dal comune della tua sede e dalla data di oggi"
        case .consulente: return "dai tuoi dati di fatturazione"
        }
    }

    /// Anagrafica e documento: gli unici dati che Prisma scrive sui moduli con le risposte del cliente (decisione 62).
    var anagrafico: Bool {
        switch self {
        case .cognome, .nome, .codiceFiscale, .dataNascita, .luogoNascita, .indirizzo, .cap, .comune, .provincia,
             .documentoTipo, .documentoNumero, .documentoRilascio, .documentoScadenza, .luogoData, .consulente:
            return true
        default:
            return false
        }
    }

    /// Il tipo di casella atteso.
    var tipoCampo: TipoCampoModulo {
        switch self {
        case .dataNascita, .documentoRilascio, .documentoScadenza, .decorrenza, .scadenza: return .data
        default: return .testo
        }
    }
}

/// Un modello di modulo: il PDF vuoto dell'utente e la mappa dei suoi campi.
struct ModelloModulo: Identifiable, Codable, Hashable {
    /// Una casella del modulo, in punti PDF sulla sua pagina (origine in basso a sinistra, come PDFKit).
    struct Campo: Identifiable, Codable, Hashable {
        var id: String
        /// Da 0.
        var pagina: Int
        var riquadro: CGRect
        /// Il nome del campo compilabile del PDF, se c'è.
        var nomeAcroForm: String?
        /// Il testo vicino alla casella, come letto.
        var etichetta: String
        /// A cosa è associata; nil = da lasciare vuota.
        var dato: DatoModulo?
        var tipo: TipoCampoModulo
        var origine: OrigineCampoModulo
        /// Proposta da confermare nella revisione della mappa (regole sul PDF piatto e Vera).
        var daConfermare: Bool
        /// Una risposta del cliente (questionario, titolare effettivo, PEP, origine dei fondi…): mai riempita (decisione 62).
        var risposta: Bool

        init(id: String = "campo-\(UUID().uuidString.prefix(8).lowercased())", pagina: Int, riquadro: CGRect,
             nomeAcroForm: String? = nil, etichetta: String, dato: DatoModulo? = nil, tipo: TipoCampoModulo = .testo,
             origine: OrigineCampoModulo, daConfermare: Bool = false, risposta: Bool = false) {
            self.id = id
            self.pagina = pagina
            self.riquadro = riquadro
            self.nomeAcroForm = nomeAcroForm
            self.etichetta = etichetta
            self.dato = dato
            self.tipo = tipo
            self.origine = origine
            self.daConfermare = daConfermare
            self.risposta = risposta
        }

        private enum CodingKeys: String, CodingKey {
            case id, pagina, riquadro, nomeAcroForm, etichetta, dato, tipo, origine, daConfermare, risposta
        }

        /// Lettura tollerante: un dato sconosciuto (di una versione più nuova) diventa «da lasciare vuoto».
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            pagina = try c.decodeIfPresent(Int.self, forKey: .pagina) ?? 0
            riquadro = try c.decode(CGRect.self, forKey: .riquadro)
            nomeAcroForm = try c.decodeIfPresent(String.self, forKey: .nomeAcroForm)
            etichetta = try c.decodeIfPresent(String.self, forKey: .etichetta) ?? ""
            dato = (try? c.decodeIfPresent(DatoModulo.self, forKey: .dato)) ?? nil
            tipo = (try? c.decodeIfPresent(TipoCampoModulo.self, forKey: .tipo)) ?? .testo
            origine = (try? c.decodeIfPresent(OrigineCampoModulo.self, forKey: .origine)) ?? .mano
            daConfermare = try c.decodeIfPresent(Bool.self, forKey: .daConfermare) ?? false
            risposta = try c.decodeIfPresent(Bool.self, forKey: .risposta) ?? false
        }

        var firma: Bool { tipo == .firma }
    }

    var id: String
    /// «Proposta di polizza».
    var titolo: String
    var tipo: TipoModulo
    /// Il canale del modulo: oggi sempre l'indipendente (decisione 60). nil = tutti e due (per i moduli di prima).
    var canale: Canale?
    /// Vuoto = tutti i prodotti del canale.
    var prodottoIds: [String]
    /// Il PDF vuoto in <archivio>/Moduli/.
    var file: String
    var pagine: Int
    var campi: [Campo]
    var caricatoIl: Date
    /// La versione stampata sul modulo, se c'è.
    var versione: String?
    /// La mappa dei campi è stata controllata dall'utente (una volta per modello).
    var mappaConfermata: Bool
    /// Fac-simile generato da Prisma, caricato con i clienti di prova (etichetta «dati di prova»).
    var diProva: Bool?

    init(id: String = "modulo-\(UUID().uuidString.prefix(8).lowercased())", titolo: String, tipo: TipoModulo,
         canale: Canale? = .indipendente, file: String, pagine: Int, campi: [Campo], caricatoIl: Date = Date(),
         versione: String? = nil, mappaConfermata: Bool = false, diProva: Bool? = nil) {
        self.id = id
        self.titolo = titolo
        self.tipo = tipo
        self.canale = canale
        self.prodottoIds = []
        self.file = file
        self.pagine = pagine
        self.campi = campi
        self.caricatoIl = caricatoIl
        self.versione = versione
        self.mappaConfermata = mappaConfermata
        self.diProva = diProva
    }

    private enum CodingKeys: String, CodingKey {
        case id, titolo, tipo, canale, prodottoIds, file, pagine, campi, caricatoIl, versione, mappaConfermata, diProva
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        titolo = try c.decodeIfPresent(String.self, forKey: .titolo) ?? "Modulo"
        tipo = (try? c.decodeIfPresent(TipoModulo.self, forKey: .tipo)) ?? .altro
        canale = (try? c.decodeIfPresent(Canale.self, forKey: .canale)) ?? nil
        prodottoIds = (try? c.decodeIfPresent([String].self, forKey: .prodottoIds)) ?? []
        file = try c.decode(String.self, forKey: .file)
        pagine = try c.decodeIfPresent(Int.self, forKey: .pagine) ?? 1
        // Una casella illeggibile si salta, le altre restano
        campi = ((try? c.decodeIfPresent(ElencoTollerante<Campo>.self, forKey: .campi)) ?? nil)?.elementi ?? []
        caricatoIl = try c.decodeIfPresent(Date.self, forKey: .caricatoIl) ?? Date()
        versione = try c.decodeIfPresent(String.self, forKey: .versione)
        mappaConfermata = try c.decodeIfPresent(Bool.self, forKey: .mappaConfermata) ?? false
        diProva = try c.decodeIfPresent(Bool.self, forKey: .diProva)
    }

    /// I moduli Alleanza non si compilano in Prisma finché la compagnia non lo approva (decisione 60).
    var compilabile: Bool { canale != .alleanza }

    /// Le caselle che Prisma sa riempire (con un dato, non firme né risposte del cliente).
    var campiConDato: [Campo] { campi.filter { $0.dato != nil && !$0.firma && !$0.risposta } }
    var firme: [Campo] { campi.filter(\.firma) }
    var risposte: [Campo] { campi.filter(\.risposta) }

    /// «PDF caricato da te», «Fac-simile di prova», «Mappa da controllare».
    var sottotitolo: String {
        if diProva == true { return "Fac-simile di prova" }
        return mappaConfermata ? "PDF caricato da te" : "PDF caricato da te · mappa da controllare"
    }
}

/// Il modulo compilato e salvato nel dossier (versione 27): sta nel `Documento` del cliente (tipo `.modulo`), con il
/// modello da cui viene, i dati che mancavano (solo i nomi, mai i valori) e le firme da raccogliere.
struct CompilazioneModulo: Codable, Hashable {
    var modelloId: String
    var titoloModello: String
    var compilatoIl: Date
    /// I dati che mancavano al salvataggio.
    var mancanti: [DatoModulo]
    /// Le caselle della firma da raccogliere a penna (o con gli strumenti della compagnia).
    var firme: Int
    var firmeRaccolte: Bool
    /// Le caselle corrette a mano in questa compilazione (non cambiano il dossier).
    var correzioni: Int

    init(modelloId: String, titoloModello: String, compilatoIl: Date, mancanti: [DatoModulo], firme: Int,
         firmeRaccolte: Bool = false, correzioni: Int = 0) {
        self.modelloId = modelloId
        self.titoloModello = titoloModello
        self.compilatoIl = compilatoIl
        self.mancanti = mancanti
        self.firme = firme
        self.firmeRaccolte = firmeRaccolte
        self.correzioni = correzioni
    }

    private enum CodingKeys: String, CodingKey {
        case modelloId, titoloModello, compilatoIl, mancanti, firme, firmeRaccolte, correzioni
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        modelloId = try c.decodeIfPresent(String.self, forKey: .modelloId) ?? ""
        titoloModello = try c.decodeIfPresent(String.self, forKey: .titoloModello) ?? "Modulo"
        compilatoIl = try c.decodeIfPresent(Date.self, forKey: .compilatoIl) ?? Date()
        // Un dato sconosciuto si salta
        mancanti = ((try? c.decodeIfPresent([String].self, forKey: .mancanti)) ?? nil)?.compactMap(DatoModulo.init(rawValue:)) ?? []
        firme = try c.decodeIfPresent(Int.self, forKey: .firme) ?? 0
        firmeRaccolte = try c.decodeIfPresent(Bool.self, forKey: .firmeRaccolte) ?? false
        correzioni = try c.decodeIfPresent(Int.self, forKey: .correzioni) ?? 0
    }
}

/// La cartella Moduli/ accanto all'archivio: i PDF dei modelli e `moduli.json`.
enum ArchivioModuli {
    static let nomeCartella = "Moduli"
    static let nomeElenco = "moduli.json"

    static func cartella(in base: URL) -> URL { base.appendingPathComponent(nomeCartella, isDirectory: true) }
    static var cartella: URL { cartella(in: Archivio.cartella) }

    static func codificatore() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }

    static func decodificatore() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    /// L'elenco dei modelli (vuoto se non c'è o è illeggibile; un modello rovinato si scarta, gli altri restano).
    static func leggi(in base: URL) -> [ModelloModulo] {
        guard let d = try? Data(contentsOf: cartella(in: base).appendingPathComponent(nomeElenco)) else { return [] }
        return ((try? decodificatore().decode(ElencoTollerante<ModelloModulo>.self, from: d)) ?? nil)?.elementi ?? []
    }

    static func scrivi(_ modelli: [ModelloModulo], in base: URL) throws {
        let c = cartella(in: base)
        try FileManager.default.createDirectory(at: c, withIntermediateDirectories: true)
        try codificatore().encode(modelli).write(to: c.appendingPathComponent(nomeElenco), options: Archivio.opzioniScrittura)
    }

    /// Il PDF vuoto di un modello.
    static func pdf(_ m: ModelloModulo, in base: URL) -> URL { cartella(in: base).appendingPathComponent(m.file) }
}
