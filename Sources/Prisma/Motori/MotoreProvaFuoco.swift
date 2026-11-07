import Foundation

// Posizioni › La prova del fuoco (Orizzonte, giro 4; specifica §6 di Design/template-novita-specifica.md).
// Uno scenario avverso applicato a TUTTI i clienti insieme: la perdita di ogni posizione in essere viene dal motore
// della prova di resistenza che c'è già (composizione per classe di attivo, crisi del passato, potere d'acquisto);
// l'effetto sugli obiettivi viene dai conti di `MotoreObiettivo` (copertura alla scadenza, prima e dopo).
// Tutto puro: nessun accesso all'archivio né alla vista, si può eseguire fuori dal thread principale.
// Dove la posizione non dice la quota azionaria, i titoli di Stato o la durata delle obbligazioni si usano le stime
// che la prova di resistenza usa già (`MotoreResistenza.composizione`) e la durata predefinita della specifica,
// e la posizione è segnata «stima».

/// Lo scenario della prova del fuoco.
enum ScenarioFuoco: Hashable, Sendable {
    /// Mercati in calo: % sulle azioni (5…45).
    case mercati(calo: Double)
    /// Tassi in rialzo: punti percentuali (0,5…4).
    case tassi(punti: Double)
    /// Inflazione al `tasso` % l'anno per `anni` anni (2,5…9, per 3 anni).
    case inflazione(tasso: Double, anni: Int)
    /// Una crisi vera del passato (2008, 2020; anche 2022) da `MotoreResistenza.crisiDelPassato`.
    case crisi(anno: Int)

    /// L'inflazione dello scenario con i suoi anni (sugli obiettivi), nil se lo scenario non la tocca.
    var inflazioneIniziale: (tasso: Double, anni: Int)? {
        if case let .inflazione(tasso, anni) = self { return (tasso, anni) }
        return nil
    }

    /// La crisi del passato dello scenario (nil se non è una crisi o se l'anno non c'è).
    var crisiStorica: CrisiStorica? {
        if case let .crisi(anno) = self { return MotoreResistenza.crisiDelPassato.first { $0.anno == anno } }
        return nil
    }

    /// Il titolo breve («Mercati −25%», «Tassi +2 punti», «Inflazione al 5%», «Come nel 2008»).
    var titolo: String {
        switch self {
        case let .mercati(calo): return "Mercati \(Formati.meno)\(CifreDoc.condizione(calo))"
        case let .tassi(punti): return "Tassi +\(Formati.numeroFormatter.string(from: NSNumber(value: punti)) ?? "\(punti)") punti"
        case let .inflazione(tasso, _): return "Inflazione al \(CifreDoc.condizione(tasso))"
        case let .crisi(anno): return "Come nel \(anno)"
        }
    }
}

/// Una posizione in essere di un cliente nella prova: quanto perde e se la composizione è stimata.
struct VoceProvaFuoco: Identifiable, Equatable, Sendable {
    let posizioneId: String
    let nome: String
    let valore: Double
    /// Euro persi (negativo = guadagno, per esempio i titoli di Stato nel 2008).
    let perdita: Double
    /// true se quota azionaria, titoli di Stato o durata delle obbligazioni sono stimati (la «≈» della riga).
    let stimata: Bool
    var id: String { posizioneId }
}

/// Un cliente nella prova del fuoco.
struct RigaProvaFuoco: Identifiable, Equatable, Sendable {
    let clienteId: String
    let nome: String
    let telefono: String
    /// L'obiettivo che scende di più (nil = nessun obiettivo con importo e scadenza futura).
    let obiettivoId: String?
    let titoloObiettivo: String?
    /// Copertura dell'obiettivo alla scadenza, oggi e dopo lo scenario (0…1, come `EsitoObiettivo.copertura`).
    let coperturaOggi: Double
    let coperturaDopo: Double
    /// Euro persi su tutte le posizioni finanziarie in essere (negativo = guadagno).
    let perdita: Double
    /// Le posizioni finanziarie in essere che cambiano valore, dalla più colpita.
    let voci: [VoceProvaFuoco]
    /// L'obiettivo mostrato non ha posizioni collegate in essere: la barra non si muove (tranne con l'inflazione).
    let collegateAssenti: Bool
    var id: String { clienteId }

