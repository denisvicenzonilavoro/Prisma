import Foundation

/// Una riga (CSV) o una domanda (JSON) scartata all'importazione, con il motivo.
struct RigaScartataOCF: Equatable {
    /// Numero della riga del CSV (l'intestazione è la riga 1, le righe vuote non contano) o della domanda nel JSON (da 1).
    let riga: Int
    let motivo: String
}

/// Il risultato della lettura di un file di domande, da mostrare nel riepilogo prima di confermare.
struct ImportazioneOCF: Equatable {
    var nuove: [DomandaOCF] = []
    /// Domande già presenti (stesso id) con il contenuto cambiato: lo storico delle risposte resta.
    var aggiornate: [DomandaOCF] = []
    /// Domande già presenti e uguali: non cambiano.
    var uguali = 0
    var scartate: [RigaScartataOCF] = []
    /// Materie che il file usa e l'archivio non ha ancora: si aggiungono confermando.
    var materieNuove: [MateriaOCF] = []
    /// La fonte dichiarata nel file JSON o il nome del file.
    var fonte: String?
    /// true = CSV (le scartate sono «righe»), false = JSON («domande»).
    var daCSV = true

    /// Niente da importare.
    var vuota: Bool { nuove.isEmpty && aggiornate.isEmpty }
    var riepilogo: String { TestiOCF.riepilogo(self) }
}

/// Un errore che impedisce di leggere tutto il file (formato, versione, intestazione): l'archivio resta com'era.
struct ErroreImportaOCF: Error, Equatable {
    let messaggio: String
}

/// Importazione delle domande OCF da CSV e JSON (formato in Design/ocf-formato.md). Il file non contiene mai dati
/// dei clienti. Funzioni pure: restituiscono il riepilogo, l'archivio cambia solo con `ArchivioOCF.applica`.
enum ImportaOCF {
    static let formato = "prisma-domande-ocf"
    static let versione = 1
    /// Il file delle domande di esempio, nella cartella Risorse.
    static let fileEsempio = "ocf-esempio.json"

    /// Legge un file: JSON se comincia con «{», altrimenti CSV (UTF-8 con o senza BOM, o Latin-1 di Excel).
    static func leggi(_ dati: Data, nomeFile: String, archivio: ArchivioOCF, origine: OrigineDomandaOCF = .importata,
                      adesso: Date = Date()) throws -> ImportazioneOCF {
        guard let testo = ImportaClienti.testo(dati) else { throw ErroreImportaOCF(messaggio: TestiOCF.fileIlleggibile) }
        let inizio = testo.trimmingCharacters(in: .whitespacesAndNewlines).first
        if inizio == "{" || inizio == "[" {
            return try daJSON(Data(testo.utf8), archivio: archivio, origine: origine, adesso: adesso, nomeFile: nomeFile)
        }
        return try daCSV(testo, archivio: archivio, origine: origine, adesso: adesso, nomeFile: nomeFile)
    }

    /// Le domande di esempio di Prisma (origine «esempio»); nil se il file manca.
    static func esempio(archivio: ArchivioOCF, adesso: Date = Date()) -> ImportazioneOCF? {
        guard let url = Risorse.cartella?.appendingPathComponent(fileEsempio), let dati = try? Data(contentsOf: url) else { return nil }
        return try? daJSON(dati, archivio: archivio, origine: .esempio, adesso: adesso, nomeFile: fileEsempio)
    }

    // MARK: Il contenuto comune

    /// Una domanda letta dal file, prima dei controlli.
    struct Candidata {
        var riga: Int
        var id: String?
        var materia: String
        var testo: String
        var risposte: [String]
        var corretta: Int?
        /// Il valore scritto per la corretta, per il messaggio d'errore.
        var correttaScritta: String
        var spiegazione: String?
        var fonte: String?
        var caso: String?
    }

