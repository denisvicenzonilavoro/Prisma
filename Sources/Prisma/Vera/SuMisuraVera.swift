import Foundation

// «Vera su misura» (Vera/BRIEF.md, fase 5, funzione 22). Ogni tanto Vera impara il tuo modo di lavorare: gli esempi che
// hai approvato con 👍 (e le lezioni delle tue correzioni) diventano, resi anonimi e dopo la tua approvazione, un pacchetto
// che porti tu a un addestramento fuori dal Mac (Unsloth su una GPU gratuita in cloud, Vera/Addestramento). Prisma non fa
// nessuna richiesta di rete per questo. Il modello addestrato torna sul Mac, entra in Ollama (API locali, 127.0.0.1) e fa
// l'esame: le domande tenute da parte (mai uscite dal Mac) poste alla Vera di oggi e a quella nuova, un modello alla
// volta, con il punteggio calcolato dal codice. La nuova Vera prende il posto di quella di oggi solo se supera l'esame;
// si torna sempre alla versione di prima.

/// L'esito breve di un esame, salvato con la versione.
struct EsitoEsameBreve: Codable, Equatable {
    var domande: Int
    var percentualeAttuale: Int
    var percentualeNuova: Int
    var cifreInventateAttuale: Int
    var cifreInventateNuova: Int
    var fattoIl: Date
    var superato: Bool
}

/// Una versione addestrata di Vera (Impostazioni › Vera › Vera su misura). Letta con tolleranza.
struct VersioneSuMisura: Codable, Equatable, Identifiable {
    enum Stato: String, Codable {
        /// In Ollama, in attesa dell'esame.
        case importata
        /// Esame superato: si può usare.
        case superata
        /// Esame non superato: la sostituzione è bloccata.
        case nonSuperata
        /// È la Vera di adesso.
        case inUso
        /// Era in uso, poi sei tornato alla Vera di prima: resta in Ollama e si può riprovare.
        case ritirata
        /// Tolta da Ollama.
        case eliminata
    }

    /// Il nome in Ollama: «vera-su-misura:2026-11-08».
    var id: String
    var creataIl: Date
    /// Il modello da cui è partito l'addestramento («qwen3.5:4b»).
    var modelloDiPartenza: String
    var esempi: Int
    var stato: Stato
    var esame: EsitoEsameBreve?
    /// L'errore per passo da rapporto.json, al massimo 60 punti.
    var curva: [Double]?
    /// true = fac-simile (istantanee): la pagina scrive «Numeri di esempio».
    var diProva: Bool?

    init(id: String, creataIl: Date, modelloDiPartenza: String, esempi: Int, stato: Stato) {
        self.id = id
        self.creataIl = creataIl
        self.modelloDiPartenza = modelloDiPartenza
        self.esempi = esempi
        self.stato = stato
    }

    private enum CodingKeys: String, CodingKey { case id, creataIl, modelloDiPartenza, esempi, stato, esame, curva, diProva }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Senza id o con uno stato sconosciuto la versione si scarta (ElencoTollerante tiene le altre)
        id = try c.decode(String.self, forKey: .id)
        stato = try c.decode(Stato.self, forKey: .stato)
        guard !id.isEmpty else { throw DecodingError.dataCorruptedError(forKey: .id, in: c, debugDescription: "versione senza nome") }
        creataIl = (try? c.decodeIfPresent(Date.self, forKey: .creataIl)) ?? Date(timeIntervalSince1970: 0)
        modelloDiPartenza = (try? c.decodeIfPresent(String.self, forKey: .modelloDiPartenza)) ?? MotoreLocale.modelloPredefinito
        esempi = max(0, (try? c.decodeIfPresent(Int.self, forKey: .esempi)) ?? 0)
        esame = (try? c.decodeIfPresent(EsitoEsameBreve.self, forKey: .esame)) ?? nil
        curva = (try? c.decodeIfPresent([Double].self, forKey: .curva)) ?? nil
        diProva = (try? c.decodeIfPresent(Bool.self, forKey: .diProva)) ?? nil
    }
}