    /// Il calo della copertura, in punti (0…100), arrotondato al milionesimo di punto: 10,0 punti restano 10,0
    /// anche quando la sottrazione in virgola mobile dà 9,999999999999998.
    var calo: Double { obiettivoId == nil ? 0 : MotoreProvaFuoco.punti(coperturaOggi - coperturaDopo) }
    /// true se almeno una posizione ha la composizione o la durata stimate.
    var stimata: Bool { voci.contains(where: \.stimata) }
    var posizioniStimate: Int { voci.filter(\.stimata).count }
    var oltreSoglia: Bool { obiettivoId != nil && calo > MotoreProvaFuoco.sogliaAllarme }
}

/// L'esito della prova del fuoco su tutti i clienti.
struct EsitoProvaFuoco: Equatable, Sendable {
    let scenario: ScenarioFuoco
    /// «Chi chiamare, in ordine» (`MotoreProvaFuoco.criterioOrdine`).
    let righe: [RigaProvaFuoco]
    /// Clienti con un obiettivo che scende di più di `sogliaAllarme` punti.
    let oltreSoglia: Int
    /// Somma delle perdite di tutti i clienti (anche di quelli senza obiettivi).
    let perditaTotale: Double
    /// Posizioni con la composizione o la durata stimate, su tutti i clienti.
    let posizioniStimate: Int

    var vuoto: Bool { righe.isEmpty }
}

/// Ciò che non cambia con il cursore, calcolato una volta: per ogni cliente le posizioni finanziarie in essere con
/// la loro composizione e gli obiettivi validi con la copertura di oggi. A ogni passo del cursore si rifanno solo
/// le perdite e le proiezioni delle posizioni collegate.
/// Contiene solo valori (struct dell'archivio): si passa senza rischi a un altro thread.
struct BaseProvaFuoco: @unchecked Sendable {
    struct PosizioneComposta {
        let posizione: Posizione
        let composizione: ComposizionePosizione?
        /// Durata finanziaria della parte obbligazionaria (anni) e se è stimata.
        let durata: Double
        let durataStimata: Bool
    }

    struct ObiettivoBase {
        let obiettivo: Obiettivo
        let coperturaOggi: Double
        /// Le posizioni collegate in essere (quelle che lo scenario scuote).
        let collegate: [Posizione]
    }

    struct ClienteBase {
        let cliente: Cliente
        /// Investimento, risparmio, previdenza e liquidità in essere, con valore (come `MotoreResistenza.calcola`).
        let finanziarie: [PosizioneComposta]
        /// Tutte le posizioni del cliente (per le proiezioni degli obiettivi).
        let posizioni: [Posizione]
        let obiettivi: [ObiettivoBase]
    }

    let clienti: [ClienteBase]
    let oggi: Date
}

enum MotoreProvaFuoco {
    /// «Più di 10 punti»: 10,0 non conta.
    static let sogliaAllarme = 10.0
    /// Sopra 5 punti la riga è arancio, sopra 10 rossa.
    static let sogliaAttenzione = 5.0
    /// Durata finanziaria della parte obbligazionaria quando la posizione non la dice, per tipologia (anni).
    /// Valori della specifica (§6.5.3, da confermare con l'utente): monetari 0,5; obbligazionari a breve termine 2;
    /// obbligazionari 6; bilanciati e flessibili 5; previdenza non in gestione separata 7; altrimenti 5.
    static let durataPredefinita: [String: Double] = [
        "monetari": 0.5, "breve termine": 2, "obbligazionari": 6, "bilanciat": 5, "flessibil": 5, "previdenza": 7, "altro": 5,
    ]

    /// Il livello di una riga, per il colore della barra (blu, arancio sopra `sogliaAttenzione`, rosso sopra
    /// `sogliaAllarme`): i colori stanno nel tema.
    enum Livello: Sendable { case tranquillo, attenzione, allarme }

    static func livello(calo: Double) -> Livello {
        if calo > sogliaAllarme { return .allarme }
        return calo > sogliaAttenzione ? .attenzione : .tranquillo
    }

    /// Una differenza di copertura (frazione) in punti, mai negativa, arrotondata al milionesimo di punto.
    static func punti(_ differenza: Double) -> Double { max(0, (differenza * 100 * 1e6).rounded() / 1e6) }

    /// Il criterio dell'elenco «Chi chiamare, in ordine», detto all'utente.
    static let criterioOrdine = "Prima chi perde più punti sull'obiettivo; a pari punti chi perde più euro. In fondo i clienti senza obiettivi, per euro persi."

