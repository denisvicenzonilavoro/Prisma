import Foundation

// MARK: - Studio › Cruscotto (versione «Orizzonte», specifica Design/template-novita-specifica.md §2)
// Il lavoro del consulente visto come un portafoglio: ricavi dell'anno per mese e per canale, obiettivi dell'anno,
// imbuto delle proposte, incassi dei prossimi 12 mesi e «il valore e il tempo» per cliente. Motore puro, senza
// SwiftUI, deterministico (riceve `oggi` e il calendario); la Shell lo tiene in cache (DerivatiDati, StatoStudio.swift).
//
// Regole (nessuna cifra inventata):
// - Alleanza: provvigioni stimate SOLO dalle aliquote che il consulente ha inserito (Impostazioni › Studio,
//   `ImpostazioniStudio`). Senza nessuna aliquota le cifre Alleanza sono nil («manca aliquote»); con un'aliquota
//   mancante per qualche posizione quella posizione non entra e si conta in `posizioniSenzaAliquota` («stima»).
//   Base di calcolo: `AliquoteProvvigione` (nuova produzione alla decorrenza, ricorrenti o rinnovi su ogni rata dalla
//   seconda annualità, fino alla scadenza). Contano le posizioni Alleanza in essere con la decorrenza, nelle aree
//   `ImpostazioniStudio.areeProvvigionali`.
// - Indipendente: le parcelle della consulenza (`RicavoConsulenza`). In questo giro non esistono ancora: si passa un
//   elenco vuoto e le cifre sono zero con `nessunaParcella`. Il giro 2 (Parcelle e fatture) passerà le sue.
// - Anno precedente: stessa regola sulle date di un anno prima (anno intero per la linea, «a pari data» per la variazione).

/// Un ricavo della consulenza indipendente (una parcella), come lo legge Studio. Il giro 2 ricava questi valori dalle
/// parcelle vere; qui serve solo la struttura.
struct RicavoConsulenza: Equatable {
    var clienteId: String
    /// La data che conta per i ricavi (emissione o incasso, secondo la scelta del giro 2).
    var data: Date
    var importo: Double
    /// Già incassata: non entra negli incassi futuri.
    var incassata: Bool

    init(clienteId: String, data: Date, importo: Double, incassata: Bool) {
        self.clienteId = clienteId
        self.data = data
        self.importo = importo
        self.incassata = incassata
    }
}

/// Le tre voci degli obiettivi dell'anno, nell'ordine degli anelli (dall'esterno).
enum VoceObiettivoStudio: String, CaseIterable, Identifiable {
    case produzioneAlleanza, nuoviClienti, ricaviConsulenza

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .produzioneAlleanza: return "Produzione Alleanza"
        case .nuoviClienti: return "Nuovi clienti"
        case .ricaviConsulenza: return "Ricavi consulenza"
        }
    }
}

/// Le cinque card del Cruscotto di Studio.
struct CruscottoStudio: Equatable {
    /// I ricavi di un anno, mese per mese e per canale, fino a una data.
    struct Ricavi: Equatable {
        let anno: Int
        /// Quanti mesi si contano: 12 per un anno intero, fino al mese di oggi per l'anno in corso (e «a pari data»).
        let mesiContati: Int
        /// Provvigioni Alleanza stimate per mese (12 valori, gennaio = 0); nil = nessuna aliquota inserita.
        let alleanzaPerMese: [Double]?
        /// Parcelle della consulenza per mese (12 valori).
        let indipendentePerMese: [Double]
        /// Posizioni Alleanza con almeno una provvigione nel periodo ma senza l'aliquota che serve (non entrano).
        let posizioniSenzaAliquota: Int
        /// Non c'è ancora nessuna parcella (giro 1): la parte indipendente è zero per questo.
        let nessunaParcella: Bool

