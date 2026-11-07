import Foundation

// Le tessere della striscia di Mercato e l'occhiello della finestra (Design/template-novita-specifica.md §12.1.2,
// §12.1.4, §12.1.9, §12.5.3, giro 7). Motore puro: la serie, le scelte e `oggi` entrano come parametri.
// - Il valore già scritto («34.180», «3,42%», «1,6%», «18,42 €»), la variazione sull'ultimo dato (indici e quote in %,
//   tassi e inflazione in punti; «invariato» sotto la soglia di rumore), il tono (buono o cattivo per i clienti, non
//   il segno), la mini linea normalizzata da 0 a 1, la data dell'ultimo valore e la fonte da citare.
// - Il tasso BCE ha un valore per ogni variazione: la sua variazione si misura sul valore in vigore un mese prima e la
//   sua freschezza sull'ultimo scaricamento (vale finché non cambia).
// - Quali serie vanno nella striscia: quelle della configurazione (con l'interruttore acceso), le calcolate (spread)
//   e quelle importate o scritte a mano; la serie che serve solo a calcolare lo spread (Germania) non si mostra, e
//   dell'inflazione si mostra una sola serie (la prima con valori).

/// Se una variazione è buona o cattiva per i clienti (§12.1.4): il colore dice questo, non il segno.
enum TonoMercato: String, Equatable {
    case buono, cattivo, neutro
}

/// Un dato è recente o vecchio rispetto alla sua frequenza (§12.1.9 «Dati vecchi»).
enum FreschezzaMercato: Equatable {
    case recente, vecchia
}

/// Una tessera della striscia, già scritta: la vista non fa conti.
struct TesseraMercato: Identifiable, Equatable {
    let id: String
    let nome: String
    let tipo: TipoSerieMercato
    let unita: UnitaMercato
    /// nil = nessun valore («—», «Da importare»).
    let valore: Double?
    /// I decimali del valore (0 per gli indici, 1 per l'inflazione, 2 per tassi e quote).
    let decimali: Int
    let valoreTesto: String
    let variazione: Double?
    /// «+0,6%», «−0,02», «invariato»; nil senza un valore precedente.
    let variazioneTesto: String?
    let tono: TonoMercato
    /// I punti della mini linea, da 0 a 1 (dal più vecchio): vuoto con meno di due valori.
    let linea: [Double]
    let data: Date?
    /// «ottobre 2026», «23 ottobre 2026», «dall'11 giugno 2025» (tasso BCE).
    let dataTesto: String?
    let freschezza: FreschezzaMercato
    /// «Fonte: BCE», «Fonte: BCE (dato di EMMI)»…
    let citazione: String

    var senzaValore: Bool { valore == nil }
}

/// Le regole fisse delle tessere, tutte in un punto.
enum RegoleTessereMercato {
    /// La mini linea ha al massimo tanti punti (uno per periodo, §12.2.4).
    static let puntiLinea = 9
    /// Sotto queste variazioni il tono è neutro e il testo «invariato»: 0,05% per indici e quote, 0,005 punti per i
    /// tassi (§12.5.3).
    static let rumorePercentuale = 0.05
    static let rumorePunti = 0.005
    /// Il tasso BCE: la variazione si misura sul valore in vigore tanti giorni prima.
    static let giorniVariazioneTassoUfficiale = 30
    /// «Chi è toccato»: al massimo tanti avatar, poi «+N» (§12.1.5, Dubbio 7).
    static let avatarMassimi = 3
}

extension MotoreMercato {
    // MARK: - Testi dei valori

    /// I decimali con cui si scrive il valore di una serie.
    static func decimali(unita: UnitaMercato, tipo: TipoSerieMercato) -> Int {
        switch unita {
        case .punti: return 0
        case .euro: return 2
        case .percentuale: return tipo == .inflazione ? 1 : 2
        }
    }