    /// La durata della parte obbligazionaria di una posizione: dalla tipologia (stimata, la posizione non ha il campo).
    static func durataObbligazioni(_ p: Posizione) -> (anni: Double, stimata: Bool) {
        let t = p.tipologia.lowercased()
        let chiave: String
        if t.contains("monetari") { chiave = "monetari" }
        else if t.contains("obbligazionari") && t.contains("breve") { chiave = "breve termine" }
        else if t.contains("obbligazionari") { chiave = "obbligazionari" }
        else if t.contains("bilanciat") { chiave = "bilanciat" }
        else if t.contains("flessibil") { chiave = "flessibil" }
        else if p.area == .previdenza { chiave = "previdenza" }
        else { chiave = "altro" }
        return (durataPredefinita[chiave] ?? 5, true)
    }

    // MARK: - Preparazione (una volta per dati e giorno)

    /// Prepara la base per tutti i clienti (in quest'ordine). Gli obiettivi validi hanno importo > 0 e scadenza futura.
    static func prepara(clienti: [Cliente], posizioni: [Posizione], obiettivi: [Obiettivo], oggi: Date,
                        annullato: () -> Bool = { false }) -> BaseProvaFuoco? {
        var perCliente: [String: [Posizione]] = [:]
        for p in posizioni { perCliente[p.clienteId, default: []].append(p) }
        var obiettiviPer: [String: [Obiettivo]] = [:]
        for o in obiettivi { obiettiviPer[o.clienteId, default: []].append(o) }
        var righe: [BaseProvaFuoco.ClienteBase] = []
        righe.reserveCapacity(clienti.count)
        for c in clienti {
            if annullato() { return nil }
            let tutte = perCliente[c.id] ?? []
            let finanziarie = tutte.filter { $0.stato == .inEssere && $0.valore > 0 && ($0.area.proiettabile || $0.area == .liquidita) }
                .map { p -> BaseProvaFuoco.PosizioneComposta in
                    let d = durataObbligazioni(p)
                    return .init(posizione: p, composizione: MotoreResistenza.composizione(p), durata: d.anni, durataStimata: d.stimata)
                }
            let validi = (obiettiviPer[c.id] ?? []).filter { $0.importo > 0 && $0.scadenza > oggi }.map { o -> BaseProvaFuoco.ObiettivoBase in
                let collegate = tutte.filter { o.posizioniCollegate.contains($0.id) && $0.stato == .inEssere }
                return .init(obiettivo: o, coperturaOggi: MotoreObiettivo.coperturaAScadenza(o, posizioni: collegate, data: oggi),
                             collegate: collegate)
            }
            righe.append(.init(cliente: c, finanziarie: finanziarie, posizioni: tutte, obiettivi: validi))
        }
        return BaseProvaFuoco(clienti: righe, oggi: oggi)
    }

    // MARK: - Lo scenario

    /// Variazione del valore di una posizione nello scenario, in frazione (negativa = calo), e se è stimata.
    /// Mercati: solo la parte azionaria. Tassi: la parte obbligazionaria per la durata (gestione separata e liquidità
    /// a zero). Inflazione: il valore nominale non cambia (cambia il potere d'acquisto, vedi `perdita`). Crisi: la
    /// composizione per classe di attivo, come `MotoreResistenza.crisi`.
    static func variazione(_ x: BaseProvaFuoco.PosizioneComposta, _ s: ScenarioFuoco) -> (frazione: Double, stimata: Bool) {
        guard let c = x.composizione else { return (0, false) }
        switch s {
        case let .mercati(calo):
            return (-c.azioni * max(0, calo) / 100, c.stimata && c.azioni > 0)
        case let .tassi(punti):
            let obbligazioni = c.governativi + c.societarie
            guard obbligazioni > 0 else { return (0, false) }
            let v = -obbligazioni * x.durata * max(0, punti) / 100
            return (max(-1, v), x.durataStimata || c.stimata)
        case .inflazione:
            return (0, false)
        case .crisi:
            guard let k = s.crisiStorica else { return (0, false) }
            return (c.variazione(k) / 100, c.stimata)
        }
    }

    /// Variazione di una posizione qualunque (prepara la composizione al momento): per le prove e per Ruby.
    static func variazione(_ p: Posizione, _ s: ScenarioFuoco) -> Double {
        let d = durataObbligazioni(p)
        let x = BaseProvaFuoco.PosizioneComposta(posizione: p, composizione: MotoreResistenza.composizione(p), durata: d.anni,
                                                durataStimata: d.stimata)
        return variazione(x, s).frazione
    }