/// Lo stato salvato di «Vera su misura» (dentro ImpostazioniVera: niente nell'istantanea di Prisma ovunque, che azzera `vera`).
struct ImpostazioniSuMisura: Codable, Equatable {
    /// Al massimo `SuMisuraVera.massimoVersioni`.
    var versioni: [VersioneSuMisura] = []
    /// Il modello di prima, per «Torna alla Vera di prima».
    var modelloPrecedente: String?
    /// Gli id degli EsempioVera tenuti per l'esame: non entrano mai nel pacchetto.
    var esame: [String] = []
    /// Gli id già esportati in un pacchetto (al massimo `MemoriaVera.massimoEsempi`): non entrano mai nell'esame.
    var usati: [String] = []
    var ultimoPacchetto: Date?
    var esempiNelPacchetto = 0

    init() {}

    private enum CodingKeys: String, CodingKey { case versioni, modelloPrecedente, esame, usati, ultimoPacchetto, esempiNelPacchetto }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        versioni = Array((((try? c.decodeIfPresent(ElencoTollerante<VersioneSuMisura>.self, forKey: .versioni)) ?? nil)?.elementi ?? [])
            .suffix(SuMisuraVera.massimoVersioni))
        modelloPrecedente = (try? c.decodeIfPresent(String.self, forKey: .modelloPrecedente)) ?? nil
        esame = (try? c.decodeIfPresent([String].self, forKey: .esame)) ?? []
        usati = Array(((try? c.decodeIfPresent([String].self, forKey: .usati)) ?? []).suffix(MemoriaVera.massimoEsempi))
        ultimoPacchetto = (try? c.decodeIfPresent(Date.self, forKey: .ultimoPacchetto)) ?? nil
        esempiNelPacchetto = max(0, (try? c.decodeIfPresent(Int.self, forKey: .esempiNelPacchetto)) ?? 0)
    }

    /// La versione in uso, se c'è.
    var inUso: VersioneSuMisura? { versioni.last { $0.stato == .inUso } }
}

enum SuMisuraVera {
    static let prefissoModello = "vera-su-misura"
    /// Sotto questo numero di esempi pronti il pacchetto non si prepara (da confermare con l'utente).
    static let minimoEsempi = 60
    /// La parte degli esempi tenuta per l'esame, tra un minimo e un massimo di domande.
    static let quotaEsame = 0.2
    static let minimoEsame = 12
    static let massimoEsame = 80
    static let massimoVersioni = 6
    static let nomeFileAddestramento = "addestramento.jsonl"
    static let nomeFileManifesto = "manifest.json"
    static let nomeFileRapporto = "rapporto.json"
    static let nomeNotebook = "vera-su-misura.ipynb"
    static let nomeScript = "addestra.py"
    static let quantizzazione = "q4_k_m"
    /// I punti della curva dell'errore tenuti con la versione.
    static let puntiCurva = 60
}

// MARK: - Nomi dei modelli

extension SuMisuraVera {
    /// «vera-su-misura:2026-11-08».
    static func nomeModello(_ data: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return prefissoModello + ":" + f.string(from: data)
    }

    static func eSuMisura(_ modello: String) -> Bool {
        modello.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix(prefissoModello)
    }

    /// «Vera su misura · novembre»: il nome della versione per la pagina.
    static func nomeVersione(_ v: VersioneSuMisura) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "LLLL"
        return "Vera su misura · " + f.string(from: v.creataIl)
    }
}

// MARK: - Raccolta e divisione degli esempi

extension SuMisuraVera {
    /// Le cifre della risposta che non sono nella fonte (la domanda, o domanda e risposta attesa): con un'unità diversa o
    /// un valore diverso (tolleranza di mezzo centesimo).
    static func cifreSenzaFonte(_ risposta: String, fonte: String) -> [String] {
        let note = FontiVera.numeri(fonte).map(\.valore)
        return FontiVera.numeri(risposta).filter { n in !note.contains { abs($0 - n.valore) < 0.005 } }.map(\.testo)
    }

    /// Gli esempi che possono servire (al pacchetto o all'esame): non esclusi, non vietati (MemoriaVera.vietato), non vuoti,
    /// senza doppioni.
    static func candidati(_ esempi: [EsempioVera]) -> [EsempioVera] {
        var visti = Set<String>()
        return esempi.filter { e in
            let d = e.domanda.trimmingCharacters(in: .whitespacesAndNewlines)
            let r = e.risposta.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !e.escluso, !d.isEmpty, !r.isEmpty, MemoriaVera.vietato(d + " " + r) == nil else { return false }
            return visti.insert(e.id).inserted && visti.insert(NucleoVera.semplice(d + "\u{1F}" + r)).inserted
        }
    }

