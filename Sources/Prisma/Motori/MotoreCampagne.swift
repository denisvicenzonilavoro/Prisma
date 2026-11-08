import CoreGraphics
import Foundation

// Le campagne di Messaggi › Campagne («Luce» giro 12, Design/template-luce-specifica.md §9.4): i gruppi di clienti con lo
// stesso bisogno, presi solo dai bisogni che i motori di Prisma calcolano già (decisione 97: MotoreBisogni, scadenze delle
// posizioni, età, versamenti della previdenza), con le soglie in `RegoleCampagne` (da approvare dall'utente). Un cliente in
// più gruppi è un membro di ognuno, con «anche in: …». Ogni messaggio è per una persona sola, con le sole cifre di quella
// persona (decisione 15: bozze in Prisma, aperte dal consulente; niente invii). Senza consenso commerciale valido il
// cliente resta nel gruppo, fuori dall'invio di base (decisione 16).
// Motore puro: riceve i dati, `oggi` e il calendario; niente StatoShell.

/// Il tipo di un gruppo con lo stesso bisogno. `Codable` perché finisce nella `Campagna` salvata.
enum TipoGruppoCampagna: String, Codable, CaseIterable, Identifiable {
    /// Bisogno «protezione-famiglia» di `MotoreBisogni`, non scartato.
    case protezioneFamiglia
    /// Posizioni in essere con la scadenza nello stesso mese, entro sei mesi.
    case scadenzaNelMese
    /// Compiono 40, 50 o 60 anni l'anno prossimo.
    case etaTonda
    /// Posizioni di previdenza in essere senza versamenti da dodici mesi (movimenti assenti = non valutata).
    case previdenzaFerma
    /// Bisogno «previdenza-assente» di `MotoreBisogni`, non scartato.
    case previdenzaAssente
    /// Bisogno «liquidita-ferma» di `MotoreBisogni`, non scartato.
    case liquiditaFerma

    var id: String { rawValue }

    /// L'id del bisogno di `MotoreBisogni` da cui nasce (nil per scadenze, età e previdenza ferma): serve al
    /// collegamento «Scrivi a tutti quelli con lo stesso bisogno» dalla scheda Bisogni del dossier.
    var bisognoId: String? {
        switch self {
        case .protezioneFamiglia: return "protezione-famiglia"
        case .previdenzaAssente: return "previdenza-assente"
        case .liquiditaFerma: return "liquidita-ferma"
        case .scadenzaNelMese, .etaTonda, .previdenzaFerma: return nil
        }
    }
}

/// Le soglie delle campagne, tutte in un punto. DA APPROVARE dall'utente (decisione 97): la vista lo dice nel piede.
enum RegoleCampagne {
    static let minimoMembri = 2
    static let etaTonde = [40, 50, 60]
    static let mesiScadenza = 6
    static let mesiPrevidenzaFerma = 12
    /// Lo stesso bisogno non si ripropone per tanti giorni (come la copertura dei messaggi).
    static let giorniStessoBisogno = RegoleMessaggi.giorniCopertura
    /// Al più una campagna ogni tanti giorni per cliente.
    static let giorniFraCampagne = 30
    static let massimoGruppiInMappa = 6
    static let massimoPallini = 120
    /// Gli orari proposti: mezz'ora, nei prossimi 14 giorni lavorativi, al più quattro, uno per giorno (decisione 98).
    static let durataAppuntamento = 30
    static let giorniAppuntamenti = 14
    static let appuntamentiMassimi = 4
    /// «Apri tutte» chiede conferma oltre tante bozze.
    static let aperturaSenzaConferma = 5
}