    /// Gli euro persi da una posizione nello scenario (negativo = guadagno) e se la cifra è stimata.
    /// Nelle crisi una variazione sotto mezzo euro non conta, come in `MotoreResistenza.crisi`.
    static func perdita(_ x: BaseProvaFuoco.PosizioneComposta, _ s: ScenarioFuoco) -> (euro: Double, stimata: Bool) {
        if case let .inflazione(tasso, anni) = s {
            return (MotoreResistenza.perditaInflazione(x.posizione, tasso: tasso, anni: anni) ?? 0, false)
        }
        let v = variazione(x, s)
        let euro = -(x.posizione.valore * v.frazione)
        if case .crisi = s, abs(euro) < 0.5 { return (0, false) }
        return (euro, v.stimata && abs(euro) >= 0.5)
    }

    /// La prova del fuoco su tutti i clienti della base. `annullato` si controlla a ogni cliente: se diventa vero
    /// il calcolo si ferma e restituisce nil (il cursore si è mosso di nuovo: vince l'ultimo).
    static func calcola(_ s: ScenarioFuoco, base: BaseProvaFuoco, annullato: () -> Bool = { false }) -> EsitoProvaFuoco? {
        var righe: [RigaProvaFuoco] = []
        righe.reserveCapacity(base.clienti.count)
        for c in base.clienti {
            if annullato() { return nil }
            righe.append(riga(c, s, oggi: base.oggi))
        }
        let ordinate = ordina(righe)
        return EsitoProvaFuoco(scenario: s, righe: ordinate,
                               oltreSoglia: ordinate.filter(\.oltreSoglia).count,
                               perditaTotale: ordinate.reduce(0) { $0 + $1.perdita },
                               posizioniStimate: ordinate.reduce(0) { $0 + $1.posizioniStimate })
    }

    /// Prepara e calcola in un colpo (prove, istantanee, Ruby).
    static func calcola(_ s: ScenarioFuoco, clienti: [Cliente], posizioni: [Posizione], obiettivi: [Obiettivo],
                        oggi: Date) -> EsitoProvaFuoco {
        let base = prepara(clienti: clienti, posizioni: posizioni, obiettivi: obiettivi, oggi: oggi)
            ?? BaseProvaFuoco(clienti: [], oggi: oggi)
        return calcola(s, base: base) ?? EsitoProvaFuoco(scenario: s, righe: [], oltreSoglia: 0, perditaTotale: 0, posizioniStimate: 0)
    }

    /// Fuori dal thread principale, annullabile: se il compito che la chiama viene annullato, il calcolo si ferma al
    /// cliente successivo e il risultato è nil. Chi pubblica il risultato lo fa sul thread principale
    /// (`CalcoloProvaFuoco`).
    static func calcolaInSottofondo(_ s: ScenarioFuoco, base: BaseProvaFuoco) async -> EsitoProvaFuoco? {
        let lavoro = Task.detached(priority: .userInitiated) { () -> EsitoProvaFuoco? in
            MotoreProvaFuoco.calcola(s, base: base, annullato: { Task.isCancelled })
        }
        return await withTaskCancellationHandler {
            await lavoro.value
        } onCancel: {
            lavoro.cancel()
        }
    }

    /// L'ordine di «Chi chiamare» (`criterioOrdine`): con obiettivo per calo decrescente, a pari calo per perdita
    /// decrescente; poi i clienti senza obiettivi per perdita decrescente; a parità il nome.
    static func ordina(_ righe: [RigaProvaFuoco]) -> [RigaProvaFuoco] {
        righe.sorted { a, b in
            let conA = a.obiettivoId != nil, conB = b.obiettivoId != nil
            if conA != conB { return conA }
            if conA, abs(a.calo - b.calo) > 1e-9 { return a.calo > b.calo }
            if abs(a.perdita - b.perdita) > 0.005 { return a.perdita > b.perdita }
            return a.nome.localizedStandardCompare(b.nome) == .orderedAscending
        }
    }

    // MARK: - Un cliente