        var mancaAliquote: Bool { alleanzaPerMese == nil }
        /// Le cifre Alleanza sono una stima parziale: qualche posizione è senza aliquota.
        var stima: Bool { posizioniSenzaAliquota > 0 }
        var alleanza: Double? { alleanzaPerMese.map { $0.reduce(0, +) } }
        var indipendente: Double { indipendentePerMese.reduce(0, +) }
        var totale: Double { (alleanza ?? 0) + indipendente }
        /// I due canali insieme, per mese (12 valori).
        var perMese: [Double] { (0..<12).map { (alleanzaPerMese?[$0] ?? 0) + indipendentePerMese[$0] } }
        /// Ricavi cumulati: il 1° gennaio (0) e la fine di ogni mese contato (`mesiContati` + 1 punti, 13 per un anno intero).
        var cumulati: [Double] {
            let mesi = perMese
            var somma = 0.0
            var punti = [0.0]
            for i in 0..<min(max(mesiContati, 0), 12) {
                somma += mesi[i]
                punti.append(somma)
            }
            return punti
        }
        /// C'è almeno un ricavo nel periodo.
        var haDati: Bool { totale > 0 }
    }

    /// Un obiettivo dell'anno e quanto è stato fatto.
    struct Obiettivo: Equatable, Identifiable {
        /// Perché la cifra fatta va letta con una nota.
        enum Avviso: String, Equatable {
            /// I nuovi clienti si contano dalla data di inserimento in Prisma (`Cliente.creatoIl`).
            case dallaDataDiInserimento
            /// Non c'è ancora nessuna parcella: i ricavi della consulenza sono zero per questo.
            case nessunaParcella
        }

        let voce: VoceObiettivoStudio
        let fatto: Double
        /// Il traguardo impostato; nil = non impostato.
        let traguardo: Double?
        let avviso: Avviso?

        var id: VoceObiettivoStudio { voce }
        /// Il traguardo c'è ed è maggiore di zero (un obiettivo a 0 conta come non impostato).
        var impostato: Bool { (traguardo ?? 0) > 0 }
        /// Fatto su traguardo, anche oltre 1 (la cifra può superare il 100%); nil senza traguardo.
        var frazione: Double? {
            guard let t = traguardo, t > 0 else { return nil }
            return fatto / t
        }
        /// La frazione per il disegno dell'anello, fra 0 e 1.
        var frazioneAnello: Double? { frazione.map { min(max($0, 0), 1) } }
    }

    /// Gli obiettivi dell'anno: sempre le tre voci, nell'ordine di `VoceObiettivoStudio`.
    struct Obiettivi: Equatable {
        let anno: Int
        let voci: [Obiettivo]
        /// Solo le voci con un traguardo (gli anelli da disegnare).
        var impostati: [Obiettivo] { voci.filter(\.impostato) }
        /// Nessun obiettivo impostato: la card mostra «Imposta gli obiettivi dell'anno».
        var nessunoImpostato: Bool { impostati.isEmpty }
        func voce(_ v: VoceObiettivoStudio) -> Obiettivo? { voci.first { $0.voce == v } }
    }

    /// L'imbuto delle proposte dell'anno (posizioni create nell'anno che sono o sono state proposte).
    struct Imbuto: Equatable {
        /// Dove si perde di più.
        enum Fase: String, Equatable {
            /// Fra preparate e presentate.
            case primaDellaPresentazione
            /// Fra presentate e firmate.
            case dopoLaPresentazione
        }

        let anno: Int
        let preparate: Int
        let presentate: Int
        let firmate: Int
        /// Media dei giorni da `presentataIl` a `esitoIl` delle sole accettate con entrambe le date; nil se nessuna.
        let giorniMediAllaFirma: Double?
        /// Quante firmate hanno entrambe le date (la base della media).
        let firmateConDate: Int
        /// La fase con la perdita più grande (a parità, dopo la presentazione); nil se non si perde niente.
        let fase: Fase?
        /// Quante proposte si fermano in quella fase.
        let ferme: Int

        /// Firmate su preparate (0…1); nil senza proposte.
        var tassoChiusura: Double? { preparate > 0 ? Double(firmate) / Double(preparate) : nil }
        var vuoto: Bool { preparate == 0 }
    }

    /// Un mese degli incassi futuri.
    struct MeseIncasso: Equatable, Identifiable {
        /// Il primo giorno del mese.
        let inizio: Date
        /// Provvigioni Alleanza stimate; nil = nessuna aliquota inserita.
        let alleanza: Double?
        /// Parcelle future non ancora incassate.
        let indipendente: Double

