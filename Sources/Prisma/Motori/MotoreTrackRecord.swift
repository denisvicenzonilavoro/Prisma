import Foundation

// MARK: - Studio › Track record (giro 2, specifica Design/template-novita-specifica.md §4.5.3)
// Motore puro, senza SwiftUI, deterministico. Legge il registro delle raccomandazioni (`DatiPrisma.raccomandazioni`,
// immutabile) e i valori aggiornati delle posizioni che esistono già, e conta:
// - quante raccomandazioni, quante accettate (accettate / (accettate + rifiutate), come Portafoglio.tassoAccettazione);
// - quante accettate da almeno 12 mesi sono ancora in essere (la posizione c'è ed è in essere oggi);
// - lo scarto rispetto all'alternativa, SEMPRE una stima: i versamenti veri della posizione fatti crescere al ritmo del
//   riferimento dell'alternativa (`MotoreRiferimenti.versamenti`, metodo «public market equivalent»), contro il valore
//   aggiornato della posizione. Senza un riferimento per l'alternativa, niente scarto per quella raccomandazione.
// Lo scarto medio annuo è la media di (tasso effettivo − tasso dell'alternativa), in punti percentuali all'anno, pesata
// sul valore al riferimento.
//
// Costruisce anche la raccomandazione da registrare quando una proposta viene presentata (`raccomandazione(per:…)`), con
// le cifre di quel momento: i dati della proposta e i controlli della scheda di adeguatezza (`MotoreAdeguatezza`).

/// Il track record del consulente.
struct TrackRecord: Equatable {
    /// Lo scarto stimato di un'accettata rispetto all'alternativa.
    struct Scarto: Equatable {
        /// Valore aggiornato − valore degli stessi versamenti al ritmo dell'alternativa (€).
        let differenza: Double
        let valoreEffettivo: Double
        let valoreAlternativa: Double
        /// Tassi annui (%) dei versamenti con il valore vero e con il valore al riferimento.
        let tassoEffettivo: Double?
        let tassoAlternativa: Double?
        /// tassoEffettivo − tassoAlternativa, in punti percentuali all'anno.
        let puntiAnnui: Double?
        /// Gli anni del riferimento stimati con l'ultimo valore noto.
        let anniStimati: [Int]
        /// Sempre true: lo scarto è una stima.
        let stima: Bool
    }

    /// Come si misura una raccomandazione.
    enum Misura: Equatable {
        case scarto(Scarto)
        /// L'alternativa non ha un riferimento con cui ricostruirla: niente scarto.
        case senzaRiferimento
        /// Mancano i valori del riferimento dall'anno indicato.
        case riferimentoMancante(dal: Int)
        /// Mancano i valori aggiornati della posizione (o lo storico è sotto l'anno).
        case pochiDati
        /// La posizione collegata non c'è più.
        case posizioneAssente
        /// Non accettata (rifiutata o in attesa): non si misura.
        case nonAccettata
    }

    struct Voce: Identifiable, Equatable {
        let raccomandazione: Raccomandazione
        let posizione: Posizione?
        /// Accettata da almeno 12 mesi.
        let daAlmeno12Mesi: Bool
        /// La posizione c'è ed è in essere oggi.
        let inEssere: Bool
        let misura: Misura
        var id: String { raccomandazione.id }
    }

    let raccomandazioni: Int
    let accettate: Int
    let rifiutate: Int
    let inAttesa: Int
    /// accettate / (accettate + rifiutate); nil senza decise.
    let quotaAccettate: Double?
    let accettateDaAlmeno12Mesi: Int
    let inEssereDopo12Mesi: Int
    /// inEssereDopo12Mesi / accettateDaAlmeno12Mesi; nil senza accettate da almeno 12 mesi.
    let quotaInEssereDopo12Mesi: Double?
    /// Le raccomandazioni con uno scarto stimato.
    let misurate: Int
    /// Media pesata degli scarti annui (punti % all'anno); nil senza scarti misurati. Stima.
    let scartoMedioAnnuo: Double?
    /// Somma delle differenze in euro delle misurate; nil senza misurate. Stima.
    let differenzaTotale: Double?
    /// Sempre true: gli scarti sono stime.
    let stima: Bool
    /// L'anno della raccomandazione più vecchia.
    let dal: Int?
    /// Dalla più recente.
    let voci: [Voce]
}

