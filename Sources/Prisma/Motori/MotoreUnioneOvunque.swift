import Foundation

// Prisma ovunque (Design/ovunque-fattibilita.md §4, giro 8): il giornale dei dispositivi e l'unione sul Mac.
// - `RegistroOvunque`: sul dispositivo, ogni modifica salvata diventa operazioni del giornale (confronto tra l'archivio
//   prima e dopo, sui soli campi sincronizzabili di `CampiOvunque`), con id, dispositivo, Lamport, progressivo e data.
// - `MotoreUnioneOvunque`: sul Mac, l'unione a tre vie (valore attuale del Mac contro `prima`). Ordine per (Lamport,
//   dispositivo, progressivo); un'operazione già vista non si applica due volte; lo stesso campo cambiato in due posti
//   va in «Da decidere» e finché l'utente non sceglie vale il valore del Mac. Mai una scelta in silenzio, mai l'ora
//   dell'orologio per decidere.

/// Una differenza tra due archivi, prima di diventare un'operazione del giornale.
struct DifferenzaOvunque: Equatable {
    var entita: EntitaOvunque
    var entitaId: String
    var tipo: TipoOperazioneOvunque
    var campo: String?
    var prima: String?
    var dopo: String?
}

enum RegistroOvunque {
    /// Le differenze sui campi sincronizzabili tra `prima` e `dopo`, in ordine stabile (tipo, poi id, poi campo).
    static func differenze(da prima: DatiPrisma, a dopo: DatiPrisma) -> [DifferenzaOvunque] {
        var r: [DifferenzaOvunque] = []
        for e in EntitaOvunque.allCases {
            let regole = CampiOvunque.regole(e)
            let vecchi = CampiOvunque.oggetti(e, in: prima)
            let nuovi = CampiOvunque.oggetti(e, in: dopo)
            for id in nuovi.keys.sorted() {
                guard let n = nuovi[id] else { continue }
                if let v = vecchi[id] {
                    for campo in regole.campi {
                        let a = JSONOvunque.canonico(v[campo])
                        let b = JSONOvunque.canonico(n[campo])
                        if a != b {
                            r.append(DifferenzaOvunque(entita: e, entitaId: id, tipo: .modificaCampo, campo: campo, prima: a, dopo: b))
                        }
                    }
                } else if regole.creabile {
                    r.append(DifferenzaOvunque(entita: e, entitaId: id, tipo: .crea, campo: nil, prima: nil, dopo: JSONOvunque.canonico(n)))
                }
            }
            if regole.eliminabile {
                for id in vecchi.keys.sorted() where nuovi[id] == nil {
                    guard let v = vecchi[id] else { continue }
                    r.append(DifferenzaOvunque(entita: e, entitaId: id, tipo: .elimina, campo: nil,
                                               prima: JSONOvunque.canonico(CampiOvunque.ristretto(v, regole)), dopo: nil))
                }
            }
        }
        return r
    }

    /// Sul dispositivo: aggiunge al giornale di `dopo` le operazioni della modifica da `prima` a `dopo` e fa avanzare
    /// Lamport e progressivo. Non fa nulla sul Mac, a spazio spento o con la copia di sola lettura. Restituisce quante.
    @discardableResult
    static func registra(prima: DatiPrisma, dopo: inout DatiPrisma, adesso: Date = Date()) -> Int {
        let o = dopo.impostazioni.ovunque
        guard o.scriveGiornale, let dispositivo = o.idDispositivo else { return 0 }
        let elenco = differenze(da: prima, a: dopo)
        guard !elenco.isEmpty else { return 0 }
        var lamport = max(o.lamport, prima.impostazioni.ovunque.lamport)
        var seq = max(o.prossimoSeq, (dopo.giornaleOvunque.map(\.seq).max() ?? 0) + 1)
        let quando = alSecondo(adesso)
        for d in elenco {
            lamport += 1
            dopo.giornaleOvunque.append(OperazioneOvunque(
                id: "op-" + UUID().uuidString.lowercased(), dispositivo: dispositivo, lamport: lamport, seq: seq, data: quando,
                base: o.generazione, entita: d.entita, entitaId: d.entitaId, tipo: d.tipo, campo: d.campo, prima: d.prima, dopo: d.dopo))
            seq += 1
        }
        dopo.impostazioni.ovunque.lamport = lamport
        dopo.impostazioni.ovunque.prossimoSeq = seq
        return elenco.count
    }

    /// Le date dello spazio si tengono al secondo, come l'archivio.
    static func alSecondo(_ d: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: d.timeIntervalSinceReferenceDate.rounded(.down))
    }
}