    /// Regola 3 del brief («i numeri li calcola Prisma»): un esempio in modalità lavoro (o senza modalità, cioè di prima
    /// della fase 5) la cui risposta contiene cifre che non sono nella domanda non entra nell'addestramento: la scheda da cui
    /// venivano quelle cifre non è salvata e il modello imparerebbe a scrivere numeri senza fonte. Resta buono per l'esame.
    static func addestrabile(_ e: EsempioVera) -> Bool {
        if e.modalita == .conversazione { return true }
        return cifreSenzaFonte(e.risposta, fonte: e.domanda).isEmpty
    }

    /// Gli esempi che possono entrare nell'addestramento.
    static func raccogli(_ esempi: [EsempioVera]) -> [EsempioVera] {
        candidati(esempi).filter(addestrabile)
    }

    /// Quante domande tiene l'esame per tanti candidati: il 20%, tra 12 e 80 (mai più di metà).
    static func quanteDomande(_ candidati: Int) -> Int {
        guard candidati > 1 else { return 0 }
        let quota = Int((Double(candidati) * quotaEsame).rounded())
        return min(candidati / 2, min(massimoEsame, max(minimoEsame, quota)))
    }

    /// Divisione deterministica (ordinata per id): l'esame non entra mai nell'addestramento. Le domande d'esame già scelte
    /// restano finché l'esempio esiste; quelle sparite (la memoria tiene gli ultimi 300 esempi) si sostituiscono con
    /// esempi mai usati in un pacchetto (`usati`), così un esempio addestrato non finisce poi nell'esame. Prima gli esempi
    /// che non possono entrare nell'addestramento (lavoro con cifre senza fonte): all'esame servono comunque.
    static func dividi(_ esempi: [EsempioVera], esameGia: [String], usati: [String] = []) -> (addestramento: [EsempioVera], esame: [EsempioVera]) {
        let tutti = candidati(esempi)
        let quante = quanteDomande(tutti.count)
        let usatiSet = Set(usati)
        var esame = tutti.filter { esameGia.contains($0.id) }.sorted { $0.id < $1.id }
        if esame.count > quante { esame = Array(esame.prefix(quante)) }
        let scelti = Set(esame.map(\.id))
        let liberi = tutti.filter { !scelti.contains($0.id) && !usatiSet.contains($0.id) }
            .sorted { (addestrabile($0) ? 1 : 0, $0.id) < (addestrabile($1) ? 1 : 0, $1.id) }
        esame += liberi.prefix(max(0, quante - esame.count))
        let ids = Set(esame.map(\.id))
        let addestramento = tutti.filter { !ids.contains($0.id) && addestrabile($0) }.sorted { $0.id < $1.id }
        return (addestramento, esame.sorted { $0.id < $1.id })
    }
}

// MARK: - Messaggi per l'addestramento e curva dell'errore

extension SuMisuraVera {
    /// Un esempio come conversazione per l'addestramento: le istruzioni della sua modalità (con le lezioni del consulente,
    /// già rese anonime), la domanda e la risposta approvata.
    static func messaggiAddestramento(_ e: EsempioAnonimo, lezioni: [String]) -> [[String: String]] {
        var sistema = e.modalita == .lavoro ? IstruzioniVera.chat : IstruzioniVera.conversazione
        if let b = LezioniVera.blocco(lezioni) { sistema += "\n\n" + b }
        return [["role": "system", "content": sistema], ["role": "user", "content": e.domanda], ["role": "assistant", "content": e.risposta]]
    }

    /// La curva dell'errore da rapporto.json ({"passi":[{"passo":1,"errore":2.1},…]}), ridotta a `puntiCurva` punti
    /// (media di ogni tratto). nil se il file non si legge o non ha passi.
    static func curva(daRapporto dati: Data) -> [Double]? {
        guard let j = try? JSONSerialization.jsonObject(with: dati) as? [String: Any],
              let passi = j["passi"] as? [[String: Any]] else { return nil }
        let errori = passi.compactMap { ($0["errore"] as? NSNumber)?.doubleValue }.filter { $0.isFinite }
        guard !errori.isEmpty else { return nil }
        guard errori.count > puntiCurva else { return errori }
        return (0..<puntiCurva).map { i in
            let da = i * errori.count / puntiCurva
            let a = max(da + 1, (i + 1) * errori.count / puntiCurva)
            let tratto = errori[da..<min(a, errori.count)]
            return tratto.reduce(0, +) / Double(tratto.count)
        }
    }
}

