import Foundation

// Le pratiche dopo la firma (Design/template-luce-specifica.md §7.3, «Luce» giro 3): a che punto è ogni pratica.
// Motore puro, senza stato: le stesse pratiche e gli stessi dati danno sempre lo stesso risultato.
// - I passi (`PassoPratica`, etichette per canale D3.1): fatto se c'è un segno a mano «fatto», oppure, senza segno, se
//   Prisma lo riconosce dai dati. Il segno a mano vince sempre, anche quando toglie un passo riconosciuto.
//   Riconoscimenti (solo dati registrati, mai simulati):
//   · Moduli completi: solo a mano (il riconoscimento arriva con Compila da solo, §7.2);
//   · Documenti informativi: la scheda di adeguatezza della posizione con tutti i documenti del canale consegnati o non
//     pertinenti (come `MotoreAdeguatezza.documenti`); data = l'ultima consegna;
//   · Documento d'identità: un documento del cliente della categoria «Documenti d'identità» (data = importazione)
//     oppure il documento d'identità di Conformità con la scadenza dopo oggi (senza data: era già valido);
//   · Primo premio / Primo versamento: un movimento positivo della posizione dal giorno di apertura; data = il movimento;
//   · Polizza emessa / Conferma dell'investimento: un documento di polizza della posizione importato dal giorno di
//     apertura (data = importazione), oppure il numero di contratto scritto nella posizione (senza data: Prisma non sa
//     quando è arrivato e non la inventa);
//   · Consegnata: solo a mano (la presa visione al Tavolo non resta registrata).
// - Passi non pertinenti (`Pratica.nonPertinenti`): escono dalla linea e dal conteggio.
// - Ferma: il riferimento è l'ultima data nota (l'apertura o il passo fatto più recente, mai prima dell'apertura);
//   ferma se da quel giorno sono passati PIÙ di `giorniFerma` giorni di calendario (soglia 7: ferma all'ottavo).
// - Ordine: le ferme in testa (da più giorni), poi le aperte dal passo più indietro, poi le concluse (più recenti prima).
// - Una pratica la cui posizione non esiste più si salta (nessun crash, nessuna riga vuota).

/// Lo stato di un passo sulla linea.
enum StatoPasso: Hashable {
    /// Fatto (verde).
    case fatto
    /// Il primo passo non fatto di una pratica che va avanti (blu).
    case adesso
    /// Il primo passo non fatto di una pratica ferma (rosso).
    case bloccato
    /// Dopo il passo di adesso (grigio).
    case futuro
}

/// Da dove viene lo stato di un passo.
enum OriginePasso: Hashable {
    /// Nessun segno e nessun dato: da fare.
    case nessuna
    /// Segnato fatto a mano.
    case aMano
    /// Tolto a mano (non fatto anche se i dati lo direbbero). `riconoscibile`: cosa avrebbe riconosciuto Prisma.
    case toltoAMano(riconoscibile: String?)
    /// Riconosciuto da Prisma dai dati: «dalla scheda di adeguatezza», «dal numero di contratto»…
    case riconosciuto(da: String)
}

/// Un passo calcolato.
struct PassoCalcolato: Identifiable, Hashable {
    let passo: PassoPratica
    let etichetta: String
    let stato: StatoPasso
    /// La data del passo fatto (nil se non fatto o se la data non si conosce, come per il numero di contratto);
    /// per un passo tolto a mano, quando è stato tolto.
    let data: Date?
    let origine: OriginePasso
    /// La nota del segno a mano, se c'è.
    let nota: String?

    var id: String { passo.rawValue }
    var fatto: Bool { stato == .fatto }
}

/// A che punto è una pratica.
struct StatoPratica: Identifiable {
    let pratica: Pratica
    let posizione: Posizione
    let passi: [PassoCalcolato]
    let fatti: Int
    /// I passi pertinenti del canale.
    let totale: Int
    /// Giorni di calendario dall'ultima data nota a oggi.
    let giorniFermo: Int
    let ferma: Bool
    let conclusa: Bool
    /// Quando è stata completata (dalla pratica o dall'ultimo passo datato); nil se non conclusa o senza date.
    let conclusaIl: Date?
    /// Il primo passo pertinente non fatto (nil se conclusa).
    let mancante: PassoPratica?
    /// La riga sotto lo stato: «Emissione in corso presso la compagnia», «Fermo da 9 giorni: manca il primo premio»…
    let nota: String

