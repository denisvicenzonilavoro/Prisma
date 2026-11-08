import Foundation
import CoreGraphics

// MARK: - Territorio («Luce» giro 11, §5.1 «Il tuo territorio»)
//
// Motore puro, senza SwiftUI: riceve `oggi` e gli elenchi già calcolati. Tutto locale (decisioni 20, 21, 22):
// le posizioni vengono dalla tabella dei comuni inclusa in Prisma o dalla posizione messa a mano, le distanze sono
// stime in linea d'aria × fattore strada, i tempi da velocità medie scritte in Impostazioni › Territorio. Niente CAP,
// niente servizi di mappe o percorsi, nessuna richiesta di rete.

/// Da dove viene la posizione di un cliente (niente CAP: decisione dell'utente).
enum PrecisioneLuogo: String, Equatable {
    case manuale, comune
}

/// La posizione di un cliente sulla mappa.
struct LuogoCliente: Equatable {
    let clienteId: String
    let coordinata: Coordinata
    let precisione: PrecisioneLuogo
    /// nil solo per la posizione a mano di un cliente il cui indirizzo non ha un comune riconosciuto.
    let comune: ComuneTabella?
    /// Il nome della zona: la zona dell'utente che contiene il comune, altrimenti il nome del comune.
    let zona: String
}

/// Perché un cliente non è sulla mappa.
enum MotivoSenzaLuogo: Equatable {
    case indirizzoVuoto
    case comuneNonRiconosciuto(String)
    /// Il nome scritto e le sigle delle province dei comuni omonimi.
    case comuneAmbiguo(String, [String])
    case estero
    case tabellaMancante

    var testo: String {
        switch self {
        case .indirizzoVuoto: return "indirizzo vuoto"
        case .comuneNonRiconosciuto(let n): return n.isEmpty ? "comune non riconosciuto" : "comune non riconosciuto: «\(n)»"
        case .comuneAmbiguo(_, let sigle): return "comune con più province (\(sigle.joined(separator: ", "))): aggiungi la sigla"
        case .estero: return "sede fuori dall'Italia"
        case .tabellaMancante: return "la tabella dei comuni non si legge"
        }
    }
}

struct ClienteSenzaLuogo: Identifiable, Equatable {
    let cliente: Cliente
    let motivo: MotivoSenzaLuogo
    var id: String { cliente.id }
}

/// Il colore della luce: il canale delle posizioni in essere del cliente (decisione 118).
enum CanaleLuce: Equatable {
    case alleanza, indipendente, entrambi

    var nome: String {
        switch self {
        case .alleanza: return "Alleanza"
        case .indipendente: return "Indipendente"
        case .entrambi: return "Entrambi i canali"
        }
    }
}

/// La cosa più urgente da fare per un cliente (niente tuple: deve stare in tipi Equatable).
struct DaFareCliente: Equatable {
    let perche: String
    let tipo: VoceDaFare.Tipo
    let gruppo: VoceDaFare.Gruppo
}

/// Un cliente sulla mappa.
struct LuceCliente: Identifiable, Equatable {
    let cliente: Cliente
    let luogo: LuogoCliente
    /// Somma di `Posizione.valore` delle posizioni in essere, esclusi i debiti (§5.1.8 n. 5).
    let patrimonio: Double
    let canale: CanaleLuce
    let daFare: DaFareCliente?
    let annoInizio: Int
    /// L'anno viene solo dalla data della scheda (`creatoIl`).
    let annoStimato: Bool
    var id: String { cliente.id }
}

struct ZonaPatrimonio: Equatable {
    let nome: String
    let patrimonio: Double
    let clienti: Int
}

/// La vista «Oggi».
struct TerritorioOggi: Equatable {
    let luci: [LuceCliente]
    let totale: Double
    let senzaLuogo: [ClienteSenzaLuogo]
    /// nil se nessuna zona ha almeno 2 clienti (mai una zona con un solo cliente).
    let zonaPiuRicca: ZonaPatrimonio?
    /// Decisione 71: la zona con un solo cliente (la più vicina alla zona più ricca); nil se nessuna.
    let zonaUnCliente: ZonaPatrimonio?
    let conQualcosaDaFare: Int

    static let vuoto = TerritorioOggi(luci: [], totale: 0, senzaLuogo: [], zonaPiuRicca: nil, zonaUnCliente: nil, conQualcosaDaFare: 0)
}

struct AnnoCrescita: Equatable {
    let anno: Int
    let clienti: Int
    /// nil = patrimonio di quell'anno non disponibile (manca lo storico): mai un fattore inventato.
    let patrimonio: Double?
    /// I clienti che cominciano quell'anno.
    let nuovi: [String]
}

/// La vista «La crescita».
struct CrescitaTerritorio: Equatable {
    let anni: [AnnoCrescita]
    /// Quanti clienti hanno l'anno della scheda in Prisma, non quello d'inizio.
    let stimati: Int

    static let vuota = CrescitaTerritorio(anni: [], stimati: 0)
}

