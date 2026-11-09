import Foundation

// Il Prisma del cliente («Luce» giro 15, §2.1): che cosa è uscito l'ultima volta nel file del cliente. Sta nel cliente
// (`Cliente.prismaCliente`, versione 27, letto con `decodeIfPresent`), nei backup e in «Prisma ovunque» (solo date e
// voci, nessun contenuto). Mai la password, mai il contenuto del file.

/// Che cosa è uscito l'ultima volta nel file del cliente (mai la password, mai il contenuto).
struct StatoPrismaCliente: Codable, Hashable {
    var ultimoFile: Date?
    var validoFinoAl: Date?
    /// Le voci del file (`VoceFilePrisma.rawValue`, 15a), ordinate.
    var contenuti: [String] = []
    /// Le voci aggiunte dalla Sala dopo l'ultimo file («nuova dall'ultimo file»).
    var aggiunteDopoUltimoFile: [String] = []
    /// SHA256 dei dati del film esportato (15b: «il piano è cambiato»).
    var filmImpronta: String?
    var filmEsportatoIl: Date?

    init(ultimoFile: Date? = nil, validoFinoAl: Date? = nil, contenuti: [String] = [], aggiunteDopoUltimoFile: [String] = [],
         filmImpronta: String? = nil, filmEsportatoIl: Date? = nil) {
        self.ultimoFile = ultimoFile
        self.validoFinoAl = validoFinoAl
        self.contenuti = contenuti
        self.aggiunteDopoUltimoFile = aggiunteDopoUltimoFile
        self.filmImpronta = filmImpronta
        self.filmEsportatoIl = filmEsportatoIl
    }

    private enum CodingKeys: String, CodingKey {
        case ultimoFile, validoFinoAl, contenuti, aggiunteDopoUltimoFile, filmImpronta, filmEsportatoIl
    }

    /// Lettura tollerante: ogni campo può mancare.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ultimoFile = (try? c.decodeIfPresent(Date.self, forKey: .ultimoFile)) ?? nil
        validoFinoAl = (try? c.decodeIfPresent(Date.self, forKey: .validoFinoAl)) ?? nil
        contenuti = ((try? c.decodeIfPresent([String].self, forKey: .contenuti)) ?? nil) ?? []
        aggiunteDopoUltimoFile = ((try? c.decodeIfPresent([String].self, forKey: .aggiunteDopoUltimoFile)) ?? nil) ?? []
        filmImpronta = (try? c.decodeIfPresent(String.self, forKey: .filmImpronta)) ?? nil
        filmEsportatoIl = (try? c.decodeIfPresent(Date.self, forKey: .filmEsportatoIl)) ?? nil
    }
}