/// Il risultato di un'unione sul Mac.
struct EsitoUnioneOvunque {
    var dati: DatiPrisma
    /// La ricevuta da scrivere nell'istantanea: fin dove è arrivato il giornale di ogni dispositivo.
    var vistoFinoA: [String: Int]
    var lamport: Int
    /// Operazioni applicate (o già allineate: il Mac aveva già lo stesso valore).
    var unite: [OperazioneOvunque]
    /// Conflitti nuovi, aggiunti a `dati.conflittiOvunque`.
    var conflitti: [ConflittoOvunque]
    /// Operazioni già viste o non applicabili (scartate senza toccare l'archivio).
    var scartate: Int

    /// true se l'unione ha cambiato qualcosa da scrivere (dati, coda «Da decidere» o ricevuta).
    var cambiato: Bool { !unite.isEmpty || !conflitti.isEmpty }
}

enum MotoreUnioneOvunque {
    /// Quanti «Arrivato da iPhone» si tengono.
    static let massimoArrivi = 200

    enum EsitoOperazione: Equatable {
        case applicata(nuova: Bool)
        case allineata
        case scartata
        case conflitto(MotivoConflitto, valoreMac: String?)
    }

    /// Unisce i giornali nell'archivio del Mac. Idempotente: le stesse operazioni unite due volte danno lo stesso archivio.
    static func unisci(_ giornali: [GiornaleOvunque], in dati: DatiPrisma, vistoFinoA: [String: Int], lamport: Int,
                       adesso: Date = Date()) -> EsitoUnioneOvunque {
        var d = dati
        var visto = vistoFinoA
        var nomi: [String: String] = [:]
        var tutte: [String: OperazioneOvunque] = [:]
        var scartate = 0
        let inCoda = Set(d.conflittiOvunque.map(\.id))
        for g in giornali {
            nomi[g.dispositivo] = g.nomeDispositivo
            for op in g.operazioni {
                // Più copie dello stesso giornale («nome 2»): le stesse operazioni, una volta sola
                if tutte[op.id] != nil { continue }
                // Un giornale contiene solo le operazioni del suo dispositivo; quelle già unite o in coda non tornano
                guard op.dispositivo == g.dispositivo, op.seq > (vistoFinoA[op.dispositivo] ?? 0), !inCoda.contains(op.id) else {
                    scartate += 1
                    continue
                }
                tutte[op.id] = op
            }
        }
        let ordinate = tutte.values.sorted { ($0.lamport, $0.dispositivo, $0.seq) < ($1.lamport, $1.dispositivo, $1.seq) }
        var unite: [OperazioneOvunque] = []
        var conflitti: [ConflittoOvunque] = []
        var orologio = lamport
        let quando = RegistroOvunque.alSecondo(adesso)
        for op in ordinate {
            orologio = max(orologio, op.lamport)
            visto[op.dispositivo] = max(visto[op.dispositivo] ?? 0, op.seq)
            let nome = nomi[op.dispositivo] ?? op.dispositivo
            switch applica(op, a: &d) {
            case .applicata(let nuova):
                unite.append(op)
                if nuova {
                    d.arriviOvunque.append(ArrivoOvunque(entita: op.entita, entitaId: op.entitaId, dispositivo: op.dispositivo,
                                                         nomeDispositivo: nome, il: quando))
                }
            case .allineata:
                unite.append(op)
            case .scartata:
                scartate += 1
            case .conflitto(let motivo, let valoreMac):
                conflitti.append(ConflittoOvunque(operazione: op, motivo: motivo, valoreMac: valoreMac, nomeDispositivo: nome, arrivatoIl: quando))
            }
        }
        d.conflittiOvunque.append(contentsOf: conflitti)
        if d.arriviOvunque.count > massimoArrivi { d.arriviOvunque.removeFirst(d.arriviOvunque.count - massimoArrivi) }
        return EsitoUnioneOvunque(dati: d, vistoFinoA: visto, lamport: orologio, unite: unite, conflitti: conflitti, scartate: scartate)
    }