/// Un cliente di un gruppo.
struct MembroCampagna: Identifiable, Hashable {
    var id: String { clienteId }
    let clienteId: String
    /// «"Piano Pensione" senza versamenti dal 3 ottobre 2025».
    let motivo: String
    /// Solo di questo cliente.
    let cifre: [CifraMessaggio]
    /// Consenso commerciale valido oggi (decisione 16).
    let consenso: Bool
    let recapitoMail: Bool
    let recapitoMessaggi: Bool
    /// Già scritto per lo stesso bisogno negli ultimi 90 giorni (il giorno più recente).
    let giaContattato: Date?
    /// Già in una campagna negli ultimi 30 giorni (il giorno più recente).
    let ultimaCampagna: Date?
    /// Il canale di lavoro del cliente quando è uno solo (`MotoreOccasioniMessaggi.canaleComune`); nil = canali misti.
    let canaleLavoro: Canale?
    /// Consenso, un recapito, non già contattato né in una campagna recente (il canale scelto lo decide la vista).
    var inclusoDiBase: Bool
    /// I titoli degli altri gruppi del cliente (decisione 97: un pallino per gruppo, con «anche in»).
    let anchein: [String]

    func recapito(_ canale: CanaleMessaggio) -> Bool { canale == .mail ? recapitoMail : recapitoMessaggi }
}

/// Un gruppo di clienti con lo stesso bisogno.
struct GruppoCampagna: Identifiable, Hashable {
    /// "protezioneFamiglia", "scadenzaNelMese-2027-03", "etaTonda-50-2027", …
    let id: String
    let tipo: TipoGruppoCampagna
    let titolo: String
    let membri: [MembroCampagna]
    /// I clienti che non si sono potuti valutare (fondi pensione senza movimenti registrati).
    let nonValutati: Int
    let notaNonValutati: String?
}

enum MotoreCampagne {
    private static let gregoriano = Calendar(identifier: .gregorian)

    // MARK: - Gruppi

