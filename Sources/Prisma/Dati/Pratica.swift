import Foundation

// Le pratiche dopo la firma (Design/template-luce-specifica.md §7.3, «Luce» giro 3): quando una proposta viene accettata
// nasce la sua pratica, che segue i passi fino alla consegna al cliente. La pratica è la coda di una posizione:
// canale, cliente e prodotto vengono dalla posizione (Posizioni resta il fulcro).
// - Nell'archivio stanno solo i segni messi a mano dal consulente (`passi`): i passi che Prisma riconosce dai dati
//   (consegne della scheda di adeguatezza, documento d'identità, movimenti, numero di contratto, documento di polizza)
//   li calcola MotorePratiche ogni volta, mai salvati. Il segno a mano vince sempre, anche quando toglie un passo.
// - Archivio versione 27 (una sola per tutta Luce): `DatiPrisma.pratiche` e `Impostazioni.pratiche` letti con
//   tolleranza; una pratica senza id o senza posizione si scarta, le altre restano.
// - Niente dati sanitari nelle pratiche (D-P1): le note sono note di lavoro.

/// I passi di una pratica, nell'ordine. Le etichette cambiano col canale (D3.1).
enum PassoPratica: String, Codable, CaseIterable, Identifiable {
    case moduli, documentiInformativi, documentoIdentita, primoPremio, polizzaEmessa, consegnata

    var id: String { rawValue }

    /// Il nome del passo sulla linea e nel dettaglio.
    func etichetta(_ canale: Canale) -> String {
        switch (self, canale) {
        case (.moduli, _): return "Moduli completi"
        case (.documentiInformativi, _): return "Documenti informativi"
        case (.documentoIdentita, _): return "Documento d'identità"
        case (.primoPremio, .alleanza): return "Primo premio"
        case (.primoPremio, .indipendente): return "Primo versamento"
        case (.polizzaEmessa, .alleanza): return "Polizza emessa"
        case (.polizzaEmessa, .indipendente): return "Conferma dell'investimento"
        case (.consegnata, .alleanza): return "Consegnata al cliente"
        case (.consegnata, .indipendente): return "Consegnata"
        }
    }

    /// Il passo dipende dalla compagnia (o dalla società prodotto): il sollecito è «Sollecita la compagnia».
    var dipendeDallaCompagnia: Bool { self == .polizzaEmessa }
}

/// Un segno messo a mano dal consulente su un passo: fatto (con la data, oggi di base e modificabile) o tolto
/// (il passo non è fatto anche se Prisma lo riconoscerebbe dai dati).
struct SegnoPasso: Codable, Hashable {
    var fatto: Bool
    /// Quando è stato fatto (o quando è stato tolto).
    var il: Date
    var nota: String?

    init(fatto: Bool, il: Date, nota: String? = nil) {
        self.fatto = fatto
        self.il = il
        self.nota = nota
    }

    private enum CodingKeys: String, CodingKey { case fatto, il, nota }

    /// Lettura tollerante: senza data il segno non vale (si scarta il passo, non la pratica).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        il = try c.decode(Date.self, forKey: .il)
        fatto = (try? c.decodeIfPresent(Bool.self, forKey: .fatto)) ?? true
        nota = (try? c.decodeIfPresent(String.self, forKey: .nota)) ?? nil
    }
}

/// Una nota di lavoro della pratica, con la data (come le note del track record).
struct NotaPratica: Codable, Hashable {
    var data: Date
    var testo: String
}

/// Una pratica dopo la firma.
struct Pratica: Identifiable, Codable, Hashable {
    var id: String
    /// La posizione (la proposta accettata): canale, cliente e prodotto vengono da lì.
    var posizioneId: String
    /// La data dell'esito della proposta accettata (`SeguitoProposta.esitoIl`).
    var apertaIl: Date
    /// I segni a mano, per passo (`PassoPratica.rawValue`: niente dizionari con chiave enum). Le chiavi sconosciute
    /// (di un Prisma più nuovo) restano nell'archivio e il motore le ignora.
    var passi: [String: SegnoPasso] = [:]
    /// I passi che per questa pratica non servono (`PassoPratica.rawValue`): escono dalla linea e dal conteggio.
    var nonPertinenti: [String]?
    var note: [NotaPratica]?
    /// Quando è stata completata (lo scrive Prisma quando l'ultimo passo viene segnato; nil = dalle date dei passi).
    var conclusaIl: Date?
    /// L'occasione di Messaggi del sollecito preparato (`OccasioneMessaggio.id`): «✓ Sollecito pronto» finché il
    /// messaggio non è stato aperto in Mail o in Messaggi. Prisma non spedisce niente da solo.
    var sollecitoOccasioneId: String?