struct TappaGiro: Identifiable, Equatable {
    enum Genere: Equatable { case partenza, visita, rientro }
    let genere: Genere
    let appuntamento: Appuntamento?
    let cliente: Cliente?
    let coordinata: Coordinata
    let kmDaPrima: Double
    let minutiDaPrima: Int
    var id: String { appuntamento?.id ?? (genere == .partenza ? "partenza" : "rientro") }
}

/// «Lungo la strada»: un cliente con qualcosa da fare vicino al giro, nello spazio libero fra due visite.
struct SuggerimentoGiro: Identifiable, Equatable {
    let cliente: Cliente
    let coordinata: Coordinata
    let motivo: String
    let deviazioneMinuti: Int
    /// Per «Scrivi a …» (solo `.conformita`).
    let tipoVoce: VoceDaFare.Tipo
    let gruppo: VoceDaFare.Gruppo
    /// Indici in `GiroGiorno.tappe` della visita prima e della visita dopo.
    let dopoTappa: Int
    let primaDiTappa: Int
    /// L'ora proposta (arrotondata ai 5 minuti in su).
    let ora: Date
    var id: String { cliente.id }
}

/// La vista «Il giro di domani».
struct GiroGiorno: Equatable {
    let giorno: Date
    /// nil = studio senza indirizzo: il giro parte dalla prima visita.
    let partenza: Coordinata?
    /// partenza? + visite + rientro?
    let tappe: [TappaGiro]
    /// Somma dei tratti, già × fattore strada.
    let km: Double
    /// Somma dei tratti.
    let minuti: Int
    /// Al più 3, il primo in evidenza.
    let suggerimenti: [SuggerimentoGiro]
    /// Visite «dal cliente» il cui cliente non ha un luogo.
    let senzaLuogo: [Appuntamento]
    /// Visite con il luogo non indicato (`presso == nil`).
    let luogoDaIndicare: [Appuntamento]
    /// Visite «altrove»: fuori dal giro.
    let altrove: Int
    /// Se il giorno non ha visite: il primo giorno dopo con visite fuori studio (entro 60 giorni).
    let prossimoGiorno: Date?

    var visite: Int { tappe.filter { $0.genere == .visita }.count }
    var vuoto: Bool { visite == 0 }
}

/// La partenza del giro e da dove viene (il pannello lo dice).
struct PartenzaGiro: Equatable {
    let coordinata: Coordinata
    let descrizione: String
}

enum MotoreTerritorio {
    // MARK: Luoghi

    /// Le posizioni dei clienti: la posizione a mano (`Cliente.luogo`), poi il comune della sede fiscale (se il comune è
    /// scritto), poi il comune dell'indirizzo. Un ciclo solo sui clienti (niente confronti a coppie).
    static func luoghi(clienti: [Cliente], tabella: TabellaComuni, zone: [ZonaTerritorio])
        -> (luoghi: [String: LuogoCliente], senzaLuogo: [ClienteSenzaLuogo]) {
        var zonaDi: [String: String] = [:]
        for z in zone where !z.nome.isEmpty {
            for codice in z.comuni where zonaDi[codice] == nil { zonaDi[codice] = z.nome }
        }
        func zona(_ c: ComuneTabella?) -> String {
            guard let c else { return "Posizione a mano" }
            return zonaDi[c.codice] ?? c.nome
        }
        var risultato: [String: LuogoCliente] = [:]
        var senza: [ClienteSenzaLuogo] = []
        var perComune: [String: [String]] = [:]
        var comuneDi: [String: ComuneTabella] = [:]
        for c in clienti {
            if let manuale = c.luogo, manuale.coordinata.valida {
                // La zona di una posizione a mano è il comune in cui cade il punto (non quello dell'indirizzo)
                let comune = comuneVicino(manuale.coordinata, tabella: tabella)
                risultato[c.id] = LuogoCliente(clienteId: c.id, coordinata: manuale.coordinata, precisione: .manuale,
                                               comune: comune, zona: zona(comune))
                continue
            }
            let esito = esitoComune(c, tabella: tabella)
            switch esito.esito {
            case .trovato(let t):
                perComune[t.codice, default: []].append(c.id)
                comuneDi[t.codice] = t
            case .ambiguo(let sigle):
                senza.append(ClienteSenzaLuogo(cliente: c, motivo: .comuneAmbiguo(esito.testo, sigle)))
            case .nonTrovato:
                senza.append(ClienteSenzaLuogo(cliente: c, motivo: .comuneNonRiconosciuto(esito.testo)))
            case .vuoto:
                senza.append(ClienteSenzaLuogo(cliente: c, motivo: .indirizzoVuoto))
            case .estero:
                senza.append(ClienteSenzaLuogo(cliente: c, motivo: .estero))
            }
        }
        for (codice, ids) in perComune {
            guard let comune = comuneDi[codice] else { continue }
            for (id, punto) in sparpaglia(ids, attorno: comune) {
                risultato[id] = LuogoCliente(clienteId: id, coordinata: punto, precisione: .comune, comune: comune, zona: zona(comune))
            }
        }
        senza.sort { $0.cliente.nome.localizedCompare($1.cliente.nome) == .orderedAscending }
        return (risultato, senza)
    }