        var id: Date { inizio }
        var totale: Double { (alleanza ?? 0) + indipendente }
    }

    /// Gli incassi dei prossimi 12 mesi, dal 1° del mese prossimo.
    struct Incassi: Equatable {
        let mesi: [MeseIncasso]
        let mancaAliquote: Bool
        let posizioniSenzaAliquota: Int
        let nessunaParcella: Bool

        var totaleAlleanza: Double? { mancaAliquote ? nil : mesi.reduce(0) { $0 + ($1.alleanza ?? 0) } }
        var totaleIndipendente: Double { mesi.reduce(0) { $0 + $1.indipendente } }
        var totale: Double { (totaleAlleanza ?? 0) + totaleIndipendente }
        var vuoto: Bool { totale <= 0 }
    }

    /// Un cliente nel grafico «il valore e il tempo».
    struct PuntoCliente: Equatable, Identifiable {
        let cliente: Cliente
        /// Ore dell'anno fino a oggi (appuntamenti conclusi o con un incontro).
        let ore: Double
        /// Ricavi dell'anno fino a oggi: provvigioni stimate più parcelle.
        let ricavi: Double
        /// Nella zona «molto tempo, poco valore».
        let inZona: Bool

        var id: String { cliente.id }
    }

    /// «Il valore e il tempo»: ore e ricavi per cliente e la zona «molto tempo, poco valore».
    struct ValoreTempo: Equatable {
        /// Il criterio della zona, da mostrare nell'interfaccia.
        static let criterio = "Molto tempo, poco valore: i clienti con più ore della mediana e meno ricavi della mediana "
            + "dei clienti del grafico (servono almeno \(ValoreTempo.minimoClienti) clienti con ore nell'anno)."
        /// Sotto questo numero di clienti le mediane non dicono niente: niente zona.
        static let minimoClienti = 3

        let anno: Int
        /// I clienti con ore nell'anno, dal più impegnativo (ore decrescenti, poi nome).
        let punti: [PuntoCliente]
        /// Mediana delle ore; nil se la zona non si calcola.
        let sogliaOre: Double?
        /// Mediana dei ricavi; nil se la zona non si calcola.
        let sogliaRicavi: Double?
        /// I ricavi per cliente sono parziali (mancano aliquote o parcelle).
        let ricaviParziali: Bool

        var vuoto: Bool { punti.isEmpty }
        var inZona: [PuntoCliente] { punti.filter(\.inZona) }
    }

    /// Le frasi degli stati vuoti e dei dati mancanti (le cifre mancanti non si inventano).
    static let fraseSenzaAliquote = "Inserisci le tue aliquote in Impostazioni › Studio"
    static let fraseSenzaObiettivi = "Imposta gli obiettivi dell'anno"

    /// Il giorno del calcolo.
    let oggi: Date
    let anno: Int
    /// I ricavi dell'anno in corso fino a oggi.
    let ricavi: Ricavi
    /// L'anno precedente intero (la linea tratteggiata).
    let annoPrecedente: Ricavi
    /// L'anno precedente fino allo stesso giorno di un anno fa (per la variazione).
    let annoPrecedenteAPariData: Ricavi
    let obiettivi: Obiettivi
    let imbuto: Imbuto
    let incassi: Incassi
    let valoreTempo: ValoreTempo
    /// Nessuna aliquota inserita: niente cifre Alleanza.
    let mancaAliquote: Bool
    /// Posizioni Alleanza in essere senza la decorrenza: non si sa quando maturano, non entrano.
    let posizioniSenzaDecorrenza: Int

    /// Variazione dei ricavi rispetto all'anno prima a pari data (0,18 = +18%); nil se l'anno prima a pari data è 0.
    var variazione: Double? {
        let base = annoPrecedenteAPariData.totale
        guard base > 0 else { return nil }
        return (ricavi.totale - base) / base
    }

    /// Nessun ricavo nell'anno prima: «primo anno in Prisma», niente linea tratteggiata né percentuale.
    var primoAnno: Bool { !annoPrecedente.haDati }
}