    /// I gruppi con almeno `minimo` membri, dal più grande. Solo bisogni già calcolati dai motori.
    static func gruppi(dati: DatiPrisma, oggi: Date, cal: Calendar = .current,
                       minimo: Int = RegoleCampagne.minimoMembri) -> [GruppoCampagna] {
        let posizioni = Dictionary(grouping: dati.posizioni, by: \.clienteId)
        // Le voci grezze: (id del gruppo, tipo, titolo, cliente, motivo, cifre)
        var voci: [String: (tipo: TipoGruppoCampagna, titolo: String, membri: [(Cliente, String, [CifraMessaggio])])] = [:]
        var nonValutatiPrevidenza = 0
        func aggiungi(_ id: String, _ tipo: TipoGruppoCampagna, _ titolo: String, _ c: Cliente, _ motivo: String, _ cifre: [CifraMessaggio]) {
            if voci[id] == nil { voci[id] = (tipo, titolo, []) }
            guard voci[id]?.membri.contains(where: { $0.0.id == c.id }) == false else { return }
            voci[id]?.membri.append((c, motivo, cifre))
        }
        let inizio = cal.startOfDay(for: oggi)
        let limiteScadenza = cal.date(byAdding: .month, value: RegoleCampagne.mesiScadenza, to: inizio) ?? inizio
        let limiteVersamenti = cal.date(byAdding: .month, value: -RegoleCampagne.mesiPrevidenzaFerma, to: inizio) ?? inizio
        let annoProssimo = cal.component(.year, from: oggi) + 1

        for c in dati.clienti {
            let suePosizioni = posizioni[c.id] ?? []
            // I bisogni di MotoreBisogni non scartati dal consulente
            let bisogni = MotoreBisogni.rileva(cliente: c, posizioni: suePosizioni, analisi: dati.analisi[c.id] ?? Analisi360(), oggi: oggi)
            for tipo in [TipoGruppoCampagna.protezioneFamiglia, .previdenzaAssente, .liquiditaFerma] {
                guard let idBisogno = tipo.bisognoId, let b = bisogni.first(where: { $0.id == idBisogno }),
                      c.bisogni.esiti[idBisogno] != false else { continue }
                aggiungi(tipo.rawValue, tipo, TestiCampagne.titolo(tipo, mese: nil, eta: nil, anno: nil, soloTitoliStato: false), c,
                         b.motivo, [CifraMessaggio(.bisogno, TestiCampagne.bisogno(tipo))])
            }
            // Le scadenze nello stesso mese, entro sei mesi
            let inEssere = suePosizioni.filter { $0.stato == .inEssere }
            for p in inEssere {
                guard let s = p.scadenza, s >= inizio, s <= limiteScadenza else { continue }
                let comp = cal.dateComponents([.year, .month], from: s)
                let id = String(format: "scadenzaNelMese-%04d-%02d", comp.year ?? 0, comp.month ?? 0)
                let data = Formati.dataEstesa.string(from: s)
                aggiungi(id, .scadenzaNelMese, "", c, "«\(p.nome)» scade \(ModelliMessaggi.il(data))",
                         [CifraMessaggio(.posizione, p.nome), CifraMessaggio(.scadenza, data),
                          CifraMessaggio(.bisogno, "«\(p.nome)» scade \(ModelliMessaggi.il(data))")])
            }
            // Le età tonde l'anno prossimo
            if let n = c.dataNascita {
                let eta = annoProssimo - cal.component(.year, from: n)
                if RegoleCampagne.etaTonde.contains(eta) {
                    let id = "etaTonda-\(eta)-\(annoProssimo)"
                    aggiungi(id, .etaTonda, TestiCampagne.titolo(.etaTonda, mese: nil, eta: eta, anno: annoProssimo, soloTitoliStato: false),
                             c, "Compie \(eta) anni nel \(annoProssimo)",
                             [CifraMessaggio(.etaProssima, "\(eta) anni"),
                              CifraMessaggio(.bisogno, "nel \(annoProssimo) arriva un compleanno importante, i \(eta) anni: un buon momento per rivedere il piano")])
                }
            }
            // La previdenza ferma: in essere, senza versamenti da dodici mesi; senza movimenti registrati non si valuta
            for p in inEssere where p.area == .previdenza {
                guard let movimenti = p.movimenti, !movimenti.isEmpty else {
                    nonValutatiPrevidenza += 1
                    continue
                }
                let ultimo = movimenti.filter { $0.importo > 0 }.map(\.data).max()
                guard ultimo.map({ $0 < limiteVersamenti }) ?? true else { continue }
                let quando = ultimo.map { Formati.dataEstesa.string(from: $0) }
                let motivo = quando.map { "«\(p.nome)» senza versamenti dal \($0)" } ?? "«\(p.nome)» senza versamenti registrati"
                var cifre = [CifraMessaggio(.posizione, p.nome)]
                if let q = quando { cifre.append(CifraMessaggio(.ultimoVersamento, q)) }
                cifre.append(CifraMessaggio(.bisogno, quando.map { "il fondo pensione «\(p.nome)» non riceve versamenti dal \($0)" }
                                            ?? "il fondo pensione «\(p.nome)» non riceve versamenti"))
                aggiungi(TipoGruppoCampagna.previdenzaFerma.rawValue, .previdenzaFerma,
                         TestiCampagne.titolo(.previdenzaFerma, mese: nil, eta: nil, anno: nil, soloTitoliStato: false), c, motivo, cifre)
            }
        }

        // I titoli delle scadenze: «Titoli di Stato» solo se tutte le posizioni del mese lo sono
        for (id, v) in voci where v.tipo == .scadenzaNelMese {
            let parti = id.split(separator: "-")
            let mese = parti.count == 3 ? gregoriano.date(from: DateComponents(year: Int(parti[1]), month: Int(parti[2]), day: 1)) : nil
            let tutteBtp = v.membri.allSatisfy { m in
                let delMese = (posizioni[m.0.id] ?? []).filter { p in
                    guard p.stato == .inEssere, let s = p.scadenza, let mm = mese else { return false }
                    return cal.isDate(s, equalTo: mm, toGranularity: .month)
                }
                return !delMese.isEmpty && delMese.allSatisfy { ($0.quotaTitoliStato ?? 0) >= 1 }
            }
            voci[id]?.titolo = TestiCampagne.titolo(.scadenzaNelMese, mese: mese, eta: nil, anno: nil, soloTitoliStato: tutteBtp)
        }

        // I gruppi abbastanza grandi
        let formati = voci.filter { $0.value.membri.count >= max(1, minimo) }
        var titoliDi: [String: [String]] = [:]
        for (_, v) in formati.sorted(by: { $0.key < $1.key }) {
            for m in v.membri { titoliDi[m.0.id, default: []].append(v.titolo) }
        }
        let limiteStesso = cal.date(byAdding: .day, value: -RegoleCampagne.giorniStessoBisogno, to: inizio) ?? inizio
        let limiteCampagne = cal.date(byAdding: .day, value: -RegoleCampagne.giorniFraCampagne, to: inizio) ?? inizio
        let campagnePerId = Dictionary(dati.campagne.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        var risultato: [GruppoCampagna] = []
        for (id, v) in formati {
            let membri = v.membri.map { voce -> MembroCampagna in
                let (c, motivo, cifre) = voce
                let consenso = MotoreConformita.commercialeValido(c, regole: dati.impostazioni.conformita, oggi: oggi, calendario: cal)
                let mail = AperturaMessaggi.email(c) != nil
                let messaggi = AperturaMessaggi.telefono(c) != nil
                // Già scritto per lo stesso bisogno (un messaggio di campagna aperto o salvato, di una campagna dello stesso tipo)
                let gia = dati.messaggi.filter { m in
                    m.clienteId == c.id && m.origine.tipo == .campagna && m.stato.copreOccasione && m.dataMostrata >= limiteStesso
                        && campagnePerId[m.origine.riferimento]?.gruppoTipo == v.tipo
                }.map(\.dataMostrata).max()
                let ultima = dati.campagne.filter { $0.clienti.contains(c.id) && $0.avviataIl >= limiteCampagne }.map(\.avviataIl).max()
                let canale = MotoreOccasioniMessaggi.canaleComune(c, posizioni[c.id] ?? [])
                return MembroCampagna(clienteId: c.id, motivo: motivo, cifre: cifre, consenso: consenso, recapitoMail: mail,
                                      recapitoMessaggi: messaggi, giaContattato: gia, ultimaCampagna: ultima, canaleLavoro: canale,
                                      inclusoDiBase: consenso && (mail || messaggi) && gia == nil && ultima == nil,
                                      anchein: (titoliDi[c.id] ?? []).filter { $0 != v.titolo })
            }.sorted { a, b in
                let na = dati.clienti.first { $0.id == a.clienteId }?.nome ?? ""
                let nb = dati.clienti.first { $0.id == b.clienteId }?.nome ?? ""
                return na != nb ? na.localizedCompare(nb) == .orderedAscending : a.clienteId < b.clienteId
            }
            let nv = v.tipo == .previdenzaFerma ? nonValutatiPrevidenza : 0
            risultato.append(GruppoCampagna(id: id, tipo: v.tipo, titolo: v.titolo, membri: membri, nonValutati: nv,
                                            notaNonValutati: nv > 0 ? TestiCampagne.nonValutati(nv) : nil))
        }
        return risultato.sorted { a, b in
            if a.membri.count != b.membri.count { return a.membri.count > b.membri.count }
            return a.id < b.id
        }
    }

    /// Quanti fondi pensione non si sono potuti valutare (senza movimenti registrati), anche se il gruppo non si forma.
    static func previdenzeNonValutate(dati: DatiPrisma) -> Int {
        dati.posizioni.filter { $0.stato == .inEssere && $0.area == .previdenza && ($0.movimenti ?? []).isEmpty }.count
    }

    // MARK: - Occasioni dei messaggi

    /// L'occasione del messaggio di un membro: origine «campagna» con l'id della campagna, le cifre del solo membro e gli
    /// orari proposti. `MessaggioCliente.occasioneId` = `id` di questa occasione.
    static func occasione(gruppo: GruppoCampagna, membro: MembroCampagna, campagnaId: String, appuntamenti: [Date],
                          data: Date = MessaggioCliente.adesso) -> OccasioneMessaggio {
        var cifre = membro.cifre
        if !appuntamenti.isEmpty { cifre.append(CifraMessaggio(.appuntamentiProposti, TestiCampagne.orari(appuntamenti))) }
        return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .campagna, riferimento: campagnaId), clienteId: membro.clienteId,
                                  canale: membro.canaleLavoro, gruppo: .oggi, titolo: gruppo.titolo,
                                  perche: TestiCampagne.perche(gruppo.titolo), oggetto: TestiCampagne.oggetto(gruppo.tipo),
                                  cifre: cifre, priorita: .bassa, data: data)
    }

    /// Le occasioni delle bozze di campagna ancora da aprire, per «Da mandare oggi» (priorità bassa, fuori dal limite di 8:
    /// non scacciano le altre). Le stesse bozze, mai duplicate: l'id dell'occasione è quello del messaggio.
    static func occasioniDaBozze(dati: DatiPrisma, oggi: Date) -> [OccasioneMessaggio] {
        let clienti = Set(dati.clienti.map(\.id))
        let campagne = Dictionary(dati.campagne.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return dati.messaggi.compactMap { m -> OccasioneMessaggio? in
            guard m.origine.tipo == .campagna, m.stato == .bozza, clienti.contains(m.clienteId) else { return nil }
            let titolo = campagne[m.origine.riferimento]?.titolo ?? TipoOccasioneMessaggio.campagna.nome
            return OccasioneMessaggio(origine: m.origine, clienteId: m.clienteId, canale: m.canaleLavoro, gruppo: .oggi,
                                      titolo: titolo, perche: TestiCampagne.perche(titolo), oggetto: m.oggetto ?? titolo,
                                      cifre: m.cifre, priorita: .bassa, data: m.creatoIl)
        }
    }

    // MARK: - Mappa

    /// La disposizione dei gruppi nella mappa: al più sei in griglia 2×3 (centri in 0…1), gli altri in «Altri bisogni».
    static func disposizione(_ gruppi: [GruppoCampagna]) -> (inMappa: [(GruppoCampagna, CGPoint)], altri: [GruppoCampagna]) {
        let ordinati = gruppi.sorted { a, b in a.membri.count != b.membri.count ? a.membri.count > b.membri.count : a.id < b.id }
        let dentro = Array(ordinati.prefix(RegoleCampagne.massimoGruppiInMappa))
        let altri = Array(ordinati.dropFirst(RegoleCampagne.massimoGruppiInMappa))
        let colonne = dentro.count <= 3 ? max(1, dentro.count) : 3
        let righe = dentro.count <= 3 ? 1 : 2
        var r: [(GruppoCampagna, CGPoint)] = []
        for (i, g) in dentro.enumerated() {
            let riga = i / colonne, colonna = i % colonne
            let quanti = riga == righe - 1 ? dentro.count - riga * colonne : colonne
            let x = (Double(colonna) + 0.5) / Double(max(1, quanti))
            let y = righe == 1 ? 0.5 : (riga == 0 ? 0.3 : 0.72)
            r.append((g, CGPoint(x: x, y: y)))
        }
        return (r, altri)
    }

    /// Seme stabile da una stringa (FNV-1a a 64 bit sugli UTF-8): MAI `hashValue`, che cambia a ogni avvio.
    static func seme(_ s: String) -> UInt64 {
        var h: UInt64 = 14_695_981_039_346_656_037
        for b in s.utf8 {
            h ^= UInt64(b)
            h = h &* 1_099_511_628_211
        }
        return h
    }

    /// Un numero in 0..<1 dal seme e da un indice (splitmix64): posizioni di partenza stabili dei pallini.
    static func casuale(_ seme: UInt64, _ k: Int) -> Double {
        var z = seme &+ UInt64(truncatingIfNeeded: k + 1) &* 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(UInt64(1) << 53)
    }

    /// Il raggio del cerchio di un gruppo: min(46 + n·7, 120).
    static func raggio(membri: Int) -> Double {
        min(46 + Double(max(0, membri)) * 7, 120)
    }
}