    /// «34.180», «3,42%», «1,6%», «18,42 €» (meno tipografico).
    static func testoValore(_ v: Double, unita: UnitaMercato, decimali: Int) -> String {
        switch unita {
        case .punti: return TestiMercato.numero(v, decimali: decimali)
        case .percentuale: return TestiMercato.numero(v, decimali: decimali) + "%"
        case .euro: return TestiMercato.numero(v, decimali: decimali) + "\u{00A0}€"
        }
    }

    /// «+0,6%» per indici e quote, «+0,15» o «−0,2» (punti) per tassi e inflazione, «invariato» sotto la soglia.
    static func testoVariazione(_ v: Double, unita: UnitaMercato, decimali: Int) -> String {
        if invariata(v, unita: unita) { return TestiAppMercato.invariato }
        if unita.variazioneInPercentuale { return TestiMercato.percentualeConSegno(v, decimali: 1) }
        return TestiAppMercato.conSegno(v, decimali: max(1, decimali))
    }

    /// La variazione è sotto la soglia di rumore.
    static func invariata(_ v: Double, unita: UnitaMercato) -> Bool {
        abs(v) < (unita.variazioneInPercentuale ? RegoleTessereMercato.rumorePercentuale : RegoleTessereMercato.rumorePunti) - 1e-12
    }

    /// Il tono di una variazione per tipo di serie (§12.5.3): azioni su = buono; rendimenti e spread su = cattivo (i
    /// prezzi dei titoli scendono); Euribor, inflazione e tasso BCE giù = buono. Sotto la soglia di rumore: neutro.
    static func tono(_ tipo: TipoSerieMercato, variazione v: Double, unita: UnitaMercato) -> TonoMercato {
        guard !invariata(v, unita: unita) else { return .neutro }
        switch tipo {
        case .indiceAzionario: return v > 0 ? .buono : .cattivo
        case .rendimentoStato, .spread, .tassoInterbancario, .tassoUfficiale, .inflazione: return v > 0 ? .cattivo : .buono
        case .altro: return .neutro
        }
    }

    // MARK: - La tessera

    /// La tessera di una serie con i suoi valori, oppure quella «senza valore» se non ne ha.
    static func tessera(_ s: SerieMercato, oggi: Date, cal: Calendar = .current) -> TesseraMercato {
        let dec = decimali(unita: s.unita, tipo: s.tipo)
        guard let ultimo = valore(s.punti, al: oggi, cal: cal) else {
            return tesseraVuota(id: s.id, nome: s.nome, tipo: s.tipo, unita: s.unita, citazione: s.citazione)
        }
        // La variazione: il tasso BCE sul valore in vigore un mese prima, le altre serie sul valore precedente
        var prima: PuntoMercato?
        if s.tipo == .tassoUfficiale {
            if let d = cal.date(byAdding: .day, value: -RegoleTessereMercato.giorniVariazioneTassoUfficiale, to: oggi) {
                prima = valore(s.punti, al: d, cal: cal)
            }
        } else if let i = s.punti.lastIndex(where: { $0.data == ultimo.data }), i > 0 {
            prima = s.punti[i - 1]
        }
        var variazione: Double?
        if let p = prima {
            if s.unita.variazioneInPercentuale {
                if p.valore != 0 { variazione = (ultimo.valore / p.valore - 1) * 100 }
            } else {
                variazione = ultimo.valore - p.valore
            }
        }
        // La freschezza: il tasso BCE vale finché non cambia, conta l'ultimo scaricamento
        let riferimento = s.tipo == .tassoUfficiale ? max(s.aggiornataIl, ultimo.data) : ultimo.data
        let vecchia = !recenteTessera(riferimento, giorni: s.frequenza.giorniFreschezza, oggi: oggi, cal: cal)
        return TesseraMercato(id: s.id, nome: s.nome, tipo: s.tipo, unita: s.unita, valore: ultimo.valore, decimali: dec,
                              valoreTesto: testoValore(ultimo.valore, unita: s.unita, decimali: dec),
                              variazione: variazione,
                              variazioneTesto: variazione.map { testoVariazione($0, unita: s.unita, decimali: dec) },
                              tono: variazione.map { tono(s.tipo, variazione: $0, unita: s.unita) } ?? .neutro,
                              linea: linea(s, oggi: oggi, cal: cal),
                              data: ultimo.data,
                              dataTesto: TestiAppMercato.dataTessera(ultimo.data, frequenza: s.frequenza, tipo: s.tipo),
                              freschezza: vecchia ? .vecchia : .recente,
                              citazione: s.citazione)
    }

