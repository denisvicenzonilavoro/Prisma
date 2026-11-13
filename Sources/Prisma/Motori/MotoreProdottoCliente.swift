import Foundation

/// «Il prodotto sul cliente» (12 novembre 2026): dal catalogo al cliente in un passo, per Alleanza e per la consulenza
/// indipendente. Tutto quello che sta nella scheda prodotto (nome, canale, area, compagnia, costi, rendimento, rischio,
/// garanzie, condizioni, gestione separata e fondi) entra da sé con `Prodotto.proposta(per:)`; si scrivono solo i pochi
/// dati del cliente, che dipendono dal tipo di prodotto (`campi`). Il resto si completa, se serve, nel modulo intero.
/// Solo codice: nessuna cifra inventata, i valori che il consulente non scrive restano vuoti.
enum MotoreProdottoCliente {
    /// I dati del cliente che si scrivono mettendo un prodotto sul cliente.
    enum Campo: String, CaseIterable, Identifiable {
        /// Premio unico o versamento iniziale (per la previdenza: trasferimento da un'altra forma).
        case versamentoIniziale
        /// Premio o versamento periodico, con la frequenza.
        case premio
        /// Durata in anni (la scadenza si ricava dalla decorrenza).
        case durata
        case decorrenza
        /// Solo per una posizione in essere: il valore di oggi.
        case controvalore
        /// Protezione: il capitale assicurato.
        case capitaleAssicurato
        /// Previdenza: TFR conferito ogni anno e contributo del datore di lavoro.
        case tfr
        case contributoDatore
        /// Solo per una posizione in essere: il numero di polizza o di contratto.
        case numeroContratto

        var id: String { rawValue }
    }

    /// I valori che il consulente scrive per il cliente.
    struct Valori: Equatable {
        var stato: StatoPosizione = .proposta
        var versamentoIniziale: Double = 0
        var premio: Double = 0
        var frequenza: Frequenza = .unica
        /// Durata in anni; nil = senza scadenza.
        var anni: Int?
        var decorrenza = Date()
        var controvalore: Double?
        var capitaleAssicurato: Double?
        var tfr: Double?
        var contributoDatore: Double?
        var numeroContratto = ""
    }

    /// Età della pensione usata per proporre la durata di un piano previdenziale (si cambia nel modulo).
    static let etaPensione = 67

    /// I campi del cliente per questo prodotto, nell'ordine in cui si scrivono: i primi due o tre sono quelli
    /// che contano davvero, gli altri compaiono solo dove servono (in essere, previdenza, protezione).
    static func campi(per p: Prodotto, stato: StatoPosizione) -> [Campo] {
        var elenco: [Campo]
        switch p.area {
        case .protezione:
            elenco = [.capitaleAssicurato, .premio, .durata, .decorrenza]
        case .previdenza:
            elenco = [.premio, .versamentoIniziale, .durata, .decorrenza, .tfr, .contributoDatore]
        case .liquidita, .immobili:
            elenco = [.versamentoIniziale, .decorrenza]
        case .debiti:
            elenco = [.versamentoIniziale, .premio, .durata, .decorrenza]
        case .investimento, .risparmio:
            elenco = [.versamentoIniziale, .premio, .durata, .decorrenza]
        }
        if stato == .inEssere {
            if p.area != .protezione { elenco.insert(.controvalore, at: min(2, elenco.count)) }
            elenco.append(.numeroContratto)
        }
        return elenco
    }

