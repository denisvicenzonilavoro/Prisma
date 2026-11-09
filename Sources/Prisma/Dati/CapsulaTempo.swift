import Foundation

// La capsula del tempo («Luce» giro 15, §3.4): un messaggio del cliente sigillato e cifrato fino al giorno giusto
// (un obiettivo raggiunto o una data). Il testo non è mai in chiaro nell'archivio: c'è solo il sigillo
// (`CifraturaBackup.cifra(_:chiave:uso:)` con una chiave a parte, `PortachiaviCapsule`, 15c). Sta nel file del cliente
// della cartella a pezzi e nei backup; mai in «Prisma ovunque» (decisione 44, D-C6).

struct CapsulaTempo: Identifiable, Codable, Hashable {
    /// Quando si apre.
    enum Apertura: Codable, Hashable {
        case obiettivo(id: String)
        case data(Date)
    }

    /// «pronta» non si salva: si calcola (`MotoreCapsule`, 15c).
    enum Stato: String, Codable {
        case sigillata, aperta, consegnata
    }

    /// "capsula-xxxxxxxx".
    var id: String
    var clienteId: String
    var apertura: Apertura
    /// Copia al sigillo (l'obiettivo può sparire).
    var titoloObiettivo: String?
    var sigillataIl: Date
    /// Il testo cifrato: mai il testo in chiaro.
    var sigillo: Data
    /// Quale chiave dell'anello di `PortachiaviCapsule`.
    var chiaveId: String
    var schemaSigillo: Int = 1
    var stato: Stato = .sigillata
    var apertaIl: Date?
    var consegnataIl: Date?
    /// Sigillata con la chiave di prova dichiarata (solo clienti di prova).
    var diProva: Bool?

    init(id: String = "capsula-\(UUID().uuidString.prefix(8).lowercased())", clienteId: String, apertura: Apertura,
         titoloObiettivo: String? = nil, sigillataIl: Date, sigillo: Data, chiaveId: String, schemaSigillo: Int = 1,
         stato: Stato = .sigillata, apertaIl: Date? = nil, consegnataIl: Date? = nil, diProva: Bool? = nil) {
        self.id = id
        self.clienteId = clienteId
        self.apertura = apertura
        self.titoloObiettivo = titoloObiettivo
        self.sigillataIl = sigillataIl
        self.sigillo = sigillo
        self.chiaveId = chiaveId
        self.schemaSigillo = schemaSigillo
        self.stato = stato
        self.apertaIl = apertaIl
        self.consegnataIl = consegnataIl
        self.diProva = diProva
    }

    private enum CodingKeys: String, CodingKey {
        case id, clienteId, apertura, titoloObiettivo, sigillataIl, sigillo, chiaveId, schemaSigillo, stato, apertaIl
        case consegnataIl, diProva
    }

    /// Lettura tollerante: id, cliente, apertura, data del sigillo, sigillo e chiave obbligatori (senza, la capsula si
    /// scarta); uno stato sconosciuto torna «sigillata» (mai aperta per sbaglio).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        apertura = try c.decode(Apertura.self, forKey: .apertura)
        titoloObiettivo = (try? c.decodeIfPresent(String.self, forKey: .titoloObiettivo)) ?? nil
        sigillataIl = try c.decode(Date.self, forKey: .sigillataIl)
        sigillo = try c.decode(Data.self, forKey: .sigillo)
        chiaveId = try c.decode(String.self, forKey: .chiaveId)
        schemaSigillo = ((try? c.decodeIfPresent(Int.self, forKey: .schemaSigillo)) ?? nil) ?? 1
        stato = ((try? c.decodeIfPresent(Stato.self, forKey: .stato)) ?? nil) ?? .sigillata
        apertaIl = (try? c.decodeIfPresent(Date.self, forKey: .apertaIl)) ?? nil
        consegnataIl = (try? c.decodeIfPresent(Date.self, forKey: .consegnataIl)) ?? nil
        diProva = (try? c.decodeIfPresent(Bool.self, forKey: .diProva)) ?? nil
    }
}