    /// Una serie ancora senza valori: il nome, «—» e la fonte da cui arriverà.
    static func tesseraVuota(id: String, nome: String, tipo: TipoSerieMercato, unita: UnitaMercato,
                             citazione: String) -> TesseraMercato {
        TesseraMercato(id: id, nome: nome, tipo: tipo, unita: unita, valore: nil, decimali: decimali(unita: unita, tipo: tipo),
                       valoreTesto: TestiAppMercato.senzaValore, variazione: nil, variazioneTesto: nil, tono: .neutro,
                       linea: [], data: nil, dataTesto: nil, freschezza: .recente, citazione: citazione)
    }

    /// La mini linea: gli ultimi 9 valori (uno per periodo). Le serie giornaliere si leggono alla fine di ognuno degli
    /// ultimi 9 mesi (il tasso BCE diventa una scala). Normalizzata da 0 (minimo) a 1 (massimo); piatta in fondo se
    /// i valori sono tutti uguali (nessuna divisione per zero).
    static func linea(_ s: SerieMercato, oggi: Date, cal: Calendar = .current) -> [Double] {
        let n = RegoleTessereMercato.puntiLinea
        var valori: [Double] = []
        if s.frequenza == .giornaliera {
            for k in stride(from: n - 1, through: 0, by: -1) {
                guard let d = k == 0 ? oggi : cal.date(byAdding: .month, value: -k, to: oggi) else { continue }
                if let p = valore(s.punti, al: d, cal: cal) { valori.append(p.valore) }
            }
        } else {
            valori = s.punti.filter { cal.startOfDay(for: $0.data) <= cal.startOfDay(for: oggi) }.suffix(n).map(\.valore)
        }
        return normalizza(valori)
    }

    /// Da 0 a 1 fra il minimo e il massimo; tutti uguali → tutti 0. Meno di due valori → vuoto.
    static func normalizza(_ valori: [Double]) -> [Double] {
        guard valori.count >= 2, let minimo = valori.min(), let massimo = valori.max() else { return [] }
        let ampiezza = massimo - minimo
        guard ampiezza > 1e-12 else { return valori.map { _ in 0 } }
        return valori.map { ($0 - minimo) / ampiezza }
    }

    private static func recenteTessera(_ data: Date, giorni: Int, oggi: Date, cal: Calendar) -> Bool {
        guard let limite = cal.date(byAdding: .day, value: -giorni, to: cal.startOfDay(for: oggi)) else { return false }
        return data >= limite
    }

    // MARK: - La striscia

