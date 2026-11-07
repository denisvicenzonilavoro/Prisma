import Foundation

// I portafogli modello del radar (Design/template-luce-specifica.md §8.3, «Luce» giro 2): nome, colore del tema, pesi
// delle quattro classi della composizione (azionario, obbligazionario, gestione separata, liquidità, somma 100) e
// tolleranza. Li scrive l'utente in Impostazioni › Portafogli modello: Prisma non ne inventa (i tre del template sono
// solo nei dati di prova). Il modello di ogni cliente è `Cliente.modelloId`, scelto dall'utente; la tolleranza generale
// è `Impostazioni.tolleranzaRadar` (nil = non ancora scritta: senza, nessuno è «fuori»). Tutto letto con tolleranza
// nella versione 27 dell'archivio.

/// Il colore di un modello: un nome di colore del tema, mai un esadecimale libero (`Tema.Apple.Posizioni.Radar.colore`).
enum ColoreModello: String, Codable, CaseIterable, Identifiable {
    case verde, blu, viola, arancio, rosso, azzurro

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .verde: return "Verde"
        case .blu: return "Blu"
        case .viola: return "Viola"
        case .arancio: return "Arancio"
        case .rosso: return "Rosso"
        case .azzurro: return "Azzurro"
        }
    }
}

/// I pesi delle quattro classi, in punti percentuali (0–100, somma 100).
struct PesiModello: Codable, Equatable {
    var azionario: Double = 0
    var obbligazionario: Double = 0
    var gestioneSeparata: Double = 0
    var liquidita: Double = 0

    init(azionario: Double = 0, obbligazionario: Double = 0, gestioneSeparata: Double = 0, liquidita: Double = 0) {
        self.azionario = azionario
        self.obbligazionario = obbligazionario
        self.gestioneSeparata = gestioneSeparata
        self.liquidita = liquidita
    }

    subscript(classe: ComposizioneInvestimenti360.Classe) -> Double {
        get {
            switch classe {
            case .azionario: return azionario
            case .obbligazionario: return obbligazionario
            case .gestioneSeparata: return gestioneSeparata
            case .liquidita: return liquidita
            }
        }
        set {
            switch classe {
            case .azionario: azionario = newValue
            case .obbligazionario: obbligazionario = newValue
            case .gestioneSeparata: gestioneSeparata = newValue
            case .liquidita: liquidita = newValue
            }
        }
    }

    var somma: Double { azionario + obbligazionario + gestioneSeparata + liquidita }
    /// La somma fa 100 (al centesimo di punto).
    var completi: Bool { abs(somma - 100) < 0.01 }

    private enum CodingKeys: String, CodingKey { case azionario, obbligazionario, gestioneSeparata, liquidita }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        azionario = (try? c.decodeIfPresent(Double.self, forKey: .azionario)) ?? 0
        obbligazionario = (try? c.decodeIfPresent(Double.self, forKey: .obbligazionario)) ?? 0
        gestioneSeparata = (try? c.decodeIfPresent(Double.self, forKey: .gestioneSeparata)) ?? 0
        liquidita = (try? c.decodeIfPresent(Double.self, forKey: .liquidita)) ?? 0
    }
}

struct PortafoglioModello: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var nome: String
    var colore: ColoreModello
    var pesi: PesiModello
    /// La tolleranza di questo modello, in punti; nil = quella generale (`Impostazioni.tolleranzaRadar`).
    var tolleranza: Double?
    var note = ""

    init(id: String = UUID().uuidString, nome: String, colore: ColoreModello, pesi: PesiModello,
         tolleranza: Double? = nil, note: String = "") {
        self.id = id
        self.nome = nome
        self.colore = colore
        self.pesi = pesi
        self.tolleranza = tolleranza
        self.note = note
    }

    private enum CodingKeys: String, CodingKey { case id, nome, colore, pesi, tolleranza, note }

    /// Lettura tollerante: un colore che questo Prisma non conosce torna verde, campi mancanti vuoti.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        nome = (try? c.decodeIfPresent(String.self, forKey: .nome)) ?? ""
        colore = (try? c.decodeIfPresent(ColoreModello.self, forKey: .colore)) ?? .verde
        pesi = (try? c.decodeIfPresent(PesiModello.self, forKey: .pesi)) ?? PesiModello()
        tolleranza = (try? c.decodeIfPresent(Double.self, forKey: .tolleranza)) ?? nil
        note = (try? c.decodeIfPresent(String.self, forKey: .note)) ?? ""
    }
}

/// Il segno lasciato su una bozza di riequilibrio (`Posizione.riequilibrio`): da quale modello e a che distanza è nata.
/// Serve al radar per dire «proposta pronta» finché la bozza resta una bozza.
struct OrigineRiequilibrio: Codable, Hashable {
    var modelloId: String
    /// La distanza dal modello quando la bozza è nata, in punti.
    var distanza: Double
    var creataIl: Date
}

// MARK: - Dati di prova (solo per «Carica i dati di prova»: Design/template-luce-specifica.md §8.3.6)

enum PortafogliModelloDiProva {
    /// I tre modelli del template (20/55/20/5, 40/40/12/8, 65/25/0/10): dimostrativi, segnati «dati di prova».
    static let prudente = PortafoglioModello(id: "modello-prova-prudente", nome: "Prudente", colore: .verde,
                                             pesi: PesiModello(azionario: 20, obbligazionario: 55, gestioneSeparata: 20, liquidita: 5),
                                             note: "Dati di prova")
    static let equilibrato = PortafoglioModello(id: "modello-prova-equilibrato", nome: "Equilibrato", colore: .blu,
                                                pesi: PesiModello(azionario: 40, obbligazionario: 40, gestioneSeparata: 12, liquidita: 8),
                                                note: "Dati di prova")
    static let dinamico = PortafoglioModello(id: "modello-prova-dinamico", nome: "Dinamico", colore: .viola,
                                             pesi: PesiModello(azionario: 65, obbligazionario: 25, gestioneSeparata: 0, liquidita: 10),
                                             note: "Dati di prova")
    static let tutti = [prudente, equilibrato, dinamico]
    /// La tolleranza del template (5 punti), solo nei dati di prova.
    static let tolleranza: Double = 5

    /// Porta i modelli di prova in `dati` e assegna a ogni cliente con investimenti il modello di prova più vicino alla
    /// sua composizione di oggi (chi ha solo liquidità resta senza). Solo per i dati di prova: con i dati veri il modello lo sceglie l'utente.
    static func applica(_ dati: inout DatiPrisma) {
        dati.portafogliModello = tutti
        dati.impostazioni.tolleranzaRadar = tolleranza
        var perCliente: [String: [Posizione]] = [:]
        for p in MotoreRadar.considerate(dati.posizioni) { perCliente[p.clienteId, default: []].append(p) }
        for i in dati.clienti.indices {
            guard let sue = perCliente[dati.clienti[i].id], !sue.isEmpty else { continue }
            let k = MotoreAree360.composizione(sue, cliente: dati.clienti[i])
            var quote = PesiModello()
            for pezzo in k.pezzi { quote[pezzo.classe] = pezzo.quota }
            // Chi ha solo liquidità resta senza modello: un modello per un conto non ha senso
            guard quote.liquidita < 99.5 else { continue }
            dati.clienti[i].modelloId = tutti.min {
                MotoreRadar.distanza(quote: quote, pesi: $0.pesi) < MotoreRadar.distanza(quote: quote, pesi: $1.pesi)
            }?.id
        }
    }
}