    /// I valori proposti all'apertura: frequenza e durata tipiche del prodotto, mai importi.
    /// Piano di risparmio e previdenza mensili, protezione annuale; durata dal periodo raccomandato del KID o,
    /// per la previdenza, fino alla pensione del cliente.
    static func valoriIniziali(per p: Prodotto, cliente: Cliente?, stato: StatoPosizione = .proposta,
                               oggi: Date = Date()) -> Valori {
        var v = Valori()
        v.stato = stato
        v.decorrenza = oggi
        let testo = (p.nome + " " + p.tipologia).lowercased()
        let ricorrente = ["piano", "pac", "risparmio", "ricorrent", "periodic"].contains { testo.contains($0) }
        switch p.area {
        case .previdenza:
            v.frequenza = .mensile
            if let eta = cliente?.eta, eta < etaPensione { v.anni = etaPensione - eta } else { v.anni = p.periodoConsigliato }
        case .protezione:
            v.frequenza = .annuale
            v.anni = p.periodoConsigliato ?? 10
        case .risparmio:
            v.frequenza = .mensile
            v.anni = p.periodoConsigliato
        default:
            v.frequenza = ricorrente ? .mensile : .unica
            v.anni = p.periodoConsigliato
        }
        return v
    }

    /// Che cosa manca perché la posizione abbia senso (nil = si può aggiungere).
    static func mancante(_ v: Valori, per p: Prodotto) -> String? {
        switch p.area {
        case .protezione:
            if (v.capitaleAssicurato ?? 0) <= 0 && v.premio <= 0 && v.versamentoIniziale <= 0 {
                return "Scrivi il capitale assicurato o il premio"
            }
        case .liquidita, .immobili:
            if v.versamentoIniziale <= 0 && (v.controvalore ?? 0) <= 0 { return "Scrivi l'importo" }
        default:
            let periodico = v.frequenza != .unica && v.premio > 0
            if v.versamentoIniziale <= 0 && !periodico && (v.controvalore ?? 0) <= 0 {
                return "Scrivi il premio unico o il versamento periodico"
            }
        }
        if let anni = v.anni, anni <= 0 { return "La durata deve essere di almeno un anno" }
        return nil
    }

    /// La posizione del cliente: le condizioni della scheda (`proposta(per:)`) più i dati del cliente.
    /// In essere: niente esito, il valore di oggi e il totale versato se si sa; proposta: in bozza.
    static func posizione(da p: Prodotto, clienteId: String, valori v: Valori) -> Posizione {
        var pos = p.proposta(per: clienteId)
        // Al secondo, come l'archivio e «Prisma ovunque»: la posizione arriva sul Mac identica
        pos.creataIl = Posizione.oggiArrotondato
        pos.stato = v.stato
        pos.esito = v.stato == .proposta ? .bozza : nil
        // Il premio periodico conta solo con una frequenza; con «unica» il periodico è zero
        pos.frequenza = v.premio > 0 ? (v.frequenza == .unica ? .annuale : v.frequenza) : .unica
        pos.premio = v.premio > 0 ? v.premio : 0
        pos.versamentoIniziale = max(0, v.versamentoIniziale)
        pos.decorrenza = v.decorrenza
        if let anni = v.anni, anni > 0 {
            pos.scadenza = Calendar.current.date(byAdding: .year, value: anni, to: v.decorrenza)
        } else {
            pos.scadenza = nil
        }
        if p.area == .protezione { pos.capitaleAssicurato = v.capitaleAssicurato.flatMap { $0 > 0 ? $0 : nil } }
        if p.area == .previdenza {
            pos.tfrConferito = v.tfr.flatMap { $0 > 0 ? $0 : nil }
            pos.contributoDatore = v.contributoDatore.flatMap { $0 > 0 ? $0 : nil }
            if v.stato != .proposta { pos.primaAdesione = v.decorrenza }
        }
        if v.stato == .inEssere {
            pos.numeroContratto = v.numeroContratto.trimmingCharacters(in: .whitespacesAndNewlines)
            if let c = v.controvalore, c > 0 {
                pos.controvalore = c
                pos.dataValore = Calendar.current.startOfDay(for: Date())
            }
        }
        // Liquidità e immobili non hanno flussi: l'importo è il valore
        if p.area == .liquidita || p.area == .immobili {
            if pos.controvalore == nil, pos.versamentoIniziale > 0 { pos.controvalore = pos.versamentoIniziale }
        }
        return pos
    }
}