    /// Le tessere della striscia, nell'ordine del template (azioni, rendimenti, spread, Euribor, inflazione, tasso
    /// BCE, il resto). Con l'interruttore acceso ci sono anche le serie configurate ancora senza valori («—»); spento
    /// solo quelle che l'archivio ha già (importate, scritte a mano o scaricate prima).
    static func tessere(archivio: ArchivioMercato, configurazione: ConfigurazioneMercato?, impostazioni: ImpostazioniMercato,
                        oggi: Date, cal: Calendar = .current) -> [TesseraMercato] {
        // Gli id candidati, senza doppioni: configurazione (se accesa), calcolate, poi l'archivio
        var ordine: [String] = []
        var vuote: [String: TesseraMercato] = [:]
        if impostazioni.attivo, let c = configurazione {
            for s in c.attive(impostazioni) where !ordine.contains(s.id) {
                ordine.append(s.id)
                vuote[s.id] = tesseraVuota(id: s.id, nome: s.nome, tipo: s.tipo, unita: s.unita,
                                           citazione: TestiMercato.citazione(origine: s.fonte, fonte: s.fonte.nome, datoDiTerzi: s.terzi))
            }
            for k in c.calcolate where !ordine.contains(k.id) {
                ordine.append(k.id)
                let da = c.serie(k.da)
                vuote[k.id] = tesseraVuota(id: k.id, nome: k.nome, tipo: k.tipo, unita: k.unita,
                                           citazione: da.map { TestiMercato.citazione(origine: $0.fonte, fonte: $0.fonte.nome, datoDiTerzi: $0.terzi) } ?? "")
            }
        }
        for s in archivio.serie where !ordine.contains(s.id) && !s.punti.isEmpty { ordine.append(s.id) }
        // Le serie che servono solo a una calcolata presente non si mostrano (il rendimento tedesco per lo spread)
        let soloPerCalcolo = Set((configurazione?.calcolate ?? []).filter { ordine.contains($0.id) }.map(\.meno))
        var elenco: [TesseraMercato] = []
        var inflazioneMostrata = false
        for id in ordine where !soloPerCalcolo.contains(id) {
            let t: TesseraMercato
            if let s = archivio.serie(id), !s.punti.isEmpty {
                t = tessera(s, oggi: oggi, cal: cal)
            } else if let v = vuote[id] {
                t = v
            } else {
                continue
            }
            if t.tipo == .inflazione {
                // Una sola inflazione (BCE ed Eurostat danno lo stesso indice): la prima con valori
                if inflazioneMostrata { continue }
                if t.senzaValore, elencoHaInflazioneConValori(ordine, archivio: archivio) { continue }
                inflazioneMostrata = true
            }
            elenco.append(t)
        }
        return elenco.enumerated().sorted { a, b in
            let ra = rangoStriscia(a.element.tipo), rb = rangoStriscia(b.element.tipo)
            return ra != rb ? ra < rb : a.offset < b.offset
        }.map(\.element)
    }

    private static func elencoHaInflazioneConValori(_ ordine: [String], archivio: ArchivioMercato) -> Bool {
        ordine.contains { id in
            guard let s = archivio.serie(id) else { return false }
            return s.tipo == .inflazione && !s.punti.isEmpty
        }
    }

    /// L'ordine della striscia per tipo, come nel template.
    static func rangoStriscia(_ tipo: TipoSerieMercato) -> Int {
        switch tipo {
        case .indiceAzionario: return 0
        case .rendimentoStato: return 1
        case .spread: return 2
        case .tassoInterbancario: return 3
        case .inflazione: return 4
        case .tassoUfficiale: return 5
        case .altro: return 6
        }
    }

    // MARK: - Occhiello e aggiornamento

    /// Il momento dell'ultimo dato arrivato: scaricamento, importazione o inserimento a mano (nil = mai).
    static func ultimoArrivo(_ archivio: ArchivioMercato) -> Date? {
        let zero = Date(timeIntervalSinceReferenceDate: 0)
        let date = [archivio.ultimoAggiornamento].compactMap { $0 }
            + archivio.serie.map(\.aggiornataIl).filter { $0 > zero }
            + archivio.quote.map(\.importataIl).filter { $0 > zero }
        return date.max()
    }

    /// «Aggiornato oggi alle 18:00», «Aggiornato ieri alle 18:00», «Aggiornato il 28 ottobre», «Mai aggiornato»,
    /// «Aggiornamento in corso…»; «· valori di prova» solo con i dati di prova (§12.1.2).
    static func occhiello(ultimo: Date?, inCorso: Bool, datiDiProva: Bool, oggi: Date, cal: Calendar = .current) -> String {
        let base: String
        if inCorso {
            base = TestiAppMercato.inCorso
        } else if let u = ultimo {
            if cal.isDate(u, inSameDayAs: oggi) {
                base = "Aggiornato oggi alle \(Formati.ora.string(from: u))"
            } else if let ieri = cal.date(byAdding: .day, value: -1, to: oggi), cal.isDate(u, inSameDayAs: ieri) {
                base = "Aggiornato ieri alle \(Formati.ora.string(from: u))"
            } else {
                base = "Aggiornato il \(Formati.giornoMese.string(from: u))"
            }
        } else {
            base = TestiAppMercato.maiAggiornato
        }
        return datiDiProva ? base + " · " + TestiAppMercato.valoriDiProva : base
    }