enum MotoreStudio {
    /// Il tipo di una provvigione Alleanza (la base di calcolo è in `AliquoteProvvigione`).
    enum TipoProvvigione: String, CaseIterable, Identifiable {
        case nuovaProduzione, ricorrente, rinnovo

        var id: String { rawValue }

        var nome: String {
            switch self {
            case .nuovaProduzione: return "Nuova produzione"
            case .ricorrente: return "Ricorrenti"
            case .rinnovo: return "Rinnovi"
            }
        }
    }

    /// Una provvigione Alleanza che matura in una data.
    struct Evento: Equatable {
        let posizioneId: String
        let clienteId: String
        let data: Date
        /// Su cosa si calcola (€): premio unico più prima annualità, oppure la rata.
        let base: Double
        let tipo: TipoProvvigione
        /// La provvigione stimata (€); nil se l'aliquota che serve non è inserita.
        let importo: Double?
    }

    /// Quante rate al massimo si scorrono per una posizione in un intervallo (un intervallo di Studio dura meno di 3 anni).
    private static let rateMassime = 400

    /// Le provvigioni di una posizione con la data in [`da`, `a`). Contano solo le posizioni Alleanza in essere con la
    /// decorrenza, nelle aree `ImpostazioniStudio.areeProvvigionali`:
    /// - alla decorrenza, nuova produzione sul versamento iniziale più il premio annuo (`AliquoteProvvigione.nuovaProduzione`);
    /// - a ogni rata dalla seconda annualità (rata numero `volteAllAnno` in poi), prima della scadenza, ricorrenti o
    ///   rinnovi sulla rata (`AliquoteProvvigione.successiva(area:)`).
    /// Le rate si contano dalla decorrenza (decorrenza + k × 12/volte mesi), senza scorrerle tutte dall'inizio.
    static func eventi(_ p: Posizione, studio: ImpostazioniStudio, da: Date, a: Date, cal: Calendar = .current) -> [Evento] {
        guard p.canale == .alleanza, p.stato == .inEssere, ImpostazioniStudio.areeProvvigionali.contains(p.area),
              let decorrenza = p.decorrenza, da < a else { return [] }
        let aliquote = studio.aliquoteInserite(per: p.area)
        var elenco: [Evento] = []
        func aggiungi(_ data: Date, base: Double, tipo: TipoProvvigione, aliquota: Double?) {
            guard base.isFinite, base > 0, data >= da, data < a else { return }
            elenco.append(Evento(posizioneId: p.id, clienteId: p.clienteId, data: data, base: base, tipo: tipo,
                                 importo: aliquota.map { base * $0 / 100 }))
        }
        // Nuova produzione alla decorrenza
        aggiungi(decorrenza, base: max(0, p.versamentoIniziale) + max(0, p.premioAnnuo), tipo: .nuovaProduzione,
                 aliquota: aliquote?.nuovaProduzione)
        // Rate dalla seconda annualità
        let volte = p.frequenza.volteAllAnno
        guard volte > 0, p.premio > 0, p.premio.isFinite else { return elenco }
        let passo = 12 / volte
        let tipo = AliquoteProvvigione.voceSuccessiva(area: p.area)
        let aliquota = aliquote?.successiva(area: p.area)
        let mesiAlInizio = cal.dateComponents([.month], from: decorrenza, to: da).month ?? 0
        var k = max(volte, mesiAlInizio / passo - 1)
        var giri = 0
        while giri < rateMassime {
            guard let data = cal.date(byAdding: .month, value: k * passo, to: decorrenza), data < a else { break }
            if let fine = p.scadenza, data >= fine { break }
            aggiungi(data, base: p.premio, tipo: tipo, aliquota: aliquota)
            k += 1
            giri += 1
        }
        return elenco
    }

    /// Il cruscotto di Studio dai dati di Prisma. `parcelle`: i ricavi della consulenza (vuoto in questo giro).
    static func calcola(_ dati: DatiPrisma, parcelle: [RicavoConsulenza] = [], oggi: Date, cal: Calendar = .current) -> CruscottoStudio {
        calcola(clienti: dati.clienti, posizioni: dati.posizioni, appuntamenti: dati.appuntamenti, incontri: dati.incontri,
                studio: dati.impostazioni.studio, parcelle: parcelle, oggi: oggi, cal: cal)
    }