    /// Il comune il cui centro è più vicino al punto, se il punto cade entro 1,5 volte il suo raggio (un ciclo sui comuni
    /// della tabella per ogni posizione a mano); nil se il punto è lontano da ogni comune noto.
    static func comuneVicino(_ p: Coordinata, tabella: TabellaComuni) -> ComuneTabella? {
        var migliore: (comune: ComuneTabella, km: Double)?
        for c in tabella.comuni {
            let km = distanzaKm(p, c.centro)
            guard km <= max(1, c.raggioKm * 1.5) else { continue }
            if migliore.map({ km < $0.km }) ?? true { migliore = (c, km) }
        }
        return migliore?.comune
    }

    /// L'esito del comune di un cliente e il testo da cui viene (per «comune non riconosciuto: …»).
    private struct EsitoCliente {
        let esito: EsitoComune
        let testo: String
    }

    private static func esitoComune(_ c: Cliente, tabella: TabellaComuni) -> EsitoCliente {
        let indirizzo = c.indirizzo.trimmingCharacters(in: .whitespacesAndNewlines)
        let dallIndirizzo = EsitoCliente(esito: TabellaTerritorio.comune(testo: indirizzo, tabella: tabella),
                                         testo: TabellaTerritorio.pezzoComune(indirizzo))
        if let sede = c.fiscale?.sede {
            if !TabellaTerritorio.italiana(sede.nazione) { return EsitoCliente(esito: .estero, testo: sede.nazione) }
            // Una sede con il solo indirizzo e senza comune non nasconde `Cliente.indirizzo`
            if !sede.comune.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let e = TabellaTerritorio.comune(sede: sede, tabella: tabella)
                if case .trovato = e { return EsitoCliente(esito: e, testo: sede.comune) }
                // La sede non si riconosce: se l'indirizzo sì, vale l'indirizzo; altrimenti il motivo è della sede
                if case .trovato = dallIndirizzo.esito { return dallIndirizzo }
                return EsitoCliente(esito: e, testo: sede.comune)
            }
        }
        return dallIndirizzo
    }

    /// Sparpaglio deterministico dei clienti di un comune: ordinati per id; uno solo → il centroide; altrimenti una
    /// spirale con l'angolo aureo (2,399963 rad), raggio 0,35 · raggioKm · √((k + 0,5) / n), km → gradi con 111,32 km/°
    /// e cos(lat).
    static func sparpaglia(_ ids: [String], attorno c: ComuneTabella) -> [String: Coordinata] {
        let ordinati = ids.sorted()
        guard ordinati.count > 1 else { return ordinati.first.map { [$0: c.centro] } ?? [:] }
        let n = Double(ordinati.count)
        let coseno = max(0.01, cos(c.centro.lat * .pi / 180))
        var r: [String: Coordinata] = [:]
        for (k, id) in ordinati.enumerated() {
            let raggio = 0.35 * c.raggioKm * ((Double(k) + 0.5) / n).squareRoot()
            let angolo = Double(k) * angoloAureo
            r[id] = Coordinata(lat: c.centro.lat + raggio * sin(angolo) / kmPerGrado,
                               lon: c.centro.lon + raggio * cos(angolo) / (kmPerGrado * coseno))
        }
        return r
    }

    static let angoloAureo = 2.399963
    static let kmPerGrado = 111.32

    // MARK: Distanze (stima dichiarata, decisione 22)

    static let raggioTerraKm = 6371.0088

    /// La distanza in linea d'aria (formula dell'emisenoverso).
    static func distanzaKm(_ a: Coordinata, _ b: Coordinata) -> Double {
        let r = Double.pi / 180
        let dLat = (b.lat - a.lat) * r
        let dLon = (b.lon - a.lon) * r
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(a.lat * r) * cos(b.lat * r) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * raggioTerraKm * asin(min(1, h.squareRoot()))
    }

    /// Un tratto: km = linea d'aria × fattore strada; minuti = km / velocità × 60, mai meno del minimo.
    static func tratto(_ a: Coordinata, _ b: Coordinata, stessoComune: Bool, impostazioni: ImpostazioniTerritorio)
        -> (km: Double, minuti: Int) {
        let km = distanzaKm(a, b) * impostazioni.fattoreStrada
        let velocita = max(1, stessoComune ? impostazioni.velocitaCitta : impostazioni.velocitaFuori)
        let minuti = Int((km / velocita * 60).rounded())
        return (km, max(impostazioni.minutiMinimiTratto, minuti))
    }

    // MARK: Aiuti

    /// Somma di `valore` delle posizioni in essere, esclusi i debiti.
    static func patrimonio(_ posizioni: [Posizione]) -> Double {
        posizioni.reduce(0) { $1.stato == .inEssere && $1.area != .debiti ? $0 + $1.valore : $0 }
    }

    /// Il canale della luce: dalle posizioni in essere; senza posizioni, dai canali della scheda.
    static func canale(_ cliente: Cliente, _ posizioni: [Posizione]) -> CanaleLuce {
        let canali = Set(posizioni.filter { $0.stato == .inEssere }.map(\.canale))
        let scelti = canali.isEmpty ? Set(cliente.canali) : canali
        if scelti == [.alleanza] { return .alleanza }
        if scelti == [.indipendente] { return .indipendente }
        return .entrambi
    }

    /// L'anno d'inizio: il più vecchio fra le decorrenze delle posizioni in essere o chiuse, il primo appuntamento
    /// concluso e `clienteDal`; se nessuno, l'anno della scheda (`creatoIl`), segnato «stimato».
    static func annoInizio(_ cliente: Cliente, posizioni: [Posizione], appuntamenti: [Appuntamento],
                           calendario: Calendar) -> (anno: Int, stimato: Bool) {
        var date: [Date] = posizioni.filter { $0.stato != .proposta }.compactMap(\.decorrenza)
        if let primo = appuntamenti.filter({ $0.clienteId == cliente.id && $0.stato == .concluso }).map(\.inizio).min() {
            date.append(primo)
        }
        if let dal = cliente.clienteDal { date.append(dal) }
        if let minimo = date.min() { return (calendario.component(.year, from: minimo), false) }
        return (calendario.component(.year, from: cliente.creatoIl), true)
    }

    /// La partenza del giro, in quest'ordine: a mano, comune scelto, sede dello studio (con il comune scritto), testo
    /// della partenza di Studio › Spese; nil se nessuna.
    static func partenzaGiro(impostazioni: Impostazioni, tabella: TabellaComuni) -> PartenzaGiro? {
        let t = impostazioni.territorio
        if let p = t.partenza, p.coordinata.valida {
            return PartenzaGiro(coordinata: p.coordinata, descrizione: "partenza: posizione a mano")
        }
        if let codice = t.comunePartenza, let c = tabella.perCodice[codice] {
            return PartenzaGiro(coordinata: c.centro, descrizione: "partenza: dal comune di \(c.nome)")
        }
        let sede = impostazioni.studio.fatturazione.sede
        if !sede.comune.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           case .trovato(let c) = TabellaTerritorio.comune(sede: sede, tabella: tabella) {
            return PartenzaGiro(coordinata: c.centro, descrizione: "partenza: lo studio, dal comune di \(c.nome)")
        }
        let testo = impostazioni.studio.spese.partenza
        if !testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           case .trovato(let c) = TabellaTerritorio.comune(testo: testo, tabella: tabella) {
            return PartenzaGiro(coordinata: c.centro, descrizione: "partenza: \(testo), dal comune di \(c.nome)")
        }
        return nil
    }

    static func partenza(impostazioni: Impostazioni, tabella: TabellaComuni) -> Coordinata? {
        partenzaGiro(impostazioni: impostazioni, tabella: tabella)?.coordinata
    }

    /// «Qualcosa da fare» (decisione 99): le voci entro il mese, tutte quelle di conformità e le attenzioni dei tipi
    /// scelti come «alte»; per cliente la voce più urgente (gruppo, poi l'ordine del nastro). Un'attenzione conta solo se
    /// la sua voce è ancora fra le voci (`"attenzione-" + a.id`): quelle segnate fatte non ci sono più.
    static func daFare(_ voci: [VoceDaFare], attenzioni: [Attenzione], attenzioniAlte: Set<Int>) -> [String: DaFareCliente] {
        let ammesse = Set(attenzioni.filter { attenzioniAlte.contains($0.tipo.rawValue) }.map { "attenzione-" + $0.id })
        var migliore: [String: VoceDaFare] = [:]
        for v in voci {
            let conta: Bool
            if v.tipo == .attenzione {
                conta = ammesse.contains(v.id)
            } else {
                conta = v.gruppo != .avanti || v.tipo == .conformita
            }
            guard conta else { continue }
            if let m = migliore[v.cliente.id] {
                if v.gruppo < m.gruppo || (v.gruppo == m.gruppo && MotoreDaFare.precede(v, m)) { migliore[v.cliente.id] = v }
            } else {
                migliore[v.cliente.id] = v
            }
        }
        return migliore.mapValues { DaFareCliente(perche: $0.perche, tipo: $0.tipo, gruppo: $0.gruppo) }
    }

    /// Il primo giorno lavorativo da `giorno` in poi (`orari.giorni` usa 1 = domenica … 7 = sabato, come Calendar).
    static func giornoLavorativo(da giorno: Date, orari: OrariLavoro, calendario: Calendar) -> Date {
        let inizio = calendario.startOfDay(for: giorno)
        for k in 0..<14 {
            guard let d = calendario.date(byAdding: .day, value: k, to: inizio) else { continue }
            if orari.giorni.contains(calendario.component(.weekday, from: d)) { return d }
        }
        return inizio
    }

    /// Il nome di battesimo (primo pezzo del nome): Prisma non conosce il genere dei clienti.
    static func nomeBattesimo(_ c: Cliente) -> String {
        c.nome.split(separator: " ").first.map(String.init) ?? c.nome
    }

    // MARK: Oggi

    static func oggi(clienti: [Cliente], posizioni: [Posizione], appuntamenti: [Appuntamento],
                     luoghi: [String: LuogoCliente], senzaLuogo: [ClienteSenzaLuogo], daFare: [String: DaFareCliente],
                     oggi: Date, calendario: Calendar = .current) -> TerritorioOggi {
        let posPer = Dictionary(grouping: posizioni, by: \.clienteId)
        let appPer = Dictionary(grouping: appuntamenti, by: \.clienteId)
        var luci: [LuceCliente] = []
        for c in clienti {
            guard let l = luoghi[c.id] else { continue }
            let suoi = posPer[c.id] ?? []
            let inizio = annoInizio(c, posizioni: suoi, appuntamenti: appPer[c.id] ?? [], calendario: calendario)
            luci.append(LuceCliente(cliente: c, luogo: l, patrimonio: patrimonio(suoi), canale: canale(c, suoi),
                                    daFare: daFare[c.id], annoInizio: inizio.anno, annoStimato: inizio.stimato))
        }
        // Le grandi prima: le piccole si disegnano sopra
        luci.sort { $0.patrimonio != $1.patrimonio ? $0.patrimonio > $1.patrimonio : $0.id < $1.id }
        let totale = luci.reduce(0) { $0 + $1.patrimonio }
        // Le zone: patrimonio, clienti e centro medio
        var somma: [String: (patrimonio: Double, clienti: Int, lat: Double, lon: Double)] = [:]
        for l in luci {
            let v = somma[l.luogo.zona] ?? (0, 0, 0, 0)
            somma[l.luogo.zona] = (v.patrimonio + l.patrimonio, v.clienti + 1, v.lat + l.luogo.coordinata.lat, v.lon + l.luogo.coordinata.lon)
        }
        func centro(_ nome: String) -> Coordinata? {
            guard let v = somma[nome], v.clienti > 0 else { return nil }
            return Coordinata(lat: v.lat / Double(v.clienti), lon: v.lon / Double(v.clienti))
        }
        let ricche = somma.filter { $0.value.clienti >= 2 }
            .sorted { $0.value.patrimonio != $1.value.patrimonio ? $0.value.patrimonio > $1.value.patrimonio : $0.key < $1.key }
        let piuRicca = ricche.first.map { ZonaPatrimonio(nome: $0.key, patrimonio: $0.value.patrimonio, clienti: $0.value.clienti) }
        let riferimento: Coordinata? = piuRicca.flatMap { centro($0.nome) }
            ?? (luci.isEmpty ? nil : Coordinata(lat: luci.reduce(0) { $0 + $1.luogo.coordinata.lat } / Double(luci.count),
                                                lon: luci.reduce(0) { $0 + $1.luogo.coordinata.lon } / Double(luci.count)))
        let sole = somma.filter { $0.value.clienti == 1 }.map(\.key).sorted()
        var unCliente: ZonaPatrimonio?
        if let rif = riferimento {
            let vicina = sole.min { a, b in
                let da = centro(a).map { distanzaKm($0, rif) } ?? .infinity
                let db = centro(b).map { distanzaKm($0, rif) } ?? .infinity
                return da != db ? da < db : a < b
            }
            unCliente = vicina.flatMap { n in somma[n].map { ZonaPatrimonio(nome: n, patrimonio: $0.patrimonio, clienti: 1) } }
        }
        return TerritorioOggi(luci: luci, totale: totale, senzaLuogo: senzaLuogo, zonaPiuRicca: piuRicca,
                              zonaUnCliente: unCliente, conQualcosaDaFare: luci.filter { $0.daFare != nil }.count)
    }

    // MARK: La crescita

    static let anniMassimiCrescita = 40

    /// Gli anni dal primo anno d'inizio delle luci all'anno di `oggi` (al più 40). Il patrimonio degli anni passati viene
    /// dallo storico (`MotoreAndamentoPortafoglio.valore(_:al:)`) al 31 dicembre; dove manca lo storico è nil. L'anno in
    /// corso: il patrimonio di oggi delle luci.
    static func crescita(luci: [LuceCliente], posizioni: [Posizione], oggi: Date,
                         calendario: Calendar = .current) -> CrescitaTerritorio {
        guard let primoInizio = luci.map(\.annoInizio).min() else { return .vuota }
        let ultimo = calendario.component(.year, from: oggi)
        let primo = min(ultimo, max(primoInizio, ultimo - anniMassimiCrescita + 1))
        let posPer = Dictionary(grouping: posizioni.filter { $0.area != .debiti && $0.stato != .proposta }, by: \.clienteId)
        var anni: [AnnoCrescita] = []
        for anno in primo...ultimo {
            let presenti = luci.filter { $0.annoInizio <= anno }
            let nuovi = luci.filter { anno == primo ? $0.annoInizio <= anno : $0.annoInizio == anno }.map(\.id).sorted()
            var patrimonio: Double? = 0
            if anno == ultimo {
                patrimonio = presenti.reduce(0) { $0 + $1.patrimonio }
            } else if let fine = calendario.date(from: DateComponents(year: anno, month: 12, day: 31, hour: 23, minute: 59)) {
                for l in presenti {
                    guard let p = patrimonio else { break }
                    guard let v = valoreAllaData(posPer[l.id] ?? [], al: fine) else { patrimonio = nil; break }
                    patrimonio = p + v
                }
            } else {
                patrimonio = nil
            }
            anni.append(AnnoCrescita(anno: anno, clienti: presenti.count, patrimonio: patrimonio, nuovi: nuovi))
        }
        return CrescitaTerritorio(anni: anni, stimati: luci.filter(\.annoStimato).count)
    }

    /// Lo storico è noto se c'è la decorrenza o almeno una rilevazione.
    static func storicoNoto(_ p: Posizione) -> Bool { p.decorrenza != nil || !(p.rilevazioni ?? []).isEmpty }

    /// Il valore delle posizioni di un cliente a una data passata (debiti e proposte già esclusi); nil se non si sa.
    /// In essere: con decorrenza (o rilevazioni) fino alla data; senza storico → nil (non si sa quando è cominciata).
    /// Chiuse: con la scadenza dopo la data contano; senza scadenza, con decorrenza fino alla data → nil (Posizione
    /// non ha una data di chiusura: mai indovinare).
    static func valoreAllaData(_ posizioni: [Posizione], al data: Date) -> Double? {
        var totale = 0.0
        for p in posizioni {
            switch p.stato {
            case .proposta:
                continue
            case .inEssere:
                guard storicoNoto(p) else { return nil }
                let cominciata: Bool
                if let d = p.decorrenza {
                    cominciata = d <= data
                } else {
                    cominciata = (p.rilevazioni ?? []).contains { $0.data <= data }
                }
                if cominciata { totale += MotoreAndamentoPortafoglio.valore(p, al: data) }
            case .chiusa:
                guard let d = p.decorrenza else {
                    // Chiusa senza decorrenza: se ha rilevazioni fino alla data e nessuna scadenza, non si sa
                    if (p.rilevazioni ?? []).contains(where: { $0.data <= data }) {
                        guard let s = p.scadenza else { return nil }
                        if s > data { totale += MotoreAndamentoPortafoglio.valore(p, al: data) }
                    }
                    continue
                }
                guard d <= data else { continue }
                guard let s = p.scadenza else { return nil }
                if s > data { totale += MotoreAndamentoPortafoglio.valore(p, al: data) }
            }
        }
        return totale
    }

    // MARK: Il giro

    /// Una visita del giro: pianificata o conclusa, non telefonata né blocco, con un cliente.
    static func visitaCandidata(_ a: Appuntamento) -> Bool {
        a.tipo != .telefonata && a.tipo != .nonDisponibile && !a.clienteId.isEmpty
    }

    static let giorniProssimoGiro = 60
    static let suggerimentiMassimi = 3

    static func giro(giorno: Date, appuntamenti: [Appuntamento], clienti: [Cliente], luoghi: [String: LuogoCliente],
                     partenza: Coordinata?, daFare: [String: DaFareCliente], impostazioni: ImpostazioniTerritorio,
                     orari: OrariLavoro, calendario: Calendar = .current) -> GiroGiorno {
        let inizio = calendario.startOfDay(for: giorno)
        let fine = calendario.date(byAdding: .day, value: 1, to: inizio) ?? inizio.addingTimeInterval(86_400)
        let delGiorno = appuntamenti.filter { $0.inizio >= inizio && $0.inizio < fine }.sorted { $0.inizio < $1.inizio }
        let perId = Dictionary(clienti.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var visite: [(appuntamento: Appuntamento, luogo: LuogoCliente)] = []
        var senzaLuogo: [Appuntamento] = []
        var daIndicare: [Appuntamento] = []
        var altrove = 0
        for a in delGiorno where visitaCandidata(a) {
            switch a.presso {
            case .cliente?:
                if let l = luoghi[a.clienteId] { visite.append((a, l)) } else { senzaLuogo.append(a) }
            case nil:
                daIndicare.append(a)
            case .altro?:
                altrove += 1
            case .studio?:
                continue
            }
        }
        // Le tappe e i tratti
        func stesso(_ a: LuogoCliente?, _ b: LuogoCliente?, _ pa: Coordinata, _ pb: Coordinata) -> Bool {
            if let ca = a?.comune?.codice, let cb = b?.comune?.codice { return ca == cb }
            // La partenza non ha un comune: è «in città» se cade dentro il raggio del comune dell'altra tappa
            if let c = (a ?? b)?.comune { return distanzaKm(pa, pb) <= max(1, c.raggioKm) }
            return false
        }
        var tappe: [TappaGiro] = []
        var km = 0.0
        var minuti = 0
        var precedente: (coordinata: Coordinata, luogo: LuogoCliente?)?
        if let p = partenza {
            tappe.append(TappaGiro(genere: .partenza, appuntamento: nil, cliente: nil, coordinata: p, kmDaPrima: 0, minutiDaPrima: 0))
            precedente = (p, nil)
        }
        for v in visite {
            var t = (km: 0.0, minuti: 0)
            if let prima = precedente {
                t = tratto(prima.coordinata, v.luogo.coordinata, stessoComune: stesso(prima.luogo, v.luogo, prima.coordinata, v.luogo.coordinata),
                           impostazioni: impostazioni)
            }
            tappe.append(TappaGiro(genere: .visita, appuntamento: v.appuntamento, cliente: perId[v.appuntamento.clienteId],
                                   coordinata: v.luogo.coordinata, kmDaPrima: t.km, minutiDaPrima: t.minuti))
            km += t.km
            minuti += t.minuti
            precedente = (v.luogo.coordinata, v.luogo)
        }
        if let p = partenza, let prima = precedente, !visite.isEmpty {
            let t = tratto(prima.coordinata, p, stessoComune: stesso(prima.luogo, nil, prima.coordinata, p), impostazioni: impostazioni)
            tappe.append(TappaGiro(genere: .rientro, appuntamento: nil, cliente: nil, coordinata: p, kmDaPrima: t.km, minutiDaPrima: t.minuti))
            km += t.km
            minuti += t.minuti
        }
        if visite.isEmpty { tappe = [] }
        // «Lungo la strada»
        var suggerimenti: [SuggerimentoGiro] = []
        let lavorativo = orari.giorni.contains(calendario.component(.weekday, from: inizio))
        if lavorativo, visite.count >= 2 {
            let nelGiro = Set(visite.map(\.appuntamento.clienteId))
            let indiceVisita: [String: Int] = Dictionary(tappe.enumerated().compactMap { i, t in t.appuntamento.map { ($0.id, i) } },
                                                         uniquingKeysWith: { a, _ in a })
            for c in clienti {
                guard let cosa = daFare[c.id], !nelGiro.contains(c.id), let lc = luoghi[c.id] else { continue }
                var migliore: SuggerimentoGiro?
                for k in 0..<(visite.count - 1) {
                    let a = visite[k], b = visite[k + 1]
                    let ac = tratto(a.luogo.coordinata, lc.coordinata, stessoComune: stesso(a.luogo, lc, a.luogo.coordinata, lc.coordinata),
                                    impostazioni: impostazioni)
                    let cb = tratto(lc.coordinata, b.luogo.coordinata, stessoComune: stesso(lc, b.luogo, lc.coordinata, b.luogo.coordinata),
                                    impostazioni: impostazioni)
                    let ab = tratto(a.luogo.coordinata, b.luogo.coordinata,
                                    stessoComune: stesso(a.luogo, b.luogo, a.luogo.coordinata, b.luogo.coordinata), impostazioni: impostazioni)
                    let deviazione = ac.minuti + cb.minuti - ab.minuti
                    guard deviazione <= impostazioni.deviazioneMassima else { continue }
                    let ora = arrotondaCinqueMinuti(a.appuntamento.fine.addingTimeInterval(TimeInterval(ac.minuti * 60)))
                    let fineVisita = ora.addingTimeInterval(TimeInterval(impostazioni.durataVisitaBreve * 60))
                    let ritorno = fineVisita.addingTimeInterval(TimeInterval(cb.minuti * 60))
                    guard ritorno <= b.appuntamento.inizio else { continue }
                    // Nessun altro appuntamento (anche i blocchi «non disponibile») nello spazio della deviazione
                    let finestra = (a.appuntamento.fine, ritorno)
                    let occupato = delGiorno.contains { x in
                        x.id != a.appuntamento.id && x.id != b.appuntamento.id && x.inizio < finestra.1 && x.fine > finestra.0
                    }
                    guard !occupato, dentroOrari(ora, fineVisita, orari: orari, calendario: calendario) else { continue }
                    guard let ia = indiceVisita[a.appuntamento.id], let ib = indiceVisita[b.appuntamento.id] else { continue }
                    let s = SuggerimentoGiro(cliente: c, coordinata: lc.coordinata, motivo: cosa.perche, deviazioneMinuti: max(0, deviazione),
                                             tipoVoce: cosa.tipo, gruppo: cosa.gruppo, dopoTappa: ia, primaDiTappa: ib, ora: ora)
                    if migliore.map({ s.deviazioneMinuti < $0.deviazioneMinuti }) ?? true { migliore = s }
                }
                if let m = migliore { suggerimenti.append(m) }
            }
            suggerimenti.sort { a, b in
                if a.deviazioneMinuti != b.deviazioneMinuti { return a.deviazioneMinuti < b.deviazioneMinuti }
                if a.gruppo != b.gruppo { return a.gruppo < b.gruppo }
                return a.cliente.nome.localizedCompare(b.cliente.nome) == .orderedAscending
            }
            suggerimenti = Array(suggerimenti.prefix(suggerimentiMassimi))
        }
        // Il prossimo giro, se il giorno non ha visite
        var prossimo: Date?
        if visite.isEmpty {
            let fuori = appuntamenti.filter { visitaCandidata($0) && $0.presso == .cliente && $0.inizio >= fine }
            if let primo = fuori.map(\.inizio).min(),
               let limite = calendario.date(byAdding: .day, value: giorniProssimoGiro, to: inizio), primo < limite {
                prossimo = calendario.startOfDay(for: primo)
            }
        }
        return GiroGiorno(giorno: inizio, partenza: partenza, tappe: tappe, km: km, minuti: minuti, suggerimenti: suggerimenti,
                          senzaLuogo: senzaLuogo, luogoDaIndicare: daIndicare, altrove: altrove, prossimoGiorno: prossimo)
    }

    /// Arrotonda ai 5 minuti in su.
    static func arrotondaCinqueMinuti(_ d: Date) -> Date {
        let passo = 300.0
        return Date(timeIntervalSinceReferenceDate: (d.timeIntervalSinceReferenceDate / passo).rounded(.up) * passo)
    }

    /// Vero se la visita (dall'ora alla fine) sta tutta in una fascia degli orari di lavoro.
    static func dentroOrari(_ da: Date, _ a: Date, orari: OrariLavoro, calendario: Calendar) -> Bool {
        guard calendario.isDate(da, inSameDayAs: a) else { return false }
        let m1 = calendario.component(.hour, from: da) * 60 + calendario.component(.minute, from: da)
        let m2 = calendario.component(.hour, from: a) * 60 + calendario.component(.minute, from: a)
        return orari.fasce.contains { m1 >= $0.inizio && m2 <= $0.fine }
    }
}