/// Le frasi delle campagne, tutte in un punto. Ogni messaggio è per una persona sola: mai nomi d'altri, mai «abbiamo
/// scritto a tutti».
enum TestiCampagne {
    private static let mese = Formati.formato("MMMM")
    private static let orario = Formati.formato("EEE d 'alle' HH:mm")

    /// «Famiglia senza protezione», «Posizioni in scadenza a marzo» («Titoli di Stato in scadenza a marzo» solo se tutte
    /// le posizioni lo sono), «Compiono 50 anni nel 2027», «Fondo pensione fermo da un anno», «Senza previdenza
    /// integrativa», «Liquidità ferma sul conto».
    static func titolo(_ tipo: TipoGruppoCampagna, mese m: Date?, eta: Int?, anno: Int?, soloTitoliStato: Bool) -> String {
        switch tipo {
        case .protezioneFamiglia: return "Famiglia senza protezione"
        case .scadenzaNelMese:
            let nome = m.map { mese.string(from: $0) } ?? "nei prossimi mesi"
            let a = m == nil ? "" : "a "
            return (soloTitoliStato ? "Titoli di Stato in scadenza " : "Posizioni in scadenza ") + a + nome
        case .etaTonda:
            if let e = eta, let a = anno { return "Compiono \(e) anni nel \(a)" }
            return "Un compleanno importante l'anno prossimo"
        case .previdenzaFerma: return "Fondo pensione fermo da un anno"
        case .previdenzaAssente: return "Senza previdenza integrativa"
        case .liquiditaFerma: return "Liquidità ferma sul conto"
        }
    }

