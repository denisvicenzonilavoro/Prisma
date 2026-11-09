import Foundation

// La lettera dal futuro conservata (Design/template-luce-specifica.md §3.1.4 e §3.1.5 punto 5): si salva solo quando il
// consulente la conserva, con «✦ Aggiungi al Prisma di …» (la «Con il piano», decisione 7) o salvandola in PDF (la
// versione mostrata). Le stesure del palco restano in memoria finché il palco è aperto; quella conservata resta
// nell'archivio, così il file del cliente non ripiega sulla lettera fissa di Prisma dopo un riavvio.
// Nel file del cliente della cartella a pezzi e nei backup (`ProvaBackupRacconti`); mai in «Prisma ovunque» (D-L8,
// decisione 44: «Restano fuori: capsule, lettere…»). Per cliente e versione si tiene solo l'ultima conservata.

struct LetteraFuturo: Identifiable, Codable, Equatable {
    /// "lettera-xxxxxxxx".
    var id: String
    var clienteId: String
    var scrittaIl: Date
    var versione: VersioneLettera
    /// Il testo intero, con la firma.
    var testo: String
    /// `.vera` (Qwen sul Mac) o `.modelloFisso` (la lettera di Prisma).
    var autore: AutoreMessaggio
    /// «qwen3.5:4b» se l'ha scritta Vera.
    var modello: String?
    /// La scheda usata, per rileggere da dove vengono i numeri (nome della cifra → cifra come compare nella lettera).
    var cifre: [String: String]

    init(id: String = "lettera-\(UUID().uuidString.prefix(8).lowercased())", clienteId: String, scrittaIl: Date,
         versione: VersioneLettera, testo: String, autore: AutoreMessaggio, modello: String? = nil, cifre: [String: String] = [:]) {
        self.id = id
        self.clienteId = clienteId
        self.scrittaIl = scrittaIl
        self.versione = versione
        self.testo = testo
        self.autore = autore
        self.modello = modello
        self.cifre = cifre
    }

    enum CodingKeys: String, CodingKey { case id, clienteId, scrittaIl, versione, testo, autore, modello, cifre }

    /// Lettura tollerante: senza id, cliente o testo la lettera si scarta (`ElencoTollerante`); una versione o un autore
    /// sconosciuti diventano «Con il piano» e «lettera di Prisma»; le cifre illeggibili si perdono, il testo resta.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        clienteId = try c.decode(String.self, forKey: .clienteId)
        testo = try c.decode(String.self, forKey: .testo)
        guard !id.isEmpty, !clienteId.isEmpty, !testo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DecodingError.dataCorrupted(.init(codingPath: c.codingPath, debugDescription: "lettera senza id, cliente o testo"))
        }
        scrittaIl = (try? c.decodeIfPresent(Date.self, forKey: .scrittaIl)) ?? Date(timeIntervalSinceReferenceDate: 0)
        versione = (try? c.decodeIfPresent(VersioneLettera.self, forKey: .versione)) ?? .conPiano
        autore = (try? c.decodeIfPresent(AutoreMessaggio.self, forKey: .autore)) ?? .modelloFisso
        modello = (try? c.decodeIfPresent(String.self, forKey: .modello)) ?? nil
        cifre = (try? c.decodeIfPresent([String: String].self, forKey: .cifre)) ?? [:]
    }

    /// Le cifre della scheda per la versione, come compaiono nella lettera (solo quelle che ci sono).
    static func cifre(_ s: SchedaLettera, _ v: VersioneLettera) -> [String: String] {
        var r = ["etaTraguardo": "\(s.etaTraguardo)", "annoTraguardo": "\(s.annoTraguardo)", "etaOggi": "\(s.etaOggi)"]
        if let p = MotoreLettera.pensione(s, v) { r["pensioneMensile"] = MotoreLettera.cifra(p) }
        if v == .conPiano, let m = s.versamentoMensile { r["versamentoMensile"] = MotoreLettera.cifra(m) }
        if let a = v == .conPiano ? s.arrivoConPiano : s.arrivoSenzaPiano { r["arrivoObiettivo"] = MotoreLettera.data(a) }
        if let o = s.obiettivo { r["obiettivo"] = o }
        return r
    }

    /// Mette la lettera nell'elenco: sostituisce quella dello stesso cliente e della stessa versione (l'ultima vince).
    static func conserva(_ l: LetteraFuturo, in elenco: [LetteraFuturo]) -> [LetteraFuturo] {
        elenco.filter { !($0.clienteId == l.clienteId && $0.versione == l.versione) } + [l]
    }

    /// L'ultima lettera conservata del cliente per la versione.
    static func ultima(_ elenco: [LetteraFuturo], cliente: String, versione: VersioneLettera) -> LetteraFuturo? {
        elenco.filter { $0.clienteId == cliente && $0.versione == versione }.max { $0.scrittaIl < $1.scrittaIl }
    }
}