    var id: String { pratica.id }
    var canale: Canale { posizione.canale }
    var clienteId: String { posizione.clienteId }
    /// «4 di 6» o «✓ Completata».
    var testoStato: String { TestiPratiche.stato(fatti: fatti, totale: totale, conclusa: conclusa) }
    /// Il sollecito va alla compagnia (manca l'emissione o la conferma dell'investimento).
    var sollecitoCompagnia: Bool { mancante?.dipendeDallaCompagnia ?? false }
    /// L'indice del passo di adesso nell'ordine dei passi (6 se conclusa): per l'ordinamento.
    var indiceAdesso: Int { mancante.flatMap { PassoPratica.allCases.firstIndex(of: $0) } ?? PassoPratica.allCases.count }
}

/// Le tre tile in alto.
struct RiepilogoPratiche: Equatable {
    let aperte: Int
    let ferme: Int
    let concluseMeseScorso: Int
    /// Il nome del mese scorso, minuscolo: «ottobre».
    let meseScorso: String
    /// La soglia della seconda tile («Ferme da più di 7 giorni»).
    let soglia: Int
}

enum MotorePratiche {
    // MARK: - Indici (una volta sola per tutte le pratiche: tempo lineare anche con 200 clienti)

    /// I dati che servono al riconoscimento, indicizzati una volta per tutte le pratiche.
    struct Indici {
        let posizioni: [String: Posizione]
        let clienti: [String: Cliente]
        let schede: [String: SchedaAdeguatezza]
        /// Documenti di polizza per posizione.
        let polizze: [String: [Documento]]
        /// Documenti d'identità per cliente.
        let identita: [String: [Documento]]
        let voci: [VoceDocumento]
        let prodotti: [Prodotto]

        init(_ dati: DatiPrisma) {
            posizioni = Dictionary(dati.posizioni.map { ($0.id, $0) }, uniquingKeysWith: { primo, _ in primo })
            clienti = Dictionary(dati.clienti.map { ($0.id, $0) }, uniquingKeysWith: { primo, _ in primo })
            schede = Dictionary(dati.schedeAdeguatezza.map { ($0.posizioneId, $0) }, uniquingKeysWith: { primo, _ in primo })
            var pol: [String: [Documento]] = [:]
            var ide: [String: [Documento]] = [:]
            for d in dati.documenti {
                if d.tipo == .polizza, let p = d.posizioneId { pol[p, default: []].append(d) }
                if d.genere == .identita { ide[d.clienteId, default: []].append(d) }
            }
            polizze = pol
            identita = ide
            voci = dati.impostazioni.consegna.voci
            prodotti = dati.prodotti
        }
    }

    // MARK: - Tutte le pratiche

    /// Lo stato di ogni pratica dei dati (le pratiche senza posizione si saltano), nell'ordine della scheda.
    static func stati(_ dati: DatiPrisma, oggi: Date = Date(), calendario: Calendar = .current) -> [StatoPratica] {
        guard !dati.pratiche.isEmpty else { return [] }
        let indici = Indici(dati)
        let soglia = dati.impostazioni.pratiche.giorniFerma
        return ordina(dati.pratiche.compactMap { stato($0, indici: indici, soglia: soglia, oggi: oggi, calendario: calendario) })
    }

    /// Lo stato di una pratica (nil se la sua posizione non c'è più).
    static func stato(_ p: Pratica, dati: DatiPrisma, oggi: Date = Date(), calendario: Calendar = .current) -> StatoPratica? {
        stato(p, indici: Indici(dati), soglia: dati.impostazioni.pratiche.giorniFerma, oggi: oggi, calendario: calendario)
    }