    /// Il bisogno detto per il messaggio (neutro: vale con il tu e con il lei).
    static func bisogno(_ tipo: TipoGruppoCampagna) -> String {
        switch tipo {
        case .protezioneFamiglia: return "la protezione della famiglia, se dovesse succedere qualcosa, oggi non basta"
        case .previdenzaAssente: return "manca ancora una previdenza integrativa accanto alla pensione pubblica"
        case .liquiditaFerma: return "sul conto c'è più liquidità di quella che serve per gli imprevisti, e resta ferma"
        case .scadenzaNelMese: return "una posizione arriva a scadenza nei prossimi mesi"
        case .etaTonda: return "l'anno prossimo arriva un compleanno importante"
        case .previdenzaFerma: return "il fondo pensione non riceve versamenti da più di un anno"
        }
    }

    static func oggetto(_ tipo: TipoGruppoCampagna) -> String {
        switch tipo {
        case .protezioneFamiglia: return "La protezione della famiglia"
        case .scadenzaNelMese: return "Una scadenza da guardare insieme"
        case .etaTonda: return "Un compleanno importante"
        case .previdenzaFerma: return "Il fondo pensione"
        case .previdenzaAssente: return "La pensione di domani"
        case .liquiditaFerma: return "La liquidità sul conto"
        }
    }