    /// Controlla le candidate e le confronta con l'archivio.
    static func componi(_ candidate: [Candidata], archivio: ArchivioOCF, materieDichiarate: [MateriaOCF], origine: OrigineDomandaOCF,
                        adesso: Date, fonte: String?, daCSV: Bool) -> ImportazioneOCF {
        var esito = ImportazioneOCF()
        esito.fonte = fonte
        esito.daCSV = daCSV
        var materie = archivio.materie
        for m in materieDichiarate where !materie.contains(where: { chiave($0.id) == chiave(m.id) }) {
            materie.append(m)
            esito.materieNuove.append(m)
        }
        var visti = Set<String>()
        for c in candidate {
            func scarta(_ motivo: String) { esito.scartate.append(RigaScartataOCF(riga: c.riga, motivo: motivo)) }
            let materiaScritta = pulito(c.materia)
            let testo = pulito(c.testo)
            let risposte = c.risposte.map(pulito)
            guard !materiaScritta.isEmpty else { scarta(TestiOCF.mancaMateria); continue }
            guard !testo.isEmpty else { scarta(TestiOCF.mancaTesto); continue }
            guard risposte.count == DomandaOCF.numeroRisposte else { scarta(TestiOCF.risposteNonQuattro(risposte.count)); continue }
            if let vuota = risposte.firstIndex(where: { $0.isEmpty }) { scarta(TestiOCF.mancaRisposta(vuota)); continue }
            guard Set(risposte.map(chiave)).count == risposte.count else { scarta(TestiOCF.risposteUguali); continue }
            guard let corretta = c.corretta, (0..<DomandaOCF.numeroRisposte).contains(corretta) else {
                scarta(TestiOCF.correttaNonValida(c.correttaScritta, daCSV: daCSV)); continue
            }
            // La materia: per codice o per nome; altrimenti è una materia nuova (si vede nel riepilogo)
            let k = chiave(materiaScritta)
            let materia: MateriaOCF
            if let m = materie.first(where: { chiave($0.id) == k || chiave($0.nome) == k || $0.id == slug(materiaScritta) }) {
                materia = m
            } else {
                let codice = slug(materiaScritta)
                guard !codice.isEmpty else { scarta(TestiOCF.mancaMateria); continue }
                materia = MateriaOCF(id: codice, nome: materiaScritta)
                materie.append(materia)
                esito.materieNuove.append(materia)
            }
            let idScritto = pulito(c.id ?? "")
            let id = idScritto.isEmpty ? impronta(materia.id, testo) : idScritto
            guard visti.insert(id).inserted else { scarta(TestiOCF.idRipetuto(id)); continue }
            let fonteRiga = facoltativo(c.fonte)
            var d = DomandaOCF(id: id, materia: materia.id, testo: testo, risposte: risposte, corretta: corretta,
                               spiegazione: facoltativo(c.spiegazione), fonte: fonteRiga ?? fonte,
                               origine: origine, caso: CasoOCF.da(c.caso), aggiuntaIl: adesso)
            if let gia = archivio.domanda(id) {
                // Senza una fonte scritta nella riga resta quella di prima (il nome del file non basta a cambiarla)
                if fonteRiga == nil { d.fonte = gia.fonte }
                if gia.stessoContenuto(di: d) {
                    esito.uguali += 1
                } else {
                    // Resta l'origine e la data di prima: cambia solo il contenuto
                    d.origine = gia.origine
                    d.aggiuntaIl = gia.aggiuntaIl ?? adesso
                    esito.aggiornate.append(d)
                }
            } else {
                esito.nuove.append(d)
            }
        }
        return esito
    }

    // MARK: CSV

    private enum Colonna: CaseIterable { case id, materia, testo, a, b, c, d, corretta, spiegazione, fonte, caso }

    private static func colonna(_ intestazione: String) -> Colonna? {
        let t = chiave(intestazione).replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
        switch t {
        case "id", "codice": return .id
        case "materia": return .materia
        case "domanda", "testo", "testo domanda": return .testo
        case "a", "risposta a": return .a
        case "b", "risposta b": return .b
        case "c", "risposta c": return .c
        case "d", "risposta d": return .d
        case "corretta", "giusta", "risposta corretta", "risposta giusta", "soluzione": return .corretta
        case "spiegazione": return .spiegazione
        case "fonte", "appunti", "riferimento", "fonte appunti": return .fonte
        case "caso", "caso vero": return .caso
        default: return nil
        }
    }