    static func stato(_ p: Pratica, indici: Indici, soglia: Int, oggi: Date, calendario: Calendar) -> StatoPratica? {
        guard let pos = indici.posizioni[p.posizioneId] else { return nil }
        let canale = pos.canale
        let apertura = calendario.startOfDay(for: p.apertaIl)
        // 1. Fatto o no, con la data e l'origine
        var grezzi: [(passo: PassoPratica, fatto: Bool, data: Date?, origine: OriginePasso, nota: String?)] = []
        for passo in PassoPratica.allCases where p.pertinente(passo) {
            let dato = riconosciuto(passo, pratica: p, posizione: pos, apertura: apertura, indici: indici,
                                    oggi: oggi, calendario: calendario)
            if let s = p.segno(passo) {
                grezzi.append(s.fatto ? (passo, true, s.il, .aMano, s.nota)
                                      : (passo, false, s.il, .toltoAMano(riconoscibile: dato?.da), s.nota))
            } else if let dato {
                grezzi.append((passo, true, dato.data, .riconosciuto(da: dato.da), nil))
            } else {
                grezzi.append((passo, false, nil, .nessuna, nil))
            }
        }
        // 2. Conteggi, ferma, conclusa
        let fatti = grezzi.filter(\.fatto).count
        let totale = grezzi.count
        let conclusa = fatti == totale
        let ultimaFatta = grezzi.filter(\.fatto).compactMap(\.data).max()
        let riferimento = max(apertura, ultimaFatta.map { calendario.startOfDay(for: $0) } ?? apertura)
        let giorni = max(0, calendario.dateComponents([.day], from: riferimento, to: calendario.startOfDay(for: oggi)).day ?? 0)
        let ferma = !conclusa && giorni > soglia
        let mancante = grezzi.first { !$0.fatto }?.passo
        // 3. Stato di ogni passo sulla linea
        var visto = false
        let passi = grezzi.map { g -> PassoCalcolato in
            let s: StatoPasso
            if g.fatto {
                s = .fatto
            } else if !visto {
                visto = true
                s = ferma ? .bloccato : .adesso
            } else {
                s = .futuro
            }
            return PassoCalcolato(passo: g.passo, etichetta: g.passo.etichetta(canale), stato: s,
                                  data: g.data, origine: g.origine, nota: g.nota)
        }
        let conclusaIl = conclusa ? (p.conclusaIl ?? ultimaFatta) : nil
        let nota = TestiPratiche.nota(conclusa: conclusa, conclusaIl: conclusaIl, ferma: ferma, giorni: giorni,
                                      mancante: mancante, canale: canale)
        return StatoPratica(pratica: p, posizione: pos, passi: passi, fatti: fatti, totale: totale, giorniFermo: giorni,
                            ferma: ferma, conclusa: conclusa, conclusaIl: conclusaIl, mancante: mancante, nota: nota)
    }

    // MARK: - Riconoscimento dai dati