// MARK: - La proiezione della mappa

/// La proiezione della mappa (equirettangolare locale, §5.4): adatta ai punti con un margine, con zoom e spostamento.
struct ProiezioneMappa: Equatable {
    var minLat: Double
    var maxLat: Double
    var minLon: Double
    var maxLon: Double
    var zoom: CGFloat = 1
    var spostamento: CGSize = .zero

    /// Mezza ampiezza minima, in gradi, attorno a un solo punto (o a punti vicinissimi).
    static let ampiezzaMinima = 0.05

    /// nil senza punti; un solo punto → ±0,05°.
    static func adatta(_ punti: [Coordinata]) -> ProiezioneMappa? {
        let validi = punti.filter(\.valida)
        guard let primo = validi.first else { return nil }
        var p = ProiezioneMappa(minLat: primo.lat, maxLat: primo.lat, minLon: primo.lon, maxLon: primo.lon)
        for c in validi.dropFirst() {
            p.minLat = min(p.minLat, c.lat)
            p.maxLat = max(p.maxLat, c.lat)
            p.minLon = min(p.minLon, c.lon)
            p.maxLon = max(p.maxLon, c.lon)
        }
        if p.maxLat - p.minLat < 2 * ampiezzaMinima {
            let m = (p.maxLat + p.minLat) / 2
            p.minLat = m - ampiezzaMinima
            p.maxLat = m + ampiezzaMinima
        }
        if p.maxLon - p.minLon < 2 * ampiezzaMinima {
            let m = (p.maxLon + p.minLon) / 2
            p.minLon = m - ampiezzaMinima
            p.maxLon = m + ampiezzaMinima
        }
        return p
    }