enum MotoreTrackRecord {
    /// I mesi dopo cui si guarda se una raccomandazione accettata è ancora in essere.
    static let mesiPermanenza = 12

    /// Il track record dalle raccomandazioni registrate e dalle posizioni di oggi. In O(R + P) più il calcolo dei
    /// versamenti al riferimento per le accettate.
    static func calcola(raccomandazioni: [Raccomandazione], posizioni: [Posizione], riferimenti: RiferimentiRendimento,
                        oggi: Date, cal: Calendar = .current) -> TrackRecord {
        calcola(raccomandazioni: raccomandazioni, posizioni: posizioni, tabella: TabellaRiferimenti(riferimenti), oggi: oggi, cal: cal)
    }

    static func calcola(raccomandazioni: [Raccomandazione], posizioni: [Posizione], tabella: TabellaRiferimenti,
                        oggi: Date, cal: Calendar = .current) -> TrackRecord {
        let perId = Dictionary(posizioni.map { ($0.id, $0) }, uniquingKeysWith: { primo, _ in primo })
        let soglia = cal.date(byAdding: .month, value: -mesiPermanenza, to: oggi) ?? oggi
        var accettate = 0, rifiutate = 0, inAttesa = 0, vecchie = 0, rimaste = 0
        var sommaPesata = 0.0, sommaPesi = 0.0, differenze = 0.0, misurate = 0
        var voci: [TrackRecord.Voce] = []
        voci.reserveCapacity(raccomandazioni.count)
        for r in raccomandazioni {
            let p = r.posizioneId.flatMap { perId[$0] }
            let inEssere = p?.stato == .inEssere
            var daAlmeno = false
            switch r.scelta {
            case .accettata:
                accettate += 1
                if let a = r.accettataIl ?? r.sceltaIl, a <= soglia {
                    daAlmeno = true
                    vecchie += 1
                    if inEssere { rimaste += 1 }
                }
            case .rifiutata: rifiutate += 1
            case .inAttesa: inAttesa += 1
            }
            let m = misura(r, posizione: p, tabella: tabella, oggi: oggi)
            if case .scarto(let s) = m {
                misurate += 1
                differenze += s.differenza
                if let punti = s.puntiAnnui, s.valoreAlternativa > 0 {
                    sommaPesata += punti * s.valoreAlternativa
                    sommaPesi += s.valoreAlternativa
                }
            }
            voci.append(TrackRecord.Voce(raccomandazione: r, posizione: p, daAlmeno12Mesi: daAlmeno, inEssere: inEssere, misura: m))
        }
        voci.sort { a, b in
            a.raccomandazione.data != b.raccomandazione.data ? a.raccomandazione.data > b.raccomandazione.data
                : a.raccomandazione.id < b.raccomandazione.id
        }
        let decise = accettate + rifiutate
        return TrackRecord(
            raccomandazioni: raccomandazioni.count, accettate: accettate, rifiutate: rifiutate, inAttesa: inAttesa,
            quotaAccettate: decise > 0 ? Double(accettate) / Double(decise) : nil,
            accettateDaAlmeno12Mesi: vecchie, inEssereDopo12Mesi: rimaste,
            quotaInEssereDopo12Mesi: vecchie > 0 ? Double(rimaste) / Double(vecchie) : nil,
            misurate: misurate, scartoMedioAnnuo: sommaPesi > 0 ? sommaPesata / sommaPesi : nil,
            differenzaTotale: misurate > 0 ? differenze : nil, stima: true,
            dal: raccomandazioni.map { cal.component(.year, from: $0.data) }.min(), voci: voci)
    }