    /// Il passo riconosciuto dai dati: la data (nil se non si conosce) e da cosa. nil = i dati non lo dicono.
    static func riconosciuto(_ passo: PassoPratica, pratica p: Pratica, posizione pos: Posizione, apertura: Date,
                             indici: Indici, oggi: Date, calendario: Calendar) -> (data: Date?, da: String)? {
        switch passo {
        case .moduli, .consegnata:
            return nil
        case .documentiInformativi:
            guard let s = indici.schede[pos.id] else { return nil }
            let sostituzione = s.posizioneSostituitaId.flatMap { indici.posizioni[$0] }.map { $0.stato == .inEssere } ?? false
            let tipo = MotoreEsperienza.classifica(pos, prodotti: indici.prodotti)?.tipo
            let voci = MotoreAdeguatezza.documenti(pos, voci: indici.voci, tipo: tipo, sostituzione: sostituzione)
            let date = voci.compactMap { s.consegnato($0.id) }
            guard !voci.isEmpty, !date.isEmpty,
                  voci.allSatisfy({ s.consegnato($0.id) != nil || s.nonPertinenti.contains($0.id) }) else { return nil }
            return (date.max(), TestiPratiche.daScheda)
        case .documentoIdentita:
            if let d = indici.identita[pos.clienteId]?.max(by: { $0.importatoIl < $1.importatoIl }) {
                return (d.importatoIl, TestiPratiche.daDocumento(d.titolo))
            }
            if let scade = indici.clienti[pos.clienteId]?.conformita?.documento?.scadenza,
               calendario.startOfDay(for: scade) > calendario.startOfDay(for: oggi) {
                return (nil, TestiPratiche.daConformita)
            }
            return nil
        case .primoPremio:
            guard let m = (pos.movimenti ?? []).filter({ $0.importo > 0 && $0.data >= apertura })
                .min(by: { $0.data < $1.data }) else { return nil }
            return (m.data, TestiPratiche.daMovimento(m.data))
        case .polizzaEmessa:
            if let d = (indici.polizze[pos.id] ?? []).filter({ $0.importatoIl >= apertura })
                .min(by: { $0.importatoIl < $1.importatoIl }) {
                return (d.importatoIl, TestiPratiche.daDocumento(d.titolo))
            }
            if !pos.numeroContratto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return (nil, TestiPratiche.daNumeroContratto)
            }
            return nil
        }
    }

    // MARK: - Riepilogo e ordine

    /// Le tre tile: aperte, ferme, concluse nel mese di calendario prima di oggi (gennaio → dicembre dell'anno prima).
    static func riepilogo(_ stati: [StatoPratica], soglia: Int, oggi: Date = Date(),
                          calendario: Calendar = .current) -> RiepilogoPratiche {
        let scorso = meseScorso(oggi, calendario: calendario)
        let concluse = stati.filter { s in
            guard s.conclusa, let d = s.conclusaIl else { return false }
            return scorso.contains(d)
        }.count
        let aperte = stati.filter { !$0.conclusa }
        return RiepilogoPratiche(aperte: aperte.count, ferme: aperte.filter(\.ferma).count, concluseMeseScorso: concluse,
                                 meseScorso: TestiPratiche.nomeMese(scorso.start, calendario: calendario), soglia: soglia)
    }

    /// Il mese di calendario prima di quello di `oggi`.
    static func meseScorso(_ oggi: Date, calendario: Calendar = .current) -> DateInterval {
        let questo = calendario.dateInterval(of: .month, for: oggi) ?? DateInterval(start: oggi, duration: 0)
        let prima = calendario.date(byAdding: .day, value: -1, to: questo.start) ?? questo.start
        return calendario.dateInterval(of: .month, for: prima) ?? questo
    }

    /// Le concluse del mese scorso (la sezione in fondo).
    static func concluseMeseScorso(_ stati: [StatoPratica], oggi: Date = Date(), calendario: Calendar = .current) -> [StatoPratica] {
        let scorso = meseScorso(oggi, calendario: calendario)
        return stati.filter { s in s.conclusa && s.conclusaIl.map { scorso.contains($0) } == true }
    }

    /// Ferme in testa (da più giorni), poi le aperte dal passo più indietro, poi le concluse (le più recenti prima).
    static func ordina(_ stati: [StatoPratica]) -> [StatoPratica] {
        func gruppo(_ s: StatoPratica) -> Int { s.conclusa ? 2 : (s.ferma ? 0 : 1) }
        return stati.sorted { a, b in
            let ga = gruppo(a), gb = gruppo(b)
            if ga != gb { return ga < gb }
            switch ga {
            case 0:
                if a.giorniFermo != b.giorniFermo { return a.giorniFermo > b.giorniFermo }
            case 1:
                if a.indiceAdesso != b.indiceAdesso { return a.indiceAdesso < b.indiceAdesso }
                if a.giorniFermo != b.giorniFermo { return a.giorniFermo > b.giorniFermo }
            default:
                let da = a.conclusaIl ?? .distantPast, db = b.conclusaIl ?? .distantPast
                if da != db { return da > db }
            }
            return a.pratica.id < b.pratica.id
        }
    }

    // MARK: - Segni a mano

    /// Segna o toglie un passo a mano (il segno a mano vince sul riconoscimento). Se con questo segno la pratica è
    /// completa, `conclusaIl` prende la data; se non lo è più, la perde.
    static func segna(_ passo: PassoPratica, fatto: Bool, il data: Date, pratica p: inout Pratica, dati: DatiPrisma,
                      oggi: Date = Date(), calendario: Calendar = .current) {
        p.passi[passo.rawValue] = SegnoPasso(fatto: fatto, il: data)
        aggiornaConclusione(&p, dati: dati, il: data, oggi: oggi, calendario: calendario)
    }

    /// Toglie il segno a mano: torna a valere il riconoscimento dai dati.
    static func togliSegno(_ passo: PassoPratica, pratica p: inout Pratica, dati: DatiPrisma,
                           oggi: Date = Date(), calendario: Calendar = .current) {
        p.passi[passo.rawValue] = nil
        aggiornaConclusione(&p, dati: dati, il: oggi, oggi: oggi, calendario: calendario)
    }

    private static func aggiornaConclusione(_ p: inout Pratica, dati: DatiPrisma, il data: Date, oggi: Date, calendario: Calendar) {
        guard let s = stato(p, dati: dati, oggi: oggi, calendario: calendario) else { return }
        if s.conclusa {
            if p.conclusaIl == nil { p.conclusaIl = data }
        } else {
            p.conclusaIl = nil
        }
    }

    /// Una pratica nuova per una proposta appena accettata (nil se la posizione ne ha già una).
    static func nuova(per posizione: Posizione, esistenti: [Pratica], il data: Date) -> Pratica? {
        guard posizione.esito == .accettata, !esistenti.contains(where: { $0.posizioneId == posizione.id }) else { return nil }
        return Pratica(posizioneId: posizione.id, apertaIl: data)
    }

    // MARK: - Sollecito (Messaggi)

    /// L'occasione di Messaggi per sollecitare il passo che manca (nil se la pratica è conclusa). Una per pratica e
    /// passo: il riferimento è «<pratica>-<passo>». Le cifre sono solo fatti della pratica (posizione, passo, giorni).
    static func occasioneSollecito(_ s: StatoPratica, oggi: Date) -> OccasioneMessaggio? {
        guard let passo = s.mancante else { return nil }
        let nome = s.posizione.nome
        var cifre = [CifraMessaggio(.posizione, nome),
                     CifraMessaggio(.passoPratica, TestiPratiche.cosa(passo, canale: s.canale)),
                     CifraMessaggio(.canale, s.canale.nome)]
        if s.ferma { cifre.append(CifraMessaggio(.giorniPratica, "\(s.giorniFermo)")) }
        let perche = s.ferma ? TestiPratiche.fermoDa(s.giorniFermo) + ": " + TestiPratiche.manca(passo, canale: s.canale)
                             : TestiPratiche.adesso(passo, canale: s.canale)
        return OccasioneMessaggio(origine: OrigineMessaggio(tipo: .pratica, riferimento: "\(s.pratica.id)-\(passo.rawValue)"),
                                  clienteId: s.clienteId, canale: s.canale, gruppo: .oggi,
                                  titolo: (passo.dipendeDallaCompagnia ? "Sollecito alla compagnia: " : "Sollecito: ") + "«\(nome)»",
                                  perche: perche,
                                  oggetto: "La pratica di «\(nome)»",
                                  cifre: cifre, priorita: s.ferma ? .alta : .media, data: oggi, inRitardo: s.ferma)
    }
}