    static func perche(_ titolo: String) -> String { "Campagna: \(titolo)" }

    /// «mar 10 alle 10:00, mer 11 alle 15:30».
    static func orari(_ date: [Date]) -> String {
        date.sorted().map { orario.string(from: $0) }.joined(separator: ", ")
    }

    /// La chip di un orario: «mar 10 · 10:00».
    static func chip(_ d: Date) -> String { Formati.giornoBreve.string(from: d) + " · " + Formati.ora.string(from: d) }

    static func nonValutati(_ n: Int) -> String {
        n == 1 ? "1 fondo pensione senza movimenti registrati: non valutato"
               : "\(n) fondi pensione senza movimenti registrati: non valutati"
    }

    /// «N CLIENTI · K GRUPPI CON LO STESSO BISOGNO».
    static func etichettaMappa(clienti: Int, gruppi: Int) -> String {
        "\(clienti) \(clienti == 1 ? "CLIENTE" : "CLIENTI") · \(gruppi) \(gruppi == 1 ? "GRUPPO" : "GRUPPI") CON LO STESSO BISOGNO"
    }

    /// «7 clienti · Marco, Giulia e altri 5».
    static func sottotitolo(nomi: [String]) -> String {
        let primi = nomi.prefix(2).map { TestiTraguardi.primoNome($0) }
        let n = nomi.count
        let testa = "\(n) \(n == 1 ? "cliente" : "clienti")"
        switch n {
        case 0: return testa
        case 1: return testa + " · " + primi[0]
        case 2: return testa + " · " + primi.joined(separator: " e ")
        default: return testa + " · " + primi.joined(separator: ", ") + " e \(n - 2 == 1 ? "un altro" : "altri \(n - 2)")"
        }
    }

