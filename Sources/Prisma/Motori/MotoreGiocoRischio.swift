import Foundation

// Il gioco del rischio della Sala (Design/template-luce-specifica.md §4.1, «Luce» giro 4): tre scenari raccontati uno
// alla volta, tre risposte ciascuno (dalla più prudente alla più audace), e alla fine il «profilo vissuto» accanto a
// quello dichiarato. Il gioco NON è il questionario di adeguatezza e non scrive mai `Cliente.profilo.propensione`
// (decisione 59): il risultato entra nel dossier solo con «Salva nel dossier» (decisione 52), come partita.
// Scenari, risposte, avvertenze e soglie stanno in `Risorse/Sala/gioco-rischio.json`, segnati «testi di prova» finché
// l'utente non li approva. Il profilo emerso usa le quattro propensioni di Prisma con le soglie della decisione 84
// (0-1 prudente, 2-3 moderata, 4-5 dinamica, 6 aggressiva). Motore puro: niente viste, niente archivio.

/// Una delle due strade dello scenario «sicurezza o rendimento»: il nome e i rendimenti anno per anno (in %).
struct StradaRischio: Codable, Equatable {
    let nome: String
    let rendimenti: [Double]
}

/// Uno scenario del gioco.
struct ScenarioRischio: Codable, Identifiable, Equatable {
    let id: String
    let domanda: String
    /// «Davanti al calo», «Quando è risalito», … (la riga del risultato).
    let etichetta: String
    /// Il valore che la domanda nomina (100.000 €): l'andamento è in centesimi di questo valore.
    let valoreIniziale: Double?
    /// I punti del grafico (100 = il valore iniziale); nil = scenario a due strade.
    let andamento: [Double]?
    let strade: [StradaRischio]?
    /// Le tre risposte, dalla più prudente alla più audace.
    let risposte: [String]
}

/// Le soglie del punteggio (sulla scala 0-6 del template).
struct SoglieGiocoRischio: Codable, Equatable {
    var prudenteFino = 1
    var moderataFino = 3
    var dinamicaFino = 5
}

/// I testi del gioco come stanno nella risorsa.
struct ScenariGiocoRischio: Codable, Equatable {
    let versione: String
    /// Vero finché l'utente non approva i testi: il gioco mostra l'etichetta «testi di prova».
    let testiDiProva: Bool
    let avvertenza: String
    let notaFinale: String
    let soglie: SoglieGiocoRischio
    let scenari: [ScenarioRischio]

    /// Il punteggio massimo (due punti per scenario: A = 0, B = 1, C = 2).
    var massimo: Int { scenari.reduce(0) { $0 + max(0, $1.risposte.count - 1) } }
}

/// Una risposta data: lo scenario, l'indice della scelta (0 = la più prudente) e i secondi per decidere.
struct RispostaRischio: Codable, Equatable {
    let scenario: String
    let scelta: Int
    let secondi: Double
}

/// Una partita giocata da un cliente. Va nell'archivio (`DatiPrisma.partiteRischio`, versione 27) solo con «Salva nel
/// dossier»; non entra in «Prisma ovunque» (decisione 44).
struct PartitaRischio: Codable, Identifiable, Equatable {
    var id: String
    var clienteId: String
    var data: Date
    var versioneScenari: String
    var risposte: [RispostaRischio]
    var vistaDalConsulenteIl: Date?

    init(id: String = UUID().uuidString, clienteId: String, data: Date, versioneScenari: String,
         risposte: [RispostaRischio], vistaDalConsulenteIl: Date? = nil) {
        self.id = id
        self.clienteId = clienteId
        self.data = data
        self.versioneScenari = versioneScenari
        self.risposte = risposte
        self.vistaDalConsulenteIl = vistaDalConsulenteIl
    }

    var punteggio: Int { risposte.reduce(0) { $0 + max(0, $1.scelta) } }
}

/// Il profilo emerso rispetto a quello dichiarato nel questionario.
enum ConfrontoProfilo: Equatable {
    case uguale, piuPrudente, piuAudace, nessunDichiarato
}

enum MotoreGiocoRischio {
    /// Il file dei testi nella cartella Risorse.
    static let fileScenari = "Sala/gioco-rischio.json"

    /// I testi del gioco letti una volta sola (le viste e il dossier li chiedono spesso).
    static let caricati: ScenariGiocoRischio? = scenari()

    /// I testi del gioco dalla risorsa (nil se il file manca o non si legge: il gioco lo dice, non inventa scenari).
    static func scenari() -> ScenariGiocoRischio? {
        guard let url = Risorse.cartella?.appendingPathComponent(fileScenari),
              let dati = try? Data(contentsOf: url) else { return nil }
        return leggi(dati)
    }

    /// Legge e controlla i testi: almeno uno scenario, tre risposte ciascuno, un grafico (andamento o due strade).
    static func leggi(_ dati: Data) -> ScenariGiocoRischio? {
        guard let s = try? JSONDecoder().decode(ScenariGiocoRischio.self, from: dati), !s.scenari.isEmpty else { return nil }
        let validi = s.scenari.allSatisfy { sc in
            sc.risposte.count >= 2 && ((sc.andamento?.count ?? 0) >= 2 || (sc.strade?.isEmpty == false))
        }
        return validi ? s : nil
    }