    /// Applica un'operazione con le regole a tre vie.
    static func applica(_ op: OperazioneOvunque, a d: inout DatiPrisma) -> EsitoOperazione {
        let regole = CampiOvunque.regole(op.entita)
        let attuale = CampiOvunque.oggetto(op.entita, id: op.entitaId, in: d)
        switch op.tipo {
        case .crea:
            guard regole.creabile, let nuovo = JSONOvunque.oggetto(op.dopo) else { return .scartata }
            // Un id che c'è già: l'operazione è già stata unita (idempotenza)
            if attuale != nil { return .scartata }
            if regole.conCliente, let cliente = nuovo["clienteId"] as? String, !d.clienti.contains(where: { $0.id == cliente }) {
                return .conflitto(.clienteMancante, valoreMac: nil)
            }
            return CampiOvunque.scrivi(op.entita, id: op.entitaId, json: nuovo, in: &d) ? .applicata(nuova: true) : .scartata
        case .modificaCampo:
            guard let campo = op.campo, regole.campi.contains(campo) else { return .scartata }
            guard var oggetto = attuale else { return .conflitto(.eliminataSulMac, valoreMac: nil) }
            let valoreMac = JSONOvunque.canonico(oggetto[campo])
            let dopo = op.dopo ?? JSONOvunque.nullo
            if valoreMac == dopo { return .allineata }
            if valoreMac != (op.prima ?? JSONOvunque.nullo) {
                guard regole.servizio.contains(campo) else { return .conflitto(.stessoCampo, valoreMac: valoreMac) }
                // Data di servizio cambiata in tutti e due i posti: vale la più recente (ISO 8601 si ordina come testo)
                guard valoreMac == JSONOvunque.nullo || dopo > valoreMac else { return .allineata }
            }
            if campo == "clienteId", regole.conCliente, let cliente = JSONOvunque.valore(dopo) as? String,
               !d.clienti.contains(where: { $0.id == cliente }) {
                return .conflitto(.clienteMancante, valoreMac: valoreMac)
            }
            JSONOvunque.imposta(&oggetto, campo, dopo)
            return CampiOvunque.scrivi(op.entita, id: op.entitaId, json: oggetto, in: &d) ? .applicata(nuova: false) : .scartata
        case .elimina:
            guard regole.eliminabile else { return .scartata }
            guard let oggetto = attuale else { return .allineata }
            // Il Mac l'ha cambiata dopo che il dispositivo l'ha vista: non si elimina in silenzio
            guard JSONOvunque.canonico(CampiOvunque.ristretto(oggetto, regole)) == (op.prima ?? "") else {
                return .conflitto(.eliminataSulDispositivo, valoreMac: JSONOvunque.canonico(oggetto))
            }
            return CampiOvunque.togli(op.entita, id: op.entitaId, in: &d) ? .applicata(nuova: false) : .scartata
        }
    }

    /// Applica un'operazione senza il confronto con `prima`: la scelta «Tieni quella dell'iPhone» e, sul dispositivo,
    /// la riapplicazione delle proprie operazioni non ancora confermate sopra un'istantanea nuova. false se non si può.
    @discardableResult
    static func applicaForzata(_ op: OperazioneOvunque, a d: inout DatiPrisma) -> Bool {
        let regole = CampiOvunque.regole(op.entita)
        switch op.tipo {
        case .crea:
            guard regole.creabile, let nuovo = JSONOvunque.oggetto(op.dopo) else { return false }
            if CampiOvunque.oggetto(op.entita, id: op.entitaId, in: d) != nil { return true }
            return CampiOvunque.scrivi(op.entita, id: op.entitaId, json: nuovo, in: &d)
        case .modificaCampo:
            guard let campo = op.campo, regole.campi.contains(campo),
                  var oggetto = CampiOvunque.oggetto(op.entita, id: op.entitaId, in: d) else { return false }
            JSONOvunque.imposta(&oggetto, campo, op.dopo ?? JSONOvunque.nullo)
            return CampiOvunque.scrivi(op.entita, id: op.entitaId, json: oggetto, in: &d)
        case .elimina:
            guard regole.eliminabile else { return false }
            CampiOvunque.togli(op.entita, id: op.entitaId, in: &d)
            return true
        }
    }

    /// La scelta dell'utente su un conflitto in «Da decidere». «Tieni quella del Mac» lo chiude e basta; «Tieni quella
    /// dell'iPhone» applica l'operazione (non per un cliente che sul Mac non c'è più: niente orfani). false se non si può.
    @discardableResult
    static func decidi(_ conflittoId: String, scelta: SceltaConflitto, in d: inout DatiPrisma, adesso: Date = Date()) -> Bool {
        guard let i = d.conflittiOvunque.firstIndex(where: { $0.id == conflittoId }) else { return false }
        let c = d.conflittiOvunque[i]
        if scelta == .tieniDispositivo {
            guard c.motivo != .clienteMancante, applicaForzata(c.operazione, a: &d) else { return false }
            if c.operazione.tipo == .crea {
                d.arriviOvunque.append(ArrivoOvunque(entita: c.operazione.entita, entitaId: c.operazione.entitaId,
                                                     dispositivo: c.operazione.dispositivo, nomeDispositivo: c.nomeDispositivo,
                                                     il: RegistroOvunque.alSecondo(adesso)))
            }
        }
        d.conflittiOvunque.remove(at: i)
        return true
    }

    /// Quante operazioni per tipo («una nota e due attività»).
    static func conteggio(_ operazioni: [OperazioneOvunque]) -> [EntitaOvunque: Int] {
        var r: [EntitaOvunque: Int] = [:]
        for op in operazioni { r[op.entita, default: 0] += 1 }
        return r
    }
}