    static func contoGruppo(_ n: Int) -> String { n == 1 ? "1 cliente" : "\(n) clienti" }
    static let tra = "tra i clienti di prova"
    static let vuoto = "Nessun gruppo con lo stesso bisogno, per ora. I gruppi nascono dai bisogni che Prisma calcola nei dossier: quando almeno due clienti condividono un bisogno, compaiono qui."
    static let altriBisogni = "Altri bisogni"
    static let campagna = "CAMPAGNA"
    static let appuntamenti = "APPUNTAMENTI DA PROPORRE"
    static let agendaPiena = "Nessuno spazio libero nelle prossime due settimane"
    static let senzaConsenso = "senza consenso commerciale"
    static let regoleDaApprovare = "Soglie dei gruppi da approvare: età 40/50/60, scadenze entro 6 mesi, fondo fermo da 12 mesi, 30 giorni fra due campagne."
    static let avvia = "Avvia la campagna"
    static let apriProssima = "Apri la prossima"
    static let apriTutte = "Apri tutte"
    static let annulla = "Annulla la campagna"
    static let storico = "Campagne avviate"
    static let vediMessaggio = "Vedi il messaggio"
    static let bozzaPronta = "✓ bozza pronta"
    static let riscriviVera = "Fai riscrivere a Vera"
    static let fermaVera = "Ferma Vera"
    static let sceltaFirma = "Clienti di canali diversi: con quale firma?"
    static let veraNonPronta = "Vera non è pronta: resta il testo di Prisma, già con le cifre di ogni cliente."

    static func pronti(_ n: Int) -> String { "✓ \(n) \(n == 1 ? "messaggio pronto" : "messaggi pronti") · li spedisci tu" }
    static func toastPronte(_ n: Int) -> String { "\(n) \(n == 1 ? "bozza pronta" : "bozze pronte") in Messaggi: le spedisci tu" }
    static func giaScritto(_ d: Date) -> String { "già scritto " + ModelliMessaggi.il(Formati.dataEstesa.string(from: d)) }
    static func ancheIn(_ titoli: [String]) -> String { "anche in: " + titoli.joined(separator: ", ") }
    static func confermaApriTutte(_ n: Int) -> String { "Aprire \(n) messaggi uno dopo l'altro? Si apriranno \(n) finestre di Mail o Messaggi." }

    /// La nota sopra il pulsante: «5 messaggi: 2 clienti senza consenso commerciale restano fuori».
    static func notaPulsante(inclusi: Int, senzaConsenso: Int, senzaRecapito: Int) -> String {
        var t = "\(inclusi) \(inclusi == 1 ? "messaggio" : "messaggi")"
        var fuori: [String] = []
        if senzaConsenso > 0 { fuori.append("\(senzaConsenso) senza consenso commerciale") }
        if senzaRecapito > 0 { fuori.append("\(senzaRecapito) senza recapito") }
        if !fuori.isEmpty { t += ": " + fuori.joined(separator: " e ") + " restano fuori" }
        return t
    }

    static func confermaSenzaConsenso(_ nome: String) -> String {
        "\(TestiTraguardi.primoNome(nome)) non ha un consenso commerciale valido. Includerlo comunque in questa campagna?"
    }

    /// Lo storico: «2 ottobre · Famiglia senza protezione · 3 aperti, 4 da aprire».
    static func rigaStorico(_ c: Campagna, aperti: Int, daAprire: Int) -> String {
        Formati.giornoMese.string(from: c.avviataIl) + " · " + c.titolo + " · \(aperti) aperti, \(daAprire) da aprire"
    }
}