    static func daCSV(_ testo: String, archivio: ArchivioOCF, origine: OrigineDomandaOCF = .importata, adesso: Date = Date(),
                      nomeFile: String? = nil) throws -> ImportazioneOCF {
        let senzaBOM = testo.hasPrefix("\u{FEFF}") ? String(testo.dropFirst()) : testo
        let righe = ImportaClienti.righeCSV(senzaBOM)
        guard let testa = righe.first else { throw ErroreImportaOCF(messaggio: TestiOCF.fileVuoto) }
        var mappa: [Colonna: Int] = [:]
        for (i, h) in testa.enumerated() {
            if let c = colonna(h), mappa[c] == nil { mappa[c] = i }
        }
        let obbligatorie: [(Colonna, String)] = [(.materia, "materia"), (.testo, "domanda"), (.a, "a"), (.b, "b"), (.c, "c"),
                                                 (.d, "d"), (.corretta, "corretta")]
        let mancano = obbligatorie.filter { mappa[$0.0] == nil }.map { $0.1 }
        guard mancano.isEmpty else { throw ErroreImportaOCF(messaggio: TestiOCF.mancanoColonne(mancano)) }
        guard righe.count > 1 else { throw ErroreImportaOCF(messaggio: TestiOCF.fileVuoto) }
        let candidate = righe.dropFirst().enumerated().map { n, r -> Candidata in
            func v(_ c: Colonna) -> String {
                guard let i = mappa[c], i < r.count else { return "" }
                return r[i].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let scritta = v(.corretta)
            return Candidata(riga: n + 2, id: v(.id), materia: v(.materia), testo: v(.testo), risposte: [v(.a), v(.b), v(.c), v(.d)],
                             corretta: correttaCSV(scritta), correttaScritta: scritta, spiegazione: v(.spiegazione),
                             fonte: v(.fonte), caso: v(.caso))
        }
        return componi(candidate, archivio: archivio, materieDichiarate: [], origine: origine, adesso: adesso,
                       fonte: nomeFile, daCSV: true)
    }

    /// «A»-«D» (anche minuscole) o «1»-«4» → 0-3.
    static func correttaCSV(_ s: String) -> Int? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch t {
        case "A", "1": return 0
        case "B", "2": return 1
        case "C", "3": return 2
        case "D", "4": return 3
        default: return nil
        }
    }

    // MARK: JSON

    private struct RadiceJSON: Decodable {
        let formato: String?
        let versione: Int?
        let fonte: String?
        let materie: [MateriaJSON]?
        let domande: RigheJSON?
    }

    private struct MateriaJSON: Decodable {
        let id: String?
        let nome: String?
        let caso: String?
    }