    private var latMedia: Double { (minLat + maxLat) / 2 }
    private var lonMedia: Double { (minLon + maxLon) / 2 }
    private var coseno: Double { max(0.01, cos(latMedia * .pi / 180)) }

    /// Punti per grado (di latitudine) con questa misura e questo margine.
    private func scala(_ misura: CGSize, _ margine: CGFloat) -> Double {
        let larghezza = max(1, Double(misura.width - 2 * margine))
        let altezza = max(1, Double(misura.height - 2 * margine))
        let gradiX = max(1e-6, (maxLon - minLon) * coseno)
        let gradiY = max(1e-6, maxLat - minLat)
        return min(larghezza / gradiX, altezza / gradiY) * Double(max(0.01, zoom))
    }

    func punto(_ c: Coordinata, in misura: CGSize, margine: CGFloat) -> CGPoint {
        let s = scala(misura, margine)
        let x = Double(misura.width) / 2 + (c.lon - lonMedia) * coseno * s + Double(spostamento.width)
        let y = Double(misura.height) / 2 - (c.lat - latMedia) * s + Double(spostamento.height)
        return CGPoint(x: x, y: y)
    }

    /// L'inverso di `punto` (per «Sposta»: il clic sulla mappa diventa una coordinata).
    func coordinata(_ p: CGPoint, in misura: CGSize, margine: CGFloat) -> Coordinata {
        let s = scala(misura, margine)
        let lon = lonMedia + (Double(p.x) - Double(misura.width) / 2 - Double(spostamento.width)) / (coseno * s)
        let lat = latMedia - (Double(p.y) - Double(misura.height) / 2 - Double(spostamento.height)) / s
        return Coordinata(lat: lat, lon: lon)
    }
}