    /// Il cruscotto di Studio. Contano solo i `clienti` dati (posizioni, appuntamenti e parcelle degli altri si ignorano).
    /// In O(P + A + I + R): ogni posizione dà al più qualche decina di rate nell'intervallo.
    static func calcola(clienti: [Cliente], posizioni: [Posizione], appuntamenti: [Appuntamento], incontri: [Incontro],
                        studio: ImpostazioniStudio, parcelle: [RicavoConsulenza] = [], oggi: Date,
                        cal: Calendar = .current) -> CruscottoStudio {
        let anno = cal.component(.year, from: oggi)
        let oggiInizio = cal.startOfDay(for: oggi)
        let domani = cal.date(byAdding: .day, value: 1, to: oggiInizio) ?? oggi
        let inizioAnno = cal.date(from: DateComponents(year: anno, month: 1, day: 1)) ?? oggiInizio
        let inizioAnnoProssimo = cal.date(byAdding: .year, value: 1, to: inizioAnno) ?? domani
        let inizioAnnoPrima = cal.date(byAdding: .year, value: -1, to: inizioAnno) ?? inizioAnno
        let pariDataPrima = cal.date(byAdding: .year, value: -1, to: domani) ?? inizioAnno
        let inizioMese = cal.date(from: cal.dateComponents([.year, .month], from: oggi)) ?? oggiInizio
        let inizioIncassi = cal.date(byAdding: .month, value: 1, to: inizioMese) ?? domani
        let fineIncassi = cal.date(byAdding: .month, value: 12, to: inizioIncassi) ?? inizioIncassi
        let meseDiOggi = cal.component(.month, from: oggi)

        let ids = Set(clienti.map(\.id))
        let mie = posizioni.filter { ids.contains($0.clienteId) }
        let mieParcelle = parcelle.filter { ids.contains($0.clienteId) && $0.importo.isFinite && $0.importo > 0 }
        let mancaAliquote = studio.senzaAliquote
        let nessunaParcella = parcelle.isEmpty

        // Tutte le provvigioni dall'inizio dell'anno prima alla fine della finestra degli incassi, in un passaggio
        let fineEventi = max(fineIncassi, inizioAnnoProssimo)
        var eventi: [Evento] = []
        var senzaDecorrenza = 0
        for p in mie {
            if p.canale == .alleanza, p.stato == .inEssere, p.decorrenza == nil,
               ImpostazioniStudio.areeProvvigionali.contains(p.area) {
                senzaDecorrenza += 1
            }
            eventi.append(contentsOf: Self.eventi(p, studio: studio, da: inizioAnnoPrima, a: fineEventi, cal: cal))
        }

        // Ricavi di un anno fino a una data (esclusa)
        func ricavi(annoInizio: Date, fino: Date, mesiContati: Int) -> CruscottoStudio.Ricavi {
            var alleanza = [Double](repeating: 0, count: 12)
            var indipendente = [Double](repeating: 0, count: 12)
            var senza = Set<String>()
            for e in eventi where e.data >= annoInizio && e.data < fino {
                if let importo = e.importo {
                    alleanza[cal.component(.month, from: e.data) - 1] += importo
                } else {
                    senza.insert(e.posizioneId)
                }
            }
            for r in mieParcelle where r.data >= annoInizio && r.data < fino {
                indipendente[cal.component(.month, from: r.data) - 1] += r.importo
            }
            return CruscottoStudio.Ricavi(anno: cal.component(.year, from: annoInizio), mesiContati: mesiContati,
                                          alleanzaPerMese: mancaAliquote ? nil : alleanza, indipendentePerMese: indipendente,
                                          posizioniSenzaAliquota: mancaAliquote ? 0 : senza.count, nessunaParcella: nessunaParcella)
        }
        let ricaviAnno = ricavi(annoInizio: inizioAnno, fino: domani, mesiContati: meseDiOggi)
        let annoPrima = ricavi(annoInizio: inizioAnnoPrima, fino: inizioAnno, mesiContati: 12)
        let pariData = ricavi(annoInizio: inizioAnnoPrima, fino: min(pariDataPrima, inizioAnno), mesiContati: meseDiOggi)

        // Obiettivi dell'anno
        let traguardi = studio.obiettiviImpostati(anno: anno)
        // Produzione Alleanza: versamenti iniziali più premi annui delle posizioni Alleanza in essere con decorrenza nell'anno
        var produzione = 0.0
        for p in mie where p.canale == .alleanza && p.stato == .inEssere && ImpostazioniStudio.areeProvvigionali.contains(p.area) {
            guard let d = p.decorrenza, d >= inizioAnno, d < domani else { continue }
            let importo = max(0, p.versamentoIniziale) + max(0, p.premioAnnuo)
            if importo.isFinite { produzione += importo }
        }
        let nuovi = clienti.filter { $0.creatoIl >= inizioAnno && $0.creatoIl < domani }.count
        let obiettivi = CruscottoStudio.Obiettivi(anno: anno, voci: [
            CruscottoStudio.Obiettivo(voce: .produzioneAlleanza, fatto: produzione, traguardo: traguardi?.produzioneAlleanza, avviso: nil),
            CruscottoStudio.Obiettivo(voce: .nuoviClienti, fatto: Double(nuovi), traguardo: traguardi?.nuoviClienti.map { Double($0) },
                                      avviso: .dallaDataDiInserimento),
            CruscottoStudio.Obiettivo(voce: .ricaviConsulenza, fatto: ricaviAnno.indipendente, traguardo: traguardi?.ricaviConsulenza,
                                      avviso: nessunaParcella ? .nessunaParcella : nil),
        ])

        // Imbuto delle proposte create nell'anno
        var preparate = 0, presentate = 0, firmate = 0
        var giorniFirma: [Int] = []
        for p in mie where p.creataIl >= inizioAnno && p.creataIl < domani && (p.stato == .proposta || p.esito != nil) {
            preparate += 1
            let esito = p.esito
            if p.seguito?.presentataIl != nil || (esito != nil && esito != .bozza) { presentate += 1 }
            if esito == .accettata {
                firmate += 1
                if let da = p.seguito?.presentataIl, let a = p.seguito?.esitoIl {
                    let g = cal.dateComponents([.day], from: cal.startOfDay(for: da), to: cal.startOfDay(for: a)).day ?? 0
                    giorniFirma.append(max(0, g))
                }
            }
        }
        let persePrima = preparate - presentate
        let perseDopo = presentate - firmate
        let fase: CruscottoStudio.Imbuto.Fase?
        let ferme: Int
        if persePrima <= 0 && perseDopo <= 0 {
            fase = nil
            ferme = 0
        } else if perseDopo >= persePrima {
            fase = .dopoLaPresentazione
            ferme = perseDopo
        } else {
            fase = .primaDellaPresentazione
            ferme = persePrima
        }
        let imbuto = CruscottoStudio.Imbuto(
            anno: anno, preparate: preparate, presentate: presentate, firmate: firmate,
            giorniMediAllaFirma: giorniFirma.isEmpty ? nil : Double(giorniFirma.reduce(0, +)) / Double(giorniFirma.count),
            firmateConDate: giorniFirma.count, fase: fase, ferme: ferme)

        // Incassi dei prossimi 12 mesi, dal 1° del mese prossimo
        let annoIncassi = cal.component(.year, from: inizioIncassi)
        let meseIncassi = cal.component(.month, from: inizioIncassi)
        func indiceIncasso(_ d: Date) -> Int? {
            guard d >= inizioIncassi, d < fineIncassi else { return nil }
            let i = (cal.component(.year, from: d) - annoIncassi) * 12 + cal.component(.month, from: d) - meseIncassi
            return i >= 0 && i < 12 ? i : nil
        }
        var incassoAlleanza = [Double](repeating: 0, count: 12)
        var incassoIndipendente = [Double](repeating: 0, count: 12)
        var senzaAliquotaIncassi = Set<String>()
        for e in eventi {
            guard let i = indiceIncasso(e.data) else { continue }
            if let importo = e.importo { incassoAlleanza[i] += importo } else { senzaAliquotaIncassi.insert(e.posizioneId) }
        }
        for r in mieParcelle where !r.incassata {
            if let i = indiceIncasso(r.data) { incassoIndipendente[i] += r.importo }
        }
        let mesiIncasso: [CruscottoStudio.MeseIncasso] = (0..<12).map { i in
            CruscottoStudio.MeseIncasso(inizio: cal.date(byAdding: .month, value: i, to: inizioIncassi) ?? inizioIncassi,
                                        alleanza: mancaAliquote ? nil : incassoAlleanza[i], indipendente: incassoIndipendente[i])
        }
        let incassi = CruscottoStudio.Incassi(mesi: mesiIncasso, mancaAliquote: mancaAliquote,
                                              posizioniSenzaAliquota: mancaAliquote ? 0 : senzaAliquotaIncassi.count,
                                              nessunaParcella: nessunaParcella)

        // Il valore e il tempo: ore dagli appuntamenti dell'anno fino a oggi, conclusi o con un incontro collegato
        let conIncontro = Set(incontri.compactMap(\.appuntamentoId))
        var minuti: [String: Int] = [:]
        for a in appuntamenti where ids.contains(a.clienteId) && a.inizio >= inizioAnno && a.inizio < domani && a.durataMinuti > 0 {
            guard a.stato == .concluso || conIncontro.contains(a.id) else { continue }
            minuti[a.clienteId, default: 0] += a.durataMinuti
        }
        var ricaviCliente: [String: Double] = [:]
        for e in eventi where e.data >= inizioAnno && e.data < domani {
            if let importo = e.importo { ricaviCliente[e.clienteId, default: 0] += importo }
        }
        for r in mieParcelle where r.data >= inizioAnno && r.data < domani {
            ricaviCliente[r.clienteId, default: 0] += r.importo
        }
        let grezzi: [(cliente: Cliente, ore: Double, ricavi: Double)] = clienti.compactMap { c in
            guard let m = minuti[c.id], m > 0 else { return nil }
            return (cliente: c, ore: Double(m) / 60, ricavi: ricaviCliente[c.id] ?? 0)
        }
        // I ricavi per cliente si confrontano solo se Prisma ne sa qualcosa (aliquote o parcelle)
        let ricaviNoti = !mancaAliquote || !mieParcelle.isEmpty
        let zona = ricaviNoti && grezzi.count >= CruscottoStudio.ValoreTempo.minimoClienti
        let sogliaOre = zona ? mediana(grezzi.map(\.ore)) : nil
        let sogliaRicavi = zona ? mediana(grezzi.map(\.ricavi)) : nil
        let punti = grezzi
            .map { g in
                CruscottoStudio.PuntoCliente(
                    cliente: g.cliente, ore: g.ore, ricavi: g.ricavi,
                    inZona: sogliaOre.map { g.ore > $0 } == true && sogliaRicavi.map { g.ricavi < $0 } == true)
            }
            .sorted { a, b in
                if a.ore != b.ore { return a.ore > b.ore }
                if a.cliente.nome != b.cliente.nome { return a.cliente.nome < b.cliente.nome }
                return a.cliente.id < b.cliente.id
            }
        let valoreTempo = CruscottoStudio.ValoreTempo(
            anno: anno, punti: punti, sogliaOre: sogliaOre, sogliaRicavi: sogliaRicavi,
            ricaviParziali: mancaAliquote || ricaviAnno.stima || nessunaParcella)

        return CruscottoStudio(oggi: oggi, anno: anno, ricavi: ricaviAnno, annoPrecedente: annoPrima,
                               annoPrecedenteAPariData: pariData, obiettivi: obiettivi, imbuto: imbuto, incassi: incassi,
                               valoreTempo: valoreTempo, mancaAliquote: mancaAliquote,
                               posizioniSenzaDecorrenza: senzaDecorrenza)
    }

    /// La mediana (media dei due centrali con un numero pari di valori); nil senza valori.
    static func mediana(_ valori: [Double]) -> Double? {
        guard !valori.isEmpty else { return nil }
        let ordinati = valori.sorted()
        let n = ordinati.count
        return n % 2 == 1 ? ordinati[n / 2] : (ordinati[n / 2 - 1] + ordinati[n / 2]) / 2
    }
}