    /// Il profilo da un punteggio, riportato sulla scala 0-6 delle soglie quando il massimo è diverso.
    static func profilo(punteggio: Int, massimo: Int = 6, soglie: SoglieGiocoRischio = SoglieGiocoRischio()) -> ProfiloInvestitore.Propensione {
        let p = massimo == 6 || massimo <= 0 ? Double(punteggio) : Double(punteggio) * 6 / Double(massimo)
        let su6 = Int(p.rounded())
        if su6 <= soglie.prudenteFino { return .prudente }
        if su6 <= soglie.moderataFino { return .moderata }
        if su6 <= soglie.dinamicaFino { return .dinamica }
        return .aggressiva
    }

    /// Il profilo di una partita; nil se la partita è incompleta (non tutti gli scenari hanno una risposta).
    static func profilo(_ p: PartitaRischio, scenari: ScenariGiocoRischio) -> ProfiloInvestitore.Propensione? {
        guard completa(p, scenari: scenari) else { return nil }
        return profilo(punteggio: p.punteggio, massimo: scenari.massimo, soglie: scenari.soglie)
    }

    /// Vero se ogni scenario ha la sua risposta valida.
    static func completa(_ p: PartitaRischio, scenari: ScenariGiocoRischio) -> Bool {
        scenari.scenari.allSatisfy { sc in
            p.risposte.contains { $0.scenario == sc.id && $0.scelta >= 0 && $0.scelta < sc.risposte.count }
        }
    }

    /// Il confronto fra il profilo emerso e la propensione dichiarata nel questionario.
    static func confronto(emerso: ProfiloInvestitore.Propensione, dichiarato: ProfiloInvestitore.Propensione?) -> ConfrontoProfilo {
        guard let dichiarato else { return .nessunDichiarato }
        let tutte = ProfiloInvestitore.Propensione.allCases
        guard let e = tutte.firstIndex(of: emerso), let d = tutte.firstIndex(of: dichiarato) else { return .nessunDichiarato }
        if e == d { return .uguale }
        return e < d ? .piuPrudente : .piuAudace
    }

    /// La perdita che il profilo sopporta (in % del patrimonio finanziario): la stessa di MotoreResistenza.
    static func perditaSopportata(_ p: ProfiloInvestitore.Propensione) -> Double {
        MotoreResistenza.sopportabile(p)
    }

    /// I punti di una strada: 100 all'inizio, poi ogni anno con il suo rendimento.
    static func punti(_ s: StradaRischio) -> [Double] {
        var v = [100.0]
        for r in s.rendimenti { v.append(v[v.count - 1] * (1 + r / 100)) }
        return v
    }

    /// Il valore finale di uno scenario con l'andamento (in euro), dal valore iniziale e dall'ultimo punto.
    static func valoreFinale(_ s: ScenarioRischio) -> Double? {
        guard let a = s.andamento, let ultimo = a.last, let v = s.valoreIniziale else { return nil }
        return (v * ultimo / 100).rounded()
    }

    /// Il valore da cui parte il conteggio del numero (il primo punto della linea, come il template).
    static func valorePartenza(_ s: ScenarioRischio) -> Double? {
        guard let a = s.andamento, let primo = a.first, let v = s.valoreIniziale else { return nil }
        return (v * primo / 100).rounded()
    }

    /// La linea scende se l'ultimo punto è sotto il primo (rossa), altrimenti sale (verde).
    static func scende(_ s: ScenarioRischio) -> Bool {
        guard let a = s.andamento, let primo = a.first, let ultimo = a.last else { return false }
        return ultimo < primo
    }

    /// L'ultima partita salvata del cliente (la più recente).
    static func ultima(_ partite: [PartitaRischio], cliente: String) -> PartitaRischio? {
        partite.filter { $0.clienteId == cliente }.max { $0.data < $1.data }
    }

    /// DATI DI PROVA: una partita già fatta per ognuno dei clienti dati (i clienti fittizi caricabili da Impostazioni),
    /// mai nell'archivio reale. Risposte e tempi inventati per provare il dossier e lo stato «L'ultima volta».
    static func partiteDiProva(clienti: [String], oggi: Date = Date()) -> [PartitaRischio] {
        let schemi: [([Int], [Double])] = [([1, 1, 2], [3.2, 1.8, 2.4]), ([0, 1, 0], [1.1, 2.6, 4.0])]
        let versione = caricati?.versione ?? "prova"
        let ids = caricati?.scenari.map(\.id) ?? []
        return clienti.enumerated().compactMap { i, id in
            guard !ids.isEmpty else { return nil }
            let (scelte, secondi) = schemi[i % schemi.count]
            return PartitaRischio(id: "partita-prova-\(id)", clienteId: id,
                                  data: oggi.addingTimeInterval(-Double(20 + 15 * i) * 86_400), versioneScenari: versione,
                                  risposte: zip(ids, zip(scelte, secondi)).map { RispostaRischio(scenario: $0, scelta: $1.0, secondi: $1.1) })
        }
    }

    /// «ha deciso in 1,0 s»: una cifra decimale con la virgola.
    static func secondi(_ s: Double) -> String {
        let decimi = Int((max(0, s) * 10).rounded())
        return "\(decimi / 10),\(decimi % 10) s"
    }
}