    init(id: String = "pratica-\(UUID().uuidString.prefix(8).lowercased())", posizioneId: String, apertaIl: Date) {
        self.id = id
        self.posizioneId = posizioneId
        self.apertaIl = apertaIl
    }

    /// Il segno a mano di un passo (nil = nessuno: vale il riconoscimento dai dati).
    func segno(_ p: PassoPratica) -> SegnoPasso? { passi[p.rawValue] }

    /// Il passo serve per questa pratica.
    func pertinente(_ p: PassoPratica) -> Bool { !(nonPertinenti ?? []).contains(p.rawValue) }

    /// Le pratiche dei dati di prova (`PraticheDiProva`): la scheda lo dice accanto al titolo.
    var diProva: Bool { id.hasPrefix(PraticheDiProva.prefisso) }

    private enum CodingKeys: String, CodingKey {
        case id, posizioneId, apertaIl, passi, nonPertinenti, note, conclusaIl, sollecitoOccasioneId
    }

    /// Lettura tollerante: senza id o posizione la pratica si scarta (ElencoTollerante tiene le altre); passi, note e
    /// date illeggibili diventano vuoti.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        posizioneId = try c.decode(String.self, forKey: .posizioneId)
        apertaIl = (try? c.decodeIfPresent(Date.self, forKey: .apertaIl)) ?? Date(timeIntervalSinceReferenceDate: 0)
        passi = Self.passiTolleranti(c)
        nonPertinenti = (try? c.decodeIfPresent([String].self, forKey: .nonPertinenti)) ?? nil
        note = ((try? c.decodeIfPresent(ElencoTollerante<NotaPratica>.self, forKey: .note)) ?? nil)?.elementi
        conclusaIl = (try? c.decodeIfPresent(Date.self, forKey: .conclusaIl)) ?? nil
        sollecitoOccasioneId = (try? c.decodeIfPresent(String.self, forKey: .sollecitoOccasioneId)) ?? nil
    }

    /// I segni passo per passo: uno illeggibile si salta, gli altri restano.
    private static func passiTolleranti(_ c: KeyedDecodingContainer<CodingKeys>) -> [String: SegnoPasso] {
        guard let dentro = try? c.nestedContainer(keyedBy: ChiaveLibera.self, forKey: .passi) else { return [:] }
        var esito: [String: SegnoPasso] = [:]
        for k in dentro.allKeys {
            if let s = try? dentro.decode(SegnoPasso.self, forKey: k) { esito[k.stringValue] = s }
        }
        return esito
    }

    private struct ChiaveLibera: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}

/// Le scelte del consulente sulle pratiche (Impostazioni › Pratiche, versione 27, lette con tolleranza).
struct ImpostazioniPratiche: Codable, Equatable, Hashable {
    /// Oltre quanti giorni senza un passo nuovo una pratica è «ferma» (D3.2: 7, ferma all'ottavo giorno).
    var giorniFerma = ImpostazioniPratiche.giorniFermaPredefiniti
    /// «Conserva l'IBAN nel dossier» (Impostazioni › Moduli, «Luce» giro 10, decisione 40): spento di base. Spento, gli
    /// IBAN non si salvano nell'anagrafica (si scrivono solo sul modulo compilato).
    var conservaIban: Bool?

    static let giorniFermaPredefiniti = 7
    /// I limiti del campo in Impostazioni (vuoto non ammesso: almeno un giorno).
    static let giorniFermaMinimi = 1
    static let giorniFermaMassimi = 90

    init() {}

    private enum CodingKeys: String, CodingKey { case giorniFerma, conservaIban }

    /// Illeggibile, minore di 1 o fuori misura: torna 7.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let g = (try? c.decodeIfPresent(Int.self, forKey: .giorniFerma)) ?? nil
        giorniFerma = g.flatMap { (Self.giorniFermaMinimi...Self.giorniFermaMassimi).contains($0) ? $0 : nil }
            ?? Self.giorniFermaPredefiniti
        conservaIban = (try? c.decodeIfPresent(Bool.self, forKey: .conservaIban)) ?? nil
    }

    /// L'interruttore dell'IBAN acceso.
    var ibanConservato: Bool { conservaIban == true }
}