    /// La misura di una raccomandazione con i valori aggiornati della sua posizione.
    static func misura(_ r: Raccomandazione, posizione p: Posizione?, tabella: TabellaRiferimenti, oggi: Date) -> TrackRecord.Misura {
        guard r.scelta == .accettata else { return .nonAccettata }
        guard let p else { return .posizioneAssente }
        guard let id = r.alternativa.serieRiferimento, tabella.serie(id) != nil else { return .senzaRiferimento }
        guard let flussi = MotoreResoconto.flussiDatati(p, data: oggi) else { return .pochiDati }
        let v = MotoreRiferimenti.versamenti(flussi, serie: id, tabella: tabella)
        if let anno = v.mancantiDal { return .riferimentoMancante(dal: anno) }
        guard let e = v.esito else { return .pochiDati }
        let punti: Double? = {
            guard let a = e.tassoEffettivo, let b = e.tassoRiferimento else { return nil }
            return a - b
        }()
        return .scarto(TrackRecord.Scarto(differenza: e.differenza, valoreEffettivo: e.valoreEffettivo,
                                          valoreAlternativa: e.valoreRiferimento, tassoEffettivo: e.tassoEffettivo,
                                          tassoAlternativa: e.tassoRiferimento, puntiAnnui: punti,
                                          anniStimati: e.stimati, stima: true))
    }

    // MARK: - La raccomandazione da registrare

    /// La frase della proposta: il nome con l'importo («Piano di risparmio da 450 € al mese»).
    static func titolo(_ p: Posizione) -> String {
        let nome = p.nome.trimmingCharacters(in: .whitespacesAndNewlines)
        if p.premio > 0 && p.frequenza != .unica {
            let ogni: String
            switch p.frequenza {
            case .mensile: ogni = "al mese"
            case .trimestrale: ogni = "al trimestre"
            case .semestrale: ogni = "al semestre"
            case .annuale, .unica: ogni = "all'anno"
            }
            return "\(nome) da \(CifreDoc.euro(p.premio)) \(ogni)"
        }
        if p.versamentoIniziale > 0 { return "\(nome) da \(CifreDoc.euro(p.versamentoIniziale))" }
        if let c = p.capitaleAssicurato, c > 0 { return "\(nome) da \(CifreDoc.euro(c)) di capitale" }
        return nome
    }

    /// Le cifre del momento: i dati della proposta e i controlli della scheda di adeguatezza, se calcolata.
    static func cifre(_ p: Posizione, adeguatezza: EsitoAdeguatezza?) -> CifreRaccomandazione {
        var righe: [RigaRaccomandazione] = []
        var ind: [String: Double] = [:]
        func riga(_ etichetta: String, _ valore: String) { righe.append(RigaRaccomandazione(etichetta: etichetta, valore: valore)) }
        riga("Canale", p.canale.nomeBreve)
        riga("Area", p.area.nome)
        if p.versamentoIniziale > 0 {
            riga("Versamento iniziale", CifreDoc.euro(p.versamentoIniziale))
            ind["versamentoIniziale"] = p.versamentoIniziale
        }
        if p.premio > 0 && p.frequenza != .unica {
            riga("Premio", "\(CifreDoc.euro(p.premio)) · \(p.frequenza.nome.lowercased())")
            ind["premio"] = p.premio
            ind["premioAnnuo"] = p.premioAnnuo
        }
        if let c = p.capitaleAssicurato, c > 0 {
            riga("Capitale assicurato", CifreDoc.euro(c))
            ind["capitaleAssicurato"] = c
        }
        if let r = p.rendimentoAtteso {
            riga("Rendimento atteso", CifreDoc.percento(r, decimali: 2))
            ind["rendimentoAtteso"] = r
        }
        if let c = p.costoIngresso {
            riga("Costo d'ingresso", CifreDoc.percento(c, decimali: 2))
            ind["costoIngresso"] = c
        }
        if let c = p.costoAnnuo {
            riga("Costo annuo", CifreDoc.percento(c, decimali: 2))
            ind["costoAnnuo"] = c
        }
        if let k = p.incidenzaCostiKID {
            riga("Incidenza dei costi (KID)", CifreDoc.percento(k, decimali: 2))
            ind["incidenzaCostiKID"] = k
        }
        if let s = p.sri {
            riga("Rischio (SRI)", "\(s) su 7")
            ind["sri"] = Double(s)
        }
        if let a = p.periodoRaccomandato {
            riga("Periodo raccomandato", a == 1 ? "1 anno" : "\(a) anni")
            ind["periodoRaccomandato"] = Double(a)
        }
        if let e = adeguatezza {
            riga("Adeguatezza", e.complessivo.nome)
            ind["adeguatezza.complessivo"] = Double(e.complessivo.urgenza)
            for c in e.controlli {
                riga(TestiAdeguatezza.titolo(c.tipo), "\(c.semaforo.nome) · \(c.esito)")
                if let v = c.valore { ind["adeguatezza.\(c.tipo.rawValue)"] = v }
            }
            if let l = e.liquiditaOggi { ind["liquiditaOggi"] = l }
            if let l = e.liquiditaResta { ind["liquiditaResta"] = l }
        }
        return CifreRaccomandazione(righe: righe, indicatori: ind)
    }