    private enum CorrettaJSON: Decodable {
        case indice(Int)
        case lettera(String)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let i = try? c.decode(Int.self) {
                self = .indice(i)
            } else {
                self = .lettera(try c.decode(String.self))
            }
        }
    }

    private struct DomandaJSON: Decodable {
        let id: String?
        let materia: String?
        let testo: String?
        let risposte: [String]?
        let corretta: CorrettaJSON?
        let spiegazione: String?
        let fonte: String?
        let caso: String?
    }

    /// Le domande una per una: una illeggibile diventa nil (scartata con il suo numero), le altre restano.
    private struct RigheJSON: Decodable {
        var elementi: [DomandaJSON?] = []

        init(from decoder: Decoder) throws {
            var c = try decoder.unkeyedContainer()
            while !c.isAtEnd {
                if let d = try? c.decode(DomandaJSON.self) {
                    elementi.append(d)
                } else {
                    elementi.append(nil)
                    if (try? c.decodeNil()) == true { continue }
                    if (try? c.decode(Scartato.self)) == nil { break }
                }
            }
        }

        private struct Scartato: Decodable {
            init(from decoder: Decoder) throws {}
        }
    }

    static func daJSON(_ dati: Data, archivio: ArchivioOCF, origine: OrigineDomandaOCF = .importata, adesso: Date = Date(),
                       nomeFile: String? = nil) throws -> ImportazioneOCF {
        guard (try? JSONSerialization.jsonObject(with: dati)) != nil else { throw ErroreImportaOCF(messaggio: TestiOCF.jsonRotto) }
        guard let radice = try? JSONDecoder().decode(RadiceJSON.self, from: dati) else {
            throw ErroreImportaOCF(messaggio: TestiOCF.strutturaJSON)
        }
        guard radice.formato == formato else { throw ErroreImportaOCF(messaggio: TestiOCF.formatoSconosciuto(radice.formato)) }
        guard let v = radice.versione else { throw ErroreImportaOCF(messaggio: TestiOCF.versioneMancante) }
        guard v == versione else { throw ErroreImportaOCF(messaggio: TestiOCF.versioneSconosciuta(v)) }
        guard let righe = radice.domande?.elementi, !righe.isEmpty else { throw ErroreImportaOCF(messaggio: TestiOCF.fileVuoto) }
        let dichiarate = (radice.materie ?? []).compactMap { m -> MateriaOCF? in
            let nome = pulito(m.nome ?? "")
            let id = pulito(m.id ?? "").isEmpty ? slug(nome) : pulito(m.id ?? "")
            guard !id.isEmpty else { return nil }
            return MateriaOCF(id: id, nome: nome.isEmpty ? id : nome, caso: CasoOCF.da(m.caso))
        }
        var candidate: [Candidata] = []
        var illeggibili: [RigaScartataOCF] = []
        for (i, e) in righe.enumerated() {
            guard let d = e else {
                illeggibili.append(RigaScartataOCF(riga: i + 1, motivo: TestiOCF.domandaIlleggibile))
                continue
            }
            let corretta: Int?
            let scritta: String
            switch d.corretta {
            case .indice(let n)?: corretta = n; scritta = String(n)
            case .lettera(let s)?:
                let t = s.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                corretta = ["A", "B", "C", "D"].firstIndex(of: t)
                scritta = s
            case nil: corretta = nil; scritta = ""
            }
            candidate.append(Candidata(riga: i + 1, id: d.id, materia: d.materia ?? "", testo: d.testo ?? "", risposte: d.risposte ?? [],
                                       corretta: corretta, correttaScritta: scritta, spiegazione: d.spiegazione, fonte: d.fonte, caso: d.caso))
        }
        let fonte = facoltativo(radice.fonte) ?? nomeFile
        var esito = componi(candidate, archivio: archivio, materieDichiarate: dichiarate, origine: origine, adesso: adesso,
                            fonte: fonte, daCSV: false)
        esito.scartate = (esito.scartate + illeggibili).sorted { $0.riga < $1.riga }
        return esito
    }

    // MARK: Aiuti

    /// Spazi in fondo e in testa tolti, a capo e spazi multipli ridotti a uno.
    static func pulito(_ s: String) -> String {
        s.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private static func facoltativo(_ s: String?) -> String? {
        guard let s else { return nil }
        let p = pulito(s)
        return p.isEmpty ? nil : p
    }

    /// Per confrontare senza badare a maiuscole, accenti e spazi.
    static func chiave(_ s: String) -> String {
        pulito(s).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "it_IT")).lowercased()
    }

    /// Il codice di una materia dal nome: «Matematica finanziaria» → «matematica-finanziaria».
    static func slug(_ s: String) -> String {
        let parole = chiave(s).split(whereSeparator: { !($0.isLetter || $0.isNumber) })
        return parole.joined(separator: "-")
    }

    /// Un id stabile dal contenuto (FNV-1a a 64 bit di materia e testo): reimportare lo stesso file non crea doppioni.
    static func impronta(_ materia: String, _ testo: String) -> String {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in (materia + "|" + chiave(testo)).utf8 {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01B3
        }
        return "ocf-" + String(h, radix: 16)
    }
}