    /// I dati sono vecchi se nessuna tessera con valore è recente (§12.1.9): «Chi è toccato dall'ultimo aggiornamento».
    static func datiVecchi(_ tessere: [TesseraMercato]) -> Bool {
        let conValore = tessere.filter { !$0.senzaValore }
        return !conValore.isEmpty && conValore.allSatisfy { $0.freschezza == .vecchia }
    }

    // MARK: - Quote per ISIN

    /// La variazione da inizio anno di una quota (%): ultimo valore sul valore in vigore al 31 dicembre dell'anno prima
    /// (nil se manca).
    static func daInizioAnno(_ q: QuotaISIN, oggi: Date, cal: Calendar = .current) -> Double? {
        guard let ultimo = valore(q.punti, al: oggi, cal: cal) else { return nil }
        let anno = cal.component(.year, from: oggi)
        guard let fineAnno = cal.date(from: DateComponents(year: anno - 1, month: 12, day: 31, hour: 12)),
              let inizio = valore(q.punti, al: fineAnno, cal: cal), inizio.valore > 0 else { return nil }
        return (ultimo.valore / inizio.valore - 1) * 100
    }

    /// «circa 3.000 €»: due cifre significative (2.980 → 3.000, 640 → 640, 12.345 → 12.000).
    static func circa(_ v: Double) -> Double {
        let a = abs(v)
        guard a >= 1 else { return 0 }
        let potenza = pow(10, floor(log10(a)) - 1)
        return (v / potenza).rounded() * potenza
    }

    // MARK: - La serie lunga del dettaglio

    /// La serie degli ultimi `mesi` mesi per il dettaglio della tessera: x per data (0 = inizio, 1 = oggi), y da 0 a 1
    /// fra minimo e massimo (0,5 se piatta). Il valore in vigore all'inizio apre la linea; il tasso BCE (un valore per
    /// variazione) arriva fino a oggi. Nil con meno di due punti.
    static func lineaLunga(_ s: SerieMercato, mesi: Int = 12, oggi: Date, cal: Calendar = .current) -> LineaLungaMercato? {
        guard let inizio = cal.date(byAdding: .month, value: -mesi, to: oggi) else { return nil }
        var punti = s.punti.filter { $0.data >= inizio && cal.startOfDay(for: $0.data) <= cal.startOfDay(for: oggi) }
        if let prima = valore(s.punti, al: inizio, cal: cal), (punti.first?.data ?? oggi) > inizio {
            punti.insert(PuntoMercato(data: inizio, valore: prima.valore), at: 0)
        }
        if s.tipo == .tassoUfficiale, let ultimo = punti.last, ultimo.data < oggi {
            punti.append(PuntoMercato(data: oggi, valore: ultimo.valore))
        }
        guard punti.count >= 2, let minimo = punti.map(\.valore).min(), let massimo = punti.map(\.valore).max() else { return nil }
        let durata = max(1, oggi.timeIntervalSince(inizio))
        let ampiezza = massimo - minimo
        let xy = punti.map { p -> PuntoLineaMercato in
            let x = min(1, max(0, p.data.timeIntervalSince(inizio) / durata))
            let y = ampiezza > 1e-12 ? (p.valore - minimo) / ampiezza : 0.5
            return PuntoLineaMercato(x: x, y: y)
        }
        return LineaLungaMercato(punti: xy, minimo: minimo, massimo: massimo, inizio: inizio, fine: oggi, valori: punti.count)
    }
}

/// Un punto della serie lunga, normalizzato (x per data, y fra minimo e massimo).
struct PuntoLineaMercato: Equatable {
    let x: Double
    let y: Double
}

/// La serie lunga del dettaglio: i punti e i limiti per gli assi.
struct LineaLungaMercato: Equatable {
    let punti: [PuntoLineaMercato]
    let minimo: Double
    let massimo: Double
    let inizio: Date
    let fine: Date
    let valori: Int
}