// MARK: - Versioni: esame, sostituzione, ritorno, eliminazione (senza rete)

extension SuMisuraVera {
    /// Aggiunge (o rimette in attesa d'esame) una versione importata; al massimo `massimoVersioni`, si tolgono prima le
    /// più vecchie già eliminate, poi le più vecchie non in uso.
    static func aggiungi(_ v: VersioneSuMisura, in vera: inout ImpostazioniVera) {
        vera.suMisura.versioni.removeAll { $0.id == v.id && $0.stato != .inUso }
        guard !vera.suMisura.versioni.contains(where: { $0.id == v.id }) else { return }
        vera.suMisura.versioni.append(v)
        while vera.suMisura.versioni.count > massimoVersioni {
            if let i = vera.suMisura.versioni.firstIndex(where: { $0.stato == .eliminata }) ?? vera.suMisura.versioni.firstIndex(where: { $0.stato != .inUso }) {
                vera.suMisura.versioni.remove(at: i)
            } else { break }
        }
    }

    /// L'esito dell'esame sulla versione: superata o non superata (mai per una versione in uso o eliminata).
    static func registraEsame(_ esito: EsitoEsameBreve, per id: String, in vera: inout ImpostazioniVera) {
        guard let i = vera.suMisura.versioni.firstIndex(where: { $0.id == id }),
              vera.suMisura.versioni[i].stato != .inUso, vera.suMisura.versioni[i].stato != .eliminata else { return }
        vera.suMisura.versioni[i].esame = esito
        vera.suMisura.versioni[i].stato = esito.superato ? .superata : .nonSuperata
    }

    /// Mette in uso una versione: solo con Ollama e solo se ha superato l'esame. La Vera di prima si ricorda per tornare
    /// indietro. false = niente è cambiato.
    @discardableResult
    static func sostituisci(_ id: String, in vera: inout ImpostazioniVera) -> Bool {
        guard vera.fornitore == .ollama, let i = vera.suMisura.versioni.firstIndex(where: { $0.id == id }) else { return false }
        let v = vera.suMisura.versioni[i]
        guard v.esame?.superato == true, v.stato == .superata || v.stato == .ritirata else { return false }
        if !eSuMisura(vera.modelloLocale) { vera.suMisura.modelloPrecedente = vera.modelloLocale }
        for j in vera.suMisura.versioni.indices where vera.suMisura.versioni[j].stato == .inUso { vera.suMisura.versioni[j].stato = .ritirata }
        vera.suMisura.versioni[i].stato = .inUso
        vera.modelloLocale = id
        return true
    }

    /// «Torna alla Vera di prima»: il modello di prima (o quello predefinito) torna in uso, la versione su misura resta in
    /// Ollama come «ritirata» (si può riprovare). false se non c'è una Vera su misura in uso.
    @discardableResult
    static func tornaIndietro(in vera: inout ImpostazioniVera) -> Bool {
        guard vera.fornitore == .ollama, eSuMisura(vera.modelloLocale) || vera.suMisura.inUso != nil else { return false }
        for j in vera.suMisura.versioni.indices where vera.suMisura.versioni[j].stato == .inUso { vera.suMisura.versioni[j].stato = .ritirata }
        let prima = vera.suMisura.modelloPrecedente ?? MotoreLocale.modelloPredefinito
        vera.modelloLocale = eSuMisura(prima) ? MotoreLocale.modelloPredefinito : prima
        return true
    }

    /// Segna eliminata una versione (dopo la cancellazione in Ollama). Mai quella in uso.
    @discardableResult
    static func segnaEliminata(_ id: String, in vera: inout ImpostazioniVera) -> Bool {
        guard let i = vera.suMisura.versioni.firstIndex(where: { $0.id == id }), vera.suMisura.versioni[i].stato != .inUso else { return false }
        vera.suMisura.versioni[i].stato = .eliminata
        return true
    }
}