    private static func riga(_ c: BaseProvaFuoco.ClienteBase, _ s: ScenarioFuoco, oggi: Date) -> RigaProvaFuoco {
        var voci: [VoceProvaFuoco] = []
        var frazioni: [String: Double] = [:]
        for x in c.finanziarie {
            let v = variazione(x, s)
            frazioni[x.posizione.id] = v.frazione
            let p = perdita(x, s)
            if abs(p.euro) >= 0.5 {
                voci.append(VoceProvaFuoco(posizioneId: x.posizione.id, nome: x.posizione.nome, valore: x.posizione.valore,
                                           perdita: p.euro, stimata: p.stimata))
            }
        }
        voci.sort { $0.perdita > $1.perdita }
        let perditaTotale = voci.reduce(0) { $0 + $1.perdita }

        // L'obiettivo che scende di più; a pari calo la priorità più alta, poi la scadenza più vicina
        var scelto: (base: BaseProvaFuoco.ObiettivoBase, dopo: Double, calo: Double)?
        for o in c.obiettivi {
            let scosse = o.collegate.map { p -> Posizione in
                let f = frazioni[p.id] ?? variazione(p, s)
                guard f != 0 else { return p }
                var q = p
                q.controvalore = max(0, p.valore * (1 + f))
                return q
            }
            let dopo = MotoreObiettivo.coperturaAScadenza(o.obiettivo, posizioni: scosse,
                                                         inflazioneIniziale: s.inflazioneIniziale, data: oggi)
            let calo = punti(o.coperturaOggi - dopo)
            if let x = scelto {
                if abs(calo - x.calo) > 1e-9 {
                    if calo < x.calo { continue }
                } else if o.obiettivo.priorita != x.base.obiettivo.priorita {
                    if o.obiettivo.priorita < x.base.obiettivo.priorita { continue }
                } else if o.obiettivo.scadenza >= x.base.obiettivo.scadenza {
                    continue
                }
            }
            scelto = (o, dopo, calo)
        }
        return RigaProvaFuoco(clienteId: c.cliente.id, nome: c.cliente.nome, telefono: c.cliente.telefono,
                              obiettivoId: scelto?.base.obiettivo.id, titoloObiettivo: scelto?.base.obiettivo.titolo,
                              coperturaOggi: scelto?.base.coperturaOggi ?? 0, coperturaDopo: scelto?.dopo ?? 0,
                              perdita: perditaTotale, voci: voci, collegateAssenti: scelto.map { $0.base.collegate.isEmpty } ?? false)
    }
}

/// «L'ultimo vince»: ogni ricalcolo prende un numero; solo il risultato con l'ultimo numero si pubblica.
struct SequenzaRicalcoli: Equatable, Sendable {
    private(set) var ultimo = 0

    mutating func nuovo() -> Int {
        ultimo += 1
        return ultimo
    }

    func valido(_ numero: Int) -> Bool { numero == ultimo }
}

extension MotoreObiettivo {
    /// L'importo dell'obiettivo alla scadenza: in euro di oggi rivalutato all'inflazione di Prisma
    /// (`IpotesiCalcolo.inflazione`); con un'inflazione iniziale diversa (la prova del fuoco), al suo tasso per i primi
    /// anni e poi a quella di sempre: `importo × (1+e)^min(n, anni) × (1+i)^max(0, anni−n)`.
    static func importoAScadenza(_ importo: Double, anni: Double, inflazioneIniziale: (tasso: Double, anni: Int)? = nil) -> Double {
        let i = IpotesiCalcolo.inflazione
        guard let e = inflazioneIniziale, e.anni > 0 else { return importo * pow(1 + i / 100, anni) }
        let primi = min(Double(e.anni), anni)
        return importo * pow(1 + e.tasso / 100, primi) * pow(1 + i / 100, max(0, anni - Double(e.anni)))
    }

    /// La copertura dell'obiettivo alla scadenza (0…1), con gli stessi conti di `calcola(_:posizioni:data:)` ma senza
    /// strade, rinvii e scenari: leggera, per la prova del fuoco su tutti i clienti. Senza inflazione iniziale è
    /// uguale a `calcola(…).copertura`.
    static func coperturaAScadenza(_ o: Obiettivo, posizioni: [Posizione], inflazioneIniziale: (tasso: Double, anni: Int)? = nil,
                                   data: Date = Date()) -> Double {
        let mesi = max(0, Calendar.current.dateComponents([.month], from: data, to: o.scadenza).month ?? 0)
        let anni = Double(mesi) / 12
        let importo = importoAScadenza(o.importo, anni: anni, inflazioneIniziale: inflazioneIniziale)
        let collegate = posizioni.filter { o.posizioniCollegate.contains($0.id) && $0.stato == .inEssere }
        let contributi = collegate.reduce(0) {
            $0 + contributoPosizione($1, obiettivo: o, scarto: 0, mesiProiezione: mesi, data: data).nettoScadenza
        }
        let proiezione = contributi + o.accantonato * pow(1 + o.rendimento / 100, anni) + versamentoPrevisto(o, mesi: mesi)
        return importo > 0 ? min(1, proiezione / importo) : 1
    }
}