    /// L'alternativa ricavata da Prisma: se la proposta sostituisce una posizione, «lasciarla com'è» misurata con il
    /// metro di quella posizione; altrimenti lo stesso capitale al ritmo del metro della proposta (`MotoreRiferimenti.serieDi`).
    static func alternativa(_ p: Posizione, scheda: SchedaAdeguatezza?, posizioni: [Posizione],
                            riferimenti: RiferimentiRendimento, tabella: TabellaRiferimenti) -> AlternativaRaccomandazione {
        if let id = scheda?.posizioneSostituitaId, let s = posizioni.first(where: { $0.id == id }) {
            let serie = MotoreRiferimenti.serieDi(s, impostazioni: riferimenti, tabella: tabella).serie
            return AlternativaRaccomandazione(tipo: .lasciareComE, descrizione: "Lasciare «\(s.nome)» com'è",
                                              serieRiferimento: serie.id, posizioneSostituitaId: s.id, ricavata: true)
        }
        guard p.area.proiettabile else {
            return AlternativaRaccomandazione(tipo: .lasciareComE, descrizione: "Lasciare le cose come sono", ricavata: true)
        }
        let serie = MotoreRiferimenti.serieDi(p, impostazioni: riferimenti, tabella: tabella).serie
        return AlternativaRaccomandazione(tipo: .riferimento, descrizione: "Lo stesso capitale al ritmo di \(serie.nomeFrase)",
                                          serieRiferimento: serie.id, ricavata: true)
    }

    /// La raccomandazione da registrare quando la proposta viene presentata, con le cifre di quel momento.
    static func raccomandazione(per p: Posizione, adeguatezza: EsitoAdeguatezza?, scheda: SchedaAdeguatezza?,
                                posizioni: [Posizione], riferimenti: RiferimentiRendimento, data: Date) -> Raccomandazione {
        let tabella = TabellaRiferimenti(riferimenti)
        return Raccomandazione(
            id: "racc-\(p.id)", data: data, clienteId: p.clienteId, posizioneId: p.id, canale: p.canale, area: p.area,
            proposta: titolo(p), motivazione: scheda?.motivazione.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            cifre: cifre(p, adeguatezza: adeguatezza),
            alternativa: alternativa(p, scheda: scheda, posizioni: posizioni, riferimenti: riferimenti, tabella: tabella))
    }

    /// La scelta del cliente che corrisponde all'esito della proposta (nil per bozza e nessun esito).
    static func scelta(_ e: EsitoProposta?) -> SceltaCliente? {
        switch e {
        case .accettata?: return .accettata
        case .rifiutata?: return .rifiutata
        case .presentata?, .rimandata?: return .inAttesa
        case .bozza?, nil: return nil
        }
    }

    /// La proposta conta come presentata (presentata, accettata, rifiutata o rimandata).
    static func presentata(_ e: EsitoProposta?) -> Bool { scelta(e) != nil }
}