/// Le frasi delle pratiche. Quelle del template: «Emissione in corso presso la compagnia», «Fermo da 9 giorni: manca il
/// primo premio», «Completata il 28 ottobre»; le altre sono nel tono del template (dichiarate nel resoconto del giro).
enum TestiPratiche {
    static let daScheda = "dalla scheda di adeguatezza (documenti consegnati)"
    static let daConformita = "dal documento d'identità valido in Conformità"
    static let daNumeroContratto = "dal numero di contratto"
    static func daDocumento(_ titolo: String) -> String { "dal documento «\(titolo)»" }
    static func daMovimento(_ data: Date) -> String { "dal versamento del \(Formati.giornoMese.string(from: data))" }

    static func stato(fatti: Int, totale: Int, conclusa: Bool) -> String {
        conclusa ? "✓ Completata" : "\(fatti) di \(totale)"
    }

    static func fermoDa(_ giorni: Int) -> String { giorni == 1 ? "Fermo da 1 giorno" : "Fermo da \(giorni) giorni" }

    /// Il passo con l'articolo, per le frasi: «il primo premio», «l'emissione della polizza».
    static func cosa(_ p: PassoPratica, canale: Canale) -> String {
        switch (p, canale) {
        case (.moduli, _): return "i moduli completi"
        case (.documentiInformativi, _): return "i documenti informativi"
        case (.documentoIdentita, _): return "il documento d'identità"
        case (.primoPremio, .alleanza): return "il primo premio"
        case (.primoPremio, .indipendente): return "il primo versamento"
        case (.polizzaEmessa, .alleanza): return "l'emissione della polizza"
        case (.polizzaEmessa, .indipendente): return "la conferma dell'investimento"
        case (.consegnata, _): return "la consegna al cliente"
        }
    }

    /// «manca il primo premio», «mancano i documenti informativi».
    static func manca(_ p: PassoPratica, canale: Canale) -> String {
        let plurale = p == .moduli || p == .documentiInformativi
        return (plurale ? "mancano " : "manca ") + cosa(p, canale: canale)
    }

    /// La riga di una pratica che va avanti, dal passo di adesso.
    static func adesso(_ p: PassoPratica, canale: Canale) -> String {
        switch (p, canale) {
        case (.moduli, _): return "Moduli da completare"
        case (.documentiInformativi, _): return "Documenti informativi da consegnare"
        case (.documentoIdentita, _): return "Documento d'identità da raccogliere"
        case (.primoPremio, .alleanza): return "In attesa del primo premio"
        case (.primoPremio, .indipendente): return "In attesa del primo versamento"
        case (.polizzaEmessa, .alleanza): return "Emissione in corso presso la compagnia"
        case (.polizzaEmessa, .indipendente): return "Conferma dell'investimento in corso"
        case (.consegnata, _): return "Da consegnare al cliente"
        }
    }

    static func nota(conclusa: Bool, conclusaIl: Date?, ferma: Bool, giorni: Int, mancante: PassoPratica?,
                     canale: Canale) -> String {
        if conclusa { return conclusaIl.map { "Completata il \(Formati.giornoMese.string(from: $0))" } ?? "Completata" }
        guard let m = mancante else { return "" }
        return ferma ? fermoDa(giorni) + ": " + manca(m, canale: canale) : adesso(m, canale: canale)
    }

    /// «ottobre».
    static func nomeMese(_ data: Date, calendario: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = Formati.italiano
        f.calendar = calendario
        f.timeZone = calendario.timeZone
        f.dateFormat = "MMMM"
        return f.string(from: data).lowercased()
    }

    /// Le tre tile.
    static let tileAperte = "Pratiche aperte"
    static func tileFerme(_ soglia: Int) -> String { soglia == 1 ? "Ferme da più di 1 giorno" : "Ferme da più di \(soglia) giorni" }
    static func tileConcluse(_ mese: String) -> String { "Concluse a \(mese)" }

    /// Stati vuoti.
    static let nessuna = "Nessuna pratica aperta. Una pratica nasce quando una proposta viene firmata."
    /// Sull'iPhone senza il giornale di «Prisma ovunque» che scrive (§7.3.4).
    static let solaLetturaTelefono = "sola lettura: i passi si segnano dal Mac, o da qui se sul Mac è acceso «Lavora anche con il Mac spento»"
    static let tuttoInOrdine = "Tutto in ordine"

    /// Il passo nel dettaglio: «Fatto il 3 novembre · segnato a mano», «Fatto · riconosciuto dal numero di contratto».
    static func dettaglio(_ p: PassoCalcolato) -> String {
        func il(_ d: Date?) -> String { d.map { " il \(Formati.giornoMese.string(from: $0))" } ?? "" }
        switch p.origine {
        case .nessuna: return "Da fare"
        case .aMano: return "Fatto\(il(p.data)) · segnato a mano"
        case .riconosciuto(let da): return "Fatto\(il(p.data)) · riconosciuto \(da)"
        case .toltoAMano(let r):
            return "Tolto a mano\(il(p.data))" + (r.map { " · Prisma lo riconoscerebbe \($0)" } ?? "")
        }
    }

    /// La notifica interna delle pratiche ferme.
    static func titoloNotifica(_ ferme: [StatoPratica]) -> String {
        guard let prima = ferme.first else { return "" }
        return ferme.count == 1 ? "Pratica ferma da \(prima.giorniFermo) giorni · \(prima.posizione.nome)"
                                : "\(ferme.count) pratiche ferme"
    }
}
